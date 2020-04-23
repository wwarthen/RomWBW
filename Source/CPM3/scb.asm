	title 'System Control Block Definition for CP/M3 BIOS'

	public @civec, @covec, @aivec, @aovec, @lovec, @bnkbf
	public @crdma, @crdsk, @vinfo, @resel, @fx, @usrcd 
        public @mltio, @ermde, @erdsk, @media, @bflgs
	public @date, @hour, @min, @sec, ?erjmp, @mxtpa
	public @ccpdr
	public @srch1, @srch2, @srch3, @srch4


scb$base equ    0FE00H          ; Base of the SCB

@CCPDR	equ	scb$base+13h	; CCP Current Drive
@CIVEC  equ     scb$base+22h    ; Console Input Redirection 
                                ; Vector (word, r/w)
@COVEC  equ     scb$base+24h    ; Console Output Redirection 
                                ; Vector (word, r/w)
@AIVEC  equ     scb$base+26h    ; Auxiliary Input Redirection 
                                ; Vector (word, r/w)
@AOVEC  equ     scb$base+28h    ; Auxiliary Output Redirection 
                                ; Vector (word, r/w)
@LOVEC  equ     scb$base+2Ah    ; List Output Redirection 
                                ; Vector (word, r/w)
@BNKBF  equ     scb$base+35h    ; Address of 128 Byte Buffer 
                                ; for Banked BIOS (word, r/o)
@CRDMA  equ     scb$base+3Ch    ; Current DMA Address 
                                ; (word, r/o)
@CRDSK  equ     scb$base+3Eh    ; Current Disk (byte, r/o)
@VINFO  equ     scb$base+3Fh    ; BDOS Variable "INFO" 
                                ; (word, r/o)
@RESEL  equ     scb$base+41h    ; FCB Flag (byte, r/o)
@FX     equ     scb$base+43h    ; BDOS Function for Error 
                                ; Messages (byte, r/o)
@USRCD  equ     scb$base+44h    ; Current User Code (byte, r/o)
@MLTIO	equ	scb$base+4Ah	; Current Multi-Sector Count
				; (byte,r/w)
@ERMDE  equ     scb$base+4Bh    ; BDOS Error Mode (byte, r/o)
@SRCH1	equ	scb$base+4Ch	; BDOS Drive Search Chain 1
@SRCH2	equ	scb$base+4Dh	; BDOS Drive Search Chain 2
@SRCH3	equ	scb$base+4Eh	; BDOS Drive Search Chain 3
@SRCH4	equ	scb$base+4Fh	; BDOS Drive Search Chain 4
@ERDSK	equ	scb$base+51h	; BDOS Error Disk (byte,r/o)
@MEDIA	equ	scb$base+54h	; Set by BIOS to indicate
				; open door (byte,r/w)
@BFLGS  equ     scb$base+57h    ; BDOS Message Size Flag (byte,r/o)  
@DATE   equ     scb$base+58h    ; Date in Days Since 1 Jan 78 
                                ; (word, r/w)
@HOUR   equ     scb$base+5Ah    ; Hour in BCD (byte, r/w)
@MIN    equ     scb$base+5Bh    ; Minute in BCD (byte, r/w)
@SEC    equ     scb$base+5Ch    ; Second in BCD (byte, r/w)
?ERJMP  equ     scb$base+5Fh    ; BDOS Error Message Jump
                                ; (word, r/w)
@MXTPA  equ     scb$base+62h    ; Top of User TPA 
                                ; (address at 6,7)(word, r/o)
	end
