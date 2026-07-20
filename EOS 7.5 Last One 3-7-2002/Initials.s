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
;   Initials.s 
;
;***************************************************************
;*      Initials.s
;*
;*      68HC11F1 Register Initialization subroutine source file
;*
;*      Note: Has temporary stretch on some of the CSIO1,2 pins.
;*
;***************************************************************

        CLIST OFF       ;Only list assembled conditionals.
        MLIST OFF       ;Don't expand macros.


initials_flag:  equ     0


	  XDEF  Initials


        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


Inits:   Section 6


Initials:
         sei
         ldx    #regbase

;************************************************************************
;*
;*  Register Initialization
;*
;*  Some of the following registers or certain bit fields within them are
;*  time protected (i.e., must be written within 1st 64 E clock cycles
;*  after reset)
;*
;************************************************************************

;** OPTION : Power up A-D converter, COP timeout 1s, IRQ edge trigger.
;            ---Time protected---

        ldaa    #%10110011
        staa    option,x

;** INIT   : Registers at $1000, RAM at $0000
;            ---Time protected---
 
        ldaa    #%00000001
        staa    init,x     


;** BPROT  : Block protection disabled for EEPROM
;            ---Time protected---

        ldaa    #%00000000
        staa    bprot,x


;** PACTL  : Enable OC5 (no IC4)
        ;Note: Can't disable this to turn off EL lamp because
        ;      doing so disables one of the timer chains!!!!!!!!!!!
        bclr    pactl,x,#%00000100


;** OPT2   : CLK4X enabled ; ports C,G set to operate normally.
;Note: The CLK4X clock is not as useful for the 56009 as had been
;      hoped, since 8 MHz does not multiply up to 90 Mhz very well.
;      (90 MHz requires a clock multiplication factor of 90 + 1 = 91.

        ldaa    #%00100000    ;CLK4X enabled.
        staa    opt2,x


;*  CONFIG : EEPROM at $7E00, COP disabled, EEPROM enabled

        ldaa    config,x      ;Do not modify CONFIG if already $7f
        cmpa    #%01111111
        beq     Port_Init

        ldab    #$16                    
        stab    pprog,x
        stab    config,x
        ldab    #$17
        stab    pprog,x
        ldy     #$0D06     
dloop1: dey
        bne     dloop1
        
        clr     pprog,x
        ldab    #$02
        stab    pprog,x
        ldaa    #%01111111
        staa    config,x
        ldab    #$03
        stab    pprog,x
        ldy     #$0D06     
dloop2: dey
        bne     dloop2

        clr     pprog,x


Port_Init:

;** Port A : pin 2=input, 0,1,3-7=output; turn lamp off;
;            leave 4226 in power down and DSPs in reset

        ldaa    #%00000001   ;Initialize port bits to assert DSP reset
        staa    porta,x      ;immediately the port is enabled for output.
        ldaa    #%11111011   ;Configure port direction register.  
        staa    ddra,x

;** Port B : High order address outputs ADDR8-15

;** Port C : Data bus input,output  DATA 0-7 (may not need to set DDRC)

;** Port D : SCI, SPI control (need to set DDRD as outputs for SPI)

        ldaa    #%00111010            
        staa    ddrd,x
        bset    portd,x,#%00100000      ;SPI data Tx indicator off (LD400)

;** Port E : A-D conversion

;** Port F : Low order address outputs  ADDR0-7

;** Port G : CSPROG, CSGEN,CSIO1,2 outputs and peripheral slave selects; *SS hi

        ldaa    #%00001111
        staa    ddrg,x
        ldaa    #%00001111
        staa    portg,x

;** SCI options : 9600 baud, 8 bits

        ldaa    #%00110000                   
        staa    baud,x
        clr     sccr1,x                
        ldaa    #%00001100
        staa    sccr2,x

;** SPI options : SPI enabled, 68HC11 master, clock 250kbps, CPOL & CPHA=1

        ldaa    #%01011101
        staa    spcr,x

;** Interrupts:

        ldaa    #%00100111
        staa    hprio,x                 ;RTI highest priority

        bset    pactl,x,#%00000011      ;RTI rate = 30.5 Hz (E/2^16); 32.77ms.
        bset    tmsk2,x,#%01000000      ;Enable real time interrupts (RTII) 
        bset    tmsk1,x,#%10001000      ;Enable OC1,OC5 interrupts for startup
        bset    tmsk2,x,#%10000000      ;Enable Timer Overflow interrupts
                                        ; (TOF occurs at default 33 ms rate).
        ldaa    #%00100000
        staa    tctl2,x                 ;Capture falling edges
        bset    tmsk1,x,#%00000100      ;Enable IC1 interrupts


;** EEPROM programming:

        clr     pprog,x


;** External chip configuration and control:

        ldab    #%11110000             ;CSIO1 3-stretch; CSI02 3-stretch; CSGEN 0-stretch
;Try this to see if it suits VFD better:
;--Did not help. ajr
;       ldab    #%10110000             ;CSIO1 2-stretch; CSI02 3-stretch; CSGEN 0-stretch
        stab    csstrh,x               ;CSPROG  0-stretch

        ldab    #%11100100             ;CSIO1 enable, active hi; CSIO2 enable, active lo;
        stab    csctl,x                ;CSPROG enable; 64K EPROM program size.
                                       ;Program chip select has priority

        ldab    #%01001111             ;CSIO1 E-time; CSI02 addr-time;
        stab    csgsiz,x               ;CSGEN active low, E-time; 0K SRAM (disabled)


;** Kills:

        jsr     kill_on                ;Assert kill relays
        bset    kill_status,#$ff

;** Default inputs:

        ldaa    #7
        staa    MB_Main_mux                ;D1 input

        IFNE    name-3    ;OVATION-8 or SIGNATURE-8

           ldaa    #1
           staa    EO_Vmux_imag            ;Video 1 is default for O-8 and S-8
           staa    curr_vid

        ELSEC             ;SIGNATURE+8

           ldaa    #0                      ;Main analog input #1
           staa    S_Main_imag
           jsr     update_S_Main_mux

           ldaa    #7                      ;Tape mon Digital input 1
           staa    MB_Tape_imag
           jsr     update_MB_Tape_mux

           ldaa    #0                      ;Tape mon Analog input 1
           staa    S_Tape_imag       
           jsr     update_S_Tape_mux   

        ENDC

        ldx     #regbase
        bclr    tmsk2,x,#%01000000     ;RTI off \\\\
        jsr     init_4226_xtal         ;Initialize 4226 in Xtal mode (muted)
                                       ;to enable a fast clock immediately
        ldx     #regbase
        bset    tmsk2,x,#%01000000     ;RTI on  ////
        delay   70*10                  ;Give time to recalibrate.

        ldaa    #%00000000             ;Assert kills, mutes, and PCM1732 reset.
        staa    DAC8_latch1            ;Note: CS3310 is initialized by asserting mute.
                                       ;Note: Bit 7 of latch1 is now *KILL for ES/SL.
                                       ;Note: Bit 6 of latch1 is now high for A9.
                                       ;Note: Bit 6 of latch 1 may br used for HP KILL in the
                                       ;      future, or we may use some other latch bit.

        delay   1000*10                ;1 sec delay to give CS3310 supplies time to stabilize.

        ldaa    #%00010000             ;Deassert reset on PCM1732.
        staa    DAC8_latch1            ;Note: Bit 6 of latch1 is spare. 

        jsr     init_4PCMs             ;Initialize all 4 PCM1732s.
                                       ; Note: It's OK to call this routine here,
                                       ; because RTI's have not started yet.

        ldaa    #%00010100             ;Assert headphone kill (*KILL_HP = 0)
                                       ;Assert PCM1732 & CS3310 mutes (*MUTE_PCM1732,*MUTE_CS3310 = 0)
                                       ;Deasert PCM1732 reset (*RST_PCM1732 = 1)
                                       ;Assert kill relays (*KILL = 0)
                                       ;Deselect CS3310 (*CS_CS3310 = 1)
                                       ;Set initial state of CS3310 serial clock (SCLK_CS3310 = 0)
                                       ;Set initial state of CS3310 serial data (SDATA_CS3310 = 0)
        staa    DAC8_imag1 
        staa    DAC8_latch1            ;($1840)

        ldaa    #%00110100             ;Set AUX = 0 (Normal 8-ch operation)
                                       ;Set LF/RF Balanced/Single = 0 (Bal = +/-4V)
                                       ;Set SR/SL Balanced/Single = 1 (Single = 8V)
                                       ;Set CT/ES/LS/RS Balanced/Single = 1 (Single = 8V)
                                       ;Assert digital source (ANLG_PASS = 0)
                                       ;Set initial state of PCM1732 ML = 1
                                       ;Set initial state of PCM1732 MC = 0
                                       ;Set initial state of PCM1732 MD = 0
        staa    DAC8_imag2 
        staa    DAC8_latch2            ;($1848)
        staa    bal_single_save        ;Used by F-9-3 to clear F-9-1 and F-9-6.

        jsr     reset_38               ;Initialize Zorans (twice necessary!)
        delay   100*10                 ;Delay 100 ms.
        jsr     reset_38

        delay   50*10                  ;Delay 50 ms. 


;** Initial configuration of CD4226:

        jsr     init_4226_pll          ;Initialize 4226 in PLL mode (still muted)
        delay   100*10                 ;Delay for recal. 
	

;** IR receive initialization:

        jsr     ic1_initialize         ;Turn on IR reception
        clr     ir_test_flag


;** LCD/VFD initialization (includes clearing of screen):

        jsr     LCD_config             ;Configure the LCD/VFD hardware.
        jsr     LCD_init0              ;Initialize LCD/VFD display manager.

;** Front panel, IR, Lamp, RS232 flags:

        clr     IRQ_flag
        clr     two_press_timer

        clr     Buefuss_flag
        clr     TM_flag


;** Timers (in TOF and RTI):

        clr     two_secs
        clr     three_secs
        clr     lat_ovcnt1
        clr     rti_timer
        clr     ir_tout
        clr     mute_cntr
        clr     noise_seq_timer
        clr     flash_up
        clr     update_screen12         ;No updates to Input Data Status screen.
        clr     slow_enc_timer

;** TheaterMaster decoding initialization:

        ldaa    #%00010000
        staa    locked                  ;Default to no-lock status

        clr     PCM_in_proc             ;Clear all processing flags
        clr     AC3_in_proc
        clr     DTS_in_proc
        clr     MPEG_in_proc

        clr     curr_pass_mode          ;Default to no pass-thru.
        clr     curr_mode               ;Default to stereo

        ldaa    #%1000
        staa    spkr_cfg                ;Default to Reference Cinema, 2 subs.
        
        jsr     volume_initials         ;Initialize all volume variables

        clr     icon_flag               ;No icons in Main screen.
        clr     hdcd_on                 ;Clear HDCD flag
        clr     es_flag                 ;ES disabled.
        clr     party_flag              ;Party mode disabled.
        clr     deem_off_flag  ;>>>     ;Leave de-emphasis as is.

        ldaa    #$55                    ;Unlikely pattern.
        staa    dec_key_save          

        clr     noise_in_proc           ;Flag not in noise mode or static mode
        clr     static_in_proc          
        clr     xover_rolloff           ;Not in X-Over or Roll-Off mode
        clr     downmix_flag

        ldaa    #1
        staa    mem_num                 ;Default to memory 1  

        clr     t_dts_inp               ;No temporary dts, mpeg, ac3 dedication
        clr     t_mpeg_inp
        clr     t_ac3_inp

        ldaa    ee_globals+ee_tm_lockout    ;Check digital tape lock-out
        cmpa    #1
        bne     dig_lo_1

        ldaa    #2
        bra     dig_lo_2

dig_lo_1:
        ldaa    #1
dig_lo_2:
        staa    dig_tape_inp            ;Set tape input to 1 (unless locked out)

        ldaa    ee_globals+ee_tm_lockout+1  ;Check analog tape lock-out
        cmpa    #1
        bne     ana_lo_1

        ldaa    #2
        bra     ana_lo_2

ana_lo_1:
        ldaa    #1
ana_lo_2:
        staa    ana_tape_inp            ;Set tape input to 1 (unless locked out)

        ldd     #0
        std     cor_l
        std     cor_r
        std     cor_ls
        std     cor_rs
        std     cor_c
        std     cor_sub

;** Write factory default parameters to EEPROM:

        jsr     write_fac_defs          ;Fac. defs. to EEPROM
        jsr     write_first_globals     ;Fac. defs. to user global EEPROM


;** Enable Power Fail XIRQ interrupt:

        tpa                             ;Get CC register.
        anda    #%10111111              ;Clear X bit to enable /XIRQ for power fail detect.
        tap                             ;Update CCR.

;** Get DIP information:

        ldaa    mb_DIP                  ;Read motherboard DIP switches.
        staa    DIP_imag

;** Buefuss Initialization:

        jsr     ONSCI                   ;Initialize Buefuss parameters
        jsr     Buef_init

;** Unmute

        clr     mute_status             ;Unmuted to start

;** Enable other interrupts:

        cli
        rts
