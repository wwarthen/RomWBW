# Writing settings in cfg_MASTER.asm for hbconfig

The config menu, hbconfig
(`make config ROM_PLATFORM=<platform> ROM_CONFIG=<config>`, the same
names as a ROM build) should have no list of options of its own. It
should read `cfg_MASTER.asm` and work out the menus, the types and the
help text from the setting lines themselves. When `ROM_PLATFORM` or
`ROM_CONFIG` is not given, the menu should ask for the platform and
the config. A new setting should show up in the menu without any
change to the tool, as long as it follows the rules below. A setting
that breaks them still builds fine, it just ends up in the wrong menu
or with the wrong type.

## 1. The setting line

```
NAME  .EQU  VALUE  ; COMMENT
;@TAG ...
```

- One setting per line. `cfg_MASTER.asm` uses `.EQU`, every other
  config file uses `.SET`.
- Between the name, `.EQU`/`.SET`, the value and the comment any mix
  of spaces and tabs is fine, any number of them.
- Tag lines (`;@DEPENDS`, `;@HELP`) go on their own lines right below
  the setting, see 4.
- The comment is the help text in the menu, shown exactly as written
  (no case change, no reflowing). Every setting should have one, but
  it is not required: a setting without a comment is still in the
  menu, just without help.
- Plain ASCII only, in the whole file. The tool should stop with the
  line number of a non-ASCII character.
- `#DEFINE` settings (`PLATFORM_NAME`, `BOOT_DEFAULT`, `AUTO_CMD`,
  `DEFSERCFG`) are not in the menu (yet), and a save keeps every
  `#DEFINE` line exactly as it is.

## 2. The type comes from the value

| Value | Type |
|---|---|
| `TRUE` / `FALSE` | checkbox |
| `$40` | hex number |
| `64` | number; `(0-3)` in the comment sets a range |
| `DL_CRITICAL` | pick list, see below |
| anything else | text (`CPUOSC/2`, `SER_57600_8N1`, ...) |

- An expression like `CPUOSC/2` or `(4915200/8)` should be kept as
  written, never worked out, so it stays linked to `CPUOSC`. It is
  shown as text.
- A `(0-3)` range should only be used when both the `cfg_MASTER` value
  and the board's value fit in it.

### Pick lists

- A setting is a pick list when its cfg_MASTER value is a constant
  defined as `NAME .EQU <number>` in `std.asm` or `hbios.inc`.
- The prefix is that value up to and including its last `_`:
  `DL_CRITICAL` gives `DL_`, `SPD_HIGH` gives `SPD_`.
- The choices are found around the value's own definition: the tool
  should go up and down from that line while each line defines another
  constant with the same prefix. The first line that doesn't (a
  comment, a blank line, another prefix) ends the list.

  ```
  SPD_FIXED  .EQU 0   ; CPUSPDCAP .EQU SPD_FIXED -> FIXED, HILO
  SPD_HILO   .EQU 1
  ;
  SPD_UNSUP  .EQU 0   ; CPUSPDDEF .EQU SPD_HIGH  -> UNSUP, HIGH, LOW
  SPD_HIGH   .EQU 1
  SPD_LOW    .EQU 2
  ```

  Both use `SPD_`, but the `;` line between them makes two lists.
- The constant's own comment is the text of the choice.
- A list needs at least two choices, and the board's value must be one
  of them; otherwise the setting is shown as text.
- Do: keep a pick list's constants together, one after the other,
  including the `_NONE` one.
- The list in the setting's comment (`DL_[NONE|CRITICAL|...]`) should
  not be used by the tool, it is for people only. Keep it right anyway.

## 3. Menus

### Driver menus

- A setting named `<BASE>ENABLE` starts a menu for that BASE, with the
  ENABLE setting first. Menu title: the ENABLE's comment, with `BASE: `
  in front unless the comment starts with its own `PREFIX:` already
  (`FP: MASTER ENABLE FOR FRONT PANEL`).
- Every other setting whose name starts with that BASE joins the menu,
  wherever it sits in the file:

  ```
  CTCENABLE   CTCBASE   CTCTIMER   ->  one "CTC" menu
  ```

- When several BASEs fit, the longest wins: `LCDI2CADDR` goes to
  `LCDI2C`, not `LCD`.
- Menus are flat, never one inside another.
- Do: start every setting of a driver with the driver's BASE.
- Don't: name a driver setting without its BASE (`AYMODE` belongs to
  `AY38910ENABLE` but does not start with `AY38910`, so it misses the
  menu).
- Don't: put a unit or slot number at the end of the name. The BASE
  is everything before ENABLE, number included, so the number goes
  right after the driver name and before the rest:

  ```
  I2CEEPROM0ENABLE  I2CEEPROM0SHIFT  I2CEEPROM0BLKCNT  ->  one menu
  I2CEEPROMADR0ENABLE  I2CEEPROMSHIFT0  I2CEEPROMBLKCNT0
  ```

  In the second naming the slot menu holds only its ENABLE;
  `SHIFT0` and `BLKCNT0` end up in the `I2CEEPROM` menu.

### Other settings

- Settings that are not part of a driver stay in the blocks of
  `cfg_MASTER.asm`: settings on consecutive lines, ended by any comment
  or blank line. A `;` line is enough to start a new block.
- Block title: the `PREFIX:` all comments in the block start with
  (`SIO 0A: ...`), otherwise `FIRST .. LAST` (the first and last
  setting names), or the name alone for a one-setting block.
- Do: one topic per block. Split unrelated settings with a `;` line.

## 4. Tags

Tags are lines of their own, right below the setting in
`cfg_MASTER.asm`, each starting with `;@` at the start of the line.
`;@DEPENDS` and `;@HELP` lines can be mixed, one after another. Any
other line ends the tags of that setting. To the assembler they are
plain comment lines.

### ;@DEPENDS \<expression\>

- On a TRUE/FALSE setting: must hold whenever the setting is TRUE.
- On any other setting: must always hold.
- Names are `cfg_MASTER` settings, written the RomWBW way:

  ```
  &&  ||  !  ( )
  =  !=  <  <=  >  >=
  TRUE  FALSE  $FF  12  CPU_Z280 (a pick list option)
  ```

  A pick list only takes `=` and `!=`.
- Several `;@DEPENDS` lines on one setting must all hold.
- Examples from `cfg_MASTER.asm`:

  ```
  INTMODE ...
  ;@DEPENDS INTMODE <= 3
  ;@DEPENDS INTMODE != 3 || (CPUFAM = CPU_Z280 && MEMMGR = MM_Z280)
  VDAEMU_SERKBD ...
  ;@DEPENDS VDAEMU_SERKBD = $FF || !AUTOCON
  ```

- The menu should refuse to save a config that breaks one, and
  `make checkconfig` should check a config without the menu (see
  SPEC.md 2). An unknown name in a tag should be reported as a bad
  tag.
- Do: add a `;@DEPENDS` for every `*** ERROR` check in the build that
  is about settings, so the menu catches it before the build does.

### ;@HELP \<text\>

For help that doesn't fit in the one-line comment.

- The help shown is the one-line comment first, then the `;@HELP`
  text, one menu line per `;@HELP` line, exactly as written (no case
  change, no reflowing).
- A `;@HELP` line with no text is an empty line in the help.
- Example:

  ```
  MDFFENABLE    .EQU    FALSE           ; MD: ENABLE FLASH FILE SYSTEM
  ;@HELP MAKES THE ROM DISK (C:) WRITABLE WHEN THE ROM CHIP IS FLASH.
  ;@HELP
  ;@HELP CAUTION: C: SHARES THE CHIP WITH THE ROM IMAGE, A REFLASH
  ;@HELP WILL LIKELY WIPE IT.
  ```

## 5. General

- Every setting in `cfg_MASTER.asm` should be read somewhere in the
  source. A setting nothing reads still shows up in the menu and
  looks like it does something.
- The menu should only write `.SET` lines into the board file you name,
  never into `cfg_MASTER.asm` or `cfg_<platform>.asm`.
