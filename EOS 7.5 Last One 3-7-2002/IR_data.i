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
;   IR_data.i
;
;****************************************
;*
;*      Infra Red Data include file
;*
;****************************************

	XDEF  IR_codes_start,TM_page,TMS_page,Special_page,IR_codes_end
        XDEF  TM_learn,TMS_learn,Specials
        XDEF  learn_buts,learn_start,learn_tx,learn_repeat

;*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;*%%%%%%%%%%%%%%%%%%%%%%%%%%%    IR CODES    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        

TM_learn:
        dc.b "TM Learn :|"
        dc.b "         Z"

TMS_learn:
        dc.b "TMS Learn:|"
        dc.b "         Z"

Specials:
        dc.b "Specials :|"
        dc.b "         Z"


learn_buts:                     
        dc.b "o-~Next, oo-~Prev   |"
        dc.b "ZZZ      ZZZZ       "

learn_start:
        dc.b "o-~Start IR...      |"
        dc.b "ZZZ                 "

learn_tx:
        dc.b " .....Sending.....  |"
        dc.b "            L       "

learn_repeat:
        dc.b "o-~Repeat IR...     |"
        dc.b "ZZZ                 "


IR_codes_start:                          

        dc.b 1                         ; start of code table
                                     
TM_page:        
        dc.b 1, k_pwr
        dc.b "POWER|"
        dc.b "     "
        
        dc.b 1, k_vup
        dc.b "VOLUME ^|"
        dc.b "       Z"

        dc.b 1, k_vdn
        dc.b "VOLUME v |"
        dc.b "       Z "
        
        dc.b 1, k_tm_sto
        dc.b "TM STO|"
        dc.b "      "

        dc.b 1, k_tm_rcl
        dc.b "TM RCL|"
        dc.b "      "
        
        dc.b 1, k_tm_du
        dc.b "Display ^|"
        dc.b "   L  L Z"

        dc.b 1, k_tm_dd
        dc.b "Display v|"
        dc.b "   L  L Z"
        
        dc.b 1, k_1
        dc.b "1|"
        dc.b " "

        dc.b 1, k_2
        dc.b "2|"
        dc.b " "

        dc.b 1, k_3
        dc.b "3|"
        dc.b " "

        dc.b 1, k_4
        dc.b "4|"
        dc.b " "
        
        dc.b 1, k_5
        dc.b "5|"
        dc.b " "
        
        dc.b 1, k_6
        dc.b "6|"
        dc.b " "
        
        dc.b 1, k_7
        dc.b "Surr/7|"
        dc.b "      "
        
        dc.b 1, k_8
        dc.b "Matrix/8|"
        dc.b "        "
        
        dc.b 1, k_9
        dc.b "Mono/9|"
        dc.b "      "

        dc.b 1, k_F
        dc.b "F|"
        dc.b " "

        dc.b 1, k_0
        dc.b "Stereo/0|"
        dc.b "        "

        dc.b 1, k_enter
        dc.b "ENTER|"
        dc.b "     "
        
        dc.b 1, k_anlg
        dc.b "Analog|"
        dc.b "     L"

        dc.b 1, k_tape
        dc.b "Tape/Mon|"
        dc.b "  L     "

        dc.b 1, k_video
        dc.b "Video|"
        dc.b "     "

        dc.b 1, k_v_enh
        dc.b "V-Enh|"
        dc.b "     "

        dc.b 1, k_HFEQ
        dc.b "CinEQ|"
        dc.b "     "

        dc.b 1,k_LN
        dc.b "LateNight|"
        dc.b "      L  "

        dc.b 1, k_scrn
        dc.b "Screen|"
        dc.b "      "

        dc.b 1, k_link
        dc.b "Link A/V|"
        dc.b "        "

        dc.b 1, k_mute
        dc.b "MUTE|"
        dc.b "    "

TMS_page:
        dc.b 1, k_pwr
        dc.b "POWER|"
        dc.b "     "
        
        dc.b 1, k_vup
        dc.b "VOLUME ^|"
        dc.b "       Z"

        dc.b 1, k_vdn
        dc.b "VOLUME v|"
        dc.b "       Z"
        
        dc.b 1, k_tms_sto
        dc.b "TMS STO|"
        dc.b "       "

        dc.b 1, k_tms_rcl
        dc.b "TMS RCL|"
        dc.b "       "
        
        dc.b 1, k_tms_du
        dc.b "DISPLAY ^|"
        dc.b "        Z"

        dc.b 1, k_tms_dd
        dc.b "DISPLAY v|"
        dc.b "        Z"
        
        dc.b 1, ks_1
        dc.b "LF/1|"
        dc.b "    "

        dc.b 1, ks_2
        dc.b "CTR/2|"
        dc.b "     "

        dc.b 1, ks_3
        dc.b "RF/3|"
        dc.b "    "

        dc.b 1, ks_4
        dc.b "LS/4|"
        dc.b "    "
        
        dc.b 1, ks_5
        dc.b "SUB/5|"
        dc.b "     "
        
        dc.b 1, ks_6
        dc.b "RS/6|"
        dc.b "    "
        
        dc.b 1, ks_7
        dc.b "7|"
        dc.b " "
        
        dc.b 1, ks_8
        dc.b "8|"
        dc.b " "
        
        dc.b 1, ks_9
        dc.b "9|"
        dc.b " "

        dc.b 1, k_F
        dc.b "F|"
        dc.b " "

        dc.b 1, ks_0
        dc.b "0|"
        dc.b " "
        
        dc.b 1, k_exit
        dc.b "EXIT|"
        dc.b "    "
        
        dc.b 1, k_adjust
        dc.b "Adjust|"
        dc.b "  L   "

        dc.b 1, k_noise_seq
        dc.b "Noise Seq|"
        dc.b "        L"

        dc.b 1, k_stat_noise
        dc.b "Stc Noise|"
        dc.b "         "
        
        dc.b 1, k_auto_setup
        dc.b "Auto-Set|"
        dc.b "        "

        dc.b 1, k_auto_delay
        dc.b "Auto-Dly|"
        dc.b "       L"

        dc.b 1, k_spkr_cfg
        dc.b "Spkr Cfg|"
        dc.b " L     L"

        dc.b 1, k_x_over
        dc.b "Re-Dir|"
        dc.b "      "

        dc.b 1, k_roll_off
        dc.b "Roll-Off|"
        dc.b "        "

        dc.b 1, k_mute
        dc.b "MUTE|"
        dc.b "    "

Special_page:
        dc.b 1, k_pwr_on
        dc.b "POWER ON|"
        dc.b "        "

        dc.b 1, k_pwr_off
        dc.b "POWER OFF|"
        dc.b "         "

        dc.b 1, k_v_enh_on
        dc.b "V-Enh ON|"
        dc.b "        "

        dc.b 1, k_v_enh_off
        dc.b "V-Enh OFF|"
        dc.b "         "

        dc.b 1, k_HFEQ_on
        dc.b "CinEQ ON|"
        dc.b "        "

        dc.b 1, k_HFEQ_off
        dc.b "CinEQ OFF|"
        dc.b "         "

        dc.b 1, k_ES_on
        dc.b "ES ON|"
        dc.b "     "

        dc.b 1, k_ES_off
        dc.b "ES OFF|"
        dc.b "      "

        dc.b 1, k_party_on
        dc.b "Party ON|"
        dc.b "    L   "

        dc.b 1, k_party_off
        dc.b "Party OFF|"
        dc.b "    L    "

        dc.b 1, k_LN_off
        dc.b "Lt Nt OFF|"
        dc.b "         "

        dc.b 1, k_LN_low
        dc.b "Lt Nt LOW|"
        dc.b "         "

        dc.b 1, k_LN_med
        dc.b "Lt Nt MED|"
        dc.b "         "

        dc.b 1, k_LN_high
        dc.b "Lt Nt HI|"
        dc.b "        "

        dc.b 1, k_scrn_dn
        dc.b "Screen v|"
        dc.b "       Z"

        dc.b 1, k_scrn_up
        dc.b "Screen ^|"
        dc.b "       Z"

        dc.b 1, k_mute_on
        dc.b "MUTE ON|"
        dc.b "       "

        dc.b 1, k_mute_off
        dc.b "MUTE OFF|"
        dc.b "        "

;        dc.b 1, k_bright
;        dc.b "Bright|"
;        dc.b "   L  "

        dc.b 1, k_display
        dc.b "Display|"
        dc.b "   L  L"

        dc.b 1, k_ref.cinema
        dc.b "RefCinema|"
        dc.b "         "

        dc.b 1, k_cinema71
        dc.b "Cinema7.1|"
        dc.b "         "

        dc.b 1, k_movie
        dc.b "7.1 Movie|"
        dc.b "         "

        dc.b 1, k_music
        dc.b "7.1 Music|"
        dc.b "         "

        dc.b 1, k_next  
        dc.b "Next Inp|"
        dc.b "       L"

        dc.b 1, k_prev  
        dc.b "Prev Inp|"
        dc.b "       L"

;Deal with these later, as part of EOS MkII IR code make-over:
;       dc.b 1, k_Anlg_1
;       dc.b "Analog 1|"
;       dc.b "     L  "
;
;       dc.b 1, k_Anlg_2
;       dc.b "Analog 2|"
;       dc.b "     L  "
;
;       dc.b 1, k_Anlg_3
;       dc.b "Analog 3|"
;       dc.b "     L  "
;
;       dc.b 1, k_Anlg_4
;       dc.b "Analog 4|"
;       dc.b "     L  "
;
;       dc.b 1, k_Anlg_5
;       dc.b "Analog 5|"
;       dc.b "     L  "
;
;       dc.b 1, k_Anlg_6
;       dc.b "Analog 6|"
;       dc.b "     L  "
 
        dc.b 1, k_credits
        dc.b "Credits|"
        dc.b "       "

IR_codes_end:                          

        dc.b 1                         ; end of code table





