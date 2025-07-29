#ifndef __USB_CBI_H__
#define __USB_CBI_H__

#include <ch376.h>
#include <dev_transfers.h>

usb_error usb_execute_cbi(device_config *const storage_device,
                          const uint8_t *const cmd,
                          const bool           send,
                          const uint16_t       buffer_size,
                          uint8_t *const       buffer,
                          uint8_t *const       asc);

#endif
