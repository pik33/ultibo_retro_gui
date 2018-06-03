unit fmsynth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, simpleaudio, mwindows;

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
    n:integer;

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
fmwindow.box(0,0,80,16,0); fmwindow.outtextxy(0,0,inttostr(notes[64,0]),120);
pauseaudio(0);
p998:
repeat i:=i+1; if i=8 then i:=0; sleep(300); n:=aa[i];  until fmwindow.needclose;
if err=0 then closeaudio;
fmwindow.destroy;
fmwindow:=nil;
p999:
end;



function play(freq:integer):integer;


begin
a:=a+notes[freq,0];
result:=(sinetable[a shr 16]) div 256;
//fmwindow.box(0,0,80,16,0); fmwindow.outtextxy(0,0,inttostr(a),120);
end;

procedure audiocallback(userdata: Pointer; stream: PUInt8; len:Integer );

var audio2:psmallint;
    i,q:integer;

begin
audio2:=psmallint(stream);
for i:=0 to (len div 4) -1 do
  begin
  q:=play(n);
  audio2[2*i]:=q;
  audio2[2*i+1]:=q;
  end;
end;

end.

