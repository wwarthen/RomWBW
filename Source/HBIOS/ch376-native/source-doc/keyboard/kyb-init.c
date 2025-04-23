#include "kyb_driver.h"
#include <print.h>
#include <stdint.h>
#include <usb_state.h>

uint8_t keyboard_init(void) __sdcccall(1) {
  uint8_t index = 1;

  do {
    usb_device_type t = usb_get_device_type(index);

    if (t == USB_IS_KEYBOARD) {
      print_string("\r\nUSB: KEYBOARD @ $");
      print_uint16(index);
      print_string(" $");

      usb_kyb_init(index);
      return 1;
    }
  } while (++index != MAX_NUMBER_OF_DEVICES + 1);

  print_string("\r\nUSB: KEYBOARD: NOT FOUND$");

  return 0;
}
