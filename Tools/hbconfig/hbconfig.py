#!/usr/bin/env python3
#
# hbconfig: menu-driven editor for RomWBW board configs.
#
# Reads cfg_MASTER.asm and the #INCLUDE chain of Config/<platform>_<config>.asm,
# shows every setting in a menuconfig-style text menu, and writes what was
# changed back into that one config file as .SET lines. What the tool does
# is in SPEC.md, how settings in cfg_MASTER.asm are written for it in
# RULES.md, both next to this file.
#
# Usage: hbconfig.py [PLATFORM [CONFIG]]          open the menu
#        hbconfig.py -show [PLATFORM [CONFIG]]    print what the config changes
#        hbconfig.py -check [PLATFORM [CONFIG]]   check every ;@DEPENDS
#
# A missing PLATFORM or CONFIG is asked for. PYTHON in the Makefile picks the
# Python to run it with; on Windows Config.cmd always uses its own, in
# Tools\python (install-python.ps1).
#
# AI: this tool was written with Claude, an AI (LLM) by Anthropic. Claude
# wrote the code; Willy De la Court (WDC) directed it, reviewed every
# change and tested it on real configs. As agreed with Wayne Warthen on
# issue #722, it falls under the applications exception in
# CONTRIBUTING.md: a standalone build-host tool, never part of the normal
# build or of the ROM.
#

import argparse
import os
import re
import shutil
import signal
import sys
import tempfile

BANNER = "hbconfig: written with Claude (AI), see Tools/hbconfig/ReadMe.txt"

HERE = os.path.dirname(os.path.realpath(__file__))
HBIOS = os.path.normpath(os.path.join(HERE, "..", "..", "Source", "HBIOS"))
MASTER = os.path.join(HBIOS, "cfg_MASTER.asm")
# the start of a new config, see new_config()
NEW_CONFIG_TEMPLATE = os.path.join(HERE, "new_config.asm")

# NAME  .EQU  VALUE  ; COMMENT   (the comment is optional)
# VALUE is everything up to the ";" or the end of the line, so an
# expression like "CPUOSC / 12" is kept whole, spaces and all.
EQU_RE = re.compile(r"^(\w+)\s+\.EQU\s+([^;\s][^;]*?)\s*(?:;\s*(.*))?$",
                    re.IGNORECASE)
# NAME  .SET  VALUE  or  NAME  .EQU  VALUE, as used in the config files
SETTING_RE = re.compile(r"^(\w+)\s+\.(?:EQU|SET)\s+([^;\s][^;]*?)\s*(?:;.*)?$",
                        re.IGNORECASE)
# #INCLUDE "file", upper or lower case
INCLUDE_RE = re.compile(r'^\s*#INCLUDE\s+"([^"]+)"', re.IGNORECASE)
# where the constants for pick-list settings are defined, see
# load_constants()
CONSTANT_FILES = ("std.asm", "hbios.inc")
# (0-3) in a comment: the lowest and highest value a number may have
RANGE_RE = re.compile(r"\((-?\d+)-(\d+)\)")


def ascii_lines(path):
    """Yield (line number, text) for every line of a file.

    The file must be plain ASCII. Lines are read as bytes and decoded one
    at a time, so a bad byte is reported with its line number.
    """
    with open(path, "rb") as file:
        for num, raw in enumerate(file, start=1):
            try:
                text = raw.decode("ascii").rstrip("\r\n")
            except UnicodeDecodeError:
                raise ValueError(f"{os.path.relpath(path, HBIOS)}:{num}: "
                                 f"non-ASCII character")
            yield num, text


def read_lines(path):
    """ascii_lines(), without the blank lines and the comments."""
    for num, text in ascii_lines(path):
        stripped = text.strip()
        if stripped == "" or stripped.startswith(";"):
            continue
        yield num, text


def add_tag(setting, tag, num):
    """Add one ";@" tag line to the setting above it: ";@DEPENDS <rule>"
    or ";@HELP <text>". tag is the line without its ";@"."""
    keyword = re.match(r"\w*", tag).group(0)
    rest = tag[len(keyword):]
    if keyword.upper() == "DEPENDS" and rest.strip():
        setting["depends"].append(rest.strip())
    elif keyword.upper() == "HELP" and (rest == "" or rest[0] in " \t"):
        # the text exactly as written, only the one separating space off
        setting["help"].append(rest[1:].rstrip())
    else:
        setting["bad_tags"].append(f"cfg_MASTER.asm:{num}: bad tag ;@{tag}")


def parse_master(path):
    """The settings in a cfg_MASTER.asm file, in file order: dicts with
    name, value, comment, line number, and from the ";@" lines right below
    the setting its ;@DEPENDS rules and ;@HELP lines."""
    settings = []
    setting = None      # the setting tag lines below it belong to
    for num, text in ascii_lines(path):
        if setting is not None and text.startswith(";@"):
            add_tag(setting, text[2:], num)
            continue
        setting = None
        stripped = text.strip()
        if stripped == "" or stripped.startswith(";"):
            continue
        match = EQU_RE.match(text)
        if match:
            setting = {
                "name": match.group(1),
                "value": match.group(2),
                "comment": (match.group(3) or "").rstrip(),
                "depends": [],
                "help": [],
                "bad_tags": [],
                "line": num
            }
            settings.append(setting)
    return settings


def resolve(path, state):
    """Read a config file the way the assembler does: top to bottom, and
    an #INCLUDE of another .asm file is read in full at that point.

    state["values"]:  name -> (value, file that set it last)
    state["chain"]:   every file read, in the order they were opened

    If state["ignore_file"] is set, settings in that file are skipped, to
    see what a config would get without its own .SET lines.
    """
    rel = os.path.relpath(path, HBIOS)
    state["chain"].append(rel)
    for num, text in read_lines(path):
        match = INCLUDE_RE.match(text)
        if match and match.group(1).lower().endswith(".asm"):
            resolve(os.path.join(HBIOS, match.group(1)), state)
            continue
        match = SETTING_RE.match(text)
        if match and rel != state.get("ignore_file"):
            state["values"][match.group(1)] = (match.group(2), rel)


def config_file(platform, config):
    """Config/<platform>_<config>.asm, relative to Source/HBIOS."""
    return os.path.join("Config", f"{platform}_{config}.asm")


def load_board(platform, config):
    """Read cfg_MASTER.asm and the include chain of the config file.
    Returns (master, state, board_file): the cfg_MASTER settings as
    parse_master() gives them, the state resolve() filled in, and the
    config file relative to Source/HBIOS."""
    board_file = config_file(platform, config)
    if not os.path.isfile(os.path.join(HBIOS, board_file)):
        sys.exit(f"hbconfig: no such config: {board_file}")

    master = parse_master(MASTER)
    if not master:
        sys.exit(f"hbconfig: no .EQU settings found in {MASTER}")
    state = {"values": {}, "chain": []}
    resolve(os.path.join(HBIOS, board_file), state)
    if "cfg_MASTER.asm" not in state["chain"]:
        sys.exit(f"hbconfig: {platform}_{config} does not include "
                 f"cfg_MASTER.asm (chain: {' -> '.join(state['chain'])}), "
                 f"not supported")
    return master, state, board_file


def show_board(platform, config):
    """-show: the settings a config ends up with that differ from
    cfg_MASTER.asm, and the file that set each one."""
    master, state, _ = load_board(platform, config)

    # the config file includes its parent first, so reversed is top-down
    print(" -> ".join(reversed(state["chain"])))
    print()

    rows = []
    for setting in master:
        value, src = state["values"][setting["name"]]
        if value != setting["value"]:
            rows.append((setting["name"], value, setting["value"], src))
    known = {setting["name"] for setting in master}
    unknown = [(name, value, "-", src)
               for name, (value, src) in state["values"].items()
               if name not in known]

    header = ("SETTING", "VALUE", "MASTER", "SET IN")
    widths = [max(len(row[i]) for row in rows + unknown + [header])
              for i in range(3)]
    for row in [header] + rows + unknown:
        print(f"{row[0]:<{widths[0]}}  {row[1]:<{widths[1]}}  "
              f"{row[2]:<{widths[2]}}  {row[3]}")

    print()
    print(f"{len(rows)} settings differ from cfg_MASTER.asm")
    if unknown:
        print(f"{len(unknown)} settings are not in cfg_MASTER.asm "
              f"(MASTER column '-')")


def load_constants():
    """Every NAME .EQU <plain number> in std.asm and hbios.inc, where the
    constants pick-list settings use are defined (DL_CRITICAL, PLT_RCZ80,
    ...). Returns name -> (comment, file, line number)."""
    constants = {}
    for file_name in CONSTANT_FILES:
        for num, text in read_lines(os.path.join(HBIOS, file_name)):
            match = EQU_RE.match(text)
            if match and number_of(match.group(2)) is not None:
                constants.setdefault(match.group(1),
                                     ((match.group(3) or "").strip(),
                                      file_name, num))
    return constants


def pick_list_options(value, constants):
    """The choices for a setting whose value is a constant like
    DL_CRITICAL: the constants with the same prefix (DL_, everything up to
    the last "_") on the lines right around its definition, in file order.

    Only the lines right around it, because some prefixes hold two lists:
    SPD_FIXED/SPD_HILO and SPD_UNSUP/SPD_HIGH/SPD_LOW are separate blocks.
    Returns an empty list when value is not such a constant, or has no
    neighbors with the same prefix.
    """
    if value not in constants or "_" not in value:
        return []
    prefix = value[:value.rfind("_") + 1]
    _, file_name, line = constants[value]
    name_on_line = {num: name
                    for name, (_, other_file, num) in constants.items()
                    if other_file == file_name and name.startswith(prefix)}
    first_line = line
    while first_line - 1 in name_on_line:
        first_line -= 1
    last_line = line
    while last_line + 1 in name_on_line:
        last_line += 1
    options = [name_on_line[num] for num in range(first_line, last_line + 1)]
    return options if len(options) >= 2 else []


def setting_type(master_value, board_value, comment, constants):
    """Pick the Kconfig type that fits both the cfg_MASTER value and the
    config's value: "choice", "bool", "hex", "int" or "string".

    Returns (type, details). details is the list of options for a choice,
    (lowest, highest) for an int when the comment gives a range like
    "(0-3)" and both values fit in it, else None.
    """
    options = pick_list_options(master_value, constants)
    if options and board_value in options:
        return "choice", options
    both_values = (master_value, board_value)
    if all(value.upper() in ("TRUE", "FALSE") for value in both_values):
        return "bool", None
    if all(re.fullmatch(r"\$[0-9A-Fa-f]+", value) for value in both_values):
        return "hex", None
    if all(re.fullmatch(r"-?\d+", value) for value in both_values):
        match = RANGE_RE.search(comment)
        if match:
            lowest = int(match.group(1))
            highest = int(match.group(2))
            if all(lowest <= int(value) <= highest for value in both_values):
                return "int", (lowest, highest)
        return "int", None
    # anything else, e.g. PLT_RCZ80, SER_57600_8N1 or CPUOSC
    return "string", None


def quote(text):
    """Put text in double quotes the way Kconfig wants it."""
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def kconfig_value(setting_kind, value):
    """Write a RomWBW value the way Kconfig wants it: TRUE/FALSE become
    y/n, $FF becomes 0xFF, strings get quotes."""
    if setting_kind == "bool":
        return "y" if value.upper() == "TRUE" else "n"
    if setting_kind == "hex":
        return "0x" + value[1:]
    if setting_kind == "string":
        return quote(value)
    return value


def group_settings(master):
    """Sort the settings into menus. Returns a list of (title, settings),
    each menu where its first setting is in cfg_MASTER.asm.

    Every <BASE>ENABLE setting (UARTENABLE: BASE is UART) gets a menu of
    its own, with the ENABLE setting first. Every other setting whose name
    starts with a BASE joins that menu, the longest BASE when several fit
    (UART0BASE -> UART). The rest stay in the blocks cfg_MASTER.asm
    already has: settings on consecutive lines, between comments or blank
    lines. Menus are flat, never one inside another.
    """
    enable_settings = {}
    for setting in master:
        name = setting["name"]
        if name.upper().endswith("ENABLE") and len(name) > len("ENABLE"):
            enable_settings[name[:-len("ENABLE")]] = setting

    menus = []            # [title, settings], in the order they start
    menu_of_base = {}     # BASE -> its entry in menus
    block = None          # the current block of settings without a BASE
    previous_line = None
    for setting in master:
        name = setting["name"]
        if enable_settings.get(name[:-len("ENABLE")]) is setting:
            base = name[:-len("ENABLE")]
        else:
            fitting_bases = [base for base in enable_settings
                             if name.startswith(base)]
            base = max(fitting_bases, key=len) if fitting_bases else None

        if base is not None:
            if base not in menu_of_base:
                enable_comment = enable_settings[base]["comment"]
                if re.match(r"[^:]{1,24}:", enable_comment):
                    # the comment has its own "PREFIX:" already, e.g.
                    # "FP: MASTER ENABLE ...", don't add a second one
                    title = enable_comment
                elif enable_comment:
                    title = f"{base}: {enable_comment}"
                else:
                    title = base
                menu_of_base[base] = [title, []]
                menus.append(menu_of_base[base])
            if setting is enable_settings[base]:
                menu_of_base[base][1].insert(0, setting)
            else:
                menu_of_base[base][1].append(setting)
        else:
            # tag lines below a setting don't break its block
            if block is None or setting["line"] != previous_line + 1:
                block = [None, []]
                menus.append(block)
            block[1].append(setting)
        previous_line = (setting["line"] + len(setting["depends"])
                         + len(setting["help"]) + len(setting["bad_tags"]))

    for menu in menus:
        if menu[0] is None:
            menu[0] = block_title(menu[1])
    return [(title, settings) for title, settings in menus]


def block_title(settings):
    """A menu title for a block of settings: the "PREFIX:" their comments
    all start with (like "SIO 0A: ..."), else the first and last name."""
    prefixes = set()
    for setting in settings:
        match = re.match(r"([^:]{1,24}):", setting["comment"])
        prefixes.add(match.group(1) if match else None)
    if len(prefixes) == 1 and None not in prefixes:
        return prefixes.pop()
    if len(settings) == 1:
        return settings[0]["name"]
    return f"{settings[0]['name']} .. {settings[-1]['name']}"


def help_lines(setting, inherited):
    """The Kconfig help block for a setting: its comment, its ;@HELP
    lines, the value it inherits and where from, and its ;@DEPENDS
    rules."""
    text = []
    if setting["comment"]:
        text.append(setting["comment"])
    text.extend(setting["help"])
    if text:
        text.append("")
    value, set_in = inherited[setting["name"]]
    text.append(f"Inherited: {value} (from {set_in})")
    text.extend(f"Needs: {expression}" for expression in setting["depends"])
    return ["\thelp"] + [f"\t  {line}" if line else "" for line in text]


def kconfig_entry(setting, board_value, inherited, constants):
    """The Kconfig lines for one setting, and its type.

    A pick list becomes a Kconfig "choice" named after the setting, with
    one bool per option called <SETTING>__<OPTION> (FD0TYPE and FD1TYPE
    both offer FDT_3HD, so the option names need the setting in front).
    """
    name = setting["name"]
    setting_kind, value_range = setting_type(
        setting["value"], board_value, setting["comment"], constants)
    prompt = f"{name}: {setting['comment']}" if setting["comment"] else name
    help_text = help_lines(setting, inherited)
    if setting_kind == "choice":
        options = value_range
        lines = [f"choice {name}",
                 f"\tprompt {quote(prompt)}",
                 f"\tdefault {name}__{board_value}"] + help_text + [""]
        for option in options:
            option_comment = constants[option][0]
            option_prompt = f"{option}: {option_comment}" if option_comment \
                else option
            lines.append(f"config {name}__{option}")
            lines.append(f"\tbool {quote(option_prompt)}")
            lines.append("")
        lines.append("endchoice")
        lines.append("")
        return lines, setting_kind
    lines = [f"config {name}",
             f"\t{setting_kind} {quote(prompt)}"]
    if value_range:
        lines.append(f"\trange {value_range[0]} {value_range[1]}")
    lines.append(f"\tdefault {kconfig_value(setting_kind, board_value)}")
    lines.extend(help_text)
    lines.append("")
    return lines, setting_kind


def make_kconfig(master, state, board_file, title):
    """A Kconfig file with one entry per cfg_MASTER setting, grouped into
    menus by group_settings(), with the config's value as the default."""
    constants = load_constants()
    inherited = inherited_values(board_file)
    entries = []
    for menu_title, settings in group_settings(master):
        entries.append(f"menu {quote(menu_title)}")
        entries.append("")
        for setting in settings:
            board_value = state["values"][setting["name"]][0]
            lines, _ = kconfig_entry(setting, board_value, inherited,
                                     constants)
            entries.extend(lines)
        entries.append("endmenu")
        entries.append("")
    return "\n".join([f"mainmenu {quote(title)}", ""] + entries)


def load_kconfig(master, state, board_file, title, temp_dir):
    """Write the Kconfig file into temp_dir and load it with Kconfiglib."""
    import kconfiglib

    kconfig_path = os.path.join(temp_dir, "Kconfig")
    with open(kconfig_path, "w", encoding="ascii") as kconfig_file:
        kconfig_file.write(make_kconfig(master, state, board_file, title))
    return kconfiglib.Kconfig(kconfig_path)


def inherited_values(board_file):
    """What a config would get without its own .SET lines: the values from
    the files it includes. board_file is relative to Source/HBIOS, e.g.
    Config/RCZ80_romp.asm. Returns name -> (value, file that set it)."""
    state = {"values": {}, "chain": [], "ignore_file": board_file}
    resolve(os.path.join(HBIOS, board_file), state)
    return state["values"]


def number_of(value):
    """The number a RomWBW value stands for ($40 or 64), or None when it
    is not a plain number (TRUE, PLT_RCZ80, CPUOSC/2, ...)."""
    if re.fullmatch(r"\$[0-9A-Fa-f]+", value):
        return int(value[1:], 16)
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    return None


def same_value(first_value, second_value):
    """True when two RomWBW values mean the same: $40, $040 and 64 are the
    same number, TRUE and true the same word."""
    first_number = number_of(first_value)
    second_number = number_of(second_value)
    if first_number is not None and second_number is not None:
        return first_number == second_number
    return first_value.upper() == second_value.upper()


def romwbw_value(setting_kind, kconfig_text, old_value):
    """The opposite of kconfig_value(): turn what menuconfig gives back
    into how RomWBW writes it. For hex, old_value sets the number of
    digits, so $0C stays $0C and does not become $C."""
    if setting_kind == "bool":
        return "TRUE" if kconfig_text == "y" else "FALSE"
    if setting_kind == "hex":
        digits = max(len(old_value) - 1, 1)
        return "$" + format(int(kconfig_text, 16), f"0{digits}X")
    return kconfig_text


def menu_value(loaded_kconfig, name):
    """A setting's current value in the menu, the way Kconfig has it
    ("y", "0x40", ...). For a pick list, the selected option: its symbol
    is <SETTING>__<OPTION>, so that is cut off the front."""
    if name in loaded_kconfig.named_choices:
        selected = loaded_kconfig.named_choices[name].selection
        return selected.name[len(name) + len("__"):]
    return loaded_kconfig.syms[name].str_value


def make_row_filter(master, state, loaded_kconfig):
    """A node_hidden() function for the patched menuconfig, which shows
    only the menus that matter for this config, those with a setting
    that is:
      - set by the std or config file (their files are in Config/)
      - in the menu of an ENABLE that is on right now
      - changed since the menu opened, so it doesn't vanish
    A menu that is shown shows all its settings. [A] (show-all) still
    shows everything; this only decides what is displayed.
    """
    import kconfiglib

    set_in_config_files = {name for name, (_, set_in)
                           in state["values"].items()
                           if set_in.startswith("Config" + os.sep)}
    enable_of = {}      # setting -> the ENABLE of the menu it is in
    for _, settings in group_settings(master):
        first_name = settings[0]["name"]
        if first_name.upper().endswith("ENABLE"):
            for setting in settings:
                enable_of[setting["name"]] = first_name
    start_value = {setting["name"]: menu_value(loaded_kconfig,
                                               setting["name"])
                   for setting in master}

    def setting_shown(name):
        enable = enable_of.get(name)
        return (name in set_in_config_files
                or (enable and loaded_kconfig.syms[enable].str_value == "y")
                or menu_value(loaded_kconfig, name) != start_value[name])

    def menu_shown(menu_node):
        child = menu_node.list
        while child:
            # a setting or a pick list, never an option inside one
            if setting_shown(child.item.name):
                return True
            child = child.next
        return False

    def node_hidden(node):
        # a setting, a pick list or one of its options: shown with the
        # menu it is in
        while node.item is not kconfiglib.MENU:
            node = node.parent
        return not menu_shown(node)

    return node_hidden


def make_row_marker(master, state, loaded_kconfig, board_file):
    """A node_on() function for the patched menuconfig, which colors a
    row green when its value differs from what the config inherits from
    the files above it (<plt>_std, cfg_<plt>, cfg_MASTER). It follows
    edits in the menu: change a value and it turns green, set it back and
    it turns plain again.
      - a setting: its current value differs from the inherited one
      - a pick list: the list and its selected option, same rule
      - a menu: something inside it is green, shown or not
    """
    import kconfiglib

    inherited = inherited_values(board_file)
    constants = load_constants()
    setting_kind = {}
    for setting in master:
        name = setting["name"]
        kind, _ = setting_type(setting["value"], state["values"][name][0],
                               setting["comment"], constants)
        setting_kind[name] = kind

    def differs(name):
        base_value = inherited[name][0]
        kconfig_text = menu_value(loaded_kconfig, name)
        current_value = romwbw_value(setting_kind[name], kconfig_text,
                                     base_value)
        return not same_value(base_value, current_value)

    def node_on(node):
        item = node.item
        if item is kconfiglib.MENU:
            child = node.list
            while child:
                if node_on(child):
                    return True
                child = child.next
            return False
        if isinstance(item, kconfiglib.Choice):
            return differs(item.name)
        if isinstance(item, kconfiglib.Symbol):
            if item.choice is not None:
                # an option inside a pick list: only the selected one
                return (item.choice.selection is item
                        and differs(item.choice.name))
            return differs(item.name)
        return False

    return node_on


def terminal_colors():
    """How many colors the terminal says it has, 0 if unknown."""
    try:
        import curses
        curses.setupterm()
        return max(curses.tigetnum("colors"), 0)
    except Exception:
        return 0


def board_changes(master, state, loaded_kconfig, board_file):
    """Compare the menu's values with the config's.

    Returns a list of (name, action, old value, new value). action is:
      "change": the config file sets it already, its value changes
      "add":    the config file does not set it yet, a .SET line is needed
      "remove": the new value is what the config inherits anyway, so its
                own .SET line is not needed any more
    """
    inherited = inherited_values(board_file)
    constants = load_constants()
    changes = []
    for setting in master:
        name = setting["name"]
        old_value, set_in = state["values"][name]
        setting_kind, _ = setting_type(setting["value"], old_value,
                                       setting["comment"], constants)
        kconfig_text = menu_value(loaded_kconfig, name)
        new_value = romwbw_value(setting_kind, kconfig_text, old_value)
        if same_value(old_value, new_value):
            continue
        if same_value(inherited[name][0], new_value):
            action = "remove"
        elif set_in == board_file:
            action = "change"
        else:
            action = "add"
        changes.append((name, action, old_value, new_value))
    return changes


def kconfig_expression(expression, loaded_kconfig):
    """Turn a ;@DEPENDS expression written in RomWBW terms into one
    Kconfig can evaluate:
      CPUFAM = CPU_Z280   ->  CPUFAM__CPU_Z280      (a pick list)
      CPUFAM != CPU_Z280  ->  !CPUFAM__CPU_Z280
      VDAEMU_SERKBD = $FF ->  VDAEMU_SERKBD = 0xFF  (hex)
      AUTOCON = TRUE      ->  AUTOCON = y           (bool)
    &&, ||, !, ( ) and the comparisons < <= > >= work as in Kconfig.
    Raises ValueError for a name that is not a setting.
    """
    import kconfiglib

    def one_comparison(match):
        name, operator, value = match.group(1), match.group(2), match.group(3)
        if name in loaded_kconfig.named_choices:
            if operator not in ("=", "!="):
                raise ValueError(f"{name} is a pick list, only = and != "
                                 f"work on it")
            option = f"{name}__{value}"
            if option not in loaded_kconfig.syms:
                raise ValueError(f"{value} is not an option of {name}")
            return option if operator == "=" else "!" + option
        symbol = loaded_kconfig.syms.get(name)
        if symbol is not None and symbol.orig_type == kconfiglib.STRING:
            # e.g. a pick list that is plain text for this config
            return f'{name} {operator} "{value}"'
        if value.startswith("$"):
            value = "0x" + value[1:]
        elif value.upper() in ("TRUE", "FALSE"):
            value = "y" if value.upper() == "TRUE" else "n"
        return f"{name} {operator} {value}"

    translated = re.sub(r"(\w+)\s*(<=|>=|!=|=|<|>)\s*(\$?\w+)",
                        one_comparison, expression)
    # every name left outside "..." must be a setting
    for word in re.findall(r"\b[A-Za-z_]\w*\b",
                           re.sub(r'"[^"]*"', "", translated)):
        if word not in loaded_kconfig.syms or \
                not loaded_kconfig.syms[word].nodes:
            if word not in ("y", "n") and not word.startswith("0x"):
                raise ValueError(f"unknown setting {word}")
    return translated


def dependency_problems(master, loaded_kconfig):
    """Check every ;@DEPENDS against the values in the menu. On a bool
    setting it only counts when that setting is TRUE; on any other
    setting it must always hold. Bad tags are problems too. Returns a
    list of messages, empty when everything is fine."""
    import kconfiglib

    problems = []
    for setting in master:
        problems.extend(setting["bad_tags"])
        name = setting["name"]
        symbol = loaded_kconfig.syms.get(name)
        if symbol is not None and symbol.nodes and \
                symbol.orig_type == kconfiglib.BOOL and \
                symbol.str_value == "n":
            continue
        for expression in setting["depends"]:
            try:
                translated = kconfig_expression(expression, loaded_kconfig)
            except ValueError as error:
                problems.append(f"{name}: bad ;@DEPENDS {expression!r}: "
                                f"{error}")
                continue
            if loaded_kconfig.eval_string(translated) != 2:
                # the value the way RomWBW writes it: TRUE, $02, DL_ERROR
                shown_value = menu_value(loaded_kconfig, name)
                if symbol is not None and symbol.nodes and \
                        symbol.orig_type == kconfiglib.BOOL:
                    shown_value = "TRUE" if shown_value == "y" else "FALSE"
                elif symbol is not None and symbol.nodes and \
                        symbol.orig_type == kconfiglib.HEX:
                    shown_value = "$" + shown_value[2:].upper()
                problems.append(f"{name} = {shown_value} needs {expression}")
    return problems


def check_board(platform, config):
    """-check: check a config's current values against every ;@DEPENDS,
    without opening the menu. Exits with status 1 on problems."""
    master, state, board_file = load_board(platform, config)
    with tempfile.TemporaryDirectory() as temp_dir:
        loaded_kconfig = load_kconfig(master, state, board_file, "check",
                                      temp_dir)
    problems = dependency_problems(master, loaded_kconfig)
    for problem in problems:
        print(f"{platform}_{config}: {problem}")
    if problems:
        sys.exit(1)
    print(f"{platform}_{config}: dependencies OK")


def import_menuconfig():
    """Import menuconfig, which needs curses. The Python that Config.cmd
    installs in Tools\\python on Windows has it, see install-python.ps1."""
    try:
        import curses
    except ImportError:
        if os.name == "nt":
            sys.exit("hbconfig: this Python has no curses module, run "
                     "Config -install to get the one hbconfig needs")
        sys.exit("hbconfig: this Python has no curses module, the menu "
                 "needs it")
    import menuconfig
    return menuconfig


def menu_and_write(platform, config):
    """Open menuconfig on the config and afterwards write what was saved
    into the config file. Returns True when the file was written.

    menuconfig itself runs in a temporary directory that is deleted
    afterwards; only write_board() touches the config file.
    """
    menuconfig = import_menuconfig()

    master, state, board_file = load_board(platform, config)
    title = (f"hbconfig {platform}_{config}, written with Claude (AI). "
             f"Save writes {board_file}, [A] shows all")
    with tempfile.TemporaryDirectory() as temp_dir:
        loaded_kconfig = load_kconfig(master, state, board_file, title,
                                      temp_dir)

        # menuconfig saves to $KCONFIG_CONFIG, and "defconfig" to the
        # current directory: point both into the temporary directory.
        os.environ["KCONFIG_CONFIG"] = os.path.join(temp_dir, ".config")
        # a .config with the config's values, else menuconfig marks every
        # setting "(NEW)"
        loaded_kconfig.write_config(os.environ["KCONFIG_CONFIG"],
                                    header="")
        menuconfig.node_hidden = make_row_filter(master, state,
                                                 loaded_kconfig)
        menuconfig.node_on = make_row_marker(master, state,
                                             loaded_kconfig, board_file)
        style = os.environ.get("MENUCONFIG_STYLE", "")
        if "on-list" not in style and terminal_colors() < 256:
            # with 8 colors the nearest to the pale green is white, the
            # normal row color, so use plain green instead
            os.environ["MENUCONFIG_STYLE"] = (
                style + " on-list=fg:black,bg:green").strip()
        start_dir = os.getcwd()
        os.chdir(temp_dir)
        try:
            while True:
                try:
                    menuconfig.menuconfig(loaded_kconfig)
                finally:
                    # the pale green is a changed palette entry, and
                    # curses doesn't put it back on exit (OSC 104 resets
                    # the palette)
                    if sys.stdout.isatty():
                        sys.stdout.write("\033]104\007")
                        sys.stdout.flush()
                # read back what was saved; quitting without saving leaves
                # the .config as it was, so then there are no changes
                loaded_kconfig.load_config(os.environ["KCONFIG_CONFIG"])

                # never write a config that breaks a ;@DEPENDS
                problems = dependency_problems(master, loaded_kconfig)
                if not problems:
                    break
                print(f"Not written to {board_file}, these settings "
                      f"conflict:")
                for problem in problems:
                    print(f"  {problem}")
                answer = input("Back to the menu to fix them? [Y/n] ")
                if answer.strip().lower().startswith("n"):
                    print(f"Nothing written to {board_file}.")
                    return False
        finally:
            os.chdir(start_dir)

        changes = board_changes(master, state, loaded_kconfig, board_file)

    if not changes:
        print(f"No changes for {board_file}.")
        return False
    write_board(board_file, changes, master)
    print(f"Changed {board_file}:")
    name_width = max(len(name) for name, _, _, _ in changes)
    for name, action, old_value, new_value in changes:
        print(f"  {action:<6}  {name:<{name_width}}  "
              f"{old_value} -> {new_value}")
    return True


def config_names(platform):
    """The configs of a platform, without the platform and .asm:
    Config/RCZ80_kio_std.asm -> kio_std."""
    prefix = platform + "_"
    return sorted(file_name[len(prefix):-len(".asm")]
                  for file_name in os.listdir(os.path.join(HBIOS, "Config"))
                  if file_name.startswith(prefix)
                  and file_name.endswith(".asm"))


def std_configs(platform):
    """The official builds a new config can inherit from:
    Config/<platform>_std.asm first, then Config/<platform>_*_std.asm.
    Returns names without .asm, e.g. RCZ80_std, RCZ80_kio_std."""
    names = [f"{platform}_{name}" for name in config_names(platform)
             if name == "std" or name.endswith("_std")]
    main_std = f"{platform}_std"
    if main_std in names:
        names.remove(main_std)
        names.insert(0, main_std)
    return names


def includes_master(platform):
    """True when cfg_<platform>.asm includes cfg_MASTER.asm (UNA doesn't,
    its settings come from UBIOS)."""
    path = os.path.join(HBIOS, f"cfg_{platform}.asm")
    for _, text in read_lines(path):
        match = INCLUDE_RE.match(text)
        if match and match.group(1).lower() == "cfg_master.asm":
            return True
    return False


def known_platforms():
    """Every platform with a cfg_<platform>.asm that includes
    cfg_MASTER.asm, and at least one std config to build from."""
    names = sorted(file_name[len("cfg_"):-len(".asm")]
                   for file_name in os.listdir(HBIOS)
                   if file_name.startswith("cfg_")
                   and file_name.endswith(".asm"))
    return [name for name in names
            if std_configs(name) and includes_master(name)]


def config_title(config_name):
    """What a config file says it is for, from its header line
    "ROMWBW DEFAULT BUILD SETTINGS FOR RCBUS Z80" -> "RCBUS Z80"."""
    path = os.path.join(HBIOS, "Config", config_name + ".asm")
    with open(path, "rb") as file:
        for raw in file:
            text = raw.decode("ascii", "replace")
            match = re.search(r"BUILD SETTINGS FOR (.+)", text)
            if match:
                return match.group(1).strip()
    return ""


def pick(prompt, choices, allow_new=False):
    """Print a numbered list of (name, text) and return the name picked
    by number, the first one on a plain Enter. With allow_new, a name
    typed in (letters, digits and _) is returned as well."""
    width = max(len(name) for name, _ in choices)
    for number, (name, text) in enumerate(choices, start=1):
        print(f"  {number:2}  {name:<{width}}  {text}")
    while True:
        answer = input(prompt).strip() or "1"
        if answer.isdigit() and 1 <= int(answer) <= len(choices):
            return choices[int(answer) - 1][0]
        if allow_new and re.fullmatch(r"\w+", answer):
            return answer
        print(f"Pick a number from 1 to {len(choices)}"
              f"{' or type a new name' if allow_new else ''}.")


def ask_platform():
    """Ask for the platform, from the list of known ones."""
    print("Platform:")
    return pick("Number [1]: ",
                [(name, config_title(std_configs(name)[0]))
                 for name in known_platforms()])


def ask_config(platform):
    """Ask for one of the platform's configs, or a new name."""
    print(f"{platform} config:")
    return pick("Number [1], or a new name: ",
                [(name, config_title(f"{platform}_{name}"))
                 for name in config_names(platform)],
                allow_new=True)


def new_config(platform, config):
    """Offer to create Config/<platform>_<config>.asm, asking which std
    it inherits from. The file is the text of new_config.asm with <TITLE>
    and <PARENT> filled in, with the std's line endings. Returns True when
    the file was created."""
    board_file = config_file(platform, config)
    if not re.fullmatch(r"\w+", config):
        sys.exit(f"hbconfig: bad config name {config!r}, "
                 f"use letters, digits and _ only")

    answer = input(f"{board_file} does not exist. Create it? [y/N] ")
    if not answer.strip().lower().startswith("y"):
        return False
    print("Inherit from:")
    parent = pick("Number [1]: ", [(name, config_title(name))
                                   for name in std_configs(platform)])

    with open(NEW_CONFIG_TEMPLATE, "rb") as file:
        text = file.read().decode("ascii")
    text = text.replace("<TITLE>", config_title(parent) or parent)
    text = text.replace("<PARENT>", parent)
    with open(os.path.join(HBIOS, "Config", parent + ".asm"), "rb") as file:
        newline = "\r\n" if b"\r\n" in file.read() else "\n"
    text = newline.join(text.splitlines()) + newline
    with open(os.path.join(HBIOS, board_file), "x", newline="") as file:
        file.write(text)
    return True


def show_menu(platform, config):
    """The menu: menu_and_write(), and a config that does not exist is
    created first when asked. When nothing gets saved in the menu, it is
    removed again unless the answer to "Keep it?" is yes."""
    board_file = config_file(platform, config)
    created = False
    if not os.path.isfile(os.path.join(HBIOS, board_file)):
        if not new_config(platform, config):
            print("Nothing created.")
            return
        created = True
        # a closed terminal or a kill should still remove the new file:
        # turn those signals into SystemExit so the "finally" below runs
        for signal_name in ("SIGHUP", "SIGTERM"):
            if hasattr(signal, signal_name):
                signal.signal(getattr(signal, signal_name),
                              lambda number, frame: sys.exit(1))
    keep = False
    try:
        keep = menu_and_write(platform, config)
        if created and not keep:
            # nothing saved: the new file only holds the header and the
            # #INCLUDE of its std, which can still be what was wanted
            answer = input(f"{board_file} has no settings of its own yet. "
                           f"Keep it? [y/N] ")
            keep = answer.strip().lower().startswith("y")
    finally:
        if created and not keep:
            os.remove(os.path.join(HBIOS, board_file))
            print(f"Nothing saved, {board_file} not created.")


def tabs_to(text, column):
    """The tabs (8 wide) that take text on to the given column, or a
    single space when the text already reaches it."""
    width = len(text.expandtabs(8))
    if width >= column:
        return " "
    return "\t" * ((column - width + 7) // 8)


def set_line(name, value, comment):
    """A new .SET line laid out like the ones in the config files:
    NAME at column 0, .SET at 16, the value at 24, the comment at 40."""
    line = name + tabs_to(name, 16) + ".SET\t" + value
    if comment:
        line += tabs_to(line, 40) + "; " + comment
    return line


def write_board(board_file, changes, master):
    """Write the changes into the config file.

    change: the value in the file's last .SET line for it is replaced,
            the rest of the line (spaces and tabs, comment) stays as it was
    remove: every .SET line for it goes, with the indented "; ..." lines
            right below it that continue its comment
    add:    a new .SET line at the end of the file, with the comment from
            cfg_MASTER.asm

    The file keeps its own line endings (CRLF or LF). Only plain ASCII is
    written.
    """
    for name, _, _, new_value in changes:
        if not new_value.isascii():
            raise ValueError(f"{name}: new value {new_value!r} is not "
                             f"plain ASCII, nothing written")

    path = os.path.join(HBIOS, board_file)
    with open(path, "rb") as file:
        data = file.read()
    newline = "\r\n" if b"\r\n" in data else "\n"
    lines = data.decode("ascii").splitlines()

    comments = {setting["name"]: setting["comment"] for setting in master}
    for name, action, _, new_value in changes:
        # where the config file sets this name, first to last
        line_numbers = []
        for index, line in enumerate(lines):
            match = SETTING_RE.match(line)
            if match and match.group(1) == name:
                line_numbers.append(index)

        if action == "change":
            last = line_numbers[-1]
            match = SETTING_RE.match(lines[last])
            start, end = match.span(2)
            lines[last] = lines[last][:start] + new_value + lines[last][end:]
        elif action == "remove":
            # from the bottom up, so the earlier line numbers stay right
            for index in reversed(line_numbers):
                following = index + 1
                while following < len(lines) and \
                        re.match(r"^\s+;", lines[following]):
                    following += 1
                del lines[index:following]
        else:
            lines.append(set_line(name, new_value, comments[name]))

    # write a new file next to the old one, then swap them, so a failure
    # halfway never leaves a half-written config file
    temp_path = path + ".new"
    with open(temp_path, "wb") as file:
        file.write((newline.join(lines) + newline).encode("ascii"))
    shutil.copymode(path, temp_path)
    os.replace(temp_path, path)


def main():
    parser = argparse.ArgumentParser(
        prog="hbconfig",
        description="Menu-driven editor for RomWBW board configs.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-show", action="store_true",
                       help="print the settings the config ends up with "
                            "that differ from cfg_MASTER.asm")
    group.add_argument("-check", action="store_true",
                       help="check the config against every ;@DEPENDS in "
                            "cfg_MASTER.asm")
    parser.add_argument("platform", nargs="?", help="e.g. RCZ80")
    parser.add_argument("config", nargs="?", help="e.g. std")
    args = parser.parse_args()

    print(BANNER)
    # no __pycache__ directory left behind in Tools/hbconfig
    sys.dont_write_bytecode = True
    try:
        platform = args.platform or ask_platform()
        if platform not in known_platforms():
            sys.exit(f"hbconfig: unknown platform {platform}, known: "
                     f"{' '.join(known_platforms())}")
        config = args.config or ask_config(platform)
        if args.show:
            show_board(platform, config)
        elif args.check:
            check_board(platform, config)
        else:
            show_menu(platform, config)
    except (EOFError, KeyboardInterrupt):
        sys.exit("\nhbconfig: stopped")
    except OSError as e:
        sys.exit(f"hbconfig: cannot read {e.filename}: {e.strerror}")
    except ValueError as e:
        sys.exit(f"hbconfig: {e}")


if __name__ == "__main__":
    main()
