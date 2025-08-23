#include "ch376.h"

#include "ez80-helpers.h"
#include "print.h"

void ch_command(const uint8_t command) __z88dk_fastcall {
  uint8_t counter = 255;
  while ((CH376_COMMAND_PORT & PARA_STATE_BUSY) && --counter != 0)
    ;

  // if (counter == 0) {
  // It appears that the Ch376 has become blocked
  // command will fail and timeout will eventually be returned by the ch_xxx_wait_int_and_get_status
  // todo consider a return value to allow callers to respond appropriately
  // Experimentation would indicate that USB_RESET_ALL will still work to reset chip
  // return;
  // }

  CH376_COMMAND_PORT = command;
}

extern usb_error ch_wait_and_get_status(const int16_t timeout) __z88dk_fastcall;

usb_error ch_long_get_status(void) { return ch_wait_and_get_status(5000); }

usb_error ch_short_get_status(void) { return ch_wait_and_get_status(100); }

usb_error ch_very_short_status(void) { return ch_wait_and_get_status(10); }

usb_error ch_get_status(void) {
  ch_command(CH_CMD_GET_STATUS);
  uint8_t ch_status = CH376_DATA_PORT;

  if (ch_status >= USB_FILERR_MIN && ch_status <= USB_FILERR_MAX)
    return ch_status;

  if (ch_status == CH_CMD_RET_SUCCESS)
    return USB_ERR_OK;

  if (ch_status == CH_USB_INT_SUCCESS)
    return USB_ERR_OK;

  if (ch_status == CH_USB_INT_CONNECT)
    return USB_INT_CONNECT;

  if (ch_status == CH_USB_INT_DISK_READ)
    return USB_ERR_DISK_READ;

  if (ch_status == CH_USB_INT_DISK_WRITE)
    return USB_ERR_DISK_WRITE;

  if (ch_status == CH_USB_INT_DISCONNECT) {
    ch_cmd_set_usb_mode(5);
    return USB_ERR_NO_DEVICE;
  }

  if (ch_status == CH_USB_INT_BUF_OVER)
    return USB_ERR_DATA_ERROR;

  ch_status &= 0x2F;

  if (ch_status == 0x2A)
    return USB_ERR_NAK;

  if (ch_status == 0x2E)
    return USB_ERR_STALL;

  ch_status &= 0x23;

  if (ch_status == 0x20)
    return USB_ERR_TIMEOUT;

  if (ch_status == 0x23)
    return USB_TOKEN_OUT_OF_SYNC;

  return USB_ERR_UNEXPECTED_STATUS_FROM_HOST;
}

void ch_cmd_reset_all(void) { ch_command(CH_CMD_RESET_ALL); }

inline uint8_t ch_cmd_check_exist(void) {
  uint8_t complement;
  ch_command(CH_CMD_CHECK_EXIST);
  CH376_DATA_PORT = (uint8_t)~0x55;
  delay();
  complement = CH376_DATA_PORT;
  return complement == 0x55;
  // if (complement != 0x55)
  //   return false;

  // ch_command(CH_CMD_CHECK_EXIST);
  // CH376_DATA_PORT = (uint8_t)~0x89;
  // delay();
  // complement = CH376_DATA_PORT;
  // return complement == 0x89;
}

uint8_t ch_probe(void) {
  uint8_t i = 5;
  do {
    if (ch_cmd_check_exist())
      return true;

    delay_short();
  } while (--i != 0);

  return false;
}

usb_error ch_cmd_set_usb_mode(const uint8_t mode) __z88dk_fastcall {
  uint8_t result = 0;

  CH376_COMMAND_PORT = CH_CMD_SET_USB_MODE;
  delay();
  CH376_DATA_PORT = mode;
  delay();

  uint8_t count = 127;

  while (result != CH_CMD_RET_SUCCESS && result != CH_CMD_RET_ABORT && --count != 0) {
    result = CH376_DATA_PORT;
    delay();
  }

  return (result == CH_CMD_RET_SUCCESS) ? USB_ERR_OK : USB_ERR_FAIL;
}

uint8_t ch_cmd_get_ic_version(void) {
  ch_command(CH_CMD_GET_IC_VER);
  return CH376_DATA_PORT & 0x1f;
}

void ch_issue_token(const uint8_t toggle_bit, const uint8_t endpoint, const ch376_pid pid) {
  ch_command(CH_CMD_ISSUE_TKN_X);
  CH376_DATA_PORT = toggle_bit;
  CH376_DATA_PORT = endpoint << 4 | pid;
}

void ch_issue_token_in(const endpoint_param *const endpoint) __z88dk_fastcall {
  ch_issue_token(endpoint->toggle ? 0x80 : 0x00, endpoint->number, CH_PID_IN);
}

void ch_issue_token_out(const endpoint_param *const endpoint) __z88dk_fastcall {
  ch_issue_token(endpoint->toggle ? 0x40 : 0x00, endpoint->number, CH_PID_OUT);
}

void ch_issue_token_out_ep0(void) { ch_issue_token(0x40, 0, CH_PID_OUT); }

void ch_issue_token_in_ep0(void) { ch_issue_token(0x80, 0, CH_PID_IN); }

void ch_issue_token_setup(void) { ch_issue_token(0, 0, CH_PID_SETUP); }

usb_error ch_data_in_transfer(uint8_t *buffer, int16_t buffer_size, endpoint_param *const endpoint) {
  uint8_t   count;
  usb_error result;

  if (buffer_size == 0)
    return USB_ERR_OK;

  USB_MODULE_LEDS = 0x01;
  do {
    ch_issue_token_in(endpoint);

    result = ch_long_get_status();
    CHECK(result);

    endpoint->toggle = !endpoint->toggle;

    count = ch_read_data(buffer);

    if (count == 0) {
      USB_MODULE_LEDS = 0x00;
      return USB_ERR_DATA_ERROR;
    }

    buffer += count;
    buffer_size -= count;
  } while (buffer_size > 0);

  USB_MODULE_LEDS = 0x00;
  return USB_ERR_OK;

done:
  USB_MODULE_LEDS = 0x00;
  return result;
}

// TODO: review: does buffer_size need to be signed?
usb_error ch_data_in_transfer_n(uint8_t *const buffer, uint8_t *const buffer_size, endpoint_param *const endpoint) {
  uint8_t   count;
  usb_error result;

  USB_MODULE_LEDS = 0x01;

  ch_issue_token_in(endpoint);

  CHECK(ch_long_get_status());

  endpoint->toggle = !endpoint->toggle;

  count = ch_read_data(buffer);

  *buffer_size = count;

  USB_MODULE_LEDS = 0x00;

  return USB_ERR_OK;
done:
  USB_MODULE_LEDS = 0x00;
  return result;
}

usb_error ch_data_out_transfer(const uint8_t *buffer, int16_t buffer_length, endpoint_param *const endpoint) {
  usb_error     result;
  const uint8_t number          = endpoint->number;
  const uint8_t max_packet_size = calc_max_packet_size(endpoint->max_packet_sizex);

  USB_MODULE_LEDS = 0x02;

  while (buffer_length > 0) {
    const uint8_t size = max_packet_size < buffer_length ? max_packet_size : buffer_length;
    buffer             = ch_write_data(buffer, size);
    buffer_length -= size;
    ch_issue_token_out(endpoint);

    CHECK(ch_long_get_status());

    endpoint->toggle = !endpoint->toggle;
  }

  USB_MODULE_LEDS = 0x00;
  return USB_ERR_OK;

done:
  USB_MODULE_LEDS = 0x00;
  return result;
}

void ch_set_usb_address(const uint8_t device_address) __z88dk_fastcall {
  ch_command(CH_CMD_SET_USB_ADDR);
  CH376_DATA_PORT = device_address;
}
