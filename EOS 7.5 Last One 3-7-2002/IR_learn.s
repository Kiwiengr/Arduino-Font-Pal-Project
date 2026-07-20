;****************************************
;*      IR_learn.s
;*
;*      IR Learning Mode source file
;****************************************

        CLIST OFF       ;Only list assembled conditonals.
        MLIST OFF       ;Don't expand macros.


irlearn_flag:   equ     0


        XDEF    Learn_mode,IR_output,IR_code_out


        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"  


IRl_vbls:       Section 36


IR_code_out:    ds.b     1       ;Storage of IR code to be output
IR_code_temp:   ds.b     1       ;Dispensible output data


IR_learn:       Section 8


;********************************************************
;*
;* Includes IR learn mode page and IR output routine
;*
;***


Learn_mode:
        ldaa    #10
        staa    bright_level

        ldx     #regbase
        ldaa    #$80                   ;Enable TOI, disable RTI
        staa    tmsk2,x
        clr     tmsk1,x                ;Disable IC, OC
        clr     sccr2,x                ;Disable SCI interrupts

        jsr     LCD_init

        ldy     #ir_learn_screen      
        jsr     screen_out             ;Display Prog. mode splash screen
        delay   3000*10                ; for 3 seconds.

        jsr     LCD_init               ;Clear screen.
        jsr     TM_message             ;Set pointer and display title message...
        ldy     #TM_page

IR_learn_step:
        pshy                   ;@@@@   ;Save IR code table pointer
        ldaa    1,y
        staa    IR_code_out            ;store IR code
        iny
        iny                            ;update pointer to name
        pshy
        ldaa    #11
        ldab    #19
        jsr     Section_clear
        puly
        ldaa    #11
        jsr     SCREENS                ;Display name

        ldx     #regbase
        clr     tmsk1,x                ;Prevent IR jitter
        clr     IRQ_flag

;%%%%%%%%%%%%%%%
IR_learn_loop:
        ldx     #regbase
        bclr    tmsk2,x,#$80           ;Disable TO interrupts for stable pulses

        ldaa    #20
        ldy     #learn_start
        jsr     SCREENS                ;Display " o...Start IR tx  "

        clr     IRQ_flag

next_IR:
        ldaa    IRQ_flag
        beq     next_IR                ;Wait for FP button press to start IR...

        ldaa    #20
        ldy     #learn_tx
        jsr     SCREENS                ;Display " Sending XXXXXXXXX... "

        ldab    #50                    ;IR frame counter
        clr     IRQ_flag
        rtint   OFF                    ;Disable real-time interrupts.
;%%%%%
IR_inner_loop:
        sei
        jsr     IR_output              ;Output code
        cli

        ldx     #regbase
        bset    porta,x,#%01000000     ; output half-click,
        delay   20*10                  ; delay 20 ms,
        bclr    porta,x,#%01000000     ; and then output other half-click...

        ldaa    IRQ_flag
        bne     IR_loop_done           ;FP press shortens the IR loop.

        decb
        bne     IR_inner_loop
;%%%%%

IR_loop_done:
        rtint   ON                     ;Re-enable real-time interrupts.
        ldx     #regbase               ;Enable TO interrupt again
        bset    tmsk2,x,#$80

        ldaa    #20
        ldy     #learn_buts
        jsr     SCREENS                ;Display " o...Next   oo...Prev "

        clr     one_sec      
        inc     one_sec                ;Start one scond timer

        clr     IRQ_flag               ;Set up for FP button press.

;%%% Wait for FP button press...
;    If < 1 second than step to next code (single press) or prev code (double press).
;    Else if >= 1 second, repeat same code.
wait_loop:
        ldaa    one_sec
        bne     wait_2
        jmp     IR_learn_loop2         ;After 1 second, put up " o...Repeat IR tx " msg.

wait_2: ldaa    IRQ_flag
        beq     wait_loop

        cmpa    #1
        beq     timing_loop
        bra     two_prs

timing_loop:
        ldaa    two_press_timer
        cmpa    #8
        bgt     one_prs
        jmp     wait_loop
;%%%%%%%%%%%%%%%
one_prs:
        clr     IRQ_flag
        puly                   ;@@@@   ;Restore IR code table pointer
        bsr     next_item
        bra     page_chk_down

two_prs:
        clr     IRQ_flag
        puly
        bsr     prev_item
        bra     page_chk_up

next_item:                             ;Search for beginning of next sequence
        iny
        ldaa    0,y                     
        cmpa    #1
        bne     next_item
        rts

prev_item:
        dey
        ldaa    0,y
        cmpa    #1
        bne     prev_item
        rts

page_chk_down:
        cpy     #TMS_page
        bne     page_down1

        bsr     TMS_message
        ldy     #TMS_page
        bra     keep_looping

page_down1:
        cpy     #Special_page
        bne     page_down2

        bsr     Specials_msg
        ldy     #Special_page
        bra     keep_looping
        
page_down2:
        cpy     #IR_codes_end
        bne     keep_looping

        bsr     TM_message
        ldy     #TM_page
        bra     keep_looping

page_chk_up:
        cpy     #IR_codes_start
        bne     page_up1

        bsr     Specials_msg
        ldy     #IR_codes_end-1
        bsr     prev_item

page_up1:
        cpy     #TMS_page
        bne     page_up2
        bsr     TM_message
        ldy     #TMS_page-1
        bsr     prev_item
page_up2:
        cpy     #Special_page
        bne     keep_looping

        bsr     TMS_message
        ldy     #Special_page-1
        bsr     prev_item

keep_looping:
        jmp     IR_learn_step


IR_learn_loop2:
        ldx     #regbase
        bclr    tmsk2,x,#$80           ;Disable TO interrupts for stable pulses

        ldaa    #20
        ldy     #learn_repeat
        jsr     SCREENS                ;Display " o...Repeat IR tx  "

        clr     IRQ_flag
        jmp     next_IR


TM_message:
        clra                           ;Put up TM LEARN message
        ldy     #TM_learn
        bra     Learn_screen


TMS_message:
        clra                           ;Put up TMS LEARN message        
        ldy     #TMS_learn
        bra     Learn_screen


Specials_msg:
        clra
        ldy     #Specials              ;Put up SPECIALS LEARN message
Learn_screen:
        jsr     SCREENS
        rts


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%   IR Output routine   %%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%  
;%%%   Outputs 8 bit IR code stored in IR_code_out
;%%%
;%%%   IR output consists of:
;%%%
;%%%   sync pulse : 0.6ms hi , 3.6ms lo , 0.6ms hi
;%%%   code       : msb first, "0" : 1.2ms lo , 0.6ms hi
;%%%                           "1" : 1.8ms lo , 0.6ms hi
;%%%   gap        : 2 ms lo 
;%%%
;%%%   hi pulses are chopped to 38khz
;%%%   (0.6ms used by mnfctrs as standard test pulse length)
;%%%   
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IR_output:
        pshb
        ldaa    IR_code_out
        staa    IR_code_temp           ;set up dispensible data
        
        jsr     pulse
        jsr     pulse_sync             ;sync delay of 5ms lo, 1ms hi  

        clrb                           ;clear bit counter
check_bits:
        pshb
        clc
        lsl     IR_code_temp           ;roll hi bit into carry
        bcc     zero_out

one_out:
        bsr     pulse
        bsr     pulse_one
        bra     next_bit

zero_out:
        bsr     pulse
        bsr     pulse_zero
        bra     next_bit

next_bit:
        pulb
        incb
        cmpb    #8                     ;all bits checked?
        bne     check_bits 

        bsr     pulse
        pulb
        rts


pulse:                           
;%%% 23 pulses each of: 13.5us hi, 13us lo : total = 0.605ms
        ldx     #regbase
        bclr    porta,x,#%00100000     ;set output lo
        ldaa    #23                    ;23 fast pulses
burst:
        bset    porta,x,#%00100000
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

        bclr    porta,x,#%00100000
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        
        deca
        bne     burst
        rts


pulse_sync:
        ldd     #sync
        bsr     delay_set
        rts

pulse_one:
        ldd     #one
        bsr     delay_set
        rts

pulse_zero:
        ldd     #zero
        bsr     delay_set
        rts


delay_set:                       
;                                      ;Uses OC2 to wait for D cycles
        
        ldx     #regbase
        bclr    porta,x,#%00100000     ;Set output low
        bclr    tflg1,x,#%10111111     ;Clear OC2 flag
        addd    tcnt,x                 ;D + current time
        std     toc2,x                 ;Set up OC2

        brclr   tflg1,x,#%01000000,*   ;Wait until OC2 flags time out
        rts



