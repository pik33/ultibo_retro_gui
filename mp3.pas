unit mp3;

{$mode objfpc}{$H+}

// This is the Pascal wrapper unit for media decoding C libraries
// Piotr Kardasz, pik33@o2.pl, 20170208


interface

uses syscalls;


// -------- mad.h ------------------------------

const MAD_BUFFER_GUARD=8;
      MAD_BUFFER_MDLEN=(511 + 2048 + MAD_BUFFER_GUARD);

type mad_bitptr=record
                bajt:PByte;
                cache:word;
                left:word;
                end;

type mad_stream=record

                buffer: PByte;		//* input bitstream buffer */
                bufend: PByte;		//* end of buffer */
                skiplen:cardinal;	//* bytes to skip before next frame */

                sync:integer;		//* stream sync found */
                freerate:cardinal;      //* free bitrate (fixed) */

                this_frame:PByte;	//* start of current frame */
                next_frame:PByte;	//* start of next frame */
                ptr:mad_bitptr;		//* current processing bit pointer */

                anc_ptr:mad_bitptr;	//* ancillary bits pointer */
                anc_bitlen:cardinal;	//* number of ancillary bits */

                main_data: pointer;     //?? or array???
                                        // unsigned char (*main_data)[MAD_BUFFER_MDLEN];

					//* Layer III main_data() */
                md_len:cardinal;       //* bytes in main_data */

                options:integer;        //* decoding options (see below) */
                error:integer;		//* error code (see above) */
                end;

type mad_pcm = record
               samplerate:cardinal;		//* sampling frequency (Hz) */
               channels:word;		        //* number of channels */
               length:word;		        //* number of samples per channel */
               samples:array[0..1,0..1151] of integer;		//* PCM output samples [ch][sample] */
               end;

type mad_synth=record

                filter:array[0..1,0..1,0..1,0..15,0..7] of integer;  // [2][2][2][16][8];	/* polyphase filterbank outputs */
                                                                    //* [ch][eo][peo][s][v] */

                phase:cardinal;			//* current processing phase */
                pcm:mad_pcm;			//* PCM output */
                end;

type mad_timer_t=record
                 seconds:integer;		//* whole seconds */
                 fraction:cardinal;	        //* 1/MAD_TIMER_RESOLUTION seconds */
                 end;


type mad_header =record
                 layer:cardinal;		//* audio layer (1, 2, or 3) */
                 mode:cardinal;			//* channel mode (see above) */
                 mode_extension:integer;	//* additional mode info */
                 emphasis:cardinal;		//* de-emphasis to use (see above) */

                 bitrate:cardinal;		//* stream bitrate (bps) */
                 samplerate:cardinal;		//* sampling frequency (Hz) */

                 crc_check:word;		//* frame CRC accumulator */
                 crc_target:word;		//* final target CRC checksum */

                 flags:integer;			//* flags (see below) */
                 private_bits:integer;		//* private bits (see below) */

                 duration:mad_timer_t;		// audio playing time of frame */
                 end;


type mad_frame=record
               header: mad_header; 	//* MPEG audio header */

               options:integer;		//* decoding options (from stream) */

               sbsample:array[0..1,0..35,0..32] of integer;	//* synthesis subband filter samples */
               overlap:pointer;
                                         // mad_fixed_t (*overlap)[2][32][18];	/* Layer III block overlap data */
               end;

{$linklib mad}
{$linklib m}


procedure mad_stream_init(pmad_stream:pointer); cdecl; external 'libmad' name   'mad_stream_init';
procedure mad_synth_init(pmad_synth:pointer); cdecl; external 'libmad' name  'mad_synth_init';
procedure mad_frame_init(pmad_frame:pointer); cdecl; external 'libmad' name  'mad_frame_init';
function mad_frame_decode(pmad_frame:pointer; mad_stream:pointer):integer; cdecl; external 'libmad' name  'mad_frame_decode';
procedure mad_synth_frame(pmad_synth, pmad_frame:pointer); cdecl; external 'libmad' name  'mad_synth_frame';
procedure mad_stream_buffer(pmad_stream, pinput_stream:pointer; size:integer);  cdecl; external 'libmad' name  'mad_stream_buffer';

var test_mad_stream: mad_stream;
    test_mad_frame: mad_frame;
    test_mad_synth: mad_synth;

implementation

end.
