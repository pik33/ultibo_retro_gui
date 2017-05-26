unit screen;

{$mode objfpc}{$H+}

// A set of screen initting, refreshing and saving procedures
// for the retromachine player
// pik33@o2.pl
// gpl2
// rev. 20170205


interface

uses sysutils,classes,retromalina,platform,retro,mwindows,threads;

const ver='The retromachine player v. 0.23u --- 2017.04.26';

type bmppixel=array[0..2] of byte;

  TOscilloscope= class(TThread)
  private
  protected
    procedure Execute; override;
  public
   Constructor Create;
  end;

 TStatus= class(TThread)
  private
  protected
    procedure Execute; override;
  public
   Constructor Create;
  end;

var test:integer ;
    licznik:integer=0;
    songname:string;
    q1,q2,q3:extended;
    thread:TRetro;
    spr0x,spr0y,spr0dx,spr0dy:integer;
    spr1x,spr1y,spr1dx,spr1dy:integer;
    spr2x,spr2y,spr2dx,spr2dy:integer;
    spr3x,spr3y,spr3dx,spr3dy:integer;
    spr4x,spr4y,spr4dx,spr4dy:integer;
    spr5x,spr5y,spr5dx,spr5dy:integer;
    spr6x,spr6y,spr6dx,spr6dy:integer;

    c:int64=0;
    c6:int64=1;
    avsct:int64=0;
    avspt:int64=0;
    avall:int64=0;
    avsid:int64=0;
    av6502:int64=0;
    qq:integer;
    avsct1,avspt1,sidtime1,av65021:array[0..59] of integer;
    song:word=0;
    songs:word=0;
    tbb:array[0..15] of integer;


   bmphead:array[0..53] of byte=(
        $42,$4d,$36,$e0,$5b,$00,$00,$00,$00,$00,$36,$00,$00,$00,$28,$00,
        $00,$00,$00,$07,$00,$00,$60,$04,$00,$00,$01,$00,$18,$00,$00,$00,
        $00,$00,$00,$e0,$5b,$00,$23,$2e,$00,$00,$23,$2e,$00,$00,$00,$00,
        $00,$00,$00,$00,$00,$00);
   bmpbuf:packed array[0..2007039] of bmppixel;
   bmpi:integer;
   bmpp:bmppixel absolute bmpi;
   a1base:integer=440;

   // animated sprites definitions
   spr0,spr1,spr2,spr3,spr4,spr5,spr6:TAnimatedSprite;

   screentime:int64;
   fi,np,sc,status:Twindow;

   oscilloscope1:TOscilloscope;
   status1:TStatus;
//   fileinfo1:TFileInfo
   testbutton,testbutton2:TButton;

procedure initscreen;
procedure refreshscreen;
procedure mandelbrot;
procedure writebmp;

implementation

uses globalconst,simpleaudio,retromouse,blitter;

constructor TOscilloscope.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;

procedure TOscilloscope.Execute;

var scr:integer;
    wh:TWindow;
    t:int64;
begin

ThreadSetAffinity(ThreadGetCurrent,CPU_AFFINITY_1);
sleep(1);
repeat
  repeat sleep(1) until sc.redraw;
  t:=gettime;
  sc.box(0,0,884,187,178);
  sc.box(0,93,884,2,140);
  sc.box(0,27,884,2,140);
  sc.box(0,158,884,2,140);
  for j:=20 to 840 do if abs(scope[j])<46000 then sc.box(10+j,93-scope[j] div 768,2,2,190);
  sc.redraw:=false;
  t:=gettime-t;
  sc.outtextxy(0,0,inttostr(t),15);
  until terminated;
end;

constructor TStatus.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;

procedure TStatus.Execute;

var scr,i:integer;
    wh:TWindow;
    t:int64;
    s1,s2,s3:string;
    c1,l1,l2,l3:integer;


const cpuclock:integer=0;
      cputemp:integer=0;
      cnt:integer=0;


begin
ThreadSetAffinity(ThreadGetCurrent,CPU_AFFINITY_1);
sleep(1);
cputemp:=TemperatureGetCurrent(0) div 1000;
cpuclock:=clockgetrate(8) div 1000000;

repeat

  repeat sleep(1) until status.redraw;

  c1:=framecnt mod 60;
  status.box(0,0,300,300,147);
  status.outtextxy(10,10,'CPU load: ',157);

  i:=length(inttostr(round(100*avsct/16666)));
  status.outtextxy(30,30,'screen: ',157);
  status.outtextxy(180-8*i,30,inttostr(round(100*avsct/16666))+'%',157);
  i:=length(inttostr(avsct));
  status.outtextxy(230-8*i,30,inttostr(avsct)+' us',157);

  status.outtextxy(30,48,'sprites: ',157);
  i:=length(inttostr(round(100*avspt/16666)));
  status.outtextxy(180-8*i,48,inttostr(round(100*avspt/16666))+'%',157);
  i:=length(inttostr(avspt));
  status.outtextxy(230-8*i,48,inttostr(avspt)+' us',157);

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
  status.outtextxy(30,66,s1,157);
  status.outtextxy(180-l3,66, s3+'%',157);
  status.outtextxy(230-l2,66, s2+' us',157);
  s1:='6502 emulation:';
  s2:=floattostrf((av6502/16),fffixed,4,1);
  s3:=inttostr(round((100*av6502)/(16*2500)));
  l2:=length(s2)*8;
  l3:=length(s3)*8;

  status.outtextxy(30,84,s1,157);
  status.outtextxy(180-l3,84,s3+'%',157);
  status.outtextxy(246-l2,84,s2+' us',157);

  s1:=inttostr(cpuclock);
  l1:=8*length(s1);
  status.outtextxy(10,112,'CPU clock: ',157);
  status.outtextxy(230-l1,112, s1+' MHz',157);

  s1:=inttostr(cputemp);
  l1:=8*length(s1);

  status.outtextxy(10,132,'CPU temperature: ',157);
  status.outtextxy(230-l1, 132, s1+' C',157);

  status.outtextxy(10,152,'Sampling frequency: ',157);
  s1:=inttostr(SA_getcurrentfreq);
  l1:=8*length(s1);

  status.outtextxy(230-l1,152,s1+ ' Hz',157);
  status.outtextxy(10,172,'A4 base frequency: ',157);
  status.outtextxy(206,172, inttostr(a1base)+' Hz',157);


  s1:=inttostr(-vol123);
  if vol123<73 then s1:=inttostr(-vol123) else s1:='Mute' ;
  l1:=8*length(s1);
  if l1<32 then s1:=s1+' dB';
  status.outtextxy(10,192,'Volume: ',157);
  status.outtextxy(230-l1,192,s1,157);

  status.outtextxy(10,212,'Mouse type:',157);
  status.outtextxy(222,212,inttostr(mousetype),157);

  status.outtextxy(10,232,'SID waveforms:',157);

  if channel1on=1 then status.outtextxyz(154,232,inttostr(peek(base+$d404)shr 4),122,2,1);  // SID waveform
  if channel2on=1 then status.outtextxyz(184,232,inttostr(peek(base+$d40b)shr 4),202,2,1);
  if channel3on=1 then status.outtextxyz(214,232,inttostr(peek(base+$d412)shr 4),42,2,1);

  if (cnt mod 60)=0 then
    begin
    for i:=0 to 14 do tbb[i]:=tbb[i+1];
    tbb[15]:=TemperatureGetCurrent(0); // temperature
    cputemp:=0; for i:=0 to 15 do cputemp+=tbb[i] ;
    cputemp:=cputemp div 16000;
    end;
  if (cnt mod 120)=30 then cpuclock:=clockgetrate(8) div 1000000;
  cnt+=1;
  status.buttons.checkall;
    if testbutton2.clicked=1 then begin
     if status.wl=600 then status.resize(900,900) else status.resize(600,600); testbutton2.clicked:=0; end;
  status.redraw:=false;

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
end;


procedure rainbow(a:integer); //1011

begin
box2(10,a,1782,1012,48+16);
box2(10,a+2,1782,1014,48+17);
box2(10,a+4,1782,1016,48+18);
box2(10,a+6,1782,1018,48+19);
box2(10,a+8,1782,1020,48+20);
box2(10,a+10,1782,1022,48+21);
box2(10,a+12,1782,1024,48+22);
box2(10,a+14,1782,1026,48+23);
box2(10,a+16,1782,1028,48+24);
box2(10,a+18,1782,1030,48+25);
box2(10,a+20,1782,1032,48+26);
box2(10,a+22,1782,1034,48+27);
box2(10,a+24,1782,1036,48+28);
box2(10,a+26,1782,1038,48+29);
box2(10,a+28,1782,1040,48+30);
box2(10,a+30,1782,1042,48+31);
box2(10,a+32,1782,1044,48+32);
box2(10,a+34,1782,1046,48+33);
box2(10,a+36,1782,1048,48+34);
box2(10,a+38,1782,1050,48+35);
box2(10,a+40,1782,1052,48+36);
box2(10,a+42,1782,1054,48+37);
box2(10,a+44,1782,1056,48+38);
box2(10,a+46,1782,1058,48+39);
end;


procedure initscreen;

var i:integer;
    b:byte;
    c:cardinal;
    a:array[0..3] of byte absolute c;

begin

// hide all sprites

sprite0xy:=$01001100;          // setting sprite x >2048 will hide it
sprite1xy:=$01001100;
sprite2xy:=$01001100;
sprite3xy:=$01001100;
sprite4xy:=$01001100;
sprite5xy:=$01001100;
sprite6xy:=$01001100;
sprite7xy:=$01001100;

// set the sprite zoom @ 2,2
// except sprite 7 which will be the mouse cursor

sprite0zoom:=$00020002;
sprite1zoom:=$00020002;
sprite2zoom:=$00020002;
sprite3zoom:=$00020002;
sprite4zoom:=$00020002;
sprite5zoom:=$00020002;
sprite6zoom:=$00020002;
sprite7zoom:=$00010001;


// --------- set the screen resolution and pallettes

bordercolor:=$0;
graphicmode:=0;
xres:=1792;
yres:=1120;

setpallette(ataripallette,0);
setpallette(ataripallette,1);
setpallette(ataripallette,2);
setpallette(ataripallette,3);

//sethidecolor(250,0,$80);   // the sprites will hide behind these colors
//sethidecolor(44,0,$80);
//sethidecolor(190,0,$80);
//sethidecolor(188,0,$80);
//sethidecolor(154,0,$80);

// prepare the scroll bar

rainbow(811);
i:=displaystart;
outtextxyz(24,819,'A retromachine SID and WAV player by pik33 --- inspired by Johannes Ahlebrand''s Parallax Propeller SIDCog ---',89,2,2);
cleandatacacherange(i,1120*1792);
blit8(i,10,811,i+$200000,10,911,1771,48,1792,1792);
rainbow(911);
outtextxyz(24,919,' F1,F2,F3 - channels 1..3 on/off; 1-100 Hz, 2-200 Hz, 3-150 Hz, 4-400 Hz, 5-50 Hz; P - pause; up/down/enter - ',89,2,2);
cleandatacacherange(i,1120*1792);
blit8(i,10,911,i+$200000,10,959,1771,48,1792,1792);
rainbow(1011);
outtextxyz(24,1019,'select; F-432 Hz; G-440 Hz; Q-volume up; A-volume down; + - next subsong; - - previous subsong; ESC-reboot -- ',89,2,2);
cleandatacacherange(i,1120*1792);
blit8(i,10,1011,i+$200000,10,1007,1771,48,1792,1792);


// -------------- Now prepare the screen



cls(202);
//box2(0,1095,1791,1119,11);
// clear the variables for time calculating

c:=0;
avsct:=0;
avspt:=0;
avall:=0;
avsid:=0;

// Set animated sprites definitions.
// The "balls" is an rotating blue ball definition
// The rest of colors will be set by exchanging color components

spr0:=balls;           // blue ball

for i:=0 to 16383 do   // green ball
  begin
  c:=balls[i];
  b:=a[0]; a[0]:=a[1]; a[1]:=b;
  spr1[i]:=c;
  end;

for i:=0 to 16383 do  // red ball
  begin
  c:=balls[i];
  b:=a[0]; a[0]:=a[2]; a[2]:=b;
  spr2[i]:=c;
  end;

for i:=0 to 16383 do  // cyan ball
  begin
  c:=balls[i];
  a[1]:=a[0];
  spr3[i]:=c;
  end;

for i:=0 to 16383 do  // magenta ball
  begin
  c:=balls[i];
  a[2]:=a[0];
  spr4[i]:=c;
  end;

for i:=0 to 16383 do // yellow ball
  begin
  c:=balls[i];
  b:=a[0];
  a[0]:=a[2];
  a[1]:=b;
  a[2]:=b;
  spr5[i]:=c;
  end;

for i:=0 to 16383 do  // white ball
  begin
  c:=balls[i];
  a[1]:=a[0];
  a[2]:=a[0];
  spr6[i]:=c;
  end;

// initialize sprite speeds

spr0dx:=1;
spr0dy:=1;
spr1dx:=2;
spr1dy:=2;
spr2dx:=3;
spr2dy:=3;
spr3dx:=4;
spr3dy:=4;
spr4dx:=5;
spr4dy:=5;
spr5dx:=6;
spr5dy:=6;
spr6dx:=7;
spr6dy:=7;

sc:=Twindow.create(884,187,'Oscilloscope');      //884,187
sc.decoration.hscroll:=false;
sc.decoration.vscroll:=false;
sc.resizable:=false;
sc.move(10,410,884,187,0,0);

np:=Twindow.create(840,80,'Now playing');      //840,132     18,864,840,132,244
np.decoration.hscroll:=false;
np.decoration.vscroll:=false;
np.cls(0);
np.resizable:=false;
np.move(10,635,840,80,0,0);


fi:=Twindow.create(600,600,'File information');      //884,187
fi.cls(15);
fi.outtextxy(10,10,'No file playing', 35);
fi.move(10,50,360,300,0,0);

status:=Twindow.create(600,600,'System status');
status.bg:=147;
status.cls(147);
status.move(400,50,300,300,0,0);

oscilloscope1:=toscilloscope.create;
oscilloscope1.Start;
status1:=tstatus.create;
status1.Start;

testbutton:=Tbutton.create(2,2,100,22,8,15,'Start',panel);
testbutton2:=Tbutton.create(10,260,150,32,21,28,'Resize canvas',status);
end;


procedure refreshscreen;

var v,a,aaa,c1,ii,i,cc:integer;
    mm,hh,ss:int64;
    mms,hhs,sss:string;
    clock:string;
    frame:cardinal;
    sl1,sl2:integer;
    s1,s2:string;

begin

clock:=timetostr(now);
waitvbl;
//repeat sleep(1) until background.redraw;
panel.buttons.checkall;
screentime:=gettime;
frame:=(framecnt mod 32) div 2;

// animate the sprites

sprite0ptr:=cardinal(@spr0[0])+4096*frame;
sprite1ptr:=cardinal(@spr1[0])+4096*frame;
sprite2ptr:=cardinal(@spr2[0])+4096*frame;
sprite3ptr:=cardinal(@spr3[0])+4096*frame;
sprite4ptr:=cardinal(@spr4[0])+4096*frame;
sprite5ptr:=cardinal(@spr5[0])+4096*frame;
sprite6ptr:=cardinal(@spr6[0])+4096*frame;

// Refresh the window with song name and time

ss:=(songtime div 1000000) mod 60;
mm:=(songtime div 60000000) mod 60;
hh:=(songtime div 3600000000);
sss:=inttostr(ss); if ss<10 then sss:='0'+sss;
mms:=inttostr(mm); if mm<10 then mms:='0'+mms;
hhs:=inttostr(hh); if hh<10 then hhs:='0'+hhs;

songfreq:=1000000 div siddelay;
if songs>1 then s1:=songname+', song '+inttostr(song+1)
else s1:=songname;

if filetype=0 then s2:='SIDCog DMP file, '+inttostr(songfreq)+' Hz'
else if filetype=1 then s2:='PSID file, '+inttostr(1000000 div siddelay)+' Hz'
else if filetype=3 then s2:='Wave file, '+inttostr(head.srate)+' Hz'
else if filetype=4 then s2:='MP3 file, '+inttostr(head.srate)+' Hz, ' + inttostr(head.brate)+' kbps'
else if filetype=5 then s2:='MP2 file'
else if filetype=6 then s2:='Module file';
if s1='' then begin s1:='No file playing'; s2:=''; end;

sl1:=8*length(s1);
sl2:=8*length(s2);
if sl1>sl2 then i:=16+sl1 else i:=16+sl2;
if i<192 then i:=192;
np.l:=i;
np.box(0,8,i,16,0);
np.outtextxy((i-sl1) div 2,8,s1,250);
np.box(0,32,i,16,0);
np.outtextxy((i-sl2) div 2,32,s2,250);
np.box(0,56,i,32,0);
np.outtextxyz((i-128) div 2,56,hhs+':'+mms+':'+sss,190,2,1);



//refresh the status bar

panel.box(1724,4,64,16,11);
panel.outtextxy(1724,4,clock,0);

// if the file is SID then move the sprites acccording to SID regs

if filetype<3 then
  begin
  if channel1on=1 then sprite0x:=(dpeek(base+$d400) div 40)+74 else sprite0x:=2048;
  sprite0y:=920-3*(peek(base+$d406) and $F0);

  if channel2on=1 then sprite1x:=((peek(base+$d407)+256*peek(base+$d408)) div 40)+74 else sprite1x:=2048;
  sprite1y:=920-3*(peek(base+$d40d) and $F0);

  if channel3on=1 then sprite2x:=(dpeek(base+$d40e) div 40) +74 else sprite2x:=2048; ;
  sprite2y:=920-3*(peek(base+$d414) and $F0);

  sprite3x:=2048;
  sprite4x:=2048;
  sprite5x:=2048;
  sprite6x:=2048;
  end
else  // animate the bouncing balls
  begin  // check collisions... Is it possible to add colision regs to the sprite machine?
  if (sqr(sprite0x-sprite1x)+sqr(sprite0y-sprite1y))<=4096 then begin i:=spr0dx; spr0dx:=spr1dx; spr1dx:=i; i:=spr0dy; spr0dy:=spr1dy; spr1dy:=i; end;
  if (sqr(sprite0x-sprite2x)+sqr(sprite0y-sprite2y))<=4096 then begin i:=spr0dx; spr0dx:=spr2dx; spr2dx:=i; i:=spr0dy; spr0dy:=spr2dy; spr2dy:=i; end;
  if (sqr(sprite0x-sprite3x)+sqr(sprite0y-sprite3y))<=4096 then begin i:=spr0dx; spr0dx:=spr3dx; spr3dx:=i; i:=spr0dy; spr0dy:=spr3dy; spr3dy:=i; end;
  if (sqr(sprite0x-sprite4x)+sqr(sprite0y-sprite4y))<=4096 then begin i:=spr0dx; spr0dx:=spr4dx; spr4dx:=i; i:=spr0dy; spr0dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite0x-sprite5x)+sqr(sprite0y-sprite5y))<=4096 then begin i:=spr0dx; spr0dx:=spr5dx; spr5dx:=i; i:=spr0dy; spr0dy:=spr5dy; spr5dy:=i; end;
  if (sqr(sprite0x-sprite6x)+sqr(sprite0y-sprite6y))<=4096 then begin i:=spr0dx; spr0dx:=spr6dx; spr6dx:=i; i:=spr0dy; spr0dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite1x-sprite2x)+sqr(sprite1y-sprite2y))<=4096 then begin i:=spr1dx; spr1dx:=spr2dx; spr2dx:=i; i:=spr1dy; spr1dy:=spr2dy; spr2dy:=i; end;
  if (sqr(sprite1x-sprite3x)+sqr(sprite1y-sprite3y))<=4096 then begin i:=spr1dx; spr1dx:=spr3dx; spr3dx:=i; i:=spr1dy; spr1dy:=spr3dy; spr3dy:=i; end;
  if (sqr(sprite1x-sprite4x)+sqr(sprite1y-sprite4y))<=4096 then begin i:=spr1dx; spr1dx:=spr4dx; spr4dx:=i; i:=spr1dy; spr1dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite1x-sprite5x)+sqr(sprite1y-sprite5y))<=4096 then begin i:=spr1dx; spr1dx:=spr5dx; spr5dx:=i; i:=spr1dy; spr1dy:=spr5dy; spr5dy:=i; end;
  if (sqr(sprite1x-sprite6x)+sqr(sprite1y-sprite6y))<=4096 then begin i:=spr1dx; spr1dx:=spr6dx; spr6dx:=i; i:=spr1dy; spr1dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite2x-sprite3x)+sqr(sprite2y-sprite3y))<=4096 then begin i:=spr2dx; spr2dx:=spr3dx; spr3dx:=i; i:=spr2dy; spr2dy:=spr3dy; spr3dy:=i; end;
  if (sqr(sprite2x-sprite4x)+sqr(sprite2y-sprite4y))<=4096 then begin i:=spr2dx; spr2dx:=spr4dx; spr4dx:=i; i:=spr2dy; spr2dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite2x-sprite5x)+sqr(sprite2y-sprite5y))<=4096 then begin i:=spr2dx; spr2dx:=spr5dx; spr5dx:=i; i:=spr2dy; spr2dy:=spr5dy; spr5dy:=i; end;
  if (sqr(sprite2x-sprite6x)+sqr(sprite2y-sprite6y))<=4096 then begin i:=spr2dx; spr2dx:=spr6dx; spr6dx:=i; i:=spr2dy; spr2dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite3x-sprite4x)+sqr(sprite3y-sprite4y))<=4096 then begin i:=spr3dx; spr3dx:=spr4dx; spr4dx:=i; i:=spr3dy; spr3dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite3x-sprite5x)+sqr(sprite3y-sprite5y))<=4096 then begin i:=spr3dx; spr3dx:=spr5dx; spr5dx:=i; i:=spr3dy; spr3dy:=spr5dy; spr5dy:=i; end;
  if (sqr(sprite3x-sprite6x)+sqr(sprite3y-sprite6y))<=4096 then begin i:=spr3dx; spr3dx:=spr6dx; spr6dx:=i; i:=spr3dy; spr3dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite4x-sprite5x)+sqr(sprite4y-sprite5y))<=4096 then begin i:=spr4dx; spr4dx:=spr5dx; spr5dx:=i; i:=spr4dy; spr4dy:=spr5dy; spr5dy:=i; end;
  if (sqr(sprite4x-sprite6x)+sqr(sprite4y-sprite6y))<=4096 then begin i:=spr4dx; spr4dx:=spr6dx; spr6dx:=i; i:=spr4dy; spr4dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite5x-sprite6x)+sqr(sprite5y-sprite6y))<=4096 then begin i:=spr5dx; spr5dx:=spr6dx; spr6dx:=i; i:=spr5dy; spr5dy:=spr6dy; spr6dy:=i; end;

  // mouse is sprite 7; we want to react when tip of the arrow touches the ball, so adding 32

  if (sqr(32+sprite6x-sprite7x)+sqr(32+sprite6y-sprite7y)<=1024) and (mousek=1) then begin  spr6dx:=-spr6dx; spr6dy:=-spr6dy;  end;
  if (sqr(32+sprite5x-sprite7x)+sqr(32+sprite5y-sprite7y)<=1024) and (mousek=1) then begin  spr5dx:=-spr5dx; spr5dy:=-spr5dy;  end;
  if (sqr(32+sprite4x-sprite7x)+sqr(32+sprite4y-sprite7y)<=1024) and (mousek=1) then begin  spr4dx:=-spr4dx; spr4dy:=-spr4dy;  end;
  if (sqr(32+sprite3x-sprite7x)+sqr(32+sprite3y-sprite7y)<=1024) and (mousek=1) then begin  spr3dx:=-spr3dx; spr3dy:=-spr3dy;  end;
  if (sqr(32+sprite2x-sprite7x)+sqr(32+sprite2y-sprite7y)<=1024) and (mousek=1) then begin  spr2dx:=-spr2dx; spr2dy:=-spr2dy;  end;
  if (sqr(32+sprite1x-sprite7x)+sqr(32+sprite1y-sprite7y)<=1024) and (mousek=1) then begin  spr1dx:=-spr1dx; spr1dy:=-spr1dy;  end;
  if (sqr(32+sprite0x-sprite7x)+sqr(32+sprite0y-sprite7y)<=1024) and (mousek=1) then begin  spr0dx:=-spr0dx; spr0dy:=-spr0dy; end;

  sprite0x+=spr0dx;   // now I have to use intermediate variables to avoid wild moving of the sprites :)
  sprite0y+=spr0dy;
  if sprite0x>=1792 then spr0dx:=-abs(spr0dx);
  if sprite0y>=1096 then spr0dy:=-abs(spr0dy);
  if sprite0x<=64 then spr0dx:=abs(spr0dx);
  if sprite0y<=40 then spr0dy:=abs(spr0dy);

  sprite1x+=spr1dx;
  sprite1y+=spr1dy;
  if sprite1x>=1792 then spr1dx:=-abs(spr1dx);
  if sprite1y>=1096 then spr1dy:=-abs(spr1dy);
  if sprite1x<=64 then spr1dx:=abs(spr1dx);
  if sprite1y<=40 then spr1dy:=abs(spr1dy);

  sprite2x+=spr2dx;
  sprite2y+=spr2dy;
  if sprite2x>=1792 then spr2dx:=-abs(spr2dx);
  if sprite2y>=1096 then spr2dy:=-abs(spr2dy);
  if sprite2x<=64 then spr2dx:=abs(spr2dx);
  if sprite2y<=40 then spr2dy:=abs(spr2dy);

  sprite3x+=spr3dx;
  sprite3y+=spr3dy;
  if sprite3x>=1792 then spr3dx:=-abs(spr3dx);
  if sprite3y>=1096 then spr3dy:=-abs(spr3dy);
  if sprite3x<=64 then spr3dx:=abs(spr3dx);
  if sprite3y<=40 then spr3dy:=abs(spr3dy);

  sprite4x+=spr4dx;
  sprite4y+=spr4dy;
  if sprite4x>=1792 then spr4dx:=-abs(spr4dx);
  if sprite4y>=1096 then spr4dy:=-abs(spr4dy);
  if sprite4x<=64 then spr4dx:=abs(spr4dx);
  if sprite4y<=40 then spr4dy:=abs(spr4dy);

  sprite5x+=spr5dx;
  sprite5y+=spr5dy;
  if sprite5x>=1792 then spr5dx:=-abs(spr5dx);
  if sprite5y>=1096 then spr5dy:=-abs(spr5dy);
  if sprite5x<=64 then spr5dx:=abs(spr5dx);
  if sprite5y<=40 then spr5dy:=abs(spr5dy);

  sprite6x+=spr6dx;
  sprite6y+=spr6dy;
  if sprite6x>=1792 then spr6dx:=-abs(spr6dx);
  if sprite6y>=1096 then spr6dy:=-abs(spr6dy);
  if sprite6x<=64 then spr6dx:=abs(spr6dx);
  if sprite6y<=40 then spr6dy:=abs(spr6dy);
  end;

sprite7xy:=mousexy+$00280040;           //sprite coordinates are fullscreen
                                        //while mouse is on active screen only
                                        //so I have to add $28 to y and $40 to x
screentime:=gettime-screentime;
background.redraw:=false;

end;


procedure writebmp;

var bmp_fh,i,j,k,idx:integer;
    b:byte;
    s:string;

begin
//pauseaudio(1);
s:=timetostr(now);
for i:=1 to length(s) do if s[i]=':' then s[i]:='_';
bmp_fh:=filecreate('d:\dump'+s+'.bmp');
filewrite(bmp_fh,bmphead[0],54);
k:=0;
for i:=1119 downto 0 do
  for j:=0 to 1791 do
   begin
   idx:=peek(displaystart+(1792*i+j)); // get a color index
   bmpi:=systempallette[0,idx];        // get a color from the pallette
   bmpbuf[k]:=bmpp;                    // bmp is 24 bit while pallette is integer
   k+=1;
   end;
for i:=0 to 119 do begin filewrite(bmp_fh,bmpbuf[i*17920],53760); threadsleep(10); end;
fileclose(fh);
//sleep(1000);
//pauseaudio(0);
end;

procedure mandelbrot;

// from the Ultibo forum;

const cxmin = -2.5;
      cxmax =  1.5;
      cymin = -1.0;
      cymax =  1.0;
      maxiteration = 255;
      escaperadius = 2;

var  ixmax  :Word;
     iymax  :Word;
     ix, iy      :Word;
     cx, cy       :real;
     pixelwidth   :real;
     pixelheight  :real;

     colour    : Byte;

   zx, zy       :real;
   zx2, zy2     :real;
   iteration   : integer;
   er2         : real = (escaperadius * escaperadius);

begin

 ixmax:=1792;
 iymax:=1120;


 pixelheight:= (cymax - cymin) / iymax;
 pixelwidth:= pixelheight;

   for iy := 1 to iymax do
   begin
      cy := cymin + (iy - 1)*pixelheight;
      if abs(cy) < pixelheight / 2 then cy := 0.0;
      for ix := 1 to ixmax do
      begin
         cx := cxmin + (ix - 1)*pixelwidth;
         zx := 0.0;
         zy := 0.0;
         zx2 := zx*zx;
         zy2 := zy*zy;
         iteration := 0;
         while (iteration < maxiteration) and (zx2 + zy2 < er2) do
         begin
            zy := 2*zx*zy + cy;
            zx := zx2 - zy2 + cx;
            zx2 := zx*zx;
            zy2 := zy*zy;
            iteration := iteration + 1;
         end;
         if iteration = maxiteration then
         begin
           colour := 0;
          end
         else
         begin
            colour := iteration;
         end;
         putpixel(ix-1, iy-1, colour);

      end;
   end;


end;
end.

