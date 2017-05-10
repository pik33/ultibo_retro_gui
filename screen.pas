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

procedure initscreen;
procedure refreshscreen;
procedure mandelbrot;
procedure writebmp;

implementation

uses simpleaudio,retromouse,blitter;

procedure rainbow;

begin
box2(10,1011,1782,1012,48+16);
box2(10,1013,1782,1014,48+17);
box2(10,1015,1782,1016,48+18);
box2(10,1017,1782,1018,48+19);
box2(10,1019,1782,1020,48+20);
box2(10,1021,1782,1022,48+21);
box2(10,1023,1782,1024,48+22);
box2(10,1025,1782,1026,48+23);
box2(10,1027,1782,1028,48+24);
box2(10,1029,1782,1030,48+25);
box2(10,1031,1782,1032,48+26);
box2(10,1033,1782,1034,48+27);
box2(10,1035,1782,1036,48+28);
box2(10,1037,1782,1038,48+29);
box2(10,1039,1782,1040,48+30);
box2(10,1041,1782,1042,48+31);
box2(10,1043,1782,1044,48+32);
box2(10,1045,1782,1046,48+33);
box2(10,1047,1782,1048,48+34);
box2(10,1049,1782,1050,48+35);
box2(10,1051,1782,1052,48+36);
box2(10,1053,1782,1054,48+37);
box2(10,1055,1782,1056,48+38);
box2(10,1057,1782,1058,48+39);
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

bordercolor:=$002040;
graphicmode:=0;
xres:=1792;
yres:=1120;

setpallette(ataripallette,0);
setpallette(ataripallette,1);
setpallette(ataripallette,2);
setpallette(ataripallette,3);

sethidecolor(250,0,$80);   // the sprites will hide behind these colors
sethidecolor(44,0,$80);
sethidecolor(190,0,$80);
sethidecolor(188,0,$80);
sethidecolor(154,0,$80);

// -------------- Now prepare the screen

cls(146);
outtextxyz(128,16,ver,154,4,2);
box2(8,64,1784,1112,0);
box2(10,1062,1782,1110,120);
box2(10,800,894,848,246);
box2(10,851,894,1008,244);
outtextxyz(320,808,'Now playing',250,2,2);
box2(10,118,894,797,178);
box2(10,67,894,115,180);
outtextxyz(320,75,'File info',188,2,2);
box2(897,118,1782,1008,34);
box2(897,67,1782,115,36);
outtextxyz(1296,75,'Files',44,2,2);

// clear the variables for time calculating

c:=0;
avsct:=0;
avspt:=0;
avall:=0;
avsid:=0;

// prepare the scroll bar

rainbow;
i:=displaystart;
outtextxyz(24,1019,'A retromachine SID and WAV player by pik33 --- inspired by Johannes Ahlebrand''s Parallax Propeller SIDCog ---',89,2,2);
blit(i,10,1011,i+$200000,10,911,1771,48,1792,1792);
rainbow;
outtextxyz(24,1019,' F1,F2,F3 - channels 1..3 on/off; 1-100 Hz, 2-200 Hz, 3-150 Hz, 4-400 Hz, 5-50 Hz; P - pause; up/down/enter - ',89,2,2);
blit(i,10,1011,i+$200000,10,959,1771,48,1792,1792);
rainbow;
outtextxyz(24,1019,'select; F-432 Hz; G-440 Hz; Q-volume up; A-volume down; + - next subsong; - - previous subsong; ESC-reboot -- ',89,2,2);
blit(i,10,1011,i+$200000,10,1007,1771,48,1792,1792);

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

end;


procedure refreshscreen;

var v,a,aaa,c1,ii,i,cc:integer;
    mm,hh,ss:int64;
    mms,hhs,sss:string;
    clock:string;
    frame:cardinal;

begin

clock:=timetostr(now);
repeat sleep(0) until not background.redraw;
repeat sleep(0) until background.redraw;
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

c1:=framecnt mod 60;

// Refresh the yellow field with song name and time

ss:=(songtime div 1000000) mod 60;
mm:=(songtime div 60000000) mod 60;
hh:=(songtime div 3600000000);
sss:=inttostr(ss); if ss<10 then sss:='0'+sss;
mms:=inttostr(mm); if mm<10 then mms:='0'+mms;
hhs:=inttostr(hh); if hh<10 then hhs:='0'+hhs;

songfreq:=1000000 div siddelay;
box(18,864,840,132,244);
//box(18,960,840,32,244);

if songs>1 then outtextxyz(18,864,songname+', song '+inttostr(song+1),250,2,2)
else outtextxyz(18,864,songname,250,2,2);
if filetype=0 then outtextxyz(18,912,'SIDCog DMP file, '+inttostr(songfreq)+' Hz',250,2,2)
else if filetype=1 then outtextxyz(18,912,'PSID file, '+inttostr(1000000 div siddelay)+' Hz',250,2,2)
else if filetype=3 then outtextxyz(18,912,'Wave file, '+inttostr(head.srate)+' Hz',250,2,2)
else if filetype=4 then outtextxyz(18,912,'MP3 file, '+inttostr(head.srate)+' Hz, ' + inttostr(head.brate)+' kbps',250,2,2)
else if filetype=5 then outtextxyz(18,912,'MP2 file'{, '+inttostr(head.srate)+' Hz'},250,2,2)
else if filetype=6 then outtextxyz(18,912,'Module file'{, '+inttostr(head.srate)+' Hz'},250,2,2);
outtextxyz(18,960,hhs+':'+mms+':'+sss,190,4,2);

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

//refresh the status bar

box2(10,1062,1782,1110,118);
outtextxyz(32,1070,'Times: ',44,2,2);
outtextxyz(144,1070,'screen '+inttostr(avsct)+' us',44,2,2);
outtextxyz(400,1070,'sprites '+inttostr(avspt)+' us',186,2,2);
if sidcount<>0 then
  begin
  if filetype<3 then outtextxyz(656,1070,'SID '+inttostr(avall)+' us',233,2,2)
  else if filetype=3 then begin if sidtime>10 then outtextxyz(656,1070,'wav '+inttostr(avall)+' us',233,2,2); end
  else if filetype=4 then outtextxyz(656,1070,'mp3 '+inttostr(mp3time)+' us',233,2,2)
  else if filetype=5 then outtextxyz(656,1070,'mp2 '+inttostr(mp3time)+' us',233,2,2)
  else if filetype=6 then outtextxyz(656,1070,'mod '+inttostr(avall)+' us',233,2,2);
  end;
outtextxyz(864,1070,'6502 '+floattostrf((av6502/16),fffixed,4,1)+' us',124,2,2);
outtextxyz(1088,1070,inttostr(a1base),200,2,2);
v:=-vol123;
if vol123<73 then outtextxyz(1168,1070,inttostr(v)+' dB',24,2,2)
else outtextxyz(1184,1070,'Mute',24,2,2);
outtextxyz(1284,1070,clock,220,2,2);
outtextxyz(1560,1070,'m'+inttostr(mousetype),136,2,2);
if channel1on=1 then outtextxyz(1640,1070,inttostr(peek(base+$d404)shr 4),108,2,2);  // SID waveform
if channel2on=1 then outtextxyz(1680,1070,inttostr(peek(base+$d40b)shr 4),200,2,2);
if channel3on=1 then outtextxyz(1720,1070,inttostr(peek(base+$d412)shr 4),40,2,2);
for i:=0 to 14 do tbb[i]:=tbb[i+1];
tbb[15]:=TemperatureGetCurrent(0); // temperature
aaa:=0; for i:=0 to 15 do aaa+=tbb[i] ;
aaa:=aaa div 16000;
if aaa<75 then ii:=184
else if aaa<80 then ii:=232
else ii:=40;
outtextxyz(1434,1070,inttostr(aaa),ii,2,2);
outtextxyz(1474,1070,'C',ii,2,2);
outtextxyz(1462,1050,'.',ii,2,2);

// make the scrollbar colors change
for i:=64 to 88 do systempallette[0,i]:=systempallette[1,(i+(framecnt div 2)) mod 256] and $FFFFFF;
if (framecnt mod 32)=0 then systempallette[0,89]:=systempallette[1,(framecnt div 64) mod 256] and $FFFFFF;

// scroll the text
cc:=(2*framecnt) mod 5316;
a:=displaystart;

if cc<1772 then blit8(a+$200000,10+(cc),911,a,12,1011,1771-(cc),48,1792,1792);
if cc<1772 then blit8(a+$200000,10,959,a,11+1771-(cc),1011,(cc),48,1792,1792);

if (cc>=1772) and (cc<3544) then blit8 (a+$200000,10,1007,a,11+3543-(cc),1011,(cc-1772),48,1792,1792);
if (cc>=1772) and (cc<3544) then blit8 (a+$200000,10+(cc-1772),959,a,12,1011,1771-(cc-1772),48,1792,1792);

if (cc>=3544) then blit8 (a+$200000,10,911,a,11+5316-(cc),1011,(cc-3544),48,1792,1792);
if (cc>=3544) then blit8 (a+$200000,10+(cc-3544),1007,a,12,1011,1771-(cc-3544),48,1792,1792);

// draw the oscilloscope
box2(10,610,894,797,178);
box2(10,700,894,701,140);
box2(10,636,894,637,140);
box2(10,764,894,765,140);
for j:=20 to 840 do if abs(scope[j])<46000 then box(20+j,700-scope[j] div 768,2,2,190);

// if the file is SID then move the sprites acccording to SID regs

if filetype<3 then
  begin
  if channel1on=1 then sprite0x:=(dpeek(base+$d400) div 40)+74 else sprite0x:=2048;
  sprite0y:=920-3*(peek(base+$d406) and $F0);

  if channel2on=1 then sprite1x:=(peek(base+$d407)+256*peek(base+$d408) div 40)+74 else sprite1x:=2048;
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
  sprite7xy:=mousexy+$00280040; //sprite coordinates are fullscreen
                                //where mouse is on active screen only


                                //so I have to add $28 to y and $40 to x

screentime:=gettime-screentime;

//box(0,0,200,100,0);
//outtextxyz(0,0,inttostr(screentime),15,2,2);
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

