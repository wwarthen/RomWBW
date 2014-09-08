                   ZCPR Version 1.0 Release Notice



  Greetings, Everyone,

       I  am  very pleased to announce (appropriately at  Christmas 
  time,  so  Merry Christmas) the formal release of ZCPR -- a  Z80-
  based Command Processor Replacement.   This program replaces  the 
  CP/M CCP and greatly extends its capabilities.

       Some  of you may have heard of CCPZ and MCPZ during  various 
  discussions.  For those who have heard of these programs, ZCPR is 
  the  Baseline System to be released into the public  domain.   It 
  was derived from CCPZ Version 4.0, and is an enhancement of this.  
  It  contains  many  internal differences which  are  not  readily 
  noticable  to the CCPZ user,  and some new key human  engineering 
  design  changes over CCPZ Version 4.0 (specifically in  the  SAVE 
  and  REN commands).   For those of you who have been  considering 
  design  changes,  including  the  unsanctioned  Version  4.1  and 
  numerous  Version  4.2  implementations (these fell  out  of  the 
  control of CCP-GROUP),  ZCPR Version 1.0 is the released baseline 
  which  CCP-GROUP has decided upon for public release.   There are 
  several internal "problems" with CCPZ Version 4.0 which have been 
  resolved  to the satisfaction of the recent working  majority  of 
  CCP-GROUP.   Hence,  I  (and I believe the majority of the above-
  named  CCP-GROUP  subset) strongly recommend backing up  to  ZCPR 
  Version 1.0 and implementing your modifications from that.

       Now, getting back to everyone in general, ZCPR is the result 
  of  a Group Effort by CCP-GROUP,  a somewhat closely-nit group of 
  individuals.  For the individual credits,  they are listed in the 
  ASM and DOC files, and I sincerely apologize if I omitted anyone.  
  If I did, the corrections will be issued later.

       ZCPR  is the result of several months of rather diligent and 
  fascinating  work.   It completely replaces the  Console  Command 
  Processor   of   CP/M  and  will  only  run  on  Z80-based   CP/M 
  microcomputer  systems.   CP/M  is required in order to  run  it, 
  since  a "heart" of CP/M,  the BDOS,  is NOT provided with  ZCPR.  
  The MAC Assembler is required to assemble it.  So far, based upon 
  both user feedback and our own experiences,  we feel that ZCPR is 
  a significant contribution to the Public Domain, and everyone who 
  has used it greatly prefers it over standard CP/M.


       ZCPR  is being released for Public Distribution through  the 
  SIG/M User's Group of the Amateur Computer Group of NJ.   In  the 
  spirit of Public Domain software,  ZCPR is by no means a panacea, 
  but  it IS a very nice stepping stone,  and you are encouraged to 
  feel free to modify it to please yourselves.   Future releases of 
  ZCPR are quite possible,  but said releases from CCP-GROUP should 
  not happen for some time.  ZCPR has been extensively tested, and, 
  although  no software can be claimed to be perfect unless  it  is 
  absolutely  trivial,  CCP-GROUP knows of no functional errors  in 
  ZCPR Version 1.0.




                                                Page 1





                   ZCPR Version 1.0 Release Notice



       For   those  interested  in  pursuing  acquisition  of  ZCPR 
  further,  I  recommend reviewing the HELP File (ZCPR.HLP  in  the 
  SIG/M  Release).   The  opening Information Section gives a  fair 
  description  of some,  but not all,  of the interesting  features 
  supported by ZCPR and NOT found in the CP/M CCP.   It is  roughly 
  16K long and should not take too long to print out.

       The  next page of this message presents several displays and 
  some information on what files compose the ZCPR system.

       CCP-GROUP hopes you enjoy using ZCPR.




                                     Richard Conn








































                                                Page 2





                   ZCPR Version 1.0 Release Notice




                 XDIR2 Listing of All Relevant Files

  ZCPR FILES ... ET AL
  XDIR II  Version 4.8, Vertical Listing by File Type
  User Number:   0, File Attributes:  Non-System  

  Filename.Typ Size K   Filename.Typ Size K   Filename.Typ Size K 
  -------- --- ------   -------- --- ------   -------- --- ------
  <Disk Name >      0   MAC     .COM     12   ZCPR    .MSG      6 
  BDOSLOC .ASM      2   SYSGEN  .COM      2   ZCPR    .WS      40 
  ZCPR    .ASM     52   ZCPR    .DOC     46   ZCPRMSG .WS       6 
  CPM     .BIN     12   ZCPR    .HLP     16
  B:     34 Entries &     14 Files -    172K Bytes Remaining
  File Data:              11 Files -    194K Bytes Displayed

                      CRCK Values for Key Files

  File:  ZCPR    .WS              CRC = A2 C2

  File:  ZCPR    .DOC             CRC = 94 B7

  File:  ZCPR    .HLP             CRC = 26 9D

  File:  ZCPR    .ASM             CRC = 7A 46

  File:  BDOSLOC .ASM             CRC = EB D4

                        Explanation of Files

  ZCPR.ASM  -- Source  to  ZCPR;  must  be  assembled  by  MAC  and 
                 customized by user for his particular system

  ZCPR.HLP  -- HELP File for ZCPR;  can be read by HELP Version 2.0 
                 or  simply  TYPEd out;  read this to  see  a  fair 
                 summary of what ZCPR can do

  ZCPR.DOC   -- Full   Documentation   on   ZCPR;   this   includes 
                 installation  notes,   customization  notes,   and 
                 detail which expands upon the ZCPR.HLP File

  ZCPR.WS -- WordStar File from which ZCPR.DOC was created

  ZCPR.MSG -- Introductory message on ZCPR

  ZCPRMSG.WS -- WordStar File from which ZCPR.MSG was created

  BDOSLOC.ASM -- BDOS and CCP Locator; this program is handy during 
                 initial  installation  of  ZCPR  and  its  use  is 
                 documented in ZCPR.DOC






                                                Page 3





