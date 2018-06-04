unit fmsynth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, simpleaudio, mwindows, retromalina;

type TFMSynthThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

const a212=1.0594630943592953098431053149397484958; //2^1/12
      c03=16.351597831287416763959505349330137242; //C-4
      norm44=0.02321995464852607709750566893424;   // freq normalize const, 1024/44100
      samplerate=961538.461538;
      norm960=0.06815744;                          // 65536/samplerate




var sinetable:array[0..65535] of integer;
    fmwindow:TWindow=nil;
    notes:array[0..127,0..2] of integer;
    a:cardinal;
    b:cardinal;
    c:cardinal;

    n:integer;
    noteon:integer;
        t,tt:int64;

implementation

procedure audiocallback(userdata: Pointer; stream: PUInt8; len:Integer ); forward;

procedure initnotes;

var i:integer;
    q:double;

begin
q:=c03;
for i:=0 to 127 do
  begin
  notes[i,0]:=round(q*norm960*65536);
  q:=q*a212;
  end;
end;

procedure initsinetable ;

var i:integer;
begin
for i:=0 to 65535 do
  sinetable[i]:=round(8388607*sin(2*pi*i/65536));

end;

constructor TFMSynthThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TFMSynthThread.execute;

label p999,p998;

var i,err:integer;
    aa:array[0..7] of integer=(48,50,52,53,55,57,59,60);
begin
if fmwindow=nil then
  begin
  fmwindow:=TWindow.create(1024,600,'FM Synthesizer');
  fmwindow.decoration.hscroll:=false;
  fmwindow.decoration.vscroll:=false;
  fmwindow.resizable:=false;
  fmwindow.cls(0);
  fmwindow.move(300,400,960,600,0,0);
  end
else goto p999;
initsinetable;
initnotes;
n:=48;
err:=sa_openaudio(961538,16,2,4800,@audiocallback);
if err<>0 then
  begin
  fmwindow.outtextxyz(16,16,'Error while opening audio: '+inttostr(err),120,1,1);
  fmwindow.outtextxyz(16,56,'Please close this window and then close the application which uses the audio driver ',120,1,1);
  goto p998;
  end;
//for i:=0 to 10 do fmwindow.outtextxy(0,16*i,inttostr(sinetable[i+16380]),120);

pauseaudio(0);   noteon:=1; sleep(10); noteon:=0;
p998:
repeat i:=i+1; if i=8 then i:=0; sleep(500); n:=aa[i]; noteon:=1; sleep(10); noteon:=0;  fmwindow.box(0,0,80,16,0); fmwindow.outtextxy(0,0,inttostr(tt),120);   until fmwindow.needclose;
if err=0 then closeaudio;
fmwindow.destroy;
fmwindow:=nil;
p999:
end;


function adsr:cardinal;

const q:cardinal=0;
      adsrstate:integer=0;
      a1s:cardinal=40000000;
      a1l:cardinal=4000000000;
      a2s:cardinal=4000000;
      a2l:cardinal=1000000000;
      a4s:cardinal=40000;

begin
if ((adsrstate=0) or (adsrstate=4)) and (noteon=1) then adsrstate:=1;
if (adsrstate=1) then begin q:=q+a1s; if q>=a1l then adsrstate:=2; end; // attack
if (adsrstate=2) then begin q:=q-a2s; if q<=a2l then adsrstate:=3; end; // decay
if (adsrstate=3) and (noteon=0) then adsrstate:=4;
if (adsrstate=4) then begin q:=q-a4s; if q<=0 then begin q:=0; adsrstate:=0; end;   end;
result:=q;
//fmwindow.box(0,0,100,16,0); fmwindow.outtextxy(0,0,inttostr(adsrstate),120); fmwindow.outtextxy(24,0,inttostr(q),120);
end;




function play(freq:integer):integer;

const i:integer=0;
      q:cardinal=0;
      r:int64=0;
      s:int64=0;

var p: int64;


begin
a:=a+notes[freq,0];
b:=(b+notes[freq,0]*2);
c:=(c+notes[freq,0]*3);
i:=i+1;
if i=20 then begin q:=adsr; i:=0; end;
p:=(q*(sinetable[((a+r*20) and $FFFFFFFF) shr 16])) shr 40;
r:=((4000000000) *(sinetable[(b + s*20) shr 16])) shr 40;
s:=((4000000000) *(sinetable[c shr 16])) shr 40;

result:=p;
end;

procedure audiocallback(userdata: Pointer; stream: PUInt8; len:Integer );

var audio2:psmallint;
    i,q:integer;


begin
t:=gettime;
audio2:=psmallint(stream);
for i:=0 to (len div 4) -1 do
  begin
  q:=play(n);
  audio2[2*i]:=q;
  audio2[2*i+1]:=q;
  end;
tt:=gettime-t
end;

end.

