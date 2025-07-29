#ifndef __USB_ENUMERATE
#define __USB_ENUMERATE

#include "ch376.h"
#include "protocol.h"
#include "usb_state.h"

#define MAX_CONFIG_SIZE 140

typedef struct {
  uint8_t next_device_address; /* Track the count of installed usb devices*/
  uint8_t storage_count;       /* Track the count of storage devices (scsi, ufi) */
} enumeration_state;

typedef struct __working {
  enumeration_state *state;

  usb_device_type    usb_device;
  device_descriptor  desc;
  uint8_t            config_index;
  uint8_t            interface_count;
  uint8_t            endpoint_count;
  uint8_t            current_device_address;
  device_config_hub *hub_config;

  uint8_t       *ptr;
  device_config *p_current_device;

  union {
    uint8_t           buffer[MAX_CONFIG_SIZE];
    config_descriptor desc;
  } config;

} _working;

extern usb_error read_all_configs(enumeration_state *const state);
extern usb_error enumerate_all_devices(void);

#endif
