

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
         dc.b  '    /         Do same address.           ^            Do previous address.'
         dc.b  CR
         dc.b  '    CTRL-J    Do next address.           RETURN       Do next opcode.'
         dc.b  CR
         dc.b  '    CTRL-A    Quit.'
         dc.b  CR
         dc.b  'BF <addr1> <addr2> [<data>]  Block fill (data defaults to $ff).'
         dc.b  CR
         dc.b  'BREAK [-][<addr>]  Set up breakpoint table (breakpoint uses SWI $3f).'
         dc.b  CR
         dc.b  'ERASE(ALL)         Erase the EEPROM (and CONFIG).'
         dc.b  CR
         dc.b  'EEMOD [<addr1> [<addr2>]]  Change EEPROM address range.'
         dc.b  CR
         dc.b  'CALL [<addr>]      Call user subroutine (defaults to user pc).'
         dc.b  CR
         dc.b  'GO [<addr>]        Execute user code (defaults to user pc).'
         dc.b  CR
         dc.b  'LOAD / VERIFY      Load or verify S-records.'
         dc.b  CR
         dc.b  'MD [<addr1> [<addr2>]]  Memory dump.'
         dc.b  CR
         dc.b  'MM [<addr>]        Memory modify.'
         dc.b  CR
         dc.b  '    /         Open same address.        CTRL-H or ^   Open previous address.'
         dc.b  CR
         dc.b  '    CTRL-J    Open next address.        SPACE         Open next address.'
         dc.b  CR
         dc.b  '    RETURN    Quit.                     <addr>O       Compute offset to <addr>.'
         dc.b  CR
         dc.b  'MOVE <s1> <s2> [<d>]  Block move (default d=s1+1).'
         dc.b  CR
         dc.b  'PROCEED       Proceed/continue execution after breakpoint.'
         dc.b  CR
         dc.b  'RM [<P>|<Y>|<X>|<A>|<B>|<C>|<S>]  Register modify.'
         dc.b  CR
         dc.b  'TRACE [<n>]   Trace n instructions starting at user pc (n<$ff, default n=1).'
         dc.b  CR
         dc.b  'CTRL-H    Backspace.          CTRL-X    Abort/cancel command.'
         dc.b  CR
         dc.b  'TM <sp> Sequence of TheaterMaster command characters <cr>'
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
SETCLRD: EQU  $17    ; bit set or clear direct

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
        dc.b  'ABX'
        dc.b  $3A
        dc.b  INH
        dc.b  'ABY'
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

