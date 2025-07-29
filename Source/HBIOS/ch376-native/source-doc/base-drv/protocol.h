#ifndef __HW
#define __HW

#include "ch376.h"
#include "dev_transfers.h"
#include "transfers.h"
#include <stdlib.h>

typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
} usb_descriptor_t;

#define USB_DESCR_DEVICE            1
#define USB_DESCR_CONFIGURATION     2
#define USB_DESCR_STRING            3
#define USB_DESCR_INTERFACE         4
#define USB_DESCR_ENDPOINT          5
#define USB_DESCR_DEV_QUALIFIER     6
#define USB_DESCR_OTHER_SPEED       7
#define USB_DESCR_HID               33
#define USB_DESCR_HID_REPORT        34
#define USB_DESCR_HID_PHYSICAL_DESC 35

typedef struct _device_descriptor {
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint16_t bcdUSB;
  uint8_t  bDeviceClass;
  uint8_t  bDeviceSubClass;
  uint8_t  bDeviceProtocol;
  uint8_t  bMaxPacketSize0;
  uint16_t idVendor;
  uint16_t idProduct;
  uint16_t bcdDevice;
  uint8_t  iManufacturer;
  uint8_t  iProduct;
  uint8_t  iSerialNumber;
  uint8_t  bNumConfigurations;
} device_descriptor;

typedef struct _config_descriptor {
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint16_t wTotalLength;
  uint8_t  bNumInterfaces;
  uint8_t  bConfigurationvalue;
  uint8_t  iConfiguration;
  uint8_t  bmAttributes;
  uint8_t  bMaxPower;
} config_descriptor;

typedef struct _interface_descriptor {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bInterfaceNumber;
  uint8_t bAlternateSetting;
  uint8_t bNumEndpoints;
  uint8_t bInterfaceClass;
  uint8_t bInterfaceSubClass;
  uint8_t bInterfaceProtocol;
  uint8_t iInterface;
} interface_descriptor, *p_interface_descriptor;

typedef struct _endpoint_descriptor {
  uint8_t  bLength;
  uint8_t  bDescriptorType;
  uint8_t  bEndpointAddress;
  uint8_t  bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t  bInterval;
} endpoint_descriptor;

extern usb_error usbtrn_get_descriptor(device_descriptor *const buffer);
extern usb_error usbtrn_get_descriptor2(device_descriptor *const buffer, const uint8_t device_address);

extern usb_error usbtrn_get_config_desc(config_descriptor *const buffer,
                                        const uint8_t            config_index,
                                        const uint8_t            buffer_size,
                                        const uint8_t            device_address,
                                        const uint8_t            max_packet_size);

extern usb_error usbtrn_gfull_cfg_desc(const uint8_t  config_index,
                                       const uint8_t  device_address,
                                       const uint8_t  max_packet_size,
                                       const uint8_t  max_buffer_size,
                                       uint8_t *const buffer);

extern usb_error usbtrn_set_config(const uint8_t device_address, const uint8_t max_packet_size, const uint8_t configuration);

extern usb_error usbtrn_set_address(const uint8_t device_address) __z88dk_fastcall;

extern usb_error usbtrn_clr_ep_halt(const uint8_t endpoint_number, const uint8_t device_address, const uint8_t max_packet_size);

#endif
