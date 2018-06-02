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

implementation

procedure audiocallback(userdata: Pointer; stream: PUInt8; len:Integer ); forward;

constructor TFMSynthThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TFMSynthThread.execute;

label p999,p998;

var err:integer;

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

err:=sa_openaudio(961538,32,2,4800,@audiocallback);
if err<>0 then
  begin
  fmwindow.outtextxyz(16,16,'Error while opening audio: '+inttostr(err),120,1,1);
  fmwindow.outtextxyz(16,56,'Please close this window and then close the application which uses the audio driver ',120,1,1);
  goto p998;
  end;


p998:
repeat sleep(100) until fmwindow.needclose;
if err=0 then closeaudio;
fmwindow.destroy;
fmwindow:=nil;
p999:
end;

procedure initsinetable ;

var i:integer;
begin
for i:=0 to 65535 do
  sinetable[i]:=round(8388607*sin(2*pi*i/65536));

end;

procedure play(freq:integer);

begin

end;

procedure audiocallback(userdata: Pointer; stream: PUInt8; len:Integer );

begin


end;

end.

