#ifndef __CLASS_HID_KEYBOARD_H__
#define __CLASS_HID_KEYBOARD_H__

#include <stdbool.h>
#include <stdint.h>

typedef struct {
  uint8_t bModifierKeys;
  uint8_t bReserved;
  uint8_t keyCode[6];
} keyboard_report_t;

#define KEY_MOD_LCTRL  0x01
#define KEY_MOD_LSHIFT 0x02
#define KEY_MOD_LALT   0x04
#define KEY_MOD_LMETA  0x08
#define KEY_MOD_RCTRL  0x10
#define KEY_MOD_RSHIFT 0x20
#define KEY_MOD_RALT   0x40
#define KEY_MOD_RMETA  0x80

#define KEY_CODE_CAPS_LOCK 0x39

extern char scancodes_table[128];
extern char scancode_to_char(const uint8_t modifier_keys, const uint8_t code, const bool caps_lock_engaged) __sdcccall(1);

#endif
