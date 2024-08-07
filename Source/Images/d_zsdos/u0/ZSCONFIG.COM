�Z3ENV ��s�1�!�6 #�>�2�*	Ϳ"	�Q��"�Y0�"�!� F#����/2��#~�/�ͳ

ZSCONFIG Ver 1.0 - Examine/Set ZSDOS/ZDDOS parameters

  Syntax:

     ZSCONFIG                - Interactive
     ZSCONFIG o[p],[o[p]],.. - Expert Mode

  Options [parameters]:

     P [-] Public Files        R [-] Read/Only sustain
     ! [-] Disk Change Alert   F [-] Fast Relog
 ͊ :ͳ     W [-] Public/Path Write   S [-] Path w/o SYStem ͳ     W [-] Public Write ͳ

     C [ - or Hex value ]        Clock address
     * [ -, Z, or Hex value ]    Wheel write protect
 ͊��ͳ     > [ -, Z, I, or Hex value ] DOS Search Path

     + [ A, C, M, G, or S ][ - or Hex value ] Time Stamp
            Access, Create, Modify, Get or Set addresses
 ;ͳ
       + [ A, M ][ - ]  Access or Modify Time Stamp
 ͳ
[more].. �,�ʴ>�]��ͳ  Examples:

       ZSCONFIG *Z,P,!-
    (ZCPR3 Wheel, Public ON, Warning OFF)

       ZSCONFIG CE800 F R
    (Clock Routine=E800H, Fast Relog ON, R/O Sustain ON)

 ͊ lͳ       ZSCONFIG C50,+GE96C,+SEA47,>I
    (Clock=0050H, Get Stamp=E96CH, Set Stamp=EA47H, Int Path)

 _ͳ       ZSCONFIG C50,+A-,+M
    (Clock at 0050H, Last Access stamp off, Modify stamp on)

 ͳ  Note:
       Delimiters are : TAB, SPACE and Comma

 ôͳ
ZSCONFIG V1.0   Copyright (C) 1988   Harold F. Bower/Cameron W. Cotrill

 :����:��S(*�D�Y:��ͳ  ...Configuring ZDDOS Ver  #:��ͳ  ...Configuring ZSDOS Ver  ��̀�]>.�]�̈́�]�:�� e*	|� "ͳ
No Z3 Environment Found
 Æͤ(Z3 Environment at  :  *	ͭ͵(ZCPR Path Address  :  	 *	^#V�"�:�� ͭ͵-Wheel Byte at :  ) *	^#V�"�:�� ͭ�: �g. "���� ��"��^�V�S�:�����͔��!�ͳ       1 - Public Files           :  �*��� F�6͊ ,ͳ
       2 - Pub/Path Write Enable  :  *ͳ
       2 - Public Write Enable    :  �*��� N�6ͳ
       3 - Read-Only Vector       :  �*��� V�6ͳ
       4 - Fast Fixed Disk Log    :  �*��� ^�6ͳ
       5 - Disk Change Warning    :  �*��� f�6͊��	ͳ
       6 - Path w/o System Attr   :  �*��� v�6ͳ
       7 - DOS Search Path        :  �*��� n(QͳEnabled *����*��n��f���R ͳ - Internal *ͳ  Addr =  �*��n��f�ͤͳDisabled ��ͳ
       8 - Wheel Byte Protect     :  �*��n��f�|�( �ͳEnabled  Addr =  �ͤ��ͳDisabled..Assumed ON ��ͳ
       T - Time Routine (Clock)   :  �*��n�f̓ͳ
       A - Stamp Last Access Time :  �*��n�f͊(�i:̓ͳ
       C - Stamp Create Time      :  �*��n�f̓ͳ
       M - Stamp Modify Time      :  �*��n�f͊(�iq̓ͳ
       G - Get Date/Time Stamp    :  �*��n	�f
̓ͳ
       S - Set Date/Time Stamp    :  �*��n�f̓�!���ͤEntry to Change ("X" to EXIT) :  ���,�u� 8��]�Xʔ�1ʹ�2ʹ�3ʹ�4ʹ�5ʹ͊��@�6ʹ�7��͵DOS Path [(D)isable, (S)et, (I)nternal *	|�(ͳ, (Z)CPR3 ͳ] :  ���D(=�Z(D͊ �I 	�*�=�S �͵Enter PATH Address :  !  ���*��� �î*	|�ʮ*��*��� ��t��u�î�8�i͵WHEEL Addr [(D)isable, (S)et *	|�(ͳ, (Z)CPR3 ͳ] :  ��!  �D(7�Z((�S �͵Enter WHEEL Address :  !  ��*	|�ʮ*��*��t��u�î�T ,͵Time (Clock) ͻ�*��u�t>�� �w�wî�A 4͵Stamp Last Access Time ͊�̻���*��u�tî͊ +�C '͵Stamp Create Time ͻ�*��u�tî�M /͵Stamp Modify Time ͊�̻���*��u�tî͊ P�G $͵Get Time Stamp ͻ�*��u	�t
î�S $͵Set Time Stamp ͻ�*��u�tîͳ  ��ͳ

Returning to system ...
 �{��x�*�ݮ �w î!� F#�����*���+��C���R �LR/O Sustain    =  ��F �LFast Relog     =  ��! �LChange Warning =  ��P �LPublic Files   =  ��W 6͊(�LPublic Write   =  �LPub/Path Write =  �͊ #�S �LPath w/o SYS   =  @��>�A����:�!��*�ݦ ��w ô�LWheel Protect  =  ���k(��- �N  �Z�[�(ͧ�k(��Z�*��r��s������*	|�� �k���LZ-System @  ��LSearch Path    =  ���k���- �N�*��� ����I ��*����LInternal
 �Z�[�(ͧ�kʻ�Z�*��r��s��� ���*	|�� �k���LZ-System @  �����LClock Routine  =  ��k���F�*��s�r>�� �w�w�����2��� +> �:��A 1�LStamp Access   =  ͊(�́��F�*��s�r�͊ *�C &�LStamp Create   =  ��F�*��s�r��M 0�LStamp Modify   =  ͊(�́��F�*��s�rW͊ Q�G %�LGet Stamp      =  ��F�*��s	�r
)�S $�LSet Stamp      =  ��F�*��s�r�������-y 	��N� ��LActive
 �/�!��w!�y�w�û�-�[� �LDisabled
 7�ͧ�Z�k�û��L-- Invalid --
 ���-�[�(��� ��*��^�V�LEnabled
 ��  �0��/��� �+	~��(  z��~���u���#��~����(#��ɷ�� ��,��	�#~�u��,�u�u2����0�:��]��/�,��0�,�
���
8�ɯ=�))))�o�(
ͳYES �ͳNO  �ͦʳ�~#� ���ͦ �ͭ�����[���R( ͳEnabled ���[���R(ͤ��ͳDisabled ����ͭ���A>H�]�äͳ Routine [(D)isable), (S)et] :  ���D(+�S �͵Enter Address of Routine :  !  ��*�7�ͳ Routine [(D)isable), (E)nable] :  ���D(��E ��*��n�f�ͳ
*** ERROR: DOS is not ZSDOS or ZDDOS!
 Ô�G:��Sx����V#^#����������V#^#���������~#�(�(	�(
�]������������ *����*��*�� ���� *��*�V�~�(�	����ɯ�����[��(�,*� ~�������%-�2�2����%(�\ �]��u�D(d�2(Y�3(Q�.(H�+(0�>(�R(�I(�]�>2��>2����O�0����G����]:���2�����	��
 ��d��
���0�:�� 0:���0�:���O:�� 0i�0�a��0�8���z�0 �A�]���~�(#�\ ~#�]�z������O*�|�y(+ 	O~� >G��C� ������I���� �����"�|�(� "��|�(~�!8 �
�s#r#�͛������
�!�s#r#�� ����~#���\ �#���( î*�|�(~���"��|�� >Z�� ����(* >�O>��G>Z��  �������� ��|�� ��������! ~��#~��3ENV��� ����>�]>
�]���.	�2��: g=�������|�L}�L����̀�]�̈́�]���.�c���O: gp���������a��{��_��Ɛ'�@'�                                                                                                                   