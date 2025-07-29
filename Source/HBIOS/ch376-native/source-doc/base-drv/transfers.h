/**
 * @file transfer.h
 * @author Dean Netherton
 * @brief A simplest implementation of common usb transfer functions, based on the CH376S chip
 * @details For a basic walkthrough of the usb protocol see https://www.beyondlogic.org/usbnutshell/usb1.shtml
 * @version 1.0
 * @date 2023-09-22
 *
 * @copyright Copyright (c) 2023
 *
 */

#ifndef __USB_TRANSFERS
#define __USB_TRANSFERS

#include "ch376.h"
#include <stdlib.h>

#define GET_STATUS      0
#define CLEAR_FEATURE   1
#define SET_FEATURE     3
#define GET_DESCRIPTOR  6
#define SET_DESCRIPTOR  7
#define CLEAR_TT_BUFFER 8
#define RESET_TT        9
#define GET_TT_STATE    10
#define CSTOP_TT        11

#define FEAT_PORT_POWER                    8
#define FEAT_PORT_RESET                    4
#define HUB_FEATURE_PORT_CONNECTION_CHANGE 16
#define FEAT_PORT_ENABLE_CHANGE            17
#define FEAT_PORT_RESET_CHANGE             20

// HUB_FEATURE_PORT_CONNECTION          = 0,
// HUB_FEATURE_PORT_ENABLE              = 1,
// HUB_FEATURE_PORT_SUSPEND             = 2,
// HUB_FEATURE_PORT_OVER_CURRENT        = 3,
// HUB_FEATURE_PORT_RESET               = 4,

// HUB_FEATURE_PORT_POWER               = 8,
// HUB_FEATURE_PORT_LOW_SPEED           = 9,

// HUB_FEATURE_PORT_CONNECTION_CHANGE   = 16,
// HUB_FEATURE_PORT_ENABLE_CHANGE       = 17,
// HUB_FEATURE_PORT_SUSPEND_CHANGE      = 18,
// HUB_FEATURE_PORT_OVER_CURRENT_CHANGE = 19,
// HUB_FEATURE_PORT_RESET_CHANGE        = 20,
// HUB_FEATURE_PORT_TEST                = 21,
// HUB_FEATURE_PORT_INDICATOR           = 22

#define RT_HOST_TO_DEVICE 0b00000000
#define RT_DEVICE_TO_HOST 0b10000000
#define RT_STANDARD       0b00000000
#define RT_CLASS          0b00100000
#define RT_VENDOR         0b01000000
#define RT_DEVICE         0b00000000
#define RT_INTERFACE      0b00000001
#define RT_ENDPOINT       0b00000010
#define RT_OTHER          0b00000011

typedef struct _setup_packet {
  uint8_t  bmRequestType;
  uint8_t  bRequest;
  uint8_t  bValue[2];
  uint8_t  bIndex[2];
  uint16_t wLength;
} setup_packet;

enum libusb_request_type {
  LIBUSB_REQUEST_TYPE_STANDARD = (0x00 << 5),
  LIBUSB_REQUEST_TYPE_CLASS    = (0x01 << 5),
  LIBUSB_REQUEST_TYPE_VENDOR   = (0x02 << 5),
  LIBUSB_REQUEST_TYPE_RESERVED = (0x03 << 5),
};

enum libusb_request_recipient {
  LIBUSB_RECIPIENT_DEVICE    = 0x00,
  LIBUSB_RECIPIENT_INTERFACE = 0x01,
  LIBUSB_RECIPIENT_ENDPOINT  = 0x02,
  LIBUSB_RECIPIENT_OTHER     = 0x03,
};

enum libusb_endpoint_direction {
  LIBUSB_ENDPOINT_IN  = 0x80,
  LIBUSB_ENDPOINT_OUT = 0x00,
};

extern usb_error usb_control_transfer(const setup_packet *const cmd_packet,
                                      void *const               buffer,
                                      const uint8_t             device_address,
                                      const uint8_t             max_packet_size);

extern usb_error
usb_data_in_transfer(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint);

extern usb_error
usb_data_in_transfer_n(uint8_t *buffer, uint8_t *const buffer_size, const uint8_t device_address, endpoint_param *const endpoint);

extern usb_error
usb_data_out_transfer(const uint8_t *buffer, uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint);

#endif
