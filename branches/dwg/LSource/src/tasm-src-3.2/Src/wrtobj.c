/****************************************************************************
 *  $Id: wrtobj.c 1.5 2001/09/23 15:17:25 toma Exp $
 **************************************************************************** 
 *  File: wrtobj.c
 *
 *  Description:
 *    Modules to write object records for TASM, the table driven assembler.
 *
 *    Copyright 1985-1995 Speech Technology Incorporated.
 *    Copyright 1997-2001 Squak Valley Software.
 *    Restrictions apply to the duplication of this software.
 *    See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *    Thomas N. Anderson
 *    Squak Valley Software
 *    837 Front Street South
 *    Issaquah, WA  98027
 *
 *
 *    See rlog for history.
 */

//static char *id_wrtobj_c = "$Id: wrtobj.c 1.5 2001/09/23 15:17:25 toma Exp $";

/* INCLUDES */
#include        "tasm.h"

#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif

/* EXTERNALS */
extern  ushort  Debug;

/*
 * Function: wrtobj()
 *
 * Description:
 *     Write the object code to the object file.
 *     Write in the object format selected on the command line (Intel
 *     hex as default).
 *
 */

void
wrtobj(
pc_t    firstpc,        /* Byte address of the first object byte      */
pc_t    lastpc,         /* Byte address of the last object byte + 1   */
ushort  bytes_per_rec)  /* Number of bytes per hex record             */
{
    ushort   i;
    ushort   checksum;
    ushort   rec_type;
    ushort   nbytes;
    char    buf[LINESIZE];
    char    *p;
    ubyte   op;
    pc_t    pc;

    extern  obj_t       Obj_format;
    extern  FILE        *Fp_object;
    extern  pc_t        First_pc;
    extern  int         Codegen;

    DEBUG2("wrtobj: %lx %lx\n",firstpc, lastpc);

    /* Make sure we actually generated some code. */
    if((lastpc == firstpc) && (First_pc > 0))return;
    if((lastpc == firstpc) && (Codegen == FALSE))return;

    pc = firstpc;
 
    if(Obj_format == BINARY_OBJ)
    {
        while(pc < lastpc)
        {
            op = getop(pc++);
            fwrite((char *)&op,1,1,Fp_object);
        }

    } 
    else
    {

        while(pc < lastpc)
        {
            nbytes = (ushort)(lastpc - pc); 
            if(nbytes > bytes_per_rec)nbytes = bytes_per_rec;
            if(nbytes == 0)return;

            rec_type = 0;
            checksum = nbytes + rec_type + (ushort)(pc & 0xff) + 
                                           (ushort)((pc >> 8) & 0xff);
            p = buf;

            switch (Obj_format){
            case MOSTECH_OBJ:
                sprintf(buf,";%02X%04lX",nbytes,pc);
                break;

            case INTEL_OBJ:
                sprintf(buf,":%02X%04lX%02X",nbytes,pc,rec_type);
                break;

            case INTELWORD_OBJ:
                /* Same as INTEL_OBJ, but convert PC to a word address */
                sprintf(buf,":%02X%04lX%02X",nbytes,(pc>>1),rec_type);
                break;

            case MOTOROLA_OBJ:
                sprintf(buf,"S1%02X%04lX",(nbytes+3),pc);
                break;

				/* Should not get here (handled above).  Put here for lint */
            case BINARY_OBJ:
                break;

            default:
                errlog("Invalid Object file type.", PASS2_ONLY);
                break;

            }

            for(i = 0; i < nbytes; i++)
            {
                op = getop(pc++);
                checksum += op;
                while(*(++p)) /* void */;
                sprintf(p,"%02X",op);
            }

            while(*(++p)) /* void */ ;

            switch (Obj_format){
            case MOSTECH_OBJ:
                sprintf(p,"%04X\n",checksum);
                break;

            case INTELWORD_OBJ:
            case INTEL_OBJ:
                /* For Intel we need to negate the checksum and mask.
                 * Invert and add one (instead of negate) since we are
                 * using unsigned types.
                 */
                checksum = ((~checksum)+1) & 0xff;
                sprintf(p,"%02X\n",checksum);
                break;

            case MOTOROLA_OBJ:
                checksum = (~((ushort)checksum+3)) & 0xff;
                sprintf(p,"%02X\n",checksum);
                break;

            /* Just for completness */
            case BINARY_OBJ:
                break;

            default:
                errlog("Invalid Object file type.", PASS2_ONLY);
                break;
            }
                                /* Advance the pointer to the end       */
                                /* just so we can compute the size of   */
                                /* the buffer.                          */
            while(*(++p)) /* void */ ;

            fwrite(buf,1,(p-buf),Fp_object);
        }
    }
}

/* 
 * Function: wrtlastobj()
 *
 * Description:
 *      Write the last Object record.
 *      If binary output then do nothing, otherwise
 *      generate the record suitable for the object format.
 *
 *      S9 with address provided by B Provo
 */

void wrtlastobj(obj_t obj_format)
{
    ushort checksum;
    ushort nbytes = 3;    /* Motorola S9 record has only 3 data bytes */
    char  buf[LINESIZE];

    /* last record to write into obj file.  Indexed by obj format */
    /* no such record if binary format selected */
    static char    *last_obj_rec[5]  = 
                              {":00000001FF\n",     /* INTEL format       */
                               ";00\n",             /* MOS Tech format    */
                               "S9030000FC\n",      /* MOTOROLA format    */
                               "",                  /* Binary (not used)  */
                               ":00000001FF\n"};    /* INTEL-WORD format  */
    
    extern   FILE  *Fp_object;
    extern   pc_t  END_Pc;

    switch (obj_format){
                                /* These are a fixed format for now */
        case MOSTECH_OBJ:
        case INTEL_OBJ:
        case INTELWORD_OBJ:
            fwrite(last_obj_rec[(int)obj_format],1,
                strlen(last_obj_rec[(int)obj_format]), Fp_object);
            break;

        case MOTOROLA_OBJ:
                                /* If an address was specified with the END */
                                /* directive then apply it now              */

            checksum = nbytes  + (ushort)(END_Pc >> 8) + (ushort)(END_Pc & 0xff);
            checksum = (0xffff - checksum) & 0xff;
            sprintf(buf,"S9%02X%04X%02X\n",nbytes,(int)END_Pc,checksum);
            fwrite(buf, 1, strlen(buf), Fp_object);
            break;

        case BINARY_OBJ:
        default:
            break;
        }
}

/* that's all folks */
