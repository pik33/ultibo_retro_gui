unit sysinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, math, threads, retromalina, mwindows, screen, simpleaudio, retromouse, platform, playerunit;

type TSysinfoThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


var si:TWindow=nil;

implementation

constructor TSysinfoThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TSysinfoThread.Execute;

var scr,i:integer;
    wh:TWindow;
    t:int64;
    s1,s2,s3:string;
    c1,l1,l2,l3:integer;


const cpuclock:integer=0;
      cputemp:integer=0;
      cnt:integer=0;

begin
ThreadSetAffinity(ThreadGetCurrent,4);
sleep(1);
si:=Twindow.create(300,290,'System status');
si.bg:=147;
si.cls(147);
si.move(400,500,300,290,0,0);
si.decoration.hscroll:=false;
si.decoration.vscroll:=false;
si.needclose:=false;
repeat

repeat sleep(1) until si.redraw;

c1:=framecnt mod 60;
si.box(0,0,300,300,147);
si.outtextxy(10,10,'CPU load: ',157);

i:=length(inttostr(round(100*avsct/16666)));
si.outtextxy(30,30,'screen: ',157);
si.outtextxy(180-8*i,30,inttostr(round(100*avsct/16666))+'%',157);
i:=length(inttostr(avsct));
si.outtextxy(230-8*i,30,inttostr(avsct)+' us',157);

si.outtextxy(30,48,'sprites: ',157);
i:=length(inttostr(round(100*avspt/16666)));
si.outtextxy(180-8*i,48,inttostr(round(100*avspt/16666))+'%',157);
i:=length(inttostr(avspt));
si.outtextxy(230-8*i,48,inttostr(avspt)+' us',157);

if sidcount<>0 then
  begin
  if filetype<3 then      begin s1:='SID emulation:'; s2:=inttostr(avall); s3:=inttostr(round(100*avall/2500)); end
  else if filetype=3 then begin s1:='WAV processing:'; s2:=inttostr(avall); s3:=inttostr(round(100*avall/siddelay)); end
  else if filetype=4 then begin s1:='MP3 decoding:'; s2:=inttostr(mp3time); s3:=inttostr(round(100*mp3time/siddelay)); end
  else if filetype=5 then begin s1:='MP2 decoding:'; s2:=inttostr(mp3time); s3:=inttostr(round(100*mp3time/siddelay)); end
  else if filetype=6 then begin s1:='MOD decoding:'; s2:=inttostr(avall); s3:=inttostr(round(100*avall/siddelay)); end;
  end;

if (filetype<3) and (avall=0) then begin s1:='Audio decoding:'; s2:='0'; s3:='0'; end;

l2:=length(s2)*8;
l3:=length(s3)*8;
si.outtextxy(30,66,s1,157);
si.outtextxy(180-l3,66, s3+'%',157);
si.outtextxy(230-l2,66, s2+' us',157);
s1:='6502 emulation:';
s2:=floattostrf((av6502/16),fffixed,4,1);
s3:=inttostr(round((100*av6502)/(16*2500)));
l2:=length(s2)*8;
l3:=length(s3)*8;

si.outtextxy(30,84,s1,157);
si.outtextxy(180-l3,84,s3+'%',157);
si.outtextxy(246-l2,84,s2+' us',157);

s1:=inttostr(cpuclock);
l1:=8*length(s1);
si.outtextxy(10,112,'CPU clock: ',157);
si.outtextxy(230-l1,112, s1+' MHz',157);

s1:=inttostr(cputemp);
l1:=8*length(s1);

si.outtextxy(10,132,'CPU temperature: ',157);
si.outtextxy(230-l1, 132, s1+' C',157);

si.outtextxy(10,152,'Sampling frequency: ',157);
s1:=inttostr(SA_getcurrentfreq);
l1:=8*length(s1);

si.outtextxy(230-l1,152,s1+ ' Hz',157);
si.outtextxy(10,172,'A4 base frequency: ',157);
si.outtextxy(206,172, inttostr(a1base)+' Hz',157);


s1:=inttostr(-vol123);
if vol123<73 then s1:=inttostr(-vol123) else s1:='Mute' ;
l1:=8*length(s1);
if l1<32 then s1:=s1+' dB';
si.outtextxy(10,192,'Volume: ',157);
si.outtextxy(230-l1,192,s1,157);

si.outtextxy(10,212,'Mouse type:',157);
si.outtextxy(222,212,inttostr(mousetype),157);

si.outtextxy(10,232,'SID waveforms:',157);

if channel1on=1 then si.outtextxyz(154,232,inttostr(peek(base+$d404)shr 4),122,2,1);  // SID waveform
if channel2on=1 then si.outtextxyz(184,232,inttostr(peek(base+$d40b)shr 4),202,2,1);
if channel3on=1 then si.outtextxyz(214,232,inttostr(peek(base+$d412)shr 4),42,2,1);

//si.outtextxy(10,252,'windows count: '+inttostr(windowcount),157);
//si.outtextxy(10,272,'windows time: '+inttostr(windowtime),157);


if (cnt mod 60)=0 then
  begin
  for i:=0 to 14 do tbb[i]:=tbb[i+1];
  tbb[15]:=TemperatureGetCurrent(0); // temperature
  cputemp:=0; for i:=0 to 15 do cputemp+=tbb[i] ;
  cputemp:=cputemp div 16000;
  end;
if (cnt mod 120)=30 then cpuclock:=clockgetrate(8) div 1000000;
cnt+=1;
si.redraw:=false;

// compute average times

avsct1[c1]:=tim;
avspt1[c1]:=ts;
sidtime1[c1]:=sidtime;
if time6502>0 then c6+=1;
av65021[c1]:=time6502;
avsct:=0; for i:=0 to 59 do avsct+=avsct1[i]; avsct:=round(avsct/60);
avspt:=0; for i:=0 to 59 do avspt+=avspt1[i]; avspt:=round(avspt/60);
avall:=0; for i:=0 to 59 do avall+=sidtime1[i]; avall:=round(avall/60);
av6502:=0; for i:=0 to 59 do av6502+=av65021[i]; av6502:=round(av6502/60);

until terminated;
si.destroy;
si:=nil;
end;

end.

