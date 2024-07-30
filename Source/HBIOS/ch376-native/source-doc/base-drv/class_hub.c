#include "class_hub.h"
#include "protocol.h"
#include "usb_state.h"

const setup_packet cmd_get_hub_descriptor = {RT_DEVICE_TO_HOST | RT_CLASS | RT_DEVICE, 6, {0, 0x29}, {0, 0}, 8};

usb_error hub_get_descriptor(const device_config_hub *const hub_config, hub_descriptor *const hub_description) __sdcccall(1) {
  return usb_control_transfer(&cmd_get_hub_descriptor, hub_description, hub_config->address, hub_config->max_packet_size);
}
