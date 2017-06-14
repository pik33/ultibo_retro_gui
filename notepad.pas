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

    TTextArray=array[0..16383,0..255] of byte;
    PTextArray=^TTextArray;




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
    cx,cy:word;
    textarray:PTextArray;
    lines:integer=0;
    mfile,mabout,mload,msave:TMenuitem;

implementation

procedure scrollup;

begin
blit8(integer(note.canvas),0,16,integer(note.canvas),0,0,note.wl, note.wh-16, note.wl,note.wl);
note.box(0,note.wh-16,note.wl,16,15);
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
  note:=TWindow.create(2064,800,'Notepad');
  note.decoration.hscroll:=true;
  note.decoration.vscroll:=true;
  note.decoration.menu:=true;
  note.resizable:=true;
  note.cls(15);
  note.move(448,200,1024,800,0,0);
  note.vcl:=2064;
  note.vch:=16384;
  note.virtualcanvas:=true;
  note.menu:=tmenu.create(note);
  mfile:=note.menu.append('File');
  mabout:=note.menu.item.append('About');
  mload:=mfile.addsub('Load');
  msave:=mload.append('Save');
 // mload.visible:=true;
 // msave.visible:=true;


  end;

textarray:=new(PTextarray);

s1:=@stringline;
s1^.prev:=nil;
s1^.next:=nil;
for i:=0 to 1023 do lpoke(base+$58000+4*i,0);
for j:=0 to 2 do
  for i:=0 to 7 do
    lpoke(base+$58000+4*i+128*j,$00800000); // test red cursor
currentline:='';
tcx:=0; tcy:=0; cx:=0; cy:=0;  lines:=0;


//----------------------------------main loop start-----------------------------

repeat
  repeat sleep(1) until note.redraw;
  note.redraw:=false;
  note.move(-2048,-2048,0,0,note.vcx,0);
  if note.selected then
    begin
    lostfocus:=0;
    sprite6ptr:=base+$58000;
    sprite6zoomx:=1;
    sprite6zoomy:=1;
    cursorcnt+=1;
    if cursorcnt=60 then cursorcnt:=0;
    if cursorcnt<30 then
      begin
      s6x:=note.x-note.vx+8*tcx+8;
      s6y:=note.y-note.vy+16*tcy+13+8;
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
 //   if key<>0 then box(0,0,100,32,0); outtextxy(0,0,inttostr(key),15);
    if key=0 then goto p999;
    if key=141 then goto p013;
    if key=136 then goto p136;
    if key=206 then goto p206;  //left arrow
    if key=207 then goto p207;  //right arrow
    if key=208 then goto p208;  //down arrow
    if key=209 then goto p209;  //up arrow
    if key<3 then goto p999;
    if key>124 then goto p999;


    textarray^[cy,cx]:=key;
    if cx<255 then
      begin
      cx+=1;
      note.box(8*tcx+8,16*tcy+8,8,16,15);
      note.putchar(8*tcx+8,16*tcy+8,chr(key),0);
//      box(0,0,100,32,0); outtextxy(0,0,inttostr(cx),15); outtextxy(50,0,inttostr(tcx),15);
      end;

    tcx:=cx;
    if (cx*8+24)>(note.l+note.vx) then
      begin
      note.move(-2048,-2048,0,0,note.vx+8,0);
      note.vcx:=note.vx;
      end;
    goto p999;

p136:  //backspace

    if cx>0 then cx-=1;
    textarray^[cy,cx]:=0;
    if tcx>0 then tcx-=1;
    if (cx*8)<(note.vx+96) then note.move(-2048,-2048,0,0,note.vx-8,0);

//        box(0,0,1000,32,0); outtextxy(0,0,currentline,15);
    note.box(8*tcx+8,16*tcy+8,8,16,15);
    goto p999;


p206: //right arrow

      if cx<255 then
         begin
         cx+=1;
         tcx+=1;
         end;

         goto p999;
p207: //left arrow
       if cx>0 then
         begin
         cx-=1;
         tcx-=1;
         end;

       goto p999;

p208: // down arrow
      if cy<lines then
        begin
        cy+=1;
        tcy+=1;
        if (16+(tcy*16)>note.h+note.vy) and (note.vy>16) then begin note.move (-2048,-2048,0,0,0,note.vy+16) end;
        end;
      goto p999;

p209: // up arrow
      if cy>0 then

        begin
        cy-=1;
        tcy:=tcy-1;
        if ((tcy*16)<note.vy) and (note.vy>16) then begin note.move (-2048,-2048,0,0,0,note.vy-16) end;
        end;


    goto p999;

p013: // enter

    if lines<16383 then
      begin
      lines+=1;
      cy+=1;
      tcy+=1;
      cx:=0;
      tcx:=0;
      end;

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
//lpoke(base+$600a0,-1); // text cursor off
note.destroy;
note:=nil;
end;

end.


end.

