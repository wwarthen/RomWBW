#include "enumerate_hub.h"
#include "class_hub.h"
#include "delay.h"
#include "protocol.h"
#include "work-area.h"
#include <string.h>

const setup_packet cmd_set_feature     = {RT_HOST_TO_DEVICE | RT_CLASS | RT_OTHER, SET_FEATURE, {FEAT_PORT_POWER, 0}, {1, 0}, 0};
const setup_packet cmd_clear_feature   = {RT_HOST_TO_DEVICE | RT_CLASS | RT_OTHER, CLEAR_FEATURE, {FEAT_PORT_POWER, 0}, {1, 0}, 0};
const setup_packet cmd_get_status_port = {
    RT_DEVICE_TO_HOST | RT_CLASS | RT_OTHER, GET_STATUS, {0, 0}, {1, 0}, sizeof(hub_port_status)};

usb_error hub_set_feature(const device_config_hub *const hub_config, const uint8_t feature, const uint8_t index) {
  setup_packet set_feature;
  set_feature = cmd_set_feature;

  set_feature.bValue[0] = feature;
  set_feature.bIndex[0] = index;
  return usb_control_transfer(&set_feature, 0, hub_config->address, hub_config->max_packet_size);
}

usb_error hub_clear_feature(const device_config_hub *const hub_config, const uint8_t feature, const uint8_t index) {
  setup_packet clear_feature;
  clear_feature = cmd_clear_feature;

  clear_feature.bValue[0] = feature;
  clear_feature.bIndex[0] = index;
  return usb_control_transfer(&clear_feature, 0, hub_config->address, hub_config->max_packet_size);
}

usb_error hub_get_status_port(const device_config_hub *const hub_config, const uint8_t index, hub_port_status *const port_status) {
  setup_packet get_status_port;
  get_status_port = cmd_get_status_port;

  get_status_port.bIndex[0] = index;
  return usb_control_transfer(&get_status_port, port_status, hub_config->address, hub_config->max_packet_size);
}

usb_error configure_usb_hub(_working *const working) __z88dk_fastcall {
  _usb_state *const work_area = get_usb_work_area();

  usb_error                      result;
  hub_descriptor                 hub_description;
  hub_port_status                port_status;
  const device_config_hub *const hub_config = working->hub_config;

  CHECK(hub_get_descriptor(hub_config, &hub_description));

  uint8_t i = hub_description.bNbrPorts;
  do {
    CHECK(hub_clear_feature(hub_config, FEAT_PORT_POWER, i));

    CHECK(hub_set_feature(hub_config, FEAT_PORT_POWER, i));

    hub_clear_feature(hub_config, FEAT_PORT_RESET, i);

    CHECK(hub_set_feature(hub_config, FEAT_PORT_RESET, i));

    CHECK(hub_get_status_port(hub_config, i, &port_status));

    if (port_status.wPortStatus & PORT_STAT_CONNECTION) {
      CHECK(hub_clear_feature(hub_config, HUB_FEATURE_PORT_CONNECTION_CHANGE, i));

      CHECK(hub_clear_feature(hub_config, FEAT_PORT_ENABLE_CHANGE, i));

      CHECK(hub_clear_feature(hub_config, FEAT_PORT_RESET_CHANGE, i));
      delay_short();

      CHECK(hub_get_status_port(hub_config, i, &port_status));
      delay_short();

      CHECK(read_all_configs(working->state));

    } else {
      CHECK(hub_clear_feature(hub_config, FEAT_PORT_POWER, i));
    }
  } while (--i != 0);

  return USB_ERR_OK;
done:
  return result;
}
