#ifndef __CLASS_HUB
#define __CLASS_HUB

#include "ch376.h"
#include "protocol.h"
#include <stdlib.h>

/*
wHubCharacteristics:
  D1...D0: Logical Power Switching Mode
    00: Ganged power switching (all ports power at once)
    01: Individual port power switching
    1X: Reserved. Used only on 1.0 compliant hubs that implement no power switching

  D2: Identifies a Compound Device
    0: Hub is not part of a compound device.
    1: Hub is part of a compound device.

  D4...D3: Logical Power Switching Mode
    00: Global Over-current Protection. The hub reports over-current as a summation
        of all ports’ current draw, without a breakdown of individual port
        over-current status.
    01: Individual Port Over-current Protection. The hub reports over-current on a
        per-port basis. Each port has an over-current status.
    1X: No Over-current Protection. This option is  allowed only for bus-powered
*/

typedef struct {
  uint8_t  bDescLength;
  uint8_t  bDescriptorType;     /* HUB Descriptor Type 0x29 */
  uint8_t  bNbrPorts;           /* Number of ports */
  uint16_t wHubCharacteristics; /* Bitmap	Hub Characteristics (see above) */
  uint8_t  bPwrOn2PwrGood;      /* Time (*2 ms) from port power on to power good */
  uint8_t  bHubContrCurrent;    /* Maximum current used by hub controller (mA).*/
  uint8_t  DeviceRemovable[1];  /* bits indicating deviceRemovable and portPwrCtrlMask */
} hub_descriptor;

typedef struct {
  uint16_t wPortStatus;
  uint16_t wPortChange;
} hub_port_status;

#define PORT_STAT_CONNECTION  0x0001
#define PORT_STAT_ENABLE      0x0002
#define PORT_STAT_SUSPEND     0x0004
#define PORT_STAT_OVERCURRENT 0x0008
#define PORT_STAT_RESET       0x0010
#define PORT_STAT_POWER       0x0100
#define PORT_STAT_LOW_SPEED   0x0200
#define PORT_STAT_HIGH_SPEED  0x0400
#define PORT_STAT_TEST        0x0800
#define PORT_STAT_INDICATOR   0x1000

#define PORT_STAT_C_CONNECTION  0x0001
#define PORT_STAT_C_ENABLE      0x0002
#define PORT_STAT_C_SUSPEND     0x0004
#define PORT_STAT_C_OVERCURRENT 0x0008
#define PORT_STAT_C_RESET       0x0010

usb_error hub_get_descriptor(const device_config_hub *const hub_config, hub_descriptor *const hub_description) __sdcccall(1);

#endif
