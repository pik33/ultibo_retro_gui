unit serialtest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GlobalConst, Platform, retromalina, mwindows, threads;

type TSerialThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

type TSerialThread2=class (TThread)

       private
       protected
         procedure Execute; override;
       public
         Constructor Create(CreateSuspended : boolean);
       end;

var sw:TWindow=nil;
    sw2:TWindow=nil;

implementation

var
 Count:LongWord;
 ch:byte;
 Character:Char;
 Characters:String;
 i:integer;


 constructor TSerialThread.create(CreateSuspended : boolean);

 begin
 FreeOnTerminate := True;
 inherited Create(CreateSuspended);

 end;

 constructor TSerialThread2.create(CreateSuspended : boolean);

 begin
 FreeOnTerminate := True;
 inherited Create(CreateSuspended);

 end;

procedure TSerialThread.execute;

var testbuf:array[0..1023] of byte;
    i:integer;

begin
ThreadSetpriority(ThreadGetCurrent,6);
threadsleep(1);
sw:=TWindow.create(800,600,'Serial receive');
sw.move(200,200,800,600,0,0);
sw.tc:=200;
sw.bg:=0;
sw.cls(0);
i:=SerialOpen(1000000,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0);
//sw.println(inttostr(i));
//for i:=1 to 6 do begin serialread(@testbuf[0],1024,count);  sw.println(inttostr(i)); end;
repeat
  serialread(@character,1,count);
  if character=#141 then sw.println('') else sw.print(character);
until sw.needclose or (sw2=nil);
sw.destroy;
sw:=nil;
end;

procedure TSerialThread2.execute;


var testbuf:array[0..1023] of byte;
    t:int64;

begin
ThreadSetpriority(ThreadGetCurrent,6);
threadsleep(1);
for i:=0 to 1022 do testbuf[i]:=i mod 100;
testbuf[1023]:=141;
sw2:=TWindow.create(800,600,'Serial transmit');
sw2.move(1100,200,800,600,0,0);
sw2.tc:=24;
sw2.bg:=0;
sw2.cls(0);
i:=SerialOpen(460800,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0);
sw2.println('waiting 2 seconds');
threadsleep(2000) ;
sw2.println('transmission start');
t:=gettime;
for i:=0 to 1023 do serialwrite(@testbuf[i],1,count); sw2.println('1');
for i:=0 to 1023 do serialwrite(@testbuf[i],1,count); sw2.println('2');
for i:=0 to 1023 do serialwrite(@testbuf[i],1,count); sw2.println('3');
for i:=0 to 1023 do serialwrite(@testbuf[i],1,count); sw2.println('4');
for i:=0 to 1023 do serialwrite(@testbuf[i],1,count); sw2.println('5');
//serialwrite(@testbuf[0],1024,count); sw2.println('2');
//serialwrite(@testbuf[0],1024,count); sw2.println('3');
//serialwrite(@testbuf[0],1024,count); sw2.println('4');
//serialwrite(@testbuf[0],1024,count); sw2.println('5');
//serialwrite(@testbuf[0],1024,count); sw2.println('6');
t:=gettime-t;
sw2.println(inttostr(t));

repeat
  repeat threadsleep(0); until keypressed;
  ch:=readkey;
  serialwrite(@ch,1,count);
  if ch=141 then sw2.println('') else sw2.print(chr(ch));
until sw2.needclose;
sw2.destroy;
sw2:=nil;
end;

//uses

//  GlobalTypes,


//  Serial;   {Include the Serial unit so we can open, read and write to the device}

{We'll need a window handle plus a couple of others.}


procedure serialtest;

var testbuf:array[0..1023] of byte;
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

