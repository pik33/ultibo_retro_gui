unit simpleaudio;

//------------------------------------------------------------------------------
// A simple audio unit for Ultibo modelled after SDL audio API
// v.0.92 beta - 20170621
// pik33@o2.pl
// gpl 2.0 or higher
//------------------------------------------------------------------------------
//
// beta changelog
//
// 0.92 - balance control added
//      - DMA buffers are now cleaned before use
//      - 9-bit noiseshaper function started, not used yet
//      - bugfix: close audio now check if it is opened.
//
// 0.91 - fixed the bug which caused 1-channel sound play badly distorted
//
//------------------------------------------------------------------------------

{$mode objfpc}{$H+}

interface

uses  Classes, SysUtils, Platform, HeapManager, Threads, GlobalConst, math;

type

// ----  I decided to use SDL-like API so this fragment is copied from SDL unit
// ----- and modified somewhat

TAudioSpecCallback = procedure(userdata: Pointer; stream: PUInt8; len:Integer );

PAudioSpec = ^TAudioSpec;

TAudioSpec = record
  freq: Integer;       // DSP frequency -- samples per second
  format: UInt16;      // Audio data format
  channels: UInt8;     // Number of channels: 1 mono, 2 stereo
  silence: UInt8;      // Audio buffer silence value (calculated)
  samples: UInt16;     // Audio buffer size in samples
  padding: UInt16;     // Necessary for some compile environments
  size: UInt32;        // Audio buffer size in bytes (calculated)

                       //     This function is called when the audio device needs more data.
                       //    'stream' is a pointer to the audio data buffer
                       //    'len' is the length of that buffer in bytes.
                       //     Once the callback returns, the buffer will no longer be valid.
                       //     Stereo samples are stored in a LRLRLR ordering.

  callback: TAudioSpecCallback;
  userdata: Pointer;
                      // 3 fields added, not in SDL

  oversample: UInt8;  // oversampling value
  range: UInt16;      // PWM range
  oversampled_size: integer; // oversampled buffer size
  end;


const

// ---------- Error codes

      freq_too_low=            -$11;
      freq_too_high=           -$12;
      format_not_supported=    -$21;
      invalid_channel_number=  -$41;
      size_too_low =           -$81;
      size_too_high=           -$81;
      callback_not_specified= -$101;

// ---------- Audio formats. Subset of SDL formats
// ---------- These are 99.99% of wave file formats:

      AUDIO_U8  = $0008; // Unsigned 8-bit samples
      AUDIO_S16 = $8010; // Signed 16-bit samples
      AUDIO_F32 = $8120; // Float 32 bit



// SDL based functions
function  OpenAudio(desired, obtained: PAudioSpec): Integer;
procedure CloseAudio;
procedure PauseAudio(p:integer);

// Functions not in SDL API
function  ChangeAudioParams(desired, obtained: PAudioSpec): Integer;
procedure SetVolume(vol:single);
procedure SetVolume(vol:integer);
procedure setDBVolume(vol:single);
procedure SetBalance(amount:integer);
function getDBVolume:single;

// Simplified functions
function  SA_OpenAudio(freq,bits,channels,samples:integer; callback: TAudioSpecCallback):integer;
function  SA_ChangeParams(freq,bits,channels,samples:integer): Integer;
function  SA_GetCurrentFreq:integer;
function  SA_GetCurrentRange:integer;
procedure  SA_SetEQ(band,db:integer);
procedure  SA_SetEQpreamp(db:integer);
var
dmanextcb,
ctrl1adr,
ctrl2adr:cardinal;
et:int64;
eq_preamp:integer=0;
eq:array[0..9] of integer=(0,0,0,0,0,0,0,0,0,0);
eqdbtable:array[-12..12] of integer=(256,288,323,363,408,458,513,579,646,725,814,914,1024,1150,1292,1450,1628,1828,2051,2302,2583,2900,3253,3651,4096);
equalizer_active:boolean=false;

//------------------ End of Interface ------------------------------------------

implementation
uses retromalina;
type
     PLongBuffer=^TLongBuffer;
     TLongBuffer=array[0..65535] of integer;  // 64K DMA buffer
     TCtrlBlock=array[0..7] of cardinal;
     PCtrlBlock=^TCtrlBlock;

TAudioThread= class(TThread)
private
protected
  procedure Execute; override;
public
 Constructor Create(CreateSuspended : boolean);
end;


const nocache=$C0000000;              // constant to disable GPU L2 Cache
      pll_freq=500000000;             // base PLL freq=500 MHz
      pwm_base_freq=1920000;

      divider=2;

      base_freq=pll_freq div divider;
      max_pwm_freq=pwm_base_freq div divider;

      dma_buffer_size=65536;          // max size for simplified channel

// TODO: make the sample buffer size dynamic (?)

      sample_buffer_size=8192;        // max size for sample buffer.
                                      // The max allowed by dma_buffer_size is 1536 for 44100/16/2 wave
      sample_buffer_32_size=16384;     // 8x sample_buffer_size for 8-bit mono samples

// ------- Hardware registers addresses --------------------------------------

      _pwm_fif1_ph= $7E20C018;       // PWM FIFO input reg physical address

      _pwm_ctl=     $3F20C000;       // PWM Control Register MMU address
      _pwm_dmac=    $3F20C008;       // PWM DMA Configuration MMU address
      _pwm_rng1=    $3F20C010;       // PWM Range channel #1 MMU address
      _pwm_rng2=    $3F20C020;       // PWM Range channel #2 MMU address

      _gpfsel4=     $3F200010;       // GPIO Function Select 4 MMU address
      _pwmclk=      $3F1010a0;       // PWM Clock ctrl reg MMU address
      _pwmclk_div=  $3F1010a4;       // PWM clock divisor MMU address

      _dma_enable=  $3F007ff0;       // DMA enable register
      _dma_cs=      $3F007000;       // DMA control and status
      _dma_conblk=  $3F007004;       // DMA ctrl block address
      _dma_nextcb=  $3F00701C;       // DMA next control block

// ------- Hardware initialization constants

      transfer_info=$00050140;        // DMA transfer information
                                      // 5 - DMA peripheral code (5 -> PWM)
                                      // 1 - src address increment after read
                                      // 4 - DREQ controls write

      and_mask_40_45=  %11111111111111000111111111111000;  // AND mask for gpio 40 and 45
      or_mask_40_45_4= %00000000000000100000000000000100;  // OR mask for set Alt Function #0 @ GPIO 40 and 45

      clk_plld=     $5a000016;       // set clock to PLL D
      clk_div=      $5a000000 + divider shl 12;  //002000;       // set clock divisor to 2.0

      pwm_ctl_val=  $0000a1e1;       // value for PWM init:
                                     // bit 15: chn#2 set M/S mode=1. Use PWM mode for non-noiseshaped audio and M/S mode for oversampled noiseshaped audio
                                     // bit 13: enable fifo for chn #2
                                     // bit 8: enable chn #2
                                     // bit 7: chn #1 M/S mode on
                                     // bit 6: clear FIFO
                                     // bit 5: enable fifo for chn #1
                                     // bit 0: enable chn #1

      pwm_dmac_val= $80000707;       // PWM DMA ctrl value:
                                     // bit 31: enable DMA
                                     // bits 15..8: PANIC value
                                     // bits 7..0: DREQ value

      dma_chn= 14;                   // use DMA channel 14 (the last)


var       gpfsel4:cardinal     absolute _gpfsel4;      // GPIO Function Select 4
          pwmclk:cardinal      absolute _pwmclk;       // PWM Clock ctrl
          pwmclk_div: cardinal absolute _pwmclk_div;   // PWM Clock divisor
          pwm_ctl:cardinal     absolute _pwm_ctl;      // PWM Control Register
          pwm_dmac:cardinal    absolute _pwm_dmac;     // PWM DMA Configuration MMU address
          pwm_rng1:cardinal    absolute _pwm_rng1;     // PWM Range channel #1 MMU address
          pwm_rng2:cardinal    absolute _pwm_rng2;     // PWM Range channel #2 MMU address

          dma_enable:cardinal  absolute _dma_enable;   // DMA Enable register

          dma_cs:cardinal      absolute _dma_cs+($100*dma_chn); // DMA ctrl/status
          dma_conblk:cardinal  absolute _dma_conblk+($100*dma_chn); // DMA ctrl block addr
          dma_nextcb:cardinal  absolute _dma_nextcb+($100*dma_chn); // DMA next ctrl block addr

          dmactrl_ptr:PCardinal=nil;                   // DMA ctrl block pointer
          dmactrl_adr:cardinal absolute dmactrl_ptr;       // DMA ctrl block address
          dmabuf1_ptr:PCardinal=nil;                 // DMA data buffer #1 pointer
          dmabuf1_adr:cardinal absolute dmabuf1_ptr;   // DMA data buffer #1 address
          dmabuf2_ptr:PCardinal=nil;                 // DMA data buffer #2 pointer
          dmabuf2_adr:cardinal absolute dmabuf2_ptr;   // DMA data buffer #2 address

          ctrl1_ptr,ctrl2_ptr:PCtrlBlock;              // DMA ctrl block array pointers
          ctrl1_adr:cardinal absolute ctrl1_ptr;       // DMA ctrl block #1 array address
          ctrl2_adr:cardinal absolute ctrl2_ptr;       // DMA ctrl block #2 array address


//          CurrentAudioSpec:TAudioSpec;

          SampleBuffer_ptr:pointer;
          SampleBuffer_ptr_b:PByte absolute SampleBuffer_ptr;
          SampleBuffer_ptr_si:PSmallint absolute SampleBuffer_ptr;
          SampleBuffer_ptr_f:PSingle absolute SampleBuffer_ptr;
          SampleBuffer_adr:cardinal absolute SampleBuffer_ptr;

          SampleBuffer_32_ptr:PCardinal;
          SampleBuffer_32_adr:cardinal absolute SampleBuffer_32_ptr;

          AudioThread:TAudioThread;

          AudioOn:integer=0;                 // 1 - audio worker thread is running
          volume:integer=4096;               // audio volume; 4096 -> 0 dB
          pauseA:integer=1;                   // 1 - audio is paused


          nc:cardinal;
          working:integer;
          CurrentAudioSpec:TAudioSpec;
          s_desired, s_obtained: TAudioSpec;

          audio_opened:boolean=false;
          balance:integer=128;
          dbvolume:single=0;

procedure InitAudioEx(range,t_length:integer);  forward;
function noiseshaper8(bufaddr,outbuf,oversample,len:integer):integer; forward;
function noiseshaper9(bufaddr,outbuf,oversample,len:integer):integer; forward;
procedure equalizer(bufaddr,len:integer); forward;
procedure equalizer2(bufaddr,len:integer); forward;

// ------------------------------------------------
// A helper procedure which removes RAM RO limit
// used here to speed up the noise shaper
//-------------------------------------------------

procedure removeramlimits(addr:integer);

var Entry:TPageTableEntry;

begin
Entry:=PageTableGetEntry(addr);
Entry.Flags:=$3b2;            //executable, shareable, rw, cacheable, writeback
PageTableSetEntry(Entry);
Entry:=PageTableGetEntry(addr+4096);
Entry.Flags:=$3b2;            //executable, shareable, rw, cacheable, writeback
PageTableSetEntry(Entry);
end;

//------------------------------------------------------------------------------
//  Procedure initaudio - init the GPIO, PWM and DMA for audio subsystem.
//------------------------------------------------------------------------------


procedure InitAudioEx(range,t_length:integer);               //TODO don't init second time!!!

var i:integer;

begin
dmactrl_ptr:=GetAlignedMem(64,32);      // get 64 bytes for 2 DMA ctrl blocks
ctrl1_ptr:=PCtrlBlock(dmactrl_ptr);     // set pointers so the ctrl blocks can be accessed as array
ctrl2_ptr:=PCtrlBlock(dmactrl_ptr+8);   // second ctrl block is 8 longs further
dmabuf1_ptr:=getmem(65536);                       // allocate 64k for DMA buffer
dmabuf2_ptr:=getmem(65536);                       // .. and the second one

for i:=0 to 16383 do
  begin
  dmabuf1_ptr[i]:=127;
  dmabuf2_ptr[i]:=127;
  end;

ctrl1_ptr^[0]:=transfer_info;             // transfer info
ctrl1_ptr^[1]:=nocache+dmabuf1_adr;       // source address -> buffer #1
ctrl1_ptr^[2]:=_pwm_fif1_ph;              // destination address
ctrl1_ptr^[3]:=t_length;                  // transfer length
ctrl1_ptr^[4]:=$0;                        // 2D length, unused
ctrl1_ptr^[5]:=nocache+ctrl2_adr;         // next ctrl block -> ctrl block #2
ctrl1_ptr^[6]:=$0;                        // unused
ctrl1_ptr^[7]:=$0;                        // unused
ctrl2_ptr^:=ctrl1_ptr^;                   // copy first block to second
ctrl2_ptr^[5]:=nocache+ctrl1_adr;         // next ctrl block -> ctrl block #1
ctrl2_ptr^[1]:=nocache+dmabuf2_adr;       // source address -> buffer #2
CleanDataCacheRange(dmactrl_adr,64);      // now push this into RAM
sleep(1);

// Init the hardware

gpfsel4:=(gpfsel4 and and_mask_40_45) or or_mask_40_45_4;  // gpio 40/45 as alt#0 -> PWM Out
pwmclk:=clk_plld;                                          // set PWM clock src=PLLD (500 MHz)
pwmclk_div:=clk_div;                                       // set PWM clock divisor=2 (250 MHz)
pwm_rng1:=range;                                           // minimum range for 8-bit noise shaper to avoid overflows
pwm_rng2:=range;                                           //
pwm_ctl:=pwm_ctl_val;                                      // pwm contr0l - enable pwm, clear fifo, use fifo
pwm_dmac:=pwm_dmac_val;                                    // pwm dma enable
dma_enable:=dma_enable or (1 shl dma_chn);                 // enable dma channel # dma_chn
dma_conblk:=nocache+ctrl1_adr;                             // init DMA ctr block to ctrl block # 1
dma_cs:=$00FF0003;                                         // start DMA

audio_opened:=true;
//dmanextcb:=dma_nextcb;
//ctrl1adr:=ctrl1_adr;
//ctrl2adr:=ctrl2_adr;
end;


function SA_OpenAudio(freq,bits,channels,samples:integer; callback: TAudioSpecCallback):integer;

begin
s_desired.freq:=freq;
s_desired.samples:=samples;
s_desired.channels:=channels;
s_desired.samples:=samples;
s_desired.callback:=callback;
case bits of
  8:s_desired.format:= AUDIO_U8;
  16:s_desired.format:=AUDIO_S16;
  32:s_desired.format:=AUDIO_F32;
  else
    begin
    result:=format_not_supported;
    exit;
    end;
  end;
result:=OpenAudio(@s_desired,@s_obtained);
end;

function  SA_ChangeParams(freq,bits,channels,samples:integer): Integer;

begin
s_desired.freq:=freq;
s_desired.samples:=samples;
s_desired.channels:=channels;
s_desired.samples:=samples;
s_desired.callback:=nil;
case bits of
  0:s_desired.format:=0;
  8:s_desired.format:= AUDIO_U8;
  16:s_desired.format:=AUDIO_S16;
  32:s_desired.format:=AUDIO_F32;
  else
    begin
    result:=format_not_supported;
    exit;
    end;
  end;
result:=ChangeAudioParams(@s_desired,@s_obtained);
end;


// ----------------------------------------------------------------------
// OpenAudio
// Inits the audio according to specifications in 'desired' record
// The values which in reality had been set are in 'obtained' record
// Returns 0 or the error code, in this case 'obtained' is invalid
//
// You have to set the fields:
//
//     freq: samples per second, 8..960 kHz
//     format: audio data format
//     channels: number of channels: 1 mono, 2 stereo
//     samples: audio buffer size in samples. >32, not too long (<384 for stereo 44100 Hz)
//     callback: a callback function you have to write in your program
//
// The rest of fields in 'desire' will be ignored. They will be filled in 'obtained'
// ------------------------------------------------------------------------

function OpenAudio(desired, obtained: PAudioSpec): Integer;

var maxsize:double;
    over_freq:integer;

begin

result:=0;

// -----------  check if params can be used
// -----------  the frequency should be between 8 and 960 kHz

if desired^.freq<8000 then
  begin
  result:=freq_too_low;
  exit;
  end;

if desired^.freq>max_pwm_freq then
  begin
  result:=freq_too_high;
  exit;
  end;

//----------- check if the format is supported

if (desired^.format <> AUDIO_U8) and (desired^.format <> AUDIO_S16) and (desired^.format <> AUDIO_F32) then
  begin
  result:=format_not_supported;
  exit;
  end;

//----------- check the channel number

if (desired^.channels < 1) or (desired^.channels>2) then
  begin
  result:=invalid_channel_number;
  exit;
  end;

//----------- check the buffer size in samples
//----------- combined with the noise shaper should not exceed 64k
//            It is ~384 for 44 kHz S16 samples

if (desired^.samples<32) then
  begin
  result:=size_too_low;
  exit;
  end;

maxsize:=65528/max_pwm_freq*desired^.freq/desired^.channels;

if (desired^.samples>maxsize) then
  begin
  result:=size_too_high;
  exit;
  end;

if (desired^.callback=nil) then
  begin
  result:=callback_not_specified;
  exit;
  end;

// now compute the obtained parameters

obtained^:=desired^;

obtained^.oversample:=max_pwm_freq div desired^.freq;

  // the workaround for simply making 432 Hz tuned sound
  // the problem is: when going 44100->43298
  // the computed oversample changes from 21 to 22
  // and this causes the resulting DMA buffer exceed 64K
  // Also if I init the 43298 Hz soud, I will want to change it to 44100
  // without changing anything else

  if obtained^.oversample=22 then obtained^.oversample:=21;

over_freq:=desired^.freq*obtained^.oversample;
obtained^.range:=round(base_freq/over_freq);
obtained^.freq:=round(base_freq/(obtained^.range*obtained^.oversample));
if (desired^.format = AUDIO_U8) then obtained^.silence:=128 else obtained^.silence:=0;
obtained^.padding:=0;
obtained^.size:=obtained^.samples*obtained^.channels;
if obtained^.size>sample_buffer_size then
  begin
  result:=size_too_high;
  exit;
  end;

if obtained^.channels=2 then obtained^.oversampled_size:=obtained^.size*4*obtained^.oversample
                       else obtained^.oversampled_size:=obtained^.size*8*obtained^.oversample; //output is always 2 channels
if obtained^.format=AUDIO_U8 then obtained^.size:=obtained^.size;
if obtained^.format=AUDIO_S16 then obtained^.size:=obtained^.size*2;
if obtained^.format=AUDIO_F32 then obtained^.size:=obtained^.size*4;
InitAudioEx(obtained^.range,obtained^.oversampled_size);
CurrentAudioSpec:=obtained^;
samplebuffer_ptr:=getmem(sample_buffer_size);
samplebuffer_32_ptr:=getmem(sample_buffer_32_size);
removeramlimits(integer(@noiseshaper8));  // noise shaper uses local vars or it will be slower
removeramlimits(integer(@equalizer));  // noise shaper uses local vars or it will be slower
removeramlimits(integer(@equalizer2));  // noise shaper uses local vars or it will be slower
removeramlimits(integer(@noiseshaper9));  // noise shaper uses local vars or it will be slower
// now create and start the audio thread
pauseA:=1;
AudioThread:=TAudioThread.Create(true);
AudioThread.start;
end;


// ---------- ChangeAudioParams -----------------------------------------
//
// This function will try to change audio parameters
// without closing and reopening the audio system (=loud click)
// The usage is the same as OpenAudio
//
// -----------------------------------------------------------------------

function ChangeAudioParams(desired, obtained: PAudioSpec): Integer;

var maxsize:double;
    over_freq:integer;

begin

// -------------- Do all things as in OpenAudio
// -------------- TODO: what is common, should go to one place

result:=0;
if desired^.freq=0 then desired^.freq:=CurrentAudioSpec.freq;
if desired^.freq<8000 then
  begin
  result:=freq_too_low;
  exit;
  end;
if desired^.freq>max_pwm_freq then
  begin
  result:=freq_too_high;
  exit;
  end;
if desired^.format=0 then desired^.format:=CurrentAudioSpec.format;
if (desired^.format <> AUDIO_U8) and (desired^.format <> AUDIO_S16) and (desired^.format <> AUDIO_F32) then
  begin
  result:=format_not_supported;
  exit;
  end;
if desired^.channels=0 then desired^.channels:=CurrentAudioSpec.channels;
if (desired^.channels < 1) or (desired^.channels>2) then
  begin
  result:=invalid_channel_number;
  exit;
  end;
if desired^.samples=0 then desired^.samples:=CurrentAudioSpec.samples ;
if (desired^.samples<32) then
  begin
  result:=size_too_low;
  exit;
  end;
maxsize:=65528/max_pwm_freq*desired^.freq/desired^.channels;
if (desired^.samples>maxsize) then
  begin
  result:=size_too_high;
  exit;
  end;
if (desired^.callback=nil) then  desired^.callback:=CurrentAudioSpec.callback;

obtained^:=desired^;



obtained^.oversample:=max_pwm_freq div desired^.freq;
  // the workaround for simply making 432 Hz tuned sound
  // the problem is: when going 44100->43298
  // the computed oversample changes from 21 to 22
  // and this causes the resulting DMA buffer exceed 64K

  if obtained^.oversample=22 then obtained^.oversample:=21;

over_freq:=desired^.freq*obtained^.oversample;
obtained^.range:=round(base_freq/over_freq);
obtained^.freq:=round(base_freq/(obtained^.range*obtained^.oversample));
if (desired^.format = AUDIO_U8) then obtained^.silence:=128 else obtained^.silence:=0;
obtained^.padding:=0;
obtained^.size:=obtained^.samples*obtained^.channels;
if obtained^.size>sample_buffer_size then
  begin
  result:=size_too_high;
  exit;
  end;

if obtained^.channels=2 then obtained^.oversampled_size:=obtained^.size*4*obtained^.oversample
                       else obtained^.oversampled_size:=obtained^.size*8*obtained^.oversample; //output is always 2 channels
if obtained^.format=AUDIO_S16 then obtained^.size:=obtained^.size * 2;
if obtained^.format=AUDIO_F32 then obtained^.size:=obtained^.size * 4;

// Here the common part ends.
//
// Now we cannot "InitAudio" as it is already init and running
// Instead we will change - only when needed:
//
// - PWM range
// - DMA transfer length

if obtained^.range<>CurrentAudioSpec.range then
  begin
  pwm_ctl:=0;                   // stop PWM
  pwm_rng1:=obtained^.range;    // set a new range
  pwm_rng2:=obtained^.range;
  pwm_ctl:=pwm_ctl_val;         // start PWM
  end;
  debug1:=dma_nextcb;
  debug2:=ctrl2_adr;
  debug3:=ctrl1_adr;
  begin
  repeat sleep(0) until dma_nextcb=nocache+ctrl2_adr;
  ctrl1_ptr^[3]:=obtained^.oversampled_size;
  repeat sleep(0) until dma_nextcb=nocache+ctrl1_adr;
  ctrl2_ptr^[3]:=obtained^.oversampled_size;
  end;

repeat until working=1;
repeat until working=0;
CurrentAudioSpec:=obtained^;


//outtextxy(100,16,inttostr(ctrl1_adr),15);
end;


procedure CloseAudio;

begin

// Stop audio worker thread

//PauseAudio(1);
if audio_opened then
  begin
  AudioThread.terminate;
  repeat sleep(1) until AudioOn=0;

// ...then switch off DMA...

  ctrl1_ptr^[5]:=0;
  ctrl2_ptr^[5]:=0;


// up to 8 ms of audio can still reside in the buffer

  sleep(20);

// Now disable DMA and PWM...

  dma_cs:=$80000000;

  pwm_ctl:=0;

//... and return the memory to the system

  dispose(dmabuf1_ptr);
  dispose(dmabuf2_ptr);
  freemem(dmactrl_ptr);
  freemem(samplebuffer_ptr);
  freemem(samplebuffer_32_ptr);
  audio_opened:=false;
  end;
end;

procedure pauseaudio(p:integer);

begin
if p=1 then pauseA:=1;
if p=0 then pausea:=0;
end;

procedure SetVolume(vol:single);
// Setting the volume as float in range 0..1

begin
if (vol>=0) and (vol<=1) then
  begin
  volume:=round(vol*4096);
  dbvolume:=20*log10(vol);
  end;
end;

procedure SetVolume(vol:integer);

// Setting the volume as integer in range 0..4096

begin
if (vol>=0) and (vol<=4096) then
  begin
  volume:=vol;
  dbvolume:=20*log10(vol/4096)
  end;
end;

procedure setDBVolume(vol:single);

// Setting decibel volume. This has to be negative number in range ~-72..0)

begin
dbvolume:=vol;
if (vol<0) and (vol>=-72) then volume:=round(4096*power(10,vol/20));
if vol<-72 then volume:=0;
if vol>=0 then volume:=4096;
end;

function getDBVolume:single;

begin
result:=dbvolume;
end;

procedure setbalance(amount:integer);

begin
balance:=amount;
end;


procedure equalizer2(bufaddr,len:integer);

label p101,p102,p999,
      filter1ll,filter2ll,filter3ll,filter4ll,filter5ll,
      filter6ll,filter7ll,filter8ll,filter9ll,
      filter1lr,filter2lr,filter3lr,filter4lr,filter5lr,
      filter6lr,filter7lr,filter8lr,filter9lr,
      len1,bufaddr1,
      e1freq, e2freq, e3freq, e4freq, e5freq, e6freq, e7freq, e8freq, e9freq, e10freq,
      e1db,e2db,e3db,e4db,e5db,e6db,e7db,e8db,e9db,e10db,preamp;

var ptr:Pcardinal;
    e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,p:cardinal;

begin
e1:=eqdbtable[eq[0]];
e2:=eqdbtable[eq[1]];
e3:=eqdbtable[eq[2]];
e4:=eqdbtable[eq[3]];
e5:=eqdbtable[eq[4]];
e6:=eqdbtable[eq[5]];
e7:=eqdbtable[eq[6]];
e8:=eqdbtable[eq[7]];
e9:=eqdbtable[eq[8]];
e10:=eqdbtable[eq[9]];
P:=eqdbtable[eq_preamp];


//signed 28bit

                asm

                push {r0-r12,r14}

                ldr r0,p
                ldr r1,e1
                ldr r2,e2
                ldr r3,e3
                ldr r4,e4
                ldr r5,e5
                ldr r6,e6
                ldr r7,e7
                ldr r8,e8
                ldr r9,e9
                ldr r10,e10

                str r0,preamp
                str r1,e1db
                str r2,e2db
                str r3,e3db
                str r4,e4db
                str r5,e5db
                str r6,e6db
                str r7,e7db
                str r8,e8db
                str r9,e9db
                str r10,e10db

                ldr r0,len
                ldr r12,bufaddr

                str r0,len1
                str r12,bufaddr1

                ldr r1,filter1ll
                ldr r2,filter2ll
                ldr r3,filter3ll
                ldr r4,filter4ll
                ldr r5,filter5ll
                ldr r6,filter6ll
                ldr r7,filter7ll
                ldr r8,filter8ll
                ldr r9,filter9ll
                mov r10,#0

p101:           ldr r14,[r12]
                sub r14,#0x8000000    //signed  28 bit

                mov r10,#0
                sub r14,r1           // r14=highpass
                ldr r11,e1freq
                smlal r10,r1,r14,r11

                sub r14,r2
                mov r10,#0
                lsl r11,#1
                smlal r10,r2,r14,r11

                sub r14,r3
                mov r10,#0
                lsl r11,#1
                smlal r10,r3,r14,r11

                sub r14,r4
                mov r10,#0
                lsl r11,#1
                smlal r10,r4,r14,r11

                sub r14,r5
                mov r10,#0
                lsl r11,#1
                smlal r10,r5,r14,r11

                sub r14,r6
                mov r10,#0
                lsl r11,#1
                smlal r10,r6,r14,r11

                sub r14,r7
                mov r10,#0
                lsl r11,#1
                smlal r10,r7,r14,r11

                sub r14,r8
                mov r10,#0
                lsl r11,#1
                smlal r10,r8,r14,r11

                sub r14,r9
                mov r10,#0
                lsl r11,#1
                smlal r10,r9,r14,r11

                mov r10, #0

                ldr r11,e10db               // 16 kHz
                smull r10,r11,r14,r11
                lsr r10,#10
                orr r10,r10,r11,lsl #22

                ldr r11,e9db
                smull r14,r11,r9,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e8db
                smull r14,r11,r8,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e7db
                smull r14,r11,r7,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e6db
                smull r14,r11,r6,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e5db
                smull r14,r11,r5,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e4db
                smull r14,r11,r4,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e3db
                smull r14,r11,r3,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e2db
                smull r14,r11,r2,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e1db
                smull r14,r11,r1,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14


                ldr r14,preamp
                lsl r14,#18
                smull r11,r10,r14,r10

                lsl r10,#4

                cmp r10,#0x8000000
                movge r10,#0x8000000
                subge r10,#1
                cmp r10,#-0x8000000
                movle r10,#-0x8000000
                addle r10,#1


                add r10,#0x8000000

                str r10,[r12],#8

                subs r0,#1
                bne p101

                str r1,filter1ll
                str r2,filter2ll
                str r3,filter3ll
                str r4,filter4ll
                str r5,filter5ll
                str r6,filter6ll
                str r7,filter7ll
                str r8,filter8ll
                str r9,filter9ll

// right

                ldr r0,len1
                ldr r12,bufaddr1
                add r12,#4

                ldr r1,filter1lr
                ldr r2,filter2lr
                ldr r3,filter3lr
                ldr r4,filter4lr
                ldr r5,filter5lr
                ldr r6,filter6lr
                ldr r7,filter7lr
                ldr r8,filter8lr
                ldr r9,filter9lr
                mov r10,#0

p102:           ldr r14,[r12]
                sub r14,#0x8000000    //signed  28 bit

                mov r10,#0
                sub r14,r1           // r14=highpass
                ldr r11,e1freq
                smlal r10,r1,r14,r11

                sub r14,r2
                mov r10,#0
                lsl r11,#1
                smlal r10,r2,r14,r11

                sub r14,r3
                mov r10,#0
                lsl r11,#1
                smlal r10,r3,r14,r11

                sub r14,r4
                mov r10,#0
                lsl r11,#1
                smlal r10,r4,r14,r11

                sub r14,r5
                mov r10,#0
                lsl r11,#1
                smlal r10,r5,r14,r11

                sub r14,r6
                mov r10,#0
                lsl r11,#1
                smlal r10,r6,r14,r11

                sub r14,r7
                mov r10,#0
                lsl r11,#1
                smlal r10,r7,r14,r11

                sub r14,r8
                mov r10,#0
                lsl r11,#1
                smlal r10,r8,r14,r11

                sub r14,r9
                mov r10,#0
                lsl r11,#1
                smlal r10,r9,r14,r11

                mov r10, #0

                ldr r11,e10db               // 16 kHz
                smull r10,r11,r14,r11
                lsr r10,#10
                orr r10,r10,r11,lsl #22

                ldr r11,e9db
                smull r14,r11,r9,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e8db
                smull r14,r11,r8,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e7db
                smull r14,r11,r7,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e6db
                smull r14,r11,r6,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e5db
                smull r14,r11,r5,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e4db
                smull r14,r11,r4,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e3db
                smull r14,r11,r3,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e2db
                smull r14,r11,r2,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14

                ldr r11,e1db
                smull r14,r11,r1,r11
                lsr r14,#10
                orr r14,r14,r11,lsl #22
                add r10,r14


                ldr r14,preamp
                lsl r14,#18
                smull r11,r10,r14,r10

                lsl r10,#4

                cmp r10,#0x8000000
                movge r10,#0x8000000
                subge r10,#1
                cmp r10,#-0x8000000
                movle r10,#-0x8000000
                addle r10,#1


                add r10,#0x8000000

                str r10,[r12],#8

                subs r0,#1
                bne p102

                str r1,filter1lr
                str r2,filter2lr
                str r3,filter3lr
                str r4,filter4lr
                str r5,filter5lr
                str r6,filter6lr
                str r7,filter7lr
                str r8,filter8lr
                str r9,filter9lr

                b p999

e1freq:         .long 0x000D6775       //30

filter1ll:      .long 0
filter2ll:      .long 0
filter3ll:      .long 0
filter4ll:      .long 0
filter5ll:      .long 0
filter6ll:      .long 0
filter7ll:      .long 0
filter8ll:      .long 0
filter9ll:      .long 0

filter1lr:      .long 0
filter2lr:      .long 0
filter3lr:      .long 0
filter4lr:      .long 0
filter5lr:      .long 0
filter6lr:      .long 0
filter7lr:      .long 0
filter8lr:      .long 0
filter9lr:      .long 0

e10db:           .long 0
e9db:            .long 0
e8db:            .long 0
e7db:            .long 0
e6db:            .long 0
e5db:            .long 0
e4db:            .long 0
e3db:            .long 0
e2db:            .long 0
e1db:            .long 0
preamp:          .long 0

len1:             .long 0
bufaddr1:         .long 0

p999:            pop {r0-r12,r14}
                end;

end;

procedure equalizer(bufaddr,len:integer);

label p101,p999,  testfreq,
      filter1bl, filter1br, filter1ll, filter1lr,
      filter2bl, filter2br, filter2ll, filter2lr,
      filter3bl, filter3br, filter3ll, filter3lr,
      filter4bl, filter4br, filter4ll, filter4lr,
      filter5bl, filter5br, filter5ll, filter5lr,
      filter6bl, filter6br, filter6ll, filter6lr,
      filter7bl, filter7br, filter7ll, filter7lr,
      filter8bl, filter8br, filter8ll, filter8lr,
      filter9bl, filter9br, filter9ll, filter9lr,
      filter0bl, filter0br, filter0ll, filter0lr,
      resl,resr,
      e1freq, e2freq, e3freq, e4freq, e5freq, e6freq, e7freq, e8freq, e9freq, e10freq;


var  e1db,e2db,e3db,e4db,e5db,e6db,e7db,e8db,e9db,e10db:integer;
     preamp:integer;

begin
e1db:=eqdbtable[eq[0]];
e2db:=eqdbtable[eq[1]];
e3db:=eqdbtable[eq[2]];
e4db:=eqdbtable[eq[3]];
e5db:=eqdbtable[eq[4]];
e6db:=eqdbtable[eq[5]];
e7db:=eqdbtable[eq[6]];
e8db:=eqdbtable[eq[7]];
e9db:=eqdbtable[eq[8]];
e10db:=eqdbtable[eq[9]];
preamp:=eqdbtable[eq_preamp];


//signed 28bit

                asm

                push {r0-r10,r12,r14}

                ldr r7,len
                //lsr r7,#1
                ldr r1,bufaddr


p101:           mov r0,#0
                mov r10,#0
                mov r12,#0
                ldr r8,[r1],#4
                sub r8,#0x8000000    //signed  28 bit
                ldr r9,[r1],#4
                sub r9,#0x8000000    //signed  28 bit


//---- One band pass filter #1

                mov r0,r8       //input
                ldr r2,filter1bl
                ldr r3,filter1ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                ldr r6,e1freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter1bl
                str r3,filter1ll

                ldr r14,e1db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                add r10,r2


                mov r0,r9            //input
                ldr r2,filter1br
                ldr r3,filter1lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter1br
                str r3,filter1lr

               // ldr r5,e1db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                add r12,r2



//-----------------    #2

                mov r0,r8       //input
                ldr r2,filter2bl
                ldr r3,filter2ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e2freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter2bl
                str r3,filter2ll

                ldr r14,e2db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                  add r10,r2



                mov r0,r9            //input
                ldr r2,filter2br
                ldr r3,filter2lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter2br
                str r3,filter2lr


             //   ldr r5,e2db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                     add r12,r2



//-----------------    #3

                mov r0,r8       //input
                ldr r2,filter3bl
                ldr r3,filter3ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e3freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter3bl
                str r3,filter3ll

                ldr r14,e3db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                 add r10,r2




                mov r0,r9            //input
                ldr r2,filter3br
                ldr r3,filter3lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter3br
                str r3,filter3lr

             // ldr r14,e3db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                     add r12,r2


//----------------    #4

                mov r0,r8       //input
                ldr r2,filter4bl
                ldr r3,filter4ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e4freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter4bl
                str r3,filter4ll

                    ldr r14,e4db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                   add r10,r2



                mov r0,r9            //input
                ldr r2,filter4br
                ldr r3,filter4lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter4br
                str r3,filter4lr

               // ldr r5,e4db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                add r12,r2



//-----------------    #5

                mov r0,r8       //input
                ldr r2,filter5bl
                ldr r3,filter5ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e5freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter5bl
                str r3,filter5ll

                ldr r14,e5db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                  add r10,r2


                mov r0,r9            //input
                ldr r2,filter5br
                ldr r3,filter5lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter5br
                str r3,filter5lr

             //ldr r5,e5db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                     add r12,r2



//----------------    #6

                mov r0,r8       //input
                ldr r2,filter6bl
                ldr r3,filter6ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e6freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter6bl
                str r3,filter6ll

                ldr r14,e6db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                add r10,r2


                mov r0,r9            //input
                ldr r2,filter6br
                ldr r3,filter6lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter6br
                str r3,filter6lr

              // ldr r5,e6db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22
               add r12,r2


//----------------    #7

                mov r0,r8       //input
                ldr r2,filter7bl
                ldr r3,filter7ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e7freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter7bl
                str r3,filter7ll

                ldr r14,e7db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                  add r10,r2



                mov r0,r9            //input
                ldr r2,filter7br
                ldr r3,filter7lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter7br
                str r3,filter7lr

             //  ldr r5,e7db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22
            add r12,r2


//----------------    #8

                mov r0,r8       //input
                ldr r2,filter8bl
                ldr r3,filter8ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e8freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter8bl
                str r3,filter8ll


                ldr r14,e8db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                  add r10,r2


                mov r0,r9            //input
                ldr r2,filter8br
                ldr r3,filter8lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter8br
                str r3,filter8lr

             //  ldr r5,e8db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

             add r12,r2


//----------------    #9

                mov r0,r8       //input
                ldr r2,filter9bl
                ldr r3,filter9ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e9freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter9bl
                str r3,filter9ll

                ldr r14,e9db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22


                  add r10,r2


                mov r0,r9            //input
                ldr r2,filter9br
                ldr r3,filter9lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter9br
                str r3,filter9lr

              // ldr r5,e9db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22
                         add r12,r2


//----------------    #10

                mov r0,r8       //input
                ldr r2,filter0bl
                ldr r3,filter0ll
                sub r0,r0,r2,asr #1
                sub r0,r0,r3          //r0=input-filterb-filterl (=filterh)
                ldr r6,e10freq
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter0bl
                str r3,filter0ll

                ldr r14,e10db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22

                add r10,r2


                mov r0,r9            //input
                ldr r2,filter0br
                ldr r3,filter0lr
                sub r0,r0,r2,asr #1
                sub r0,r0,r3            //r0=input-filterb-filterl (=filterh)
                smull r4,r5,r0,r6    // result in r5
                add r2,r5            // filter_b:=filter-b+freq*filter_h
                smull r4,r5,r2,r6
                add r3,r5            // filter_l:=filter_l+freq*filter_b
                str r2,filter0br
                str r3,filter0lr

             //   ldr r5,e10db
                smull r2,r5,r2,r14
                lsr r2,#10
                orr r2,r2,r5,lsl #22
                add r12,r2


// now the result is 28 bit signed while I need 28 bit unsigned

                sub r1,#8

                ldr r5,preamp
                lsl r5,#18
                smull r2,r10,r5,r10
                smull r2,r12,r5,r12

                lsl r10,#3
                lsl r12,#3

                cmp r10,#0x8000000
                movge r10,#0x8000000
                subge r10,#1
                cmp r10,#-0x8000000
                movle r10,#-0x8000000
                addle r10,#1

                cmp r12,#0x8000000
                movge r12,#0x8000000
                subge r12,#1
                cmp r12,#-0x8000000
                movle r12,#-0x8000000
                addle r12,#1


                add r10,#0x8000000
                add r12,#0x8000000
                str r10,[r1],#4
                str r12,[r1],#4

                subs r7,#1
                bne p101


                b p999

testfreq:       .long 0x00001000
e1freq:         .long 0x000D6775       //30
e2freq:         .long 0x001ACEE9       //60
e3freq:         .long 0x00359DD3       //120
e4freq:         .long 0x006B3BA7       //250
e5freq:         .long 0x00D6774F       //500
e6freq:         .long 0x01ACEE9F       //1k
e7freq:         .long 0x0359DD3E       //2k
e8freq:         .long 0x06B3BA7C       //4k
e9freq:         .long 0x0D6774F9       //8k
e10freq:        .long 0x1ACEE9F3       //16k

filter1ll:      .long 0
filter1lr:      .long 0
filter1bl:      .long 0
filter1br:      .long 0

filter2ll:      .long 0
filter2lr:      .long 0
filter2bl:      .long 0
filter2br:      .long 0

filter3ll:      .long 0
filter3lr:      .long 0
filter3bl:      .long 0
filter3br:      .long 0

filter4ll:      .long 0
filter4lr:      .long 0
filter4bl:      .long 0
filter4br:      .long 0

filter5ll:      .long 0
filter5lr:      .long 0
filter5bl:      .long 0
filter5br:      .long 0

filter6ll:      .long 0
filter6lr:      .long 0
filter6bl:      .long 0
filter6br:      .long 0

filter7ll:      .long 0
filter7lr:      .long 0
filter7bl:      .long 0
filter7br:      .long 0

filter8ll:      .long 0
filter8lr:      .long 0
filter8bl:      .long 0
filter8br:      .long 0

filter9ll:      .long 0
filter9lr:      .long 0
filter9bl:      .long 0
filter9br:      .long 0

filter0ll:      .long 0
filter0lr:      .long 0
filter0bl:      .long 0
filter0br:      .long 0

resl:           .long 0
resr:           .long 0


p999:            pop {r0-r10,r12,r14}
                end;

end;


procedure oversample1(bufaddr,outbuf,oversample,len:integer);

label p101,p102;

// -- rev 20170126

begin
                 asm
                 push {r0-r6}

                 ldr r5,bufaddr        // init buffers addresses
                 ldr r2,outbuf
                 ldr r3,oversample
                 ldr r0,len             // outer loop counter

 p102:           mov r1,r3              // inner loop counter
                 ldr r4,[r5],#4         // new input value left
                 ldr r6,[r5],#4         // new input value right

             //        asr r4,#2
             //        asr r6,#2

 p101:           str r4,[r2],#4
                 str r6,[r2],#4
                 subs r1,#1
                 bne p101
                 subs r0,#1
                 bne p102

                 pop {r0-r6}
                 end;

//CleanDataCacheRange(outbuf,$10000);
end;

function noiseshaper8a(bufaddr,outbuf,oversample,len:integer):integer;

label p102,p999,i1l,i1r,i2l,i2r;
var len2:integer;
     et2:int64;
// -- rev 20170701

begin
et2:=gettime;
oversample1(bufaddr,outbuf,oversample,len);
len2:=len*oversample;
if equalizer_active then equalizer2(outbuf,len2);


                 asm
                 push {r0-r10,r12,r14}
                 ldr r3,i1l            // init integrators
                 ldr r4,i1r
                 ldr r7,i2l
                 ldr r8,i2r
                 ldr r5,outbuf        // init buffers addresses
                 ldr r2,outbuf

                 ldr r0,len2            // outer loop counter

 p102:           ldr r12,[r5],#4       // new input value left
                 ldr r6,[r5],#4        // new input value right

                 add r3,r6             // inner loop: do oversampling
                 add r4,r12
                 add r7,r3
                 add r8,r4
                 mov r9,r7,asr #20
                 mov r10,r9,lsl #20
                 sub r3,r10
                 sub r7,r10
                 add r9,#1            // kill the negative bug :) :)
                 str r9,[r2],#4
                 mov r9,r8,asr #20
                 mov r10,r9,lsl #20
                 sub r4,r10
                 sub r8,r10
                 add r9,#1
                 str r9,[r2],#4

                 subs r0,#1
                 bne p102

                 str r3,i1l
                 str r4,i1r
                 str r7,i2l
                 str r8,i2r
                 str r2,result

                 b p999

i1l:            .long 0
i1r:            .long 0
i2l:            .long 0
i2r:            .long 0

p999:           pop {r0-r10,r12,r14}
                end;

CleanDataCacheRange(outbuf,$10000);
et:=gettime-et2;
end;


function noiseshaper9(bufaddr,outbuf,oversample,len:integer):integer;

label p101,p102,p999,i1l,i1r,i2l,i2r;

// -- rev 20170621

begin
                 asm
                 push {r0-r10,r12,r14}
                 ldr r3,i1l            // init integerators
                 ldr r4,i1r
                 ldr r7,i2l
                 ldr r8,i2r
                 ldr r5,bufaddr        // init buffers addresses
                 ldr r2,outbuf
                 ldr r14,oversample    // yes, lr used here, I am short of regs :(
                 ldr r0,len            // outer loop counter

 p102:           mov r1,r14            // inner loop counter
                 ldr r6,[r5],#4        // new input value left
                 ldr r12,[r5],#4       // new input value right

 p101:           add r3,r6             // inner loop: do oversampling
                 add r4,r12
                 add r7,r3
                 add r8,r4
                 mov r9,r7,asr #19
                 mov r10,r9,lsl #19
                 sub r3,r10
                 sub r7,r10
                 add r9,#1            // kill the negative bug :) :)
                 str r9,[r2],#4
                 mov r9,r8,asr #19
                 mov r10,r9,lsl #19
                 sub r4,r10
                 sub r8,r10
                 add r9,#1
                 str r9,[r2],#4
                 subs r1,#1
                 bne p101
                 subs r0,#1
                 bne p102

                 str r3,i1l
                 str r4,i1r
                 str r7,i2l
                 str r8,i2r
                 str r2,result

                 b p999

i1l:            .long 0
i1r:            .long 0
i2l:            .long 0
i2r:            .long 0

p999:           pop {r0-r10,r12,r14}
                end;

CleanDataCacheRange(outbuf,$10000);
end;


function noiseshaper8(bufaddr,outbuf,oversample,len:integer):integer;

label p101,p102,p999,i1l,i1r,i2l,i2r;

// -- rev 20170126

begin
                 asm
                 push {r0-r10,r12,r14}
                 ldr r3,i1l            // init integrators
                 ldr r4,i1r
                 ldr r7,i2l
                 ldr r8,i2r
                 ldr r5,bufaddr        // init buffers addresses
                 ldr r2,outbuf
                 ldr r14,oversample    // yes, lr used here, I am short of regs :(
                 ldr r0,len            // outer loop counter

 p102:           mov r1,r14            // inner loop counter
                 ldr r12,[r5],#4       // new input value left
                 ldr r6,[r5],#4        // new input value right

 p101:           add r3,r6             // inner loop: do oversampling
                 add r4,r12
                 add r7,r3
                 add r8,r4
                 mov r9,r7,asr #20
                 mov r10,r9,lsl #20
                 sub r3,r10
                 sub r7,r10
                 add r9,#1            // kill the negative bug :) :)
                 str r9,[r2],#4
                 mov r9,r8,asr #20
                 mov r10,r9,lsl #20
                 sub r4,r10
                 sub r8,r10
                 add r9,#1
                 str r9,[r2],#4
                 subs r1,#1
                 bne p101
                 subs r0,#1
                 bne p102

                 str r3,i1l
                 str r4,i1r
                 str r7,i2l
                 str r8,i2r
                 str r2,result

                 b p999

i1l:            .long 0
i1r:            .long 0
i2l:            .long 0
i2r:            .long 0

p999:           pop {r0-r10,r12,r14}
                end;

CleanDataCacheRange(outbuf,$10000);
end;


// Audio thread
// After the audio is opened it calls audiocallback when needed


constructor TAudioThread.Create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;



procedure TAudioThread.Execute;

var
    i:integer;
    ns_size:integer;
    vl,vr:integer;


begin
AudioOn:=1;
ThreadSetCPU(ThreadGetCurrent,CPU_ID_1);
ThreadSetPriority(ThreadGetCurrent,7);
threadsleep(1);
repeat
  repeat threadsleep(1) until (dma_cs and 2) <>0 ;
  if balance<128 then begin vl:=(volume*balance) div 128; vr:=volume; end
  else if (balance>128) and (balance<=256) then begin vr:=(volume*(256-balance)) div 128; vl:=volume; end
  else begin vl:=volume; vr:=volume; end;
  working:=1;
  nc:=dma_nextcb;
  if pauseA>0 then  // clean the buffers
    begin
    if nc=nocache+ctrl1_adr then for i:=0 to 16383 do dmabuf1_ptr[i]:=CurrentAudioSpec.range div 2;
    if nc=nocache+ctrl2_adr then for i:=0 to 16383 do dmabuf2_ptr[i]:=CurrentAudioSpec.range div 2;
    if nc=nocache+ctrl1_adr then CleanDataCacheRange(dmabuf1_adr,$10000);
    if nc=nocache+ctrl2_adr then CleanDataCacheRange(dmabuf2_adr,$10000);
    end
  else
    begin

    // if not pause then we should call audiocallback to fill the buffer

    if CurrentAudioSpec.callback<>nil then CurrentAudioSpec.callback(CurrentAudioSpec.userdata, samplebuffer_ptr, CurrentAudioSpec.size);

    // the buffer has to be converted to 2 chn 32bit integer

    if CurrentAudioSpec.channels=2 then // stereo
      begin
      case CurrentAudioSpec.format of
        AUDIO_U8:  for i:=0 to CurrentAudioSpec.samples-1 do begin samplebuffer_32_ptr[2*i]:= vl*256*samplebuffer_ptr_b[2*i]; samplebuffer_32_ptr[2*i+1]:= vr*256*samplebuffer_ptr_b[2*i+1]; end;
        AUDIO_S16: for i:=0 to CurrentAudioSpec.samples-1 do begin samplebuffer_32_ptr[2*i]:= vl*samplebuffer_ptr_si[2*i]+$8000000; samplebuffer_32_ptr[2*i+1]:= vr*samplebuffer_ptr_si[2*i+1]+$8000000; end;
        AUDIO_F32: for i:=0 to CurrentAudioSpec.samples-1 do begin samplebuffer_32_ptr[2*i]:= round(vl*32768*samplebuffer_ptr_f[2*i])+$8000000; samplebuffer_32_ptr[2*i+1]:= round(vr*32768*samplebuffer_ptr_f[2*i+1])+$8000000; end;
        end;
      end
    else
      begin
      case CurrentAudioSpec.format of
        AUDIO_U8:  for i:=0 to CurrentAudioSpec.samples-1 do begin samplebuffer_32_ptr[2*i]:= vl*256*samplebuffer_ptr_b[i]; samplebuffer_32_ptr[2*i+1]:= vr*256*samplebuffer_ptr_b[i];; end;
        AUDIO_S16: for i:=0 to CurrentAudioSpec.samples-1 do begin samplebuffer_32_ptr[2*i]:= vl*samplebuffer_ptr_si[i]+$8000000; samplebuffer_32_ptr[2*i+1]:= vr*samplebuffer_ptr_si[i]+$8000000; end;
        AUDIO_F32: for i:=0 to CurrentAudioSpec.samples-1 do begin samplebuffer_32_ptr[2*i]:= round(vl*32768*samplebuffer_ptr_f[i])+$8000000; samplebuffer_32_ptr[2*i+1]:= round(vr*32768*samplebuffer_ptr_f[i])+$8000000; end;
        end;
      end;
    if nc=nocache+ctrl1_adr then noiseshaper8a (samplebuffer_32_adr,dmabuf1_adr,CurrentAudioSpec.oversample,CurrentAudioSpec.samples)
    else noiseshaper8a (samplebuffer_32_adr,dmabuf2_adr,CurrentAudioSpec.oversample,CurrentAudioSpec.samples);
    if nc=nocache+ctrl1_adr then CleanDataCacheRange(dmabuf1_adr,$10000) else CleanDataCacheRange(dmabuf2_adr,$10000);
    end;
  dma_cs:=$00FF0003;
  working:=0;
  until terminated;
AudioOn:=0;
end;

function  SA_GetCurrentFreq:integer;

begin
result:=CurrentAudioSpec.freq;
end;

function  SA_GetCurrentRange:integer;

begin
result:=CurrentAudioSpec.range;
end;

procedure  SA_SetEQ(band,db:integer);

begin
if band<0 then exit;
if band>9 then exit;
if db>12 then db:=12;
if db<-12 then db:=-12;
eq[band]:=db;
end;

procedure  SA_SetEQpreamp(db:integer);

begin
if db>12 then db:=12;
if db<-12 then db:=-12;
eq_preamp:=db;
end;

end.



