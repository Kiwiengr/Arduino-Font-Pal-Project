;***************************************************************
;*      Inv.s
;*
;* Possible Improvements:
;*
;* Use local variable delay routine.
;* Allow invaders to be destroyed with the laser.
;* Accelerate the invaders with each invader destroyed.
;* Left-right movement of laser together with manual firing.
;* Keep the existing demo mode intact, but also have a playable mode.
;* Increment the score by 25s and 100s, as appropriate.
;* Decrement the number of spare laser bases with each one destroyed.
;*
;***************************************************************

        CLIST OFF       ;Only list assembled conditionals.
        MLIST OFF       ;Don't expand macros.

inv_flag:  equ     0

          XDEF  Invade

        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


Inv_vbl:     Section 79

;%% Static buffer space in CPU RAM:
inv_line_out:   ds.b    23
inv_line_in:    ds.b    23
laser:          ds.b    3
explode:        ds.b    3
UFO:            ds.b    9


Invs:        Section 77


Invade: jsr     LCD_init

;%% Misc constants:
RH_side:                equ     13       ;Defines RHS of screen.
final_inv_position:     equ     24  ;30  ;Number of invader moves in each wave.
number_of_waves:        equ     2        ;Number of invasion waves.
High_score_frames:      equ     20       ;Determines duration of high score screen.

;%% Local variables dynamically allocated on stack:
LR_position:            equ     0        ;8-bit counter.
LR_flag:                equ     1        ;8-bit flag.
invaders:               equ     2        ;16-bit pointer.
run_counter:            equ     5        ;8-bit invader run counter
laser_position:         equ     6        ;8-bit position register
wave_counter:           equ     7        ;8-bit invasion wave counter

        tsx
        xgdx
        subd    #7          ;Allocate local variables on stack
        xgdx
        txs

splash_screen:
        jsr     splash
inv_init:
        jsr     LCD_init
        ldy     #Inv_screen
        jsr     screen_out
        delay   1500*10

        ldaa    #number_of_waves
        staa    wave_counter,x

new_wave:
        jsr     init_strgs
        ldy     #inv_line_out
        sty     invaders,x

        ldaa    #28
        staa    laser_position,x

        ldaa    #final_inv_position
        staa    run_counter,x

        ldaa    #1
        staa    LR_flag,x               ;Go right

        ldaa    #0                      ;Allows for 1 leading space on aliens.
        staa    LR_position,x           ;Start at LH end

;----------- MAIN LOOP ------------
inv_loop:
        ldaa    laser_position,x
        ldy     #laser
        jsr     SCREENS

        ldaa    LR_position,x
        ldy     invaders,x
        jsr     SCREENS

        ldaa    LR_flag,x
        cmpa    #1                      ;Determine direction...
        bne     .left

.right: inc     LR_position,x
        inc     LR_position,x
.left:  dec     LR_position,x
        ldaa    LR_position,x 

RH_check:
        cmpa    #6                      ;Reached RH end?
        bne     LH_check

        ldaa    #$ff                    ;Flag left move
        staa    LR_flag,x
        jsr     move_down
        bra     new_invs
                                        
LH_check:
        cmpa    #0                      ;Reached LH_end?
        bne     new_invs

        ldaa    #1                      ;Flag right move
        staa    LR_flag,x
        jsr     move_down
        
new_invs:
        ldy     invaders,x
        cpy     #inv_line_out
        bne     legs_out

legs_in:
        ldy     #inv_line_in
        bra     inv_line

legs_out:
        ldy     #inv_line_out
inv_line:
        sty     invaders,x
        jsr     tick  
        delay   800*10                  ;Initial speed is approx. 1.25 Hz.
        dec     run_counter,x           ;Have invaders reached final position?
        beq     final_stage             ;Yes...

fire_laser:
        ldy     #laser                  ;No, continue firing laser...
        ldaa    0,y
        cmpa    #'e'                    ;Last frame in animation sequence?
        blt     fire_next

reload_laser:
        ldaa    #'a'-1                  ;First frame in animation sequence.
        staa    0,y
fire_next:
        inc     0,y

        ldaa    0,y
        cmpa    #'b'                    ;Laser firing frame?
        bne     end_loop 

        jsr     chirp                   ;Sound for laser beam.
end_loop:
        jmp     inv_loop


;---------- FINAL STAGE ------------
final_stage:
        jsr     explode_laser

        delay   1000*10
        jsr     UFO_fly_by              ;Occurs at the end of each wave.

        dec     wave_counter,x
        beq     finals
        jmp     new_wave                ;Go get another invasion wave.


finals: delay   2000*10
        jsr     LCD_init

        ldaa    #High_score_frames
        staa    run_counter,x           ;Using as a loop counter here.

        ldy     #high_scores
        jsr     screen_out
        delay   400*10

score_loop:
        ldaa    #5                      ;"o" in Scores
        ldy     #high_scores_I
        jsr     SCREENS
        delay   400*10

        ldaa    #5                      ;"o" in Scores
        ldy     #high_scores_O
        jsr     SCREENS
        delay   400*10

        dec     run_counter,x
        bne     score_loop

        jsr     LCD_init
        delay   500*10
        jmp     splash_screen

;------------------------------------
;Note: The following return locks up the main EOS_com.s code.
Never:
        tsx
        xgdx
        addd    #7          ;Deallocate local stack variables.
        xgdx
        txs

        rts


;*******************************************************
;*
;* Move Down 
;*
;***
move_down:
        ldy     #inv_line_out
        ldaa    1,y
        cmpa    #4
        beq     move_end                ;If all the way down, do nothing

        ldab    #5                      ;Move 5 invaders down one row...
mve_loop:
        inc     1,y                     ;Do outies (skip leading space)
        inc     24,y                    ;Do innies (skip leading space)
        iny
        iny
        decb
        bne     mve_loop

move_end:
        rts


;*******************************************************
;*
;* Explode Laser
;*
;***
explode_laser:
        ldaa    laser_position,x        ;wipe out laser.
        tab
        jsr     Section_clear
        rts

;replace the above with this code:
        ldaa    #0
        ldab    #16   
        jsr     Section_clear           ;Clear top row of LCD except 000.

        delay   1000*10
        ldy     #laser+4                ;1st explosion frame.

explode_loop:
        ldaa    laser_position,x
        jsr     SCREENS

        ldaa    0,y
        cmpa    #'t'                    ;Last frame in animation sequence?
        beq     explode_exit

        inc     0,y
        delay   350*10                  ;Do explosion noise here later.
        bra     explode_loop

explode_exit:
        rts


;*******************************************************
;*
;* UFO Fly By 
;*
;***
UFO_fly_by:
        ldaa    #0
        ldab    #16 
        jsr     Section_clear           ;Clear top row of LCD except for 000.

        ldy     #laser                  ;Make sure main laser frame matches spares
        ldd     #'a|'                   ; during fly-by to conserve CGRAM.
        std     0,y
        ldaa    laser_position,x
        jsr     SCREENS
        
        ldaa    #0
        staa    LR_position,x

UFO_loop:
        jsr     chirp

        ldy     #UFO
        ldd     #'AB'
        std     0,y
        ldd     #'C '
        std     2,y
        stab    8,y                     ;Clear leading space font
        ldaa    #'U'
        staa    5,y                     ;Make trailing space UFO font
        ldaa    LR_position,x
        jsr     SCREENS
        delay   120*10

        jsr     chirp

        ldd     #'IJ'
        std     0,y
        ldd     #'KL'
        std     2,y
        ldaa    #'U'
        staa    8,y                     ;Make leading space UFO font
        ldaa    LR_position,x
        jsr     SCREENS
        delay   120*10

        jsr     chirp

        ldd     #'QR'
        std     0,y
        ldd     #'ST'
        std     2,y
        ldaa    LR_position,x
        jsr     SCREENS
        delay   120*10

        jsr     chirp

        ldd     #'ab'
        std     0,y
        ldd     #'cd'
        std     2,y
        ldaa    LR_position,x
        jsr     SCREENS
        delay   120*10

        jsr     chirp

        ldd     #'ij'
        std     0,y
        ldd     #'kl'
        std     2,y
        ldaa    LR_position,x
        jsr     SCREENS
        delay   120*10

        jsr     chirp

        ldd     #' r'
        std     0,y
        staa    5,y                     ;Clear trailing space
        ldd     #'st'
        std     2,y

        ldaa    LR_position,x
        jsr     SCREENS
        delay   120*10

        inc     LR_position,x
        ldaa    LR_position,x



        cmpa    #RH_side                ;Reached RH side?
        beq     UFO_exit
        jmp     UFO_loop

UFO_exit:
        ldaa    #0
        ldab    #16 
        jsr     Section_clear           ;Clear top row of LCD except for 000.
                                        ;(frees up some CGRAM for next wave).
        rts


;*******************************************************
;*
;* Sound when invaders move.
;*
;***
tick:   pshy
        pshx
        psha

        ldy     #2              ;Duration.
        ldaa    #100            ;Frequency.
        bra     .t1

;*******************************************************
;*
;* Sound when laser fires.
;*
;***
chirp:  pshy
        pshx
        psha
        ldy     #8              ;Chirp length.
.t1:    ldx     #regbase
	bset    porta,x,#%01000000
.t2:    deca
        bne     .t2  

        bclr    porta,x,#%01000000
        ldaa    #50             ;Chirp pitch.
.t3:    deca
        bne     .t3  

        dey
        bne     .t1    

        pula
        pulx
	puly

	rts                  ;** Return **
        

;*******************************************************
;*
;* Initialize string variables
;*
;*      inv_line_out:  ' 0 0 0 0 0 |'
;*                     ' O O O O O '
;*
;*      Inv_line_in:   ' 0 0 0 0 0 |'
;*                     ' I I I I I '
;*
;*      Laser:         'a|'
;*                     'P'
;*
;*      Explode:       'i|'
;*                     'P'
;*
;*      UFO:           'IJKL|', etc.
;*                     'UUUU'
;***
init_strgs:  
        ldy     #inv_line_out
        ldd     #' 0'
        std     0,y
        std     2,y
        std     4,y
        std     6,y
        std     8,y
        ldd     #' |'
        std     10,y
        ldd     #' O'
        std     12,y
        std     14,y
        std     16,y
        std     18,y
        std     20,y
        ldaa    #' '
        staa    22,y

        ldy     #inv_line_in
        ldd     #' 0'
        std     0,y
        std     2,y
        std     4,y
        std     6,y
        std     8,y
        ldd     #' |'
        std     10,y
        ldd     #' I'
        std     12,y
        std     14,y
        std     16,y
        std     18,y
        std     20,y
        ldaa    #' '
        staa    22,y

        ldy     #laser
        ldd     #'a|'
        std     0,y
        ldaa    #'P'
        staa    2,y

        ldy     #explode
        ldd     #'i|'
        std     0,y
        ldaa    #'P'
        staa    2,y

        ldy     #UFO
        ldd     #'IJ'
        std     0,y
        ldd     #'KL'
        std     2,y
        ldaa    #'|'
        staa    4,y
        ldd     #'UU'
        std     5,y
        std     7,y

        rts


;*******************************************************
;*
;* Put up splash screen, etc.
;*
;***
splash:
        ldy     #Inv_splash
        jsr     screen_out              ;(Includes LCD_init)
        delay   600*10

        ldaa    #25
        ldy     #score1
        jsr     SCREENS 
        jsr     tick
        delay   200*10

        ldaa    #25
        ldy     #score2
        jsr     SCREENS 
        jsr     tick
        delay   200*10

        ldaa    #25
        ldy     #score3
        jsr     SCREENS 
        jsr     tick
        delay   400*10

        ldaa    #34
        ldy     #score4
        jsr     SCREENS 
        jsr     tick
        delay   200*10

        ldaa    #34
        ldy     #score5
        jsr     SCREENS 
        jsr     tick
        delay   200*10

        ldaa    #34
        ldy     #score6
        jsr     SCREENS 
        jsr     tick
        delay   1500*10

        ldy     #Inv_get_ready
        jsr     screen_out              ;(Includes LCD_init)
        delay   3000*10
        rts


;-------------------------------------
Inv_splash:  
        dc.b     '   Space Invaders   |'   
        dc.b     '   BL    B          '
        dc.b     '   1-     ABC-      |'
        dc.b     '   I      UUU       '

Inv_get_ready:
        dc.b     '       GET       000|'   
        dc.b     '                    '
        dc.b     '      READY!     _aa|'
        dc.b     '                 SPP'

Inv_screen:  
        dc.b     '                 000|'   
        dc.b     '                    '
        dc.b     '  yz yz   yz yz  _aa|'
        dc.b     '  PP PP   PP PP  SPP'

high_scores:                  
        dc.b     'Hi-Sc3rers: AJR SCR |'              
        dc.b     'BB BBOBBBB          '
        dc.b     '            AR  JSH |'
        dc.b     '                    '


score1: dc.b     '2  |'       ;Position 25
        dc.b     '   '

score2: dc.b     '25 |'
        dc.b     '   '

score3: dc.b     '25 |'
        dc.b     '   '

score4: dc.b     '1  |'       ;Position 34
        dc.b     '   '

score5: dc.b     '10 |'
        dc.b     '   '

score6: dc.b     '100|'
        dc.b     '   '


high_scores_I:
        dc.b     '3|'              
        dc.b     'I'

high_scores_O:
        dc.b     '3|'              
        dc.b     'O'

;-------------------------------------










