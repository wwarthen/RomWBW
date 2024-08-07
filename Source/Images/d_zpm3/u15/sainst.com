�Z3ENV  SALIAS�*	ͫ�)�s$*0 "'�] �/ʭ�  !� ��e �  !� ���$�6ʕ*'d �Q*'��.")�['��R�%�l& " *	� =
~�(����G��
                         SALIAS 1.6 INSTALLATION


Installing  �v����    1  Install Editing Keys
    2  Install Word Separator Chars
    3  Install Insert/Overwrite Flag

    I  Information

    S  Save Changes
    X  Quit

 ͅ��X^.^S4I�1�2�3< ���G��

                        COMMAND KEY INSTALLATION

     The control key bindings are listed in a table.  Letters represent
CONTROL KEYS entered while editing.  Those preceeded by a control character
are shifted keys scanned only after one of four lead-in keys has been pressed.

     To change a key binding, move the cursor to the function you want to
change.  To make it a shifted command, first enter a number 1-3 corresponding
to the lead-in key you want to assign.  Enter a character "A" through  "^"
for the base control key.  If you don't want a function implemented, enter
a "-" for it.

     For example, if lead-in key #2 is ^Q and you want to assign the control
sequence ^QZ to a function, first enter "2" then enter "Z".  The display then
shows the current key assignment.

     DEL is converted to ^_ by SALIAS, so that control key is not available.

 ��Strike Any key --  �.Õ
 ͭ�KͰ����Default Insert On?   ~͉��  -->  �.���Y(�N��w�=wͤɷ>N��>Y��5 ͭͣͰ����Install characters recognized as word separators.  You can use no more
than the number below.  To use fewer, just repeat some of them.  Do not
start with a space.  [<CR> to skip installation]

Current   ->  �~��#���
Change to ->  >�����ͤ�~�������G�� Each command must have a unique key.  Letters represent control keys.  Enter
 a number 1-3 BEFORE entering the key to bind it to one of the lead-in keys.
 To disable a function use "-".  ESC CR DEL are entered directly.  TAB is "I".

 Quit - ^C or "."     Skip - <sp>     ^E Up, ^D Rt, ^X Dn, ^S Lt (& Arrow Keys) �ͬ͗
*) "*��	�
�)�2� 	;	:<�	:�
��	~#�-�{	��*��(-��(�#��(�#�~ �@ʹ	ʹ	�[ ͍	ͬ	����_�@��_�@��_�	[�	I�	M�	 ��͹	���DEL ���ESC ���TAB ���CR ��>^�����>��> ��͹	:G!�(~#���	�������:�g�K��	�o�b��ɯ���:��0��G���	�C�͗
��	�.����
	�
�
�
.�� j
\
a
R
W
\
a
R
W
 �!��
�
ͩ
ͼ
͵
͢
̓
�
͢
:� �ͩ
��[ *��K��	G:�2�)د222�!!4{��6 �!!~�(5�s�ͤ�x
^6 �18'�50#�0G�*�+�#= ��~ �-̾�
>`� �w�.���-(��w��     �� 	�:��
�{�̬*��	�2�<�
�
�x
~�-�:�<G>`� �_)*~�� �>)�2�
��	��   ? �#��2�Lead-in Key #�Lead-in Key #�Lead-in Key #�Backspac�Cursor L�Cursor R�Cursor U�Cursor D�Word R�Word L�End/Start of Lin�Line Star�Line En�Up Scree�Down Scree�Delete Cha�Delete Char L�Delete Word R�Delete Lin�Delete to EO�Carriage Retur�Insert Lin�Indent Lin�Indent Scrip�Insert/Overwrit�Control Cha�Fin�Replac�Repeat Find/Re�Clear (Zap�Save & Resum�Save & Clea�Save & Qui�Qui�FILE Mod�Renam�Read Fil�Toggle Mod�Undo Change�Print Scrip�Hel��:����  Saving...  �+�6*)�i�I�2��:��(#��Save Changes? (Y/n)  �.���N�:��G�7�{$��� No file �6
>�g���SAINST - Default option and command key installation for SALIAS 1.6
  Syntax:  SAINST [salias.com]
 Í�d 	�>�W������� Installs only SALIAS, Version 1.6 Í�����B ����G��x(
�#�	�0�=������# ������Choice:   ��.��*)""���=2��� ͜����!����~#�������>����������#(##� �#���^#V����!� w��!� 6<�
�� �#^ #�6 �������~#� (�+��:i 2&�!h �w#��:&2i \ ͹� <�\ � y������K����� ��"* "} ���File:   \ ��x�A��y�Y�EĠ>:���7>/��~#� ����� 0ͬ	�����>����SALIAS  COM�����������~#���(	�(
�������������V#^#���b�����:2*7�N���[9���[;�����/�����[=��=�����[?����*3:0�W~�(�f������*E�����[5�(��:1�w���������̈́�& �O�[I̬�ܬ�ܬ�ܬ:/�g�:/�g ��gɠg���������[G�(����%-���%(�\ ������D(L�2(C�3(;�.(+�+(*�>(�R(�I(�N ү�$,�}lg��0�g�|���e�| |d�L
�L�0��/�0��Gz�0 �A(��x��~�(#�\ ~#���z�����O*e|�(�+ �~�(G�͝� �����ͣ���� �����"e|�(� "+�|�(D~�!8?� ~2-#~2.#~2/ 0 ���4��:-O	���4� �������.!06 #�s#r#�6 #s#r#�6 #�� �����s#r#�~#���\ �#�͒ ��~�(��# 	~� #���� 	�����###�w����*e1 ����" *e|�(~#fo���͡�� �0�x��� è*e|�(^#V#~���������(G! N������"e�����Y �X������������ �O�G�����>�������� �ѷ����O� ������>��>
�����>���������M>.���M������ ��������&d�o&
�o̓����.��,0��g}� �|�> (��0G��|������'ͷ����ͷd ͷ
 ͷ}����������R<0� ��> (��0G�����������������O>�������a��{��_��������o��* o���Ɛ'�@'�g                                                                                                     