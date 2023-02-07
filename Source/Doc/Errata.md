$define{doc_title}{Errata}$
$include{"Book.h"}$

# Errata

The following errata apply to $doc_product$ $doc_ver$:

* The use of high density floppy disks requires a CPU speed of 8 MHz or 
  greater.

* The PropIO support is based on RomWBW specific firmware. Be sure to 
  program/update your PropIO firmware with the corresponding firmware 
  image provided in the Binary directory of the RomWBW distribution.

* Reading bytes from the video memory of the VDU board (not Color 
  VDU) appears to be problematic. This is only an issue when the driver 
  needs to scroll a portion of the screen which is done by applications 
  such as WordStar or ZDE. You are likely to see screen corruption in 
  this case.