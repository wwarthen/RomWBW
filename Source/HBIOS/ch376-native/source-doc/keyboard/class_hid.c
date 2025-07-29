#include "class_hid.h"
#include <stdint.h>

const setup_packet cmd_hid_set = {0x21, HID_SET_PROTOCOL, {0, 0}, {0, 0}, 0};

usb_error hid_set_protocol(const device_config_keyboard *const dev, const uint8_t protocol) __sdcccall(1) {
  setup_packet cmd;
  cmd = cmd_hid_set;

  cmd.bRequest  = HID_SET_PROTOCOL;
  cmd.bValue[0] = protocol;

  return usb_control_transfer(&cmd, NULL, dev->address, dev->max_packet_size);
}

usb_error hid_set_idle(const device_config_keyboard *const dev, const uint8_t duration) __sdcccall(1) {
  setup_packet cmd;
  cmd = cmd_hid_set;

  cmd.bRequest  = HID_SET_IDLE;
  cmd.bValue[0] = duration;

  return usb_control_transfer(&cmd, NULL, dev->address, dev->max_packet_size);
}
