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
;   RS_data.i
;
;*********************************************************************
;*********************************************************************
;*
;*      RS-232 control codes
;*
;*********************************************************************
;*********************************************************************

        XDEF    rs_codes,rs_codes_end

rs_codes:
        dc.b    "u",k_vup                       ;Side column
        dc.b    "d",k_vdn
        dc.b    "!",k_tm_sto
        dc.b    "=",k_tm_rcl
        dc.b    "U",k_tm_du
        dc.b    "D",k_tm_dd
        dc.b    "+",k_tms_du
        dc.b    "-",k_tms_dd

        dc.b    "1",k_1                         ;TM screen numbers
        dc.b    "2",k_2
        dc.b    "3",k_3
        dc.b    "4",k_4
        dc.b    "5",k_5
        dc.b    "6",k_6
        dc.b    "7",k_surr
        dc.b    "8",k_mat
        dc.b    "9",k_mono
        dc.b    "0",k_ster

        dc.b    "F",k_F
        dc.b    "E",k_enter

        dc.b    "A",k_anlg                      ;TM screen main control buttons
        dc.b    "T",k_tape
        dc.b    "V",k_video
        dc.b    "Q",k_HFEQ

        dc.b    "s",k_scrn
        dc.b    "#",k_link
        dc.b    '"',k_mute

        dc.b    "L",k_LF                        ;TMS screen numbers
        dc.b    "C",k_CTR
        dc.b    "R",k_RF
        dc.b    "l",k_LS
        dc.b    "S",k_SUB
        dc.b    "r",k_RS
        dc.b    "e",k_exit

        dc.b    "a",k_adjust                    ;TMS screen main control
        dc.b    "n",k_noise_seq
        dc.b    "$",k_stat_noise
        dc.b    "*",k_auto_setup
        dc.b    "@",k_auto_delay
        dc.b    "X",k_x_over
        dc.b    "O",k_roll_off

        dc.b    ")",k_pwr_off                   ;Extra ON-OFF commands.
        dc.b    "(",k_pwr_on

        dc.b    "[",k_v_enh_on
        dc.b    "]",k_v_enh_off

        dc.b    "{",k_HFEQ_on
        dc.b    "}",k_HFEQ_off

        dc.b    "h",k_LN_off
        dc.b    "i",k_LN_low
        dc.b    "j",k_LN_med
        dc.b    "k",k_LN_high

        dc.b    "_",k_scrn_dn
        dc.b    "^",k_scrn_up

        dc.b    "M",k_mute_on
        dc.b    "m",k_mute_off

;        dc.b    "B",k_bright

        dc.b    "?",k_display           ;Followed by nn = 01 to 17.

        dc.b    "~",k_ref.cinema
        dc.b    "b",k_cinema71

        dc.b    "Y",k_ES_on             ;For Ref. Cinema only
        dc.b    "Z",k_ES_off            ;For Ref. Cinema only

        dc.b    "G",k_movie             ;For Cinema 7.1 only
        dc.b    "g",k_music             ;For Cinema 7.1 only

        dc.b    "p",k_party_on
        dc.b    "o",k_party_off

        dc.b    ">",k_next
        dc.b    "<",k_prev

;
;IMPORTANT NOTE:
;
; The toggle commands Power, V_Enh, LateNight, Balanced are not
; deterministic unless the current state of the machine is known.
; This is further complicated by the property of the V_Enh, LateNight,
; and Balanced commands that they only flash up the relevant info
; screen the first time that they are pressed, unless you happen to be
; in this screen beforehand. In other words these commands behave
; differently depending on which screen is showing.
;
; We therefore strongly recommned that the followinge RS-232 commands
; not be used for automated control, but only in situations that
; essentially duplicate the existing hand-held remote used within sight
; of the TheaterMaster's LCD screen.
;
        dc.b    "P",k_pwr
        dc.b    "v",k_v_enh          
        dc.b    "N",k_LN            
        dc.b    "c",k_spkr_cfg                               
 
 
rs_codes_end:
        dc.b   1
