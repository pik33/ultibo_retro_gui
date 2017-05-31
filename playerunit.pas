unit playerunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, retromalina, mwindows;


type TPlayerThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


var pl:TWindow=nil;


implementation

constructor TPlayerThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;


procedure TPlayerThread.Execute;

var fh,i,j:integer;

begin
pl:=Twindow.create(550,232,'');
pl.resizable:=false;
pl.move(400,500,550,231,0,0);
fh:=fileopen(drive+'Colors\Bitmaps\Player\base.rbm',$40);
    begin
    fileread(fh,pl.canvas^,127600);
    end;
fileclose(fh);
pl.needclose:=false;
sleep(10000);
pl.destroy;
pl:=nil;
end;


end.

