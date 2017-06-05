unit mandelbrot;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mwindows, threads;

type TMandelthread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

var man:TWindow=nil;

implementation

constructor TMandelthread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;


procedure TMandelthread.execute;

// from the Ultibo forum, changed to work in window;

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
ThreadSetAffinity(ThreadGetCurrent,4);
sleep(1);
if man=nil then
  begin
  man:=TWindow.create(1024,600,'Mandelbrot');
  man.decoration.hscroll:=false;
  man.decoration.vscroll:=false;
  man.resizable:=false;
  man.cls(0);
  man.move(300,400,960,600,0,0);
  end;
ixmax:=960;
iymax:=600;
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
    man.putpixel(ix-1, iy-1, colour);
    end;
  end;
repeat sleep(100) until man.needclose;
man.destroy;
man:=nil;
end;

end.

