;  D7-D4 D3 D2-D0    D7-D0
;           A23-A21  A20-A13
;   xxxx  L   yyy zzzzzzzz
;
;
;
;
;
;
;
;
;
;
;
;
;



        .ORG    0E000H

        JP      CSTART
CSTART:
;-------------------------------
; 32K RAM
; ----- $0000-$1FFF
        LD      A,00000000B     ;
        OUT     ($F8),A         ; lo addr (        A20-A13 )
        LD      A,00001000B     ; L,000000
        OUT     ($F8),A         ; hi addr ( Local, A23-A21 )
; ----- $2000-$3FFF
        LD      A,00000001B     ;
        OUT     ($F9),A         ; lo addr (        A20-A13 )
        LD      A,00001000B     ; L,002000
        OUT     ($F9),A         ; hi addr ( Local, A23-A21 )
; ----- $4000-$5FFF
        LD      A,00000010B     ;
        OUT     ($FA),A         ; lo addr (        A20-A13 )
        LD      A,00001000B     ; L,004000
        OUT     ($FA),A         ; hi addr ( Local, A23-A21 )
; ----- $6000-$7FFF
        LD      A,00000011B     ;
        OUT     ($FB),A         ; lo addr (        A20-A13 )
        LD      A,00001000B     ; L,006000
        OUT     ($FB),A         ; hi addr ( Local, A23-A21 )

;        JP      MM1
;-------------------------------
; CHECK WRITE/READ CYCLE FIRS 32k of ADDRESS SPACE
;
        LD      HL,0000H        ; Start of Video RAM
RAMLoop:
        LD      A, 55H
        LD      (HL),A
        CP      (HL)
        JP      NZ, EndOfRAM
        INC     HL
        LD      A, H
        CP      80H
        JP      NZ, RAMLoop
        JP      MM1
EndOfRAM:
        LD      A, H
        CP      80H
        JP      NZ, MM3
        JP      MM2

MM1:

;-------------------------------
; 24K VIDEO RAM (00000h - 05FFFh) ( 0000h-2FFFh 16bits wide )
;                                   000 0 0000 0000 0000 - 010 1 1111 1111 1111
;                                    0000 0000 0000 0000 -  0010 1111 1111 1111
; ----- $8000-$9FFF
        LD      A,11110000B     ;
        OUT     ($FC),A         ; lo addr (        A20-A13 )
; ----- $A000-$BFFF
        LD      A,11110001B     ;
        OUT     ($FD),A         ; lo addr (        A20-A13 )
; ----- $C000-$DFFF
        LD      A,11110010B     ;
        OUT     ($FE),A         ; lo addr (        A20-A13 )

;
        LD      HL,8000H        ; Start of Video RAM
        LD      SP,HL 

        LD      HL,8000H        ; Start of Video RAM
        LD      C,00101111B     ; Color 
;
; FIRST LINE
;
        LD      A,11001001B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      B,126
        
ML1:    LD      A,11001101B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        DJNZ    ML1

        LD      A,10111011B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     H               ; add Y + 1
        INC     H               ; add Y + 1
        LD      L,0             ;
;
; 2 - 94 LINES
;
        LD      D,94
        LD      E,00

ML2:
        LD      A,10111010B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      B,126
        LD      A,D
        SUB     E               ;
        LD      C,A             ; Color 
        LD      A,E

ML3:
        LD      (HL),A          ;
        INC     HL              ;
        INC     A               ;

        LD      (HL),C          ;
        INC     HL              ;
        INC     C               ;

        DJNZ    ML3

        LD      A,10111010B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      C,00101111B     ; Color 
        LD      (HL),C          ;
        INC     H               ; add Y + 1
        LD      L,0             ;

        INC     E
        DEC     D
        JP      NZ,ML2
;
; LAST LINE
;
        LD      A,11001001B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      B,126
        
ML4:    LD      A,11001101B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        DJNZ    ML4

        LD      A,10111011B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
;
;
;
        LD      D,0FFH
ML21:
ML31:
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        DJNZ    ML31

        DEC     D
        JP      NZ,ML21
;
; CLEAR SCREEN
;
        LD      HL,8100H        ; Start of Video RAM
        LD      C,00101111B     ; Color 

        LD      D,8
ML42:
        LD      A,10111010B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      B,126
        
ML41:   LD      A,00100000B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        DJNZ    ML41

        LD      A,10111010B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     H               ; add Y + 1
        LD      L,0             ;

        DEC     D
        JP      NZ,ML42
;
; WRITE SCREEN
;
        LD      HL,8210H        ; Start of Video RAM
        LD      A,'t'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'Z'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'8'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'0'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,' '
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'C'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'P'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'U'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,' '
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'a'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'t'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,' '
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'5'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'M'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'H'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'z'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;

        LD      HL,8410H        ; Start of Video RAM
        LD      A,'S'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'D'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'R'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'A'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'M'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,' '
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'w'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'o'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'r'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'k'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,' '
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'8'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'M'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'b'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;

        LD      HL,8610H        ; Start of Video RAM
        LD      A,'V'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'I'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'D'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'E'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'O'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,' '
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'1'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'2'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'8'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'x'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'9'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'6'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,' '
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'1'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'6'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'c'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'o'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'l'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'o'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'r'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;
        LD      A,'s'
        LD      (HL),A          ;
        INC     HL              ;
        INC     HL              ;

;
;
;
        LD      D,0FFH
ML61:
ML51:
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        DJNZ    ML51

        DEC     D
        JP      NZ,ML61

        LD      A,00000001B     ;
        OUT     ($F7),A         ; Video ctrl reg - set scale x2
;
;
;
        LD      D,0FFH
ML62:
ML52:
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        DJNZ    ML52

        DEC     D
        JP      NZ,ML62

        LD      A,00000010B     ;
        OUT     ($F7),A         ; Video ctrl reg - set scale x4
;
;
;
        LD      D,0FFH
ML63:
ML53:
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        DJNZ    ML53

        DEC     D
        JP      NZ,ML63

        LD      A,00010000B     ;
        OUT     ($F7),A         ; Video ctrl reg - set scale x1, multy color 


        JP      CSTART

MM2:

;-------------------------------
; 24K VIDEO RAM (06000h - 0BFFFh) ( 3000h-5FFFh 16bits wide )
;                                   0011 0000 0000 0000 - 0101 1111 1111 1111
; ----- $8000-$9FFF
        LD      A,11110000B     ;
        OUT     ($F4),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FE6000
        OUT     ($F4),A         ; hi addr ( Local, A23-A21 )
; ----- $A000-$BFFF
        LD      A,11110001B     ;
        OUT     ($F5),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FE8000
        OUT     ($F5),A         ; hi addr ( Local, A23-A21 )
; ----- $C000-$DFFF
        LD      A,11110010B     ;
        OUT     ($F6),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FEA000
        OUT     ($F6),A         ; hi addr ( Local, A23-A21 )

;-------------------------------
; 8K ROM
; ----- $E000-$FFFF
;       LD      A,11110111B     ;
;       OUT     ($FF),A         ; lo addr (        A20-A13 )
;       LD      A,00001111B     ; L,FEE000
;       OUT     ($F7),A         ; hi addr ( Local, A23-A21 )

        LD      HL,8000H        ; Start of Video RAM

ML9:    LD      A,11011001B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      A,10000111B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      A,H             ; Above address FFFF ?
        CP      0E0H
        JP      NZ,ML9       ; Yes - 64K RAM

        JP      CSTART

MM3:

;-------------------------------
; 24K VIDEO RAM (0C000h - 11FFFh) ( 6000h-8FFFh 16bits wide )
;                                   0110 0000 0000 0000 - 1000 1111 1111 1111
; ----- $8000-$9FFF
        LD      A,11110000B     ;
        OUT     ($FC),A         ; lo addr (        A20-A13 )
;        LD      A,00001111B     ; L,FEC000
;        OUT     ($F4),A         ; hi addr ( Local, A23-A21 )
; ----- $A000-$BFFF
        LD      A,11110001B     ;
        OUT     ($FD),A         ; lo addr (        A20-A13 )
;        LD      A,00001111B     ; L,FEE000
;        OUT     ($F5),A         ; hi addr ( Local, A23-A21 )
; ----- $C000-$DFFF
        LD      A,11110010B     ;
        OUT     ($FE),A         ; lo addr (        A20-A13 )
;        LD      A,00001111B     ; L,FF0000
;        OUT     ($F6),A         ; hi addr ( Local, A23-A21 )

;-------------------------------
; 8K ROM
; ----- $E000-$FFFF
;        LD      A,11110011B     ;
;        OUT     ($FF),A         ; lo addr (        A20-A13 )
;        LD      A,00001111B     ; L,FF6000
;        OUT     ($F7),A         ; hi addr ( Local, A23-A21 )

        LD      HL,8000H        ; Start of Video RAM

        LD      C,01011111B     ;

        LD      A,11001001B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      B,126
        
MLO1:   LD      A,11001101B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        DJNZ    MLO1          ; Yes - 64K RAM

        LD      A,10111011B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      D,94
        LD      E,00

MLO2:
        LD      A,10111010B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      B,126
        LD      A,E

MLO3:
        LD      (HL),A          ;
        INC     HL              ;
        INC     A               ;

        LD      (HL),C          ;
        INC     HL              ;

        DJNZ    MLO3        ; Yes - 64K RAM

        LD      A,10111010B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        DEC     E
        DEC     D
        JP      NZ,MLO2       ; Yes - 64K RAM

        LD      A,11001001B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        LD      B,126
        
MLO4:   LD      A,11001101B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        DJNZ    MLO4          ; Yes - 64K RAM

        LD      A,10111011B     ; 
        LD      (HL),A          ;
        INC     HL              ;

        LD      (HL),C          ;
        INC     HL              ;

        JP      CSTART

MM4:

;-------------------------------
; 24K VIDEO RAM (18000h - 1DFFFh) ( C000h-EFFFh 16bits wide )
;                                   1001 0000 0000 0000 - 1011 1111 1111 1111
; ----- $8000-$9FFF
        LD      A,11111100B     ;
        OUT     ($FC),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FF8000
        OUT     ($F4),A         ; hi addr ( Local, A23-A21 )
; ----- $A000-$BFFF
        LD      A,11111101B     ;
        OUT     ($FD),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FFA000
        OUT     ($F5),A         ; hi addr ( Local, A23-A21 )
; ----- $C000-$DFFF
        LD      A,11111110B     ;
        OUT     ($FE),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FFE000
        OUT     ($F6),A         ; hi addr ( Local, A23-A21 )

;-------------------------------
; 8K ROM
; ----- $E000-$FFFF
;        LD      A,11110111B     ;
;        OUT     ($FF),A         ; lo addr (        A20-A13 )
;        LD      A,00001111B     ; L,FFE000
;        OUT     ($F7),A         ; hi addr ( Local, A23-A21 )

        LD      HL,8000H        ; Start of Video RAM

ML8:    LD      A,11011001B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      A,00000111B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      A,H             ; Above address FFFF ?
        CP      0E0H
        JP      NZ,ML8          ; Yes - 64K RAM

        JP      CSTART

MM5:

;-------------------------------
; 24K VIDEO RAM (12000h - 17FFFh) ( 9000h-BFFFh 16bits wide )
;                                   1001 0000 0000 0000 - 1011 1111 1111 1111
; ----- $8000-$9FFF
        LD      A,11111001B     ;
        OUT     ($FC),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FF2000
        OUT     ($F4),A         ; hi addr ( Local, A23-A21 )
; ----- $A000-$BFFF
        LD      A,11111010B     ;
        OUT     ($FD),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FF4000
        OUT     ($F5),A         ; hi addr ( Local, A23-A21 )
; ----- $C000-$DFFF
        LD      A,11111011B     ;
        OUT     ($FE),A         ; lo addr (        A20-A13 )
        LD      A,00001111B     ; L,FF6000
        OUT     ($F6),A         ; hi addr ( Local, A23-A21 )

;-------------------------------
; 8K ROM
; ----- $E000-$FFFF
;        LD      A,11110111B     ;
;        OUT     ($FF),A         ; lo addr (        A20-A13 )
;        LD      A,00001111B     ; L,FFE000
;        OUT     ($F7),A         ; hi addr ( Local, A23-A21 )

        LD      HL,8000H        ; Start of Video RAM

ML7:    LD      A,11011001B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      A,00000111B     ;
        LD      (HL),A          ;
        INC     HL              ;

        LD      A,H             ; Above address FFFF ?
        CP      0E0H
        JP      NZ,ML7       ; Yes - 64K RAM

        JP      CSTART


.end