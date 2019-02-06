unit serialtest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

implementation



uses
   GlobalConst,
//  GlobalTypes,
  Platform;
//  Threads,
//  Console,
//  Framebuffer,
//  BCM2837,
//  BCM2710,
//  Serial;   {Include the Serial unit so we can open, read and write to the device}

{We'll need a window handle plus a couple of others.}
var
 Count:LongWord;
 Character:Char;
 Characters:String;
// WindowHandle:TWindowHandle;
  i:integer;

procedure serialtest;

begin
if SerialOpen(9600,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0) = ERROR_SUCCESS then
  begin
  for i:=0 to 1000 do
    begin
    SerialRead(@Character,SizeOf(Character),Count);
    if Character = #13 then
      begin
//      ConsoleWindowWriteLn(WindowHandle,'Received a line: ' + Characters);
        if Uppercase(Characters) = 'QUIT' then
          begin
           {If received then say goodbye and exit our loop}
          Characters:='Goodbye!' + Chr(13) + Chr(10);
          SerialWrite(PChar(Characters),Length(Characters),Count);
          Sleep(1000);
          Break;
          end;
        Characters:=Characters + Chr(13) + Chr(10);
       {And echo them back to the serial device using SerialWrite}
       SerialWrite(PChar(Characters),Length(Characters),Count);
       {Now clear the characters and wait for more}
       Characters:='';
      end
    else
      begin
       {Add the character to what we have already recevied}
      Characters:=Characters + Character;
      end;

     {No need to sleep on each loop, SerialRead will wait until data is received}
    end;

   {Close the serial device using SerialClose}
   SerialClose;

  end
 else
  begin
  end;
end;

end.

