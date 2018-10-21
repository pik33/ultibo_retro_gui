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
    outputtable:array[0..8191] of integer;
    fmwindow:TWindow=nil;
    notes:array[0..127] of integer;
    a:cardinal;
    b:cardinal;
    c:cardinal;

    n:integer;
    noteon:integer;
        t,tt,ttt,tttt:int64;

implementation

var opdata:array[0..65535] of cardinal;
// 1024 operators @ 64 entries




              // 00 - 00 - freq
              // 01 - 04 - c3
              // 02 - 08 - lfo1
              // 03 - 0c - c4
              // 04 - 10 - lfo2
              // 05 - 14 - pa
              // 06 - 18 - mul0
              // 07 - 1c - mul1
              // 08 - 20 - mul2
              // 09 - 24 - mul3
              // 10 - 28 - mul4
              // 11 - 2c - mul5
              // 12 - 30 - mul6
              // 13 - 34 - mul7
              // 14 - 38 - wavetable ptr
              // 15 - 3c - wavetable length
              // 16 - 40 - wavetable loop start
              // 17 - 44 - wavetable loop end
              // 18 - 48 - ar1
              // 19 - 4c - av1
              // 20 - 50 - ar2
              // 21 - 54 - av2
              // 22 - 58 - ar3
              // 23 - 5c - av3
              // 24 - 60 - ar4
              // 25 - 64 - av4
              // 26 - 68 - adsr bias
              // 27 - 6c - c5
              // 28 - 70 - lfo3
              // 29 - 74 - vel
              // 30 - 78 - key sense
              // 31 - 7c - c6
              // 32 - 80 - expression

              // 33..63 reserved






procedure audiocallback(userdata: Pointer; stream: PUInt8; len:Integer ); forward;
function play(freq:integer):integer;    forward;

procedure initnotes;

var i:integer;
    q:double;

begin
q:=c03;
for i:=0 to 127 do
  begin
  notes[i]:=round(q*norm960*65536);
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
//ThreadSetPriority(ThreadGetCurrent,6);
removeramlimits(integer(@play));
removeramlimits(integer(@play)+4096);

threadsleep(10);
initsinetable;
initlogtable;
initnotes;
for i:=0 to 511 do opdata[i*32+7]:=integer(@sinetable[0]);
for i:=0 to 511 do opdata[i*32+8]:=16;
n:=48;

//err:=sa_openaudio(48000,16,2,384,@audiocallback);
//if err<>0 then
///  begin
//  fmwindow.outtextxyz(16,16,'Error while opening audio: '+inttostr(err),120,1,1);
//  fmwindow.outtextxyz(16,56,'Please close this window and then close the application which uses the audio driver ',120,1,1);
//  goto p998;
//  end;
//for i:=0 to 10 do fmwindow.outtextxy(0,16*i,inttostr(sinetable[i+16380]),120);


fmwindow.outtextxy(16,48,inttohex(logtable[65535],8),15);
fmwindow.outtextxy(16,64,inttohex(logtable[49152],8),15);
fmwindow.outtextxy(16,80,inttohex(logtable[32768],8),15);
fmwindow.outtextxy(16,96,inttohex(logtable[16384],8),15);
fmwindow.outtextxy(16,112,inttohex(logtable[0],8),15);
// pauseaudio(0);   noteon:=1; threadsleep(10); noteon:=0;
p998:  {
repeat fmwindow.box(0,0,80,16,0); fmwindow.outtextxy(0,0,inttostr(tt),120);
  if getkey>0 then begin nn:=keymap2[(readkey shr 16) and $FF]; if nn>12 then begin n:=nn-12; noteon:=1; end; end;
  if getreleasedkey>0 then begin fmwindow.box(16,48,100,16,0); fmwindow.outtextxy(16,48,inttostr(readreleasedkey),120); noteon:=0; end;
  threadsleep(8);
        }


repeat
tt:=gettime;
for  i:=0 to 999 do play(64);
tt:=gettime-tt;
fmwindow.box(0,0,80,16,0); fmwindow.outtextxy(0,0,inttostr(tt),120);
threadsleep(100);

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

label p101, p199,a3fffc;

const i:integer=0;
      q:cardinal=0;
      r:int64=0;
      s:int64=0;

var
      optr,st,outputs:pointer;
      v:integer;

var p: int64;

{


      // 00 - 00 - freq   24 bit
      // 01 - 04 - c3     32 bit  8:24
      // 02 - 08 - lfo1   32 bit  signed
      // 03 - 0c - c4     32 bit  8:24
      // 04 - 10 - lfo2   32 bit  signed
      // 05 - 14 - pa     32 bit
      // 06 - 18 - mul0   24 bit  8:16
      // 07 - 1c - mul1
      // 08 - 20 - mul2
      // 09 - 24 - mul3
      // 10 - 28 - mul4
      // 11 - 2c - mul5
      // 12 - 30 - mul6
      // 13 - 34 - mul7
      // 14 - 38 - wavetable ptr
      // 15 - 3c - wavetable length
      // 16 - 40 - wavetable loop start
      // 17 - 44 - wavetable loop end
      // 18 - 48 - adsr value
      // 19 - 4c - adsr state
      // 20 - 40 - ar1
      // 21 - 54 - av1
      // 22 - 58 - ar2
      // 23 - 5c - av2
      // 24 - 50 - ar3
      // 25 - 64 - av3
      // 26 - 68 - ar4
      // 27 - 6c - av4
      // 28 - 60 - adsr bias
      // 29 - 74 - c5
      // 30 - 78 - lfo3
      // 31 - 7c - vel
      // 32 - 70 - key sense
      // 33 - 84 - c6
      // 34 - 88 - expression

      // 35..63 reserved


      freq:=c1*midi_IN_FREQ+c2
      freq:=freq+c3*lfo1
      freq:=freq*c4*lfo2

      pa:=pa+freq

      mod:=mul0*out0+mul1*out1+...+mul7*out7

      spl:=table[pa+mod]
      spl:=spl*adsr
      spl:=spl+c5*lfo3
      spl:=spl*vel*key sense
      spl:=spl*c6*expr
      out:=spl

}

begin
//ttt:=gettime;
optr:=@opdata[0];
st:=@sinetable;
//lt:=@logtable
outputs:=@outputtable;

    asm
    push {r0-r12,r14}
    ldr r0,optr
    ldr r12,outputs
    mov r14,#256




    // stage 1. Compute a new PA

//    freq:=c1*midi_IN_FREQ+c2
//    freq:=freq+c3*lfo1
//    freq:=freq*c4*lfo2

//    pa:=pa+freq


p101:  ldm r0!,{r1-r6}                  // r1 - freq
                                        // r2 - c3
                                        // r3 - lfo1
                                        // r4 - c4
                                        // r5 - lfo2
                                        // r6 - pa

       smull r7,r8,r2,r3                // r8:r7:= c3*lfo1    lfo1 as signed; out is 64 bit 8:56
       add r1,r8                        // r1:=freq+c3*lfo1
       add r5,#0x80000000               // convert lfo2 to unsigned
       umull r7,r8,r4,r5                // r8:r7=c4*lfo2  @ 9:55
       umull r7,r9,r1,r8                // r9:r7=freq*c3*lfo2 freq is 24 bit lfo2*c3 is 23 bit so 47 bit result has to be >>23 or <<9
       lsr r9,#9
       add r9,r9,r7,lsl #23
       add r6,r9
       mov r14,r6
       str r6,[r0,#-4]                  // new pa saved

//stage 1 10 ns@1300

//     stage 2

//     add modulators accordng to algo
//     PA:=PA+mod


       ldm r0!,{r1-r4}               // algo coeffs
       ldm r12!,{r5-r8}              // outputs in r2-r9

       smull r9,r10,r1,r5
       smlal r9,r10,r2,r6
       smlal r9,r10,r3,r7
       smlal r9,r10,r4,r8

       ldm r0!,{r1-r4}               // algo coeffs
       ldm r12!,{r5-r8}              // outputs in r2-r9

       smlal r9,r10,r1,r5
       smlal r9,r10,r2,r6
       smlal r9,r10,r3,r7
       smlal r9,r10,r4,r8

       add r10,r14                  // modulated PA in r10


// stage 2 18 ns @ 1300 MHz


//         stage 3
//         Load the sample       TODO: use params 14-17 instead of sinetable

         ldr r3,st
         mov r1,#0xFFFFFFFF
         sub r1,#0xFF000000
         and r10,r1
         lsl r10,#2
         ldr r14,[r3,r10]

//        stage 4
//       Compute ADSR

        add  r0,#16   //skip sample params TO DO use them
        ldm  r0!,{r1-r2}  // adsr val and state

        add r0,r0,r1,lsl #2
        ldm r0!,{r3,r4} // current stage adsr params
        add r1,r3
        cmp r1,r4
// todo!!!



  //     ldm r0!,{r2,r3}             // r2 - adsr
                                   // r3 - adsr state

   //    add r0,r0,r3,lsr #3
   //    ldm r0!,{r4,r5}

   //    add r0,#84


 //      subs r14,#1
 //      bne p101

       b p199



a3FFFc: .long 0x3FFFC

p199: pop {r0-r12,r14}

   end;


//opdata[1]:=notes[freq]  ;


//a:=a+notes[freq];
//b:=(b+notes[freq]*2);
//c:=(c+notes[freq]*3);
//i:=i+1;
//if i=20 then begin q:=adsr; i:=0; end;
//p:=(q*(sinetable[((a+r*20) and $FFFFFFFF) shr 16])) shr 40;
//r:=((4000000000) *(sinetable[(b + s*20) shr 16])) shr 40;
//s:=((4000000000) *(sinetable[c shr 16])) shr 40;
//p:=(q*v) shr 40;
result:=v;
//tttt:=gettime-ttt;
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

