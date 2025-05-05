#include "kyb_driver.h"
#include "class_hid.h"
#include "class_hid_keyboard.h"
#include <critical-section.h>
#include <dev_transfers.h>
#include <stdint.h>
#include <usb_state.h>

#define KEYBOARD_BUFFER_SIZE      8
#define KEYBOARD_BUFFER_SIZE_MASK 7

static bool                    caps_lock_engaged = true;
static device_config_keyboard *keyboard_config   = 0;

static uint8_t buffer[KEYBOARD_BUFFER_SIZE] = {0};
static uint8_t write_index                  = 0;
static uint8_t read_index                   = 0;

static keyboard_report_t report   = {0};
static keyboard_report_t previous = {0};

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

static void keyboard_buf_put(const uint8_t indx) __sdcccall(1) {
  const uint8_t key_code = report.keyCode[indx];
  if (key_code >= 0x80 || key_code == 0)
    return; // ignore ???

  // if already reported, just skip it
  if (previous.keyCode[indx] == key_code)
    return;

  if (key_code == KEY_CODE_CAPS_LOCK) {
    caps_lock_engaged = !caps_lock_engaged;
    return;
  }

  const unsigned char c = scancode_to_char(report.bModifierKeys, key_code, caps_lock_engaged);

  if (c == 0)
    return;

  uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
  if (next_write_index != read_index) { // Check if buffer is not full
    buffer[write_index] = c;
    write_index         = next_write_index;
  }
}

uint8_t usb_kyb_status() __sdcccall(1) {
  DI;

  uint8_t size;

  if (write_index >= read_index)
    size = write_index - read_index;
  else
    size = KEYBOARD_BUFFER_SIZE - read_index + write_index;

  EI;
  return size;
}

uint16_t usb_kyb_read() {
  if (write_index == read_index) // Check if buffer is empty
    return 0xFF00;               // H = -1, L = 0

  DI;
  const uint8_t c = buffer[read_index];
  read_index      = (read_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
  EI;

  /* H = 0, L = ascii char */
  return c;
}

uint8_t usb_kyb_flush() __sdcccall(1) {
  DI;
  write_index = read_index = 0;

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
  usb_error result;

  if (is_in_critical_section())
    return;

  ch_configure_nak_retry_disable();
  result = usbdev_dat_in_trnsfer_0((device_config *)keyboard_config, (uint8_t *)&report, 8);
  ch_configure_nak_retry_3s();
  if (result == 0) {
    if (report_diff()) {
      uint8_t i = 6;
      do {
        keyboard_buf_put(i - 1);
      } while (--i != 0);
      previous = report;
    }
  }
}

void usb_kyb_init(const uint8_t dev_index) __sdcccall(1) {
  keyboard_config = (device_config_keyboard *)get_usb_device_config(dev_index);

  if (keyboard_config == NULL)
    return;

  hid_set_protocol(keyboard_config, 1);
  hid_set_idle(keyboard_config, 0x80);
}
