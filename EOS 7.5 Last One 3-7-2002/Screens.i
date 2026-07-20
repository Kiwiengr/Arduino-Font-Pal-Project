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
;   Screens.i 
;
;****************************************
;*
;*    Display Screens Include File
;*
;****************************************
 
screens:	equ	1

        XDEF spaces,dB,dot_dB,neg_dB,neg_dB2
        XDEF no_lock_screen,Stereo,Surround,Matrix,Mono
        XDEF channel_8_names,channel_6_names,channel_2_names
        XDEF HDCD,HFEQ,ESon,MusicON,PartyON,AES_sign,data_sign,v_enh_sign
        XDEF ln_high_sign,ln_med_sign,ln_low_sign,ln_off_sign
        XDEF xover_sym,sml_kick,lrg_kick,Buef_screen
        XDEF Spkr_cfg_RefCinema,Spkr_cfg_Cinema71,anlg_passthru_NA
        XDEF full_horiz_bar,left_horiz_bar1,left_horiz_bar2       
        XDEF emph_sign,freq_48,freq_32,V_sign,C_sign,P_sign
        XDEF daisies,versions_screen_A,versions_screen_B
        XDEF special_test_screen,analog_passthru,analog_daisies
        XDEF spkrs_rev,spkrs_norm,dts_memo,dts_5_1,dts_stereo
        XDEF ir_learn_screen,noise_seq_screen,static_nse_screen,no_lock_dts
        XDEF MPEG_stereo,MPEG_ProL,auto_s_unavailable_screen
        XDEF Anlg_inp_atten,System_config,Features_status
        XDEF PAV_links,DAV_links,AAV_links,Dig_inp_desig,input_data_freq
        XDEF Anlg_inp_desig,IR_test,rs232_ok,rs232_error,ir_tx_error,ir_tx_okay
        XDEF AnlgPT_inp_desig,deselect,SPL_meter,temp_dts_scrn,memory_vacant
        XDEF dolby_dig_blurb,selection_to_blurb,auto_s_err_screen,auto_d_err_screen
        XDEF clippage_star,clip_colon,auto_setup_screen,auto_delay_screen
        XDEF nl_ster,nl_surr,nl_matr,nl_mono,temp_mpeg_scrn,no_lock_mpeg
        XDEF MPEG_matrix,MPEG_mono,no_lock_ac3,clip_block
        XDEF sys_cfg_tdts,sys_cfg_tmpg,sys_cfg_tac3,input_data_khz
        XDEF SM_down_screen_1,SM_down_screen_2,dts_n_a,freq_44,freq_nolk
        XDEF dolby_20_prol,subs0_sign,subs1R_sign,subs2_sign
        XDEF Stdby_dots,Into_Stdby,sub1_sign,sub0_sign,movie_sign,music_sign
        XDEF Standby_scrn,VFD_test_1,VFD_test_2,ES_off_sign
        XDEF special_single_screen,special_bal_screen



spaces: dc.b     ' |'
        dc.b     ' '

dB:     dc.b     'dB|'
        dc.b     '  '

dot_dB: dc.b     '.|'
        dc.b     ' '

neg_dB: dc.b     '_|'        ;Used by Big Nums.
        dc.b     ' '

neg_dB2:
        dc.b     '-|'
        dc.b     ' '

clippage_star:
        dc.b     '*|'
        dc.b     ' '

clip_colon:
        dc.b     ':|'
        dc.b     ' '

clip_block:
        dc.b     $ff,'|'
        dc.b     ' '

sml_kick:
        dc.b     ':k|'
        dc.b     'SS'

lrg_kick:
        dc.b     ':K|'
        dc.b     'SS'

xover_sym:
        dc.b     'x|'
        dc.b     ' '


input_data_freq:
        dc.b     'fs:|'
        dc.b     ' S '        

input_data_khz:
        dc.b     'kHz|'
        dc.b     'FFF'

;balance:
;        dc.b     'Bal|'
;        dc.b     '   '

emph_sign:
        dc.b     'Emph.|'
        dc.b     '  L  '

freq_44:
        dc.b     '44.1|'
        dc.b     '    '

freq_48:
        dc.b     '48.0|'
        dc.b     '    '

freq_32:
        dc.b     '32.0|'
        dc.b     '    '

freq_nolk:
        dc.b     '       |'
        dc.b     '       '

V_sign:                      ;Validity flag
        dc.b     'V|'
        dc.b     ' '

C_sign:                      ;Confidence flag
        dc.b     'C|'
        dc.b     ' '

P_sign:                      ;Parity flag
        dc.b     'P|'
        dc.b     ' '

AES_sign:                    ;AES format detected
        dc.b     'AES|'
        dc.b     '   '

data_sign:                   ;Non-PCM audio data detected
        dc.b     'Data|'
        dc.b     '    '


full_horiz_bar:
        dc.b     'c|'
        dc.b     '='

left_horiz_bar1:
        dc.b     'a|'
        dc.b     '='

left_horiz_bar2: 
        dc.b     'b|'
        dc.b     '='

v_enh_sign:
        dc.b     'V-Enh|'
        dc.b     '     '

ln_high_sign:
        dc.b     'High|'
        dc.b     '  L '

ln_med_sign:
        dc.b     'Med|'
        dc.b     '   '

ln_low_sign:
        dc.b     'Low|'
        dc.b     '   '

ln_off_sign:
        dc.b     'Off|'
        dc.b     '   '

dts_memo:
        dc.b     'dts|'
        dc.b     'lll'

     IFEQ    brand-1          ;EAD

ir_learn_screen:
        dc.b     '["IR Program mode""]|'
        dc.b     'SS      L        SSS'
        dc.b     '{Power-down=to=exit}|'
        dc.b     'S          S  S    S'

noise_seq_screen:
        dc.b     '[""""""Noise"""""""]|'   
        dc.b     'SSSSSSS     SSSSSSSS'
        dc.b     '{====Sequencer=====}|'
        dc.b     'SSSSS  L      SSSSSS'

static_nse_screen:
        dc.b     '["""Static Noise"""]|'
        dc.b     'SSSS            SSSS'
        dc.b     '{====Generator=====}|'
        dc.b     'SSSSS         SSSSSS'

auto_setup_screen:
        dc.b     '[""""Auto Setup""""]|'
        dc.b     'SSSSS         LSSSSS'
        dc.b     '{=======mode=======}|'
        dc.b     'SSSSSSSS    SSSSSSSS'

auto_s_err_screen:
        dc.b     '  Auto Setup Error  |'              
        dc.b     '           L        '
        dc.b     '<Please insert mic!>|'
        dc.b     '                    '

auto_s_unavailable_screen:
        dc.b     'Error: No Cinema 7.1|'              
        dc.b     '                    '
        dc.b     'Auto Setup procedure|'
        dc.b     '         L L        '

auto_delay_screen:
        dc.b     '[""""Auto Delay""""]|'
        dc.b     'SSSSS         LSSSSS'
        dc.b     '{=======mode=======}|'
        dc.b     'SSSSSSSS    SSSSSSSS'

     ENDC   
     IFEQ    brand-2          ;Legacy

ir_learn_screen:
        dc.b     '  IR Program mode   |'
        dc.b     '        L           '
        dc.b     ' Power-down to exit |'
        dc.b     '                    '

noise_seq_screen:
        dc.b     '       Noise        |'   
        dc.b     '                    '
        dc.b     '     Sequencer      |'
        dc.b     '       L            '

static_nse_screen:
        dc.b     '    Static Noise    |'
        dc.b     '                    '
        dc.b     '     Generator      |'
        dc.b     '                    '

auto_setup_screen:
        dc.b     '     Auto Setup     |'
        dc.b     '              L     '
        dc.b     '        mode        |'
        dc.b     '                    '

auto_s_err_screen:
        dc.b     '  Auto Setup Error  |'              
        dc.b     '           L        '
        dc.b     '<Please insert mic!>|'
        dc.b     '                    '

auto_s_unavailable_screen:
        dc.b     'Error:No 7.1-channel|'              
        dc.b     '                    '
        dc.b     'Auto Setup procedure|'
        dc.b     '         L L        '

auto_delay_screen:
        dc.b     '   Auto Delay mode  |'
        dc.b     '            L       '
        dc.b     '                    |'
        dc.b     '                    '

     ENDC
     IFEQ    brand-3          ;SIMAudio

ir_learn_screen:
        dc.b     '  IR Program mode   |'
        dc.b     '        L           '
        dc.b     ' Power-down to exit |'
        dc.b     '                    '

noise_seq_screen:
        dc.b     '       Noise        |'   
        dc.b     '                    '
        dc.b     '     Sequencer      |'
        dc.b     '       L            '

static_nse_screen:
        dc.b     '    Static Noise    |'
        dc.b     '                    '
        dc.b     '     Generator      |'
        dc.b     '                    '

auto_setup_screen:
        dc.b     '     Auto Setup     |'
        dc.b     '              L     '
        dc.b     '        mode        |'
        dc.b     '                    '

auto_s_err_screen:
        dc.b     '  Auto Setup Error  |'              
        dc.b     '           L        '
        dc.b     '<Please insert mic!>|'
        dc.b     '                    '

auto_s_unavailable_screen:
        dc.b     'Error:No Theater 7.1|'              
        dc.b     '                    '
        dc.b     'Auto Setup procedure|'
        dc.b     '         L L        '

auto_delay_screen:
        dc.b     '   Auto Delay mode  |'
        dc.b     '            L       '
        dc.b     '                    |'
        dc.b     '                    '

     ENDC

auto_d_err_screen:
        dc.b     '  Auto Delay Error  |'
        dc.b     '           L        '
        dc.b     '<Please insert mic!>|'
        dc.b     '                    '

special_test_screen:
        dc.b     ' Special Test Mode. |'              
        dc.b     '  L                 '
        dc.b     ' LF ',$7e,' 7 ch''s (& ES) |'
        dc.b     '                    '

special_single_screen:
        dc.b     'All ch''s Single End.|'              
        dc.b     '            L       '
        dc.b     'Use F-9-3 to restore|'
        dc.b     '                    '

special_bal_screen:
        dc.b     ' All ch''s Balanced. |'              
        dc.b     '                    '
        dc.b     'Use F-9-3 to restore|'
        dc.b     '                    '

temp_dts_scrn:
        dc.b     '   dts dedication   |'           ;Don't change the layout of this screen
        dc.b     '   lll              '            ; because it needs to have 'ed' at pos'n 8
        dc.b     '        on D        |'           ; for eos_10.s main_loop5_big:
        dc.b     '                    '

temp_mpeg_scrn:
        dc.b     '   MPEG dedication  |'           ;Don't change the layout of this screen
        dc.b     '                    '            ; because it needs to have 'de' at pos'n 8
        dc.b     '        on D        |'           ; for eos_10.s main_loop5_big:
        dc.b     '                    '

analog_passthru:
        dc.b     'Analog Pass-Thru|'
        dc.b     '     L          '

anlg_passthru_NA:
        dc.b     'Anlg PassThr N/A|'
        dc.b     '   L            '

no_lock_screen:
        dc.b     '(No Lock)       |'
        dc.b     '                '

no_lock_dts:
        dc.b     '(No Lock)    dts|'
        dc.b     '             lll'

no_lock_mpeg:
        dc.b     '(No Lock)   MPEG|'
        dc.b     '                '

no_lock_ac3: 
        dc.b     '(No Lock)   AC-3|'
        dc.b     '                '

nl_ster:
        dc.b     ':Stereo|'
        dc.b     '       '

nl_surr:
        dc.b     ':Pro L |'
        dc.b     '       '

nl_matr:
        dc.b     ':Matrix|'
        dc.b     '       '

nl_mono:
        dc.b     ':Mono  |'
        dc.b     '       '

Stereo:
        dc.b     'Stereo          |'
        dc.b     '                '

Surround:
        dc.b     ')( Pro Logic    |'
        dc.b     'll              '

Matrix:
        dc.b     'Matrix          |'
        dc.b     '                '

Mono:
        dc.b     'Enhanced Mono   |'
        dc.b     '                '

dts_5_1:
        dc.b     'dts 5.1         |'
        dc.b     'lll             '

dts_stereo:
        dc.b     'dts:Stereo DnMx |'            ;User-override.
        dc.b     'lll             '

dts_n_a:
        dc.b     'dts 5.1:N/A     |'            ;User-override not available.
        dc.b     'lll             '

MPEG_stereo:
        dc.b     'MPEG2 Stereo    |'
        dc.b     '                '

MPEG_ProL:
        dc.b     'MPEG2:Pro Logic |'            ;User-override.
        dc.b     '            L   '

MPEG_matrix:
        dc.b     'MPEG2:Matrix    |'            ;User-override.
        dc.b     '                '

MPEG_mono:
        dc.b     'MPEG2:Enh Mono  |'            ;User-override.
        dc.b     '                '

dolby_dig_blurb:
        dc.b     ')( Digital      |'
        dc.b     'll              '

dolby_20_prol:
        dc.b     ')( Dig/Pro Logic|'            ;Note: "\" is Japanese "Yen"
        dc.b     'll              '             ;We don't have a spare custom

HDCD:
        dc.b     'HDCD|'                        ;HDCD icon.
        dc.b     'llll'

HFEQ:
        dc.b     $96,'|'                        ;CinEQ icon (Diamond).
        dc.b     ' '

ESon:
        dc.b     $85,'|'                        ;Bold 'E' icon indicates that ES speaker is enabled.
        dc.b     ' '

MusicON:
        dc.b     $19,'|'                        ;Musical 'Note' icon indicates Music mode for Cinema 7.1.
        dc.b     ' '

PartyON:
        dc.b     'P|'                           ;Party mode icon indicates that Party mode is engaged..
        dc.b     'B'

deselect:
        dc.b     '____|'
        dc.b     '    '

channel_6_names:
        dc.b     ' LF CR RF  LS SB RS '         ;Labels for Cinema 7.1 Music mode VU meter:

channel_8_names:
        dc.b     'LF CR RF SB LS ES RS'         ;Labels for Ref.Cinema & Cinema 7.1 Movie mode VU meter.

channel_2_names:
        dc.b     '   LEFT      RIGHT  '

Buef_screen:
        dc.b     'Buefuss is alive!!! |'
        dc.b     '                    '

     IFEQ    brand-1         ;EAD

SM_down_screen_1:
        dc.b     '["""SwitchMaster"""]|'        
        dc.b     'SSSS            SSSS'
        dc.b     '{====Downloader====}|'
        dc.b     'SSSSS          SSSSS'

     ELSEC                   ;Legacy/Simaudio

SM_down_screen_1:
        dc.b     '    SwitchMaster    |'        
        dc.b     '                    '
        dc.b     '     Downloader     |'
        dc.b     '                    '

     ENDC

SM_down_screen_2:
        dc.b     ' Check S/M set-up   |'
        dc.b     '                L   '
        dc.b     '  Press any key.... |'
        dc.b     '          L   L     '
        

daisies:
;* Without LFE:

        dc.b     '242|'                         ;3/2/0 daisy 0                        
        dc.b     'CCC'
        dc.b     '1d1|'
        dc.b     'CCC'

        dc.b     '2c2|'                         ;2/P/0 daisy 1
        dc.b     'CCC'
        dc.b     'a5a|'
        dc.b     'CCC'

        dc.b     '2c2|'                         ;2/0/0 daisy 2
        dc.b     'CCC'
        dc.b     'ada|'
        dc.b     'CCC'

        dc.b     '242|'                         ;3/1/0 daisy 3
        dc.b     'CCC'
        dc.b     'a5a|'
        dc.b     'CCC'

        dc.b     '242|'                         ;3/0/0 daisy 4
        dc.b     'CCC'
        dc.b     'ada|'
        dc.b     'CCC'

        dc.b     '2c2|'                         ;2/2/0 daisy 5
        dc.b     'CCC'
        dc.b     '1d1|'
        dc.b     'CCC'

        dc.b     'b4b|'                         ;1/0/0 daisy 6
        dc.b     'CCC'
        dc.b     'ada|'
        dc.b     'CCC'

        dc.b     'bcb|'                         ;0/0/0 daisy 7 (no lock)
        dc.b     'CCC'
        dc.b     'ada|'
        dc.b     'CCC'


;* With LFE:

        dc.b     '232|'                         ;3/2/.1 daisy 8
        dc.b     'CCC'
        dc.b     '1e1|'
        dc.b     'CCC'

        dc.b     '2f2|'                         ;2/P/.1 daisy 9 
        dc.b     'CCC'
        dc.b     'a6a|'
        dc.b     'CCC'

        dc.b     '2f2|'                         ;2/0/.1 daisy 10
        dc.b     'CCC'
        dc.b     'aea|'
        dc.b     'CCC'

        dc.b     '232|'                         ;3/1/.1 daisy 11
        dc.b     'CCC'
        dc.b     'a6a|'
        dc.b     'CCC'

        dc.b     '232|'                         ;3/0/.1 daisy 12
        dc.b     'CCC'
        dc.b     'aea|'
        dc.b     'CCC'

        dc.b     '2f2|'                         ;2/2/.1 daisy 13
        dc.b     'CCC'
        dc.b     '1e1|'
        dc.b     'CCC'

        dc.b     'b3b|'                         ;1/0/.1 daisy 14
        dc.b     'CCC'
        dc.b     'aea|'
        dc.b     'CCC'

        dc.b     '   |'                         ;0/0/0 daisy 15 (for no lock mute)
        dc.b     '   '
        dc.b     '   |'
        dc.b     '   '


spkrs_rev:
        dc.b     'LF|'                          ;Ref.Cinema & 7.1 Movie
        dc.b     'rr'
        dc.b     'RF|'
        dc.b     'rr'
        dc.b     'LS|'
        dc.b     'rr'
        dc.b     'RS|'
        dc.b     'rr'
        dc.b     'CR|'
        dc.b     'rr'
        dc.b     'SB|'
        dc.b     'rr'

        dc.b     'LF|'                          ;Use spkrs_rev + 30 for 7.1 Music
        dc.b     'rr'
        dc.b     'RF|'
        dc.b     'rr'
        dc.b     'L',$19,'|'                    ;L-reversed note (refers to LS spkr)
        dc.b     'r',' '
        dc.b     'R',$19,'|'                    ;R-reversed note (refers to RS spkr)
        dc.b     'r',' ' 
        dc.b     'CR|'
        dc.b     'rr'
        dc.b     'SB|'
        dc.b     'rr'

spkrs_norm:
        dc.b     'LF|'                          ;Ref.Cinema & 7.1 Movie
        dc.b     'cc'
        dc.b     'RF|'
        dc.b     'cc'
        dc.b     'Ls|'                          
        dc.b     'c '
        dc.b     'Rs|'
        dc.b     'c '
        dc.b     'cR|'
        dc.b     ' c'
        dc.b     'sB|'
        dc.b     ' c'

        dc.b     'LF|'                          ;Use spkrs_norm + 30 for 7.1 Music
        dc.b     'cc'
        dc.b     'RF|'
        dc.b     'cc'
        dc.b     'L',$19,'|'                    ;L-note (refers to LS spkr)
        dc.b     'c',' '
        dc.b     'R',$19,'|'                    ;R-note (refers to RS spkr)
        dc.b     'c',' '                
        dc.b     'cR|'
        dc.b     ' c'
        dc.b     'sB|'
        dc.b     ' c'

SPL_meter:
        dc.b     'SPL:  Ref!     .  dB|'  
        dc.b     '         =          '    
        

analog_daisies:

        dc.b     ' 6 |'                         ;6-channel Analog Pass-thru
        dc.b     '   '

        dc.b     ' 2 |'                         ;2-channel Analog Pass-thru
        dc.b     '   '

        dc.b     ' 8 |'                         ;8-channel Analog Pass-thru
        dc.b     '   '      

        dc.b     'xyz|'                         ;Bottom part of pass-thru "daisy"
        dc.b     'CCC'

        dc.b     'uvw|'                         ;Mute pattern for bottom part of p/t "daisy"
        dc.b     'CCC'


;Main screen is done elsewhere.

;Output VU meter is done elsewhere.

;Speaker Adjustment screen is done elsewhere.

;Bass Management screen is done elsewhere.

;Speaker Distances screen is done elsewhere.


; EAD:           +--------------------+
;                |<-Config: REF.CINEMA|             "Reference Cinema" layout.
;                |ES+6.5dB    Subs:> <|
;                +--------------------+
;                          or
;                +--------------------+
;                |<-Config: CINEMA 7.1|             "Movie" mode.
;                |Movie ES+6.5dB Sub:<|
;                +--------------------+
;                          or
;                +--------------------+
;                |<-Config: CINEMA 7.1|             "Music" mode.
;                |Musicd         Sub:<|
;                +--------------------+
;
;
; SIMAUDIO:      +--------------------+
;                |<-Config:REF.THEATER|             "Reference Cinema" layout.
;                |ES+6.5dB    Subs:> <|
;                +--------------------+
;                          or
;                +--------------------+
;                |<-Config:THEATER 7.1|             "Movie" mode.
;                |Movie ES+6.5dB Sub:<|
;                +--------------------+
;                          or
;                +--------------------+
;                |<-Config:THEATER 7.1|             "Music" mode.
;                |Musicd         Sub:<|
;                +--------------------+
;
;
; LEGACY AUDIO:  +--------------------+
;                |<-Confg:THEATER MODE|            "Reference Cinema" layout.
;                |ES+6.5dB    Subs:> <|
;                +--------------------+
;                          or
;                +--------------------+
;                |<-Confg: AMBIENT 7.1|             "Movie" mode.
;                |Movie ES+6.5dB Sub:<|
;                +--------------------+
;                          or
;                +--------------------+
;                |<-Config:THEATER 7.1|             "Music" mode.
;                |Musicd         Sub:<|
;                +--------------------+


 IFEQ brand-1        ;EAD brand.

Spkr_cfg_RefCinema:
        dc.b     'K-Config: REF.CINEMA|'            ;Reference Cinema Speaker Configuration.
        dc.b     'S      L            '
        dc.b     '            Subs:   |'
        dc.b     '                    '

Spkr_cfg_Cinema71:
        dc.b     'K-Config: CINEMA 7.1|'            ;Cinema 7.1 Speaker Configuration.
        dc.b     'S      L            '
        dc.b     '               Sub: |'
        dc.b     '                    '

 ENDC
 IFEQ brand-2                              ;Legacy NexStep2 (Ovation-8 only)

Spkr_cfg_RefCinema:                   
        dc.b     'K-Confg: THEATER    |'            ;Reference Cinema Speaker Configuration.
        dc.b     'S     L             '
        dc.b     '            Subs:   |'
        dc.b     '                    '

Spkr_cfg_Cinema71:
        dc.b     'K-Confg: AMBIENT 7.1|'            ;Cinema 7.1 Speaker Configuration.
        dc.b     'S     L             '
        dc.b     '               Sub: |'
        dc.b     '                    '

 ENDC
 IFEQ brand-3                              ;SimAudio brand (Ovation-8 only)

Spkr_cfg_RefCinema:
        dc.b     'K-Config:REF.THEATER|'            ;Reference Cinema Speaker Configuration.
        dc.b     'S      L            '
        dc.b     '            Subs:   |'
        dc.b     '                    '

Spkr_cfg_Cinema71:
        dc.b     'K-Config:THEATER 7.1|'            ;Cinema 7.1 Speaker Configuration.
        dc.b     'S      L            '
        dc.b     '               Sub: |'
        dc.b     '                    '

 ENDC

ES_off_sign:
        dc.b     $85,'S ____ |'
        dc.b     ' ','       '

subs0_sign:
        dc.b     '___|'
        dc.b     '   '

subs1R_sign:
        dc.b     'K=R|'
        dc.b     'S  '

subs2_sign:
        dc.b     'K S|'                             ;Reversed subwoofer icon.
        dc.b     'S S'

sub0_sign:
        dc.b     '_|'                               ;Cinema 7.1 only.
        dc.b     ' '

sub1_sign:
        dc.b     'K|'                               ;Cinema 7.1 only.
        dc.b     'S'

movie_sign:
        dc.b     'Movie |'                          ;Cinema 7.1 only.
        dc.b     '      '

music_sign:
        dc.b     'Music',$19,'|'                    ;Cinema 7.1 only.
        dc.b     '      '


Anlg_inp_atten:

     IFEQ    name-3    ;SIGNATURE+8

        dc.b     'A1 A2 A3 A4 A5 A6   |'
        dc.b     '                    '
        dc.b     '-0 -0 -0 -0 -0 -0 dB|'
        dc.b     '                    '

     ELSEC             ;OVATION-8 or SIGNATURE-8

        dc.b     'A1 A2 A3            |'
        dc.b     '                    '
        dc.b     '-0 -0 -0 dB         |'
        dc.b     '                    '

     ENDC

System_config:

;Signature-8a model:
;                +--------------------+
;                |ES+7 fo:100Hz Tdts=2|   <--Future feature: offset ES volume
;                |-36oC LkOut: A=0 D=0|      in Reference Cinema layout.
;                +--------------------+
;
;Ovation-8 & Signature-8 models:
;                +--------------------+
;                |ES+7 fo:100Hz Tdts=2|   <--Future feature: offset ES volume
;                |-36oC  Lock Out: D=0|      in Reference Cinema layout.
;                +--------------------+

        dc.b     '     fo:   Hz       |'
        dc.b     '      F    FF       '

     IFEQ    name-3    ;SIGNATURE+8

        dc.b     '   oC LkOut: A=  D= |'
        dc.b     '   S                '

     ELSEC             ;OVATION-8

        dc.b     '   oC  Lock Out: D= |'
        dc.b     '   S                '

     ENDC


sys_cfg_tdts:
        dc.b    'Tdts=|'
        dc.b    ' lll '

sys_cfg_tmpg:
        dc.b    'tMPG=|'
        dc.b    '     '

sys_cfg_tac3:
        dc.b    'tAC3=|'
        dc.b    '     '


Features_status:

;                +--------------------+
;                |LN=High V-Enh  Mem=3|
;                |Screen^ D.Norm 31 dB|
;                +--------------------+

        dc.b     'LN=            Mem= |'
        dc.b     '                    '
        dc.b     'Screen  D.Norm    dB|'
        dc.b     '                    '

DAV_links:
        dc.b     ' D1 D2 D3  D4 D5 D6 |'
        dc.b     '                    '

AAV_links:

     IFEQ    name-3    ;SIGNATURE+8

        dc.b     ' A1 A2 A3  A4 A5 A6 |'   ;Signature has 6 analog inputs.
        dc.b     '                    '

     ELSEC             ;OVATION-8 or SIGNATURE-8

        dc.b     ' A1 A2 A3           |'   ;Enc/Ova have 3 analog inputs.
        dc.b     '                    '

     ENDC

PAV_links:
        dc.b     ' A7 A8 A9           |'   ;Pass-through analog inputs.
        dc.b     '                    '

Dig_inp_desig:
        dc.b     'D1     D2     D3    |'
        dc.b     '                    '
        dc.b     'D4     D5     D6    |'
        dc.b     '                    '

Anlg_inp_desig:
        dc.b     'A1     A2     A3    |'
        dc.b     '                    '

     IFEQ     name-3   ;SIGNATURE+8

        dc.b     'A4     A5     A6    |'
        dc.b     '                    '

     ELSEC             ;OVATION-8 or SIGNATURE-8

        dc.b     '                    |'
        dc.b     '                    '

     ENDC

AnlgPT_inp_desig:
        dc.b     'A7     A8     A9    |'
        dc.b     '                    '
        dc.b     '                    |'
        dc.b     '                    '

IR_test:       
        dc.b     'Remote Control Test |'   
        dc.b     '                    '   
        dc.b     '  [Press Any Key]   |'  
        dc.b     '           L   L    '

rs232_ok:
        dc.b     '  RS232 Tx/Rx okay! |'  
        dc.b     '                 L  '   

rs232_error:
        dc.b     '    RS232 error     |'  
        dc.b     '                   '   

ir_tx_okay:
        dc.b     '    IR Tx okay!     |'
        dc.b     '             L      '

ir_tx_error:
        dc.b     '    IR Tx error     |'
        dc.b     '                    '

VFD_test_1:
        dc.b     '["""""VFD TEST"""""]|'       
        dc.b     'SSSSSS        SSSSSS'
        dc.b     '{==================}|'
        dc.b     'SSSSSSSSSSSSSSSSSSSS'

VFD_test_2:
        dc.b     '                    |'   
        dc.b     'RRRRRRRRRRRRRRRRRRRR'
        dc.b     '                    |'
        dc.b     'RRRRRRRRRRRRRRRRRRRR'


     IFEQ    brand-1          ;EAD

Into_Stdby:
        dc.b     '["""""Entering"""""]|'       
        dc.b     'SSSSSS       LSSSSSS'
        dc.b     '{===Standby=Mode===}|'
        dc.b     'SSSS      LS    SSSS'

     ELSEC                    ;Legacy/Simaudio   

Into_Stdby:
        dc.b     '      Entering      |'       
        dc.b     '             L      '
        dc.b     '    Standby Mode    |'
        dc.b     '          L         '

     ENDC

Stdby_dots:
        dc.b     '         ab         |'         ;Standby dots prevent VFD burn-in of VFD!
        dc.b     '         SS         '
        dc.b     '         cd         |'
        dc.b     '         SS         '

versions_screen_A:
        dc.b     'CPU:     Z1:        |'
        dc.b     'RRR      RR         '
        dc.b     'DIP:     Z2:        |'
        dc.b     'RRR      RR         '

versions_screen_B:
        dc.b     'CS:     Z1E:        |'
        dc.b     'RR      RRR         '
        dc.b     '        Z2E:        |'
        dc.b     '        RRR         '


memory_vacant:
        dc.b     '   Memory Vacant    |'
        dc.b     '        L           '


selection_to_blurb:
        dc.b     ':N/A  '     ;#0              ;No override allowed.
        dc.b     ' Mono '     ;#1
        dc.b     ' Ster '     ;#2
        dc.b     ' 3/0  '     ;#3
        dc.b     ' 2/1  '     ;#4
        dc.b     ' 3/1  '     ;#5
        dc.b     ' 2/2  '     ;#6
        dc.b     ' 3/2  '     ;#7
        dc.b     ' Pro L'     ;#8
        dc.b     ':Ster '     ;#9
        dc.b     ':Mat  '     ;#10
        dc.b     ':E.Mon'     ;#11
        dc.b     ':Pro L'     ;#12
        dc.b     ' 5.0  '     ;#13
        dc.b     ' 5.1  '     ;#14


Standby_scrn:

 IFEQ brand-1        ;EAD brand.
    IFEQ name-3                            ;Signture+8 (aka Signature-8a)
       IFEQ alpha-1  ;Alpha Digital Technologies

        dc.b     '   TheaterMaster    |'
        dc.b     '   BBBBBBBBBBBBB    '
        dc.b     '   SIGNATURE--8a    |'
        dc.b     '                    '

       ELSEC

        dc.b     '     ABABABAB       |'
        dc.b     '     88000000       '
        dc.b     '     CDCDCDCDPro    |'
        dc.b     '     88000000       '

       ENDC
    ENDC
    IFEQ name-2                            ;Signature-8
       IFEQ alpha-1  ;Alpha Digital Technologies

        dc.b     '   TheaterMaster    |'
        dc.b     '   BBBBBBBBBBBBB    '
        dc.b     '    SIGNATURE-8     |'
        dc.b     '                    '

       ELSEC

        dc.b     '     ABABABAB       |'
        dc.b     '     88000000       '
        dc.b     '     CDCDCDCDPro    |'
        dc.b     '     88000000       '

       ENDC
    ENDC
    IFEQ name-1                            ;Ovation-8
       IFEQ alpha-1  ;Alpha Digital Technologies

        dc.b     '   TheaterMaster    |'
        dc.b     '                    '
        dc.b     '     Ovation-8      |'
        dc.b     '     BBBBBBB B      '

       ELSEC

        dc.b     '      ABABABAB      |'
        dc.b     '      88000000      '
        dc.b     '      CDCDCDCD      |'
        dc.b     '      88000000      '

       ENDC
    ENDC
 ENDC
 IFEQ brand-2                              ;Legacy NexStep2

        dc.b     '       LEGACY       |'
        dc.b     '                    '
        dc.b     '      NexStep2      |'
        dc.b     '      BBBBBBBS      '

 ENDC
 IFEQ brand-3                              ;SimAudio brand (Encore & Ovation only)
                                           ;NOTE: Later on, SimAudio want the Simaudio
                                           ;      string to blank out after 10 seconds.

    IFEQ model - 2                         ;"Ovation" style

        dc.b     '        MOON        |'
        dc.b     '                    '
        dc.b     '     Attraction     |'
        dc.b     '     BBBBBBBBBB     '

    ENDC
    IFEQ model - 1                         ;"Encore" style (possible future product)

        dc.b     '        MOON        |'
        dc.b     '                    '
        dc.b     '      Stargate      |'
        dc.b     '      BBBBBBBB      '

    ENDC
 ENDC


End_standby_scrn:

