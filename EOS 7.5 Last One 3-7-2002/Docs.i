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
;   Docs.i
;
;****************************************
;*
;*      Documentation Include File
;*
;****************************************

DOCS:   equ     1           ;to prevent further inclusion

        IFND DOCS    ; Skip documantation section.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%                       %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%    M E M O R Y  M A P   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%                       %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    $0000 \  
      .    +--- 1K bytes internal RAM
    $03ff /

    $1000 \
      .    +--- 96 bytes internal register block (default location)
    $105f /

    $1060 \
      .    +--- CSIO1 (<2K bytes, LCD I/O)
    $17ff /

    $1800 \
      .    +--- _CSIO2 (2K bytes, external I/O)
    $1fff /

    $2000 \
      .    +--- _CSGEN (8K bytes, external RAM)
    $3fff /


    $4e00 \
      .    +--- 0.5K bytes internal EEPROM (moved from default location)
    $4fff /


    $8000 \
      .    +--- _CSPROG (32K bytes, external EPROM)
    $ffff /

          
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%                       %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%       C S 4 2 2 6       %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%                       %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 CS4226 registers (with MAP) = Value at initialization stage:

  bits 7       6       5       4       3       2       1       0

------------------------------
 Clock Mode (1) = $04

       0       CO1     CO0     CI1     CI0     CS2     CS1     CS0

   CS     = 4 = %100   PLL driven by RX1 (SPDIF) data
   CI     = 0 = %00    XTI = 256 Fs
   CO     = 0 = %00    CLKOUT = 256 Fs

------------------------------
 Converter Control (2) = $01

       CALP    CLKE    DU      AUTO    0       0       CAL     RS

   RS     = 1          Reset asserted (only control port active)
   CAL    = 0          Normal operation (no extra calibration)
   AUTO   :            AC-3/MPEG flag (1 = detected)
   DU     :            De-emphasis status (1 = selected by DAC's)
   CLKE   :            Clocking system status (0 = OK)
   CALP   :            Calibration status (1 = in process)

------------------------------
 DAC Control (3) = $3f

       ZCD     MUTC    MUT6    MUT5    MUT4    MUT3    MUT2    MUT1

   MUT1-6 = 1 = %111111  All DAC's muted
   MUTC   = 0          512 consecutive zeros will mute DAC
   ZCD    = 0          DAC mutes andvolume control changes on 0-crossings

------------------------------
 Output Attenuator Data (4=L, 5=R, 6=LS, 7=RS, 8=C, 9=SUB) = $00

       0       ATT6    ATT5    ATT4    ATT3    ATT2    ATT1    ATT0

   ATT    = 0 = %00000000  Attenuation in 1 dB steps

------------------------------
 DAC Status Report (10) = 0

       0       -       ACC6    ACC5    ACC4    ACC3    ACC2    ACC1

   ACCx   :            Attenuation setting in process (0 = accepted)

------------------------------
 ADC Control (11) = $40

       IS1     IS0     0       AIS1    AIS0    MUTM    MUTR    MUTL

   MUTx   = 0          Left, right, mono channel not muted
   AIS    = 0 = %00    Select stereo pair 1
   IS     = 1 = %01    SPDIF rec'r to SDOUT1

------------------------------
 Input Control (12) = $f0

       OVRM    VM      BM      PM      GNR1    GNR0    GNL1    GNL0

   OVRM   = 1          ADC overflow not masked
   VM     = 1          V-flag not masked
   BM     = 1          Biphase error not masked
   PM     = 1          Parity error no masked
   GNL    = 0 = %00    Left input gain
   GNR    = 0 = %00    Right input gain

------------------------------
 ADC Status Report (13) = 0

       LVM1    LVM0    LVR2    LVR1    LVR0    LVL2    LVL1    LVL0

   LVx    :            Left, right, mono ADC peak levels (sticky)
                               (3 or 7 = clipping)

------------------------------
 DSP Port Mode (14) = $e4

       DCK1    DCK0    DMS1    DMS0    DSCK    DDF2    DDF1    DDF0

   DDF    = 4 = %100   I2S compatible
   DSCK   = 0          Data latched on rising edge
   DMS    = 2 = %10    Master, evenly distributed SCLK
   DCK    = 3 = %11    64 bit clock periods per Fs period

------------------------------
 Aux Port Mode (15) = $e4

       ACK1    ACK0    AMS1    AMS0    ASCK    ADF2    ADF1    ADF0

                       Ditto for Aux port (not used by TM)

------------------------------
Aux Port Control (16) = $48

       CSP     HPC     UMV     MOH     DEM24   DEM2    DEM1    DEM0

   DEM    = 7 = %111   Auomatic deemphasis
   DEM24  = 1          4 LSB's not processed by deem.
   MOH    = 0          Hold >16 frames mutes DAC's
   UMV    = 0          DAC's unmute when error is removed
   HPC    = 1          HOLD/RUBIT is output
   CSP    = 0          Analog inputs to pins A2L,R,A3L,R

------------------------------
 Receiver Status (17) 

       CV      0       CRC     LOCK    V       CONF    BIP     PAR

   PAR    :            1 = parity error
   BIP    :            1 = biphase error
   CONF   :            1 = confidence error
   V      :            1 = V-flag
   LOCK   :            1 = PLL out-of-lock
   CRC    :            1 = CRC error
   CV     :            1 = ch. status data updating (invalid)

------------------------------
 Receiver Channel Status (18=ch. A/byte 1, 19=A2, 20=A3, 21=A4, 22=B1,..,25=B4)

====================================================================

Consumer Channel Status (fields of interest):

 Byte 1:

       MODE    MODE0   PREEM2  PREEM1  PREEM0  COPY    _AUDIO  PRO

   PRO    :            0 = consumer mode
   _AUDIO :            0 = audio, 1= data
   PREEM  :            0 = none, 1 = 50/15 us

 Byte 4:

       X       X       CLK1    CLK0    FS3     FS2     FS1     FS0

   FS     :            sampling freq.: 0 = 44.1, 2 = 48, 3 = 32


Professional Channel Status (fields of interest):

 Byte 1:

       FS1     FS0     LOCK    PREEM2  PREEM1  PREEM0  _AUDIO  PRO

   PRO    :            1 = professional mode
   _AUDIO :            0 = audio, 1= data
   PREEM  :            0 = not indicated, 1 = none, 3 = 50/15 us
   FS     :            sampling freq.: 0 = not ind., 1 = 48, 2 = 44.1, 3 = 32




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%                       %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%   P O R T   U S A G E   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%                       %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Bit  Direction   Signal
             (P=prog.)    
 Port G:
        PG0     PO      _SS for 4226 SPI
        PG1     PO      _SS for Z1 SPI
        PG2     PO      _SS for Z2 SPI
        PG3     PO      _SS for M1 SPI
        PG4     PO      _CSIO2, HC138s on MB,BP,DAC
        PG5     PO      CSIO1, LCD
        PG6     PO      _CSGEN, external SRAM
        PG7     PO      _CSPROG, external EPROM

 Port E:       
        PE0/AN0  I      Mic signal, analog.
        PE1      I      Mic sense, 1 = mic in          (XXXXX check polarity)
        PE2/AN2  I      Temperature measurement signal, analog.
        PE3      I      HDCD flag from PMD, 1 = HDCD   (XXXXX check polarity)
        PE4      I      Anlg O/L from Sig. BP, 1 = O/L (XXXXX check polarity)    
        PE5      I      DTS F-flag, 0 = DTS            (XXXXX check polarity)         
        PE6      I      HDCD gain, 1 = add 6 dB        (XXXXX check polarity)       
        PE7      I      Flywheel detect, 1 = locked    (XXXXX check polarity)

 Port A:
        PA0     I/O     DPD signal to CS5390 (Sig. only)
                         and HC157 CS5390/CS4226 data selector.
        PA1     PO      DSP reset, 0 = reset
      PA2/IC1    I      IR Rx
    PA3/OC1/OC5 PO      EL Lamp PWM (OC1 ON, OC5 OFF)
                         --also handles LCD character blinking (could also use RTI routine)
        PA4     PO      Screen control, 1 = 12 V
      PA5/OC3   PO      IR Tx
        PA6     PO      Piezo buzzer
        PA7     PO      DTS select, 1 = DTS

 Port D:
        PD0     PO      RS232 Rx
        PD1     PO      RS232 Tx
        PD2     PO      SPI MISO from CS4226,Z1,Z2,M1
        PD3     PO      SPI MOSI to CS4226,Z1,Z2,M1
        PD4     PO      SPI SCK  to CS4226,Z1,Z2,M1
        PD5     PO      SPI _SS (to SPI diagnostic LED)

 Ports B and F:
        A0 ... A15      Address bus

 Port C:
        D0 ... D7       Data bus


 *XIRQ    --      Power fail, 0 = fail
 *IRQ     --      FP piezo switch
 *RESET   --      System reset
 4XOUT    --      8 MHz clock to Z1,Z2,(M1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%          P E R I P H E R A L S          %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%                                         %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%            M E M O R Y  M A P           %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%                                       %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  CSIO1:        $1060 - 17FF    LCD panel
  ---------------------------------------

        WRITE ---
                $1060 Send control word to LCD
                $1061 Send data to CGRAM or DDRAM


        READ ---
                $1060 Get LCD Busy flag
                $1061 Get data from CGRAM or DDRAM



 _CSIO2:        $1800 - 1FFF    HC138's on MB,BP,DAC
 ---------------------------------------------------

  WRITE ---
   Model   Board  Lower Address Bits  Function           Address       
                  A7 6 5 4 | 3 2 1 0

     S   DAC HC138 x 1 0 0 | 0 x x x  Volume HC574        $1840
     -             x 1 0 0 | 1 x x x  Misc. & Vol. HC574  $1848
                   x 1 0 1 | 0 . . .  Surr. PMD           $1850 + A[2:0]
                   x 1 0 1 | 1 . . .  Front PMD           $1858 + A[2:0]
                   x 1 1 0 | 0 . . .  C/Sub PMD           $1860 + A[2:0]

     EO  BP HC138  x 1 1 0 | 1 x x x  Video Main HC137    $1868
     --                               ?use unused video o/p for kill relay?

     S   BP HC138  x 1 1 0 | 1 x x x  Analog Main HC137   $1868
     -             x 1 1 1 | 0 x x x  Analog TMon HC137   $1870
                   x 1 1 1 | 1 x x x  BP Kill & -6dB HC74 $1878

     EOS MB HC138  x 0 0 0 | 0 x x x  Dig. TMon HC354     $1800
     ---           x 0 0 0 | 1 x x x  Dig. Main HC354     $1808

                   x 0 0 1 | 0 x x x \
                         : | :       - spare             $1810 - 183F
                   x 0 1 1 | 1 x x x /

  READ ---

     EOS MB        x x x x | x x x x  DIP-sw HC273       $1800
     ---
 -----------------------------------------------------------------

 WRITE ---

  Volume HC574 U3, 1840:

         D0  BAL, 1 = balanced
         D1  SVC3
         D2  SVC2
         D3  SVC1
         D4  FVC3
         D5  FVC2
         D6  FVC1
         D7  CSUBVC3

  Misc. & Vol. HC574 U2, $1848:

         D0  CSUBVC2
         D1  CSUBVC1
         D2  Flywheel enable, 1 = enabled
         D3  FSEL, 1 = 48 kHz, 0 = 44.1 k
         D4  DEEMPH, 1 = deemphasize
         D5  SMUTE, 1 = mute
         D6  n.c. (spare)
         D7  n.c. (spare)

  Surr. PMD U7, $1850  Shift 24 bits in from D0
                $1851  Increment Surr. attenuators by 0.1875 dB
                $1852  Decrement Surr. attenuators by 0.1875 dB
                $1853  Zero Surr. attenuators (sets gain = 1)
                $1854  Set Left Surr. attenuator
                $1855  Set Right Surr. attenuator
                $1856  Set Control
                $1857  Reserved. DO NOT USE! (Note: was RESET on 5803)

  Front PMD U8, $1858  Shift 24 bits in from D0
                $1859  Increment Left Front attenuators by 0.1875 dB
                $185a  Decrement Left Front attenuators by 0.1875 dB
                $185b  Zero Front attenuators (sets gain = 1)
                $185c  Set Left Front attenuator
                $185d  Set Right Front attenuator
                $185e  Set Control
                $185f  Reserved. DO NOT USE! (Note: was RESET on 5803)

  C/Sub PMD U9, $1860  Shift 24 bits in from D0
                $1861  Increment C/Sub attenuators by 0.1875 dB
                $1862  Decrement C/Sub attenuators by 0.1875 dB
                $1863  Zero C/Sub attenuators (sets gain = 1)
                $1864  Set Sub (Left) attenuator
                $1865  Set Center (Right) attenuator
                $1866  Set Control
                $1867  Reserved. DO NOT USE! (Note: was RESET on 5803)


  $1868: D[2:0] = %000 selects analog(S)/video(EO) main input 1
         :                            -        --
         D[2:0] = %101 selects input 6

  $1870: ditto for analog TMon (S)
                                -
  $1878: D0  -6 dB analog attenuation before ADC, 1 = attenuate
         D1  Kill relay, 1 = Killpowered down
         D2  n.c.

  $1800: D[2:0] = 0 selects digital main input 1
         :
         D[2:0] = 5 selects input 6

  $1808: ditto for digital TMon (S)

 READ ---

  $1800: DIP-switch

        Pos'n     OFF=1 (default)            ON=0

   D0     1     English                    Japanese

   D1     2     Flywheel chatter supress.  No flywheel chatter supress.

   D2     3     Backlight time-out short.  Backlight time-out 8 hrs.

   D3     4     IR receiver enabled.       IR receiver disabled.

   D5     6     No HDCD override.          HDCD override.         

   D6     7     Input 2 standard.          Input 2 dedicated to DTS.

   D4     5     Input 3 standard.          Input 3 dedicated to DTS.

   D7     8     6 dB/step Bar Graph        Custom Bar Graph


        Pos'n     Boot Mode Switches

   MODB   9     0\ Special    0\ Special    1\ Single     1\ Expanded
                  +Bootstrap    +Test         +Chip         +mode
   MOBA  10     0/ mode       1/ mode       0/ mode       1/
                (reserved)    (factory      (reserved)    (normal
                              use only)                    mode)

****************************************************************

        ENDIF


        end
