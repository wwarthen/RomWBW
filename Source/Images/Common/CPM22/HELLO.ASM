        ORG     100H

BDOS    EQU     0005H                   ; LOCATION OF BDOS ENTRY POINT
BOOT    EQU     0000H                   ; LOCATION OF BOOT REQUEST

START:
        MVI     C,9                     ; BDOS REQUEST 9 - PRINT STRING
        LXI     D,MESSAGE               ; OUR STRING TO PRINT
        CALL    BDOS
        JMP     BOOT                    ; EXIT TO CP/M

MESSAGE:
        DB      13,10,'Hello World from CP/M!',13,10,'$'

        END     START
