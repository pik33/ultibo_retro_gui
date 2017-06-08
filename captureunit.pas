unit captureunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, retromalina;

type bmppixel=array[0..2] of byte;

var bmpbuf:packed array[0..2007039] of bmppixel;
    bmpi:integer;
    bmpp:bmppixel absolute bmpi;
    dir:string;

    bmphead:array[0..53] of byte=(
         $42,$4d,$36,$e0,$5b,$00,$00,$00,$00,$00,$36,$00,$00,$00,$28,$00,
         $00,$00,$00,$07,$00,$00,$60,$04,$00,$00,$01,$00,$18,$00,$00,$00,
         $00,$00,$00,$e0,$5b,$00,$23,$2e,$00,$00,$23,$2e,$00,$00,$00,$00,
         $00,$00,$00,$00,$00,$00);

procedure writebmp;

implementation

procedure writebmp;

var bmp_fh,i,j,k,idx:integer;
    b:byte;
    s:string;

begin
dir:=drive;
s:=timetostr(now);
for i:=1 to length(s) do if s[i]=':' then s[i]:='_';
bmp_fh:=filecreate(dir+'Colors/Capture/dump'+s+'.bmp');
filewrite(bmp_fh,bmphead[0],54);
k:=0;
for i:=yres-1 downto 0 do
  for j:=0 to xres-1 do
   begin
   idx:=peek(displaystart+(xres*i+j)); // get a color index
   bmpi:=systempallette[0,idx];        // get a color from the pallette
   bmpbuf[k]:=bmpp;                    // bmp is 24 bit while pallette is integer
   k+=1;
   end;
for i:=0 to 119 do begin filewrite(bmp_fh,bmpbuf[i*17920],53760); sleep(10); end;
fileclose(fh);
//sleep(1000);
//pauseaudio(0); }
end;

end.

