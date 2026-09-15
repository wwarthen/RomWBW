/* BFI2C.H -- BF_I2C ($60) RST 8 wrappers. See Source/HBIOS/hbios.inc.

   Status codes (bf_i2cstart/bf_i2crepstart/bf_i2cwrite/bf_i2cread):
   0=ok, 1=NAK, 3=bus never went idle (bf_i2cstart only), 0xFF=timeout.

   bf_i2cbusbusy() reuses the same code 3 for "busy", 0 for "free". It is
   a non-blocking check, it never waits. */

extern getbank();
extern bf_i2cdevice();
extern bf_i2cstart();
extern bf_i2crepstart();
extern bf_i2cwrite();
extern bf_i2cread();
extern bf_i2cxfer();
extern bf_i2cbusbusy();
extern bf_i2cstop();
