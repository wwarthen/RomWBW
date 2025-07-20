#include "hbios-driver-storage.h"
#include <hbios.h>
#include <print.h>
#include <usb_state.h>

extern const uint16_t const ch_ufi_fntbl[];

void chufi_init(void) {
  uint8_t index = 1;

  do {
    usb_device_type t = usb_get_device_type(index);

    if (t == USB_IS_FLOPPY) {
      const uint8_t dev_index = find_storage_dev(); // dev_index == -1 (no more left) should never happen

      hbios_usbstore_devs[dev_index].drive_index = dev_index + 1;
      hbios_usbstore_devs[dev_index].usb_device  = index;

      print_string("\r\nUSB: FLOPPY @ $");
      print_uint16(index);
      print_string(":$");
      print_uint16(dev_index);
      print_string(" $");
      dio_add_entry(ch_ufi_fntbl, &hbios_usbstore_devs[dev_index]);
    }

  } while (++index != MAX_NUMBER_OF_DEVICES + 1);
}
