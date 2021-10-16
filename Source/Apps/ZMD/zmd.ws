. MARGINS: RIGHT=65; LEFT=
.op
.he** 09/29/88 **   ZMD Reference Manual - Version 1.50      
.foCopyright (c) 1987, 1988  Robert W. Kramer III  ALL RIGHTS RESERVED
 



















            ZMD File Transfer Program for the Z80 RCP/M

                 External Reference Specification

                       ZMD - Version 1.50
.PA�.pn 1
.he** 09/29/88 **   ZMD Reference Manual - Version 1.50         Page #

�����CONTENTS

�����1.�       Introductio� t� ZMD..........................� 4

�����2.�       Applicabl� Files.............................� 5

�����3.�       Installation.................................� 8

�����  3.�     Loca� CR� Clea� Scree� Sequences.............. 8

�����  3.�     Input/Output.................................. 8
�����    3.2.� Mode�......................................... 8
�����    3.2.� Microprocesso� Speed.......................... 9
�����    3.2.� Mode� Spee� Indicato� Byte.................... 9
�����    3.2.� Dis� Writ� Loc� Flag.......................... 9
�����    3.2.� Sleep� Calle� Timeout......................... 9
�����    3.2.� Minimu� Spee� fo� 1� Blocks................... 9
�����    3.2.� File Transfer Buffer Queue.................... 10
�����    3.2.� Pag� Pausing.................................. 10
���������3.2.9 Automatic Calculation of Disk Buffer Size..... 10

�����  3.�     Timekeeping................................... 11
�����    3.3.� MBYE/BYE� Cloc� Support....................... 11
�����    3.3.� ZM� Interna� Clock/Dat� Reade� Code........... 11
�����    3.3.� Restrictin� Download� t� Tim� Left............ 12
�����    3.3.� Maximu� Tim� Allowed.......................... 12
�����    3.3.� Displa� Tim� o� Syste� messages............... 12
�����    3.3.6 Logon Hour/Minute Addresses................... 12

�����  3.�     Acces� Restrictions........................... 13
�����    3.4.� ZCMD/ZCPR..................................... 13
�����    3.4.� WHEE� Byte.................................... 13
�����    3.4.� Maximu� Drive/User............................ 13
�����    3.4.� BYE/BB� Progra� Acces� Fla� Byte.............. 13

       3.�     Uploa� Configuration.........................� 14
�����    3.5.� Preformatte� BB� Messag� Uploads.............. 14
�����    3.5.� Hidin� Ne� Upload� Unti� Approve� b� Sysop.... 14
�����    3.5.� Uploa� Routin� t� Multipl� Drive/Users........ 14
�����    3.5.4 Uploadin� t� Specifie� Drive/User............. 14
�����    3.5.5 Receivin� Privat� Uploads..................... 15
�����    3.5.� Creditin� Uploa� Tim� t� Tim� Left............ 15
�����    3.5.� Receivin� .CO� File� Securely................. 15

�����  3.�     Uploa� Descriptions........................... 16
�����    3.6.� Forwardin� Description� t� BB� Messag� Base... 16
�����    3.6.� Forwardin� Description� t� FO� Tex� File...... 16
�����    3.6.� Desriptio� Fil� Filename/Drive/User........... 16
�����    3.6.� Uploa� Descriptio� Heade� Information......... 17
�����    3.6.� Includin� Fil� Descriptors.................... 17
�����    3.6.� Includin� Uploa� Drive/Use� Area.............. 17
�����    3.6.� Datestampin� th� Descriptio� Header........... 17
�����    3.6.� Overridin� Descriptio� Requests............... 17
�����    3.6.� Automati� Wor� Wrap........................... 18�
�����  3.�     Downloa� Configurations....................... 19
�����    3.7.� Restrictin� .LB� an� Singl� F� Tagge� Files... 19
�����    3.7.� Disallo� Sendin� .CO� Files................... 19
�����    3.7.� Disallo� Sendin� .??� Files................... 19
�����    3.7.� Disallo� Sendin� F� Tagge� $SYSte� Files...... 20
�����    3.7.� Sendin� F� Tagge� File� Regardles� o� Access.. 20
�����    3.7.� Specia� Syso� Download� t� Selecte� Caller.... 20

�����  3.�     Logkeeping.................................... 21
�����    3.8.� Makin� ZMD.LO� File..........................� 21
�����    3.8.� Europea� Dat� Forma� (DD/MM/YY)............... 21
�����    3.8.� Transfe� Lo� Drive/User/Filename.............. 21
�����    3.8.� LASTCAL� Fil� Information..................... 21
�����    3.8.� Countin� Fil� Transfer� fo� BB� Software...... 21

.pa�
�����APPENDICES


�����APPENDI� A.............................................. 23

�����  A.�     Modem Interface............................... 23
         A.1.1 Creating Modem I/O Overlays................... 23
         A.1.2 Installing Modem I/O Overlays................. 23


�����APPENDI� B.............................................. 25

�����  B.�     RT� Clock/Dat� Reade� Cod�.................... 25


�����APPENDI� C.............................................. 26

�����  C.�     Fil� Descriptors/Categories................... 26


�����APPENDI� D.............................................. 27

�����  D.�     Uploa� Routin� Table.......................... 27
.pa�
�����1.�       Introductio� t� ZMD

�����ZMĠ i� � Remot� CP/� Fil� Transfe� Progra� writte� i� �
�����MICROSOFԠ MACRO-8� languag� usin� ZILO� Z8�� assembler�� I� �
�����wil� ru� o� an� Z8� microprocesso� usin� CP/� � o� �� an� �
�����provide� ful� suppor� fo� system� runnin� ZCM� o� ZCPҠ CC� �
�����replacement� ZM� ca� b� configure� t� ru� unde� mos� popula� �
�����remot� consol� programs�� bu� i� primaril�� targete� fo� �
�����BYE5+�� MBY� an� BYE3� o� a� a� entirel� stan� alon� progra� �
�����usin� modem/por� overlay� fo� mode� I/O��  Ful� suppor�� i� �
�����provide� fo� mos� o� th� popula� BB� softwar� suc� a� PBBS� �
�����MBBS�� RBBS� Metal� Oxgate� ZBB� an� others�  Communication� �
�����program� suc� a� MODEM7� MEX� MEX+� PROCOMM� ProYam� QMODEM� �
�����IM� an� other� ar� al� als� full� compatible.

�����Thi� manua� i� no� intende� t� b� specifi� i� detai� t� �
�����th� interna� characteristic� o� ZM� an� utilities��  I�� wa� �
�����writte� a� � guid� t� hel� th� implemente� decid� whic� o� �
�����th� option� an� feature� wil� b� use� o� hi� system�

�����A� interna� referenc� manua� coverin� th� ZMDSUBS.RE̠ fil� �
�����an� user'� manua� ha� bee� i� th� making�� Additiona� �
�����modem/por� overlay� wil� b� adde� t� th� ZMDOVLn.LB� fil� a� �
�����the�� ar� created�� � ZMDCLOCK.LB� i� bein� considere� fo� �
�����organizin� approve� RT� inserts��  Ther� ar� man�� planne� �
�����features��  I� yo� hav� an� idea� fo� change� o� additions� �
�����fee� fre� t� contac� me.

�         Robert W. Kramer III       RI RCPM-RDOS  (128mb)
�         1569 40th St.              300/1200/240� - 24hrs
�         Rock Island, Il  61201     Data:  (309) 786-6227
�����                                Voice��(309� 786-671�

�����Features:

�����   � Men� drive� instal� progra� with intelligence
�����   o  Automatic installation of new releases
�����   � User definable mode�/port I/� routine�
�����   � � secon�s to gather 255 filenames in batch mode!
�����   o  Multiple drive/users fully supported in Batch send
�����   o  Overlayable .COM file installation
�����   o  Upload routing to multiple drive/user areas
�����   o  Time and Datestamping in upload description header
�����   o  100% MBYE/BYE3/BYE5 compatible
        o  Truly capable of standalone operation
�����   o  Automatic batch enable (eliminates the 'SB' command)
�����   o  Automatic 'k' block detection of host
�����   o  Fully CP/M 2.n and CP/M 3.n compatible
�����   o  ARC/ARK/LBR member extraction support
�����   o  Automatic BYEBDOS - I/O overlay detection
�����   � Faste� erro� checkin� resultin� i� quicker transfers
        o  No delays between files in batch transfers
.pa�
�����2.0        Applicable Files

�����Filenam�     K�                    Purpose
�����ZMDHDR .Z80          Thi� fil� contain� al� th� progra� �
��������������������������switche� an� value� looke� a�� b�� al� �
��������������������������th� ZM� programs��  I� i� no� neede� i� �
��������������������������usin� th� installatio� progra�ZINST�.�

�����ZMDSUBS.REL�          Contains the common subroutines for all �
                          ZMĠ an� suppor� utilities��  Thi� i� �
��������������������������use� whe� linkin� � newl�� assemble� �
��������������������������versio� o� on� o� th� programs�  Sourc� �
��������������������������cod� i� no� release� fo� thi� file�

�����ZINSTL .COM          Thi� i� th� instal� progra� use� t� 
�����                     configur� th� ZMD an� utilit� programs�  �
��������������������������Whe� firs� ran�� ZINST� read� th� firs� �
��������������������������1�� record� o� ZMD.CO� o� th� curren� �
��������������������������drive/user��  I� no� found� prompt� fo� �
��������������������������� ne� drive/use� t� lo� int� an� trie� �
��������������������������again��  �� fas�� an� eas� t� us� men� �
��������������������������drive� displa�� showin� al젠 curren� �
��������������������������progra� settings�� Afte� editin� an� o� �
��������������������������th� switches/values� � selectio� o� 'J� �
��������������������������i� th� mai� men� wil� writ� th� curren� �
��������������������������configuratio (firs�� 11� record� o� �
��������������������������ZINSTL�� bac� t� ZMD an� AL̠ o� it'� �
��������������������������utilities�  Us� i� o� th� fl� t� chang� �
��������������������������switche� an� value� quickl�� withou� �
��������������������������havin� t� reassembl� anything�� Thi� �
��������������������������take� onl� second� an� allow� yo�� th� �
��������������������������versatilit� o� changin� addresses� fil� �
��������������������������descriptors/categories� upload/downloa� �
��������������������������drive/use� areas�� tim� restrictions� �
��������������������������etc�� Anythin�  foun� i� th� ZMDHDR.Z8� �
��������������������������configuratio� heade� ca� b� edite� fro� �
��������������������������withi� ZINSTL��  Sourc� cod� i� no� �
��������������������������provide� fo� thi� program�� I� yo� mak� �
��������������������������an�� modification� t� th� ZMDHDR.Z8� �
��������������������������configuratio� file��� ZINST̠ wil� N� �
��������������������������longe� b� abl� t� instal� you� .CO� �
��������������������������file� properly.

�����ZMD   �.COM��         Mai�  fil�  transfe� program��  Leav� �
     ZMD    .Z80�         thi� on� onlin� fo� publi� us� (Usuall� �
��������������������������A0:)�  I� provide� ful� syste� securit� �
��������������������������whil堠 presentin砠 � use� freindl� �
��������������������������interfac� t� upload� an� downloads�  �
��������������������������YMODE� 1� an� YMODE� 1� Batch�� XMODE� �
��������������������������12�� byt� CRC�� an� XMODE͠ 12�� byt� �
��������������������������checksu� ar� supporte� wit� automati� �
��������������������������protoco� detect.
.pa�
�����Filenam�     K�  CR�               Purpose
     ZMAP   .COM          Publi�upload/downloa�  matri�  displa� �
�����ZMAP   .Z80����������program�� Als� completel�� installabl�
��������������������������wit� th� ZINST� program�� Privat� area� �
��������������������������are shown only if WHEEL byte is on.

�����ZFORS  .COM          Syso�  descriptio� fil� utility�   Thi� �
�����ZFORS  .Z80          on堠� allow� th堠 Syso� t� ad� �
��������������������������description� t� th� FO� tex� fil� (o� �
��������������������������BBӠ messag� base)��  Thi� progra� wil� �
��������������������������no��� ru unles� description� ar� �
��������������������������enabled.

�����ZNEW�  .COM�          Syso�  fil� transfe� lo� utility�  Thi� �
�����ZNEWS  .Z80          on� allow� th� Syso� t� appen� th� �
��������������������������ZMD.LOǠ fil� wit� � ne� uploa� entry�  �
��������������������������Thi� procedur� currentl�� support� � �
��������������������������entry per program run.

�����ZMDE�  .COM�          Syso� fil� transfe�  lo� purg� utility� �
�����ZMDEL  .Z80          Clean� th� ZMD.LO� fil� o� al� entrie� �
��������������������������excep� fo� "R� uploade� entries��  Thi� �
��������������������������keep� th� lo� fil� a�� � reasonabl� �
��������������������������size.

�����ZNEWР .COM�          Publi� fil� transfe� lo�utilit��allow� �
�����ZNEWP  .Z80          caller� t� quickl� vie� statistic� o� �
��������������������������recen�� upload� suc� a� th� drive/user� �
��������������������������fil� siz� i� kilobytes�� dat� o� uploa� �
��������������������������(i� clock/dat� option� ar� enabled)� �
��������������������������etc��  Thi� progra� i� usuall�� place� �
��������������������������on A0:.

�����ZFORР .COM�          Publi� uploa�  descriptio�  search  an� �
�����ZFORP  .Z80          displa�� utility�� User� ca� vie�� th� �
��������������������������description� onlin� o栠 th堠 file� �
��������������������������recentl��� uploaded���  Strin砠 searc� �
��������������������������capabilitie� ar� supporte� t� allo� �
��������������������������'picking� th� description� desired��  � �
��������������������������calle򠠠 ca� quickl���� vie���� al� �
��������������������������description� pertainin� t� 'IBM'� 'Z80� �
��������������������������o� an� strin� tha� wil� fi� o� th� hos� �
��������������������������system'� comman䠠 line���   Multipl� �
��������������������������strin� searc� i� als� supported�� a� i� �
��������������������������dat� searche�(i� enabled�� an� file� �
��������������������������locate� i� � specifi� drive/use� (i� �
��������������������������tha�� featur� i� enabled)���  �� nic� �
��������������������������companion for ZMD.


.pa�














�����------------------------------------------------------------
�����NOTE�� T� preven� possibl� discrepencie� withi� th� ZMDSUB� �
�����subroutine� file�� al� program� hav� bee� designe� t� abor� �
�����wit� erro� i� th� program'� mai� featur� i� disabled��  Fo� �
�����example�� ZFORӠ wil� no� ru� unles� i� ha� bee� installe� �
�����wit� description� enabled�  ZM� ca� no� b� disabled� howeve� �
�����wil� abor�� wit� erro� i� th� mode� I/Ϡ routine� ar� no� �
�����found�  Pleas� d� no� tr� t� disable thi� progra� function.
�����------------------------------------------------------------
.pa�
�����3.0        Installation

�����3.1        Local CRT Clear Screen Sequences

�����CLRSCR�� se�� t� YE� enable� ZM� an� al� utilit�� file� t� �
�����clea� you� scree� locall� durin� batc� fil� transfer� an� �
�����men� displays�� I� you� termina� require� � ^� (1AH)�� leav� �
�����CLRSTR� alone�  Otherwis� yo� wil� hav� t� includ� you� clea� �
�����scree� sequenc� a� labe� CLRSTR�  U� t� � byte� ar� allowed.
�����This CLS sequence is terminated with a '$'.

�����STOP�  I� runnin� ZM� an� utilitie� a� � stan� alon� packag� �
�����an� you� loca� consol� outpu� vecto� addres� canno�� b� �
�����calculate� usin� standar� CP/� convention� (i.e�� you� BIO� �
�����JР tabl� ha� bee� altered)��  yo� wil� nee� t� provid� th� �
�����addres� yoursel� a� labe� CONOU� i� you� port/mode� overlay�  �
�����Thi� i� crucia� t� ZM� eve� whe� no� usin� th� clea� scree� �
�����featur� a� th� recor� coun� i� displaye� locall� durin� th� �
�����fil� transfe� an� an� outpu� o� thi� natur� t� th� mode� a� �
�����thi� tim� woul� caus� seriou� problems.


�����3.2        Input/Output

�����3.2.1      Modem

�����ZM� provide� ful� suppor� fo� th� Extende� BDO� call� se� u� �
�����b�� som� Remot� Consol� Program� suc� a� BYE�� o� MBYE44+� �
�����I� orde� t� us� thi� method� simpl� ski� th� overla� proces� �
�����outline� i� APPENDI� A�  I� n� overla� i� included� ZM� wil� �
�����us� BYE'� mode� I/� routine� alread�� established��  I� a� �
�����attemp�� t� se� th� curren� use� are� t� 24� return� � valu� �
�����o� 7� i� registe� A�� th� followin� call� t� BDOӠ mus�� b� �
�����handled by your BYE program:

�����     BDOS
�����     Call       Function
�����     ----  ---------------------
�����      61   Check receive ready
�����      62   Check send ready
�����      63   Send a character
�����      64   Receive a character
�����      65   Check carrier
�����      66   Console status
�����      67   Console input
�����      68   Local console output�      

�����I� you� BY� progra� doe� no� se� u� it'� mode� I/� routine� �
�����fo� publi� acces� b� outsid� programs�� yo� wil� hav� t� �
�����follo�� th� overla�� procedur� outline� i� APPENDIؠ �� o�  �
�����Modem Interface� t� instal� you� mode� routines.

�����NOTE:��  Thi� featur� i� full� automatic�� N� matte� whic� �
�����metho� yo� use��  ZM� wil� know��
�����3.2.2      Microprocessor Speed

�����MH�� i� define� t� represen� you� system'� microprocesso� �
�����speed�  Thi� allow� ZMD t� accuratel� tim� delay� an� sleep� �
�����calle� timeouts�  Mus� b� intege� valu� i� th� rang� o� 1-9.


�����3.2.3      Modem Speed Indicator Byte

�����MSPEE�� shoul� contai� th� addres� o� you� mode� spee� �
�����indicato� byte��  Thi� i� neede� s� tha� ZM� ca� calculat� �
�����th� amoun�� o� tim� neede� fo� transfer� an� fo� transfe� �
�����spee� insertio� i� th� lo� fil� entry��  You� BYŠ progra� �
�����shoul� stuf� thi� intege� valu� somewher� i� memory�� A� �
�����intege� valu� o� 1-� mus� correspon� a� illustrated:

�����  ���     Value    Bps            Value    Bps
�����          -----  -------          -----  -------
�����            1       300             7      4800
�����            5      1200             8      9600
�����            6      2400             9     19200


�����3.2.4      Disk Write Lock Flag
�����
�����WRTLO�� i� th� hig� memor� byt� toggl� use� fo� disablin� �
�����BYE'� abilit�� t� han� u� whe� th� caller'� tim� i� u� o� �
�����carrie� i� lost��  Thi� allow� curren� dis� writ� operation� �
�����t� b� complete� first�� Chec� you� BB� documentatio� - man� �
�����moder� system� don'� nee� this��  I� unsure� se� thi� t� NO�  �
�����Cod� t� se� an� rese� thi� toggl� assume� i� t� b� locate� �
�����LOCOF� byte� fro� th� J� COLDBOO� vecto� a� th� beginnin� o� �
�����th� BY� BIO� jum� table�  (YE� fo� MBB� an� PBBS).
�����

�����3.2.5      Sleepy Caller Timeout

�����DESWAI�� i� th� numbe� o� minute� o� inactivit�� durin� a� �
�����uploa� descriptio� o� an� promp� befor� abortin� th� inpu� �
�����routine�� (0-255�� � disable� thi� feature)��   I� � timeou� �
�����occur� durin� descriptio� entry�� th� curren� dis� buffe� i� �
�����writte� t� dis� an� th� progra� exit� t� CP/� givin� contro� �
�����back to your BYE program (if WRTLOC is YES).


�����3.2.6      Minimum Speed for 1k Blocks

�����MINKSPD� i� th� minimu� mode� spee� allowe� t� transfe� file� �
�����usin� 1� blocks��  I� o� � networ� suc� a� Pà Pursuit�� an� �
�����ar� abl� t� receiv� incomin� calls� se� thi� byt�  t� 1� Th� �
�����delay� thes� network� us� t� sen� dat� bac� an� fort� mak� �
�����1� packet� advantageou� t� eve� 30� bp� users��  I� no� o� � �
�����networ� suc� a� P� Pursuit� it'� � matte� o� preference� Se� �
     illustratio� i� figur� 3.2.� fo� lis� o� mode� spee� values.�
�����3.2.7      File Transfer Buffer Queue

�����BUFSI�� allow� yo� t� chang� th� numbe� o� 1� block� befor� �
�����writin� buffe� t� disk��  Norma� dis� system� ca� transfe� �
�����16� fro� compute� t� dis� i� 2-3-� second� o� less�� Som� �
�����ver�� slo�� 5-1/4� flopp� system� (suc� a� Nort� Star�� ma� �
�����tak� u� t� 20-3� second� t� transfe� 16k��  Thi� woul� caus� �
�����severa� timeout� a� 1� second� each��  I� yo� experienc� an� �
�����timeouts� tr� changin� thi� t� somethin� smaller� perhap� 8� �
�����o� eve� 4k.
�����

�����3.2.8      Page Pausing

�����PAGLE�� i� se� t� th� numbe� o� line� t� displa� i� betwee� �
�����[moreݠ pause� an� men� displays��  (Se� t� �� t� disabl� �
�����page pauses.�


�����3.2.9      Automatic Calculation of Disk Buffer Size

�����STDBUF� enable� tell� ZM� program� t� calculat� th� amoun� o� �
�����memor�� availabl� fo� routine� usin� DBUƠ dis� buffer�  �
�����OUTSIڠ wil� adjus� accordin� t� th� content� o� locatio� � �
�����an� 7�  I� BY� i� running� thi� valu� i� use� a� is� els� i� �
�����BYŠ i� NOT� running�� 0806� i� subtracte� fro� thi� addres� �
�����locatio� � an� 7��  I� eithe� case� th� en� o� progra� valu� �
�����determine� a� tim� o� assembl� i� subtracte� fro� th� resul� �
�����o� th� abov� t� situations��  Leftove� byte� i� � ar� the� �
�����discarde� t� leav� a� eve� pag� boundary.


�����------------------------------------------------------------
�����NOTE��  MOSԠ AL� system� wil� benefi� wit� STDBUƠ enabled� �
�����sinc� maximu� numbe� o� upload� allowe� i� batc� receiv� �
�����mod� i� directl� relate� t� th� amoun� o� memor� available�  �
�����However� I� you� syste� use� memor� locate� belo� th� CC� o� �
�����BY� program�� yo� wil� nee� t� disabl� this�� i� whic� cas� �
�����OUTSIڠ wil� b� se� t� 16� n� matte� what��  I� you� syste� �
�����hang� o� behave� strangel�� durin砠 descriptio fil� �
�����read/writ� operations� disabl� thi� - tr� i� enable� first.
�����------------------------------------------------------------

.pa�
�����3.3       Timekeeping

�����3.3.1     BYE Clock Support

�����CLOCK�� enable� wil� allo� ZM� an� utilitie� t� loo� a� �
�����cloc� an� dat� informatio� retrieve� b� BYŠ (BYE5�� MBYEn� �
�����an� MBYE44� wit� extende� BDO� enabled� fro� you� syste� an� �
�����store� i� hig� memory�� Th� addres� o� thi� hig� memor� �
�����buffe� i� calculate� a� th� addres� a� (J� COLBOOT+25)��  I� �
�����yo� se� thi� t� YES� th� followin� informatio� i� retrieved:


�����      Location           Contents                Range
�  ���   +------------------+-----------------------+-------+
���  �   | (JP COLDBOOT+24) | Maximum time allowed  | 0-255 |
����     | (JP COLDBOOT+25) | LSB of RTCBUF address | ----- |
����     | (JP COLDBOOT+26) | MSB of RTCBUF address | ----- |
����     +------------------+-----------------------+-------+

         +------------------+-----------------------+-------+
����     | (RTCBUF+0)       | Current hour          | 0-23  |  
����     | (RTCBUF+1)       | Current minute        | 0-59  |
����     | (RTCBUF+2)       | Current seconds       | 0-59  |
����     | (RTCBUF+3)       | Current century       |  19   |
����     | (RTCBUF+4)       | Current year          | 0-99  |
����     | (RTCBUF+5)       | Current month         | 1-12  |
����     | (RTCBUF+6)       | Current day           | 1-31  |
����     | (RTCBUF+7��      | LSB o�TOS            | 0-255 |
����     | (RTCBUF+8��      | MSB o�TOS            | ----- |
         +------------------+-----------------------+-------+�

     Clock/dat� reade� cod� insert� ar� no� supporte� unde� thi� �
�����configuration�  ZM� program� suppor� al� clock/dat� feature� �
�����wit� thi� switc� enable� an� clock/dat� reade� cod� i� i� �
�����BYE� 


�����3.3.2      ZMD Internal Clock/Date Reader Code

�����RTC�� shoul� b� enable� i� yo� canno� tak� advantag� o� BYE'� �
�����RTCBUƠ explaine� abov� an� yo� wis� t� includ� you� syste� �
�����specifi� cloc� an� dat� reade� cod� a� labe� RTCTI� i� th� �
�����ZMDHDR.Z8��  configuratio� table�� B� sur� t� initializ� al� �
�����byte� wit� binar� value� (se� Range� colum� i� tabl� 3.3.�  �
�����fo� minimu� an� maximu� values)��  BCDBI� ma� b� requeste� �
�����fro� ZMDSUBS.RE� t� conver� binar� cod� decima� valu� i� � �
�����registe� t� binar� valu� i� � register�� Delet� al� ';<=� �
�����line� afte� you� cod�  i� installed��  Thi� concep� i� no� �
�����vali� i� CLOC� switc� i�  enable� an� BY� i� runnin� wit� �
�����cloc� an� dat� reade� cod� installed.

�����NOTE��  Mak� sur� yo� d� no� overru� th� mode� I/Ϡ patc� �
�����area when you insert your clock code.
.pa�
�����3.3.3      Restricting Downloads to Time Left

�����TIMEON� switc� enable� tell� ZM� t� restric� download� t� th� �
�����caller� tim� lef�� o� system��  I� CLOCˠ i� enable� an� �
�����MBYE/BYE�� i� running��  BYE'� maximu� tim� allowe� byt� (J� �
�����COLDBOOT+24�� i� use� fo� comparison��  I� CLOC� i� NϠ (o� �
�����MBYE/BYE5�� an� RT� i� yes�� MAXTO� shoul� b� poke� b�� you� �
�����RTà insert��  I� CLOC� an� RT� ar� bot� NO�� MAXMI� wil� b� �
�����use� a� � defaul� an� incremente� o� decremente� a� fil� �
�����transfer� occur.


�����3.3.4      Maximum Minutes Allowed

�����MAXMIN�� shoul� b� se� t� you� likin� i� CLOC� an� RTà ar� �
�����bot� NO� an� TIMEO� i� YES�  Thi� valu� wil� b� th� default�  �
�����Thi� i� decremented/incremente� eac� tim� � fil� transfe� i� �
�����mad� an� th� calle� i� logge� of� whe� i�� reache� 0�  �


�����3.3.5      Display Time on System Messages

�����DSPTIM� i� se� YE� t� hav� tim� o� syste� message� displaye� �
�����a� th� star� an� exi� o� ZMD�  I� CLOC� i� YES� an� MBYE/BY� �
�����i� running�� TO� i� gotte� fro� BYE'� TO� wor� (i� RTCBUF)�  �
�����I� CLOC� i� NO�� o� MBYE/BYE� i� no� running�� th� curren� �
�����minute� allowe� i� subtracte� fro� th� origina� valu� o� �
�����MAXMI� a� progra� startup��  Th� resul� i� displaye� a� tim� �
�����on�  Thi� value i� actuall� � tall�:
�����
����� Original MAXMIN + upload time - download time = time on


�����3.3.6      Logon Hour/Minute Addresses

�����     LHOUR�� i� th� addres� o� th� caller'� logo� hou� byt� �
�����se�� b�� you� BY� o� BB� progra� whe� th� calle� log� on�  �
�����LHOUR+� i� th� logo� minute�  Bot� value� containe� i� thes� �
�����addresse� shoul� b� i� binary��  Thi� shoul� onl� b� se� i� �
�����RT� an� eithe� TIMEO� o� DSPTO� ar� se� YES�  (No� use� wit� �
�����CLOCK).
.pa�
�����3.4        Access Restrictions

�����3.4.1      ZCMD/ZCPR

�����ZCP� (bi� � i� ACCMAP� shoul� b� se� t� YE� i� yo� inten� o� �
�����monitorin� WHEE� byt� statu� o� nee� t� restric�� receivin� �
�����SYS�� RCP�� ND� fil� types�  I� thi� bi� i� se� NO� WHEE� i� �
�����alway� 0.
 

�����3.4.2      WHEEL Byte

�����WHEE� byt� toggl� i� fo� ver� specia� users�  I� ZCP� i� se� �
�����t� YES��  ZM� wil� monito� th� byt� locate� a� thi� address�  �
�����I� it'� 0� time� drive/user/filenam� an� acces� restriction� �
�����remai� i� force�  I� thi� byt� i� non-zero� al� restriction� �
�����are bypassed.


�����3.4.3      Maximum Drive/User

�����USEMA�� shoul� b� se� t� YE� i� yo� wan� t� us� ZCPR'� lo� �
�����memor�� byte� t� kee� trac� o� maximu� driv� an� user��  ZM� �
�����wil� us� th� value� a� location� DRIVMA�� an� USRMA�� fo� �
�����maximu� drive/user��  I� USEMA� i� NO�� hardcod� MAXDR� an� �
�����MAXUS� t� you� ow� requirements.


�����3.4.4      BYE/BBS Program Access Flag Byte

�����ACCES�� i� enabled��  tell� ZM� tha� you� BYE/BBӠ softwar� �
�����suppor�� a� acces� flag� register��  Thi� fla� registe� �
�����(AFBYTE�� i� � dat� byt� i� lengt� an� contain� � fla� bit� �
�����correspdondin� t� commo� BB� restrictions��  ZM� ca� chec� �
�����thi� registe� befor� allowin� th� 'RM� optio� t� uploa� �
�����preformatte� messag� file� t� you� BBS'� messag� base� o� t� �
�����us� th� 'RW� optio� fo� 'privilege� user�� uploa� withou� �
�����bein� require� t� giv� uploa� descriptions�� I� enabled� se� �
�����ACCOF�� t� reflec� th� numbe� o� byte� fro� J� COLDBOOԠ t� �
�����AFBYTŠ flag� byte�� ZM� inspect� AFBYT� fo� th� followin� �
�����fla� data:


		Bit:    7 6 5 4 3 2 1 0
			| | | | | | | |
    �Privileged user ---* | | | | | | |
	      Uploa� -----� � � � � � �  � O� thes� bits� onl� 3� �
	    Downloa� -------� � � � � �    5� � an� � ar� use� b� �
	        CP/� ---------� � � � �    ZMD��  Bi� number� ar� �
	       Writ� -----------� � � �    power� o� 2�� wit� bi� �
		Rea�-------------�����    �  bein�  th�  leas� �
		 BB� ---------------� �	   significan� bi� o� th� �
	      System -----------------+    byte.
.pa�
�����3.5        Upload Configurations

�����3.5.1      Preformatted BBS Message Uploads

�����MSGFI�� switc� enable� ZM� t� accep�� preformatte� messag� �
�����fil� uploads�� File� uploade� wit� th� 'RM� optio� wil� b� �
�����forwarde� t� th� drive/use� define� a� PRDR֠ an� PRUSR�  �
�����Thi� uploa� i� the� appende� t� you� BB� messag� base�� You� �
�����BBӠ softwar� an� BY� progra� mus� suppor�� thi� feature� �
�����MBB�, QBBS and PBBS all support this feature.   PMSG/HMSG is
     now available on RI RCPM-RDOS.


�����3.5.2      Hiding New Uploads Until Approved by Sysop

�����HIDEI� allow� Sysop� t� kee� al� ne� regula� upload� hidde� �
�����fro� publi� viewin� unti� reviewe� an� cleared��  Thi� way�  �
�����ne�� upload� wil� no� appea� i� � DIRector�� listin� an� �
�����canno� b� viewe� o� eve� downloade� b� ZMD�  Thi� featur� i� �
�����disable� whe� th� WHEE� byt� i� O� o� Privat� uploa� mod� i� �
�����enabled��  File� tha�� hav� bee� hidde� wil� sho� u� i� � �
�����DIRector� listin� whe� th� WHEE� byt� i� se� an� � $� optio� �
�����i� use� t� sho� SYSTE� files��  Referenc� wil� b� mad� t� �
�����thes� file� i� th� lo� an� FO� tex� fil� listing� i� thos� �
�����feature� ar� enabled��  Yo� ca� us� POWE� o� NSWEE� t� se� �
�����hidde� file� t� $DIR.


�����3.5.3      Upload Routing to Multiple Drive/Users

�����ASKARE�� switc� se� YE� enable� uploa� routin� t� multipl� �
�����drive/use� areas��  Wit� thi� enable� � calle� i� displaye� �
������ lis� o� uploa� categorie� t� choos� from��  Whe� h� enter� �
�����hi� selection�� ZM� wil� calculat� th� offse� t� th� uploa� �
�����drive/use� i� TYPTB�  an� se� th� uploa� are� base� o� hi� �
�����selection��  Thi� i� don� a� th� sam� tim� fo� bot� Regula� �
�����an� Privat� uploads)��   Uploa� routin� i� disable� whe� th� �
�����WHEE� byt� i� set� i� whic� case�  norma� upload� wil� g� t� �
�����th� curren� drive/use� are� an� privat� upload� wil� g� t� �
�����th� drive/use� equate� a� PRDR� an� PRUSR.


�����3.5.4      Uploading to Specified Drive/User

�����SETARE�� enable� force� al� ne� upload� t� th� drive/use� �
�����define� a� DRV� an� USR��  I� th� WHEE� byt� i� set�� regula� �
�����upload� wil� g� t� th� curren� o� specifie� drive/user�  Al� �
�����privat� file� uploade� wit� th� 'RP� optio� wil� b� sen� t� �
�����PRDR� an� PRUS� regardles� o� WHEE� status.

.pa�
�����3.5.5      Receiving Private Uploads

�����PRDR� an� PRUS� ar� th� drive/use� are� wher� AL� file� sen� �
�����t� th� Syso� wit� th� 'RP� optio� wil� g� (unles� ASKARE� �
�����i� YES)� Thi� permit� experimenta� files� replacemen� and/o� �
�����proprietar�� program� t� b� sen� t� a� are� onl�� accessibl� �
�����b�� th� Sysop�� Thi� i� als� th� driv� an� use� are� wher� �
�����messag� file� ar� uploaded�� i� MSGFI� i� se�� YES��  I� �
�����ASKARE� i� YES�  'RP� upload� wil� g� her� onl� i� th� WHEE� �
�����i� set�� I� MSGDES� i� YES�� thi� i� th� driv� an� use� are� �
�����th� FO� tex� fil� wil� b� place� befor� appendin� i� t� th� �
�����BB� system'� messag� base.


�����3.5.6      Crediting Upload Time to Time Left

�����CREDI�� enable� cause� ZM� t� credi� caller� fo� th� tim� �
�����the�� spen�  uploadin� non-privat� file� eac� session�� Fo� �
�����example�� � calle� wh� spend� 3� minute� sendin� a� uploa� �
�����get� 3� minute� adde� t� hi� TLOS��  (Yo� mus�� se�� eithe� �
�����CLOCK� RT� o� TIMEO� t� YE� t� us� thi� feature).


�����3.5.7     Receiving .COM Files Securely

�����NOCOM�� tell� ZM� t� renam� .CO� file� t� .OB� an� .PR̠ t� �
�����.OBР o� receive��  Thi� featur� i� als� disable� whe� th� �
�����WHEE� byt� i� set.

.pa�
�����3.6        Upload Descriptions

�����Thi� sectio� ha� t� d� wit� uploa� descriptions��  I� yo� d� �
�����no� inten� o� implementin� uploa� descriptions�� se� DESCRI� �
�����an� MSGDESà t� NO�� Th� res� o� thes� value� ar� the� �
�����ignored��  I� usin� descriptions�� se� ONL� on� o� thes� t� �
�����YES� no� both.


�����3.6.1      Forwarding Descriptions to BBS Message Base

�����MSGDES�� shoul� b� se� YE� i� you� you� BB� syste� support� �
�����messag� uploads�� an� yo� prefe� uploa� description� t� b� �
�����place� i� you� BB� messag� bas� (se� DESCRI� NO)� MBB� user� �
�����nee� t� instal� MFMSG.CO� wit� th� MBBSINI� program��  The� �
�����se�� you� BY� progra� t� kno� abou� messag� fil� upload� b� �
�����settin� th� MSGFI� optio� i� BYE/MBY� t� YES��  I� se�� YES� �
�����ZMĠ wil� produc� � FO� tex�� fil� whe� writin� uploa� �
�����descriptions�� Thi� FO� fil� wil� g� t� th� driv� an� use� �
�����are� equate� a� PRDR� an� PRUS� jus� befor� bein� appende� �
�����t� you� BB� system'� messag� base.


�����3.6.2      Forwarding Description to FOR Text File

�����DESCRI�� switc� shoul� b� YE� i� yo� wan� description� t� b� �
�����appende� t� th� curren� FO� fil� wher� the� ca� b� viewe� b� �
�����caller� wit� th� ZFORР utility��� Syso� ca� ad䠠 ne� �
�����description� wit� th� ZFOR� utility��  Upload� sen� t� th� �
�����Syso� privat� uploa� are� wil� no� requir� descriptions� no� �
�����wil� file� uploade� wit� th� 'RW� optio� - use� mus�� b� � �
�����privilege� use� (bi� � i� ACCES� byt� set� o� hav� WHEE� �
�����acces� an� PUPOP� mus� b� se� YE� t� us� th� 'RW� option.


�����3.6.3      Description Filename

�����FORNAM/DRIVE/USE�� i� th� drive/use� an� filenam� o� th� FO� �
�����descriptio� tex�� file��  Thi� filenam� mus�� b� 1�� byte� �
�����padde� wit� spaces�  I� usin� wit� DESCRI� se� YES� yo� mus� �
�����indicat� wha�� drive/use� yo� wan� th� 'FOR�� fil� t� b� �
�����placed��  Drive/use� are� i� automaticall� change� t� PRDR� �
�����an� PRUSҠ i� description� ar� t� b� forwarde� t� th� BB� �
�����messag� bas� 

.pa�
�����3.6.4      Upload Description Header Information

�����I� you� configuratio� include� DESCRI� se� t� YES�� you'l� �
�����hav� t� tel� ZM� wha� informatio� yo� wan� include� i� th� �
�����firs� lin� o� eac� description�  Cod� i� include� i� al� ZM� �
�����program� t� plac� al� (any� informatio� i� th� uploa� �
�����descriptio� header� Th� followin� diagra� illustrate� � ful� �
�����implementatio� o� DESCRIB:


    �-----
    �ZMD150.LBR - Communications         (C3:)     Rcvd: 09/29/88
		      /			   /		  /
      	      _______/		   _______/	    _____/
       ASKIND 	             INCLDU 	      DSTAMP



�����3.6.5      Including File Descriptors

�����ASKIN�� switc� enable� cause� ZM� program� t� as� fo� th� �
�����categor�� o� th� upload(s� an� writ� i�� int� th� uploa� �
�����descriptio� header��  I� yo� se� thi� t� YES�� mak� sur� yo� �
�����se�� MAXTY� t� th� highes� lette� choic� yo� wis� t� suppor� �
�����an� edi� th� tex� a� KNDTB� u� t� an� includin� you� MAXTY� �
�����setting� (Use� onl� wit� DESCRIB).


�����3.6.6      Including Upload Drive/User Area

�����INCLD�� enable� wil� includ� th� drive/use� are� o� th� �
�����uploade� fil� int� th� uploa� descriptio� header� (Use� onl� �
�����wit� DESCRIB).


�����3.6.7      Datestamping the Description Header

�����DSTAM� enable� wil� includ� th� dat� th� uploa� wa� receive� �
�����int� th� uploa� descriptio� header��  (N� i� n� clock� (Use� �
�����onl� wit� DESCRIB).


�����3.6.8      Overriding Description requests

�����PUPOP�� allow� description� t� b� disable� whe� "RW� i� use� �
�����o� th� ZM� comman� lin� (i.e� ZM� R� FILE.EXT)� Thi� comman� �
�����ma�� onl� b� use� b� thos� considere� "priviledged� user� o� �
�����you� syste� o� WHEE� users��  Upload� o� thi� typ� wil� b� �
�����tagge� i� th� ZMD.LO� fil� a� private�� s� a� no� t� displa� �
�����wit� th� NE� command��  (Se� ACCES� equat� descriptio� abov� �
�����fo� informatio� o� detecting 'priviledged� users).

.pa�
�����3.6.9      Automatic Word Wrap

�����WRA�� i� se� t� th� colum� positio� wher� wor� wra� wil� �
�����occur��  I� usin� MSGDES� an� hav� problem� wit� a� 'Invali� �
�����format� erro� fro� MFMSG.COM�� tr� settin� WRA� t� somethin� �
�����smaller��  lik� 6� o� 63�  (Wor� wra� ca� b� disable� b� th� �
�����use� wit� ^� durin� descriptio� entry��  Ente� 7�� her� t� �
�����disabl� WRA� completely).

.pa�
�����3.7        Download Configurations

�����ACCMA�� i� � bi� mappe� fla� registe� � byt� i� length��  I� �
�����contain� �� fla� bit� whic� enable/disabl� th� filenam� �
�����restriction� outline� below���  Th� restriction� alway� �
�����pertai� t� th� fil� bein� considere� fo� transfer�  Enablin� �
�����an�� o� thes� option� cause� ZM� t� loo� a� th� hig� bi�� o� �
�����th� byt� positio� indicate� belo�� (F1=filenam� byt� 1� �
�����T2=fil� typ� byt� 2�� etc)��  Thes� restriction� ar� alway� �
�����bypasse� whe� usin� ZCP� an� th� WHEE� i� set.


�����3.7.1      Restricting .LBR and Single F1 Tagged Files

�����TAGFIL�� switc� i� enable� i� yo� wan� t� restric�� caller� �
�����fro� downloadin� certai� files�� suc� a� ver� larg� overla� �
�����libraries�� gam� libraries�� etc��  I� mos� cases� remainin� �
�����tim� lef�� o� syste� woul� b� sufficien�� fo� restrictin� �
�����downloads�� However� wit� bi� � o� ACCMA� se� t� 1� ZM� wil� �
�����chec� th� hig� bi� o� filenam� byt� � an� i� thi� i� set� �
�����th� fil� ma�� no�� b� downloaded���  I� th� fil� i� � �
�����ARK/ARC/LBҠ file�� individua� member� ma�� b� downloade� �
�����however��  Thi� restrictio� i� bypasse� i� th� WHEE� byt� i� �
�����set.

�����     ACCMAP Switch:  10000000
�����     Filename Byte:  FILENAME.EXT
�����

�����3.7.2      Disallowing .COM Downloads

�����NOCOM�� shoul� b� enable� i� yo� d� no� wan� caller� t� b� �
�����abl� t� downloa� *.CO� files��  Mos� secur� system� wil� �
�����enabl� thi� restriction��  Thi� featur� i� bypasse� whe� �
�����WHEEL byte is set.

�����     ACCMAP Switch:  00001000
�����     Filename Byte:  FILENAME.EXT


�����3.7.3      Disallowing .??# Downloads

�����NOLB� i� enable� fo� thos� system� whic� us� 'labels� i� th� �
�����thir� fil� exten� byt� o� syste� file� t� restric�� publi� �
�����acces� t� them� ZM� wil� chec� T� byt� fo� � '#� characters�  �
�����Upo� � match�� th� downloa� i� denied��  Thi� featur� i� �
�����bypassed when the WHEEL byte is set.

�����     ACCMAP Switch:  00010000
�����     Filename Byte:  FILENAME.EXT

.pa�
�����3.7.4      Disallowing F2 Tagged $SYStem File Downloads

�����NOSY�� enable� tell� ZM� t� ignor� al� file� wit� th� hig� �
�����bi� se� i� filenam� byt� T2��  Thes� file� ar� considere� a�  �
�����hidde� $SYSte� file� b� CP/� an� ca� b� treate� th� sam� wa� 
�����b� ZMD� Thi� featur� i� bypasse� whe� th� WHEE� byt� i� set.

�����     ACCMAP Switch:  00100000
�����     Filename Byte:  FILENAME.EXT


�����3.7.5      Sending F3 Tagged Files Regardless of Access

�����DWNTA�� i� enable� allow� an� fil� wit� th� hig� bi� se�� i� �
�����filenam� byt� � t� b� sen� regardles� o� th� caller� access. �
�����Thi� come� i� ver� hand� fo� close� system� requirin� user� �
�����t� downloa� applications�� syste� informatio� files�� BB� �
�����lists, etc.

�����     ACCMAP Switch:  01000000
�����     Filename Byte:  FILENAME.EXT


�����3.7.6      Special Sysop Downloads to Selected Caller

�����SPDR�� an� SPUS� contai� th� drive/use� are� fo� downloadin� �
�����privat� 'SP� file� fro� Sysop��  Thi� permit� you t� pu�� � �
�����specia� 'non-public� fil� i� thi� area� the� leav� � privat� �
�����not� t� th� perso� i� i� intende� fo� mentionin� th� nam� o� �
�����th� fil� an� ho� t� downloa� it��  Althoug� anybod� 'could� �
�����downloa� tha� program�� the� don'� kno� wha� (i� any�� file� �
�����ar� there��  � hig� degre� o� securit� exists��  whil� th� �
�����Syso� stil� ha� th� abilit� t� mak� specia� file� available� �
�����Thu� an� perso� ca� b� � temporar� 'privilege� user'.

�����NOTE� � breac� o� securit� exist� i� SPUS� i� no� define� a� �
������ highe� use� are� tha� th� maximu� allowabl� publi� use� �
�����area.� 

.pa�
�����3.8        Logkeeping

������ cloc� i� not necessary for this logkeeping features.


�����3.8.1      Making ZMD.LOG File

  ���LOGCAL� enable� th� lo� keepin� routine� i� ZMD�  Ne� upload� �
�����wil� b� adde� t� th� curren� ZMD.LO� file��  I� n� lo� fil� �
�����exists� on� wil� b� created�  Al� fil� transfer� ar� logged�  �
�����Yo�� ca� the� us� ZNEWP.CO� t� sho�� listing� o� recen� �
�����upload� o� ZNEW� t� ad� lo� entries.


�����3.8.2      European Date Format (DD/MM/YY)

�����EDATE�� cause� ZM� an� utilitie� t� sho�� dat� i� dd/mm/y� �
�����forma� instea� o� mm/dd/y� format.


�����3.8.3      Transfer Log Drive/User/Filename

�����LOGNAM/LOGDRV/LOGUSR�� i� th� drive/use� an� filenam� o� th� �
�����ZMD.LOǠ fil� transfe� log��  Thi� filenam� mus� b� 1� byte� �
�����padde� wit� spaces��  I� usin� wit� LOGCA� se� YES� yo� mus� �
�����indicat� wha� drive/use� yo� wan� th� 'ZMD.LOG� fil� t� b� �
�����placed�


�����3.8.4      LASTCALR Drive/User

�����LASTDRV/LASTUSR/LCNAME�� i� th� drive/use� o� you� BB� o� BY� �
�����program'� LASTCALR.??� file�  Thi� filenam� mus� b� 1� byte� �
�����padde� wit� spaces��  I� usin� wit� LOGCA� se� YES� yo� mus� �
�����indicat� wha� drive/use� ZM� ca� fin� th� LASTCALR.??� file� 
�����LCNAM� shoul� b� se� t� th� colum� positio� o� th� caller'� �
�����nam� i� th� LASTCALR.??� file�  (� fo� PBBS� 1� fo� MBBS).


�����3.8.5      Counting Files Transfers for BBS Software

�����LGLDS�� se� YE� enable� sessio� uploa� an� downloa� counting� �
�����ZMĠ wil� coun� th� numbe� o� up/download� fo� eac� logon�  �
�����You� BBӠ progra� the� ca� chec� UPLDS�� an� DNLDS�� counte� �
�����byte� whe� � use� log� ou� an� updat� eithe� th� user'� fil� �
�����o� � fil� fo� thi� purpose��  Yo� ca� eithe� modif� you� BB� �
�����entr� progra� t� chec� th� LASTCAL� fil� befor� updatin� an� �
�����the� updat� (risky)�� o� mak� � separat� progra� tha�� BY� �
�����call� whe� loggin� of� � use� (preferred)��  (YE� fo� PBBS)�  �
�����Don'� forge� t� initializ� UPLD� an� DNLD� counte� byte� t� �
������ fro� you� BB� progra� whe� somebod� log� in.

�����NOTE�� Clea� th� UPL� an� DNL� byte� ONL� whe� � use� log� �
�����in� no� whe� h� re-enter� th� BB� progra� fro� CP/M.�






















�����                       APPENDICES

.pa�
�����A.1        Modem Interface

     A.1.1      Creating ZMD Modem Input/Output Overlays

�����Al� port/mode� overlay� ar� allowe� 12� byte� betwee� 580� �
�����an� 5FFH��  Thi� are� i� alway� containe� i� th� ZMDHDR.Z8� �
�����configuratio tabl� an� include� durin� th堠 assembl� �
�����process�� Th� firs� 27 byte� o� thi� overla� mus� contai� � �
�����J� instruction� i� th� followin� order:


�����  Routine  Purpose                      Entry    Exit
�����  --------------------------------------------------------
�����  CONOUT   Local console output (BIOS)  A=char   -----
�����  INIT     Initialization               -----    -----
�����  UNINIT   Uninitialization             -----    -----
�����  SNDCHR   Send character  POP AF gets->A=char   -----
       CARCH�   Carrier check                -----    Z=Carrier
�����  GETCHҠ  Receive a character          -----    Char in A
�����  RCVRD٠  Check receive ready          -----    Z=char
�����  SNDRD٠  Check send ready             -----    Z=ready


     A.1.2      Installing Your Modem I/O Overlays

�����ZM� mus� hav� acces� t� you� mode� fo� obviou� reasons��  I� �
�����need� t� sen� data�� receiv� data�� perfor� erro� checking� �
�����monito� carrie� an� giv� contro� bac� t� you� BYŠ progra� �
�����whe� carrie� i� lost��  I� ha� t� kno� whe� th� mode� i� �
�����read�� t� sen� anothe� characte� an� whe� on� ha� bee� �
�����received�  I� you� syste� use� extende� BDO� call� t� acces� �
�����you� BY� program� port/mode� routines�� yo� ca� instal� ZM� �
�����an� utilitie� withou� regar� t� thi� section��  Otherwise� �
�����follo��these steps:

�����   1��  Fin� a� overla� fro� ZMDOVLn.LB� tha� bes� fit�you�        �
�����        modem/por� requirements�  Yo� ma� hav� t� creat� on� �
�����        fo� you� syste� i�  on� doesn'� exis� already�  Some
�����        standar� format� ar� include� (se� -OVERLAY.LSԠ i� �
�����        the ZMDOVLn.LBR).
���     2��  Edi� i� wit�  you� favorit� wordprocesso� a� needed� �
�����        Mak� sur� yo� loca� consol� outpu�� addres� (BIOS� �
�����        ca� b� calculate� usin� standar� CP/� method� (i.e��
�����        (JР COLDBOOT+9�� I� you� BIO� JР TABLŠ ha� bee�         �
�����        altered�� yo�� wil� hav� t� provid� thi� addres� fo�    �
�����        ZMĠ a� labe� CONOUT��  I� mos� cases�� ZM� wil� b� �
�����        abl� t� calculat� thi� addres� fo� you�  I� yo� wil� �
�����        nee� t� initializ� anythin� a� progra� star�� up� �
�����        includ� you� custo� routin� a� labe� INI� an� you�         �
�����        uninitializ� routin� a� UNINIT��  INI� i� calle� a�         �
�����        progra� startup��  an� o� cours� UNINI� i� calle� a�         �
�����        progra� exit.
.pa������   3�   Assembl� wit� M80� o� SLRMA� o� othe� Z8� compatibl� 
�����        assembler to produce ZMxx-n.HEX
���     4�   Us� MLOA� (included� t� loa� ZMxx-n.HE� ove� ZMD.CO� �
�����        lik� this:

�����         A0>MLOAD ZMD=ZMD.COM,ZMxx-n


�����ZINST� wil� no� recogniz� you� mode� overlay��  Yo� ca� als� �
�����us� DD� t� patc� you� overla� in��  Mak� sur� i� start� a� �
�����580H and ends by 5FFH (128 bytes).

�����NOTE��  I� ZM� attempt� t� se� th� curren� use� are� t� 24� �
�����an� 7� i� returne� i� registe� A�� BYE'� extende� BDO� call� �
�����will be used for modem I/O.  
.pa�
�����B.1        RTC Clock/Date Reader Code

������ fe� o� ZMD'� nic� feature� ar� dependen� upo� acces� t� � �
�����Rea� Tim� Clock��  MBY� an� BYE� user� wh� hav� thei� cloc� �
�����an� dat� reade� cod� installe� nee� onl� se� CLOC� t� YE� �
�����an� leav� RT� se� NO��  I� o� th� othe� han� you� BYŠ doe� �
�����no�� rea� you� syste� clock�� yo� wil� hav� t� inser�� you� �
�����cloc� an� dat� reade� cod� a� labe� RTCTI� i� ZMDHDR.Z80�  �
�����Wit� RTà se�� YES�� al� ZM� routine� hav� acces� t� th� �
�����followin� binary value� (poke� b� you� cloc� insert):


�����               Address   Length   Range
�����             +---------+--------+-------+
�����             | MONTH   | 1 byte | 1-12  |
�����             | DAY     | 1 byte | 1-31  |
�����             | YEAR    | 1 byte | 0-99  |
�����             | HOUR    | 1 byte | 0-23  |
�����             | MINUTE  | 1 byte | 0-59  |
�����             +---------+----------------+ 


     You� inser� mus� star� a� 4FE� an� en� b� 57F� (13� bytes).
.pa�
�����C.1        File Descriptors/Categories

�����Thi� tabl� define� th� tex� t� b� include� i� uploa� �
�����descriptio� header� (DESCRI  an� ASKIND�� and/o� define� �
�����categorie� fo� uploadin� t� multipl� drive/use� area� (I� �
�����ASKAREA)��  Chang� a� desired� i� thi� lis� i� no� suitable�  �
�����D� NOԠ remov� an� o� th� tex� a� KNDTBL�� Simpl� edi�� th� �
�����categor�� tex�� belo� u� to/includin� you� MAXTYР setting� �
�����MAXTYP�� belo�� mus� b� se� t� whateve� lette� you� maximu� �
�����choic� wil� be� 


�����MAXTYP:	DB	'W'	; Highest category you will support.
 
�����KNDTBL:

�����DB   '  A) - CP/M Utility          ',CR,LF
     D�   '  B� - CP/� Applicatio�      ',CR,LF
�����D�   '  C� - CP/� Gam�             ',CR,LF
�����D�   '  D� - Wordprocessin�        ',CR,LF
     DB   '  E) - Text & Information    ',CR,LF
     DB   '  F) - Printer Related       ',CR,LF
     DB   '  G) - Communications - IMP  ',CR,LF
     DB   '  H) - Communications - MEX  ',CR,LF
     DB   '  I) - Communications - Other',CR,LF
     DB   '  J) - RCP/M Software        ',CR,LF
     DB   '  K) - BBS List              ',CR,LF
     DB   '  L) - ZCPR1/2/3             ',CR,LF
�����DB   '  M) - Pascal Utility/Source ',CR,LF
     DB   '  N) - dBase Utility/Source  ',CR,LF
     DB   '  O) - Basic Utility/Source  ',CR,LF
     DB   '  P) - ''Other'' Language      ',CR,LF
     DB   '  Q) - EPSON Specific        ',CR,LF
     DB   '  R) - ZMD Support           ',CR,LF
     DB   '  S) - IBM Utility           ',CR,LF
     DB   '  T) - IBM Application       ',CR,LF
     DB   '  U) - IBM Game              ',CR,LF
     DB   '  V) - IBM Communications    ',CR,LF
     DB   '  W) - Mixed Batch/Misc      ',CR,LF
     DB   '  X) - <<<< Not Defined! >>>>',CR,LF
     DB   '  Y) - <<<< Not Defined! >>>>',CR,LF
     DB   '  Z) - <<<< Not Defined! >>>>',CR,LF
     DB	  0		; leave the table terminator alone.


�����------------------------------------------------------------
�����NOTE��  Mak� sur� yo� leav� al� th� categorie� abov� EXACTL� �
�����3�� byte� lon�  (2� byte� o� tex� plu� th� CR,L� equal� 31� �
�����o� yo� wil� hav� problem� wit� th� doubl� colum� formattin� �
�����routines.
�����------------------------------------------------------------
.pa�
�����D.1        Upload Routing Table

�����I� yo� decide� t� enabl� uploa� routin� t� multipl� driv� �
�����users� yo� wil� hav� t� se� th� followin� tabl� fo� you� ow� �
�����requirements�� Edi�� al� area� a� TYPTB� u� t� an� includin� �
�����you� MAXTYР setin� t� matc� th� messag� tex�� i� KNDTB� �
�����above�  Not� tha� PRIVAT� upload� ma� b� sen� t� � differen� �
�����driv� a� wel� a� � differen� use� area��  Eac� entr�� i� �
�����expresse� a� 'driv� letter',use� area�  Simpl� se� MAXTY� t� �
�����th� highes� lette� choic� supported��  (D� NO� commen�� ou� �
�����an� o� thes� storag� bytes).

                     _________
       NOTE:        /    A    \	 <--- Corresponds to category 'A'
                   'A',1,'B',15,
                     \ /   \ /
      Normal upload --+     |
      Private upload -------+


     TYPTBL:
	    _________     _________     _________     _________
	   /    A    \   /    B    \   /    C    \   /    D    \
     DB	  'A',1,'B',15, 'A',2,'B',15, 'B',2,'B',15, 'B',4,'B',15
	    _________                   _________
	   /    E    \                 /    Z    \
     DB	  'B',3,'B',15, ... thru ...  'B',7,'C',12


