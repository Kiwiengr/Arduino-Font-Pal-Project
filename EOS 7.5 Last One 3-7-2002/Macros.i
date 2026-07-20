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
;   Macros.i
;
;************************************************
;*
;*    Macro Sources
;*
;************************************************
;*
;* Contents:
;*  Software delay routine
;*  24-bit lamp timer ON/OFF control
;*  24-bit Big Nums timer ON/OFF control
;*  Real-time interrupt ON/OFF control
;*
;*

;*********************************************************************
;*
;*            S O F T W A R E    D E L A Y    M A C R O
;*                               = = = = =
;*
;* Approximate delay = parameter / 10 milliseconds
;*                     i.e., delays in increments of 0.1 ms
;*
;*              parameter          delay
;*
;*                  1              0.1 ms
;*                 10              1.0 ms
;*               2000              200 ms
;*              65535             6.55 s    (max. delay)
;*
;* Note: Since this routine only uses cpu registers and the stack, it
;*       is inherently re-entrant and may freely be called by main-line
;*       code and interrupt service routines.
;*
;* Usage:    delay  20*10    ;20 ms delay.
;*
;*
;* Regs altered: None
;*
;**

delay: MACRO

	IFGE \1 - 65536

           FAIL "Delay parameter exceeds 65536"

	ELSEC

           pshy
           ldy     #\1
           jsr     delay_loop     
           puly
           
	ENDC

       ENDM


;*********************************************************************
;*
;*       2 4 - B I T   L A M P   T I M E R   C O N T R O L
;*
;* Valid parameters are ON (start timer) or OFF (stop timer).
;*
;* Usage:    lamp_timer  ON|OFF
;*
;**
;
;lamp_timer: MACRO
;
;        IFC "\1","OFF"
;
;           clr     lamp_time_out+2
;           clr     lamp_time_out+1
;           clr     lamp_time_out
;           clr     lamp_status
;           
;
;        ELSEC
;
;             IFC "\1","ON"
;
;                ldx     #1
;                stx     lamp_time_out+1
;                clr     lamp_time_out
;                ldaa    #1
;                staa    lamp_status
;
;             ELSEC
;
;                FAIL "Valid parameters are ON or OFF"
;
;             ENDC
;
;        ENDC
;
;       ENDM


;*********************************************************************
;*
;*       R E A L   T I M E   I N T E R R U P T   C O N T R O L
;*
;* Valid parameters are ON or OFF.
;*
;* Usage:    rtint   ON|OFF
;*
;**

rtint: MACRO

        IFC "\1","ON"

           ldx     #regbase
           bset    tmsk2,x,#%01000000

        ELSEC

             IFC "\1","OFF"

                ldx     #regbase
                bclr    tmsk2,x,#%01000000

             ELSEC

                FAIL "Valid parameters are ON or OFF"

             ENDC

	ENDC

       ENDM


