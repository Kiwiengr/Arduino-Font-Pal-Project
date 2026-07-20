;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%                       %%%%
;%%%%   @   @ @@@@@ @@@@    %%%%
;%%%%   @   @ @     @   @   %%%%
;%%%%   @   @ @@@   @   @   %%%%
;%%%%    @ @  @     @   @   %%%%
;%%%%     @   @     @@@@    %%%%
;%%%%                       %%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;   English.i
;
;**********************************************************************
;*
;*                   English Features include file
;*
;**********************************************************************

;***************************************
;*** Long Features list ***
;***************************************

Long_features:

        dc.b     '    High-End A/V    |'         ;All
        dc.b     '      L             '
        dc.b     '    Preamplifier    |'
        dc.b     '         L          '

 IFEQ brand-1        ;EAD brand.

        dc.b     ' Reference CinemaTM |'         ;All
        dc.b     ' B         B     SS '
        dc.b     '   & Cinema 7.1TM   |'
        dc.b     '     B      BBBSS   '

 ENDC
 IFEQ brand-2                              ;Legacy NexStep2 (Ovation-8)

        dc.b     '    Theater Mode    |'         ;All
        dc.b     '    B       B       '
        dc.b     '   & Ambient 7.1    |'
        dc.b     '     B       BBB    '

 ENDC
 IFEQ brand-3                              ;SimAudio Moon Attraction Mk II (Ovation-8 only)

        dc.b     ' Reference Theater  |'         ;All
        dc.b     ' B         B        '
        dc.b     '   & Theater 7.1    |'
        dc.b     '     B       BBB    '

 ENDC

        dc.b     '  )( Dolby Digital  |'         ;All
        dc.b     '  ll     L   L      '
        dc.b     'dts Digital Surround|'
        dc.b     'lll   L             '

        dc.b     'MPEG2 Digital Audio |'         ;All
        dc.b     '        L           '
        dc.b     '(2-ch. + Pro Logic) |'
        dc.b     '               L    '

        dc.b     '8-ch. Anlg Pass-Thru|'         ;All  
        dc.b     '         L          '
        dc.b     '   HhDCcBb Audio    |'          
        dc.b     '   HHHHHHH          '

 IFEQ Arlon25-1

        dc.b     '  Arlon 25n analog  |'         ;Signature-8 and Signature+8
        dc.b     '  BBBBB BBB      L  '
        dc.b     '   circuit board    |'
        dc.b     '                    '

 ENDC

 IFEQ name-2

        dc.b     ' Premium 24-bit D/A |'         ;Ovation-8 and Signature-8
        dc.b     '                    '
        dc.b     '   20-bit -+ A/D    |'
        dc.b     '          SS        '

 ELSEC

        dc.b     ' Premium 24-bit D/A |'         ;Signature+8
        dc.b     '                    '
        dc.b     ' Premium 20-bit A/D |'
        dc.b     '                    '

 ENDC

        dc.b     '    Auto SetupTM    |'         ;All
        dc.b     '             LSS    '
        dc.b     '(level,delay,phase) |'
        dc.b     '           L L      '

        dc.b     'High Quality Analog |'         ;All
        dc.b     '  L        L      L '
        dc.b     '  Volume Control    |'
        dc.b     '                    '

        dc.b     '      cinEQ_TM      |'         ;All
        dc.b     '      llllllSS      '
        dc.b     '6-Channel Cinema EQ |'
        dc.b     '                    '

        dc.b     '   A/V Switching    |'         ;All
        dc.b     '               L    '
        dc.b     '  RS-232 Interface  |'
        dc.b     '                    '


End_Long_feats:





