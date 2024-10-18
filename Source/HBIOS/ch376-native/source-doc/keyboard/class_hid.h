#ifndef __CLASS_HID_H__
#define __CLASS_HID_H__

#include "ch376.h"
#include "protocol.h"

#define HID_GET_REPORT   0x01
#define HID_GET_IDLE     0x02
#define HID_GET_PROTOCOL 0x03
#define HID_SET_REPORT   0x09
#define HID_SET_IDLE     0x0A
#define HID_SET_PROTOCOL 0x0B

#define HID_BOOT_PROTOCOL   0x00
#define HID_REPORT_PROTOCOL 0x01

extern usb_error hid_set_protocol(const device_config_keyboard *const dev, const uint8_t protocol) __sdcccall(1);
extern usb_error hid_set_idle(const device_config_keyboard *const dev, const uint8_t duration) __sdcccall(1);
extern usb_error hid_get_input_report(const device_config_keyboard *const dev, uint8_t const *report) __sdcccall(1);

#endif
