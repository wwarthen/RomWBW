//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// CompileDatBlocks.cpp
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

void CompileDatBlocks_EnterInfo(int datstart, int objstart)
{
    g_pCompilerData->inf_start = datstart;
    g_pCompilerData->inf_finish = g_pElementizer->GetSourcePtr();
    g_pCompilerData->inf_data0 = objstart;
    g_pCompilerData->inf_data1 = g_pCompilerData->obj_ptr;
    g_pCompilerData->inf_data2 = 0;
    g_pCompilerData->inf_data3 = 0;
    g_pCompilerData->inf_data4 = 0;
    g_pCompilerData->inf_type = info_dat;
    EnterInfo();
}

void CompileDatBlocks_EnterSymbol(bool bResSymbol, int size)
{
    int value_1 = g_pCompilerData->obj_ptr;
    int value_2 = g_pCompilerData->cog_org;
    g_pCompilerData->inf_data0 = value_1;
    g_pCompilerData->inf_data1 = size;
    g_pCompilerData->inf_data2 = value_2;
    g_pCompilerData->inf_data3 = 0;
    g_pCompilerData->inf_data4 = 0;
    g_pCompilerData->inf_type = info_dat_symbol;
    EnterInfo();
    g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, bResSymbol ? type_dat_long_res : (size == 0 ? type_dat_byte : (size == 1 ? type_dat_word : type_dat_long)), value_1, value_2);
#ifdef RPE_DEBUG
    printf("dat: %s %08X %08X (%d)\n", g_pCompilerData->symbolBackup, value_1, value_2, size);
#endif
}

bool CompileDatBlocks_EnterByte(unsigned char value)
{
    if (EnterObj(value))
    {
        if (g_pCompilerData->orgx == 0)
        {
            g_pCompilerData->cog_org++;
        }
        return true;
    }
    return false;
}

bool CompileDatBlocks_Enter(int value, int count, int size)
{
    int numBytesPer = 1 << size;
    for (int i = 0; i < count; i++)
    {
        if(!CompileDatBlocks_EnterByte(value & 0x000000FF))
        {
            return false;
        }
        if (numBytesPer > 1)
        {
            if(!CompileDatBlocks_EnterByte((value >> 8) & 0x000000FF))
            {
                return false;
            }
        }
        if (numBytesPer > 2)
        {
            if(!CompileDatBlocks_EnterByte((value >> 16) & 0x000000FF))
            {
                return false;
            }
            if(!CompileDatBlocks_EnterByte((value >> 24) & 0x000000FF))
            {
                return false;
            }
        }
    }
    return true;
}

bool CompileDatBlocks_Advance(bool bSymbol, bool bResSymbol, int size)
{
    int testVal = (1 << size) - 1;
    for (;;)
    {
        if ((g_pCompilerData->obj_ptr & testVal) == 0)
        {
            if (bSymbol)
            {
                CompileDatBlocks_EnterSymbol(bResSymbol, size);
            }
            break;
        }
        if (!CompileDatBlocks_EnterByte(0)) // obj_ptr gets incremented in here
        {
            return false;
        }
    }

    return true;
}

bool CompileDatBlocks_Data(bool& bEof, int pass, bool bSymbol, bool& bResSymbol, int& size)
{
    size = g_pElementizer->GetValue() & 0x000000FF;
    int overrideSize = size;

    if (!CompileDatBlocks_Advance(bSymbol, bResSymbol, size))
    {
        return false;
    }

    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    if (g_pElementizer->GetType() == type_end)
    {
        return true;
    }

    while (!bEof)
    {
        // do we have a size override?
        if (g_pElementizer->GetType() == type_size)
        {
            // yes, get it
            overrideSize = g_pElementizer->GetValue() & 0x000000FF;
            if (overrideSize < size)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_sombl];
                return false;
            }
        }
        else
        {
            // no, backup
            g_pElementizer->Backup();
        }

        // get the value
        if (!GetTryValue(pass == 1 ? true : false, overrideSize == 2 ? false : true, true))
        {
            return false;
        }
        int value = GetResult();

        // get the count
        int count = 1;
        if (g_pElementizer->CheckElement(type_leftb))
        {
            if (!GetTryValue(true, true, true))
            {
                return false;
            }
            count = GetResult();
            if (!g_pElementizer->GetElement(type_rightb))
            {
                return false;
            }
        }

        // enter the value count times into the obj
        if (!CompileDatBlocks_Enter(value, count, overrideSize))
        {
            return false;
        }

        bool bComma = false;
        if (!GetCommaOrEnd(bComma))
        {
            return false;
        }
        if (!bComma)
        {
            break;
        }

        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
    }

    return true;
}

bool CompileDatBlocks_File(bool bSymbol, bool bResSymbol, int& size)
{
    size = 0; // force size to byte
    if (bSymbol)
    {
        CompileDatBlocks_EnterSymbol(bResSymbol, size);
    }

    int filenameStart = 0;
    int filenameFinish = 0;
    if (!GetFilename(filenameStart, filenameFinish))
    {
        return false;
    }

    // find the file in the dat_data array and copy it into obj
    for (int i = 0; i < g_pCompilerData->dat_files; i++)
    {
        if (strcmp(&(g_pCompilerData->dat_filenames[256*i]), g_pCompilerData->filename) == 0)
        {
            // copy dat data into obj (RPE: this should be optimized)
            for (int j = 0; j < g_pCompilerData->dat_lengths[i]; j++)
            {
                if (!CompileDatBlocks_EnterByte(g_pCompilerData->dat_data[g_pCompilerData->dat_offsets[i] + j]))
                {
                    return false;
                }
            }
            if (!g_pElementizer->GetElement(type_end))
            {
                return false;
            }
            return true;
        }
    }

    // file data not found
    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_idfnf];
    return false;
}

bool CompileDatBlocks_AsmDirective(bool bSymbol, bool& bResSymbol, int& size)
{
    size = 2; // force to long size

    int directive = g_pElementizer->GetValue() & 0x000000FF;
    switch (directive)
    {
        case dir_nop:
            {
                if (!CompileDatBlocks_Advance(bSymbol, bResSymbol, size))
                {
                    return false;
                }
                if (!g_pElementizer->GetElement(type_end))
                {
                    return false;
                }
                if (!CompileDatBlocks_Enter(0, 1, 2)) // enter a 0 long
                {
                    return false;
                }
                return true;
            }
            break;
        case dir_fit:
            {
                if (!CompileDatBlocks_Advance(bSymbol, bResSymbol, size))
                {
                    return false;
                }
                int fit = 0x1F0;
                if (!g_pElementizer->CheckElement(type_end))
                {
                    if (!GetTryValue(true, true, true))
                    {
                        return false;
                    }
                    fit = GetResult();
                    if (!g_pElementizer->GetElement(type_end))
                    {
                        return false;
                    }
                }
                fit <<= 2;
                if ((unsigned int)(g_pCompilerData->cog_org) > (unsigned int)fit)
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_oefl];
                    return false;
                }
                return true;
            }
            break;
        case dir_res:
            {
                if (g_pCompilerData->orgx != 0)
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_rinaiom];
                    return false;
                }
                bResSymbol = true;
                if (!CompileDatBlocks_Advance(bSymbol, bResSymbol, size))
                {
                    return false;
                }
                int resSize = 1;
                if (!g_pElementizer->CheckElement(type_end))
                {
                    if (!GetTryValue(true, true, true))
                    {
                        return false;
                    }
                    resSize = GetResult();
                    if (!g_pElementizer->GetElement(type_end))
                    {
                        return false;
                    }
                }
                resSize <<= 2;
                g_pCompilerData->cog_org += resSize;
                if (g_pCompilerData->cog_org > (0x1F0 * 4))
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_oexl];
                    return false;
                }
                return true;
            }
            break;
        case dir_org:
            {
                if (!CompileDatBlocks_Advance(bSymbol, bResSymbol, size))
                {
                    return false;
                }
                int newOrg = 0;
                if (!g_pElementizer->CheckElement(type_end))
                {
                    if (!GetTryValue(true, true, true))
                    {
                        return false;
                    }
                    newOrg = GetResult();
                    if (!g_pElementizer->GetElement(type_end))
                    {
                        return false;
                    }
                }
                if (newOrg > 0x1F0)
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_oexl];
                    return false;
                }
                g_pCompilerData->cog_org = newOrg << 2;
                g_pCompilerData->orgx = 0;
                return true;
            }
            break;
    }

    if (!CompileDatBlocks_Advance(bSymbol, bResSymbol, size))
    {
        return false;
    }
    if (!g_pElementizer->GetElement(type_end))
    {
        return false;
    }
    g_pCompilerData->cog_org = 0;
    g_pCompilerData->orgx = 1;
    return true;
}

bool CompileDatBlocks_ValidateCallSymbol(bool bIsRet, char* pSymbol)
{
    if (!g_pElementizer->FindSymbol(pSymbol))
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eads];
        return false;
    }
    if (g_pElementizer->GetType() == type_undefined)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[bIsRet ? error_urs : error_us];
        return false;
    }
    if (g_pElementizer->GetType() < type_dat_byte || g_pElementizer->GetType() > type_dat_long_res)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_eads];
        return false;
    }

    // the offset to the label symbol is in second symbol value
    int value = g_pElementizer->GetValue2();

    // make sure it's long aligned
    if (value & 0x03)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[bIsRet ? error_rainl : error_ainl];
        return false;
    }
    // make sure is in range
    value >>= 2;
    if (value >= 0x1F0)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[bIsRet ? error_raioor : error_aioor];
        return false;
    }

    return true;
}

bool CompileDatBlocks_AsmInstruction(bool& bEof, int pass, bool bSymbol, bool bResSymbol, int& size, unsigned char condition)
{
    size = 2; // force to long size
    if (!CompileDatBlocks_Advance(bSymbol, bResSymbol, size))
    {
        return false;
    }

    int opcode = g_pElementizer->GetValue() & 0x000000FF;
    // handle dual type entries and also AND and OR (which are the only type_binary that will get here)
    if (g_pElementizer->IsDual() || g_pElementizer->GetType() == type_binary)
    {
        opcode = g_pElementizer->GetAsm() & 0x000000FF;
    }

    unsigned int instruction = opcode << 8;

    if (opcode & 0x80) // sys instruction
    {
        instruction = 0x03 << 8;
    }

    instruction |= condition;

    if (opcode & 0x40) // set WR?
    {
        instruction |= 0x20;
    }

    instruction <<= 18;  // justify the instruction (s & d will go in lower 18 bits)

    if (opcode & 0x80) // sys instruction
    {
        instruction |= 0x00400000; // set immediate
        instruction |= (opcode & 0x07); // set s

        // get d
        if (!GetTryValue(pass == 1 ? true : false, true, true))
        {
            return false;
        }
        int d = GetResult();
        if (d > 0x1FF)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_drcex];
            return false;
        }
        instruction	|= (d << 9); // set d
    }
    else if (opcode == 0x15) // call?
    {
        // make 'jmpret label_ret, #label'
        instruction ^= 0x08C00000;
        if (!g_pElementizer->GetElement(type_pound))
        {
            return false;
        }
        int length = 0;
        if (!GetSymbol(&length))
        {
            return false;
        }
        if (length > 0)
        {
            if (length > symbol_limit - 4)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_csmnexc];
                return false;
            }
            char* pSymbol = g_pElementizer->GetCurrentSymbol();
            if (pass == 1)
            {
                if (!CompileDatBlocks_ValidateCallSymbol(false, pSymbol))
                {
                    return false;
                }
            }
            instruction |= ((g_pElementizer->GetValue2() & 0x7FF) >> 2); // set #label

            pSymbol[length] = '_';
            pSymbol[length+1] = 'R';
            pSymbol[length+2] = 'E';
            pSymbol[length+3] = 'T';
            pSymbol[length+4] = 0;
            if (pass == 1)
            {
                if (!CompileDatBlocks_ValidateCallSymbol(true, pSymbol))
                {
                    return false;
                }
            }
            instruction |= (((g_pElementizer->GetValue2() & 0x7FF) >> 2) << 9); // set label_ret
        }
        else
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_eads];
            return false;
        }
    }
    else if (opcode == 0x16) // ret?
    {
        instruction ^= 0x04400000; // make 'jmp #0'
    }
    else if (opcode == 0x17) // jmp?
    {
        // for jmp, we only get s, there is no d

        // see if it's an immediate value for s
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (g_pElementizer->GetType() == type_pound)
        {
            instruction |= 0x00400000;
        }
        else
        {
            g_pElementizer->Backup();
        }

        // get s
        if (!GetTryValue(pass == 1 ? true : false, true, true))
        {
            return false;
        }
        int s = GetResult();

        // make sure it's in range
        if (s > 0x1FF)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_srccex];
            return false;
        }

        // set s on instruction
        instruction |= s;
    }
    else // regular instruction get both d and s
    {
        // get d
        if (!GetTryValue(pass == 1 ? true : false, true, true))
        {
            return false;
        }
        int d = GetResult();

        // make sure it's in range
        if (d > 0x1FF)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_drcex];
            return false;
        }

        // set d on instruction
        instruction	|= (d << 9);

        if (!g_pElementizer->GetElement(type_comma))
        {
            return false;
        }

        // see if it's an immediate value for s
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (g_pElementizer->GetType() == type_pound)
        {
            instruction |= 0x00400000;
        }
        else
        {
            g_pElementizer->Backup();
        }

        // get s
        if (!GetTryValue(pass == 1 ? true : false, true, true))
        {
            return false;
        }
        int s = GetResult();

        // make sure it's in range
        if (s > 0x1FF)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_srccex];
            return false;
        }

        // set s on instruction
        instruction |= s;
    }

    // check for effects
    bool bAfterComma = false;
    while (!bEof)
    {
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (g_pElementizer->GetType() == type_asm_effect)
        {
            int effectValue = g_pElementizer->GetValue();

            // don't allow wr/nr for r/w instructions
            if ((effectValue & 0x09) && (instruction >> 26) <= 2)
            {
                g_pCompilerData->error = true;
                g_pCompilerData->error_msg = g_pErrorStrings[error_micuwn];
                return false;
            }

            // apply effect to instruction
            int temp = (effectValue & 0x38) << 20;
            instruction |= temp;
            instruction ^= temp;
            instruction |= ((effectValue & 0x07) << 23);

            bool bComma = false;
            if (!GetCommaOrEnd(bComma))
            {
                return false;
            }
            if (!bComma)
            {
                // got end, done with effects
                break;
            }

            // got a comma, expecting another effect
            bAfterComma = true;
        }
        else if (bAfterComma)
        {
            // expected another effect after the comma
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_eaasme];
            return false;
        }
        else if (g_pElementizer->GetType() != type_end)
        {
            // if it wasn't an effect the first time in then it should be an end
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_eaaeoeol];
            return false;
        }
        else
        {
            // we get here if we got no effect and got the proper end
            break;
        }
    }
    // enter instruction as 1 long
    if (!CompileDatBlocks_Enter(instruction, 1, 2))
    {
        return false;
    }

    return true;
}

bool CompileDatBlocks_CheckInstruction()
{
    if (g_pElementizer->GetType() == type_asm_inst || g_pElementizer->IsDual())
    {
        return true;
    }
    if (g_pElementizer->GetType() == type_binary)
    {
        if (g_pElementizer->GetOpType() == op_log_and || g_pElementizer->GetOpType() == op_log_or)
        {
            return true;
        }
    }
    return false;
}

bool CompileDatBlocks_AsmCondition(bool& bEof, int pass, bool bSymbol, bool bResSymbol, int& size)
{
    unsigned char condition = (unsigned char)(g_pElementizer->GetValue() & 0x000000FF);
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }
    if (CompileDatBlocks_CheckInstruction())
    {
        return CompileDatBlocks_AsmInstruction(bEof, pass, bSymbol, bResSymbol, size, condition);
    }

    g_pCompilerData->error = true;
    g_pCompilerData->error_msg = g_pErrorStrings[error_eaasmi];
    return false;
}

bool CompileDatBlocks()
{
    int infoflag = 0;
    int ptr = g_pCompilerData->obj_ptr;
    int datstart = 0;
    int objstart = 0;

    for (int pass = 0; pass < 2; pass++)
    {
        g_pCompilerData->obj_ptr = ptr;
        g_pCompilerData->asm_local = 0;
        g_pCompilerData->cog_org = 0;
        g_pCompilerData->orgx = 0;
        int size = 0;

        bool bEof = false;
        g_pElementizer->Reset();

        while(!bEof)
        {
            if(g_pElementizer->GetNextBlock(block_dat, bEof))
            {
                if (bEof)
                {
                    break;
                }

                datstart = g_pCompilerData->source_start;
                objstart = g_pCompilerData->obj_ptr;

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
                    infoflag = 1;
                    if (g_pElementizer->GetType() == type_end)
                    {
                        continue;
                    }

                    g_pCompilerData->inf_start = g_pCompilerData->source_start;

                    // clear symbol flags
                    bool bLocal = false;
                    bool bSymbol = false;
                    bool bResSymbol = false;

                    if (!CheckLocal(bLocal)) // bLocal will be set if it is a local
                    {
                        return false;
                    }

                    g_pCompilerData->inf_finish = g_pCompilerData->source_finish;

                    if (g_pElementizer->GetType() == type_undefined) // undefined here means it's a symbol
                    {
                        if (!bLocal)
                        {
                            if (!IncrementAsmLocal())
                            {
                                return false;
                            }
                        }

                        bSymbol = true;
                        g_pElementizer->BackupSymbol();

                        if (!g_pElementizer->GetNext(bEof))
                        {
                            return false;
                        }
                        if (g_pElementizer->GetType() == type_end)
                        {
                            if (bSymbol)
                            {
                                CompileDatBlocks_EnterSymbol(bResSymbol, size);
                            }
                            continue;
                        }
                    }
                    else if (g_pElementizer->GetType() == type_dat_byte ||
                             g_pElementizer->GetType() == type_dat_word ||
                             g_pElementizer->GetType() == type_dat_long ||
                             g_pElementizer->GetType() == type_dat_long_res)
                    {
                        if (!bLocal)
                        {
                            if (!IncrementAsmLocal())
                            {
                                return false;
                            }
                        }
                        if (pass == 0)
                        {
                            g_pCompilerData->error = true;
                            g_pCompilerData->error_msg = g_pErrorStrings[error_siad];
                            return false;
                        }
                        if (!g_pElementizer->GetNext(bEof))
                        {
                            return false;
                        }
                        if (g_pElementizer->GetType() == type_end)
                        {
                            continue;
                        }
                    }

                    if (g_pElementizer->GetType() == type_size)
                    {
                        if (!CompileDatBlocks_Data(bEof, pass, bSymbol, bResSymbol, size))
                        {
                            return false;
                        }
                        continue;
                    }
                    else if (g_pElementizer->GetType() == type_file)
                    {
                        if (!CompileDatBlocks_File(bSymbol, bResSymbol, size))
                        {
                            return false;
                        }
                        continue;
                    }
                    else if (g_pElementizer->GetType() == type_asm_dir)
                    {
                        if (!CompileDatBlocks_AsmDirective(bSymbol, bResSymbol, size))
                        {
                            return false;
                        }
                        continue;
                    }
                    else if (g_pElementizer->GetType() == type_asm_cond)
                    {
                        if (!CompileDatBlocks_AsmCondition(bEof, pass, bSymbol, bResSymbol, size))
                        {
                            return false;
                        }
                        continue;
                    }
                    else if (CompileDatBlocks_CheckInstruction())
                    {
                        if (!CompileDatBlocks_AsmInstruction(bEof, pass, bSymbol, bResSymbol, size, if_always))
                        {
                            return false;
                        }
                        continue;
                    }

                    if (g_pElementizer->GetType() == type_block)
                    {
                        g_pElementizer->Backup();
                        if (pass == 0)
                        {
                            CompileDatBlocks_EnterInfo(datstart, objstart);
                        }
                        break;
                    }
                    else
                    {
                        g_pCompilerData->error = true;
                        g_pCompilerData->error_msg = g_pErrorStrings[error_eaunbwlo];
                        return false;
                    }
                }
            }
            else
            {
                return false;
            }
        }

        if (infoflag != 0 && pass == 0)
        {
            CompileDatBlocks_EnterInfo(datstart, objstart);
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
