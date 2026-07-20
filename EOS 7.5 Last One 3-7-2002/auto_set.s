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
;   auto_set.s
;
;*************************************************
;*                                               *
;*     S T A R T   O F   A U T O   S E T U P     *
;*                                               *
;*   Some routines in this section also used by  *
;*     noise sequencer and static noise modes    *
;*                                               *
;*************************************************

autos_flag:     equ     0

        XDEF    SPLdB,deciSPL
        XDEF    aver_flt,switch_SPL,ref_level
        XDEF    tweak_vol,crack_channel,prev_peak,max_time,auto_stage
        XDEF    max_time2

        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"

auto_vbl:       Section   44

;** Automatic volume/delay adjustment
ref_level:      ds.b     1       ;Setpoint for automatic speaker level adjustment.
auto_stage:     ds.b     1       ;Automatic adjustment stage.
max_ampl:       ds.b     1       ;Peak amplitude during delay measurement.
dly_cnt:        ds.b     2       ;Current delay step count during measurement
prev_peak:      ds.b     1       ;Current crack delay measurement
max_time:       ds.b     2       ;Time of occurrence of individual peaks
max_time2:      ds.b     2       ;Storage of time for one polarity
auto_vol:       ds.b     1       ;Flag to indicate full auto service (incl volume)
                ds.b     1    
vol_change:     ds.b     2       ;Volume adjustment "servo" step
colddef_mod:    ds.b     2


auto_set:       Section 45

;**********************************************************************
;*
;*              MIC SIGNAL MOVING AVERAGE ROUTINE
;*
;* This routine reads the autosetup microphone and does one iteration
;* of a k = 2^14 = 16384 sample boxcar moving average. It is called by
;* the main loop at about 10 kHz.
;*
;* The accumulator (vol_acc) is multiplied by (K-1)/K where K is the
;* number of samples in the moving average. The input data is shifted
;* to adjust the gain and then added to the accumulator, vol_acc.
;*
;* A companion routine called SPLdB can access the upper byte of
;* the 3-byte vol_acc at any time, in order to convert the smoothed
;* microphone signal average to dB for display on the VFD.
;*
;* The current code averages 2^14 samples, which is 1.6 seconds at a
;* sampling rate of 10,000 samples per second.
;*
;*
;* We want the adjustment to be done at SPL = 75 dB and the mic amp
;* gain should be adjusted so that the volume accumulator shows %00100000.
;* The strategy is:
;*  -- Choose reference SPL level (Currently, 80 dB uses a ref_level of 22)
;*  -- Adjust front left to ref. level
;*  -- Initialize next channel to the adjusted front left level 
;*      and adjust it in turn to reference level   
;*  -- Repeat for all channels
;*
;**********************************************************************

scratch:        equ     0       ;16-bit local stack variable.


aver_flt:
        pshy
        des
        des                     ;Allocate space for local variables on stack.
        tsy

        clra
        ldab    vol_acc         ;Top byte of vol_acc extended to 16 bits.
        lsld
        lsld
        lsld

        std     scratch,y

        ldd     vol_acc+1
        subd    scratch,y
        std     vol_acc+1
        bcc     done_0

        dec     vol_acc         ;vol_acc - vol_acc/2^13

done_0: ldx     #regbase
        brclr   adctl,x,#%10000000,* ;Wait until valid data in result registers
        bclr    adctl,x,#%10000000   ;Pseudo-clear CCF to initiate new scan cycle

        ldab    adr2,x  
        clra                    ;Get 8-bit mic signal & sign extend to 16 bits.

        lsld
        lsld                    ;Adjust filter gain by padding the data with zeros.
        lsld
        addd    vol_acc+1       ;Add it to lower 2 bytes of accumulator.
        std     vol_acc+1
        bcc     done_1          ;If carry set,
        inc     vol_acc         ; increment upper 8 bits of result.
        bvc     done_1          ;If no overflow from msb, then continue...

;What does the following line buy us?
;What happens if overflow occurs?
;Is this the infamous Dan Sharpe SHORTED MIC lock-up problem?
        ldaa    #$ff            ;Else set vol_acc to indicate overflow...
        staa    vol_acc

done_1: ins
        ins                     ;Deallocate local variables.
        puly
        rts                 ;** Return **
        

;********************************************************************
;*
;*                    C O M P U T E   S P L
;*
;* Accesses local variables on stack using Y, leaving X register
;* available for the idiv instruction.
;*
;* This routine computes 64 * log2(x) + 528, which is read as
;* 6.4 * log2(x) + 52.8 dB or approx. 20 * log10(x) +52.8 dB
;* when the VFD decimal point is moved one position left,
;* where x is the lowpass filtered microphone signal.
;*
;*  x = 256 --> 512.   Move decimal point to left to get 51.2 dB
;*                     Add 487 (i.e., 48.7 dB) and move decimal
;*                     point to left to get 99.9 dB.
;*
;*  x = 2   --> 64.    I.e., 6.4 dB. Add 48.7 to get 55.1 dB.
;*
;* Note: (64log2(x)/10) is approx. equal to 20log10(x), being
;*       high by 6% (= 1.06 scaling factor). So the procedure
;*       is compute 64log2(x) and the decimal point is moved
;*       to get an SPL with a 1/10 dB readout.
;*
;* Execution time = 129 us, including call.
;*
;* Zero signal is converted to the smallest signal, which is 1.
;*
;* Input: 8-bit unsigned filtered mic. signal in B.
;* Result: Scaled SPL value is in D.
;*
;***

hiBitPos: equ   0               ;1 byte
mic_flt:  equ   1               ;2 bytes
J_:       equ   3               ;2 bytes
Lscratch: equ   5               ;2 bytes
L0:       equ   7               ;2 bytes

SPLdB:  pshx
        pshy

        tsy                     ;Allocate space for local variables on stack.
        xgdy
        subd    #9
        xgdy
        tys                     ;Set y to point to local variables.

        clra                    ;Extend unsigned 8-bit input to 16 bits.
        tstb
        bne     mic_sav         ;If not zero, continue...

        incb                    ;Else, set to smallest number since can't do log(0)..
mic_sav:
        std     mic_flt,y       ;Save.

;%% Zero-order estimate (L0):
        tba
        ldab    #8              ;Find position of highest bit...
hi_bit_loop:
        decb
        cmpb    #0
        beq     hidone          ;Exit when done...

        asla
        bcc     hi_bit_loop

hidone: stab    hiBitPos,y      ;Save high bit position.
        clra                    ;Convert to 16 bits.
        asld
        asld
        asld
        asld                    
        asld
        asld                    ;x64.
        std     L0,y            ;L0 = k*(high bit pos'n), k=64

;--- Compute J = 2^(high bit position):
        clra
        ldab    hiBitPos,y      ;Get positon of highest bit
        sec
J_loop: rola                    
        decb                     
        bge     J_loop          
                               
        tab
        clra
        std     J_,y            ;Convert J to 16 bits & save.

;%% Calculate 1st order correction:
        ldd     mic_flt,y
        subd    J_,y            ;D = mic_flt - J
        asld
        asld
        asld
        asld
        asld
        asld                    ;D = k*(mic_flt - J), k=64
        std     Lscratch,y      ;Save

;--- Catch powers of 2:
        bne     continue_        

        ldd     L0,y            ;Return k*L0 to caller.
        bra     finished_

continue_:
        ldd     mic_flt,y
        addd    J_,y            ;D = mic_flt + J
        xgdx                    ;Transfer to X, ready for idiv
        ldd     Lscratch,y      ;D = k*(mic_flt - J)
        idiv                    ;X = D/X = k*(mic_flt - J)/(mic_flt + J)
        xgdx                    ;D = k*(mic_flt - J)/(mic_flt + J)
        std     Lscratch,y      ;Save k*(mic_flt - J)/(mic_flt + J)
        asld                    ;D = 2*k*(mic_flt - J)/(mic_flt + J)
        addd    Lscratch,y      ;D = 3*k*(mic_flt - J)/(mic_flt + J)
        addd    L0,y            ;D = k*L0 + 3*k*(mic_flt - J)/(mic_flt + J)

finished_:
;%% Scale output to match desired dB scale:
        addd    #528            ;Add 52.7 dB to normalize full scale to 99.9 dB.
                                ;Bumped up to 52.8 to allow 75.0 dB SPL on readout.
        cpd     #999
        bls     finish_1_spl
        ldd     #999

finish_1_spl:
        tsy                     ;Deallocate local variables.
        xgdy
        addd    #9
        xgdy
        tys

        puly
        pulx
        rts


;********************************************************************
;*
;* deciSPL - Subroutine to convert the 16-bit binary SPL dB value
;*           to a 3 digit decimal dB volume NN.N (decimal point
;*           is implied).
;*
;* Accepts 16-bit binary SPL dB input in D.
;* Uses 3 byte variable SPL_buf for decimal result.
;*
;* Preserves all registers.
;*
;***
deciSPL:
        pshx                    ;Save registers.

        ldx     #100
        idiv                    ;D/100 -> X; r -> D.
        xgdx                    ;Save r in X; 100s digit in D (A:B).
        stab    SPL_buf         ;Store 100s digit as tens dB in volume buffer.
        xgdx                    ;r back to D.
        ldx     #10
        idiv                    ;D/10 -> X; r in D (B is units digit).
        stab    SPL_buf+2       ;Store 1s digit as fractional dB in volume buffer.
        xgdx                    ;10s digit to D (A:B).
        stab    SPL_buf+1       ;Store 10s digit as 1s dB in volume buffer.

        pulx
        rts             ;** Return **



;*****************************************************************
;*
;* Tweaking of Volume to achieve a Reference Level
;*
;***

vol_offset:                     ;Offsets into volume variable space
        dc.b    0,8,2,6,4       ;LF,C,RF,RS,LS


tweak_vol:
        ldy     #vol_offset
        ldab    noise_channel
        cmpb    #1              
        bne     tweak_1

        ldab    #6
tweak_1:
        decb
        decb
        aby
        ldab    0,y
        ldy     #vcp_l
        aby                     ;Get current attenuator value

        ldd     0,y
        bge     .get_ad

tweak_2:
        jmp     abort_auto_set

.get_ad:
        ldaa    vol_acc         ;Get mic A/D level
	suba    ref_level       ;Get difference to ref level
	tsta
        bmi     get_up          ;If volume is lower than ref, bring it up
                                ; or if larger, bring volume down.
get_dn: jsr     test_for_same   ;Check if in range.
        tsta
        bne     tweaked         ;If so, vol is ok.

        jsr     set_diff        ;Set up adjustment step (currently 0.5 dB).    
        ldd     0,y             ;Get current atten.
        addd    vol_change      ;Add change to current atten.
	cpd     #vc_min
        bhs     setting_ok      ;If volume smaller than min volume, go out!

        std     0,y             ;Otherwise save result, and continue...
	jmp     adj_vol

get_up: nega                    ;Take abs value of difference
        jsr     test_for_same   ;See if in range of target
        tsta
        bne     tweaked         ;If so, vol is ok

        jsr     set_diff        ;Set up adjustment step (currently 0.5 dB).
        ldd     0,y             ;Get current atten.
        subd    vol_change      ;Subtract change from current atten.
        blt     tweak_2         ;If overflow over above 0 dB, do warble tone!

        std     0,y             ;Otherwise save result, and finish...
adj_vol:
        jsr     unpack_vol      ;Compute composite volumes and set them
        jsr     display31
setting_ok:
	rts                  ;** Return **


tweaked:
        inc     auto_ctr
        ldaa    auto_ctr
        cmpa    #3
        bls     tweaked_rts

tweaked_done_all:
        ldaa    #1              ;Flag all ok!
        staa    auto_success
        clr     auto_ctr

        ldaa    noise_channel
        cmpa    #2              ;Check if LF being done.
        bne     tw_1

        ldd     vcp_l
        std     vcp_r           ;Start RF at same volume as LF.
        bra     tweaked_update

tw_1:   cmpa    #5              ;Check for RS being done.
        bne     tweaked_rts

        ldd     vcp_rs
        std     vcp_ls          ;Start LS at same volume as RS.
        std     vcp_es    ;>>>
tweaked_update:
        jsr     unpack_vol
        jsr     display31
tweaked_rts:
        rts


;********************************************************************
;* Test if mic level is in range (Updated for DAC-8)
;*
;* Try changing checking to 0.5 dB later.
;*
;***

test_for_same:
        cmpa    #2              ;Check if within 2 * 0.5 dB
        bls     tweaked_flag

tweaked_no_flag:
        clra
        rts

tweaked_flag:                           ;Flag that we are in range
        ldaa    #$ff
        rts
        


;**********************************************************************
;* Set up Volume step of 0.5 dB (Updated for DAC-8)
;*
;* The original idea for this routine was to accelerate the
;* rate of volume changes during auto level, starting with bigger
;* volume steps and finishing off with the smallest. Currently,
;* the step size is fixed at minimum.
;*
;***
set_diff:
        ldd     #1                       ;0.5 dB
        std     vol_change
        rts             



;***********************************************************************
;*
;*              A U T O   D E L A Y   R O U T I N E S
;*
;* IMPORTANT NOTE: If the memory structure of the vc_s, vcp_s, cor_s, etc.,
;* is ever modified, the 48 offset on y may need to be changed. It represents
;* the address offset between the vcp_s and the secondary volume storage
;* area, vc_2_s.
;*
;***
crack_offsets:                          ;Offsets into volume variable space
        dc.b    0,8,2,6,4               ;LF,C,RF,RS,LS

crack_channel:
        jsr     quiet_spkrs             ;Set all attenuators minimum vol.
        ldab    noise_channel           ;Compute offset into volume space...
        decb                            ;(Offset lookup table is 0-relative)
        ldy     #crack_offsets
        aby
        ldab    0,y                     ;Get channel offset
        ldy     #vcp_l
        aby                             

        cmpb    #0
        beq     front_cracks

        cmpb    #2
        beq     front_cracks

crack_OK:
        ldd     48,y  ;!!!! 48 o/s is wrong (should be 64 for vc_2_) but ut works!         
        bra     crack_contd

front_cracks:
        ldd     48,y  ;!!!! 48 o/s is wrong (should be 64 for vc_2_) but ut works!                  
        subd    #15                     ;Subtracting makes LF or RF louder.

crack_contd:
        std     0,y                     ; and adjust to crack vol.
        jsr     unpack_vol              ;Set volume control to this value.
        jsr     unmute_all
        delay   200*10


;**************************************************************
;*
;* TICK_TACK ROUTINE
;*
;* The philosophy of polarity for AutoPhase:
;* Volume levels and thresholds are tuned so that we do not pick up
;* spurious whiskers. We send out the following pulse on all channels,
;* directed to each channel in turn by manipulating the volume controls:
;*
;*       /\                      
;*      /  \                   
;* -----    ----- 1 second delay --------    -----------...
;*                                       \  /
;*                                        \/
;*
;*       2ms                              2ms
;*   +ve polarity                     -ve polarity
;*     (first)                          (second)
;*
;*
;* Speaker response puts out a small pulse to begin with and a larger
;* reversed pulse after that.  We set the threshold to avoid this small
;* precursor and catch only the high-amplitude positive edge.
;* We know which pulse we sent out and which one succeeds. This relationship
;* determines the speaker phase.
;* In the event that both pulses succeed, we take the later one
;* (since the earlier one is the small precursor and is speaker dependent)
;*
;*
;***
tick_tack:
        rtint   OFF                     ;Avoid possible 2ms RTI interrupt
                                        ;For max precision do we need sei as well?
        ldaa    polarity
        beq     pos_polarity

;The following code gets commented out for new Z2 EPROM:
;neg_polarity:                           ;Send out negative polarity pulse
;        ldaa    #$40
;        bra     set_polarity
;
;pos_polarity:
;        ldaa    #$00
;
;set_polarity:
;        staa    crack_lst+6             ;PAR5 sets polarity of crack
;        ldy     #crack_lst
;        jsr     spi_cmd_2               ;Send crack out on Z2


;The following code gets uncommented for the new Z2 EPROM:
neg_polarity:                           ;Send out negative polarity pulse
        ldaa    #$80
        bra     set_polarity

pos_polarity:
        ldaa    #$00

set_polarity:
        staa    crack_lst+5             ;PAR4 sets polarity of crack
        ldy     #crack_lst
        jsr     spi_cmd_2               ;Send crack out on Z2



;----------------------------------------------------------------+
; CRACK LATENCY:                                                 |
        delay   148 ;159     ;Delay 15.9 ms for Ovation-8/Signature-8 |
;;;;;;;;delay   164     ;Delay 16.4 ms for Ovation/Signature     |
;;;;;;;;delay   142     ;Delay 14.2 ms for Encore                |
;                                                                |
;----------------------------------------------------------------+

        clr     max_ampl                ;Ready for peak detection
	ldd     #0        
        std     dly_cnt                 ;Clear delay measuring counter

; A/D registers are updated at rate E/128 = 15.6 kHz.
; We use every 2nd measurement, so time step is 0.128 ms,
;  which corresponds to 0.04403 m (speed of sound is assumed
;  to be 344 m/s at 20 degrees Celsius or 68 degrees Farenheit).
; We collect 256 samples, spanning 32.768 ms, or 11.272 m.
; Measurement count is multiplied by .440 to get distance in
;  0.1 m steps (0.440 = 11.272 * 10 / 256 = 113/256). 
; Measurement accuracy is about 0.1 m, or two time steps.
; The measurement are affected by air temperature. The temperature
;  coefficient of the acoustically-measured distance is about
;  -0.2 % per degree Celsius (0.02 m in 10 m). The relationship
;  obeys the formula D = Do * sqrt(t / 293 K), where Do is the
;  acoustically measured distance, and D is the corrected distance.
;  At 293 K, or 20 degrees Celsius, there is no correction required.
; Despite the temperature calibration problem, the present
;  acoustically measured distance ALWAYS sets the correct delays
;  for the particular air temperature.
; Distances are stored with a resolution of 0.1 m  (1/3').


        ldx     #regbase
        ldd     tcnt,x
        std     dly_cnt                 ;Save time now

read_ad:       
        ldx     #regbase
        brclr   adctl,x,#%10000000,*    ;Wait until valid data in result registers
        bclr    adctl,x,#%10000000      ;Pseudo-clear CCF to initiate new scan cycle

        ldab    adr2,x                  ;Get sample into B.
        cmpb    max_ampl                ;If smaller than current peak, 
        bls     not_peak                ; keep as is...

is_peak:
        stab    max_ampl                ;Store new peak.
        cmpb    #67                     ;Check for high value   
        bhs     peak_found

not_peak:
        ldx     #regbase
        ldd     tcnt,x                  ;Get current time
        subd    dly_cnt
        cpd     #58139                  ;See how many cycles elapsed
        bls     read_ad                 ;If not enough, read more
        bra     more_cracks             ;Time-out so do another crack

peak_found:
        ldx     #regbase
        ldd     tcnt,x
        subd    dly_cnt                 ;Find duration of delay (in cycles)
        bclr    porta,x,#%01000000 


;* A contains delay/256:
        ldab    #14                     ;Dump low byte (divide by 256)
        mul
        lsrd
        lsrd
        lsrd
        lsrd
        lsrd                            ;(delay/256)*(14/32) = dist in 0.1m
        stab    max_time                
        cmpb    prev_peak               ;Compare to previous measurement
        beq     crack_okay              ;If same, flag success


;* Unequal hits recorded
        stab    prev_peak               ;Save this result for next time around

more_cracks:
        inc     auto_ctr                ;One more failure
        clr     auto_success            ;Flag no success

        ldaa    auto_ctr
        cmpa    #max_cracks
        blo     more_cracks_rts         ;If few cracks, keep cracking


;* Maxed out on number of cracks sent - decide which polarity has failed
        ldaa    polarity              
        bne     cracks_neg_fail         ;See which polarity has failed

cracks_pos_fail:
        inc     polarity                ;Do next polarity
        clr     auto_ctr
        clr     prev_peak
        clr     max_time2               ;1st pulse has failed
                                        ;so go back ready for -ve pulses
more_cracks_rts:
        rts

cracks_neg_fail:
        ldaa    max_time2               ;If this slot is zero, both pulses
        beq     more_cracks_rts         ;have failed and main loop will deal
                                        ;with it (and will abort)

        ldaa    #1                      ;2nd failed: flag success since
        staa    auto_success            ;1st was okay 
                                        ;max_time contains the result
        clr     auto_ctr                
        clr     prev_peak
        bra     pol_revd                ;Speaker is reversed in this case


;* Successful reception of pulses
crack_okay:
        clr     auto_ctr
        clr     prev_peak               ;Clear for next time around

        inc     polarity
        ldaa    polarity                ;See which pulse was successful
        cmpa    #2
        bhs     second_crack_ok         ;2nd successful


        ldaa    max_time                ;1st successful
        staa    max_time2               ;Save time for this crack
        rts


second_crack_ok:
        ldaa    #1
        staa    auto_success            ;Flag success

        ldaa    max_time                ;2nd pulse (just done)
        ldab    max_time2               ;1st pulse (may be 0 if 1st failed)
        beq     pol_okay                ;If first failed, polarity is ok


;* At this point, both pulses have been detected.
;* We could have detected a reflection here, so make sure the pulses
;* are sufficiently close. If not, discard the later one.

        cba                             ;See which is longer
        bmi     first_longer

second_longer:
        sba                             ;Find difference
        cmpa    #3                      
        bls     pol_okay                ;If close enough, take 2nd pulse
                                        ;and polarity +ve

        stab    max_time                ;If too far, take 1st pulse,
        bra     pol_revd                ;and polarity is reversed in this case


first_longer:
        sba                             
        nega                            ;Find (positive) difference
        cmpa    #3
        bhi     pol_okay                ;If too far, take 2nd pulse (already                                       
                                        ;lined up) and polarity is ok

        stab    max_time                ;If close enough, take 1st pulse
        bra     pol_revd                ;and polarity -ve

pol_okay:                           
        clra                            ;Flag polarity ok.
        bra     flag_pol

pol_revd:                               ;If second pulse shorter, pol is rev'd
        ldaa    #1

flag_pol:
        jsr     flag_polarity           ;0=all ok ; 1=speaker reversed

        ldaa    noise_channel
        cmpa    #1
        beq     lf_distance

        cmpa    #2
        beq     cr_distance

        cmpa    #3
        beq     rf_distance

        cmpa    #4
        beq     rs_distance

ls_distance:
        ldaa    LSRS_dst                ;Take average for these two
        adda    max_time
        lsra
        staa    max_time
        ldy     #LSRS_dst
        bra     store_dist

rs_distance:
        ldy     #LSRS_dst
        bra     store_dist

cr_distance:
        ldy     #CT_dst
        bra     store_dist

rf_distance:
        ldaa    LFRF_dst                ;Take average for these two
        adda    max_time
        lsra
        staa    max_time
        ldy     #LFRF_dst
        bra     store_dist

lf_distance:
        ldy     #LFRF_dst

store_dist:
        ldaa    max_time
        cmpa    #99                     ;Check for max dist
        bls     store_dist_2

        ldaa    #99                     ;Set to 9.9m if too high

store_dist_2:
        staa    0,y
        jsr     spkr_dist_nums          ;Update screen

        ldx     #ee_globals             ;Write speaker distances to EEPROM
        ldab    #ee_spkr_dists
        abx
        clrb
store_1: 
        ldy     #LFRF_dst
        aby
        ldaa    0,y
        jsr     write_ee
        incb
        inx
        inx
        cmpb    #3
        bne     store_1

        clr     polarity                ;Clear polarity flag for next time
        rts                         ;** Return **


channel_pol_data:                       ;Convert noise_channel to channel_pol
        dc.b    0,4,1,3,2               

flag_polarity:                          ;Enter with polarity in A
        ldab    noise_channel           ;Channel number must be converted...
        decb
        ldy     #channel_pol_data
        aby
        ldab    0,y                     ;Get offset into channel_pol slots

        ldy     #channel_pol            
        aby                             ;Point to correct channel polarity slot
        staa    0,y                     ;Store new channel polarity

        ldx     #ee_chan_pol     
        abx                             ;Add in offset
        jsr     write_ee                ;A contains polarity
        rts
        

;***********************************************************************
;*
;* Switch SPL on whenever microphone is plugged in.
;*
;***
switch_SPL:
        ldx     #regbase
        brclr   porte,x,#%00000010,mic_out  ;If no mic plugged in, disable A/D...

mic_in: brset   option,x,#%10000000,vu_done ;If A/D system is powered up, skip...

        bset    option,x,#%10000000         ;Else enable A/D charge pump,
        ldaa    #%00000000                  ; start A/D as single scan, single
        staa    adctl,x                     ; channel, input pin PE0
        ldd     #0
        std     vol_acc                     ;Clear mic LPF memory for a fresh start.
        staa    vol_acc+2
        bra     vu_done

mic_out:
        brclr   option,x,#%10000000,vu_done ;If A/D system is powered down, skip...
        bclr    option,x,#%10000000         ;Else, disable A/D charge pump
vu_done:
        rts                       ;** Return **
        

;***********************************************************************
;*
;* Volumes Average
;*
;***
volumes_aver:
	ldd     vcp_l
	addd    vcp_r           
        lsrd                    ;Make average of front volumes.
        subd    f_cold_def      ;Get diff. between LR factory default & our level.
        std     colddef_mod     ;Save for modifying other channels.

        ldd     f_cold_def      ;Give fronts the factory default level.
        std     vcp_l           ;Save them to maintain front balance.
	std     vcp_r

	ldd     vcp_ls
	addd    vcp_rs           
        lsrd                    ;Make average of surround volumes.
        subd    colddef_mod     ;Modify as determined above.
        std     vcp_ls          ;Save them to maintain rear balance.
	std     vcp_rs

        ldd     vcp_c
        subd    colddef_mod
        std     vcp_c           ;Shift the C value as well.

        delay   230*10          ;Delay 230 ms.

volumes_back:
        jsr     unpack_vol      ;Compute composite volumes and set them
        clr     ch_vol          ;Clear channel volume mode flag
        clr     curr_chs        ;No channel selected
        clr     ch_id 

	ldaa    #0
        staa    b_state         ;Cheat to revert to normal state insted of setup

	clr     auto_stage
;;;;;;;;clr     auto_vol
        rts                 ;** Return **
        

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!       E N D   O F   A U T O   S E T U P        !
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

