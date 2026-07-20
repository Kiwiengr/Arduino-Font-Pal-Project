;************************************************************************
;*
;* SwitchMaster Downloader
;*
;****



        CLIST OFF       ;Only list assembled conditonals.
        MLIST OFF       ;Don't expand macros.


sm_dl_flag:    equ     0


        XDEF   downloader


        include "c:\1work\eos-i\xrefs.i"
        include "c:\1work\eos-i\equates.i"
        include "c:\1work\eos-i\macros.i"


sm_vbls:       Section 85

        

dl_posn:        ds.b    1               ;Blocks pointer 
old_ctr:        ds.b    1               ;4 line counter for old code

;****************************************************************

sm_down:       Section 86

;****************************************************************

downloader:
        ldaa    #20
        staa    dl_posn                 ;Set indicator start position

        jsr     LCD_init

        delay   300*10

        ldy     #SM_down_screen_1       ;Put up announcement screen
        jsr     screen_out

        delay   2500*10                 ;for 2 seconds

        ldy     #SM_down_screen_2
        jsr     screen_out

        clr     IR_ready

dl_loop1:
        ldaa    IR_ready                ;Check for Front panel or IR push
        adda    IRQ_flag                
        beq     dl_loop1


        ldy     #downloading            ;Show downloading screen
        jsr     screen_out

        sei                             ;Disable all interrupts


;* Configure SCI to correct baud

        ldx     #regbase

        ldaa    #%00110011              ;Set SCI baud to 1200
        staa    baud,x
                                        ;Enable RS232 Tx,Rx
        ldaa    #%00001100
        staa    sccr2,x



;****************************************************************
;* First download the CPU S-record loader
;*
;****************************************************************

        ldy     #Loader                 ;Point to loader data
dl_loader_loop:
        ldaa    0,y
        jsr     dl_out                  ;Send out a byte

        iny
        cpy     #End_of_Loader          ;Check for end of data block
        bne     dl_loader_loop  

        delay   500*10                  ;Essential delay!!!

        ldaa    #'~'                    ;Displays '->'
        jsr     print

;****************************************************************
;* At this point, the CPU downloader has been set up...we can now
;* check if it is responding...
;****************************************************************
dl_code:
        ldx     #regbase

        ldaa    #%00110000              ;Set SCI baud to 9600
        staa    baud,x
                                        
        ldaa    #%00001100              ;Enable RS232 Tx,Rx
        staa    sccr2,x

        ldaa    scdr,x                  ;Flush SCI buffer

        clrb                            ;Number of errors in start-up
dl_check_if_ok:
        pshb

        delay   500*10

        ldaa    #$0d                    ;Send out CR
        jsr     dl_out

        pulb

        ldaa    #'I'                    ;Send out I
        jsr     dl_out

        bra     dl_code_in


;******************************************************************
;* It is responding ok, so now download the code
;*
;******************************************************************
dl_code_in:
        ldaa    #'~'                    ;Displays one more '->'
        jsr     print

        delay   500*10

        
        ldy     #box_line_old           ;Put up a line of empty boxes

        brclr   DIP_imag,#%11111111,dl_in_1   ;Check for old download

        ldy     #box_line               ;Empty boxes for new code
dl_in_1:
        ldaa    #20
        jsr     SCREENS

        ldaa    #20                     ;Restart indicator position
        staa    dl_posn
        clr     old_ctr                 ;Clear 4 line counter for old code

        ldy     #SM_OLD                 ;Point to code (old)

        brclr   DIP_imag,#%11111111,sm_contd   ;All DIP SW's ON to load old code.

        ldy     #SM1                    ;Point to new code
sm_contd:
        ldx     #regbase

dl_code_loop:
        ldaa    0,y
        jsr     dl_out                  ;Send out character

        delay   8*10                    ;Small delay

        ldaa    1,y
        jsr     dl_out                  ;Send out character

        delay   30*10                   ;Long delay for EEPROM burn

        ldaa    0,y
        cmpa    #'S'
        bne     dl_code_1

        brclr   DIP_imag,#%11111111,dl_code_0

        ldaa    #'?'                    ;Show a block for each line of S-records
        jsr     print                   ;for new code
        bra     dl_code_1

dl_code_0:
        inc     old_ctr                 ;Old code has one block for 4 lines
        ldaa    old_ctr
        cmpa    #4
        blo     dl_code_1
        ldaa    #'?'                    ;Show a block for 4 line of S-records
        jsr     print                   ;for old code
        clr     old_ctr

dl_code_1:
        iny
        iny

        brclr   DIP_imag,#%11111111,old_SM

        cpy     #End_of_SM1             ;Check for end of new data block.
        bne     dl_code_loop    
        bra     dl_success

old_SM: cpy     #End_of_SM_OLD          ;Check for end of old data block.
        bne     dl_code_loop



;******************************************************************
;* Check for number of errors
;******************************************************************


dl_success:
        ldy     #SM_dl_ok_1
        jsr     screen_out

        delay   2500*10

        ldy     #SM_dl_ok_2
        jsr     screen_out
        jmp     dl_forever

dl_errors:
        ldy     #dl_breakdown_1         ;Show error screens
        jsr     screen_out

        delay   3000*10

        ldy     #dl_breakdown_2
        jsr     screen_out
        jmp     dl_forever

timed_out_msg:
        ldy     #dl_timed_out   
        jsr     screen_out
        jmp     dl_forever

dl_forever:
        bra     *               ;Run around forever (to force power down)
        rts


;* Character transmit

dl_out:
        ldx     #regbase
        brclr   scsr,x,#%10000000,*
        staa    scdr,x
        rts


;*Timed reception routine...waits for a character for 1/2s before timing out

timed_rx:
        pshy
        ldy     #0
        ldx     #regbase
timed_1:
        brset   scsr,x,#%00100000,timed_ok      ;If character received, get it
        nop
        iny                                     ;Otherwise, increment timer

        cpy     #$c300                          ;About 500ms (21 cycles/loop)
        bls     timed_1
        puly
        jmp     timed_out_msg                   ;Timed out! Show message

timed_ok:
        ldaa    scdr,x                          ;Get character returned
        puly
        rts



;* Character printing on screen (Preserves all registers)
print:
        pshx
        pshy
        psha
        pshb

        des
        des
        des
        tsy

        staa    0,y
        ldaa    #'|'
        staa    1,y
        ldaa    #'S'            ;Symbol font to get full 5x8 block on VFD.
        staa    2,y

        ldaa    dl_posn
        jsr     SCREENS
        inc     dl_posn

        ins
        ins
        ins

        pulb
        pula
        puly
        pulx
        rts

;***********************************************************
;* Downloading screens
;***

downloading:
        dc.b '  Downloading....   |'
        dc.b '            L       '
        dc.b '                    |'
        dc.b '                    '


dl_breakdown_1:
        dc.b 'Serial Comm. Errors |'
        dc.b '                    '
        dc.b ' Download aborted!  |'
        dc.b '                    '
        
dl_breakdown_2:
        dc.b '     Power down     |'
        dc.b '                    '
        dc.b '   and try again!   |'
        dc.b '         L  L       '



SM_dl_ok_1:
        dc.b '      Download      |'
        dc.b '                    '
        dc.b '     Completed!     |'
        dc.b '        L           '

SM_dl_ok_2:
        dc.b '   Power Down TM    |'
        dc.b '                    '
        dc.b 'Configure S/M to RUN|'
        dc.b '     L              '
        
dl_timed_out:
        dc.b '    Rx time out!    |'
        dc.b '                    '
        dc.b 'Power down, check SM|'
        dc.b 'L                   '

box_line:
        dc.b 'OOOOOOOOOOOOOOOOOOO|'
        dc.b 'SSSSSSSSSSSSSSSSSSS'

box_line_old:
        dc.b 'OOOOOOOOOOOOOOOO|'
        dc.b 'SSSSSSSSSSSSSSSS'

;*********************************************************
;* 68HC11F1 S-record loader for EOS TheaterMasters.
;*********************************************************
;
;(This code is same as the file EEPROGIX.S19)
;****
;**** Must be exactly 256 bytes for the 68HC11E2 bootloader code
;****
;

Loader:
        dc.b $ff        ;* Must start with this!!! (not part of loader code)

        dc.b $8E,$00,$FF,$CE,$10,$00,$1D,$35,$0F,$6F,$2C,$CC,$30,$0C,$A7,$2B
        dc.b $E7,$2D,$1C,$3C,$20,$9F,$00,$8D,$7C,$C1,$49,$27,$14,$C1,$58,$26
        dc.b $09,$7C,$00,$00,$86,$80,$97,$01,$20,$07,$C1,$56,$26,$E7,$7A,$00
        dc.b $00,$8D,$62,$C1,$53,$26,$FA,$8D,$5C,$C1,$31,$27,$19,$C1,$39,$26
        dc.b $F0,$8D,$5F,$17,$80,$02,$8D,$6B,$8D,$58,$4A,$26,$FB,$18,$8C,$00
        dc.b $00,$27,$FE,$18,$6E,$00,$8D,$4A,$17,$80,$03,$8D,$56,$18,$09,$20
        dc.b $17,$D6,$00,$2B,$25,$27,$05,$C6,$A6,$5A,$26,$FD,$18,$E6,$00,$D8
        dc.b $03,$D4,$01,$26,$F7,$4A,$27,$B9,$8D,$28,$18,$08,$7D,$00,$00,$2B
        dc.b $05,$27,$43,$18,$E7,$00,$D7,$03,$20,$D7,$18,$E6,$00,$D1,$03,$27
        dc.b $E4,$8D,$08,$20,$E0,$1F,$2E,$20,$FC,$E6,$2F,$1F,$2E,$80,$FC,$E7
        dc.b $2F,$39,$8D,$F1,$8D,$17,$58,$58,$58,$58,$D7,$02,$8D,$E7,$8D,$0D
        dc.b $DA,$02,$39,$36,$8D,$EC,$17,$8D,$E9,$18,$8F,$32,$39,$C1,$39,$23
        dc.b $02,$CB,$09,$C4,$0F,$39,$36,$86,$16,$18,$8C,$10,$3F,$26,$02,$86
        dc.b $06,$8D,$10,$86,$02,$8D,$0C,$18,$8C,$10,$3F,$26,$03,$18,$E6,$00
        dc.b $32,$20,$A3,$A7,$3B,$18,$E7,$00,$6C,$3B,$3C,$CE,$0D,$05,$09,$26
        dc.b $FD,$38,$6A,$3B,$6F,$3B,$39

        dc.b                             $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
 
End_of_Loader:


;*********************************************************
;* SwitchMaster program for EOS TheaterMasters.
;*********************************************************
;
;(This code is same as the file SM1.S19)
;

SM1:
        dc.b   'S123F8001696175318191A8E00FFCE10000F1D35011C26801C07FF1C093A8630A72B860065'
        dc.b   'S123F820A72C860CA72D1C26031D24408604A73C1404FF1D00F01D03FF1D04FF0E7EF84031'
        dc.b   'S123F8407F00007F0001CC0000DD021E2E20421204FFF8A60A43847F2614960127ED8140A3'
        dc.b   'S123F8602617DC021A83006423E19601200B9701DC02C30001DD0220D2164F4C5424FC4A28'
        dc.b   'S123F88016C1062609A6048880A7047EF8407EF92BA62FBDF973D600262ABDF9915D271A9A'
        dc.b   'S123F8A0811826037EF9A7811926037EF9B0811A26037EF9B697007EF84B81FF26037EF911'
        dc.b   'S123F8C07A7EF84B81FF26037EF97AC47FC116271AC1172716C1532607814D26037EF989A7'
        dc.b   'S123F8E0BDF9915D2602202E7EF8A01504FF8115221B81102517840FC117276316960085F6'
        dc.b   'S123F9008027051C048020031D0480201EBDF9915D27037EF8A07EF84000100100200200C8'
        dc.b   'S123F920400400800840001080002018CEF91986033D183A18A600E603C43F1BA703180868'
        dc.b   'S123F94018A600E600C40F1BA700180818A600E604C4C01BA7047EF840010204081020164D'
        dc.b   'S123F96018CEF959183A18A600E603C4C01BA7037EF8401F2E80FCA72F391404FF1D00F057'
        dc.b   'S123F9801D03C01D04FF7EF840862ABDF9737EF84018CEF80018A100270A1808188CF80892'
        dc.b   'S123F9A026F35F39C60139A6048880A7047EF8401C04407EF8401D04407EF840183C18CE18'
        dc.b   'S123F9C0FFFF2020183C18CE2BC02018183C18CE16522010183C18CE05942008183C18CE81'
        dc.b   'S118F9E001182000180926FC1838394FA700A704A70320FE3B65'
        dc.b   'S123FFD6F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9F4F9EB40'
        dc.b   'S10DFFF6F9F4F9F4F9F4F9F4F8074A'
        dc.b   'S9030000FC'


End_of_SM1:

;*********************************************************
;* SwitchMaster program for Classic TheaterMaster.
;*********************************************************
;
;(This code is same as the file SMSHIP7.S19)
;

SM_OLD:
        dc.b   'S123FF50436F70797269676874202843292031393932202D203139393620627920456E6CAB'
        dc.b   'S123FF7069676874656E656420417564696F2044657369676E7320436F72706F7261746953'
        dc.b   'S123FF906F6E3A20205377697463684D617374657220204669726D776172652056657273DB'
        dc.b   'S11EFFB0696F6E20302E3030313920204A756E652031362C20313939362020E6'
        dc.b   'S123F8008081820304050001028384850600010203040500010203040532210BFF0021081C'
        dc.b   'S123F820FF00134EFF802109FF4E2109FF003709FF003609FF003509FF003B09FF003A0905'
        dc.b   'S123F840FF003909FF4E137FFF000D7AFF000E7BFF00020C027FFF00040DFF0D024CFF007F'
        dc.b   'S123F8600785FF000878FF000C79FF8513D2217FFF850878FF850C79FF0012962111FF9671'
        dc.b   'S123F88013A12112FF8506A5056EFFBE2113FF00113CFF970564FF97210A210FFF85119980'
        dc.b   'S123F8A00158FF990359FF8520C820C9FFA520C9FF9707A4054FFF3C1173FF000F74FF0040'
        dc.b   'S123F8C01075FF080000FC5E090000FC550A0A4BFC6B0B0000FC6B0C0C11FEDB0D0D00FA96'
        dc.b   'S123F8E0030F0000FBE5110000FC1C120000FC16130000FC10142800FEDB153000FEDB165D'
        dc.b   'S123F9003A00FEDB37374BFEDB3C3C11FBD44C0000F9E84D4D5BFEDB4E4E11FD1B4F0000D7'
        dc.b   'S123F920FDBB580000FC08590000FC0C640000FDF56E0000FCF8730000FBE5740000FBD9FB'
        dc.b   'S123F940750000FBDF780000FD0E790000FD127A0000FC477B0000FC4E7F0000FEDB960ECB'
        dc.b   'S123F960970E391C0808BDFD47BDFD471D0808398E00FFCE10000F1D35011C26801C07FF60'
        dc.b   'S123F9801C093A18CE005E186F00180926F918CEFEEA18DF2018CE003218DF228619BDFD8A'
        dc.b   'S123F9A020BDF9D7BDFA03860D97169717140FFF8630A72B8600A72C862CA72D1C26031C04'
        dc.b   'S123F9C024408604A73C0E7EF9CABDFA157D001C27F8BDFAAC20F3B6F80097244C97257F19'
        dc.b   'S123F9E000268606BDFC1639BDFD76A600840F97097F000096247C0024BDFC7B7F00047F31'
        dc.b   'S123FA000001399624368606BDFC7B329724BDFCFC1D048039BDFD3D9616810D2610962E51'
        dc.b   'S123FA20270C8602971C9710140FFF7EFAA07F002B1E0A4003142BFF962B912C2708122B36'
        dc.b   'S123FA40FF3F1230FF3B962E26037EFA98912D26037EFA985F0C5C4624FC18CEFBB2183AE2'
        dc.b   'S123FA6018A600971C9710140FFF8632132BFF051430FF86BE971686119719142FFF7EFA19'
        dc.b   'S123FA80987F0030863C971686119719C611D71CD710140FFF142FFF962B972C962E972D44'
        dc.b   'S123FAA0397F000E1F044003140E3F39961CD60F27087F00157F000F200C81012704810337'
        dc.b   'S123FAC026521215FF4E121FFF03140FFFD61CBDFBBCD71D961C971BBDFB397D001A263441'
        dc.b   'S123FAE0D61DC1FF272E8620971BBDFB397D001A2622D61DC1002710C106220C8621971B99'
        dc.b   'S123FB00BDFB397D001A260C8622971BBDFB397D001A2600961C97107D001A2612961797B3'
        dc.b   'S123FB2016961481022C087C0014140FFF20097F001F7F00147F001C39141AFF18CEF81946'
        dc.b   'S123FB4018A60018089116260718A600911B270A1808188CF8C3245620E618A601971812D5'
        dc.b   'S123FB6018803F9618810A25031415FF18CEF8C318A6009118270CC605183A188CF95E25A9'
        dc.b   'S123FB80EF202B0F183C18EE0318AD0018380E18A601971618A60297192616961697177EA8'
        dc.b   'S123FBA0FBB1131FFF009716C64BD71920037F001A39061716151B1A190B0A09961C845F78'
        dc.b   'S123FBC05F18CEFBB218A100270918085CC1092FF4C6FF39869797173996248A8020209641'
        dc.b   'S123FBE024847F201A152F0F962488809724D62853D42AD72A13248006D628DA2AD72A9729'
        dc.b   'S123FC00247C0024BDFC7B391C0440391D04403918CEF80D200A18CEF806200418CEF80081'
        dc.b   'S123FC20D61D5A183A18A6009731847F9127271697274CC6014A27035820FAD729C43FA643'
        dc.b   'S123FC400384C01BA703399625971D2008399625971D200A391426FF18CEF806200715263A'
        dc.b   'S123FC60FF18CEF800D61DD72520088600971718CEF80DD61D5A183A18A600912426037EB4'
        dc.b   'S123FC80FCC197244C847FC6014A27035820FAD7289624BDFCD3132FFF0C132FF00F96285B'
        dc.b   'S123FCA0942A843F200B962843942A972A9624848026081D048015248020061C04801424D0'
        dc.b   'S123FCC0807F002F390010002000400080400080000000183C3718CEFCC54816183A18A669'
        dc.b   'S123FCE000E603C43F1BA703180818A600E600C40F1BA700331838391204FF081D047F1469'
        dc.b   'S123FD0004FF20099616810D27037F0004391401FF397F00013986859717398680971739AE'
        dc.b   'S123FD2018DE2018E60018DE2218E700180818DF2218DE20180818DF204A26E739A60A438B'
        dc.b   'S123FD4036843F972E3239183C18CEFFFF2020183C18CE2BC02018183C18CE1652201018B7'
        dc.b   'S123FD603C18CE05942008183C18CE01182000180926FC1838398DCF8DCD18CEFDB08D196E'
        dc.b   'S123FD808DC58DC38DC18DBF8DBD8DBB8DB918CEFDB38D058DB18DAF3918A60097021808F9'
        dc.b   'S123FDA018A600A704BDFD4F18087A000226F139023F3F073F3E3C38302000860C18CEF8A9'
        dc.b   'S123FDC00018DF2218CEF80D18DF2018E60018DE2236BDFEDC32180818DF2218DE20180880'
        dc.b   'S123FDE018DF204A26E59625971D1226FF037EFC5E7EFC5539D6255A1326FF02CB0618CEC4'
        dc.b   'S123FE00F800183AD624BDFEDC39A62EA62F817F271781C027231E2F8002971C12090106B4'
        dc.b   'S123FE201F2F8004847F8D0A3BCCF970183018ED073B1F2E80FCA72F3986C08DF5C60C18C9'
        dc.b   'S123FE40CEF8008D2018085A26F918CE00248D1518CE00278D0F86451E04400286658DD2C4'
        dc.b   'S123FE60860D8DCE3B8653181E00800286438DC218A600847F8B318DB9394FA700A704A768'
        dc.b   'S123FE80037F000320FE1301FF067F000EBDFAA11D25BF1201FF04D628D70E7D00192725E1'
        dc.b   'S123FEA07A00192620200F8623971C9710140FFF86119719200F9617971613168007864BC0'
        dc.b   'S123FEC097197F0017BDFA15BDF95E1204FF08A60484C09A0EA7041411FF3B3918E10027E2'
        dc.b   'S123FEE00886169D3286029D3239A73B18E7006C3B183C18CE0B28180926FC18386A3B6F5F'
        dc.b   'S106FF003B393B4B'
        dc.b   'S123FFD6FE0AFF02FF02FF02FF02FF02FF02FF02FF02FF02FF02FF02FF02FE86FF02FE7AF6'
        dc.b   'S10DFFF6FF02FF02FF02FF02F97090'
        dc.b   'S9030000FC'

End_of_SM_OLD:

        end
