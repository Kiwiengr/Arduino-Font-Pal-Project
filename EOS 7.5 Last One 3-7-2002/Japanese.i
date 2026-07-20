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
;   Japanese.i
;
;****************************************
;*
;*      Japanese Features Include File
;*
;****************************************

Japanese: equ 1              ;to prevent further inclusion

;English transliteration for Japanese Kana symbols:
.stop:          equ       $a1
.l_quote:       equ       $a2
.r_quote:       equ       $a3
.comma:         equ       $a4
.separator:     equ       $a5
.o2:            equ       $a6       ;Also see .o
.sml.a:         equ       $a7
.sml.i:         equ       $a8
.sml.u:         equ       $a9
.sml.e:         equ       $aa
.sml.o:         equ       $ab
.sml.ya:        equ       $ac
.sml.yu:        equ       $ad
.sml.yo:        equ       $ae
.sml.tsu:       equ       $af
.long:          equ       $b0       ;-
.a:             equ       $b1
.i:             equ       $b2
.u:             equ       $b3
.e:             equ       $b4
.o:             equ       $b5       ;Also see .o2
.ka:            equ       $b6
.ki:            equ       $b7
.ku:            equ       $b8
.ke:            equ       $b9
.ko:            equ       $ba
.sa:            equ       $bb
.shi:           equ       $bc
.su:            equ       $bd
.se:            equ       $be
.so:            equ       $bf
.ta:            equ       $c0
.chi:           equ       $c1
.tsu:           equ       $c2
.te:            equ       $c3
.to:            equ       $c4
.na:            equ       $c5
.ni:            equ       $c6
.nu:            equ       $c7
.ne:            equ       $c8
.no:            equ       $c9
.ha:            equ       $ca
.hi:            equ       $cb
.fu:            equ       $cc
.he:            equ       $cd
.ho:            equ       $ce
.ma:            equ       $cf
.mi:            equ       $d0
.mu:            equ       $d1
.me:            equ       $d2
.mo:            equ       $d3
.ya:            equ       $d4
.yu:            equ       $d5
.yo:            equ       $d6
.ra:            equ       $d7
.ri:            equ       $d8
.ru:            equ       $d9
.re:            equ       $da
.ro:            equ       $db
.wa:            equ       $dc
.ng:            equ       $dd

_s:             equ       $de       ;sonant ("ten ten" or "dot dot")
_h:             equ       $df       ;half-sonant ("maru" or "circle")

.j_yen:         equ       $fc       ;Japanese symbol for Yen.
.i_yen:         equ       $5c       ;International symbol for Yen.
.s:             equ       $20       ;space

_ga:            equ       $b6       ;= ka + " (sonant)
_gi:            equ       $b7       ;= ki + " (sonant)
_gu:            equ       $b8       ;= ku + " (sonant)
_ge:            equ       $b9       ;= ke + " (sonant)
_go:            equ       $ba       ;= ko + " (sonant)

_za:            equ       $bb       ;= sa + " (sonant)
_ji:            equ       $bc       ;= shi+ " (sonant)
_zu:            equ       $bd       ;= su + " (sonant)
_ze:            equ       $be       ;= se + " (sonant)
_zo:            equ       $bf       ;= so + " (sonant)

_da:            equ       $c0       ;= ta + " (sonant)
_de:            equ       $c3       ;= te + " (sonant)
_do:            equ       $c4       ;= to + " (sonant)

_ba:            equ       $ca       ;= ha + " (sonant)
_bi:            equ       $cb       ;= hi + " (sonant)
_bu:            equ       $cc       ;= fu + " (sonant)

_pa:            equ       $ca       ;= ha + o (half-sonant)
_pi:            equ       $cb       ;= hi + o (half-sonant)
_pu:            equ       $cc       ;= fu + o (half-sonant)
_be:            equ       $cd       ;= he + " (sonant)
_bo:            equ       $ce       ;= ho + " (sonant)

_pe:            equ       $cd       ;= he + o (half-sonant)
_po:            equ       $ce       ;= ho + o (half-sonant)
                                   


;********************************************
;*** Exit Standby Screen ***
;********************************************

J_Exit_Stdby_scrn:

 IFEQ model - 3                                                                 ;Signature

                 ;'TheaterMaster; Signature'
        dc.b     '       ',.shi,.a,.ta,.long,.ma,.su,.ta,.long,'     |'
        dc.b     '                    '
        dc.b     '       ',.shi,_gu,_s,.na,.chi,.sml.ya,.long,'      |'
        dc.b     '                    '

 ENDC
 IFEQ model - 2                                                                 ;Ovation
                 ;'TheaterMaster; Ovation'
        dc.b     '      ',.shi,.a,.ta,.long,.ma,.su,.ta,.long,'      |'
        dc.b     '                    '
        dc.b     '      ',.o,.u,_s,.sml.e,.i,.shi,.sml.yo,.ng,'      |'
        dc.b     '                    '

 ENDC
 IFEQ model - 1                                                                 ;Encore
                 ;'TheaterMaster; Encore'
        dc.b     '      ',.shi,.a,.ta,.long,.ma,.su,.ta,.long,'      |'
        dc.b     '                    '
        dc.b     '       ',.a,.ng,.ko,.long,.ru,'        |'
        dc.b     '                    '

 ENDC


;***************************
;*** Features Heading ***    (for IR Features command only)
;***************************

J_Features:      ;'***Features***'
        dc.b     '   ***',.fu,.sml.i,.long,.chi,.sml.ya,.long,_zu,_s,'***   |'
        dc.b     '   SSS        SSS   '
        dc.b     '                    |'
        dc.b     '                    '                   


;********************************************
;*** Short Features list ***
;********************************************

J_Short_features:

                 ;')( Dolby Digital; dts Digital Surround'
        dc.b     '  )(',_do,_s,.ru,_bi,_s,.long,_de,_s,_ji,_s,.ta,.ru,'    |'   ;All
        dc.b     '  ll                '
        dc.b     '  dts',_de,_s,_ji,_s,.ta,.ru,.sa,.ra,.u,.ng,_do,_s,'   |'
        dc.b     '  lll               '

 IFNE model - 1 

                 ;'HDCD Audio; MPEG2 Digital Audio'
        dc.b     '   HhDCcBb',.o,.long,_de,_s,.sml.i,.o,'    |'         
        dc.b     '   lllllll          '
        dc.b     ' MPEG2 ',_de,_s,_ji,_s,.ta,.ru,.o,.long,_de,_s,.sml.i,.o,' |' ;Signature, Ovation
        dc.b     '                    '

 ENDC
 IFEQ model - 1 

                 ;'MPEG2; Digital Audio'
        dc.b     '       MPEG2        |'                                        ;Encore
        dc.b     '                    '
        dc.b     '    ',_de,_s,_ji,_s,.ta,.ru,.o,.long,_de,_s,.sml.i,.o,'    |'         
        dc.b     '                    '

 ENDC

J_End_Short_feats:

        dc.b     0     ;Separator

;********************************************
;*** Long Features list ***
;********************************************

J_Long_features:

                 ;'High-End Surround; Sound Processor'
        dc.b     '    ',.ha,.i,.e,.ng,_do,_s,.sa,.ra,.u,.ng,_do,_s,'    |'      ;All
        dc.b     '                    '
        dc.b     '    ',.sa,.u,.ng,_do,_s,_pu,_h,.ro,.se,.sml.tsu,.sa,.long,'    |'
        dc.b     '                    '


                 ;')( Dolby Digital; dts Digital Surround'
        dc.b     '  )(',_do,_s,.ru,_bi,_s,.long,_de,_s,_ji,_s,.ta,.ru,'    |'   ;All
        dc.b     '  ll                '
        dc.b     '  dts',_de,_s,_ji,_s,.ta,.ru,.sa,.ra,.u,.ng,_do,_s,'   |'
        dc.b     '  lll               '


                 ;'MPEG2 Digital Audio; <2-ch. + Pro Logic>' 
        dc.b     ' MPEG2 ',_de,_s,_ji,_s,.ta,.ru,.o,.long,_de,_s,.sml.i,.o,' |' ;All
        dc.b     '                    '
        dc.b     ' <2',.chi,.sml.ya,.ne,.ru,'+',_pu,_h,.ro,.separator,.ro,_ji,_s,.sml.tsu,.ku,'>  |'         ;Update to 5.1-channels later...
        dc.b     '                    '



 IFNE model - 1
 
                 ;'HDCD High Definition; Compatible Digital'
        dc.b     ' HhDCcBb',.ha,.i,_de,_s,.fu,.sml.i,.ni,.shi,.sml.yo,.ng,'  |' ;Ovation, Signature
        dc.b     ' HHHHHHH            '
        dc.b     '   ',.ko,.ng,_pa,_h,.chi,_bu,_s,.ru,_de,_s,_ji,_s,.ta,.ru,'   |'          
        dc.b     '                    '


                 ;'AccuLinearTM; circuitry'
        dc.b     '      ',.a,.ki,.sml.yu,.ri,.ni,.a,'TM      |'                 ;Ovation, Signature
        dc.b     '            SS      '
        dc.b     '       ',.sa,.long,.ki,.sml.tsu,.to,'        |'          
        dc.b     '                    '


 ENDC
 IFEQ model - 1

                 ;'20-bit -+ D/A; 20-bit -+ A/D'
        dc.b     '   20',_bi,_s,.sml.tsu,.to,'-+',_de,_s,_ji,_s,.a,.na,'   |' ;Encore
        dc.b     '         SS         '
        dc.b     '   20',_bi,_s,.sml.tsu,.to,'-+',.a,.na,_de,_s,_ji,_s,'   |'
        dc.b     '         SS         '

 ENDC
 IFEQ model - 2

                 ;'Premium 20-bit D/A; 20-bit -+ A/D'
        dc.b     ' ',_pu,_h,.re,.mi,.a,.mu,'20',_bi,_s,.sml.tsu,.to,_de,_s,_ji,_s,.a,.na,' |' ;Ovation
        dc.b     '                    '
        dc.b     '   20',_bi,_s,.sml.tsu,.to,'-+',.a,.na,_de,_s,_ji,_s,'   |'
        dc.b     '         SS         '

 ENDC
 IFEQ model - 3

                 ;'Premium 20-bit D/A; Premium 20-bit A/D' 
        dc.b     ' ',_pu,_h,.re,.mi,.a,.mu,'20',_bi,_s,.sml.tsu,.to,_de,_s,_ji,_s,.a,.na,' |' ;Signature
        dc.b     '                    '
        dc.b     ' ',_pu,_h,.re,.mi,.a,.mu,'20',_bi,_s,.sml.tsu,.to,.a,.na,_de,_s,_ji,_s,' |'
        dc.b     '                    '

 ENDC

                 ;'Auto SetupTM; (spkr level & delay)'
        dc.b     '    ',.o,.long,.to,.se,.sml.tsu,.to,.a,.sml.tsu,_pu,_h,'TM    |'  ;All
        dc.b     '              SS    '
        dc.b     '<',.su,_pi,_h,.long,.ka,.re,_be,_s,.ru,.a,.ng,_do
        dc.b     _s,_de,_s,.sml.i,.re,.i,'>|'
        dc.b     '                    '


                 ;'Switch Resistor; Array Volume Control'
        dc.b     '     ',.su,.i,.sml.tsu,.chi,.re,_ji,_s,.su,.ta,.long,'     |'     ;All
        dc.b     '                    '
        dc.b     '  ',.a,.re,.i,_bo,_s,.ri,.sml.yu,.long,.mu,.ko,.ng,.to,.ro,.long,.ru,'   |'
        dc.b     '                    '


 IFNE model - 1

                 ;'Digital FlywheelTM; jitter reduction'                        
        dc.b     '   ',_de,_s,_ji,_s,.ta,.ru,.fu,.ra,.i,.ho,.i,.long,.ru,'TM  |'  ;Ovation, Signature
        dc.b     '                SS  '
        dc.b     '    ',_ji,_s,.sml.tsu,.ta,.long,.ri,_da,_s,.ku,.shi,.sml.yo,.ng,'    |'        
        dc.b     '                    '         
                                              
 ENDC

                 ;'CINEQ TM; 5-channel cinema equalizer'
        dc.b     'cinEQ_TM            |'                                          ;All
        dc.b     'llllllSS            '
        dc.b     '    5',.chi,.sml.ya,.ng,.ne,.ru,.shi,.ne,.ma,.i,.ko,.ra,.i,_za,_s,.long,'|'
        dc.b     '                    '


                 ;'Audio Video Switching; RS232 Interface'
        dc.b     ' ',.o,.long,_de,_s,.sml.i,.o,_bi,_s,_de,_s,.o,.su,.i,.sml.tsu,.chi,.ng,_gu,_s,' |'
        dc.b     '                    '
        dc.b     '   RS232',.i,.ng,.ta,.long,.fu,.sml.e,.long,.su,'    |'         ;All
        dc.b     '                    '


J_End_Long_feats:





