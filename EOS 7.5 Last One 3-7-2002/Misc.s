;************************************************
;*    Misc.s
;*
;*    Miscellaneous source stuff
;************************************************
;*
;* Contents:
;*  ACIA character output subroutine
;*
;*

        CLIST OFF       ;Only list assembled conditonals.
        MLIST OFF       ;Don't expand macros.


misc_flag:      equ     0


        XDEF    outa,inchar,delay_loop
        XDEF    dummy,short_dummy


        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


Misc:   Section 7


;******************************************************************
;*
;* Output a character to via the ACIA
;* All registers unchanged
;*
;***

outa:
        pshx
        ldx     #regbase
        bsr     wait_sci
        cmpa    #$0d
        bne     out_sci
        ldaa    #$0a
        staa    scdr,x
        ldaa    #$0d
        bsr     wait_sci
out_sci:
        staa    scdr,x
        pulx
        inc     CHRCNT
        rts
wait_sci:
        brclr   scsr,x,#%10000000,*
        rts                         


inchar:
        pshx
        ldx     #regbase
inchar_wait:
        ldaa    scsr,x
        anda    #$20
        beq     inchar_wait
        ldaa    scdr,x
        anda    #$7f
        pulx
        rts


;*********************************************************************
;*
;* Body of software delay macro.
;* On entry, Y must contain the delay value in 0.1 ms increments.
;* See macros.i for details.
;*
;**
delay_loop:
        psha
.loopo: ldaa    #29            ;[2]
.loopi: deca                   ;[2]
        bne     .loopi         ;[3]

        dey
        bne     .loopo

        pula

        rts               ;** Return **


;************************************************************
;*
dummy:
short_dummy:
        rts


        end

