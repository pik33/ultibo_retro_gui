program Project1;


{$mode objfpc}{$H+}

uses
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
  MMC,         {Include the MMC/SD core to access our SD card}
  FileSystem,  {Include the file system core and interfaces}
  FATFS,       {Include the FAT file system driver}
  ntfs,
  BCM2710,
  ds1307,
  rtc,
  Ultibo,
  retrokeyboard,    {Keyboard uses USB so that will be included automatically}
  retromouse,
  DWCOTG,
  retromalina,
  Unit6502,
  screen,
  mp3,
  blitter,
//  timezone;
  retro, simpleaudio, scripttest, xmp, mwindows, calculatorunit, icons, sysinfo,
  playerunit, captureunit, mandelbrot;


label p101, p102 ,p999, p998, p997;


var
    hh,mm,ss,i,j:integer;

    longbuf:array[0..4095] of byte;



    workdir:string;

    drivetable:array['A'..'Z'] of boolean;
    c:char;
    f:textfile;


    wheel:integer;
    t,tt,ttt,tttt:int64;
    srate,samples,bits:integer;
    mousedebug:boolean=false;

    wh,scope:Twindow;

    testicon, trash, calculator, console,player,status,mandel:TIcon;
    calculatorthread:TCalculatorthread=nil;
    sysinfothread:TSysinfothread=nil;
    mandelthread:Tmandelthread=nil;


// ---- procedures

//------------------- The main program

begin

initmachine;
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

if fileexists(drive+'kernel7_l.img') then
  begin
  DeleteFile(pchar(drive+'kernel7.img'));
  RenameFile(drive+'kernel7_l.img',drive+'kernel7.img');
  end;

fh:=fileopen(drive+'wallpaper.rbm',$40);
fileread(fh,pointer($30000000)^,1792*1120);
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

  refreshscreen;
 // key:=readkey and $FF;
  wh:=panel.checkmouse;
  wh:=background.checkmouse;





  p998:
 { if key=ord('5') then begin siddelay:=20000; songfreq:=50; skip:=0; end
  else if key=ord('1') then begin siddelay:=10000; songfreq:=100; skip:=0; end
  else if key=ord('2') then begin siddelay:=5000; songfreq:=200; skip:=0;end
  else if key=ord('3') then begin siddelay:=6666; songfreq:=150; skip:=0; end
  else if key=ord('4') then begin siddelay:=2500; songfreq:=400; skip:=0; end
  else if key=ord('p') then begin pause1a:=not pause1a; if pause1a then pauseaudio(1) else pauseaudio(0); end
  else if key=key_f1 then begin if channel1on=0 then channel1on:=1 else channel1on:=0; end   // F1 toggle channel 1 on/off
  else if key=key_f2 then begin if channel2on=0 then channel2on:=1 else channel2on:=0; end   // F2 toggle channel 1 on/off
  else if key=key_f3 then begin if channel3on=0 then channel3on:=1 else channel3on:=0; end   // F3 toggle channel 1 on/off

  else if key=ord('s') then   // script test
    begin
    script1;
    end

  else if key=ord('q') then   // volume up
    begin
    vol123-=1; if vol123<0 then vol123:=0;
    setdbvolume(-vol123);
    end

  else if key=ord('a') then  // volume down
    begin
    vol123+=1; if vol123>73 then vol123:=73;
    setdbvolume(-vol123);
    end

     else if key=ord('+') then  // next subsong
      begin
      if songs>0 then
        begin
        if song<songs-1 then
          begin
          song+=1;
          jsr6502(song,init);
          end;
        end;
      end

     else if key=ord('-') then // previous subsong
      begin
      if songs>0 then
        begin
        if song>0 then
          begin
          song-=1;
          jsr6502(song,init);
          end;
        end;
      end

     else if key=key_leftarrow then
       begin
       if abs(SA_GetCurrentFreq-44100)<200 then filebuffer.seek(-1760000)
       else filebuffer.seek(-7680000);
       end

     else if key=key_rightarrow then
       begin
       if abs(SA_GetCurrentFreq-44100)<200 then filebuffer.seek(1760000)
       else filebuffer.seek(7680000);
       end


     else if key=ord('f') then  // set 432 Hz
      begin
      a1base:=432;
      if abs(SA_GetCurrentFreq-44100)<200 then SA_ChangeParams(43298,0,0,0);
      if abs(SA_GetCurrentFreq-48000)<200 then SA_ChangeParams(47127,0,0,0);
      if abs(SA_GetCurrentFreq-480000)<2000 then SA_ChangeParams(471270,0,0,0);
      if abs(SA_GetCurrentFreq-96000)<400 then SA_ChangeParams(94254,0,0,0);
      if abs(SA_GetCurrentFreq-49152)<200 then SA_ChangeParams(48258,0,0,0);
      end

     else if key=ord('g') then   // set 440 Hz
       begin
       a1base:=440;
       if abs(SA_GetCurrentFreq-43298)<200 then SA_ChangeParams(44100,0,0,0);
       if abs(SA_GetCurrentFreq-47127)<200 then SA_ChangeParams(48000,0,0,0);
       if abs(SA_GetCurrentFreq-471270)<2000 then SA_ChangeParams(480000,0,0,0);
       if abs(SA_GetCurrentFreq-94254)<400 then SA_ChangeParams(96000,0,0,0);
       if abs(SA_GetCurrentFreq-48258)<200 then SA_ChangeParams(49152,0,0,0);
       end

    else if playfilename<>'' then //  key=key_enter then

      begin
      i:=length(playfilename);
      while (playfilename[i]<>'.') and (i>1) do i:=i-1;
      ext:=lowercase(copy(playfilename,i,length(playfilename)-i+1));
      if (ext<>'.wav')
        and (ext<>'.mp2')
          and (ext<>'.mp3')
            and (ext<>'.s48')
              and (ext<>'.sid')
                and (ext<>'.dmp')
                  and (ext<>'.mod')
                    and (ext<>'.s3m')
                      and (ext<>'.xm')
                        and (ext<>'it')
                          then begin playfilename:=''; goto p997; end;

      av6502:=0;


        begin
        pause1a:=true;
        pauseaudio(1);
        sleep(10);
        for i:=$d400 to $d420 do poke(base+i,0);
        if sfh>=0 then fileclose(sfh);
        sfh:=-1;
        sleep(10);
        for i:=0 to $2F do siddata[i]:=0;
        for i:=$50 to $7F do siddata[i]:=0;
        siddata[$0e]:=$7FFFF8;
        siddata[$1e]:=$7FFFF8;
        siddata[$2e]:=$7FFFF8;
        songtime:=0;

        fn:= playfilename; // currentdir2+filenames[sel+selstart,0];
        playfilename:='';
        sfh:=fileopen(fn,$40);
        s:=copy(fn,1,length(fn)-4);
        for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
        siddelay:=20000;
        filetype:=0;
        fileread(sfh,buf,4);
        if (buf[0]=ord('S')) and (buf[1]=ord('D')) and (buf[2]=ord('M')) and (buf[3]=ord('P')) then
          begin
          for i:=0 to 15 do times6502[i]:=0;
 //         fi.box(0,0,600,600,15);
  //        fi.outtextxy(10,10,'type: SDMP',178);
          songs:=0;
          fileread(sfh,buf,4);
          siddelay:=1000000 div buf[0];
  //        fi.outtextxy(10,30,'speed: '+inttostr(buf[0])+' Hz',178);
          atitle:='                                ';
          fileread(sfh,atitle[1],16);
          fileread(sfh,buf,1);
 //         fi.outtextxy (10,50,'title: '+atitle,178);
          if a1base=432 then error:=SA_changeparams(10*47127,16,2,1200)
                        else error:=SA_changeparams(10*48000,16,2,1200);
          songs:=0;
          end
       else if (buf[0]=ord('P')) and (buf[1]=ord('S')) and (buf[2]=ord('I')) and (buf[3]=ord('D')) then
          begin
          reset6502;
          sidopen(sfh);
          for i:=1 to 4 do waitvbl;
          if cia>0 then siddelay:={985248}1000000 div (50*round(19652/cia));
          filetype:=1;
          if a1base=432 then error:=SA_changeparams(10*47127,16,2,10*120)
                        else error:=SA_changeparams(10*48000,16,2,10*120);
          fileclose(sfh);
          end
       else if (buf[0]=ord('R')) and (buf[1]=ord('S')) and (buf[2]=ord('I')) and (buf[3]=ord('D')) then
          begin
          filetype:=2;

 //         fi.box(0,0,600,600,15);
 //         fi.outtextxy(10,10,'type: RSID, not yet supported',44);
          fileclose(sfh);
          end
        else if copy(fn,length(fn)-2,3)='mp3' then
          begin
          filetype:=4;
          mp3open(sfh);
          sleep(20);
          filebuffer.setmp3(1);
          sleep(50);
          for i:=0 to 15 do times6502[i]:=0;
          filetype:=4;
          filebuffer.setfile(sfh);
          sleep(200);
          songs:=0;
          if a1base=432 then error:=SA_changeparams(43298,16,2,384)
                       else error:=SA_changeparams(44100,16,2,384);

          siddelay:=8707 ;

          pauseaudio(0);
          end

         else if copy(fn,length(fn)-2,3)='mp2' then
          begin
          fileseek(sfh,0,fsfrombeginning);

          filetype:=5;
          filebuffer.setmp3(2);
          sleep(50);
          for i:=0 to 15 do times6502[i]:=0;
          filebuffer.setfile(sfh);
          sleep(200);
          songs:=0;

          siddelay:=8707 ;
                   if a1base=432 then error:=SA_changeparams(43298,16,2,384)
                       else error:=SA_changeparams(44100,16,2,384);

    //      fi.box(0,0,600,600,15);
   //       fi.outtextxy(10,10,'type: MP2',178);
          pauseaudio(0);
          end

         else if (copy(fn,length(fn)-2,3)='mod')
                       or (copy(fn,length(fn)-2,3)='s3m')
                       or (copy(fn,length(fn)-1,2)='xm')
                       or (copy(fn,length(fn)-1,2)='it')
                       then
          begin
          fileclose(sfh);
          i:=xmp_test_module(Pchar(fn),nil);
          if i<>0 then goto p102;
          if xmp_context<>nil then
            begin
            xmp_end_player(xmp_context);
            xmp_release_module(xmp_context);
            xmp_free_context(xmp_context);
            end;


          xmp_context:=xmp_create_context;
          if a1base=432 then error:=SA_changeparams(48258,16,2,384)
                        else error:=SA_changeparams(49152,16,2,384);
          siddelay:=7812;
          filetype:=6;


          i:=xmp_load_module(xmp_context,Pchar(fn));

                  xmp_set_player(xmp_context,xmp_player_interp,xmp_interp_spline);
                xmp_set_player(xmp_context,xmp_player_mix,50);
          if i<>0 then
            begin
           xmp_free_context(xmp_context);
                 goto p102;
            end;
          i:= xmp_start_player(xmp_context,49152,34);
            xmp_set_player(xmp_context,xmp_player_interp,xmp_interp_spline);
            xmp_set_player(xmp_context,xmp_player_mix,50);

          if i<>0 then
            begin
                       xmp_release_module(xmp_context);
            xmp_free_context(xmp_context);
            goto p102;
            end;
          sleep(50);
          for i:=0 to 15 do times6502[i]:=0;

//          fi.box(0,0,600,600,15);
//          fi.outtextxy(10,10,'type: MOD',178);
          pauseaudio(0);
          p102:
          end


         else if copy(fn,length(fn)-2,3)='s48' then
           begin
           fileseek(sfh,$2800,fsfrombeginning);
           filebuffer.clear;
           sleep(50);
           filetype:=5;
           filebuffer.setmp3(2);
           for i:=0 to 15 do times6502[i]:=0;
           filebuffer.setfile(sfh);
           sleep(200);
           songs:=0;

           siddelay:=8000;
           error:=SA_changeparams(48000,16,2,384);
 //          fi.box(0,0,600,600,15);
 //          fi.outtextxy(10,10,'type: MP2',178);
           pauseaudio(0);
           end

        else if (buf[0]=ord('R')) and (buf[1]=ord('I')) and (buf[2]=ord('F')) and (buf[3]=ord('F')) then
          begin
          pauseaudio(1);

          for i:=0 to 15 do times6502[i]:=0;

          waveopen(sfh);
          if head.pcm=85 then
            begin
            filebuffer.setmp3(1);
            filetype:=4;
            end
          else
            begin
            filebuffer.setmp3(0);
            filetype:=3;
            end;
          filebuffer.clear;
          filebuffer.setfile(sfh);
          sleep(200);
          songs:=0;

          if head.srate=44100 then siddelay:=8707 else siddelay:=2000;

          if head.srate=44100 then if a1base=432 then error:=SA_changeparams(43298,16,head.channels,384)
                                                 else error:=SA_changeparams(44100,16,head.channels,384);
          if head.srate=96000 then if a1base=432 then error:=SA_changeparams(94254,32,2,192)
                                                 else error:=SA_changeparams(96000,32,2,192);



          pauseaudio(0);

          end
        else
          begin
          for i:=0 to 15 do times6502[i]:=0;
          fileread(sfh,buf,21);
  //        fi.box(0,0,600,600,15);
  //
   //       fi.outtextxy(10,10,'type: unknown, 50 Hz SDMP assumed',178);

          if a1base=432 then error:=SA_changeparams(471270,16,2,1200)
                        else error:=SA_changeparams(480000,16,2,1200);

          songs:=0;
          end;

        songname:=s;
        songtime:=0;
        timer1:=-1;
        if filetype<>2 then begin pause1a:=false; pauseaudio(0); end;

        end;      }
    p997:

  //  end;

  until {(mousek=3) or }(key=key_escape) ;
  pauseaudio(1);
  if sfh>0 then fileclose(sfh);
  setcurrentdir(workdir);
  stopmachine;
  systemrestart(0);

end.

