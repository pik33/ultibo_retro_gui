program Project1;


{$mode objfpc}{$H+}

uses  //Ultibo units
  ProgramInit,
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  dos,
  Framebuffer,
  BCM2837,
  SysUtils,
  Classes,
  MMC,
  FileSystem,
  FATFS,
  ntfs,
  BCM2710,
  ds1307,
  rtc,
  Ultibo,
  retrokeyboard,
  retromouse,
  DWCOTG,
  retromalina,
  Unit6502,
  screen,
  mp3,
  blitter,
//  timezone;
  retro, simpleaudio, scripttest, xmp, mwindows, calculatorunit, icons, sysinfo,
  playerunit, captureunit, mandelbrot, notepad;


label p101, p102 ,p999, p998, p997;

var
    hh,mm,ss:integer;

    //longbuf:array[0..4095] of byte;

    workdir:string;

    drivetable:array['A'..'Z'] of boolean;
    c:char;
    f:textfile;
    key:integer;

    wheel:integer;
    t:int64;
    testicon, trash, calculator, console,player,status,mandel,textedit,raspbian:TIcon;
    calculatorthread:TCalculatorthread=nil;
    sysinfothread:TSysinfothread=nil;
    mandelthread:Tmandelthread=nil;
    notepadthread:Tnotepadthread=nil;
    oneicon:TIcon ;
    fh,i,j:integer;
    message:TWindow;

// ---- procedures

procedure copyfile2(src,dest:string);

var fh1,fh2,il:integer;
    buf:pbyte;

begin

buf:=Pbyte($28000000);
fh1:=fileopen(src,$40);
fh2:=filecreate(dest);
il:=fileread(fh1,buf^,16000000);
filewrite(fh2,buf^,il);
fileclose(fh1);
fileclose(fh2);
end;

//------------------- The main program

begin

initmachine(144);     // 16+128=hi, double buffered TODO init @19
initscreen;
ThreadSetAffinity(ThreadGetCurrent,CPU_AFFINITY_0);
sleep(1);
while not DirectoryExists('C:\') do
  begin
  Sleep(100);
  end;

if fileexists('C:\kernel7.img') then begin workdir:='C:\ultibo\'; drive:='C:\'; end
else if fileexists('D:\kernel7.img') then begin workdir:='D:\ultibo\' ; drive:='D:\'; end
else if fileexists('E:\kernel7.img') then begin workdir:='E:\ultibo\' ; drive:='E:\'; end
else if fileexists('F:\kernel7.img') then begin workdir:='F:\ultibo\' ; drive:='F:\'; end
else
  begin
  outtextxyz(440,1060,'Error. No Ultibo folder found. Press Enter to reboot',157,2,2);
  repeat until readkey=$141;
  systemrestart(0);
  end;

t:=SysRTCGetTime;
if t=0 then
  if fileexists(drive+'now.txt') then
    begin
    assignfile(f,drive+'now.txt');
    reset(f);
    read(f,hh); read(f,mm); read(f,ss);
    closefile(f);
    settime(hh,mm,ss,0);
    end;

//if fileexists(drive+'kernel7_l.img') then
//  begin
//  DeleteFile(pchar(drive+'kernel7.img'));
//  RenameFile(drive+'kernel7_l.img',drive+'kernel7.img');
//  end;

fh:=fileopen(drive+'Colors\Wallpapers\rpi-logo.rbm',$40);
fileread(fh,pointer($30300000)^,235*300);
for i:=0 to 299 do
  for j:=0 to 234 do
    if (peek($30300000+j+i*235)>15) or (peek($30300000+j+i*235)<5) then poke ($30000000+xres*(i+(yres div 2)-150)+j+(xres div 2) - 117,peek($30300000+j+i*235));
for c:='C' to 'F' do drivetable[c]:=directoryexists(c+':\');

songtime:=0;
siddelay:=20000;
setcurrentdir(workdir);
ThreadSetCPU(ThreadGetCurrent,CPU_ID_0);
threadsleep(1);
startreportbuffer;
startmousereportbuffer;
testicon:=TIcon.create('Drive C',background);
testicon.icon48:=i48_hdd;
testicon.x:=0; testicon.y:=192; testicon.size:=48; testicon.l:=128; testicon.h:=96; testicon.draw;
trash:=testicon.append('Trash');
trash.icon48:=i48_trash;
trash.x:=0; trash.y:=960; trash.size:=48; trash.l:=128; trash.h:=96; trash.draw;
calculator:=Testicon.append('Calculator');
calculator.icon48:=i48_calculator;
calculator.x:=256; calculator.y:=0; calculator.size:=48; calculator.l:=128; calculator.h:=96; calculator.draw;
console:=Testicon.append('Console');
console.icon48:=i48_terminal;
console.x:=384; console.y:=0; console.size:=48; console.l:=128; console.h:=96; console.draw;
player:=Testicon.append('RetAMP Player');
player.icon48:=i48_player;
player.x:=512; player.y:=0; player.size:=48; player.l:=128; player.h:=96; player.draw;
status:=Testicon.append('System status');
status.icon48:=i48_sysinfo;
status.x:=640; status.y:=0; status.size:=48; status.l:=128; status.h:=96; status.draw;
mandel:=Testicon.append('Mandelbrot');
mandel.icon48:=i48_mandelbrot;
mandel.x:=768; mandel.y:=0; mandel.size:=48; mandel.l:=128; mandel.h:=96; mandel.draw;
textedit:=Testicon.append('Text editor');
textedit.icon48:=i48_textedit;
textedit.x:=896; textedit.y:=0; textedit.size:=48; textedit.l:=128; textedit.h:=96; textedit.draw;
raspbian:=Testicon.append('Raspbian');
raspbian.icon48:=i48_raspi;
raspbian.x:=256; raspbian.y:=96; raspbian.size:=48; raspbian.l:=128; raspbian.h:=96; raspbian.draw;
//sleep(1000);
filetype:=-1;
//desired.callback:=@AudioCallback;
//desired.channels:=2;
//desired.format:=AUDIO_S16;
//desired.freq:=480000;
//desired.samples:=1200;
//error:=openaudio(@desired,@obtained);

//------------------- The main loop

repeat

  background.icons.checkall;
  if calculator.dblclicked then
    begin
    calculator.dblclicked:=false;
    if cw=nil then
      begin
      calculatorthread:=TCalculatorthread.create(true);
      calculatorthread.start;
      end;
    end;
  if cw<>nil then
    if cw.needclose then begin calculatorthread.terminate; end;
  if status.dblclicked then
     begin
     status.dblclicked:=false;
     if si=nil then
       begin
       sysinfothread:=TSysinfothread.create(true);
       sysinfothread.start;
       end;
     end;
  if si<>nil then
    if si.needclose then begin sysinfothread.terminate; end;

  if player.dblclicked then
    begin
    player.dblclicked:=false;
    if pl=nil then
      begin
      playerthread:=TPlayerthread.create(true);
      playerthread.start;
      end;
    end;

  if mandel.dblclicked then
    begin
    mandel.dblclicked:=false;
    if man=nil then
      begin
      mandelthread:=Tmandelthread.create(true);
      mandelthread.start;
      end;
    end;

  if textedit.dblclicked then
    begin
    textedit.dblclicked:=false;
    if note=nil then
      begin
      notepadthread:=Tnotepadthread.create(true);
      notepadthread.start;
      end;
    end;

  if raspbian.dblclicked then
    begin
    raspbian.dblclicked:=false;
    if fileexists(drive+'\ultibo\Raspbian.u') then
      begin
      pauseaudio(1);
      message:=twindow.create(500,112,'');
      message.cls(0);
      message.outtextxyz(16,16,'Preparing reboot to Raspbian',250,2,2);
      message.outtextxyz(16,64,'Please wait...',250,2,2);
      message.move(xres div 2 - 250, yres div 2 - 56, 600,200,0,0);
      message.select;
 //     DeleteFile(pchar(drive+'kernel7_l.img'));
      if not fileexists(drive+'kernel7_c.img') then RenameFile(drive+'kernel7.img',drive+'kernel7_c.img') else deletefile(pchar(drive+'kernel7.img'));
      RenameFile(drive+'kernel7_l.img',drive+'kernel7.img');
//      CopyFile2(drive+'\ultibo\Raspbian.u',drive+'kernel7.img');
//      stopmachine;
      systemrestart(0);
      end;
    end;

  refreshscreen;
  key:=getkey and $FF;
//  panel.checkmouse;
//  background.checkmouse;

//  if key=ord('s') then   // script test
//    begin
//    script1;
//    readkey;
//    end


  until {(mousek=3) or }(key=key_escape) ;
pauseaudio(1);
if sfh>0 then fileclose(sfh);
setcurrentdir(workdir);
stopmachine;
systemrestart(0);
end.

