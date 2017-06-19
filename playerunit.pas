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
  Classes, SysUtils, platform, retromalina, mwindows, blitter, threads, simpleaudio, retro, icons, retrokeyboard, unit6502,xmp;


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

     TPlaylistThread= class(TThread)
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
     next,prev:TPlaylistItem;
     constructor create(aitem:string);
     procedure append(aitem:string);
     procedure remove;
     end;


const

// CPU Affinity constants copied here

      CPU_AFFINITY_0  = 1;
      CPU_AFFINITY_1  = 2;
      CPU_AFFINITY_2  = 4;
      CPU_AFFINITY_3  = 8;


var pl:TWindow=nil;
    info:TWindow=nil;
    sc:TWindow=nil;
    vis:TWindow=nil;
    fi:TWindow=nil;
    list:TWindow=nil;
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



procedure hide_sprites;
procedure start_sprites;
procedure vis_sprites;
procedure prepare_sprites;
//procedure AudioCallback(userdata: Pointer; stream: PUInt8; len:Integer );


implementation


function mp3check(name:string):integer;

label p999;

var i,il,j,infofh,bitrate, freq, skip, samplerate, padding,len,channels,fs,err:integer;
    mp3buf:array[0..32767] of byte;
    bitrates:array[0..15] of integer=(0,32,40,48,56,64,80,96,112,128,160,192,224,256,320,0);
    freqs:array[0..3] of integer=(44100,48000,32000,0);

begin
infofh:=fileopen(name,$40);
fileread(infofh,mp3buf,10);
if (mp3buf[0]=ord('I')) and (mp3buf[1]=ord('D')) and (mp3buf[2]=ord('3')) then // Skip ID3
  begin
  skip:=(mp3buf[6] shl 21) + (mp3buf[7] shl 14) + (mp3buf[8] shl 7) + mp3buf[9]+10;
  end
else skip:=0;
fileseek(infofh,skip,fsfrombeginning);

if skip>0 then begin
  repeat skip+=1; mp3buf[1]:=mp3buf[0]; fileread(infofh,mp3buf,1) until (mp3buf[0]=$FB) and (mp3buf[1]=$FF);
  fileseek(infofh,skip-2,fsfrombeginning);
  end;
err:=0;
i:=0;
repeat
  i:=i+1;
  il:= fileread(infofh,mp3buf,2);
  if (mp3buf[0]<>$FF) or (mp3buf[1]<>$FB) then     begin err+=1;
    repeat mp3buf[1]:=mp3buf[0]; il:=fileread(infofh,mp3buf,1) until (il=0) or ((mp3buf[0]=$FB) and (mp3buf[1]=$FF));  end;
  if il=0 then goto p999;
  il:=fileread(infofh,mp3buf,2);
  bitrate:=bitrates[mp3buf[0] shr 4];
  samplerate:=freqs[(mp3buf[0] and $0C) shr 2];
  if (mp3buf[1] shr 6)=3 then channels:=1 else channels:=2;
  if (mp3buf[0] and 2)=2 then padding:=1 else padding:=0;
  len:=padding+trunc((144*bitrate*1000)/samplerate);
  fs:=fileseek(infofh,len-4,fsfromcurrent);
  box(0,200,100,100,0); outtextxy(0,200,inttostr(i),15); outtextxy(0,216,inttostr(bitrate),15);outtextxy(0,232,inttostr(samplerate),15); outtextxy(0,248,inttostr(err),15);
until (il<>2) or (fs<0);
p999:
result:=i;
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

//fi.box(0,0,600,600,15);
//fi.outtextxy (10,10 ,'type:           mp3',177);
//fi.outtextxy (10,30 ,   'channels:     '+inttostr(head.channels),177);
//fi.outtextxy (10,50 ,   'sample rate:  '+inttostr(head.srate),177);
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

var i,j:integer;

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

      end;
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

var fh,i,j,hh,mm,ss,q,sl1,sl2:integer;
    s1,s2:string;
    mms,hhs,sss:string;
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
    item:TPlaylistitem;


const clickcount:integer=0;
      vbutton_x:integer=0;
      vbutton_dx:integer=0;
      select:boolean=true;
      cnt:integer=0;

begin
if playlistitem=nil then playlistitem:=Tplaylistitem.create('');
item:=playlistitem;
//box(0,0,100,40,0); outtextxy(0,0,inttostr(integer(playlistitem))+' '+playlistitem.item,15);
prepare_sprites;
hide_sprites;
dir:=drive;
ThreadSetAffinity(ThreadGetCurrent,CPU_AFFINITY_2);

// Create the player window

pl:=Twindow.create(550,232,'');   // no decoration, we will use the skin
pl.resizable:=false;
pl.move(400,500,550,232,0,0);

// If the skin is not loaded, load it


if cbuttons=nil then
  begin
  cbuttons:=getmem(72*272);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\cbuttons.rbm',$40);
  fileread(fh,cbuttons^,72*272);
  fileclose(fh);
  end;
if posbar=nil then
  begin
  posbar:=getmem(614*20);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\posbar.rbm',$40);
  fileread(fh,posbar^,614*20);
  fileclose(fh);
  end;
if titlebar=nil then
  begin
  titlebar:=getmem(174*688);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\titlebar.rbm',$40);
  fileread(fh,titlebar^,174*688);
  fileclose(fh);
  end;
if baseskin=nil then
  begin
  baseskin:=getmem(127600);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\base.rbm',$40);
  fileread(fh,baseskin^,127600);
  fileclose(fh);
  end;
if numbers=nil then
  begin
  numbers:=getmem(26*216);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\nums_ex.rbm',$40);
  fileread(fh,numbers^,26*216);
  fileclose(fh);
  end;
if volume=nil then
  begin
  volume:=getmem(866*136);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\volume.rbm',$40);
  fileread(fh,volume^,866*136);
  fileclose(fh);
  end;
if shufrep=nil then
  begin
  shufrep:=getmem(170*184);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\shufrep.rbm',$40);
  fileread(fh,shufrep^,170*184);
  fileclose(fh);
  end;
if monoster=nil then
  begin
  monoster:=getmem(48*116);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\monoster.rbm',$40);
  fileread(fh,monoster^,48*116);
  fileclose(fh);
  end;
if playpaus=nil then
  begin
  playpaus:=getmem(84*18);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\playpaus.rbm',$40);
  fileread(fh,playpaus^,84*18);
  fileclose(fh);
  end;
if eqmain=nil then
  begin
  eqmain:=getmem(550*630);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\eqmain.rbm',$40);
  fileread(fh,eqmain^,550*630);
  fileclose(fh);
  end;
if pledit=nil then
  begin
  pledit:=getmem(560*372);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\pledit.rbm',$40);
  fileread(fh,pledit^,560*372);
  fileclose(fh);
  end;

// Draw the skin

blit8(integer(baseskin),0,0,integer(pl.canvas),0,0,550,232,550,550);     // base
blit8(integer(titlebar),56,0,integer(pl.canvas),2,0,546,28,688,550);     // title bar
blit8(integer(titlebar),658,92,integer(pl.canvas),22,48,16,80,688,550);  // OAIDV
blit8(integer(playpaus),0,0,integer(pl.canvas),52,56,18,18,84,550);      // PLAY sign
blit8(integer(playpaus),72,0,integer(pl.canvas),48,56,6,18,84,550);      // PLAY sign
blit8(integer(cbuttons),0,0,integer(pl.canvas),32,176,228,36,272,550);   // transport buttons
blit8(integer(cbuttons),230,0,integer(pl.canvas),272,178,42,32,272,550); // eject button
blit8(integer(volume),0,810,integer(pl.canvas),214,112,136,28,136,550);  // volume bar
blit8(integer(volume),0,0,integer(pl.canvas),354,112,38,28,136,550);     // balance bar left
blit8(integer(volume),98,0,integer(pl.canvas),392,112,38,28,136,550);    // balance bar right
blit8(integer(volume),30,844,integer(pl.canvas),318,116,28,22,136,550);  // volume slider
blit8(integer(volume),30,844,integer(pl.canvas),376,116,28,22,136,550);  // balance slider
blit8(integer(shufrep),56,0,integer(pl.canvas),330,178,90,30,184,550);   // shuffle button
blit8(integer(shufrep),0,0,integer(pl.canvas),420,178,54,30,184,550);    // rep button
blit8(integer(shufrep),0,122,integer(pl.canvas),438,116,46,24,184,550);  // eq button
blit8(integer(shufrep),46,122,integer(pl.canvas),484,116,46,24,184,550); // pl button
blit8(integer(monoster),58,24,integer(pl.canvas),428,82,58,24,116,550);  // green stereo
blit8(integer(monoster),0,0,integer(pl.canvas),476,82,58,24,116,550);    // gray mono

for i:=0 to 47 do                                      // retamp icon instead of winamp
  for j:=0 to 47 do
    if i48_player[j+48*i]<>0 then pl.putpixel(488+j,172+i,i48_player[j+48*i]);

pl.needclose:=false;

// get the visualization area background for scope/spectrum

if visarea=nil then
  begin
  visarea:=getmem(158*34);
  blit8(integer(pl.canvas),44,84,integer(visarea),0,0,158,34,550,158);
  end;

// initialize volume button position

vbutton_x:=318;

// The player main loop

repeat
//   retromalina.box(0,0,500,100,0);
//   retromalina.outtextxy(0,0,inttostr(integer(item))+' '+item.name,15) ;
// Wait until redraw done

  box(0,100,100,40,0); outtextxy(0,100,inttostr(mp3frames),15);
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

// volume button/slider release

  if mousek=0 then
  begin
  if eject_down then begin blit8(integer(cbuttons),230,0,integer(pl.canvas),272,178,42,32,272,550); eject_down:=false; end; // eject button
  if pause_down then begin blit8(integer(cbuttons),92,0,integer(pl.canvas),32+92,176,46,36,272,550); pause_down:=false; end;  // transport buttons
  if start_down then begin blit8(integer(cbuttons),46,0,integer(pl.canvas),32+46,176,46,36,272,550); start_down:=false; end;  // transport buttons
  if stop_down then begin blit8(integer(cbuttons),138,0,integer(pl.canvas),32+138,176,46,36,272,550);  stop_down:=false; end;  // transport buttons
  if prev_down then begin blit8(integer(cbuttons),0,0,integer(pl.canvas),32,176,46,36,272,550);  prev_down:=false; end;  // transport buttons
  if next_down then begin blit8(integer(cbuttons),184,0,integer(pl.canvas),32+184,176,44,36,272,550);  next_down:=false; end;  // transport buttons
  if repeat_down then begin
    if repeat_selected then blit8(integer(shufrep),0,60,integer(pl.canvas),420,178,54,30,184,550)
    else blit8(integer(shufrep),0,0,integer(pl.canvas),420,178,54,30,184,550);
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



  if vbutton_dx<>0 then
    begin
    vbutton_x:=mousex-pl.x-vbutton_dx;
    if vbutton_x>318 then vbutton_x:=318;
    if vbutton_x<214 then vbutton_x:=214;
    blit8(integer(volume),0,30*round(27*(q-214)/104),integer(pl.canvas),214,112,136,28,136,550);
    blit8(integer(volume),30,844,integer(pl.canvas),q,116,28,22,136,550);
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
    blit8(integer(volume),0,30*round(27*(q-214)/104),integer(pl.canvas),214,112,136,28,136,550);
    blit8(integer(volume),00,844,integer(pl.canvas),q,116,28,22,136,550);
    if q<220 then setdbvolume(-73) else setdbvolume(-24+round(24*(q-214)/100));
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
    info.outtextxy(8,8,'RetAMP - the Retromachine Advanced Music Player',200);
    info.outtextxy(8,28,'Version: 0.26 - 20170619',200);
    info.outtextxy(8,48,'Alpha code',200);
    info.outtextxy(8,68,'Plays: mp2, mp3, s48, wav, sid, dmp, mod, s3m, xm, it files',200);
    info.outtextxy(8,88,'GPL 2.0 or higher',200);
    info.outtextxy(8,108,'more information: pik33@o2.pl',200);
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
  if (item.next<>nil) then
    begin
    item:=item.next;
    playfilename:=item.item
    end
  else if (item.next=nil) and repeat_selected then
    begin
    item:=playlistitem.next;
    playfilename:=item.item;
    end;
  end;       // todo: dont play if not started

// prev button

if (pl.mx>32) and (pl.mx<78) and (pl.my>176) and (pl.my<212) and (mousek=1) and (clickcount>60) and not prev_down and (pl.selected) then
  begin
  blit8(integer(cbuttons),0,36,integer(pl.canvas),32,176,46,36,272,550);   // transport buttons
  clickcount:=0;
  prev_down:=true;
  if (item.prev<>nil) and (item.prev<>playlistitem) then
    begin
    item:=item.prev;
    playfilename:=item.item
    end
  else if (item.prev=playlistitem) and repeat_selected then
    begin
    while item.next<>nil do item:=item.next;
    playfilename:=item.item;
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
  if item=playlistitem then
    begin
    if item.next<>nil then
      begin
      item:=item.next;
      playfilename:=item.item;
      end;
    end
  else if item<>nil then playfilename:=item.item;
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
      playlistitem.append(sel1.filename);
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

  if (pl.needclose) then
    begin
    if (oscilloscopebutton<>nil) then begin oscilloscopebutton.destroy; oscilloscopebutton:=nil; end;
    if (spritebutton<>nil) then begin spritebutton.destroy; spritebutton:=nil; end;
    if (sel1<>nil) then begin sel1.destroy; sel1:=nil; end;
    if (vis<>nil) then begin vis.destroy; vis:=nil; end;
    if (info<>nil) then begin info.destroy; info:=nil; end;
    end;


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
  else if filetype=3 then s2:='??'   //'Wave file, '+inttostr(head.srate)+' Hz'
  else if filetype=4 then s2:=inttostr(head.brate)
  else if filetype=5 then s2:=inttostr(head.brate)
  else if filetype=6 then s2:='??'; //'Module file';
  if s1='' then begin s1:='No file playing'; s2:=''; end;

  sl1:=8*length(s1);
  sl2:=8*length(s2);
  if sl1>sl2 then i:=16+sl1 else i:=16+sl2;
  if i<192 then i:=192;
  //np.l:=i;
  //np.box(0,8,i,16,0);
  qq:=length(s1);
  if qq>38 then
    begin
    s1:=s1+'   ***   '+s1+'   ***   ';
    qqq:=(cnt div 12) mod (qq+9)+1;
    s1:=copy(s1,qqq,38);
    end;
  if pl<>nil then begin pl.box(222,52,304,16,0); pl.outtextxy(222,52,s1,200); end;
  if pl<>nil then pl.box(220,84,32,16,0);
  if pl<>nil then pl.outtextxy(252-8*length(s2),84,s2,200);
  s2:=inttostr((SA_getcurrentfreq) div 1000);
  if pl<>nil then pl.box(309,84,24,16,0);
  if pl<>nil then pl.outtextxy(333-8*length(s2),84,s2,200);

  if (nextsong=1) then
    begin
    nextsong:=0;
    if (item.next<>nil) and (item<>playlistitem) then
      begin
      item:=item.next;
      playfilename:=item.item;
      end;
    if repeat_selected and (item.next=nil) then
      begin
      item:=playlistitem.next;
      playfilename:=item.item;
      end;
    end;

until pl.needclose;
if info<>nil then begin info.destroy; info:=nil; end;
if sc<>nil then sc.needclose:=true;
if vis<>nil then vis.needclose:=true;
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
  if spritebutton=nil then spritebutton:=TButton.create(4,4,248,26,4,248,'Dancing sprites',vis) else begin spritebutton.granny:=vis; vis.buttons:=spritebutton; spritebutton.draw; end;
  if oscilloscopebutton=nil then oscilloscopebutton:=spritebutton.append(4,34,248,26,4,248,'Big oscilloscope') else begin oscilloscopebutton.granny:=vis; oscilloscopebutton.draw; end;
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

constructor TOscilloscope.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;

procedure TOscilloscope.Execute;

var scr,xx,yy:integer;
    wh:TWindow;
    t:int64;
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
  for j:=20 to 840 do if abs(scope[j])<46000 then sc.box(10+j,93-scope[j] div 768,2,2,190);
  sc.redraw:=false;
  t:=gettime-t;
  sc.outtextxy(0,0,inttostr(t),15);
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

constructor TPlaylistThread.Create;

begin
FreeOnTerminate := True;
inherited Create(true);
end;


procedure TPlaylistThread.execute;

var xx,yy,i:integer;
    item:TPlaylistItem;


begin
if list=nil then
  begin
  list:=TWindow.create(550,464,'');
 // list.decoration.hscroll:=false;
 // list.decoration.vscroll:=true;
  list.resizable:=false;
  list.cls(0);
  list.activey:=24;
  end;


blit8(integer(pledit),0,0,integer(list.canvas),0,0,50,40,560,550);
blit8(integer(pledit),254,0,integer(list.canvas),50,0,50,40,560,550);
blit8(integer(pledit),254,0,integer(list.canvas),100,0,50,40,560,550);
blit8(integer(pledit),254,0,integer(list.canvas),150,0,25,40,560,550);
blit8(integer(pledit),52,0,integer(list.canvas),175,0,200,40,560,550);
blit8(integer(pledit),254,0,integer(list.canvas),375,0,50,40,560,550);
blit8(integer(pledit),254,0,integer(list.canvas),425,0,50,40,560,550);
blit8(integer(pledit),254,0,integer(list.canvas),475,0,25,40,560,550);
blit8(integer(pledit),306,0,integer(list.canvas),500,0,50,40,560,550);
blit8(integer(pledit),0,84,integer(list.canvas),0,40,50,58,560,550);
blit8(integer(pledit),52,84,integer(list.canvas),500,40,50,58,560,550);
blit8(integer(pledit),0,84,integer(list.canvas),0,98,50,58,560,550);
blit8(integer(pledit),52,84,integer(list.canvas),500,98,50,58,560,550);
blit8(integer(pledit),0,84,integer(list.canvas),0,156,50,58,560,550);
blit8(integer(pledit),52,84,integer(list.canvas),500,156,50,58,560,550);
blit8(integer(pledit),0,84,integer(list.canvas),0,214,50,58,560,550);
blit8(integer(pledit),52,84,integer(list.canvas),500,214,50,58,560,550);
blit8(integer(pledit),0,84,integer(list.canvas),0,272,50,58,560,550);
blit8(integer(pledit),52,84,integer(list.canvas),500,272,50,58,560,550);
blit8(integer(pledit),0,84,integer(list.canvas),0,330,50,58,560,550);
blit8(integer(pledit),52,84,integer(list.canvas),500,330,50,58,560,550);
blit8(integer(pledit),0,84,integer(list.canvas),0,378,50,58,560,550);
blit8(integer(pledit),52,84,integer(list.canvas),500,378,50,58,560,550);
blit8(integer(pledit),0,144,integer(list.canvas),0,388,250,76,560,550);
blit8(integer(pledit),252,144,integer(list.canvas),250,388,300,76,560,550);
// test
xx:=pl.x; yy:=pl.y;
list.move(pl.x+550,pl.y,550,464,0,0);
//for xx:=0 to 31 do list.putchar8(30+8*xx, 50, chr(xx),200);
//for xx:=32 to 63 do list.putchar8(30+8*(xx-32), 60, chr(xx),200);
//for xx:=64 to 95 do list.putchar8(30+8*(xx-64), 70, chr(xx),200);
//for xx:=96 to 127 do list.putchar8(30+8*(xx-96), 80, chr(xx),200);

//list.outtextxy8(30,90,'ABCDEFG abcdefg 123456 !@#$%^',200);
item:=playlistitem;
i:=0;
if item=nil then list.outtextxy(30,50,'nil',200);
while item<>nil do
  begin
  list.outtextxy8(28,40+i*10,copy(item.name,1,60),200);
  i+=1;
  item:=item.next;
  end;
item:=playlistitem;

// retromalina.box(0,0,200,200,0);
 //    i:=0;
while item.next<>nil do

  begin
  item:=item.next; // now the item points to the last one
//  retromalina.outtextxy(0,16*i,inttostr(integer(item))+' '+inttostr(integer(item.prev))+' '+inttostr(integer(item.next)),15);
//  i:=i+1;
  end;



repeat


  repeat sleep(2) until list.redraw;




  list.redraw:=false;
  if item.next<>nil then // someone added something
    begin
    list.box(28,40,473,338,0);
    item:=playlistitem;
    i:=0;
    while item<>nil do
      begin
      list.outtextxy8(28,40+i*10,copy(item.name,1,60),200);
      i+=1;
      item:=item.next;
      end;
    item:=playlistitem;
    while item.next<>nil do item:=item.next
    end;
until terminated or list.needclose;
sleep(100);
list.destroy; list:=nil;
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
end;

procedure TPlaylistItem.remove;

begin
if next<>nil then next.prev:=prev;
if prev<>nil then prev.next:=next;
self.destroy;
end;

        {
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
    if filebuffer.eof then // il<>1536 then
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
      if ((head.pcm=1) or (filetype>=4)) and (len=1536) then for i:=0 to 383 do oscilloscope(audio2[2*i]+audio2[2*i+1])
                         else if ((head.pcm=1) or (filetype>=4)) and (len=768) then for i:=0 to 383 do oscilloscope(audio2[i])
                         else for i:=0 to 95 do oscilloscope(round(16384*(audio3[4*i]+audio3[4*i+1]+audio3[4*i+2]+audio3[4*i+3])));
      end;
    end;
  end
else if filetype=6 then
  begin
  time6502:=0;
  timer1+=siddelay;
  songtime+=siddelay;
  for i:=0 to 383 do oscilloscope(audio2[2*i]+audio2[2*i+1]);
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
    oscilloscope(s[0]+s[1]);
    for i:=1 to 1199 do
      begin
      s:=sid(0);
      audio2[2*i]:=(s[0]);
      audio2[2*i+1]:=(s[1]);
      if (i mod 10) = 0 then oscilloscope(s[0]+s[1]);
      end;
  end;
inc(sidcount);
//sidtime+=gettime-t;
p999:
sidtime:=clockgettotal-ttt;
end;

}
end.

