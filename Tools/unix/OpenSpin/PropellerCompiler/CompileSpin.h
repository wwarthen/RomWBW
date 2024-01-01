///////////////////////////////////////////////////////////////
//                                                           //
// Propeller Spin/PASM Compiler Command Line Tool 'OpenSpin' //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.    //
// See end of file for terms of use.                         //
//                                                           //
///////////////////////////////////////////////////////////////
//
// CompileSpin.h
//
#ifndef _COMPILESPIN_H_
#define _COMPILESPIN_H_

typedef char* (*LoadFileFunc)(const char* pFilename, int* pnLength, char** ppFilePath);
typedef void (*FreeFileBufferFunc)(char* pBuffer);

struct CompilerConfig
{
    CompilerConfig()
        : bVerbose(false)
        , bQuiet(false)
        , bFileTreeOutputOnly(false)
        , bFileListOutputOnly(false)
        , bDumpSymbols(false)
        , bUsePreprocessor(true)
        , bAlternatePreprocessorMode(false)
        , bUnusedMethodElimination(false)
        , bDocMode(false)
        , bDATonly(false)
        , bBinary(true)
        , eeprom_size(32768)
    {
    }

    bool bVerbose;
    bool bQuiet;
    bool bFileTreeOutputOnly;
    bool bFileListOutputOnly;
    bool bDumpSymbols;
    bool bUsePreprocessor;
    bool bAlternatePreprocessorMode;
    bool bUnusedMethodElimination;
    bool bDocMode;
    bool bDATonly;
    bool bBinary;
    unsigned int eeprom_size;
};


void InitCompiler(CompilerConfig* pCompilerConfig, LoadFileFunc pLoadFileFunc, FreeFileBufferFunc pFreeFileBufferFunc);
void SetDefine(const char* pName, const char* pValue);
unsigned char* CompileSpin(char* pFilename, int* pnResultLength);
void ShutdownCompiler();

#endif // _COMPILESPIN_H_

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
