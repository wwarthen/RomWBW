//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// Elementizer.cpp
//

#include <string.h>
#include "PropellerCompilerInternal.h"
#include "Elementizer.h"
#include "SymbolEngine.h"
#include "ErrorStrings.h"
#include "Utilities.h"

// private

// set elementizer data from the currently set symbol entry
void Elementizer::SetFromSymbolEntry()
{
    if (m_pSymbolEntry)
    {
        m_type = m_pSymbolEntry->m_data.type;
        m_value = m_pSymbolEntry->m_data.value;
        m_value_2 = m_pSymbolEntry->m_data.value_2;
        if (m_pSymbolEntry->m_data.dual)
        {
            m_dual = true;
            m_asm = m_pSymbolEntry->m_data.operator_type_or_asm;
        }
        else
        {
            m_dual = false;
            m_opType = m_pSymbolEntry->m_data.operator_type_or_asm;

            // fixup for AND and OR to have asm also
            if (m_type == type_binary && m_opType == op_log_and)
            {
                m_asm = 0x18 + 0x40;
            }
            if (m_type == type_binary && m_opType == op_log_or)
            {
                m_asm = 0x1A + 0x40;
            }
        }
    }
    else
    {
        m_type = 0;
        m_value = 0;
        m_value_2 = 0;
        m_asm = -1;
        m_opType = -1;
    }
}

// public

// reset to start of source
void Elementizer::Reset()
{
    m_sourceOffset = 0;
    m_sourceFlags = 0;
}

// get the next element in source, returns true no error, bEof will be set to true if eof is hit
bool Elementizer::GetNext(bool& bEof)
{
    // update back data
    m_backOffsets[m_backIndex&0x03] = m_sourceOffset;
    m_backFlags[m_backIndex&0x03] = m_sourceFlags;
    m_backIndex++;

    // default to type_undefined
    m_type = 0;
    m_value = 0;
    m_value_2 = 0;
    m_asm = -1;
    m_opType = -1;
    m_pSymbolEntry = 0;

    // no error, and not end of file
    int error = error_none;
    bEof = false;
    bool bDocComment = false;
    int constantBase = 0;

    // setup source and symbol pointers
    char* pSource = m_pCompilerData->source;
    int sourceStart = m_sourceOffset;

    m_currentSymbol[0] = 0;
    int symbolOffset = 0;
    bool bConstantOverflow = false;

    for (;;)
    {
        char currentChar = pSource[m_sourceOffset++];

        // parse
        if (constantBase > 0)
        {
            // this handles reading in a constant of base 2, 4, 10, or 16
            // the constantBase value is set based on prefix characters handled below

            if (currentChar == '_')
            {
                // skip over _'s
                continue;
            }
            char digitValue;
            if (!CheckDigit(currentChar, digitValue, (char)constantBase))
            {
                char notUsed;
                char nextChar = pSource[m_sourceOffset];
                bool bNextCharDigit = CheckDigit(nextChar, notUsed, (char)constantBase);

                if ((constantBase == 10 &&
                    (currentChar == '.' && bNextCharDigit)) ||
                    currentChar == 'e' || currentChar == 'E')
                {
                    // handle float
                    bConstantOverflow = false;
                    m_sourceOffset = sourceStart;
                    if (GetFloat(pSource, m_sourceOffset, m_value))
                    {
                        m_sourceOffset--; // back up to point at last digit
                        m_type = type_con_float;
                    }
                    else
                    {
                        error = error_fpcmbw;
                    }
                }
                else
                {
                    // done with this constant
                    m_sourceOffset--; // back up to point at last digit
                    m_type = type_con;
                }
                constantBase = 0;
                break;
            }
            else
            {
                // multiply accumulate the constant
                unsigned int oldValue = m_value;
                m_value *= constantBase;

                // check for overflow
                if (((unsigned int)m_value / constantBase) != oldValue)
                {
                    bConstantOverflow = true;
                }

                m_value += digitValue;
            }
            continue;
        }
        else if (m_sourceFlags != 0)
        {
            // old string? (continue parsing a string)

            // for strings, m_sourceFlags will start out 0, and then cycle between 1 and 2 for
            // each character of the string, when it is 1, a type_comma is returned, when it is
            // 2 the next character is returned

            // return a comma element between each character of the string
            if (m_sourceFlags == 1)
            {
                m_sourceFlags++;
                m_sourceOffset--;
                m_type = type_comma;
                break;
            }

            // reset flag
            m_sourceFlags = 0;

            // check for errors
            if (currentChar == '\"')
            {
                error = error_es;
                break;
            }
            else if (currentChar == 0)
            {
                m_sourceOffset--; // back up from eof
                error = error_eatq;
                break;
            }
            else if (currentChar == 13)
            {
                error = error_eatq;
                break;
            }

            // return the character
            m_value = currentChar;

            // check the next character, if it's not a " then setup so the next
            // call returns a type_comma, if it is a ", then we are done with this string
            // and we leave the offset pointing after the "
            currentChar = pSource[m_sourceOffset++];
            if (currentChar != '\"')
            {
                m_sourceOffset--;
                m_sourceFlags++;
            }

            // return the character constant
            m_type = type_con;
            break;
        }
        else if (currentChar == '\"')
        {
            // new string (start parsing a string)

            // we got here because m_sourceFlags was 0 and the character is a "

            // get first character of string
            currentChar = pSource[m_sourceOffset++];

            // check for errors
            if (currentChar == '\"')
            {
                error = error_es;
                break;
            }
            else if (currentChar == 0)
            {
                m_sourceOffset--; // back up from eof
                error = error_eatq;
                break;
            }
            else if (currentChar == 13)
            {
                error = error_eatq;
                break;
            }

            // return the character in value
            m_value = currentChar & 0x000000FF;

            // check the next character, it's it's not a " then setup so the next
            // call returns a type_comma, if it is a " then it means it's a one character
            // string and we leave the offset pointing after the "
            currentChar = pSource[m_sourceOffset++];
            if (currentChar != '\"')
            {
                m_sourceOffset--; // back up, so this character will be read after the type_comma
                m_sourceFlags = 1; // cause the next call to return a type_comma
            }

            // return the character constant
            m_type = type_con;
            break;
        }
        else if (currentChar == 0)
        {
            // eof
            m_type = type_end;
            bEof = true;
            m_sourceOffset--;
            sourceStart = m_sourceOffset;
            break;
        }
        else if (currentChar == 13)
        {
            // eol
            m_type = type_end;
            break;
        }
        else if (currentChar <= ' ')
        {
            // space or tab?
            sourceStart = m_sourceOffset;
            continue;
        }
        else if (currentChar == '\'')
        {
            // comment
            // read until end of line or file, handle doc comment
            if (pSource[m_sourceOffset] == '\'')
            {
                m_sourceOffset++; // skip over second '
                bDocComment = true;
                g_pCompilerData->doc_flag = true;
            }
            for (;;)
            {
                currentChar = pSource[m_sourceOffset++];
                if (currentChar == 0)
                {
                    m_sourceOffset--; // back up from eof
                    m_type = type_end;
                    bEof = true;
                    break;
                }
                if (bDocComment)
                {
                    DocPrint(currentChar);
                }
                if (currentChar == 13)
                {
                    m_type = type_end;
                    break;
                }
            }
            break;
        }
        else if (currentChar == '{')
        {
            // brace comment
            // read the whole comment, handling doc comments as needed
            int braceCommentLevel = 1;
            if (pSource[m_sourceOffset] == '{')
            {
                m_sourceOffset++; // skip over second {
                bDocComment = true;
                g_pCompilerData->doc_flag = true;
                if (pSource[m_sourceOffset] == 13)
                {
                    m_sourceOffset++; // skip over end if present
                }
            }
            for (;;)
            {
                currentChar = pSource[m_sourceOffset++];
                if (currentChar == 0)
                {
                    if (bDocComment)
                    {
                        error = error_erbb;
                    }
                    else
                    {
                        error = error_erb;
                    }
                    m_sourceOffset--; // back up from eof
                    sourceStart = m_sourceOffset;
                    break;
                }
                else if (!bDocComment && currentChar == '{')
                {
                    braceCommentLevel++;
                }
                else if (currentChar == '}')
                {
                    if (bDocComment && pSource[m_sourceOffset] == '}')
                    {
                        m_sourceOffset++; // skip over second }
                        break;
                    }
                    else if (!bDocComment)
                    {
                        braceCommentLevel--;
                        if (braceCommentLevel < 1)
                        {
                            break;
                        }
                    }
                }
                else if (bDocComment)
                {
                    DocPrint(currentChar);
                }
            }
            if (error == error_none)
            {
                sourceStart = m_sourceOffset;
                continue;
            }
            else
            {
                break;
            }
        }
        else if (currentChar == '}')
        {
            // unmatched brace comment end
            error = error_bmbpbb;
            break;
        }
        else if (currentChar == '%')
        {
            // binary
            currentChar = pSource[m_sourceOffset++];
            char temp;
            if (currentChar == '%')
            {
                // double binary
                currentChar = pSource[m_sourceOffset++];
                if (!CheckDigit(currentChar, temp, 4))
                {
                    error = error_idbn;
                    break;
                }
                constantBase = 4;
            }
            else
            {
                if (!CheckDigit(currentChar, temp, 2))
                {
                    error = error_idbn;
                    break;
                }
                constantBase = 2;
            }
            m_sourceOffset--; // back up to first digit
            // constantBase is now set, so loop back around to read in the constant
            continue;
        }
        else if (currentChar == '$')
        {
            // hex
            currentChar = pSource[m_sourceOffset++];
            char temp;
            if (!CheckDigit(currentChar, temp, 16))
            {
                m_sourceOffset--;
                m_type = type_asm_org;
                break;
            }
            constantBase = 16;
            m_sourceOffset--; // back up to first digit
            // constantBase is now set, so loop back around to read in the constant
            continue;
        }
        else if (currentChar >= '0' && currentChar <= '9')
        {
            // dec
            constantBase = 10;
            m_sourceOffset--; // back up to first digit
            // constantBase is now set, so loop back around to read in the constant
            continue;
        }
        else
        {
            // symbol
            currentChar = Uppercase(currentChar);
            if (CheckWordChar(currentChar))
            {
                // do word symbol
                while(CheckWordChar(currentChar) && symbolOffset <= symbol_limit)
                {
                    m_currentSymbol[symbolOffset++] = currentChar;
                    currentChar = Uppercase(pSource[m_sourceOffset++]);
                }
                if (symbolOffset > symbol_limit)
                {
                    error = error_sexc;
                }
                else
                {
                    // back up so we point at last char of symbol
                    m_sourceOffset--;
                    // terminate symbol
                    m_currentSymbol[symbolOffset] = 0;
                    m_pSymbolEntry = m_pSymbolEngine->FindSymbol(m_currentSymbol);
                }
            }
            else
            {
                // try non-word symbol (one or two char operators)
                m_currentSymbol[symbolOffset++] = currentChar;
                currentChar = pSource[m_sourceOffset++];

                bool bDoOneChar = false;
                bool bDoTwoChar = false;

                // if the next char is not whitespace or eol
                if (currentChar > ' ')
                {
                    // three char symbol

                    // assign second char into symbol
                    m_currentSymbol[symbolOffset++] = currentChar;

                    // read third char into symbol
                    m_currentSymbol[symbolOffset++] = pSource[m_sourceOffset++];

                    // terminate symbol
                    m_currentSymbol[symbolOffset] = 0;

                    m_pSymbolEntry = m_pSymbolEngine->FindSymbol(m_currentSymbol);
                    if (m_pSymbolEntry == 0)
                    {
                        bDoTwoChar = true;
                        symbolOffset--;
                    }
                }

                if (bDoTwoChar)
                {
                    // two char symbol

                    // back up so we point at last char of symbol
                    m_sourceOffset--;

                    // terminate symbol
                    m_currentSymbol[symbolOffset] = 0;

                    m_pSymbolEntry = m_pSymbolEngine->FindSymbol(m_currentSymbol);
                    if (m_pSymbolEntry == 0)
                    {
                        bDoOneChar = true;
                        symbolOffset--;
                    }
                }

                if (bDoOneChar || currentChar <= ' ')
                {
                    // one char symbol

                    // back up so we point at last char of symbol
                    m_sourceOffset--;

                    // terminate symbol
                    m_currentSymbol[symbolOffset] = 0;

                    m_pSymbolEntry = m_pSymbolEngine->FindSymbol(m_currentSymbol);
                    if (m_pSymbolEntry == 0)
                    {
                        error = error_uc;
                    }
                }
            }
            break;
        }
    }

    if (bConstantOverflow)
    {
        error = error_ce32b;
    }

    // update pointers
    m_pCompilerData->source_start = sourceStart;
    m_pCompilerData->source_finish = m_sourceOffset;

    // if we got a symbol, then set the type, value, etc.
    if (m_type == 0 && m_pSymbolEntry)
    {
        SetFromSymbolEntry();
    }

    if (error != error_none)
    {
        m_pCompilerData->error = true;
        m_pCompilerData->error_msg = g_pErrorStrings[error];
        return false;
    }

    return true;
}

// if the next element is type, then return true, else false, retains value
bool Elementizer::GetElement(int type)
{
    int value = m_value;	// save current value

    bool bEof = false;
    GetNext(bEof);

    if (GetType() != type)
    {
        m_pCompilerData->error = true;
        int errorNum = 0;
        switch (type)
        {
            case type_left: errorNum = error_eleft; break;
            case type_right: errorNum = error_eright; break;
            case type_rightb: errorNum = error_erightb; break;
            case type_comma: errorNum = error_ecomma; break;
            case type_pound: errorNum = error_epound; break;
            case type_colon: errorNum = error_ecolon; break;
            case type_dot: errorNum = error_edot; break;
            case type_sub: errorNum = error_easn; break;
            case type_end: errorNum = error_eeol; break;
        }
        m_pCompilerData->error_msg = g_pErrorStrings[errorNum];
        return false;
    }

    m_value = value;		// restore saved value

    return true;
}

// check if next element is of the given type, if so return true, if not, backup and return false
bool Elementizer::CheckElement(int type)
{
    bool bEof = false;
    GetNext(bEof);
    if (GetType() == type)
    {
        return true;
    }
    Backup();
    return false;
}

// scan for the next block element of type, returns true if no error, , bEof will be set to true if eof is hit
bool Elementizer::GetNextBlock(int type, bool& bEof)
{
    bool bFound = false;
    while(bFound == false)
    {
        if (GetNext(bEof) == false || bEof == true)
        {
            break;
        }
        if (GetType() == type_block && GetValue() == type)
        {
            if (GetColumn() != 1)
            {
                m_pCompilerData->error = true;
                m_pCompilerData->error_msg = g_pErrorStrings[error_bdmbifc];
                return false;
            }
            bFound = true;
        }
    }
    // if we found the block or we hit eof, then we got no error so return true
    return (bFound || bEof);
}

// returns column of most recent Element gotten
int Elementizer::GetColumn()
{
    char* pSource = m_pCompilerData->source;
    int sourceStart = m_pCompilerData->source_start;
    if (sourceStart == 0)
    {
        // we are at the start of the source, so return 1
        return 1;
    }

    // back up until we hit a CR character
    while(pSource[sourceStart] != 13 && sourceStart > 0)
    {
        sourceStart--;
    }

    // advance forward one, (off of the CR)
    sourceStart++;

    if (sourceStart == m_pCompilerData->source_start)
    {
        // we are at the start of the line, so return 1
        return 1;
    }

    // adjust source pointer to start of line
    pSource += sourceStart;
    // adjust sourceStart such that it is how many characters we backed up
    sourceStart = m_pCompilerData->source_start - sourceStart;

    // count the characters we backed up over, accounting for tabs (tabs are 8 chars)
    int column = 0;
    for (int i = 0; i < sourceStart; i++)
    {
        if (pSource[i] == 9)
        {
            column |= 7;
        }
        column++;
    }

    return column + 1;
}

int Elementizer::GetCurrentLineNumber(int &offsetToStartOfLine, int& offsetToEndOfLine)
{
    int lineCount = 1;

    char* pSource = m_pCompilerData->source;
    int scanEnd = m_pCompilerData->source_start;
    offsetToStartOfLine = -1;
    while (scanEnd > 0)
    {
        if (pSource[--scanEnd] == 13)
        {
            if (offsetToStartOfLine == -1)
            {
                offsetToStartOfLine = scanEnd+1;
            }
            lineCount++;
        }
    }
    if (offsetToStartOfLine == -1)
    {
        offsetToStartOfLine = 0;
    }
    scanEnd = m_pCompilerData->source_start;
    while (pSource[scanEnd] != 0)
    {
        if (pSource[scanEnd] == 13 || pSource[scanEnd] == 0)
        {
            break;
        }
        scanEnd++;
    }
    offsetToEndOfLine = scanEnd;

    return lineCount;
}

// backup to the previous element
void Elementizer::Backup()
{
    m_backIndex--;
    m_sourceOffset = m_backOffsets[m_backIndex&0x03];
    m_sourceFlags = m_backFlags[m_backIndex&0x03];
}

void Elementizer::ObjConToCon()
{
    m_type -= (type_objcon - type_con);
}

void Elementizer::DatResToLong()
{
    if (m_type == type_dat_long_res)
    {
        m_type = type_dat_long;
    }
}

bool Elementizer::SubToNeg()
{
    if (m_type == type_binary && m_opType == op_sub)
    {
        m_type = type_unary;
        m_opType = op_neg;
        m_value = 0;
        m_value_2 = 0;
        return true;
    }

    return false;
}

bool Elementizer::NegConToCon()
{
    if (m_type == type_binary && m_opType == op_sub)
    {
        int savedValue = m_value;
        bool bEof = false;
        if (!GetNext(bEof))
        {
            return false;
        }
        if (m_type == type_con)
        {
            m_value = -m_value;
        }
        else if (m_type == type_con_float)
        {
            m_value |= 0x80000000;
        }
        else
        {
            Backup();
            m_type = type_binary;
            m_asm = -1;
            m_opType = op_sub;
            m_value = savedValue;
        }
    }
    return true;
}

bool Elementizer::FindSymbol(const char* symbol)
{
    m_pSymbolEntry = m_pSymbolEngine->FindSymbol(symbol);
    SetFromSymbolEntry();
    return true;
}

void Elementizer::BackupSymbol()
{
    strcpy(m_pCompilerData->symbolBackup, m_currentSymbol);
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
