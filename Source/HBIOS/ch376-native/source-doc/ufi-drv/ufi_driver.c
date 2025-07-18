#include "ufi_driver.h"
#include "class_ufi.h"
#include <dev_transfers.h>
#include <string.h>

uint32_t usb_ufi_get_cap(const uint16_t dev_index) {
  device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);

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

usb_error usb_ufi_read(const uint16_t dev_index, uint8_t *const buffer) {
  device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);

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
  const uint8_t sense_key = response.sense_key & 15;

  if (sense_key != 0)
    return -1;

  return USB_ERR_OK;
}

usb_error usb_ufi_write(const uint16_t dev_index, uint8_t *const buffer) {
  device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);

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
  const uint8_t sense_key = response.sense_key & 15;

  if (sense_key != 0)
    return -1;

  return USB_ERR_OK;
}
