*-----------------------------------------------------------
* Program    : DrawSprite.x68
* Written by : Chuck Speed
* Date       : 10/2/2015
* Description: Draws sprites provided a clipping rectangle.
*-----------------------------------------------------------
IMAGE_HEIGHT_OFFSET     EQU     22
IMAGE_WIDTH_OFFSET      EQU     18
IMAGE_DATA_OFFSET       EQU     10
BMP_DATA_OFFSET         EQU     $36

SPRITE_LEFT_X  EQU     0
SPRITE_WIDTH   EQU     120
SPRITE_TOP_Y   EQU     0
SPRITE_HEIGHT  EQU     23

PEN_COLOR_TRAP_CODE     EQU     80
DRAW_PIXEL_TRAP_CODE    EQU     82
SET_OUTPUT_RESOLUTION_TRAP_CODE EQU     33

X1POSITION   EQU 36
X2POSITION   EQU 32
Y1POSITION   EQU 28
Y2POSITION   EQU 24 

DrawSprite
        movem.l INVALID_RECT_REG,-(sp)
        
        lea     SpriteBMP,a0                              ;load the address of the image file into a0
        adda    #BMP_DATA_OFFSET,a0

        moveq   #0,d1
        moveq   #0,d2
        
        move.l    X1POSITION(sp),d1
        move.l    Y2POSITION(sp),d2
     
GetNextSpriteColor:
        moveq.l  #0,d3
        moveq.l  #0,d4
        move.l   d1,d6
        
        move.b  (a0)+,d3                         ;retrieve color data
        move.b  (a0)+,d4
        move.b  (a0)+,d5
        lsl     #8,d4
        
        swap    d3
        move    d4,d3
        move.b  d5,d3
        move.l  d3,d5

        move    d1,d6
        move.l  d3,d1
        
        move.l  #PEN_COLOR_TRAP_CODE, d0         ;set the proper trap code to set the pen color
        TRAP    #15

        move.l  d6,d1
        move.l  #DRAW_PIXEL_TRAP_CODE,d0
        TRAP    #15                              ;draw pixel

SkipPixelDraw:
        move.l  d6,d1
        moveq.l #0,d6
        moveq.l #0,d7
        addq    #1,d1
        add.l   X2POSITION(sp),d7
        cmp.l   d1,d7
        
        bne     GetNextSpriteColor
        
        move.l  X1POSITION(sp),d1
        subq    #1,d2
        cmp.l   Y1POSITION(sp),d2
        bge     GetNextSpriteColor
     
SpriteDone:
        movem.l (sp)+,INVALID_RECT_REG
        rts
        
SpriteBMP   INCBIN  "paddle4.bmp"











*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
