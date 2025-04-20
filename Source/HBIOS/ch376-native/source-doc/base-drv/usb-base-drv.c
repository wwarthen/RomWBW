#include "usb-base-drv.h"

uint8_t chnative_seek(const uint32_t lba, device_config_storage *const storage_device) __sdcccall(1) {
  storage_device->current_lba = lba;
  return 0;
}
