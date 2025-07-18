#ifndef __SCSI_DRIVER__
#define __SCSI_DRIVER__

#include "class_scsi.h"
#include <ch376.h>
#include <stdint.h>

extern usb_error usb_scsi_init(const uint16_t dev_index);
extern usb_error usb_scsi_read_capacity(const uint16_t dev_index, scsi_read_capacity_result *result);
extern usb_error usb_scsi_read(const uint16_t dev_index, uint8_t *const buffer);
extern usb_error usb_scsi_write(const uint16_t dev_index, uint8_t *const buffer);
extern usb_error usb_scsi_seek(const uint16_t dev_index, const uint32_t lba);

#endif
