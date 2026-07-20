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
;   Colddef.i
;
;******************************************************************
;* This table contains the cold start factory default parameters.
;* It will be copied to user adjustable area at first startup or 
;* when the remote key sequence [F][recall] ("factory recall") is
;* received during standby mode.
;* 
;* Note: Default x-over selection is defined in two places below, at
;*       f_spkr_xover-sel and f_spkr-xover.
;***

        XDEF    f_cold_def,f_cold_def_end,f_cold_def_globs,f_chan_pol

f_chan_pol:             dc.b     $80,$80,$80,$80,$80


f_cold_def:

;%%% The next 5 items are per memory and so are called "local".
;%%% There are ten memory locations.

f_active_chs:           dc.b     %00111111     ;Modes: 5.1 (default):    %00111111
                                               ;       3Stereo with SUB: %00110011
                                               ;       Phantom with SUB: %00101111 
                                               ; Order: SUB,C,RS,LS,R,L.

f_spkr_xover_sel:       dc.b     %00011111     ;C,LS,RS,R,L selected to be crossed over to SUB.
                                               ; Order: SUB,C,RS,LS,R,L.

f_spkr_rloff_sel:       dc.b     %00011100     ;C,LS,RS selected to be rolled off (HPF).
                                               ; Order: SUB,C,RS,LS,R,L.

f_xover_freq:           dc.b     2             ;X-over frequency 80 Hz.


f_cold_start_volume:    dc.w     cold_vol      ;LF  (0.5 dB/step CS3310)
                        dc.w     cold_vol      ;RF
                        dc.w     cold_vol      ;LS
                        dc.w     cold_vol      ;RS
                        dc.w     cold_vol      ;C
                        dc.w     cold_vol      ;SUB-R
                        dc.w     cold_vol      ;SUB-L     >>>>
                        dc.w     cold_vol      ;ES        >>>>


;%%% The next items apply to all inputs, and so are called "global".
;%%% Permanent, stored in EEPROM, may be changed by user.
;Not listed below: Digital and analog input designators default to blank.

f_cold_def_globs:

f_spkr_cfg:             dc.b     %00001000     ;Reference Cinema with 2 subs.
                                               ;      #  M M
                                               ;      S  o o
                                               ;      u  v d
                                               ;      b  i e
                                               ;      s  e
                                               ; 0 = %00 0 0 Ref. Cinema, 0 subs.
                                               ; 4 = %01 0 0 Ref. Cinema, 1 sub.
                                               ; 8 = %10 0 0 Ref. Cinema, 2 subs.
                                               ; 5 = %01 0 1 Cinema 7.1 Movie, 1 sub.
                                               ; 1 = %00 0 1 Cinema 7.1 Movie, 0 subs.
                                               ; 7 = %01 1 1 Cinema 7.1 Music, 1 sub.
                                               ; 3 = %00 1 1 Cinema 7.1 Music, 0 subs.

f_balanced:             dc.b     %00110000     ;D6 = 0 = LF/RF Balanced,
                                               ;D5 = 1 = SR/SL = Single.
                                               ;D4 = 1 = CTR/ES/LS/RS Single.

f_dtape_inp:            dc.b     $0            ;Digital tape input lockout
                                               ; (This input can't be selected as tape/mon source).

f_atape_inp:            dc.b     $0            ;Analog tape input lockout
                                               ; (This input can't be selected as tape/mon source).
                                               ;Applies to Sig+8 only. 

f_av_links:
;                                 D1  D2  D3  D4  D5  D6
                        dc.b     $81,  3,  3,  3,  3,$82   ;Digital links (1=C1, $81=S1)

;                                 A1  A2  A3  A4  A5  A6
                        dc.b     $82,  3,  3,  3,  3,  3   ;Analog links  (1=C1, $81=S1)

;                                 A7  A8  A9
                        dc.b       3,  3,$81               ;Analog Pass-thru links  (1=C1, $81=S1)

f_LF_dst:               dc.b     30            ;Default speaker distances in 0.1 meters,
f_RF_dst:               dc.b     30            ; for Reference Cinema layout.
f_LS_dst:               dc.b     15            ;Make ES dist = av. LS, RS.
f_RS_dst:               dc.b     15            ;Make SL dist = SR dist.
f_CT_dst:               dc.b     25            ;Cinema 7.1 LS(dipole), RS(dipole) are
f_SR_dst:               dc.b     25            ; same as ES-L, ES-R (because non-critical).
                                               ;Cinema 7.1 ES-L, ES-R are same dist as 
                                               ; Ref. Cinema LS, RS.

f_bright_level:         dc.b     0             ;Default VFD display brightness (not currently used)

f_vertical_enhancer:    dc.b     $0            ;Default vertical enhancer = off.


 IFEQ brand-1        ;EAD brand.

;                                D1 D2 D3 D4 D5 D6
f_dig_desig:            dc.b     23,12, 0, 0, 0,19   ;Digital input designators.

;                                A1 A2 A3 A4 A5 A6
f_ana_desig:            dc.b     50,45, 0, 0, 0, 0   ;Analog (A-to-D) input designators.

;                                A7 A8 A9
                        dc.b      0, 0,49            ;Anlg pass-through designators.

 ENDC
 IFEQ brand-2                              ;Legacy brand (which model?)

;                                D1 D2 D3 D4 D5 D6
f_dig_desig:            dc.b     23,12, 0, 0, 0,19   ;Digital input designators.

;                                A1 A2 A3 A4 A5 A6
f_ana_desig:            dc.b     50,45, 0, 0, 0, 0   ;Analog (A-to-D) input designators.

;                                A7 A8 A9
                        dc.b      0, 0,49            ;Anlg pass-through designators.

 ENDC
 IFEQ brand-3                              ;SimAudio brand (Ovation-8 only)

;                                D1 D2 D3 D4 D5 D6
f_dig_desig:            dc.b     23,12, 0, 0, 0,19   ;Digital input designators.

;                                A1 A2 A3 A4 A5 A6
f_ana_desig:            dc.b     50,45, 0, 0, 0, 0   ;Analog (A-to-D) input designators.

;                                A7 A8 A9
                        dc.b     22, 0, 0            ;Anlg pass-through designators.

 ENDC




f_ana_6dB:              dc.b     %00000000     ;No analog input -6 dB attenuation.

f_cold_def_end:

;%%% Global (temporary, stored in RAM, de-asserted on standby)
;HF-EQ Y/N, Late-Night off/low/med/high, Theater mode Y/N, Screen up/down.

;** End of default parameters.

