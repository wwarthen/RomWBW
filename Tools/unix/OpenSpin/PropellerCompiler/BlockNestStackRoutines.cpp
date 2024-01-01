//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// BlockNestStackRoutines.cpp
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
// Block Nest Routines
//

bool BlockNest_New(unsigned char type, int stackSize)
{
    if (g_pCompilerData->bnest_ptr > block_nest_limit)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_loxnbe];
        return false;
    }

    // set blockstack base
    g_pCompilerData->bnest_type[g_pCompilerData->bnest_ptr] = type;
    g_pCompilerData->bstack_base[g_pCompilerData->bnest_ptr++] = g_pCompilerData->bstack_ptr;

    // init bstack values to max forward
    for (int i = 0; i < stackSize; i++)
    {
        g_pCompilerData->bstack[g_pCompilerData->bstack_ptr + i] = 0x0000FFC0;
    }
    g_pCompilerData->bstack_ptr += stackSize;
    if (g_pCompilerData->bstack_ptr >= block_stack_limit)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_bnso];
        return false;
    }

    return true;
}

void BlockNest_Redo(unsigned char type)
{
    g_pCompilerData->bnest_type[g_pCompilerData->bnest_ptr - 1] = type;
}

void BlockNest_End()
{
    g_pCompilerData->bnest_ptr--;
    g_pCompilerData->bstack_ptr = g_pCompilerData->bstack_base[g_pCompilerData->bnest_ptr];
}

//
// Block Stack Routines
//

void BlockStack_Write(int address, int value)
{
    int stackAddress = g_pCompilerData->bstack_base[g_pCompilerData->bnest_ptr - 1] + address;
    g_pCompilerData->bstack[stackAddress] = value;
}

int BlockStack_Read(int address)
{
    int stackAddress = g_pCompilerData->bstack_base[g_pCompilerData->bnest_ptr - 1] + address;
    return g_pCompilerData->bstack[stackAddress];
}

bool BlockStack_CompileAddress(int address)
{
    return CompileAddress(BlockStack_Read(address));
}

bool BlockStack_CompileConstant()
{
    int value = BlockStack_Read(0);

    if (value >= 0x100)
    {
        // two byte
        if (!EnterObj(0x39)) // 0x39 = 00111001b
        {
            return false;
        }
        if (!EnterObj((unsigned char)((value >> 8) & 0xFF)))
        {
            return false;
        }
    }
    else
    {
        // one byte
        if (!EnterObj(0x38)) // 0x38 = 00111000b
        {
            return false;
        }
    }

    return EnterObj((unsigned char)(value & 0xFF));
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
