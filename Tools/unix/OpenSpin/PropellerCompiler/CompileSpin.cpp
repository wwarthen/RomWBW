 ///////////////////////////////////////////////////////////////
//                                                           //
// Propeller Spin/PASM Compiler Command Line Tool 'OpenSpin' //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.    //
// See end of file for terms of use.                         //
//                                                           //
///////////////////////////////////////////////////////////////
//
// CompileSpin.cpp
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "CompileSpin.h"
#include "PropellerCompiler.h"
#include "objectheap.h"
#include "textconvert.h"
#include "preprocess.h"
#include "Utilities.h"

#define ObjFileStackLimit   16
#define ListLimit           2000000
#define DocLimit            2000000

static struct preprocess s_preprocessor;
CompilerData* s_pCompilerData = 0;
static int  s_nObjStackPtr = 0;
static bool s_bFinalCompile;

static CompilerConfig s_compilerConfig;
static LoadFileFunc s_pLoadFileFunc = 0;
static FreeFileBufferFunc s_pFreeFileBufferFunc = 0;
static unsigned char* s_pCompileResultBuffer = 0;

static Heirarchy s_objectHeirarchy;

class ObjectNode : public HeirarchyNode
{
public:
    char* m_pFullPath;

    ObjectNode()
        : m_pFullPath(0)
    {
    }
};

static bool GetPASCIISource(char* pFilename)
{
    // read in file to temp buffer, convert to PASCII, and assign to s_pCompilerData->source
    int nLength = 0;
    char* pRawBuffer = s_pLoadFileFunc(pFilename, &nLength, &s_pCompilerData->current_file_path);
    if (pRawBuffer)
    {
        char* pBuffer = 0;
        if (s_compilerConfig.bUsePreprocessor)
        {
            memoryfile mfile;
            mfile.buffer = pRawBuffer;
            mfile.length = nLength;
            mfile.readoffset = 0;
            pp_push_file_struct(&s_preprocessor, &mfile, pFilename);
            pp_run(&s_preprocessor);
            pBuffer = pp_finish(&s_preprocessor);
            nLength = (int)strlen(pBuffer);
            if (nLength == 0)
            {
                free(pBuffer);
                pBuffer = 0;
            }
            s_pFreeFileBufferFunc(pRawBuffer);
        }
        else
        {
            pBuffer = pRawBuffer;
        }

        char* pPASCIIBuffer = new char[nLength+1];
        memset(pPASCIIBuffer, 0, nLength + 1);
        if (!UnicodeToPASCII(pBuffer, nLength, pPASCIIBuffer, s_compilerConfig.bUsePreprocessor))
        {
            printf("Unrecognized text encoding format!\n");
            delete [] pPASCIIBuffer;
            if (s_compilerConfig.bUsePreprocessor)
            {
                free(pBuffer);
            }
            else
            {
                s_pFreeFileBufferFunc(pRawBuffer);
            }
            return false;
        }

        // clean up any previous buffer
        if (s_pCompilerData->source)
        {
            delete [] s_pCompilerData->source;
        }

        s_pCompilerData->source = pPASCIIBuffer;

        if (s_compilerConfig.bUsePreprocessor)
        {
            free(pBuffer);
        }
        else
        {
            s_pFreeFileBufferFunc(pRawBuffer);
        }
    }
    else
    {
        s_pCompilerData->source = NULL;
        return false;
    }

    return true;
}

static void CleanupMemory(bool bUnusedMethodData = true)
{
    delete s_objectHeirarchy.m_pRoot;
    s_objectHeirarchy.m_pRoot = 0;

    if ( s_pCompilerData )
    {
        delete [] s_pCompilerData->list;
        delete [] s_pCompilerData->doc;
        delete [] s_pCompilerData->obj;
        delete [] s_pCompilerData->source;
    }
    CleanObjectHeap();
    if (bUnusedMethodData)
    {
        CleanUpUnusedMethodData();
    }
    Cleanup();
    if (s_pCompileResultBuffer != 0)
    {
        delete [] s_pCompileResultBuffer;
        s_pCompileResultBuffer = 0;
    }
}

void PrintError(const char* pFilename, const char* pErrorString)
{
    int lineNumber = 1;
    int column = 1;
    int offsetToStartOfLine = -1;
    int offsetToEndOfLine = -1;
    int offendingItemStart = 0;
    int offendingItemEnd = 0;

    GetErrorInfo(lineNumber, column, offsetToStartOfLine, offsetToEndOfLine, offendingItemStart, offendingItemEnd);

    printf("%s(%d:%d) : error : %s\n", pFilename, lineNumber, column, pErrorString);

    if ( offendingItemStart == offendingItemEnd && s_pCompilerData->source[offendingItemStart] == 0 )
    {
        printf("Line:\nEnd Of File\nOffending Item: N/A\n");
    }
    else
    {
        char* errorLine = 0;
        char* errorItem = 0;

        if (offendingItemEnd - offendingItemStart > 0)
        {
            errorLine = new char[(offsetToEndOfLine - offsetToStartOfLine) + 1];
            strncpy(errorLine, &s_pCompilerData->source[offsetToStartOfLine], offsetToEndOfLine - offsetToStartOfLine);
            errorLine[offsetToEndOfLine - offsetToStartOfLine] = 0;
        }

        if (offendingItemEnd - offendingItemStart > 0)
        {
            errorItem = new char[(offendingItemEnd - offendingItemStart) + 1];
            strncpy(errorItem, &s_pCompilerData->source[offendingItemStart], offendingItemEnd - offendingItemStart);
            errorItem[offendingItemEnd - offendingItemStart] = 0;
        }

        printf("Line:\n%s\nOffending Item: %s\n", errorLine ? errorLine : "N/A", errorItem ? errorItem : "N/A");

        delete [] errorLine;
        delete [] errorItem;
    }
}

static bool CheckForCircularReference(ObjectNode* pObjectNode)
{
    ObjectNode* pCurrentNode = pObjectNode;
    while (pCurrentNode->m_pParent)
    {
        ObjectNode* pParent = (ObjectNode*)(pCurrentNode->m_pParent);
        if (strcmp(pObjectNode->m_pFullPath, pParent->m_pFullPath) == 0)
        {
            return true;
        }
        pCurrentNode = pParent;
    }

    return false;
}

static bool CompileRecursively(char* pFilename, int& nCompileIndex, ObjectNode* pParentNode)
{
    nCompileIndex++;
    if (s_nObjStackPtr > 0 && (!s_compilerConfig.bQuiet || s_compilerConfig.bFileTreeOutputOnly))
    {
        // only do this if UME is off or if it's the final compile when UME is on
        if (!s_compilerConfig.bUnusedMethodElimination || s_pCompilerData->bFinalCompile)
        {
            char spaces[] = "                              \0";
            printf("%s|-%s\n", &spaces[32-(s_nObjStackPtr<<1)], pFilename);
        }
    }
    s_nObjStackPtr++;
    if (s_nObjStackPtr > ObjFileStackLimit)
    {
        printf("%s : error : Object nesting exceeds limit of %d levels.\n", pFilename, ObjFileStackLimit);
        return false;
    }

    void *definestate = 0;
    if (s_compilerConfig.bUsePreprocessor)
    {
        definestate = pp_get_define_state(&s_preprocessor);
    }
    if (!GetPASCIISource(pFilename))
    {
        printf("%s : error : Can not find/open file.\n", pFilename);
        return false;
    }

    if (!s_pCompilerData->bFinalCompile  && s_compilerConfig.bUnusedMethodElimination)
    {
        AddObjectName(pFilename, nCompileIndex);
    }

    strcpy(s_pCompilerData->current_filename, pFilename);
    char* pExtension = strstr(s_pCompilerData->current_filename, ".spin");
    if (pExtension != 0)
    {
        *pExtension = 0;
    }

    ObjectNode* pObjectNode = new ObjectNode();
    pObjectNode->m_pFullPath = s_pCompilerData->current_file_path;
    pObjectNode->m_pParent = pParentNode;
    s_objectHeirarchy.AddNode(pObjectNode, pParentNode);
    if (CheckForCircularReference(pObjectNode))
    {
        printf("%s : error : Illegal Circular Reference\n", pFilename);
        return false;
    }

    // first pass on object
    const char* pErrorString = Compile1();
    if (pErrorString != 0)
    {
        PrintError(pFilename, pErrorString);
        return false;
    }

    if (s_pCompilerData->obj_files > 0)
    {
        char filenames[file_limit*256];

        int numObjects = s_pCompilerData->obj_files;
        for (int i = 0; i < numObjects; i++)
        {
            // copy the obj filename appending .spin if it doesn't have it.
            strcpy(&filenames[i<<8], &(s_pCompilerData->obj_filenames[i<<8]));
            if (strstr(&filenames[i<<8], ".spin") == NULL)
            {
                strcat(&filenames[i<<8], ".spin");
            }
        }

        for (int i = 0; i < numObjects; i++)
        {
            if (!CompileRecursively(&filenames[i<<8], nCompileIndex, pObjectNode))
            {
                return false;
            }
        }

        // redo first pass on parent object
        if (s_compilerConfig.bUsePreprocessor)
        {
            // undo any defines in sub-objects
            pp_restore_define_state(&s_preprocessor, definestate);
        }
        if (!GetPASCIISource(pFilename))
        {
            printf("%s : error : Can not find/open file.\n", pFilename);
            return false;
        }

        strcpy(s_pCompilerData->current_filename, pFilename);
        pExtension = strstr(s_pCompilerData->current_filename, ".spin");
        if (pExtension != 0)
        {
            *pExtension = 0;
        }
        pErrorString = Compile1();
        if (pErrorString != 0)
        {
            PrintError(pFilename, pErrorString);
            return false;
        }

        if (!CopyObjectsFromHeap(s_pCompilerData, filenames))
        {
            printf("%s : error : Object files exceed 128k.\n", pFilename);
            return false;
        }
    }

    // load all DAT files
    if (s_pCompilerData->dat_files > 0)
    {
        int p = 0;
        for (int i = 0; i < s_pCompilerData->dat_files; i++)
        {
            // Get DAT's Files

            // Get name information
            char filename[256];
            strcpy(&filename[0], &(s_pCompilerData->dat_filenames[i<<8]));

            // Load file and add to dat_data buffer
            s_pCompilerData->dat_lengths[i] = -1;
            char* pFilePath = 0;
            char* pBuffer = s_pLoadFileFunc(&filename[0], &s_pCompilerData->dat_lengths[i], &pFilePath);

            if (s_pCompilerData->dat_lengths[i] == -1)
            {
                s_pCompilerData->dat_lengths[i] = 0;
                printf("Cannot find/open dat file: %s \n", &filename[0]);
                return false;
            }
            if (p + s_pCompilerData->dat_lengths[i] > data_limit)
            {
                printf("%s : error : DAT files exceed 128k.\n", pFilename);
                return false;
            }
            memcpy(&(s_pCompilerData->dat_data[p]), pBuffer, s_pCompilerData->dat_lengths[i]);
            s_pFreeFileBufferFunc(pBuffer);
            s_pCompilerData->dat_offsets[i] = p;
            p += s_pCompilerData->dat_lengths[i];
        }
    }

    // second pass of object
    pErrorString = Compile2();
    if (pErrorString != 0)
    {
        PrintError(pFilename, pErrorString);
        return false;
    }

    // only do this check if UME is off or if it's the final compile when UME is on
    if (!s_compilerConfig.bUnusedMethodElimination || s_pCompilerData->bFinalCompile)
    {
        // Check to make sure object fits into 32k (or eeprom size if specified as larger than 32k)
        unsigned int i = 0x10 + s_pCompilerData->psize + s_pCompilerData->vsize + (s_pCompilerData->stack_requirement << 2);
        if ((s_pCompilerData->compile_mode == 0) && (i > s_pCompilerData->eeprom_size))
        {
            printf("%s : error : Object exceeds runtime memory limit by %d longs.\n", pFilename, (i - s_pCompilerData->eeprom_size) >> 2);
            return false;
        }
    }

    // save this object in the heap
    if (!AddObjectToHeap(pFilename, s_pCompilerData))
    {
        printf("%s : error : Object Heap Overflow.\n", pFilename);
        return false;
    }
    s_nObjStackPtr--;

    return true;
}

static bool ComposeRAM(unsigned char** ppBuffer, int& bufferSize)
{
    if (!s_compilerConfig.bDATonly)
    {
        unsigned int varsize = s_pCompilerData->vsize;                                                // variable size (in bytes)
        unsigned int codsize = s_pCompilerData->psize;                                                // code size (in bytes)
        unsigned int pubaddr = *((unsigned short*)&(s_pCompilerData->obj[8]));                        // address of first public method
        unsigned int publocs = *((unsigned short*)&(s_pCompilerData->obj[10]));                       // number of stack variables (locals), in bytes, for the first public method
        unsigned int pbase = 0x0010;                                                                  // base of object code
        unsigned int vbase = pbase + codsize;                                                         // variable base = object base + code size
        unsigned int dbase = vbase + varsize + 8;                                                     // data base = variable base + variable size + 8
        unsigned int pcurr = pbase + pubaddr;                                                         // Current program start = object base + public address (first public method)
        unsigned int dcurr = dbase + 4 + (s_pCompilerData->first_pub_parameters << 2) + publocs;      // current data stack pointer = data base + 4 + FirstParams*4 + publocs

        if (s_compilerConfig.bBinary)
        {
           // reset ram
           *ppBuffer = new unsigned char[vbase];
           memset(*ppBuffer, 0, vbase);
           bufferSize = vbase;
        }
        else
        {
           if (vbase + 8 > s_compilerConfig.eeprom_size)
           {
              printf("ERROR: eeprom size exceeded by %d longs.\n", (vbase + 8 - s_compilerConfig.eeprom_size) >> 2);
              return false;
           }
           // reset ram
           *ppBuffer = new unsigned char[s_compilerConfig.eeprom_size];
           memset(*ppBuffer, 0, s_compilerConfig.eeprom_size);
           bufferSize = s_compilerConfig.eeprom_size;
           (*ppBuffer)[dbase-8] = 0xFF;
           (*ppBuffer)[dbase-7] = 0xFF;
           (*ppBuffer)[dbase-6] = 0xF9;
           (*ppBuffer)[dbase-5] = 0xFF;
           (*ppBuffer)[dbase-4] = 0xFF;
           (*ppBuffer)[dbase-3] = 0xFF;
           (*ppBuffer)[dbase-2] = 0xF9;
           (*ppBuffer)[dbase-1] = 0xFF;
        }

        // set clock frequency and clock mode
        *((int*)&((*ppBuffer)[0])) = s_pCompilerData->clkfreq;
        (*ppBuffer)[4] = s_pCompilerData->clkmode;

        // set interpreter parameters
        ((unsigned short*)&((*ppBuffer)[4]))[1] = (unsigned short)pbase;         // always 0x0010
        ((unsigned short*)&((*ppBuffer)[4]))[2] = (unsigned short)vbase;
        ((unsigned short*)&((*ppBuffer)[4]))[3] = (unsigned short)dbase;
        ((unsigned short*)&((*ppBuffer)[4]))[4] = (unsigned short)pcurr;
        ((unsigned short*)&((*ppBuffer)[4]))[5] = (unsigned short)dcurr;

        // set code
        memcpy(&((*ppBuffer)[pbase]), &(s_pCompilerData->obj[4]), codsize);

        // install ram checksum byte
        unsigned char sum = 0;
        for (unsigned int i = 0; i < vbase; i++)
        {
          sum = sum + (*ppBuffer)[i];
        }
        (*ppBuffer)[5] = (unsigned char)((-(sum+2028)) );
    }
    else
    {
        unsigned int objsize = *((unsigned short*)&(s_pCompilerData->obj[4]));
        if (s_pCompilerData->psize > 65535)
        {
            objsize = s_pCompilerData->psize;
        }
        unsigned int size = objsize - 4 - (s_pCompilerData->obj[7] * 4);
        *ppBuffer = new unsigned char[size];
        bufferSize = size;
        memcpy(&((*ppBuffer)[0]), &(s_pCompilerData->obj[8 + (s_pCompilerData->obj[7] * 4)]), size);
    }

    return true;
}

static void DumpSymbols()
{
    for (int i = 0; i < s_pCompilerData->info_count; i++)
    {
        char szTemp[256];
        szTemp[0] = '*';
        szTemp[1] = 0;
        int length = 0;
        int start = 0;
        if (s_pCompilerData->info_type[i] == info_pub || s_pCompilerData->info_type[i] == info_pri)
        {
            length = s_pCompilerData->info_data3[i] - s_pCompilerData->info_data2[i];
            start = s_pCompilerData->info_data2[i];
        }
        else if (s_pCompilerData->info_type[i] != info_dat && s_pCompilerData->info_type[i] != info_dat_symbol)
        {
            length = s_pCompilerData->info_finish[i] - s_pCompilerData->info_start[i];
            start = s_pCompilerData->info_start[i];
        }

        if (length > 0 && length < 256)
        {
            strncpy(szTemp, &s_pCompilerData->source[start], length);
            szTemp[length] = 0;
        }

        switch(s_pCompilerData->info_type[i])
        {
            case info_con:
                printf("CON, %s, %d\n", szTemp, s_pCompilerData->info_data0[i]);
                break;
            case info_con_float:
                printf("CONF, %s, %f\n", szTemp, *((float*)&(s_pCompilerData->info_data0[i])));
                break;
            case info_pub_param:
                {
                    char szTemp2[256];
                    szTemp2[0] = '*';
                    szTemp2[1] = 0;
                    length = s_pCompilerData->info_data3[i] - s_pCompilerData->info_data2[i];
                    start = s_pCompilerData->info_data2[i];
                    if (length > 0 && length < 256)
                    {
                        strncpy(szTemp2, &s_pCompilerData->source[start], length);
                        szTemp2[length] = 0;
                    }
                    printf("PARAM, %s, %s, %d, %d\n", szTemp2, szTemp, s_pCompilerData->info_data0[i], s_pCompilerData->info_data1[i]);
                }
                break;
            case info_pub:
                printf("PUB, %s, %d, %d\n", szTemp, s_pCompilerData->info_data4[i] & 0xFFFF, s_pCompilerData->info_data4[i] >> 16);
                break;
        }
    }
}

static void DumpList()
{
    size_t listOffset = 0;
    while (listOffset < s_pCompilerData->list_length)
    {
        char* pTemp = strstr(&(s_pCompilerData->list[listOffset]), "\r");
        if (pTemp)
        {
            *pTemp = 0;
        }
        printf("%s\n", &(s_pCompilerData->list[listOffset]));
        if (pTemp)
        {
            *pTemp = 0x0D;
            listOffset += (pTemp - &(s_pCompilerData->list[listOffset])) + 1;
        }
        else
        {
            listOffset += strlen(&(s_pCompilerData->list[listOffset]));
        }
    }
}

static void DumpDoc()
{
    size_t docOffset = 0;
    while (docOffset < s_pCompilerData->doc_length)
    {
        char* pTemp = strstr(&(s_pCompilerData->doc[docOffset]), "\r");
        if (pTemp)
        {
            *pTemp = 0;
        }
        printf("%s\n", &(s_pCompilerData->doc[docOffset]));
        if (pTemp)
        {
            *pTemp = 0x0D;
            docOffset += (pTemp - &(s_pCompilerData->doc[docOffset])) + 1;
        }
        else
        {
            docOffset += strlen(&(s_pCompilerData->doc[docOffset]));
        }
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void InitCompiler(CompilerConfig* pCompilerConfig, LoadFileFunc pLoadFileFunc, FreeFileBufferFunc pFreeFileBufferFunc)
{
    s_nObjStackPtr = 0;
    s_pCompilerData = 0;
    s_bFinalCompile = false;
    s_pCompileResultBuffer = 0;

    if (pCompilerConfig)
    {
        s_compilerConfig = *pCompilerConfig;
    }

    s_pLoadFileFunc = pLoadFileFunc;
    s_pFreeFileBufferFunc = pFreeFileBufferFunc;

    pp_setFileFunctions(pLoadFileFunc, pFreeFileBufferFunc);
    pp_init(&s_preprocessor, s_compilerConfig.bAlternatePreprocessorMode);
    pp_setcomments(&s_preprocessor, "\'", "{", "}");
}

void SetDefine(const char* pName, const char* pValue)
{
    pp_define(&s_preprocessor, pName, pValue);
}

unsigned char* CompileSpin(char* pFilename, int* pnResultLength)
{
    *pnResultLength = 0;

    if (s_compilerConfig.bFileTreeOutputOnly)
    {
        printf("%s\n", pFilename);
    }

    if (s_compilerConfig.bUnusedMethodElimination)
    {
        InitUnusedMethodData();
    }

    int nOriginalSize = 0;

restart_compile:
    s_pCompilerData = InitStruct();
    s_pCompilerData->bUnusedMethodElimination = s_compilerConfig.bUnusedMethodElimination;
    s_pCompilerData->bFinalCompile = s_bFinalCompile;

    s_pCompilerData->list = new char[ListLimit];
    s_pCompilerData->list_limit = ListLimit;
    memset(s_pCompilerData->list, 0, ListLimit);

    if (s_compilerConfig.bDocMode && !s_compilerConfig.bDATonly)
    {
        s_pCompilerData->doc = new char[DocLimit];
        s_pCompilerData->doc_limit = DocLimit;
        memset(s_pCompilerData->doc, 0, DocLimit);
    }
    else
    {
        s_pCompilerData->doc = 0;
        s_pCompilerData->doc_limit = 0;
    }
    s_pCompilerData->bDATonly = s_compilerConfig.bDATonly;
    s_pCompilerData->bBinary = s_compilerConfig.bBinary;
    s_pCompilerData->eeprom_size = s_compilerConfig.eeprom_size;

    // allocate space for obj based on eeprom size command line option
    s_pCompilerData->obj_limit = s_compilerConfig.eeprom_size > min_obj_limit ? s_compilerConfig.eeprom_size : min_obj_limit;
    s_pCompilerData->obj = new unsigned char[s_pCompilerData->obj_limit];

    // copy filename into obj_title, and chop off the .spin
    strcpy(s_pCompilerData->obj_title, pFilename);
    char* pExtension = strstr(&s_pCompilerData->obj_title[0], ".spin");
    if (pExtension != 0)
    {
        *pExtension = 0;
    }

    int nCompileIndex = 0;
    if (!CompileRecursively(pFilename, nCompileIndex, 0))
    {
        return 0;
    }

    if (!s_compilerConfig.bQuiet)
    {
        // only do this if UME is off or if it's the final compile when UME is on
        if (!s_compilerConfig.bUnusedMethodElimination || s_bFinalCompile)
        {
            printf("Done.\n");
        }
    }

    if (!s_compilerConfig.bFileTreeOutputOnly && !s_compilerConfig.bFileListOutputOnly && !s_compilerConfig.bDumpSymbols)
    {
        if (!s_bFinalCompile && s_compilerConfig.bUnusedMethodElimination)
        {
            nOriginalSize = s_pCompilerData->psize;
            FindUnusedMethods(s_pCompilerData);
            s_bFinalCompile = true;
            CleanupMemory(false);
            goto restart_compile;
        }
        int bufferSize = 0;
        if (!ComposeRAM(&s_pCompileResultBuffer, bufferSize))
        {
            return 0;
        }

        if (!s_compilerConfig.bQuiet)
        {
            if (s_compilerConfig.bUnusedMethodElimination)
            {
                printf("Unused Method Elimination:\n");
                if ((nOriginalSize - s_pCompilerData->psize) > 0)
                {
                    if (s_compilerConfig.bVerbose)
                    {
                        if (s_pCompilerData->unused_obj_files)
                        {
                            printf("Unused Objects:\n");
                            for(int i = 0; i < s_pCompilerData->unused_obj_files; i++)
                            {
                                printf("%s\n", &(s_pCompilerData->obj_unused[i<<8]));
                            }
                        }
                        if (s_pCompilerData->unused_methods)
                        {
                            printf("Unused Methods:\n");
                            for(int i = 0; i < s_pCompilerData->unused_methods; i++)
                            {
                                printf("%s\n", &(s_pCompilerData->method_unused[i*symbol_limit]));
                            }
                        }
                        if (s_pCompilerData->unused_methods || s_pCompilerData->unused_obj_files)
                        {
                            printf("---------------\n");
                        }
                    }
                    printf("%5d methods removed\n%5d objects removed\n%5d bytes saved\n", s_pCompilerData->unused_methods, s_pCompilerData->unused_obj_files,  nOriginalSize - s_pCompilerData->psize );
                }
                else
                {
                    printf("Nothing removed.\n");
                }
                printf("--------------------------\n");
            }
            printf("Program size is %d bytes\n", bufferSize);
        }
        *pnResultLength = bufferSize;
    }

    if (s_compilerConfig.bDumpSymbols)
    {
        DumpSymbols();
    }

    if (s_compilerConfig.bVerbose && !s_compilerConfig.bQuiet && !s_compilerConfig.bDATonly)
    {
        DumpList();
    }

    if (s_compilerConfig.bDocMode && s_compilerConfig.bVerbose && !s_compilerConfig.bQuiet && !s_compilerConfig.bDATonly)
    {
        DumpDoc();
    }

    return s_pCompileResultBuffer;
}

void ShutdownCompiler()
{
    pp_clear_define_state(&s_preprocessor);
    CleanupMemory();
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
