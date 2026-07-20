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
;   LCD_ctl.s 
;
;****************************************
;*
;*  LCD Control Routines source file
;*
;*
;* Summary of subroutines:
;*
;*    screen_position      A=position (0-39)
;*    Section_clear        A=start position (0-39), B=end position (0-39), A < B
;*    LCD_config           Configure the LCD/VFD mode.
;*    LCD_init             Initialize display manager and clears screen.
;*    LCD_init0            Initialize display manager only.
;*    start_blinking       Uses blink positions in 'blink_posns'
;*    SCREENS              A=position (0-39), Y=pointer to formatted string.
;*    screen_out           Y=pointer to formatted 40-character string.
;*                         (Note: screen_out calls SCREENS twice, and also LCD_init.)
;*
;*    VFD_bright_driver    A=VFD brightness (0-3, i.e.,100% to 25%)
;*
;*
;* Error characters:
;*
;*    *   ---   CGRAM overload (more than 8 custom characters)
;*    #   ---   Custom character not found.
;*    @   ---   Font not found.
;*
;*
;****************************************

        CLIST OFF       ;Only list assembled conditonals.
        MLIST OFF       ;Don't expand macros.


lcdctl_flag:   equ     0


        XDEF    LCD_init,screen_position,Section_clear,start_blinking
        XDEF    blinking,SCREENS,screen_out,clear_CC,blink_posns
        XDEF    screen_image,blink_on_off
        XDEF    VFD_bright_driver,LCD_config,LCD_init0


        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


LCD_vbls:       Section 34


screen_image:   ds.b     40
CC_table_char:  ds.b     16
CC_table_num:   ds.b     8


blink_cycle:    ds.b     1       ;Number of cycles of 16.4ms for blink rate
blink_on_off:   ds.b     1       ;Indicates if blink on or off
blink_posns:    ds.b     12      ;6 blink field positions



LCD_ctl:        Section 4


;***************************************************************
;* Position Setter 
;*
;* Converts (0-39) on screen in A to screen position
;* (preserves all registers)
;*
;***
screen_position:
        psha
        cmpa    #$13
        bls     top_line
        adda    #$2c                   ;convert positions 20-39
top_line:
        oraa    #%10000000             ;convert to LCD protocol  
        jsr     LCD0_write             ;move to screen position
        pula
        rts



;***************************************************************
;* Section clear.
;*
;* Writes spaces to the screen section specified by A and B.
;* Register A = start position (0-39) and register B = end
;* position (0-39).
;*
;***
Section_clear:
        psha
        pshb
        ldy     #spaces
        jsr     SCREENS                ;Write a space
        pulb
        pula
        cba                            ;Check if at end of section
        beq     end_clear
        inca
        bra     Section_clear
end_clear:
        rts


;***************************************************************
;* Configure the LCD/VFD display
;*
;* LCD: To ensure correct initialization despite slow power supply
;*      risetime, the %00110000 initialization code is sent 3 times.
;*
;* VFD: Some difficulties getting the Noritake VFD to start, and
;*      not hang-up the 68HC11F1 during its own initialization.
;*      This problem is worse in the Encore than the Signature.
;*      It has been reduced with a capacitor (50 pF in parallel
;*      with the VFD E strobe).
;*

Mode:   dc.b     %00111000              ;Set 8-bit i/f; 2 lines; 5x7 dots

        dc.b     %00000000              ;Set VFD 100% brightness

        dc.b     %00001000              ;Display OFF, no cursor, no blinking.
        dc.b     %00000001              ;Clear display & home cursor.
        dc.b     %00000110              ;Set entry mode to increment & no shift.
        dc.b     %00001100              ;Display ON, cursor OFF, blinking OFF.
        dc.b     $ff                    ;Table end marker.
;*
;*
;***
LCD_config:
        pshy
        psha

        delay   260*10                 ;Wait 260 ms for VFD/LCD to do internal init.
        ldaa    #%00111000             ;Set 8-bit i/f
        jsr     LCD0_jam               ;Jam control word into VFD.
        delay   5*10                   ;Wait 5 ms  (should be > 4.1 ms)
        ldaa    #%00111000             ;Set 8-bit i/f
        jsr     LCD0_jam               ;Jam control word into VFD.
        delay   1*10                   ;Wait 1 ms  (should be > 100 us)

;* 2nd part of routine loads the above table:

        ldy     #Mode                  ;Mode data table.
Mod_lp: ldaa    0,y                    ;Get data
        cmpa    #$ff
        beq     M_out
        jsr     LCD0_write             ;write to LCD.
        iny                            ;get next data byte.
        bra     Mod_lp                 

M_out:  pula
        puly
        rts


;***************************************************************
;* Initialize the LCD/VFD display image, etc.
;*
;*LCD_init0:
;* Initializes the screen image, but does not clear the screen.
;*
;*LCD_init:
;* Initializes the screen image and the screen.
;*
;***
LCD_init0:
        pshy
        psha
        bra     .no_clr

LCD_init:
        pshy
        psha

        ldaa    #%00000001
        jsr     LCD0_write             ;Clear LCD/VFD.
.no_clr:
        ldab    #39
clr_image:                             ;Clear RAM image of LCD/VFD..
        ldy     #screen_image
        aby
        ldaa    #$20
        staa    0,y
        decb
        bge     clr_image

        clrb
clear_table:                           ;Clear custom characters table.
        ldy     #CC_table_num
        aby
        clr     0,y
        ldy     #CC_table_char
        aby
        aby
        clr     0,y
        clr     1,y
        incb
        cmpb    #8
        bne     clear_table

        ldaa    #$ff                   ;Clear all blink positions
        ldy     #blink_posns
        staa    0,y
        staa    2,y
        staa    4,y
        staa    6,y
        staa    8,y
        staa    10,y
        jsr     start_blinking         ;Initialize timers and flags for blinking

        pula
        puly
        rts


;***************************************************************
;* Read CG/DDRAM contents into A.
;* All regs except A preserved.
;*
;***
LCD1_read:
        pshx
        ldx     #regbase
        jsr     Busy                   ;BF (Busy Flag) check.
        ldaa    $61,x
        pulx
        rts


;***************************************************************
;* Write control word to LCD register 0 from register A.
;* Preserves all regs.
;*
;***
LCD0_write:
        pshx
        ldx     #regbase
        jsr     Busy                   ;BF (Busy Flag) check.
        staa    $60,x
        pulx
        rts


;***************************************************************
;* Write control word to LCD register 0 from register A.
;* Busy flag is not referenced, so caller must use delay.
;* Preserves all regs.
;*
;***
LCD0_jam:  
        pshx
        ldx     #regbase
;ajr     jsr     Busy                   ;BF (Busy Flag) check.
        staa    $60,x
        pulx
        rts


;***************************************************************
;* Write data word to LCD register 1 from register A           
;* Preserves all regs.
;*
;***
LCD1_write:
        pshx
        ldx     #regbase
        jsr     Busy                   ;BF (Busy Flag) check.
        staa    $61,x
        pulx
        rts


;***************************************************************
;* Wait until the LCD is ready (i.e., loop until BF = 0).
;* Preserves all regs.
;*
;***
Busy:   psha
BFloop: ldaa    $60,x
        bmi     BFloop      
        pula
        rts



;**************************************************************
;*          B L I N K I N G   C H A R A C T E R S
;**************************************************************
;*
;* Blinking characters routines:
;* Called by OC1,5 so that blinking does not disturb brightness
;*
;* Destroys A,B,Y
;*
;***
start_blinking:
        ldaa    #1
        staa    blink_on_off           ;Flag 'characters on'
        ldaa    #40
        staa    blink_cycle            ;Set blinking cycle counter
        bset    mute_status,#$80       ;Start blinks from 'ON'
        clr     mute_cntr              ;and flag no update until blink counter
                                       ;expires
        rts


blinking:
        dec     blink_cycle
        bne     end_blink              ;Check if number of cycles have passed
        ldaa    #40     
        staa    blink_cycle            ;Restore number of cycles

        ldaa    mute_status
        eora    #$80                   ;Flip-flop MSB for daisy flashing
        staa    mute_status
        ldaa    #$ff                   ;Flag changes having occurred
        staa    mute_cntr               

        clrb                           ;Clear counter
blink_loop1:
        pshb
        ldy     #blink_posns           ;Pointer to blink positions
        aby                            ;Update pointer
        ldaa    0,y                    ;Get blink field start information
        cmpa    #$ff                   ;Check for 'no-blink' flag
        beq     blink_loop_again

        ldab    blink_on_off
        bne     blink_off              ;Check if characters are on or off               


blink_on:
        jsr     screen_position        ;Move to start point
unclear_loop:
        psha                           ;Save start position info
        ldx     #screen_image
        tab
        abx
        ldaa    0,x                    ;Get character from screen image
        jsr     LCD1_write             ;Display character
        pula
        cmpa    1,y                    ;Check if at end of section
        beq     blink_loop_again
        inca                           ;Go to next position
        bra     unclear_loop



blink_off:
        jsr     screen_position        ;Go to start position
clear_loop:
        psha
        ldaa    #$20                   ;Write spaces to the screen
        jsr     LCD1_write
        pula
        cmpa    1,y                    ;Check if at end of section
        beq     blink_loop_again
        inca                           ;Next position
        bra     clear_loop


blink_loop_again:
        pulb
        incb
        incb
        cmpb    #10                    ;See if 6 done
        bls     blink_loop1

        ldaa    blink_on_off
        eora    #1
        staa    blink_on_off           ;Update blink for next time
end_blink:
        rts



;************************************************************************
;*
;*  SCREEN MANAGER
;*
;*  This routine loads relevant custom characters and displays a string.
;*  The N-character string must end with a '|' marker followed by N
;*  spaces or font characters.
;*
;*  Example string:
;*                      'Large LCD display|'
;*                      '   L  RRR    L  L'
;*
;*  There can be up to 40 display characters before the '|' character,
;*  with the corresponding font characters following, which is convenient
;*  when consntructing a display string on the fly (e.g., the VU meter):
;* 
;*             'This very long string takes two lines!|'
;*             '        L    L      L                 '
;*
;*  Error messages:  '*'  CGRAM overflow! (maximum custom chars = 8)
;*                   '@'  Font not found!
;*                   '#'  Custom character not found in font!
;*
;*  Use as:      ldaa  #screen_posn (0-39)
;*               ldy   #string_ptr
;*               jsr   SCREENS
;*
;***

SCREENS:

;* Local variables allocated on the stack:
chars_ptr:      equ     0             ;Pointer to screen-data string
attrb_ptr:      equ     2             ;Pointer into attributes line
CC_id:          equ     4             ;Custom Char identifier (e.g. 'gL')
font_beg:       equ     6             ;Font beginning pointer
font_end:       equ     8             ;Font end pointer

len:            equ     10            ;String length
len2:           equ     11            ;String length copy
CC_space:       equ     12            ;Character number (0-7)
CGRAM:          equ     13            ;CGRAM pointer
curr_posn:      equ     14            ;Current position on screen
end_posn:       equ     15            ;String end position on screen
start_posn:     equ     16            ;String start position on screen
        
        pshx
        pshy
        tsx
        psha                           ;Save screen start position
        xgdx
        subd    #17                    ;Reserve stack space
        xgdx
        txs                            ;x points to local variables

        sty     chars_ptr,x            ;Store screen data pointer


;* Determine length of string to be output and set positions

        ldaa    start_posn,x           ;Get screen start position.
        staa    curr_posn,x            ;Initialize current position
        staa    end_posn,x             ; and end position
        clr     len,x
        clr     len2,x
string_len:
        inc     len,x                  ;Increment length of string
        inc     len2,x
        inc     end_posn,x             ;Increment end position
        iny                            ;Get new data
        ldaa    0,y
        cmpa    #'|'                   ;Check for end of string character
        bne     string_len

        ldaa    start_posn,x
        jsr     screen_position        ;Go to correct place on screen

;* Scan the section of the screen to be written over
;*   for custom characters and modify CC_table.

scan_image:
        ldy     #screen_image          ;Pointer into screen image
        ldab    start_posn,x
        aby                            ;Add start position
        ldab    len2,x
        decb
        aby                            ;Go to end of string
        ldab    0,y                    ;Get screen image character
        cmpb    #8
        blo     CC_table_update        ;Custom character?
inc_image_ptrs:
        dec     len2,x                 ;Update pointer
        bne     scan_image             ;Check if all done
        bra     write_string

CC_table_update:
        ldy     #CC_table_num          ;Point into CC occurrences
        aby                              
        dec     0,y                    ;Decrement occurrences
        bra     inc_image_ptrs

write_string:
        ldy     chars_ptr,x
        ldab    len,x
        incb
        aby
        sty     attrb_ptr,x            ;Set pointer into attributes line

write_loop:
        ldy     attrb_ptr,x            ;Get attribute in B
        ldab    0,y
        ldy     chars_ptr,x            ;Get character in A
        ldaa    0,y

        cmpa    #'|'                   ;Check for end of string
        beq     end_of_string
        cmpb    #$20                   ;Check if custom or not
        bne     do_custom
write_char:
        staa    CC_space,x             ;Save character

        pshx
        ldx     #regbase
        bclr    tmsk1,x,#%10001000     ;Disable OC1,OC5 interrupts
                                       ;while output is going on to avoid blink
                                       ;conflicts
        pulx

        ldaa    curr_posn,x            ;Go to correct position
        jsr     screen_position
       
        ldaa    CC_space,x             ;Retrieve character
        jsr     LCD1_write             ;Output character to screen

        pshx
        ldx     #regbase
        bset    tmsk1,x,#%10001000     ;re-enable OC1,OC5 interrupts
        pulx

        ldy     #screen_image          ;Update screen image
        ldab    curr_posn,x
        aby
        staa    0,y

inc_screen_ptrs:
        ldy     attrb_ptr,x
        iny
        sty     attrb_ptr,x
        ldy     chars_ptr,x
        iny
        sty     chars_ptr,x        
        inc     curr_posn,x
        bra     write_loop

end_of_string:
        jmp     SCREENS_end

;* Load in custom characters to CGRAM, update CC_table
;*   and output custom character to screen.

do_custom:
        std     CC_id,x                ;Save custom character identifier
        clr     CC_space,x             ;Clear character number

;* Find location in CC_table (either a repeated char or a space):
char_table_loop:
        ldy     #CC_table_char
        ldab    CC_space,x
        aby
        aby
        ldd     0,y                    ;Get table identifier
        cpd     CC_id,x                ;Compare to current character
        beq     identify_font
        inc     CC_space,x             ;Next character space
        ldaa    CC_space,x
        cmpa    #8                     ;Check for end of table
        bne     char_table_loop

        clr     CC_space,x             ;Clear character number
num_table_loop:
        ldy     #CC_table_num
        ldab    CC_space,x
        aby                            ;Update to next slot in table
        ldaa    0,y
        beq     load_table
        inc     CC_space,x             ;Next character
        ldaa    CC_space,x
        cmpa    #8                     ;Check if at end of table
        bne     num_table_loop
                
        ldaa    #'*'                   ;!!!!! No more space for CCs !!!!!
        jmp     write_char             ;      (output a '*')

load_table:
        ldy     #CC_table_char         ;Set pointer into table
        ldab    CC_space,x
        aby
        aby
        ldd     CC_id,x
        std     0,y                    ;Store identifier


;* Font identification:
identify_font:
        ldy     #font_pointers
        ldd     CC_id,x

find_font:
        ldaa    0,y                    ;Get first font pointer
        cba                            ;Compare to CC identifier
        beq     font_ptr
        iny                            ;Update to next font pointer
        iny
        iny
        iny
        iny                             
        cpy     #fonts_end
        bne     find_font

        ldaa    #'@'                   ;!!!!! Font not found !!!!!
        jmp     write_char             ;      (output a '@')

font_ptr:
        ldd     3,y
        std     font_end,x             ;Save font_end pointer
        ldy     1,y
        sty     font_beg,x             ;Save font_beginning pointer

;* Custom character identification:
identify_CC:
        ldaa    0,y                    ;Check character
        cmpa    CC_id,x                ;Compare to custom identifier
        beq     load_CC
        ldab    #9
        aby
        cpy     font_end,x
        bne     identify_CC

        ldaa    #'#'                   ;!!!!! Custom Char not found !!!!!
        jmp     write_char             ;          (output a '#')


;* Custom Character loading:

load_CC:
        iny                            ;Put pointer into CC bit list
        ldaa    CC_space,x             ;Get character number (0-7)
        lsla
        lsla
        lsla
        oraa    #%01000000                      
        staa    CGRAM,x                ;Convert character number to CGRAM #

        ldab    #8                     ;8 bits counter
CC_write_loop:
        ldaa    CGRAM,x                ;Set write mode to CGRAM positions
        jsr     LCD0_write              
        ldaa    0,y                    ;Write data to CGRAM
        jsr     LCD1_write
        iny                            ;Update CC bit pointer
        inc     CGRAM,x                ;Update CGRAM pointer
        decb
        bne     CC_write_loop

        ldaa    curr_posn,x            ;Go to correct screen position
        jsr     screen_position


        ldy     #CC_table_num
        ldab    CC_space,x
        aby
        inc     0,y                    ;Update CC_table

        ldaa    CC_space,x             ;Output character
        jmp     write_char


SCREENS_end:
        tsx
        xgdx
        addd    #17                    ;Restore stack
        xgdx
        txs

        puly
        pulx
        rts


;************************************************************************
;* Clearing of Custom character table - use with care!!!!
;* SCREENS takes care of this, but you can get into problems when
;* updating only part of the screen at a time
;***
clear_CC:
        ldab    #8
        clra
        ldy     #CC_table_num           ;Only need to clear occurrences table
clear_CC_loop:
        staa    0,y
        iny
        decb
        bne     clear_CC_loop
        rts


;************************************************************************
;*
;* General purpose LCD screen output routine
;* This routine is normally used to load 40 characters to the screen.
;* Enter with y pointing to the screen string.
;*
;*  Example string:
;*                      'A bright VFD display|'
;*                      '     L   BBB    L  L'
;*                      'is very easy to read|'
;*                      '      L    L        '
;*                       
;*  Due to the formatting information, it takes 40 + 42 = 82 bytes
;*   to fully define the 40-character display string.
;*
;*  Error messages:  '*'  CGRAM overflow! (maximum custom chars = 8)
;*                   '@'  Font not found!
;*                   '#'  Custom character not found in font!
;*
;*  Use as:      ldy   #string_ptr
;*               jsr   screen_out
;*
;***
screen_out:
        jsr     LCD_init
        clra
        jsr     SCREENS
        ldab    #41
        aby
        ldaa    #20
        jsr     SCREENS
        rts


;************************************************************************
;*
;* Load 2-bit brightness level in A into the VFD
;*
;* Brightness value is 3 (25%), 2 (50%), 1 (75%), 0 (100%)
;*
;***
VFD_bright_driver:
        anda    #%00000011              ;Mask values > 3.
        psha
        ldaa    #%00111000              ;Function Set (8-bit i/f) Last bit is for LCD compatibilty.
        jsr     LCD0_write              ;Write to LCD.
        pula
        anda    #%00000011              ;Mask brightness value.
        jsr     LCD1_write
        rts

        end

