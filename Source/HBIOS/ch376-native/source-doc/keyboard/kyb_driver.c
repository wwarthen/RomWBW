#include "kyb_driver.h"
#include "class_hid.h"
#include "class_hid_keyboard.h"
#include <critical-section.h>
#include <dev_transfers.h>
#include <stdint.h>
#include <usb_state.h>

#define KEYBOARD_BUFFER_SIZE      8
#define KEYBOARD_BUFFER_SIZE_MASK 7
typedef uint16_t modifier_and_code_t;

static device_config_keyboard *keyboard_config = 0;

static modifier_and_code_t buffer[KEYBOARD_BUFFER_SIZE] = {0};
static uint8_t             write_index                  = 0;
static uint8_t             read_index                   = 0;

static uint8_t           alt_write_index               = 0;
static uint8_t           alt_read_index                = 0;
static keyboard_report_t reports[KEYBOARD_BUFFER_SIZE] = {{0}};

static keyboard_report_t *queued_report = NULL;
static keyboard_report_t  report        = {0};
static keyboard_report_t  previous      = {0};

#define DI __asm__("DI")
#define EI __asm__("EI")

static uint8_t report_diff() __sdcccall(1) {
  uint8_t *a = (uint8_t *)&report;
  uint8_t *b = (uint8_t *)&previous;

  uint8_t i = sizeof(report);
  do {
    if (*a++ != *b++)
      return true;
  } while (--i != 0);

  return false;
}

static void report_put() {
  uint8_t next_write_index = (alt_write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;

  if (next_write_index != alt_read_index) { // Check if buffer is not full
    reports[alt_write_index] = report;
    alt_write_index          = next_write_index;
  }
}

static void keyboard_buf_put(const uint8_t indx) __sdcccall(1) {
  const uint8_t key_code = report.keyCode[indx];
  if (key_code >= 0x80 || key_code == 0)
    return; // ignore ???

  // if already reported, just skip it
  uint8_t  i = 6;
  uint8_t *a = previous.keyCode;
  do {
    if (*a++ == key_code)
      return;
  } while (--i != 0);

  uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
  if (next_write_index != read_index) { // Check if buffer is not full
    buffer[write_index] = (uint16_t)report.bModifierKeys << 8 | (uint16_t)key_code;
    write_index         = next_write_index;
  }
}

uint16_t usb_kyb_buf_size() {
  DI;

  uint8_t size;
  uint8_t alt_size;

  if (alt_write_index >= alt_read_index)
    alt_size = alt_write_index - alt_read_index;
  else
    alt_size = KEYBOARD_BUFFER_SIZE - alt_read_index + alt_write_index;

  if (alt_size != 0)
    alt_read_index = (alt_read_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;

  if (write_index >= read_index)
    size = write_index - read_index;
  else
    size = KEYBOARD_BUFFER_SIZE - read_index + write_index;

  EI;
  return (uint16_t)alt_size << 8 | (uint16_t)size;
}

uint32_t usb_kyb_buf_get_next() {
  if (write_index == read_index) // Check if buffer is empty
    return 0x0000FF00;           // H = -1, D, E, L = 0

  DI;
  const uint8_t modifier_key = buffer[read_index] >> 8;
  const uint8_t key_code     = buffer[read_index] & 255;
  read_index                 = (read_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
  EI;
  // D: Modifier keys - aka Keystate
  // E: ASCII Code
  // H: 0
  // L: KeyCode aka scan code

  const unsigned char c = scancode_to_char(modifier_key, key_code);
  /* D = modifier, e-> char, H = 0, L=>code */

  return (uint32_t)modifier_key << 24 | (uint32_t)c << 16 | key_code;
}

uint8_t usb_kyb_flush() __sdcccall(1) {
  DI;
  write_index = read_index = alt_write_index = alt_read_index = 0;

  uint8_t  i = sizeof(previous);
  uint8_t *a = (uint8_t *)previous;
  uint8_t *b = (uint8_t *)report;
  do {
    *a++ = 0;
    *b++ = 0;
  } while (--i != 0);

  EI;

  return 0;
}

void usb_kyb_tick(void) {
  if (is_in_critical_section())
    return;

  ch_configure_nak_retry_disable();
  result = usbdev_dat_in_trnsfer_0((device_config *)keyboard_config, (uint8_t *)&report, 8);
  ch_configure_nak_retry_3s();
  if (result == 0) {
    if (report_diff()) {
      report_put();
      uint8_t i = 6;
      do {
        keyboard_buf_put(i - 1);
      } while (--i != 0);
      previous = report;
    }
  }
}

usb_error usb_kyb_init(const uint8_t dev_index) {
  uint8_t result;
  keyboard_config = (device_config_keyboard *)get_usb_device_config(dev_index);

  if (keyboard_config == NULL)
    return USB_ERR_OTHER;

  CHECK(hid_set_protocol(keyboard_config, 1));
  return hid_set_idle(keyboard_config, 0x80);

done:
  return result;
}
