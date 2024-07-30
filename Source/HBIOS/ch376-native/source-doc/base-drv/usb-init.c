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

void chnative_init(void) {
  memset(get_usb_work_area(), 0, sizeof(_usb_state));

  ch_cmd_reset_all();

  delay_medium();

  if (!ch_probe()) {
    print_string("\r\nCH376: NOT PRESENT$");
    return;
  }

  print_string("\r\nCH376: PRESENT (VER $");
  print_hex(ch_cmd_get_ic_version());
  print_string("); $");

  usb_host_bus_reset();

  for (uint8_t i = 0; i < 4; i++) {
    const uint8_t r = ch_very_short_wait_int_and_get_status();

    if (r == USB_INT_CONNECT) {
      print_string("USB: CONNECTED$");

      enumerate_all_devices();

      return;
    }
  }

  print_string("USB: DISCONNECTED$");
}
