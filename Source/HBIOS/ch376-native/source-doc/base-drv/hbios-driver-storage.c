#include "hbios-driver-storage.h"

hbios_storage_device_t hbios_usb_storage_devices[MAX_NUMBER_OF_DEVICES] = {{NULL}};

uint8_t find_storage_dev(void) {
  for(uint8_t i = 0; i < MAX_NUMBER_OF_DEVICES; i++)
    if (hbios_usb_storage_devices[i].storage_device == NULL)
      return i;

  return -1;
}
