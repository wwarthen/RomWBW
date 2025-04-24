#include "class_hid_keyboard.h"

#define ESC 0x1B
/**
 * scan codes sourced from https://deskthority.net/wiki/Scancode
 *
 */
char scancodes_shift_table[128] = {
    0x00, /*Reserved*/
    0x00, /*Reserved*/
    0x00, /*Reserved*/
    0x00, /*Reserved*/

    /* 0x04 */
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',

    /* 0x0C */
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',

    /* 0X14 */
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',

    /* 0X1C */
    'Y',
    'Z',
    '!',
    '@',
    '#',
    '$',
    '%',
    '^',

    /* 0x24 */
    '&',
    '*',
    '(',
    ')',
    '\r',
    ESC,
    '\b',
    '\t',

    /* 0x2C */
    ' ',
    '_',
    '+',
    '{',
    '}',
    '|',
    '~',
    ':',

    /* 0x34 */
    '"',
    '~',
    '<',
    '>',
    '?',
    0x00 /*CAPSLOCK*/,
    0x00 /* F1 */,
    0x00 /* F2 */,

    /* 0x3C */
    0x00 /* F3 */,
    0x00 /* F4 */,
    0x00 /* F5 */,
    0x00 /* F6 */,
    0x00 /* F7 */,
    0x00 /* F8 */,
    0x00 /* F9 */,
    0x00 /* F10 */,

    /* 0x44 */
    0x00 /* F11 */,
    0x00 /* F12 */,
    0x00 /* PRINTSCREEN */,
    0x00 /* SCROLLLOCK */,
    0x00 /* PAUSE */,
    0x00 /* INSERT */,
    0x00 /* HOME */,
    0x00 /* PAGEUP */,

    /* 0x4C */
    0x00 /* DELETE */,
    0x00 /* END */,
    0x00 /* PAGEDOWN */,
    0x00 /* RIGHT */,
    0x00 /* LEFT */,
    0x00 /* DOWN */,
    0x00 /* UP */,
    0x00 /* NUMLOCK */,

    /* 0x54 */
    '/' /* KP / */,
    '*' /* KP * */,
    '-' /* KP - */,
    '+' /* KP + */,
    '\r' /* KP ENTER */,
    '1' /* KP 1 */,
    '2' /* KP 2 */,
    '3' /* KP 3 */,

    /* 0x5C */
    '4' /* KP 4 */,
    '5' /* KP 5 */,
    '6' /* KP 6 */,
    '7' /* KP 7 */,
    '8' /* KP 8 */,
    '9' /* KP 9 */,
    '0' /* KP 0 */,
    '.' /* KP . */,

    /* 0x64 */
    '\\',
    0x00 /* MENU */,
    0x00 /* POWER */,
    '=' /* KP = */,
    0x00 /* F13 */,
    0x00 /* F14 */,
    0x00 /* F15 */,
    0x00 /* F16 */,

    /* 0x6C */
    0x00 /* F17 */,
    0x00 /* F18 */,
    0x00 /* F19 */,
    0x00 /* F20 */,
    0x00 /* F21 */,
    0x00 /* F22 */,
    0x00 /* F23 */,
    0x00 /* F24 */,

    /* 0x74 */
    0x00 /* EXECUTE */,
    0x00 /* HELP */,
    0x00 /* MENU */,
    0x00 /* SELECT */,
    0x00 /* STOP */,
    0x00 /* AGAIN */,
    0x00 /* UNDO */,
    0x00 /* CUT */,

    /* 0x7C */
    0x00 /* COPY */,
    0x00 /* PASTE */,
    0x00 /* FIND */,
    0x00 /* MUTE */,
};

char scancodes_table[128] = {
    0x00, /*Reserved*/
    0x00, /*Reserved*/
    0x00, /*Reserved*/
    0x00, /*Reserved*/

    /* 0x04 */
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',

    /* 0x0C */
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',

    /* 0x14 */
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',

    /* 0x1C */
    'y',
    'z',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',

    /* 0x24 */
    '7',
    '8',
    '9',
    '0',
    '\r',
    ESC,
    '\b',
    '\t',

    /* 0x2C */
    ' ',
    '-',
    '=',
    '[',
    ']',
    '\\',
    '#',
    ';',

    /* 0x34 */
    '\'',
    '`',
    ',',
    '.',
    '/',

    /* 0x39 */
    0x00 /*CAPSLOCK*/,
    0x00 /* F1 */,
    0x00 /* F2 */,

    /* 0x3C */
    0x00 /* F3 */,
    0x00 /* F4 */,
    0x00 /* F5 */,
    0x00 /* F6 */,
    0x00 /* F7 */,
    0x00 /* F8 */,
    0x00 /* F9 */,
    0x00 /* F10 */,

    /* 0x44 */
    0x00 /* F11 */,
    0x00 /* F12 */,
    0x00 /* PRINTSCREEN */,
    0x00 /* SCROLLLOCK */,
    0x00 /* PAUSE */,
    0x00 /* INSERT */,
    0x00 /* HOME */,
    0x00 /* PAGEUP */,

    /* 0x4C */
    0x00 /* DELETE */,
    0x00 /* END */,
    0x00 /* PAGEDOWN */,
    0x00 /* RIGHT */,
    0x00 /* LEFT */,
    0x00 /* DOWN */,
    0x00 /* UP */,
    0x00 /* NUMLOCK */,

    /* 0x54 */
    '/' /* KP / */,
    '*' /* KP * */,
    '-' /* KP - */,
    '+' /* KP + */,
    '\r' /* KP ENTER */,
    '1' /* KP 1 */,
    '2' /* KP 2 */,
    '3' /* KP 3 */,

    /* 0x5C */
    '4' /* KP 4 */,
    '5' /* KP 5 */,
    '6' /* KP 6 */,
    '7' /* KP 7 */,
    '8' /* KP 8 */,
    '9' /* KP 9 */,
    '0' /* KP 0 */,
    '.' /* KP . */,

    /* 0x64 */
    '\\',
    0x00 /* MENU */,
    0x00 /* POWER */,
    '=' /* KP = */,
    0x00 /* F13 */,
    0x00 /* F14 */,
    0x00 /* F15 */,
    0x00 /* F16 */,

    /* 0x6C */
    0x00 /* F17 */,
    0x00 /* F18 */,
    0x00 /* F19 */,
    0x00 /* F20 */,
    0x00 /* F21 */,
    0x00 /* F22 */,
    0x00 /* F23 */,
    0x00 /* F24 */,

    /* 0x74 */
    0x00 /* EXECUTE */,
    0x00 /* HELP */,
    0x00 /* MENU */,
    0x00 /* SELECT */,
    0x00 /* STOP */,
    0x00 /* AGAIN */,
    0x00 /* UNDO */,
    0x00 /* CUT */,

    /* 0x7C */
    0x00 /* COPY */,
    0x00 /* PASTE */,
    0x00 /* FIND */,
    0x00 /* MUTE */,
};

static char char_with_caps_lock(const char c, const bool caps_lock_engaged) __sdcccall(1) {
  if (!caps_lock_engaged)
    return c;

  if (c >= 'A' && c <= 'Z')
    return c - 'A' + 'a';

  if (c >= 'a' && c <= 'z')
    return c - 'a' + 'A';

  return c;
}

char scancode_to_char(const uint8_t modifier_keys, const uint8_t code, const bool caps_lock_engaged) __sdcccall(1) {
  if ((modifier_keys & (KEY_MOD_LCTRL | KEY_MOD_RCTRL))) {
    if (code >= 4 && code <= 0x1d)
      return code - 3;

    if (code == 0x1F || code == 0x2C) //@ or SPACE
      return 0;

    if (code == 0x2F) // [
      return 27;

    if (code == 0x31) // back slash
      return 28;

    if (code == 0x30) // ]
      return 29;

    if (code == 0x23) //^
      return 30;

    if (code == 0x2D) //_
      return 31;
  }

  if (modifier_keys & (KEY_MOD_LSHIFT | KEY_MOD_RSHIFT))
    return char_with_caps_lock(scancodes_shift_table[code], caps_lock_engaged);

  return char_with_caps_lock(scancodes_table[code], caps_lock_engaged);
}
