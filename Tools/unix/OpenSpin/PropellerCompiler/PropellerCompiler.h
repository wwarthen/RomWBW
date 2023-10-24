//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// PropellerCompiler.h
//

#ifndef _PROPELLER_COMPILER_H_
#define _PROPELLER_COMPILER_H_

#include "UnusedMethodUtils.h"

//
// OpenSpin code uses _stricmp() which is the VC++ name for the function.
// this needs to be remapped to stricmp or strcasecmp depending on the compiler and OS being compiled on
// GCC prior to version 4.8 have strcasecmp on both linux and windows
// GCC 4.8 and newer on linux appears to still have strcasecmp, but GCC 4.8 and newer on windows does not (it has stricmp instead)
//
#if defined(__linux__)
// we are on linux, then always use strcasecmp
#define _stricmp strcasecmp
#else
#if __GNUC__
// if GCC version is 4.8 or greater use stricmp, else use strcasecmp
#if __GNUC__ > 4 || (__GNUC__ == 4 && (__GNUC_MINOR__ >= 8 ))
#define _stricmp stricmp
#else
#define _stricmp strcasecmp
#endif
#endif
#endif

//
// no longer compatible with Prop Tool / Propellent
//

#define language_version    '0'
#define loc_limit           0x8000
#define var_limit           0x8000
#define min_obj_limit       0x00020000
#define file_limit          32
#define data_limit          0x20000
#define info_limit          1000
#define distiller_limit     0x4000
#define symbol_limit        256 // was 32 
#define pubcon_list_limit   0x8000
#define block_nest_limit    8
#define block_stack_limit   4096
#define case_limit          256
#define if_limit            16
#define str_limit           256
#define str_buffer_limit    0x8000


enum infoType
{
    info_con = 0,       // data0 = value (must be followed by info_con_float)
    info_con_float,     // data0 = value
    info_dat,           // data0/1 = obj start/finish
    info_dat_symbol,    // data0 = value, data2 = offset, data1 = size
    info_pub,           // data0/1 = obj start/finish, data2/3 = name start/finish
    info_pri,           // data0/1 = obj start/finish, data2/3 = name start/finish
    info_pub_param,     // data0 = pub index, data3 = param index, data2/3 = pub name start/finish
    info_pri_param      // data0 = pri index, data3 = param index, data2/3 = pri name start/finish
};

// Propeller Compiler Interface Structure
struct CompilerData
{
    bool            error;          // Compilation status; error if true, success if false
    const char*     error_msg;      // Pointer to error string

    int             compile_mode;   // Compile Mode; 0 = normal compile, 1 = Propeller Development compile

    char*           source;         // Pointer to source data
    int             source_start;   // Offending item start (if error)
    int             source_finish;  // Offending item end (+1) (if error)

    char*           list;           // Pointer to list data
    unsigned int    list_limit;     // Max size of list data
    unsigned int    list_length;    // Length of list data

    char*           doc;            // Pointer to document data
    unsigned int    doc_limit;      // Max size of document data
    unsigned int    doc_length;     // Length of document data

    unsigned char*  obj;                // Object binary for currently being compiled obj
    int             obj_ptr;            // Length of Object binary
    int             obj_limit;          // size of buffer allocated for obj

    int             obj_files;                      // Number of object files referenced by source
    char            obj_filenames[file_limit*256];  // Object filenames
    int             obj_name_start[file_limit];     // Starting char of each filename
    int             obj_name_finish[file_limit];    // Ending character (+1) of each filename
    int             obj_offsets[file_limit];        // Offsets of final objects in ObjData
    int             obj_lengths[file_limit];        // Lengths of final objects in ObjData
    unsigned char   obj_data[data_limit];           // Final top-level object binary
    int             obj_instances[file_limit];      // Instances per filename
    char            obj_title[256];                 // Object Filename (without path)

    int             dat_files;                      // Number of DAT files referenced by source
    char            dat_filenames[file_limit*256];  // DAT filenames
    int             dat_name_start[file_limit];     // Starting char of each filename
    int             dat_name_finish[file_limit];    // Ending character (+1) of each filename
    int             dat_offsets[file_limit];        // Offsets of final objects in DatData
    int             dat_lengths[file_limit];        // Lengths of final objects in DatData
    unsigned char   dat_data[data_limit];           // Binary data

    int             pre_files;                      // Number of Precompile files referenced by source
    char            pre_filenames[file_limit*256];  // Precompile filenames
    int             pre_name_start[file_limit];		// Starting char of each filename
    int             pre_name_finish[file_limit];	// Ending character (+1) of each filename

    int             arc_files;                      // Number of Archive files referenced by source
    char            arc_filenames[file_limit*256];  // Archive filenames
    int             arc_name_start[file_limit];     // Starting char of each filename
    int             arc_name_finish[file_limit];    // Ending character (+1) of each filename

    int             info_count;                     // Number of information records for object
    int             info_start[info_limit];         // Start of source related to this info
    int             info_finish[info_limit];        // End (+1) of source related to this info
    int             info_type[info_limit];          // 0 = CON, 1 CON(float), 2 = DAT, 3 = DAT Symbol, 4 = PUB, 5 = PRI, 6 = PUB_PARAM, 7 = PRI_PARAM
    int             info_data0[info_limit];         // Info field 0: if CON = Value, if DAT/PUB/PRI = Start addr in object, if DAT Symbol = value, if PARAM = pub/pri index
    int             info_data1[info_limit];         // Info field 1: if DAT/PUB/PRI = End+1 addr in object, if DAT Symbol = size, if PARAM = param index
    int             info_data2[info_limit];         // Info field 2: if PUB/PRI/PARAM = Start of pub/pri name in source, if DAT Symbol = offset (in cog)
    int             info_data3[info_limit];         // Info field 3: if PUB/PRI/PARAM = End+1 of pub/pri name in source
    int             info_data4[info_limit];         // Info field 4: if PUB/PRI = index|param count

    int             distilled_longs;                // Total longs optimized out of object
    unsigned char   first_pub_parameters;
    int             stack_requirement;              // Stack requirement for top-level object

    unsigned char   clkmode;
    int             clkfreq;
    int             debugbaud;                      // 0 = no debug, > 0 = debug at DebugBaud rate

    bool            bDATonly;                       // only compile DAT sections (into obj)

    // only add new stuff below here

    bool            bBinary;                        // true for binary, false for eeprom

    unsigned int    eeprom_size;                    // size of eeprom
    unsigned int    vsize;                          // used to hold last vsize (in case it is greater than 65536)
    unsigned int    psize;                          // used to hold last psize (in case it is greater than 65536)

    char            current_filename[256];          // name of object being compiled at the moment
    bool            bUnusedMethodElimination;       // true if unused method elimination is on
    bool            bFinalCompile;                  // set to true after unused method scan complete

    int             unused_obj_files;               // number of unused object files
    char            obj_unused[file_limit*256];     // hold filenames of unused objects

    int             unused_methods;                 // number of unused methods
    char            method_unused[32*file_limit*symbol_limit]; // hold names of unused methods

    char*           current_file_path;              // full path of the current file being compiled (points to entries in s_filesAccessed[])
};

// public functions
extern CompilerData* InitStruct();
extern void Cleanup();
extern const char* Compile1();
extern const char* Compile2();
extern bool GetErrorInfo(int& lineNumber, int& column, int& offsetToStartOfLine, int& offsetToEndOfLine, int& offendingItemStart, int& offendingItemEnd);

#endif // _PROPELLER_COMPILER_H_

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
