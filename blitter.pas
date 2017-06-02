unit blitter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Platform, HeapManager;

//procedure box8(x,y,l,h,c:cardinal);
procedure dma_blit(chn,from,x,y,too,x2,y2,len,lines,bpl1,bpl2:integer);
procedure blit8(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);
procedure fill(start,len,color:integer);
procedure fill32(start,len,color:integer);
procedure fastmove(from,too,len:integer);
//procedure blitaligned8(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);
procedure fill2d(dest,x,y,length,lines,bpl,color:integer);
//procedure dma_blit1D(from,too,len:integer);


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
  {
procedure blitaligned8(from,x,y,too,x2,y2,length,lines,bpl1,bpl2:integer);

// --- rev 21070509

label p101;

begin
                  asm
                  push {r0-r10}
                  ldr r0,from
                  ldr r1,x
                  add r0,r1
                  ldr r2,y
                  ldr r3,bpl1         //r3=bpl1
                  mul r4,r3,r2
                  add r0,r4           //r0=src start
                  and r0,#0xFFFFFFFC
                  ldr r1,too
                  ldr r2,x2
                  add r1,r2
                  ldr r4,y2
                  ldr r5,bpl2         //r5=bpl2
                  ldr r2,lines        //r2=lines
                  mul r6,r5,r4
                  add r1,r6           //r1=dest start
                  and r1,#0xFFFFFFFC
                  ldr r4,length       //r4=length

                  add r7,r1,r4

p101:             ldm r0!,{r6,r8,r9,r10}
                  stm r1!,{r6,r8,r9,r10}
                  cmps r1,r7
                  blt  p101

                  add r0,r3
                  sub r0,r4
                  add r1,r5
                  mov r7,r1
                  sub r1,r4
                  subs r2,#1
                  bgt p101
                  pop {r0-r10}
                  end;

end;



procedure box8(x,y,l,h,c:cardinal);

label p999,blitter_color;

var transfer_info2:cardinal;


begin

transfer_info2:=$00009232;   //232 to not inc

    asm
    push {r9,r10}
    ldr r10,c
    and r10,#0xFF
    add r10,r10,r10,lsl #8
    add r10,r10,r10,lsl #16
    ldr r9,blitter_color
    str r10,[r9],#4
    str r10,[r9],#4
    str r10,[r9],#4
    str r10,[r9],#4
    str r10,[r9],#4
    str r10,[r9],#4
    str r10,[r9],#4
    str r10,[r9],#4
    pop {r9,r10}
    b p999

blitter_color: .long _blitter_color
p999:
end;

cleandatacacherange (_blitter_color,32);

ctrl1[0]:=transfer_info2;                      // transfer info
ctrl1[1]:=_blitter_color;                       // source address -> buffer #1
ctrl1[2]:=$40000000+displaystart+1792*y+x;       // destination address
ctrl1[3]:=l+h shl 16;                          // transfer length
ctrl1[4]:=(1792-l) shl 16;                     // 2D
ctrl1[5]:=$0;                                  // next ctrl block -> 0
ctrl1[6]:=$0;                                  // unused
ctrl1[7]:=$0;                                  // unused
CleanDataCacheRange(_blitter_dmacb,32);        // now push this into RAM

// Init the hardware

dma_enable:=dma_enable or (1 shl blit_dma_chn);                 // enable dma channel # dma_chn
dma_conblk:=_blitter_dmacb;                                 // init DMA ctr block to ctrl block # 1

dma_cs:=$00FF0003;                                         // start DMA
repeat until (dma_cs and 2) <>0 ;
//InvalidateDataCacheRange(displaystart,$200000);

end;


procedure dma_blit32(from,x,y,too,x2,y2,len,lines,bpl1,bpl2:integer);


var transfer_info2:cardinal;


begin

transfer_info2:=$00008332;   //burst=8, 2D

ctrl1[0]:=transfer_info2;                       // transfer info
ctrl1[1]:=from+4*x+4*bpl1*y;                    // source address -> buffer #1
ctrl1[2]:=too+4*x2+4*bpl2*y2;                   // destination address
ctrl1[3]:=4*len+(lines shl 16);                 // transfer length
ctrl1[4]:=((bpl2-len) shl 18)+((bpl1-len) shl 2); // 2D
ctrl1[5]:=$0;                                   // next ctrl block -> 0
ctrl1[6]:=$0;                                   // unused
ctrl1[7]:=$0;                                   // unused
CleanDataCacheRange(_blitter_dmacb,32);         // now push this into RAM

// Init the hardware

dma_enable:=dma_enable or (1 shl blit_dma_chn);                 // enable dma channel # dma_chn
dma_conblk:=nocache+_blitter_dmacb;                                // init DMA ctr block to ctrl block # 1
dma_cs:=$00FF0003;                                         // start DMA
repeat until (dma_cs and 2) <>0 ;
//InvalidateDataCacheRange(displaystart,$200000);

end;
 }

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
if x2+len>1791 then len:=1792-x2;
if y2+lines>1119 then lines:=1120-y2;
if len<1 then goto p999;
if lines<1 then goto p999;

transfer_info2:=$00009332;                      //burst=9, 2D
cs:=Pcardinal(_dma_cs+$100*chn);
conblk:=Pcardinal(_dma_conblk+$100*chn);
ctrl1[chn,0]:=transfer_info2;                       // transfer info
ctrl1[chn,1]:=from+x+bpl1*y+$80000000;                        // source address -> buffer #1
ctrl1[chn,2]:=too+x2+bpl2*y2;                       // destination address
ctrl1[chn,3]:=len+(lines shl 16);                   // transfer length
ctrl1[chn,4]:=((bpl2-len) shl 16)+((bpl1-len));     // 2D
ctrl1[chn,5]:=$0;                                   // next ctrl block -> 0
ctrl1[chn,6]:=$0;                                   // unused
ctrl1[chn,7]:=$0;                                   // unused
CleanDataCacheRange(_blitter_dmacb+$20*chn,32);     // now push this into RAM
cleandatacacherange(from+x+y*bpl1,lines*bpl1);  // source range cache clean
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

{
procedure old_dma_blit(from,x,y,too,x2,y2,len,lines,bpl1,bpl2:integer);

var transfer_info2:cardinal;

begin

transfer_info2:=$00009332;   //burst=8, 2D

ctrl1[0]:=transfer_info2;                       // transfer info
ctrl1[1]:=from+x+bpl1*y;                        // source address -> buffer #1
ctrl1[2]:=too+x2+bpl2*y2;                       // destination address
ctrl1[3]:=len+(lines shl 16);                   // transfer length
ctrl1[4]:=((bpl2-len) shl 16)+((bpl1-len));     // 2D
ctrl1[5]:=$0;                                   // next ctrl block -> 0
ctrl1[6]:=$0;                                   // unused
ctrl1[7]:=$0;                                   // unused
CleanDataCacheRange(_blitter_dmacb,32);         // now push this into RAM
cleandatacacherange(from+x+y*bpl1,lines*bpl1);  // source range cache clean
cleanDataCacheRange(too+x2+y2*bpl2,lines*bpl2); // destination range cache clean

// Init the hardware
//while (dma_cs and 1)=1 do sleep(0);
dma_enable:=dma_enable or (1 shl blit_dma_chn); // enable dma channel # dma_chn
dma_conblk:=nocache+_blitter_dmacb;             // init DMA ctr block
dma_cs:=$00FF0003;                              // start DMA
repeat  until (dma_cs and 1) =0 ;               //
//dma_enable:=dma_enable and ($FFFFFFFE shl blit_dma_chn);                 // disable dma channel
InvalidateDataCacheRange(too+x2+y2*bpl2,lines*bpl2);                     // !!!
end;


procedure dma_blit1D(from,too,len:integer);

var transfer_info2:cardinal;

begin

transfer_info2:=$00009330;                  //burst=8, 2D

ctrl1[0]:=transfer_info2;                       // transfer info
ctrl1[1]:=from;                        // source address -> buffer #1
ctrl1[2]:=too;                       // destination address
ctrl1[3]:=len;                   // transfer length
ctrl1[4]:=0;     // 2D
ctrl1[5]:=$0;                                   // next ctrl block -> 0
ctrl1[6]:=$0;                                   // unused
ctrl1[7]:=$0;                                   // unused
CleanDataCacheRange(_blitter_dmacb,32);         // now push this into RAM
cleandatacacherange(from,len);  // source range cache clean
cleanDataCacheRange(too,len);// destination range cache clean

// Init the hardware
//while (dma_cs and 1)=1 do sleep(0);
dma_enable:=dma_enable or (1 shl blit_dma_chn); // enable dma channel # dma_chn
dma_conblk:=nocache+_blitter_dmacb;             // init DMA ctr block
dma_cs:=$00FF0003;                              // start DMA
repeat  until (dma_cs and 1) =0 ;               //
//dma_enable:=dma_enable and ($FFFFFFFE shl blit_dma_chn);                 // disable dma channel
InvalidateDataCacheRange(too,len);                     // !!!
end;
 }
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
if x+length>1791 then length:=1792-x;
if y+lines>1119 then lines:=1120-y;
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

