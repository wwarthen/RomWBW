  �'���#OCPSMIT.ASM (30) 29-Mar-1991$!  9"c1�c|T�UO͂Q<2�c:�p��> �M2�p* p|�ʰT�|�¹*p��|�¹!�Q"'p�Mp:�p2-g�Z�wp!� �j� �tp:� �ʡ=ʡ:�c�2�c2�c>�2,g��2�c��UV�UO���V�UO��1�c�p�22G23G24G2�l2qb2rb2�f:�c�@2�T�	T:�l�0��> 2�T:�l2�T:�c��:�c����T�RG%!<�O���T�wp�� BREAK$�BYE$�C$�=CONNECT$�=COPY$�D	DIRECTORY$�@ERASE$�BEXIT$�FINISH$'GET$7HELP$�INPUT$�LOG$�LOGOUT$e'OUTPUT$�PAUSE$�PRINT$�QUIT$�R$mRECEIVE$mREMOTE$T-RENAME$�ES$�SEND$�SET$�SHOW$ISTATUS$USTAY$XTAKE$	TRANSMIT$(<TYPE$GCVERSION$
BREAK to send a break to the host
BYE to host (LOGOUT) and exit to CP/M
CONNECT to host on selected port
COPY to copy a CP/M file
DIRECTORY of current used Micro-disk
ERASE a CP/M file
EXIT to CP/M
FINISH running Kermit on the host
GET a file from the host
HELP by giving this message
INPUT to make the micro wait for a string from the host
LOG the terminal sessions to a file
LOGOUT the host
OUTPUT to send a specified string to the host
PAUSE to wait for a little time
PRINT a file to the printer
QUIT to CP/M
RECEIVE file from host
REMOTE to send commands to a remote server
RENAME to rename a CP/M file
SEND file to host
SET a parameter
SHOW the parameters
STATUS of Kermit
STAY at Kermit command-level after a command tail
TAKE commands from a file
TRANSMIT file to host (in connect state)
TYPE a file to the console
VERSION of Kermit running$�O>B�\p���X���O�q'���bp���O�Pp�  >ͥG��**g"g�f>ͥG��2"k�O*g)))#"g"g�2me*g+"g|��>2�f�|ͦ=��N͈D��p���6:"k������F:�c��wR������_:me!�f�o> �g{���:me<2me*g"g_:"k���2�f���W�wp���O<�5T��>\ ͥG��O!\ �c �tp>2�c��>ͥG��**g�*'g|�g"*g͋R:�c����͂Q���**g�*'g|�g{�_z������>�2 g�GC�2 g�����>�cͥG���&�� �c!�c�tp:�c��wR�c͂Q�2�c2�c�c͂Q<�Z!  "�c:�c�2�c�SR:�c���U�wp�zQCPSCOM.ASM (13) 25-Mar-1991$�!�	�O��AUTORECEIVE$BLOCK-CHECK-TYPE$#BUFFER-SIZE$�	COLLISION$cDEBUG$�DEFAULT-DISK$�DIRECTORY-FILE-SIZE${ESCAPE$k	FILE-MODE$�FLOW-CONTROL$rIBM$�INCOMPLETE-FILES$�
LOCAL-ECHO$LOGGING$bNO-EXIT$XPARITY$+PORT$�PRINTER$�RECEIVE$�SEND$SPEED$�TACTRAP$~TERMINAL$1TIMER$�USER$�BWARNING$�
AUTORECEIVE to automatically re-receive files
BLOCK-CHECK-TYPE for error detection
BUFFER-SIZE for multi-sector buffering
COLLISION to specify action for filename conflicts
DEBUG message control
DEFAULT-DISK to receive data
DIRECTORY-FILE-SIZE when displaying directories
ESCAPE character during CONNECT
FILE-MODE for outgoing files
FLOW-CONTROL to set XON/XOFF flow control
IBM mode: parity and turn around handling
INCOMPLETE-FILE disposition
LOCAL-ECHO (half-duplex)
LOGGING of terminal sessions
NO-EXIT to prevent exit to CP/M after a command tail
PARITY for communication line
PORT to communicate on
PRINTER copy control
RECEIVE parameters
SEND parameters
SPEED of communication line
TAC interface support
TERMINAL to set a terminal type
TIMER control
USER to set a user number
WARNING for filename conflicts$�2�l��2!|�2�p��1-CHARACTER-CHECKSUM$112-CHARACTER-CHECKSUM$223-CHARACTER-CRC-CCITT$33
1-CHARACTER-CHECKSUM
2-CHARACTER-CHECKSUM
3-CHARACTER-CRC-CCITT$>ͥG��**g|���:-g���}2�p��	W�wp��\ >ͥG��:\ ���:�c2�c͂Q:�c=_͂Q��!X�O��PAD-CHAR$APADDING$8START-OF-PACKET$$PACKET-LENGTH$J
PAD-CHAR to define the pad character to use
PADDING to define the number of PAD-CHAR to use
START-OF-PACKET to define the start of packet character
PACKET-LENGTH for the length of transmitted packet$�O\�wp͂Q2�c���C2  ����2  ���C_ ��(T�*W�b}2�p���wp���C��vNW��� �p�02Sk���!X�O��PAD-CHAR$PADDING$�START-OF-PACKET$�PACKET-LENGTH$
�O\�wp͂Q2�c��>ͥG��>ͥG**g}2  �O@\�wp͂Q���2  ���C_ ��(T�*W�"}2�p���wp���C��6NW��� �0�02Tk��>ͥG��>ͥG��**g}��O�2�c���2�c���O�[�wp͂Q2�p���2�p���2�p���2�p���2�c���2�p��BACKUP$DISCARD$	OVERWRITE$  RENAME$
BACKUP (rename) existing files
DISCARD new versions of existing files
OVERWRITE existing files
RENAME new versions of existing files$�!��2�p���2nb���2=j���2�p�ʢ>2�p>2�p2�c�2nbñ>2�p�2�p2�c2nb���!��2�p��ASCII$BINARY$DEFAULT$  
ASCII	BINARY	DEFAULT$!�2�p��DISCARD$  KEEP$
DISCARD	KEEP$:!c�2�p��EVEN$  MARK$NONE$ODD$		SPACE$
EVEN	MARK	NONE	ODD	SPACE$�!���ʡ�ʞ�[�wp͂Q2�p:�p2�p��	CHARACTER$OFF$  ON$
ON to enable TAC trap
OFF to disable TAC trap
CHARACTER to enable TAC trap and specify intercept character$s!��z��V*$p|�>�V�OO�X�wp���@�a2�l�����m�2�l��2�p��DUMB$EXTERNAL$QUIET$@@REGULAR$��OFF$  VT52$
DUMB - only printable characters passed to terminal
EXTERNAL - with emulation code system specific
OFF - all characters passed to terminal
QUIET - display nothing during transfers
REGULAR - normal display for transfers
VT52 - assume Kermit can emulate a VT52$*|p|���*~p�O��O�"�p��ep��*�p|���*�p�O��O�"�p�hp��OFF$  ON$
OFF	ON$�!��O2�l�O:�l�V#F#"�l#�"N��7##�!<7ɷ*�l�
?Not found$�O�2p�a���O�2p�a��:$g��n]]�wp��;����Ͳ;�]���)͐�i�G�`O��͍��*�p|��^́�@�/�O�*|p|��~�w�͜���u�s]�wp:�l���]�wp:�p���]�wp�]:�l����]�wp�]�wp:�p���!�X�&O!sF#^ #�##��&���wp�]�wp:�p�]��wp�]��wp^�wp?^�wpe^:�p��wpn^�wp^�wp:=j��4^�wp:�p��t^�wp:�p���^�wp:�p���^�wp�l!�c~�¡:�c�@>:!�c ~#� ʽ°x���>.�!�cð>$�l�wp�^�wp:�c�����^�wp�_�wp:�p�_��wp�_��wp�_��wp�_�	�wp�_�wp�^�wp:�c�@_ÂQ�^�wp:�c�@_ÂQ_�wp:�po& �#O�^�wp:�po& �#O�_�wp:�p!�_��ʺ*�p��{!�_ú�_�wp:�p!�_��ʺ*|pV#F#"�l#N�ʰ##!�_ú*�l��wp!�_��wpu_�wp:�p_͂Q�_�wp�_�wp!�:�p���wp_�wp��N�+_�wp!  :�po�#OH_�wp!  :-go�#O�`�wp:�c���O�OO|T�wp�T�wp�OO!]^#V#z��I��wp�OO��5*p��wp�OO*p��wp��h)%7-�;<�@�E5G�N_T  `�wp�]:�p��wp_͂Q�OO�]�wp:nb�� �͂Qo& �J`�wp��#O�c`�wp:�p��o`�wp:�c�@_ÂQ�]��wp�]�wp>�fͥG��2"k����O�p�f�ͯN_�p�:"k=2"k���p���X�wp��CPSPK1.ASM (23) 16-Jan-1991$>�2�l1m>ͥG���2/m�6$�6,:�l��a�OO�d�;p1m�wp�x> 2/m2�l�6,�l>ͥG�2*m2�l:/m�ʕ>I2Bk�29k!  "<k">k2;k2@k:�l�¸�Ap!  �#O:/m���>R2Bk:�l���:�f����>p*<k�#O:Bk�D���O���X������F������R�Ͳ:Bk�F���Z͑,���C�L�W:9k��.�29k�X:�f�̑,:/m���:�l���h[�wpÕ�Y���I¤͕:Bk�X�i�A����:/m2�lO !1mZk�tp>127k�2�l>R��'��29k!  "<k2;k2@k>R2Bk���A©�W͑,��:@k����T�!,�M,<2@k>127k��(�V,�S�:@k2Ak�2@k:�l��,:�l!Zk͎"!Zk�M"2�l>Y��'�M,:8k27k>F2Bk��E�S,��+�M,:@k��)U�!,�M,<2@k��(�V,�S�t:Ak��I�T�!,�M,<2Ak:;k=�?G:�l��S,�i,�2@k!Zk�M"2�l>Y��'�M,��Z:Ak���3U�!,�M,��,��F��O:�f�y����,�S,��,O:�f�y´�F%�M,:@k2Ak��,>D2Bk:9k�Zȯ29k��X�'��,�S,��,�p:�l���<��p��p�!Zk�^#��p��=��>��p��p�OO:@k2Ak��,>D2Bk:9k�Zȯ29k��B�D��,�S,�2�l>Y��'�M,>C2Bk��E�M,��+�M,:@k���TU�!,:�f��M,:�p��}\ �͂Q�͂Q�M,�GQ�u�M,<2@k��(�V,�D����,ʰ:Ak���TU�!,�]��,���,:@k2Ak:�l�&#�x�2@k2�lO:9k���O>2�ly2Zk>Y��'�]��F��:Ak���U�!,�]��,��Z��,�S,��,:�l��:Zk�D�9:�f��)�GQ�u�29k:@k2Ak��,�o:@k2Ak��,:�f��o::k��o:�p��i\ �͂Q�͂Q�o�GQ�u>F2Bk���#:�f��M,\ �͂Q�:�p��M,͂Q�M,�E�]��+�]>\ ͥG���l>ͥG�2*m�22G23G24G20g!1g".g��E���U�wp���6,�2;k2@k2�c!  "<k">k:�l���Ap!  �#O>127k>S2Bk:�l���>p*<k�#O:Bk�D�,�F ��F�7�@��Z�B�C!��S�[͕:Bk�F��Z͑,��B�f��!��C�~�W:9k��x�X͑,���A�W͑,���W͑,��:@k����U�!,�M,<2@k>127k:�p28k!Zk�M"2�l:<k2�l:Bk��'�M,��(�_O�Y���,���,:�l!Zk͎":@k2Ak�2@k:Bk�I� >X2Bk�:8k27k>F2Bk�nO��N�-�i,:;k<�?G:�l���2@k>F2Bk��E�M,:Bk�I����+�M,:@k��Q�U�!,�M,<2@k�29k!Zk"0k:*m��/ !] ".k  x�>.*0kw#"0kx��*.k~�#".k�!�p*0kw#"0k�py2�l*0k>$w:�l�·�;pZk�wp:;k2�l>F��'�M,��(�_O�Y� ��,���,:@k2Ak�2@k2%k2&k2'k2(k�$� 26k>D2Bk����M,>Z2Bk��N�$ �i,:;k<�?G:�l�����E�M,��+�M,�!�lOG~#x��5 �"0kã:@k��W �U�!,�M,<2@k!Zk"0k!l"2k*2k~#"2kO:�c�y :�p�yʛ :�c� y�ʘ ̈́,>�2�cy�*0kw#"0k:6k��i :6k2�l:;k2�l>D��'�M,��(�_O�Y�!!��,�:�l��,:@k2Ak�2@k:�l��� :Zk�Z�� 29k�!�X�� 29k�!:9k��!>Z2Bk��$�!26k����M,>Z2Bk��N�8!�i,:;k<�?G:�l���!�E�M,��+�M,:@k��T!�U�!,�M,<2@k:;k2�l�2�l:9k��s!>D2Zk>2�l>Z��'�M,��(�_O�Y��!��,���,:@k2Ak�2@k\ ͂Q:9k�Zʺ!��Eں!�nO�29k>F2Bk�>B2Bk��N��!�i,:;k<�?G:�l��Ê!�E�M,��+�M,:@k���!�U�!,�M,<2@k:;k2�l�2�l>B��'�M,��(�_O�Y�+"��,���,:@k2Ak�2@k>C2Bk��N�B"�i,:;k<�?G:�l���"�E�M,��+�M,:�p� w#:�p� w#:�p� w#:�p�@�w#:�p� w#:�pw#6Y:�p�ʅ":�cw#:�pw#>�2�l>2�p>#2�p>&2�c>128k~� 2�p:�l��##~� 2�p:�l��#~�@�2�p:�l��#~� 2�p:�l��#~2�p:�l��#> 2�c~�N�#� �#�Y�#:�p��#>�2�c�#2�c>�2�c:�l��#~G:�p��28k�2�l:�f��G#:�p��G#::k��G#>X29k�ZO!Zk"*k:�pG :�c��^#:�cO!�l5�ZO:�f��y#!$k5�y#��P��#**k~#"*k �#�:�l=2�l~#"*k�·#~#"*k!�l5W怳_z��ʷ#�ʷ#z�@��2�l:�f�:�l��#���_͂Q����^#*,kw#",k�^#nU��!,�!Zk:�l��,2�l�2�l��
$w#:�l<2�l��#6 :�l2�l>E��'   �:�pO:7k�1G:�p��2�l!l"2k :�l=�A$x�ZO2�l:$k=�Q$2$k�b$͍O�Z$�b$x��ZO�&%*,k~#",kW�_ʒ$:�c�ʒ$:�l��%=2�l*2k:�cw#"2k z�W� ��$���$:�c�ʮ$:�c�ʳ$z��
%!�l5*2kq#"2kz�
%���$:�p���$���$*,k:$kWz��$�2$kx�ZO~#���$>2�l!�l5*2kq#"2k:�l�@�*2k�w#"2k�6$*,k+",k!$k4x�ZO>��CPSPK2.ASM (11)  21-Mar-1991$�2\ !Zk:*m��i%!�l:�l�:�i%~�_�@2\ ##"0k!] ".k�2�l2�l p#<��{%6 *0k~�a��%�_#�.­%"0k!e ".k:�l2�l>	2�l��%��&"0k*.kw#".k:�l<2�l���%2�l*0k~#"0k��&�.��%*0k~�a��%�_��&#"0k*.kw#".k:�l<2�l���%*0k6$:�l��&�;pZk:�l��&�l�wp�2:k:�p���&\ ͂Q����&:�p��J&>�2:k�ZO��W�!,���c&!\ �j! �tp>0!d w�x&+~� >0�j&!] ~�w#�}&\ ͂Q<ʥ&:d <2d �:�x&�U�wp��l!] ~#­&>.~#»&>$�l�wp:�p���&!\ �j �tp�j͂Q����&�U�!,!�j\  �tpͧP�'�ZOnU�!,��O�p�p�p�2@k>127k:@k��5' V�wp��<2@k�2�l>2�l!Zk6F>G��'�,'��(�$'�Y���E�$'��+���O�q'�����p�p�p�2@k>127k:@k���'4V�wp�<2@k�2�l>2�l!Zk6L>G��'Ë'��(Ã'�Y�ZO�E'��+�2�l!Vk:�cw#:7k�1G:�l�#�w#  O:�l� w#�O> �G:�lw#�O> �G:�l��(=2�l~#�O> �G��':7k�2�<(�%(y����?� w#�S(6 �!Wk�f+�KBz�� w#x�Gy��� w#y�?� w#:�p�ʠ(�6 :�l�(�Jp!Wk�-:�p�ʟ(!�a�!-:Bk_��R!b�!-!�a�!-!Wk�!-!b�!-!b�!-�:�pw#�w�p:�p2�l:�l=���(2�l:�pͯN_�pð(!Vk~���(ͯN_�p:�p���(ͯN_�p#��(�p�ZO�&*�_O��*��(!�c���(��*�_O!�c��)2WkO:7k�1Gy�#�2�l ��*�_O!�c��)2�l2Xk�O> �G:�l� 2�l��*�_O!�c��)2�l2Yk�O> �G:�l2�l!Zk"0k:�l���)2�l��*�_O!�c��)*0kw#"0k�O> �G�h)��*�_O!�c��)� 2�l:7k�2��)��)y����?G:�l��*�i,�*0k6 !Wk�f+KBz�W:�l�¾)��*�_O!�c��)� 2�lx�Gy��G:�l�¾)��*�_O!�c��)� Gy�?�¾)*0k6 :�l�ZO!�k"4k��*�_O!�c��,*�O*��*�_O!�c��O*!�k"4k*4kw#"4kG��&*:�p��<*!�k:Yk��&*:�p�ʊ*:Bk�Sʊ*��*Ê*��**4k+6 �p:�p���*#:�l���*�Gp!�k�-:�p���*!�a�!-:Bk_��R!b�!-!b�!-!�k�!-!b�!-!b�!-!�k"4k�ZO*4k~#"4k��ZO���*�p"�c�p�p��+G:�p�x�+����ZO�p�p��?+��<+��4+��X+��?+�@29k�?+���:�c���**�c+"�c|���*�i,����2p:�c��wR����  ~�ʙ+�_�O !�+		�{�O!�+	~�#V�_#~�W�#�k+���  �!�1B�Rc�s���
���ƍ���  �#�2$F�W6e�tH���Z�Ӿl���~���:�l���+:�f���+�8p>A2Bk�,�T:�l��,�wp:�lO !Zk	6$Zk:�f��,:�l���wp�:�l��:�f��2,��8p��wp�|T:�l��C,�kp�p�p�p�>A2Bk��i,:;k2�l�2�l>N��'�M,�*>k#">k:�f��:�l���Ap*>k�#O�����Z�!,����:�l�ʯ,��OO��wp ��͂Q��͂Q���Dp��wp�!�T^��� ��#½,�`�wp�5p�:;kG:�l��<�?2;k*<k#"<kɯ2@k2�l>Y��'�M,�<2Ak:;k=�?G:�l��S,�i,��,�~���_�p�#�-~���_��R�#�!-�O:Uk�y��CPSREM.ASM (13)  21-Mar-1991$�p�p�ph-!.�O��CD$�1COPY$=1DELETE$�1	DIRECTORY$62
DISK-USAGE$;2ERASE$�1FINISH$'HELP$@2HOST$E2KERMIT$^2LOGIN$c2LOGOUT$e'MESSAGE$�2RENAME$�2SET$�2SPACE$;2STATUS$S3TYPE$h3WHO$m3
CD - change default directory for remote server operations
COPY - copy files on a remote system
DELETE - delete files on a remote system
DIRECTORY - list a directory on a remote system
DISK-USAGE - show disk usage on a remote system
FINISH - stop a remote server
HELP - get help from a remote server
HOST - execute a command on a remote system
KERMIT - tell a remote server to execute a Kermit command
LOGIN - send user-identification to a remote server
LOGOUT -  stop and logout a remote server
MESSAGE - send a message to a remote system user
RENAME - rename files on a remote system
SET - set remote server parameters
SPACE - show disk-usage on a remote system
STATUS - Get status of a remote server
TYPE - type files on a remote system
WHO - show current users on a remote system$!"b"�m>K21m>2/m>G2�m3m� 5��G� 22m:/m�2/m*�m�"�m�RG*�m#�� 5*�mO� w:/m��2/m�x3!/b"�m>C21m>2/m>G2�m3m� 5G� 22m:/m��2/m:1m�C��1x��x3>�2rb*�m�"�m>�2qb�RG*�m�� 5��x3O� *�mw:/m��2/m�x3>E21m>2/m>G2�m3m� 5G:1m�E� 2�T� 2x��x3x��� 22m:/m��2/m�x3>D��1>U��1>H��1>C2�m�2/m1m� 5��2/m�x3>K�G2>G2�m>I21m>2/m3m� 5��x3G� 22m:/m��2/m�"�m>�2qb2rb/b�RG*�m�� 5��x3O� *�mw:/m��2/m�"�m�2rb<b�RG*�m�� 5��x3O� *�mw:/m��2/m�x3!"b"�m>R�E1!Ub"�m>M�E1>2/m>S21m>G2�m>#22m=5!�5�O��7m>ͥG���O� 26m:/m�2/m�O�x3�27m>!26m:/m�2/m�x3�O>Q21m>G2�m>2/m�x3>T��1!ab"�m>WÖ1>�2�f:�m�G3:1m�Sʐ3�2p�2@k29k2;k!  "<k">k>127k>I2Bk͕:Bk�X��3�A¨3���2@k29k2;k!  "<k">k>127k:/m��B42�l:�p�2�l1m!Zk:�cG:�pO:�l=2�l�84� �4��4:�c��+4��54q#:�l=2�l�84:/m<2/m� �54�@�w#:�l=2�l��3�2�l:/m2�l:�m��'��[4�S,:@k<��m4cW�wp��2@k��(�X4�E4:�m�G4:1m�S�OO��+���S©4��:Bk�A��>X2Bk���N�[42Bk�p!Zk:�l���4��<��p��p����4=^#���p����4>��p��p�OO:Bk�Y����,��,>D2Bk���20mG�OM���85�
�85��/5��&5�?�5�*c#"c���2pb��5x20m�BLOCK-CHECK-TYPE$�:FILE$;
INCOMPLETE$I;RECEIVE$;REPLACE$�;RETRY$�;SERVER-TIMEOUT$�;
BLOCK-CHECK-TYPE for a remote server
FILE parameters for a remote server
INCOMPLETE file disposition for a remote server
RECEIVE parameters for a remote server
REPLACE file attribute handling for a remote server
RETRY maximum for a remote server
SERVER-TIMEOUT interval for a remote server$
BLOCK-SIZE$';	COLLISION$5;
INCOMPLETE$I;NAMES$];RECORD-FORMAT$q;RECORD-LENGTH$�;REPLACE$�;TYPE$�;
BLOCK-SIZE of files for a remote server
COLLISION action on filename conflicts for a remote server
INCOMPLETE file disposition for a remote server
NAMES translation of files for a remote server
RECORD-FORMAT of files for a remote server
RECORD-LENGTH for a remote server
REPLACE file attribute handling for a remote server
TYPE of files for a remote server$FIXED$FFVARIABLE$VV
FIXED	VARIABLE$PACKET-LENGTH$�;TIMEOUT$�;
PACKET-length	TIMEOUT$APPEND$33ASK$55BACKUP$22DISCARD$44	OVERWRITE$11RENAME$00
ASK about existing files on a remote system
APPEND to existing files on a remote system
BACKUP (rename) existing files on a remote system
DISCARD new versions of existing files on a remote system
OVERWRITE existing files on a remote system
RENAME new versions of existing files on a remote system$DISCARD$00KEEP$11
DISCARD	KEEP$	CONVERTED$00LITERAL$11
CONVERTED	LITERAL$PRESERVE$00DEFAULT$11
PRESERVE	DEFAULT$BINARY$11TEXT$00
BINARY	TEXT$!40"3m>025m2!|�=3�6!+7�O���8!�8�;!31"3m>125m�3!30"3m>225m�8!39�=3!31"3m>025mc:!w:�=3!30"3m>125m�:!�:�=3!31"3m>325m�8!�8�=3!31"3m>225m�3!30"3m>325m�:!�:�=3!30"3m>025m�:!�:�=3!40"3m>125m�3!40"3m>225m�3!40"3m>325m�3!40"3m>425m�3CPSSER.ASM (1)  8-SEP-87$CPSTT.ASM  (12) 31-Jan-1991$>\ ͥG���f>ͥG��2"k��O<>2"k>2�f�O�nO���c<�U�wp��&Y�wp�2me2ne�2oe2pe�3=���w<�2pe�p*�p:ne<2ne�< <�2ne�OO:�c�¯=�2meͦ=���<͈D��p����<:"k��w<��<�ʯ=���<\ ͂Q���«<>2oe�w<�=��=ͦ=��=͈D��p���ʯ=���<_:me!�f�o> �g{� <:me<2me_:"k��p<ë<�p:�c��?=>�z=�
�ʯ=� �[=��[=�	�[=�?=ͯN�_�p�_:�p�{�y=:�p��y=��p��:oe�ʑ=!qe:pe _<2pe~��PO:pe_ !qe<2peyq��p�p��\ ͂Q�p:�cLZ���=$[��=�O X�wp��NDX�wp��NYX�wp�Sp:�c�İ>��=ͥ?����=�p�p��p��>2�c��2mb:�p�:mb�#p���=���=�ʩ>�ʪ>_:�p��U>:#g��G>�,?��={��U>>2#g��=��c>!$p|��c>���}>:mb��}>�
�}>�	�}>� ��_p���=:�c����>�p:�p��p�p!�c4~�3��=6 :mbɯ2%g��=>��!�c\  �tp�AP�?!�c>��w[���wp�Z�wp!$k5��>���P��>�:�c��*,ks#",k��jS��P�?ͤS�X�wp�GQ�?!�c~�w��V�wp\ ͂Q�2�c��?{�Y�=?>2#g��Z�c?�A�^?�L�^?�A*zp_ ��p�wp�2#g�>ͯN_�p>/ͯN_�p>KͯN_�p�^?�?{�2#k>2#gɯ2#g{�O:#kG�p�np��p��ZO_2�l:�p���?�p{ͯN_��p��p:�p��ZO{�_�p�ZO�p���?G���?�_�C��?oX�wp�Vp:�c��?��S�@�a�OO�ZOx�?�:@:�c��@�\�wp�\�wp�Yp%]�wp��N7]�wp��?x�0�Q@�ͯN_�p�p�p�ZO:�p��i@xͯN_�p�p�p�ZOx�_�P�|@:�p�2�p�ZO:�c��@x�_�R@>�2�c[�wp�ZO�Q¬@>�2�c�Z�wp�ZOx��\pý@��p�ZO��_�D��?�ZOCPSCPM.ASM (14)  1-Apr-1991$\ >ͥG��@�
A:\ � ��@�2\ !] 6?#�A�	T:\ ��A:�c�@2�X:�l�0�&A> 2�X:�l2�X�OO�X�wp>2�p:=j��KA:�p<2�p�20g22G23G24G!1g".gͦB�20g��E�nA��A:�c�A͂Q�ʆA͂Q��A!] ��A>.ͺA��A�9B!�p5�ĪA���A�eA͸A>:ͺAøA͸A> ���_͂Q����~�ͺA#��A�����OO���6:=j��4��OO:�c=_͂Q���22G23G:\ ��
B=_͂Q�qp��X�wp:\ ��!B͂Q<�@2�X�X�wp��#OY�wp��A:=j��#\ ͂Q:}   o��UB ��:~ 2~ :} 2} �XBo:~ g�	:�p�O	/�o���	ڍB͵AÙB����	ڙB͸A͸A��#O>kͺA�͂Q##~2�p#~2�p##^#V�"�p�>\ ͥG��>ͥG��\ ͂Q<��B�U�wp��\ ͂QY�wp��>ͥG��>ͥG��**g�!���>C�}2�c] ͂Q�	T:�l�0�,C> 2�T2�X:�l2�T2�X���V�wp��>\ ͥG�"D�22G23G24G20g!1g".k��E�"D�2p�2�l\ �nO͍O��CÈC:$k=�xC2$k*,k~#",k�� ��C�	¯C> �/D:�l�CÁC�¾C�/D�2�lÁC�
��C�/D�2�lÁC���C��C�>^�/D��/DÁC\ ͂Q>�/D>
�/D��E�kC�2 g��\ ͂Q>�/D>
�/D�2 g:�c��wR���`�wp�2 g��_�VD�RD�ND��p:�l<2�l�: g����R����C��D�͈D��{D�ʆD�ʁD͈D��iD�ʆD�ʁD�7?�ZO�7�ZO���p�� �>>jͥG��>_jͥG��>ͥG��>j!_j�2!g���D:!g<2!g#½D:!g���D�`�wp��>j͂Q<��D�`�wp��_j͂Q_j͂Q<�E{U�wp�mE_j͂Q<�&E�U�wp�mE�2-m2.m2�c!>j\ ! �tp͍O�xE*,k�͂Q_j͂Q��<E�U�wp_j͂Q_j͂Q>j͂Q��_j͂Q�mE>>jͥG��>_jͥG��>j͂Q<®E�`�wp��_j͂Q<��E�W�wp��!_jNj �tp>j͂Q<���U�wp��CPSWLD.ASM (4)  20-Jun-86$�����F!1g".g:0g��:F*.g\  �tp�2h 2} *.g ".g:0g=20g���F:4G��G!1g".g�20g� ͂Q�2h :2G��xF23G!\ &G �tp\ ͂QÕF=23G!&G\  �tp\ ͂Q͂Q�:3G�ʥF=23G�ÐF���F�G:&G2\ :2G<22G> 2h 2} *.g�!\  �tp*.g ".g:0g<20g�@�F\ !&G �tpÐF����24G:0g��F�24G23G22G7��F�����O !� 	\  �tp�               CPSCMD.ASM (13)  17-Jan-1991$��"wb!  9"ub�"yb�!b"c"c�2pb2sb�OOÄN*ub�!b"c*wb�*ub�!b"c"c�2pb2sb�OÖ́N*wb�2obͨM�>�2tb���eI���I��K��K��K���G���H�`�wpɯ2c2c2c�"{b �OM��(H���H͂Q�2pb*c+"c"c!sb5��G�?�vH��2px*{b��ZO�\�;H:c�/�;H2c��G_:c�{�}H�\�OH:cÃH�0��H��H_:c����2c:c<2c�:c�}H��G*c#"c͎H��G͎H>\2c��G*{bw#"{b�2c2c2c�pa�wp��                                !  "*g�OM��<I��� ��H�ZO      �?��H���HÇG    �ZO**g}��a�I�a�wp�OÖ́N*c6$*c+"cb�wp�2pb�yG>            ��0�\I�
�\I?**g��))) _"*g��HYa�wp�ZO�OM����I͂Q�2pb*c+"c"c!sb5�eI�?¸I�a�wp�OÖ́N*c>$w*c+"cb�wp�2pb�yG��2p�ZO"}b�"{bF#"c*c"
cx��>�2tb*c^#{����J�OM��J��?�J�2pb!sb5*}b��5T�OÖ́N*c>$w*c+"cb�wp�yG�J�2pb�����J�MJ͂Q*c+"c"c!sb5�����I*c+���~�$�iJ#�w#�:sb<2sb�TJ:sb<2sb�> w#"c"c����wp ͂Q���áJ����JßJ�`�wpÇG�� #^#V{�ZO�a��J�{�J�_V#���I {���J� "c*
c"c��I�K{�� F#�*c~�O���J�*
c�ZO�F#�~#�a�K�{�K�_����J> 2c�"�b 6 #"c�6 #<��%K6 #<� �.K�OM��DL��?�cK:c��"M*c#"c:c��^K�2pb>?�M��7L�2pb*c+"c"c!sb5{2�l�	��K=*c��K6?#<ÇK*�b�͂Q���-L!�l�(M!�l�(M*�b�͂Q����K!�l�(M�l!�l:�l�	��K= ���K#��Ky��L���K:�l�	��K>.�@MF#��L� ��K�@M��Ky2�l>$�@M*c�	͂Q*c+"c!sb5:�l��yG͂Q�yG{��M��M�ZO�.�eL{��M�
�M	 *�b	"c	�7K�:L{��M*c+~�@"c6 +w �7K�*´L:c� �"M{��M�LáL*c>?w#"c{���L�7K�!�Mg:�p�|��L�%�M�(�M�)�M�,�M�/�M�:�M�@�M�[�M�^�M�_�M�|�M�a�M�{�M�_*cw#"c�7K:ob��_Oa	͂Q�)a�M�� �<_w#�6M���*cw#"c!sb4����:pb�̨M*c~#"c� �jM�	�}M:tb��QM>�2tb> ��åM��2tb����ʥM�?ʜM�ʜM�
ʜM���*c+"c�������:pb�N!sb4:rb���M�͂Q�ʿM��M͂Q*cw#"c���M���M�)p̈́N!b"c!sb6 �yG��N��/N:rb��/p:sb==��N͂Q��M2sb:rb��,p*c++"c�yG�?�ZN��ZN��KN�
�KN��bN�2p:qb��ZN:sb�ʇG>�2pbÀN:sb�}��M�p:sb=2sb*c+"còM����͂Q*yb��wp�CPSUTL.ASM (31) 21-Mar-1991$��!�pN !�N	���N��N��N��N��N��N���N����N����N���N����N���N���:�p� �O��X�wp��@_͂Q�>ͥG�O��T�wp��>ͥG��>0��S����	�.O��|��+O�}�:��S2�l_:"g��ÂQ�T�wp	ÂQ�###���[�wp� T��fOɯ2$k2-m2�c2.m2h 2j 2| \ ͂Q�:�c�����:-m�ʸO*+m",k� 	"+m=2-m>2$k����ZO:.m���O2�c�2$k����*�p"+m",k�͂Q\ ͂Q2.m���O!-m4:�p��P*,k� ��O�zQÕO�zQ:-mÜO:�c��b*,k:$kG�,P͍O�;P*,k:$kGx2$k~#",k��P�>�2�cɯ2h 2j 2| \ ͂Q��ʹP#\ ͂Q*} |���P+"} *�p�͂Q!\ ͂Q��zQ*�p� >�ʒP#P",k"+m{2$k�2-m�zQ�ZO\ ͂Q�2h 2j 2| \ ͂Q���*�p",k� "+m{2$k�2-m�ZO�!-m4:�p���P5���!-m4:�p���P�Q�Q*+m",k� "+m>2$k��ZO��*�p"+m",k*,k�!� ",k͂Q\ ͂Q��zQ!-m5�Q�zQ�ZO:$k���bQ*,k=�\Q6#�RQ��P�_O:-m��oQ�Q�_O\ ͂Q�ZO� ÂQ�:�c�ʟQy�ʣQ�ʨQ�
ʲQ���Q�� ���Q�{<Q���Q����Q���Q�
ʴQ�& o& �w�4�ôQ�����c*�c~���>���wR��:�c�� R�c*�c~*�c#"�cͣR�}��R�SR����
��Q���wR>��j:�jo:�j��<R:�c��2�c>��R}& <2�j~�;�LR>ͣR��R����c͂Q�c͂Q��wR!  "�c�zQ����:�c��2�c�c͂Q�zQ���*&g#"&g|� R*(g#"(g����
��R���R���R����_� �����{2g��R��R���R�
S��R��jSx�_SG2bd!cd�VS:gw�_�p�:adO:bdGx��S>���	Sy������:,g��MS�RS��MS!ad~#��MS+�_S2ad##�VSN:�f��IS���R���MS�ͤS�y��R������ p���o> �g���<G>�x��������:nb�ʇS>2�fͯN_�p�S�wp�����
[XOFF sent to host]
$����:nb���S�2�f>ͯN_�p�S�wp�����
[XON sent to host]
$���!�l
w#��S���������l!�l	w+��S�����>�2"g �͂Qo& �#O�2"g��͂Q�2�l}�o|�g:�lɯ2�l�$���_�p���
�9T:�l<2�l��9T��`O��5TCPSDAT.ASM (19)  29-Mar-1991$Kermit-80 v4.11 $ has been built from the following modules:$Kermit-80  nnx:>$
$
?Unrecognized command$
?Not confirmed$?Unable to receive initiate
$?Unable to receive file name
$?Unable to receive end of file
$?Unable to receive data
$?Disk full
$?Directory full
$?Unable to receive an acknowledgement from the host
$
?Unable to find file
$?Unable to rename file$
?Disk full$
?Unable to tell host that the session is finished$
?Unable to tell host to logout$
?Kermit has not been configured for a target system$
?Consistency check on configuration failed$
?Error writing to log file
$
?Invalid user number$
?Invalid Pause parameter$
?Invalid BUFFER-SIZE parameter$
?Invalid packet length (too long)$
?Invalid Checktype$
?Too many retries$
?Failed to exchange parameters$
?Failed to receive input string in alloted time$
?File already exists$Completed$Failed$%Renaming file to $
[Closing the log file]$
[Connected to remote host.  Type $C to return;
 type $? for command list]
$
[Connection closed, back at micro]$Control-$ Not implemented.$ (Not implemented)
$Interrupted$		    Directory for drive nnx:
$
		Drive $  has $K bytes free
$
File(s) erased$

[Transmitting file to host:
 1. Lines automatically sent, and wait for possible reply
 2. CONTROL-C aborts transfer
 3. If transfer hangs, try a return to continue
 4. on exit, you will be placed in CONNECT state.
$R to send the same line again,
   or type $C to abort transmission.]
$
[Transmission done. Connected normally to remote host,
 type $Sending...$Receiving...$Warning: eighth bit cannot be sent$
For help, type ? at any point in a command$
[Logging suspended]
$
[Logging resumed]
$
[Transmission Aborted. Connected normally to remote host,
 type $

[Automatically receiving; type ^C to abort]

$

 * * * Press any key to continue * * * 

$
Type the new escape character:  $
Type the new TAC intercept character:  $
Give the start-of-packet character: $
Type the new padding character: $
R Send the same line again$
Q  Suspend logging
R  Resume logging$
?  This message
C  Close the connection
0  (zero) Transmit a NULL
P  Toggle printer on/off
S  Status of the connection$
Typing another $ will send it to the host

Command>$
Transmitting a file$
Autoreceive is$
Local echo$ on$ off$
Flow control$
Terminal display is $REGULAR$QUIET$
Terminal emulation is $
File Mode$ default$ ASCII$ binary$
Display file size on DIRECTORY command$
IBM flag$
Disposition for incomplete files is$ discard$ keep$
File warning$
Printer copy$
Logging to $ is$ suspended$
SEND start-of-pkt char  ^$
RECEIVE start-of-pkt char  ^$
SEND packet length  $
RECEIVE packet length  $
Escape char: $
Multi-sector buffering at $ of a maximum of $
Transmit protocol char: $
Block check type: $-character$
File COLLISION:  $
Parity: $none$mark$space$odd$even$
Port in use is: $
Current speed is: $ bps$indeterminate (not SET)$
Timer$
Current TACTrap Status/Intercept Character:  $
Current user number:  $
Debugging$
Current default disk: $               $
?Source and destination files the same$
?File not found$
?Program error:  Invalid COMND call$
?Ambiguous$
?Illegal CP/M file specification$
?Wild-cards not allowed in file specification$
?Invalid user number$
?Invalid \ parameter$ Confirm with carriage return$ Enter a number$ Confirm with carriage return or enter more$<SState:>  <RState:>  <Data transmitted>  <Data received   >  
 
New file: $
Password: $
Account: $
New name: $
Message: $
Options: $                                                                                                                                                                                                                                                                                                              &   KERMIT  LOG  � KERMIT  INI                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  �                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         $                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     �  �r�rÂsÞsêsósÉsÙsÐs��sûs�  �  ��s��s��s��s�r��q��q��q��q��q��q��qìp��r��r��r��r��r��r��r��r��r�2q�	t�Zq�0r�rJt    Bs�r  ����     PP    ##1 @�      ��p� 2�s� }2�p>r�rvt�rNr�r(t�r�r!�t"�p>@2�p��r� *  "q "q "q "q "q��  �  �  �  �  F�%q�#q=�!q��.t�r��r[͙svt�rUr�r:�p���r�r�:�p�0��q:\ ��mq=�rq� _.� �!� +~wq�zq^#V��� �*�p#  �ڧqW+}�ʸqz¢q�Þq�i`:�p��)=��q��	t�	t�	trt�r�	t��q�	t��q	�	t��q�	t��q:�p��r�r	�	tnt�r;r���	� �����###�~#x��0r�
$configured for $ with $]

Number of packets:
Number of retries:
File name:$


Rpack:

Spack:$CPXSWT.ASM (10)  7-Jan-1991 $CPXSYS.ASM (40)  28-Aug-89 $�����$�_�+r{�{�{��~2�s#~2s�
CRT device
PTR device
TTY device
UC1 device
UR1 device
UR2 device$CRT$msPTR$psTTY$ssUC1$vsUR1$ysUR2$|sU V   W j ~ V�:�s2 �:�s2 ��q���q�K�q���:sO� ����q���q�ͪs�³s��q�q����r���sK�q��Ùs ͙sÙsBt�r;t�rCPXVDU.ASM  (6)  12-Oct-1990 $�Gt�r��l& �;͙s�& �HÙsVT100$<[H[J
		$[H[J$[K$[$[A$[B$[C$[D$$   $   $   [H$M$ [J$[K$Generic CP/M-80 v2.2$                                                                                                                     