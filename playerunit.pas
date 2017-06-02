unit playerunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, retromalina, mwindows, blitter, threads, simpleaudio;


type TPlayerThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


var pl:TWindow=nil;
    info:TWindow=nil;
    visarea:pointer=nil;
    cbuttons:pointer=nil;
    titlebar:pointer=nil;
    baseskin:pointer=nil;
    numbers:pointer=nil;
    volume:pointer=nil;
    sel1:TFileselector=nil;
    playfilename:string;
    dir:string;

implementation

procedure displaytime(mm,ss:integer);

var mm1,mm2,ss1,ss2:integer;

begin
mm1:=mm div 10;
mm2:=mm mod 10;
ss1:=ss div 10;
ss2:=ss mod 10;

blit8(integer(numbers),180,0,integer(pl.canvas),96,52,18,26,216,550);
blit8(integer(numbers),mm1*18,0,integer(pl.canvas),96,52,18,26,216,550);
blit8(integer(numbers),180,0,integer(pl.canvas),120,52,18,26,216,550);
blit8(integer(numbers),mm2*18,0,integer(pl.canvas),120,52,18,26,216,550);
blit8(integer(numbers),180,0,integer(pl.canvas),156,52,18,26,216,550);
blit8(integer(numbers),ss1*18,0,integer(pl.canvas),156,52,18,26,216,550);
blit8(integer(numbers),180,0,integer(pl.canvas),180,52,18,26,216,550);
blit8(integer(numbers),ss2*18,0,integer(pl.canvas),180,52,18,26,216,550);
end;

constructor TPlayerThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;


procedure TPlayerThread.Execute;

var fh,i,j,mm,ss,q:integer;

    const clickcount:integer=0;
          vbutton_x:integer=0;
          vbutton_dx:integer=0;

begin
dir:=drive;
ThreadSetAffinity(ThreadGetCurrent,4);
pl:=Twindow.create(550,232,'');
pl.resizable:=false;
pl.move(400,500,550,231,0,0);
if cbuttons=nil then
  begin
  cbuttons:=getmem(72*272);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\cbuttons.rbm',$40);
  fileread(fh,cbuttons^,72*272);
  fileclose(fh);
  end;
if titlebar=nil then
  begin
  titlebar:=getmem(174*688);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\titlebar.rbm',$40);
  fileread(fh,titlebar^,174*688);
  fileclose(fh);
  end;
if baseskin=nil then
  begin
  baseskin:=getmem(127600);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\base.rbm',$40);
  fileread(fh,baseskin^,127600);
  fileclose(fh);
  end;
if numbers=nil then
  begin
  numbers:=getmem(26*216);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\nums_ex.rbm',$40);
  fileread(fh,numbers^,26*216);
  fileclose(fh);
  end;
if volume=nil then
  begin
  volume:=getmem(866*136);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\volume.rbm',$40);
  fileread(fh,volume^,866*136);
  fileclose(fh);
  end;
blit8(integer(baseskin),0,0,integer(pl.canvas),0,0,550,232,550,550);
blit8(integer(titlebar),56,2,integer(pl.canvas),2,2,546,28,688,550);
blit8(integer(cbuttons),0,0,integer(pl.canvas),32,176,228,36,272,550);
blit8(integer(cbuttons),230,0,integer(pl.canvas),272,178,42,32,272,550);

blit8(integer(volume),0,810,integer(pl.canvas),214,112,136,28,136,550);
blit8(integer(volume),30,844,integer(pl.canvas),318,116,28,22,136,550);


pl.needclose:=false;
if visarea=nil then
  begin
  visarea:=getmem(158*34);
  blit8(integer(pl.canvas),44,84,integer(visarea),0,0,158,34,550,158);
  end;
vbutton_x:=318;
repeat
repeat sleep(1) until pl.redraw;
clickcount:=clickcount+1;
ss:=(songtime div 1000000) mod 60;
mm:=(songtime div 60000000);
displaytime(mm,ss);
blit8(integer(visarea),0,0,integer(pl.canvas),44,84,158,34,158,550);
for j:=46 to 200 do if abs(scope[j])<48000 then pl.box(j,100-scope[j] div (3000),2,2,15);
if mousek=0 then
  begin
  if vbutton_dx<>0 then
    begin
    vbutton_x:=mousex-pl.x-vbutton_dx;
    if vbutton_x>318 then vbutton_x:=318;
    if vbutton_x<214 then vbutton_x:=214;
    end;
  vbutton_dx:=0;
  end;

if (pl.mx>523) and (pl.my<28) and (mousek=1) then pl.needclose:=true;
if (pl.mx>495) and (pl.my>175) and (mousek=1) and  (clickcount>60) then
  begin
  clickcount:=0;
  if info=nil then
    begin
    info:=TWindow.create(500,160,'RetAMP info');
    info.decoration.hscroll:=false;
    info.decoration.vscroll:=false;
    info.resizable:=false;
    info.move(650,400,500,160,0,0);
    info.cls(0);
    info.outtextxy(8,8,'RetAMP - the Retromachine Advanced Music Player',41);
    info.outtextxy(8,28,'Version: 0.25u - 20170602',57);
    info.outtextxy(8,48,'Alpha code',73);
    info.outtextxy(8,68,'Plays: mp2, mp3, s48, wav, sid, dmp, mod, s3m, xm, it files',89);
    info.outtextxy(8,88,'GPL 2.0 or higher',105);
    info.outtextxy(8,108,'more information: pik33@o2.pl',121);
    sleep(100);
    info.select;
    end;
  end;

if info<> nil then if info.needclose then begin info.destroy; info:=nil; end;

if (pl.mx>vbutton_x) and (pl.mx<vbutton_x+28) and (pl.my>116) and (pl.my<138) and (mousek=1) and (vbutton_dx=0) then
  begin
  vbutton_dx:=pl.mx-vbutton_x;

  end;
q:=mousex-pl.x-vbutton_dx;
if q<214 then q:=214;
if q>318 then q:=318;
if ((mousex-pl.x-vbutton_dx)>0) and ((mousex-pl.x-vbutton_dx)<550) and (mousek=1) and (vbutton_dx<>0) then
  begin
  blit8(integer(volume),0,30*round(27*(q-214)/108),integer(pl.canvas),214,112,136,28,136,550);
  blit8(integer(volume),30,844,integer(pl.canvas),q,116,28,22,136,550);
  if q<220 then setdbvolume(-73) else setdbvolume(-36+round(36*(q-214)/100));
  end;

if (pl.mx>272) and (pl.mx<314) and (pl.my>178) and (pl.my<210) and (mousek=1) and (clickcount>60) then
  begin
  clickcount:=0;

  if sel1=nil then
    begin
    sel1 :=Tfileselector.create(dir);

    sel1.move(900,100,480,500,0,0);
          dblclick;
    end;
  end;
if sel1<>nil then
  begin
  if sel1.filename<>'' then
    begin
    playfilename:=sel1.filename;
    dir:=sel1.currentdir2;
    sel1.destroy;
    sel1:=nil;
    end;
  end;
if sel1<>nil then if sel1.needclose then begin playfilename:=''; sel1.destroy; sel1:=nil; end;
if (pl.needclose) and (sel1<>nil) then begin sel1.destroy; sel1:=nil; end;  ;
until pl.needclose;
pl.destroy;
pl:=nil;
end;


end.

