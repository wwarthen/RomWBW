
///////////////////////////////////////////////////////////////
//                                                           //
// Propeller Spin/PASM Compiler Command Line Tool 'OpenSpin' //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.    //
// See end of file for terms of use.                         //
//                                                           //
///////////////////////////////////////////////////////////////
//
// UnusedMethodUtils.cpp
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "PropellerCompiler.h"

//
// track object names based on "indent" or which child/parent level
// note: the same name can be in here multiple times at different indent levels
//

struct ObjectNameEntry
{
    char filename[256];
    int nCompileIndex;
};

ObjectNameEntry s_objectNames[file_limit * file_limit];
int s_nNumObjectNames = 0;

void AddObjectName(char* pFilename, int nCompileIndex)
{
    strcpy(s_objectNames[s_nNumObjectNames].filename, pFilename);

    // chop off the .spin extension
    char* pExtension = strstr(s_objectNames[s_nNumObjectNames].filename, ".spin");
    if (pExtension != 0)
    {
        *pExtension = 0;
    }

    s_objectNames[s_nNumObjectNames].nCompileIndex = nCompileIndex;
    s_nNumObjectNames++;
}

int GetObjectName(int nCompileIndex)
{
    for (int i = 0; i < s_nNumObjectNames; i++)
    {
        if (s_objectNames[i].nCompileIndex == nCompileIndex)
        {
            return i;
        }
    }
    return -1;
}

//
// track method usage by object
//

struct IndexEntry
{
    short offset; // offset in longs to method (or sub object)
    short vars; // var offset for objs, locals size for methods
};

struct CallEntry
{
    unsigned char* objaddress;
    unsigned int callOffset;
    unsigned short objoffset;
    unsigned char opcode;
    unsigned char pubnum;
    unsigned char objnum;
};

struct MethodUsage
{
    int nLength;
    int nCalled;
    int nCalls;
    CallEntry *pCalls;
    int nCurrCall;
    int nNewIndex;
};

struct ObjectEntry
{
    int nObjectNameIndex;
    unsigned char* pObject;
    int nObjectMethodCount;
    int nObjectSubObjectCount;
    int nObjectIndexCount;
    int nMethodsCalled;
    int nNewObjectIndex;
    IndexEntry* pIndexTable;
    MethodUsage* pMethods;
};
  
ObjectEntry s_objects[file_limit * file_limit];
int s_nNumObjects;

bool HaveObject(unsigned char* pObject)
{
    for (int i = 0; i < s_nNumObjects; i++)
    {
        if (s_objects[i].pObject == pObject)
        {
            return true;
        }
    }

    return false;
}

ObjectEntry* GetObject(unsigned char* pObject)
{
    for (int i = 0; i < s_nNumObjects; i++)
    {
        if (s_objects[i].pObject == pObject)
        {
            return &s_objects[i];
        }
    }

    return NULL;
}

ObjectEntry* GetObjectByName(char* pFilename)
{
    for (int i = 0; i < s_nNumObjects; i++)
    {
        if (strcmp(s_objectNames[s_objects[i].nObjectNameIndex].filename, pFilename) == 0)
        {
            return &s_objects[i];
        }
    }

    return NULL;
}

int AddObject(unsigned char* pObject, int nObjectNameIndex)
{
    s_objects[s_nNumObjects].pObject = pObject;
    s_objects[s_nNumObjects].nObjectNameIndex = nObjectNameIndex;
    s_objects[s_nNumObjects].nObjectMethodCount = pObject[2]-1;
    s_objects[s_nNumObjects].nObjectSubObjectCount = pObject[3];
    s_objects[s_nNumObjects].nObjectIndexCount = s_objects[s_nNumObjects].nObjectMethodCount + s_objects[s_nNumObjects].nObjectSubObjectCount;
    s_objects[s_nNumObjects].pIndexTable = (IndexEntry *)&(pObject[4]);
    s_objects[s_nNumObjects].pMethods = new MethodUsage[s_objects[s_nNumObjects].nObjectMethodCount];
    for (int i = 0; i < s_objects[s_nNumObjects].nObjectMethodCount; i++)
    {
        s_objects[s_nNumObjects].pMethods[i].nCalled = 0;
        s_objects[s_nNumObjects].pMethods[i].nCalls = 0;
        s_objects[s_nNumObjects].pMethods[i].pCalls = 0;
        s_objects[s_nNumObjects].pMethods[i].nCurrCall = 0;
        s_objects[s_nNumObjects].pMethods[i].nNewIndex = 0;
        s_objects[s_nNumObjects].pMethods[i].nLength = 0;
    }
    return s_nNumObjects++;
}

bool IsObjectUsed(char* pFilename)
{
    // chop off the .spin extension, saving the . char for restoring
    char* pExtension = strstr(pFilename, ".spin");
    char savedChar = 0;
    if (pExtension != 0)
    {
        savedChar = *pExtension;
        *pExtension = 0;
    }

    ObjectEntry* pObject = GetObjectByName(pFilename);

    // restore extention to passed in filename
    if (pExtension != 0)
    {
        *pExtension = savedChar;
    }

    if (pObject && pObject->nMethodsCalled > 0)
    {
        return true;
    }

    return false;
}

bool IsMethodUsed(char* pFilename, int nMethod)
{
    ObjectEntry* pObject = GetObjectByName(pFilename);
    if (pObject && pObject->nMethodsCalled > 0 && pObject->pMethods[nMethod].nCalled > 0)
    {
        return true;
    }

    return false;
}

//
// store pubcon list data so it can be used in the final compile
// note: this is needed to allow removing a child object where the parent used only CONs from the child
//

struct ObjectPubConListEntry
{
    char filename[256];
    unsigned char* pPubConList;
    int nPubConListSize;
};

ObjectPubConListEntry s_objectPubConLists[file_limit * file_limit];
int s_nNumObjectPubConLists;

ObjectPubConListEntry* GetObjectPubConListEntryByName(char* pFilename)
{
    for (int i = 0; i < s_nNumObjectPubConLists; i++)
    {
        if (strcmp(s_objectPubConLists[i].filename, pFilename) == 0)
        {
            return &s_objectPubConLists[i];
        }
    }

    return NULL;
}

void AddObjectPubConList(char* pFilename, unsigned char* pPubConList, int nPubConListSize)
{
    strcpy(s_objectPubConLists[s_nNumObjectPubConLists].filename, pFilename);
    s_objectPubConLists[s_nNumObjectPubConLists].pPubConList = new unsigned char[nPubConListSize];
    s_objectPubConLists[s_nNumObjectPubConLists].nPubConListSize = nPubConListSize;
    memcpy(s_objectPubConLists[s_nNumObjectPubConLists].pPubConList, pPubConList, s_objectPubConLists[s_nNumObjectPubConLists].nPubConListSize);
    s_nNumObjectPubConLists++;
}

bool GetObjectPubConList(char* pFilename, unsigned char** ppPubConList, int* pnPubConListSize)
{
    ObjectPubConListEntry* pObject = GetObjectPubConListEntryByName(pFilename);
    if (pObject && pObject->pPubConList != 0 && pObject->nPubConListSize > 0)
    {
        *ppPubConList = pObject->pPubConList;
        *pnPubConListSize = pObject->nPubConListSize;
        return true;
    }
    return false;
}

struct ObjectCogInitEntry
{
    char filename[256];
    int nSubConstant;
};

ObjectCogInitEntry s_objectCogInits[file_limit * file_limit];
int s_nNumObjectCogInits;

void AddCogNewOrInit(char* pFilename, int nSubConstant)
{
    if (s_nNumObjectCogInits > 0)
    {
        // see if this combo already is in the array
        for (int i = s_nNumObjectCogInits; i > 0; i--)
        {
            if (s_objectCogInits[i-1].nSubConstant == nSubConstant && strcmp(s_objectCogInits[i-1].filename, pFilename) == 0)
            {
                return;
            }
        }
    }
    // wasn't already there, so add it
    strcpy(s_objectCogInits[s_nNumObjectCogInits].filename, pFilename);
    s_objectCogInits[s_nNumObjectCogInits].nSubConstant = nSubConstant;
    s_nNumObjectCogInits++;
}

void MarkCalls(MethodUsage* pMethod, ObjectEntry* pObject);

void CheckForCogNewOrInit(ObjectEntry* pObject)
{
    char* pObjectFilename = s_objectNames[pObject->nObjectNameIndex].filename;
    for (int i = 0; i < s_nNumObjectCogInits; i++)
    {
        if (strcmp(s_objectCogInits[i].filename, pObjectFilename) == 0)
        {
            // don't do this if the object has no called methods already
            // in that case it means the cognew/coginit is never done, so it's safe to not mark the referred to method
            if (pObject->nMethodsCalled > 0)
            {
                MarkCalls(&(pObject->pMethods[s_objectCogInits[i].nSubConstant - 1]), pObject);
            }
        }
    }
}

void CleanUpUnusedMethodData()
{
    for (int i = 0; i < s_nNumObjects; i++)
    {
        s_objects[i].pObject = 0;
        s_objects[i].pIndexTable = 0;

        for (int j = 0; j < s_objects[s_nNumObjects].nObjectMethodCount; j++)
        {
            if (s_objects[i].pMethods[j].pCalls)
            {
                delete [] s_objects[i].pMethods[j].pCalls;
                s_objects[i].pMethods[j].pCalls = 0;
            }
        }
        delete [] s_objects[i].pMethods;
        s_objects[i].pMethods = 0;
    }
    s_nNumObjects = 0;
    s_nNumObjectNames = 0;

    for (int i = 0; i < s_nNumObjectPubConLists; i++)
    {
        delete [] s_objectPubConLists[i].pPubConList;
        s_objectPubConLists[i].pPubConList = 0;
    }
    s_nNumObjectPubConLists = 0;

    s_nNumObjectCogInits = 0;
}

void InitUnusedMethodData()
{
    for (int i = 0; i < (file_limit * file_limit); i++)
    {
        s_objectPubConLists[i].filename[0] = 0;
        s_objectPubConLists[i].pPubConList = 0;
        s_objectPubConLists[i].nPubConListSize = 0;
    }
    s_nNumObjectPubConLists = 0;
    s_nNumObjectCogInits = 0;
    s_nNumObjectNames = 0;
}

void AdvanceCompileIndex(unsigned char* pObject, int& nCompileIndex)
{
    nCompileIndex++;

    int nNextObjOffset = *((unsigned short *)pObject);
    ObjectEntry* pObjectEntry = GetObject(pObject);
    for (int i = 0; i < pObjectEntry->nObjectIndexCount; i++)
    {
        if (pObjectEntry->pIndexTable[i].offset >= nNextObjOffset)
        {
            AdvanceCompileIndex(&(pObject[pObjectEntry->pIndexTable[i].offset]), nCompileIndex);
        }
    }
}

void BuildTables(unsigned char* pObject, int indent, int& nCompileIndex)
{
#ifdef RPE_DEBUG
#define MAX_INDENT 32
    char s_indent[MAX_INDENT+1] = "                                ";
#endif

    if (HaveObject(pObject))
    {
#ifdef RPE_DEBUG
        printf("%sObject Already Added\n", &s_indent[MAX_INDENT-indent]);
#endif
        AdvanceCompileIndex(pObject, nCompileIndex);
        return;
    }
    nCompileIndex++;
    int nNextObjOffset = *((unsigned short *)pObject);
    int nObjectName = GetObjectName(nCompileIndex);
    int nObject = AddObject(pObject, nObjectName);

#ifdef RPE_DEBUG
    printf("%sObject Index Table: %s\n", &s_indent[MAX_INDENT-indent], s_objectNames[s_objects[nObject].nObjectNameIndex].filename);
#endif
    for (int i = 0; i < s_objects[nObject].nObjectIndexCount; i++)
    {
        if (s_objects[nObject].pIndexTable[i].offset >= nNextObjOffset)
        {
#ifdef RPE_DEBUG
            printf("%s Object Offset: %04d  Vars Offset: %d\n", &s_indent[MAX_INDENT-indent], s_objects[nObject].pIndexTable[i].offset, s_objects[nObject].pIndexTable[i].vars);
#endif
            // this skip logic here is to handle the case where there are multiple instances of the same object source included
            // either as an array of objects or as separately named objects
            bool bSkip = false;
            for (int j = 0; j < i; j++)
            {
                if (s_objects[nObject].pIndexTable[i].offset == s_objects[nObject].pIndexTable[j].offset)
                {
                    bSkip = true;
                }
            }
            if (!bSkip)
            {
                BuildTables(&(pObject[s_objects[nObject].pIndexTable[i].offset]), indent + 1, nCompileIndex);
            }
        }
#ifdef RPE_DEBUG
        else
        {
            printf("%s Method Offset: %04d  Locals size: %d\n", &s_indent[MAX_INDENT-indent], s_objects[nObject].pIndexTable[i].offset, s_objects[nObject].pIndexTable[i].vars);
        }
#endif
    }
}

//
// byte code scanning stuff
// borrowed from Dave Hein's spinsim code and then modified for my needs (mostly stripped down to just skip intelligently over byte code)
//

int SkipSignedOffset(unsigned char* pOpcode)
{
    return (*pOpcode < 0x80) ? 1 : 2;
}

int SkipUnsignedOffset(unsigned char* pOpcode)
{
    return (*pOpcode & 0x80) ? 2 : 1;
}

int ScanMathOpcode(unsigned char* pOpcode)
{
    bool execflag = false;
    int opcode = *pOpcode;

    if (opcode < 0xe0)
    {
        execflag = true;
        opcode += 0xe0 - 0x40;
    }

    // Execute the math op
    switch (opcode)
    {
        case 0xe0: // ror
        case 0xe1: // rol
        case 0xe2: // shr
        case 0xe3: // shl
        case 0xe4: // min
        case 0xe5: // max
        case 0xe6: // neg
        case 0xe7: // com
        case 0xe8: // and
        case 0xe9: // abs
        case 0xea: // or
        case 0xeb: // xor
        case 0xec: // add
        case 0xed: // sub
        case 0xee: // sar
        case 0xef: // rev
        case 0xf0: // andl
        case 0xf1: // encode
        case 0xf4: // mul
        case 0xf5: // mulh
        case 0xf2: // orl
        case 0xf3: // decode
        case 0xf6: // div
        case 0xf7: // mod
        case 0xf8: // sqrt
        case 0xf9: // cmplt
        case 0xfa: // cmpgt
        case 0xfb: // cmpne
        case 0xfc: // cmpeq
        case 0xfd: // cmple
        case 0xfe: // cmpgr
        case 0xff: // notl
            break;

        default:
            break;
    }

    return (execflag ? 0 : 1);
}

int ScanExtraOpcode(unsigned char* pOpcode, int opcode)
{
    int nOpSize = 0;

    opcode &= 0x7f;

    if (opcode >= 0x40 && opcode < 0x60) // math op
    {
        nOpSize += ScanMathOpcode(pOpcode);
    }
    else if ((opcode & 0x7e) == 0x00) // store
    {
    }
    else if ((opcode & 0x7a) == 0x02) // repeat, repeats
    {
        nOpSize += SkipSignedOffset(pOpcode);
    }
    else if ((opcode & 0x78) == 8) // randf, randr
    {
    }
    else if ((opcode & 0x7c) == 0x10) // sexb
    {
    }
    else if ((opcode & 0x7c) == 0x14) // sexw
    {
    }
    else if ((opcode & 0x7c) == 0x18) // postclr
    {
    }
    else if ((opcode & 0x7c) == 0x1c) // postset
    {
    }
    else if ((opcode & 0x78) == 0x20) // preinc
    {
    }
    else if ((opcode & 0x78) == 0x28) // postinc
    {
    }
    else if ((opcode & 0x78) == 0x30) // predec
    {
    }
    else if ((opcode & 0x78) == 0x38) // postdec
    {
    }
    else
    {
#ifdef _DEBUG
        printf("NOT IMPLEMENTED\n");
#endif
    }

    return nOpSize;
}


int ScanMemoryOpcode(unsigned char* pOpcode)
{
    int opcode = *pOpcode;
    int memfunc = opcode & 3;

    int nOpSize = 1;

    if (opcode < 0x80) // Compact offset
    {
    }
    else
    {
        if ((opcode & 0x0c) >> 2)
        {
            nOpSize += SkipUnsignedOffset(&pOpcode[nOpSize]);
        }
    }

    if (memfunc == 3)      // la
    {
    }
    else if (memfunc == 0) // ld
    {
    }
    else if (memfunc == 1) // st
    {
    }
    else                   // ex
    {
        opcode = pOpcode[nOpSize];
        nOpSize++;

        nOpSize += ScanExtraOpcode(&pOpcode[nOpSize], opcode);
    }

    return nOpSize;
}

int ScanRegisterOpcode(unsigned char* pOpcode, int operand)
{
    int opcode;
    int nOpSize = 0;
    int memfunc = (operand >> 5) & 3;

    if (memfunc == 1) // store
    {
    }
    else if (memfunc == 0) // load
    {
    }
    else if (memfunc == 2) // execute
    {
        opcode = *pOpcode;
        nOpSize++;

        nOpSize += ScanExtraOpcode(&pOpcode[nOpSize], opcode);
    }
    else
    {
#ifdef _DEBUG
        printf("Undefined register operation\n");
#endif
    }

    return nOpSize;
}

int ScanLowerOpcode(unsigned char* pOpcode, MethodUsage* pUsage, ObjectEntry* pObject, unsigned char* pMethodStart)
{
    int opcode = *pOpcode;
    int nOpSize = 1;

    if (opcode <= 3) // ldfrmr, ldfrm, ldfrmar, ldfrma
    {
    }
    else if (opcode == 0x04) // jmp
    {
        nOpSize += SkipSignedOffset(&pOpcode[nOpSize]);
    }
    else if (opcode >= 0x05 && opcode <= 0x07) // call, callobj, callobjx
    {
        int objnum = 0;

        if (opcode > 0x05)
        {
            objnum = pOpcode[nOpSize];
            nOpSize++;
            if (opcode == 0x07)
            {
                // indexed
            }

            // skip over invalid calls (happens when we scan strings as opcodes, this can go away when we fix scanning strings properly)
            if (objnum < 0 || objnum > (pObject->nObjectMethodCount + pObject->nObjectSubObjectCount)) 
            {
                return nOpSize + 1;
            }
        }

        int pubnum = pOpcode[nOpSize];
        nOpSize++;

        // skip over invalid calls (happens when we scan strings as opcodes, this can go away when we fix scanning strings properly)
        if (objnum == 0 && (pubnum < 0 || pubnum > pObject->nObjectMethodCount))
        {
            return nOpSize;
        }

        // need to update usage here
        if (pUsage->pCalls == 0)
        {
            pUsage->nCalls++;
        }
        else
        {
            pUsage->pCalls[pUsage->nCurrCall].opcode = (unsigned char)opcode;
            pUsage->pCalls[pUsage->nCurrCall].pubnum = (unsigned char)pubnum;
            pUsage->pCalls[pUsage->nCurrCall].callOffset = (unsigned int)((&pOpcode[1]) - pMethodStart);
            
            if (opcode > 0x05)
            {
                pUsage->pCalls[pUsage->nCurrCall].objnum = (unsigned char)objnum;
                pUsage->pCalls[pUsage->nCurrCall].objoffset = pObject->pIndexTable[objnum-1].offset;
                pUsage->pCalls[pUsage->nCurrCall].objaddress = &pObject->pObject[pUsage->pCalls[pUsage->nCurrCall].objoffset];
#ifdef RPE_DEBUG
                printf(" callobj %02X:%02X (%p)\n", pUsage->pCalls[pUsage->nCurrCall].objnum, pUsage->pCalls[pUsage->nCurrCall].pubnum, pUsage->pCalls[pUsage->nCurrCall].objaddress);
#endif
            }
            else
            {
                pUsage->pCalls[pUsage->nCurrCall].objnum = 0;
                pUsage->pCalls[pUsage->nCurrCall].objoffset = 0;
                pUsage->pCalls[pUsage->nCurrCall].objaddress = (pObject->pObject);
#ifdef RPE_DEBUG
                printf(" call %02X (%p)\n", pUsage->pCalls[pUsage->nCurrCall].pubnum, pUsage->pCalls[pUsage->nCurrCall].objaddress);
#endif
            }
            pUsage->nCurrCall++;
        }
    }
    else if (opcode == 0x08) // tjz
    {
        nOpSize += SkipSignedOffset(&pOpcode[nOpSize]);
    }
    else if (opcode == 0x09) // djnz
    {
        nOpSize += SkipSignedOffset(&pOpcode[nOpSize]);
    }
    else if (opcode == 0x0a) // jz
    {
        nOpSize += SkipSignedOffset(&pOpcode[nOpSize]);
    }
    else if (opcode == 0x0b) // jnz
    {
        nOpSize += SkipSignedOffset(&pOpcode[nOpSize]);
    }
    else if (opcode >= 0x0c && opcode <= 0x15)
    {
        if (opcode == 0x0c) // casedone
        {
        }
        else if (opcode == 0x0d) // casevalue
        {
            nOpSize += SkipSignedOffset(&pOpcode[nOpSize]);
        }
        else if (opcode == 0x0e) // caserange
        {
            nOpSize += SkipSignedOffset(&pOpcode[nOpSize]);
        }
        else if (opcode == 0x0f) // lookdone
        {
        }
        else if (opcode == 0x10) // lookupval
        {
        }
        else if (opcode == 0x11) // lookdnval
        {
        }
        else if (opcode == 0x12) // lookuprng
        {
        }
        else if (opcode == 0x13) // lookdnrng
        {
        }
        else if (opcode == 0x14) // pop
        {
        }
        else if (opcode == 0x15) // run
        {
        }
        else
        {
#ifdef _DEBUG
            printf("%2.2x - NOT IMPLEMENTED\n", opcode);
#endif
        }
    }
    else if (opcode >= 0x16 && opcode <= 0x23)
    {
        if (opcode == 0x16) // strsize
        {
        }
        else if (opcode == 0x17) // strcomp
        {
        }
        else if (opcode == 0x18) // bytefill
        {
        }
        else if (opcode == 0x19) // wordfill
        {
        }
        else if (opcode == 0x1a) // longfill
        {
        }
        else if (opcode == 0x1b) // waitpeq
        {
        }
        else if (opcode >= 0x1c && opcode <= 0x1e ) // bytemove, wordmove, longmove
        {
        }
        else if (opcode == 0x1f) // waitpne
        {
        }
        else if (opcode == 0x20) // clkset
        {
        }
        else if (opcode == 0x21) // cogstop
        {
        }
        else if (opcode == 0x22) // lockret
        {
        }
        else if (opcode == 0x23) // waitcnt
        {
        }
    }
    else if (opcode >= 0x24 && opcode <= 0x2f)
    {
        if (opcode >= 0x24 && opcode <= 0x26) // ldregx, stregx, exregx
        {
            int operand = ((opcode & 3) << 5);
            nOpSize += ScanRegisterOpcode(&pOpcode[nOpSize], operand);
        }
        else if (opcode == 0x27) // waitvid
        {
        }
        else if (opcode == 0x28 || opcode == 0x2c) // coginitret, coginit
        {
        }
        else if (opcode == 0x29 || opcode == 0x2d) // locknewret, locknew
        {
        }
        else if (opcode == 0x2a || opcode == 0x2b || opcode == 0x2e || opcode == 0x2f) // locksetret, lockclrret, lockset, lockclr
        {
        }
    }
    else if (opcode >= 0x30 && opcode <= 0x33) // abort, abortval, ret, retval
    {
    }
    else if (opcode >= 0x34 && opcode < 0x3c)
    {
        if (opcode == 0x35)        // dli0
        {
        }
        else if (opcode == 0x36)   // dli1
        {
        }
        else if (opcode == 0x34)   // dlim1
        {
        }
        else if (opcode == 0x37) // ldlip
        {
            nOpSize++;
        }
        else // ldbi, ldwi, ldmi, ldli
        {
            while (opcode-- >= 0x38)
            {
                nOpSize++;
            }
        }
    }
    else if (opcode == 0x3d) // ldregbit, stregbit, exregbit
    {
        int operand = pOpcode[nOpSize];
        nOpSize++;

        nOpSize += ScanRegisterOpcode(&pOpcode[nOpSize], operand);
    }
    else if (opcode == 0x3e) // ldregbits, stregbits, exregbits
    {
        int operand = pOpcode[nOpSize];
        nOpSize++;

        nOpSize += ScanRegisterOpcode(&pOpcode[nOpSize], operand);
    }
    else if (opcode == 0x3f) // ldreg, streg, exreg
    {
        int operand = pOpcode[nOpSize];
        nOpSize++;

        nOpSize += ScanRegisterOpcode(&pOpcode[nOpSize], operand);
    }
    else
    {
#ifdef _DEBUG
        printf("NOT PROCESSED\n");
#endif
    }

    return nOpSize;
}


int ScanOpcode(unsigned char* pOpcode, MethodUsage* pUsage, ObjectEntry* pObject, unsigned char* pMethodStart)
{
    if (*pOpcode < 0x40)
    {
        return ScanLowerOpcode(pOpcode, pUsage, pObject, pMethodStart);
    }
    else if (*pOpcode < 0xe0)
    {
        return ScanMemoryOpcode(pOpcode);
    }
    else
    {
        return ScanMathOpcode(pOpcode);
    }
}


void ScanMethod(unsigned char* pMethod, MethodUsage* pUsage, ObjectEntry* pObject)
{
#ifdef RPE_DEBUG
    for (int i = 0; i < pUsage->nLength; i++)
    {
        printf("%02x ", pMethod[i]);
    }
    printf("\n");
#endif

    // scan once to count calls
    int nOffset = 0;
    while (nOffset < pUsage->nLength)
    {
        nOffset += ScanOpcode(&pMethod[nOffset], pUsage, pObject, pMethod);
    }
    if (pUsage->nCalls > 0)
    {
        // if there were calls then allocate space and scan again to fill in call info
        pUsage->pCalls = new CallEntry[pUsage->nCalls];
        nOffset = 0;
        while (nOffset < pUsage->nLength)
        {
            nOffset += ScanOpcode(&pMethod[nOffset], pUsage, pObject, pMethod);
        }
    }
}

void ScanObjectMethods(ObjectEntry* pObjectEntry)
{
    for (int i = 0; i < pObjectEntry->nObjectMethodCount; i++)
    {
        unsigned char* pMethod = pObjectEntry->pObject + pObjectEntry->pIndexTable[i].offset;
        int nLength = 0;
        if (i < pObjectEntry->nObjectMethodCount-1)
        {
            nLength = pObjectEntry->pIndexTable[i+1].offset - pObjectEntry->pIndexTable[i].offset;
        }
        else
        {
            int nNextObjectOffset = *((unsigned short *)(pObjectEntry->pObject));
            nLength = nNextObjectOffset - pObjectEntry->pIndexTable[i].offset;
        }
        pObjectEntry->pMethods[i].nLength = nLength;
        ScanMethod(pMethod, &(pObjectEntry->pMethods[i]), pObjectEntry);
    }
}

void MarkCalls(MethodUsage* pMethod, ObjectEntry* pObject)
{
    if (pMethod->nCalled == 0)
    {
        pMethod->nCalled = 1;
        pObject->nMethodsCalled++;

        for (int nCall = 0; nCall < pMethod->nCalls; nCall++)
        {
            CallEntry* pCall = &(pMethod->pCalls[nCall]);
            if ( pCall->opcode == 5 ) // normal call
            {
                MarkCalls(&(pObject->pMethods[pCall->pubnum-1]), pObject);
            }
            else // obj call
            {
                ObjectEntry* pSubObject = GetObject(pCall->objaddress);
                MarkCalls(&(pSubObject->pMethods[pCall->pubnum-1]), pSubObject);
            }
        }
    }
}

void FindUnusedMethods(CompilerData* pCompilerData)
{
    for (int i = 0; i < (file_limit * file_limit); i++)
    {
        s_objects[i].pObject = 0;
        s_objects[i].nObjectMethodCount = 0;
        s_objects[i].nObjectSubObjectCount = 0;
        s_objects[i].nObjectIndexCount = 0;
        s_objects[i].nMethodsCalled = 0;
        s_objects[i].nNewObjectIndex = 0;
        s_objects[i].pIndexTable = 0;
        s_objects[i].pMethods = 0;
    }
    s_nNumObjects = 0;

    int nCompileIndex = 0;
    BuildTables(&(pCompilerData->obj[4]), 0, nCompileIndex);

    for (int i = 0; i < s_nNumObjects; i++)
    {
        ScanObjectMethods(&s_objects[i]);
    }

    ObjectEntry* pObject = &(s_objects[0]);
    MethodUsage* pMethod = &(pObject->pMethods[0]);
    MarkCalls(pMethod, pObject);

    for (int i = 0; i < s_nNumObjects; i++)
    {
        CheckForCogNewOrInit(&s_objects[i]);
    }
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
