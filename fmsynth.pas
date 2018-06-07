unit fmsynth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, simpleaudio, mwindows, retromalina, Threads;

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

      keymap:array[0..127] of byte=(
//     0   1   2   3   4   5   6   7   8   9
      000,000,000,000,048,042,040,050,062,051, // 000
      052,053,067,054,055,056,044,043,068,069, // 010
      060,063,049,064,066,041,061,039,065,038, // 020
      073,074,075,076,077,078,079,080,081,082, // 030
      000,000,085,000,036,083,084,070,071,000, // 040
      059,057,058,072,045,046,047,000,084,085, // 050
      086,087,088,089,090,091,092,093,094,095, // 060
      096,097,098,000,000,000,000,000,000,000, // 070
      000,000,000,000,000,000,000,000,000,000, // 080
      000,000,000,000,000,000,000,000,000,000, // 090
      037,000,000,000,000,000,000,000,000,000, // 100
      000,000,000,000,000,000,000,000,000,000, // 110
      000,000,000,000,000,000,000,000);        // 120

      keymap2:array[0..127] of byte=(
//     0   1   2   3   4   5   6   7   8   9
      000,000,000,000,049,057,053,000,071,054, // 000
      056,058,079,000,061,063,060,059,081,083, // 010
      067,072,051,074,077,055,069,052,076,050, // 020
      066,068,070,000,073,075,000,078,080,820, // 030
      000,000,087,000,000,000,085,084,086,000, // 040
      000,000,066,000,062,064,065,000,088,089, // 050
      090,091,092,093,094,095,096,097,098,099, // 060
      100,101,102,000,000,000,000,000,000,000, // 070
      000,000,000,000,000,000,000,000,000,000, // 080
      000,000,000,000,000,000,000,000,000,000, // 090
      048,000,000,000,000,000,000,000,000,000, // 100
      000,000,000,000,000,000,000,000,000,000, // 110
      000,000,000,000,000,000,000,000);        // 120


var sinetable:array[0..65535] of integer;
    logtable:array[0..65535] of cardinal;
    fmwindow:TWindow=nil;
    notes:array[0..127,0..2] of integer;
    a:cardinal;
    b:cardinal;
    c:cardinal;

    n:integer;
    noteon:integer;
        t,tt:int64;

implementation

var opdata:array[0..16383] of cardinal;


// 0 - PA
// 1 - freq
// 2 - fmod1
// 3 - fmod2
// 4 - fmod3
// 5 - fmod4
// 6 - LFO freq
// 7 - reserved
// 8 - vol
// 9 - velocity
//10 - ADSR
//11 - LFO vol
//12..15 reserved



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

procedure initlogtable ;

var i:integer;
    q,q2:double;

begin
q:=4294967296;
q2:=0.999841363784793800909651;

for i:=65535 downto 0 do
 begin
  q:=q*q2;
 logtable[i]:=trunc(q);
 end;
end;

constructor TFMSynthThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TFMSynthThread.execute;

label p999,p998;

var i,err,nn:integer;
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
ThreadSetPriority(ThreadGetCurrent,6);
sleep(10);
initsinetable;
initlogtable;
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
fmwindow.outtextxy(16,48,inttohex(logtable[65535],8),15);
fmwindow.outtextxy(16,64,inttohex(logtable[49152],8),15);
fmwindow.outtextxy(16,80,inttohex(logtable[32768],8),15);
fmwindow.outtextxy(16,96,inttohex(logtable[16384],8),15);
fmwindow.outtextxy(16,112,inttohex(logtable[0],8),15);
pauseaudio(0);   noteon:=1; sleep(10); noteon:=0;
p998:
repeat fmwindow.box(0,0,80,16,0); fmwindow.outtextxy(0,0,inttostr(tt),120);
  if getkey>0 then begin nn:=keymap2[(readkey shr 16) and $FF]; if nn>12 then begin n:=nn-12; noteon:=1; end; end;
  if getreleasedkey>0 then begin fmwindow.box(16,48,100,16,0); fmwindow.outtextxy(16,48,inttostr(readreleasedkey),120); noteon:=0; end;
  sleep(8);

until fmwindow.needclose;
if err=0 then closeaudio;
fmwindow.destroy;
fmwindow:=nil;
p999:
end;


function adsr:cardinal;
// 1073741824
const q:integer=0;
      adsrstate:integer=0;
      a1s:integer=2000000;
      a1l:integer=1000000000;
      a2s:integer=100000;
      a2l:integer=950000000;
      a3s:integer=5000;
      a3l:integer=100000;
      a4s:integer=20000;

begin
if ((adsrstate=0) or (adsrstate=5)) and (noteon=1) then adsrstate:=1;
if (adsrstate=1) then begin q:=q+a1s; if q>1073741824 then q:=1073741824; if q>=a1l then adsrstate:=2; end; // attack
if (adsrstate=2) then begin q:=q-a2s; if q<=a2l then adsrstate:=3; end; // decay   1
if (adsrstate=3) then begin q:=q-a3s; if q<=a3l then adsrstate:=4; end; // decay   2
if {(adsrstate=3) and} (noteon=0) then adsrstate:=5;
if (adsrstate=5) then begin q:=q-a4s; if q<=0 then begin q:=0; adsrstate:=0; end;   end;
result:=logtable[q shr 14];
//fmwindow.box(0,0,100,16,0); fmwindow.outtextxy(0,0,inttostr(adsrstate),120); fmwindow.outtextxy(24,0,inttostr(q),120);
end;




function play(freq:integer):integer;

const i:integer=0;
      q:cardinal=0;
      r:int64=0;
      s:int64=0;

var p: int64;

    // 0 - PA
    // 1 - freq
    // 2 - fmod1
    // 3 - fmod2
    // 4 - fmod3
    // 5 - fmod4
    // 6 - LFO freq
    // 7 - reserved
    // 8 - vol
    // 9 - velocity
    //10 - ADSR
    //11 - LFO vol
    //12..15 reserved



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

