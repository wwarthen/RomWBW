�Z3ENV   TDD       �s�1��2�� �" 0� �(|� 7��SORRY! ZSDOS is required to run this program!
 ��Ly��2�:� Ɓ& o6 !� �{�/�1#~�/�1��
TDD, Vers 1.6  - Time/Date utility for ZSDOS and B/P Bios.   12 May 97
   (SMT No-Slot-Clock/Dallas 1216/Dallas 1202 Version)
  - for YASBEC, SB-180/SB180FX, Ampro LB -
     - and D-X Designs Pty Ltd P112 -

  Syntax:
	TDD                     - Display current date and time
	TDD //                  - Display this help info
	TDD S[et]               - Set date and time in dialog mode
	TDD U[pdate]            - Set ZSDOS clock from Hardware RTC
	TDD C[ontinuous]        - Display date and time continuously
 :�(r��	TDD dd.mm.yy [hh:mm:ss] - Set date and time for RTC
	TDD dd.mm.yy [+XXXX]    - Set date and relative time ����	TDD mm/dd/yy [hh:mm:ss] - Set date and time for RTC
	TDD mm/dd/yy [+XXXX]    - Set date and relative time

NOTE: This routine MAY disrupt Serial Port handshake signal settings
on the SB180FX due to altering IO Port 00B1H. �*�{����
*** Must have B/P Bios to use!!!
 ��* .Z~�� �͋!��~�B �#~�/ �#~�P �#͆(2��
*** Hardware Type Not Supported ! ***
 ��2�� >ӱ��b�:��(D!V� � !�  ��* ��B�| $��
++ Insufficient Memory! ++ �������U�q�C�ͽ�S�=͍!� ��	�=�r
�=��{�(�
�=�{��=͌
�=�5��Press any key to set time  �M�*��:�� �&	�e�*͍͸
�*�:������ �0)��
**** Can't find No-Slot-Clock!
 �=��
No-Slot-Clock found, setting ZSDOS time to:
 :�2�:��2�:��?2�:�2�:�2�:�2����b!�͌�͍͸
:����C�:��͍�G:��(�>�f�͍:� %��Enter today's date (MM/DD/YY):  #��Enter today's date (DD.MM.YY):  ��͍:� Ƃ& o6 !� �{�(��	�=�{��=�r
�=�>�2�:��('��Enter the relative time (+XXXX):  ��Enter the time (HH:MM:SS):  �:� Ƃ& o6 !� �{�(�
8�{� ͌
0�5�P��*** Error in Data Input
 :���=��:���� �0T��-- No Dallas DS-1216 Clock Found
     Attempt to set it anyway? [Y/n]  �7�Y��*!��~#~#~#~#~#~��!��+*�́2�����   Dallas DS-1216 No-Slot-Clock SET !
 �!�͌=(J��-- No DS-1202 Clock Found
     Attempt to set anyway? [Y/n]  �7�Y��*�!��+*�́2�>�2���>���> �����>���!�~��#����   Dallas DS-1202 Clock SET !
 �~#�7�͆8�+�W�C~#�7�͆8�+�W�K~#�7�͆8�+�W�:�(yHG��:�� 0~#�7�͆8�+�W�C~#�7�͆8�+�W�K ~��#͆8�+�Wɯ�O_~�+7�#~͆?���`i)�))�	O 	DM����x�8�=���!�
�o> �gy=���:�� x�$�y�`�{�`��˸!'��B?����1)1010110101> �f���!��+*�́!G�o> �f�f:� -:��8�_ !~#�f~#�f~�f��> �f:� :��D:� >,�f> �f:� �:���x> 8>�D��D> �f�f:���K:��D>:�f:��D>:�f:��D> �f����O 	~#�f���� ��͚����R}�ѷ�>���կ2��!  "���<�0�*�"�0>�2���)����*�:��(�7������!  "����R�8)�*��j"���R8"����������!  �SunMonTueWedThuFriSatJanFebMarAprMayJunJulAugSepOctNovDec��M����0�f���{~͆��_ #~͆?��))))��o�z�7��~� (�	�#��0��:?���b� = 
:��2�����
*** NO Clock Driver Installed!!!
 ��c� = ��
   ZsDos Clock SET !
 ���
-- ZsDos Clock can't be Set !
 ��!�q+y2�p+x2�s{2����!�p#x2�q#y2�s2�������>+�f!�~˿#ng��z���z���z}�0�f�����/8��Ry�f��͞ y<��� �=���� #����-AM-YS-18-FX-DX ��*	G|�x(7) 	G~#fo~�x )��*** Must be wheel to set clock!
 ����� >~
� �*:�����
*** Must have Z180 Processor for this Bios Version!!!
 ����;��l�! � : ��q# �> �96> �99> �92�:��(<(�7��l�! �N�8: : �# �: ��96:%��99:*��92������892%���99�822*����92�862 ���96!��: N�8: : �# ����:�\�:�\���0��S�! � : ��q# �>@� �:��(<(�7��S�! �N�8: : �# �>@� ������ !x�: N�8: : �# ����:�\�:�\��� ^�>�����xˏ�y �x����y �]�z�(�(˻s+� �� ��~<�~#�#�++�>�� �x���y�xˏ�y���y��o�8�ˇ�9��xˏ�y�?��y���y ��8����9����8����9��x���y˗�y��G�(]x���N0�dl�O> �G��g���o|=�06�_ !�V���� }=�0�& �i`���B	(�!m���� ����  ;=����!�z�(~�o> �g{��� #�#����q#p#��������A��I���� �' �x��������� ~#� ����	(�f�(��
(	�(� ����y/�<G> �f���>�f>
�f���=�f�M�q�V/���M�>�|���>��|�/������O>�|�����a��{��_���̈́����o��* o��                                                                                                                  