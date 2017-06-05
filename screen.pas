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



   screentime:int64;
   fi,np,sc,status:Twindow;


   testbutton,testbutton2:TButton;

procedure initscreen;
procedure refreshscreen;
procedure mandelbrot;
procedure writebmp;

implementation

uses globalconst,simpleaudio,retromouse,blitter,playerunit;

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


c:=0;
avsct:=0;
avspt:=0;
avall:=0;
avsid:=0;

testbutton:=Tbutton.create(2,2,100,22,8,15,'Start',panel);
//testbutton2:=Tbutton.create(10,260,150,32,21,28,'Resize canvas',status);
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
//panel.buttons.checkall;
screentime:=gettime;
frame:=(framecnt mod 32) div 2;


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
 {
if filetype=0 then s2:='SIDCog DMP file, '+inttostr(songfreq)+' Hz'
else if filetype=1 then s2:='PSID file, '+inttostr(1000000 div siddelay)+' Hz'
else if filetype=3 then s2:='Wave file, '+inttostr(head.srate)+' Hz'
else if filetype=4 then s2:='MP3 file, '+inttostr(head.srate)+' Hz, ' + inttostr(head.brate)+' kbps'
else if filetype=5 then s2:='MP2 file'
else if filetype=6 then s2:='Module file';
if s1='' then begin s1:='No file playing'; s2:=''; end;
  }
if filetype=0 then s2:=inttostr(songfreq)
else if filetype=1 then s2:=inttostr(1000000 div siddelay)
else if filetype=3 then s2:='??'   //'Wave file, '+inttostr(head.srate)+' Hz'
else if filetype=4 then s2:=inttostr(head.brate)
else if filetype=5 then s2:=inttostr(head.brate)
else if filetype=6 then s2:='??'; //'Module file';
if s1='' then begin s1:='No file playing'; s2:=''; end;

sl1:=8*length(s1);
sl2:=8*length(s2);
if sl1>sl2 then i:=16+sl1 else i:=16+sl2;
if i<192 then i:=192;
//np.l:=i;
//np.box(0,8,i,16,0);
s1:=copy(s1,1,38);
if pl<>nil then begin pl.box(222,52,304,16,0); pl.outtextxy(222,52,s1,200); end;
if pl<>nil then pl.box(220,84,32,16,0);
if pl<>nil then pl.outtextxy(252-8*length(s2),84,s2,200);
s2:=inttostr((SA_getcurrentfreq) div 1000);
if pl<>nil then pl.box(309,84,24,16,0);
if pl<>nil then pl.outtextxy(333-8*length(s2),84,s2,200);





//refresh the status bar

panel.box(1724,4,64,16,11);
panel.outtextxy(1724,4,clock,0);

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

