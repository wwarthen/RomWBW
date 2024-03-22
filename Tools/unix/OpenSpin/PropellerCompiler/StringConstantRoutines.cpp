//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// StringConstantRoutines.cpp
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

void StringConstant_PreProcess()
{
    g_pCompilerData->str_enable = true;
    g_pCompilerData->str_patch_enable = true;
    g_pCompilerData->str_count = 0;
    g_pCompilerData->str_buffer_ptr = 0;
}

bool StringConstant_GetIndex()
{
    int strIndex = 0;
    for (strIndex = 0; strIndex < g_pCompilerData->str_count; strIndex++)
    {
        if (g_pCompilerData->str_source[strIndex] == g_pCompilerData->source_start)
        {
            break;
        }
    }

    if (strIndex == g_pCompilerData->str_count)
    {
        // new string constant
        if (g_pCompilerData->str_count > str_limit)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_tmsc];
            return false;
        }
        g_pCompilerData->str_count++;
        g_pCompilerData->str_source[strIndex] = g_pCompilerData->source_start;
        g_pCompilerData->str_offset[strIndex] = g_pCompilerData->str_buffer_ptr;
    }
    else
    {
        // old
        g_pCompilerData->str_buffer_ptr = g_pCompilerData->str_offset[strIndex];
    }

    g_pCompilerData->str_index = strIndex;

    return true;
}

bool StringConstant_EnterChar(unsigned char theChar)
{
    if (g_pCompilerData->str_buffer_ptr >= str_buffer_limit)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_tmscc];
        return false;
    }
    g_pCompilerData->str_buffer[g_pCompilerData->str_buffer_ptr++] = theChar;
    return true;
}

void StringConstant_EnterPatch()
{
    if (g_pCompilerData->str_patch_enable)
    {
        g_pCompilerData->str_patch[g_pCompilerData->str_index] = g_pCompilerData->obj_ptr;
    }
}

bool StringConstant_PostProcess()
{
    if (g_pCompilerData->str_count > 0)
    {
        // patch string addresses
        int strIndex = 0;
        while(g_pCompilerData->str_count > 0)
        {
            int temp = g_pCompilerData->obj_ptr;
            temp += g_pCompilerData->str_offset[strIndex];
            temp |= 0x8000;
            //short strAddress = ((temp & 0xFF00) >> 8) | ((temp & 0x00FF) << 8);  // xchg ah,al
            //*((short*)&(g_pCompilerData->obj[g_pCompilerData->str_patch[strIndex]])) = strAddress;
            g_pCompilerData->obj[g_pCompilerData->str_patch[strIndex]] = (unsigned char)((temp >> 8) & 0xFF);
            g_pCompilerData->obj[g_pCompilerData->str_patch[strIndex] + 1] = (unsigned char)(temp & 0xFF);
            strIndex++;
            g_pCompilerData->str_count--;
        }

        // enter strings into obj
        for (int i = 0; i < g_pCompilerData->str_buffer_ptr; i++)
        {
            if (!EnterObj(g_pCompilerData->str_buffer[i]))
            {
                return false;
            }
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
