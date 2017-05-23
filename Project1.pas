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
  Ultibo,
  retrokeyboard,    {Keyboard uses USB so that will be included automatically}
  retromouse,
  DWCOTG,
  retromalina,
 // cwindows,
  Unit6502,
  screen,
  mp3,
//  syscalls,
  blitter,
 // retro,
  simpleaudio,scripttest,xmp, mwindows;


label p101, p102 ,p999, p998;


var s,currentdir,currentdir2:string;
    sr:tsearchrec;
    filenames:array[0..1000,0..1] of string;
    hh,mm,ss,l,i,j,ilf,ild:integer;
    sel:integer=0;
    selstart:integer=0;
    nsel:integer;
    buf:array[0..25] of  byte;
    longbuf:array[0..4095] of byte;
    fn:string;

    cia:integer;
    init:word;
    atitle,author,copyright:string[32];
    workdir:string;
    pause1a:boolean=true;
    drivetable:array['A'..'Z'] of boolean;
    c:char;
    f:textfile;
    drive:string;
    key:integer;
    wheel:integer;
    t,tt,ttt,tttt:int64;
    srate,samples,bits:integer;
    mousedebug:boolean=false;
        mp3buf:array[0..4096] of byte;

    wh,scope:Twindow;
    sel1:TFileselector;

//    mp3test:pointer;
//    mp3testi:cardinal absolute mp3test;
//
//   mp3buf:byte absolute $20000000;
//   outbuf:byte absolute $21000000;
//    mp3bufidx:integer=0;
//   outbufidx:integer=0;
//    info:mp3_info_t;
//    framesize:integer;

// ---- procedures

procedure waveopen (var fh:integer);

label p999;

var
    i,k:integer;
    s:string;
    head_datasize:int64;
    samplenum:int64;
    currentdatasize:int64;

begin
fileseek(fh,0,0);
fileread(fh,head,44);
if head.data<>1635017060 then
  begin  //non-standard header
  i:=0;
  repeat fileseek(fh,i,fsfrombeginning); fileread(fh,k,4); i+=1 until (k=1635017060) or (i>512);
  if k=1635017060 then
    begin
    head.data:=k;
    fileread(fh,k,4);
    head.datasize:=k;
    end
  else
    begin
    goto p999;
    end;
  end;

// visualize wave data

fi.box(0,0,600,600,15);

fi.outtextxy(10,10,  'type:             RIFF',178);



fi.outtextxy (10,30 ,   'size:             '+inttostr(head.size),178);
fi.outtextxy (10,50 ,   'pcm type:         '+inttostr(head.pcm),178);
fi.outtextxy (10,70 ,   'channels:         '+inttostr(head.channels),178);
fi.outtextxy (10,90 ,   'sample rate:      '+inttostr(head.srate),178);
fi.outtextxy (10,110,   'bitrate:          '+inttostr(head.brate),178);
fi.outtextxy (10,130,   'bytes per sample: '+inttostr(head.bytesps),178);
fi.outtextxy (10,150,   'bits per sample:  '+inttostr(head.bps),178);
fi.outtextxy (10,170,   'data size:        '+inttostr(head.datasize),178);

if head.pcm=85 then goto p999;

head_datasize:=head.datasize ;
currentdatasize:=head.datasize;

// determine the number of samples

samplenum:=currentdatasize div (head.channels*head.bps div 8);
fi.outtextxy (10,190,   'samples:          '+inttostr(samplenum),178);

p999:
end;

procedure mp3open (var fh:integer);

label p999;

var
    il2:integer;
    skip:integer;


begin
fileseek(fh,0,fsfrombeginning);
fileread(fh,mp3buf,10);
if (mp3buf[0]=ord('I')) and (mp3buf[1]=ord('D')) and (mp3buf[2]=ord('3')) then // Skip ID3
  begin
  skip:=(mp3buf[6] shl 21) + (mp3buf[7] shl 14) + (mp3buf[8] shl 7) + mp3buf[9]+10;
  end
else skip:=0;
fileseek(fh,skip,fsfrombeginning);
if skip>0 then begin
  repeat skip+=1; mp3buf[1]:=mp3buf[0]; fileread(fh,mp3buf,1) until (mp3buf[0]=$FB) and (mp3buf[1]=$FF);
  fileseek(fh,skip-2,fsfrombeginning);
  end;

// visualize wave data

fi.box(0,0,600,600,15);
//outtextxyz(42,156,'type:              mp3',177,2,2);
fi.outtextxy (10,10 ,'type:           mp3',177);


//outtextxyz(42,228+24,'channels:         '+inttostr(head.channels),177,2,2);
//outtextxyz(42,260+24,'sample rate:      '+inttostr(head.srate),177,2,2);
//outtextxyz(42,292+24,'bitrate:          ',177,2,2);

fi.outtextxy (10,30 ,   'channels:     '+inttostr(head.channels),177);
fi.outtextxy (10,50 ,   'sample rate:  '+inttostr(head.srate),177);
//fi.outtextxy (10,70 ,   'bitrate:       ',177,2,2);


// determine the number of samples

//box(18,912,800,32,244);
//outtextxyz(18,912,'MP3 file, '+inttostr(head.srate)+' Hz',250,2,2);
end;

procedure sidopen (var fh:integer);

var i:integer;
    speed:cardinal;
    version,offset,load,startsong,flags:word;
    dump:word;
    il,b:byte;

begin
reset6502;
atitle:='                                ';
author:='                                ';
copyright:='                                ';
fileread(fh,version,2); version:=(version shl 8) or (version shr 8);
fileread(fh,offset,2); offset:=(offset shl 8) or (offset shr 8);
fileread(fh,load,2); load:=(load shl 8) or (load shr 8);
fileread(fh,init,2); init:=(init shl 8) or (init shr 8);
fileread(fh,play,2);  play:=(play shl 8) or (play shr 8);
fileread(fh,songs,2); songs:=(songs shl 8) or (songs shr 8);
fileread(fh,startsong,2); startsong:=(startsong shl 8) or (startsong shr 8);
fileread(fh,speed,4);
speed:=speed shr 24+((speed shr 8) and $0000FF00) + ((speed shl 8) and $00FF0000) + (speed shl 24);
fileread(fh,atitle[1],32);
fileread(fh,author[1],32);
fileread(fh,copyright[1],32);
if version>1 then begin
  fileread(fh,flags,2); flags:=(flags shl 8) or (flags shr 8);
  fileread(fh,dump,2);
  fileread(fh,dump,2);
  b:=0; if load=0 then begin b:=1; fileread(fh,load,2); end;
  end;
for i:=1 to 32 do if byte(atitle[i])=$F1 then atitle[i]:=char(26);
for i:=1 to 32 do if byte(author[i])=$F1 then author[i]:=char(26);
fi.box(0,0,600,600,15);
//fi.outtextxy(42,156,'type: PSID',177,2,2);
fi.outtextxy (10,10,'type:      PSID',178);

//outtextxyz(42,164+24,'version: '+inttostr(version),177,2,2);
//outtextxyz(42,196+24,'offset: ' +inttohex(offset,4),177,2,2);
//outtextxyz(42,228+24,'load: '+inttohex(load,4),177-144*b,2,2);
//outtextxyz(42,260+24,'init: '+inttohex(init,4),177,2,2);
//outtextxyz(42,292+24,'play: '+inttohex(play,4),177,2,2);
//outtextxyz(42,324+24,'songs: '+inttostr(songs),177,2,2);
//outtextxyz(42,356+24,'startsong: '+inttostr(startsong),177,2,2);
//outtextxyz(42,388+24,'speed: '+inttohex(speed,8),177,2,2);
//outtextxyz(42,420+24,'title: '+atitle,177,2,2);
//outtextxyz(42,452+24,'author: '+author,177,2,2);
//outtextxyz(42,484+24,'copyright: '+copyright,177,2,2);
//outtextxyz(42,516+24,'flags: '+inttohex(flags,4),177,2,2);

fi.outtextxy (10,30 ,'version:   '+inttostr(version),178);
fi.outtextxy (10,50 ,'offset:    '+inttohex(offset,4),178);
fi.outtextxy (10,70 ,'load:      '+inttohex(load,4),178-144*b);
fi.outtextxy (10,90 ,'init:      '+inttohex(init,4),178);
fi.outtextxy (10,110,'play:      '+inttohex(play,4),178);
fi.outtextxy (10,130,'songs:     '+inttostr(songs),178);
fi.outtextxy (10,150,'startsong: '+inttostr(startsong),178);
fi.outtextxy (10,170,'speed:     '+inttohex(speed,8),178);
fi.outtextxy (10,190,'title:     '+atitle,178);
fi.outtextxy (10,210,'author:    '+author,178);
fi.outtextxy (10,230,'copyright: '+copyright,178);
fi.outtextxy (10,250,'flags:     '+inttohex(flags,4),178);
song:=startsong-1;

//reset6502;
for i:=0 to 65535 do write6502(i,0);
repeat
  il:=fileread(fh,b,1);
  write6502(load,b);
  load+=1;
until il<>1;
fileseek(fh,0,fsfrombeginning);
CleanDataCacheRange(base,65536);
i:=lpeek(base+$60000);
repeat until lpeek(base+$60000)>(i+4);
jsr6502(song,init);
cia:=read6502($dc04)+256*read6502($dc05);
//outtextxyz(42,548+24,'cia: '+inttohex(read6502($dc04)+256*read6502($dc05),4),177,2,2);
fi.outtextxy (10,270,'cia:       '+inttohex(read6502($dc04)+256*read6502($dc05),4),178);
end;


procedure sort;

// A simple bubble sort for filenames

var i,j:integer;
    s,s2:string;

begin
repeat
  j:=0;
  for i:=0 to ilf-2 do
    begin
    if (copy(filenames[i,0],3,1)<>'\') and (lowercase(filenames[i,1]+filenames[i,0])>lowercase(filenames[i+1,1]+filenames[i+1,0])) then
      begin
      s:=filenames[i,0]; s2:=filenames[i,1];
      filenames[i,0]:=filenames[i+1,0];
      filenames[i,1]:=filenames[i+1,1];
      filenames[i+1,0]:=s; filenames[i+1,1]:=s2;
      j:=1;
      end;
    end;
until j=0;
end;


procedure dirlist(dir:string);

var c:char;
    i:integer;
    dd:boolean;

begin
for c:='C' to 'F' do drivetable[c]:=directoryexists(c+':\');
currentdir2:=dir;
setcurrentdir(currentdir2);
currentdir2:=getcurrentdir;
if copy(currentdir2,length(currentdir2),1)<>'\' then currentdir2:=currentdir2+'\';
box2(897,67,1782,115,36);
box2(897,118,1782,1008,34);
s:=currentdir2;
if length(s)>55 then s:=copy(s,1,55);
l:=length(s);
outtextxyz(1344-8*l,75,s,44,2,2);
ilf:=0;
if length(currentdir2)=3 then
for c:='A' to 'Z' do
  begin
  if drivetable[c] then
    begin
    filenames[ilf,0]:=c+':\';
    filenames[ilf,1]:='(DIR)';
    ilf+=1;
    end;
  end;

currentdir:=currentdir2+'*';
if findfirst(currentdir,fadirectory,sr)=0 then
  repeat
  if (sr.attr and faDirectory) = faDirectory then
    begin
    filenames[ilf,0]:=sr.name;
    filenames[ilf,1]:='(DIR)';
    ilf+=1;
    end;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

// ntfs no .. patch

dd:=false;
for i:=0 to ilf do if filenames[i,0]='..' then dd:=true;
if (not dd) and (length(currentdir2)>3) then
  begin
  filenames[ilf,0]:='..';
  filenames[ilf,1]:='(DIR)';
  ilf+=1;
  end;
//box(100,100,100,100,0); if dd then outtextxy(100,100,'true',40) else outtextxy(100,100,'false',40);


currentdir:=currentdir2+'*.sid';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='sid';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.dmp';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='dmp';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.wav';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='wav';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.mp3';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='mp3';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.mp2';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='mp2';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.s48';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='s48';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.mod';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='mod';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.xm';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='xm';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.s3m';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='s3m';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

currentdir:=currentdir2+'*.it';
if findfirst(currentdir,faAnyFile,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='it';
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

sort;

box(920,132,840,32,36);
if ilf<26 then ild:=ilf-1 else ild:=26;
for i:=0 to ild do
  begin
  if filenames[i,1]<>'(DIR)' then l:=length(filenames[i,0])-4 else  l:=length(filenames[i,0]);
  if filenames[i,1]<>'(DIR)' then  s:=copy(filenames[i,0],1,length(filenames[i,0])-4) else s:=filenames[i,0];
  if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
  for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
  if filenames[i,1]<>'(DIR)' then outtextxyz(1344-8*l,132+32*i,s,44,2,2);
  if filenames[i,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*i,s,44,2,2);  outtextxyz(1672,132+32*i,'(DIR)',44,2,2);   end;
  end;
sel:=0; selstart:=0;
box2(897,67,1782,115,36);
s:=currentdir2;
if length(s)>55 then s:=copy(s,1,55);
l:=length(s);
outtextxyz(1344-8*l,75,s,44,2,2);
end;

procedure initframebuffer;

begin
fb:=FramebufferDevicegetdefault;
FramebufferDeviceRelease(fb);
Sleep(100);
FramebufferProperties.Depth:=32;
FramebufferProperties.PhysicalWidth:=1920;
FramebufferProperties.PhysicalHeight:=1200;
FramebufferProperties.VirtualWidth:=FramebufferProperties.PhysicalWidth;
FramebufferProperties.VirtualHeight:=FramebufferProperties.PhysicalHeight * 2;
FramebufferDeviceAllocate(fb,@FramebufferProperties);
sleep(100);
FramebufferDeviceGetProperties(fb,@FramebufferProperties);
p2:=Pointer(FramebufferProperties.Address);

end;

//------------------- The main program

begin

//background_init(147);
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

for c:='C' to 'F' do drivetable[c]:=directoryexists(c+':\');




//workdir:='C:\';
//dirlist('C:\');
songtime:=0;
siddelay:=20000;
setcurrentdir(workdir);
ThreadSetCPU(ThreadGetCurrent,CPU_ID_0);
threadsleep(1);
startreportbuffer;
startmousereportbuffer;
sel1 :=Tfileselector.create('C:\');
sel1.move(100,100,400,600,-1,-1);

//------------------- The main loop

repeat

  refreshscreen;
  key:=readkey and $FF;
  wh:=panel.checkmouse;
  wh:=background.checkmouse;
//  if wh<>@background  then goto p998;
//   box(600,100,200,500,0);
//   outtextxy(600,100,'mousedoubleclick '+inttostr(mousedblclick),15);
//   outtextxy(600,116,'oscilloscope y '+inttostr(sc.y),15);
//   outtextxy(600,132,'oscilloscope wl '+inttostr(sc.wl),15);
//   outtextxy(600,148,'oscilloscope wh '+inttostr(sc.wh),15);
//   outtextxy(600,164,'oscilloscope vx '+inttostr(sc.vx),15);
//   outtextxy(600,180,'oscilloscope vy '+inttostr(sc.vy),15);
//   outtextxy(600,196,'oscilloscope l '+inttostr(sc.l),15);
//   outtextxy(600,212,'oscilloscope h '+inttostr(sc.h),15);

//  if (key=0) and (nextsong=2) then begin nextsong:=0; key:=key_enter; end;      // play the next song
//  if (key=0) and (nextsong=1) then begin nextsong:=2; key:=key_downarrow; end;  // select the nest song


//  if wh=background then

//    begin
//    wheel:=readwheel;

//    if (key=0) and (wheel=-1) then begin key:=key_downarrow;  end;
//    if (key=0) and (wheel=1) then begin key:=key_uparrow;  end;
//
//
 //   if (dblclick) and (key=0) and (mousex>896) and (wh=background) then begin key:=key_enter; end;    // dbl click on right panel=enter

//    if (click) and (mousex>896) and (wh=background) then
//      begin
//
//      nsel:=(mousey-132) div 32;
//      if (nsel<=ild) and (nsel>=0) then
//        begin
//        box(920,132+32*sel,840,32,34);
//        if filenames[sel+selstart,1]<>'(DIR)' then l:=length(filenames[sel+selstart,0])-4 else  l:=length(filenames[sel+selstart,0]);
//        if filenames[sel+selstart,1]<>'(DIR)' then  s:=copy(filenames[sel+selstart,0],1,length(filenames[sel+selstart,0])-4) else s:=filenames[sel+selstart,0];
//        if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
//        for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
//        if filenames[sel+selstart,1]<>'(DIR)'then outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);
//        if filenames[sel+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);  outtextxyz(1672,132+32*(sel),'(DIR)',44,2,2);   end;
//        sel:=nsel;
//        box(920,132+32*sel,840,32,36);
//        if filenames[sel+selstart,1]<>'(DIR)' then l:=length(filenames[sel+selstart,0])-4 else  l:=length(filenames[sel+selstart,0]);
//        if filenames[sel+selstart,1]<>'(DIR)' then  s:=copy(filenames[sel+selstart,0],1,length(filenames[sel+selstart,0])-4) else s:=filenames[sel+selstart,0];
//        if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
//        for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
//        if filenames[sel+selstart,1]<>'(DIR)' then outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);
//        if filenames[sel+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);  outtextxyz(1672,132+32*(sel),'(DIR)',44,2,2);   end;
//        end;
//      end;
//    end;
  p998:
  if key=ord('5') then begin siddelay:=20000; songfreq:=50; skip:=0; end
  else if key=ord('1') then begin siddelay:=10000; songfreq:=100; skip:=0; end
  else if key=ord('2') then begin siddelay:=5000; songfreq:=200; skip:=0;end
  else if key=ord('3') then begin siddelay:=6666; songfreq:=150; skip:=0; end
  else if key=ord('4') then begin siddelay:=2500; songfreq:=400; skip:=0; end
  else if key=ord('p') then begin pause1a:=not pause1a; if pause1a then pauseaudio(1) else pauseaudio(0); end
  else if key=key_f1 then begin if channel1on=0 then channel1on:=1 else channel1on:=0; end   // F1 toggle channel 1 on/off
  else if key=key_f2 then begin if channel2on=0 then channel2on:=1 else channel2on:=0; end   // F2 toggle channel 1 on/off
  else if key=key_f3 then begin if channel3on=0 then channel3on:=1 else channel3on:=0; end   // F3 toggle channel 1 on/off


  else if key=ord('b') then   // blitter test
    begin
pauseaudio(0);
sleep(10);
pauseaudio(1);

    end

  else if key=ord('s') then   // blitter test
    begin
    lpoke ($2E000000,1);
    lpoke ($2E000004,0);

//    asm
//    mov r1,#0x2E000000;
//    vld2.8 {d0,d1},[r1]
//    vadd.i64 d1,d2
//    vstr d1,[r1]
//    end;
//    box(100,100,100,100,0);
//    outtextxy(100,100,inttostr(lpeek($2E000000)),40);


    //script1;
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
 {
  else if key=key_downarrow then
    begin
    if sel<ild then
      begin
      box(920,132+32*sel,840,32,34);
      if filenames[sel+selstart,1]<>'(DIR)' then l:=length(filenames[sel+selstart,0])-4 else  l:=length(filenames[sel+selstart,0]);
      if filenames[sel+selstart,1]<>'(DIR)' then  s:=copy(filenames[sel+selstart,0],1,length(filenames[sel+selstart,0])-4) else s:=filenames[sel+selstart,0];
      if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
      for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
      if filenames[sel+selstart,1]<>'(DIR)'then outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);
      if filenames[sel+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);  outtextxyz(1672,132+32*(sel),'(DIR)',44,2,2);   end;
      sel+=1;
      box(920,132+32*sel,840,32,36);
      if filenames[sel+selstart,1]<>'(DIR)' then l:=length(filenames[sel+selstart,0])-4 else  l:=length(filenames[sel+selstart,0]);
      if filenames[sel+selstart,1]<>'(DIR)' then  s:=copy(filenames[sel+selstart,0],1,length(filenames[sel+selstart,0])-4) else s:=filenames[sel+selstart,0];
      if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
      for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
      if filenames[sel+selstart,1]<>'(DIR)' then outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);
      if filenames[sel+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);  outtextxyz(1672,132+32*(sel),'(DIR)',44,2,2);   end;

      end
    else if sel+selstart<ilf-1 then
      begin
      selstart+=1;
      box2(897,118,1782,1008,34);
      box(920,132+32*sel,840,32,36);
      for i:=0 to ild do
        begin
        if filenames[i+selstart,1]<>'(DIR)' then l:=length(filenames[i+selstart,0])-4 else  l:=length(filenames[i+selstart,0]);
        if filenames[i+selstart,1]<>'(DIR)'then  s:=copy(filenames[i+selstart,0],1,length(filenames[i+selstart,0])-4) else s:=filenames[i+selstart,0];
        if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
        for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
        if filenames[i+selstart,1]<>'(DIR)'then outtextxyz(1344-8*l,132+32*i,s,44,2,2);
        if filenames[i+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*i,s,44,2,2);  outtextxyz(1672,132+32*i,'(DIR)',44,2,2);   end;
        end;
      end;
    end

  else if key=key_uparrow then
     begin
      if sel>0 then
        begin
        box(920,132+32*sel,840,32,34);
        if filenames[sel+selstart,1]<>'(DIR)' then l:=length(filenames[sel+selstart,0])-4 else  l:=length(filenames[sel+selstart,0]);
        if filenames[sel+selstart,1]<>'(DIR)' then  s:=copy(filenames[sel+selstart,0],1,length(filenames[sel+selstart,0])-4) else s:=filenames[sel+selstart,0];
        if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
        for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
        if filenames[sel+selstart,1]<>'(DIR)' then outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);
        if filenames[sel+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);  outtextxyz(1672,132+32*(sel),'(DIR)',44,2,2);   end;
        sel-=1;
        box(920,132+32*sel,840,32,36);
        if filenames[sel+selstart,1]<>'(DIR)'then l:=length(filenames[sel+selstart,0])-4 else  l:=length(filenames[sel+selstart,0]);
        if filenames[sel+selstart,1]<>'(DIR)'then  s:=copy(filenames[sel+selstart,0],1,length(filenames[sel+selstart,0])-4) else s:=filenames[sel+selstart,0];
        if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
        for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
        if filenames[sel+selstart,1]<>'(DIR)' then outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);
        if filenames[sel+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*(sel),s,44,2,2);  outtextxyz(1672,132+32*(sel),'(DIR)',44,2,2);   end;
        end
      else if sel+selstart>0 then
        begin
        selstart-=1;
        box2(897,118,1782,1008,34);
        box(920,132+32*sel,840,32,36);
        for i:=0 to ild do
          begin
          if filenames[i+selstart,1]<>'(DIR)' then l:=length(filenames[i+selstart,0])-4 else  l:=length(filenames[i+selstart,0]);
          if filenames[i+selstart,1]<>'(DIR)' then s:=copy(filenames[i+selstart,0],1,length(filenames[i+selstart,0])-4) else s:=filenames[i+selstart,0];
          if length(s)>40 then begin s:=copy(s,1,40); l:=40; end;
          for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
          if filenames[i+selstart,1]<>'(DIR)' then outtextxyz(1344-8*l,132+32*i,s,44,2,2);
          if filenames[i+selstart,1]='(DIR)' then begin outtextxyz(1344-8*l,132+32*i,s,44,2,2);  outtextxyz(1672,132+32*i,'(DIR)',44,2,2);   end;
          end;
        end;
      end
  }
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

     else if key=ord('w') then   // set 440 Hz
       begin
  //     sel1 :=Tfileselector.create('C:\');
       //wh.title:='';//'Test window '+inttohex(integer(wh),8);
       //wh.cls(16*random(16)+2);
       //wh.outtextxy(10,10,'Window handle: '+inttostr(integer(wh)),136);
       //wh.outtextxy(10,42,'Moving window test line 1',152);
       //wh.box(100,100,100,100,40);
 //      wh.outtextxy(10,74,'Moving window test line 2',168);
 //      wh.outtextxy(10,106,'Moving window test line 3',184);
 //      wh.outtextxy(10,138,'Moving window test line 4',200);
 //      wh.outtextxy(10,170,'Moving window test line 5',216);

//       box(100,100,200,600,0);
//       outtextxy(100,100,inttostr(integer(wh)),15);
//       outtextxy(100,132,inttostr(integer(wh.gdata)),15);

//       wh.outtextxy(10,202,'Moving window test line 6',232);
//       wh.outtextxy(10,234,'Moving window test line 7',248);
//       wh.outtextxy(10,266,'Moving window test line 8',8);
//       wh.outtextxy(10,298,'Moving window test line 9',24);
//       wh.outtextxy(10,330,'Moving window test line 10',40);
//       wh.outtextxy(10,363,'Moving window test line 11',56);
//       wh.outtextxy(10,394,'Moving window test line 12',72);
//       wh.outtextxy(10,426,'Moving window test line 13',88);
//       wh.outtextxy(10,458,'Moving window test line 14',104);
//       wh.outtextxy(10,490,'Moving window test line 15',120);
   //    sel1.move(100,100,400,600,-1,-1);
//       for i:=10 to 800 do begin movewindow(wh,100,100,i,i,0,0); waitvbl; end;
//       for i:=1 to 300 do begin movewindow(wh,100,100,800-i,800-i,0,0); waitvbl; end;
//       for i:=1 to 300 do begin movewindow(wh,100+i,100+i,500,500,0,0); waitvbl; end;
//       for i:=0 to 100 do begin movewindow(wh,400,400,500,500,i,i); waitvbl; end;
//       sleep(1000);
//       destroywindow(wh);
       end

    else if sel1.filename<>'' then //  key=key_enter then
      begin
      av6502:=0;
//      if filenames[sel+selstart,1]='(DIR)' then
//        begin
//        if copy(filenames[sel+selstart,0],2,1)<>':' then dirlist(currentdir2+filenames[sel+selstart,0]+'\')
//        else begin currentdir2:=filenames[sel+selstart,0] ; dirlist(currentdir2); end;
//       end

//      else

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

        fn:= sel1.filename; // currentdir2+filenames[sel+selstart,0];
        sel1.filename:='';
        sfh:=fileopen(fn,$40);
        s:=copy(fn,1,length(fn)-4);
        for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
        siddelay:=20000;
        filetype:=0;
        fileread(sfh,buf,4);
        if (buf[0]=ord('S')) and (buf[1]=ord('D')) and (buf[2]=ord('M')) and (buf[3]=ord('P')) then
          begin
          for i:=0 to 15 do times6502[i]:=0;
          fi.box(0,0,600,600,15);
          fi.outtextxy(10,10,'type: SDMP',178);
          songs:=0;
          fileread(sfh,buf,4);
          siddelay:=1000000 div buf[0];
          fi.outtextxy(10,30,'speed: '+inttostr(buf[0])+' Hz',178);
          atitle:='                                ';
          fileread(sfh,atitle[1],16);
          fileread(sfh,buf,1);
          fi.outtextxy (10,50,'title: '+atitle,178);
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
      //    box(18,912,800,32,244);
       //   outtextxyz(18,912,'PSID file, '+inttostr(1000000 div siddelay)+' Hz',250,2,2);
          if a1base=432 then error:=SA_changeparams(10*47127,16,2,10*120)
                        else error:=SA_changeparams(10*48000,16,2,10*120);
          fileclose(sfh);
          end
       else if (buf[0]=ord('R')) and (buf[1]=ord('S')) and (buf[2]=ord('I')) and (buf[3]=ord('D')) then
          begin
          filetype:=2;

          fi.box(0,0,600,600,15);
          fi.outtextxy(10,10,'type: RSID, not yet supported',44);
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
          //if head.srate=44100 then
          siddelay:=8707 ;//else siddelay:=2000;
        //  if head.srate=44100 then if a1base=432 then error:=SA_changeparams(43298,16,2,384)
       //                                          else error:=SA_changeparams(44100,16,2,384);
       //   if head.srate=96000 then if a1base=432 then error:=SA_changeparams(94254,32,2,192)
       //                                          else error:=SA_changeparams(96000,32,2,192);

          if sprite6x>2047 then begin sprite0x:=100; sprite1x:=200; sprite2x:=300;sprite3x:=400; sprite4x:=500; sprite5x:=600; sprite6x:=700; end;
 //                   box(18,132,800,600,178);
  //        outtextxyz(18,132,'type: MP3',188,2,2);
          pauseaudio(0);
          end

         else if copy(fn,length(fn)-2,3)='mp2' then
          begin
          fileseek(sfh,0,fsfrombeginning);
       //   filebuffer.clear;

          filetype:=5;
          filebuffer.setmp3(2);
          sleep(50);
          for i:=0 to 15 do times6502[i]:=0;
          filebuffer.setfile(sfh);
          sleep(200);
          songs:=0;
          //if head.srate=44100 then
          siddelay:=8707 ;//else siddelay:=2000;
                   if a1base=432 then error:=SA_changeparams(43298,16,2,384)
                       else error:=SA_changeparams(44100,16,2,384);
        //  if head.srate=44100 then if a1base=432 then error:=SA_changeparams(43298,16,2,384)
       //                                          else error:=SA_changeparams(44100,16,2,384);
       //   if head.srate=96000 then if a1base=432 then error:=SA_changeparams(94254,32,2,192)
       //                                          else error:=SA_changeparams(96000,32,2,192);

          if sprite6x>2047 then begin sprite0x:=100; sprite1x:=200; sprite2x:=300;sprite3x:=400; sprite4x:=500; sprite5x:=600; sprite6x:=700; end;
          fi.box(0,0,600,600,15);
          fi.outtextxy(10,10,'type: MP2',178);
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

     //     box(0,0,500,100,0);
          xmp_context:=xmp_create_context;
 //        outtextxyz(0,0,inttostr(integer(xmp_context)),40,2,2);
          if a1base=432 then error:=SA_changeparams(48258,16,2,384)
                        else error:=SA_changeparams(49152,16,2,384);
          siddelay:=7812;
          filetype:=6;


          i:=xmp_load_module(xmp_context,Pchar(fn));
 //                   outtextxyz(0,32,inttostr(i),40,2,2);
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
 //               outtextxyz(0,64,inttostr(i),40,2,2);

 //               xmp_set_player(xmp_context,xmp_player_volume,90);
          if i<>0 then
            begin
                       xmp_release_module(xmp_context);
            xmp_free_context(xmp_context);
            goto p102;
            end;
          sleep(50);
          for i:=0 to 15 do times6502[i]:=0;
          if sprite6x>2047 then begin sprite0x:=100; sprite1x:=200; sprite2x:=300;sprite3x:=400; sprite4x:=500; sprite5x:=600; sprite6x:=700; end;
          fi.box(0,0,600,600,15);
          fi.outtextxy(10,10,'type: MOD',178);
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
           //if head.srate=44100 then
           siddelay:=8000;//else siddelay:=2000;
           error:=SA_changeparams(48000,16,2,384);
         //  if head.srate=44100 then if a1base=432 then error:=SA_changeparams(43298,16,2,384)
        //                                          else error:=SA_changeparams(44100,16,2,384);
        //   if head.srate=96000 then if a1base=432 then error:=SA_changeparams(94254,32,2,192)
        //                                          else error:=SA_changeparams(96000,32,2,192);

           if sprite6x>2047 then begin sprite0x:=100; sprite1x:=200; sprite2x:=300;sprite3x:=400; sprite4x:=500; sprite5x:=600; sprite6x:=700; end;
           fi.box(0,0,600,600,15);
           fi.outtextxy(10,10,'type: MP2',178);
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

    //      if (head.pcm=1) or (head.pcm=85) then bits:=16 else bits:=32;
    //      srate:=round(head.srate*(a1base/440));
    //      if head.pcm=3 then samples:=96*head.channels else samples:=192*head.channels;
    //      error:=SA_changeparams(srate,bits,2, {head.channels,}samples);
          if head.srate=44100 then if a1base=432 then error:=SA_changeparams(43298,16,head.channels,384)
                                                 else error:=SA_changeparams(44100,16,head.channels,384);
          if head.srate=96000 then if a1base=432 then error:=SA_changeparams(94254,32,2,192)
                                                 else error:=SA_changeparams(96000,32,2,192);

          if sprite6x>2047 then begin sprite0x:=100; sprite1x:=200; sprite2x:=300;sprite3x:=400; sprite4x:=500; sprite5x:=600; sprite6x:=700; end;

          pauseaudio(0);

          end
        else
          begin
          for i:=0 to 15 do times6502[i]:=0;
          fileread(sfh,buf,21);
          fi.box(0,0,600,600,15);

          fi.outtextxy(10,10,'type: unknown, 50 Hz SDMP assumed',178);

          if a1base=432 then error:=SA_changeparams(471270,16,2,1200)
                        else error:=SA_changeparams(480000,16,2,1200);

          songs:=0;
          end;

        songname:=s;
        songtime:=0;
        timer1:=-1;
        if filetype<>2 then begin pause1a:=false; pauseaudio(0); end;

        end;
    end;

  until (mousek=3) or (key=key_escape) ;
  pauseaudio(1);
  if sfh>0 then fileclose(sfh);
  setcurrentdir(workdir);
  stopmachine;
  systemrestart(0);

end.

