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
;   xrefs.i
;
;*****************************************************
;
; Eos10.s
	ifndef eos10_flag
        XREF  ic1_initialize,MSG1
	XREF  EOS_start,First_2_secs,Standby_mode,Main_loop
        XREF  IRQ_flag,IR_ready,two_press_timer,Buefuss_flag,TM_flag
        XREF  one_sec,two_secs,three_secs,rti_timer
        XREF  screen_num,ovcnt1,lat_ovcnt1,ovcnt2,frame,lamp_status
        XREF  screen_status1,screen_status2,features,cold_start,feats_ptr
        XREF  Long_features,main_loop1,main_ft_end_sby,the_temp
        XREF  J_Short_features,J_Long_features,main_ft_end_pre
        XREF  noise_seq_timer,flash_up,update_screen12,temp_cntr
        XREF  ir_test_flag,ir_test_count,theater,SPL_timer,slow_enc_timer
        XREF  zoran_cntr,auto_set_timer
        XREF  screen_status3,sticky_dts_ctr,err_star_ctr,clippage
        XREF  sticky_ac3_ctr,mpeg_err_ctr,VFD_time_out

	endc

; Initials.s
	ifndef initials_flag
	XREF  Initials
	endc

; Eos_com.s
	ifndef eoscom_flag
        XREF  display_scrn,Z_modes,Bar_None_Display
        XREF  Bar_volume,Bar2_Display,Bar6_Display,Bar8_Display
        XREF  init_4226_xtal,init_4226_pll,noisy_channels,rotate_noise
        XREF  do_ams,do_dms,unpack_vol,mute_all,unmute_all,curr_pass_mode
        XREF  SPL_display,display30,mute_on,mute_off,do_mute,undo_mute
        XREF  reset_38,WR_CS4226,RD_CS4226,mute_cmd,init_4PCMs
        XREF  spi_cmd_1,spi_cmd_2,CS3310_vol_imag,WR_CS3310s
        XREF  AC3_in_proc,rs_imag,locked,from_standby,into_standby
        XREF  cs0_imag,cs3_imag,fs_freq,ret_inf,WR_Z1,WR_Z2,stat_cmd
        XREF  t_state,b_state,ch_id,ir_tout,DIP_imag,ms_save
        XREF  curr_mode,curr_mode_ac3,curr_mode_dts,curr_mode_mpeg,mode_chs
        XREF  chirp_H,chirp_L,beepbeep,savebeep,beep1,tone1,click
        XREF  mute_cntr,mute_status,daisy_num,ps_frame
        XREF  exec_frm,daisy,show_HDCD,show_HFEQ,spkr_cfg 
        XREF  update_EO_Vmux,update_S_Main_mux,update_MB_Tape_mux
        XREF  update_S_Tape_mux,update_S_K6,update_MB_Main_mux
        XREF  DAC8_imag1,DAC8_imag2,EO_Vmux_imag,S_Main_imag,S_Tape_imag
        XREF  S_K6_imag,MB_Main_imag,MB_Tape_imag,vol_buf_fixup
        XREF  Dig_labels,Ana_labels,AnaPT_labels,hdcd_on,icon_flag,es_flag
        XREF  set_atten,volume_initials,send_sci,mute_togl
        XREF  noise_in_proc,noise_channel,static_in_proc,party_flag
        XREF  chs_seld,dec_key,highlight_spkrs,curr_chs,active_chs
        XREF  spkr_masks_symm,spkr_masks_asymm,dec_key_save
        XREF  xover_rolloff,xover_chs,rolloff_chs,xover_val
        XREF  ir_test_mode,feats_sel_bits,v_enh_flag,late_nite
        XREF  shortcut_feats,set_all_lists,kill_es_sl_on
        XREF  enc_vol_slow,ana_6dB,downmix_flag,mem_num
        XREF  write_fac_defs,write_globals,write_first_globals
        XREF  curr_vid,t_dts_inp,dig_tape_inp,ana_tape_inp,t_mpeg_inp
        XREF  t_ac3_inp,unmute_Zs,kill_on,kill_off,kill_status
        XREF  z_mode,coding_cfg,get_curr_mode,check_if_new_Z
        XREF  vol_acc,SPL_buf,SPL_dBs,auto_in_proc,screen_up,screen_down
        XREF  vcp_l,vcp_r,vcp_ls,vcp_rs,vcp_sub,vcp_c,LFRF_dst,LSRS_dst,CT_dst
        XREF  r_f,ls_f,sub_f,ch_vol,abort_auto_set,init_noise,auto_success
        XREF  display31,auto_ctr,auto_set_finish,bal_single_save
        XREF  auto_delay_finish,auto_delay_mode,auto_delay
        XREF  exit_adjust,restore_locals,restore_globals,freaked
        XREF  cor_l,cor_r,cor_ls,cor_rs,cor_c,cor_sub,test_screen
        XREF  PCM_in_proc,DTS_in_proc,MPEG_in_proc,deem_off_flag
        XREF  get_auto_flag,dbufr,byte_to_3,spkr_dist_nums,write_ee
        XREF  warble,crack_cmd2,quiet_spkrs,show_temp,exec_rs232
        XREF  new_version,err_star,display12_no_clr,display12_VCP
        XREF  crack_change,show_ESMP,vc_sub,vc_c_addr_offset,vcp_es
        XREF  emphasis_check,freq_check,crack_lst,polarity,channel_pol

	endc

; Buef_com.s
	ifndef buefcom_flag
        XREF  SRCH,UPCASE,WCHEK,INPUT,OUTPUT,OUTA,OUTCRLF,OUTSTRG,INCHAR
        XREF  ONSCI,WSKIP,MSG3,SVSCI,COMBUFF,JSWI,JTOC4,Buef_init,CHRCNT
        XREF  EEWRIT,EEBYTE,INBUFF,ENDBUFF

	endc

; IR_learn.s
	ifndef irlearn_flag
        XREF  Learn_mode,IR_output,IR_code_out
	endc

; Lamp_ctl.s
	ifndef lampctl_flag
        XREF  bright_up,bright_down,lamp_on,lamp_off,add_pulse
        XREF  bright_level,write_bright
        endc

; LCD_ctl.s
	ifndef lcdctl_flag
	XREF  LCD_init,screen_position,Section_clear,start_blinking
        XREF  blinking,SCREENS,screen_out,clear_CC,blink_posns
        XREF  screen_image,blink_on_off
        XREF  VFD_bright_driver,LCD_config,LCD_init0
	endc

; Misc.s
	ifndef misc_flag
        XREF  outa,inchar,delay_loop
        XREF  dummy,short_dummy
	endc


; Auto_set.s
        ifndef autos_flag

        XREF  SPLdB,deciSPL
        XREF  aver_flt,switch_SPL,ref_level
        XREF  tweak_vol,crack_channel,prev_peak,max_time,auto_stage
        XREF  max_time2

        endc


; Screens.i
	ifndef eos10_flag
        XREF  spaces,dB,dot_dB,neg_dB,neg_dB2
        XREF  no_lock_screen,Stereo,Surround,Matrix,Mono
        XREF  channel_8_names,channel_6_names,channel_2_names
        XREF  HDCD,HFEQ,ESon,MusicON,PartyON,AES_sign,data_sign,v_enh_sign
        XREF  ln_high_sign,ln_med_sign,ln_low_sign,ln_off_sign
        XREF  xover_sym,sml_kick,lrg_kick,Buef_screen
        XREF  Spkr_cfg_RefCinema,Spkr_cfg_Cinema71,anlg_passthru_NA
        XREF  full_horiz_bar,left_horiz_bar1,left_horiz_bar2       
        XREF  emph_sign,freq_48,freq_32,V_sign,C_sign,P_sign
        XREF  daisies,versions_screen_A,versions_screen_B
        XREF  special_test_screen,analog_passthru,analog_daisies
        XREF  spkrs_rev,spkrs_norm,dts_memo,dts_5_1,dts_stereo
        XREF  ir_learn_screen,noise_seq_screen,static_nse_screen,no_lock_dts
        XREF  MPEG_stereo,MPEG_ProL,auto_s_unavailable_screen
        XREF  Anlg_inp_atten,System_config,Features_status
        XREF  PAV_links,DAV_links,AAV_links,Dig_inp_desig,input_data_freq
        XREF  Anlg_inp_desig,IR_test,rs232_ok,rs232_error,ir_tx_error,ir_tx_okay
        XREF  AnlgPT_inp_desig,deselect,SPL_meter,temp_dts_scrn,memory_vacant   
        XREF  dolby_dig_blurb,selection_to_blurb,auto_s_err_screen,auto_d_err_screen
        XREF  clippage_star,clip_colon,auto_setup_screen,auto_delay_screen
        XREF  nl_ster,nl_surr,nl_matr,nl_mono,temp_mpeg_scrn,no_lock_mpeg
        XREF  MPEG_matrix,MPEG_mono,no_lock_ac3,clip_block
        XREF  sys_cfg_tdts,sys_cfg_tmpg,sys_cfg_tac3,input_data_khz
        XREF  SM_down_screen_1,SM_down_screen_2,dts_n_a,freq_44,freq_nolk
        XREF  dolby_20_prol,subs0_sign,subs1R_sign,subs2_sign
        XREF  Stdby_dots,Into_Stdby,sub1_sign,sub0_sign,movie_sign,music_sign
        XREF  Standby_scrn,VFD_test_1,VFD_test_2,ES_off_sign
        XREF  special_single_screen,special_bal_screen


	XREF  IR_codes_start,TM_page,TMS_page,Special_page,IR_codes_end
        XREF  TM_learn,TMS_learn,Specials
        XREF  learn_buts,learn_start,learn_tx,learn_repeat
	XREF  font_pointers,fonts_end
        XREF  f_cold_def,f_cold_def_end,f_cold_def_globs,f_chan_pol
        XREF  rs_codes,rs_codes_end

        endc


; Keylabel.i
        ifndef eos10_flag
        XREF key_labels
	endc


; Invade.s
        ifndef inv_flag
        XREF  Invade
	endc


; sm_dl.s
        ifndef sm_dl_flag
        XREF  downloader
        endc
