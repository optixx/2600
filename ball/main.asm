; a moving dot by Kirk Israel
	
	processor 6502
	include vcs.h
	org $F000

;we start by setting up two "variables"
;this means we tell DASM that when we say
;variablename, we mean this specific memory
;location (we have $80 to $FF to play with)

;we'll use this one to store the vertical position
YPosFromBot = $80;
;more on the use of this variable below
VisibleMissileLine = $81;

;generic start up stuff...
Start
	SEI	
	CLD  	
	LDX #$FF	;we're so clever, we LDX
	TXS		;once and use that for 
	LDA #0		;both TXS ad the ClearMem loop
ClearMem 
	STA 0,X		
	DEX		
	BNE ClearMem	
	LDA #$00		
	STA COLUBK	
	LDA #66		;Lets go for purpley!
	STA COLUP0

	LDA #80
	STA YPosFromBot	;set Initial Y Position

	;NUSIZ0 sets the size and multiplying
	;of the sprite and missiles --see the Stella 
	;guide for details
	LDA #$20	
	STA NUSIZ0 ;Quad Width for now


;VSYNC time
MainLoop
	LDA  #2
	STA  VSYNC	
	STA  WSYNC	
	STA  WSYNC 	
	STA  WSYNC	
	LDA  #43	
	STA  TIM64T	
	LDA #0		
	STA  VSYNC 	

	;#% is a way of indicating a binary actual number
	;(just like #$ starts a hex number and # a decimal number)
	
	LDA #%00010000  ;put value of 1 in the left nibble (slow move right)
	STA HMM0	;set the move for missile 0

WaitForVblankEnd
	LDA INTIM	
	BNE WaitForVblankEnd	
	LDY #191 	
	STA WSYNC
	STA VBLANK  	

	STA WSYNC	
	STA HMOVE 	

;main scanline loop...
ScanLoop 
	STA WSYNC 	

; here the idea is that VisibleMissileLine
; is zero if the line isn't being drawn now,
; otherwise it's however many lines we have to go

; there are probably more efficient ways of doing this


; we see if this is the line (line # stored in Y) is the 
; one that we start the missile on
CheckActivateMissile
	CPY YPosFromBot		;compare Y to the YPosFromBot...
	BNE SkipActivateMissile ;if not equal, skip this...
	LDA #8			;otherwise say that this should go
	STA VisibleMissileLine	;on for 8 lines	
SkipActivateMissile

;turn missile off then see if it's turned on
	LDA #0		
	STA ENAM0
;
;if the VisibleMissileLine is non zero,
;we're drawing it
;
	LDA VisibleMissileLine	;load the value of what missile line we're showing
	BEQ FinishMissile	;if zero we aren't showing, skip it
IsMissileOn	
	LDA #2			;otherwise
	STA ENAM0		;showit
	DEC VisibleMissileLine 	;and decrement the missile line thing
FinishMissile

	DEY		;decrement scanline counter
	BNE ScanLoop	;lather rinse repeat


;overscan same as last time
	LDA #2		
	STA WSYNC  	
	STA VBLANK 	
	LDX #30		
OverScanWait
	STA WSYNC
	DEX
	BNE OverScanWait
	JMP  MainLoop      
 
	org $FFFC
	.word Start
	.word Start
