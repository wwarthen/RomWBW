///////////////////////////////////////////////////////////////
//                                                           //
// Propeller Spin/PASM Compiler Command Line Tool 'OpenSpin' //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.    //
// Adapted from Jeff Martin's Delphi code by Roy Eltham      //
// See end of file for terms of use.                         //
//                                                           //
///////////////////////////////////////////////////////////////
//
// openspin.cpp
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../PropellerCompiler/CompileSpin.h"
#include "pathentry.h"

#define MAX_FILES           2048

static int  s_nFilesAccessed = 0;
static char s_filesAccessed[MAX_FILES][PATH_MAX];


static void Banner(void)
{
    fprintf(stdout, "Propeller Spin/PASM Compiler \'OpenSpin\' (c)2012-2018 Parallax Inc. DBA Parallax Semiconductor.\n");
    fprintf(stdout, "Version 1.00.81 Compiled on %s %s\n",__DATE__, __TIME__);
}

/* Usage - display a usage message and exit */
static void Usage(void)
{
    Banner();
    fprintf(stderr, "\
usage: openspin\n\
         [ -h ]                 display this help\n\
         [ -L or -I <path> ]    add a directory to the include path\n\
         [ -o <path> ]          output filename\n\
         [ -b ]                 output binary file format\n\
         [ -e ]                 output eeprom file format\n\
         [ -c ]                 output only DAT sections\n\
         [ -d ]                 dump out doc mode\n\
         [ -t ]                 output just the object file tree\n\
         [ -f ]                 output a list of filenames for use in archiving\n\
         [ -q ]                 quiet mode (suppress banner and non-error text)\n\
         [ -v ]                 verbose output\n\
         [ -p ]                 disable the preprocessor\n\
         [ -a ]                 use alternative preprocessor rules\n\
         [ -D <define> ]        add a define\n\
         [ -M <size> ]          size of eeprom (up to 16777216 bytes)\n\
         [ -s ]                 dump PUB & CON symbol information for top object\n\
         [ -u ]                 enable unused method elimination\n\
         <name.spin>            spin file to compile\n\
\n");
}

FILE* OpenFileInPath(const char *name, const char *mode)
{
    const char* pTryPath = NULL;

    FILE* file = fopen(name, mode);
    if (!file)
    {
        PathEntry* entry = NULL;
        while(!file)
        {
            pTryPath = MakeNextPath(&entry, name);
            if (pTryPath)
            {
                file = fopen(pTryPath, mode);
                if (file != NULL)
                {
                    break;
                }
            }
            else
            {
                break;
            }
        }
    }

    if (s_nFilesAccessed < MAX_FILES)
    {
        if (!pTryPath)
        {
#ifdef WIN32
            if (_fullpath(s_filesAccessed[s_nFilesAccessed], name, PATH_MAX) == NULL)
#else
            if (realpath(name, s_filesAccessed[s_nFilesAccessed]) == NULL)
#endif
            {
                strcpy(s_filesAccessed[s_nFilesAccessed], name);
            }
            s_nFilesAccessed++;
        }
        else
        {
            strcpy(s_filesAccessed[s_nFilesAccessed++], pTryPath);
        }
    }
    else
    {
        // should never hit this, but just in case
        printf("Too many files!\n");
        exit(-2);
    }

    return file;
}

// returns NULL if the file failed to open or is 0 length
char* LoadFile(const char* pFilename, int* pnLength, char** ppFilePath)
{
    char* pBuffer = 0;
    FILE* pFile = OpenFileInPath(pFilename, "rb");
    if (pFile != NULL)
    {
        // get the length of the file by seeking to the end and using ftell
        fseek(pFile, 0, SEEK_END);
        *pnLength = ftell(pFile);

        if (*pnLength > 0)
        {
            pBuffer = (char*)malloc(*pnLength+1); // allocate a buffer that is the size of the file plus one char
            pBuffer[*pnLength] = 0; // set the end of the buffer to 0 (null)

            // seek back to the beginning of the file and read it in
            fseek(pFile, 0, SEEK_SET);
            fread(pBuffer, 1, *pnLength, pFile);
        }

        fclose(pFile);

        *ppFilePath = &(s_filesAccessed[s_nFilesAccessed-1][0]);
    }
    else
    {
        return 0;
    }

    return pBuffer;
}

void FreeFileBuffer(char* pBuffer)
{
    if (pBuffer != 0)
    {
        free(pBuffer);
    }
}

int main(int argc, char* argv[])
{
    CompilerConfig compilerConfig;

    char* infile = NULL;
    char* outfile = NULL;
    char* p = NULL;
    s_nFilesAccessed = 0;

    // go through the command line arguments, skipping over any -D
    for(int i = 1; i < argc; i++)
    {
        // handle switches
        if(argv[i][0] == '-')
        {
            switch(argv[i][1])
            {
            case 'I':
            case 'L':
                if(argv[i][2])
                {
                    p = &argv[i][2];
                }
                else if(++i < argc)
                {
                    p = argv[i];
                }
                else
                {
                    Usage();
                    CleanupPathEntries();
                    return 1;
                }
                AddPath(p);
                break;

            case 'M':
                if (argv[i][2])
                {
                    p = &argv[i][2];
                }
                else if(++i < argc)
                {
                    p = argv[i];
                }
                else
                {
                    Usage();
                    CleanupPathEntries();
                    return 1;
                }
                sscanf(p, "%d", &(compilerConfig.eeprom_size));
                if (compilerConfig.eeprom_size > 16777216)
                {
                    Usage();
                    CleanupPathEntries();
                    return 1;
                }
                break;

            case 'o':
                if(argv[i][2])
                {
                    outfile = &argv[i][2];
                }
                else if(++i < argc)
                {
                    outfile = argv[i];
                }
                else
                {
                    Usage();
                    CleanupPathEntries();
                    return 1;
                }
                break;

            case 'p':
                compilerConfig.bUsePreprocessor = false;
                break;

            case 'a':
                compilerConfig.bAlternatePreprocessorMode = true;
                break;

            case 'D':
                if (compilerConfig.bUsePreprocessor)
                {
                    if (argv[i][2])
                    {
                        p = &argv[i][2];
                    }
                    else if(++i < argc)
                    {
                        p = argv[i];
                    }
                    else
                    {
                        Usage();
                        CleanupPathEntries();
                        return 1;
                    }
                    // just skipping these for now
                }
                else
                {
                    Usage();
                    CleanupPathEntries();
                    return 1;
                }
                break;

            case 't':
                compilerConfig.bFileTreeOutputOnly = true;
                break;

            case 'f':
                compilerConfig.bFileListOutputOnly = true;
                break;

            case 'b':
                compilerConfig.bBinary = true;
                break;

            case 'c':
                compilerConfig.bDATonly = true;
                break;

            case 'd':
                compilerConfig.bDocMode = true;
                break;

            case 'e':
                compilerConfig.bBinary = false;
                break;

            case 'q':
                compilerConfig.bQuiet = true;
                break;

            case 'v':
                compilerConfig.bVerbose = true;
                break;

            case 's':
                compilerConfig.bDumpSymbols = true;
                break;

            case 'u':
                compilerConfig.bUnusedMethodElimination = true;
                break;

            case 'h':
            default:
                Usage();
                CleanupPathEntries();
                return 1;
                break;
            }
        }
        else // handle the input filename
        {
            if (infile)
            {
                Usage();
                CleanupPathEntries();
                return 1;
            }
            infile = argv[i];
        }
    }

    // must have input file
    if (!infile)
    {
        Usage();
        CleanupPathEntries();
        return 1;
    }

    if (compilerConfig.bFileTreeOutputOnly || compilerConfig.bFileListOutputOnly || compilerConfig.bDumpSymbols)
    {
        compilerConfig.bQuiet = true;
    }

    // finish the include path
    AddFilePath(infile);

    char outputFilename[256];
    if (!outfile)
    {
        // create *.binary filename from user passed in spin filename
        strcpy(&outputFilename[0], infile);
        const char* pTemp = strstr(&outputFilename[0], ".spin");
        if (pTemp == 0)
        {
            printf("ERROR: spinfile must have .spin extension. You passed in: %s\n", infile);
            Usage();
            CleanupPathEntries();
            return 1;
        }
        else
        {
            int offset = (int)(pTemp - &outputFilename[0]);
            outputFilename[offset+1] = 0;
            if (compilerConfig.bDATonly)
            {
                strcat(&outputFilename[0], "dat");
            }
            else if (compilerConfig.bBinary)
            {
                strcat(&outputFilename[0], "binary");
            }
            else 
            {
                strcat(&outputFilename[0], "eeprom");
            }
        }
    }
    else // use filename specified with -o
    {
        strcpy(outputFilename, outfile);
    }

    if (!compilerConfig.bQuiet)
    {
        Banner();
        printf("Compiling...\n%s\n", infile);
    }

    InitCompiler(&compilerConfig, LoadFile, FreeFileBuffer);

    if (compilerConfig.bUsePreprocessor)
    {
        // go through the command line arguments again, this time only processing -D
        for(int i = 1; i < argc; i++)
        {
            // handle switches
            if(argv[i][0] == '-')
            {
                if (argv[i][1] == 'D')
                {
                    if (argv[i][2])
                    {
                        p = &argv[i][2];
                    }
                    else if(++i < argc)
                    {
                        p = argv[i];
                    }
                    else
                    {
                        Usage();
                        ShutdownCompiler();
                        CleanupPathEntries();
                        return 1;
                    }

                    // add any predefined symbols here - note that when using the 
                    // "alternate" rules, these symbols have a null value - i.e.
                    // they are just "defined", but are not used in macro substitution
                    SetDefine(p, (compilerConfig.bAlternatePreprocessorMode ? "" : "1"));
                }
            }
        }

        // add symbols with predefined values here
        SetDefine("__SPIN__", "1");
        SetDefine("__TARGET__", "P1");
    }

    int nLength = 0;
    unsigned char* pBuffer = CompileSpin(infile, &nLength);

    if (pBuffer)
    {
        FILE* pFile = fopen(outputFilename, "wb");
        if (pFile)
        {
            fwrite(pBuffer, nLength, 1, pFile);
            fclose(pFile);
        }
    }
    else
    {
        // compiler put out an error
        ShutdownCompiler();
        CleanupPathEntries();
        return 1;
    }

    if (compilerConfig.bFileListOutputOnly)
    {
        for (int i = 0; i < s_nFilesAccessed; i++)
        {
            for (int j = i+1; j < s_nFilesAccessed; j++)
            {
                if (strcmp(s_filesAccessed[i], s_filesAccessed[j]) == 0)
                {
                    s_filesAccessed[j][0] = 0;
                }
            }
        }

        for (int i = 0; i < s_nFilesAccessed; i++)
        {
            if (s_filesAccessed[i][0] != 0)
            {
                printf("%s\n", s_filesAccessed[i]);
            }
        }
    }


    ShutdownCompiler();
    CleanupPathEntries();

    return 0;
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
