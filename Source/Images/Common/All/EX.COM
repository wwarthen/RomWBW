�Z3ENV  :] �/�R/͔!^�P� ��A͔/͔!�P� ��A͔/͔!�~��#�_� ��

EX is an indirect command file processing facility, similar to 
the standard CP/M SUBMIT facility.  The major difference between 
SUBMIT and EX is that EX is memory-based, storing a command 
processor and the interpreted command file itself in memory, 
just under the CCP or the last RSX as the case may be.

There is a speed/tpa tradeoff to be considered when using EX.
EX being memory-based, offers the advantage of greatly increased 
operating speed at the expense of decreased tpa compared to SUBMIT.
EX incorporates the function of XSUB.  Unlike SUBMIT, input comes 
from the command file unless the User Input directive is used.  If 
a program such as an editor needs user input, the '^"' directive 
must be placed immediately after the command and before the carriage
return.  Input from the command file is resumed after a Warm 
Boot or if cntrl-] is typed at the console.  Thus, EX acts like 
SUBMIT and XSUB combined.

Be aware that EX reduces the TPA work area by at least 3K, so that
programs that require a lot of memory may have trouble running under
EX.  So keep SUBMIT and XSUB handy to handle such cases.

Strike Any Key to Continue, ^C to Abort -  

EX is invoked by one of the following command lines --

	EX <subfile> <parameters>
or
	EX

The first form executes the indicated command file
(<subfile> (default type SUB), passing to it the indicated 
parameters, similar to the way SUBMIT is used.

The second form allows the user to enter a series of commands.
EX presents the user with a prompt like "n:", where
n is a line number, and the user may enter any command
line.  Input is terminated by simply striking the
RETURN key (empty input line).

EX can be aborted by ^C from console.

The following screen displays the EX control codes.

Strike Any Key to Continue, ^C to Abort -  

	**** EX Embedded Command Processing Facility ****

EX supports an enhanced command processing facility which includes the
following escaped character commands which may be
embedded in the text of the command file or user
input and will be executed after the command run begins --

	Cmd Meaning		Cmd Meaning
	 |  insert <CR>		^|  insert <CR> <LF>
	^:  rerun command file	^.  suppress print of chars
	^#  toggle EX msgs	^$  define default params
	^?  wait for user <CR>	^/  ring and wait for <CR>
	^*  ring bell		^"  allow user input.  CNTRL-] to quit.
	^<  display chars only	^>  stop display
	;;  EX comment		$n  1<=n<=9 for param
	$$  =$			$^  =^
	$|  =|			^c  insert ctrl char c

 �sD1�>�2 �=�l/͔�  *	"J}�(.�" ~#fo"J >�w�B ^#V� �*	? ^#V�* ����"F�"H/͔ͱ*g�DM* �[F��R�0* }��o��B��!������bkx�(':U<2U� �~#�2T:T2T0����+�"c#�� �:� o& 6!{� ����>
2P�]:� � M!  "X>2 !�"Zͮ*X#"X��:�� �� 
� � O *Z�(m����6#6
#"Z�:e �  e ! ���2| \ � < !�] �6.#e �6$�n*Z�!� "Z� \ � �(�*Z��6"\}��|��e�2L2M2N2^! "X*c"_"e���
 �#�����| �����>�#&O:L��y(�;��^(�$��2O� O:^�y(�͛�?�͆�:(.�?(.�/(.�"(.�*(N�|(O�$([�.�\�#�W�<�m�>ʄ�>��>��>����(G��
(�(�>�͛�?x�*>��[>͛>
͛2O��!i� ���>	2P�]�>
�$�!O�w��[O:N��y�[:L��y�[#�!O:^=2^�(�
 �w:^�(�>͛>
�$�>
�$���>��[>��!N� �w�>��[>�2O�!L���2L2M�[>�2O�!M���2M2L�[���*\��}� |��}��w+�* ###>X�(&>E��#>X��#>���V͔*J}�( 6 �{D�#>S��#>U��#>B��m͔�6�+6�}�0%.6�+6X+6E+: w+: w+6�" ����*H� �����*F���[J�͔ó�͔ó�͔ó͔*R͙���͔���͔�͔���͔ó�|��`8�{0�� �@0!�:��?��/��*��"��$��.��#��<��>��;�@��;�$��^��|��1�M�:�M�1�2Q��!}�0_ ^#V�{�(�(w+��#~��!i:Q��D_ ^#V�{��D�� �w# ���*X#"X!O6 !^6 kb"V�"_�� ���(��:N���:L���:^<2^� �"R��("� (�s#r#:P��V�(
�  ��د>�	� ~���  > #�_� ��A� ͔*X��ͮ*V�~#�(� �6 �����~#��_������ �������	8�
 	�|���{�0_� �����_x�{��w#�SUBZEX Error Line # $
MUST HAVE Z-80 PROCESSOR....ABORTING$
(Ex Already Present)$
XSUB Active - Aborting$
Text Buffer Empty$
Input/EX Buffer Overlap$
No Parameter or Default Parameter$
Parameter$
File filename.typ$ not there$
Control character$
Too many arguments - $EX 1.6   01-25-21$
$                 �� �           8                                      pppppppppppppppppppppppppppppppp                                                            V#����S� �"�"�""~�� +"2(1* " ��*�!v  ��1*~���#͂ (�w2)2+>2*!�͉: O*�:)��/2+��< �Ñ ��  *� }���X ��̈́ (~� 2)� 
�w2)>2*:)� -�s,1��(=���� 1��*#w">�{,��!*���2)>2*̈́ (�w>ɯ2+:%2&�����Q��(\��(s��(}��������������������� �2&>O:'��y�� �!ý ̈́ (>w>�2)��2*�{,��� >�*"�2'2%2(2)>2*ý ����(&�! `��� +|��!����� �O��
��� ��� !%� �w� !(� �w� 2'� :&��y2$�!*~+"���*#"�g!�͉1!�͉	�g!�͉̈́ (�w�X*�* {�z� 	og" ��{,>�*�! ��Ý:$�!��0څ�:��Aڅ�[��aڅ�{�2��:(�����~�$�#�O�!�!<  ��!�  ��!!� ���
>>>Ex Aborted<<<
$
(Ex Active)$
(Ex Completed)
>$                                  ����!                    A "A@���B  ! I BD��H@ !B$�$B	HI @� !!$��A$ �$$���   �"@@@A ! $�           $�  �S��"�"�""~�� +"2(1* " ��*�!v ��1*~���#͂(�w2)2+>2*!�͉: O*�:)��