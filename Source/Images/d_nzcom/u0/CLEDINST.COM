�	Z3ENV �CLED Lead-in Ke�Backspac�Char Lef�Char Righ�Word Lef�Word Righ�Line End/ Star�Line Star�Line En�Delete Cha�Delete Lef�Delete Word R�Delete Word L�Delete to SO�Delete Lin�Delete to EO�Toggle Inser�Enter Contro�Recall Pre�Recall Nex�Execute Lin�ESC Menu �*	�=�s  *q0 �"	  " �1*	� o���:] �/�C� (e � ��͛�4�
* �[	  ���tͨ1y2~I� ��h���
*	  " ���>2��6�	~#��ͨ�[�M�I� ���># > ���:�<���DE����ES����C����TA������:�G!�(~#����������:��
g�K��#�o�F��ɯ���:���0��G��(�C���6�	�7_�ͨ�	������g.g ����� �!ҩ�A�H�[�T�A���A:�� ��H����� ���s�7#�(��� ���G�����A�{�����DE��[��ES��I��TA��M�� C����[� * ���K��#G:��2����6ɯ2�2�2��!�!�4{��6 �!�!�~�(5�s����

                         DEFAULT INSTALLATION

<CR> to skip a fiel��.͈ͺ���>͊��

HEX strings are terminated by 00 or high bit se�ͻ�1��

All OK? (Y/n)��7�N��.�F��*	 " � &���Insert vs. Overwrite       (Y/N)  ��|��  ��7�Y(�N�6 6����~�>N�>Y�& ���History recording ON       (Y/N)  ��]&	 ���Erase stored line on exit  (Y/N)  ��]&
 ���Minimum line to save       (DEC)  �~<�t��  �>�jͅ�����(=* w�&  ���DU:DIR separator        (1 char)  �~���  �>�jͅ����[ ���& ���Time string separator   (1 char)  ��& ���Dim video ON               (HEX)  ����&.$�F���   �>�j�* ͅ����(�s �#���* ~�����#��&  ���Dim video OFF              (HEX)  ����&�!� ��w�
�� �#^ #�6 ����~#� (�+�����
NOTES ON RCPCLED INSTALLATION


Default Settings:

The last command line executed is saved to the top of the history stack if it
is as long as the minimum size you set.  To reduce cluttering the small stack,
"minsave" is set fairly high (6).  For secure systems, a flag may be set to
automatically erase the history when the CLED shell is exited.


Key Installation:

"Recall Prev" reloads successive lines going back into the history stack.
"Recall Next" reverses direction in the history stack.  The ESC key accesses
a separate control list:  ESC-Q quits the shell.  ESC-S toggles history
recording ON/OFF.  There may be more line editing functions available than
you want to use.  You may assign the ones you like to convenient control
keys and disable the others.

 ��Strike Any Key -- ��$�g���
     Letters in the table below represent CONTROL KEYS.  Those followed
 by a "#" are shifted keys which are scanned only after the lead-in key
 has been pressed.  Each command must be assigned a unique key.

 Cursor Movement:  ^E  Up,  ^D  Rt,  ^X  Dn,  ^S  Lt   (Or Arrow Keys)    
 Quit: "."  Skip: <sp>  To Enter CR/ ESC/ DEL/ TAB Use Key   Disable = "-" ����* ESC Sub-menu:  Q - Quit shell,  S - Toggle Sav�����
                     >>> RCPCLED 1.3 INSTALLATION <<<

�:�� W��Installing memory                  History Buffer Size �& �&^#V�ͮ�� byte�͒��


    1  Set default options
    2  Install control keys

    I  Information

    S  Save changes
    X  Quit


Choice:��7ͨX.S� �����#(##� �#���^#V�������B ����G���(
�#�	�0�=������# ���������~#���(�(�������������_� ���������� �(�������$�a��{��_�:i 2 �: 2i �!h �w#���J\ �� <�\ � 2�y������ �n����� ���File: �\ �3x�A�y�tͲĿ����R�����~#� ����� No fil���6
>���;>�2�����t*	 �[  ��:�����2��:��("��

Save Changes? (Y/n)��7�N�����7�{  ���
RCPCLED (Command Line Editor) Installation, Version 1.3b
  Syntax:  CLEDINST          Install CLED in loaded RCP package.
           CLEDINST <file>   Install CLED in RCPxxx.ZRL disk file. �;*	 ^#V#~��m� �>���m"  " �* >�K ��(��� CLED not found in RCP disk file. �;�� CLED not found in current RCP package. �;�C�\��>` * �t" !_ ��B" �l�=2���Q�\>�K * �t�l!� ���ZRL     ������V#^#���F�����: * ��* �* ���* : �W~�(��������*( ��*  �*" � �����������[ �(�f: �	�����������%-���%(�\ ���X�D(K�2(B�3(:�.(-�+('�>(�R(�I(�N ү�$,�}lg��0�g���e. �| |d��
���0��0�8���z�0 �A����~�(#�\ ~#��z�����O*M |�(�+ �~�(G��/� ������5���� �����"M |�(� " �|�(&~�!8!   ��
͡���͡�������! 6 #�
s#r#�6 #s#r#�� �����s#r#�~#���\ �#��� ��~�(��# 	~� #���� 	������###�w���" *M ~#fo���� ��*M ^#V#~�ѷ�"M �����3�(G! N� ��������Y �JX�J�����J�� �JO�G������� �������h>.��h������ ������&d͊&
͊͏����͖0�0�|�.�,�0��g}� �@(> �� 7�����'�����d ��
 ��}�����������0��=<�R0�� �@(> ��ˀ7����c���g����  ~�08�0�
0�bk)))_ ��#�{���  ~�X�08!�G0�:8�A8�0�
8��))))O 	�#�{����a��{��_��Ɛ'�@'�!O �}�($. ��   