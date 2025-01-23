#include "ch376.h"
#include "enumerate.h"
#include "print.h"
#include "work-area.h"
#include "z80.h"
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

void _chnative_init(bool forced) {
  memset(get_usb_work_area(), 0, sizeof(_usb_state));

  USB_MODULE_LEDS = 0x00;

  ch_cmd_reset_all();

  delay_medium();

  if (forced) {
    bool indicator = true;
    print_string("\r\nCH376: *$");
    while (!ch_probe()) {
      if (indicator) {
        USB_MODULE_LEDS = 0x00;
        print_string("\b $");
      } else {
        USB_MODULE_LEDS = 0x03;
        print_string("\b*$");
      }

      delay_medium();
      indicator = !indicator;
    }

    print_string("\bPRESENT (VER $");
  } else {
    if (!ch_probe()) {
      USB_MODULE_LEDS = 0x00;
      print_string("\r\nCH376: NOT PRESENT$");
      return;
    }

    print_string("\r\nCH376: PRESENT (VER $");
  }

  USB_MODULE_LEDS = 0x01;

  print_hex(ch_cmd_get_ic_version());
  print_string("); $");

  usb_host_bus_reset();

  for (uint8_t i = 0; i < (forced ? 10 : 5); i++) {
    const uint8_t r = ch_very_short_wait_int_and_get_status();

    if (r == USB_INT_CONNECT) {
      print_string("USB: CONNECTED$");

      enumerate_all_devices();

      USB_MODULE_LEDS = 0x03;
      return;
    }
  }

  USB_MODULE_LEDS = 0x00;
  print_string("USB: DISCONNECTED$");
}

void chnative_init_force(void) { _chnative_init(true); }

void chnative_init(void) { _chnative_init(false); }
