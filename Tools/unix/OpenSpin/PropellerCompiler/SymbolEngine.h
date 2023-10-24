//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// SymbolEngine.h
//

#ifndef _SYMBOL_ENGINE_H_
#define _SYMBOL_ENGINE_H_

#include "Utilities.h"

enum symbol_Type
{
    type_undefined = 0,     // (undefined symbol, must be 0)
    type_left,              // (
    type_right,             // )
    type_leftb,             // [
    type_rightb,            // ]
    type_comma,             // ,
    type_equal,             // =
    type_pound,             // #
    type_colon,             // :
    type_back,              /* \  */
    type_dot,               // .
    type_dotdot,            // ..
    type_at,                // @
    type_atat,              // @@
    type_til,               // ~
    type_tiltil,            // ~~
    type_rnd,               // ?
    type_inc,               // ++
    type_dec,               // --
    type_assign,            // :=
    type_spr,               // SPR
    type_unary,             // -, !, ||, etc.
    type_binary,            // +, -, *, /, etc.
    type_float,             // FLOAT
    type_round,             // ROUND
    type_trunc,             // TRUNC
    type_conexp,            // CONSTANT
    type_constr,            // STRING
    type_block,             // CON, VAR, DAT, OBJ, PUB, PRI
    type_size,              // BYTE, WORD, LONG
    type_precompile,        // PRECOMPILE
    type_archive,           // ARCHIVE
    type_file,              // FILE
    type_if,                // IF
    type_ifnot,             // IFNOT
    type_elseif,            // ELSEIF
    type_elseifnot,         // ELSEIFNOT
    type_else,              // ELSE
    type_case,              // CASE
    type_other,             // OTHER
    type_repeat,            // REPEAT
    type_repeat_count,      // REPEAT count - different QUIT method
    type_while,             // WHILE
    type_until,             // UNTIL
    type_from,              // FROM
    type_to,                // TO
    type_step,              // STEP
    type_i_next_quit,       // NEXT/QUIT
    type_i_abort_return,    // ABORT/RETURN
    type_i_look,            // LOOKUP/LOOKDOWN
    type_i_clkmode,         // CLKMODE
    type_i_clkfreq,         // CLKFREQ
    type_i_chipver,         // CHIPVER
    type_i_reboot,          // REBOOT
    type_i_cogid,           // COGID
    type_i_cognew,          // COGNEW
    type_i_coginit,         // COGINIT
    type_i_ar,              // STRSIZE, STRCOMP - always returns value
    type_i_cr,              // LOCKNEW, LOCKCLR, LOCKSET - can return value
    type_i_nr,              // BYTEFILL, WORDFILL, LONGFILL, etc. - never returns value
    type_dual,              // WAITPEQ, WAITPNE, etc. - type_asm_inst or type_i_???
    type_asm_org,           // $ (without a hex digit following)
    type_asm_dir,           // ORGX, ORG, RES, FIT, NOP
    type_asm_cond,          // IF_C, IF_Z, IF_NC, etc
    type_asm_inst,          // RDBYTE, RDWORD, RDLONG, etc.
    type_asm_effect,        // WZ, WC, WR, NR
    type_reg,               // PAR, CNT, INA, etc.
    type_con,               // user constant integer (must be followed by type_con_float)
    type_con_float,         // user constant float
    type_var_byte,          // V0user byte var
    type_var_word,          // V1user word var
    type_var_long,          // V2user long var
    type_dat_byte,          // D0user byte dat
    type_dat_word,          // D1user word dat
    type_dat_long,          // D2user long dat
    type_dat_long_res,      // (D2)user res dat (must follow type_dat_long)
    type_loc_byte,          // L0user byte local
    type_loc_word,          // L1user word local
    type_loc_long,          // L2user long local
    type_obj,               // user object
    type_objpub,            // user object.subroutine
    type_objcon,            // user object.constant (must be followed by type_objcon_float)
    type_objcon_float,      // user object.constant float
    type_sub,               // user subroutine
    type_end                // end-of-line c=0, end-of-file c=1
};

enum block_Type
{
    block_con = 0,
    block_var,
    block_dat,
    block_obj,
    block_pub,
    block_pri,
    block_dev,
};

enum operator_Type
{
    op_ror = 0,     // operator precedences (0=priority)
    op_rol,         //
    op_shr,         // 0= -, !, ||, >|, |<, ^^  (unary)
    op_shl,         // 1= ->, <-, >>, << ~>, ><
    op_min,         // 2= &
    op_max,         // 3= |, ^
    op_neg,         // 4= *, **, /, //
    op_not,         // 5= +, -
    op_and,         // 6= #>, <#
    op_abs,         // 7= <, >, <>, ==, =<, =>
    op_or,          // 8= NOT       (unary)
    op_xor,         // 9= AND
    op_add,         // 10= OR
    op_sub,
    op_sar,
    op_rev,
    op_log_and,
    op_ncd,
    op_log_or,
    op_dcd,
    op_mul,
    op_scl,
    op_div,
    op_rem,
    op_sqr,
    op_cmp_b,
    op_cmp_a,
    op_cmp_ne,
    op_cmp_e,
    op_cmp_be,
    op_cmp_ae,
    op_log_not
};

enum directives_Type
{
    dir_orgx = 0,
    dir_org,
    dir_res,
    dir_fit,
    dir_nop
};

enum if_Type
{
    if_never = 0,
    if_nc_and_nz,
    if_nc_and_z,
    if_nc,
    if_c_and_nz,
    if_nz,
    if_c_ne_z,
    if_nc_or_nz,
    if_c_and_z,
    if_c_eq_z,
    if_z,
    if_nc_or_z,
    if_c,
    if_c_or_nz,
    if_c_or_z,
    if_always,
};

struct SymbolTableEntryDataTable
{
    symbol_Type     type;                   // what type of symbol is it?
    int             value;                  // value is type dependant
    const char*     name;                   // the string of the symbol
    unsigned char   operator_type_or_asm;   // operator type for op symbols, or asm value for dual symbols
    bool            dual;                   // indicates that this symbol is used by both PASM and spin
};

struct SymbolTableEntryData
{
    symbol_Type     type;                   // what type of symbol is it?
    int             value;                  // value is type dependant
    int             value_2;                // value 2 is type dependant
    char*           name;                   // the string of the symbol
    unsigned char   operator_type_or_asm;   // operator type for op symbols, or asm value for dual symbols
    bool            dual;                   // indicates that this symbol is used by both PASM and spin
};

class SymbolTableEntry : public Hashable
{
public:
    SymbolTableEntry()
    {
        m_data.name = 0;
    }
    SymbolTableEntry(const SymbolTableEntryDataTable& data);
    ~SymbolTableEntry()
    {
        delete [] m_data.name;
    }
    SymbolTableEntryData m_data;
};

class SymbolEngine
{
    HashTable*  m_pSymbols;             // predefined symbols
    HashTable*  m_pUserSymbols;         // any symbols defined during compiling
    HashTable*  m_pTempUserSymbols;     // used for locals during CompileSubBlocks

public:
    SymbolEngine();
    ~SymbolEngine();

    SymbolTableEntry* FindSymbol(const char* pSymbolName);

    void AddSymbol(const char* pSymbolName, symbol_Type type, int value, int value_2 = 0, bool bTemp = false);
    void Reset(bool bTempsOnly = false);
};

#endif // _SYMBOL_ENGINE_H_

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
