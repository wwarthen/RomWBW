//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// CompileUtilities.h
//
 
#ifndef _COMPILEUTILITIES_H_
#define _COMPILEUTILITIES_H_

extern bool SkipBlock(int column);
extern bool SkipRange();
extern bool SkipExpression();
extern bool CheckIndex(bool& bIndex, int& expSourcePtr);
extern bool CheckIndexRange(bool& bIndex, int& expSourcePtr);
extern bool CheckVariable(bool& bVariable, unsigned char& type, unsigned char& size, int& address, int& indexSourcePtr);
extern bool GetVariable(unsigned char& type, unsigned char& size, int& address, int& indexSourcePtr);
extern bool CompileVariable(unsigned char vOperation, unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr);
extern bool CompileVariable_Assign(unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr);
extern bool CompileVariable_Expression(unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr);
extern bool CompileVariable_PreSignExtendOrRandom(unsigned char vOperator);
extern bool CompileVariable_IncOrDec(unsigned char vOperator, unsigned char type, unsigned char size, int address, int indexSourcePtr);
extern bool CompileVariable_PreIncOrDec(unsigned char vOperator);
extern bool CompileParameters(int numParameters);
extern bool CompileConstant(int value);
extern bool CompileOutOfSequenceExpression(int sourcePtr);
extern bool CompileOutOfSequenceRange(int sourcePtr, bool& bRange);
extern bool CompileRange(bool& bRange);
extern bool CompileAddress(int address);

// these are in InstructionBlockCompiler.cpp
extern bool CompileBlock(int column);
extern bool OptimizeBlock(int column, int param, bool (*pCompileFunction)(int, int));

extern bool CompileInstruction(); // in CompileInstruction.cpp
extern bool CompileExpression(); // in CompileExpression.cpp

// these are in StringConstantRoutines.cpp
extern void StringConstant_PreProcess();
extern bool StringConstant_GetIndex();
extern bool StringConstant_EnterChar(unsigned char theChar);
extern void StringConstant_EnterPatch();
extern bool StringConstant_PostProcess();

// these are int BlockNestStackRoutines.cpp
extern bool BlockNest_New(unsigned char type, int stackSize);
extern void BlockNest_Redo(unsigned char type);
extern void BlockNest_End();
extern void BlockStack_Write(int address, int value);
extern int BlockStack_Read(int address);
extern bool BlockStack_CompileAddress(int address);
extern bool BlockStack_CompileConstant();

#endif // _COMPILEUTILITIES_H_

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
