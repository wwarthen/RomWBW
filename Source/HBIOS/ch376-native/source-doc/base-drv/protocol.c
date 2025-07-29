/**
 * @file protocol.c
 * @author Dean Netherton
 * @brief A simplest implementation of common usb transfer functions, based on the CH376S chip
 * @details For a basic walkthrough of the usb protocol see https://www.beyondlogic.org/usbnutshell/usb1.shtml
 * @version 1.0
 * @date 2023-09-22
 *
 * @copyright Copyright (c) 2023
 *
 */

#include "protocol.h"
#include "ch376.h"
#include "delay.h"
#include <stdlib.h>

#include "ez80-helpers.h"
#include "print.h"

const setup_packet cmd_get_dev_descriptr = {0x80, 6, {0, 1}, {0, 0}, 8};

/**
 * @brief Issue GET_DESCRIPTOR request to retrieve the device descriptor for usb device at address 0
 *
 * @param buffer the buffer to store the device descriptor in
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error usbtrn_get_descriptor(device_descriptor *const buffer) {
  usb_error    result;
  setup_packet cmd;
  cmd         = cmd_get_dev_descriptr;
  cmd.wLength = 8;

  result = usb_control_transfer(&cmd, (uint8_t *)buffer, 0, 8);

  CHECK(result);

  cmd         = cmd_get_dev_descriptr;
  cmd.wLength = 18;
  result      = usb_control_transfer(&cmd, (uint8_t *)buffer, 0, buffer->bMaxPacketSize0);

  RETURN_CHECK(result);

done:
  return result;
}

/**
 * @brief Issue GET_DESCRIPTOR request to retrieve the device descriptor for usb device at the specified address
 *
 * @param buffer the buffer to store the device descriptor in
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error usbtrn_get_descriptor2(device_descriptor *const buffer, const uint8_t device_address) {
  usb_error result;

  setup_packet cmd;
  cmd         = cmd_get_dev_descriptr;
  cmd.wLength = 8;

  result = usb_control_transfer(&cmd, (uint8_t *)buffer, device_address, 8);

  CHECK(result);

  cmd         = cmd_get_dev_descriptr;
  cmd.wLength = 18;
  RETURN_CHECK(usb_control_transfer(&cmd, (uint8_t *)buffer, device_address, buffer->bMaxPacketSize0));
done:
  return result;
}

const setup_packet cmd_set_device_address = {0x00, 5, {0, 0}, {0, 0}, 0};

/**
 * @brief configure device at address 0 to be assigned a new device address
 *
 * @param device_address the new device address
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error usbtrn_set_address(const uint8_t device_address) __z88dk_fastcall {
  setup_packet cmd;
  cmd           = cmd_set_device_address;
  cmd.bValue[0] = device_address;

  return usb_control_transfer(&cmd, 0, 0, 0);
}

const setup_packet cmd_set_configuration = {0x00, 9, {0, 0}, {0, 0}, 0};

/**
 * @brief configure device at address 0 to be assigned a new configuration
 *
 * @param config the device to be configured
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error usbtrn_set_config(const uint8_t device_address, const uint8_t max_packet_size, const uint8_t configuration) {
  setup_packet cmd;
  cmd           = cmd_set_configuration;
  cmd.bValue[0] = configuration;

  return usb_control_transfer(&cmd, 0, device_address, max_packet_size);
}

const setup_packet cmd_get_config_desc = {0x80, 6, {0, 2}, {0, 0}, 0};

/**
 * @brief request the config descriptor for the specific config index of the specified device
 *
 * @param buffer the buffer to store the config descriptor in
 * @param config_index the index of the config descriptor to retrieve
 * @param buffer_size the size of the buffer
 * @param device_address the usb address of the device
 * @param max_packet_size the max packet size for control transfers (endpoint 0)
 * @return usb_error USB_ERR_OK if all good, otherwise specific error code
 */
usb_error usbtrn_get_config_desc(config_descriptor *const buffer,
                                 const uint8_t            config_index,
                                 const uint8_t            buffer_size,
                                 const uint8_t            device_address,
                                 const uint8_t            max_packet_size) {
  setup_packet cmd;
  cmd           = cmd_get_config_desc;
  cmd.bValue[0] = config_index;
  cmd.wLength   = (uint16_t)buffer_size;

  return usb_control_transfer(&cmd, (uint8_t *)buffer, device_address, max_packet_size);
}

usb_error usbtrn_gfull_cfg_desc(const uint8_t  config_index,
                                const uint8_t  device_address,
                                const uint8_t  max_packet_size,
                                const uint8_t  max_buffer_size,
                                uint8_t *const buffer) {
  usb_error result;

  CHECK(usbtrn_get_config_desc((config_descriptor *)buffer, config_index, sizeof(config_descriptor), device_address,
                               max_packet_size));

  uint8_t max_length = ((config_descriptor *)buffer)->wTotalLength;
  if (max_length > max_buffer_size)
    max_length = max_buffer_size;

  CHECK(usbtrn_get_config_desc((config_descriptor *)buffer, config_index, max_length, device_address, max_packet_size));

  return USB_ERR_OK;
done:
  return result;
}

const setup_packet usb_cmd_clr_ep_halt = {2, 1, {0, 0}, {255, 0}, 0}; //    ;byte 4 is the endpoint to be cleared

usb_error usbtrn_clr_ep_halt(const uint8_t endpoint_number, const uint8_t device_address, const uint8_t max_packet_size) {
  setup_packet cmd;
  cmd           = usb_cmd_clr_ep_halt;
  cmd.bIndex[0] = endpoint_number;

  return usb_control_transfer(&cmd, (uint8_t *)0, device_address, max_packet_size);
}
