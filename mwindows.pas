unit mwindows;

{$mode objfpc}{$H+}

//------------------------------------------------------------------------------
// The window manager unit for use with the retromachine
// v.0.01 - 20170517
// Piotr Kardasz pik33@o2.pl
// gpl v. 2.0 or higher
// alpha code quality
//------------------------------------------------------------------------------

interface

uses
  Classes, SysUtils;

const mapbase=$30800000;
      framewidth=4;

type TWindow=class;
     TDecoration=class;
     TButton=class;


type TDecoration=class(TObject)
     title:pointer;
     hscroll,vscroll,up,down,close:boolean;
     constructor create;
     destructor destroy;
     end;


//------------------------------------------------------------------------------
// Basic window class
//------------------------------------------------------------------------------

type TWindow=class(TObject)
     handle:TWindow;
     prev,next:TWindow;                     // 2-way list
     x,y:integer;                           // position on screen
     l,h:integer;                           // dmensions on screen
     vx,vy:integer;                         // visible upper left
     mx,my,mk:integer;                      // mouse events
     wl,wh:integer;                         // windows l,h
     bg:integer;                            // background color
     gdata:pointer;                         // graphic memory
     decoration:TDecoration;                // the decoration or nil if none
     visible:boolean;                       // visible or hidden
     resizable:boolean;                     // if true windows not resizable
     movable:boolean;                       // if true windows not movable by mouse
     redraw:boolean;                        // set true by redrawing process after redraw
     active:boolean;                        // if false, window doesn't need redrawing
     title:string;                          // window title
     buttons:TButton;                       // widget chain start
     mstate:integer;
     // The constructor. al, ah - graphic canvas dimensions
     // atitle - title to set, if '' then windows will have no decoration

     constructor create (al,ah:integer; atitle:string);
     destructor destroy; override;

     // graphic methods

     procedure cls(c:integer);                                          // clear window and fill with color
     procedure putpixel(ax,ay,color:integer); inline;                   // put a pixel to window
     function getpixel(ax,ay:integer):integer; inline;                  // get a pixel from window
     procedure putchar(ax,ay:integer;ch:char;col:integer);              // put a 8x16 char on window
     procedure putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);       // put a zoomed char, xz,yz - zoom
     procedure outtextxy(ax,ay:integer; t:string;c:integer);            // output a string from x,y position
     procedure outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);     // output a zoomed string
     procedure box(ax,ay,al,ah,c:integer);                              // draw a filled box

     procedure draw(dest:integer);                                      // redraw a window
     procedure move(ax,ay,al,ah,avx,avy:integer);                       // move and resize. ax,ay - position on screen
                                                                        // al, ah - visible dimensions without decoration
                                                                        // avy, avy - upper left visible canvas pixel
     function checkmouse:TWindow;                                       // check and react to mouse events
     procedure resize(nwl,nwh:integer);                                 // resize the canvas
     end;

     Tpanel=class(TWindow)
     constructor create;
     end;

type TButton=class(TObject)
     x,y:integer;                                                      // upper left pixel position on window
     l,h:integer;                                                      // dimensions
     c1,c2:integer;                                                    // basic background color, text color
     clicked:integer;                                                  // mouse event
     s:string;                                                         // title
     fsx,fsy:integer;
     value:integer;
     gdata:pointer;
     visible,highlighted,selected,radiobutton,selectable,down:boolean;
     radiogroup:integer;
     next,last:TButton;
     granny:TWindow;

  constructor create(ax,ay,al,ah,ac1,ac2:integer;aname:string;g:TWindow);
  destructor destroy; override;
  function checkmouse:boolean;
  procedure highlight;
  procedure unhighlight;
  procedure show;
  procedure hide;
  procedure select;
  procedure unselect;
  procedure draw;
  function append(ax,ay,al,ah,ac1,ac2:integer;aname:string):TButton;
  procedure setparent(parent:TButton);
  procedure setdesc(desc:TButton);
  function gofirst:TButton;
  function findselected:TButton;
  procedure setvalue(v:integer);
  procedure checkall;
  procedure box(ax,ay,al,ah,c:integer);
  end;


var background:TWindow=nil;
    panel:TPanel=nil;


    activecolor:integer=120;
    inactivecolor:integer=13;
    activetextcolor:integer=15;
    inactivetextcolor:integer=0;
    borderwidth:integer=6;
    scrollwidth:integer=16;
    borderdelta:integer=-2;
    scrollcolor:integer=12;
    activescrollcolor:integer=124;
    titleheight:integer=24;
    icon:array[0..15,0..15] of byte;

procedure background_init(color:byte);
//function window(l,h:integer; title:string):pointer;
//function checkmouse:TWindow;
procedure selectwindow(wh:TWindow);
procedure gouttextxy(g:pointer;x,y:integer; t:string;c:integer);
procedure gputpixel(g:pointer; x,y,color:integer); inline;
procedure makeicon;



implementation

uses retromalina,blitter,retro;

constructor TDecoration.create;

begin
inherited create;
title:=nil;
hscroll:=false;
vscroll:=false;
up:=false;
down:=false;
close:=false;
end;

destructor TDecoration.destroy;

begin
if title<>nil then freemem(title);
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



constructor TWindow.create (al,ah:integer; atitle:string);

var who:TWindow;
    i,j:integer;

begin
inherited create;
mstate:=0;
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
  title:=atitle;
  if atitle<>'' then
    begin
    decoration:=TDecoration.create;
    decoration.title:=getmem(wl*titleheight);
    decoration.hscroll:=true;
    decoration.vscroll:=true;
    decoration.up:=true;
    decoration.down:=true;
    decoration.close:=true;
    end
  else decoration:=nil;
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

destructor TWindow.destroy;

var i,j:integer;

begin
visible:=false;
prev.next:=next;
if next<>nil then next.prev:=prev;
if gdata<>nil then freemem(gdata);
if decoration<>nil then
  begin
  decoration.destroy
  end;
end;

procedure TWindow.resize(nwl,nwh:integer);

label p999;

var gd,gd2:pointer;
    bl,bh:integer;
    i:integer;

begin
if (nwl=wl) and (nwh=wh) then goto p999; // nothing to resize
gd:=getmem(nwl*nwh);
for i:=0 to nwl*nwh-1 do poke(integer(gd)+i,bg);
if nwl>wl then bl:=wl else bl:=nwl;
if nwh>wh then bh:=wh else bh:=nwh;
blit(integer(gdata),0,0,integer(gd),0,0,bl,bh,wl,nwl);
gd2:=gdata;
gdata:=gd;
wl:=nwl; wh:=nwh;
waitvbl;
waitvbl;
freemem(gd2);
if l>wl then l:=wl;
if h>wh then h:=wh;
if vx+l>wl then vx:=wl-l;
if vy+h>wh then vy:=wh-h;
p999:
end;


procedure TWindow.move(ax,ay,al,ah,avx,avy:integer);

var q:integer;

begin
if ay>1090 then ay:=1090;
if al>0 then l:=al;        // now set new window parameters
if ah>0 then h:=ah;

q:=8*length(title)+96;
if (decoration<>nil) and (al>0) and (al<q) then l:=q;
if (ah>0) and (ah<64) then h:=64;
if al>wl then l:=wl;
if ah>wh then h:=wh;



if ax>-2048 then x:=ax;
if ay>-2048 then y:=ay;
if avx>-1 then vx:=avx;
if avy>-1 then vy:=avy;

 end;


procedure TWindow.draw(dest:integer);

var dt,dg,dh,dx,dy,dx2,dy2,dl,dsh,dsv,i,j,c,ct,a:integer;
   wt:int64;
   q1,q2,q3:integer;
   hsw,vsh,hsp,vsp:integer;

begin

redraw:=false;

if decoration=nil then
  begin
  dg:=0;
  dh:=0;
  dt:=0;
  dl:=0;
  dsh:=0;
  dsv:=0;
  hsw:=0;
  vsh:=0;
  hsp:=0;
  vsp:=0;

  end
else
  begin
  dt:=titleheight;
  dl:=borderwidth;
  dg:=borderwidth;
  dh:=borderwidth;
  if decoration.hscroll then dsh:=scrollwidth else dsh:=0;
  if decoration.vscroll then dsv:=scrollwidth else dsv:=0;
  hsw:=round((l/wl)*l); if hsw<11 then hsw:=10;
  vsh:=round((h/wh)*h); if vsh<11 then vsh:=10;
  hsp:=round((vx/(wl-l))*(l-hsw));
  vsp:=round((vy/(wh-h))*(h-vsh));
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
  if decoration<>nil then
    begin
    if (mousex>(x+l+dsv-60)) and (mousey>(y-20)) and (mousex<(x+l+dsv-44)) and (mousey<(y-4)) then q1:=122 else q1:=0;
    if (mousex>(x+l+dsv-40)) and (mousey>(y-20)) and (mousex<(x+l+dsv-24)) and (mousey<(y-4)) then q2:=122 else q2:=0;
    if (mousex>(x+l+dsv-20)) and (mousey>(y-20)) and (mousex<(x+l+dsv-4)) and (mousey<(y-4)) then begin q3:=32; a:=32; end else q3:=0;


    fill2d(dest,x-dl,y-dt-dl,l+dl+dsv,dl,1792,c+borderdelta);         //upper borded
    fill2d(dest,x-dl,y-dt,l+dl+dsv,dt,1792,c);                        //title bar
    fill2d(dest,x-dl,y-dt-dl,dl,h+dt+dl+dsh+dh,1792,c+borderdelta);   //left border
    fill2d(dest,x-dl,y+h+dsh,l+dl+dg+dsv,dh,1792,c+borderdelta);      //lower border
    fill2d(dest,x+l+dsv,y-dt-dl,dg,h+dt+dl+dsh+dl,1792,c+borderdelta);//right border

    fill2d(dest,x,y+h,l,dsh,1792,scrollcolor);                        //horizontal scroll bar
    fill2d(dest,x+3+hsp,y+h+3,hsw-6,dsh-6,1792,activescrollcolor);                        //horizontal scroll bar

    fill2d(dest,x+l,y,dsv,h,1792,scrollcolor);                        //vertical scroll bar
//    fill2d(dest,x+l+3,y,dsv,vsh,1792,scrollcolor+borderdelta-2);                        //vertical scroll bar

    fill2d(dest,x+l+3,y+3+vsp,dsv-6,vsh-6,1792,activescrollcolor);                        //vertical scroll bar


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
  end;
  redraw:=true;
wt:=gettime-wt;
//title:='Window time='+inttostr(wt)+' us';
end;

function TWindow.checkmouse:TWindow;

label p999;

var window:TWindow;
    mmx,mmy,mmk,dt,dg,dh,dl,dsh,dsv:integer;
    q,q2,sy2:integer;

const state:integer=0;
      deltax:integer=0;
      deltay:integer=0;
      sx:integer=0;
      sy:integer=0;
      hsw:integer=0;
      vsp:integer=0;
      vsh:integer=0;
      hsp:integer=0;
      oldhsp:integer=0;
      oldvsp:integer=0;
begin


result:=background;

mmx:=mousex;
mmy:=mousey;
mmk:=mousek;

if mmk=0 then state:=0;

// if mouse key pressed ans there is a window set to move, move it

//hsw:=round((window.l/window.wl)*window.l); if hsw<11 then hsw:=10;
//vsh:=round((window.h/window.wh)*window.h); if vsh<11 then vsh:=10;
//hsp:=round((window.vx/(window.wl-window.l))*(window.l-hsw));
//vsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh));

if mmk=1 then // find a window with mk=1
  begin
  window:=background;
  while (window.next<>nil) and (window.mk<>1) do window:=window.next;
  if window.mk=1 then
    begin


    if state=0 then window.move(mmx-window.mx,mmy-window.my,0,0,-1,-1)
    else if state=1 then
      begin
      q:=mmx-window.x+deltax;
      if q+window.vx>window.wl then begin window.vx:=window.wl-q; if window.vx<0 then begin window.vx:=0; q:=window.wl; end; end;//q:=window.wl-window.vx;
      window.move(window.x,window.y, q ,window.h,-1,-1)
      end
    else if state=2 then
      begin
       q:=mmy-window.y+deltay;
       if q+window.vy>window.wh then begin window.vy:=window.wh-q; if window.vy<0 then begin window.vy:=0; q:=window.wh; end; end;//q:=window.wl-window.vx;
       window.move(window.x,window.y, window.l, q,-1,-1)
       end

    else if state=3 then
      begin
      q:=mmx-window.x+deltax;
      if q+window.vx>window.wl then begin window.vx:=window.wl-q; if window.vx<0 then begin window.vx:=0; q:=window.wl; end; end;//q:=window.wl-window.vx;
      q2:=mmy-window.y+deltay;
      if q2+window.vy>window.wh then begin window.vy:=window.wh-q2; if window.vy<0 then begin window.vy:=0; q2:=window.wh; end; end;//q:=window.wl-window.vx;


      window.move(window.x,window.y, q ,q2, -1, -1)
      end
    else if state=4 then
      begin
      // sy2:=mmy-window.y-vsp;
      // vsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh));
      // q:=round((mmy-sy-window.y+oldvsp)*window.wh/(window.h-vsh));
      q:=round((mmy-window.y-sy)*(window.wh-window.h)/(window.h-vsh));
      if q<0 then q:=0;
      if q>window.wh-window.h then q:=window.wh-window.h;
      window.move(window.x,window.y, {mmx-window.x+deltax ,mmy-window.y+deltay,}0,0,-1,q);
      end
    else if state=5 then
      begin
      q:=round((mmx-window.x-sx)*(window.wl-window.l)/(window.l-hsw));
      if q<0 then q:=0;
      if q>window.wl-window.l then q:=window.wl-window.l;
      window.move(window.x,window.y, {mmx-window.x+deltax ,mmy-window.y+deltay,}0,0,q,-1);
      end;
    result:=window;
//    retromalina.box(0,0,300,100,0);
//    retromalina.outtextxy(0,0,inttostr(state)+' q='+inttostr(q)+' sx='+inttostr(sy),15);

    goto p999;
    end;
  end;

// we are here if mousekey=0 or there is no windows to move

window:=background;
while window.next<>nil do window:=window.next;        // go to the top window

// calculate decoration sizes to add to the window size

if window.decoration=nil then
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
  if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
  if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
  end ;

// go back with windows chain until you found the window on which there is the mouse cursor

while ((mmx<window.x-dg) or (mmx>window.x+window.l+dg+dsv) or (mmy<window.y-dt-dg) or (mmy>window.y+window.h+dh+dsh)) and (window.prev<>nil) do
  begin
  window.mx:=-1;
  window.my:=-1;
  window.mk:=-1;
  window:=window.prev;

  if window.decoration=nil then
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
    if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
    if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
    end
  end;
result:=window;

// now, here no windows to move and window=window to select
// if the window is not selected, select it

if (mmk=1) and (window.mk=0) then

  selectwindow(window);

//and set mouse correction amount
window.mx:=mmx-window.x;
window.my:=mmy-window.y;
window.mk:=mmk;

hsw:=round((window.l/window.wl)*window.l); if hsw<11 then hsw:=10;
vsh:=round((window.h/window.wh)*window.h); if vsh<11 then vsh:=10;
hsp:=round((window.vx/(window.wl-window.l))*(window.l-hsw));
vsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh));

// now set the state according to clicked area

if not(window.resizable) or ((mmx<(window.x+window.l)) and (mmy<(window.y+window.h))) then begin state:=0; deltax:=0; deltay:=0 end      // window
else if (mmx>=(window.x+window.l)) and (mmx<(window.x+window.l+scrollwidth-1)) and (mmy<(window.y+vsp+vsh-3)) and (mmy>(window.y+vsp+3)) then begin state:=4;
             oldvsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh)); sy:=mmy-window.y-vsp; end      // vertical scroll bar
else if (mmx>=(window.x+window.l)) and (mmy<(window.y+window.h)) then begin state:=1; deltax:=window.x+window.l-mmx; deltay:=0; end      // right border
else if (mmx<(window.x+hsp+hsw-3)) and (mmx>(window.x+hsp+3)) and (mmy>=(window.y+window.h)) and (mmy<(window.y+window.h+scrollwidth-1)) then begin state:=5;
             oldhsp:=round((window.vx/(window.wl-window.l))*(window.l-hsw));     sx:=mmx-window.x-hsp; end      // down border
else if (mmx<(window.x+window.l)) and (mmy>=(window.y+window.h)) then begin state:=2; deltax:=0; deltay:=window.y+window.h-mmy; end      // down border
else begin state:=3; deltax:=window.x+window.l-mmx; deltay:=window.y+window.h-mmy; end ;                                                 // corner
window.mstate:=state;
//retromalina.box(0,0,300,100,0);
//retromalina.outtextxy(0,0,inttostr(state)+' hsp='+inttostr(hsp)+' hsw='+inttostr(hsw)+' vsp='+inttostr(vsp)+' vsh='+inttostr(vsh),15);
p999:
end;


procedure selectwindow(wh:TWindow);

var whh:TWindow;

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

procedure TWindow.cls(c:integer);

var i,al:integer;

begin
box(0,0,wl,wh,c);
end;

procedure TWindow.putpixel(ax,ay,color:integer); inline;

label p999;

var adr:integer;

begin
if (ax<0) or (ax>=wl) or (ay<0) or (ay>wh) then goto p999;
adr:=cardinal(gdata)+ax+wl*ay;
poke(adr,color);
p999:
end;

function TWindow.getpixel(ax,ay:integer):integer; inline;

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

procedure TWindow.putchar(ax,ay:integer;ch:char;col:integer);


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

procedure TWindow.putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);


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

procedure TWindow.outtextxy(ax,ay:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(ax+8*i-8,ay,t[i],c);
end;

procedure gouttextxy(g:Pointer;x,y:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do gputchar(g,x+8*i-8,y,t[i],c);
end;

procedure TWindow.outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(ax+8*xz*i,ay,t[i+1],c,xz,yz);
end;

procedure TWindow.box(ax,ay,al,ah,c:integer);

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

constructor TPanel.create;


var i,j:integer;

begin
  handle:=self;
  x:=0;
  y:=1095;
  mx:=-1;
  my:=-1;
  mk:=0;
  vx:=0;
  vy:=0;
  l:=1792;
  h:=25;
  bg:=11;
  wl:=l;
  wh:=h;
  buttons:=nil;
  next:=nil;
  visible:=false;
  resizable:=false;
  prev:=nil;
  gdata:=getmem(wl*wh);
  for i:=0 to wl*wh-1 do poke(cardinal(gdata)+i,bg);
  decoration:=nil;
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

constructor TButton.create(ax,ay,al,ah,ac1,ac2:integer;aname:string;g:TWindow);

begin
inherited create;
x:=ax; y:=ay; l:=al; h:=ah; c1:=ac1; c2:=ac2; s:=aname;
gdata:=getmem(4*al*ah);
granny:=g;
if granny.buttons=nil then granny.buttons:=self;
visible:=false; highlighted:=false; selected:=false; radiobutton:=false;
selectable:=false; down:=false;
next:=nil; last:=nil;
fsx:=1; fsy:=1;
radiogroup:=0;
self.show;
end;


destructor TButton.destroy;

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


procedure TButton.setvalue(v:integer);

begin
value:=v;
end;

function TButton.findselected:TButton;

var temp:TButton;

begin
temp:=self.gofirst;
while not (temp=nil) do
  begin
  if temp.selected then break else temp:=temp.next;
  end;
result:=temp;
end;

function TButton.checkmouse:boolean;

var mx,my:integer;

begin
mx:=mousex-granny.x+granny.vx;
my:=mousey-granny.y+granny.vy;
if ((background.checkmouse=granny) or (granny=panel)) and (granny.mstate=0) and (my>y) and (my<y+h) and (mx>x) and (mx<x+l) then checkmouse:=true else checkmouse:=false;
end;


procedure TButton.highlight;

var c:integer;

begin
if visible and not highlighted then begin
  c1+=2;
  draw;
  highlighted:=true;
  end;
end;

procedure TButton.unhighlight;

begin

if visible and highlighted then begin
  c1-=2;
  draw;
  highlighted:=false;
  end;
end;

procedure TButton.draw;

var l2,a:integer;

begin
if selected or down then a:=-2 else a:=2;
granny.box(x,y,l,h,c1+a);
granny.box(x,y+3,l-3,h-3,c1-a);
granny.putpixel(x,y+1,c1-a); granny.putpixel(x,y+2,c1-a); granny.putpixel(x+1,y+2,c1-a);
granny.putpixel(x+l-3,y+h-2,c1-a); granny.putpixel(x+l-3,y+h-1,c1-a); granny.putpixel(x+l-2,y+h-1,c1-a);
granny.box(x+3,y+3,l-6,h-6,c1);
l2:=length(s)*4*fsx;
granny.outtextxyz(x+(l div 2)-l2,y+(h div 2)-8*fsy,s,c2,fsx,fsy);
end;


procedure TButton.show;

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

procedure TButton.hide;

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


procedure TButton.select;

var c:integer;
    temp:TButton;

begin
if visible and selectable and not selected then begin
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

procedure TButton.unselect;

begin

if visible and selectable and selected then begin
  selected:=false;
  draw;
  end;
end;

function TButton.append(ax,ay,al,ah,ac1,ac2:integer;aname:string):TButton;

begin
next:=TButton.create(ax,ay,al,ah,ac1,ac2,aname,self.granny);
next.setparent(self);
result:=next;
end;

procedure TButton.setparent(parent:TButton);

begin
last:=parent;
end;

procedure TButton.setdesc(desc:TButton);

begin
next:=desc;
end;

function TButton.gofirst:TButton;

begin
result:=self;
while result.last<>nil do result:=result.last;
end;

procedure TButton.checkall;

label p999;

var temp:TButton;
    cm:boolean;

begin
temp:=self.gofirst;
while temp<>nil do
  begin
  cm:=temp.checkmouse;
//  retromalina.box(0,0,100,100,0) ;
//  retromalina.outtextxy(0,0,inttostr(mousek),15);

  if cm and (mousek=0) then begin temp.highlight; temp.down:=false; end;
  if cm and (mousek=1) then begin temp.unhighlight; temp.down:=true; end;
  if not cm then begin temp.down:=false; temp.unhighlight; end;
  if cm and click {(peek(base+$60030)=1)} then begin
      if (temp.selected) and not temp.radiobutton then temp.unselect else temp.select;
      temp.clicked:=1;
    //  poke(base+$60030,0);
      end;
  temp:=temp.next;

  end;
p999:
end;

procedure TButton.box(ax,ay,al,ah,c:integer);

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

