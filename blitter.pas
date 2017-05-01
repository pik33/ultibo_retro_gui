unit blitter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Platform, HeapManager;

procedure box8(x,y,l,h,c:cardinal);

implementation

uses retromalina;

type TCtrlBlock=array[0..7] of cardinal;
     PCtrlBlock=^TCtrlBlock;

const
      dma_chn=1;                     // let blitter use dma #6
      _dma_enable=  $3F007ff0;       // DMA enable register
      _dma_cs=      $3F007000;       // DMA control and status
      _dma_conblk=  $3F007004;       // DMA ctrl block address

      _blitter_dmacb=base+$60100;     // blitter dma control block
      _blitter_color=base+$60120;     // blitter color area



var
     dma_enable:cardinal              absolute _dma_enable;   // DMA Enable register
     dma_cs:cardinal                  absolute _dma_cs+($100*dma_chn); // DMA ctrl/status
     dma_conblk:cardinal              absolute _dma_conblk+($100*dma_chn); // DMA ctrl block addr
     ctrl1: TCtrlBlock                absolute _blitter_dmacb;
     color8: array[0..15] of byte     absolute _blitter_color;
     color16: array[0..7] of word     absolute _blitter_color;
     color32: array[0..3] of cardinal absolute _blitter_color;


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

dma_enable:=dma_enable or (1 shl dma_chn);                 // enable dma channel # dma_chn
dma_conblk:=_blitter_dmacb;                                 // init DMA ctr block to ctrl block # 1

dma_cs:=$00FF0003;                                         // start DMA
repeat until (dma_cs and 2) <>0 ;
//InvalidateDataCacheRange(displaystart,$200000);

end;


end.

