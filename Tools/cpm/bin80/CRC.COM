�mCRCK 4.2B BY KEITH PETERSEN W8SDZ
modified and called CRC 1.1 by W.Swan, Alspa Computer, Inc. 05/21/82
 !  "�9"/	1/	�eCRC:  File CRC Check Utility  v1.1 :] � �-!] 6?#­� Change instruction at 0208 (CD 65 07) to (C3 2D 04), to avoid printing message. �e

    CRC reads the specified CP/M files, computes a Cyclic Redundancy
Check (CRC) number based on the CCITT standard polynomial, and lists
each filename with its CRC. This can help verify file transfers.
CRC is unsupported software in the public domain.

Command Format: CRC [[d:]fname [F,S,D]]
	d:)	optional drive specification
	fname)	any ambiguous filename (D.COM, *.*, etc)
	F)	create a disk File CRC.CRC
	S)	list System files only.
	D)	list Dir (i.e. non-System) files only.
Files with .$$$ or .CRC attributes are not listed.
 !m ~�F�;2��D�C2��S�K2�� �U#�2:��F�VÇ CRC     $$$ guous filename (D.CO1	  .*��*��*�}�|���!  "��*�{�z���*��� `� ���� *�"�ß	�� ��:
DISK FULL: CRCFILE$� � !  "��*���*�#"�ɯ2l2�!  "�!  "�`� `� <�V	>� �:
NO DIR SPACE: CRCFILE$1/	͘�?:���x�XFile Not Found$�e
Sum of Listed CRCs =  :��Q:��Q�r:��F�:*�}�¶"�>�͊�ª`� <��	�� ��
CANNOT CLOSE CRCFILE$� CRC     CRC ���*�#"�ɯ2l2��� �1� 	w#�"�� �!`����$:f ��R:��S�V�Z:��D�V!e �.�V!�5�t�e |  �|6�e
 !] � �M!e � �M�eXXXXXXXX XXX  \ � <���X++OPEN FAILED++$!  "�! "�*��z� � � ���� ��^�"�\ � ��� *�)��o��|�g}�o"�����::��Q:��Q*��*�"��V�X++FILE READ ERROR++$��Z��Ɛ'�@'�y�~�y#~��f��>�y>
����_�͍�� ����:��F�{͊�� � �2h 2| :����!\ � �M:\ 2�!�\  �M\ � ��!�\  �M\ � !�\  �M\ � <7�=������Ɓo& �� �M�]  �M�2h 2| 2��>C��>#>R��#>C���F��F�~��$#�~#x��M��	� :��F²*�}��r"�>�͊��f`� <ª	�� ê
CANNOT CLOSE CRCFILE$`� ��

++ABORTED++$�	� */	��                                              