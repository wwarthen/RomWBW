�Z3ENV  * ͜ "	͠�j�:�o� -� B/P System Build  V1.0     31 Aug 92 
 �f +���#��R�6 #{� ��s�$1�$�!�C�$:] �/� � (u!e ~�  	�!` ��!] � ����#͟� ��#�C� 
+++ Can't Read...any key to continue w/defaults +++ ��!��#�!� ��!�#��w#� �!��#����!�$����!�*$���!�q$���D	́� �`��`�����1(�2�V�3�[�͝	����%�͈� 
..building system..

 !  ""��#!���"M$	͢"�*"]$�*�"[$͢"��9$!���"O$	͢"�*"Y$�*�"W$͢"��9)$!���"Q$	͢"�*"U$�*�"S$"��9*"d$*?"j$*B"h$*E"f$� 
Auto-size system    ([Y]/N)? :  ��!�����N>� �2a$� 
-- Pre-linking Bios for Info -- *"�!  "�*��[�"��[S$"��K�*Q$	����# DM"l$*�	"��[S$"	*Q$	)$��*l$� ~2c$�2b$ � (Non-Banked) � (Banked) *��[�MD*l$]T6 ��:a$��ī�()*j$"?�*h$"B��R)|2A*f$"E�[B��R)|2D=� 
Set to "Standard" if possible? (Y/[N]) :  ��!�����Y�y��[E�S��[B�S��[?�S�:c$�(;�z��� 
+++ CPR Starting Addr Too Low (<8000H) +++
 �	*"�*E"�*""�*$"�*"�*"*&"+�f !� "�"�"�"�"�""!"-*�$"�"��*[$"*���K�*M$	����# MD"l$*�	"��[[$"	!�"�$*M$	�#��*��[�"�"��[W$"��K�*O$	���Kl$*�	�[�MD"l$!�"�$*�	"��[W$"	*O$	$��*��[�"�"��[S$"��K�*Q$	���Kl$*�	�[�MD"l$*�	"��[S$"	�[U$"n$*Q$	)$���[n$��#��R͢}l& ��j"_$��0�� 
   Total  q$�$"�  size =  ��"� H sectors
 �[l$!� �Kq#p 	~2+!C ~#fo�K���B#~#fo��B  +#~#�(7����S4*�"<:�2;2>��#�!� ���K_$��#���5	� 
..Error Writing output file..
 �5	�(����!�    ...aborting...
 �5	� 
 �|�  builds banked and non-banked parts of a B/P Bios.
 It operates with layered Menus and supports tailoring of defaults.
 Starting locations of BIOS, DOS and CPR may be automatically computed
 or Specified.  If ZSDOS2 is the selected Dos, Bit Allocation buffers
 for Hard Drives are located in the System Bank.

Syntax:
    �|�           - Generate system w/defaults
    �|�  fn[.ft]  - Make/Modify a specific system
                       (Default type is .IMG)
    �|�  //       - Display this Message
 �{�$�x�K�$�� �͈� 
 Main 


	 1  File Names

	 2  BIOS Configuration

	 3  Environment �͈� 
 Files (1.1) 


	 1  Command Processor File :  �#�"� 

	 2  Operating System File  :  $�"� 

	 3  B/P Bios Source File   :  *$�"� 

	 4  B/P Executable Image   :  q$�"́� ��������5ҝ	�#!��1($!��2()$!��3(p$!�2�#�� 
		 FileName[.Typ] :  �:�\ ͙!�r��(>��"Ý	:] � (��:e �  :�#�e  !`�4(
!c�3(!f���!\  ���!]  ��Ý	͈�  Environment (2.1)  ��COMMON (Bank 0) MEMORY              BANK 2 MEMORY ��----------------------         ------------------------ �� A   Common BIOS  -  ��       Size       -  �� B   Common BDOS  -  ��       Size       -  ��	 C   Command Proc -  ��
       Size       -  �� D   User Space   -  ��       Size       -  ��" E   Banked BIOS  -  ��"       Size       -  ��" F   Banked BDOS  -  ��"       Size       -  ��	" G   Command Proc -  ��
"       Size       -  ��" H   User Space   -  ��"       Size       -  !ͣ*E�6�!ͣ�����K�x����R)}�($|�C!B�!!	?�!!��!!6��!!6��!!6	��!!6��!́� �������!E�A(1!B�B(*!?�C(#!��D(!��E(!��F(!��G(!��H �͑�|�� }��i`�͈�  Environment (3.1)  �� A  - Environment   -  ��       Size (# recs)-  �� B  - Flow Ctrl Pkg -  ��       Size (# recs)-  �� C  - I/O Package   -  ��       Size (# recs)-  ��	 D  - Res Cmd Proc  -  ��
       Size (# recs)-  �� E  - Command Line  -  ��       Size (bytes) -  ��" F  - Named Dirs    -  ��"       # of Entries -  ��" G  - External Path -  ��"       # of Entries -  ��" H  - Shell Stack   -  ��"       # of Entries -  ��	"       Entry Size   -  ��
" I  - Msg Buffer    -  ��" J  - Ext. FCB      -  ��" K  - Ext. Stack    -  !�!!�!!�!!	�!!�!!9�!!9	�!!9�!!9	ͣ:!�C!9
ͣ*"�6!9ͣ*$�6!9ͣ*&�6́� ��������A8�!(I!�B(B!�C(;!�D(4!�E(-!�F(.!	�G('!�H(.!"�I( !$�J(!&�K(�%͑8��%��8����8��͇8��� 

 � 		Selection :  �N��!� ��������08��:8�A8��[0���"�N(>Y��"�Y(�>N��S�$"�$��"�͙!�4!��͙!�N!��5>�2�$�*�$̀��Q�����[�$�D!�   -  CSEG= ���"� H, DSEG= ���"� H
 ���*|�*� |���         Bank2= *���"� H  B2Ram= *��"� H
 ��[�! ��R8C�[�! �R88��; !  ��R"�*E"f$ �R"B"h$>2D �R"?"j$>2A�� 
		+++ CPR or DOS too Large +++
 �	���S�$͙!�4!�(͙!�N!� )>�2�$>*�$��̀� 5���� ..not found.. ��!��� ..Open Error.. �[�$�D!��!�� 
..Link Error.. ��A0�Z"> ��"�  in  �[�$�$"�D!�5	���:�$��8!� ͏!�[�$�V!�7 _ !� <2�$~�����_BIOS_�     _ENV_�   �  _MSG_�      _FCB_�      _MCL_�      BANK2�      B2RAM�      RESVD�      _SSTK_�     _XSTK_�     ��[l$*n$��RMD�������͈�� ����:����?
 �8��
O!00	�r#s##���!��͝�����k Bios ������00255075\ �N!� ��#͏!\ �V! � ͏!\ �V!���7���p$͙!�4!(%!p$\ 	 ��!] ��\ ͙!�I!�p$�[!((p$͙!�;!����͏!͊!��� :�� �x� ��D!��� 
 +++ ..Error Renaming:  q$�"��!�5	� 
 +++ ..Error Writing to:  ��*	|��>(͝~�:
��Y� BPBUILD �#~�� ��"�Ʌo�$� }�o���� 
Sizing from lowest ENV element =  ��";��R"�:b$� �[d$��R�[���R. "f$�[��R"h$�[��R"j$�*�|� %� 
     <No Resident User Space> � 
     Base of Usr Sp =  ��"� 
     Base of Bios   =  *f$��"� 
     Base of Dos    =  *h$��"� 
     Base of Cpr    =  *j$��"�W �:���! 	 N#F+>���#�= �>���= �#�i`�^#V#z��~��{�z��KB�#~#��+~#�~��F+N#����">H��"��2��,#�͒"��2��#� ]	:  !�$6#6 #6 ++��í!�M.
ͣ� Selection (ESC/Ctrl-C Aborts) :  ��!�����{# ������M#����M$$.ͣ� Size	 [ �~�o& �&�0>��"�{w�����M$$.ͣ� # Entries  [ �~�o& �&�0�>��"���M$.ͣ� Address	[ �^#V+����0>��"�s#r#�ͣ�og�6�$ͣ��">H��"͢)|�> ��"��Z"�*	2 f%%%%%��BAKIMGRELZRL                       �   �          ZCPR33  REL                     ZSDOS   ZRL                     B/P-18  REL                     BPSYS   IMG     �  Z3ENV��� � � � � �� � � ������ ��  P� PB: � � � �SH      VAR                                              "�$��������C�$!%6 #��"%"%��S%�!%�w �s%�| �� F �� ~�I�| ͪ��| �|(4͙�*%	}�ͭ�|�ͧ��| 
͙�*%�͙�*%��[%�����(o�(t�(g�(i�(\�
(<����(?8�� N(:%�(�<�8�*%s��[%�K%��{%�����>N!>S�͐"%�� �
͐"%�� ���ø͐�[ø͐�[�*�$%�~>C ��� � ,#�� %� �� F(^#V�S%#^#V�S%�[%s#r� ���ø͐�� N(:%�<�_(�*%s�*%:%��_�K�$�8 C�� N(�[%�K%]T	������ ��� N(-}�2%�<���[%"%G�~(�_�[%�� �����ø���W�!% 6 #�����w#� �6���G͋O>��Jx�yɯ��2%����go"%�7����� F��� ~�\�w �#�� N��!%4�^�6 *%s#"%^���|7 ? ���� n��� v��� ����@�������~#�?���(�(�(�(��"�0���X��`��N�͝���@���V#^#��ͣ�����:'%*,%Ï���[.%���[0%�ý��p�����[2%��~�����[4%�ý�*(%:%%�W~�(�[������*:%�����[*%�(��:&%�l�������(����%-���%(�\ ��"�ͧ#�D(L�2(C�3(;�.(+�+(*�>(�R(�I(�N ү�$,�}lg��0�g�|���"e�| |d�A
�A�0��/�0��Gz�0 �A(��"x��~�(#�\ ~#��"�z�����O*^%|�(�+ �~�(G�͒� �����͘���� �����"^%|�(� " %�|�(D~�!8?� ~2"%#~2#%#~2$% %% ���)��:"%O	���)� �������#!%%6 #�s#r#�6 #s#r#�6 #�� �����s#r#�~#���\ �#�!Q~����� (# ������        ���:(~�� (��"#�������^#������̈́���2Z%�!�C\%���:>  &#:Z%�(�Ė͖��xy2\%��������� 	�~�. #��:\%�:[%�ɯ2[%���(#�* +>?�? �![%4����(#��> ��������(p�K\%�!8bͧ#�A8G�!8! �!8��8JO}�����o% ��  9M*\%��B(,� �8*�) �8$*^%|�( �~(, ~#fo>�=) �0�������K\%����A (��#�(�GO���� #����(�� 	���0��
?�~�_��.��,��>��:0� Яɿɯ��� q#��w#�!q#w#�����. �H �$ � ��, �H �" *^%|�(~#fo�����- �H �A �� =�0�x��� �U *^%|�(~���*^%|�(^#V#~������w �[ z�0������*^% �~(
7 ^#V�* �����"^%�|�� >Z�� ��� �(* >�O>��G>Z��  �� ���� �� ��|�� � ����� ���! ~��#~��3ENV��!�C`%����K`%�!������Y ��!X��!����������!�� ��!O�G����>��!<��N!�>�P!>�P!>�P!>��!���>��!�����!b%�$�n#�s%# ���c%# ��b%��!���<�>��!�>���!������� rr# ����������
� �#~#�_ 6 ���^#��+~#����� �ѷ����O� ������>��">
��"����!��"��!ç#�>Ͳ#��������"�>.��"��"���������A">.��"�A"y��Q"������ �M"����"> ��" ��� �c"����&d�v"&
�v"͊"����.��,0��g}� �|�> (��0G��"|������';"����;"d ;"
 ;"}��"��������R<0� ��> (��0G��"�|��"}��"�����#��"����#��"������O>Ͳ#����  B~�0?0�
0O�bk)8)88)8	8��#��{���  B~ͧ#�08!�0�
8�8��O)8)8)8	)8	�#�?{����~�(ͧ#w#������t#���w#���͖#�Â#�O�ͧ#�A8�[8��y���O��08�:8��y����a��{��_���ͺ#����o��* o���Ɛ'�@'���*�#� j��Ɇ%                                