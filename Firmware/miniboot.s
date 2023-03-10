;
;	Mini 11 Bootstrap
;
SPCR	EQU	$28
SPSR	EQU	$29
SPDR	EQU	$2A
PDDR	EQU	$08
DDRD	EQU	$09
TMSK2	EQU	$24
PACTL	EQU	$26

BAUD	EQU	$2B
SCCR1	EQU	$2C
SCCR2	EQU	$2D
SCSR	EQU	$2E
SCDR	EQU	$2F

PORTA	EQU	$00

	ORG	$F040
	;	IRAM
CARDTYPE:
	FCB	0

CTMMC	EQU	1
CTSD2	EQU	2
CTSDBLK	EQU	3
CTSD1	EQU	4

BUF:
	FCB	0,0,0,0,0,0,0,0

	ORG $F800

START:
	;	Put the internal RAM at F040-F0FF
	;	and I/O at F000-F03F. This costs s 64bits of IRAM
	;	but gives us a nicer addressing map.
	LDAA	#$FF
	STAA  	$103D
	LDX	#$F000
	;	Free running timer on divide by 16
	LDAA	$24,X
	ORAA    #3
	STAA	$24,X
	;	Set up the memory
	;	Ensure we are in ram bank 0, ROMEN, CS1 high
	;	regardless of any surprises at reset
	LDAA	#$80
	STAA	PORTA,X
	BSET	PACTL,X $80
	LDAA	#$13
	STAA	$39,X	;COP slow, DLY still on
	SEI
	LDAA	#$30
	STAA	BAUD,X	; BAUD
	LDAA	#$00
	STAA	SCCR1,X	; SCCR1
	LDAA	#$0C
	STAA	SCCR2,X	; SCCR2
	;	Serial is now 9600 8N1 for the 8MHz crystal
	LDS	#$F0FF


	LDY	#INIT
	JSR	STROUT

	LDAA	$3F,X	; CONFIG
	JSR	PHEX	; Display it

	LDY	#INIT2
	JSR	STROUT
	;
	;	Probe for an SD card and set it up as tightly as we can
	;

	LDAA #$38	; SPI outputs on
	STAA DDRD,X
	LDAA #$52	; SPI on, master, mode 0, slow (125Khz)
	STAA SPCR,X

	;	Raise CS send clocks
	JSR  CSRAISE
	LDAA #200	; Time for SD to stabilize
CSLOOP:
	JSR  SENDFF
	DECA
	BNE CSLOOP
	LDY #CMD0
	BSR  SENDCMD
	DECB	; 1 ?
	BNE SDFAILB
	LDY #CMD8
	JSR SENDCMD
	DECB
	BEQ NEWCARD
	JMP OLDCARD
NEWCARD:
	BSR GET4
	LDD BUF+2
	CMPD #$01AA
	BNE SDFAILD
WAIT41:
	LDY #ACMD41
	JSR SENDACMD
	BNE WAIT41
	LDY #CMD58
	JSR SENDCMD
	BNE SDFAILB
	BSR GET4
	LDAA BUF
	ANDA #$40
	BNE BLOCKSD2
	LDAA #CTSD2
INITOK:
	STAA CARDTYPE
	JMP LOADER

GET4:
	LDAA #4
	LDY #BUF
GET4L:
	JSR SENDFF
	STAB ,Y
	INY
	DECA
	BNE GET4L
	RTS

SDFAILD:
	JSR PHEX
SDFAILB:
	TBA
SDFAILA:
	JSR PHEX
	LDY #ERROR
	JMP FAULT

SENDACMD:
	PSHY
	LDY #CMD55
	JSR SENDCMD
	PULY
SENDCMD:
	JSR CSRAISE
	BSR CSLOWER
	CMPY #CMD0
	BEQ NOWAITFF
WAITFF:
	JSR SENDFF
	INCB
	BNE WAITFF
NOWAITFF:
	; Command, 4 bytes data, CRC all preformatted
	LDAA #6
SENDLP:
	LDAB ,Y
	JSR SEND
	INY
	DECA
	BNE SENDLP
	JSR SENDFF
WAITRET:
	JSR SENDFF
	BITB #$80
	BNE WAITRET
	CMPB #$00
	RTS

SDFAIL2:
	BRA SDFAILB

CSLOWER:
	BCLR PDDR,X $20
	RTS
BLOCKSD2:
	LDAA #CTSDBLK
	JMP INITOK
OLDCARD:
	LDY #ACMD41_0	; FIXME _0 check ?
	JSR SENDACMD
	CMPB #2
	BHS MMC
WAIT41_0:
	LDY #ACMD41_0
	JSR SENDACMD
	BNE WAIT41_0
	LDAA #CTSD1
	STAA CARDTYPE
	BRA SECSIZE
MMC:
	LDY #CMD1
	JSR SENDCMD
	BNE MMC
	LDAA #CTMMC
	STAA CARDTYPE
SECSIZE:
	LDY #CMD16
	JSR SENDCMD
	BNE SDFAIL2
LOADER:
	BSR CSRAISE
	LDY #CMD17
	JSR SENDCMD
	BNE SDFAIL2
WAITDATA:
	JSR SENDFF
	CMPB #$FE
	BNE WAITDATA
	LDY #$0
	CLRA
DATALOOP:
	JSR SENDFF
	STAB ,Y
	JSR SENDFF
	STAB 1,Y
	INY
	INY
	DECA
	BNE DATALOOP
	BSR CSRAISE
	LDY #$0
	LDD ,Y
	CPD #$6811
	BNE NOBOOT
	LDAA CARDTYPE
	JMP 2,Y

;
;	This lot must preserve A
;
CSRAISE:
	BSET PDDR,X $20
SENDFF:
	LDAB #$FF
SEND:
;	PSHA
;	TBA
;	JSR PHEX
;	LDA #':'
;	JSR CHOUT
;	PULA
	STAB SPDR,X
SENDW:	BRCLR SPSR,X $80 SENDW
	LDAB SPDR,X
;	PSHA
;	TBA
;	JSR PHEX
;	LDAA #10
;	JSR CHOUT
;	LDAA #13
;	JSR CHOUT
;	PULA
	RTS

;
;	Commands
;
CMD0:
	FCB $40,0,0,0,0,$95
CMD1:
	FCB $41,0,0,0,0,$01
CMD8:
	FCB $48,0,0,$01,$AA,$87
CMD16:
	FCB $50,0,0,2,0,$01
CMD17:
	FCB $51,0,0,0,0,$01
CMD55:	
	FCB $77,0,0,0,0,$01
CMD58:
	FCB $7A,0,0,0,0,$01
ACMD41_0:
	FCB $69,0,0,0,0,$01
ACMD41:
	FCB $69,$40,0,0,0,$01

NOBOOT: LDY	#NOBOOT
	FCC	'Not bootable'
	FCB	13,10,0
FAULT:	JSR	STROUT
STOPB:	BRA	STOPB

INIT:
	FCC	'Mini11 68HC11 System, (C) 2019-2023 Alan Cox'
	FCB	13,10
	FCC	'Firmware revision: 0.1.1'
	FCB	13,10,13,10
	FCC	'MC68HC11 config register '
	FCB	0

INIT2:
	FCB	13,10
	FCC	'Booting from SD card...'
	FCB	13,10,0

ERROR:
	FCC	'SD Error'
	FCB	13,10,0

	;
	;	Serial I/O	
	;

PHEX:	PSHA
	LSRA
	LSRA
	LSRA
	LSRA
	BSR	HEXDIGIT
	PULA
	ANDA #$0F
HEXDIGIT:
	CMPA #10
	BMI LO
	ADDA #7
LO:	ADDA #'0'
CHOUT:	BRCLR	SCSR,X $80 CHOUT
	STAA	SCDR,X
CHOUTE:	BRCLR	SCSR,X $80 CHOUTE	; helps debug as it's now sync
STRDONE: RTS
STROUT:	LDAA	,Y
	BEQ	STRDONE
	BSR	CHOUT
	INY
	BRA	STROUT

	ORG	$FFFE

	FDB	START
