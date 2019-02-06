unit pwmtest;

{$mode objfpc}{$H+}

// from original Ultibo PWM example

interface

procedure pwmtest1;

implementation

uses
  Threads,
  Classes,
  simpleaudio,
  retromalina;


type tpwmthread=class(TThread)
private
protected
  procedure Execute; override;
public
 Constructor Create(CreateSuspended : boolean);
end;


{Declare a window handle, a counter and a couple of PWM devices}
var
 Handle:THandle;
 Count:Integer;
 pwmthread:TPwmthread;

procedure pwmtest1;

begin
pwmthread:=tpwmthread.create(true);
pwmthread.start;
end;

constructor Tpwmthread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure tpwmthread.execute;

begin

// First locate the PWM devices
initpwm(1000,1024);
while keypressed do readkey;
while not keypressed do
  begin
  for Count:=0 to 1024 do
    begin
    setpwm(0,count);
    setpwm(1,1024-count);
    threadsleep(1);
    end;
  for Count:=0 to 1024 do
    begin
    setpwm(1,count);
    setpwm(0,1024-count);
    threadsleep(1);
    end;
  end;
end;


end.

