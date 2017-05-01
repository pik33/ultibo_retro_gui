unit xmp;

{$mode objfpc}{$H+}

interface

const XMP_VERSION =             '4.4.1';
      XMP_VERCODE =             $040401;
      XMP_VER_MAJOR =           4;
      XMP_VER_MINOR =           4;
      XMP_VER_RELEASE =         1;
      XMP_NAME_SIZE=		64;	//* Size of module name and type */

      XMP_KEY_OFF=		$81;	//* Note number for key off event */
      XMP_KEY_CUT=		$82;	//* Note number for key cut event */
      XMP_KEY_FADE=		$83;	//* Note number for fade event */

//* mixer parameter macros */

//* sample format flags */
     XMP_FORMAT_8BIT=		1; //(1 << 0) /* Mix to 8-bit instead of 16 */
     XMP_FORMAT_UNSIGNED=	2; //(1 << 1) /* Mix to unsigned samples */
     XMP_FORMAT_MONO=		4; // (1 << 2) /* Mix to mono instead of stereo */

//* player parameters */

     XMP_PLAYER_AMP=		0;	//* Amplification factor */
     XMP_PLAYER_MIX=		1;	//* Stereo mixing */
     XMP_PLAYER_INTERP=	        2;	//* Interpolation type */
     XMP_PLAYER_DSP=		3;	//* DSP effect flags */
     XMP_PLAYER_FLAGS=	        4;	//* Player flags */
     XMP_PLAYER_CFLAGS=	        5;	//* Player flags for current module */
     XMP_PLAYER_SMPCTL=	        6;	//* Sample control flags */
     XMP_PLAYER_VOLUME=	        7;	//* Player module volume */
     XMP_PLAYER_STATE=	        8;	//* Internal player state (read only) */
     XMP_PLAYER_SMIX_VOLUME=	9;	//* SMIX volume */
     XMP_PLAYER_DEFPAN=	        10;	//* Default pan setting */
     XMP_PLAYER_MODE= 	        11;	//* Player personality */
     XMP_PLAYER_MIXER_TYPE=	12;	//* Current mixer (read only) */
     XMP_PLAYER_VOICES=	        13;	//* Maximum number of mixer voices */

//* interpolation types */

     XMP_INTERP_NEAREST=	0;	//* Nearest neighbor */
     XMP_INTERP_LINEAR=	        1;	//* Linear (default) */
     XMP_INTERP_SPLINE=	        2;	//* Cubic spline */

//* dsp effect types */

     XMP_DSP_LOWPASS=		1;      //(1 << 0) /* Lowpass filter effect */
     XMP_DSP_ALL=		1;      //(XMP_DSP_LOWPASS)

//* player state */

     XMP_STATE_UNLOADED=	0;	//* Context created */
     XMP_STATE_LOADED=	        1;	//* Module loaded */
     XMP_STATE_PLAYING=	        2;	//* Module playing */

//* player flags */

     XMP_FLAGS_VBLANK=	        1;      //(1 << 0) /* Use vblank timing */
     XMP_FLAGS_FX9BUG=	        2;      //(1 << 1) /* Emulate FX9 bug */
     XMP_FLAGS_FIXLOOP=	        4;      //(1 << 2) /* Emulate sample loop bug */
     XMP_FLAGS_A500=		8;      //(1 << 3) /* Use Paula mixer in Amiga modules */

//* player modes */

     XMP_MODE_AUTO=		0;	//* Autodetect mode (default) */
     XMP_MODE_MOD=		1;	//* Play as a generic MOD player */
     XMP_MODE_NOISETRACKER=	2;	//* Play using Noisetracker quirks */
     XMP_MODE_PROTRACKER=	3;	//* Play using Protracker quirks */
     XMP_MODE_S3M=		4;	//* Play as a generic S3M player */
     XMP_MODE_ST3=		5;	//* Play using ST3 bug emulation */
     XMP_MODE_ST3GUS=		6;	//* Play using ST3+GUS quirks */
     XMP_MODE_XM=		7;	//* Play as a generic XM player */
     XMP_MODE_FT2=		8;	//* Play using FT2 bug emulation */
     XMP_MODE_IT=		9;	//* Play using IT quirks */
     XMP_MODE_ITSMP=		10;	//* Play using IT sample mode quirks */

//* mixer types */

     XMP_MIXER_STANDARD=        0;      //* Standard mixer */
     XMP_MIXER_A500=		1;	//* Amiga 500 */
     XMP_MIXER_A500F=		2;	//* Amiga 500 with led filter */

//* sample flags */

     XMP_SMPCTL_SKIP=		1;       //* Don't load samples */

//* limits */

    XMP_MAX_KEYS=		121;	//* Number of valid keys */
    XMP_MAX_ENV_POINTS=	        32;     //* Max number of envelope points */
    XMP_MAX_MOD_LENGTH=	        256;    //* Max number of patterns in module */
    XMP_MAX_CHANNELS=	        64;     //* Max number of channels in module */
    XMP_MAX_SRATE=		49152;	//* max sampling rate (Hz) */
    XMP_MIN_SRATE=		4000;	//* min sampling rate (Hz) */
    XMP_MIN_BPM=		20;     //* min BPM */

//* frame rate = (50 * bpm / 125) Hz */
//* frame size = (sampling rate * channels * size) / frame rate */

     XMP_MAX_FRAMESIZE=        5*XMP_MAX_SRATE*2 div XMP_MIN_BPM;

//* error codes */

     XMP_END=			1;
     XMP_ERROR_INTERNAL=	2;	//* Internal error */
     XMP_ERROR_FORMAT=	        3;	//* Unsupported module format */
     XMP_ERROR_LOAD=		4;	//* Error loading file */
     XMP_ERROR_DEPACK=	        5;	//* Error depacking file */
     XMP_ERROR_SYSTEM=	        6;	//* System error */
     XMP_ERROR_INVALID=	        7;	//* Invalid parameter */
     XMP_ERROR_STATE=		8;	//* Invalid player state */

     XMP_INST_NNA_CUT=	        $00;
     XMP_INST_NNA_CONT=	        $01;
     XMP_INST_NNA_OFF=	        $02;
     XMP_INST_NNA_FADE=	        $03;

     XMP_INST_DCT_OFF=	        $00;
     XMP_INST_DCT_NOTE=	        $01;
     XMP_INST_DCT_SMP=	        $02;
     XMP_INST_DCT_INST=	        $03;

     XMP_INST_DCA_CUT=	        XMP_INST_NNA_CUT;
     XMP_INST_DCA_OFF=	        XMP_INST_NNA_OFF;
     XMP_INST_DCA_FADE=	        XMP_INST_NNA_FADE;

     XMP_CHANNEL_SYNTH=	        1;     //(1 << 0)  /* Channel is synthesized */
     XMP_CHANNEL_MUTED=         2;     //(1 << 1)  /* Channel is muted */
     XMP_CHANNEL_SPLIT=	        4;     //(1 << 2)  /* Split Amiga channel in bits 5-4 */
     XMP_CHANNEL_SURROUND=	16;    //(1 << 4)  /* Surround channel */

     XMP_ENVELOPE_ON=		1;     //(1 << 0)  /* Envelope is enabled */
     XMP_ENVELOPE_SUS=	        2;     //(1 << 1)  /* Envelope has sustain point */
     XMP_ENVELOPE_LOOP=	        4;     //(1 << 2)  /* Envelope has loop */
     XMP_ENVELOPE_FLT=	        8;     //(1 << 3)  /* Envelope is used for filter */
     XMP_ENVELOPE_SLOOP=        16;    //(1 << 4)  /* Envelope has sustain loop */
     XMP_ENVELOPE_CARRY=        32;    //(1 << 5)  /* Don't reset envelope position */
     XMP_SAMPLE_16BIT=	        1;     //(1 << 0)  /* 16bit sample */


     XMP_SAMPLE_LOOP=		2;     //(1 << 1)  /* Sample is looped */
     XMP_SAMPLE_LOOP_BIDIR=	4;     //(1 << 2)  /* Bidirectional sample loop */
     XMP_SAMPLE_LOOP_REVERSE=	8;     //(1 << 3)  /* Backwards sample loop */
     XMP_SAMPLE_LOOP_FULL=	16;    //(1 << 4)  /* Play full sample before looping */
     XMP_SAMPLE_SLOOP=	        32;    //(1 << 5)  /* Sample has sustain loop */
     XMP_SAMPLE_SYNTH=	        32768; //(1 << 15) /* Data contains synth patch */

type Pxmp_channel=^Txmp_channel;
     Txmp_channel=record
                 pan:integer;           //* Channel pan (0x80 is center) */
	         vol:integer;		//* Channel volume */
               	 flg:integer	        //* Channel flags */
                 end;

var xmp_channel:Txmp_channel;

type Txmp_pattern=record
                 rows:integer;		            //* Number of rows */
	         index:array[0..0] of integer 	    //* Track index */
                 end;

var xmp_pattern:Txmp_pattern;

type Pxmp_event=^Txmp_event;

     Txmp_event=record
	        note:byte;		//* Note number (0 means no note) */
	        ins:byte;		//* Patch number */
                vol:byte;		//* Volume (0 to basevol) */
                fxt:byte;		//* Effect type */
                fxp:byte;		//* Effect parameter */
                f2t:byte;		//* Secondary effect type */
                f2p:byte;		//* Secondary effect parameter */
                _flag:byte		//* Internal (reserved) flags */
                end;

var xmp_event:Txmp_event;

type Txmp_track=record
                rows:integer;		 	//* Number of rows */
	        event:array[0..0] of Txmp_event//* Event data */
               end;

var xmp_track:Txmp_track;

type Txmp_envelope=record

	flg:integer;		        //* Flags */
	npt:integer;			//* Number of envelope points */
	scl:integer;			//* Envelope scaling */
	sus:integer;			//* Sustain start point */
	sue:integer;			//* Sustain end point */
	lps:integer;			//* Loop start point */
	lpe:integer;			//* Loop end point */
	data:array[0..XMP_MAX_ENV_POINTS * 2-1] of smallint
        end;

var xmp_envelope:Txmp_envelope;

type Tmap=record
        ins:byte;
        xpo:shortint
        end;

type Pxmp_subinstrument=^Txmp_subinstrument;

      Txmp_subinstrument=record
     		vol:integer;		//* Default volume */
     		gvl:integer;		//* Global volume */
     		pan:integer;		//* Pan */
     		xpo:integer;		//* Transpose */
     		fin:integer;		//* Finetune */
     		vwf:integer;		//* Vibrato waveform */
     		vde:integer;		//* Vibrato depth */
     		vra:integer;		//* Vibrato rate */
     		vsw:integer;		//* Vibrato sweep */
     		rvv:integer;		//* Random volume/pan variation (IT) */
     		sid:integer;		//* Sample number */
     		nna:integer;		//* New note action */
                dct:integer;		//* Duplicate check type */
     		dca:integer;		//* Duplicate check action */
     		ifc:integer;		//* Initial filter cutoff */
     		ifr:integer		//* Initial filter resonance */
                end;

type Pxmp_instrument=^Txmp_instrument;
     Txmp_instrument=record
	name:array[0..31] of char;		//* Instrument name */
	vol:integer;			//* Instrument volume */
	nsm:integer;			//* Number of samples */
	rls:integer;			//* Release (fadeout) */
	aei:Txmp_envelope;	                //* Amplitude envelope info */
	pei:Txmp_envelope;	                //* Pan envelope info */
	fei:Txmp_envelope;                      //* Frequency envelope info */

        map:array[0..XMP_MAX_KEYS-1] of Tmap;
        sub:Pxmp_subinstrument;
        extra:pointer;
end;

var xmp_instrument:Txmp_instrument;

type Pxmp_sample=^Txmp_sample;
     Txmp_sample=record

	name:array[0..31] of char;		//* Sample name */
	len:integer;			        //* Sample length */
	lps:integer;			        //* Loop start */
	lpe:integer;			        //* Loop end */

	flg:integer;			        //* Flags */
	data:Pbyte		                //* Sample data */
        end;

var xmp_sample:^Txmp_sample;

type Pxmp_sequence=^Txmp_sequence;
     Txmp_sequence=record
        entry_point:integer;
	duration:integer
        end;

var xmp_sequence:Txmp_sequence;

type Pxmp_module=^Txmp_module;
     Txmp_module=record
	name:array[0..XMP_NAME_SIZE-1] of char;	    //* Module title */
	_type:array[0..XMP_NAME_SIZE-1] of char;    //* Module format */
	pat:integer;			//* Number of patterns */
	trk:integer;			//* Number of tracks */
	chn:integer;			//* Tracks per pattern */
	ins:integer;			//* Number of instruments */
	smp:integer;			//* Number of samples */
	spd:integer;			//* Initial speed */
	bpm:integer;			//* Initial BPM */
	len:integer;			//* Module length in patterns */
	rst:integer;			//* Restart position */
	gvl:integer;			//* Global volume */

	xxp:pointer;                    //struct xmp_pattern **xxp;	//* Patterns */
	xxt:pointer;                     //struct xmp_track **xxt;		//* Tracks */
	xxi:Pxmp_instrument;             // *xxi;	//* Instruments */
	xxs:Pxmp_sample;                //struct xmp_sample *xxs;		//* Samples */
	xxc:array[0..XMP_MAX_CHANNELS-1] of Pxmp_channel; //* Channel info */
	xxo:array[0..XMP_MAX_MOD_LENGTH-1] of shortint	//* Orders */
        end;

var xmp_module:Txmp_module;

type Pxmp_test_info=^Txmp_test_info;
     Txmp_test_info=record
	name:array[0..XMP_NAME_SIZE-1] of char;	//* Module title */
	 _type:array[0..XMP_NAME_SIZE-1] of char	//* Module format */
        end;

type Pxmp_module_info=^Txmp_module_info;
     Txmp_module_info=record
        md5:array[0..15] of byte;		//* MD5 message digest */
	vol_base:integer;			//* Volume scale */
	module:Pxmp_module;	   	        //* Pointer to module data */
	comment:PChar;			        //* Comment text, if any */
	num_sequences:integer;		        //* Number of valid sequences */
	seq_data:Pxmp_sequence	                //* Pointer to sequence data */
        end;

type Txmp_channel_info=record            //* Current channel information */
     	period:cardinal;	         //* Sample period (* 4096) */
     	position:cardinal;	         //* Sample position */
     	pitchbend:smallint;	         //* Linear bend from base note*/
     	note:byte;	                 //* Current base note number */
     	instrument:byte;                 //* Current instrument number */
     	sample:byte;	                 //* Current sample number */
     	volume:byte;	                 //* Current volume */
     	pan:byte;	                 //* Current stereo pan */
     	reserved:byte;	                 //* Reserved */
     	event:Txmp_event	         //* Current track event */
        end;

type Pxmp_frame_info=^Txmp_frame_info;
     Txmp_frame_info=record 		//* Current frame information */
	pos:integer;			//* Current position */
	pattern:integer;		//* Current pattern */
	row:integer;			//* Current row in pattern */
	num_rows:integer;		//* Number of rows in current pattern */
	frame:integer;			//* Current frame */
	speed:integer;			//* Current replay speed */
	bpm:integer;			//* Current bpm */
	time:integer;			//* Current module time in ms */
	total_time:integer;		//* Estimated replay time in ms*/
	frame_time:integer;		//* Frame replay time in us */
	buffer:pointer;			//* Pointer to sound buffer */
	buffer_size:integer;		//* Used buffer size */
	total_size:integer;		//* Total buffer size */
	volume:integer;			//* Current master volume */
	loop_count:integer;		//* Loop counter */
	virt_channels:integer;		//* Number of virtual channels */
	virt_used:integer;		//* Used virtual channels */
	sequence:integer;		//* Current sequence */
	channel_info:array[0..XMP_MAX_CHANNELS] of Txmp_channel_info //* Current channel information */
        end;

type Txmp_context=PChar;
var xmp_context:TXmp_context=nil;


     {$linklib xmp-lite}
     {$linklib m}

//EXPORT extern const char *xmp_version;
//EXPORT extern const unsigned int xmp_vercode;

function xmp_create_context:Txmp_context; cdecl; external 'libxmp-lite' name 'xmp_create_context';
procedure xmp_free_context(xmp_context:Txmp_context); cdecl; external 'libxmp-lite' name 'xmp_free_context';
function xmp_test_module(a:Pchar;b:Pxmp_test_info):integer; cdecl; external 'libxmp-lite' name 'xmp_test_module';
function xmp_load_module(a:Txmp_context; b:Pchar):integer; cdecl; external 'libxmp-lite' name 'xmp_load_module';
procedure xmp_scan_module(a:Txmp_context);cdecl; external 'libxmp-lite' name 'xmp_scan_module';
procedure xmp_release_module(a:Txmp_context);cdecl; external 'libxmp-lite' name  'xmp_release_module';
function xmp_start_player(a:Txmp_context;b,c:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_start_player';
function xmp_play_frame(a:Txmp_context):integer; cdecl; external 'libxmp-lite' name 'xmp_play_frame';
function xmp_play_buffer(a:Txmp_context; b:pointer; c,d:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_play_buffer';
procedure xmp_get_frame_info(a:Txmp_context; b:Pxmp_frame_info); cdecl; external 'libxmp-lite' name 'xmp_get_frame_info';
procedure xmp_end_player(a:Txmp_context); cdecl; external 'libxmp-lite' name 'xmp_end_player';
procedure xmp_inject_event(a:Txmp_context; b:integer;c:Pxmp_event); cdecl; external 'libxmp-lite' name 'xmp_inject_event';
procedure xmp_get_module_info (a:Txmp_context;b:Pxmp_module_info); cdecl; external 'libxmp-lite' name 'xmp_get_module_info';
function xmp_get_format_list:pointer; cdecl; external 'libxmp-lite' name 'xmp_get_format_list';
function xmp_next_position(a:Txmp_context):integer; cdecl; external 'libxmp-lite' name 'xmp_next_position';
function xmp_prev_position(a:Txmp_context):integer; cdecl; external 'libxmp-lite' name 'xmp_prev_position';
function xmp_set_position(a:Txmp_context;b:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_set_position';
procedure xmp_stop_module(a:Txmp_context); cdecl; external 'libxmp-lite' name 'xmp_stop_module';
procedure xmp_restart_module(a:Txmp_context);cdecl; external 'libxmp-lite' name 'xmp_restart_module';
function xmp_seek_time(a:Txmp_context;b:integer):integer cdecl; external 'libxmp-lite' name 'xmp_seek_time';
function xmp_channel_mute(a:Txmp_context;b,c:integer):integer;cdecl; external 'libxmp-lite' name 'xmp_channel_mute';
function xmp_channel_vol(a:Txmp_context;b,c:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_channel_vol';
function xmp_set_player(a:Txmp_context;b,c:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_set_player';
function xmp_get_player(a:Txmp_context;b:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_get_player';
function xmp_set_instrument_path(a:Txmp_context; b:PChar):integer; cdecl; external 'libxmp-lite' name 'xmp_set_instrument_path';
function xmp_load_module_from_memory(a:Txmp_context; b:pointer; c:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_load_module_from_memory';
function xmp_load_module_from_file(a:Txmp_context; b:pointer; c:integer):integer; cdecl; external 'libxmp-lite' name 'xmp_load_module_from_file';

//* External sample mixer API */  NOT NEEDED NOW -------------------------------
//EXPORT int         xmp_start_smix       (xmp_context, int, int);
//EXPORT void        xmp_end_smix         (xmp_context);
//EXPORT int         xmp_smix_play_instrument(xmp_context, int, int, int, int);
//EXPORT int         xmp_smix_play_sample (xmp_context, int, int, int, int);
//EXPORT int         xmp_smix_channel_pan (xmp_context, int, int);
//EXPORT int         xmp_smix_load_sample (xmp_context, int, char *);
//EXPORT int         xmp_smix_release_sample (xmp_context, int);
//------------------------------------------------------------------------------

implementation

end.

