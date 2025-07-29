
#ifndef __CH376
#define __CH376

#include "ch376inc.h"
#include "delay.h"
#include <stdint.h>
#include <stdlib.h>

typedef enum {
  USB_ERR_OK                          = 0,
  USB_ERR_NAK                         = 1,
  USB_ERR_STALL                       = 2,
  USB_ERR_TIMEOUT                     = 3,
  USB_ERR_DATA_ERROR                  = 4,
  USB_ERR_NO_DEVICE                   = 5,
  USB_ERR_PANIC_BUTTON_PRESSED        = 6,
  USB_TOKEN_OUT_OF_SYNC               = 7,
  USB_ERR_UNEXPECTED_STATUS_FROM_HOST = 8,
  USB_ERR_CODE_EXCEPTION              = 9,
  USB_ERR_MEDIA_CHANGED               = 10,
  USB_ERR_MEDIA_NOT_PRESENT           = 11,
  USB_ERR_CH376_BLOCKED               = 12,
  USB_ERR_CH376_TIMEOUT               = 13,
  USB_ERR_FAIL                        = 14,
  USB_ERR_MAX                         = 14,
  USB_ERR_OTHER                       = 15,
  USB_ERR_DISK_READ                   = 0x1D,
  USB_ERR_DISK_WRITE                  = 0x1E,
  USB_FILERR_MIN                      = 0x41,
  USB_ERR_OPEN_DIR                    = 0x41,
  USB_ERR_MISS_FILE                   = 0x42,
  USB_FILERR_MAX                      = 0xB4,
  USB_INT_CONNECT                     = 0x81,
  USB_BAD_ADDRESS                     = 0x82,
  USB_ERR_OUT_OF_MEMORY               = 0x83,
  USB_ERR_BUFF_TO_LARGE               = 0x84,
  USB_ERROR_DEVICE_NOT_FOUND          = 0x85,
} usb_error;

typedef enum { CH_NAK_RETRY_DONT = 0b00, CH_NAK_RETRY_INDEFINITE = 0b10, CH_NAK_RETRY_3S = 0b11 } ch_nak_retry_type;

typedef enum {
  USB_NOT_SUPPORTED   = 0,
  USB_IS_FLOPPY       = 1,
  USB_IS_MASS_STORAGE = 2,
  USB_IS_CDC          = 3,
  USB_IS_KEYBOARD     = 4,
  USB_IS_UNKNOWN      = 6,
  _USB_LAST_DEVICE_TYPE,
  USB_IS_HUB = 15

} usb_device_type; // 4 bits only

typedef enum { ENDPOINT_BULK_OUT = 0, ENDPOINT_BULK_IN = 1, ENDPOINT_INTERRUPT_IN = 2 } usb_endpoint_type;

extern int printf(const char *msg, ...);

#if STACK_TRACE_ENABLED

#define trace_printf printf

#define CHECK(fn)                                                                                                                  \
  {                                                                                                                                \
    result = fn;                                                                                                                   \
    if (result != USB_ERR_OK && result != USB_ERR_STALL) {                                                                         \
      if (result != USB_TOKEN_OUT_OF_SYNC)                                                                                         \
        printf("Error: %s:%d %d\r\n", __FILE__, __LINE__, result);                                                                 \
      return result;                                                                                                               \
    }                                                                                                                              \
  }

#define RETURN_CHECK(fn)                                                                                                           \
  {                                                                                                                                \
    result = fn;                                                                                                                   \
    if (result != USB_ERR_OK && result != USB_ERR_STALL) {                                                                         \
      if (result != USB_TOKEN_OUT_OF_SYNC)                                                                                         \
        printf("Error: %s:%d %d\r\n", __FILE__, __LINE__, result);                                                                 \
      return result;                                                                                                               \
    }                                                                                                                              \
    return result;                                                                                                                 \
  }

#define TRACE_USB_ERROR(result)                                                                                                    \
  {                                                                                                                                \
    if (result != USB_ERR_OK) {                                                                                                    \
      printf("USB: %s:%d %d\r\n", __FILE__, __LINE__, result);                                                                     \
    }                                                                                                                              \
  }

#else

#define trace_printf(...)

#define CHECK(fn)                                                                                                                  \
  {                                                                                                                                \
    result = fn;                                                                                                                   \
    if (result != USB_ERR_OK)                                                                                                      \
      goto done;                                                                                                                   \
  }

#define RETURN_CHECK(fn)                                                                                                           \
  {                                                                                                                                \
    result = fn;                                                                                                                   \
    goto done;                                                                                                                     \
  }

#define TRACE_USB_ERROR(result)

#endif

#define calc_max_packet_sizex(packet_size) (packet_size & 0x3FF)
#define calc_max_packet_size(packet_sizex) packet_sizex

typedef struct {
  uint8_t  toggle : 1;
  uint8_t  number : 3;
  uint16_t max_packet_sizex : 10;
} endpoint_param;

#define CH_SPEED_FULL                                                                                                              \
  0                         /* 12Mbps full speed FullSpeed ​​(default value)                                                   \
                             */
#define CH_SPEED_LOW_FREQ 1 /* 1.5Mbps (modify frequency only) */
#define CH_SPEED_LOW      2 /* 1.5Mbps low speed LowSpeed */

#define CH_MODE_HOST_RESET 7
#define CH_MODE_HOST       6

typedef enum _ch376_pid { CH_PID_SETUP = DEF_USB_PID_SETUP, CH_PID_IN = DEF_USB_PID_IN, CH_PID_OUT = DEF_USB_PID_OUT } ch376_pid;

extern __sfr __banked CH376_DATA_PORT;
extern __sfr __banked CH376_COMMAND_PORT;

extern __sfr __banked USB_MODULE_LEDS;

extern void delay_20ms(void);
extern void delay_short(void);
extern void delay_medium(void);

extern void           ch_command(const uint8_t command) __z88dk_fastcall;
extern usb_error      ch_get_status(void);
extern usb_error      ch_long_get_status(void);
extern usb_error      ch_short_get_status(void);
extern usb_error      ch_very_short_status(void);
extern uint8_t        ch_read_data(uint8_t *buffer) __sdcccall(1);
extern void           ch_cmd_reset_all(void);
extern uint8_t        ch_probe(void);
extern usb_error      ch_cmd_set_usb_mode(const uint8_t mode) __z88dk_fastcall;
extern uint8_t        ch_cmd_get_ic_version(void);
extern const uint8_t *ch_write_data(const uint8_t *buffer, uint8_t length);

extern void ch_set_usb_address(const uint8_t device_address) __z88dk_fastcall;

extern usb_error ch_control_transfer_request_descriptor(const uint8_t descriptor_type) __z88dk_fastcall;
extern usb_error ch_control_transfer_set_address(const uint8_t device_address) __z88dk_fastcall;
extern usb_error ch_control_transfer_set_config(const uint8_t config_value) __z88dk_fastcall;
extern usb_error ch_data_in_transfer(uint8_t *buffer, int16_t data_length, endpoint_param *const endpoint);
extern usb_error ch_data_in_transfer_n(uint8_t *buffer, uint8_t *const buffer_size, endpoint_param *const endpoint);
extern usb_error ch_data_out_transfer(const uint8_t *buffer, int16_t buffer_length, endpoint_param *const endpoint);

inline void ch_configure_nak_retry(const ch_nak_retry_type retry, const uint8_t number_of_retries) {
  ch_command(CH_CMD_WRITE_VAR8);
  CH376_DATA_PORT = CH_VAR_RETRY_TIMES;
  CH376_DATA_PORT = retry << 6 | (number_of_retries & 0x1F);
}

#define ch_configure_nak_retry_indefinite() ch_configure_nak_retry(CH_NAK_RETRY_INDEFINITE, 0x1F)
#define ch_configure_nak_retry_disable()    ch_configure_nak_retry(CH_NAK_RETRY_DONT, 0x1F)
#define ch_configure_nak_retry_3s()         ch_configure_nak_retry(CH_NAK_RETRY_3S, 0x1F)

extern void ch_issue_token_setup(void);
extern void ch_issue_token_out_ep0(void);
extern void ch_issue_token_in_ep0(void);

#endif
