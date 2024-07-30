#include "print.h"

void print_device_mounted(const char *const description, const uint8_t count) {
  print_string("\r\n  $");
  print_uint16(count);
  print_string(description);
  if (count > 1)
    print_string("S$");
}
