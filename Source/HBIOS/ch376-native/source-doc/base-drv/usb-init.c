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

uint16_t ch376_init(uint8_t state) {
  uint8_t r;

  USB_MODULE_LEDS = 0x03;

  if (state == 0) {
    ch_cmd_reset_all();
    delay_medium();

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

    r = ch_very_short_wait_int_and_get_status();

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
  return (uint16_t)count_of_devices() << 8 | state + 1;
}

static uint16_t wait_for_state(const uint8_t loop_counter, uint8_t state, const uint8_t desired_state) __sdcccall(1) {
  uint16_t r = state;

  for (uint8_t i = 0; i < loop_counter; i++) {
    if (state == desired_state)
      break;

    if (i & 1)
      print_string("\b $");
    else
      print_string("\b*$");

    r     = ch376_init(state);
    state = r & 255;
  }

  return r;
}

void _chnative_init(bool forced) {
  uint8_t       state = 0;
  uint16_t      r;
  const uint8_t loop_counter = forced ? 40 : 5;

  print_string("\r\nCH376: *$");

  r     = wait_for_state(loop_counter, state, 1);
  state = r & 255;

  print_string("\bPRESENT (VER $");

  r     = ch376_init(state);
  state = r & 255;
  if (state != 2) {
    print_string("\rCH376: $");
    print_string("VERSION FAILURE\r\n$");
    return;
  }

  print_hex(r >> 8);
  print_string("); $");

  print_string("USB: *$");

  r     = wait_for_state(loop_counter, state, 3);
  state = r & 255;

  if (state == 2) {
    print_string("\bDISCONNECTED$");
    return;
  }

  print_string("\bCONNECTED$");

  // enumerate....
  r     = ch376_init(state);
  state = r & 255;

  for (uint8_t i = 0; i < loop_counter; i++) {
    if (r >> 8 != 0)
      break;

    print_string(".$");
    r     = ch376_init(state);
    state = r & 255;
  }
}

void chnative_init_force(void) { _chnative_init(true); }

void chnative_init(void) { _chnative_init(false); }
