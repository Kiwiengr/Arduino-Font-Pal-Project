;****************************************
;*      Buef_com.s
;*
;*      Buefuss Command Processor
;****************************************
;
;Bugs: This version ussumes that oc5 is connected to XIRQ
;      to allow trace of one instruction. TheaterMaster
;      is not compatible with this scheme!  (see line 3153)
;
;Note: Strings with EOT = $04 in original BUFFALO.
;
;*****************
;* Search tables for command.  At this point,
;* COMBUFF holds the command field to be executed,
;* and B = # of characters in the command field.
;* The command table holds the whole command name
;* but only the first n characters of the command
;* must match what is in COMBUFF where n is the
;* number of characters entered by the user.
;*****************
;*count = b;
;*ptr1 = comtabl;
;*while(ptr1[0] != end of table)
;*   ptr1 = next entry
;*   for(b=1; b=count; b++)
;*      if(ptr1[b] == combuff[b]) continue;
;*      else error(not found);
;*   execute task;
;*  return();
;*return(command not found);


        CLIST OFF       ;Only list assembled conditonals.
        MLIST OFF       ;Don't expand macros.


buefcom_flag:   equ     0


        XDEF  SRCH,UPCASE,WCHEK,INPUT,OUTPUT,OUTA,OUTCRLF,OUTSTRG,INCHAR
        XDEF  ONSCI,WSKIP,MSG3,SVSCI,COMBUFF,JSWI,JTOC4,Buef_init,CHRCNT
        XDEF  EEWRIT,EEBYTE,INBUFF,ENDBUFF

        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"      ;Global constants
        include "c:\1work\eos-i\macros.i"


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%                               %%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%          BUFFALO SPACE          %%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%                               %%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Buef_vbl:	Section 31

REGS:     ds.b   9          ;user's pc,y,x,a,b,c
SP:       ds.b   2          ;user's sp

INBUFF:   ds.b   35         ;input buffer
ENDBUFF:  equ    *

COMBUFF:  ds.b   8          ;command buffer
SHFTREG:  ds.b   2          ;input shift register
BRKTABL:  ds.b   8          ;breakpoint table
AUTOLF:   ds.b   1          ;auto lf flag for i/o
COUNT:    ds.b   1          ;# characters read into input buffer
CHRCNT:   ds.b   1          ;# characters output on current line
PTRMEM:   ds.b   2          ;current memory location
LDOFFST:  ds.b   2          ;offset for download

PTR0:     ds.b   2          ;main,readbuff,incbuff,AS
PTR1:     ds.b   2          ;main,BR,DU,MO,AS,EX
PTR2:     ds.b   2          ;EX,DU,MO,AS
PTR3:     ds.b   2          ;EX,HO,MO,AS
PTR4:     ds.b   2          ;EX,AS
PTR5:     ds.b   2          ;EX,AS,BOOT
PTR6:     ds.b   2          ;EX,AS,BOOT
PTR7:     ds.b   2          ;EX,AS
PTR8:     ds.b   2          ;AS
PTR9:     ds.b   2
TMP1:     ds.b   1          ;main,hexbin,buffarg,termarg
TMP2:     ds.b   1          ;GO,HO,AS,LOAD
TMP3:     ds.b   1          ;AS,LOAD
TMP4:     ds.b   1          ;TR,HO,ME,AS,LOAD
JSWI:     ds.b   3
JTOC4:    ds.b   3
STREE:    ds.b   2          ;Current EEPROM start and
ENDEE:    ds.b   2          ; end address save here.


Buef_com:	Section 3

;***************************************************************************

Buef_init:


        LDAA    #$C0
        STAA    REGS+8                 ;default user ccr

        LDD     #$3F0D                 ;initial command is '?' (i.e., Help screen)
        STD     INBUFF

        JSR     BPCLR

        CLR     AUTOLF
        INC     AUTOLF                 ;auto cr/lf = on

        ldd     #STREE_DEF
        std     STREE
        ldd     #ENDEE_DEF
        std     ENDEE

        LDAA    #$7E                   ;Set SWI and OC4 vectors
        STAA    JSWI
        STAA    JTOC4

        LDY     #JTOC4
        STX     1,Y
        RTS

;**************************************************************************
;*
;* SVSCI : Transfers characters from the SCI into the input buffer.
;*
;**************************************************************************

SVSCI:  ldx     #regbase
        ldaa    scsr,x                  ;clear SCI Rx data register full flag

        ldaa    TM_flag                 ;If processing a TM command,
        bne     not_svsci               ; or if processing 
        ldaa    Buefuss_flag            ; a Buefuss command,
        beq     sci_clear               ; do not accept further characters.

not_svsci:
        rti


sci_clear:
        ldaa    scdr,x                  ;Get data from the SCI Rx data register.
       
        ldy     #INBUFF
        ldab    COUNT
        aby                             ;point into buffer

        cmpa    #BS                     ;Check for rub-out (BS) char.
        bne     sci_clear2

        tstb                            ;Check if any characters to delete
        bne     delete_char     
        rti                             ;If at beginning of buffer, do nothing


delete_char:
        ldaa    #BS
        jsr     OUTA                    ;Move back on screen
        ldaa    #' '
        jsr     OUTA                    ;Delete character
        ldaa    #BS
        jsr     OUTA                    ;Move back again
        dec     COUNT                   ;Decrement buffer pointer
        rti


sci_clear2:
        cmpa    #CR                     ;Check for CR
        bne     sci_clear3

        tstb
        beq     get_comm                ;If CR only, repeat last command,
                                        ; but only if it was a Bueffus command.
        staa    0,y
        bra     get_comm


sci_clear3:
        cmpb    #BUFFLNG                ;Check if buffer exceeded
        bls     buffer_update             

        ldx     #MSG3                   ;Otherwise, 'Too Long' message
        jsr     OUTSTRG
        jmp     reset_command


buffer_update:
;% The next four lines are to protect the SwitchMaster!!!
        cmpa    #$1f
        bls     buffer_update_out       ;If control characters, ignore
                                        ;and do not pass through!! 
        cmpa    #$80
        bhs     buffer_update_out       ;If MSB set, ignore and do not pass thru

        staa    0,y                     ;Store character in buffer
        jsr     OUTA                    ;Echo character to RS232
        inc     COUNT
buffer_update_out:
        rti
        

reset_command:
        clr     AUTOLF
        inc     AUTOLF                  ;auto cr/lf = on
        jsr     OUTCRLF
        ldaa    #PROMPT                 ;prompt user
        jsr     OUTPUT
        clr     Buefuss_flag            ;Reset 'command-issued' flag
        clr     TM_flag
        clr     COUNT
        rti


flag_done:
        stab    COUNT
        ldaa    #1                      ;Flag a Buefuss command
        staa    Buefuss_flag
        clr     TM_flag
        bra     disable

TM_operation:                           
        ldaa    #1                      ;Flag a TM code
        staa    TM_flag
        clr     Buefuss_flag

disable:
        ldx     #regbase
        ldaa    #$0c
        staa    sccr2,x                 ;Disable SCI interrupts, enable Tx,Rx
        rti


get_comm:
        clr     TMP1                    ;Enable "/" command
        clr     SHFTREG
        clr     SHFTREG+1
        ldx     #INBUFF                 ;ptrbuff[] = inbuff[]
        stx     PTR0           

        jsr     WSKIP                   ;find first char

        ldd     0,x
        cpd     #'TM'                   ;Check for Theater Master header code in 1st position.
        bne     COMM0                   ;If not, deal with as Buef command...

        ldaa    2,x
        cmpa    #' '                    ;Check for TheaterMaster space delimiter
        bne     COMM0                   ;If not, deal with as Buef commmand
        bra     TM_operation            ;If string starts as "TM ", do not
                                        ;massage buffer, and flag as TM command

COMM0:  ldd     0,x
        cpd     #'$$'
        bne     COMM0a                  ;If EOS init string, ignore!!!

        ldx     $fffe                   ;Get Cold Start Reset vector
        jmp     0,x


COMM0a: clr     COUNT
        clrb                            ;Clear string-length counter

COMM1:  jsr     READBUFF                ;read from buffer
        ldx     #COMBUFF
        abx
        jsr     UPCASE                  ;convert to upper case
        staa    0,X                     ;put in command buffer

        cmpa    #CR
        beq     flag_done               ;jump if cr

        jsr     WCHEK
        beq     flag_done               ;jump if wspace

        inc     PTR0+1                  ;move buffer pointer
        incb

        cmpb    #8
        bls     COMM1

        ldx     #MSG3                   ;"Too long"
        jsr     OUTSTRG
        jmp     reset_command


;******************************************************************
;******************************************************************


SRCH:   LDX  #COMTABL   ;pointer to table
        STX  PTR1       ;pointer to next entry
SRCH1:  LDX  PTR1
        LDY  #COMBUFF   ;pointer to command buffer
        LDAB 0,X
        CMPB #$FF
        BNE  SRCH2
        LDX  #MSG2      ;"command not found"
        JSR  OUTSTRG
        rts

SRCH2:  PSHX            ;compute next table entry
        ADDB #$3
        ABX
        STX  PTR1
        PULX
        CLRB
SRCHLP: INCB            ;match characters loop
        LDAA 1,X        ;read table
        CMPA 0,Y        ;compare to combuff
        BNE  SRCH1      ;try next entry
        INX             ;move pointers
        INY
        CMPB COUNT
        BLT  SRCHLP     ;loop countu1 times
        LDX  PTR1
        DEX
        DEX
        LDX  0,X        ;jump address from table
EXEC:   JMP  0,X        ;call task as subroutine


;*
;*****************
;*   UTILITY SUBROUTINES - These routines
;* are called by any of the task routines.
;*****************
;*****************
;*  UPCASE(a) - If the contents of A is alpha,
;* returns a converted to uppercase.
;*****************
UPCASE:  CMPA #'a'
         BLT  UPCASE1   ;jump if < a
         CMPA #'z'
         BGT  UPCASE1   ;jump if > z
         SUBA #' '      ;convert
UPCASE1: RTS

;*****************
;*  BPCLR() - Clear all entries in the
;* table of breakpoints.
;*****************
BPCLR:   LDX  #BRKTABL
         LDAB #8
BPCLR1:  CLR  0,X
         INX
         DECB
         BGT  BPCLR1     ;loop 8 times
         RTS

;*****************
;*  RPRNT1(x) - Prints name and contents of a single
;* user register. On entry X points to name of register
;* in reglist.  On exit, a=register name.
;*****************
REGLIST: dc.b  'PYXABCS'       ;names
         dc.b  0,2,4,6,7,8,9   ;offset
         dc.b  1,1,1,0,0,0,1   ;size
RPRNT1:  LDAA 0,X
         PSHA
         PSHX
         JSR  OUTPUT      ;name
         LDAA #'-'
         JSR  OUTPUT      ;dash
         LDAB 7,X         ;contents offset
         LDAA 14,X        ;bytesize
         LDX  #REGS       ;address
         ABX
         TSTA
         BEQ  RPRN2       ;jump if 1 byte
         JSR  OUT1BYT     ;2 bytes
RPRN2:   JSR  OUT1BSP
         PULX
         PULA
         RTS

;*****************
;*  RPRINT() - Print the name and contents
;* of all the user registers.
;*****************
RPRINT:  PSHX
         LDX  #REGLIST
RPRI1:   JSR  RPRNT1    ;print name
         INX
         CMPA #'S'      ;s is last register
         BNE  RPRI1     ;jump if not done
         PULX
         RTS

;*****************
;*   HEXBIN(a) - Convert the ASCII character in a
;* to binary and shift into shftreg.  Returns value
;* in tmp1 incremented if a is not hex.
;*****************
HEXBIN: PSHA
        PSHB
        PSHX
        JSR  UPCASE     ;convert to upper case
        CMPA #'0'
        BLT  HEXNOT     ;jump if a < $30
        CMPA #'9'
        BLE  HEXNMB     ;jump if 0-9
        CMPA #'A'
        BLT  HEXNOT     ;jump if $39> a <$41
        CMPA #'F'
        BGT  HEXNOT     ;jump if a > $46
        ADDA #$9        ;convert $A-$F
HEXNMB: ANDA #$0F       ;convert to binary
        LDX  #SHFTREG
        LDAB #4
HEXSHFT:
        ASL  1,X        ;2 byte shift through
        ROL  0,X        ;       carry bit
        DECB
        BGT  HEXSHFT    ;shift 4 times
        ORAA 1,X
        STAA 1,X
        BRA  HEXRTS
HEXNOT: INC  TMP1       ;indicate not hex
HEXRTS: PULX
        PULB
        PULA
        RTS

;*****************
;*  BUFFARG() - Build a hex argument from the
;* contents of the input buffer. Characters are
;* converted to binary and shifted into shftreg
;* until a non-hex character is found.  On exit
;* shftreg holds the last four digits read, count
;* holds the number of digits read, ptrbuff points
;* to the first non-hex character read, and A holds
;* that first non-hex character.
;*****************
;*Initialize
;*while((a=readbuff()) not hex)
;*     hexbin(a);
;*return();

BUFFARG: CLR  TMP1        ;not hex indicator
         CLR  COUNT       ;# or digits
         CLR  SHFTREG
         CLR  SHFTREG+1
         JSR  WSKIP
BUFFLP:  JSR  READBUFF    ;read char
         JSR  HEXBIN
         TST  TMP1
         BNE  BUFFRTS     ;jump if not hex
         INC  COUNT
         JSR  INCBUFF     ;move buffer pointer
         BRA  BUFFLP
BUFFRTS: RTS

;*****************
;*  TERMARG() - Build a hex argument from the
;* terminal.  Characters are converted to binary
;* and shifted into shftreg until a non-hex character
;* is found.  On exit shftreg holds the last four
;* digits read, count holds the number of digits
;* read, and A holds the first non-hex character.
;*****************
;*initialize
;*while((a=inchar()) == hex)
;*     if(a = cntlx)    --patch. Old code: if(a = cntlx or del)
;*          abort;
;*     else
;*          hexbin(a); countu1++;
;*return();

TERMARG: CLR  COUNT
         CLR  SHFTREG
         CLR  SHFTREG+1
TERM0:   JSR  INCHAR
         CMPA #CTLX
         bne  TERM2        ;                    --patch
;*         BEQ  TERM1       ;jump if controlx      --patch
;*         CMPA #DEL        ;                    --patch
;*         BNE  TERM2       ;jump if not delete    --patch

TERM1:   rts               ;abort

TERM2:   CLR  TMP1         ;hex indicator
         JSR  HEXBIN
         TST  TMP1
         BNE  TERM3        ;jump if not hex
         INC  COUNT
         BRA  TERM0
TERM3:   RTS

;*****************
;*   CHGBYT() - If shftreg is not empty, put
;* contents of shftreg at address in X.  If X
;* is an address in EEPROM then program it.
;*****************
;*if(count != 0)
;*   (x) = a;
CHGBYT:  TST  COUNT
         BEQ  CHGBYT4   ;quit if shftreg empty
         LDAA SHFTREG+1 ;get data into a
         JSR  WRITE
CHGBYT4: RTS


;*****************
;* WRITE() - This routine is used to write the
;* contents of A to the address of X.  If the
;* address is in EEPROM, it will be programmed
;* and if it is already programmed, it will be
;* byte erased first.
;******************
;*if(X == config) then
;*   byte erase config;
;*if(X is eeprom)then
;*   if(not erased) then erase;
;*   program (x) = A;
;*write (x) = A;
;*if((x) != A) error(rom);
WRITE:  EQU  *
        CPX  #CONFIG
        BEQ  WRITE0     ;jump if config

        CPX  STREE      ;start of EE
        BLO  WRITE2     ;jump if not EE

        CPX  ENDEE      ;end of EE
        BHI  WRITE2     ;jump if not EE

WRITEE: PSHB            ;check if byte erased
        LDAB 0,X
        CMPB #$FF
        PULB
        BEQ  WRITE1     ;jump if erased

WRITE0: JSR  EEBYTE     ;byte erase
WRITE1: JSR  EEWRIT     ;byte program
WRITE2: STAA 0,X        ;write for non EE
        CMPA 0,X
        BEQ  WRITE3     ;jump if write ok

        PSHX
        LDX  #MSG6      ;"rom"
        JSR  OUTSTRG
        PULX
WRITE3: RTS


;*****************
;*   EEWRIT(), EEBYTE(), EEBULK() -
;* These routines are used to program and eeprom
;*locations.  eewrite programs the address in X with
;*the value in A, eebyte does a byte address at X,
;*and eebulk does a bulk of eeprom.  Whether eebulk
;*erases the config or not depends on the address it
;*receives in X.
;****************
EEWRIT:                 ;program one byte at x
        PSHB
        LDAB #$02
        STAB PPROG
        STAA 0,X
        LDAB #$03
        BRA  EEPROG

EEBYTE:                 ;byte erase address x
        PSHB
        LDAB #$16
        STAB PPROG
        LDAB #$FF
        STAB 0,X
        LDAB #$17
        BRA  EEPROG

EEBULK:                 ;bulk erase eeprom
        PSHB
        LDAB #$06
        STAB PPROG
        STAA 0,X        ;erase config or not ...
        LDAB #$07       ;  ... depends on X addr
EEPROG: BNE  ACL1       ;(if x=CONFIG, the EEPROM is bulk erased as well)
                        ;(if x=any addr in EEPROM, CONFIG is not erased) 

        CLRB            ;fail safe
ACL1:   STAB PPROG
        PULB

DLY10MS: EQU  *         ; delay 10ms __and__ clear PPROG
        PSHX
        LDX     #$0D06          ; $0D06 * %1     (8MHz crystal)
DLYLP:  DEX
        BNE  DLYLP

        PULX
        CLR  PPROG
        RTS


;*****************
;*  READBUFF() -  Read the character in INBUFF
;* pointed at by ptrbuff into A.  Returns ptrbuff
;* unchanged.
;*****************
READBUFF:
         PSHX
         LDX  PTR0
         LDAA 0,X
         PULX
         RTS

;*****************
;*  INCBUFF(), DECBUFF() - Increment or decrement
;* ptrbuff.
;*****************
INCBUFF: PSHX
         LDX  PTR0
         INX
         BRA  INCDEC
DECBUFF: PSHX
         LDX  PTR0
         DEX
INCDEC:  STX  PTR0
         PULX
         RTS

;*****************
;*  WSKIP() - Read from the INBUFF until a
;* non whitespace (space, comma, tab) character
;* is found.  Returns ptrbuff pointing to the
;* first non-whitespace character and a holds
;* that character.  WSKIP also compares a to
;* $0D (CR) and cond codes indicating the
;* results of that compare.
;*****************
WSKIP:   JSR  READBUFF  ;read character
         JSR  WCHEK
         BNE  WSKIP1    ;jump if not wspc
         JSR  INCBUFF   ;move pointer
         BRA  WSKIP     ;loop
WSKIP1:  CMPA #CR
         RTS

;*****************
;*  WCHEK(a) - Returns z=1 if a holds a
;* whitespace character, else z=0.
;*****************
WCHEK:   CMPA #$2C      ;comma
         BEQ  WCHEK1
         CMPA #' '      ;space
         BEQ  WCHEK1    ;
         CMPA #$09      ;tab
WCHEK1:  RTS

;*****************
;*   DCHEK(a) - Returns Z=1 if a = whitespace
;* or carriage return.  Else returns z=0.
;*****************
DCHEK:  JSR  WCHEK
        BEQ  DCHEK1     ;jump if whitespace

        CMPA #CR
DCHEK1: RTS

;*****************
;*  CHKABRT() - Checks for a control x (previously also delete) --patch
;* from the terminal.  If found, the stack is
;* reset and the control is transferred to main.
;* Note that this is an abnormal termination.
;*   If the input from the terminal is a control W
;* then this routine keeps waiting until any other
;* character is read.
;*****************
;*a=input();
;*if(a=cntl w) wait until any other key;
;*if(a = cntl x)  --patched. Old code: abort;if(a = cntl x or del) abort;

CHKABRT: JSR  INPUT
         BEQ  CHK4      ;jump if no input
         CMPA #CTLW
         BNE  CHK2      ;jump in not cntlw
CHKABRT1:
         JSR  INPUT
         BEQ  CHKABRT1  ;jump if no input
CHK2:

;         CMPA #DEL                          --patch
;         BEQ  CHK3     ;jump if delete      --patch

         CMPA #CTLX
         BEQ  CHK3      ;jump if control x
         CMPA #CTLA     ;
         BNE  CHK4      ;jump not control a
CHK3:
CHK4:    RTS            ;return

;*
;**********
;*


;**********
;*   INPUT() - Read from SCI.  Return a=char or 0.
;**********
INPUT:   LDAA SCSR      ;read status reg
         ANDA #$20
         BEQ  INSCI1    ;jump if rdrf=0
         LDAA SCDAT     ;read data register
         ANDA #$7F      ;mask parity
INSCI1:  RTS


;**********
;*  OUTPUT() - Output A to sci. IF autolf = 1,
;*               cr and lf sent as crlf.
;**********
OUTPUT:  PSHA
         PSHB
         PSHX
         BSR  OUTSCI
         PULX
         PULB
         PULA
         INC  CHRCNT    ;increment column count
         RTS

OUTSCI:  TST  AUTOLF
         BEQ  OUTSCI2     ;jump if autolf=0
         BSR  OUTSCI2
         CMPA #CR
         BNE  OUTSCI1
         LDAA #$0a        ;if cr, send lf
         BRA  OUTSCI2
OUTSCI1: CMPA #$0a
         BNE  OUTSCI3
         LDAA #CR        ;if lf, send cr
OUTSCI2: LDAB SCSR        ;read status
         BITB #$80
         BEQ  OUTSCI2     ;loop until tdre=1
         ANDA #$7F        ;mask parity
         STAA SCDAT       ;send character
OUTSCI3: RTS

;**********
;*   ONSCI() - Initialize the SCI on interrupt for 9600
;*                 baud at 8 MHz Extal.
;**********
ONSCI:  ldx     #$1000
        ldaa    #%00110000         ;Set SCI baud rate to 9600 baud
        staa    baud,x
        ldaa    #%00000000         ;1,8,1 data format
        staa    sccr1,x 
        ldaa    #%00101100         ;Rx,Tx enabled, Rx interrupt enabled
        staa    sccr2,x            ;no wake-up or breaks

        clr     AUTOLF
        inc     AUTOLF             ;auto cr/lf = on
        clr     Buefuss_flag       ;Reset 'command-issued' flags
        clr     TM_flag
        clr     COUNT

        rts



;*******************************
;*** I/O UTILITY SUBROUTINES ***
;***These subroutines perform the neccesary
;* data I/O operations.
;* OUTLHLF-Convert left 4 bits of A from binary
;*            to ASCII and output.
;* OUTRHLF-Convert right 4 bits of A from binary
;*            to ASCII and output.
;* OUT1BYT-Convert byte addresed by X f0O»Å+Jπary
;*           to ASCII and output.
;* OUT1BSP-Convert byte addressed by X from binary
;*           to ASCII and output followed by a space.
;* OUT2BSP-Convert 2 bytes addressed by X from binary
;*            to ASCII and  output followed by a space.
;* OUTSPAC-Output a space.
;*
;* OUTCRLF-Output a line feed and carriage return.
;*
;* OUTSTRG-Output the string of ASCII bytes addressed
;*            by X until EOT ($04).
;* OUTA-Output the ASCII character in A.
;*
;* TABTO-Output spaces until column 20 is reached.
;*
;* INCHAR-Input to A and echo one character.  Loops
;*            until character read.
;*        *******************

;**********
;*  OUTRHLF(), OUTLHLF(), OUTA()
;*Convert A from binary to ASCII and output.
;*Contents of A are destroyed..
;**********
OUTLHLF: LSRA            ;shift data to right
         LSRA
         LSRA
         LSRA
OUTRHLF: ANDA #$0F       ;mask top half
         ADDA #$30       ;convert to ascii
         CMPA #$39
         BLE  OUTA       ;jump if 0-9
         ADDA #$07       ;convert to hex A-F
OUTA:    JSR  OUTPUT     ;output character
         RTS

;**********
;*  OUT1BYT(x) - Convert the byte at X to two
;* ASCII characters and output. Return X pointing
;* to next byte.
;**********
OUT1BYT: PSHA
         LDAA 0,X        ;get data in a
         PSHA            ;save copy
         BSR  OUTLHLF    ;output left half
         PULA            ;retrieve copy
         BSR  OUTRHLF    ;output right half
         PULA
         INX
         RTS

;**********
;*  OUT1BSP(x), OUT2BSP(x) - Output 1 or 2 bytes
;* at x followed by a space.  Returns x pointing to
;* next byte.
;**********
OUT2BSP: JSR  OUT1BYT      ;do first byte
OUT1BSP: JSR  OUT1BYT      ;do next byte
OUTSPAC: LDAA #' '         ;output a space
         JSR  OUTPUT
         RTS

;**********
;*  OUTCRLF() - Output a Carriage return and
;* a line feed.  Returns a = cr.
;**********
OUTCRLF: LDAA #CR      ;cr
         JSR  OUTPUT    ;output a
         LDAA #$00
         JSR  OUTPUT    ;output padding
         LDAA #CR
         CLR  CHRCNT    ;zero the column counter
         RTS

;**********
;*  OUTSTRG(x) - Output string of ASCII bytes
;* starting at x until end of text (EOT).  Can
;* be paused by control w (any char restarts).
;**********
OUTSTRG:
         JSR  OUTCRLF
OUTSTRG0:
        PSHA
OUTSTRG1:
        LDAA 0,X          ;read char into a
         CMPA #EOT
         BEQ  OUTSTRG3     ;jump if eot
         JSR  OUTPUT       ;output character
         INX
         JSR  INPUT
         BEQ  OUTSTRG1     ;jump if no input
         CMPA #CTLW
         BNE  OUTSTRG1     ;jump if not cntlw
OUTSTRG2:
         JSR  INPUT
         BEQ  OUTSTRG2     ;jump if any input
         BRA  OUTSTRG1
OUTSTRG3:
         PULA
         RTS


;*********
;*  TABTO() - move cursor over to column 20.
;*while(chrcnt < 16) outspac.
TABTO:
        PSHA
TABTOLP:
        JSR  OUTSPAC
        LDAA CHRCNT
        CMPA #20
        BLE  TABTOLP
        PULA
        RTS

;**********
;*  INCHAR() - Reads input until character sent.
;*    Echoes char and returns with a = char.
INCHAR:  JSR  INPUT
         TSTA
         BEQ  INCHAR      ;jump if no input
         JSR  OUTPUT      ;echo
         RTS


;**********
;*   break [-][<addr>] . . .
;* Modifies the breakpoint table.  More than
;* one argument can be entered on the command
;* line but the table will hold only 4 entries.
;* 4 types of arguments are implied above:
;* break           Prints table contents.
;* break <addr>    Inserts <addr>.
;* break -<addr>   Deletes <addr>.
;* break -         Clears all entries.
;**********
;* while 1
;*     a = wskip();
;*     switch(a)
;*          case(cr):
;*               bprint(); return;

BREAK:  JSR  WSKIP
        BNE  BRKDEL     ;jump if not cr
        JSR  BPRINT     ;print table
        RTS

;*          case("-"):
;*               incbuff(); readbuff();
;*               if(dchek(a))          /* look for wspac or cr */
;*                    bpclr();
;*                    breaksw;
;*               a = buffarg();
;*               if( !dchek(a) ) return(bad argument);
;*               b = bpsrch();
;*               if(b >= 0)
;*                    brktabl[b] = 0;
;*               breaksw;

BRKDEL: CMPA #'-'
        BNE  BRKDEF     ;jump if not -
        JSR  INCBUFF
        JSR  READBUFF
        JSR  DCHEK
        BNE  BRKDEL1    ;jump if not delimeter
        JSR  BPCLR      ;clear table
        JMP  BREAK      ;do next argument
BRKDEL1:
        JSR  BUFFARG    ;get address to delete
        JSR  DCHEK
        BEQ  BRKDEL2    ;jump if delimeter
        LDX  #MSG9      ;"bad argument"
        JSR  OUTSTRG
        RTS

BRKDEL2:JSR  BPSRCH     ;look for addr in table
        TSTB
        BMI  BRKDEL3    ;jump if not found
        LDX  #BRKTABL
        ABX
        CLR  0,X        ;clear entry
        CLR  1,X
BRKDEL3:
        JMP  BREAK      ;do next argument

;*          default:
;*               a = buffarg();
;*               if( !dchek(a) ) return(bad argument);
;*               b = bpsrch();
;*               if(b < 0)            /* not already in table */
;*                    x = shftreg;
;*                    shftreg = 0;
;*                    a = x[0]; x[0] = $3F
;*                    b = x[0]; x[0] = a;
;*                    if(b != $3F) return(rom);
;*                    b = bpsrch();   /* look for hole */
;*                    if(b >= 0) return(table full);
;*                    brktabl[b] = x;
;*               breaksw;

BRKDEF: JSR  BUFFARG    ;get argument
        JSR  DCHEK
        BEQ  BRKDEF1    ;jump if delimiter
        LDX  #MSG9      ;"bad argument"
        JSR  OUTSTRG
        RTS

BRKDEF1:
        JSR  BPSRCH     ;look for entry in table
        TSTB
        BGE  BREAK      ;jump if already in table

        LDX  SHFTREG    ;x = new entry addr
        LDAA 0,X        ;save original contents
        PSHA
        LDAA #SWI
        JSR  WRITE      ;write to entry addr
        LDAB 0,X        ;read back
        PULA
        JSR  WRITE      ;restore original
        CMPB #SWI
        BEQ  BRKDEF2    ;jump if writes ok
        STX  PTR1       ;save address
        LDX  #PTR1
        JSR  OUT2BSP    ;print address
        JSR  BPRINT
        RTS

BRKDEF2:
        CLR  SHFTREG
        CLR  SHFTREG+1
        PSHX
        JSR  BPSRCH     ;look for 0 entry
        PULX
        TSTB
        BPL  BRKDEF3    ;jump if table not full
        LDX  #MSG4      ;"full"
        JSR  OUTSTRG
        JSR  BPRINT
        RTS

BRKDEF3:
        LDY  #BRKTABL
        ABY
        STX  0,Y        ;put new entry in
        JMP  BREAK      ;do next argument

;**********
;*   bprint() - print the contents of the table.
;**********
BPRINT:  JSR  OUTCRLF
         LDX  #BRKTABL
         LDAB #4
BPRINT1: JSR  OUT2BSP
         DECB
         BGT  BPRINT1   ;loop 4 times
         RTS

;**********
;*   bpsrch() - search table for address in
;* shftreg. Returns b = index to entry or
;* b = -1 if not found.
;**********
;*for(b=0; b=6; b=+2)
;*     x[] = brktabl + b;
;*     if(x[0] = shftreg)
;*          return(b);
;*return(-1);

BPSRCH:  CLRB
BPSRCH1: LDX  #BRKTABL

         ABX
         LDX  0,X       ;get table entry
         CPX  SHFTREG
         BNE  BPSRCH2   ;jump if no match
         RTS
BPSRCH2: INCB
         INCB
         CMPB #$6
         BLE  BPSRCH1   ;loop 4 times
         LDAB #$FF
         RTS


;**********
;*  ERASE   - Bulk erase the eeprom not config.
;* ERASEALL - Bulk erase eeprom and config.
;*********
BULK:   EQU  *
        LDX  STREE
        BRA  BULK1

BULKALL:
        LDX  #CONFIG
BULK1:  LDAA #$FF
        JSR  EEBULK
        RTS



;**********
;*  MD [<addr1> [<addr2>]]  - Dump memory
;* in 16 byte lines from <addr1> to <addr2>.
;*   Default starting address is "current
;* location" and default number of lines is 8.
;**********
;*ptr1 = ptrmem;        /* default start address */
;*ptr2 = ptr1 + $80;    /* default end address */
;*a = wskip();
;*if(a != cr)
;*     a = buffarg();
;*     if(countu1 = 0) return(bad argument);
;*     if( !dchek(a) ) return(bad argument);
;*     ptr1 = shftreg;
;*     ptr2 = ptr1 + $80;  /* default end address */
;*     a = wskip();
;*     if(a != cr)
;*          a = buffarg();
;*          if(countu1 = 0) return(bad argument);
;*          a = wskip();
;*          if(a != cr) return(bad argument);
;*          ptr2 = shftreg;

DUMP:    LDX  PTRMEM    ;current location
         STX  PTR1      ;default start
         LDAB #$80
         ABX
         STX  PTR2      ;default end
         JSR  WSKIP
         BEQ  DUMP1     ;jump - no arguments
         JSR  BUFFARG   ;read argument
         TST  COUNT
         BEQ  DUMPERR   ;jump if no argument
         JSR  DCHEK
         BNE  DUMPERR   ;jump if delimiter
         LDX  SHFTREG
         STX  PTR1
         LDAB #$80
         ABX
         STX  PTR2      ;default end address
         JSR  WSKIP
         BEQ  DUMP1     ;jump - 1 argument
         JSR  BUFFARG   ;read argument
         TST  COUNT
         BEQ  DUMPERR   ;jump if no argument
         JSR  WSKIP
         BNE  DUMPERR   ;jump if not cr
         LDX  SHFTREG
         STX  PTR2
         BRA  DUMP1     ;jump - 2 arguments
DUMPERR: LDX  #MSG9     ;"bad argument"
         JSR  OUTSTRG
         RTS

;*ptrmem = ptr1;
;*ptr1 = ptr1 & $fff0;

DUMP1:   LDD  PTR1
         STD  PTRMEM    ;new current location
         ANDB #$F0
         STD  PTR1      ;start dump at 16 byte boundary

;*** dump loop starts here ***
;*do:
;*     output address of first byte;

DUMPLP:  JSR  OUTCRLF
         LDX  #PTR1
         JSR  OUT2BSP   ;first address

;*     x = ptr1;
;*     for(b=0; b=16; b++)
;*          output contents;

         LDX  PTR1      ;base address
         CLRB           ;loop counter
DUMPDAT: JSR  OUT1BSP   ;hex value loop
         INCB
         CMPB #$10
         BLT  DUMPDAT   ;loop 16 times

;*     x = ptr1;
;*     for(b=0; b=16; b++)
;*          a = x[b];
;*          if($7A < a < $20)  a = $20;
;*          output ascii contents;

         CLRB           ;loop counter
DUMPASC: LDX  PTR1      ;base address
         ABX
         LDAA 0,X       ;ascii value loop
         CMPA #' '
         BLO  DUMP3     ;jump if non printable
         CMPA #$7e   ;Prev. $7a
         BLS  DUMP4     ;jump if printable
DUMP3:   LDAA #' '      ;space for non printables
DUMP4:   JSR  OUTPUT    ;output ascii value
         INCB
         CMPB #$10
         BLT  DUMPASC   ;loop 16 times

;*     chkabrt();
;*     ptr1 = ptr1 + $10;
;*while(ptr1 <= ptr2);
;*return;

         JSR  CHKABRT   ;check abort or wait
         LDD  PTR1
         ADDD #$10      ;point to next 16 byte bound
         STD  PTR1      ;update ptr1
         CPD  PTR2
         BHI  DUMP5     ;quit if ptr1 > ptr2
         CPD  #$00      ;check wraparound at $ffff
         BNE  DUMPLP    ;jump - no wraparound
         LDD  PTR2
         CPD  #$FFF0
         BLO  DUMPLP    ;upper bound not at top
DUMP5:   RTS            ;quit



;**********
;*   EEMOD [<addr1> [<addr2>]]
;* Modifies the eeprom address range.
;*  EEMOD                 -show ee address range
;*  EEMOD <addr1>         -set range to addr1 -> addr1+0.5k
;*  EEMOD <addr1> <addr2> -set range to addr1 -> addr2
;**********
;*if(<addr1>)
;*    stree = addr1;
;*    endee = addr1 + 0.5k bytes;
;*if(<addr2>)
;*    endee = addr2;
;*print(stree,endee);
EEMOD:   EQU  *
         JSR  WSKIP
         BEQ  EEMOD2    ;jump - no arguments

         JSR  BUFFARG   ;read argument
         TST  COUNT
         BEQ  EEMODER   ;jump if no argument

         JSR  DCHEK
         BNE  EEMODER   ;jump if no delimeter

         LDD  SHFTREG
         STD  PTR1
         ADDD #$01FF ;>>>   ;add 0.5k bytes to stree 
         STD  PTR2      ;default endee address
         JSR  WSKIP
         BEQ  EEMOD1    ;jump - 1 argument

         JSR  BUFFARG   ;read argument
         TST  COUNT
         BEQ  EEMODER   ;jump if no argument

         JSR  WSKIP
         BNE  EEMODER   ;jump if not cr

         LDX  SHFTREG
         STX  PTR2
EEMOD1:  LDX  PTR1
         STX  STREE     ;new stree address
         LDX  PTR2
         STX  ENDEE     ;new endee address
EEMOD2:  JSR  OUTCRLF   ;display ee range
         LDX  #STREE
         JSR  OUT2BSP
         LDX  #ENDEE
         JSR  OUT2BSP
         RTS

EEMODER: LDX  #MSG9     ;"bad argument"
         JSR  OUTSTRG
         RTS




;**********
;*  FILL <addr1> <addr2> [<data>]  - Block fill
;*memory from addr1 to addr2 with data.  Data
;*defaults to $FF.
;**********
;*get addr1 and addr2
FILL:   EQU  *
        JSR  WSKIP
        JSR  BUFFARG
        TST  COUNT
        BEQ  FILLERR    ;jump if no argument
        JSR  WCHEK
        BNE  FILLERR    ;jump if bad argument
        LDX  SHFTREG
        STX  PTR1       ;address1
        JSR  WSKIP
        JSR  BUFFARG
        TST  COUNT
        BEQ  FILLERR    ;jump if no argument
        JSR  DCHEK
        BNE  FILLERR    ;jump if bad argument
        LDX  SHFTREG
        STX  PTR2       ;address2

;*Get data if it exists
        LDAA #$FF
        STAA TMP2       ;default data
        JSR  WSKIP
        BEQ  FILL1      ;jump if default data
        JSR  BUFFARG
        TST  COUNT
        BEQ  FILLERR    ;jump if no argument
        JSR  WSKIP
        BNE  FILLERR    ;jump if bad argument
        LDAA SHFTREG+1
        STAA TMP2

;*while(ptr1 <= ptr2)
;*   *ptr1 = data
;*   if(*ptr1 != data) abort

FILL1:  EQU  *
        JSR  CHKABRT    ;check for abort
        LDX  PTR1       ;starting address
        LDAA TMP2       ;data
        JSR  WRITE      ;write the data to x
        CMPA 0,X
        BNE  FILLBAD    ;jump if no write
        CPX  PTR2
        BEQ  FILL2      ;quit yet?
        INX
        STX  PTR1
        BRA  FILL1      ;loop
FILL2:  RTS

FILLERR:                
        LDX  #MSG9      ;"bad argument"
        JSR  OUTSTRG
        RTS

FILLBAD: EQU  *
        LDX  #PTR1      ;output bad address
        JSR  OUT2BSP
        RTS



;*******************************************
;*   MM [<addr>]
;*   [<addr>]/
;* Opens memory and allows user to modify the
;* contents at <addr> or the last opened location.
;*
;*   Subcommands:
;* [<data>]<cr>       - Close current location and exit.
;* [<data>]<lf><+>    - Close current and open next.
;* [<data>]<^><-><bs> - Close current and open previous.
;* [<data>]<sp>       - Close current and open next.
;* [<data>]</><=>     - Reopen current location.
;*     The contents of the current location is only
;*  changed if valid data is entered before each
;*  subcommand.
;* [<addr>]O - Compute relative offset from current
;*     location to <addr>.  The current location must
;*     be the address of the offset byte.
;**********
;*a = wskip();
;*if(a != cr)
;*     a = buffarg();
;*     if(a != cr) return(bad argument);
;*     if(countu1 != 0) ptrmem[] = shftreg;

MEMORY:  JSR  WSKIP
         BEQ  MEM1      ;jump if cr

         JSR  BUFFARG
         JSR  WSKIP
         BEQ  MSLASH    ;jump if cr

         LDX  #MSG9     ;"bad argument"
         JSR  OUTSTRG
         RTS

MSLASH:  TST  COUNT
         BEQ  MEM1      ;jump if no argument

         LDX  SHFTREG
         STX  PTRMEM    ;update "current location"

;**********
;* Subcommands
;**********
;*outcrlf();
;*out2bsp(ptrmem[]);
;*out1bsp(ptrmem[0]);

MEM1:    JSR  OUTCRLF
MEM2:    LDX  #PTRMEM
         JSR  OUT2BSP   ;output address
MEM3:    LDX  PTRMEM
         JSR  OUT1BSP   ;output contents
         CLR  SHFTREG
         CLR  SHFTREG+1
;*while 1
;*a = termarg();
;*     switch(a)
;*          case(space):
;*             chgbyt();
;*             ptrmem[]++;
;*             if(ptrmem%16 == 0) start new line;
;*          case(linefeed | +):
;*             chgbyt();
;*             ptrmem[]++;
;*          case(up arrow | backspace | -):
;*               chgbyt();
;*               ptrmem[]--;
;*          case('/' | '='):
;*               chgbyt();
;*               outcrlf();
;*          case(O):
;*               d = ptrmem[0] - (shftreg);
;*               if($80 < d < $ff81)
;*                    print(out of range);
;*               countt1 = d-1;
;*               out1bsp(countt1);
;*          case(carriage return):
;*               chgbyt();
;*               return;
;*          default: return(command?)

MEM4:    JSR  TERMARG
         JSR  UPCASE
         LDX  PTRMEM
         CMPA #' '
         BEQ  MEMSP     ;jump if space

         CMPA #$0a
         BEQ  MEMLF     ;jump if linefeed

         CMPA #'+'
         BEQ  MEMPLUS   ;jump if +

         CMPA #'^'
         BEQ  MEMUA     ;jump if up arrow

         CMPA #'-'
         BEQ  MEMUA     ;jump if -

         CMPA #BS
         BEQ  MEMUA     ;jump if backspace

         CMPA #'/'
         BEQ  MEMSL     ;jump if /

         CMPA #'='
         BEQ  MEMSL     ;jump if =

         CMPA #'O'
         BEQ  MEMOFF    ;jump if O

         CMPA #CR
         BEQ  MEMCR     ;jump if carriage ret

         CMPA #'.'
         BEQ  MEMEND    ;jump if .

         LDX  #MSG8     ;"command?"
         JSR  OUTSTRG
         JMP  MEM1

MEMSP:   JSR  CHGBYT
         INX
         STX  PTRMEM
         XGDX           
         ANDB #$0F
         BEQ  MEMSP1    ;jump if mod16=0
         JMP  MEM3      ;continue same line

MEMSP1:  JMP  MEM1      ;.. else start new line
MEMLF:   JSR  CHGBYT
         INX
         STX  PTRMEM
         JMP  MEM2      ;output next address

MEMPLUS: JSR  CHGBYT
         INX
         STX  PTRMEM
         JMP  MEM1      ;output cr, next address

MEMUA:   JSR  CHGBYT
         DEX
         STX  PTRMEM
         JMP  MEM1      ;output cr, previous address

MEMSL:   JSR  CHGBYT
         JMP  MEM1      ;output cr, same address

MEMOFF:  LDD  SHFTREG   ;destination addr
         SUBD PTRMEM
         CMPA #$0
         BNE  MEMOFF1   ;jump if not 0

         CMPB #$80
         BLS  MEMOFF3   ;jump if in range
         BRA  MEMOFF2   ;out of range

MEMOFF1: CMPA #$FF
         BNE  MEMOFF2   ;out of range

         CMPB #$81
         BHS  MEMOFF3   ;in range

MEMOFF2: LDX  #MSG3     ;"Too long"
         JSR  OUTSTRG
         JMP  MEM1      ;output cr, addr, contents

MEMOFF3: SUBD #$1       ;b now has offset
         STAB TMP4
         JSR  OUTSPAC
         LDX  #TMP4
         JSR  OUT1BSP   ;output offset
         JMP  MEM1      ;output cr, addr, contents

MEMCR:   JSR  CHGBYT
MEMEND:  RTS            ;exit task


;**********
;*   MOVE <src1> <src2> [<dest>]  - block move
;*block at <src1> to <src2> to <dest>.
;*  Moves block 1 byte up if no <dest>.
;**********
;*a = buffarg();
;*if(countu1 = 0) return(bad argument);
;*if( !wchek(a) ) return(bad argument);
;*ptr1 = shftreg;         /* src1 */

MOVE:    EQU  *
         JSR  BUFFARG
         TST  COUNT
         BEQ  MOVERR    ;jump if no arg

         JSR  WCHEK
         BNE  MOVERR    ;jump if no delim

         LDX  SHFTREG   ;src1
         STX  PTR1

;*a = buffarg();
;*if(countu1 = 0) return(bad argument);
;*if( !dchek(a) ) return(bad argument);
;*ptr2 = shftreg;         /* src2 */

         JSR  BUFFARG
         TST  COUNT
         BEQ  MOVERR    ;jump if no arg

         JSR  DCHEK
         BNE  MOVERR    ;jump if no delim
         LDX  SHFTREG   ;src2
         STX  PTR2

;*a = buffarg();
;*a = wskip();
;*if(a != cr) return(bad argument);
;*if(countu1 != 0) tmp2 = shftreg;  /* dest */
;*else tmp2 = ptr1 + 1;

         JSR  BUFFARG
         JSR  WSKIP
         BNE  MOVERR    ;jump if not cr

         TST  COUNT
         BEQ  MOVE1     ;jump if no arg

         LDX  SHFTREG   ;dest
         BRA  MOVE2

MOVERR:  LDX  #MSG9     ;"bad argument"
         JSR  OUTSTRG
         RTS

MOVE1:   LDX  PTR1
         INX            ;default dest
MOVE2:   STX  PTR3

;*if(src1 < dest <= src2)
;*     dest = dest+(src2-src1);
;*     for(x = src2; x = src1; x--)
;*          dest[0]-- = x[0]--;
         LDX  PTR3        ;dest
         CPX  PTR1        ;src1
         BLS  MOVE3       ;jump if dest =< src1

         CPX  PTR2        ;src2
         BHI  MOVE3       ;jump if dest > src2
         LDD  PTR2
         SUBD PTR1
         ADDD PTR3
         STD  PTR3        ;dest = dest+(src2-src1)
         LDX  PTR2
MOVELP1: JSR  CHKABRT     ;check for abort
         LDAA 0,X         ;char at src2
         PSHX
         LDX  PTR3
         JSR  WRITE       ;write a to x
         CMPA 0,X
         BNE  MOVEBAD     ;jump if no write

         DEX
         STX  PTR3
         PULX
         CPX  PTR1
         BEQ  MOVRTS

         DEX
         BRA  MOVELP1     ;Loop SRC2 - SRC1 times
;*
;* else
;*     for(x=src1; x=src2; x++)
;*          dest[0]++ = x[0]++;


MOVE3:   LDX  PTR1        ;srce1
MOVELP2: JSR  CHKABRT     ;check for abort
         LDAA 0,X
         PSHX
         LDX  PTR3        ;dest
         JSR  WRITE       ;write a to x
         CMPA 0,X
         BNE  MOVEBAD     ;jump if no write

         INX
         STX  PTR3
         PULX
         CPX  PTR2
         BEQ  MOVRTS

         INX
         BRA  MOVELP2     ;Loop SRC2-SRC1 times

MOVRTS:  RTS

MOVEBAD: PULX             ;restore stack
         LDX  #PTR3
         JSR  OUT2BSP     ;output bad address
         RTS

   
;****************
;*   ASM <addr>  -assemble into memory
;*
;* 68HC11 line assembler/disassembler.
;* This routine will disassemble the opcode at
;* <addr> and then allow the user to enter a line for
;* assembly.
;*
;* Rules for assembly are as follows:
;* -A '#' sign indicates immediate addressing.
;* -A ',' (comma) indicates indexed addressing
;*       and the next character must be X or Y.
;* -All arguments are assumed to be hex and the
;*       '$' sign shouldn't be used.
;* -Arguments should be separated by 1 or more
;*       spaces or tabs.
;* -Any input after the required number of
;*       arguments is ignored.
;* -Upper or lower case makes no difference.
;*
;* To signify end of input line, the following
;* commands are available and have the indicated action:
;*   <cr>      - Finds the next opcode for
;*          assembly.  If there was no assembly input,
;*          the next opcode disassembled is retrieved
;*          from the disassembler.
;*   <lf><+>   - Works the same as carriage return
;*          except if there was no assembly input, the
;*          <addr> is incremented and the next <addr> is
;*          disassembled.
;*   <^><->    - Decrements <addr> and the previous
;*          address is then disassembled.
;*   </><=>    - Redisassembles the current address.
;*
;* To exit the assembler use CONTROL A or . (period).  
;* Of course control X (and previously DEL) will also allow you to abort.--patch
;*
;*** Equates for assembler ***
PAGE1:   EQU  $00     ;values for page opcodes
PAGE2:   EQU  $18
PAGE3:   EQU  $1A
PAGE4:   EQU  $CD
IMMED:   EQU  $0      ;addressing modes
INDX:    EQU  $1
INDY:    EQU  $2
LIMMED:  EQU  $3      ;(long immediate)
OTHER:   EQU  $4

;*** Rename variables for assem/disassem ***
AMODE:   EQU  TMP2    ;addressing mode
YFLAG:   EQU  TMP3
PNORM:   EQU  TMP4    ;page for normal opcode
OLDPC:   EQU  PTR8
PC:      EQU  PTR1    ;program counter
PX:      EQU  PTR2    ;page for x indexed
PY:      EQU  PTR2+1  ;page for y indexed
BASEOP:  EQU  PTR3    ;base opcode
CLASS:   EQU  PTR3+1  ;class
DISPC:   EQU  PTR4    ;pc for disassembler
BRADDR:  EQU  PTR5    ;relative branch offset
MNEPTR:  EQU  PTR6    ;pointer to table for dis
ASSCOMM: EQU  PTR7    ;subcommand for assembler

;**********
;*oldpc = rambase;
;*a = wskip();
;*if (a != cr)
;*   buffarg()
;*   a = wskip();
;*   if ( a != cr ) return(error);
;*   oldpc = a;
ASSEM:  EQU  *
        LDX  #RAMBS
        STX  OLDPC
        JSR  WSKIP
        BEQ  ASSLOOP   ;jump if no argument
        JSR  BUFFARG
        JSR  WSKIP
        BEQ  ASSEM1    ;jump if argument ok
        LDX  #MSGA4    ;"bad argument"
        JSR  OUTSTRG
        RTS

ASSEM1: LDX  SHFTREG
        STX  OLDPC

;*repeat
;*  pc = oldpc;
;*  out2bsp(pc);
;*  disassem();
;*  a=readln();
;*  asscomm = a;  /* save command */
;*  if(a == [^,+,-,/,=]) outcrlf;
;*  if(a == 0) return(error);

ASSLOOP: LDX  OLDPC
        STX  PC
        JSR  OUTCRLF
        LDX  #PC
        JSR  OUT2BSP   ;output the address
        JSR  DISASSM   ;disassemble opcode

        JSR  TABTO

        LDAA #PROMPT   ;prompt user
        JSR  OUTA      ;output prompt character
        JSR  READLN    ;read input for assembly
        STAA ASSCOMM
        CMPA #'^'
        BEQ  ASSLP0    ;jump if '^'
        CMPA #'+'      ;
        BEQ  ASSLP0    ;jump if '+'
        CMPA #'-'      ;
        BEQ  ASSLP0    ;jump if '-'
        CMPA #'/'
        BEQ  ASSLP0    ;jump if '/'
        CMPA #'='
        BEQ  ASSLP0    ;jump if '='
        CMPA #$00
        BNE  ASSLP1    ;jump if none of above
        RTS            ;return if bad input

ASSLP0: JSR  OUTCRLF
ASSLP1: EQU  *         ;come here for cr or lf
        JSR  OUTSPAC
        JSR  OUTSPAC
        JSR  OUTSPAC
        JSR  OUTSPAC
        JSR  OUTSPAC

;*  b = parse(input); /* get mnemonic */
;*  if(b > 5) print("not found"); asscomm='/';
;*  elseif(b >= 1)
;*     msrch();
;*     if(class==$FF)
;*        print("not found"); asscomm='/';
;*     else
;*        a = doop(opcode,class);
;*        if(a == 0) dispc=0;
;*        else process error; asscomm='/';

        JSR  PARSE
        CMPB #$5
        BLE  ASSLP2  ;jump if mnemonic <= 5 chars
        LDX  #MSGA5  ;"mnemonic not found"
        JSR  OUTSTRG
        BRA  ASSLP5
ASSLP2: EQU  *
        CMPB #$0
        BEQ  ASSLP10 ;jump if no input
        JSR  MSRCH
        LDAA CLASS
        CMPA #$FF
        BNE  ASSLP3
        LDX  #MSGA5  ;"mnemonic not found"
        JSR  OUTSTRG
        BRA  ASSLP5
ASSLP3: JSR  DOOP
        CMPA #$00
        BNE  ASSLP4  ;jump if doop error
        LDX  #$00
        STX  DISPC   ;indicate good assembly
        BRA  ASSLP10
ASSLP4: DECA         ;a = error message index
        TAB
        LDX  #MSGDIR
        ABX
        ABX
        LDX  0,X
        JSR  OUTSTRG ;output error message
ASSLP5: CLR  ASSCOMM ;error command

;*  /* compute next address - asscomm holds subcommand
;*     and dispc indicates if valid assembly occured. */
;*  if(asscomm== ^ or -) oldpc--;
;*  if(asscomm==(lf or + or cr)
;*     if(dispc==0) oldpc=pc;   /* good assembly */
;*     else
;*        if(asscomm==lf or +) dispc= ++oldpc;
;*        oldpc=dispc;
;*until(eot)
ASSLP10: EQU  *
        LDAA ASSCOMM
        CMPA #'^'
        BEQ  ASSLPA     ;jump if '^'
        CMPA #'-'
        BNE  ASSLP11    ;jump not '-'
ASSLPA: LDX  OLDPC      ;back up for '^' or '-'
        DEX
        STX  OLDPC   
        BRA  ASSLP15
ASSLP11:
        CMPA #$0a
        BEQ  ASSLP12    ;jump if linefeed
        CMPA #'+'
        BEQ  ASSLP12    ;jump if '+'
        CMPA #CR
        BNE  ASSLP15    ;jump if not cr
ASSLP12:
        LDX  DISPC
        BNE  ASSLP13    ;jump if dispc != 0
        LDX  PC
        STX  OLDPC
        BRA  ASSLP15
ASSLP13:
        CMPA #$0a
        BEQ  ASSLPB    ;jump not lf
        CMPA #'+'
        BNE  ASSLP14   ;jump not lf or '+'
ASSLPB: LDX  OLDPC
        INX
        STX  DISPC
ASSLP14:
        LDX  DISPC
        STX  OLDPC
ASSLP15:
        JMP  ASSLOOP

;****************
;*  readln() --- Read input from terminal into buffer
;* until a command character is read (cr,lf,/,^).
;* If more chars are typed than the buffer will hold,
;* the extra characters are overwritten on the end.
;*  On exit: b=number of chars read, a=0 if quit,
;* else a=next command.
;****************
;*for(b==0;b<=bufflng;b++) inbuff[b] = cr;

READLN: CLRB
        LDAA #CR    ;carriage ret
RLN0:   LDX  #INBUFF
        ABX
        STAA 0,X     ;initialize input buffer
        INCB
        CMPB #BUFFLNG
        BLT  RLN0
;*b=0;
;*repeat
;*  if(a == (ctla, cntlc, cntld, cntlx))  --patch ", del" deleted
;*     return(a=0);
;*  if(a == backspace)
;*     if(b > 0) b--;
;*     else b=0;
;*  else  inbuff[b] = upcase(a);
;*  if(b < bufflng) b++;
;*until (a == [cr,lf,+,^,-,/,=])
;*return(a);

        CLRB
RLN1:   JSR  INCHAR

;       CMPA #DEL            ;Delete     --patch
;       BEQ  RLNQUIT         ;           --patch

        CMPA #CTLX           ;Control X
        BEQ  RLNQUIT

        CMPA #CTLA           ;Control A
        BEQ  RLNQUIT

        CMPA #'.'            ;Period
        BEQ  RLNQUIT

        CMPA #CTLC           ;Control C
        BEQ  RLNQUIT

        CMPA #CTLD           ;Control D
        BEQ  RLNQUIT

        CMPA #BS      ;>>>CTLH           ;backspace
        beq  RLN2a  ; --patch

;>>>        cmpa #DEL   ; --patch Allow use of <DEL> key like CTLH
;>>>        beq  RLN2a  ; --patch
        bra  RLN2   ; --patch

RLN2a:  DECB         ;--patch
        BGT  RLN1a
        BRA  READLN          ;Start over

RLN1a:  ldaa    #BS    ;>>>new 7 lines
        jsr     OUTA                    ;Move back on screen
        ldaa    #' '
        jsr     OUTA                    ;Delete character
        ldaa    #BS
        jsr     OUTA                    ;Move back again
        bra     RLN1

RLN2:   LDX  #INBUFF
        ABX
        JSR  UPCASE
        STAA 0,X             ;Put char in buffer
        CMPB #BUFFLNG        ;Max buffer length
        BGE  RLN3            ;Jump if buffer full
        INCB                 ;Move buffer pointer
RLN3:   JSR  ASSCHEK         ;Check for subcommand
        BNE  RLN1
        RTS
RLNQUIT:
        CLRA                 ;Quit
        RTS                  ;Return


;**********
;*  parse() -parse out the mnemonic from INBUFF
;* to COMBUFF. on exit: b=number of chars parsed.
;**********
;*combuff[3] = <space>;   initialize 4th character to space.
;*ptrbuff[] = inbuff[];
;*a=wskip();
;*for (b = 0; b = 5; b++)
;*   a=readbuff(); incbuff();
;*   if (a = (cr,lf,^,/,wspace)) return(b);
;*   combuff[b] = upcase(a);
;*return(b);

PARSE:  LDAA #' '
        STAA COMBUFF+3
        LDX  #INBUFF         ;initialize buffer ptr
        STX  PTR0
        JSR  WSKIP           ;find first character
        CLRB
PARSLP: JSR  READBUFF        ;read character
        JSR  INCBUFF
        JSR  WCHEK
        BEQ  PARSRT          ;jump if whitespace
        JSR  ASSCHEK
        BEQ  PARSRT          ;jump if end of line
        JSR  UPCASE          ;convert to upper case
        LDX  #COMBUFF
        ABX
        STAA 0,X             ;store in combuff
        INCB
        CMPB #$5
        BLE  PARSLP          ;loop 6 times
PARSRT: RTS


;****************
;*  asschek() -perform compares for
;* lf, cr, ^, /, +, -, =
;****************
ASSCHEK:
          CMPA #$0a    ;linefeed
        BEQ  ASSCHK1
        CMPA #CR    ;carriage ret
        BEQ  ASSCHK1
        CMPA #'^'    ;up arrow
        BEQ  ASSCHK1
        CMPA #'/'    ;slash
        BEQ  ASSCHK1
        CMPA #'+'    ;plus
        BEQ  ASSCHK1
        CMPA #'-'    ;minus
        BEQ  ASSCHK1 ;
        CMPA #'='    ;equals
ASSCHK1:
        RTS


;*********
;*  msrch() --- Search MNETABL for mnemonic in COMBUFF.
;*stores base opcode at baseop and class at class.
;*  Class = FF if not found.
;**********
;*while ( != EOF )
;*   if (COMBUFF[0-3] = MNETABL[0-3])
;*      return(MNETABL[4],MNETABL[5]);
;*   else *MNETABL =+ 6

MSRCH:  LDX  #MNETABL        ;pointer to mnemonic table
        LDY  #COMBUFF        ;pointer to string
        BRA  MSRCH1
MSNEXT: EQU  *
        LDAB #6
        ABX                  ;point to next table entry
MSRCH1: LDAA 0,X             ;read table
        CMPA #EOT
        BNE  MSRCH2          ;jump if not end of table
        LDAA #$FF
        STAA CLASS           ;FF = not in table
        RTS
MSRCH2: CMPA 0,Y             ;op[0] = tabl[0] ?
        BNE  MSNEXT
        LDAA 1,X
        CMPA 1,Y             ;op[1] = tabl[1] ?
        BNE  MSNEXT
        LDAA 2,X
        CMPA 2,Y             ;op[2] = tabl[2] ?
        BNE  MSNEXT
        LDAA 3,X
        CMPA 3,Y             ;op[2] = tabl[2] ?
        BNE  MSNEXT
        LDD  4,X             ;opcode, class
        STAA BASEOP
        STAB CLASS
        RTS

;**********
;**   doop(baseop,class) --- process mnemonic.
;**   on exit: a=error code corresponding to error
;**                                     messages.
;**********
;*amode = OTHER; /* addressing mode */
;*yflag = 0;     /* ynoimm, nlimm, and cpd flag */
;*x[] = ptrbuff[]

DOOP:   EQU  *
        LDAA #OTHER
        STAA AMODE   ;mode
        CLR  YFLAG
        LDX  PTR0

;*while (*x != end of buffer)
;*   if (x[0]++ == ',')
;*      if (x[0] == 'y') amode = INDY;
;*      else amod = INDX;
;*      break;
;*a = wskip()
;*if( a == '#' ) amode = IMMED;

DOPLP1: CPX  #ENDBUFF ;(end of buffer)
        BEQ  DOOP1   ;jump if end of buffer
        LDD  0,X     ;read 2 chars from buffer
        INX          ;move pointer
        CMPA #','
        BNE  DOPLP1
        CMPB #'Y'    ;look for ",y"
        BNE  DOPLP2
        LDAA #INDY
        STAA AMODE
        BRA  DOOP1
DOPLP2: CMPB #'X'    ;look for ",x"
        BNE  DOOP1   ;jump if not x
        LDAA #INDX
        STAA AMODE
        BRA  DOOP1
DOOP1:  JSR  WSKIP
        CMPA #'#'    ;look for immediate mode
        BNE  DOOP2
        JSR  INCBUFF ;point at argument
        LDAA #IMMED
        STAA AMODE
DOOP2:  EQU  *

;*switch(class)
        LDAB CLASS
        CMPB #P2INH
        BNE  DOSW1
        JMP  DOP2I
DOSW1:  CMPB #INH
        BNE  DOSW2
        JMP  DOINH
DOSW2:  CMPB #REL
        BNE  DOSW3
        JMP  DOREL
DOSW3:  CMPB #LIMM
        BNE  DOSW4
        JMP  DOLIM
DOSW4:  CMPB #NIMM
        BNE  DOSW5
        JMP  DONOI
DOSW5:  CMPB #GEN
        BNE  DOSW6
        JMP  DOGENE
DOSW6:  CMPB #GRP2
        BNE  DOSW7
        JMP  DOGRP
DOSW7:  CMPB #CPD
        BNE  DOSW8
        JMP  DOCPD
DOSW8:  CMPB #XNIMM
        BNE  DOSW9
        JMP  DOXNOI
DOSW9:  CMPB #XLIMM
        BNE  DOSW10
        JMP  DOXLI
DOSW10: CMPB #YNIMM
        BNE  DOSW11
        JMP  DOYNOI
DOSW11: CMPB #YLIMM
        BNE  DOSW12
        JMP  DOYLI
DOSW12: CMPB #BTB
        BNE  DOSW13
        JMP  DOBTB
DOSW13: CMPB #SETCLR
        BNE  DODEF
        JMP  DOSET

;*   default: return("error in mnemonic table");

DODEF:  LDAA #$2
        RTS

;*  case P2INH: emit(PAGE2)

DOP2I:  LDAA #PAGE2
        JSR  EMIT

;*  case INH: emit(baseop);
;*       return(0);

DOINH:  LDAA BASEOP
        JSR  EMIT
        CLRA
        RTS

;*  case REL: a = assarg();
;*            if(a=4) return(a);
;*            d = address - pc + 2;
;*            if ($7f >= d >= $ff82)
;*               return (out of range);
;*            emit(opcode);
;*            emit(offset);
;*            return(0);

DOREL:  JSR  ASSARG
        CMPA #$04
        BNE  DOREL1  ;jump if arg ok
        RTS

DOREL1: LDD  SHFTREG ;get branch address
        LDX  PC      ;get program counter
        INX
        INX          ;point to end of opcode
        STX  BRADDR
        SUBD BRADDR  ;calculate offset
        STD  BRADDR  ;save result
        CPD  #$7F    ;in range ?
        BLS  DOREL2  ;jump if in range
        CPD #$FF80
        BHS  DOREL2  ;jump if in range
        LDAA #$09    ;'Out of range'
        RTS

DOREL2: LDAA BASEOP
        JSR  EMIT    ;emit opcode
        LDAA BRADDR+1
        JSR  EMIT    ;emit offset
        CLRA         ;normal return
        RTS

;*  case LIMM: if (amode == IMMED) amode = LIMMED;

DOLIM:  LDAA AMODE
        CMPA #IMMED
        BNE  DONOI
        LDAA #LIMMED
        STAA AMODE

;*  case NIMM: if (amode == IMMED)
;*                return("Immediate mode illegal");

DONOI:  LDAA AMODE
        CMPA #IMMED
        BNE  DOGENE  ;jump if not immediate
        LDAA #$1     ;"immediate mode illegal"
        RTS

;*  case GEN: dogen(baseop,amode,PAGE1,PAGE1,PAGE2);
;*            return;

DOGENE: LDAA #PAGE1
        STAA PNORM
        STAA PX
        LDAA #PAGE2
        STAA PY
        JSR  DOGEN
        RTS

;*  case GRP2: if (amode == INDY)
;*                emit(PAGE2);
;*                amode = INDX;
;*             if( amode == INDX )
;*                doindx(baseop);
;*             else a = assarg();
;*                if(a=4) return(a);
;*                emit(opcode+0x10);
;*                emit(extended address);
;*             return;

DOGRP:  LDAA AMODE
        CMPA #INDY
        BNE  DOGRP1
        LDAA #PAGE2
        JSR  EMIT
        LDAA #INDX
        STAA AMODE
DOGRP1: EQU  *
        LDAA AMODE
        CMPA #INDX
        BNE  DOGRP2
        JSR  DOINDEX
        RTS

DOGRP2: EQU  *
        LDAA BASEOP
        ADDA #$10
        JSR  EMIT
        JSR  ASSARG
        CMPA #$04
        BEQ  DOGRPRT ;jump if bad arg
        LDD  SHFTREG ;extended address
        JSR  EMIT
        TBA
        JSR  EMIT
        CLRA
DOGRPRT:
        RTS

;*  case CPD: if (amode == IMMED)
;*               amode = LIMMED; /* cpd */
;*            if( amode == INDY ) yflag = 1;
;*            dogen(baseop,amode,PAGE3,PAGE3,PAGE4);
;*            return;

DOCPD:  LDAA AMODE
        CMPA #IMMED
        BNE  DOCPD1
        LDAA #LIMMED
        STAA AMODE
DOCPD1: LDAA AMODE
        CMPA #INDY
        BNE  DOCPD2
        INC  YFLAG
DOCPD2: LDAA #PAGE3
        STAA PNORM
        STAA PX
        LDAA #PAGE4
        STAA PY
        JSR  DOGEN
        RTS

;*  case XNIMM: if (amode == IMMED)      /* stx */
;*                 return("Immediate mode illegal");

DOXNOI: LDAA AMODE
        CMPA #IMMED
        BNE  DOXLI
        LDAA #$1     ;"immediate mode illegal"
        RTS

;*  case XLIMM: if (amode == IMMED)  /;* cpx, ldx ;*/
;*                 amode = LIMMED;
;*              dogen(baseop,amode,PAGE1,PAGE1,PAGE4);
;*              return;

DOXLI:  LDAA AMODE
        CMPA #IMMED
        BNE  DOXLI1
        LDAA #LIMMED
        STAA AMODE
DOXLI1: LDAA #PAGE1
        STAA PNORM
        STAA PX
        LDAA #PAGE4
        STAA PY
        JSR  DOGEN
        RTS

;*  case YNIMM: if (amode == IMMED)      /;* sty ;*/
;*                 return("Immediate mode illegal");

DOYNOI: LDAA AMODE
        CMPA #IMMED
        BNE  DOYLI
        LDAA #$1     ;"immediate mode illegal"
        RTS

;*  case YLIMM: if (amode == INDY) yflag = 1;/;* cpy, ldy ;*/
;*              if(amode == IMMED) amode = LIMMED;
;*              dogen(opcode,amode,PAGE2,PAGE3,PAGE2);
;*              return;

DOYLI:  LDAA AMODE
        CMPA #INDY
        BNE  DOYLI1
        INC  YFLAG
DOYLI1: CMPA #IMMED
        BNE  DOYLI2
        LDAA #LIMMED
        STAA AMODE
DOYLI2: LDAA #PAGE2
        STAA PNORM
        STAA PY
        LDAA #PAGE3
        STAA PX
        JSR  DOGEN
        RTS

;*  case BTB:        /;* bset, bclr ;*/
;*  case SETCLR: a = bitop(baseop,amode,class);
;*               if(a=0) return(a = 3);
;*               if( amode == INDY )
;*                  emit(PAGE2);
;*                  amode = INDX;

DOBTB:  EQU  *
DOSET:  JSR  BITOP
        CMPA #$00
        BNE  DOSET1
        LDAA #$3     ;"illegal bit op"
        RTS

DOSET1: LDAA AMODE
        CMPA #INDY
        BNE  DOSET2
        LDAA #PAGE2
        JSR  EMIT
        LDAA #INDX
        STAA AMODE
DOSET2: EQU  *

;*               emit(baseop);
;*               a = assarg();
;*               if(a = 4) return(a);
;*               emit(index offset);
;*               if( amode == INDX )
;*                  Buffptr += 2;      /* skip ,x or ,y */

        LDAA BASEOP
        JSR  EMIT
        JSR  ASSARG
        CMPA #$04
        BNE  DOSET22         ;jump if arg ok
        RTS

DOSET22:
        LDAA SHFTREG+1       ;index offset
        JSR  EMIT
        LDAA AMODE
        CMPA #INDX
        BNE  DOSET3
        JSR  INCBUFF
        JSR  INCBUFF
DOSET3: EQU  *

;*               a = assarg();
;*               if(a = 4) return(a);
;*               emit(mask);   /;* mask ;*/
;*               if( class == SETCLR )
;*                  return;

        JSR  ASSARG
        CMPA #$04
        BNE  DOSET33         ;jump if arg ok
        RTS

DOSET33:
        LDAA SHFTREG+1       ;mask
        JSR  EMIT
        LDAA CLASS
        CMPA #SETCLR
        BNE  DOSET4
        CLRA
        RTS

DOSET4: EQU  *

;*               a = assarg();
;*               if(a = 4) return(a);
;*               d = (pc+1) - shftreg;
;*               if ($7f >= d >= $ff82)
;*                  return (out of range);
;*               emit(branch offset);
;*               return(0);

        JSR  ASSARG
        CMPA #$04
        BNE  DOSET5          ;jump if arg ok
        RTS

DOSET5: LDX  PC              ;program counter
        INX                  ;point to next inst
        STX  BRADDR          ;save pc value
        LDD  SHFTREG         ;get branch address
        SUBD BRADDR          ;calculate offset
        CPD #$7F
        BLS  DOSET6          ;jump if in range
        CPD #$FF80
        BHS  DOSET6          ;jump if in range
        CLRA
        JSR  EMIT
        LDAA #$09            ;'out of range'
        RTS

DOSET6: TBA                  ;offset
        JSR  EMIT
        CLRA
        RTS


;*;*********
;**   bitop(baseop,amode,class) --- adjust opcode on bit
;**       manipulation instructions.  Returns opcode in a
;**       or a = 0 if error
;**********
;*if( amode == INDX || amode == INDY ) return(op);
;*if( class == SETCLR ) return(op-8);
;*else if(class==BTB) return(op-12);
;*else fatal("bitop");

BITOP:  EQU  *
        LDAA AMODE
        LDAB CLASS
        CMPA #INDX
        BNE  BITOP1
        RTS

BITOP1: CMPA #INDY
        BNE  BITOP2  ;jump not indexed
        RTS

BITOP2: CMPB #SETCLR
        BNE  BITOP3  ;jump not bset,bclr
        LDAA BASEOP  ;get opcode
        SUBA #8
        STAA BASEOP
        RTS

BITOP3: CMPB #BTB
        BNE  BITOP4  ;jump not bit branch
        LDAA BASEOP  ;get opcode
        SUBA #12
        STAA BASEOP
        RTS

BITOP4: CLRA         ;0 = fatal bitop
        RTS

;**********
;**   dogen(baseop,mode,pnorm,px,py) - process
;** general addressing modes. Returns a = error #.
;**********
;*pnorm = page for normal addressing modes: IMM,DIR,EXT
;*px = page for INDX addressing
;*py = page for INDY addressing
;*switch(amode)
DOGEN:  LDAA AMODE
        CMPA #LIMMED
        BEQ  DOGLIM
        CMPA #IMMED
        BEQ  DOGIMM
        CMPA #INDY
        BEQ  DOGINDY
        CMPA #INDX
        BEQ  DOGINDX
        CMPA #OTHER
        BEQ  DOGOTH

;*default: error("Unknown Addressing Mode");

DOGDEF: LDAA #$06        ;unknown addre...
        RTS

;*case LIMMED: epage(pnorm);
;*             emit(baseop);
;*             a = assarg();
;*             if(a = 4) return(a);
;*             emit(2 bytes);
;*             return(0);

DOGLIM: LDAA PNORM
        JSR  EPAGE
DOGLIM1:
        LDAA BASEOP
        JSR  EMIT
        JSR  ASSARG   ;get next argument
        CMPA #$04
        BNE  DOGLIM2   ;jump if arg ok
        RTS
DOGLIM2:
        LDD  SHFTREG
        JSR  EMIT
        TBA
        JSR  EMIT
        CLRA
        RTS

;*case IMMED: epage(pnorm);
;*            emit(baseop);
;*            a = assarg();
;*            if(a = 4) return(a);
;*            emit(lobyte);
;*            return(0);

DOGIMM: LDAA PNORM
        JSR  EPAGE
        LDAA BASEOP
        JSR  EMIT
        JSR  ASSARG
        CMPA #$04
        BNE  DOGIMM1   ;jump if arg ok
        RTS
DOGIMM1:
        LDAA SHFTREG+1
        JSR  EMIT
        CLRA
        RTS

;*case INDY: epage(py);
;*           a=doindex(op+0x20);
;*           return(a);

DOGINDY:
        LDAA PY
        JSR  EPAGE
        LDAA BASEOP
        ADDA #$20
        STAA BASEOP
        JSR  DOINDEX
        RTS

;*case INDX: epage(px);
;*           a=doindex(op+0x20);
;*           return(a);

DOGINDX:
        LDAA PX
        JSR  EPAGE
        LDAA BASEOP
        ADDA #$20
        STAA BASEOP
        JSR  DOINDEX
        RTS

;*case OTHER: a = assarg();
;*            if(a = 4) return(a);
;*            epage(pnorm);
;*            if(countu1 <= 2 digits)   /;* direct ;*/
;*               emit(op+0x10);
;*               emit(lobyte(Result));
;*               return(0);
;*            else    emit(op+0x30);    /;* extended ;*/
;*               eword(Result);
;*               return(0)

DOGOTH: JSR  ASSARG
        CMPA #$04
        BNE  DOGOTH0  ;jump if arg ok
        RTS

DOGOTH0:
        LDAA PNORM
        JSR  EPAGE
        LDAA COUNT
        CMPA #$2
        BGT  DOGOTH1
        LDAA BASEOP
        ADDA #$10            ;direct mode opcode
        JSR  EMIT
        LDAA SHFTREG+1
        JSR  EMIT
        CLRA
        RTS

DOGOTH1:
        LDAA BASEOP
        ADDA #$30            ;extended mode opcode
        JSR  EMIT
        LDD  SHFTREG
        JSR  EMIT
        TBA
        JSR  EMIT
        CLRA
        RTS

;*;*;*;*;*;*;*;*;*;*
;**  doindex(op) --- handle all wierd stuff for
;**   indexed addressing. Returns a = error number.
;**********
;*emit(baseop);
;*a=assarg();
;*if(a = 4) return(a);
;*if( a != ',' ) return("Syntax");
;*buffptr++
;*a=readbuff()
;*if( a != 'x' &&  != 'y') warn("Ind Addr Assumed");
;*emit(lobyte);
;*return(0);

DOINDEX:
        LDAA BASEOP
        JSR  EMIT
        JSR  ASSARG
        CMPA #$04
        BNE  DOINDX0     ;jump if arg ok
        RTS

DOINDX0:
        CMPA #','
        BEQ  DOINDX1
        LDAA #$08        ;"syntax error"
        RTS

DOINDX1:
        JSR  INCBUFF
        JSR  READBUFF
        CMPA #'Y'
        BEQ  DOINDX2
        CMPA #'X'
        BEQ  DOINDX2
        LDX  MSGA7       ;"index addr assumed"
        JSR  OUTSTRG
DOINDX2:
        LDAA SHFTREG+1
        JSR  EMIT
        CLRA
        RTS

;**********
;**   assarg(); - get argument.  Returns a = 4 if bad
;** argument, else a = first non hex char.
;**********
;*a = buffarg()
;*if(asschk(aa) && countu1 != 0) return(a);
;*return(bad argument);

ASSARG: JSR  BUFFARG
        JSR  ASSCHEK   ;check for command
        BEQ  ASSARG1   ;jump if ok
        JSR  WCHEK     ;check for whitespace
        BNE  ASSARG2   ;jump if not ok
ASSARG1:
        TST  COUNT
        BEQ  ASSARG2   ;jump if no argument
        RTS
ASSARG2:
        LDAA #$04      ;bad argument
        RTS

;**********
;**  epage(a) --- emit page prebyte
;**********
;*if( a != PAGE1 ) emit(a);

EPAGE:  CMPA #PAGE1
        BEQ  EPAGRT  ;jump if page 1
        JSR  EMIT
EPAGRT: RTS

;**********
;*   emit(a) --- emit contents of a
;**********
EMIT:   LDX  PC
        JSR  WRITE      ;write a to x
        JSR  OUT1BSP
        STX  PC
        RTS


 
;*********************************************
PG1:    EQU     $0
PG2:    EQU     $1
PG3:    EQU     $2
PG4:    EQU     $3

;******************
;*disassem() - disassemble the opcode.
;******************
;*(check for page prebyte)
;*baseop=pc[0];
;*pnorm=PG1;
;*if(baseop==$18) pnorm=PG2;
;*if(baseop==$1A) pnorm=PG3;
;*if(baseop==$CD) pnorm=PG4;
;*if(pnorm != PG1) dispc=pc+1;
;*else dispc=pc; (dispc points to next byte)

DISASSM: EQU  *
        LDX  PC         ;address
        LDAA 0,X        ;opcode
        LDAB #PG1
        CMPA #$18
        BEQ  DISP2      ;jump if page2
        CMPA #$1A
        BEQ  DISP3      ;jump if page3
        CMPA #$CD
        BNE  DISP1      ;jump if not page4
DISP4:  INCB            ;set up page value
DISP3:  INCB
DISP2:  INCB
        INX
DISP1:  STX  DISPC      ;point to opcode
        STAB PNORM      ;save page

;*If(opcode == ($00-$5F or $8D or $8F or $CF))
;*  if(pnorm == (PG3 or PG4))
;*      disillop(); return();
;*  b=disrch(opcode,NULL);
;*  if(b==0) disillop(); return();

        LDAA 0,X  	;get current opcode
        STAA BASEOP
        INX
        STX  DISPC      ;point to next byte
        CMPA #$5F
        BLS  DIS1       ;jump if in range
        CMPA #$8D
        BEQ  DIS1       ;jump if bsr
        CMPA #$8F
        BEQ  DIS1       ;jump if xgdx
        CMPA #$CF
        BEQ  DIS1       ;jump if stop
        JMP  DISGRP     ;try next part of map
DIS1:   LDAB PNORM
        CMPB #PG3
        BLO  DIS2       ;jump if page 1 or 2
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DIS2:   LDAB BASEOP     ;opcode
        CLRB            ;class=null
        JSR  DISRCH
        TSTB
        BNE  DISPEC     ;jump if opcode found
        JSR  DISILLOP   ;"illegal opcode"
        RTS

;*   if(opcode==$8D) dissrch(opcode,REL);
;*   if(opcode==($8F or $CF)) disrch(opcode,INH);

DISPEC: LDAA BASEOP
        CMPA #$8D
        BNE  DISPEC1
        LDAB #REL
        BRA  DISPEC3    ;look for BSR opcode
DISPEC1:
        CMPA #$8F
        BEQ  DISPEC2    ;jump if XGDX opcode
        CMPA #$CF
        BNE  DISINH     ;jump not STOP opcode
DISPEC2:
        LDAB #INH
DISPEC3:                ;
        JSR  DISRCH     ;find other entry in table

;*   if(class==INH)           /* INH */
;*      if(pnorm==PG2)
;*         b=disrch(baseop,P2INH);
;*         if(b==0) disillop(); return();
;*      prntmne();
;*      return();

DISINH: EQU  *
        LDAB CLASS
        CMPB #INH
        BNE  DISREL     ;jump if not inherent
        LDAB PNORM
        CMPB #PG1
        BEQ  DISINH1    ;jump if page1
        LDAA BASEOP     ;get opcode
        LDAB #P2INH     ;class=p2inh
        JSR  DISRCH
        TSTB
        BNE  DISINH1    ;jump if found
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DISINH1:
        JSR  PRNTMNE
        RTS

;*   elseif(class=REL)       /* REL */
;*      if(pnorm != PG1)
;*         disillop(); return();
;*      prntmne();
;*      disrelad();
;*      return();

DISREL: EQU  *
        LDAB CLASS
        CMPB #REL
        BNE  DISBTD
        TST  PNORM      ;
        BEQ  DISREL1    ;jump if page1
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DISREL1:
        JSR  PRNTMNE    ;output mnemonic
        JSR  DISRELAD   ;compute relative address
        RTS

;*   else           /* SETCLR,SETCLRD,BTB,BTBD */
;*      if(class == (SETCLRD or BTBD))
;*         if(pnorm != PG1)
;*            disillop(); return();   /* illop */
;*         prntmne();           /* direct */
;*         disdir();           /* output $byte */
;*      else (class == (SETCLR or BTB))
;*         prntmne();           /* indexed */
;*         disindx();
;*      outspac();
;*      disdir();
;*      outspac();
;*      if(class == (BTB or BTBD))
;*         disrelad();
;*   return();

DISBTD: EQU  *
        LDAB CLASS
        CMPB #SETCLRD
        BEQ  DISBTD1
        CMPB #BTBD
        BNE  DISBIT     ;jump not direct bitop
DISBTD1:
        TST  PNORM      ;
        BEQ  DISBTD2    ;jump if page 1
        JSR  DISILLOP
        RTS
DISBTD2:
        JSR  PRNTMNE
        JSR  DISDIR     ;operand(direct)
        BRA  DISBIT1
DISBIT: EQU  *
        JSR  PRNTMNE
        JSR  DISINDX    ;operand(indexed)
DISBIT1:
        JSR  OUTSPAC
        JSR  DISDIR     ;mask
        LDAB CLASS
        CMPB #BTB
        BEQ  DISBIT2    ;jump if btb
        CMPB #BTBD
        BNE  DISBIT3    ;jump if not bit branch
DISBIT2:
        JSR  DISRELAD   ;relative address
DISBIT3:
        RTS


;*Elseif($60 <= opcode <= $7F)  /*  GRP2 */
;*   if(pnorm == (PG3 or PG4))
;*      disillop(); return();
;*   if((pnorm==PG2) and (opcode != $6x))
;*      disillop(); return();
;*   b=disrch(baseop & $6F,NULL);
;*   if(b==0) disillop(); return();
;*   prntmne();
;*   if(opcode == $6x)
;*      disindx();
;*   else
;*      disext();
;*   return();

DISGRP: EQU  *
        CMPA #$7F       ;a=opcode
        BHI  DISNEXT    ;try next part of map
        LDAB PNORM
        CMPB #PG3
        BLO  DISGRP2    ;jump if page 1 or 2
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DISGRP2:
        ANDA #$6F       ;mask bit 4
        CLRB            ;class=null
        JSR  DISRCH
        TSTB
        BNE  DISGRP3    ;jump if found
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DISGRP3:
        JSR  PRNTMNE
        LDAA BASEOP     ;get opcode
        ANDA #$F0
        CMPA #$60
        BNE  DISGRP4    ;jump if not 6x
        JSR  DISINDX    ;operand(indexed)
        RTS
DISGRP4:
        JSR  DISEXT     ;operand(extended)
        RTS

;*Else  ($80 <= opcode <= $FF)
;*   if(opcode == ($87 or $C7))
;*      disillop(); return();
;*   b=disrch(opcode&$CF,NULL);
;*   if(b==0) disillop(); return();

DISNEXT: EQU  *
        CMPA #$87       ;a=opcode
        BEQ  DISNEX1
        CMPA #$C7
        BNE  DISNEX2
DISNEX1:
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DISNEX2:
        ANDA #$CF       ;
        CLRB            ;class=null
        JSR  DISRCH
        TSTB
        BNE  DISNEW     ;jump if mne found
        JSR  DISILLOP   ;"illegal opcode"
        RTS

;*   if(opcode&$CF==$8D) disrch(baseop,NIMM; (jsr)
;*   if(opcode&$CF==$8F) disrch(baseop,NIMM; (sts)
;*   if(opcode&$CF==$CF) disrch(baseop,XNIMM; (stx)
;*   if(opcode&$CF==$83) disrch(baseop,LIMM); (subd)

DISNEW: LDAA BASEOP
        ANDA #$CF
        CMPA #$8D
        BNE  DISNEW1    ;jump not jsr
        LDAB #NIMM
        BRA  DISNEW4
DISNEW1:
        CMPA #$8F
        BNE  DISNEW2    ;jump not sts
        LDAB #NIMM
        BRA  DISNEW4
DISNEW2:
        CMPA #$CF
        BNE  DISNEW3    ;jump not stx
        LDAB #XNIMM
        BRA  DISNEW4
DISNEW3:
        CMPA #$83
        BNE  DISGEN     ;jump not subd
        LDAB #LIMM
DISNEW4:
        JSR  DISRCH
        TSTB
        BNE  DISGEN     ;jump if found
        JSR  DISILLOP   ;"illegal opcode"
        RTS

;*   if(class == (GEN or NIMM or LIMM   ))   /* GEN,NIMM,LIMM,CPD */
;*      if(opcode&$CF==$83)
;*         if(pnorm==(PG3 or PG4)) disrch(opcode#$CF,CPD)
;*         class=LIMM;
;*      if((pnorm == (PG2 or PG4) and (opcode != ($Ax or $Ex)))
;*         disillop(); return();
;*      disgenrl();
;*      return();

DISGEN: LDAB CLASS      ;get class
        CMPB #GEN
        BEQ  DISGEN1
        CMPB #NIMM
        BEQ  DISGEN1
        CMPB #LIMM
        BNE  DISXLN     ;jump if other class
DISGEN1:
        LDAA BASEOP
        ANDA #$CF
        CMPA #$83
        BNE  DISGEN3    ;jump if not #$83
        LDAB PNORM
        CMPB #PG3
        BLO  DISGEN3    ;jump not pg3 or 4
        LDAB #CPD
        JSR  DISRCH     ;look for cpd mne
        LDAB #LIMM
        STAB CLASS      ;set class to limm
DISGEN3:
        LDAB PNORM
        CMPB #PG2
        BEQ  DISGEN4    ;jump if page 2
        CMPB #PG4
        BNE  DISGEN5    ;jump not page 2 or 4
DISGEN4:
        LDAA BASEOP
        ANDA #$B0       ;mask bits 6,3-0
        CMPA #$A0
        BEQ  DISGEN5    ;jump if $Ax or $Ex
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DISGEN5:
        JSR  DISGENRL   ;process general class
        RTS

;*   else       /* XLIMM,XNIMM,YLIMM,YNIMM */
;*      if(pnorm==(PG2 or PG3))
;*         if(class==XLIMM) disrch(opcode&$CF,YLIMM);
;*         else disrch(opcode&$CF,YNIMM);
;*      if((pnorm == (PG3 or PG4))
;*         if(opcode != ($Ax or $Ex))
;*            disillop(); return();
;*      class=LIMM;
;*      disgen();
;*   return();

DISXLN: LDAB PNORM
        CMPB #PG2
        BEQ  DISXLN1    ;jump if page2
        CMPB #PG3
        BNE  DISXLN4    ;jump not page3
DISXLN1:
        LDAA BASEOP
        ANDA #$CF
        LDAB CLASS
        CMPB #XLIMM
        BNE  DISXLN2
        LDAB #YLIMM
        BRA  DISXLN3    ;look for ylimm
DISXLN2:
        LDAB #YNIMM     ;look for ynimm
DISXLN3:
        JSR  DISRCH
DISXLN4:
        LDAB PNORM
        CMPB #PG3
        BLO  DISXLN5    ;jump if page 1 or 2
        LDAA BASEOP     ;get opcode
        ANDA #$B0       ;mask bits 6,3-0
        CMPA #$A0
        BEQ  DISXLN5    ;jump opcode = $Ax or $Ex
        JSR  DISILLOP   ;"illegal opcode"
        RTS
DISXLN5:
        LDAB #LIMM
        STAB CLASS
        JSR  DISGENRL   ;process general class
        RTS


;******************
;*disrch(a=opcode,b=class)
;*return b=0 if not found
;*  else mneptr=points to mnemonic
;*        class=class of opcode
;******************
;*x=#MNETABL
;*while(x[0] != eot)
;*   if((opcode==x[4]) && ((class=NULL) || (class=x[5])))
;*      mneptr=x;
;*      class=x[5];
;*      return(1);
;*   x += 6;
;*return(0);      /* not found */

DISRCH: EQU  *
        LDX  #MNETABL   ;point to top of table
DISRCH1:
        CMPA 4,X        ;test opcode
        BNE  DISRCH3    ;jump not this entry
        TSTB
        BEQ  DISRCH2    ;jump if class=null
        CMPB 5,X        ;test class
        BNE  DISRCH3    ;jump not this entry
DISRCH2:
        LDAB 5,X
        STAB CLASS
        STX  MNEPTR     ;return ptr to mnemonic
        INCB            ;
        RTS             ;return found
DISRCH3:
        PSHB            ;save class
        LDAB #6
        ABX
        LDAB 0,X
        CMPB #EOT       ;test end of table
        PULB
        BNE  DISRCH1
        CLRB
        RTS             ;return not found

;******************
;*prntmne() - output the mnemonic pointed
;*at by mneptr.
;******************
;*outa(mneptr[0-3]);
;*outspac;
;*return();

PRNTMNE: EQU  *
        LDX  MNEPTR
        LDAA 0,X
        JSR  OUTA       ;output char1
        LDAA 1,X
        JSR  OUTA       ;output char2
        LDAA 2,X
        JSR  OUTA       ;output char3
        LDAA 3,X
        JSR  OUTA       ;output char4
        JSR  OUTSPAC
        RTS

;******************
;*disindx() - process indexed mode
;******************
;*disdir();
;*outa(',');
;*if(pnorm == (PG2 or PG4)) outa('Y');
;*else outa('X');
;*return();

DISINDX: EQU  *
        JSR  DISDIR     ;output $byte
        LDAA #','
        JSR  OUTA       ;output ,
        LDAB PNORM
        CMPB #PG2
        BEQ  DISIND1    ;jump if page2
        CMPB #PG4
        BNE  DISIND2    ;jump if not page4
DISIND1:
        LDAA #'Y'
        BRA DISIND3
DISIND2:
        LDAA #'X'
DISIND3:
        JSR  OUTA       ;output x or y
        RTS

;******************
;*disrelad() - compute and output relative address.
;******************
;* braddr = dispc[0] + (dispc++);( 2's comp arith)
;*outa('$');
;*out2bsp(braddr);
;*return();

DISRELAD: EQU *
        LDX  DISPC
        LDAB 0,X        ;get relative offset
        INX
        STX  DISPC
        TSTB
        BMI  DISRLD1    ;jump if negative
        ABX
        BRA  DISRLD2
DISRLD1:
        DEX
        INCB
        BNE  DISRLD1    ;subtract
DISRLD2:
        STX  BRADDR     ;save address
        JSR  OUTSPAC
        LDAA #'$'
        JSR  OUTA
        LDX  #BRADDR
        JSR  OUT2BSP    ;output address
        RTS


;******************
;*disgenrl() - output data for the general cases which
;*includes immediate, direct, indexed, and extended modes.
;******************
;*prntmne();
;*if(baseop == ($8x or $Cx))   /* immediate */
;*   outa('#');
;*   disdir();
;*   if(class == LIMM)
;*      out1byt(dispc++);
;*elseif(baseop == ($9x or $Dx))  /* direct */
;*   disdir();
;*elseif(baseop == ($Ax or $Ex)) /* indexed */
;*   disindx();
;*else  (baseop == ($Bx or $Fx)) /* extended */
;*   disext();
;*return();

DISGENRL: EQU *
        JSR  PRNTMNE    ;print mnemonic
        LDAA BASEOP     ;get opcode
        ANDA #$B0       ;mask bits 6,3-0
        CMPA #$80
        BNE  DISGRL2    ;jump if not immed
        LDAA #'#'       ;do immediate
        JSR  OUTA
        JSR  DISDIR
        LDAB CLASS
        CMPB #LIMM
        BEQ  DISGRL1    ;jump class = limm
        RTS
DISGRL1:
        LDX  DISPC
        JSR  OUT1BYT
        STX  DISPC
        RTS
DISGRL2:
        CMPA #$90
        BNE  DISGRL3    ;jump not direct
        JSR  DISDIR     ;do direct
        RTS
DISGRL3:
        CMPA #$A0
        BNE  DISGRL4    ;jump not indexed
        JSR  DISINDX    ;do extended
        RTS
DISGRL4:
        JSR  DISEXT     ;do extended
        RTS

;*****************
;*disdir() - output "$ next byte"
;*****************
DISDIR: EQU  *
        LDAA #'$'
        JSR  OUTA
        LDX  DISPC
        JSR  OUT1BYT
        STX  DISPC
        RTS

;*****************
;*disext() - output "$ next 2 bytes"
;*****************
DISEXT: EQU  *
        LDAA #'$'
        JSR  OUTA
        LDX  DISPC
        JSR  OUT2BSP
        STX  DISPC
        RTS


;*****************
;*disillop() - output "illegal opcode"
;*****************
DISMSG1: dc.b  'ILLOP'
         dc.b  EOT
DISILLOP: EQU *
        PSHX
        LDX  #DISMSG1
        JSR  OUTSTRG0   ;no cr
        PULX
        RTS



;**********
;*   help  -  List buffalo commands to terminal.
;**********
HELP:    EQU  *
         LDX  #HELPMSG1
         JSR  OUTSTRG    ;print help screen
         RTS
  


;**********
;*   call [<addr>] - Execute a jsr to <addr> or user
;*pc value.  Return to monitor via  rts or breakpoint.
;**********
;*a = wskip();
;*if(a != cr)
;*     a = buffarg();
;*     a = wskip();
;*     if(a != cr) return(bad argument)
;*     pc = shftreg;
CALL:    JSR  WSKIP
         BNE  CALL1       ;return if no arg
         RTS
CALL1:
         JSR  BUFFARG
         JSR  WSKIP
         BEQ  CALL2       ;jump if cr
         LDX  #MSG9       ;"bad argument"
         JSR  OUTSTRG
         RTS
CALL2:   LDX  SHFTREG
         STX  REGS        ;pc = <addr>

;*put return address on user stack
;*setbps();
;*restack();     /* restack and go*/
CALL3:
         LDX  #RETURN     ;make "RETURN" the place to come back to
         PSHX
         JSR  SETBPS
         CLR  TMP2        ;1=go, 0=call
         JMP  RESTACK     ;go to user code

;**********
;*   return() - Return here from rts after
;*call command.
;**********
RETURN:  PSHA             ;save a register
         TPA
         STAA REGS+8      ;cc register
         PULA
         STD  REGS+6      ;a and b registers
         STX  REGS+4      ;x register
         STY  REGS+2      ;y register
         JSR  REMBPS      ;remove breakpoints
         JSR  OUTCRLF
         JSR  RPRINT      ;print user registers
         RTS

;** RESTACK - Restore user stack and RTI to user code.
;* This code is the pathway to execution of user code.
;*(Force extended addressing to maintain cycle count)
;*Restore user stack and rti to user code
RESTACK:EQU  *                                   
        LDX  >REGS
        PSHX            ;pc
        LDX  >REGS+2
        PSHX            ;y
        LDX  >REGS+4
        PSHX            ;x
        LDD  >REGS+6
        PSHA            ;a
        PSHB            ;b
        LDAA >REGS+8
        PSHA            ;ccr
        RTI


;**********
;*   go [<addr>] - Execute starting at <addr> or
;*user's pc value.  Executes an rti to user code.
;*Returns to monitor via an swi through swiin.
;**********
;*a = wskip();
;*if(a != cr)
;*     a = buffarg();
;*     a = wskip();
;*     if(a != cr) return(bad argument)
;*     pc = shftreg;
;*setbps();
;*restack();     /* restack and go*/
GO:      JSR  WSKIP
         BEQ  GO2         ;jump if no arg
         JSR  BUFFARG
         JSR  WSKIP
         BEQ  GO1         ;jump if cr
         LDX  #MSG9       ;"bad argument"
         JSR  OUTSTRG
         RTS
GO1:     LDX  SHFTREG
         STX  REGS        ;pc = <addr>
GO2:     CLR  TMP2        
         INC  TMP2        ;1=go, 0=call
         JSR  SETBPS
         JMP  RESTACK     ;go to user code

;*****
;** SWIIN - Breakpoints from go or call commands enter here.
;*Remove breakpoints, save user registers, return
SWIIN:   EQU  *        ;swi entry point
         TSX           ;user sp -> x
         LDS  PTR2     ;restore monitor sp
         JSR  SAVSTACK ;save user regs
         JSR  REMBPS   ;remove breakpoints from code
         LDX  REGS
         DEX
         STX  REGS     ;save user pc value

;*if(call command) remove call return addr from user stack;
         TST  TMP2     ;1=go, 0=call
         BNE  GO3      ;jump if go command
         LDX  SP       ;remove return address
         INX           ;  user stack pointer
         INX
         STX  SP
GO3:     JSR  OUTCRLF  ;print register values
         JSR  RPRINT
         RTS           ;done 

;**********
;*   proceed - Same as go except it ignores
;* a breakpoint at the first opcode.  Calls
;* trace once and then go.
;**********
PROCEED: CLR  TMP2       ;flag for breakpoints
         INC  TMP2       ;0=trace, 1=proceed
         JMP  TRACE3

;**********
;*   trace <n> - Trace n instructions starting
;* at user's pc value. n is a hex number less than
;* $FF (defaults to 1).
;**********
;*countt1 = 1
;*a = wskip();
;*if(a != cr)
;*     a = buffarg(); a = wskip();
;*     if(a != cr) return(bad argument);
;*     countt1 = n
;
TRACE:   CLR  TMP4
         INC  TMP4        ;default countt1 = 1
         CLR  TMP2        ;0 = trace
         JSR  WSKIP
         CMPA #CR
         BEQ  TRACE2      ;jump if cr
         JSR  BUFFARG
         JSR  WSKIP
         CMPA #CR
         BEQ  TRACE1      ;jump if cr
         LDX  #MSG9       ;"bad argument"
         JSR  OUTSTRG
         RTS
TRACE1:  LDAA SHFTREG+1   ;n
         STAA TMP4

;*Print opcode
TRACE2:  JSR  OUTCRLF
         LDX  #MSG5      ;"op-"
         JSR  OUTSTRG
         LDX  REGS
         JSR  OUT1BSP    ;opcode

;*Save user OC4 regs, setup monitor OC4 regs
TRACE3:  LDAA TCTL1
         STAA PTR2       ;save user mode/level
         ANDA #$F3
         STAA TCTL1      ;disable oc4 output
         LDAA TMSK1
         STAA PTR2+1     ;save user int masks
         CLR  TMSK2      ;disable tof and pac ints

;*Put monitor TOC4 vector into jump table
         LDX  JTOC4+1
         STX  PTR4        ;save user's vector
         LDAA #$7E        ;jmp opcode
         STAA JTOC4
         LDX  #TRACEIN
         STX  JTOC4+1     ;monitor toc4 vector

;*Unmask i bit in user ccr
         LDAA REGS+8      ;user ccr
         ANDA #$EF        ;clear i bit
         STAA REGS+8

;*Arm OC4 interrupt
         LDAB #87        ;cycles to end of rti
         LDX  TCNT       ;timer count value
         ABX                                     ;3~  *
         STX  TOC4       ;oc4 match register      5~  *
         LDAA #$10                               ;2~  *
         STAA TFLG1      ;clear oc4 int flag      4~  *
         STAA TMSK1      ;enable oc4 interrupt    4~  * 86~
         CLI                                     ;2~  *
         JMP  RESTACK    ;execute an rti         66~  *

;**********
;*   tracein - return from toc4 interrupt.
;**********
;*Disable toc4 interrupt
;*replace user's toc4 vector
TRACEIN: SEI
         CLR  TMSK1      ;disable timer ints
         TSX
         LDS  #ram_end
         JSR  SAVSTACK   ;save user regs
         LDX  PTR4       ;
         STX  JTOC4+1
         JSR  CHKABRT    ;check for abort

;*if(flagt1 = 1) jump to GO command ( proceed )
         TST  TMP2
         BEQ  TRACE9      ;jump if trace command
         JMP  GO2

;*rprint();
;*while(countt1 >= 0) continue trace;

TRACE9:  JSR  OUTCRLF     ;print registers for
         JSR  RPRINT      ;        trace only.
         DEC  TMP4
         BHI  TRACE2      ;jump if countt1 >= 0
         rts              ;return to monitor
;*                        ; (sp destroyed above)

;**********
;*  setbps - Replace user code with swi's at
;*breakpoint addresses.
;**********
;*for(b=0; b=6; b =+ 2)
;*     x = brktabl[b];
;*     if(x != 0)
;*          optabl[b] = x[0];
;*          x[0] = $3F;

SETBPS:  CLRB
SETBPS1: LDX  #BRKTABL
         LDY  #PTR6
         ABX
         ABY
         LDX  0,X         ;breakpoint table entry
         BEQ  SETBPS2     ;jump if 0
         LDAA 0,X         ;save user opcode
         STAA 0,Y         ;
         LDAA #SWI        ;insert swi into code
         STAA 0,X
SETBPS2: ADDB #$2
         CMPB #$6
         BLE  SETBPS1     ;loop 4 times

;*Put monitor SWI vector into jump table
         LDX  JSWI+1
         STX  PTR4        ;save user swi vector
         LDAA #$7E        ;jmp opcode
         STAA JSWI
         LDX  #SWIIN
         STX  JSWI+1      ;monitor swi vector
         RTS

;**********
;*   rembps - Remove breakpoints from user code.
;**********
;*for(b=0; b=6; b =+ 2)
;*     x = brktabl[b];
;*     if(x != 0)
;*          x[0] = optabl[b];

REMBPS:  CLRB
REMBPS1: LDX  #BRKTABL
         LDY  #PTR6
         ABX
         ABY
         LDX  0,X         ;breakpoint table entry
         BEQ  REMBPS2     ;jump if 0
         LDAA 0,Y         ;restore user's opcode
         STAA 0,X
REMBPS2: ADDB #$2
         CMPB #$6
         BLE  REMBPS1     ;loop 4 times

;*Replace user's SWI vector
         LDX  PTR4
         STX  JSWI+1
         RTS



;** Return here from run one line of user code.
XIRQIN: EQU  *
        TSX               ;user sp -> x
        LDS  PTR2         ;restore monitor sp

;** SAVSTACK - Save user's registers.
;* On entry - x points to top of user stack.
SAVSTACK: EQU *
        LDAA 0,X
        STAA REGS+8      ;user ccr
        LDD  1,X
        STAA REGS+7      ;b
        STAB REGS+6      ;a
        LDD  3,X
        STD  REGS+4      ;x
        LDD  5,X
        STD  REGS+2      ;y
        LDD  7,X
        STD  REGS        ;pc
        LDAB #8
        ABX
        STX  SP          ;user stack pointer
        LDAA TCTL1       ;force oc5 pin high which
        ORAA #$03        ;  is tied to xirq line
        STAA TCTL1
        LDAA #$08
        STAA CFORC
        RTS



;**********
;*   load <ptrbuff[]> - Load s1/s9 records from
;* host to memory.  Ptrbuff[] points to string in
;* input buffer which is a command to output s1/s9
;* records from the host ("cat filename" for unix).
;* Returns error and address if it can't write
;* to a particular location.
;**********
;*   verify <ptrbuff[]> - Verify memory from load
;* command.  Ptrbuff[] is same as for load.
;* tmp3 is used as an error indication, 0=no errors,
;* 1=receiver, 2=rom error, 3=checksum error.
;**********
VERIFY:   CLR  TMP2
          INC  TMP2      ;TMP2=1=verify
          BRA  LOAD1
LOAD:     CLR  TMP2      ;     0=load

;*a=wskip();
;*if(a = cr) goto transparent mode;
;*if(t option) hostdev = iodev;


LOAD1:    EQU  *
          LDAA #0
          STAA TMSK2     ;Turn off RTI etc.
          JSR  OUTCRLF
          CLR  TMP3      ;clear error flag
          JSR  WSKIP
          CMPA #CR
          BNE  LOAD3     ;jump if 'LOAD<cr>'
          BRA  LOAD10    ;go wait for s1 records

;*else while(not cr)
;*     read character from input buffer;
;*     send character to host;
LOAD3:    LDX  #MSG2     ;"command not found"
          JSR  OUTSTRG
          RTS


;*repeat:                           /* look for s records */
;*      if(hostdev != iodev) check abort;
;*      a = hostin();
;*      if(a = 'S')
;*          a = hostin;
;*          if(a = '1')
;*              checksum = 0;
;*              get byte count in b;
;*              get base address in x;
;*              while(byte count > 0)
;*                  byte();
;*                  x++; b--;
;*                  if(tmp3=0)           /* no error */
;*                      if(load) x[0] = shftreg+1;
;*                      if(x[0] != shftreg+1)
;*                          tmp3 = 2;    /* rom error */
;*                          ptr3 = x;    /* save address */
;*              if(tmp3 = 0) do checksum;
;*              if(checksum err) tmp3 = 3; /* checksum error */
;** Look for s-record header
LOAD10:   EQU  *
          JSR  INPUT     ;read host
          TSTA
          BEQ  LOAD10    ;jump if no input
          CMPA #'S'
          BNE  LOAD10    ;jump if not S
LOAD12:   JSR  INPUT     ;read host
          TSTA
          BEQ  LOAD12    ;jump if no input
          CMPA #'9'
          BEQ  LOAD90    ;jump if S9 record
          CMPA #'1'
          BNE  LOAD10    ;jump if not S1
          CLR  TMP4      ;clear checksum
;** Get Byte Count and Starting Address
          JSR  BYTE
          LDAB SHFTREG+1
          SUBB #$2       ;b = byte count
          JSR  BYTE
          JSR  BYTE
          LDX  SHFTREG
          DEX            ;condition for loop
;** Get and Store Incoming Data Byte
LOAD20:   JSR  BYTE      ;get next byte
          INX
          DECB           ;check byte count
          BEQ  LOAD30    ;if b=0, go do checksum
          TST  TMP3
          BNE  LOAD10    ;jump if error flagged
          TST  TMP2
          BNE  LOAD21    ;jump if verify
          LDAA SHFTREG+1
          JSR  WRITE     ;load only
LOAD21:   CMPA 0,X       ;verify ram location
          BEQ  LOAD20    ;jump if ram ok
          LDAA #$02
          STAA TMP3      ;indicate rom error
          STX  PTR3      ;save error address
          BRA  LOAD20    ;finish download
;** Get and Test Checksum
LOAD30:   TST  TMP3
          BNE  LOAD10    ;jump if error already
          LDAA TMP4
          INCA           ;do checksum
          BEQ  LOAD10    ;jump if s1 record okay
          LDAA #$03
          STAA TMP3      ;indicate checksum error
          BRA  LOAD10

;*          if(a = '9')
;*              read rest of record;
;*              if(tmp3=2) return("[ptr3]");
;*              if(tmp3=1) return("rcv error");
;*              if(tmp3=3) return("checksum err");
;*              else return("done");
LOAD90:   JSR  BYTE
          LDAB SHFTREG+1 ;b = byte count
LOAD91:   JSR  BYTE
          DECB
          BNE  LOAD91    ;loop until end of record
          LDAB #$64                                 
LOAD91A:  JSR  DLY10MS   ;delay 1 sec -let host finish
          DECB
          BNE  LOAD91A
          LDAA #$C0
          STAA TMSK2     ;Turn on RTI and TOF interrupts
          JSR  INPUT     ;clear comm device
          LDD  #$7E0D    ;put dummy command in inbuff
          STD  INBUFF
          INC  AUTOLF    ;turn on autolf
          LDX  #MSG11    ;"done" default msg
          LDAA TMP3
          CMPA #$02
          BNE  LOAD92    ;jump not rom error
          LDX  #PTR3
          JSR  OUT2BSP   ;address of rom error
          BRA  LOAD95
LOAD92:   CMPA #$01
          BNE  LOAD93    ;jump not rcv error
          LDX  #MSG14    ;"rcv error"
          BRA  LOAD94
LOAD93:   CMPA #$03
          BNE  LOAD94    ;jump not checksum error
          LDX  #MSG12    ;"checksum error"
LOAD94:   JSR  OUTSTRG
LOAD95:   RTS

;**********
;*  byte() -  Read 2 ascii bytes from host and
;*convert to one hex byte.  Returns byte
;*shifted into shftreg and added to tmp4.
;**********
BYTE:     PSHB
          PSHX
BYTE0:    JSR  INPUT     ;read host (1st byte)
          TSTA           ;
          BEQ  BYTE0     ;loop until input
          JSR  HEXBIN
BYTE1:    JSR  INPUT     ;read host (2nd byte)
          TSTA
          BEQ  BYTE1     ;loop until input
          JSR  HEXBIN
          LDAA SHFTREG+1
          ADDA TMP4
          STAA TMP4      ;add to checksum
          PULX
          PULB
          RTS

;**********
;*   register [<name>]  - prints the user regs
;*and opens them for modification.  <name> is
;*the first register opened (default = P).
;*   Subcommands:
;* [<nn>]<space>  Opens the next register.
;* [<nn>]<cr>     Return.
;*    The register value is only changed if
;*    <nn> is entered before the subcommand.
;**********
;*x[] = reglist
;*a = wskip(); a = upcase(a);
;*if(a != cr)
;*     while( a != x[0] )
;*          if( x[0] = "s") return(bad argument);
;*          x[]++;
;*     incbuff(); a = wskip();
;*     if(a != cr) return(bad argument);

REGISTER:
         LDX  #REGLIST
         JSR  WSKIP       ;a = first char of arg
         JSR  UPCASE      ;convert to upper case
         CMPA #$D
         BEQ  REG4        ;jump if no argument
REG1:    CMPA 0,X
         BEQ  REG3
         LDAB 0,X
         INX
         CMPB #'S'
         BNE  REG1        ;jump if not "s"
REG2:    LDX  #MSG9       ;"bad argument"
         JSR  OUTSTRG
         RTS
REG3:    PSHX
         JSR  INCBUFF
         JSR  WSKIP       ;next char after arg
         PULX
         BNE  REG2        ;jump if not cr

;*rprint();
;*     while(x[0] != "s")
;*          rprnt1(x);
;*          a = termarg();    /* read from terminal */
;*          if( ! dchek(a) ) return(bad argument);
;*          if(countu1 != 0)
;*               if(x[14] = 1)
;*                    regs[x[7]++ = shftreg;
;*               regs[x[7]] = shftreg+1;
;*          if(a = cr) break;
;*return;

REG4:    JSR  RPRINT      ;print all registers
REG5:    JSR  OUTCRLF
         JSR  RPRNT1      ;print reg name
         CLR  SHFTREG
         CLR  SHFTREG+1
         JSR  TERMARG     ;read subcommand
         JSR  DCHEK
         BEQ  REG6        ;jump if delimeter
         LDX  #MSG9       ;"bad argument"
         JSR  OUTSTRG
         RTS
REG6:    PSHA
         PSHX
         TST  COUNT
         BEQ  REG8        ;jump if no input
         LDAB 7,X         ;get reg offset
         LDAA 14,X        ;byte size
         LDX  #REGS       ;user registers
         ABX
         TSTA
         BEQ  REG7        ;jump if 1 byte reg
         LDAA SHFTREG
         STAA 0,X         ;put in top byte
         INX
REG7:    LDAA SHFTREG+1
         STAA 0,X         ;put in bottom byte
REG8:    PULX
         PULA
         LDAB 0,X         ;CHECK FOR REGISTER S
         CMPB #'S'
         BEQ  REG9        ;jump if "s"
         INX              ;point to next register
         CMPA #$D
         BNE  REG5        ;jump if not cr
REG9:    RTS


;* Equates
JPORTD: EQU   $08
JDDRD:  EQU   $09
JBAUD:  EQU   $2B
JSCCR1: EQU   $2C
JSCCR2: EQU   $2D
JSCSR:  EQU   $2E
JSCDAT: EQU   $2F
;*

;************
;*  xboot [<addr1> [<addr2>]] - Use SCI to talk to an 'hc11 in
;* boot mode.  Downloads bytes from addr1 thru addr2.
;* Default addr1 = $C000 and addr2 = $C0ff.
;*
;* IMPORTANT:
;* if talking to an 'A8 or 'A2: use either default addresses or ONLY
;*    addr1 - this sends 256 bytes
;* if talking to an 'E9: include BOTH addr1 and addr2 for variable
;*    length
;************

;*Get arguments
;*If no args, default $C000
BOOT:   JSR   WSKIP
        BNE   BOT1       ;jump if arguments
        LDX   #$C0FF     ;addr2 default
        STX   PTR5
        LDY   #$C000     ;addr1 default
        BRA   BOT2       ;go - use default address

;*Else get arguments
BOT1:   JSR   BUFFARG
        TST   COUNT
        BEQ   BOTERR    ;jump if no address
        LDY   SHFTREG   ;start address (addr1)
        JSR   WSKIP
        BNE   BOT1A     ;go get addr2
        STY   PTR5      ;default addr2...
        LDD   PTR5      ;...by taking addr1...
        ADDD  #$FF      ;...and adding 255 to it...
        STD   PTR5      ;...for a total download of 256
        BRA   BOT2      ;continue
;*
BOT1A:  JSR   BUFFARG
        TST   COUNT
        BEQ   BOTERR    ;jump if no address
        LDX   SHFTREG   ;end address (addr2)
        STX   PTR5
        JSR   WSKIP
        BNE   BOTERR    ;go use addr1 and addr2
        BRA   BOT2

;*
BOTERR: LDX   #MSG9     ;"bad argument"
        JSR   OUTSTRG
        RTS

;*Boot routine
BOT2:   LDAB  #$FF       ;control character ($ff -> download)
        JSR   BTSUB      ;set up SCI and send control char
;*                       ; initializes X as register pointer
;*Download block
BLOP:   LDAA  0,Y
        STAA  JSCDAT,X   ;write to transmitter
        BRCLR JSCSR,X,#$80,*      ;wait for TDRE
        CPY   PTR5       ;if last...
        BEQ   BTDONE     ;     ...quit
        INY              ;else...
        BRA   BLOP       ;     ...send next
BTDONE: RTS

;************************************************
;*   btsub   - sets up SCI and outputs control character
;* On entry, B = control character
;* On exit,  X = $1000
;*           A = $0C
;***************************

BTSUB:  EQU   *
        LDX   #$1000    ;to use indexed addressing
        LDAA  #$02
        STAA  JPORTD,X  ;drive transmitter line
        STAA  JDDRD,X   ;  high
        CLR   JSCCR2,X  ;turn off XMTR and RCVR
        LDAA  #$22      ;BAUD = /16
        STAA  JBAUD,X
        LDAA  #$0C      ;TURN ON XMTR & RCVR
        STAA  JSCCR2,X
        STAB  JSCDAT,X
        BRCLR JSCSR,X,#$80,*   ;wait for TDRE
        RTS


;***********
;* TILDE - This command is put into the combuff by the
;* load command so that extraneous carriage returns after
;* the load will not hang up.
TILDE:  RTS


;************************************************
;*
;* LCD test:
;*
;************************************************
        
;* BUEF_MSG:
;*        ldaa    #0
;*        ldy     #Buef_screen
;*        jsr     SCREENS
;*        rts

  ;*********************
;*** COMMAND TABLE ***
COMTABL: EQU  *
         dc.b  3
         dc.b  'ASM'
         dc.w  ASSEM
         dc.b  5
         dc.b  'BREAK'
         dc.w  BREAK
         dc.b  5
         dc.b  'ERASE'
         dc.w  BULK
         dc.b  8
         dc.b  'ERASEALL'
         dc.w  BULKALL
         dc.b  4
         dc.b  'CALL'
         dc.w  CALL
         dc.b  2
         dc.b  'MD'
         dc.w  DUMP
         dc.b  5
         dc.b  'EEMOD'
         dc.w  EEMOD
         dc.b  2
         dc.b  'BF'
         dc.w  FILL
         dc.b  2
         dc.b  'GO'
         dc.w  GO
         dc.b  4
         dc.b  'HELP'
         dc.w  HELP
         dc.b  4
         dc.b  'LOAD'
         dc.w  LOAD
         dc.b  2          ;LENGTH OF COMMAND
         dc.b  'MM'       ;ASCII COMMAND
         dc.w  MEMORY     ;COMMAND ADDRESS
         dc.b  4
         dc.b  'MOVE'
         dc.w  MOVE
         dc.b  7
         dc.b  'PROCEED'
         dc.w  PROCEED
         dc.b  2
         dc.b  'RM'
         dc.w  REGISTER
         dc.b  5
         dc.b  'TRACE'
         dc.w  TRACE
         dc.b  1
         dc.b  '?'       ;initial command
         dc.w  HELP
         dc.b  5
         dc.b  'XBOOT'
         dc.w  BOOT
         dc.b  6
         dc.b  'VERIFY'
         dc.w  VERIFY
 ;        dc.b  4
 ;        dc.b  'BUEF'
 ;        dc.w  #BUEF_MSG
         dc.b  1         ;dummy command for load 
         dc.b  '~'
         dc.w  TILDE

         dc.b  -1
      


;*******************
;*** TEXT TABLES ***

MSG2:   dc.b   'Command not found'
        dc.b   EOT
MSG3:   dc.b   'Too Long'
        dc.b   EOT
MSG4:   dc.b   'Full'
        dc.b   EOT
MSG5:   dc.b   'Op- '
        dc.b   EOT
MSG6:   dc.b   'rom-'
        dc.b   EOT
MSG8:   dc.b   'Command?'
        dc.b   EOT
MSG9:   dc.b   'Bad argument'
        dc.b   EOT
MSG10:  dc.b   'No host port'
        dc.b   EOT
MSG11:  dc.b   'done'
        dc.b   EOT
MSG12:  dc.b   'chksum error'
        dc.b   EOT
MSG13:  dc.b   'error addr '
        dc.b   EOT
MSG14:  dc.b   'rcvr error'
        dc.b   EOT


HELPMSG1: EQU  *
         dc.b  'BUEFUSS Command Set:'
         dc.b  CR
         dc.b  'ASM [<addr>]  Line assembler/disassembler.'
         dc.b  CR
         dc.b  '    <CTRL-X>  Quit.                          ^        Do previous address.'
         dc.b  CR
         dc.b  '    <CTRL-J>  Do next address.           <RETURN>     Do next opcode.'
         dc.b  CR
         dc.b  '        /     Assemble current line & then dissassemble same address.'
         dc.b  CR
         dc.b  'BF <addr1> <addr2> [<data>]  Block fill (data defaults to $ff).'
         dc.b  CR
         dc.b  'BREAK [-][<addr>]  Set up breakpoint table (breakpoint uses SWI $3f).'
         dc.b  CR
         dc.b  'ERASE(ALL)         Erase the EEPROM (and CONFIG).'
         dc.b  CR
         dc.b  'EEMOD [<addr1> [<addr2>]]  Change EEPROM address range.'
         dc.b  CR
         dc.b  'CALL [<addr>]      Call user subroutine (defaults to user PC).'
         dc.b  CR
         dc.b  'GO [<addr>]        Execute user code (defaults to user PC).'
         dc.b  CR
         dc.b  'LOAD / VERIFY      Load or verify S-records.'
         dc.b  CR
         dc.b  'MD [<addr1> [<addr2>]]  Memory dump.'
         dc.b  CR
         dc.b  'MM [<addr>]        Memory modify.'
         dc.b  CR
         dc.b  '        /     Open same address.         <BS> or ^  Open previous address.'
         dc.b  CR
         dc.b  '    <CTRL-J>  Open next address.         <SPACE>   Open next address.'
         dc.b  CR
         dc.b  '    <RETURN>  Quit.                      <addr>O   Compute offset to <addr>.'
         dc.b  CR
         dc.b  'MOVE <s1> <s2> [<d>]  Block move (default d=s1+1).'
         dc.b  CR
         dc.b  'PROCEED       Proceed/continue execution after breakpoint.'
         dc.b  CR
         dc.b  'RM [<P>|<Y>|<X>|<A>|<B>|<C>|<S>]  Register modify.'
         dc.b  CR
         dc.b  'TRACE [<n>]   Trace n instructions starting at user PC (n<$ff, default n=1).'
         dc.b  CR
         dc.b  '<BS>   Backspace on screen (Erases last character typed).'
         dc.b  CR
         dc.b  'TM <SPACE> TheaterMaster command string <CR>'
         dc.b  4



;*** Error messages for assembler ***
MSGDIR: dc.w  MSGA1   ;message table index
        dc.w  MSGA2
        dc.w  MSGA3
        dc.w  MSGA4
        dc.w  MSGA5
        dc.w  MSGA6
        dc.w  MSGA7
        dc.w  MSGA8
        dc.w  MSGA9
MSGA1:  dc.b  'Immediate mode illegal'
        dc.b  EOT
MSGA2:  dc.b  'Error in mnemonic table'
        dc.b  EOT
MSGA3:  dc.b  'Illegal bit op'
        dc.b  EOT
MSGA4:  dc.b  'Bad argument'
        dc.b  EOT
MSGA5:  dc.b  'Mnemonic not found'
        dc.b  EOT
MSGA6:  dc.b  'Unknown addressing mode'
        dc.b  EOT
MSGA7:  dc.b  'Indexed addressing assumed'
        dc.b  EOT
MSGA8:  dc.b  'Syntax error'
        dc.b  EOT
MSGA9:  dc.b  'Branch out of range'
        dc.b  EOT

;*Mnemonic table for hc11 line assembler
NULL:   EQU  $0      ;nothing
INH:    EQU  $1      ;inherent
P2INH:  EQU  $2      ;page 2 inherent
GEN:    EQU  $3      ;general addressing
GRP2:   EQU  $4      ;group 2
REL:    EQU  $5      ;relative
IMM:    EQU  $6      ;immediate
NIMM:   EQU  $7      ;general except for immediate
LIMM:   EQU  $8      ;2 byte immediate
XLIMM:  EQU  $9      ;longimm for x
XNIMM:  EQU  $10     ;no immediate for x
YLIMM:  EQU  $11     ;longimm for y
YNIMM:  EQU  $12     ;no immediate for y
BTB:    EQU  $13     ;bit test and branch
SETCLR: EQU  $14     ;bit set or clear
CPD:    EQU  $15     ;compare d
BTBD:   EQU  $16     ;bit test and branch direct
SETCLRD: EQU  $17    ;bit set or clear direct

;**********
;*   mnetabl - includes all '11 mnemonics, base opcodes,
;* and type of instruction.  The assembler search routine
;*depends on 4 characters for each mnemonic so that 3 char
;*mnemonics are extended with a space and 5 char mnemonics
;*are truncated.
;**********

MNETABL: EQU  *
        dc.b  'ABA '             ;Mnemonic
        dc.b  $1B                ;Base opcode
        dc.b  INH                ;Class
        dc.b  'ABX '
        dc.b  $3A
        dc.b  INH
        dc.b  'ABY '
        dc.b  $3A
        dc.b  P2INH
        dc.b  'ADCA'
        dc.b  $89
        dc.b  GEN
        dc.b  'ADCB'
        dc.b  $C9
        dc.b  GEN
        dc.b  'ADDA'
        dc.b  $8B
        dc.b  GEN
        dc.b  'ADDB'
        dc.b  $CB
        dc.b  GEN
        dc.b  'ADDD'
        dc.b  $C3
        dc.b  LIMM
        dc.b  'ANDA'
        dc.b  $84
        dc.b  GEN
        dc.b  'ANDB'
        dc.b  $C4
        dc.b  GEN
        dc.b  'ASL '
        dc.b  $68
        dc.b  GRP2
        dc.b  'ASLA'
        dc.b  $48
        dc.b  INH
        dc.b  'ASLB'
        dc.b  $58
        dc.b  INH
        dc.b  'ASLD'
        dc.b  $05
        dc.b  INH
        dc.b  'ASR '
        dc.b  $67
        dc.b  GRP2
        dc.b  'ASRA'
        dc.b  $47
        dc.b  INH
        dc.b  'ASRB'
        dc.b  $57
        dc.b  INH
        dc.b  'BCC '
        dc.b  $24
        dc.b  REL
        dc.b  'BCLR'
        dc.b  $1D
        dc.b  SETCLR
        dc.b  'BCS '
        dc.b  $25
        dc.b  REL
        dc.b  'BEQ '
        dc.b  $27
        dc.b  REL
        dc.b  'BGE '
        dc.b  $2C
        dc.b  REL
        dc.b  'BGT '
        dc.b  $2E
        dc.b  REL
        dc.b  'BHI '
        dc.b  $22
        dc.b  REL
        dc.b  'BHS '
        dc.b  $24
        dc.b  REL
        dc.b  'BITA'
        dc.b  $85
        dc.b  GEN
        dc.b  'BITB'
        dc.b  $C5
        dc.b  GEN
        dc.b  'BLE '
        dc.b  $2F
        dc.b  REL
        dc.b  'BLO '
        dc.b  $25
        dc.b  REL
        dc.b  'BLS '
        dc.b  $23
        dc.b  REL
        dc.b  'BLT '
        dc.b  $2D
        dc.b  REL
        dc.b  'BMI '
        dc.b  $2B
        dc.b  REL
        dc.b  'BNE '
        dc.b  $26
        dc.b  REL
        dc.b  'BPL '
        dc.b  $2A
        dc.b  REL
        dc.b  'BRA '
        dc.b  $20
        dc.b  REL
        dc.b  'BRCL'      ;(BRCLR)
        dc.b  $1F
        dc.b  BTB
        dc.b  'BRN '
        dc.b  $21
        dc.b  REL
        dc.b  'BRSE'      ;(BRSET)
        dc.b  $1E
        dc.b  BTB
        dc.b  'BSET'
        dc.b  $1C
        dc.b  SETCLR
        dc.b  'BSR '
        dc.b  $8D
        dc.b  REL
        dc.b  'BVC '
        dc.b  $28
        dc.b  REL
        dc.b  'BVS '
        dc.b  $29
        dc.b  REL
        dc.b  'CBA '
        dc.b  $11
        dc.b  INH
        dc.b  'CLC '
        dc.b  $0C
        dc.b  INH
        dc.b  'CLI '
        dc.b  $0E
        dc.b  INH
        dc.b  'CLR '
        dc.b  $6F
        dc.b  GRP2
        dc.b  'CLRA'
        dc.b  $4F
        dc.b  INH
        dc.b  'CLRB'
        dc.b  $5F
        dc.b  INH
        dc.b  'CLV '
        dc.b  $0A
        dc.b  INH
        dc.b  'CMPA'
        dc.b  $81
        dc.b  GEN
        dc.b  'CMPB'
        dc.b  $C1
        dc.b  GEN
        dc.b  'COM '
        dc.b  $63
        dc.b  GRP2
        dc.b  'COMA'
        dc.b  $43
        dc.b  INH
        dc.b  'COMB'
        dc.b  $53
        dc.b  INH
        dc.b  'CPD '
        dc.b  $83
        dc.b  CPD
        dc.b  'CPX '
        dc.b  $8C
        dc.b  XLIMM
        dc.b  'CPY '
        dc.b  $8C
        dc.b  YLIMM
        dc.b  'DAA '
        dc.b  $19
        dc.b  INH
        dc.b  'DEC '
        dc.b  $6A
        dc.b  GRP2
        dc.b  'DECA'
        dc.b  $4A
        dc.b  INH
        dc.b  'DECB'
        dc.b  $5A
        dc.b  INH
        dc.b  'DES '
        dc.b  $34
        dc.b  INH
        dc.b  'DEX '
        dc.b  $09
        dc.b  INH
        dc.b  'DEY '
        dc.b  $09
        dc.b  P2INH
        dc.b  'EORA'
        dc.b  $88
        dc.b  GEN
        dc.b  'EORB'
        dc.b  $C8
        dc.b  GEN
        dc.b  'FDIV'
        dc.b  $03
        dc.b  INH
        dc.b  'IDIV'
        dc.b  $02
        dc.b  INH
        dc.b  'INC '
        dc.b  $6C
        dc.b  GRP2
        dc.b  'INCA'
        dc.b  $4C
        dc.b  INH
        dc.b  'INCB'
        dc.b  $5C
        dc.b  INH
        dc.b  'INS '
        dc.b  $31
        dc.b  INH
        dc.b  'INX '
        dc.b  $08
        dc.b  INH
        dc.b  'INY '
        dc.b  $08
        dc.b  P2INH
        dc.b  'JMP '
        dc.b  $6E
        dc.b  GRP2
        dc.b  'JSR '
        dc.b  $8D
        dc.b  NIMM
        dc.b  'LDAA'
        dc.b  $86
        dc.b  GEN
        dc.b  'LDAB'
        dc.b  $C6
        dc.b  GEN
        dc.b  'LDD '
        dc.b  $CC
        dc.b  LIMM
        dc.b  'LDS '
        dc.b  $8E
        dc.b  LIMM
        dc.b  'LDX '
        dc.b  $CE
        dc.b  XLIMM
        dc.b  'LDY '
        dc.b  $CE
        dc.b  YLIMM
        dc.b  'LSL '
        dc.b  $68
        dc.b  GRP2
        dc.b  'LSLA'
        dc.b  $48
        dc.b  INH
        dc.b  'LSLB'
        dc.b  $58
        dc.b  INH
        dc.b  'LSLD'
        dc.b  $05
        dc.b  INH
        dc.b  'LSR '
        dc.b  $64
        dc.b  GRP2
        dc.b  'LSRA'
        dc.b  $44
        dc.b  INH
        dc.b  'LSRB'
        dc.b  $54
        dc.b  INH
        dc.b  'LSRD'
        dc.b  $04
        dc.b  INH
        dc.b  'MUL '
        dc.b  $3D
        dc.b  INH
        dc.b  'NEG '
        dc.b  $60
        dc.b  GRP2
        dc.b  'NEGA'
        dc.b  $40
        dc.b  INH
        dc.b  'NEGB'
        dc.b  $50
        dc.b  INH
        dc.b  'NOP '
        dc.b  $01
        dc.b  INH
        dc.b  'ORAA'
        dc.b  $8A
        dc.b  GEN
        dc.b  'ORAB'
        dc.b  $CA
        dc.b  GEN
        dc.b  'PSHA'
        dc.b  $36
        dc.b  INH
        dc.b  'PSHB'
        dc.b  $37
        dc.b  INH
        dc.b  'PSHX'
        dc.b  $3C
        dc.b  INH
        dc.b  'PSHY'
        dc.b  $3C
        dc.b  P2INH
        dc.b  'PULA'
        dc.b  $32
        dc.b  INH
        dc.b  'PULB'
        dc.b  $33
        dc.b  INH
        dc.b  'PULX'
        dc.b  $38
        dc.b  INH
        dc.b  'PULY'
        dc.b  $38
        dc.b  P2INH
        dc.b  'ROL '
        dc.b  $69
        dc.b  GRP2
        dc.b  'ROLA'
        dc.b  $49
        dc.b  INH
        dc.b  'ROLB'
        dc.b  $59
        dc.b  INH
        dc.b  'ROR '
        dc.b  $66
        dc.b  GRP2
        dc.b  'RORA'
        dc.b  $46
        dc.b  INH
        dc.b  'RORB'
        dc.b  $56
        dc.b  INH
        dc.b  'RTI '
        dc.b  $3B
        dc.b  INH
        dc.b  'RTS '
        dc.b  $39
        dc.b  INH
        dc.b  'SBA '
        dc.b  $10
        dc.b  INH
        dc.b  'SBCA'
        dc.b  $82
        dc.b  GEN
        dc.b  'SBCB'
        dc.b  $C2
        dc.b  GEN
        dc.b  'SEC '
        dc.b  $0D
        dc.b  INH
        dc.b  'SEI '
        dc.b  $0F
        dc.b  INH
        dc.b  'SEV '
        dc.b  $0B
        dc.b  INH
        dc.b  'STAA'
        dc.b  $87
        dc.b  NIMM
        dc.b  'STAB'
        dc.b  $C7
        dc.b  NIMM
        dc.b  'STD '
        dc.b  $CD
        dc.b  NIMM
        dc.b  'STOP'
        dc.b  $CF
        dc.b  INH
        dc.b  'STS '
        dc.b  $8F
        dc.b  NIMM
        dc.b  'STX '
        dc.b  $CF
        dc.b  XNIMM
        dc.b  'STY '
        dc.b  $CF
        dc.b  YNIMM
        dc.b  'SUBA'
        dc.b  $80
        dc.b  GEN
        dc.b  'SUBB'
        dc.b  $C0
        dc.b  GEN
        dc.b  'SUBD'
        dc.b  $83
        dc.b  LIMM
        dc.b  'SWI '
        dc.b  $3F
        dc.b  INH
        dc.b  'TAB '
        dc.b  $16
        dc.b  INH
        dc.b  'TAP '
        dc.b  $06
        dc.b  INH
        dc.b  'TBA '
        dc.b  $17
        dc.b  INH
        dc.b  'TPA '
        dc.b  $07
        dc.b  INH
        dc.b  'TEST'
        dc.b  $00
        dc.b  INH
        dc.b  'TST '
        dc.b  $6D
        dc.b  GRP2
        dc.b  'TSTA'
        dc.b  $4D
        dc.b  INH
        dc.b  'TSTB'
        dc.b  $5D
        dc.b  INH
        dc.b  'TSX '
        dc.b  $30
        dc.b  INH
        dc.b  'TSY '
        dc.b  $30
        dc.b  P2INH
        dc.b  'TXS '
        dc.b  $35
        dc.b  INH
        dc.b  'TYS '
        dc.b  $35
        dc.b  P2INH
        dc.b  'WAI '
        dc.b  $3E
        dc.b  INH
        dc.b  'XGDX'
        dc.b  $8F
        dc.b  INH
        dc.b  'XGDY'
        dc.b  $8F
        dc.b  P2INH
        dc.b  'BRSE'       ;bit direct modes for
        dc.b  $12          ; disassembler.
        dc.b  BTBD
        dc.b  'BRCL'
        dc.b  $13
        dc.b  BTBD
        dc.b  'BSET'
        dc.b  $14
        dc.b  SETCLRD
        dc.b  'BCLR'
        dc.b  $15
        dc.b  SETCLRD
        dc.b  EOT          ;End of table



        end
