�Z3ENV  * ͢"	͞�/́ 1�� Start/Stop SCSI Hard Drive  V1.0 31 Aug 92
 �s1:] �/�2*	 �~�[ (= ^#V�"�.Z~�� �.�C�!��~�B #~�/ #~�P(-��
+++ Not B/P Bios ... aborting +++
 �*�.�~�(:�(6��
+++ Can't handle this Controller Type! +++
 �.]"&!�6#6 #�:] �-(>2�ͺ� �%�0H��
**** SCSI Block Length Error ! ���
**** Invalid Unit # !  ��;*�.�~2�.�:] �- :^ �08��0�G	 �Ǵ ��Unit  x�H�� :  ~2�� ́ ��Not Defined ����:��%���%ó�}� !:] �- ��Stopped! ���Started! ���Error  }�z���
 ��� moves the heads on the specified B/P BIOS hard drive unit to the
 designated shipping or park zone and may turn the drive motor off if called
 to Stop the unit.  If called to Start the unit, the drive motor is activated
 for the specified B/P BIOS hard drive unit (if turned off) and the
 heads are positioned to Cylinder 0.

Syntax:

	 ��� -n       - Stop Unit "n" (0..2)
	 ��� n        - Start Unit "n"
	 ��� //       - display this message �;�{�:
��N��SPINUP ��  >B* o�!F~�����g(# ������        ���/(~�� (͐#�����$ �r�" *|�(~#fo�����( *|����*|�(~���"�|�� >Z�� ����(* >�O>��G>Z��  �������� ��|�� ���������! ~��#~��3ENV�� ���� ~#� ����	(͐�(��
(	�(� ���y/�<G> ͐���>͐>
͐������&d�^&
�^�r����.��,0��g}� �|�> (��0G͐|��ͭ͐��ͱ͐������O>͛�����ͣ����o��* o���Ɛ'�@'���*�� j���                                                       