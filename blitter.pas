unit blitter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Platform, HeapManager;

procedure dma_blit(chn,from,x,y,too,x2,y2,len,lines,bpl1,bpl2:integer);
procedure blit8(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);
//procedure aligned_blit8(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);
procedure fill(start,len,color:integer);
procedure fill32(start,len,color:integer);
procedure fastmove(from,too,len:integer);
procedure fill2d(dest,x,y,length,lines,bpl,color:integer);
procedure fill2d32(dest,x,y,length,lines,bpl:integer;color:cardinal);


implementation

uses retromalina;

type TCtrlBlock=array[0..15,0..7] of cardinal;
     PCtrlBlock=^TCtrlBlock;

const
      blit_dma_chn=9;                                 // let blitter use dma #6
      _dma_enable=  $3F007ff0;                        // DMA enable register
      _dma_cs=      $3F007000;                        // DMA control and status
      _dma_conblk=  $3F007004;                        // DMA ctrl block address

      _blitter_dmacb=base+$60100;                     // blitter dma control block
      _blitter_color=base+$60120;                     // blitter color area
      nocache=$C0000000;                              // disable GPU cache


var
     dma_enable:cardinal              absolute _dma_enable;                       // DMA Enable register
     dma_cs:cardinal                  absolute _dma_cs+($100*blit_dma_chn);       // DMA ctrl/status
     dma_conblk:cardinal              absolute _dma_conblk+($100*blit_dma_chn);   // DMA ctrl block addr
     ctrl1: TCtrlBlock                absolute _blitter_dmacb;
     color8: array[0..15] of byte     absolute _blitter_color;
     color16: array[0..7] of word     absolute _blitter_color;
     color32: array[0..3] of cardinal absolute _blitter_color;


procedure blit8(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);

// --- rev 21070509

label p101,p999;

begin
if (length<=0) or (lines<=0) then goto p999;

                  asm
                  push {r0-r7}
                  ldr r0,from
                  ldr r1,x
                  add r0,r1
                  ldr r2,y
                  ldr r3,bpl1         //r3=bpl1
                  mul r4,r3,r2
                  add r0,r4           //r0=src start
                  ldr r1,too
                  ldr r2,x2
                  add r1,r2
                  ldr r4,y2
                  ldr r5,bpl2         //r5=bpl2
                  ldr r2,lines        //r2=lines
                  mul r6,r5,r4
                  add r1,r6           //r1=dest start
                  ldr r4,length       //r4=length

                  add r7,r1,r4

p101:             ldrb r6,[r0],#1
                  strb r6,[r1],#1
                  cmps r1,r7
                  blt  p101

                  add r0,r3
                  sub r0,r4
                  add r1,r5
                  mov r7,r1
                  sub r1,r4
                  subs r2,#1
                  bgt p101
                  pop {r0-r7}
                  end;
p999:
end;




procedure dma_blit(chn,from,x,y,too,x2,y2,len,lines,bpl1,bpl2:integer);

label p999;

var transfer_info2:cardinal;
    cs:Pcardinal;          //         absolute _dma_cs+($100*blit_dma_chn);       // DMA ctrl/status
    conblk:Pcardinal;        //      absolute _dma_conblk+($100*blit_dma_chn);   // DMA ctrl block addr

begin
//cleandatacacherange(from+x+y*bpl1,lines*bpl1);  // source range cache clean

if len<1 then goto p999;
if x+len>bpl1 then len:=bpl1-x;
if x2<0 then
  begin
  x:=x-x2;
  len:=len+x2;
  x2:=0;
  if len<1 then goto p999;
  end;
if y2<0 then
  begin
  y:=y-y2;
  lines:=lines+y2;
  if lines<1 then goto p999;
  y2:=0;
  end;
if (x2+len)>(xres-1) then len:=xres-x2;
if (y2+lines)>(yres-1) then lines:=yres-y2;
if len<1 then goto p999;
if lines<1 then goto p999;

transfer_info2:=$00009332;                      //burst=9, 2D
cs:=Pcardinal(_dma_cs+$100*chn);
conblk:=Pcardinal(_dma_conblk+$100*chn);
ctrl1[chn,0]:=transfer_info2;                       // transfer info
ctrl1[chn,1]:=from+x+bpl1*y+$80000000;                        // source address -> buffer #1
ctrl1[chn,2]:=too+x2+bpl2*y2;                       // destination address
ctrl1[chn,3]:=len+((lines-1) shl 16);                   // transfer length  - why lines-1 ??
ctrl1[chn,4]:=((bpl2-len) shl 16)+((bpl1-len));     // 2D
ctrl1[chn,5]:=$0;                                   // next ctrl block -> 0
ctrl1[chn,6]:=$0;                                   // unused
ctrl1[chn,7]:=$0;                                   // unused
CleanDataCacheRange(_blitter_dmacb+$20*chn,32);     // now push this into RAM
cleandatacacherange(from+x+y*bpl1,(lines+1)*bpl1);  // source range cache clean
cleanDataCacheRange(too+x2+y2*bpl2,(lines+1)*bpl2); // destination range cache clean

// Init the hardware
//cs^:=$80EE0003;
dma_enable:=dma_enable or (1 shl chn); // enable dma channel # dma_chn
conblk^:=nocache+_blitter_dmacb+$20*chn;             // init DMA ctr block
cs^:=$00110003;                              // start DMA
repeat until (cs^ and 1) =0 ;                //
InvalidateDataCacheRange(too+x2+y2*bpl2,(lines+1)*bpl2);                     // !!!
p999:
end;


procedure fill(start,len,color:integer);

label p101 ;

begin
           asm
           push {r0-r12}
           ldr r12,len
           ldr r10,start
           add r12,r10
           ldrb r0,color
           add r0,r0,r0,lsl #8
           add r0,r0,r0,lsl #16
           mov r1,r0
           mov r2,r0
           mov r3,r0
           mov r4,r0
           mov r5,r0
           mov r6,r0
           mov r7,r0
p101:      stm r10!,{r0-r7}
           stm r10!,{r0-r7}
           stm r10!,{r0-r7}
           stm r10!,{r0-r7}
           stm r10!,{r0-r7}
           stm r10!,{r0-r7}
           stm r10!,{r0-r7}
           stm r10!,{r0-r7}
           cmps r10,r12
           blt p101
           pop {r0-r12}
           end;

end;

procedure fill2d(dest,x,y,length,lines,bpl,color:integer);

// --- rev 21070509

label p101,p999;

begin
if length<1 then goto p999;
if x<0 then
  begin
  length:=length+x;
  x:=0;
  if length<1 then goto p999;
  end;
if y<0 then
  begin
  lines:=lines+y;
  if lines<1 then goto p999;
  y:=0;
  end;
if (x+length)>(xres-1) then length:=xres-x;
if (y+lines)>(yres-1) then lines:=yres-y;
if length<1 then goto p999;
if lines<1 then goto p999;

                  asm
                  push {r0-r7}

                  ldr r1,dest
                  ldr r2,x
                  add r1,r2
                  ldr r4,y
                  ldr r5,bpl         //r5=bpl2
                  ldr r2,lines        //r2=lines
                  mul r6,r5,r4
                  add r1,r6           //r1=dest start
                  ldr r4,length       //r4=length
                  ldrb r6,color
                  add r7,r1,r4

p101:             strb r6,[r1],#1
                  cmps r1,r7
                  blt  p101

                  add r0,r3
                  sub r0,r4
                  add r1,r5
                  mov r7,r1
                  sub r1,r4
                  subs r2,#1
                  bgt p101
                  pop {r0-r7}
                  end;
p999:
end;

procedure fill2d32(dest,x,y,length,lines,bpl:integer;color:cardinal);

// --- rev 21071004

label p101,p999;

begin
if length<1 then goto p999;
if x<0 then
  begin
  length:=length+x;
  x:=0;
  if length<1 then goto p999;
  end;
if y<0 then
  begin
  lines:=lines+y;
  if lines<1 then goto p999;
  y:=0;
  end;
if length<1 then goto p999;
if lines<1 then goto p999;

                  asm
                  push {r0-r7}
                  ldr r1,dest           // r1:=dest;
                  ldr r2,x              // r2:=x;
                  add r1,r1,r2,lsl #2   // r1:=r1+r2*4   - pointer to the start
                  ldr r4,y              // r4:=y;
                  ldr r5,bpl            // r5=bpl;
                  ldr r2,lines          // r2:=lines;
                  mul r6,r5,r4          // r6:=lines*bpl; bpl - bytes per line
                  add r1,r6             // r1=:r1+y*bpl
                  ldr r4,length         // r4:=length in pixels
                  ldr r6,color          // r6:=color
                  add r7,r1,r4,lsl #2   // r7:=r1+r4*4

p101:             str r6,[r1],#4
                  cmps r1,r7
                  blt  p101             // fill the line

                  add r1,r5             // end of the next line
                  add r7,r5
                  sub r1,r1,r4,lsl #2
                  subs r2,#1
                  bgt p101
                  pop {r0-r7}
                  end;
p999:
end;

procedure fill32(start,len,color:integer);

label p101 ;

begin
     asm
     push {r0-r12}
     ldr r12,len
     ldr r10,start
     add r12,r10
     ldr r0,color
//     add r0,r0,r0,lsl #8
//     add r0,r0,r0,lsl #16
     mov r1,r0
     mov r2,r0
     mov r3,r0
     mov r4,r0
     mov r5,r0
     mov r6,r0
     mov r7,r0
p101:     stm r10!,{r0-r7}
     stm r10!,{r0-r7}
     stm r10!,{r0-r7}
     stm r10!,{r0-r7}
     stm r10!,{r0-r7}
     stm r10!,{r0-r7}
     stm r10!,{r0-r7}
     stm r10!,{r0-r7}
     cmps r10,r12
     blt p101
     pop {r0-r12}
     end;

end;

procedure fastmove(from,too,len:integer);

label p101 ;

begin
     asm
     push {r0-r12}
     ldr r12,len
     ldr r9,from
     add r12,r9
     ldr r10,too


p101:
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}

     cmps r9,r12
     blt p101
     pop {r0-r12}
     end;

end;


end.

