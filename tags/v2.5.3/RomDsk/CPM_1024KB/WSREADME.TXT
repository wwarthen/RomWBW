			--THE README FILE--
		      ------------------------

README contains late-breaking news and tips about WordStar,
and information about printers.


THE DISKS THAT CAME IN YOUR PACKAGE
-----------------------------------

The file HOMONYMS.TXT is included on the Speller disk
contrary to what is listed in Appendix D.


INSTALLATION
------------

WINSTALL and WSCHANGE

  WordStar has two installation programs:

  o  WINSTALL contains the basic choices to install WordStar.
     It is recommended for all users.

     Be sure and install your valid disk drives since WordStar 
     running under CP/M cannot recover from attempts to access non-
     existent disk drives.

  o  WSCHANGE contains every installation and customization
     choice.  It is designed for advanced users and users who
     want to customize WordStar after they're familiar with it.
     Use the menu listing below for a directory of the menus
     in WSCHANGE.

Directory of WSCHANGE Menus

  The chart below shows the organization of menus in WSCHANGE.
  Print it out and refer to it as you customize WordStar.

  Main Installation Menu

  A Console
    A Monitor
      A Monitor selection
      B Monitor name
      C Screen sizing
    B Function keys
    C Monitor patches
      A Special characters
      B Cursor control
      C Screen control
    D Keyboard patches
      A Function keys
      B Save function keys
    E Interface patches
      A Console busy handshaking
      B Special I/O subroutines
  B Printer
    A Printer choices
      A Printer selection
      B Printer name
      C Default printer driver
    B Printer driver library
      A Select library file
      B Create smaller library
      C Add new printer driver
      D Change printer driver data
    C WS printer patches
      A Custom print controls, printer initialization

  NOTE:  Disregard the "CUSTOM & SIMPLE Controls  Save CUSTOM/SIMPLE
  Controls" option shown.  This is not available from this menu.

    D Printing defaults
    E Printer interface
      A Printer port selection
      B Printer busy handshaking
      C Printer subroutines
  C Computer
    A Disk drives
      A Valid disk drives
      B Maximum valid user number
      C Delay disk access if typing
    B Operating system
      A Single-user system
      B Multi-user MP/M
      C Multi-user Turbo DOS
      D ZCPR3
    C Memory usage
    D WordStar files
    E Directory display
    F Computer patches
  D WordStar
    A Page layout
      A Page sizing & margins
      B Headers & footers
      C Tabs
    B Editing settings
      A Edit screen & help level
      B Typing
      C Paragraph alignment
      D Blocks
      E Erase & unerase
      F Lines & characters
      G Find & replace
      H WordStar 3.3 compatibility
      I Printing defaults
    C Other features
      A Spelling checks
      B Nondocument mode
      C Indexing
      D Shorthand (key macros)
      E Merge printing
      F Miscellaneous
  E Patching
    A Auto patcher
    B Save settings
    C Reset all settings

MEMORY USAGE
------------

  WordStar requires a minimum TPA size of 50 kbytes to run  
  using the factory defaults.  The TPA is the amount of memory  
  available in your computer for use by programs that have a  
  file type of COM.  To see how big the TPA is in your computer,
  press the question mark key (?) at the Opening Menu.

  The amount of memory required by WordStar can be reduced by 
  approximately 3 kbytes if necessary.  Use the WSCHANGE program 
  to select the minimum memory configuration option.  The menu  
  will show you what capabilities are being reduced.

  WordStar uses a general-purpose buffer for a variety of  
  tasks.  WordStar allocates memory to this buffer for editing,  
  for merge printing, and at the Opening Menu (see BFSIZE in 
  PATCH.LST).  The buffer used for editing is usually the most 
  sensitive to a reduced TPA size.  (You may be able to use the 
  Opening Menu and print, but there may be insufficient memory 
  for editing.)

  The merge print buffer is used only to hold merge print  
  variable names and data.  Increase it if you run out of memory 
  while merge printing.

  The  Opening Menu buffer is used primarily to hold the file 
  directory, and for miscellaneous tasks.


LOW-MEMORY INDICATOR IN STATUS LINE 
-----------------------------------

  If the Low-Memory indicator appears in the status line, it  
  means that WordStar was unable to complete some function.   
  The most common symptoms are:  the line number in the  
  status line is wrong, or a paragraph alignment could not be 
  completed. You may correct the line counter by saving your 
  file, exiting WordStar, and re-loading your file.  To correct 
  the paragraph alignment, move your cursor to the point where 
  paragraph alignment stopped, and then press ^B again.

  The reason this comes up is that WordStar was not able to fit  
  a big enough chunk of text into memory at one time.

  When you first begin editing, WordStar uses the value from 
  EDSIZE in the user area to determine the minimum amount  
  of memory required for a page of text.  The default  
  is set for approximately a 55 line by 66 column page.  If 
  your page size is routinely larger than this, you may want  
  to increase EDSIZE.  Multiply the number of lines by the 
  number of columns, and divide by 128.

  If the Low-Memory indicator comes on while printing, it is due 
  to either the same reasons as for editing, or there is  
  insufficient memory to print the text proportionally spaced.  
  The amount of memory required depends on which printer 
  driver you  are using.  If you aren't using the .PS ON dot 
  command to turn proportional spacing on in your document, 
  low memory won't be a problem.  Also, WordStar uses more 
  memory for merge printing than it does for regular printing 
  (around 2.5 kbytes more).

  The Low-Memory indicator will also appear when a full disk error
  is encountered during editing.  Treat the disk-full error as you
  would normally.


RAM-RESIDENT PROGRAMS
---------------------

  RAM-resident programs, such as SmartKey, reduce the amount of 
  working memory (TPA) that WordStar can use. The new features in 
  WordStar, such as shorthand, may reduce the need for these 
  RAM-resident programs, thus freeing memory for WordStar.


ZCPR3 SUPPORT
-------------

  In order to enable the ZCPR facilities within WordStar, the user 
  must use the Z3INS utility provided with ZCPR to install the 
  address of the ZCPR "environment" into WordStar. The environment 
  contains information that WordStar uses to support ZCPR-specific 
  functions.
  
  Generally, the user should log onto the drive containing the file 
  WS.COM, and issue the command:
  
  	Z3INS SYS.ENV WS.COM
  	
  The user should also run either WINSTALL or WSCHANGE to further 
  install WordStar for ZCPR. However, this is not mandatory because 
  the only thing that happens is that the WordStar sign-on says 
  "ZCPR3," and the LGLUSR location in the user area is changed for a 
  maximum user number of 31. (The normal default for LGLUSR is 15.)
  
  Once the user has installed WordStar for use with ZCPR, the user 
  will be able to use the following ZCPR features:
  
  - A named directory may be used when logging onto a new drive/user.
  	
  - A named directory may be used instead of a drive/user as part
    of any file name.
  	  
  - The drive/user always appears above file directories. (For CP/M
    only the drive letter is shown if the user number is zero.)
  	  
  - The directory name also appears above the directory if one has
    been defined for the currently logged drive/user.
  	  
  - If WordStar does not find its OVR files on the current drive and
    user, it will search the drives and user numbers in the ZCPR
    search path rather than using its standard search pattern.
  	  
  - WordStar installs itself as a ZCPR "shell" process which lets the
    user enter any legal ZCPR command when running a program. (CP/M
    can only run programs that are COM files.)


OSBORNE USERS
-------------

  The command to change a hard carriage return to a soft carriage
  return (document mode) or to turn Auto-indent ON (nondocument
  mode) does not function on the Osborne because of a limitation
  in its BIOS.  The following patch can be applied to change the
  command from ^^ to ^- (Ctrl-Hyphen):

  Using DDT or SID in the file WSMSGS.OVR:

	At 02DA replace 1E with a 1D
	At 02EF replace 1E with a 1D
	At 0359 replace 1E with a 1D
	At 06B2 replace 1E with a 1D
	At 06C9 replace 1E with a 1D

  At the system prompt type SAVE 53 WSMSGS.OVR

  For more information on how to use SID or DDT, see your CP/M
  reference guide.  As always, be sure and apply the patch to a
  COPY of the file.


INSTRUCTIONS FOR TWO FLOPPY DISK COMPUTERS
------------------------------------------

  Do not remove the Program disk while you are using WordStar.

  The Printer Driver Library file (WSPRINT.OVR) on the WordStar 
  program disk is much smaller than the Printer Driver Library 
  file contained on the disk labeled PRINTER. Be sure to read the 
  section in "Starting" that discusses the printer library file.


RUN A PROGRAM
-------------

  Once you press R you can type the drive and user number for the 
  program you want to run. You may run only .COM files. CCP commands, 
  such as DIR cannot be used. 


INDEXING
--------

Using StarIndex

  StarIndex 1.01 works with files created with this release of
  WordStar.  

"Can't Use That Printer" Message

  When WordStar creates an index or table of contents, it uses
  the printer drivers $INDEX and $TOC.  If you created a smaller
  WSPRINT.OVR file, you may have left these drivers out.  To
  return them to the file, copy the original WSPRINT.OVR file
  onto your disk.  When you create a smaller file again, be sure
  to save these drivers.  See Appendix C in the WordStar manual 
  for a list of other drivers to save.


SPELL CHECKING
--------------

  Dual floppy disk users:
  
  Unless you have sufficient room on your working WordStar program 
  disk for the files TW.COM, SPELL.COM, MARKFIX.COM, REVIEW.COM and 
  MAINDICT.CMP you will not be able to run a spell check from the 
  Opening Menu.  You will need to exit WordStar and replace the 
  working WordStar program disk with the dictionary disk you created 
  during installation.  This disk should contain the files listed 
  above.  Make sure the disk in drive B has the file you want to 
  spell-check.
  
  Follow the directions for running a spell check in The WORD Plus 
  manual. 
  

UPGRADING FROM A PREVIOUS RELEASE
---------------------------------

  This release of WordStar contains many new features and commands.
  See the "What's New" booklet for a complete list.  The following
  changes came in too late to be included in the documentation.

Printer Patches

  Previous versions of WordStar treat most dot matrix printers 
  and other non-daisy wheel printers as a DRAFT printer with a 
  few patchable items. Because of this, many users have used 
  these patches to be able to use certain features of their 
  printers. Sometimes the patches have been quite extensive, and 
  some users have many files that count on them.

  The printer drivers of WordStar Release 4, on the other hand, 
  are very powerful. Almost every driver recognizes all the print 
  controls and all the dot commands. In fact, if a document is 
  written to be printed on one kind of printer, it is likely that 
  it will also print fine on some other printer.

  However, if you want to use your existing files with WordStar 
  4, and those files rely on the user area being patched in a 
  special way, you can probably do so by moving the patches into 
  WordStar 4, and using the CUSTOM or SIMPLE printer driver.

  On the INSTALL disk is a program called MOVEPRN.COM that 
  copies the printer driver portion of the previous release's 
  user area into files that can be installed into Release 4 with 
  the "auto patcher" feature.

  Copy the program MOVEPRN.COM onto the disk containing the 
  WS.COM file for the previous version. Type 

     MOVEPRN WS.COM FILE1.PAT FILE2.PAT

  MOVEPRN extracts the proper portions of the user area and 
  writes them into two files that may then be used with the "auto 
  patcher" feature of WSCHANGE.

  FILE1.PAT is to be used with the general patching menu 
  (Choose E "Patching" on the WSCHANGE Main Menu, then A "Auto 
  Patcher").  FILE2.PAT should be used to install strings first 
  into the SIMPLE driver, and then into the CUSTOM driver (choose
  B "Printer" on the WSCHANGE Main Menu, then B "Printer driver
  library", D "Change printer driver data" and D "Driver auto
  patcher").

  Test print your document first with the SIMPLE driver, and then 
  with the CUSTOM driver to see which one produces the most 
  satisfactory results.
  
  Also read Appendix C for more information on using the Auto 
  Patcher.


Hanging Indents

  For WordStar Professional Release 4, MailMerge reformats indented 
  text created with ^OG to the current margins.  If you want the text 
  to remain  indented, use embedded ruler lines or the .RM, .LM, 
  and .PM commands.  See the "Reference Guide" for more information.

  Pressing ^OG to wrap back to the first tab on the ruler line after 
  having reached the last tab works the same way it did in previous 
  versions of WordStar, contrary to what is stated in the manual.


TERMINALS
---------

  WordStar comes installed for an "idealized" special terminal. 
  WINSTALL and WSCHANGE allow you to install many terminals by 
  name, thus allowing WordStar to take advantage of the special 
  features that the terminal might support, such as underlining 
  or the function keys.
    
  Use either WINSTALL or WSCHANGE to pick your specific terminal 
  or computer screen from the Monitor menu.  If your terminal 
  isn't on the menu, it probably emulates one of those that is 
  there.   Look in your terminal documentation to find out.

  After you install WordStar for the proper terminal, run 
  WordStar and open the file PRINT.TST to see  which attributes 
  (such as bold and underline) work on your screen.  
  WordStar will highlight the following in some way...

     Bold           (^PB)
     Underline      (^PS)
     Strike-out     (^PX)
     Subscript      (^PV)
     Superscript    (^PT)
     Doublestrike   (^PD)
     Italics        (^PY)
     Blocks         (^KB, ^KK)
     Error messages

  Most of the time, normal text will be shown in dim intensity, 
  and highlighted text will be shown in bright intensity.  You 
  may have to use a brightness and/or contrast knob to adjust  
  your screen the first time you use WordStar this way.

  If your dim intensity is too dim to see well, and you can't  
  adjust it, you can change the BRITE flag to ON using WSCHANGE.  
  This will invert bright and dim in your text, so that regular 
  text is displayed bright, and highlighted text will be 
  displayed as dim. However, text in the menus is not affected.


DISPLAY PROBLEMS WITH TERMINALS
-------------------------------

  Once you have installed WordStar for the proper terminal, you 
  may still experience display problems.

  If text from the previous screen remains after WordStar 
  displays a new screenful of text, the most likely cause is 
  cursor wrap.  Basically, WordStar must know what happens to the 
  cursor when a character is displayed at the rightmost position 
  of the screen.  It can either remain at the right edge, or it 
  can wrap to the beginning of  the next  line.  The WRAP flag in 
  WordStar must be set either on or off to correspond to the 
  way the terminal works.  (It is generally set for the 
  terminal's factory default, but the default can usually be 
  changed using the terminal's setup mode.)

  Another possible cause for display problems is your terminal's 
  incomplete emulation of some other terminal.  The most 
  common differences are...

     Line insert (LININS), line delete (LINDEL),
     Erase to end of screen (ERAEOS),
     Erase to end of line (ERAEOL),
     And, erase screen (ERASCR).

  Look in the manual for your terminal and use WSCHANGE to see  
  if the control sequences match.


PRINTERS
--------

WHAT'S IN THIS SECTION

  This section contains the following information:

  Choosing a Printer
  Setting Up Your Printer
  Printer Drivers
  Proportional Printing
  Laser Printers
  Information on Specific Printers

CHOOSING A PRINTER

  WordStar is ready to work with over 100 printers. The printer you
  choose during installation becomes your default printer. However, 
  when you print a document, you can choose any other printer. To 
  choose a default printer, follow these steps:

  1. Look at the Printer Information brochure that came in your 
     package.  The first chart shows the printers listed on the 
     Printer Selection Menus. If your printer is on the menu, 
     simply choose it during installation.

  2. If your printer isn't listed on the menu, it may work like a
     printer that is. Refer to the second chart in the Printer
     Information brochure for a list of printers that work like
     printers on the menu. When WordStar asks you to choose a
     printer, choose the printer that works like yours.

  3. If neither chart lists your printer, choose Typewriter Printer
     (if your printer can backspace) or Draft Printer (if it can't).
     These choices may not take advantage of all your printer's
     features, but they will work with almost any printer.
 
  Note:  If you choose Draft or Typewriter, you can modify custom
  print controls and printer initialization.

  If you want to make more modifications to take advantage of your
  printer's feature, choose the Custom or Simple drivers, then use 
  the WS Printer Patches section of WSCHANGE to tell WordStar the 
  codes for your printer. Refer to your printer manual for these 
  codes. Some printers work better with the Custom driver and some
  with the Simple driver. Try using both and see which works better 
  with your printer. See the "Reference Guide" for more information. 

SETTING UP YOUR PRINTER

Choosing a Printer Port

  Each printer is connected to a printer port at the back of
  the computer. WordStar looks for printers on the LST: port.
  If your printer is connected to a different port, use
  WSCHANGE to tell WordStar the correct port.

Testing Your Printer Connection

  At the operating system prompt, type "PIP LST:=READ.ME." This 
  file should be printed by your printer. If it is not, your printer 
  may be connected to a different port. See your computer reference 
  manual, and the section on the STAT command in your CP/M 
  reference manual for more information.


PRINTER DRIVERS

  The WSPRINT.OVR file on the Printers disk contains a printer 
  driver for each printer on the Printer Selection Menu. The printer 
  driver for a printer contains all the codes WordStar needs to work 
  with that printer.  
  
  Each printer driver has a short name. If you choose a printer when
  you print a document, you see the names of the printer drivers, not
  the names of the printers.

PROPORTIONAL PRINTING

  WordStar supports proportional printing on a number of printers.
  To turn on proportional printing, either install WordStar to
  default to proportional printing, or place a ".PS on" command
  in your document. At print time, WordStar selects the
  appropriate proportional font based on the character width
  (.CW) currently in effect.

  The specific printer descriptions later in this section show
  recommended character widths for proportional typefaces.
  These widths are for a normal mix of upper- and lowercase
  letters. If you have many words or phrases all in uppercase
  or if you want your text less densely printed, choose a larger
  character width.

  While WordStar mostly sets character widths based on the
  proportional-width table in the driver, on the more advanced
  daisy wheel printers, WordStar uses the printer's proportional-
  spacing mode. WordStar determines how much white space is needed
  to right-justify the line based on its own proportional width 
  tables. If the table values don't match the wheel installed,
  WordStar won't be able to justify the line correctly.

  WordStar sends standard ASCII characters; if a proportional wheel 
  uses a different spoke mapping, set up the printer to handle this.

LASER PRINTERS

  WordStar supports laser printer features such as font changes
  and proportional spacing.

  WordStar supports several laser printers: the Canon LPB-8 A1 & A2;
  the Hewlett-Packard LaserJet, LaserJet+, and LaserJet 500+; 
  and the Ricoh LP4080. Refer to the "Specific Printer
  Information" section of this file for information on these 
  printers. General notes about using laser printers are given below.

Paper Size and Margins

  Laser printers come with preset page margins. You need to 
  compensate for these margins by changing page length in your 
  WordStar documents. The chart below shows the recommended 
  settings for 8 1/2 X 11 inch paper for both portrait and landscape 
  orientations. These settings allow 55 lines of text for portrait 
  orientation and 40 lines of text for landscape orientation (at 6 
  lines per inch). They also allow for a footer of up to 3 lines 
  and a one-line header. If you use multiple-line headers, adjust 
  the top margin accordingly.

                 Dot      Default  Portrait     Landscape
  Setting        Command  Value    Orientation  Orientation
  -------        -------  -------  -----------  -----------
  page length     .PL       66         62           47
  top margin      .MT        3          2            2
  bottom margin   .MB        8          5            5
  header margin   .HM        2          1            1
  footer margin   .FM        2          2            2

  If the laser printer is your primary printer, you can use WSCHANGE
  to make these settings the defaults.

  Because laser printers leave small margins at the left and right
  sides of the page, you may want to use a smaller page offset 
  setting (the default is .PO 8).

Form Feeds

  When you print with a laser printer, answer Y for yes to the "Use
  form feeds (Y/N)?" prompt at print time. (The default is NO.) If
  the laser printer is your primary printer, you can use WSCHANGE to
  change the default to yes.

WordStar Commands for Font Selection

  The WordStar dot commands and print control commands listed below
  determine the fonts used for printing a document.

  .PR  .PR OR=L selects landscape orientation; .PR OR=P (or just
       .PR OR) selects portrait orientation (the default). If
       either of these commands appears after the first printing
       line on a page, the orientation will not change until the
       following page. 

  .PS  .PS ON selects proportionally spaced characters; .PS OFF
       (the default) selects fixed-spaced characters.

  .CW  The character-width setting (.CW followed by the width in
       120ths of an inch) determines the character pitch and font
       selected for fixed-width printing. For proportional fonts, it
       determines the point size and proportional-width table 
       selected.

  .LQ  .LQ ON selects near letter quality print (if supported by
       your printer).  LQ OFF selects draft quality print.  Default
       is ON.

  ^PY  The italic print control toggles between normal and italic
       characters when the appropriate italic font is available.

  ^PB  The boldface print control toggles between normal and bold
       characters when the appropriate bold font is available.

  ^PD  The double strike print control used with the laser printers
       toggles overprinting with a horizontal offset of 1/120"
       between the two character images. This allows a bold effect
       where no bold font is available. 

  ^PA  ^PA turns alternate pitch on. Use .CW to assign different
       character widths to normal pitch (see ^PN below) and alternate
       pitch so that each pitch accesses a different font. You can 
       then change fonts by switching between the two pitches. This 
       is the only way to use two fonts on the same line. 
       (See "Character width" and "Pitch" in the "Reference Guide.")

  ^PN  ^PN turns normal pitch on. You can use it with ^PA as
       described above.

  ^P@  When working with columns, if you use alternate and normal
       pitch for two fonts, or if you use proportional spacing, you
       may need to use ^P@ to make sure the columns line up.
       Remember that the column position set with ^P@ is determined
       by the normal pitch character width. (See "Columns" and
       "Proportional spacing" in the "Reference Guide." 

INFORMATION ON SPECIFIC PRINTERS

  This section describes the capabilities of each printer listed on 
  the Printer Selection Menu. The printers are listed in alphabetical 
  order (except for the generic printers such as "Draft," 
  "Typewriter," "Custom," "Simple," and the various print-to-disk 
  options, which are listed first).  

  There is a chart for each printer explaining how features work and 
  listing any special notes about the printer.  Each printer is 
  described in the following format:

PRINTER NAME ----- Driver: (short name)

 ^PY    Effect of italics/ribbon color print control
 ^PT/V  Subscript/superscript information
 .CW    Information on available character widths and fonts.  The
        chart shows the .CW, .LQ, and .PS settings required to use 
        different fonts.

        .LQ OFF   .LQ ON    .PS ON                      Font Name
        -------   ------    ------                      ---------
        .cw val   .cw val   recommended value (range)   font 1
        .cw val   .cw val   recommended value (range)   font 2

 .UL    Continuous-underline information (if restrictions)
 .UJ    Microspace-justification information (if restrictions)

        N/A means a command has no effect on this printer.

 NOTES  Switch settings, special features, anomalies.

DRAFT PRINTER (nonbackspacing) ----- Driver: DRAFT

 ^PD    Overprints the line twice
 ^PB    Overprints the line three times
 ^PS    Overprints the underscore character in a separate pass
 ^PT/V  Prints super/subscripts with a full line between
        super/subscript and text
 .LH    Sets line height only in multiples of full lines
 .CW    N/A
 .PS    N/A
 .LQ    N/A
 .UJ    N/A

 NOTES  This driver works with any printer that doesn't automatically
 perform a line feed when it receives a carriage return command.  All
 overprinting is done by returning the carriage and passing over the
 line again.

TYPEWRITER PRINTER (backspacing) ----- Driver: TYPEWR

 ^PD    Backspaces and overprints each character twice
 ^PB    Backspaces and overprints each character three times
 ^PS    Backspaces and overprints the underscore character
 ^PT/V  Prints super/subscripts with a full line between
        super/subscript and text
 .LH    Sets line height only in multiples of full lines
 .CW    N/A
 .PS    N/A
 .LQ    N/A
 .UJ    N/A

 NOTES  This driver works with any printer that doesn't automatically
 perform a line feed when a it receives a carriage return command,
 and responds to a backspace character.  Overprinting is done by
 backspacing.

AUTO LINE FEED PRINTER (backspacing) ----- Driver: AUTOLF

 ^PD    Backspaces and overprints each character twice
 ^PB    Backspaces and overprints each character three times
 ^PS    Backspaces and overprints the underscore character
 ^PT/V  Prints super/subscripts with a full line between
        super/subscript and text
 .LH    Sets line height only in multiples of full lines
 .CW    N/A
 .PS    N/A
 .LQ    N/A
 .UJ    N/A

 NOTES  This driver works with any printer that automatically
 performs a line feed when it receives a carriage return character,
 and responds to a backspace command.  Overprinting is done by
 backspacing.

SIMPLE CUSTOMIZABLE PRINTERS ----- Driver: SIMPLE

 All print controls cause control strings (on and off) in
 the user area to be sent to the printer.  These strings
 are used by both the SIMPLE and CUSTOM drivers.  They can
 be installed with the WSCHANGE program.

 .LQ    Controlled by user area strings
 .PS    Controlled by user area strings
 .CW    N/A
 .UJ    N/A
 .LH    N/A

 NOTES  This printer driver prints the line in one pass, sending
 control strings from the user area to select print enhancements.

CUSTOMIZABLE PRINTERS ----- Driver: CUSTOM

 All print controls cause control strings (on and off) in
 the user area to be sent to the printer.  These strings
 are used by both the SIMPLE and CUSTOM drivers.  They can
 be installed with the WSCHANGE program.

 .LQ    ON/OFF controlled by user area strings
 .PS    ON/OFF controlled by user area strings
 .LH    Sets line height only in multiples of full lines
 .UJ    N/A
 .CW    N/A

 NOTES  This driver prints the line in multiple passes, sending
 control strings from the user area to select print enhancements.

PREVIEW TO DISK ----- Driver: PRVIEW

 This driver prints documents to the PREVIEW.WS file to allow
 you to preview the format and appearance of a document before
 printing. Headers, footers, and pagination are shown correctly
 and print controls remain in the file to display onscreen
 attributes.  Dot commands are not printed.

PRINT TO DISK WITHOUT PRINT CONTROLS ----- Driver: ASCII

 This driver prints to the ASCII.WS file, stripping headers and
 footers, high bits, and print controls.

PRINT TO DISK WITHOUT HEADERS AND FOOTERS ----- Driver: XTRACT

 This driver prints to the XTRACT.WS disk file, stripping headers
 and footers, but preserving high bits and print controls.

ANADEX 9500A, 9500B ----- Driver: 9500

 ^PY    N/A
 ^PT/V  Even superscript roll

 .CW    .CW  Font name
        ---  ---------
         9   13.3 cpi
        10   12   cpi
        12   10   cpi
        18    6.7 cpi
        20    6   cpi
        24    5   cpi

 .LH    1/24" resolution, use even values
 .UJ    This printer has no incremental horizontal positioning
 .PS    N/A
 .LQ    N/A

ANADEX 9501B, INTEQ 5100B ----- Driver: 9501B

 ^PY    N/A
 ^PT/V  Even superscript roll

 .CW    .CW  Font name
        ---  ---------
         7   16.7 cpi
         8   15   cpi
        10   12.5 cpi
        12   10   cpi
        14    8.3 cpi
        16    7.5 cpi
        20    6.2 cpi
        24    5   cpi

 .LH    1/24" resolution, use even values
 .UJ    This printer has no incremental horizontal positioning
 .PS    N/A
 .LQ    N/A

C. ITOH STARWRITER 1550 AND 8510 ----- Driver: C1550

 ^PY    N/A
 ^PT/V  Prints full-size characters with roll

 .CW    .CW  Font Name
        ---  ---------
         7   compressed
        10   elite
        12   pica
        14   expanded compressed
        20   expanded elite
        24   expanded pica

 .LQ    N/A
 .PS    N/A
 .UL    Continuous underlining suppresses microspace justification

C. ITOH F10 STARWRITER ----- Driver: QUME

 See Diablo 630, 1610, 1620 Daisy Wheel.
 
 Note:  Proportional printing was tested with a Theme 10 wheel.

CANON LBP-8A1 AND LBP-8A2 LASER PRINTER ----- Driver: LBP8

 ^PY    Selects italics if appropriate font installed
 ^PT/V  Prints full-size characters with roll
         .PS .PS
 .CW     OFF  ON           Font Name
         ---  --           ---------
          6   -            20 cpi
          8   -            15 cpi
          9   -            13.3 cpi
         10   -            12 cpi (elite)
         12   -            10 cpi
         20   -            6 cpi
         24   -            5 cpi
         16   -            7.5 cpi
         -     7 (0-8)     Garland 8 point
         -    10 (9-11)    Garland 12 point
         -    14 (12-17)   Expanded 8 point
         -    20 (18-30)   Expand