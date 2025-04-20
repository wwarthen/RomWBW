#include "class_ufi.h"
#include <dev_transfers.h>
#include <hbios.h>
#include <print.h>
#include <string.h>
#include <usb-base-drv.h>
#include <work-area.h>

extern const uint16_t const ch_ufi_fntbl[];

void chufi_init(void) {
  uint8_t index = 1;

  do {
    device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);

    if (storage_device == NULL)
      break;

    const usb_device_type t = storage_device->type;

    if (t == USB_IS_FLOPPY) {
      print_string("\r\nUSB: FLOPPY @ $");
      print_uint16(index);
      print_string(":$");
      print_uint16(storage_device->drive_index);
      print_string(" $");
      dio_add_entry(ch_ufi_fntbl, storage_device);
    }

  } while (++index != MAX_NUMBER_OF_DEVICES + 1);
}

uint32_t chufi_get_cap(device_config *const dev) {
  ufi_format_capacities_response response;
  memset(&response, 0, sizeof(ufi_format_capacities_response));

  wait_for_device_ready(dev, 25);

  // not sure if we need to do this to 'clear' some state
  ufi_inquiry_response inquiry;
  ufi_inquiry(dev, &inquiry);

  wait_for_device_ready(dev, 15);

  const usb_error result = ufi_read_frmt_caps(dev, &response);
  if (result != USB_ERR_OK)
    return 0;

  return convert_from_msb_first(response.descriptors[0].number_of_blocks);
}

uint8_t chufi_read(device_config_storage *const dev, uint8_t *const buffer) {

  if (wait_for_device_ready((device_config *)dev, 20) != 0)
    return -1; // Not READY!

  usb_error            result;
  ufi_interrupt_status sense_codes;

  memset(&sense_codes, 0, sizeof(sense_codes));

  if (ufi_read_write_sector((device_config *)dev, false, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes) != USB_ERR_OK)
    return -1; // general error

  ufi_request_sense_response response;
  memset(&response, 0, sizeof(response));

  if ((result = ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK)
    return -1; // error

  const uint8_t asc       = response.asc;
  const uint8_t ascq      = response.ascq;
  const uint8_t sense_key = response.sense_key;

  if (sense_key != 0)
    return -1;

  return USB_ERR_OK;
}

usb_error chufi_write(device_config_storage *const dev, uint8_t *const buffer) {

  if (wait_for_device_ready((device_config *)dev, 20) != 0)
    return -1; // Not READY!

  ufi_interrupt_status sense_codes;

  memset(&sense_codes, 0, sizeof(sense_codes));
  if ((ufi_read_write_sector((device_config *)dev, true, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes)) != USB_ERR_OK) {
    return -1;
  }

  ufi_request_sense_response response;
  memset(&response, 0, sizeof(response));

  if ((ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK) {
    return -1;
  }

  const uint8_t asc       = response.asc;
  const uint8_t ascq      = response.ascq;
  const uint8_t sense_key = response.sense_key;

  if (sense_key != 0)
    return -1;

  return USB_ERR_OK;
}
