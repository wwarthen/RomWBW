#include "usb-base-drv.h"
#include "usb_state.h"

uint8_t scsi_seek(const uint16_t dev_index, const uint32_t lba) {
  device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);

  dev->current_lba = lba;
  return 0;
}
