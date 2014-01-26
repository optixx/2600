; move a happy face with the joystick by Kirk Israel
; (with a can't'dodge'em line sweeping across the screen)

	processor 6502
	include vcs.h
	org $F000

YPosFromBot = $80;
VisiblePlayerLine = $81;

;generic start up stuff...
Start
	SEI	
	CLD  	
	LDX #$FF	
	TXS	
	LDA #0		
ClearMem 
	STA 0,X		
	DEX		
	BNE ClearMem	
	
	LDA #$00   ;start with a black background
	STA COLUBK	
	LDA #$1C   ;lets go for bright yellow, the traditional color for happyfaces
	STA COLUP0
;Setting some variables...
	LDA #80
	STA YPosFromBot	;Initial Y Position

;; Let's set up the sweeping line. as Missile 1

	
	LDA #2
	STA ENAM1  ;enable it
	LDA #33
	STA COLUP1 ;color it

	LDA #$20	
	STA NUSIZ1	;make it quadwidth (not so thin, that)

	
	LDA #$F0	; -1 in the left nibble
	STA HMM1	; of HMM1 sets it to moving


;VSYNC time
MainLoop
	LDA #2
	STA VSYNC	
	STA WSYNC	
	STA WSYNC 	
	STA WSYNC	
	LDA #43	
	STA TIM64T	
	LDA #0
	STA VSYNC 	


;Main Computations; check down, up, left, right
;general idea is to do a BIT compare to see if 
;a certain direction is pressed, and skip the value
;change if so

;
;Not the most effecient code, but gets the job done,
;including diagonal movement
;

; for up and down, we INC or DEC
; the Y Position

	LDA #%00010000	;Down?
	BIT SWCHA 
	BNE SkipMoveDown
	INC YPosFromBot
SkipMoveDown

	LDA #%00100000	;Up?
	BIT SWCHA 
	BNE SkipMoveUp
	DEC YPosFromBot
SkipMoveUp

; for left and right, we're gonna 
; set the horizontal speed, and then do
; a single HMOVE.  We'll use X to hold the
; horizontal speed, then store it in the 
; appropriate register


;assum horiz speed will be zero
	LDX #0	

	LDA #%01000000	;Left?
	BIT SWCHA 
	BNE SkipMoveLeft
	LDX #$10	;a 1 in the left nibble means go left

;; moving left, so we need the mirror image
	LDA #%00001000   ;a 1 in D3 of REFP0 says make it mirror
	STA REFP0

SkipMoveLeft
	LDA #%10000000	;Right?
	BIT SWCHA 
	BNE SkipMoveRight
	LDX #$F0	;a -1 in the left nibble means go right...

;; moving right, cancel any mirrorimage
	LDA #%00000000
	STA REFP0

SkipMoveRight


	STX HMP0	;set the move for player 0, not the missile like last time...



; see if player and missile collide, and change the background color if so

	;just a review...comparisons of numbers always seem a little backwards to me,
	;since it's easier to load up the accumulator with the test value, and then
	;compare that value to what's in the register we're interested.
	;in this case, we want to see if D7 of CXM1P (meaning Player 0 hit
	; missile 1) is on. So we put 10000000 into the Accumulator,
	;then use BIT to compare it to the value in CXM1P

	LDA #%10000000
	BIT CXM1P		
	BEQ NoCollision	;skip if not hitting...
	LDA YPosFromBot	;must be a hit! load in the YPos...
	STA COLUBK	;and store as the bgcolor
NoCollision
	STA CXCLR	;reset the collision detection for next time




WaitForVblankEnd
	LDA INTIM	
	BNE WaitForVblankEnd	
	LDY #191 	


	STA WSYNC	
	STA HMOVE 	
	
	STA VBLANK  	


;main scanline loop...


ScanLoop 
	STA WSYNC 	

; here the idea is that VisiblePlayerLine
; is zero if the line isn't being drawn now,
; otherwise it's however many lines we have to go

CheckActivatePlayer
	CPY YPosFromBot
	BNE SkipActivatePlayer
	LDA #8
	STA VisiblePlayerLine 
SkipActivatePlayer



;set player graphic to all zeros for this line, and then see if 
;we need to load it with graphic data
	LDA #0		
	STA GRP0  

;
;if the VisiblePlayerLine is non zero,
;we're drawing it now!
;
	LDX VisiblePlayerLine	;check the visible player line...
	BEQ FinishPlayer		;skip the drawing if its zero...
IsPlayerOn	
	LDA BigHeadGraphic-1,X	;otherwise, load the correct line from BigHeadGraphic
				;section below... it's off by 1 though, since at zero
				;we stop drawing
	STA GRP0		;put that line as player graphic
	DEC VisiblePlayerLine 	;and decrement the line count
FinishPlayer


	DEY		
	BNE ScanLoop	

	LDA #2		
	STA WSYNC  	
	STA VBLANK 	
	LDX #30		
OverScanWait
	STA WSYNC
	DEX
	BNE OverScanWait
	JMP  MainLoop      


; here's the actual graphic! If you squint you can see its
; upsidedown smiling self
BigHeadGraphic
	.byte #%00111100
	.byte #%01111110
	.byte #%11000001
	.byte #%10111111
	.byte #%11111111
	.byte #%11101011
	.byte #%01111110
	.byte #%00111100

	org $FFFC
	.word Start
	.word Start
