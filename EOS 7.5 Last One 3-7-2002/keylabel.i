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
;   keylabel.i
;
;****************************************
;*
;*      Key Labels Include File
;*
;****************************************

        XDEF key_labels

;*****************************************************************
;* User-selectable input labels.
;* Now in a modified alphanumeric order, A-Z, 0-9.
;*
;* If the number of labels is changed, son't forget to adjust the
;* Designators: EQU in EOS_com.s.  Current total = 54 (don't count 0).
;*
;***
key_labels:
           dc.b     '    '    ;0     Default string.
           dc.b     ':AC3'    ;1     LD Dolby Digital audio
           dc.b     ':ADT'    ;2     ADAT tape machine
           dc.b     ':AM '    ;3     Amplitude Modulation radio
           dc.b     ':Aux'    ;4     Auxilliary
           dc.b     ':Ax1'    ;5     Aux 1
           dc.b     ':Ax2'    ;6     Aux 2
           dc.b     ':Ax3'    ;7     Aux 3
           dc.b     ':BS '    ;8     Japanese "Broadcast Satellite"
           dc.b     ':BUD'    ;9     "Big Ugly Dish"
           dc.b     ':Cam'   ;10     Camcorder or security video camera
           dc.b     ':Cas'   ;11     Cassette tape recorder
           dc.b     ':CD '   ;12     Compact Audio Disc
           dc.b     ':CTV'   ;13     Community Antenna TV or Cable TV.
           dc.b     ':DAT'   ;14     Digital Audio Tape
           dc.b     ':DD '   ;15     This input is dedicated to Dolby Diital
           dc.b     ':DMX'   ;16     Digital Music Express
           dc.b     ':DSD'   ;17     Sony DSD
           dc.b     ':Dsh'   ;18     Dish Network Satellite
           dc.b     ':DSS'   ;19     DSS satellite
           dc.b     ':DTS'   ;20     This input is dedicated to DTS audio
           dc.b     ':DTV'   ;21     Direct TV
           dc.b     ':DVA'   ;22     DVD-Audio
           dc.b     ':DVD'   ;23     DVD
           dc.b     ':DVX'   ;24     Digital Video Express
           dc.b     ':DV1'   ;25     DVD 1
           dc.b     ':DV2'   ;26     DVD 2
           dc.b     ':FM '   ;27     Frequency Modulation radio
           dc.b     ':LD '   ;28     Laser Disc
           dc.b     ':LP '   ;29     Record player
           dc.b     ':MD '   ;30     Sony Minidisc
           dc.b     ':MPG'   ;31     This input is dedicated to MPEG audio
           dc.b     ':MP3'   ;32     MPEG1 Layer 3 audio
           dc.b     ':PC '   ;33     Computer
           dc.b     ':PCM'   ;34     Pulse code modulation
           dc.b     ':RCA'   ;35     Coaxial S/PDIF input
           dc.b     ':Rpy'   ;36     Replay TV recorder/time-shifter
           dc.b     ':Sat'   ;37     Satellite
           dc.b     ':SCD'   ;38     Philips SACD
           dc.b     ':Set'   ;39     Set-top box
           dc.b     ':Sky'   ;40     European satellite system
           dc.b     ':ST '   ;41     ST Glass optic fiber 
           dc.b     ':Tap'   ;42     Tape
           dc.b     ':TOS'   ;43     TOSLINK
           dc.b     ':TT '   ;44     Turntable
           dc.b     ':Tun'   ;45     Tuner
           dc.b     ':TVO'   ;46     TiVO video recorder/time-shifter
           dc.b     ':TVP'   ;47     EAD TheaterVision P DVD player
           dc.b     ':UTV'   ;48     Ultimate TV video recorder/time-shifter
           dc.b     ':Ult'   ;49     EAD Ultra DVD-A player
           dc.b     ':VCR'   ;50     Video Cassette Recorder
           dc.b     ':VC1'   ;51     VCR-1
           dc.b     ':VC2'   ;52     VCR-2
           dc.b     ':XM '   ;53     XM satellite radio
           dc.b     ':8mm'   ;54     8 mm VCR

End_key_labels:

;*****************************************************************


      
