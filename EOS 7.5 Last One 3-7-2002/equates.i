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
;   equates.i
;
;************************************************
;*
;*     Global Constants Include File
;*
;************************************************

       include "c:\1work\eos-i\build.i"


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%                                      %%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%    G L O B A L    C O N S T A N T S    %%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%                                      %%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ram_end:         equ $03ff ;Top of 68HC11F1 RAM
ram_start:       equ $0000
regbase:         equ $1000

;**********************************************************************
; One-Byte Port Register Offsets (Use Offset,X to access...)
;
porta:          equ $00   ;Port A data register
                          ; (PA7,PA6,PA5,PA4;PA3,PA2,PA1,PA0)
ddra:           equ $01   ;Data direction register for port A
                          ; (DDA7,DDA6,DDA5,DDA4;DDA3,DDA2,DDA1,DDA0)
portg:          equ $02   ;Port G data register  
                          ; (PG7,PG6,PG5,PG4;PG3,PG2,PG1,PG0)
ddrg:           equ $03   ;Data direction register for port G
                          ; (DDG7,DDG6,DDG5,DDG4;DDG3,DDG2,DDG1,DDG0)
portb:          equ $04   ;Port B data register
                          ; (PB7,PB6,PB5,PB4;PB3,PB2,PB1,PB0)
portf:          equ $05   ;Port F data register
                          ; (PF7,PF6,PF5,PF4;PF3,PF2,PF1,PF0)
portc:          equ $06   ;Port C data register
                          ; (PC7,PC6,PC5,PC4;PC3,PC2,PC1,PC0)
ddrc:           equ $07   ;Data Direction register for port C
                          ; (DDC7,DDC6,DDC5,DDC4;DDC3,DDC2,DDC1,DDC0)
portd:          equ $08   ;Port D data register
                          ; (0,0,PD5,PD4;PD3,PD2,PD1,PD0)
ddrd:           equ $09   ;Data Direction register for port D
                          ; (0,0,DDD5,DDD4;DDD3,DDD2,DDD1,DDD0)
porte:          equ $0a   ;Port E data register
                          ; (PE7,PE6,PE5,PE4;PE3,PE2,PE1,PE0)
cforc:          equ $0b   ;Timer Compare Force Register
                          ; (FOC1,FOC2,FOC3,FOC4;FOC5,0,0,0)
oc1m:           equ $0c   ;Output Compare 1 Mask register
                          ; (OC1M7,OC1M6,OC1M5,OC1M4;OC1M3,0,0,0)
oc1d:           equ $0d   ;Output Compare 1 Data register
                          ; (OC1D7,OC1D6,OC1D5,OC1D4;OC1D3,0,0,0)
tcnt:           equ $0e   ;Timer Count Register

tic1:           equ $10   ;Timer Input Capture register 1

tic2:           equ $12   ;Timer Input Capture register 2

tic3:           equ $14   ;Timer Input Capture register 3

toc1:           equ $16   ;Timer Output Compare register 1

toc2:           equ $18   ;Timer Output Compare register 2

toc3:           equ $1a   ;Timer Output Compare register 3

toc4:           equ $1c   ;Timer Output Compare register 4

ti4o5:          equ $1e   ;Timer Input Compare 4 or Output Compare 5 register


;**********************************************************************
;Two-Byte Timer Registers (High,Low -- Use LDD, STD to access...)
;
tcnt.:        equ $100e   ;Timer Count Register

tic1.:        equ $1010   ;Timer Input Capture register 1

tic2.:        equ $1012   ;Timer Input Capture register 2

tic3.:        equ $1014   ;Timer Input Capture register 3

toc1.:        equ $1016   ;Timer Output Compare register 1

toc2.:        equ $1018   ;Timer Output Compare register 2

toc3.:        equ $101a   ;Timer Output Compare register 3

toc4.:        equ $101c   ;Timer Output Compare register 4

ti4o5.:       equ $101e   ;Timer Input Compare 4 or Output Compare 5 register


;**********************************************************************
;One-Byte Control Register Offsets (Use Offset,X to access...)
;
tctl1:          equ $20   ;Timer Control register 1
                          ; (OM2,OL2,OM3,OL3;OM4,OL4,OM5,OL5)
tctl2:          equ $21   ;Timer Control register 2
                          ; (EDG4B,EDG4A,EDG1B,EDG1A;EDG2B,EDG2A,EDG3B,EDG3A)
tmsk1:          equ $22   ;Main Timer interrupt Mask register 1
                          ; (OC1I,OC2I,OC3I,OC4I;I4/O5I,IC1I,IC2I,IC3I)
tflg1:          equ $23   ;Main Timer interrupt Flag register 1
                          ; (OC1F,OC2F,OC3F,OC4F;I4/O5F,IC1F,IC2F,IC3F)
tmsk2:          equ $24   ;Misc Timer interrupt Mask register 2
                          ; (TOI,RTII,PAOVI,PAII;0,0,PR1,PR0)
tflg2:          equ $25   ;Misc Timer interrupt Flag register 2
                          ; (TOF,RTIF,PAOVF,PAIF;0,0,0,0)
pactl:          equ $26   ;Pulse Accumulator Control register
                          ; (0,PAEN,PAMOD,PEDGE;0,I4/O5,RTR1,RTR0)
pacnt:          equ $27   ;Pulse Accumulator Count register

spcr:           equ $28   ;SPI Control Register
                          ; (SPIE,SPE,DWOM,MSTR;CPOL,CPHA,SPR1,SPR0)
spsr:           equ $29   ;SPI Status Register
                          ; (SPIF,WCOL,0,MODF;0,0,0,0)
spdr:           equ $2a   ;SPI Data Register

baud:           equ $2b   ;SCI Baud Rate Control Register
                          ; (TCLR,0,SCP1,SCP0;RCKB,SCR2,SCR1,SCR0)
sccr1:          equ $2c   ;SCI Control Register 1
                          ; (R8,T8,0,M;WAKE,0,0,0)
sccr2:          equ $2d   ;SCI Control Register 2
                          ; (TIE,TCIE,RIE,ILIE;TE,RE,RWU,SBK)
scsr:           equ $2e   ;SCI Status Register
                          ; (TDRE,TC,RDRF,IDLE;OR,NF,FE,0)
scdr:           equ $2f   ;SCI Data Register

adctl:          equ $30   ;A/D Control/status Register
                          ; (CCF,0,SCAN,MULT;CD,CC,CB,CA)
adr1:           equ $31   ;A/D Result Register 1

adr2:           equ $32   ;A/D Result Register 2

adr3:           equ $33   ;A/D Result Register 3

adr4:           equ $34   ;A/D Result Register 4

bprot:          equ $35   ;Block Protect register
                          ; (0,0,0,PTCON;BPRT3,BPRT2,BPRT1,BPRT0)
resv2:          equ $36   ;Reserved

resv3:          equ $37   ;Reserved

opt2:           equ $38   ;System Configuration Options
                          ; (GWOM,CWOM,CLK4X,0;0,0,0,0)
option:         equ $39   ;System configuration Options
                          ; (ADPU,CSEL,IRQE,DLY;CME,FCME,CR1,CR0)
coprst:         equ $3a   ;Arm/Reset COP timer circuitry

pprog:          equ $3b   ;EEPROM Programming register
                          ; (ODD,EVEN,0,BYTE;ROW,ERASE,EELAT,EEPGM)
hprio:          equ $3c   ;Highest Priority Interrupt and misc.
                          ; (RBOOT,SMOD,MDA,IRV;PSEL3,PSEL2,PSEL1,PSEL0)
init:           equ $3d   ;RAM and I/O Mapping Register
                          ; (RAM3,RAM2,RAM1,RAM0;REG3,REG2,REG1,REG0)
test1:          equ $3e   ;Factory Test register
                          ; (TILOP,0,OCCR,CBYP;DISR,FCM,FCOP,0)
config:         equ $3f   ;Configuration Control Register
                          ; (EE3,EE2,EE1,EE0;1,NOCOP,1,EEON)
csstrh:         equ $5c   ;Chip Select Clock Stretch Select
                          ; (IO1SA,IO1SB,IO2SA,IO2SB;GSTHA,GSTHB,PSTHA,PSTHB) 
csctl:          equ $5d   ;Chip Select Control Register
                          ; (IO1EN,IO1PL,IO2EN,IO2PL;GCSPR,PCSEN,PSIZA,PSIZB)
csgadr:         equ $5e   ;General Purpose Chip Select Address Register
                          ; (GA15,GA14,GA14,GA12;GA11,GA10,0,0)
csgsiz:         equ $5f   ;General Purpose Chip Select Size Register
                          ; (IO1AV,IO2AV,0,GNPOL;GAVLD,GSIZA,GSIZB,GSIZC)

;**********************************************************************
;Masks for serial port
;        
portdwom:       equ $20
baud1200:       equ $B3
baud9600:       equ $B0
tena:           equ $08   ;Transmit ENAble
rdrf:           equ $20   ;Receive Data Register Full
tdre:           equ $80   ;Transmit Data Register Empty



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%    C S 4 2 2 6   D E F I N T I O N S    %%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;Strings defined elsewhere.


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%                                         %%%%%%%%%%%%%%%%
;%%%%%%%%%%%%    P C M 1 7 3 2   D E F I N T I O N S    %%%%%%%%%%%%%%%
;%%%%%%%%%%%%%                                         %%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;PCM1732 software mode control flags:

REGISTER_0:     equ     %00*$0200
LDL:            equ      %1*$0100     ;Set L-ch attenuation.
LCHAN_VOL:      equ     %11111111     ;Attenuation = 0 dB.
MODE0:          equ     REGISTER_0+LDL+LCHAN_VOL
_MODE00:         equ     $01ff         ;Check for debugging.

;------------------------------------------

REGISTER_1:     equ     %01*$0200
LDR:            equ      %1*$0100     ;Set R-ch attenuation.
RCHAN_VOL:      equ     %11111111     ;Attenuation = 0 dB.
MODE1:          equ     REGISTER_1+LDR+RCHAN_VOL
_MODE11:         equ     $03ff         ;Check for debugging.

;------------------------------------------

REGISTER_2:     equ     %10*$0200
CB:             equ     %00*$0080     ;HDCD control bit location -- %00=16, %01=20, %10=res., %11=24.
SCA:            equ     %1*$0040      ;Gain scaling -- Digital=%0, Analog=%1.
FSS:            equ     %0*$0020      ;Sampling rate -- %0 fs <= 52 kHz, %1 fs > 52 kHz.
IW:             equ     %11*$0008     ;%00 Input Word (also set I2S=0) 16-bit RJ (std).
                                      ;%01     "             "         20-bit RJ (std).
                                      ;%10     "             "         24-bit RJ (std).
                                      ;%11     "             "         24-bit LJ (MSB 1st).
                                      ;%00     "      (also set I2S=1) 16-bit I2S.
                                      ;%01     "             "         26-bit I2S.
                                      ;%10     "             "         reserved.
                                      ;%11     "             "         reserved.
OPE:            equ     %0*$0004      ;DAC operation -- %0 Normal, %1 Disabled.
DEM:            equ     %0*$0002      ;De-emphasis -- %0=off, %1=on.
MUTE:           equ     %0*$0001      ;Soft Mute -- %0=off, %1=on.
MODE2:          equ     REGISTER_2+CB+SCA+FSS+IW+OPE+DEM+MUTE
_MODE22:         equ     $0458         ;Check for debugging.

DEM_on:         equ     %1*$0002      ;De-emphasis ON.
DEM_off:        equ     %0*$0002      ;De-emphasis OFF.

MODE2_DEM_on:   equ     REGISTER_2+CB+SCA+FSS+IW+OPE+DEM_on+MUTE
MODE2_DEM_off:  equ     REGISTER_2+CB+SCA+FSS+IW+OPE+DEM_off+MUTE

;------------------------------------------

REGISTER_3:     equ     %11*$0200
IZD:            equ     %0*$0100      ;Zero Detect Mute -- %0=off, %1=on.
SF:             equ     %10*$0040     ;%00 Reserved.
                                      ;%01 De-Emphasis Sampling Rate 48 kHz.
                                      ;%10             "             44.1 kHz.
                                      ;%11             "             32 kHz.
CKO:            equ     %0*$0020      ;Bufferred clock -- %0 XTO = XTI, %1 1/2 frequency. 
REV:            equ     %0*$0010      ;DAC output phase -- %0=normal, %1=inverted.
ATC:            equ     %0*$0004      ;Attenuator Control -- %0=individual channel, %1=common..
LRP:            equ     %1*$0002      ;%0 L-ch = 1, R-ch = 0, %1 L-ch = 0, R-ch = 1.
I2S:            equ     %0*$0001      ;Data format is not I2S (depends on IW setting)
MODE3:          equ     REGISTER_3+IZD+SF+CKO+REV+ATC+LRP+I2S
_MODE33:         equ     $0682         ;Check for debugging.

SF48:           equ     %01*$0040     ;48 kHz
SF441:          equ     %10*$0040     ;41.1 kHz
SF32:           equ     %11*$0040     ;32 kHz

MODE3_48:       equ     REGISTER_3+IZD+SF48+CKO+REV+ATC+LRP+I2S
MODE3_441:      equ     REGISTER_3+IZD+SF441+CKO+REV+ATC+LRP+I2S
MODE3_32:       equ     REGISTER_3+IZD+SF32+CKO+REV+ATC+LRP+I2S

;***********************************************************************
;* Default values of the IR remote decode parameters:  
;* Ceramic resonator frequency = 500 kHz (T=0.5 usec)
;*
;*          Bit type   Pulse period   IC1 counts @ 2 MHz
;*                               
;*            gap (hi)  1T    0.6 ms         1200
;*             0        2T    1.2 ms         2400
;*             1        3T    1.8 ms         3600
;*            sync      6T    3.6 ms         7200
;***
hi_sync:        equ     8000    ;Higher limit for sync bits (+10%)
lo_sync:        equ     6400    ;Lower  limit for sync bits (-10%)

hi_one:         equ     4000    ;Higher limit for 1
lo_one:         equ     3200    ;Lower  limit for 1

hi_zero:        equ     2650    ;Higher limit for 0
lo_zero:        equ     2150    ;Lower  limit for 0

size:           equ     8       ;# of bits in frame


;*** Pulse timing (in cycles) ***

sync:           equ     6000        ;3.0ms + 0.6ms pulse for sync 
one:            equ     2400        ;1.8ms + 0.6ms pulse for '1'
zero:           equ     1200        ;1.2ms + 0.6ms pulse for '0'


;***********************************************************************
;* Screen numbers
;*
;***
.SCREEN.Main:             equ   1   ;Main screen
.SCREEN.VU_meter:         equ   2   ;VU Meter screen
.SCREEN.Spkr_Adj:         equ   3   ;Speaker Adjustment screen
.SCREEN.Spkr_Cfg:         equ   4   ;Speaker Configuration & Cinema Type screen
.SCREEN.Bass_Man:         equ   5   ;Bass Management screen
.SCREEN.Spkr_Dist:        equ   6   ;Speaker Distances screen
.SCREEN.Anlg_Atten:       equ   7   ;Analog Input Attenuation screen
.SCREEN.Sys_Config:       equ   8   ;System Configuration screen
.SCREEN.Feat_Sel:         equ   9   ;Features Selection screen
.SCREEN.Dig_AVLink:       equ   10  ;Digital AV Links screen
.SCREEN.Anlg_AVLink:      equ   11  ;Analog AV Links screen
.SCREEN.AnlgPT_AVLink:    equ   12  ;Analog Pass-Thru AV Links screen
.SCREEN.Inp_Data_Stat:    equ   13  ;Input Data Status screen
.SCREEN.Dig_Inp_Desig:    equ   14  ;Digital Input Designator screen
.SCREEN.Anlg_Inp_Desig:   equ   15  ;Analog Input Designator screen
.SCREEN.AnlgPT_Inp_Desig: equ   16  ;Analog Pass-Thru Designator screen
.SCREEN.IR_Test:          equ   17  ;IR Remote Control Test screen

Max_screens:              equ   .SCREEN.IR_Test   ;# of VFD display screens.

;***********************************************************************
;* Various defaults:
;*
;***
freq1:          equ 100             ;Determines beep1 tone freq (100 gives 2 kHz)
tone1dura:      equ 20000/freq1*10  ;Tone duration (2000 @ 2 kHz gives 1.0 s)
beep1dura:      equ 9000/freq1*10   ;Beep duration  (600 @ 2 kHz gives 0.3 s)
savebeep_dura:  equ 2000/freq1*10   ;Beep duration  (200 @ 2 kHz gives 0.3 s)
chirp1_dura:    equ 500/freq1*10    ;Chirp duration  (50 @ 2 kHz gives 0.1 s)

freq3:          equ 140             ;Determines beep3 tone freq (100 gives 2 kHz)
beep3dura:      equ 4000/freq3*10   ;Beep duration  (600 @ 2 kHz gives 0.3 s)

freq2:          equ 112             ;Determines aux. tone freq (120 gives 1.68 kHz)
tone2dura:      equ 16800/freq2*10  ;Tone duration (1400 @ 1.68 kHz gives 1.0 s)
chirp2_dura:    equ 420/freq2*10    ;Chirp duration  (42 @ 1.68 kHz gives 0.1 s)

;************** Table-driven remote stuff
stop:           equ $ff             ;End marker
long:           equ 75              ;75 * 33 ms = 2.5 s timeout
short:          equ 17              ;17 * 33 ms = 0.6 s timeout
very_short:     equ 5               ;0.17 s

;************** Lamp related time-outs
lamp_short:     equ 180             ;6 seconds
lamp_long:      equ  1              ;1/2 hour. Used by VFD too, to switch
                                    ; standby display to dim dots after 1/2 hour.


;*******************************************************************************
;* INFRARED REMOTE KEY CODES
;*
;***
;Note: To facilitate error checking, all IR key codes have four 1s and four 0s.
;      For an 8-bit code, this gives 8!/4!/4! = 70 valid code words.

;** Actual IR remote keys (Custom Remote Angel):

k_pwr:		equ	%00001111	;$0f	1	[POWER] (toggle)	
k_1:            equ     %00010111       ;$17    2       [TM 1]
k_2:            equ     %00011011       ;$1b    3       [TM 2]
k_3:            equ     %00011101       ;$1d    4       [TM 3]
k_4:            equ     %00011110       ;$1e    5       [TM 4]
k_5:            equ     %00100111       ;$27    6       [TM 5]
k_6:            equ     %00101011       ;$2b    7       [TM 6]
k_7:            equ     %00101101       ;$2d    8       [TM 7]
k_8:            equ     %00101110       ;$2e    9       [TM 8]
k_9:            equ     %00110011       ;$33    10      [TM 9]
k_0:            equ     %00110101       ;$35    11      [TM 0]

k_stat_off:     equ     0               ;Check value!!!
k_stat_on:      equ     8

k_surr:		equ	k_7		;		[Surround]
k_mat:		equ	k_8		;		[Matrix]
k_mono:		equ	k_9		;		[Mono]
k_ster:		equ	k_0		;		[Stereo]

ks_1:           equ     %00110110       ;$36    12      [TMS 1]
ks_2:           equ     %00111001       ;$39    13      [TMS 2]
ks_3:           equ     %00111010       ;$3a    14      [TMS 3]
ks_4:           equ     %00111100       ;$3c    15      [TMS 4]
ks_5:           equ     %01000111       ;$47    16      [TMS 5]
ks_6:           equ     %01001011       ;$4b    17      [TMS 6]
ks_7:           equ     %01001101       ;$4d    18      [TMS 7]
ks_8:           equ     %01001110       ;$4e    19      [TMS 8]
ks_9:           equ     %01010011       ;$53    20      [TMS 9]
ks_0:           equ     %01010101       ;$55    21      [TMS 0]

k_LF:           equ     ks_1            ;               [LF]
k_CTR:		equ	ks_2		;	 	[CTR]
k_RF:           equ     ks_3            ;               [RF]
k_LS:           equ     ks_4            ;               [LS]
k_SUB:		equ	ks_5		;	 	[SUB]
k_RS:           equ     ks_6            ;               [RS]

k_F:            equ     %01010110       ;$56    22      [F]      
k_anlg:		equ	%01011001	;$59	23	[Analog]	
k_tape:		equ	%01011010	;$5a	24	[Tape/Mon]	
k_video:        equ     %01011100       ;$5c    25      [Video]  
k_v_enh:        equ     %01100011       ;$63    26      [V-Enh] (toggle)         
k_HFEQ:		equ	%01100101	;$65	27	[HF-EQ] (toggle)   	
k_LN:           equ     %01100110       ;$66    28      [LateNight] (toggle list)  
k_scrn:		equ	%01101001	;$69	29	[Screen] (toggle)		
k_link:		equ	%01101010	;$6a	30	[Link A/V]	
k_mute:		equ	%01101100	;$6c	31	[MUTE] (toggle)		
k_tm_du:        equ     %01110001       ;$71    32      [TM Display UP] 
k_tm_dd:        equ     %01110010       ;$72    33      [TM Display DOWN] 
k_tms_du:       equ     %01110100       ;$74    34      [TMS Display UP] 
k_tms_dd:       equ     %01111000       ;$78    35      [TMS Display DOWN] 
k_tm_sto:       equ     %10000111       ;$87    36      [TM Store] 
k_tm_rcl:       equ     %10001011       ;$8b    37      [TM Recall] 
k_tms_sto:      equ     %10001101       ;$8d    38      [TMS Store] 
k_tms_rcl:      equ     %10001110       ;$8e    39      [TMS Recall] 
k_vup:          equ     %10010011       ;$93    40      [Volume UP]
k_vdn:		equ	%10010101  	;$95	41	[Volume DOWN]  
k_adjust:       equ     %10010110       ;$96    42      [Adjust]         
k_noise_seq:	equ	%10011001	;$99	43	[Noise Seq]	
k_stat_noise:	equ	%10011010	;$9a	44	[Static Noise]   	
k_auto_setup:	equ	%10011100	;$9c	45	[Auto-Setup]	
k_auto_delay:	equ	%10100011	;$a3	46	[Auto-Delay]	
k_spkr_cfg:     equ     %10100101       ;$a5    47      [Spkr Cfg] (= BAL key on older remotes) 
k_x_over:       equ     %10100110       ;$a6    48      [X-Over] 
k_roll_off:     equ     %10101001       ;$a9    49      [Roll-Off] 
k_enter:        equ     %10101010       ;$aa    50      [ENTER] 
k_exit:		equ	%10101100	;$ac	51	[EXIT]		

;** IR codes reserved for EAD and custom installer use:

k_pwr_on:       equ     %10110001       ;$b1    52      [POWER ON]
k_pwr_off:      equ     %10110010       ;$b2    53      [POWER OFF]
k_v_enh_on:     equ     %10110100       ;$b4    54      [V-Enh ON] 
k_v_enh_off:	equ	%10111000	;$b8	55	[V-Enh OFF]
k_HFEQ_on:      equ     %11000011       ;$c3    56      [HF-EQ ON]
k_HFEQ_off:     equ     %11000101       ;$c5    57      [HF-EQ OFF]
k_LN_off:       equ     %11000110       ;$c6    58      [LateNight OFF]
k_LN_low:       equ     %11001001       ;$c9    59      [LateNight LOW]
k_LN_med:       equ     %11001010       ;$ca    60      [LateNight MED]
k_LN_high:      equ     %11001100       ;$cc    61      [LateNight HIGH]
k_scrn_dn:      equ     %11010001       ;$d1    62      [Screen DOWN]
k_scrn_up:      equ     %11010010       ;$d2    63      [Screen UP]
k_mute_on:      equ     %11010100       ;$d4    64      [MUTE ON]
k_mute_off:     equ     %11011000       ;$d8    65      [MUTE OFF]
;k_bright:       equ     %11100001       ;$e1    66      [Brightness] {Backlight brightness [Brightness][n], n=0,1,2,3,4,5}
k_display:      equ     %11100010       ;$e2    67      [Display] {Select display screen [Display][n][n], n=01,02,03,...14}
k_ref.cinema:   equ     %11100100       ;$e4    68      Select Reference Cinema
k_cinema71:     equ     %11100101       ;$e5   *69*     Select Cinema 7.1 (* no parity *)
k_next:         equ     %11101000       ;$e8    70      [Next Input]
k_prev:         equ     %11110000       ;$f0    71      [Prev. Input]
k_ES_on:        equ     %11110001       ;$f1   *72*     [ES spkr ON] (* no parity *)
k_ES_off:       equ     %11110011       ;$f3   *73*     [ES spkr OFF] (* no parity *)
k_movie:        equ     %11110101       ;$f5   *74*     [Movie mode] (* no parity *)
k_music:        equ     %11110110       ;$f6   *75*     [Music mode] (* no parity *)
k_party_on:     equ     %11111101       ;$fd   *76*     [Party mode ON] (* no parity *)
k_party_off:    equ     %11111110       ;$fe   *77*     [Party mode OFF] (* no parity *)

; The following two keys don't obey the parity rule for actual keys:
k_test:         equ     %11110010       ;$f2    78      Test for IR Tx,Rx.
k_sys_conf:     equ     %11110100       ;$f4    79      Used for TheaterMaster/SwitchMaster system configuration (see below)

; k_sys_conf is a value which is not used anywhere for actual processing,
; but is recognized as a valid code when RS-232 program sends the initial
; system configuration inquiry (are both TheaterMaster and SwitchMaster
; present?), the letter 'X'.
		
k_credits:      equ     %11111000       ;$f8    80      Credits demo.

; The Credits command is IR only, and has no RS-232 equivalent.
; It is possible to start the demo from Buefus, however, using CALL 400

;Check this out carefully:
;
; THIS IS A MESS: SwitchMaster needs these codes for reliable switching, but
;                 we have reassigned them in the TheaterMaster. Therefore,
;                 we still send k_to_anlg and k_to_dig from the adip_toggle
;                 routine to the SwitchMaster, but avoid sending k_roll_off
;                 and k_x_over in exec_frm.


;** Virtual keys:

k_num:          equ %00100000       ;Any key [0] thru [9]
k_16_TM:        equ %00100001       ;Any key [1] thru [6]  TM
k_70_TM:        equ %00100010       ;Keys [7],[8],[9],[0]  TM
k_16_TMS:       equ %10100001       ;Any key [1] thru [6]  TMS
k_70_TMS:       equ %10100010       ;Keys [7],[8],[9],[0]  TMS


; Virtual keys have bit 5 set and don't obey the parity rule for actual keys.


;****************************************************************
;* Addresses of External EOS Registers:
;*
;* NOTE: Most of these registers have an image register.
;*       It will almost always be better to write to the
;*       image register and then call the appropriate
;*       update routine.
;*
;***

DAC8_latch1:    equ $1840   ;Write-only DAC8 HC574A octal D flip-flop.
DAC8_latch2:    equ $1848   ;Write-only DAC8 HC574A octal D flip-flop.

EOBP_Vmux:      equ $1868   ;Write-only EO-BP  HC237  1:8 decoder w. latch.

SBP_Main_mux:   equ $1868   ;Write-only S-BP   HC237  1:8 decoder w. latch.
SBP_Tape_mux:   equ $1870   ;Write-only S-BP   HC237  1:8 decoder w. latch.
SBP_K6:         equ $1878   ;Write-only S-BP   HC74   2-bit latch.

MB_Tape_mux:    equ $1800   ;Write-only EOS-MB HC354  8:1 mux w. addr. latch.
MB_Main_mux:    equ $1808   ;Write-only EOS-MB HC354  8:1 mux w. addr. latch.

surrPMD:        equ $1850   ;Write-only OS-DAC PMD100 digital filter.
frontPMD:       equ $1858   ;Write-only OS-DAC PMD100 digital filter.
csubPMD:        equ $1860   ;Write-only OS-DAC PMD100 digital filter.

mb_DIP:         equ $1800   ;Read-only  EOS-MB HC541  8-bit latch.



;***************************************************************
;* Special delay parameters used by volume routines.
;*
;***
up1:    equ     5           ;0.5 ms 
dn1:    equ     19          ;1.9 ms

;***************************************************************
;* Maximum number of cracks used in AutoDelay
;***
max_cracks:     equ     8

;**************************************************************
;* EEPROM pointers
;***
ee_chan_pol:     equ     $7e10           ;Channel polarity (5 channels)

ee_cold_def:     equ     $7e20           ;"locals" and then "globals"

ee_cold_def_globs: equ   $7e34           ;Always factory defaults...


;*** User globals:
ee_globals:         equ     $7e64      

ee_spkr_cfg:        equ     0            ;Address offsets into ee_globals...
ee_balanced:        equ     1
ee_tm_lockout:      equ     2         
ee_dig_lockout:     equ     2
ee_ana_lockout:     equ     3
ee_av_links:        equ     4
ee_dig_av_links:    equ     4
ee_ana_av_links:    equ     10
ee_ana_pt_av_links: equ     16

ee_spkr_dists:      equ     19
ee_LF_dst:          equ     19           ;L-Front
ee_RF_dst:          equ     20           ;R-Front
ee_LS_dst:          equ     21           ;L-Surr
ee_RS_dst:          equ     22           ;R-Surr
ee_CT_dst:          equ     23           ;Center
ee_SR_dst:          equ     24           ;Sub-R

ee_bright:          equ     25
ee_ven:             equ     26
ee_desig_dig:       equ     27
ee_desig_ana:       equ     33
ee_anlg_att:        equ     42


;*** User memories:
ee_memory:          equ     $7ec0        ;User memories (0-9) 32 bytes each.
                                         ;(Uses up balance of EEPROM, to $7fff)

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%                              %%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%         BUFFALO EQUATES        %%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%                              %%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;***************
;*   EQUATES   *
;***************
RAMBS:    EQU   $0200      ;start of BUFFALO RAM
;REGBS:    EQU   $1000      ;start of CPU register block
ROMBS:    EQU   $E000      ;start of BUFFALO ROM

STREE_DEF: EQU   $7E00      ;EOS-defined start of eeprom on 68HC11F1
ENDEE_DEF: EQU   $7FFF      ;EOS-defined end of eeprom on 68HC11F1

PORTA:    EQU   $1000
DDRA:     EQU   $1001
PORTB:    EQU   $1004
PORTE:    EQU   $100A      ;port e
CFORC:    EQU   $100B      ;force output compare
TCNT:     EQU   $100E      ;timer count
TOC4:     EQU   $101C      ;oc4 reg
TCTL1:    EQU   $1020      ;timer control 1
TMSK1:    EQU   $1022      ;timer mask 1
TFLG1:    EQU   $1023      ;timer flag 1
TMSK2:    EQU   $1024      ;timer mask 2
BAUD:     EQU   $102B      ;sci baud reg
SCCR1:    EQU   $102C      ;sci control1 reg
SCCR2:    EQU   $102D      ;sci control2 reg
SCSR:     EQU   $102E      ;sci status reg
SCDAT:    EQU   $102F      ;sci data reg
BPROT:    EQU   $1035      ;block protect reg
OPTION:   EQU   $1039      ;option reg
COPRST:   EQU   $103A      ;cop reset reg
PPROG:    EQU   $103B      ;ee prog reg
HPRIO:    EQU   $103C      ;hprio reg
CONFIG:   EQU   $103F      ;config register
CSCTL:    EQU   $105D      ;chip select control
CSGADR:   EQU   $105E      ;gen purpose chip sel address
CSGSIZ:   EQU   $105F      ;gen purpose chip sel size reg

;Buefuss:

PROMPT:   EQU   '>'
BUFFLNG:  EQU   35
CTLA:     EQU   $01        ;exit host or assembler
CTLB:     EQU   $02        ;send break to host
CTLC:     EQU   $03        ;
CTLD:     EQU   $04        ;
CTLH:     EQU   $08        ;
BS:       EQU   $08        ;back space
CTLW:     EQU   $17        ;wait
CTLX:     EQU   $18        ;abort
DEL:      EQU   $7F        ;delete
EOT:      EQU   $04        ;end of text/table
CR:       EQU   $0d        ;carriage return
;LF:  <---This symbol already being used for Left Front sepaker

SWI:      EQU   $3F



