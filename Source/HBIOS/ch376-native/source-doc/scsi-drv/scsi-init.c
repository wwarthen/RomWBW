#include "class_scsi.h"
#include <ch376.h>
#include <enumerate.h>
#include <hbios.h>
#include <print.h>
#include <string.h>
#include <usb-base-drv.h>
#include <work-area.h>
#include <z80.h>

extern const uint16_t const ch_scsi_fntbl[];

void chscsi_init(void) {
  uint8_t index = 1;
  do {
    device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);

    if (storage_device == NULL)
      break;

    const usb_device_type t = storage_device->type;

    if (t == USB_IS_MASS_STORAGE) {
      storage_device->drive_index = storage_count++;
      scsi_sense_init(storage_device);
      dio_add_entry(ch_scsi_fntbl, storage_device);
    }

  } while (++index != MAX_NUMBER_OF_DEVICES + 1);

  if (storage_count == 0)
    return;

  print_device_mounted(" STORAGE DEVICE$", storage_count);
}
