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

    q1,q2,q3:extended;
    thread:TRetro;
    c:int64=0;
    c6:int64=1;
    avsct:int64=0;
    avspt:int64=0;
    avall:int64=0;
    avsid:int64=0;

    qq:integer;
    avsct1,avspt1,sidtime1,av65021:array[0..59] of integer;

    tbb:array[0..15] of integer;



   bmpbuf:packed array[0..2007039] of bmppixel;
   bmpi:integer;
   bmpp:bmppixel absolute bmpi;




   screentime:int64;
   fi,np,sc,status:Twindow;


   testbutton,testbutton2:TButton;

procedure initscreen;
procedure refreshscreen;
procedure mandelbrot;


implementation

uses globalconst,simpleaudio,retromouse,blitter,playerunit;



procedure initscreen;

var i:integer;
    b:byte;
    c:cardinal;
    a:array[0..3] of byte absolute c;

begin


sprite7zoom:=$00010001;


// --------- set the screen resolution and pallettes

//bordercolor:=$0;
//graphicmode:=0;
//xres:=1792;
//yres:=1120;

//setpallette(ataripallette,0);
//setpallette(ataripallette,1);
//setpallette(ataripallette,2);
//setpallette(ataripallette,3);



// prepare the scroll bar




// -------------- Now prepare the screen


//c:=16*round(16*random)+3;
//cls(c);

cls(100);

c:=0;
avsct:=0;
avspt:=0;
avall:=0;
avsid:=0;

testbutton:=Tbutton.create(2,2,100,22,8,15,'Start',panel);

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

 {
if filetype=0 then s2:='SIDCog DMP file, '+inttostr(songfreq)+' Hz'
else if filetype=1 then s2:='PSID file, '+inttostr(1000000 div siddelay)+' Hz'
else if filetype=3 then s2:='Wave file, '+inttostr(head.srate)+' Hz'
else if filetype=4 then s2:='MP3 file, '+inttostr(head.srate)+' Hz, ' + inttostr(head.brate)+' kbps'
else if filetype=5 then s2:='MP2 file'
else if filetype=6 then s2:='Module file';
if s1='' then begin s1:='No file playing'; s2:=''; end;
  }





//refresh the status bar

panel.box(panel.l-68,4,64,16,11);
panel.outtextxy(panel.l-68,4,clock,0);


screentime:=gettime-screentime;
background.redraw:=false;

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

