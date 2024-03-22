//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// Utilities.cpp
//

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include "PropellerCompilerInternal.h"
#include "SymbolEngine.h"
#include "Elementizer.h"
#include "ErrorStrings.h"

char* pPrintDestination = 0;
int printLimit = 0;

void SetPrint(char* pDestination, int limit)
{
    pPrintDestination = pDestination;
    printLimit = limit;
    g_pCompilerData->print_length = 0;
}

bool PrintChr(char theChar)
{
    if (g_pCompilerData->print_length >= printLimit)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_litl];
        return false;
    }
    pPrintDestination[g_pCompilerData->print_length++] = theChar;
    return true;
}

bool PrintString(const char* theString)
{
    int stringOffset = 0;
    bool result = true;
    char theChar = theString[stringOffset++];
    while(theChar != 0 && result)
    {
        result = PrintChr(theChar);
        theChar = theString[stringOffset++];
    }

    return result;
}

bool PrintSymbol(const char* pSymbolName, unsigned char type, int value, int value_2)
{
    char tempStr[symbol_limit + 64];
    sprintf(tempStr, "TYPE: %02X", type);
    if (!PrintString(tempStr))
    {
        return false;
    }
    sprintf(tempStr, "   VALUE: %08X (%08x)", value, value_2);
    if (!PrintString(tempStr))
    {
        return false;
    }
    sprintf(tempStr, "   NAME: %s\r", pSymbolName);
    return PrintString(tempStr);
}

bool ListLine(int offset, int count)
{
    char tempStr[8];
    sprintf(tempStr, "%04X-", offset);
    if (!PrintString(tempStr))
    {
        return false;
    }

    for (int i = 0; i < 17; i++)
    {
        if (i < count)
        {
            sprintf(tempStr, " %02X", g_pCompilerData->obj[offset+i]);
            if (!PrintString(tempStr))
            {
                return false;
            }
        }
        else
        {
            if (!PrintChr(32))
            {
                return false;
            }
            if (!PrintChr(32))
            {
                return false;
            }
            if (!PrintChr(32))
            {
                return false;
            }
        }
    }
    for (int i = 0; i < count; i++)
    {
        unsigned char theChar = g_pCompilerData->obj[offset+i];
        if (theChar < ' ' || theChar >= 0x7F)
        {
            theChar = '.';
        }
        if (!PrintChr(theChar))
        {
            return false;
        }
    }

    return PrintChr(13);
}

bool PrintObj()
{
    char tempStr[256];
    sprintf(tempStr, "\rOBJ bytes: %d", g_pCompilerData->obj_ptr);
    if (!PrintString(tempStr))
    {
        return false;
    }

    sprintf(tempStr, "\r\r_CLKMODE: %02X", g_pCompilerData->clkmode);
    if (!PrintString(tempStr))
    {
        return false;
    }
    sprintf(tempStr, "\r_CLKFREQ: %08X\r\r", g_pCompilerData->clkfreq);
    if (!PrintString(tempStr))
    {
        return false;
    }

    for (int i = 0; i < g_pCompilerData->obj_ptr; i+=16)
    {
        if (!ListLine(i, ((i + 16) < g_pCompilerData->obj_ptr) ? 16 : (g_pCompilerData->obj_ptr - i)))
        {
            return false;
        }
    }
    return true;
}

bool DocPrint(char theChar)
{
    if (g_pCompilerData->doc_mode)
    {
        return PrintChr(theChar);
    }
    return true;
}

// assumes theChar has been uppercased.
bool CheckWordChar(char theChar)
{
    if ((theChar >= '0' && theChar <= '9') || (theChar == '_') || (theChar >= 'A' && theChar <= 'Z'))
    {
        return true;
    }
    return false;
}

char Uppercase(char theChar)
{
    if (theChar >= 'a' && theChar <= 'z')
    {
        return theChar - ('a' - 'A');
    }
    return theChar;
}

// if theChar is a hex digit this returns true and digitValue is 0 to 15 depending on the digit
bool CheckHex(char theChar, char& digitValue)
{
    theChar = Uppercase(theChar);
    digitValue = theChar - '0';
    if (digitValue >= 0 && digitValue <= 9)
    {
        return true;
    }
    digitValue -= ('A' - '9' - 1);
    if (digitValue >= 10 && digitValue <= 15)
    {
        return true;
    }
    return false;
}

// if theChar is a valid digit in numberBase this returns true and digitValue is 0 to numberBase-1 depending on the digit
bool CheckDigit(char theChar, char& digitValue, char numberBase)
{
    if (CheckHex(theChar, digitValue))
    {
        if (digitValue < numberBase)
        {
            return true;
        }
    }
    return false;
}

bool CheckPlus(char theChar)
{
    if (theChar == '+')
    {
        return true;
    }
    return false;
}

bool CheckLocal(bool& bLocal)
{
    if (g_pElementizer->GetType() != type_colon)
    {
        bLocal = false;
        return true;
    }
    else
    {
        int save_start = g_pCompilerData->source_start;
        int length = 0;
        if (!GetSymbol(&length))
        {
            return false;
        }
        g_pCompilerData->source_start = save_start;
        if (length == 0)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_eals];
            return false;
        }
        if (length > symbol_limit)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_sexc];
            return false;
        }

        int temp = g_pCompilerData->asm_local;
        temp += 0x01010101;   //(last four characters range from 01h-20h)

        //append above four bytes to the symbol name
        char* pSymbol = g_pElementizer->GetCurrentSymbol();
        pSymbol += strlen(pSymbol);
        //*((int*)pSymbol) = temp;
        pSymbol[0] = (char)(temp & 0xFF);
        pSymbol[1] = (char)((temp >> 8) & 0xFF);
        pSymbol[2] = (char)((temp >> 16) & 0xFF);
        pSymbol[3] = (char)((temp >> 24) & 0xFF);
        pSymbol += 4;
        *pSymbol = 0;

        // re-get the symbol (point to the beginning of it)
        pSymbol = g_pElementizer->GetCurrentSymbol();

        // try to find the symbol
        g_pElementizer->FindSymbol(pSymbol);
        bLocal = true;
    }

    return true;
}

// returns true if it's able to get a valid float from pSource
// on success, value will be the float value
bool GetFloat(char* pSource, int& sourceOffset, int& value)
{
    // copy stuff to a temp buffer, stripping _'s and going until an invalid float char
    // this also stops if we hit a second ., a second E, or get a sign without and E before it
    //
    char temp[128];
    int tempOffset = 0;
    bool bGotDot = false;
    bool bGotE = false;
    bool bGotSign = false;
    while(tempOffset < 127)
    {
        char currentChar = pSource[sourceOffset++];
        if (currentChar == '_')
        {
            continue;
        }
        if (currentChar >= '0' && currentChar <= '9')
        {
            temp[tempOffset++] = currentChar;
        }
        else if (bGotDot == false && currentChar == '.')
        {
            temp[tempOffset++] = currentChar;
            bGotDot = true;
        }
        else if (bGotE == false && (currentChar == 'e' || currentChar == 'E'))
        {
            temp[tempOffset++] = currentChar;
            bGotE = true;
        }
        else if (bGotE == true && bGotSign == false && (currentChar == '+' || currentChar == '-'))
        {
            temp[tempOffset++] = currentChar;
            bGotSign = true;
        }
        else
        {
            break;
        }
    }
    // terminate temp buffer
    temp[tempOffset] = 0;

    // if temp is full bail (it's not possible for this to be a valid float)
    if (tempOffset == 127)
    {
        return false;
    }

    // use strtod to convert temp to a float
    char* endPtr;
    float floatValue = (float)strtod(temp, &endPtr);

    // if strtod failed then bail
    if (endPtr == temp || errno == ERANGE)
    {
        return false;
    }

    // then use pointer assignment trick to assign float into int without casting
    value = *((int*)&floatValue);

    return true;
}

bool GetSymbol(int* pLength)
{
    bool bEof = false;

    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    char* pSymbol = g_pElementizer->GetCurrentSymbol();
    if (!CheckWordChar(pSymbol[0])) // g_pCompilerData->source[g_pCompilerData->source_start]
    {
        *pLength = 0;
    }
    else
    {
        *pLength = (int)strlen(pSymbol);
    }

    return true;
}

bool GetObjSymbol(int type, char id)
{
    int length = 0;
    if (!GetSymbol(&length))
    {
        return false;
    }
    if (length > 0)
    {
        // append id to symbol
        char* pSymbol = g_pElementizer->GetCurrentSymbol();
        pSymbol[length] = id + 1;
        pSymbol[length+1] = 0;

        g_pElementizer->FindSymbol(pSymbol);

        if (type == type_objpub)
        {
            if (g_pElementizer->GetType() == type_objpub)
            {
                return true;
            }
        }
        else
        {
            if (g_pElementizer->GetType() == type_objcon || g_pElementizer->GetType() == type_objcon_float)
            {
                // convert type_objcon_xx to type_con_xx
                g_pElementizer->ObjConToCon();
                return true;
            }
        }
    }

    g_pCompilerData->error = true;
    if (type == type_objpub)
    {
        g_pCompilerData->error_msg = g_pErrorStrings[error_easn];
    }
    else
    {
        g_pCompilerData->error_msg = g_pErrorStrings[error_eacn];
    }

    return false;
}

bool GetCommaOrEnd(bool& bComma)
{
    bool bEof = false;
    g_pElementizer->GetNext(bEof);
    if (g_pElementizer->GetType() == type_comma)
    {
        bComma = true;
        return true;
    }
    if (g_pElementizer->GetType() == type_end)
    {
        bComma = false;
        return true;
    }

    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_ecoeol];
    return false;
}

bool GetCommaOrRight(bool& bComma)
{
    bool bEof = false;
    g_pElementizer->GetNext(bEof);
    if (g_pElementizer->GetType() == type_comma)
    {
        bComma = true;
        return true;
    }
    if (g_pElementizer->GetType() == type_right)
    {
        bComma = false;
        return true;
    }

    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_ecor];
    return false;
}

bool GetPipeOrEnd(bool& bPipe)
{
    bool bEof = false;
    g_pElementizer->GetNext(bEof);
    if (g_pElementizer->GetType() == type_binary && g_pElementizer->GetOpType() == op_or)
    {
        bPipe = true;
        return true;
    }
    if (g_pElementizer->GetType() == type_end)
    {
        bPipe = false;
        return true;
    }

    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_epoeol];
    return false;
}

// this puts the filename into g_pCompilerData->filename
bool GetFilename(int& filenameStart, int& filenameFinish)
{
    bool bEof = false;
    int filenameOffset = 0;

    g_pElementizer->GetNext(bEof);
    filenameStart = g_pCompilerData->source_start;
    g_pElementizer->Backup();

    for (;;)
    {
        g_pElementizer->GetNext(bEof);
        if (g_pElementizer->GetType() != type_con)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_ifufiq];
            return false;
        }
        char theChar = (char)(g_pElementizer->GetValue());

        // check for illegal characters in filename
        if (theChar > 127 || theChar < 32 || theChar == '\\' || theChar == '/' ||
            theChar == ':' || theChar == '*' || theChar == '?' || theChar == '\"' ||
            theChar == '<' || theChar == '>' || theChar == '|')
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_ifc];
            break;
        }

        // add character
        g_pCompilerData->filename[filenameOffset++] = theChar;
        filenameFinish = g_pCompilerData->source_finish;

        // see if the filename is too long
        if (filenameOffset > 253)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_ftl];
            break;
        }

        if (!g_pElementizer->CheckElement(type_comma))
        {
            g_pCompilerData->filename[filenameOffset] = 0; // terminate filename
            g_pCompilerData->source_start = filenameStart;
            g_pCompilerData->source_finish = filenameFinish;
            return true;
        }
    }

    return false;
}

void EnterInfo()
{
    int index = g_pCompilerData->info_count;
    if (index >= info_limit)
    {
        index--;
    }
    else
    {
        g_pCompilerData->info_count++;
    }

    g_pCompilerData->info_start[index] = g_pCompilerData->inf_start;
    g_pCompilerData->info_finish[index] = g_pCompilerData->inf_finish;
    g_pCompilerData->info_type[index] = g_pCompilerData->inf_type;
    g_pCompilerData->info_data0[index] = g_pCompilerData->inf_data0;
    g_pCompilerData->info_data1[index] = g_pCompilerData->inf_data1;
    g_pCompilerData->info_data2[index] = g_pCompilerData->inf_data2;
    g_pCompilerData->info_data3[index] = g_pCompilerData->inf_data3;
    g_pCompilerData->info_data4[index] = g_pCompilerData->inf_data4;
}

bool EnterObj(unsigned char value)
{
    if (g_pCompilerData->obj_ptr < g_pCompilerData->obj_limit)
    {
        g_pCompilerData->obj[g_pCompilerData->obj_ptr++] = value;
    }
    else
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_oex];
        return false;
    }

    return true;
}

bool EnterObjLong(int value)
{
    if (g_pCompilerData->obj_ptr+4 < g_pCompilerData->obj_limit)
    {
        g_pCompilerData->obj[g_pCompilerData->obj_ptr++] = (unsigned char)value;
        value >>= 8;
        g_pCompilerData->obj[g_pCompilerData->obj_ptr++] = (unsigned char)value;
        value >>= 8;
        g_pCompilerData->obj[g_pCompilerData->obj_ptr++] = (unsigned char)value;
        value >>= 8;
        g_pCompilerData->obj[g_pCompilerData->obj_ptr++] = (unsigned char)value;
    }
    else
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_oex];
        return false;
    }

    return true;
}

bool IncrementAsmLocal()
{
    unsigned char* pAsmLocal = (unsigned char*)&(g_pCompilerData->asm_local);
    (*pAsmLocal)++;
    (*pAsmLocal)&=0x1F;
    if (*pAsmLocal == 0)
    {
        (*(pAsmLocal+1))++;
        (*(pAsmLocal+1))&=0x1F;
        if ((*(pAsmLocal+1)) == 0)
        {
            (*(pAsmLocal+2))++;
            (*(pAsmLocal+2))&=0x1F;
            if ((*(pAsmLocal+2)) == 0)
            {
                (*(pAsmLocal+3))++;
                (*(pAsmLocal+3))&=0x1F;
                if ((*(pAsmLocal+3)) == 0)
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_loxdse];
                    return false;
                }
            }
        }
    }
    return true;
}

bool AddFileName(int& fileCount, int& fileIndex, char* pFilenames, int* pNameStart, int* pNameFinish, int error)
{
    int filenameStart = 0;
    int filenameFinish = 0;
    if (GetFilename(filenameStart, filenameFinish))
    {
        for (int i = 0; i < fileCount; i++)
        {
            if (strcmp(&pFilenames[i*256], g_pCompilerData->filename) == 0)
            {
                // filename already in list
                fileIndex = i;
                return true;
            }
        }

        // not in list, so add it if there is room
        if (fileCount < file_limit)
        {
            pNameStart[fileCount] = filenameStart;
            pNameFinish[fileCount] = filenameFinish;
            strcpy(&pFilenames[fileCount*256], g_pCompilerData->filename);
            fileIndex = fileCount;
            fileCount++;
            return true;
        }

        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error];
    }
    return false;
}

bool AddPubConListByte(char value)
{
    if (g_pCompilerData->pubcon_list_size < pubcon_list_limit)
    {
        g_pCompilerData->pubcon_list[g_pCompilerData->pubcon_list_size] = value;
        g_pCompilerData->pubcon_list_size++;
    }
    else
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_pclo];
        return false;
    }

    return true;
}

bool AddSymbolToPubConList()
{
    for (unsigned int i = 0; i < strlen(g_pCompilerData->symbolBackup); i++)
    {
        if (!AddPubConListByte(g_pCompilerData->symbolBackup[i]))
        {
            return false;
        }
    }
    return true;
}

bool ConAssign(bool bFloat, int value)
{
    if (g_pCompilerData->assign_flag == 0)
    {
        // verify
        g_pCompilerData->source_start = g_pCompilerData->inf_start;
        g_pCompilerData->source_finish = g_pCompilerData->inf_finish;

        int type = bFloat ? type_con_float : type_con;
        if (g_pCompilerData->assign_type != type || g_pCompilerData->assign_value != value)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_siad];
            return false;
        }
    }
    else
    {
        g_pCompilerData->inf_type = bFloat ? info_con_float : info_con;
        g_pCompilerData->inf_data0 = value;
        g_pCompilerData->inf_data1 = 0;
        g_pCompilerData->inf_data2 = 0;
        g_pCompilerData->inf_data3 = 0;
        g_pCompilerData->inf_data4 = 0;
        EnterInfo();

        if (!AddSymbolToPubConList())
        {
            return false;
        }
        if (!AddPubConListByte(bFloat ? 17 : 16))
        {
            return false;
        }
        int temp = value;
        for (int i = 0; i < 4; i++)
        {
            if (!AddPubConListByte(temp & 0xFF))
            {
                return false;
            }
            temp >>= 8;
        }

        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, bFloat ? type_con_float : type_con, value);
#ifdef RPE_DEBUG
        float fValue = *((float*)(&value));
        printf("%s %d %f \n", g_pCompilerData->symbolBackup, value, fValue);
#endif
    }

    return true;
}

bool HandleConSymbol(int pass)
{
    // symbol
    g_pCompilerData->inf_start = g_pCompilerData->source_start;
    g_pCompilerData->inf_finish = g_pCompilerData->source_finish;

    // save a copy of the symbol
    g_pElementizer->BackupSymbol();

    bool bFloat = false;

    bool bEof = false;
    g_pElementizer->GetNext(bEof);
    if (g_pElementizer->GetType() == type_equal)
    {
        // equal
        if (!GetTryValue(pass == 1 ? true : false, false))
        {
            return false;
        }
        if (g_pCompilerData->intMode == 2)
        {
            bFloat = true;
        }
        if (g_pCompilerData->bUndefined == false)
        {
            if (!ConAssign(bFloat, GetResult()))
            {
                return false;
            }
        }
    }
    else if (g_pElementizer->GetType() == type_leftb)
    {
        // enumx
        if (!GetTryValue(pass == 1 ? true : false, true))
        {
            return false;
        }
        if (!g_pElementizer->GetElement(type_rightb))
        {
            return false;
        }
        if (g_pCompilerData->bUndefined == false)
        {
            if (g_pCompilerData->enum_valid == 1)
            {
                int temp = g_pCompilerData->enum_value;
                g_pCompilerData->enum_value = GetResult() + temp;

                if (!ConAssign(bFloat, temp))
                {
                    return false;
                }
            }
        }
        else
        {
            g_pCompilerData->enum_valid = 0;
        }
    }
    else if ((g_pElementizer->GetType() == type_comma) ||
             (g_pElementizer->GetType() == type_end))
    {
        // enuma
        g_pElementizer->Backup();
        if (g_pCompilerData->enum_valid == 1)
        {
            int temp = g_pCompilerData->enum_value;
            g_pCompilerData->enum_value = 1 + temp;

            if (!ConAssign(bFloat, temp))
            {
                return false;
            }
        }
    }
    else
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eelcoeol];
        return false;
    }

    return true;
}

#define WORD_LENGTH (8 * sizeof(value))
int rol(unsigned int value, int places)
{
    return (value << places) | (value >> (WORD_LENGTH - places));
}

int ror(unsigned int value, int places)
{
    return (value >> places) | (value << (WORD_LENGTH - places));
}
#undef WORD_LENGTH

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
