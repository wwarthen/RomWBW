//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// CompileExpression.cpp
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

//
//************************************************************************
//*  Expression Compiler                                                 *
//************************************************************************
//
// Basic expression syntax rules:               i.e.  4000/(||x*5)//127)+1
//
//  Any one of these...     Must be followed by any one of these...
//  ------------------------------------------------------------------
//  term                    binary operator
//  )                       )
//                          <end>
//
//  Any one of these...     Must be followed by any one of these... *
//  ------------------------------------------------------------------
//  unary operator          term
//  binary operator         unary operator
//  (                       (
//
//                          * initial element of an expression
//

// forward declarations
bool CompileTerm();
bool CompileSubExpression(int precedence);
bool CompileTopExpression();

// Compile expression with sub-expressions
bool CompileExpression()
{
    if (!CompileTopExpression())
    {
        return false;
    }
    return true;
}

bool CompileTopExpression()
{
    if (!CompileSubExpression(11))
    {
        return false;
    }
    return true;
}

bool CompileSubExpression_Term()
{
    // get next element ignoring any leading +'s
    bool bEof = false;
    do
    {
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
    } while (g_pElementizer->GetType() == type_binary && g_pElementizer->GetOpType() == op_add);

    if (!g_pElementizer->NegConToCon())
    {
        return false;
    }
    g_pElementizer->SubToNeg();

    int opType = g_pElementizer->GetOpType();

    switch (g_pElementizer->GetType())
    {
        case type_atat:
            if (!CompileSubExpression(0))
            {
                return false;
            }
            if (!EnterObj(0x97)) // memop byte+index+pbase+address
            {
                return false;
            }
            if (!EnterObj(0)) // address 0
            {
                return false;
            }
            break;

        case type_unary:
            if (!CompileSubExpression(g_pElementizer->GetValue())) // value = precedence for type_unary
            {
                return false;
            }
            if (!EnterObj((unsigned char)opType | 0xE0)) // math
            {
                return false;
            }
            break;

        case type_left:
            if (!CompileTopExpression())
            {
                return false;
            }
            if (!g_pElementizer->GetElement(type_right))
            {
                return false;
            }
            break;

        default:
            if (!CompileTerm())
            {
                return false;
            }
            break;
    }
    return true;
}

bool CompileSubExpression(int precedence)
{
    precedence--;
    if (precedence < 0)
    {
        if (!CompileSubExpression_Term())
        {
            return false;
        }
        return true;
    }
    else
    {
        if (!CompileSubExpression(precedence))
        {
            return false;
        }
    }

    for (;;)
    {
        bool bEof = false;
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (g_pElementizer->GetType() != type_binary)
        {
            g_pElementizer->Backup();
            break;
        }
        // if we got here then it's type_binary (so the value is the precedence)
        if (g_pElementizer->GetValue() != precedence)
        {
            g_pElementizer->Backup();
            break;
        }
        int opType = g_pElementizer->GetOpType();
        if (!CompileSubExpression(precedence))
        {
            return false;
        }
        if (!EnterObj((unsigned char)(opType | 0xE0)))
        {
            return false;
        }
    }

    return true;
}

////////////////////////////////////////////////////////////////

//
// CompileTerm functions
//

// compile constant(constantexpression)
bool CompileTerm_ConExp()
{
    if (!g_pElementizer->GetElement(type_left))
    {
        return false;
    }
    if (!GetTryValue(true, false))
    {
        return false;
    }
    if (!CompileConstant(GetResult()))
    {
        return false;
    }
    return g_pElementizer->GetElement(type_right);
}

// compile string("constantstring")
bool CompileTerm_ConStr()
{
    if (g_pCompilerData->str_enable == false)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_snah];
        return false;
    }
    if (!g_pElementizer->GetElement(type_left))
    {
        return false;
    }
    if (!StringConstant_GetIndex()) // get index in g_pCompilerData->str_index
    {
        return false;
    }

    // get the string into the string constant buffer
    for (;;)
    {
        if (!GetTryValue(true, false))
        {
            return false;
        }
        int value = GetResult();
        if (g_pCompilerData->intMode == 2 || value == 0 || value > 0xFF)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_scmr];
            return false;
        }
        if (!StringConstant_EnterChar((unsigned char)(value & 0xFF))) // add character to string constant buffer
        {
            return false;
        }
        // more characters?
        bool bComma = false;
        if (!GetCommaOrRight(bComma))
        {
            return false;
        }
        if (!bComma)
        {
            // got right ')'
            break;
        }
    }
    StringConstant_EnterChar(0); // enter 0 terminator into string constant buffer

    if (!EnterObj(0x87)) // (memcp byte+pbase+address)
    {
        return false;
    }

    StringConstant_EnterPatch(); // enter string constant patch address

    // enter two address bytes (patched later)
    if (!EnterObj(0x80))
    {
        return false;
    }
    return EnterObj(0);
}

// compile float(integer)/round(float)/trunc(float)
bool CompileTerm_FloatRoundTrunc()
{
    g_pElementizer->Backup(); // backup to float/round/trunc

    if (!GetTryValue(true, false))
    {
        return false;
    }
    return CompileConstant(GetResult());
}

bool CompileTerm_Sub(unsigned char anchor, int value)
{
    if (!EnterObj(anchor)) // drop anchor
    {
        return false;
    }
    if (!CompileParameters((value & 0x0000FF00) >> 8))
    {
        return false;
    }
    if (!EnterObj(0x05)) // call sub
    {
        return false;
    }
    return EnterObj((unsigned char)(value & 0xFF)); // index of sub
}

// compile obj[].pub
bool CompileTerm_ObjPub(unsigned char anchor, int value)
{
    if (!EnterObj(anchor)) // drop anchor
    {
        return false;
    }

    // check for [index]
    bool bIndex = false;
    int expSourcePtr = 0;
    if (!CheckIndex(bIndex, expSourcePtr))
    {
        return false;
    }

    if (!g_pElementizer->GetElement(type_dot))
    {
        return false;
    }

    // lookup the pub symbol
    if (!GetObjSymbol(type_objpub, (char)((value & 0x0000FF00) >> 8)))
    {
        return false;
    }

    int objPubValue = g_pElementizer->GetValue();

    // compile any parameters the pub has
    if (!CompileParameters((objPubValue & 0x0000FF00) >> 8))
    {
        return false;
    }

    unsigned char byteCode = 0x06; // call obj.pub
    if (bIndex)
    {
        if (!CompileOutOfSequenceExpression(expSourcePtr))
        {
            return false;
        }
        byteCode = 0x07; // call obj[].pub
    }
    if (!EnterObj(byteCode))
    {
        return false;
    }

    if (!EnterObj((unsigned char)(value & 0xFF))) // index of obj
    {
        return false;
    }
    return EnterObj((unsigned char)(objPubValue & 0xFF)); // index of objpub
}

// compile obj[].pub\obj[]#con
bool CompileTerm_ObjPubCon(int value)
{
    if (!g_pElementizer->CheckElement(type_pound)) // check for obj#con
    {
        // not obj#con, so do obj[].pub
        return CompileTerm_ObjPub(0, value);
    }
    // lookup the symbol to get the value to compile
    if (!GetObjSymbol(type_objcon, (char)((value & 0x0000FF00) >> 8)))
    {
        return false;
    }
    return CompileConstant(g_pElementizer->GetValue());
}

// compile \sub or \obj
bool CompileTerm_Try(unsigned char anchor)
{
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    if (g_pElementizer->GetType() == type_sub)
    {
        return CompileTerm_Sub(anchor, g_pElementizer->GetValue());
    }
    else if (g_pElementizer->GetType() == type_obj)
    {
        return CompileTerm_ObjPub(anchor, g_pElementizer->GetValue());
    }

    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_easoon];
    return false;
}

bool CompileLook(int column, int param)
{
    column = column; // stop warning

    param &= 0xFF; // we only care about the bottom byte

    unsigned char byteCode = 0x35; // constant 0
    if (param < 0x80) // zero based?
    {
        byteCode += 1; // not, so make it a constant 1
    }
    if (!EnterObj(byteCode))
    {
        return false;
    }

    if (!BlockStack_CompileConstant()) // enter address constant
    {
        return false;
    }

    if (!g_pElementizer->GetElement(type_left))
    {
        return false;
    }
    if (!CompileExpression()) // compile primary value
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_colon))
    {
        return false;
    }

    for (;;)
    {
        bool bRange = false;
        if (!CompileRange(bRange)) // compile (next) value/range
        {
            return false;
        }
        byteCode = (unsigned char)param;
        if (bRange)
        {
            byteCode |= 2;
        }
        if (!EnterObj(byteCode & 0x7F))
        {
            return false;
        }
        bool bComma = false;
        if (!GetCommaOrRight(bComma))
        {
            return false;
        }
        if (!bComma)
        {
            break;
        }
    }

    if (!EnterObj(0x0F)) // lookdone
    {
        return false;
    }

    BlockStack_Write(0, g_pCompilerData->obj_ptr); // set address
    return true;
}

// compile 'lookup'/'lookdown'
// this one compiles like a block (see InstructionBlockCompiler.cpp stuff)
bool CompileTerm_Look(int value)
{
    if (!BlockNest_New(type_i_look, 1))
    {
        return false;
    }

    if (!OptimizeBlock(0, value, &CompileLook))
    {
        return false;
    }

    BlockNest_End();
    return true;
}

bool CompileTerm_ClkMode()
{
    if (!EnterObj(0x38)) // constant 4
    {
        return false;
    }
    if (!EnterObj(4))
    {
        return false;
    }
    return EnterObj(0x80); // read byte[]
}

bool CompileTerm_ClkFreq()
{
    if (!EnterObj(0x35)) // constant 0
    {
        return false;
    }
    return EnterObj(0xC0); // read long[]
}

bool CompileTerm_ChipVer()
{
    if (!EnterObj(0x34)) // constant -1
    {
        return false;
    }
    return EnterObj(0x80); // read byte[]
}

bool CompileTerm_CogId()
{
    if (!EnterObj(0x3F)) // reg op
    {
        return false;
    }
    return EnterObj(0x89); // read id
}

bool CompileTerm_Inst(int value)
{
    if (!CompileParameters((value & 0xFF) >> 6))
    {
        return false;
    }
    return EnterObj((unsigned char)(value & 0x3F)); // instruction
}

bool CompileTerm_CogNew(int value)
{
    // see if first param is a sub
    if (!g_pElementizer->GetElement(type_left))
    {
        return false;
    }
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    if (g_pElementizer->GetType() == type_sub)
    {
        int subConstant = g_pElementizer->GetValue();

        if (!g_pCompilerData->bFinalCompile && g_pCompilerData->bUnusedMethodElimination)
        {
            AddCogNewOrInit(g_pCompilerData->current_filename, subConstant & 0x000000FF);
        }

        // it is a sub, so compile as cognew(subname(params),stack)
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
        return EnterObj((unsigned char)(value & 0x3F)); // coginit
    }

    // it is not a sub, so backup and compile as cognew(address, parameter)
    g_pElementizer->Backup();
    g_pElementizer->Backup();

    if (!EnterObj(0x34)) // constant -1
    {
        return false;
    }
    return CompileTerm_Inst(value);
}

// compile @var
bool CompileTerm_At()
{
    unsigned char varType = 0;
    unsigned char varSize = 0;
    int varAddress = 0;
    int varIndexSourcePtr = 0;
    if (!GetVariable(varType, varSize, varAddress, varIndexSourcePtr))
    {
        return false;
    }
    if (varType == type_reg || varType == type_spr)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eamvaa];
        return false;
    }
    return CompileVariable(3, 0, varType, varSize, varAddress, varIndexSourcePtr);
}

bool CompileTerm()
{
    int type = g_pElementizer->GetType();
    int value = g_pElementizer->GetValue();

    switch(type)
    {
        case type_con:
        case type_con_float:
            return CompileConstant(value);
        case type_conexp:
            return CompileTerm_ConExp();
        case type_constr:
            return CompileTerm_ConStr();
        case type_float:
        case type_round:
        case type_trunc:
            return CompileTerm_FloatRoundTrunc();
        case type_back:
            return CompileTerm_Try(0x02);
        case type_sub:
            return CompileTerm_Sub(0, value);
        case type_obj:
            return CompileTerm_ObjPubCon(value);
        case type_i_look:
            return CompileTerm_Look(value);
        case type_i_clkmode:
            return CompileTerm_ClkMode();
        case type_i_clkfreq:
            return CompileTerm_ClkFreq();
        case type_i_chipver:
            return CompileTerm_ChipVer();
        case type_i_cogid:
            return CompileTerm_CogId();
        case type_i_cognew:
            return CompileTerm_CogNew(value);
        case type_i_ar: // instruction always-returns
        case type_i_cr: // instruction can-return
            return CompileTerm_Inst(value);
        case type_at: // @var
            return CompileTerm_At();
        case type_inc: // assign pre-inc w/push  ++var
            return CompileVariable_PreIncOrDec(0xA0);
        case type_dec: // assign pre-dec w/push  --var
            return CompileVariable_PreIncOrDec(0xB0);
        case type_til: // assign sign-extern byte w/push  ~var
            return CompileVariable_PreSignExtendOrRandom(0x90);
        case type_tiltil: // assign sign-extern word w/push  ~~var
            return CompileVariable_PreSignExtendOrRandom(0x94);
        case type_rnd: // assign random forward w/push  ?var
            return CompileVariable_PreSignExtendOrRandom(0x88);
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
        g_pCompilerData->error_msg = g_pErrorStrings[error_eaet];
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
        case type_inc: // assign post-inc w/push  var++
            return CompileVariable_IncOrDec(0xA8, varType, varSize, varAddress, varIndexSourcePtr);
        case type_dec: // assign post-dec w/push  var--
            return CompileVariable_IncOrDec(0xB8, varType, varSize, varAddress, varIndexSourcePtr);
        case type_rnd: // assign random reverse w/push  var?
            return CompileVariable_Assign(0x8C, varType, varSize, varAddress, varIndexSourcePtr);
        case type_til: // assign post-clear w/push  var~
            return CompileVariable_Assign(0x98, varType, varSize, varAddress, varIndexSourcePtr);
        case type_tiltil: // assign post-set w/push  var~~
            return CompileVariable_Assign(0x9C, varType, varSize, varAddress, varIndexSourcePtr);
        case type_assign: // assign write w/push  var :=
            return CompileVariable_Expression(0x80, varType, varSize, varAddress, varIndexSourcePtr);
    }

    unsigned char varOperator = 0x80; // assign write w/push
    // var binaryop?
    if (type == type_binary)
    {
        varOperator = 0xC0;	// assign math w/swapargs w/push
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
    return CompileVariable(0, varOperator, varType, varSize, varAddress, varIndexSourcePtr);
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
