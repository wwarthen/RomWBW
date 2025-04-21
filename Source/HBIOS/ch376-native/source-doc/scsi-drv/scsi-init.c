#include "class_scsi.h"
#include "hbios-driver-storage.h"
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
      const uint8_t dev_index                          = find_storage_dev(); // index == -1 (no more left) should never happen
      hbios_usb_storage_devices[dev_index].drive_index = dev_index + 1;
      hbios_usb_storage_devices[dev_index].usb_device  = index;

      print_string("\r\nUSB: MASS STORAGE @ $");
      print_uint16(index);
      print_string(":$");
      print_uint16(dev_index + 1);
      print_string(" $");
      scsi_sense_init(index);
      dio_add_entry(ch_scsi_fntbl, &hbios_usb_storage_devices[dev_index]);
    }

  } while (++index != MAX_NUMBER_OF_DEVICES + 1);
}
