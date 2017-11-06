*-----------------------------------------------------------
* Title      :  Break.x68
* Written by :  Chuck Speed
* Date       :  10/7/15
* Description:  A simple target shooting game. Break the target to earn points. Your score will reset if you miss a target. 

*Controls*
*Use the arrow keys to move left and right, and space bar to shoot.
*-----------------------------------------------------------
ALL_REG                 REG     D0-D7/A0-A6
INVALID_RECT_REG        REG     D3-D7

*SCREEN & OUTPUT*
CLEAR_SCREEN_MAGIC_VAL          EQU    $FF00
CLEAR_SCREEN_COMMAND            EQU    11
SET_OUTPUT_RESOLUTION_TRAP_CODE EQU    33
OUTPUT_WIDTH                    EQU    640
OUTPUT_HEIGHT                   EQU    1079
REPAINT_SCREEN_TRAP_CODE	    EQU	   94
DRAWING_MODE_TRAP_CODE          EQU    92
DOUBLE_BUFFERED_MODE            EQU    17
RIGHT_SIDE_OF_SCREEN	        EQU	   640
TOP_SIDE_OF_SCREEN              EQU    0
SET_PEN_COLOR_COMMAND           EQU    80
SET_FILL_COLOR_COMMAND          EQU    81
DRAW_LINE_COMMAND               EQU    84
DRAW_CIRCLE_COMMAND             EQU    88
DRAW_RECTANGLE_COMMAND          EQU    87
GET_TIME_COMMAND                EQU    8
WHITE			                EQU	$00FFFFFF

*INPUT CODES*
GET_USER_INPUT_COMMAND  EQU     19
KEY_SPACE_INPUT         EQU     $20
KEY_LEFT_INPUT          EQU     $25
KEY_RIGHT_INPUT         EQU     $27

*PLAYER*
PLAYER_MOVEMENT         EQU     10

*BALL PROPERTIES*
BALL_WIDTH		         EQU	20
BALL_HEIGHT		         EQU	20
BALL_INITIAL_VELOCITY    EQU	$500
MAX_BALL_VELOCITY        EQU    $800

*BULLET PROPERTIES*
BULLET_WIDTH                 EQU     10
BULLET_HEIGHT                EQU     10
BULLET_VELOCITY              EQU     $800
BULLET_INITIAL_Y             EQU     $3ABFF
OFFSET_TO_CENTER_OF_PLAYER   EQU     65

*FUNCTION ARGUMENTS*
BULLET_LEFT_X_OFFSET         EQU    4
LARGE_NUMBER                 EQU    $5678
SCORE_X1                     EQU    580
SCORE_X2                     EQU    640
SCORE_Y1                     EQU    980
SCORE_Y2                     EQU    1050

*7-SEGMENTED LED COORDINATES*
SEGMENT_A_X1	EQU	580
SEGMENT_A_X2	EQU 610
SEGMENT_A_Y		EQU 990
SEGMENT_B_X		EQU 610
SEGMENT_B_Y1	EQU	990
SEGMENT_B_Y2	EQU 1020
SEGMENT_C_X		EQU 610
SEGMENT_C_Y1	EQU	1020
SEGMENT_C_Y2	EQU	1050
SEGMENT_D_X1	EQU	580
SEGMENT_D_X2	EQU	610
SEGMENT_D_Y		EQU	1050
SEGMENT_E_X		EQU	580
SEGMENT_E_Y1	EQU 1020
SEGMENT_E_Y2	EQU	1050
SEGMENT_F_X		EQU	580
SEGMENT_F_Y1	EQU	990
SEGMENT_F_Y2	EQU	1020
SEGMENT_G_X1	EQU	580
SEGMENT_G_X2	EQU	610
SEGMENT_G_Y		EQU	1020



        ORG    $1000
START:                  

        move.b  #SET_OUTPUT_RESOLUTION_TRAP_CODE,D0
        move.l  #OUTPUT_WIDTH,d1
        swap    d1
        move    #OUTPUT_HEIGHT,d1
        TRAP    #15
        
        move.l  #DRAWING_MODE_TRAP_CODE,d0
        move.l  #DOUBLE_BUFFERED_MODE,d1
        TRAP    #15
        
        move.l  BACKGROUND_X1,-(sp)
        move.l  BACKGROUND_X2,-(sp)
        move.l  BACKGROUND_Y1,-(sp)
        move.l  BACKGROUND_Y2,-(sp)        
        jsr     DrawBackground
        add     #16,sp
        
        move.l  PLAYER1_X1POSITION,-(sp)
        move.l  PLAYER1_X2POSITION,-(sp)
        move.l  PLAYER1_Y1POSITION,-(sp)
        move.l  PLAYER1_Y2POSITION,-(sp)
        jsr     DrawSprite
        add     #16,sp
        
        jsr     UpdateDeltaTime         
        jsr     UpdateDeltaTime
        jsr     UpdateBall
        jsr     DrawBall
        jsr     UpdateScoreDisplay

GameLoop:
        jsr     HandleInput
        jsr     UpdateBallInvalidRect
        jsr     ClearBulletTrail

        jsr     UpdateBall
        jsr     DrawBall
        
        jsr     UpdateBullet
        
        jsr     UpdateDeltaTime
        jsr     SwapBuffer
        jsr     CheckCollision
        bra     GameLoop
       
HandleInput
        cmpi.b   #1,BULLET_ACTIVE
        beq      NoInput

        move.l   #KEY_SPACE_INPUT<<16+KEY_LEFT_INPUT<<8+KEY_RIGHT_INPUT,d1
        move.b   #GET_USER_INPUT_COMMAND,d0
        TRAP     #15
        andi.l   #$FFFFFF,d1
        beq      NoInput
        cmpi     #$FF00,d1
        ble      MoveLeft
        cmpi.l   #$FF0000,d1
        bge      Shoot
      
      
        cmp.l    #RIGHT_SIDE_OF_SCREEN,PLAYER1_X2POSITION
        beq      NoInput
  
        add.l    #PLAYER_MOVEMENT,PLAYER1_X1POSITION
        add.l    #PLAYER_MOVEMENT,PLAYER1_X2POSITION
        move.l   PLAYER1_X1POSITION,-(sp)
        move.l   PLAYER1_X2POSITION,-(sp)
        move.l   PLAYER1_Y1POSITION,-(sp)
        move.l   PLAYER1_Y2POSITION,-(sp)
        jsr      DrawSprite
        add      #16,sp
        
        move.l   PLAYER1_X1POSITION,d5
        subi     #PLAYER_MOVEMENT,d5
        move.l   d5,-(sp)
        moveq    #0,d5
        move.l   PLAYER1_X1POSITION,d5
        move.l   d5,-(sp)
        move.l   PLAYER1_Y1POSITION,-(sp)
        move.l   PLAYER1_Y2POSITION,-(sp)
        jsr      DrawBackground
        add      #16,sp
        rts
        
MoveLeft:
        cmp.l   #0,PLAYER1_X1POSITION
        beq     NoInput

        subi.l    #PLAYER_MOVEMENT,PLAYER1_X1POSITION
        subi.l    #PLAYER_MOVEMENT,PLAYER1_X2POSITION
        move.l    PLAYER1_X1POSITION,-(sp)
        move.l    PLAYER1_X2POSITION,-(sp)
        move.l    PLAYER1_Y1POSITION,-(sp)
        move.l    PLAYER1_Y2POSITION,-(sp)
        jsr       DrawSprite
        add       #16,sp


        move.l    PLAYER1_X2POSITION,d5
        move.l    d5,-(sp)
        moveq     #0,d5
        move.l    PLAYER1_X2POSITION,d5
        add.l     #PLAYER_MOVEMENT,d5
        move.l    d5,-(sp)

        move.l    PLAYER1_Y1POSITION,-(sp)
        move.l    PLAYER1_Y2POSITION,-(sp)
        jsr       DrawBackground
        add       #16,sp
        rts
        
Shoot:
        cmpi.b  #1,BULLET_ACTIVE
        beq     NoInput
        move.l  PLAYER1_X2POSITION,d7
        sub.l   #OFFSET_TO_CENTER_OF_PLAYER,d7
        move.l  d7,-(sp)
        move.l  BULLET_Y_FIXED_POINT,d7
        jsr     DrawBullet
        addq    #4,sp
        
        move.b  #1,BULLET_ACTIVE
        
NoInput:
        rts     

ClearScreen
        move.b  #CLEAR_SCREEN_COMMAND,d0
       	move.l  #CLEAR_SCREEN_MAGIC_VAL,d1
       	TRAP    #15
	    rts
	    
SwapBuffer
    move.l  #REPAINT_SCREEN_TRAP_CODE,d0
    TRAP #15
    rts
    
    
UpdateBall
    move.l  BALL_X_FIXED_POINT,d7
    move.w  BALL_VELOCITY,d6       
    move.l  DELTA_TIME,d5
    muls    d5,d6
	add.l	d6,d7

	cmpi.l	#(RIGHT_SIDE_OF_SCREEN-BALL_WIDTH)<<8,d7
	ble	noNegativeSet
	move.l  #-1,d5
    muls    BALL_VELOCITY,d5
    cmp.l   #MAX_BALL_VELOCITY,BALL_VELOCITY
    bge     DontAccelerateLeft
	sub.l  #250,d5
DontAccelerateLeft:
	move.w  d5,BALL_VELOCITY
	move.l	#(RIGHT_SIDE_OF_SCREEN-BALL_WIDTH)<<8,d7
	bra	NoPositiveSet
NoNegativeSet:
	cmpi.l	#0,d7
	bgt	NoPositiveSet
    muls    #-1,d7
	move.l  #-1,d5
    muls    BALL_VELOCITY,d5
    cmp.l   #MAX_BALL_VELOCITY,d5
    bge     DontAccelerateRight
	add.l   #250,d5
DontAccelerateRight:
	move.w  d5,BALL_VELOCITY
NoPositiveSet:
    move.l  d7,BALL_X_FIXED_POINT
	rts

DrawBall
	move.l	#WHITE,d1
	move.b	#SET_PEN_COLOR_COMMAND,d0
	trap	#15
	move.b	#SET_FILL_COLOR_COMMAND,d0
	trap	#15
	
	move.b	#DRAW_CIRCLE_COMMAND,d0
	move.l	d7,d1
	asr.l	#8,d1
	   
	cmp.l   #0,d1                         ;Resets ball's Left_X position if it's off-screen
	bge     DontResetPosition
    moveq   #0,d1
    moveq   #0,d7
DontResetPosition:	
	move.l	d1,d3
	add.l	#BALL_WIDTH,d3
	move.l  BALL_Y,d2
	move.l  d2,d4
	add.l   #BALL_HEIGHT,d4
	trap	#15

    move.l    d1,BALL_X
    move.l    d2,BALL_Y
	rts
	
UpdateBullet
    cmpi.b  #1,BULLET_ACTIVE
    bne     DontUpdate
    
    move.l  BULLET_Y_FIXED_POINT,d7
    move.l  #BULLET_VELOCITY,d6       
    move.l  DELTA_TIME,d5
    muls    d5,d6
	sub.l	d6,d7


    move.l  d7,BULLET_Y_FIXED_POINT
    move.l  BULLET_LEFT_X,-(sp)
    jsr     DrawBullet
    add     #4,sp    
DontUpdate:
    rts
	
DrawBullet
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_RECTANGLE_COMMAND,d0
    move.l  BULLET_LEFT_X_OFFSET(sp),d1
    move.l  d1,d3
    add.l   #BULLET_WIDTH,d3
    move.l  d7,d2
    asr.l   #8,d2
    move.l  d2,d4
    add.l   #BULLET_HEIGHT,d4
    TRAP    #15
    
    
    cmp.l   #10,d2
    bge     AroundDisableBullet
    jsr     ClearBulletTrail
    move.l  #BULLET_INITIAL_Y,BULLET_Y_FIXED_POINT
    move.b  #0,BULLET_ACTIVE
    move.b  #1,MISS

AroundDisableBullet:
    move.l    d1,BULLET_LEFT_X
    move.l    d2,BULLET_TOP_Y
    rts
	
UpdateDeltaTime
    move.l  #GET_TIME_COMMAND,d0
    TRAP    #15
    move.l  CURRENT_TIME,PREV_TIME
    move.l  d1,CURRENT_TIME
    sub.l   PREV_TIME,d1
    move.l  d1,DELTA_TIME
    rts
    
UpdateBallInvalidRect
    move.l    PREV_BALL_X,d3
    sub.l     #10,d3
    move.l    d3,-(sp)
    move.l    PREV_BALL_X,d3      ;Left_X of invalid recatangle
    add.l     #BALL_WIDTH+10,d3        
    move.l    d3,-(sp)            ;Right_X of invalid rectangle
    move.l    PREV_BALL_Y,-(sp)
    move.l    PREV_BALL_Y,d4      ;Top_Y of invalid rectangle
    add.l     #BALL_HEIGHT,d4
    move.l    d4,-(sp)            ;Bottom_Y of invalid rectangle
    jsr       DrawBackground
    add       #16,sp
        
    move.l    BALL_X,PREV_BALL_X
    move.l    BALL_Y,PREV_BALL_Y
    rts
    
ClearBulletTrail
    cmpi.b  #1,BULLET_ACTIVE
    bne     DontClear

    move.l  BULLET_LEFT_X,-(sp)
    move.l  BULLET_LEFT_X,d7
    add.l   #BULLET_WIDTH+1,d7
    move.l  d7,-(sp)
    move.l  BULLET_TOP_Y,-(sp)
    move.l  BULLET_TOP_Y,d7
    add.l   #BULLET_HEIGHT,d7
    move.l  d7,-(sp)
    jsr     DrawBackground
    add     #16,sp
    
DontClear:
    rts
    
ClearBulletRemains
    move.l  #0,-(sp)
    move.l  #RIGHT_SIDE_OF_SCREEN,-(sp)
    move.l  #TOP_SIDE_OF_SCREEN,-(sp)
    move.l  #TOP_SIDE_OF_SCREEN+BULLET_HEIGHT+5,-(sp)
    jsr     DrawBackground
    add     #16,sp
    rts
    
CheckCollision
    movem.l d6/d7,-(sp)
    cmpi.b  #1,BULLET_ACTIVE
    bne     NoCollision


    move.l  BULLET_LEFT_X,d7
    add.l   #BULLET_WIDTH,d7
    move.l  BALL_X,d6
    cmp.l   d6,d7               ;Checks if bullet is completely to the left of the ball
    blt     NoCollision
    
    move.l  BALL_X,d7
    add.l   #BALL_WIDTH,d7
    move.l  BULLET_LEFT_X,d6
    cmp.l   d6,d7               ;Checks if bullet is completely to the right of the ball
    blt     NoCollision
    
    move.l  BULLET_TOP_Y,d7
    add.l   #BULLET_HEIGHT,d7
    move.l  BALL_Y,d6
    cmp.l   d6,d7               ;Checks if bullet is completely above the ball
    blt     NoCollision
    
    move.l  BALL_Y,d7
    add.l   #BALL_HEIGHT,d7
    move.l  BULLET_TOP_Y,d6
    cmp.l   d6,d7               ;Checks if bullet is completely below the ball
    blt     NoCollision
    
                                ;if all checks fail, the bullet must be colliding with the ball
    addq.b  #1,SCORE
    move.b  #0,MISS
    move.l  #SCORE_X1,-(sp)
    move.l  #SCORE_X2,-(sp)
    move.l  #SCORE_Y1,-(sp)
    move.l  #SCORE_Y2,-(sp)
    jsr     DrawBackground
    add     #16,sp
    jsr     UpdateScoreDisplay
GetAnotherRandomNumber:
    jsr     SeedRandomNumber
    jsr     GetRandomLongIntoD6
    move.l  #OUTPUT_HEIGHT,d7
    lsr.l   #4,d6
    divu    d7,d6
    clr.w   d6
    swap    d6
    move.l  PLAYER1_Y1POSITION,d7
    sub.l   #BALL_HEIGHT,d7
    cmp.l   d7,d6                                       ;ensures the new ball position is above the player
    bge     GetAnotherRandomNumber
    cmp     #20,d6                                      ;ensures the new ball position is within the output window
    ble     GetAnotherRandomNumber
    jsr     UpdateBallInvalidRect
    move.l  d6,BALL_Y
 
    jsr     ClearBulletTrail
    jsr     ClearBulletRemains 
    move.b  #0,BULLET_ACTIVE
    move.l  #BULLET_INITIAL_Y,BULLET_Y_FIXED_POINT
    move    #BALL_INITIAL_VELOCITY,BALL_VELOCITY
    movem.l (sp)+,d6/d7
    rts

NoCollision:
    movem.l (sp)+,d6/d7
    cmpi.b  #1,MISS
    bne     AroundResetScore
    cmpi.b  #0,SCORE
    beq     AroundResetScore
    move.b  #0,SCORE
    move.l  #SCORE_X1,-(sp)
    move.l  #SCORE_X2,-(sp)
    move.l  #SCORE_Y1,-(sp)
    move.l  #SCORE_Y2,-(sp)
    jsr     DrawBackground
    add     #16,sp
    jsr     UpdateScoreDisplay
AroundResetScore:
    rts
    
SeedRandomNumber
        movem.l ALL_REG,-(sp)
        clr.l   d6
        move.b  #GET_TIME_COMMAND,d0
        TRAP    #15
        move.l  d1,d6
        mulu    #LARGE_NUMBER,d6
        move.l  d6,RANDOMVAL
        movem.l (sp)+,ALL_REG
        rts
        
GetRandomLongIntoD6
        movem.l d0,-(sp)
        movem.l d1,-(sp)
        move.l  RANDOMVAL,d6
        mulu    #LARGE_NUMBER,d6
        move.l  #31,d0
        TRAP    #15
        mulu    d1,d6
        bcs     Nocarry
        add.l   #1,d6
NoCarry:
        move.l  d6,RANDOMVAL
        movem.l (sp)+,d1
        movem.l (sp)+,d0
        rts
        
DrawSegA
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_LINE_COMMAND,d0
    move.l  #SEGMENT_A_X1,d1
    move.l  #SEGMENT_A_Y,d2
    move.l  #SEGMENT_A_X2,d3
    move.l  #SEGMENT_A_Y,d4
    TRAP    #15
    rts
    
DrawSegB
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_LINE_COMMAND,d0
    move.l  #SEGMENT_B_X,d1
    move.l  #SEGMENT_B_Y1,d2
    move.l  #SEGMENT_B_X,d3
    move.l  #SEGMENT_B_Y2,d4
    TRAP    #15
    rts

DrawSegC
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_LINE_COMMAND,d0
    move.l  #SEGMENT_C_X,d1
    move.l  #SEGMENT_C_Y1,d2
    move.l  #SEGMENT_C_X,d3
    move.l  #SEGMENT_C_Y2,d4
    TRAP    #15
    rts
    
DrawSegD
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_LINE_COMMAND,d0
    move.l  #SEGMENT_D_X1,d1
    move.l  #SEGMENT_D_Y,d2
    move.l  #SEGMENT_D_X2,d3
    move.l  #SEGMENT_D_Y,d4
    TRAP    #15
    rts
    
DrawSegE
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_LINE_COMMAND,d0
    move.l  #SEGMENT_E_X,d1
    move.l  #SEGMENT_E_Y1,d2
    move.l  #SEGMENT_E_X,d3
    move.l  #SEGMENT_E_Y2,d4
    TRAP    #15
    rts
    
DrawSegF
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_LINE_COMMAND,d0
    move.l  #SEGMENT_F_X,d1
    move.l  #SEGMENT_F_Y1,d2
    move.l  #SEGMENT_F_X,d3
    move.l  #SEGMENT_F_Y2,d4
    TRAP    #15
    rts
    
DrawSegG
    move.l  #WHITE,d1
    move.b  #SET_PEN_COLOR_COMMAND,d0
    TRAP    #15
    move.b  #SET_FILL_COLOR_COMMAND,d0
    TRAP    #15
    
    move.b  #DRAW_LINE_COMMAND,d0
    move.l  #SEGMENT_G_X1,d1
    move.l  #SEGMENT_G_Y,d2
    move.l  #SEGMENT_G_X2,d3
    move.l  #SEGMENT_G_Y,d4
    TRAP    #15
    rts
    
UpdateScoreDisplay
    moveq  #0,d1
    moveq  #0,d2

    move.b SCORE,d0
    lea DIGIT_TABLE,a0
    move.b (a0,d0),d1
    move.b  d1,d2
    
    andi.b  #$01,d1
    beq     aroundDrawSegA
    move.b  d2,-(sp)
    jsr     DrawSegA
    move.b  (sp)+,d2
aroundDrawSegA:
    move.b  d2,d1
    andi.b  #$02,d1
    beq     aroundDrawSegB
    move.b  d2,-(sp)
    jsr     DrawSegB
    move.b  (sp)+,d2
aroundDrawSegB:
    move.b  d2,d1
    andi.b  #$04,d1
    beq     aroundDrawSegC
    move.b  d2,-(sp)
    jsr     DrawSegC
    move.b  (sp)+,d2
aroundDrawSegC:
    move.b  d2,d1
    move.b  d2,d1
    andi.b  #$08,d1
    beq     aroundDrawSegD
    move.b  d2,-(sp)
    jsr     DrawSegD
    move.b  (sp)+,d2
aroundDrawSegD:
    move.b  d2,d1
    andi.b  #$10,d1
    beq     aroundDrawSegE
    move.b  d2,-(sp)
    jsr     DrawSegE
    move.b  (sp)+,d2
aroundDrawSegE:
    move.b  d2,d1
    andi.b  #$20,d1
    beq     aroundDrawSegF
    move.b  d2,-(sp)
    jsr     DrawSegF
    move.b  (sp)+,d2
aroundDrawSegF:
    move.b  d2,d1
    andi.b  #$40,d1
    beq     aroundDrawSegG
    jsr     DrawSegG
aroundDrawSegG:
    rts
    
    SIMHALT             
        
*Variables, Constants, & Tables
HAVE_HAD_NO_INPUT       ds.b   1
BULLET_ACTIVE           ds.b   1
PLAYER1_X1POSITION      dc.l   260
PLAYER1_X2POSITION      dc.l   380
PLAYER1_Y1POSITION      dc.l   950
PLAYER1_Y2POSITION      dc.l   972
BACKGROUND_X1           dc.l   0
BACKGROUND_X2           dc.l   640
BACKGROUND_Y1           dc.l   0
BACKGROUND_Y2           dc.l   1079
BALL_X                  dc.l   0
BALL_X_FIXED_POINT      dc.l   0
BALL_Y                  dc.l   100
PREV_BALL_X             dc.l   0
PREV_BALL_Y             dc.l   100
BALL_VELOCITY           dc.w   $500
CURRENT_TIME            dc.l   0
PREV_TIME               dc.l   0
DELTA_TIME              dc.l   0
BULLET_LEFT_X           dc.l   260
BULLET_TOP_Y            dc.l   940
BULLET_Y_FIXED_POINT    dc.l   $3ABFF
RANDOMVAL               ds.l   1
SCORE                   dc.b   0
MISS                    dc.b   0
DIGIT_TABLE             dc.b   $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F
                        ds.w   0
        INCLUDE         'DrawBackground.x68'
        INCLUDE         'DrawSprite.x68'


    END    START















*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
