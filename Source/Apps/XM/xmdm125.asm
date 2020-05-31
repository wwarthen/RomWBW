;
;	TITLE	'XMODEM ver. 12.5 - 07/13/86'
;
;	XMDM125.ASM - REMOTE CP/M FILE TRANSFER PROGRAM
;
;	Originally adapted from Ward Christensen's MODEM2
;		    by Keith Petersen, W8SDZ
;
;	ASEG		;Needed by M80 assemblers, comment out if using MAC
;
; This program allows a remote user to transfer files (to or from) RCPM
; systems running under BYE (remote console program).  It can be assem-
; bled with ASM, LASM, MAC, M80, SRLMAC and other 8080 assemblers.
;
; All comments and past revisions have been removed from this file and
; put into the XMODEM.UPD file.  Place only the current revision at the
; beginning of this file and move the one that was here to XMODEM.UPD.
;
;=======================================================================
;
;  v12.5	Fixed conditional assembly bug which caused date to
;  07/13/86	appear in log twice when MBBS and BYEBDOS were both set
;		to YES.
;		Fixed conditional assembly bug which did not allow MBFMSG
;		to be set to YES while MBDESC was set to NO.
;		Removed patch to log download before sending EOF because
;		EOF would not be sent, leaving caller's program in file
;		transfer mode, if LOGCALL routine exited with an error.
;		This problem was noticed by Keith Petersen.
;		Modified to abort any download which would result in a
;		user exceeding his time limit when BYEBDOS is YES.
;		Fixed bug which would cause caller to be logged off
;		without updating log file if transmission errors caused
;		his download to put him over time limit when BYEBDOS was
;		YES and CLOCK and TIMEON in BYE were YES (call to TCHECK
;		in BYE's extended BDOS call would hang up on caller).
;		Revised comments for some equates to make them easier to
;		understand.
;						- Murray Simsolo
;
;========================================================================
;
VERSION	EQU	1
INTERM	EQU	2
MODLEV	EQU	5
VMONTH	EQU	07
VDAY	EQU	13
VYEAR	EQU	86
;
NO	EQU	0
YES	EQU	NOT NO
;
; Define ASCII characters used
;
BS	EQU	08H	; Backspace character
ACK	EQU	06H	; Acknowledge
CAN	EQU	18H	; CTL-X for cancel
CR	EQU	0DH	; Carriage return
CRC	EQU	'C'	; CRC request character
EOF	EQU	1AH	; End of file - ^Z
EOT	EQU	04H	; End of transmission
LF	EQU	0AH	; Line feed
NAK	EQU	15H	; Negative acknowledge
RLEN	EQU	128	; Record length
TAB	EQU	09H	; Horizontal tab
SOH	EQU	01H	; Start of header for 128-byte blocks
STX	EQU	02H	; 'Start of header' for 1024 byte blocks
;
;=======================================================================
;
; Conditional equates - change to suit your system, then assemble
;
MHZ	EQU	10	; Clock speed, use integer (2,4,5,8, etc.)
SCL	EQU	6600	; [WBW] Receive loop timeout scalar
CPM3	EQU	NO	; Yes, if operating in CP/M v3.0 environment
STOPBIT	EQU	NO	; No, if using 1 stop bit, yes if using 2
BYEBDOS	EQU	NO	; Yes, if using BYE338-up, BYE501-up, or NUBYE
			; with its I/O (CLOCK in BYE must be YES)
			; No if using your own hardware overlay
LUXMOD	EQU	NO	; Set to YES if LUXMODEM version desired rather
			; than standard XMODEM with upload options.
;
;=======================================================================
;
; If OK2400 is YES, then it overrides the TAGLBR and MAXMIN restrictions
; if the current caller is operating at 2400 baud (or higher).
;
OK2400	EQU	NO	; Yes, no restrictions for 2400 bps callers
;
MSPEED	EQU	3CH	; Location of speed byte set by BYE prgm, must
			; be set for OK2400 or BYEBDOS to work
;
DSPFNAM	EQU	YES	; Set to YES if you wish XMODEM to display the
			; file name being up or downloaded for user to
			; see and verify system received name correctly.
;
; If ZCPR3 is YES, then NO filetypes of .NDR or .RCP will be received.
; This is for security if you need LDR.COM on A0: for cold starts or if
; LDR is in the defined path. (If you don't have LDR on-line or
; accessible, then this equate isn't necessary for ZCPR3 systems.)
;
ZCPR3	EQU	NO	; Yes, NO filetypes .NDR or .RCP received
;
;=======================================================================
;
; If ZCPR2 = yes, then the following will all be NO if wheel is set
; in local non-zero (0FFH) mode.  SYSOP rules...
;
ZCPR2	EQU	NO	; Yes, if using ZCPR* with WHEEL byte
;
WHEEL	EQU	3EH	; Location of wheel byte (normally 3EH)
NOCOMR	EQU	NO	; Yes, change .COM to .OBJ on receive
NOCOMS	EQU	NO	; Yes, .COM files not sent
NOLBS	EQU	NO	; Yes, .??# files not sent
NOSYS	EQU	NO	; Yes, no $SYS files sent or reported
;
;=======================================================================
;
; The following are only used by NZCPR or ZCMD systems
;
USEMAX	EQU	NO	; Yes, using NZCPR for maximum du: values
			; No, use MAXDRV and MAXUSR specified next
DRIVMAX	EQU	03DH	; Location of MAXDRIV byte
USRMAX	EQU	03FH	; Location of MAXUSER byte
;
;=======================================================================
;
; Hard-coded system maximums allowed if USEMAX above is NO
;
MAXDRV	EQU	16	; Number of disk drives used (1=A, 2=B, etc)
MAXUSR	EQU	16	; Maximum 'SEND' user allowed
;
;=======================================================================
;
; File transfer buffer size - 16k is the same buffer length used in IMP,
; MDM7 and MEX so all those modem programs as well as XMODEM would be
; transferring from the buffer simultaneously, minimizing any delays.
; Slower floppy disk drives may require the use of a smaller buffer, try
; 8k, 4k, or 2k and use largest that does not result in a time-out at
; the sending end.  Please note the requirement for the protocol to ac-
; cept any mixture of 1K and small blocks may result in effective buffer
; usage extending an additional 896 bytes (7*128) beyond the 'end' of
; the buffer defined here. (Actually, due to handshaking, the buffers
; are NOT loaded simultaneously, so the above statement is misleading,
; too large a buffer will slow things down if you have a slow disk
; drive.. Too small a buffer will really slow you down though, so
; stick with 16k...)
;
BUFSIZ	EQU	16	; File transfer buffer size in Kbytes (16k)
;
;=======================================================================
;
; DESCRIB is used to ask the uploader to give a description of the file
; he just uploaded.  If YES and ZCPR2 is YES and wheel is set, it does
; NOT ask for a description unless ASKSYS is set to YES.
; (If using on an MBBS v4.1 and up system, use MBDESC instead of
; this option.) (NDESC can be used with either DESCRIB or MBDESC.)
;
DESCRIB	EQU	NO	; Yes asks for a description of uploaded file
DRIVE	EQU	'A'	; Drive area for description of upload
USER	EQU	14	; User area for description of upload
BSIZE	EQU	32*1024	; Set for 16k, 24k or 32k as desired for DESCRIB
;
NDESC	EQU	NO	; If YES, user can add a "N" to option to skip
			; description for pre-arranged uploads or
			; for the sysop..
ASKSYS	EQU	NO	; If YES, and ZCPR2=YES, the system will ask
			; the sysop for a description of the uploaded
			; file
ASKIND EQU	NO	; IF YES, user is asked for the category of
			; the uploaded file. This category is auto-
			; matically added to the file description.
;
;=======================================================================
;
; XMODEM transfer log options
;
LOGCAL	EQU	NO	; Yes, logs XMODEM transfers
LOGDRV	EQU	'A'	; Drive to place 'XMODEM.LOG' file
LOGUSR	EQU	14	; User area to put 'XMODEM.LOG' file
;
; OxGate BBS puts the date after the caller's name.  If you are using
; either BYEBDOS or B3RTC or RTC, and have an OxGate, then set this
; equate to YES, so the date doesn't appear twice.
;
OXGATE	EQU	NO	; If yes, and B3RTC or RTC is yes, does not read
			; date in OxGate's LASTCALR file.
;
KNET	EQU	NO	; If yes, the log file is called XMODEM.TX# with
			; $SYS attr set (for K-NET 84(tm) RCP/M Systems)
;
LASTDRV	EQU	'A'	; Drive to read 'LASTCALR' file from
LASTUSR	EQU	14	; User area of 'LASTCALR' file, if 'LOGCAL' yes
;
;=======================================================================
;
; The receiving station sends an 'ACK' for each valid sector received.
; It sends a 'NAK' for each sector incorrectly received.  In poor con-
; ditions either may be garbled.  Waiting for a valid 'NAK' can slow
; things down somewhat, giving more time for the interference to quit.
;
RETRY	EQU	NO	; Yes requires a valid NAK to resend a record
			; No resends a record after any non-ACK
;
; Note that some modem programs will send a "C" instead of a NAK when
; operating in CRC mode. Therefore, RETRY EQU NO will allow XMODEM to
; work correctly with more programs.
;
;=======================================================================
;
; When sending in 1K block mode, XMODEM will downshift to 128 byte
; blocks when the ratio of successfully transmitted blocks to total
; errors falls below the ratio defined here.
;
DWNSHFT	EQU	5	; must have at least this many good blocks for
			; every error, or will downshift to size 128
;
MINKSP	EQU	5	; set this equate to the minimum MSPEED value
			; allowed to use the 1k block protocol..
;
; MSPEED values: 1=300, 5=1200, 6=2400
;
;=======================================================================
;
; Allows uploading to be done on a specified driver and user area so all
; can readily find the latest entries.
;
SETAREA	EQU	NO	; Yes, using designated du: to receive files
			; No, upload to currently logged du:
SPCDU	EQU	NO	; Yes, upload to designated du: if wheel set
;
DRV	EQU	'B'	; Drive to receive file on
USR	EQU	0	; User area to receive file in
;
ASKAREA	EQU	NO	; If YES, ask user what type of upload and
			; set area accordingly. For Multiple
			; Operating system support.
;
SYSNEW	EQU	NO	; If YES, then new uploads are made $SYS
			; to "hide" them from users until cleared...
;
;=======================================================================
;
; Selects the DU: for uploading private files with XMODEM RP option.
;
PRDRV	EQU	'A'	; Private drive for SYSOP to receive file
PRUSR	EQU	0	; Private user area for SYSOP to receive file
;
;=======================================================================
;
; Selects the DU: for private download files.  This permits Sysop
; to put file(s) in this area, then leave a private note to that
; person mentioning the name(s) of the file and its location.
;
SPLDRV	EQU	'A'	; Special drive area for downloading SYSOP files
SPLUSR	EQU	0	; Special user area for downloading SYSOP files
;
;=======================================================================
;
; Selects the DU: used for message files uploaded with the "RM" option.
; (Used only if MBFMSG option enabled)
;
MSGDRV	EQU	'A'	; Drive used to receive message files
MSGUSR	EQU	15	; User used to receive message files
;
;=======================================================================
;
; SYSOP may use NSWP or TAG and set the high bit of F1 to disallow the
; sending of large .LBR files.	If TAGLBR is YES, only LUX or the option
; XMODEM L will allow transfer of individual member files from tagged
; .LBR files.  The entire .LBR file can NOT be sent using XMODEM S NAME.
;
TAGLBR	EQU	NO	; Yes tagged .LBR files not sent
;
; Note: The OK2400 equate if YES will bypass this restriction if the
;	caller is operating at 2400 baud (or faster).
;
;=======================================================================
;
; Some modems will either go onhook immediately after carrier loss or
; can be set to lower values.  A good value with the Smartmodem is five
; seconds, since it catches all "call forwarding" breaks.  Not all is
; lost after timeout in XMODEM; BYE will still wait some more, but the
; chance of someone slipping in is less now.
;
TIMOUT	EQU	2	; Seconds to abort after carrier loss
;
;=======================================================================
;
; Count the number of up/down loads since login.  Your BBS program can
; check UPLDS and NDLDS when user logs out and update either the users
; file or another file for this purpose.
;
LOGLDS	EQU	NO	; Count number of up/down loads since login.
;
	 IF	LOGLDS
UPLDS	EQU	054H	; Clear these values to Zero from your BBS pro-
DNLDS	EQU	055H	;   gram when somebody logs in.  NOTE:	Clear
			;   ONLY when a user logs in.  Not when he re-
			;   enters the BBS program for CP/M.
	 ENDIF
;
;======================================================================
;
; Maximum file transfer time allowed.
;
; NOTE: If ZCPR2 = YES and WHEEL byte is set, send time is unlimited.
;
;		 TIME	300 BPS  1200 BPS
;		------	-------  --------
;		30 min	 48.7k	   180k
;		45 min	 73.1k	   270k
;		60 min	 97.5k	   360k
;
MAXTIM	EQU	NO	; Yes if limiting transmission time
;
MAXMIN	EQU	60	; Minutes for maximum file transfer time.
			;   this should be set to 60 if TIMEON is YES
			;   (99 minutes maximum.) (This is ignored if
			;   BYEBDOS is set.)
;
; Note: The OK2400 equate if YES will bypass MAXMIN limits.
;
;======================================================================
;
; The following equates need to be set ONLY if you are NOT using the
; BYE-BDOS calls supported in BYE338 and newer.
;
; Length of external patch program.  If over 128 bytes, get/set size
;
LARGEIO	EQU	YES	; Yes, if modem patch area over 128 bytes
LARSIZE	EQU	500H	; If 'LARGEIO' set patch area size (bytes) here
;
;=======================================================================
;
; USECON allows XMODEM to display the record count on the local CRT
; during transfers.  All new remote console programs support this
; feature.  BYE3* and MBYE3* will tell XMODEM where to find the local
; console's output vector.
;
USECON	EQU	NO	; Yes to get CONOUT address from BYE
			; NO, get CONOUT address from the XMODEM overlay
;
CONOFF	EQU	15	; Offset to COVECT where original console output
			;   routine address is stored in BYE3/MBYE
			;   versions immediately followed by BYE as a
			;   check to insure BYE is running.
;
;=======================================================================
;		    start of TIMEON area
;
RTC	EQU	NO	; If YES, add clock and date reader code at
			; start of GETTIME: and GETDATE: below
;
; The TIMEON and RTC equates should be NO if B3RTC is YES
;
TIMEON	EQU	NO	; If YES and BYEBDOS is NO, add your clock reader
			; code at the start of label GETTIME: and return
			; time in registers A & B.  Also set to YES if
			; BYEBDOS is YES and you want XMODEM to check
			; time on system (not necessary if TIMEON in BYE
			; is YES - saves unnecessary code).
TOSEXIT	EQU	NO	; If YES, time on system displayed on exit if
			; B3RTC or TIMEON or BYEBDOS set to YES
;
	 IF	TIMEON AND NOT CPM3
LHOUR	EQU	050H	; Set by BBS (or BYE) in binary when user logs
LMIN	EQU	051H	; on and his status
STATUS	EQU	053H
	 ENDIF
;
	 IF	TIMEON AND CPM3
LHOUR	EQU	022H	; Set by BBS (or BYE) in binary when user logs
LMIN	EQU	023H	; on and his status
STATUS	EQU	024H
	 ENDIF
;
;		   end of TIMEON area
;========================================================================
;		   Miscellaneous Support Bytes
;========================================================================
; Set this equate to enable access byte support.  ACBOFF specifies
; the offset from the JMP COLDBOOT instruction as above with WRTLOC.
; MBBS and some newer BBS's support this byte, therefore, it is no
; longer specific to MBBS. You must determine if your system uses this.
;
ACCESS	EQU	NO	; Yes, check flags for upload/dwnld restrictions
ACBOFF	EQU	21	; # of bytes from JMP COLDBOOT to ACCESS byte.
ACWRIT	EQU	8	; Bit to test for BBS msg write OK (1=OK,0=NOT OK)
ACDNLD	EQU	32	; Bit to test for downloads OK (1=OK,0=NOT OK)
ACUPLD	EQU	64	; Bit to test for uploads OK (1=OK,0=NOT OK)
DWNTAG	EQU	NO	; If YES, files with F3 attribute bit can be
			; downloaded regardless of access byte restrictions
;
; Access byte flag bit assignments
;
;	Bit	; Used for
;	0	; System access (no admittance if off)
;	1	; BBS access (if off, dumped to CP/M)
;	2	; Read access (if off, no "R" command allowed)
;	3	; Write access (if off, no "E" command allowed)
;	4	; CP/M access (if off, no admittance to CP/M)
;	5	; Download access (if off, no downloads permitted)
;	6	; Upload access (if off, no uploads permitted)
;	7	; Privileged user (if on, user is "privileged")
;
; Of these bits, only 5 and 6 are used by XMODEM.  Bit numbers are
; powers of 2, bit 0 being least significant bit of byte.
;-------------------------------------------------------------------------
; The CONFUN and WRTLOC are supported by BYE339 and many BBS's require
; the WRTLOC for propoer operation. These functions are not specific to
; MBBS and therefore have been made independant of the MBBS equate.
;
; (Set CONFUN/WRTLOC YES if using with MBBS)
;
CONFUN	EQU	YES	; Yes, check local console for function keys
SYSABT	EQU	YES	; If yes, sysop can abort up/downloads with ^X
			; (CONFUN must be enabled to use this option)
;
; If you set CONFUN true, a call to the console status check routine in
; the BIOS will be done during waiting periods and when sector counts
; are displayed on the local console in order to allow MBYE and BYE339
; function keys to work.  This is for MBYE.  Other versions of BYE3
; may or may not check for console function keys during the console
; status check "MSTAT" routine.
;
WRTLOC	EQU	YES	; Yes, set/reset WRTLOC so BYE won't hang up
LOCOFF	EQU	12	; # of bytes from JMP COLDBOOT to WRTLOC byte
;
; NOTE: Code to set/reset WRTLOC assumes WRTLOC byte to be
;	located "LOCOFF" bytes from the JMP COLDBOOT instruction at
;	the beginning of the BYE3 BIOS jump table. On BYE3 versions
;	and MBYE versions, this offset is usually 12. Note:
;	TIMEON and RTC should be set to no if B3RTC is on.
;	(If BYEBDOS is enabled, the appropriate extended BDOS
;	calls are used to set and reset the WRTLOC if this
;	equate is set and LOCOFF is ignored in these cases.)
;
;		   End of Miscellaneous Support Bytes
;=======================================================================
;		start of MBBS/MBYE specific information
;
B3RTC	EQU	NO	; If YES, your clock is setup in BYE3 (or MBYE)
			; set to NO if using BYEBDOS
B3COFF	EQU	25	; OFFSET from COLDBOOT: to RTCBUF address
B3CMOS	EQU	7	; OFFSET from RTCBUF: to mins on system
;
MBMXT	EQU	NO	; If YES, running MBYE with max. time on system
MBMXO	EQU	24	; OFFSET from COLDBOOT: to MXML address
;
; If B3RTC is YES and LOGCAL is YES, the log file will show
; the date and time of all up/downloads.  Note: Set RTC, TIMEON,
; and BYEBDOS to NO if using B3RTC or MBMXT.
;
; Note: Some of these equates may not be valid if you are using MBYE*
;	with another BBS program - check them carefully.
;
MBBS	EQU	NO	; Yes if running MBBS v2.9 up
LOGSYS	EQU	NO	; Set YES if running MBBS v3.1 or earlier
MBDESC	EQU	NO	; Yes if running MBBS v4.0 up for upload desc.
NEWPRV	EQU	NO	; Yes: all new uploads are private initially
MBFMSG	EQU	NO	; Yes if running MBYE v4.1 up with MFMSG
;
;
;----------------------------------------------------------------------
;
; If B3RTC is YES download time may be limited using the following
; equates instead of using MAXMIN.  MAXMIN will be the default value
; if BYE is not running.
;
B3TOS	EQU	NO	; Yes if using BYE3/MBYE and want to show time on sys
;
MTOS	EQU	NO	; Yes if using maximum time on system instead
			;   of MAXMIN to limit transmission time
;
	 IF	MTOS AND MBMXT	; both must be YES
MXTOS	EQU	YES	; (leave YES)
	 ENDIF
;
	 IF	NOT (MTOS AND MBMXT) ; (if either is NO)
MXTOS	EQU	NO	; (leave NO)
	 ENDIF
;
MXTL	EQU	NO	; Yes if limiting transmission time to time
			;   left plus MAXMIN. MXTOS must be yes.
;
	 IF	MXTL AND MXTOS	; both must be YES
MTL	EQU	YES	; (leave YES)
	 ENDIF
;
	 IF	NOT (MXTL AND MXTOS); (if either are NO)
MTL	EQU	NO	; (leave NO)
	 ENDIF
;
;		end of MBBS/MBYE specific information
;=======================================================================
;
	ORG	100H
	JMP	BEGIN
;
;-----------------------------------------------------------------------
;
; This is the I/O patch area.  Assemble the appropriate I/O patch file
; for your modem, then integrate it into this program via DDT (or SID).
; Initially, all jumps are to zero, which will cause an unpatched XMODEM
; to simply execute a warm boot.  All routines must end with RET.
;
	 IF	NOT BYEBDOS	; Universal I/O
CONOUT:	JMP	0		; See 'CONOUT' discussion above
MINIT:	JMP	0		; Initialization routine (if needed)
UNINIT:	JMP	0		; Undo whatever MINIT did (or return)
SENDR:	JMP	0		; Send character (via POP PSW)
CAROK:	JMP	0		; Test for carrier
MDIN:	JMP	0		; Receive data byte
GETCHR:	JMP	0		; Get character from modem
RCVRDY:	JMP	0		; Check receive ready (A - ERRCDE)
SNDRDY:	JMP	0		; Check send ready
SPEED:	JMP	0		; Get speed value for transfer time
EXTRA1:	JMP	0		; Extra for custom routine
EXTRA2:	JMP	0		; Extra for custom routine
EXTRA3:	JMP	0		; Extra for custom routine
	 ENDIF
;
;-----------------------------------------------------------------------
;
	 IF	NOT (LARGEIO OR	BYEBDOS)
	ORG	100H+80H	; Origin plus 128 bytes for patches
	 ENDIF
;
	 IF	LARGEIO	AND NOT	BYEBDOS
	ORG	100H+LARSIZE	; I/O patch area size if over 128 bytes
	 ENDIF
;
; PRIVATE/SETAREA UPLOAD DISK/USER AREAS:
;
; (Here at start (usually 180H unless LARGEIO) so can be easily patched
; in .COM file using DDT without needing to reassemble.  All references
; are made to these locations in memory and not to DRV/PRDRV/USR/PRUSR
; equates directly.)
;
XPRDRV:	DB	PRDRV		; Private uploads go to this disk/user
XPRUSR:	DB	PRUSR
;
XDRV:	DB	DRV		; Forced uploads (if SETAREA EQU YES)
XUSR:	DB	USR		; Go to this disk/user
;
	 IF	MBFMSG
XMDRV:	DB	MSGDRV		; Message uploads go to this disk/user
XMUSR:	DB	MSGUSR		; (if MBFMSG option enabled)
	 ENDIF
;
;-----------------------------------------------------------------------
;
; File descriptors, change as desired if this list is not suitable.
; Move the line with the terminating '$' up, if fewer descriptors are
; desired.
;
	IF	ASKIND AND DESCRIB
;
KIND0:	DB	'  0) - CP/M',CR,LF
KIND1:	DB	'  1) - ZCPR',CR,LF
KIND2:	DB	'  2) - MS-DOS/PC-DOS',CR,LF
KIND3:	DB	'  3) - dBASE',CR,LF
KIND4:	DB	'  4) - Basic',CR,LF
KIND5:	DB	'  5) - General',CR,LF
KIND6:	DB	'  6) - Modems',CR,LF
KIND7:	DB	'  7) - Games',CR,LF
KIND8:	DB	'  8) - Xerox/KPro',CR,LF
KIND9:	DB	'  9) - RCP/M',CR,LF
	DB	'$'
	ENDIF
;.....
;
;----------------------------------------------------------------------
;
; If ASKAREA and SETAREA are set, then set these areas up and modify
; the message text in the FILTYP: function below if you desire a
; different choice. (As released in XMDM121, 1 = CP/M, 2 = MS/PC-DOS
; and 3 = General Interest.)
;
	 IF	ASKAREA	AND SETAREA
;
MAXTYP	EQU	'3'		; Set maximum type choice # here
;
TYPTBL:	DB	'B',0		; CHOICE 1 (CP/M NORMAL)
	DB	'B',9		; CHOICE 1 (CP/M PRIVATE)
	DB	'B',3		; CHOICE 2 (MS/PC-DOS NORMAL)
	DB	'B',9		; CHOICE 2 (MS/PC-DOS PRIVATE)
	DB	'B',0		; CHOICE 3 (General interest NORMAL)
	DB	'B',9		; CHOICE 3 (General interest PRIVATE)
;
	 ENDIF
;
;=======================================================================
;
;			PROGRAM STARTS HERE
;
;=======================================================================
;
; Save CP/M stack, initialize new one for this program
;
BEGIN:	LXI	H,0
	DAD	SP
	SHLD	STACK
	LXI	SP,STACK	; Initialize new stack
;
	 IF	BYEBDOS
	CALL	BYECHK
	JZ	BYEOK
	CALL	ILPRT
	DB	'You need to be running BYEBDOS',CR,LF,0
	JMP	EXIT2		; Get stack pointer back and return
;
BYEOK:	MVI	C,BDSTOS	; Get current maximum time on system
	MVI	E,255
	CALL	BDOS
	STA	MAXTOS
	 ENDIF
;
	 IF	B3RTC AND MXTOS	AND (NOT BYEBDOS)
	CALL	BYECHK		; If BYE not active
	MVI	A,MAXMIN	; (we'll use MAXMIN as default)
	JNZ	EXTMXT		; Skip MXML update
	LHLD	0001H		; Get JMP COLDBOOT
	DCX	H
	MOV	D,M
	DCX	H
	MOV	E,M
	LXI	H,MBMXO		; + MBMXO offset to MXML
	DAD	D
	MOV	A,M		; = max time allowed on system
;
EXTMXT:	STA	MAXTOS		; Store max download time
	 ENDIF
;
; Get address of RTCBUF in BYE3 or MBYE
;
	 IF	B3RTC AND (NOT BYEBDOS)
	CALL	BYECHK		; See if BYE3/MBYE is running
	JNZ	NOBYE0		; If not, skip this junk
	LHLD	0001H		; Get COLDBOOT addr
	DCX	H		; (just before JMP WBOOT)
	MOV	D,M		; And stuff in DE
	DCX	H
	MOV	E,M
	LXI	H,B3COFF	; Add offset to RTCBUF address
	DAD	D		; (in HL)
	MOV	E,M		; Get RTCBUF address
	INX	H		; And
	MOV	D,M		; Stuff in DE
	XCHG			; Swap into HL
	SHLD	RTCBUF		; Save for use later
	 ENDIF
;
NOBYE0:	 IF	CONFUN		; Console status checks to be done?
	LHLD	0001H		; If so get addr of warmboot (jmp table)
	INX	H
	INX	H
	INX	H		; + 3 = address of console status check
	SHLD	CONCHK+1	; Stuff after call for FUNCHK
	 ENDIF
;
	 IF	WRTLOC		; Set WRITE LOCK?
	CALL	SETLCK
	 ENDIF
;
; Save the current drive and user area
;
NOBYE1:	MVI	E,0FFH		; Get the current user area
	MVI	C,SETUSR
	CALL	BDOS
	STA	OLDUSR		; Save user number here
	MVI	C,CURDRV	; Get the current drive
	CALL	BDOS
	STA	OLDDRV		; Save drive here
;
	 IF	B3TOS OR TIMEON
	CALL	TIME		; Get user's time status
	 ENDIF
;
	 IF	BYEBDOS	AND (NOT TIMEON)
	MVI	C,BDPTOS	; Display time on system and
	CALL	BDOS		; log off if over time limit
	 ENDIF
;
	CALL	ILPRT
	DB	CR,LF
;
	 IF	LUXMOD
	DB	'LUX-'
	 ENDIF
;
	DB	'XMODEM v'
	DB	VERSION+'0',INTERM+'0','.',MODLEV+'0',' - '
	DB	VMONTH/10+'0',VMONTH MOD 10+'0','/'
	DB	VDAY/10+'0',VDAY MOD 10+'0','/'
	DB	VYEAR/10+'0',VYEAR MOD 10+'0',CR,LF,0
;
; Stuff address of BIOS CONOUT vector in our routine as default.
;
	 IF	USECON AND NOT BYEBDOS
	LHLD	0001H		; Point to warm boot for normal BIOS
	LXI	D,9
	DAD	D		; Calc addr of normal BIOS conout vector
	SHLD	CONOUT+1	; Save in case no BYE program is active
	CALL	BYECHK
	JNZ	NOBYE
	XCHG			; Point to the console output routine
	SHLD	CONOUT+1	; Save vector address supplied by BYE
	 ENDIF
;
; Get option
;
NOBYE:	LXI	H,FCB+1		; Get primary option
	MOV	A,M
	STA	OPTSAV		; Save option
	CPI	'R'		; Receive file?
	JZ	RECVOPT
;
; Send option processor
; Single option: "K"	- force 1k mode
;
	INX	H		; Look for a 'K'
	MOV	A,M
	CPI	' '		; Is it a space?
	JZ	ALLSET		; Then we're ready to send...
	CPI	'K'
	JNZ	OPTERR		; "K" is the only setable 2nd option
	LDA	MSPEED
	CPI	MINKSP		; If less than MINKSP bps, ignore 1k
	JC	ALLSET		; Request
	MVI	A,'K'		; Set 1k mode
	STA	KFLAG		; First, force us to 1K mode
	CALL	ILPRT
	DB	'(1k protocol selected)',CR,LF,0
	JMP	ALLSET		; That's it for send...
;
; Receive option processor
; 3 or 4 options: "X"	- disable auto-protocol select
;		  "P"	- receive file in private area
;		  "C"	- force checksum protocol
;		  "M"	- message file upload (if MBFMSG)
;
RECVOPT:MVI	A,'K'		; First off, default to 1K mode
	STA	KFLAG
	MVI	A,0		; And default to CRC mode
	STA	CRCFLG
;
	CALL	RCVOPC		; Check 1st option
	CALL	RCVOPC		; Check 2nd option
	CALL	RCVOPC		; Check 3rd option
;
	 IF	MBFMSG
	CALL	RCVOPC		; Check 4th option
	 ENDIF
;
	 IF	NDESC
	CALL	RCVOPC		; Check 4th (or 5th) option
	 ENDIF
;
	; [WBW] Added to support port number
	CALL	RCVOPC		; Check 5th (or 6th) option
;
	JMP	OPTERR		; If 7th or 8th option, whoops!
;
RCVOPC:	INX	H		; Increment pointer to next character
	MOV	A,M		; Get option character HL points to
	CPI	' '		; Space?
	JNZ	CHK1ST		; No, we have an option
	POP	PSW		; Else, we are done (restore stack)
	JMP	ALLSET		; Exit routine now
;
CHK1ST:	CPI	'P'		; Got a "P" option?
	JNZ	CHK2ND		; Nope
	STA	PRVTFL		; Yep, set private upload flag
	RET			; Check next option
;
CHK2ND:	CPI	'C'		; Got a "C" option?
	JNZ	CHK3RD		; Nope
	STA	CRCFLG		; Set checksum flag (crc flag="C")
	CALL	ILPRT
	DB	'(Checksum protocol selected)',CR,LF,0
	RET
;
CHK3RD:	CPI	'X'		; Got an "X" for first option?
	JNZ	CHK4TH
	MVI	A,0
	STA	KFLAG		; Disable "1K" flag
	CALL	ILPRT
	DB	'(128 byte protocol only)',CR,LF,0
	RET
;
CHK4TH:
	 IF	MBFMSG		; Allowing "RM" for message uploads?
	CPI	'M'		; Got an "M" for message upload?
	JNZ	CHK5TH		; Nope, try next
	STA	MSGFLG		; If "M", set MSGFLG
	MVI	A,'P'		; Also, set PRVTFL
	STA	PRVTFL
	LDA	XMDRV		; And copy XMDRV
	STA	XPRDRV
	LDA	XMUSR		; And XMUSR to XPRDRV / XPRUSR
	STA	XPRUSR
	RET
	 ENDIF
;
CHK5TH:
	 IF	NDESC		; Allowing "RN" to skip upload descript?
	CPI	'N'		; Got an 'N'?
	JNZ	CHK6TH		; Nope, try next
	STA	NDSCFL		; else set flag to skip descript phase
	RET
	 ENDIF
;
CHK6TH:
	; [WBW] Get target serial port (0-9 supported)
	CPI	'0'
	JC	BADROP		; If < 0, out of range
	CPI	'9' + 1
	JNC	BADROP		; If > 9, out of range
	SUI	'0'		; Make binary
	STA	PORT
	RET
;
BADROP:	POP	PSW		; Restore stack
	JMP	OPTERR		; is bad option
;
; All options have been set, gobble up garbage characters from the line
; prior to receive or send and initialize whatever has to be initialized
;
ALLSET:	CALL	GETCHR
	CALL	GETCHR
	LDA	PORT		; [WBW] Pass serial port to driver
	CALL	MINIT
	STA	CPUMHZ		; [WBW] Save CPU speed from MINIT
	SHLD	RCVSCL		; [WBW] Save rcv loop scalar from MINIT
;
; Jump to appropriate function
;
	LDA	OPTSAV		; Get primary option again
;
	 IF	LOGCAL
	STA	LOGOPT		; But save it
	 ENDIF
;
	CPI	'L'		; To send a file from a library?
	JZ	SENDFIL
	CPI	'R'		; To receive a file?
	JZ	RCVFIL
	CPI	'S'
	JZ	SENDFIL		; Otherwise go send a file
;
; Invalid option
;
OPTERR:
;
	 IF	ASKAREA	AND SETAREA
	LDA	OPTSAV		; Check 'option'
	CPI	'A'		; If 'A' (avail upload space option)
	CZ	FILTYP		;   ask type of upload...
	 ENDIF
;
	 IF	NOT (SETAREA OR	LUXMOD)
	CALL	ILPRT
	DB	CR,LF,'Uploads files to specified or '
	DB	'current disk/user',0
	 ENDIF
;
	 IF	SETAREA	AND NOT	LUXMOD
	CALL	ILPRT
	DB	CR,LF,'Uploads files to ',0
	LDA	XDRV
	CALL	CTYPE
	LDA	XUSR
	MVI	H,0
	MOV	L,A
	CALL	DECOUT
	MVI	A,':'
	CALL	CTYPE
	CALL	ILPRT
	DB	' (',0
	LDA	XDRV
	STA	KDRV
	CALL	KSHOW
	MVI	A,')'
	CALL	CTYPE
	 ENDIF
;
	 IF	NOT LUXMOD
	CALL	ILPRT
	DB	CR,LF,'Private files to ',0
	LDA	XPRDRV
	CALL	CTYPE
	LDA	XPRUSR
	MVI	H,0
	MOV	L,A
	CALL	DECOUT
	MVI	A,':'
	CALL	CTYPE
	LDA	XPRDRV		; If private drive is
	MOV	B,A
	LDA	XDRV		; The same as forced upload drive
	SUB	B
	JZ	SKSK2		; Skip showing space available 2nd time
	CALL	ILPRT
	DB	' (',0
	LDA	XPRDRV		; Else show it..
	STA	KDRV
	CALL	KSHOW
	MVI	A,')'
	CALL	CTYPE
;
SKSK2:	CALL	ILPRT
	DB	CR,LF,0
	 ENDIF
;
	LDA	OPTSAV		; Check 'option'
	CPI	'A'		; If 'A' (avail upload space option)
	JZ	EXIT		; Skip error message
;
	 IF	WRTLOC AND NOT BYEBDOS
	CALL	RSTLCK
	 ENDIF
;
	CALL	ERXIT		; Exit with error
	DB	'++ Examples of valid options: ++ '
	DB	'(use Ctrl-C or Ctrl-K to abort)',CR,LF,LF
;
	 IF	NOT LUXMOD
	DB	'XMODEM S HELLO.DOC         send a file to you',CR,LF
	DB	'XMODEM S B1:HELLO.DOC      send from a named '
	DB	'drive/area',CR,LF
	DB	'XMODEM SK HELLO.DOC        send in 1k blocks',CR,LF
	DB	'XMODEM L CAT.LBR CAT.COM   send a file from a library'
	DB	CR,LF
	DB	'XMODEM LK CAT.LBR CAT.COM  send in 1k blocks',CR,LF
	DB	'   The ".LBR" file extension may be omitted',CR,LF
	DB	'   Add "0"-"9" to specify serial port',CR,LF,LF
	DB	'XMODEM R HELLO.DOC         receive a file from you'
	DB	CR,LF
	DB	'XMODEM RP HELLO.DOC        receive in a private area'
	DB	CR,LF
	 ENDIF
;
	 IF	(MBDESC	OR DESCRIB) AND	NDESC
	DB	'XMODEM RN FILE.EXT         receive without description'
	DB	CR,LF
	 ENDIF
;
	 IF	(NOT LUXMOD) AND MBFMSG
	DB	'XMODEM RM MESSAGE.FIL      receive message for MBBS'
	DB	CR,LF
	 ENDIF
;
	 IF	NOT LUXMOD
	DB	'   Add "C" for forced checksum ("RC" "RPC")',CR,LF
	DB	'   Add "X" for forced 128 byte protocol ("RX" "RPX")',CR,LF
	DB	'   Add "0"-"9" to specify serial port'
	DB	CR,LF
	DB	'   "R" switches from CRC to checksum after 5 retries'
	DB	CR,LF,LF
	DB	'XMODEM A                   shows areas/space for '
	DB	'uploads$'
	 ENDIF
;
	 IF	LUXMOD
	DB	'SEND MEMBERNAME.TYP        sends member with CRC'
	DB	CR,LF
	DB	'SENDK MEMBERNAME.TYP       sends using 1k packets'
	DB	CR,LF,LF
	DB	'XMODEM S MEMBERNAME.TYP    same as SEND command'
	DB	CR,LF
	DB	'XMODEM SK MEMBERNAME.TYP   same as SENDK',CR,LF,LF
	DB	'(XMODEM can NOT receive while in LUX.)$'
	 ENDIF
;
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; ---> SENDFIL	sends a CP/M file
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; The CP/M file specified in the XMODEM command is transferred over the
; phone to another computer running modem with the "R" (receive) option.
; The data is sent one record at a time with headers and checksums, and
; retransmission on errors.
;
SENDFIL:CALL	LOGDU		; Check file name or drive/user option
	LDA	OPTSAV
	CPI	'L'		; If library option skip 'CNREC'
	CNZ	CNREC		; Ignore if in library mode
	CALL	OPENFIL		; Open the file
	MVI	E,100		; Wait 100 sec for initial 'NAK'
	CALL	WAITNAK
	LHLD	RCNT		; XMDM116.FIX
	CALL	CKKSIZ		; XMDM116.FIX -- Murray Simsolo
;
SENDLP:	CALL	CHKERR		; Check ratio of blocks to errors
	CALL	RDRECD		; Read a record
	JC	SENDEOF		; Send 'EOF' if done
	CALL	INCRRNO		; Bump record number
	XRA	A		; Initialize error count to zero
	STA	ERRCT
;
SENDRPT:CALL	SENDHDR		; Send a header
	CALL	SENDREC		; Send data record
	LDA	CRCFLG		; Get 'CRC' flag
	ORA	A		; 'CRC' in effect?
	CZ	SENDCRC		; Yes, send 'CRC'
	CNZ	SENDCKS		; No, send checksum
	CALL	GETACK		; Get the 'ACK'
	JC	SENDRPT		; Repeat if no 'ACK'
	CALL	UPDPTR		; Update buffer pointers and counters
	LDA	OPTSAV		; Get the command option again
	CPI	'L'
	JNZ	SENDLP		; If not library option, go ahead
;
;
; Check to see if done sending LBR member yet, downshift to small blocks
; if less that 8 remaining
;
	LHLD	RCNT
	MOV	A,H
	ORA	L		; See if L and H both zero now
	JZ	SENDEOF		; If finished, exit
	LDA	KFLAG		; Was last record a 1024 byte one?
	ORA	A
	JZ	SNRPT0		; Just handled an normal 128 byte record
	DCX	H		; Otherwise, must have be a BIG one, so
	DCX	H		; Seven ...
	DCX	H
	DCX	H
	DCX	H
	DCX	H
	DCX	H		; Plus
;
SNRPT0:	DCX	H		; One, is either 1 or 8
	SHLD	RCNT		; One (or eight) less to go
	CALL	CKKSIZ		; Check to see if at least 8 left
	JMP	SENDLP		; Loop until EOF
;
; File sent, send EOT's
;
SENDEOF: IF	LOGLDS
	LDA	DNLDS		; Get Down loads Counter
	INR	A		; One more download since log in
	STA	DNLDS		; And update counter
	 ENDIF
;
SNDEOFL:LDA	EOFCTR		; Get EOF counter
	CPI	5		; Tried five times ?
	JZ	EXITLG		; Yes, quit trying
	MVI	A,EOT		; Send an 'EOT'
	CALL	SEND
	LDA	EOFCTR		; Get EOF counter
	INR	A		; Add one
	STA	EOFCTR		; Save new count
	CALL	GETACK		; Get the ACK
	JC	SNDEOFL		; Loop if no ACK
	JMP	EXITLG		; All done
;.....
;
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; ---> RCVFIL Receive a CP/M file
;
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; Receives a file in block format as sent by another person doing
; "XMODEM S FILENAME.TYP".  Can be invoked by "XMODEM R FILENAME.TYPE"
; or by "XMODEM RC FILENAME.TYP" if checksum is to be used.
;
RCVFIL:	 IF	ACCESS
	CALL	BYECHK
	JNZ	RCVFL1
	LHLD	0001H		; Get JMP COLDBOOT
	DCX	H
	MOV	D,M
	DCX	H
	MOV	E,M
	LXI	H,ACBOFF	; + ACBOFF
	DAD	D
	MOV	A,M		; = ACCESS byte address
	ANI	ACUPLD		; Test upload access bit
	JNZ	RCVFL0		; If bit on, uploads OK
	CALL	ERXIT
	DB	'Sorry, but you are not allowed to upload files '
	DB	'at this time...$'
	 ENDIF
;
RCVFL0:	 IF	ACCESS AND MBFMSG
	LDA	MSGFLG
	ORA	A		; Is this "RM" upload?
	JZ	RCVFL1		; If not, skip ACWRIT check
	MOV	A,M
	ANI	ACWRIT		; If "RM", check if WRITE access
	JNZ	RCVFL1		; If so, ok
	CALL	ERXIT
	DB	'Sorry, but you are not allowed to enter messages '
	DB	'at this time...$'
	 ENDIF
;
RCVFL1:
	CALL	LOGDU		; Check file name or drive/user option
;
	 IF	ZCPR2
	LDA	WHEEL		; Let SYSOP put file wherever he wants
	ORA	A
	JZ	RCVFL5		; If WHEEL byte not set, stay normal
	LDA	RCVDRV
	ORA	A
	 ENDIF
;
;
	 IF	ZCPR2 AND NOT SPCDU
	JZ	RCVFL2
	 ENDIF
;
	 IF	ZCPR2 AND SPCDU
	JZ	RCVFL2
	 ENDIF
;
	 IF	ZCPR2
	SUI	'A'		; Convert ASCII drive to binary
	JMP	RCVFL3
;
RCVFL2:	LDA	OLDDRV
;
RCVFL3:	INR	A
	STA	FCB
	ADI	'A'-1		; Convert binary to ASCII
	STA	XDRV		; Drive
	LDA	RCVDRV		; See if a drive was requested
	ORA	A
	LDA	OLDUSR		; Current user
	JZ	RCVFL4		; If not, use current user
	LDA	RCVUSR		; Else get requested user
;
RCVFL4:	STA	XUSR		; User
	JMP	CONTIN
	 ENDIF	; ZCPR2
;
RCVFL5:	 IF	SETAREA
	LDA	XDRV
	SUI	40H
	STA	FCB
	 ENDIF
;
	LDA	PRVTFL		; Receiving to a private area?
	ORA	A
	JZ	RCVFL6		; If not, exit
	LDA	XPRDRV		; Private area takes precedence
	SUI	40H
	STA	FCB		; Store drive to be used
;
RCVFL6:	 IF	NOCOMR
	LXI	H,FCB+9		; Point to filetype
	MVI	A,'C'		; 1st letter
	CMP	M		; Is it C ?
	JNZ	RCVFL7		; If not, continue normally
	INX	H		; Get 2nd letter
	MVI	A,'O'		; 2nd letter
	CMP	M		; Is it O ?
	JNZ	RCVFL7		; If not, continue normally
	INX	H		; Get 3rd letter
	MVI	A,'M'		; 3rd letter
	CMP	M		; Is it M ?
	JNZ	RCVFL7		; If not, continue normally
	CALL	ILPRT		; Print renaming message
	DB	'Auto-renaming file to ".OBJ"',CR,LF,0
	LXI	H,FCB+9
	MVI	M,'O'
	INX	H
	MVI	M,'B'
	INX	H
	MVI	M,'J'
	JMP	CONTIN
	 ENDIF	; NOCOMR
;
RCVFL7:	 IF	NOCOMR AND CPM3
	LXI	H,FCB+9		; Point to filetype
	MVI	A,'P'		; 1st letter
	CMP	M		; Is it P ?
	JNZ	RCVFL8		; If not, continue normally
	INX	H		; Get 2nd letter
	MVI	A,'R'		; 2nd letter
	CMP	M		; Is it R ?
	JNZ	RCVFL8		; If not, continue normally
	INX	H		; Get 3rd letter
	MVI	A,'L'		; 3rd letter
	CMP	M		; Is it L ?
	JNZ	RCVFL8		; If not, continue normally
	CALL	ILPRT		; Print renaming message
	DB	'Auto-renaming file to ".OBP"',CR,LF,0
	LXI	H,FCB+9
	MVI	M,'O'
	INX	H
	MVI	M,'B'
	INX	H
	MVI	M,'P'
	JMP	CONTIN
	 ENDIF	; NOCOMR AND CPM3
;
; Check to see if filetype is .NDR, if so do NOT allow upload
;
RCVFL8:	 IF	ZCPR3
	LXI	H,FCB+9		; Point to filetype
	MVI	A,'N'		; 1st letter
	CMP	M		; Is it N ?
	JNZ	RCVFL9		; If not, continue normally
	INX	H		; Get 2nd letter
	MVI	A,'D'		; 2nd letter
	CMP	M		; Is it D ?
	JNZ	RCVFL9		; If not, continue normally
	INX	H		; Get 3rd letter
	MVI	A,'R'		; 3rd letter
	CMP	M		; Is it R ?
	JNZ	RCVFL9		; If not, continue normally
	CALL	ERXIT		; Print renaming message
	DB	'Cannot receive filetype ".NDR"',CR,LF,'$'
;
; Check to see if filetype is .RCP, if so do NOT allow upload
;
RCVFL9:	LXI	H,FCB+9		; Point to filetype
	MVI	A,'R'		; 1st letter
	CMP	M		; Is it R ?
	JNZ	CONTIN		; If not, continue normally
	INX	H		; Get 2nd letter
	MVI	A,'C'		; 2nd letter
	CMP	M		; Is it C ?
	JNZ	CONTIN		; If not, continue normally
	INX	H		; Get 3rd letter
	MVI	A,'P'		; 3rd letter
	CMP	M		; Is it P ?
	JNZ	CONTIN		; If not, continue normally
	CALL	ERXIT		; Abort with error msg
	DB	'Cannot receive filetype ".RCP"',CR,LF,'$'
	 ENDIF	; ZCPR3
;
CONTIN:
	 IF	MBFMSG
	LDA	MSGFLG
	ORA	A		; Is this "RM" upload?
	JNZ	DONT		; If yes, skip asking what kind of upload
	 ENDIF
;
	 IF	ASKAREA	AND SETAREA AND	(NOT ZCPR2)
	CALL	FILTYP		; Ask caller what kinda beast it is
	 ENDIF
;
	 IF	ASKAREA	AND SETAREA AND	ZCPR2
	LDA	WHEEL		; Don't ask the SYSOP
	ORA	A
	JNZ	DONT		; If WHEEL byte set, skip asking
	CALL	FILTYP		; Ask caller what kinda beast it is
	 ENDIF
;
DONT:	CALL	ILPRT		; Print the message
;
	 IF	NOT DSPFNAM
	DB	CR,LF,'File will be received on ',0
	 ENDIF
;
	 IF	DSPFNAM
	DB	CR,LF,'Receiving: ',0
	 ENDIF
;
	LDA	PRVTFL		; Going to store in the private area?
	ORA	A
	JZ	CONT1		; If not, exit
;
	LDA	XPRDRV		; Get private drive
	JMP	CONT2		; If yes, it takes priority
;
CONT1:
	 IF	SETAREA
	LDA	XDRV		; Setarea uses a specified drive
	 ENDIF
;
	 IF	NOT SETAREA
	LDA	OLDDRV		; Otherwise get current drive
	ADI	'A'		; Convert to ASCII
;
NOTDRV:	DB	0,0		; Filled in by 'GETDU' if requested
	 ENDIF
;
CONT2:
	STA	KDRV		; Save drive for KSHOW
	SUI	40H		; Convert ASCII to binary
	STA	FCB		; Stuff in FCB
	LDA	KDRV		; Get ASCII version back again
	CALL	CTYPE		; Print the drive to store on
	LDA	PRVTFL		; Going to store in the private area?
	ORA	A
	JZ	NOPRVL		; If nope, skip ahead
;
	 IF	LOGCAL
	MVI	A,'P'		; If private upload
	STA	LOGOPT		; Show "P" as option
	 ENDIF
;
	LDA	XPRUSR		; Get private user area
	JMP	CONT3		; It takes priority
;
NOPRVL:
	 IF	SETAREA
	LDA	XUSR		; Setarea takes next precedence
	 ENDIF
;
	 IF	NOT SETAREA
	LDA	OLDUSR		; Get current drive for default
;
NOTUSR:	DB	0,0		; Filled in by 'GETDU' if requested
	 ENDIF
;
CONT3:	MVI	H,0
	MOV	L,A
	CALL	DECOUT		; Print the user area
;
	 IF	NOT DSPFNAM
	CALL	ILPRT
	DB	':',CR,LF,0
	 ENDIF
;
	 IF	DSPFNAM
	MVI	A,':'
	CALL	CTYPE		; We showed disk/user:
	LXI	H,FCB+1		; Now display filename
	CALL	DSPFN
	CALL	ILPRT
	DB	CR,LF,0
	 ENDIF
;
	CALL	KSHOW		; Show available space remaining
	CALL	ILPRT
	DB	CR,LF,0
	CALL	CHEKFIL		; See if file exists
	CALL	MAKEFIL		; If not, start a new file
	CALL	ILPRT
	DB	'File open - ready to receive',CR,LF
	DB	'To cancel: Ctrl-X, pause, Ctrl-X',CR,LF,0
;
	 IF	B3RTC AND (NOT MBMXT OR	BYEBDOS)
	CALL	GETTOS		; Get time on system
	SHLD	TOSSAV		; Save it for exit
	 ENDIF
;
RCVLP:	CALL	RCVRECD		; Get a record
	JC	RCVEOT		; Got 'EOT'
	CALL	WRRECD		; Write the record
	CALL	INCRRNO		; Bump record number
	CALL	SENDACK		; Ack the record
	JMP	RCVLP		; Loop until 'EOF'
;
;
; Got EOT on record so flush buffers then done
;
RCVEOT:	LHLD	RECDNO		; Check for zero length file
	MOV	A,H		; If no records, no file
	ORA	L
	JNZ	EOT1		; If not zero, continue, else abort
	CALL	RCVSABT		; Abort and erase the zero length file
	JMP	EXIT		; And exit
;
EOT1:	CALL	WRBLOCK		; Write the last block
	CALL	SENDACK		; Ack the record
	CALL	CLOSFIL		; Close the file
	XRA	A		; Clear CTYPE's console
	STA	CONONL		; Output only flag
;
	 IF	LOGLDS
	LDA	UPLDS		; Get Upload Counter
	INR	A		; One more upload since log in
	STA	UPLDS		; Update Counter
	 ENDIF
;
; Logging upload or crediting time on?
;
	 IF	LOGCAL
	LHLD	VRECNO		; If yes, get virtual # of recs
	SHLD	RCNT		; And stuff in RCNT
	CALL	FILTIM		; Calculate appox. xfer time
	 ENDIF
;
	 IF	B3RTC AND MBMXT	AND (NOT BYEBDOS)
	CALL	BYECHK		; If BYE not active
	JNZ	EXITLG		; Skip MXML update
	LHLD	0001H		; Get JMP COLDBOOT
	DCX	H
	MOV	D,M
	DCX	H
	MOV	E,M
	LXI	H,MBMXO		; + MBMXO offset to MXML
	DAD	D
	MOV	A,M		; = max time allowed on system
	ORA	A		; Check it (zero?)
	JZ	EXITLG		; If unlimited time, skip update
	INR	A		; Else, increment it (for secs)
	ADD	C		; Add mins LSB (can't be >255)
	JC	MAK255		; If overflow, make it max (255)
	JZ	MAK255		; (if zero, make 255)
	MOV	M,A		; Update it (credit them for upload)
	JMP	EXITLM
;
MAK255:	MVI	A,255		; If up to max, make sure they don't
	MOV	M,A		; Get LESS than what they had..
	 ENDIF
;
	 IF	B3RTC AND NOT (BYEBDOS OR MBMXT)
	CALL	BYECHK
	JNZ	EXITLG		; SKIP this if BYE not running
	LHLD	RTCBUF		; Get address of RTCBUF in HL
	LXI	D,B3CMOS	; Add offset to mins on system
	DAD	D		; (addr in HL)
	LDA	TOSSAV		;Get saved time on system
	MOV	M,A		; And restore it
	INX	H		; (don't count upload time
	LDA	TOSSAV+1	; Against them)
	MOV	M,A
	 ENDIF
;
	 IF	BYEBDOS	AND (NOT B3RTC)
	LDA	MAXTOS		; Get maximum time allowed
	ORA	A
	JZ	EXITLG		; If zero, he's a super-guy anyway
	INR	A
	ADD	C		; Add in upload time
	JC	MAK254		; Make it 254 minutes if overflow
	JZ	MAK254		; (or zero)
	CPI	255		; (or 255)
	JNZ	MAXSTR
;
MAK254:	MVI	A,254		; (254 is max allowed)
;
MAXSTR:	STA	MAXTOS		; Save for internal use
	MOV	E,A
	MVI	C,BDSTOS	; Set maximum time on system
	CALL	BDOS
	 ENDIF
;
EXITLM:	 IF	BYEBDOS	OR (B3RTC AND MBMXT)
	CALL	ILPRT
	DB	CR,LF,'Upload time credited towards maximum timeon.'
	DB	CR,LF,0
	 ENDIF
;
	JMP	EXITLG
;
;-----------------------------------------------------------------------
;
;			SUBROUTINES
;
;-----------------------------------------------------------------------
;
;	FILTYP: Ask file type for uploads
;
	 IF	ASKAREA	AND SETAREA
;
; Routine to get file type for uploads (modified from XMDM10XX.ASM
; by Russ Pencin (Dallas Connection)). (Modify MAXTYP and TYPTBL
; near the top of the program.)
;
FILTYR:	CALL	ILPRT
	DB	CR,LF,0
;
FILTYP:	CALL	ILPRT		; Modify message as needed
	DB	CR,LF,'Is file for:',CR,LF,CR,LF
	DB	'   (1) CP/M',CR,LF
	DB	'   (2) MS/PC-DOS',CR,LF
	DB	'or (3) General interest?',CR,LF,CR,LF
	DB	'Enter choice (1, 2 or 3): ',0
	 ENDIF	;ASKAREA AND SETAREA
;
	 IF	ASKAREA	AND SETAREA AND	WRTLOC
	CALL	RSTLCK		;Turn off WRTLOC so RDCON will work
	 ENDIF
;
	 IF	ASKAREA	AND SETAREA
	MVI	C,RDCON
	CALL	BDOS
	CPI	'1'		;is it a cpm file
	JC	FILTYR		;nope, ask again use default upload area(s)
	CPI	MAXTYP+1
	JNC	FILTYR
	SUI	'1'		;GET OFFSET FOR TYPTBL
	RAL
	RAL
	MVI	D,0
	MOV	E,A
	LXI	H,TYPTBL
	DAD	D
	MOV	A,M
	STA	XDRV		;set drive
	INX	H
	MOV	A,M		;user
	STA	XUSR
	INX	H
	MOV	A,M		;private drive
	STA	XPRDRV
	INX	H
	MOV	A,M		;and private user values
	STA	XPRUSR
	CALL	ILPRT
	DB	CR,LF,0
	 ENDIF	;ASKAREA AND SETAREA
;
	 IF	ASKAREA	AND SETAREA AND	WRTLOC
	CALL	SETLCK		;Turn WRTLOC back on
	 ENDIF
;
	 IF	ASKAREA	AND SETAREA
	RET
	 ENDIF
;
;---------------------------------------------------------------------
; WRTLOC ROUTINES (SETLCK AND RSTLCK)
;
	 IF	WRTLOC AND NOT BYEBDOS
SETLCK:	CALL	BYECHK		; Is BYE running
	RNZ			; If not, skip this
	LHLD	0001H		; Get JMP COLDBOOT
	DCX	H
	MOV	D,M
	DCX	H
	MOV	E,M
	LXI	H,LOCOFF	; + LOCOFF
	DAD	D
	ORI	0FFH		; = WRTLOC address
	MOV	M,A		; Turn the lock on
	RET
;
RSTLCK:	CALL	BYECHK		; Is BYE running
	RNZ			; Nope, don't touch a thing
	LHLD	0001H		; If so, time to reset it
	DCX	H		; Get JMP COLDBOOT addr.
	MOV	D,M
	DCX	H
	MOV	E,M
	LXI	H,LOCOFF	; + LOCOFF bytes
	DAD	D		; = WRTLOC address
	XRA	A		; Clear it
	MOV	M,A		; (so ctrl-C/ctrl-K work)
	RET
	 ENDIF	;WRTLOC AND NOT BYEBDOS
;
	 IF	WRTLOC AND BYEBDOS
SETLCK:	MVI	C,BDWRTL	; Set/Get writeloc function
	MVI	E,1		; Turn on WRTLOC flag
	CALL	BDOS
	RET
;
RSTLCK:	MVI	C,BDWRTL	; Set/Get writeloc function
	MVI	E,0		; Turn off WRTLOC flag
	CALL	BDOS
	RET
	 ENDIF
;
;---------------------------------------------------------------------
;
; Display file name function
;
	 IF	DSPFNAM		; HL=FCB address
DSPFN:	MVI	B,8
;
PRNAM:	MOV	A,M
	ANI	7FH		; Strip any attribute bits
	CPI	' '		; Don't print blanks
	CNZ	CTYPE		; Print filename
	INX	H
	DCR	B
	JNZ	PRNAM
;
PRDOT:	MVI	A,'.'		; After first part, print dot
	CALL	CTYPE
	MVI	B,3
;
PRTYP:	MOV	A,M
	ANI	7FH		; Strip any attribute bits
	CPI	' '		; Don't print blanks
	CNZ	CTYPE		; Print filetype
	INX	H
	DCR	B
	JNZ	PRTYP
	RET
	 ENDIF	; DSPFNAM
;
; Check to see if BYE is running before getting CONOUT, checking MBBS
; ACCESS byte or setting/resetting WRTLOC.  This routine also returns
; the address of the original cold boot routine in DE.
;
; Go through a big search to see if BYE is active.
;
	 IF	BYEBDOS
BYECHK:	MVI	C,32		; This bizarre combination determines
	MVI	E,241		; If BYE is not there.
	CALL	BDOS
	CPI	77		; Is it there?
	RET
	 ENDIF
;
	 IF	(NOT BYEBDOS) AND (USECON OR ACCESS OR WRTLOC)
BYECHK:	LHLD	0001H		; Point to warm boot again
	DCX	H		; If BYE active,
	MOV	D,M		; Pick up pointer to BYE variables
	DCX	H		; (COVECT) followed by 'BYE'
	MOV	E,M
	LXI	H,CONOFF	; Calculate address of BYE variable
	DAD	D		; Where ptr to orig BIOS vector stored
	MOV	E,M		; Load that address into DE, if BIOS
	INX	H		; Is active, DE now points to original
	MOV	D,M		; BIOS console output vector
	INX	H		; Point to BYE signon message
;
; Note that if more BYE variables are added after the cold boot pointer,
; extra INX may be needed.  Fix to match your BYE.
;
	MOV	A,M		; Get letter
	ANI	05FH		; Convert to upper case if needed
	CPI	'B'		; Try to match 'BYE'
	RNZ			; Out if BYE not active
	INX	H
	MOV	A,M
	ANI	05FH		; Convert to upper case if needed
	CPI	'Y'
	RNZ
	INX	H
	MOV	A,M
	ANI	05FH		; Convert to upper case if needed
	CPI	'E'
	RET
	 ENDIF
;
; Check next character to see if a space or non-space, file name error
; if no ASCII character.
;
CHKFSP:	DCR	B
	JZ	NFN		; Error if end of chars.
	MOV	A,M
	CPI	' '+1
	RNC			; Ok if valid character so return
	INX	H
	JMP	CHKFSP		; Look at next character
;
; Check next character to see if a space or non-space, go to menu if a
; command error.
;
CHKSP:	DCR	B
	JZ	OPTERR
	INX	H
	MOV	A,M		; Get the char. there
	CPI	' '		; Space character?
	RET			; JZ = space, JNZ = non-space
;
; Exit, but first write record to log file and ask for description
;
EXITLG:
;
	 IF	LOGCAL OR MBDESC OR MBFMSG
	CALL	LOGCALL
	 ENDIF
;
; Ask sysop for a description of the file if ASKSYS is yes
;
	 IF	DESCRIB	AND ZCPR2 AND (NOT ASKSYS)
	LDA	WHEEL		; If its the Sysop, don't ask
	ORA	A		; For a description because he
	JNZ	EXIT		; Might want to batch recv files
	 ENDIF
;
	 IF	DESCRIB	AND NDESC
	LDA	NDSCFL		; If user picked "N" option
	ORA	A		; allow them to skip upload
	JNZ	EXIT		; descript
	 ENDIF
;
	 IF	DESCRIB	AND WRTLOC
	CALL	RSTLCK		; Clear WRTLOC before DESCRIB
	 ENDIF
;
	 IF	DESCRIB
	CALL	ASK		; If yes, ask for description of file
	 ENDIF
;
; Finished, clean up and return to CP/M, send thank-you and timeon
; messages if enabled.
;
EXIT:	XRA	A
	STA	CONONL		; Reset 'console only' flag for timeon
;
	 IF	WRTLOC
	CALL	RSTLCK		; Clear WRTLOC
	 ENDIF
;
NOBYE2:	CALL	UNINIT		; Reset vectors (if needed)
	LDA	OLDDRV		; Restore the original drive
	CALL	RECDRX
	LDA	OLDUSR		; Restore the original number
	CALL	RECARE
	LXI	D,TBUF		; Reset to default DMA address
	MVI	C,SETDMA
	CALL	BDOS
	LDA	OPTSAV		; If so check option flag
	CPI	'R'		; Was it 'R' for receive
	JNZ	EXIT1		; If not, then skip this,
	CALL	ILPRT		; And print
	DB	CR,LF,'Thanks for the upload',CR,LF,0
;
	 IF	SYSNEW
	CALL	ILPRT
	DB	CR,LF,'(Upload set as SYS file and cannot be examined'
	DB	CR,LF,'or downloaded until released by the SYSOP....)'
	DB	CR,LF,0
	 ENDIF
;
	 IF	B3RTC AND NOT (MBMXT OR	BYEBDOS)
	CALL	ILPRT		; And print
	DB	CR,LF,'Time online is not increased during uploads'
	DB	CR,LF,0
	 ENDIF
;
	 IF	MBFMSG
	LDA	MSGFLG		; Was this a "XMODEM RM" upload?
	ORA	A
	JZ	NOTMSG
	CALL	BYECHK
	JNZ	EXIT1
	CALL	ILPRT
	DB	CR,LF
	DB	'Loading MFMSG for message input, please stand by...'
	DB	CR,LF,LF,0
	LXI	D,81H		; Our buffer starts at 81H
	MVI	C,0		; C=# of characters (stuff at 80H)
	CALL	MBDFIL
	STA	80H		; Save # of chars in 80H
	MVI	A,0C2H		; Stuff C2H (JNZ instruction)
	STA	0000H
	ORA	A		; Make sure NZ flag set so JNZ will jump
	JMP	0000H
;
NOTMSG:	 ENDIF	; MBFMSG
;
	 IF	MBFMSG AND NOT MBDESC
	JMP	EXIT1		; If not message upload, exit
	 ENDIF
;
;-----------------------------------------------------------------------
;
	 IF	MBDESC AND ZCPR2 AND (NOT ASKSYS)
	LDA	WHEEL		; If its the Sysop, don't ask
	ORA	A		; For a description because he
	JNZ	EXIT1		; Might want to batch recv files
	 ENDIF
;
	 IF	MBDESC AND NDESC
	LDA	NDSCFL		; If user picked "N" option
	ORA	A		; allow them to skip upload
	JNZ	EXIT1		; descript
	 ENDIF
;
	 IF	MBDESC
	CALL	BYECHK
	JNZ	EXIT1
	CALL	ILPRT
	DB	CR,LF
	DB	'Loading MBBS for upload description, '
	DB	'please stand by...',CR,LF,LF,0
	 ENDIF
;
	 IF	MBDESC AND NEWPRV
	MVI	A,'P'		; ALL "NEW UPLOADS:" private to start
	 ENDIF
;
	 IF	MBDESC AND NOT NEWPRV
	LDA	PRVTFL		; 80H=0 if public, "P" if private
	 ENDIF
;
	 IF	MBDESC
	STA	80H		; Stuff "private" flag in page zero
	LXI	D,82H		; Our buffer starts at 82H
	MVI	C,0		; C=# of characters (stuff at 81H)
	LXI	H,MBDSH		; Heading ("NEW UPLOAD: ")
;
MBDSHP:	MOV	A,M
	CPI	0
	JZ	MBDFS
	CALL	MBDPUT
	INX	H
	JMP	MBDSHP
;
MBDFS:	CALL	MBDFIL
	STA	81H		; Save # of chars in 81H
	MVI	A,0CAH		; Stuff CAH (JZ instruction)
	STA	0000H
	XRA	A		; Make sure Z flag set so JZ will jump
	JMP	0000H
;
MBDSH:	DB	'NEW UPLOAD: ',0 ; Heading stuffed ahead of filename
	 ENDIF	; MBDESC
;
	 IF	MBDESC OR MBFMSG
MBDFIL:	LDA	FCB		; Get drive code
	ORA	A		; Check it
	JNZ	MWDRV		; If auto login, use it
	LDA	DSKSAV		; Else, get current disk
	INR	A
;
MWDRV:	ADI	'A'-1
	CALL	MBDPUT		; Stuff in command line buffer
	LDA	USRSAV		; Get user #
	CPI	10		; Are we 0-9 or above?
	JC	US0		; Must be 0-9
	ORA	A		; Clear flags
	DAA			; Decimal adjust
	RAR			; Shift down tens digit
	RAR
	RAR
	RAR
	ANI	0FH		; Mask out tens digit
	ADI	'0'		; Make it ASCII
	CALL	MBDPUT
	LDA	USRSAV
	ORA	A		; Clear flags
	DAA			; Decimal adjust
	ANI	0FH		; Mask out singles digit
;
US0:	ADI	'0'		; Make it ASCII
	CALL	MBDPUT
	MVI	A,':'		; Put in a colon
	CALL	MBDPUT
	LXI	H,FCB+1		; Stuff in filename without spaces
	MVI	B,8
;
DESNM:	MOV	A,M
	CPI	' '
	CNZ	MBDPUT
	INX	H
	DCR	B
	JNZ	DESNM
	MVI	A,'.'
	CALL	MBDPUT
	MVI	B,3
;
DESNM3:	MOV	A,M
	CPI	' '
	JZ	DESGO
	CPI	0
	JZ	DESGO
	CALL	MBDPUT
	INX	H
	DCR	B
	JNZ	DESNM3
;
DESGO:	MOV	A,C
	RET
;
MBDPUT:	ANI	7FH		; Strip off any high bits
	STAX	D		; Short routine to stuff A in (DE) and
	INX	D		; Increment pointer and character count
	INR	C
	RET
	 ENDIF	; MBDESC OR MBFMSG
;
;-----------------------------------------------------------------------
;
EXIT1:	 IF	(TIMEON	OR B3TOS) AND (NOT LUXMOD) AND TOSEXIT
	CALL	TIME		; Tell user how long he's been on
	 ENDIF
;
	 IF	(BYEBDOS AND (NOT TIMEON)) AND TOSEXIT AND (NOT	LUXMOD)
	MVI	C,BDPTOS	; Print time on system
	CALL	BDOS
	 ENDIF
;
EXIT2:	XRA	A
	LHLD	STACK
	SPHL
	RET
;
; Check local console status in order to let BYE function keys work in
; MBYE and possibly other BYE versions also.  (Your BYE must check for
; console function keys in MSTAT.)
;
	 IF	CONFUN
FUNCHK:	PUSH	B		; Save everything
	PUSH	D		; (to be safe)
	PUSH	H
	PUSH	PSW
;
CONCHK:	CALL	0000H		; Address patched in by START
;
	 ENDIF
;
	 IF	CONFUN AND SYSABT
	ORA	A		; If SYSABT set, check for
	JZ	CONDNE		; CANCEL (^X) typed by sysop
	MVI	C,RDCON
	CALL	BDOS
	CPI	CAN
	JNZ	CONDNE
	STA	SYSABF
	 ENDIF
;
CONDNE:
	 IF	CONFUN
	POP	PSW		; For BIOS JMP CONSTAT
	POP	H
	POP	D
	POP	B		; Restore everything
	RET			; And return
	 ENDIF
;
; Get Disk and User from DUSAVE and log in if valid.
;
GETDU:	CALL	CHKFSP		; See if a file name is included
	SHLD	SAVEHL		; Save location of the filename
	LDA	PRVTFL		; Uploading to a private area?
	ORA	A
	JNZ	TRAP		; If yes, going to a specified area
	LXI	H,DUSAVE	; Point to drive/user
	LDA	OLDDRV		; Get current drive
	STA	DUD
	ADI	'A'
	STA	RCVDRV
	MOV	A,M		; Get 1st character
	CPI	'0'
	JC	GETDU1
	CPI	'9'+1
	JC	NUMER1
;
GETDU1:	STA	RCVDRV		; Allows SYSOP to upload to any drive
	CPI	'A'-1
	JC	NUMER		; Satisfied with current drive
	SUI	'A'
	STA	DUD
;
	 IF	ZCPR2
	LDA	WHEEL		; SYSOP using the system?
	ORA	A
	LDA	DUD		; Get the value back (flags stay)
	JNZ	GETDU2		; If sysop, all things are possible
	 ENDIF
;
	 IF	NOT USEMAX
	CPI	MAXDRV
	JNC	ILLDU		; Drive selection not available
	 ENDIF
;
	 IF	USEMAX
	PUSH	H
	LXI	H,DRIVMAX	; Point to max drive byte
	INR	M
	CMP	M		; And check it
	PUSH	PSW		; Save flags from the CMP
	DCR	M		; Restore max drive to normal
	POP	PSW		; Restore flags from the CPM
	JNC	ILLDU
	POP	H
	 ENDIF
;
GETDU2:	INX	H		; Get 2nd character
;
NUMER:	MOV	A,M
	CPI	':'
	JZ	OK4		; Colon for drive only, no user number
	CALL	CKNUM		; Check if numeric
;
NUMER1:	SUI	'0'		; Convert ASCII to binary
	STA	DUU		; Save it
	INX	H		; Get 3rd character if any
	MOV	A,M
	CPI	':'
	JZ	OK1
	LDA	DUU
	CPI	1		; Is first number a '1'?
	JNZ	ILLDU
	MOV	A,M
	CALL	CKNUM
	SUI	'0'-10
	STA	DUU
	INX	H		; Get 4th (and last character) if any
	MOV	A,M
	CPI	':'
	JNZ	ILLDU
;
OK1:	LDA	OPTSAV		; Get the option back
	CPI	'R'		; Receiving a file?
	LDA	DUU		; Get desired user area
	JZ	OK2		; Yes, can not use special download area
	LDA	DUD		; Get desired drive
	CPI	SPLDRV-'A'	; Special download drive requested?
	LDA	DUU		; Get user area requested
	JNZ	OK2		; If none, exit
	CPI	SPLUSR		; Special download area requested?
	JZ	OK3		; If yes, process request
;
OK2:	 IF	ZCPR2
	LDA	WHEEL		; SYSOP using the system?
	ORA	A
	LDA	DUU		; Restore desired user area
	STA	RCVUSR		; Allows SYSOP to upload anywhere
	JNZ	OK3		; If yes, let him have all user areas
	 ENDIF
;
	 IF	NOT USEMAX
	CPI	MAXUSR+1	; Check for maximum user download area
	JNC	ILLDU		; Error if more (and not special area)
	 ENDIF
;
	 IF	USEMAX
	PUSH	H
	LXI	H,USRMAX	; Point at maximum user byte
	CMP	M		; And check it
	JNC	ILLDU
	POP	H
	 ENDIF
;
OK3:	MOV	E,A
;
	 IF	NOT SETAREA
	STA	NOTUSR+1	; Store requested user area
	MVI	A,3EH		; 'MVI A,--' instruction
	STA	NOTUSR
	 ENDIF
;
	MVI	C,SETUSR
	CALL	BDOS		; Set to requested user area
;
OK4:	LDA	DUD		; Get drive
	MOV	E,A
;
	 IF	NOT SETAREA
	ADI	'A'
	STA	NOTDRV+1	; Store requested drive
	MVI	A,3EH		; 'MVI A,--' instruction
	STA	NOTDRV
	 ENDIF
;
	MVI	C,SELDSK
	CALL	BDOS		; Set to requested drive
;
XIT:	JMP	TRAP		; Now find file selected
;
; Shows available space on upload disk/area.  Uses KDRV data area which
; must be loaded before calling this routine.  (So KSHOW will work with
; user specified disk if SETAREA equate is not set YES.)
;
; Print the free space remaining for the received file
;
CPMVER	EQU	0CH
CURDPB	EQU	1FH
GALLOC	EQU	1BH
SELDSK	EQU	0EH
GETFRE	EQU	46
;
KDRV:	DB	0		; Drive stored here before calling KSHOW
;
KSHOW:	LDA	KDRV		; Get drive ('A','B','C',etc.)
	SUI	41H		; Convert to numeric (0,1,2,etc.)
	MOV	E,A		; Stuff in E for BDOS call
	MVI	C,SELDSK	; Select the directory drive to retrieve
	CALL	BDOS		; The proper allocation vector
	MVI	C,CURDPB	; It's 2.X or MP/M...request DPB
	CALL	BDOS
	INX	H
	INX	H
	MOV	A,M		; Get block shift
	STA	BLKSHF
	INX	H		; Bump to block mask
	MOV	A,M
	INX	H
	INX	H
	MOV	E,M		; Get max block #
	INX	H
	MOV	D,M
	XCHG
	SHLD	BLKMAX		; Save it
	XCHG
	INX	H
	MOV	E,M		; Get directory size
	INX	H
	MOV	D,M
	XCHG
;
; Calculate # of K free on selected drive
;
	MVI	C,CPMVER	; Get CP/M version number
	CALL	BDOS
	MOV	A,L		; Get returned version number
	CPI	30H		; 3.0?
	JC	FREE20		; Use old method if not
	LDA	KDRV		; Get drive #
	SBI	'A'		; Change from ASCII to binary
	MOV	E,A		; Use new Compute Free Space BDOS call
	MVI	C,GETFRE
	CALL	BDOS
	MVI	C,3		; Answer is a 24-bit integer
;
FRE3L1:	LXI	H,80H+2		; Answer is in 1st 3 bytes of DMA adr
	MVI	B,3		; Convert it from sectors to K
	ORA	A		; By dividing by 8
;
FRE3L2:	MOV	A,M
	RAR
	MOV	M,A
	DCX	H
	DCR	B
	JNZ	FRE3L2		; Loop for 3 bytes
	DCR	C
	JNZ	FRE3L1		; Shift 3 times
	LHLD	80H		; Now get result in K
	JMP	SAVFRE		; Go store it
;
FREE20:	MVI	C,GALLOC	; Get address of allocation vector
	CALL	BDOS
	XCHG
	LHLD	BLKMAX		; Get its length
	INX	H
	LXI	B,0		; Init block count to 0
;
GSPBYT:	PUSH	D		; Save alloc address
	LDAX	D
	MVI	E,8		; Set to process 8 blocks
;
GSPLUP:	RAL			; Test bit
	JC	NOTFRE
	INX	B
;
NOTFRE:	MOV	D,A		; Save bits
	DCX	H		; Count down blocks
	MOV	A,L
	ORA	H
	JZ	ENDALC		; Quit if out of blocks
	MOV	A,D		; Restore bits
	DCR	E		; Count down 8 bits
	JNZ	GSPLUP		; Do another bit
	POP	D		; Bump to next byte..
	INX	D		; Of alloc. vector
	JMP	GSPBYT		; Process it
;
ENDALC:	POP	D		; Clear stack of allocation vector ptr.
	MOV	L,C		; Copy block to HL
	MOV	H,B
	LDA	BLKSHF		; Get block shift factor
	SUI	3		; Convert from sectors to K
	JZ	SAVFRE		; Skip shifts if 1K blocks...
;				; Return free in HL
FREKLP:	DAD	H		; Multiply blocks by K/BLK
	DCR	A
	JNZ	FREKLP
;
; Print the amount of free space remaining on the selected drive
;
SAVFRE:	CALL	DECOUT
	CALL	ILPRT
	DB	'k available for uploads',0
	RET
;
; Log into drive and user (if specified).  If none mentioned, it falls
; through to 'TRAP' routine for normal use.
;
LOGDU:	LXI	H,TBUF		; Point to default buffer command line
	MOV	B,M		; Store number of characters in command
	INR	B		; Add in current location
;
LOG1:	CALL	CHKSP		; Skip spaces to find 1st command
	JZ	LOG1
;
LOG2:	CALL	CHKSP		; Skip 1st command (non-spaces)
	JNZ	LOG2
	INX	H
	CALL	CHKFSP		; Skip spaces to find 2nd command
	SHLD	SAVEHL		; Save start address of the 2nd command
;
; Now point to the first byte in the argument, i.e., if it was of format
; similar to:  B6:HELLO.DOC then we point at the drive character 'B'.
;
	LXI	D,DUSAVE
	MVI	C,4		; Drive/user is 4 characters maximum
;
CPLP:	MOV	A,M
	CPI	' '+1		; Space or return, finished
	JC	TRAP
	STAX	D
	INX	H
	INX	D
	CPI	':'
	JZ	GETDU		; If colon, get drive/user and log in
	DCR	B		; One less position to check
	DCR	C		; One less to go
	JNZ	CPLP
;
; Check for no file name or ambiguous name
;
TRAP:	CALL	MOVEFCB		; Move the filename into the file block
	LXI	H,FCB+1		; Point to file name
	MOV	A,M		; Get first character of file name
	CPI	' '		; Any there?
	JNZ	ATRAP		; Yes, check for ambigous file name
;
NFN:	CALL	ERXIT		; Print message, exit
	DB	'++ No file name requested ++$'
;
ATRAP:	MVI	B,11		; 11 characters to check
;
TRLOOP:	MOV	A,M		; Get char from FCB
	CPI	'?'		; Ambiguous?
	JZ	TRERR		; Yes, exit with error message
	CPI	'*'		; Even more ambiguous?
	JZ	TRERR		; Yes, exit with error message
	INX	H		; Point to next character
	DCR	B		; One less to go
	JNZ	TRLOOP		; Not done, check some more
	RET
;
TRERR:	CALL	ERXIT		; Print message, exit
	DB	'++ Wild-card options are not valid ++$'
;
CKNUM:	CPI	'0'
	JC	ILLDU		; Error if less than ascii '0'
	CPI	'9'+1
	RC			; Error if more than ascii '9'
;
ILLDU:	CALL	ERXIT
	DB	'++ Improper drive/user combination ++$'
;
; Receive a record - returns with carry bit set if EOT received
;
RCVRECD:XRA	A		; Initialize error count to zero
	STA	ERRCT
;	
; [WBW] BEGIN: Be more patient waiting for host to start sending file
	LDA	FRSTIM		; Get first time flag
	ORA	A		; Set CPU flags
	JNZ	RCVRPT		; If not first time, bypass
	MVI	A,-10		; Else increase error limit
	STA	ERRCT		; Save error new limit
; [WBW] END
;
RCVRPT:	 IF	CONFUN		; Check for function key?
	CALL	FUNCHK		; Yeah, why not?
	 ENDIF
;
	 IF	CONFUN AND SYSABT
	LDA	SYSABF		; If SYSABT option, check
	ORA	A		; to see if Abort
	JNZ	RCVSABT		; If so, bail out now...
	 ENDIF
;
	;MVI	B,10-1		; 10-second timeout
	MVI	B,5-1		; [WBW] 5-second timeout
	CALL	RECV		; Get any character received
	JC	RCVSTOT		; Timeout
;
RCVRPTB:CPI	SOH		; 'SOH' for a 128-byte block?
	JZ	RCVSOH		; Yes
	CPI	STX		; A 1024-byte block?
	JZ	RCVSTX		;
	ORA	A		;
	JZ	RCVRPT		; Ignore nulls
	CPI	CRC		; Ignore our own 'CRC' if needed
	JZ	RCVRPT
	CPI	NAK		; Ignore our own 'NAK' if needed
	JZ	RCVRPT
	CPI	CAN		; CANcel?
	JZ	CANRCV		; (look for CAN CAN)
	CPI	EOT		; End of transfer?
	STC			; Return with carry set if 'EOT'
	RZ
;
; Didn't get SOH or EOT - or - didn't get valid header - purge the line,
; then send nak
;
RCVSERR:MVI	B,1		; Wait for 1 second
	CALL	RECV		; After last char. received
	JNC	RCVSERR		; Loop until sender done
RCVSER1:LDA	FRSTIM		; Is it the first time?
	ORA	A
	MVI	A,NAK
	JNZ	RCVSER2		; If not first time, send NAK
;
; First time through...do crc/1k/checksum select
;
	LDA	CRCFLG		; Get 'CRC' flag
	ORA	A		; 'CRC' in effect?
	MVI	A,NAK		; Put 'NAK' in accum
	JNZ	RCVSER2		; And go send it
	MVI	A,CRC		; Tell sender 'CRC' is in effect
	CALL	SEND
	LDA	KFLAG		; Did we want 1k protocol?
	ORA	A
	JZ	RCVSERX		; No, just send the "C"
	MVI	A,'K'		; Else send a C and a K
;
RCVSER2:CALL	SEND		; The 'NAK' or 'CRC' request
;
RCVSERX:LDA	ERRCT		; Abort if
	INR	A		; We have reached
	STA	ERRCT		; The error
	CPI	10		; Limit?
	JZ	RCVSABT		; Yes, abort
	CPI	5		; Have we tried 5 times already?
	JNZ	RCVRPT		; No, try again with same mode
	MVI	A,'C'		; Else flip to checksum mode if CRC
	STA	CRCFLG
	JMP	RCVRPT		; And try again
;
; Error limit exceeded, so abort
;
CANRCV:	CALL	DELAY		; Wait 100ms
	CALL	RCVRDY		; Character waiting?
	JZ	RCVRPT		; If so, no pause, skip CANcel
	MVI	B,4
	CALL	RECV		; Else wait for 2nd character
	JC	RCVSERR		; If no second character received, error
	CPI	CAN
	JNZ	RCVRPTB		; If second character not CAN, check it
;
RCVSABT:CALL	CLOSFIL		; Close file
	CALL	ILPRT
	DB	CR,LF,CR,LF,'++ Receive cancelled ++',0
	CALL	DELFILE		; Delete received file
	CALL	ERXIT		; Print second half of message
	DB	'++ Partial file deleted ++$'
;
; Deletes the received file (used if receive aborts)
;
DELFILE:LXI	D,FCB		; Point to file
	MVI	C,DELET		; Get function
	CALL	BDOS		; Delete it
	INR	A		; Delete ok?
	RNZ			; Yes, return
	CALL	ERXIT		; No, abort
	DB	'++ Can''t delete received file ++$'
;
; Timed out on receive
;
;RCVSTOT:JMP	RCVSERR		; Bump error count, etc.
; [WBW] Bypass line flush if error is timeout
RCVSTOT:JMP	RCVSER1		; Bump error count, etc.
;
; Got SOH or STX - get block number, block number complemented
;
RCVSOH:	LXI	H,128		; 128 bytes in this block
	XRA	A		; Zero-out KFLAG
	JMP	RCVHDR
;		;
RCVSTX:	MVI	A,0FFH		; Set KFLAG true
	LXI	H,1024		; 1024 bytes in block
;
RCVHDR:	SHLD	BLKSIZ		; Store block size for later
	STA	KFLAG		; Set KFLAG as appropriate
	MVI	B,1		; Timeout = 1 sec
	MVI	A,1		; Need something to store at FRSTIM
	STA	FRSTIM		; Indicate first 'SOH' received
	CALL	RECV		; Get record
	JC	RCVSTOT		; Got timeout
	MOV	D,A		; D=block number
	MVI	B,1		; Timeout = 1 sec
	CALL	RECV		; Get complimented record number
	JC	RCVSTOT		; Timeout
	CMA			; Calculate the  complement
	CMP	D		; Good record number?
	JZ	RCVDATA		; Yes, get data
;
; Got bad record number
;
	JMP	RCVSERR		; Bump error count
;
RCVDATA:MOV	A,D		; Get record number
	STA	RCVRNO		; Save it
	MVI	C,0		; Initialize checksum
	CALL	CLRCRC		; Clear CRC counter
	LHLD	BLKSIZ		; Get block size,
	XCHG			; And put in DE pair to initialize count
	LHLD	RECPTR		; Get buffer address
;
RCVCHR:	MVI	B,1		; 1 sec timeout
	CALL	RECV		; Get the character
	JC	RCVSTOT		; Timeout
	MOV	M,A		; Store the character
	INX	H		; Point to next character
	DCX	D		; Done?
	MOV	A,D
	ORA	E
	JNZ	RCVCHR		; No, loop if <= BLKSIZ
	LDA	CRCFLG		; Get 'CRC' flag
	ORA	A		; 'CRC' in effect?
	JZ	RCVCRC		; Yes, to receive 'CRC'
;
; Verify checksum
;
	MOV	D,C		; Save checksum
	MVI	B,1		; Timeout length
	CALL	RECV		; Get checksum
	JC	RCVSTOT		; Timeout
	CMP	D		; Checksum ok?
	JNZ	RCVSERR		; No, error
;
; Got a record, it's a duplicate if = previous, or OK if = 1 + previous
; record.
;
CHKSNUM:LDA	RCVRNO		; Get received
	MOV	B,A		; Save it
	LDA	RECDNO		; Get previous
	CMP	B		; Prev repeated?
	JZ	RECVACK		; 'ACK' to catch up
	INR	A		; Calculate next record number
	CMP	B		; Match?
	JNZ	ABORT		; No match - stop sender, exit
	RET			; Carry off - no errors
;
; Receive the Cyclic Redundancy Check characters (2 bytes) and see if
; the CRC received matches the one calculated.	If they match, get next
; record, else send a NAK requesting the record be sent again.
;
RCVCRC:	MVI	E,2		; Number of bytes to receive
;
RCVCRC2:MVI	B,1		; 1 sececond timeout
	CALL	RECV		; Get crc byte
	JC	RCVSTOT		; Timeout
	DCR	E		; Decrement the number of bytes
	JNZ	RCVCRC2		; Get both bytes
	CALL	CHKCRC		; Check received CRC against calc'd CRC
	ORA	A		; Is CRC okay?
	JZ	CHKSNUM		; Yes, go check record numbers
	JMP	RCVSERR		; Go check error limit and send NAK
;
; Previous record repeated, due to the last ACK being garbaged.  ACK it
; so sender will catch up
;
RECVACK:CALL	SENDACK		; Send the ACK
	JMP	RCVRECD		; Get next block
;
; Send an ACK for the record
;
SENDACK:MVI	A,ACK		; Get 'ACK'
	CALL	SEND		; And send it
	RET
;
; Send the record header
;
; Send	[(SOH) or (STX)] (block number) (complemented block number)
;
SENDHDR:LDA	KFLAG		; 1k blocks enabled?
	ORA	A
	JNZ	SENDBIG		; Yes
	MVI	A,SOH		; 128 blocks, use SOH
	JMP	MORHDR		; Send it
;
SENDBIG:MVI	A,STX		; 1024 byte block -  Start of Header
;
MORHDR:	CALL	SEND		; One Start of Header or another
	LDA	RECDNO		; Then send record number
	CALL	SEND
	LDA	RECDNO		; Then record number
	CMA			; Complemented
	CALL	SEND		; Record number
	RET			; From SENDHDR
;
; Send the data record
;
SENDREC:MVI	C,0		; Initialize checksum
	CALL	CLRCRC		; Clear the 'CRC' counter
	LDA	KFLAG		; Are we using 1K blocks?
	ORA	A
	JNZ	SEND1		; Yes, 1k size
	LXI	D,128		; Initialize small count
	JMP	SEND2
;
SEND1:	LXI	D,1024		; Initialize big count
;
SEND2:	LHLD	RECPTR		; Get buffer address
;
SENDC:	MOV	A,M		; Get a character
	CALL	SEND		; Send it
	INX	H		; Point to next character
	DCX	D		; Done?
	MOV	A,D
	ORA	E
	JNZ	SENDC		; Loop if <=Blocksize
	RET			; From SENDREC
;
; Send the checksum
;
SENDCKS:MOV	A,C		; Send the
	CALL	SEND		; Checksum
	RET			; From 'SENDCKS'
;
; Send the two Cyclic Redundancy Check characters.  Call FINCRC to cal-
; culate the CRC which will be in 'DE' upon return.
;
SENDCRC:CALL	FINCRC		; Calculate the 'CRC' for this record
	MOV	A,D		; Put first 'CRC' byte in accumulator
	CALL	SEND		; Send it
	MOV	A,E		; Put second 'CRC' byte in accumulator
	CALL	SEND		; Send it
	XRA	A		; Set zero return code
	RET
;
; Returns with carry clear if ACK received.  If an ACK is not received,
; the error count is incremented, and if less than 10, carry is set and
; the record is resent.  if the error count is 10, the program aborts.
; waits 12 seconds to avoid any collision with the receiving station.
;
GETACK:	MVI	B,10		; Wait 10 seconds max
	CALL	RECVDG		; Receive with garbage collect
	JC	ACKERR		; Timed out
	CPI	ACK		; Was it an 'ACK' character?
	RZ			; Yes, return
;
	 IF	RETRY
	CPI	NAK		; Was it an authentic 'NAK'?
	JNZ	GETACK		; Ignore if neither 'ACK' nor 'NAK'
	 ENDIF
;
; Timeout or error on ACK - bump error counters then resend the record
; if error limit is not exceeded.
;
ACKERR:	LDA	ERRCT		; Get count
	INR	A		; Bump it
	STA	ERRCT		; Save back
	LHLD	TOTERR		; Total errors this run
	INX	H
	SHLD	TOTERR		; Update and put back
	CPI	10		; At limit?
	RC			; If not, go resend the record
;
; Reached error limit
;
	CALL	ERXIT
	DB	'++ Send file cancelled ++$'
;
CHKERR:	LDA	KFLAG
	ORA	A		; Check to see if in 1024 mode
	RZ			; No, so don't bother with rest
	LHLD	TOTERR		; Check on errors to date...
	MOV	A,L		; Skip if less than DWNSHFT error so far
	CPI	DWNSHFT
	RC			; Not enough errors to bother with yet
	XCHG			; Total errors to DE
	LHLD	RECDNO		; Get records sent so far
	CALL	DVHLDE		; Divide by errors so far
	MOV	A,C		; Take low order byte of quotient...
	CPI	DWNSHFT		; Compare to specified ratio...
	RNC			; Better ratio than needed, so return
	XRA	A		; Noisy line, let's try
	STA	KFLAG		; 128 byte blocks
	RET
;
ABORT:	LXI	SP,STACK
;
ABORTL:	MVI	B,1		; One second without characters
	CALL	RECV
	JNC	ABORTL		; Loop until sender done
	MVI	A,CAN		; CTL-X
	CALL	SEND		; Stop sending end
;
ABORTW:	MVI	B,1		; One second without chracters
	CALL	RECV
	JNC	ABORTW		; Loop until sender done
	MVI	A,CR		; Get a space...
	CALL	SEND		; To clear out CTL-X
	CALL	ERXIT		; Exit with abort message
	DB	'++ XMODEM aborted ++$'
;
; Increment record number
;
INCRRNO:PUSH	H
	LHLD	RECDNO		; Increment record number
	INX	H
	SHLD	RECDNO
	LHLD	VRECNO		; Update Virtual Record Number
	LDA	KFLAG		; Was last record a 1024 byte one?
	ORA	A		;
	JZ	INCRR1		; Just handled an normal 128 byte record
	INX	H		; Otherwise, must have be a BIG one, so
	INX	H		; Seven ...
	INX	H
	INX	H
	INX	H
	INX	H
	INX	H		; Plus
;
INCRR1:	INX	H		; One
	SHLD	VRECNO		; Equals the new virtual record number
;
	 IF	NOT (USECON OR BYEBDOS)
	LHLD	CONOUT+1	; Check to see if showing count on crt
	MOV	A,H		; If both zero, user did not fill out
	ORA	L		; 'CONOUT:  jmp 0000H' in patch area
	JZ	INCRN5		; With his own console output address
	 ENDIF
;
; Display the record count on the local CRT if "CONOUT" was filled in by
; the implementor
;
	MVI	A,1
	STA	CONONL		; Set local only
	LDA	OPTSAV		; See if receive or send mode
	CPI	'R'
	JZ	RMSG
	CALL	ILPRT
	DB	CR,'Sending # ',0
	JMP	REST
;
RMSG:	CALL	ILPRT
	DB	CR,'Received # ',0
;
REST:	LDA	KFLAG
	ORA	A
	JZ	REST1
	LHLD	VRECNO
	DCX	H		; Stupid but simple way to subtract 7
	DCX	H		; Without dying on high-byte
	DCX	H
	DCX	H
	DCX	H
	DCX	H
	DCX	H
	CALL	DECOUT
	MVI	A,'-'
	CALL	CTYPE
;
REST1:	LHLD	VRECNO		; Virtual record number to minimize
	CALL	DECOUT		; Confusion between 1K and normal
	CALL	ILPRT		; 'record' sizes (always in terms of
	DB	' ',18H,0	; 128-byte records)
;
	 IF	CONFUN		; Check for sysop console function
	CALL	FUNCHK		; Keys if CONFUN EQU YES
	 ENDIF
;
INCRN5:	POP	H		; Here from above if no CONOUT
	RET
;
; See if file exists - if it exists, ask for a different name.
;
CHEKFIL: IF	NOT SETAREA
	LDA	PRVTFL		; Receiving in private area?
	ORA	A
	CNZ	RECAREA		; If yes, set drive and user area
	 ENDIF
;
	 IF	SETAREA
	CALL	RECAREA		; Set the designated area up
	 ENDIF
;
	LXI	D,FCB		; Point to control block
	MVI	C,SRCHF		; See if it
	CALL	BDOS		; Exists
	INR	A		; Found?
	RZ			; No, return
	CALL	ERXIT		; Exit, print error message
	DB	'++ File exists, use a different name ++$'
;
; Makes the file to be received
;
MAKEFIL:XRA	A		; Set extent and record number to 0
	STA	FCBEXT
	STA	FCBRNO
	LXI	D,FCB		; Point to FCB
	MVI	C,MAKE		; Get BDOS FNC
	CALL	BDOS		; To the make
	INR	A		; 0FFH=bad?
	RNZ			; Open ok
;
; Directory full - can't make file
;
	CALL	ERXIT
	DB	'++ Error: can''t make file -'
	DB	' directory may be full? ++$'
;
; Computes record count, and saves it until a successful file-open.
;
CNREC:	MVI	C,CFSIZE	; Computes file size
	LXI	D,FCB
	CALL	BDOS		; Read first
	LHLD	RANDOM		; Get the file size
	SHLD	RCNT		; Save total record count
	MOV	A,H
	ORA	L
	RNZ			; Return if not zero length
;
NONAME:	CALL	ERXIT
	DB	'++ File not found, check DIR ++','$'
;
; Opens the file to be sent
;
OPENFIL:XRA	A		; Set extent and rec number to 0
	STA	FCBEXT		; For proper open
	STA	FCBRNO
	LXI	D,FCB		; Point to file
	MVI	C,OPEN		; Get function
	CALL	BDOS		; Open it
	INR	A		; Open ok?
	JNZ	OPENOK		; If yes, exit
	LDA	OPTSAV		; Get command line option
	CPI	'L'		; Want to send a library file?
	JNZ	NONAME		; Exit, if not
	CALL	ILPRT
	DB	CR,LF,'++ Member not found, check DIR ++',CR,LF,0
	JMP	OPTERR
;
; Check to see if the SYSOP has tagged a .LBR file for NO SEND - if so,
; only allow XMODEM L NAME to transfer individual files. If requested
; file is a $SYS file or has any high bits set, disallow unless WHEEL.
;
OPENOK:	 IF	ZCPR2
	LDA	WHEEL		; Check wheel status if ZCPR2
	ORA	A		; Is it zero
	JNZ	OPENOK1		; If non-zero skip all restrictions
	 ENDIF
;
	 IF	DWNTAG
	LDA	FCB+3		; Regardless of access byte?
	ANI	80H		; If so,
	JNZ	OPENOK1		; Allow it if F3 set regardless
	 ENDIF
;
	 IF	ACCESS
	CALL	BYECHK
	JNZ	SNDFOK
	LHLD	0001H		; Get JMP COLDBOOT
	DCX	H
	MOV	D,M
	DCX	H
	MOV	E,M
	LXI	H,ACBOFF	; + ACBOFF
	DAD	D
	MOV	A,M		; = ACCESS byte address
	ANI	ACDNLD		; Test download access bit
	JNZ	SNDFOK		; If bit on, downloads OK
	CALL	ERXIT
	DB	'Sorry, but you are not allowed to download files '
	DB	'at this time...','$'
	 ENDIF
;
SNDFOK:	 IF	NOSYS AND NOT LUXMOD
	LDA	FCB+10
	ANI	80H
	JNZ	NONAME		; If $SYS then fake a "file not found"
	 ENDIF
;
	 IF	OK2400 AND TAGLBR AND NOT LUXMOD
	LDA	MSPEED		; Check baudrate byte set by BYE
	CPI	6		; Is caller >=2400 baud?
	JNC	OPENOK1		; If so - let em send the file (PAT2)
	 ENDIF
;
	 IF	TAGLBR AND NOT LUXMOD
	LDA	OPTSAV		; Has SYSOP tagged a large .LBR file?
	CPI	'L'		; Using XMODEM L?
	JZ	OPENOK1		; Yes, skip tag test
	LDA	FCB+1		; First char of file name
	ANI	80H		; Check bit 7 for tag
	JZ	OPENOK1		; If on, file cannot be sent
	 ENDIF
;
	 IF	TAGLBR AND NOT LUXMOD
OPENOT:	CALL	ERXIT		; Exit with message
	DB	'++ File is not for distribution, sorry. ++',CR,LF,CR,LF
	DB	'For large LBR files please use XMODEM L or LUX',CR,LF
	DB	'to transfer individual member files','$'
	 ENDIF
;
OPENOK1:LDA	OPTSAV
	CPI	'L'
	JNZ	OPN2
	LXI	D,TBUF
	MVI	C,SETDMA
	CALL	BDOS
	MVI	C,READ
	LXI	D,FCB
	CALL	BDOS
	ORA	A		; Read ok?
	JNZ	LERROR
	LHLD	TBUF+14		; Value in buffer where DIRSIZE is
	SHLD	DIRSZ
	LXI	H,TBUF
	MOV	A,M
	ORA	A
	JZ	CKDIR		; Check directory present?
;
NOTLBR:	CALL	ERXIT
	DB	'++ Bad .LBR directory, notify Sysop ++','$'
;
; Check to see if there is a .LBR file directory with that name and
; complain if not.
;
CKDIR:	MVI	B,11		; Maximum length of file name
	MVI	A,' '		; First entry must be all blanks
	INX	H
;
CKDLP:	CMP	M
	JNZ	NOTLBR
	DCR	B
	INX	H
	JNZ	CKDLP
;
; The first entry in the .LBR directory is indeed blank.  Now see if the
; directory size is more than 0.
;
	MOV	D,M		; Get directory starting location
	INX	H		; Which must be 0000H...
	MOV	A,M
	ORA	D
	JNZ	NOTLBR		; Directory does not start in record 0
	INX	H
	MOV	A,M		; Get size of directory
	INX	H
	ORA	M
	JZ	NOTLBR		; Directory must be >0 records!
	LXI	H,TBUF		; Point to directory
;
; The next routine checks the .LBR directory for the specified member.
; Name one sector at a time.
;
CMLP:	MOV	A,M		; Get member active flag
	ORA	A		; 00=active, anything else can be...
	MVI	B,11		; Regarded as invalid (erased or blank)
	INX	H		; Point to member name
	JNZ	NOMTCH		; No match if inactive entry
;
CKLP:	LDAX	D		; Now compare the file name specified...
	CMP	M		; Against the member file name
	JNZ	NOMTCH		; Exit loop if no match found
	INX	H
	INX	D
	DCR	B
	JNZ	CKLP		; Check all 11 characters
	MOV	E,M		; Got the file - get file address
	INX	H
	MOV	D,M
	XCHG
	SHLD	INDEX		; Save file address in .LBR
	XCHG
	INX	H
	MOV	E,M		; Get the file size
	INX	H
	MOV	D,M
	XCHG
	DCX	H
	SHLD	RCNT		; Save size a # of records
	LHLD	INDEX		; Get file address
	SHLD	RANDOM		; Place it into random field
	XRA	A
	STA	RANDOM+2	; Must zero the 3rd byte
	STA	FCBRNO		; Also zero FCB record #
	LXI	D,FCB		; Point to FCB of .LBR file
	MVI	C,RRDM		; Read random
	CALL	BDOS
	JMP	OPENOK3		; No need to error check
;
; Come here if no file name match and another sector is needed
;
NOMTCH:	INX	H		; Skip past the end of the file entry
	DCR	B
	JNZ	NOMTCH
	LXI	B,20		; Point to next file entry
	DAD	B
	LXI	D,MEMFCB	; Point to member name again
	MOV	A,H		; See if we checked all 4 entries
	ORA	A
	JZ	CMLP		; No, check next
	LHLD	DIRSZ		; Get directory size
	MOV	A,H
	ORA	L
	JNZ	INLBR		; Continue if still more to check
	CALL	ERXIT
	DB	'++ Member not found, check DIR ++$'
;
INLBR:	DCX	H		; Decrement dirctory size
	SHLD	DIRSZ
	MVI	C,READ		; Read next sector of directory
	LXI	D,FCB
	CALL	BDOS
	ORA	A		; Read ok?
	JNZ	LERROR
	LXI	H,TBUF		; Set our pointers for compare
	LXI	D,MEMFCB
	JMP	CMLP		; Check next sector
;
OPN2:	 IF	ZCPR2
	LDA	WHEEL		; Check status of wheel if zcpr2
	ORA	A		; Is it zero
	JNZ	OPENOK3		; If not then skip the # and .com check
	 ENDIF
;
	 IF	NOLBS OR NOCOMS	; Check for send restrictions
	LXI	H,FCB+11
	MOV	A,M		; Check for protect attr
	ANI	7FH		; Remove CP/M 2.x attrs
	 ENDIF
;
	 IF	NOLBS		; Do not allow '#' to be sent
	CPI	'#'		; Chk for '#' as last first
	JNZ	OPELOK		; If '#', can not send, show why
	CALL	ERXIT
	DB	'++ File not for distribution ++$'
;
OPELOK:	 ENDIF
;
	 IF	NOCOMS		; Do not allow '.COM' to be sent
	CPI	'M'		; If not, check for '.COM'
	JNZ	OPENOK3		; If not, ok to send
	DCX	H
	MOV	A,M		; Check next character
	ANI	7FH		; Strip attributes
	CPI	'O'		; 'O'?
	JNZ	OPENOK3		; If not, ok to send
	DCX	H
	MOV	A,M		; Now check 1st character
	ANI	7FH		; Strip attributes
	CPI	'C'		; 'C' as in '.COM'?
	JNZ	OPENOK3		; If not, continue
	CALL	ERXIT		; Exit with message
	DB	'++ Sending .COM files not allowed ++$'
	 ENDIF	; NOCOMS
;
OPENOK3: IF	NOT DSPFNAM
	CALL	ILPRT		; Print the message
	DB	'File open: ',0
	 ENDIF
;
	 IF	DSPFNAM
	CALL	ILPRT
	DB	'Sending: ',0
	LDA	OPTSAV
	CPI	'L'
	JNZ	SFNNL		; If not L opt, just show name
	LXI	H,MEMFCB
	CALL	DSPFN
	CALL	ILPRT
	DB	' from ',0
;
SFNNL:	LXI	H,FCB+1
	CALL	DSPFN
	CALL	ILPRT
	DB	CR,LF,'File size: ',0
	 ENDIF
;
	LHLD	RCNT		; Get record count
	LDA	OPTSAV
	CPI	'L'
	JNZ	OPENOK4		; If send from library add 1 to
	INX	H		; Show correct record count
;
OPENOK4:CALL	CKKSIZ		; Check to see if it is at least 1K...
	CALL	DECOUT		; Print decimal number of records
	PUSH	H
	CALL	ILPRT
	DB	' records (',0
	POP	H		; Get # of 128 byte records
	LXI	D,8		; Divide by 8
	CALL	DVHLDE		; To get # of 1024 byte blocks
	MOV	A,H
	ORA	L		; Check if remainder
	MOV	H,B		; Get quotient
	MOV	L,C
	JZ	EXKB		; If 0 remainder, exact kilobytes
	INX	H		; Else, increment to next k
;
EXKB:	CALL	DECOUT		; Show # of kilobytes
	CALL	ILPRT
	DB	'k)',CR,LF,0
	CALL	ILPRT
	DB	'Send time: ',0
	CALL	FILTIM		; Get file xfer time in mins in BC
	PUSH	H		; Save seconds in HL
;
	 IF	ZCPR2 AND MAXTIM
	LDA	WHEEL		; Check wheel status if zcpr2
	ORA	A		; Is it zero
	JNZ	SKIPTIM		; If its not then skip the limit
	 ENDIF
;
	 IF	OK2400		; No restrictions for 2400 bps callers?
	LDA	MSPEED		; Check baudrate byte set by BYE
	CPI	6		; Is >=2400?
	JNC	SKIPTIM		; If so, skip time check
	 ENDIF
;
	 IF	MAXTIM
	MOV	A,C		; If limiting get length of this program
	INR	A		; Increment to next full minute
	 ENDIF
;
	 IF	MAXTIM AND TIMEON
	LXI	H,TON
	ADD	M		; Add time on to xfer time, TON will
	 ENDIF
;
	 IF	MAXTIM
	STA	MINUTE		; Store value for later comparison
	MOV	A,B		; Get high byte of minute if >255
	JNZ	MXTMC2		; If no carry from increment/add
	INR	A
;
MXTMC2:	STA	MINUTE+1
	 ENDIF
;
SKIPTIM:MOV	L,C
	MOV	H,B
	CALL	DECOUT		; Print decimal number of minutes
	MVI	A,':'
	CALL	CTYPE		; Output colon
	POP	H		; Get seconds
	MOV	A,L
	CPI	10
	MVI	A,'0'		; Needs a leading zero
	CC	CTYPE
	CALL	DECOUT		; Print the seconds portion
	CALL	ILPRT
	DB	' at ',0
	LXI	H,SPTBL		; Start of baud rate speeds
	MVI	D,0		; Zero the 'D' register
	CALL	SPEED		; Get speed indicator
	ADD	A		; Index into the baud rate table
	ADD	A
	MOV	E,A		; Now have the index factor in 'DE'
	DAD	D		; Add to 'HL'
	XCHG			; Put address in 'DE' regs.
	MVI	C,PRINT		; Show the baud
	CALL	BDOS
	CALL	SPEED
	CPI	5
	MVI	A,'0'		; Adds a zero for 1200, 2400, 4800 and
	CNC	CTYPE		; 9600 bps
;
OPENOK5:CALL	ILPRT
	DB	' baud',CR,LF,0
;
	 IF	ZCPR2 AND MAXTIM
	LDA	WHEEL		; Check wheel status if zcpr2
	ORA	A		; Is it zero
	JNZ	SKIPEM		; If not then no time limits
	 ENDIF
;
	 IF	MAXTIM AND (BYEBDOS OR MXTOS)
	LDA	MAXTOS		; Get maximum time on system
	ORA	A		; If zero, this guy is a winner
	JZ	SKIPEM		; (skip restrictions)
	LDA	MINUTE+1	; Is it over 255 minutes?
	ORA	A
	JNZ	OVERTM
	 ENDIF
;
	 IF	MTL
	CALL	GETTOS		; Get time on system in HL
	 ENDIF
;
	 IF	MAXTIM AND BYEBDOS AND (NOT TIMEON)
	MVI	C,BDGRTC	; Get time on system in A
	CALL	BDOS
	MOV	B,A		; Put in B
	 ENDIF
;
	 IF	MAXTIM AND (BYEBDOS OR MXTOS)
	LDA	MAXTOS
	INR	A
	 ENDIF
;
	 IF	MAXTIM AND BYEBDOS AND (NOT TIMEON)
	SUB	B
	 ENDIF
;
	 IF	MTL
	SUB	L		; Get how much time is left
	ADI	MAXMIN		; Give them MAXMIN extra
	 ENDIF
;
	 IF	MAXTIM AND (BYEBDOS OR MXTOS)
	MOV	B,A		; Put max time on sys in B
	LDA	MINUTE		; Are we > max time on sys?
	CMP	B
	JNC	OVERTM
	 ENDIF
;
	 IF	MAXTIM AND NOT (BYEBDOS	OR MXTOS)
	LDA	MINUTE+1	; Get minute count high byte
	ORA	A		; Check if zero
	JNZ	OVERTM		; If not, is over 255 minutes!
	LDA	MINUTE		; Get minute count
	CPI	MAXMIN+1	; Compare to MAXTIM value
	JNC	OVERTM		; If greater than MAXTIM
	 ENDIF
;
SKIPEM:	CALL	ILPRT
	DB	'To cancel: Ctrl-X, pause, Ctrl-X',CR,LF,0
	RET
;
	 IF	MAXTIM
OVERTM:	CALL	ILPRT
	DB	CR,LF,'++ XMODEM ABORTED - send time exceeds the ',0
	 ENDIF
;
	 IF	MAXTIM AND NOT (BYEBDOS	OR MXTOS)
	LXI	H,MAXMIN
	 ENDIF
;
	 IF	MAXTIM AND BYEBDOS
	MVI	C,BDGRTC
	CALL	BDOS
	MOV	B,A
	 ENDIF
;
	 IF	MTL
	CALL	GETTOS		; Get TOS back into HL
	 ENDIF
;
	 IF	MAXTIM AND (BYEBDOS OR MXTOS)
	LDA	MAXTOS
	 ENDIF
;
	 IF	MAXTIM AND BYEBDOS
	SUB	B
	 ENDIF
;
	 IF	MTL
	SUB	L		; Get time left
	ADI	MAXMIN		; Add MAXMIN
	 ENDIF
;
	 IF	MAXTIM AND (BYEBDOS OR MXTOS)
	MVI	H,0
	MOV	L,A
	 ENDIF
;
	 IF	MAXTIM
	CALL	DECOUT
	CALL	ERXIT1
	DB	' minutes allowed ++$'
	 ENDIF
;
BTABLE:	 IF	NOT STOPBIT	; One stop bit
	DW	5,13,19,25,30,48,85,141,210,280,0
	 ENDIF
;
	 IF	STOPBIT		; Two stop bits
	DW	5,12,18,23,27,44,78,128,191,255,0
	 ENDIF
;
KTABLE:	 IF	NOT STOPBIT	; One stop bit
	DW	5,14,21,27,32,53,101,190,330,525,0
	 ENDIF
;
	 IF	STOPBIT		; Two stop bits
	DW	5,13,19,25,29,48,92,173,300,477,0
	 ENDIF
;
RECTBL:	 IF	NOT STOPBIT	; One stop bit
	DB	192,74,51,38,32,20,11,8,5,3,0
	 ENDIF
;
	 IF	STOPBIT		; Two stop bits
	DB	192,80,53,42,36,22,12,7,5,4,0
	 ENDIF
;
KECTBL:	 IF	NOT STOPBIT	; One stop bit
	DB	192,69,46,36,30,18,10,5,3,2,0
	 ENDIF
;
	 IF	STOPBIT		; Two stop bits
	DB	192,74,51,38,33,20,10,6,3,2,0
	 ENDIF
;
SPTBL:	DB	'110$','300$','450$','600$','710$','120$','240$'
	DB	'480$','960$','1920$'
;
; Pass record count in RCNT: returns file's approximate download/upload
; time in minutes in BC, seconds in HL, also stuffs the # of mins/secs
; values in PGSIZE if LOGCAL is YES.
;
FILTIM:	CALL	SPEED		; Get speed indicator
	MVI	D,0
	MOV	E,A		; Set up for table access
	LXI	H,BTABLE	; Point to baud factor table
	LDA	KFLAG
	CPI	'K'
	JNZ	FILTI1
	LXI	H,KTABLE	; The guy is using 1k file xfers
;
FILTI1:	DAD	D		; Index to proper factor
	DAD	D
	MOV	E,M
	INX	H
	MOV	D,M
	LHLD	RCNT		; Get number of records
	LDA	OPTSAV
	CPI	'L'		; If not L download
	JNZ	SKINCR		; Skip increment of record count
	INX	H		; Increment record count
;
SKINCR:	CALL	DVHLDE		; Divide HL by value in DE (records/min)
	PUSH	H		; Save remainder
	LXI	H,RECTBL	; Point to divisors for seconds calc.
	LDA	KFLAG
	CPI	'K'
	JNZ	FILTI2
	LXI	H,KECTBL	; The guy is using 1k file transfers
;
FILTI2:	MVI	D,0
	CALL	SPEED		; Get speed indicator
	MOV	E,A
	DAD	D		; Index into table
	MOV	A,M		; Get multiplier
	POP	H		; Get remainder
	CALL	MULHLA		; Multiply 'H' by 'A'
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	MVI	H,0		; HL now = seconds (L=secs,H=0)
;
	 IF	LOGCAL
	MOV	A,C		; Add minutes of length (to 0 or 1)
	STA	PGSIZE		; Save as LSB of minutes
	MOV	A,B		; Get MSB of minutes
	STA	PGSIZE+1	; Save as MSB of minutes (>255?)
	MOV	A,L		; Get LSB of seconds (can't be >59)
	STA	PGSIZE+2	; Save for LOGCALL
	 ENDIF
;
	RET			; End of FILTIM routine
;
; Divides 'HL' by value in 'DE' - upon exit: BC=quotient, HL=remainder
;
DVHLDE:	PUSH	D		; Save divisor
	MOV	A,E
	CMA			; Negate divisor
	MOV	E,A
	MOV	A,D
	CMA
	MOV	D,A
	INX	D		; 'DE' is now two's complemented
	LXI	B,0		; Init quotient
;
DIVL1:	DAD	D		; Subtract divisor from divident
	INX	B		; Bump quotient
	JC	DIVL1		; Loop until sign changes
	DCX	B		; Adjust quotient
	POP	D		; Retrieve divisor
	DAD	D		; Readjust remainder
	RET
;
; Multiply the value in 'HL' by the value in 'A', return with answer in
; 'HL'.
;
MULHLA:	XCHG			; Multiplicand to 'DE'
	LXI	H,0		; Init product
	INR	A
;
MULLP:	DCR	A
	RZ
	DAD	D
	JMP	MULLP
;
; Shift the 'HL' register pair one bit to the right
;
SHFTHL:	MOV	A,L
	RAR
	MOV	L,A
	ORA	A		; Clear the carry bit
	MOV	A,H
	RAR
	MOV	H,A
	RNC
	MVI	A,128
	ORA	L
	MOV	L,A
	RET
;
; Closes the received file
;
CLOSFIL:LXI	D,FCB		; Point to file
	MVI	C,CLOSE		; Get function
	CALL	BDOS		; Close it
	INR	A		; Close ok?
	JNZ	CLSEXIT		; Yes, continue
	CALL	ERXIT		; No, abort
	DB	'++ Can''t close file ++$'
;
CLSEXIT:
	 IF	SYSNEW
	LDA	FCB+10		; Set $SYS attribute
	ORI	80H
	STA	FCB+10
	LXI	D,FCB		; Point to file
	MVI	C,SETATT	; Set attribute function
	CALL	BDOS
	 ENDIF
;
	RET
;
; Decimal output routine - call with decimal value in 'HL'
;
DECOUT:	PUSH	B
	PUSH	D
	PUSH	H
	LXI	B,-10
	LXI	D,-1
;
DECOU2:	DAD	B
	INX	D
	JC	DECOU2
	LXI	B,10
	DAD	B
	XCHG
	MOV	A,H
	ORA	L
	CNZ	DECOUT
	MOV	A,E
	ADI	'0'
	CALL	CTYPE
	POP	H
	POP	D
	POP	B
	RET
;
; Makes sure there are enough records to send.	For speed, this routine
; buffers up 16 records at a time.
;
RDRECD:	LDA	KFLAG		; Check for 1024 byte records
	ORA	A
	JNZ	RDRECDK		; Using 1K blocks
;
NOTKAY:	LDA	RECNBF		; Get number of records in buffer
	DCR	A		; Decrement it
	JM	RDBLOCK		; Exhausted?  need more
	ORA	A		; Otherwise, clear carry and...
	RET			; From 'RDRECD'
;
RDRECDK:LDA	RECNBF		; Get number of records in buffer
	ORA	A		; Any records in buffer?
	JZ	RDBLOCK		; Nope, get more
	SUI	8		; Decrement count of records
	RNC			; 8 or more left
	XRA	A		; Less than 8 left
	STA	KFLAG		; Revert to 128 blocks
	JMP	NOTKAY		; Continue with short blocks
;
; Update buffer pointers and counters AFTER sending a good block.
;
UPDPTR:	LDA	KFLAG
	ORA	A
	JNZ	BIG
	LXI	D,128		; Small pointer increment
	MVI	B,1		; Small sector number
	JMP	UPDPTR1
;
BIG:	LXI	D,1024		; Big pointer increment
	MVI	B,8		; Number of sectors in big block
;
UPDPTR1:LDA	RECNBF		; Update buffer sector count
	SUB	B
	STA	RECNBF
	LHLD	RECPTR		; Get buffer address
	DAD	D		; To next buffer
	SHLD	RECPTR		; Save buffer address
	RET
;
; Buffer is empty - read in another block of 16
;
RDBLOCK:LDA	EOFLG		; Get 'EOF' flag
	CPI	1		; Is it set?
	STC			; To show 'EOF'
	RZ			; Got 'EOF'
	MVI	C,0		; Records in block
	LXI	D,DBUF		; To disk buffer
;
RDRECLP:PUSH	B
	PUSH	D
	MVI	C,SETDMA	; Set DMA address
	CALL	BDOS
	LXI	D,FCB
	MVI	C,READ
	CALL	BDOS
	POP	D
	POP	B
	ORA	A		; Read ok?
	JZ	RDRECOK		; Yes
	DCR	A		; 'EOF'?
	JZ	REOF		; Got 'EOF'
;
; Read error
;
LERROR:	CALL	ERXIT
	DB	'++ File read error ++$'
;
RDRECOK:LXI	H,128		; Add length of one record
	DAD	D		; To next buffer
	XCHG			; Buffer to 'DE'
	INR	C		; More records?
	MOV	A,C		; Get count
	CPI	BUFSIZ*8	; Done?
	JZ	RDBFULL		; Yes, buffer is full
	JMP	RDRECLP		; Read more
;
REOF:	MVI	A,1
	STA	EOFLG		; Set EOF flag
	MOV	A,C
;
; Buffer is full, or got EOF
;
RDBFULL:STA	RECNBF		; Store record count
	LXI	H,DBUF		; Init buffer pointear
	SHLD	RECPTR		; Save buffer address
	LXI	D,TBUF		; Reset DMA address
	MVI	C,SETDMA
	CALL	BDOS
	JMP	RDRECD		; Pass record to caller
;
; Writes the record into a buffer.  When 16 have been written, writes
; the block to disk.
;
; Entry point "WRBLOCK" flushes the buffer at EOF
;
WRRECD:	LHLD	BLKSIZ		; Get length of last record
	XCHG			; Get ready for add
	LHLD	RECPTR		; Get buffer address
	DAD	D		; To next buffer
	SHLD	RECPTR		; Save buffer address
	XCHG			; Move BLKSIZ to HL
	CALL	SHFTHL		; Divide by 128 to get recors
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	CALL	SHFTHL
	LDA	RECNBF		; Bump the records number in the buffer
	ADD	L
	STA	RECNBF
	CPI	BUFSIZ*8	; Equal to, or past 'end' of buffer?
	RC			; No, return
;
; Writes a block to disk
;
WRBLOCK:LDA	RECNBF		; Number of records in the buffer
	ORA	A		; 0 means end of file
	RZ			; None to write
	MOV	C,A		; Save count
	LXI	D,DBUF		; Point to disk buff
;
DKWRLP:	PUSH	H
	PUSH	D
	PUSH	B
	MVI	C,SETDMA	; Set DMA
	CALL	BDOS		; To buffer
	LXI	D,FCB		; Then write the block
	MVI	C,WRITE
	CALL	BDOS
	POP	B
	POP	D
	POP	H
	ORA	A
	JNZ	WRERR		; Oops, error
	LXI	H,128		; Length of 1 record
	DAD	D		; 'HL'= next buff
	XCHG			; To 'DE' for setdma
	DCR	C		; More records?
	JNZ	DKWRLP		; Yes, loop
	XRA	A		; Get a zero
	STA	RECNBF		; Reset number of records
	LXI	H,DBUF		; Reset buffer buffer
	SHLD	RECPTR		; Save buffer address
;
RSDMA:	LXI	D,TBUF		; Reset DMA address
	MVI	C,SETDMA
	CALL	BDOS
	RET
;
WRERR:	CALL	RSDMA		; Reset DMA to normal
	MVI	C,CAN		; Cancel
	CALL	SEND		; Sender
; [WBW] BEGIN: RCVSABT does not return, so file write error
; message was never being displayed.  Swapped things around
; to fix this.
;	CALL	RCVSABT		; Kill receive file
;	CALL	ERXIT		; Exit with msg:
;	DB	'++ Error writing file ++$'
; [WBW] -----
	CALL	ILPRT		; Dispaly error msg
	DB	CR,LF,'++ Error writing file ++',CR,LF,0
	CALL	RCVSABT		; Kill receive file
; [WBW] END
	
;
; Receive a character - timeout time is in 'B' in seconds.  Entry via
; 'RECVDG' deletes garbage characters on the line.  For example, having
; just sent a record calling 'RECVDG' will delete any line-noise-induced
; characters "long" before the ACK/NAK would be received.
;
RECVDG:	CALL	GETCHR
	CALL	GETCHR
;
RECV:	PUSH	D		; Save 'DE' regs.
;
; [WBW] BEGIN: Check immediately for char pending to avoid delay
	CALL	RCVRDY		; Input from modem ready
	JZ	MCHAR		; Got the character
; [WBW] END
;
; [WBW] BEGIN: Use dynamic CPU speed
;	MVI	E,MHZ		; Get the clock speed
	LDA	CPUMHZ		; Get the clock speed
	MOV	E,A		; Put speed in E
; [WBW] END
	XRA	A		; Clear the 'A' reg.
;
MSLOOP:	ADD	B		; Number of seconds
	DCR	E		; One less mhz. to go
	JNZ	MSLOOP		; If not zero, continue
	MOV	B,A		; Put total value back into 'B'
;
MSEC:	 IF	NOT BYEBDOS
; [WBW] BEGIN: Use scalar passed in by patch
	;LXI	D,6600		; 1 second DCR count
	XCHG
	LHLD	RCVSCL		; Use scalar value from patch
	XCHG
; [WBW] END
	 ENDIF
;
	 IF	BYEBDOS
	LXI	D,2800		; (includes BYEBDOS overhead)
	 ENDIF
;
MWTI:	CALL	RCVRDY		; Input from modem ready
	JZ	MCHAR		; Got the character
	DCR	E		; Count down for timeout
	JNZ	MWTI
	DCR	D
	JNZ	MWTI
	DCR	B		; More seconds?
	JNZ	MSEC		; Yes, wait
;
; Test for the presence of carrier - if none, go to 'CARCK' and continue
; testing for specified time.  If carrier returns, continue.  If it does
; not return, exit.
;
	CALL	CAROK		; Is carrier still on?
	CNZ	CARCK		; If not, test for 15 seconds
;
; Modem timed out receiving - but carrier is still on.
;
	POP	D		; Restore 'DE'
	STC			; Carry shows timeout
	RET
;
; Get character from modem.
;
MCHAR:	CALL	MDIN		; Get data byte from modem
	POP	D		; Restore 'DE'
;
; Calculate checksum and CRC
;
	PUSH	PSW		; Save the character
	CALL	UPDCRC		; Calculate CRC
	ADD	C		; Add to checksum
	MOV	C,A		; Save checksum
	POP	PSW		; Restore the character
	ORA	A		; Carry off: no error
	RET			; From 'RECV'
;
; Common carrier test for receive and send.  If carrier returns within
; TIMOUT seconds, normal program execution continues.  Else, it will
; abort to CP/M via EXIT.
;
CARCK:	MVI	E,TIMOUT*10	; Value for 15 second delay
;
CARCK1:	CALL	DELAY		; Kill .1 seconds
	CALL	CAROK		; Is carrier still on?
	RZ			; Return if carrier on
	DCR	E		; Has 15 seconds expired?
	JNZ	CARCK1		; If not, continue testing
;
; See if got a local console, and report if so.
;
	 IF	NOT (USECON OR BYEBDOS)
	LHLD	CONOUT+1	; Get conout address
	MOV	A,H		; Zero if no local console
	ORA	L
	JZ	CARCK2
	 ENDIF
;
	MVI	A,1		; Print local only
	STA	CONONL
	CALL	ILPRT		; Report loss of carrier
	DB	CR,LF,'++ Carrier lost in XMODEM ++',CR,LF,0
;
CARCK2:	LDA	OPTSAV		; Get option
	CPI	'R'		; If not receive
	JNZ	EXIT		; Then abort now, else
	CALL	DELFILE		; Get rid of the junk first
	JMP	EXIT		; Else, abort to CP/M
;
; Delay - 100 millisecond delay.
;
DELAY:	PUSH	B		; Save 'BC'
; [WBW] BEGIN: Use dynamic CPU speed
; Loop below is 105TS on Z80 and 96TS on Z180
; Approx 1024 iter per 100ms per MHz
; Loop time below extended to accommodate CPU speeds up to 64MHz
;	LXI	B,MHZ*4167	; Value for 100 ms. delay
; Init BC w/ CPU MHz * 1024
	LDA	CPUMHZ		; CPU MHz to A
	RLC			; * 2
	RLC			; * 2, A now has MHz * 4
	MOV	B,A		; Use as high byte
	MVI	C,0		; Zero low byte, BC now has MHz * 1024
; [WBW] END
DELAY2:	DCX	B		; Update count
	MOV	A,B		; Get MSP byte
	ORA	C		; Count = zero?
	JNZ	DELAY2		; If not, continue
	CALL	DELAY3		; WBW: Extend loop time
	CALL	DELAY3		; WBW: Extend loop time
	CALL	DELAY3		; WBW: Extend loop time
	POP	B		; Restore 'BC'
DELAY3:	RET			; Return to CARCK1
;
;-----------------------------------------------------------------------
;
; Tells user to add description of an uploaded file
;
	 IF	DESCRIB
ASK:	LDA	OPTSAV		; Get the option
	CPI	'R'
	RNZ			; If not receiving a file, exit
	LDA	PRVTFL		; Sending to "private area"?
	ORA	A
	RNZ			; If yes, do not ask for description
	 ENDIF
;
	 IF	DESCRIB	AND ZCPR2 AND (NOT ASKSYS)
	LDA	WHEEL
	ORA	A
	RNZ
	 ENDIF
;
	 IF	DESCRIB
	MVI	B,2		; Short delay to wait for an input char.
	CALL	RECV
	 ENDIF
;
	 IF	DESCRIB	AND ASKIND
ASK1:	CALL	DELAY
	CALL	SHONM		; Show the file name
	CALL	DILPRT
	DB	' - this file is for:',CR,LF,CR,LF,0
	MVI	C,PRINT		; Display the file descriptors
	LXI	D,KIND0
	CALL	BDOS
	CALL	DILPRT
	DB	CR,LF,'Select one: ',0
	CALL	INPUT		; Get a character
	CALL	TYPE
	CPI	'0'
	JC	ASK1
	CPI	'9'+1
	JNC	ASK1
	STA	KIND
	 ENDIF
;
	 IF DESCRIB AND	(NOT ASKIND)
ASK1:	CALL	DELAY
	CALL	SHONM
	 ENDIF
;
	 IF	DESCRIB
ASK2:	LXI	H,0
	SHLD	OUTPTR		; Initialize the output pointers
	CALL	DILPRT
	DB	CR,LF,CR,LF
	DB	'Please describe this file (7 lines or less).  Tell '
	DB	'what equipment can use',CR,LF,'it and what the '
	DB	'program does.  Extra RET to quit.',CR,LF,CR,LF,0
	CALL	SENBEL
;
; Get the file name from FCB, skip any blanks
;
	LXI	H,HLINE
	CALL	DSTOR1
	MVI	B,8		; Get FILENAME
	LXI	D,FCB+1
	LXI	H,OLINE
	CALL	LOPFCB
	MVI	M,'.'
	MOV	A,M		; Separate FILENAME and EXTENT
	CALL	TYPE
	INX	H
	MVI	B,3		; Get EXTENT name
	CALL	LOPFCB
	 ENDIF
;
	IF	DESCRIB	AND ASKIND
AFIND1:	LDA	KIND
	CPI	'0'		; File category 0
	LXI	D,KIND0+4
	CZ	DKIND		; File category 1
	CPI	'1'
	LXI	D,KIND1+4
	CZ	DKIND		; File category 1
	CPI	'2'
	LXI	D,KIND2+4
	CZ	DKIND		; File category 2
	CPI	'3'
	LXI	D,KIND3+4
	CZ	DKIND		; File category 3
	CPI	'4'
	LXI	D,KIND4+4
	CZ	DKIND		; File category 4
	CPI	'5'
	LXI	D,KIND5+4
	CZ	DKIND		; File category 5
	CPI	'6'
	LXI	D,KIND6+4
	CZ	DKIND		; File category 6
	CPI	'7'
	LXI	D,KIND7+4
	CZ	DKIND		; File category 7
	CPI	'8'
	LXI	D,KIND8+4
	CZ	DKIND		; File category 8
	CPI	'9'
	LXI	D,KIND9+4
	CZ	DKIND		; File category 9
	 ENDIF			; DESCRIB AND ASKIND
;
	 IF DESCRIB AND	(NOT ASKIND)
	MVI	M,CR
	INX	H
	MVI	M,LF
	 ENDIF
;
	 IF	DESCRIB
	CALL	DSTOR		; Put FILENAME line into memory
	CALL	DILPRT
	DB	CR,LF,CR,LF,'0: ---------1---------2---------3'
	DB	'---------4---------5---------6---------',CR,LF,0
	XRA	A
	STA	ANYET		; Reset the flag for no information yet
	MVI	C,'0'
;
EXPLN:	INR	C
	MOV	A,C
	CPI	'7'+1
	JNC	EXPL1
	CALL	TYPE
	MVI	A,' '
	CALL	OUTCHR
	CALL	OUTCHR
	CALL	OUTCHR
	CALL	DILPRT
	DB	': ',0
	CALL	DESC		; Get a line of information
	CALL	DSTOR
	JMP	EXPLN
;
EXPL1:
	MVI	A,CR		; All finished, put in an extra CR-LF
	CALL	OUTCHR
	MVI	A,LF
	CALL	OUTCHR
	MVI	A,'$'
	CALL	OUTCHR
	CALL	DILPRT
	DB	'   Repeating to verify:',CR,LF,CR,LF,0
	LHLD	OUTADR
	XCHG
	MVI	C,PRINT
	CALL	BDOS
	LHLD	OUTPTR
	DCX	H
	SHLD	OUTPTR
;
EXPL2:	CALL	DILPRT
	DB	CR,LF,'Is this ok (Y/N)? ',0
	CALL	INPUT
	CALL	TYPE		; Display answer
	ANI	5FH		; Change to upper case
	CPI	'N'
	JZ	ASK1		; If not, do it over
	CPI	'Y'
	JNZ	EXPL2		; If yes, finish up, else ask again
;
; Now open the file and put this at the beginning
;
EXPL3:	LDA	0004H		; Get current drive/user
	STA	DRUSER		; Store
;
; Set drive/user to the area listed above
;
	MVI	E,USER		; Set user to WHATSFOR.TXT area
	MVI	C,SETUSR
	CALL	BDOS
	MVI	A,DRIVE		; Set drive to WHATSFOR.TXT area
	SUI	41H
	MOV	E,A
	MVI	C,SELDSK
	CALL	BDOS
;
; Open source file
;
	CALL	DILPRT
	DB	CR,LF,0
	LXI	D,FILE		; Open WHATSFOR.TXT file
	MVI	C,OPEN
	CALL	BDOS
	INR	A		; Check for no open
	JNZ	OFILE		; File exists, exit
	MVI	C,MAKE		; None exists, make a new file
	LXI	D,FILE
	CALL	BDOS
	INR	A
	JZ	NOROOM		; Exit if cannot open new file
;
OFILE:	LXI	H,FILE		; Otherwise use same filename
	LXI	D,DEST		; With .$$$ extent for now
	MVI	B,9
	CALL	MOVE
;
; Open the destination file
;
	XRA	A
	STA	DEST+12
	STA	DEST+32
	LXI	H,BSIZE		; Get Buffer allocated size
	SHLD	OUTSIZ		; Set for comparison
	MVI	C,DELET		; Delete any existing file that name
	LXI	D,DEST
	CALL	BDOS
	MVI	C,MAKE		; Now make a new file that name
	LXI	D,DEST
	CALL	BDOS
	INR	A
	JZ	NOROOM		; Cannot open file, no directory room
	CALL	DILPRT
	DB	CR,LF,'Wait a moment...',0
;
; Read sector from source file
;
READLP:	LXI	D,TBUF
	MVI	C,SETDMA
	CALL	BDOS
	LXI	D,FILE		; Read from WHATSFOR.TXT
	MVI	C,READ
	CALL	BDOS
	ORA	A		; Read ok?
	JNZ	RERROR
	LXI	H,TBUF		; Read buffer address
;
; Write sector to output file (with buffering)
;
WRDLOP:	MOV	A,M		; Get byte from read buffer
	ANI	7FH		; Strip parity bit
	CPI	7FH		; Del (rubout)?
	JZ	NEXT		; Yes, ignore it
	CPI	EOF		; End of file marker?
	JZ	TDONE		; Transfer done, close, exit
	CALL	OUTCHR
;
NEXT:	INR	L		; Done with sector?
	JZ	READLP		; If yes get another sector
	JMP	WRDLOP		; No, get another byte
;
; Handle a backspace character while entering a character string
;
BCKSP:	CALL	TYPE
	MOV	A,B		; Get position on line
	ORA	A
	JNZ	BCKSP1		; Exit if at initial column
	CALL	SENBEL		; Send a bell to the modem
	MVI	A,' '		; Delete the character
	JMP	BCKSP3
;
BCKSP1:	DCR	B		; Show one less column used
	DCX	H		; Decrease buffer location
	MVI	A,' '
	MOV	M,A		; Clear memory at this point
	CALL	TYPE		; Backspace the "CRT"
;
BCKSP2:	MVI	A,BS		; Reset the "CRT" again
;
BCKSP3:	CALL	TYPE		; Write to the "CRT"
	RET
;
; Asks for line of information
;
DESC:	MVI	B,0
	LXI	H,OLINE
;
DESC1:	CALL	INPUT		; Get keyboard character
	CPI	CR
	JZ	DESC4
	CPI	TAB
	JZ	DESC6
	CPI	BS
	JNZ	DESC2
	CALL	BCKSP
	JMP	DESC1		; Get the next character
;
DESC2:	CPI	' '
	JC	DESC1		; If non-printing character, ignore
	JZ	DESC3		; If a space, continue
	STA	ANYET		; Show a character has been sent now
;
DESC3:	MOV	M,A
	CALL	TYPE		; Display the character
	INX	H
	INR	B
	MOV	A,B
	CPI	70		; Do not exceed line length
	JC	DESC1
	CALL	SENBEL		; Send a bell to the modem
	CALL	BCKSP2
	CALL	BCKSP1		; Do not allow a too-long line
	JMP	DESC1
;
DESC4:	LDA	ANYET		; Any text typed on first line yet?
	ORA	A
	JNZ	DESC5		; If yes, exit
	POP	H
	JMP	ASK1		; Ask again for a description
;
DESC5:	MVI	M,CR
	MOV	A,M
	CALL	TYPE
	INX	H		; Ready for next character
	MVI	M,LF
	MOV	A,M
	CALL	TYPE		; Display the line feed
	INX	H
	MOV	A,B		; See if at first of line
	ORA	A
	RNZ			; If not, ask for next line
	POP	H		; Clear "CALL" from stack
	JMP	EXPL1
;
DESC6:	MOV	A,B		; At end of line now?
	CPI	68
	JNC	DESC1		; If yes, disregard
	MVI	M,' '
	MOV	A,M
	CALL	TYPE
	INX	H
	INR	B
	MOV	A,B
	ANI	7
	JNZ	DESC6
	JMP	DESC1		; Ask for next character
;
DSTOR:	LXI	H,OLINE
;
DSTOR1:	MOV	A,M
	CALL	OUTCHR
	CPI	LF
	RZ
	INX	H
	JMP	DSTOR1
;
; Print message then exit to CP/M
;
DEXIT:	POP	D		; Get message address
	MVI	C,PRINT		; Print message
	CALL	BDOS
	CALL	RESET		; Reset the drive/user
	JMP	EXIT		; all done
;
; Inline print routine - prints string pointed to by stack until a zero
; is found.  Returns to caller at the next address after the zero ter-
; minator.
;
DILPRT:	XTHL			; Save hl, get message address
;
DILPLP:	MOV	A,M		; Get char
	CALL	TYPE		; Output it
	INX	H		; Point to next
	MOV	A,M		; Test
	ORA	A		; For end
	JNZ	DILPLP
	XTHL			; Restore hl, ret address
	RET			; Return past the end of the message
;
;
; Disk is full, save original file, erase others.
;
FULL:	MVI	C,DELET
	LXI	D,DEST
	CALL	BDOS
	CALL	DEXIT
	DB	CR,LF,'++ DISK FULL, ABORTING, SAVING ORIGINAL FILE','$'
;
; Get a character, if none ready wait up to 3 minutes, then abort pgm
;
INPUT:	PUSH	H		; Save current values
	PUSH	D
	PUSH	B
;
; [WBW] BEGIN: Use dynamic CPU speed
;INPUT1:	LXI	D,1200		; Outer loop count (about 2 minutes)
;;
;INPUT2:	LXI	B,MHZ*100	; Roughly 100 ms.
INPUT1:	LXI	D,468		; Outer loop count (about 2 minutes)
;
INPUT2:	LDA	CPUMHZ		; CPU MHz to A
	MOV	B,A		; Put in B
	MVI	C,0		; Zero C, BC is now CPU MHz * 256, ~256ms
; [WBW] END
;
INPUT3:	PUSH	D		; Save the outer delay count
	PUSH	B		; Save the inner delay count
	MVI	E,0FFH
	MVI	C,DIRCON	; Get console status
	CALL	BDOS
	ANI	7FH
	POP	B		; Restore the inner delay count
	POP	D		; Restore the outer delay count
	ORA	A		; Have a character yet?
	JNZ	INPUT4		; If yes, exit and get it
	DCX	B
	MOV	A,C		; See if inner loop is finished
	ORA	B
	JNZ	INPUT3		; If not loop again
	DCX	D
	MOV	A,E
	ORA	D
	JNZ	INPUT2		; If not reset inner loop and go again
	MVI	A,CR
	CALL	OUTCHR
	MVI	A,LF
	CALL	OUTCHR
	LXI	SP,STACK	; Restore the stack
	CALL	EXPL3		; Finish appending previous information
	JMP	EXIT		; Finished
;
INPUT4:	POP	B
	POP	D
	POP	H
	RET
;
; Stores the Filename/extent in the buffer temporarily
;
LOPFCB:	LDAX	D		; Get FCB FILENAME/EXT character
	CPI	' '+1
	JC	LOPF1
	MOV	M,A		; Store in OLINE area
	CALL	TYPE		; Display on CRT
	INX	H		; Next OLINE position
;
LOPF1:	INX	D		; Next FCB position
	DCR	B		; One less to go
	JNZ	LOPFCB		; If not done, get next one
	RET
;
; No room to open a new file
;
NOROOM:	CALL	DEXIT
	DB	CR,LF,'++ No DIR space: output ++$'
;
; Output error - cannot close destination file
;
OERROR:	CALL	DEXIT
	DB	CR,LF,'++ Cannot close output ++$'
;
; Output a character to the new file buffer - first, see if there is
; room in the buffer for this character.
;
OUTCHR:	PUSH	H
	PUSH	PSW		; Store the character for now
	LHLD	OUTSIZ		; Get buffer size
	XCHG			; Put in 'DE'
	LHLD	OUTPTR		; Now get the buffer pointers
	MOV	A,L		; Check to see if room in buffer
	SUB	E
	MOV	A,H
	SBB	D
	JC	OUT3		; If room, go store the character
	LXI	H,0		; Otherwise reset the pointers
	SHLD	OUTPTR		; Store the new pointer address
;
OUT1:	XCHG			; Put pointer address into 'DE'
	LHLD	OUTSIZ		; Get the buffer size into 'HL'
	MOV	A,E		; See if buffer is max. length yet
	SUB	L		; By subtracting 'HL' from 'DE'
	MOV	A,D
	SBB	H
	JNC	OUT2		; If less, exit and keep going
;
; No more room in buffer, stop and transfer to destination file
;
	LHLD	OUTADR		; Get the buffer address
	DAD	D		; Add pointer value
	XCHG			; Put into 'DE'
	MVI	C,SETDMA
	CALL	BDOS
	LXI	D,DEST
	MVI	C,WRITE
	CALL	BDOS
	ORA	A
	JNZ	FULL		; Exit with error, if disk is full now
	LXI	D,RLEN
	LHLD	OUTPTR
	DAD	D
	SHLD	OUTPTR
	JMP	OUT1
;
OUT2:	LXI	D,TBUF
	MVI	C,SETDMA
	CALL	BDOS
	LXI	H,0
	SHLD	OUTPTR
;
OUT3:	XCHG
	LHLD	OUTADR
	DAD	D
	XCHG
	POP	PSW		; Get the character back
	STAX	D		; Store the character
	LHLD	OUTPTR		; Get the buffer pointer
	INX	H		; Increment them
	SHLD	OUTPTR		; Store the new pointer address
	POP	H
	RET
;
RERROR:	CPI	1		; File finished?
	JZ	TDONE		; Exit, then
	MVI	C,DELET		; Erase destination file, keep original
	LXI	D,DEST
	CALL	BDOS
	CALL	DEXIT
	DB	'++ Source file read error ++$'
;
; Reset the Drive/User to original, then back to original caller
;
RESET:	LDA	DRUSER		; Get original drive/user area back
	RAR
	RAR
	RAR
	RAR
	ANI	0FH		; Just look at the user area
	MOV	E,A
	MVI	C,SETUSR	; Restore original user area
	CALL	BDOS
	LDA	DRUSER		; Get the original drive/user back
	ANI	0FH		; Just look at the drive for now
	MOV	E,A
	MVI	C,SELDSK	; Restore original drive
	CALL	BDOS
	CALL	DILPRT		; Print CRLF before quitting
	DB	CR,LF,0
	RET			; Return to caller (Not JMP EXIT1)
;
; Send a bell just to the modem
;
SENBEL:	CALL	SNDRDY		; Is modem ready for another character?
	JNZ	SENBEL		; If not, wait
	MVI	A,7
	PUSH	PSW		; Overlay has the "POP PSW"
	JMP	SENDR		; Send to the modem only
;
;.....
;
;
; Shows the Filename/extent
;
SHONM:	CALL	DILPRT
	DB	CR,LF,CR,LF,0
	LXI	H,FCB+1
	MVI	B,8		; Maximum size of file name
	CALL	SHONM1
	MOV	A,M		; Get the next character
	CPI	' '		; Any file extent?
	RZ			; If not, finished
	MVI	A,'.'
	CALL	TYPE
	MVI	B,3		; Maximum size of file extent
;
SHONM1:	MOV	A,M		; Get FCB FILENAME/EXT character
	CPI	' '+1		; Skip any blanks
	JC	$+6
	CALL	TYPE		; Display on CRT
	INX	H		; Next FCB position
	DCR	B		; One less to go
	JNZ	SHONM1		; If not done, get next one
	RET
;.....
;
; Transfer is done - close destination file
;
TDONE:	LHLD	OUTPTR
	MOV	A,L
	ANI	RLEN-1
	JNZ	TDONE1
	SHLD	OUTSIZ
;
TDONE1:	MVI	A,EOF		; Fill remainder of record with ^Z's
	PUSH	PSW
	CALL	OUTCHR
	POP	PSW
	JNZ	TDONE
	MVI	C,CLOSE		; Close WHATSFOR.TXT file
	LXI	D,FILE
	CALL	BDOS
	MVI	C,CLOSE		; Close WHATSFOR.$$$ file
	LXI	D,DEST
	CALL	BDOS
	INR	A
	JZ	OERROR
;
;  Rename both files as no destination file name was specified
;
	LXI	H,FILE+1	; Prepare to rename old file to new
	LXI	D,DEST+17
	MVI	B,16
	CALL	MOVE
	MVI	C,DELET		; Delete original WHATSFOR.TXT file
	LXI	D,FILE
	CALL	BDOS
	LXI	D,DEST		; Rename WHATSFOR.$$$ to WHATSFOR.TXT
	MVI	C,RENAME
	CALL	BDOS
	JMP	RESET		; Reset the drive/user, back to caller
;
TYPE:	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	PSW
	MOV	E,A		; Character to 'E' for CP/M
	MVI	C,WRCON		; Write to console
	CALL	BDOS
	POP	PSW
	POP	H
	POP	D
	POP	B
	RET
	 ENDIF	; DESCRIB
;
	 IF	DESCRIB	AND ASKIND
DKIND:	LDAX	D		; Get the character from the string
	CALL	TYPE		; Otherwise display the character
	MOV	M,A		; Put in the buffer
	CPI	LF		; Done yet?
	JZ	DKIND1		; Exit if a LF, done
	INX	D		; Next position in the string
	INX	H		; Next postion in the buffer
	JMP	DKIND		; Keep going until a LF
;
DKIND1:	LDA	KIND		; Get the kind of file back
	RET			; Finished
	 ENDIF
;.....
;
;-----------------------------------------------------------------------
;
; Send a character to the modem
;
SEND:	PUSH	PSW		; Save the character
	CALL	UPDCRC		; Calculate CRC
	ADD	C		; Calcculate checksum
	MOV	C,A		; Save cksum
;
SENDW:	CALL	SNDRDY		; Is transmit ready
	JZ	SENDR		; Yes, go send
;
; Xmit status not ready, so test for carrier before looping - if lost,
; go to CARCK and give it up to 15 seconds to return.  If it doesn't,
; return abort via EXIT.
;
	PUSH	D		; Save 'DE'
	CALL	CAROK		; Is carrier still on?
	CNZ	CARCK		; If not, continue testing it
	POP	D		; Restore 'DE'
	JMP	SENDW		; Else, wait for xmit ready
;
; Waits for initial NAK - to ensure no data is sent until the receiving
; program is ready, this routine waits for the first timeout-nak or the
; letter 'C' for CRC from the receiver.  If CRC is in effect then Cyclic
; Redundancy Checks are used instead of checksums.  'E' contains the
; number of seconds to wait.  If the first character received is a CAN
; (CTL-X) then the send will be aborted as though it had timed out.
; Since 1K extensions require CRC, KFLAG is set to NULL if the receiver
; requests checksum
;
WAITNAK: IF	CONFUN		; Check for Sysop function key?
	CALL	FUNCHK		; Yeah, go ahead.. Twit?
	 ENDIF
;
	 IF	CONFUN AND SYSABT
	LDA	SYSABF		; If SYSABT option, check
	ORA	A		; to see if Abort
	JNZ	ABORT		; If so, bail out now...
	 ENDIF
;
	MVI	B,1		; Timeout delay
	CALL	RECV		; Did we get
	CPI	'K'		; Did he send a "K" first?
	JZ	SET1KX
	CPI	CRC		; 'CRC' indicated?
	JZ	SET1K		; Yes, send block
	CPI	NAK		; A 'NAK' indicating checksum?
	JZ	SETNAK		; Yes go put checksum in effect
	CPI	CAN		; Was it a cancel (CTL-X)?
	JZ	ABORT		; Yes, abort
	DCR	E		; Finished yet?
	JZ	ABORT		; Yes, abort
	JMP	WAITNAK		; No, loop
;
; Turn on checksum flag
;
SETNAK:	XRA	A
	STA	KFLAG		; Make sure transfer uses small blocks
	MVI	A,'C'		; Change to checksum
	STA	CRCFLG
	RET
;
; Turn on 1k flag
;
SET1K:	MVI	B,1		; Wait up to 1 second to get "K"
	CALL	RECV
	CPI	'K'		; Did we get a "K" or something else
	RNZ			; (or nothing)
;
SET1KX:	LDA	MSPEED
	CPI	5
	RC
	MVI	A,'K'
	STA	KFLAG		; Set 1k flag
	RET
;
; This routine moves the filename from the default command line buffer
; to the file control block (FCB).
;
MOVEFCB:LHLD	SAVEHL		; Get position on command line
	CALL	GETB		; Get numeric position
	LXI	D,FCB+1
	CALL	MOVENAM		; Move name to FCB
	XRA	A
	STA	FCBRNO		; Zero record number
	STA	FCBEXT		; Zero extent
	LDA	OPTSAV		; This going to be a library file?
	CPI	'L'
	RNZ			; If not, finished
;
; Handles library entries, first checks for proper .LBR extent.  If no
; extent was included, it adds one itself.
;
	SHLD	SAVEHL
	LXI	H,FCB+9		; 1st extent character
	MOV	A,M
	CPI	' '
	JZ	NOEXT		; No extent, make one
	CPI	'L'		; Check 1st character in extent
	JNZ	LBRERR
	INX	H
	MOV	A,M
	CPI	'B'		; Check 2nd character in extent
	JNZ	LBRERR
	INX	H
	MOV	A,M
	CPI	'R'		; Check 3rd character in extent
	JNZ	LBRERR
;
; Get the name of the desired file in the library
;
MOVEF1:	LHLD	SAVEHL		; Get current position on command line
	CALL	CHKMSP		; See if valid library member file name
	INR	B		; Increment for move name
	LXI	D,MEMFCB	; Store member name in special buffer
	JMP	MOVENAM		; Move from command line to buffer, done
;
; Check for any spaces prior to library member file name, if none (or
; only spaces remaining), no name.
;
CHKMSP:	DCR	B
	JZ	MEMERR
	MOV	A,M
	CPI	' '+1
	RNC
	INX	H
	JMP	CHKMSP
;
; Gets the count of characters remaining on the command line
;
GETB:	MOV	A,L
	SUI	TBUF+2		; Start location of 1st command
	MOV	B,A		; Store for now
	LDA	TBUF		; Find length of command line
	SUB	B		; Subtract those already used
	MOV	B,A		; Now have number of bytes remaining
	RET
;
LBRERR:	CALL	ERXIT
	DB	'++ Invalid library name ++$'
;
MEMERR:	CALL	ILPRT
	DB	CR,LF,'++ No library member file requested ++',CR,LF,0
	JMP	OPTERR
;
; Add .LBR extent to the library file name
;
NOEXT:	LXI	H,FCB+9		; Location of extent
	MVI	M,'L'
	INX	H
	MVI	M,'B'
	INX	H
	MVI	M,'R'
	JMP	MOVEF1		; Now get the library member name
;
; Move a file name from the 'TBUF' command line buffer into FCB
;
MOVENAM:MVI	C,1
;
MOVEN1:	MOV	A,M
	CPI	' '+1		; Name ends with space or return
	JC	FILLSP		; Fill with spaces if needed
	CPI	'.'
	JZ	CHKFIL		; File name might be less than 8 chars.
	STAX	D		; Store
	INX	D		; Next position to store the character
	INR	C		; One less to go
	MOV	A,C
	CPI	12+1
	JNC	NONAME		; 11 chars. maximum filename plus extent
;
MOVEN2:	INX	H		; Next char. in file name
	DCR	B
	JZ	OPTERR		; End of name, see if done yet
	JMP	MOVEN1
;
; See if any spaces needed between file name and .ext
;
CHKFIL:	CALL	FILLSP		; Fill with spaces
	JMP	MOVEN2
;
FILLSP:	MOV	A,C
	CPI	9
	RNC			; Up to 1st character in .ext now
	MVI	A,' '		; Be sure there is a blank there now
	STAX	D
	INR	C
	INX	D
	JMP	FILLSP		; Go do another
;
CTYPE:	PUSH	B		; Save all registers
	PUSH	D
	PUSH	H
	MOV	E,A		; Character to 'E' in case BDOS (normal)
	LDA	CONONL		; Want to bypass 'BYE' output to modem?
	ORA	A
	JNZ	CTYPEL		; Yes, go directly to CRT, then
	MVI	C,WRCON		; BDOS console output, to CRT and modem
	CALL	BDOS		; Since 'BYE' intercepts the char.
	POP	H		; Restore all registers
	POP	D
	POP	B
	RET
;
CTYPEL:	MOV	C,E		; BIOS needs it in 'C'
	CALL	CONOUT		; BIOS console output routine, not BDOS
	POP	H		; Restore all registers saved by 'CTYPE'
	POP	D
	POP	B
	RET
;
HEXO:	PUSH	PSW		; Save for right digit
	RAR			; Right justify the left digit
	RAR
	RAR
	RAR
	CALL	NIBBL		; Print left digit
	POP	PSW		; Restore right
;
NIBBL:	ANI	0FH		; Isolate digit
	ADI	90H
	DAA
	ACI	40H
	DAA
	JMP	CTYPE		; Type it
;
; Inline print of message, terminates with a 0
;
ILPRT:	XTHL			; Save HL, get HL=message
;
ILPLP:	MOV	A,M		; Get the character
	INX	H		; To next character
	ORA	A		; End of message?
	JZ	ILPRET		; Yes, return
	CALL	CTYPE		; Type the message
	JMP	ILPLP		; Loop
;
ILPRET:	XTHL			; Restore HL
	RET			; Past message
;
; Exit printing message following call
;
ERXIT:	CALL	ILPRT
	DB	CR,LF,0
	XRA	A
	STA	OPTSAV		; Reset option to zero for TELL
;
ERXIT1:	MVI	C,DIRCON	; Use BDOS Direct
	MVI	E,0FFH		; Console input function
	CALL	BDOS		; To check for abort
	CPI	'C'-40H		; CTL-C
	JZ	ERXITX		; Abort msg
	CPI	'K'-40H		; CTL-K
	JZ	ERXITX		; Abort msg
	POP	H		; Get address of next char
	MOV	A,M		; Get char
	INX	H		; Increment to next char
	PUSH	H		; Save address
	CPI	'$'		; End of message?
	JZ	EXITXL		; If '$' is end of message
	CALL	CTYPE		; Else print char on console
	JMP	ERXIT1		; And repeat until abort/end
;
EXITXL:	CALL	ILPRT
	DB	CR,LF,0
;
ERXITX:	POP	H		; Restore stack
	JMP	EXIT		; Get out of here
;
; Restore the old user area and drive from a received file
;
RECAREA:CALL	RECDRV		; Ok set the drive to its place
	LDA	PRVTFL		; Private area wanted?
	ORA	A
	LDA	XPRUSR		; Yes, set to private area
	JNZ	RECARE
	LDA	XUSR		; Ok now set the user area
;
RECARE:	MOV	E,A		; Stuff it in E
	MVI	C,SETUSR	; Tell BDOS what we want to do
	CALL	BDOS		; Now do it
	RET
;
RECDRV:	LDA	PRVTFL
	ORA	A
	LDA	XPRDRV		; Get private upload drive
	JNZ	RECDR1
	LDA	XDRV		; Or forced upload drive
;
RECDR1:	SUI	'A'		; Adjust it
;
RECDRX:	MOV	E,A		; Stuff it in E
	MVI	C,SELDSK	; Tell BDOS
	CALL	BDOS
	RET
;
MOVE:	MOV	A,M		; Get a character
	STAX	D		; Store it
	INX	H		; To next 'from'
	INX	D		; To next 'to'
	DCR	B		; More?
	JNZ	MOVE		; Yes, loop
	RET
;
;-----------------------------------------------------------------------
;
;			CRC SUBROUTINES
;
;-----------------------------------------------------------------------
;
CHKCRC:	PUSH	H		; Check 'CRC' bytes of received message
	LHLD	CRCVAL
	MOV	A,H
	ORA	L
	POP	H
	RZ
	MVI	A,0FFH
	RET
;
CLRCRC:	PUSH	H		; Reset 'CRC' store for a new message
	LXI	H,0
	SHLD	CRCVAL
	POP	H
	RET
;
FINCRC:	PUSH	PSW		; Finish 'CRC' calculation
	XRA	A
	CALL	UPDCRC
	CALL	UPDCRC
	PUSH	H
	LHLD	CRCVAL
	MOV	D,H
	MOV	E,L
	POP	H
	POP	PSW
	RET
;
UPDCRC:	PUSH	PSW		; Update 'CRC' store  with byte in 'A'
	PUSH	B
	PUSH	H
	MVI	B,8
	MOV	C,A
	LHLD	CRCVAL
;
UPDLOOP:MOV	A,C
	RLC
	MOV	C,A
	MOV	A,L
	RAL
	MOV	L,A
	MOV	A,H
	RAL
	MOV	H,A
	JNC	SKIPIT
	MOV	A,H		; The generator is x^16 + x^12 + x^5 + 1
	XRI	10H
	MOV	H,A
	MOV	A,L
	XRI	21H
	MOV	L,A
;
SKIPIT:	DCR	B
	JNZ	UPDLOOP
	SHLD	CRCVAL
	POP	H
	POP	B
	POP	PSW
	RET
;
;		       end of CRC routines
;-----------------------------------------------------------------------
;		    start of LOGCAL routines
;
; The following allocations are used by the LOGCALL routines
;
	 IF	LOGCAL
PGSIZE:	DB	0,0,0		; Program length in minutes and seconds
LOGOPT:	DB	'?'		; Primary option stored here
DEFAULT$DISK:
	DB	0		; Disk for open stored here
DEFAULT$USER:
	DB	0		; User for open stored here
FCBCALLER:
	DB	0,'LASTCALR???'	; Last caller file FCB
	DB	0,0,0,0,0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0
CALLERPTR:
	DW	LOGBUF
FCBLOG:	DB	0		; Log file FCB
	 ENDIF
;
	 IF	LOGCAL AND NOT (LOGSYS OR KNET)
	DB	'XMODEM  '
	DB	'L','O'+80H,'G'	; (the +80H makes this a $SYS file)
	 ENDIF
;
	 IF	LOGCAL AND LOGSYS AND NOT KNET
	DB	'LOG     '
	DB	'S','Y'+80H,'S'
	 ENDIF
;
	 IF	LOGCAL AND KNET	AND NOT	LOGSYS
	DB	'XMODEM  '
	DB	'T','X'+80H,'#'
	 ENDIF
;
	 IF	LOGCAL
	DB	0,0,0,0,0,0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0,0
LOGPTR:	DW	DBUF
LOGCNT:	DB	0
LOGK:	DB	'k '
	 ENDIF
;
	 IF	LOGCAL OR MBFMSG OR MBDESC
DSKSAV:	DB	0		; Up/download disk saved here
USRSAV:	DB	0		; Up/download user saved here
	 ENDIF
;
	 IF	LOGCAL AND (RTC	OR B3RTC OR BYEBDOS)
YYSAV:	DB	0
MMSAV:	DB	0
DDSAV:	DB	0
MNSAV:	DB	0
	 ENDIF
;
; Main log file routine, adds record to log file
;
	 IF	LOGCAL OR MBDESC OR MBFMSG
LOGCALL:
	MVI	C,CURDRV	; Get current disk
	CALL	BDOS		; (where down/upload occurred)
	STA	DSKSAV		; And save it...
	MVI	C,SETUSR	; Get current user area
	MVI	E,0FFH		; (where down/upload occurred)
	CALL	BDOS
	STA	USRSAV		; And save it...
	 ENDIF
;
	 IF	(MBDESC	OR MBFMSG) AND (NOT LOGCAL)
	RET			; Skip logging if no log
	 ENDIF
;
	 IF	LOGCAL
	XRA	A
	STA	FCBCALLER+12
	STA	FCBCALLER+32
	MVI	A,LASTDRV-'A'
	STA	DEFAULT$DISK
	MVI	A,LASTUSR
	STA	DEFAULT$USER
	LXI	D,FCBCALLER
	CALL	OPENF		; Open LASTCALR file
	JNZ	LOGC1
	CALL	ERXIT
	DB	'++ No last caller file found +++$'
;
LOGC1:	MVI	C,SETRRD	; Get random record #
	LXI	D,FCBCALLER	; (for first record in file)
	CALL	BDOS
	LXI	D,DBUF		; Set DMA to DBUF
	MVI	C,SETDMA
	CALL	BDOS
	LXI	D,FCBCALLER	; Read first (& only) record
	MVI	C,RRDM
	CALL	BDOS
	 ENDIF	;LOGCAL
;
	 IF	LOGCAL AND NOT (MBBS AND (RTC OR B3RTC OR BYEBDOS))
	LXI	H,DBUF		; Set pointer to beginning of record
	 ENDIF
;
	 IF	LOGCAL AND (MBBS AND (RTC OR B3RTC OR BYEBDOS))
	LXI	H,DBUF+11	; Set pointer to skip log on date
	 ENDIF
;
	 IF	LOGCAL
	SHLD	CALLERPTR
	LXI	D,LOGBUF	; Set DMA address to LOGBUF
	MVI	C,SETDMA
	CALL	BDOS
	XRA	A
	STA	FCBLOG+12
	STA	FCBLOG+32
	MVI	A,LOGDRV-'A'
	STA	DEFAULT$DISK
	MVI	A,LOGUSR
	STA	DEFAULT$USER
	LXI	D,FCBLOG
	CALL	OPENF		; Open log file
	JNZ	LOGC4		; If file exists, skip create
	LXI	D,FCBLOG
	MVI	C,MAKE		; Create a new file if needed
	CALL	BDOS
	INR	A
	JNZ	LOGC2		; No error, cont.
	CALL	ERXIT		; File create error
	DB	'++ No dir space: log ++$'
;
LOGC2:	MVI	C,SETRRD	; Set random record #
	LXI	D,FCBLOG	; (for first record in file)
	CALL	BDOS
;
LOGC3:	MVI	A,EOF
	STA	LOGBUF
	JMP	LOGC4B
;
LOGC4:	MVI	C,CFSIZE	; Get file length
	LXI	D,FCBLOG
	CALL	BDOS		; (end+1)
	LHLD	FCBLOG+33	; Back up to last record
	MOV	A,L
	ORA	H
	JZ	LOGC3		; Unless zero length file
	DCX	H
	SHLD	FCBLOG+33
	LXI	D,FCBLOG
	MVI	C,RRDM		; And read it
	CALL	BDOS
;
LOGC4B:	CALL	RSTLP		; Initialize LOGPTR and LOGCNT
;
LOGC6:	CALL	GETLOG		; Get characters out of last record
	CPI	EOF
	JNZ	LOGC6		; Until EOF
	LDA	LOGCNT		; Then backup one character
	DCR	A
	STA	LOGCNT
	LHLD	LOGPTR
	DCX	H
	SHLD	LOGPTR
	LDA	LOGOPT		; Get option back and put in file
	CALL	PUTLOG
	CALL	SPEED		; Get speed factor
	ADI	30H
	CALL	PUTLOG
	CALL	PUTSP		; Blank
	LDA	PGSIZE		; Now the program size in minutes..
	CALL	PNDEC		; Of transfer time (mins)
	MVI	A,':'
	CALL	PUTLOG		; ':'
	LDA	PGSIZE+2
	CALL	PNDEC		; And secs..
	CALL	PUTSP		; Blank
;
; Log the drive and user area as a prompt
;
	LDA	FCB
	ORA	A
	JNZ	WDRV
	LDA	DSKSAV
	INR	A
;
WDRV:	ADI	'A'-1
	CALL	PUTLOG
	LDA	USRSAV
	CALL	PNDEC
	MVI	A,'>'		; Make it look like a prompt
	CALL	PUTLOG
	LDA	OPTSAV
	CPI	'L'
	JNZ	WDRV1
	LXI	H,MEMFCB	; Name of file in library
	MVI	B,11
	CALL	PUTSTR
	CALL	PUTSP		; ' '
;
WDRV1:	LXI	H,FCB+1		; Now the name of the file
	MVI	B,11
	CALL	PUTSTR
	LDA	OPTSAV
	CPI	'L'
	JNZ	WDRV2
	MVI	C,1
	JMP	SPLOOP
;
WDRV2:	MVI	C,13
;
SPLOOP:	PUSH	B
	CALL	PUTSP		; Put ' '
	POP	B
	DCR	C
	JNZ	SPLOOP
	LHLD	VRECNO		; Get VIRTUAL record count
	LXI	D,8		; Divide record count by 8
	CALL	DVHLDE		; To get # of 1024 byte blocks
	MOV	A,H
	ORA	L		; Check if remainder
	MOV	H,B		; Get quotient
	MOV	L,C
	JZ	EXKB2		; If 0 remainder, exact kb
	INX	H		; Else increment to next kb
;
EXKB2:	CALL	PNDEC3		; Print to log file (right just xxxk)
	LXI	H,LOGK		; 'k '
	MVI	B,2
	CALL	PUTSTR
	 ENDIF
;
	 IF	LOGCAL AND BYEBDOS
	MVI	C,BDSTOS	; Set max time to 0 so BYE won't
	MVI	E,0		; hang up when doing BYEBDOS calls
	CALL	BDOS		; when getting time/date
	 ENDIF
;
	 IF	LOGCAL AND (B3RTC OR RTC OR BYEBDOS)
	CALL	GETDATE		; IF RTC, get current date
	PUSH	B		; (save DD/YY)
	CALL	PNDEC		; Print MM
	MVI	A,'/'		; '/'
	CALL	PUTLOG
	POP	PSW		; Get DD/YY
	PUSH	PSW		; Save YY
	CALL	PNDEC		; Print DD
	MVI	A,'/'		; '/'
	CALL	PUTLOG
	POP	B		; Get YY
	MOV	A,C
	CALL	PNDEC		; Print YY
	CALL	PUTSP		; ' '
	CALL	GETTIME		; IF RTC, get current time
	STA	MNSAV		; Save min
	MOV	A,B		; Get current hour
	CALL	PNDEC		; Print hr to file
	MVI	A,':'		; With ':'
	CALL	PUTLOG		; Between HH:MM
	LDA	MNSAV		; Get min
	CALL	PNDEC		; And print min
	CALL	PUTSP		; Print a space
	 ENDIF
;
	 IF	LOGCAL AND BYEBDOS
	LDA	MAXTOS		; Reset time on system
	MOV	E,A		; So BYE will hang up
	MVI	C,BDSTOS	; If caller is over time limit
	CALL	BDOS
	 ENDIF
;
	 IF	LOGCAL AND OXGATE AND (B3RTC OR	RTC OR BYEBDOS)
	XRA	A
	STA	CMMACNT		; Clear comma count
	 ENDIF
;
	 IF	LOGCAL
CLOOP:	CALL	GETCALLER	; And the caller
	CPI	EOF
	JZ	QUIT
	CPI	CR		; Do not print 2nd line of 'LASTCALR'
	JNZ	CLOP1
	CALL	PUTLOG
	MVI	A,LF
	CALL	PUTLOG		; And add a LF
	JMP	QUIT
;
CLOP1:	CPI	','		; Do not print the ',' between names
	JNZ	CLOP2
	 ENDIF	; LOGCAL
;
	 IF	LOGCAL AND OXGATE AND (B3RTC OR	RTC OR BYEBDOS)
	LDA	CMMACNT		; Get comma count
	INR	A
	STA	CMMACNT
	CPI	2		; If reached second comma, do CRLF exit
	JZ	CLOPX
	 ENDIF
;
	 IF	LOGCAL
	MVI	A,' '		; Instead send a ' '
CLOP2:	CALL	PUTLOG
	JMP	CLOOP
	 ENDIF
;
	 IF	LOGCAL AND OXGATE AND (B3RTC OR	RTC OR BYEBDOS)
CLOPX:	MVI	A,CR		; Cloop exit... do a CRLF and finish up.
	CALL	PUTLOG
	MVI	A,LF
	CALL	PUTLOG
	 ENDIF
;
	 IF	LOGCAL
QUIT:	MVI	A,EOF		; Put in EOF
	CALL	PUTLOG
	LDA	LOGCNT		; Check count of chars in buffer
	CPI	1
	JNZ	QUIT		; Fill last buffer & write it
	LXI	D,FCBCALLER	; Close lastcaller file
	MVI	C,CLOSE
	CALL	BDOS
	INR	A
	JZ	QUIT1
	LHLD	FCBLOG+33	; Move pointer back to show
	DCX	H		; Actual file size
	SHLD	FCBLOG+33
	LXI	D,FCBLOG	; Close log file
	MVI	C,CLOSE
	CALL	BDOS
	INR	A
	RNZ			; If OK, return now...
;
QUIT1:	CALL	ERXIT		; If error, oops
	DB	'++ Cannot close log ++$'
	 ENDIF	; LOGCAL
;
;-----------------------------------------------------------------------
;
; Support routines for LOGCAL
;
; Gets a single byte from DBUF
;
	 IF	LOGCAL
GETCALLER:
	LHLD	CALLERPTR
	MOV	A,M
	INX	H
	SHLD	CALLERPTR
	RET
;
; Gets a single byte from log file
;
GETLOG:	LDA	LOGCNT
	INR	A
	STA	LOGCNT
	CPI	129
	JZ	EOLF
	LHLD	LOGPTR
	MOV	A,M
	INX	H
	SHLD	LOGPTR
	RET
;
EOLF:	LHLD	FCBLOG+33
	INX	H
	SHLD	FCBLOG+33
	LXI	H,LOGBUF+1
	SHLD	LOGPTR
	MVI	A,1
	STA	LOGCNT
	MVI	A,EOF
	RET
;
; Open file with FCB pointed to by DE (disk/user passed in DEFAULT$DISK
; and DEFAULT$USER)
;
OPENF:	PUSH	D		; Save FCB address
	LDA	DEFAULT$DISK	; Get disk for file
	CALL	RECDRX		; Log into it
	LDA	DEFAULT$USER	; Get default user
	CALL	RECARE		; Log into it
	POP	D		; Get FCB address
	MVI	C,OPEN		; Open file
	CALL	BDOS
	CPI	255		; Not present?
	RET			; Return to caller
;
; Write character to log file
;
PUTLOG:	LHLD	LOGPTR		; Get pointer
	ANI	7FH		; Mask off any high bits
	MOV	M,A		; Put data
	INX	H		; Increment pointer
	SHLD	LOGPTR		; Update pointer
	MOV	B,A		; Save character in B
	LDA	LOGCNT		; Get count
	INR	A		; Increment it
	STA	LOGCNT		; Update count
	CPI	129		; Check it
	RNZ			; If not EOB, return
	PUSH	B		; Save character
	LXI	D,FCBLOG	; Else, write this sector
	MVI	C,WRDM
	CALL	BDOS
	ORA	A
	JZ	ADVRCP		; If ok, cont.
	CALL	ERXIT
	DB	'++ Disk full - cannot add to log ++$'
;
ADVRCP:	LHLD	FCBLOG+33	; Advance record number
	INX	H
	SHLD	FCBLOG+33
	CALL	RSTLP		; Reset buffer pointers
	POP	PSW		; Get saved character
	JMP	PUTLOG		; Put it in buffer and return
;
RSTLP:	LXI	H,LOGBUF	; Reset pointers
	SHLD	LOGPTR		; And return
	MVI	A,0
	STA	LOGCNT
	RET
;
; Print number in decimal format (into log file)
;    IN:  HL=binary number
;    OUT: nnn=right justified with spaces
;
PNDEC3:	MOV	A,H		; Check high byte
	ORA	A
	JNZ	DECOT		; If on, is at least 3 digits
	MOV	A,L		; Else, check low byte
	CPI	100
	JNC	TEN
	CALL	PUTSP
;
TEN:	CPI	10
	JNC	DECOT
	CALL	PUTSP
	JMP	DECOT
;
; Puts a single space in log file, saves PSW/HL
;
PUTSP:	PUSH	PSW
	PUSH	H
	MVI	A,' '
	CALL	PUTLOG
	POP	H
	POP	PSW
	RET
;
; Print number in decimal format (into log file)
;
PNDEC:	CPI	10		; Two column decimal format routine
	JC	ONE		; One or two digits to area number?
	JMP	TWO
;
ONE:	PUSH	PSW
	MVI	A,'0'
	CALL	PUTLOG
	POP	PSW
;
TWO:	MVI	H,0
	MOV	L,A
;
DECOT:	PUSH	B
	PUSH	D
	PUSH	H
	LXI	B,-10
	LXI	D,-1
;
DECOT2:	DAD	B
	INX	D
	JC	DECOT2
	LXI	B,10
	DAD	B
	XCHG
	MOV	A,H
	ORA	L
	CNZ	DECOT
	MOV	A,E
	ADI	'0'
	CALL	PUTLOG
	POP	H
	POP	D
	POP	B
	RET
;
; Put string to log file
;
PUTSTR:	MOV	A,M
	PUSH	H
	PUSH	B
	CALL	PUTLOG
	POP	B
	POP	H
	INX	H
	DCR	B
	JNZ	PUTSTR
	RET
	 ENDIF	; LOGCAL
;
;		      end of LOGCAL routine
;-----------------------------------------------------------------------
;		     start of TIMEON routine
;
; Calculate time on system and inform user.  Log him off if =>MAXMIN
; unless STATUS is non-zero.
;
	 IF	TIMEON
TIME:	PUSH	B		; Save BC pair
	CALL	GETTIME		; Get time from system's RTC
	STA	CMTEMP		; Save in current-hour-temp
	MOV	A,B		; Get current hour
	POP	B		; Restore BC
	 ENDIF
;
	 IF	TIMEON AND BYEBDOS
	PUSH	PSW		; save the current hour <== BUG FIX
	PUSH	B		; Lhour was safely moved to highmem
	PUSH	D		; in newer versions of BYE
	MVI	C,BDGRTC
	CALL	BDOS
	LXI	D,11		; Get address of LHOUR
	DAD	D
	POP	D
	POP	B
	POP	PSW		; Restore current hour...BDOS killed it
	 ENDIF
;
	 IF	TIMEON AND NOT BYEBDOS
	LXI	H,LHOUR		; Point to log-on hour (in low memory)
	 ENDIF
;
	 IF	TIMEON
	CMP	M		; Equal?
	INX	H		; Point to logon minutes
	JNZ	TIME1		; No
	MOV	D,M
	LDA	CMTEMP		; Current minutes
	SUB	D
	STA	TON		; Store total time on
	JMP	TIME2
;
TIME1:	MOV	D,M		; Get logon minutes
	MVI	A,03CH		; 60 min into A
	SUB	D
	LXI	H,CMTEMP	; Point at current min
	ADD	M		; Add current minutes
	STA	TON
	 ENDIF
;
TIME2:	 IF	ZCPR2 AND TIMEON
	LDA	WHEEL		; Check wheel status if ZCPR
	ORA	A		; Is it zero
	JNZ	TIME3		; If not then this is a special user
	 ENDIF
;
	 IF	TIMEON
	LDA	MAXTOS
	ORA	A		; If maxtos is zero, guy is superuser
	JZ	TIME3
	 ENDIF
;
	 IF	TIMEON AND NOT BYEBDOS ; BYEBDOS doesn't use status byte
	ORA	A		; Special user?
	JNZ	TIME3		; Yes, skip log off check
	LDA	TON
	SUI	MAXMIN		; Subtract max time allowed
	 ENDIF
;
	 IF	TIMEON AND BYEBDOS
	LDA	MAXTOS
	MOV	B,A
	LDA	TON
	SUB	B
	 ENDIF
;
	 IF	TIMEON
	JC	TIME3		; Still time left
	CALL	TIMEUP		; Time is up, inform user
	MVI	A,0CDH		; Alter jump vector
	STA	0		; At zero
	JMP	0000H		; And log him off
;
TIME3:	LXI	H,MSG1+015H	; Point at message insert bytes
	LDA	TON		; Convert to ASCII
	MVI	B,0FFH
;
TIME4:	INR	B
	SUI	0AH		; Subtract 10
	JNC	TIME4		; Until done
	ADI	0AH
	ORI	'0'		; Make ASCII
	MOV	M,A
	DCX	H
	MVI	A,'0'
	ADD	B
	MOV	M,A
	CALL	ILPRT
;
MSG1:	DB	CR,LF,'Time on system is 00 minutes',CR,LF,0
	 ENDIF
;
	 IF	TIMEON AND NOT BYEBDOS
	LDA	STATUS		; Check user status
	ORA	A		; Special user?
	JNZ	TIME5		; Yes, reset TON
	 ENDIF
;
	 IF	TIMEON
	RET
	 ENDIF
;
	 IF	TIMEON AND NOT BYEBDOS
TIME5:	MVI	A,0		; Reset timeout for good guys
	STA	TON
	RET
	 ENDIF
;
	 IF	TIMEON
TIMEUP:	CALL	ILPRT
	DB	CR,LF,CR,LF
	DB	'Your time is up - wait 24 hours to call back',CR,LF,0
	RET
;
TON:	DB	0		; Storage for time on system
CMTEMP:	DB	0		; Storage for current minute value
	 ENDIF
;
; Get caller's time on system from BYE3 or MBYE and display on console.
;
	 IF	B3RTC AND B3TOS
TIME:	CALL	ILPRT
	DB	CR,LF,'Time on system is ',0
	CALL	GETTOS		; Get Time On System from MBYE's RTC
	CALL	DECOUT		; Print it on the screen
	CALL	ILPRT
	DB	' minutes',CR,LF,0
	RET
	 ENDIF
;
; Get caller's time on system (returned in HL).
;
	IF	B3RTC AND (NOT BYEBDOS)
GETTOS:	LHLD	RTCBUF		; Get RTCBUF addr
	MOV	A,H
	ORA	L
	RZ			; If 0000H, BYE not running so TOS=0
	MOV	A,M		; If hours = 99
	CPI	099H
	LXI	H,0
	RZ			; Return with TOS=0
	LHLD	RTCBUF
	LXI	D,B3CMOS	; Get offset to TOS word
	DAD	D		; (addr in HL)
	MOV	E,M		; Get minutes on system
	INX	H
	MOV	D,M		; Stuff into DE
	XCHG			; Swap into HL
	RET
	ENDIF
;
	 IF	BYEBDOS	OR MXTOS
MAXTOS:	DB	0		; Maximum time on system
	 ENDIF
;
;		      end of TIMEON routine
;-----------------------------------------------------------------------
;
GETDATE: IF	(RTC AND LOGCAL) AND NOT (CPM3 OR BYEBDOS)
	LDA	45H		; Get the binary day number
	MOV	B,A		; Set to return binary day # B reg.
	LDA	46H		; Get the binary year number
	MOV	C,A		; Set to return binary year # in C reg.
	LDA	44H		; Get the binary month number
	RET
	 ENDIF
;
;-----------------------------------------------------------------------
;		   start of CPM+ date routine

	 IF	RTC AND	LOGCAL AND CPM3
	MVI	C,GETTIM	; BDOS function to get date and time
	LXI	D,TIMEPB	; Get address of 4-byte data structure
	CALL	BDOS		; Transfer the current date/time
	LHLD	TIMEPB
	MVI	B,78		; Set years counter
;
LOOP:	CALL	CKLEAP
	LXI	D,-365		; Set up for subtract
	JNZ	NOLPY		; Skip if no leap year
	DCX	D		; Set for leap year
;
NOLPY:	DAD	D		; Subtract
	JNC	YDONE		; Continue if years done
	MOV	A,H
	ORA	L
	JZ	YDONE
	SHLD	TIMEPB		; Else save days count
	INR	B		; Increment years count
	JMP	LOOP		; And do again
;
; The years are now finished, the years count is in 'B' and TIMEPB holds
; the days (HL is invalid)
;
YDONE:	MOV	A,B
	STA	YEAR
	CALL	CKLEAP		; Check if leap year
	MVI	A,-28
	JNZ	FEBNO		; February not 29 days
	MVI	A,-29		; Leap year
;
FEBNO:	STA	FEB		; Set february
	LHLD	TIMEPB		; Get days count
	LXI	D,MTABLE	; Point to months table
	MVI	B,0FFH		; Set up 'B' for subtract
	MVI	A,0		; Set a for # of months
;
MLOOP:	PUSH	PSW
	LDAX	D		; Get month
	MOV	C,A		; Put in 'C' for subtract
	POP	PSW
	SHLD	TIMEPB		; Save days count
	DAD	B		; Subtract
	INX	D		; Increment months counter
	INR	A
	JC	MLOOP		; Loop for next month
;
; The months are finished, days count is on stack.  First, calculate
; the month.
;
MDONE:	MOV	B,A		; Save months
	LHLD	TIMEPB
	MOV	A,H
	ORA	L
	JNZ	NZD
	DCX	D
	DCX	D
	LDAX	D
	CMA
	INR	A
	MOV	L,A
	DCR	B
;
NZD:	MOV	A,B
	STA	MONTH
	MOV	A,L
	STA	DAY
	LDA	YEAR
	MOV	C,A
	LDA	DAY
	MOV	B,A
	LDA	MONTH
	RET
;
; This routine checks for leap years.
;
CKLEAP:	MOV	A,B
	ANI	0FCH
	CMP	B
	RET
;
; This is the month's table
;
MTABLE:	DB	-31		; January
FEB:	DB	-28		; February
	DB	-31,-30,-31,-30	; Mar-Jun
	DB	-31,-31,-30	; Jul-Sep
	DB	-31,-30,-31	; Oct-Dec
;
YEAR:	DB	0
MONTH:	DB	0
DAY:	DB	0
	 ENDIF	; RTC AND LOGCAL AND CPM3
;
;		    end of CPM+ date routine
;-----------------------------------------------------------------------
;
	 IF	LOGCAL AND B3RTC AND NOT BYEBDOS
	CALL	BYECHK		; See if BYE is running
	JZ	GETBDAT		; If so, get date from buffer & convert
	MVI	A,0		; Else, return 00/00/00
	MOV	B,A
	MOV	C,A
	RET
	 ENDIF
;
	 IF	LOGCAL AND B3RTC AND (NOT BYEBDOS)
GETBDAT:LHLD	RTCBUF		; Get RTC buffer in HL
	 ENDIF
;
	 IF	LOGCAL AND BYEBDOS AND (NOT B3RTC)
	MVI	C,BDGRTC	; Get RTC buffer in HL
	CALL	BDOS
	 ENDIF
;
	 IF	LOGCAL AND (BYEBDOS OR B3RTC)
	LXI	D,4		; Offset to YY
	DAD	D		; HL=YY Address
	MOV	A,M		; Get YY
	CALL	BCDBIN		; Make it binary
	STA	YYSAV		; Save YY
	INX	H		; Point to MM
	MOV	A,M		; Get MM
	CALL	BCDBIN		; Convert BCD to binary
	STA	MMSAV		; Save it
	INX	H		; Point to DD
	MOV	A,M		; Get DAY
	CALL	BCDBIN		; Convert it to binary
	MOV	B,A		; Stuff DD in B
	LDA	YYSAV		; Get YY
	MOV	C,A		; Put YY in C
	LDA	MMSAV		; Get MM in A
	RET			; And return
	 ENDIF
;
;
; The routine here should read your real-time clock and return with the
; following information:
;
; register: A - current minute (0-59)
;	    B - current hour   (0-23)
;
GETTIME: IF	(TIMEON	OR RTC)	AND NOT	(B3RTC OR CPM3 OR BYEBDOS)
;
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;;	     (this example is for the Serria SBC-100)
;;
;;SBCHR EQU	040H		; Low memory area where stored
;;SBCMN EQU	041H
;;
;;	LDA	SBCHR		; Get hour from BIOS memory-clock
;;	MOV	B,A
;;	LDA	SBCMN		; Get minute from BIOS memory-clock
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;;	(this example is for Don Brown's computer)
;;
;;	LDA	43h		; Get the current binary hour number
;;	MOV	B,A		; Set to return binary hour number in Reg. B
;;	LDA	42h		; Get the current binary minute number
;; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
	RET
	 ENDIF
;
; The following code is for CP/M Plus
;
	 IF	(TIMEON	OR RTC)	AND CPM3
	MVI	C,GETTIM	; BDOS function to get date and time
	LXI	D,TIMEPB	; Get address of 4-byte data structure
	CALL	BDOS		; Transfer the current date/time
	LDA	TIMEPB+2	; Get current hour
	CALL	BCDBIN		; Convert BCD hour to binary
	MOV	B,A		; Position hour for return
	PUSH	B		; Save the binary hour
	LDA	TIMEPB+3	; Get current minute
	CALL	BCDBIN		; Convert BCD minute to binary
	POP	B		; Restore the binary hour
	RET
	 ENDIF
;
	 IF	LOGCAL AND B3RTC AND (NOT BYEBDOS)
	CALL	BYECHK		; See if BYE is running
	JZ	GETBTIM		; If so, get time from buffer & convert
	MVI	A,0		; Else, return 00:00
	MOV	B,A
	RET
;
GETBTIM:LHLD	RTCBUF		; Get RTC buffer address
	 ENDIF
;
	 IF	LOGCAL AND BYEBDOS AND (NOT B3RTC)
	MVI	C,BDGRTC	; Get RTC buffer address
	CALL	BDOS
	 ENDIF
;
	 IF	LOGCAL AND (B3RTC OR BYEBDOS)
	MOV	A,M		; Get hours on system
	CALL	BCDBIN		; Convert BCD value to binary
	PUSH	PSW		; Save hr on stack
	INX	H		; Point to minute
	MOV	A,M		; Get min
	CALL	BCDBIN		; Convert BCD to binary
	POP	B		; Get hr in B (min in A)
	RET			; And return
	 ENDIF
;
; Convert BCD value in A to binary in A
;
	 IF	LOGCAL AND (B3RTC OR CPM3 OR BYEBDOS)
BCDBIN:	PUSH	PSW		; Save A
	ANI	0F0H		; Mask high nibble
	RRC			; Move to low nibble
	RRC
	RRC
	RRC
	MOV	C,A		; And stuff in C (C=A)
	MVI	B,9		; X10 (*9)
;
BCDBL:	ADD	C		; Add orig value to A
	DCR	B		; Decrement B
	JNZ	BCDBL		; Loop nine times (A+(C*9)=A*10)
	MOV	B,A		; Save result in B
	POP	PSW		; Get original value
	ANI	0FH		; Mask low nibble
	ADD	B		; +B gives binary value of BCD digit A
	RET			; Return
	 ENDIF
;
; Check to see that HL register is at least 8 records.	If it not, make
; sure 1K blocks are turned off
;
CKKSIZ:	MOV	A,H		; Get high order byte
	ORA	A		; Something there?
	RNZ			; Yes, certainly more than 8
	MOV	A,L		; Get low order byte
	CPI	8		; Looking for at least this many records
	RNC			; Not Carry means 8 or more records
	XRA	A		; Get nothing
	STA	KFLAG		; Turn off 1K blocks
	RET
;
;-----------------------------------------------------------------------
;
;		    BYEBDOS access routines
;
;-----------------------------------------------------------------------
;
	 IF	BYEBDOS
CONOUT:	MOV	E,C		; Get character into E
	MVI	C,BDCONO	; Console output (local only)
	JMP	BDOS		; Go to it...
;
MINIT:
UNINIT:	RET			; Modem's already initialized
;
SENDR:	POP	PSW		; Needed by specifications
	PUSH	B
	PUSH	D
	PUSH	H
	MOV	E,A		; Put character in E
	MVI	C,BDMOUT
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET
;
GETCHR:
MDIN:	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,BDMINP
	CALL	BDOS
	POP	H
	POP	D
	POP	B
	RET
;
; The following 3 routines operate in differently than BYE does, so we
; must make things "backwards"
;
CAROK:	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,BDCSTA
	CALL	BDOS
	JMP	BKWDS
;
RCVRDY:	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,BDMIST
	CALL	BDOS
	JMP	BKWDS
;
SNDRDY:	PUSH	B
	PUSH	D
	PUSH	H
	MVI	C,BDMOST
	CALL	BDOS
;
; Flip around bytes, if A>0 then make A zero & set flags
;		     if A=0 then make A =255 & set flags
BKWDS:	ORA	A
	MVI	A,255
	JZ	NOSIG
	XRA	A
;
NOSIG:	ORA	A
	POP	H
	POP	D
	POP	B
	RET
;
SPEED:	LDA	MSPEED
	RET
	 ENDIF
;
;-----------------------------------------------------------------------
;
;		     Temporary storage area
;
;-----------------------------------------------------------------------
;
	 IF	DESCRIB
FILE:	DB	0,'WHATSFORTXT',0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0
DEST:	DB	0,'        $$$',0,0,0,0,0,0,0
	DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0
	 ENDIF
;
; Put this ram stuff in the RAM section at the end
;
LZFLG:	DB	0		; For the free space printer
BLKSHF:	DB	0
BLKMAX:	DB	0,0
;
	 IF	B3RTC AND NOT BYEBDOS	; If BYE3/MBYE real-time clock
RTCBUF:	DW	0		; Address of RTCBUF saved here
	 ENDIF
;
	 IF	B3RTC AND NOT (MBMXT OR	BYEBDOS)
TOSSAV:	DW	0
	 ENDIF
;
	 IF	LOGCAL AND OXGATE AND (B3RTC OR	RTC OR BYEBDOS)
CMMACNT:DB	0		; Comma counter
	 ENDIF
;
	 IF	TIMEON AND CPM3
TIMEPB:	DS	4		; Storage for the system date/time
	 ENDIF
;
MINUTE:	DW	0		; Transfer time in mins for MAXTIM
MEMFCB:	DB	'                ' ; Library name (16 bytes required)
ANYET:	DB	0		; Any description typed yet?
BLKSIZ:	DW	0		; Number of bytes, 128 or 1024
CONONL:	DB	0		; CTYPE console-only flag
CRCFLG:	DB	0		; Sets to 'C' if checksum requested
CRCVAL:	DW	0		; Current CRC value
DIRSZ:	DW	0		; Directory size
DRUSER:	DB	0		; Original drive/user, for return
DUD:	DB	0		; Specified disk
DUSAVE:	DB	0,0,0,0		; Buffer for drive/user
DUU:	DB	0		; Specified user
ERRCT:	DB	0		; Error count
FRSTIM:	DB	0		; Turned on after first 'SOH' received
INDEX:	DW	0		; Index into directory
KFLAG:	DB	0		; Non-zero if sending 1K blocks
OUTPTR:	DW	0
RCNT:	DW	0		; Record count
RCVDRV:	DB	0		; Requested drive number
RCVRNO:	DB	0		; Record number received
RCVUSR:	DB	0		; Requested user number
RECDNO:	DW	0		; Current record number
KIND:	DB	0		; Asks what kind of file this is
OLDDRV:	DB	0		; Save the original drive number
OLDUSR:	DB	0		; Save the original user number
OPTSAV:	DB	0		; Save option here for carrier loss
PRVTFL:	DB	0		; Private user area option flag
MSGFLG:	DB	0		; Message upload flag
SAVEHL:	DW	0		; Saves TBUF command line address
TOTERR:	DW	0		; Total errors for transmission attempt
VRECNO:	DW	0		; Virtual record # in 128 byte records
CPUMHZ:	DB	MHZ		; [WBW] CPU speed in MHz
RCVSCL: DW	SCL		; [WBW] Recv loop scalar
PORT:	DB	0FFH		; [WBW] Target serial port, FFH=not specified
;
EOFLG:	DB	0		; 'EOF' flag (1=yes)
EOFCTR:	DB	0		; EOF send counter
OUTADR:	DW	LOGBUF
OUTSIZ:	DW	BSIZE
RECPTR:	DW	DBUF
RECNBF:	DW	0		; Number of records in the buffer
;
	 IF	CONFUN AND SYSABT
SYSABF:	DB	0		; set if sysop uses ^X to abort
	 ENDIF
;
	 IF	(DESCRIB OR MBDESC) AND	NDESC
NDSCFL:	DB	0		; Used to store "RN" option
	 ENDIF			; to bypass upload descriptions
;
	 IF	DESCRIB
HLINE:	DB	'-------------------',CR,LF
OLINE:	DS	80		; Temporary buffer to store line
	 ENDIF
;
	DS	80		; Minimum stack area
;
; Disk buffer
;
	ORG	($+127)/128*128
;
DBUF	EQU	$		; 16-record disk buffer
;STACK	EQU	DBUF-2		; Save original stack address
STACK	EQU	0B000H		; [WBW] Above 8000h for HBIOS Fastpath
LOGBUF	EQU	DBUF+128	; For use with LOGCAL
;
;-----------------------------------------------------------------------
;
;			  BDOS equates
;
;-----------------------------------------------------------------------
;
RDCON	EQU	1		; Get character from console
WRCON	EQU	2		; Output to console
DIRCON	EQU	6		; Direct console output
PRINT	EQU	9		; Print string function
VERNO	EQU	12		; Get CP/M version number
SELDSK	EQU	14		; Select drive
OPEN	EQU	15		; 0FFH = not found
CLOSE	EQU	16		; "	  "
SRCHF	EQU	17		; "	  "
SRCHN	EQU	18		; "	  "
DELET	EQU	19		; Delete file
READ	EQU	20		; 0=OK, 1=EOF
WRITE	EQU	21		; 0=OK, 1=ERR, 2=?, 0FFH=no dir. space
MAKE	EQU	22		; 0FFH=bad
RENAME	EQU	23		; Rename a file
CURDRV	EQU	25		; Get current drive
SETDMA	EQU	26		; Set DMA
SETATT	EQU	30		; Set file attributes
SETUSR	EQU	32		; Set user area to receive file
RRDM	EQU	33		; Read random
WRDM	EQU	34		; Write random
CFSIZE	EQU	35		; Compute file size
SETRRD	EQU	36		; Set random record
GETTIM	EQU	105		; CP/M Plus get date/time
BDOS	EQU	0005H
TBUF	EQU	0080H		; Default DMA address
FCB	EQU	005CH		; System FCB
FCBEXT	EQU	FCB+12		; File extent
FCBRNO	EQU	FCB+32		; Record number
RANDOM	EQU	FCB+33		; Random record field
;
;	Extended BYEBDOS equates
;
	 IF	BYEBDOS
BDMIST	EQU	61		; Modem raw input status
BDMOST	EQU	62		; Modem raw output status
BDMOUT	EQU	63		; Modem output 8 bit char
BDMINP	EQU	64		; Modem input 8 bit char
BDCSTA	EQU	65		; Modem carrier status
BDCONS	EQU	66		; Local console input status
BDCONI	EQU	67		; Local console input char
BDCONO	EQU	68		; Local console output char
BDMXDR	EQU	69		; Set/get maximum drive
BDMXUS	EQU	70		; Set/get maximum user area
BDNULL	EQU	72		; Set/get nulls
BDTOUT	EQU	71		; Set/get idle timeout
BDULCS	EQU	73		; Set/get upperlowercase switch
BDLFMS	EQU	74		; Set/get line-feed mask
BDHRDL	EQU	76		; Set/get hardlog
BDWRTL	EQU	75		; Set/get writeloc
BDMDMO	EQU	77		; Set/get mdmoff flag
BDBELL	EQU	78		; Set/get bell mask flag
BDGRTC	EQU	79		; Get address of rtc buffer
BDGLCB	EQU	80		; Get address of lc buffer
BDSTOS	EQU	81		; Maximum time on system
BDSLGT	EQU	82		; Set login time
BDPTOS	EQU	83		; Print Time on System
	 ENDIF			; BYEBDOS
;
	END
