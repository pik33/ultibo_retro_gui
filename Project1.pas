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
  //screen,
  HeapManager,
  mp3,
  blitter,
  retro, simpleaudio, {scripttest,} xmp, mwindows, calculatorunit, icons, sysinfo,
  playerunit, captureunit, mandelbrot, notepad, c64, fmsynth,
  camera2, gltest,gltest2,glwindows, SimpleGL,pwmtest, serialtest,shadertest,
  network, SMSC95XX,        {And the drivers for the Raspberry Pi network adapter}
  LAN78XX, http;


const ver='Colors v. 0.30 --- 2018.04.30';

var
    hh,mm,ss:integer;

    workdir:string;

    drivetable:array['A'..'Z'] of boolean;
    c:char;
    f:textfile;
    key:integer;

    wheel:integer;
    t:int64;
    desktop_icons:array[0..1023] of TIcon;
    testicon, test1icon, test2icon, trash, calculator, console,player,status,mandel,textedit,raspbian,synth,cameratest,basictest,gltesticon:TIcon;
    calculatorthread:TCalculatorthread=nil;
    sysinfothread:TSysinfothread=nil;
    mandelthread:Tmandelthread=nil;
    notepadthread:Tnotepadthread=nil;
    fmthread:TFMSynthThread=nil;

    glwindowsthread:TGLWindowsThread=nil;
    st1:Tclientthread=nil;
    st2:TServerthread=nil;
    fh,i,j,k:integer;
    message:TWindow;
    scr:cardinal;
    testbutton:TButton;
    clock:string;
    testptr:pointer;


//------------------- The main program

begin
initmachine(144);     // 16+128=hi, double buffered TODO init @19
threadsleep(1);
while not DirectoryExists('C:\') do
  begin
  Sleep(100);
  end;

if fileexists('C:\kernel7.img') then begin workdir:='C:\colors\'; drive:='C:\'; end
else if fileexists('D:\kernel7.img') then begin workdir:='D:\colors\' ; drive:='D:\'; end
else if fileexists('E:\kernel7.img') then begin workdir:='E:\colors\' ; drive:='E:\'; end
else if fileexists('F:\kernel7.img') then begin workdir:='F:\colors\' ; drive:='F:\'; end
else
  begin
  outtextxyz(440,1060,'Error. No Ultibo folder found. Press Enter to reboot',157,2,2);
  repeat until readkey=$141;
  systemrestart(0);
  end;

t:=SysRTCGetTime;
// box(0,0,100,100,0); outtextxy(0,0,inttostr(t),15); sleep(100000);
//if t=0 then
//  if fileexists(drive+'now.txt') then
//    begin
//    assignfile(f,drive+'now.txt');
//    reset(f);
//    read(f,hh); read(f,mm); read(f,ss);
//    closefile(f);
//    settime(hh,mm,ss,0);
//    end;

scr:=mainscreen+$300000;
fh:=fileopen(drive+'Colors\Wallpapers\rpi-logo.rbm',$40);
fileread(fh,pointer(scr)^,235*300);
for i:=0 to 299 do
  for j:=0 to 234 do
    if (peek(scr+j+i*235)>15) or (peek(scr+j+i*235)<5) then poke (mainscreen+xres*(i+(yres div 2)-150)+j+(xres div 2) - 117,peek(scr+j+i*235));
for c:='C' to 'F' do drivetable[c]:=directoryexists(c+':\');

songtime:=0;
siddelay:=20000;
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
//calculator.icon48:=i48_calculator;   commented out pjde
calculator.LoadICONFromFile(drive+'Colors\Icons\Calculator-01.png');    // added pjde
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
//textedit.icon48:=i48_textedit;     commented out pjde
textedit.LoadICONFromFile(drive+'Colors\Icons\Text-Edit-icon.png');    // added pjde
textedit.x:=896; textedit.y:=0; textedit.size:=48; textedit.l:=128; textedit.h:=96; textedit.draw;
raspbian:=Testicon.append('Raspbian');
raspbian.icon48:=i48_raspi;
raspbian.x:=256; raspbian.y:=96; raspbian.size:=48; raspbian.l:=128; raspbian.h:=96; raspbian.draw;
synth:=Testicon.append('FM Synthesizer');
synth.icon48:=i48_note;
synth.x:=384; synth.y:=96; synth.size:=48; synth.l:=128; synth.h:=96; synth.draw;
cameratest:=Testicon.append('Camera test');
cameratest.icon48:=i48_camera;
cameratest.x:=512; cameratest.y:=96; cameratest.size:=48; cameratest.l:=128; cameratest.h:=96; cameratest.draw;
basictest:=Testicon.append('BASIC test');
basictest.icon48:=i48_basic;
basictest.x:=640; basictest.y:=96; basictest.size:=48; basictest.l:=128; basictest.h:=96; basictest.draw;
test1icon:=Testicon.append('Network test');
test1icon.LoadICONFromFile(drive+'Colors\Icons\Adwaita\48x48\apps\web-browser.png');
test1icon.x:=768; test1icon.y:=96; test1icon.size:=48; test1icon.l:=128; test1icon.h:=96; test1icon.draw;
test2icon:=Testicon.append('Test icon 2');
test2icon.LoadICONFromFile(drive+'Colors\Icons\Adwaita\48x48\apps\user-info.png');
test2icon.x:=896; test2icon.y:=96; test2icon.size:=48; test2icon.l:=128; test2icon.h:=96; test2icon.draw;
gltesticon:=Testicon.append('OpenGL test');
gltesticon.LoadICONFromFile(drive+'Colors\Icons\Adwaita\48x48\status\weather-clear.png');
gltesticon.x:=1024; gltesticon.y:=0; gltesticon.size:=48; gltesticon.l:=128; gltesticon.h:=96; gltesticon.draw;
//gltesticon.ondblclick:=@runglthread;
gltesticon.ondblclick:=@runshaderthread;

filetype:=-1;
testbutton:=Tbutton.create(2,2,100,22,8,15,'Start',panel);



//------------------- The main loop




// todo:
// icons from ini file
// thread assigned to icon
//key:=0;

// remapping test

//testptr:=getalignedmem  (1000000,MEMORY_PAGE_SIZE);
//t:=gettime;
//tt:=remapram(cardinal(testptr),$80000000,1000000);
//t:=gettime-t;
//poke($80001234,123);
//if peek($80001234)=123 then
 // begin box(0,0,100,100,0);
//  outtextxy(0,0,'remap test ok',15);
//outtextxy(0,20,'1 MB remapped in '+inttostr(t)+' us',15);
//  outtextxy(0,40,inttostr(mmm),40);
//remapram(cardinal(testptr),cardinal(testptr),1000000);
//freemem(testptr);
// end;



repeat

  background.icons.checkall;

  if test1icon.dblclicked then
    begin
    close:=false;
    sleep(150);
//    if mousedebugwindow=nil then begin mousedebugwindow:=twindow.create(640,480,'Mouse debug'); mousedebugwindow.move(100,100,640,480,0,0); end;
    if sw=nil then begin
    st1:=Tclientthread.create(true);
    sleep(150);

    st1.start;
    st2:=Tserverthread.create(true);
    sleep(150);

    st2.start;

    end;
    test1icon.dblclicked:=false;
    end;

  if cameratest.dblclicked then
    begin
    cameratest.dblclicked:=false;
    if keypressed then readkey;
    if cmw2=nil then
      begin
      camerathread2:=TCameraThread2.create(true);
      camerathread2.start;

      threadsleep(100);

      PAThread2:=TPAThread2.create(true);
      PAThread2.start;
      cmw2:=camerathread2;
      end;
    end;

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



  if synth.dblclicked then
    begin

    synth.dblclicked:=false;
    if fmwindow=nil then
      begin

     pwmtest1;
  //    fmthread:=TFMSynthThread.create(true);
 //     fmthread.start;
      end;
    end;

  if (raspbian.dblclicked) or (key=197) then
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
      if not fileexists(drive+'kernel7_c.img') then RenameFile(drive+'kernel7.img',drive+'kernel7_c.img') else deletefile(pchar(drive+'kernel7.img'));
      RenameFile(drive+'kernel7_l.img',drive+'kernel7.img');
      RenameFile(drive+'config.txt',drive+'config_u.txt');
      RenameFile(drive+'config_l.txt',drive+'config.txt');
      RenameFile(drive+'cmdline.txt',drive+'cmdline.u');
      RenameFile(drive+'cmdline.l',drive+'cmdline.txt');
      systemrestart(3);
      end;
    end;

  waitvbl;
  panel.box(panel.l-68,4,64,16,11);
  clock:=timetostr(now);
  panel.outtextxy(panel.l-68,4,clock,0);
  key:=getkey and $FF;

// if key=ord('s') then   // script test
//  begin
//  script1;
//  readkey;
//  end;
//     box(0,0,100,100,0);    outtextxyz(0,0,inttostr(key),44,2,2);

  if key=198 then //print screen
    begin
    key:=readkey;   key:=0;
    printscreen;
    end;

  until key=key_escape;
pauseaudio(1);
if sfh>0 then fileclose(sfh);
stopmachine;
systemrestart(0);
end.

