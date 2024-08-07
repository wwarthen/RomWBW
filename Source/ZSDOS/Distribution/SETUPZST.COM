�Z3ENV  �s�!1�!!  "! ��"0 ͕!2 3 M6 ��!�L  ��!� ~##�ʤ�¤~#�/¤~�/¤�

SETUPZST  V1.2   Create/Modify ZSDOS/ZDDOS Time Stamp module

  Syntax:

       SETUPZST       - Enter interactive mode
       SETUPZST fn    - Set defaults in file "FN.COM"
       SETUPZST //    - Print this message

  Note:

       Creation of Stamp module requires access to 
       STAMPS.DAT and CLOCKS.DAT.
 7�=���
+++ ZSDOS is only for Z80 type computers!!! �R�~$"� T]6  0�� !�X �� !�| �� !�� �����C!�}ͰSETUPZST V1.2     Copyright (C) 1988/93    H.F. Bower / C.W. Cotrill :] � (!� ~� #(�+��25 �ʸ�C	!ͬøͰ
1 - Generate New Time Stamp Program Ͱ
2 - Examine/Modify Existing Time Stamp Program Ͱ
X - Exit to DOS Ͱ
Enter Selection :  �a�G�X�R�2�g�1 ���Ͱ
Select type of Date/Time Stamping : Ͱ
1 - DateStamper (tm) Ͱ
2 - P2DOS (CP/M Plus compatible) Ͱ
3 - Read DateStamper (tm), Write Both DateStamper & P2DOS Ͱ	
4 - Read P2DOS, Write Both DateStamper & P2DOS Ͱ

5 - NZTime Ͱ
6 - Read P2DOS or NZTime, Write P2DOS or NZTime Ͱ
7 - ZDDOS Clock interface ͰChoice (^C Exits) :  �a�G�18��80���D!�7((S!�5(!$�6(!��2(!��1(
!�3(!y2- A  ��ͰLoad as an RSX below the CCP? (Y/[N]) :  �a�G�!2�Y 	!/͌͔y2. I  ���Ͷ��(CͰInstall in NZ-COM User Space? ([Y]/N) :  �a�G��N(͌͔y2/ !� ! ��ͰLocation of STAMPS.DAT file [ ͣ�:]     :  �a���(�*�ͶͰ..Extracting files from STAMPS.DAT.. !���W �j�K	!ͬ!A ��{ �j���K!ͬ�2!Ͱ
Extract Clock from Library ([Y]/N) :  �G�N d͔Ͱ
Name of User-supplied .REL clock :  �a��C!:] � (�!] �  ��� �$�� >����K!ͬ�w	��2!͌Ͱ
Location of CLOCKS.DAT [ ͣ�:] :  �a�!� ! ��Ͱ !�$��� �*�R��((Ͱ
-- Error initializing DAT file �R�~MD!!��"((Ͱ
-- Memory overflow in DAT file �R�~�͍�o� �1���  ͳ�yͣ�.  ���   ͳ��! ��>��ͰEnter Clock Driver Selection :  �a!� 6
#6 +��8!� �~� �z� �K�~��(� (x�(0! �Ͱ-- Error in locating Clock file þͰ..Loading :  ��� ...  �6  ��!6 ��� �j{ �$�կ�_���Q"� 	}�(#�"� :!� �K!ͬ� �$�կ�_���Q"� 	}�(#�"� �K!ͬ��Ͱ
Linking Loader Module..  W �$�� �*�R�կ�_���Q"� 	"� �$� *� 	���K� *� 	���>�_ѷ�}*�  :- w�OK *� }�(. $�[� "=$"Q$.�"� �*� �K� 	"� �. s#r.�"� Ͱ
Linking Time Module ...  { �$�  �[� ��K� ! 	"3 *� 	���>�_ѷ�}�OK Ͱ
Linking Clock Module...  :!� �K!ͬ*� �[� "� *� � �$��K� *� 	���K� *� 	���>�_ѷ�}�OK
 �K!ͬ*� +++ �~F��� � 6#6#6 *� �<��#�[� "� �[� ��R}��($l& "� ! :. � +w+w##:/ � +6�+6�##�[� s#r#�K� q#p:. �(	�	�*3 s#r��!
͘*=##��o�o*= ��o�o!�!N#F#^#V#�x�(J���� (Default= ��(�����H) :  �G�(�!  �Y}|��o��*3  ��R�ͅ#!�����o!͘�K!ͬ�{�!�����ͰTime Stamp File to load [default type = .COM] :  �>�25 :] �?(�!͹!,ͿL !]  �����   *� "� ���\ ���� *� ��C� \ ��!͹*� ###^#Vz� #Ͱ
Module will load below CCP Ôz�<��Ͱ
Module will load NZ-COM User Space.  Change? (Y/[N]) �G�Y(I͔�Ͱ	
NZCOM user area size (in bytes) must be  �#N#F#^#V�+	��>H���͌��Ͱ	
Stamp Routine :  ������>-����#N#F#��	�+��>H���aͰ

Clock Driver  :  ����>-����N#F�+	��>H��Ͱ
Change Load Address (Y/[N])? :  �a�G�Y 5͌ͰEnter HEX Load address :  �a�S�*� ###s#r��͔!͹Ͱ
CCP Size is :  *� 	 ^#V����H.  Change it (Y/[N])? :  �a�G�Y 5͌ͰEnter CCP size in HEX :  �a�S�*� 	 	s#rÔ͔Ͱ
Opening Message : ________________________________________\ )>���!� 6)#6 +��8O ��*�  	N#F*� 	����͔Ͱ
Name of output file [Default =  ͣ>:��L ͅ�] :  �a:5 � *!"	!�:] �?(� �!,Ϳ� !L ]  ��\ �$� �K	!ͬ\ ��(PͰ
+++ That file already exists.  Overwrite it (Y/[N])?  �a�G�Y͌\ �Ͱ ..Saving :  ͣ�:  ] ͅ\ ��<ʬ*� ��\ ��¬� �*� +"� |�� �\ ��<ʬͰ..Erasing Work Files.. �a�K!ͬ![ 6?#6?#6?W �$�Ͱ
<< System Saved.  Good Bye >> �a�R~#��������Ͱ
+++ Can't find :  ͣ�:  �Å�Ͱ
+++ Error sizing :  �ͣ�:  ͅ�R��Ͱ
+++ Link Error :  ���� in file :  �Ͱ
+++ Error on file open �\ �(ͬ�RͰ
..Loading  ͣ�:  ] ͅ�o!��͘�a�$���!� 6#6 +>��8\ !� \ >�/:i O:\ G�[!� By< K�C	!ì�|�B��R�!  �G22 ���q0��:2 ���ͅ��0���
���
8�ɯ=�))))�o��YES ��NO ���>H����x�A��yé�o�!͘�ae � (�?� �����������!����(Ͱ
-- Error in :  *�[(.Ͱ
-- Error Opening :  �ͅ� in   !ͅ�R�~ �!�/ � �<�Ͱ
-- Error Reading :  !���K!ͬ�$����<ʬ�~��¬�� ����<ʬ�???????????CLOCKS  DATSTAMPS  DAT---LDR--TMP---TIM--TMP---CLK--TMPLDTIM   COMINSTZST RELP2D     ZDS     ZDDCLK  DS2BOTH P2D2BOTHNZT     NZP2    COMLR HR _CLKID�   _PARM_� �!_PRE_�    _POST_� �#� ��"���������C�!��6 #��S��!��w >�2��s��[������] ���O��� F �� ~�A�K ͜��K �K(4͋�*�	}�͟�|�͙��K 
͋�*��͋�*���[������ʌ�ʒ�(}�(v�(r�
(R����(U8�� N(:��(�<�8�*� s#"� ���[�����[��K���{������>�!>�!>�!>�!>��͂"��� �
͂"��� ���ê͂�*ê�*�!5��� � #�� ��~  ^#V�S����~ 
 ����ê͂"��*�:��(��8 4�[��� V(�*������� ��[���R��f�f|�ʪ��͟�+��[���� ����ê���W�!� 6 #�����w#� �6���0��:���8!�����[�����`_ !�<2�N���yɯ��2�����go"��7����� F��� ~�c�w �#�� V�*�#"��� N��!�4�^�6 *� s#"�  ���K7 ? ���� n��� v��� ��������������������S�������~#�?���(�(�(�(���0���k��s��a�͒���S���V#^#��͘�����:�%*�%Ä���[�%���[�%�ò�*�%:�%�W~�(�P������*�%�����[�%�(ͻ:�%�a�������(�ͽ�%-���%(�\ ����B�D(L�2(C�3(;�.(+�+(*�>(�R(�I(�N ү�$,�}lg��0�g�|���e�| |d�6
�6�0��/�0��Gz�0 �A(��x��~�(#�\ ~#���z�����O*�%|�(�+ �~�(G�͇� �����͍���� �����"�%|�(� "�%�|�(D~�!8?� ~2�%#~2�%#~2�% �% �����:�%O	���� �������!�%6 #�s#r#�6 #s#r#�6 #�� �����s#r#�~#���\ �#����2��h����A���2�%���C�%͟�:>  &#:�%�(���S�S���xy2�%��n�͟��� 	�~�. #ͥ:�%�:�%�ɯ2�%��P(#�* +>?�? �!�%4���P(#��> ������͆(p�K�%�!8b�B�A8G�!8! �!8�I8JO}�����o% ��  9M*�%��B(,͎�8*͖�8$*�%|�( �~(, ~#fo>�=) �0�������K�%���ͮ(��#�(�GO���� #����(�� 	������%�ͥ��(ͺ��̺(������P(	�B#��> ����͆(O���P(F�B�A8G#�P( �P(�I8,O{�����_# ��P Ki`����B�(͎=�8͖�8��������͞()����(!=GO���� #����(� 	��������0��
?�~�_��.��,��>��:0� Яɿɯ�n� q#��w#��q#w#�����. õ��, õ��- õͮ�� =�0�x��� ��*�%|�(~���*�%|�(^#V#~���"�%�|�� >Z�� ���(* >�O>��G>Z��  �	����� ��|�� +�������! ~��#~��3ENV���! N#Fy�(p+q+F+N�q#p ����(���������"�%!� �! ��N#F!  �� ��ͩ��(#x� ��������"�% � ��*�%# �����!� ~� �#�[�%���_� ����   ��������!� �! 6 #�! ��$�> '�>  �!� ~� #> � #�~#�#> ����������!� �����: �
2�%"�%�C�%! �N#F!  �� ����h���(#x� �*�%w������!� ~� 1�#�[�%��?(� #��*�%:�%�8��� ���S�%� �   ��������Y �ZX�Z���������Z�� �ZO�G����>!��!! �s#r#6 ���c>�c<��>�c���>�
>�
>�c���>�c>�c�>��c������� rr# ����������
� �#~#�_ 6 ���2��+~#����� �ѷ����O� ������>��>
�����>�M���������>.���������� ì����&dͿ&
Ϳ������.��,0��g}� �|�> (��0G��|��|��}������q�����u��������O>�M����  B~�0?0�
0O�bk)8)88)8	8��#��{����~�(�Bw#������a��{��_����U����o��* o��~��?(O���#���Ɛ'�@'���*�� j����%                                                                                                                   