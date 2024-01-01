//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// PropellerCompilerInternal.h
//

#ifndef _PROPELLER_COMPILER_INTERNAL_H_
#define _PROPELLER_COMPILER_INTERNAL_H_

#include "PropellerCompiler.h"

struct CompilerDataInternal : public CompilerData
{
    // this stuff is misc globals from around the asm code

    int             var_byte;
    int             var_word;
    int             var_long;
    int             var_ptr;

    int             obj_start;
    int             obj_count;

    int             asm_local;

    unsigned char   pubcon_list[pubcon_list_limit];
    int             pubcon_list_size;

    char            symbolBackup[symbol_limit+2];   // used when entering a symbol into the symbol table

    bool            doc_flag;
    bool            doc_mode;

    int             cog_org;

    int             print_length;

    // these are used by EnterInfo() to fill in info_* stuff above
    // various code fills these in and then calls EnterInfo()
    // I kept it this way because at the point the code calls EnterInfo() it doesn't
    // always have the values available to just pass as parameters.
    int             inf_start;         // Start of source related to this info
    int             inf_finish;        // End (+1) of source related to this info
    int             inf_type;          // 0 = CON, 1 CON(float), 2 = DAT, 3 = DAT Symbol, 4 = PUB, 5 = PRI, 6 = PUB_PARAM, 7 = PRI_PARAM
    int             inf_data0;         // Info field 0: if CON = Value, if DAT/PUB/PRI = Start addr in object, if DAT Symbol = value, if PARAM = pub/pri index
    int             inf_data1;         // Info field 1: if DAT/PUB/PRI = End+1 addr in object, if DAT Symbol = size, if PARAM = param index
    int             inf_data2;         // Info field 2: if PUB/PRI/PARAM = Start of pub/pri name in source, if DAT Symbol = offset (in cog)
    int             inf_data3;         // Info field 3: if PUB/PRI/PARAM = End+1 of pub/pri name in source
    int             inf_data4;         // Info field 4: if PUB/PRI = index|param count

    // used by GetFileName/AddFileName
    char            filename[255];

    // these are used by the CompileConBlocks() code
    int             enum_valid;
    int             enum_value;
    int             assign_flag;
    int             assign_type;
    int             assign_value;

    // used by CompileDatBlocks code
    int             orgx;

    // used by ResolveExpression code
    int             intMode;            // 0 = uncommitted, 1 = int mode, 2 = float mode
    int             precedence;         // current precedence
    bool            bMustResolve;       // the expression must resolve
    bool            bUndefined;         // the expression is undefined
    bool            bOperandMode;       // when dealing with a PASM operand
    int             mathCurrent;        // index into mathStack[]
    int             mathStack[16];      // holds the intermediate values during expression resolving
    int             intermediateResult; // the current intermediate result
    int             currentOp;          // index into savedOp[]
    int             savedOp[32];        // stack of operations to perform during expression resolving

    // used by Object Distiller (DistillObjects.cpp)
    int             dis_ptr;
    unsigned short  dis[distiller_limit];

    // used for string constant processing (StringConstantRoutines.cpp)
    bool            str_enable;
    bool            str_patch_enable;
    int             str_count;
    int             str_buffer_ptr;
    unsigned char   str_buffer[str_buffer_limit];
    int             str_source[str_limit];
    int             str_patch[str_limit];
    int             str_offset[str_limit];
    int             str_index;

    // used by InstructionBlockCompiler.cpp & BlockNestStackRoutines.cpp
    int             bnest_ptr;
    unsigned char	bnest_type[block_nest_limit];
    int             bstack_ptr;
    int             bstack_base[block_nest_limit];
    int             bstack[block_stack_limit];
};

class Elementizer;
class SymbolEngine;

// shared globals
extern Elementizer* g_pElementizer;
extern CompilerDataInternal* g_pCompilerData;
extern SymbolEngine* g_pSymbolEngine;

#endif // _PROPELLER_COMPILER_INTERNAL_H_

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
