#include "class_hid.h"
#include "class_hid_keyboard.h"
#include <dev_transfers.h>
#include <print.h>
#include <stdint.h>
#include <usb_state.h>

void keyboard_init(void) {

  uint8_t index = 1;
  do {
    device_config_keyboard *const keyboard_config = (device_config_keyboard *)get_usb_device_config(index);

    if (keyboard_config == NULL)
      break;

    const usb_device_type t = keyboard_config->type;

    if (t == USB_IS_KEYBOARD) {
      print_string("\r\nUSB: KEYBOARD @ $");
      print_uint16(index);
      print_string(" $");

      // keyboard_config->drive_index = usb_device_count++;
      hid_set_protocol(keyboard_config, 1);
      hid_set_idle(keyboard_config, 0x80);
      return;
    }
  } while (++index != MAX_NUMBER_OF_DEVICES + 1);

  print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
}

// void drv_timi_keyboard(void) {
//   _usb_state *const p = get_usb_work_area();
//   if (p->active)
//     return;

//   p->active = true;

//   device_config_keyboard *const keyboard_config = (device_config_keyboard *)find_device_config(USB_IS_KEYBOARD);

//   keyboard_report report;

//   ch_configure_nak_retry_disable();
//   const usb_error result = usbdev_data_in_transfer_ep0((device_config *)keyboard_config, (uint8_t *)report, 8);
//   ch_configure_nak_retry_3s();
//   if (result == 0) {
//     const char c = scancode_to_char(report.bModifierKeys, report.keyCode[0]);
//     key_put_into_buf(c);
//   }

//   p->active = false;
// }
