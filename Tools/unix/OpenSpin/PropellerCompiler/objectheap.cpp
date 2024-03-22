///////////////////////////////////////////////////////////////
//                                                           //
// Propeller Spin/PASM Compiler Command Line Tool 'OpenSpin' //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.    //
// Adapted from Jeff Martin's Delphi code by Roy Eltham      //
// See end of file for terms of use.                         //
//                                                           //
///////////////////////////////////////////////////////////////
//
// objectheap.cpp
//
#include <string.h>

#include "PropellerCompiler.h"
#include "objectheap.h"

// Object heap (compile-time objects)
struct ObjHeap
{
    char*   ObjFilename;    // Full filename of object
    char*   Obj;            // Object binary
    int     ObjSize;        // Size of object
};

ObjHeap s_ObjHeap[MaxObjInHeap];
int     s_nObjHeapIndex = 0;

bool AddObjectToHeap(char* name, CompilerData* pCompilerData)
{
    // see if it already exists in the heap
    if (IndexOfObjectInHeap(name) != -1)
    {
        return true;
    }

    // add the object to the heap
    if (s_nObjHeapIndex < MaxObjInHeap)
    {
        int nNameBufferLength = (int)strlen(name)+1;
        s_ObjHeap[s_nObjHeapIndex].ObjFilename = new char[nNameBufferLength];
        strcpy(s_ObjHeap[s_nObjHeapIndex].ObjFilename, name);
        s_ObjHeap[s_nObjHeapIndex].ObjSize = pCompilerData->obj_ptr;
        s_ObjHeap[s_nObjHeapIndex].Obj = new char[pCompilerData->obj_ptr];
        memcpy(s_ObjHeap[s_nObjHeapIndex].Obj, &(pCompilerData->obj[0]), pCompilerData->obj_ptr);
        s_nObjHeapIndex++;
        return true;
    }

    return false;
}

// Returns index of object of Name in Object Heap.  Returns -1 if not found.
int IndexOfObjectInHeap(char* name)
{
    for (int i = s_nObjHeapIndex-1; i >= 0; i--)
    {
        if (_stricmp(s_ObjHeap[i].ObjFilename, name) == 0)
        {
            return i;
        }
    }
    return -1;
}

void CleanObjectHeap()
{
    for (int i = 0; i < s_nObjHeapIndex; i++)
    {
        delete [] s_ObjHeap[i].ObjFilename;
        s_ObjHeap[i].ObjFilename = NULL;
        delete [] s_ObjHeap[i].Obj;
        s_ObjHeap[i].Obj = NULL;
        s_ObjHeap[i].ObjSize = 0;
    }
    s_nObjHeapIndex = 0;
}

bool CopyObjectsFromHeap(CompilerData* pCompilerData, char* filenames)
{
    // load sub-objects from heap into obj_data for Compile2()
    int p = 0;
    for (int i = 0; i < pCompilerData->obj_files; i++)
    {
        int nObjIdx = IndexOfObjectInHeap(&filenames[i<<8]);
        if (p + s_ObjHeap[nObjIdx].ObjSize > data_limit)
        {
            return false;
        }
        memcpy(&pCompilerData->obj_data[p], s_ObjHeap[nObjIdx].Obj, s_ObjHeap[nObjIdx].ObjSize);
        pCompilerData->obj_offsets[i] = p;
        pCompilerData->obj_lengths[i] = s_ObjHeap[nObjIdx].ObjSize;
        p += s_ObjHeap[nObjIdx].ObjSize;
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
