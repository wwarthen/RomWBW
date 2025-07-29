#include "usb_cbi.h"
#include "dev_transfers.h"
#include "protocol.h"
#include <ch376.h>
#include <critical-section.h>

setup_packet cbi2_adsc = {0x21, 0, {0, 0}, {255, 0}, 12}; // ;4th byte is interface number

// was no clear
usb_error usb_execute_cbi(device_config *const storage_device,
                          const uint8_t *const cmd,
                          const bool           send,
                          const uint16_t       buffer_size,
                          uint8_t *const       buffer,
                          uint8_t *const       sense_codes) {
  usb_error     result;
  const uint8_t interface_number = storage_device->interface_number;

  setup_packet adsc;
  adsc           = cbi2_adsc;
  adsc.bIndex[0] = interface_number;

  critical_begin();

  result = usbdev_control_transfer(storage_device, &adsc, (uint8_t *const)cmd);

  if (result == USB_ERR_STALL) {
    if (sense_codes != NULL)
      usbdev_dat_in_trnsfer(storage_device, sense_codes, 2, ENDPOINT_INTERRUPT_IN);

    result = USB_ERR_STALL;
    goto done;
  }

  if (result != USB_ERR_OK) {
    TRACE_USB_ERROR(result);
    goto done;
  }

  if (send) {
    result = usbdev_blk_out_trnsfer(storage_device, buffer, buffer_size);

    if (result != USB_ERR_OK) {
      TRACE_USB_ERROR(result);
      goto done;
    }
  } else {
    result = usbdev_dat_in_trnsfer(storage_device, buffer, buffer_size, ENDPOINT_BULK_IN);

    if (result != USB_ERR_OK) {
      TRACE_USB_ERROR(result);
      goto done;
    }
  }

  if (sense_codes != NULL) {
    result = usbdev_dat_in_trnsfer(storage_device, sense_codes, 2, ENDPOINT_INTERRUPT_IN);

    if (result != USB_ERR_OK) {
      TRACE_USB_ERROR(result);
      // goto done;
    }
  }

done:
  critical_end();

  return result;
}
