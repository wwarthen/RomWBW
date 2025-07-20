#include "hbios-driver-storage.h"

hbios_storage_device_t hbios_usbstore_devs[MAX_NUMBER_OF_DEVICES] = {{NULL}};

uint8_t find_storage_dev(void) {
  for (uint8_t i = 0; i < MAX_NUMBER_OF_DEVICES; i++)
    if (hbios_usbstore_devs[i].drive_index == 0)
      return i;

  return -1;
}
