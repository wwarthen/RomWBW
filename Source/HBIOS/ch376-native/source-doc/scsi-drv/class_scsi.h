#ifndef __CLASS_SCSI
#define __CLASS_SCSI

#include <protocol.h>

typedef struct {
  uint8_t  dCBWSignature[4];
  uint16_t dCBWTag[2];
  uint32_t dCBWDataTransferLength;
  uint8_t  bmCBWFlags;
  uint8_t  bCBWLUN;
  uint8_t  bCBWCBLength;
} _scsi_command_block_wrapper;

typedef struct {
  uint8_t operation_code;
  uint8_t lun;
  uint8_t reserved1;
  uint8_t reserved2;
  uint8_t allocation_length;
  uint8_t reserved3;
  uint8_t pad[6];
} _scsi_packet_request_sense;

typedef struct {
  _scsi_command_block_wrapper cbw;
  _scsi_packet_request_sense  request_sense;
} cbw_scsi_request_sense;

typedef struct {
  uint8_t operation_code;

  uint8_t IMMED : 1;
  uint8_t reserved : 7;

  uint8_t reserved2;

  uint8_t power_condition_modifier : 4;
  uint8_t reserved3 : 4;

  uint8_t start : 1;
  uint8_t loej : 1;
  uint8_t no_flush : 1;
  uint8_t reserved4 : 1;
  uint8_t power_condition : 4;

  uint8_t control;
} _scsi_packet_eject;

typedef struct {
  _scsi_command_block_wrapper cbw;
  _scsi_packet_eject          eject;
} cbw_scsi_eject;

typedef struct {
  uint8_t operation_code;
  uint8_t lun;
  uint8_t reserved1;
  uint8_t reserved2;
  uint8_t reserved3;
  uint8_t reserved4;
  uint8_t pad[6];
} _scsi_packet_test;

typedef struct {
  _scsi_command_block_wrapper cbw;
  _scsi_packet_test           test;
} cbw_scsi_test;

typedef struct {
  uint8_t operation_code;
  uint8_t lun;
  uint8_t reserved[8];
  uint8_t pad[2];
} _scsi_read_capacity;

typedef struct {
  _scsi_command_block_wrapper cbw;
  _scsi_read_capacity         read_capacity;
} cbw_scsi_read_capacity;

typedef struct __scsi_packet_inquiry { // contains information about a specific device
  uint8_t operation_code;
  uint8_t lun;
  uint8_t reserved1;
  uint8_t reserved2;
  uint8_t allocation_length;
  uint8_t reserved3;
  uint8_t pad[6];
} _scsi_packet_inquiry;

typedef struct {
  _scsi_command_block_wrapper cbw;
  _scsi_packet_inquiry        inquiry;
} cbw_scsi_inquiry;

typedef struct {
  uint8_t device_type : 5;
  uint8_t device_type_qualifier : 3;
  uint8_t device_type_modifier : 7;
  uint8_t removable_media : 1;
  union {
    uint8_t versions;
    struct {
      uint8_t ansi_version : 3;
      uint8_t ecma_version : 3;
      uint8_t iso_version : 2;
    };
  };
  uint8_t response_data_format : 4;
  uint8_t hi_support : 1;
  uint8_t norm_aca : 1;
  uint8_t terminate_task : 1;
  uint8_t aerc : 1;
  uint8_t additional_length;
  uint8_t reserved;
  uint8_t addr16 : 1;
  uint8_t addr32 : 1;
  uint8_t ack_req_q : 1;
  uint8_t medium_changer : 1;
  uint8_t multi_port : 1;
  uint8_t reserved_bit2 : 1;
  uint8_t enclosure_services : 1;
  uint8_t reserved_bit3 : 1;
  uint8_t soft_reset : 1;
  uint8_t command_queue : 1;
  uint8_t transfer_disable : 1;
  uint8_t linked_commands : 1;
  uint8_t synchronous : 1;
  uint8_t wide16_bit : 1;
  uint8_t wide32_bit : 1;
  uint8_t relative_addressing : 1;
  uint8_t vendor_information[8];
  uint8_t product_id[16];
  uint8_t product_revision[4];
  uint8_t vendor_specific[20];
  uint8_t reserved3[40];
} scsi_inquiry_result;

typedef struct __scsi_command_status_wrapper {
  uint8_t  dCSWSignature[4];
  uint16_t dCSWTag[2];
  uint8_t  dCSWDataResidue[4];
  uint8_t  bCSWStatus;
} _scsi_command_status_wrapper;

typedef struct {
  uint8_t number_of_blocks[4];
  uint8_t block_size[4];
} scsi_read_capacity_result;

typedef struct {
  uint8_t error_code : 7;
  uint8_t valid : 1;
  uint8_t segment_number;
  uint8_t sense_key : 4;
  uint8_t reserved : 1;
  uint8_t incorrect_length : 1;
  uint8_t end_of_media : 1;
  uint8_t file_mark : 1;
  uint8_t information[4];
  uint8_t additional_sense_length;
  uint8_t command_specific_information[4];
  uint8_t additional_sense_code;
  uint8_t additional_sense_code_qualifier;
  uint8_t field_replaceable_unit_code;
  uint8_t sense_key_specific[3];
} scsi_sense_result;

typedef struct {
  uint8_t operation_code;
  uint8_t lun;
  uint8_t lba[4]; // high-endian block number
  uint8_t reserved1;
  uint8_t transfer_len[2]; // high-endian in blocks of block_len (see scsi_capacity)
  uint8_t reserved2;
  uint8_t pad[2];
} _scsi_packet_read_write;

typedef struct {
  _scsi_command_block_wrapper cbw;
  _scsi_packet_read_write     scsi_cmd;
} cbw_scsi_read_write;

extern _scsi_command_block_wrapper scsi_cmd_blk_wrap;

extern usb_error do_scsi_cmd(device_config_storage *const       dev,
                             _scsi_command_block_wrapper *const cbw,
                             void *const                        send_receive_buffer,
                             const bool                         send);

extern usb_error scsi_test(device_config_storage *const dev);

extern usb_error scsi_request_sense(device_config_storage *const dev, scsi_sense_result *const sens_result);

#endif
