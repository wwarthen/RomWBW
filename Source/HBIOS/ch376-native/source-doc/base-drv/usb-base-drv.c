#include "usb-base-drv.h"

/* The total number of mounted devices (scsi, ufi and keyboard) */
// uint8_t usb_device_count = 0;

uint8_t chnative_seek(const uint32_t lba, device_config_storage *const storage_device) __sdcccall(1) {
  storage_device->current_lba = lba;
  return 0;
}
