unit playerunit;

{$mode objfpc}{$H+}

interface

//------------------------------------------------------------------------------
// A Winamp skinnable player for the Colors GUI/RPi
// v. 0.26 alpha - 20170619
// work in progress
// GPL 2.0
// pik33@o2.pl
//------------------------------------------------------------------------------

uses
  Classes, SysUtils, platform, retromalina, mwindows, blitter, threads, simpleaudio, retro, icons, retrokeyboard, unit6502,xmp,mp3;


type TPlayerThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

     TOscilloscope= class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create;
     end;

     TVisualization= class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create;
     end;

     TSettings= class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create;
     end;

     TPlaylistThread= class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create;
     end;

     TCountThread= class(TThread)
     private
     protected
       procedure Execute; override;
     public
       Constructor Create;
     end;

     TPlaylistItem=class(TObject)
     item:string;
     name:string;
     time:integer;
     rep:integer;
     x,y:integer;
     selected:boolean;
     granny:TWindow;
     next,prev:TPlaylistItem;
     constructor create(aitem:string);
     procedure append(aitem:string);
     procedure remove;
     function checkall:boolean;
     procedure draw;
     procedure select;
     end;


          // File buffer thread

    TFileBuffer= class(TThread)
    private
      buf:array[0..131071] of byte;
      tempbuf:array[0..32767] of byte;
      outbuf: array[0..8191] of byte;
    pocz:integer;
    koniec:integer;
    il,fh,newfh:integer;
    newfilename:string;
    needclear:boolean;
    seekamount:int64;
    eof:boolean;
    mp3:integer;
    qq:integer;
    maintenance:boolean;
    reading:boolean;
    protected
      procedure Execute; override;
    public
     m:integer;
     empty,full:boolean;
     Constructor Create(CreateSuspended : boolean);
     function getdata(b,ii:integer):integer;
     procedure setfile(nfh:integer);
     procedure clear;
     procedure seek(amount:int64);
     procedure setmp3(mp3b:integer);
    end;




const

// CPU Affinity constants copied here

      CPU_AFFINITY_0  = 1;
      CPU_AFFINITY_1  = 2;
      CPU_AFFINITY_2  = 4;
      CPU_AFFINITY_3  = 8;
      ver='RetAMP v. 0.28 (2017.06.27)';

var pl:TWindow=nil;
    info:TWindow=nil;
    sc:TWindow=nil;
    vis:TWindow=nil;
    fi:TWindow=nil;
    list:TWindow=nil;
    sett:TWindow=nil;
    spritebutton:TButton;
    oscilloscopebutton:TButton;

    visarea:pointer=nil;
    cbuttons:pointer=nil;
    titlebar:pointer=nil;
    baseskin:pointer=nil;
    numbers:pointer=nil;
    volume:pointer=nil;
    balance:pointer=nil;
    posbar:pointer=nil;
    shufrep:pointer=nil;
    monoster:pointer=nil;
    playpaus:pointer=nil;
    eqmain:pointer=nil;
    pledit:pointer=nil;

    playerthread:TPlayerthread=nil;
    oscilloscope:TOscilloscope=nil;
    visualization:TVisualization=nil;
    playlistthread:Tplaylistthread=nil;
    settings:TSettings=nil;

    sel1:TFileselector=nil;
    playfilename,pf2:string;
    dir:string;

    fileinfo:array[0..31,0..1] of string;

    spr0x,spr0y,spr0dx,spr0dy:integer;
    spr1x,spr1y,spr1dx,spr1dy:integer;
    spr2x,spr2y,spr2dx,spr2dy:integer;
    spr3x,spr3y,spr3dx,spr3dy:integer;
    spr4x,spr4y,spr4dx,spr4dy:integer;
    spr5x,spr5y,spr5dx,spr5dy:integer;
    spr6x,spr6y,spr6dx,spr6dy:integer;
    spr0,spr1,spr2,spr3,spr4,spr5,spr6:TAnimatedSprite;
    pause1a:boolean=true;
    song:word=0;
    songs:word=0;
    init:word;
    mp3buf:array[0..4096] of byte;
    atitle,author,copyright:string[32];
    cia:integer;
    a1base:integer=440;
    ext:string;
    av6502:int64=0;
    s, fn:string;
    buf:array[0..25] of  byte;
    songname:string;
    key:integer;

    playlistitem:TPlaylistitem=nil;
    infofh:integer;
    filebuffer:TFileBuffer=nil;
    player_item:TPlaylistitem;

    desired, obtained:TAudioSpec;
    skintextcolor:integer=200;
    skinbackcolor:integer=0;
    maintextcolor:integer=200;
    mainbackcolor:integer=0;
    countfilename:string;
        skindir:string;
        sdir:string;
        sliders:boolean=true;
   volume_pos,balance_pos:integer;

procedure hide_sprites;
procedure start_sprites;
procedure vis_sprites;
procedure prepare_sprites;
procedure AudioCallback(userdata: Pointer; stream: PUInt8; len:Integer );

implementation


function mp3check(name:string):integer;

label p999;

var i,il,j,infofh,q,bitrate, freq, samplerate, padding,channels,fs,err:integer;
    mp3buf:array[0..32767] of byte;
    bitrates:array[0..15] of integer=(0,32,40,48,56,64,80,96,112,128,160,192,224,256,320,0);
    bitrates2:array[0..15] of integer=(0,8,16,24,32,40,48,56,64,80,96,112,128,144,160,0);
    bitrates22:array[0..15] of integer=(0,32,48,56,64,80,96,112,128,160,192,224,256,320,384,0);
    freqs:array[0..3] of integer=(44100,48000,32000,0);
    freqs2:array[0..3] of integer=(22050,24000,16000,0);
    crc,lll,layer:integer;
    skip,len: int64;
    t:int64;

begin
t:=gettime;
infofh:=fileopen(name,$40);
fileread(infofh,mp3buf,10);
if (mp3buf[0]=ord('I')) and (mp3buf[1]=ord('D')) and (mp3buf[2]=ord('3')) then // Skip ID3
  begin
  skip:=(mp3buf[6] shl 21) + (mp3buf[7] shl 14) + (mp3buf[8] shl 7) + mp3buf[9]+10;
  end
else skip:=0;
fileseek(infofh,skip,fsfrombeginning);

begin
  repeat skip+=1; mp3buf[1]:=mp3buf[0]; il:=fileread(infofh,mp3buf,1) until
    (il=0) or
      ((mp3buf[0]=$FB) and (mp3buf[1]=$FF)) or
        ((mp3buf[0]=$F3) and (mp3buf[1]=$FF)) or
          ((mp3buf[0]=$FA) and (mp3buf[1]=$FF)) or
            ((mp3buf[0]=$F2) and (mp3buf[1]=$FF)) or
             ((mp3buf[0]=$FC) and (mp3buf[1]=$FF)) or
                ((mp3buf[0]=$FD) and (mp3buf[1]=$FF));
  fileseek(infofh,skip-2,fsfrombeginning);
  end;

err:=0;
i:=0;
repeat
  q:=0;
  i:=i+1;
  il:= fileread(infofh,mp3buf,1); mp3buf[1]:=mp3buf[0]; il:= fileread(infofh,mp3buf,1);

  if (mp3buf[1]<>$FF) or ((mp3buf[0]<>$FB) and (mp3buf[0]<>$FA) and (mp3buf[0]<>$F3) and (mp3buf[0]<>$F2) and (mp3buf[0]<>$FC) and (mp3buf[0]<>$FD)) then
    begin
    err+=1;
    repeat mp3buf[1]:=mp3buf[0]; il:=fileread(infofh,mp3buf,1); q+=1; until
      (il=0) or
        ((mp3buf[0]=$FB) and (mp3buf[1]=$FF)) or
          ((mp3buf[0]=$F3) and (mp3buf[1]=$FF)) or
            ((mp3buf[0]=$FA) and (mp3buf[1]=$FF)) or
              ((mp3buf[0]=$F2) and (mp3buf[1]=$FF)) or
                ((mp3buf[0]=$FC) and (mp3buf[1]=$FF)) or
                   ((mp3buf[0]=$FD) and (mp3buf[1]=$FF));

    end;

  if (mp3buf[0]=$FA) or (mp3buf[0]=$F2) or (mp3buf[0]=$FC) then crc:=2 else crc:=0;
  if (mp3buf[0]=$F3) or (mp3buf[0]=$F2) then lll:=72 else lll:=144;
  if (mp3buf[0]=$FC) or (mp3buf[0]=$FD) then layer:=2 else layer:=3;

  if il=0 then goto p999;
  il:=fileread(infofh,mp3buf,2);

  if (layer=3) and (lll=144) then bitrate:=bitrates[mp3buf[0] shr 4]
    else if (layer=3) and (lll=72) then bitrate:=bitrates2[mp3buf[0] shr 4]
      else bitrate:=bitrates22[mp3buf[0] shr 4];  //layer 2

  if lll=144 then samplerate:=freqs[(mp3buf[0] and $0C) shr 2] else samplerate:=freqs2[(mp3buf[0] and $0C) shr 2];
  if (mp3buf[1] shr 6)=3 then channels:=1 else channels:=2;
  if (mp3buf[0] and 2)=2 then padding:=1 else padding:=0;
  len:=crc+padding+trunc((lll*bitrate*1000)/samplerate);
  fs:=fileseek(infofh,len-4,fsfromcurrent);

until (il<>2) or (fs<0);
p999:
result:=i;
t:=gettime-t;

fileclose(infofh);
end;


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
//if fi<>nil then begin
//fi.box(0,0,600,600,15);
//fi.outtextxy(10,10,     'type:             RIFF',178);
//fi.outtextxy (10,30 ,   'size:             '+inttostr(head.size),178);
//fi.outtextxy (10,50 ,   'pcm type:         '+inttostr(head.pcm),178);
//fi.outtextxy (10,70 ,   'channels:         '+inttostr(head.channels),178);
//fi.outtextxy (10,90 ,   'sample rate:      '+inttostr(head.srate),178);
//fi.outtextxy (10,110,   'bitrate:          '+inttostr(head.brate),178);
//fi.outtextxy (10,130,   'bytes per sample: '+inttostr(head.bytesps),178);
//fi.outtextxy (10,150,   'bits per sample:  '+inttostr(head.bps),178);
//fi.outtextxy (10,170,   'data size:        '+inttostr(head.datasize),178);
//end;
if head.pcm=85 then goto p999;

head_datasize:=head.datasize ;
currentdatasize:=head.datasize;

// determine the number of samples

samplenum:=currentdatasize div (head.channels*head.bps div 8);
//fi.outtextxy (10,190,   'samples:          '+inttostr(samplenum),178);

p999:
end;


function mp3open (var fh:integer):integer;

label p999;

var
    il,il2:integer;
    skip:integer;
    q:int64;
    bitrates:array[0..15] of integer=(0,32,40,48,56,64,80,96,112,128,160,192,224,256,320,0);
    freqs:array[0..3] of integer=(44100,48000,32000,0);
    samplerate,channels:integer;

begin
fileseek(fh,0,fsfrombeginning);
fileread(fh,mp3buf,10);
if (mp3buf[0]=ord('I')) and (mp3buf[1]=ord('D')) and (mp3buf[2]=ord('3')) then // Skip ID3
  begin
  skip:=(mp3buf[6] shl 21) + (mp3buf[7] shl 14) + (mp3buf[8] shl 7) + mp3buf[9]+10;
  end
else skip:=0;
mp3buf[0]:=0; mp3buf[1]:=0;
q:=skip;
fileseek(fh,q,fsfrombeginning);

repeat q+=1; mp3buf[1]:=mp3buf[0]; il:=fileread(fh,mp3buf,1) until
  (il=0) or
    ((mp3buf[0]=$FB) and (mp3buf[1]=$FF)) or
      ((mp3buf[0]=$F3) and (mp3buf[1]=$FF)) or
        ((mp3buf[0]=$FA) and (mp3buf[1]=$FF)) or
          ((mp3buf[0]=$F2) and (mp3buf[1]=$FF)) or
           ((mp3buf[0]=$FC) and (mp3buf[1]=$FF)) or
              ((mp3buf[0]=$FD) and (mp3buf[1]=$FF));
fileseek(fh,q-2,fsfrombeginning);


fileread(fh,mp3buf,4);
samplerate:=freqs[(mp3buf[2] and $0C) shr 2];
if (mp3buf[3] shr 6)=3 then channels:=1 else channels:=2;
if mp3buf[1]=$F3 then samplerate:=samplerate div 2;
q:=-4;
fileseek(fh,q,fsfromcurrent);
result:=samplerate;
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
//fi.box(0,0,600,600,15);
//fi.outtextxy (10,10,'type:      PSID',178);
//fi.outtextxy (10,30 ,'version:   '+inttostr(version),178);
//fi.outtextxy (10,50 ,'offset:    '+inttohex(offset,4),178);
//fi.outtextxy (10,70 ,'load:      '+inttohex(load,4),178-144*b);
//fi.outtextxy (10,90 ,'init:      '+inttohex(init,4),178);
//fi.outtextxy (10,110,'play:      '+inttohex(play,4),178);
//fi.outtextxy (10,130,'songs:     '+inttostr(songs),178);
//fi.outtextxy (10,150,'startsong: '+inttostr(startsong),178);
//fi.outtextxy (10,170,'speed:     '+inttohex(speed,8),178);
//fi.outtextxy (10,190,'title:     '+atitle,178);
//fi.outtextxy (10,210,'author:    '+author,178);
//fi.outtextxy (10,230,'copyright: '+copyright,178);
//fi.outtextxy (10,250,'flags:     '+inttohex(flags,4),178);
song:=startsong-1;

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
//fi.outtextxy (10,270,'cia:       '+inttohex(read6502($dc04)+256*read6502($dc05),4),178);
end;


//------------------------------------------------------------------------------
// A helper procedure for displaying time with Winamp skin digits
//------------------------------------------------------------------------------

procedure displaytime(mm,ss:integer);

var mm1,mm2,ss1,ss2:integer;

begin
mm1:=mm div 10;
mm2:=mm mod 10;
ss1:=ss div 10;
ss2:=ss mod 10;

blit8(integer(numbers),180,0,integer(pl.canvas),96,52,18,26,216,550);
blit8(integer(numbers),mm1*18,0,integer(pl.canvas),96,52,18,26,216,550);
blit8(integer(numbers),180,0,integer(pl.canvas),120,52,18,26,216,550);
blit8(integer(numbers),mm2*18,0,integer(pl.canvas),120,52,18,26,216,550);
blit8(integer(numbers),180,0,integer(pl.canvas),156,52,18,26,216,550);
blit8(integer(numbers),ss1*18,0,integer(pl.canvas),156,52,18,26,216,550);
blit8(integer(numbers),180,0,integer(pl.canvas),180,52,18,26,216,550);
blit8(integer(numbers),ss2*18,0,integer(pl.canvas),180,52,18,26,216,550);
end;

// Old player code to be rewritten


procedure old_player;

label p102,p997;

var i,j,sr:integer;

begin

key:=readkey and $FF;

if key=ord('5') then begin siddelay:=20000; songfreq:=50; skip:=0; end
else if key=ord('1') then begin siddelay:=10000; songfreq:=100; skip:=0; end
else if key=ord('2') then begin siddelay:=5000; songfreq:=200; skip:=0;end
else if key=ord('3') then begin siddelay:=6666; songfreq:=150; skip:=0; end
else if key=ord('4') then begin siddelay:=2500; songfreq:=400; skip:=0; end
else if key=ord('p') then begin pause1a:=not pause1a; if pause1a then pauseaudio(1) else pauseaudio(0); end
else if key=key_f1 then begin if channel1on=0 then channel1on:=1 else channel1on:=0; end   // F1 toggle channel 1 on/off
else if key=key_f2 then begin if channel2on=0 then channel2on:=1 else channel2on:=0; end   // F2 toggle channel 1 on/off
else if key=key_f3 then begin if channel3on=0 then channel3on:=1 else channel3on:=0; end   // F3 toggle channel 1 on/off

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
  ext:=lowercase(copy(playfilename,i+1,length(playfilename)-i+1));
  if (ext<>'wav')
    and (ext<>'mp2')
      and (ext<>'mp3')
        and (ext<>'s48')
          and (ext<>'sid')
            and (ext<>'dmp')
              and (ext<>'mod')
                and (ext<>'s3m')
                  and (ext<>'xm')
                    and (ext<>'it')
                      then begin playfilename:=''; goto p997; end;

  av6502:=0;
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
  else if (ext='mp3') or (ext='mp2') then
    begin
    filetype:=4;
    sr:=mp3open(sfh);
    sleep(20);
    filebuffer.setmp3(1);
    sleep(50);
    for i:=0 to 15 do times6502[i]:=0;
    filetype:=4;
    filebuffer.setfile(sfh);
    sleep(200);
    songs:=0;
    if sr>=44100 then
      begin
      if a1base=432 then error:=SA_changeparams(((sr*432) div 440),16,2,384)
                 else error:=SA_changeparams(sr,16,2,384);
      end
    else
      begin
      if a1base=432 then error:=SA_changeparams(((sr*432) div 440),16,2,160)
                    else error:=SA_changeparams(sr,16,2,160);
      end;

    if sr>=44100 then siddelay:=(8707*44100) div sr
    else siddelay:=(160*8707*44100) div (384*sr);

    pauseaudio(0);
    end

   else if (ext='mod')
                 or (ext='s3m')
                 or (ext='xm')
                 or (ext='it')
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
    if i<>0 then
      begin
      xmp_free_context(xmp_context);
      goto p102;
      end;
    i:= xmp_start_player(xmp_context,49152,34);
    xmp_set_player(xmp_context,xmp_player_interp,xmp_interp_spline);
    xmp_set_player(xmp_context,xmp_player_mix,30);

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


   else if ext='s48' then
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

//    box(100,100,100,100,40);
    filebuffer.setfile(sfh);


    sleep(300);
    songs:=0;

    if head.srate=44100 then siddelay:=8707 else siddelay:=2000;

//    box(100,100,100,100,120);

    if head.srate=44100 then if a1base=432 then error:=SA_changeparams(43298,16,head.channels,384)
                                           else error:=SA_changeparams(44100,16,head.channels,384);
    if head.srate=96000 then if a1base=432 then error:=SA_changeparams(94254,32,2,192)
                                           else error:=SA_changeparams(96000,32,2,192);


//    box(100,100,100,100,250);
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
  i:=length(s);
  while (copy(s,i,1)<>'\') and (i>1) do i:=i-1;
  if i>1 then songname:=copy(s,i+1,length(s)-2) else songname:=s;
//  songname:=s;
  songtime:=0;
  timer1:=-1;
  if filetype<>2 then begin pause1a:=false; pauseaudio(0); end;


   end;
p997:
end;



//------------------------------------------------------------------------------
// A main player thread
//------------------------------------------------------------------------------

constructor TPlayerThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;


procedure TPlayerThread.Execute;

var fh,i,j,hh,mm,ss,sl1,sl2:integer;
    s1,s2:string;

    ext,mms,hhs,sss,ps:string;
    qq,qqq:integer;
    eject_down: boolean=false;
    pause_down: boolean=false;
    start_down: boolean=false;
    stop_down: boolean=false;
    prev_down: boolean=false;
    next_down: boolean=false;
    repeat_down: boolean=false;
    shuffle_down: boolean=false;
    playlist_down: boolean=false;
    repeat_selected:boolean=false;
    shuffle_selected:boolean=false;
    playlist_selected:boolean=false;
    fh2:textfile;
    q,vq:integer;
    il:integer;

const clickcount:integer=0;
      vbutton_x:integer=0;
      vbutton_dx:integer=0;
      bbutton_x:integer=0;
      bbutton_dx:integer=0;
      select:boolean=true;
      cnt:integer=0;

begin
songtime:=0;

if playlistitem=nil then
  begin
  playlistitem:=Tplaylistitem.create('');
  playlistitem.x:=28;
  playlistitem.y:=30;

  end;
player_item:=playlistitem;


if filebuffer=nil then
  begin
  filebuffer:=Tfilebuffer.create(true);
  filebuffer.start;
  end;

filetype:=-1;

filetype:=-1;
desired.callback:=@AudioCallback;
desired.channels:=2;
desired.format:=AUDIO_S16;
desired.freq:=480000;
desired.samples:=1200;
error:=openaudio(@desired,@obtained);

//box(0,0,100,30,0); outtextxy(0,0,inttostr(error),15);
prepare_sprites;
hide_sprites;
dir:=drive;
ThreadSetAffinity(ThreadGetCurrent,CPU_AFFINITY_2);

// Create the player window

pl:=Twindow.create(550,232,'');   // no decoration, we will use the skin
pl.resizable:=false;
pl.move(400,500,550,232,0,0);

// If the skin is not loaded, load it
skindir:=drive+'Colors\Bitmaps\Player\Base\';

if cbuttons=nil then
  begin
  cbuttons:=getmem(72*272);
  fh:=fileopen(skindir+'cbuttons.rbm',$40);
  fileread(fh,cbuttons^,72*272);
  fileclose(fh);
  end;
if posbar=nil then
  begin
  posbar:=getmem(614*20);
  fh:=fileopen(skindir+'posbar.rbm',$40);
  fileread(fh,posbar^,614*20);
  fileclose(fh);
  end;
if titlebar=nil then
  begin
  titlebar:=getmem(174*688);
  fh:=fileopen(skindir+'titlebar.rbm',$40);
  fileread(fh,titlebar^,174*688);
  fileclose(fh);
  end;
if baseskin=nil then
  begin
  baseskin:=getmem(127600);
  fh:=fileopen(skindir+'main.rbm',$40);
  fileread(fh,baseskin^,127600);
  fileclose(fh);
  end;
if numbers=nil then
  begin
  numbers:=getmem(26*216);
  fh:=fileopen(skindir+'nums_ex.rbm',$40);
  fileread(fh,numbers^,26*216);
  fileclose(fh);
  end;
if volume=nil then
  begin
  volume:=getmem(866*136);
  fh:=fileopen(skindir+'volume.rbm',$40);
  il:=fileread(fh,volume^,866*136);
  if il<866*136 then sliders:=false;
  fileclose(fh);
  end;
if shufrep=nil then
  begin
  shufrep:=getmem(170*184);
  fh:=fileopen(skindir+'shufrep.rbm',$40);
  fileread(fh,shufrep^,170*184);
  fileclose(fh);
  end;
if monoster=nil then
  begin
  monoster:=getmem(48*116);
  fh:=fileopen(skindir+'monoster.rbm',$40);
  fileread(fh,monoster^,48*116);
  fileclose(fh);
  end;
if playpaus=nil then
  begin
  playpaus:=getmem(84*18);
  fh:=fileopen(skindir+'playpaus.rbm',$40);
  fileread(fh,playpaus^,84*18);
  fileclose(fh);
  end;
if eqmain=nil then
  begin
  eqmain:=getmem(550*630);
  fh:=fileopen(skindir+'eqmain.rbm',$40);
  fileread(fh,eqmain^,550*630);
  fileclose(fh);
  end;
if pledit=nil then
  begin
  pledit:=getmem(560*372);
  fh:=fileopen(skindir+'pledit.rbm',$40);
  fileread(fh,pledit^,560*372);
  fileclose(fh);
  end;
if (balance=nil) and fileexists(skindir+'balance.rbm') then
  begin
  balance:=getmem(866*136);
  fh:=fileopen(skindir+'balance.rbm',$40);
  fileread(fh,balance^,866*136);
  fileclose(fh);
  end;
try
  assignfile(fh2,skindir+'color.txt');
  reset(fh2);
  read(fh2,skintextcolor);
  closefile(fh2);
except
  skintextcolor:=200;
end;

// Draw the skin

blit8(integer(baseskin),0,0,integer(pl.canvas),0,0,550,232,550,550);     // base
blit8(integer(titlebar),56,0,integer(pl.canvas),2,0,546,28,688,550);     // title bar
blit8(integer(titlebar),658,92,integer(pl.canvas),22,48,16,80,688,550);  // OAIDV
blit8(integer(playpaus),0,0,integer(pl.canvas),52,56,18,18,84,550);      // PLAY sign
blit8(integer(playpaus),72,0,integer(pl.canvas),48,56,6,18,84,550);      // PLAY sign
blit8(integer(cbuttons),0,0,integer(pl.canvas),32,176,228,36,272,550);   // transport buttons
blit8(integer(cbuttons),230,0,integer(pl.canvas),272,178,42,32,272,550); // eject button
blit8(integer(volume),0,810,integer(pl.canvas),214,114,136,26,136,550);  // volume bar
if balance=nil then
  begin
  blit8(integer(volume),0,0,integer(pl.canvas),352,114,38,26,136,550);     // balance bar left
  blit8(integer(volume),98,0,integer(pl.canvas),390,114,38,26,136,550);    // balance bar right
  end
else
  begin
  blit8(integer(balance),18,0,integer(pl.canvas),352,114,76,26,136,550);     // balance bar left
  end;

if sliders then blit8(integer(volume),30,844,integer(pl.canvas),318,116,28,22,136,550);  // volume slider
if sliders then blit8(integer(volume),30,844,integer(pl.canvas),376,116,28,22,136,550);  // balance slider
blit8(integer(shufrep),56,0,integer(pl.canvas),328,178,90,30,184,550);   // shuffle button
blit8(integer(shufrep),0,0,integer(pl.canvas),418,178,54,30,184,550);    // rep button
blit8(integer(shufrep),0,122,integer(pl.canvas),438,116,46,24,184,550);  // eq button
blit8(integer(shufrep),46,122,integer(pl.canvas),484,116,46,24,184,550); // pl button
blit8(integer(monoster),58,24,integer(pl.canvas),424,82,58,24,116,550);  // green stereo
blit8(integer(monoster),0,0,integer(pl.canvas),478,82,58,24,116,550);    // gray mono

//for i:=0 to 47 do                                      // retamp icon instead of winamp
//  for j:=0 to 47 do
//    if i48_player[j+48*i]<>0 then pl.putpixel(488+j,172+i,i48_player[j+48*i]);

pl.needclose:=false;

// get the visualization area background for scope/spectrum

if visarea=nil then
  begin
  visarea:=getmem(158*34);
  blit8(integer(pl.canvas),44,84,integer(visarea),0,0,158,34,550,158);
  end;

// initialize volume button position

vbutton_x:=318;
volume_pos:=318;
bbutton_x:=376;
balance_pos:=376;

// The player main loop

repeat
//box(0,0,200,50,0) ;
//outtextxy(0,0,inttohex(ctrl1adr,8),15);
//outtextxy(0,16,inttohex(ctrl2adr,8),15);
//outtextxy(100,0,inttohex(dmanextcb,8),15);

  repeat sleep(1) until pl.redraw;
  pl.redraw:=false;
  inc(cnt);

// unlit playlist buton when window closed

  if (list=nil) and not playlist_down and (clickcount>60) then begin
  blit8(integer(shufrep),46,122,integer(pl.canvas),484,116,46,24,184,550);
  end;

// Change title bar if needed

  if pl.selected and (not select) then
    begin
    blit8(integer(titlebar),56,0,integer(pl.canvas),2,0,546,28,688,550);
    select:=true;
    end ;
  if (not pl.selected) and select then
    begin
    blit8(integer(titlebar),56,30,integer(pl.canvas),2,0,546,28,688,550);
    select:=false;
    end ;

  clickcount:=clickcount+1; // one second click counter to avoid double clicks

// get and display song time, TODO: time to the end of song

  ss:=(songtime div 1000000) mod 60;
  mm:=(songtime div 60000000);
  displaytime(mm,ss);

// visualize the small scope on the skin visualization area

  blit8(integer(visarea),0,0,integer(pl.canvas),44,84,158,34,158,550);
  for j:=46 to 200 do if abs(scope[j])<47000 then pl.box(j,101-scope[j] div (3000),2,2,15);

  if (mousek=1) and pl.selected then dblclick;

// buttons release

  if mousek=0 then
  begin
  ps:='';
  if eject_down then begin blit8(integer(cbuttons),230,0,integer(pl.canvas),272,178,42,32,272,550); eject_down:=false; end; // eject button
  if pause_down then begin blit8(integer(cbuttons),92,0,integer(pl.canvas),32+92,176,46,36,272,550); pause_down:=false; end;  // transport buttons
  if start_down then begin blit8(integer(cbuttons),46,0,integer(pl.canvas),32+46,176,46,36,272,550); start_down:=false; end;  // transport buttons
  if stop_down then begin blit8(integer(cbuttons),138,0,integer(pl.canvas),32+138,176,46,36,272,550);  stop_down:=false; end;  // transport buttons
  if prev_down then begin blit8(integer(cbuttons),0,0,integer(pl.canvas),32,176,46,36,272,550);  prev_down:=false; end;  // transport buttons
  if next_down then begin blit8(integer(cbuttons),184,0,integer(pl.canvas),32+184,176,44,36,272,550);  next_down:=false; end;  // transport buttons
  if repeat_down then begin
    if repeat_selected then blit8(integer(shufrep),0,60,integer(pl.canvas),418,178,54,30,184,550)
    else blit8(integer(shufrep),0,0,integer(pl.canvas),418,178,54,30,184,550);
    repeat_down:=false; end;

  if playlist_down then begin
    if (list=nil) then
      begin
      playlistthread:=TPlaylistthread.create;
      playlistthread.start;
      sleep(100);
      blit8(integer(shufrep),46,146,integer(pl.canvas),484,116,46,24,184,550)
      end
    else
      begin
      playlistthread.terminate;
      blit8(integer(shufrep),46,122,integer(pl.canvas),484,116,46,24,184,550);;
      end;
    playlist_down:=false;
    end;

  if bbutton_dx<>0 then
    begin
    bbutton_x:=mousex-pl.x-bbutton_dx;
    if bbutton_x>400 then bbutton_x:=400;
    if bbutton_x<352 then bbutton_x:=352;
    balance_pos:=bbutton_x;
    if balance=nil then
      begin
      blit8(integer(volume),0,30*abs(round(27*(vq-376)/24)),integer(pl.canvas),352,114,38,26,136,550);     // balance bar left
      blit8(integer(volume),98,30*abs(round(27*(vq-376)/24)),integer(pl.canvas),390,114,38,26,136,550);    // balance bar right
      end
    else
      blit8(integer(balance),18,30*abs(round(27*(vq-376)/24)),integer(pl.canvas),352,114,76,26,136,550);
    if sliders then blit8(integer(volume),30,844,integer(pl.canvas),vq,116,28,22,136,550);
    end;
  bbutton_dx:=0;


  if vbutton_dx<>0 then
    begin
    vbutton_x:=mousex-pl.x-vbutton_dx;
    if vbutton_x>318 then vbutton_x:=318;
    if vbutton_x<214 then vbutton_x:=214;
    volume_pos:=vbutton_x;
    blit8(integer(volume),0,30*round(27*(q-214)/104),integer(pl.canvas),214,114,136,26,136,550);
    if sliders then blit8(integer(volume),30,844,integer(pl.canvas),q,116,28,22,136,550);
    end;
  vbutton_dx:=0;
  end;

// volume button/slider change if mouse drag

  if (pl.mx>vbutton_x) and (pl.mx<vbutton_x+28) and (pl.my>116) and (pl.my<138) and (mousek=1) and (vbutton_dx=0) and (pl.selected) then
    begin
    vbutton_dx:=pl.mx-vbutton_x;
    end;

  q:=mousex-pl.x-vbutton_dx;
  if q<214 then q:=214;
  if q>318 then q:=318;
  if ((mousex-pl.x-vbutton_dx)>0) and ((mousex-pl.x-vbutton_dx)<550) and (mousek=1) and (vbutton_dx<>0) and (pl.selected) then
    begin
    blit8(integer(volume),0,30*round(27*(q-214)/104),integer(pl.canvas),214,114,136,26,136,550);
    if sliders then blit8(integer(volume),00,844,integer(pl.canvas),q,116,28,22,136,550);
    if q<215 then setdbvolume(-73) else setdbvolume(-26+round(26*(q-214)/104));
    if q<215 then ps:='Mute' else ps:='Volume: '+inttostr(-26+round(26*(q-214)/104))+' dB';
    end;

// balance button/slider change if mouse drag

  if (pl.mx>bbutton_x) and (pl.mx<bbutton_x+28) and (pl.my>116) and (pl.my<138) and (mousek=1) and (bbutton_dx=0) and (pl.selected) then
    begin
    bbutton_dx:=pl.mx-bbutton_x;
    end;

  vq:=mousex-pl.x-bbutton_dx;
  if vq<352 then vq:=352;
  if vq>400 then vq:=400;
  if ((mousex-pl.x-bbutton_dx)>0) and ((mousex-pl.x-bbutton_dx)<550) and (mousek=1) and (bbutton_dx<>0) and (pl.selected) then
    begin
    if balance=nil then
      begin
      blit8(integer(volume),0,30*abs(round(27*(vq-376)/24)),integer(pl.canvas),352,114,38,26,136,550);     // balance bar left
      blit8(integer(volume),98,30*abs(round(27*(vq-376)/24)),integer(pl.canvas),390,114,38,26,136,550);    // balance bar right
      end
    else blit8(integer(balance),18,30*abs(round(27*(vq-376)/24)),integer(pl.canvas),352,114,76,26,136,550);
    if sliders then blit8(integer(volume),00,844,integer(pl.canvas),vq,116,28,22,136,550);
    if vq<373 then setbalance(128-round(6.095*(vq-373)))
    else if vq>379 then setbalance(128-round(6.095*(vq-379)))
    else setbalance(128);
    ps:='Balance: ';
    if vq<373 then ps:=ps+'left '+inttostr(abs(round(6.095*(vq-373))))
    else if vq>379 then ps:=ps+'right '+inttostr(abs(round(6.095*(vq-379))))
    else ps:=ps+' center ';
    end;

// if O leter clicked, open settings menu

  if (pl.mx>22) and (pl.my>48) and (pl.mx<38) and (pl.my<64)  and (mousek=1) and (pl.selected) then
    begin
    if sett=nil then
      begin
      settings:=TSettings.Create;
      settings.start;
      end;
    end;


// if V leter clicked, open visualization menu

  if (pl.mx>22) and (pl.my>112) and (pl.mx<38) and (pl.my<128)  and (mousek=1) and (pl.selected) then
    begin
    if vis=nil then
      begin
      visualization:=TVisualization.Create;
      visualization.start;
      end;
    end;

// if retamp icon clicked, display the info

  if (pl.mx>495) and (pl.my>175) and (mousek=1) and  (clickcount>60) and (pl.selected) then
  begin
  clickcount:=0;
  if info=nil then
    begin
    info:=TWindow.create(500,160,'RetAMP info');
    info.decoration.hscroll:=false;
    info.decoration.vscroll:=false;
    info.resizable:=false;
    info.move(650,400,500,160,0,0);
    info.cls(0);
    info.outtextxy(8,8,'RetAMP - the Retromachine Advanced Music Player',skintextcolor);
    info.outtextxy(8,28,'Version: 0.28 - 20170626',skintextcolor);
    info.outtextxy(8,48,'Alpha code',skintextcolor);
    info.outtextxy(8,68,'Plays: mp2, mp3, s48, wav, sid, dmp, mod, s3m, xm, it files',skintextcolor);
    info.outtextxy(8,88,'GPL 2.0 or higher',skintextcolor);
    info.outtextxy(8,108,'more information: pik33@o2.pl',skintextcolor);
    sleep(100);
    info.select;
    end;
  end;

// if info window got close signal, close it

if info<> nil then if info.needclose then begin info.destroy; info:=nil; end;


// next button

if (pl.mx>32+184) and (pl.mx<78+184) and (pl.my>176) and (pl.my<212) and (mousek=1) and (clickcount>60) and not next_down and (pl.selected) then
  begin
  blit8(integer(cbuttons),184,36,integer(pl.canvas),32+184,176,44,36,272,550);   // next button is 2 px shorter
  clickcount:=0;
  next_down:=true;
  if (player_item.next<>nil) then
    begin
    player_item:=player_item.next;
    player_item.select;
    if list<>nil then playlistitem.draw;
    playfilename:=player_item.item
    end
  else if (player_item.next=nil) and repeat_selected then
    begin
    player_item:=playlistitem.next;
    player_item.select;
    if list<>nil then playlistitem.draw;
    playfilename:=player_item.item;
    end;
  end;       // todo: dont play if not started

// prev button

if (pl.mx>32) and (pl.mx<78) and (pl.my>176) and (pl.my<212) and (mousek=1) and (clickcount>60) and not prev_down and (pl.selected) then
  begin
  blit8(integer(cbuttons),0,36,integer(pl.canvas),32,176,46,36,272,550);   // transport buttons
  clickcount:=0;
  prev_down:=true;
  if (player_item.prev<>nil) and (player_item.prev<>playlistitem) then
    begin
    player_item:=player_item.prev;
    player_item.select;
    if list<>nil then playlistitem.draw;
    playfilename:=player_item.item
    end
  else if (player_item.prev=playlistitem) and repeat_selected then
    begin
    while player_item.next<>nil do player_item:=player_item.next;
    playfilename:=player_item.item;
    player_item.select;
    if list<>nil then playlistitem.draw;
    end;
  end;       // todo: dont play if not started


// start button

if (pl.mx>78) and (pl.mx<124) and (pl.my>176) and (pl.my<212) and (mousek=1) and (clickcount>60) and not start_down and (pl.selected) then
  begin
  mp3frames:=0;
  blit8(integer(cbuttons),46,36,integer(pl.canvas),32+46,176,46,36,272,550);    // transport buttons
  blit8(integer(playpaus),0,0,integer(pl.canvas),52,56,18,18,84,550);      // PLAY sign
  blit8(integer(playpaus),72,0,integer(pl.canvas),48,56,6,18,84,550);      // transport status     clickcount:=0;
  start_down:=true;
  if player_item=playlistitem then
    begin
    if player_item.next<>nil then
      begin
      player_item:=player_item.next;
      player_item.select;
      playfilename:=player_item.item;
      end;
    end
  else if player_item<>nil then begin player_item.select; playfilename:=player_item.item; end;
  if list<>nil then playlistitem.draw;
  end;

// stop button

if (pl.mx>170) and (pl.mx<216) and (pl.my>176) and (pl.my<212) and (mousek=1) and (clickcount>60) and not stop_down and (pl.selected) then
  begin
  blit8(integer(cbuttons),138,36,integer(pl.canvas),32+138,176,46,36,272,550);
    // transport buttons
  clickcount:=0;
  pauseaudio(1);
  stop_down:=true;
  blit8(integer(playpaus),66,0,integer(pl.canvas),48,56,6,18,84,550);      // clear transport status
  blit8(integer(playpaus),36,0,integer(pl.canvas),52,56,18,18,84,550);     // stop sign
  if sfh>=0 then fileclose(sfh);
  sfh:=-1;
  end;

// repeat button

if (pl.mx>422) and (pl.mx<476) and (pl.my>180) and (pl.my<206) and (mousek=1) and (clickcount>60) and not repeat_down and (pl.selected) then
  begin
  if repeat_selected then blit8(integer(shufrep),0,90,integer(pl.canvas),420,178,54,30,184,550)
  else blit8(integer(shufrep),0,30,integer(pl.canvas),420,178,54,30,184,550);
  repeat_selected:=not repeat_selected;
  repeat_down:=true;
  clickcount:=0;
  end;

// playlist button

if (pl.mx>484) and (pl.mx<528) and (pl.my>116) and (pl.my<138) and (mousek=1) and (clickcount>60) and not playlist_down and (pl.selected) then
  begin
  if list<>nil then blit8(integer(shufrep),138,146,integer(pl.canvas),484,116,46,24,184,550)
  else blit8(integer(shufrep),138,122,integer(pl.canvas),484,116,46,24,184,550);
  playlist_down:=true;
  clickcount:=0;
  end;

// if pause button clicked, pause

if (pl.mx>124) and (pl.mx<170) and (pl.my>176) and (pl.my<212) and (mousek=1) and (clickcount>60) and not pause_down and (pl.selected) then
  begin
  blit8(integer(cbuttons),92,36,integer(pl.canvas),32+92,176,46,36,272,550);   // transport buttons
  pause_down:=true;
  pause1a:=not pause1a; if pause1a then pauseaudio(1) else pauseaudio(0);
  if pause1a then
    begin
    blit8(integer(playpaus),66,0,integer(pl.canvas),48,56,6,18,84,550);      // clear transport status
    blit8(integer(playpaus),18,0,integer(pl.canvas),52,56,18,18,84,550);     // pause sign
    end
  else
    begin
    blit8(integer(playpaus),0,0,integer(pl.canvas),52,56,18,18,84,550);      // PLAY sign
    blit8(integer(playpaus),72,0,integer(pl.canvas),48,56,6,18,84,550);      // transport status
    end;
  clickcount:=0;
  end;


// if eject button clicked, open the file selector


if (pl.mx>272) and (pl.mx<314) and (pl.my>178) and (pl.my<210) and (mousek=1) and (clickcount>60) and (pl.selected) then
  begin
  eject_down:=true;
  blit8(integer(cbuttons),230,32,integer(pl.canvas),272,178,42,32,272,550); // eject button
  clickcount:=0; // avoid opening a second fileselector until the first is creating
   if sel1=nil then
    begin
    sel1 :=Tfileselector.create(dir);
    sel1.move(900,100,480,500,0,0);
    dblclick;   // avoid double click on fresh opened window, calling the function will switch off the signal
    end;
  end;
if sel1<>nil then
  begin
  if sel1.filename<>'' then  // if a file selected, set a playfilename which will start play the file
    begin
    if list<>nil then
      begin
        i:=length(sel1.filename);
        while (sel1.filename[i]<>'.') and (i>1) do i:=i-1;
        ext:=lowercase(copy(sel1.filename,i+1,length(sel1.filename)-i+1));
        if (ext<>'wav')
          and (ext<>'mp2')
            and (ext<>'mp3')
              and (ext<>'s48')
                and (ext<>'sid')
                  and (ext<>'dmp')
                    and (ext<>'mod')
                      and (ext<>'s3m')
                        and (ext<>'xm')
                          and (ext<>'it')
                            then begin sel1.filename:='';  end

      else playlistitem.append(sel1.filename);
//      retromalina.box(0,0,100,100,0); retromalina.outtextxy(0,0,inttostr(mp3check(sel1.filename)),15);

      dir:=sel1.currentdir2;
      sel1.filename:='';
      end
    else
      begin
      playfilename:=sel1.filename;
      pf2:=playfilename;
      cnt:=0;
      sleep(50);
      if spritebutton<>nil then if spritebutton.selected then start_sprites;  // if dancing sprites visuzlization active, start the sprites
      dir:=sel1.currentdir2;   // remember a file selector direcory
      sel1.destroy;            // and close the file selector window
      sel1:=nil;
      end;
    end;
  end;

// if clicked the upper right corner, close the player

  if (pl.mx>523) and (pl.my<28) and (mousek=1) then pl.needclose:=true;

// run dancing sprites if selected

  if spritebutton<>nil then if spritebutton.selected then vis_sprites;

// close the file selector when it received close signal

  if sel1<>nil then if sel1.needclose then begin playfilename:=''; sel1.destroy; sel1:=nil; end;

// if the player is closing, close its child windows too

//  if (pl.needclose) then
//    begin
//    if (oscilloscopebutton<>nil) then begin oscilloscopebutton.destroy; oscilloscopebutton:=nil; end;
//    if (spritebutton<>nil) then begin spritebutton.destroy; spritebutton:=nil; end;
////    if (sel1<>nil) then begin sel1.destroy; sel1:=nil; end;
//    if (vis<>nil) then begin vis.destroy; vis:=nil; end;
//    if (info<>nil) then begin info.destroy; info:=nil; end;
//    end;


  if pl.selected or (playfilename<>'') then old_player;


  ss:=(songtime div 1000000) mod 60;
  mm:=(songtime div 60000000) mod 60;
  hh:=(songtime div 3600000000);
  sss:=inttostr(ss); if ss<10 then sss:='0'+sss;
  mms:=inttostr(mm); if mm<10 then mms:='0'+mms;
  hhs:=inttostr(hh); if hh<10 then hhs:='0'+hhs;

  songfreq:=1000000 div siddelay;
  if songs>1 then s1:=songname+', song '+inttostr(song+1)
  else s1:=songname;

  if filetype=0 then s2:=inttostr(songfreq)
  else if filetype=1 then s2:=inttostr(1000000 div siddelay)
  else if filetype=3 then s2:=inttostr(head.brate div 125) //'??'   //'Wave file, '+inttostr(head.srate)+' Hz'
  else if filetype=4 then s2:=inttostr(head.brate)
  else if filetype=5 then s2:=inttostr(head.brate)
  else if filetype=6 then s2:='MOD'; //'Module file';
  if s1='' then begin s1:=ver; s2:=''; end;

  sl1:=8*length(s1);
  sl2:=8*length(s2);
  if sl1>sl2 then i:=16+sl1 else i:=16+sl2;
  if i<192 then i:=192;
  //np.l:=i;
  //np.box(0,8,i,16,0);
  if ps<>'' then s1:=ps;
  qq:=length(s1);
  if qq>38 then
    begin
    s1:=s1+'   ***   '+s1+'   ***   ';
    qqq:=(cnt div 12) mod (qq+9)+1;
    s1:=copy(s1,qqq,38);
    end;
  if pl<>nil then begin pl.box(222,54,304,14,mainbackcolor); pl.outtextxy(220,54,s1,maintextcolor); end;
  if pl<>nil then pl.box(220,84,32,16,mainbackcolor);
  if pl<>nil then pl.outtextxy(252-8*length(s2),84,s2,maintextcolor);
  s2:=inttostr((SA_getcurrentfreq) div 1000);
  if pl<>nil then pl.box(309,84,24,16,mainbackcolor);
  if pl<>nil then pl.outtextxy(333-8*length(s2),84,s2,maintextcolor);

  if (nextsong=1) then
    begin
    nextsong:=0;
    if (playlistitem.next=nil) and (pf2<>'') and repeat_selected then playfilename:=pf2

    else if (player_item.next<>nil) and (player_item<>playlistitem) then
      begin
      player_item:=player_item.next;
      player_item.select;
      if list<>nil then playlistitem.draw;
      playfilename:=player_item.item;
      end

    else if repeat_selected and (player_item.next=nil) then
      begin
      player_item:=playlistitem.next;
      player_item.select;
      if list<>nil then playlistitem.draw;
      playfilename:=player_item.item;
      end;
    end;

until pl.needclose;

// now clean up
if sel1<>nil then
  begin
  sel1.destroy;
  sel1:=nil;
  end;
hide_sprites;
//pauseaudio(1);

closeaudio;
//repeat sleep(20) until audio_opened=false;
filebuffer.terminate;
repeat sleep(10) until filebuffer.Terminated;
filebuffer:=nil;
if sfh>0 then fileclose(sfh);
sfh:=-1; s1:=''; s2:='';  songname:='';
if (oscilloscopebutton<>nil) then begin oscilloscopebutton.destroy; oscilloscopebutton:=nil; end;
if (spritebutton<>nil) then begin spritebutton.destroy; spritebutton:=nil; end;
if info<>nil then begin info.destroy; info:=nil; end;
if sc<>nil then sc.needclose:=true;
if vis<>nil then vis.needclose:=true;
if list<>nil then list.needclose:=true;
repeat sleep(10) until list=nil;
player_item:=playlistitem;
while player_item.next<>nil do player_item:=player_item.next;
while player_item.prev<>nil do
  begin
  player_item:=player_item.prev;
  player_item.next.destroy;
  end;
playlistitem.next:=nil;
pl.destroy;
pl:=nil;
end;

//------------------------------------------------------------------------------
// File information window
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Visualization procedures
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Visualization menu thread
//------------------------------------------------------------------------------

constructor TVisualization.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;


procedure TVisualization.execute;

var xx,yy:integer;

begin
if vis=nil then
  begin
  vis:=TWindow.create(256,64,'Visualization menu');
  vis.decoration.hscroll:=false;
  vis.decoration.vscroll:=false;
  vis.resizable:=false;
  vis.cls(0);
  if spritebutton=nil then spritebutton:=TButton.create(4,4,248,26,4,skintextcolor,'Dancing sprites',vis) else begin spritebutton.granny:=vis; vis.buttons:=spritebutton; spritebutton.draw; end;
  if oscilloscopebutton=nil then oscilloscopebutton:=spritebutton.append(4,34,248,26,4,skintextcolor,'Big oscilloscope') else begin oscilloscopebutton.granny:=vis; oscilloscopebutton.draw; end;
  spritebutton.selectable:=true;
  oscilloscopebutton.selectable:=true;
  spritebutton.radiogroup:=1;
  oscilloscopebutton.radiogroup:=2;
  end;

xx:=pl.x; yy:=pl.y;
if xx<400 then vis.move(xx+600,yy,256,64,0,0) else vis.move(xx-300,yy,256,64,0,0);
vis.select;
repeat
  repeat sleep(1) until vis.redraw;
  if sc=nil then oscilloscopebutton.unselect else oscilloscopebutton.select;
  if oscilloscopebutton.clicked=1 then
    begin
    oscilloscopebutton.clicked:=0;
    if oscilloscopebutton.selected then oscilloscopebutton.unselect else oscilloscopebutton.select;
    if oscilloscopebutton.selected then
      begin
      if sc=nil then
        begin
        oscilloscope:=TOscilloscope.create;
        oscilloscope.start;
        end;
      end
    else sc.needclose:=true;
    end;
  if spritebutton.clicked=1 then
    begin
    spritebutton.clicked:=0;
    if spritebutton.selected then spritebutton.unselect else spritebutton.select;
    if spritebutton.selected then start_sprites else hide_sprites;
     end;
until vis.needclose;
//oscilloscopebutton.destroy;
//spritebutton.destroy;
vis.destroy; vis:=nil;
end;

//------------------------------------------------------------------------------
// Visualisation plugin #1 - a big oscilloscope
//------------------------------------------------------------------------------

procedure oscilloscope1(sample:integer);

const oldsc1:integer=0;
      sc1:integer=0;
      scj:integer=0;


begin
oldsc1:=sc1;
sc1:=sample+(sample div 2);
scope[scj]:=sc1;
inc(scj);
if scj>959 then if (oldsc1<0) and (sc1>0) then scj:=0 else scj:=959;
end;

constructor TOscilloscope.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;

procedure TOscilloscope.Execute;

var scr,xx,yy:integer;
    wh:TWindow;
    t:int64;
    i,j,k,l,color:integer;
    newsc:array[0..883,0..186] of byte;
begin

ThreadSetAffinity(ThreadGetCurrent,CPU_AFFINITY_1);
sleep(1);
if sc=nil then
  begin
  sc:=Twindow.create(884,187,'Oscilloscope');      //884,187
  sc.decoration.hscroll:=false;
  sc.decoration.vscroll:=false;
  sc.resizable:=false;
  xx:=pl.x; yy:=pl.y;
    sc.box(0,0,884,187,178);
   sc.box(0,93,884,2,140);
  sc.box(0,27,884,2,140);
  sc.box(0,158,884,2,140);
  if yy>600 then sc.move(xx,yy-220,884,187,0,0) else sc.move(xx,yy+260,884,187,0,0);
  sc.select;
  end;
repeat
  repeat sleep(1) until sc.redraw;
  t:=gettime;
  sc.box(0,0,884,187,178);
  sc.box(0,93,884,2,140);
  sc.box(0,27,884,2,140);
  sc.box(0,158,884,2,140);

{   for i:=1 to 882 do
    for j:=1 to 185 do
      begin
      color:=-5+sc.getpixel(i,j);
      for k:=-1 to 1 do
        for l:=-1 to 1 do
          begin
          color+=sc.getpixel(i+k,j+l);
          end;
      color:=color div 10;
      newsc[i,j]:=color;
      end;
  for i:=0 to 883 do
    for j:=0 to 186 do
      sc.putpixel(i,j,newsc[i,j]);
}
for j:=20 to 840 do {if abs(scope[j])<46000 then }
    begin
    color:=12+(abs(scope[j]) div 8000);
    if color>15 then color:=color-15;
    sc.box(10+j,93-scope[j] div 768,2,2,{190} 16*color+8 {255});
    end;

  sc.redraw:=false;
  t:=gettime-t;
//  sc.outtextxy(0,0,inttostr(t),15);
  until sc.needclose;
sc.destroy; sc:=nil;
end;

//------------------------------------------------------------------------------
// Visualisation plugin #2 - dancing sprites
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Prepare the sprites before using them
//------------------------------------------------------------------------------

procedure prepare_sprites;

var i:integer;
    b:byte;
    c:cardinal;
    a:array[0..3] of byte absolute c;


begin
// Set animated sprites definitions.
// The "balls" is an rotating blue ball definition
// The rest of colors will be set by exchanging color components

spr0:=balls;           // blue ball

for i:=0 to 16383 do   // green ball
  begin
  c:=balls[i];
  b:=a[0]; a[0]:=a[1]; a[1]:=b;
  spr1[i]:=c;
  end;

for i:=0 to 16383 do  // red ball
  begin
  c:=balls[i];
  b:=a[0]; a[0]:=a[2]; a[2]:=b;
  spr2[i]:=c;
  end;

for i:=0 to 16383 do  // cyan ball
  begin
  c:=balls[i];
  a[1]:=a[0];
  spr3[i]:=c;
  end;

for i:=0 to 16383 do  // magenta ball
  begin
  c:=balls[i];
  a[2]:=a[0];
  spr4[i]:=c;
  end;

for i:=0 to 16383 do // yellow ball
  begin
  c:=balls[i];
  b:=a[0];
  a[0]:=a[2];
  a[1]:=b;
  a[2]:=b;
  spr5[i]:=c;
  end;

for i:=0 to 16383 do  // white ball
  begin
  c:=balls[i];
  a[1]:=a[0];
  a[2]:=a[0];
  spr6[i]:=c;
  end;

// initialize sprite speeds

spr0dx:=1;
spr0dy:=1;
spr1dx:=2;
spr1dy:=2;
spr2dx:=3;
spr2dy:=3;
spr3dx:=4;
spr3dy:=4;
spr4dx:=5;
spr4dy:=5;
spr5dx:=6;
spr5dy:=6;
spr6dx:=7;
spr6dy:=7;

// set 2x zoom

sprite0zoom:=$00020002;
sprite1zoom:=$00020002;
sprite2zoom:=$00020002;
sprite3zoom:=$00020002;
sprite4zoom:=$00020002;
sprite5zoom:=$00020002;
//if textcursorx<>$FFFF then sprite6zoom:=$00020002;

// set sprite pointers to sprite definitions

sprite0ptr:=cardinal(@spr0[0]);
sprite1ptr:=cardinal(@spr1[0]);
sprite2ptr:=cardinal(@spr2[0]);
sprite3ptr:=cardinal(@spr3[0]);
sprite4ptr:=cardinal(@spr4[0]);
sprite5ptr:=cardinal(@spr5[0]);
//if textcursorx<>$FFFF then sprite6ptr:=cardinal(@spr6[0]);

end;

//------------------------------------------------------------------------------
// Hide sprites 0..6 by setting x>2048
//------------------------------------------------------------------------------

procedure hide_sprites;

begin
sprite0xy:=$01001080;          // setting sprite x >2048 will hide it
sprite1xy:=$01001100;
sprite2xy:=$01001180;
sprite3xy:=$01001200;
sprite4xy:=$01001280;
sprite5xy:=$01001300;
//if textcursorx<>$FFFF then sprite6xy:=$01001380;
end;

//------------------------------------------------------------------------------
// Unhide sprites 0..6 and set them at different positions
//------------------------------------------------------------------------------

procedure start_sprites;

begin
sprite0xy:=$00800080;
sprite1xy:=$00800100;
sprite2xy:=$00800180;
sprite3xy:=$00800200;
sprite4xy:=$00800280;
sprite5xy:=$00800300;
//if textcursorx<>$FFFF then sprite6xy:=$00800380;
end;


//------------------------------------------------------------------------------
// The main visualization procedure
//------------------------------------------------------------------------------

procedure vis_sprites;

var frame,s0y,s1y,s2y:integer;

begin

// animate the sprites @ 30 fps, there are 16 frames available

frame:=(framecnt mod 32) div 2;

sprite0ptr:=cardinal(@spr0[0])+4096*frame;
sprite1ptr:=cardinal(@spr1[0])+4096*frame;
sprite2ptr:=cardinal(@spr2[0])+4096*frame;
sprite3ptr:=cardinal(@spr3[0])+4096*frame;
sprite4ptr:=cardinal(@spr4[0])+4096*frame;
sprite5ptr:=cardinal(@spr5[0])+4096*frame;
//if textcursorx<>$FFFF then sprite6ptr:=cardinal(@spr6[0])+4096*frame;

// if the file is SID then move the sprites 0,1,2 acccording to SID regs and hide the rest of them

if filetype<3 then
  begin
  if channel1on=1 then sprite0x:=(dpeek(base+$d400) div 40)+74 else sprite0x:=2048;
  s0y:=920-3*(peek(base+$d406) and $F0);
  if s0y<0 then s0y:=0;
  if s0y>yres-64 then s0y:=yres-64;
  sprite0y:=s0y;

  if channel2on=1 then sprite1x:=((peek(base+$d407)+256*peek(base+$d408)) div 40)+74 else sprite1x:=2048;
  s1y:=920-3*(peek(base+$d40d) and $F0);
  if s1y<0 then s1y:=0;
  if s1y>yres-64 then s1y:=yres-64;
  sprite1y:=s1y;

  if channel3on=1 then sprite2x:=(dpeek(base+$d40e) div 40) +74 else sprite2x:=2048; ;
  s2y:=920-3*(peek(base+$d414) and $F0);
  if s2y<0 then s2y:=0;
  if s2y>yres-64 then s2y:=yres-64;
  sprite2y:=s2y;

  sprite3x:=2048;
  sprite4x:=2148;
  sprite5x:=2248;
//  if textcursorx<>$FFFF then   sprite6x:=2348;
  end
else  // animate the bouncing balls

  begin  // check collisions... Is it possible to add colision regs to the sprite machine?

  if sprite3x>2048 then    // unhide and start
    begin
    sprite0x:=100;
    sprite1x:=200;
    sprite2x:=300;
    sprite3x:=400;
    sprite4x:=500;
    sprite5x:=600;
//    if textcursorx<>$FFFF then     sprite6x:=700;
    end;

  if (sqr(sprite0x-sprite1x)+sqr(sprite0y-sprite1y))<=4096 then begin i:=spr0dx; spr0dx:=spr1dx; spr1dx:=i; i:=spr0dy; spr0dy:=spr1dy; spr1dy:=i; end;
  if (sqr(sprite0x-sprite2x)+sqr(sprite0y-sprite2y))<=4096 then begin i:=spr0dx; spr0dx:=spr2dx; spr2dx:=i; i:=spr0dy; spr0dy:=spr2dy; spr2dy:=i; end;
  if (sqr(sprite0x-sprite3x)+sqr(sprite0y-sprite3y))<=4096 then begin i:=spr0dx; spr0dx:=spr3dx; spr3dx:=i; i:=spr0dy; spr0dy:=spr3dy; spr3dy:=i; end;
  if (sqr(sprite0x-sprite4x)+sqr(sprite0y-sprite4y))<=4096 then begin i:=spr0dx; spr0dx:=spr4dx; spr4dx:=i; i:=spr0dy; spr0dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite0x-sprite5x)+sqr(sprite0y-sprite5y))<=4096 then begin i:=spr0dx; spr0dx:=spr5dx; spr5dx:=i; i:=spr0dy; spr0dy:=spr5dy; spr5dy:=i; end;
//  if textcursorx<>$FFFF then   if (sqr(sprite0x-sprite6x)+sqr(sprite0y-sprite6y))<=4096 then begin i:=spr0dx; spr0dx:=spr6dx; spr6dx:=i; i:=spr0dy; spr0dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite1x-sprite2x)+sqr(sprite1y-sprite2y))<=4096 then begin i:=spr1dx; spr1dx:=spr2dx; spr2dx:=i; i:=spr1dy; spr1dy:=spr2dy; spr2dy:=i; end;
  if (sqr(sprite1x-sprite3x)+sqr(sprite1y-sprite3y))<=4096 then begin i:=spr1dx; spr1dx:=spr3dx; spr3dx:=i; i:=spr1dy; spr1dy:=spr3dy; spr3dy:=i; end;
  if (sqr(sprite1x-sprite4x)+sqr(sprite1y-sprite4y))<=4096 then begin i:=spr1dx; spr1dx:=spr4dx; spr4dx:=i; i:=spr1dy; spr1dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite1x-sprite5x)+sqr(sprite1y-sprite5y))<=4096 then begin i:=spr1dx; spr1dx:=spr5dx; spr5dx:=i; i:=spr1dy; spr1dy:=spr5dy; spr5dy:=i; end;
//  if textcursorx<>$FFFF then   if (sqr(sprite1x-sprite6x)+sqr(sprite1y-sprite6y))<=4096 then begin i:=spr1dx; spr1dx:=spr6dx; spr6dx:=i; i:=spr1dy; spr1dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite2x-sprite3x)+sqr(sprite2y-sprite3y))<=4096 then begin i:=spr2dx; spr2dx:=spr3dx; spr3dx:=i; i:=spr2dy; spr2dy:=spr3dy; spr3dy:=i; end;
  if (sqr(sprite2x-sprite4x)+sqr(sprite2y-sprite4y))<=4096 then begin i:=spr2dx; spr2dx:=spr4dx; spr4dx:=i; i:=spr2dy; spr2dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite2x-sprite5x)+sqr(sprite2y-sprite5y))<=4096 then begin i:=spr2dx; spr2dx:=spr5dx; spr5dx:=i; i:=spr2dy; spr2dy:=spr5dy; spr5dy:=i; end;
//  if textcursorx<>$FFFF then   if (sqr(sprite2x-sprite6x)+sqr(sprite2y-sprite6y))<=4096 then begin i:=spr2dx; spr2dx:=spr6dx; spr6dx:=i; i:=spr2dy; spr2dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite3x-sprite4x)+sqr(sprite3y-sprite4y))<=4096 then begin i:=spr3dx; spr3dx:=spr4dx; spr4dx:=i; i:=spr3dy; spr3dy:=spr4dy; spr4dy:=i; end;
  if (sqr(sprite3x-sprite5x)+sqr(sprite3y-sprite5y))<=4096 then begin i:=spr3dx; spr3dx:=spr5dx; spr5dx:=i; i:=spr3dy; spr3dy:=spr5dy; spr5dy:=i; end;
//  if textcursorx<>$FFFF then   if (sqr(sprite3x-sprite6x)+sqr(sprite3y-sprite6y))<=4096 then begin i:=spr3dx; spr3dx:=spr6dx; spr6dx:=i; i:=spr3dy; spr3dy:=spr6dy; spr6dy:=i; end;

  if (sqr(sprite4x-sprite5x)+sqr(sprite4y-sprite5y))<=4096 then begin i:=spr4dx; spr4dx:=spr5dx; spr5dx:=i; i:=spr4dy; spr4dy:=spr5dy; spr5dy:=i; end;
//  if textcursorx<>$FFFF then   if (sqr(sprite4x-sprite6x)+sqr(sprite4y-sprite6y))<=4096 then begin i:=spr4dx; spr4dx:=spr6dx; spr6dx:=i; i:=spr4dy; spr4dy:=spr6dy; spr6dy:=i; end;

//  if textcursorx<>$FFFF then   if (sqr(sprite5x-sprite6x)+sqr(sprite5y-sprite6y))<=4096 then begin i:=spr5dx; spr5dx:=spr6dx; spr6dx:=i; i:=spr5dy; spr5dy:=spr6dy; spr6dy:=i; end;

  // mouse is sprite 7; we want to react when tip of the arrow touches the ball, so adding 32

//  if textcursorx<>$FFFF then   if (sqr(32+sprite6x-sprite7x)+sqr(32+sprite6y-sprite7y)<=1024) and (mousek=1) then begin  spr6dx:=-spr6dx; spr6dy:=-spr6dy;  end;
  if (sqr(32+sprite5x-sprite7x)+sqr(32+sprite5y-sprite7y)<=1024) and (mousek=1) then begin  spr5dx:=-spr5dx; spr5dy:=-spr5dy;  end;
  if (sqr(32+sprite4x-sprite7x)+sqr(32+sprite4y-sprite7y)<=1024) and (mousek=1) then begin  spr4dx:=-spr4dx; spr4dy:=-spr4dy;  end;
  if (sqr(32+sprite3x-sprite7x)+sqr(32+sprite3y-sprite7y)<=1024) and (mousek=1) then begin  spr3dx:=-spr3dx; spr3dy:=-spr3dy;  end;
  if (sqr(32+sprite2x-sprite7x)+sqr(32+sprite2y-sprite7y)<=1024) and (mousek=1) then begin  spr2dx:=-spr2dx; spr2dy:=-spr2dy;  end;
  if (sqr(32+sprite1x-sprite7x)+sqr(32+sprite1y-sprite7y)<=1024) and (mousek=1) then begin  spr1dx:=-spr1dx; spr1dy:=-spr1dy;  end;
  if (sqr(32+sprite0x-sprite7x)+sqr(32+sprite0y-sprite7y)<=1024) and (mousek=1) then begin  spr0dx:=-spr0dx; spr0dy:=-spr0dy; end;

  sprite0x+=spr0dx;   // now we have to use intermediate variables to avoid wild moving of the sprites :)
  sprite0y+=spr0dy;
  if sprite0x>=xres-64 then spr0dx:=-abs(spr0dx);
  if sprite0y>=yres-64 then spr0dy:=-abs(spr0dy);
  if sprite0x<=0 then spr0dx:=abs(spr0dx);
  if sprite0y<=0 then spr0dy:=abs(spr0dy);

  sprite1x+=spr1dx;
  sprite1y+=spr1dy;
  if sprite1x>=xres-64 then spr1dx:=-abs(spr1dx);
  if sprite1y>=yres-64 then spr1dy:=-abs(spr1dy);
  if sprite1x<=0 then spr1dx:=abs(spr1dx);
  if sprite1y<=0 then spr1dy:=abs(spr1dy);

  sprite2x+=spr2dx;
  sprite2y+=spr2dy;
  if sprite2x>=xres-64 then spr2dx:=-abs(spr2dx);
  if sprite2y>=yres-64 then spr2dy:=-abs(spr2dy);
  if sprite2x<=0 then spr2dx:=abs(spr2dx);
  if sprite2y<=0 then spr2dy:=abs(spr2dy);

  sprite3x+=spr3dx;
  sprite3y+=spr3dy;
  if sprite3x>=xres-64 then spr3dx:=-abs(spr3dx);
  if sprite3y>=yres-64 then spr3dy:=-abs(spr3dy);
  if sprite3x<=0 then spr3dx:=abs(spr3dx);
  if sprite3y<=0 then spr3dy:=abs(spr3dy);

  sprite4x+=spr4dx;
  sprite4y+=spr4dy;
  if sprite4x>=xres-64 then spr4dx:=-abs(spr4dx);
  if sprite4y>=yres-64 then spr4dy:=-abs(spr4dy);
  if sprite4x<=0 then spr4dx:=abs(spr4dx);
  if sprite4y<=0 then spr4dy:=abs(spr4dy);

  sprite5x+=spr5dx;
  sprite5y+=spr5dy;
  if sprite5x>=xres-64 then spr5dx:=-abs(spr5dx);
  if sprite5y>=yres-64 then spr5dy:=-abs(spr5dy);
  if sprite5x<=0 then spr5dx:=abs(spr5dx);
  if sprite5y<=0 then spr5dy:=abs(spr5dy);

//  if textcursorx<>$FFFF then
//    begin
//    sprite6x+=spr6dx;
//    sprite6y+=spr6dy;
//    if sprite6x>=xres-64 then spr6dx:=-abs(spr6dx);
//    if sprite6y>=yres-64 then spr6dy:=-abs(spr6dy);
//    if sprite6x<=0 then spr6dx:=abs(spr6dx);
//    if sprite6y<=0 then spr6dy:=abs(spr6dy);
//    end;
  end;
end;


//------------------------------------------------------------------------------
// Visualization menu thread
//------------------------------------------------------------------------------


procedure playlistdrawdecoration(ax,ay:integer);  // todo" make this a method

var i,up_fill,up_fill_n,up_fill_rest,up_fill_title:integer;
    bottom_gap, bottom_gap_n:integer;
    right_fill_n:integer;

begin

// --------------------------- Top

up_fill:=(ax-300) div 2;
up_fill_n:=up_fill div 50;
up_fill_rest:=up_fill mod 50;
up_fill_title:=50+up_fill;
blit8(integer(pledit),0,0,integer(list.canvas),0,0,50,40,560,800);                                          //upper left corner
for i:=1 to up_fill_n do
  blit8(integer(pledit),254,0,integer(list.canvas),50*i,0,50,40,560,800);                                   //upper filler
blit8(integer(pledit),254,0,integer(list.canvas),50+50*up_fill_n,0,up_fill_rest,40,560,800);                //upper filler - the rest
blit8(integer(pledit),52,0,integer(list.canvas),up_fill_title,0,200,40,560,800);                            // title
for i:=1 to up_fill_n do
  blit8(integer(pledit),254,0,integer(list.canvas),up_fill_title+150+50*i,0,50,40,560,800);                 // upper filler
blit8(integer(pledit),254,0,integer(list.canvas),up_fill_title+200+50*up_fill_n,0,up_fill_rest,40,560,800); // upper filler rest
blit8(integer(pledit),306,0,integer(list.canvas),ax-50,0,50,40,560,800);                                    // upper right corner

// right,left

right_fill_n:=(ay-116) div 58;
for i:=0 to right_fill_n do
  begin
  blit8(integer(pledit),0,84,integer(list.canvas),0,40+58*i,50,58,560,800);
  blit8(integer(pledit),52,84,integer(list.canvas),ax-50,40+58*i,50,58,560,800);
  end;

// -------------------------- Bottom
bottom_gap:=ax-550;
bottom_gap_n:=bottom_gap div 50;
for i:=0 to bottom_gap_n do
  blit8(integer(pledit),358,0,integer(list.canvas),250+50*i,ay-76,50,76,560,800);

blit8(integer(pledit),0,144,integer(list.canvas),0,ay-76,250,76,560,800);
blit8(integer(pledit),252,144,integer(list.canvas),ax-300,ay-76,300,76,560,800);

list.box(24,40,ax-64,ay-116,skinbackcolor);
end;

constructor TPlaylistThread.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;


procedure TPlaylistThread.execute;

var xx,yy,i:integer;
    temp,item:TPlaylistItem;
    selecteditem:integer=0;
    items:integer=0;
    state:integer=0;
    dx,dy,dmx,dmy:integer;


// work area: up+40, down-76, yr=y-116

begin
if list=nil then
  begin
  list:=TWindow.create(800,2116,'');
  list.resizable:=false;
  list.cls(0);
  list.activey:=24;
  end;
playlistitem.granny:=list;
item:=playlistitem;
while item.next<>nil do
  begin
  item:=item.next;
  item.granny:=list;
  end;
playlistdrawdecoration(550,464);

xx:=pl.x; yy:=pl.y;
list.move(pl.x+550,pl.y,550,464,0,0);

item:=playlistitem;
i:=0;
if item<>nil then item.draw;


item:=playlistitem;
while item.next<>nil do item:=item.next;




repeat

  repeat sleep(2) until list.redraw;

  list.redraw:=false;
  if item.next<>nil then // someone added something
    begin
    item:=playlistitem;
    item.draw;
    item:=playlistitem;
    while item.next<>nil do item:=item.next
    end;

 if playlistitem.checkall then playlistitem.draw;

if list.selected then
  if (readkey and $FF)=127 then
    begin
    temp:=playlistitem;
    while (temp.next<>nil) and not temp.selected do temp:=temp.next;
    if temp.selected then temp.remove;
    list.box(28,40,list.l-76,list.h-116,0);
    playlistitem.draw;
    end;


//------------------------ Playlist window resizing

if mousek=0 then state:=0;

if (mousek=1) and (list.selected) and (list.mx>list.l-40) and (list.mx<list.l) and (list.my>list.h-40) and (list.my<list.h) and (state=0) then
  begin
  state:=1;
  dmx:=list.l+list.x-mousex;
  dmy:=list.h+list.y-mousey;

  end;
if (mousek=1) and (state=1) then
  begin
  dx:=mousex-list.x+dmx; if dx>800 then dx:=800;  if dx<550 then dx:=550;
  dy:=mousey-list.y+dmy; if dy<223 then dy:=223;
  list.move(-2048,-2048,dx,dy,0,0);
  playlistdrawdecoration(dx,dy);     //550,464
  playlistitem.draw;
  end;



//box(0,0,300,50,0); outtextxy(0,0,inttostr(state)+' '+inttostr(dmx)+' '+inttostr(dmy)+' '+inttostr(mousex)+' '+inttostr(list.x+list.l),15);
until terminated or list.needclose;
sleep(100);
list.destroy;
item:=playlistitem;
while item<>nil do
  begin
  item.granny:=nil;
  item:=item.next;
  end;
list:=nil;
end;


constructor TPlaylistItem.create(Aitem:string);

var i:integer;

begin
inherited create;
item:=Aitem;
i:=length(item);
while (copy(item,i,1)<>'\') and (i>1) do i:=i-1;
if i>1 then name:=copy(item,i+1,length(item)-2) else name:=item;
time:=0;
rep:=1;
next:=nil;
prev:=nil;
end;

procedure TPlaylistItem.append(Aitem:string);

var temp:TPlaylistItem;

begin
temp:=self;
while temp.next<>nil do temp:=temp.next;
temp.next:=TPlaylistitem.create(AItem);
temp.next.prev:=temp;
temp.next.x:=temp.x;
temp.next.y:=temp.y+10;
temp.next.selected:=false;
temp.next.granny:=temp.granny;
end;

procedure TPlaylistItem.remove;

var temp:TPlaylistItem;

begin
temp:=self.next;
if next<>nil then next.prev:=prev;
if prev<>nil then prev.next:=next;
self.destroy;
while temp<>nil do
  begin
  temp.y:=temp.y-10;
  temp:=temp.next;
  end;
end;

function TPlaylistitem.checkall:boolean;

var temp,temp2:TPlaylistitem;
    needredraw:boolean;
    mmx,mmy,mmk:integer;

begin
needredraw:=false;
mmx:=granny.mx;
mmy:=granny.my;
mmk:=mousek;
temp:=self;

while temp.prev<>nil do temp:=temp.prev;
while temp.next<>nil do
  begin
  temp:=temp.next;
  if (mmx>temp.x) and (mmx<temp.x+granny.l-78) and (mmy>temp.y) and (mmy<temp.y+10) and (mmk=1) and not temp.selected then
    begin
    needredraw:=true;
    temp.selected:=true;
    temp2:=temp;
    while temp2.next<>nil do
      begin
      temp2:=temp2.next;
      temp2.selected:=false;
      end;
    temp2:=temp;
    while temp2.prev<>nil do
      begin
      temp2:=temp2.prev;
      temp2.selected:=false;
      end;
    end;

  end;
if playlistitem.granny<>nil then
  begin
  if playlistitem.granny.selected and (mousex>playlistitem.granny.x+28) and (mousex<playlistitem.granny.x+playlistitem.granny.l-78) and (mousey>playlistitem.granny.y+30) and (mousey<playlistitem.granny.y+playlistitem.granny.h-76) and dblclick then
    begin

    temp:=playlistitem;
    while (temp.next<>nil) and not temp.selected do temp:=temp.next;
    if temp.selected then
      begin
      playfilename:=temp.item;
      // mp3check(temp.item);   end;
      player_item:=temp;
      end;
    end;
  end;
result:=needredraw;
end;

procedure TPlaylistItem.draw;

var temp:TPlaylistItem;

begin
temp:=self;
while temp.prev<>nil do temp:=temp.prev;
while temp.next<>nil do
  begin
  temp:=temp.next;
  if (temp.y>=temp.granny.vy+30) and (temp.y<temp.granny.vy+temp.granny.h-86) then
    begin
    if temp.selected then
      begin
      granny.box(temp.x-1,temp.y-2,granny.l-78,10,skintextcolor);
      granny.outtextxy8(temp.x,temp.y,temp.name,skinbackcolor);
      end
    else
      begin
      granny.box(temp.x-1,temp.y-2,granny.l-78,10,skinbackcolor);
      granny.outtextxy8(temp.x,temp.y,temp.name,skintextcolor);
      end;
    end;
  end;
end;

procedure TPlaylistitem.select;

var temp:TPlaylistItem;

begin
self.selected:=true;
temp:=self;
while temp.next<>nil do
  begin
  temp:=temp.next;
  temp.selected:=false;
  end;
temp:=self;
while temp.prev<>nil do
  begin
  temp:=temp.prev;
  temp.selected:=false;
  end;
end;

// ---- TCountThread

constructor TCountThread.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;


procedure TCountThread.Execute;

begin
  repeat
  repeat sleep(10) until countfilename<>'';
  if countfilename<>'' then mp3check(countfilename);
  countfilename:='';
  until terminated;
end;

constructor TSettings.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;


procedure TSettings.Execute;

var skins:array of string; //todo: dynamic list
    ii,il,fh,j:integer;
    sr:TSearchRec;
    currentdir:string;
    fh2:textfile;
    cnt:integer=0;

begin
skins:=nil;
if sett=nil then
  begin
  sdir:=drive+'Colors\Bitmaps\Player\';
  currentdir:=sdir+'*';
  ii:=0;
  if findfirst(currentdir,fadirectory,sr)=0 then
  repeat

  if (sr.attr and faDirectory) = faDirectory then
    begin
    if (sr.name<>'.') and (sr.name<>'..') then
      begin
      setlength(skins,length(skins)+1);
      skins[ii]:=sr.name;

      ii+=1;
      end;
    end;
  until (findnext(sr)<>0);
  sysutils.findclose(sr);

  if ii>5 then sett:=TWindow.create(400,20*ii,'Select the skin') else sett:=TWindow.create(400,100,'Select the skin') ;
  for j:=0 to ii-1 do sett.outtextxy(8,8+20*j,skins[j],skintextcolor);
  sett.move(200,200,400,400,0,0);
  end;
repeat
  repeat sleep(2) until sett.redraw;
  sett.redraw:=false;
  cnt:=cnt+1;
  if (sett.selected) and (mousek=1) and (sett.my<8+20*ii) and (sett.my>8) then
    begin

    sett.cls(0);
    for j:=0 to ii-1 do sett.outtextxy(8,8+20*j,skins[j],skintextcolor);
    sett.box(8,6+20*((sett.my-8) div 20),392,20,skintextcolor);
    sett.outtextxy(8,8+20*((sett.my-8) div 20),skins[(sett.my-8) div 20],skintextcolor-8);
    end;


  if (sett.selected) then
    if (sett.my<8+20*ii) and (sett.my>8) and dblclick then
    begin
    skindir:=sdir+skins[(sett.my-8) div 20]+'\';
    fh:=fileopen(skindir+'cbuttons.rbm',$40);
    fileread(fh,cbuttons^,72*272);
    fileclose(fh);
    fh:=fileopen(skindir+'posbar.rbm',$40);
    fileread(fh,posbar^,614*20);
    fileclose(fh);
    fh:=fileopen(skindir+'titlebar.rbm',$40);
    fileread(fh,titlebar^,174*688);
    fileclose(fh);
    fh:=fileopen(skindir+'main.rbm',$40);
    fileread(fh,baseskin^,127600);
    fileclose(fh);
    fh:=fileopen(skindir+'nums_ex.rbm',$40);
    fileread(fh,numbers^,26*216);
    fileclose(fh);
    fh:=fileopen(skindir+'volume.rbm',$40);
    il:=fileread(fh,volume^,866*136);
    if il<866*136 then sliders:=false else sliders:=true;
    fileclose(fh);
    fh:=fileopen(skindir+'shufrep.rbm',$40);
    fileread(fh,shufrep^,170*184);
    fileclose(fh);
    fh:=fileopen(skindir+'monoster.rbm',$40);
    fileread(fh,monoster^,48*116);
    fileclose(fh);
    fh:=fileopen(skindir+'playpaus.rbm',$40);
    fileread(fh,playpaus^,84*18);
    fileclose(fh);
    fh:=fileopen(skindir+'eqmain.rbm',$40);
    fileread(fh,eqmain^,550*630);
    fileclose(fh);
    fh:=fileopen(skindir+'pledit.rbm',$40);
    fileread(fh,pledit^,560*372);
    fileclose(fh);
    if fileexists(skindir+'balance.rbm') then
      begin
      if balance=nil then balance:=getmem(866*136);
      fh:=fileopen(skindir+'balance.rbm',$40);
      fileread(fh,balance^,866*136);
      fileclose(fh);
      end
    else
      if balance<>nil then
        begin
        freemem(balance);
        balance:=nil;
        end;

    try
      assignfile(fh2,skindir+'color.txt');
      reset(fh2);
      readln(fh2,skintextcolor);
      readln(fh2,skinbackcolor);
      readln(fh2,maintextcolor);
      readln(fh2,mainbackcolor);
      closefile(fh2);
    except
      skintextcolor:=200;
      skinbackcolor:=0;
      maintextcolor:=200;
      mainbackcolor:=0;
    end;

  // Draw the skin

    blit8(integer(baseskin),0,0,integer(pl.canvas),0,0,550,232,550,550);     // base
    blit8(integer(titlebar),56,0,integer(pl.canvas),2,0,546,28,688,550);     // title bar
    blit8(integer(titlebar),658,92,integer(pl.canvas),22,48,16,80,688,550);  // OAIDV
    blit8(integer(playpaus),0,0,integer(pl.canvas),52,56,18,18,84,550);      // PLAY sign
    blit8(integer(playpaus),72,0,integer(pl.canvas),48,56,6,18,84,550);      // PLAY sign
    blit8(integer(cbuttons),0,0,integer(pl.canvas),32,176,228,36,272,550);   // transport buttons
    blit8(integer(cbuttons),230,0,integer(pl.canvas),272,178,42,32,272,550); // eject button
    blit8(integer(volume),0,810,integer(pl.canvas),214,114,136,26,136,550);  // volume bar
    if balance=nil then
      begin
      blit8(integer(volume),0,0,integer(pl.canvas),352,114,38,26,136,550);     // balance bar left
      blit8(integer(volume),98,0,integer(pl.canvas),390,114,38,26,136,550);    // balance bar right
      end
    else
      begin
      blit8(integer(balance),18,0,integer(pl.canvas),352,114,76,26,136,550);     // balance bar left
      end;

    if sliders then blit8(integer(volume),30,844,integer(pl.canvas),volume_pos,116,28,22,136,550);  // volume slider
    if sliders then blit8(integer(volume),30,844,integer(pl.canvas),balance_pos,116,28,22,136,550);  // balance slider
    blit8(integer(shufrep),56,0,integer(pl.canvas),328,178,90,30,184,550);   // shuffle button
    blit8(integer(shufrep),0,0,integer(pl.canvas),418,178,54,30,184,550);    // rep button
    blit8(integer(shufrep),0,122,integer(pl.canvas),438,116,46,24,184,550);  // eq button
    blit8(integer(shufrep),46,122,integer(pl.canvas),484,116,46,24,184,550); // pl button
    blit8(integer(monoster),58,24,integer(pl.canvas),424,82,58,24,116,550);  // green stereo
    blit8(integer(monoster),0,0,integer(pl.canvas),478,82,58,24,116,550);    // gray mono

    blit8(integer(baseskin),44,84,integer(visarea),0,0,158,34,550,158);
    if list<>nil then
      begin
      playlistdrawdecoration(list.l,list.h);
      playlistitem.draw;
      end;
    cnt:=0;
    sett.cls(0);
    for j:=0 to ii-1 do sett.outtextxy(8,8+20*j,skins[j],skintextcolor);
    sett.box(8,6+20*((sett.my-8) div 20),392,20,skintextcolor);
    sett.outtextxy(8,8+20*((sett.my-8) div 20),skins[(sett.my-8) div 20],skintextcolor-8);
    end;

until sett.needclose or terminated;
setlength(skins,0);
sett.destroy;
sett:=nil;
end;


// ---- TFileBuffer thread methods --------------------------------------------------

constructor TFileBuffer.Create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
m:=131072;
pocz:=0;
koniec:=0;
fh:=-1;
newfh:=-1;
il:=0;
newfilename:='';
empty:=true; full:=false;
needclear:=false;
seekamount:=0;
eof:=true;
mp3:=0;
qq:=2048;
reading:=false;
end;

procedure TFileBuffer.Execute;

var i,il2,k:integer;
    ml:int64;
    const cnt:integer=0;
var   outbuf2: PSmallint;
     pcml:integer;

//    info:mp3_info_t;
//    framesize:integer;

begin
outbuf2:=@outbuf;
ThreadSetaffinity(ThreadGetCurrent,2);
sleep(1);
repeat
  if needclear or (seekamount<>0) or (newfh>0) then

  // now do not do maintenence tasks while other thread is reading the buffer or the conflit may happen
    begin

    repeat until not reading;
//                 box(100,100,100,100,200);
    maintenance:=true;
    if eof and (newfh>0) then
      begin
      fh:=newfh;
      newfh:=-1;
      eof:=false;
      qq:=2048;
      end;
    if seekamount<>0 then needclear:=true;
    if needclear then
      begin
      koniec:=0;
      pocz:=0;
      needclear:=false;
      empty:=true;
      m:=131071;
      for i:=0 to 131071 do buf[i]:=0;
      qq:=2048;
      for i:=0 to 32767 do tempbuf[i]:=0;
      end;
    if (seekamount<>0) and (fh>0) then
      begin
      fileseek(fh,seekamount,fsFromCurrent);
      seekamount:=0;
      end;
    maintenance:=false;
    end;
    // end of maintenance processes

//  if newfh>0 then
//  begin
//  fh:=newfh;
//  newfh:=0;
//  end;
  if (fh>0){ and not eof} then
    begin
    if koniec>=pocz then m:=131072-koniec+pocz-1 else m:=pocz-koniec-1;
    if m>=32768 then // more than 32k free place, do a read
      begin
      if mp3=0 then  // no decoding needed, simply read 32k from file
        begin
        il:=fileread(fh,tempbuf[0],qq);
        if il<>0 then for i:=0 to il-1 do buf[(i+koniec) and $1FFFF]:=tempbuf[i] ;
        koniec:=(koniec+il) and $1FFFF;
        m:=m-il;
        if m<3*32678 then empty:=false;
        if (il<qq) and empty then eof:=true;
        end
      else // compressed file: read and decompress
        begin
        cnt+=1;
        il:=fileread(fh,tempbuf[2048-qq],qq);
        if (il<qq) then eof:=true;
        if il=qq then
          begin

           ml:=gettime;


           mad_stream_buffer(@test_mad_stream,@tempbuf, 2048);
           mad_frame_decode(@test_mad_frame, @test_mad_stream);
           mad_synth_frame(@test_mad_synth,@test_mad_frame);
           mp3frames+=1;
           pcml:=test_mad_synth.pcm.length;

  //        box(0,0,100,100,0); outtextxy(0,0,inttostr(l),15);
          if test_mad_synth.pcm.channels=2 then for i:=0 to pcml-1 do begin outbuf2[2*i]:= test_mad_synth.pcm.samples[0,i] div 8704;   outbuf2[2*i+1]:= test_mad_synth.pcm.samples[1,i] div 8704;  end;
          if test_mad_synth.pcm.channels=1 then for i:=0 to pcml-1 do begin outbuf2[2*i]:= test_mad_synth.pcm.samples[0,i] div 8704;   outbuf2[2*i+1]:= test_mad_synth.pcm.samples[0,i] div 8704;  end;
          il2:= (PtrUInt(test_mad_stream.next_frame)-ptruint(@tempbuf));

      // box(100,100,100,100,0); outtextxyz(100,100,inttostr(PtrUInt(test_mad_stream.next_frame)-ptruint(@tempbuf)),15,2,2);     outtextxyz(100,132,inttostr(tempbuf[il2]),15,2,2);

          if head.srate=44100 then head.brate:=8*((130+il2*10) div 261)
          else head.brate:=8*((120+il2*10) div 240);
          head.srate:=44100;//info.sample_rate;
          head.channels:=2;//info.channels;
          for i:=il2 to 2047 do tempbuf[i-il2]:=tempbuf[i];
          for i:=0 to 4*pcml-1 do buf[(i+koniec) and $1FFFF]:=outbuf[i]; // audio bytes
          qq:=il2;
          koniec:=(koniec+4*pcml) and $1FFFF;
          mp3time:=gettime-ml;

          if koniec>=pocz then m:=131072-koniec+pocz-1 else m:=pocz-koniec-1;
          if m<131072-1152 then empty:=false;
          end;
        end;
      end
    else
      begin
      full:=true;
      end;
    end
  else
    begin
//    if newfh>0 then
//      begin
//      fh:=newfh;
//      newfh:=-1;
//      eof:=false;
//      end;
    end;
  sleep(1);
until terminated;

end;

procedure TFileBuffer.setmp3(mp3b:integer);

begin
mp3:=mp3b;
qq:=2048;
needclear:=true;
end;

procedure TFileBuffer.seek(amount:int64);

begin
seekamount:=amount;
end;

function TFileBuffer.getdata(b,ii:integer):integer;

var i,d:integer;

begin
repeat until not maintenance;
reading:=true;
result:=0;
if not empty then
  begin
  if koniec>=pocz then d:=koniec-pocz
  else d:=131072-pocz+koniec;
  if d>=ii then
    begin
    full:=false;
    result:=ii;
    for i:=0 to ii-1 do poke(b+i,buf[(pocz+i) and $1FFFF]);
    pocz:=(pocz+ii) and $1FFFF;
    if pocz=koniec then empty:=true;
    end
  else
    begin
    for i:=0 to d-1 do poke(b+i,buf[(pocz+i) and $1FFFF]);
    for i:=d to ii-1 do poke(b+i,0);
    result:=d;
    pocz:=(pocz+d) and $1FFFF;
    empty:=true;
    end;
  end;
reading:=false;
end;


procedure TFileBuffer.setfile(nfh:integer);

begin
self.newfh:=nfh;
//eof:=false;
end;

procedure TFileBuffer.clear;

begin
self.needclear:=true;
end;



procedure AudioCallback(userdata: Pointer; stream: PUInt8; len:Integer );

label p999;

var audio2:psmallint;
    audio3:psingle;
    s:tsample;
    ttt:int64;
    i,il:integer;
    buf:array[0..25] of byte;

const aa:integer=0;


begin

audio2:=psmallint(stream);
audio3:=psingle(stream);

ttt:=clockgettotal;



if (filetype=3) or (filetype=4) or (filetype=5) then
  begin
  time6502:=0;
  if sfh>0 then
    begin
    if filebuffer.empty {and filebuffer.eof {eof}} then // il<>1536 then
      begin
      fileclose(sfh);
      sfh:=-1;
      songtime:=0;
      pauseaudio(1);
      nextsong:=1;
      timer1:=-1;
      end
    else
      begin
      il:=filebuffer.getdata(integer(stream),len);
      timer1+=siddelay;
      songtime+=siddelay;
      if ((head.pcm=1) or (filetype>=4)) and (len=1536) then for i:=0 to 383 do oscilloscope1(audio2[2*i]+audio2[2*i+1])
                         else if ((head.pcm=1) or (filetype>=4)) and (len=640) then for i:=0 to 159 do oscilloscope1(audio2[2*i]+audio2[2*i+1])
                         else if ((head.pcm=1) or (filetype>=4)) and (len=768) then for i:=0 to 383 do oscilloscope1(audio2[i])
                         else for i:=0 to 95 do oscilloscope1(round(16384*(audio3[4*i]+audio3[4*i+1]+audio3[4*i+2]+audio3[4*i+3])));
      end;
    end;
  end
else if filetype=6 then
  begin
  time6502:=0;
  timer1+=siddelay;
  songtime+=siddelay;
  for i:=0 to 383 do oscilloscope1(audio2[2*i]+audio2[2*i+1]);
  if xmp_play_buffer(xmp_context,stream,len,2)<>0 then
    begin
     pauseaudio(1);
     nextsong:=1;
    end
   else
   begin
     for i:=0 to 767 do audio2[i]:=word(audio2[i])-32768;
   end;
  end
else if filetype=-1 then
  begin
   s:=sid(1);
   audio2[0]:=(s[0]);
   audio2[1]:=(s[1]);
   oscilloscope1(s[0]+s[1]);
   for i:=1 to 1199 do
     begin
     s:=sid(0);
     audio2[2*i]:=(s[0]);
     audio2[2*i+1]:=(s[1]);
     if (i mod 10) = 0 then oscilloscope1(s[0]+s[1]);
     end;
  end
else
  begin
  aa+=2500;
  if (aa>=siddelay) then
    begin
    aa-=siddelay;
    if sfh>-1 then
      begin
      if filetype=0 then

        begin
        time6502:=0;
        il:=fileread(sfh,buf,25);
        if il=25 then
          begin
          for i:=0 to 24 do poke(base+$d400+i,buf[i]);
          timer1+=siddelay;
          songtime+=siddelay;
          end
        else
          begin
          fileclose(sfh);
          sfh:=-1;
          pause1:=true;
          songtime:=0;
          timer1:=-1;
          for i:=0 to 6 do lpoke(base+$d400+4*i,0);
          end;
        end
      else if filetype=1 then
        begin
        for i:=0 to 15 do times6502[i]:=times6502[i+1];
        t6:=clockgettotal;
        jsr6502(256,play);
        times6502[15]:=clockgettotal-t6;
        t6:=0; for i:=0 to 15 do t6+=times6502[i];
        time6502:=t6-15;
        //CleanDataCacheRange($d400,32);
        timer1+=siddelay;
        songtime+=siddelay;
        end;


      end;
    end;
    s:=sid(1);
    audio2[0]:=(s[0]);
    audio2[1]:=(s[1]);
    oscilloscope1(s[0]+s[1]);
    for i:=1 to 1199 do
      begin
      s:=sid(0);
      audio2[2*i]:=(s[0]);
      audio2[2*i+1]:=(s[1]);
      if (i mod 10) = 0 then oscilloscope1(s[0]+s[1]);
      end;
  end;
inc(sidcount);
//sidtime+=gettime-t;
p999:
sidtime:=clockgettotal-ttt;
end;


end.

