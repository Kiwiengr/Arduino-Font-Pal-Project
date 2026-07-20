*****************************************************************

*        org     $ff50
*
*        fcc     'Copyright (C) 1992 - 1998 by '
*        fcc     'Enlightened Audio Designs Corporation:  '
*
*        fcc     'SwitchMaster  '
*        fcc     'Firmware Version 0.0040  '
*        fcc     'May 6th, 1998  '

*------------------------------------------------------------------------
*                               NOTICE
*
*  This software  embodies a confidential proprietary  design owned by
*  Enlightened Audio Designs Corporation and all Copyrights and design,
*  manufacturing, reproduction, use and sales rights regarding the same
*  are expressly reserved to  Enlightened  Audio  Designs  Corporation.
*
*                    Copyright (C) 1992-1998 by
*
*                 ENLIGHTENED AUDIO DESIGNS CORPORATION,
*                  300 West Lowe, Fairfield,  IA 52556
*                  Ph. 515-472-4312  FAX: 515-472-3566
*
*
* TARGET PCB:   
*             Name:       SFP-1         SMB-2
*             Date Code:  0303          0512
*             Year:       1996          1996  
*             PCB File:   SF10303.PCB   SMB20512.PCB
*
*
* TARGET CPU: 
*             MC68HC811E2  (256 bytes RAM, 2K EEPROM, HC24 PRU)
*             52-pin plastic quad package (package 52 FN, PLCC)
*             This cpu has EEPROM block protect (BPROT port $1035).
*             EEPROM security feature available on request.
*             8K EPROM version of the 68HC811 cpu also available.
*
*
* MEMORY MAP:       
*             RAM              $0000 - $00FF      (256 bytes)
*             Register Block   $1000 - $103F      (64 bytes)
*             Boot ROM         $BF40 - $BFFF      (192 bytes)
*             EEPROM           $F800 - $FFFF      (2K bytes)        
*
*-----------------------------------------------------------------
*
* STILL TO BE DONE:
* ================
*  1) Front panel "S" switch should toggle between S and composite
*     when the switch is RELEASED, making it operate the same way
*     as the TheaterMaster front panel "INV" button. This will also
*     have the benefit of changing the Tape/Mon input from the
*     Switcher front panel without briefly toggling "S".
*
* DONE:
* ====
*  1) Copy EEPROM burning routine to RAM to be able to write
*     permanent parameters. The following parameters are to be
*     permanently saved in the CPU:
*      - Dedicated video tape/mon input selection
*      - Video links to digital and analog inputs
*      - S/composite video by inputs
*
*
* NOTES:
* =====
*  1) TM IR commands relevant to switcher:
*      - Input select (analog, digital, video)
*        (also from TheaterMaster front panel)
*      - Dedicated video tape/mon input selection
*        (uses analog and digital Tape/Mon command)
*      - Status mode (also from TheaterMaster front panel)
*      - Link current A/V selection
*      - Restore deafult links
*      - Enable/disable comb filter vertical enhancer
*      - To and from standby
*      - Mute (deselects video inputs) 
*      - Display off/on
*      - S source display during TheaterMaster status mode
*
*  2) SwitchMaster Front Panel commands:
*      - S-video mode (from SwitchMaster front panel)
*
*  3) Code size: 497 bytes out of 2048 still available (ver 0.003)
*
*
* Functional blocks of program:
* ============================
*  - main loop looks for incoming IR codes and services them.
*  - RTI (30 Hz) checks FP and leaves keypresses to be serviced
*    as IR codes, also keeps track of time-outs etc.
*  - make only low-level routines implementation-dependent
*
***********************************************************************
*
*                  C P U    P O R T    U S A G E
*
* NOTE: A lowercase "p" before the I or O direction flag indicates a
*       port bit that must be programmed for the indicated direction.
*
***********************************************************************
* Port A: ($1000)  DIP switch, 
*                  Main Video Input Selects 1,2,3,4
*
*  Pin:    Dir:     
*
*  PA7     pO       Main video input select 4
*  PA6      O       Main video input select 3
*  PA5/OC3  O       Main video input select 2
*  PA4/OC4  O       Main video input select 1
*  PA3     pI       DIP sw 4  A
*  PA2/IC1  I       DIP sw 3  B
*  PA1      I       DIP sw 2  C
*  PA0      I       DIP sw 1  D
*
***********************************************************************
* Port B: ($1004)  Front panel LEDs
*                  Y/C separator, Vertical Enhancer
*
*  Pin:    Dir:     
*
*  PB7      O       Y/C Relay and Front Panel "S" LED 
*                    {0 = comb filter Y/C output routed to S-output}
*                    {1 = S-input routed to S-output}
*  PB6      O       Vertical Enhancer {0 = OFF, 1 = ON}
*  PB5      O       Front Panel LED 6
*  PB4      O       Front Panel LED 5
*  PB3      O       Front Panel LED 4
*  PB2      O       Front Panel LED 3
*  PB1      O       Front Panel LED 2
*  PB0      O       Front Panel LED 1

*
***********************************************************************
* Port C:  ($1003) Main video input selects 5,6
*                  Tape/Mon video input selects
*
*  Pin:   Dir:      Function:      
*                 
*  PC7    pO        Main video input select 6 
*  PC6    pO        Main video input select 5
*  PC5    pO        Tape/Mon video input select 6
*  PC4    pO        Tape/Mon video input select 5
*  PC3    pO        Tape/Mon video input select 4
*  PC2    pO        Tape/Mon video input select 3
*  PC1    pO        Tape/Mon video input select 2
*  PC0    pO        Tape/Mon video input select 1
*
***********************************************************************
* Port D:  ($1008) RS-232 SCI interface to TheaterMaster.
*
*  Pin:      Dir:   Function:
*              
*  PD5/SS    pO     Spare (4.7 k pull-up RSIP3)
*  PD4/SCK   pO     Spare (4.7 k pull-up RSIP3)
*  PD3/MOSI  pO     Spare (4.7 k pull-up RSIP3)
*  PD2/MISO  pI     Spare (4.7 k pull-up RSIP3)
*  PD1/TxD   pO     TxD (serial data to TheaterMaster)
*  PD0/RxD   pI     RxD (serial data from TheaterMaster)
*
***********************************************************************
* Port E:  ($100A) Front Panel Keypad.
*
*  Pin:   Dir:      Function:
*
*  PE7     I        Spare (error: should be grounded; currently is floating)
*  PE6     I        Key [S]   
*  PE5     I        Key [v6]
*  PE4     I        Key [v5]
*  PE3     I        Key [v4]
*  PE2     I        Key [v3]
*  PE1     I        Key [v2]
*  PE0     I        Key [v1]
*                     

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%   E Q U A T E S   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ram_end         equ     $00ff
regbase         equ     $1000

***********************************************************************
* Port address offsets (use indexed addressing offset,x)...
***
porta   equ     $00     Port A data register
*                        (PA7,PA6,PA5,PA4;PA3,PA2,PA1,PA0)
pioc    equ     $02     Parallel I/O control register
*                        (STAF,STAI,CWOM,HNDS;OIN,PLS,EGA,INVB)
portc   equ     $03     Port C data register
*                        (PC7,PC6,PC5,PC4;PC3,PC2,PC1,PC0)
portb   equ     $04     Port B data register
*                        (PB7,PB6,PB5,PB4;PB3,PB2,PB1,PB0)
portcl  equ     $05     Port C latched data register
*                        (PCL7,PCL6,PCL5,PCL4;PCL3,PCL2,PCL2,PCL1,PCL0)
ddrc    equ     $07     Data direction register for port C
*                        (DDC7,DDC6,DDC5,DDC4;DDC3,DDC2,DDC1,DDC0)
portd   equ     $08     Port D data register
*                        (0,0,PD5,PD4;PD3,PD2,PD1,PD0)
ddrd    equ     $09     Data direction register for port D
*                        (0,0,DDD5,DDD4;DDD3,DDD2,DDD1,DDD0)
porte   equ     $0a     Port E data register
*                        (PE7,PE6,PE5,PE4;PE3,PE2,PE1,PE0)
cforc   equ     $0b     Timer compare force register
*                        (FOC1,FOC2,FOC3,FOC4;FOC5,0,0,0)
oc1m    equ     $0c     Output compare 1 mask register
*                        (OC1M7,OC1M6,OC1M5,OC1M4;OC1M3,0,0,0)
oc1d    equ     $0d     Output compare 1 data register
*                        (OC1D7,OC1D6,OC1D5,OC1D4;OC1D3,0,0,0)
tcnt    equ     $0e     Free running timer counter register (16-bit)
tic1    equ     $10     Timer input capture register 1 (16-bit)
tic2    equ     $12     Timer input capture register 2 (16-bit)
tic3    equ     $14     Timer input capture register 3 (16-bit)
toc1    equ     $16     Timer output compare register 1 (16-bit)
toc2    equ     $18     Timer output compare register 2 (16-bit)
toc3    equ     $1a     Timer output compare register 3 (16-bit)
toc4    equ     $1c     Timer output compare register 4 (16-bit)
ti4o5   equ     $1e     Timer input compare 4/output compare 5 register (16-bit)                   
tctl1   equ     $20     Timer control register 1 
*                        (OM2,OL2,OM3,OL3;OM4,OL4,OM5,OL5)
tctl2   equ     $21     Timer control register 2 
*                        (EDG4B,EDG4A,EDG1B,EDG1A;EDG2B,EDG2A,EDG3B,EDG3A)
tmsk1   equ     $22     Main timer interrupt mask register 1
*                        (OC1I,OC2I,OC3I,OC4I;OC5I,IC1I,IC2I,IC3I)
tflg1   equ     $23     Main timer interrupt flag register 1
*                        (OC1F,OC2F,OC3F,OC4F;OC5F,IC1F,IC2F,IC3F)
tmsk2   equ     $24     Misc. timer interrupt mask register 2
*                        (TOI,RTII,PAOVI,PAII;0,0,PR1,PR0)
tflg2   equ     $25     Misc. timer interrupt flag register 2
*                        (TOF,RTIF,PAOVF,PAIF;0,0,0,0)
pactl   equ     $26     Pulse accumulator control register
*                        (DDRA7,PAEN,PAMOD,PEDGE;DDRA3,I4/O5,RTR1,RTR0)
pacnt   equ     $27     Pulse accumulator count register
spcr    equ     $28     SPI control register
*                        (SPIE,SPE,DWOM,MSTR;CPOL,CPHA,SPR1,SPR0)
spsr    equ     $29     SPI status register
*                        (SPIF,WCOL,0,MODF;0,0,0,0)
spdr    equ     $2a     SPI data register
baud    equ     $2b     SCI baud rate control register
*                        (TCLR,0,SCP1,SCP0;RCKB,SCR2,SCR1,SCR0)
sccr1   equ     $2c     SCI control register 1
*                        (R8,T8,0,M;WAKE,0,0,0)
sccr2   equ     $2d     SCI control register 2
*                        (TIE,TCIE,RIE,ILIE;TE,RE,RWU,SBK)
scsr    equ     $2e     SCI status register
*                        (TDRE,TC,RDRF,IDLE;OR,NF,FE,0)
scdr    equ     $2f     SCI data register
*
adctl   equ     $30     A/D control/status register
*
adr1    equ     $31     A/D result register 1
*
adr2    equ     $32     A/D result register 2
*
adr3    equ     $33     A/D result register 3
*
adr4    equ     $34     A/D result register 4
*
bprot   equ     $35     EEPROM block protect 
*                        (0,0,0,PTCON;BPRT3,BPRT2,BPRT1,BPRT0)
option  equ     $39     System configuration options
*                        (ADPU,CSEL,IRQE,DLY;CME,0,CR1,CR2)
coprst  equ     $3a     Arm/Reset COP timer circuitry
pprog   equ     $3b     EEPROM programming register
*                        (ODD,EVEN,0,BYTE;ROW,ERASE,EELAT,EEPGM)
hprio   equ     $3c     Highest priority interrupt and misc.
*                        (RBOOT,SMOD,MDA,IRV;PSEL3,PSEL2,PSEL1,PSEL0)
init    equ     $3d     RAM and I/O mapping register
*                        (RAM3,RAM2,RAM1,RAM0;REG3,REG2,REG1,REG0)
test1   equ     $3e     Factory test register
*                        (TILOP,0,OCCR,CBYP;DISR,FCM,FCOP,TCON)
config  equ     $3f     Configuration control register
*                        (EE3,EE2,EE1,EE0;1,NOCOP,1,EEON)


*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%  RAM Variables  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

       org      $0000           Start of cpu RAM.

chars_recd:     rmb     1       Characters received                          
fp_recd:        rmb     1       Front panel push
s_timer:        rmb     2       S toggle timer debouncing
in_stand:       rmb     1       In standby flag

*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%  DATA and lookup tables  %%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



	org     $F800           Start address of 2K cpu EEPROM.


vid_code:       equ     $16
S_vid_code:     equ     $16+$80
tm_code:        equ     $17
SM_ex_code:     equ     $53
s_toggle:       equ     $18
v_enh_on:       equ     $19
v_enh_off:      equ     $1a

commands        fcb     #vid_code,#S_vid_code,#tm_code,#SM_ex_code   
		fcb     #s_toggle,#v_enh_on,#v_enh_off
end_commands:




*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%                                  %%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%% PROGRAM STARTS HERE OUT OF RESET %%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%                                  %%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


START:  lds     #ram_end        Establish top of stack in cpu internal RAM.
*-----------------------------------------------------------------+
*     Do not change the following global variable in the x reg!!! |
	ldx     #regbase        Global variable!!!                |
*-----------------------------------------------------------------+       

* Important: If it is necessary to change the default settings of INIT, 
*            TMSK2 (PR[0:1] bits only), OPTION, and BPROT, do it here 
*            (must be done within the first 64 E-clock cycles after
*            reset in the normal cpu operating modes).


	sei                        Disable interrupts globally for soft restart.


	bclr    bprot,x %00000001  Disable block protect
*                                   for 1st 512 EEPROM bytes.
	bset    pactl,x %10000000  Configure bit 7 of port A as output.
	bset    ddrc,x  %11111111  Configure port C as output.
	bset    ddrd,x  %00111010  Configure bits 1,3,4,5 of port D as outputs.

	ldaa    #%00110000         Set SCI baud rate to 9600 baud
	staa    baud,x
	ldaa    #%00000000         1,8,1 data format
	staa    sccr1,x 
	ldaa    #%00001100         Rx enabled, no wake-up or breaks
	staa    sccr2,x            Tx enabled

	bset    pactl,x %00000011  RTI rate = 30.5 Hz (E/2^16); 32.768 ms.
	bclr    tmsk2,x %01000000  Disable real time interrupts.

	ldaa    #%00000100         Elevate SCI interrupts to highest priority
	staa    hprio,x

	bset    in_stand $ff       We are in standby first time through

;* Initialize all ports to relays OFF

	bclr    porta,x %11110000       Deselect Vid. 1-4
        bclr    portc,x %11111111       Deselect Vid. 5,6 & TM video relays
	bclr    portb,x %11111111       Deselect S vid, V-enh. LEDs off

        cli                        Enable interrupts globally.

	
	jmp     main_loop



*********************************************************************
********************       Main Loop       **************************
*********************************************************************
main_loop:
	clr     chars_recd
	clr     fp_recd
	ldd     #0
	std     s_timer

inloop:
	brset   scsr,x %00100000 sci_recd    See if SCI character received
	
	brset   in_stand $ff inloop         If in standby, no FP checks

	ldaa    porte,x
	coma                                 Complement since Port E is active lo
	anda    #$7f                         Get FP button push information
	bne     fp_detect                    If something pushed, store info
       

inloop_2:
	ldaa    fp_recd                      Check if FP push just received
	beq     inloop                       If not, loop again

	cmpa    #%01000000                   Check for S push
	bne     fp_success                   If not, no need to debounce

	ldd     s_timer
	cpd     #100
	bls     inloop                       Wait for long time-out
	
	ldaa    fp_recd
	bra     fp_success                   If FP pushed and released, do it!




*********************************************************************
** Front panel push detected
*********************************************************************
fp_detect:
	staa    fp_recd                 Store front panel push
	
	ldd     s_timer                 Update debounce timer
	addd    #1
	std     s_timer

	bra     inloop



fp_success:
	tab                             Get bit number in B          
	clra
fp_succ_loop:
	inca                            Count number of shifts
	lsrb
	bcc     fp_succ_loop            Keep shifting if no 0 bit found

	deca
	tab                             B contains a number 0-6


	cmpb    #6
	bne     fp_vid_num

	
	
	
	ldaa    portb,x
	eora    #$80                    Toggle S bit
	staa    portb,x
	jmp     main_loop       

fp_vid_num:
	jmp     do_video

	
	
	
	
	
*********************************************************************
** Character received on SCI
*********************************************************************
sci_recd:        
	ldaa    scdr,x
	jsr     send_sci                Echo character
	
	ldab    chars_recd         
	bne     check_2nd               Non-zero means check for 2nd character

	
* Check for 1st character                                 

	jsr     check_comm              Check for valid command received
	tstb                            
	beq     check_sby               If not valid, check for sby

* Check for vert enh. codes
	
v_enh_check:
	cmpa    #s_toggle               Check for v-enh toggle
	bne     sci_recd_1
	jmp     s_togg_comm
sci_recd_1:
	cmpa    #v_enh_on               Check for v-enh on
	bne     sci_recd_2
	jmp     ve_on   
sci_recd_2:
	cmpa    #v_enh_off              Check for v-enh off
	bne     sci_recd_3
	jmp     ve_off    
	
sci_recd_3:
	staa    chars_recd              If valid, store character received
	jmp     inloop                  Go and check for characters again



check_sby:
	cmpa    #$ff                    Check for standby
	bne     sci_recd_end            If not, loop again

	jmp     into_standby            If so, set into standby mode

sci_recd_end:
	jmp     inloop                  No valid commands so loop again



*********************************************************************
** Process 2 character command 
** 1st character is in B, char. just received is in A
**
*********************************************************************
check_2nd:
	cmpa    #$ff
	bne     check_2nd_1             Check for Sig. in sby

	jmp     into_standby

check_2nd_1:
	andb    #$7f                    Mask out msb of 1st character
	cmpb    #vid_code
	beq     vid_num
	cmpb    #tm_code
	beq     vid_num                 If V or v, check for 1-6

	cmpb    #SM_ex_code
	bne     check_2nd_2
	cmpa    #'M'
	bne     check_2nd_2             Sx is not a command

	jmp     sm_exists               SM command puts out a *

check_2nd_2:
	jsr     check_comm              Check if new character is valid 1st
	tstb
	bne     check_2nd_3             
	bra     not_command             If not valid, flush all

check_2nd_3:
	jmp     v_enh_check




vid_num:
	bclr    in_stand $ff            Not in standby any more!

	cmpa    #$15                    Check if 1-6 received
	bhi     not_num                 If not, check if next char is valid
	cmpa    #$10
	blo     not_num      

	anda    #$0f                    Convert character to number 0-5
	
	cmpb    #tm_code                See if tape-mon selection
	beq     do_tm_video             
	
	tab                             Selection is in B

	ldaa    chars_recd
	bita    #$80                    Check for MSB
	beq     unset_S                 If not, do normal video or TM video
	
set_S:        
	bset    portb,x %10000000       Turn on S video
	bra     go_to_vids
unset_S:        
	bclr    portb,x %10000000       Turn off S video


go_to_vids:
	bra     do_video


not_num:
	jsr     check_comm              Check if a valid char is received
	tstb
	beq     not_command
	
	jmp     v_enh_check             Go check for v-enh

not_command:
	jmp     main_loop               Flush and loop again




***************************************************************
*Switch main video input mux. relays
*
*--------------------------------------------
*Lookup table for video_main_sw subroutine:
*
*Port:            Port C    Port A      Port B
*Relay #:          65       4321
*
v_main_mux_tab:
	fcb     %00000000,  %00010000,  %00000001       Main video input 1
	fcb     %00000000,  %00100000,  %00000010       Main video input 2
	fcb     %00000000,  %01000000,  %00000100       Main video input 3
	fcb     %00000000,  %10000000,  %00001000       Main video input 4
	fcb     %01000000,  %00000000,  %00010000       Main video input 5
	fcb     %10000000,  %00000000,  %00100000       Main video input 6
*
*
do_video:
     
	ldy     #v_main_mux_tab
	ldaa    #3
	mul                           Adjust number for table spacing.
	aby                           Point to table.
	
	ldaa    0,y                   Get Port C select bits.
	ldab    portc,x
	andb    #%00111111            Keep Tape/Mon bits
	aba                           Add new main i/p bits
	staa    portc,x

	iny
	ldaa    0,y                   Get Port A select bits.
	ldab    porta,x
	andb    #%00001111            Keep non-i/p bits
	aba                           Add new main i/p bits
	staa    porta,x         

	iny
	ldaa    0,y                   Get Port B select bits
	ldab    portb,x
	andb    #%11000000            Keep S video selection and v-enh selection
	aba
	staa    portb,x               Add new light bits

	jmp     main_loop


***************************************************************
*Switch tape/mon video input mux. relays
*
*--------------------------------------------
*Lookup table for video_tm_sw subroutine:
*
*Port:            Port C   
*Relay #:          65      
*
v_tm_mux_tab:
	fcb     %00000001       Tape/mon video input 1
	fcb     %00000010       Tape/mon video input 2
	fcb     %00000100       Tape/mon video input 3
	fcb     %00001000       Tape/mon video input 4
	fcb     %00010000       Tape/mon video input 5
	fcb     %00100000       Tape/mon video input 6


do_tm_video:
	tab
	ldy     #v_tm_mux_tab
	aby
	ldaa    0,y                     Get Port C select bits
	ldab    portc,x
	andb    #%11000000              Keep non-i/p bits
	aba                             Add new i/p bits
	staa    portc,x                 
	
	jmp     main_loop
	




	       

**********************************************************************
** Sending SCI
**********************************************************************
send_sci:
	brclr   scsr,x %10000000 *                  Wait for Transmit complete
	staa    scdr,x
	rts


*********************************************************************
** Refresh upon Sig. coming out of standby
*********************************************************************
into_standby:
	bset    in_stand  $ff           Flag in standby
	
	bclr    porta,x %11110000       Deselect Vid. 1-4
	bclr    portc,x %11000000       Deselect Vid. 5,6
	bclr    portb,x %11111111       Deselect S vid, V-enh. LEDs off
	

	jmp     main_loop               Start looping again

*********************************************************************
** Send out a * if SM code comes in (to determine if S/M exists)
*********************************************************************
sm_exists:
	ldaa    #'*'
	jsr     send_sci

	jmp     main_loop               Flush and loop again



**********************************************************************
** Checking for valid character:
** Enter with A containing character received
** Returns with B=0 if not valid, B non-zero if valid
**********************************************************************
check_comm:
	ldy     #commands
which_loop:
	cmpa    0,y                     Check if character is in command list
	beq     comm_ok                 If so, store first character and loop
	iny
	cpy     #end_commands+1         Check if end of list reached
	bne     which_loop              If not, try next entry
comm_not_ok:
	clrb
	rts

comm_ok:
	ldab    #1
	rts


********************************************************************
** 
********************************************************************
s_togg_comm:
	ldaa    portb,x
	eora    #%10000000              Toggle S video
	staa    portb,x         
	jmp     main_loop               
ve_on:                                  
	bset    portb,x #%01000000      V-Enh on
	jmp     main_loop
ve_off:
	bclr    portb,x #%01000000      V-Enh off
	jmp     main_loop

********************************************************************
* dly230 -  Subroutine to delay 230 ms (for E=2MHz)
* dly40  -  Subroutine to delay 62 ms  (for E=2MHz)
* dly20  -  Subroutine to delay 20 ms  (for E=2MHz)
* dly5   -  Subroutine to delay 5 ms   (for E=2MHz)
*
* Approximate delay = Y * 7~ * 500 nS per ~ 
*
* Note: Since this routine only uses cpu registers and the stack, it
*       is inherently re-entrant and may freely be called by main-line
*       code and interrupt service routines.
*
* Regs altered: None
***
dly230: pshy                 
	ldy     #65535
	bra     dloop
dly40:  pshy
	ldy     #11200
	bra     dloop
dly20:  pshy
	ldy     #5714
	bra     dloop
dly5:   pshy
	ldy     #1428
	bra     dloop
dly1:   pshy
	ldy     #280       
	bra     dloop

dloop   dey 
	bne     dloop 
	
	puly   
	rts              ** Return **


*********************************************************************

SVXIRQ: clra
	staa    porta,x         Blank display
	staa    portb,x          and turn off
	staa    portc,x          video mux relays.
	bra     *                due to falling VDD...

*****************************************************************

**************************************************************************
* Dummy service routine for unused interrupts:

SVSCI:
SVSPI:             
SVPAIE:            
SVPAO:             
SVTOF:
SVTOC1:            
SVTOC2:            
SVTOC3:            
SVTOC4:            
SVTOC5:            
SVTIC3: 
SVTIC2:            
SVTIC1:
SVRTI:
SVIRQ:
SVSWI:
SVILLOP: 
SVCOP:  
SVCLM:  rti


***********************************************************************
* Interrupt vector table...
***
       org      $ffd6

Vsci:   fdb     SVSCI    
Vspi:   fdb     SVSPI
Vpaie:  fdb     SVPAIE
Vpao:   fdb     SVPAO
Vtof:   fdb     SVTOF       
Vtoc5:  fdb     SVTOC5 
Vtoc4:  fdb     SVTOC4 
Vtoc3:  fdb     SVTOC3      
Vtoc2:  fdb     SVTOC2
Vtoc1:  fdb     SVTOC1    
Vtic3:  fdb     SVTIC3
Vtic2:  fdb     SVTIC2
Vtic1:  fdb     SVTIC1      
Vrti:   fdb     SVRTI       
Virq:   fdb     SVIRQ       
Vxirq:  fdb     SVXIRQ      Power fail
Vswi:   fdb     SVSWI       
Villop: fdb     SVILLOP
Vcop:   fdb     SVCOP
Vclm:   fdb     SVCLM
Vrst:   fdb     START       Cpu reset controlled by low-voltage inhibit (LVI).device.
*
	end
