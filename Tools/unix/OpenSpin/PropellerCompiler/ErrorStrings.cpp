//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// ErrorStrings.cpp
//

const char* g_pErrorStrings[] = 
{
    "Address is not long",
    "Address is out of range",
    "\"}\" must be preceeded by \"{\" to form a comment",
    "Block designator must be in first column",
    "Blocknest stack overflow",
    "Cannot compute square root of negative floating-point number",
    "Constant exceeds 32 bits",
    "_CLKFREQ or _XINFREQ must be specified",
    "CALL symbol must not exceed 252 characters",
    "_CLKFREQ/_XINFREQ not allowed with RCFAST/RCSLOW",
    "_CLKFREQ/_XINFREQ specified without _CLKMODE",
    "Divide by zero",
    "Destination register cannot exceed $1FF",
    "Expected an assembly effect or end of line",
    "Expected an assembly effect",
    "Expected an assembly instruction",
    "Expected a binary operator or \")\"",
    "Expected a constant name",
    "Expected a constant, unary operator, or \"(\"",
    "Expected a DAT symbol",
    "Expected an expression term",
    "Expected an instruction or variable",
    "Expected a local symbol",
    "Expected a memory variable after \"@\"",
    "Expected a subroutine name",
    "Expected a subroutine or object name",
    "Expected a terminating quote",
    "Expected a unique object name",
    "Expected a variable",
    "Expected a unique constant name or \"#\"",
    "Expected a unique name, BYTE, WORD, LONG, or assembly instruction",
    "Expected a unique parameter name",
    "Expected a unique result name",
    "Expected a unique subroutine name",
    "Expected a unique variable name",
    "Expected BYTE, WORD, or LONG",
    "Expected \",\" or end of line",
    "Expected \":\"",
    "Expected \",\"",
    "Expected \",\" or \")\"",
    "Either _CLKFREQ or _XINFREQ must be specified, but not both",
    "Expected \".\"",
    "Expected end of line",
    "Expected \"=\" \"[\" \",\" or end of line",
    "Expected FROM",
    "Expression is too complex",
    "Expected \"(\"",
    "Expected \"[\"",
    "Expected PRECOMPILE or ARCHIVE",
    "Expected \"|\" or end of line",
    "Expected \"#\"",
    "Expected \"}\"",
    "Expected \"}}\"",
    "Expected \")\"",
    "Expected \"]\"",
    "Empty string",
    "Expected STEP or end of line",
    "Expected TO",
    "Filename too long",
    "Floating-point constant must be within +/- 3.4e+38",
    "Floating-point not allowed in integer expression",
    "Floating-point overflow",
    "Invalid binary number",
    "Invalid _CLKMODE specified",
    "Invalid double-binary number",
    "Internal DAT file not found",
    "Invalid filename character",
    "Invalid filename, use \"FilenameInQuotes\"",
    "Integer not allowed in floating-point expression",
    "Internal",
    "Integer operator not allowed in floating-point expression",
    "Limit of 64 cases exceeded",
    "Limit of 8 nested blocks exceeded",
    "Limit of 32 unique objects exceeded",
    "Limit of 32 unique DAT files exceeded",
    "Limit of 32 unique PRECOMPILE files exceeded",
    "Limit of 32 unique ARCHIVE files exceeded",
    "List is too large",
    "Limit of 1,048,576 DAT symbols exceeded",
    "Limit of 16 ELSEIFs exceeded",
    "Limit of 4096 local variables exceeded",
    "Limit of 15 parameters exceeded",
    "Limit of 256 subroutines + objects exceeded",
    "Memory instructions cannot use WR/NR",
    "No cases encountered",
    "No PUB routines found",
    "Object count must be from 1 to 255",
    "Object distiller overflow",
    "Origin exceeds FIT limit",
    "Object exceeds 128k (before distilling)",
    "Origin exceeds $1F0 limit",
    "\"$\" is not allowed here",
    "OTHER must be last case",
    "PUB/CON list overflow",
    "?_RET address is not long",
    "?_RET address is out of range",
    "Register is not allowed here",
    "RES is not allowed in ORGX mode",
    "_STACK and _FREE must sum to under 8k",
    "Symbols _CLKMODE, _CLKFREQ, _XINFREQ can only be used as integer constants",
    "String characters must range from 1 to 255",
    "Symbol _DEBUG can only be used as an integer constant",
    "Symbol exceeds 256 characters",
    "Symbol is already defined",
    "STRING not allowed here",
    "Size override must be larger",
    "Size override must be smaller",
    "Source register/constant cannot exceed $1FF",
    "Symbols _STACK and _FREE can only be used as integer constants",
    "Symbol table is full",
    "This instruction is only allowed within a REPEAT block",
    "Too many string constants",
    "Too many string constant characters",
    "Too much variable space is declared",
    "Unrecognized character",
    "Undefined ?_RET symbol",
    "Undefined symbol",
    "Variable needs an operator"
};

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
