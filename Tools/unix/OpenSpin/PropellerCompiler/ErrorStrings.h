//////////////////////////////////////////////////////////////
//                                                          //
// Propeller Spin/PASM Compiler                             //
// (c)2012-2016 Parallax Inc. DBA Parallax Semiconductor.   //
// Adapted from Chip Gracey's x86 asm code by Roy Eltham    //
// See end of file for terms of use.                        //
//                                                          //
//////////////////////////////////////////////////////////////
//
// ErrorStrings.h
//

#ifndef _ERROR_STRINGS_H_
#define _ERROR_STRINGS_H_

enum errorType
{
    error_none = -1,
    error_ainl = 0,
    error_aioor,
    error_bmbpbb,
    error_bdmbifc,
    error_bnso,
    error_ccsronfp,
    error_ce32b,
    error_coxmbs,
    error_csmnexc,
    error_cxnawrc,
    error_cxswcm,
    error_dbz,
    error_drcex,
    error_eaaeoeol,
    error_eaasme,
    error_eaasmi,
    error_eaboor,
    error_eacn,
    error_eacuool,
    error_eads,
    error_eaet,
    error_eaiov,
    error_eals,
    error_eamvaa,
    error_easn,
    error_easoon,
    error_eatq,
    error_eauon,
    error_eav,
    error_eaucnop,
    error_eaunbwlo,
    error_eaupn,
    error_eaurn,
    error_eausn,
    error_eauvn,
    error_ebwol,
    error_ecoeol,
    error_ecolon,
    error_ecomma,
    error_ecor,
    error_ecoxmbs,
    error_edot,
    error_eeol,
    error_eelcoeol,
    error_efrom,
    error_eitc,
    error_eleft,
    error_eleftb,
    error_epoa,
    error_epoeol,
    error_epound,
    error_erb,
    error_erbb,
    error_eright,
    error_erightb,
    error_es,
    error_esoeol,
    error_eto,
    error_ftl,
    error_fpcmbw,
    error_fpnaiie,
    error_fpo,
    error_ibn,
    error_icms,
    error_idbn,
    error_idfnf,
    error_ifc,
    error_ifufiq,
    error_inaifpe,
    error_internal,
    error_ionaifpe,
    error_loxce,
    error_loxnbe,
    error_loxuoe,
    error_loxudfe,
    error_loxupfe,
    error_loxuafe,
    error_litl,
    error_loxdse,
    error_loxee,
    error_loxlve,
    error_loxpe,
    error_loxspoe,
    error_micuwn,
    error_nce,
    error_nprf,
    error_ocmbf1tx,
    error_odo,
    error_oefl,
    error_oex,
    error_oexl,
    error_oinah,
    error_omblc,
    error_pclo,
    error_rainl,
    error_raioor,
    error_rinah,
    error_rinaiom,
    error_safms,
    error_sccx,
    error_scmr,
    error_sdcobu,
    error_sexc,
    error_siad,
    error_snah,
    error_sombl,
    error_sombs,
    error_srccex,
    error_ssaf,
    error_stif,
    error_tioawarb,
    error_tmsc,
    error_tmscc,
    error_tmvsid,
    error_uc,
    error_urs,
    error_us,
    error_vnao
};

extern const char* g_pErrorStrings[];

#endif // _ERROR_STRINGS_H_

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
