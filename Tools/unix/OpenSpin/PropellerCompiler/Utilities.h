//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// Utilities.h
//

#ifndef _UTILITIES_H_
#define _UTILITIES_H_

extern void SetPrint(char* pDestination, int limit);
extern bool PrintChr(char theChar);
extern bool PrintString(const char* theString);
extern bool PrintLong(int value);
extern bool PrintWord(short value);
extern bool PrintByte(char value);
extern bool PrintHex(char value);
extern bool PrintDecimal(int value);
extern bool PrintSymbol(const char* pSymbolName, unsigned char type, int value, int value_2);
extern bool PrintObj();
extern bool DocPrint(char theChar);

extern char Uppercase(char theChar);

extern bool CheckWordChar(char theChar);
extern bool CheckHex(char theChar, char& digitValue);
extern bool CheckDigit(char theChar, char& digitValue, char numberBase);
extern bool CheckPlus(char theChar);
extern bool CheckLocal(bool& bLocal);

extern bool GetFloat(char* pSource, int& sourceOffset, int& value);
extern bool GetSymbol(int* length);
extern bool GetObjSymbol(int type, char id);

extern bool GetCommaOrEnd(bool& bComma);
extern bool GetCommaOrRight(bool& bComma);
extern bool GetPipeOrEnd(bool& bPipe);

extern bool GetFilename(int& filenameStart, int& filenameFinish);

extern void EnterInfo();
extern bool EnterObj(unsigned char value);
extern bool EnterObjLong(int value);

extern bool IncrementAsmLocal();

extern bool AddFileName(int& fileCount, int& fileIndex, char* pFilenames, int* pNameStart, int* pNameFinish, int error);
extern bool AddPubConListByte(char value);
extern bool AddSymbolToPubConList();
extern bool ConAssign(bool bFloat, int value);
extern bool HandleConSymbol(int pass);

extern int rol(unsigned int value, int places);
extern int ror(unsigned int value, int places);

// these is in ExpressionResolver.cpp
extern bool GetTryValue(bool bMustResolve, bool bInteger, bool bOperandMode = false);
extern int GetResult();

//
// Simple Hash Table (used by the Symbol Engine)
//

class Hashable
{
public:
    virtual ~Hashable()
    {
    }
};

struct HashNode
{
    int         key;
    Hashable*   pValue;
    HashNode*   pNext;
    HashNode*   pNextList;

    ~HashNode()
    {
        if (pNext)
        {
            delete pNext;
        }
        delete pValue;
    }
};

class HashTable
{
private:
    HashNode**  m_pTable;
    int         m_tableSize;
    HashNode*   m_pListHead;
    HashNode*   m_pListTail;

public:
    HashTable(int tableSize)
        : m_tableSize(tableSize)
        , m_pListHead(0)
        , m_pListTail(0)
    {
        m_pTable = new HashNode*[tableSize];
        for(int i = 0; i < m_tableSize; i++)
        {
            m_pTable[i] = 0;
        }
    }
    ~HashTable()
    {
        for(int i = 0; i < m_tableSize; i++)
        {
            if (m_pTable[i] != 0)
            {
                delete m_pTable[i];
                m_pTable[i] = 0;
            }
        }
        delete [] m_pTable;
        m_pTable = 0;
        m_pListHead = m_pListTail = 0;
    }

    // insert a new node in the table with the given key and value
    void Insert(int key, Hashable* pValue)
    {
        unsigned int bucket = (unsigned int)key % m_tableSize;

        HashNode* pNode = new HashNode;
        pNode->key = key;
        pNode->pValue = pValue;
        pNode->pNext = m_pTable[bucket];
        pNode->pNextList = 0;

        m_pTable[bucket] = pNode;

        if ( m_pListTail )
        {
            m_pListTail->pNextList = pNode;
            m_pListTail = pNode;
        }
        else
        {
            m_pListHead = m_pListTail = pNode;
        }
    }

    HashNode* First()
    {
        return m_pListHead;
    }

    HashNode* Last()
    {
        return m_pListTail;
    }

    HashNode* Next(HashNode* pCurrent)
    {
        return (pCurrent != 0) ? pCurrent->pNextList : 0;
    }

    // find the first node with a matching key
    // returns 0 if not found
    HashNode* FindFirst(int key)
    {
        unsigned int bucket = (unsigned int)key % m_tableSize;
        if (m_pTable[bucket] != 0)
        {
            HashNode* pNode = m_pTable[bucket];
            while (pNode != 0)
            {
                if (pNode->key == key)
                {
                    return pNode;
                }
                pNode = pNode->pNext;
            }
        }

        return 0;
    }

    // find the next node with a matching key
    // returns 0 if not found
    HashNode* FindNext(HashNode* pCurrent)
    {
        if (pCurrent->pNext != 0 && pCurrent->pNext->key == pCurrent->key)
        {
            return pCurrent->pNext;
        }

        return 0;
    }

    // calculate a hash value of a zero terminated string (uppercased)
    // uses Jenkins One-at-a-time hash function
    int GetStringHashUppercase(const char* s)
    {
        int hash = 0;
        while (*s != 0)
        {
            int c = *s;
            c = c - (32 * (c >= 'a' && c <= 'z'));
            hash += c;
            hash += (hash << 10);
            hash ^= (hash >> 6);
            s++;
        }
        hash += (hash << 3);
        hash ^= (hash >> 11);
        hash += (hash << 15);
        return hash;
    }

    // calculate a hash value of a zero terminated string
    // uses Jenkins One-at-a-time hash function
    int GetStringHash(const char* s)
    {
        int hash = 0;
        while (*s != 0)
        {
            hash += *s;
            hash += (hash << 10);
            hash ^= (hash >> 6);
            s++;
        }
        hash += (hash << 3);
        hash ^= (hash >> 11);
        hash += (hash << 15);
        return hash;
    }
};


class HeirarchyNode
{
public:
    HeirarchyNode* m_pNextSibling;
    HeirarchyNode* m_pParent;

    HeirarchyNode()
        : m_pNextSibling(0)
        , m_pParent(0)
    {
    }

    ~HeirarchyNode()
    {
        if (m_pNextSibling)
        {
            delete m_pNextSibling;
        }
    }
};

class Heirarchy
{
public:
    HeirarchyNode*  m_pRoot;

    Heirarchy()
        : m_pRoot(0)
    {
    }
    ~Heirarchy()
    {
        delete m_pRoot;
    }

    void AddNode(HeirarchyNode* pValue, HeirarchyNode* pParent)
    {
        if (m_pRoot == 0)
        {
            m_pRoot = pValue;
        }
        else
        {
            if (pParent)
            {
                pValue->m_pNextSibling = pParent->m_pNextSibling;
                pParent->m_pNextSibling = pValue;
            }
            else
            {
                pValue->m_pNextSibling = m_pRoot->m_pNextSibling;
                m_pRoot->m_pNextSibling = pValue;
            }
        }
    }
 };

#endif // _UTILITIES_H_

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
