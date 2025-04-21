#include "hbios-driver-storage.h"
#include "scsi_driver.h"
#include <hbios.h>
#include <print.h>
#include <string.h>

extern const uint16_t const ch_scsi_fntbl[];

void chscsi_init(void) {
  uint8_t index = 1;
  do {
    usb_device_type t = get_usb_device_type(index);

    if (t == USB_IS_MASS_STORAGE) {
      const uint8_t dev_index = find_storage_dev(); // index == -1 (no more left) should never happen

      hbios_usb_storage_devices[dev_index].drive_index = dev_index + 1;
      hbios_usb_storage_devices[dev_index].usb_device  = index;

      print_string("\r\nUSB: MASS STORAGE @ $");
      print_uint16(index);
      print_string(":$");
      print_uint16(dev_index + 1);
      print_string(" $");
      usb_scsi_init(index);
      dio_add_entry(ch_scsi_fntbl, &hbios_usb_storage_devices[dev_index]);
    }

  } while (++index != MAX_NUMBER_OF_DEVICES + 1);
}
