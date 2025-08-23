#include "enumerate.h"
#include "enumerate_hub.h"
#include "enumerate_storage.h"
#include "protocol.h"
#include "work-area.h"
#include <string.h>

#include "print.h"

usb_error op_id_class_drv(_working *const working) __sdcccall(1);
usb_error op_parse_endpoint(_working *const working) __sdcccall(1);

static usb_error adv_to_next_desc(_working *const working, const uint8_t descriptor_type) __sdcccall(1) {
  usb_descriptor_t *d;
  const uint8_t    *buffer_end = working->config.buffer + MAX_CONFIG_SIZE;

  if (working->ptr >= buffer_end)
    return USB_ERR_BUFF_TO_LARGE;

  d = (usb_descriptor_t *)working->ptr;

  do {
    working->ptr += d->bLength;

    if (working->ptr >= buffer_end)
      return USB_ERR_BUFF_TO_LARGE;

    d = (usb_descriptor_t *)working->ptr;
  } while (d->bDescriptorType != descriptor_type);

  if (working->ptr + d->bLength >= buffer_end)
    return USB_ERR_BUFF_TO_LARGE;

  return USB_ERR_OK;
}

void parse_endpoint_keyboard(device_config_keyboard *const keyboard_config, const endpoint_descriptor const *pEndpoint)
    __sdcccall(1) {
  endpoint_param *const ep = &keyboard_config->endpoints[0];
  ep->number               = pEndpoint->bEndpointAddress;
  ep->toggle               = 0;
  ep->max_packet_sizex     = calc_max_packet_sizex(pEndpoint->wMaxPacketSize);
}

usb_device_type identify_class_driver(_working *const working) {
  const interface_descriptor *const p = (const interface_descriptor *)working->ptr;
  if (p->bInterfaceClass == 2)
    return USB_IS_CDC;

  if (p->bInterfaceClass == 8 && (p->bInterfaceSubClass == 6 || p->bInterfaceSubClass == 5) && p->bInterfaceProtocol == 80)
    return USB_IS_MASS_STORAGE;

  if (p->bInterfaceClass == 8 && p->bInterfaceSubClass == 4 && p->bInterfaceProtocol == 0)
    return USB_IS_FLOPPY;

  if (p->bInterfaceClass == 9 && p->bInterfaceSubClass == 0 && p->bInterfaceProtocol == 0)
    return USB_IS_HUB;

  if (p->bInterfaceClass == 3)
    return USB_IS_KEYBOARD;

  return USB_IS_UNKNOWN;
}

usb_error op_interface_next(_working *const working) __z88dk_fastcall {
  uint8_t result;

  if (--working->interface_count == 0)
    return USB_ERR_OK;

  CHECK(adv_to_next_desc(working, USB_DESCR_INTERFACE));
  return op_id_class_drv(working);

done:
  return result;
}

usb_error op_endpoint_next(_working *const working) __sdcccall(1) {
  usb_error result;

  if (working->endpoint_count != 0 && --working->endpoint_count > 0) {
    CHECK(adv_to_next_desc(working, USB_DESCR_ENDPOINT));
    return op_parse_endpoint(working);
  }

  return op_interface_next(working);

done:
  return result;
}

usb_error op_parse_endpoint(_working *const working) __sdcccall(1) {
  const endpoint_descriptor *endpoint = (endpoint_descriptor *)working->ptr;
  device_config *const       device   = working->p_current_device;

  switch (working->usb_device) {
  case USB_IS_FLOPPY:
  case USB_IS_MASS_STORAGE: {
    parse_endpoints((device_config_storage *)device, endpoint);
    break;
  }

  case USB_IS_KEYBOARD: {
    parse_endpoint_keyboard((device_config_keyboard *)device, endpoint);
    break;
  }
  }

  return op_endpoint_next(working);
}

usb_error
configure_device(const _working *const working, const interface_descriptor *const interface, device_config *const dev_cfg) {
  dev_cfg->interface_number = interface->bInterfaceNumber;
  dev_cfg->max_packet_size  = working->desc.bMaxPacketSize0;
  dev_cfg->address          = working->current_device_address;
  dev_cfg->type             = working->usb_device;

  return usbtrn_set_config(dev_cfg->address, dev_cfg->max_packet_size, working->config.desc.bConfigurationvalue);
}

usb_error op_cap_hub_drv_intf(_working *const working) __sdcccall(1) {
  const interface_descriptor *const interface = (interface_descriptor *)working->ptr;

  usb_error         result;
  device_config_hub hub_config;
  working->hub_config = &hub_config;

  hub_config.type = USB_IS_HUB;
  CHECK(configure_device(working, interface, (device_config *const)&hub_config));
  RETURN_CHECK(configure_usb_hub(working));
done:
  return result;
}

usb_error op_cap_drv_intf(_working *const working) __z88dk_fastcall {
  usb_error                         result;
  _usb_state *const                 work_area = get_usb_work_area();
  const interface_descriptor *const interface = (interface_descriptor *)working->ptr;

  working->endpoint_count = interface->bNumEndpoints;
  if (working->endpoint_count > 0)
    CHECK(adv_to_next_desc(working, USB_DESCR_ENDPOINT));
  working->p_current_device = NULL;

  switch (working->usb_device) {
  case USB_IS_HUB: {
    CHECK(op_cap_hub_drv_intf(working))
    break;
  }

  case USB_IS_UNKNOWN: {
    device_config unkown_dev_cfg;
    memset(&unkown_dev_cfg, 0, sizeof(device_config));
    working->p_current_device = &unkown_dev_cfg;
    CHECK(configure_device(working, interface, &unkown_dev_cfg));
    break;
  }

  default: {
    device_config *dev_cfg = find_first_free();
    if (dev_cfg == NULL)
      return USB_ERR_OUT_OF_MEMORY;
    working->p_current_device = dev_cfg;
    CHECK(configure_device(working, interface, dev_cfg));
    break;
  }
  }

  return op_parse_endpoint(working);

done:
  return result;
}

usb_error op_id_class_drv(_working *const working) __sdcccall(1) {
  const interface_descriptor *const ptr = (const interface_descriptor *)working->ptr;

  if (ptr->bDescriptorType != USB_DESCR_INTERFACE)
    return USB_ERR_FAIL;

  working->usb_device = identify_class_driver(working);

  return op_cap_drv_intf(working);
}

usb_error op_get_cfg_desc(_working *const working) __sdcccall(1) {
  usb_error result;

  const uint8_t max_packet_size = working->desc.bMaxPacketSize0;

  memset(working->config.buffer, 0, MAX_CONFIG_SIZE);
  working->ptr = working->config.buffer;

  CHECK(usbtrn_gfull_cfg_desc(working->config_index, working->current_device_address, max_packet_size, MAX_CONFIG_SIZE,
                              working->config.buffer));

  CHECK(adv_to_next_desc(working, USB_DESCR_INTERFACE));
  working->interface_count = working->config.desc.bNumInterfaces;

  return op_id_class_drv(working);

done:
  return result;
}

usb_error read_all_configs(enumeration_state *const state) {
  uint8_t           result;
  _usb_state *const work_area = get_usb_work_area();
  uint8_t retry_count = 0;

  _working working;
  memset(&working, 0, sizeof(_working));
  working.state = state;

retry:
  CHECK(usbtrn_get_descriptor(&working.desc));

  state->next_device_address++;
  working.current_device_address = state->next_device_address;
  CHECK(usbtrn_set_address(working.current_device_address));

  for (uint8_t config_index = 0; config_index < working.desc.bNumConfigurations; config_index++) {
    working.config_index = config_index;

    CHECK(op_get_cfg_desc(&working));
  }

  return USB_ERR_OK;
done:
  if (result == USB_ERR_STALL && retry_count == 0) {
    retry_count++;
    ch_command(CMD1H_CLR_STALL);
    ch_get_status();
    goto retry;
  }
  return result;
}

usb_error enumerate_all_devices(void) {
  _usb_state *const work_area = get_usb_work_area();
  enumeration_state state;
  memset(&state, 0, sizeof(enumeration_state));

  usb_error result = read_all_configs(&state);

  work_area->count_of_detected_usb_devices = state.next_device_address;

done:
  return result;
}

/*
  enumerate_all_devices
    -> read_all_configs
      -> parse_config
        -> op_get_cfg_desc
          -> op_id_class_drv
            -> op_cap_drv_intf (increment index)
              -> op_parse_endpoint
                -> parse_endpoints
                -> parse_endpoint_hub
                -> op_endpoint_next
                  -> op_parse_endpoint -^ (install driver endpoint)
                  -> op_interface_next
                    -> return
                    -> op_id_class_drv -^


*/
