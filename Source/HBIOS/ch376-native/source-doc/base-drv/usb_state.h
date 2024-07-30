#ifndef __USB_STATE
#define __USB_STATE

#include "ch376.h"
#include "protocol.h"
#include <stdlib.h>

#define MAX_NUMBER_OF_DEVICES     6
#define DEVICE_CONFIG_STRUCT_SIZE sizeof(device_config_storage) /* Assumes is largest struct */

typedef struct __usb_state {
  uint8_t active : 1; /* if true, a usb operation/interrupt handler is active, prevent re-entrant */
  uint8_t reserved : 7;
  uint8_t count_of_detected_usb_devices;
  uint8_t device_configs[DEVICE_CONFIG_STRUCT_SIZE * MAX_NUMBER_OF_DEVICES];

  uint8_t device_configs_end; // always zero to mark end
} _usb_state;

extern device_config *find_first_free(void);
extern device_config *first_device_config(const _usb_state *const p) __sdcccall(1);
extern device_config *next_device_config(const _usb_state *const usb_state, const device_config *const p) __sdcccall(1);
extern device_config *find_device_config(const usb_device_type requested_type);

extern device_config *get_usb_device_config(const uint8_t device_index) __sdcccall(1);

#endif
