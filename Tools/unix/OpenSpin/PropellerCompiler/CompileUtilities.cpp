//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// CompileUtilities.cpp
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

bool SkipBlock(int column)
{
    int savedObjPtr = g_pCompilerData->obj_ptr;
    bool savedStringPatchEnable = g_pCompilerData->str_patch_enable;
    g_pCompilerData->str_patch_enable = false;
    if (!CompileBlock(column))
    {
        return false;
    }
    g_pCompilerData->str_patch_enable = savedStringPatchEnable;
    g_pCompilerData->obj_ptr = savedObjPtr;
    return true;
}

bool SkipRange()
{
    int savedObjPtr = g_pCompilerData->obj_ptr;
    bool savedStringPatchEnable = g_pCompilerData->str_patch_enable;
    g_pCompilerData->str_patch_enable = false;
    bool bRange;
    if (!CompileRange(bRange))
    {
        return false;
    }
    g_pCompilerData->str_patch_enable = savedStringPatchEnable;
    g_pCompilerData->obj_ptr = savedObjPtr;
    return true;
}

bool SkipExpression()
{
    int savedObjPtr = g_pCompilerData->obj_ptr;
    bool savedStringPatchEnable = g_pCompilerData->str_patch_enable;
    g_pCompilerData->str_patch_enable = false;
    if (!CompileExpression())
    {
        return false;
    }
    g_pCompilerData->str_patch_enable = savedStringPatchEnable;
    g_pCompilerData->obj_ptr = savedObjPtr;
    return true;
}

bool CheckIndex(bool& bIndex, int& expSourcePtr)
{
    bIndex = false;
    if (g_pElementizer->CheckElement(type_leftb))
    {
        expSourcePtr = g_pElementizer->GetSourcePtr();
        if (!SkipExpression())
        {
            return false;
        }
        if (!g_pElementizer->GetElement(type_rightb))
        {
            return false;
        }
        bIndex = true;
    }
    return true;
}

bool CheckIndexRange(bool& bIndex, int& expSourcePtr)
{
    bIndex = false;
    if (g_pElementizer->CheckElement(type_leftb))
    {
        expSourcePtr = g_pElementizer->GetSourcePtr();
        if (!SkipExpression())
        {
            return false;
        }
        if (g_pElementizer->CheckElement(type_dotdot))
        {
            if (!SkipExpression())
            {
                return false;
            }
        }
        if (!g_pElementizer->GetElement(type_rightb))
        {
            return false;
        }
        bIndex = true;
    }
    return true;
}

bool CheckVariable_AddressExpression(int& expSourcePtr)
{
    bool bIndex = false;
    if (!CheckIndex(bIndex, expSourcePtr))
    {
        return false;
    }
    if (!bIndex)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eleftb];
        return false;
    }
    return true;
}

bool CheckVariable(bool& bVariable, unsigned char& type, unsigned char& size, int& address, int& indexSourcePtr)
{
    address = g_pElementizer->GetValue();
    indexSourcePtr = 0;

    unsigned char varType = (unsigned char)(g_pElementizer->GetType() & 0xFF);

    if (varType >= type_var_byte && varType <= type_var_long)
    {
        type = type_var_byte;
        // adjust address base on the var size
        if (varType < type_var_long)
        {
            address += g_pCompilerData->var_long;
        }
        if (varType == type_var_byte)
        {
            address += g_pCompilerData->var_word;
        }
    }
    else if (varType >= type_dat_byte && varType <= type_dat_long)
    {
        type = type_dat_byte;
    }
    else if (varType >= type_loc_byte && varType <= type_loc_long)
    {
        type = type_loc_byte;
    }
    else
    {
        type = varType;
        if (varType == type_size)
        {
            size = (unsigned char)(g_pElementizer->GetValue() & 0xFF);
            if (!CheckVariable_AddressExpression(address))
            {
                return false;
            }
            bool bIndex = false;
            if (!CheckIndex(bIndex, indexSourcePtr))
            {
                return false;
            }
            bVariable = true;
            return true;
        }
        else
        {
            size = 2;
            if (varType == type_spr)
            {
                if (!CheckVariable_AddressExpression(address))
                {
                    return false;
                }
                bVariable = true;
                return true;
            }
            else if (varType == type_reg)
            {
                bool bIndex = false;
                if (!CheckIndexRange(bIndex, indexSourcePtr))
                {
                    return false;
                }
                if (bIndex)
                {
                    size = 3;
                }
                bVariable = true;
                return true;
            }
            else
            {
                bVariable = false;
                return true;
            }
        }
    }
    // if we got here then it's a var/dat/loc type
    // set size
    size = varType;
    size -= type;
    bool bIndex = false;
    if (!CheckIndex(bIndex, indexSourcePtr))
    {
        return false;
    }
    if (!bIndex)
    {
        // check for .byte/word/long{[index]}
        if (g_pElementizer->CheckElement(type_dot))
        {
            bool bEof = false;
            if (!g_pElementizer->GetNext(bEof)) // get byte/word/long
            {
                return false;
            }
            if (g_pElementizer->GetType() != type_size)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_ebwol];
                return false;
            }
            if (size < (g_pElementizer->GetValue() & 0xFF)) // new size must be same or smaller
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_sombs];
                return false;
            }
            size = (g_pElementizer->GetValue() & 0xFF); // update size

            bool bIndexCheck = false;
            if (!CheckIndex(bIndexCheck, indexSourcePtr))
            {
                return false;
            }
        }
    }
    bVariable = true;
    return true;
}

bool GetVariable(unsigned char& type, unsigned char& size, int& address, int& indexSourcePtr)
{
    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    bool bVariable = false;
    if (!CheckVariable(bVariable, type, size, address, indexSourcePtr))
    {
        return false;
    }
    if (!bVariable)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eav];
        return false;
    }
    return true;
}

bool CompileVariable(unsigned char vOperation, unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr)
{
    // compile and index(s)
    if (type != type_reg)
    {
        if (type == type_spr || type == type_size)
        {
            if (!CompileOutOfSequenceExpression(address))
            {
                return false;
            }
        }
        if (type != type_spr)
        {
            if (indexSourcePtr != 0)
            {
                if (!CompileOutOfSequenceExpression(indexSourcePtr))
                {
                    return false;
                }
            }
        }
    }

    unsigned char byteCode = 0;

    if (type == type_spr)
    {
        byteCode = 0x24 | vOperation;
    }
    else if (type == type_reg)
    {
        byteCode = 0x3F;
        if (size != 2)
        {
            bool bRange = false;
            if (!CompileOutOfSequenceRange(indexSourcePtr, bRange))
            {
                return false;
            }
            if (bRange)
            {
                byteCode = 0x3E;
            }
            else
            {
                byteCode = 0x3D;
            }
        }
        if (!EnterObj(byteCode))
        {
            return false;
        }
        // byteCode = 1 in high bit, bottom 2 bits of vOperation in next two bits, then bottom 5 bits of address
        byteCode = 0x80 | ((vOperation & 3) << 5) | (address & 0x1F);
    }
    else
    {
        if ((type != type_var_byte && type != type_loc_byte) || size != 2 || address >= 8*4 || indexSourcePtr != 0)
        {
            // not compact
            byteCode = 0x80 | (size << 5);
            if (indexSourcePtr != 0)
            {
                byteCode |= 0x10;
            }
            byteCode |= vOperation;
            if (type != type_size)
            {
                if (type == type_dat_byte)
                {
                    byteCode += 4;
                }
                else if (type == type_var_byte)
                {
                    byteCode += 8;
                }
                else if (type == type_loc_byte)
                {
                    byteCode += 12;
                }
                else
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_internal];
                    return false;
                }
                if (!EnterObj(byteCode))
                {
                    return false;
                }
                if (address > 0x7F)
                {
                    // two byte address
                    byteCode = (unsigned char)(address >> 8) | 0x80;
                    if (!EnterObj(byteCode))
                    {
                        return false;
                    }
                }
                byteCode = (unsigned char)address;
            }
        }
        else
        {
            // compact
            byteCode = (type == type_var_byte) ? 0x40 : 0x60;
            byteCode |= (unsigned char)address;
            byteCode |= vOperation;
        }
    }

    if (!EnterObj(byteCode))
    {
        return false;
    }
    if (vOperation == 2) // if assign
    {
        if (!EnterObj(vOperator))
        {
            return false;
        }
    }
    return true;
}

bool CompileVariable_Assign(unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr)
{
    return CompileVariable(2, vOperator, type, size, address, indexSourcePtr);
}

bool CompileVariable_Expression(unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr)
{
    if (!CompileExpression())
    {
        return false;
    }
    return CompileVariable(2, vOperator, type, size, address, indexSourcePtr);
}

bool CompileVariable_PreSignExtendOrRandom(unsigned char vOperator)
{
    unsigned char varType = 0;
    unsigned char varSize = 0;
    int varAddress = 0;
    int varIndexSourcePtr = 0;
    if (!GetVariable(varType, varSize, varAddress, varIndexSourcePtr))
    {
        return false;
    }

    return CompileVariable_Assign(vOperator, varType, varSize, varAddress, varIndexSourcePtr);
}

bool CompileVariable_IncOrDec(unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr)
{
    return CompileVariable(2, vOperator | (((size + 1) & 3) << 1), type, size, address, indexSourcePtr);
}

bool CompileVariable_PreIncOrDec(unsigned char vOperator)
{
    unsigned char varType = 0;
    unsigned char varSize = 0;
    int varAddress = 0;
    int varIndexSourcePtr = 0;
    if (!GetVariable(varType, varSize, varAddress, varIndexSourcePtr))
    {
        return false;
    }

    return CompileVariable_IncOrDec(vOperator, varType, varSize, varAddress, varIndexSourcePtr);
}

bool CompileParameters(int numParameters)
{
    if (numParameters > 0)
    {
        if (!g_pElementizer->GetElement(type_left)) // (
        {
            return false;
        }
        for (int i = 0; i < numParameters; i++)
        {
            if (!CompileExpression())
            {
                return false;
            }
            if (i < (numParameters - 1))
            {
                if (!g_pElementizer->GetElement(type_comma))
                {
                    return false;
                }
            }
        }
        if (!g_pElementizer->GetElement(type_right)) // )
        {
            return false;
        }
    }
    return true;
}

bool CompileConstant(int value)
{
    if (value >= -1 && value <= 1)
    {
        // constant is -1, 0, or 1, so compiles to a single bytecode
        unsigned char byteCode = (unsigned char)(value+1) | 0x34;
        if (!EnterObj(byteCode))
        {
            return false;
        }
        return true;
    }

    // see if it's a mask
    // masks can be: only one bit on (e.g. 0x00008000),
    //				 all bits on except one (e.g. 0xFFFF7FFF),
    //			     all bits on up to a bit then all zeros (e.g. 0x0000FFFF),
    //				 or all bits off up to a bit then all ones (e.g. 0xFFFF0000)
    for (unsigned char i = 0; i < 128; i++)
    {
        int testVal = 2;
        testVal <<= (i & 0x1F); // mask i, so that we only actually shift 0 to 31

        if (i & 0x20) // i in range 32 to 63 or 96 to 127
        {
            testVal--;
        }
        if (i& 0x40) // i in range 64 to 127
        {
            testVal = ~testVal;
        }

        if (testVal == value)
        {
            if (!EnterObj(0x37)) // (constant mask)
            {
                return false;
            }
            if (!EnterObj(i))
            {
                return false;
            }
            return true;
        }
    }

    // handle constants with upper 2 or 3 bytes being 0xFFs, using 'not'
    if ((value & 0xFFFFFF00) == 0xFFFFFF00)
    {
        // one byte constant using 'not'
        if (!EnterObj(0x38))
        {
            return false;
        }
        unsigned char byteCode = (unsigned char)(value & 0xFF);
        if (!EnterObj(~byteCode))
        {
            return false;
        }
        if (!EnterObj(0xE7)) // (bitwise bot)
        {
            return false;
        }
        return true;
    }
    else if ((value & 0xFFFF0000) == 0xFFFF0000)
    {
        // two byte constant using 'not'
        if (!EnterObj(0x39))
        {
            return false;
        }
        unsigned char byteCode = (unsigned char)((value >> 8) & 0xFF);
        if (!EnterObj(~byteCode))
        {
            return false;
        }
        byteCode = (unsigned char)(value & 0xFF);
        if (!EnterObj(~byteCode))
        {
            return false;
        }
        if (!EnterObj(0xE7)) // (bitwise bot)
        {
            return false;
        }
        return true;
    }

    // 1 to 4 byte constant
    unsigned char size = 1;
    if (value & 0xFF000000)
    {
        size = 4;
    }
    else if (value & 0x00FF0000)
    {
        size = 3;
    }
    else if (value & 0x0000FF00)
    {
        size = 2;
    }
    unsigned char byteCode = 0x37 + size; // (constant 1..4 bytes)
    if (!EnterObj(byteCode))
    {
        return false;
    }
    for (unsigned char i = size; i > 0; i--)
    {
        byteCode = (unsigned char)((value >> ((i - 1) * 8)) & 0xFF);
        if (!EnterObj(byteCode))
        {
            return false;
        }
    }
    return true;
}

bool CompileOutOfSequenceExpression(int sourcePtr)
{
    int savedSourcePtr = g_pElementizer->GetSourcePtr();
    g_pElementizer->SetSourcePtr(sourcePtr);
    if (!CompileExpression())
    {
        return false;
    }
    g_pElementizer->SetSourcePtr(savedSourcePtr);
    return true;
}

bool CompileOutOfSequenceRange(int sourcePtr, bool& bRange)
{
    int savedSourcePtr = g_pElementizer->GetSourcePtr();
    g_pElementizer->SetSourcePtr(sourcePtr);
    if (!CompileRange(bRange))
    {
        return false;
    }
    g_pElementizer->SetSourcePtr(savedSourcePtr);
    return true;
}

// compiles either a value or a range and sets the bRange flag accordingly
bool CompileRange(bool& bRange)
{
    if (!CompileExpression())
    {
        return false;
    }

    if (g_pElementizer->CheckElement(type_dotdot))
    {
        if (!CompileExpression())
        {
            return false;
        }
        bRange = true;
    }
    else
    {
        bRange = false;
    }

    return true;
}

// Compile relative address
bool CompileAddress(int address)
{
    address -= g_pCompilerData->obj_ptr; // make relative address
    address--; // compensate for single-byte

    if ((address < 0 && abs(address) <= 64) || (address >= 0 && address < 64))
    {
        // single byte, enter
        address &= 0x007F;
    }
    else
    {
        // double byte, compensate and enter
        address--;
        if (!EnterObj((unsigned char)((address >> 8) | 0x80)))
        {
            return false;
        }
        address &= 0x00FF;
    }

    return EnterObj((unsigned char)address);
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
