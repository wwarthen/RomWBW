;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $Id: test3225.asm 1.1 1993/08/02 01:24:21 toma Exp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TASM  test file
; Test all instructions and addressing modes.
; Processor:  TMS320C25
;


          .org 100h
shift:    .equ 4
shift0:   .equ 0
shiftmode: .equ 3        ;SPM instruction only
addr7:    .equ 12h
addr9:    .equ 123h
addr16:   .equ 1234h
bit:      .equ 05h
port:     .equ 2
arp:      .equ 3
nextarp:  .equ 4
ar:       .equ 1
const:    .equ 34h
const1:   .equ  1h
const8:   .equ 0ffh
const13:  .equ 0234h
const16:  .equ 5678h
cmode:    .equ 2
format:   .equ 1

        ABS

        
        ADD  *BR0+,shift,nextarp  
        ADD  *BR0-,shift,nextarp  
        ADD  *0+,  shift,nextarp  
        ADD  *0-,  shift,nextarp  
        ADD  *+,   shift,nextarp  
        ADD  *-,   shift,nextarp  
        ADD  *,    shift,nextarp   
        ADD  *BR0+,shift
        ADD  *BR0-,shift
        ADD  *0+,  shift
        ADD  *0-,  shift
        ADD  *+,   shift
        ADD  *-,   shift
        ADD  *,    shift
        ADD  *BR0+
        ADD  *BR0-
        ADD  *0+ 
        ADD  *0- 
        ADD  *+  
        ADD  *-  
        ADD  *
        ADD  addr7,shift     
        ADD  addr7       
        
        ADDC *BR0+,nextarp
        ADDC *BR0-,nextarp
        ADDC *0+,  nextarp
        ADDC *0-,  nextarp
        ADDC *+,   nextarp
        ADDC *-,   nextarp
        ADDC *,    nextarp
        ADDC *BR0+
        ADDC *BR0-
        ADDC *0+ 
        ADDC *0- 
        ADDC *+  
        ADDC *-  
        ADDC *
        ADDC addr7       
        
        ADDH *BR0+,nextarp
        ADDH *BR0-,nextarp
        ADDH *0+,  nextarp
        ADDH *0-,  nextarp
        ADDH *+,   nextarp
        ADDH *-,   nextarp
        ADDH *,    nextarp
        ADDH *BR0+
        ADDH *BR0-
        ADDH *0+ 
        ADDH *0- 
        ADDH *+  
        ADDH *-  
        ADDH *
        ADDH addr7       
        
        
        ADDK const8      

        ADDS *BR0+,nextarp
        ADDS *BR0-,nextarp
        ADDS *0+,  nextarp
        ADDS *0-,  nextarp
        ADDS *+,   nextarp
        ADDS *-,   nextarp
        ADDS *,    nextarp
        ADDS *BR0+
        ADDS *BR0-
        ADDS *0+ 
        ADDS *0- 
        ADDS *+  
        ADDS *-  
        ADDS *
        ADDS addr7       
        
        ADDT *BR0+,nextarp
        ADDT *BR0-,nextarp
        ADDT *0+,  nextarp
        ADDT *0-,  nextarp
        ADDT *+,   nextarp
        ADDT *-,   nextarp
        ADDT *,    nextarp
        ADDT *BR0+
        ADDT *BR0-
        ADDT *0+ 
        ADDT *0- 
        ADDT *+  
        ADDT *-  
        ADDT *
        ADDT addr7       
        
        ADLK const16,shift     
        ADLK const16      
        ADLK 0
        ADLK 1
        ADLK 256
        ADLK 512
        ADLK $1234
        ADLK $1234,0

        ADRK const8      
        
        AND  *BR0+,nextarp
        AND  *BR0-,nextarp
        AND  *0+,  nextarp
        AND  *0-,  nextarp
        AND  *+,   nextarp
        AND  *-,   nextarp
        AND  *,    nextarp
        AND  *BR0+
        AND  *BR0-
        AND  *0+ 
        AND  *0- 
        AND  *+  
        AND  *-  
        AND  *
        AND  addr7       
        
        ANDK const16,shift     
        ANDK const16      

        APAC   

loop1:        

        B    loop1,*BR0+,nextarp
        B    loop1,*BR0-,nextarp
        B    loop1,*0+,  nextarp
        B    loop1,*0-,  nextarp
        B    loop1,*+,   nextarp
        B    loop1,*-,   nextarp
        B    loop1,*,    nextarp
        B    loop1,*BR0+
        B    loop1,*BR0-
        B    loop1,*0+ 
        B    loop1,*0- 
        B    loop1,*+  
        B    loop1,*-  
        B    loop1,*
        B    loop1       

        BACC        
        
        BANZ loop1,*BR0+,nextarp
        BANZ loop1,*BR0-,nextarp
        BANZ loop1,*0+,  nextarp
        BANZ loop1,*0-,  nextarp
        BANZ loop1,*+,   nextarp
        BANZ loop1,*-,   nextarp
        BANZ loop1,*,    nextarp
        BANZ loop1,*BR0+
        BANZ loop1,*BR0-
        BANZ loop1,*0+ 
        BANZ loop1,*0- 
        BANZ loop1,*+  
        BANZ loop1,*-  
        BANZ loop1,*
        BANZ loop1       

        BBNZ loop1,*BR0+,nextarp
        BBNZ loop1,*BR0-,nextarp
        BBNZ loop1,*0+,  nextarp
        BBNZ loop1,*0-,  nextarp
        BBNZ loop1,*+,   nextarp
        BBNZ loop1,*-,   nextarp
        BBNZ loop1,*,    nextarp
        BBNZ loop1,*BR0+
        BBNZ loop1,*BR0-
        BBNZ loop1,*0+ 
        BBNZ loop1,*0- 
        BBNZ loop1,*+  
        BBNZ loop1,*-  
        BBNZ loop1,*
        BBNZ loop1       

        BBZ  loop1,*BR0+,nextarp
        BBZ  loop1,*BR0-,nextarp
        BBZ  loop1,*0+,  nextarp
        BBZ  loop1,*0-,  nextarp
        BBZ  loop1,*+,   nextarp
        BBZ  loop1,*-,   nextarp
        BBZ  loop1,*,    nextarp
        BBZ  loop1,*BR0+
        BBZ  loop1,*BR0-
        BBZ  loop1,*0+ 
        BBZ  loop1,*0- 
        BBZ  loop1,*+  
        BBZ  loop1,*-  
        BBZ  loop1,*
        BBZ  loop1       

        BC   loop1,*BR0+,nextarp
        BC   loop1,*BR0-,nextarp
        BC   loop1,*0+,  nextarp
        BC   loop1,*0-,  nextarp
        BC   loop1,*+,   nextarp
        BC   loop1,*-,   nextarp
        BC   loop1,*,    nextarp
        BC   loop1,*BR0+
        BC   loop1,*BR0-
        BC   loop1,*0+ 
        BC   loop1,*0- 
        BC   loop1,*+  
        BC   loop1,*-  
        BC   loop1,*
        BC   loop1       

        BGEZ loop1,*BR0+,nextarp
        BGEZ loop1,*BR0-,nextarp
        BGEZ loop1,*0+,  nextarp
        BGEZ loop1,*0-,  nextarp
        BGEZ loop1,*+,   nextarp
        BGEZ loop1,*-,   nextarp
        BGEZ loop1,*,    nextarp
        BGEZ loop1,*BR0+
        BGEZ loop1,*BR0-
        BGEZ loop1,*0+ 
        BGEZ loop1,*0- 
        BGEZ loop1,*+  
        BGEZ loop1,*-  
        BGEZ loop1,*
        BGEZ loop1       

        BGZ  loop1,*BR0+,nextarp
        BGZ  loop1,*BR0-,nextarp
        BGZ  loop1,*0+,  nextarp
        BGZ  loop1,*0-,  nextarp
        BGZ  loop1,*+,   nextarp
        BGZ  loop1,*-,   nextarp
        BGZ  loop1,*,    nextarp
        BGZ  loop1,*BR0+
        BGZ  loop1,*BR0-
        BGZ  loop1,*0+ 
        BGZ  loop1,*0- 
        BGZ  loop1,*+  
        BGZ  loop1,*-  
        BGZ  loop1,*
        BGZ  loop1       

        BIOZ loop1,*BR0+,nextarp
        BIOZ loop1,*BR0-,nextarp
        BIOZ loop1,*0+,  nextarp
        BIOZ loop1,*0-,  nextarp
        BIOZ loop1,*+,   nextarp
        BIOZ loop1,*-,   nextarp
        BIOZ loop1,*,    nextarp
        BIOZ loop1,*BR0+
        BIOZ loop1,*BR0-
        BIOZ loop1,*0+ 
        BIOZ loop1,*0- 
        BIOZ loop1,*+  
        BIOZ loop1,*-  
        BIOZ loop1,*
        BIOZ loop1       

        BLEZ loop1,*BR0+,nextarp
        BLEZ loop1,*BR0-,nextarp
        BLEZ loop1,*0+,  nextarp
        BLEZ loop1,*0-,  nextarp
        BLEZ loop1,*+,   nextarp
        BLEZ loop1,*-,   nextarp
        BLEZ loop1,*,    nextarp
        BLEZ loop1,*BR0+
        BLEZ loop1,*BR0-
        BLEZ loop1,*0+ 
        BLEZ loop1,*0- 
        BLEZ loop1,*+  
        BLEZ loop1,*-  
        BLEZ loop1,*
        BLEZ loop1       

        BLZ  loop1,*BR0+,nextarp
        BLZ  loop1,*BR0-,nextarp
        BLZ  loop1,*0+,  nextarp
        BLZ  loop1,*0-,  nextarp
        BLZ  loop1,*+,   nextarp
        BLZ  loop1,*-,   nextarp
        BLZ  loop1,*,    nextarp
        BLZ  loop1,*BR0+
        BLZ  loop1,*BR0-
        BLZ  loop1,*0+ 
        BLZ  loop1,*0- 
        BLZ  loop1,*+  
        BLZ  loop1,*-  
        BLZ  loop1,*
        BLZ  loop1       

        BNC  loop1,*BR0+,nextarp
        BNC  loop1,*BR0-,nextarp
        BNC  loop1,*0+,  nextarp
        BNC  loop1,*0-,  nextarp
        BNC  loop1,*+,   nextarp
        BNC  loop1,*-,   nextarp
        BNC  loop1,*,    nextarp
        BNC  loop1,*BR0+
        BNC  loop1,*BR0-
        BNC  loop1,*0+ 
        BNC  loop1,*0- 
        BNC  loop1,*+  
        BNC  loop1,*-  
        BNC  loop1,*
        BNC  loop1       

        BNV  loop1,*BR0+,nextarp
        BNV  loop1,*BR0-,nextarp
        BNV  loop1,*0+,  nextarp
        BNV  loop1,*0-,  nextarp
        BNV  loop1,*+,   nextarp
        BNV  loop1,*-,   nextarp
        BNV  loop1,*,    nextarp
        BNV  loop1,*BR0+
        BNV  loop1,*BR0-
        BNV  loop1,*0+ 
        BNV  loop1,*0- 
        BNV  loop1,*+  
        BNV  loop1,*-  
        BNV  loop1,*
        BNV  loop1       

        BNZ  loop1,*BR0+,nextarp
        BNZ  loop1,*BR0-,nextarp
        BNZ  loop1,*0+,  nextarp
        BNZ  loop1,*0-,  nextarp
        BNZ  loop1,*+,   nextarp
        BNZ  loop1,*-,   nextarp
        BNZ  loop1,*,    nextarp
        BNZ  loop1,*BR0+
        BNZ  loop1,*BR0-
        BNZ  loop1,*0+ 
        BNZ  loop1,*0- 
        BNZ  loop1,*+  
        BNZ  loop1,*-  
        BNZ  loop1,*
        BNZ  loop1       

        BV   loop1,*BR0+,nextarp
        BV   loop1,*BR0-,nextarp
        BV   loop1,*0+,  nextarp
        BV   loop1,*0-,  nextarp
        BV   loop1,*+,   nextarp
        BV   loop1,*-,   nextarp
        BV   loop1,*,    nextarp
        BV   loop1,*BR0+
        BV   loop1,*BR0-
        BV   loop1,*0+ 
        BV   loop1,*0- 
        BV   loop1,*+  
        BV   loop1,*-  
        BV   loop1,*
        BV   loop1       

        BZ   loop1,*BR0+,nextarp
        BZ   loop1,*BR0-,nextarp
        BZ   loop1,*0+,  nextarp
        BZ   loop1,*0-,  nextarp
        BZ   loop1,*+,   nextarp
        BZ   loop1,*-,   nextarp
        BZ   loop1,*,    nextarp
        BZ   loop1,*BR0+
        BZ   loop1,*BR0-
        BZ   loop1,*0+ 
        BZ   loop1,*0- 
        BZ   loop1,*+  
        BZ   loop1,*-  
        BZ   loop1,*
        BZ   loop1       

        BIT  *BR0+,bit  ,nextarp  
        BIT  *BR0-,bit  ,nextarp  
        BIT  *0+,  bit  ,nextarp  
        BIT  *0-,  bit  ,nextarp  
        BIT  *+,   bit  ,nextarp  
        BIT  *-,   bit  ,nextarp  
        BIT  *,    bit  ,nextarp   
        BIT  *BR0+,bit  
        BIT  *BR0-,bit  
        BIT  *0+,  bit  
        BIT  *0-,  bit  
        BIT  *+,   bit  
        BIT  *-,   bit  
        BIT  *,    bit  
        BIT  addr7,bit       
        
        BITT *BR0+,nextarp
        BITT *BR0-,nextarp
        BITT *0+,  nextarp
        BITT *0-,  nextarp
        BITT *+,   nextarp
        BITT *-,   nextarp
        BITT *,    nextarp
        BITT *BR0+
        BITT *BR0-
        BITT *0+ 
        BITT *0- 
        BITT *+  
        BITT *-  
        BITT *
        BITT addr7       
        
        BLKD addr16,*BR0+,nextarp
        BLKD addr16,*BR0-,nextarp
        BLKD addr16,*0+,  nextarp
        BLKD addr16,*0-,  nextarp
        BLKD addr16,*+,   nextarp  
        BLKD addr16,*-,   nextarp   
        BLKD addr16,*,    nextarp    
        BLKD addr16,*BR0+
        BLKD addr16,*BR0-
        BLKD addr16,*0+
        BLKD addr16,*0-
        BLKD addr16,*+
        BLKD addr16,*-
        BLKD addr16,*
        BLKD addr16,addr7     
        
        BLKP addr16,*BR0+,nextarp
        BLKP addr16,*BR0-,nextarp
        BLKP addr16,*0+,  nextarp
        BLKP addr16,*0-,  nextarp
        BLKP addr16,*+,   nextarp  
        BLKP addr16,*-,   nextarp   
        BLKP addr16,*,    nextarp    
        BLKP addr16,*BR0+
        BLKP addr16,*BR0-
        BLKP addr16,*0+
        BLKP addr16,*0-
        BLKP addr16,*+
        BLKP addr16,*-
        BLKP addr16,*
        BLKP addr16,addr7     
        
        CALA        

        CALL addr16,*BR0+,nextarp
        CALL addr16,*BR0-,nextarp
        CALL addr16,*0+,  nextarp
        CALL addr16,*0-,  nextarp
        CALL addr16,*+,   nextarp  
        CALL addr16,*-,   nextarp   
        CALL addr16,*,    nextarp    
        CALL addr16,*BR0+
        CALL addr16,*BR0-
        CALL addr16,*0+
        CALL addr16,*0-
        CALL addr16,*+
        CALL addr16,*-
        CALL addr16,*
        CALL addr16
        
        CMPL       
        
        CMPR cmode     

        CNFD       
        CNFP       
        
        DINT       
        
        DMOV *BR0+,nextarp
        DMOV *BR0-,nextarp
        DMOV *0+,  nextarp
        DMOV *0-,  nextarp
        DMOV *+,   nextarp
        DMOV *-,   nextarp
        DMOV *,    nextarp
        DMOV *BR0+
        DMOV *BR0-
        DMOV *0+ 
        DMOV *0- 
        DMOV *+  
        DMOV *-  
        DMOV *
        DMOV addr7       
        
        EINT       
        
        FORT format     
        
        IDLE       
        
        IN   *BR0+,port,nextarp  
        IN   *BR0-,port,nextarp  
        IN   *0+,  port,nextarp  
        IN   *0-,  port,nextarp  
        IN   *+,   port,nextarp  
        IN   *-,   port,nextarp  
        IN   *,    port,nextarp   
        IN   *BR0+,port
        IN   *BR0-,port
        IN   *0+,  port
        IN   *0-,  port
        IN   *+,   port
        IN   *-,   port
        IN   *,    port
        IN   addr7,port     

        LAC  *BR0+,shift,nextarp  
        LAC  *BR0-,shift,nextarp  
        LAC  *0+,  shift,nextarp  
        LAC  *0-,  shift,nextarp  
        LAC  *+,   shift,nextarp  
        LAC  *-,   shift,nextarp  
        LAC  *,    shift,nextarp   
        LAC  *BR0+,shift
        LAC  *BR0-,shift
        LAC  *0+,  shift
        LAC  *0-,  shift
        LAC  *+,   shift
        LAC  *-,   shift
        LAC  *,    shift
        LAC  *BR0+
        LAC  *BR0-
        LAC  *0+ 
        LAC  *0- 
        LAC  *+  
        LAC  *-  
        LAC  *
        LAC  addr7,shift     
        LAC  addr7       

        LACK const8     
        
        LACT *BR0+,nextarp
        LACT *BR0-,nextarp
        LACT *0+,  nextarp
        LACT *0-,  nextarp
        LACT *+,   nextarp
        LACT *-,   nextarp
        LACT *,    nextarp
        LACT *BR0+
        LACT *BR0-
        LACT *0+ 
        LACT *0- 
        LACT *+  
        LACT *-  
        LACT *
        LACT addr7       
        
        LALK const16,shift    
        LALK const16     
                    
        LAR arp,*BR0+,nextarp
        LAR arp,*BR0-,nextarp
        LAR arp,*0+,  nextarp
        LAR arp,*0-,  nextarp
        LAR arp,*+,   nextarp
        LAR arp,*-,   nextarp
        LAR arp,*,    nextarp
        LAR arp,*BR0+
        LAR arp,*BR0-
        LAR arp,*0+ 
        LAR arp,*0- 
        LAR arp,*+  
        LAR arp,*-  
        LAR arp,*
        LAR arp,addr7       
        
        LARK arp, const8
        
        LARP arp      
                     
        LDP  *BR0+,nextarp
        LDP  *BR0-,nextarp
        LDP  *0+,  nextarp
        LDP  *0-,  nextarp
        LDP  *+,   nextarp
        LDP  *-,   nextarp
        LDP  *,    nextarp
        LDP  *BR0+
        LDP  *BR0-
        LDP  *0+ 
        LDP  *0- 
        LDP  *+  
        LDP  *-  
        LDP  *
        LDP  addr7       
        
        LDPK addr9      
                     
        LPH  *BR0+,nextarp
        LPH  *BR0-,nextarp
        LPH  *0+,  nextarp
        LPH  *0-,  nextarp
        LPH  *+,   nextarp
        LPH  *-,   nextarp
        LPH  *,    nextarp
        LPH  *BR0+
        LPH  *BR0-
        LPH  *0+ 
        LPH  *0- 
        LPH  *+  
        LPH  *-  
        LPH  *
        LPH  addr7       
        
        LRLK arp, const16   
        
        LST  *BR0+,nextarp
        LST  *BR0-,nextarp
        LST  *0+,  nextarp
        LST  *0-,  nextarp
        LST  *+,   nextarp
        LST  *-,   nextarp
        LST  *,    nextarp
        LST  *BR0+
        LST  *BR0-
        LST  *0+ 
        LST  *0- 
        LST  *+  
        LST  *-  
        LST  *
        LST  addr7       
        
        LST1 *BR0+,nextarp
        LST1 *BR0-,nextarp
        LST1 *0+,  nextarp
        LST1 *0-,  nextarp
        LST1 *+,   nextarp
        LST1 *-,   nextarp
        LST1 *,    nextarp
        LST1 *BR0+
        LST1 *BR0-
        LST1 *0+ 
        LST1 *0- 
        LST1 *+  
        LST1 *-  
        LST1 *
        LST1 addr7       
        
        LT   *BR0+,nextarp
        LT   *BR0-,nextarp
        LT   *0+,  nextarp
        LT   *0-,  nextarp
        LT   *+,   nextarp
        LT   *-,   nextarp
        LT   *,    nextarp
        LT   *BR0+
        LT   *BR0-
        LT   *0+ 
        LT   *0- 
        LT   *+  
        LT   *-  
        LT   *
        LT   addr7       
        
        LTA  *BR0+,nextarp
        LTA  *BR0-,nextarp
        LTA  *0+,  nextarp
        LTA  *0-,  nextarp
        LTA  *+,   nextarp
        LTA  *-,   nextarp
        LTA  *,    nextarp
        LTA  *BR0+
        LTA  *BR0-
        LTA  *0+ 
        LTA  *0- 
        LTA  *+  
        LTA  *-  
        LTA  *
        LTA  addr7       
        
        LTD  *BR0+,nextarp
        LTD  *BR0-,nextarp
        LTD  *0+,  nextarp
        LTD  *0-,  nextarp
        LTD  *+,   nextarp
        LTD  *-,   nextarp
        LTD  *,    nextarp
        LTD  *BR0+
        LTD  *BR0-
        LTD  *0+ 
        LTD  *0- 
        LTD  *+  
        LTD  *-  
        LTD  *
        LTD  addr7       
        
        LTP  *BR0+,nextarp
        LTP  *BR0-,nextarp
        LTP  *0+,  nextarp
        LTP  *0-,  nextarp
        LTP  *+,   nextarp
        LTP  *-,   nextarp
        LTP  *,    nextarp
        LTP  *BR0+
        LTP  *BR0-
        LTP  *0+ 
        LTP  *0- 
        LTP  *+  
        LTP  *-  
        LTP  *
        LTP  addr7       
        
        LTS  *BR0+,nextarp
        LTS  *BR0-,nextarp
        LTS  *0+,  nextarp
        LTS  *0-,  nextarp
        LTS  *+,   nextarp
        LTS  *-,   nextarp
        LTS  *,    nextarp
        LTS  *BR0+
        LTS  *BR0-
        LTS  *0+ 
        LTS  *0- 
        LTS  *+  
        LTS  *-  
        LTS  *
        LTS  addr7       
        
        MAC  addr16,*BR0+,nextarp
        MAC  addr16,*BR0-,nextarp
        MAC  addr16,*0+,  nextarp
        MAC  addr16,*0-,  nextarp
        MAC  addr16,*+,   nextarp  
        MAC  addr16,*-,   nextarp   
        MAC  addr16,*,    nextarp    
        MAC  addr16,*BR0+
        MAC  addr16,*BR0-
        MAC  addr16,*0+
        MAC  addr16,*0-
        MAC  addr16,*+
        MAC  addr16,*-
        MAC  addr16,*
        MAC  addr16,addr7
        
        MACD addr16,*BR0+,nextarp
        MACD addr16,*BR0-,nextarp
        MACD addr16,*0+,  nextarp
        MACD addr16,*0-,  nextarp
        MACD addr16,*+,   nextarp  
        MACD addr16,*-,   nextarp   
        MACD addr16,*,    nextarp    
        MACD addr16,*BR0+
        MACD addr16,*BR0-
        MACD addr16,*0+
        MACD addr16,*0-
        MACD addr16,*+
        MACD addr16,*-
        MACD addr16,*
        MACD addr16,addr7

        MAR  *BR0+,nextarp
        MAR  *BR0-,nextarp
        MAR  *0+,  nextarp
        MAR  *0-,  nextarp
        MAR  *+,   nextarp
        MAR  *-,   nextarp
        MAR  *,    nextarp
        MAR  *BR0+
        MAR  *BR0-
        MAR  *0+ 
        MAR  *0- 
        MAR  *+  
        MAR  *-  
        MAR  *
        MAR  addr7       
        
        MPY  *BR0+,nextarp
        MPY  *BR0-,nextarp
        MPY  *0+,  nextarp
        MPY  *0-,  nextarp
        MPY  *+,   nextarp
        MPY  *-,   nextarp
        MPY  *,    nextarp
        MPY  *BR0+
        MPY  *BR0-
        MPY  *0+ 
        MPY  *0- 
        MPY  *+  
        MPY  *-  
        MPY  *
        MPY  addr7       
        
        MPYA *BR0+,nextarp
        MPYA *BR0-,nextarp
        MPYA *0+,  nextarp
        MPYA *0-,  nextarp
        MPYA *+,   nextarp
        MPYA *-,   nextarp
        MPYA *,    nextarp
        MPYA *BR0+
        MPYA *BR0-
        MPYA *0+ 
        MPYA *0- 
        MPYA *+  
        MPYA *-  
        MPYA *
        MPYA addr7       
        
        MPYK const13     
                    
        MPYS *BR0+,nextarp
        MPYS *BR0-,nextarp
        MPYS *0+,  nextarp
        MPYS *0-,  nextarp
        MPYS *+,   nextarp
        MPYS *-,   nextarp
        MPYS *,    nextarp
        MPYS *BR0+
        MPYS *BR0-
        MPYS *0+ 
        MPYS *0- 
        MPYS *+  
        MPYS *-  
        MPYS *
        MPYS addr7       
        
        MPYU *BR0+,nextarp
        MPYU *BR0-,nextarp
        MPYU *0+,  nextarp
        MPYU *0-,  nextarp
        MPYU *+,   nextarp
        MPYU *-,   nextarp
        MPYU *,    nextarp
        MPYU *BR0+
        MPYU *BR0-
        MPYU *0+ 
        MPYU *0- 
        MPYU *+  
        MPYU *-  
        MPYU *
        MPYU addr7       
        
        NEG         
        
        NOP         
        
        NORM *BR0+      
        NORM *BR0-      
        NORM *0+      
        NORM *0-      
        NORM *+      
        NORM *-      
        NORM *       
        NORM
        
        OR   *BR0+,nextarp
        OR   *BR0-,nextarp
        OR   *0+,  nextarp
        OR   *0-,  nextarp
        OR   *+,   nextarp
        OR   *-,   nextarp
        OR   *,    nextarp
        OR   *BR0+
        OR   *BR0-
        OR   *0+ 
        OR   *0- 
        OR   *+  
        OR   *-  
        OR   *
        OR   addr7       
        
        ORK  const16, shift     
        ORK  const16      
        
        OUT  *BR0+,port,nextarp  
        OUT  *BR0-,port,nextarp  
        OUT  *0+,  port,nextarp  
        OUT  *0-,  port,nextarp  
        OUT  *+,   port,nextarp  
        OUT  *-,   port,nextarp  
        OUT  *,    port,nextarp   
        OUT  *BR0+,port
        OUT  *BR0-,port
        OUT  *0+,  port
        OUT  *0-,  port
        OUT  *+,   port
        OUT  *-,   port
        OUT  *,    port
        OUT  addr7,port     
        
        PAC         
        POP         
        
        POPD *BR0+,nextarp
        POPD *BR0-,nextarp
        POPD *0+,  nextarp
        POPD *0-,  nextarp
        POPD *+,   nextarp
        POPD *-,   nextarp
        POPD *,    nextarp
        POPD *BR0+
        POPD *BR0-
        POPD *0+ 
        POPD *0- 
        POPD *+  
        POPD *-  
        POPD *
        POPD addr7       
        
        PSHD *BR0+,nextarp
        PSHD *BR0-,nextarp
        PSHD *0+,  nextarp
        PSHD *0-,  nextarp
        PSHD *+,   nextarp
        PSHD *-,   nextarp
        PSHD *,    nextarp
        PSHD *BR0+
        PSHD *BR0-
        PSHD *0+ 
        PSHD *0- 
        PSHD *+  
        PSHD *-  
        PSHD *
        PSHD addr7       
        
        PUSH        
        RC          
        RET         
        RFSM        
        RHM         
        ROL         
        ROR         
        ROVM        
        
        RPT  *BR0+,nextarp
        RPT  *BR0-,nextarp
        RPT  *0+,  nextarp
        RPT  *0-,  nextarp
        RPT  *+,   nextarp
        RPT  *-,   nextarp
        RPT  *,    nextarp
        RPT  *BR0+
        RPT  *BR0-
        RPT  *0+ 
        RPT  *0- 
        RPT  *+  
        RPT  *-  
        RPT  *
        RPT  addr7       
        
        RPTK const8      
        
        RSXM        
        RTC         
        RTXM        
        RXF         
        
        SACH *BR0+,shift,nextarp  
        SACH *BR0-,shift,nextarp  
        SACH *0+,  shift,nextarp  
        SACH *0-,  shift,nextarp  
        SACH *+,   shift,nextarp  
        SACH *-,   shift,nextarp  
        SACH *,    shift,nextarp   
        SACH *BR0+,shift
        SACH *BR0-,shift
        SACH *0+,  shift
        SACH *0-,  shift
        SACH *+,   shift
        SACH *-,   shift
        SACH *,    shift
        SACH *BR0+
        SACH *BR0-
        SACH *0+ 
        SACH *0- 
        SACH *+  
        SACH *-  
        SACH *
        SACH addr7,shift     
        SACH addr7       
        
        SACL *BR0+,shift,nextarp  
        SACL *BR0-,shift,nextarp  
        SACL *0+,  shift,nextarp  
        SACL *0-,  shift,nextarp  
        SACL *+,   shift,nextarp  
        SACL *-,   shift,nextarp  
        SACL *,    shift,nextarp   
        SACL *BR0+,shift
        SACL *BR0-,shift
        SACL *0+,  shift
        SACL *0-,  shift
        SACL *+,   shift
        SACL *-,   shift
        SACL *,    shift
        SACL *BR0+
        SACL *BR0-
        SACL *0+ 
        SACL *0- 
        SACL *+  
        SACL *-  
        SACL *
        SACL addr7,shift     
        SACL addr7       
        
        SAR arp,*BR0+,nextarp
        SAR arp,*BR0-,nextarp
        SAR arp,*0+,  nextarp
        SAR arp,*0-,  nextarp
        SAR arp,*+,   nextarp
        SAR arp,*-,   nextarp
        SAR arp,*,    nextarp
        SAR arp,*BR0+
        SAR arp,*BR0-
        SAR arp,*0+ 
        SAR arp,*0- 
        SAR arp,*+  
        SAR arp,*-  
        SAR arp,*
        SAR arp,addr7       
        
        SBLK const16, shift     
        SBLK const16      
        
        SBRK const8      
        
        SC          
        SFL         
        SFR         
        SFSM        
        SHM         
        SOVM        
        SPAC        
        
        SPH  *BR0+,nextarp
        SPH  *BR0-,nextarp
        SPH  *0+,  nextarp
        SPH  *0-,  nextarp
        SPH  *+,   nextarp
        SPH  *-,   nextarp
        SPH  *,    nextarp
        SPH  *BR0+
        SPH  *BR0-
        SPH  *0+ 
        SPH  *0- 
        SPH  *+  
        SPH  *-  
        SPH  *
        SPH  addr7       
        
        SPL  *BR0+,nextarp
        SPL  *BR0-,nextarp
        SPL  *0+,  nextarp
        SPL  *0-,  nextarp
        SPL  *+,   nextarp
        SPL  *-,   nextarp
        SPL  *,    nextarp
        SPL  *BR0+
        SPL  *BR0-
        SPL  *0+ 
        SPL  *0- 
        SPL  *+  
        SPL  *-  
        SPL  *
        SPL  addr7       
        
        SPM  shiftmode      
        
        SQRA *BR0+,nextarp
        SQRA *BR0-,nextarp
        SQRA *0+,  nextarp
        SQRA *0-,  nextarp
        SQRA *+,   nextarp
        SQRA *-,   nextarp
        SQRA *,    nextarp
        SQRA *BR0+
        SQRA *BR0-
        SQRA *0+ 
        SQRA *0- 
        SQRA *+  
        SQRA *-  
        SQRA *
        SQRA addr7
        
        SQRS *BR0+,nextarp
        SQRS *BR0-,nextarp
        SQRS *0+,  nextarp
        SQRS *0-,  nextarp
        SQRS *+,   nextarp
        SQRS *-,   nextarp
        SQRS *,    nextarp
        SQRS *BR0+
        SQRS *BR0-
        SQRS *0+ 
        SQRS *0- 
        SQRS *+  
        SQRS *-  
        SQRS *
        SQRS addr7
        
        SST  *BR0+,nextarp
        SST  *BR0-,nextarp
        SST  *0+,  nextarp
        SST  *0-,  nextarp
        SST  *+,   nextarp
        SST  *-,   nextarp
        SST  *,    nextarp
        SST  *BR0+
        SST  *BR0-
        SST  *0+ 
        SST  *0- 
        SST  *+  
        SST  *-  
        SST  *
        SST  addr7
        
        SST1 *BR0+,nextarp
        SST1 *BR0-,nextarp
        SST1 *0+,  nextarp
        SST1 *0-,  nextarp
        SST1 *+,   nextarp
        SST1 *-,   nextarp
        SST1 *,    nextarp
        SST1 *BR0+
        SST1 *BR0-
        SST1 *0+ 
        SST1 *0- 
        SST1 *+  
        SST1 *-  
        SST1 *
        SST1 addr7      
        
        SSXM        
        STC         
        STXM        

        SUB  *BR0+,shift,nextarp  
        SUB  *BR0-,shift,nextarp  
        SUB  *0+,  shift,nextarp  
        SUB  *0-,  shift,nextarp  
        SUB  *+,   shift,nextarp  
        SUB  *-,   shift,nextarp  
        SUB  *,    shift,nextarp   
        SUB  *BR0+,shift
        SUB  *BR0-,shift
        SUB  *0+,  shift
        SUB  *0-,  shift
        SUB  *+,   shift
        SUB  *-,   shift
        SUB  *,    shift
        SUB  *BR0+
        SUB  *BR0-
        SUB  *0+ 
        SUB  *0- 
        SUB  *+  
        SUB  *-  
        SUB  *
        SUB  addr7,shift     
        SUB  addr7       
        
        SUBB *BR0+,nextarp
        SUBB *BR0-,nextarp
        SUBB *0+,  nextarp
        SUBB *0-,  nextarp
        SUBB *+,   nextarp
        SUBB *-,   nextarp
        SUBB *,    nextarp
        SUBB *BR0+
        SUBB *BR0-
        SUBB *0+ 
        SUBB *0- 
        SUBB *+  
        SUBB *-  
        SUBB *
        SUBB addr7      
        
        SUBC *BR0+,nextarp
        SUBC *BR0-,nextarp
        SUBC *0+,  nextarp
        SUBC *0-,  nextarp
        SUBC *+,   nextarp
        SUBC *-,   nextarp
        SUBC *,    nextarp
        SUBC *BR0+
        SUBC *BR0-
        SUBC *0+ 
        SUBC *0- 
        SUBC *+  
        SUBC *-  
        SUBC *
        SUBC addr7      
        
        SUBH *BR0+,nextarp
        SUBH *BR0-,nextarp
        SUBH *0+,  nextarp
        SUBH *0-,  nextarp
        SUBH *+,   nextarp
        SUBH *-,   nextarp
        SUBH *,    nextarp
        SUBH *BR0+
        SUBH *BR0-
        SUBH *0+ 
        SUBH *0- 
        SUBH *+  
        SUBH *-  
        SUBH *
        SUBH addr7      
        
        SUBK const8      
        
        SUBS *BR0+,nextarp
        SUBS *BR0-,nextarp
        SUBS *0+,  nextarp
        SUBS *0-,  nextarp
        SUBS *+,   nextarp
        SUBS *-,   nextarp
        SUBS *,    nextarp
        SUBS *BR0+
        SUBS *BR0-
        SUBS *0+ 
        SUBS *0- 
        SUBS *+  
        SUBS *-  
        SUBS *
        SUBS addr7      
        
        SUBT *BR0+,nextarp
        SUBT *BR0-,nextarp
        SUBT *0+,  nextarp
        SUBT *0-,  nextarp
        SUBT *+,   nextarp
        SUBT *-,   nextarp
        SUBT *,    nextarp
        SUBT *BR0+
        SUBT *BR0-
        SUBT *0+ 
        SUBT *0- 
        SUBT *+  
        SUBT *-  
        SUBT *
        SUBT addr7      
        
        SXF         
        
        TBLR *BR0+,nextarp
        TBLR *BR0-,nextarp
        TBLR *0+,  nextarp
        TBLR *0-,  nextarp
        TBLR *+,   nextarp
        TBLR *-,   nextarp
        TBLR *,    nextarp
        TBLR *BR0+
        TBLR *BR0-
        TBLR *0+ 
        TBLR *0- 
        TBLR *+  
        TBLR *-  
        TBLR *
        TBLR addr7      
        
        TBLW *BR0+,nextarp
        TBLW *BR0-,nextarp
        TBLW *0+,  nextarp
        TBLW *0-,  nextarp
        TBLW *+,   nextarp
        TBLW *-,   nextarp
        TBLW *,    nextarp
        TBLW *BR0+
        TBLW *BR0-
        TBLW *0+ 
        TBLW *0- 
        TBLW *+  
        TBLW *-  
        TBLW *
        TBLW addr7      
        
        TRAP        
        
        XOR  *BR0+,nextarp
        XOR  *BR0-,nextarp
        XOR  *0+,  nextarp
        XOR  *0-,  nextarp
        XOR  *+,   nextarp
        XOR  *-,   nextarp
        XOR  *,    nextarp
        XOR  *BR0+
        XOR  *BR0-
        XOR  *0+ 
        XOR  *0- 
        XOR  *+  
        XOR  *-  
        XOR  *
        XOR  addr7      
        
        XORK const16, shift     
        XORK const16      
        
        ZAC         
        
        ZALH *BR0+,nextarp
        ZALH *BR0-,nextarp
        ZALH *0+,  nextarp
        ZALH *0-,  nextarp
        ZALH *+,   nextarp
        ZALH *-,   nextarp
        ZALH *,    nextarp
        ZALH *BR0+
        ZALH *BR0-
        ZALH *0+ 
        ZALH *0- 
        ZALH *+  
        ZALH *-  
        ZALH *
        ZALH addr7      
        
        ZALR *BR0+,nextarp
        ZALR *BR0-,nextarp
        ZALR *0+,  nextarp
        ZALR *0-,  nextarp
        ZALR *+,   nextarp
        ZALR *-,   nextarp
        ZALR *,    nextarp
        ZALR *BR0+
        ZALR *BR0-
        ZALR *0+ 
        ZALR *0- 
        ZALR *+  
        ZALR *-  
        ZALR *
        ZALR addr7      
        
        ZALS *BR0+,nextarp
        ZALS *BR0-,nextarp
        ZALS *0+,  nextarp
        ZALS *0-,  nextarp
        ZALS *+,   nextarp
        ZALS *-,   nextarp
        ZALS *,    nextarp
        ZALS *BR0+
        ZALS *BR0-
        ZALS *0+ 
        ZALS *0- 
        ZALS *+  
        ZALS *-  
        ZALS *
        ZALS addr7      
        .end

