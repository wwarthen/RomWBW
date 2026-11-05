# hbconfig specification

hbconfig is a menu-driven editor for RomWBW board configs. This
describes what the tool should do. How settings in `cfg_MASTER.asm`
are written so the tool can read them is in `RULES.md`.

## 1. Scope

- The tool edits one config file: `Config/<platform>_<config>.asm`,
  the file a ROM build with `ROM_PLATFORM=<platform>
  ROM_CONFIG=<config>` uses. That can be a user's own config or a
  `_std` file.
- It never changes `cfg_MASTER.asm` or `cfg_<platform>.asm`.
- It is optional. The normal build should never run it or need it,
  and a config file written by hand should keep working exactly as
  today.

## 2. Running it

- `make config ROM_PLATFORM=<platform> ROM_CONFIG=<config>` opens the
  menu for that config.
- When `ROM_PLATFORM` or `ROM_CONFIG` is not given, the menu should ask
  for them: the platform from a list of the platforms that have a
  `cfg_<platform>.asm`, then the config from a list of that platform's
  existing configs, or a new name (see 8).
- `make showconfig ROM_PLATFORM=<platform> ROM_CONFIG=<config>` prints,
  without the menu, every setting the config ends up with that differs
  from `cfg_MASTER.asm`, and the file that set it.
- `make checkconfig ROM_PLATFORM=<platform> ROM_CONFIG=<config>` checks
  the config against every `;@DEPENDS` without the menu (see 6). It
  prints the broken rules and fails when there are any, so it can run
  over all configs in one go.
- On Windows it is `Config.cmd`, in the RomWBW root next to
  `Build.cmd`: `Config <platform> <config>` opens the menu,
  `Config -show <platform> <config>` and
  `Config -check <platform> <config>` do what `make showconfig` and
  `make checkconfig` do. Like `make config`, it asks for the platform
  and config when they are not given. The config is then built the
  usual way, `Build <platform> <config>`.
- `Config.cmd` starts the tool with its arguments, using a Python of its
  own in `Tools\python`, never the system one. When that is missing it
  asks, then `install-python.ps1` downloads it. `Config -install` does
  it again. Everything else is in the tool itself, the same for every
  build environment.
- It should run on every supported build environment: Linux, macOS and
  Windows. A text menu in the style of the Linux kernel's menuconfig
  fits all three. When something extra has to be installed (on Windows
  Python and a curses package), a small script installs it into the
  RomWBW tree: nothing outside it changes, and each download is checked
  against a SHA-256 sum written in the script.

## 3. The cascade

- The config is read the way the assembler reads it: top to bottom, an
  `#INCLUDE` of another `.asm` file is read in full at that point, and
  the last `.EQU`/`.SET` of a name wins. For a normal config that gives
  `cfg_MASTER.asm`, then `cfg_<platform>.asm`, then `<platform>_std.asm`,
  then the config's own lines.
- The **inherited value** of a setting is what the config gets with its
  own `.SET` lines left out: from the std file, the platform file or
  `cfg_MASTER.asm`, whichever sets it last. For a `_std` file it comes
  from the platform file or `cfg_MASTER.asm`.
- The menu shows the config's current value. The help for a setting
  should also show its inherited value and the file it comes from.

## 4. What the menu shows

- Settings are grouped into menus as described in `RULES.md`.
- The normal view shows only the menus that matter for this config,
  those with a setting that is:
  - set by the std file or the config itself,
  - in the menu of a driver whose ENABLE is on,
  - changed since the menu opened, so it doesn't vanish while being
    edited.
  A menu that is shown shows all its settings, so a setting is never
  hidden next to one that is shown.
- One key switches to showing every setting, and back.
- A setting whose value differs from its inherited value is marked
  (a different color), and so are the menus it is in. The marking
  follows edits: change a value and it is marked, set it back and the
  mark goes away.

## 5. Help

- The help for a setting is its comment in `cfg_MASTER.asm` and its
  `;@HELP` lines (see `RULES.md`), shown as written.
- Below that: the inherited value and where it comes from (see 3), and
  every `;@DEPENDS` rule on the setting.

## 6. Dependencies

- The rules are the `;@DEPENDS` tags in `cfg_MASTER.asm` (see
  `RULES.md`). The tool has no rules of its own.
- On save, every rule is checked against the values in the menu. When
  one breaks, nothing is written: the menu lists the broken rules and
  offers to go back into the menu, with the edits kept, to fix them.
- A tag the tool can't read (bad syntax, an unknown setting or pick
  list option) is reported as a bad tag, with the setting it is on.
- A config that passes the check should build. The first rules to add
  are the build's own `*** ERROR` checks that are about settings, so
  the menu stops a config before the build does.

## 7. Writing the config file

The config file keeps only what differs from what it inherits, and
stays a normal, hand-editable assembler file.

- A changed setting that the file already sets: the value in its last
  `.SET` line is replaced, and the rest of the line (spaces and tabs,
  comment) stays as it was.
- A setting set back to its inherited value: its `.SET` lines are
  removed, with the indented `; ...` lines right below them that
  continue their comment.
- A setting the file didn't set yet: a new `.SET` line at the end of
  the file, laid out like the existing config files (name at column 0,
  `.SET` at 16, value at 24, comment at 40, tabs 8 wide), with the
  comment from `cfg_MASTER.asm`.
- Every other line (comments, `#INCLUDE`, `#DEFINE`, blank lines) stays
  exactly as it was.
- The file keeps its own line endings (CRLF or LF). Only plain ASCII
  is written.
- The new file is written next to the old one and then swapped in, so
  a failure halfway never leaves a half-written config.
- Quitting without saving changes nothing. After a save the tool lists
  what it changed, or says there were no changes.

## 8. A new config

- When the config named doesn't exist, the tool should offer to create
  it. The name may only hold letters, digits and `_`.
- It lists the platform's std files to start from, `<platform>_std`
  first, then the other `<platform>_*_std` files, each with the title
  from its header ("DEFAULT BUILD SETTINGS FOR ...").
- The new file gets a short header with that title and an `#INCLUDE`
  of the std file picked, and the same line endings as that std file.
- The menu then opens on the new config. When nothing gets saved, the
  tool asks whether to keep the new file anyway (default no); if not,
  it is removed again. It is also removed when the tool is
  interrupted.

## 9. Errors

- A non-ASCII character in any file read: stop with the file and line
  number.
- A file that can't be read, or an `#INCLUDE` of a file that doesn't
  exist: stop with a one-line message naming the file.
- An unknown platform: stop and list the known ones.
