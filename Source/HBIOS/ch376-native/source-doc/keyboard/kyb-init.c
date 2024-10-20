#include "class_hid.h"
#include "class_hid_keyboard.h"
#include <critical-section.h>
#include <dev_transfers.h>
#include <print.h>
#include <stdint.h>
#include <usb_state.h>

static device_config_keyboard *keyboard_config = 0;

void keyboard_init(void) {

  uint8_t index   = 1;
  keyboard_config = NULL;

  do {
    keyboard_config = (device_config_keyboard *)get_usb_device_config(index);

    if (keyboard_config == NULL)
      break;

    const usb_device_type t = keyboard_config->type;

    if (t == USB_IS_KEYBOARD) {
      print_string("\r\nUSB: KEYBOARD @ $");
      print_uint16(index);
      print_string(" $");

      hid_set_protocol(keyboard_config, 1);
      hid_set_idle(keyboard_config, 0x80);
      return;
    }
  } while (++index != MAX_NUMBER_OF_DEVICES + 1);

  print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
}

#define KEYBOARD_BUFFER_SIZE      8
#define KEYBOARD_BUFFER_SIZE_MASK 7
typedef struct {
  uint8_t modifier_keys;
  uint8_t key_code;
} keyboard_event;
keyboard_event buffer[KEYBOARD_BUFFER_SIZE] = {{0}};
uint8_t        write_index                  = 0;
uint8_t        read_index                   = 0;

void keyboard_buf_put(const uint8_t modifier_keys, const uint8_t key_code) {
  if (key_code >= 0x80 || key_code == 0)
    return; // ignore ???

  uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
  if (next_write_index != read_index) { // Check if buffer is not full
    buffer[write_index].modifier_keys = modifier_keys;
    buffer[write_index].key_code      = key_code;
    write_index                       = next_write_index;
  }
}

uint8_t keyboard_buf_size() __sdcccall(1) {
  if (write_index >= read_index)
    return write_index - read_index;

  return KEYBOARD_BUFFER_SIZE - read_index + write_index;
}

uint32_t keyboard_buf_get_next() {
  if (write_index == read_index) // Check if buffer is empty
    return 255 << 8;

  const uint8_t modifier_key = buffer[read_index].modifier_keys;
  const uint8_t key_code     = buffer[read_index].key_code;
  read_index                 = (read_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
  const unsigned char c      = scancode_to_char(modifier_key, key_code);
  /* D = modifier, e-> char, H = 0, L=>code */
  return (uint32_t)modifier_key << 24 | (uint32_t)c << 16 | key_code;
}

void keyboard_buf_flush() {
  write_index = 0;
  read_index  = 0;
}

uint8_t active = 0;

keyboard_report report = {0};

void keyboard_tick(void) {
  if (is_in_critical_section())
    return;

  ch_configure_nak_retry_disable();
  result = usbdev_dat_in_trnsfer_0((device_config *)keyboard_config, (uint8_t *)report, 8);
  ch_configure_nak_retry_3s();
  if (result == 0)
    keyboard_buf_put(report.bModifierKeys, report.keyCode[0]);
}
