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
;   Build.i
;
;****************************************
;*
;*      Build Information Include File
;*
;****************************************

Build:          equ 1                ;to prevent further inclusion

name:           equ 1           ;Ovation-8
;name:           equ 2           ;Signature-8
;name:           equ 3           ;Signature+8 (aka Signature-8a)

brand:          equ     1       ;EAD (set name = 1, 2, or 3).
;brand:          equ     2       ;Legacy Audio Ovation-8 (set name = 1 also)
;brand:          equ     3       ;Simaudio "Attraction" (set name = 1 also)

alpha:          equ     0       ;TheaterMaster 8000/8000 Pro
;alpha:          equ     1       ;EOS TheaterMaster & TheaterMaster 8

;----------------------------------------------------------------------
;*** TO PREVENT ERRORS, DO NOT CHANGE ANYTHING BELOW THIS LINE!!!
;----------------------------------------------------------------------
 IFEQ   name-1   ;Ovation-8

model:          equ     2       ;Ovation-8
Arlon25:        equ     0       ;FR4 pcb.

 ENDC

 IFEQ   name-2   ;Signature-8

model:          equ     2       ;Signature-8
Arlon25:        equ     1       ;Arlon 25N pcb.

 ENDC

 IFEQ   name-3   ;Signature+8

model:          equ     3       ;Signature+8
Arlon25:        equ     1       ;Arlon 25N pcb.

 ENDC

;***************************************************************
;*
;*                   STANDBY DISPLAYS:
;*
;* Brand 1 = EAD
;* =============
;*                          TheaterMaster       (bold)
;*                            Signature   
;*
;*                          TheaterMaster       (bold)
;*                             Ovation          (bold)
;*
;*                          TheaterMaster       (bold)
;*                              Encore          (bold)
;*
;* Brand 2 = Legacy Audio
;* ======================  
;*                             Legacy           (bold)
;*                         Digital Theater      (=Encore)
;*
;* Brand 3 = Simaudio
;* ==================
;*                           Attraction         (=Ovation)
;*
;*                            Stargate          (=Encore?)
;*
;*
;***
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%                                                           %%%%
;%%%%                  Model Dependent Stuff                    %%%%
;%%%%                                                           %%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Four_dB:        equ  4*2            ;4 dB
Five_dB:        equ  5*2            ;5 dB
Six_dB:         equ  6*2            ;6 dB
Twenty_dB:      equ 20*2            ;20 dB
vc_min:         equ 90*2-1          ;Minimum volume count = -90 dB
vc_bot:         equ 95*2            ;Bottom of attenuation count set to -95 dB
adj_start:      equ 30*2            ;Auto level starts at -30 dB for all speakers.
cold_vol:       equ 40*2            ;-40 dB Cold Start volume.

  IFEQ    model-2   ;OVATION-8 or SIGNATURE-8

Anlg_ins:       equ  3              ;Ovation-8 and Signature-8 have 3 analog inputs
                                    ; (not counting the analog pass-thru inputs)
  ELSEC             ;SIGNATURE+8

Anlg_ins:       equ  6              ;Signature+8 has 6 analog inputs.
                                    ; (not counting the analog pass-thru inputs)
  ENDC

