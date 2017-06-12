unit playerunit;

{$mode objfpc}{$H+}

interface

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

    playerthread:TPlayerthread=nil;
    oscilloscope:TOscilloscope=nil;
    visualization:TVisualization=nil;

    sel1:TFileselector=nil;
    playfilename:string;
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

procedure hide_sprites;
procedure start_sprites;
procedure vis_sprites;
procedure prepare_sprites;

implementation


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
// A helper procedurt for displaying time with Winamp skin digits
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

var fh,i,j,mm,ss,q:integer;

    const clickcount:integer=0;
          vbutton_x:integer=0;
          vbutton_dx:integer=0;
          select:boolean=true;

begin
prepare_sprites;
hide_sprites;
dir:=drive;
ThreadSetAffinity(ThreadGetCurrent,CPU_AFFINITY_2);

// Create the player window

pl:=Twindow.create(550,232,'');   // no decoration, we will use the skin
pl.resizable:=false;
pl.move(400,500,550,231,0,0);

// If the skin is not loaded, load it

if cbuttons=nil then
  begin
  cbuttons:=getmem(72*272);
  fh:=fileopen(drive+'Colors\Bitmaps\Player\cbuttons.rbm',$40);
  fileread(fh,cbuttons^,72*272);
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
blit8(integer(shufrep),56,2,integer(pl.canvas),330,180,90,26,184,550);   // shuffle button
blit8(integer(shufrep),2,2,integer(pl.canvas),422,180,54,26,184,550);    // rep button
blit8(integer(shufrep),0,122,integer(pl.canvas),438,116,44,22,184,550);  // eq button
blit8(integer(shufrep),46,122,integer(pl.canvas),484,116,44,22,184,550); // pl button
blit8(integer(monoster),58,24,integer(pl.canvas),428,82,58,24,116,550);  // green stereo
blit8(integer(monoster),0,0,integer(pl.canvas),476,82,58,24,116,550);    // gray mono

for i:=0 to 47 do                                      // retamp icon instead of winamp
  for j:=0 to 47 do
    if i48_player[j+48*i]<>0 then pl.putpixel(486+j,172+i,i48_player[j+48*i]);

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

// Wait until redraw done


  repeat sleep(1) until pl.redraw;
  pl.redraw:=false;

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

// volume button/slider release

  if mousek=0 then
  begin
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

  if (pl.mx>vbutton_x) and (pl.mx<vbutton_x+28) and (pl.my>116) and (pl.my<138) and (mousek=1) and (vbutton_dx=0) then
    begin
    vbutton_dx:=pl.mx-vbutton_x;
    end;

  q:=mousex-pl.x-vbutton_dx;
  if q<214 then q:=214;
  if q>318 then q:=318;
  if ((mousex-pl.x-vbutton_dx)>0) and ((mousex-pl.x-vbutton_dx)<550) and (mousek=1) and (vbutton_dx<>0) then
    begin
    blit8(integer(volume),0,30*round(27*(q-214)/104),integer(pl.canvas),214,112,136,28,136,550);
    blit8(integer(volume),00,844,integer(pl.canvas),q,116,28,22,136,550);
    if q<220 then setdbvolume(-73) else setdbvolume(-24+round(24*(q-214)/100));
    end;

// if V leter clicked, open vizualization menu

  if (pl.mx>22) and (pl.my>112) and (pl.mx<38) and (pl.my<128)  and (mousek=1) then
    begin
    if vis=nil then
      begin
      visualization:=TVisualization.Create;
      visualization.start;
      end;
    end;

// if retamp icon clicked, display the info

  if (pl.mx>495) and (pl.my>175) and (mousek=1) and  (clickcount>60) then
  begin
  clickcount:=0;
  if info=nil then
    begin
    info:=TWindow.create(500,160,'RetAMP info');
    info.decoration.hscroll:=false;
    info.decoration.vscroll:=false;
    info.resizable:=false;
    info.move(650,400,500,160,0,0);
    info.cls(2);
    info.outtextxy(8,8,'RetAMP - the Retromachine Advanced Music Player',248);
    info.outtextxy(8,28,'Version: 0.25u - 20170602',248);
    info.outtextxy(8,48,'Alpha code',248);
    info.outtextxy(8,68,'Plays: mp2, mp3, s48, wav, sid, dmp, mod, s3m, xm, it files',248);
    info.outtextxy(8,88,'GPL 2.0 or higher',248);
    info.outtextxy(8,108,'more information: pik33@o2.pl',248);
    sleep(100);
    info.select;
    end;
  end;

// if info window got close signal, close it

if info<> nil then if info.needclose then begin info.destroy; info:=nil; end;

// if eject button clicked, open the file selector

if (pl.mx>272) and (pl.mx<314) and (pl.my>178) and (pl.my<210) and (mousek=1) and (clickcount>60) then
  begin
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
    playfilename:=sel1.filename;
    sleep(50);
    if spritebutton<>nil then if spritebutton.selected then start_sprites;  // if dancing sprites visuzlization active, start the sprites
    dir:=sel1.currentdir2;   // remember a file selector direcory
    sel1.destroy;            // and close the file selector window
    sel1:=nil;
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


  if pl.selected then old_player;

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

end.

