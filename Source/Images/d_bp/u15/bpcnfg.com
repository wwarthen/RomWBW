�Z3ENV   BPCNFG   IMGCNF�s�;1�;�h6�C�;�H:" ;"�;�! ���RMDkb6 ��!l {: ����0* ��5"	�3Ͳ3�-� ^͑1
B/P CONFIG Utility  V2.1a   21 Apr 97
    Copyright 1991-3 by H.F.Bower/C.W.Cotrill
 * >�.t1 ��:] �/��)�?M(T� I¯:\ �(�@Dy͑1
  Configure Memory (M), Disk (D), or Image (I) ? :  ͳ-O�M 
y2�;�~'���D 5͑1
	Disk Drive Letter (A..P) :  ͳ-�+.8��y2�;���'e�I��͑1
	Image File to Configure :  �.��,\ ��3� 	y2�;ͭ3($�;/͑1Error in File Name Parse ! ��,��%�2v::|:� �.01�;�2w:��1͑1
Main Menu  -  Configuring  :�;�M ͑1Running Memory ]�D *͑1Drive  :�;�@��8>:��8͑1 Boot Sectors /͑1Image File  [ �K�;x�A��8y�N8>:��8] �8>]��8͑1
        Bios Ver  :;��G/>.��8��G/͑1

   1   System Options

   2   Character IO Options

   3   Floppy Subsystem Options

   4   Hard Disk Subsystem Options

   5   Logical Drive Layouts

   6   Configure from Script File >6�i-�(#�1�0�2�!
�3���4�
�5�l�6�R/��0�͑1
..Writing New Configuration to  :�;�D ͑1Drive :  :�;�@��8�(+�M ͑1Memory.. ͮ'͑1 :  ] �8͑1.. ��&�K�;�S6��7��,>2w:��1͑1
Menu 1 - System Options


   1   System Drive    =  >�.~�A��8͑1:

   2   Startup Command = " >��.#͙1͑1"

   3   Reload Constant =  >��.~#fò8͑1 ( ��8͑1H)

   4   Processor Speed =  >��.~�N8͑1 MHz

   5   Memory Waits =  >��.~��N8͑1,  IO Waits =  ~��N8>6�i-����1 W��7͑1		System Drive Letter		[ >�.~�A��8͑1]	:  ��1ͳ-�0��0�+.0��0��AO>�.q�0�2 L��7͑1		Enter New Startup Command :  ��1�.(��>��.#�~�(#��6 #��0�3 ;��7͑1		Timer Reload Value	[ ��1>��.^#V����-�0��0�r+s��4����7͑1		Processor Speed in MHz	[ ��1>��.^ ����-�8z�(��0�Vs�͑1
		   Scale Timer Constant?	([Y]/N) :  ͳ-�N��0>��.~#foJ �0�  ��B8��!   ��>��.#�I�6ʎ��7͑1		Number of Memory Waits	[ ��1>��.~�o& ��-8	z� {�8��0�O��7͑1		Number of IO Waits	[ ��1>��.~��o& ��-�8	z� {�8��0±w�0͑1
	-- This is DANGEROUS...Proceed? (Y/[N]) :  ͳ-�Y�0��1͑1
Menu 1.1 - System Bank Numbers


   1   TPA Bank #       =  >��.~�N8͑1

   2   System Bank #    =  >��.~�N8͑1

   3   User Bank #      =  >��.~�N8͑1

   4   RAM Drive Bank # =  >��.~�N8͑1

   5   Maximum Bank #   =  >��.~�N8>5�i-��0��7�1!�	�.~��	�������2W:͑1	    Enter Bank Number	[ ��1:W:�.^ ����-�8�z� �s�>2w:��1͑1
Menu 2 - Character IO Options


   1   IOBYTE Assignment:
		Console   =  >~�.~�͖͑1
		Auxiliary =  ��͖͑1
		Printer   =  �͖�2[:�k~�(1"\::[:<2[:���7͑1
    :[:�1��8͑1    *\:��:[:�12^::;� :^:8+͑1

    :[:�2��8͑1   Swap Devices :^:<�i-����1��͑1
	Set [C]onsole, [A]uxiliary, or [P]rinter :  ��7��!
�C 
ͪ�!
�<�A ͪ�!
� � x���G�%�P(� �!
��!
��0͑1 �ͪ�!
��?>~�.~��w�!
�:^:<O��t͑1
	Swap [2.. :^:��8͑1] :  ͳ-�!
�28!^:=�8͑1 ��0��12_:͑1  with [2.. :^:��8͑1] :  ͳ-�!
�28!^:=�8͑1 ��0��12[:�k�:_:2[:�k�N�q�#��!
�22[:�k���~� #͑1
-- Nothing There !! -- ��0�!
͑1
	Configuring  ��> ��8͋>:��8�~���l͑1
	    Baud Rate  �~/��(!͑1 (Max= �~�2Z:�͑1) =  ͑1  Selections are: >�=� ͑1
	 >	��8���N8>-��8�����!Z:�0�<����7͑1	    Select	[ ��1�~�o& ��-8z� {�(=!Z:�8��0��~���w͑1
	    Data =  �~/�_ͦ >ݮ�w͑1
	    Stop Bits =  ��F>1 <��8ͮ >ݮ�w͑1
	    Parity =  !���N(!���V(!�͙1͸ P͑1
		Enable Parity ����� 2���͑1
		Odd or Even? (O/[E]) :  ͳ-����O ���͑1
	    XON/XOFF Flow =  ��f͋͸ >ݮ�w͑1
	    RTS/CTS Flow =  ��n͋͸ > ݮ�w�~��(Y��v(%͑1
	    Input is  ��~ͦ >�ݮ�w��~(g͑1
	    Output is  ��~ͦ I>�ݮ�w?͑1
	  -- Nothing Configurable...[any key to continue]  -- ͚/�!
:;�8:[:G�(���_>��. �!�(!�Ù1�2[:��k�~��8#��͑1
	  Set  �2[:͖>[��8:[:<2[:�0�4���8>]��8��>,��8> ��8�8�͑1?  ͳ-7��1G8�?�͑1 ����~� ͑1-- Unavailable -- ���͑1 -  ��8[�͑1,  �#>8�^(=���8͑1 Data,  �G>1 >2��8͑1 Stop,  !��O(
!��W !�͙1͑1 Parity,  >[��8��v(*͑1In >(��8��~>7(<��8>)��8�~���� >/��8��~(͑1Out >(��8��~>7(<��8>)��8>]��8Even Odd No None Yes ~#��8���!V�0&!\�(!b�G����.x�	8͙1͑1 kbps ͙1͑1 bps �~�����͑1 (fixed) �115.2 134.5 50   75   150  300  600  1200 2400 4800 9600 19.2 38.4 76.8 (fixed) >8 =��8͑1-bits. ͑1	Change ͑1? (Y/[N]) :  ͳ-�Y�>2w:��1͑1
Menu 3 - Floppy Disk Options


   1   Floppy Drive Characteristics:
	Drv0 =  >��/͑1	Drv1 =  >��/͑1	Drv2 =  >��/͑1	Drv3 =  >��/͑1
   2   Motor ON Time (Tenths-of-Seconds) :  >��.~�N8͑1

   3   Motor Spinup (Tenths-of-Seconds)  :  >��.~�N8͑1

   4   Times to Try Disk Operations :  >��.~�N8>4�i-�����7�1 [͑1	    Configure which unit [0..3] :  ��1ͳ-� (&�("�08�8�'�o& ))�.�>��.���͏���2 =͑1		Motor On Time in 1/10 Secs	[ ��1>���8z� � �'�s���3 <͑1		Motor Spinup in 1/10 Secs	[ ��1>���8z� � �'�s����1͑1		Times to try Disk Opns	[ ��1>���8z� � �'�{�8B͑1
			Do you REALLY mean  {�N8͑1 tries? (Y/[N]) :  ��7�Y(�'�s����7͑1		Size  8"(1),  5.25"(2),  3.5"(3)?	[ ��1�~ �o& ��-8z� {�(�8�'�G�~ ����w ͑1		Single or Double-Sided Drive ?		( SD�� ^��-͑1)	:  ��1ͳ-��-(�S(	�D(�'��D�� �(�� �͑1
		Motor On/Off Control Needed ?		( YN�~ /�o��-͑1)	:  ͳ-��-(�N�� � �� ��~ �=(a��7͑1		Motor Speed Standard or Hi-Density	( SH�� v��-͑1)	:  ��1ͳ-��-(�S(	�H(�'��� ��H �� ���7�~ �=>M(G͑1		Tracks-per-Side (35,40,80)		[ ��1�n& ��-8z� {�#(�((	�P(�'��w͑1		Step Rate in Milli-Seconds		[ ��1�n& ��-8z� � �'��w͑1		Head Load Time in Milli-Seconds		[ ��1�n& ��-8z� � �'��w͑1		Head Unload Time in Milli-Seconds	[ ��1�n& ��-8z� � �'��w�>��8��0�.~�!���0!���#.͙1> ��8��^#�>S(>D��8>S��8͑1,  ��###~�N8͑1 Trks/Side
		Step Rate =  �~�N8͑1 mS, Head Load =  #~�N8͑1 mS, Unload =  #~�N8͑1 mS
 �����Fixed 3.5" 5.25" 8" Unknown >]��8͑1	:  ��.^ ����-��>2w:��1͑1
Menu4 - Hard Disk Options

   1   Hard Drive Controller =  >��.~2b:2c:!���(!c:6 �
!�0!���#.͙1͑1

   2   First Drive  : >�͡͑1

   3   Second Drive : >�͡͑1

   4   Third Drive  : >�͡>4�i-����2(\�3([�4(Z͑1
	  Select Controller Type as:
 �O!���.��y�
8�>��.���>:�i-(�0�	8>��w �
>�!>�!>��.͑1
		Activate Drive ([Y]/N) ?  ��7˦�N�b����7͑1		Physical Unit (0..7)		[ ��1�~�o& ��-�z� {�8��0�~���wO:b:��(N��7͑1		Logical Unit Number (0..7)	[ ��1~��o& ��-�z� {�8��0�G~��w#���͑1
		Number of Cylinders		[ �n �f��-�s �r�S`:��7͑1		Number of Heads			[ ��1�n& ��-z�(��0��s:b:�� ͑1
		Sectors Per Track		[ )͑1
		Reduced Write Starting Cylinder	[ �n�f��-�s�r:b:ր�_͑1
		Write Precomp. Start Cylinder	[ �n�f��-�s�r:b:�> 02:b:!e=(!�= "͙1��1�n,& ��-8	z� {=�8��0��w�

		Step Rate:
  3mS(1), 28uS(2), 12uS(3)		[ 
		Step Rate:  3mS(1), 200uS(2), 70uS(3), 40uS(4)	[ ͑1
		( y�0��8͑1)  ^#V�Ù1��+8T`my��Owl Adaptec ACB-4000A Xebec 1410a/Shugart 1610-3 Seagate SCSI Shugart 1610-4/Minimal SCSI Conner SCSI Quantum SCSI Maxtor SCSI Syquest SCSI GIDE (IDE/ATA) --Unknown-- �.~�g ͑1 - inactive - �:b:�� ͑1  Unit  ~2͑1  Physical Unit  ~��N8͑1,  Logical Unit  ~��N8#���~#fo��+"`:͑1
	 No. of Cylinders =  ̀8͑1,	No. of Heads   =  �~�N8:b:�� $͑1
	 Sectors-Per-Track=  �n�fÀ8��͑1
	 Red. Write Cyl   =  �^�V*`:��R� 
͑1None ̀8͑1,	Precomp. @ Cyl =  �^�V*`:��R� 
͑1None ̀8:b:����͑1
	 Drive Step Rate  =  !D=(!X�~�G����.~#��8��͑1
	-- Not Defined -- �3mS  28uS 12uS ???  3mS  200uS70uS 40uS >2w:* ;C ^#V�͆%#^#V�͆%"p:��1͑1
Menu 5 - Logical Drive Layout

 ����A��8͑1: =  ���$��7��<�͑1
      1  Swap Drives,  2  Configure Partition 3  Show Drive Allocations >3�i-����1��͑1
   Swap drive [A..P] :  ͳ-�!ڊ�$8�2r:͑1  with drive [A..P] :  ͳ-�!ڊ�$8�*p:]T�.�:r:��.F�p#F�p*p:  +#~#�(7���:�;4 *�;�I(*	�M(*�;|�(	s#rÊ�2":�;�M 5͑1
	--- Can't Configure Running System ! --- ��0��#͑1
	Configure which Drive [A..P] :  ͳ-�ʊ�$8�2e:�o%z�ʊ2s:�(�(
>��8��0 ���7͑1	Allocation Size (1, 2, 4, 8, 16, 32k)	[ :e:�o%^#V#�:��:��:��St:~2d:�@%o& ��->�(��>��8��0��.%"f:͑1		Number of Dir Entries	[ :e:�o% ~#fo#��-*f:#~77�(/͑1  +++ Illegal Number of Entries +++
 ��0��Sh:͑1		Starting Track Number	[ :e:�o% ~#fo��-�Sj:͑1		# Tracks in Logical Drv	[ :e:�o% ^#V:d:��G�[t:> ()� ��"%i`��-�Sl::e:�o%��+�n& ͑1		Physical Unit Number	[ ��-�s��:s:�(##6@#6 # �St:�[f:�������_ *l::t:�?G�)� �80��"%{. �?(7��? �x�(�=}�w#q#p#�Kh:q#p#�i`#�<����"%A!  7�����r#s#6 #6 #�[j:s#rÊ͑1
  Display Allocations for which Hard Drive [0..2] :  ͳ-�ʊ�08��0�O*�;$>����o%�z�(O� H� C��>��Aw#���! N#F�q#p#���^#V�#�(G�)� � �"%��	�s#r#����6 ���1͑1Partition Data Hard Drive Unit :  y�0��8͑1

      Drv	Start Trk	End Trk
 *�;$~� ͑1
	-- No Assignments -- 0͑1
	 ~#��8>	��8^#V#�̀8�͑1		 ^#V#�̀8�~� ���7͑1	[any key to continue] ͳ-Ê�A��0�Q?��0�A��o%{���$���$͑1Unit  �N8͑1,  ^#V�Sn:#�̀8�~�͑1 Sctrs/Trk,  �@%�N8͑1k/Blk,  ^#V#�#��G(�)��%����͓%͑1k ( �[n:�:�����"%i`̀8͑1 Trks),  �^#V�#̀8͑1 Dirs �͑1   -- No Drive -- �� ͑1Floppy  �0��8� ͑1RAM �͑1??? ( �N8>)��8͑1+++ Too Big +++ ɷ���R� 0���!_%�(###�++��]%��# ��(�###�?� *p:��#.T]��͆%�!
 ~#fo�K$;��B�K ;	���� �����R�0����%'��%���%d ��%
 ��%}��%�������R� 0�� y� �(��0G��8�e �  ! ��*�;"�;ͱ6\ ��5͘6 �;/͑1File Not Found! ��,ͤ6(�;/͑1Can't Open! ��,!  ̈́6��&*�;  ��&###��& 	��&###��& 	N#F�C$;�)|2�;l& \ ̈́6 R��*�;� 	"�;ͱ6��#�*�;"�;ͪ)��,�*�;�[ ^#V*$;��R�
 ~2;�h6�C�;�*�;ͱ6! ̈́6��;/͑1Error Reading :  fN#F�	��*�;"�;ͱ6�K�;�S6\ ��5:�;o& �6 "��*�;� 	"�;ͱ6��#�*�;ͱ6! �6(#͟6�;/͑1Error Writing :  ] �8��7͟6͑1
	...File Closed. �* .Z~��.�:/2;�C$;�S";��<-.�[ ;i` 
���S�;�* ;�[$; 
��*$;.?�:/͑1

	..New Configuration Installed..
 ��@2�;�2.:�;* ;�e(�4/:�;�U-:�;�T-�K�;�[�;���w1��:�;G*�;����[�;͉1DM�z1���}1 ̓1���.�� �� Ã1:�;� � ���BK�w1����"�;�T-ʸ.^#V�S�;>	�.^#V�^#V�S�;>�.^#~���.���.2�;*�;.  ��R0��R0�� {�(�C�;�S�;��:�;�[�;!  = ���}2�;�w1��:�;G*�;����[�;͉1DM�z1���}1̀1�£.�� "�;��(:�;� � ���BK�w1����ͪ)��,!  "�;* ;[ N#FY * ;�~� #~� #~��(�$z�8�!  D�� ~2;��~�g. ��[ ;*�;��RMD��)���)���� #����� ���"�;�"$;�Z3ENV*�;" ;* ;>~�.�<-�* ;� " ;�È.͑1
 �-͑1 - Alter parameters in a B/P Bios Image file, Boot Tracks or Memory.
    The program may be interactive with screen attributes under ZCPR3
    or take input from a text Configuration file.

Syntax:
    �-͑1 //		<-- Display this message
    �-͑1		<-- Run interactively

  The following forms may be followed by an optional Config file
  from which to draw parameters to set.  There must be a space
  between the first argument shown and the filename.

    �-͑1 *		<-- Configure Memory Image
    �-͑1 d:		<-- Configure drive d: Boot Tracks
    �-͑1 [du:]fn[.ft]	<-- Configure Image File
    �-͑1 [du:]fn[.ft] [du:]fn[.ft]  <-- Configure Image file (1st 
              filespec) using Config file (2nd filespec).
              Default Type of Config File is .CNF.
 �{�;�  ͑1
	.. aborted ..
 �*	|��>(�.~�:
���3͑1BPCNFG �#~�� ��8���++++++~�B 
#~�/ #~�P��=O �t1|������ <����<_͑1


	Enter Selection :  ͚/� ($�( ���,���,�18�?8��8�>��8��0կ���7� ��8�(���,� �� ������8�̀8�͑1]	:  �.���8�.z��8��->/��8�.{��8�>]��8>[��8�.��8!�;6 ��ͻ6~��* ;�o�$��.~#fo��A��Q?�͑1
Place disk in drive  :�;�@��8͑1: and press return to continue... ͚/���,� ���7�;/͑1Not B/P Bios +++
 7�͑1*** Read Error |͑1*** Bad source! f͑1*** Write Error P͑1*** Bad destination! 5͑1*** No System!  ͑1*** Can't open source file! ��7!  �͑1
+++  ��Ɛ'�@'��8͑1

  Enter Config File (default type = .CNF) :  �.!�;{:��3��0�.0��:v:�(F��/8��; ��/8��(��
 �:y:<2y:��(��
 	:y:<2y:�� (��	(��[(��](�,�>����* .	�:/�����!�::z:�<�082z:�.~�7? �2v:7����!�:ͱ6{:��5ͬ6ľ0���!�:ͱ6{:��5͘6 T�;/͑1Not Found ͑1..using Console Input!
     [press any key to continue] ��/�2v:�ͤ6(�;/͑1Can't Open �>2y:>�2v:=2z:�2�:�{:��5͟6�2v:7�:�:�  �:! ��{:��:v:��r1���;0͑1
+++ Error in :  |:�8͑1,  Line :  :y:�N8͑1 ..aborting to Keyboard..
    [press any key to continue] ��/��  ��  ��7������  �  �  �  �  �  �  �  ���1���͙1���~#�?���(�(�(�(��8�0����1���1���1��2����1���V#^#���2�����:�;*�;�2���[�;���[�;��02�*�;:�;�W~�(��2������*�;�����[�;�(�92:�;��2�������(��;2�%-���%(�\ ��8��:�D(L�2(C�3(;�.(+�+(*�>(�R(�I(�N ү�$,�}lg��0�g�|���8e�| |dʹ2
ʹ2�0��/�0��Gz�0 �A(��8x��~�(#�\ ~#��8�z�����O*<|�(�+ �~�(G��3� ������3���� �����"<|�(� "�;�|�(D~�!8?� ~2�;#~2�;#~2�; �; ��͜3��:�;O	��͜3� ��������3!�;6 #�s#r#�6 #s#r#�6 #�� �����s#r#�~#���\ �#�:k ��!�3~�����5(# ������        ��Ͳ3(~�� (��8#�������:��Y5�����3���2�;�h6�C<�Z4�:>  &#:�;�(͏4�5�5ď4�xy2<��_5��Z4��� 	�~�. #�`4:<�: <�ɯ2 <��A5(#�* +>?�? �! <4���A5(#��> �������w5(p�K<�!8b�:�A8G�!8! �!8�:58JO}�����o% ��  9M*<��B(,͆5�8*͡5�8$*<|�( �~(, ~#fo>�=) �0�������K<���͹5(��#�(�GO���� #����(�� 	���0��
?�~�_��.��,��>��:0� Яɿɯ�_5� q#��w#�h6q#w#�����. ��5�$ Ò5��, ��5�" *<|�(~#fo�����- ��5͹5�� =�0�x��� ��5*<|�(~���*<|�(^#V#~�������h6�(G! N�S6����"<�|�� >Z�� ��16�(* >�O>��G>Z��  �-6���16�� ��|�� O6����76���! ~��#~��3ENV����Y Ϳ7XͿ7��������Ϳ7�� Ϳ7O�G����>"Æ6>!��!! �s#r#6 ����7>��7<�>æ6>��7���>��7�>���7������� �("<*< ͚/�(���Y7�(l�	(&��v7�
(P�(>�(?�(�(w#͖7���7�w#͢7�6  *<ͷ7~�(�͖7~�	(�(#�ͷ7�y�(��^7�6#6
# �C��7�͂7(�+~͖7�(���^7�͂7�+�C�>��8> ��8>��86 �C��7�������[<z��{����>��8���C�� 0��	��7y�G>�G�O�C�> ��8��>#��8��7��� �ѷ����O� ������>��8>
��8����7��8͚/�:�8��8��>^��8��@��8����� 0�����	8�
ɿ�����58>.��8�58y��E8������ �A8����8> ��8 ������&d�d8&
�d8�x8����.��,0��g}� �|�> (��0G��8|������'ͬ8����ͬ8d ͬ8
 ͬ8}ͽ8��������R<0� ��> (��0G��8�|��8}��8����;:��8���?:��8������O>�):�����  B~�:�08�:8�A8
�G0G#�O� 8y�H(!�X(�O(/�Q(+x�B(8�t98~�:�D 9#6͟98~�:#�H((�X(${7����98�~�:#�O(�Q��98�~�:#�B �{����  B~�0?0�
0O�bk)8)88)8	8��#��{���  B~�:�08!�0�
8�8��O)8)8)8	)8	�#�?{���  B~�0?0�0O�)8)8)8	�#�{���  ~�0?0�0
��j8�#�{����~�(�:w#������a��{��_����1:����o��* o���Ɛ'�@'���*U:� j���<                                         