//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// SymbolEngine.cpp
//

#include "PropellerCompilerInternal.h"
#include "SymbolEngine.h"
#include "ErrorStrings.h"
#include "Utilities.h"
#include <string.h>

static SymbolTableEntryDataTable symbols[] =
{
    {type_left,             0,                  "(",            0,                  false}, //miscellaneous
    {type_right,            0,                  ")",            0,                  false},
    {type_leftb,            0,                  "[",            0,                  false},
    {type_rightb,           0,                  "]",            0,                  false},
    {type_comma,            0,                  ",",            0,                  false},
    {type_equal,            0,                  "=",            0,                  false},
    {type_pound,            0,                  "#",            0,                  false},
    {type_colon,            0,                  ":",            0,                  false},
    {type_back,             0,                  "\\",           0,                  false},
    {type_dot,              0,                  ".",            0,                  false},
    {type_dotdot,           0,                  "..",           0,                  false},
    {type_at,               0,                  "@",            0,                  false},
    {type_atat,             0,                  "@@",           0,                  false},
    {type_til,              0,                  "~",            0,                  false},
    {type_tiltil,           0,                  "~~",           0,                  false},
    {type_rnd,              0,                  "?",            0,                  false},
    {type_inc,              0,                  "++",           0,                  false},
    {type_dec,              0,                  "--",           0,                  false},
    {type_assign,           0,                  ":=",           0,                  false},
    {type_spr,              0,                  "SPR",          0,                  false},

    {type_binary,           1,                  "->",           op_ror,             false}, // math operators
    {type_binary,           1,                  "<-",           op_rol,             false},
    {type_binary,           1,                  ">>",           op_shr,             false},
    {type_binary,           1,                  "<<",           op_shl,             false},
    {type_binary,           6,                  "#>",           op_min,             false},
    {type_binary,           6,                  "<#",           op_max,             false},
//  {type_unary,            0,                  "-",            op_neg,             false}, // (uses op_sub symbol)
    {type_unary,            0,                  "!",            op_not,             false},
    {type_binary,           2,                  "&",            op_and,             false},
    {type_unary,            0,                  "||",           op_abs,             false},
    {type_binary,           3,                  "|",            op_or,              false},
    {type_binary,           3,                  "^",            op_xor,             false},
    {type_binary,           5,                  "+",            op_add,             false},
    {type_binary,           5,                  "-",            op_sub,             false},
    {type_binary,           1,                  "~>",           op_sar,             false},
    {type_binary,           1,                  "><",           op_rev,             false},
    {type_binary,           9,                  "AND",          op_log_and,         false},
    {type_unary,            0,                  ">|",           op_ncd,             false},
    {type_binary,           10,                 "OR",           op_log_or,          false},
    {type_unary,            0,                  "|<",           op_dcd,             false},
    {type_binary,           4,                  "*",            op_mul,             false},
    {type_binary,           4,                  "**",           op_scl,             false},
    {type_binary,           4,                  "/",            op_div,             false},
    {type_binary,           4,                  "//",           op_rem,             false},
    {type_unary,            0,                  "^^",           op_sqr,             false},
    {type_binary,           7,                  "<",            op_cmp_b,           false},
    {type_binary,           7,                  ">",            op_cmp_a,           false},
    {type_binary,           7,                  "<>",           op_cmp_ne,          false},
    {type_binary,           7,                  "==",           op_cmp_e,           false},
    {type_binary,           7,                  "=<",           op_cmp_be,          false},
    {type_binary,           7,                  "=>",           op_cmp_ae,          false},
    {type_unary,            8,                  "NOT",          op_log_not,         false},

    {type_float,            0,                  "FLOAT",        0,                  false}, //floating-point operators
    {type_round,            0,                  "ROUND",        0,                  false},
    {type_trunc,            0,                  "TRUNC",        0,                  false},

    {type_conexp,           0,                  "CONSTANT",     0,                  false}, //constant and string expressions
    {type_constr,           0,                  "STRING",       0,                  false},

    {type_block,            block_con,          "CON",          0,                  false}, //block designators
    {type_block,            block_var,          "VAR",          0,                  false},
    {type_block,            block_dat,          "DAT",          0,                  false},
    {type_block,            block_obj,          "OBJ",          0,                  false},
    {type_block,            block_pub,          "PUB",          0,                  false},
    {type_block,            block_pri,          "PRI",          0,                  false},
    {type_block,            block_dev,          "DEV",          0,                  false},

    {type_size,             0,                  "BYTE",         0,                  false}, //sizes
    {type_size,             1,                  "WORD",         0,                  false},
    {type_size,             2,                  "LONG",         0,                  false},

    {type_precompile,       0,                  "PRECOMPILE",   0,                  false}, //file-related
    {type_archive,          0,                  "ARCHIVE",      0,                  false},
    {type_file,             0,                  "FILE",         0,                  false},

    {type_if,               0,                  "IF",           0,                  false}, //high-level structures
    {type_ifnot,            0,                  "IFNOT",        0,                  false},
    {type_elseif,           0,                  "ELSEIF",       0,                  false},
    {type_elseifnot,        0,                  "ELSEIFNOT",    0,                  false},
    {type_else,             0,                  "ELSE",         0,                  false},
    {type_case,             0,                  "CASE",         0,                  false},
    {type_other,            0,                  "OTHER",        0,                  false},
    {type_repeat,           0,                  "REPEAT",       0,                  false},
    {type_while,            0,                  "WHILE",        0,                  false},
    {type_until,            0,                  "UNTIL",        0,                  false},
    {type_from,             0,                  "FROM",         0,                  false},
    {type_to,               0,                  "TO",           0,                  false},
    {type_step,             0,                  "STEP",         0,                  false},

    {type_i_next_quit,      0,                  "NEXT",         0,                  false}, //high-level instructions
    {type_i_next_quit,      1,                  "QUIT",         0,                  false},
    {type_i_abort_return,   0x30,               "ABORT",        0,                  false},
    {type_i_abort_return,   0x32,               "RETURN",       0,                  false},
    {type_i_look,           0x10,               "LOOKUP",       0,                  false},
    {type_i_look,           0x10 + 0x80,        "LOOKUPZ",      0,                  false},
    {type_i_look,           0x11,               "LOOKDOWN",     0,                  false},
    {type_i_look,           0x11 + 0x80,        "LOOKDOWNZ",    0,                  false},
    {type_i_clkmode,        0,                  "CLKMODE",      0,                  false},
    {type_i_clkfreq,        0,                  "CLKFREQ",      0,                  false},
    {type_i_chipver,        0,                  "CHIPVER",      0,                  false},
    {type_i_reboot,         0,                  "REBOOT",       0,                  false},
    {type_i_cognew,         0x28 + (2 * 0x40),  "COGNEW",       0,                  false},
    {type_i_ar,             0x16 + (1 * 0x40),  "STRSIZE",      0,                  false},
    {type_i_ar,             0x17 + (2 * 0x40),  "STRCOMP",      0,                  false},
    {type_i_nr,             0x18 + (3 * 0x40),  "BYTEFILL",     0,                  false},
    {type_i_nr,             0x19 + (3 * 0x40),  "WORDFILL",     0,                  false},
    {type_i_nr,             0x1A + (3 * 0x40),  "LONGFILL",     0,                  false},
    {type_i_nr,             0x1C + (3 * 0x40),  "BYTEMOVE",     0,                  false},
    {type_i_nr,             0x1D + (3 * 0x40),  "WORDMOVE",     0,                  false},
    {type_i_nr,             0x1E + (3 * 0x40),  "LONGMOVE",     0,                  false},

    {type_i_nr,             0x1B + (3 * 0x40),  "WAITPEQ",      0x3C,               true},  // dual mode instructions (spin and asm)
    {type_i_nr,             0x1F + (3 * 0x40),  "WAITPNE",      0x3D,               true},
    {type_i_nr,             0x23 + (1 * 0x40),  "WAITCNT",      0x3E + 0x40,        true},
    {type_i_nr,             0x27 + (2 * 0x40),  "WAITVID",      0x3F,               true},
    {type_i_nr,             0x20 + (2 * 0x40),  "CLKSET",       0 + 0x80,           true},
    {type_i_cogid,          0,                  "COGID",        1 + 0x80 + 0x40,    true},
    {type_i_coginit,        0x2C + (3 * 0x40),  "COGINIT",      2 + 0x80,           true},
    {type_i_nr,             0x21 + (1 * 0x40),  "COGSTOP",      3 + 0x80,           true},
    {type_i_cr,             0x29 + (0 * 0x40),  "LOCKNEW",      4 + 0x80 + 0x40,    true},
    {type_i_nr,             0x22 + (1 * 0x40),  "LOCKRET",      5 + 0x80,           true},
    {type_i_cr,             0x2A + (1 * 0x40),  "LOCKSET",      6 + 0x80,           true},
    {type_i_cr,             0x2B + (1 * 0x40),  "LOCKCLR",      7 + 0x80,           true},

    {type_asm_dir,          dir_orgx,           "ORGX",         0,                  false}, //assembly directives
    {type_asm_dir,          dir_org,            "ORG",          0,                  false},
    {type_asm_dir,          dir_res,            "RES",          0,                  false},
    {type_asm_dir,          dir_fit,            "FIT",          0,                  false},
    {type_asm_dir,          dir_nop,            "NOP",          0,                  false},

    {type_asm_cond,         if_nc_and_nz,       "IF_NC_AND_NZ", 0,                  false}, //assembly conditionals
    {type_asm_cond,         if_nc_and_nz,       "IF_NZ_AND_NC", 0,                  false},
    {type_asm_cond,         if_nc_and_nz,       "IF_A",         0,                  false},
    {type_asm_cond,         if_nc_and_z,        "IF_NC_AND_Z",  0,                  false},
    {type_asm_cond,         if_nc_and_z,        "IF_Z_AND_NC",  0,                  false},
    {type_asm_cond,         if_nc,              "IF_NC",        0,                  false},
    {type_asm_cond,         if_nc,              "IF_AE",        0,                  false},
    {type_asm_cond,         if_c_and_nz,        "IF_C_AND_NZ",  0,                  false},
    {type_asm_cond,         if_c_and_nz,        "IF_NZ_AND_C",  0,                  false},
    {type_asm_cond,         if_nz,              "IF_NZ",        0,                  false},
    {type_asm_cond,         if_nz,              "IF_NE",        0,                  false},
    {type_asm_cond,         if_c_ne_z,          "IF_C_NE_Z",    0,                  false},
    {type_asm_cond,         if_c_ne_z,          "IF_Z_NE_C",    0,                  false},
    {type_asm_cond,         if_nc_or_nz,        "IF_NC_OR_NZ",  0,                  false},
    {type_asm_cond,         if_nc_or_nz,        "IF_NZ_OR_NC",  0,                  false},
    {type_asm_cond,         if_c_and_z,         "IF_C_AND_Z",   0,                  false},
    {type_asm_cond,         if_c_and_z,         "IF_Z_AND_C",   0,                  false},
    {type_asm_cond,         if_c_eq_z,          "IF_C_EQ_Z",    0,                  false},
    {type_asm_cond,         if_c_eq_z,          "IF_Z_EQ_C",    0,                  false},
    {type_asm_cond,         if_z,               "IF_Z",         0,                  false},
    {type_asm_cond,         if_z,               "IF_E",         0,                  false},
    {type_asm_cond,         if_nc_or_z,         "IF_NC_OR_Z",   0,                  false},
    {type_asm_cond,         if_nc_or_z,         "IF_Z_OR_NC",   0,                  false},
    {type_asm_cond,         if_c,               "IF_C",         0,                  false},
    {type_asm_cond,         if_c,               "IF_B",         0,                  false},
    {type_asm_cond,         if_c_or_nz,         "IF_C_OR_NZ",   0,                  false},
    {type_asm_cond,         if_c_or_nz,         "IF_NZ_OR_C",   0,                  false},
    {type_asm_cond,         if_c_or_z,          "IF_C_OR_Z",    0,                  false},
    {type_asm_cond,         if_c_or_z,          "IF_Z_OR_C",    0,                  false},
    {type_asm_cond,         if_c_or_z,          "IF_BE",        0,                  false},
    {type_asm_cond,         if_always,          "IF_ALWAYS",    0,                  false},
    {type_asm_cond,         if_never,           "IF_NEVER",     0,                  false},

    {type_asm_inst,         0,                  "WRBYTE",       0,                  false}, //assembly instructions
    {type_asm_inst,         0x00 + 0x40,        "RDBYTE",       0,                  false},
    {type_asm_inst,         0x01,               "WRWORD",       0,                  false},
    {type_asm_inst,         0x01 + 0x40,        "RDWORD",       0,                  false},
    {type_asm_inst,         0x02,               "WRLONG",       0,                  false},
    {type_asm_inst,         0x02 + 0x40,        "RDLONG",       0,                  false},
    {type_asm_inst,         0x03,               "HUBOP",        0,                  false},
    {type_asm_inst,         0x04 + 0x40,        "MUL",          0,                  false},
    {type_asm_inst,         0x05 + 0x40,        "MULS",         0,                  false},
    {type_asm_inst,         0x06 + 0x40,        "ENC",          0,                  false},
    {type_asm_inst,         0x07 + 0x40,        "ONES",         0,                  false},
    {type_asm_inst,         0x08 + 0x40,        "ROR",          0,                  false},
    {type_asm_inst,         0x09 + 0x40,        "ROL",          0,                  false},
    {type_asm_inst,         0x0A + 0x40,        "SHR",          0,                  false},
    {type_asm_inst,         0x0B + 0x40,        "SHL",          0,                  false},
    {type_asm_inst,         0x0C + 0x40,        "RCR",          0,                  false},
    {type_asm_inst,         0x0D + 0x40,        "RCL",          0,                  false},
    {type_asm_inst,         0x0E + 0x40,        "SAR",          0,                  false},
    {type_asm_inst,         0x0F + 0x40,        "REV",          0,                  false},
    {type_asm_inst,         0x10 + 0x40,        "MINS",         0,                  false},
    {type_asm_inst,         0x11 + 0x40,        "MAXS",         0,                  false},
    {type_asm_inst,         0x12 + 0x40,        "MIN",          0,                  false},
    {type_asm_inst,         0x13 + 0x40,        "MAX",          0,                  false},
    {type_asm_inst,         0x14 + 0x40,        "MOVS",         0,                  false},
    {type_asm_inst,         0x15 + 0x40,        "MOVD",         0,                  false},
    {type_asm_inst,         0x16 + 0x40,        "MOVI",         0,                  false},
    {type_asm_inst,         0x17 + 0x40,        "JMPRET",       0,                  false},
//  {type_asm_inst,         0x18 + 0x40,        "AND",          0,                  false}, //({type_binary_bool)
    {type_asm_inst,         0x19 + 0x40,        "ANDN",         0,                  false},
//  {type_asm_inst,         0x1A + 0x40,        "OR",           0,                  false}, //({type_binary_bool)
    {type_asm_inst,         0x1B + 0x40,        "XOR",          0,                  false},
    {type_asm_inst,         0x1C + 0x40,        "MUXC",         0,                  false},
    {type_asm_inst,         0x1D + 0x40,        "MUXNC",        0,                  false},
    {type_asm_inst,         0x1E + 0x40,        "MUXZ",         0,                  false},
    {type_asm_inst,         0x1F + 0x40,        "MUXNZ",        0,                  false},
    {type_asm_inst,         0x20 + 0x40,        "ADD",          0,                  false},
    {type_asm_inst,         0x21 + 0x40,        "SUB",          0,                  false},
    {type_asm_inst,         0x22 + 0x40,        "ADDABS",       0,                  false},
    {type_asm_inst,         0x23 + 0x40,        "SUBABS",       0,                  false},
    {type_asm_inst,         0x24 + 0x40,        "SUMC",         0,                  false},
    {type_asm_inst,         0x25 + 0x40,        "SUMNC",        0,                  false},
    {type_asm_inst,         0x26 + 0x40,        "SUMZ",         0,                  false},
    {type_asm_inst,         0x27 + 0x40,        "SUMNZ",        0,                  false},
    {type_asm_inst,         0x28 + 0x40,        "MOV",          0,                  false},
    {type_asm_inst,         0x29 + 0x40,        "NEG",          0,                  false},
    {type_asm_inst,         0x2A + 0x40,        "ABS",          0,                  false},
    {type_asm_inst,         0x2B + 0x40,        "ABSNEG",       0,                  false},
    {type_asm_inst,         0x2C + 0x40,        "NEGC",         0,                  false},
    {type_asm_inst,         0x2D + 0x40,        "NEGNC",        0,                  false},
    {type_asm_inst,         0x2E + 0x40,        "NEGZ",         0,                  false},
    {type_asm_inst,         0x2F + 0x40,        "NEGNZ",        0,                  false},
    {type_asm_inst,         0x30,               "CMPS",         0,                  false},
    {type_asm_inst,         0x31,               "CMPSX",        0,                  false},
    {type_asm_inst,         0x32 + 0x40,        "ADDX",         0,                  false},
    {type_asm_inst,         0x33 + 0x40,        "SUBX",         0,                  false},
    {type_asm_inst,         0x34 + 0x40,        "ADDS",         0,                  false},
    {type_asm_inst,         0x35 + 0x40,        "SUBS",         0,                  false},
    {type_asm_inst,         0x36 + 0x40,        "ADDSX",        0,                  false},
    {type_asm_inst,         0x37 + 0x40,        "SUBSX",        0,                  false},
    {type_asm_inst,         0x38 + 0x40,        "CMPSUB",       0,                  false},
    {type_asm_inst,         0x39 + 0x40,        "DJNZ",         0,                  false},
    {type_asm_inst,         0x3A,               "TJNZ",         0,                  false},
    {type_asm_inst,         0x3B,               "TJZ",          0,                  false},
    {type_asm_inst,         0x15,               "CALL",         0,                  false}, //converts to 17h (jmpret symbol_ret,#symbol)
    {type_asm_inst,         0x16,               "RET",          0,                  false}, //converts to 17h (jmp #0)
    {type_asm_inst,         0x17,               "JMP",          0,                  false},
    {type_asm_inst,         0x18,               "TEST",         0,                  false},
    {type_asm_inst,         0x19,               "TESTN",        0,                  false},
    {type_asm_inst,         0x21,               "CMP",          0,                  false},
    {type_asm_inst,         0x33,               "CMPX",         0,                  false},

    {type_asm_effect,       0x04,               "WZ",           0,                  false}, //assembly effects
    {type_asm_effect,       0x02,               "WC",           0,                  false},
    {type_asm_effect,       0x01,               "WR",           0,                  false},
    {type_asm_effect,       0x08,               "NR",           0,                  false},

    {type_reg,              0x10,               "PAR",          0,                  false}, //registers
    {type_reg,              0x11,               "CNT",          0,                  false},
    {type_reg,              0x12,               "INA",          0,                  false},
    {type_reg,              0x13,               "INB",          0,                  false},
    {type_reg,              0x14,               "OUTA",         0,                  false},
    {type_reg,              0x15,               "OUTB",         0,                  false},
    {type_reg,              0x16,               "DIRA",         0,                  false},
    {type_reg,              0x17,               "DIRB",         0,                  false},
    {type_reg,              0x18,               "CTRA",         0,                  false},
    {type_reg,              0x19,               "CTRB",         0,                  false},
    {type_reg,              0x1A,               "FRQA",         0,                  false},
    {type_reg,              0x1B,               "FRQB",         0,                  false},
    {type_reg,              0x1C,               "PHSA",         0,                  false},
    {type_reg,              0x1D,               "PHSB",         0,                  false},
    {type_reg,              0x1E,               "VCFG",         0,                  false},
    {type_reg,              0x1F,               "VSCL",         0,                  false},

    {type_loc_long,         0,                  "RESULT",       0,                  false}, //variables

    {type_con,              0,                  "FALSE",        0,                  false}, //constants
    {type_con,              -1,                 "TRUE",         0,                  false},
    {type_con,              ~0x7FFFFFFF,        "NEGX",         0,                  false},
    {type_con,              0x7FFFFFFF,         "POSX",         0,                  false},
    {type_con_float,        0x40490FDB,         "PI",           0,                  false},

    {type_con,              0x00000001,         "RCFAST",       0,                  false},
    {type_con,              0x00000002,         "RCSLOW",       0,                  false},
    {type_con,              0x00000004,         "XINPUT",       0,                  false},
    {type_con,              0x00000008,         "XTAL1",        0,                  false},
    {type_con,              0x00000010,         "XTAL2",        0,                  false},
    {type_con,              0x00000020,         "XTAL3",        0,                  false},
    {type_con,              0x00000040,         "PLL1X",        0,                  false},
    {type_con,              0x00000080,         "PLL2X",        0,                  false},
    {type_con,              0x00000100,         "PLL4X",        0,                  false},
    {type_con,              0x00000200,         "PLL8X",        0,                  false},
    {type_con,              0x00000400,         "PLL16X",       0,                  false},

    {type_undefined,        0,                  "*END*",        0,                  false}  // end of table marker
};

SymbolTableEntry::SymbolTableEntry(const SymbolTableEntryDataTable& data)
{
    m_data.type = data.type;
    m_data.value = data.value;
    m_data.value_2 = 0;
    size_t nameLength = strlen(data.name)+1;
    m_data.name = new char[nameLength];
    strcpy(m_data.name, data.name);
    m_data.operator_type_or_asm = data.operator_type_or_asm;
    m_data.dual = data.dual;
}

SymbolEngine::SymbolEngine()
{
    m_pSymbols = new HashTable(256);
    m_pUserSymbols = new HashTable(8192);
    m_pTempUserSymbols = new HashTable(1024);

    // add symbols to hash table
    int index = 0;
    while (strcmp(symbols[index].name, "*END*") != 0)
    {
        int hashKey = m_pSymbols->GetStringHashUppercase(symbols[index].name);
        m_pSymbols->Insert(hashKey, new SymbolTableEntry(symbols[index]));
        index++;
    }
}

SymbolEngine::~SymbolEngine()
{
    delete m_pSymbols;
    m_pSymbols = 0;
    delete m_pUserSymbols;
    m_pUserSymbols = 0;
    delete m_pTempUserSymbols;
    m_pTempUserSymbols = 0;
}

// looks for the given symbol in the symbol table and returns a pointer to the entry
// if the symbol is not found, then it returns 0
SymbolTableEntry* SymbolEngine::FindSymbol(const char* pSymbolName)
{
    int hashKey = m_pSymbols->GetStringHashUppercase(pSymbolName);

    // look in automatic symbols
    HashNode* pNode = m_pSymbols->FindFirst(hashKey);
    while (pNode != 0)
    {
        SymbolTableEntry* pSymbol = (SymbolTableEntry*)(pNode->pValue);
        if (_stricmp(pSymbol->m_data.name, pSymbolName) == 0)
        {
            return pSymbol;
        }

        pNode = m_pSymbols->FindNext(pNode);
    }

    // didn't find it above, so look in user symbols
    pNode = m_pUserSymbols->FindFirst(hashKey);
    while (pNode != 0)
    {
        SymbolTableEntry* pSymbol = (SymbolTableEntry*)(pNode->pValue);
        if (_stricmp(pSymbol->m_data.name, pSymbolName) == 0)
        {
            return pSymbol;
        }

        pNode = m_pUserSymbols->FindNext(pNode);
    }

    // didn't find it above, so look in temp user symbols
    pNode = m_pTempUserSymbols->FindFirst(hashKey);
    while (pNode != 0)
    {
        SymbolTableEntry* pSymbol = (SymbolTableEntry*)(pNode->pValue);
        if (_stricmp(pSymbol->m_data.name, pSymbolName) == 0)
        {
            return pSymbol;
        }

        pNode = m_pTempUserSymbols->FindNext(pNode);
    }

    return 0;
}

void SymbolEngine::AddSymbol(const char* pSymbolName, symbol_Type type, int value, int value_2, bool bTemp)
{
    PrintSymbol(pSymbolName, (unsigned char)type, value, value_2);

    SymbolTableEntry* pSymbol = new SymbolTableEntry;
    size_t nameLength = strlen(pSymbolName)+1;
    pSymbol->m_data.name = new char[nameLength];
    strcpy(pSymbol->m_data.name, pSymbolName);
    pSymbol->m_data.type = type;
    pSymbol->m_data.value = value;
    pSymbol->m_data.value_2 = value_2;
    pSymbol->m_data.dual = false;
    pSymbol->m_data.operator_type_or_asm = 0;

    if (bTemp)
    {
        int hashKey = m_pTempUserSymbols->GetStringHashUppercase(pSymbol->m_data.name);
        m_pTempUserSymbols->Insert(hashKey, pSymbol);
    }
    else
    {
        int hashKey = m_pUserSymbols->GetStringHashUppercase(pSymbol->m_data.name);
        m_pUserSymbols->Insert(hashKey, pSymbol);
    }
}

void SymbolEngine::Reset(bool bTempsOnly)
{
    if (!bTempsOnly)
    {
        delete m_pUserSymbols;
        m_pUserSymbols = new HashTable(8192);
    }

    delete m_pTempUserSymbols;
    m_pTempUserSymbols = new HashTable(1024);
}

///////////////////////////////////////////////////////////////////////////////////////////
//                           TERMS OF USE: MIT License                                   //
///////////////////////////////////////////////////////////////////////////////////////////
// Permission is hereby granted, free of charge, to any person obtaining a copy of this  //
// software and associated documentation files (the "Software"), to deal in the Software //
// without restriction, including without limitation the rights to use, copy, modify,    //
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    //
// permit persons to whom the Software is furnished to do so, subject to the following   //
// conditions:                                                                           //
//                                                                                       //
// The above copyright notice and this permission notice shall be included in all copies //
// or substantial portions of the Software.                                              //
//                                                                                       //
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   //
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         //
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    //
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     //
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        //
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                //
///////////////////////////////////////////////////////////////////////////////////////////
