//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// CompileInstruction.cpp
//

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "Utilities.h"
#include "PropellerCompilerInternal.h"
#include "SymbolEngine.h"
#include "Elementizer.h"
#include "ErrorStrings.h"
#include "CompileUtilities.h"

// these are in CompileExpression.cpp
extern bool CompileTerm_Try(unsigned char anchor);
extern bool CompileTerm_Sub(unsigned char anchor, int value);
extern bool CompileTerm_ObjPub(unsigned char anchor, int value);
extern bool CompileTerm_CogNew(int value);
extern bool CompileTerm_Inst(int value);

bool CompileInst_NextQuit(int value)
{
    int blockNestPtr = g_pCompilerData->bnest_ptr;

    unsigned char byteCode = 0;
    int caseDepth = 0;

    // find repeat block
    for (;;)
    {
        if (blockNestPtr == 0)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_tioawarb];
            return false;
        }

        unsigned char blockNestType = g_pCompilerData->bnest_type[blockNestPtr-1];

        if (blockNestType == type_repeat)
        {
            byteCode = 0x04; // jmp 'quit'
            break;
        }
        else if (blockNestType == type_repeat_count)
        {
            byteCode = 0x0B; // jnz 'quit'
            break;
        }
        else if (blockNestType == type_if)
        {
            // ignore 'if' block nest(s)
        }
        else if (blockNestType == type_case) // allow nesting within 'case' block(s)
        {
            caseDepth += 8;	// pop 2 longs for each nested 'case'
        }
        else
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_internal];
            return false;
        }
        blockNestPtr--;
    }

    if (caseDepth > 0)
    {
        if (!CompileConstant(caseDepth)) // enter pop count
        {
            return false;
        }
        if (!EnterObj(0x14)) // pop
        {
            return false;
        }
    }

    int blockStackPtr = g_pCompilerData->bstack_base[blockNestPtr - 1];

    if ((value & 0xFF) == 0)
    {
        // next
        if (!EnterObj(0x04)) // jmp 'next'
        {
            return false;
        }
        return CompileAddress(g_pCompilerData->bstack[blockStackPtr]);
    }

    // quit
    if (!EnterObj(byteCode)) // jmp/jnz 'quit'
    {
        return false;
    }
    return CompileAddress(g_pCompilerData->bstack[blockStackPtr + 1]);
}

bool CompileInst_AbortReturn(int value)
{
    // preview next element
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    g_pElementizer->Backup();

    if (g_pElementizer->GetType() != type_end)
    {
        // there's an expression, compile it
        if (!CompileExpression())
        {
            return false;
        }
        value |= 0x01; // +value
    }
    return EnterObj((unsigned char)(value & 0xFF));
}

bool CompileInst_Reboot()
{
    if (!EnterObj(0x37)) // constant 0x80
    {
        return false;
    }
    if (!EnterObj(0x06))
    {
        return false;
    }

    if (!EnterObj(0x35)) // constant 0
    {
        return false;
    }

    return EnterObj(0x20); // clkset
}

bool CompileInst_CogNew(int value)
{
    return CompileTerm_CogNew(value ^ 0x04); // no push
}

bool CompileInst_CogInit(int value)
{
    int savedSourcePtr = g_pElementizer->GetSourcePtr();

    if (!g_pElementizer->GetElement(type_left))
    {
        return false;
    }
    int cogidSourcePtr = g_pElementizer->GetSourcePtr();
    if (!SkipExpression())
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_comma))
    {
        return false;
    }

    // check for subroutine
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    if (g_pElementizer->GetType() != type_sub)
    {
        // not subroutine, so backup
        g_pElementizer->SetSourcePtr(savedSourcePtr);

        return CompileTerm_Inst(value); // compile assembly 'coginit'
    }

    // compile subroutine 'cognew' (push params+index)
    int subConstant = g_pElementizer->GetValue();

    if (!g_pCompilerData->bFinalCompile && g_pCompilerData->bUnusedMethodElimination)
    {
        AddCogNewOrInit(g_pCompilerData->current_filename, subConstant & 0x000000FF);
    }

    if (!CompileParameters((g_pElementizer->GetValue() & 0x0000FF00) >> 8))
    {
        return false;
    }
    if (!CompileConstant(subConstant))
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_comma))
    {
        return false;
    }
    if (!CompileExpression()) // compile stack expression
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_right))
    {
        return false;
    }
    if (!EnterObj(0x15)) // run
    {
        return false;
    }

    // compile 'cogid' exp
    if (!CompileOutOfSequenceExpression(cogidSourcePtr))
    {
        return false;
    }

    if (!EnterObj(0x3F)) // regop
    {
        return false;
    }
    if (!EnterObj(0x8F)) // read+dcurr
    {
        return false;
    }
    if (!EnterObj(0x37)) // constant mask
    {
        return false;
    }
    if (!EnterObj(0x61)) // -4
    {
        return false;
    }
    if (!EnterObj(0xD1)) // write long[base][index]
    {
        return false;
    }
    return EnterObj(0x2C); // coginit
}

bool CompileInst_InstCr(int value)
{
    return CompileTerm_Inst(value ^ 0x04); // no push
}

bool CompileInst_Unary(int value)
{
    return CompileVariable_PreSignExtendOrRandom((unsigned char)(0x40 | (value & 0xFF)));
}

bool CompileInst_Assign(unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr)
{
    if (!CompileExpression())
    {
        return false;
    }

    return CompileVariable(1, vOperator, type, size, address, indexSourcePtr);
}

bool CompileInstruction()
{
    int type = g_pElementizer->GetType();
    int value = g_pElementizer->GetValue();

    switch(type)
    {
        case type_back:
            return CompileTerm_Try(0x03);
        case type_sub:
            return CompileTerm_Sub(0x01, value);
        case type_obj:
            return CompileTerm_ObjPub(0x01, value);
        case type_i_next_quit:
            return CompileInst_NextQuit(value);
        case type_i_abort_return:
            return CompileInst_AbortReturn(value);
        case type_i_reboot:
            return CompileInst_Reboot();
        case type_i_cognew:
            return CompileInst_CogNew(value);
        case type_i_coginit:
            return CompileInst_CogInit(value);
        case type_i_cr: // instruction can-return
            return CompileInst_InstCr(value);
        case type_i_nr: // instruction never-return
            return CompileTerm_Inst(value);

        case type_inc: // assign pre-inc  ++var
            return CompileVariable_PreIncOrDec(0x20);
        case type_dec: // assign pre-dec  --var
            return CompileVariable_PreIncOrDec(0x30);
        case type_til: // assign sign-extern byte  ~var
            return CompileVariable_PreSignExtendOrRandom(0x10);
        case type_tiltil: // assign sign-extern word  ~~var
            return CompileVariable_PreSignExtendOrRandom(0x14);
        case type_rnd: // assign random forward  ?var
            return CompileVariable_PreSignExtendOrRandom(0x08);
    }

    g_pElementizer->SubToNeg();
    if (g_pElementizer->GetType() == type_unary)
    {
        return CompileInst_Unary(g_pElementizer->GetOpType());
    }

    unsigned char varType = 0;
    unsigned char varSize = 0;
    int varAddress = 0;
    int varIndexSourcePtr = 0;
    bool bVariable = false;
    if (!CheckVariable(bVariable, varType, varSize, varAddress, varIndexSourcePtr))
    {
        return false;
    }
    if (!bVariable)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eaiov];
        return false;
    }

    // check for post-var modifier
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    type = g_pElementizer->GetType();
    switch (type)
    {
        case type_inc: // assign post-inc
            return CompileVariable_IncOrDec(0x28, varType, varSize, varAddress, varIndexSourcePtr);
        case type_dec: // assign post-dec
            return CompileVariable_IncOrDec(0x38, varType, varSize, varAddress, varIndexSourcePtr);
        case type_rnd: // assign random reverse
            return CompileVariable_Assign(0x0C, varType, varSize, varAddress, varIndexSourcePtr);
        case type_til: // assign post-clear
            return CompileVariable_Assign(0x18, varType, varSize, varAddress, varIndexSourcePtr);
        case type_tiltil: // assign post-set
            return CompileVariable_Assign(0x1C, varType, varSize, varAddress, varIndexSourcePtr);
        case type_assign:
            return CompileInst_Assign(0x1C, varType, varSize, varAddress, varIndexSourcePtr);
    }

    // var binaryop?
    if (type == type_binary)
    {
        unsigned char varOperator = 0x40;   // assign math w/swapargs
        varOperator |= (unsigned char)(g_pElementizer->GetOpType());

        // check for '=' after binary op
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (g_pElementizer->GetType() == type_equal)
        {
            return CompileVariable_Expression(varOperator, varType, varSize, varAddress, varIndexSourcePtr);
        }
        else
        {
            g_pElementizer->Backup(); // not '=' so backup
        }
    }
    g_pElementizer->Backup(); // no post-var modifier, so backup

    // error, so backup and reget variable for error display
    g_pElementizer->Backup();
    g_pElementizer->GetNext(bEof); //  this won't fail here, because it already succeeded above

    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_vnao];
    return false;
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
