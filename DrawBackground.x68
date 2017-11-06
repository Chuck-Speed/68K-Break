*-----------------------------------------------------------
* Program    : DrawBackGround.x68
* Written by : Chuck Speed
* Date       : 10/2/2015
* Description: Draws specified portion of a BMP Image provided a clipping rectangle.
*-----------------------------------------------------------
IMAGE_HEIGHT_OFFSET     EQU     22
IMAGE_WIDTH_OFFSET      EQU     18
IMAGE_DATA_OFFSET       EQU     10
BMP_DATA_OFFSET         EQU     $36

PEN_COLOR_TRAP_CODE     EQU     80
DRAW_PIXEL_TRAP_CODE    EQU     82

BACKGROUND_WIDTH        EQU 640
BACKGROUND_HEIGHT       EQU 1079

BACKGROUND_WIDTH_OFFSET  EQU 640*3
BACKGROUND_HEIGHT_OFFSET EQU 1080*3

X1_POSITION EQU 36
X2_POSITION EQU 32
Y1_POSITION EQU 28
Y2_POSITION EQU 24

DrawBackground
        movem.l INVALID_RECT_REG,-(sp)

        lea     BackgroundBMP,a0                          ;load the address of the image file into a0
        adda    #BMP_DATA_OFFSET,a0
        
        move.l    Y2_POSITION(sp),d2
        move.l    X1_POSITION(sp),d1
        
        cmp.l   #0,X2_POSITION(sp)
        ble     Done
        
        cmp.l   #0,Y2_POSITION(sp)
        ble     Done
         
        moveq   #0,d3
        moveq   #0,d4
        moveq   #0,d5
        moveq   #0,d6
        moveq   #0,d0
        
        move.l  d1,d6
        add     d1,d6
        add     d1,d6

        move    #BACKGROUND_HEIGHT,d3           ;find image data offset to begin drawing at proper coordinates
        sub     d2,d3
        move    d3,d5
        
        mulu    #BACKGROUND_WIDTH_OFFSET,d5
        add.l   d5,d0
        adda.l  d0,a0
        
        adda.l  d6,a0                           ;add image data offset to image file
        
        jmp     GetNextColor

SkipToImageDataInCurrentRow:    
        move     d6,d0    
        adda     d0,a0
        

GetNextColor:
        moveq.l  #0,d3
        
        move.b  (a0)+,d3                         ;retrieve color data
        move.b  (a0)+,d4
        lsl     #8,d4
        move.b  (a0)+,d4
        
        swap    d3
        move    d4,d3
        
        move    d1,d4
        move.l  d3,d1
         
        move.l  #PEN_COLOR_TRAP_CODE, d0         ;set the proper trap code to set the pen color
        trap    #15

        move.l  d4,d1
        move.l  #DRAW_PIXEL_TRAP_CODE,d0
       
        trap    #15                              ;draw pixel
        addq    #1,d1
        cmp.l   X2_POSITION(sp),d1
        bne     GetNextColor
        cmpi.l  #BACKGROUND_WIDTH,d1
        bne     SkipToImageDataInNextRow
        
        move.l  X1_POSITION(sp),d1
        subq    #1,d2
        cmp     Y1_POSITION(sp),d2
        bge     SkipToImageDataInCurrentRow
        blt     Done
        
SkipToImageDataInNextRow:
        move    #BACKGROUND_WIDTH,d3
        add.l   X1_POSITION(sp),d3
        sub     d1,d3
        moveq.l #0,d4
        add     d3,d4
        add     d3,d4
        add     d3,d4
        adda    d4,a0
        move.l  X1_POSITION(sp),d1
        subq    #1,d2
        cmp.l   Y1_POSITION(sp),d2
        bge     GetNextColor          
        
Done:
        movem.l (sp)+,INVALID_RECT_REG
        rts

BackgroundBMP   INCBIN  "rb640.bmp"


























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
