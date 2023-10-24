//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// InstructionBlockCompiler.cpp
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

//////////////////////////////////////////
// declarations for internal functions
//

bool CompileBlock_IfOrIfNot(int column, int bIf);
bool CompileBlock_Case(int column);
bool CompileBlock_Repeat(int column);

static int s_column = 0;

//////////////////////////////////////////
// exported functions
//

bool CompileTopBlock()
{
    g_pCompilerData->bnest_ptr = 0;
    g_pCompilerData->bstack_ptr = 0;
    StringConstant_PreProcess();

    if (!CompileBlock(0))
    {
        return false;
    }

    // enter a return into obj
    if (!EnterObj(0x32)) // 0x32 = 00110010b
    {
        return false;
    }

    return StringConstant_PostProcess();
}

bool CompileBlock(int column)
{
    bool bEof = false;

    while (!bEof)
    {
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (g_pElementizer->GetType() == type_end)
        {
            continue;
        }
        if (g_pElementizer->GetType() == type_block)
        {
            break;
        }

        s_column = g_pElementizer->GetColumn();
        if (s_column <= column)
        {
            break;
        }

        if (g_pElementizer->GetType() == type_if)
        {
            if (!CompileBlock_IfOrIfNot(s_column, true))
            {
                return false;
            }
        }
        else if (g_pElementizer->GetType() == type_ifnot)
        {
            if (!CompileBlock_IfOrIfNot(s_column, false))
            {
                return false;
            }
        }
        else if (g_pElementizer->GetType() == type_case)
        {
            if (!CompileBlock_Case(s_column))
            {
                return false;
            }
        }
        else if (g_pElementizer->GetType() == type_repeat)
        {
            if (!CompileBlock_Repeat(s_column))
            {
                return false;
            }
        }
        else
        {
            if (!CompileInstruction())
            {
                return false;
            }
            if (!g_pElementizer->GetElement(type_end))
            {
                return false;
            }
        }
    }
    g_pElementizer->Backup();
    return true;
}

//////////////////////////////////////////
// internal function definitions
//

bool CompileIfOrIfNot_FinalJmp(int& addressCount)
{
    if (!EnterObj(0x04)) // jmp
    {
        return false;
    }
    if (!BlockStack_CompileAddress(0))
    {
        return false;
    }
    BlockStack_Write(addressCount, g_pCompilerData->obj_ptr);
    addressCount++;
    return true;
}

bool CompileIfOrIfNot_Condition(int& addressCount, unsigned char byteCode)
{
    if (!CompileExpression())
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_end))
    {
        return false;
    }
    if (!EnterObj(byteCode))
    {
        return false;
    }
    if (!BlockStack_CompileAddress(addressCount))
    {
        return false;
    }
    return true;
}

bool CompileIfOrIfNot_ElseCondition(int& addressCount, unsigned char byteCode)
{
    if (!CompileIfOrIfNot_FinalJmp(addressCount))
    {
        return false;
    }
    if (addressCount < (if_limit + 2))
    {
        return CompileIfOrIfNot_Condition(addressCount, byteCode);
    }

    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_loxee];
    return false;
}

bool CompileIfOrIfNot(int column, int param)
{
    int addressCount = 1;

    if (!CompileIfOrIfNot_Condition(addressCount, (unsigned char)(param)))
    {
        return false;
    }

    bool bEof = false;

    while (!bEof)
    {
        if (!CompileBlock(column))
        {
            return false;
        }

        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (bEof)
        {
            break;
        }
        s_column = g_pElementizer->GetColumn();
        if (s_column < column)
        {
            g_pElementizer->Backup();
            break;
        }
        if (g_pElementizer->GetType() == type_elseif)
        {
            if (!CompileIfOrIfNot_ElseCondition(addressCount, 0x0A))
            {
                return false;
            }
        }
        else if (g_pElementizer->GetType() == type_elseifnot)
        {
            if (!CompileIfOrIfNot_ElseCondition(addressCount, 0x0B))
            {
                return false;
            }
        }
        else if (g_pElementizer->GetType() == type_else)
        {
            if (!CompileIfOrIfNot_FinalJmp(addressCount))
            {
                return false;
            }
            if (!g_pElementizer->GetElement(type_end))
            {
                return false;
            }
            if (!CompileBlock(column))
            {
                return false;
            }
            break;
        }
        else
        {
            g_pElementizer->Backup();
            break;
        }
    }

    BlockStack_Write(addressCount, g_pCompilerData->obj_ptr); // set last address
    BlockStack_Write(0, g_pCompilerData->obj_ptr);	// set final address
    return true;
}

bool CompileBlock_IfOrIfNot(int column, int bIf)
{
    if (!BlockNest_New(type_if, if_limit+3))
    {
        return false;
    }
    if (!OptimizeBlock(column, bIf ? 0x0A : 0x0B, &CompileIfOrIfNot))
    {
        return false;
    }
    BlockNest_End();
    return true;
}

bool CompileCase(int column, int param)
{
    param = param; // stop warning

    if (!BlockStack_CompileConstant())
    {
        return false;
    }
    if (!CompileExpression())
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_end))
    {
        return false;
    }

    int savedSourcePtr = g_pElementizer->GetSourcePtr();
    int otherSourcePtr = 0;
    bool bOther = false;
    int caseCount = 0;

    bool bEof = false;
    while (!bEof)
    {
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (bEof)
        {
            break;
        }
        if (g_pElementizer->GetType() == type_end)
        {
            continue;
        }
        s_column = g_pElementizer->GetColumn();
        g_pElementizer->Backup();
        if (s_column <= column)
        {
            break;
        }

        if (bOther) // if we have OTHER: it should have been the last case, so we shouldn't get here again
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_omblc];
            return false;
        }

        if (g_pElementizer->GetType() == type_other)
        {
            bOther = true;
            if (!g_pElementizer->GetNext(bEof)) // get/skip 'other'
            {
                return false;
            }
            otherSourcePtr = g_pCompilerData->source_start; // save the pointer to the beginning of 'other'
        }
        else
        {
            caseCount++;
            if (caseCount > case_limit)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_loxce];
                return false;
            }
            for (;;)
            {
                bool bRange = false;
                if (!CompileRange(bRange))
                {
                    return false;
                }
                if (!EnterObj(bRange ? 0x0E : 0x0D)) // enter bytecode for case range or case value into obj
                {
                    return false;
                }
                if (!BlockStack_CompileAddress(caseCount))
                {
                    return false;
                }
                if (!g_pElementizer->CheckElement(type_comma))
                {
                    break;
                }
            }
        }
        if (!g_pElementizer->GetElement(type_colon))
        {
            return false;
        }
        if (!SkipBlock(s_column))
        {
            return false;
        }
    }

    if (caseCount == 0)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_nce];
        return false;
    }

    if (bOther)
    {
        // set the source pointer to where the OTHER is at, then get it to set the column
        g_pElementizer->SetSourcePtr(otherSourcePtr);
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        int new_column = g_pElementizer->GetColumn();
        // skip the colon
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (!CompileBlock(new_column))
        {
            return false;
        }
    }
    if (!EnterObj(0x0C)) // casedone, end of range checks
    {
        return false;
    }
    g_pElementizer->SetSourcePtr(savedSourcePtr);
    caseCount = 0;
    bOther = false;
    bEof = false;

    while(!bEof)
    {
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (bEof)
        {
            break;
        }
        if (g_pElementizer->GetType() == type_end)
        {
            continue;
        }
        s_column = g_pElementizer->GetColumn();
        g_pElementizer->Backup();
        if (s_column <= column)
        {
            break;
        }

        if (g_pElementizer->GetType() == type_other)
        {
            // skip over other, already compiled
            if (!g_pElementizer->GetNext(bEof))
            {
                return false;
            }
            if (!g_pElementizer->GetNext(bEof))
            {
                return false;
            }
            if (!SkipBlock(s_column))
            {
                return false;
            }
        }
        else
        {
            // skip over range/values(s), already compiled
            for (;;)
            {
                if (!SkipRange())
                {
                    return false;
                }
                if (!g_pElementizer->CheckElement(type_comma))
                {
                    break;
                }
            }
            caseCount++;
            BlockStack_Write(caseCount, g_pCompilerData->obj_ptr);
            if (!g_pElementizer->GetElement(type_colon))
            {
                return false;
            }
            if (!CompileBlock(s_column))
            {
                return false;
            }
            if (!EnterObj(0x0C))    // casedone
            {
                return false;
            }
        }
    }
    BlockStack_Write(0, g_pCompilerData->obj_ptr);
    return true;
}

bool CompileBlock_Case(int column)
{
    if (!BlockNest_New(type_case, case_limit+1))
    {
        return false;
    }
    if (!OptimizeBlock(column, 0, &CompileCase))
    {
        return false;
    }
    BlockNest_End();
    return true;
}

static bool s_bHasPost = false;
bool CompileRepeatPlain(int column, int param)
{
    param = param; // stop warning

    BlockStack_Write(2, g_pCompilerData->obj_ptr); // set reverse address
    if (!s_bHasPost)
    {
        BlockStack_Write(0, g_pCompilerData->obj_ptr); // set plain 'next' address
    }
    if (!CompileBlock(column))
    {
        return false;
    }
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    unsigned char byteCode = 0x04;
    if (!bEof)
    {
        s_column = g_pElementizer->GetColumn();
        if (s_column < column)
        {
            g_pElementizer->Backup();
        }
        else
        {
            // check for post while or until
            int postType = g_pElementizer->GetType();
            if ((postType == type_while) ||
                (postType == type_until))
            {
                s_bHasPost = true;
                BlockStack_Write(0, g_pCompilerData->obj_ptr); // set post-while/until 'next' address
                if (!CompileExpression()) // compile post-while/until expression
                {
                    return false;
                }
                if (!g_pElementizer->GetElement(type_end))
                {
                    return false;
                }
                byteCode = (postType == type_while) ? 0x0B : 0x0A;
            }
            else
            {
                g_pElementizer->Backup();
            }
        }
    }
    if (!EnterObj(byteCode))
    {
        return false;
    }
    if (!BlockStack_CompileAddress(2)) // compile reverse address
    {
        return false;
    }
    BlockStack_Write(1, g_pCompilerData->obj_ptr); // set 'quit' address

    return true;
}

bool CompileRepeatPreWhileOrUntil(int column, int param)
{
    BlockStack_Write(0, g_pCompilerData->obj_ptr); // set 'next'/reverse address
    if (!CompileExpression()) // compile pre-while/until expression
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_end))
    {
        return false;
    }
    if (!EnterObj((unsigned char)(param & 0xFF))) // enter the passed in bytecode (jz or jnz)
    {
        return false;
    }
    if (!BlockStack_CompileAddress(1)) // compile forward address
    {
        return false;
    }
    if (!CompileBlock(column)) // compile repeat-while/until block
    {
        return false;
    }
    if (!EnterObj(0x04)) // (jmp)
    {
        return false;
    }
    if (!BlockStack_CompileAddress(0)) // compile reverse address
    {
        return false;
    }
    BlockStack_Write(1, g_pCompilerData->obj_ptr); // set 'quit'/forward address
    return true;
}

bool CompileRepeatCount(int column, int param)
{
    param = param; // stop warning

    if (!CompileExpression()) // compile count expression
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_end))
    {
        return false;
    }
    if (!EnterObj(0x08)) // (tjz)
    {
        return false;
    }
    if (!BlockStack_CompileAddress(1)) // compile forward address
    {
        return false;
    }
    BlockStack_Write(2, g_pCompilerData->obj_ptr); // set reverse address
    if (!CompileBlock(column)) // compile repeat-count block
    {
        return false;
    }
    BlockStack_Write(0, g_pCompilerData->obj_ptr); // set 'next' address
    if (!EnterObj(0x09)) // (djnz)
    {
        return false;
    }
    if (!BlockStack_CompileAddress(2)) // compile reverse address
    {
        return false;
    }
    BlockStack_Write(1, g_pCompilerData->obj_ptr); // set 'quit'/forward address
    return true;
}

bool CompileRepeatVariable(int column, int param)
{
    param = param; // stop warning

    unsigned char varType = 0;
    unsigned char varSize = 0;
    int varAddress = 0;
    int varIndexSourcePtr = 0;
    if (!GetVariable(varType, varSize, varAddress, varIndexSourcePtr))
    {
        return false;
    }

    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof)) // get 'from'
    {
        return false;
    }
    if (g_pElementizer->GetType() != type_from)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_efrom];
        return false;
    }
    int fromSourcePtr = g_pElementizer->GetSourcePtr();
    g_pCompilerData->str_enable = false;
    if (!CompileExpression()) // compile 'from' expression (string not allowed)
    {
        return false;
    }
    g_pCompilerData->str_enable = true;

    if (!CompileVariable(1, 0, varType, varSize, varAddress, varIndexSourcePtr)) // compile var write
    {
        return false;
    }
    BlockStack_Write(2, g_pCompilerData->obj_ptr); // set reverse address

    if (!g_pElementizer->GetNext(bEof)) // get 'to'
    {
        return false;
    }
    if (g_pElementizer->GetType() != type_to)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eto];
        return false;
    }
    g_pCompilerData->str_enable = false;
    if (!SkipExpression()) // skip 'to' expression (string not allowed)
    {
        return false;
    }
    g_pCompilerData->str_enable = true;

    if (!g_pElementizer->GetNext(bEof)) // check for 'step'
    {
        return false;
    }
    unsigned char byteCode = 0;
    if (g_pElementizer->GetType() == type_step)
    {
        // handle step
        int savedSourcePtr = g_pElementizer->GetSourcePtr();
        g_pCompilerData->str_enable = false;
        if (!SkipExpression()) // skip 'step' expression (string not allowed)
        {
            return false;
        }
        g_pCompilerData->str_enable = true;
        if (!g_pElementizer->GetElement(type_end))
        {
            return false;
        }
        if (!CompileBlock(column))
        {
            return false;
        }
        BlockStack_Write(0, g_pCompilerData->obj_ptr); // set 'next' address
        if (!CompileOutOfSequenceExpression(savedSourcePtr)) // compile the step expression
        {
            return false;
        }
        byteCode = 0x06; // (repeat-var w/step)
    }
    else if (g_pElementizer->GetType() == type_end)
    {
        // no step, compile block
        if (!CompileBlock(column))
        {
            return false;
        }
        BlockStack_Write(0, g_pCompilerData->obj_ptr); // set 'next' address
        byteCode = 0x02; // (repeat-var)
    }
    else
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_esoeol];
        return false;
    }

    int savedSourcePtr = g_pElementizer->GetSourcePtr();
    g_pElementizer->SetSourcePtr(fromSourcePtr);
    if (!CompileExpression()) // compile 'from' expression
    {
        return false;
    }
    if (!g_pElementizer->GetNext(bEof)) // skip 'to'
    {
        return false;
    }
    if (!CompileExpression()) // compile 'to' expression
    {
        return false;
    }
    g_pElementizer->SetSourcePtr(savedSourcePtr);
    if (!CompileVariable_Assign(byteCode, varType, varSize, varAddress, varIndexSourcePtr)) // compile repeat-var
    {
        return false;
    }
    if (!BlockStack_CompileAddress(2)) // compile reverse address
    {
        return false;
    }
    BlockStack_Write(1, g_pCompilerData->obj_ptr); // set 'quit'/forward address
    return true;
}

bool CompileBlock_Repeat(int column)
{
    if (!BlockNest_New(type_repeat, 3))
    {
        return false;
    }

    // determine which type of repeat
    bool (*pCompileFunc)(int, int) = 0;
    int param = 0;
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    if (g_pElementizer->GetType() == type_end)
    {
        // repeat
        pCompileFunc = &CompileRepeatPlain;
        s_bHasPost = false; // assume it doesn't have a post while or until (will be detected)
    }
    else if (g_pElementizer->GetType() == type_while)
    {
        // repeat while <exp>
        pCompileFunc = &CompileRepeatPreWhileOrUntil;
        param = 0x0A;
    }
    else if (g_pElementizer->GetType() == type_until)
    {
        // repeat until <exp>
        pCompileFunc = &CompileRepeatPreWhileOrUntil;
        param = 0x0B;
    }
    else
    {
        g_pElementizer->Backup();
        int savedSourcePtr = g_pElementizer->GetSourcePtr();
        if (!SkipExpression())
        {
            return false;
        }
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        g_pElementizer->SetSourcePtr(savedSourcePtr);
        if (g_pElementizer->GetType() == type_end)
        {
            // repeat <exp>
            pCompileFunc = &CompileRepeatCount;
            // redo blocknest type
            BlockNest_Redo(type_repeat_count);
        }
        else
        {
            // repeat var from <exp> to <exp> step <exp>
            pCompileFunc = &CompileRepeatVariable;
        }
    }

    if (!OptimizeBlock(column, param, pCompileFunc))
    {
        return false;
    }

    BlockNest_End();
    return true;
}

bool OptimizeBlock(int column, int param, bool (*pCompileFunction)(int, int))
{
    int savedSourcePtr = g_pElementizer->GetSourcePtr();
    int savedObjPtr = g_pCompilerData->obj_ptr;
    int size = 0;

    for (;;)
    {
        g_pElementizer->SetSourcePtr(savedSourcePtr);
        g_pCompilerData->obj_ptr = savedObjPtr;

        if (!(*pCompileFunction)(column, param))
        {
            return false;
        }

        // (re)compile until same size twice
        if (size != g_pCompilerData->obj_ptr)
        {
            size = g_pCompilerData->obj_ptr;
        }
        else
        {
            break;
        }
    }

    return true;
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
