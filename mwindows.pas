unit mwindows;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const mapbase=$30800000;
      framewidth=4;



type PDecoration=^TDecoration;

     TDecoration=record
     title:pointer;
     hscroll,vscroll,up,down,close:boolean;
     end;

type PWindow=^Twindow;

     Twindow=record  // dont change the field order or the asm procedures will crash
     handle:PWindow;                                    //+0
     prev,next:PWindow;
     x,y:integer;   // position on screen               //+4 +8
     l,h:integer;   // dmensions on screen              //+12 +16
     vx,vy:integer; // visible upper left               //+20 +24
     mx,my,mk:integer;
     wl,wh:integer; // windows l,h                      //+28 +32
     background:integer;                                //+36
     gdata:pointer; // graphic memory                   //+40
     decoration:pDecoration;//+48
     visible:boolean;
     redraw:boolean;
     active:boolean;
     title:string;
     end;

var background:TWindow;
    activecolor:integer=120;
    inactivecolor:integer=15;
    activetextcolor:integer=15;
    inactivetextcolor:integer=0;
    borderwidth:integer=6;
    scrollwidth:integer=16;
    borderdelta:integer=-2;
    scrollcolor:integer=12;
    activescrollcolor:integer=10;
    titleheight:integer=24;
    icon:array[0..15,0..15] of byte;

procedure background_init(color:byte);
function window(l,h:integer; title:string):pointer;
procedure destroywindow(wh:PWindow);
procedure drawwindow(wh:PWindow; dest:integer);
procedure movewindow(wh:PWindow;x,y,l,h,vx,vy:integer);
procedure wcls(wh:PWindow;c:integer);
procedure wputpixel(wh:PWindow; x,y,color:integer); inline;
procedure wputchar(wh:PWindow; x,y:integer;ch:char;col:integer);
procedure wputcharz(wh:PWindow;x,y:integer;ch:char;col,xz,yz:integer);
procedure wouttextxy(wh:PWindow;x,y:integer; t:string;c:integer);
procedure wouttextxyz(wh:PWindow;x,y:integer; t:string;c,xz,yz:integer);
function checkmouse:PWindow;
procedure selectwindow(wh:PWindow);
procedure gouttextxy(g:pointer;x,y:integer; t:string;c:integer);
procedure gputpixel(g:pointer; x,y,color:integer); inline;
procedure makeicon;



implementation

uses retromalina,blitter,retro;



procedure background_init(color:byte);

begin
background.handle:=@background;
background.prev:=nil;
background.next:=nil;
background.x:=0;
background.y:=0;                       // position on screen
background.l:=1792;
background.h:=1792;                    // dimensions on screen
background.vx:=0;
background.vy:=0;                      // visible upper left
background.wl:=1792;
background.wh:=1120;                   // windows l,h
background.background:=147;            // backround color
background.gdata:=pointer($30000000);  // graphic memory
background.decoration:=nil;            //+48
background.visible:=true;
background.redraw:=true;
end;



function window(l,h:integer; title:string):pointer;

var wh,whn:PWindow;
    i,j:integer;
    decoration:PDecoration;
begin

wh:=@background;
while wh^.next<>nil do wh:=wh^.next;

whn:=new(PWindow);
makeicon;

whn^.handle:=whn;
whn^.x:=0;
whn^.y:=0;
whn^.mx:=-1;
whn^.my:=-1;
whn^.mk:=0;
whn^.vx:=0;
whn^.vy:=0;
whn^.l:=0;
whn^.h:=0;
whn^.background:=0;
whn^.wl:=l;
whn^.wh:=h;

whn^.next:=nil;
whn^.visible:=false;
result:=whn;
whn^.prev:=wh;
whn^.gdata:=getmem(l*h);
//wbox(whn,0,0,whn^.wx,24,
for i:=0 to l*h-1 do poke(cardinal(whn^.gdata)+i,0);
decoration:=new(PDecoration);

whn^.title:=title;

decoration^.title:=getmem(whn^.wl*titleheight);
decoration^.hscroll:=true;
decoration^.vscroll:=true;
decoration^.up:=true;
decoration^.down:=true;
decoration^.close:=true;
whn^.decoration:=decoration;
wh^.next:=whn;


end;

procedure destroywindow(wh:PWindow);

var i,j:integer;

begin
wh^.visible:=false;
wh^.prev^.next:=wh^.next;
if wh^.next<>nil then wh^.next^.prev:=wh^.prev;
if wh^.gdata<>nil then freemem(wh^.gdata);
if wh^.decoration<>nil then
  begin
  if wh^.decoration^.title<>nil then freemem(wh^.decoration^.title);
  dispose(wh^.decoration);
  end;
dispose(wh);
end;

procedure movewindow(wh:PWindow;x,y,l,h,vx,vy:integer);

begin

if l>0 then wh^.l:=l;        // now set new window parameters
if h>0 then wh^.h:=h;
if x>-2048 then wh^.x:=x;
if y>-2048 then wh^.y:=y;
if vx>-2048 then wh^.vx:=vx;
if vy>-2048 then wh^.vy:=vy;

end;


procedure drawwindow(wh:PWindow;dest:integer);

var dt,dg,dh,dx,dy,dl,dsh,dsv,i,j:integer;
   wt:int64;

begin

wh^.redraw:=false;

if wh^.decoration=nil then
  begin
  dg:=0;
  dh:=0;
  dt:=0;
  dl:=0;
  dsh:=0;
  dsv:=0;
  end
else
  begin
  dt:= titleheight;
  dl:=borderwidth;
  dg:=borderwidth;
  dh:=borderwidth;
  if wh^.decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
  if wh^.decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
  end;


if wh=@background then begin wt:=gettime; fastmove($30000000,dest,1792*1120);  wt:=gettime-wt; box(100,100,200,100,0); outtextxyz(100,100,inttostr(wt),15,2,2); end
else
  begin
  wt:=gettime;
  if wh^.x<0 then dx:=0-wh^.x else dx:=0;
  if wh^.y<0 then dy:=0-wh^.y else dy:=0;

  {blit8} dma_blit(integer(wh^.gdata),wh^.vx+dx,wh^.vy+dy,dest,wh^.x+dx,wh^.y+dy,wh^.l-dx,wh^.h-dy,wh^.wl,1792);

  if wh^.x<dl then dx:=dl-wh^.x else dx:=0;
  if wh^.y<(dt+dl) then dy:=dt+dl-wh^.y else dy:=0;

  if wh^.next<>nil then
    begin
    if (dy<dt+dl) then fill2d(dest, wh^.x-dl+dx, wh^.y+dy-dt-dl, wh^.l-dx+dl +dsv ,dl-dy,1792,inactivecolor+borderdelta);
    if (dy<dt) then fill2d(dest,wh^.x-dl+dx,wh^.y-dt+dy,wh^.l-dx+dl+dsv,dt-dy,1792,inactivecolor);
    if (dx<dl) then fill2d(dest,wh^.x-dl+dx,wh^.y-dt-dl,dl-dx,wh^.h+dt+dl+dsh+dh-dy,1792,inactivecolor+borderdelta);
    fill2d(dest, wh^.x-dl+dx, wh^.y+wh^.h+dsh, wh^.l+dl+dg-dx+dsv,dh,1792,inactivecolor+borderdelta);
    fill2d(dest, wh^.x+dx, wh^.y+wh^.h, wh^.l-dx,dsh,1792,scrollcolor);
    fill2d(dest, wh^.x+wh^.l+dsv, wh^.y+dy-dt-dl,dg,wh^.h+dt+dl+dsh+dl,1792,inactivecolor+borderdelta);
    fill2d(dest, wh^.x+wh^.l, wh^.y+dy,dsv,wh^.h,1792,scrollcolor);
    fill2d(dest, wh^.x+wh^.l, wh^.y+wh^.h,dsv,dsh,1792,inactivecolor);
    gouttextxy(pointer(dest),wh^.x+32,wh^.y-20,wh^.title,inactivetextcolor);
    for i:=0 to 15 do for j:=0 to 15 do if down_icon[i+16*j]>0 then gputpixel(pointer(dest),wh^.x+wh^.l+dsv-60+i,wh^.y-20+j,down_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if up_icon[i+16*j]>0 then gputpixel(pointer(dest),wh^.x+wh^.l+dsv-40+i,wh^.y-20+j,up_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if close_icon[i+16*j]>0 then gputpixel(pointer(dest),wh^.x+wh^.l+dsv-20+i,wh^.y-20+j,close_icon[i+16*j]);
//    gouttextxy(pointer(dest),wh^.x+wh^.l+dsv-54,wh^.y-20,'_',inactivetextcolor);
//    gouttextxy(pointer(dest),wh^.x+wh^.l+dsv-38,wh^.y-32,'_',inactivetextcolor);
//    gouttextxy(pointer(dest),wh^.x+wh^.l+dsv-22,wh^.y-22,'x',inactivetextcolor);

    for i:=0 to 15 do for j:=0 to 15 do if icon[i,j]>0 then gputpixel(pointer(dest),wh^.x+4+i,wh^.y-20+j,icon[i,j]);
    end
  else
    begin
    if (dy<dt+dl) then fill2d(dest, wh^.x-dl+dx, wh^.y+dy-dt-dl, wh^.l-dx+dl +dsv ,dl-dy,1792,activecolor+borderdelta);
    if (dy<dt) then fill2d(dest,wh^.x-dl+dx,wh^.y-dt+dy,wh^.l-dx+dl+dsv,dt-dy,1792,activecolor);
    if (dx<dl) then fill2d(dest,wh^.x-dl+dx,wh^.y-dt-dl,dl-dx,wh^.h+dt+dl+dsh+dh-dy,1792,activecolor+borderdelta);
    fill2d(dest, wh^.x-dl+dx, wh^.y+wh^.h+dsh, wh^.l+dl+dg-dx+dsv,dh,1792,activecolor+borderdelta);
    fill2d(dest, wh^.x+dx, wh^.y+wh^.h, wh^.l-dx,dsh,1792,scrollcolor);
    fill2d(dest, wh^.x+wh^.l+dsv, wh^.y+dy-dt-dl,dg,wh^.h+dt+dl+dsh+dl,1792,activecolor+borderdelta);
    fill2d(dest, wh^.x+wh^.l, wh^.y+dy,dsv,wh^.h,1792,scrollcolor);
    fill2d(dest, wh^.x+wh^.l, wh^.y+wh^.h,dsv,dsh,1792,activecolor);
    gouttextxy(pointer(dest),wh^.x+32,wh^.y-20,wh^.title,activetextcolor);
//    gouttextxy(pointer(dest),wh^.x+wh^.l+dsv-54,wh^.y-20,'_',activetextcolor);
//    gouttextxy(pointer(dest),wh^.x+wh^.l+dsv-38,wh^.y-32,'_',activetextcolor);
//    gouttextxy(pointer(dest),wh^.x+wh^.l+dsv-22,wh^.y-22,'x',activetextcolor);
    for i:=0 to 15 do for j:=0 to 15 do if icon[i,j]>0 then gputpixel(pointer(dest),wh^.x+4+i,wh^.y-20+j,icon[i,j]);
    for i:=0 to 15 do for j:=0 to 15 do if down_icon[i+16*j]>0 then gputpixel(pointer(dest),wh^.x+wh^.l+dsv-60+i,wh^.y-20+j,down_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if up_icon[i+16*j]>0 then gputpixel(pointer(dest),wh^.x+wh^.l+dsv-40+i,wh^.y-20+j,up_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if close_icon[i+16*j]>0 then gputpixel(pointer(dest),wh^.x+wh^.l+dsv-20+i,wh^.y-20+j,32+close_icon[i+16*j]);
//    for i:=0 to 15 do for j:=0 to 15 do if icon[i,j]>0 then gputpixel(pointer(dest),wh^.x+4+i,wh^.y-20+j,icon[i,j]);
//    for i:=0 to 15 do for j:=0 to 15 do if icon[i,j]>0 then gputpixel(pointer(dest),wh^.x+4+i,wh^.y-20+j,icon[i,j]);
    end;
  end;
wh^.redraw:=true;
  wt:=gettime-wt;
  wh^.title:='Window time='+inttostr(wt)+' us';
end;

function checkmouse:PWindow;

label p999;

var wh:PWindow;
    mmx,mmy,mmk,dt,dg,dh,dl,dsh,dsv:integer;

const state:integer=0;
      deltax:integer=0;
      deltay:integer=0;

begin

result:=@background;

mmx:=mousex;
mmy:=mousey;
mmk:=mousek;

  dg:=6;
  dt:=28;

if mmk=0 then state:=0;

if (state=0) and (mmk=2) then
    begin
    wh:=@background;
    while wh^.next<>nil do wh:=wh^.next;

    if wh^.decoration=nil then
      begin
      dg:=0;
      dh:=0;
      dt:=0;
      dl:=0;
      dsh:=0;
      dsv:=0;
      end
    else
      begin
      dt:= titleheight;
      dl:=borderwidth;
      dg:=borderwidth;
      dh:=borderwidth;
      if wh^.decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
      if wh^.decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
      end;

    while ((mmx<wh^.x-dl) or (mmx>wh^.x+wh^.l+dg+dsv) or (mmy<wh^.y-dt-dg) or (mmy>wh^.y+wh^.h+dh+dsh)) and (wh^.prev<>nil) do wh:=wh^.prev;
    if wh<>@background then destroywindow(wh);
    state:=4;
    goto p999;
    end;

  if mmk=1 then // find a window with mk=1
    begin
    wh:=@background;
    while (wh^.next<>nil) and (wh^.mk<>1) do wh:=wh^.next;
    if wh^.mk=1 then
      begin
      if state=0 then movewindow(wh,mmx-wh^.mx,mmy-wh^.my,0,0,0,0)
      else if state=1 then movewindow(wh,wh^.x,wh^.y, mmx-wh^.x+deltax ,wh^.h,0,0)
      else if state=2 then movewindow(wh,wh^.x,wh^.y, wh^.l, mmy-wh^.y+deltay ,0,0)
      else movewindow(wh,wh^.x,wh^.y, mmx-wh^.x+deltax ,mmy-wh^.y+deltay, 0,0);
      result:=wh;
      goto p999;
      end;
    end;

wh:=@background;
while wh^.next<>nil do wh:=wh^.next;


    if wh^.decoration=nil then
      begin
      dg:=0;
      dh:=0;
      dt:=0;
      dl:=0;
      dsh:=0;
      dsv:=0;
      end
    else
      begin
      dt:= titleheight;
      dl:=borderwidth;
      dg:=borderwidth;
      dh:=borderwidth;
      if wh^.decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
      if wh^.decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
      end ;

while ((mmx<wh^.x-dg) or (mmx>wh^.x+wh^.l+dg+dsv) or (mmy<wh^.y-dt-dg) or (mmy>wh^.y+wh^.h+dh+dsh)) and (wh^.prev<>nil) do
  begin
  wh^.mx:=-1;
  wh^.my:=-1;
  wh^.mk:=-1;
  wh:=wh^.prev;

  if wh^.decoration=nil then
    begin
    dg:=0;
    dh:=0;
    dt:=0;
    dl:=0;
    dsh:=0;
    dsv:=0;
    end
  else
    begin
    dt:= titleheight;
    dl:=borderwidth;
    dg:=borderwidth;
    dh:=borderwidth;
    if wh^.decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
    if wh^.decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
    end



  end;
result:=wh;
if (mmk=1) and (wh^.mk=0) then selectwindow(wh);
if (mmk=1) and (wh^.mk=1) and (wh<>@background) then begin lpoke($2f06000c,$FF0000);movewindow(wh,mmx-wh^.mx,mmy-wh^.my,0,0,0,0) ;end
else
  begin
  wh^.mx:=mmx-wh^.x;
  wh^.my:=mmy-wh^.y;
  wh^.mk:=mmk;
  end;
if (mmx<(wh^.x+wh^.l)) and (mmy<(wh^.y+wh^.h)) then begin state:=0; deltax:=0; deltay:=0 end
else if (mmx>=(wh^.x+wh^.l)) and (mmy<(wh^.y+wh^.h)) then begin state:=1; deltax:=wh^.x+wh^.l-mmx; deltay:=0; end
else if (mmx<(wh^.x+wh^.l)) and (mmy>=(wh^.y+wh^.h)) then begin state:=2; deltax:=0; deltay:=wh^.y+wh^.h-mmy;end
else begin state:=3; deltax:=wh^.x+wh^.l-mmx; deltay:=wh^.y+wh^.h-mmy; end ;

p999:
end;

procedure selectwindow(wh:PWindow);

var whh:PWindow;

begin
if (wh^.next<>nil) and (wh<>@background) then
  begin
  wh^.prev^.next:=wh^.next;
  wh^.next^.prev:=wh^.prev;
  whh:=wh;
  repeat whh:=whh^.next until whh^.next=nil;
  wh^.next:=nil;
  wh^.prev:=whh;
  whh^.next:=wh;
  end;
end;

procedure wcls(wh:PWindow;c:integer);

// --- rev 20170502

var i,l:integer;


begin
c:=c mod 256;
l:=wh^.wl*wh^.wh;
for i:=0 to l-1 do poke(cardinal(wh^.gdata)+i,c);
end;

procedure wputpixel(wh:PWindow; x,y,color:integer); inline;

label p999;

var adr:integer;

begin
if (x<0) or (x>=wh^.wl) or (y<0) or (y>wh^.wh) then goto p999;
adr:=cardinal(wh^.gdata)+x+wh^.wl*y;
poke(adr,color);
p999:
end;

procedure gputpixel(g:pointer; x,y,color:integer); inline;

label p999;

var adr:integer;

begin
if (x<0) or (x>=1792) or (y<0) or (y>1120) then goto p999;
adr:=cardinal(g)+x+1792*y;
poke(adr,color);
p999:
end;

procedure wputchar(wh:PWindow; x,y:integer;ch:char;col:integer);

// --- TODO: translate to asm, use system variables
// --- rev 20170111
var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      wputpixel(wh,x+j,y+i,col);
    end;
  end;
end;

procedure gputchar(g:pointer; x,y:integer;ch:char;col:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      gputpixel(g,x+j,y+i,col);
    end;
  end;
end;

procedure wputcharz(wh:PWindow;x,y:integer;ch:char;col,xz,yz:integer);


var i,j,k,l:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      for k:=0 to yz-1 do
        for l:=0 to xz-1 do
           wputpixel(wh,x+j*xz+l,y+i*yz+k,col);
    end;
  end;
end;

procedure wouttextxy(wh:PWindow;x,y:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do wputchar(wh,x+8*i-8,y,t[i],c);
end;

procedure gouttextxy(g:Pointer;x,y:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do gputchar(g,x+8*i-8,y,t[i],c);
end;

procedure wouttextxyz(wh:PWindow;x,y:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do wputcharz(wh,x+8*xz*i,y,t[i+1],c,xz,yz);
end;

procedure wbox(wh:PWindow;x,y,l,h,c:integer);

label p101,p102,p999;

var screenptr:cardinal;
    xres,yres:integer;

begin

screenptr:=integer(wh^.gdata);
xres:=wh^.wl;
yres:=wh^.wh;
if x<0 then begin l:=l+x; x:=0; if l<1 then goto p999; end;
if x>=xres then goto p999;
if y<0 then begin h:=h+y; y:=0; if h<1 then goto p999; end;
if y>=yres then goto p999;
if x+l>=xres then l:=xres-x;
if y+h>=yres then h:=yres-y;


             asm
             push {r0-r6}
             ldr r2,y
             ldr r3,xres
             ldr r1,x
             mul r3,r3,r2
             ldr r4,l
             add r3,r1
             ldr r0,screenptr
             add r0,r3
             ldrb r3,c
             ldr r6,h

p102:        mov r5,r4
p101:        strb r3,[r0],#1  // inner loop
             subs r5,#1
             bne p101
             ldr r1,xres
             add r0,r1
             sub r0,r4
             subs r6,#1
             bne p102

             pop {r0-r6}
             end;

p999:
end;


procedure makeicon;

var x,y,q:integer;

begin
for x:=0 to 15 do
  for y:=0 to 15 do
    begin
    q:=balls[2*x+2*y*32];
    if ((q shr 8) and 255) >= (q and 255) then icon[x,y]:=((q and 255) shr 4) else icon[x,y]:=32+(q and 255) shr 4;
    if q=0 then icon[x,y]:=0;
    end;
end;



end.

