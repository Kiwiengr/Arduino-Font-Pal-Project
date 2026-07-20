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
;   EOS_com.s
;
;************************************************
;*
;*  Main Command and Screen Processing Routines
;*
;************************************************
;
;TO INVESTIGATE:
;==============
;
;Do we want the screen output state to be maintained across standby?
;Answer: Yes, because when doing a quick DTS dedication, the device
;        connected to the screen output will otherwise go off.
;
;Check that we are using the optimal error concealment repeat block on
; error (See Title 78 on Dolby Test DVD). 
;
;
;BUGS TO FIX & THINGS TO DO:
;==========================
;
;B7 Pro Logic possibly applies its own volume correction to better match
; the levels of Pro Logic and Dolby Digital 5.1. Check if this is so, and
; omit the correction if Z1 is a B7. NOTE: May still need to do 1 or 2 dB
; coreection with B7, depending on the exact Zoran correction (which may
; be 3, 4, or 5 dB. Check with Vlad on the exact level used.)
;
;Which characters should the TM ignore from the RS232?
; E.g.,(1) Should ignore SM control codes, Buefuss error message, etc., so
;          poor old Buefuss doesn't choke!
;      (2) TheaterMaster production testing uses a loop-back switch for
;          testing the RS-232. When this switch is ON, bringing TheaterMaster
;          out of standby puts up the model name on the LCD, turns on the
;          light, and gets no further. This is to be expected, which is why
;          the switch was provided on the test jig. The reason why it happens:
;          The sign-on message comes back as an invalid command, which puts
;          out a "Command not found" message, which is itself an invalid
;          command. One solution would be to make the sign-on message a valid
;          (but do nothing) RS-232 command.
;
;FUTURE:
;======
;
;Documentation of algorithms.
;
;Adjust Auto Setup final stage as follows:
; 1) Use a longer time constant on the smoothing filter.
; 2) Use 0.5 dB volume steps (this is the CS3310 resolution).
; The Classic and Ovation/Signature TheaterMasters used volume controls
; which had 0.1875 dB resolution. The Classic's Auto Setup final stage
; used both a longer time constant smoothing filter, and the fine 0.1875 dB
; volume steps. Due to the Encore's 1 dB volume control resolution, the
; Classic's Auto Setup was rewritten for the EOS to allow the use of the
; lowest common denomminator 1 dB volume step. Although this has worked well,
; and also converges faster than in the Classic (due to omission of the
; 0.1875 dB final stage), maybe we can improve level accuracy slightly by
; going down to 0.5 dB.
;
;Improve the resolution of the SPL meter, especially for low dB values.
; Noise mode SPL meter can be a bit jittery if the reading sits between two
; scale points, e.g., 59.1 dB and 62.7 dB.
;
;Follow Auto Phase detect with Auto Phase correction?
;
;Make two new F-n-n commands, one to put out the English feats, and the
; other to put out the Japanese feats.
;
;
;QUIRKS & LIMITATIONS:
;=====================
;
;The -4 dB adjustment of LS,RS in Hafler Matrix mode is not applied in
; Dolby Digital 2/0/0 Hafler Matrix override mode (:Mat).
;
;The changing of input designators will lock up for 2 seconds if user
; presses Enter-ChanUP-ChanUP or Enter-ChanUP-ChanDN, etc. Problem is
; that ChanUP and ChanDN are the start of Store-n and Recall-n; the
; state machine waits for n, which takes 2 seconds to time-out.
;
;No auto-detect flag for MPEG. Don't expect any improvement here!
;
;Special Mono Test mode clips very slightly on a 0 dB 1 kHz PCM sinewave.
;
;EOS main analog outputs are 13.6 ms behind the analog output of the A100
; Panasonic DVD player sample that we have. Is this a problem for lip-synch?
; Answer: No. The DVDO video processor chip has a delay of 3 fields, or
;         approximately 50 ms. The 13.6 ms differential delay of the
;         TheaterMaster (due mainly to the bass management software),
;         in fact improves the situation, decreasing the lip-synch delay
;         when using the DVDO (or other similar) line doubler.
;
;Note that it is correct for the V flag to be asserted for DVD AC-3 and
; DVD DTS. This is specified in the IEC standard for DVD S/PDIF bitsreams.
; The reasoning is that the Audio/Data flag occurs too infrequently to be
; useful for detecting non-audio (compressed) data streams. The V flag,
; on the other hand, occurs every sample.  The Pioneer AC-3 RF demodulator
; chip behaved contrary to the standard, leaving the V flag deasserted.
; This special use of the DVD V flag is OK because AC-3 and DTS data
; integrity is separately protected by means of a block CRC check.
;
;Note: ^X command deleted from Buefuss (is used by the SwitchMaster).
;
;
;NEW FEATURES IMPLEMENTED:
;========================
;The rev. number of Z1 (38600-B6, 38600-B7, 38601-A2) is now auto-detected
; to allow the appropriate ProL string to be sent to Z1. It also disables the
; download of MPEG2 code to B7 and A2. Note: At present, the B7 and A2
; versions are lumped together.
;
;8-ch bar graph now stays up across bitstream mode changes.
;
;Pink Noise scaling adjusted to standard level of -9 dBFS for Noise
; Sequencer and Static Noise modes.  Auto Setup level is still 0 dB.
;

;************************************************
;*     EOS_com.s
;*
;* EOS commands and initialization routines
;*******************************************
;
; Bar graph VU Meter display (stereo & 6-channel)
; Big Nums display
; Main display (small volume, coding config., etc.)
; Speaker Adjustment display
; Noise Sequencer mode
; Static Noise mode
; Various other setup screens.
; 
; Initialize CS4226, ZR38600s, PMD100s
; Read/write CS4226
; Read/write Z1, Z2, M1.
;
; CS4226 SPI command strings
; Z1 and Z2 (ZR38600) SPI command strings
; M1 (56009) SPI command strings (DTS daughter board)
;

        CLIST OFF       ;Only list assembled conditionals.
        MLIST OFF       ;Don't expand macros.


eoscom_flag:    equ     0


        XDEF   display_scrn,Z_modes,Bar_None_Display
        XDEF   Bar_volume,Bar2_Display,Bar6_Display,Bar8_Display
        XDEF   init_4226_xtal,init_4226_pll,noisy_channels,rotate_noise
        XDEF   do_ams,do_dms,unpack_vol,mute_all,unmute_all,curr_pass_mode
        XDEF   SPL_display,display30,mute_on,mute_off,do_mute,undo_mute
        XDEF   reset_38,WR_CS4226,RD_CS4226,mute_cmd,init_4PCMs
        XDEF   spi_cmd_1,spi_cmd_2,CS3310_vol_imag,WR_CS3310s
        XDEF   locked,AC3_in_proc,rs_imag,from_standby,into_standby
        XDEF   cs0_imag,cs3_imag,fs_freq,ret_inf,WR_Z1,WR_Z2,stat_cmd
        XDEF   t_state,b_state,ch_id,ir_tout,DIP_imag,ms_save
        XDEF   curr_mode,curr_mode_ac3,curr_mode_dts,curr_mode_mpeg,mode_chs
        XDEF   mute_cntr,mute_status,daisy_num,ps_frame
        XDEF   chirp_H,chirp_L,beepbeep,savebeep,beep1,tone1,click
        XDEF   exec_frm,daisy,show_HDCD,show_HFEQ,spkr_cfg
        XDEF   update_EO_Vmux,update_S_Main_mux,update_MB_Tape_mux
        XDEF   update_S_Tape_mux,update_S_K6,update_MB_Main_mux
        XDEF   DAC8_imag1,DAC8_imag2,EO_Vmux_imag,S_Main_imag,S_Tape_imag
        XDEF   S_K6_imag,MB_Main_imag,MB_Tape_imag,vol_buf_fixup
        XDEF   Dig_labels,Ana_labels,AnaPT_labels,hdcd_on,icon_flag,es_flag
        XDEF   set_atten,volume_initials,send_sci,mute_togl
        XDEF   noise_in_proc,noise_channel,static_in_proc,party_flag
        XDEF   chs_seld,dec_key,highlight_spkrs,curr_chs,active_chs
        XDEF   spkr_masks_symm,spkr_masks_asymm,dec_key_save
        XDEF   xover_rolloff,xover_chs,rolloff_chs,xover_val
        XDEF   ir_test_mode,feats_sel_bits,v_enh_flag,late_nite
        XDEF   shortcut_feats,set_all_lists,kill_es_sl_on
        XDEF   enc_vol_slow,ana_6dB,downmix_flag,mem_num
        XDEF   write_fac_defs,write_globals,write_first_globals
        XDEF   curr_vid,t_dts_inp,dig_tape_inp,ana_tape_inp,t_mpeg_inp
        XDEF   t_ac3_inp,unmute_Zs,kill_on,kill_off,kill_status
        XDEF   z_mode,coding_cfg,get_curr_mode,check_if_new_Z
        XDEF   vol_acc,SPL_buf,SPL_dBs,auto_in_proc,screen_up,screen_down
        XDEF   vcp_l,vcp_r,vcp_ls,vcp_rs,vcp_sub,vcp_c,LFRF_dst,LSRS_dst,CT_dst
        XDEF   r_f,ls_f,sub_f,ch_vol,abort_auto_set,init_noise,auto_success
        XDEF   display31,auto_ctr,auto_set_finish,bal_single_save
        XDEF   auto_delay_finish,auto_delay_mode,auto_delay
        XDEF   exit_adjust,restore_locals,restore_globals,freaked
        XDEF   cor_l,cor_r,cor_ls,cor_rs,cor_c,cor_sub,test_screen
        XDEF   PCM_in_proc,DTS_in_proc,MPEG_in_proc,deem_off_flag
        XDEF   get_auto_flag,dbufr,byte_to_3,spkr_dist_nums,write_ee
        XDEF   warble,crack_cmd2,quiet_spkrs,show_temp,exec_rs232
        XDEF   new_version,err_star,display12_no_clr,display12_VCP
        XDEF   crack_change,show_ESMP,vc_sub,vc_c_addr_offset,vcp_es
        XDEF   emphasis_check,freq_check,crack_lst,polarity,channel_pol

        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


;*************************************************************************
;*************************************************************************

EOS_vbls:	Section 32

;** General housekeeping
locked:           ds.b     1       ;Receiver PLL lock flag (initialized to $00, unlocked).
freaked:          ds.b     1       ;Receiver freaked flag. (1=freaked) byte2 CLKE
kill_status:      ds.b     1       ;Kill status (0=unkilled, 1=killed)

mute_status:      ds.b     1       ;Mute command status (0=unmuted)
                                   ;1=mute: MSB=0=Source daisy is cleared.
                                   ;      : MSB=1=Source daisy shows coding config.

mute_cntr:        ds.b     1       ;Daisy blink counter for mute mode
daisy_num:        ds.b     1       ;Source daisy number

icon_flag:        ds.b     1       ;Icons to be displayed: HDCD, CinEQ, ES, Music, Party.
                                   ; bit 0 = 1 = HDCD (=lsb)
                                   ; bit 1 = 1 = CinEQ ON
                                   ; bit 2 = 1 = ES enabled
                                   ; bit 3 = 1 = 7.1 Music mode (= 0 = 7.1 Movie mode)
                                   ; bit 4 = 1 = Party mode engaged

DIP_imag:         ds.b     1       ;Copy of front panel DIP switch states at bootup.
Z_ver_flag:       ds.b     1       ;ZR38600 version flag: $00=ver.B6, $ff=ver.B7,A2.

;** CS4226 registers
rs_imag:          ds.b     1       ;Image of CS4226 receiver status byte.
cs0_imag:         ds.b     1       ;1st byte of CS4226 channel status data.
;cs1_imag:         ds.b     1       ;2nd byte of CS4226 channel status data.
;cs2_imag:         ds.b     1       ;3rd byte of CS4226 channel status data.
cs3_imag:         ds.b     1       ;4th byte of CS4226 channel status data.
fs_freq:          ds.b     1       ;1=44.1kHz, 2=48kHz, 3=32kHz


;** Images of write-only latches
DAC8_imag1:       ds.b     1       ;Image of DAC8 latch 1 (Mutes/Kills/CS3310 ser. ctrl)
DAC8_imag2:       ds.b     1       ;Image of DAC8 latch 2 (4V/8V/Anlg Pass-thre ctrl/PCM1732 ser. ctrl)
bal_single_save:  ds.b     1       ;Saved image of balanced/single-ended bits from DAC2_imag.

EO_Vmux_imag:     ds.b     1       ;Image of EO video switching mux.
curr_vid:         ds.b     1       ;Current video input. msb=1 for S-video.
S_Main_imag:      ds.b     1       ;Image of S back panel analog Main mux.
S_Tape_imag:      ds.b     1       ;Image of S back panel analog Tape/Mon mux.
S_K6_imag:        ds.b     1       ;Image of S backpanel Kill (D1) & -6 dB (D0) bits.
MB_Main_imag:     ds.b     1       ;Image of mother board digital Main mux.
MB_Tape_imag:     ds.b     1       ;Image of mother board digital Tape/Mon mux.


;** Zoran stuff
plltab_lst:       ds.b     9       ;PLLTAB template for Z1
pllcfg_lst:       ds.b     4       ;PLLCFG template for Z1


;** Volume setting 
CS3310_vol_imag:  ds.b    8        ;CS3310 volume image (raw CS3310 units).
                                   ;(RF, LF, RS, LS, ES, SL, SR, CT)
                                   ; 0   1   2   3   4   5   6   7  <--addr. offsets.

vc_min_flags:     ds.b     1       ;Flags any of the channels at min volume
vc_max_flags:     ds.b     1       ;Flags any of the channels at max volume or in compression
vc_cmp_flags:     ds.b     1       ;Flags any of the channels at max volume
att_chng:         ds.b     2       ;Vol change 1 step (1 for vdn, -1 for vup)
this_flag:        ds.b     1       ;Mask for min and max volume flags (ch_id related)
this_mask:        ds.b     1       ;Mask for min and max volume flags (curr_chs related)
vc_count:         ds.b     2       ;Volume level used in direct setting (all ch.)
dB_value:         ds.b     2       ;User's desired dB level from [F][n][n] 
min_att:          ds.b     2       ;Min. att. level of all channels
bar_info:         ds.b     8       ;8 channel bar VU meter


;** Table-driven remote and RS232 processing
dec_key:          ds.b     1       ;Decimal value of key pressed ($ff if not number key).
dec_key_save:     ds.b     1       ;Save value of decimal key.
t_state:          ds.b     1       ;Current state in key sequence processing.
b_state:          ds.b     1       ;State at beginning of key sequence.
n_state:          ds.b     1       ;Next state after current one times out.
ir_tout:          ds.b     1       ;IR command sequence time out counter.
succ_exec:        ds.b     1       ;Flag to show if key was valid in sequence.
ps_frame:         ds.b     1       ;Pseudo-frame to accommodate sets of keys in table.

downmix_flag:     ds.b     1       ;AC-3/DTS to Dolby Surround downmix requested by user.

late_nite:        ds.b     1       ;AC-3 late night compression level requested.
ret_ptr:          ds.b     2       ;Current position in return info buffer
record_rx:        ds.b     1       ;Zoran SPI response recording flag
tone_freq:        ds.b     1       ;Current noisemaker tone frequency.
v_enh_flag:       ds.b     1       ;Video vertical enhancer flag.
ana_6dB:          ds.b     1       ;Analog 6dB attenuation (1 bit per input).

                                
;** Special noise modes
ch_vol:           ds.b     1       ;Channel volume mode flag (anything but normal mdoe) 
ch_id:            ds.b     1       ;Channel to write volume value to.
noise_in_proc:    ds.b     1       ;Flag to show that noise sequencer is in process
noise_channel:    ds.b     1       ;Which channel is noisy
static_in_proc:   ds.b     1       ;Flag to show that static noise is in process
xover_rolloff:    ds.b     1       ;Flags if we are in x-over or roll-off modes
auto_in_proc:     ds.b     1       ;Flags auto setup in process 
auto_success:     ds.b     1       ;Succesful auto setup level complete
auto_ctr:         ds.b     1       ;Counter for auto setup
polarity:         ds.b     1       ;Polarity of Auto-delay cracks
channel_pol:      ds.b     6       ;Channel polarity measured by Auto Delay.
crack_change:     ds.b     2       ;For crack tweaking (not currently used = 0)

;** Input selection
ms_save:          ds.b     1       ;Main source (1-6, digital; 1-9 analog),
                                  ; analog if msb set.
;** Mode setting
curr_mode:        ds.b     1       ;PCM user mode (ster=0,matrix=2,mono=3,surr=1)
curr_mode_ac3:    ds.b     1       ;AC3 user mode (default=$ff,ster=0,matrix=2,mono=3,surr=1)
curr_mode_dts:    ds.b     1       ;DTS user mode ( " )
curr_mode_mpeg:   ds.b     1       ;MPEG2 user mode ( " )
curr_mode_temp:   ds.b     1       ;
curr_pass_mode:   ds.b     1       ;Pass-through mode (digital=0,passthru6=1,passthru2=2,passthru8=3)

PCM_in_proc:      ds.b     1       ;PCM decoding in process
AC3_in_proc:      ds.b     1       ;AC-3 decoding in process flag.
DTS_in_proc:      ds.b     1       ;DTS decoding in process flag. NOT NEEDED.
MPEG_in_proc:     ds.b     1       ;MPEG2 decoding in process

deem_off_flag:    ds.b     1       ;Set this flag to request that de-empahsis be turned off.
hdcd_on:          ds.b     1       ;HDCD indicator.
hfeq_dig_flag:    ds.b     6       ;HFEQ flags - digital
hfeq_ana_flag:    ds.b     6       ;HFEQ flags - analog

party_flag:       ds.b     1       ;Party mode flag (1=Party, 0=Stereo)

es_flag:          ds.b     1       ;ES speaker flag (1=enabled, 0=disabled)

spkr_cfg:         ds.b     1       ;User-selected speaker config:
                                   ; C    #  M M
                                   ; o    S  o o
                                   ; d    u  v d
                                   ; e    b  i e
                                   ;      s  e
                                   ; 0 = %00 0 0 Reference Cinema, 0 subs
                                   ; 4 = %01 0 0 Reference Cinema, 1 sub=R  
                                   ; 8 = %10 0 0 Reference Cinema, 2 subs (default)
                                   ; 5 = %01 0 1 Cinema 7.1 Movie, 1 sub  (default when switching from Ref.Cinema)
                                   ; 1 = %00 0 1 Cinema 7.1 Movie, 0 subs 
                                   ; 7 = %01 1 1 Cinema 7.1 Music, 1 sub 
                                   ; 3 = %00 1 1 Cinema 7.1 Music, 0 subs
                                   ;Disallowed combinations: 2,6,9,10,11,...,15.
                                   ;Note: ES status is stored separately in es_flag

;%%%%%% Channel Flags: SB, CR, RS, LS, RF, LF (right-justified %00111111):
active_chs:       ds.b     1       ;Active channels in current mode.
active_chs_saved: ds.b     1       ;Storage of active channel setting.
curr_chs:         ds.b     1       ;Channels being currently selected.
mode_chs:         ds.b     1       ;Channels available in current mode.
mode_chs_saved:   ds.b     1       ;Storage of current mode channel setting.
chs_seld:         ds.b     1       ;Channels selected (for spkr adjust screen).
xover_chs:        ds.b     1       ;Which channels are crossed over (1=crossed-over).
rolloff_chs:      ds.b     1       ;Which channels have big spkrs (=1) or small spkrs (=0).
xover_val:        ds.b     1       ;Which xover frequency we have selected.


;** Mode-dependent volume level corrections
dianorm_val:      ds.b     1       ;Raw dB dialog normalization code from Zoran #1.
mat_flag:         ds.b     1       ;1 = matrix; 0 = other mode. Used to apply -4 dB
                                   ; to the surrounds in Hafler matrix mode.
HDCD_corr:        ds.b     2       ;+6 dB (if any) to compensate for HDCD.
prol_corr:        ds.b     2       ;+5 dB (if any) to compensate for PCM ProL.
                                   ; processing loss and psychoacoustic loss
                                   ; compared to AC-3 or DTS.
matrix_corr:      ds.b     2       ;-4 dB to adjust Hafler matrix surrounds for
                                   ; balance with majority of stereo recordings.
                                   ; (This was requested by Legacy Audio).
lr_bs_corr:       ds.b     2       ;L,R correction value due to Zoran #2 scaling
sub_bs_corr:      ds.b     2       ;SUB correction value due to Zoran #2 scaling
dialog_corr:      ds.b     2       ;AC-3 scaled dialog normalization compensation value


;%%%% The following variables must be protected across standby...

;The unpack_vol subroutine calculates vc_ = vcp_ + corr_ for "digital"
; sources, and vc_ = vcp_ for the analog pass-throughs. It then sets
; the individual volumes according to the vc_ result.

vc_l:             ds.b     2       ;L   channel digital attenuation in effect. 
vc_r:             ds.b     2       ;R   channel digital attenuation in effect. 
vc_ls:            ds.b     2       ;LS  channel digital attenuation in effect. 
vc_rs:            ds.b     2       ;RS  channel digital attenuation in effect. 
vc_c:             ds.b     2       ;C   channel digital attenuation in effect.
vc_sub:           ds.b     2       ;SUB channel digital attenuation in effect.
vc_es:            ds.b     2       ;ES  channel digital attenuation in effect.
vc_dummy:         ds.b     2       ;Conveniently keeps volume processing in pairs.

vcp_addr_offset:  equ     16       ;Address offset of vcp_s from vc_s.

vcp_l:            ds.b     2       ;L   channel composite attenuation 
vcp_r:            ds.b     2       ;R   channel composite attenuation. 
vcp_ls:           ds.b     2       ;LS  channel composite attenuation. 
vcp_rs:           ds.b     2       ;RS  channel composite attenuation. 
vcp_c:            ds.b     2       ;C   channel composite attenuation.
vcp_sub:          ds.b     2       ;SUB channel composite attenuation.
vcp_es:           ds.b     2       ;ES  channel composite attenuation.
vcp_dummy:        ds.b     2

cor_addr_offset:  equ     32       ;Address offset of cor_s from vc_s.

cor_l:            ds.b     2       ;L   channel correction value (due to HDCD, xovers, etc)
cor_r:            ds.b     2       ;R   channel correction value (due to HDCD, xovers, etc)
cor_ls:           ds.b     2       ;LS  channel correction value (due to HDCD, xovers, etc)
cor_rs:           ds.b     2       ;RS  channel correction value (due to HDCD, xovers, etc)
cor_c:            ds.b     2       ;C   channel correction value (due to HDCD, xovers, etc)
cor_sub:          ds.b     2       ;SUB channel correction value (due to HDCD, xovers, etc)
cor_es:           ds.b     2       ;ES  channel correction value (due to HDCD, xovers, etc)
cor_dummy:        ds.b     2

vc_c_addr_offset: equ     48       ;Address offset of vc_c_s from vc_s.

;* Primary volume level copy area (same order as vc_l ...)
vc_c_l:           ds.b     2       ;L   channel volume level copy area.
vc_c_r:           ds.b     2       ;R   channel volume level copy area.
vc_c_ls:          ds.b     2       ;LS  channel volume level copy area.
vc_c_rs:          ds.b     2       ;RS  channel volume level copy area.
vc_c_c:           ds.b     2       ;C   channel volume level copy area.
vc_c_sub:         ds.b     2       ;SUB channel volume level copy area.
vc_c_es:          ds.b     2       ;ES  channel volume level copy area.
vc_c_dummy:       ds.b     2

vc_2_addr_offset: equ     64       ;Address offset of vc_2_s from vc_s.

;* Secondary volume level copy area (same order as vc_l ...)
vc_2_l:           ds.b     2       ;L   channel volume level copy area.
vc_2_r:           ds.b     2       ;R   channel volume level copy area.
vc_2_ls:          ds.b     2       ;LS  channel volume level copy area.
vc_2_rs:          ds.b     2       ;RS  channel volume level copy area.
vc_2_c:           ds.b     2       ;C   channel volume level copy area.
vc_2_sub:         ds.b     2       ;SUB channel volume level copy area.
vc_2_es:          ds.b     2       ;ES  channel volume level copy area.
vc_2_dummy:       ds.b     2

;** Zoran command string buffers
AC3_lst:          ds.b     11      ;Current AC-3 command sequence.
prol_lst:         ds.b     11      ;Current ProL command sequence.
mpeg_lst:         ds.b     11      ;Current MPEG2 command sequence.
ead_lst:          ds.b     11      ;Current EAD custom PCM command sequence.
DTS_lst:          ds.b     16      ;Current DTS command sequence.
crack_lst:        ds.b     11      ;Crack command for Z2.

vol_overall:      ds.b     2       ;Overall volume level.
enc_vol_slow:     ds.b     2       ;Volume slow factor for Encore. No longer used.

dbufr:            ds.b     3       ;Volume dB display buffer used in various modes.
vol_acc:          ds.b     3       ;Mic filter 24-bit volume level accumulator.
SPL_buf:          ds.b     3       ;Decimal mic SPL dB result buffer.
SPL_dBs:          ds.b     1       ;0-60 for mic spl bar.

ret_inf:          ds.b     43      ;Return info received from Z1,Z2,M1 on SPI.
peek_lst:         ds.b     14      ;Z2 peeking to Xover frequencies.
xover_freqs:      ds.b     10      ;List of cross over frequencies.
png_lst:          ds.b     11      ;Pink noise generator list.

;** New variables:
z_mode:           ds.b     1       ;Entry in composite decoding mode table.
z_error:          ds.b     1       ;Flags Zoran mode errors.
coding_cfg:       ds.b     1       ;Source material coding config (2/0, 3/1 etc).

mem_num:          ds.b     1       ;User memory number.
t_dts_inp:        ds.b     1       ;Temporarily dedicated DTS input, 1-6.
t_mpeg_inp:       ds.b     1       ;Temporarily dedicated MPEG input 1-6
t_ac3_inp:        ds.b     1       ;Temporarily dedicated AC3 input 1-6.
dig_tape_inp:     ds.b     1       ;Digital tape.
ana_tape_inp:     ds.b     1       ;Analog tape.

LFRF_dst:         ds.b     1       ;Front speaker distances.
LSRS_dst:         ds.b     1       ;Surround spkr distances.
CT_dst:           ds.b     1       ;Center spkr distances.

write_reg_lst:    ds.b     4       ;4226 register writing command.
read_reg_a_lst:   ds.b     3       ;4226 register reading command.

Dig_labels:       ds.b     6       ;Table of pointers to digital labels.
Ana_labels:       ds.b     6       ;Table of pointers to analog labels.
AnaPT_labels:     ds.b     3       ;Table of pointers to analog pass-thru labels.

test_screen:      ds.b     1       ;Flags whether a test screen is up.

;************************************************************************
;************************************************************************


EOS_com:       Section 2


;*****************************************************************
;*
;*             Main Infra-Red Frame Execution Subroutine
;*                           
;*****************************************************************
;*
;* Subroutine to execute received IR codes.
;* Called when the flag IR_ready is set. At this point, 2 identical frames
;* have been received, the second of which is stored in "frame".
;*
;* TM   (blue)  = Ordinary TheaterMaster remote control keys.
;* TMS (yellow) = TheaterMaster Setup remote control keys.
;*
;* [Note: Blue and yellow refer to the two TheaterMaster devices
;* on the UEI 8080 push-button remote control]
;*
;***
exec_frm:
	ldab    frame
        jsr     fr_to_dec        ;Convert keycode to decimal value
        stab    dec_key          ;Store decimal value for future

;%% execute key as is...
	ldaa    frame
        staa    ps_frame         ;Set pseudo frame (same as actual frame)
        clr     IR_ready         ;Get ready for next frames
        jsr     exec             ;Execute the command as is...
        tst     succ_exec        ;If successful (valid key),
        bne     ir_out           ; we're done...

;>>>        bne     ir_done          ; we're done...

        ldab    dec_key          ;Look at decimal value of received frame
        cmpb    #$ff             ;Is it a number key?
        beq     ir_done          ;If not, can't interpret as anything else...

;%% execute TM numeric keys {0,1,2,...,9} i.e., k_num...
	ldaa    #k_num
        staa    ps_frame         ;Set pseudo frame as "any number key"
        jsr     exec             ;Execute the command...
        tst     succ_exec        ;If successful (valid key), 
        bne     ir_done          ; we're done...

        ldab    dec_key                ;Get decimal value
        brset   dec_key,#$80,nums_TMS  ;If MSB set, it is TMS number

;%% execute TM keys {1,2,...,6} or {7,8,9,0}, i.e., k_16_TM or k_70_TM...
nums_TM:
        cmpb    #0               ;Is it 0?
        beq     keys_7to0_TM     ;If so, go process as TM 0-7

        cmpb    #6               ;Is it more than 6?
        bhi     keys_7to0_TM     ;If so, go process as TM 0-7

keys_1to6_TM:
        ldaa    #k_16_TM         ;Else process as TM 1-6
        staa    ps_frame         ;Set pseudo frame as "number key 1 to 6"
        jsr     exec             ;Execute the command
        bra     ir_done          ;We're done

keys_7to0_TM:
        ldaa    #k_70_TM
        staa    ps_frame         ;Set pseudo frame as "number key 7 to 0"
        jsr     exec             ;Execute the command
        bra     ir_done          ;We're done

;%% execute TMS keys {1,2,...,6} or {7,8,9,0}, i.e., k_16_TMS or k_70_TMS...
nums_TMS:
        andb    #%01111111       ;Mask out MSB
        cmpb    #0               ;Is it 0?
        beq     keys_7to0_TMS    ;If so, go process as TMS 0-7

        cmpb    #6               ;Is it more than 6?
        bhi     keys_7to0_TMS    ;If so, go process as TMS 0-7

keys_1to6_TMS:
        ldaa    #k_16_TMS        ;Else process as TMS 1-6
        staa    ps_frame         ;Set pseudo frame as "number key 1 to 6"
        jsr     exec             ;Execute the command and
        bra     ir_done          ; we're done!

keys_7to0_TMS:
        ldaa    #k_70_TMS
        staa    ps_frame         ;Set pseudo frame as "number key 7 to 0"
        jsr     exec             ;Execute the command and we're done!
ir_done:  
        tst     succ_exec        ;If successful (valid key), 
        bne     ir_out           ; we're done!
	
        ldaa    b_state          ;Else get state at beginning of sequence
        staa    t_state          ; and change current state to this value.
ir_out:        
        rts                  ;** Return **
                       
        
;***************************************************************
exec:   bset    succ_exec,#$ff   ;Set success flag.
        ldy     #key_tab         ;Point to keypress table.
nxt_key:        
        ldaa    0,y              ;Get state number.
        iny                      ;Advance table pointer to key code.
        cmpa    t_state          ;If table state different from current state, 
        bne     nxt_state        ; advance to next state in table...

        ldaa    0,y              ;Get key code from table.
        cmpa    ps_frame         ;If key code matches received key,
        beq     response         ; determine response...
	
nxt_state:        
        iny                      ;Advance to next state in table.
        cpy     #end_key_tab     ;End of table, i.e., invalid key press?
        bhs     inval_key        ;If so, go revert back to beginning state...
        bra     nxt_key          ;Else, get next state from table...

response:
        ldaa    1,y              ;Get state after key press
	staa    n_state 
	brset   n_state,#%10000000,intermed   ;If intermediate state, handle accordingly

        ldy     #state_tab       ;Point to response table.
nxt_resp:
        ldaa    0,y              ;Get state.
        cmpa    n_state          ;Same as current?
        beq     react            ;If so, do the response...

        ldab    #6  
        aby                      ;Advance 6 bytes in response table.
        cpy     #end_state_tab   ;End of table?
        blo     nxt_resp         ;If not, look at next row of table...
        bra     inval_key        ;Else restore beginning state...

react:  ldaa    1,y
        cmpa    #126
        beq     no_change_t      ;If code 126, do not alter t_state

        staa    t_state          ;Set state after response
no_change_t:
	ldaa    2,y
        staa    ir_tout          ;Set time-out

        tst     curr_pass_mode   ;If not Anlg Pass-Thru mode,
        beq     .exec_OK         ;Then continue as normal...

        tst     3,y              ;If cmnd allowed in Anlg Pass-Thru mode,
        beq     .exec_OK         ; continue as normal...

        jsr     warble_L         ;Else signal warble tone to indicate
        bra     inval_key        ; that command is invalid in Pass-Thru.

.exec_OK:
        pshy                     ;Save table location
        ldy     4,y  
        jsr     0,y              ;Execute service routine
        puly                     ;Restore table location

.exec_contd:
        ldaa    ir_tout
        bne     exec_done        ;If unstable state, leave beginning state as is

        ldaa    t_state          ;For stable state set current state as 
        staa    b_state          ; beginning state of next sequence
exec_done:
        rts                  ;** Return **


intermed:
        staa    t_state          ;Set current state
	ldab    #long
        stab    ir_tout          ;Set command sequence timeout
        rts                  ;** Return **
        

inval_key:
        clr     succ_exec        ;Signal invalid key in sequence
        rts                  ;** Return **
        

;*******************************************************************
;* Conversion of key pushes into decimal
;*
;***
dec_tab:
        dc.b     k_0             ;TM codes output $00 - $09
	dc.b     k_1
	dc.b     k_2
	dc.b     k_3
	dc.b     k_4
	dc.b     k_5
	dc.b     k_6
	dc.b     k_7
	dc.b     k_8
	dc.b     k_9

        dc.b     ks_0            ;TMS codes output $80 - $89 (i.e., msb is set)
        dc.b     ks_1
        dc.b     ks_2
        dc.b     ks_3
        dc.b     ks_4
        dc.b     ks_5
        dc.b     ks_6
        dc.b     ks_7
        dc.b     ks_8
        dc.b     ks_9

end_dec_tab:

fr_to_dec:
        ldaa    frame           ;Get frame code
	clrb                    ;Clear counter
        ldy     #dec_tab        ;Point to conversion table
nxt_code:
        cmpa    0,y             ;Compare framecode to table entry
        beq     found           ;If match, exit

        iny                     ;Else advance in table
        incb                    ; and increase counter
        cmpb    #19             ;Past end of table?
        ble     nxt_code        ;If not, check next entry       

        ldab    #$ff            ;Error
        rts
found:
        cmpb    #9
        ble     found_end

        addb    #$80            ;Set MSB for TMS numbers
        subb    #10
found_end:
        rts                     ;** Return with result in B **


;***************************************************************
;*
;*          E X E C U T E   R S 2 3 2   C O M M A N D S
;*
;* This routine implements a primitive form of double buffering
;* for TheaterMaster RS232 commands by copying INBUFF to CINBUFF.
;* It then searches CINBUFF for commands, converts them to IR
;* key-codes, and executes them as if they were IR codes.
;*
;***
exec_rs232:                                                               
        clr     TM_flag                 ;Flag to allow next input

        ldx     #INBUFF

;        ldx     INBUFF_PTR  ;#INBUFF                 ;Point to start of in-buffer
        inx
        inx                             ;Update to beginning of command sequence
        inx

exec_rs_loop1:
        ldy     #rs_codes               ;Point to head of table

        cpx     #ENDBUFF                ;Check for end of buffer
        beq     exec_rs_end

        ldaa    0,x
        cmpa    #CR                     ;Check for CR (end-of-string)
        beq     exec_rs_end

        cmpa    #' '                    ;Check for space delimiter
        bne     exec_rs_loop2           ;If not, execute command

        inx                             ;Get to next character
        bra     exec_rs_loop1           ;Go around again


exec_rs_loop2:
        cmpa    0,y                     ;Compare character to table entry
        beq     got_ir_code

        iny                             ;Update pointer to next character
        iny
        cpy     #rs_codes_end           ;End of table?
        blo     exec_rs_loop2

exec_rs_end:
        ldd     #$0d0d
        std     INBUFF                  ;Prevent repeated command execution...
        rts

got_ir_code:
        ldaa    1,y                     ;Get corresponding IR keycode
        staa    frame                   ;Prepare to pass it to IR decoder

        pshx                            ;Save buffer pointer
        jsr     exec_frm                ;Go and execute IR code   
        pulx                            ;Restore buffer pointer

        inx                             ;Update pointer
        bra     exec_rs_loop1           ;Go and do next command               


;*****************************************************************************
;
;          STATE TABLES FOR IR REMOTE COMMAND DECODE & EXECUTION
;
; States > 127 correspond to intermediate states within a key sequence. These
; are used to keep track of where we are in the sequence, and don't perform
; any other action.
;
; States < 127 have an entry in the table defining the response to the
; key sequence.
;
; Some of the response routines modify the beginning state (b_state).
;
;
; Stable states:
;                  0  -  Normal operation
;                  7  -  Noise Sequencer mode
;                  8  -  Static Noise mode
;                 40  -  Channel Balance Volume mode (Speaker Adjustment screen)
;                 79  -  Autosetup mode
;                 13  -  Standby
;
;
;             beginning
;               state    key     state   key     state   key ...  [end marker]
;-----------------------------------------------------------------------------
key_tab:

;* Normal volume control:        
        dc.b      0,     k_vup,   1,     stop                               
        dc.b      0,     k_vdn,   2,     stop                           

;* Noise sequencer mode volume control:
        dc.b      7,     k_vup,   1,     stop                           
        dc.b      7,     k_vdn,   2,     stop                           

;* Static Noise mode volume control:
        dc.b      8,     k_vup,   1,     stop                           
        dc.b      8,     k_vdn,   2,     stop                           

;* Main input selection:
        dc.b      0,   k_16_TM,  10,     stop                           

        dc.b      0,    k_next,  61,     stop
        dc.b      0,    k_prev,  62,     stop

        dc.b      0,    k_anlg, 133,     stop

        dc.b    133,       k_1,  11,     stop 
        dc.b    133,       k_2,  11,     stop
        dc.b    133,       k_3,  11,     stop

     IFEQ    name-3     ;Allow analog inputs 4,5,6 with Signature+8 only

        dc.b    133,       k_4,  11,     stop
        dc.b    133,       k_5,  11,     stop
        dc.b    133,       k_6,  11,     stop

     ENDC

        dc.b    133,       k_7,  11,     stop
        dc.b    133,       k_8,  11,     stop
        dc.b    133,       k_9,  11,     stop
        dc.b    133,    k_anlg,  97,     stop           

;* HFEQ:
        dc.b      0,    k_HFEQ,   3,     stop                           
        dc.b      0, k_HFEQ_on,   3,     stop                           
        dc.b      0,k_HFEQ_off,   3,     stop                           

;* Speaker Configuration selection (Reference Cinema vs. Cinema 7.1 layouts)
        dc.b      0,k_spkr_cfg,  18,     stop                     ;View or change speaker config.
        dc.b      0,k_ref.cinema,86,     stop                     ;Select Reference Cinema.       
        dc.b      0,k_cinema71,  87,     stop                     ;Select Cinema 7.1

;* Decoding mode selection:
        dc.b      0,   k_70_TM,   9,     stop                     ;[Surr] | [Stereo] | [Mono] | [Matrix] | [Party]
                                                                  ;Note: Party is handled differently, as a 2nd press of [Surr]
;* [F] key:
        dc.b      0,       k_F, 134,     stop                           
        dc.b      7,       k_F, 135,     stop                           
        dc.b      8,       k_F, 136,     stop                           

;* [Enter] key:
        dc.b      0,   k_enter,  15,     stop                           
        dc.b      7,   k_enter,  38,     stop
        dc.b      8,   k_enter,  38,     stop
        dc.b    139,   k_enter, 139,     stop                     ;To re-initialize enter key

;* Brightness control of VFD display: [F][display up/down]
        dc.b    134,   k_tm_du,  27,     stop                     ;Normal mode                       
        dc.b    134,   k_tm_dd,  28,     stop                           
        dc.b    134,  k_tms_du,  27,     stop                           
        dc.b    134,  k_tms_dd,  28,     stop                           

        dc.b    135,   k_tm_du,  34,     stop                     ;Noise Seq. mode
        dc.b    135,   k_tm_dd,  35,     stop                           
        dc.b    135,  k_tms_du,  34,     stop                           
        dc.b    135,  k_tms_dd,  35,     stop                           

        dc.b    136,   k_tm_du,  36,     stop                     ;Static Noise mode
        dc.b    136,   k_tm_dd,  37,     stop                           
        dc.b    136,  k_tms_du,  36,     stop                           
        dc.b    136,  k_tms_dd,  37,     stop

;* Display selection: [display up/down]
        dc.b      0,   k_tm_du,  29,     stop                           
        dc.b      0,   k_tm_dd,  29,     stop                           
        dc.b      0,  k_tms_du,  31,     stop                           
        dc.b      0,  k_tms_dd,  32,     stop                           

;* Label changing: [Enter][ch. up/down]
        dc.b    139,  k_tm_sto,  33,     stop                           
        dc.b    139,  k_tm_rcl,  33,     stop                           

;* Display brightness: [Enter][disp. up/down]
        dc.b    139,   k_tm_du,  27,     stop
        dc.b    139,   k_tm_dd,  28,     stop                           

;* Speaker adjustment:
        dc.b      0,  k_adjust,   4,     stop                           

;* Noise sequencer mode:
        dc.b     0,k_noise_seq,   7,     stop                           

;* Static noise mode:
        dc.b     0,k_stat_noise,  8, k_16_TMS,     5,     stop          

;* Speaker selection in Adjustment and Spkr distances modes:
        dc.b      0,  k_16_TMS,   5,     stop

;* Exit from Adjust, Noise Seq, Static modes:
        dc.b      0,    k_exit,   6,     stop                           
        dc.b      7,    k_exit,  38,     stop
        dc.b      8,    k_exit,  38,     stop

;* Speaker selection in Adjustment and Speaker Distances:
;* XOver frequency select in System config screen:
;* Subwoofer selection in Speaker Config screen:
        dc.b      0, k_tms_sto,  14,     stop
        dc.b      0, k_tms_rcl,  14,     stop                           

;* X-Over mode:
        dc.b      0,  k_x_over,  19,     stop
        dc.b    137,  k_16_TMS,  20,     stop

;* Roll-off mode:
        dc.b      0,k_roll_off,  21,     stop
        dc.b    138,  k_16_TMS,  22,     stop

;* Power:
        dc.b      0,     k_pwr,  54,    k_pwr,   13,     stop           
        dc.b      7,     k_pwr,  55,    k_pwr,   13,     stop           
        dc.b      8,     k_pwr,  56,    k_pwr,   13,     stop           

        dc.b      1,     k_pwr,  78,     stop
        dc.b     13,     k_pwr,  76,     stop                           

        dc.b     13,  k_pwr_on,  76,     stop
        dc.b      0, k_pwr_off,  13,     stop                           

;* temp DTS: [n] (stdby mode only)
        dc.b     13,   k_16_TM,  77,     stop
        dc.b     13,  k_16_TMS,  77,     stop

;* temp MPEG: [F][n] (stdby mode only)
        dc.b    145,   k_16_TM,  96,     stop
        dc.b    145,  k_16_TMS,  96,     stop

;* Mute: [Mute]
        dc.b      0,    k_mute,  12,     stop
        dc.b      7,    k_mute,  12,     stop
        dc.b      8,    k_mute,  12,     stop

        dc.b      0, k_mute_on,  12,     stop
        dc.b      0,k_mute_off,  12,     stop
        dc.b     40,    k_mute,  20,     stop
        dc.b     48,    k_mute,  21,     stop
        dc.b     58,    k_mute,  22,     stop

;* Set volume level: [F][n][n]
        dc.b    134,     k_num,  16,     k_num,  17,     stop     ;Normal mode          
        dc.b    135,     k_num,  23,     k_num,  24,     stop     ;Noise Seq. mode           
        dc.b    136,     k_num,  25,     k_num,  26,     stop     ;Static Noise mode          

;* Screen up/down:
        dc.b      0,    k_scrn,  39,     stop
        dc.b      0, k_scrn_dn,  39,     stop
        dc.b      0, k_scrn_up,  39,     stop

;* V-Enhance toggle:
        dc.b      0,   k_v_enh,  40,     stop
        dc.b      0,k_v_enh_on,  40,     stop
        dc.b      0,k_v_enh_off, 40,     stop

;* Late Night compression:
        dc.b      0,      k_LN,  41,     stop
        dc.b      0,  k_LN_off,  88,     stop
        dc.b      0,  k_LN_low,  88,     stop
        dc.b      0,  k_LN_med,  88,     stop
        dc.b      0, k_LN_high,  88,     stop

;* Video button: (includes [Video][Tape/mon][n])
        dc.b      0,   k_video,  93,     stop
        dc.b    142,   k_video,  60,     stop
        dc.b    142,   k_16_TM,  42,     stop
        dc.b    147,   k_16_TM,  50,     stop

        dc.b    142,    k_tape, 150,     stop  
        dc.b    150,   k_16_TM,  59,     stop
        dc.b      0,    k_link,  51,     stop

;* Analog input 6 dB:
        dc.b      0,    k_anlg, 133,  k_tm_sto,  45,     stop
        dc.b      0,    k_anlg, 133,  k_tm_rcl,  45,     stop

;* Memory store:
        dc.b      0,  k_tm_sto,  57,     stop
        dc.b    143,   k_16_TM,  46,     stop
        dc.b    143,   k_70_TM,  46,     stop
        dc.b    143,  k_16_TMS,  46,     stop
        dc.b    143,  k_70_TMS,  46,     stop

;* Memory recall:
        dc.b      0,  k_tm_rcl,  58,     stop                                 
        dc.b    144,   k_16_TM,  47,     stop
        dc.b    144,   k_70_TM,  47,     stop
        dc.b    144,  k_16_TMS,  47,     stop
        dc.b    144,  k_70_TMS,  47,     stop

;* Memory restore defaults (stdby mode only):
        dc.b     13,       k_F, 145,  k_tm_rcl,  48,     stop
        dc.b    145, k_tms_rcl,  48,     stop
;        dc.b    146,       k_F,  49,     stop                     ;Now included in F-RCL

;* Tape/Mon selection:
        dc.b      0,    k_tape,  94,     stop
        dc.b    148,   k_16_TM,  52,     stop

     IFEQ    name-3     ;Analog Tape/Mon Signature+8 only

        dc.b    148,    k_anlg,  94,  k_16_TM,   53,     stop

     ENDC

;* Tape/Mon lockout: [F][Tape][n]             
        dc.b    134,    k_tape, 155,  k_16_TM,   95,     stop
        dc.b    155,   k_70_TM,  95,     stop

     IFEQ    name-3     ;Analog lockout in Signature+8 only

        dc.b    155,    k_anlg, 156,  k_16_TM,   92,     stop
        dc.b    156,   k_70_TM,  92,     stop

     ENDC

;* Auto Setup mode:
        dc.b     0,k_auto_setup, 79,     stop
        dc.b    79,      k_exit, 81,     stop

;* Auto Delay mode:
        dc.b     0,k_auto_delay, 80,     stop


;* Display number select: [Display][n][n]
        dc.b     0, k_display,  153,     stop                     ;RS-232 select
        dc.b   153,     k_num,   90,    k_num,   91,     stop     ;     /

;* Credits display
        dc.b     0, k_credits,   98,     stop

end_key_tab:


;*******************************************************************
;*
;*    R E M O T E    R E S P O N S E    S T A T E    T A B L E
;*
;* Not in P/T = 1 indicates command is not valid in Anlg Pass-Thru.
;*
;*******************************************************************
;*               state   state   stable  Not     response      
;*               before  after   time    in      routine
;*               service service         P/T
;----------------------------------------------------------------
state_tab:
        dc.b     1,    126,      0,      0
        dc.w                                     vol_up                         
        dc.b     2,    126,      0,      0
        dc.w                                     vol_dn                         
        dc.b     3,      0,      0,      1
        dc.w                                     hfeq                      
        dc.b     4,      0,      0,      1
        dc.w                                     adjust_mode                    
        dc.b     5,    126,      0,      1
        dc.w                                     select_spkrs                   
        dc.b     6,      0,      0,      0
        dc.w                                     exit_adjust                    
        dc.b     7,      7,      0,      1
        dc.w                                     noise_seq_mode                 
        dc.b     8,      8,      0,      1
        dc.w                                     static_noise_mode              
        dc.b     9,      0,      0,      0  ;1
        dc.w                                     mode_select                    
        dc.b     10,     0,      0,      0
        dc.w                                     do_dms                         
        dc.b     11,     0,      0,      0                                        
        dc.w                                     do_ams
        dc.b     12,   126,      0,      0
        dc.w                                     mute_togl                      
        dc.b     13,    13,      0,      0
        dc.w                                     into_standby                   
        dc.b     14,     0,   long,      0
        dc.w                                     deselection                                        
        dc.b     15,     0,   long,      0
        dc.w                                     enter_key                      
        dc.b     16,    16,   long,      0
        dc.w                                     get_1st                        
        dc.b     17,     0,      0,      0
        dc.w                                     set_comp_vol                   
        dc.b     18,     0,      0,      0
        dc.w                                     spkr_config        ;Ref.Cinema vs. Cinema 7.1 layout.
        dc.b     19,     0,   long,      1
        dc.w                                     x_over_mode                    
        dc.b     20,     0,      0,      1
        dc.w                                     x_over_sels                    
        dc.b     21,     0,   long,      1
        dc.w                                     roll_off_mode                  
        dc.b     22,     0,      0,      1
        dc.w                                     roll_off_sels                  
        dc.b     23,    23,   long,      0
        dc.w                                     get_1st                        
        dc.b     24,     7,      0,      0
        dc.w                                     set_comp_vol                   
        dc.b     25,    25,   long,      0
        dc.w                                     get_1st                        
        dc.b     26,     8,      0,      0
        dc.w                                     set_comp_vol                   
        dc.b     27,     0,      0,      0
        dc.w                                     bright_up
        dc.b     28,     0,      0,      0
        dc.w                                     bright_down                    
        dc.b     29,     0,      0,      0
        dc.w                                     display_updn_TM                
        dc.b     31,     0,      0,      0
        dc.w                                     display_dn_TMS                 
        dc.b     32,     0,      0,      0
        dc.w                                     display_up_TMS                 
        dc.b     33,     0,      0,      0
        dc.w                                     label_updn                     
        dc.b     34,     7,      0,      0
        dc.w                                     bright_up
        dc.b     35,     7,      0,      0
        dc.w                                     bright_down
        dc.b     36,     8,      0,      0
        dc.w                                     bright_up
        dc.b     37,     8,      0,      0
        dc.w                                     bright_down
        dc.b     38,     0,      0,      0
        dc.w                                     exit_noise                     
        dc.b     39,     0,      0,      0
        dc.w                                     screen_updn                    
        dc.b     40,     0,      0,      0
        dc.w                                     v_enh_togl                     
        dc.b     41,     0,      0,      1
        dc.w                                     ln_togl                        
        dc.b     42,     0,  short,      0
        dc.w                                     do_vms_vid                     
        dc.b     43,     0,      0,      1
        dc.w                                     xover_freq_select              
        dc.b     44,     0,      0,      0
        dc.w                                     theater_mode      ;LCD only.
        dc.b     45,     0,      0,      1
        dc.w                                     analog_atten                   
        dc.b     46,     0,      0,      1
        dc.w                                     memory_store                   
        dc.b     47,     0,      0,      1
        dc.w                                     memory_recall                  
        dc.b     48,    13,   long,      0
        dc.w                                     restore_fac_defs               
;;;;;;;;dc.b     49,    13,      0,      0
;;;;;;;;dc.w                                     clear_mems       ;Now included in restore factory defaults.              
        dc.b     50,     0,  short,      0                        
        dc.w                                     set_S
        dc.b     51,     0,      0,      0
        dc.w                                     link_av
        dc.b     52,     0,      0,      1
        dc.w                                     dig_tape
        dc.b     53,     0,      0,      1
        dc.w                                     ana_tape
        dc.b     54,    54,  short,      0
        dc.w                                     short_dummy
        dc.b     55,    55,  short,      0
        dc.w                                     short_dummy
        dc.b     56,    56,  short,      0
        dc.w                                     short_dummy
        dc.b     57,     0,   long,      0
        dc.w                                     do_store_mem   ;>>>> check on this later (to do with rcl) 
        dc.b     58,     0,   long,      0
        dc.w                                     do_store_mem   ;>>>> check on this later (to do with rcl)
        dc.b     59,     0,      0,      1
        dc.w                                     sm_tape_mon
        dc.b     60,     0,      0,      0
        dc.w                                     sm_s_toggle
        dc.b     61,     0,      0,      0
        dc.w                                     next_input   
        dc.b     62,     0,      0,      0
        dc.w                                     prev_input   
        dc.b     76,     1,      0,      0
        dc.w                                     from_standby                   
        dc.b     77,     0,      0,      0     
        dc.w                                     temp_dts                       
        dc.b     78,     0,      0,      0
        dc.w                                     shortcut_feats                 
        dc.b     79,    79,      0,      1
        dc.w                                     auto_setup_mode
        dc.b     80,    79,      0,      1
        dc.w                                     auto_delay_mode                
        dc.b     81,     0,      0,      0
        dc.w                                     abort_auto_set
        dc.b     86,     0,      0,      0
        dc.w                                     sel_RefCinema
        dc.b     87,     0,      0,      0
        dc.w                                     sel_Cinema71
        dc.b     88,     0,      0,      1
        dc.w                                     LN_determined
;;;;;;;;dc.b     89,   152,   long,      0
;;;;;;;;dc.w                                     bright_nums
        dc.b     90,    90,   long,      0
        dc.w                                     get_1st
        dc.b     91,     0,      0,      0
        dc.w                                     disp_nums
        dc.b     92,     0,      0,      1
        dc.w                                     ana_tape_lock_out
        dc.b     93,     0,   long,      0
        dc.w                                     vid_flash
        dc.b     94,     0,   long,      1
        dc.w                                     tape_flash
        dc.b     95,     0,      0,      1
        dc.w                                     dig_tape_lock_out
        dc.b     96,     0,      0,      0
        dc.w                                     temp_mpeg
        dc.b     97,     0,      0,      0
        dc.w                                     anlg_direct
        dc.b     98,     0,      0,      0
        dc.w                                     credits
                                  
;----------------------------------------------------------------
;*               state   state   stable  response      
;*               before  after   time    routine
;*               service service
;****************************************************************

end_state_tab:


;**************************************************************
;* Housekeeping prior to entering standby:
;*   Mutes DACs, resets DSPs, writes input designator labels
;*   and speaker distances to EEPROM (only if changed), take
;*   SwitchMaster into standby, clear temporary mode dedications.
;*
;* Called by the stand-by command (e.g., [Power][Power])
;*
;***
into_standby:
        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        delay   150*10                  ;Delay for mute.
        jsr     mute_Zs                 ;Mute Zorans
        jsr     init_Z1_version_flag    ;Determine if ZR38600 version is B6 or B7

        ldx     #regbase
        bclr    porta,x,#%00000010      ;DSP reset pin low

; The following feature, if implemented, would be a problem for users who
; need to go briefly to standby to temporarily dedicate an input for DTS CD
; or MPEG DVD. These users don't want their screen to go up or their amp
; to go through a restart cycle while changing DTS modes, etc.
;
;;;;;;;;bclr    porta,x,#%00010000      ;Make sure screen is up/amplifier is OFF.

        ldaa    #13
        staa    b_state
        staa    t_state                 ;Set up correct IR state

        ldaa    cold_start              ;If in cold start, do not RAM to EEPROM
        bne     into_s_3

        ldx     #ee_globals             ;Write designator labels
        ldab    #ee_desig_dig
        abx
        clrb
into_s_1:
        ldy     #Dig_labels
        aby
        ldaa    0,y
        jsr     write_ee 
        incb
        inx
        cmpb    #15                     ;Total number of inputs (6 dig, 6 ana, 6 anaPT)
        bne     into_s_1

        jsr     write_ee_dists          ;Write speaker distances

into_s_3:
        jsr     OUTCRLF
        ldaa    #PROMPT                 ;New user prompt
        jsr     outa

        ldab    #$ff
        jsr     send_sci                ;Send S/M into standby mode

        jsr     ONSCI                   ;Turn on SCI interrupts

        clr     t_dts_inp               ;Clear temporary dedication assignments
        clr     t_mpeg_inp
        clr     t_ac3_inp

        ldy     #Into_Stdby
        jsr     screen_out              ;Display "Entering Standby" message on VFD/LCD.
        delay   2000*10                 ;2 sec delay to see message.

        ldaa    #%11                    ;Set VFD to minimum brightness to
        jsr     VFD_bright_driver       ; prevent phosphor burn-in during standby.
        jmp     Standby_mode            ;Go into standby mode
                                        ;(stack is taken care of there)
write_ee:
        psha
        pshb
        pshx
        cmpa    0,x
        beq     write_ee_end            ;Only do if different

        jsr     EEBYTE                  ;Erase
        jsr     EEWRIT                  ;Program
write_ee_end:
        pulx
        pulb
        pula
        rts


;**************************************************************
;*
;* Housekeeping for exiting standby -- selects previous input and mode
;*  and initializes status parameters that are cleared over standby.
;*
;***
from_standby:
        ldx     #regbase
        bclr    porta,x,#%00000010      ;Reset pin low to force restart of DSPs, etc.
                                        ;(it is set hi in the Reset38 routine)

        bclr    porta,x,#%10000000      ;Deselect DTS to force fresh DTS start

        jsr     restore_globals         ;Get EEPROM global vbls
                                        ;(could be factory defs. if first time out)
        jsr     restore_locals          ;Restore locals from the last-used user memory.

        jsr     reset_38                ;Initialize Zorans (twice necessary)
        delay   100*10                  ;Delay 100 ms.
        jsr     reset_38              
        delay   100*10

        ldaa    #%00                    ;Set VFD to 100% brightness.
        jsr     VFD_bright_driver

        ldy     #Standby_scrn           ;Puts up model name briefly...
        jsr     screen_out
        jsr     beep1
        delay   1000*10                 ;Delay to see message.

        brset   DIP_imag,#%00000010,long_feats   ;If DIP SW2 is OFF (default), do nothing...
        jsr     screen_down              ;Else turn ON 12 V trigger.

long_feats:
        brset   DIP_imag,#%00000001,Eng1 ;Language?

Jap1:   ldy     #J_Long_features
        bra     stby_end

Eng1:   ldy     #Long_features          ;If cold start-up, do long features list

stby_end:
        sty     feats_ptr               ;Set pointer to features screens
        jsr     from_sby_flags
        jmp     Main_loop               ;Go to main loop
                                        ;(stack is taken care of there)
from_sby_flags:
        clr     screen_status1          ;Flag no restore needed       
        clr     screen_status2
        clr     flash_up
        clr     update_screen12         ;Clear flag for Input Data Status screen updates.
        clr     test_screen             ;No test screens up

        ldaa    #.SCREEN.Main      
        staa    screen_num              ;Start at main (=first) screen

        ldaa    #$ff
        staa    features                ;Flag features screens in progress

        clr     mute_status             ;Turn mute off
        clr     mute_cntr

        clr     late_nite
        clr     t_dts_inp
        clr     t_mpeg_inp
        clr     t_ac3_inp
        clr     auto_in_proc
        clr     auto_stage
        clr     noise_in_proc
        clr     noise_seq_timer
        clr     static_in_proc
        clr     z_error
        clr     err_star_ctr
        clr     clippage
        clr     slow_enc_timer

; Selecting one of the next two lines sets the EL Theater mode
; lamp timeout for LCD to be long or short:
;
;;;;;;;;clra                            ;Default = long time-out.
        ldaa    #$ff                    ;Default = short time-out.
        staa    theater

        ldaa    #17                     ;Set MPEG error counter to do
        staa    mpeg_err_ctr            ;correct unmutes if necessary

        clr     PCM_in_proc
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc

        ldx     #0
        stx     zoran_cntr
        stx     sticky_dts_ctr
        stx     sticky_ac3_ctr
        stx     vol_acc
        stx     crack_change

        jsr     set_all_lists           ;Set up all ram lists

        ldaa    #$ff
        staa    z_mode                  ;Force changing Zoran modes

        ldaa    #1
        staa    b_state                 ;Beginning state is features

        clr     kill_status             ;Request unkill.

        ldaa    #$ff
        staa    curr_mode_ac3           ;Set AC-3 sub mode to default sub mode.
        staa    curr_mode_dts           ;Ditto DTS.
        staa    curr_mode_mpeg          ;Ditto MPEG2.

        clr     IR_ready                ;Flush IR to avoid freeze-up problems

        jsr     OUTCRLF
        ldaa    #PROMPT                 ;New user prompt
        jsr     outa
        jsr     ONSCI                   ;Turn on SCI interrupts
        rts


;******************************************************************
;* Setting up lists for processors          
;***
set_all_lists:

zoran_peek_list:
        ldy     #peek_lst
        ldx     #peek_cmd21
        ldab    #14                     ;Block length
        jsr     blockcopy

zoran_crack_list:
        ldy     #crack_lst
        ldx     #crack_cmd2
        ldab    #11                     ;Block length
        jsr     blockcopy


xover_freq_list:
        ldaa    #$02
        clrb
xover_freq_loop:
        ldy     #peek_lst               
        staa    4,y                     ;Store address (low byte)
        psha
        pshb
        jsr     WR_Z2                   ;Get info from Z2
        ldaa    ret_inf+$0d             ;Pick up frequency
        ldy     #xover_freqs
        pulb
        aby
        staa    0,y                     ;Store in list

        pula
        inca
        inca
        inca                            ;New address in Z2

        incb                            ;New pointer into storage list
        cmpb    #10
        bne     xover_freq_loop

AC3_list_setup:
        ldx     #AC3_cmd1
        ldy     #AC3_lst                ;Set up AC3 command list
        ldab    #11                     ;Block length
        jsr     blockcopy

DTS_list_setup:
        ldx     #cntrl_5.1
        ldy     #DTS_lst                ;Set up DTS command list
        ldab    #16                     ;Block length
        jsr     blockcopy

ProL_list_setup:
        ldx     #prol_cmd1
        ldy     #prol_lst               ;Set up Pro Logic command list
        ldab    #11                     ;Block length
        jsr     blockcopy

MPEG_list_setup:
        ldx     #mpeg_cmd1
        ldy     #mpeg_lst               ;Set up MPEG2 command list
        ldab    #11                     ;Block length
        jsr     blockcopy

png_list_setup:
        ldx     #png_cmd1
        ldy     #png_lst                ;Set up pink noise gen. command list
        ldab    #11                     ;Block length
        jsr     blockcopy

ead_list_setup:
        ldx     #ead_cmd2
        ldy     #ead_lst                ;Custom bass management list
        ldab    #11                     ;Block length
        jsr     blockcopy

plltab_list_setup:
        ldx     #plltab_cmd1
        ldy     #plltab_lst
        ldab    #9                      ;Block length 
        jsr     blockcopy

pllcfg_list_setup:
        ldx     #pllcfg_cmd1
        ldy     #pllcfg_lst
        ldab    #4                      ;Block length
        jsr     blockcopy

hfeq_list:                              ;All inputs default to no hfeq
        ldy     #hfeq_dig_flag
        ldd     #$0000
        std     0,y
        std     2,y
        std     4,y
        std     6,y
        std     8,y
        std     10,y
        ldx     #regbase
        rts


;*************************************************************
;* Block Copy
;***
blockcopy:
        ldaa    0,x                     ;Get source byte
        staa    0,y                     ;Copy it to destination
        inx
        iny
        decb
        bne     blockcopy
        rts


;******************************************************************
;* Writing Factory defaults: "Locals" and "Globals"
;***
write_fac_defs:                         ;Write factory defaults (in EPROM)
                                        ;to EEPROM (starting at ee_cold_def)

        ldy     #f_cold_def             ;Factory default data
        ldx     #ee_cold_def            ;EEPROM storage space
fac_def_loop:
        ldaa    0,y
        cmpa    0,x
        beq     next_fac_def            ;Only writes the first with 1st power up.

        pshx
        pshy
        jsr     EEBYTE                  ;Erase EEPROM
        jsr     EEWRIT                  ;Write into EEPROM
        puly
        pulx

next_fac_def:
        inx
        iny
        cpy     #f_cold_def_end
        bne     fac_def_loop
        rts


;*******************************************
write_first_globals:                    ;Factory power up
        ldx     #ee_globals
        ldd     0,x
        cpd     #$ffff                  ;If empty, do factory defs
        beq     write_fst_gl_ok

        rts                             ;Otherwise, leave as they are


;*******************************************
write_fst_gl_ok:
        ldy     #f_chan_pol             ;Channel polarities first
        jsr     write_ee_pol
        
        ldy     #f_cold_def_globs       ;Copy Fac. def. globals to user globals
        ldx     #ee_globals
        jmp     fac_def_loop


;***********************************************************
;* Enter with an offset in B corresponding to the correct
;* slot in the ee_globals section of EEPROM.
;***
write_globals:
        ldx     #ee_globals
write_any:
        pshx                            ;If writing something else
        pshb
        abx
        cmpa    0,x
        beq     write_globals_end       ;Only do if different

        jsr     EEBYTE                  ;Erase
        jsr     EEWRIT                  ;Program byte in A.
write_globals_end:
        pulb
        pulx
        rts


;*******************************************
;* Restore Globals
;***
restore_globals:                        ;Load globals from EEPROM
        ldy     #ee_globals
        ldaa    0,y
        cmpa    #$ff                    ;Check if initialized
        bne     rest_globs_ok_1

        ldy     #ee_cold_def_globs      ;If not, do factory defaults

rest_globs_ok_1:
        ldaa    ee_spkr_cfg,y           ;Speaker Configuration
        staa    spkr_cfg        

        ldaa    DAC8_imag2
        anda    #$bf                    ;Mask out LF/RF balanced bit
        oraa    0,y                     ;Add in eeprom bit
        staa    DAC8_imag2
        jsr     update_DAC8_latch2

        ldaa    ee_LF_dst,y             ;Speaker distances
        anda    #%00111111
        staa    LFRF_dst

        ldaa    ee_LS_dst,y       
        anda    #%00111111
        staa    LSRS_dst

        ldaa    ee_CT_dst,y       
        anda    #%00111111
        staa    CT_dst

        ldx     #ee_chan_pol            ;Channel polarities
        ldd     0,x
        std     channel_pol
        ldd     2,x
        std     channel_pol+2
        ldd     4,x
        std     channel_pol+4

        ldaa    ee_bright,y             ;Display brightness.
        staa    bright_level   

        ldaa    ee_ven,y                ;Video vertical enhancer ON/OFF.
        staa    v_enh_flag
        beq     rest_globs_ven_off      ;Reassert V-Enh in SwitchMaster.

rest_globs_ven_on:
        ldab    #$19                    ;SwitchMaster command.
        bra     rest_globs_ok_2

rest_globs_ven_off:
        ldab    #$1a                    ;SwitchMaster command.

rest_globs_ok_2:
        jsr     send_sci                ;Update SwitchMaster.

        ldaa    ee_anlg_att,y     
        staa    ana_6dB
        jsr     set_anlg_att

        ldx     #ee_globals
        ldaa    0,x
        cmpa    #$ff
        bne     rest_globs_ok_3

        ldx     #ee_cold_def_globs
rest_globs_ok_3:
        ldab    #ee_desig_dig     
        abx
        ldy     #Dig_labels
        ldab    #15                     ;Block length
        jsr     blockcopy               ;Restore 15 labels (6 digital, 9 analog)
        rts


;*******************************************
;* Restore Locals (i.e., the ten user memories)
;*
;* Restores from last used memory.
;*
;***
restore_locals:                         ;Load Locals from EEPROM.
        ldaa    mem_num                 ;Get old memory number
        ldab    #16                     ;To avoid overflowing B, mulitply by
        mul                             ; half of mem size = 32, and add twice!
        ldx     #ee_memory
        abx
        abx
        ldaa    0,x                
        cmpa    #$ff                    ;Check if unfilled
        bne     old_mem_ok              ;If it is, all is well...

        ldaa    #22   ;'F'-$30????      ;If not, do factory defaults...
        staa    mem_num                 
        ldx     #f_cold_def
old_mem_ok:
        jsr     memory_recall_vbls      ;Get all local variables
        rts


;*******************************************
write_ee_pol:                           ;Enter with y as source
        clrb
        ldx     #ee_chan_pol            ;Write to EEPROM channel pol slots
write_ee_pol_loop:
        ldaa    0,y
        jsr     write_any
        iny
        incb
        cmpb    #5
        bne     write_ee_pol_loop
        rts


;******************************************************************
;* Memory storage and recalling
;***
;%% [STO][n]...
memory_store:
        ldaa    dec_key
        anda    #%01111111              ;Map TMS numbers onto TM numbers.
        staa    mem_num
        ldab    #16                     ;To avoid overflowing B, mulitply by
        mul                             ; half of mem size = 32, and add twice!
        ldx     #ee_memory
        abx
        abx                             ;Go to correct position in EEPROM

        ldaa    active_chs
        clrb
        jsr     write_any    

        ldaa    xover_chs
        incb
        jsr     write_any   

        ldaa    rolloff_chs
        incb
        jsr     write_any    

        ldaa    xover_val
        incb
        jsr     write_any    

store_vcp_loop:
        ldy     #vcp_l-4                ;!!!! Tricky addressing to keep pointers in step.
        incb
        aby
        ldaa    0,y
        jsr     write_any    
        cmpb    #vcp_addr_offset+3      ;!!!! Tricky addressing to keep pointers in step.
        bne     store_vcp_loop

        jsr     beepbeep
        rts
        

;%% [RCL][n]...
memory_recall:
        ldaa    dec_key
        anda    #%01111111              ;Map TMS numbers onto TM numbers.
        ldab    #$10                    ;To avoid overflowing B, mulitply by
        mul                             ; half of mem size and add twice!
        ldx     #ee_memory
        abx
        abx                             ;Go to correct position in EEPROM
        ldaa    0,x
        cmpa    #$ff                    ;If uninitialized,
        bne     mem_rcl                 ;Then go and do recall...

        jsr     LCD_init                ;Else flash up "Memory Vacant" sign...
        clra
        ldy     #memory_vacant
        jsr     SCREENS   

        ldaa    #1
        staa    screen_status1
        staa    flash_up
        jsr     click   
        rts


mem_rcl:
        ldaa    dec_key
        anda    #%01111111              ;Map TMS numbers onto TM numbers.
        staa    mem_num
        jsr     memory_recall_vbls      ;Put all variables back into RAM.
        jsr     LCD_init                ;Clear all blink fields etc.

        jsr     Features_selection_screen
        ldaa    #1
        staa    screen_status1
        staa    flash_up

        jsr     force_new_Z_flush       ;Do new Zoran mode (includes volumes)

        jsr     click 
        rts


;*******************************************
memory_recall_vbls:
        ldaa    0,x
        staa    active_chs
        ldaa    1,x
        staa    xover_chs
        ldaa    2,x
        staa    rolloff_chs
        ldaa    3,x       
        staa    xover_val

        ldab    #4                      ;Block length
        abx
        ldy     #vcp_l
        ldab    #vcp_addr_offset
        jsr     blockcopy
        rts


;%% [F][RCL]...
restore_fac_defs:
        ldaa    DAC8_imag2              ;Restore default Balanced/Single-Ended...
        anda    #%10001111       
        ldab    bal_single_save  
        andb    #%01110000       
        aba                      
        staa    DAC8_imag2       
        jsr     update_DAC8_latch2

        ldy     #f_cold_def_globs       ;Copy Fac. def. globals to user globals...
        ldx     #ee_globals    
        jsr     fac_def_loop   

        ldy     #f_chan_pol
        jsr     write_ee_pol
        jsr     beepbeep

;%% Old [F][RCL][F]
;%% (Now automatically follows [F][RCL])
; This routine can still be called by new_version (gives rise to six beep-beeps).
clear_mems:                             ;Clear out all user memories
        delay   100*10
        jsr     beepbeep       
        ldx     #ee_memory
clr_mems_loop:
        jsr     EEBYTE
        inx
        cpx     #ee_memory+320          ;32*10 = 320 bytes to clear.
        bne     clr_mems_loop

        ldx     #f_cold_def             ;Restore input-by-input fac-defs
        jsr     memory_recall_vbls
        rts


;%% Does automamtic "F-RCL" if new EPROM version code...        
new_version:
        ldaa    $8004
        ldab    $8006                   ;Get version number in EPROM
        cpd     $7e00                   ;Compare to EEPROM stored value
        beq     new_version_end         ;If same, version is the same, ok

        jsr     restore_fac_defs        ;If different, restore factory defs
        jsr     clear_mems              ;and clear memories

        ldaa    $8004
        ldx     #$7e00                  ;Don't change this address!!!
        jsr     write_ee                ;Write new version number at start of EEPROM

        ldaa    $8006
        ldx     #$7e01
        jsr     write_ee

new_version_end:
        rts


;******************************************************************
;* Temporary DTS assignment coming from standby
;*
;* NOTE: Only does temporary DTS if DIP SW3 is OFF (default).
;*
;***
temp_dts:
        brset   DIP_imag,#%00000100,temp_dts_OK  ;If DIP SW3 off then do temp DTS,

        ldaa    b_state                          ;Else remain in waiting in standby...
        staa    t_state
        rts

temp_dts_OK:
        jsr     temp_setup

;****   Select DTS correct channel  ****

        ldab    dec_key                 ;Get decimal key code in B
        andb    #$7f
        stab    t_dts_inp
        stab    ms_save                 ;Save new digital main source number
        ldaa    #8                
        sba                             ;Dec key code becomes dig. input # in A
        staa    MB_Main_mux             ;Select new digital input
                                        ;(NB. already muted if coming from standby)

        ldaa    #$ff                    ;Default dts mode
        staa    curr_mode_dts

        ldaa    #$ff
        staa    deem_off_flag   ;>>>    ;Turn Emphasis OFF in this case.

        jsr     LCD_init

        ldaa    #%00                    ;Set VFD to 100% brightness.
        jsr     VFD_bright_driver

        ldy     #Standby_scrn           ;Puts up model name briefly...
        jsr     screen_out
        jsr     beep1
        delay   1000*10                 ;Delay to see message.

        ldy     #temp_dts_scrn          ;Do a temp DTS screen
        jsr     screen_out

        des
        des
        des
        tsy

        ldaa    dec_key
        anda    #$7f
        adda    #$30
        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #$20
        staa    2,y
        ldaa    #31
        jsr     SCREENS                 ;Display correct number

        ldaa    #1
        staa    screen_status1          ;Do 2s count down on announcement screen

        lds     #ram_end                ;Reset stack (fresh start every time)
        clr     cold_start              ;If we reach here, warm start is next

        jsr     temp_mutes

        ;The following kludge unmutes the sound.
        ;Without it, VU works but no sound unless user does NEXT/PREV, etc.
        ldaa    #$7f
        staa    ms_save
        jsr     do_dms

        jmp     main_loop1              ;Go spinning around main loop


;******************************************************************
;* Temporary MPEG assignment coming from standby
;***
temp_mpeg:
        jsr     temp_setup

;****   Select MPEG correct channel  ****

        ldab    dec_key                 ;Get decimal key code in B
        andb    #$7f
        stab    t_mpeg_inp
        stab    ms_save                 ;Save new digital main source number
        ldaa    #8                
        sba                             ;Dec key code becomes dig. input # in A
        staa    MB_Main_mux             ;Select new digital input
                                        ;(NB. already muted if coming from standby)

        ldaa    #$ff                    ;Default mpeg mode
        staa    curr_mode_mpeg

        ldaa    #17                     ;Set MPEG error counter to do
        staa    mpeg_err_ctr            ;correct unmutes if necessary

        ldaa    #$ff
        staa    deem_off_flag   ;>>>    ;Turn Emphasis OFF in this case.

        jsr     LCD_init

        ldaa    #%00                    ;Set VFD to 100% brightness.
        jsr     VFD_bright_driver

        ldy     #Standby_scrn           ;Puts up model name briefly...
        jsr     screen_out
        jsr     beep1
        delay   1000*10                 ;Delay to see message.

        ldy     #temp_mpeg_scrn         ;Do a temp mpeg screen
        jsr     screen_out

        des
        des
        des
        tsy

        ldaa    dec_key
        anda    #$7f
        adda    #$30
        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #$20
        staa    2,y
        ldaa    #31
        jsr     SCREENS                 ;Display correct number

        ldaa    #1
        staa    screen_status1          ;Do 2 second count down on announcement screen

        lds     #ram_end                ;Reset stack (fresh start every time)
        clr     cold_start              ;If we reach here, warm start is next

        jsr     temp_mutes              ;Includes from_sby_flags

        ;The following kludge unmutes the sound.
        ;Without it, VU works but no sound unless user does NEXT/PREV, etc.
        ldaa    #$7f
        staa    ms_save
        jsr     do_dms

        jmp     main_loop1              ;Go spinning around main loop
        

;%% Used by DTS and MPEG temporary input dedication...
temp_setup:
        ldx     #regbase
        bset    porta,x,#%00000010      ;Reset pin hi

        bclr    porta,x,#%10000000      ;Deselect dts to force fresh DTS start

        jsr     restore_globals         ;Get EEPROM global vbls
                                        ;(could be factory defs. if first time out)
        jsr     restore_locals

        jsr     reset_38                ;Initialize Zorans (twice necessary)
        delay   100*10                  ;Delay 100 ms.
        jsr     reset_38              
        delay   100*10
        jsr     from_sby_flags

        clr     features
        clr     three_secs
        clr     cold_start
        clr     b_state                 ;Clear IR state (we are out of features)
        clr     t_state
        rts


temp_mutes:
        jsr     get_auto_flag           ;Set up dts processing
        jsr     reassert_ip             ;Reassert 4226 mode and Zoran mode
        ldaa    locked                  ;If unlocked, do not unmute pmds
        bne     .kill_off_temp
        brset   mute_status,#1,.kill_off_temp       ;Check for user mute

        jsr     unmute_all              ;Unmute if no user mute asserted.

.kill_off_temp:
        jsr     kill_off                ;Unkill now.
        clr     kill_status      

        jsr     .do_linked_AV_sw
        jsr     do_sm_vid_sels          ;Send SM video control codes
        rts


;******************************************************************
;* Sends B register out via SCI, after setting MSB in data byte
;* Use to bypass SwitchMaster RS232 processing.
;* Preserves all registers.
;***
;send_sci_msb:
;        pshb
;        ldx     #regbase
;        orab    #%10000000              ;Set MSB
;        brclr   scsr,x,#%10000000,*
;        stab    scdr,x                  ;Send byte
;        pulb                          
;        rts                         ;** Return **


;******************************************************************
send_sci:
        ldx     #regbase
        brclr   scsr,x,#%10000000,*
        stab    scdr,x                  ;Send byte
        rts                         ;** Return **
        

;******************************************************************
;* Enter key - Takes you into main screen if not already there
;*             Puts up bar labels if in VU Meter
;***
enter_key:
        ldaa    screen_num
        cmpa    #.SCREEN.VU_meter       ;Check if in VU meter screen
        beq     enter_key_labels        ;If so, do labels

        cmpa    #.SCREEN.Main           ;Check if in Main screen already
        beq     enter_key_2             ;If so, prepare for STO/RCL or CH up/dn

        cmpa    #.SCREEN.Spkr_Dist      ;Check if coming from Speaker Dist. screen
        bne     enter_key_1

        jsr     write_ee_dists          ;If so, write EE if necessary

enter_key_1:
        ldaa    #.SCREEN.Main      
        staa    screen_num
        clr     screen_status1
        clr     screen_status2
        clr     screen_status3          ;Reset all timers
        jsr     LCD_init                ;Clear screen
        jsr     display_scrn            ;Put up main_screen
        clr     ir_tout                 ;Clear long time-out
        rts                             ;Go home

enter_key_2:
        ldaa    #139
        staa    t_state                 ;Set current state for CH up/dn possibility
        clr     b_state
        rts

enter_key_labels:
        ldaa    #1
        staa    three_secs              ;Put up bar labels

enter_key_end:
        rts
        

;******************************************************************
display_updn_TM:
        ldaa    #%00111111
        staa    curr_chs

        clr     xover_rolloff

        ldaa    screen_num              ;See if coming from Speaker Distances screen
        cmpa    #.SCREEN.Spkr_Dist  
        bne     display_updn_tm1

        jsr     write_ee_dists          ;If so, write EE if necessary

display_updn_tm1:
        ldaa    screen_num
        cmpa    #.SCREEN.VU_meter   
        bls     in_TM_updn

in_TMS_updn:
        ldaa    #.SCREEN.Main           ;If in TMSetup screens, go into Main screen
        bra     disp_TM

in_TM_updn:
        cmpa    #.SCREEN.VU_meter   
        bne     to_TM2                  ;If in screen 2, go into screen 1

to_TM1:
        ldaa    #.SCREEN.Main       
        bra     disp_TM

to_TM2:
        ldaa    #.SCREEN.VU_meter   
disp_TM:
        staa    screen_num
        jsr     LCD_init                ;Clear old screen
        jsr     display_scrn            ;Put up new screen
disp_up_end:
        rts


;******************************************************************
display_up_TMS:
        ldaa    #%00111111
        staa    curr_chs

        clr     xover_rolloff

        ldaa    screen_num              ;See if coming from Speaker Distances screen
        cmpa    #.SCREEN.Spkr_Dist  
        bne     display_up_tms1

        jsr     write_ee_dists          ;If so, write EE if necessary

display_up_tms1:
        ldaa    screen_num
        cmpa    #Max_screens            ;!!!!!!!
        beq     disp_upS_end

;Note: The method used below to reject screens requires a valid last screen.
disp_upS_1:
        inc     screen_num
        ldaa    curr_pass_mode          ;If not in analog pass-thru mode,
        beq     disp_upS_2              ; proceed as normal, and show screen,
                                        ; else reject certain screens...
        ldaa    screen_num              
        cmpa    #.SCREEN.Spkr_Adj       ;Don't show Adjust screen.
        beq     disp_upS_1

        cmpa    #.SCREEN.Spkr_Cfg       ;Don't show Spkr Cfg screen.
        beq     disp_upS_1

        cmpa    #.SCREEN.Bass_Man       ;Don't show Bassman screen.
        beq     disp_upS_1

        cmpa    #.SCREEN.Spkr_Dist      ;Don't show Spkr Dists screen.
        beq     disp_upS_1

        cmpa    #.SCREEN.Anlg_Atten     ;Don't show Anlg Atten screen.
        beq     disp_upS_1

        cmpa    #.SCREEN.Sys_Config     ;Don't show Sys Config screen.
        beq     disp_upS_1

        cmpa    #.SCREEN.Feat_Sel       ;Don't show Feature Selection screen.
        beq     disp_upS_1

        cmpa    #.SCREEN.Inp_Data_Stat  ;Don't show Input Data Status screen.
        beq     disp_upS_1

disp_upS_2:
        jsr     LCD_init
        jsr     display_scrn
        ldaa    screen_num
        cmpa    #.SCREEN.Bass_Man       ;Flag that we are already in Bass Man screen
        bne     disp_upS_3      

        ldaa    #$ff
        staa    xover_rolloff
disp_upS_3:
disp_upS_end:
        rts


;******************************************************************
display_dn_TMS:
        ldaa    #%00111111
        staa    curr_chs

        clr     xover_rolloff

        ldaa    screen_num              ;See if coming from Speaker Distances screen
        cmpa    #.SCREEN.Spkr_Dist  
        bne     display_dn_tms1

        jsr     write_ee_dists          ;If so, write EE if necessary

display_dn_tms1:
        ldaa    screen_num
        cmpa    #.SCREEN.Main       
        beq     disp_dnS_end

;Note: The method used below to reject screens requires a valid 1st screen.
disp_dnS_1:
        dec     screen_num
        ldaa    curr_pass_mode          ;If not in analog pass-thru mode,
        beq     disp_dnS_2              ; proceed as normal, and show screen,
                                        ; else reject certain screens...
        ldaa    screen_num              
        cmpa    #.SCREEN.Spkr_Adj       ;Don't show Adjust screen.
        beq     disp_dnS_1

        cmpa    #.SCREEN.Spkr_Cfg       ;Don't show Spkr Cfg screen.
        beq     disp_dnS_1

        cmpa    #.SCREEN.Bass_Man       ;Don't show Bassman screen.
        beq     disp_dnS_1

        cmpa    #.SCREEN.Spkr_Dist      ;Don't show Spkr Dists screen.
        beq     disp_dnS_1

        cmpa    #.SCREEN.Anlg_Atten     ;Don't show Anlg Atten screen.
        beq     disp_dnS_1

        cmpa    #.SCREEN.Sys_Config     ;Don't show Sys Config screen.
        beq     disp_dnS_1

        cmpa    #.SCREEN.Feat_Sel       ;Don't show Feature Selection screen.
        beq     disp_dnS_1

        cmpa    #.SCREEN.Inp_Data_Stat  ;Don't show Input Data Status screen.
        beq     disp_dnS_1

disp_dnS_2:
        jsr     LCD_init                ;Clear old screen
        jsr     display_scrn            ;Put up Main screen
        ldaa    screen_num
        cmpa    #.SCREEN.Bass_Man       ;Flag that we are already in Bass Man screen
        bne     disp_dnS_3      

        ldaa    #$ff
        staa    xover_rolloff
disp_dnS_3:
disp_dnS_end:
        rts


;******************************************************************
next_input:
        ldaa    ms_save
        brset   ms_save,#%10000000,.nxt_anlg

.nxt_dig:
        cmpa    #6
        blt     .inc_dig

        clra
.nxt_anlg:
        anda    #$7f

        IFNE    name-3        ;OVATION-8 or SIGNATURE-8

           cmpa    #3         
           blt     .inc_anlg

           cmpa    #3
           bne     .nxt_anlg2

           adda    #3           ;Skip over A4, A5, A6.

        ENDC

.nxt_anlg2:
        cmpa    #9          
        blt     .inc_anlg   

        clra
        bra     .nxt_dig

.inc_dig:
        inca
        staa    dec_key
        jmp     do_dms

.inc_anlg:
        inca
        staa    dec_key
        jmp     do_ams


;******************************************************************
prev_input:
        ldaa    ms_save
        brset   ms_save,#%10000000,.prev_anlg

.prev_dig:
        cmpa    #1
        bgt     .dec_dig

        ldaa    #10
        bra     .dec_anlg

.prev_anlg:
        anda    #$7f
        cmpa    #1
        bgt     .dec_anlg

        ldaa    #7
        bra     .prev_dig

.dec_dig:
        deca
        staa    dec_key
        jmp     do_dms

.dec_anlg:
        deca

        IFNE    name-3        ;OVATION-8 or SIGNATURE-8

           cmpa    #4         
           blt     .dec_anlg2

           cmpa    #6
           bne     .dec_anlg2

           suba    #3           ;Skip over A6, A5, A4.

        ENDC

.dec_anlg2:
        staa    dec_key
        jmp     do_ams


;******************************************************************
;* Theater mode
;***
theater_mode:
           ldaa    ps_frame
           cmpa    #k_tm_dd
           beq     tmode_on

tmode_off: clr     theater
           rts

tmode_on:  ldaa    #$ff
           staa    theater
           rts


;******************************************************************
;* Analog attenuation
;***
analog_atten:
        brclr   ms_save,#%10000000,anlg_att_rts     ;Only do this if in Analog

        jsr     anlg_ch_to_bit          ;Convert channel to bit in A
anlg_att_updn:
        tab                             ;Bit to change is in B
        ldaa    ps_frame
        cmpa    #k_tm_sto
        beq     anlg_atten_0dB

anlg_atten_6dB:
        orab    ana_6dB                 ;Set bit high to show attenuation
        bra     anlg_atten_end

anlg_atten_0dB:
        comb
        andb    ana_6dB                 ;Mask out the correct bit
anlg_atten_end:
        stab    ana_6dB                 ;Store the result

        tba
        ldab    #ee_anlg_att            ;Store in EEPROM
        jsr     write_globals
        jsr     set_anlg_att            ;Tell 4226 about attenuation
        jsr     Analog_input_atten_screen
        ldaa    screen_num
        cmpa    #.SCREEN.Anlg_Atten 
        beq     anlg_att_rts            ;If already in Anlg Input Atten screen, don't flash

        ldaa    #1
        staa    screen_status1
        staa    flash_up
anlg_att_rts:
        rts


set_anlg_att:
        jsr     anlg_ch_to_bit          ;Convert channel to bit in A
        tab
        andb    ana_6dB
        bne     set_ana_att_6

set_ana_att_0:
        IFNE    name-3
          ldab    #$0a                  ;0 dB attenation
        ELSEC
          bset    S_K6_imag,#1          ;Set Sig+8 anlg atten to 0dB
        ENDC
        bra     set_4226_ana_att


set_ana_att_6:

        IFNE    name-3
          ldab    #0                    ;-6 dB attenutation
        ELSEC
          bclr  S_K6_imag,#1            ;Set Sig+8 anlg atten to -6dB
        ENDC


set_4226_ana_att:

        IFNE    name-3
          ldaa    #12
          jsr     WR_CS4226             ;Write Input control byte (12)
        ELSEC
          jsr   update_S_K6             ;Click S_K6 relay for Sig+8.
        ENDC

        ldx     #regbase
        rts

anlg_ch_to_bit:
        ldab    ms_save                 ;Get current channel
        andb    #%01111111
        ldaa    #%00000001
anlg_to_bit:
        decb                            ;Get correct bit to be changed
        beq     anlg_to_bit_end

        asla
        bra     anlg_to_bit

anlg_to_bit_end:
        rts


;******************************************************************
;* Set Zoran Version Flag for B6/B7/A2 versions.
;*
;*Version Strings:
;*                       vv    vv
;* 38600  B6   ---    00 30 20 04
;*
;* 38600  B7   ---    00 50 20 06
;*
;* 38601  A2   ---    A1 20 10 02
;*
;***
init_Z1_version_flag:
        bset    Z_ver_flag,#$ff         ;Set flag.
        ldy     #ver_cmd
        jsr     WR_Z1
        ldy     #ret_inf
        ldaa    4,y
        cmpa    #$30
        bne     Not_B6  

        ldaa    6,y
        cmpa    #$04
        bne     Not_B6

        clr     Z_ver_flag              ;Clear flag if version B6.
Not_B6: rts


;**************************************************************
;**************************************************************
;*
;* Source select stuff
;*
;*
;**************************************************************
;**************************************************************


;**************************************************************
do_dms:  
        ldab    dec_key                 ;Get decimal key code in B
        ldaa    #8
        sba                             ;Dec key code becomes main MB mux no. in A.
        cmpb    ms_save                 ;If not selected, go ahead
        bne     do_dms_1

        ldaa    screen_num              ;If already selected, check if we are
        cmpa    #.SCREEN.Main           ; in Main screen
        beq     .dms_endbr              ;If so, do nothing.
        jmp     now_scrn_1              ;Put up Main screen again and exit.

.dms_endbr:
        jmp     .dms_end 

do_dms_1:
        stab    ms_save                 ;Save new digital main source number
        staa    MB_Main_imag            ;Select new digital input

        jsr     digital_8_mode          ;Assert digital mode to disable any anlg pass-thru.
        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        delay   150*10                  ;Delay for mute.

        ldx     #regbase
        bset    porta,x,#%00000001      ;Set DPD bit for digital input mode (NOTE: EOS all!!!)
                                        ;(this is done after the mute to avoid potential hiss)

        jsr     update_MB_Main_mux

        clr     PCM_in_proc             ;Clear all processing flags
        clr     AC3_in_proc             ;to force boot of Zoran in correct mode
        clr     MPEG_in_proc
        clr     DTS_in_proc

        ldaa    #17                     ;Set MPEG error counter to do
        staa    mpeg_err_ctr            ;correct unmutes if necessary

        ldd     #0
        std     sticky_dts_ctr          ;Flush sticky DTS count down timer
        std     sticky_ac3_ctr

        jsr     reassert_ip             ;Reassert 4226 and Zoran mode
        jsr     now_scrn_1              ;Select new main screen.

        ldaa    locked                  ;If unlocked, do not unmute pmds
        bne     .kill_off               ;Other models, all ok! (different DACs)
        brset   mute_status,#1,.kill_off      ;Check for user mute

do_dms_unmutes:
        jsr     unmute_Zs
        jsr     unmute_all              ;Unmute if no user mute asserted.

.kill_off:
        jsr     kill_off                ;Unkill now.
        clr     kill_status      

.kill_off_vids:
        jsr     .do_linked_AV_sw        ;Hardware video selections
do_dms_end:
        jsr     do_sm_vid_sels          ;Send SM video control codes       
.dms_end:
        rts


enc_vid_vbl_update:                     ;In Encore, if switching into a no-lock input,
                                        ; must update curr_vid variable!!
        jsr     pick_link
        bra     do_dms_end


;%% Do linked digital A/V switching:
pick_link:                                 ;Picking link from EEPROM
        ldab    dec_key
        decb
        addb    #ee_av_links
        ldy     #ee_globals
        aby                                     
        ldaa    0,y                        ;Get digital A/V link
        staa    curr_vid                   ;Update current video input.
        rts

.do_linked_AV_sw:
        bsr     pick_link                  ;Pick up EEPROM link
        anda    #$7f

        IFNE    name-3     ;OVATION-8 or SIGNATURE-8

           cmpa    #4                      ;If video number > 3
           bhs     .do_l_av_end            ; then go out...

           brclr   0,y,#$80,.do_EO_v       ;Test msb of current A/V link.
           adda    #3                      ;Add 3 if S-video.
.do_EO_v:
           deca
           staa    EO_Vmux_imag            ;0-5
           jsr     update_EO_Vmux

        ENDC

.do_l_av_end:
        rts                             ;** Return **


;**************************************************************
reassert_ip:
        jsr     init_4226_pll           ;Init. CS4226 PLL mode
        delay   30*10                   ;Delay to let CS4226 catch its breath
        ldaa    #11                     ;Set ADC control byte (11)
        ldab    #$40                    ; to digital output
        jsr     WR_CS4226 
        delay   100*10                  ;A further delay to complete calibration?

;%% Check if unlocked (PLL locked if locked=0; PLL unlocked if locked=1):
        jsr     check_if_unlocked       ;If unlocked, bypass freaked check 3x.
        bne     .unlocked_end

        jsr     check_if_unlocked
        bne     .unlocked_end

        jsr     check_if_unlocked
        bne     .unlocked_end
        bra     .check_if_freaked

.unlocked_end:
        delay   150*10
        jsr     unpack_vol              ;To match cumulative locked delays

        ldaa    #$ff                    ;Flush Zoran mode
        staa    z_mode
        bra     .reassert_end

;%% Check if freaked:
.check_if_freaked:
        jsr     check_if_freaked
        bne     .notok4226            

        jsr     check_if_freaked
        bne     .notok4226      

        jsr     check_if_freaked
        bne     .notok4226      
        bra     .ok4226

.notok4226:
        jsr     chirp_H                 ;Sound the alert.
        jsr     init_4226_xtal          ;Put 4226 into crystal mode
        rtint   ON                      ;RTI on  ////
        delay   200*10                  ; Delay to recal.
        jmp     reassert_ip             ;Else try again...

;%% CS4226 OK:
.ok4226:
        jsr     get_auto_flag           ;Determine bitstream info
        clr     screen_status1
        jsr     force_new_Z             ;Force Zoran updates
        jsr     unpack_vol

.reassert_end:
        rts


;**************************************************************
now_scrn_1:
        ldaa    #.SCREEN.Main                  
        staa    screen_num         
        jsr     display_scrn            ;Put new screen up
        clr     screen_status1
        rts


check_if_unlocked:
        ldaa    #17
        jsr     RD_CS4226               ;Get locked status from byte 17.
        anda    #%00010000
        rts


check_if_freaked:
        ldaa    #2
        jsr     RD_CS4226               ;Get freaked status from byte 2.
        anda    #%01000000
        rts


;**************************************************************
;[Anlg][Anlg] takes you straight to A8 (2-channel anlg pass-thru)
anlg_direct:
        ldaa    #8                      ;Select A8
        staa    dec_key
        jmp     do_ams


;**************************************************************
do_ams:
        ldab    dec_key                 ;Get decimal key code

;* The following code is not needed now, since inputs 4,5,6 have
;* already been rejected by the remote command state machine:
;        IFNE    name-3   ;OVATION-8 or SIGNATURE-8.
;           cmpb    #3                      ;Ovation-8 & Signature-8 have only 3 analog inputs
;           bhi     .ams_end1
;        ENDC

        orab    #%10000000              ;Set analog flag
        cmpb    ms_save
        bne     do_ams_1                ;If not already selected, change

        ldaa    screen_num
        cmpa    #.SCREEN.Main       
        beq     .ams_end1               ;If Main screen already up, do nothing
        jmp     now_scrn_1              ;Else put up Main screen again and return...

.ams_end1:
        jmp     .ams_end

do_ams_1:
        stab    ms_save                 ;Save new analog input number
        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        delay   150*10                  ;Delay for mute.

        IFEQ    name-3   ;SIGNATURE+8  !!! Moved from above to prevent TSHHH!

           ldx     #regbase
           bclr    porta,x,#%00000001      ;Clear DPD bit for analog input.

        ENDC

        ldd     #0
        std     sticky_dts_ctr          ;Flush sticky DTS count down timer
        std     sticky_ac3_ctr

        ldaa    #1                      ;Treat analog as PCM
        staa    PCM_in_proc
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc


        jsr     init_4226_xtal          ;Put 4226 into crystal mode
        rtint   ON                      ;RTI on  ////
        delay   100*10                  ;Give time to recal.

        ldab    dec_key
        cmpb    #7
        beq     .6_ch

        cmpb    #8
        beq     .2_ch

        cmpb    #9
        beq     .8_ch

        jsr     digital_8_mode          ;Non pass-thru analog signals use digital mode.
        bra     .ams_cont1

.2_ch:  jsr     passthru_2_mode
        bra     .ams_cont2

.8_ch:  jsr     passthru_8_mode
        bra     .ams_cont2

.6_ch:  jsr     passthru_6_mode
        bra     .ams_cont2

.ams_cont1:
        IFEQ    name-3   ;SIGNATURE+8

;%% Update Signature+8 analog mux:

           ldab    dec_key
           decb                            ;Translate decimal key code to analog input select code.
           stab    SBP_Main_mux            ;Select new analog input

        ELSEC             ;OVATION-8 or SIGNATURE-8

;%% Update Ovation-8 and Signature-8 analog mux:

           ldab    dec_key                 ;Convert input number to 4226 protocol
           decb                    
           lslb
           lslb
           lslb
           ldaa    #11                     ;Set ADC control byte (11) to Analog pair
           jsr     WR_CS4226

        ENDC

.ams_cont2:
        delay   120*10                  ;Time for Z1 to detect AC-3 submode.
                                        ; and to match cumulative digital select delays (includes 90 extra ms)    
        jsr     force_new_Z             ;Select new mode in Zorans

        jsr     unpack_vol
        jsr     set_anlg_att            ;Set atten. if neccesary
        jsr     now_scrn_1              ;Select new main screen.

        brset   mute_status,#1,.kill_off2     ;Check for user mute

        jsr     unmute_all

.kill_off2:
        jsr     kill_off                ;Unkill now.
        clr     kill_status      

;%% Do linked analog A/V switching:
.do_linked_anlg_AV_sw:
        ldab    dec_key
        decb
        addb    #ee_ana_av_links        ;Anlg link save area.
        ldy     #ee_globals
        aby
        ldaa    0,y                     ;Get A/V link
        staa    curr_vid                ;Update current video input.
        anda    #$7f

        IFNE    name-3     ;OVATION-8 or SIGNATURE-8

           cmpa    #4                      ;If video number > 3 
           bhs     .do_anlg_SM_v           ; then go out...
                                          
           brclr   0,y,#$80,.do_anlg_EO_v  ;Else if S-video,
           adda    #3                      ; add 3.
.do_anlg_EO_v:
           deca                         
           staa    EO_Vmux_imag            ;0-5.
           jsr     update_EO_Vmux

        ENDC

.do_anlg_SM_v:
        jsr     do_sm_vid_sels          ;Send SM video control codes

.ams_end:
        rts                         ;** Return **


;************************************************************
;* Video stuff
;***
do_sm_vid_sels:
        ldab    #$16                            ;C video command for SM
        brclr   curr_vid,#$80,do_sm_vid_0       ;Send as is if C vid.
        addb    #$80                            ;Add MSB if S video

do_sm_vid_0:
        jsr     send_sci                ;Output control code to SM
        ldab    curr_vid
        andb    #$7f                    ;Mask out MSB
        decb
        addb    #$10                    ;$10-$15 are video selection numbers
        jsr     send_sci                ;Output it to S/M
        rts


do_sm_tm_sels:                          ;Enter with selection in A
        adda    #$10                    ;Convert selection to control code

        ldab    #$17
        jsr     send_sci                ;SM tape-mon video code
        tab
        jsr     send_sci                ;Send out selection control code
        rts
        
do_vms_vid:             
        ldaa    dec_key             
        cmpa    #7                      ;Video 1 to 6 only (includes E/O with S/M)
        bhs     do_not_vms

        anda    #$7f            
        staa    curr_vid        

        jsr     do_sm_vid_sels          ;Send SM video control codes

        ldaa    #.SCREEN.Main           ;Bring up main screen
        staa    screen_num
        jsr     display_scrn
        jsr     show_vid_sel

        clr     b_state
        ldaa    #147                    ;Check for repeated number key (S video)
        staa    t_state

        ldaa    curr_vid
        deca
        staa    EO_Vmux_imag            ;Note: Used to keep track of Sig. 

        IFNE    name-3     ;OVATION-8 or SIGNATURE-8

           cmpa    #3                      ;Video 1,2,3 for EO only (#'s are 0,1,2)
           bhs     .end_vms  

           jsr     update_EO_Vmux

        ENDC
.end_vms:
        rts


do_not_vms:
        clr     b_state
        clr     t_state
        rts


set_S:  ldaa    EO_Vmux_imag            ;Note: We use contents to keep track of Sig.
        inca
        cmpa    dec_key                 ;If same number, set as composite
        beq     set_S_ok
        jmp     do_dms                  ;Go and set Digital input for case of Video-1-2

set_S_ok:
        ldaa    dec_key             
        cmpa    #7                      ;Video 1 to 6 only (includes E/O with S/M)
        bhs     do_not_vms          

        oraa    #$80                    ;Set msb for S-video.
        staa    curr_vid        
        jsr     do_sm_vid_sels          ;Send SM video control codes

        IFNE    name-3     ;OVATION-8 or SIGNATURE-8

           ldaa    curr_vid
           anda    #$7f                    ;Mask msb.
           cmpa    #4
           bhs     set_S_end

           adda    #3                      ;Convert to
           deca                            ; S video 3,4,5 for O-8/S-8
           staa    EO_Vmux_imag
           jsr     update_EO_Vmux

        ENDC

set_S_end:
        jsr     show_vid_sel
        rts


sm_tape_mon:
        ldaa    dec_key                 ;Get number selection
        deca
        jsr     do_sm_tm_sels           ;Send out SM tape-mon code
        rts


;*** Flash up current video selection
vid_flash:
        clr     b_state
        ldaa    #142                    ;Get ready for number push
        staa    t_state

        ldaa    screen_status1          ;Check for Big Nums
        bne     vid_flash_0

        ldaa    screen_num
        cmpa    #.SCREEN.Main       
        beq     vid_flash_1

vid_flash_0:
        jsr     LCD_init
        clr     screen_status2
        clr     screen_status3          ;Flush other timers
        ldaa    #.SCREEN.Main           ;Bring up Main screen
        staa    screen_num
        jsr     display_scrn

vid_flash_1:
        jsr     show_vid_sel            ;Show current selection
        jsr     do_sm_vid_sels          ;Reassert SM video selection
        rts


;*************************************************************************
;*
;* LINK AV
;*
;***
link_av:
        ldaa    screen_num
        cmpa    #.SCREEN.Main
        bne     .avlink_end             ;Skip a/v link if not in Main screen.

        ldaa    flash_up
        bne     .avlink_end             ;Don't do another link while the a/v
                                        ; link screen is flashed up.
                                        ; (Stops beep-beep repeating)
        ldx     #ee_globals
        ldab    #ee_dig_av_links
        brclr   ms_save,#$80,link_dig   ;Check if digital or analog.

link_anlg:
        ldab    #ee_ana_av_links
link_dig:
        abx
        ldab    ms_save
        andb    #$7f
        decb
        abx                             ;Update pointer to EEPROM a/v link slot.
        ldaa    curr_vid                ;msb is set if S-video.
        clrb                            ;B is used by the write_any routine.
        jsr     write_any
        ldaa    #1                      
        staa    flash_up                 
        brclr   ms_save,#$80,d_av_scrn

a_av_scrn:
        ldaa    ms_save
        anda    #$7f
        cmpa    #6
        bge     apt_av_scrn

        jsr     display11
        bra     links_scrn

apt_av_scrn:
        jsr     display11a
        bra     links_scrn

d_av_scrn:
        jsr     display10
links_scrn:
        jsr     beepbeep               ;Signal that a/v link has been saved.
        ldaa    #1
        staa    screen_status1         ;Note: can't use screen_status2 or 3 here
.avlink_end:                           ; to get longer flash up, because flash_up 
        rts                            ; stays set to $01, and so prevents further
                                       ; link a/v commands until a screen_status1-type
                                       ; flash-up is done, which correctly leads to
                                       ; flash_up becoming zero at the end of the timeout.

;**********************************************************
;*
;*  SHOW VIDEO SELECTION
;*
;***
show_vid_sel:
        tsx
        xgdx
        subd    #9                ;Allocate local variables on stack.
        xgdx
        txs
        ldaa    #':'
        staa    0,x
        ldaa    curr_vid
        brset   curr_vid,#$80,show_s_sel       ;If MSB set, it is S video

show_c_sel:
        adda    #$30
        staa    2,x     
        ldaa    #'C'
        staa    1,x
        bra     show_vid_rest

show_s_sel:
        anda    #$7f            
        adda    #$30
        staa    2,x
        ldaa    #'S'
        staa    1,x

show_vid_rest:
        ldaa    #$20
        staa    3,x
        ldaa    #'|'
        staa    4,x
        ldd     #$2020
        std     5,x
        std     7,x

        tsy
        ldaa    #26
        jsr     SCREENS

        ldaa    #1
        staa    screen_status1
        staa    flash_up

        tsx
        xgdx
        addd    #9                 ;Deallocate local variables.
        xgdx
        txs
        rts


;************************************************************
;*
;* TAPE SELECTION
;*
;***
dig_tape:
        ldab    dec_key
        cmpb    ee_globals+ee_dig_lockout  ;See if selection locked out
        beq     locked_out

        stab    dig_tape_inp

        ldaa    #8
        sba                             ;Convert to tape mux numbers
        staa    MB_Tape_imag
        jsr     update_MB_Tape_mux

        jsr     show_dig_tape_sel       ;Flash up selection

        clrb                            ;Pick up digital AV links
        bra     tape_common


ana_tape:
        ldab    dec_key
        cmpb    ee_globals+ee_ana_lockout  ;See if selection locked out
        beq     locked_out

        stab    ana_tape_inp

        IFEQ    name-3         ;SIGNATURE+8

           decb
           stab    S_Tape_imag          
           jsr     update_S_Tape_mux

        ENDC

        jsr     show_ana_tape_sel       ;Flash up selection

        ldab    #6                      ;Pick up analog AV links
        bra     tape_common


;*** Switch SM tape mon video inputs ***

tape_common:
        addb    dec_key
        decb
        addb    #ee_av_links
        ldy     #ee_globals
        aby
        ldaa    0,y                     ;Get digital A/V link
        deca                            ;Convert to correct SM input #
        anda    #$7f                    ;Mask out S video bit (??????)Sig?
        jsr     do_sm_tm_sels           ;Send out tape-mon video code to SM
        rts

locked_out:
        jsr     lock_out_show           ;Display lockout selections
        jmp     warble                  ;Chirp to indicate problems

tape_flash:                             ;Flash up current tape selection
        clr     b_state
        ldaa    #148
        staa    t_state                 ;Get ready for number push

        ldaa    screen_status1          ;Check for big nums
        bne     tape_flash_0

        ldaa    screen_num
        cmpa    #.SCREEN.Main
        beq     tape_flash_1            ;If already in Main screen, all ok

tape_flash_0:
        ldaa    ps_frame
        cmpa    #k_anlg                 ;Check for t/m analog push
        beq     tape_flash_2            ;If so, no need to update screen

        clr     screen_status2
        clr     screen_status3          ;Flush other timers
        ldaa    #.SCREEN.Main           ;Bring up Main screen
        staa    screen_num
        jsr     display_scrn

tape_flash_1:
        ldaa    ps_frame
        cmpa    #k_anlg                 ;Check for Tape-Anlg
        beq     tape_flash_2

        jsr     show_dig_tape_sel       ;Show current digital selection
        rts

tape_flash_2:
        jsr     show_ana_tape_sel       ;Show current analog selection
        ldaa    #94
        staa    t_state                 ;Get ready for analog push
        rts


;******************************************************************
;*
;*   TAPE/MON LOCKOUT
;*
;***
dig_tape_lock_out:
        ldaa    dec_key
        cmpa    #7
        bhs     lock_out_rts            

        ldab    #ee_tm_lockout          ;Digital lockout location
        jsr     write_globals           ;Write EEPROM

        bsr     lock_out_show
        jmp     beepbeep

ana_tape_lock_out:
        ldaa    dec_key
        cmpa    #7
        bhs     lock_out_rts            

        ldab    #ee_tm_lockout+1        ;Analog lockout location
        jsr     write_globals           ;Write EEPROM

        bsr     lock_out_show
        jmp     beepbeep

lock_out_show:
        ldaa    #1                      ;Start long flash timer
        staa    screen_status3

        jsr     LCD_init                ;Clear screen
        jsr     System_config_screen    ;Put up new screen

lock_out_rts:
        rts



;**********************************************************
;*
;*  SHOW TAPE SELECTION
;*
;***
show_ana_tape_sel:
        tsx
        xgdx
        subd    #9                ;Allocate local variables on stack.
        xgdx
        txs
        ldaa    #':'
        staa    0,x
show_at_sel:
        ldaa    ana_tape_inp                    ;Get analog tape selection
        adda    #$30
        staa    2,x
        ldaa    #'A'
        staa    1,x
        bra     show_tape_rest

show_dig_tape_sel:
        tsx
        xgdx
        subd    #9                ;Allocate local variables on stack.
        xgdx
        txs
        ldaa    #':'
        staa    0,x
show_dt_sel:
        ldaa    dig_tape_inp                    ;Get digital tape selection
        adda    #$30                            
        staa    2,x     
        ldaa    #'D'
        staa    1,x
     
show_tape_rest:
        ldaa    #$20
        staa    3,x
        ldaa    #'|'
        staa    4,x
        ldd     #$2020
        std     5,x
        std     7,x

        tsy
        ldaa    #26
        jsr     SCREENS

        ldaa    #1
        staa    screen_status1
        staa    flash_up

        tsx
        xgdx
        addd    #9                 ;Deallocate local variables.
        xgdx
        txs
        rts


;************************************************************
;* Terminating the Features screens with Power key or FP push
;***
shortcut_feats:
        clr     features
        clr     three_secs

        lds     #ram_end

        ldaa    cold_start
        bne     shortcut_1

        jsr     OUTCRLF
        ldaa    #PROMPT                 ;New user prompt
        jsr     outa

        jsr     ONSCI                   ;Turn on SCI interrupts
        jmp     main_ft_end_sby

shortcut_1:
        ldaa    #$7f
        staa    ms_save                 ;Force fresh screen
        jmp     main_ft_end_pre


;**************************************************************
;*
;*                 M O D E    S E L E C T I O N
;*
;*
;*         Key Press          Mode #     Mode            Cancels
;* ------------------------   ------     ----     --------------------
;*    [TM 0]     = [Stereo]     0       stereo    ES(Ref.Cin)     N/A
;*    [TM 7]     =  [Surr]      1      surround      N/A*        Party
;*    [TM 8]     = [Matrix]     2       matrix    ES(Ref.Cin)    Party
;*    [TM 9]     =  [Mono]      3        mono     ES(Ref.Cin)    Party
;*
;*   *Footnote: ES should be disabled in Pro Logic mode. 
;*
;* Double key-press options:
;*
;*   [Stereo][Stereo] =  [Party] Toggle Party mode ON/OFF.
;*                               (Party mode ON switches 7.1
;*                                Music mode to 7.1 Movie).
;*
;*   [Surr][Surr]     =  [ES]    Toggle Ref.Cinema ES ON/OFF
;*                               or Cinema 7.1 Movie/Music
;*
;* The mode number is stored in the variable curr_mode for use in Z_modes,
;* and may also be stored in curr_mode_ac3, curr_mode_dts, or curr_mode_mpeg,
;* as appropriate.
;*
;***
mode_select:
        ldaa    dec_key
        cmpa    dec_key_save            ;If mode key is same as previous,
        beq     same_mode               ; go process as special mode...

        staa    dec_key_save            ;Else save the new mode key,
        ldaa    #1                      ; start a
        staa    two_secs                ; 2 s timer,
        bra     new_mode                ; and continue mode change as usual...

same_mode:
        ldaa    two_secs                ;If 2 s timer has gone to zero,
        beq     new_mode                ; treat key as a new mode.

        ldaa    #$55                    ;Else store an
        staa    dec_key_save            ; unlikely pattern,
        ldaa    dec_key                 ; and find out which key it was... 
        cmpa    #7                      ;If it was the [Surr] key that was repeated,
        beq     Surr_key_plus           ; then toggle the ES speaker on/off
                                        ; (or Movie/Music in Cinema 7.1 layout).

        cmpa    #0                      ;If it was the [Stereo] key that was repeated,
        beq     Stereo_key_plus         ; then toggle party mode on/off.
        bra     new_mode                ;Else change modes as usual...


;%% Toggle ES ON/OFF or Movie/Music...
Surr_key_plus:
        ldaa    spkr_cfg
        anda    #%0001                  ;Depending on the
        beq     Ref_Cinema_plus         ; Speaker Configuration:
        bra     Cinema71_plus           ;
                                        ;Either toggle
Ref_Cinema_plus:                        ; the ES speaker
        jsr     ES_togl                 ; flag, and set 
        bra     plus_done               ; a new Z2 mode
                                        ; (Ref. Cinema).
Cinema71_plus:                          ;Or toggle the Movie/Music
        jsr     movie_music_togl        ; flag, and set a new Z2
                                        ; mode (Cinema 7.1).
plus_done:
        ldaa    #$55
        staa    dec_key_save            ;Restore dec_key_save.
        bra     new_mode


;%% Toggle Party ON/OFF...
Stereo_key_plus:
        jsr     party_stereo_toggle     ;Toggle Party mode ON/OFF.
        ldaa    #$55
        staa    dec_key_save            ;Restore dec_key_save.
        bra     new_mode


;%% Normal decoding mode requests come through here...
new_mode:
        brset   ms_save,#$80,mode_sel0  ;If analog, go ahead and change

        ldaa    locked
        beq     mode_sel0               ;If not locked, make the change
        jmp     mode_sel_no_lock

mode_sel0:
        ldaa    dec_key                 ;Convert to curr_mode number as follows:
        beq     mode_sel1               ; 0 Stereo stays as 0.
                                        ; 7 Surr is converted to 1.
        suba    #6                      ; 8 Matrix is converted to 2.
                                        ; 9 Mono is converted to 3.

;%% Cancel Party if new decoding mode is incompatible.
;%% Then if current input is same as the temp dedicated dts input, do mode_sel_dts...
mode_sel1:
        psha
        beq     .mode_sel1a             ;Stereo=0

        clr     party_flag              ;No Party mode in Matrix, Mono, & Surround.

.mode_sel1a:
        cmpa    #1                      ;Surr=1
        ;Also exclude Pro Logic here later...
        beq     .mode_sel1b             

        cmpa    #0                      ;If Stereo mode, check for Party
        bne     .mode_sel1aa         

        ldaa    party_flag           
        beq     .mode_sel1aa         

        ldaa    #$ff                    ; and if Party enabled,
        staa    es_flag                 ; enable ES.
        bra     .mode_sel1b          

.mode_sel1aa:
        clr     es_flag                 ;No ES in Mono, Matrix, Stereo (of the non Party kind).

.mode_sel1b:
        ldaa    ms_save
        cmpa    t_dts_inp
        pula    
        beq     mode_sel_dts   

        psha                            ;Save selected mode
        jsr     get_auto_flag           ;Get correct bitstream
        pula                            ;Restore selected mode

        ldab    AC3_in_proc    
        bne     mode_sel_ac3   

        ldab    DTS_in_proc
        bne     mode_sel_dts

        ldab    MPEG_in_proc
        bne     mode_sel_mpeg


mode_sel_pcm:
        cmpa    curr_mode               ;Else if PCM, check if new PCM mode...
        bne     mode_sel2               ;If so, go do updates... 
        rts                             ;If same do nothing


mode_sel_ac3:
        cmpa    curr_mode_ac3 
        bne     mode_sel2
        rts                             ;If same do nothing


mode_sel_dts:
        cmpa    curr_mode_dts
        bne     mode_sel2
        rts


mode_sel_mpeg:        
        cmpa    curr_mode_mpeg
        bne     mode_sel2
        rts


;%% All mode changes come here:
mode_sel2:
        psha                            ;Save new mode selection
        jsr     check_if_new_Z          ;Do new Zoran mode if necessary.
        tsta                            ;Check status of Zoran update
                                        ;(A=0 --> new mode)
        beq     mode_sel_update         ;If a new mode or sub-mode go & update current mode.

        jsr     not_valid_Z             ;If mode is invalid, put up :N/A
        pula                    
        rts                       ;** Return **


mode_sel_update:
        pula
        staa    curr_mode               ;Update PCM mode
        psha
.chk_ac3:
        ldaa    AC3_in_proc             ;Set flags.
        pula                            ;This leaves flags intact.
        beq     .chk_dts

        staa    curr_mode_ac3           ;Update only if AC-3 and valid mode change.
        bra     .mode_exit

.chk_dts:
        psha  
        ldaa    ms_save        
        cmpa    t_dts_inp
        pula  
        beq     .update_curr_mode_dts

        ldx     #regbase
        brset   porte,x,#%00100000,.update_curr_mode_dts

.chk_mpeg:
        psha
        ldaa    MPEG_in_proc            ;Set flags.
        pula                            ;This leaves flags intact.
        beq     .mode_exit

        staa    curr_mode_mpeg
        bra     .mode_exit

.update_curr_mode_dts:
        staa    curr_mode_dts

.mode_exit:
        ldaa    #.SCREEN.Main           ;Update screen
        staa    screen_num
        jsr     display_scrn
        rts                       ;** Return **


not_valid_Z:                            ;Comes here if invalid Z-mode found
        ldaa    #1
        staa    z_error                 ;Flag that new mode is bad
        ldaa    #.SCREEN.Main       
        staa    screen_num              ;Go back to Main screen
        ldaa    #$ff
        staa    screen_status1          ;Force Main screen display

not_valid_Z_end:
        rts


mode_sel_no_lock:
        ldaa    #.SCREEN.Main      
        staa    screen_num
        jsr     LCD_init                ;Go into Main screen
        jsr     display_scrn

        ldab    dec_key                 ;Get mode selection
        beq     ms_no_lck0

        subb    #6
ms_no_lck0:
        stab    curr_mode
        stab    curr_mode_ac3
        stab    curr_mode_dts
        stab    curr_mode_mpeg          ;Save current mode selection everywhere
        
        aslb                            ;Multiply B by 2
        ldy     #ms_no_lck_blurb        ;Point to beginning of blurb list
        aby
        ldy     0,y                     ;Point to proper blurb
        ldaa    #13
        jsr     SCREENS

        ldaa    #1                      ;2s time-out
        staa    screen_status1
        rts

ms_no_lck_blurb:                        ;Pointers to blurb
        dc.w    nl_ster,nl_surr,nl_matr,nl_mono

;**************************************************************** 
get_curr_mode:
        jsr     get_auto_flag           ;Get correct bitstream

        ldaa    PCM_in_proc
        bne     get_curr_pcm

        ldaa    AC3_in_proc
        bne     get_curr_ac3

        ldaa    DTS_in_proc
        bne     get_curr_dts

        ldaa    MPEG_in_proc
        bne     get_curr_mpeg

get_curr_pcm:
        ldaa    curr_mode
        rts


get_curr_ac3:
        ldaa    curr_mode_ac3
        rts


get_curr_dts:
        ldaa    curr_mode_dts
        rts


get_curr_mpeg:
        ldaa    curr_mode_mpeg
        rts


;****************************************************************
;* Checking for new modes: Enter with the current mode in A.
;* Sees if the number passed in dec_key predicts:
;*
;*    Brand new Zoran mode (A=0),
;*
;*    Invalid Zoran mode (A=$ff),
;*
;*  
;*
;* If all ok, redoes Zorans
;*
;***
check_if_new_Z:
        staa    curr_mode_temp  ;Needed to temporarily store curr-mode (before it's
                                ; updated in mode_sel_update) for use below in Z_modes
        ldaa    locked          ;Check if locked
        beq     check_2         ;If so, all ok

        brset   ms_save,#$80,check_2    ;If analog, ignore locked status

        jsr     mute_all        ;If not, mute PCM1732s and CS3310s (to avoid DC offset)
        ldaa    #$ff
        staa    z_mode
        rts                     ;and return

check_2:
        ldaa    active_chs      ;Table number
        anda    #%00011000      ;Keep only CTR, SURR fields for indexing
        lsra
        lsra
        lsra                    ;Move into msbs

        ldab    #spk_entries    ;Entries per table
        mul                     ;D is offset into table group
                
        addd    #spkr_20        ;Add beginning of table group
        xgdy

        ldaa    curr_mode_temp  ;Restore mode
check_1:
        pshy
        ldy     #key_to_row-2   ;Y points 2 bytes back from translation table
rd_nxkey:
        iny                     ;Advance 2 bytes
        iny
        cmpa    0,y             ;Is table entry same as user override code?
        beq     found_key_Z

        cpy     #key_to_row+4*2 ;Last entry of table ?
        bne     rd_nxkey        ;If not, look at next (spacing is 2)

found_key_Z:
        iny                     ;Advance to row index
        ldaa    0,y             ;Get row index corresponding to key
        ldab    #coding_modes   ;Entries per row
        mul                     ;B is offset into table group

        puly                    ;Y is beg. address of table for current spkr cfg
        aby                     ;Y is row address for given user mode, speaker cfg
        pshy

        jsr     get_auto_flag   ;Update coding_cfg. Includes dts!!!
        ldab    coding_cfg      ;Composite of dts, pcm/anlg, ac3 return info.
        puly
        aby                     ;Y is entry address for given coding sub mode
        ldaa    0,y             ;A is row # in decoding parm table
        cmpa    z_mode
        beq     same_cfg        ;If same cfg requested, go home

        cmpa    #99
        beq     invalid_cfg     ;If invalid cfg flagged, go home

different_cfg:
        staa    z_mode
        jsr     Z_modes         ;Change Zorans
        clr     z_error         ;Flush Zoran mode error flag
        clra                    ;Flag mode accepted
        rts


same_cfg:
        clra                    ;Flag mode accepted
        rts


invalid_cfg:
        ldaa    #$ff            ;Flag invalid selection
        rts


;*************************************************************************
;*
;* ZORAN MODE SETTING
;*
;***
Z_modes:
        jsr     mute_all                ;Try & stop AC-3 burst.

        ldaa    z_mode
        ldab    #5                      ;Five bytes of data per row.
        mul                             ;D(=B) is beg. offset of relevant row.
        ldy     #dec_parms
        aby                             ;Y is address of parameter row.

        ldaa    0,y                     ;A is bass weight code for Z2.
        iny
        ldab    0,y                     ;B is proc mode for Z2.
        iny

        pshy
        jsr     ead_proc2               ;Send command to Z2

        RTINT   OFF          ;\\\\\\\\
        jsr     freq_check              ;Do freq check first
        RTINT   ON           ;////////

        ldaa    fs_freq
        cmpa    #1
        beq     z_conf_44

        cmpa    #2
        beq     z_conf_48

z_conf_32:
        ldaa    #$40
        bra     z_conf_fs
z_conf_48:
        ldaa    #0
        bra     z_conf_fs
z_conf_44:
        ldaa    #$20
z_conf_fs:
        ldab    plltab_lst+2
        bclr    plltab_lst+2,#%11100000 ;Clear SR bits in PLLTAB
        adda    plltab_lst+2            ;Set new SR bits
        cba
        beq     no_need_Z1

        staa    plltab_lst+2            ;Write back
        bclr    pllcfg_lst+2,#%11100000 ;Clear SR bits in PLLCFG
        adda    pllcfg_lst+2            ;Set new SR bits
        staa    pllcfg_lst+2            ;Write back
        jsr     configure_Z1

no_need_Z1:
        puly
        ldaa    0,y                     ;A is ocfg for Z1
        iny
        ldy     0,y                     ;Y is Z1 routine address
        jsr     0,y                     ;Go to it to send command to Z1
        ldy     #muteoff_cmd
        jsr     WR_Z1                   ;Unmute Z1
        jsr     peek_corr               ;Get volume corrections and set up vbls
        jsr     unpack_vol              ;Put volume+corrs into effect

        brset   mute_status,#1,.no_unmute ;If user muted, don't unmute.

        ldaa    locked                  ;If locked, do unmute
        beq     .unmute_ok 

        brclr   ms_save,#$80,.no_unmute2  ;If Dig, unlocked, no unmute
                                          ;If analog unlocked, unmute
.unmute_ok:
        delay   100*10                  ;Try to stop AC-3 burst
        jsr     unmute_all
           
.no_unmute:
        rts

.no_unmute2:
        ldaa    #$ff
        staa    z_mode
        bra     .no_unmute


;************************************************************
;
; DECODING MODE SELECTION TABLES
;
;    - each table is per speaker configuration:
;         0 = 2/0    (Stereo)
;         1 = 2/2    (Phantom)
;         2 = 3/0    (3Stereo)
;         3 = 3/2    (5.1)
;
;    - each row is per default mode / user override mode:
;         0 = Default
;         1 = Stereo
;         2 = Matrix
;         3 = Enhanced Mono
;         4 = Surround
;
;    - each column is per coding config (0..7 are straight from AC3 status):
;         0 = AC-3  Dual Mono     
;         1 = AC-3  1/0
;         2 = AC-3  2/0  No Dolby surround flag.
;         3 = AC-3  3/0
;         4 = AC-3  2/1
;         5 = AC-3  3/1
;         6 = AC-3  2/2
;         7 = AC-3  3/2
;         8 = AC-3  Dual Mono/.1
;         9 = AC-3  1/0/.1
;        10 = AC-3  1/0/.1
;        11 = AC-3  3/0/.1        
;        12 = AC-3  2/1/.1
;        13 = AC-3  3/1/.1
;        14 = AC-3  2/2/.1
;        15 = AC-3  3/2/.1
;        16 = AC-3  2/0     With Dolby Surround flag.
;        17 = AC-3  2/0/.1  With Dolby Surround flag.
;        18 = PCM   2/0
;        19 = DTS   3/2/.1
;        20 = MPEG2 2/0
;
;     - table entry is the offset into the decoding parameter table

; # of coding cfgs and table entries:
coding_modes:    equ     21               ;Number of configurations
user_modes:      equ     5
spk_entries:     equ     coding_modes*user_modes

; Coding configurations:
;ac3_32_src:      equ     7
;ac3_20ds_src:    equ     8
;dts_32_src:      equ     9
;pcm_20_src:      equ     10

;
;F = Pro Logic flagged.
;Not F = Pro Logic not flagged.
;DM = dual mono.
;
;                          CODING CONFIGURATION
;
;       0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20
;
;       D  1  2  3  2  3  2  3  D  1  2  3  2  3  2  3  2  2  2  3  2
;       M  /  /  /  /  /  /  /  M  /  /  /  /  /  /  /  /  /  /  /  /
;          0  0  0  1  1  2  2     0  0  0  1  1  2  2  0  0  0  2  0
;            Not                /  /  /  /  /  /  /  /  F  /  P  /  M
;             F                .1 .1 .1 .1 .1 .1 .1 .1    .1  C .1  P
;                                    Not                   F  M  D  E
;                                     F                          T  G
;      \-------------------------AC3------------------------/    S  2
;                                                                    
spkr_20: ;2/0 (Phantom-3Stereo mode is not allowed)
  dc.b 99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 ; Default (no user override)
  dc.b 99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 ; Stereo
  dc.b 99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 ; Matrix
  dc.b 99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 ; Enhanced Mono
  dc.b 99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 ; Surround

spkr_22: ;2/2 (Phantom)
  dc.b  6, 6, 6,11,10,10,10,10,27,37,27,37,10,10,10,10,29, 7, 0, 8,30 ; Default (no user override)
  dc.b 99,99, 6,38,38,38,38,38,27,27,27,38,38,38,38,38,38,38, 0, 9,30 ; Stereo
  dc.b 99,99,13,13,99,99,99,99,99,99,12,12,99,99,99,99,99,99, 1,99,31 ; Matrix
  dc.b 99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 ; Enhanced Mono
  dc.b 99,99,99,11,10,10,10,10,27,37,99,37,10,10,10,10,29, 7,14, 8,35 ; Surround
                                
spkr_30: ;3/0 (3Stereo)
  dc.b  6,25, 6,25,25,25,25,25,27,23,27,23,23,23,23,23,26,24, 0,15,30 ; Default (no user override)
  dc.b 99, 6, 6,38,38,38,38,38,27,27,27,38,38,38,38,38,38,38, 0, 9,30 ; Stereo
  dc.b 99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99 ; Matrix
  dc.b 22,22,99,99,99,99,99,99,21,21,99,99,99,99,99,99,99,99, 2,99,32 ; Enhanced Mono
  dc.b  6,25,26,25,25,25,25,25,27,23,24,23,23,23,23,23,26,24, 4,15,34 ; Surround

spkr_32: ;3/2 (5.1)
  dc.b  6,16, 6,16, 5, 5, 5, 5,27,36,27,36, 5, 5, 5, 5,17,18, 0,28,30 ; Default (no user override)
  dc.b  6, 6, 6,38,38,38,38,38,27,27,27,38,38,38,38,38,38,38, 0, 9,30 ; Stereo
  dc.b 99,99,20,20,99,99,99,99,99,99,19,19,99,99,99,99,99,99, 1,99,31 ; Matrix
  dc.b 22,22,99,99,99,99,99,99,21,21,99,99,99,99,99,99,99,99, 2,99,32 ; Enhanced Mono
  dc.b  6,16,17,16, 5, 5, 5, 5,27,36,18,36, 5, 5, 5, 5,17,18, 3,28,33 ; Surround


;****************************************************************************

;IRcode-to-table row translation
key_to_row:
        dc.b   $ff,0              ;No user override specified (Note!!!)
        dc.b     0,1              ;Stereo
        dc.b     1,4              ;Pro Logic
        dc.b     2,2              ;Matrix
        dc.b     3,3              ;Mono


;****************************************************************************
;
;            D E C O D I N G    P A R A M E T E R    T A B L E
;
; Z1 = Zoran DSP #1 (does Dolby Digital decoding)
; Z2 = Zoran DSP #2 (does EAD bass management)
; M1 = Motorola DSP (does DTS decoding, in place of Z1)
;
; Each row is comprised of:
;
;      Z2 bassmode, Z2 dec2_mode, Z1 ocfg + ProL mode, Z1/M1 dec1_cmd
;
; where:
;   bassmode  -- bass summing weight set code for Z2
;   dec2_mode -- custom processing mode for Z2
;                 0 = 6-channel feed-through
;                 1 = stereo
;                 2 = matrix
;                 3 = enhanced mono
;                 4 = special test mode (L-channel fed to all channels)
;          xxx    5 = NEW: Party (old: stereo balanced)
;                 6 = distance measurement crack
;                 7 = 4-channel feedthru
;   ocfg      -- output speaker config for dec1_cmd
;                (auto ProL decode = 2 msbs set to %10)
;   dec1_cmd  -- standard 1st-stage decoding routine (AC3, ProL, DTS, etc)
;
;
;Decoding parameter table (This is not an exhaustive list !!!):

dec_parms:      ;Z2 Z2 ProL+Z1 Z1/M1
        dc.b     2, 1,$00+0+2
        dc.w                 pcm_proc1    ;#0: PCM, Stereo    
        dc.b     2, 2,$00+0+2             
        dc.w                 pcm_proc1    ;#1: PCM, Matrix
        dc.b     3, 3,$00+0+2
        dc.w                 pcm_proc1    ;#2: PCM, Enh. Mono

        dc.b     1, 0,$00+0+7
        dc.w                 prol_proc1   ;#3: PCM, Pro Logic, 6-ch. feedthru
        dc.b     1, 7,$00+0+3
        dc.w                 prol_proc1   ;#4: PCM, 3Stereo Pro Logic, 4-ch. feedthru
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     0, 0,$00+8+7
        dc.w                 ac3_proc1    ;#5: AC-3 3/2/.1, no Pro Logic, 6-ch. feedthru
        dc.b     2, 1,$40+0+0                      
        dc.w                 ac3_proc1    ;#6: AC-3 2/0 normal, Stereo
        dc.b     0, 0,$40+8+6        
        dc.w                 ac3_proc1    ;#7: AC-3 2/2/.1, Pro Logic ON, 6-ch. feedthru

        dc.b     4, 0,$00+0+2+4
        dc.w                 dts_proc1    ;#8: DTS 2/2/.1 6-ch. feed thru
        dc.b     2, 1,$80+0+0+0                               
        dc.w                 dts_proc1    ;#9: DTS Lt/Rt downmix

        dc.b     0, 0,$00+8+6
        dc.w                 ac3_proc1   ;#10: AC-3 2/2/.1, no Pro Logic, 6-ch. feedthru ?????
        dc.b     2, 7,$00+8+6
        dc.w                 ac3_proc1   ;#11: AC-3 2/2/.1, no Pro Logic, Phantom, 4-ch. feedthru
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     0, 2,$00+8+6
        dc.w                 ac3_proc1   ;#12: AC-3 2/2/.1, no Pro Logic, Matrix
        dc.b     2, 2,$00+8+6
        dc.w                 ac3_proc1   ;#13: AC-3 2/2/.1, no Pro Logic, ?????

        dc.b     2, 0,$00+0+6
        dc.w                 prol_proc1  ;#14: AC-3 2/2 ProL, 6-ch. feedthru                        

        dc.b     4, 0,$00+1+0+4
        dc.w                 dts_proc1   ;#15: DTS 5.1, 3/0/.1, 6-ch. feedthru 

        dc.b     1, 7,$00+8+7
        dc.w                 ac3_proc1   ;#16: AC-3 3/2/.1, no ProL , 4-ch. feedthru
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     1, 0,$40+8+7
        dc.w                 ac3_proc1   ;#17: AC-3 3/2/.1, ProL ON, 6-ch. feedthru
        dc.b     0, 0,$40+8+7
        dc.w                 ac3_proc1   ;#18: AC-3 3/2/.1, ProL ON, 6-ch. feedthru
        dc.b     0, 2,$00+8+7
        dc.w                 ac3_proc1   ;#19: AC-3 3/2/.1, Matrix
        dc.b     1, 2,$00+8+7
        dc.w                 ac3_proc1   ;#20: AC-3 3/2/.1, Matrix
        dc.b     0, 3,$00+8+2              
        dc.w                 ac3_proc1   ;#21: AC-3 2/0/.1 Normal, Enh. Mono
        dc.b     3, 3,$00+0+2
        dc.w                 ac3_proc1   ;#22: AC-3 2/0 Dual Mono, Enh. Mono
        dc.b     0, 7,$00+8+3
        dc.w                 ac3_proc1   ;#23: AC-3 3/0/.1, no Pro Logic, 4-ch. feedthru 
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     0, 7,$40+8+3
        dc.w                 ac3_proc1   ;#24: AC-3 3/0/.1, ProL ON, 4-ch. feedthru
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     1, 7,$00+8+3
        dc.w                 ac3_proc1   ;#25: AC-3 3/0/.1, no Pro Logic, ProL bassmode, 4-ch. feedthru
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     1, 7,$40+8+3
        dc.w                 ac3_proc1   ;#26: AC-3, ProL ON, 4-ch. feedthru
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     0, 1,$40+8+0
        dc.w                 ac3_proc1   ;#27: AC-3 2/0/.1 Normal, 6-ch. feedthru                        

        dc.b     4, 0,$00+1+2+4
        dc.w                 dts_proc1   ;#28: DTS 3/2/.1 6-ch. feedthru

        dc.b     2, 0,$40+0+6
        dc.w                 ac3_proc1   ;#29: AC-3 2/2  ProL on         

        dc.b     2, 1,$00+0+2
        dc.w                 mpeg_proc1  ;#30: MPEG2 Stereo   
        dc.b     2, 2,$00+0+2             
        dc.w                 mpeg_proc1  ;#31: MPEG2 Matrix
        dc.b     3, 3,$00+0+2
        dc.w                 mpeg_proc1  ;#32: MPEG2 Enh. Mono
        dc.b     1, 0,$40+0+7
        dc.w                 mpeg_proc1  ;#33: MPEG2, 3/2, ProL ON, Z2 6-ch. feedthru
        dc.b     1, 0,$40+0+3
        dc.w                 mpeg_proc1  ;#34: MPEG2, 3Stereo, ProL ON, Z2 6-ch. feedthru
        dc.b     2, 0,$40+0+6
        dc.w                 mpeg_proc1  ;#35: MPEG2, 2/2, ProL ON, Z2 6-ch. feedthru

        dc.b     0, 7,$00+8+7     ;Is this one using correct Z2 mode?
        dc.w                 ac3_proc1   ;#36: AC-3 3/2/.1, no Pro Logic, 4-ch. feedthru
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     0, 7,$00+8+6     ;Is this one using correct Z2 mode?
        dc.w                 ac3_proc1   ;#37: AC-3 2/2/.1, no Pro Logic, 4-ch. feedthru ?????
        ;           ^
        ;           |
        ;           +4-ch feed-thru (can this be changed to 0 = 6-ch feed-thru?

        dc.b     2, 1,$40+0+0                      
        dc.w                 ac3_proc1   ;#38: AC-3 2/0 normal, Stereo, activate "line" compression in Z1


; All 2/0 configurations will be done by DEC2 = 1 (Stereo) in Z2.
;******* Take Care of Party mode *********
ead_proc2:
        psha
        ldaa    party_flag
        beq     ead_proc2a

        ldab    #5              ;Set dec2 to Party mode for PAR1.
ead_proc2a:
        pula

;************** Z2 PAR 1 *****************
        lsla                    ;Shift bass weight set to MS nibble
        lsla
        lsla
        lsla
        aba                     ;Combine with Z2 decode mode
        staa    ead_lst+2       ;Store PAR1


;************* Z2 PAR 2 ******************
;%% Massage xover, rolloff bytes into Z2 format.
;%% Get fsel sampling rate info in SR.

        clra                    ;Start with PAR2 = 0

        ldab    xover_chs
        andb    #%00001000      ;Surround X
        aslb
        aba

        ldab    xover_chs
        andb    #%00010000      ;Center X
        aslb
        aba

        ldab    xover_chs
        andb    #%00000010      ;Front X
        aslb
        aslb
        aba

        ldab    rolloff_chs
        andb    #%00010000      ;Center R
        lsrb
        lsrb
        aba

;*** HDCD restrictions (if Dig Stereo/Matrix, no rolloff of fronts)
;*** DIP HDCD override (SW5 = ON = 0) ***

.hdcd_restrictions:
        brclr   DIP_imag,#%00010000,hdcd_rest_1 ;If DIP override, do rolloff

        ldab    AC3_in_proc
        bne     hdcd_rest_1     ;If AC3, no restrictions

        ldx     #regbase
        brset   porte,x,#%00100000,hdcd_rest_1  ;If DTS, no restrictions

        brset   ms_save,#$80,hdcd_rest_1        ;If analog, no restrictions

        ldab    curr_mode_temp  
        cmpb    #1
        beq     hdcd_rest_1     ;If ProL, no restrictions     

        cmpb    #3
        beq     hdcd_rest_1     ;If Enh. Mono, no restrictions   
        bra     .surround_roll  ;Default, Stereo, Matrix have no front rolloff

hdcd_rest_1:   ;Override hdcd restrictions (i.e., no restrictions) E/O/S

;** No HDCD comes here & does front & rear roll-offs:
        ldab    rolloff_chs     ;Front RF
        andb    #%00000010
        lsrb
        aba

.surround_roll:
        ldab    rolloff_chs
        andb    #%00001000      ;Surround RS
        lsrb
        lsrb
        aba
        tab

        ldaa    spkr_cfg
        anda    #%0011
        cmpa    #%0001
        bne     .sample_rate

        andb    #%11111101      ;Force roll-off of dipole surrounds for 7.1 Movie mode.

.sample_rate:
        ldaa    fs_freq
        cmpa    #1  
        bne     sr_1

        addb    #$40
        bra     sr_3

sr_1:   cmpa    #2
        bne     sr_2
        bra     sr_3

sr_2:   addb    #%10000000
sr_3:   stab    ead_lst+3       ;Store PAR2


;**************** Z2 PAR 3 *******************
        ldy     #xover_freqs
        ldab    xover_val
        aby
        ldaa    0,y             ;Get cross over frequency
        staa    ead_lst+4       ; and store in PAR3


;*************** Z2 PARS 4,5 ********************
sr_3_1: clrb                    ;Start with PAR4 = 0

;*** DIP HDCD override ***
        brclr   DIP_imag,#%00010000,hfeq_rest_1 ;If DIP override, do HFEQ   

;*** Sig,Ovat HFEQ restrictions (if Dig Stereo/Matrix, no rolloff of fronts)

        ldaa    AC3_in_proc
        bne     hfeq_rest_1     ;If AC3, no restrictions

        ldx     #regbase
        brset   porte,x,#%00100000,hfeq_rest_1  ;If DTS, no restrictions

        brset   ms_save,#$80,hfeq_rest_1        ;If analog, no restrictions

        ldaa    curr_mode_temp  
        cmpa    #1
        beq     hfeq_rest_1     ;If ProL, no restrictions     

        cmpa    #3
        beq     hfeq_rest_1     ;If Enh. Mono, no restricitions   
        bra     sr_3_2          ;Default, Stereo, Matrix have no HFEQ         

hfeq_rest_1:
        jsr     get_correct_hfeq
        ldaa    0,y             ;Get correct HFEQ flag
        beq     sr_3_2          ;0 = no HFEQ

        ldab    #%01000000      ;1 = HFEQ

sr_3_2: andb    #%11000000      ;Make sure LF delay field is zero.
        stab    ead_lst+5       ;Store PAR4. (LFdly=0)

;------For new Z2 EPROM
        ldaa    spkr_cfg
        anda    #%1100          ;Get number of SUBs,
        lsla
        lsla
        lsla
        lsla                    ; and left justify.
        anda    #%11000000      ;This also makes RFdly=0, as is required.
        bne     .chk_sub_override ;If we have subs, go and check the sub override,

        ldab    active_chs      ;Else apply this to active_chs,
        andb    #%011111        ; so that we get 'SB____', i.e.,
        stab    active_chs      ; no subs also on the Adjust screen.
        bra     .store_PAR5     ;Note: This should also take care of any
                                ; attempt to enable non-existant subs
                                ; using the Adjust screen SB toggle.
.chk_sub_override:
        ldab    active_chs      ;If there's no sub disable override
        andb    #%100000        ; selected on the Adjust screen,
        bne     .store_PAR5     ; proceed as normal, 

        clra                    ;Else disable subwoofer 'SB____' on the
                                ; Adjust screen, and make RFdly=0.
.store_PAR5:
        staa    ead_lst+6       ;Store PAR5 (RFdly=0)
;-----End of stuff for new Z2 EPROM

;************** Z2 PARS 6,7,8 ******************

        ldaa    LFRF_dst
        suba    LSRS_dst        ;How much closer are surrounds?

        tsta
        bge     place_LSRS      ;If negative distance,

        clra                    ; make 0.

place_LSRS:

;* Add 15 ms for ProL or Matrix: 

        ldab    PCM_in_proc             ;If PCM or MPEG, only need to check
        bne     place_only_curr         ;if ProL or Mat

        ldab    MPEG_in_proc
        bne     place_only_curr

        ldab    AC3_in_proc             ;If AC3, need to check for special cases
        bne     place_AC3       
        bra     place_LSRS_set  ;If not, go ahead and store

place_only_curr:
        ldab    curr_mode_temp
        cmpb    #1                      ;Check for Pro Logic
        beq     place_LSRS_add

        cmpb    #2                      ;Check for Matrix
        beq     place_LSRS_add
        bra     place_LSRS_set

place_AC3:
        psha                            ;Save delay from above

        ldab    curr_mode_temp          ;(MODE+1)x18 + CFG = NUMBER
        incb  
        ldaa    #18                     ;Number of columns in blurb_nums.
        mul
        addb    coding_cfg
        ldy     #blurb_nums
        aby
        ldab    0,y                     ;Get blurb number
        
        pula

        cmpb    #8                      ;Check for " ProL", ":ProL", ":Mat"             
        beq     place_LSRS_add

        cmpb    #10
        beq     place_LSRS_add

        cmpb    #12
        beq     place_LSRS_add          ;If so, add 15ms
        bra     place_LSRS_set          ;If not, add nothing

place_LSRS_add:
        adda    #51             ;Add 51*0.3ms=15 ms if ProL or Matrix (AC3 or PCM)

        cmpa    #127            ;Check for saturation
        bls     place_LSRS_set

        ldaa    #127            ;Maxed out!!


place_LSRS_set:
        staa    ead_lst+7       ;Store PAR6
        staa    ead_lst+8       ;Store PAR7

        ldaa    LFRF_dst
        suba    CT_dst          ;How much closer is C?
        bge     place_CT        ;If negative distance, 

        clra                    ; make 0.

place_CT:
;Uncomment the next lines for new Z2 EPROM:
        ldab    spkr_cfg
        andb    #%0011          ;Get Movie/Music and Ref.C/Cin7.1 bits
        cmpb    #%0011          ;Convert spkr_cfg as follows:
        bne     place_CT2       ; 00 to 0 (Ref.Cinema layout)
                                ; 01 to 1 (Cinema 7.1 Movie)
        clrb                    ; 11 to 0 (Cinema 7.1 Music uses Ref.Cin Z2 mode)
place_CT2:                      ;This puts up the correct 'Ref.Cinema' speaker
        andb    #%0001          ; layout for Cinema 7.1 Music mode.
        aslb
        aslb
        aslb
        aslb
        aslb
        aslb                    ;Move to bit 6  
        aba
;----------------uncomment down to here

        staa    ead_lst+9       ;Store PAR8

        ldy     #ead_lst
        jsr     WR_Z2           ;Start EAD processing in Z2 (+ unmute)
        rts


;************************************************************
;*
pcm_proc1:
        ldy     #pcm_cmd1_B6
        brclr   Z_ver_flag,#$ff,pcm_1

        ldy     #pcm_cmd1_B7
pcm_1:  jsr     WR_Z1           ;Start PCM on Z1
        rts
        

;************************************************************
;*
;* AC3 PROCESSING
;*
;* AC3 command skeleton has been copied into AC3_lst at start-up
;* All variable parameters in it are set here
;**
ac3_proc1:
        tab                             
        anda    #%11000000              ;Extract PRLG field
        bclr    AC3_lst+2,#%11000000    ;Clear current PRLG bits
        adda    AC3_lst+2               ;Set as required
        staa    AC3_lst+2               ;Save PAR1

        andb    #%00001111              ;Extract SW and OCFG field
        bclr    AC3_lst+3,#%00001111    ;Clear current OCFG bits
        addb    AC3_lst+3               ;Set as required
        stab    AC3_lst+3               ;Save PAR2

        ldaa    late_nite
        cmpa    #0                      ;Defeat?
	bne     isit_1

        clrb                            ;Set B = 0.0
        stab    AC3_lst+5               ;Clear HDYNRNG
        stab    AC3_lst+6               ;Clear LDYNRNG
	bra     dyn_dun

isit_1:
        cmpa    #1                      ;Low level ?
	bne     isit_2

        ldab    #$26                    ;Set B = 0.3 ~= %0.01001100 =$0.4c = $26
        stab    AC3_lst+5               ;Set HDYNRNG
        stab    AC3_lst+6               ;Set LDYNRNG
	bra     dyn_dun
isit_2:
        cmpa    #2                      ;Mid level ?
	bne     isit_3

        ldab    #$4c                    ;Set B = 0.6 ~= %0.10011001 =$0.99 = $4c
        stab    AC3_lst+5               ;Set HDYNRNG
        stab    AC3_lst+6               ;Set LDYNRNG
	bra     dyn_dun

isit_3:
        cmpa    #3                      ;High level ?
	bne     dyn_dun

        ldab    #$7f                    ;Set B = 0.992 ~= %0.11111110 = $0.fe = $7f
                                        ;          (Note: B ~= 1 = 127/128 exactly)
        stab    AC3_lst+5               ;Set HDYNRNG
        stab    AC3_lst+6               ;Set LDYNRNG
dyn_dun:
        ldy     #AC3_lst                ;Point to AC3 list


;* Change 11dB correction in Stereo downmix to Line compression  

        ldaa    z_mode
        cmpa    #38
        bne     dyn_dun_no_line         ;Check for mode 38 (=line compression)

dyn_dun_line:
        bset    2,y,#%00001000          ;Set line compression bit
        bra     dyn_dun2

dyn_dun_no_line:
        bclr    2,y,#%00001000          ;Clear line compression bit

dyn_dun2:
        jsr     WR_Z1                   ;Start AC3 on Z1
        rts


;*************************************************************
;*
;* ProL command skeleton has been copied into prol_lst at start-up
;* Variable parameter OCFG is set here
;*
;***
prol_proc1:
        anda    #%00000111              ;Extract OCFG field
        bclr    prol_lst+3,#%00110111   ;Clear current OCFG bits (and bass redirection)
        adda    prol_lst+3              ;Set as required
        staa    prol_lst+3              ;Save PAR1
        ldy     #prol_lst
        jsr     WR_Z1                   ;Start ProL on Z1
        rts


;*************************************************************
;*
;* MPEG2 command skeleton has been copied into mpeg_lst at start-up
;* Variable parameter OCFG is set here
;*
;***
mpeg_proc1:
        tab                             
        anda    #%11000000              ;Extract PRLG field
        bclr    mpeg_lst+2,#%11000000   ;Clear current PRLG bits
        adda    mpeg_lst+2              ;Set as required
        staa    mpeg_lst+2              ;Save PAR1

        tba
        anda    #%00000111              ;Extract OCFG field
        bclr    mpeg_lst+3,#%00110111   ;Clear current OCFG bits (and bass redirection)
        adda    mpeg_lst+3              ;Set as required
        staa    mpeg_lst+3              ;Save PAR1

        ldaa    late_nite
        cmpa    #0                      ;Defeat?
        bne     misit_1

        clrb                            ;Set B = 0.0
        bra     mdyn_dun

misit_1:
        cmpa    #1                      ;Low level ?
        bne     misit_2

        ldab    #$26                    ;Set B = 0.3 ~= %0.01001100 =$0.4c = $26
        bra     mdyn_dun

misit_2:
        cmpa    #2                      ;Mid level ?
        bne     misit_3

        ldab    #$4c                    ;Set B = 0.6 ~= %0.10011001 =$0.99 = $4c
        bra     mdyn_dun

misit_3:
        cmpa    #3                      ;High level ?
        bne     mdyn_dun

        ldab    #$7f                    ;Set B = 0.992 ~= %0.11111110 = $0.fe = $7f
                                        ;          (Note: B ~= 1 = 127/128 exactly)
mdyn_dun:
        stab    AC3_lst+5               ;Set HDYNRNG
        stab    AC3_lst+6               ;Set LDYNRNG

        brset   Z_ver_flag,#$ff,start_mpeg ;Use ROM MPEG2 for Z1 version B7.

;*** B6 MPEG patch download ***

        ldy     #mpeg_cmd
        ldx     #regbase

        rtint   OFF

        bclr    spcr,x,#%00001000      ;Set SCLK to latch on falling edge
        bset    spcr,x,#%00000100      ;CPHA=1

        bclr    portg,x,#%00000010     ;Assert _SS for Z1
;        bclr    portd,x,#%00100000     ;Assert generic _SS for debugging
	
mpeg_tx:
        ldaa    0,y                    ;Get byte to transmit
        staa    spdr,x                 ;Send byte out to SPI
        brclr   spsr,x,#%10000000,*     ;Wait if SPI is busy...
        ldaa    spdr,x                 ;Unload byte from SPI

        cpy     #mpeg_cmd_end          ;See if end of patch
        beq     mpeg_tx_end

        iny
        bra     mpeg_tx                ;Go to handle next byte

mpeg_tx_end:
        ldx     #regbase
        bset    portg,x,#%00001111     ;Deassert all_*SS
;        bset    portd,x,#%00100000     ;including the debug one.

        rtint   ON

start_mpeg:
        ldy     #mpeg_lst
        jsr     WR_Z1                   ;Start MPEG on Z1
        rts


;*************************************************************
;* Control DTS board here!!
;* A contains:
;*   MSB set=Lt/Rt downmix
;*   MSB clr=5.1
;*   Bit 0=Center on/off
;*   Bit 1=Surrounds on/off
;*   Bit 2=LFE on/off
;* 
;***
dts_proc1:
        ldy     #DTS_lst                ;Set pointer to DTS list

        bita    #$80
        beq     dts_no_dnmx             ;MSB clear menas no downmix

dts_dnmx:
        bset    8,y,#%00001000          ;Set Lt/Rt downmix bit
        bra     dts_channels

dts_no_dnmx:
        bclr    8,y,#%00001000          ;Clear Lt/Rt downmix


dts_channels:
        anda    #$7f                    ;Clear out MSB
        ldab    DTS_lst+9
        andb    #%11111000              ;Clear out channel info (preserve other)
        aba                             ;Add in new channel info
        staa    DTS_lst+9               ;Store new channel info

        ldy     #DTS_lst                ;Redo DTS on M1
        jsr     WR_M1                   
        rts


;*************************************************************
;* Configuring Z1
configure_Z1:
        ldy     #plltab_lst
        jsr     WR_Z1                   ;Inform Z1 of clock frequency.
        delay   20*10
        ldy     #pllcfg_lst
        jsr     WR_Z1                   ;Inform Z1 of sampling frequency.
        delay   1*10
        ldy     #cfg_cmd1
        jsr     WR_Z1                   ;Set Z1 ports
        delay   20*10                   ;20 ms
        rts


;*************************************************************
;* Routine to force a new Zoran mode
force_new_Z:
        ldaa    #$ff
        staa    z_mode                  ;Force new Zoran mode
        jsr     get_curr_mode
        jsr     check_if_new_Z
        tsta
        beq     force_new_rts           ;If not errors, go home            

force_default_Z:
        ldaa    #$ff                    ;Otherwise, select default mode
        jsr     check_if_new_Z          ;Put Zoran into default mode

force_new_rts:
        rts

;*************************************************************
;* Routine to force a new Zoran mode and flush curr_mode if
;* an invalid mode is selected
force_new_Z_flush:
        ldaa    #$ff
        staa    z_mode                  ;Force new Zoran mode
        jsr     get_curr_mode
        jsr     check_if_new_Z
        tsta
        beq     force_new_flush_rts     ;If not errors, go home            

force_default_Z_flush:
        ldaa    #$ff                    ;Otherwise, select default mode
        clr     curr_mode               ;and flush all mode selections
        staa    curr_mode_ac3
        staa    curr_mode_dts
        staa    curr_mode_mpeg
        jsr     check_if_new_Z          ;Put Zoran into default mode

force_new_flush_rts:
        rts


        
;*************************************************************
;*
;*                DETERMINE TYPE OF BITSTREAM
;*
;* Decoding tree:
;*
;*      Temp/Perm DTS?  -----Yes--------> Do DTS
;*           |
;*           |no
;*           |
;*           V
;*      Temp/Perm MPEG? -----Yes--------> Do MPEG
;*           |
;*           |
;*      (get AUTO flag)
;*        |        |
;*  auto=1|        |auto=0
;*        |        |
;*        |        V
;*        |       PCM ------------------> Old-DTS?--Yes-------> Do DTS
;*        |                                        |
;*        |                                        +-No-------> Do PCM
;*        V
;*    F-flag set? -----------Yes------->  New DTS
;*        |
;*        |no
;*        |
;*        V    
;*      Boot up AC3
;*        |
;*     Check F-flag ---------on-------->  New DTS
;*        |
;*        |off
;*        |
;*        +-----------------------+
;*                                |
;*                                V
;*                         Check AC3 status
;*                           /          \
;*                          /            \
;*                        OK           Updating/Error
;*                         |                 |
;*                         |                 |Check F-Flag ---yes--->DTS
;*                         |                 |
;*                         V                 V
;* New DTS<---on-----Check F-flag       100ms delay
;*                   |     |                 |
;*                   |     |                 |Check F-Flag ---yes--->DTS
;*                   |     |                 |
;*                off|     |                 |
;*                   |     |                 |
;*                   V     |                 |   
;*                AC3 mode |                 |
;*                         |                 V
;*                         |           Check AC3 status
;*                         |               /     \
;*                         |              /       \
;*                         +----------- OK    Updating/Error
;*                                                 |
;*                                                 |Check F-flag--yes-->DTS
;*                                                 |
;*                                                 V
;*                                       Flush decoding flags, exit
;*                                        and try fresh next time
;*                                         
;*
;***
get_auto_flag:
        brset   ms_save,#$80,get_auto_anlg      ;If analog, avoid all this

        ldaa    locked                  ;If locked, all ok
        beq     get_auto_ded

        clr     PCM_in_proc             ;Otherwise, flush all processing flags
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc

        ldaa    #$ff
        staa    z_mode                  ;Flush Zoran mode
        jmp     auto_exit               ;Don't do any check in this case

get_auto_anlg:
        ldaa    #1                      ;Pretend it is PCM
        staa    PCM_in_proc
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc
        ldaa    #18
        staa    coding_cfg              ;Indicate PCM going on

        ldx     #regbase
        bclr    porta,x,#%10000000      ;Disable DTS select.
        jmp     auto_exit               ;Don't do any check in this case

;------ Dedicated DTS and MPEG -----

get_auto_ded:

        ldaa    ms_save                 ;Get current digital input
        cmpa    t_dts_inp               ;Check if temporarily DTS dedicated
        beq     get_auto_t_p_dts

        cmpa    t_mpeg_inp              ;Check if temporarily MPEG dedicated
        beq     get_auto_t_p_mpeg

;        cmpa    #2                                      ;Check if in Dig. 2
;        bne     get_auto_t0  
;        brclr   DIP_imag,#%00000010,get_auto_t_p_dts    ;If D2 and DIP #2
;                                                        ;on, do perm. DTS
;get_auto_t0:    
;        cmpa    #3
;        bne     get_auto_t1                             ;Check if in Dig. 3
;        brclr   DIP_imag,#%00000100,get_auto_p_ac3      ;If D3 and DIP #3
;                                                        ;on, do perm. AC3 
;
;get_auto_t1:
        cmpa    #4
        bne     get_auto_t2
        brclr   DIP_imag,#%00001000,get_auto_t_p_mpeg   ;If D4 and DIP #4
                                                        ;on, do perm. MPEG

get_auto_t2:
        bra     get_flags

get_auto_t_p_dts:
        jmp     auto_DTS


get_auto_t_p_mpeg:
        jmp     auto_MPEG


;get_auto_p_ac3:
;        jmp     auto_AC3


;------ Check 4226 Auto flag ------

get_flags:
        rtint   OFF

;*** Check status of Auto flag:

        ldaa    #2
        jsr     RD_CS4226               ;Get converter control byte (2)

        anda    #%00010000              ;Get AC-3/MPEG2/New-DTS auto detect flag.        
        beq     auto_PCM                ;If zero, do PCM
        jmp     auto_AC3                ;If not zero, check in turn for each of
                                        ; the above modes, starting with AC-3.
                                        ;If zero, bitstream should be PCM or Old-DTS.

;------ AUTO PCM & AUTO OLD-DTS -------

auto_PCM:

;%% Auto Old-DTS (DTS-encoded CDs and LDs):
        ldx     #regbase
        brclr   porte,x,#%00100000,auto_pcm_1   ;If no f-flag, go on
        jmp     auto_DTS                        ;If f-flag, do old DTS

auto_pcm_1:
        ldx     sticky_dts_ctr
        bne     auto_pcm_2              ;If DTS counter counting, don't do PCM

        ldx     sticky_ac3_ctr
        bne     auto_pcm_2              ;If AC3 counter counting, don't do PCM
        bra     auto_pcm_3              ;If both counters clear, do PCM

auto_pcm_2:
        jmp     auto_exit               ;Skip this if DTS or AC3 is sticking still

auto_pcm_3:
        ldx     #regbase
        bclr    porta,x,#%10000000      ;Else disable DTS select.

;%% Auto PCM:
;                      PCM
;                     /   \
;                 new/     \old
;                   /       \
;                PCM=1      Check DATA flag ---same----->Exit
;                Mute             |
;            Flag change          |changed
;           (Emph on AUTO)        |
;            (if DATA=0)         / \
;                              0/   \1
;                              /     \
;                             /       \
;                         Unmute       Mute
;                      (if allowed)  (Emph AUTO)
;                       (Emph OFF)
;
;
        ldaa    PCM_in_proc
        beq     new_pcm                 ;If new mode, do PCM...   


old_pcm:
        ldaa    #18
        jsr     RD_CS4226               ;Get Rx CS0 channel Status byte (18)

        cmpa    cs0_imag
        beq     old_pcm_exit            ;If no changes, just exit

        ldab    #1                      ;Flag changes for Input Data Status screenn 11
        stab    update_screen12         ; if there are any changes

        ldab    cs0_imag                ;Get old CS0
        staa    cs0_imag                ;Save new info

        andb    #%00000010              ;Old DATA flag
        anda    #%00000010              ;New DATA flag

        cba                             ;See if any changes in DATA
        beq     old_pcm_exit            ;If none, go home

        tsta                            ;Check if new DATA flag is ON/OFF
        beq     old_pcm_unmute          ;If off, unmute

old_pcm_mute:
        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        jsr     do_mute
        ldaa    #$ff
        staa    deem_off_flag   ;>>>    ;Turn Emphasis OFF in this case.
        bra     old_pcm_exit

old_pcm_unmute:
        brset   mute_status,#1,old_pcm_exit     ;If user mute, don't unmute

        jsr     undo_mute
old_pcm_exit:
        jmp     auto_exit        

new_pcm:
        rtint   ON

        ldaa    #1
        staa    PCM_in_proc             ;Set PCM flag, clear others.
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc

        ldx     #regbase
        bclr    porta,x,#%10000000      ;Disable DTS select.

        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        jsr     do_mute                 ;Mute output to avoid hiss

        ldaa    #18
        staa    coding_cfg              ;Indicate PCM going on
        jmp     auto_change


;----------- AUTO AC-3 ------------
auto_AC3:
        ldx     #regbase
        brclr   porte,x,#%00100000,auto_AC3_0   ;If no f-flag, go on       
        jmp     auto_DTS                        ;If f-flag, do new DTS


auto_AC3_0:
        ldaa    AC3_in_proc             ;If it is new AC3 submode, set flags and Zs
        beq     auto_AC3_1
        jmp     ac3_coding_cfg          ;If same AC3 submode, check coding_cfg status


auto_AC3_1:
        rtint   OFF

        ldaa    #1                      ;Set flags
        staa    AC3_in_proc
        clr     PCM_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc

        ldx     #regbase
        bclr    porta,x,#%10000000      ;Disable DTS select.

        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        jsr     do_mute                 ;Mute output to avoid hiss

        ldaa    #$ff
        staa    deem_off_flag   ;>>>    ;Turn Emphasis OFF in this case.

        ldaa    #$0f                    ;Set up no ProL, yes SW, all OCFG bits
        jsr     ac3_proc1               ;Set up Z1 in AC3 mode
        delay   50*10                   ;Give Z1 time to boot AC-3.
        jmp     ac3_coding_cfg          ;Check coding_cfg now


;----------- AUTO MPEG ------------
auto_MPEG:
        ldaa    MPEG_in_proc
        beq     auto_MPEG_1             ;If not MPEG, boot up MPEG
        jmp     MPEG_coding_cfg         ;If already MPEG, check for errors


auto_MPEG_1:
        rtint   OFF

        ldaa    #1
        staa    MPEG_in_proc
        clr     PCM_in_proc
        clr     AC3_in_proc
        clr     DTS_in_proc

        ldx     #regbase
        bclr    porta,x,#%10000000      ;Disable DTS select.

        ldaa    #$ff
        staa    deem_off_flag   ;>>>    ;Turn Emphasis OFF in this case.

        ldaa    #20
        staa    coding_cfg              ;Indicate MPEG going on, flag change

        ldaa    #$0f
        jsr     mpeg_proc1              ;Boot up in MPEG
        delay   50*10                   ;Give Z1 time to boot MPEG

        ldaa    #17                     ;Set MPEG error counter to do
        staa    mpeg_err_ctr            ;correct unmutes if necessary
        jmp     MPEG_coding_cfg



;----------- AUTO DTS ------------
auto_DTS:
        rtint   ON

        ldx     #300                    ;Refresh DTS countdown timer
        stx     sticky_dts_ctr

        ldaa    DTS_in_proc
        bne     auto_exit               ;If already in DTS, do nothing

        ldaa    #1
        staa    DTS_in_proc
        clr     AC3_in_proc
        clr     PCM_in_proc
        clr     MPEG_in_proc

        ldaa    #$ff
        staa    deem_off_flag   ;>>>    ;Turn Emphasis OFF in this case.

        ldx     #regbase
        bset    porta,x,#%10000000      ;Assert dts select
        ldaa    #19
        staa    coding_cfg              ;Indicate DTS going on, flag change
        jmp     auto_change


;---------- FLAG CHANGES ----------
auto_change:
        ldaa    #$fe                    ;Flag changes necessary
        staa    screen_status1
auto_exit:
        rts


;***********************************************************************
;* Get AC-3 coding configuration information from Zoran 1
;*
;* Compiles the variable coding_cfg (composed of coding config & LFE info)
;* Any change, and a screen/Zoran refresh is flagged
;*
;***
ac3_coding_cfg:
        ldy     #stat_cmd               ;Read Z1 AC-3 status.
        jsr     WR_Z1

        ldaa    ret_inf+3
        anda    #%11100000              ;Get decoder status bits.
        beq     ac3_no_errors           ;If Status=0, no errors --> AC-3 OK

                                        ;If Status=1,2 (updating,error)
                                        ;read again.
op_error:
        ldaa    ms_save
        cmpa    #3                      ;Check if in Dig. 3
        bne     op_error1

;        brset   DIP_imag,#%00000100,op_error1  ;If DIP3 OFF, do more checks
;
;        ldaa    #15                     ;Dig. 3 and DIP #3 on,
;        staa    coding_cfg              ;so default to 5.1
;        jmp     ac3_coding_compare

op_error1:
        ldx     #regbase
        brclr   porte,x,#%00100000,op_error_2   ;If no f-flag, go on       
        jmp     auto_DTS                        ;If f-flag, do new DTS
        
op_error_2:
        delay   100*10                  ;!!! Look at this.....needed so as to
                                        ;!!! avoid AC3 update errors (if
                                        ;!!! too fast) leading to mute.
                                        ;!!! This delay cuts 100ms+ off DTS!!
        ldx     #regbase
        brclr   porte,x,#%00100000,op_error_3   ;If no f-flag, go on       
        jmp     auto_DTS                        ;If f-flag, do new DTS

op_error_3:
        ldy     #stat_cmd               ;Read Z1 AC-3 status (2nd time)
        jsr     WR_Z1
        ldaa    ret_inf+3
        anda    #%11100000              ;Get decoder status bits.
        beq     ac3_no_errors           ;If Status=0, no errors --> AC-3

        ldx     #regbase
        brclr   porte,x,#%00100000,op_error_4   ;If no f-flag, go on       
        jmp     auto_DTS                        ;If f-flag, do new DTS

op_error_4:
;* At this point, we have probably pressed SKIP or PAUSE or STOP
;* while playing AC3 or DVD DTS.


        clr     PCM_in_proc             ;Flush all flags to force a reboot
        clr     DTS_in_proc             ;next time around
        clr     AC3_in_proc
        clr     MPEG_in_proc            
        clr     coding_cfg

        ldaa    #$ff                    ;Flush Zoran mode to force fresh boot
        staa    z_mode

        rts




;****************************************************************
ac3_no_errors:

;** First check for F-flag just in case it has come on late

        ldx     #regbase
        brclr   porte,x,#%00100000,ac3_no_errors0                     
        jmp     auto_DTS                        ;If f-flag, do DTS

;** Now we are convinced that it is real AC3, so go ahead and
;** flush the DTS stickiness and determine the correct
;** coding configuration

ac3_no_errors0:

        ldaa    ret_inf+4
        anda    #%00111000
        cmpa    #$10                    ;Look for muting error
        bne     ac3_no_errors1     
        jmp     fix_ac3_mutes

ac3_no_errors1:

        ldx     #0
        stx     sticky_ac3_ctr          ;No AC3 stickiness!!!!!

;       ldx     #300                    ;Refresh sticky AC3 counter
;       stx     sticky_ac3_ctr

        clra
        ldab    ret_inf+14              ;Get dialog normalization value (0-31)
        andb    #%00011111
        stab    dianorm_val             ;Save raw dialog normalization dB value.

        lsld                            ;Get dB * 2 (due to CS3310 0.5 dB vol step)
        subd    #62         ;!!!!!!!!!!!;Ad hoc EAD factor to normalize AC-3 loudness.

        cpd     dialog_corr             ;Check for dialog changes
        beq     dia_no_change           ;If not, go on

        std     dialog_corr             ;If so, store change
                                     
        jsr     peek_corr               ;Get new vol. corrections
        jsr     unpack_vol              ;Do new volume 

dia_no_change:
        ldaa    ret_inf+10              ;Get decoder CCFG (coding configuration and LFE (0-15)
        anda    #%00001111
        ldab    ret_inf+12              ;Get surround flag information
        andb    #%00001100              

        cmpa    #2                      ;Check for 2/0
        bne     ac3_coding_1

        cmpb    #%00001000              ;No surround flag so no change (=2)
        bne     ac3_coding_compare

        ldaa    #16                     ;2/0 ProL flagged, no LFE
        bra     ac3_coding_compare


ac3_coding_1:
        cmpa    #8+2                    ;Check for 2/0 LFE
        bne     ac3_coding_compare 

        cmpb    #%00001000              ;No surround flag so no change (=2)
        bne     ac3_coding_compare

        ldaa    #17                     ;2/0 ProL flagged, LFE

ac3_coding_compare:
        cmpa    coding_cfg
        beq     ac3_coding_out          ;If no change, do nothing

        cmpa    #17
        bls     ac3_src_comp_2          ;If >17, bogus, so do it again

        jsr     chirp_H         ;!!!

        ldaa    #18                     ;Do PCM

ac3_src_comp_2:
        staa    coding_cfg              ;Coding configuration has changed! Store new value
        ldaa    #$fe
        staa    screen_status1          ;Flag new mode required.
ac3_coding_out:
        rts


fix_ac3_mutes:
        ldaa    #$0f
        jsr     ac3_proc1
        jmp     ac3_no_errors1


;***********************************************************************
;* MPEG coding error checking routine
;*
;*
;*                      Get present error status
;*                             /      \
;*                            /        \
;*                     Errors/          \No errors
;*                          /            \
;*                         /              \
;*                      Check   error   counter         
;*                     /  |                |\
;*                    /   |                | \
;*                   /    |0          non-0|  \0
;*                  /     |                |   \
;*                 /      |                |    \
;*            refresh  refresh             |     \
;*            counter  counter        dec ctr    rts 
;*              rts     MUTE             / |
;*                                 non 0/  |0
;*                                     /   |
;*                                    /  unmute
;*                                   /
;*                                 rts
;*
;*
;*
MPEG_coding_cfg:
        ldy     #stat_cmd               ;Read Z1 MPEG status.
        jsr     WR_Z1

        ldaa    ret_inf+3               ;Get present error status
        anda    #%11100000
        beq     MPEG_no_errors

MPEG_errors:
        ldab    mpeg_err_ctr            ;Get old value of counter
        ldaa    #17                     ;Refresh error counter
        staa    mpeg_err_ctr

        tstb                            ;Test old value of counter
        bne     MPEG_coding_exit        ;Non-zero means errors still
        bra     MPEG_mute               ;0 means it was unmuted before, so
                                        ;go and mute!


MPEG_no_errors:
        ldab    mpeg_err_ctr
        beq     MPEG_coding_exit        ;If zero,all is well so do nothing

        dec     mpeg_err_ctr            ;Count-down
        ldab    mpeg_err_ctr            ;Check new value
        beq     MPEG_unmute             ;If timed-out, we have consistent
                                        ;error-free behaviour so unmute!

                                        ;Otherwise, do nothing
MPEG_coding_exit:
        rts

MPEG_mute:
        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        jsr     do_mute
        rts

MPEG_unmute:
        brset   mute_status,#1,MPEG_unmute_exit    ;If user mute, don't unmute

        jsr     undo_mute
MPEG_unmute_exit:
        rts
        

;***********************************************************************
;* Emphasis logic...
;*
;* IMPORTANT! To avoid scrambling the PCM1732 serial control words,
;*            this routine must be called by the real-time interrupt
;*            service routine only!
;*
;***
emphasis_check:
        ldaa    deem_off_flag       ;>>>
        bne     emph_off            ;>>>

        ldaa    cs0_imag
        brset   cs0_imag,#%00000001,emph_prof   ;See if Consumer or Professional

emph_cons:
        anda    #%00111000
        cmpa    #%00001000
        bra     emph_on_off

emph_prof:
        anda    #%00011100
        cmpa    #%00001100

emph_on_off:
        bne     emph_off

emph_on:
        ldx     #regbase
        brset   porte,x,#%00100000,emph_off     ;(Only do if DTS not present)        

        ldd     #MODE2_DEM_on   
        jsr     WR_PCM1732                      ;PCM1732 emphasis ON

        bra     emph_end

emph_off:
        ldd     #MODE2_DEM_off  
        jsr     WR_PCM1732                      ;PCM1732 emphasis OFF
        clr     deem_off_flag       ;>>>

emph_end:
        rts


;***********************************************************************
;* Frequency checking
;*
;* IMPORTANT! To avoid scrambling the PCM1732 serial control words,
;*            this routine must be called by the real-time interrupt
;*            service routine only!
;*
;***
freq_check:
        ldaa    #21
        jsr     RD_CS4226                   ;Get Rx CS3 channel status byte (21)
        staa    cs3_imag                    ;(4 msbs contain consumer fs)
        brset   cs0_imag,#%00000001,freq_professional  ;Check for prof mode

freq_consumer:
        ldaa    cs3_imag
        anda    #%00001111
        beq     freq_set_44

        cmpa    #%00000010
        beq     freq_set_48

        cmpa    #%00000011
        beq     freq_set_32


freq_professional:
        ldaa    cs0_imag
        anda    #%11000000
        cmpa    #%11000000
        beq     freq_set_32

        cmpa    #%01000000
        beq     freq_set_44

        cmpa    #%10000000
        beq     freq_set_48

        ldaa    AC3_in_proc                 ;If not sure, 48kHz if AC3
        bne     freq_set_48                 ;             44.1kHz if stereo

freq_set_44:
        ldd     #MODE3_441        ;>>>
        jsr     WR_PCM1732                  ;Set SF=10 if 44.1 kHz indicated.
        ldaa    #1
        bra     freq_set_freq

freq_set_48:
        ldd     #MODE3_48         ;>>>
        jsr     WR_PCM1732                  ;Set SF=01 if 48 kHz indicated.
        ldaa    #2
        bra     freq_set_freq

freq_set_32:
        ldd     #MODE3_32         ;>>>
        jsr     WR_PCM1732                  ;Set SF=11 if 32 kHz indicated.
        ldaa    #3
freq_set_freq:
        ldab    fs_freq                     ;Get old value
        staa    fs_freq                     ;Store new value
        cba                                 ;Check for changes
        beq     freq_reads4  

        ldab    #1                          ;Flag changes
        stab    update_screen12             ; for Input Data Status screen.

freq_reads4:  
        ldaa    #48                         ;Force main loop Zoran reads asap!
        staa    zoran_cntr                  ; (avoids possible AC3 hiss)

        rts


;***********************************************************************
;*
;*  CinEQ 6-channel cinema EQ (aka HFEQ) on/off
;*
;***
hfeq:   ldaa    ps_frame
        cmpa    #k_HFEQ_on
        beq     hfeq_on_off         

        cmpa    #k_HFEQ_off                     ;If RS232 control, do not worry
        beq     hfeq_on_off                     ; about being in Main screen

        ldaa    screen_num
        cmpa    #.SCREEN.Main                   ;If IR control,
        bne     hfeq_rts                        ; only process if in Main screen

hfeq_on_off:
        brclr   DIP_imag,#%00010000,hfeq_togl_2 ;If HDCD override on, continue

        brset   ms_save,#$80,hfeq_togl_2        ;If analog, do not check for PCM

        ldaa    PCM_in_proc
        beq     hfeq_togl_2                     ;If not PCM contiue

hfeq_togl_1:
        jsr     get_curr_mode                   ;Otherwise, check for Matrix, Stereo
        tsta                            
        beq     hfeq_rts

        cmpa    #2
        beq     hfeq_rts                        ;If in Matrix (2), Stereo (0), do nothing

hfeq_togl_2:
        jsr     get_correct_hfeq                ;y points to correct HFEQ flag

        ldaa    ps_frame
        cmpa    #k_HFEQ_on                      ;Check for HFEQ on RS232 command
        beq     hfeq_on             

        cmpa    #k_HFEQ_off                     ;Check for HFEQ off RS232 command
        beq     hfeq_off                    
        
hfeq_togl_3:                                    ;Otherwise, do HFEQ toggle
        ldaa    0,y       
        beq     hfeq_on

hfeq_off:
        clr     0,y
        bra     hfeq_icon

hfeq_on:
        ldaa    #1
        staa    0,y
hfeq_icon:
        bset    icon_flag,#%00000010            ;Update HFEQ icon
hfeq_end:
        jsr     force_new_Z                     ;Go into new Zoran mode
hfeq_rts:
        rts


get_correct_hfeq:                               ;Get HFEQ flag for correct input
        ldy     #hfeq_dig_flag
        ldab    ms_save
        decb
        andb    #%01111111
        brclr   ms_save,#%10000000,corr_hfeq

        addb    #6
corr_hfeq:
        aby
        rts


;***********************************************************************
;*
;* Extra Surround speaker on/off
;* =     =
;*
;***
ES_togl:
        ldy     #es_flag
        ldaa    ps_frame
        cmpa    #k_ES_on
        beq     es_on         

        cmpa    #k_ES_off                       ;If RS232 control, do not worry
        beq     es_off                          ; about being in Main screen

        ldaa    screen_num
        cmpa    #.SCREEN.Main                   ;If IR control,
        bne     es_rts                          ; only process if in Main screen

es_on_off:
        ldaa    0,y
        beq     es_on             

es_off: clr     0,y
        bra     es_icon

es_on:  bset    0,y,#$ff

es_icon:
        bset    icon_flag,#%00000100            ;Update ES icon
        jsr     force_new_Z                     ;Go into new Zoran mode
es_rts:
        rts


;***********************************************************************
;*
;* Party/Stereo mode on/off toggle
;*
;***
party_stereo_toggle:
        ldy     #party_flag
        ldaa    ps_frame
        cmpa    #k_party_on 
        beq     go_to_party 

        cmpa    #k_party_off                    ;If RS232 control, do not worry
        beq     go_to_stereo                    ; about being in Main screen

        ldaa    screen_num
        cmpa    #.SCREEN.Main                   ;If IR control,
        bne     party_rts                       ; only process if in Main screen

party_togl:
        brset   0,y,#$ff,go_to_stereo

go_to_party:
        bset    0,y,#$ff                        ;Party mode.
        bra     update_party_icon

go_to_stereo:
        clr     0,y                             ;Stereo mode.

update_party_icon:
        bset    icon_flag,#%00010000            ;Update Party icon
end_of_party:
        jsr     force_new_Z                     ;Go into new Zoran mode
party_rts:
        rts


;***********************************************************************
;*
;* Movie/Music mode toggle
;*
;***
movie_music_togl:
        ldy     #spkr_cfg
        ldaa    ps_frame
        cmpa    #k_movie
        beq     get_movie         

        cmpa    #k_music                        ;If RS232 control, do not worry
        beq     get_music                       ; about being in Main screen

        ldaa    screen_num
        cmpa    #.SCREEN.Main                   ;If IR control,
        bne     movie_rts                       ; only process if in Main screen

mm_togl:
        brset   0,y,#%0010,get_movie

get_music:
        bset    0,y,#%0010                      ;Music mode.
        bra     music_icon

get_movie:
        bclr    0,y,#%0010

music_icon:
        bset    icon_flag,#%00001000            ;Update Music icon
movie_end:
        jsr     force_new_Z                     ;Go into new Zoran mode
movie_rts:
        rts


;***********************************************************************
;*
;* Speaker Configuration: Ref.Cinema vs Cinema 7.1 layout
;*
;***
spkr_config:
        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Cfg               ;If already in Spkr Config screen,
        beq     do_spkr_cfg_togl                ; go ahead and toggle...

        ldaa    flash_up                        ;Else, start flash up of Spkr Config screen,
        beq     spkr_1st                        ; just save keypress.
        jmp     Spkr_Config_screen              ; Prevent toggle by just putting up Spkr Config screen...

spkr_1st:
        ldaa    #1                              ;Comes here with first press only.
        staa    screen_status1                  ;Start timer for screen flashing. 
        staa    flash_up
        jsr     LCD_init
        jmp     Spkr_Config_screen              ;Put up Speaker Config screen.

do_spkr_cfg_togl:
        ldaa    spkr_cfg
        eora    #%0001                          ;Toggle between Ref.Cinema & Cinema 7.1 layouts
        anda    #$0001
        bne     sel_Cinema71
        
sel_RefCinema:
        ldaa    #%1000                          ;Select Ref.Cinema with 2 subs (default).
        bra     store_spkr_cfg

sel_Cinema71:
        ldaa    #%0101                          ;Select Cinema 7.1 Movie with 1 sub (default).

store_spkr_cfg:
        staa    spkr_cfg
        ldab    #ee_spkr_cfg      
        jsr     write_globals     
        jsr     Spkr_Config_screen

        ldaa    #1                              ;Flash up Spkr Config screen
        staa    screen_status1                  ; to allow user to see the
        staa    flash_up                        ; results of the change,
        jsr     force_new_Z                     ; and force new Zoran mode
        rts


;***********************************************************************
;***********************************************************************
;***********************************************************************
;*
;* Main loop screen display
;*
;* Displays the screen corresponding to the value in screen_num.
;*
;*
;***
display_scrn:
         ldaa    screen_num

;****************************************************
;** TM screens (= top two TMSetup screens):
;****************************************************
scrn1:   cmpa    #.SCREEN.Main                  ;MAIN screen.
         bne     scrn2
         jmp     MAIN_screen

;----------------------------------------------------
scrn2:   cmpa    #.SCREEN.VU_meter              ;Output VU meter (2/6-ch bar graph)
         bne     scrn3
         jmp     Output_VU_screen

;****************************************************
;** Balance of TMSetup screens:
;****************************************************
scrn3:   cmpa    #.SCREEN.Spkr_Adj              ;Speaker Adjustment screen.
         bne     scrn4a
         jmp     Spkr_adj_screen

;----------------------------------------------------
scrn4a:  cmpa    #.SCREEN.Spkr_Cfg              ;Speaker Configuration screen.
         bne     scrn4
         jmp     Spkr_Config_screen

;----------------------------------------------------
scrn4:   cmpa    #.SCREEN.Bass_Man              ;Bass Management screen.
         bne     scrn5
         jmp     Bass_man_screen

;----------------------------------------------------
scrn5:   cmpa    #.SCREEN.Spkr_Dist             ;Speaker Distances screen.
         bne     scrn6
         jmp     Spkr_dist_screen

;----------------------------------------------------
scrn6:   cmpa    #.SCREEN.Anlg_Atten            ;Analog Input Attenuation screen.
         bne     scrn7
         jmp     Analog_input_atten_screen

;----------------------------------------------------
scrn7:   cmpa    #.SCREEN.Sys_Config            ;System Configuration screen.
         bne     scrn8
         jmp     System_config_screen

;----------------------------------------------------
scrn8:   cmpa    #.SCREEN.Feat_Sel              ;Features Selection screen.
         bne     scrn9 
         jmp     Features_selection_screen

;----------------------------------------------------
scrn9:   cmpa    #.SCREEN.Dig_AVLink            ;Digital A/V Links screen.
         bne     scrn10
         jmp     display10

;----------------------------------------------------
scrn10:  cmpa    #.SCREEN.Anlg_AVLink           ;Analog A/V Links screen.
         bne     scrn11
         jmp     display11

;----------------------------------------------------
scrn11:  cmpa    #.SCREEN.AnlgPT_AVLink         ;Analog Pass-Thru A/V Links screen.
         bne     scrn12
         jmp     display11a

;----------------------------------------------------
scrn12:  cmpa    #.SCREEN.Inp_Data_Stat         ;Input Data Status screen.
         bne     scrn13

         jsr     display12
         jmp     display12_VCP

;----------------------------------------------------
scrn13:  cmpa    #.SCREEN.Dig_Inp_Desig         ;Digital Input Designators screen.
         bne     scrn14
         jmp     display13

;----------------------------------------------------
scrn14:  cmpa    #.SCREEN.Anlg_Inp_Desig        ;Analog Input Designators screen.
         bne     scrn15
         jmp     display14

;----------------------------------------------------
scrn15:  cmpa    #.SCREEN.AnlgPT_Inp_Desig      ;Analog Pass-Thru Input Designators screen.
         bne     scrn16
         jmp     display14a

;----------------------------------------------------
scrn16:  cmpa    #.SCREEN.IR_Test               ;IR Remote Control Test screen.
         bne     scrn17
         jmp     IR_remote_test

;----------------------------------------------------
scrn17:
         rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 1 -- MAIN Screen    
;*
;***
MAIN_screen:
        bset    icon_flag,#%00011111            ;Default to icons updated

        ldaa    #%00111111                      ;Default to all channels
        staa    curr_chs                        ;currently selected
        clr     xover_rolloff
        clr     test_screen

        ldaa    ms_save                         ;Determine whether dig or analog
        anda    #%10000000                      ; by looking at msb.
        beq     digital_display                 ;MSB=0, do digital inputs
        jmp     stereo_displays                 ;MSB=1, do analog inputs


;%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%% DIGITAL MODES:
;%%%%%%%%%%%%%%%%%%%%%%%%%%
digital_display:
        clra
        ldab    locked
        beq     dig_disp1
        jmp     dig_disp_no_lock                ;Locked not zero means no lock
                                                ;i.e., Locked=zero means locked!!!
dig_disp1:
        ldaa    DTS_in_proc                     ;Check for DTS
        beq     dig_disp2
        jmp     dig_disp_dts 

dig_disp2:
        ldaa    AC3_in_proc                     ;Check for AC3
        bne     dig_disp_AC3

dig_disp3:
        ldaa    MPEG_in_proc
        beq     .stereo_displays
        jmp     dig_disp_MPEG

.stereo_displays:
        jmp     stereo_displays                 ;!!!


;***********************************************************************
;* AC3 screens:
;*  
;*
;*                        CODING CONFIGURATION
;*
;*      0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19
;*      D  1  2  3  2  3  2  3  D  1  2  3  2  3  2  3  2  2  2  3
;*      M  /  /  /  /  /  /  /  M  /  /  /  /  /  /  /  /  /  /  /
;*         0  0  0  1  1  2  2     0  0  0  1  1  2  2  0  0  0  2
;*           Not                /  /  /  /  /  /  /  /  F  F  P  /
;*            F                .1 .1 .1 .1 .1 .1 .1 .1    .1  C .1
;*     \-------------------------AC3------------------------/ M  D
;*                                                               T
;*                                                               S
;* F   = LtRt-flagged AC3 bitstream
;* DM  = Dual Mono AC3 bitstream
;* PCM = Pulse Code Modulation
;* DTS = Digital Theater Systems bitstream
;*
;***

coding_to_daisy:
  dc.b  2, 6, 2, 4, 1, 3, 5, 0,10,14,10,12, 9,11,13, 8, 1, 9, 2, 8


blurb_nums:
  dc.b  1, 1, 2, 3, 4, 5, 6,13, 1, 1, 2, 3, 4, 5, 6,14, 8, 8 ;Defaults
  dc.b  2, 9, 2, 9, 9, 9, 9, 9, 2, 9, 2, 9, 9, 9, 9, 9, 9, 9 ;Stereo
  dc.b  1, 1,12, 3, 4, 5, 6,13, 1, 1,12, 3, 4, 5, 6,14, 8, 8 ;Surround
  dc.b  1, 1,10,10, 4, 5, 6,13, 1, 1,10,10, 4, 5, 6,14, 8, 8 ;Matrix
  dc.b 11,11, 2, 3, 4, 5, 6,13,11,11, 2, 3, 4, 5, 6,14, 8, 8 ;Mono


dig_disp_AC3:
        clr     mat_flag                        ;Clear matrix flag.

        ldaa    #%00111111                      ;Put up all channels
        staa    mode_chs                        
        ldy     #coding_to_daisy                ;Point to conversion table
        ldab    coding_cfg                      ;Get Zoran AC3 info
        aby
        ldaa    0,y                             ;Get empty LFE daisy number
        staa    daisy_num

        tsx                                     ;Create 13-byte local buffer on the stack. 
        xgdx
        subd    #13
        xgdx
        txs

        jsr     LCD_init                        ;Clear screen

        ldy     #dolby_dig_blurb                ;Put up |)(| Digital blurb
        ldaa    #4
        jsr     SCREENS

        ldab    curr_mode_ac3                   ;(MODE+1)x18 + CFG = NUMBER
        incb  
        ldaa    #18                             ;Number of columns in blurb_nums.
        mul
        addb    coding_cfg
        ldy     #blurb_nums
        aby
        ldaa    0,y                             ;Get blurb number

        ldab    z_error                         ;Check if Z mode override error
        beq     blurb_no_err

                                                ;If error get N/A flag:
        clr     z_error                         ;Clear error flag for 2nd time
        ldab    #1
        stab    screen_status1                  ;Start 2s timer for update later
                                                ; (will put up correct label).
        stab    flash_up                        ;Flag flashing up.
        jsr     show_HFEQ                       ;Show HFEQ icon if necessary'

        ldaa    #0                              ;If error, get ":N/A" blurb

blurb_no_err:

;* Dolby want this case for 2/0 LtRt-flagged sources:
        cmpa    #8                              ;Check for 2/0 RtLt-flagged blurb
        bne     blurb_no_err_1

        ldaa    #4                              ;Change the whole thing for this!
        ldy     #dolby_20_prol
        jsr     SCREENS
        bra     blurb_no_err_2

blurb_no_err_1:
        ldab    #6 
        mul
        ldy     #selection_to_blurb             ;Point into data table
        aby                                     ;Update to correct blurb

        tsx
        ldd     0,y                             ;Store blurb
        std     0,x
        ldd     2,y
        std     2,x
        ldd     4,y
        std     4,x                             
        ldaa    #'|'
        staa    6,x
        ldd     #$2020                          ;No special fonts.
        std     7,x
        std     9,x
        std     11,x

        tsy                                     ;Display specific blurb
        ldaa    #14                             ; starting at position 14.
        jsr     SCREENS

blurb_no_err_2:
        tsx                                     ;Deallocate stack buffer area.
        xgdx
        addd    #13
        xgdx
        txs

        ldaa    daisy_num
        jsr     daisy                           ;Source coding config indicator daisy.
        jsr     channel_num                     ;Dx or Ax
        ldaa    #26                             ;Screen pos'n.
        jsr     input_label                     ;Input label
        jsr     err_star
        jsr     Small_Volume                    ;Volume readout at bottom right
        rts


;***********************************************************************
;* No lock screens
;***
dig_disp_no_lock:
        clr     mat_flag                        ;Clear matrix flag.

        ldaa    ms_save  
        cmpa    t_dts_inp
        beq     no_lk_dts

        cmpa    t_mpeg_inp
        beq     no_lk_mpeg

;        cmpa    #2
;        bne     dig_no_lk0
;
;        brclr   DIP_imag,#%00000010,no_lk_dts   ;If Dig. 2 and DIP #2 on, DTS
;
;dig_no_lk0:
;        cmpa    #3
;        bne     dig_no_lk1
;
;        brclr   DIP_imag,#%00000100,no_lk_ac3   ;If Dig. 3 and DIP #3 on, AC-3
;
;dig_no_lk1:
        cmpa    #4
        bne     dig_no_lk2

        brclr   DIP_imag,#%00001000,no_lk_mpeg  ;If Dig. 4 and DIP #4 on, MPEG

dig_no_lk2:
        ldy     #no_lock_screen                 ;Normal no lock
        bra     no_lk_rest

no_lk_mpeg:
        ldy     #no_lock_mpeg                   ;MPEG no lock
        bra     no_lk_rest

no_lk_ac3:
        ldy     #no_lock_ac3                    ;AC3 no lock
        bra     no_lk_rest

no_lk_dts:
        ldy     #no_lock_dts                    ;DTS no lock 
no_lk_rest:
        ldaa    #%00111111
        staa    mode_chs

        pshy
        jsr     clear_corrs                     ;Clear volume corrections
        jsr     unpack_vol                      ;Set up volume correctly
        puly

        ldaa    #7
        staa    daisy_num
        jmp     do_screen1


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%% ANALOG & STEREO MODES:
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stereo_displays:
        clr     mat_flag                        ;Clear matrix flag.

        ldaa    curr_pass_mode                  
        beq     .stereo_displays2               
                                                
;--------------------------------------------------------
;%% Raise bit D6 of DAC8 latch1 if pass-thru input is A9...
;%% (This signal can be used to control another set of relays
;%% that will separate A9 from A8 and A7). 
        cmpa    #3                              ;If pssthru8=3 (input A9),
        beq     .setbit6                        ; set bit D6 of DAC8_latch1, else clear it.
                                            
        bclr    DAC8_imag1,#%01000000           ;Clear bit D6. 
        bra     .update_latch1              
                                            
.setbit6:                                   
        bset    DAC8_imag1,#%01000000           ;Set bit D6.
.update_latch1:                             
        jsr     update_DAC8_latch1          
;--------------------------------------------------------

        ldaa    curr_pass_mode
        deca
        anda    #%00000011                      
        jmp     do_ana_screen1                  

.stereo_displays2:
        ldaa    curr_mode                       ;See if stereo, etc.
        bne     ster_disp1

        ldy     #Stereo
        ldaa    #%00100011                      ;LF,RF,SB active.
        staa    mode_chs
        bra     show_ster_screen


ster_disp1:
        cmpa    #1
        bne     ster_disp2

        ldy     #Surround
        ldaa    #%00111111                      ;All channels active.
        staa    mode_chs

        ldaa    #1                              ;2/P/0 source daisy pointer.
        staa    daisy_num
        jmp     do_screen1


ster_disp2:
        cmpa    #2
        bne     ster_disp3

        ldaa    #1
        staa    mat_flag                        ;Flag matrix mode for -4 dB LS,RS adjustment.

        ldy     #Matrix
        ldaa    #%00101111                      ;LF,RF,LS,RS,SB active.
        staa    mode_chs
        bra     show_ster_screen


ster_disp3:
        ldy     #Mono
        ldaa    #%00110011                      ;LF,RF,CR,SB active.
        staa    mode_chs
show_ster_screen:
        ldaa    #2                              ;2/0/0 source daisy pointer.
        staa    daisy_num
        jmp     do_screen1


;***********************************************************************
;* dts screens
;***
dig_disp_dts:
        clr     mat_flag                        ;Clear matrix flag.

        ldaa    z_error
        beq     dig_disp_dts0                   ;If no errors, all ok

        clr     z_error                         ;Clear error flag for 2nd time
        ldab    #1
        stab    screen_status1                  ;Start 2s timer for update later
        stab    flash_up
        ldy     #dts_n_a                        ;If errors, show N/A
        bra     show_dts_screen

dig_disp_dts0:
        ldaa    curr_mode_dts                   ;Get user dts mode
        cmpa    #0
        beq     dts_ster_blurb

dts_default:
        ldy     #dts_5_1
        bra     show_dts_screen

dts_ster_blurb:
        ldy     #dts_stereo

show_dts_screen:
        ldaa    #%00111111                      ;All channels active
        staa    mode_chs

        ldaa    #8                              ;3/2/.1 source daisy pointer.
        staa    daisy_num
        jmp     do_screen1


;***********************************************************************
;* MPEG2 screens
;***
dig_disp_MPEG:
        clr     mat_flag                        ;Clear matrix flag.

        ldaa    curr_mode_mpeg                  ;Get user MPEG2 mode
        cmpa    #$ff
        beq     MPEG_default_blurb

        cmpa    #0
        beq     MPEG_default_blurb

        cmpa    #1
        beq     MPEG_ProL_blurb

        cmpa    #2
        beq     MPEG_matrix_blurb

MPEG_mono_blurb:
        ldy     #MPEG_mono  
        ldaa    #%00110011                                
        staa    mode_chs
        bra     show_MPEG_screen
        
MPEG_matrix_blurb:
        ldaa    #1
        staa    mat_flag                        ;Flag matrix mode for -4 dB LS,RS adjustment.

        ldy     #MPEG_matrix
        ldaa    #%00101111                                   
        staa    mode_chs
        bra     show_MPEG_screen

MPEG_ProL_blurb:
        ldy     #MPEG_ProL
        ldaa    #%00111111                      ;All channels active
        staa    mode_chs
        bra     show_MPEG_screen

MPEG_default_blurb:
        ldy     #MPEG_stereo
        ldaa    #%00100011                                  
        staa    mode_chs

show_MPEG_screen:
        ldaa    #2                              ;2/0/0 source daisy pointer.
        staa    daisy_num
        jmp     do_screen1


;**********************************************************************
;All "digital" inputs...
do_screen1:
        jsr     LCD_init                        ;Clear screen
        jsr     daisy                           ;Show daisy. Source CCF is in A.
        jsr     blurb                           ;Main text
        jsr     channel_num                     ;Dx or Ax
        ldaa    #26                             ;Screen pos'n.
        jsr     input_label                     ;Input label
        jsr     err_star
        jsr     Small_Volume                    ;Volume readout at bottom right
        rts


daisy:  pshy
        ldab    #14                             ;Convert daisy number into
        mul                                     ;address
        addd    #daisies
        xgdy
        clra
        jsr     SCREENS

        ldaa    #20
        ldab    #7
        aby
        jsr     SCREENS

        puly
        rts


blurb:  ldaa    #4
        jsr     SCREENS
        rts


;**********************************************************************
;All analog pass-through inputs...
do_ana_screen1:
        jsr     LCD_init                        ;Clear screen
        jsr     ana_daisy                       ;Show "daisy". # channels is in A
        ldy     #analog_passthru                ;Put special blurb at pos'n 4.

;%%% Signal that 8-channel analog pass-thru is N/A in Cinema 7.1 Movie mode:
        ldaa    spkr_cfg
        anda    #%0011
        cmpa    #%0001              
        bne     .ana_scrn_cont                  ;If not 7.1 Movie, continue...

        ldaa    curr_pass_mode                  ;Here if 7.1 Movie mode...
        cmpa    #3                              ;If not 8-channel pass-thru (A9),
        bne     .ana_scrn_cont                  ; also continue...

        ldy     #anlg_passthru_NA               ;Put up special 'N/A' blurb for
                                                ; Cinema 7.1 Movie mode.

.ana_scrn_cont:
        ldaa    #4                              ;Screen pos'n.
        jsr     SCREENS

        jsr     channel_num
        ldaa    #26                             ;Screen pos'n.
        jsr     input_label
        jsr     Small_Volume
        rts


ana_daisy:
        pshy
        anda    #$03                            ;Only want the two lsbs.
        ldab    #7                              ;Convert daisy number into
        mul                                     ;address
        addd    #analog_daisies
        xgdy
        ldaa    #0                              ;Position on screen.
        jsr     SCREENS

        ldaa    #20
        ldy     #analog_daisies
        ldab    #7*3
        aby
        jsr     SCREENS

        puly
        rts


;%%% Misc. Screen 1 display routines...
channel_num:
        des
        des
        des
        des
        des
        tsy

        ldaa    ms_save
        anda    #%10000000
        beq     dig_channel

ana_channel:
        ldaa    #'A'
        staa    0,y
        bra     chan_number

dig_channel:
        ldaa    #'D'
        staa    0,y
chan_number:
        ldaa    ms_save
        anda    #%01111111              ;Mask out analog indicator
        adda    #$30
        staa    1,y                     ;Input channel number
        ldaa    #'|'
        staa    2,y
        ldaa    #$20
        staa    3,y
        staa    4,y
        ldaa    #24                     
        jsr     SCREENS                 ;Display number at position 25

        ins
        ins
        ins
        ins
        ins
        rts


;------------------------------------------------
input_label:
        tsx
        psha                            ;Save position
        xgdx
        subd    #10                     ;Reserve stack space
        xgdx
        txs                             ;X points to local variables

        ldab    ms_save                 
        tba
        andb    #%01111111              ;Get channel number information in B
        decb
        anda    #%10000000              ;Get analog/digital information in A
        beq     dig_labs

ana_labs:
        ldy     #Ana_labels
        bra     get_labs

dig_labs:
        ldy     #Dig_labels
get_labs:
        aby
        ldaa    0,y                     ;Get label pointer
        ldab    #4
        mul                             ;Convert pointer to address offset
        ldy     #key_labels             ;Get starting address of labels
        aby
        ldd     0,y                     ;Put characters on the stack
        std     0,x
        ldd     2,y
        std     2,x
        ldaa    #'|'                    ;End of string character
        staa    4,x

        ldd     #$2020                  ;Normal font
        std     5,x
        std     7,x
        tsy
        ldaa    9,x                     ;Restore position
        jsr     SCREENS                 ;Display label
       
input_label_end:
        tsx                    
        xgdx
        addd    #10                     ;Reserve stack space
        xgdx
        txs                             ;x points to local variables
        rts


err_star:
        ldaa    test_screen             ;See if we are in a test screen
        beq     err_star_0              ;If not all ok
        rts                             ;Otherwise do nothing

err_star_0:
        brset   ms_save,#$80,ana_err_star       ;Check if Analog or Digital

        ldaa    locked
        bne     err_star_clr                    ;No star if unlocked

dig_err_star:
        ldaa    update_screen12
        cmpa    #2
        beq     err_star_clr            ;Check if flag needs to be cleared

        ldaa    rs_imag
        anda    #%00001111
        beq     err_star_clr            ;If V,C,P clear, show colon
        bra     err_star_up             ;If V,C or P show error star

ana_err_star:
        ldaa    clippage                ;Check for clipping
        beq     err_star_clr

err_star_up:
        ldaa    #15
        staa    err_star_ctr            ;Refresh error star counter

        ldy     #clippage_star          ;Put up a star
        bra     err_posn_show

err_star_clr:                           ;Check if colon or space to be put up
        ldab    ms_save                 ;(depends on label!)
        tba
        andb    #%01111111              ;Get channel number information in B
        decb
        anda    #%10000000              ;Get analog/digital information in A
        beq     err_dig_labs

err_ana_labs:
        ldy     #Ana_labels
        bra     err_get_labs

err_dig_labs:
        ldy     #Dig_labels
err_get_labs:
        aby
        ldaa    0,y                     ;Get label pointer
        beq     err_star_spce           ;If no label, put up a space

err_star_col:
        ldy     #clip_colon             ;Put up a colon
        bra     err_posn_show      

err_star_spce:
        ldy     #spaces                 ;Put up a space

err_posn_show:
        ldaa    #26
        jsr     SCREENS
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 2 -- Output VU Meter Screen
;*
;***
Output_VU_screen:
        ldaa    #1
        staa    three_secs              ;Three sec timer for names
        clr     ovcnt2                  ;Update counter
        clr     screen_status1          ;Clear off big nums
        jsr     LCD_init
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 4 -- Speaker Configuration: Reference Cinema vs. Cinema 7.1
;*
;***
Spkr_Config_screen:
        ldaa    spkr_cfg             ;Which Speaker Config,
        anda    #%0001               ; Ref.Cinema or Cinema 7.1?
        beq     sel_ref_cinema
        jmp     sel_cinema71

;%%%%%
sel_ref_cinema:
        ldy     #Spkr_cfg_RefCinema
        jsr     screen_out

        ldaa    spkr_cfg
        anda    #%1100
        beq     sel_no_subs

        cmpa    #%0100               ;1 sub (= SUB-R) (default).
        beq     sel_1R_sub

        cmpa    #%1000               ;2 subs.
        beq     sel_2_subs
        
sel_no_subs:
        ldy     #subs0_sign
        bra     spkr_cfg_show

sel_2_subs:
        ldy     #subs2_sign
        bra     spkr_cfg_show

sel_1R_sub:
        ldy     #subs1R_sign

spkr_cfg_show:
        ldaa    #37                  ;Position of subwoofers on screen.
        jsr     SCREENS

        ldaa    es_flag              ;ES speaker enabled?
        beq     ES_disabled

ES_enabled:
        tsx
        xgdx
        subd    #17                  ;Allocate stack space for ES volume buffer.
        xgdx
        txs

        jsr     ES_blurb             ;Fill ES volume blurb string.
        tsy                          ;Point to string
        ldaa    #20      
        jsr     SCREENS              ; and display it. 

        tsx
        xgdx
        addd    #17                  ;Deallocate stack buffer.
        xgdx
        txs
        bra     ES_out

ES_disabled:
        ldy     #ES_off_sign
        ldaa    #20
        jsr     SCREENS              ;Display ES _____ sign on screen.
ES_out: rts                    ;***Return***


;%%%%%
sel_cinema71:
        ldy     #Spkr_cfg_Cinema71
        jsr     screen_out

        ldaa    spkr_cfg
        anda    #%0100               ;Check # subwoofers.
        bne     sel_yes_sub          

sel_no_sub:                          
        ldy     #sub0_sign           ;0 subs.
        bra     sel_show_sub

sel_yes_sub:
        ldy     #sub1_sign           ;1 sub.

sel_show_sub:
        ldaa    #39                  ;Position of subwoofer on screen.
        jsr     SCREENS

        ldaa    spkr_cfg
        anda    #%0010               ;Check speaker mode.
        bne     sel_music            

sel_movie:
        tsx
        xgdx
        subd    #17                  ;Allocate stack space for ES volume buffer.
        xgdx
        txs

        jsr     ES_blurb             ;Fill ES volume blurb string.
        tsy                          ;Point to string
        ldaa    #26      
        jsr     SCREENS              ; and display it. 

        tsx
        xgdx
        addd    #17                  ;Deallocate stack buffer.
        xgdx
        txs

        ldy     #movie_sign          ;Movie.
        bra     mode_show

sel_music:
        ldy     #music_sign          ;Music.

mode_show:
        ldaa    #20                  ;Position of Movie/Music sign on screen.
        jsr     SCREENS
        rts                    ;***Return***

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;% Fill ES Volume Blurb String For Display On Spkr Config Screen
;%%%
ES_blurb:
        ldd     #$8553               ;'ES'
        std     0,x                  ;Place into display buffer.

        ldy     #CS3310_vol_imag
        ldab    LS,y
        clra
        addb    RS,y
        adca    #0
        lsrd                         ;b = mean of LS, RS volumes.

        ldaa    ES,y
        sba                          ;a = a - b = ES offset from Mean(LS,RS).   
        bgt     pos_difference

neg_difference:
        nega
        ldab    #'-'
        stab    2,x                  ;'-' sign for negative ES volume offset
        bra     convert2dB

pos_difference:
        ldab    #'+'
        stab    2,x                  ;'+' sign for positive ES volume offset

convert2dB:
        tab                          ;Binary ES volume offset is in b.
        cmpb    #198
        blt     ES_ok

        ldab    #198
ES_ok:  pshx
        jsr     vtodB2
        pulx
        ldy     #dbufr               ;Point to ASCII ES volume string.
        ldaa    1,y       
        adda    #$30                 ;Convert to ASCII
        staa    3,x                  ;10s dB

        ldaa    #'.'
        staa    4,x                  ;'.'

        ldaa    2,y
        adda    #$30                 ;Convert to ASCII
        staa    5,x                  ;1/10s dB

        ldd     #'dB'
        std     6,x                  ;'dB'

        ldaa    #'|'
        staa    8,x                  ;'|' end of string marker

        ldd     #'  '                ;Font string...
        std     9,x
        std     11,x
        std     13,x
        std     15,x
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 5 -- Bass Management (Speaker sizes, re-direction or x-over, roll-off)
;*
;***
kicker_posns:
        dc.b    2,16,22,36,9,29

Bass_man_screen:
        ldaa    #$ff
        staa    dec_key
        ldaa    mode_chs                ;Save mode channels
        psha
        ldaa    #%00111111
        staa    mode_chs                ;All labels up
        clr     chs_seld                ;No channels highlighted
        jsr     highlight_spkrs         ;Put up speaker names 
        pula
        staa    mode_chs                ;Restore mode channels

xover_temp:     equ     0
roll_temp:      equ     1
kicker_ctr:     equ     2
kicker_bits:    equ     3

Bass_man_info:
        des
        des
        des
        des
        tsx

        ldaa    xover_chs
        ldab    rolloff_chs

        brset   active_chs,#%00100000,bm_info_1   ;If SUB enabled all ok
        anda    #%00111100                        ;If SUB disabled, show
        andb    #%00111100                        ;fronts as NOT xover'd or
                                                  ;rolled-off
bm_info_1:
        staa    xover_temp,x            ;Save cross-over info
        stab    roll_temp,x

        clr     kicker_ctr,x            ;Start counter for channels
        ldaa    #1
        staa    kicker_bits,x
xover_loop:
        ldy     #kicker_posns
        ldab    kicker_ctr,x
        aby
        ldaa    0,y                     ;Get position information
        ldab    kicker_bits,x
        andb    active_chs              ;See if this channel active
        bne     xover_loop1

        ldy     #deselect
        jsr     SCREENS                 ;Show deselection ____

        lsr     roll_temp,x             ;Update bit counters
        lsr     xover_temp,x

        bra     next_kicker

xover_loop1:
        lsr     roll_temp,x             ;Get big/small speaker info
        bcs     sml_spkr                ;1=small kicker

lrg_spkr:                               ;0=large kicker
        ldy     #lrg_kick
        bra     show_kickers

sml_spkr:
        ldy     #sml_kick
show_kickers:
        psha
        jsr     SCREENS                 ;Display kicker
        pula
        inca                            ;Update position
        inca
        lsr     xover_temp,x            ;Get cross over info
        bcc     not_x_overed            ;0=not crossed over (no symbol)

x_overed:                               ;1=crossed over (x symbol)
        ldy     #xover_sym
        bra     show_xover

not_x_overed:
        ldy     #spaces
show_xover:
        jsr     SCREENS                 ;Put up symbol

next_kicker:
        inc     kicker_ctr,x
        asl     kicker_bits,x
        ldaa    kicker_ctr,x
        cmpa    #6
        bne     xover_loop

        ins
        ins
        ins
        ins
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 6 -- Speaker distances
;*
;***
Spkr_dist_screen:
        clr     chs_seld                ;No speaker highlighted to begin
        clr     curr_chs
        jsr     LCD_init

spkr_dist_labs:
        ldaa    mode_chs
        psha
        ldaa    #$1f
        staa    mode_chs                ;Show all speakers except sub
        ldaa    #$ff
        staa    dec_key
        jsr     highlight_spkrs         ;Put up correct labels
        pula
        staa    mode_chs

spkr_dist_nums:

dist_ctr:       equ     9
        tsx
        xgdx
        subd    #10
        xgdx
        txs

        clr     dist_ctr,x
dist_ctr_loop:
        tsx
        ldaa    #'.'
        staa    1,x
        ldaa    #'m'
        staa    3,x
        ldaa    #'|'
        staa    4,x
        ldd     #'  '                   ;$2020
        std     5,x
        std     7,x
        ldab    dist_ctr,x
        ldy     #channel_pol
        aby
        ldaa    0,y                     ;Get correct channel polarity
        beq     dist_pos

        cmpa    #1
        beq     dist_neg

dist_undet:
        ldaa    #'m'                    ;If MSB set, display 'm'
        bra     set_dist_pol            

dist_neg:
        ldaa    #'-'                    ;If 1, display '-'
        bra     set_dist_pol

dist_pos:
        ldaa    #'+'                    ;If 0, display '+'
set_dist_pol:
        staa    3,x                     

        ldy     #LFRF_dst
        ldab    dist_ctr,x
        lsrb                            ;2 distances in one slot!
        aby
        ldab    0,y                     ;Get distance
        jsr     byte_to_3               ;Convert to decimal
        tsx

        ldd     dbufr+1     
        addd    #$3030
        staa    0,x
        stab    2,x
    
        ldy     #spkr_vol_posns         ;Get positions of numbers
        ldab    dist_ctr,x
        aby
        ldaa    0,y
        tsy
        jsr     SCREENS

        tsx
        inc     dist_ctr,x
        ldaa    dist_ctr,x
        cmpa    #5                      ;Stop before you do the SUB!
        bne     dist_ctr_loop

        tsx
        xgdx
        addd    #10
        xgdx
        txs
        rts


write_ee_dists:
        ldx     #ee_globals             ;Write speaker distances
        ldab    #ee_spkr_dists
        abx
        clrb
wr_ee_dist1:
        ldy     #LFRF_dst
        aby
        ldaa    0,y
        jsr     write_ee
        incb
        inx
        inx
        cmpb    #3
        bne     wr_ee_dist1

        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 7 -- Analog Input Attenuation Screen
;*
;***
Analog_input_atten_screen:
        ldy     #Anlg_inp_atten 
        jsr     screen_out

        des
        des
        des
        tsy

        ldaa    ana_6dB                 ;Get attenuation information
        clrb
ana_inp_atten_loop:
        lsra
        bcc     next_ana_attn           ;0 dB is default on screen

        tsy
        psha
        pshb

        ldaa    #'6'
        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #$20
        staa    2,y

        ldaa    #3                      ;Convert to position
        mul
        incb                                  
        addb    #20
        tba
        jsr     SCREENS                 ;Put out a 6

        pulb                            ;Restore counter
        pula

next_ana_attn:
        incb
        cmpb    #Anlg_ins               ;All n analog channels done?
        bne     ana_inp_atten_loop

        ins
        ins
        ins
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 8 -- System Configuration Screen
;*
;***
System_config_screen:
        ldy     #System_config 
        jsr     screen_out

sys_cfg_0:
;Use the following space for ES volume offset in Ref. Cinema mode:
;        ldx     #ee_globals+ee_balanced
;        brclr   0,x,#%00000001,sys_cfg_1 ;Check for Balanced
;
;        ldaa    #0
;        ldy     #balance
;        jsr     SCREENS

sys_cfg_1:
        tsx
        xgdx
        subd    #7                      ;Allocate stack space for locals.
        xgdx
        txs

        ldy     #xover_freqs            ;Get X-Over frequency
        ldab    xover_val
        aby
        ldab    0,y                     ;Pick up frequency
        jsr     byte_to_3               ;Convert to 3 numbers

        tsy                             ;Create ### string
        ldd     dbufr
        addd    #$3030
        std     0,y
        ldaa    dbufr+2
        adda    #$30
        staa    2,y
        ldaa    #'|'
        staa    3,y
        ldd     #'  '                   ;$2020
        std     4,y
        staa    6,y

        ldaa    #8                      ;Display X-Over frequency
        jsr     SCREENS

;** Temporary Assignment number:

        ldaa    t_dts_inp               ;Temporary dts assignment
        bne     sys_temp_dts

        ldaa    t_mpeg_inp              ;Temporary MPEG assignment
        bne     sys_temp_mpeg

        ldaa    t_ac3_inp               ;Temporary AC3 assignment
        bne     sys_temp_ac3
        bra     sys_cfg_2               ;If no temps, show nothing

sys_temp_dts:
        ldy     #sys_cfg_tdts
        ldaa    #14
        jsr     SCREENS

        ldaa    t_dts_inp
        bra     sys_temp_1

sys_temp_mpeg:
        ldy     #sys_cfg_tmpg
        ldaa    #14
        jsr     SCREENS

        ldaa    t_mpeg_inp
        bra     sys_temp_1

sys_temp_ac3:
        ldy     #sys_cfg_tac3
        ldaa    #14
        jsr     SCREENS

        ldaa    t_ac3_inp
        bra     sys_temp_1

sys_temp_1:
        tsy
        adda    #$30
        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #$20
        staa    2,y

        ldaa    #19                     ;Put up temporary assignment number
        jsr     SCREENS

sys_cfg_2:
        tsy
        ldx     #ee_globals
        ldaa    ee_dig_lockout,x        ;Digital tape lock out
        adda    #$30
        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #$20
        staa    2,y

        ldaa    #39
        jsr     SCREENS

        IFEQ    name-3   ;SIGNATURE+8

           tsy
           ldx     #ee_globals
           ldaa    ee_ana_lockout,x     ;Analog tape lock out
           adda    #$30
           staa    0,y
           ldaa    #'|'
           staa    1,y
           ldaa    #$20
           staa    2,y

           ldaa    #35
           jsr     SCREENS

        ENDC 

        jsr     show_temp

        tsx
        xgdx
        addd    #7
        xgdx
        txs
        rts


show_temp:
        tsx
        xgdx
        subd    #7                      ;Allocate stack frame for local variables.
        xgdx
        txs

        ldx     #regbase
        bset    option,x,#%10000000     ;Enable A/D charge pump,
        ldaa    #%00000010              ;Start A/D as single scan, single channel.
        staa    adctl,x                
        brclr   adctl,x,#%10000000,*    ;Wait until valid data in result registers
        bclr    adctl,x,#%10000000      ;Pseudo-clear CCF to initiate new scan cycle
        clra
        ldab    adr1,x                  ;Read thermistor voltage 
        addb    adr2,x                  ;(take average of 4 readings).
        adca    #0                 
        addb    adr3,x             
        adca    #0                 
        addb    adr4,x             
        adca    #0                 
        lsrd                       
        lsrd                            
        bclr    option,x,#%10000000     ;Disable A/D charge pump.
        ldx     #the_temp
        abx
        ldab    0,x
        bpl     temp_plus

temp_minus:
        negb
        jsr     byte_to_3               ;Create --# temperature string...

        tsy

        ldd     dbufr
        addd    #'00'                   ;Leading 0s becomes spaces here.
        cpd     #' 0'
        bne     temp_0

        ldd     #'  '
temp_0: std     0,y
        cmpb    #' '                    ;Check for two spaces
        bne     temp_1

        ldab    #'-'                    ;Float the leading '-' sign inwards
        stab    1,y
        bra     temp_2

temp_1: ldaa    #'-'
        staa    0,y
temp_2: ldaa    dbufr+2
        adda    #'0'
        staa    2,y
        bra     temp_display

temp_plus:
        jsr     byte_to_3               ;Convert to 3 numbers.
        tsy                             ;Create ### string
        ldd     dbufr
        addd    #'00'                   ;Leading zeros becomes space here.
        cpd     #' 0'
        bne     temp_p0

        ldd     #'  '
temp_p0:
        std     0,y
        ldaa    dbufr+2
        adda    #$30
        staa    2,y
temp_display:
        ldaa    #'|'
        staa    3,y
        ldd     #'  '                   ;$2020
        std     4,y
        staa    6,y
        ldaa    #20                     ;Display temperature
        jsr     SCREENS
        tsx
        xgdx
        addd    #7                      ;Deallocate local stack frame.
        xgdx
        txs
        rts

   
;***********************************************************************
;***********************************************************************
;*
;* SCREEN 9 -- Features Selection Screen
;*
;***
Features_selection_screen:
        ldy     #Features_status 
        jsr     screen_out              ;Put up Features Selection boiler plate.

feats_sel_bits:
        des
        des
        des
        des
        des                             ;Reserve display string buffer on stack.
        tsy                             ;Y is buffer pointer.

feats_sel_screen:                       ;Screen up/down
        ldx     #regbase
        brset   porta,x,#%00010000,feats_sel_sdn

feats_sel_sup:
        ldaa    #'^'
        bra     feats_sel_arrow

feats_sel_sdn:
        ldaa    #'v'        
feats_sel_arrow:
        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #'S'
        staa    2,y
        ldaa    #26                  ;Position on screen.
        jsr     SCREENS

        ;Display D.Norm xx dB (where xx = 00 to 31 dB) in AC-3 mode:

        ldaa    AC3_in_proc          ;1 = AC3, 0 otherwise.
        bne     AC3_DN
        
        tsy
        ldd     #'--'                ;Don't show dialog normalization value unless AC-3.
        std     0,y
        bra     .disp_DN

AC3_DN: ldab    dianorm_val          ;Get Zoran dialog normalization value.
        jsr     byte_to_3            ;Convert to decimal
        tsy
        ldd     dbufr+1              ;Get 2-digit dialog normalization value
        addd    #$3030               ; and convert to ASCII.
        std     0,y

.disp_DN:
        ldaa    #'|'
        staa    2,y
        ldd     #'  '                ;Standard font.
        std     3,y

        ldaa    #35                  ;Position on screen.
        jsr     SCREENS


        ;Display Mem=x
feats_sel_mem:
        tsy
        ldaa    mem_num
        adda    #$30
        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #$20
        staa    2,y

        ldaa    #19
        jsr     SCREENS

feats_sel_ven:                       ;V-Enh
        ldaa    v_enh_flag
        beq     feats_sel_ln         ;Default to off

        ldaa    #8                   ;Position on screen.
        ldy     #v_enh_sign
        jsr     SCREENS

        ;Display LN=xxx
feats_sel_ln:                           ;Late Night Compression=Off,Low,Med,High
        ldaa    late_nite
        beq     ln_is_off

        cmpa    #1
        beq     ln_is_low

        cmpa    #2
        beq     ln_is_med

ln_is_high:
        ldy     #ln_high_sign
        bra     ln_show

ln_is_med:
        ldy     #ln_med_sign
        bra     ln_show

ln_is_low:
        ldy     #ln_low_sign
        bra     ln_show

ln_is_off:
        ldy     #ln_off_sign
ln_show:
        ldaa    #3                   ;Position on screen.
        jsr     SCREENS

feats_sel_end:
        ins
        ins
        ins
        ins
        ins                             ;Deallocate stack buffer space.
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 10 -- Digital A/V Links
;*
;***
display10:
        jsr     LCD_init

        ldaa    #0
        ldy     #DAV_links
        jsr     SCREENS

        ldx     #ee_globals
        ldab    #ee_dig_av_links  
        abx
        jsr     links_inform
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 11 -- Analog A/V Links
;*
;***
display11:
        jsr     LCD_init

        ldaa    #0
        ldy     #AAV_links
        jsr     SCREENS

        ldx     #ee_globals
        ldab    #ee_ana_av_links
;       addb    #6
        abx
        jsr     links_inform
        rts

;%% Also used by digital A/V links...
links_inform:
        des
        des
        des
        des
        des
        tsy                             ;Allocate space for locals.

        ldaa    #'|'
        staa    2,y
        ldd     #$2020
        std     3,y
        clrb                            ;Input loop counter (0-5)
link_disp_loop:
        ldaa    0,x                     ;Get stored video link
        anda    #$7f                 
        brset   0,x,#$80,s_links     

c_links:
        ldaa    #'C'                    ;Put out Cn
        staa    0,y
        ldaa    0,x
        adda    #$30                    ;Convert to ASCII  
        staa    1,y
        bra     link_disp_next

s_links:
        ldaa    #'S'                    ;Put out Sn
        staa    0,y
        ldaa    0,x
        anda    #$7f                    ;Remove msb
        adda    #$30                    ;Convert to ASCII
        staa    1,y
link_disp_next:
        pshb
        tba
        ldab    #3
        mul
        tba
        inca
        cmpa    #10
        blo     link_disp_lh            ;Check if LH or RH side

        inca                            ;RH side has one extra space
link_disp_lh:
        adda    #20                     ;Convert to a position
        jsr     SCREENS

        inx                             ;Update pointer
        pulb
        incb                            ;Increment loop counter.

;Also check for Anlg PT A/V Links:
        ldaa    screen_num              ;Check if in either anlg or dig screen
        cmpa    #.SCREEN.Anlg_AVLink 
        beq     analog_links_diff1

        ldaa    screen_num              ;Check if in either anlg or dig screen
        cmpa    #.SCREEN.AnlgPT_AVLink 
        beq     analog_links_diff2

        ldaa    flash_up                ;Check if flashing up screen (upon changes)
        beq     link_disp_1

        brset   ms_save,#$80,analog_links_diff1  ;If anlg, do those links

link_disp_1:
        cmpb    #6                      ;Maximum of 6 inputs, either anlg or dig..
        bra     links_looping

analog_links_diff2:
        cmpb    #3                      ;Always three analog pass-through inputs.
        bra     links_looping

analog_links_diff1:
        cmpb    #Anlg_ins               ;Varies with model:
                                        ; 3 for Ovation-8, Signature-8; 6 for Signature+8.
links_looping:
        bne     link_disp_loop

        ins
        ins
        ins
        ins
        ins
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 12 -- Analog Pass-Thru A/V Links
;*
;***
display11a:
        jsr     LCD_init

        ldaa    #0
        ldy     #PAV_links
        jsr     SCREENS

        ldx     #ee_globals
        ldab    #ee_ana_pt_av_links     
        abx
        jsr     links_inform
        rts


;***********************************************************************
;*
;* SCREEN 13 -- Input Data Status Screen
;*
;***
display12:
        jsr     LCD_init

display12_no_clr:
        ldaa    #10
        ldy     #input_data_freq
        jsr     SCREENS

display12_1: 
        brclr   cs0_imag,#%00000010,display12_no_data   ;Check for Data or Audio

        ldy     #data_sign              ;Data on
        ldaa    #26
        jsr     SCREENS
        bra     display12_2

display12_no_data:
        ldaa    #26
        ldab    #29
        jsr     Section_clear           ;Data off


display12_2:
        brclr   cs0_imag,#%00000001,display12_cons ;Check for Prof./cons mode

;** Now we are in professional mode
display12_prof:                
        ldaa    #6                      ;AES on
        ldy     #AES_sign
        jsr     SCREENS

        ldaa    cs0_imag
        anda    #%00011100              ;Get emphasis information
        cmpa    #%00001100              ;Check for emphasis on
        beq     display12_emph  
        bra     display12_no_emph


;** Now we are in consumer mode
display12_cons:
        ldaa    #6                      ;AES off
        ldab    #8
        jsr     Section_clear

        ldaa    cs0_imag
        anda    #%00111000              ;Get emphasis information
        cmpa    #%00001000              ;Check for emphasis on
        beq     display12_emph
        bra     display12_no_emph

display12_no_emph:
        ldaa    #0                      ;No Emphasis
        ldab    #4
        jsr     Section_clear
        bra     display12_freqs

display12_emph:
        ldaa    #0                      ;Emphasis
        ldy     #emph_sign
        jsr     SCREENS

display12_freqs:
        ldaa    locked                  ;Check if locked or not
        bne     show_nolk

        ldaa    fs_freq                 ;Get fs information 
        cmpa    #1                      
        beq     show_44                 ;44.1kHz            

        cmpa    #2
        beq     show_48                 ;48kHz

        cmpa    #3
        beq     show_32                 ;32kHz
        bra     display12_x

show_44:
        ldy     #freq_44
        bra     freq_sign_disp

show_48:
        ldy     #freq_48
        bra     freq_sign_disp

show_32:
        ldy     #freq_32
        bra     freq_sign_disp

freq_sign_disp:
        ldaa    #13                     ;Show frequency number
        jsr     SCREENS

do_khz_sign:
        ldy     #input_data_khz
        ldaa    #17
        jsr     SCREENS
        bra     display12_x

show_nolk:
        ldaa    #13                     ;If not locked, clear freq selection
        ldab    #16
        jsr     Section_clear
display12_x:
        rts


display12_VCP:
        brclr   rs_imag,#%00001000,display12_noV        ;Check Validity bit

        ldaa    #15
        staa    err_star_ctr                            ;Refresh monostable timer
        ldy     #V_sign                                 ;V on
        bra     display12_showV

display12_noV:
        ldy     #spaces                                 ;V off
display12_showV:
        ldaa    #20
        jsr     SCREENS

        brclr   rs_imag,#%00000100,display12_noC        ;Check Confidence bit

        ldaa    #15
        staa    err_star_ctr                            ;Refresh monostable timer
        ldy     #C_sign                                 ;C on
        bra     display12_showC

display12_noC:
        ldy     #spaces                                 ;C off
display12_showC:
        ldaa    #22
        jsr     SCREENS

        ldaa    rs_imag
        anda    #%00000011                              ;Get PAR and BIP bits
        beq     display12_noP
        
        ldaa    #15
        staa    err_star_ctr                            ;Refresh monostable timer
        ldy     #P_sign                                 ;P on
        bra     display12_showP

display12_noP:
        ldy     #spaces                                 ;P off
display12_showP:
        ldaa    #24
        jsr     SCREENS

        rts

;***********************************************************************
;***********************************************************************
;*
;* SCREEN 14 -- Digital Input Designators Screen
;*
;***
display13:
        ldy     #Dig_inp_desig
        jsr     screen_out
        ldaa    ms_save                 ;Save current main source.
        psha
        ldaa    #1                      ;Dummy digital input 1.
        staa    ms_save

disp_13_14_labs:
        anda    #%01111111              ;Mask out MSB for anlg inputs.
        ldab    #7                      ;Field width on screen.
        mul
        tba
        suba    #5                      ;Adjust to starting position.
        cmpa    #23
        blo     .desig_labs_ok

        deca                            ;Correct positions for 2nd char row.
.desig_labs_ok:
        jsr     input_label             ;Show label
        inc     ms_save
        ldaa    ms_save
        anda    #%01111111
        cmpa    #7
        bne     disp_13_14_labs

        pula
        staa    ms_save                 ;Restore current main source.
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 15 -- Analog Input Designators Screen
;*
;***
display14:
        ldy     #Anlg_inp_desig
        jsr     screen_out
        ldaa    ms_save                 ;Save current main source.
        psha
        ldaa    #$81                    ;Dummy analog input 1.
        staa    ms_save
        jmp     disp_13_14_labs


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 16 -- Analog Pass-Thru Input Designators Screen
;*
;***
display14a:
        ldy     #AnlgPT_inp_desig
        jsr     screen_out
        ldaa    ms_save                 ;Save current main source.
        psha
        ldaa    #$87                    ;Dummy analog input 7.
        staa    ms_save

disp_14a_labs:
        anda    #%01111111              ;Mask out MSB
        suba    #6                      ;Bring back to 1,2,3 range for display.
        ldab    #7                      ;Field width on screen.
        mul
        tba
        suba    #5                      ;Adjust to starting position.
        jsr     input_label             ;Show label
        inc     ms_save
        ldaa    ms_save
        anda    #%01111111
        cmpa    #10                     ;Stop at A9
        bne     disp_14a_labs

        pula
        staa    ms_save                 ;Restore current main source.
        rts             


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 17 -- IR Remote Control Test 
;*
;***
IR_remote_test:
        ldy     #IR_test
        jsr     screen_out
        rts

ir_test_mode:            
        ldaa    frame                   ;Check for valid key presses
        cmpa    #k_tm_du
        beq     ir_test_valid

        cmpa    #k_tms_du
        beq     ir_test_valid

        cmpa    #k_exit
        beq     ir_test_valid

        ldy     #TM_page
find_ir_code:
        ldaa    0,y
        cmpa    #1                      ;Check for key information
        bne     find_next_ir

        ldaa    1,y
        cmpa    frame                   ;See if this key is pressed
        beq     found_key

find_next_ir:
        iny
        cpy     #IR_codes_end           ;Check for end of table
        bne     find_ir_code

ir_test_valid:
        ldab   #$ff                     ;If key press valid, flag it
        rts

found_key:
        iny
        iny                             ;y points to name
        pshy

        ldaa    #20
        ldab    #39
        jsr     Section_clear           ;Clear off bottom line

        puly
        pshy
        clrb
center_name:
        iny
        incb
        ldaa    0,y                     ;Get character
        cmpa    #'|'                    ;Look for end of string
        bne     center_name

        lsrb                            
        ldaa    #30                     ;30-length/2 is start point
        sba                             
      
        puly
        jsr     SCREENS                 ;Display name

        jsr     click
        clrb                            ;Flag that all is well
        clr     IR_ready
        rts


;***********************************************************************
;***********************************************************************
;*
;* SCREEN 3 -- Speaker Adjustment Screen 
;*
;***
spkr_vol_posns:
        dc.b    2,16,22,36,9,29
vcp_zero:
        dc.b    0,0,0

;Local variables allocated on the stack:
spkr_bits:      equ     0
spkr_vols:      equ     1
spkr_num:       equ     2

Spkr_adj_screen:
        ldaa    static_in_proc
        bne     spkr_adj_1               ;If in static noise, keep hi-lite info

        clr     curr_chs                 ;Otherwise deselect all channels...
        clr     chs_seld
spkr_adj_1:
        ldaa    noise_in_proc            ;Check if in Noise seq mode
        bne     mic_check                ;If so, check if mic in

        ldaa    static_in_proc           ;Check if in Static noise mode
        bne     mic_check                ;If so, check if mic in

display30:
        ldaa    #$ff
        staa    dec_key
        jsr     highlight_spkrs          ;Put up correct labels
        bra     display31                ;Now put up individual volumes

mic_check:
        ldx     #regbase
        brclr   porte,x,#%00000010,display30  ;If mic not in, do normal screen

        jsr     LCD_init

        ldaa    #0
        ldy     #SPL_meter
        jsr     SCREENS                  ;Display SPL meter blurb

        clra
        jsr     SPL_display              ;Display bar and volume
        jsr     switch_SPL               ;Power up A-D
        rts


display31:
        des                              ;Reserve stack space for locals.
        des
        des        
        tsy

        ldaa    #%00000001
        staa    spkr_bits,y              ;First speaker bit
        ldaa    #0
        staa    spkr_num,y               ;First speaker

display32:
        ldaa    mode_chs
        anda    spkr_bits,y              ;Check if current channel is available
        bne     display32_1              ;If so, all ok
        jmp     spkr_not_avail           ;If not, do not display volume

display32_1:
        ldx     #spkr_vol_posns          ;Get individual volume position
        ldab    spkr_num,y
        abx
        ldaa    0,x
        staa    spkr_vols,y              ;Store speaker volume position

        ldx     #vcp_l
        ldab    spkr_num,y
        lslb                             ;Spkr_num x 2 = offset from vcp_l
        abx                              ;X register contains address of volume
        
        ldaa    active_chs
        anda    spkr_bits,y
        bne     display33                ;If speaker active, go on

        ldaa    spkr_vols,y              ;Get position
        jsr     indiv_deseld             ;Put out '____' and defeat blink
        bra     spkr_not_avail

display33:
        ldaa    vc_cmp_flags
        anda    spkr_bits,y              ;Check if speaker compressed
        bne     vc_compd                 ;If so, set blink field
        
        ldaa    vc_max_flags
        anda    spkr_bits,y              ;Check if speaker max'ed out
        beq     vc_not_maxed             ;If not, put out correct volume
        bra     vc_not_compd             ;If so, defeat blink and put up 0.0

vc_compd:                                ;In case speakers are compressed
        ldaa    spkr_vols,y              ;Get label position
        bra     vc_blink_field

vc_not_compd:                            ;Speakers not compressed (maybe maxed)
        ldaa    #$ff                     ;Flag no blink (blink field=ff)

vc_blink_field:                          ;Sets up blinking volume field
        ldab    spkr_num,y
        lslb
        pshy
        ldy     #blink_posns
        aby                              ;Get blink field position        
        staa    0,y                      ;Store label posn in blink field
        adda    #3
        staa    1,y                      ;Store posn+2 in blink field end
        puly

        ldab    spkr_vols,y              ;Get position of compressed speaker

        pshy
        ldy     #screen_image
        aby

        ldd     0,x                      ;Get volume
        bmi     vc_blink_1               ;If compressed, put 0 on screen

        puly
        ldaa    spkr_vols,y              ;Position of speaker
        jsr     indiv_vol_disp           ;Put out number
        bra     spkr_not_avail           ;Move along...


vc_blink_1:
        ldd     #' 0'
        std     0,y 
        ldd     #'.0'                  
        std     2,y                      ;Put 0.0 in screen image so
        puly                             ;that it comes up first time through.

        ldx     #vcp_zero                ;Put up a zero if max'ed out or compressed
        ldaa    vc_cmp_flags
        anda    spkr_bits,y
        bne     spkr_not_avail           ;If compressed, do not redisplay

vc_not_maxed:
        ldaa    #$ff                     ;Flag no blink
        ldab    spkr_num,y
        lslb
        pshy
        ldy     #blink_posns
        aby                              ;Get blink field position        
        staa    0,y                      ;Turn off blinking in that field
        puly

        ldaa    spkr_vols,y              ;Position of speaker
        jsr     indiv_vol_disp           ;Put out number

spkr_not_avail:
        lsl     spkr_bits,y              ;Update speaker bit
        inc     spkr_num,y               ;Next speaker
        ldaa    spkr_num,y
        cmpa    #6                       ;Check if all speakers done
        beq     display34
        jmp     display32

display34:
        ins                              ;Restore stack
        ins
        ins
        rts


indiv_deseld:
        ldaa    #$ff                     ;Flag no blink
        ldab    spkr_num,y
        lslb
        pshy
        ldy     #blink_posns
        aby                              ;Get blink field position        
        staa    0,y
        puly
        ldaa    spkr_vols,y              ;Get position
        pshy
        ldy     #deselect                ;Show deselection '____'
        jsr     SCREENS
        puly
        rts


indiv_vol_disp:
        pshy                            ;Make routine re-entrant
        tsy                             ;Reserve stack space
        psha
        xgdy
        subd    #10
        xgdy
        tys
        jsr     vtodB                   ;Convert volume to 3 dec. numbers in dbufr
        ldaa    #'.'                    ;Decimal point
        staa    2,y                     
        ldaa    #'|'                    ;End of string
        staa    4,y
        ldaa    #' '                    ;Normal font numbers
        staa    5,y
        staa    6,y
        staa    7,y
        staa    8,y

        ldx     #dbufr
        ldaa    0,x                     ;First 2 numbers
        bne     indiv_1

        ldaa    #$f0                    ;If first digit is zero, put a space in

indiv_1:
        adda    #$30                    ;Convert to ASCII
        staa    0,y

        ldaa    1,x
        adda    #$30                    ;Convert to ASCII
        staa    1,y

        ldaa    2,x                     ;Tenths
        adda    #$30                    ;Convert to ASCII
        staa    3,y

        ldaa    9,y                     ;Get position pointer
        jsr     SCREENS                 ;Display number

        tsy                             ;Restore stack
        xgdy
        addd    #10
        xgdy
        tys

        puly                            ;Restore previous y value
        rts


;***********************************************************************
;*
;* Going into Speaker Adjustment screen
;*
;***
adjust_mode:
        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Adj   
        beq     adj_mode_rts            ;Do nothing if already there.

        clr     xover_rolloff           ;No longer in bass management screen.
        clr     curr_chs                ;Select no channels by default
        clr     chs_seld                ; so that vol up/dn does big nums...

        ldaa    #.SCREEN.Spkr_Adj   
        staa    screen_num
        jsr     LCD_init
        jsr     display_scrn            ;Go into adjustment screen
adj_mode_rts:
        rts


;***********************************************************************
;* Noise Sequencer mode - displays entry screen and sets Zoran modes
;***
noise_bits:                             ;Conversion of noise_channel to Z1 PNG bits
        dc.b    %00100000               ;LF
        dc.b    %00010000               ;CR
        dc.b    %00001000               ;RF
        dc.b    %00000010               ;RS
        dc.b    %00000001               ;SB
        dc.b    %00000100               ;LS

noise_seq_mode:
        clr     es_flag                 ;In case it is set!
        clr     party_flag              ;In case it is set!

        ldaa    #1
        staa    noise_in_proc           ;Flag noise seq. going on

        jsr     init_noise              ;Mute processors and set 4226 in xtal

        ldaa    #$1f                    ;Enable on all channels except sub
        staa    active_chs
        ldaa    #$1f                    ;No sub on screen!!
        staa    mode_chs                
        
        ldaa    #.SCREEN.Spkr_Adj       ;Flag speaker adjust screen for later
        staa    screen_num
        jsr     LCD_init
        ldy     #noise_seq_screen       ;Display mode screen
        jsr     screen_out
        ldaa    #1
        staa    screen_status2          ;Set 2s timer for mode screen
        rts

noisy_channels:                         ;Set Z1 into PNG for the relevant channel
        ldy     #noise_bits
        ldab    noise_channel
        decb
        aby
        ldaa    0,y                     ;Get bit pattern for Z1 png
        ldy     #png_lst
        staa    3,y                     ;Store channel info

        ldaa    auto_in_proc
        bne     noisy_0dB

noisy_9dB:
        ldd     #$2d6a                  ;-9 dB = 0.3548. Multiply 0.3548 by 32767
        bra     noisy_chan1             ; to get 16-bit fractional format: $2d6a.
                                        ;Everything other than AutoSetup/Delay
                                        ; has Dolby standard -9dBFS for pink noise.
noisy_0dB:
        ldd     #$7fff                  ;0 dB = 1. Multiply 1 by 32767
                                        ; to get 16-bit fractional format: $7fff.
                                        ;Auto setup/delay uses a Z1 png at max level = 0 dB.

noisy_chan1:
        std     8,y                     ;Store PCM scale factor info.
        jsr     WR_Z1                   ;Set Z1 into correct png output
                                        ;(includes Z1 unmute command)
        jsr     unmute_all              ;Just in case!
noisy_end:
        rts


;***********************************************************************
;* Auto Setup and Auto Delay start-up
;***
auto_setup_mode:
        clr     es_flag                 ;Just in case!
        clr     party_flag              ;Just in case!

        ldaa    #1
        staa    auto_in_proc            ;Flag Auto Setup pressed
        jsr     auto_setup_init
        cmpa    #$55                    ;Check for no mic
        beq     auto_s_end

        ldy     #auto_setup_screen      ;Display mode screen
        jsr     screen_out
        jmp     auto_setup


auto_delay_mode:
        clr     es_flag                 ;Just in case!
        clr     party_flag              ;Just in case!

        ldaa    #2
        staa    auto_in_proc            ;Flag Auto Delay pressed
        jsr     auto_setup_init
        cmpa    #$55                    ;Check for no mic
        beq     auto_s_end

        ldy     #auto_delay_screen      ;Display mode screen
        jsr     screen_out
        jmp     auto_setup

auto_s_end:
        rts


;*********************************************************************
;* Common initialization for Auto Setup and Auto Delay
;***
ref_spl: equ    22   ;Calibrated volume accumulator value for reference SPL (75 dB).

auto_setup_init:
        ldaa    spkr_cfg
        anda    #%0001
        beq     as_OK

as_not_OK:
        ldy     #auto_s_unavailable_screen     ;Display error msg: Auto-Setup is 
        bra     as_mic_out_1                   ; unavailable in Cinema 7.1 layout.

as_OK:  ldx     #regbase
        brset   porte,x,#%00000010,auto_set_mic_in

auto_set_mic_out:
        jsr     LCD_init
        ldaa    auto_in_proc
        cmpa    #1                      ;Check if coming from Auto Setup...
        beq     as_mic_setup            

        ldy     #auto_d_err_screen      ; or if coming from Auto Delay...
        bra     as_mic_out_1

as_mic_setup:
        ldy     #auto_s_err_screen      ;Display Auto Setup error screen
as_mic_out_1:
        jsr     screen_out
        ldaa    #1
        staa    screen_status2          ;Set 2s timer for mode screen
        jsr     do_mute             
        jsr     warble                  ;If mic not in, warble
        jsr     exit_noise
        ldaa    #$55                    ;Flag an error
        rts


auto_set_mic_in:
        ldx     #vcp_l                  ;Save volume values
        ldy     #vc_c_l                 ; in primary copy area.
        ldab    #vcp_addr_offset        ;Block length
        jsr     blockcopy               

        jsr     init_noise              ;Set up Zorans for PNG

        ldaa    #$1f                    ;Turn on all channels except sub
        staa    active_chs
        ldaa    #$1f                    ;No sub on screen!!
        staa    mode_chs                

        ldaa    #ref_spl                ;Set up reference mic level
        staa    ref_level

        clr     auto_ctr                ;No success yet
        clr     auto_success
        clr     prev_peak               ;Clear crack timer
        clr     polarity
        
        ldaa    #.SCREEN.Spkr_Adj       ;Flag speaker adjust screen for later
        staa    screen_num
        jsr     LCD_init                ;Clear old screen

        ldaa    #1
        staa    screen_status2          ;Start timer for mode screen
        rts


;***********************************************************************
;* Auto Setup
;***
auto_setup:       
        ldaa    #1
        staa    auto_stage              ;Flag Auto-level in process

;** Start all speakers at predetermined level
        ldd     #adj_start
        std     vcp_l                   ;Set L
        std     vcp_r                   ;Set R
        std     vcp_c                   ;Set C
        std     vcp_ls                  ;Set LS
        std     vcp_rs                  ;Set RS
        std     vcp_sub                 ;Set SUB
        std     vcp_es                  ;Set ES (not currently used by Auto Setup)
        std     vcp_dummy
        jsr     unpack_vol              ;Compute composite volumes and set them
        rts


;***********************************************************************
;* Auto Setup Finish
;***
auto_set_finish:
        jsr     mute_Zs                 ;Turn off all noise
        delay   2000*10                 ;2 sec delay.
        jsr     savebeep                ;Signal successful completion of auto level.

;* Save volumes for cracks
        ldx     #vcp_l                  ;Save volume values
        ldy     #vc_2_l                 ; in secondary copy area.
        ldab    #vcp_addr_offset        ;Block length.
        jsr     blockcopy

;* If doing Auto-Delay automatically following Auto-Setup, change user volumes.
;* If coming from Auto-Delay, don't!
        ldaa    auto_in_proc
        cmpa    #1
        bne     auto_fin_end            ;Skip -20 dB change if not in Auto Setup.

        ldd     vcp_l                   ;Take LR average
        addd    vcp_r
        lsrd
        addd    #Twenty_dB              ; and change LF/RF by -20 dB.
        std     vc_c_l
        std     vc_c_r

        ldd     vcp_ls                  ;Take LR surround average
        addd    vcp_rs
        lsrd
        addd    #Twenty_dB              ; and change surrounds by -20 dB.
        std     vc_c_ls
        std     vc_c_rs
        std     vc_c_es                 ;Set ES to same vol as LS, RS.

        ldd     vcp_c
        addd    #Twenty_dB              ;Change CTR and SUB by -20 dB.
        std     vc_c_c
        std     vc_c_sub                ;(Make sub level match center initially!!!)


auto_fin_end:
        jsr     LCD_init
        ldaa    #.SCREEN.Spkr_Dist      ;Display speaker distance screen
        staa    screen_num
        jsr     display_scrn
        jmp     auto_delay              ;Go into auto delay now
       

;*********************************************************************
;* Auto Delay mode
;***
auto_delay:
        ldaa    #2
        staa    auto_stage              ;Flag Auto-Delay in process        

        ldaa    #1
        staa    noise_channel
        clr     auto_success
        clr     auto_set_timer

;* Set all speakers to minimum volume:

        jsr     quiet_spkrs            
        jsr     unpack_vol
        jsr     unmute_Zs               ;Because they were muted after finishing Auto-Setup
        rts


;*********************************************************************
;* Auto Delay Finish
;***
auto_delay_finish:
        jsr     mute_Zs                 ;Turn off all noise
        delay   2000*10                 ;2 sec delay.
        jsr     beepbeep                ;Signal successful completion of Autosetup.

        ldx     #vc_c_l                 ;Restore volumes from primary copy area
        ldy     #vcp_l                  ; to the vcp_s.
        ldab    #vcp_addr_offset        ;Block length
        jsr     blockcopy               

        jsr     unpack_vol
        jmp     exit_noise


;*********************************************************************
;* Quiet Speakers (used by auto_delay routine)
;***
quiet_spkrs:
        ldd     #vc_bot                 ;Start all speakers quiet
        std     vcp_l                   ;Set L
        std     vcp_r                   ;Set R
        std     vcp_c                   ;Set C
        std     vcp_ls                  ;Set LS
        std     vcp_rs                  ;Set RS
        std     vcp_sub                 ;Set SUB
        std     vcp_es                  ;Set ES
        std     vcp_dummy
        rts


;***********************************************************************
;* Static Noise mode - displays entry screen and sets Zoran modes
;***
static_noise_mode:
        clr     es_flag                 ;Just in case!
        clr     party_flag              ;Just in case!

        ldaa    #1
        staa    static_in_proc          ;Flag that we are in Static Noise mode
        clr     curr_chs                ;Select no channels by default
        clr     chs_seld                ; so that vol up, dn does Big Nums
        jsr     init_noise

        ldaa    #.SCREEN.Spkr_Adj       ;Flag speaker adjust screen for later
        staa    screen_num
        ldy     #static_nse_screen      ;Display mode screen
        jsr     screen_out
        ldaa    #1
        staa    screen_status2          ;Set 2s timer for mode screen
        rts


;***********************************************************************
;* Startup for static noise, noise seq. or auto setup/delay modes
;***
init_noise:
        ldx     #regbase
        bclr    porta,x,#%10000000      ;Deselect DTS

        ldaa    #$ff
        staa    z_mode                  ;Force switching to new mode when done

        jsr     switch_SPL              ;Power up A-D and clear buffer

        clr     PCM_in_proc             ;Clear all processing flags
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc            

        ldaa    mode_chs
        staa    mode_chs_saved          ;Save old mode channels
        ldaa    #%00111111
        staa    mode_chs                ;All channels on screen

        ldaa    active_chs
        staa    active_chs_saved        ;Save old active channels
        ldaa    #%00111111
        staa    active_chs              ;Enable all channels

        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        jsr     clear_corrs             ;Clear all volume corrections
        jsr     unpack_vol              

        delay   200*10                  ;Wait for soft mute.

        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        delay   5*10

        ldaa    #1                      ;Set clock mode byte (1)
        ldab    #$00                    ; to CS4226.
        jsr     WR_CS4226

        ldaa    spkr_cfg
        anda    #%0001
        bne     noise71
        
        ldy     #feedthru_cmd2_Ref
        bra     init_noise2

noise71:
        ldy     #feedthru_cmd2_71

init_noise2:
        jsr     WR_Z2                   ;Put Z2 into 6 channel feed thru'
        rts


;***********************************************************************
;* Noise sequencer noise rotation
;***
rotate_noise:
        ldab    noise_channel
        decb
        cmpb    #2
        bls     rotate_1

        ldab    #9
        subb    noise_channel           ;Convert in order to go around the room

rotate_1:
        ldy     #spkr_masks_asymm
        aby
        ldaa    0,y
        anda    active_chs              ;Check if this channel is active
        bne     rotate_2                ;If channel active, continue

        inc     noise_channel           ;If channel inactive, try next
        ldaa    noise_channel
        cmpa    #7
        bne     rotate_noise            

        ldaa    #1                      ;Wrap around if necessary
        staa    noise_channel
        bra     rotate_noise 

rotate_2:     
        ldaa    0,y
        staa    chs_seld                ;Highlight single channels

        ldaa    auto_in_proc
        beq     rotate_symm             ;If in Noise seq, do symmmetric vol changes

rotate_asymm:
        ldy     #spkr_masks_asymm       ;If in Auto setup, do asymm. channels
        bra     rotate_20

rotate_symm:
        ldy     #spkr_masks_symm
rotate_20:
        aby
        ldaa    0,y
        staa    curr_chs                ;Select symmetric channels
     
        ldaa    #$ff
        staa    dec_key

        ldaa    auto_in_proc            ;If in auto setup, do highlight channels
        bne     rotate_21

        ldx     #regbase
        brset   porte,x,#%00000010,rotate_3    ;No labels if mic is in!!

rotate_21:
        jsr     highlight_spkrs         ;Put up relevant labels
rotate_3:
        jsr     noisy_channels          ;Turn on correct Z1 png channel
        inc     noise_channel           ;Next channel
        clr     noise_seq_timer         ;Restart timer
        ldaa    noise_channel
        cmpa    #7                      ;Check if last channel
        bne     rotate_4   

        ldaa    #1                      ;Wrap to first channel
        staa    noise_channel
rotate_4:
        rts


;***********************************************************************
;* Selection of speakers when in Adjustment, Noise Sequencer or Static Noise
;***
select_spkrs:
        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Adj       ;If in Speaker Adjust screen, continue
        beq     select_spkrs_1

        cmpa    #.SCREEN.Spkr_Dist      ;Check if in Speaker Distances screen
        bne     select_spkrs_0
        jmp     spkr_dist_sel

select_spkrs_0:
        ldaa    static_in_proc          ;If in static noise, continue
        bne     select_spkrs_1         

        ldaa    dec_key
        cmpa    #$85                    ;Check for SUB button only
        bne     select_end              
        jmp     xover_freq_select       ;Otherwise, do xover frequency select

select_spkrs_1:
        ldaa    xover_rolloff           ;If in Bass management, do nothing
        bne     select_end

        ldaa    static_in_proc          ;If in Static Noise, do that
        bne     select_static

select_adjust:                          ;Speaker highlighting in Adjustment mode
        jsr     highlight_spkrs
        ldaa    chs_seld
        staa    curr_chs
select_end:
        rts


select_static:                          ;Speaker highlighting in Static Noise
        jsr     highlight_spkrs

sel_sp_skip:
        ldaa    chs_seld
        staa    curr_chs                ;Channels selected

put_out_static:                         ;Converts the bit pattern in curr_chs
                                        ;to the bit pattern in the PNG in Z1
                                        ;then puts out the pink noise
;% Local variables on stack:
png_pattern:    equ     0
png_ctr:        equ     1 
curr_chs_temp:  equ     2 


        des                             ;Allocate stack space for locals.
        des
        des
        tsx

        clr     png_pattern,x
        clr     png_ctr,x
        ldaa    curr_chs
        staa    curr_chs_temp,x         ;Disposable copy of speaker selections 
png_bit_loop:
        ldy     #png_bits
        ldab    png_ctr,x
        aby
        ldaa    0,y                     ;Get Z1 PNG bit pattern for this channel

        lsr     curr_chs_temp,x         ;Get LSB
        bcc     next_png_ch             ;If 0, no pink noise in this channel

noisy_png_ch:
        oraa    png_pattern,x           ;Add in relevant bit
        staa    png_pattern,x
next_png_ch:
        inc     png_ctr,x               ;Get next bit
        ldaa    png_ctr,x
        cmpa    #6                      ;Check if last channel
        bne     png_bit_loop
        
;% Set up Zoran 1 to do correct Pink Noise

        ldy     #png_lst
        ldaa    png_pattern,x           ;Channels selected
        staa    3,y
        ldd     #$2d6f                  ;Static noise, Noise seq has 9dB redn.
        std     8,y
        jsr     WR_Z1                   ;Set Z1 into correct png output
                                        ;(unmutes Z1 also)
        jsr     unmute_all              ;Just in case

        ins                             ;Deallocate stack space for locals.
        ins
        ins
        rts


;***********************************************************************
;*
png_bits:                               
        dc.b    %00100000       ;LF \
        dc.b    %00001000       ;RF |
        dc.b    %00000100       ;LS |
        dc.b    %00000010       ;RS |- Bit patterns for the Zoran PNG
        dc.b    %00010000       ;CR |
        dc.b    %00000001       ;SB /


;***********************************************************************
;*
;* Highlighting speakers.
;* Call this screen with dec_key containing a TMS number 1-6.
;* This subroutine displays highlighted names for selected speakers
;* and normal names for unselected speakers.
;*
;* chs_seld contains the updated bit information on which speakers are
;* selected and which are not.
;*
;*                 SCRLRL
;*                 UTSSFF
;*                 BR
;***
spkr_masks_symm:                ;In order of button pushes 1-6
        dc.b    %00000011       ;LF,RF   TMS 1
        dc.b    %00010000       ;CR      TMS 2
        dc.b    %00000011       ;LF,RF   TMS 3
        dc.b    %00001100       ;LS,RS   TMS 4
        dc.b    %00100000       ;SB      TMS 5
        dc.b    %00001100       ;LS,RS   TMS 6
spkr_masks_asymm:
        dc.b    %00000001       ;LF      TMS 1
        dc.b    %00010000       ;CR      TMS 2
        dc.b    %00000010       ;RF      TMS 3
        dc.b    %00000100       ;LS      TMS 4
        dc.b    %00100000       ;SB      TMS 5
        dc.b    %00001000       ;RS      TMS 6
        
spkr_positions:
        dc.b    0, 14, 20, 34,  7, 27
;              LF  RF  LS  RS  CT  SB   ;In order of bits in mode_chs

highlight_spkrs:
        des                             ;Allocate stack space for local variables.
        des
        des
        des
        des
        tsx

spkr_bit:       equ     0               ;Bit mask corresponding to number
chs_seld_temp:  equ     1               ;Temp storage of highlighted selection
spkr_cnt:       equ     2
spkr_pos:       equ     3
mode_ch_temp:   equ     4

        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Adj       ;Check if in an adjustment screen
        beq     highlight_0             ; (covers Spkr Adj, Noise Seq, Static Noise)

        cmpa    #.SCREEN.Bass_Man
        beq     highlight_0             ; (covers Bass Management screen)

        cmpa    #.SCREEN.Spkr_Dist
        beq     highlight_0             ; (covers Speaker Dist screen)
        jmp     highl_spkrs_end         ;If not, do nothing...

highlight_0:
        ldaa    dec_key
        cmpa    #$ff
        beq     highlight_5             ;Check if straight labels required

        ldaa    screen_status1          ;Check if big nums are up
        bne     highlight_1

        ldaa    screen_status2          ;Check if mode screen is up
        bne     highlight_1
        bra     highlight_2             ;If neither are up, all ok!!

highlight_1:
        clr     screen_status1
        clr     screen_status2          ;Stop screen refresh timers

        pshx                            ;Save pointer to stack variables
        jsr     LCD_init                ;Clear screen
        jsr     display31               ;Put up volumes and go on to do labels
        pulx                            ;Restore pointer to stack variables

highlight_2:
        ldaa    static_in_proc
        bne     highl_asymm             ;If in static noise, allow asymm selection

highl_symm:
        ldy     #spkr_masks_symm
        bra     highlight_3

highl_asymm:
        ldy     #spkr_masks_asymm

highlight_3:        
        ldab    dec_key
        andb    #%01111111              ;Map TMS numbers onto TM numbers.
        aby
        dey
        ldaa    0,y                     ;Get bit mask corresponding to number
        staa    spkr_bit,x              ;Save mask
        ldaa    chs_seld                ;Get current information
        eora    spkr_bit,x              ;Add in to current selection
        cmpa    mode_chs                ;Check if all on screen selected
        bne     highlight_4             ;If not, carry on anyway
       
        ldaa    #%00111111
        staa    chs_seld                ;Otherwise, select all 6 channels
        bra     highlight_5

highlight_4:
        anda    mode_chs                ;Mask out channels not available
        staa    chs_seld                ;Store highlighted speaker information

highlight_5: 
        ldaa    chs_seld                ;Get highlighted speaker information
        staa    chs_seld_temp,x         ;Save info

        ldaa    mode_chs                ;Get available speaker information
        staa    mode_ch_temp,x          ;Save

        clr     spkr_cnt,x              ;First speaker


highlight_loop:
        ldx     #regbase
        brclr   porte,x,#%00000010,hilite_0     ;If mic out, all ok

        tsx
        ldaa    static_in_proc          ;If mic but not static noise, all ok
        beq     hilite_0

        jsr     LCD_init
        jsr     display31               ;Put up speaker volumes
        ldaa    #1
        staa    screen_status2          ;Start mode screen timer
                                        ; (so that SPL doesn't overwrite for 2s)
hilite_0:      
        tsx                             ;Makes it work w.o. mic!!!
        ldy     #spkr_positions         ;Point to position table
        ldab    spkr_cnt,x          
        aby                             ;Update to next position
        ldaa    0,y                     ;Get position information
        staa    spkr_pos,x

        lsr     chs_seld_temp,x         ;Get bit information in carry
        bcc     norm_spkr               ;If = 0, normal name
        bcs     rev_spkr                ;If = 1, reverse letters

;%%% REVERSE SPEAKERS...
rev_spkr:
        ldaa    chs_seld
        cmpa    #%00110011              ;See if CR,SB,LF,RF selected
        bne     rev_spkr1

        ldaa    spkr_cnt,x
        bne     rev_spkr1               ;See if LF to be put up      
     
rev_spkr0:                              ;If you reach here, you have selected
                                        ; CR,SB and LF,RF.  ...this causes a
                                        ; problem with the number of CChars on screen
                                        ; (max. number is 8) so we need to fix it up...
        ldaa    #1
        ldy     #spaces                 ;The following is a very devious piece of code:
        jsr     SCREENS                 ;Clear F in LF,RF slots to free up one CChar

        ldaa    #15
        ldy     #spaces
        jsr     SCREENS         

rev_spkr1:
        ldy     #spkrs_rev
        ldaa    spkr_cfg                ;Adjust pointer by 12 if 7.1 Music mode:
        anda    #%0011
        cmpa    #%0011
        bne     change_spkr_name

        ldab    #6*5                    ;Six channels...
        aby
        bra     change_spkr_name

;%%% NORMAL SPEAKERS...
norm_spkr:
        ldy     #spkrs_norm
        ldaa    spkr_cfg                ;Adjust pointer by 12 if 7.1 Music mode:
        anda    #%0011
        cmpa    #%0011
        bne     change_spkr_name

        ldab    #6*5                    ;Six channels...
        aby

change_spkr_name:
        lsr     mode_ch_temp,x          
        bcc     next_spkr               ;If speaker not available, no name

        ldaa    #5
        ldab    spkr_cnt,x
        mul                             
        aby                             ;Point to correct speaker
        ldaa    spkr_pos,x              ;Get correct screen position
        jsr     SCREENS                 ;Display speaker name

next_spkr:
        inc     spkr_cnt,x              ;Next speaker
        ldaa    spkr_cnt,x
        cmpa    #6                      ;6 already done?
        bne     hilite_0       
             
highl_spkrs_end:

        ins                             ;Deallocate local variables from stack.
        ins
        ins
        ins
        ins
        rts


;***********************************************************************
;* Speaker distance selection and changing
;***
spkr_dist_sel:
        ldaa    dec_key
        anda    #%01111111              ;Map TMS numbers onto TM numbers.
        cmpa    #5
        beq     spkr_dist_sel_end

        ldaa    mode_chs
        psha

        ldab    dec_key
        andb    #%01111111              ;Convert key push to TM number
        decb
        ldy     #spkr_masks_symm
        aby
        ldab    0,y                     ;Get bit pattern for key push
        cmpb    curr_chs                ;See if same as current selection
        bne     spkr_dist_sel1          ;If not, flush bit pattern

        ldaa    #$ff                    ;If same, make sure no spkrs selected
        staa    dec_key

spkr_dist_sel1:
        clr     curr_chs                ;Only select one thing at a time!
        clr     chs_seld

        ldaa    #$1f
        staa    mode_chs                ;Show all speakers except sub
        jsr     highlight_spkrs         ;Put up correct labels

        pula
        staa    mode_chs
        ldaa    chs_seld
        staa    curr_chs
spkr_dist_sel_end:
        rts


;***********************************************************************
;* Exiting TMSetup screens
;***
exit_adjust:
        ldaa    #%00111111
        staa    curr_chs                ;Select all speakers

        clr     xover_rolloff           ;Go out of X-over or Roll-Off modes
        clr     test_screen             ;Go out of test screens

        ldaa    auto_in_proc
        bne     abort_auto_set

exit_adj_1:
        ldaa    screen_num              ;See if coming from Speaker Distances
        cmpa    #.SCREEN.Spkr_Dist  
        bne     exit_adj_2

        jsr     write_ee_dists          ;Write to EE if coming from Speaker Distances

exit_adj_2:
        ldaa    #.SCREEN.Main                             
        staa    screen_num
        clr     screen_status1
        clr     screen_status2
        clr     screen_status3
        jsr     display_scrn            ;Go into normal screen
exit_adj_end:
        rts

abort_auto_set:
        jsr     mute_all                ;Assert CS3310 and PCM1732 mutes.
        jsr     warble                  ;Warble to indicate abort.

        ldx     #vc_c_l                 ;Restore old volumes
        ldy     #vcp_l
        ldab    #vcp_addr_offset        ;Block length
        jsr     blockcopy
        jsr     unpack_vol
        bra     exit_noise              ;Go back into old mode, etc.


;***********************************************************************
;* Exiting Noise Seq. or Static noise modes or Auto Setup
;***
exit_noise:
        ldy     #png_lst
        clra
        staa    3,y                             ;Turn off all noise channels
        ldd     #$7fff                          ;Auto set/dly has no redn.
        std     8,y                             ;Store 0 dB PCM scale factor info.
        jsr     WR_Z1                           ;Set Z1 into correct png output
                                                ; (includes Z1 unmute).
        ldaa    #%00111111
        staa    curr_chs                        ;Select all speakers

        ldaa    mode_chs_saved                  ;Restore channels available
        staa    mode_chs

        ldaa    active_chs_saved                ;Restore active channels
        staa    active_chs

        clr     static_in_proc                  ;Clear noise flags
        clr     noise_in_proc
        clr     auto_in_proc
        clr     auto_stage                      
        clr     t_state

        brset   ms_save,#%10000000,stay_xtal    ;Redo 4226 appropriately

        ldaa    #1                              ;Set clock mode byte (1)
        ldab    #$04                            ; to PLL
        jsr     WR_CS4226
stay_xtal:
        bclr    option,x,#%10000000             ;Disable A/D charge pump
        clr     PCM_in_proc
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc                    ;Clear processing flags

        jsr     get_auto_flag                   ;Get bitstream info
        jsr     force_new_Z                     ;Force Zorans into correct mode
        clr     screen_status1                  

        clr     mute_status                     ;Flag unmuted
        clr     mute_cntr                       ;Stop counter for source daisy blink

        ldaa    auto_success                   
        bne     exit_noise2                     ;If all successful, do not update screen

        ldaa    #.SCREEN.Main                                          
        staa    screen_num                      
        jsr     display_scrn                    ;Go into Main screen

exit_noise2:
        jsr     unmute_Zs                      
        jsr     unmute_all                      ; with music (i.e., unmuted).
        rts

;***********************************************************************
;* Speaker select and deselect in Speaker adjustment
;* Subwoofer selection 0, 1, 2 in Speaker Config screen
;***
deselection:
        ldaa    screen_num
        cmpa    #.SCREEN.Sys_Config             ;Check if in Sys Config screen
        bne     desel_1
        jmp     xover_fsel_updn

desel_1:
        cmpa    #.SCREEN.Spkr_Dist              ;Check if in Speaker Dists screen
        bne     desel_1a
        jmp     spkr_dist_adjust

desel_1a:
        cmpa    #.SCREEN.Spkr_Cfg      
        bne     desel_2                         ;Check that we are in Speaker Config screen
        jmp     subwoofer_select

desel_2:
        cmpa    #.SCREEN.Spkr_Adj           
        bne     do_store_mem                    ;Check that we are in spkr adjust screen

        ldaa    curr_chs
        beq     do_store_mem                    ;If no spkrs selected, do store

;*** Speaker deselection procedures ***

        clr     ir_tout
        clr     t_state                         ;Flush timeout

        ldaa    noise_in_proc                   ;If in Noise Seq or Static noise,
        bne     spkr_select_end                 ; do nothing with this key push

        ldaa    static_in_proc
        bne     spkr_select_end

        ldaa    curr_chs                        ;Get selected speaker information
        beq     spkr_select_end                 ;If none selected, do nothing

        anda    #%00111100                      ;Mask out LF,RF (deselect not allowed)
        ldab    ps_frame
        cmpb    #k_tms_sto                      ;Look for channel up (select)
        beq     spkr_sel

spkr_desel:

;*** Check for Phantom/3Stereo lockout ***
        ldab    curr_chs
        andb    #%00011100
        cmpb    #%00011100                      ;See if all of CR,LS,RS highlighted
        beq     phantom_lockout_2

        ldab    active_chs
        comb
        andb    #%00010000                      ;See if CR deselected
        bne     phantom_lockout_0

        ldab    active_chs
        comb
        andb    #%00001100                      ;See if LS,RS deselected
        bne     phantom_lockout_1

spkr_desel_1:
        anda    active_chs                      ;Get valid deselected channel info
        eora    active_chs                      ;Deselect these channels
        staa    active_chs                      ; and store result
        bra     spkr_select_end1

spkr_sel:
        oraa    active_chs                      ;Deselect highlighted channnels
        staa    active_chs                      ; and store result
spkr_select_end1:
        jsr     force_new_Z_flush               ;Force new Zoran boot if necessary
        jmp     display31                       ;Display new status of screens

spkr_select_end:
        rts


do_store_mem:
        ldaa    ps_frame
        cmpa    #k_tm_rcl                       ;Check for recall (TM)
        beq     do_st_rcl

        cmpa    #k_tms_rcl                      ;Check for recall (TMS)
        beq     do_st_rcl

        ldaa    #143                            ;Force store-num possibility
        bra     do_st_1

do_st_rcl:
        ldaa    #144
do_st_1:
        staa    t_state
        rts


;*** Phantom/3Stereo lockout ***
phantom_lockout_0:
        ldab    curr_chs
        andb    #%00001100
        beq     spkr_desel_1                    ;Check if LS,RS highlighted

        ldab    active_chs
        orab    #%00010000
        stab    active_chs                      ;Reselect CR
        bra     spkr_desel_1

phantom_lockout_1:
        ldab    curr_chs
        andb    #%00010000
        beq     spkr_desel_1                    ;Check if CR highlighted

        ldab    active_chs
        orab    #%00001100
        stab    active_chs                      ;Reselect LS,RS
        bra     spkr_desel_1

phantom_lockout_2:
        ldab    active_chs
        andb    #%00100011
        orab    #%00001100                      ;Select LS,RS ; deselect CR
        stab    active_chs
        anda    #%00110011                      ;Mask out LS,RS highlights
        bra     spkr_desel_1


;***********************************************************************
;*
;* X-Over selections
;*
;***
x_over_mode:
        ldaa    xover_rolloff                   ;Check if first time through
        bne     x_over_already

        ldaa    #.SCREEN.Bass_Man    
        staa    screen_num
        jsr     LCD_init
        jsr     display_scrn                    ;Put up Bass Management screen
        ldaa    #$ff
        staa    xover_rolloff                   ;Flag that screen is up
        rts

x_over_already:
        ldaa    #137
        staa    t_state                         ;Prepare for 1-6 keys
        clr     b_state
        rts

x_over_sels:
        ldab    dec_key
        andb    #%01111111                      ;Map TMS numbers onto TM numbers.
        cmpb    #5                              ;Can't xover sub (so do nothing here)
        beq     x_over_sels_end_3      

        decb
        ldy     #spkr_masks_symm
        aby
        ldaa    0,y                             ;Get bit info for speakers

        tab
        andb    rolloff_chs                     ;If selection is rolled off,
        bne     x_over_sels_end                 ; do not do x-over

        tab
        andb    active_chs                      ;If deselected, do nothing
        beq     x_over_sels_end_3       

        eora    xover_chs                       ;Toggle key information
        staa    xover_chs
x_over_sels_end:
        jsr     force_new_Z
x_over_sels_end_2:
        jmp     Bass_man_screen                 ;Put up new symbols

x_over_sels_end_3:
        rts


;***********************************************************************
;*
;* Roll-Off selections
;*
;***
roll_off_mode:
        ldaa    xover_rolloff                   ;Check if first time through
        bne     roll_off_already

        ldaa    #.SCREEN.Bass_Man
        staa    screen_num
        jsr     LCD_init
        jsr     display_scrn                    ;Put up Bass Management screen
        ldaa    #$ff
        staa    xover_rolloff                   ;Flag that screen is up
        rts


roll_off_already:
        ldaa    #138
        staa    t_state                         ;Prepare for 1-6 keys
        clr     b_state
        rts


roll_off_sels:
        ldab    dec_key
        andb    #%01111111                      ;Map TMS numbers onto TM numbers.
        cmpb    #5                              ;Can't roll-off SUB
        beq     roll_off_sels_end_1

        decb
        ldy     #spkr_masks_symm
        aby
        ldaa    0,y                             ;Get bit info for speakers

        tab
        andb    active_chs                      ;If deselected, do nothing
        beq     roll_off_sels_end_1     

        eora    rolloff_chs                     ;Toggle key information
        staa    rolloff_chs

        oraa    xover_chs                       ;Cross over any channels that are rolled off
        staa    xover_chs               
roll_off_sels_end:
        jsr     force_new_Z
        jmp     Bass_man_screen                 ;Put up new symbols

roll_off_sels_end_1:
        rts


;***********************************************************************
;*
;* Cross-Over frequency selections
;*
;***
xover_freq_select:                              ;Reached by pressing the SUB key
        ldaa    screen_num
        cmpa    #.SCREEN.Sys_Config             ;Check if in Sys. Config screen,
        beq     xover_fsel_end                  ;If so, do nothing

        ldaa    #.SCREEN.Sys_Config   
        staa    screen_num
        clr     xover_rolloff                   ;Just in case coming from Bass mgt
        jmp     display_scrn                    ;Show System Config screen

xover_fsel_updn:
        clr     ir_tout
        clr     t_state                         ;Flush timeout

        ldaa    xover_val
        ldab    ps_frame
        cmpb    #k_tms_rcl                      ;Channel down
        beq     xover_fsel_dn

xover_fsel_up:
        cmpa    #9                              ;Check for end of list
        beq     xover_fsel_end

        inc     xover_val
        bra     xover_fsel_disp         

xover_fsel_dn:
        tsta
        beq     xover_fsel_end                  ;Check if at beginning of list

        dec     xover_val
xover_fsel_disp:
        jsr     force_new_Z
        jmp     sys_cfg_1                       ;Update display

xover_fsel_end:
        rts


;***********************************************************************
;*
;* Speaker distance adjustment
;*
;***

spkr_dist_adjust:
        ldaa    curr_chs
        bne     spkr_dist_1
        jmp     do_store_mem                    ;If no spkrs selected, do store


spkr_dist_1:
        clr     ir_tout                         ;Flush timeout
        clr     t_state

        ldaa    curr_chs                        ;If nothing selected go home!
        beq     spkr_dist_updn_end

        ldaa    ps_frame
        cmpa    #k_tms_sto
        beq     spkr_dist_up

spkr_dist_dn:
        bsr     bit_to_dist
        dec     0,y
        bra     spkr_dst_show

spkr_dist_up:
        bsr     bit_to_dist
        inc     0,y
spkr_dst_show:
        ldaa    0,y
        cmpa    #100
        bne     s_dst_2

        ldaa    #99
        bra     s_dst_3

s_dst_2:
        cmpa    #255
        bne     s_dst_3

        ldaa    #0
s_dst_3:
        staa    0,y
       
        jsr     spkr_dist_nums
        jmp     force_new_Z

spkr_dist_updn_end:        
        rts


bit_to_dist:                                    ;Convert curr_chs to an offset into
        ldaa    curr_chs                        ; the distance table
        cmpa    #3
        bne     bd_1

        ldab    #0
        bra     bd_3

bd_1:   cmpa    #$0c
        bne     bd_2

        ldab    #1
        bra     bd_3

bd_2:   ldab    #2
bd_3:   ldy     #LFRF_dst
        aby
        rts


;***********************************************************************
;*
;* Select Number of Subwoofers in Speaker Config screen
;*
;* This routine is accessible only from the Spkr_Cfg screen.
;*
;***
subwoofer_select:
        clr     ir_tout
        clr     t_state                         ;Flush timeout

        ldaa    spkr_cfg
        anda    #%0001
        beq     sub_ref_cinema

;%%% Toggle sub on/off for Cinema 7.1...
sub_71: ldaa    spkr_cfg
        eora    #%0100
        staa    spkr_cfg
        bra     sub_sel_disp

;%%% Increment/Decrement # Subs for Reference Cinema...
sub_ref_cinema:
        ldaa    spkr_cfg
        ldab    ps_frame
        cmpb    #k_tms_rcl                      ;Channel down decrements # subs.
        beq     sub_sel_dn

sub_sel_up:                                     ;Channel up increments # subs.
        adda    #%0100
        staa    spkr_cfg
        anda    #%1100
        cmpa    #%1100
        bne     sub_sel_disp

        ldaa    spkr_cfg
        anda    #%0011                          ;Correct 3 to 0 for incrementing modulo 3.
        staa    spkr_cfg
        bra     sub_sel_disp

sub_sel_dn:
        suba    #%0100                          ;Decrement number of subs.
        staa    spkr_cfg
        anda    #%1100
        cmpa    #%1100
        bne     sub_sel_disp

        ldaa    spkr_cfg
        anda    #%0011
        oraa    #%1000                          ;Correct 3 to 2 for decrementing modulo 3.
        staa    spkr_cfg

sub_sel_disp:
        ldaa    spkr_cfg       
        anda    #%1100         
        beq     sub_sel_disp2  
                               
        ldaa    #%111111       
        staa    active_chs     
                               
sub_sel_disp2:                 
        ldaa    spkr_cfg               ;>>>     ;Fixes the bug in version 7.1
        ldab    #ee_spkr_cfg           ;>>>     ; that # subwoofers was not
        jsr     write_globals          ;>>>     ; saved in globals.

        jsr     force_new_Z
        jmp     Spkr_Config_screen              ;Update display


;***********************************************************************
;*
;* Icon display routines for Main screen:
;* HDCD, HF-EQ ( = CinEQ), ES, Music
;* 
;***
;%%%%%%%%%%%%%
show_HDCD:                              ;HDCD icon routine
        ldaa    screen_num
        cmpa    #.SCREEN.Main      
        bne     show_HDCD_e2            ;If not in Main screen, just do vol corrs

        ldaa    hdcd_on
        beq     show_HDCD_1

        ldx     #regbase
        brset   porta,x,#%10000000,show_HDCD_1  ;If dts selected, do not
                                                ; show HDCD icon
        ldx     #regbase
        brset   porte,x,#%00100000,show_HDCD_1  ;If dts selected, do not
                                                ; show HDCD icon
        ldaa    #16
        ldy     #HDCD
        jsr     SCREENS                 ;Put up HDCD icon
        bsr     show_HDCD_end           ;Do vol corrs
        jmp     Small_Volume            ;Show any compression


show_HDCD_1:
        ldaa    #16
        ldab    #19
        jsr     Section_clear           ;Clear HDCD icon.
        bsr     show_HDCD_end           ;Do vol corrs.
        jmp     Small_Volume            ;Show any compression

show_HDCD_e2:                           ;Not in screen 1....
        bsr     show_HDCD_end           ;Do vol corrs
        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Adj       ;Check if in Speaker Adjustment screen
        bne     show_HDCD_ret           ;If not, go home now
        jmp     display31               ;If so, update volumes

show_HDCD_end:
        ldaa    curr_mode               ;Put current PCM mode into temp. vbl
        staa    curr_mode_temp          ;so that vol. corrs. get correct mode info
        jsr     check_HDCD_corr         ;Check if 6dB gain needed
        jsr     update_corr             ;Redo volume corrections
        jsr     unpack_vol
show_HDCD_ret:
        rts


;%%%%%%%%%%%%%
show_HFEQ:                              ;HFEQ icon routine
        ldaa    screen_num
        cmpa    #.SCREEN.Main       
        bne     .show_HFEQ_end          ;If not in Main screen, do nothing

        ldaa    curr_pass_mode
        bne     .unshow_HFEQ            ;If in Anlg Pass-Thru, clear HFEQ icon

        jsr     get_correct_hfeq
        ldaa    0,y
        beq     .unshow_HFEQ

        ldx     #ead_lst                ;Get Z2 HFEQ byte (par 4).
        brclr   5,x,#%01000000,.unshow_HFEQ

        ldaa    #32
        ldy     #HFEQ                   ;Put up HFEQ icon
        jsr     SCREENS
        bra     .show_HFEQ_end

.unshow_HFEQ:
        ldaa    #32
        ldab    #32
        jsr     Section_clear           ;Clear HFEQ icon
.show_HFEQ_end:
        rts


;%%%%%%%%%%% (Show ES, Party, or Music icon)
show_ESMP:                              ;ES/Party/Music icon routine
        ldaa    screen_num
        cmpa    #.SCREEN.Main       
        bne     show_ESMP_end           ;If not in Main screen, do nothing.

        ;The Party icon has priority over the ES and Music icons...
        ldaa    party_flag
        bne     party_icon

        bsr     unshow_icon             ;Clear Party "P" icon and then
        bra     .show_contd             ; see if ES or Music icons should be redisplayed.

party_icon:
        ldy     #PartyON
        bra     show_icon

.show_contd:
        ldaa    spkr_cfg
        anda    #%0001
        bne     cinema71_icon

ref_cinema_icon:
        ldaa    es_flag
        beq     unshow_icon             ;If ES disabled, put up blank,

        ldy     #ESon                   ;Else put up ES icon.
        bra     show_icon

cinema71_icon:
        ldaa    spkr_cfg
        anda    #%0010
        beq     unshow_icon             ;If Movie mode, put up blank,

        ldy     #MusicON                ;Else put up Music icon.
        bra     show_icon

show_icon:
        ldaa    #31
        jsr     SCREENS
        bra     show_ESMP_end

unshow_icon:
        ldaa    #31
        ldab    #31
        jsr     Section_clear           ;Clear ES icon
show_ESMP_end:
        rts


;***********************************************************************
;*
;* Input label changing in TMS mode
;*
;***
Designators:    equ     54

label_updn:
        ldaa    screen_num
        cmpa    #.SCREEN.Main       
        bne     label_updn_end          ;If not in Main screen, ignore.

        ldab    ms_save                 
        tba
        andb    #%01111111              ;Get channel number information in B
        decb
        anda    #%10000000              ;Get analog/digital information in A
        beq     dig_labs_updn

ana_labs_updn:
        ldy     #Ana_labels
        bra     get_labs_updn

dig_labs_updn:
        ldy     #Dig_labels
get_labs_updn:
        aby
        ldaa    0,y                     ;Get label pointer number
        ldab    ps_frame
        cmpb    #k_tm_sto               ;Check for channel up
        beq     label_up

label_down:  
        deca
        bge     label_updn1             ;Check if at end of list

        ldaa    #Designators
        bra     label_updn1             ;Wrap around to bottom of list

label_up:
        inca
        cmpa    #Designators+1  
        bne     label_updn1

        clra
label_updn1:
        staa    0,y                     ;Save new label number
        ldaa    #26                     ;Screen pos'n.
        jsr     input_label             ;Display input label
        jsr     click

label_updn_end:
        rts


;********************************************************************
;* Screen up/down
;***
screen_updn:
        ldaa    ps_frame
        cmpa    #k_scrn_dn
        beq     screen_down 

        cmpa    #k_scrn_up
        beq     screen_up

        ;Else if k_scrn...
screen_togl:
        ldx     #regbase
        brclr   porta,x,#%00010000,screen_down  ;If screen up, put it down

screen_up:
        ldx     #regbase
        bclr    porta,x,#%00010000              ;0V = screen up
        bra     screen_end

screen_down:
        ldx     #regbase
        bset    porta,x,#%00010000              ;12V = screen down
screen_end:
        ldaa    screen_num
        cmpa    #.SCREEN.Feat_Sel        
        bne     screen_rts

        jsr     feats_sel_bits
screen_rts:
        rts


;********************************************************************
;* Vertical enhance toggle
;***
v_enh_togl:
        ldaa    ps_frame
        cmpa    #k_v_enh_on
        beq     v_enh_on                        ;Assert vertical enhancer.

        cmpa    #k_v_enh_off
        beq     v_enh_off                       ;Deassert vertical enhancer.

        ldaa    screen_num
        cmpa    #.SCREEN.Feat_Sel       
        beq     do_v_enh_togl                   ;If already in Features Selection screen, go ahead

        ldaa    flash_up                        ;If already flashing screen, do toggle
        bne     do_v_enh_togl


        ldaa    #1
        staa    screen_status1                  ;Set up timer for screen flashing 
        staa    flash_up
        jsr     LCD_init
        jmp     Features_selection_screen       ;Put up Features Selection screen

do_v_enh_togl:
        ldaa    v_enh_flag
        beq     v_enh_on                        

v_enh_off:
        ldab    #$1a
        jsr     send_sci                        ;SM vert. enh code

        clr     v_enh_flag                      ;V-Enh off
        bra     v_enh_end

v_enh_on:
        ldab    #$19
        jsr     send_sci

        ldaa    #1                              ;V-Enh on
        staa    v_enh_flag

v_enh_end:
        ldaa    v_enh_flag
        ldab    #ee_ven
        jsr     write_globals                   ;Write new value into EEPROM

        ldaa    #1
        staa    screen_status1                  ;Refresh timer for screen
        staa    flash_up
        jmp     Features_selection_screen       ;Update Features Selection screen


;********************************************************************
;* S-video toggle ([Video][Video])
;***
sm_s_toggle:
        ldab    #$18
        jsr     send_sci                        ;Toggle SM S video

        ldaa    curr_vid
        eora    #$80                            ;Toggle S video selection
        staa    curr_vid

        jsr     show_vid_sel                    ;Flash up current selection

        IFNE    name-3       ;OVATION-8 or SIGNATURE-8

           ldaa    curr_vid
           deca
           staa    EO_Vmux_imag
           anda    #$80                         ;If composite video,
           beq     .v_ok                        ;leave as is...

           ldaa    EO_Vmux_imag                 ;Else adjust by 3 for S-video...
           adda    #3
           staa    EO_Vmux_imag
.v_ok:     jsr     update_EO_Vmux

        ENDC

        clr     b_state
        ldaa    #142                            ;Get ready for number push
        staa    t_state                         ;or another video push
	ldab    #long
        stab    ir_tout                         ;Set command sequence timeout
        
        rts


;********************************************************************
;* Late night toggle
;*
;* (Note: the LN= display should be suppressed unless in AC-3 mode)
;*      --this has not been done yet!
;***
ln_togl:
        ldaa    screen_num
        cmpa    #.SCREEN.Feat_Sel       
        beq     do_ln_togl                     ;If already in Features Selection screen, go ahead

        ldaa    flash_up                       ;If already flashing screen, do toggle
        bne     do_ln_togl

ln_togl_0:
        ldaa    #1
        staa    screen_status1                 ;Set up timer for screen flashing 
        staa    flash_up

        jsr     LCD_init
        jmp     Features_selection_screen      ;Put up Features Selection screen


do_ln_togl:
        inc     late_nite
        ldaa    late_nite
        cmpa    #4
        bne     ln_togl_2

ln_togl_1:
        clr     late_nite
ln_togl_2:
        jsr     Features_selection_screen

        ldaa    #1                              ;Do screen and
        staa    screen_status1
        staa    flash_up

        jsr     force_new_Z                     ; force new Zoran mode
        rts


;-------------------------------------------
LN_determined:                                  ;RS232 deterministic codes
        ldaa    ps_frame
        cmpa    #k_LN_off
        beq     ln_off

        cmpa    #k_LN_low
        beq     ln_low

        cmpa    #k_LN_med
        beq     ln_med

        cmpa    #k_LN_high
        beq     ln_high

ln_off:
        ldaa    #0
        bra     ln_deter

ln_low:
        ldaa    #1
        bra     ln_deter

ln_med:
        ldaa    #2
        bra     ln_deter

ln_high:
        ldaa    #3
ln_deter:
        staa    late_nite                       ;Store selection
        bra     ln_togl_0                       ;Flash up LN screen


;********************************************************************
;* Display number setting from RS232
;***
disp_nums:
        jsr     get_2nd                         ;Get 2 digits in B
        cmpb    #Max_screens
        bhi     disp_nums_end                   ;Check for too high

        cmpb    #0
        beq     disp_nums_end

        stab    screen_num
        clr     screen_status1                  ;Flush change timers
        clr     screen_status2
        clr     screen_status3
        jsr     LCD_init
        jmp     display_scrn

disp_nums_end:
        rts              ;*** Return ***


;********************************************************************
;*
;* vtodB -  Subroutine to convert an 8-bit unsigned binary volume 
;*          (stored right-justified in a 16-bit word)
;*          at X to a 3 digit decimal dB volume NN.N in dbufr
;*          (decimal point is implied).
;*
;* vtodB2 - Subroutine to convert an 8-bit unsigned binary volume 
;*          in b register to a 3 digit decimal dB volume NN.N in dbufr
;*          (decimal point is implied).
;*
;*
;* NEW OVATION-8/SIGNATURE-8/SIGNATURE+8:
;*
;*        Maximum volume:     0 * 5  =   0.0 dB
;*                            1 * 5  =  -0.5 dB
;*                            2 * 5  =  -1.0 dB
;*                            .      .    .
;*                            .      .    .
;*                            .      .    .
;*        Minimum volume:   191 * 5  = -95.5 dB
;*
;*
;* Puts decimal result in 3 byte variable dbufr.
;*
;* Preserves all registers.
;*
;***
vtodB:
        ldd     0,x             ;Get volume number (in 0.5 dB units)
vtodB2:
        ldaa    #5
        mul                     ; * 5 
        jsr     word_to_3

        ldaa    dbufr
        cmpa    #$f0            ;Compensate for leading zeros
        bne     vto_1

        clr     dbufr
vto_1:
        rts              ;*** Return ***


;***********************************************************************
;*
;* Subroutine to convert an unsigned word in D into a 3 digit decimal
;* number in dbufr
;*
;* Destroys x,d registers.
;*
;***
word_to_3:
        ldx     #100
        idiv                    ;r/100 -> X; r -> D.
        xgdx                    ;Save r in X; 100s digit in D (A:B).
        stab    dbufr           ;Store 100s digit as tens dB in volume buffer.
        xgdx                    ;r back to D.
        ldx     #10
        idiv                    ;r/10 -> X; r in D (B is units digit).
        stab    dbufr+2         ;Store 1s digit as fractional dB in volume buffer.
        xgdx                    ;10s digit to D (A:B).
        stab    dbufr+1         ;Store 10s digit as 1s dB in volume buffer.
        rts              ;*** Return ***


;***********************************************************************
;*
;* Subroutine to convert an unsigned byte in B into a 3 digit decimal
;* number in dbufr
;*
;* Destroys x,d registers.
;*
;***
byte_to_3:
        clra
        ldx     #100
        idiv
        xgdx
        tstb
        bne     first_num_b3

        ldab    #$f0                    ;Gives leading ASCII space ($20)
        stab    dbufr                   ; when summed with $30.
        clrb
        bra     sec_num_b3

first_num_b3:
        stab    dbufr
sec_num_b3:
        xgdx                            ;Get remainder
        ldx     #10
        idiv
        xgdx
        stab    dbufr+1
        xgdx
        stab    dbufr+2
        rts              ;*** Return ***


;***********************************************************************
;* compose_volume:
;*
;* Takes 6 channels of volume and creates one overall volume
;* stored in vol_overall
;*
;* Currently this routine takes the louder of LF and RF,
;* ignoring the other channels.
;*
;***
compose_volume:
        ldd     vcp_l
        cpd     vcp_r
        blo     compose_left

compose_right:
        ldd     vcp_r
compose_left:
        std     vol_overall
        rts              ;*** Return ***


;***********************************************************************
;*
;*                    BAR GRAPH VU METER ROUTINES
;*
;***********************************************************************
;*
;* BAR VOLUME (Bar_volume):
;* =======================
;*
;*   Collects Z2 volume information. Note that the Z2 channel peaks
;*   are calculated before the channel re-arrangement required by
;*   Cinema 7.1 Movie mode, and so do not change their positions.
;*   Cinema 7.1 Music mode is a sub set of Reference Cinema mode,
;*   but is shown with six VU bars because it does not have ES or
;*   a second sub woofer.
;*
;*
;* BAR CONVERT (Bar_conv):
;* ======================
;*
;*   Takes the 3-byte (20-bit, 2's complement fractional, positive)
;*   volume information previously received from Z2, rolls this left
;*   4 bits, then apart from the special case of 0 dB which is treated
;*   differently, finds the highest bit in the first 2 bytes. Returns
;*   8-bit 1-17 (LCD) or 1-16 (VFD) (6 dB per step) result in A.
;*
;*
;* LCD DISPLAY [obsolete]:
;* ======================
;*
;*   $07fff0  ->  $7fff                0 dB        17
;*                $4000 - $7ffe       -6 dB        16
;*                $2000 - $3ffe      -12 dB        15
;*                $1000 - $1fff      -18 dB        14
;*                $0800 - $0fff      -24 dB        13
;*                $0400 - $07ff      -30 dB        12
;*                $0200 - $03ff      -36 dB        11
;*                $0100 - $01ff      -42 dB        10
;*                                                 
;*                $0080 - $00ff      -48 dB         9  Gap shows as 8.
;*                                               
;*                $0040 - $007f      -54 dB         8
;*                $0020 - $003f      -60 dB         7
;*                $0010 - $001f      -66 dB         6
;*                $000f - $0007      -72 dB         5
;*                $0007 - $000e      -78 dB         4
;*                $0003 - $0006      -84 dB         3
;*                $0001 - $0002      -90 dB         2
;*                $0000             <-90 dB         1
;*
;*
;* VFD DISPLAY:
;* ===========
;*
;*   $07fff0  ->  $7fff                0 dB        16
;*                $4000 - $7ffe       -6 dB        15
;*                $2000 - $3ffe      -12 dB        14
;*                $1000 - $1fff      -18 dB        13
;*                $0800 - $0fff      -24 dB        12
;*                $0400 - $07ff      -30 dB        11
;*                $0200 - $03ff      -36 dB        10
;*                $0100 - $01ff      -42 dB         9
;*                                                     Ignore small gap.
;*                $0080 - $00ff      -48 dB         8  
;*                $0040 - $007f      -54 dB         7
;*                $0020 - $003f      -60 dB         6
;*                $0010 - $001f      -66 dB         5
;*                $000f - $0007      -72 dB         4
;*                $0007 - $000e      -78 dB         3
;*                $0003 - $0006      -84 dB         2
;*                $0000             <-84 dB         1
;*
;*
;*
;* BAR SCALING (scale_bars):
;* ========================
;*
;*   Depending on DIP SW8, the resulting 5-bit VU dB value (1-17 or 1-16)
;*   is adjusted for the volume attenuation level.
;*
;*
;*** 
Bar_volume: 
        ldy     #peek_vol
        jsr     WR_Z2

        ldy     #ret_inf+11            ;LF
        jsr     Bar_conv
        ldy     #vcp_l
        jsr     scale_bars
        staa    bar_info+0

        ldy     #ret_inf+15            ;CT
        jsr     Bar_conv
        ldy     #vcp_c
        jsr     scale_bars
        staa    bar_info+1

        ldy     #ret_inf+19            ;RF
        jsr     Bar_conv
        ldy     #vcp_r
        jsr     scale_bars
        staa    bar_info+2

        ldy     #ret_inf+35            ;SB-L
        jsr     Bar_conv
        ldy     #vcp_sub    
        jsr     scale_bars
        staa    bar_info+3

        ldy     #ret_inf+31            ;SB-R (SUB)
        jsr     Bar_conv
        ldy     #vcp_sub
        jsr     scale_bars
        staa    bar_info+4

        ldy     #ret_inf+23            ;LS
        jsr     Bar_conv
        ldy     #vcp_ls
        jsr     scale_bars
        staa    bar_info+5

        ldaa    spkr_cfg               ;If we are in
        anda    #%0001                 ; the Reference
        bne     .es_bar_info           ; Cinema layout,
                                       ; and ES
        ;Ref. Cinema comes here:       ; is not
        ldaa    es_flag                ; enabled,
        bne     .es_bar_info           ; then suppress
                                       ; the display
        ldaa    #1                     ; of the ES
        staa    bar_info+6             ; VU meter
        bra     .rs_bar_info           ; bar.

.es_bar_info:
        ldy     #ret_inf+39            ;ES
        jsr     Bar_conv
        ldy     #vcp_es     
        jsr     scale_bars
        staa    bar_info+6

.rs_bar_info:
        ldy     #ret_inf+27            ;RS
        jsr     Bar_conv
        ldy     #vcp_rs
        jsr     scale_bars
        staa    bar_info+7

.no_es_bar:
        ldx     #regbase               ;Clear Zoran #2 channel peaks space.
        ldy     #poke_vol
        jsr     WR_Z2    
.b_out:
        rts                       ;** Return **


;---------------------------------------------------------------
Bar_conv:
        ldab    #4                             ;Roll counter
roll4_loop:
        clc
        rol     2,y                            ;Roll three bytes
        rol     1,y
        rol     0,y
        decb
        bne     roll4_loop

        ldx     #16                            ;Max. level is 16 for VFD.

        ldd     0,y                            ;Take first 2 bytes
        cpd     #$7fff
        beq     log_record                     ;0 dB is max. level.

        inx
        clc
log_loop:
        dex                                    ;Reduce by 1 for each position
        cpx     #1                             ;Check for minimum
        beq     log_record

        asld                                   ;Check next bit
        bcc     log_loop

log_record:
        xgdx
        tba        
        rts                                    ;** Return ** 

;-------------------------------------------------------------------
scale_bars:
       cmpa     #1                             ;If bar level already at smallest level,
       beq      s_bars_end                     ; then don't scale.
       brset    DIP_imag,#%10000000,s_bars_end ;If DIP SW8 OFF (=1), skip scaling (default)...

       ;Else if DIP SW8 ON (=0), scale the volumes...
       psha                                    ;Save bar level
       ldd      0,y                            ;Get attenuation level
       ldx      #Six_dB                        ;Divide by 6 dB.
       idiv
       xgdx                                    ;Get result in D (all in B actually)
       pula
       sba                                     ;Bar dB - atten dB = scaled bar
       bgt      s_bars_end                     ;If >=1, all ok

       ldaa     #1                             ;If <=0, set to 1

s_bars_end:
       rts

        
;************************************************************************
;*
;* Lookup table for remapping the bar graph dB scale (not currently used).
;*
;* The table should have 17 elements (LCD) or 16 elements (VFD).
;* The first element should be 1, the last should be 16 or 17.
;* The given table is an exmaple only.
;* The remapping feature is not currently used.
;*
;***
;remap_dB:
;        ldy     #dB_table
;        aby
;        ldaa    0,y
;        bra     dB_ret
;
;dB_table: dc.b 1,2,2,2,2,2,2,2,3,4,5,7,9,11,13,15,17     


;************************************************************************
;*
;* Display of 2-Channel Bar Graph
;*
;* Upon entry, bar_info contains 6 unsigned integers (0-17 or 0-16)
;* representing the 6 volumes. This routine displays a 2-channel bar
;* graph corresponding to the LF and RF volumes.
;*
;***
Bar2_Display:

;%% Local variables on the stack:

wbars:  equ     0    ;Full screen of bars arranged as
                     ; 40 characters, |, then 40 font specifier characters
        tsx
        xgdx
        subd    #81                    ;Reserve stack space for bars screen.
        xgdx
        txs                            ;X points to local variables

        ldab    #81                    ;Clear bar graph storage area
        ldaa    #$20                   ; (all spaces if after 3 secs,
        tsy                            ; spaces and names if before )
wbar_loop1:
        staa    0,y
        iny
        decb
        bne     wbar_loop1

        ldaa    #'|'                   ;String delimiter
        staa    wbars+40,x

        ldaa    three_secs             ;Check if within 3 seconds
        beq     wdisplay_bars          ; if not, do full bars...

        ldab    #20                    ; if so, put in channel names...
wbar_loop2:
        ldy     #channel_2_names-20
        aby
        ldaa    0,y                    ;Get channel name character
        tsy
        aby
        staa    0,y                    ;Store in screen string
        incb
        cmpb    #40
        bne     wbar_loop2

wdisplay_bars:
        ldaa    bar_info+0
        ldab    #2                     ;Left bar position.
        bsr     do_wide_bar

        ldaa    bar_info+2            
        ldab    #12                    ;Right bar position.
        bsr     do_wide_bar
        jmp     put_out_bars           ;Display bars and mute (if necessary)


do_wide_bar:
        cmpa    #17
        bls     wheight_ok

        ldaa    #17                    ;Maximum height is 17.
wheight_ok:
        adda    #$30                   ;Convert height to ASCII
        cmpa    #$30
        beq     wbar_done              ;If height = 0, return.

wheight2:
        cmpa    #$38                   ;VFD
        bls     wlower_part            ;Check for <= 9

wupper_part:
        suba    #8                     ;VFD
        tsy
        iny
        iny
        aby

        staa    wbars+0,y              ;Store bar height info...
        staa    wbars+1,y              
        staa    wbars+2,y
        staa    wbars+3,y
        staa    wbars+4,y
        staa    wbars+5,y

        pshb
        ldab    #41
        aby
        ldaa    #'='
        staa    wbars+0,y              ;Store bar font info...
        staa    wbars+1,y
        staa    wbars+2,y
        staa    wbars+3,y
        staa    wbars+4,y
        staa    wbars+5,y

        pulb                           ;Restore bar position info.
        ldaa    #$38                   ;Fill in bottom part of tall bar.

wlower_part:
        psha
        ldaa    three_secs             ;Check if in first two secs
        pula
        bne     wbar_done              ; if so, no lower line
        
        cmpa    #$39        
        bne     wless

wless:  addb    #20                    ;Move to lower part of screen
        tsy
        iny
        iny
        aby
        staa    wbars+0,y              ;Store bar height info.
        staa    wbars+1,y
        staa    wbars+2,y
        staa    wbars+3,y
        staa    wbars+4,y
        staa    wbars+5,y
                
        ldab    #41
        aby
        ldaa    #'='                   ;Store bar font info.
        staa    wbars+0,y
        staa    wbars+1,y
        staa    wbars+2,y
        staa    wbars+3,y
        staa    wbars+4,y
        staa    wbars+5,y
                
wbar_done:
        rts


;************************************************************************
;*
;* Display of 6-Channel Bar Graph -- Cinema 7.1 Music mode only.
;*
;* Upon entry, bar_info contains 8 unsigned integers (0-17 for LCD or
;* 0-16 for VFD) representing the 8 volumes. Two of these (SB-L and ES)
;* are ignored in this mode.
;*
;* This routine displays the bar graph corresponding to these volumes.
;*
;***
Bar6_Display:

;* Local variables on the stack:

mubars: equ     0     ;Full screen of bars, arranged as
                      ; 40 characters, |, then 40 font specifier characters.
        tsx
        xgdx
        subd    #81                    ;Reserve stack space for bars screen.
        xgdx
        txs                            ;x points to local variables

        ldab    #81                    ;Clear bar graph storage area
        ldaa    #$20                   ; (all spaces if after 2 secs,
        tsy                            ; spaces and names if before )
mubar_loop1:
        staa    0,y
        iny
        decb
        bne     mubar_loop1

        ldaa    #'|'                   ;String delimiter
        staa    mubars+40,x

        ldaa    three_secs             ;Check if within 2 seconds
        beq     display_mubars         ; if not, do full bars...
                                       
        ldab    #20                    ; if so, put in channel names...
mubar_loop2:
        ldy     #channel_6_names-20
        aby
        ldaa    0,y                    ;Get channel name character
        tsy
        aby
        staa    0,y                    ;Store in screen string
        incb
        cmpb    #40
        bne     mubar_loop2

display_mubars:
        ldaa    bar_info+0
        ldab    #1                     ;1st bar position. LF
        bsr     do_mubar

        ldaa    bar_info+1
        ldab    #4                     ;2nd bar position. CT
        bsr     do_mubar

        ldaa    bar_info+2
        ldab    #7                     ;3rd bar position. RF
        bsr     do_mubar

        ldaa    bar_info+5
        ldab    #11                    ;4th bar position. LS
        bsr     do_mubar

        ldaa    bar_info+4
        ldab    #14                    ;5th bar position. SB
        bsr     do_mubar

        ldaa    bar_info+7
        ldab    #17                    ;6th bar position. RS
        bsr     do_mubar
        jmp     put_out_bars           ;Display bars and mute (if necessary)


do_mubar:
        cmpa    #17
        bls     muheight_ok

        ldaa    #17                    ;Maximum height is 17.
muheight_ok:
        adda    #$30                   ;Convert height to ASCII
        cmpa    #$30
        beq     mubar_done             ;If height = 0, return.

        cmpa    #$38                   ;VFD
        bls     lower_mupart           ;Check for <= 9

upper_mupart:
        suba    #8                     ;VFD
        tsy
        iny
        iny
        aby
        staa    mubars+0,y             ;Store bar height info...
        staa    mubars+1,y
        pshb
        ldab    #41
        aby
        ldaa    #'='                   ;Store bar font info...
        staa    mubars+0,y
        staa    mubars+1,y
        pulb                           ;Restore bar position info.
        ldaa    #$38                   ;Fill in bottom part of tall bar.
lower_mupart:
        psha
        ldaa    three_secs             ;Check if in first two secs
        pula
        bne     mubar_done             ; if so, no lower line

        cmpa    #$39
        bne     muless

muless:  addb    #20                   ;Move to lower part of screen
        tsy
        iny
        iny
        aby
        staa    mubars+0,y             ;Store bar height info.
        staa    mubars+1,y

        ldab    #41
        aby
        ldaa    #'='                   ;Store bar font info.
        staa    mubars+0,y
        staa    mubars+1,y
mubar_done:
        rts


;******************************************************************************
;*
;* Display of 8-Channel Bar Graph -- Ref.Cinema and Cinema 7.1 Movie mode only.
;*
;* Upon entry, bar_info contains 8 unsigned integers (0-17 for LCD or
;* 0-16 for VFD) representing the 8 volumes.
;*
;* This routine displays the bar graph corresponding to these volumes.
;*
;***
Bar8_Display:

;* Local variables on the stack:

bars:    equ     0    ;Full screen of bars, arranged as
                      ; 40 characters, |, then 40 font specifier characters.
        tsx
        xgdx
        subd    #81                    ;Reserve stack space for bars screen.
        xgdx
        txs                            ;x points to local variables

        ldab    #81                    ;Clear bar graph storage area
        ldaa    #$20                   ; (all spaces if after 2 secs,
        tsy                            ; spaces and names if before )
bar_loop1:
        staa    0,y
        iny
        decb
        bne     bar_loop1

        ldaa    #'|'                   ;String delimiter
        staa    bars+40,x

        ldaa    three_secs             ;Check if within 2 seconds
        beq     display_bars           ; if not, do full bars...
                                       
        ldab    #20                    ; if so, put in channel names...
bar_loop2:
        ldy     #channel_8_names-20
        aby
        ldaa    0,y                    ;Get channel name character
        tsy
        aby
        staa    0,y                    ;Store in screen string
        incb
        cmpb    #40
        bne     bar_loop2

display_bars:
        ldaa    bar_info+0
        ldab    #0                     ;1st bar position. LF
        bsr     do_bar

        ldaa    bar_info+1
        ldab    #3                     ;2nd bar position. CT
        bsr     do_bar

        ldaa    bar_info+2
        ldab    #6                     ;3rd bar position. RF
        bsr     do_bar

        ldaa    spkr_cfg
        anda    #%1100
        cmpa    #%0100                 ;1 sub = %0100
        beq     .1_wide_sub

.2_thin_subs:
        ldaa    bar_info+3
        ldab    #9                     ;4th bar position. SB-L
        jsr     do_thin_bar

        ldaa    bar_info+4
        ldab    #10                    ;5th bar position. SB-R (default SUB)
        jsr     do_thin_bar
        bra     .do_surrounds

.1_wide_sub:
        ldaa    bar_info+4
        ldab    #9                     ;4th & 5th bar positions for one SUB = SB-R
        bsr     do_bar

.do_surrounds:
        ldaa    bar_info+5
        ldab    #12                    ;6th bar position. LS
        bsr     do_bar

        ldaa    bar_info+6
        ldab    #15                    ;7th bar position. ES
        bsr     do_bar

        ldaa    bar_info+7
        ldab    #18                    ;8th bar position. RS
        bsr     do_bar
        jmp     put_out_bars           ;Display bars and mute (if necessary)

do_bar: cmpa    #17                    ;Maximum bar height + 1.
        bls     height_ok

        ldaa    #16                    ;Maximum bar height.
height_ok:
        adda    #$30                   ;Convert height to ASCII
        cmpa    #$30
        beq     bar_done               ;If height = 0, return.

        cmpa    #$38                   ;VFD lower bar is 1 to 8 ($31 to $38).
        bls     lower_part             ;Check for <= 9

upper_part:
        suba    #8                     ;VFD upper bar is 1 to 8 ($31 to $38).
        tsy
        iny
        iny
        aby

        staa    bars+0,y               ;Store bar height info...
        staa    bars+1,y

        pshb
        ldab    #41
        aby
        ldaa    #'='                   ;Store bar font info...

        staa    bars+0,y
        staa    bars+1,y

        pulb                           ;Restore bar position info.
        ldaa    #$38                   ;Fill in bottom part of tall bar.
lower_part:
        psha
        ldaa    three_secs             ;Check if in first two secs
        pula
        bne     bar_done               ; if so, no lower line

        cmpa    #$39
        bne     less

less:   addb    #20                    ;Move to lower part of screen
        tsy
        iny
        iny
        aby

        staa    bars+0,y               ;Store bar height info.
        staa    bars+1,y

        ldab    #41
        aby
        ldaa    #'='                   ;Store bar font info.

        staa    bars+0,y
        staa    bars+1,y

bar_done:
        rts


;And thin bars for the 8-channel SUB-L and SUB-R:
do_thin_bar:
        cmpa    #17                    ;Maximum bar height + 1.
        bls     thin_height_ok

        ldaa    #16                    ;Maximum bar height.
thin_height_ok:
        adda    #$30                   ;Convert height to ASCII
        cmpa    #$30
        beq     thin_bar_done          ;If height = 0, return.

        cmpa    #$38                   ;VFD lower bar is 1 to 8 ($31 to $38).
        bls     thin_lower_part        ;Check for <= 9

thin_upper_part:
        suba    #8                     ;VFD upper bar is 1 to 8 ($31 to $38).
        tsy
        iny
        iny
        aby

        staa    bars+0,y               ;Store bar height info...

        pshb
        ldab    #41
        aby
        ldaa    #'='                   ;Store bar font info...

        staa    bars+0,y

        pulb                           ;Restore bar position info.
        ldaa    #$38                   ;Fill in bottom part of tall bar.
thin_lower_part:
        psha
        ldaa    three_secs             ;Check if in first two secs
        pula
        bne     thin_bar_done          ; if so, no lower line

        cmpa    #$39
        bne     thin_less

thin_less:
        addb    #20                    ;Move to lower part of screen
        tsy
        iny
        iny
        aby

        staa    bars+0,y               ;Store bar height info.

        ldab    #41
        aby
        ldaa    #'='                   ;Store bar font info.

        staa    bars+0,y

thin_bar_done:
        rts


;***********************************************************************
;* Display bars (also 'Mute' string if necessary)
;***********************************************************************
put_out_bars:
        brclr   mute_status,#1,.not_in_mute   ;Check for user mute

        tsy
        ldaa    #$20
        staa    7,y                    ;Space each side of mute label.
        staa    12,y
        staa    48,y                   ;Standard font for mute label.
        staa    49,y
        staa    50,y
        staa    51,y
        staa    52,y
        staa    53,y

        ldaa    #'M'                   ;Put in a mute label
        staa    8,y
        ldaa    #'u'
        staa    9,y
        ldaa    #'t'
        staa    10,y
        ldaa    #'e'
        staa    11,y

.not_in_mute:
        tsy
        clra
        jsr     SCREENS                ;Put out entire screen

        tsx
        xgdx
        addd    #81                    ;Restore stack
        xgdx
        txs
        rts                        ;***Return***


;******************************************************************************
;*
;* Display of Special 'No VU Meter' Display for Analog Pass-thru.
;*
;***
Bar_None_Display:
;* Local variables on the stack:

nobars: equ     0    ;Full screen of bars, arranged as
                      ; 40 characters, |, then 40 font specifier characters.
        tsx
        xgdx
        subd    #81                    ;Reserve stack space for bars screen.
        xgdx
        txs                            ;x points to local variables

        ldab    #81                    ;Clear bar graph storage area
        ldaa    #' ' 
        tsy          
.nbar_loop2:
        staa    0,y
        iny
        decb
        bne     .nbar_loop2

        tsy
        ldaa    #'|'                   ;String delimiter
        staa    bars+40,y

        ldd     #'xx'                  ;Build "xx" bars in std font.
        std     20,y
        std     23,y
        std     26,y
        std     29,y
        std     32,y
        std     35,y
        std     38,y
        ldaa    #' '
        staa    22,y
        staa    25,y
        staa    28,y
        staa    31,y
        staa    34,y
        staa    37,y

        brclr   mute_status,#1,.not_in_mute2  ;Check for user mute

        ldd     #'Mu'                  ;Put in a mute label
        std     8,y
        ldd     #'te'
        std     10,y

.not_in_mute2:
        tsy
        clra
        jsr     SCREENS                ;Put out entire screen

        tsx
        xgdx
        addd    #81                    ;Restore stack
        xgdx
        txs
        rts                        ;***Return***


;------------------------------
;%%% Although the following code is scads simpler than the above,
;%%% it does not suffer from the problem of a flickering "Mute",
;%%% which occurs when updating a small part of the display repetitively.
;        ldy     #No_VU
;        clra
;        jsr     SCREENS
;        brclr   mute_status,#1,.not_in_mute2    ;Check for user mute
;
;        ldy     #Mute_strg
;        ldaa    #8
;        jsr     SCREENS
;
;.not_in_mute2:
;        rts                        ;***Return***
;
;Requires these strings to be defined in Screens.i:
;Mute_strg:
;        dc.b     ' Mute |'    ;Used by the Anlg Pass-thru 'No VU meter' screen.
;        dc.b     '      '
;
;No_VU: 
;        dc.b     '                    xx xx xx xx xx xx xx|' ;Direct analog pass-thru mode.
;        dc.b     '                                        '  ;Has space reserved for "Mute" on top line.
;                                                             ;Displayed in place of VU meter.



;********************************************************************
;* SPL meter
;* Upon entry, A holds a number 0-60.
;* This routine puts up a its horizontal bar graph
;* and a corresponding dB number (in ...)
;*
;***
SPL_display:
        tsx          
        xgdx
        subd    #8
        xgdx
        txs

;%% Local variables on the stack:

SP_level_temp:  equ     0               ;1 byte
SPL_posn:       equ     1               ;1 byte
SPL_make_up:    equ     2               ;1 byte
SPL_num:        equ     3               ;5 bytes

        inca
        inca
        cmpa    #60                     ;Look for overflow
        bls     spl_ok

        ldaa    #60
spl_ok:
        staa    SP_level_temp,x         ;Save new value


        ldaa    SP_level_temp,x
        ldaa    #20
        staa    SPL_posn,x              ;Start at RHS
spl_loop:
        ldaa    SP_level_temp,x
        beq     last_spl_bar0           ;Check for partial bars

        cmpa    #1
        beq     last_spl_bar1

        cmpa    #2
        beq     last_spl_bar2

full_spl_bar:
        ldaa    SPL_posn,x
        ldy     #full_horiz_bar         ;Show full character
        jsr     SCREENS

next_spl_bar:
        inc     SPL_posn,x              ;Update position
        dec     SP_level_temp,x         ;Subtract 3 from level
        dec     SP_level_temp,x
        dec     SP_level_temp,x
        bra     spl_loop                ;Loop again


last_spl_bar0:
        ldy     #spaces
        bra     last_spl_bar

last_spl_bar1:
        ldy     #left_horiz_bar1        ;Show 1 strip
        bra     last_spl_bar

last_spl_bar2:
        ldy     #left_horiz_bar2        ;Show 2 strips


last_spl_bar:
        ldaa    SPL_posn,x
        jsr     SCREENS
        
        ldaa    SPL_posn,x              ;Clear RH part
        inca
        cmpa    #40
        bhs     spl_bar_end

        ldab    #40
        jsr     Section_clear


spl_bar_end:
        ldd     SPL_buf
        addd    #$3030                  ;Convert first two digits to ASCII.
        std     SPL_num,x
        ldaa    #'|'
        staa    SPL_num+2,x
        ldd     #'  '                   ;$2020
        std     SPL_num+3,x
        tsy
        ldab    #SPL_num
        aby
        ldaa    #13
        jsr     SCREENS

        ldaa    SPL_buf+2               ;Last digit
        adda    #$30
        staa    SPL_num,x               ;Convert to ASCII
        ldaa    #'|'
        staa    SPL_num+1,x
        ldaa    #' '                    ;$20
        staa    SPL_num+2,x
        tsy
        ldab    #SPL_num
        aby
        ldaa    #16
        jsr     SCREENS

        tsx                       ;Deallocate local variables stack space.
        xgdx
        addd    #8
        xgdx
        txs
        rts


;************************************************************************
;*
;* Display of Big Numbers.
;*
;* This routine converts the overall binary volume to 3 decimal digits
;* XX.Y dB in dbufr, and displays the big nums corresponding to this volume.
;*
;***
Big_Numbers:

;%% Local variables on the stack:

numtop:          equ     0              ;5 characters of top row
numbot:          equ     5              ;5 characters of bottom row
point:           equ     10             ;3 characters for fractional dB

        tsx
        xgdx
        subd    #17                     ;Reserve stack space
        xgdx
        txs                             ;X points to local variables

        jsr     compose_volume          ;Get overall volume level
        ldx     #vol_overall
        jsr     vtodB                   ;Convert to dB (in dbufr)
        
        ldaa    noise_in_proc
        adda    static_in_proc
        beq     bnum_1                  ;If not in noise modes, go on
        
big_nums_mic:                           ;If in noise modes, check if mic in
        ldx     #regbase
        brset   porte,x,#%00000010,big_nums_clr  ;Clear screen if mic in

bnum_1:
        ldaa    flash_up
        bne     big_nums_clr            ;Clear screen if we are flashing up something

        ldy     #screen_image
        ldd     7,y
        cpd     #'de'                   ;Check for dts dedication screen
        beq     big_nums_clr            ;If so, clear screen

        cpd     #' d'                   ;Check for MPEG dedication screen
        beq     big_nums_clr            ;If so, clear screen

        ldaa    screen_status1
        bne     big_nums_no_clr         ;If already counting, do not clear screen

big_nums_clr:
        jsr     LCD_init
        clr     flash_up
       
big_nums_no_clr:
        tsx

;** Characters  **

        ldaa    #'A'
        staa    numtop+0,x              ;Upper left character
        ldaa    #'B'
        staa    numtop+1,x              ;Upper right character
        ldaa    #'C'
        staa    numbot+0,x              ;Lower left character
        ldaa    #'D'
        staa    numbot+1,x              ;Lower right character
        ldaa    #$20
        staa    point+2,x               ;Fractional dB (normal font)

        ldaa    #'|'
        staa    numtop+2,x
        staa    numbot+2,x              ;String delimiters
        staa    point+1,x

        ldd     dbufr
        bne     do_neg_sign

        ldaa    dbufr+2
        bne     do_neg_sign             ;If non-zero, show negative sign
        bra     do_dot

do_neg_sign:
        ldaa    #5
        ldy     #neg_dB                 ;Display negative sign
        jsr     SCREENS

do_dot:
        ldaa    #14

        ldy     #dB                     ;Display "dB"
        jsr     SCREENS

        ldaa    #11
        ldy     #dot_dB                 ;Display decimal point
        jsr     SCREENS

        ldab    dbufr+2
        addb    #$30                    ;Convert to ASCII
        stab    point,x
        ldaa    #12
       
        ldab    #point
        tsy                             ;Get stack pointer in y
        aby                             ;Update to right place
        jsr     SCREENS

        ldab    dbufr                   ;First number
        ldaa    #7
        jsr     disp_num
        ldab    dbufr+1                 ;Second number
        ldaa    #9
        jsr     disp_num

big_nums_end:
        ldaa    #1
        staa    screen_status1          ;Start big nums timer

big_nums_restore:
        tsx
        xgdx
        addd    #17                     ;Restore stack
        xgdx
        txs

        rts
        

;** Number display routine:
;** B contains number to be output as a 2x2 big num
;** A contains position of top left of 2x2 big num

disp_num:
        
        addb    #$30                    ;Convert to ASCII (gives font)
        stab    numtop+3,x              ;Store font
        stab    numtop+4,x
        stab    numbot+3,x
        stab    numbot+4,x

        ldab    #numtop
        tsy                             ;Get stack pointer in y
        aby
        iny
        iny
        psha                            ;Update to right place
        jsr     SCREENS

        pula
        adda    #20
        ldab    #numbot
        tsy                             ;Get stack pointer in y
        aby
        iny
        iny                             ;Update to right place
        jsr     SCREENS

        rts


;*********************************************************************
;*
;* Display Small Volume
;*
;* Upon entry, dbufr contains 3 decimal numbers representing the
;* overall volume as XX.Y dB. This routine ignores the fractional dB
;* value and displays XX dB in the volume field.
;*
;***
Small_Volume:

        tsx
        xgdx
        subd    #5                      ;Reserve stack space
        xgdx
        txs                             ;x points to local variables

        jsr     compose_volume          ;Get overall volume level
        ldx     #vol_overall
        jsr     vtodB                   ;Convert to dB (in dbufr)
        tsx

        ldd     dbufr                   ;Display leading '-' (or ' ' if zero dB).
        bne     disp_neg

        ldy     #spaces
        bra     disp_neg_dB

disp_neg:
        ldy     #neg_dB2
disp_neg_dB:
        ldaa    #34
        jsr     SCREENS

        ldy     #dB                     ;Display 'dB'
        ldaa    #38
        jsr     SCREENS

        ldd     dbufr                   ;Get integer part of dB volume &
        addd    #$3030                  ; convert to decimal ASCII.      
;** Construct string:
        cmpa    #$30                    ;Check for 0-9 dB volume
        bne     non_zero_vol

        ldaa    #$20                    ;Insert space for single digit dB
non_zero_vol:                           
        staa    0,x                     ;Numbers                  
        stab    1,x                     
        ldaa    #'|'                    ;String delimiter
        staa    2,x
        ldaa    #' '                    ;$20
        staa    3,x                     ;Fonts
        staa    4,x

        tsy
        ldaa    #35
        jsr     SCREENS

        ldy     #blink_posns
        ldaa    vc_cmp_flags            ;Check if anything compressed
        beq     sm_vol_no_blinks        ;If not, flush blinking

        ldaa    #34
        staa    0,y
        ldaa    #36
        staa    1,y
        bra     sm_vol_blinks

sm_vol_no_blinks:                       ;Flush blinking
        ldaa    #$ff
        staa    0,y
        staa    1,y

sm_vol_blinks:
        jsr     start_blinking          ;Set up blinking

sm_vol_end:
        tsx
        xgdx
        addd    #5                      ;Restore stack
        xgdx
        txs

        rts


;*********************************************************************
;*
;*                INITIALIZE THE CS4226 DIGITAL RECEIVER
;*                ====             ====
;*
;*                
;* We assume that there has been few ms delay between +5VD power
;*  coming up and LVI de-asserting 68HC11 !RESET and 4226 !DPD.
;*  !DPD should have been be asserted for at least 1 ms.
;*
;* RTI must be disabled/enabled outside of this routine unless
;*  it is being used from within the RTI service routine.
;*
;* Note that RTI interrupts are turned off and not turned on again...
;* this is to allow further initiation after this for proper functioning.
;*
;***
init_4226_xtal:
        ldx     #regbase
        ldaa    #3                     ;Write chip address $20
        staa    write_reg_lst
        ldaa    #$20
        staa    write_reg_lst+1
        ldy     #xtal_regs
        bra     .init_4226

init_4226_pll:
        ldx     #regbase
        ldaa    #3                     ;Write chip address $20
        staa    write_reg_lst
        ldaa    #$20
        staa    write_reg_lst+1
        ldy     #init_regs

.init_4226:
        rtint   OFF
        jsr     spi_cmd_4226
        delay   20*10                  ;20 ms 

;%% Set RS bit to 0 to initiate normal operation
        ldaa    #2                     ;Select converter control (2)
        ldab    #0                     ;Set to $00
        staa    write_reg_lst+2        ;Set MAP
        stab    write_reg_lst+3        ;Set data to be written
        ldy     #write_reg_lst
        jsr     spi_cmd_4226           ;Send write command to 4226

        rts                ;** Return **


;***************************************************************************
;*
;*      P A S S - T H R O U G H  M O D E S
;*
;*
;***
digital_8_mode:
        ldaa    #0
        staa    curr_pass_mode       
        bclr    DAC8_imag2,#%10001000   ;Aux=0, Anlg_pass=0.
        jsr     update_DAC8_latch2
        rts

passthru_6_mode:
        ldaa    #1
        staa    curr_pass_mode       
        bclr    DAC8_imag2,#%10000000
        bset    DAC8_imag2,#%00001000   ;Aux=0, Anlg_pass=1.
        jsr     update_DAC8_latch2
        rts

passthru_2_mode:
        ldaa    #2
        staa    curr_pass_mode       
        bset    DAC8_imag2,#%10001000   ;Aux=1, Anlg_pass=1.
        jsr     update_DAC8_latch2
        rts

passthru_8_mode:
        ldaa    #3
        staa    curr_pass_mode       
        bclr    DAC8_imag2,#%10000000
        bset    DAC8_imag2,#%00001000   ;Aux=0, Anlg_pass=1.
        jsr     update_DAC8_latch2
        rts


;*****************************************************************************
;*
;*      W R I T E    V O L U M E    D A T A    T O    T H E    C S 3 3 1 0 s
;*      = =                                                    = = = = = = =
;*
;* Write volume data in CS3310_vol_imag to the CS3310s via DAC8_latch1.
;* The volume image data is preserved.
;*
;* Eight 8-bit volume values are loaded msb first, R-ch. before L-ch.
;* RF channel is loaded first, CT last.
;*
;* This routine is called after vol_buf_fixup has re-arranged the
;*  buffer contents according to speaker config & various other modes.
;*
;* CS3310_vol_imag:
;*      RF, LF, RS, LS, ES, SL, SR, CT
;*      0   1   2   3   4   5   6   7
;*
;* Preserves a, y registers.
;*
;***
bit_count:      equ     0              ;(also used by WR_PCM1732)
byte_count:     equ     1              ;(also used by WR_PCM1732)

WR_CS3310s:
        psha
        pshy
        des
        des                            ;Allocate 2 local variables on stack.
        tsx                            ;Make x reg point to locals.
        
        ldaa    #8                     ;# bits per byte = 8
        staa    bit_count,x            ;# bytes  to load = 8 
        staa    byte_count,x           ;Init. local vbls.

        bclr    DAC8_imag1,#%00000010  ;Get serial clock ready (sclk=0).
        jsr     update_DAC8_latch1
        nop

        bclr    DAC8_imag1,#%00000100  ;Enable CS3310 serial control (*cs=0).
        jsr     update_DAC8_latch1
        nop

        ldy     #CS3310_vol_imag

CS3310vloop:
        rol     0,y                    ;Get msb into carry.
        bcc     send0

send1:  bset    DAC8_imag1,#%00000001  ;Setup for a 1.
        bra     sendOK

send0:  bclr    DAC8_imag1,#%00000001  ;Setup for a 0.
sendOK: jsr     update_DAC8_latch1     ;Send 1 or 0.
        nop
        nop
        nop
        nop
        nop
        bset    DAC8_imag1,#%00000010  ;Generate a rising
        jsr     update_DAC8_latch1     ; clock edge...
        nop                            ;    /
        nop
        bclr    DAC8_imag1,#%00000010  ;Bring clock back to 0
        jsr     update_DAC8_latch1     ;    /

        dec     bit_count,x
        bne     CS3310vloop

        rol     0,y                    ;9th shift preserves the vol. buffer.
        iny                            ;Next channel.
        ldaa    #8
        staa    bit_count,x
        dec     byte_count,x
        bne     CS3310vloop

        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop

        bset    DAC8_imag1,#%00000100  ;Disable CS3310 serial control (*cs=1)
        jsr     update_DAC8_latch1

        ins
        ins                            ;Deallocate two local vbls from stack. 
        puly
        pula
        rts                    ;** Return **


;***************************************************************************
;*
;*      W R I T E    D A T A    T O    T H E    P C M 1 7 3 2 U s
;*      = =                                     = = = = = = =
;*
;* The PCM1732's 16-bit control words are loaded msb first.
;* The 16-bit value to be loaded is in D on entry.
;* Execution time = .93 ms
;*
;***
;bit_count:      equ     0              ;(defined above)
data_word:      equ     1

WR_PCM1732:
        des                            ;Allocate 2 local variables on stack.
        des
        des
        tsx                            ;Make X reg point to locals.

        std     data_word,x            ;Save data to be loaded.

        ldaa    #16                    ;# bits to load = 16
        staa    bit_count,x

        bset    DAC8_imag2,#%00000100  ;Set ML to correct resting value.
        jsr     update_DAC8_latch2

        bclr    DAC8_imag2,#%00000010  ;Set MC to correct resting value.
        jsr     update_DAC8_latch2

PCM1732loop:
        rol     data_word+1,x
        rol     data_word,x            ;Get msb of data into carry.
        bcc     tx_0

tx_1:   bset    DAC8_imag2,#%00000001  ;Setup for sending a 1.
        bra     tx_OK

tx_0:   bclr    DAC8_imag2,#%00000001  ;Setup for sending a 0.
tx_OK:  jsr     update_DAC8_latch2     ;Send 1 or 0.
        nop
        nop
        nop
        bset    DAC8_imag2,#%00000010  ;Generate a rising
        jsr     update_DAC8_latch2     ; clock edge...
        nop                            ;    /
        nop                            ;    /
        nop                            ;    /
        bclr    DAC8_imag2,#%00000010  ;    /
        jsr     update_DAC8_latch2     ;Bring clock back to 0.

        dec     bit_count,x
        bne     PCM1732loop

        bclr    DAC8_imag2,#%00000100  ;Generate a positive
        jsr     update_DAC8_latch2     ;    /
        nop                            ;    /
        nop                            ;    /
        nop                            ;    /
        bset    DAC8_imag2,#%00000100  ;    /
        jsr     update_DAC8_latch2     ; edge on ML to load data.

        ins                            ;Deallocate 2 local vbls from stack.
        ins
        ins
        rts                    ;** Return **


;*****************************************************************
;*
;*      W R I T E    D A T A    T O    T H E    C S 4 2 2 6
;*      = =                                     = = = = = =
;*
;* Write single 4226 register
;* Register MAP must be in A register.
;* Data to be written must be in B register.
;*
;* RTI must be disabled/enabled outside of this routine.
;* This is not necessary if it is being called from within
;* the RTI service routine.
;*
;***
WR_CS4226:
        ldx     #regbase
        staa    write_reg_lst+2        ;Set MAP
        stab    write_reg_lst+3        ;Set data to be written
        ldy     #write_reg_lst
        rtint   OFF
        jsr     spi_cmd_4226           ;Send write command to 4226
        rtint   ON
        rts                    ;** Return **


;*****************************************************************
;*
;*     R E A D    D A T A    F R O M    T H E    C S 4 2 2 6
;*     =     =                                   = = = = = =
;*
;* Read single 4226 register
;* Register MAP must be in the A register.
;* Data is returned in the A register.
;*
;* RTI must be disabled/enabled outside of this routine.
;* This is not necessary if it is being called from within
;* the RTI service routine.
;*
;***
RD_CS4226:
        ldx     #regbase
        staa    read_reg_a_lst+2
        ldaa    #2
        staa    read_reg_a_lst
        ldaa    #$20
        staa    read_reg_a_lst+1
        ldy     #read_reg_a_lst
        rtint   OFF
        jsr     spi_cmd_4226           ;Do partial write cycle

        ldy     #read_stat_1
        jsr     spi_cmd_4226           ;Read 1 register

        ldaa    ret_inf+1              ;Extract data from return buffer     
        rtint   ON
        rts                    ;** Return **


;*****************************************************************
;*
;*      W R I T E    D A T A    T O    Z O R A N    1
;*      = =                            =            =
;*
;***
WR_Z1:  pshx
        rtint   OFF                    ;RTI off \\\\
        jsr     spi_cmd_1              ;Send command string to Z1.
        rtint   ON                     ;RTI on  ////
        pulx
        rts                        ;** Return **


;*****************************************************************
;*
;*      W R I T E    D A T A    T O    Z O R A N    2
;*      = =                            =            =
;*
;***
WR_Z2:  pshx
        rtint   OFF                    ;RTI off \\\\
        jsr     spi_cmd_2              ;Send command string to Z2.
        rtint   ON                     ;RTI on  ////
        pulx
        rts                        ;** Return **

;*****************************************************************
;*
;*      W R I T E    D A T A    T O    MOTOROLA DSP 56009
;*      = =                            =             
;*
;***
WR_M1:  pshx
        rtint   OFF                    ;RTI off \\\\
        jsr     spi_cmd_M1             ;Send command string to Motorola
        rtint   ON                     ;RTI on  ////
        pulx
        rts                        ;** Return **

;*******************************************************************
;*
;* Resets Z1 and Z2, configures PLLs and serial ports.
;*
;* This routine is also able to install any necessary program patches
;* and handler lookup table updates.
;*
;* Note: /RESET may have already been asserted,  for example by the
;*       initial configuration code that executes after 68HC11F1
;*       power-on reset.
;*
;* Also resets MC56009 DTS decoder (if present).
;*
;*** 
reset_38:
        ldx     #regbase
        bclr    porta,x,#%00000010      ;Assert (or reassert) Z1,2 and M1 /RESET pins
        delay   5*10                    ;Wait long enough (5 ms), and then
        bset    porta,x,#%00000010      ; release to start DSPs...

        delay   180*10                  ;Give ZR38001 time to boot from EPROM...
                                        ; (take into account code size and Zoran clock speed).

        ldy     #plltab_cmd1
        jsr     WR_Z1                   ;Specify Z1 clocks
        delay   20*10                   ;20 ms

        ldy     #pllcfg_cmd1
        jsr     WR_Z1                   ;Set Z1 clocks
        delay   1*10                    ;At least 50us delay

        ldy     #cfg_cmd1
        jsr     WR_Z1                   ;Set Z1 ports
        delay   20*10                   ;20 ms

        jsr     check_for_Z1_eprom      ;Check and invoke init if
                                        ; Z1 EPROM present.
        ldy     #mute_cmd
        jsr     WR_Z1    

        ldy     #plltab_cmd2
        jsr     WR_Z2                   ;Specify Z2 clocks
        delay   20*10                   ;20 ms

        ldy     #pllcfg_cmd2
        jsr     WR_Z2                   ;Set Z2 clocks
        delay   1*10                    ;At least 50us delay

        ldy     #cfg_cmd2
        jsr     WR_Z2                   ;Set Z2 ports
        delay   20*10

        ldy     #invoke_init_cmd2
        jsr     WR_Z2    

        ldy     #mute_cmd            
        jsr     WR_Z2

        ldy     #feedthru_cmd2_Ref      ;Put Z2 into 6 channel feed through
        jsr     WR_Z2                   ;so that it is happy upon cold start
                                        ;**** Z2 must be put into some mode
                                        ;**** to give correct peek info!!!
                                        ;**** (tell Andres!)
        delay   100*10

        ldy     #cntrl_5.1 
        jsr     WR_M1                   ;Initialize DTS board

        rts

;** Check if Z1 EPROM present. If so, boot up EPROM
;       If an EPROM with proper boot package format is present in Z1
;       EPROM socket, custom code is automatically loaded into Z1 program
;       RAM at reset (done by now). We will check a PRAM location for a 
;       known instruction and if it is found, we will invoke an 
;       initialization program that replaces the standard AC-3 interrupt
;       handler with a professional-AC-3-capable EAD custom handler.

check_for_Z1_eprom:
        ldy     #peek_for_Z1E           ;Peek a PRAM location in Z1
        jsr     WR_Z1                   ;to see if custom handler is loaded
                                        ;(looking for 0x380d0203 at 0xd0201)

        ldy     #ret_inf
        ldd     10,y                    ;First half of instruction
        cpd     #$380d
        bne     Z1_init_end             ;If doesn't match, don't invoke

        ldd     12,y                    ;Second half
        cpd     #$0203
        bne     Z1_init_end             ;If doesn't match, don't invoke

do_Z1_init:                             ;EPROM present, so invoke AC-3 patch
        ldy     #invoke_init_cmd1
        jsr     WR_Z1    
Z1_init_end:
        rts

        
;*********************************************************************
;*
;* Sends SPI command to one of the 4 slaves.
;*
;* Z1 and Z2 format consists of sequence of 8-bit frames, so _SS assertion
;* can be arbitrary. On the other hand, 4226 and M1 format is a sequence
;* of 8-bit groups within a single _SS assertion. Thus we assert _SS at
;* the beginning of sequence and record response to each byte.
;*
;* This routine has several entry points to activate different SPI slaves.
;* It reads command length and decides whether response will be saved or not
;* (some commands might need too long a buffer). Then sends commmand bytes,
;* followed by 3 READs. 
;*
;* Note: Protection against interrupts that use SPI is expected to be
;*       at a higher level.
;*
;* Note: .spi_cmd is NOT an entry point!!!
;*
;***
spi_cmd_1:
        ldx     #regbase
        bclr    spcr,x,#%00001000      ;Set SCLK to latch on falling edge
        bset    spcr,x,#%00000100      ;CPHA=1

        bclr    portg,x,#%00000010     ;Assert _SS for Z1
        bra     .spi_cmd

spi_cmd_2:
        ldx     #regbase
        bclr    spcr,x,#%00001000      ;Set SCLK to latch on falling edge
        bset    spcr,x,#%00000100      ;CPHA=1

        bclr    portg,x,#%00000100     ;Assert _SS for Z2
        bra     .spi_cmd

spi_cmd_4226:
        ldx     #regbase
        bset    spcr,x,#%00001000      ;Set SCLK to latch on rising edge
        bset    spcr,x,#%00000100      ;CPHA=1

        bclr    portg,x,#%00000001     ;Assert _SS for 4226
        bra     .spi_cmd

spi_cmd_M1:
        ldx     #regbase
        bset    spcr,x,#%00001000      ;CPOL=1 , CPHA=0 
        bclr    spcr,x,#%00000100

        bclr    portg,x,#%00001000     ;Assert _SS for M1

.spi_cmd:
        ldx     #regbase
;        bclr    portd,x,#%00100000     ;Assert generic _SS for debugging
        ldd     #ret_inf               ;Point to beginning of return info buffer.
	std     ret_ptr
        bset    record_rx,#$ff         ;Assume a short command with response.
        ldab    0,y                    ;Get number of bytes transmitted for this command
        cmpb    #43                    ;Is it a short command? (Previous value, for 6-ch's, was 35)
        bls     .tx_byte               ;If so, jump and do it.

        clr     record_rx              ;Else don't record response (might need a long buffer)
.tx_byte:        
        iny                            ;Point to next byte in code table.
        tstb                           ;Anything more to transmit?
        beq     get_istatus            ;If not, get command interpreter status...
	
        ldaa    0,y                    ;Get byte to transmit
        jsr     to_spislave            ;Send to slave.
        decb                           ;Decrement counter
        bra     .tx_byte               ;Go to handle next byte

get_istatus:
        ldx     #regbase
        brset   portg,x,#%00000110,spi_done
                                       ;If Z1 or Z2 _SS not asserted, skip response check
        clra                           ;Else issue a few READ commands (all zeros)
        jsr     to_spislave
	clra
        jsr     to_spislave
	clra
        jsr     to_spislave            ;Issue three READ commands and get ISTATUS info

spi_done:
        ldx     #regbase
        bset    portg,x,#%00001111     ;Deassert all_*SS
;        bset    portd,x,#%00100000     ; including the debug one.
        rts                        ;** Return **
        

;******************************************************************
;*
;* Subroutine for sending byte in A to SPI and returning response in A
;*
;* X must be set to REGBASE 
;*
;***
to_spislave:
        pshb                           ;B contains SPI command byte counter
        staa    spdr,x                 ;Send byte out to SPI
        brclr   spsr,x,#%10000000,*     ;Wait if SPI is busy...
        ldaa    spdr,x                 ;Unload byte from SPI
	
        brclr   record_rx,#$ff,ztx_done ;If long command, don't record

        pshy                           ;Save input list location
        ldy     ret_ptr                ;Get current return info location
        staa    0,y                    ;Write returned code
        iny                            ;Advance 1 byte
        sty     ret_ptr                ;Store return info location for next time
        puly                           ;Restore input list

ztx_done:
        delay   5

        pulb                           ;Restore byte counter
        rts                        ;** Return **


;***********************************************************************
;*
;* INITIALIZE THE 4 PCM1732 DIGITAL FILTER/DACs               
;* ====           = ===                       =
;*
;***
init_4PCMs:
;        ldd     #MODE0
;        jsr     WR_PCM1732

;        ldd     #MODE1
;        jsr     WR_PCM1732

        ldd     #MODE2
        jsr     WR_PCM1732

        ldd     #MODE3
        jsr     WR_PCM1732
        rts


;***************************************************************
;* Initialization of volume variables
;* (called out of reset)
;***************************************************************
volume_initials:
        clr     vc_min_flags
        clr     vc_cmp_flags
        clr     vc_max_flags
        clr     enc_vol_slow

clear_corrs:
        clr     mat_flag                ;!!
        ldd     #$0000
        std     dialog_corr
        std     HDCD_corr
        std     matrix_corr             ;!!
        std     prol_corr
        std     sub_bs_corr
        std     lr_bs_corr
        jsr     update_corr             ;Set up cor_ variables

        rts


;**************************************************************************
;*
;*              V O L U M E   C O N T R O L   U P  /  D O W N
;*
;* Channel flags lookup table for checking min/max volume condition
;*  in variables vc_min_flags and vc_max_flags

ch_flags:
all_f:          dc.b     %00111111   ;id=0    All channel flags
l_f:            dc.b     %00000001      ;1    L channel flag
r_f:            dc.b     %00000010      ;2    R channel flag
ls_f:           dc.b     %00000100      ;3    LS channel flag
rs_f:           dc.b     %00001000      ;4    RS channel flag
c_f:            dc.b     %00010000      ;5    C channel flag
sub_f:          dc.b     %00100000      ;6    SUB channel flag
lr_f:           dc.b     %00000011
lsrs_f:         dc.b     %00001100


;*****************************************************************
;*
;* MANAGEMENT OF INCREASE VOLUME.
;*
;***
vol_up:
;        jsr     slow_down_vol           ;Slow down Encore volume.
;        tsta
;        bne     .vu_done

        clr     noise_seq_timer         ;Refresh noise seq. timer just in case
        ldaa    curr_chs                ;Get current channel flag(s)
        tsta                            ;If some channels selected, 
        bne     st_flags_up             ;set mask

        ldaa    #%00111111              ;Else set all channel flags
st_flags_up:
        staa    this_mask               ;Store flag mask for current channel(s)

        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Adj       ;Check if in Speaker Adjust screen
        beq     adj_checks              ;If so, do detailed checks

upp2:   ldaa    vc_max_flags            ;If not, check for limit set by LR
        anda    #%00000011              ;Get LR channel max info
        bne     .vu_done                ;If either max'ed out, do nothing

upp: 	ldd     #-1
        std     att_chng                ;Set step for decreasing attenuation
        jsr     vol_step                ;Go do vol up...
.vu_done:
        jmp     update_scrn_vol         ;Display volume changes

adj_checks:
        ldaa    curr_chs
        beq     upp2                    ;If no channels selected do as normal
                                        ;If some channels selected,
        anda    vc_max_flags            ; and some of them are maxed out,
        bne     .vu_done                ; do nothing to prevent compression.
        bra     upp                     ;If no selected channels are maxed
                                        ; out, go on as normal


;*****************************************************************
;*
;* MANAGEMENT OF DECREASE VOLUME.
;*
;***
vol_dn:
;        jsr     slow_down_vol           ;Slow down Encore volume.
;        tsta
;        bne     .vd_done

        clr     noise_seq_timer         ;Refresh noise seq. timer just in case
        ldaa    curr_chs                ;Get current channel flag(s)
        tsta                            ;If some channels selected, 
        bne     st_flags_dn             ;set mask

        ldaa    #%00111111
st_flags_dn:
        staa    this_mask               ;Store flag mask for current channel(s)

chk_vdn2:
        anda    vc_min_flags            ;See if any relevant vol min flag is set
        bne     .vd_done                ;If so, can't do vol down

	ldd     #1
        std     att_chng                ;Set step for increasing attenuation
        jsr     vol_step                ;Go do vol down...
.vd_done:
        jmp     update_scrn_vol         ;Display changes


;******************************************************************
;* Slowing down volume ramp
;*
;* >>>Later: Accelerate the rate the longer the key is pressed.
;*
;***
;slow_down_vol:
;
;        ldaa    enc_vol_slow
;        beq     do_enc_vol              ;If first time through, all ok!
;
;        inc     enc_vol_slow            ;Number of times increases
;        clr     slow_enc_timer          ;Refresh time out
;        ldaa    enc_vol_slow
;        cmpa    #4                      ;Check for 4 times through
;        bls     do_not_enc_vol
;
;        clr     enc_vol_slow            ;Next time will be okay
;do_not_enc_vol:
;        ldaa    #$ff                    ;Flag error
;        rts
;
;do_enc_vol:
;        ldaa    #1
;        staa    enc_vol_slow            ;Flag that we have just done the volume
;        clr     slow_enc_timer          ;Start timer
;        clra                            ;Flag all ok!
;        rts


;******************************************************************
;* Display of Volume (depending on which screen we are in)
;***
update_scrn_vol:

        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Adj       ;Check if in Speaker Adjustment screen
        bne     scrn_vol_bigs           ;If not, do Big Nums

;At this point we are in Spkr adj, Noise Seq or Static noise...
        ldaa    static_in_proc          ;Check if in Static Noise mode
        bne     update_v_static

        ldaa    screen_status2          ;Adj. or Noise Seq and in mode screen
        bne     scrn_vol_end            ;If so, do not show changes

        ldaa    noise_in_proc           ;Noise Seq? 
        bne     update_v_noise

update_v_1:                             ;Adjustment screen
        ldaa    curr_chs
        beq     scrn_vol_bigs           ;If no speakers selected, do Big Nums
        jmp     display31               ;Else if some selected, show individual vols

scrn_vol_bigs:
        jmp     Big_Numbers             ;Show Big Nums

scrn_vol_end:
        rts

update_v_noise:                                     
        ldx     #regbase                ;If mic is out, treat as Adjustment screen
        brclr   porte,x,#%00000010,update_v_1
        rts                             ;If mic in, no show

update_v_static:
        ldy     #screen_image
        ldd     4,y
        cpd     #'St'                   ;If Static Noise mode screen,
        beq     scrn_vol_end            ;no update

        ldx     #regbase                ;If mic is out, treat as Adj screen
        brclr   porte,x,#%00000010,update_v_1

        ldaa    screen_status2          ;Check if vols flashing up
        beq     scrn_vol_end            ;If not, do nothing

        ldaa    #1                      ;Otherwise refresh flash timer
        staa    screen_status2
        jmp     update_v_1              ;Then treat as adj. screen


;*****************************************************************
;* vol_step:
;*
;* Changes all vcp's selected in "this_mask" by an amount in "att_chng"
;* then goes to unpack_vol
;*
;***
vol_step:
	ldaa    #%00000001
        staa    this_flag       ;Min and max volume flag mask for ch. 1
	ldy     #vcp_l          ;Point to atten. counter

nx1_up: ldaa    this_mask       ;Look at all channels that must be adjusted under current cuur_ch
	anda    this_flag       ;Pick out one that would be done during this loop step
        beq     nx2_up          ;If does not match, skip adjust

do_up:  ldd     0,y             ;Get 16-bit attenuation (vcp)
        addd    att_chng        ;Add in the change  
        std     0,y             ;Store new dig. atten. value (vcp)
nx2_up: iny
	iny                     ;Advance to next attenuation counter
	lsl     this_flag       ;Move flag mask left for next channel
	cpy     #vcp_sub        ;All done?
        ble     nx1_up          ;If not, do next...

        jsr     unpack_vol      ;Compute composite volumes and set them.

vs_done:
        rts                 ;** Return **
        

;*******************************************************************
;* Set separate volumes using [F][n][n] in Speaker Adjusment screen.
;*
;***
set_sep_vol:
	ldaa    #%00000001
        staa    this_flag       ;Start with ch. 1
	ldy     #vcp_l          ;Point to atten. counter
nx1_adj: 
        ldaa    curr_chs        ;Look at all channels that must be adjusted under current curr_chs
	anda    this_flag       ;Pick out one that would be done during this loop step
        beq     nx2_adj         ;If does not match, keep current volume

do_adj: ldd     vc_count        ;Get desired volume
        std     0,y             ;Set volume for this channel
nx2_adj:
	iny
	iny                     ;Point to next counter
	lsl     this_flag       ;Move selector bit over to next channel
	cpy     #vcp_sub        
        bls     nx1_adj         ;If still channels left, continue

        jsr     unpack_vol      ;Compute composite volumes and set them

        rts                 ;** Return **
        

;*******************************************************************
;*
;* Set volume control to value entered with the [F][n][n] command.
;*
;*  Sets the loudest of L and R to the level specified in vc_count and
;*  adjusts other channels so that relative volume balance remains
;*  the same (even if some end up compressed). 
;*
;* vc_count  =  dB * 2.
;*
;***
set_all_volume:
	ldd     vcp_l           ;Get left channel composite
	std     min_att         ;Assume it is minimum of the two
	ldd     vcp_r           ;Get right channel composite
	cpd     min_att         ;Compare to min
        bgt     d_ok            ;If larger,skip...

        std     min_att         ;Else make right minimum of the two fronts
d_ok:   ldd     min_att         ;Get minimum attenuation of two front ch's.

;** Removing following line would avoid inconsistency in levels depending 
;**  on mode where command issued, and program material type, but would
;**  NOT clearly define the position of volume control in current
;**  available range based on setup, mode, and material.
	 
        std     min_att         ;to get actual value.
	ldd     vc_count
	subd    min_att         ;Get difference (X-A)
	std     min_att
	ldy     #vcp_l          ;Point to first channel

nexxt:  ldd     0,y             ;Get Lchannel composite
        addd    min_att         ;Add adjustment
	std     0,y
	iny
	iny                     ;Point to next channel
	cpy     #vcp_sub        ;Was this last channel?
        bls     nexxt           ;If not,look at one more
	
        jsr     unpack_vol      ;Compute composite volumes and set them
        rts                 ;** Return **
        

;******************************************************************
;*
;* Unpack Volume
;*
;* Does volume corrections for 4 sets of channels,
;* then sets individual volumes levels.
;*
;***
unpack_vol:
        ldy     #vc_l
        jsr     compute_vc_     

        ldy     #vc_ls 
        jsr     compute_vc_     

        ldy     #vc_c
        jsr     compute_vc_     

        ldy     #vc_es        
        jsr     compute_vc_   

        jsr     set_volume
        rts                 ;** Return **
        

compute_vc_:
        ldaa    curr_pass_mode
        beq     .compute_dig_vc_

;*** Pass-Thru mode computes vc_ =  vcp_ 
.compute_passthru_vc_:
        ldd     vcp_addr_offset,y   ;Get composite att. of left channel
        std     0,y                 ;Update dig. att. (L)

        ldd     vcp_addr_offset+2,y ;Get composite att. of right channel
        std     2,y                 ;Update dig. att. (R)

        rts                 ;** Return **
        

;*** "Digital" mode computes vc_ =  vcp_ + corr_ 
.compute_dig_vc_:
        ldd     vcp_addr_offset,y   ;Get composite att. of left channel
        addd    cor_addr_offset,y   ;Add correction
        std     0,y                 ;Update dig. att. (L)

        ldd     vcp_addr_offset+2,y ;Get composite att. of right channel
        addd    cor_addr_offset+2,y ;Add correction
        std     2,y                 ;Update dig. att. (R)

        rts                 ;** Return **
        

;*********************************************************************
;*
;* Set all channel volumes according to dB values in vc_l, etc. 
;*
;***
set_volume:
        clr     vc_min_flags
	clr     vc_cmp_flags
        clr     vc_max_flags        ;Clear min and max flags if any

	ldaa    #1
        staa    ch_id               ;First channel to process
	ldaa    #%00000001      
        staa    this_flag           ;Set min and max volume flag mask for ch 1
        ldy     #vc_l               ;Point to atten. counter

next_ind:
        ldd     0,y                 ;Get attenuator value (includes corrections!!!)
        jsr     set_atten           ;Set attenuator appropriately (as vc_'s)

        ldd     vcp_addr_offset,y   ;Get composite volume (vcp's)(no correction)
        cpd     #0                  ;Check for max'ed out (vcp <= 0)
        ble     set_max         

        cpd     #vc_min             ;Check for minimum volume
        ble     next_set_ind        ;If louder,  go on...

set_min:
        ldaa    vc_min_flags        ;Get volume min flag set
        oraa    this_flag           ;Set apropriate flag
        staa    vc_min_flags        ;Store flag set
        bra     next_set_ind

set_max:
        ldaa    vc_max_flags        ;Get vol max flag set
        oraa    this_flag           ;Set apropriate flag
        staa    vc_max_flags        ;Store flag set

next_set_ind:
        ldd     0,y                 ;Get attenuator value (includes corrections!!!)
        cpd     #0                  ;Check if in uncompressed range, (with corr's)
        bge     go_on               ;If not, go on; otherwise set compressed flag

        ldaa    vc_cmp_flags        ;Get vol compressed flag set (includes corr's!!)
        oraa    this_flag           ;Set appropriate flag
        staa    vc_cmp_flags        ;Store flag set

go_on:  iny
        iny                         ;Advance to next attenuation counter
        lsl     this_flag           ;Move one bit to left for min/max flag management
        inc     ch_id               ;Next channel
        cpy     #vc_sub     ;!!!!!  ;All done? (NOTE: Ch. will need to be changed
                                    ; if we ever do Auto Delay with ES)
        ble     next_ind            ;If not, loop back and do next...

        jsr     vol_buf_fixup       ;Fix up CS3310 volume buffer according to spkr cfg.
        jsr     WR_CS3310s          ;Write to CS3310s...
        rts                  ;** Return **


;********************************************************************
;*
;*                  S E T    A T T E N U A T O R
;*                  = = =    = = = = =
;*
;* Subroutine to load a single dB volume attenuation value
;*  into the CS3310 volume buffer. It maps system dB attenuation
;*  values to CS3310 attenuation codes, and also takes account
;*  of the different channel order of the CS3310 buffer.
;* The attenuation value to be loaded must be in the D register.
;* The channel to be updated is in ch_id.
;*
;* Attenuation units = dB * 2  (i.e., 0.5 dB steps).
;*
;* Registers altered: d register.
;*
;***
set_atten:
        pshy
        cpd     #0                   ;See if volume compressed (i.e., negative volume)
        bge     chk_rng              ;If not, go check bottom

        ldd     #0                   ;If it is, set digital attenuation to 0 dB
chk_rng:
        cpd     #vc_bot              ;See if volume below attenuator range
        ble     do_vol               ;If not, go ahead

        ldd     #vc_bot              ;Set attenuator to max value

do_vol: coma
        comb
        subd    #$ff3f               ;Convert to CS3310 volume codes.

        tba                          ;Save volume value
        ldab    ch_id
        ldy     #.CS3310_ch_map
        aby
        ldab    0,y                  ;Addr. offset for CS3310 vol imag.
        ldy     #CS3310_vol_imag
        aby
        staa    0,y                  ;Put volume value into CS3310 buffer.

        puly
        rts

;** Remap channel id to match the order of channels in the CS3310:
.CS3310_ch_map:
        dc.b    0     ;dummy
        dc.b    1     ;LF      ch_id = 1
        dc.b    0     ;RF      ch_id = 2
        dc.b    3     ;LS      ch_id = 3
        dc.b    2     ;RS      ch_id = 4
        dc.b    7     ;CT      ch_id = 5
        dc.b    6     ;SR      ch_id = 6
;        dc.b    4     ;ES      ch_id = 7


;********************************************************************
;*
;*          V O L U M E   B U F F E R   F I X U P
;*          = = =         = = =         = = = = =
;*
;* Subroutine to rearrange the CS3310 volume buffer,
;*  according to the speaker configuration.
;*
;* Also adds 6 dB gain for "digital", i.e., non Pass-thru
;*  signals.
;*
;* Mutes ES speaker in Ref. Cinema "digital" mode unless ES
;*  has been enabled by the user ("E" icon).
;*
;* For Analog Pass-thru modes it makes all channel volumes equal
;*  to Max(LF,RF). This removes all "digital" processing volume
;*  setup corrections. The assumption is that the analog source
;*  (e.g., DVD-A) will provide all necessary channel balance
;*  adjustments.
;*
;***

;CS3310 volume image adressing offsets.
;(standard Reference Cinema speaker naming scheme)
RF:     equ     0      ;Right Front.
LF:     equ     1      ;Left Front.
RS:     equ     2      ;Right Surround.
LS:     equ     3      ;Left Surround.
ES:     equ     4      ;Extra Surround.
SL:     equ     5      ;Sub Left.
SR:     equ     6      ;Sub Right.
CT:     equ     7      ;Center.

vol_buf_fixup:
        ldaa    curr_pass_mode
        bne     .v_anlg_passthru        ;Analog pass-through mode.
        jmp     .v_digital              ;Digital processing mode.

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%% "ANALOG" FORMATS:

;%%% ANALOG PASSTHRU (No Volume Corrections: vc_ = vcp_):
.v_anlg_passthru:
        ldy     #CS3310_vol_imag
        ldaa    LF,y                    ;Set LF and RF to the louder
        cmpa    RF,y                    ; of the two.
        bhs     .v_LF_louder            ;Note: CS3310 volumes are unsigned!

.v_RF_louder:
        ldaa    RF,y
.v_LF_louder:
        staa    LF,y
        staa    RF,y

.v_next:
        ldaa    curr_pass_mode
        cmpa    #1                      ;6-channel anlg passthru mode, A7 input.
        beq     .v_6ch_passthru

        cmpa    #2                      ;2-channel anlg passthru mode, A8 input.
        beq     .v_2ch_passthru

        cmpa    #3                      ;8-channel anlg passthru mode, A9 input.
        beq     .v_8ch_passthru
        jmp     .v_done


;%% 6-Channel Pass-Through:
.v_6ch_passthru:
        ldy     #CS3310_vol_imag
        ldaa    RF,y
        staa    LF,y
        staa    RS,y
        staa    LS,y
        staa    SR,y
        staa    CT,y

        clra
        staa    ES,y
        staa    SL,y
        jmp     .v_done


;%% 2-Channel Pass-Through:
.v_2ch_passthru:
        ldy     #CS3310_vol_imag
        ldaa    RF,y
        staa    ES,y

        ldaa    LF,y
        staa    SL,y

        clra
        staa    RF,y
        staa    LF,y
        staa    RS,y
        staa    LS,y
        staa    SR,y
        staa    CT,y
        jmp     .v_done


;%% 8-Channel Pass-Through:
.v_8ch_passthru:
        ldaa    spkr_cfg
        anda    #%0001
        beq     .v1_ref.cinema          ;If Ref.Cinema, set volumes accordingly.

        ldaa    spkr_cfg
        anda    #%0011
        cmpa    #%0001
        beq     .v1_cinema71_movie      ;Else if 7.1 Movie mode, mute outputs.

        ldy     #CS3310_vol_imag        ;Else if 7.1 Music mode, set volumes accordingly.
        ldaa    RF,y
        staa    LF,y
        staa    RS,y
        staa    LS,y
        staa    SR,y
        staa    CT,y

        clra
        staa    ES,y
        staa    SL,y
        jmp     .v_done


.v1_ref.cinema:
        ldy     #CS3310_vol_imag
        ldaa    RF,y
        staa    LF,y
        staa    RS,y
        staa    LS,y
        staa    SR,y
        staa    CT,y
        staa    ES,y
        staa    SL,y
        jmp     .v_done


.v1_cinema71_movie:
        ldy     #CS3310_vol_imag
        ldab    #8                      ;8 speaker outputs.
        clra
.v_lp3: staa    0,y                     ;8-ch pass-thru outputs (A9) muted in Cinema 7.1 Movie.
        iny
        decb
        bne     .v_lp3
        jmp     .v_done


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%% "DIGITAL" FORMATS:
.v_digital:
        ldy     #CS3310_vol_imag
        ldab    #8                      ;8 speaker outputs.

.v_lp2:
        ldaa    0,y
        adda    #12                     ;Add 6 dB to all speakers for "digital" modes.
        staa    0,y
        iny
        decb
        bne     .v_lp2

        ldaa    spkr_cfg
        anda    #%0001
        beq     .v2_ref.cinema          ;Reference Cinema.

        ldaa    spkr_cfg
        anda    #%0010
        beq     .v_71movie              ;0 for Cinema 7.1 Movie mode.
        bra     .v_71music              ;1 for Cinema 7.1 Music mode.


;%%% REFERENCE CINEMA:
;
; LF   CT   RF
;
; SL        SR    <---Mono or stereo subwoofers.
;                     Note: SL is used for 2nd ES when 1 sub.
;
; LS        RS
;      ES
;
.v2_ref.cinema:
        ldy     #CS3310_vol_imag
        ldaa    SR,y
        staa    SL,y                    ;Stereo subs have the same volume.

        ;Temporary code until Ref.Cinema ES level can be adjusted by user:
        ldab    LS,y
        clra
        addb    RS,y
        adca    #0
        lsrd
        stab    ES,y                    ;ES volume = mean of LS, RS volumes.

        ldaa    party_flag              ;If Party mode then leave ES
        bne     .v_done                 ; speaker enabled...

        ldaa    es_flag                 ;If Ref.Cinema ES speaker is enabled,
        bne     .ES1_is_ES2             ;then leave enabled, but check if 2 ESs first...

        clr     ES,y                    ;else mute ES and possibly ES2 as well...

        ldaa    spkr_cfg
        anda    #%1100
        cmpa    #%0100
        bne     .v_done

        clr     SL,y                    ;If two ES outputs and ES is disabled,
        bra     .v_done                 ; mute ES2 as well...

.ES1_is_ES2:
        ldaa    spkr_cfg        
        anda    #%1100          
        cmpa    #%0100          
        bne     .v_done                 ;If 0 or 2 subs, go set volumes...

        ldaa    ES,y                    ;Else, if 1 sub, set SL to same volume as ES
        staa    SL,y                    ;(Z2 is putting out ES on SL)
        bra     .v_done


;%%% CINEMA 7.1 MOVIE:
;
; LF   CT   RF
;
;      SB
;
; LS        RS
;
;  ESL    ESR
;
.v_71movie:
        ldy     #CS3310_vol_imag
        ldaa    LS,y                    ;Copy LS to SL 
        staa    SL,y                    ; to give 7.1 Movie LS(dipole).

        ldaa    ES,y                    ;Copy ES to LS
        staa    LS,y                    ; to give 7.1 Movie ES-L.

        ldaa    RS,y
        tab                             ;Save RS.

        ldaa    ES,y                    ;Copy ES to RS
        staa    RS,y                    ; to give 7.1 Movie ES-R.

        tba                             ;Copy saved RS to ES
        staa    ES,y                    ; to give 7.1 Movie RS(dipole).

        ldaa    #$ff      
        staa    es_flag                 ;Enable ES 
        bra     .v_done


;%%% CINEMA 7.1 MUSIC:
;
; LF   CT   RF
;
;      SB
;
; --        --
;
;  LS      RS
;
.v_71music:
        ldy     #CS3310_vol_imag
        clra
        staa    ES,y                    ;ES muted to disable 7.1 Music RS(dipole).
        staa    SL,y                    ;SL muted to disable 7.1 Music LS(dipole).

.v_done:
        rts


;*********************************
;*                               *
;* Level adjustment stuff ends   *
;*                               *
;*********************************


;*********************************************************************
;* Image updates for write-only latches.
;*
;**
update_DAC8_latch1:
        psha
        ldaa    DAC8_imag1
        staa    DAC8_latch1
        pula
        rts

update_DAC8_latch2:
        psha
        ldaa    DAC8_imag2
        staa    DAC8_latch2
        pula
        rts

update_EO_Vmux:
        psha
        ldaa    EO_Vmux_imag
        staa    EOBP_Vmux
        pula
        rts

update_S_Main_mux:
        psha
        ldaa    S_Main_imag
        staa    SBP_Main_mux
        pula
        rts

update_S_Tape_mux:
        psha
        ldaa    S_Tape_imag
        staa    SBP_Tape_mux
        pula
        rts

update_S_K6:
        psha
        ldaa    S_K6_imag
        staa    SBP_K6
        pula
        rts

update_MB_Main_mux:
        psha
        ldaa    MB_Main_imag
        staa    MB_Main_mux
        pula
        rts

update_MB_Tape_mux:
        psha
        ldaa    MB_Tape_imag
        staa    MB_Tape_mux
        pula
        rts


;***************************************************************
;***************************************************************
set_comp_vol: 
        jsr     get_vol                    ;Get volume in attenuator steps in vc_count
	ldd     dB_value
        cmpb    #99
        bne     set_comp_1
        jmp     Spec_Test_mode            ;If dB = 99 then enter Spec Test mode.

set_comp_1:
        cmpb    #98
        bne     set_comp_2
        jmp     RS_232_test               ;If dB = 98 then test RS-232.

set_comp_2:
        cmpb    #97                     
        bne     set_comp_3
        jmp     IR_Tx_test                ;If dB = 97 then test IR Tx.

set_comp_3:
        cmpb    #96                     
        bne     set_comp_4
        jmp     relay_test2               ;If dB = 96 then set all outputs to single-ended.

;        ldaa    #.SCREEN.Feat_Sel         
;        staa    screen_num                ;If dB = 96 then display Features Selection Screen.           
;        jmp     Features_selection_screen 

set_comp_4:
        cmpb    #95                     
        bne     set_comp_5
        jmp     Versions_A                ;If dB = 95 then display version numbers A.

set_comp_5:
        cmpb    #94                     
        bne     set_comp_6
        jmp     Versions_B                ;If dB = 94 then display version numbers B.

set_comp_6:
        cmpb    #93                     
        bne     set_comp_7
        jmp     VFD_test                  ;If dB = 93 then display VFD contrast test pattern.
                                          ; (Also sets balanced/Single-ended back to default).
set_comp_7:
        cmpb    #92                     
        bne     set_comp_8

        ldaa    #.SCREEN.Inp_Data_Stat
        staa    screen_num                
        jmp     display12                 ;If dB = 92 then display Input Data Status screen.

set_comp_8:
        cmpb    #91                     
        bne     set_comp_9
        jmp     relay_test1               ;If dB = 91 then set all outputs to balanced.

set_comp_9:
        jmp     chan_vol                  ;Else, go change volume...


;******************************************************************
;* Read crossover-related PMD100 scaling factors from Zoran and other...
;*
;**
peek_corr:
        pshy

        ldy     #peek_cmd22           
        jsr     WR_Z2                   ;Get scaling factors from Z2.

        clra
        ldab    ret_inf+12            
        jsr     undo_16_3               ;Undo Zoran 16/3 factor to give 0.5 dB units.
        std     sub_bs_corr             ;Store SUB PMD100 gain factor.

        clra
        ldab    ret_inf+13
        jsr     undo_16_3               ;Undo Zoran 16/3 factor to give 0.5 dB units.

        cpd     #$0021                  ;Check for Garcon's error
        bne     peek_corr_1             ;DO NOT REMOVE!!!!!!

        ldd     #$0015                  ;Modify it if found!!
                                        ;(Zoran EPROM modified 5/22/98)
                                        ;(This patch works with old AND new
                                        ;  Zoran EPROMs!!!)

peek_corr_1:
        std     lr_bs_corr              ;Store front PMD100 gain factor.

        jsr     check_HDCD_corr         ;Check if 6 dB HDCD gain needed.
        jsr     check_mat_corr       ;!!;Obtain LS,RS correction for Matrix mode.
        jsr     check_prol_corr         ;Add 5 dB if PCM Pro Logic.
        jsr     check_dia_corr          ;Clear dialog normalization if not AC-3.

        jsr     update_corr             ;Invoke new corrections and and set volumes

	puly
        rts                         ;** Return **

; We could rewite Z2 code to use 0.5 dB units, instead of 0.1875 units,
; so that the following step would become unnecessary. On the other hand,
; if it's not broken, it may be best to leave it alone, since * 3 / 8
; does the trick exactly!

undo_16_3:                              ;Convert Zoran 16/3 = 0.1875 dB vol units to 0.5 dB.
        ldaa    #3
        mul
        lsrd
        lsrd
        lsrd                            ;We want 0.5 dB units for the CS3310.
        rts


;********************************************************************
;*
;* Update volume corrections
;* (1st code for v6.3 Legacy -4 dB on LS,RS for Matrix mode)
;*
;***
update_corr:
        ldd     #0
        subd    dialog_corr
        subd    HDCD_corr
        subd    prol_corr
        std     cor_c           ;C affected by HDCD, ProL and dialog normalization. 

;        psha
;        pshb                   
;        addd    matrix_corr ;!!!;Lower LS,RS volume for Matrix mode.
        std     cor_ls          ;LS,RS affected by HDCD, ProL,
        std     cor_rs          ; and dialog normalization.
;        pulb                   
;        pula                   

        psha
        pshb
        subd    sub_bs_corr
        std     cor_sub         ;SUB is affected by HDCD, ProL,  
        pulb                    ; dialog normalization and Zoran.
        pula

                                ;L,R affected by HDCD, ProL,
        subd    lr_bs_corr      ; dialog normalization, and Zoran.
        std     cor_l
        std     cor_r
        rts                 ;** Return **


;****************************************************************
;*
;* Volume correction checks
;*
;***
check_HDCD_corr:
        ldaa    PCM_in_proc                     ;If not PCM, clear HDCD corr.       
        beq     check_hdcd_off

        ldaa    curr_mode_temp                  ;Check PCM mode num.
        cmpa    #1                              ;If in ProL or Mono, no correction
        beq     check_hdcd_off

        cmpa    #3
        beq     check_hdcd_off
        
        ldx     #regbase                            ;Otherwise, check HDCD gain
        brclr   porte,x,#%01000000,check_hdcd_off

check_hdcd_on:
        ldd     #Six_dB
        bra     check_hdcd_end

check_hdcd_off:
        ldd     #0
check_hdcd_end:
        std     HDCD_corr
        rts


;------------------------------------
check_prol_corr:
        ldaa    PCM_in_proc                     ;If not PCM, clear ProL corr.
        beq     check_prol_off 

        ldaa    curr_mode_temp
        cmpa    #1                              ;Check for PCM prol
        bne     check_prol_off

check_prol_on:
        ldd     #Five_dB                        ;Increase Pro Logic loudness to compensate
        bra     check_prol_end                  ; for Dolby Surround matrix processing loss, and
                                                ; various psychoacoustic factors.
check_prol_off:
        ldd     #$0000

check_prol_end:
        std     prol_corr
        rts


;------------------------------------
check_mat_corr:
        ldaa    mat_flag                        ;mat_flag = 1 for matrix, else 0.
        bne     check_mat_off               ;!!

check_mat_on:
        ldd     #Four_dB                        ;Legacy requested -5 dB on Matrix LS, RS.
        bra     check_mat_end

check_mat_off:
        ldd     #$0000

check_mat_end:
        std     matrix_corr
        rts


;-------------------------------------
check_dia_corr:
        ldaa    AC3_in_proc                     ;If not AC3, clear dialog corr.
        beq     check_dia_off
        rts                                     ;If AC3, already done!!

check_dia_off:
        ldd     #0
        std     dialog_corr    
        rts


;****************************************************************
get_1st:
	clra
        ldab    dec_key         ;Get decimal key code                  
        andb    #%01111111      ;Map TMS numbers onto TM numbers.
	std     dB_value        ;Save ls digit
        rts                 ;** Return **


;****************************************************************
get_2nd:
	ldd     dB_value        ;Get least significant digit(s) so far in B
	ldaa    #10
	mul                     ;Shift one dec place to left
	std     dB_value        ;Store again
	ldab    dec_key         ;Get decimal key code
        andb    #%01111111      ;Map TMS numbers onto TM numbers.
	clra
        addd    dB_value        ;Add 'ones' to old 'tens' to give binary
        std     dB_value        ; dB volume level, and save.
        rts                 ;** Return **


;****************************************************************
get_vol:
        jsr     get_2nd         ;Process second digit, return total in B
        lsld                    ; Multiply by 2 to convert to 0.5 dB units
        std     vc_count        ; and store for setting volume.
        rts                 ;** Return **
        

;****************************************************************
;*
;* [F][9][9] starts Special Test Mode.
;*
;* Special Test mode is intended to be used
;* with stereo PCM or analog input.
;*
;***
Spec_Test_mode:
        ldaa    #1
        staa    test_screen

        jsr     mute_Zs

        ldy     #special_test_screen
        jsr     screen_out

        ldy     #pcm_cmd1_B6
        brclr   Z_ver_flag,#$ff,pcm_2

        ldy     #pcm_cmd1_B7
pcm_2:  jsr     WR_Z1           ;Start PCM on Z1

        ldy     #spectest_cmd2
        jsr     WR_Z2
        delay   20*10

        jsr     clear_corrs             ;Clear volume corrections and do them
        jsr     unpack_vol

        jsr     unmute_Zs

        ldaa    #$ff
        staa    z_mode

        rts


;******************************************
;*
;* [F][9][8] tests the RS-232.
;*
;***
RS_232_test:
        jsr     LCD_init
        ldx     #regbase
        ldaa    #%00001100              ;Turn off SCI interrupts
        staa    sccr2,x
        brclr   scsr,x,#%10000000,*     ;Wait for buffer to be clear

        ldaa    #$7f
        staa    scdr,x                  ;Transmit $7f character on SCI

        ldy     #0
wait_for_char:
        iny
        beq     no_char_rx
        brclr   scsr,x,#%00100000,wait_for_char  ;Wait to Rx character

        ldaa    scdr,x
        cmpa    #$7f
        bne     no_char_rx              ;If not $7f received, error

        clra
        ldy     #rs232_ok
        jsr     SCREENS                 ;Do 'all ok' screen

        jsr     ONSCI                   ;Turn on SCI interrupts
        bra     .test_end

no_char_rx:
        clra
        ldy     #rs232_error            ;Do 'RS232 error' screen
        jsr     SCREENS   

        jsr     ONSCI
.test_end:
        ldaa    #1                      ;Set 2 sec timeout for test ok screen
        staa    screen_status1
        rts                   ;** Return **


;****************************************************
;*
;* [F][9][7] tests the IR transmitter and receiver.
;*
;***
IR_Tx_test:
        jsr     LCD_init
        ldaa    #k_test
        staa    IR_code_out
        delay   1000*10                 ;Delay 1s to avoid remote pulses
                                        ; messing up the test.
        ldaa    #1
        staa    ir_test_flag            ;Flag test mode
        clr     ir_test_count           ;Clear edge counter
        jsr     IR_output               ;Send out one pulse
        ldaa    ir_test_count
        cmpa    #8                      ;Check if several edges received
        blo     ir_tx_err               ;If too few, no good

        clra
        ldy     #ir_tx_okay
        jsr     SCREENS

        clr     ir_test_flag            ;Come out of test mode
        bra     .test_end2

ir_tx_err:
        clra
        ldy     #ir_tx_error
        jsr     SCREENS

        clr     ir_test_flag            ;Come out of test mode
.test_end2:
        ldaa    #1                      ;Set 2 sec timeout for test ok screen
        staa    screen_status1
        rts                   ;** Return **


;******************************************
;*
;* [F][9][5] displays version numbers and
;* DIP switch information on the VFD/LCD
;*
;*
;* Zoran DSP version numbers and version strings:
;*
;*  B1 :  00302004   ZR38600 MPEG2 ROM bugs, S/PDIF problems
;*
;*  B6 :  00302004   ZR38600 Production version of B1, with same problems.
;*                        
;*  B5 :  00402005   ZR38600 MPEG2 OK, S/PDIF OK.
;*
;*  B7 :  00502006   ZR38600 Production version of B5.
;*
;*  A2 :  A1201002   ZR38601 Improved S/PDIF. 24/96 capability.
;*
;*
;***
Versions_A:
        ldaa    #1
        staa    test_screen             ;Flag that a test screen is up
        ldy     #versions_screen_A
        jsr     screen_out

        tsx
        xgdx
        subd    #17                     ;Allocate stack space for versions buffer.
        xgdx
        txs


;%% Show CPU EPROM version number at position 4 on LCD:
        ldy     #MSG1                   ;Point to EOS EPROM version string.
        ldd     4,y
        std     0,x
        ldd     6,y
        std     2,x
        ldaa    #'|'
        staa    4,x
        ldd     #'  ' 
        std     5,x
        std     7,x
        tsy
        ldaa    #4      
        jsr     SCREENS               

                           
;%% Show DIP switch info. at position 24 on LCD:
        ldaa    DIP_imag                ;Get DIP switch setting.
        jsr     lh2ascii
        staa    0,x
        ldaa    DIP_imag                ;Get DIP switch setting.
        jsr     rh2ascii
        staa    1,x
        ldaa    #'-'
        staa    2,x
        ldy     #regbase
        ldaa    hprio,y                 ;Get SMOD (=*MODB), MDA (=MODA) bits
        eora    #%01000000              ;Complement SMOD to match MODB.
        lsra
        jsr     lh2ascii
        staa    3,x
        ldaa    #'|'
        staa    4,x
        ldd     #'  ' 
        std     5,x
        std     7,x
        tsy
        ldaa    #24     
        jsr     SCREENS                


;%% Show Z1 CPU version # at position 12 on LCD:
        ldy     #ver_cmd
        jsr     WR_Z1
        jsr     proc_ver_inf
        tsy
        ldaa    #12     
        jsr     SCREENS           

;%% Show Z2 CPU version # at position 32 on LCD:
        ldy     #ver_cmd
        jsr     WR_Z2
        jsr     proc_ver_inf
        tsy
        ldaa    #32     
        jsr     SCREENS           

        tsx
        xgdx
        addd    #17                     ;Deallocate stack buffer.
        xgdx
        txs

        rts


;************************************************
;*
;* [F][9][4] displays 68HC11 CPU EPROM checksum
;* and Zoran EPROM Version numbers on VFD/LCD
;*
;***
Versions_B:
        ldaa    #1
        staa    test_screen             ;Flag that a test screen is up
        ldy     #versions_screen_B
        jsr     screen_out

        tsx
        xgdx
        subd    #17                     ;Allocate stack space for versions buffer.
        xgdx
        txs

;%% Show Z1 EPROM ver. # at position 12 on LCD: 
        ldy     #peek_cmd1E
        jsr     WR_Z1
        jsr     proc_peek_inf
        tsy
        ldaa    #12     
        jsr     SCREENS

;%% Show Z2 EPROM ver. # at position 32 on LCD:
        ldy     #peek_cmd2E
        jsr     WR_Z2
        jsr     proc_peek_inf
        tsy
        ldaa    #32     
        jsr     SCREENS

;%% Calculate CPU EPROM check sum:
;(NOTE: skips CPU RAM, registers, EEPROM)
        ldy     #$0400
        clra
        clrb
eprom1_loop:
        addb    0,y
        adca    #0
        iny
        cpy     #$0fff
        ble     eprom1_loop
                                        ;Skip registers $1000 - $1fff
        ldy     #$2000
eprom2_loop:
        addb    0,y
        adca    #0
        iny
        cpy     #$7dff
        ble     eprom2_loop
                                        ;Skip EEPROM
        ldy     #$8000
eprom34_loop:
        addb    0,y
        adca    #0
        iny
        cpy     #$ffff
        ble     eprom34_loop

        tsx
        std     12,x                    ;Save D past end of display info.

        jsr     lh2ascii
        staa    0,x
        ldd     12,x     
        jsr     rh2ascii
        staa    1,x

        ldd     12,x
        tba
        jsr     lh2ascii
        staa    2,x
        tba              
        jsr     rh2ascii
        staa    3,x
        ldaa    #'|'
        staa    4,x
        ldd     #'  ' 
        std     5,x
        std     7,x
        tsy
        ldaa    #3      
        jsr     SCREENS                

        tsx
        xgdx
        addd    #17                     ;Deallocate versions buffer.
        xgdx
        txs

        rts


;****************************************
;* Process version return information
;***
proc_ver_inf:
        ldy     #ret_inf
        ldaa    3,y
        jsr     lh2ascii
        staa    0,x
        ldaa    3,y
        jsr     rh2ascii
        staa    1,x

        ldaa    4,y
        jsr     lh2ascii
        staa    2,x
        ldaa    4,y
        jsr     rh2ascii
        staa    3,x

        ldaa    5,y
        jsr     lh2ascii
        staa    4,x
        ldaa    5,y
        jsr     rh2ascii
        staa    5,x

        ldaa    6,y
        jsr     lh2ascii
        staa    6,x
        ldaa    6,y
        jsr     rh2ascii
        staa    7,x

        ldaa    #'|'
        staa    8,x
        ldd     #'  ' 
        std     9,x
        std     11,x
        std     13,x
        std     15,x
        rts



;**********************************************************
;* Process peek return information for [F][9][4] command
;***
proc_peek_inf:
        ldy     #ret_inf+10
        ldaa    0,y
        jsr     lh2ascii
        staa    0,x
        ldaa    0,y
        jsr     rh2ascii
        staa    1,x

        ldaa    1,y
        jsr     lh2ascii
        staa    2,x
        ldaa    1,y
        jsr     rh2ascii
        staa    3,x

        ldaa    2,y
        jsr     lh2ascii
        staa    4,x
        ldaa    2,y
        jsr     rh2ascii
        staa    5,x

        ldaa    3,y
        jsr     lh2ascii
        staa    6,x
        ldaa    3,y
        jsr     rh2ascii
        staa    7,x

        ldaa    #'|'
        staa    8,x
        ldd     #'  ' 
        std     9,x
        std     11,x
        std     13,x
        std     15,x
        rts


;*********************************
;*  lh2ascii(), rh2ascii()
;*Convert A from binary to ASCII.
;*Contents of A are destroyed.
;***
lh2ascii:
        lsra            ;Shift data to right
        lsra
        lsra
        lsra
rh2ascii:
        anda #$0f       ;Mask top half
        adda #'0'       ;Convert to ascii
        cmpa #'9'
        ble  .finascii  ;Jump if 0-9

        adda #'A'-'9'-1 ;Convert to hex A-F
.finascii:
        rts


;**********************************************
;*
;* [F][9][3] displays the VFD test screen.
;*
;***
VFD_test:
        ldaa    DAC8_imag2
        anda    #%10001111
        ldab    bal_single_save
        andb    #%01110000
        aba
        staa    DAC8_imag2
        jsr     update_DAC8_latch2      ;Restore default Balanced/Single-Ended.

        ldaa    #1
        staa    test_screen        
        ldy     #VFD_test_1
        jsr     screen_out

        delay   1000*10

        ldaa    #1
        staa    test_screen        
        ldy     #VFD_test_2
        jsr     screen_out

        rts


;******************************************
;*
;* [F][9][1] Special DAC8 balanced relay test.
;*
;***
relay_test1:
        ldy     #special_bal_screen
        jsr     screen_out
        ldaa    DAC8_imag2
        anda    #%10001111              ;Make all outputs balanced.
        staa    DAC8_imag2
        jsr     update_DAC8_latch2
        rts


;******************************************
;*
;* [F][9][6] Special DAC8 single-ended relay test.
;*
;***
relay_test2:
        ldy     #special_single_screen
        jsr     screen_out
        ldaa    DAC8_imag2
        oraa    #%01110000
        staa    DAC8_imag2              ;Make all outputs single-ended.
        jsr     update_DAC8_latch2
        rts                   ;** Return **
       

;********************************
chan_vol:
        ldaa    screen_num
        cmpa    #.SCREEN.Spkr_Adj  
        bne     all_ch_vol              ;If not in Speaker Adjustment screen, do all volumes

        ldaa    curr_chs
        beq     all_ch_vol              ;If no channels selected, do all volumes

some_ch_vol:
        jsr     set_sep_vol             ;Do individual volumes
        bra     show_ch_vols

all_ch_vol:
        jsr     set_all_volume          ;Set overall volume level.

show_ch_vols:
        jmp     update_scrn_vol         ;Show changes


;*******************************************************************
;*
;*                   M U T E    C O N T R O L
;*
;***
mute_togl:  ;User command
        ldaa    ps_frame
        cmpa    #k_mute_on
        beq     mute_on                 ;Assert mute.

        cmpa    #k_mute_off
        beq     mute_off                ;Deassert mute.

        ;Else if k_mute...
        brset   mute_status,#1,mute_off ;Toggle mute.

;-------------------------------------------------------------------
mute_on:    ;User command
        ldaa    #$80
        ldab    blink_on_off            ;Sync. mute blinking with other
        mul                             ;blinks (e.g. compression blink)
        incb                            ;Flag muted
        stab    mute_status             
        clr     mute_cntr               ;Make sure daisy updates next time round

do_mute:
        jsr     mute_all                ;Assert PCM1732 and CS3310 mutes.
        delay   80*10                   ;Delay for mute.
        rts                    ;** Return **


;--------------------------------------------------------------------
mute_off:   ;User command
        clr     mute_status             ;Flag unmuted
        clr     mute_cntr               ;Stop counter for source daisy blink
        ldaa    screen_num
        cmpa    #.SCREEN.Main   
        bne     undo_mute               ;Only put source daisy back up if in Main screen

        ldaa    screen_status1       
        bne     undo_mute               ;Only put source daisy back up if in real
                                        ;screen (i.e., not in big nums)
        ldaa    screen_status3          ;and not in Link screen
        bne     undo_mute

        ldaa    test_screen
        bne     undo_mute               ;Only put source daisy back up if not in test screen

        ldaa    curr_pass_mode          ;Start of new anlg p/t code/
        beq     .undo_dig_mute          ;>>>>
                                        ;>>>>
        deca                            ;>>>>
        anda    #%00000011              ;>>>>
        jsr     ana_daisy               ;>>>>
        bra     undo_mute               ;>>>>
                                        ;>>>>
.undo_dig_mute:                         ;End of new anlg p/t code.
        ldaa    daisy_num
        jsr     daisy                   ;Display correct source daisy.

undo_mute:
        jsr     unmute_all              ;Deassert Ovation/Signature mute.
        rts                   ;** Return **


;*****************************************************************
mute_all:
        bclr    DAC8_imag1,#%00100000   ;Assert CS3310 and PCM1732 mutes.
        jsr     update_DAC8_latch1
        rts                   ;** Return **


;*****************************************************************
unmute_all:
        brset   ms_save,#$80,.unmute_all_1  ;If analog, go ahead and unmute

        ldaa    PCM_in_proc             ;Get PCM status
        beq     .unmute_all_1            

        ldaa    cs0_imag
        anda    #%00000010              ;Get DATA flag
        bne     .unmute_all_end         ;If PCM and DATA=1, go home!

.unmute_all_1:
        bset    DAC8_imag1,#%00100000   ;Deassert CS3310 and PCM1732 mutes.
        jsr     update_DAC8_latch1

.unmute_all_end:
        rts                   ;** Return **


;*****************************************************************
; Only Z1 responds to this command.
; (Perhaps the EAD custom code in Z2 does not implement this command?)
mute_Zs:
        ldy     #mute_cmd
        bra     set_it_Zs

unmute_Zs:
        ldy     #muteoff_cmd
set_it_Zs:
        delay   100*10
        pshy
        jsr     WR_Z1    
        puly                     
        jsr     WR_Z2  
        rts


;*****************************************************************
;*
;*                   K I L L    C O N T R O L
;*
;*****************************************************************
;*
;* Note: The power fail interrupt, SVXIRQ does not use kill_on, but
;*       instead does something very similar using in-line code
;*       (rather than using the subroutine call/return mechanism),
;*       so as to conserve CPU cycles during power fail.
;*
;*       The kill_on subroutine is currently used only by initials.
;***
kill_on:
        bclr    DAC8_imag1,#%10001000    ;Assert output kills.
        jsr     update_DAC8_latch1
        rts                   ;** Return **

;------------------------------------------------------------
kill_es_sl_on:
        bclr    DAC8_imag1,#%10000000    ;Assert ES & SL output kills
        jsr     update_DAC8_latch1       ; for 2-ch Passthru mode.
        rts                   ;** Return **

;------------------------------------------------------------
kill_off:
        bset    DAC8_imag1,#%10001000    ;Deassert output kill.
        jsr     update_DAC8_latch1
        rts                   ;** Return **



;*****************************************************************
;*
;*          T H E   I N F A M O U S   C R E D I T S
;*
;***
credits:
        jsr     Invade                   ;Display credits demo on the VFD.
        rts                   ;** Return **


;*********************************************************************
;* Warbles
;**
warble: ldaa    #20                      ;Warble duration

.wloop: jsr     chirp_H
        deca
        bne     .wloop

        rts


warble_L:
        ldaa    #15                      ;Warble duration

.wllop: jsr     chirp_L
        deca
        bne     .wllop

        rts



;*********************************************************************
;* Click - for Front panel pushes
;*
;***
click:  pshy
        psha
        ldy     #3              ;Duration.
        ldaa    #108            ;Frequency.
        staa    tone_freq
        jmp     tcycle


;*********************************************************************
;* chirp_H - Subroutine to make very short high-pitch (freq1) beep.
;*           Is preceeded by a 20 ms delay to make it easy to construct
;*           warble-tones.
;*
;***
chirp_H:
	pshy
	psha
        delay   20*10
        ldy     #chirp1_dura    ;Chirp length.
	ldaa	#freq1		;Chirp pitch.
	staa	tone_freq
	jmp     tcycle          ;Completed in tone1 subroutine.


;*********************************************************************
;* chirp_L - Subroutine to make very short low-pitch (freq2) beep.
;*
;***
chirp_L:
        pshy
	psha
        ldy     #32             ;Chirp length.
        ldaa    #64             ;Chirp pitch.
	staa	tone_freq
	jmp     tcycle          ;Completed in tone1 subroutine.


;*********************************************************************
;* beepbeep - Subroutine to make double beep.
;*
;***
beepbeep:
	jsr     savebeep        ;Do just beeps
        delay   230*10
	jsr     savebeep        ;Two of them
        rts                 ;** Return **


;*********************************************************************
;* savebeep - Subroutine to make short freq1 beeps.
;*
;***
savebeep:   
	pshy
	psha
	ldaa	#freq1		;Beep pitch.
	staa	tone_freq
	ldy     #savebeep_dura  ;Beep length.
	jmp     tcycle          ;Completed in tone subroutine.


;*********************************************************************
;* beep1 - Subroutine to make short freq1 beeps.
;*
;***
beep1:	pshy
	psha
	ldaa	#freq1		;Beep1 pitch.
	staa	tone_freq
        ldy     #beep1dura        ;Beep1 length.
        jmp     tcycle            ;Completed in tone subroutine.


;*********************************************************************
;* tone1 - Subroutine to make freq1 audible tone.
;*
;***
tone1:  pshy
	psha
	ldaa	#freq1		;Tone1 pitch.
	staa	tone_freq
        ldy     #tone1dura      ;Tone1 duration.
	bra	tcycle

;------------------------------------------------------------------
tcycle: sei
	ldaa    tone_freq 
	ldx     #regbase
	bset    porta,x,#%01000000
.tlp1:  deca
        bne     .tlp1

        bclr    porta,x,#%01000000
	ldaa    tone_freq 
.tlp2:  deca
        bne     .tlp2

        dey
        bne     tcycle

        cli
        pula
	puly

	rts                  ;** Return **


;**********************************************************************
;*                                                                    *
;*                      ZR38600 command sequences                     *
;*                                                                    *
;**********************************************************************

;*** Configuration sequences ***
;All three strings must be sent to each Zoran
; DSP prior to selecting any decoding function.

plltab_cmd1:                               
        dc.b     8, $98, $20, $00,   0,   4, 7, 62, 0   ;Z1: 256x, 35.4 MHz

plltab_cmd2:                               
        dc.b     8, $98, $20, $00,   0,   4, 7, 64, 0   ;Z2: 256x, 36.5 MHz

pllcfg_cmd1:
        dc.b     3, $99, $23, 0                                         ;Z1

pllcfg_cmd2:
        dc.b     3, $99, $23, 0                                         ;Z2


;  IFEQ model-1      ;ENCORE (Obsolete-kept here for reference only)
;
;cfg_cmd1:
;        dc.b     10, $82, $C0, $00, $09, $00, $00, $01, $01, $09, 0     ;Z1
;
;cfg_cmd2:
;        dc.b     10, $82, $C0, $00, $09, $00, $00, $01, $01, $09, 0     ;Z2
;
;
;  ELSEC             ;OVATION/SIGNATURE

cfg_cmd1:
        dc.b     10, $82, $C0, $00, $09, $00, $00, $01, $01, $09, 0     ;Z1

cfg_cmd2:
        dc.b     10, $82, $C0, $00, $89, $00, $00, $01, $01, $01, 0     ;Z2

;  ENDC


;*** Mode selection ***

pcm_cmd1_B6:
        dc.b     10, $84, $00, $08, $00, $00, $00, $00, $7f, $ff, 0     ;Z1 - B6

pcm_cmd1_B7: 
        dc.b     10, $86, $00, $00, $00, $00, $00, $00, $7f, $ff, 0     ;Z1 - B7

prol_cmd1:                      
        dc.b     10, $86, $00, $0f, $00, $00, $00, $00, $7f, $ff, 0     ;Z1 - B6 or B7

AC3_cmd1:
        dc.b     10, $85, $a0, $0f, $00, $00, $00, $02, $7f, $ff, 0     ;Z1

mpeg_cmd1:                        
        dc.b     10, $87, $20, $0f, $00, $00, $00, $00, $7f, $ff, 0     ;Z1

png_cmd1:                                              ;$2d6f cuts pink noise by 9 dB
        dc.b     10, $83, $00, $7f, $00, $00, $00, $00, $2d, $6f, $89 ;Includes unmute!!
                                                       ;$7f, $ff is 0dB pink noise
mute_cmd:
        dc.b     2, $8b,0                                               ;Z1

muteoff_cmd:
        dc.b     2, $89,0                                               ;Z1

play_cmd:
        dc.b     2, $8a,0
                                                       
stop_cmd:
        dc.b     2, $8c,0

;*** Special commands ***

stat_cmd:
        dc.b     17, $8e, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        dc.b              0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;Version string for Z1 and Z2 DSPs:
ver_cmd:
        dc.b     6, $81, 0,0,0,0,0                                     

;EAD command string for Z2:
ead_cmd2:
        dc.b     10, $86, $00, $00,  80, $00, $00, $00, $00, $00, 0    

;Crack string for Z2: 
crack_cmd2:
        dc.b     10, $86, $06, $00, $00, $00, $00, $00, $00, $00, 0   

;Special Test mode string for Z2:
spectest_cmd2:
        dc.b     10, $86, $04, $00, $00, $00, $80, $00, $00, $00, 0   
                                            ;2 subs         Ref.Cinema
;Six-channel feed-thru string for Z2:
feedthru_cmd2:
feedthru_cmd2_Ref:
        dc.b     10, $86, $00, $00,  80, $00, $80, $00, $00, $00, 0
                                    ;80 Hz   2 subs         Ref. Cinema

feedthru_cmd2_71:  ;(includes channel re-arrangement for Cinema 7.1)
;The following is a temporary work-around for a problem in Z10:
;It makes LS pink noise go to LS, ES-L, ES-R; and it makes RS pink
; noise go to RS, ES-L, ES-R. (This takes advantage of the Ref.Cinema
;feature that puts ES on SUB-L if there's only 1 sub.)
        dc.b     10, $86, $00, $00,  80, $00, $40, $00, $00, $00, 0
                                    ;80 Hz   1 sub          Ref. Cinema

;Problem with this is that Z10 Z2 code swaps ES-L & ES-R with LS & RS
; for pink noise in Cinema 7.1 Movie and Music modes.
;        dc.b     10, $86, $00, $00,  80, $00, $40, $00, $00, $40, 0
;                                    ;80 Hz   1 sub          Cinema 7.1

;Peek string for custom Z1 EPROM version:
peek_cmd1E:
        dc.b     13, $94, $0d, $00, $00, 0,0,0,1, 0,0,0,0,0             
                                       
;Peek string for Z2 bass management EPROM version (VER_NUM):
peek_cmd2E:
        dc.b     13, $94, $0d, $03, $ee, 0,0,0,1, 0,0,0,0,0             

;Peek string for Z2 cross-over frequencies:
peek_cmd21:
        dc.b     13, $94, $00, $1e, $00, 0,0,0,1, 0,0,0,0,0             

;Peek string for Z2 scaling factors:
peek_cmd22:
;;;;;;;;;6-channel
;;;;;;;;dc.b     13, $94, $00, $02, $86, 0,0,0,1, 0,0,0,0,0

        ;8-channel (makes room for 8-channel ch. peak buffer)
        dc.b     13, $94, $00, $02, $88, 0,0,0,1, 0,0,0,0,0

;Peek string for Z2 VU display data:
peek_vol:
;;;;;;;;;6-channel
;;;;;;;;dc.b     34, $94, $00, $02, $80, 0,0,0,6
;;;;;;;;dc.b     0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0

        ;8-channel
        dc.b     42, $94, $00, $02, $80, 0,0,0,8
        dc.b     0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        dc.b     0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0

;Poke string for resetting Z2 VU display peak hold:
poke_vol:
;;;;;;;;;6-channel
;;;;;;;;dc.b     34, $93, $00, $02, $80, 0,0,0,6
;;;;;;;;dc.b     0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0

        ;8-channel
        dc.b     42, $93, $00, $02, $80, 0,0,0,8
        dc.b     0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
        dc.b     0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0

peek_for_Z1E:
        dc.b     13, $94, $0d, $02, $01, 0,0,0,1, 0,0,0,0,0             

;Boot string for Z1:
invoke_init_cmd1:
        dc.b     25, $90, $00,$0d,$02,$00, 0,0,0,0,0,0,0,0
        dc.b         $ff, $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

;Boot strinb for Z2:
invoke_init_cmd2:
        dc.b     25, $90, $00,$0d,$00,$00, 0,0,0,0,0,0,0,0
        dc.b         $ff, $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

mpeg_cmd:
;       include "c:\1work\eos-i\mpeg2b1.i"  Crashes when bitstream has errors.

;       include "c:\1work\eos-i\mpeg2b6.i"  Also crashes!

        include "c:\1work\eos-i\mpeg2b63.i"        ; Try this!!!

mpeg_cmd_end:

;**********************************************************************
;*                                                                    *
;*                      CS4226 command sequences                      *
;*                                                                    *
;**********************************************************************

;*** Register reading and writing ***

init_regs:      ;To write all regs, start at reg #1, autoincrement up to reg. #16       

;     IFEQ    model-1      ;ENCORE
;        dc.b     18,$20,$81, 4, 0,$3f,$7f,$7f,$7f,$7f,$7f,$7f, 0,$40
;        dc.b          0, 0,$e4,$e4,$47
;                                 ;****
;                                 ;Auto Emphasis!
;     ELSEC                ;OVATION/SIGNATURE

        dc.b     18,$20,$81, 4, 0,$3f,$7f,$7f,$7f,$7f,$7f,$7f, 0,$40
        dc.b          0, 0,$e4,$e4,$40
                                 ;*****
                                 ;Emphasis off!!!

;     ENDC


xtal_regs:
        dc.b     18, $20, $81, 0,0,0,0,0,0,0,0,0,0,0,0,0,$e4,$e4,$47

read_reg_a:
        dc.b     02, $20, $00      ;Last byte will be updated

read_reg_b:
;       dc.b     02, $21, $00      

read_stat_a:    ;To read status regs, start at reg #17, set autoincrement
;       dc.b     02,  $20, $80+17

read_stat_b:    ; read up to reg. #25
;       dc.b     10, $21, 0,0,0,0,0,0,0,0,0

read_stat_1:
        dc.b     02, $21,0

write_reg:
        dc.b     03, $20, $01, 00  ;Last 2 bytes will be updated



;**********************************************************************
;*                                                                    *
;*                       56009 command sequences                      *
;*                                                                    *
;**********************************************************************

;*** Configuration sequences ***


cntrl_5.1:
        dc.b    15              ;5x24-bit words to follow... 
        dc.b    $bb, $00, $59   ;PLL clock multiplier = 90x ($000 - $fff).
        dc.b    $cc, $04, $9f ;was $18 ;          L=0,^clk,          I2S,LJ,msb 1st,32 clks
        dc.b    $dd, $05, $9f ;was $1f ;Lt/Rt=off,L=0,^clk,-10dB LFE,I2S,LJ,msb 1st,32 clks,all ch.
        dc.b    $ee, $00, $00
        dc.b    $ff, $ff, $ff



        end

                                                                                                              
