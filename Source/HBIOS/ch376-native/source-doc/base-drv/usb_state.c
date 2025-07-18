#include "usb_state.h"
#include "ch376.h"
#include "work-area.h"

extern device_config *first_device_config(const _usb_state *const p) __sdcccall(1);
extern device_config *next_device_config(const _usb_state *const usb_state, const device_config *const p) __sdcccall(1);

const uint8_t device_config_sizes[_USB_LAST_DEVICE_TYPE] = {
    0,                              /* USB_NOT_SUPPORTED   = 0 */
    sizeof(device_config_storage),  /* USB_IS_FLOPPY       = 1 */
    sizeof(device_config_storage),  /* USB_IS_MASS_STORAGE = 2 */
    sizeof(device_config),          /* USB_IS_CDC          = 3 */
    sizeof(device_config_keyboard), /* USB_IS_KEYBOARD     = 4 */
};

// always usb work area
uint8_t count_of_devices(void) __sdcccall(1) {
  _usb_state *const p = get_usb_work_area();

  uint8_t count = 0;

  const device_config *p_config = first_device_config(p);
  while (p_config) {
    const uint8_t type = p_config->type;

    if (type != USB_IS_HUB && type)
      count++;
    ;

    p_config = next_device_config(p, p_config);
  };

  return count;
}

// always search in boot
device_config *find_first_free(void) {
  _usb_state *const boot_state = get_usb_work_area();

  uint8_t        c = 0;
  device_config *p = first_device_config(boot_state);
  while (p) {
    if (p->type == 0)
      return p;

    p = next_device_config(boot_state, p);
  }

  return NULL;
}

device_config *first_device_config(const _usb_state *const p) __sdcccall(1) { return (device_config *)&p->device_configs[0]; }

device_config *next_device_config(const _usb_state *const usb_state, const device_config *const p) __sdcccall(1) {
  if (p->type == 0)
    return NULL;

  const uint8_t size = device_config_sizes[p->type];
  // TODO: bug when size is zero we dont increment the pointer
  // but if we abort on size 0 - we fail to pick up other devices???
  // we should not get size of 0 unless the size entry is missing
  //  if (size == 0)
  //    return NULL;

  const uint8_t       *_p     = (uint8_t *)p;
  device_config *const result = (device_config *)(_p + size);

  if (result >= (device_config *)&usb_state->device_configs_end)
    return NULL;

  return result;
}

device_config *get_usb_device_config(const uint8_t device_index) __sdcccall(1) {
  const _usb_state *const usb_state = get_usb_work_area();

  uint8_t counter = 1;

  for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
    if (p->type != USB_NOT_SUPPORTED) {
      if (counter == device_index)
        return p;
      counter++;
    }
  }

  return NULL; // is not a usb device
}

usb_device_type usb_get_device_type(const uint16_t dev_index) {
  const device_config *dev = get_usb_device_config(dev_index);

  if (dev == NULL)
    return -1;

  return dev->type;
}
