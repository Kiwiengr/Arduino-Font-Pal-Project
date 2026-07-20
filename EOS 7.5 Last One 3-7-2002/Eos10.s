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
;   Eos10.s 
;
;**********************************************************************
;*
;*                         EOS Main Code
;*
;**********************************************************************
;      Version  Date             Notes
;----------------------------------------------------------------------
;
;        1.0                Original
;
;        1.1                1st Encore ship version.
;                           1st Ovation ship version.         
;
;        1.2   01/09/98     Fixed PMD100 DC offset problem on
;                            going from lock to no-lock input.
;                           Added user delay to main loop to
;                            fix possible Big-Nums flicker problems.
;
;        2.1   01/15/98     HMUTE added.
;
;        2.2   01/16/98     Signature tape/mon switching & defaults.
;
;        2.3   01/22/98     Dolby submodes & auto detect modes.
;                           Fixed HFEQ in Analog bug.
;
;        2.4   02/04/98     Auto Delay, temperature.
;
;        2.5   02/--/98     Volume corrections, RS-232.
;
;        2.6                RS232 interface fully working
;                           Fixed STO/RCL problems (were not
;                            initiating Z modes).
;                           Now able to deselect spkrs in distance
;                            screen so that STO/RCL work there.
;                           Added ENTER key as EXIT.
;
;        2.7                Fixed HFEQ mute problems
;                            (and AC3 FF mute??) by extra delays.
;
;        2.8                Extra Zoran modes (using Z EPROM #5).
;
;        2.9   05/18/98     Fixed noise burst on do_ams.
;          
;        3.0   05/26/98     Z1 B6/B7 version checking.
;
;        3.1   06/01/98     Various display-related problems fixed.
;                           Problems with Enter key exit from modes fixed.
;
;        3.2   06/03/98     SwitchMaster downloader added.
;                           AES/fs bug fixed.
;
;        3.3   06/06/98     MPEG error handling improved.
;                           No screen flicking if bitstream changes
;                            while in bar graph.
;                           SwitchMaster standby mode added.
;                                               
;        3.4   06/17/98     Old SwitchMaster code download (DIP SW #1-#8 ON).
;                           Added )( Dig/Pro Logic trademark usage for
;                            flagged Dolby Surround AC-3 bitstreams.
;                           HF-EQ now stays up during :N/A blurb.
;
;        4.0   06/18/98     PCM mute problem fixed (again).
;                           Debugging beeps removed from autosetup.
;                           MPEG2 is enabled in this version.
;                           No update yet for B6 MPEG2 patch (B7 is OK).
;                           Temporary patch for 2 dB Pro Logic bass level bug
;                            (this will be solved permanently by the Z6 EPROM).
;                           Initial "FINAL" shipping version of software.
;
;        4.1e  06/18/98     Asserts kill for Encore unlocked inputs, to
;                            reduce thumps and pops when switching inputs.
;
;        4.2   06/30/98     Fixed AC3 reboot problem (caused hesitation
;                            out of pause in Dolby Digital 5.1)
;                           B6 MPEG patch (reboot DSPs)
;
;        4.3   07/03/98     Saved speaker dists upon EXIT,ENTER,DISP up/down
;                           Bypass MPEG patch in B7 (In B7 we use ROM MPEG!)
;
;        4.4   07/14/98     Third-generation MPEG2 patch from Zoran
;                           (properly implemented this time!)
;                           Encore "whiplash" fix (needs harware fix).
;                           
;          
;        4.5   07/23/98     Finally fixed balanced glitch on noise modes
;                           4.5.1 Fixed bug on Perm. ded. AC3 no-lock
;                                 (was showing no-lock MPEG !)
;          
;        4.6   08/04/98     Discovered and fixed DTS muting problem
;                           with problem LD players
;
;        4.7   08/04/98     Added Prof. AC3 decoding and Z1 EPROM check
;
;        4.8   08/07/98     Fixed SM tape-mon error upon picking up links
;
;        4.9   08/17/98     Changed SM code: Added cold start initialization
;                           of ports to prevent flakiness on start-up.
;                           Fixed Enc. link bug when going into No-Lock inputs
;                           Fixed IR learn jitter
;
;        4.91  08/31/98     Flywheel checking fix...goes with DAC board kluge
;                           (but it is backward compatible!)
;                           (IR learn jitter reappeared!!)
;
;        4.92  09/16/98     Fixed IR jitter again
;
;        4.93  10/15/98     Fixed freeze ups associated with flywheel
;
;        4.94  10/29/98     1 min. mute problem fixed
;
;        4.95  11/10/98     Default flywheel to OFF
;                           (too many cracks and pops!!)
;
;
;                AUTO PHASE FROM HERE!!!
;
;        5.0 and 5.01       Internal testing (and afew sympathetic dealers!)
;
;        5.02  11/20/98     Encore mute split accompanies wire kluge
;
;        5.03  12/09/98     Reduce long lamp time-out to 1/2 hour to
;                           preserve lamp life
;
;        5.04  02/02/99     Theater mode default to save lamp!
;
;        5.05  02/08/99     Clear theater mode timer to avoid auto-del probs
;
;        5.06e 06/09/99     Add delay to unkill after regain lock, line 5078 of EOS_com
;
;        6.0s  10/21/99     VFD developmental version.
;                           x 1. Raise screen when entering standby.
;                           x 2. No brightness control initially (always 100% in use, 25% in standby).
;                           x 3. Need Dialog Normalization readout for VFD version.
;                                (in place of Bright:5, have DN:23 dB). Clear in non AC-3.
;                           x 4. Inv IR code and decode.
;                           x 5. Later install 100% and 50% user brightness levels (F^, Fv).
;                              (from standby should reinstate 100% user brightness).
;                           x 7. Need 1/2-hour (36 minute) timer on standby screen.
;                                (Shows TheaterMaster SIGNATURE for 1/2-hr, then dots)
;
;
;        6.1   10/27/99     First VFD shipping version.
;                             1. Brightness control 25% or 100% (F-disp up/down)
;                             2. Dialog Normalization readout for all VFD builds.
;                                 (in place of Bright:5, have DN:23 dB). '--' in non AC-3.
;                             3. Inv IR code and decode.
;                             4. Half-hour timer on standby screen.
;                                 (Shows TheaterMaster SIGNATURE for 36 minutes, then dots)
;                             5. VFD requires 47 pF ceramic cap on VFD 'E'-strobe to gnd.
;
;
;        6.2   02/21/00       1. Zoran version number corrected to also handle 38601 A2.
;                             2. Some improvements to some of the title screens.
;                             3. Bogus delay in IR programming mode makes "oo" difficult.
;
;
;        6.3   03/15/00       1. Matrix mode surrounds reduced by 4 dB (requested by Legacy Audio).
;                             2. Fixed minor problems with Legacy/Encore/LCD build.  
;                             3. Bogus delay in IR programming mode makes "oo" difficult.
;
;
;        6.4   04/20/00       1. IR programming mode delay repaired.
;                             2. IR programming mode splash screen.
;                             3. VU meter shows a weird scrolling to the left
;                                 when run at high volume (lots of bar height).
;
;
;        7.1   06/21/01       1. DAC8 initial volume control -80 dB to 0 dB (+31 dB future?)
;                             2. DAC8 DHP (headphone detect) ignored in this version of the s/w.
;                             3. No digital flywheel.
;                           x 4. PWM code for LCD EL lamp needs to be removed.
;                             5. Default for VU meter is now absolute (i.e., not scaled).
;                             6. BAL key is now Spkr Cfg, and is used to flash up or change.
;                             7. Spkr Cfg, CH+, CH-, SURR are used to modify Speaker Config.
;                             8. No AutoSetup in Cinema 7.1 layout.
;                             9. Cinema 7.1 Movie mode not available in Anlg Passthru.
;                            10. Old F-RCL command deleted for increased simplicity.
;                            11. Old F-RCL-F command is now accessed with F-RCL.
;                            12. Enter-STO/RCL reversed for input labels.
;
;
;        7.2   07/08/01       1. Number of subwoofers now stored. Symptom was that system
;                                 always gave the maximum number of subs when turned on
;                                 from cold or from standby.
;
;                             2. Default VU meter for stereo in now 6, 7, or 8 channels
;                                 (so that Party mode shows as multi-channel, and stereo
;                                 and stereo with stereo subs is shown to best effect).
;
;        7.3   07/23/01       1. -4 dB surround correction for Matrix mode removed, due
;                                 to interaction with other decoding modes. This will be
;                                 fixed in a future version.
;                             2. See further details elsewhere.
;
;        7.4   09/23/01       1. -10 dB pink noise error on LF, RF fixed.
;                             2. The above fix also took care of St.Noise problem where SUB
;                                 pink noise showed up in LF, RF.
;                             3. Distance measurement readout corrected. Now accurate <1 m to >5 m.
;                             4. DIP SW3: OFF (default) Temporary DTS enabled.
;                                         ON: Temporary DTS disabled (number keys do not turn on).
;                                (Permanent AC-3 dedication on input 3 command deleted)
;                             5. Fixed: Problem where temporary dedication of an input to DTS
;                                 or MPEG results in no audio until user does NEXT/PREV, etc.
;                                 However, if temporary dts/mpeg is used after immediately after
;                                 changing the speaker configuration (Ref.Cinema <--> Cinema 7.1)
;                                 pressing 1 takes it to A1 instead of D1, and Motorola DSP
;                                 produces a weird noise in the speakers.
;
;                             6. Special Test modes now has sub woofer outputs!
;                                 Note also: To get ES in Sp.Test mode, enable before
;                                 doing the [F][9][9] Sp.Test command.
;
;        7.5   02/19/02       1. Fix pending for ES level adjustment (offset from mean of LS, RS).
;                             2. Fix pending for "pause burst".
;                             3. Fix pending for RS232 double buffering.
;                         ok  4. DIP SW2: OFF (default) Manual 12-volt trigger.
;                                         ON: Automatic 12-volt trigger.
;                                (Permanent DTS on input 2 command has been deleted)
;                         ok  5. $$<cr> RS232 cold start command added.
;                         ok  6. IR learn now has user-controlled bursts.
;
;
;        Problems:            1. Need a way of turning on with RS-232 but without the features
;                                 screen. Currently there is no way to shorten the cold-start
;                                 features list when using TM ( RS-232 Power ON command.
;                             2. Need a way of determining if unit is ON (e.g., monitor DSP reset lines)
;
;        Future features:     1. Need RS-232 status feedback for Crestron & WCES..
;                             2. Move the standby dots every hour or so to save VFD.
;                             3. Default input labels on Chassis, like Lexicon DC-1.  
;                             4. New RS-232 commands: B ("big"), single char anlg select, etc.
;                               
;----------------------------------------------------------------------

        CLIST OFF       ;Only list assembled conditonals.
        MLIST OFF       ;Don't expand macros.

eos10_flag:   equ     0


        XDEF    ic1_initialize,MSG1
        XDEF    EOS_start,Standby_mode,First_2_secs,Main_loop
        XDEF    IRQ_flag,IR_ready,two_press_timer,Buefuss_flag,TM_flag
        XDEF    one_sec,two_secs,three_secs,rti_timer
        XDEF    screen_num,ovcnt1,lat_ovcnt1,ovcnt2,frame,lamp_status
        XDEF    screen_status1,screen_status2,features,cold_start,feats_ptr
        XDEF    Long_features,main_loop1,main_ft_end_sby,the_temp
        XDEF    J_Short_features,J_Long_features,main_ft_end_pre
        XDEF    noise_seq_timer,flash_up,update_screen12,temp_cntr
        XDEF    ir_test_flag,ir_test_count,theater,SPL_timer,slow_enc_timer
        XDEF    zoran_cntr,auto_set_timer
        XDEF    screen_status3,sticky_dts_ctr,err_star_ctr,clippage
        XDEF    sticky_ac3_ctr,mpeg_err_ctr,VFD_time_out

        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


        
;**************************************************************************
;**************************************************************************

eos10_vb:       Section 33

;** Timers
ovcnt1:          ds.b     1       ;8-bit timer (free running) (used in IR Rx)
ovcnt2:          ds.b     1       ;8-bit timer (free running) (used for bar graph timeout)
lat_ovcnt1:      ds.b     1       ;8-bit timer (latched)      (used in IR Rx)
lamp_time_out:   ds.b     3       ;24-bit timer (latched)     (used for EL lamp timeout)
VFD_time_out:    ds.b     3       ;24-bit timer (latched)     (used for VFD stdby timeout)
one_sec:         ds.b     1       ;1 second timer (latched)   (used in IR Learn)
two_secs:        ds.b     1       ;2 second timer (latched)   (used to expand decoding mode key functionality)
three_secs:      ds.b     1       ;3 second timer (latched)   (used in bar graph & feat. scrn)
rti_timer:       ds.b     1       ;RTI timer for CS4226 status reads.

screen_status1:  ds.b     1       ;Big Nums timer and screen restoration flag.
                                  ;  0 = timer stopped, no action;
                                  ;  1 = start timer;
                                  ; $ff= timer stopped, restore old screen;
                                  ; $fe= timer stopped, restore Main screen & initialize.

screen_status2:  ds.b     1       ;Mode indicator screen timer

screen_status3:  ds.b     1       ;Longer flash screen timer for A/V Link screens


noise_seq_timer: ds.b     1       ;Free timer for noise sequencer
auto_set_timer:  ds.b     1       ;Free timer for auto setup samples

flash_up:        ds.b     1       ;Flash preview of status screens.
                                  ; (use with screen_status1 timer only).
update_screen12: ds.b     1       ;Updates for Input Data Status screen
SPL_timer:       ds.b     2       ;Number of main loops before SPL update
slow_enc_timer:  ds.b     1       ;Time out for encore volume slowing
zoran_cntr:      ds.b     2       ;Counts # of main loops between Z1 reads
temp_cntr:       ds.b     1       ;Counts # of main loops between temperature updates
filter_cntr:     ds.b     2       ;Counts # of filters before averaging
sticky_dts_ctr:  ds.b     2       ;Sticky DTS count-down timer
sticky_ac3_ctr:  ds.b     2       ;Sticky AC3 count-down timer
err_star_ctr:    ds.b     1       ;Error star count-down timer
mpeg_err_ctr:    ds.b     1       ;MPEG error timer

clippage:        ds.b     1       ;Clip indicator


;** Front panel button stuff
IRQ_flag:        ds.b     1       ;Flags number of IRQs 
two_press_timer:
                 ds.b     1       ;Times gap between button presses


;** IR Remote Control decode stuff
sync_in:         ds.b     1       ;flag: 0-not done; 1-sync pulse detected.
ic1mod:          ds.b     1       ;s/w mode flag: $ff-off; 0-1st edge; 1-last edge.
cnt1:            ds.b     2       ;First  rising edge cycle count (16 bits).
cnt2:            ds.b     2       ;Second rising edge cycle count (16 bits).
dura:            ds.b     2       ;Pulse Width in cycles (16 bits).
bitcnt:          ds.b     1       ;Counter for number of received bits.
prev_frame:      ds.b     1       ;Storage for 1st frame received.
right_frame:     ds.b     1       ;Storage of successful frame
IR_ready:        ds.b     1       ;Flag to indicate successful IR Rx.
nxt_frm_flg:     ds.b     1       ;Flags first or second frame to be read.
frame:           ds.b     1       ;Stores incoming bits.
ir_test_flag:    ds.b     1       ;Flags if we are testing IR Tx
ir_test_count:   ds.b     1       ;Counts edges for the test


;** Miscellaneous
cold_start:      ds.b     1       ;Flags cold start (=1) or reset (=0)

;Use this for a "theater mode" feature later:
lamp_status:     ds.b     1       ;Lamp on/off flag

theater:         ds.b     1       ;Theater mode on/off flag (is controlled in EOS_com.s)
features:        ds.b     1       ;Features screens in progress flag (for start-up)
feats_ptr:       ds.b     2       ;Pointer to Features screens
screen_num:      ds.b     1       ;Which screen are we on?

Buefuss_flag:    ds.b     1       ;Flag indicating BUEFUSS RS232 command.
TM_flag:         ds.b     1       ;Flag indicating TheaterMaster RS-232 command.



;**************************************************************************
;**************************************************************************

All_Data:       Section 20      
      
;**********************************************************************
;********    Version Number - output on RS232 at reset    *************
;**********************************************************************

MSG1:   dc.b 'EOS '

        dc.b '7.5'   ;SOFTWARE VERSION NUMBER.  ;Do not change the length (=3)
                                                ; or the address of this string!!!
                                                ; (It is also used bu the IR
                                                ; "Versions" command, F-9-5)
        IFEQ    name-1     ;OVATION-8
           IFEQ    brand-1    ;EAD
              IFEQ    alpha-1    ;EOS

                 dc.b 'o'           ;TheaterMaster Ovation-8

              ELSEC              ;8000 series

                 dc.b 'x'           ;TheaterMaster 8000

              ENDC
           ENDC
           IFEQ    brand-2    ;LEGACY VFD

              dc.b 'p'

           ENDC
           IFEQ    brand-3    ;SIMAUDIO Attraction VFD

              dc.b 'q'

           ENDC
        ENDC
        IFEQ    name-2     ;SIGNATURE-8
              IFEQ    alpha-1 ;EOS

                 dc.b 's'        ;TheaterMaster Signature-8

              ELSEC           ;8000 series

                 dc.b 'p'        ;TheaterMaster 8000 pro

              ENDC
           IFEQ    brand-2    ;LEGACY model?

              dc.b 't'

           ENDC
           IFEQ    brand-3    ;SIMAUDIO model?

              dc.b 'u'

           ENDC
        ENDC
        IFEQ    name-3     ;SIGNATURE-8a
           IFEQ    brand-1    ;EAD

              dc.b '+'

           ENDC
        ENDC

        dc.b '  Copyright 2001 Thunder Lake Audio Corporation'

        dc.b  EOT


        INCLUDE "c:\1work\eos-i\IR_data.i"
        INCLUDE "c:\1work\eos-i\RS_data.i"
        INCLUDE "c:\1work\eos-i\Screens.i"
        INCLUDE "c:\1work\eos-i\English.i"  
        INCLUDE "c:\1work\eos-i\Japanese.i" 
        INCLUDE "c:\1work\eos-i\CChars.i"
        INCLUDE "c:\1work\eos-i\keylabel.i"
        INCLUDE "c:\1work\eos-i\colddef.i" 
        INCLUDE "c:\1work\eos-i\temperat.i"


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%                                 %%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%          :  MAIN CODE :           %%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%                                   %%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%  Starts here at power up / reset  %%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%                                 %%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EOS_strt:       Section 1

;**********************************************************************
;*
;* First two seconds of operation:
;*
;* Front panel button push in this time goes to IR Learn.
;* IR Rx 'Power' in this time goes to Main loop
;*
;**********************************************************************

EOS_start:
        lds     #ram_end
        jsr     Initials
        ldaa    #1
        staa    cold_start              ;Flag cold start

First_2_secs:
        brset   DIP_imag,#%00100000,first2  ;Check for SM downloader
        jmp     downloader                  ;Go to SM downloader - No TM at all!!


first2: ldab    #$7f                    ;Send Soft-Reset control
        jsr     send_sci                ; character to SwitchMaster.

        jsr     OUTCRLF
        ldx     #MSG1                   ;Buefuss sign-on message on terminal screen.
        jsr     OUTSTRG

        ldy     #Standby_scrn           ;Put up standby screen
        jsr     screen_out

        ldaa    #1                      ;Start time-window for entry to IR Learn mode.
        staa    one_sec

        ldaa    #13                
        staa    t_state                 ;Initialize the keycode
        staa    b_state                 ; state machine.

first2_0:
        ldaa    IRQ_flag                ;Check for button push
        beq     first2_1
        jmp     Learn_mode

first2_1:
        ldaa    one_sec                 ;Check if IR Learn window expired
        bne     first2_0                ; if not, keep looping

        jsr     new_version             ;Check if "F-RCL" command needed (new version)
        jsr     into_standby            ;Set up for standby mode


;*********************************************************************
;*
;* Standby Mode:
;*
;* Wait for front panel push, IR [Power] code or RS232 'W'
;*  to come out of standby.
;* Meanwhile, do features list:
;*  long features for cold start, short features for warm start.
;*
;*********************************************************************

Standby_mode:

        lds     #ram_end                ;Reset stack (fresh start at each standby).

        ldy     #Standby_scrn           ;Put up Standby screen
        jsr     screen_out

        delay   230*10                  ;230 ms

        ldd     #1                      ;Start VFD anti-burn-in timer.
        std     VFD_time_out+1
        clr     VFD_time_out

        clr     IRQ_flag

        brset   DIP_imag,#%00000010,stby_loop0   ;If DIP SW3 is OFF (default), do nothing...
        jsr     screen_up               ;Else turn OFF 12 V trigger.

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%% STANDBY LOOP:

stby_loop0:
        ;When anti-burn-in timer reaches zero, replace the standard
        ; Standby screen to the anti-burn-in dot pattern:
;       ldaa    VFD_time_out+1          ;256x faster (8.4 sec.) for testing.
        ldaa    VFD_time_out            ;Normal 36 minute time-out.
        cmpa    #$01                    ;If elapsed standby time < 36 minutes,
        blo     skip_dots               ;Then continue showing model...

        ldd     #0                      ;Else stop timer
        std     VFD_time_out+1          ;      /
        clr     VFD_time_out            ;      /
                                        ;      /
        ldy     #Stdby_dots             ; and put up Standby Dot screen...
        jsr     screen_out

skip_dots:
        ldaa    IRQ_flag                ;Check for front panel push
        beq     stby_loop1              ;If not, go on

        clr     IRQ_flag                ;If so, clear flag, out of standby 
        ldaa    #1
        staa    t_state
        clr     b_state                 ;Set up correct key state
        jmp     from_standby            ; and go to main loop

stby_loop1:
        ldaa    IR_ready                ;Check for IR Rx
        beq     stby_loop2              ;If not, go on

        jsr     exec_frm                ;Deal with IR code received

stby_loop2:
        ldaa    TM_flag                 ;Check for RS232 TM code
        beq     stby_loop3              ;If not, go on

;Clear already done in exec_rs232:   clr     TM_flag
        jsr     exec_rs232              ;Execute the command

stby_loop20:
        jsr     ONSCI                   ;Re-enable SCI interrupts
        lds     #ram_end                ;Initialize stack pointer every time
        jsr     OUTCRLF
        ldaa    #PROMPT                 ;Prompt user
        jsr     outa

stby_loop3:
        ldaa    Buefuss_flag            ;Check for Buefuss command
        beq     stby_loop_x             ;If not, loop again

        clr     Buefuss_flag
        jsr     SRCH                    ;Do Buefuss command...
stby_reprompt:
        jsr     ONSCI                   ;Re-enable SCI interrupts
        lds     #ram_end                ;Initialize stack pointer every time
        jsr     OUTCRLF
        ldaa    #PROMPT                 ;Prompt user
        jsr     outa
stby_loop_x:
        jmp     stby_loop0              ;Loop again.

;%%% END OF STANDBY LOOP.
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


;*********************************************************************
;*
;*
;*                    M  A  I  N      L  O  O  P
;*
;*
;*********************************************************************

Main_loop:
        lds     #ram_end                ;Reset stack (fresh start every time)
        ldaa    #1
        staa    three_secs              ;Start timer for Features screens.

main_loop0:
        ldaa    features                ;Check if in Features screens
        beq     main_loop1              ; if not, all Features screens done so go on
                                        
        ldaa    three_secs              ;Check if Features screens timer expired
        bne     main_loop1              ; if not, check for buttons

        ldaa    cold_start              ;If in warm start, now go into operation
        beq     main_ft_end_sby

        ldaa    #$7f
        staa    ms_save                 ;Force a fresh screen after Features screens

        ldy     feats_ptr
        brclr   DIP_imag,#%00000001,Jap3  ;Language?

Eng3:   cpy     #End_Long_feats
        beq     main_ft_end_pre
        bra     Next_feature

Jap3:   cpy     #J_End_Long_feats
        beq     main_ft_end_pre

Next_feature:
        ldaa    #1
        staa    three_secs              ;Restart Features screens timer.
        clra
        ldy     feats_ptr               ;Get pointer to Features screen
        jsr     screen_out              ;Display Features screen
        ldab    #41
        aby
        sty     feats_ptr               ;Update Features pointer
        bra     main_loop1

main_ft_end_sby:                        ;Coming from warm start from title
                                        ;Get standby preserved channel number

        ldaa    ms_save
        anda    #%01111111
        staa    dec_key                 ;Force old input selection

        bclr    ms_save,#%01111111      ;Force anlg. or dig. selection
        bra     main_ft_end

main_ft_end_pre:                        
        ldaa    #1
        staa    dec_key                 ;Digital 1 input by default

main_ft_end:
        clr     three_secs              ;Turn off Features screens timer
        clr     features                ;Flag end of Features list


        clr     b_state                 ;Clear IR state
        clr     t_state

        brset   ms_save,#%10000000,into_main_anlg

into_main_dig:
        jsr     do_dms                  ;Select proper digital input
        bra     into_main_Zs

into_main_anlg:
        jsr     do_ams                  ;Select proper analog input

into_main_Zs:
        clr     cold_start              ;If we reach here, warm start is next
        jmp     main_loop1              ;Go to button checking
        

;The main control loop starts here:
;***********************************************************************
;********************** Check for front panel push *********************
;***********************************************************************

main_loop1:
        ldaa    IRQ_flag                
        beq     main_loop2              ;If not, go on

        cmpa    #1
        beq     one_or_2_prs            ;One press - check for second         

;*** Two presses occurred:
        clr     IRQ_flag
        jmp     into_standby            ;Two presses - go to standby

one_or_2_prs:
        ldaa    two_press_timer
        cmpa    #8
        bls     main_loop2              ;If under 300ms passed, continue to loop            

;*** One press occurred:
        clr     IRQ_flag                ;Get ready for next push
        ldaa    features                ;Check if in Features
        beq     one_press               ; if not, go to mute
        jmp     shortcut_feats          ; if so, stop features, go to Main screen

one_press:
        clr     ps_frame
        jsr     mute_togl               ;Toggle mute
        jmp     main_loop2              ;Check other flags             



;***********************************************************************
;************************* Check for IR Rx *****************************
;***********************************************************************

main_loop2:
        ldaa    IR_ready                
        beq     main_loop3              ;If not, go on

        ldaa    screen_num
        cmpa    #.SCREEN.IR_Test        ;Check if in IR Remote Control Test screen
        bne     not_testing

        jsr     ir_test_mode
        cmpb    #$ff
        beq     not_testing             ;Check if valid key press
        bra     main_loop3

not_testing:
        jsr     exec_frm                ;Deal with IR frame received


;***********************************************************************
;********************** Check for TM Command ***************************
;***********************************************************************

main_loop3:
        ldaa    TM_flag                 
        beq     main_loop4              ;If not TM command, loop again...

        jsr     exec_rs232              ;Else execute the TM command and
        jmp     main_reprompt           ; prompt user again...


;***********************************************************************
;******************* Check for Buefuss Command *************************
;***********************************************************************

main_loop4:
        ldaa    Buefuss_flag            
        beq     main_loop5              ;If not Buefuss command, loop again...

        clr     Buefuss_flag            ;Else
        jsr     SRCH                    ; do Buefuss command and
;       bra     main_reprompt           ; prompt user again...

main_reprompt:
        jsr     ONSCI
        lds     #ram_end                ;Initialize stack pointer every time
        jsr     OUTCRLF
        ldaa    #PROMPT                 ;Prompt user
        jsr     outa
        bra     main_loop5              ;Continue flag checking

;***********************************************************************
;***     SCREEN RESTORATION - after Big Nums, mode screens, ...      ***             
;***********************************************************************
main_loop5:
        ldaa    features
        beq     main_loop5_big          
        jmp     main_loop6              ;If in features, skip this section


;*********************   After Big Nums  *******************************
main_loop5_big:
        ldaa    screen_status1
        cmpa    #$ff                    ;Check for old screen restore
        beq     main_loop5_big1

        cmpa    #$fe                    ;Check for Main screen restore
        bne     main_loop5_mode         ;if not, go on

;* At this point, a mode change has happened through one of 2 things:
;* Locked status has changed     - NO screen update in this case
;* Bitstream has changed         - NO screen update in this case

        ldy     #screen_image
        ldd     8,y
        cpd     #'ed'                   ;Check for DTS Dedication screen
        beq     main_loop5_big2         ;If so, postpone until later

        cpd     #'de'                   ;Check for MPEG Dedication screen
        beq     main_loop5_big2         ;If so, postpone until later

        ldaa    screen_num      
        cmpa    #.SCREEN.VU_meter
        beq     main_loop5_0            ;If in VU meter, do not touch screen

        ldaa    #.SCREEN.Main
        staa    screen_num              ;if so, go to Main screen                      

main_loop5_0:
        clr     update_screen12         ;To avoid double refresh
        clr     screen_status1          ;Flag no restore needed (DO NOT MOVE THIS!!!

        jsr     get_curr_mode
        jsr     check_if_new_Z          ;Initialize Zorans if necessary
                                        ;(if elsewhere, can cause problems when lock changes
                                        ; during Z mode initialization)

        cmpa    #$ff                    ;Check for invalid mode change
        bne     main_loop5_big0

        jsr     check_if_new_Z          ;Call default mode (A=$ff)

main_loop5_big0:
        ldaa    screen_num
        cmpa    #.SCREEN.VU_meter
        beq     main_loop5_mode         ;If in VU meter, do not touch screen

        jsr     LCD_init
        jsr     display_scrn            ;Put Main screen up again
        bset    icon_flag,#%00011111    ;Display relevant icons
        bra     main_loop5_mode


main_loop5_big1:
        clr     screen_status1          ;Flag no restore needed
        clr     flash_up                ;Flag end of flash update
        jsr     LCD_init

        jsr     display_scrn            ;Put previous screen up again
        bset    icon_flag,#%00011111    ;Display relevant icons

        bra     main_loop5_mode


main_loop5_big2:
        ldaa    #1                      ;If mode change is flagged, while you
        staa    screen_status1          ; are in DTS dedication screen make 
        bra     main_loop5_mode         ; sure you get 2 secs of dedication screen


;***********************  After Mode Screen  ***************************
main_loop5_mode:
        ldaa    screen_status2          
        cmpa    #$ff                    ;Check for old screen restore
        bne     main_loop5_other

        ldaa    #0                      ;Clear restoration timer
        staa    screen_status2

        jsr     LCD_init                ;Clear old screen
        jsr     display_scrn            ;Put up volumes/labels (or SPL meter)

main_loop5_mode1:
        ldaa    auto_stage              
        cmpa    #1                      ;If going into Auto Setup now,
        beq     main_loop5_mode2        ; turn on noise in LF


        ldaa    noise_in_proc           ;If going into Noise Seq. now,
        bne     main_loop5_mode2        ; turn on noise in LF
        jmp     main_loop5_other        ;Otherwise, go on


main_loop5_mode2:
        ldaa    #1
        staa    noise_channel
        clr     noise_seq_timer         ;In case going into Noise Seq. mode
        clr     auto_success
        clr     auto_set_timer          ;In case going into Auto setup mode

        jsr     rotate_noise            ;Turn on noise in LF
        jmp     main_loop5_other


;***** The following is after other things (e.g. A/V Link screens): *****

main_loop5_other:
        ldaa    screen_status3
        cmpa    #$ff                    ;Check for old screen restore
        bne     main_loop6

        clra
        staa    screen_status3          ;Clear restoration timer

        ldaa    screen_status1          ;Check if Big Nums are up now
        bne     main_loop6              ;If so, do not redisplay screen now
                                        ;(allow Big Nums update to do it!)

        jsr     LCD_init                ;Put up old screen
        jsr     display_scrn

;***********************************************************************
;***********      Check for lamp time out (screen saver)      **********
;***********            (currently not implemented)           **********
;***********************************************************************
main_loop6:
        ;Lamp  time out code would go here...
        bra     main_loop7              ;Check next flags

;***********************************************************************
;******* UPDATE OF MAIN SCREEN - mute daisy, hdcd, hfeq icons **********
;***********************************************************************
main_loop7:
        ldaa    test_screen             
        beq     main_loop71  
        jmp     main_loop8              ;If in test screens, skip this section

main_loop71:
        ldaa    screen_status1
        beq     main_loop72             
        jmp     main_loop8              ;If in Big Nums, skip this section

main_loop72:
        ldaa    features
        beq     main_loop73    
        jmp     main_loop8              ;If in features, skip this section

main_loop73:
        ldaa    screen_status3
        beq     main_loop74    
        jmp     main_loop8              ;If in an A/V Link screen, skip this

main_loop74:
        ldaa    screen_status2
        beq     main_loop75    
        jmp     main_loop8              ;If in Mode screen, skip this

main_loop75:
        ldaa    screen_num
        cmpa    #.SCREEN.Main
        beq     main_loop7_mute
        jmp     main_loop7_icon         ;If not in Main screen, skip to the
                                        ;icons section


;******************   Check for mute daisy flashing   ******************
main_loop7_mute:
        brclr   mute_status,#1,main_loop7_icon  ;If no user mute, go on

        ldaa    mute_cntr
        cmpa    #$ff                    
        bne     main_loop7_icon         ;If no daisy change, go on

        clr     mute_cntr               ;Restart mute counter
        ldaa    mute_status
        anda    #%10000000              ;Get daisy info (0=clear, 1=source coding config)
        bne     main_loop7_mute2

main_loop7_mute1:
        ldaa    locked                  ;If locked do clear daisy
        beq     main_loop7_mute11
        brset   ms_save,#$80,main_loop7_mute11  ;If analog, ignore locked status

        ldaa    #15                     ;If unlocked, do blank daisy...
        bra     main_loop7_mute12

main_loop7_mute11:
        ldaa    curr_pass_mode        ;>>>>
        beq     .main_loop7_mute11a

        ldy     #analog_daisies
        ldab    #7*4
        aby                             ;Select p/t "Daisy" Mute string.
        ldaa    #20                     ;Position on screen.
        jsr     SCREENS
        bra     main_loop7_mute3      ;>>>>

.main_loop7_mute11a:
        ldaa    #7                      ;If locked, do clear daisy...
main_loop7_mute12:
        jsr     daisy                   ;Do clear or blank daisy
        bra     main_loop7_mute3

main_loop7_mute2:
        ldaa    curr_pass_mode        ;>>>>
        beq     .main_loop7_mute2a      ;If not in pass-thru, put up real daisy...

        ldy     #analog_daisies
        ldab    #7*3
        aby                             ;Select p/t "Daisy" string.
        ldaa    #20                     ;Position on screen.
        jsr     SCREENS
        bra     main_loop7_mute3      ;>>>>

.main_loop7_mute2a:
        ldaa    daisy_num               ;Do real daisy
        jsr     daisy

main_loop7_mute3:
        bra     main_loop7_icon


;*******  Check for HDCD, HFEQ, ES, Music, Party icons in Main screen *******

main_loop7_icon:
        ldaa    icon_flag
        beq     main_loop8              ;If no icons, go on     
                               
        ldaa    noise_in_proc
        adda    static_in_proc
        bne     main_loop_7_clear       ;If in Noise or Static, do no icons

        ldaa    curr_pass_mode
        bne     main_loop_7_clear              ;If in pass-through mode, no icons!
        brset   ms_save,#$80,main_loop7_icon2  ;If analog, skip HDCD...

        ldaa    locked                  ;If not locked, don't do hdcd icon
        bne     main_loop7_icon2

        ldaa    curr_mode               ;If current mode is Mono or Surr,
        cmpa    #3                      ; do not update HDCD icon
        beq     main_loop7_icon2        

        cmpa    #1
        beq     main_loop7_icon2

        ldaa    PCM_in_proc             ;If not in PCM, (i.e., if in AC3, MPEG, DTS)
        beq     main_loop7_icon2        ; do not update HDCD icon

                                        
main_loop7_icon1:                       ;Else...
        brset   icon_flag,#%00000001,main_loop_7_hdcd   ;Check if HDCD update

main_loop7_icon2:
        bclr    icon_flag,#%00000001                    ;Clear HDCD update
        brset   icon_flag,#%00000010,main_loop_7_hfeq   ;Check if HFEQ update
        brset   icon_flag,#%00000100,main_loop_7_esmp   ;Check if ES update
        brset   icon_flag,#%00001000,main_loop_7_esmp   ;Check if Music update
        brset   icon_flag,#%00010000,main_loop_7_esmp   ;Check if Party update
        bra     main_loop8              ;If not, go on

main_loop_7_hdcd:
        jsr     show_HDCD
        bclr    icon_flag,#%00000001    ;Clear HDCD update flag
        bra     main_loop8

main_loop_7_hfeq:
        jsr     show_HFEQ
        bclr    icon_flag,#%00000010    ;Clear HFEQ update flag
        brset   icon_flag,#%00000100,main_loop_7_esmp ;Check if also ES update
        bra     main_loop8

main_loop_7_esmp:
        jsr     show_ESMP
        bclr    icon_flag,#%00011100    ;Clear ES, Music, & Party update flags
        bra     main_loop8
        
main_loop_7_clear:
        bclr    icon_flag,#%00011111    ;Clear all flags
        bra     main_loop8


;***********************************************************************
;****************  Check for VU Meter update (screen 2)  ***************
;***********************************************************************
main_loop8:
        ldaa    curr_pass_mode          ;If in digital mode (0),
        beq     .m_digital              ; proceed to do VU meter as normal...
                                        ;Else put up "no VU in pass thru mode":
;%%% ANALOG PASSTHRU:
.m_analog_pass:
        ldaa    screen_num
        cmpa    #.SCREEN.VU_meter       ;Check for VU meter screen
        bne     main_loop9 

        ldaa    ovcnt2                  ;If VU meter showing, check timer
        cmpa    #4           ;>>>>      ; (Real digital mode VU uses a 2 here)
        bls     main_loop9              ;If < 200 ms, do not update

        ldaa    screen_status1
        bne     .main_loop82            ;If in Big Nums, do not update

        jsr     Bar_None_Display        ;Put up special bar display for anlg pass-thru

.main_loop82:
        clr     ovcnt2                  ;Restart timer
        bra     main_loop9 


;%%% DIGITAL MODES:
.m_digital:
        ldaa    screen_num
        cmpa    #.SCREEN.VU_meter       ;Check for VU meter screen
        bne     main_loop9 

        ldaa    ovcnt2                  ;If VU meter showing, check timer
        cmpa    #2
        bls     main_loop9              ;If < 100 ms, do not update

        ldaa    screen_status1
        bne     .main_loop81            ;If in Big Nums, do not update

        jsr     Bar_volume              ;Get 8 channels of vol from Z2


;%% Style of VU meter bar graph depends on speaker configuration:
;%% 2-ch VU meter -- 2-channel stereo (only if DIP SW7 ON)
;%% 8-ch VU meter -- Ref.Cinema and Cinema 7.1 Movie mode.
;%% 6-ch VU meter -- Cinema 7.1 Music mode.

        brset   DIP_imag,#%01000000,eight_six_bar ;If DIP SW7 is OFF (default), then use multi-channel bars only.
        
        ldaa    mode_chs
        anda    #%00011111              ;Mask out SUB.
        cmpa    #%00000011              ;2-channel stereo
        beq     two_bar                 ; gets a 2-bar graph.

eight_six_bar:
        ldaa    spkr_cfg
        anda    #%0011
        cmpa    #%0011                  ;Cinema 7.1 Music mode
        beq     six_bar                 ; gets 6-ch. bars,
        bra     eight_bar               ; else do 8-ch. bars.

eight_bar:
        jsr     Bar8_Display            ;Do 8 bar Ref.Cinema & 7.1 Movie (AC3 and DTS)
        bra     .main_loop81

six_bar:
        jsr     Bar6_Display            ;Do 6 bar 7.1 Music (AC3 and DTS)
        bra     .main_loop81

two_bar:
        jsr     Bar2_Display
.main_loop81:
        clr     ovcnt2                  ;Restart timer
        bra     main_loop9 


;************************************************************************
;****************** Check if in Noise Sequencer mode ********************
;************************************************************************
main_loop9: 
        ldaa    noise_in_proc           ;Check if in Noise Sequencer mode
        beq     main_loop10

        ldaa    screen_status2          ;If still in mode screen, do nothing
        bne     main_loop10

main_loop9_0: 
        ldaa    noise_seq_timer
        cmpa    #110                    ;Check if 3s time out
        bls     main_loop10

main_loop9_1: 
        jsr     rotate_noise            ;PNG rotates around the room
        bra     main_loop10


;************************************************************************
;********    Input Data Status changes for * and C,V,P flags    *********
;************************************************************************
main_loop10:
        ldaa    update_screen12         ;Check if Input Data Status screen update needed
        beq     main_loop11

        ldaa    screen_num
        cmpa    #.SCREEN.Inp_Data_Stat  ;Check if in Input Data Status screen
        beq     main_loop10_s11

        cmpa    #.SCREEN.Main
        beq     main_loop10_s1          ;Also check if in Main screen
        bra     main_loop10_x           ;If neither, clear flag and go on       

main_loop10_s11:
        ldaa    update_screen12
        cmpa    #2                      ;#2 indicates V flag still up
        beq     main_loop10_x           ;If V flag still up, make no changes

        jsr     display12_no_clr        ;Refresh Input Data Status screen (with no clear)

        ldaa    err_star_ctr            ;Only update VCP if timed out
        bne     main_loop11             ;(timer is started upon VCP update)

        jsr     display12_VCP
        clr     update_screen12         ;Clear update flag
        bra     main_loop11

main_loop10_s1:
        ldaa    screen_status1          ;If flash screens are up, no update
        bne     main_loop11

        ldaa    screen_status2
        bne     main_loop11

        ldaa    screen_status3
        bne     main_loop11

        ldaa    features
        bne     main_loop11             ;If features going on, no update

        ldaa    err_star_ctr
        bne     main_loop11             ;No update if not timed out
       
        jsr     err_star                ;Put up error star or colon
main_loop10_x:
        clr     update_screen12         ;Clear update flag
        bra     main_loop11

;************************************************************************
;**********************     Check for Mic    ****************************
;************************************************************************
main_loop11:
        ldaa    noise_in_proc          
        bne     main_loop11_mic1        ;If in Noise Seq, check for mic

        ldaa    static_in_proc          
        beq     main_loop12             ;If in Static noise check for mic

main_loop11_mic1:
        ldaa    screen_status2          ;If still in mode screen, do nothing
        bne     main_loop12

        ldaa    screen_image
        cmpa    #'S'                    ;Check if SPL meter is up
        bne     spl_not_on

spl_on:
        ldx     #regbase
        brset   porte,x,#%00000010,main_loop11_ad   ;If mic in, all ok

        jsr     switch_SPL                          ;Power down A-D
        jsr     LCD_init
        jsr     display30                           ;Put up normal screen
        bra     main_loop12

spl_not_on:
        ldx     #regbase
        brclr   porte,x,#%00000010,main_loop12     ;If mic not in, all ok
put_up_spl:
        jsr     LCD_init

        clra
        ldy     #SPL_meter              ;Put up SPL meter blurb
        jsr     SCREENS

        jsr     switch_SPL              ;Power up A-D
        ldx     #0
        stx     filter_cntr
        bra     main_loop11_ad


;*******************************************************************
;***********************      SPL  A/D      ************************
;*******************************************************************
main_loop11_ad:                         ;Only called if Noise seq or
                                        ;static noise in process and mic in
        jsr     aver_flt                ;Do one iteration of microphone LPF
                                        ; (the 8-bit result is in vol_acc).
        ldx     filter_cntr
        inx
        stx     filter_cntr
        cpx     #200 
        bls     main_loop12

        ldab    vol_acc
        jsr     SPLdB            ;D = 16-bit SPL dB.

        psha
        pshb

        jsr     deciSPL

        pulb
        pula
        subd    #527             ;Convert D to a number 0-60 in A
        lsrd
        lsrd
        lsrd
        tba
        jsr     SPL_display      ;Update SPL screen

        ldx     #0               ;Restart counter
        stx     filter_cntr
        bra     main_loop12


;************************************************************************
;**************************    Zoran reads     **************************
;************************************************************************
main_loop12:
        ldaa    static_in_proc          ;If in static noise, do not check Zoran
        beq     main_loop12_1
        jmp     next_12                 


main_loop12_1:
        ldaa    noise_in_proc           ;If in noise sequencer, do not check Zoran
        beq     main_loop12_2
        jmp     next_12    


main_loop12_2:
        ldaa    auto_in_proc            ;If in auto-setup, do not check Zoran
        beq     main_loop12_3
        jmp     next_12    
        

main_loop12_3:
        ldx     zoran_cntr
        inx
        stx     zoran_cntr
        cpx     #50                     ;Slow down to 120 times a second
        bls     next_12    

        ldx     #0
        stx     zoran_cntr

        jsr     get_auto_flag           ;Get PCM, AC3 info

next_12:                                ;(will update screen_status1 if necessary)
        bra     main_loop13


;************************************************************************
;**********  Check for temperature update (Sys Config screen) ***********
;************************************************************************
main_loop13:
        ldaa    screen_num
        cmpa    #.SCREEN.Sys_Config
        beq     temp_chk                ;If in Sys Config screen then do live update
        jmp     main_loop14

temp_chk:
        ldx     temp_cntr
        inx
        stx     temp_cntr
        cpx     #7500                   ;Update temperature once per sec.
        bhs     temp_reading
        jmp     main_loop14

temp_reading:
        ldx     #0
        stx     temp_cntr

        ldaa    screen_status1          ;Do not show if in Big Nums.
        bne     main_loop14

        jsr     show_temp
        jmp     main_loop14


;************************************************************************
;************ Auto Setup tweaking of volume and cracking ****************
;************************************************************************
main_loop14:
        ldaa    auto_in_proc            ;Check if auto setup is going on
        bne     main_loop14_0           ;Yes it is...
        jmp     main_loop_x             ;If not, do nothing here

main_loop14_0:
        jsr     aver_flt                ;Update mic filter as fast as possible
        ldaa    screen_status2          ;Check if in indicator screen
        beq     main_loop14_1           ; if not, deal with auto setup...
        jmp     main_loop_x             ; if so,  do nothing here...

main_loop14_1:
        ldaa    auto_stage  
        cmpa    #1
        beq     main_loop14_tweak       ;Check if in auto-level

        cmpa    #2
        beq     main_loop14_crack       ;Check if in auto-delay

;%% AUTO LEVEL...
main_loop14_tweak:
        ldaa    auto_set_timer
        cmpa    #15                     ;Two 0.5 dB volume steps per second = 1 dB/s.
        bls     main_loop_x

        clr     auto_set_timer          ;Start timer to do volume check twice a second.

        ldx     #regbase
        brset   porte,x,#%00000010,main_loop14_2  ;If mic in, continue with setup...

        jsr     exit_adjust             ;If mic out, fail...
        jsr     do_mute     
        bra     main_loop_x             

main_loop14_2:
        jsr     tweak_vol
        ldaa    auto_success
        beq     main_loop_x             ;Check if successful vol level found

        ldaa    noise_channel           
        cmpa    #1                      ;Have we done all channels?
        beq     main_loop14_3           ;Yes...

        jsr     rotate_noise            ;No, Do next channel in sequence around room...
        clr     auto_success
        jmp     main_loop_x

main_loop14_3:                          ;Success!!
        jsr     auto_set_finish         ;Set up volumes accordingly, & start auto delay...
        jmp     main_loop_x


;%% AUTO DELAY...
main_loop14_crack:
        ldaa    auto_set_timer
        cmpa    #30
        bls     main_loop_x

        clr     auto_set_timer          ;Do crack check every second
        jsr     crack_channel           ;Put crack out in one channel
        ldaa    auto_ctr
        cmpa    #8                      ;Check for 7 failures
        blo     main_loop14_crack1      ;If <7, check for success

        jsr     abort_auto_set          ;Abort if 7 failures
        bra     main_loop_x

main_loop14_crack1:
        ldaa    auto_success
        beq     main_loop_x             ;If no success, keep same channel

;       clr     auto_success  ;>>>Why?  ;Clear success flag for next channel

        inc     noise_channel           ;Update to next channel
        ldaa    noise_channel
        cmpa    #5                      ;Check if all channels done
        bls     main_loop_x             

        jsr     auto_delay_finish       ;Finish up
        bra     main_loop_x


;************************************************************************
;************************************************************************
;*
;*  Loop again
;*

main_loop_x:
        jmp     main_loop0
;*
;*
;************************************************************************        

need_to_update:                              ;No need to update if in noise modes
        ldaa    static_in_proc
        bne     need_to_rts

        ldaa    noise_in_proc
        bne     need_to_rts

        ldaa    auto_in_proc
        bne     need_to_rts

        ldaa    #$fe                         ;Otherwise no screen change (all ok)
        staa    screen_status1

need_to_rts:
        rts


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%
;%%%%%% Interrupt Service routines
;%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


;*****************************************************************
;* SVTOC1,5 - Output Compare 1 and 5 interrupt service routine
;*
;* Used for LCD lamp brightness levels and blinking characters.
;*
;* TOC1 turns lamp on  \
;*                      } both OCs control PA3 (via OC1M,D and TCTL1)
;* TOC5 turns lamp off /
;*
;* Note: Blinking routine takes time, so is integrated into the lamp
;*       routines to avoid noticeable variation of brightness.
;*
;***

SVTOC1:
        ldx     #regbase
        ldd     #32768                  ;total_bright
        addd    toc1,x                   
        std     toc1,x                  ;Set up interrupt after 16.4ms
        bclr    tflg1,x,#%01111111      ;Clear OC1F
svtoc1_rti:
        rti

;***

SVTOC5:
        ldx     #regbase
        ldd     #32768                  ;total_bright
        addd    ti4o5,x
        std     ti4o5,x                 ;Set up interrupt after 16.4ms
        bclr    tflg1,x,#%11110111      ;Clear OC5F
        jsr     blinking                ;Do blinking now
svtoc5_rti:
        rti


;*****************************************************************
;* SVTIC1 - Input Capture 1 interrupt service routine
;*
;* Used by IR decode.
;*                                         
;*                    |<--------T-------->|
;*                    +-----+             +-----+
;*                    |     |             |     |
;*       -------------+     +-------------+     +-------------
;*                    ^                   ^
;*                    |                   |
;*                    1st edge.           2nd edge.
;*
;*
;*  After valid sync detected, take time of 2nd edge, 
;*  store as 1st edge time and start looking for second edge again.
;*
;***

SVTIC1:
        ldaa    ir_test_flag
        beq     svtic1_1
        inc     ir_test_count
        bra     svtic1_done_1

svtic1_1:
        ldx     #regbase
        ldaa    IR_ready                ;Do not get pulse if not yet processed
        bne     svtic1_done_1

        inc     ic1mod                  ;Update to next edge
        bne     not1st                  ;If not 0, this is second edge
        
;*%%%%% Process first edge %%%%%%%%

        ldd     tic1,x                  ;Read time of first edge
        std     cnt1                    ;Save till next capture
svtic1_done_1:
        bclr    tflg1,x,#%11111011      ;Clear IC1F
        rti


;*%%%%% Process second edge of pulse
not1st: ldd     tic1,x                  ;Get time of second edge
        std     cnt2
        subd    cnt1                    ;Time of last minus time of first
        std     dura                    ;Store duration of pulse


;*%%%%% Determine if valid sync
validity_test:
        ldaa    sync_in
        bne     read_bits               ;If sync pulse already in, read bits

        ldd     dura
        cpd     #hi_sync                ;Compare pulse duration count to higher sync threshold 
        bhs     next_edge               ;if longer, try again for sync

        cpd     #lo_sync                ;Compare pulse duration count to lower sync threshold
        bls     next_edge               ;if shorter,try again for sync 
                                        ;Otherwise, get ready to read bits               
        ldaa    #1
        staa    sync_in

        clr     bitcnt                  ;No bits detected yet
        clr     frame                   ;Clear data storage area

next_edge:
        ldd     cnt2                    ;Convert this edge time into first edge time
        std     cnt1
next_edge_1:
        clr     ic1mod                  ;Count next edge as second
        bra     svtic1_done_1

read_bits:
        ldd     dura

;%% Determine whether 0 or 1:
        cpd     #lo_zero                ;Compare to lower "0" threshold
        bls     garbage_bit             ; if shorter, garbage

        cpd     #hi_zero                ;Compare to higher "0" threshold
        bls     zero_bit                ; if shorter it is a "0"

        cpd     #lo_one                 ;Compare to lower "1" threshold
        bls     garbage_bit             ; if shorter it is garbage

        cpd     #hi_one                 ;Compare to higher "1" threshold
        bls     one_bit                 ; if shorter it is a "1"
                                        ;Otherwise, it is garbage
garbage_bit:
                               
        clr     sync_in                 ;Wait for another sync pulse...bit corrupted
        bra     next_edge

one_bit:
        sec        
        rol     frame                   ;Place a "1" in lsb of data
        bra     update_bit_count

zero_bit:
        lsl     frame                   ;Place a "0" in lsb of data

update_bit_count:
        inc     bitcnt                  ;One more bit read
        ldaa    bitcnt
        cmpa    #size                   ;All bits in?
        bne     next_edge


;** Deal with complete frame **

        ldaa    nxt_frm_flg             ;Check if receiving 1st or 2nd frame
        bne     two_frames_in

one_frame_in:

        ldaa    lat_ovcnt1              ;Check if latched counter is timing
        beq     one_frame_1             ; if not, process pulse

        ldaa    frame                   ; if so, a pulse is repeating
        cmpa    #k_vup                  ;If volume up/down, process 
        beq     one_frame_1             ; (i.e., allow repeat)

        cmpa    #k_vdn
        beq     one_frame_1  

        ldaa    #1
        staa    lat_ovcnt1              ;Restart timer to avoid next pulses
        clr     nxt_frm_flg             ;Get ready for next frame
        bra     one_frame_2             ;Reset for next sync pulse

one_frame_1:
        ldaa    #1
        staa    nxt_frm_flg             ;Flag next frame ready to be read
        ldaa    frame           
        staa    prev_frame              ;Store data already collected
one_frame_2:                                
        ldaa    #$ff                    ;Get ready for first edge again
        staa    ic1mod
        clr     sync_in                 ;Get ready for next sync pulse
        clr     ovcnt1                  ;Start timer
svtic1_done_2:
        bclr    tflg1,x,#%11111011      ;Clear IC1F
        rti
        

two_frames_in:
        ldaa    ovcnt1          ;Check if 2nd frame Rx is within 96ms
        cmpa    #5              
        bhs     timed_out       ;If timed out, look for first frame again

        ldaa    frame           ;Otherwise check that 2 frames are the same
        cmpa    prev_frame      
        bne     different_2nd   ;If not, receive 2nd frame again
        
frame_okay:
        ldaa    #1
        staa    IR_ready        ;If so, flag that IR is ready to be read
        staa    lat_ovcnt1      ;Start timer for gap between allowed Rx
        ldaa    #$ff            ;Get ready for first edge again
        staa    ic1mod
        clr     sync_in         ;Get ready for next sync pulse
        clr     nxt_frm_flg     ;Get ready to Rx first frame again
        bclr    tflg1,x,#%11111011       ;Clear IC1F
        rti

timed_out:                                              
        clr     nxt_frm_flg     ;Receive 2nd frame, clear timout
        bra     one_frame_in    ;and set current frame as 1st.

different_2nd:
        ldaa    #1
        staa    nxt_frm_flg     ;Receive 2nd frame again ignoring current frame
        clr     sync_in         ;Ready for next sync pulse
        jmp     next_edge       ;Receive next frame


;*****************************************************************

ic1_initialize:
        
        ldx     #regbase  
        clr     nxt_frm_flg             ;Get ready for first frame
        clr     sync_in                 ;Get ready for sync
        ldaa    #$ff                    ;Get ready for first edge
        staa    ic1mod
        clr     ovcnt1                  ;Clear time-out flags
        clr     lat_ovcnt1
        clr     IR_ready                ;Clear successful IR Rx flag
        bclr    tflg1,x,#%11111011      ;Clear IC1F
        rts



;*****************************************************************
;* SVIRQ - Front panel button press interrupt service routine
;*
;* This is the Highest Priority interrupt:
;* Controls Standby and IR learning mode.
;* Debounce the button presses by ignoring repeated presses before 120ms
;* 
;***

SVIRQ:

        ldaa    IRQ_flag                ;test number of IRQ presses
        bne     multi_press
        bra     valid_1st_press         ;if =0 this is a valid 1st press
        
multi_press:
        ldaa    two_press_timer         ;Check time since last press
        cmpa    #5
        bls     svirq_rti                 ;if time < 120ms, return (debouncing)

        cmpa    #10
        bls     valid_2nd_press           ;if time < 300ms, it is good

        rti                             ;Else, let main loop to deal with it
        

valid_2nd_press:                        ; flag second press
        ldaa    #2
        staa    IRQ_flag
        ldaa    #1                      ;restart the timer
        staa    two_press_timer         
        jsr     click
        rti

valid_1st_press:
        ldaa    #1
        staa    IRQ_flag                ;flag one valid press
        staa    two_press_timer         ;start TOF counter for many presses
        jsr     click

svirq_rti:
        rti


;*******************************************************************
;* SVTOF - Timer Overflow interrupt service routine
;*
;* Called every time the main 16-bit timer overflows (every 33 ms).
;* This routine uses various counters to extend the range of the
;* main timer.
;*
;*        --- Main Timer extension counter usage ---
;*
;* Latched (only count if non zero):
;*
;*  one_sec         (8-bit)  --   IR Learn
;*  two_secs        (8-bit)  --   Used to expand mode key functionality
;*  three_secs      (8-bit)  --   Bar graph, Features
;*
;*  lat_ovcnt1      (8-bit)  --   IR Rx (100 ms)
;*  ir_tout         (8-bit)  --   IR time-out
;*  two_press_timer (8-bit)  --   Front Panel double-click timer.
;*  VFD_time_out   (24-bit)  --   VFD standby/screen saver time-out.
;*  screen_status1  (8-bit)  --   BigNums timer & screen restoration flag.
;*                                     0 = timer stopped, no action.
;*                                     1 = start timer.
;*                                    $ff= timer stopped, restore old screen.
;*                                    $fe= timer stopped, restore Main screen & init.
;*  screen_status2  (8-bit)  --   Mode indicator screen timer.
;*  screen_status3  (8-bit)  --   Longer flash screen timer for certain screens.
;*  sticky_dts_ctr (16 bit)  --   Sticky DTS countdown timer.
;*  sticky_ac3_ctr (16 bit)  --   Sticky AC3 countdown timer.
;*
;* Free-running:
;*
;*  ovcnt1          (8-bit)  --   IR Rx
;*  ovcnt2          (8-bit)  --   Used for VU meter time-out.
;*  noise_seq_timer (8-bit)  --   Determines Noise Sequencer rotation rate.
;*  two_press_timer (8-bit)  --   Time out for two presses
;*  auto_set_timer  (8-bit)  --   Determines Auto Level and Delay checking. 
;*
;***
SVTOF:

;*** Latched counters first **

;** 1 second...
        ldaa    one_sec                 ;Latched counter (only counts if not 0)
        beq     svtof_0                 ;Check if 1 second timer on 

        inc     one_sec                 ;Increment if non-zero.
        ldaa    one_sec
        cmpa    #30                     ;Check for 1 seconds elapsed
        bls     svtof_0

        clr     one_sec                 ;If so, clear 1 sec timer

;** 2 seconds...
svtof_0:
        ldaa    two_secs                ;Latched counter (only counts if not 0)
        beq     svtof_1                 ;Check if 2 second timer on 

        inc     two_secs                ;Increment if non-zero.
        ldaa    two_secs
        cmpa    #60                     ;Check for 2 seconds elapsed
        bls     svtof_1

        clr     two_secs                ;If so, clear 2 sec timer
        ldaa    #$55            ;<<<<
        staa    dec_key_save    ;<<<<

;** 3 seconds...
svtof_1:
        ldaa    three_secs              ;Latched counter (only counts if not 0)
        beq     svtof_2                 ;Check if 3 second timer on 

        inc     three_secs              ;Increment if non-zero.
        ldaa    three_secs
        cmpa    #90                     ;Check for 3 seconds elapsed
        bls     svtof_2

        clr     three_secs              ;If so, clear 3 sec timer

;** 100 ms...
svtof_2:
        ldaa    lat_ovcnt1              ;Latched timer (only counts if not 0)
        beq     svtof_3

        inc     lat_ovcnt1              ;Increment if non-zero
        ldaa    lat_ovcnt1
        cmpa    #3                      
        bls     svtof_3

        clr     lat_ovcnt1              ;At 100 ms, reset lat_ovcnt1 timer.


;** VFD standby time out...
svtof_3:
        ldaa    VFD_time_out+2          ;Latched timer (only counts if not 0)
        bne     .vstby_count

        ldaa    VFD_time_out+1
        bne     .vstby_count

        ldaa    VFD_time_out
        bne     .vstby_count
        bra     .tof_0

.vstby_count:
        inc     VFD_time_out+2          ;Increment the 24-bit VFD time-out counter.
        bne     .tof_0                  ; (l's byte overflows every 8.4 sec).

        inc     VFD_time_out+1          ;The middle byte overflows every 2148 seconds
        bne     .tof_0                  ; (approx. every half-hour).

        inc     VFD_time_out            ;The upper byte counts elapsed half-hours.


;** Long/short lamp time-out...
.tof_0:
        ldaa    lamp_status             ;If lamp off, don't count
        beq     svtof_4

.tof_2: ldaa    theater                 ;theater=1 is short time out
        bne     .tof_3                  

        ldaa    lamp_time_out
        cmpa    #lamp_long              ;If at long time-out, stay there
        bra     .tof_4  

.tof_3: ldd     lamp_time_out+1         ;bottom 16 bits.
        cpd     #lamp_short
.tof_4: bhi     svtof_4                 ;If at short time_out, stay there

        inc     lamp_time_out+2         ;Increment the 24-bit lamp time-out counter.
        bne     svtof_4                 ; (l's byte overflows every 8.4 sec).

        inc     lamp_time_out+1         ;The middle byte overflows every 2148 seconds
        bne     svtof_4                 ; (approx. every half-hour).

        inc     lamp_time_out           ;The upper byte counts elapsed half-hours.


;** Big Nums and screen restoration...
svtof_4:
        ldaa    screen_status1
        beq     svtof_5                 ;If zero, ignore

        cmpa    #$ff                    ;If negative, ignore
        beq     svtof_5

        cmpa    #$fe
        beq     svtof_5

        inc     screen_status1
        ldaa    screen_status1
        cmpa    #50                     ;Check for 1.6 second time-out
        bls     svtof_5

        ldaa    #$ff
        staa    screen_status1          ;Flag restoration of old screen


;** IR time-out...
svtof_5:
        tst     ir_tout                 ;Deal with IR time-out if necessary
        beq     svtof_7

        dec     ir_tout                 ;Count down
        bne     svtof_7

        ldaa    b_state                 ;If we reach zero, set IR states
        staa    t_state


;** Mode indicator...
svtof_7:
        ldaa    screen_status2
        beq     svtof_8                 ;If zero, ignore

        cmpa    #$ff                    ;If negative, ignore
        beq     svtof_8

        cmpa    #$fe
        beq     svtof_8

        inc     screen_status2
        ldaa    screen_status2
        cmpa    #70                     ;Check for 2.8 second time-out
        bls     svtof_8

        ldaa    #$ff
        staa    screen_status2          ;Flag restoration of old screen


svtof_8:
        ldaa    enc_vol_slow            ;If clean, don't time
        beq     svtof_9 
        inc     slow_enc_timer          ;Update slow timer
        ldaa    slow_enc_timer
        cmpa    #4                      ;Check for time out
        bls     svtof_9 
        clr     slow_enc_timer
        clr     enc_vol_slow            ;Flag that volume adjust is allowed


svtof_9:
        ldaa    screen_status3
        beq     svtof_10

        cmpa    #$ff
        beq     svtof_10

        inc     screen_status3
        ldaa    screen_status3
        cmpa    #100                    ;Check for longer ( 4 s) time-out
        bls     svtof_10        

        ldaa    #$ff
        staa    screen_status3


svtof_10:
        ldx     sticky_dts_ctr
        beq     svtof_11                

        dex
        stx     sticky_dts_ctr          ;Count down sticky dts timer

svtof_11:
        ldaa    err_star_ctr
        beq     svtof_12

        deca
        staa    err_star_ctr            ;Count down error star timer

svtof_12:
        ldx     sticky_ac3_ctr
        beq     svtof_13

        dex
        stx     sticky_ac3_ctr          ;Count down sticky AC3 timer


;** Free running 8-bit counters...
svtof_13:
        inc     ovcnt1
        inc     ovcnt2
        inc     noise_seq_timer
        inc     two_press_timer         ;Time out for two presses
        inc     auto_set_timer

svtof_end:
        ldx     #regbase
        bclr    tflg2,x,#%01111111
        rti


;*********************************************************************
;* SVRTI - Real time interrupt service routine
;*
;* Called at 30.5Hz = every 32.77ms
;*
;*
;***

SVRTI:

.rti_analog_clip:
        ldx     #regbase
        ldaa    porte,x
        anda    #%00010000              ;Get Sig. Anlg clip indicator
        cmpa    clippage                ;See if same as before
        beq     .rti_rec_stat           ;If same, do nothing

        staa    clippage                ;Save new value
        ldaa    #1                      ;Flag screen updates
        staa    update_screen12

.rti_rec_stat:
        ldaa    #17
        jsr     RD_CS4226               ;Get receiver status byte (17)
        tab
        andb    #%10000000              ;Get CV bit
        beq     .do_4226_reads          ;If CV=zero, go ahead and read
        jmp     .svrti_rti              ;If CV=1, data is updating, so skip reads

.do_4226_reads:
        ldab    rs_imag                 ;Get old value of receiver status byte.
        staa    rs_imag                 ;Store new value of receiver status byte.

        cba                             ;Check for changes
        beq     .reads_same_1

        ldab    #1                      ;Flag changes
        stab    update_screen12
        bra     .reads_same_10

.reads_same_1:                          ;At this stage, rs_imag is the same
        andb    #%00001000              ;Get V flag
        beq     .reads_same_10          ;If still off, all ok

                                        ;If V still on, take star away
        ldy     #screen_image           ;if it is still showing
        ldab    26,y
        cmpb    #'*'
        bne     .reads_same_10          ;If no star up, do nothing

        ldab    #2                      ;Otherwise flag that star has to be
        stab    update_screen12         ; cleared
                                       

.reads_same_10:
        anda    #%00010000              ;Get PLL locked bit
        cmpa    locked                  ;Check if locked status has changed  
        beq     .rti_ac3_check          ;if same, continue with reads    

        tsta
        bne     locked_on               ;If into no_lock, all ok


locked_on:
        staa    locked
        jsr     need_to_update

.rti_ac3_check:
        ldaa    locked                  ;PLL locked bit
        beq     .rti_ac3_check2         ;If locked, go ahead
        jmp     .svrti_rti              ;If not locked, do no more reads!

.rti_ac3_check2:
        ldaa    AC3_in_proc
        bne     .rti_reads_misc         ;If in AC3, go right ahead

        ldaa    #2                      ;If not in AC3, must check if any
                                        ;changes in bitstream have occurred
                                        ;to avoid AC3 hiss

        jsr     RD_CS4226               ;Get converter control byte (2)

        anda    #%00010000              ;Get AC-3/MPEG2/New-DTS auto detect flag.
        beq     .rti_reads_misc         ;If not AC3 here go on

        ldaa    #48
        staa    zoran_cntr              ;Force a main loop zoran check
        jmp     .svrti_rti              ;Exit RTI now to avoid AC3 hiss!!


.rti_reads_misc:
;************* The following stuff is done every 1/2 second *************
;*
;* Format of CS0 byte in channel status block (CS4226 byte 18):
;*
;*           bit:  7       6       5       4       3       2       1       0
;*
;* CONSUMER:       |-Mode--|       |---Emphasis----|      Copy   /Audio  Pro=0
;*
;* PROFESSIONAL:   |--fs---|     /Lock     |---Emphasis----|     /Audio  Pro=1
;*
;*       (/Audio: 0 = audio, 1 = data;  Copy: 0 = inhibit, 1 = permitted)
;* 
;* Note: CDROMs sometimes have normal audio tracks in addition to 
;*       one or more data tracks. The /Audio flag is used sample-by-sample, 
;*       as appropriate.
;*
;*
;*
;* Format of CS3 byte in channel status block (CS4226 byte 21):
;*
;*           bit:  7       6       5       4       3       2       1       0
;*
;* CONSUMER:       |----------fs-----------|       |Clk Acc|       |-Resvd-|
;* 
;*
;*** 
.rti_reads2:
        inc     rti_timer
        ldaa    rti_timer
        cmpa    #15                     ;Read CS4226 status at 30.5/15 Hz.
        bhi     .rti_reads2_1
        jmp     .svrti_rti

.rti_reads2_1:
        clr     rti_timer
        ldaa    locked
        beq     .rti_reads2_2           ;If locked, go on to do reads
        jmp     .svrti_rti              ;If not locked, no more 4226 reads

.rti_reads2_2:
        ldaa    PCM_in_proc             ;Check if PCM
        bne     .rti_reads2_3           ;If PCM, cs0 is read in "get_auto_flags"
                                        ;If not PCM, we must read here!!!

        ldaa    #18
        jsr     RD_CS4226               ;Get Rx CS0 channel Status byte (18)
        cmpa    cs0_imag
        beq     .rti_reads2_3           ;If same, all ok

        staa    cs0_imag                ;Store new flags (includes DATA flag)
        ldaa    #1
        staa    update_screen12         ;Flag changes

.rti_reads2_3:
        jsr     emphasis_check          ;Always check for Emphasis
                                        ;and do appropriate things...

        jsr     freq_check              ;Check frequency and do FSEL

        ldaa    #48                     ;Force main loop Zoran reads asap!
        staa    zoran_cntr              ;(avoids possible AC3 hiss)


;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
;^^^^^^^^^^^ Everything above here is done every 1/2 second ^^^^^^^^^^^^^^^
;^^^^^^^^^^ Everything below here is done every 1/30th second ^^^^^^^^^^^^^
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.svrti_rti:
        ldx     #regbase
        ldaa    porte,x
        anda    #%00001000              ;Get HDCD sense information
        cmpa    hdcd_on                 ;See if state has changed
        beq     .rti_reads5             ;if same, continue with reads

        staa    hdcd_on
        bset    icon_flag,#%00000001    ;Flag that an icon needs to be displayed

.rti_reads5:
        ldx     #regbase
        bclr    porta,x,#%00100000      ;Protect IR Tx diodes
        bclr    tflg2,x,#%10111111      ;Write a 1 to RTIF to enable next RTI.

;%% Deal with ES/SL kill in 2-ch. Pass-Thru mode:
        ldaa    curr_pass_mode
        cmpa    #2                      ;Two-channel Pass-Through input A8?
        bne     .rti_chk_kill 

        jsr     kill_es_sl_on           ;If yes, apply kill to ES/SL.
        bra     .rti_out

.rti_chk_kill:
        ldaa    kill_status             ;If no, and if system not already killed,
        bne     .rti_out

        jsr     kill_off                ;Unkill ES/SL

.rti_out:
        rti          ;**Return from RTI interrupt service***


;*********************************************************************
;* SVXIRQ - Power Fail interrupt service routine
;*
;* Called whenever AC power is missing for more than 1 or 2 half-cycles,
;* i.e., 8 to 16 ms after AC power fail. 
;*
;***

SVXIRQ:
        ldaa    #%00000000
        staa    DAC8_latch1             ;Assert KILL relays & PCM1732U MUTE, RESET.
                                        
        ldaa    #%00000011
        ldx     #regbase
        staa    porta,x                 ;Turn off IR Tx, screen relay, EL lamp.
                                           ;Reset DSPs, power-down Signature A/D.
        ;%% Last hatches battened down...

        jsr     beep1                   ;Buefuss' last gasp!
        stop                            ;R.I.P.
        bra     *                       ;...in case of further interrupt?


;**************************************************************************
;* Dummy service routine for unused interrupts:

SVSPI:
SVPAIE:            
SVPAO:
SVTOC3:
SVTOC2:
SVTIC3:
SVTIC2:
SVSWI:
SVILLOP: 
SVCOP:  
SVCLM:  rti




;**********************************************************************
;*
;* Reset Vector for Special Test mode (must be at $bffe-bfff)
;*
;**********************************************************************

Sp_reset:       Section 22

        dc.w     EOS_start




;***********************************************************************
;*
;* Interrupt vector table...
;*
;***********************************************************************

Int_vecs:       Section  23

Vsci:   dc.w     SVSCI       ;SCI interrupt service (RS232 character input)
Vspi:   dc.w     SVSPI
Vpaie:  dc.w     SVPAIE
Vpao:   dc.w     SVPAO
Vtof:   dc.w     SVTOF       
Vtoc5:  dc.w     SVTOC5 
Vtoc4:  dc.w     JTOC4
Vtoc3:  dc.w     SVTOC3      
Vtoc2:  dc.w     SVTOC2
Vtoc1:  dc.w     SVTOC1    
Vtic3:  dc.w     SVTIC3
Vtic2:  dc.w     SVTIC2
Vtic1:  dc.w     SVTIC1    
Vrti:   dc.w     SVRTI       ;Real Time Interrupt service
Virq:   dc.w     SVIRQ       ;Front panel button push
Vxirq:  dc.w     SVXIRQ      ;Power fail
Vswi:   dc.w     JSWI       
Villop: dc.w     SVILLOP
Vcop:   dc.w     SVCOP
Vclm:   dc.w     SVCLM
Vrst:   dc.w     EOS_start   ;Cpu reset controlled by low-voltage inhibit (LVI).device.


        end
