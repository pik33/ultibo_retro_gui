unit serialtest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GlobalConst, Platform, retromalina, mwindows, threads, simpleaudio, blcksock, winsock2;


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


    type TServerThread=class (TThread)

         protected
           procedure Execute; override;
         public
           Constructor Create(CreateSuspended : boolean);
    end;

    type TClientThread=class (TThread)

         protected
           procedure Execute; override;
         public
           Constructor Create(CreateSuspended : boolean);
    end;


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
    const i:integer=0;

begin
ThreadSetpriority(ThreadGetCurrent,6);
threadsleep(1);
sw:=TWindow.create(1152,800,'Serial receive');
sw.move(200,200,800,600,0,0);
sw.tc:=200;
sw.bg:=0;
sw.cls(0);
sleep(200);
initI2SMaster;
sleep(200);
//initI2Smasterreceiver;
sleep(200);
//i:=SerialOpen(1000000,SERIAL_DATA_8BIT,SERIAL_STOP_1BIT,SERIAL_PARITY_NONE,SERIAL_FLOW_NONE,0,0);
//sw.println(inttostr(i));
//for i:=1 to 6 do begin serialread(@testbuf[0],1024,count);  sw.println(inttostr(i)); end;
repeat
  repeat threadsleep(1) until i2stransmitted;
  i2stransmitted:=false; i:=(i+1) and $7F;
//  for i:=0 to 127 do
  sw.print(inttohex(outbuf[i],8)+' ');
//  sw.println(' ');
  if keypressed then begin readkey; repeat threadsleep(100) until keypressed; readkey; end;
until sw.needclose;
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
repeat
  threadsleep(1)
//  repeat threadsleep(0); until keypressed;
//  ch:=readkey;
//  serialwrite(@ch,1,count);
//  if ch=141 then sw2.println('') else sw2.print(chr(ch));
until sw2.needclose;
sw2.destroy;
sw2:=nil;
end;





constructor TClientThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

constructor TServerThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TServerThread.execute;

var sock:TUDPBlockSocket;
    buf:string;

begin
sock:=TUDPBlockSocket.create;
sock.createsocket;
sock.bind('127.0.0.1','12345');
while buf<>'exit' do
  begin
  buf:=sock.RecvPacket(1000);
//  if buf<>'' then  form1.memo1.lines.add(buf);
  sleep(1);
  end;
end;

procedure TClientThread.execute;

label p999;

var sock:TUDPBlockSocket;
    buf:string;
    result:boolean;
    IPAddress:string;
     Winsock2TCPClient:TWinsock2TCPClient;

const i:integer=0;

begin
//result:=SetIPAddress('Network0','192.168.2.10','255.255.255.0','192.168.2.1');

Winsock2TCPClient:=TWinsock2TCPClient.Create;


sw2:=TWindow.create(800,600,'Network transmit');
sw2.move(1100,200,800,600,0,0);
sw2.tc:=26;
sw2.bg:=0;
sw2.cls(0);
i:=0;
REPEAT i+=1; IPAddress:=Winsock2TCPClient.LocalAddress;    sw2.println('Waiting for ip '+ inttostr(i)); threadsleep(500) until ((ipaddress<>'') or (i>29));
if i>19 then
  begin
  sw2.println('No IP address available, closing.');
  threadsleep(2000);
  goto p999;
  end;
sw2.println('IP Address: '+ipaddress);
i:=0;

sock:=TUDPBlockSocket.create;
sock.connect('192.168.2.2','12345');

repeat
  i:=i+1;
  buf:='Test string '+inttostr(i);
  sw2.println(buf);
  sock.sendstring(buf);
  threadsleep(200);
until sw2.needclose;

p999:
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

initialization

//SetIPAddress('Network0','192.168.2.10','255.255.255.0','192.168.2.1');

end.

