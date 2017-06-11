unit notepad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mwindows, threads, retromalina, retro, blitter;

type TNotepadthread=class (TThread)

     private
     protected
       procedure Execute; override;
     public

       Constructor Create(CreateSuspended : boolean);
     end;

    TBasicLine=string[255];
    TBasicLineC=array[0..255] of byte;
    PStringLine=^TStringLine;
    TStringLine=record
      s:string;
      next,prev:PStringLine;
      end;

var note:TWindow=nil;
    currentline:TBasicLine;
    stringline:TStringLine;
    currentlinec:TBasiclinec absolute currentline;
    s1,s2:PStringline;

implementation

procedure scrollup;

begin
blit8(integer(note.canvas),0,16,integer(note.canvas),0,0,note.wl, note.wh-16, note.wl,note.wl);
note.box(0,note.wh-16,note.wl,16,15);
end;

procedure crlf;

begin
 dpoke(base+$600a0, 0);
 if dpeek (base+$600a2)<49 then dpoke(base+$600a2, dpeek(base+$600a2)+1) else scrollup;
end;

constructor TNotepadthread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TNotepadthread.execute;

label p013,p136,p206,p207,p208,p209,p999;

var i,j,key,clpointer:integer;
    s6x,s6y:integer;

const cursorcnt:integer=0;
      lostfocus:integer=0;

begin
ThreadSetAffinity(ThreadGetCurrent,4);
sleep(1);
if note=nil then
  begin
  note:=TWindow.create(2040,800,'Notepad');
  note.decoration.hscroll:=true;
  note.decoration.vscroll:=true;
  note.resizable:=true;
  note.cls(15);
  note.move(448,200,1024,800,0,0);
  end;
s1:=@stringline;
s1^.prev:=nil;
s1^.next:=nil;
for i:=0 to 1023 do lpoke(base+$58000+4*i,0);
for j:=0 to 2 do
  for i:=0 to 7 do
    lpoke(base+$58000+4*i+128*j,$00800000); // test red cursor
lpoke(base+$600a0,0); // text cursor at 0,0;
currentline:='';

//----------------------------------main loop start-----------------------------

repeat
  repeat sleep(3) until note.redraw;
  if note.selected then
    begin
    lostfocus:=0;
    sprite6ptr:=base+$58000;
    sprite6zoomx:=1;
    sprite6zoomy:=1;

    note.redraw:=false;
    cursorcnt+=1;
    if cursorcnt=60 then cursorcnt:=0;
    if cursorcnt<30 then
      begin
      s6x:=note.x-note.vx+8*dpeek (base+$600a0);
      s6y:=note.y-note.vy+16*dpeek (base+$600a2)+13;
      if s6x<note.x then s6x:=2049;
      if s6x<0 then s6x:=2049;
      if s6x>=note.x+note.l then s6x:=2049;
      if s6x>=xres then s6x:=2049;
      if s6y<0 then begin s6x:=2049; s6y:=0; end;
      if s6y>=yres-25 then begin s6x:=2049; s6y:=yres-32; end;
      if s6y<note.y then s6x:=2049;
      if s6y>=note.y+note.h then s6x:=2049;
      sprite6x:=s6x;
      sprite6y:=s6y;

      end;
    if cursorcnt>=30 then sprite6x:=2049;

    key:=readkey and $FF;
//    if key<>0 then box(0,0,100,32,0); outtextxy(0,0,inttostr(key),15);
    if key=0 then goto p999;
    if key=141 then goto p013;
    if key=136 then goto p136;
    if key=206 then goto p206;  //left arrow
    if key=207 then goto p207;  //right arrow
    if key=208 then goto p208;  //down arrow
    if key=209 then goto p209;  //up arrow
    if key<3 then goto p999;
    if key>124 then goto p999;

    note.box(8*dpeek(base+$600a0),16*dpeek(base+$600a2),8,16,15);
    note.putchar(8*dpeek(base+$600a0),16*dpeek(base+$600a2),chr(key),0);

    currentlinec[clpointer+1]:=key; //peek(base+$60028);
    if clpointer<255 then clpointer+=1;
    if clpointer>currentlinec[0] then currentlinec[0]:=clpointer;
 //   box(0,0,1000,32,0); outtextxy(0,0,currentline,15);
    dpoke(base+$600a0,clpointer);
    if (clpointer*8+8)>(note.l+note.vx) then note.move(-2048,-2048,0,0,note.vx+8,0);
    goto p999;

p136:  //backspace

    if clpointer>0 then clpointer-=1;
    currentlinec[clpointer+1]:=0;
    currentlinec[0]:=clpointer;
    if dpeek(base+$600a0)>0 then dpoke(base+$600a0,dpeek(base+$600a0)-1);
    if (clpointer*8)<(note.vx+80) then note.move(-2048,-2048,0,0,note.vx-8,0);

//        box(0,0,1000,32,0); outtextxy(0,0,currentline,15);
    note.box(8*dpeek(base+$600a0),16*dpeek(base+$600a2),8,16,15);
    goto p999;


p206: //right arrow
p207: //left arrow


p208: // down arrow
p209: // up arrow

    goto p999;

p013: // enter

    crlf;
    s1^.s:=currentline;
    s2:=new(PStringline);
    s2^.prev:=s1;
    s1^.next:=s2;
    s1:=s2;
    for i:=0 to 255 do currentline[i]:=#0;
    clpointer:=0;

p999:

    end
  else
    begin
    lostfocus+=1;
    if lostfocus=1 then sprite6x:=2049;
    if lostfocus>=2 then lostfocus:=2;
    end;
until note.needclose;
sprite6x:=2049;
lpoke(base+$600a0,-1); // text cursor off
note.destroy;
note:=nil;
end;

end.


end.

