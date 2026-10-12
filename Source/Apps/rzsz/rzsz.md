# RZ and SZ: Technical Operation

**RZ v1.04 (receive) and SZ v1.11 (send): X/Y/ZModem file transfer for CP/M 3**

Written by Wilfried Schmitten, 1992.  This document describes how the two programs work internally.

## Contents

* [0. About this document](#0-about-this-document)
    * [0.1 Scope](#01-scope)
    * [0.2 How the information was obtained](#02-how-the-information-was-obtained)
    * [0.3 A note on the ZModem specification used](#03-a-note-on-the-zmodem-specification-used)
* [1. Overview](#1-overview)
    * [1.1 What the programs do](#11-what-the-programs-do)
    * [1.2 Structure](#12-structure)
    * [1.3 Shared code](#13-shared-code)
    * [1.4 Conventions used in the code](#14-conventions-used-in-the-code)
* [2. Memory layout](#2-memory-layout)
    * [2.1 Load image and work area](#21-load-image-and-work-area)
    * [2.2 Stack](#22-stack)
    * [2.3 The SZ program header](#23-the-sz-program-header)
    * [2.4 Self-modifying code](#24-self-modifying-code)
    * [2.5 Buffer sizing](#25-buffer-sizing)
* [3. Start-up, options and exit](#3-start-up-options-and-exit)
    * [3.1 Sequence](#31-sequence)
    * [3.2 Command tail](#32-command-tail)
    * [3.3 Option letters](#33-option-letters)
    * [3.4 Detaching the modem port from the console](#34-detaching-the-modem-port-from-the-console)
    * [3.5 Exit](#35-exit)
* [4. Common services](#4-common-services)
    * [4.1 Table-driven dispatch](#41-table-driven-dispatch)
    * [4.2 The AUX device layer](#42-the-aux-device-layer)
    * [4.3 Timing](#43-timing)
    * [4.4 CRC and checksum](#44-crc-and-checksum)
    * [4.5 32-bit arithmetic and number output](#45-32-bit-arithmetic-and-number-output)
    * [4.6 File specification parsing](#46-file-specification-parsing)
    * [4.7 Console output](#47-console-output)
    * [4.8 Small utilities](#48-small-utilities)
* [5. The ZModem implementation](#5-the-zmodem-implementation)
    * [5.1 Frame formats](#51-frame-formats)
    * [5.2 ZDLE escaping](#52-zdle-escaping)
    * [5.3 Receiving a header (`get_header`)](#53-receiving-a-header-get_header)
    * [5.4 Receiving a data subpacket (`rx_data_subpkt`)](#54-receiving-a-data-subpacket-rx_data_subpkt)
    * [5.5 Frame types used](#55-frame-types-used)
* [6. RZ in detail](#6-rz-in-detail)
    * [6.1 Control flow](#61-control-flow)
    * [6.2 ZModem session](#62-zmodem-session)
    * [6.3 Writing to disk](#63-writing-to-disk)
    * [6.4 XModem and YModem reception](#64-xmodem-and-ymodem-reception)
    * [6.5 Progress display and abort](#65-progress-display-and-abort)
* [7. SZ in detail](#7-sz-in-detail)
    * [7.1 Control flow](#71-control-flow)
    * [7.2 Building the file list](#72-building-the-file-list)
    * [7.3 Choosing and starting the protocol (`wait_rx_start`)](#73-choosing-and-starting-the-protocol-wait_rx_start)
    * [7.4 Reading the file and the retransmission ring](#74-reading-the-file-and-the-retransmission-ring)
    * [7.5 ZModem sending](#75-zmodem-sending)
    * [7.6 XModem and YModem sending](#76-xmodem-and-ymodem-sending)
    * [7.7 Console, abort and errors](#77-console-abort-and-errors)
    * [7.8 The buffered file object](#78-the-buffered-file-object)
* [8. Error handling and limits](#8-error-handling-and-limits)
    * [8.1 Retry limits](#81-retry-limits)
    * [8.2 Other limits](#82-other-limits)
    * [8.3 Aborting and cancelling](#83-aborting-and-cancelling)
    * [8.4 BDOS functions used](#84-bdos-functions-used)
* [9. Observations](#9-observations)
* [Appendix A: Routine index](#appendix-a-routine-index)
* [Appendix B: Dispatch tables](#appendix-b-dispatch-tables)
* [Appendix C: RAM maps](#appendix-c-ram-maps)
* [Appendix D: BDOS functions used](#appendix-d-bdos-functions-used)
* [Appendix E: Shared routines](#appendix-e-shared-routines)

---

## 0. About this document

### 0.1 Scope

`RZ.COM` and `SZ.COM` are a pair of Z80 programs for CP/M 3 that receive and send files using the XModem, YModem and ZModem protocols.  This document explains their internal operation at the level of memory layout, data structures, control flow, protocol state machines, timing and error handling.  It is meant for someone who wants to understand, debug, port or modify the programs.  For a user-level description see the `RZ / SZ` entry in the RomWBW *Applications Guide*.

### 0.2 How the information was obtained

Neither program came with source code.  Everything here was derived by disassembling the two `.COM` files and tracing the code, then cross-checking against three references: the ZModem specification (rev. 05/14/86), the Unix `rz.c` and `sz.c` sources, and an independent disassembly of the same binaries.  The commented disassembly (`rz.asm`, `sz.asm`, TASM syntax, reassembling byte-for-byte to the originals) is the companion to this document, and routine and variable names used here are the labels in those files.

Statements are of three kinds:

* **Facts** read directly from the code (addresses, sizes, constants, sequences).
* **Interpretation** of what the code is for.  These are phrased as such where the purpose is not self-evident.
* **Observations** of behavior that follows from the code but that the original author may not have intended.  They are collected in section 9.

Where the two programs share code, the routine has the same name in both listings but a different address.  Addresses are written `RZ 0BD3` or `SZ 0D47`.  All numbers are hexadecimal unless noted; `H` is sometimes omitted for addresses.

### 0.3 A note on the ZModem specification used

The supplied specification predates 32-bit CRC.  The CRC-32 frame format (`ZBIN32`), the `CANFC32` and `ESCCTL` flag bits and the `ZMPROT` file option are later extensions of the protocol that the programs implement.  They are described here from the code.

---

## 1. Overview

### 1.1 What the programs do

`SZ` sends one or more files; `RZ` receives them.  They are used as a pair on two systems, or against any other ZModem/YModem/XModem implementation.  The only requirement stated by the author is that a modem (or a null-modem cable) is connected to the **AUX** device of a CP/M 3 system.  All communication goes through the standard CP/M 3 BDOS auxiliary-device calls; the programs contain no hardware-specific code.

| Feature | RZ | SZ |
|---|---|---|
| Direction | receive | send |
| Version / date | 1.04 (1992) | 1.11 (1992) |
| Image size at 0100H | 5,888 bytes (0100-17FF) | 7,808 bytes (0100-1F7F) |
| Work RAM above the image | 1808-2D10 | 2000-28DB |
| First free memory | 2D11 | 28DC |
| AUX input ring buffer | 4096 bytes | 512 bytes |
| Protocols | ZModem, YModem batch, XModem | ZModem, YModem batch, XModem |
| ZModem CRC | CRC-16 and CRC-32 | CRC-16 and CRC-32 |
| Wildcards / multiple files | no (sender supplies names) | yes, sorted directory expansion |
| ZCPR3 environment header | no | yes (`Z3ENV`, patched by Z3INS) |
| Option letters | `? p b c r x y z` | `? p a b c x y z` |

### 1.2 Structure

Each program is organized in layers.  The top layer is a protocol driver (receive or send).  Below it sit the shared building blocks: ZModem framing, CRC, the AUX device layer and a small run-time library.

```
            +-------------------------------+   +-------------------------------+
            |  RZ: receive_main             |   |  SZ: send_main / send_files   |
            |  ZModem / YModem / XModem rx  |   |  ZModem / YModem / XModem tx  |
            +---------------+---------------+   +---------------+---------------+
                            |                                   |
            +---------------+-----------------------------------+---------------+
            |  ZModem framing: hex/binary headers, data subpackets, ZDLE escapes  |
            |  (get_header, rx_data_subpkt | send_hex_header, send_bin_header,    |
            |   send_subpacket, put_zdle_char)                                    |
            +---------------+-----------------------------------+---------------+
                            |                                   |
            +---------------+-----------------------------------+---------------+
            |  AUX layer: aux_poll_input, ring buffer, aux_getc_timeout,          |
            |  aux_putc_wait, ESC abort hook, software delay timing               |
            +---------------+-----------------------------------+---------------+
                            |                                   |
            +---------------+-----------------------------------+---------------+
            |  Library: dispatch tables, 32-bit math, CRC-16/32, number output,   |
            |  filespec parser, argument tokenizer, BDOS wrappers                 |
            +---------------------------------------------------------------------+
                            |
                  CP/M 3 BDOS (AUX, console, files, System Control Block)
```

### 1.3 Shared code

Roughly two thirds of each program is shared.  About 65 routines are the same in both images apart from the addresses and a few constants (for example the ring size) that they refer to.  The differences are the protocol drivers, the file layer (RZ writes through a single sector buffer; SZ has a general buffered file object and a directory scanner and sorter) and the sizes of the buffers.

### 1.4 Conventions used in the code

* **Dispatch tables.**  Most decisions on a single byte value are made with the Z80 `CPIR` instruction over a table of key bytes followed by a table of 16-bit vectors (section 4.1).
* **32-bit values** (file positions, sizes) are stored little-endian in four bytes and manipulated by a small set of routines (`add32`, `sub32`, `cmp32_signed`, `copy32`, ...) that take pointers in `HL`, `DE` and `BC`.
* **Return conventions.**  Carry set means error or abort; `A` then often holds a protocol code.  Zero/non-zero is used for "no data / data available" results.
* **Self-modifying code.**  Several routines keep a variable inside an instruction operand (section 2.4).  The programs therefore must run from RAM, which a `.COM` file always does.
* **Strings** are terminated with `$` (printed with BDOS function 9) or with a zero byte (sent to the modem).

---

## 2. Memory layout

### 2.1 Load image and work area

CP/M loads the `.COM` file at 0100H.  Both programs keep all their variables, tables and large buffers *above* the loaded image, in memory the loader does not initialize.  The image itself therefore contains only code, constant tables, text and a few pre-initialized variables.

**RZ memory map**

| Address | Size | Contents |
|---|---|---|
| 0100-17FF | 5,888 | Program image: code, tables, strings, a few variables |
| 17C8-1807 | 64 | Stack (the 56 zero bytes ending the image plus 8 unused bytes); SP starts at 1808 |
| 1808-180D | 6 | AUX receive ring control block |
| 180E-280D | 4,096 | AUX receive ring data |
| 280E-2810 | 3 | Output sector buffer count / write index / read index |
| 2811-2890 | 128 | File sector buffer |
| 2891-289C | 12 | `ltoa_value`, `ltoa_temp`, `crc32_value` |
| 289D-2C9C | 1,024 | CRC-32 lookup table |
| 2C9D-2D10 | 116 | Protocol state variables (appendix C) |
| 2D11-BDOS | rest | Free memory: argument table, then the receive buffer |

**SZ memory map**

| Address | Size | Contents |
|---|---|---|
| 0100-1F7F | 7,808 | Program image |
| 2000-2002 | 3 | Default user, default drive, user to select |
| 2003-2026 | 36 | Work FCB |
| 2027-2066 | 64 | Stack; SP starts at 2067 |
| 2067-206C | 6 | AUX receive ring control block |
| 206D-226C | 512 | AUX receive ring data |
| 226D-2292 | 38 | Current file-list entry user byte and send FCB (name at 226F) |
| 2293-229E | 12 | `ltoa_value`, `ltoa_temp`, `crc32_value` |
| 229F-269E | 1,024 | CRC-32 lookup table |
| 269F-2764 | 198 | Protocol state, directory, sort and parse variables (appendix C) |
| 2765-28B4 | 336 | Two buffered file objects: `in_file` and `out_file` (168 bytes each) |
| 28B5-28DB | 39 | File-object pointer, character buffer, scratch FCB |
| 28DC-BDOS | rest | Free memory: argument table / file list, then the file buffer |

### 2.2 Stack

Both programs set `SP` to the address of the AUX ring control block at start (`ld sp,aux_ring`), so the stack grows downward into 64 bytes of otherwise unused space.  In RZ these are the last 56 bytes of the image (which the file stores as zeros) plus 8 unused bytes; in SZ they are a 64-byte block below the ring.  The stack is shallow: the deepest nesting is a handful of calls with a few registers saved at each level.

### 2.3 The SZ program header

`SZ.COM` starts with a ZCPR3 type-1 header:

```
0100  C3 0B 01        jp main
0103  'Z3ENV'         identification string
0108  01              environment type
0109  0000            ZCPR3 environment address (patched by Z3INS)
010B  main:
```

`RZ.COM` has no header and begins directly with `ld sp,aux_ring`.

### 2.4 Self-modifying code

Several routines store a value in an instruction operand instead of in a separate variable.  In the listings each such byte has a name defined as an offset into its instruction (for example `crc16_hi .equ L0886+2`).  The programs rely on this for speed and size.

| Name | Where | Role |
|---|---|---|
| `restore_du` | start-up (`ld bc,nnnn`) | default user/drive restored at exit |
| `spinner_index` | RZ show_spinner | phase 0-3 of the activity spinner |
| `ltoa_digit`, `ltoa_started`, `ltoa_outptr` | ltoa32 | digit being built, leading-zero flag, output pointer |
| `xm_checksum` | checksum_add | running 8-bit XModem checksum |
| `crc32_tab_ptr` | crc32_update | address of the CRC-32 table |
| `crc16_lo`, `crc16_hi` | crc16_update | CRC-16 accumulator |
| `zri_frame_type` | RZ zrinit_handshake | frame type sent in the ZRINIT slot |
| `prev_char`, `file_char` | RZ write_buf_file / file_putc | previous source byte; byte being stored |
| `xm_blk_no_rx` | RZ XModem block receive | received block number |
| `zdl_char`, `aux_out_char` | put_zdle_char / aux_putc_wait | character being sent |
| `file_list_ptr`, `entry_drive` | SZ fetch_file_entry | next list entry; drive of the entries |
| `blk_bytes_left` | SZ xmodem_snd_block | bytes left in the block |
| `zfile_info_len` | SZ zmodem_snd_zfile | length of the ZFILE information |
| `resp_mode_flag` | SZ zmodem_get_resp | accept any ZACK, or only one for the current position |

### 2.5 Buffer sizing

Both programs use free memory above the work area as a data buffer.  `calc_buffer_mask` takes the number of free bytes (the distance from the buffer base to the BDOS entry stored at 0006H) and reduces it to the largest power of two that is a multiple of 256, found by locating the highest set bit of the high byte.  The result is stored as the buffer size, and the size minus one as a mask (`buffer_mask`).  A 48 KB TPA, for example, gives a 32 KB buffer.  The maximum is 32 KB.

* **RZ** uses the buffer to collect received data until it is safe to write it to disk.  The buffer size is announced to the sender in the ZRINIT header (section 6.2).
* **SZ** uses the buffer as a ring that holds recently read file data so that it can be retransmitted without re-reading the disk (section 7.4).  The mask is applied to file positions to find the slot of a byte.

---

## 3. Start-up, options and exit

### 3.1 Sequence

Both programs run the same start-up steps:

1. Set `SP`.
2. **Check the BDOS version** with function 12 (`S_BDOSVER`).  If the version is below 30H, print `sorry, CP/M 3 Tool` and exit.
3. **Print the banner**: `RZ for CP/M 3   V 1.04` or `SZ for CP/M 3   V 1.11`, and `(C) 92 wshbg`.
4. **Save the default drive and user** (`get_default_du`) from the byte at 0004H (drive in the low nibble, user in the high nibble) and remember them for exit.
5. **Parse the command tail** (section 3.2).
6. **Prompt the user**: RZ prints `start your local X/Y/ZModem sending program`; SZ prints the number of files found followed by `File(s) requested` and `start your local X/Y/ZModem receive program`.
7. **Detach the modem port from the console** (`scb_setup`, section 3.4).
8. **Run the transfer** (`receive_main` or `send_main`).
9. **Restore** the System Control Block (`scb_restore`), the default drive and user (`set_du`) and **exit with a warm boot** (`jp 0`).

### 3.2 Command tail

The command tail at 0080H is split into at most two whitespace-separated tokens by `tokenize_args`, which builds a table of token pointers at the start of free memory (RZ clears the first 20 bytes of it beforehand).  More than two tokens print the usage text and exit.

* If the **first token begins with `-`**, it is the option string.  `parse_options` scans it one character at a time (the `-` itself is skipped) and looks each character up in a dispatch table.  Characters that are not options are silently ignored.  The **second token**, if present, is then the file specification.
* If the first token does not begin with `-`, it is the file specification and there are no options.

The tail is already converted to upper case by the CP/M 3 command processor, so the option table contains only capital letters.

### 3.3 Option letters

Each handler sets a variable to 0FFH, or, for `x`, `y` and `z`, stores a protocol number.

| Letter | RZ handler and flag | SZ handler and flag |
|---|---|---|
| `?` | print usage and exit | print usage and exit |
| `P` | `opt_protect_flag`: protect an existing file | `opt_protect_flag`: ask receiver to protect |
| `B` | `opt_binary_flag` | `opt_binary_flag`: ZF0 = ZCBIN |
| `C` | `opt_convert_flag` | `opt_convert_flag`: ZF0 = ZCNL |
| `R` | `opt_resume_flag` | not recognized |
| `A` | not recognized | `opt_append_flag`: ZF1 = ZMAPND |
| `X` | `protocol` = 1 | `protocol` = 1 |
| `Y` | `protocol` = 3 | `protocol` = 3 |
| `Z` | `protocol` = 4 | `protocol` = 4 |

`protocol` defaults to 4 (ZModem) in both programs; its byte lives in the image at `RZ 08AF` and `SZ 0852`.  The effect of the protocol value is different in the two programs and is described in sections 6.1 and 7.1.

The file specification is parsed by `parse_filespec` (section 4.6).  **In RZ a file specification forces XModem** (`opt_xmodem` is called after it is parsed), because XModem does not carry file names; it overrides any `-y` or `-z`.  The drive and user of the specification are selected with `set_du`, and the XModem file is created there.  With YModem and ZModem no specification is given, so received files are created in the default drive and user area.

### 3.4 Detaching the modem port from the console

CP/M 3 lets each logical device be redirected to a set of physical devices through bit vectors held in the System Control Block (SCB).  `scb_setup` uses BDOS function 49 (`S_SYSVAR`) with three parameter blocks.  A parameter block is four bytes: SCB offset, a set code (0 = read, 0FEH = write a word) and a 16-bit value.

| SCB offset | Name used here | Meaning |
|---|---|---|
| 22H | `SCB_CIVEC` | console input redirection vector |
| 24H | `SCB_COVEC` | console output redirection vector |
| 28H | `SCB_AOVEC` | auxiliary output redirection vector |

The procedure is:

1. Read AOVEC and keep its complement as a mask (`scb_aovec_mask`).
2. Read COVEC, remember the original (`scb_sv_covec`), clear the AOVEC devices from it with the mask, and queue the result for writing.
3. Do the same for CIVEC (`scb_sv_civec`).
4. Write the new COVEC and CIVEC.

The effect is that the physical device(s) behind AUX are removed from console input and output for the duration of the transfer, so that the console cannot read or echo to the same port.  `scb_restore` copies the saved values back into the parameter blocks and writes them at exit.  The SCB offsets above are from the CP/M 3 System Control Block definition; the programs themselves do not identify the fields.

### 3.5 Exit

After the transfer, `scb_restore` and `set_du` run, then `jp CPM` (a warm boot).  A transfer that fails or is aborted returns to the same exit path, so the console assignment and the drive/user are restored in every case that returns to the start-up code.  `usage_exit` and the version-check failure jump to the warm boot directly because they have changed nothing yet.


---

## 4. Common services

### 4.1 Table-driven dispatch

Most multi-way decisions are made with one mechanism.  A table consists of **n key bytes** immediately followed by **n 16-bit vectors**:

```
        ld   hl,table          ; address of the key bytes
        ld   bc,n              ; number of keys
        cpir                   ; search for A in the keys
        jp   z,dispatch        ; found: jump through the matching vector
        ...                    ; not found: fall through
```

After a successful `CPIR`, `HL` points just past the matching key and `BC` holds the number of keys that were *not* yet examined.  `dispatch` adds `BC` to `HL` to reach the start of the vectors, then adds `2*BC` to select a vector, loads it and jumps to it.  The consequence is that **the vectors are stored in the reverse order of the keys**: the first key corresponds to the last vector.  The option table is a good example:

```
keys:     ?        P         B        C         X          Y          Z          R
vectors:  opt_resume opt_zmodem opt_ymodem opt_xmodem opt_convert opt_binary opt_protect usage_exit
          (R)        (Z)       (Y)        (X)        (C)        (B)        (P)        (?)
```

Where only membership matters (is this character one of a set?) the same `CPIR` is used without vectors.  Appendix B lists every table in both programs with its keys and handlers.

### 4.2 The AUX device layer

The programs talk to the modem exclusively through four BDOS functions:

| BDOS function | Use |
|---|---|
| 7 `A_STATIN` | is a character waiting? |
| 3 `A_READ` | read one character |
| 8 `A_STATOUT` | is the device ready for output? |
| 4 `A_WRITE` | write one character (in `E`) |

**Receiving.**  `aux_poll_input` drains the device: while the ring buffer is not full and `A_STATIN` reports a character, it reads the character with `A_READ` and stores it in a ring buffer (`ring_put`).  It returns "not zero" if anything is available to be read, counting characters queued in the ring and any pending characters described below.

The ring buffer has a six-byte control block and a data area:

```
+0  count        word   number of bytes in the ring
+2  write index  word   next slot to write
+4  read index   word   next slot to read
+6  data         4096 bytes in RZ, 512 bytes in SZ
```

Indices wrap with the mask 0FFFH (RZ) or 01FFH (SZ).  `ring_put` returns Z (and does not store) when the ring is full; `ring_get` returns Z when it is empty.  When the ring is full `aux_poll_input` simply stops reading, so no data is discarded by the programs; any overflow would have to be handled by the CP/M driver.

**Pending characters.**  A two-variable queue (`pending_char`, `pending_count`) can inject up to a few repeats of a single character into the input stream ahead of the ring.  It is used only by the abort mechanism below.

**Timed read.**  `aux_getc_timeout` takes a timeout in `B` in units that are nominally 0.1 second ("ticks") and returns the next character (carry clear) or `0FEH` with carry set on timeout.  Each call first looks at the console:

1. If a key is waiting (BDOS function 11), it is read (function 1).
2. If it is **ESC** (1BH), `set_pending_char` queues ten CAN characters (18H) as pending input.

Any other key is discarded.  Because the ten CANs are then delivered like data from the peer, every protocol layer sees a cancel (five consecutive CANs abort ZModem, two abort XModem) and the transfer ends through its normal error path, including the transmission of a cancel string to the other side.  This is why the author notes that an abort "may take a few seconds": the CANs are only injected when the next timed read starts.

The wait itself is `aux_wait_input`, one tick of which consists of 95 iterations of "poll the port, then run a software delay" (section 4.3).  It returns as soon as a character is available.

**Sending.**  `aux_putc_wait` stores the character, then loops `aux_poll_input` and `A_STATOUT` until the port is ready, then calls `A_WRITE`.  Polling for input while waiting for output keeps incoming data flowing into the ring during long transmissions (important at low speeds on a full-duplex link).

### 4.3 Timing

There is no hardware timer.  All timeouts come from the software delay `delay_short`:

```
delay_short:  push bc ; ld a,04H ; ld b,00H
L:            djnz L           ; 256 iterations
              dec a ; jr nz,L  ; 4 passes
              pop bc ; ret
```

On a Z80, `DJNZ` takes 13 T-states when it loops and 8 when it falls through.  One pass of the inner loop is therefore 255 x 13 + 8 = 3,323 T-states; four passes with the outer-loop overhead are 13,351; with the push, pop, load and return and the `CALL` the total is **about 13,400 T-states**, or 3.35 ms at 4 MHz.

A tick is 95 iterations of poll + delay + loop overhead.  Each iteration costs about 14,000 T-states (the BDOS status call is not included in that estimate and depends on the CP/M BIOS), so a tick is about 1.3 million T-states:

| CPU clock | Nominal 0.1 s tick takes about |
|---|---|
| 4 MHz | 0.33 s |
| 8 MHz | 0.17 s |
| 13 MHz | 0.10 s |

The constants therefore look tuned for a fast CPU of roughly 12-14 MHz Z80 equivalent.  On slower systems every timeout is proportionally longer; a 10-second wait is about 33 seconds on a 4 MHz Z80.  This does not change protocol behavior on a healthy link, only the time a stalled transfer takes to give up.

The timeouts used by the protocol code, in nominal time:

| Where | Timeout |
|---|---|
| First character of a ZModem header (`get_header`) | 10 s |
| Each further character of a header or data subpacket | 10 s |
| The CR and LF after a hex header | 1 s |
| ZModem sender waiting for the receiver to start (`wait_rx_start`) | 25.5 s per wait |
| ZModem sender waiting for a response (`zmodem_get_resp`) | 10 s |
| Sender waiting for ZPAD after a repeated ZRINIT | 5 s |
| XModem receiver, first block | 13 s |
| XModem receiver, later blocks | 5 s (4 s after an error) |
| XModem receiver, characters inside a block | 1 s |
| XModem receiver, EOT confirmation | 1 s of silence |
| XModem sender waiting for ACK/NAK | 10 s |
| XModem sender waiting for the receiver to start | 25.5 s |
| ZFIN / "OO" exchange | 10 s per attempt |

### 4.4 CRC and checksum

**CRC-16** (`crc16_update`).  The CCITT polynomial 1021H, MSB first, initial value 0.  The input byte is XORed into the high byte of the accumulator, then the accumulator is shifted left eight times, XORing 1021H after each shift that carries out.  The accumulator is held in the operand of an instruction (`crc16_hi`, `crc16_lo`) and is transmitted high byte first.  The same routine serves ZModem headers, ZModem data (with CRC-16) and XModem/YModem CRC.

**CRC-32** (`crc32_table_init`, `crc32_update`).  The reflected polynomial EDB88320H.  A 1,024-byte table of 256 little-endian entries is built once at start-up.  The update is the standard table form `crc = table[(crc xor byte) and FFH] xor (crc >> 8)` with initial value FFFFFFFFH.  The accumulator is not complemented.  RZ checks a received frame by running the CRC over the data, the terminator and the four CRC bytes and comparing the accumulator with the constant residue **DEBB20E3H** (`crc32_residue`).  SZ transmits the complement of the accumulator, low byte first.

**Checksum** (`checksum_add`).  An 8-bit sum held in an instruction operand (`xm_checksum`), used for XModem blocks in non-CRC mode.

`crc_init` resets all three accumulators: CRC-16 to 0, CRC-32 to FFFFFFFFH and (through the same routine) the checksum.

### 4.5 32-bit arithmetic and number output

File positions and sizes are 32-bit little-endian values.  The library is a set of small routines that take pointers:

| Routine | Operation |
|---|---|
| `zero32`, `set32_minus1` | `(HL) = 0`, `(HL) = -1` |
| `copy32` | `(DE) = (HL)` |
| `inc32`, `dec32` | `(HL) = (HL) +/- 1` |
| `add32` | `(BC) = (DE) + (HL)` |
| `sub32` | `(BC) = (HL) - (DE)` |
| `and32` | `(BC) = (DE) AND (HL)` |
| `eq32` | compare `(HL)` and `(DE)`; Z if equal |
| `cmp32_signed`, `cmp32_unsigned` | compare `(HL)` with `(DE)`; carry if `(HL)` is smaller |

`ltoa32` converts a 32-bit value to decimal text.  It works on a copy of the value, repeatedly subtracting the powers of ten in `pow10_table` (10^9 down to 10, stored as nine little-endian 32-bit constants) and counting the subtractions to obtain each digit; leading zeros are suppressed and the final digit is the remainder.  The text is zero terminated.

### 4.6 File specification parsing

`parse_filespec` converts text of the form `[prefix:]name[.ext]` into an FCB.  On entry `HL` points to the text, `DE` to the FCB and `A` selects the order in which a prefix is interpreted.

* The name and extension fields are copied by `parse_fcb_field`: up to 8 or 3 characters, with `*` expanded to a run of `?`.  The number of wildcard characters is counted and returned in `A` (non-zero means the name is ambiguous).
* The first field, if followed by `:`, is a **prefix**.  It may be a drive/user form (`parse_du_inner`) or a **named directory** (`named_dir_lookup`).  If `A` is non-zero the drive/user form is tried first, otherwise the named directory is tried first.
* A drive/user prefix is a drive letter, a user number, or both (letter immediately followed by up to two digits).  The drive is checked against the maximum drive, and the user against the maximum user.
* A named directory is found by comparing eight characters against the ZCPR3 named directory register (entries of 16 bytes: drive, user, an 8-character name and 6 further bytes).
* The drive is stored in the first FCB byte, and the user in the byte at FCB+0DH (`FCB_S1`) and in `parsed_user`.

The limits and the named directory register come from the **ZCPR3 environment descriptor** through four helper routines: the DU-allowed flag (offset 2EH), maximum drive (2CH), maximum user (2DH) and the named directory register address (15H) and entry count (17H).  The environment address is held in `z3env_ptr`.

SZ stores the address it finds in its `Z3ENV` header (patched by the Z3INS installer).  **RZ never initializes `z3env_ptr`.**  When the pointer is zero the helpers do not add the offset: they read the byte at address 0000H, which on CP/M is the `JP` opcode 0C3H.  Without a ZCPR3 environment this makes the DU-allowed flag non-zero (DU forms are accepted) and both maximums 0C3H (effectively unlimited), while the named-directory lookup reads from page zero and in practice finds a count of zero.  See section 9.

### 4.7 Console output

Messages are printed with BDOS function 9.  Three outputs are shown during a transfer:

* `print_filename` prints the drive and name of the current file (`d:NAME.EXT`) and, when available, its announced size.
* `print_position` converts the current file position with `ltoa32` into a line that begins with a carriage return, so each update overwrites the previous one.
* `print_err_count` prints the error counter with the ` error(s)` text; it is called each time a retry happens.

RZ also runs a four-phase spinner (`| / - \`) in `show_spinner`, advancing once per received subpacket.

### 4.8 Small utilities

`tokenize_args` splits text into blank-separated tokens (the tokens may be terminated with zero bytes in place); `upcase_string` and `to_upper` change case; `memset` fills memory; `a_to_decimal` prints a byte as up to three digits; `skip_blanks`, `skip_token`, `is_delimiter`, `digit_value` and `parse_decimal` support the parsers; `bdos_save_regs`, `bdos_call_a`, `bdos_check` are BDOS wrappers that preserve registers or return success in the carry flag; `get_drive_user` returns the current drive in `B` and user in `C`; `file_exists` searches the directory for a name.

---

## 5. The ZModem implementation

This section describes the parts of ZModem shared by both programs.  The protocol drivers follow in sections 6 and 7.

### 5.1 Frame formats

Every ZModem exchange starts with a **header**: a frame type and four argument bytes.  For position-carrying frames the four bytes are a 32-bit position, least significant byte first (`ZP0`-`ZP3`).  For `ZRINIT` and `ZFILE` the bytes hold flags in the order `ZF3`, `ZF2`, `ZF1`, `ZF0`, so `ZF0` is the **fourth** byte.  The headers are held in `tx_header_data` and `rx_header_data`.

**Hex header** (`send_hex_header`, `get_hex_header`)

```
ZPAD ZPAD ZDLE 'B'  tt  p0 p1 p2 p3  cc cc  CR LF  [XON]
                    \---- lower-case hex digits ----/
```

The type, the four argument bytes and the two CRC-16 bytes are sent as 14 lower-case hexadecimal digits.  Nothing in a hex header is ZDLE-escaped.  The CRC is computed over the type and the four argument bytes, and sent high byte first.  A CR and LF follow, then an XON (11H) unless the frame is ZFIN.  The receiver accepts only lower-case digits.

**Binary header with CRC-16** (`send_bin_header` when the peer did not announce CRC-32)

```
ZPAD ZDLE 'A'  tt p0 p1 p2 p3  crc_hi crc_lo
               \------ every byte after 'A' is ZDLE-escaped ------/
```

**Binary header with CRC-32**

```
ZPAD ZDLE 'C'  tt  p0 p1 p2 p3  c0 c1 c2 c3
                   \--- ZDLE-escaped ---/  (c = complement of the CRC-32 accumulator, low byte first)
```

SZ uses the binary form for ZFILE, ZDATA, ZEOF and ZNAK and the hex form for ZRQINIT, ZFIN and the challenge reply.  RZ sends only hex headers.

**Data subpacket** (`send_subpacket`, `rx_data_subpkt`)

```
data bytes (ZDLE-escaped)  ZDLE  terminator  CRC (ZDLE-escaped)  [XON]
```

The CRC covers the data bytes and the terminator byte.  The terminator is one of

| Terminator | Value | Meaning |
|---|---|---|
| `ZCRCE` | 68H | end of frame; a header follows; no acknowledgement |
| `ZCRCG` | 69H | more data follows immediately; no acknowledgement |
| `ZCRCQ` | 6AH | more data follows; the receiver acknowledges with ZACK |
| `ZCRCW` | 6BH | end of frame; the receiver must acknowledge before more data is sent |

SZ appends an XON after every subpacket except ZCRCW.

### 5.2 ZDLE escaping

ZDLE is the ZModem escape character (18H, the same value as CAN).

**Sending** (`put_zdle_char`).  A character is sent as ZDLE followed by the character XOR 40H when it is

* ZDLE, DLE (10H) or XON (11H) or XOFF (13H), each also with bit 7 set (90H, 91H, 93H);
* CR (0DH or 8DH) when the previously sent character was `@` (this protects Telenet-style networks); or
* any other control character (bits 5 and 6 clear) when the peer requested escaping of all control characters (`ESCCTL`, held in `escape_ctl_flag`).

Everything else is sent unchanged.

**Receiving** (`getc_zdl_filt`, `zdlread_escape`).  Characters with either of bits 5-6 set are taken as data.  XON and XOFF (with or without bit 7) are discarded anywhere in a frame.  Other control characters are discarded as noise when `ESCCTL` is active, otherwise accepted.  After a ZDLE the next character selects:

| Character after ZDLE | Result |
|---|---|
| `ZCRCE`, `ZCRCG`, `ZCRCQ`, `ZCRCW` | terminator: value OR 80H returned with carry set (`GOTCRCE`... `GOTCRCW`) |
| `ZRUB0` ('l') | data byte 7FH |
| `ZRUB1` ('m') | data byte FFH |
| ZDLE | counted; five ZDLE (CAN) in a row return `GOTCAN` |
| XON/XOFF variants | ignored |
| any character with bits 5-6 = 10 (40H-5FH) | data byte = character XOR 40H |
| anything else | error (0FFH) |

### 5.3 Receiving a header (`get_header`)

`get_header` is a small state machine that scans the incoming stream for a header and returns the frame type in `A`.

```
idle ---ZPAD(2AH/AAH)---> got_zpad ---ZPAD---> (stay)
  |                           |
  |                           +--ZDLE--> got_zpad_zdle --'B'--> hex header
  |                                              |      --'A'--> binary CRC-16
  |                                              |      --'C'--> binary CRC-32
  +--ZDLE--> count CAN (5 in a row => ZCAN)
  +--other--> junk counter (1024 characters => give up, code 0FCH)
```

* Waiting for the first character allows 10 seconds.  A timeout returns `0FEH` with carry set.
* `ZPAD` in the idle state, with or without bit 7, starts a header.  In `got_zpad` the characters are read with parity stripped and with XON and XOFF ignored (and, when `ESCCTL` is active, other control characters as well); further pads are skipped, so a header may be preceded by any number of them, and anything other than a pad or ZDLE counts as junk.
* The format character selects `get_hex_header`, `get_bin16_header` or `get_bin32_header`; `crc_mode` is set to 10H (CRC-16) or 20H (CRC-32) accordingly, so that the following data subpackets use the same CRC.
* A valid header is copied to `rx_header_data` and the frame type is returned with carry clear and `header_ok_flag` set.
* The pseudo return codes `0FFH` (error), `0FEH` (timeout), `0FCH` (junk limit) and `GOTCAN` (converted to `ZCAN`), and the frame types `ZNAK` and `ZCAN`, are returned with carry set.

Five CAN characters in a row anywhere in the scan return `ZCAN`; this is the receiving end of the cancel sequence.

### 5.4 Receiving a data subpacket (`rx_data_subpkt`)

`rx_data_subpkt` reads escaped data into the receive buffer until a terminator arrives.  At each character it

1. updates the CRC (CRC-16 or CRC-32 according to `crc_mode`);
2. stores the byte at `rx_buffer_ptr`, counting it in `rx_buffer_count` and in `subpacket_len`.

If the buffer fills before a terminator arrives the routine returns an error: the sender is expected to end each buffer-full with `ZCRCW`.  On a terminator it includes the terminator in the CRC, reads the two or four CRC bytes through the same decoder, and checks the result (CRC-16 must be zero; CRC-32 must equal the residue).  The return code is `GOTCRCE`, `GOTCRCG`, `GOTCRCQ` or `GOTCRCW` with carry clear when the CRC is good, `0FFH` (error), `0FEH` (timeout) or `ZCAN` with carry set otherwise.

### 5.5 Frame types used

| Frame | Value | Sent by RZ | Sent by SZ | Handling |
|---|---|---|---|---|
| `ZRQINIT` | 0 | | hex, start of session | RZ answers with ZRINIT |
| `ZRINIT` | 1 | hex, announces capabilities and buffer size | | SZ reads flags and buffer length |
| `ZSINIT` | 2 | | not sent | RZ stores the Attn string and flags |
| `ZACK` | 3 | hex (ZSINIT, ZFREECNT, ZCRCQ, ZCRCW) | hex (challenge echo) | position check at the sender |
| `ZFILE` | 4 | | binary, with the file information | RZ creates the file |
| `ZSKIP` | 5 | hex (in the ZRINIT slot) | | SZ gives up on the current file |
| `ZNAK` | 6 | hex (bad ZSINIT/ZFILE packet) | hex or binary | treated as an error |
| `ZFIN` | 8 | hex | hex | end of session |
| `ZRPOS` | 9 | hex | | SZ repositions and resumes |
| `ZDATA` | 10 | | binary | RZ checks the position |
| `ZEOF` | 11 | | binary | RZ checks the position and closes |
| `ZFERR` | 12 | prepared on a disk error | | see section 6 |
| `ZCRC` | 13 | | | SZ ignores a request |
| `ZCHALLENGE` | 14 | | | SZ echoes the value in a ZACK |
| `ZCOMPL` | 15 | | | RZ ignores it; also its own return code |
| `ZCAN` | 16 | | | abort |
| `ZFREECNT` | 17 | | | RZ answers ZACK with zero (unknown/unlimited) |
| `ZCOMMAND` | 18 | | | RZ aborts; SZ re-sends ZRQINIT |


---

## 6. RZ in detail

### 6.1 Control flow

`receive_main` (RZ 08D1) prepares the session and then chooses the protocol.

1. Clear 97 bytes of protocol state starting at `escape_ctl_flag`, empty the AUX ring, and build the CRC-32 table.
2. Set up the receive buffer: it starts at the first free byte (`argv_ptr`, 2D11H) and extends to the BDOS; `calc_buffer_mask` rounds the size down to a power of two (section 2.5) and stores it in `rx_buffer_size`.
3. If `-p` was given, set `protect_option` to `ZMPROT` (7).  Set `crc_mode` to 10H (CRC-16).
4. Choose the protocol:

```
protocol < 3 (XModem)         prep_output_file ; xmodem_rx_file
protocol >= 3 (YModem, ZModem)
      zri_frame_type := ZRINIT
      zrinit_handshake
         carry set            -> abort_receive
         result 0             -> "no ZModem": YModem batch loop
         result ZCOMPL        -> done (the sender had already finished)
         anything else        -> zmodem_rx_files
YModem batch loop:   protocol := 3
      xmodem_rx_start         (receive block 0, which carries the file name)
      prep_output_file        (create the file)
      xmodem_rx_file          (receive the data blocks)
      repeat
```

`zrinit_handshake` returns 0 immediately unless `protocol` is 4, so `-y` goes straight to the YModem loop with no ZModem attempt.  Without options RZ first offers ZModem and falls back to YModem if no ZModem header arrives (section 6.2).  A failure or abort anywhere ends in `abort_receive`, which sends a cancel string (ten CAN characters followed by ten backspaces) and, if an output file is open, flushes and closes it.  Data already written to disk is therefore kept.

### 6.2 ZModem session

#### 6.2.1 The handshake (`zrinit_handshake`)

The handshake corresponds to `tryz` in the Unix `rz`.  It repeatedly sends a ZRINIT header and reads the sender's answer.

* The number of attempts is **5** if a valid header has already been seen (`header_ok_flag`) and **10** otherwise.
* Each attempt sends a **ZRINIT hex header** with `ZF0 = CANFC32` (the receiver accepts 32-bit CRC), `ZF1 = 0`, and `ZP0`/`ZP1` set to the size of the receive buffer, then waits up to 10 seconds for a header.  Declaring a buffer length tells the sender it must not send more than that between acknowledgements; `CANOVIO` is not set.
* If the previous frame was a ZSKIP, the ZRINIT slot carries it once, then ZRINIT resumes.

The answer is dispatched on the frame type:

| Received | Action |
|---|---|
| `ZRQINIT`, `ZEOF` | send ZRINIT again (no error counted) |
| timeout / error | count an error and send ZRINIT again |
| `ZCOMPL` | ignored; read the next header |
| `ZFREECNT` | answer `ZACK` with a zero position (free space unknown) |
| `ZSINIT` | read a data subpacket; if it ends with `ZCRCW` and its CRC is good, copy the first 32 bytes to `attn_string` and answer `ZACK`; otherwise answer `ZNAK`.  The ZF0 bit 40H (escape control characters) is stored in `escape_ctl_flag` first |
| `ZFILE` | save the four flag bytes (`zfile_zf3`..`zfile_zf0`), read the file-information subpacket; if it ends with `ZCRCW` with a good CRC return `ZFILE`; otherwise answer `ZNAK` |
| `ZFIN` | answer with ZFIN and wait for the sender's "OO" (`send_zfin_wait`), then return `ZCOMPL` |
| `ZCAN`, `ZCOMMAND` | abort (RZ does not execute remote commands) |
| anything else | count an error and send ZRINIT again |

When all attempts are used up without a usable header the handshake returns **0**, which `receive_main` treats as "the sender is not using ZModem".  On a sender that waits silently for XModem/YModem start characters, this means up to 10 ZRINIT attempts of up to 10 s each before the fallback; `-y` or an XModem file name avoids the delay.

The **attention string** received in a ZSINIT is saved so that it can be sent to the sender when RZ detects an error (section 6.2.4).  RZ sends it as ordinary characters: the special control codes defined by ZModem for the attention string (break and pause) are not interpreted.

#### 6.2.2 File information and file creation

The ZFILE data subpacket is `name NUL information`, the information being decimal fields (length and others).  `prep_output_file` (RZ 0961) turns the NUL after the name into a blank and uses `tokenize_args` to split the string into at most seven tokens (`info_argv`, `info_name_ptr`, `info_size_ptr`).  The first token is the file name; the second token, when present, is the announced length (RZ prints it but does not use it to validate the transfer).  The name is parsed with `parse_filespec` like a command-line name, so a drive or user prefix sent by the other side is interpreted as described in section 4.6; the file is then created in the default drive and user area.

Before creating the file RZ decides how to treat the data.

**Binary or text.**  `binary_mode_flag` (0FFH = store exactly as received):

| Condition | Result |
|---|---|
| neither `-b` nor `-c`, and the sender sent no conversion flag | binary |
| `-c` given | text conversion |
| sender requests `ZCNL` and `-b` was not given | text conversion |
| sender requests `ZCBIN` | binary (this overrides `-c`) |
| `-b` given | binary (always) |

**File management** (`zfile_zf1`):

* `-p` overrides the sender's ZF1 with `ZMPROT`.
* `ZMAPND` (append) combined with a binary transfer is changed to `ZMPROT`: appending binary data is not supported.

`file_exists` (BDOS search first) then decides what to do.

* **No such file.**  The file is created (BDOS function 22).  If creation fails the file is refused with `ZSKIP`.
* **The file exists** (`handle_existing`):
  * For XModem and YModem the old file is deleted (BDOS 19) and recreated, so an existing file is always replaced.
  * For ZModem, `ZMPROT` (from `-p` or from the sender) skips the file: RZ prints `File skipped` and answers `ZSKIP`.  Otherwise, `ZMAPND` (sender) or `-r` makes RZ open the file, compute its length in 128-byte records, and read the last record.  For **append** the last record is searched for the `^Z` end marker so the new data starts at the real end of a text file.  For **resume** RZ answers `ZRPOS` with the position of the start of the last record, so that record is rewritten (CP/M cannot tell where the data in a partial record ends).  Any other case deletes and recreates the file.

#### 6.2.3 The data phase (`zmodem_rx_file`)

`zmodem_rx_file` (RZ 0BD3) corresponds to `rzfile` in the Unix `rz`.  The central variable is `file_position`, the 32-bit position of the next byte RZ expects.

```
 prep_output_file ... (create/open)
 rx_send_zrpos:  restore buffer state ; write validated data ; send ZRPOS(file_position)
 rx_wait_header: get_header
    ZDATA   position == file_position ?  yes -> rx_get_data   no -> rx_data_error
    ZEOF    position == file_position ?  yes -> close file, return ZEOF   no -> rx_send_zrpos
    ZFILE   (sender repeats ZFILE) -> read and ignore its subpacket ; rx_send_zrpos
    ZNAK, timeout, junk, error -> rx_header_error
 rx_get_data:    rx_data_subpkt
    GOTCRCE  advance_position ; rx_wait_header           (frame ended, header follows)
    GOTCRCG  advance_position ; rx_get_data              (frame continues)
    GOTCRCQ  advance_position ; send ZACK(position) ; rx_get_data
    GOTCRCW  advance_position ; write buffer to disk ; send ZACK(position) ; rx_wait_header
    error / timeout / bad CRC -> rx_data_error (or rx_header_error for a timeout)
    ZCAN     abort
```

* `advance_position` adds the length of the subpacket just received to `file_position`, saves the buffer state (`rx_pos_save`) and resets the error counter.  The saved state marks the end of data that is known to be good.
* The data is **not written to disk for each subpacket**.  It accumulates in the receive buffer and is written when a `ZCRCW` subpacket arrives (the sender's buffer boundary), at a ZEOF, and when an error forces a resynchronization.  The sender is told the buffer size in the ZRINIT so that it ends each buffer-full with `ZCRCW`; an overflow of the buffer is reported as an error by `rx_data_subpkt`.
* On a **ZACK** reply (ZCRCQ and ZCRCW) the position field carries the current `file_position`.

#### 6.2.4 Error recovery

Two routines handle errors, both with a limit of **10 consecutive errors** (`error_count`, reset by every good subpacket), after which RZ aborts.

* `rx_header_error` (timeout, bad header, ZNAK): count the error, print the count, then resend `ZRPOS`.
* `rx_data_error` (bad data CRC, a ZDATA at the wrong position, a data error): count the error, **send the attention string** to the sender so that it stops its streaming, then resend `ZRPOS`.

`rx_send_zrpos` restores the saved buffer state (so data received after the last good subpacket is discarded), writes the validated data to disk, empties the AUX ring (to drop whatever the sender transmitted meanwhile) and sends ZRPOS with `file_position`.

A **disk write error** at a ZCRCW makes RZ prepare a `ZFERR` and abort.

#### 6.2.5 End of file and session

On a ZEOF whose position equals `file_position` RZ closes the file and returns `ZEOF`.  `zmodem_rx_files` (RZ 0BB4) then calls `zrinit_handshake` again, which sends a ZRINIT announcing readiness for the next file, and loops while the answer is a ZFILE.  A ZFIN ends the session: RZ answers ZFIN (up to four times, waiting 10 s each time for the first `O` of the sender's "OO", then briefly for the second; `send_zfin_wait`), then returns to the main routine, which exits.

A file skipped because it exists, or because it could not be created, ends with `ZSKIP`; the next ZRINIT carries the ZSKIP frame once so the sender moves on.

### 6.3 Writing to disk

RZ writes with one 128-byte sector buffer (`file_sector_buf`, controlled by `file_buf_count`, `file_buf_wr`, `file_buf_rd`).

* `write_buf_file` hands the bytes of the receive buffer to `file_putc` one at a time.  In **text mode** it inserts a CR before every LF that is not already preceded by a CR (`prev_char` remembers the previous source byte), so Unix line ends become CP/M line ends.  In binary mode bytes are stored unchanged.
* `file_putc` collects bytes in the sector buffer; when it is full it sets the DMA address (BDOS 26), sets the multi-sector count to 1 (BDOS 44) and writes the record with BDOS function 21.  A write error returns carry.
* `close_outfile` writes the pending data, then pads the final record with `^Z` (1AH) and writes it so that the file ends on a record boundary, and closes the file (BDOS 16).  A file whose length is an exact multiple of 128 bytes gets no padding record.

### 6.4 XModem and YModem reception

#### 6.4.1 Starting

For XModem the file name comes from the command line.  For YModem the name arrives in **block 0**, which RZ requests with `xmodem_rx_start`:

* RZ sends `C` (CRC mode, `crc_mode` = 10H) or NAK (checksum mode) and waits up to 10 s for a block.
* On success it acknowledges and goes on to `prep_output_file`, which takes the file name from the block exactly as it takes it from a ZFILE packet.
* If an EOT arrives, it is acknowledged and the start sequence is repeated.
* An empty block 0 (no name) ends the batch.  `prep_output_file` returns carry in that case, so the batch ends through `abort_receive` (which sends a cancel string after the sender has already finished).

For XModem `xmodem_rx_file` sends `C` or NAK itself.  If, in CRC mode, no valid first block arrives, RZ **falls back to checksum mode** and starts again.

#### 6.4.2 A block (`xmodem_get_block`)

The caller passes the timeout for the first character: 13 s before the first block, 5 s afterwards.  The first character selects the action:

| Character | Action |
|---|---|
| `SOH` (01H) | 128-byte block |
| `STX` (02H) | 1024-byte block |
| `EOT` (04H) | wait 1 s: if the line stays silent the end of file is confirmed (internal code 0F6H) |
| `CAN` (18H) | a second CAN in a row aborts; the first is counted as an error |
| anything else, or a timeout | bad block |

For `SOH`/`STX`: read the block number and its complement (each within 1 s; their sum must be FFH), then the data bytes (each within 1 s, stored in the receive buffer and added to both the CRC and the checksum), then the check value: two CRC bytes in CRC mode (the CRC over data and the CRC bytes must be zero) or one checksum byte.

A **bad block** is handled in `xm_bad_block`: the line is drained until it is silent for 1 s, then RZ sends `C` or NAK if no block has yet been accepted, or NAK (with the timeout lowered to 4 s) afterwards, restores the buffer state and counts an error.  After **5 errors** the block is abandoned and the transfer aborts.

#### 6.4.3 The block loop

For each accepted block the loop compares the block number with the expected one:

* the **same number as the previous block** (a repeated block): acknowledge it without storing the data;
* the **next number**: add the block length to `file_position`, write the data (`write_buf_file`) and acknowledge;
* any other number: error.

The data is written to disk after every block.  On the confirmed EOT RZ closes the file, acknowledges and returns.  XModem and YModem data is always stored in binary mode (`-c` has no effect), and the padding of the last block (`^Z` or zeros added by the sender) is stored with the file because the announced length is not used to trim it.

### 6.5 Progress display and abort

During reception RZ shows the file name and a running count of bytes (`print_position`, overwriting one line), the spinner and the error count.  Pressing ESC ends the transfer through the injected CANs described in section 4.2.


---

## 7. SZ in detail

### 7.1 Control flow

SZ has more to do before the transfer starts, because it must find the files to send.

```
main:  version check, banner, save drive/user, tokenize command tail, options
       parse the file specification, select its drive/user
       build_file_list        (search the directory, filter, sort)  -> count, list
       print "<n> File(s) requested" and the "start your local receive program" prompt
       file buffer := free memory after the list, rounded to a power of two
       scb_setup
       send_main
       scb_restore, restore drive/user, warm boot
```

`send_main` (SZ 0854) then

1. **converts the protocol**: if `protocol` is 4 (ZModem, the default, or `-z`) it is changed to 3 (YModem).  `-y` also gives 3 and `-x` gives 1.  The significance is explained in 7.3: a ZModem receiver is detected at start-up and switches SZ to ZModem, so `-y` and `-z` and no option at all behave identically;
2. clears 80 bytes of state, clears the work FCB, builds the CRC-32 table and empties the AUX ring;
3. sizes the file buffer with `calc_buffer_mask` and sets `subpacket_size` to 1024;
4. calls `send_files`.

`send_files` (SZ 08C1) loops over the list:

```
for each file entry:
    fetch_file_entry            -> work FCB for this file
    buffer_start_pos := 0
    send_one_file               -> 0 = sent, ZSKIP = receiver declined, carry = failed
    if ZSKIP: print "File skipped"
    file_close_input
    on carry: send cancel string, return error
if no file was sent: print "can't open any file", send cancel string, return error
end of session:
    XModem: nothing more
    YModem: send an empty block 0 (128 zero bytes) to end the batch
    ZModem: send_zfin_oo
```

### 7.2 Building the file list

`build_file_list` (SZ 17C9) reads the directory with the BDOS search functions and produces a sorted table of 16-byte entries in free memory.  It is called by `main` with a **selection mask** in `A` and the FCB (with wildcards) in `DE`.

**Selection mask** (`dir_attr_mask`): bit 7 = include DIR files, bit 6 = include SYS files, bit 5 = match any user number, bits 0-4 = user number.  `main` passes the user number OR 0C0H, so both directory and system files are included and only the selected user area is searched.

**Steps**

1. `dir_table_init` reads the disk parameter block (BDOS 31) to find the maximum number of directory entries, fills in the sort control block (item size 16) and reserves a **pointer index** of that many words; the 16-byte entries follow the index.
2. `dir_collect` runs BDOS Search First (17) and then Search Next (18) with a wildcard FCB (`????????.???`), which matches every directory entry.  Each successful call returns in `A` the position (0-3) of a 32-byte directory entry within the 128-byte record at the DMA address (0080H); `dir_add_entry` extracts that entry.
3. `dir_add_entry` takes each entry in turn.  Erased entries (first byte E5H) and special entries (user number 21H and above) are ignored.  Otherwise the first 16 bytes (user, 8+3 name characters, extent and the following three bytes) are appended to the table unless `dir_find_dup` finds the same user and name already present.  Large files appear in several directory entries (one per extent); `dir_find_dup` keeps only one, the **lowest extent** when `dir_dup_mode` is non-zero and the highest otherwise.  `build_file_list` uses the non-zero mode.  The loop stops when the table is full.
4. `dir_mark_matches` compares every entry with the file specification (name and extension, with `?` matching any character) and with the selection mask (`dir_check_attr`), and sets bit 7 of the user byte of each entry that qualifies.
5. `dir_compact` removes the unmarked entries and clears the marks; the count is returned in `C`.
6. `sort_file_list` sorts the entries.

Because the count is held in one byte (`file_count`), SZ can send at most 255 files in one run.

**The sort.**  `sort_alloc_index` builds an index of one pointer per entry.  `sort_shell` sorts the *pointers* with a **Shell sort**: the gap starts at N/2 made odd and is halved on each pass, items are compared through the callback `dir_compare` and swapped with `sort_swap`.  `sort_entries` then rearranges the real entries in place by following the permutation cycles with `sort_copy_ents`.  `dir_compare` compares two entries: key 0 compares the name, extension and extent and then the user number; a non-zero key compares the extension first.  `main` uses key 0, so files are sent in name order.

### 7.3 Choosing and starting the protocol (`wait_rx_start`)

Before the first file, and before every YModem file, SZ calls `wait_rx_start` (SZ 09D9):

1. If `protocol` is 3 or more, SZ sends a **ZRQINIT hex header**, which a ZModem receiver answers and which a YModem or XModem receiver ignores.
2. It then waits up to 25.5 s for a character and dispatches on it:

| Character | Meaning | Action |
|---|---|---|
| `ZPAD` (`*`) | the receiver is speaking ZModem | run `zmodem_send_init`; on success set `protocol` to 4 |
| `C` | receiver wants CRC | set `tx_crc_mode` to 10H; start |
| NAK | receiver wants a checksum | start |
| `CAN` | possible cancel | a second CAN within 2 s aborts, otherwise continue waiting |
| timeout | no receiver | fail |

So a request for ZModem (or YModem) starts as a YModem session and is **upgraded to ZModem** if the receiver answers with a ZModem header.  A receiver that answers `C` or NAK is served with YModem.  `-x` skips the ZRQINIT and goes straight to XModem.

For ZModem sessions after the first file, `build_file_info` skips `wait_rx_start` (it checks that the last terminator sent was `ZCRCE`, which is the case after a completed ZModem file).

### 7.4 Reading the file and the retransmission ring

SZ reads the file through a **buffered file object** (section 7.8).  Data read for transmission is kept in a ring buffer in free memory so that it can be sent again after a ZRPOS without re-reading the disk.

* The ring has `file_buffer_size` bytes (a power of two, at most 32 KB) and mask `buffer_mask`.  The byte at file position `p` lives at `file_buffer_base + (p AND mask)` (`ring_buffer_addr`).
* `file_read_pos` is the position of the next byte to be read from the disk; `tx_position` and `last_sync_pos` track the next byte to be sent.
* `fill_file_buffer` reads a number of bytes from the file into the ring and advances `file_read_pos`; end of file sets `eof_flag`.
* `get_next_chunk` supplies the next subpacket: if the next byte to send has not been read yet it reads up to `subpacket_size` bytes from the file; otherwise (a retransmission) it takes the data already in the ring, up to `subpacket_size` bytes or up to `file_read_pos`.  When the chunk ends the file it sets `eof_pending`.
* `reposition_file` moves the send position after a ZRPOS.  If the requested position is still inside the ring (not older than the ring size and at least 1 KB behind the read position) nothing is read.  If it is older than the ring, the file is closed, reopened and read forward (`file_rewind_skip`) to the 1 KB boundary at or below the target, and the ring is refilled from there.  If it is newer, the file is read forward from the current position (`file_skip_fwd`) to that boundary and the ring refilled.

**File size.**  SZ gets the size with BDOS function 35 (record count) and multiplies it by 128.  The size announced to the receiver is therefore always a multiple of 128 bytes and SZ sends the file as stored on disk, including any `^Z` padding in the last record.

### 7.5 ZModem sending

#### 7.5.1 Session start (`zmodem_send_init`)

`zmodem_send_init` (SZ 0BF0) corresponds to `getzrxinit` in the Unix `sz`.  It reads headers, up to **10 times**, dispatching on the frame type:

| Received | Action |
|---|---|
| `ZRINIT` | `zmodem_got_zri`: read the receiver's flags and buffer length (below); done |
| `ZCHALLENGE` | answer `ZACK` with the same 32-bit value |
| `ZCOMMAND` | send `ZRQINIT` again |
| `ZRQINIT` | if ZF0 says ZCOMMAND, ignore; otherwise answer `ZNAK` |
| `ZCAN`, timeout | abort |
| anything else | answer `ZNAK` |

`zmodem_got_zri` takes from the ZRINIT header

* **ZF0 bit 20H (`CANFC32`)**: if set, `tx_crc_mode` is 20H and all further headers and subpackets use CRC-32;
* **ZF0 bit 40H (`ESCCTL`)**: if set, `escape_ctl_flag` makes `put_zdle_char` escape all control characters;
* **ZP0/ZP1** = the receiver's buffer length in `rx_window_size`.  A zero means the receiver declared no limit, in which case SZ substitutes a **32 KB window**.

It also sets the subpacket size to 1024 bytes.  SZ does not send ZSINIT.

#### 7.5.2 Announcing a file (`zmodem_snd_zfile`)

`build_file_info` first builds the file information at the start of the file buffer: the file name in lower case (letters of `NAME.EXT`), a NUL, and the size in decimal.  `zmodem_snd_zfile` then sends:

1. a **ZFILE binary header** with four flag bytes: `ZF0 = ZCBIN` (`-b`) or `ZCNL` (`-c`) or 0; `ZF1 = ZMPROT` (`-p`) or `ZMAPND` (`-a`) or 0; `ZF2 = ZF3 = 0`;
2. the information as a data subpacket terminated with **ZCRCW**.

The receiver's answer is read with `get_header` (10 s timeout):

| Received | Action |
|---|---|
| `ZRPOS` | set all position variables to the requested position, reposition the file, and start sending data (section 7.5.3) |
| `ZSKIP` | skip this file (return `ZSKIP`) |
| `ZRINIT` | the receiver has not seen the ZFILE: wait up to 5 s for a `ZPAD` and read the next header; if none arrives, send the ZFILE again |
| `ZCRC` | ignored |
| `ZFIN`, `ZABORT`, `ZCAN`, timeout | abort |
| anything else | send the ZFILE again |

#### 7.5.3 Streaming data (`zmodem_stream`)

`zmodem_stream` (SZ 0DB6) corresponds to `zsendfdata`.  It sends one or more ZDATA frames:

```
window_remaining := rx_window_size
send ZDATA(tx_position)   (binary header)
loop:
    get_next_chunk                         -> chunk of up to subpacket_size bytes
    choose the terminator:
        end of file in this chunk          -> ZCRCE
        four or more junk characters seen  -> ZCRCW
        position equals last ZRPOS         -> ZCRCW   (be careful after a repeat)
        window exhausted                   -> ZCRCW
        otherwise                          -> ZCRCG
    send_subpacket(chunk, terminator)
    tx_position += chunk length ; last_sync_pos := tx_position
    if ZCRCW: wait for the receiver's answer (7.5.4) and, on ZACK, start a new ZDATA frame
    else: sample the reverse channel (below), then loop
at end of file: send ZEOF(tx_position)    (7.5.5)
```

The window is decremented by every chunk; when it reaches zero the terminator is `ZCRCW`, which makes the receiver acknowledge, so the amount of data in flight never exceeds the receiver's declared buffer.  After the acknowledgement `zmodem_stream` starts again with a fresh ZDATA header at the current position and a full window.

**Sampling the reverse channel.**  After every subpacket that did not end with `ZCRCW`, SZ checks the AUX port for incoming data (`aux_poll_input`).  If nothing is waiting it carries on.  Otherwise it reads a character:

* `ZPAD` or `ZDLE`: the receiver is sending a header.  SZ reads it (`zmodem_get_resp` with "accept any ZACK"): a `ZACK` lets streaming continue; any other frame (normally `ZRPOS`) makes SZ **discard everything waiting in the AUX ring**, send an **empty ZCRCE subpacket** to end the current frame cleanly, and then act on the response;
* XON/XOFF (`13H`, `93H`): the line is paused; SZ waits up to 10 s for the next character;
* any other character is counted as junk (`resp_junk_count`).

#### 7.5.4 The receiver's answer (`zmodem_get_resp`)

`zmodem_get_resp` (SZ 0ED1) reads a header and dispatches:

| Received | Action |
|---|---|
| `ZACK` | remember its position (`zack_pos`).  With mode FFH the position must equal `tx_position`, otherwise the ACK is ignored as stale; with mode 0 any ACK is accepted |
| `ZRPOS` | `zmodem_do_zrpos`, below |
| `ZRINIT` | the file is finished from the receiver's point of view: close the file |
| `ZSKIP` | return `ZSKIP` |
| error (bad header) | send a `ZNAK` binary header and read again |
| `ZFIN`, `ZABORT`, `ZCAN`, timeout | abort |

`zmodem_do_zrpos` is the retransmission step: it repositions the file (`reposition_file`), clears `eof_pending`, counts and prints an error, and sets `tx_position`, `last_sync_pos` and `zack_pos` to the requested position.  If the receiver asks for **the same position again** `same_zrpos_count` is incremented, and when it reaches 5 the **subpacket size is halved** (but never below 32 bytes).  There is no limit on the number of ZRPOS requests; shrinking the subpackets is the only adaptation to a noisy line.

#### 7.5.5 End of file

When the last chunk has been sent, `zmodem_send_zeof` sends `ZEOF` carrying the final `tx_position` and waits for the answer: `ZRINIT` completes the file, `ZRPOS` repositions and resumes streaming, `ZACK` makes SZ send the ZEOF again, `ZSKIP` returns `ZSKIP`, anything else fails.  For the next file `send_files` calls `send_one_file` again; the ZFILE header is sent in answer to the same ZRINIT.

At the end of the batch `send_zfin_oo` sends a hex `ZFIN`, reads the receiver's answer, and when the answer is ZFIN sends the two characters **`OO`** (over and out).  Any other frame causes the ZFIN to be sent again; a timeout or ZCAN ends the exchange.

### 7.6 XModem and YModem sending

XModem and YModem share one block sender.

**Starting.**  For YModem, SZ first runs `wait_rx_start` (7.3) and sends block 0 containing the file name and size as text (128 bytes, zero padded): the same name/size string used for ZFILE.  For both protocols `xmodem_wait_rx` (SZ 0A4C) then waits for the receiver: a NAK requests checksum blocks, a `C` requests CRC blocks (`tx_crc_mode` = 10H); a CAN or a timeout (25.5 s) aborts.  Block numbering starts at 1 for the data blocks.

**Block size.**  `xmodem_snd_blks` computes the remaining length (`file_size - tx_position`).  If at least 1024 bytes remain the block is **1024 bytes** (`STX`), otherwise **128 bytes** (`SOH`).  Because the size is a multiple of 128, no padding is ever needed.  This applies to XModem as well, so a 128-byte-only XModem receiver cannot receive from SZ when files are 1 KB or longer.

**One block** (`xmodem_snd_block`): `SOH` or `STX`, block number, its complement, the data, then the CRC-16 (two bytes, high first) or the 8-bit checksum.  The response is awaited for 10 s:

| Response | Action |
|---|---|
| `ACK` | success |
| `NAK` | count an error and send the block again |
| `C` | on the first block, switch to CRC mode and resend; later it is treated like NAK |
| timeout | count an error and resend |
| `CAN` | two in a row abort |
| anything else | read further characters (10 s each) until ACK, NAK or `C` appears; a timeout resends the block |

After **5** errors in one block the transfer aborts.

**Ending.**  When no data remains `xmodem_send_eot` sends `EOT` and waits 10 s for an ACK, up to 5 times.  YModem then continues with the next file (a new `wait_rx_start` and block 0); at the end of the batch SZ sends an all-zero block 0.

### 7.7 Console, abort and errors

SZ prints each file name (`print_filename`) and updates the byte position during blocks and subpackets.  A file the receiver declines is reported with `File skipped`.  If no file could be opened it prints `can't open any file`.  ESC aborts through the injected CANs (section 4.2); SZ then sends a cancel string.

### 7.8 The buffered file object

SZ's file access is built on a general **file object** of 168 bytes (`CIO_SIZE`), two of which exist (`in_file`, `out_file`):

| Offset | Name | Contents |
|---|---|---|
| 0 | `CIO_FLAG` | 0 = closed, FFH = open |
| 1 | `CIO_COUNT` | bytes left in the sector buffer (0-128) |
| 2 | `CIO_PTR` | pointer to the next byte in the buffer (16 bits) |
| 4 | `CIO_FCB` | a 36-byte FCB |
| 40 (28H) | `CIO_BUF` | 128-byte sector buffer |

The routines operate on the object selected by `select_input_handle` or `select_output_handle`.  A read refills the buffer with BDOS function 20 (one record, multi-sector count 1); a write uses function 21; a close pads the last sector with `^Z` and zeros before closing.  Errors are returned in `A`:

| Code | Meaning |
|---|---|
| 1 | object not open |
| 2 | write error (disk full) |
| 3 | open failed |
| 4 | read failed or end of file |
| 5 | create failed |
| 6 | close failed |
| 7 | already open |

SZ's own logic uses only the input object; the output routines are part of the general-purpose library that the program carries.


---

## 8. Error handling and limits

### 8.1 Retry limits

| Situation | Program | Limit |
|---|---|---|
| ZRINIT attempts before falling back to YModem | RZ | 5 (after a valid header has been seen) or 10 |
| Consecutive header or data errors during a ZModem file | RZ | 10, then abort |
| Errors per XModem/YModem block | RZ | 5, then abort |
| CRC-mode start attempts before falling back to checksum | RZ | 5 errors on the first block |
| Header reads while starting ZModem | SZ | 10 |
| Errors per XModem/YModem block | SZ | 5, then abort |
| EOT transmissions | SZ | 5 |
| Repeated ZRPOS for one position before halving the subpacket | SZ | 5 (no overall limit) |
| ZFIN transmissions in the closing exchange | RZ | 4 |

### 8.2 Other limits

| Item | Value |
|---|---|
| Largest transfer buffer | 32 KB (power of two, 256 bytes or more) |
| ZModem subpacket size | 1024 bytes, reduced to as little as 32 bytes after repeated ZRPOS |
| Window assumed when the receiver declares none | 32 KB |
| Attention string kept by RZ | 32 bytes |
| Junk characters tolerated while looking for a header | 1024 |
| Files in one SZ run | 255 |
| Command line tokens | 2 |
| Position and size range | 32 bits |
| Announced file size granularity | 128 bytes |
| File name | 8.3, wildcards only in SZ |

### 8.3 Aborting and cancelling

A cancel is requested in three ways: by the user (ESC), by the peer, or by an internal failure.

* **User**: ESC makes the next timed read return ten CAN characters (section 4.2); the protocol layers treat them as a cancel from the peer.
* **Peer**: five CANs in a row are recognized by `get_header` and `zdlread_escape` (ZModem); two in a row by the XModem routines.
* **Internal failure**: the routine returns carry to the top-level routine, which sends the cancel string (`send_can_string`: ten CANs followed by ten backspaces; the backspaces erase the CANs on a terminal that echoes them) and returns to the start-up code.  RZ also closes the output file, so a partial file stays on disk.

In every case the start-up code restores the System Control Block and the drive and user, then warm boots.

### 8.4 BDOS functions used

The programs use only BDOS calls.  Appendix D lists the functions used by each.

---

## 9. Observations

These items follow from the code.  Some may be unintended consequences of the design; none changes the description above.

1. **SZ treats `-y`, `-z` and no option identically.**  `send_main` turns protocol 4 into 3 before anything is sent, and the ZRQINIT/`wait_rx_start` exchange then decides between ZModem and YModem according to the receiver's reply (section 7.3).  Only `-x` forces XModem.  There is no downgrade from a ZModem start to YModem once the receiver has answered with a ZModem header.

2. **The ZCPR3 environment pointer.**  RZ contains the environment-aware parsing routines but never sets `z3env_ptr`, and has no `Z3ENV` header; the word lives in uninitialized memory at 2D0FH.  With a zero pointer the helper routines read page zero (section 4.6) and accept drive/user prefixes with no limits; named directories can effectively not be resolved.  If the word happens to be non-zero (stale memory from a previous program), the helpers read from an arbitrary address.  SZ initializes the pointer from its header, which is zero unless the Z3INS installer has patched it.

3. **SZ sends 1024-byte blocks in XModem mode** whenever at least 1024 bytes remain, so a strict 128-byte XModem receiver cannot take files of that size from SZ.

4. **File sizes and timestamps.**  SZ announces `name NUL size` only, with no modification time, mode or serial number, and the size is the record count times 128, so the receiver cannot tell where the real data ends in the last record.  SZ sends the `^Z` padding with the file.  RZ ignores the announced size when receiving.

5. **ZBIN32 header type byte.**  In a binary header with CRC-32, SZ sends the frame type without passing it through the ZDLE escaping routine, while the four argument bytes and the CRC are escaped.  The frame types SZ actually sends (ZFILE, ZDATA, ZEOF, ZNAK) are not characters that need escaping unless the receiver has requested escaping of all control characters.

6. **A 32-bit AND on a 16-bit mask.**  In `get_next_chunk` the call `and32` takes `buffer_mask` as a 32-bit operand, but the variable is only two bytes and its neighbour is `buffer_start_pos`.  The two upper result bytes are therefore meaningless; they are harmless because only the low 16 bits of `buffer_start_pos` are used (`ring_buffer_addr`).

7. **End of a YModem batch in RZ.**  An empty block 0 makes `prep_output_file` return carry, so the batch ends through `abort_receive`, which sends a cancel string after the sender has finished.

8. **`-c` and `-b` in RZ.**  A sender's request for a binary file (`ZCBIN`) overrides `-c`, although the usage text says the options override the sender's.  For XModem and YModem the data is always stored unchanged.

9. **`ZFERR`.**  After a disk write error RZ prepares a ZFERR frame, but the session ends with the cancel string; the frame is not sent.

10. **Attention string and unsupported frames.**  The attention string is sent as plain characters, so the break and pause codes are not honored.  ZCOMMAND is not supported by RZ, ZSINIT is never sent by SZ, and SZ ignores ZCRC.

11. **Time-outs depend on CPU speed.**  All time-outs derive from software delay loops that appear tuned for roughly a 13 MHz Z80 (section 4.3).

12. **Interrupted resume.**  `-r` restarts from the beginning of the last record of the existing file, not from its exact length, because CP/M files have 128-byte granularity.

13. **Names.**  SZ lowercases the file name it announces; RZ upper-cases whatever name arrives and does not check it for characters that are invalid on CP/M.



---

## Appendix A: Routine index

Addresses are those of the commented disassembly.  The last column gives the counterpart in the Unix `rz.c`, `sz.c` or `zm.c` sources where there is one.  Routines whose names start with `rx_`, `zri_`, `zd_`, `zs_`, `zeof_`, `resp_`, `xs_` or `xm_` are entry points of the state machines described in sections 6 and 7.

### A.1 RZ

**Start-up, options and console output**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0100 | `start` | Program entry: check for CP/M 3, show banner, parse command line, run the transfer, restore the default drive/user and exit. |  |
| 0195 | `get_default_du` | Save the current user number and drive (from IOBYTE/0004H) so they can be restored at exit. |  |
| 01B0 | `set_du` | Select user number and drive from a (user,drive+1) pair addressed by DE (BDOS F_USERNUM, DRV_SET). |  |
| 01C2 | `err_need_cpm3` | Print "sorry, CP/M 3 Tool" and exit. |  |
| 01CA | `usage_exit` | Print the usage/help text and exit to CP/M. |  |
| 039A | `parse_options` | Scan a "-xyz" option string; each letter is looked up in the option key table and its handler is run. |  |
| 03C9 | `opt_xmodem` | Option X: select XMODEM. |  |
| 03CD | `opt_ymodem` | Option Y: select YMODEM. |  |
| 03D1 | `opt_zmodem` | Option Z: select ZMODEM. |  |
| 03D3 | `set_protocol` | Store protocol number in A (1=XMODEM, 3=YMODEM, 4=ZMODEM). |  |
| 03D7 | `opt_protect` | Option P: protect existing files (do not overwrite). |  |
| 03DD | `opt_binary` | Option B: binary transfer. |  |
| 03E3 | `opt_convert` | Option C: convert to local linefeed convention. |  |
| 03E9 | `opt_resume` | Option R: resume an interrupted transmission. |  |
| 03EF | `scb_setup` | Detach the modem port from the console: read AOVEC (SCB 28H) via BDOS 49 and clear its devices from COVEC (24H) and CIVEC (22H), keeping the originals. |  |
| 0451 | `scb_restore` | Put the original console input/output redirection vectors (CIVEC, COVEC) back into the System Control Block. |  |
| 0471 | `bdos_check` | Call BDOS (function in C) and set Z/NZ from the result in A. |  |
| 0476 | `skip_strings` | Advance HL past B zero-terminated strings. |  |
| 0482 | `print_err_count` | Print the current error count / retry message on the console. |  |
| 04A4 | `print_filename` | Print the current file name (DU:NAME.EXT) and its size. |  |
| 050B | `print_position` | Print the current file position as a decimal number on the console. |  |
| 0529 | `spinner_entry` | Entry to the spinner display. |  |
| 052A | `show_spinner` | Advance and print the rotating "\|/-\" activity spinner. |  |
| 054D | `print_cant_open` | Print "can't open any file". |  |
| 0552 | `print_skipped` | Print "File skipped". |  |
| 057F | `set_pending_char` | Queue A (count in C) as pending input characters; used to inject CANs when ESC is pressed. |  |

**AUX I/O, ring buffer and file buffers**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0588 | `aux_poll_input` | Poll the AUX device (BDOS A_STATIN/A_READ) and move any waiting characters into the receive ring buffer. |  |
| 05B4 | `aux_get_char` | Fetch next input character: pending queued char first, otherwise from the ring buffer. |  |
| 05C7 | `aux_putc` | Write the character in A to the AUX (modem) device. |  |
| 05CD | `aux_out_ready` | Test whether the AUX output is ready (BDOS A_STATOUT). |  |
| 05D4 | `aux_wait_input` | Wait roughly 100 ms-steps for an input character; returns it in A with NZ, Z on timeout. |  |
| 05EB | `delay_short` | Short software delay loop. |  |
| 05F7 | `ring_get` | Remove one byte from the receive ring buffer. |  |
| 061C | `ring_put` | Insert byte C into the receive ring buffer. |  |
| 0643 | `clear_fcb` | Zero the 37-byte FCB at HL. |  |
| 064A | `file_buf_reset` | Reset the 128-byte file sector buffer control block. |  |
| 064E | `ring_reset` | Clear the 6-byte ring buffer control block at HL. |  |
| 0654 | `file_buf_get` | Get next byte from the sector buffer; carry/zero indicates empty. |  |
| 0669 | `file_buf_put` | Store byte C in the sector buffer; NZ when a sector is full. |  |

**Dispatch, 32-bit arithmetic, CRC and number output**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 067F | `dispatch` | Table dispatcher: after CPIR over N keys, jump to the matching vector stored (in reverse order) after the key list. |  |
| 0688 | `zero32` | Set the 32-bit value at (HL) to 0. |  |
| 0692 | `copy32` | Copy 32-bit value (HL) to (DE). |  |
| 06A1 | `cmp32_signed` | Signed compare of 32-bit values (HL) and (DE); sets carry/zero. |  |
| 06C2 | `cmp32_unsigned` | Unsigned compare of 32-bit values (HL) and (DE). |  |
| 06D3 | `eq32` | Compare 32-bit values (HL) and (DE) for equality (Z if equal). |  |
| 06E4 | `add32` | (BC) = (DE) + (HL), 32-bit. |  |
| 06FA | `sub32` | (BC) = (HL) - (DE), 32-bit. |  |
| 0712 | `inc32` | Increment the 32-bit value at (HL). |  |
| 0726 | `set32_minus1` | Set the 32-bit value at (HL) to -1 (0FFFFFFFFH). |  |
| 0729 | `dec32` | Decrement the 32-bit value at (HL). |  |
| 073B | `and32` | (BC) = (DE) AND (HL), 32-bit. |  |
| 0774 | `ltoa32` | Convert the 32-bit value at (HL) to decimal ASCII at (DE) (zero terminated). |  |
| 07DD | `checksum_add` | Add A to the running 8-bit XMODEM checksum. |  |
| 07ED | `crc32_update` | Update the running CRC-32 with byte A. |  |
| 0825 | `crc32_table_init` | Build the 256-entry CRC-32 lookup table. |  |
| 0885 | `crc16_update` | Update the running CRC-16 (CCITT, polynomial 1021H) with byte A. | `updcrc` |
| 08A0 | `crc_init` | Reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH. |  |
| 08B6 | `calc_buffer_mask` | Round the available buffer size down to a power of two and derive the wrap-around mask. |  |

**Receive control, ZModem session and file output**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 08D1 | `receive_main` | Top-level receive: set up buffers and CRC table, then run ZMODEM or XMODEM/YMODEM reception. | `rz.c wcreceive` |
| 0954 | `abort_receive` | send the cancel string and close any open file. |  |
| 0961 | `prep_output_file` | Work out transfer options and file name for the incoming file, check/handle an existing file and create the output file. | `rz.c procheader` |
| 0A11 | `handle_existing` | Output file exists: skip, overwrite or resume depending on the options and the sender's flags. |  |
| 0ACF | `zrinit_handshake` | Send ZRINIT headers and wait for the sender's ZFILE/ZSINIT/ZFIN. | `rz.c tryz` |
| 0B1A | `zri_read_hdr` | Read the next header without sending anything. |  |
| 0B28 | `zri_count_err` | Count an error, then try again. |  |
| 0B2F | `zri_resend` | Send ZRINIT again (no error counted). |  |
| 0B34 | `zri_abort` | ZCAN received, or a request this program does not support (ZCOMMAND): abandon the session. |  |
| 0B39 | `zri_got_zfin` | the sender has finished the session [tryz: ackbibi, return ZCOMPL]. |  |
| 0B40 | `zri_got_zfreecnt` | the sender asks for the free disk space; answer ZACK with 0 = unknown/unlimited. |  |
| 0B48 | `zri_got_zsinit` | the sender announces its flags and Attn string; read the data packet, answer ZACK, or ZNAK if it was damaged. |  |
| 0B7B | `zri_got_zfile` | a file is offered; keep the option bytes, read the file-name data packet and return ZFILE. |  |
| 0BB4 | `zmodem_rx_files` | Receive successive files until ZFIN. | `rz.c rzfiles` |
| 0BD3 | `zmodem_rx_file` | Receive one file: send ZRPOS and process ZDATA/ZEOF until complete. | `rz.c rzfile` |
| 0BF0 | `rx_send_zrpos` | Tell the sender where to (re)start: ZRPOS with the current file position [rzfile: stohdr(rxbytes); zshhdr(ZRPOS)]. |  |
| 0C0A | `rx_wait_header` | Wait for the next header from the sender and act on its type [rzfile: switch (zgethdr)]. |  |
| 0C1C | `rx_header_error` | Timeout, ZNAK or garbage: count the error (10 allowed) and send ZRPOS again. |  |
| 0C36 | `rx_got_zeof` | if its offset equals the bytes received the file is complete, otherwise ask again with ZRPOS. |  |
| 0C57 | `rx_data_error` | Bad or misplaced data: count the error, send the Attn string to stop the sender, then ZRPOS. |  |
| 0C73 | `rx_got_zdata` | its offset must equal the bytes received so far, otherwise resynchronise with ZRPOS. |  |
| 0C7F | `rx_get_data` | Receive one data subpacket and act on how it ended (ZCRCE/G/Q/W). |  |
| 0C93 | `rx_got_cancel` | Sender cancelled the session. |  |
| 0C97 | `advance_position` | Count the subpacket just received into the file position and save the buffer state. |  |
| 0CAA | `rx_got_crce` | last subpacket of the frame; no reply, a header follows. |  |
| 0CB0 | `rx_got_crcg` | more data follows immediately; no reply. |  |
| 0CB6 | `rx_got_crcq` | more data follows; acknowledge the position with ZACK. |  |
| 0CCA | `rx_got_crcw` | write the buffered data to disk and acknowledge with ZACK; the sender waits for it. |  |
| 0D0E | `close_outfile` | Flush buffered data, pad to a sector, and close the output file. | `rz.c closeit` |
| 0D30 | `write_buf_file` | Write the received data buffer to the file, translating CR/LF if text conversion is on. | `rz.c putsec` |
| 0D68 | `file_putc` | Write byte A to the file via the sector buffer. |  |
| 0D9B | `send_zfin_wait` | Send ZFIN and wait for the sender's "OO" over-and-out. | `rz.c ackbibi` |

**Character input, ZDLE decoding, header and subpacket reception**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0DD9 | `send_can_string` | Send eight+ CAN characters followed by backspaces to abort the peer. | `canit` |
| 0DDC | `send_string` | Send the zero-terminated string at HL to the modem. | `rz.c zmputs` |
| 0DE7 | `aux_getc_timeout` | Get a character from the modem with timeout (B = tenths of a second). | `readline` |
| 0E05 | `getc_7bit_filt` | Get a modem char, strip bit 7 and ignore XON/XOFF/CR/LF/ZDLE. | `zm.c noxrd7` |
| 0E2F | `getc_zdl_filt` | Get a modem char, ignore XON/XOFF and decode ZDLE escapes. | `zm.c zdlread` |
| 0E50 | `zdlread_escape` | Decode the byte following a ZDLE (CAN) escape: frame-end codes, ZRUB0/ZRUB1, or XOR 40H. | `zm.c zdlread` |
| 0EC7 | `rx_data_subpkt` | Receive a ZMODEM data subpacket into the buffer, check its CRC and terminator. | `zm.c zrdata` |
| 0F4E | `rx_err_return` | Return an error (carry set, A = FFH). |  |
| 0FA2 | `is_crc32_mode` | Z if the link is using 32-bit CRC (flag 20H). |  |
| 0FAA | `rx_buffer_reset` | Reset the receive buffer pointers to the start. |  |
| 0FBA | `rx_pos_save` | Save buffer pointer/count. |  |
| 0FC9 | `rx_pos_restore` | Restore buffer pointer/count. |  |
| 0FD1 | `get_header` | Receive a ZMODEM header (hex, binary16 or binary32); returns frame type in A, carry on error. | `zm.c zgethdr` |
| 1012 | `hdr_zdle_zdle` | A second ZDLE: count a CAN; five in a row return ZCAN. |  |
| 101D | `hdr_zdle_zcrcw` | ZDLE then ZCRCW: wait briefly for one more character, otherwise return an error. |  |
| 103F | `hdr_pad_loop` | Another ZPAD: keep waiting for ZDLE. |  |
| 10C5 | `get_bin32_header` | Receive a binary header with 32-bit CRC. | `zm.c zrbhdr32` |
| 1100 | `get_bin16_header` | Receive a binary header with 16-bit CRC. | `zm.c zrbhdr` |
| 113F | `get_hex_header` | Receive a hex-encoded header. | `zm.c zrhhdr` |
| 1194 | `get_hex_byte` | Receive two hex digits and combine them into a byte. | `zm.c zgethex` |
| 11B3 | `hex_digit_value` | Convert an ASCII hex digit in A to 0-15. |  |

**XModem and YModem reception**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 11C1 | `xmodem_rx_start` | Send the initial NAK or C to start XMODEM/YMODEM reception and read the first block. | `rz.c wcrxpn` |
| 11FA | `xmodem_rx_file` | Receive all blocks of an XMODEM/YMODEM file. | `rz.c wcrx` |
| 1289 | `xmodem_get_block` | Read one XMODEM block (SOH/STX/EOT/CAN) with its checksum or CRC. | `rz.c wcgetsec` |
| 12BA | `xm_got_stx` | 1024-byte block start. |  |
| 12BF | `xm_got_soh` | 128-byte block start. |  |
| 135F | `xm_got_eot` | EOT received. |  |
| 136A | `xm_got_can` | CAN received. |  |
| 137A | `xm_bad_block` | bad block, discard input and NAK. |  |

**Frame transmission**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 13BA | `send_hex_header` | Send a hex header: frame type in A, four argument bytes from the header buffer, CRC-16, CR LF. | `zm.c zshhdr` |
| 1418 | `put_hex_byte` | Send A as two lowercase hex digits. | `zm.c zputhex` |
| 1438 | `put_zdle_char` | Send A, escaping it with ZDLE if it is a control character. | `zm.c zsendline` |
| 1450 | `zdl_escape` | Send ZDLE followed by the character XOR 40H, then fall through to send it. |  |
| 145C | `aux_putc_wait` | Send A to the modem, waiting until the output is ready. |  |
| 146C | `zdl_cr_rule` | CR is escaped only if the previous character sent was "@". |  |

**File specification parsing and utilities**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 1492 | `parse_filespec` | Parse a [DU:\|DIR:]filename into an FCB (Z3PLUS named directories supported). |  |
| 14A7 | `parse_fcb` | Core of the filespec parser. |  |
| 1522 | `parse_fcb_field` | Copy up to B name characters, expanding "*" to "?"s. |  |
| 1543 | `inc_wild_count` | Count one wildcard character. |  |
| 154A | `parse_du` | Try to interpret a prefix as drive/user (DU:). |  |
| 1552 | `parse_du_inner` | Decode "dU" / "d" / "U" form checking against the environment limits. |  |
| 159D | `parse_named_dir` | Try to interpret a prefix as a named directory (DIR:). |  |
| 15A5 | `named_dir_lookup` | Look up an 8-character name in the Z3 named directory register. |  |
| 15D9 | `is_delimiter` | Z if A ends a file name token. |  |
| 15FA | `parse_decimal` | Parse a decimal user number. |  |
| 1625 | `digit_value` | A = A-'0'; carry if not a digit. |  |
| 162C | `clear_dirspec` | Clear the drive/user part of the FCB. |  |
| 1632 | `clear_fcb_tail` | Clear the rest of the FCB. |  |
| 1645 | `fill_clear` | Fill B bytes at DE with A. |  |
| 164A | `z3env_duok` | Read the DU:-form-allowed flag (DUOK, offset 2EH) of the ZCPR3 environment descriptor; Z if there is none or DU: is not allowed. |  |
| 1652 | `z3env_max_drive` | Read the highest valid drive (offset 2CH) from the ZCPR3 environment descriptor. |  |
| 165A | `z3env_max_user` | Read the highest valid user number (offset 2DH) from the ZCPR3 environment descriptor. |  |
| 1662 | `z3env_ndr_ptr` | Get the named directory register address (offset 15H) from the ZCPR3 environment descriptor; its entry count is at 17H. |  |
| 1683 | `set_z3env` | Store HL as the ZCPR3 environment pointer. |  |
| 1687 | `get_drive_user` | Return current drive in B and user in C. |  |
| 169E | `file_exists` | BDOS search-first on the FCB at DE; Z if not found. |  |
| 16A5 | `console_read` | Read a console character (BDOS C_READ). |  |
| 16AA | `console_status` | Console input status (BDOS C_STAT). |  |
| 16AF | `bdos_save_regs` | BDOS call preserving BC and DE. |  |
| 16B8 | `bdos_call_a` | BDOS call with function number in A, preserving BC, DE, HL. |  |
| 16C4 | `fcb_to_name` | Format the FCB name at DE as NAME.EXT at HL. |  |
| 16DA | `copy_name_part` | Copy B characters of a name, dropping blanks. |  |
| 16E7 | `a_to_decimal` | Convert A to up to three decimal digits at DE. |  |
| 1703 | `decimal_digit` | Extract one decimal digit. |  |
| 1717 | `decimal_emit` | Store one decimal digit. |  |
| 171E | `upcase_string` | Convert the zero-terminated string at HL to upper case. |  |
| 172E | `tokenize_args` | Split the command tail into blank-separated tokens, building a pointer table. |  |
| 176B | `skip_blanks` | Skip spaces and tabs at DE. |  |
| 1779 | `skip_token` | Skip a token at DE. |  |
| 1786 | `memset` | Fill B bytes at HL with A (preserves HL). |  |
| 178C | `memset_inner` | Fill B bytes at HL with A. |  |
| 1793 | `to_upper` | Convert A to upper case. |  |

### A.2 SZ

**Start-up, options and console output**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0100 | `start` | Program entry: check for CP/M 3, show banner, parse command line, run the transfer, restore the default drive/user and exit. |  |
| 010B | `main` | Program entry (after the ZCPR3 header): check for CP/M 3, show banner, parse command line and file list, run the transfer, restore drive/user and exit. |  |
| 01F1 | `get_default_du` | Save the current user number and drive (from IOBYTE/0004H) so they can be restored at exit. |  |
| 020C | `set_du` | Select user number and drive from a (user,drive+1) pair addressed by DE (BDOS F_USERNUM, DRV_SET). |  |
| 021E | `err_need_cpm3` | Print "sorry, CP/M 3 Tool" and exit. |  |
| 0226 | `usage_exit` | Print the usage/help text and exit to CP/M. |  |
| 03B3 | `parse_options` | Scan a "-xyz" option string; each letter is looked up in the option key table and its handler is run. |  |
| 03E2 | `opt_xmodem` | Option X: select XMODEM. |  |
| 03E6 | `opt_ymodem` | Option Y: select YMODEM. |  |
| 03EA | `opt_zmodem` | Option Z: select ZMODEM. |  |
| 03EC | `set_protocol` | Store protocol number in A (1=XMODEM, 3=YMODEM, 4=ZMODEM). |  |
| 03F0 | `opt_protect` | Option P: protect existing files (do not overwrite). |  |
| 03F6 | `opt_append` | Option A: ask the receiver to append (ZF1 = ZMAPND). |  |
| 03FC | `opt_binary` | Option B: binary transfer. |  |
| 0402 | `opt_convert` | Option C: convert to local linefeed convention. |  |
| 0408 | `scb_setup` | Detach the modem port from the console: read AOVEC (SCB 28H) via BDOS 49 and clear its devices from COVEC (24H) and CIVEC (22H), keeping the originals. |  |
| 046A | `scb_restore` | Put the original console input/output redirection vectors (CIVEC, COVEC) back into the System Control Block. |  |
| 048A | `print_err_count` | Print the current error count / retry message on the console. |  |
| 04AC | `print_filename` | Print the current file name (DU:NAME.EXT) and its size. |  |
| 0508 | `print_position` | Print the current file position as a decimal number on the console. |  |
| 0526 | `print_cant_open` | Print "can't open any file". |  |
| 052B | `print_skipped` | Print "File skipped". |  |
| 0558 | `set_pending_char` | Queue A (count in C) as pending input characters; used to inject CANs when ESC is pressed. |  |

**AUX I/O, ring buffer and file buffer helpers**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0561 | `aux_poll_input` | Poll the AUX device (BDOS A_STATIN/A_READ) and move any waiting characters into the receive ring buffer. |  |
| 058D | `aux_get_char` | Fetch next input character: pending queued char first, otherwise from the ring buffer. |  |
| 05A0 | `aux_putc` | Write the character in A to the AUX (modem) device. |  |
| 05A6 | `aux_out_ready` | Test whether the AUX output is ready (BDOS A_STATOUT). |  |
| 05AD | `aux_wait_input` | Wait roughly 100 ms-steps for an input character; returns it in A with NZ, Z on timeout. |  |
| 05C4 | `delay_short` | Short software delay loop. |  |
| 05D0 | `ring_get` | Remove one byte from the receive ring buffer. |  |
| 05F5 | `ring_put` | Insert byte C into the receive ring buffer. |  |
| 061C | `clear_fcb` | Zero the 37-byte FCB at HL. |  |
| 0623 | `ring_reset` | Clear the 6-byte ring buffer control block at HL. |  |
| 0625 | `memset_a` | Fill using A and B. |  |

**Dispatch, 32-bit arithmetic, CRC and number output**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0629 | `dispatch` | Table dispatcher: after CPIR over N keys, jump to the matching vector stored (in reverse order) after the key list. |  |
| 0632 | `zero32` | Set the 32-bit value at (HL) to 0. |  |
| 063C | `copy32` | Copy 32-bit value (HL) to (DE). |  |
| 064B | `cmp32_signed` | Signed compare of 32-bit values (HL) and (DE); sets carry/zero. |  |
| 066C | `cmp32_unsigned` | Unsigned compare of 32-bit values (HL) and (DE). |  |
| 067D | `eq32` | Compare 32-bit values (HL) and (DE) for equality (Z if equal). |  |
| 068E | `add32` | (BC) = (DE) + (HL), 32-bit. |  |
| 06A4 | `sub32` | (BC) = (HL) - (DE), 32-bit. |  |
| 06BC | `inc32` | Increment the 32-bit value at (HL). |  |
| 06D0 | `set32_minus1` | Set the 32-bit value at (HL) to -1 (0FFFFFFFFH). |  |
| 06D3 | `dec32` | Decrement the 32-bit value at (HL). |  |
| 06E5 | `and32` | (BC) = (DE) AND (HL), 32-bit. |  |
| 071E | `ltoa32` | Convert the 32-bit value at (HL) to decimal ASCII at (DE) (zero terminated). |  |
| 0787 | `checksum_add` | Add A to the running 8-bit XMODEM checksum. |  |
| 0797 | `crc32_update` | Update the running CRC-32 with byte A. |  |
| 07CF | `crc32_table_init` | Build the 256-entry CRC-32 lookup table. |  |
| 082F | `crc16_update` | Update the running CRC-16 (CCITT, polynomial 1021H) with byte A. | `updcrc` |

**Send control, file information, XModem and YModem sending**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0854 | `send_main` | Top-level send: set up buffers and CRC table, then send all files. | `sz.c wcsend` |
| 088A | `calc_buffer_mask` | Round the available buffer size down to a power of two and derive the wrap-around mask. |  |
| 08A5 | `fetch_file_entry` | Fetch the next file name from the list into the working FCB. |  |
| 08C1 | `send_files` | Loop over all files in the list and send them, then finish the session. | `sz.c wcsend` |
| 0922 | `send_one_file` | Open one file, print its name and send it with the selected protocol. | `sz.c wcs` |
| 0972 | `build_file_info` | Build the ZFILE/block-0 information (name, size) for the current file. | `sz.c wctxpn` |
| 09D9 | `wait_rx_start` | Wait for the receiver's start character (C, NAK) or ZRINIT. | `sz.c getnak` |
| 0A1B | `got_c_crc_mode` | 'C': the receiver asks for CRC-16. |  |
| 0A20 | `got_nak` | the receiver wants a checksum. |  |
| 0A26 | `got_zpad_zmodem` | Receiver started ZMODEM: switch to ZMODEM sending. |  |
| 0A4C | `xmodem_wait_rx` | XMODEM/YMODEM sender session: wait for the receiver's NAK / "C" / "G" (sz.c wctx), then send the file in 128- or 1024-byte blocks and finish with EOT. | `sz.c wctx` |
| 0A76 | `xw_got_can` | CAN while waiting for the receiver: abort. |  |
| 0A7A | `xw_got_c` | 'C': the receiver wants CRC-16 blocks. |  |
| 0A7F | `xw_got_nak` | the receiver wants checksum blocks. |  |
| 0A83 | `xmodem_snd_blks` | Send the file as a series of 128/1024-byte blocks. | `sz.c wctx` |
| 0AC9 | `xmodem_send_eot` | Send EOT and wait for ACK. | `sz.c wctx` |
| 0ADD | `xw_timeout` | No answer within 25.5 s: abort. |  |
| 0AE4 | `xmodem_snd_block` | Send one block: SOH/STX, block number and complement, data, checksum or CRC, then wait for the reply. | `sz.c wcputsec` |
| 0B60 | `xs_wait_ack` | XMODEM send: wait for ACK/NAK reply. |  |
| 0B71 | `xs_got_can` | CAN received (two in a row cancel). |  |
| 0B7D | `xs_timeout` | No reply within 10 s: resend the block. |  |
| 0B80 | `xs_got_c` | 'C' received: the receiver wants CRC-16 instead of a checksum. |  |
| 0B8C | `xs_got_nak` | the block was damaged; resend it. |  |
| 0B8F | `xs_got_ack` | block accepted. |  |
| 0B99 | `xs_got_garbage` | Garbage instead of ACK/NAK: count it and resend. |  |
| 0BD3 | `xs_chk_can` | CAN received after garbage: abort if the previous character was also CAN. |  |
| 0BDD | `xs_retry` | XMODEM send: count error and resend. |  |

**ZModem sending and file repositioning**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 0BF0 | `zmodem_send_init` | Send ZRQINIT and wait for the receiver's ZRINIT. | `sz.c getzrxinit` |
| 0C2F | `zmodem_got_zri` | Process the ZRINIT flags from the receiver (CRC-32, escape-control, buffer size). | `sz.c getzrxinit` |
| 0C66 | `zi_abort` | ZCAN or timeout while waiting for ZRINIT: give up. |  |
| 0C6A | `zi_got_zrqinit` | ZRQINIT received instead of ZRINIT: ignore it if it echoes our own, otherwise answer ZNAK. |  |
| 0C8B | `zmodem_snd_zfile` | Send the ZFILE header and its data subpacket, then wait for ZRPOS/ZSKIP. | `sz.c zsendfile` |
| 0CE9 | `zf_wait_zpad` | ZRINIT again: wait up to 5 s for ZPAD; if none arrives send the ZFILE again. |  |
| 0CF6 | `zf_abort` | Abort the ZModem transfer. |  |
| 0CFA | `zf_ignore` | Ignore this frame and read the next header. |  |
| 0CFD | `zf_skip` | the receiver does not want the file. |  |
| 0D00 | `zf_got_zrpos` | reposition the file and start streaming data. |  |
| 0D47 | `zmodem_send_data` | Start sending file data from the position requested. | `sz.c zsendfdata` |
| 0D65 | `zd_abort` | ZCAN, timeout or error: abort. |  |
| 0D69 | `zd_got_zskip` | the receiver does not want this file. |  |
| 0D6C | `zd_ok` | ZRINIT received: the file was accepted. |  |
| 0D7D | `zd_got_zack` | ZACK received: acknowledged; carry on streaming. |  |
| 0D81 | `zd_got_zrpos` | ZRPOS received while streaming. |  |
| 0D98 | `zd_got_pad` | ZPAD or ZDLE seen: a header is coming; read it. |  |
| 0DA0 | `zd_got_xoff` | XOFF seen: the line is paused; wait for it to be released. |  |
| 0DB6 | `zmodem_stream` | Send ZDATA then stream data subpackets, checking for ZRPOS/ZACK from the receiver. | `sz.c zsendfdata` |
| 0E9B | `zmodem_send_zeof` | Send ZEOF and wait for the receiver's ZRINIT. | `sz.c zsendfdata (ZEOF)` |
| 0EBD | `zeof_retry` | ZACK after ZEOF: send ZEOF again. |  |
| 0EBF | `zeof_resend` | ZRPOS after ZEOF: the receiver is missing data; send from its offset again. |  |
| 0EC2 | `zeof_ok` | Receiver acknowledged ZEOF. |  |
| 0EC4 | `zeof_skip` | ZSKIP after ZEOF. |  |
| 0ED1 | `zmodem_get_resp` | Wait for a header from the receiver and dispatch on its type. | `sz.c getinsync` |
| 0EE2 | `resp_send_znak` | Bad header: send ZNAK and read again. |  |
| 0EE9 | `resp_return` | return it to the caller. |  |
| 0EEA | `resp_zack_pass` | file finished; close it and return. |  |
| 0EF0 | `resp_zack_check` | remember its position and accept it if it matches what was sent. |  |
| 0F0F | `zmodem_do_zrpos` | Handle ZRPOS: reposition the file and restart streaming. | `sz.c getinsync (ZRPOS)` |
| 0F70 | `resp_abort` | Abort (ZCAN, ZABORT, ZFIN or timeout). |  |
| 0F8F | `reposition_file` | Seek the file buffer to the requested position (re-reading if necessary). | `sz.c fseek(in, Rxpos)` |
| 1017 | `file_skip_fwd` | Advance the file read position to the target position by reading. |  |
| 101D | `file_rewind_skip` | Rewind the file and skip forward to the target position. |  |
| 1042 | `get_next_chunk` | Get the next chunk of file data to send; sets the end-of-file flag. | `sz.c zfilbuf` |
| 10A2 | `fill_file_buffer` | Read BC bytes from the file into the ring buffer. | `sz.c zfilbuf` |
| 10C5 | `ring_buffer_addr` | Compute the address of the ring-buffer byte at offset DE from the buffer start. |  |
| 10DD | `send_zfin_oo` | Send ZFIN, wait for the receiver's ZFIN and answer with "OO". | `sz.c saybibi` |

**Frame transmission**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 10FD | `send_subpacket` | Send BC data bytes followed by ZDLE and the terminator in A, with CRC-16 or CRC-32. | `zm.c zsbdata` |
| 118C | `send_bin_header` | Send a binary header (ZBIN or ZBIN32) with frame type A and the header buffer contents. | `zm.c zsbhdr` |
| 1204 | `send_hex_header` | Send a hex header: frame type in A, four argument bytes from the header buffer, CRC-16, CR LF. | `zm.c zshhdr` |
| 1262 | `put_hex_byte` | Send A as two lowercase hex digits. | `zm.c zputhex` |
| 1282 | `put_zdle_char` | Send A, escaping it with ZDLE if it is a control character. | `zm.c zsendline` |
| 129A | `zdl_escape` | Send ZDLE followed by the character XOR 40H, then fall through to send it. |  |
| 12A6 | `aux_putc_wait` | Send A to the modem, waiting until the output is ready. |  |
| 12B6 | `zdl_cr_rule` | CR is escaped only if the previous character sent was "@". |  |

**Frame and character reception**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 12DC | `crc_init` | Reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH. |  |
| 12EB | `get_header` | Receive a ZMODEM header (hex, binary16 or binary32); returns frame type in A, carry on error. | `zm.c zgethdr` |
| 132C | `hdr_zdle_zdle` | A second ZDLE: count a CAN; five in a row return ZCAN. |  |
| 1337 | `hdr_zdle_zcrcw` | ZDLE then ZCRCW: wait briefly for one more character, otherwise return an error. |  |
| 1359 | `hdr_pad_loop` | Another ZPAD: keep waiting for ZDLE. |  |
| 13DF | `get_bin32_header` | Receive a binary header with 32-bit CRC. | `zm.c zrbhdr32` |
| 141A | `get_bin16_header` | Receive a binary header with 16-bit CRC. | `zm.c zrbhdr` |
| 1454 | `get_hex_header` | Receive a hex-encoded header. | `zm.c zrhhdr` |
| 14A4 | `get_hex_byte` | Receive two hex digits and combine them into a byte. | `zm.c zgethex` |
| 14C3 | `hex_digit_value` | Convert an ASCII hex digit in A to 0-15. |  |
| 14D1 | `getc_7bit_filt` | Get a modem char, strip bit 7 and ignore XON/XOFF/CR/LF/ZDLE. | `zm.c noxrd7` |
| 14FB | `getc_zdl_filt` | Get a modem char, ignore XON/XOFF and decode ZDLE escapes. | `zm.c zdlread` |
| 151C | `zdlread_escape` | Decode the byte following a ZDLE (CAN) escape: frame-end codes, ZRUB0/ZRUB1, or XOR 40H. | `zm.c zdlread` |
| 15A8 | `send_can_string` | Send eight+ CAN characters followed by backspaces to abort the peer. | `canit` |
| 15AB | `send_string` | Send the zero-terminated string at HL to the modem. | `rz.c zmputs` |
| 15B6 | `aux_getc_timeout` | Get a character from the modem with timeout (B = tenths of a second). | `readline` |

**File specification parsing and utilities**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 15D4 | `parse_filespec` | Parse a [DU:\|DIR:]filename into an FCB (Z3PLUS named directories supported). |  |
| 15E9 | `parse_fcb` | Core of the filespec parser. |  |
| 1664 | `parse_fcb_field` | Copy up to B name characters, expanding "*" to "?"s. |  |
| 1685 | `inc_wild_count` | Count one wildcard character. |  |
| 168C | `parse_du` | Try to interpret a prefix as drive/user (DU:). |  |
| 1694 | `parse_du_inner` | Decode "dU" / "d" / "U" form checking against the environment limits. |  |
| 16DF | `parse_named_dir` | Try to interpret a prefix as a named directory (DIR:). |  |
| 16E7 | `named_dir_lookup` | Look up an 8-character name in the Z3 named directory register. |  |
| 171B | `is_delimiter` | Z if A ends a file name token. |  |
| 173C | `parse_decimal` | Parse a decimal user number. |  |
| 1767 | `digit_value` | A = A-'0'; carry if not a digit. |  |
| 176E | `clear_dirspec` | Clear the drive/user part of the FCB. |  |
| 1774 | `clear_fcb_tail` | Clear the rest of the FCB. |  |
| 1787 | `fill_clear` | Fill B bytes at DE with A. |  |
| 178C | `z3env_duok` | Read the DU:-form-allowed flag (DUOK, offset 2EH) of the ZCPR3 environment descriptor; Z if there is none or DU: is not allowed. |  |
| 1794 | `z3env_max_drive` | Read the highest valid drive (offset 2CH) from the ZCPR3 environment descriptor. |  |
| 179C | `z3env_max_user` | Read the highest valid user number (offset 2DH) from the ZCPR3 environment descriptor. |  |
| 17A4 | `z3env_ndr_ptr` | Get the named directory register address (offset 15H) from the ZCPR3 environment descriptor; its entry count is at 17H. |  |
| 17C5 | `set_z3env` | Store HL as the ZCPR3 environment pointer. |  |

**Directory scan and sort**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 17C9 | `build_file_list` | Expand the command-line file specification into a table of matching directory entries (16 bytes each: user, name, extension, extent data), sorted by name; C = count. |  |
| 17D6 | `build_flist_alt` | Same as build_file_list, but a file listed in several extents keeps its HIGHEST extent (dir_dup_mode = 0). |  |
| 17F2 | `sort_file_list` | Sort the BC directory entries at HL: build a pointer index, Shell-sort the pointers with dir_compare, then rearrange the entries in place. |  |
| 181A | `dir_compare` | Sort callback: compare the directory entries at HL and DE (name, extension and extent; extension first when sort_key_flag is nonzero; the user number breaks ties). |  |
| 185C | `dir_collect_ff` | Scan the directory with BDOS Search First/Next and insert every file entry into the table. |  |
| 185D | `dir_collect_00` | Collect matching directory entries (flag 0). |  |
| 18A8 | `dir_add_entry` | Take directory entry number A (0-3) of the sector BDOS returned in the 0080H buffer. |  |
| 18EB | `dir_find_dup` | Look for the same user + file name (12 bytes) in the table. |  |
| 1938 | `dir_compact` | Squeeze the table: entries marked with bit 7 (they matched the file specification) are moved to the front and unmarked; BC = number kept. |  |
| 1979 | `dir_table_init` | Prepare the directory table at HL: read the disk parameter block for the maximum number of directory entries, fill in the sort control block (item size 16) and reserve the pointer index; the 16-byte entries follow the index. |  |
| 19A1 | `get_disk_params` | Read the disk parameter block (BDOS 31) and keep BSH, BLM, EXM, the number of allocation blocks (DSM+1) and the number of directory entries (DRM+1). |  |
| 19CB | `dir_mark_matches` | Compare every table entry with the file specification (name and extension, "?" matches any character) and the selection mask; matching entries get bit 7 of the user byte set. |  |
| 1A0B | `dir_check_attr` | Does the entry pass the selection mask? |  |
| 1A30 | `sort_alloc_index` | Build an index of N pointers, one per item, so the items can be sorted indirectly; the items start right after the index. |  |
| 1A81 | `sort_entries` | Shell-sort the pointer index (sort_shell), then rearrange the real items in place by following the permutation cycles. |  |
| 1AF9 | `sort_swap` | Swap items HL and DE: exchange the two index pointers when the sort is indirect, otherwise the whole items. |  |
| 1B08 | `sort_copy_ents` | Swap the contents of two complete items (item-size bytes each) at addresses HL and DE. |  |
| 1B25 | `sort_elem_adr_de` | HL and DE become the addresses of items HL and DE. |  |
| 1B29 | `sort_elem_addr` | HL = address of item number HL: base + (HL - 1) * item size. |  |
| 1B55 | `sort_compare` | Call the caller's compare routine with HL and DE = the two items (found through the index when sorting indirectly); its flags are returned. |  |
| 1B7C | `sort_index_addr` | HL = address of index entry HL: sort_index_ptr + (HL - 1) * 2. |  |
| 1B84 | `sort_params_save` | Copy the caller's 12-byte sort control block (base, count, item size, compare routine, flags) into the working copy. |  |
| 1B91 | `sort_prm_restore` | Copy the working sort control block back to the caller. |  |
| 1B9A | `sort_shell` | Shell sort of the index. |  |

**Buffered file layer and BDOS wrappers**

| Address | Routine | Purpose | Counterpart |
|---|---|---|---|
| 1BDB | `file_open_input` | Open the file named at DE for reading. |  |
| 1BF9 | `file_getc` | Read the next byte from the input file (A, Z/NZ status). |  |
| 1C09 | `file_close_input` | Close the input file. |  |
| 1C23 | `sel_in_handle` | Select the input file control block. |  |
| 1C2C | `sel_out_handle` | Select the output file control block. |  |
| 1C37 | `file_oprd_impl` | Open the file of the file object at HL for reading: an already open object is closed first, the first 128-byte sector is read. |  |
| 1C75 | `file_opwr_impl` | Create (BDOS F_MAKE) the file of the file object at HL for writing and give it an empty buffer. |  |
| 1C98 | `file_getc_impl` | Return the next byte of an input file object (byte in A and in file_io_char, Z). |  |
| 1CDB | `file_putc_a` | Put byte A to the output file. |  |
| 1CDF | `file_putc_impl` | Append byte A to an output file object; a full 128-byte buffer is written to disk. |  |
| 1D16 | `file_clsrd_impl` | Close the input file object and mark it unused (error 6 = close failed). |  |
| 1D21 | `file_clswr_impl` | Finish an output file object: pad the last sector with ^Z (1AH) and zeros, write it, close the file and mark the object unused. |  |
| 1D56 | `file_read_sector` | Read the next 128-byte record of the current file object into its buffer (BDOS F_READ); Z = success. |  |
| 1D6D | `file_wr_sector` | Write the buffer out as a sector. |  |
| 1D8C | `get_drive_user` | Return current drive in B and user in C. |  |
| 1DA3 | `get_file_size` | Get the file size (BDOS F_SIZE). |  |
| 1DA7 | `get_rand_record` | Get the random record number (BDOS F_RANDREC). |  |
| 1DC9 | `fcb_open_or_make` | Open the file, or create it if it does not exist. |  |
| 1DD2 | `fcb_close` | Close the file (BDOS F_CLOSE). |  |
| 1DD7 | `fcb_open` | Open the file (BDOS F_OPEN). |  |
| 1DD9 | `fcb_bdos_check` | BDOS call with FCB; Z on success. |  |
| 1DDF | `fcb_read_sector` | Read a sector (BDOS F_READ). |  |
| 1DE4 | `fcb_write_sector` | Write a sector (BDOS F_WRITE). |  |
| 1DE9 | `set_dma` | Set the DMA address to DE (BDOS F_DMAOFF). |  |
| 1DF3 | `fcb_clear_tail` | Clear the extent/record part of the FCB. |  |
| 1E07 | `console_read` | Read a console character (BDOS C_READ). |  |
| 1E0C | `console_status` | Console input status (BDOS C_STAT). |  |
| 1E11 | `bdos_save_regs` | BDOS call preserving BC and DE. |  |
| 1E1A | `bdos_call_a` | BDOS call with function number in A, preserving BC, DE, HL. |  |
| 1E26 | `fcb_to_name` | Format the FCB name at DE as NAME.EXT at HL. |  |
| 1E3C | `copy_name_part` | Copy B characters of a name, dropping blanks. |  |
| 1E49 | `a_to_decimal` | Convert A to up to three decimal digits at DE. |  |
| 1E65 | `decimal_digit` | Extract one decimal digit. |  |
| 1E79 | `decimal_emit` | Store one decimal digit. |  |
| 1E80 | `upcase_string` | Convert the zero-terminated string at HL to upper case. |  |
| 1E91 | `skip_blanks_str` | Skip blank characters in the string at HL. |  |
| 1E9E | `skip_to_blank` | Advance HL to the next blank. |  |
| 1EAB | `tokenize_args` | Split the command tail into blank-separated tokens, building a pointer table. |  |
| 1EE8 | `skip_blanks` | Skip spaces and tabs at DE. |  |
| 1EF6 | `skip_token` | Skip a token at DE. |  |
| 1F03 | `memset` | Fill B bytes at HL with A (preserves HL). |  |
| 1F09 | `memset_inner` | Fill B bytes at HL with A. |  |
| 1F10 | `is_alpha` | Z if A is an upper-case letter (after case conversion). |  |
| 1F24 | `is_space` | Z if A is a blank/control separator. |  |
| 1F3F | `to_upper` | Convert A to upper case. |  |
| 1F4A | `get_tpa_top` | Compute the top of the TPA. |  |
| 1F58 | `compare_wild` | Compare B bytes at HL and DE, "?" matches anything. |  |
| 1F6A | `compare_mem` | Compare B bytes at HL and DE (7-bit). |  |


## Appendix B: Dispatch tables

Each table lists the key, its meaning and the routine (or entry point) that handles it.  Tables with no handler column are key lists used for membership tests.  Keys are shown with the protocol names used in the listings.

### B.1 RZ

**03B1: Option letters**

| Key | Meaning | Handler |
|---|---|---|
| 3FH | '?' | `usage_exit` |
| 50H | 'P' | `opt_protect` |
| 42H | 'B' | `opt_binary` |
| 43H | 'C' | `opt_convert` |
| 58H | 'X' | `opt_xmodem` |
| 59H | 'Y' | `opt_ymodem` |
| 5AH | 'Z' | `opt_zmodem` |
| 52H | 'R' | `opt_resume` |

**0B96: ZRINIT handshake: frame type of the reply**

| Key | Meaning | Handler |
|---|---|---|
| 00H | ZRQINIT | `zri_resend` |
| 0BH | ZEOF | `zri_resend` |
| FEH | timeout | `zri_count_err` |
| 04H | ZFILE | `zri_got_zfile` |
| 02H | ZSINIT | `zri_got_zsinit` |
| 11H | ZFREECNT | `zri_got_zfreecnt` |
| 12H | ZCOMMAND | `zri_abort` |
| 0FH | ZCOMPL | `zri_read_hdr` |
| 08H | ZFIN | `zri_got_zfin` |
| 10H | ZCAN | `zri_abort` |

**0CE4: ZModem file receive: frame type of the header**

| Key | Meaning | Handler |
|---|---|---|
| 06H | ZNAK | `rx_header_error` |
| FEH | timeout | `rx_header_error` |
| 04H | ZFILE | `rx_got_zfile_2` |
| 0BH | ZEOF | `rx_got_zeof` |
| FFH | error | `rx_data_error` |
| 0AH | ZDATA | `rx_got_zdata` |
| FCH | junk limit | `rx_header_error` |

**0CF9: ZModem file receive: result of a data subpacket**

| Key | Meaning | Handler |
|---|---|---|
| EBH | GOTCRCW | `rx_got_crcw` |
| EAH | GOTCRCQ | `rx_got_crcq` |
| E9H | GOTCRCG | `rx_got_crcg` |
| E8H | GOTCRCE | `rx_got_crce` |
| FFH | error | `rx_data_error` |
| FEH | timeout | `rx_header_error` |
| 10H | ZCAN | `rx_got_cancel` |

**0E2A: Read filter: ignored characters**

| Key | Meaning |
|---|---|
| 11H |  |
| 13H |  |

**0EA2: ZDLE filter: characters ignored**

| Key | Meaning |
|---|---|
| 11H |  |
| 91H |  |
| 13H |  |
| 93H |  |

**0EA6: ZDLE escape: character after ZDLE**

| Key | Meaning | Handler |
|---|---|---|
| 11H |  | `zdlread_escape` |
| 91H |  | `zdlread_escape` |
| 13H |  | `zdlread_escape` |
| 93H |  | `zdlread_escape` |
| 18H | ZDLE | `zdl_crc_end` |
| 68H | ZCRCE | `zdl_crc_end` |
| 69H | ZCRCG | `zdl_crc_end` |
| 6AH | ZCRCQ | `zdl_crc_end` |
| 6BH | ZCRCW | `zdl_crc_end` |
| 6CH | ZRUB0 | `zdl_rub0` |
| 6DH | ZRUB1 | `zdl_rub1` |

**0F0E: Data subpacket end, CRC-16**

| Key | Meaning | Handler |
|---|---|---|
| E8H | GOTCRCE | `rx_end_crc16` |
| E9H | GOTCRCG | `rx_end_crc16` |
| EAH | GOTCRCQ | `rx_end_crc16` |
| EBH | GOTCRCW | `rx_end_crc16` |
| 98H | GOTCAN | `rx_cancel` |
| FFH | error | `rx_err_return` |
| FEH | timeout | `rx_timeout` |

**0F23: Data subpacket end, CRC-32**

| Key | Meaning | Handler |
|---|---|---|
| E8H | GOTCRCE | `rx_end_crc32` |
| E9H | GOTCRCG | `rx_end_crc32` |
| EAH | GOTCRCQ | `rx_end_crc32` |
| EBH | GOTCRCW | `rx_end_crc32` |
| 98H | GOTCAN | `rx_cancel` |
| FFH | error | `rx_err_return` |
| FEH | timeout | `rx_timeout` |

**109E: Header scan: idle state**

| Key | Meaning | Handler |
|---|---|---|
| 18H | ZDLE | `hdr_got_zdle` |
| AAH | ZPAD (bit 7 set) | `hdr_got_zpad` |
| 2AH | ZPAD | `hdr_got_zpad` |

**10A7: Header scan: after ZDLE**

| Key | Meaning | Handler |
|---|---|---|
| 6BH | ZCRCW after CAN: no header follows | `hdr_zdle_zcrcw` |
| 18H | ZDLE | `hdr_zdle_zdle` |

**10AD: Header scan: after ZPAD**

| Key | Meaning | Handler |
|---|---|---|
| 2AH | ZPAD | `hdr_pad_loop` |
| 18H | ZDLE | `hdr_zpad_zdle` |

**10B3: Header scan: after ZPAD ZDLE (format character)**

| Key | Meaning | Handler |
|---|---|---|
| 43H | ZBIN32 (binary header, CRC-32) | `hdr_bin32` |
| 41H | ZBIN (binary header, CRC-16) | `hdr_bin16` |
| 42H | ZHEX (hex header) | `hdr_hex` |
| 18H | ZDLE | `hdr_got_zdle` |

**10BF: Header result codes that return with carry set**

| Key | Meaning |
|---|---|
| 98H | GOTCAN |
| 06H | ZNAK |
| 10H | ZCAN |
| FFH | error |
| FEH | timeout |
| FCH | junk limit |

**12AE: XModem block start character**

| Key | Meaning | Handler |
|---|---|---|
| 02H | STX (1024-byte block) | `xm_got_stx` |
| 01H | SOH (128-byte block) | `xm_got_soh` |
| 04H | EOT | `xm_got_eot` |
| 18H | CAN | `xm_got_can` |

**1477: ZDLE escape set (sender)**

| Key | Meaning | Handler |
|---|---|---|
| 18H | ZDLE | `zdl_escape` |
| 0DH | CR (escaped only after "@") | `zdl_cr_rule` |
| 8DH | CR with bit 7 (escaped only after "@") | `zdl_cr_rule` |
| 10H | DLE | `zdl_escape` |
| 90H | DLE with bit 7 | `zdl_escape` |
| 11H | XON | `zdl_escape` |
| 91H | XON with bit 7 | `zdl_escape` |
| 13H | XOFF | `zdl_escape` |
| 93H | XOFF with bit 7 | `zdl_escape` |

### B.2 SZ

**03CA: Option letters**

| Key | Meaning | Handler |
|---|---|---|
| 3FH | '?' | `usage_exit` |
| 50H | 'P' | `opt_protect` |
| 41H | 'A' | `opt_append` |
| 42H | 'B' | `opt_binary` |
| 43H | 'C' | `opt_convert` |
| 58H | 'X' | `opt_xmodem` |
| 59H | 'Y' | `opt_ymodem` |
| 5AH | 'Z' | `opt_zmodem` |

**0A31: wait_rx_start: first character from the receiver**

| Key | Meaning | Handler |
|---|---|---|
| 2AH | ZPAD: receiver speaks ZMODEM | `got_zpad_zmodem` |
| FEH | TIMEOUT | `got_timeout` |
| 43H | 'C' (CRC requested) | `got_c_crc_mode` |
| 15H | NAK | `got_nak` |
| 18H | CAN | `wait_can_confirm` |

**0A40: xmodem_wait_rx: start character from the receiver**

| Key | Meaning |
|---|---|
| 15H | NAK |
| 43H | 'C' (CRC requested) |
| FEH | TIMEOUT |
| 18H | CAN |

**0A40: xmodem_wait_rx: start character from the receiver**

| Key | Meaning | Handler |
|---|---|---|
| 15H | NAK | `xw_got_nak` |
| 43H | 'C' (CRC requested) | `xw_got_c` |
| FEH | TIMEOUT | `xw_timeout` |
| 18H | CAN | `xw_got_can` |

**0B9C: XModem sender: response to a block**

| Key | Meaning | Handler |
|---|---|---|
| 18H | CAN | `xs_got_can` |
| FEH | TIMEOUT | `xs_timeout` |
| 43H | 'C' (CRC requested) | `xs_got_c` |
| 15H | NAK | `xs_got_nak` |
| 06H | ACK | `xs_got_ack` |
| FFH | ERROR | `xs_got_garbage` |

**0BAE: XModem sender: response after garbage**

| Key | Meaning | Handler |
|---|---|---|
| FEH | TIMEOUT | `xs_retry` |
| 15H | NAK | `xs_wait_ack` |
| 43H | 'C' (CRC requested) | `xs_wait_ack` |
| 18H | CAN | `xs_chk_can` |

**0C79: ZModem start: frame type received**

| Key | Meaning | Handler |
|---|---|---|
| 0EH | ZCHALLENGE | `zi_got_zchall` |
| 12H | ZCOMMAND | `zi_got_zcommand` |
| 01H | ZRINIT | `zmodem_got_zri` |
| 10H | ZCAN | `zi_abort` |
| FEH | timeout | `zi_abort` |
| 00H | ZRQINIT | `zi_got_zrqinit` |

**0D2F: ZFILE: frame type of the answer**

| Key | Meaning | Handler |
|---|---|---|
| 01H | ZRINIT | `zf_wait_zpad` |
| 10H | ZCAN | `zf_abort` |
| FEH | timeout | `zf_abort` |
| 07H | ZABORT | `zf_abort` |
| 08H | ZFIN | `zf_abort` |
| 0DH | ZCRC | `zf_ignore` |
| 05H | ZSKIP | `zf_skip` |
| 09H | ZRPOS | `zf_got_zrpos` |

**0D6E: After a ZCRCW: frame type of the answer**

| Key | Meaning | Handler |
|---|---|---|
| 10H | ZCAN | `zd_abort` |
| 05H | ZSKIP | `zd_got_zskip` |
| 03H | ZACK | `zd_got_zack` |
| 09H | ZRPOS | `zd_got_zrpos` |
| 01H | ZRINIT | `zd_ok` |

**0DA7: After a ZACK: character from the receiver**

| Key | Meaning |
|---|---|
| FEH | timeout |
| 18H | ZDLE/CAN |
| 2AH | ZPAD |
| 13H | XOFF |
| 93H | XOFF (bit 7 set) |

**0DA7: After a ZACK: character from the receiver**

| Key | Meaning | Handler |
|---|---|---|
| FEH | timeout | `zd_abort` |
| 18H | ZDLE/CAN | `zd_got_pad` |
| 2AH | ZPAD | `zd_got_pad` |
| 13H | XOFF | `zd_got_xoff` |
| 93H | XOFF (bit 7 set) | `zd_got_xoff` |

**0E84: Reverse-channel sampling: character from the receiver**

| Key | Meaning | Handler |
|---|---|---|
| FEH | timeout | `zd_abort` |
| 18H | ZDLE/CAN | `zs_got_pad` |
| 2AH | ZPAD | `zs_got_pad` |
| 13H | XOFF | `zs_got_xoff` |
| 93H | XOFF (bit 7 set) | `zs_got_xoff` |

**0EC5: After ZEOF: frame type of the answer**

| Key | Meaning | Handler |
|---|---|---|
| 03H | ZACK | `zeof_retry` |
| 09H | ZRPOS | `zeof_resend` |
| 01H | ZRINIT | `zeof_ok` |
| 05H | ZSKIP | `zeof_skip` |

**0F74: zmodem_get_resp: frame type received**

| Key | Meaning | Handler |
|---|---|---|
| 10H | ZCAN | `resp_abort` |
| 07H | ZABORT | `resp_abort` |
| 08H | ZFIN | `resp_abort` |
| FEH | timeout | `resp_abort` |
| 09H | ZRPOS | `zmodem_do_zrpos` |
| 03H | ZACK | `resp_zack_check` |
| 01H | ZRINIT | `resp_zack_pass` |
| 05H | ZSKIP | `resp_return` |
| FFH | error | `resp_send_znak` |

**12C1: ZDLE escape set (sender)**

| Key | Meaning | Handler |
|---|---|---|
| 18H | ZDLE | `zdl_escape` |
| 0DH | CR (escaped only after "@") | `zdl_cr_rule` |
| 8DH | CR with bit 7 (escaped only after "@") | `zdl_cr_rule` |
| 10H | DLE | `zdl_escape` |
| 90H | DLE with bit 7 | `zdl_escape` |
| 11H | XON | `zdl_escape` |
| 91H | XON with bit 7 | `zdl_escape` |
| 13H | XOFF | `zdl_escape` |
| 93H | XOFF with bit 7 | `zdl_escape` |

**13B8: Header scan: idle state**

| Key | Meaning | Handler |
|---|---|---|
| 18H | ZDLE | `hdr_got_zdle` |
| AAH | ZPAD (bit 7 set) | `hdr_got_zpad` |
| 2AH | ZPAD | `hdr_got_zpad` |

**13C1: Header scan: after ZDLE**

| Key | Meaning | Handler |
|---|---|---|
| 6BH | ZCRCW after CAN: no header follows | `hdr_zdle_zcrcw` |
| 18H | ZDLE | `hdr_zdle_zdle` |

**13C7: Header scan: after ZPAD**

| Key | Meaning | Handler |
|---|---|---|
| 2AH | ZPAD | `hdr_pad_loop` |
| 18H | ZDLE | `hdr_zpad_zdle` |

**13CD: Header scan: after ZPAD ZDLE (format character)**

| Key | Meaning | Handler |
|---|---|---|
| 43H | ZBIN32 (binary header, CRC-32) | `hdr_bin32` |
| 41H | ZBIN (binary header, CRC-16) | `hdr_bin16` |
| 42H | ZHEX (hex header) | `hdr_hex` |
| 18H | ZDLE | `hdr_got_zdle` |

**13D9: Header result codes that return with carry set**

| Key | Meaning |
|---|---|
| 98H | GOTCAN |
| 06H | ZNAK |
| 10H | ZCAN |
| FFH | error |
| FEH | timeout |
| FCH | junk limit |

**14F6: Read filter: ignored characters**

| Key | Meaning |
|---|---|
| 11H |  |
| 13H |  |

**156E: ZDLE filter: characters ignored**

| Key | Meaning |
|---|---|
| 11H |  |
| 91H |  |
| 13H |  |
| 93H |  |

**1572: ZDLE escape: character after ZDLE**

| Key | Meaning | Handler |
|---|---|---|
| 11H |  | `zdlread_escape` |
| 91H |  | `zdlread_escape` |
| 13H |  | `zdlread_escape` |
| 93H |  | `zdlread_escape` |
| 18H | ZDLE | `zdl_crc_end` |
| 68H | ZCRCE | `zdl_crc_end` |
| 69H | ZCRCG | `zdl_crc_end` |
| 6AH | ZCRCQ | `zdl_crc_end` |
| 6BH | ZCRCW | `zdl_crc_end` |
| 6CH | ZRUB0 | `zdl_rub0` |
| 6DH | ZRUB1 | `zdl_rub1` |


## Appendix C: RAM maps

Sizes are those of the `.ds` reservations in the listings.  Addresses between entries are unused by the code.

### C.1 RZ

**Variables inside the program image**

| Address | Name | Description |
|---|---|---|
| 04F2 | `name_line_buf` | Console line buffer: CR LF, "d:" and file name |
| 051E | `pos_line_buf` | Console line buffer for the position display |
| 0544 | `spinner_chars` | Spinner characters "\|/-\" |
| 0548 | `spinner_msg` | Spinner message: blank, spinner char, two backspaces, "$" |
| 0549 | `spinner_char` | Spinner character being displayed |
| 0586 | `pending_char` | Queued input character (see set_pending_char) |
| 0587 | `pending_count` | Number of times pending_char is still to be delivered |
| 07E5 | `crc32_poly` | CRC-32 polynomial 0EDB88320H (little endian) |
| 07E9 | `crc32_residue` | CRC-32 residue 0DEBB20E3H expected after a good frame |
| 08AF | `protocol` | Selected protocol: 1 = XMODEM, 3 = YMODEM, 4 = ZMODEM (default) |
| 08B0 | `opt_protect_flag` | FFH if -p (protect existing files) was given |
| 08B1 | `opt_convert_flag` | FFH if -c (convert to local line feeds) was given |
| 08B2 | `opt_binary_flag` | FFH if -b (binary) was given |
| 08B3 | `opt_resume_flag` | FFH if -r (resume) was given |
| 08B4 | `buffer_mask` | Receive buffer size mask (power of two minus one) |
| 179E | `argv_ptr` | Pointer to the argument table built by tokenize_args |
| 17A0 | `default_user` | User number at program start |
| 17A1 | `default_drive` | Drive (1 = A:) at program start |
| 17A2 | `saved_user` | User number to select (pair with work_fcb drive byte) |
| 17A3 | `work_fcb` | FCB for the file being received (starts with the drive byte) |
| 17C4 | `work_fcb_r0` | Random record number r0-r2 of work_fcb |
| 17C7 | `work_fcb_r3` | Random record overflow byte of work_fcb |

**Work area above the image**

| Address | Size | Name | Description |
|---|---|---|---|
| 1808 | 6 | `aux_ring` | AUX receive ring buffer control block: count, head, tail (6 bytes); 4096 data bytes follow at 180EH-280DH |
| 180E | 4096 | `aux_ring_data` | Data area of the AUX receive ring (4096 bytes) |
| 280E | 1 | `file_buf_count` | Output sector buffer: number of bytes currently held (0-128) |
| 280F | 1 | `file_buf_wr` | Output sector buffer: write index |
| 2810 | 1 | `file_buf_rd` | Output sector buffer: read index |
| 2811 | 128 | `file_sector_buf` | 128-byte file sector buffer (also the DMA address for file I/O) |
| 2891 | 4 | `ltoa_value` | ltoa32: working copy of the 32-bit value being converted |
| 2895 | 4 | `ltoa_temp` | ltoa32: temporary 32-bit subtraction result |
| 2899 | 4 | `crc32_value` | Running CRC-32 accumulator (4 bytes) |
| 289D | 1024 | `crc32_table` | CRC-32 lookup table, 256 x 4 bytes (289DH-2C9CH) |
| 2C9D | 1 | `escape_ctl_flag` | Nonzero (40H) if the sender requested escaping of all control characters (TESCCTL) |
| 2C9E | 1 | `crc_mode` | Link CRC type: 10H = CRC-16, 20H = CRC-32, 0 = XMODEM checksum |
| 2C9F | 1 | `zfile_zf3` | ZFILE header bytes ZF3,ZF2,ZF1,ZF0 as received (2C9FH-2CA2H); ZF2 = transport option, unused |
| 2CA0 | 1 | `zfile_zf2` | ZFILE header byte ZF2 (transport option), not used by the code |
| 2CA1 | 1 | `zfile_zf1` | ZFILE ZF1, management option: ZMAPND 3 = append to existing file, ZMPROT 7 = protect existing file, ... |
| 2CA2 | 1 | `zfile_zf0` | ZFILE ZF0, conversion option: ZCBIN 1 = binary, ZCNL 2 = convert newlines to the local convention |
| 2CA3 | 1 | `binary_mode_flag` | FFH = store data unmodified (binary); otherwise translate CR LF |
| 2CA4 | 1 | `protect_option` | 0, or 07H (ZMPROT) when the -p option forces protection |
| 2CA5 | 1 | `file_open_flag` | FFH while an output file is open |
| 2CA6 | 1 | `header_ok_flag` | FFH once a valid header has been received |
| 2CA7 | 4 | `rx_header_data` | Four argument bytes of the most recently received header |
| 2CAB | 4 | `file_position` | Current file position, 32 bits (next byte expected) |
| 2CAF | 32 | `attn_string` | Attention string from ZSINIT (up to 32 bytes), sent to the sender on errors |
| 2CD0 | 1 | `info_argv` | Argument table built from the ZFILE data subpacket: max entries |
| 2CD1 | 1 | `info_argc` | ... number of entries found |
| 2CD2 | 2 | `info_name_ptr` | ... pointer to the file name string |
| 2CD4 | 2 | `info_size_ptr` | ... pointer to the file length/info string |
| 2CE0 | 4 | `tx_header_data` | Four argument bytes for the next header to send (position / flags) |
| 2CE4 | 4 | `rx_header_copy` | Copy of the received header arguments |
| 2CE8 | 1 | `tx_frame_type` | Frame type of the header being sent |
| 2CE9 | 2 | `rx_buffer_base` | Start address of the receive data buffer |
| 2CEB | 2 | `rx_buffer_size` | Size of the receive data buffer |
| 2CED | 2 | `rx_buffer_ptr` | Next free byte in the receive buffer |
| 2CEF | 2 | `rx_buffer_count` | Number of bytes in the receive buffer |
| 2CF3 | 2 | `rx_saved_ptr` | Saved receive buffer pointer (see rx_pos_save) |
| 2CF5 | 2 | `rx_saved_count` | Saved byte count; amount to write to the file |
| 2CF9 | 4 | `subpacket_len` | Length of the last data subpacket (32 bits, added to file_position) |
| 2CFD | 1 | `subpkt_term` | Terminator of the last data subpacket (ZCRCE/G/Q/W \| 80H) |
| 2CFE | 2 | `hdr_junk_limit` | get_header: remaining number of junk characters tolerated |
| 2D00 | 1 | `hdr_can_count` | get_header: remaining CAN characters before abort |
| 2D01 | 1 | `rx_frame_type` | Frame type of the last header received |
| 2D02 | 1 | `xm_first_flag` | FFH until the first valid XMODEM block has arrived |
| 2D03 | 1 | `xm_timeout` | XMODEM receive timeout in tenths of a second |
| 2D04 | 1 | `error_count` | Consecutive error/retry counter |
| 2D05 | 2 | `xm_block_len` | XMODEM bytes still to read in the current block |
| 2D07 | 1 | `xm_block_no` | Expected XMODEM block number |
| 2D08 | 1 | `xm_rx_char` | Last character received in XMODEM block handling |
| 2D09 | 1 | `xm_can_flag` | Set after one CAN, abort on the second |
| 2D0A | 1 | `parse_mode` | parse_filespec argument (nonzero: try DU form / named directory) |
| 2D0B | 1 | `parse_next_char` | Character following the parsed name |
| 2D0C | 1 | `wildcard_count` | Number of wildcard characters in the file name |
| 2D0D | 1 | `parsed_drive` | Drive from the file spec (0 = default) |
| 2D0E | 1 | `parsed_user` | User number from the file spec |
| 2D0F | 2 | `z3env_ptr` | Address of the ZCPR3 environment descriptor (0 if none) |

### C.2 SZ

**Variables inside the program image**

| Address | Name | Description |
|---|---|---|
| 0109 | `z3env_addr` | ZCPR3 environment address, patched in by Z3INS |
| 04E7 | `name_line_buf` | Console line buffer: CR LF, "d:" and file name |
| 051B | `pos_line_buf` | Console line buffer for the position display |
| 078F | `crc32_poly` | CRC-32 polynomial 0EDB88320H (little endian) |
| 0793 | `crc32_residue` | CRC-32 residue 0DEBB20E3H expected after a good frame |
| 084A | `const_1024` | 32-bit constant 1024 |
| 084E | `const_minus_1024` | 32-bit constant -1024 |
| 0852 | `protocol` | Selected protocol: 1 = XMODEM, 3 = YMODEM, 4 = ZMODEM (default) |
| 0853 | `window_default` | Default receiver window: value x 4 x 256 bytes |
| 1C35 | `in_file_active` | Flag byte: input file object in use |
| 1C36 | `out_file_active` | Flag byte: output file object in use |
| 1F78 | `argv_ptr` | Pointer to the argument table built by tokenize_args |

**Work area above the image**

| Address | Size | Name | Description |
|---|---|---|---|
| 2000 | 1 | `default_user` | User number at program start |
| 2001 | 1 | `default_drive` | Drive (1 = A:) at program start |
| 2002 | 1 | `saved_user` | User number to select (pair with work_fcb drive byte) |
| 2003 | 36 | `work_fcb` | Work FCB / DU pair for the command line file spec |
| 2027 | 64 | `stack_area` | Stack: grows down from aux_ring (SP is set to aux_ring at start) |
| 2067 | 6 | `aux_ring` | AUX receive ring buffer control block: count, write index, read index; 512 data bytes follow (also initial stack top) |
| 206D | 512 | `aux_ring_data` | Data area of the AUX receive ring (512 bytes) |
| 226D | 1 | `entry_user` | User number of the current file list entry |
| 226E | 36 | `send_fcb` | FCB of the file being sent |
| 2293 | 4 | `ltoa_value` | ltoa32: working copy of the value being converted |
| 2297 | 4 | `ltoa_temp` | ltoa32: temporary subtraction result |
| 229B | 4 | `crc32_value` | Running CRC-32 accumulator (4 bytes) |
| 229F | 1024 | `crc32_table` | CRC-32 lookup table, 256 x 4 bytes (229FH-269EH) |
| 269F | 1 | `error_count` | Consecutive error/retry counter |
| 26A0 | 4 | `rx_header_data` | Four argument bytes of the last received header |
| 26A4 | 4 | `pos_display` | Copy of the file position shown on the console |
| 26A8 | 1 | `rx_crc_mode` | CRC type of the last received header (10H = CRC-16, 20H = CRC-32) |
| 26A9 | 1 | `tx_crc_mode` | CRC type used for sending: 20H = CRC-32, 10H = CRC-16 (XMODEM CRC) |
| 26AA | 4 | `tx_header_data` | Four argument bytes for the next header to send |
| 26AE | 1 | `xm_first_flag` | FFH until the first block has been acknowledged |
| 26AF | 4 | `zack_pos` | Position from the last ZACK |
| 26B3 | 4 | `rx_pos_arg` | Position argument of the last ZRPOS/ZACK from the receiver |
| 26B7 | 4 | `tx_position` | Position in the file of the next byte to send (32 bits) |
| 26BB | 4 | `last_sync_pos` | Position at the last synchronisation point (ZCRCW) |
| 26BF | 4 | `last_zrpos_pos` | Position of the last ZRPOS request |
| 26C3 | 4 | `file_read_pos` | Position of the next byte to be read from the disk file |
| 26C7 | 4 | `pos_scratch` | Scratch 32-bit result for position arithmetic |
| 26CB | 2 | `rx_window_size` | Receiver buffer length from ZRINIT ZP0/ZP1 (0 = nonstop I/O) [Rxbuflen] |
| 26CD | 2 | `window_remaining` | Bytes left before the receiver must acknowledge |
| 26CF | 2 | `subpacket_size` | Current data subpacket size (starts at 1024, reduced after errors) |
| 26D3 | 1 | `same_zrpos_count` | Number of times in a row ZRPOS asked for the same position |
| 26D4 | 1 | `zrinit_zf0` | ZF0 from the receiver's ZRINIT: CANFDX 1, CANOVIO 2, CANBRK 4, CANCRY 8, CANFC32 20H, ESCCTL 40H |
| 26D5 | 1 | `escape_ctl_flag` | Nonzero (40H) if all control characters must be escaped |
| 26D6 | 1 | `eof_pending` | FFH when the end of the file has been read into the buffer |
| 26D7 | 1 | `eof_flag` | FFH when the disk file is at end of file |
| 26D8 | 1 | `subpkt_term` | Terminator for the next data subpacket (68H ZCRCE, 69H ZCRCG, 6BH ZCRCW) |
| 26D9 | 1 | `files_sent_count` | Number of files sent so far |
| 26DA | 2 | `buffer_mask` | File buffer size mask (power of two minus one) |
| 26DC | 4 | `buffer_start_pos` | File position corresponding to the start of the ring buffer |
| 26E0 | 1 | `last_rx_char` | Last character received from the modem |
| 26E1 | 1 | `xmodem_block_no` | Current XMODEM block number |
| 26E2 | 1 | `prev_rx_char` | Previous received character |
| 26E3 | 2 | `file_size` | Size of the current file in bytes (32 bits) |
| 26E5 | 2 | `file_size_hi` | High word of file_size (the 32-bit size is built in two halves) |
| 26E7 | 2 | `block_len` | Length of the current block / subpacket |
| 26EB | 1 | `opt_protect_flag` | FFH if -p (protect) was given |
| 26EC | 1 | `opt_append_flag` | FFH if -a (append) was given |
| 26ED | 1 | `opt_convert_flag` | FFH if -c (convert to local line feeds) was given |
| 26EE | 1 | `opt_binary_flag` | FFH if -b (binary) was given |
| 26EF | 2 | `file_buffer_base` | Start of the file data ring buffer |
| 26F1 | 2 | `unused_26F1` | Cleared at startup, never read |
| 26F3 | 2 | `file_buffer_size` | Size of the file data ring buffer |
| 26F5 | 2 | `unused_26F5` | Cleared at startup, never read |
| 26F7 | 1 | `file_count` | Number of files in the list to send |
| 26F8 | 1 | `zrqinit_retries` | Remaining attempts to get ZRINIT |
| 26F9 | 1 | `resp_junk_count` | Garbage characters seen while streaming |
| 26FA | 4 | `zrpos_target` | Position requested by ZRPOS |
| 26FE | 4 | `reposition_temp` | Temporary position used while repositioning the file |
| 2702 | 4 | `chunk_len` | Number of bytes in the current chunk |
| 2706 | 1 | `data_terminator` | Terminator byte of the data subpacket being sent |
| 2707 | 1 | `out_frame_type` | Frame type of the header being sent |
| 2708 | 2 | `hdr_junk_limit` | get_header: remaining number of junk characters tolerated |
| 270A | 1 | `hdr_can_count` | get_header: remaining CAN characters before abort |
| 270B | 1 | `rx_frame_type` | Frame type of the last header received |
| 270C | 1 | `parse_mode` | parse_filespec argument (nonzero: try DU form / named directory) |
| 270D | 1 | `parse_next_char` | Character following the parsed name |
| 270E | 1 | `wildcard_count` | Number of wildcard characters in the file name |
| 270F | 1 | `parsed_drive` | Drive from the file spec (0 = default) |
| 2710 | 1 | `parsed_user` | User number from the file spec |
| 2711 | 2 | `z3env_ptr` | Address of the ZCPR3 environment descriptor (0 if none) |
| 2713 | 1 | `sort_key_flag` | Sort key: 0 = name then extension, 1 = extension first |
| 2714 | 36 | `dir_search_fcb` | Wildcard FCB used for BDOS search first/next |
| 2738 | 1 | `dir_dup_mode` | File seen in several extents: 0 = keep the highest extent, nonzero = keep the lowest |
| 2739 | 2 | `dir_table_start` | Start of the directory entry table (16 bytes per entry) |
| 273B | 2 | `dir_entry_count` | Number of directory entries collected |
| 273D | 2 | `dir_marked_count` | Number of entries marked / kept |
| 273F | 2 | `dir_table_ptr` | Pointer into the directory table (also sort block base) |
| 2741 | 2 | `sort_count` | Sort control block: element count |
| 2743 | 2 | `sort_elem_size` | Sort control block: element size (16) |
| 2745 | 2 | `sort_compare_fn` | Sort control block: compare routine address |
| 2747 | 2 | `sort_aux` | Sort control block: auxiliary pointer |
| 2749 | 2 | `sort_limit` | Sort control block: limit (00FFH) |
| 274B | 3 | `dpb_bsh` | Disk parameter block: BSH, BLM, EXM |
| 274E | 2 | `disk_blocks` | Number of allocation blocks on the disk |
| 2750 | 2 | `dir_entries` | Number of directory entries on the disk |
| 2752 | 1 | `dir_attr_mask` | Selection mask: bit 7 include DIR files, bit 6 include SYS files, bit 5 any user number, bits 0-4 user number |
| 2753 | 2 | `sort_blk_ptr` | Pointer to the caller's sort control block |
| 2755 | 2 | `sort_blk_base` | Working copy of sort block: base address |
| 2757 | 2 | `sort_blk_count` | ... element count |
| 2759 | 2 | `sort_blk_size` | ... element size |
| 275B | 2 | `sort_blk_cmp` | ... compare function |
| 275D | 2 | `sort_index_ptr` | Pointer to the sort index array |
| 275F | 1 | `sort_blk_flag` | Sort block flag (indirect elements) |
| 2760 | 1 | `sort_blk_flag2` | Sort block second flag |
| 2761 | 2 | `sort_i` | Sort loop index i |
| 2763 | 2 | `sort_j` | Sort loop index j |
| 2765 | 168 | `in_file` | Input file object: open flag, count, pointer, 36-byte FCB, 128-byte buffer (168 bytes) |
| 280D | 168 | `out_file` | Output file object (same layout as in_file) |
| 28B5 | 2 | `cur_file_ptr` | Pointer to the file object being operated on |
| 28B7 | 1 | `file_io_char` | Character passed through file get/put |
| 28B8 | 36 | `fcb_copy` | Scratch copy of a 36-byte FCB |


## Appendix D: BDOS functions used

| No. | Function | RZ | SZ | Purpose in these programs |
|---|---|---|---|---|
| 1 | `C_READ` | x | x | read the key that ESC-abort checks for |
| 3 | `A_READ` | x | x | read a character from AUX |
| 4 | `A_WRITE` | x | x | send a character to AUX |
| 7 | `A_STATIN` | x | x | AUX input status |
| 8 | `A_STATOUT` | x | x | AUX output status |
| 9 | `C_WRITESTR` | x | x | banner, prompts, messages and progress |
| 11 | `C_STAT` | x | x | check the console for a key (ESC abort) |
| 12 | `S_BDOSVER` | x | x | require CP/M 3 |
| 14 | `DRV_SET` | x | x | select drive |
| 15 | `F_OPEN` | x | x | open a file |
| 16 | `F_CLOSE` | x | x | close a file |
| 17 | `F_SFIRST` | x | x | search for a file (RZ) / first directory entry (SZ) |
| 18 | `F_SNEXT` |  | x | next directory entry (SZ) |
| 19 | `F_DELETE` | x |  | delete an existing file (RZ) |
| 20 | `F_READ` |  | x | read a 128-byte record |
| 21 | `F_WRITE` | x | x | write a 128-byte record |
| 22 | `F_MAKE` | x | x | create a file |
| 25 | `DRV_GET` | x | x | current drive |
| 26 | `F_DMAOFF` | x | x | set DMA address |
| 31 | `DRV_DPB` |  | x | disk parameter block (SZ directory scan) |
| 32 | `F_USERNUM` | x | x | get/set user number |
| 33 | `F_READRAND` | x |  | read the last record when resuming or appending (RZ) |
| 35 | `F_SIZE` | x | x | file size in records |
| 36 | `F_RANDREC` |  | x | set random record |
| 44 | `F_MULTISEC` | x |  | multi-sector count 1 |
| 49 | `S_SYSVAR` | x | x | read/write System Control Block (console vectors) |


## Appendix E: Shared routines

Routines present in both programs under the same name, with their addresses.  Differences between the two copies are limited to constants such as the ring size.

| Routine | RZ | SZ |
|---|---|---|
| `start` | 0100 | 0100 |
| `get_default_du` | 0195 | 01F1 |
| `set_du` | 01B0 | 020C |
| `err_need_cpm3` | 01C2 | 021E |
| `usage_exit` | 01CA | 0226 |
| `parse_options` | 039A | 03B3 |
| `opt_xmodem` | 03C9 | 03E2 |
| `opt_ymodem` | 03CD | 03E6 |
| `opt_zmodem` | 03D1 | 03EA |
| `set_protocol` | 03D3 | 03EC |
| `opt_protect` | 03D7 | 03F0 |
| `opt_binary` | 03DD | 03FC |
| `opt_convert` | 03E3 | 0402 |
| `scb_setup` | 03EF | 0408 |
| `scb_restore` | 0451 | 046A |
| `print_err_count` | 0482 | 048A |
| `print_filename` | 04A4 | 04AC |
| `print_position` | 050B | 0508 |
| `print_cant_open` | 054D | 0526 |
| `print_skipped` | 0552 | 052B |
| `set_pending_char` | 057F | 0558 |
| `aux_poll_input` | 0588 | 0561 |
| `aux_get_char` | 05B4 | 058D |
| `aux_putc` | 05C7 | 05A0 |
| `aux_out_ready` | 05CD | 05A6 |
| `aux_wait_input` | 05D4 | 05AD |
| `delay_short` | 05EB | 05C4 |
| `ring_get` | 05F7 | 05D0 |
| `ring_put` | 061C | 05F5 |
| `clear_fcb` | 0643 | 061C |
| `ring_reset` | 064E | 0623 |
| `dispatch` | 067F | 0629 |
| `zero32` | 0688 | 0632 |
| `copy32` | 0692 | 063C |
| `cmp32_signed` | 06A1 | 064B |
| `cmp32_unsigned` | 06C2 | 066C |
| `eq32` | 06D3 | 067D |
| `add32` | 06E4 | 068E |
| `sub32` | 06FA | 06A4 |
| `inc32` | 0712 | 06BC |
| `set32_minus1` | 0726 | 06D0 |
| `dec32` | 0729 | 06D3 |
| `and32` | 073B | 06E5 |
| `ltoa32` | 0774 | 071E |
| `checksum_add` | 07DD | 0787 |
| `crc32_update` | 07ED | 0797 |
| `crc32_table_init` | 0825 | 07CF |
| `crc16_update` | 0885 | 082F |
| `crc_init` | 08A0 | 12DC |
| `calc_buffer_mask` | 08B6 | 088A |
| `send_can_string` | 0DD9 | 15A8 |
| `send_string` | 0DDC | 15AB |
| `aux_getc_timeout` | 0DE7 | 15B6 |
| `getc_7bit_filt` | 0E05 | 14D1 |
| `getc_zdl_filt` | 0E2F | 14FB |
| `zdlread_escape` | 0E50 | 151C |
| `get_header` | 0FD1 | 12EB |
| `get_bin32_header` | 10C5 | 13DF |
| `get_bin16_header` | 1100 | 141A |
| `get_hex_header` | 113F | 1454 |
| `get_hex_byte` | 1194 | 14A4 |
| `hex_digit_value` | 11B3 | 14C3 |
| `send_hex_header` | 13BA | 1204 |
| `put_hex_byte` | 1418 | 1262 |
| `put_zdle_char` | 1438 | 1282 |
| `aux_putc_wait` | 145C | 12A6 |
| `parse_filespec` | 1492 | 15D4 |
| `parse_fcb` | 14A7 | 15E9 |
| `parse_fcb_field` | 1522 | 1664 |
| `inc_wild_count` | 1543 | 1685 |
| `parse_du` | 154A | 168C |
| `parse_du_inner` | 1552 | 1694 |
| `parse_named_dir` | 159D | 16DF |
| `named_dir_lookup` | 15A5 | 16E7 |
| `is_delimiter` | 15D9 | 171B |
| `parse_decimal` | 15FA | 173C |
| `digit_value` | 1625 | 1767 |
| `clear_dirspec` | 162C | 176E |
| `clear_fcb_tail` | 1632 | 1774 |
| `fill_clear` | 1645 | 1787 |
| `z3env_duok` | 164A | 178C |
| `z3env_max_drive` | 1652 | 1794 |
| `z3env_max_user` | 165A | 179C |
| `z3env_ndr_ptr` | 1662 | 17A4 |
| `set_z3env` | 1683 | 17C5 |
| `get_drive_user` | 1687 | 1D8C |
| `console_read` | 16A5 | 1E07 |
| `console_status` | 16AA | 1E0C |
| `bdos_save_regs` | 16AF | 1E11 |
| `bdos_call_a` | 16B8 | 1E1A |
| `fcb_to_name` | 16C4 | 1E26 |
| `copy_name_part` | 16DA | 1E3C |
| `a_to_decimal` | 16E7 | 1E49 |
| `decimal_digit` | 1703 | 1E65 |
| `decimal_emit` | 1717 | 1E79 |
| `upcase_string` | 171E | 1E80 |
| `tokenize_args` | 172E | 1EAB |
| `skip_blanks` | 176B | 1EE8 |
| `skip_token` | 1779 | 1EF6 |
| `memset` | 1786 | 1F03 |
| `memset_inner` | 178C | 1F09 |
| `to_upper` | 1793 | 1F3F |

