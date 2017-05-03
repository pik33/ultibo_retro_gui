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
     x,y:integer;   // position on screen               //+4 +8
     l,h:integer;   // dmensions on screen              //+12 +16
     vx,vy:integer; // visible upper left               //+20 +24
     wl,wh:integer; // windows l,h                      //+28 +32
     background:integer;                                //+36
     gdata:pointer; // graphic memory                   //+40
     map:PCardinal;                                     //+44
     decoration:pointer;                                //+48
     end;

function window(l,h:integer):pointer;
procedure destroywindow(wh:PWindow);
procedure drawwindow(wh:PWindow;x,y,l,h,vx,vy:integer);
procedure wcls(wh:PWindow;c:integer);
procedure wputpixel(wh:PWindow; x,y,color:integer); inline;
procedure wputchar(wh:PWindow; x,y:integer;ch:char;col:integer);
procedure wputcharz(wh:PWindow;x,y:integer;ch:char;col,xz,yz:integer);
procedure wouttextxy(wh:PWindow;x,y:integer; t:string;c:integer);
procedure wouttextxyz(wh:PWindow;x,y:integer; t:string;c,xz,yz:integer);

implementation

uses retromalina;

function window(l,h:integer):pointer;

var wh:PWindow;
    i,j:integer;

begin

wh:=new(PWindow);
wh^.gdata:=getmem(l*h);
for i:=0 to l*h-1 do poke(cardinal(wh^.gdata)+i,0);
wh^.handle:=wh;
wh^.x:=0;
wh^.y:=0;
wh^.vx:=0;
wh^.vy:=0;
wh^.l:=0;
wh^.h:=0;
wh^.background:=0;
wh^.wl:=l;
wh^.wh:=h;
wh^.map:=nil;
wh^.decoration:=nil;
result:=wh;
end;

procedure destroywindow(wh:PWindow);

var i,j:integer;

begin
if wh^.map<>nil then
  begin
  for i:=wh^.y to wh^.y+wh^.h-1 do
    begin
    for j:=wh^.x to wh^.x+wh^.l-1 do
      begin
      lpoke(mapbase+4*1792*i+4*j,wh^.map[wh^.l*(i-wh^.y)+j-wh^.x]);
      end;
    end;
  freemem(wh^.map);
  end;
freemem(wh^.gdata);
dispose(wh);
end;

procedure drawwindow(wh:PWindow;x,y,l,h,vx,vy:integer);

label p101,p102;

var wh1,i,j,x1,y1,map1,map2:cardinal;

begin

if wh^.map<>nil then   // restore the map under the window if backup exists
  begin
  wh1:=integer(wh)+4;
  map1:=mapbase;
                 asm
                 push {r0-r10,r12}
                 ldr r0,wh1
                 ldr r1,[r0], #4  //wh^.x
                 ldr r2,[r0], #4  //wh^.y
                 ldr r3,[r0], #4  //wh^.l
                 ldr r4,[r0], #28 //wh^.h
                 ldr r5,[r0]      //wh^.map
                 ldr r6,map1
                 mov r7,r4        // outer loop counter
                 sub r7,#1

                 mov r9,r7
                 mul r9,r9,r3
                 add r9,r3
                 sub r9,#1


p102:            mov r8,r3        // inner loop counter
                 sub r8,#1

                 mov r0,#0x1c00
                 mov r12,r7
                 add r12,r2
                 mul r12,r12,r0
                 add r12,r12,r8,lsl #2
                 add r12,r12,r1,lsl #2


p101:           // inner loop

                ldr r10,[r5,r9,lsl #2]
                sub r9,#1

                str r10,[r6,r12]
                sub r12,#4

                subs r8,#1
                bge p101

                subs r7,#1
                bge p102

                pop {r0-r10,r12}
                end;


 { if (wh^.l=l) and (wh^.h=h) then begin }freemem(wh^.map);{ wh^.map:=nil; end;}  // don't freemem if the same dimesion
  end;

if l>0 then wh^.l:=l;        // now set new window parameters
if h>0 then wh^.h:=h;
if x>0 then wh^.x:=x;
if y>0 then wh^.y:=y;
if vx>0 then wh^.vx:=vx;
if vy>0 then wh^.vy:=vy;

{if wh^.map=nil then} wh^.map:=getmem(4*l*h);

for i:=wh^.y to wh^.y+wh^.h-1 do
  begin
  for j:=wh^.x to wh^.x+wh^.l-1 do
    begin
    wh^.map[wh^.l*(i-wh^.y)+j-wh^.x]:=lpeek(mapbase+4*1792*i+4*j);
    end;
  end;
for i:=wh^.y to wh^.y+wh^.h-1 do
  begin
  for j:=wh^.x to wh^.x+wh^.l-1 do
    begin
    lpoke(mapbase+4*1792*i+4*j, cardinal(wh^.gdata)+wh^.vx+wh^.vy*wh^.wl+(wh^.wl*(i-wh^.y)+j-wh^.x));
    end;
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

