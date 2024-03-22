//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// PropellerCompiler.cpp
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
#include "UnusedMethodUtils.h"

//////////////////////////////////////////
// declarations for internal functions
// some of these are defined in other files (where noted)
//

bool CompileDevBlocks();
bool CompileConBlocks(int pass);
bool CompileSubBlocksId();
bool CompileObjBlocksId();
bool CompileDatBlocksFileNames();

bool CompileObjSymbols();
bool CompileVarBlocks();
extern bool CompileDatBlocks(); // in CompileDatBlocks.cpp
bool CompileSubBlocks();
bool CompileObjBlocks();
bool DistillObjBlocks();
bool CompileFinal();
bool PointToFirstCon();
bool DetermineStack();
bool DetermineClock();
bool DetermineDebug();
bool CompileDoc();

extern bool DistillObjects(); // in DistillObjects.cpp
extern bool CompileTopBlock(); // in InstructionBlockCompiler.cpp

// globals used by the compiler
CompilerDataInternal* g_pCompilerData = 0;
SymbolEngine* g_pSymbolEngine         = 0;
Elementizer* g_pElementizer           = 0;

//////////////////////////////////////////
// exported functions
//

// Call this before using Compile1() & Compile2()
// the CompilerData pointer it returns is what Compile1() and Compile2() use/fill.
CompilerData* InitStruct()
{
    g_pCompilerData = new CompilerDataInternal;
    // wipe the compiler data struct with 0's
    memset(g_pCompilerData, 0, sizeof(CompilerDataInternal));

    g_pSymbolEngine = new SymbolEngine;
    g_pElementizer = new Elementizer(g_pCompilerData, g_pSymbolEngine);

    return g_pCompilerData;
}

void Cleanup()
{
    delete g_pElementizer;
    g_pElementizer = 0;
    delete g_pSymbolEngine;
    g_pSymbolEngine = 0;
    delete g_pCompilerData;
    g_pCompilerData = 0;
}

// Usage:
//
//  Call Compile1
//  Load any obj files
//  Call Compile2
//  Save new obj file
//
// OBJ structure:
//
//              word    varsize, pgmsize                ;variable and program sizes
//
//          0:  word    objsize                         ;object size (w/o sub-objects)
//              byte    objindex>>2, objcount           ;sub-object start index and count
//          4:  word    PUBn offset, PUBn locals        ;index to PUBs (multiple)
//              word    PRIn offset, PRIn locals        ;index to PRIs (multiple)
//   objindex:  word    OBJn offset, OBJn var offset    ;index to OBJs (multiple)
//              byte    DAT data...                     ;DAT data
//              byte    PUB data...                     ;PUB data
//              byte    PRI data...                     ;PRI data
//    objsize:
//              long    OBJ data...                     ;OBJ data (sub-objects)
//    pgmsize:
//              byte    checksum                        ;checksum reveals language_version
//              byte    'PUBn', parameters              ;PUB names and parameters (0..15)
//              byte    'CONn', 16, values              ;CON names and values
//

const char* Compile1()
{
    g_pElementizer->Reset();
    g_pSymbolEngine->Reset();
    g_pCompilerData->pubcon_list_size = 0;
    g_pCompilerData->list_length = 0;
    g_pCompilerData->doc_length = 0;
    g_pCompilerData->doc_mode = false;
    g_pCompilerData->info_count = 0;

    // reset obj pointer based on compile_mode
    if (g_pCompilerData->compile_mode == 0)
    {
        g_pCompilerData->obj_ptr = 4;
    }
    else
    {
        g_pCompilerData->obj_ptr = 0;
    }

    SetPrint(g_pCompilerData->list, g_pCompilerData->list_limit);

    if (!CompileDevBlocks())
    {
        return g_pCompilerData->error_msg;
    }
    if (!CompileConBlocks(0))
    {
        return g_pCompilerData->error_msg;
    }
    if (!CompileSubBlocksId())
    {
        return g_pCompilerData->error_msg;
    }
    if (!CompileObjBlocksId())
    {
        return g_pCompilerData->error_msg;
    }
    if (!CompileDatBlocksFileNames())
    {
        return g_pCompilerData->error_msg;
    }

    g_pCompilerData->source_start = 0;
    g_pCompilerData->source_finish = 0;
    return 0;
}

const char* Compile2()
{
    if (!CompileObjSymbols())
    {
        return g_pCompilerData->error_msg;
    }
    if (!CompileConBlocks(1))
    {
        return g_pCompilerData->error_msg;
    }
    if (!CompileVarBlocks())
    {
        return g_pCompilerData->error_msg;
    }
    if (!CompileDatBlocks())
    {
        return g_pCompilerData->error_msg;
    }

    if (!g_pCompilerData->bDATonly)
    {
        if (!CompileSubBlocks())
        {
            return g_pCompilerData->error_msg;
        }
    }

    if (!CompileObjBlocks())
    {
        return g_pCompilerData->error_msg;
    }

    if (!g_pCompilerData->bDATonly)
    {
        if (!DistillObjBlocks())
        {
            return g_pCompilerData->error_msg;
        }
    }

    if (!CompileFinal())
    {
        return g_pCompilerData->error_msg;
    }

    if (!g_pCompilerData->bDATonly)
    {
        if (!PointToFirstCon())
        {
            return g_pCompilerData->error_msg;
        }
        if (!DetermineStack())
        {
            return g_pCompilerData->error_msg;
        }
        if (!DetermineClock())
        {
            return g_pCompilerData->error_msg;
        }
        if (!DetermineDebug())
        {
            return g_pCompilerData->error_msg;
        }

        if (!PrintObj())
        {
            return g_pCompilerData->error_msg;
        }

        g_pCompilerData->list_length = g_pCompilerData->print_length;

        if (g_pCompilerData->doc_limit > 0)
        {
            SetPrint(g_pCompilerData->doc, g_pCompilerData->doc_limit);

            if (!CompileDoc())
            {
                return g_pCompilerData->error_msg;
            }
            g_pCompilerData->doc_length = g_pCompilerData->print_length;
        }
        else
        {
            g_pCompilerData->doc_length = 0;
        }
    }

    g_pCompilerData->source_start = 0;
    g_pCompilerData->source_finish = 0;
    return 0;
}

bool GetErrorInfo(int& lineNumber, int& column, int& offsetToStartOfLine, int& offsetToEndOfLine, int& offendingItemStart, int& offendingItemEnd)
{
    if (g_pCompilerData && g_pCompilerData->error)
    {
        lineNumber = g_pElementizer->GetCurrentLineNumber(offsetToStartOfLine, offsetToEndOfLine);
        column = g_pElementizer->GetColumn();
        offendingItemStart = g_pCompilerData->source_start;
        offendingItemEnd = g_pCompilerData->source_finish;
        return true;
    }

    return false;
}

//////////////////////////////////////////
// internal function definitions
//

bool CompileDevBlocks()
{
    g_pCompilerData->pre_files = 0;
    g_pCompilerData->arc_files = 0;
    int index = 0;

    bool bEof = false;
    g_pElementizer->Reset();

    while (!bEof)
    {
        if(g_pElementizer->GetNextBlock(block_dev, bEof))
        {
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
                if (g_pElementizer->GetType() == type_precompile)
                {
                    if (!AddFileName(g_pCompilerData->pre_files,
                                     index,
                                     g_pCompilerData->pre_filenames,
                                     g_pCompilerData->pre_name_start,
                                     g_pCompilerData->pre_name_finish,
                                     error_loxupfe))
                    {
                        return false;
                    }
                    if (!g_pElementizer->GetElement(type_end))
                    {
                        return false;
                    }
                    continue;
                }
                else if (g_pElementizer->GetType() == type_archive)
                {
                    if (!AddFileName(g_pCompilerData->arc_files,
                                     index,
                                     g_pCompilerData->arc_filenames,
                                     g_pCompilerData->arc_name_start,
                                     g_pCompilerData->arc_name_finish,
                                     error_loxuafe))
                    {
                        return false;
                    }
                    if (!g_pElementizer->GetElement(type_end))
                    {
                        return false;
                    }
                    continue;
                }
                else if (g_pElementizer->GetType() != type_block)
                {
                    // we got an element that wasn't a precompile or archive or the next block
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_epoa];
                    return false;
                }

                // if we get here, then the element we got was of type_block

                // finished with this block, backup off the next block
                g_pElementizer->Backup();
                break;
            }
        }
        else
        {
            return false;
        }
    }

    return true;
}

bool CompileConBlocks(int pass)
{
    bool bEof = false;
    g_pElementizer->Reset();

    while (!bEof)
    {
        g_pCompilerData->enum_valid = 1;
        g_pCompilerData->enum_value = 0;

        bool bFindNextConBlock = false;
        while (!bEof && !bFindNextConBlock)
        {
            if (!g_pElementizer->GetNext(bEof))
            {
                return false;
            }
            if (g_pElementizer->GetType() == type_end)
            {
                continue;
            }

            while(!bEof)
            {
                g_pCompilerData->assign_flag = 1;

                if ((g_pElementizer->GetType() == type_con) ||
                    (g_pElementizer->GetType() == type_con_float))
                {
                    // constant
                    if (pass == 0)
                    {
                        g_pCompilerData->error = true;
                        g_pCompilerData->error_msg = g_pErrorStrings[error_eaucnop];
                        return false;
                    }
                    else
                    {
                        g_pCompilerData->assign_flag = 0;
                        g_pCompilerData->assign_type = g_pElementizer->GetType();
                        g_pCompilerData->assign_value = g_pElementizer->GetValue();
                    }

                    if (!HandleConSymbol(pass))
                    {
                        return false;
                    }
                }
                else if (g_pElementizer->GetType() == type_undefined)
                {
                    if (!HandleConSymbol(pass))
                    {
                        return false;
                    }
                }
                else if (g_pElementizer->GetType() == type_pound)
                {
                    // pound
                    if (!GetTryValue(pass == 1 ? true : false, true))
                    {
                        return false;
                    }
                    if (g_pCompilerData->bUndefined == false)
                    {
                        g_pCompilerData->enum_valid = 1;
                        g_pCompilerData->enum_value = GetResult();
                    }
                    else
                    {
                        g_pCompilerData->enum_valid = 0;
                    }
                }
                else if (g_pElementizer->GetType() == type_block)
                {
                    // hit next block, so backup and search for next con block
                    g_pElementizer->Backup();
                    bFindNextConBlock = true;
                    break;
                }
                else
                {
                    // we got an element that isn't valid in a con block
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_eaucnop];
                    return false;
                }

                bool bComma = false;
                if (!GetCommaOrEnd(bComma))
                {
                    return false;
                }
                if (bComma == false)
                {
                    break;
                }
                if(!g_pElementizer->GetNext(bEof))
                {
                    return false;
                }
            }
        }

        if(!bEof)
        {
            if(!g_pElementizer->GetNextBlock(block_con, bEof))
            {
                return false;
            }
        }
    }
    return true;
}

bool CompileSubBlocksId_Compile(int blockType, bool &bFirst, int &nMethodIndex)
{
    bool bEof = false;
    g_pElementizer->Reset();

    while (!bEof)
    {
        if(g_pElementizer->GetNextBlock(blockType, bEof))
        {
            if (!bEof)
            {
                char params = 0;
                int locals = 0;

                if (!g_pElementizer->GetNext(bEof))
                {
                    return false;
                }
                if (g_pElementizer->GetType() == type_end || g_pElementizer->GetType() != type_undefined)
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_eausn];
                    return false;
                }

                // save a copy of the symbol
                g_pElementizer->BackupSymbol();

                if (g_pCompilerData->obj_ptr < 256*4)
                {
                    params = 0;

                    // are there parameters?
                    if (g_pElementizer->CheckElement(type_left))
                    {
                        // if so, then count them
                        while (!bEof)
                        {
                            if (!g_pElementizer->GetNext(bEof))
                            {
                                return false;
                            }
                            if (g_pElementizer->GetType() == type_undefined)
                            {
                                if (params < 15)
                                {
                                    params++;
                                    bool bComma = false;
                                    if (!GetCommaOrRight(bComma))
                                    {
                                        // error was set inside GetCommaOrRight()
                                        return false;
                                    }
                                    if (!bComma)
                                    {
                                        // we got the ')' so fall out of counting parameters
                                        break;
                                    }
                                }
                                else
                                {
                                    // too many parameters
                                    g_pCompilerData->error = true;
                                    g_pCompilerData->error_msg = g_pErrorStrings[error_loxpe];
                                    return false;
                                }
                            }
                            else
                            {
                                // a parameter used an already defined symbol name
                                g_pCompilerData->error = true;
                                g_pCompilerData->error_msg = g_pErrorStrings[error_eaupn];
                                return false;
                            }
                        }
                    }
                    // is there a result defined
                    if (g_pElementizer->CheckElement(type_colon))
                    {
                        // yes, so read the name
                        if (!g_pElementizer->GetNext(bEof))
                        {
                            return false;
                        }
                        if (g_pElementizer->GetType() != type_undefined &&
                            g_pElementizer->GetType() != type_loc_long) // this allows for 'RESULT' (ignores it)
                        {
                            // result name was not unique
                            g_pCompilerData->error = true;
                            g_pCompilerData->error_msg = g_pErrorStrings[error_eaurn];
                            return false;
                        }
                    }
                    // check for locals
                    locals = 0;
                    bool bPipe = false;
                    if(!GetPipeOrEnd(bPipe))
                    {
                        // error was set inside GetPipeOrEnd()
                        return false;
                    }
                    if (bPipe)
                    {
                        // count locals (handling arrays)
                        while (!bEof)
                        {
                            if (!g_pElementizer->GetNext(bEof))
                            {
                                return false;
                            }
                            if (g_pElementizer->GetType() == type_undefined)
                            {
                                // is it an array?
                                if (g_pElementizer->CheckElement(type_leftb))
                                {
                                    // it is, so read the index
                                    if (!GetTryValue(true, true))
                                    {
                                        return false;
                                    }
                                    int value = GetResult();
                                    value <<= 2;
                                    if (value > loc_limit)
                                    {
                                        // too many locals
                                        g_pCompilerData->error = true;
                                        g_pCompilerData->error_msg = g_pErrorStrings[error_loxlve];
                                        return false;
                                    }
                                    locals += value;
                                    if (locals <= loc_limit)
                                    {
                                        if (!g_pElementizer->GetElement(type_rightb))
                                        {
                                            // error was set inside GetElement()
                                            return false;
                                        }
                                    }
                                }
                                else
                                {
                                    locals += 4;
                                }
                                if (locals > loc_limit)
                                {
                                    // too many locals
                                    g_pCompilerData->error = true;
                                    g_pCompilerData->error_msg = g_pErrorStrings[error_loxlve];
                                    return false;
                                }
                                bool bComma = false;
                                if (!GetCommaOrEnd(bComma))
                                {
                                    // error was set inside GetCommaOrEnd()
                                    return false;
                                }
                                if (!bComma)
                                {
                                    break;
                                }
                            }
                            else
                            {
                                // a local used an already defined symbol name
                                g_pCompilerData->error = true;
                                g_pCompilerData->error_msg = g_pErrorStrings[error_eauvn];
                                return false;
                            }
                        }
                    }

                    if (!g_pCompilerData->bFinalCompile || IsMethodUsed(g_pCompilerData->current_filename, nMethodIndex))
                    {
                        // enter sub symbol
                        int value = params;
                        value <<= 8;
                        value |= (g_pCompilerData->obj_ptr >> 2) & 0xFF;
                        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, type_sub, value, blockType);
#ifdef RPE_DEBUG
                        printf("Pub/Pri %s %d (%d, %d)\n", g_pCompilerData->symbolBackup, value, params, g_pCompilerData->obj_ptr);
#endif
                        if (!g_pCompilerData->bDATonly)
                        {
                            // enter locals count into index (shifted up 16 to leave space for the sub offset which will be fixed up later)
                            EnterObjLong(locals<<16);
                        }

                        if (blockType == block_pub)
                        {
                            if (!AddSymbolToPubConList())
                            {
                                return false;
                            }
                            if (!AddPubConListByte(params))
                            {
                                return false;
                            }
                        }
                        if (bFirst == false)
                        {
                            g_pCompilerData->first_pub_parameters = params;
                            bFirst = true;
                        }
                    }
                    nMethodIndex++;
                }
                else
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_loxspoe];
                    return false;
                }
            }
        }
        else
        {
            return false;
        }
    }

    return true;
}

bool CompileSubBlocksId()
{
    bool bFirst = false;
    int nMethodIndex = 0;
    if (!CompileSubBlocksId_Compile(block_pub, bFirst, nMethodIndex))
    {
        return false;
    }
    if (bFirst == false && g_pCompilerData->compile_mode == 0)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_nprf];
        g_pCompilerData->source_start = g_pCompilerData->source_finish;
        return false;
    }
    if (!CompileSubBlocksId_Compile(block_pri, bFirst, nMethodIndex))
    {
        return false;
    }

    return true;
}

bool CompileObjBlocksId()
{
    g_pCompilerData->obj_start = g_pCompilerData->obj_ptr;
    g_pCompilerData->obj_count = 0;
    g_pCompilerData->obj_files = 0;
    g_pCompilerData->unused_obj_files = 0;

    bool bEof = false;
    g_pElementizer->Reset();

    while (!bEof)
    {
        if(g_pElementizer->GetNextBlock(block_obj, bEof))
        {
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
                else if (g_pElementizer->GetType() == type_undefined)
                {
                    // save a copy of the symbol
                    g_pElementizer->BackupSymbol();

                    int instanceCount = 1;

                    // see if there is a count
                    if (g_pElementizer->CheckElement(type_leftb))
                    {
                        // get the count value and validate it
                        if (!GetTryValue(true, true))
                        {
                            return false;
                        }
                        instanceCount = GetResult();
                        if (instanceCount < 1 || instanceCount > 255)
                        {
                            g_pCompilerData->error = true;
                            g_pCompilerData->error_msg = g_pErrorStrings[error_ocmbf1tx];
                            return false;
                        }
                        // get the closing bracket
                        if (!g_pElementizer->GetElement(type_rightb))
                        {
                            return false;
                        }
                    }

                    // must have the colon
                    if (!g_pElementizer->GetElement(type_colon))
                    {
                        return false;
                    }

                    int objFileIndex = 0;
                    // now get the filename
                    if (!AddFileName(g_pCompilerData->obj_files,
                                     objFileIndex,
                                     g_pCompilerData->obj_filenames,
                                     g_pCompilerData->obj_name_start,
                                     g_pCompilerData->obj_name_finish,
                                     error_loxuoe))
                    {
                        return false;
                    }
                    if (!g_pCompilerData->bFinalCompile || IsObjectUsed(&g_pCompilerData->obj_filenames[objFileIndex<<8]))
                    {
                        // is it a new obj?
                        if (objFileIndex <= (g_pCompilerData->obj_files - 1))
                        {
                            // reset instances
                            g_pCompilerData->obj_instances[objFileIndex] = 0;
                        }

                        // enter obj symbol
                        int value = objFileIndex;
                        value <<= 8;
                        value |= (g_pCompilerData->obj_ptr >> 2) & 0xFF;
                        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, type_obj, value);
#ifdef RPE_DEBUG
                        printf("Obj %s %d (%d, %d)\n", g_pCompilerData->symbolBackup, value, instanceCount, g_pCompilerData->obj_ptr);
#endif

                        for (int i=0; i < instanceCount; i++)
                        {
                            if (g_pCompilerData->obj_ptr < 256*4)
                            {
                                // enter object index into table
                                EnterObjLong(objFileIndex);
                                g_pCompilerData->obj_count++;
                            }
                            else
                            {
                                g_pCompilerData->error = true;
                                g_pCompilerData->error_msg = g_pErrorStrings[error_loxspoe];
                                return false;
                            }
                        }

                        // accumulate instances
                        g_pCompilerData->obj_instances[objFileIndex] += instanceCount;
                    }
                    else
                    {
                        strcpy(&(g_pCompilerData->obj_unused[g_pCompilerData->unused_obj_files<<8]), &(g_pCompilerData->obj_filenames[objFileIndex<<8]));
                        int value = g_pCompilerData->unused_obj_files | 0x40;
                        value <<= 8;
                        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, type_obj, value);
                        g_pCompilerData->unused_obj_files++;
                        g_pCompilerData->obj_files--;
                    }

                    if (!g_pElementizer->GetElement(type_end))
                    {
                        return false;
                    }
                }
                else if (g_pElementizer->GetType() == type_block)
                {
                    g_pElementizer->Backup();
                    break;
                }
                else
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_eauon];
                    return false;
                }
            }
        }
        else
        {
            return false;
        }
    }
    return true;
}

bool CompileDatBlocksFileNames()
{
    g_pCompilerData->dat_files = 0;
    int index = 0;

    bool bEof = false;
    g_pElementizer->Reset();

    while (!bEof)
    {
        if(g_pElementizer->GetNextBlock(block_dat, bEof))
        {
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
                if (g_pElementizer->GetType() == type_file)
                {
                    if (!AddFileName(g_pCompilerData->dat_files,
                                     index,
                                     g_pCompilerData->dat_filenames,
                                     g_pCompilerData->dat_name_start,
                                     g_pCompilerData->dat_name_finish,
                                     error_loxudfe))
                    {
                        return false;
                    }
                    if (!g_pElementizer->GetElement(type_end))
                    {
                        return false;
                    }
                    continue;
                }
                else if (g_pElementizer->GetType() != type_block)
                {
                    continue;
                }

                // if we get here, then the element we got was of type_block

                // finished with this block, backup off the next block
                g_pElementizer->Backup();
                break;
            }
        }
        else
        {
            return false;
        }
    }

    return true;
}

void CompileObjSymbol_BadObj(int nFile)
{
    g_pCompilerData->print_length = 0;
    PrintString("Invalid object file ");
    char* pFilename = &(g_pCompilerData->obj_filenames[nFile]);
    PrintString(pFilename);
    PrintString(".OBJ");
    PrintChr(0);
    g_pCompilerData->error_msg = g_pCompilerData->list;
}

bool CompileObjSymbols()
{
    int nFile;
    for (nFile = 0; nFile < g_pCompilerData->obj_files; nFile++)
    {
        unsigned char* pData = &(g_pCompilerData->obj_data[g_pCompilerData->obj_offsets[nFile]]);

        // do checksum of obj
        unsigned char uChecksum = 0;
        for (int i = 0; i < g_pCompilerData->obj_lengths[nFile]; i++)
        {
            uChecksum += pData[i];
        }

        unsigned char* pDataEnd = pData + g_pCompilerData->obj_lengths[nFile];

        short vsize = pData[0] | ((short)pData[1] << 8);// *((short*)(&pData[0]));
        short psize = pData[2] | ((short)pData[3] << 8);// *((short*)(&pData[2]));
        pData += 4; // move past vsize/psize

        // validate checksum and that vsize/psize are valid long addresses
        if ((!g_pCompilerData->bDATonly && uChecksum != language_version) || vsize & 0x03 || psize & 0x03)
        {
            CompileObjSymbol_BadObj(nFile);
            return false;
        }

        // skip obj bytes and checksum
        pData += psize;
        pData++;

        // go thru symbols validating them and adding them to the symbol table
        int nPub = 1;
        while (pData < pDataEnd)
        {
            for (int i = 0; i < symbol_limit+1; i++)
            {
                if (!CheckWordChar((char)(*pData)))
                {
                    CompileObjSymbol_BadObj(nFile);
                    return false;
                }
                g_pCompilerData->symbolBackup[i] = (char)(*pData);
                pData++;
                if (pData[0] < 18) // 0 to 15 = pub param count, 16 and 17 are constants
                {
                    g_pCompilerData->symbolBackup[i+1] = (char)(nFile+1);
                    g_pCompilerData->symbolBackup[i+2] = 0;
                    if (pData[0] < 16) // handle objpub symbol
                    {
                        int value = nPub | ((int)pData[0] << 8);
                        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, type_objpub, value);
#ifdef RPE_DEBUG
                        printf("objpub: %s %d \n", g_pCompilerData->symbolBackup, value);
#endif
                        nPub++;
                        pData++; // adjust pointer to after param count
                        break;
                    }
                    else	// handle objcon or objcon_float symbol
                    {
                        int value = (int)pData[1] | ((int)pData[2] << 8)  | ((int)pData[3] << 16)  | ((int)pData[4] << 24);// *((int*)(&pData[1]));
                        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, (pData[0] == 16) ? type_objcon : type_objcon_float, value);
#ifdef RPE_DEBUG
                        float fValue = *((float*)(&value));
                        printf("objcon: %s %d %f \n", g_pCompilerData->symbolBackup, value, fValue);
#endif
                        pData+=5; // adjust pointer to after value
                        break;
                    }
                }
            }
            if (pData > pDataEnd)
            {
                CompileObjSymbol_BadObj(nFile);
                return false;
            }
        }
    }

    // now add any CON symbols from unused objects
    for (int nUnusedFile = 0; nUnusedFile < g_pCompilerData->unused_obj_files; nUnusedFile++)
    {
        unsigned char* pData = 0;
        int nDataSize = 0;
        if (GetObjectPubConList(&(g_pCompilerData->obj_unused[nUnusedFile<<8]), &pData, &nDataSize))
        {
            unsigned char *pDataEnd = pData + nDataSize;
            // go thru symbols validating them and adding them to the symbol table
            while (pData < pDataEnd)
            {
                for (int i = 0; i < symbol_limit+1; i++)
                {
                    if (!CheckWordChar((char)(*pData)))
                    {
                        CompileObjSymbol_BadObj(nFile);
                        return false;
                    }
                    g_pCompilerData->symbolBackup[i] = (char)(*pData);
                    pData++;
                    if (pData[0] < 18) // 0 to 15 = pub param count, 16 and 17 are constants
                    {
                        g_pCompilerData->symbolBackup[i+1] = (char)(0x40 | (nUnusedFile + 1));
                        g_pCompilerData->symbolBackup[i+2] = 0;
                        if (pData[0] < 16) // handle objpub symbol
                        {
                            // we don't add pubs in this case
                            pData++; // adjust pointer to after param count
                            break;
                        }
                        else	// handle objcon or objcon_float symbol
                        {
                            int value = (int)pData[1] | ((int)pData[2] << 8)  | ((int)pData[3] << 16)  | ((int)pData[4] << 24);
                            g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, (pData[0] == 16) ? type_objcon : type_objcon_float, value);
#ifdef RPE_DEBUG
                            float fValue = *((float*)(&value));
                            printf("objcon: %s %d %f *\n", g_pCompilerData->symbolBackup, value, fValue);
#endif
                            pData+=5; // adjust pointer to after value
                            break;
                        }
                    }
                }
            }
        }
    }
    return true;
}

bool CompileVarBlocks()
{
    g_pCompilerData->var_byte = 0;
    g_pCompilerData->var_word = 0;
    g_pCompilerData->var_long = 0;

    bool bEof = false;
    g_pElementizer->Reset();

    while (!bEof)
    {
        if(g_pElementizer->GetNextBlock(block_var, bEof))
        {
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
                if (g_pElementizer->GetType() == type_size)
                {
                    int nSize = g_pElementizer->GetValue();

                    while(!bEof)
                    {
                        if (!g_pElementizer->GetNext(bEof))
                        {
                            return false;
                        }
                        if (g_pElementizer->GetType() != type_undefined)
                        {
                            g_pCompilerData->error = true;
                            g_pCompilerData->error_msg = g_pErrorStrings[error_eauvn];
                            return false;
                        }

                        // save a copy of the symbol
                        g_pElementizer->BackupSymbol();

                        int nCount = 1;

                        // see if there is a count
                        if (g_pElementizer->CheckElement(type_leftb))
                        {
                            // get the count value and validate it
                            if (!GetTryValue(true, true))
                            {
                                return false;
                            }
                            nCount = GetResult();
                            if (nCount > var_limit)
                            {
                                g_pCompilerData->error = true;
                                g_pCompilerData->error_msg = g_pErrorStrings[error_tmvsid];
                                return false;
                            }
                            // get the closing bracket
                            if (!g_pElementizer->GetElement(type_rightb))
                            {
                                return false;
                            }
                        }

                        int nValue = 0;
                        switch(nSize)
                        {
                            case 0:
                                nValue = g_pCompilerData->var_byte;
                                g_pCompilerData->var_byte += nCount;
                                break;
                            case 1:
                                nValue = g_pCompilerData->var_word;
                                g_pCompilerData->var_word += nCount<<1;
                                break;
                            case 2:
                                nValue = g_pCompilerData->var_long;
                                g_pCompilerData->var_long += nCount<<2;
                                break;
                        }
                        if ((nValue + (nCount << nSize)) > var_limit)
                        {
                            g_pCompilerData->error = true;
                            g_pCompilerData->error_msg = g_pErrorStrings[error_tmvsid];
                            return false;
                        }

                        // add the symbol
                        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, (nSize == 0) ? type_var_byte : ((nSize == 1) ? type_var_word : type_var_long), nValue);
#ifdef RPE_DEBUG
                        printf("var: %s %d (%d, %d)\n", g_pCompilerData->symbolBackup, nValue, nSize, nCount);
#endif

                        bool bComma = false;
                        if (!GetCommaOrEnd(bComma))
                        {
                            // error was set inside GetCommaOrEnd()
                            return false;
                        }
                        if (!bComma)
                        {
                            break;
                        }
                    }
                    continue;
                }
                else if (g_pElementizer->GetType() != type_block)
                {
                    g_pCompilerData->error = true;
                    g_pCompilerData->error_msg = g_pErrorStrings[error_ebwol];
                    return false;
                }

                // if we get here, then the element we got was of type_block

                // finished with this block, backup off the next block
                g_pElementizer->Backup();
                break;
            }
        }
        else
        {
            return false;
        }
    }

    return true;
}

bool CompileSubBlocks_Compile(int blockType, int &subCount, int &nMethodIndex)
{
    bool bEof = false;
    g_pElementizer->Reset();

    while (!bEof)
    {
        if(g_pElementizer->GetNextBlock(blockType, bEof))
        {
            if (!bEof)
            {
                int saved_inf_start = g_pCompilerData->source_start;
                int saved_inf_data0 = g_pCompilerData->obj_ptr;

                if (!g_pElementizer->GetNext(bEof))
                {
                    return false;
                }

                int saved_inf_data2 = g_pCompilerData->source_start;
                int saved_inf_data3 = g_pCompilerData->source_finish;

                // locals is tracking the number of bytes, so 4 per long
                // we start at 4 because every sub has a result local
                int locals = 4;
                int paramCount = 0;

                // are there parameters?
                if (g_pElementizer->CheckElement(type_left))
                {
                    // if so, then count them
                    while (!bEof)
                    {
                        if (!g_pElementizer->GetNext(bEof))
                        {
                            return false;
                        }
                        if (g_pElementizer->GetType() == type_undefined)
                        {
                            g_pElementizer->BackupSymbol();

                            g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, type_loc_long, locals, 0, true); // add to temp symbols

                            g_pCompilerData->inf_start = g_pCompilerData->source_start;
                            g_pCompilerData->inf_finish = g_pCompilerData->source_finish;
                            g_pCompilerData->inf_data0 = subCount;
                            g_pCompilerData->inf_data1 = paramCount;
                            g_pCompilerData->inf_data2 = saved_inf_data2;
                            g_pCompilerData->inf_data3 = saved_inf_data3;
                            g_pCompilerData->inf_data4 = 0;
                            if (blockType == block_pub)
                            {
                                g_pCompilerData->inf_type = info_pub_param;
                            }
                            else
                            {
                                g_pCompilerData->inf_type = info_pri_param;
                            }
                            EnterInfo();

                            paramCount++;
#ifdef RPE_DEBUG
                            printf("temp loc: %s %d\n", g_pCompilerData->symbolBackup, locals);
#endif

                            locals += 4;

                            bool bComma = false;
                            if (!GetCommaOrRight(bComma))
                            {
                                // error was set inside GetCommaOrRight()
                                return false;
                            }
                            if (!bComma)
                            {
                                // we got the ')' so fall out of counting parameters
                                break;
                            }
                        }
                        else
                        {
                            // a parameter used an already defined symbol name
                            g_pCompilerData->error = true;
                            g_pCompilerData->error_msg = g_pErrorStrings[error_eaupn];
                            return false;
                        }
                    }
                }

                // is there a result defined
                if (g_pElementizer->CheckElement(type_colon))
                {
                    // yes, so read the name
                    if (!g_pElementizer->GetNext(bEof))
                    {
                        return false;
                    }
                    if ((g_pElementizer->GetType() != type_undefined && g_pElementizer->GetType() != type_loc_long) ||  // this allows for 'RESULT'
                        (g_pElementizer->GetType() == type_loc_long && g_pElementizer->GetValue() != 0))                // ''
                    {
                        // result name was not unique
                        g_pCompilerData->error = true;
                        g_pCompilerData->error_msg = g_pErrorStrings[error_eaurn];
                        return false;
                    }

                    if (g_pElementizer->GetType() != type_loc_long)
                    {
                        // if we result symbol then add it to temp symbols
                        // we don't increment locals, because result local is already accounted for
                        g_pElementizer->BackupSymbol();
                        g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, type_loc_long, 0, 0, true);
#ifdef RPE_DEBUG
                        printf("result: %s %d\n", g_pCompilerData->symbolBackup, 0);
#endif
                    }
                }

                // check for locals
                bool bPipe = false;
                if(!GetPipeOrEnd(bPipe))
                {
                    // error was set inside GetPipeOrEnd()
                    return false;
                }
                if (bPipe)
                {
                    // count locals (handling arrays)
                    while (!bEof)
                    {
                        if (!g_pElementizer->GetNext(bEof))
                        {
                            return false;
                        }
                        if (g_pElementizer->GetType() == type_undefined)
                        {
                            g_pElementizer->BackupSymbol();

                            int sizeOfThisLocal = 4;

                            // is it an array?
                            if (g_pElementizer->CheckElement(type_leftb))
                            {
                                // it is, so read the index (size of array)
                                if (!GetTryValue(true, true))
                                {
                                    return false;
                                }
                                int value = GetResult();
                                sizeOfThisLocal = (value * 4);

                                // get passed ]
                                if (!g_pElementizer->GetElement(type_rightb))
                                {
                                    // error was set inside GetElement()
                                    return false;
                                }
                            }

                            g_pSymbolEngine->AddSymbol(g_pCompilerData->symbolBackup, type_loc_long, locals, 0, true); // add to temp symbols
#ifdef RPE_DEBUG
                            if (sizeOfThisLocal > 4)
                            {
                                printf("temp loc: %s[%d] %d\n", g_pCompilerData->symbolBackup, sizeOfThisLocal/4, locals);
                            }
                            else
                            {
                                printf("temp loc: %s %d\n", g_pCompilerData->symbolBackup, locals);
                            }
#endif
                            locals += sizeOfThisLocal;

                            bool bComma = false;
                            if (!GetCommaOrEnd(bComma))
                            {
                                // error was set inside GetCommaOrEnd()
                                return false;
                            }
                            if (!bComma)
                            {
                                break;
                            }
                        }
                        else
                        {
                            // a local used an already defined symbol name
                            g_pCompilerData->error = true;
                            g_pCompilerData->error_msg = g_pErrorStrings[error_eauvn];
                            return false;
                        }
                    }
                }

                if (!g_pCompilerData->bFinalCompile || IsMethodUsed(g_pCompilerData->current_filename, nMethodIndex))
                {
                    // enter sub offset into index
                    *((short*)&(g_pCompilerData->obj[4 + (subCount * 4)])) = (short)g_pCompilerData->obj_ptr;

                    if (!CompileTopBlock()) // instruction block compiler
                    {
                        return false;
                    }

                    g_pCompilerData->inf_start = saved_inf_start;
                    g_pCompilerData->inf_finish = g_pElementizer->GetSourcePtr();
                    g_pCompilerData->inf_data0 = saved_inf_data0;
                    g_pCompilerData->inf_data1 = g_pCompilerData->obj_ptr;
                    g_pCompilerData->inf_data2 = saved_inf_data2;
                    g_pCompilerData->inf_data3 = saved_inf_data3;
                    g_pCompilerData->inf_data4 = (paramCount << 16) | subCount;
                    if (blockType == block_pub)
                    {
                        g_pCompilerData->inf_type = info_pub;
                    }
                    else
                    {
                        g_pCompilerData->inf_type = info_pri;
                    }
                    EnterInfo();

                    subCount++;
                }
                else
                {
                    // just simple tracking of unused methods, maximum tracked amount works out to 1024 entries
                    if (g_pCompilerData->unused_methods < (32 * file_limit))
                    {
                        char szMethodName[symbol_limit + 1];
                        int nLength = saved_inf_data3 - saved_inf_data2;
                        strncpy(szMethodName, &g_pCompilerData->source[saved_inf_data2], nLength);
                        szMethodName[nLength] = 0;
                        sprintf(&(g_pCompilerData->method_unused[symbol_limit * g_pCompilerData->unused_methods]), "%s.%s", g_pCompilerData->current_filename, szMethodName);
                        g_pCompilerData->unused_methods++;
                    }
                }
                nMethodIndex++;
                g_pSymbolEngine->Reset(true); // cancel local symbols
            }
        }
        else
        {
            return false;
        }
    }

    return true;
}

bool CompileSubBlocks()
{
    int subCount = 0;
    int nMethodIndex = 0;
    if (!CompileSubBlocks_Compile(block_pub, subCount, nMethodIndex))
    {
        return false;
    }
    if (!CompileSubBlocks_Compile(block_pri, subCount, nMethodIndex))
    {
        return false;
    }

    return true;
}

bool CompileObjBlocks()
{
    // calculate var_ptr and align to long
    g_pCompilerData->var_ptr = g_pCompilerData->var_byte + g_pCompilerData->var_word + g_pCompilerData->var_long;
    if ((g_pCompilerData->var_ptr & 0x00000003) != 0)
    {
        g_pCompilerData->var_ptr = (g_pCompilerData->var_ptr | 0x00000003) + 1;
    }
    if (g_pCompilerData->var_ptr > var_limit)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_tmvsid];
        return false;
    }

    // align obj_ptr to long
    if (!g_pCompilerData->bDATonly)
    {
        while ((g_pCompilerData->obj_ptr & 0x00000003) != 0)
        {
            if (!EnterObj(0))
            {
                return false;
            }
        }
    }

    if (g_pCompilerData->compile_mode == 0)
    {
        // set obj size word at offset 0
        *((short*)(&g_pCompilerData->obj[0])) = (short)g_pCompilerData->obj_ptr;
        // set obj index byte at offset 2
        g_pCompilerData->obj[2] = (unsigned char)(g_pCompilerData->obj_start >> 2);
        // set obj count byte at offset 3
        g_pCompilerData->obj[3] = (unsigned char)(g_pCompilerData->obj_count);
    }

    // and any objects (OBJ sections)
    int objptr[file_limit];
    int objvar[file_limit];

    for (int i = 0; i < g_pCompilerData->obj_files; i++)
    {
        objptr[i] = g_pCompilerData->obj_ptr;

        unsigned char* pObj = &(g_pCompilerData->obj_data[g_pCompilerData->obj_offsets[i]]);

        // get vsize and save in objvar[i]
        //objvar[i] = (int)(*((unsigned short*)(pObj)));
        objvar[i] = (int)pObj[0] | ((int)pObj[1] << 8);
        pObj += 2;

        // get psize
        //unsigned short psize = *((unsigned short*)(pObj));
        unsigned short psize = (unsigned short)pObj[0] | ((unsigned short)pObj[1] << 8);
        pObj += 2;

        for (unsigned short j = 0; j < psize; j++)
        {
            if (!EnterObj(pObj[j]))
            {
                return false;
            }
        }
    }

    // get start of object index
    unsigned short* pIndex = (unsigned short*)&(g_pCompilerData->obj[g_pCompilerData->obj_start]);

    for (int i = 0; i < g_pCompilerData->obj_count; i++)
    {
        // get file number from index
        int index = *((int*)pIndex);

        // write objptr back to index
        *pIndex = (unsigned short)(objptr[index]);
        pIndex++;

        // write var ptr back to index
        *pIndex = (unsigned short)(g_pCompilerData->var_ptr);
        pIndex++;

        // update var ptr and check limit
        g_pCompilerData->var_ptr += objvar[index];
        if (g_pCompilerData->var_ptr > var_limit)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_tmvsid];
            return false;
        }
    }

    return true;
}

bool DistillObjBlocks()
{
    if (g_pCompilerData->compile_mode == 0)
    {
       // Cannot "distill" large objects (eeprom_size set to greater than min_obj_limit(64k))
       if (g_pCompilerData->obj_ptr <= min_obj_limit)
       {
           return DistillObjects();
       }
    }
    return true;
}

bool CompileFinal()
{
    if (g_pCompilerData->compile_mode == 0)
    {
        int vsize = g_pCompilerData->var_ptr;
        int psize = g_pCompilerData->obj_ptr;
        int vsize_psize = (psize << 16) | vsize;
        int checksum_offset = g_pCompilerData->obj_ptr;
        if (!EnterObj(0)) //placeholder for checksum;
        {
            return false;
        }

        if (!g_pCompilerData->bFinalCompile && g_pCompilerData->bUnusedMethodElimination)
        {
            AddObjectPubConList(g_pCompilerData->current_filename, g_pCompilerData->pubcon_list, g_pCompilerData->pubcon_list_size);
        }

        // copy pubcon_list into obj (RPE: this could be optimized)
        for (int i = 0; i < g_pCompilerData->pubcon_list_size; i++)
        {
            if (!EnterObj(g_pCompilerData->pubcon_list[i]))
            {
                return false;
            }
        }

        if (!EnterObjLong(0)) // allocate space for vsize/psize long
        {
            return false;
        }

        // shift contents of obj up 4 bytes (to insert vsize/psize at front)
        memmove(&(g_pCompilerData->obj[4]), &(g_pCompilerData->obj[0]), g_pCompilerData->obj_limit - 4);
        // insert vsize_psize at beginning on obj
        *((int*)(&g_pCompilerData->obj[0])) = vsize_psize;
        // also store them separately in case they are larger than 65536
        g_pCompilerData->vsize = vsize;
        g_pCompilerData->psize = psize;

        // calculate the checksum
        unsigned char checksum = 0;
        for (int i = 0; i < g_pCompilerData->obj_ptr; i++)
        {
            checksum += g_pCompilerData->obj[i];
        }
        g_pCompilerData->obj[checksum_offset + 4] = language_version - checksum; // + 4 because we shifted obj by 4 above
    }
    return true;
}

bool PointToFirstCon()
{
    bool bEof = false;
    g_pElementizer->Reset();

    if(g_pElementizer->GetNextBlock(block_con, bEof))
    {
        if (!bEof)
        {
            g_pCompilerData->source_finish = g_pCompilerData->source_start;
        }
    }
    else
    {
        return false;
    }

    return true;
}

bool Determine_GetSymbol(const char* pSymbol, int errorCode, bool& bFound)
{
    bFound = false;
    if (g_pElementizer->FindSymbol(pSymbol))
    {
        if (g_pElementizer->GetType() == type_con)
        {
            bFound = true;
        }
        else if (g_pElementizer->GetType() != type_undefined)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[errorCode];
            return false;
        }
    }
    return true;
}

bool DetermineStack()
{
    int stackRequired = 16;

    bool bFound;
    if (!Determine_GetSymbol("_STACK", error_ssaf, bFound))
    {
        return false;
    }
    if (bFound)
    {
        stackRequired = g_pElementizer->GetValue();
    }
    if (!Determine_GetSymbol("_FREE", error_ssaf, bFound))
    {
        return false;
    }
    if (bFound)
    {
        stackRequired += g_pElementizer->GetValue();
    }

    if (stackRequired > 0x2000)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_safms];
        return false;
    }

    g_pCompilerData->stack_requirement = stackRequired;

    return true;
}

bool Determine_GetBitPos(int value, int& bitPos)
{
    int bitCount = 0;
    for (int i = 32; i > 0; i--)
    {
        if (value & 0x01)
        {
            bitPos = 32 - i;
            bitCount++;
        }
        value >>= 1;
    }
    if (bitCount != 1)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_icms];
        return false;
    }
    return true;
}

bool DetermineClock()
{
    // set to RCFAST for default
    g_pCompilerData->clkmode = 0;
    g_pCompilerData->clkfreq = 12000000;

    int mode = 0;
    int freq = 0;
    int xin = 0;
    int freqShift = 0;

    // try to find the values in the symbols
    bool bHaveClkMode = false;
    bool bHaveClkFreq = false;
    bool bHaveXinFreq = false;

    if (!Determine_GetSymbol("_CLKMODE", error_sccx, bHaveClkMode))
    {
        return false;
    }
    if (bHaveClkMode)
    {
        mode = g_pElementizer->GetValue();
    }
    if (!Determine_GetSymbol("_CLKFREQ", error_sccx, bHaveClkFreq))
    {
        return false;
    }
    if (bHaveClkFreq)
    {
        freq = g_pElementizer->GetValue();
    }
    if (!Determine_GetSymbol("_XINFREQ", error_sccx, bHaveXinFreq))
    {
        return false;
    }
    if (bHaveXinFreq)
    {
        xin = g_pElementizer->GetValue();
    }

    if (bHaveClkMode == false && bHaveClkFreq == false && bHaveXinFreq == false)
    {
        // just use default (already set above)
        return true;
    }

    // can't have either freq without clkmode
    if (bHaveClkMode == false && (bHaveClkFreq == true || bHaveXinFreq == true))
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_cxswcm];
        return false;
    }

    // can't have both clkfreq and xinfreq
    if (bHaveClkFreq == true && bHaveXinFreq == true)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_ecoxmbs];
        return false;
    }

    // validate the mode
    if (mode == 0 || (mode & 0xFFFFF800) != 0 || (((mode & 0x03) != 0) && ((mode & 0x7FC) != 0)))
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_icms];
        return false;
    }

    if (mode & 0x03) // RCFAST or RCSLOW
    {
        // can't have clkfreq or xinfreq in RC mode
        if (bHaveClkFreq == true || bHaveXinFreq == true)
        {
            g_pCompilerData->error = true;
            g_pCompilerData->error_msg = g_pErrorStrings[error_cxnawrc];
            return false;
        }

        if (mode == 2)
        {
            // RCSLOW
            g_pCompilerData->clkmode = 1;
            g_pCompilerData->clkfreq = 20000;
            return true;
        }
        else
        {
            // RCFAST (which is already set as default)
            return true;
        }
    }
    else
    {
        // get xinput/xtal1/xtal2/xtal3
        int bitPos = 0;
        if (!Determine_GetBitPos((mode >> 2) & 0x0F, bitPos))
        {
            return false;
        }
        g_pCompilerData->clkmode = (unsigned char)((bitPos << 3) | 0x22); // 0x22 = 0100010b

        if (mode & 0x7C0)
        {
            // get xmul
            if (!Determine_GetBitPos(mode >> 6, bitPos))
            {
                return false;
            }
            freqShift = bitPos;
            g_pCompilerData->clkmode += (unsigned char)(bitPos + 0x41); // 0x41 = 1000001b
        }
    }

    // get clkfreq

    // must have xinfreq or clkfreq
    if (bHaveClkFreq == false && bHaveXinFreq == false)
    {
        g_pCompilerData->error = true;
        g_pCompilerData->error_msg = g_pErrorStrings[error_coxmbs];
        return false;
    }

    if (bHaveClkFreq)
    {
        g_pCompilerData->clkfreq = freq;
    }
    else
    {
        g_pCompilerData->clkfreq = (xin << freqShift);
    }

    return true;
}

bool DetermineDebug()
{
    bool bFound = false;
    if (!Determine_GetSymbol("_DEBUG", error_sdcobu, bFound))
    {
        return false;
    }
    if (bFound)
    {
        g_pCompilerData->debugbaud = g_pElementizer->GetValue();
    }
    return true;
}

char CompileDoc_ScanSkip(int& scanPtr)
{
    while (g_pCompilerData->source[scanPtr] == ' ' || g_pCompilerData->source[scanPtr] == 9)
    {
        scanPtr++;
    }

    return g_pCompilerData->source[scanPtr];
}

bool CompileDoc_ScanInterface(bool bPrint, int& nCount)
{
    int savedSourcePtr = g_pElementizer->GetSourcePtr();

    bool bEof = false;
    if (!g_pElementizer->GetNext(bEof))
    {
        return false;
    }

    // start off count with the length of the pub name
    nCount = g_pCompilerData->source_finish - g_pCompilerData->source_start;

    if (bPrint)
    {
        // print the pub name
        for (int i = 0; i < nCount; i++)
        {
            if (!PrintChr(g_pCompilerData->source[g_pCompilerData->source_start + i]))
            {
                return false;
            }
        }
    }

    // start right after name
    int scanPtr = g_pCompilerData->source_start + nCount;

    // scan/print any parameters
    char currentChar = CompileDoc_ScanSkip(scanPtr);
    if (currentChar == '(')
    {
        for (;;)
        {
            currentChar = g_pCompilerData->source[scanPtr++];
            nCount++;
            if (bPrint)
            {
                if (!PrintChr(currentChar))
                {
                    return false;
                }
            }
            if (currentChar == ')')
            {
                break;
            }
            else if (currentChar == ',')
            {
                // add a space after the comma
                nCount++;
                if (bPrint)
                {
                    if (!PrintChr(' '))
                    {
                        return false;
                    }
                }

                // scan for first char of next param
                CompileDoc_ScanSkip(scanPtr);
            }
        }
    }

    // scan/print any result
    currentChar = CompileDoc_ScanSkip(scanPtr);
    if (currentChar == ':')
    {
        nCount+=3;
        if (bPrint)
        {
            if (!PrintString(" : "))
            {
                return false;
            }
        }

        // scan/print chars until we get a non-word char (end of the result name)
        currentChar = CompileDoc_ScanSkip(scanPtr);
        while (CheckWordChar(currentChar))
        {
            nCount++;
            if (bPrint)
            {
                if (!PrintChr(' '))
                {
                    return false;
                }
            }
            currentChar = g_pCompilerData->source[scanPtr++];
        }
    }

    // done with this interface
    g_pElementizer->SetSourcePtr(savedSourcePtr);
    nCount += 5; // account for 'PUB  ' &  the following cr
    if (bPrint)
    {
        if (!PrintChr(13))
        {
            return false;
        }
    }

    return true;
}

bool CompileDoc_PrintAll(int sourcePtr)
{
    g_pElementizer->Reset();
    g_pElementizer->SetSourcePtr(sourcePtr);

    bool bEof = false;
    while (!bEof)
    {
        if (!g_pElementizer->GetNextBlock(block_pub, bEof))
        {
            return false;
        }
        if (bEof)
        {
            break;
        }
        if (g_pCompilerData->doc_mode)
        {
            // print extra cr and underline
            if (!PrintChr(13))
            {
                return false;
            }
            int nCount = 0;
            if (!CompileDoc_ScanInterface(false, nCount))
            {
                return false;
            }
            for (int i = 0; i < nCount; i++)
            {
                if (!PrintChr('_'))
                {
                    return false;
                }
            }
            if (!PrintChr(13))
            {
                return false;
            }
        }

        // print pub name and interface
        if (!PrintString("PUB  "))
        {
            return false;
        }
        int nCount = 0;
        if (!CompileDoc_ScanInterface(true, nCount))
        {
            return false;
        }
        if (g_pCompilerData->doc_mode)
        {
            // print extra cr
            if (!PrintChr(13))
            {
                return false;
            }
        }
    }

    return true;
}

bool CompileDoc()
{
    g_pElementizer->Reset();
    g_pCompilerData->doc_flag = false;
    g_pCompilerData->doc_mode = true;

    bool bEof = false;

    // in doc mode, this will print out any doc comments at the top of the obj
    // GetNext() does it, and also sets the doc_flag if it did
    // it'll return type_end until it gets to the first non-comment line (start of code)
    while (!bEof)
    {
        if (!g_pElementizer->GetNext(bEof))
        {
            return false;
        }
        if (g_pElementizer->GetType() != type_end)
        {
            break;
        }
    }

    // if something was printed above then add a CR
    if (g_pCompilerData->doc_flag)
    {
        if (!PrintChr(13))
        {
            return false;
        }
    }

    // clear doc_mode flag so we can print the interface stuff without doc comments in it
    g_pCompilerData->doc_mode = false;
    int savedSourceStart = g_pCompilerData->source_start;

    char tempStr[512];
    sprintf(tempStr, "Object \"%s", g_pCompilerData->obj_title);
    if (!PrintString(tempStr))
    {
        return false;
    }
    if (!PrintString("\" Interface:\r\r"))
    {
        return false;
    }
    if (!CompileDoc_PrintAll(savedSourceStart))
    {
        return false;
    }
    short variables = *((short*)&(g_pCompilerData->obj[0])) >> 2;
    short program = *((short*)&(g_pCompilerData->obj[2])) >> 2;
    sprintf(tempStr, "\rProgram:  %d Longs\rVariable: %d Longs\r", program, variables);
    if (!PrintString(tempStr))
    {
        return false;
    }

    // doc_flag will get set when printing the interfaces above
    if (g_pCompilerData->doc_flag)
    {
        // set doc mode to true, in order to print the interfaces (again) with doc comments in it
        g_pCompilerData->doc_mode = true;

        // doc comments in pubs print interface again, this time with doc comments
        if (!CompileDoc_PrintAll(savedSourceStart))
        {
            return false;
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
