unit mwindows;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const mapbase=$30800000;
      framewidth=4;

type window=class;
     cbutton=class;


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
     buttons:Cbutton;
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
     function getpixel(ax,ay:integer):integer; inline;

     end;


type cbutton=class(TObject)
  x,y,l,h,c1,c2,clicked:integer;
  s:string;
  fsx,fsy:integer;
  value:integer;
  gdata:pointer;
  visible,highlighted,selected,radiobutton:boolean;
  radiogroup:integer;
  next,last:cbutton;
  granny:window;

  constructor create(ax,ay,al,ah,ac1,ac2:integer;aname:string;g:window);
  destructor destroy; override;
  function checkmouse:boolean;
  procedure highlight;
  procedure unhighlight;
  procedure show;
  procedure hide;
  procedure select;
  procedure unselect;
  procedure draw;
  function append(ax,ay,al,ah,ac1,ac2:integer;aname:string):cbutton;
  procedure setparent(parent:cbutton);
  procedure setdesc(desc:cbutton);
  function gofirst:cbutton;
  function findselected:cbutton;
  procedure setvalue(v:integer);
  procedure checkall;
  procedure box(ax,ay,al,ah,c:integer);
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
  buttons:=nil;
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
  buttons:=nil;
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
   q1,q2,q3:integer;

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
  if buttons<>nil then buttons.draw;
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

  if (mousex>(x+l+dsv-60)) and (mousey>(y-20)) and (mousex<(x+l+dsv-44)) and (mousey<(y-4)) then q1:=122 else q1:=0;
  if (mousex>(x+l+dsv-40)) and (mousey>(y-20)) and (mousex<(x+l+dsv-24)) and (mousey<(y-4)) then q2:=122 else q2:=0;
  if (mousex>(x+l+dsv-20)) and (mousey>(y-20)) and (mousex<(x+l+dsv-4)) and (mousey<(y-4)) then begin q3:=32; a:=32; end else q3:=0;


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
  if q1<>0 then
     for i:=0 to 15 do
       for j:=0 to 15 do
         if down_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-60+i,y-20+j,down_icon[i+16*j])
                                else gputpixel(pointer(dest),x+l+dsv-60+i,y-20+j,q1);
  if q2<>0 then
     for i:=0 to 15 do
       for j:=0 to 15 do
         if up_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-40+i,y-20+j,up_icon[i+16*j])
                                else gputpixel(pointer(dest),x+l+dsv-40+i,y-20+j,q2)
  else for i:=0 to 15 do for j:=0 to 15 do if up_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-40+i,y-20+j,up_icon[i+16*j]);
  for i:=0 to 15 do for j:=0 to 15 do if close_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-20+i,y-20+j,a+q3+close_icon[i+16*j]);
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

{if (state=0) and (mmk=2) then
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
 }


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

if wh.decoration<>nil then
  begin


  end;
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

function window.getpixel(ax,ay:integer):integer; inline;

label p999;

var adr:integer;

begin
if (ax<0) or (ax>=wl) or (ay<0) or (ay>wh) then goto p999;
adr:=cardinal(gdata)+ax+wl*ay;
result:=peek(adr);
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

//------------------------------------------------------------------------------
// button
//------------------------------------------------------------------------------

constructor cbutton.create(ax,ay,al,ah,ac1,ac2:integer;aname:string;g:window);

begin
inherited create;
x:=ax; y:=ay; l:=al; h:=ah; c1:=ac1; c2:=ac2; s:=aname;
gdata:=getmem(4*al*ah);
granny:=g;
if granny.buttons=nil then granny.buttons:=self;
visible:=false; highlighted:=false; selected:=false; radiobutton:=false;
next:=nil; last:=nil;
fsx:=1; fsy:=1;
radiogroup:=0;
self.show;
end;


destructor cbutton.destroy;

begin
if visible then hide;
freemem(gdata);
if (last=nil) and (next<>nil) then next.setparent(nil)
else if next<>nil then next.setparent(last);
if (next=nil) and (last<>nil) then last.setdesc(nil)
else if last<>nil then last.setdesc(next);
if last=nil then granny.buttons:=nil;
inherited destroy;
end;


procedure cbutton.setvalue(v:integer);

begin
value:=v;
end;

function cbutton.findselected:cbutton;

var temp:cbutton;

begin
temp:=self.gofirst;
while not (temp=nil) do
  begin
  if temp.selected then break else temp:=temp.next;
  end;
result:=temp;
end;

function cbutton.checkmouse:boolean;

var mx,my:integer;

begin
mx:=mousex-granny.x;
my:=mousey-granny.y;
if (my>y) and (my<y+h) and (mx>x) and (mx<x+l) then checkmouse:=true else checkmouse:=false;
end;


procedure cbutton.highlight;

var c:integer;

begin
if visible and not highlighted then begin
  c1+=2;
  draw;
  highlighted:=true;
  end;
end;

procedure cbutton.unhighlight;

begin

if visible and highlighted then begin
  c1-=2;
  draw;
  highlighted:=false;
  end;
end;

procedure cbutton.draw;

var l2,a:integer;

begin
if selected then a:=-2 else a:=2;
granny.box(x,y,l,h,c1+a);
granny.box(x,y+3,l-3,h-3,c1-a);
granny.putpixel(x,y+1,c1-a); granny.putpixel(x,y+2,c1-a); granny.putpixel(x+1,y+2,c1-a);
granny.putpixel(x+l-3,y+h-2,c1-a); granny.putpixel(x+l-3,y+h-1,c1-a); granny.putpixel(x+l-2,y+h-1,c1-a);
granny.box(x+3,y+3,l-6,h-6,c1);
l2:=length(s)*4*fsx;
granny.outtextxyz(x+(l div 2)-l2,y+(h div 2)-8*fsy,s,c2,fsx,fsy);
end;


procedure cbutton.show;

var i,j,k:integer;
    p:^integer;

begin
if not visible then begin
p:=gdata;
k:=0;
for i:=y to y+h-1 do
  for j:=x to x+l-1 do
    begin
    (p+k)^:=granny.getpixel(j,i);
    k+=1;
    end;
draw;
visible:=true;
end;
end;

procedure cbutton.hide;

var i,j,k:integer;
    p:^integer;

begin
if visible then begin
  p:=gdata;
  k:=0;
  for i:=y to y+h-1 do
    for j:=x to x+l-1 do
      begin
      granny.putpixel(j,i,(p+k)^);
      k+=1;
      end;
  visible:=false;
  end;
end;


procedure cbutton.select;

var c:integer;
    temp:cbutton;

begin
if visible and not selected then begin
  selected:=true;
  draw;
  temp:=self;
  while temp.last<>nil do
    begin
    temp:=temp.last;
    temp.unselect;
    end;
  temp:=self;
  while temp.next<>nil do
    begin
    temp:=temp.next;
    temp.unselect;
    end;
   end;
end;

procedure cbutton.unselect;

begin

if visible and  selected then begin
  selected:=false;
  draw;
  end;
end;

function cbutton.append(ax,ay,al,ah,ac1,ac2:integer;aname:string):cbutton;

begin
next:=cbutton.create(ax,ay,al,ah,ac1,ac2,aname,self.granny);
next.setparent(self);
result:=next;
end;

procedure cbutton.setparent(parent:cbutton);

begin
last:=parent;
end;

procedure cbutton.setdesc(desc:cbutton);

begin
next:=desc;
end;

function cbutton.gofirst:cbutton;

begin
result:=self;
while result.last<>nil do result:=result.last;
end;

procedure cbutton.checkall;

var temp:cbutton;

begin
temp:=self.gofirst;
while temp<>nil do
  begin
  if temp.checkmouse then temp.highlight else temp.unhighlight;
  if temp.checkmouse and (peek(base+$60030)=1) then begin
      if (temp.selected) and not temp.radiobutton then temp.unselect else temp.select;
      temp.clicked:=1;
      poke(base+$60030,0);
      end;
  temp:=temp.next;
  end;
end;

procedure cbutton.box(ax,ay,al,ah,c:integer);

label p101,p102,p999;

var screenptr:cardinal;
    xres,yres:integer;

begin

screenptr:=integer(gdata);
xres:=l;
yres:=h;
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



end.

