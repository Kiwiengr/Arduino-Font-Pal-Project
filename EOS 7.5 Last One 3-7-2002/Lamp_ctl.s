;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%                       %%%%
;%%%%   @   @ @@@@@ @@@@    %%%%
;%%%%   @   @ @     @   @   %%%%
;%%%%   @   @ @@@   @   @   %%%%
;%%%%    @ @  @     @   @   %%%%
;%%%%     @   @     @@@@    %%%%
;%%%%                       %%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
;
;   Lamp_ctl.s 
;
;**********************************************
;*
;*      Lamp Control Routines source file
;*
;**********************************************

        CLIST OFF       ;Only list assembled conditonals.
        MLIST OFF       ;Don't expand macros.


lampctl_flag:   equ     0


        XDEF    bright_up,bright_down,lamp_on,lamp_off,add_pulse
        XDEF    bright_level,write_bright


        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


Lamp_vbl:       Section 35
 

bright_level:   ds.b     1       ;10 possible brightness levels



Lamp_ctl:       Section 5


;******************************************************************
;*           L A M P   C O N T R O L   R O U T I N E S
;******************************************************************
;*
;* Calculate time of lamp on from brightness level in A
;*  and add it on to D
;*
;* Destroys Y. D contains new time
;*
;* Used as:      ldd     on_time
;*               jsr     add_pulse
;*               std     off_time
;*
;***

add_pulse:
        psha                           ;Save A
        ldaa    bright_level
        psha                           ;Push brightness level onto stack
        tsy                            ;Stack pointer in Y
        ldaa    1,y                    ;Restore A
add_loop:
        addd    #3277                  ;bright_level x (bright_unit=3277)
        dec     0,y                    ;= time difference in on/off
        bne     add_loop
        ins
        ins                            ;Restore stack
        rts


;**************************************************************
;*
;* Brightness control routines (off, on, up and down)
;*
;* These routines wait for the lamp to go off, then recalculate the
;* time of the next pulse.
;*
;* Destroy A,B,Y
;*
;***

lamp_off:
        ldx     #regbase
        bset    oc1m,x,#%00001000       ;OC1 controls PA3
        bclr    oc1d,x,#%00001000       ;OC1 turns PA3 off

        bset    tctl1,x,#%00000010      ;OC5 turns PA3 off
        bclr    tctl1,x,#%00000001

        ldd     #200
        std     toc1,x                  
        std     ti4o5,x                 
        clr     lamp_status             ;Flag lamp is off
        rts

lamp_on:
        ldx     #regbase
        bset    oc1m,x,#%00001000       ;OC1 controls PA3
        bset    oc1d,x,#%00001000       ;OC1 turns PA3 on

        bset    tctl1,x,#%00000011      ;OC5 turns PA3 on

        ldd     #200
        std     toc1,x                  
        std     ti4o5,x
        ldaa    #1
        staa    lamp_status             ;Flag lamp is on 
        rts

bright_up:
        ldaa    #%00                 ;Set VFD to 100% brightness.
        jsr     VFD_bright_driver
        rts

bright_up_2:
        ldaa    bright_level
        cmpa    #10                  ;num_levels
        beq     end_up
        
        inc     bright_level

        ldaa    screen_num              ;Update screen 9 if there
        cmpa    #8
        bne     bup_only
        jsr     feats_sel_bits
bup_only:
        ldaa    bright_level
        cmpa    #10                  ;num_levels
        beq     lamp_on

        ldx     #regbase
        brclr   tflg1,x,#%00001000,*   ;Wait for lamp to go off (OC5)
        nop        
        bra     set_times              ;Set up next pulse of correct length        
end_up:
        rts


bright_down:
        ldaa    #%11                 ;Set VFD to 25% brightness.
        jsr     VFD_bright_driver
        rts

bright_down_2:
        ldaa    bright_level
        beq     end_down
        
        dec     bright_level

        ldaa    screen_num
        cmpa    #8
        bne     bdn_only
        jsr     feats_sel_bits          ;If there, update screen 9
bdn_only:
        ldaa    bright_level
        beq     lamp_off

        ldx     #regbase
        brclr   tflg1,x,#%00001000,*   ;Wait for lamp to go off (OC5)
        nop        
        bra     set_times              ;Set up next pulse of correct length
end_down: 
        rts



set_times:
        ldd     toc1,x
        jsr     add_pulse
        std     ti4o5,x                ;Off time=on time + duration of bright
enable_OC:
        ldx     #regbase
        ldaa    #%00001000              ;Set up OC1 to set PA3 hi
        staa    oc1m,x
        ldaa    #%00001000
        staa    oc1d,x
        ldaa    #%00000010              ;Set up OC5 to set PA3 low
        staa    tctl1,x
        bclr    tflg1,x,#%01110111      ;Clear OC1F and OC5F
        bset    tmsk1,x,#%10001000      ;Enable OC1 and OC5  interrupts
OC_init_end:
        ldx     #1
;        stx     lamp_time_out+1
;        clr     lamp_time_out
;        ldaa    #1
;        staa    lamp_status
        rts


;**************************************************************
;*
;* Sleep mode brightness fade. Saves current level before fading, 
;* then waits for another IR pulse before lighting up 
;* and dealing with pulse.
;*
;* Destroys A,B,Y
;*
;***

;smooth_off:
;        ldaa    bright_level
;        psha                           ;Save brightness level
;down_loop:
;        ldaa    bright_level
;        beq     smooth_return
;        bsr     bright_down_2
;        bsr     bright_down_2
;        delay   1*10                   ;5 ms delay
;        bra     down_loop      
;smooth_return:
;        pula
;        staa    bright_level
;        clr     lamp_status            ;Flag lamp is off
;        rts


;**************************************************************
write_bright:
        ldaa    bright_level
        ldab    #ee_bright
        rts


        end


