��	  � 	�	�|�g(��7ɯ�#Gz�x ��!��x� ������ ����������_� �����>.�<�����~� (_�� �#�������̓z�<{�<����x�hy�h��W͒_z͒W��Ɛ'�@'��& oͤ������Ͱ�����0�������������� �>/<	8��B�� �<ɷ�> �<�h�����!��Q��
 ��~�<�#����Q#��
Copy a full RomWBW hard disk slice to another slice.

Syntax:
  copysl <destunit>[.<slice>]=<srcunit>[.<slice>] [/options]
Options:
  /f - Full copy of slice, ignoring directory allocations.
  /u - Unattented, doesnt ask for user confirmation.
  /v - Verify, by doing a read and compare after write.
Notes:
  - drive identification is by RomWBW disk unit number.
  - if slice is omitted a default of 0 is used.
  - for full information please see copysl.doc

 
Invalid Arguments
        !� ʹ�>�H &�S�ʹ�= #ʹ(�H �S�ʹ�/ ̓��!��Q!�Q>���ʹ��®��ڮW�_ʹ~�ʁ�.(�:(Á#ʹ��®��ڮ_Á��#ʹ�ͽ�F(
�U(�V(�>�2�>�2�>�2��h���~��� �#��a��{���� ~�08�:0y�؁��O~�0��O#�y���08�:0����������(�
(�ɷ�  �������=X*:W��=��������=X*:W��=�������y2��"����T]6  ���w O����s{�� A�q�p  !  ��C�~ O�	��*�}�U ^|�� Y> 2�!�~ �.(-�   �::�� �����*� 	� ��>2������[�>
 �� @�q�p:��  �~ O����u�t�s�r	���w
�N�F!    �(	0=���	0��N�F�B��N�F	�B��8����N�F	��N�F�J��u�t�s�r��*��[� :��
   	��� Disk Unit  �~ ͛�, Slice  �~
͛�, Type =  �~�
(�hd512
 ��hd1k
 �>��>��>��   MBR_START                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                MBR_END���� ��C :�O�	�> �� ! �~�0'�[�	�S�	 �^#V#�*�	�R0�S�	� ����(�"82�	  x� ���  	0���! �~�
(! *�	 :��
(  	"�	��
Found  *�	ͤ� directory entries, with  *�	ͤ� (4k) extents. �Debug123      Debug456!��Q��o�>:��!��I:���
Source ͅ: �!��I:���Target ͅ�!��!��~��ʓ�~��ʓ�~���~ ��  �~
��
 É�~
�  �~� !��Q:� 3!$�Q�m���{:��(���{:�	� (!:�Q�q	͆	�!��b	:� !{�Q�-�Y(�y(�o��!��Q��"����{�!�v�{ͅ�K�	x�(�C�	��
Copied  :�(�and verified  *�ͤ� kBytes in  ���[���Rͤ� seconds.
 !��Q�  ����  �!�'!��Q�h!�!�!*!�
!c!� �Q�  �
Disk I/O Error (Code 0x ) Aborting!!
 
Verification Failed. Aborting!!
 
Source and Target disk slices must be different
 
Hard disc(s) must have matching layout (hd1k/hd512).
 
A specified disk device does not exist.
 
Only hard disc devices are supported.
 
Slice numbers must be valid and fit on the disk.
  ��C*��[�:�O�	�>��*� 	"�0	�[��S��� ��C*��[�:�O�#�>���Z(�*� 	"�0	�[��S���:�� ��C*��[�:�O�	�>��! � ���*� "�}� �I|�� ���    CopySlice v0.2 (RomWBW) Sept 2024 - M.Pruden
 
Warning: Copying to Slice 0 of hd512 media, will override partition table! 
 
Parsing directory.   -> Directory Not Found!
Will perform a full copy of the Slice. 
Continue (Y,N) ?  
Copying data blocks. 
 
Finished.
                                                                          