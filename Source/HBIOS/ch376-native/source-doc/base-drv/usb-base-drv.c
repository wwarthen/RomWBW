#include "usb-base-drv.h"
#include "ch376.h"
#include "enumerate.h"
#include "work-area.h"
#include <string.h>

static usb_error usb_host_bus_reset(void) {
  ch_cmd_set_usb_mode(CH_MODE_HOST);
  delay_20ms();

  ch_cmd_set_usb_mode(CH_MODE_HOST_RESET);
  delay_20ms();

  ch_cmd_set_usb_mode(CH_MODE_HOST);
  delay_20ms();

  ch_configure_nak_retry_3s();

  return USB_ERR_OK;
}

#define ERASE_LINE "\x1B\x6C\r$"

uint16_t usb_init(uint8_t state) __z88dk_fastcall {
  uint8_t r;

  USB_MODULE_LEDS = 0x03;

  if (state == 0) {
    ch_cmd_reset_all();
    delay_short();

    if (!ch_probe()) {
      USB_MODULE_LEDS = 0x00;
      return 0xFF00;
    }
    USB_MODULE_LEDS = 0x00;
    return 1;
  }

  if (state == 1) {
    r = ch_cmd_get_ic_version();

    USB_MODULE_LEDS = 0x00;
    return (uint16_t)r << 8 | 2;
  }

  if (state == 2) {
    usb_host_bus_reset();

    r = ch_very_short_status();

    if (r != USB_INT_CONNECT) {
      USB_MODULE_LEDS = 0x00;
      return 2;
    }

    return 3;
  }

  memset(get_usb_work_area(), 0, sizeof(_usb_state));
  if (state != 2) {
    usb_host_bus_reset();
    delay_medium();
  }
  enumerate_all_devices();
  USB_MODULE_LEDS = 0x00;
  return (uint16_t)count_of_devices() << 8 | 4;
}

usb_error usb_scsi_seek(const uint16_t dev_index, const uint32_t lba) {
  device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);

  dev->current_lba = lba;
  return USB_ERR_OK;
}
