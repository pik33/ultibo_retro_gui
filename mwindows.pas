unit mwindows;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const mapbase=$30800000;
      framewidth=4;
      scrollwidth=20;

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
     decoration:pointer;//+48
     visible:boolean;
     redraw:boolean;
     active:boolean;
     end;

var background:TWindow;

procedure background_init(color:byte);
function window(l,h:integer):pointer;
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

implementation

uses retromalina,blitter;



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



function window(l,h:integer):pointer;

var wh,whn:PWindow;
    i,j:integer;

begin

wh:=@background;
while wh^.next<>nil do wh:=wh^.next;

whn:=new(PWindow);


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
whn^.decoration:=nil;
whn^.next:=nil;
whn^.visible:=false;
result:=whn;
whn^.prev:=wh;
whn^.gdata:=getmem(l*h);
for i:=0 to l*h-1 do poke(cardinal(whn^.gdata)+i,0);
wh^.next:=whn;


end;

procedure destroywindow(wh:PWindow);

var i,j:integer;

begin
wh^.visible:=false;
wh^.prev^.next:=wh^.next;
if wh^.next<>nil then wh^.next^.prev:=wh^.prev;
if wh^.gdata<>nil then freemem(wh^.gdata);
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

var dt,dg,dx,dy:integer;


begin

  dg:=6;
  dt:=28;
wh^.redraw:=false;
if wh=@background then fastmove($30000000,dest,1792*1120)
else
  begin
  if wh^.x<0 then dx:=0-wh^.x else dx:=0;
  if wh^.y<0 then dy:=0-wh^.y else dy:=0;

  blit8(integer(wh^.gdata),wh^.vx+dx,wh^.vy+dy,dest,wh^.x+dx,wh^.y+dy,wh^.l-dx,wh^.h-dy,wh^.wl,1792);

  if wh^.x<dg then dx:=dg-wh^.x else dx:=0;
  if wh^.y<dt then dy:=dt-wh^.y else dy:=0;

  if wh^.next<>nil then
    begin
    if (dy<dt) then fill2d(dest,wh^.x-dg+dx,wh^.y-dt+dy,wh^.l+2*dg-dx,dt-dy,1792,15);
    if (dx<dg) then fill2d(dest,wh^.x-dg+dx,wh^.y,dg-dx,wh^.h,1792,15);
    fill2d(dest,wh^.x-dg+dx,wh^.y+wh^.h,wh^.l+2*dg-dx,dg,1792,15);
    fill2d(dest,wh^.x+wh^.l,wh^.y,dg,wh^.h,1792,15);
    end
  else
    begin
    if (dy<dt) then fill2d(dest,wh^.x-dg+dx,wh^.y-dt+dy,wh^.l+2*dg-dx,dt-dy,1792,120);
    if (dx<dg) then fill2d(dest,wh^.x-dg+dx,wh^.y,dg-dx,wh^.h,1792,120);
    fill2d(dest,wh^.x-dg+dx,wh^.y+wh^.h,wh^.l+2*dg-dx,dg,1792,120);
    fill2d(dest,wh^.x+wh^.l,wh^.y,dg,wh^.h,1792,120);
    end;
  end;
wh^.redraw:=true;

end;

function checkmouse:PWindow;

label p999;

var wh:PWindow;
    mmx,mmy,mmk,dt,dg:integer;

const state:integer=0;
      deltax:integer=0;
      deltay:integer=0;

begin
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
    while ((mmx<wh^.x-dg) or (mmx>wh^.x+wh^.l+dg) or (mmy<wh^.y-dt) or (mmy>wh^.y+wh^.h+dg)) and (wh^.prev<>nil) do wh:=wh^.prev;
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
      goto p999;
      end;
    end;

wh:=@background;
while wh^.next<>nil do wh:=wh^.next;
//if wh^.decoration=nil then
//  begin
//  dg:=0;
//  dt:=0;
//  end
//else
  begin
  dg:=6;
  dt:=28;
  end;


while ((mmx<wh^.x-dg) or (mmx>wh^.x+wh^.l+dg) or (mmy<wh^.y-dt) or (mmy>wh^.y+wh^.h+dg)) and (wh^.prev<>nil) do
  begin
  wh^.mx:=-1;
  wh^.my:=-1;
  wh^.mk:=-1;
  wh:=wh^.prev;
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

procedure wouttextxyz(wh:PWindow;x,y:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do wputcharz(wh,x+8*xz*i,y,t[i+1],c,xz,yz);
end;
end.

