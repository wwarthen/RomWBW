#ifndef __CLASS_UFI2
#define __CLASS_UFI2

#include "ch376.h"
#include "protocol.h"
#include "usb_cbi.h"
#include "usb_state.h"
#include <stdlib.h>

typedef struct {
  uint8_t bASC;
  uint8_t bASCQ;
} ufi_interrupt_status;

typedef struct {
  uint8_t operation_code;
  uint8_t lun; // in top 3 bits
  uint8_t reserved1[5];
  uint8_t allocation_length[2];
  uint8_t reserved[3];
} ufi_read_format_capacities_command;

typedef enum { UNFORMATTED_MEDIA = 1, FORMATTED_MEDIA = 2, NO_MEDIA = 3 } UFI_DESCRIPTOR_CODE;

#define UFI_DESCRIPTOR_CODE_UNFORMATTED_MEDIA 1
#define UFI_DESCRIPTOR_CODE_FORMATTED_MEDIA   2
#define UFI_DESCRIPTOR_CODE_NO_MEDIA          3

typedef struct {
  uint8_t number_of_blocks[4];
  uint8_t descriptor_codex; // UFI_DESCRIPTOR_CODE
  uint8_t block_size[3];
} ufi_format_capacity_descriptor;

typedef struct {
  uint8_t                        reserved1[3];
  uint8_t                        capacity_list_length;
  ufi_format_capacity_descriptor descriptors[4]; // support upto
} ufi_format_capacities_response;

typedef struct {
  uint8_t operation_code;
  uint8_t lun;
  uint8_t reserved[10];
} ufi_test_unit_ready_command;

typedef struct {
  uint8_t operation_code;
  uint8_t lun_and_evpd;
  uint8_t page_code;
  uint8_t reserved3;
  uint8_t allocation_length;
  uint8_t reserved4[7];
} ufi_inquiry_command;

typedef struct {
  uint8_t operation_code;
  uint8_t lun; // top 3 bits
  uint8_t reserved2;
  uint8_t reserved3;
  uint8_t allocation_length;
  uint8_t reserved4[7];
} ufi_request_sense_command;

typedef struct {
  uint8_t error_code;
  uint8_t reserved1;
  uint8_t sense_key; // lower 4 bits
  uint8_t information[4];
  uint8_t additional_length;
  uint8_t reserved3[4];
  uint8_t asc;  // Additional Sense Code
  uint8_t ascq; // Additional Sense Code Qualifier
  uint8_t reserved4[4];
} ufi_request_sense_response;

typedef struct {
  // device_type: identifies the device currently connected to the requested logical unit.
  // 00h Direct-access device (floppy)
  // 1Fh none (no FDD connected to the requested logical unit)
  uint8_t device_type; // lower 5 bits

  // Removable Media Bit: this shall be set to one to indicate removable media.
  uint8_t removable_media; // top bit

  // ANSI Version: must contain a zero to comply with this version of the Specification.
  // ISO/ECMA: These fields shall be zero for the UFI device.
  uint8_t version;

  // Response Data Format: a value of 01h shall be used for UFI device
  uint8_t response_data_format; // lower 4 bits

  // The Additional Length field shall specify the length in bytes of the parameters. If the Allocation Length of the
  // Command Packet is too small to transfer all of the parameters, the Additional Length shall not be adjusted to
  // reflect the truncation. The UFI device shall set this field to 1Fh.
  uint8_t additional_length;
  uint8_t reserved4[3];

  // The Vendor Identification field contains 8 bytes of ASCII data identifying the vendor of the product. The data
  // shall be left aligned within this field.
  char vendor_information[8];

  // The Product Identification field contains 16 bytes of ASCII data as defined by the vendor. The data shall be
  // left-aligned within this field.
  char product_id[16];

  // The Product Revision Level field contains 4 bytes of ASCII data as defined by the vendor.
  char product_revision[4];
} ufi_inquiry_response;

typedef struct {
  uint8_t operation_code; /*0*/
  uint8_t byte_1;         /*1*/
  /* [7:5] lun, [4] dpo, [3] fua, [0]rel_adr*/
  uint8_t lba[4];             /*2, 3, 4, 5*/
  uint8_t reserved2;          /*6*/
  uint8_t transfer_length[2]; /*7, 8*/
  uint8_t reserved3[3];       /*9, 10, 11*/
} ufi_read_write_command;

typedef struct {
  struct {
    uint8_t reserved1;
    /* [7] FOV, [6] Extend, [5] DCRT, [4] SingleTrack, [1] Immediate, [0] Side*/
    uint8_t status;
    uint8_t defect_list_length_msb;
    uint8_t defect_list_length_lsb;
  } defect_list_header;

  ufi_format_capacity_descriptor format_descriptor;
} ufi_format_parameter_list;

#define FMT_DEFECT_STATUS_FOV          0x80
#define FMT_DEFECT_STATUS_EXTEND       0x40
#define FMT_DEFECT_STATUS_DCRT         0x20
#define FMT_DEFECT_STATUS_SINGLE_TRACK 0x10
#define FMT_DEFECT_STATUS_IMMEDIATE    0x02
#define FMT_DEFECT_STATUS_SIDE         0x01

typedef struct {
  uint8_t operation_code; /* 0x04 */
  /* [7:5] lun, [4]format_data, [3]cmp_list, [2:0] defect_list_format*/
  uint8_t status;
  uint8_t track_number;
  uint8_t interleave[2];
  uint8_t reserved1[2];
  uint8_t parameter_list_length[2];
  uint8_t reserved2[3];
} ufi_format_command;

typedef struct {
  uint8_t operation_code; /*0x1D*/
  /* [7:5] lun, [4] pf, [2] self test, [1] def of l [0] unit of l*/
  uint8_t status;
  uint8_t reserved[10];
} ufi_send_diagnostic_command;

extern usb_error ufi_request_sense(device_config *const storage_device, ufi_request_sense_response const *response);

extern usb_error ufi_read_frmt_caps(device_config *const storage_device, ufi_format_capacities_response const *response);

extern usb_error ufi_test_unit_ready(device_config *const storage_device, ufi_request_sense_response const *response);

extern usb_error ufi_inquiry(device_config *const storage_device, ufi_inquiry_response const *response);

extern usb_error ufi_read_write_sector(device_config *const storage_device,
                                       const bool           send,
                                       const uint16_t       sector_number,
                                       const uint8_t        sector_count,
                                       const uint8_t *const buffer,
                                       uint8_t *const       sense_codes);

uint8_t wait_for_device_ready(device_config *const storage_device, uint8_t timeout_counter);

usb_error ufi_format(device_config *const                        storage_device,
                     const uint8_t                               side,
                     const uint8_t                               track_number,
                     const ufi_format_capacity_descriptor *const format);

usb_error ufi_send_diagnostics(device_config *const storage_device);

uint32_t convert_from_msb_first(const uint8_t *const buffer);

extern usb_error ufi_seek(const uint16_t dev_index, const uint32_t lba);

#endif
