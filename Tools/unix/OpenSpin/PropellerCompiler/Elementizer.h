//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// Elementizer.h
//

#ifndef _ELEMENTIZER_H_
#define _ELEMENTIZER_H_

struct CompilerDataInternal;
class SymbolEngine;
class SymbolTableEntry;

const int state_stack_limit = 32;

class Elementizer
{
    CompilerDataInternal*   m_pCompilerData;
    SymbolEngine*           m_pSymbolEngine;

    int                     m_sourceOffset;
    unsigned char           m_sourceFlags;

    SymbolTableEntry*       m_pSymbolEntry;
    int                     m_type;
    int                     m_value;
    int                     m_value_2;
    int                     m_opType;
    int                     m_asm;
    bool                    m_dual;

    unsigned char           m_backIndex;
    int                     m_backOffsets[4];
    unsigned char           m_backFlags[4];

    char                    m_currentSymbol[symbol_limit+2];

    void SetFromSymbolEntry();

public:
    Elementizer(CompilerDataInternal* pCompilerData, SymbolEngine* pSymbolEngine)
        : m_pCompilerData(pCompilerData)
        , m_pSymbolEngine(pSymbolEngine)
        , m_sourceOffset(0)
        , m_sourceFlags(0)
        , m_backIndex(0)
    {
        for(int i = 0; i < 4; i++)
        {
            m_backOffsets[i] = 0;
            m_backFlags[0] = 0;
        }
    }

    void    Reset();                            // reset to start of source

    bool    GetNext(bool& bEof);                // get the next element in source, returns true no error, bEof will be set to true if eof is hit
    bool    GetElement(int type);               // if the next element is type, then return true, else false, retains value
    bool    CheckElement(int type);             // check if next element is of the given type, if so return true, if not, backup and return false
    bool    GetNextBlock(int type, bool& bEof); // scan for the next block element of type, returns true if no error, , bEof will be set to true if eof is hit
    bool    FindSymbol(const char* symbol);     // lookup a symbol in the symbol table and set it as the current element
    void    Backup();                           // backup to the previous element

    void    BackupSymbol();                     // copy the current symbol into g_pCompilerData->symbolBackup

    int     GetColumn();                        // returns column of the element pointed to by g_pCompilerData->source_start

    int     GetSourcePtr()                      // used to save the current source pointer so it can be put back
    {
        return m_sourceOffset;
    }
    void    SetSourcePtr(int value)             // used to set the source pointer back to a previously saved value
    {
        m_sourceOffset = value;
    }

    int     GetType() { return m_type; }        // symbol's type
    int     GetValue() { return m_value; }      // only valid if m_type != type_undefined
    int     GetValue2() { return m_value_2; }   // only valid if m_type != type_undefined
    int     GetOpType() { return m_opType; }    // only valid for operator symbols
    int     GetAsm() { return m_asm; }          // only valid for dual symbols + op_log_and & op_log_or
    bool    IsDual() { return m_dual; }         // true if is a dual symbol
    char*   GetCurrentSymbol()                  // returns the string for the symbol
    {
        return &(m_currentSymbol[0]);
    }
    int     GetCurrentLineNumber(int &offsetToStartOfLine, int& offsetToEndOfLine);

    bool    SubToNeg();                         // convert a sub to a neg
    void    ObjConToCon();                      // convert type_objcon_xx to type_con_xx
    void    DatResToLong();                     // convert type_dat_long_res to type_dat_long
    bool    NegConToCon();                      // convert -constant to constant
};

#endif // _ELEMENTIZER_H_

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
