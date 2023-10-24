//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// ExpressionResolver.cpp
//

#include <string.h>
#include <math.h>
#include "Utilities.h"
#include "PropellerCompilerInternal.h"
#include "SymbolEngine.h"
#include "Elementizer.h"
#include "ErrorStrings.h"

//bool GetTryValue(bool bMustResolve, bool bInteger, bool bOperandMode = false); // declared in Utilities.h

//////////////////////////////////////////
// declarations of internal functions
//

void ResolveExpression();
void ResolveSubExpression(int precedence);
void GetTerm(int& precedence);

bool CheckUndefined(bool& bUndefined);
bool CheckDat();
bool CheckConstant(bool& bConstant);
bool GetObjSymbol(int type, char id);

bool PreviewOp();
bool PerformPush();
bool PerformBinary();
bool PerformOp();

//////////////////////////////////////////
// exported functions
//

// only valid after calling GetTryValue() with bMustResolve set to true and it returned true
int GetResult()
{
    return g_pCompilerData->mathStack[g_pCompilerData->mathCurrent - 1];
}

// if this succeeds and bMustResolve it true then, the result is in g_pCompilerData->mathStack[g_pCompilerData->mathCurrent-1]
bool GetTryValue(bool bMustResolve, bool bInteger, bool bOperandMode)
{
    g_pCompilerData->intMode = bInteger ? 1 : 0;
    g_pCompilerData->bMustResolve = bMustResolve;
    g_pCompilerData->bOperandMode = bOperandMode;
    g_pCompilerData->mathCurrent = 0;
    g_pCompilerData->bUndefined = false;
    g_pCompilerData->currentOp = 0;

    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    int save_start = g_pCompilerData->source_start;
    g_pElementizer->Backup();

    // results are put into g_pCompilerData
    ResolveExpression();

    if (g_pCompilerData->error)
    {
        return false;
    }

    g_pElementizer->Backup();
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    g_pCompilerData->source_start = save_start;

    return true;
}

//////////////////////////////////////////
// internal function definitions
//

void ResolveExpression()
{
    g_pCompilerData->precedence = 11;
    ResolveSubExpression(g_pCompilerData->precedence - 1);
}

void ResolveSubExpression(int precedence)
{
    if (precedence < 0)
    {
        GetTerm(precedence);
    }
    else
    {
        ResolveSubExpression(precedence - 1);
    }

    if (g_pCompilerData->error)
    {
        return;
    }

    bool bEof = false;

    while (!bEof)
    {
        if (!g_pElementizer->GetNext(bEof))
        {
            return;
        }
        if (g_pElementizer->GetType() != type_binary)
        {
            g_pElementizer->Backup();
            return;
        }
        if (!PreviewOp())
        {
            return;
        }
        if (precedence != g_pElementizer->GetValue())
        {
            g_pElementizer->Backup();
            return;
        }
        g_pCompilerData->savedOp[g_pCompilerData->currentOp] = g_pElementizer->GetOpType();
        g_pCompilerData->currentOp++;
        int save_start = g_pCompilerData->source_start;
        int save_finish = g_pCompilerData->source_finish;
        ResolveSubExpression(precedence - 1);
        if (g_pCompilerData->error)
        {
            return;
        }
        g_pCompilerData->source_start = save_start;
        g_pCompilerData->source_finish = save_finish;
        if (!PerformBinary())
        {
            return;
        }
        g_pCompilerData->currentOp--;
    }
}

void GetTerm(int& precedence)
{
    bool bEof = false;

    // skip over any leading +'s
    do
    {
        g_pElementizer->GetNext(bEof);
        if (g_pElementizer->GetType() == type_binary && g_pElementizer->GetOpType() == op_add)
        {
            continue;
        }
        break;
    } while (!bEof);

    bool bConstant = false;
    if (!CheckConstant(bConstant))
    {
        if (g_pCompilerData->error)
        {
            return;
        }
    }
    if (bConstant)
    {
        PerformPush();
        return;
    }

    if (g_pElementizer->SubToNeg())
    {
        precedence = 0;
    }

    if (g_pElementizer->GetType()  == type_unary)
    {
        if (!PreviewOp())
        {
            return;
        }
        precedence = g_pElementizer->GetValue(); // for unary types, value = precedence
        int save_start = g_pCompilerData->source_start;
        int save_finish = g_pCompilerData->source_finish;
        g_pCompilerData->savedOp[g_pCompilerData->currentOp] = g_pElementizer->GetOpType();
        g_pCompilerData->currentOp++;
        ResolveSubExpression(precedence - 1);
        if (g_pCompilerData->error)
        {
            return;
        }
        g_pCompilerData->source_start = save_start;
        g_pCompilerData->source_finish = save_finish;
        if (!PerformOp())
        {
            return;
        }
        g_pCompilerData->currentOp--;
    }
    else if (g_pElementizer->GetType() == type_left)
    {
        ResolveExpression();
        if (!g_pElementizer->GetElement(type_right))
        {
            return;
        }
    }
    else if (g_pCompilerData->bMustResolve)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eacuool];
        // when we return from here, the calling code will return due to error = true
    }
}

bool CheckUndefined(bool& bUndefined)
{
    if (g_pElementizer->GetType() == type_undefined)
    {
        g_pCompilerData->bUndefined = bUndefined = true;

        int save_start = g_pCompilerData->source_start;
        int save_finish = g_pCompilerData->source_finish;
        if(g_pElementizer->CheckElement(type_pound))
        {
            int length = 0;
            if (!GetSymbol(&length))
            {
                return false;
            }
            if (length == 0)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_eacn];
                return false;
            }
        }
        g_pCompilerData->source_start = save_start;
        g_pCompilerData->source_finish = save_finish;

        if (g_pCompilerData->bMustResolve)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_us];
            return false;
        }
    }
    else
    {
        bUndefined = false;
    }

    return true;
}

bool CheckDat()
{
    if (g_pCompilerData->bOperandMode)
    {
        g_pElementizer->DatResToLong();
    }
    if ((g_pElementizer->GetType() == type_dat_byte) ||
        (g_pElementizer->GetType() == type_dat_word) ||
        (g_pElementizer->GetType() == type_dat_long))
    {
        return true;
    }

    return false;
}

bool CheckConstant(bool& bConstant)
{
    bConstant = true;

    if (g_pElementizer->GetType() == type_con)
    {
        if (g_pCompilerData->intMode == 2)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_fpnaiie];
            return false;
        }
        else
        {
            g_pCompilerData->intMode = 1;
        }
        g_pCompilerData->intermediateResult = g_pElementizer->GetValue();
        return true;
    }
    else if (g_pElementizer->GetType() == type_con_float)
    {
        if (g_pCompilerData->intMode == 1)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_inaifpe];
            return false;
        }
        else
        {
            g_pCompilerData->intMode = 2;
        }
        g_pCompilerData->intermediateResult = g_pElementizer->GetValue();
        return true;
    }
    else if (g_pElementizer->GetType() == type_float)
    {
        if (g_pCompilerData->intMode == 1)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_inaifpe];
            return false;
        }
        else
        {
            g_pCompilerData->intMode = 2;
        }
        if (!g_pElementizer->GetElement(type_left))
        {
            return false;
        }
        g_pCompilerData->intMode = 1;
        ResolveExpression(); // integer mode
        g_pCompilerData->intMode = 2;
        if (!g_pElementizer->GetElement(type_right))
        {
            return false;
        }

        int value = g_pCompilerData->mathStack[g_pCompilerData->mathCurrent - 1];
        g_pCompilerData->mathCurrent--;
        float fValue = (float)(value);
        g_pCompilerData->intermediateResult = *(int*)(&fValue);
        return true;
    }
    else if (g_pElementizer->GetType() == type_round)
    {
        if (g_pCompilerData->intMode == 2)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_fpnaiie];
            return false;
        }
        else
        {
            g_pCompilerData->intMode = 1;
        }
        if (!g_pElementizer->GetElement(type_left))
        {
            return false;
        }
        g_pCompilerData->intMode = 2;
        ResolveExpression(); // float mode
        g_pCompilerData->intMode = 1;
        if (!g_pElementizer->GetElement(type_right))
        {
            return false;
        }

        // convert float to rounded integer
        int value = g_pCompilerData->mathStack[g_pCompilerData->mathCurrent - 1];
        g_pCompilerData->mathCurrent--;
        float fValue = *(float*)(&value);
        g_pCompilerData->intermediateResult = (int)(fValue + 0.5f);
        return true;
    }
    else if (g_pElementizer->GetType() == type_trunc)
    {
        if (g_pCompilerData->intMode == 2)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_fpnaiie];
            return false;
        }
        else
        {
            g_pCompilerData->intMode = 1;
        }
        if (!g_pElementizer->GetElement(type_left))
        {
            return false;
        }
        g_pCompilerData->intMode = 2;
        ResolveExpression(); // float mode
        g_pCompilerData->intMode = 1;
        if (!g_pElementizer->GetElement(type_right))
        {
            return false;
        }

        // convert float to truncated integer
        int value = g_pCompilerData->mathStack[g_pCompilerData->mathCurrent - 1];
        g_pCompilerData->mathCurrent--;
        float fValue = *(float*)(&value);
        g_pCompilerData->intermediateResult = (int)(fValue);
        return true;
    }

    if (g_pCompilerData->bOperandMode)
    {
        bool bLocal = false;
        if (!CheckLocal(bLocal))
        {
            return false;
        }
    }

    bool bUndefined = false;
    if (!CheckUndefined(bUndefined))
    {
        return false;
    }
    if (bUndefined)
    {
        if (!g_pCompilerData->bMustResolve)
        {
            g_pCompilerData->intermediateResult = 0;
        }
        return true;
    }
    else if (g_pElementizer->GetType() == type_asm_org)
    {
        if (g_pCompilerData->bOperandMode)
        {
            g_pCompilerData->intermediateResult = g_pCompilerData->cog_org >> 2;
            return true;
        }
        else
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_oinah];
            return false;
        }
    }
    else if (g_pElementizer->GetType() == type_reg)
    {
        if (g_pCompilerData->bOperandMode)
        {
            if (g_pCompilerData->intMode == 2)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_fpnaiie];
                return false;
            }
            else
            {
                g_pCompilerData->intMode = 1;
            }
            g_pCompilerData->intermediateResult = g_pElementizer->GetValue();
            g_pCompilerData->intermediateResult |= 0x1E0;
            return true;
        }
        else
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_rinah];
            return false;
        }
    }
    else if (g_pElementizer->GetType() == type_obj)
    {
        if (!g_pElementizer->GetElement(type_pound))
        {
            return false;
        }
        char id = (g_pElementizer->GetValue() & 0x0000FF00) >> 8;
        if (!GetObjSymbol(type_objcon, id))
        {
            return false;
        }
        return CheckConstant(bConstant);
    }
    else if (g_pElementizer->GetType() == type_at)
    {
        if (g_pCompilerData->intMode == 2)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_fpnaiie];
            return false;
        }
        else
        {
            g_pCompilerData->intMode = 1;
        }
        bool bEof = false;
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (CheckDat())
        {
            g_pCompilerData->intermediateResult = g_pElementizer->GetValue();
            return true;
        }
        bool bUndefinedCheck = false;
        if (!CheckUndefined(bUndefinedCheck))
        {
            return false;
        }
        if (bUndefinedCheck)
        {
            if (!g_pCompilerData->bMustResolve)
            {
                g_pCompilerData->intermediateResult = 0;
            }
            bConstant = false;
            return true;
        }
        else
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_eads];
            return false;
        }
    }
    else if (CheckDat())
    {
        if (g_pCompilerData->intMode == 2)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_fpnaiie];
            return false;
        }
        else
        {
            g_pCompilerData->intMode = 1;
        }
        if (g_pCompilerData->bOperandMode)
        {
            // use org address in value 2
            g_pCompilerData->intermediateResult = g_pElementizer->GetValue2();

            // check for valid long address
            if ((g_pCompilerData->intermediateResult & 0x03) != 0)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_ainl];
                return false;
            }

            // convert to long index
            g_pCompilerData->intermediateResult >>= 2;

            if (g_pCompilerData->intermediateResult >= 0x1F0)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_aioor];
                return false;
            }
        }
        else
        {
            g_pCompilerData->intermediateResult = g_pElementizer->GetValue();
        }
        return true;
    }

    bConstant = false;
    return true;
}

bool PreviewOp()
{
    int i = g_pElementizer->GetOpType();
    int check = 0x00AACD8F; // 00000000 10101010 11001101 10001111
    check >>= i;
    if (check & 1)
    {
        if (g_pCompilerData->intMode == 2)
        {
            // integer only op while in float mode
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_ionaifpe];
            return false;
        }

        // force integer mode
        g_pCompilerData->intMode = 1;
    }
    return true;
}

bool PerformPush()
{
    if (g_pCompilerData->mathCurrent > 9)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eitc];
        return false;
    }

    g_pCompilerData->mathStack[g_pCompilerData->mathCurrent] = g_pCompilerData->intermediateResult;
    g_pCompilerData->mathCurrent++;

    return true;
}

bool PerformBinary()
{
    g_pCompilerData->mathCurrent--;
    return PerformOp();
}

bool PerformOp()
{
    if (g_pCompilerData->bUndefined)
    {
        g_pCompilerData->mathStack[g_pCompilerData->mathCurrent-1] = 0;
        return true;
    }

    int value1 = g_pCompilerData->mathStack[g_pCompilerData->mathCurrent - 1];
    int value2 = g_pCompilerData->mathStack[g_pCompilerData->mathCurrent];

    float fValue1 = *((float*)(&value1));
    float fValue2 = *((float*)(&value2));

    int result = 0;
    float fResult = 0.0f;

    switch(g_pCompilerData->savedOp[g_pCompilerData->currentOp-1])
    {
        case op_ror:
            result = ror(value1, (value2 & 0xFF));
            break;

        case op_rol:
            result = rol(value1, (value2 & 0xFF));
            break;

        case op_shr:
            result = (unsigned int)value1 >> (value2 & 0xFF);
            break;

        case op_shl:
            result = value1 << (value2 & 0xFF);
            break;

        case op_min:  // limit minimum
            if (g_pCompilerData->intMode == 2)
            {
                fResult = (fValue1 < fValue2) ? fValue2 : fValue1;
            }
            else
            {
                result = (value1 < value2) ? value2 : value1;
            }
            break;

        case op_max:  // limit maximum
            if (g_pCompilerData->intMode == 2)
            {
                fResult = (fValue1 > fValue2) ? fValue2 : fValue1;
            }
            else
            {
                result = (value1 > value2) ? value2 : value1;
            }
            break;

        case op_neg:
            if (g_pCompilerData->intMode == 2)
            {
                // float neg (using xor)
                fResult = -fValue1;
            }
            else
            {
                result = -value1;
            }
            break;

        case op_not:
            result = ~value1;
            break;

        case op_and:
            result = value1 & value2;
            break;

        case op_abs:
            if (g_pCompilerData->intMode == 2)
            {
                // float abs
                fResult = (float)fabs(fValue1);
            }
            else
            {
                result = (value1 < 0) ? -value1 : value1;
            }
            break;

        case op_or:
            result = value1 | value2;
            break;

        case op_xor:
            result = value1 ^ value2;
            break;

        case op_add:
            if (g_pCompilerData->intMode == 2)
            {
                // float add
                fResult = fValue1 + fValue2;
            }
            else
            {
                result = value1 + value2;
            }
            break;

        case op_sub:
            if (g_pCompilerData->intMode == 2)
            {
                // float sub
                fResult = fValue1 - fValue2;
            }
            else
            {
                result = value1 - value2;
            }
            break;

        case op_sar:
            result = value1 >> (value2 & 0xFF);
            break;

        case op_rev:
            value2 &= 0xFF;
            result = 0;
            for (int i = 0; i < value2; i++)
            {
                result <<= 1;
                result |= (value1 & 0x01);
                value1 >>= 1;
            }
            break;

        case op_log_and:
            if (value1 != 0)
            {
                value1 = 0xFFFFFFFF;
            }
            if (value2 != 0)
            {
                value2 = 0xFFFFFFFF;
            }
            result = value1 & value2;
            if (g_pCompilerData->intMode == 2)
            {
                if (result != 0)
                {
                    fResult = 1.0f;
                }
                else
                {
                    fResult = 0.0f;
                }
            }
            break;

        case op_ncd:
            result = 32;
            while(!(value1 & 0x80000000) && result > 0)
            {
                result--;
                value1 <<= 1;
            }
            break;

        case op_log_or:
            if (value1 != 0)
            {
                value1 = 0xFFFFFFFF;
            }
            if (value2 != 0)
            {
                value2 = 0xFFFFFFFF;
            }
            result = value1 | value2;
            if (g_pCompilerData->intMode == 2)
            {
                if (result != 0)
                {
                    fResult = 1.0f;
                }
                else
                {
                    fResult = 0.0f;
                }
            }
            break;

        case op_dcd:
            result = 1;
            result <<= (value1 & 0xFF);
            break;

        case op_mul:
            if (g_pCompilerData->intMode == 2)
            {
                // float mul
                fResult = fValue1 * fValue2;
            }
            else
            {
                result = value1 * value2;
            }
            break;

        case op_scl:
            {
                // calculate the upper 32bits of the 64bit result of multiplying two 32bit numbers
                // I did it this way to avoid using compiler specific stuff.
                int a = (value1 >> 16) & 0xffff;
                int b = value1 & 0xffff;
                int c = (value2 >> 16) & 0xffff;
                int d = value2 & 0xffff;
                int x = a * d + c * b;
                int y = (((b * d) >> 16) & 0xffff) + x;
                result = (y >> 16) & 0xffff;
                result += a * c;
            }
            break;

        case op_div:
            if (g_pCompilerData->intMode == 2)
            {
                // float div
                fResult = fValue1 / fValue2;
            }
            else
            {
                result = value1 / value2;
            }
            break;

        case op_rem: // remainder (mod)
            result = value1 % value2;
            break;

        case op_sqr: // sqrt
            if (g_pCompilerData->intMode == 2)
            {
                // float sqrt
                if (fValue1 < 0.0f)
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_ccsronfp];
                    return false;
                }
                fResult = (float)sqrt(fValue1);
            }
            else
            {
                for (result = 0; value1 >= (2*result)+1; value1 -= (2*result++)+1);
            }
            break;

        case op_cmp_b:
        case op_cmp_a:
        case op_cmp_ne:
        case op_cmp_e:
        case op_cmp_be:
        case op_cmp_ae:
            if (g_pCompilerData->intMode == 2)
            {
                // float cmp
                if (fValue1 < fValue2)
                {
                    result = 1;
                }
                else if (fValue1 > fValue2)
                {
                    result = 2;
                }
                else
                {
                    result = 4;
                }
                result &= g_pCompilerData->savedOp[g_pCompilerData->currentOp-1];
                if (result != 0)
                {
                    fResult = 1.0f;
                }
                else
                {
                    fResult = 0.0f;
                }
            }
            else
            {
                if (value1 < value2)
                {
                    result = 1;
                }
                else if (value1 > value2)
                {
                    result = 2;
                }
                else
                {
                    result = 4;
                }
                result &= g_pCompilerData->savedOp[g_pCompilerData->currentOp-1];
                if (result != 0)
                {
                    result = 0xFFFFFFFF;
                }
            }
            break;

        case op_log_not:
            result = !value1;
            if (g_pCompilerData->intMode == 2)
            {
                if (result != 0)
                {
                    fResult = 1.0f;
                }
                else
                {
                    fResult = 0.0f;
                }
            }
            else
            {
                if (result != 0)
                {
                    result = 0xFFFFFFFF;
                }
            }
            break;
    }

    if (g_pCompilerData->intMode == 2)
    {
        result = *(int*)(&fResult);
    }

    g_pCompilerData->mathStack[g_pCompilerData->mathCurrent - 1] = result;
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
