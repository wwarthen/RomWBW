#ifndef __USB_ENUMERATE_STORAGE
#define __USB_ENUMERATE_STORAGE

#include "dev_transfers.h"
#include "protocol.h"

extern void parse_endpoints(device_config_storage *const storage_dev, const endpoint_descriptor const *pEndpoint);

#endif
