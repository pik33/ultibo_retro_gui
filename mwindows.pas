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

type //PWindow=^Twindow;

     window=class(TObject)  // dont change the field order or the asm procedures will crash
     handle:Window;                                    //+0
     prev,next:Window;
     x,y:integer;   // position on screen               //+4 +8
     l,h:integer;   // dmensions on screen              //+12 +16
     vx,vy:integer; // visible upper left               //+20 +24
     mx,my,mk:integer;
     wl,wh:integer; // windows l,h                      //+28 +32
     bg:integer;                                //+36
     gdata:pointer; // graphic memory                   //+40
     decoration:pDecoration;//+48
     visible:boolean;
     resizable:boolean;
     redraw:boolean;
     active:boolean;
     title:string;
     constructor create (al,ah:integer; atitle:string);
     destructor destroy; override;

     procedure cls(c:integer);
     procedure putpixel(ax,ay,color:integer); inline;
     procedure putchar(ax,ay:integer;ch:char;col:integer);
     procedure putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);
     procedure outtextxy(ax,ay:integer; t:string;c:integer);
     procedure outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);
     //function checkmouse:boolean;
     procedure draw(dest:integer);
     procedure move(ax,ay,al,ah,avx,avy:integer);
     procedure box(ax,ay,al,ah,c:integer);


     end;


TThreadWindow=class(TThread)
        win:window;
        Constructor Create(al,ah:integer; atitle:string);
        end;

var background:window=nil;

    activecolor:integer=120;
    inactivecolor:integer=13;
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
//function window(l,h:integer; title:string):pointer;
function checkmouse:Window;
procedure selectwindow(wh:Window);
procedure gouttextxy(g:pointer;x,y:integer; t:string;c:integer);
procedure gputpixel(g:pointer; x,y,color:integer); inline;
procedure makeicon;



implementation

uses retromalina,blitter,retro;

constructor tthreadwindow.create(al,ah:integer; atitle:string);

begin
inherited create(true);
win:=window.create(al,ah,atitle);
end;

procedure background_init(color:byte);

begin
background.handle:=background;
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
background.bg:=147;            // backround color
background.gdata:=pointer($30000000);  // graphic memory
background.decoration:=nil;            //+48
background.visible:=true;
background.redraw:=true;
end;



constructor window.create (al,ah:integer; atitle:string);

var who:window;
    i,j:integer;

begin
inherited create;
if background<>nil then
  begin
  who:=background;
  while who.next<>nil do who:=who.next;

  makeicon;

  handle:=self;
  x:=0;
  y:=0;
  mx:=-1;
  my:=-1;
  mk:=0;
  vx:=0;
  vy:=0;
  l:=0;
  h:=0;
  bg:=0;
  wl:=al;
  wh:=ah;

  next:=nil;
  visible:=false;
  resizable:=true;
  prev:=who;
  gdata:=getmem(wl*wh);
  for i:=0 to wl*wh-1 do poke(cardinal(gdata)+i,0);
  decoration:=new(PDecoration);

  title:=atitle;

  decoration^.title:=getmem(wl*titleheight);
  decoration^.hscroll:=true;
  decoration^.vscroll:=true;
  decoration^.up:=true;
  decoration^.down:=true;
  decoration^.close:=true;
  who.next:=self;
  end
else
  begin
  handle:=self;
  prev:=nil;
  next:=nil;
  x:=0;
  y:=0;                       // position on screen
  l:=al;
  h:=ah;                    // dimensions on screen
  vx:=0;
  vy:=0;                      // visible upper left
  wl:=al;
  wh:=ah;                   // windows l,h
  bg:=147;            // backround color
  gdata:=pointer($30000000);  // graphic memory
  decoration:=nil;            //+48
  visible:=true;
  redraw:=true;     x:=0;
  mx:=-1;
  my:=-1;
  decoration:=nil;
  title:=atitle;
  end;
end;

destructor window.destroy;

var i,j:integer;

begin
visible:=false;
prev.next:=next;
if next<>nil then next.prev:=prev;
if gdata<>nil then freemem(gdata);
if decoration<>nil then
  begin
  if decoration^.title<>nil then freemem(decoration^.title);
  dispose(decoration);
  end;
end;

procedure window.move(ax,ay,al,ah,avx,avy:integer);

begin

if al>0 then l:=al;        // now set new window parameters
if ah>0 then h:=ah;

if (decoration<>nil) and (al>0) and (al<96) then l:=96;

if al>wl then l:=wl;
if ah>wh then h:=wh;



if ax>-2048 then x:=ax;
if ay>-2048 then y:=ay;
if avx>-2048 then vx:=avx;
if avy>-2048 then vy:=avy;

 end;


procedure window.draw(dest:integer);

var dt,dg,dh,dx,dy,dx2,dy2,dl,dsh,dsv,i,j,c,ct,a:integer;
   wt:int64;

begin

//redraw:=false;

if decoration=nil then
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
  dt:=titleheight;
  dl:=borderwidth;
  dg:=borderwidth;
  dh:=borderwidth;
  if decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
  if decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
  end;


if self=background then begin wt:=gettime; fastmove($30000000,dest,1792*1120);   wt:=gettime-wt; end
else
  begin
  wt:=gettime;
  dma_blit(6,integer(gdata),vx,vy,dest,x,y,l,h,wl,1792);

//  if x<dl then dx:=dl-x else dx:=0;
//  if y<(dt+dl) then dy:=dt+dl-y else dy:=0;

  if next<>nil then
    begin
    c:=inactivecolor;
    ct:=inactivetextcolor;
    a:=0;
    end
  else
    begin
    c:=activecolor;
    ct:=activetextcolor;
    a:=32
    end;

  fill2d(dest,x-dl,y-dt-dl,l+dl+dsv,dl,1792,c+borderdelta);         //upper borded
  fill2d(dest,x-dl,y-dt,l+dl+dsv,dt,1792,c);                        //title bar
  fill2d(dest,x-dl,y-dt-dl,dl,h+dt+dl+dsh+dh,1792,c+borderdelta);   //left border
  fill2d(dest,x-dl,y+h+dsh,l+dl+dg+dsv,dh,1792,c+borderdelta);      //lower border
  fill2d(dest,x+l+dsv,y-dt-dl,dg,h+dt+dl+dsh+dl,1792,c+borderdelta);//right border
  fill2d(dest,x,y+h,l,dsh,1792,scrollcolor);                        //horizontal scroll bar
  fill2d(dest,x+l,y,dsv,h,1792,scrollcolor);                        //vertical scroll bar
  fill2d(dest,x+l,y+h,dsv,dsh,1792,c);                  //down right corner
  gouttextxy(pointer(dest),x+32,y-20,title,ct);
  for i:=0 to 15 do for j:=0 to 15 do if down_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-60+i,y-20+j,down_icon[i+16*j]);
  for i:=0 to 15 do for j:=0 to 15 do if up_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-40+i,y-20+j,up_icon[i+16*j]);
  for i:=0 to 15 do for j:=0 to 15 do if close_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-20+i,y-20+j,a+close_icon[i+16*j]);
  for i:=0 to 15 do for j:=0 to 15 do if icon[i,j]>0 then gputpixel(pointer(dest),x+4+i,y-20+j,icon[i,j]);
  end;
  redraw:=true;
wt:=gettime-wt;
//title:='Window time='+inttostr(wt)+' us';
end;

function checkmouse:Window;

label p999;

var wh:Window;
    mmx,mmy,mmk,dt,dg,dh,dl,dsh,dsv:integer;

const state:integer=0;
      deltax:integer=0;
      deltay:integer=0;

begin

result:=background;

mmx:=mousex;
mmy:=mousey;
mmk:=mousek;

  dg:=6;
  dt:=28;

if mmk=0 then state:=0;

if (state=0) and (mmk=2) then
    begin
    wh:=background;
    while wh.next<>nil do wh:=wh.next;

    if wh.decoration=nil then
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
      if wh.decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
      if wh.decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
      end;

    while ((mmx<wh.x-dl) or (mmx>wh.x+wh.l+dg+dsv) or (mmy<wh.y-dt-dg) or (mmy>wh.y+wh.h+dh+dsh)) and (wh.prev<>nil) do wh:=wh.prev;
    if wh<>background then
      begin
      wh.destroy;
      state:=4;
      goto p999;
      end;
    end;

  if mmk=1 then // find a window with mk=1
    begin
    wh:=background;
    while (wh.next<>nil) and (wh.mk<>1) do wh:=wh.next;
    if wh.mk=1 then
      begin
      if state=0 then wh.move(mmx-wh.mx,mmy-wh.my,0,0,0,0)
      else if state=1 then wh.move(wh.x,wh.y, mmx-wh.x+deltax ,wh.h,0,0)
      else if state=2 then wh.move(wh.x,wh.y, wh.l, mmy-wh.y+deltay ,0,0)
      else wh.move(wh.x,wh.y, mmx-wh.x+deltax ,mmy-wh.y+deltay, 0,0);
      result:=wh;
      goto p999;
      end;
    end;

wh:=background;
while wh.next<>nil do wh:=wh.next;


    if wh.decoration=nil then
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
      if wh.decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
      if wh.decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
      end ;

while ((mmx<wh.x-dg) or (mmx>wh.x+wh.l+dg+dsv) or (mmy<wh.y-dt-dg) or (mmy>wh.y+wh.h+dh+dsh)) and (wh.prev<>nil) do
  begin
  wh.mx:=-1;
  wh.my:=-1;
  wh.mk:=-1;
  wh:=wh.prev;

  if wh.decoration=nil then
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
    if wh.decoration^.hscroll then dsh:=scrollwidth else dsh:=0;
    if wh.decoration^.vscroll then dsv:=scrollwidth else dsv:=0;
    end



  end;
result:=wh;
if (mmk=1) and (wh.mk=0) then selectwindow(wh);
if (mmk=1) and (wh.mk=1) and (wh<>background) then begin lpoke($2f06000c,$FF0000);wh.move(mmx-wh.mx,mmy-wh.my,0,0,0,0) ;end
else
  begin
  wh.mx:=mmx-wh.x;
  wh.my:=mmy-wh.y;
  wh.mk:=mmk;
  end;
if not(wh.resizable) or ((mmx<(wh.x+wh.l)) and (mmy<(wh.y+wh.h))) then begin state:=0; deltax:=0; deltay:=0 end
else if (mmx>=(wh.x+wh.l)) and (mmy<(wh.y+wh.h)) then begin state:=1; deltax:=wh.x+wh.l-mmx; deltay:=0; end
else if (mmx<(wh.x+wh.l)) and (mmy>=(wh.y+wh.h)) then begin state:=2; deltax:=0; deltay:=wh.y+wh.h-mmy;end
else begin state:=3; deltax:=wh.x+wh.l-mmx; deltay:=wh.y+wh.h-mmy; end ;

p999:
end;

procedure selectwindow(wh:Window);

var whh:Window;

begin
if (wh.next<>nil) and (wh<>background) then
  begin
  wh.prev.next:=wh.next;
  wh.next.prev:=wh.prev;
  whh:=wh;
  repeat whh:=whh.next until whh.next=nil;
  wh.next:=nil;
  wh.prev:=whh;
  whh.next:=wh;
  end;
end;

procedure window.cls(c:integer);

var i,al:integer;

begin
box(0,0,wl,wh,c);
end;

procedure window.putpixel(ax,ay,color:integer); inline;

label p999;

var adr:integer;

begin
if (ax<0) or (ax>=wl) or (ay<0) or (ay>wh) then goto p999;
adr:=cardinal(gdata)+ax+wl*ay;
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

procedure window.putchar(ax,ay:integer;ch:char;col:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      putpixel(ax+j,ay+i,col);
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

procedure window.putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);


var i,j,k,ll:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      for k:=0 to yz-1 do
        for ll:=0 to xz-1 do
           putpixel(ax+j*xz+ll,ay+i*yz+k,col);
    end;
  end;
end;

procedure window.outtextxy(ax,ay:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(ax+8*i-8,ay,t[i],c);
end;

procedure gouttextxy(g:Pointer;x,y:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do gputchar(g,x+8*i-8,y,t[i],c);
end;

procedure window.outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(ax+8*xz*i,ay,t[i+1],c,xz,yz);
end;

procedure window.box(ax,ay,al,ah,c:integer);

label p101,p102,p999;

var screenptr:cardinal;
    xres,yres:integer;

begin

screenptr:=integer(gdata);
xres:=wl;
yres:=wh;
if ax<0 then begin al:=al+ax; ax:=0; if al<1 then goto p999; end;
if ax>=xres then goto p999;
if ay<0 then begin ah:=ah+ay; ay:=0; if ah<1 then goto p999; end;
if ay>=yres then goto p999;
if ax+al>=xres then al:=xres-ax;
if ay+ah>=yres then ah:=yres-ay;


             asm
             push {r0-r6}
             ldr r2,ay
             ldr r3,xres
             ldr r1,ax
             mul r3,r3,r2
             ldr r4,al
             add r3,r1
             ldr r0,screenptr
             add r0,r3
             ldrb r3,c
             ldr r6,ah

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

