#include "print.h"
#include "usb-base-drv.h"

static uint16_t wait_for_state(const uint8_t loop_counter, uint8_t state, const uint8_t desired_state) __sdcccall(1) {
  uint16_t r = state;

  for (uint8_t i = 0; i < loop_counter; i++) {
    if (state == desired_state)
      break;

    if (i & 1)
      print_string("\b $");
    else
      print_string("\b*$");

    r     = usb_init(state);
    state = r & 255;
  }

  return r;
}

extern const char ch376_driver_version[];

extern uint8_t CH376_DAT_PORT_ADDR;
extern uint8_t CH376_CMD_PORT_ADDR;
extern uint8_t USB_MOD_LEDS_ADDR;

// there is a weird bug with the compiler - sometimes string literals containing
// a dollar sign -- the dollar sign is ignored!
const char comma_0_x_dollar[] = {' ', '0', 'x', '$'};

static void _chnative_init(bool forced) {
  uint8_t       state = 0;
  uint16_t      r;
  const uint8_t loop_counter = forced ? 40 : 5;

  print_string("\r\nCH376: IO=0x$");
  print_hex((uint8_t)&CH376_DAT_PORT_ADDR);
  print_string(comma_0_x_dollar);
  print_hex((uint8_t)&CH376_CMD_PORT_ADDR);
  print_string(comma_0_x_dollar);
  print_hex((uint8_t)&USB_MOD_LEDS_ADDR);
  print_string(" *$");

  r     = wait_for_state(loop_counter, state, 1);
  state = r & 255;

  print_string("\bPRESENT (VER $");

  r     = usb_init(state);
  state = r & 255;
  if (state != 2) {
    print_string("\rCH376: $");
    print_string("VERSION FAILURE\r\n$");
    return;
  }

  print_hex(r >> 8);
  print_string(ch376_driver_version);

  print_string("USB: *$");

  r     = wait_for_state(loop_counter, state, 3);
  state = r & 255;

  if (state == 2) {
    print_string("\bDISCONNECTED$");
    return;
  }

  print_string("\bCONNECTED$");

  // enumerate....
  r     = usb_init(state);
  state = r & 255;

  for (uint8_t i = 0; i < loop_counter; i++) {
    if (r >> 8 != 0)
      break;

    print_string(".$");
    r     = usb_init(state);
    state = r & 255;
  }
}

void chnative_init_force(void) { _chnative_init(true); }

void chnative_init(void) { _chnative_init(false); }
