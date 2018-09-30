unit uOMX;

{$mode delphi}{$H+}
(*
 * Copyright (c) 2008 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject
 * to the following conditions:
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 *)

interface

uses
  Classes, SysUtils, VC4;

const
  OMX_MAX_STRINGNAME_SIZE                  = 128;
  OMX_CONFIG_IMAGEFILTERPARAMS_MAXPARAMS   = 6;
  OMX_BRCM_MAXIOPERFBANDS                  = 10;
  OMX_BRCM_MAXANNOTATETEXTLEN              = 256;
  OMX_CONFIG_FLASHINFOTYPE_NAME_LEN        = 16;
  OMX_PARAM_CAMERARMITYPE_RMINAME_LEN      = 16;
  OMX_CONFIG_CAMERAINFOTYPE_NAME_LEN       = 16;
  OMX_CONFIG_CAMERAINFOTYPE_SERIALNUM_LEN  = 20;
  OMX_CONFIG_CAMERAINFOTYPE_EPROMVER_LEN   = 8;

  OMX_IndexVendorStartUnused               = $7F000000;

  OMX_BUFFERFLAG_EOS                       = $00000001;
  OMX_BUFFERFLAG_STARTTIME                 = $00000002;
  OMX_BUFFERFLAG_DECODEONLY                = $00000004;
  OMX_BUFFERFLAG_DATACORRUPT               = $00000008;
  OMX_BUFFERFLAG_ENDOFFRAME                = $00000010;
  OMX_BUFFERFLAG_SYNCFRAME                 = $00000020;
  OMX_BUFFERFLAG_EXTRADATA                 = $00000040;
  OMX_BUFFERFLAG_CODECCONFIG               = $00000080;

  OMX_BUFFERFLAG_TIME_UNKNOWN              = $00000100;
  OMX_BUFFERFLAG_CAPTURE_PREVIEW           = $00000200;
  OMX_BUFFERFLAG_ENDOFNAL                  = $00000400;
  OMX_BUFFERFLAG_FRAGMENTLIST              = $00000800;
  OMX_BUFFERFLAG_DISCONTINUITY             = $00001000;
  OMX_BUFFERFLAG_CODECSIDEINFO             = $00002000;
  OMX_BUFFERFLAG_TIME_IS_DTS               = $000004000;
  OMX_BUFFERFLAG_INTERLACED                = $000010000;
  OMX_BUFFERFLAG_TOP_FIELD_FIRST           = $000020000;

  OMX_PortDomainAudio                      = 0;
  OMX_PortDomainVideo                      = 1;
  OMX_PortDomainImage                      = 2;
  OMX_PortDomainOther                      = 3;
  OMX_PortDomainKhronosExtensions          = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_PortDomainVendorStartUnused          = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_PortDomainMax                        = $7ffffff;

  OMX_FALSE                                = LongBool (false);
  OMX_TRUE                                 = LongBool (true);

  OMX_ALL                                  = $FFFFFFFF;

  OMX_NumericalDataSigned                  = 0;          (* signed data *)
  OMX_NumericalDataUnsigned                = 1;          (* unsigned data *)
  OMX_NumercialDataMax                     = $7FFFFFFF;

  OMX_EndianBig                            = 0;          (* big endian *)
  OMX_EndianLittle                         = 1;          (* little endian *)
  OMX_EndianMax                            = $7FFFFFFF;

  OMX_VERSION_MAJOR                        = 1;
  OMX_VERSION_MINOR                        = 1;
  OMX_VERSION_REVISION                     = 2;
  OMX_VERSION_STEP                         = 0;
  OMX_VERSION                              = (OMX_VERSION_STEP shl 24) or (OMX_VERSION_REVISION shl 16) or
                                             (OMX_VERSION_MINOR shl 8) or OMX_VERSION_MAJOR;

  OMX_BufferSupplyUnspecified              = 0;          (* port supplying the buffers is unspecified, or don't care *)
  OMX_BufferSupplyInput                    = 1;          (* input port supplies the buffers *)
  OMX_BufferSupplyOutput                   = 2;          (* output port supplies the buffers *)
  OMX_BufferSupplyKhronosExtensions        = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_BufferSupplyVendorStartUnused        = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_BufferSupplyMax                      = $7FFFFFFF;

  OMX_ErrorNone                            = 0;
  OMX_ErrorInsufficientResources           = $80001000;  (* There were insufficient resources to perform the requested operation *)
  OMX_ErrorUndefined                       = $80001001;  (* There was an error, but the cause of the error could not be determined *)
  OMX_ErrorInvalidComponentName            = $80001002;  (* The component name string was not valid *)
  OMX_ErrorComponentNotFound               = $80001003;  (* No component with the specified name string was found *)
  OMX_ErrorInvalidComponent                = $80001004;  (* The component specified did not have a "OMX_ComponentInit" or
                                                            "OMX_ComponentDeInit entry point *)
  OMX_ErrorBadParameter                    = $80001005;  (* One or more parameters were not valid *)
  OMX_ErrorNotImplemented                  = $80001006;  (* The requested function is not implemented *)
  OMX_ErrorUnderflow                       = $80001007;  (* The buffer was emptied before the next buffer was ready *)
  OMX_ErrorOverflow                        = $80001008;  (* The buffer was not available when it was needed *)
  OMX_ErrorHardware                        = $80001009;  (* The hardware failed to respond as expected *)
  OMX_ErrorInvalidState                    = $8000100A;  (* The component is in the state OMX_StateInvalid *)
  OMX_ErrorStreamCorrupt                   = $8000100B;  (* Stream is found to be corrupt *)
  OMX_ErrorPortsNotCompatible              = $8000100C;  (* Ports being connected are not compatible *)
  OMX_ErrorResourcesLost                   = $8000100D;  (* Resources allocated to an idle component have been
                                                            lost resulting in the component returning to the loaded state *)
  OMX_ErrorNoMore                          = $8000100E;  (* No more indicies can be enumerated *)
  OMX_ErrorVersionMismatch                 = $8000100F;  (* The component detected a version mismatch *)
  OMX_ErrorNotReady                        = $80001010;  (* The component is not ready to return data at this time *)
  OMX_ErrorTimeout                         = $80001011;  (* There was a timeout that occurred *)
  OMX_ErrorSameState                       = $80001012;  (* This error occurs when trying to transition into the state you are already in *)
  OMX_ErrorResourcesPreempted              = $80001013;  (* Resources allocated to an executing or paused component have been
                                                            preempted, causing the component to return to the idle state *)
  OMX_ErrorPortUnresponsiveDuringAllocation = $80001014; (* A non-supplier port sends this error to the IL client (via the EventHandler callback)
                                                            during the allocation of buffers (on a transition from the LOADED to the IDLE state or
                                                            on a port restart) when it deems that it has waited an unusually long time for the supplier
                                                            to send it an allocated buffer via a UseBuffer call. *)
  OMX_ErrorPortUnresponsiveDuringDeallocation = $80001015; (* A non-supplier port sends this error to the IL client (via the EventHandler callback)
                                                              during the deallocation of buffers (on a transition from the IDLE to LOADED state or
                                                              on a port stop) when it deems that it has waited an unusually long time for the supplier
                                                              to request the deallocation of a buffer header via a FreeBuffer call. *)
  OMX_ErrorPortUnresponsiveDuringStop      = $80001016;  (* A supplier port sends this error to the IL client (via the EventHandler callback)
                                                            during the stopping of a port (either on a transition from the IDLE to LOADED
                                                            state or a port stop) when it deems that it has waited an unusually long time for
                                                            the non-supplier to return a buffer via an EmptyThisBuffer or FillThisBuffer call. *)
  OMX_ErrorIncorrectStateTransition        = $80001017;  (* Attempting a state transtion that is not allowed *)
  OMX_ErrorIncorrectStateOperation         = $80001018;  (* Attempting a command that is not allowed during the present state. *)
  OMX_ErrorUnsupportedSetting              = $80001019;  (* The values encapsulated in the parameter or config structure are not supported. *)
  OMX_ErrorUnsupportedIndex                = $8000101A;  (* The parameter or config indicated by the given index is not supported. *)
  OMX_ErrorBadPortIndex                    = $8000101B;  (* The port index supplied is incorrect. *)
  OMX_ErrorPortUnpopulated                 = $8000101C;  (* The port has lost one or more of its buffers and it thus unpopulated. *)
  OMX_ErrorComponentSuspended              = $8000101D;  (* Component suspended due to temporary loss of resources *)
  OMX_ErrorDynamicResourcesUnavailable     = $8000101E;  (* Component suspended due to an inability to acquire dynamic resources *)
  OMX_ErrorMbErrorsInFrame                 = $8000101F;  (* When the macroblock error reporting is enabled the component returns new error
                                                            for every frame that has errors *)
  OMX_ErrorFormatNotDetected               = $80001020;  (* A component reports this error when it cannot parse or determine the format of an input stream. *)
  OMX_ErrorContentPipeOpenFailed           = $80001021;  (* The content open operation failed. *)
  OMX_ErrorContentPipeCreationFailed       = $80001022;  (* The content creation operation failed. *)
  OMX_ErrorSeperateTablesUsed              = $80001023;  (* Separate table information is being used *)
  OMX_ErrorTunnelingUnsupported            = $80001024;  (* Tunneling is unsupported by the component*)
  OMX_ErrorKhronosExtensions               = $8F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_ErrorVendorStartUnused               = $90000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_ErrorDiskFull                        = $90000001;  (* Disk Full error *)
  OMX_ErrorMaxFileSize                     = $90000002;  (* Max file size is reached *)
  OMX_ErrorDrmUnauthorised                 = $90000003;  (* Unauthorised to play a DRM protected file *)
  OMX_ErrorDrmExpired                      = $90000004;  (* The DRM protected file has expired *)
  OMX_ErrorDrmGeneral                      = $90000005;  (* Some other DRM library error *)
  OMX_ErrorMax                             = $7FFFFFFF;

  OMX_EventCmdComplete                     = 0;          (* component has sucessfully completed a command *)
  OMX_EventError                           = 1;          (* component has detected an error condition *)
  OMX_EventMark                            = 2;          (* component has detected a buffer mark *)
  OMX_EventPortSettingsChanged             = 3;          (* component is reported a port settings change *)
  OMX_EventBufferFlag                      = 4;          (* component has detected an EOS *)
  OMX_EventResourcesAcquired               = 5;          (* component has been granted resources and is
                                                            automatically starting the state change from
                                                            OMX_StateWaitForResources to OMX_StateIdle. *)
  OMX_EventComponentResumed                = 6;          (* Component resumed due to reacquisition of resources *)
  OMX_EventDynamicResourcesAvailable       = 7;          (* Component has acquired previously unavailable dynamic resources *)
  OMX_EventPortFormatDetected              = 8;          (* Component has detected a supported format. *)
  OMX_EventKhronosExtensions               = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_EventVendorStartUnused               = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_EventParamOrConfigChanged            = $7F000001;  (* Should be added to the main spec as part of IL416c *)
  OMX_EventMax                             = $7FFFFFFF;

  OMX_DirInput                             = 0;         (* Port is an input port *)
  OMX_DirOutput                            = 1;         (* Port is an output port *)
  OMX_DirMax                               = $7FFFFFFF;

  OMX_CommandStateSet                      = 0;         (* Change the component state *)
  OMX_CommandFlush                         = 1;         (* Flush the data queue(s) of a component *)
  OMX_CommandPortDisable                   = 2;         (* Disable a port on a component. *)
  OMX_CommandPortEnable                    = 3;         (* Enable a port on a component. *)
  OMX_CommandMarkBuffer                    = 4;         (* Mark a component/buffer for observation *)
  OMX_CommandKhronosExtensions             = $6F000000; (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_CommandVendorStartUnused             = $7F000000; (* Reserved region for introducing Vendor Extensions *)
  OMX_CommandMax                           = $7FFFFFFF;

  OMX_StateInvalid                         = 0;         (* component has detected that it's internal data
                                                           structures are corrupted to the point that
                                                           it cannot determine it's state properly *)
  OMX_StateLoaded                          = 1;         (* component has been loaded but has not completed
                                                           initialization.  The OMX_SetParameter macro
                                                           and the OMX_GetParameter macro are the only
                                                           valid macros allowed to be sent to the
                                                           component in this state. *)
  OMX_StateIdle                            = 2;         (* component initialization has been completed
                                                           successfully and the component is ready to
                                                           to start. *)
  OMX_StateExecuting                       = 3;         (* component has accepted the start command and
                                                           is processing data (if data is available) *)
  OMX_StatePause                           = 4;         (* component has received pause command *)
  OMX_StateWaitForResources                = 5;         (* component is waiting for resources, either after
                                                           preemption or before it gets the resources requested.
                                                           See specification for complete details. *)
  OMX_StateKhronosExtensions               = $6F000000; (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_StateVendorStartUnused               = $7F000000; (* Reserved region for introducing Vendor Extensions *)
  OMX_StateMax                             = $7FFFFFFF;

  OMX_VIDEO_CodingUnused                   = 0;          (* Value when coding is N/A *)
  OMX_VIDEO_CodingAutoDetect               = 1;          (* Autodetection of coding type *)
  OMX_VIDEO_CodingMPEG2                    = 2;          (* AKA: H.262 *)
  OMX_VIDEO_CodingH263                     = 3;          (* H.263 *)
  OMX_VIDEO_CodingMPEG4                    = 4;          (* MPEG-4 *)
  OMX_VIDEO_CodingWMV                      = 5;          (* all versions of Windows Media Video *)
  OMX_VIDEO_CodingRV                       = 6;          (* all versions of Real Video *)
  OMX_VIDEO_CodingAVC                      = 7;          (* H.264/AVC *)
  OMX_VIDEO_CodingMJPEG                    = 8;          (* Motion JPEG *)
  OMX_VIDEO_CodingKhronosExtensions        = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_VIDEO_CodingVendorStartUnused        = $7F000000;  (* Reserved region for introducing Vendor Extensions *)

  OMX_IMAGE_CodingUnused                   = $0;         (* Value when format is N/A *)
  OMX_IMAGE_CodingAutoDetect               = $1;         (* Auto detection of image format *)
  OMX_IMAGE_CodingJPEG                     = $2;         (* JPEG/JFIF image format *)
  OMX_IMAGE_CodingJPEG2K                   = $3;         (* JPEG 2000 image format *)
  OMX_IMAGE_CodingEXIF                     = $4;         (* EXIF image format *)
  OMX_IMAGE_CodingTIFF                     = $5;         (* TIFF image format *)
  OMX_IMAGE_CodingGIF                      = $6;         (* Graphics image format *)
  OMX_IMAGE_CodingPNG                      = $7;         (* PNG image format *)
  OMX_IMAGE_CodingLZW                      = $8;         (* LZW image format *)
  OMX_IMAGE_CodingBMP                      = $9;         (* Windows Bitmap format *)
  OMX_IMAGE_CodingKhronosExtensions        = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_IMAGE_CodingVendorStartUnused        = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_IMAGE_CodingTGA                      = $7F000001;
  OMX_IMAGE_CodingPPM                      = $7F000002;
  OMX_IMAGE_CodingMax                      = $7FFFFFFF;

  OMX_OTHER_FormatTime                     = 0;          (* Transmission of various timestamps, elapsed time,
                                                            time deltas, etc *)
  OMX_OTHER_FormatPower                    = 1;          (* Perhaps used for enabling/disabling power
                                                            management, setting clocks? *)
  OMX_OTHER_FormatStats                    = 2;          (* Could be things such as frame rate, frames
                                                            dropped, etc *)
  OMX_OTHER_FormatBinary                   = 3;          (* Arbitrary binary data *)
  OMX_OTHER_FormatVendorReserved           = 1000;       (* Starting value for vendor specific
                                                            formats *)
  OMX_OTHER_FormatKhronosExtensions        = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_OTHER_FormatVendorStartUnused        = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_OTHER_FormatText                     = $7F000001;
  OMX_OTHER_FormatTextSKM2                 = $7F000002;
  OMX_OTHER_FormatText3GP5                 = $7F000003;
  OMX_OTHER_FormatMax                      = $7FFFFFFF;

  OMX_TIME_ClockStateRunning               = 0;          (* Clock running. *)
  OMX_TIME_ClockStateWaitingForStartTime   = 1;          (* Clock waiting until the
                                                            prescribed clients emit their
                                                            start time. *)
  OMX_TIME_ClockStateStopped = 2;                        (* Clock stopped. *)
  OMX_TIME_ClockStateKhronosExtensions     = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_TIME_ClockStateVendorStartUnused     = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_TIME_ClockStateMax                   = $7FFFFFFF;

  OMX_AUDIO_CodingUnused                   = 0;          (* Placeholder value when coding is N/A  *)
  OMX_AUDIO_CodingAutoDetect               = 1;          (* auto detection of audio format *)
  OMX_AUDIO_CodingPCM                      = 2;          (* Any variant of PCM coding *)
  OMX_AUDIO_CodingADPCM                    = 3;          (* Any variant of ADPCM encoded data *)
  OMX_AUDIO_CodingAMR                      = 4;          (* Any variant of AMR encoded data *)
  OMX_AUDIO_CodingGSMFR                    = 5;          (* Any variant of GSM fullrate (i.e. GSM610) *)
  OMX_AUDIO_CodingGSMEFR                   = 6;          (* Any variant of GSM Enhanced Fullrate encoded data*)
  OMX_AUDIO_CodingGSMHR                    = 7;          (* Any variant of GSM Halfrate encoded data *)
  OMX_AUDIO_CodingPDCFR                    = 8;          (* Any variant of PDC Fullrate encoded data *)
  OMX_AUDIO_CodingPDCEFR                   = 9;          (* Any variant of PDC Enhanced Fullrate encoded data *)
  OMX_AUDIO_CodingPDCHR                    = 10;         (* Any variant of PDC Halfrate encoded data *)
  OMX_AUDIO_CodingTDMAFR                   = 11;         (* Any variant of TDMA Fullrate encoded data (TIA/EIA-136-420) *)
  OMX_AUDIO_CodingTDMAEFR                  = 12;         (* Any variant of TDMA Enhanced Fullrate encoded data (TIA/EIA-136-410) *)
  OMX_AUDIO_CodingQCELP8                   = 13;         (* Any variant of QCELP 8kbps encoded data *)
  OMX_AUDIO_CodingQCELP13                  = 14;         (* Any variant of QCELP 13kbps encoded data *)
  OMX_AUDIO_CodingEVRC                     = 15;         (* Any variant of EVRC encoded data *)
  OMX_AUDIO_CodingSMV                      = 16;         (* Any variant of SMV encoded data *)
  OMX_AUDIO_CodingG711                     = 17;         (* Any variant of G.711 encoded data *)
  OMX_AUDIO_CodingG723                     = 18;         (* Any variant of G.723 dot 1 encoded data *)
  OMX_AUDIO_CodingG726                     = 19;         (* Any variant of G.726 encoded data *)
  OMX_AUDIO_CodingG729                     = 20;         (* Any variant of G.729 encoded data *)
  OMX_AUDIO_CodingAAC                      = 21;         (* Any variant of AAC encoded data *)
  OMX_AUDIO_CodingMP3                      = 22;         (* Any variant of MP3 encoded data *)
  OMX_AUDIO_CodingSBC                      = 23;         (* Any variant of SBC encoded data *)
  OMX_AUDIO_CodingVORBIS                   = 24;         (* Any variant of VORBIS encoded data *)
  OMX_AUDIO_CodingWMA                      = 25;         (* Any variant of WMA encoded data *)
  OMX_AUDIO_CodingRA                       = 26;         (* Any variant of RA encoded data *)
  OMX_AUDIO_CodingMIDI                     = 27;         (* Any variant of MIDI encoded data *)
  OMX_AUDIO_CodingKhronosExtensions        = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_AUDIO_CodingVendorStartUnused        = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_AUDIO_CodingMax                      = $7FFFFFFF;



  OMX_AUDIO_PCMModeLinear                  = 0;          (* Linear PCM encoded data *)
  OMX_AUDIO_PCMModeALaw                    = 1;          (* A law PCM encoded data (G.711) *)
  OMX_AUDIO_PCMModeMULaw                   = 2;          (* Mu law PCM encoded data (G.711)  *)
  OMX_AUDIO_PCMModeKhronosExtensions       = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_AUDIO_PCMModeVendorStartUnused       = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_AUDIO_PCMModeMax                     = $7FFFFFFF;

  OMX_AUDIO_ChannelNone                    = $0;         (* Unused or empty *)
  OMX_AUDIO_ChannelLF                      = $1;         (* Left front *)
  OMX_AUDIO_ChannelRF                      = $2;         (* Right front *)
  OMX_AUDIO_ChannelCF                      = $3;         (* Center front *)
  OMX_AUDIO_ChannelLS                      = $4;         (* Left surround *)
  OMX_AUDIO_ChannelRS                      = $5;         (* Right surround *)
  OMX_AUDIO_ChannelLFE                     = $6;         (* Low frequency effects *)
  OMX_AUDIO_ChannelCS                      = $7;         (* Back surround *)
  OMX_AUDIO_ChannelLR                      = $8;         (* Left rear. *)
  OMX_AUDIO_ChannelRR                      = $9;         (* Right rear. *)
  OMX_AUDIO_ChannelKhronosExtensions       = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_AUDIO_ChannelVendorStartUnused       = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_AUDIO_ChannelMax                     = $7FFFFFFF;

  OMX_AUDIO_MAXCHANNELS                    = 16;         (* maximum number distinct audio channels that a buffer may contain *)

  OMX_DISPLAY_ROT0                         = 0;
  OMX_DISPLAY_MIRROR_ROT0                  = 1;
  OMX_DISPLAY_MIRROR_ROT180                = 2;
  OMX_DISPLAY_ROT180                       = 3;
  OMX_DISPLAY_MIRROR_ROT90                 = 4;
  OMX_DISPLAY_ROT270                       = 5;
  OMX_DISPLAY_ROT90                        = 6;
  OMX_DISPLAY_MIRROR_ROT270                = 7;
  OMX_DISPLAY_DUMMY                        = $7FFFFFFF;

  OMX_DISPLAY_MODE_FILL                    = 0;
  OMX_DISPLAY_MODE_LETTERBOX               = 1;
  OMX_DISPLAY_MODE_STEREO_LEFT_TO_LEFT     = 2;
  OMX_DISPLAY_MODE_STEREO_TOP_TO_TOP       = 3;
  OMX_DISPLAY_MODE_STEREO_LEFT_TO_TOP      = 4;
  OMX_DISPLAY_MODE_STEREO_TOP_TO_LEFT      = 5;
  OMX_DISPLAY_MODE_DUMMY                   = $7FFFFFFF;

  OMX_DISPLAY_SET_NONE                     = 0;
  OMX_DISPLAY_SET_NUM                      = 1;
  OMX_DISPLAY_SET_FULLSCREEN               = 2;
  OMX_DISPLAY_SET_TRANSFORM                = 4;
  OMX_DISPLAY_SET_DEST_RECT                = 8;
  OMX_DISPLAY_SET_SRC_RECT                 = $10;
  OMX_DISPLAY_SET_MODE                     = $20;
  OMX_DISPLAY_SET_PIXEL                    = $40;
  OMX_DISPLAY_SET_NOASPECT                 = $80;
  OMX_DISPLAY_SET_LAYER                    = $100;
  OMX_DISPLAY_SET_COPYPROTECT              = $200;
  OMX_DISPLAY_SET_ALPHA                    = $400;
  OMX_DISPLAY_SET_DUMMY                    = $7FFFFFFF;

  OMX_SOURCE_WHITE                         = 0;
  OMX_SOURCE_BLACK                         = 1;
  OMX_SOURCE_DIAGONAL                      = 2;
  OMX_SOURCE_NOISE                         = 3;
  OMX_SOURCE_RANDOM                        = 4;
  OMX_SOURCE_COLOUR                        = 5;
  OMX_SOURCE_BLOCKS                        = 6;
  OMX_SOURCE_SWIRLY                        = 7;
  OMX_SOURCE_DUMMY                         = $7FFFFFFF;

  OMX_RESIZE_NONE                          = 0;
  OMX_RESIZE_CROP                          = 1;
  OMX_RESIZE_BOX                           = 2;
  OMX_RESIZE_BYTES                         = 3;
  OMX_RESIZE_DUMMY                         = $7FFFFFFF;

  OMX_PLAYMODE_NORMAL                      = 0;
  OMX_PLAYMODE_FF                          = 1;
  OMX_PLAYMODE_REW                         = 2;
  OMX_PLAYMODE_DUMMY                       = $7FFFFFFF;

  OMX_DELIVERYFORMAT_STREAM                = 0;
  OMX_DELIVERYFORMAT_SINGLE_PACKET         = 1;
  OMX_DELIVERYFORMAT_DUMMY                 = $7FFFFFFF;

  OMX_AUDIOMONOTRACKOPERATIONS_NOP         = 0;
  OMX_AUDIOMONOTRACKOPERATIONS_L_TO_R      = 1;
  OMX_AUDIOMONOTRACKOPERATIONS_R_TO_L      = 2;
  OMX_AUDIOMONOTRACKOPERATIONS_DUMMY       = $7FFFFFFF;

  OMX_CAMERAIMAGEPOOLINPUTMODE_ONEPOOL     = 0;
  OMX_CAMERAIMAGEPOOLINPUTMODE_TWOPOOLS    = 1;

  OMX_COMMONFLICKERCANCEL_OFF              = 0;
  OMX_COMMONFLICKERCANCEL_AUTO             = 1;
  OMX_COMMONFLICKERCANCEL_50               = 2;
  OMX_COMMONFLICKERCANCEL_60               = 3;
  OMX_COMMONFLICKERCANCEL_DUMMY            = $7FFFFFFF;

  OMX_RedEyeRemovalNone                    = 0;
  OMX_RedEyeRemovalOn                      = 1;
  OMX_RedEyeRemovalAuto                    = 2;
  OMX_RedEyeRemovalKhronosExtensions       = $6F000000;
  OMX_RedEyeRemovalVendorStartUnused       = $7F000000;
  OMX_RedEyeRemovalSimple                  = $7F000001;
  OMX_RedEyeRemovalMax                     = $7FFFFFFF;

  OMX_FaceDetectionControlNone             = 0;
  OMX_FaceDetectionControlOn               = 1;
  OMX_FaceDetectionControlKhronosExtensions = $6F000000;
  OMX_FaceDetectionControlVendorStartUnused = $7F000000;
  OMX_FaceDetectionControlMax              = $7FFFFFFF;

  OMX_FaceRegionFlagsNone                  = 0;
  OMX_FaceRegionFlagsBlink                 = 1;
  OMX_FaceRegionFlagsSmile                 = 2;
  OMX_FaceRegionFlagsKhronosExtensions     = $6F000000;
  OMX_FaceRegionFlagsVendorStartUnused     = $7F000000;
  OMX_FaceRegionFlagsMax                   = $7FFFFFFF;

  OMX_InterlaceProgressive                 = 0;
  OMX_InterlaceFieldSingleUpperFirst       = 1;
  OMX_InterlaceFieldSingleLowerFirst       = 2;
  OMX_InterlaceFieldsInterleavedUpperFirst = 3;
  OMX_InterlaceFieldsInterleavedLowerFirst = 4;
  OMX_InterlaceMixed                       = 5;
  OMX_InterlaceKhronosExtensions           = $6F000000;
  OMX_InterlaceVendorStartUnused           = $7F000000;
  OMX_InterlaceMax                         = $7FFFFFFF;

  OMX_AFAssistAuto                         = 0;
  OMX_AFAssistOn                           = 1;
  OMX_AFAssistOff                          = 2;
  OMX_AFAssistTorch                        = 3;
  OMX_AFAssistKhronosExtensions            = $6F000000;
  OMX_AFAssistVendorStartUnused            = $7F000000;
  OMX_AFAssistMax                          = $7FFFFFFF;

  OMX_PrivacyIndicatorOff                  = 0;
  OMX_PrivacyIndicatorOn                   = 1;
  OMX_PrivacyIndicatorForceOn              = 2;
  OMX_PrivacyIndicatorKhronosExtensions    = $6F000000;
  OMX_PrivacyIndicatorVendorStartUnused    = $7F000000;
  OMX_PrivacyIndicatorMax                  = $7FFFFFFF;

  OMX_CameraFlashDefault                   = 0;
  OMX_CameraFlashXenon                     = 1;
  OMX_CameraFlashLED                       = 2;
  OMX_CameraFlashNone                      = 3;
  OMX_CameraFlashKhronosExtensions         = $6F000000;
  OMX_CameraFlashVendorStartUnused         = $7F000000;
  OMX_CameraFlashMax                       = $7FFFFFFF;

  OMX_CameraFlashConfigSyncFrontSlow       = 0;
  OMX_CameraFlashConfigSyncRearSlow        = 1;
  OMX_CameraFlashConfigSyncFrontFast       = 2;
  OMX_CameraFlashConfigSyncKhronosExtensions = $6F000000;
  OMX_CameraFlashConfigSyncVendorStartUnused = $7F000000;
  OMX_CameraFlashConfigSyncMax             = $7FFFFFFF;

  OMX_PixelValueRangeUnspecified           = 0;
  OMX_PixelValueRangeITU_R_BT601           = 1;
  OMX_PixelValueRangeFull8Bit              = 2;
  OMX_PixelValueRangeKhronosExtensions     = $6F000000;
  OMX_PixelValueRangeVendorStartUnused     = $7F000000;
  OMX_PixelValueRangeMax                   = $7FFFFFFF;

  OMX_CameraDisableAlgorithmFacetracking   = 0;
  OMX_CameraDisableAlgorithmRedEyeReduction = 1;
  OMX_CameraDisableAlgorithmVideoStabilisation = 2;
  OMX_CameraDisableAlgorithmWriteRaw       = 3;
  OMX_CameraDisableAlgorithmVideoDenoise   = 4;
  OMX_CameraDisableAlgorithmStillsDenoise  = 5;
  OMX_CameraDisableAlgorithmAntiShake      = 6;
  OMX_CameraDisableAlgorithmImageEffects   = 7;
  OMX_CameraDisableAlgorithmDarkSubtract   = 8;
  OMX_CameraDisableAlgorithmDynamicRangeExpansion = 9;
  OMX_CameraDisableAlgorithmFaceRecognition = 10;
  OMX_CameraDisableAlgorithmFaceBeautification = 11;
  OMX_CameraDisableAlgorithmSceneDetection = 12;
  OMX_CameraDisableAlgorithmHighDynamicRange = 13;
  OMX_CameraDisableAlgorithmKhronosExtensions = $6F000000;
  OMX_CameraDisableAlgorithmVendorStartUnused = $7F000000;
  OMX_CameraDisableAlgorithmMax            = $7FFFFFFF;

  OMX_CameraUseCaseAuto                    = 0;
  OMX_CameraUseCaseVideo                   = 1;
  OMX_CameraUseCaseStills                  = 2;
  OMX_CameraUseCaseKhronosExtensions       = $6F000000;
  OMX_CameraUseCaseVendorStartUnused       = $7F000000;
  OMX_CameraUseCaseMax                     = $7FFFFFFF;

  OMX_CameraFeaturesShutterUnknown         = 0;
  OMX_CameraFeaturesShutterNotPresent      = 1;
  OMX_CameraFeaturesShutterPresent         = 2;
  OMX_CameraFeaturesShutterKhronosExtensions = $6F000000;
  OMX_CameraFeaturesShutterVendorStartUnused = $7F000000;
  OMX_CameraFeaturesShutterMax             = $7FFFFFFF;

  OMX_FocusRegionNormal                    = 0;
  OMX_FocusRegionFace                      = 1;
  OMX_FocusRegionMax                       = 2;

  OMX_DynRangeExpOff                       = 0;
  OMX_DynRangeExpLow                       = 1;
  OMX_DynRangeExpMedium                    = 2;
  OMX_DynRangeExpHigh                      = 3;
  OMX_DynRangeExpKhronosExtensions         = $6F000000;
  OMX_DynRangeExpVendorStartUnused         = $7F000000;
  OMX_DynRangeExpMax                       = $7FFFFFFF;

  OMX_BrcmThreadAffinityCPU0               = 0;
  OMX_BrcmThreadAffinityCPU1               = 1;
  OMX_BrcmThreadAffinityMax                = $7FFFFFFF;

  OMX_SceneDetectUnknown                   = 0;
  OMX_SceneDetectLandscape                 = 1;
  OMX_SceneDetectPortrait                  = 2;
  OMX_SceneDetectMacro                     = 3;
  OMX_SceneDetectNight                     = 4;
  OMX_SceneDetectPortraitNight             = 5;
  OMX_SceneDetectBacklit                   = 6;
  OMX_SceneDetectPortraitBacklit           = 7;
  OMX_SceneDetectSunset                    = 8;
  OMX_SceneDetectBeach                     = 9;
  OMX_SceneDetectSnow                      = 10;
  OMX_SceneDetectFireworks                 = 11;
  OMX_SceneDetectMax                       = $7FFFFFFF;

  OMX_IndexKhronosExtensions               = $6F000000;  // check
  OMX_IndexExtVideoStartUnused             = OMX_IndexKhronosExtensions + $00600000;
  OMX_IndexParamNalStreamFormatSupported   = OMX_IndexExtVideoStartUnused + 1;
  OMX_IndexParamNalStreamFormat            = OMX_IndexExtVideoStartUnused + 2;
  OMX_IndexParamNalStreamFormatSelect      = OMX_IndexExtVideoStartUnused + 3;
  OMX_IndexExtMax                          = $7FFFFFFF;

  OMX_NaluFormatStartCodes                 = 1;
  OMX_NaluFormatOneNaluPerBuffer           = 2;
  OMX_NaluFormatOneByteInterleaveLength    = 4;
  OMX_NaluFormatTwoByteInterleaveLength    = 8;
  OMX_NaluFormatFourByteInterleaveLength   = 16;
  OMX_NaluFormatCodingMax                  = $7FFFFFFF;

  OMX_StaticBoxNormal                      = 0;
  OMX_StaticBoxPrimaryFaceAfIdle           = 1;
  OMX_StaticBoxNonPrimaryFaceAfIdle        = 2;
  OMX_StaticBoxFocusRegionAfIdle           = 3;
  OMX_StaticBoxPrimaryFaceAfSuccess        = 4;
  OMX_StaticBoxNonPrimaryFaceAfSuccess     = 5;
  OMX_StaticBoxFocusRegionAfSuccess        = 6;
  OMX_StaticBoxPrimaryFaceAfFail           = 7;
  OMX_StaticBoxNonPrimaryFaceAfFail        = 8;
  OMX_StaticBoxFocusRegionAfFail           = 9;
  OMX_StaticBoxMax                         = 10;

  OMX_CameraCaptureModeWaitForCaptureEnd   = 0;
  OMX_CameraCaptureModeWaitForCaptureEndAndUsePreviousInputImage = 1;
  OMX_CameraCaptureModeResumeViewfinderImmediately = 2;
  OMX_CameraCaptureModeMax                 = 3;

  OMX_DrmEncryptionNone                    = 0;
  OMX_DrmEncryptionHdcp2                   = 1;
  OMX_DrmEncryptionKhronosExtensions       = $6F000000;
  OMX_DrmEncryptionVendorStartUnused       = $7F000000;
  OMX_DrmEncryptionRangeMax                = $7FFFFFFF;

  OMX_TimestampModeZero                    = 0;
  OMX_TimestampModeRawStc                  = 1;
  OMX_TimestampModeResetStc                = 2;
  OMX_TimestampModeKhronosExtensions       = $6F000000;
  OMX_TimestampModeVendorStartUnused       = $7F000000;
  OMX_TimestampModeMax                     = $7FFFFFFF;

  OMX_COLOR_FormatUnused                   = 0;
  OMX_COLOR_FormatMonochrome               = 1;
  OMX_COLOR_Format8bitRGB332               = 2;
  OMX_COLOR_Format12bitRGB444              = 3;
  OMX_COLOR_Format16bitARGB4444            = 4;
  OMX_COLOR_Format16bitARGB1555            = 5;
  OMX_COLOR_Format16bitRGB565              = 6;
  OMX_COLOR_Format16bitBGR565              = 7;
  OMX_COLOR_Format18bitRGB666              = 8;
  OMX_COLOR_Format18bitARGB1665            = 9;
  OMX_COLOR_Format19bitARGB1666            = 10;
  OMX_COLOR_Format24bitRGB888              = 11;
  OMX_COLOR_Format24bitBGR888              = 12;
  OMX_COLOR_Format24bitARGB1887            = 13;
  OMX_COLOR_Format25bitARGB1888            = 14;
  OMX_COLOR_Format32bitBGRA8888            = 15;
  OMX_COLOR_Format32bitARGB8888            = 16;
  OMX_COLOR_FormatYUV411Planar             = 17;
  OMX_COLOR_FormatYUV411PackedPlanar       = 18;
  OMX_COLOR_FormatYUV420Planar             = 19;
  OMX_COLOR_FormatYUV420PackedPlanar       = 20;
  OMX_COLOR_FormatYUV420SemiPlanar         = 21;
  OMX_COLOR_FormatYUV422Planar             = 22;
  OMX_COLOR_FormatYUV422PackedPlanar       = 23;
  OMX_COLOR_FormatYUV422SemiPlanar         = 24;
  OMX_COLOR_FormatYCbYCr                   = 25;
  OMX_COLOR_FormatYCrYCb                   = 26;
  OMX_COLOR_FormatCbYCrY                   = 27;
  OMX_COLOR_FormatCrYCbY                   = 28;
  OMX_COLOR_FormatYUV444Interleaved        = 29;
  OMX_COLOR_FormatRawBayer8bit             = 30;
  OMX_COLOR_FormatRawBayer10bit            = 31;
  OMX_COLOR_FormatRawBayer8bitcompressed   = 32;
  OMX_COLOR_FormatL2                       = 33;
  OMX_COLOR_FormatL4                       = 34;
  OMX_COLOR_FormatL8                       = 35;
  OMX_COLOR_FormatL16                      = 36;
  OMX_COLOR_FormatL24                      = 37;
  OMX_COLOR_FormatL32                      = 38;
  OMX_COLOR_FormatYUV420PackedSemiPlanar   = 39;
  OMX_COLOR_FormatYUV422PackedSemiPlanar   = 40;
  OMX_COLOR_Format18BitBGR666              = 41;
  OMX_COLOR_Format24BitARGB6666            = 42;
  OMX_COLOR_Format24BitABGR6666            = 43;
  OMX_COLOR_FormatKhronosExtensions        = $6F000000;  (* Reserved region for introducing Khronos Standard Extensions *)
  OMX_COLOR_FormatVendorStartUnused        = $7F000000;  (* Reserved region for introducing Vendor Extensions *)
  OMX_COLOR_Format32bitABGR8888            = $7F000001;
  OMX_COLOR_Format8bitPalette              = $7F000002;
  OMX_COLOR_FormatYUVUV128                 = $7F000003;
  OMX_COLOR_FormatRawBayer12bit            = $7F000004;
  OMX_COLOR_FormatBRCMEGL                  = $7F000005;
  OMX_COLOR_FormatBRCMOpaque               = $7F000006;
  OMX_COLOR_FormatYVU420PackedPlanar       = $7F000007;
  OMX_COLOR_FormatYVU420PackedSemiPlanar   = $7F000008;
  OMX_COLOR_FormatRawBayer16bit            = $7F000009;
  OMX_COLOR_FormatYUV420_16PackedPlanar    = $7F00000A;  (* YUV420, 16bit/component *)
  OMX_COLOR_FormatYUV420_10PackedPlanar    = $7F00000B;  (* YUV420, 10bit/component as least sig 10bits of 16 bit words *)
  OMX_COLOR_FormatYUVUV64_10               = $7F00000C;  (* YUVUV, 10bit/component as least sig 10bits of 16 bit words *)
  OMX_COLOR_FormatMax                      = $7FFFFFFF;

  OMX_COLORSPACE_UNKNOWN                   = 0;
  OMX_COLORSPACE_JPEG_JFIF                 = 1;
  OMX_COLORSPACE_ITU_R_BT601               = 2;
  OMX_COLORSPACE_ITU_R_BT709               = 3;
  OMX_COLORSPACE_FCC                       = 4;
  OMX_COLORSPACE_SMPTE240M                 = 5;
  OMX_COLORSPACE_BT470_2_M                 = 6;
  OMX_COLORSPACE_BT470_2_BG                = 7;
  OMX_COLORSPACE_JFIF_Y16_255              = 8;
  OMX_COLORSPACE_MAX                       = $7FFFFFFF;

  OMX_NotCapturing                         = 0;
  OMX_CaptureStarted                       = 1;
  OMX_CaptureComplete                      = 2;
  OMX_CaptureMax                           = $7FFFFFFF;

  OMX_STEREOSCOPIC_NONE                    = 0;
  OMX_STEREOSCOPIC_SIDEBYSIDE              = 1;
  OMX_STEREOSCOPIC_TOPBOTTOM               = 2;
  OMX_STEREOSCOPIC_MAX                     = $7FFFFFFF;

  OMX_CAMERAINTERFACE_CSI                  = 0;
  OMX_CAMERAINTERFACE_CCP2                 = 1;
  OMX_CAMERAINTERFACE_CPI                  = 2;
  OMX_CAMERAINTERFACE_MAX                  = $7FFFFFFF;

  OMX_CAMERACLOCKINGMODE_STROBE            = 0;
  OMX_CAMERACLOCKINGMODE_CLOCK             = 1;
  OMX_CAMERACLOCKINGMODE_MAX               = $7FFFFFFF;

  OMX_CAMERARXDECODE_NONE                  = 0;
  OMX_CAMERARXDECODE_DPCM8TO10             = 1;
  OMX_CAMERARXDECODE_DPCM7TO10             = 2;
  OMX_CAMERARXDECODE_DPCM6TO10             = 3;
  OMX_CAMERARXDECODE_DPCM8TO12             = 4;
  OMX_CAMERARXDECODE_DPCM7TO12             = 5;
  OMX_CAMERARXDECODE_DPCM6TO12             = 6;
  OMX_CAMERARXDECODE_DPCM10TO14            = 7;
  OMX_CAMERARXDECODE_DPCM8TO14             = 8;
  OMX_CAMERARXDECODE_DPCM12TO16            = 9;
  OMX_CAMERARXDECODE_DPCM10TO16            = 10;
  OMX_CAMERARXDECODE_DPCM8TO16             = 11;
  OMX_CAMERARXDECODE_MAX                   = $7FFFFFFF;

  OMX_CAMERARXENCODE_NONE                  = 0;
  OMX_CAMERARXENCODE_DPCM10TO8             = 1;
  OMX_CAMERARXENCODE_DPCM12TO8             = 2;
  OMX_CAMERARXENCODE_DPCM14TO8             = 3;
  OMX_CAMERARXENCODE_MAX                   = $7FFFFFFF;

  OMX_CAMERARXUNPACK_NONE                  = 0;
  OMX_CAMERARXUNPACK_6                     = 1;
  OMX_CAMERARXUNPACK_7                     = 2;
  OMX_CAMERARXUNPACK_8                     = 3;
  OMX_CAMERARXUNPACK_10                    = 4;
  OMX_CAMERARXUNPACK_12                    = 5;
  OMX_CAMERARXUNPACK_14                    = 6;
  OMX_CAMERARXUNPACK_16                    = 7;
  OMX_CAMERARXUNPACK_MAX                   = $7FFFFFFF;

  OMX_CAMERARXPACK_NONE                    = 0;
  OMX_CAMERARXPACK_8                       = 1;
  OMX_CAMERARXPACK_10                      = 2;
  OMX_CAMERARXPACK_12                      = 3;
  OMX_CAMERARXPACK_14                      = 4;
  OMX_CAMERARXPACK_16                      = 5;
  OMX_CAMERARXPACK_RAW10                   = 6;
  OMX_CAMERARXPACK_RAW12                   = 7;
  OMX_CAMERARXPACK_MAX                     = $7FFFFFFF;

  OMX_BayerOrderRGGB                       = 0;
  OMX_BayerOrderGBRG                       = 1;
  OMX_BayerOrderBGGR                       = 2;
  OMX_BayerOrderGRBG                       = 3;
  OMX_BayerOrderMax                        = $7FFFFFFF;

  // OMX_INDEX_TYPE
  OMX_IndexComponentStartUnused            = $01000000;
  OMX_IndexParamPriorityMgmt               = $01000001;  (* reference: OMX_PRIORITYMGMTTYPE *)
  OMX_IndexParamAudioInit                  = $01000002;  (* reference: OMX_PORT_PARAM_TYPE *)
  OMX_IndexParamImageInit                  = $01000003;  (* reference: OMX_PORT_PARAM_TYPE *)
  OMX_IndexParamVideoInit                  = $01000004;  (* reference: OMX_PORT_PARAM_TYPE *)
  OMX_IndexParamOtherInit                  = $01000005;  (* reference: OMX_PORT_PARAM_TYPE *)
  OMX_IndexParamNumAvailableStreams        = $01000006;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamActiveStream               = $01000007;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamSuspensionPolicy           = $01000008;  (* reference: OMX_PARAM_SUSPENSIONPOLICYTYPE *)
  OMX_IndexParamComponentSuspended         = $01000009;  (* reference: OMX_PARAM_SUSPENSIONTYPE *)
  OMX_IndexConfigCapturing                 = $0100000A;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigCaptureMode               = $0100000B;  (* reference: OMX_CONFIG_CAPTUREMODETYPE *)
  OMX_IndexAutoPauseAfterCapture           = $0100000C;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamContentURI                 = $0100000D;  (* reference: OMX_PARAM_CONTENTURITYPE *)
  OMX_IndexParamCustomContentPipe          = $0100000E;  (* reference: OMX_PARAM_CONTENTPIPETYPE *)
  OMX_IndexParamDisableResourceConcealment = $0100000F;  (* reference: OMX_RESOURCECONCEALMENTTYPE *)
  OMX_IndexConfigMetadataItemCount         = $01000010;  (* reference: OMX_CONFIG_METADATAITEMCOUNTTYPE *)
  OMX_IndexConfigContainerNodeCount        = $01000011;  (* reference: OMX_CONFIG_CONTAINERNODECOUNTTYPE *)
  OMX_IndexConfigMetadataItem              = $01000012;  (* reference: OMX_CONFIG_METADATAITEMTYPE *)
  OMX_IndexConfigCounterNodeID             = $01000013;  (* reference: OMX_CONFIG_CONTAINERNODEIDTYPE *)
  OMX_IndexParamMetadataFilterType         = $01000014;  (* reference: OMX_PARAM_METADATAFILTERTYPE *)
  OMX_IndexParamMetadataKeyFilter          = $01000015;  (* reference: OMX_PARAM_METADATAFILTERTYPE *)
  OMX_IndexConfigPriorityMgmt              = $01000016;  (* reference: OMX_PRIORITYMGMTTYPE *)
  OMX_IndexParamStandardComponentRole      = $01000017;  (* reference: OMX_PARAM_COMPONENTROLETYPE *)

  OMX_IndexPortStartUnused                 = $02000000;
  OMX_IndexParamPortDefinition             = $02000001;  (* reference: OMX_PARAM_PORTDEFINITIONTYPE *)
  OMX_IndexParamCompBufferSupplier         = $02000002;  (* reference: OMX_PARAM_BUFFERSUPPLIERTYPE *)

  OMX_IndexReservedStartUnused             = $03000000;

  (* Audio parameters and configurations *)
  OMX_IndexAudioStartUnused                = $04000000;
  OMX_IndexParamAudioPortFormat            = $04000001;  (* reference: OMX_AUDIO_PARAM_PORTFORMATTYPE *)
  OMX_IndexParamAudioPcm                   = $04000002;  (* reference: OMX_AUDIO_PARAM_PCMMODETYPE *)
  OMX_IndexParamAudioAac                   = $04000003;  (* reference: OMX_AUDIO_PARAM_AACPROFILETYPE *)
  OMX_IndexParamAudioRa                    = $04000004;  (* reference: OMX_AUDIO_PARAM_RATYPE *)
  OMX_IndexParamAudioMp3                   = $04000005;  (* reference: OMX_AUDIO_PARAM_MP3TYPE *)
  OMX_IndexParamAudioAdpcm                 = $04000006;  (* reference: OMX_AUDIO_PARAM_ADPCMTYPE *)
  OMX_IndexParamAudioG723                  = $04000007;  (* reference: OMX_AUDIO_PARAM_G723TYPE *)
  OMX_IndexParamAudioG729                  = $04000008;  (* reference: OMX_AUDIO_PARAM_G729TYPE *)
  OMX_IndexParamAudioAmr                   = $04000009;  (* reference: OMX_AUDIO_PARAM_AMRTYPE *)
  OMX_IndexParamAudioWma                   = $0400000A;  (* reference: OMX_AUDIO_PARAM_WMATYPE *)
  OMX_IndexParamAudioSbc                   = $0400000B;  (* reference: OMX_AUDIO_PARAM_SBCTYPE *)
  OMX_IndexParamAudioMidi                  = $0400000C;  (* reference: OMX_AUDIO_PARAM_MIDITYPE *)
  OMX_IndexParamAudioGsm_FR                = $0400000D;  (* reference: OMX_AUDIO_PARAM_GSMFRTYPE *)
  OMX_IndexParamAudioMidiLoadUserSound     = $0400000E;  (* reference: OMX_AUDIO_PARAM_MIDILOADUSERSOUNDTYPE *)
  OMX_IndexParamAudioG726                  = $0400000F;  (* reference: OMX_AUDIO_PARAM_G726TYPE *)
  OMX_IndexParamAudioGsm_EFR               = $04000010;  (* reference: OMX_AUDIO_PARAM_GSMEFRTYPE *)
  OMX_IndexParamAudioGsm_HR                = $04000011;  (* reference: OMX_AUDIO_PARAM_GSMHRTYPE *)
  OMX_IndexParamAudioPdc_FR                = $04000012;  (* reference: OMX_AUDIO_PARAM_PDCFRTYPE *)
  OMX_IndexParamAudioPdc_EFR               = $04000013;  (* reference: OMX_AUDIO_PARAM_PDCEFRTYPE *)
  OMX_IndexParamAudioPdc_HR                = $04000014;  (* reference: OMX_AUDIO_PARAM_PDCHRTYPE *)
  OMX_IndexParamAudioTdma_FR               = $04000015;  (* reference: OMX_AUDIO_PARAM_TDMAFRTYPE *)
  OMX_IndexParamAudioTdma_EFR              = $04000016;  (* reference: OMX_AUDIO_PARAM_TDMAEFRTYPE *)
  OMX_IndexParamAudioQcelp8                = $04000017;  (* reference: OMX_AUDIO_PARAM_QCELP8TYPE *)
  OMX_IndexParamAudioQcelp13               = $04000018;  (* reference: OMX_AUDIO_PARAM_QCELP13TYPE *)
  OMX_IndexParamAudioEvrc                  = $04000019;  (* reference: OMX_AUDIO_PARAM_EVRCTYPE *)
  OMX_IndexParamAudioSmv                   = $0400001A;  (* reference: OMX_AUDIO_PARAM_SMVTYPE *)
  OMX_IndexParamAudioVorbis                = $0400001B;  (* reference: OMX_AUDIO_PARAM_VORBISTYPE *)

  OMX_IndexConfigAudioMidiImmediateEvent   = $0400001C;  (* reference: OMX_AUDIO_CONFIG_MIDIIMMEDIATEEVENTTYPE *)
  OMX_IndexConfigAudioMidiControl          = $0400001D;  (* reference: OMX_AUDIO_CONFIG_MIDICONTROLTYPE *)
  OMX_IndexConfigAudioMidiSoundBankProgram = $0400001E;  (* reference: OMX_AUDIO_CONFIG_MIDISOUNDBANKPROGRAMTYPE *)
  OMX_IndexConfigAudioMidiStatus           = $0400001F;  (* reference: OMX_AUDIO_CONFIG_MIDISTATUSTYPE *)
  OMX_IndexConfigAudioMidiMetaEvent        = $04000020;  (* reference: OMX_AUDIO_CONFIG_MIDIMETAEVENTTYPE *)
  OMX_IndexConfigAudioMidiMetaEventData    = $04000021;  (* reference: OMX_AUDIO_CONFIG_MIDIMETAEVENTDATATYPE *)
  OMX_IndexConfigAudioVolume               = $04000022;  (* reference: OMX_AUDIO_CONFIG_VOLUMETYPE *)
  OMX_IndexConfigAudioBalance              = $04000023;  (* reference: OMX_AUDIO_CONFIG_BALANCETYPE *)
  OMX_IndexConfigAudioChannelMute          = $04000024;  (* reference: OMX_AUDIO_CONFIG_CHANNELMUTETYPE *)
  OMX_IndexConfigAudioMute                 = $04000025;  (* reference: OMX_AUDIO_CONFIG_MUTETYPE *)
  OMX_IndexConfigAudioLoudness             = $04000026;  (* reference: OMX_AUDIO_CONFIG_LOUDNESSTYPE *)
  OMX_IndexConfigAudioEchoCancelation      = $04000027;  (* reference: OMX_AUDIO_CONFIG_ECHOCANCELATIONTYPE *)
  OMX_IndexConfigAudioNoiseReduction       = $04000028;  (* reference: OMX_AUDIO_CONFIG_NOISEREDUCTIONTYPE *)
  OMX_IndexConfigAudioBass                 = $04000029;  (* reference: OMX_AUDIO_CONFIG_BASSTYPE *)
  OMX_IndexConfigAudioTreble               = $0400002A;  (* reference: OMX_AUDIO_CONFIG_TREBLETYPE *)
  OMX_IndexConfigAudioStereoWidening       = $0400002B;  (* reference: OMX_AUDIO_CONFIG_STEREOWIDENINGTYPE *)
  OMX_IndexConfigAudioChorus               = $0400002C;  (* reference: OMX_AUDIO_CONFIG_CHORUSTYPE *)
  OMX_IndexConfigAudioEqualizer            = $0400002D;  (* reference: OMX_AUDIO_CONFIG_EQUALIZERTYPE *)
  OMX_IndexConfigAudioReverberation        = $0400002E;  (* reference: OMX_AUDIO_CONFIG_REVERBERATIONTYPE *)
  OMX_IndexConfigAudioChannelVolume        = $0400002F;  (* reference: OMX_AUDIO_CONFIG_CHANNELVOLUMETYPE *)

  (* Image specific parameters and configurations *)
  OMX_IndexImageStartUnused                = $05000000;
  OMX_IndexParamImagePortFormat            = $05000001;  (* reference: OMX_IMAGE_PARAM_PORTFORMATTYPE *)
  OMX_IndexParamFlashControl               = $05000002;  (* reference: OMX_IMAGE_PARAM_FLASHCONTROLTYPE *)
  OMX_IndexConfigFocusControl              = $05000003;  (* reference: OMX_IMAGE_CONFIG_FOCUSCONTROLTYPE *)
  OMX_IndexParamQFactor                    = $05000004;  (* reference: OMX_IMAGE_PARAM_QFACTORTYPE *)
  OMX_IndexParamQuantizationTable          = $05000005;  (* reference: OMX_IMAGE_PARAM_QUANTIZATIONTABLETYPE *)
  OMX_IndexParamHuffmanTable               = $05000006;  (* reference: OMX_IMAGE_PARAM_HUFFMANTTABLETYPE *)
  OMX_IndexConfigFlashControl              = $05000007;  (* reference: OMX_IMAGE_PARAM_FLASHCONTROLTYPE *)

  (* Video specific parameters and configurations *)
  OMX_IndexVideoStartUnused                = $06000000;
  OMX_IndexParamVideoPortFormat            = $06000001;  (* reference: OMX_VIDEO_PARAM_PORTFORMATTYPE *)
  OMX_IndexParamVideoQuantization          = $06000002;  (* reference: OMX_VIDEO_PARAM_QUANTIZATIONTYPE *)
  OMX_IndexParamVideoFastUpdate            = $06000003;  (* reference: OMX_VIDEO_PARAM_VIDEOFASTUPDATETYPE *)
  OMX_IndexParamVideoBitrate               = $06000004;  (* reference: OMX_VIDEO_PARAM_BITRATETYPE *)
  OMX_IndexParamVideoMotionVector          = $06000005;  (* reference: OMX_VIDEO_PARAM_MOTIONVECTORTYPE *)
  OMX_IndexParamVideoIntraRefresh          = $06000006;  (* reference: OMX_VIDEO_PARAM_INTRAREFRESHTYPE *)
  OMX_IndexParamVideoErrorCorrection       = $06000007;  (* reference: OMX_VIDEO_PARAM_ERRORCORRECTIONTYPE *)
  OMX_IndexParamVideoVBSMC                 = $06000008;  (* reference: OMX_VIDEO_PARAM_VBSMCTYPE *)
  OMX_IndexParamVideoMpeg2                 = $06000009;  (* reference: OMX_VIDEO_PARAM_MPEG2TYPE *)
  OMX_IndexParamVideoMpeg4                 = $0600000A;  (* reference: OMX_VIDEO_PARAM_MPEG4TYPE *)
  OMX_IndexParamVideoWmv                   = $0600000B;  (* reference: OMX_VIDEO_PARAM_WMVTYPE *)
  OMX_IndexParamVideoRv                    = $0600000C;  (* reference: OMX_VIDEO_PARAM_RVTYPE *)
  OMX_IndexParamVideoAvc                   = $0600000D;  (* reference: OMX_VIDEO_PARAM_AVCTYPE *)
  OMX_IndexParamVideoH263                  = $0600000E;  (* reference: OMX_VIDEO_PARAM_H263TYPE *)
  OMX_IndexParamVideoProfileLevelQuerySupported = $0600000F; (* reference: OMX_VIDEO_PARAM_PROFILELEVELTYPE *)
  OMX_IndexParamVideoProfileLevelCurrent   = $06000010;  (* reference: OMX_VIDEO_PARAM_PROFILELEVELTYPE *)
  OMX_IndexConfigVideoBitrate              = $06000011;  (* reference: OMX_VIDEO_CONFIG_BITRATETYPE *)
  OMX_IndexConfigVideoFramerate            = $06000012;  (* reference: OMX_CONFIG_FRAMERATETYPE *)
  OMX_IndexConfigVideoIntraVOPRefresh      = $06000013;  (* reference: OMX_CONFIG_INTRAREFRESHVOPTYPE *)
  OMX_IndexConfigVideoIntraMBRefresh       = $06000014;  (* reference: OMX_CONFIG_MACROBLOCKERRORMAPTYPE *)
  OMX_IndexConfigVideoMBErrorReporting     = $06000015;  (* reference: OMX_CONFIG_MBERRORREPORTINGTYPE *)
  OMX_IndexParamVideoMacroblocksPerFrame   = $06000016;  (* reference: OMX_PARAM_MACROBLOCKSTYPE *)
  OMX_IndexConfigVideoMacroBlockErrorMap   = $06000017;  (* reference: OMX_CONFIG_MACROBLOCKERRORMAPTYPE *)
  OMX_IndexParamVideoSliceFMO              = $06000018;  (* reference: OMX_VIDEO_PARAM_AVCSLICEFMO *)
  OMX_IndexConfigVideoAVCIntraPeriod       = $06000019;  (* reference: OMX_VIDEO_CONFIG_AVCINTRAPERIOD *)
  OMX_IndexConfigVideoNalSize              = $0600001A;  (* reference: OMX_VIDEO_CONFIG_NALSIZE *)

  (* Image & Video common Configurations *)
  OMX_IndexCommonStartUnused               = $07000000;
  OMX_IndexParamCommonDeblocking           = $07000001;  (* reference: OMX_PARAM_DEBLOCKINGTYPE *)
  OMX_IndexParamCommonSensorMode           = $07000002;  (* reference: OMX_PARAM_SENSORMODETYPE *)
  OMX_IndexParamCommonInterleave           = $07000003;  (* reference: OMX_PARAM_INTERLEAVETYPE *)
  OMX_IndexConfigCommonColorFormatConversion = $07000004; (* reference: OMX_CONFIG_COLORCONVERSIONTYPE *)
  OMX_IndexConfigCommonScale               = $07000005;  (* reference: OMX_CONFIG_SCALEFACTORTYPE *)
  OMX_IndexConfigCommonImageFilter         = $07000006;  (* reference: OMX_CONFIG_IMAGEFILTERTYPE *)
  OMX_IndexConfigCommonColorEnhancement    = $07000007;  (* reference: OMX_CONFIG_COLORENHANCEMENTTYPE *)
  OMX_IndexConfigCommonColorKey            = $07000008;  (* reference: OMX_CONFIG_COLORKEYTYPE *)
  OMX_IndexConfigCommonColorBlend          = $07000009;  (* reference: OMX_CONFIG_COLORBLENDTYPE *)
  OMX_IndexConfigCommonFrameStabilisation  = $0700000A;  (* reference: OMX_CONFIG_FRAMESTABTYPE *)
  OMX_IndexConfigCommonRotate              = $0700000B;  (* reference: OMX_CONFIG_ROTATIONTYPE *)
  OMX_IndexConfigCommonMirror              = $0700000C;  (* reference: OMX_CONFIG_MIRRORTYPE *)
  OMX_IndexConfigCommonOutputPosition      = $0700000D;  (* reference: OMX_CONFIG_POINTTYPE *)
  OMX_IndexConfigCommonInputCrop           = $0700000E;  (* reference: OMX_CONFIG_RECTTYPE *)
  OMX_IndexConfigCommonOutputCrop          = $0700000F;  (* reference: OMX_CONFIG_RECTTYPE *)
  OMX_IndexConfigCommonDigitalZoom         = $07000010;  (* reference: OMX_CONFIG_SCALEFACTORTYPE *)
  OMX_IndexConfigCommonOpticalZoom         = $07000011;  (* reference: OMX_CONFIG_SCALEFACTORTYPE*)
  OMX_IndexConfigCommonWhiteBalance        = $07000012;  (* reference: OMX_CONFIG_WHITEBALCONTROLTYPE *)
  OMX_IndexConfigCommonExposure            = $07000013;  (* reference: OMX_CONFIG_EXPOSURECONTROLTYPE *)
  OMX_IndexConfigCommonContrast            = $07000014;  (* reference: OMX_CONFIG_CONTRASTTYPE *)
  OMX_IndexConfigCommonBrightness          = $07000015;  (* reference: OMX_CONFIG_BRIGHTNESSTYPE *)
  OMX_IndexConfigCommonBacklight           = $07000016;  (* reference: OMX_CONFIG_BACKLIGHTTYPE *)
  OMX_IndexConfigCommonGamma               = $07000017;  (* reference: OMX_CONFIG_GAMMATYPE *)
  OMX_IndexConfigCommonSaturation          = $07000018;  (* reference: OMX_CONFIG_SATURATIONTYPE *)
  OMX_IndexConfigCommonLightness           = $07000019;  (* reference: OMX_CONFIG_LIGHTNESSTYPE *)
  OMX_IndexConfigCommonExclusionRect       = $0700001A;  (* reference: OMX_CONFIG_RECTTYPE *)
  OMX_IndexConfigCommonDithering           = $0700001B;  (* reference: OMX_CONFIG_DITHERTYPE *)
  OMX_IndexConfigCommonPlaneBlend          = $0700001C;  (* reference: OMX_CONFIG_PLANEBLENDTYPE *)
  OMX_IndexConfigCommonExposureValue       = $0700001D;  (* reference: OMX_CONFIG_EXPOSUREVALUETYPE *)
  OMX_IndexConfigCommonOutputSize          = $0700001E;  (* reference: OMX_FRAMESIZETYPE *)
  OMX_IndexParamCommonExtraQuantData       = $0700001F;  (* reference: OMX_OTHER_EXTRADATATYPE *)
  OMX_IndexConfigCommonFocusRegion         = $07000020;  (* reference: OMX_CONFIG_FOCUSREGIONTYPE *)
  OMX_IndexConfigCommonFocusStatus         = $07000021;  (* reference: OMX_PARAM_FOCUSSTATUSTYPE *)
  OMX_IndexConfigCommonTransitionEffect    = $07000022;  (* reference: OMX_CONFIG_TRANSITIONEFFECTTYPE *)

  (* Reserved Configuration range *)
  OMX_IndexOtherStartUnused                = $08000000;
  OMX_IndexParamOtherPortFormat            = $08000001;  (* reference: OMX_OTHER_PARAM_PORTFORMATTYPE *)
  OMX_IndexConfigOtherPower                = $08000002;  (* reference: OMX_OTHER_CONFIG_POWERTYPE *)
  OMX_IndexConfigOtherStats                = $08000003;  (* reference: OMX_OTHER_CONFIG_STATSTYPE *)

  (* Reserved Time range *)
  OMX_IndexTimeStartUnused                 = $09000000;
  OMX_IndexConfigTimeScale                 = $09000001;  (* reference: OMX_TIME_CONFIG_CLOCKSTATETYPE *)
  OMX_IndexConfigTimeClockState            = $09000002;  (* reference: OMX_TIME_CONFIG_CLOCKSTATETYPE *)
  OMX_IndexConfigTimeActiveRefClock        = $09000003;  (* reference: OMX_TIME_CONFIG_ACTIVEREFCLOCKTYPE *)
  OMX_IndexConfigTimeCurrentMediaTime      = $09000004;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE (read only) *)
  OMX_IndexConfigTimeCurrentWallTime       = $09000005;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE (read only) *)
  OMX_IndexConfigTimeCurrentAudioReference = $09000006;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE (write only) *)
  OMX_IndexConfigTimeCurrentVideoReference = $09000007;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE (write only) *)
  OMX_IndexConfigTimeMediaTimeRequest      = $09000008;  (* reference: OMX_TIME_CONFIG_MEDIATIMEREQUESTTYPE (write only) *)
  OMX_IndexConfigTimeClientStartTime       = $09000009;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE (write only) *)
  OMX_IndexConfigTimePosition              = $0900000A;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE *)
  OMX_IndexConfigTimeSeekMode              = $0900000B;  (* reference: OMX_TIME_CONFIG_SEEKMODETYPE *)

  OMX_IndexParamMarkComparison             = $7F000001;  (* reference: OMX_PARAM_MARKCOMPARISONTYPE *)
  OMX_IndexParamPortSummary                = $7F000002;  (* reference: OMX_PARAM_PORTSUMMARYTYPE *)
  OMX_IndexParamTunnelStatus               = $7F000003;  (* reference: OMX_PARAM_TUNNELSTATUSTYPE *)
  OMX_IndexParamBrcmRecursionUnsafe        = $7F000004;  (* reference: OMX_PARAM_BRCMRECURSIONUNSAFETYPE *)

  (* used for top-ril communication *)
  OMX_IndexParamBufferAddress              = $7F000005;  (* reference : OMX_PARAM_BUFFERADDRESSTYPE *)
  OMX_IndexParamTunnelSetup                = $7F000006;  (* reference : OMX_PARAM_TUNNELSETUPTYPE *)
  OMX_IndexParamBrcmPortEGL                = $7F000007;  (* reference : OMX_PARAM_BRCMPORTEGLTYPE *)
  OMX_IndexParamIdleResourceCount          = $7F000008;  (* reference : OMX_PARAM_U32TYPE *)

  (* used for ril-ril communication *)
  OMX_IndexParamImagePoolDisplayFunction   = $7F000009;  (* reference : OMX_PARAM_IMAGEDISPLAYFUNCTIONTYPE *)
  OMX_IndexParamBrcmDataUnit               = $7F00000A;  (* reference: OMX_PARAM_DATAUNITTYPE *)
  OMX_IndexParamCodecConfig                = $7F00000B;  (* reference: OMX_PARAM_CODECCONFIGTYPE *)
  OMX_IndexParamCameraPoolToEncoderFunction = $7F00000C; (* reference : OMX_PARAM_CAMERAPOOLTOENCODERFUNCTIONTYPE *)
  OMX_IndexParamCameraStripeFunction       = $7F00000D;  (* reference : OMX_PARAM_CAMERASTRIPEFUNCTIONTYPE *)
  OMX_IndexParamCameraCaptureEventFunction = $7F00000E;  (* reference : OMX_PARAM_CAMERACAPTUREEVENTFUNCTIONTYPE *)

  (* used for client-ril communication *)
  OMX_IndexParamTestInterface              = $7F00000F;  (* reference : OMX_PARAM_TESTINTERFACETYPE *)

  // 0x7f000010
  OMX_IndexConfigDisplayRegion             = $7F000010;  (* reference : OMX_CONFIG_DISPLAYREGIONTYPE *)
  OMX_IndexParamSource                     = $7F000011;  (* reference : OMX_PARAM_SOURCETYPE *)
  OMX_IndexParamSourceSeed                 = $7F000012;  (* reference : OMX_PARAM_SOURCESEEDTYPE *)
  OMX_IndexParamResize                     = $7F000013;  (* reference : OMX_PARAM_RESIZETYPE *)
  OMX_IndexConfigVisualisation             = $7F000014;  (* reference : OMX_CONFIG_VISUALISATIONTYPE *)
  OMX_IndexConfigSingleStep                = $7F000015;  (* reference : OMX_PARAM_U32TYPE *)
  OMX_IndexConfigPlayMode                  = $7F000016;  (* reference: OMX_CONFIG_PLAYMODETYPE *)
  OMX_IndexParamCameraCamplusId            = $7F000017;  (* reference : OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCommonImageFilterParameters = $7F000018; (* reference : OMX_CONFIG_IMAGEFILTERPARAMSTYPE *)
  OMX_IndexConfigTransitionControl         = $7F000019;  (* reference : OMX_CONFIG_TRANSITIONCONTROLTYPE *)
  OMX_IndexConfigPresentationOffset        = $7F00001A;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE *)
  OMX_IndexParamSourceFunctions            = $7F00001B;  (* reference: OMX_PARAM_STILLSFUNCTIONTYPE *)
  OMX_IndexConfigAudioMonoTrackControl     = $7F00001C;  (* reference : OMX_CONFIG_AUDIOMONOTRACKCONTROLTYPE *)
  OMX_IndexParamCameraImagePool            = $7F00001D;  (* reference : OMX_PARAM_CAMERAIMAGEPOOLTYPE *)
  OMX_IndexConfigCameraISPOutputPoolHeight = $7F00001E;  (* reference : OMX_PARAM_U32TYPE *)
  OMX_IndexParamImagePoolSize              = $7F00001F;  (* reference: OMX_PARAM_IMAGEPOOLSIZETYPE *)

  // 0x7f000020
  OMX_IndexParamImagePoolExternal          = $7F000020;  (* reference: OMX_PARAM_IMAGEPOOLEXTERNALTYPE *)
  OMX_IndexParamRUTILFifoInfo              = $7F000021;  (* reference: OMX_PARAM_RUTILFIFOINFOTYPE*)
  OMX_IndexParamILFifoConfig               = $7F000022;  (* reference: OMX_PARAM_ILFIFOCONFIG *)
  OMX_IndexConfigCameraSensorModes         = $7F000023;  (* reference : OMX_CONFIG_CAMERASENSORMODETYPE *)
  OMX_IndexConfigBrcmPortStats             = $7F000024;  (* reference : OMX_CONFIG_BRCMPORTSTATSTYPE *)
  OMX_IndexConfigBrcmPortBufferStats       = $7F000025;  (* reference : OMX_CONFIG_BRCMPORTBUFFERSTATSTYPE *)
  OMX_IndexConfigBrcmCameraStats           = $7F000026;  (* reference : OMX_CONFIG_BRCMCAMERASTATSTYPE *)
  OMX_IndexConfigBrcmIOPerfStats           = $7F000027;  (* reference : OMX_CONFIG_BRCMIOPERFSTATSTYPE *)
  OMX_IndexConfigCommonSharpness           = $7F000028;  (* reference : OMX_CONFIG_SHARPNESSTYPE *)
  OMX_IndexConfigCommonFlickerCancellation = $7F000029;  (* reference : OMX_CONFIG_FLICKERCANCELTYPE *)
  OMX_IndexParamCameraSwapImagePools       = $7F00002A;  (* reference : OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamCameraSingleBufferCaptureInput = $7F00002B; (* reference : OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigCommonRedEyeRemoval       = $7F00002C;  (* reference : OMX_CONFIG_REDEYEREMOVALTYPE  *)
  OMX_IndexConfigCommonFaceDetectionControl = $7F00002D; (* reference : OMX_CONFIG_FACEDETECTIONCONTROLTYPE *)
  OMX_IndexConfigCommonFaceDetectionRegion = $7F00002E;  (* reference : OMX_CONFIG_FACEDETECTIONREGIONTYPE *)
  OMX_IndexConfigCommonInterlace           = $7F00002F;  (* reference: OMX_CONFIG_INTERLACETYPE *)

  // 0x7f000030
  OMX_IndexParamISPTunerName               = $7F000030;  (* reference: OMX_PARAM_CAMERAISPTUNERTYPE *)
  OMX_IndexParamCameraDeviceNumber         = $7F000031;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamCameraDevicesPresent       = $7F000032;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCameraInputFrame          = $7F000033;  (* reference: OMX_CONFIG_IMAGEPTRTYPE *)
  OMX_IndexConfigStillColourDenoiseEnable  = $7F000034;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigVideoColourDenoiseEnable  = $7F000035;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigAFAssistLight             = $7F000036;  (* reference: OMX_CONFIG_AFASSISTTYPE *)
  OMX_IndexConfigSmartShakeReductionEnable = $7F000037;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigInputCropPercentages      = $7F000038;  (* reference: OMX_CONFIG_INPUTCROPTYPE *)
  OMX_IndexConfigStillsAntiShakeEnable     = $7F000039;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigWaitForFocusBeforeCapture = $7F00003A;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigAudioRenderingLatency     = $7F00003B;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigDrawBoxAroundFaces        = $7F00003C;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamCodecRequirements          = $7F00003D;  (* reference: OMX_PARAM_CODECREQUIREMENTSTYPE *)
  OMX_IndexConfigBrcmEGLImageMemHandle     = $7F00003E;  (* reference: OMX_CONFIG_BRCMEGLIMAGEMEMHANDLETYPE *)
  OMX_IndexConfigPrivacyIndicator          = $7F00003F;  (* reference: OMX_CONFIG_PRIVACYINDICATORTYPE *)

  // 0x7f000040
  OMX_IndexParamCameraFlashType            = $7F000040;  (* reference: OMX_PARAM_CAMERAFLASHTYPE *)
  OMX_IndexConfigCameraEnableStatsPass     = $7F000041;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigCameraFlashConfig         = $7F000042;  (* reference: OMX_CONFIG_CAMERAFLASHCONFIGTYPE *)
  OMX_IndexConfigCaptureRawImageURI        = $7F000043;  (* reference: OMX_PARAM_CONTENTURITYPE *)
  OMX_IndexConfigCameraStripeFuncMinLines  = $7F000044;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCameraAlgorithmVersionDeprecated = $7F000045; (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCameraIsoReferenceValue   = $7F000046;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCameraCaptureAbortsAutoFocus = $7F000047; (*reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmClockMissCount        = $7F000048;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigFlashChargeLevel          = $7F000049;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmVideoEncodedSliceSize = $7F00004A;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmAudioTrackGaplessPlayback = $7F00004B; (* reference: OMX_CONFIG_BRCMAUDIOTRACKGAPLESSPLAYBACKTYPE *)
  OMX_IndexConfigBrcmAudioTrackChangeControl = $7F00004C; (* reference: OMX_CONFIG_BRCMAUDIOTRACKCHANGECONTROLTYPE *)
  OMX_IndexParamBrcmPixelAspectRatio       = $7F00004D;  (* reference: OMX_CONFIG_POINTTYPE *)
  OMX_IndexParamBrcmPixelValueRange        = $7F00004E;  (* reference: OMX_PARAM_BRCMPIXELVALUERANGETYPE *)
  OMX_IndexParamCameraDisableAlgorithm     = $7F00004F;  (* reference: OMX_PARAM_CAMERADISABLEALGORITHMTYPE *)

  // 0x7f000050
  OMX_IndexConfigBrcmVideoIntraPeriodTime  = $7F000050;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmVideoIntraPeriod      = $7F000051;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmAudioEffectControl    = $7F000052;  (* reference: OMX_CONFIG_BRCMAUDIOEFFECTCONTROLTYPE *)
  OMX_IndexConfigBrcmMinimumProcessingLatency = $7F000053; (* reference: OMX_CONFIG_BRCMMINIMUMPROCESSINGLATENCY *)
  OMX_IndexParamBrcmVideoAVCSEIEnable      = $7F000054;  (* reference: OMX_PARAM_BRCMVIDEOAVCSEIENABLETYPE *)
  OMX_IndexParamBrcmAllowMemChange         = $7F000055;  (* reference: OMX_PARAM_BRCMALLOWMEMCHANGETYPE *)
  OMX_IndexConfigBrcmVideoEncoderMBRowsPerSlice = $7F000056; (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamCameraAFAssistDeviceNumber_Deprecated = $7F000057; (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamCameraPrivacyIndicatorDeviceNumber_Deprecated = $7F000058; (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCameraUseCase             = $7F000059;  (* reference: OMX_CONFIG_CAMERAUSECASETYPE *)
  OMX_IndexParamBrcmDisableProprietaryTunnels = $7F00005A; (* reference: OMX_PARAM_BRCMDISABLEPROPRIETARYTUNNELSTYPE *)
  OMX_IndexParamBrcmOutputBufferSize       = $7F00005B;  (*  reference: OMX_PARAM_BRCMOUTPUTBUFFERSIZETYPE *)
  OMX_IndexParamBrcmRetainMemory           = $7F00005C;  (* reference: OMX_PARAM_BRCMRETAINMEMORYTYPE *)
  OMX_IndexConfigCanFocus_Deprecated       = $7F00005D;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmImmutableInput         = $7F00005E;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamDynamicParameterFile       = $7F00005F;  (* reference: OMX_PARAM_CONTENTURITYPE *)

  // 0x7f000060
  OMX_IndexParamUseDynamicParameterFile    = $7F000060;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigCameraInfo                = $7F000061;  (* reference: OMX_CONFIG_CAMERAINFOTYPE *)
  OMX_IndexConfigCameraFeatures            = $7F000062;  (* reference: OMX_CONFIG_CAMERAFEATURESTYPE *)
  OMX_IndexConfigRequestCallback           = $7F000063;  (* reference: OMX_CONFIG_REQUESTCALLBACKTYPE *) // Should be added to the spec as part of IL416c
  OMX_IndexConfigBrcmOutputBufferFullCount = $7F000064;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCommonFocusRegionXY       = $7F000065;  (* reference: OMX_CONFIG_FOCUSREGIONXYTYPE *)
  OMX_IndexParamBrcmDisableEXIF            = $7F000066;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigUserSettingsId            = $7F000067;  (* reference: OMX_CONFIG_U8TYPE *)
  OMX_IndexConfigCameraSettings            = $7F000068;  (* reference: OMX_CONFIG_CAMERASETTINGSTYPE *)
  OMX_IndexConfigDrawBoxLineParams         = $7F000069;  (* reference: OMX_CONFIG_DRAWBOXLINEPARAMS *)
  OMX_IndexParamCameraRmiControl_Deprecated = $7F00006A; (* reference: OMX_PARAM_CAMERARMITYPE *)
  OMX_IndexConfigBurstCapture              = $7F00006B;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmEnableIJGTableScaling  = $7F00006C;  (* reference: OMX_PARAM_IJGSCALINGTYPE *)
  OMX_IndexConfigPowerDown                 = $7F00006D;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmSyncOutput            = $7F00006E;  (* reference: OMX_CONFIG_BRCMSYNCOUTPUTTYPE *)
  OMX_IndexParamBrcmFlushCallback          = $7F00006F;  (* reference: OMX_PARAM_BRCMFLUSHCALLBACK *)

  // 0x7f000070
  OMX_IndexConfigBrcmVideoRequestIFrame    = $7F000070;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmNALSSeparate           = $7F000071;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigConfirmView               = $7F000072;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigDrmView                   = $7F000073;  (* reference: OMX_CONFIG_DRMVIEWTYPE *)
  OMX_IndexConfigBrcmVideoIntraRefresh     = $7F000074;  (* reference: OMX_VIDEO_PARAM_INTRAREFRESHTYPE *)
  OMX_IndexParamBrcmMaxFileSize            = $7F000075;  (* reference: OMX_PARAM_BRCMU64TYPE *)
  OMX_IndexParamBrcmCRCEnable              = $7F000076;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmCRC                    = $7F000077;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigCameraRmiInUse_Deprecated = $7F000078;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmAudioSource           = $7F000079;  (* reference: OMX_CONFIG_BRCMAUDIOSOURCETYPE *)
  OMX_IndexConfigBrcmAudioDestination      = $7F00007A;  (* reference: OMX_CONFIG_BRCMAUDIODESTINATIONTYPE *)
  OMX_IndexParamAudioDdp                   = $7F00007B;  (* reference: OMX_AUDIO_PARAM_DDPTYPE *)
  OMX_IndexParamBrcmThumbnail              = $7F00007C;  (* reference: OMX_PARAM_BRCMTHUMBNAILTYPE *)
  OMX_IndexParamBrcmDisableLegacyBlocks_Deprecated = $7F00007D; (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmCameraInputAspectRatio = $7F00007E;  (* reference: OMX_PARAM_BRCMASPECTRATIOTYPE *)
  OMX_IndexParamDynamicParameterFileFailFatal = $7F00007F; (* reference: OMX_CONFIG_BOOLEANTYPE *)

  // 0x7f000080
  OMX_IndexParamBrcmVideoDecodeErrorConcealment = $7F000080; (* reference: OMX_PARAM_BRCMVIDEODECODEERRORCONCEALMENTTYPE *)
  OMX_IndexParamBrcmInterpolateMissingTimestamps = $7F000081; (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmSetCodecPerformanceMonitoring = $7F000082; (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigFlashInfo                 = $7F000083;  (* reference: OMX_CONFIG_FLASHINFOTYPE *)
  OMX_IndexParamBrcmMaxFrameSkips          = $7F000084;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigDynamicRangeExpansion     = $7F000085;  (* reference: OMX_CONFIG_DYNAMICRANGEEXPANSIONTYPE *)
  OMX_IndexParamBrcmFlushCallbackId        = $7F000086;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmTransposeBufferCount   = $7F000087;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigFaceRecognitionControl    = $7F000088;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigFaceRecognitionSaveFace   = $7F000089;  (* reference: OMX_PARAM_BRCMU64TYPE *)
  OMX_IndexConfigFaceRecognitionDatabaseUri = $7F00008A; (* reference: OMX_PARAM_CONTENTURITYPE *)
  OMX_IndexConfigClockAdjustment           = $7F00008B;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE *)
  OMX_IndexParamBrcmThreadAffinity         = $7F00008C;  (* reference: OMX_PARAM_BRCMTHREADAFFINITYTYPE *)
  OMX_IndexParamAsynchronousOutput         = $7F00008D;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigAsynchronousFailureURI    = $7F00008E;  (* reference: OMX_PARAM_CONTENTURITYPE *)
  OMX_IndexConfigCommonFaceBeautification  = $7F00008F;  (* reference: OMX_CONFIG_BOOLEANTYPE *)

  // 0x7f000090
  OMX_IndexConfigCommonSceneDetectionControl = $7F000090; (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigCommonSceneDetected       = $7F000091;  (* reference: OMX_CONFIG_SCENEDETECTTYPE *)
  OMX_IndexParamDisableVllPool             = $7F000092;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamVideoMvc                   = $7F000093;  (* reference: OMX_VIDEO_PARAM_MVCTYPE *)
  OMX_IndexConfigBrcmDrawStaticBox         = $7F000094;  (* reference: OMX_CONFIG_STATICBOXTYPE *)
  OMX_IndexConfigBrcmClockReferenceSource  = $7F000095;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamPassBufferMarks            = $7F000096;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigPortCapturing             = $7F000097;  (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexConfigBrcmDecoderPassThrough    = $7F000098;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmDecoderPassThrough     = OMX_IndexConfigBrcmDecoderPassThrough;  (* deprecated *)
  OMX_IndexParamBrcmMaxCorruptMBs          = $7F000099;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmGlobalAudioMute       = $7F00009A;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamCameraCaptureMode          = $7F00009B;  (* reference: OMX_PARAM_CAMERACAPTUREMODETYPE *)
  OMX_IndexParamBrcmDrmEncryption          = $7F00009C;  (* reference: OMX_PARAM_BRCMDRMENCRYPTIONTYPE *)
  OMX_IndexConfigBrcmCameraRnDPreprocess   = $7F00009D;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmCameraRnDPostprocess  = $7F00009E;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmAudioTrackChangeCount = $7F00009F;  (* reference: OMX_PARAM_U32TYPE *)

  // 0x7f0000a0
  OMX_IndexParamCommonUseStcTimestamps     = $7F0000A0;  (* reference: OMX_PARAM_TIMESTAMPMODETYPE *)
  OMX_IndexConfigBufferStall               = $7F0000A1;  (* reference: OMX_CONFIG_BUFFERSTALLTYPE *)
  OMX_IndexConfigRefreshCodec              = $7F0000A2;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamCaptureStatus              = $7F0000A3;  (* reference: OMX_PARAM_CAPTURESTATETYPE *)
  OMX_IndexConfigTimeInvalidStartTime      = $7F0000A4;  (* reference: OMX_TIME_CONFIG_TIMESTAMPTYPE *)
  OMX_IndexConfigLatencyTarget             = $7F0000A5;  (* reference: OMX_CONFIG_LATENCYTARGETTYPE *)
  OMX_IndexConfigMinimiseFragmentation     = $7F0000A6;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmUseProprietaryCallback = $7F0000A7; (* reference: OMX_CONFIG_BRCMUSEPROPRIETARYTUNNELTYPE *)
  OMX_IndexParamPortMaxFrameSize           = $7F0000A8;  (* reference: OMX_FRAMESIZETYPE *)
  OMX_IndexParamComponentName              = $7F0000A9;  (* reference: OMX_PARAM_COMPONENTROLETYPE *)
  OMX_IndexConfigEncLevelExtension         = $7F0000AA;  (* reference: OMX_VIDEO_CONFIG_LEVEL_EXTEND *)
  OMX_IndexConfigTemporalDenoiseEnable     = $7F0000AB;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmLazyImagePoolDestroy   = $7F0000AC;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmEEDEEnable             = $7F0000AD;  (* reference: OMX_VIDEO_EEDE_ENABLE *)
  OMX_IndexParamBrcmEEDELossRate           = $7F0000AE;  (* reference: OMX_VIDEO_EEDE_LOSSRATE *)
  OMX_IndexParamAudioDts                   = $7F0000AF;  (* reference: OMX_AUDIO_PARAM_DTSTYPE *)

  // 0x7f0000b0
  OMX_IndexParamNumOutputChannels          = $7F0000B0;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmHighDynamicRange      = $7F0000B1;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmPoolMemAllocSize      = $7F0000B2;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmBufferFlagFilter      = $7F0000B3;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmVideoEncodeMinQuant    = $7F0000B4;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmVideoEncodeMaxQuant    = $7F0000B5;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamRateControlModel           = $7F0000B6;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmExtraBuffers           = $7F0000B7;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigFieldOfView               = $7F0000B8;  (* reference: OMX_CONFIG_BRCMFOVTYPE *)
  OMX_IndexParamBrcmAlignHoriz             = $7F0000B9;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmAlignVert              = $7F0000BA;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamColorSpace                 = $7F0000BB;  (* reference: OMX_PARAM_COLORSPACETYPE *)
  OMX_IndexParamBrcmDroppablePFrames       = $7F0000BC;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmVideoInitialQuant      = $7F0000BD;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmVideoEncodeQpP         = $7F0000BE;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmVideoRCSliceDQuant     = $7F0000BF;  (* reference: OMX_PARAM_U32TYPE *)

  // 0x7f0000c0
  OMX_IndexParamBrcmVideoFrameLimitBits    = $7F0000C0;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmVideoPeakRate          = $7F0000C1;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmVideoH264DisableCABAC = $7F0000C2;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmVideoH264LowLatency   = $7F0000C3;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmVideoH264AUDelimiters = $7F0000C4;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmVideoH264DeblockIDC   = $7F0000C5;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigBrcmVideoH264IntraMBMode  = $7F0000C6;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexConfigContrastEnhance           = $7F0000C7;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamCameraCustomSensorConfig   = $7F0000C8;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmHeaderOnOpen           = $7F0000C9;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmUseRegisterFile       = $7F0000CA;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmRegisterFileFailFatal = $7F0000CB;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmConfigFileRegisters    = $7F0000CC;  (* reference: OMX_PARAM_BRCMCONFIGFILETYPE *)
  OMX_IndexParamBrcmConfigFileChunkRegisters = $7F0000CD; (* reference: OMX_PARAM_BRCMCONFIGFILECHUNKTYPE *)
  OMX_IndexParamBrcmAttachLog              = $7F0000CE;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamCameraZeroShutterLag       = $7F0000CF;  (* reference: OMX_CONFIG_ZEROSHUTTERLAGTYPE *)

  // 0x7f0000d0
  OMX_IndexParamBrcmFpsRange               = $7F0000D0;  (* reference: OMX_PARAM_BRCMFRAMERATERANGETYPE *)
  OMX_IndexParamCaptureExposureCompensation = $7F0000D1; (* reference: OMX_PARAM_S32TYPE *)
  OMX_IndexParamBrcmVideoPrecodeForQP      = $7F0000D2;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmVideoTimestampFifo     = $7F0000D3;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamSWSharpenDisable           = $7F0000D4;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexConfigBrcmFlashRequired         = $7F0000D5;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmVideoDrmProtectBuffer  = $7F0000D6;  (* reference: OMX_PARAM_BRCMVIDEODRMPROTECTBUFFERTYPE *)
  OMX_IndexParamSWSaturationDisable        = $7F0000D7;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmVideoDecodeConfigVD3   = $7F0000D8;  (* reference: OMX_PARAM_BRCMVIDEODECODECONFIGVD3TYPE *)
  OMX_IndexConfigBrcmPowerMonitor          = $7F0000D9;  (* reference: OMX_CONFIG_BOOLEANTYPE *)
  OMX_IndexParamBrcmZeroCopy               = $7F0000DA;  (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexParamBrcmVideoEGLRenderDiscardMode = $7F0000DB; (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexParamBrcmVideoAVC_VCLHRDEnable  = $7F0000DC;  (* reference: OMX_CONFIG_PORTBOOLEANTYPE*)
  OMX_IndexParamBrcmVideoAVC_LowDelayHRDEnable = $7F0000DD; (* reference: OMX_CONFIG_PORTBOOLEANTYPE*)
  OMX_IndexParamBrcmVideoCroppingDisable   = $7F0000DE;  (* reference: OMX_CONFIG_PORTBOOLEANTYPE*)
  OMX_IndexParamBrcmVideoAVCInlineHeaderEnable = $7F0000DF; (* reference: OMX_CONFIG_PORTBOOLEANTYPE*)

  // 0x7f0000f0
  OMX_IndexConfigBrcmAudioDownmixCoefficients = $7F0000F0; (* reference: OMX_CONFIG_BRCMAUDIODOWNMIXCOEFFICIENTS *)
  OMX_IndexConfigBrcmAudioDownmixCoefficients8x8 = $7F0000F1; (* reference: OMX_CONFIG_BRCMAUDIODOWNMIXCOEFFICIENTS8x8 *)
  OMX_IndexConfigBrcmAudioMaxSample        = $7F0000F2;  (* reference: OMX_CONFIG_BRCMAUDIOMAXSAMPLE *)
  OMX_IndexConfigCustomAwbGains            = $7F0000F3;  (* reference: OMX_CONFIG_CUSTOMAWBGAINSTYPE *)
  OMX_IndexParamRemoveImagePadding         = $7F0000F4;  (* reference: OMX_CONFIG_PORTBOOLEANTYPE*)
  OMX_IndexParamBrcmVideoAVCInlineVectorsEnable = $7F0000F5; (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexConfigBrcmRenderStats           = $7F0000F6;  (* reference: OMX_CONFIG_BRCMRENDERSTATSTYPE *)
  OMX_IndexConfigBrcmCameraAnnotate        = $7F0000F7;  (* reference: OMX_CONFIG_BRCMANNOTATETYPE *)
  OMX_IndexParamBrcmStereoscopicMode       = $7F0000F8;  (* reference :OMX_CONFIG_BRCMSTEREOSCOPICMODETYPE *)
  OMX_IndexParamBrcmLockStepEnable         = $7F0000F9;  (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexParamBrcmTimeScale              = $7F0000FA;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamCameraInterface            = $7F0000FB;  (* reference: OMX_PARAM_CAMERAINTERFACETYPE *)
  OMX_IndexParamCameraClockingMode         = $7F0000FC;  (* reference: OMX_PARAM_CAMERACLOCKINGMODETYPE *)
  OMX_IndexParamCameraRxConfig             = $7F0000FD;  (* reference: OMX_PARAM_CAMERARXCONFIG_TYPE *)
  OMX_IndexParamCameraRxTiming             = $7F0000FE;  (* reference: OMX_PARAM_CAMERARXTIMING_TYPE *)
  OMX_IndexParamDynamicParameterConfig     = $7F0000FF;  (* reference: OMX_PARAM_U32TYPE *)

  // 0x7f000100
  OMX_IndexParamBrcmVideoAVCSPSTimingEnable = $7F000100; (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexParamBrcmBayerOrder             = $7F000101;  (* reference: OMX_PARAM_BAYERORDERTYPE *)
  OMX_IndexParamBrcmMaxNumCallbacks        = $7F000102;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmJpegRestartInterval    = $7F000103;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmSupportsSlices         = $7F000104;  (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexParamBrcmIspBlockOverride       = $7F000105;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamBrcmSupportsUnalignedSliceheight = $7F000106; (* reference: OMX_CONFIG_PORTBOOLEANTYPE *)
  OMX_IndexParamBrcmLensShadingOverride    = $7F000107;  (* reference: OMX_PARAM_LENSSHADINGOVERRIDETYPE *)
  OMX_IndexParamBrcmBlackLevel             = $7F000108;  (* reference: OMX_PARAM_U32TYPE *)
  OMX_IndexParamOutputShift                = $7F000109;  (* reference: OMX_PARAM_S32TYPE *)
  OMX_IndexParamCcmShift                   = $7F00010A;  (* reference: OMX_PARAM_S32TYPE *)
  OMX_IndexParamCustomCcm                  = $7F00010B;  (* reference: OMX_PARAM_CUSTOMCCMTYPE *)
  OMX_IndexMax                             = $7FFFFFFF;

type
  OMX_U8                                   = uint8;
  POMX_U8                                  = ^OMX_U8;
  PPOMX_U8                                 = ^POMX_U8;
  OMX_S8                                   = Int8;
  OMX_U16                                  = uint16;
  OMX_S16                                  = Int16;
  OMX_U32                                  = uint32;
  POMX_U32                                 = ^OMX_U32;
  OMX_S32                                  = integer;
  OMX_U64                                  = uint64;
  OMX_S64                                  = Int64;
  OMX_BOOL                                 = LongBool;
  OMX_PTR                                  = pointer;
  OMX_STRING                               = PChar;
  OMX_CHAR                                 = Char;

  OMX_HANDLETYPE                           = pointer;
  POMX_HANDLETYPE                          = ^OMX_HANDLETYPE;
  OMX_NATIVE_DEVICETYPE                    = pointer;
  OMX_NATIVE_WINDOWTYPE                    = pointer;
  OMX_UUIDTYPE                             = array [0 .. 127] of byte;
  POMX_UUIDTYPE                            = ^OMX_UUIDTYPE;

  OMX_ENDIANTYPE                           = LongWord;
  OMX_NUMERICALDATATYPE                    = LongWord;
  OMX_PORTDOMAINTYPE                       = Longword;
  OMX_ERRORTYPE                            = Longword;
  OMX_EVENTTYPE                            = LongWord;
  OMX_BUFFERSUPPLIERTYPE                   = LongWord;
  OMX_DIRTYPE                              = LongWord;
  OMX_COMMANDTYPE                          = LongWord;
  OMX_STATETYPE                            = LongWord;
  OMX_INDEXTYPE                            = LongWord;
  OMX_AUDIO_CODINGTYPE                     = LongWord;
  OMX_VIDEO_CODINGTYPE                     = LongWord;
  OMX_COLOR_FORMATTYPE                     = LongWord;
  OMX_OTHER_FORMATTYPE                     = LongWord;
  OMX_IMAGE_CODINGTYPE                     = LongWord;
  OMX_TIME_CLOCKSTATE                      = LongWord;
  OMX_AUDIO_PCMMODETYPE                    = LongWord;
  OMX_AUDIO_CHANNELTYPE                    = Longword;
  OMX_DISPLAYTRANSFORMTYPE                 = LongWord;
  OMX_DISPLAYMODETYPE                      = LongWord;
  OMX_DISPLAYSETTYPE                       = LongWord;
  OMX_SOURCETYPE                           = LongWord;
  OMX_RESIZEMODETYPE                       = LongWord;
  OMX_PLAYMODETYPE                         = LongWord;
  OMX_DELIVERYFORMATTYPE                   = LongWord;
  OMX_BUFFERADDRESSHANDLETYPE              = pointer;
  OMX_AUDIOMONOTRACKOPERATIONSTYPE         = LongWord;
  OMX_CAMERAIMAGEPOOLINPUTMODETYPE         = LongWord;
  OMX_COMMONFLICKERCANCELTYPE              = LongWord;
  OMX_REDEYEREMOVALTYPE                    = Longword;
  OMX_FACEDETECTIONCONTROLTYPE             = LongWord;
  OMX_FACEREGIONFLAGSTYPE                  = LongWord;
  OMX_INTERLACETYPE                        = LongWord;
  OMX_AFASSISTTYPE                         = LongWord;
  OMX_PRIVACYINDICATORTYPE                 = LongWord;
  OMX_CAMERAFLASHTYPE                      = LongWord;
  OMX_CAMERAFLASHCONFIGSYNCTYPE            = LongWord;
  OMX_BRCMPIXELVALUERANGETYPE              = LongWord;
  OMX_CAMERADISABLEALGORITHMTYPE           = LongWord;
  OMX_CONFIG_CAMERAUSECASE                 = LongWord;
  OMX_CONFIG_CAMERAFEATURESSHUTTER         = LongWord;
  OMX_FOCUSREGIONTYPE                      = LongWord;
  OMX_DYNAMICRANGEEXPANSIONMODETYPE        = LongWord;
  OMX_BRCMTHREADAFFINITYTYPE               = LongWord;
  OMX_SCENEDETECTTYPE                      = LongWord;
  OMX_INDEXEXTTYPE                         = LongWord;
  OMX_NALUFORMATSTYPE                      = LongWord;
  OMX_STATICBOXTYPE                        = LongWord;
  OMX_CAMERACAPTUREMODETYPE                = LongWord;
  OMX_BRCMDRMENCRYPTIONTYPE                = LongWord;
  OMX_TIMESTAMPMODETYPE                    = LongWord;
  OMX_COLORSPACETYPE                       = LongWord;
  OMX_CAPTURESTATETYPE                     = LongWord;
  OMX_BRCMSTEREOSCOPICMODETYPE             = LongWord;
  OMX_CAMERAINTERFACETYPE                  = LongWord;
  OMX_CAMERACLOCKINGMODETYPE               = LongWord;
  OMX_CAMERARXDECODETYPE                   = LongWord;
  OMX_CAMERARXENCODETYPE                   = LongWord;
  OMX_CAMERARXUNPACKTYPE                   = LongWord;
  OMX_CAMERARXPACKTYPE                     = LongWord;
  OMX_BAYERORDERTYPE                       = LongWord;

// forward declarations

  POMX_VERSIONTYPE                         = ^OMX_VERSIONTYPE;
  POMX_PORT_PARAM_TYPE                     = ^OMX_PORT_PARAM_TYPE;
  POMX_PARAM_U32TYPE                        = ^OMX_PARAM_U32TYPE;
  POMX_TICKS                               = ^OMX_TICKS;
  POMX_BUFFERHEADERTYPE                    = ^OMX_BUFFERHEADERTYPE;
  PPOMX_BUFFERHEADERTYPE                   = ^POMX_BUFFERHEADERTYPE;
  POMX_CONFIG_SCALEFACTORTYPE              = ^OMX_CONFIG_SCALEFACTORTYPE;
  POMX_CALLBACKTYPE                        = ^OMX_CALLBACKTYPE;
  POMX_TUNNELSETUPTYPE                     = ^OMX_TUNNELSETUPTYPE;
  POMX_STATETYPE                           = ^OMX_STATETYPE;
  POMX_INDEXTYPE                           = ^OMX_INDEXTYPE;
  POMX_COMPONENTTYPE                       = ^OMX_COMPONENTTYPE;
  POMX_AUDIO_PORTDEFINITIONTYPE            = ^OMX_AUDIO_PORTDEFINITIONTYPE;
  POMX_VIDEO_CODINGTYPE                    = ^OMX_VIDEO_CODINGTYPE;
  POMX_VIDEO_PORTDEFINITIONTYPE            = ^OMX_VIDEO_PORTDEFINITIONTYPE;
  POMX_IMAGE_PORTDEFINITIONTYPE            = ^OMX_IMAGE_PORTDEFINITIONTYPE;
  POMX_VIDEO_PARAM_PORTFORMATTYPE          = ^OMX_VIDEO_PARAM_PORTFORMATTYPE;
  POMX_IMAGE_CODINGTYPE                    = ^OMX_IMAGE_CODINGTYPE;
  POMX_OTHER_PORTDEFINITIONTYPE            = ^OMX_OTHER_PORTDEFINITIONTYPE;
  POMX_BRCM_POOL_T                         = ^OMX_BRCM_POOL_T;
  P_IL_FIFO_T                              = ^_IL_FIFO_T;

  {$PACKRECORDS C}

  OMX_MARKTYPE = record
    hMarkTargetComponent : OMX_HANDLETYPE;               (* The component that will
                                                            generate a mark event upon
                                                            processing the mark. *)
    pMarkData : OMX_PTR;                                 (* Application specific data associated with
                                                            the mark sent on a mark event to disambiguate
                                                            this mark from others. *)
  end;

  OMX_VERSIONTYPE = record
    case boolean of
      false :
        (
          nVersionMajor : OMX_U8;                        (* Major version accessor element *)
          nVersionMinor : OMX_U8;                        (* Minor version accessor element *)
          nRevision : OMX_U8;                            (* Revision version accessor element *)
          nStep : OMX_U8;                                (* Step version accessor element *)
        );
      true :
        (
          nVersion : OMX_U32;                            (* 32 bit value to make accessing the
                                                            version easily done in a single word
                                                            size copy/compare operation *)
        )
  end;

  OMX_PARAM_U32TYPE = record
    nSize : OMX_U32;                                     (* Size of this structure, in Bytes *)
    nVersion : OMX_VERSIONTYPE;                          (* OMX specification version information *)
    nPortIndex : OMX_U32;                                (* port that this structure applies to *)
    nU32 : OMX_U32;                                      (* U32 value *)
  end;

  OMX_PORT_PARAM_TYPE = record
    nSize : OMX_U32;                                     (* size of the structure in bytes *)
    nVersion : OMX_VERSIONTYPE;                          (* OMX specification version information *)
    nPorts : OMX_U32;                                    (* The number of ports for this component *)
    nStartPortNumber : OMX_U32;                          (* first port number for this type of port *)
  end;

  OMX_TICKS = record
    nLowPart : OMX_U32;                                  (* low bits of the signed 64 bit tick value *)
    nHighPart : OMX_U32;                                 (* high bits of the signed 64 bit tick value *)
  end;

  OMX_BUFFERHEADERTYPE = record
    nSize : OMX_U32;                                     (* size of the structure in bytes *)
    nVersion : OMX_VERSIONTYPE;                          (* OMX specification version information *)
    pBuffer : POMX_U8;                                   (* Pointer to actual block of memory
                                                            that is acting as the buffer *)
    nAllocLen : OMX_U32;                                 (* size of the buffer allocated, in bytes *)
    nFilledLen : OMX_U32;                                (* number of bytes currently in the buffer *)
    nOffset : OMX_U32;                                   (* start offset of valid data in bytes from
                                                            the start of the buffer *)
    pAppPrivate : OMX_PTR;                               (* pointer to any data the application
                                                            wants to associate with this buffer *)
    pPlatformPrivate  : OMX_PTR;                         (* pointer to any data the platform
                                                            wants to associate with this buffer *)
    pInputPortPrivate : OMX_PTR;                         (* pointer to any data the input port
                                                            wants to associate with this buffer *)
    pOutputPortPrivate  : OMX_PTR;                       (* pointer to any data the output port
                                                            wants to associate with this buffer *)
    hMarkTargetComponent : OMX_HANDLETYPE;               (* The component that will generate a
                                                            mark event upon processing this buffer. *)
    pMarkData : OMX_PTR;                                 (* Application specific data associated with
                                                            the mark sent on a mark event to disambiguate
                                                            this mark from others. *)
    nTickCount : OMX_U32;                                (* Optional entry that the component and
                                                            application can update with a tick count
                                                            when they access the component.  This
                                                            value should be in microseconds.  Since
                                                            this is a value relative to an arbitrary
                                                            starting point, this value cannot be used
                                                            to determine absolute time.  This is an
                                                            optional entry and not all components
                                                            will update it.*)
    nTimeStamp : OMX_TICKS;                              (* Timestamp corresponding to the sample
                                                            starting at the first logical sample
                                                            boundary in the buffer. Timestamps of
                                                            successive samples within the buffer may
                                                            be inferred by adding the duration of the
                                                            of the preceding buffer to the timestamp
                                                            of the preceding buffer.*)
    nFlags : OMX_U32;                                    (* buffer specific flags *)
    nOutputPortIndex : OMX_U32;                          (* The index of the output port (if any) using
                                                            this buffer *)
    nInputPortIndex : OMX_U32;                           (* The index of the input port (if any) using
                                                            this buffer *)
  end;

  OMX_CONFIG_SCALEFACTORTYPE = record
    nSize: OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    xWidth : OMX_S32;
    xHeight : OMX_S32;
  end;

  TEventHandler = function (hComponent : OMX_HANDLETYPE;
                            pAppData : OMX_PTR;
                            eEvent : OMX_EVENTTYPE;
                            nData1 : OMX_U32;
                            nData2 : OMX_U32;
                            pEventData : OMX_PTR) : OMX_ERRORTYPE; cdecl;

  TFillBufferDone = function (hComponent : OMX_HANDLETYPE;
                              pAppData : OMX_PTR;
                              pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE; cdecl;

  TEmptyBufferDone = function (hComponent : OMX_HANDLETYPE;
                               pAppData : OMX_PTR;
                               pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE; cdecl;


  OMX_CALLBACKTYPE = record
    EventHandler : TEventHandler;                        (* The EventHandler method is used to notify the application when an
                                                            event of interest occurs.  Events are defined in the OMX_EVENTTYPE
                                                            enumeration.  Please see that enumeration for details of what will
                                                            be returned for each type of event. Callbacks should not return
                                                            an error to the component, so if an error occurs, the application
                                                            shall handle it internally.  This is a blocking call.

                                                            The application should return from this call within 5 msec to avoid
                                                            blocking the component for an excessively long period of time.

                                                            @param hComponent
                                                                handle of the component to access.  This is the component
                                                                handle returned by the call to the GetHandle function.
                                                            @param pAppData
                                                                pointer to an application defined value that was provided in the
                                                                pAppData parameter to the OMX_GetHandle method for the component.
                                                                This application defined value is provided so that the application
                                                                can have a component specific context when receiving the callback.
                                                            @param eEvent
                                                                Event that the component wants to notify the application about.
                                                            @param nData1
                                                                nData will be the OMX_ERRORTYPE for an error event and will be
                                                                an OMX_COMMANDTYPE for a command complete event and OMX_INDEXTYPE for a OMX_PortSettingsChanged event.
                                                             @param nData2
                                                                nData2 will hold further information related to the event. Can be OMX_STATETYPE for
                                                                a OMX_CommandStateSet command or port index for a OMX_PortSettingsChanged event.
                                                                Default value is 0 if not used. )
                                                            @param pEventData
                                                                Pointer to additional event-specific data (see spec for meaning).   *)
    EmptyBufferDone : TEmptyBufferDone;                  (* The EmptyBufferDone method is used to return emptied buffers from an
                                                            input port back to the application for reuse.  This is a blocking call
                                                            so the application should not attempt to refill the buffers during this
                                                            call, but should queue them and refill them in another thread.  There
                                                            is no error return, so the application shall handle any errors generated
                                                            internally.

                                                            The application should return from this call within 5 msec.

                                                            @param hComponent
                                                                handle of the component to access.  This is the component
                                                                handle returned by the call to the GetHandle function.
                                                            @param pAppData
                                                                pointer to an application defined value that was provided in the
                                                                pAppData parameter to the OMX_GetHandle method for the component.
                                                                This application defined value is provided so that the application
                                                                can have a component specific context when receiving the callback.
                                                            @param pBuffer
                                                                pointer to an OMX_BUFFERHEADERTYPE structure allocated with UseBuffer
                                                                or AllocateBuffer indicating the buffer that was emptied.   *)

    FillBufferDone : TFillBufferDone;                    (* The FillBufferDone method is used to return filled buffers from an
                                                            output port back to the application for emptying and then reuse.
                                                            This is a blocking call so the application should not attempt to
                                                            empty the buffers during this call, but should queue the buffers
                                                            and empty them in another thread.  There is no error return, so
                                                            the application shall handle any errors generated internally.  The
                                                            application shall also update the buffer header to indicate the
                                                            number of bytes placed into the buffer.

                                                            The application should return from this call within 5 msec.

                                                            @param hComponent
                                                                handle of the component to access.  This is the component
                                                                handle returned by the call to the GetHandle function.
                                                            @param pAppData
                                                                pointer to an application defined value that was provided in the
                                                                pAppData parameter to the OMX_GetHandle method for the component.
                                                                This application defined value is provided so that the application
                                                                can have a component specific context when receiving the callback.
                                                            @param pBuffer
                                                                pointer to an OMX_BUFFERHEADERTYPE structure allocated with UseBuffer
                                                                or AllocateBuffer indicating the buffer that was filled. *)
  end;

  OMX_TUNNELSETUPTYPE = record
    nTunnelFlags : OMX_U32;                              (* bit flags for tunneling *)
    eSupplier : OMX_BUFFERSUPPLIERTYPE;                  (* supplier preference *)
  end;

  TGetComponentVersion = function (hComponent  : OMX_HANDLETYPE;
                                   pComponentName : OMX_STRING;
                                   pComponentVersion : POMX_VERSIONTYPE;
                                   pSpecVersion : POMX_VERSIONTYPE;
                                   pComponentUUID : POMX_UUIDTYPE) : OMX_ERRORTYPE; cdecl;

  TSendCommand = function (hComponent : OMX_HANDLETYPE;
                           Cmd : OMX_COMMANDTYPE;
                           nParam1 : OMX_U32;
                           pCmdData : OMX_PTR) : OMX_ERRORTYPE; cdecl;

  TGetParameter = function (hComponent : OMX_HANDLETYPE;
                            nParamIndex : OMX_INDEXTYPE;
                            pComponentParameterStructure : OMX_PTR) : OMX_ERRORTYPE; cdecl;

  TSetParameter = function (hComponent : OMX_HANDLETYPE;
                            nIndex : OMX_INDEXTYPE;
                            pComponentParameterStructure : OMX_PTR) : OMX_ERRORTYPE; cdecl;

  TGetConfig = function (hComponent : OMX_HANDLETYPE;
                         nIndex : OMX_INDEXTYPE;
                         pComponentConfigStructure : OMX_PTR) : OMX_ERRORTYPE; cdecl;

  TSetConfig = function (hComponent : OMX_HANDLETYPE;
                         nIndex : OMX_INDEXTYPE;
                         pComponentConfigStructure : OMX_PTR) : OMX_ERRORTYPE; cdecl;

  TGetExtensionIndex = function (hComponent : OMX_HANDLETYPE;
                                 cParameterName : OMX_STRING;
                                 pIndexType : POMX_INDEXTYPE) : OMX_ERRORTYPE; cdecl;

  TGetState = function (hComponent : OMX_HANDLETYPE;
                        pState : POMX_STATETYPE) : OMX_ERRORTYPE; cdecl;

  TComponentTunnelRequest = function (hComp : OMX_HANDLETYPE;
                                      nPort : OMX_U32;
                                      hTunneledComp : OMX_HANDLETYPE;
                                      nTunneledPort : OMX_U32;
                                      pTunnelSetup : POMX_TUNNELSETUPTYPE) : OMX_ERRORTYPE; cdecl;

  TUseBuffer = function (hComponent : OMX_HANDLETYPE;
                         ppBufferHdr : PPOMX_BUFFERHEADERTYPE;
                         nPortIndex : OMX_U32;
                         pAppPrivate : OMX_PTR;
                         nSizeBytes : OMX_U32;
                         pBuffer : POMX_U8) : OMX_ERRORTYPE; cdecl;

  TAllocateBuffer = function (hComponent : OMX_HANDLETYPE;
                              ppBuffer : PPOMX_BUFFERHEADERTYPE;
                              nPortIndex : OMX_U32;
                              pAppPrivate : OMX_PTR;
                              nSizeBytes : OMX_U32) : OMX_ERRORTYPE; cdecl;

  TFreeBuffer = function (hComponent : OMX_HANDLETYPE;
                          nPortIndex : OMX_U32;
                          pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE; cdecl;

  TEmptyThisBuffer = function (hComponent : OMX_HANDLETYPE;
                               pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE; cdecl;

  TFillThisBuffer = function (hComponent : OMX_HANDLETYPE;
                              pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE; cdecl;

  TSetCallbacks = function (hComponent : OMX_HANDLETYPE;
                            pCallbacks : POMX_CALLBACKTYPE;
                            pAppData : OMX_PTR) : OMX_ERRORTYPE; cdecl;

  TComponentDeInit = function (hComponent : OMX_HANDLETYPE) : OMX_ERRORTYPE; cdecl;

  TUseEGLImage = function (hComponent : OMX_HANDLETYPE;
                           ppBufferHdr : PPOMX_BUFFERHEADERTYPE;
                           nPortIndex : OMX_U32;
                           pAppPrivate : OMX_PTR;
                           eglImage : Pointer) : OMX_ERRORTYPE; cdecl;

  TComponentRoleEnum = function (hComponent : OMX_HANDLETYPE;
                    		         cRole : POMX_U8;
                                 nIndex : OMX_U32) : OMX_ERRORTYPE; cdecl;

  OMX_COMPONENTTYPE = record
    nSize : OMX_U32;                                     (* The size of this structure, in bytes.  It is the responsibility
                                                            of the allocator of this structure to fill in this value.  Since
                                                            this structure is allocated by the GetHandle function, this
                                                            function will fill in this value. *)
    nVersion : OMX_VERSIONTYPE;                          (* nVersion is the version of the OMX specification that the structure
                                                            is built against.  It is the responsibility of the creator of this
                                                            structure to initialize this value and every user of this structure
                                                            should verify that it knows how to use the exact version of
                                                            this structure found herein. *)
    pComponentPrivate : OMX_PTR;                         (* pComponentPrivate is a pointer to the component private data area.
                                                            This member is allocated and initialized by the component when the
                                                            component is first loaded.  The application should not access this
                                                            data area. *)
    pApplicationPrivate : OMX_PTR;                       (* pApplicationPrivate is a pointer that is a parameter to the
                                                            OMX_GetHandle method, and contains an application private value
                                                            provided by the IL client.  This application private data is
                                                            returned to the IL Client by OMX in all callbacks *)
    GetComponentVersion : TGetComponentVersion;          (* refer to OMX_GetComponentVersion in OMX_core.h or the OMX IL
                                                            specification for details on the GetComponentVersion method. *)
    SendCommand : TSendCommand;                          (* refer to OMX_SendCommand in OMX_core.h or the OMX IL
                                                            specification for details on the SendCommand method. *)
    GetParameter : TGetParameter;                        (* refer to OMX_GetParameter in OMX_core.h or the OMX IL
                                                            specification for details on the GetParameter method. *)
    SetParameter : TSetParameter;                        (* refer to OMX_SetParameter in OMX_core.h or the OMX IL
                                                            specification for details on the SetParameter method. *)
    GetConfig : TGetConfig;                              (* refer to OMX_GetConfig in OMX_core.h or the OMX IL
                                                            specification for details on the GetConfig method. *)
    SetConfig : TSetConfig;                              (* refer to OMX_SetConfig in OMX_core.h or the OMX IL
                                                            specification for details on the SetConfig method.*)
    GetExtensionIndex : TGetExtensionIndex;              (* refer to OMX_GetExtensionIndex in OMX_core.h or the OMX IL
                                                            specification for details on the GetExtensionIndex method. *)
    GetState : TGetState;                                (* refer to OMX_GetState in OMX_core.h or the OMX IL
                                                            specification for details on the GetState method. *)
    ComponentTunnelRequest : TComponentTunnelRequest;    (* The ComponentTunnelRequest method will interact with another OMX
                                                            component to determine if tunneling is possible and to setup the
                                                            tunneling.  The return codes for this method can be used to
                                                            determine if tunneling is not possible, or if tunneling is not
                                                            supported.

                                                            Base profile components (i.e. non-interop) do not support this
                                                            method and should return OMX_ErrorNotImplemented

                                                            The interop profile component MUST support tunneling to another
                                                            interop profile component with a compatible port parameters.
                                                            A component may also support proprietary communication.

                                                            If proprietary communication is supported the negotiation of
                                                            proprietary communication is done outside of OMX in a vendor
                                                            specific way. It is only required that the proper result be
                                                            returned and the details of how the setup is done is left
                                                            to the component implementation.

                                                            When this method is invoked when nPort in an output port, the
                                                            component will:
                                                            1.  Populate the pTunnelSetup structure with the output port's
                                                                requirements and constraints for the tunnel.

                                                            When this method is invoked when nPort in an input port, the
                                                            component will:
                                                            1.  Query the necessary parameters from the output port to
                                                                determine if the ports are compatible for tunneling
                                                            2.  If the ports are compatible, the component should store
                                                                the tunnel step provided by the output port
                                                            3.  Determine which port (either input or output) is the buffer
                                                                supplier, and call OMX_SetParameter on the output port to
                                                                indicate this selection.

                                                            The component will return from this call within 5 msec.

                                                            @param [in] hComp
                                                                Handle of the component to be accessed.  This is the component
                                                                handle returned by the call to the OMX_GetHandle method.
                                                            @param [in] nPort
                                                                nPort is used to select the port on the component to be used
                                                                for tunneling.
                                                            @param [in] hTunneledComp
                                                                Handle of the component to tunnel with.  This is the component
                                                                handle returned by the call to the OMX_GetHandle method.  When
                                                                this parameter is 0x0 the component should setup the port for
                                                                communication with the application / IL Client.
                                                            @param [in] nPortOutput
                                                                nPortOutput is used indicate the port the component should
                                                                tunnel with.
                                                            @param [in] pTunnelSetup
                                                                Pointer to the tunnel setup structure.  When nPort is an output port
                                                                the component should populate the fields of this structure.  When
                                                                When nPort is an input port the component should review the setup
                                                                provided by the component with the output port.
                                                            @return OMX_ERRORTYPE
                                                                If the command successfully executes, the return code will be
                                                                OMX_ErrorNone.  Otherwise the appropriate OMX error will be returned.  *)
    UseBuffer : TUseBuffer;                              (* refer to OMX_UseBuffer in OMX_core.h or the OMX IL
                                                            specification for details on the UseBuffer method.  *)
    AllocateBuffer : TAllocateBuffer;                    (* refer to OMX_AllocateBuffer in OMX_core.h or the OMX IL
                                                            specification for details on the AllocateBuffer method. *)
    FreeBuffer : TFreeBuffer;                            (* refer to OMX_FreeBuffer in OMX_core.h or the OMX IL
                                                            specification for details on the FreeBuffer method. *)
    EmptyThisBuffer : TEmptyThisBuffer;                  (* refer to OMX_EmptyThisBuffer in OMX_core.h or the OMX IL
                                                            specification for details on the EmptyThisBuffer method. *)
    FillThisBuffer : TFillThisBuffer;                    (* refer to OMX_FillThisBuffer in OMX_core.h or the OMX IL
                                                            specification for details on the FillThisBuffer method. *)
    SetCallbacks : TSetCallbacks;                        (* The SetCallbacks method is used by the core to specify the callback
                                                            structure from the application to the component.  This is a blocking
                                                            call.  The component will return from this call within 5 msec.

                                                         @param [in] hComponent
                                                             Handle of the component to be accessed.  This is the component
                                                             handle returned by the call to the GetHandle function.
                                                         @param [in] pCallbacks
                                                             pointer to an OMX_CALLBACKTYPE structure used to provide the
                                                             callback information to the component
                                                         @param [in] pAppData
                                                             pointer to an application defined value.  It is anticipated that
                                                             the application will pass a pointer to a data structure or a "this
                                                             pointer" in this area to allow the callback (in the application)
                                                             to determine the context of the call
                                                         @return OMX_ERRORTYPE
                                                             If the command successfully executes, the return code will be
                                                             OMX_ErrorNone.  Otherwise the appropriate OMX error will be returned. *)
    ComponentDeInit : TComponentDeInit;                  (* ComponentDeInit method is used to deinitialize the component
                                                            providing a means to free any resources allocated at component
                                                            initialization.  NOTE:  After this call the component handle is
                                                            not valid for further use.
                                                         @param [in] hComponent
                                                             Handle of the component to be accessed.  This is the component
                                                             handle returned by the call to the GetHandle function.
                                                         @return OMX_ERRORTYPE
                                                             If the command successfully executes, the return code will be
                                                             OMX_ErrorNone.  Otherwise the appropriate OMX error will be returned.   *)
    UseEGLImage : TUseEGLImage;
    ComponentRoleEnum : TComponentRoleEnum;
  end;

  OMX_AUDIO_PORTDEFINITIONTYPE = record
    cMIMEType : OMX_STRING;                              (* MIME type of data for the port *)
    pNativeRender : OMX_NATIVE_DEVICETYPE;               (* platform specific reference
                                                            for an output device,
                                                            otherwise this field is 0 *)
    bFlagErrorConcealment : OMX_BOOL;                    (* Turns on error concealment if it is
                                                            supported by the OMX component *)
    eEncoding : OMX_AUDIO_CODINGTYPE;                    (* Type of data expected for this
                                                            port (e.g. PCM, AMR, MP3, etc) *)
  end;

  OMX_VIDEO_PORTDEFINITIONTYPE = record
    cMIMEType : OMX_STRING;
    pNativeRender : OMX_NATIVE_DEVICETYPE;
    nFrameWidth : OMX_U32;
    nFrameHeight : OMX_U32;
    nStride : OMX_S32;
    nSliceHeight : OMX_U32;
    nBitrate : OMX_U32;
    xFramerate : OMX_U32;
    bFlagErrorConcealment : OMX_BOOL;
    eCompressionFormat : OMX_VIDEO_CODINGTYPE;
    eColorFormat : OMX_COLOR_FORMATTYPE;
    pNativeWindow : OMX_NATIVE_WINDOWTYPE;
  end;

  OMX_VIDEO_PARAM_QUANTIZATIONTYPE = record
    nSize: OMX_U32;
    nVersion :OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nQpI : OMX_U32;
    nQpP : OMX_U32;
    nQpB : OMX_U32;
   end;

  OMX_VIDEO_PARAM_PORTFORMATTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nIndex : OMX_U32;
    eCompressionFormat : OMX_VIDEO_CODINGTYPE;
    eColorFormat : OMX_COLOR_FORMATTYPE;
    xFramerate : OMX_U32;
  end;

  OMX_IMAGE_PORTDEFINITIONTYPE = record
    cMIMEType : OMX_STRING;
    pNativeRender : OMX_NATIVE_DEVICETYPE;
    nFrameWidth : OMX_U32;
    nFrameHeight : OMX_U32;
    nStride : OMX_S32;
    nSliceHeight : OMX_U32;
    bFlagErrorConcealment : OMX_BOOL;
    eCompressionFormat : OMX_IMAGE_CODINGTYPE;
    eColorFormat : OMX_COLOR_FORMATTYPE;
    pNativeWindow : OMX_NATIVE_WINDOWTYPE;
  end;

  OMX_IMAGE_PARAM_PORTFORMATTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nIndex : OMX_U32;
    eCompressionFormat :OMX_IMAGE_CODINGTYPE;
    eColorFormat : OMX_COLOR_FORMATTYPE;
  end;

  OMX_TIME_CONFIG_CLOCKSTATETYPE = record
    nSize : OMX_U32;                                     (* size of the structure in bytes *)
    nVersion : OMX_VERSIONTYPE;                          (* OMX specification version information *)
    eState : OMX_TIME_CLOCKSTATE;                        (* State of the media time. *)
    nStartTime : OMX_TICKS;                              (* Start time of the media time. *)
    nOffset : OMX_TICKS;                                 (* Time to offset the media time by
                                                            (e.g. preroll). Media time will be
                                                            reported to be nOffset ticks earlier. *)
    nWaitMask : OMX_U32;                                 (* Mask of OMX_CLOCKPORT values. *)
  end;

  OMX_OTHER_PORTDEFINITIONTYPE = record
    eFormat : OMX_OTHER_FORMATTYPE;                      (* Type of data expected for this channel *)
  end;

  OMX_FORMAT = record
    case integer of
     1 : (audio : OMX_AUDIO_PORTDEFINITIONTYPE);
     2 : (video : OMX_VIDEO_PORTDEFINITIONTYPE);
     3 : (image : OMX_IMAGE_PORTDEFINITIONTYPE);
     4 : (other : OMX_OTHER_PORTDEFINITIONTYPE);
  end;

  OMX_PARAM_PORTDEFINITIONTYPE = record
    nSize : OMX_U32;                                     (* Size of the structure in bytes *)
    nVersion : OMX_VERSIONTYPE;                          (* OMX specification version information *)
    nPortIndex : OMX_U32;                                (* Port number the structure applies to *)
    eDir : OMX_DIRTYPE;                                  (* Direction (input or output) of this port *)
    nBufferCountActual : OMX_U32;                        (* The actual number of buffers allocated on this port *)
    nBufferCountMin : OMX_U32;                           (* The minimum number of buffers this port requires *)
    nBufferSize : OMX_U32;                               (* Size, in bytes, for buffers to be used for this channel *)
    bEnabled : OMX_BOOL;                                 (* Ports default to enabled and are enabled/disabled by
                                                            OMX_CommandPortEnable/OMX_CommandPortDisable.
                                                            When disabled a port is unpopulated. A disabled port
                                                            is not populated with buffers on a transition to IDLE. *)
    bPopulated : OMX_BOOL;                               (* Port is populated with all of its buffers as indicated by
                                                            nBufferCountActual. A disabled port is always unpopulated.
                                                            An enabled port is populated on a transition to OMX_StateIdle
                                                            and unpopulated on a transition to loaded. *)
    eDomain : OMX_PORTDOMAINTYPE;                        (* Domain of the port. Determines the contents of metadata below. *)
    format : OMX_FORMAT;
    bBuffersContiguous : OMX_BOOL;
    nBufferAlignment : OMX_U32;
  end;

  OMX_AUDIO_PARAM_PCMMODETYPE = record
    nSize : OMX_U32;                                     (* Size of this structure, in Bytes *)
    nVersion : OMX_VERSIONTYPE;                          (* OMX specification version information *)
    nPortIndex : OMX_U32;                                (* port that this structure applies to *)
    nChannels : OMX_U32;                                 (* Number of channels (e.g. 2 for stereo) *)
    eNumData : OMX_NUMERICALDATATYPE;                    (* indicates PCM data as signed or unsigned *)
    eEndian : OMX_ENDIANTYPE;                            (* indicates PCM data as little or big endian *)
    bInterleaved : OMX_BOOL;                             (* True for normal interleaved data; false for
                                                            non-interleaved data (e.g. block data) *)
    nBitPerSample : OMX_U32;                             (* Bit per sample *)
    nSamplingRate : OMX_U32;                             (* Sampling rate of the source data.  Use 0 for
                                                            variable or unknown sampling rate. *)
    ePCMMode : OMX_AUDIO_PCMMODETYPE;                    (* PCM mode enumeration *)
    eChannelMapping : array [0 .. OMX_AUDIO_MAXCHANNELS - 1] of OMX_AUDIO_CHANNELTYPE; (* Slot i contains channel defined by eChannelMap[i] *)
  end;

  OMX_BUFFERFRAGMENTTYPE = record
    pBuffer : OMX_PTR;
    nLen : OMX_U32;
  end;

  OMX_PARAM_IJGSCALINGTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bEnabled : OMX_BOOL;
  end;

  OMX_DISPLAYRECTTYPE = record
    x_offset : OMX_S16;
    y_offset : OMX_S16;
    width : OMX_S16;
    height : OMX_S16;
  end;

  OMX_CONFIG_DISPLAYREGIONTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    set_ : OMX_DISPLAYSETTYPE;
    num : OMX_U32;
    fullscreen : OMX_BOOL;
    transform : OMX_DISPLAYTRANSFORMTYPE;
    dest_rect : OMX_DISPLAYRECTTYPE;
    src_rect : OMX_DISPLAYRECTTYPE;
    noaspect : OMX_BOOL;
    mode : OMX_DISPLAYMODETYPE;
    pixel_x : OMX_U32;
    pixel_y : OMX_U32;
    layer : OMX_S32;
    copyprotect_required : OMX_BOOL;
    alpha : OMX_U32;
    wfc_context_width : OMX_U32;
    wfc_context_height : OMX_U32;
  end;

  OMX_PARAM_SOURCETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eType : OMX_SOURCETYPE;
    nParam : OMX_U32;
    nFrameCount : OMX_U32;
    xFrameRate : OMX_U32;
  end;

  OMX_PARAM_SOURCESEEDTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nData : array [0 .. 15] of OMX_U16;
  end;

  OMX_PARAM_RESIZETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_RESIZEMODETYPE;
    nMaxWidth : OMX_U32;
    nMaxHeight : OMX_U32;
    nMaxBytes : OMX_U32;
    bPreserveAspectRatio : OMX_BOOL;
    bAllowUpscaling : OMX_BOOL;
  end;

  OMX_PARAM_TESTINTERFACETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bTest : OMX_BOOL;
    bSetExtra : OMX_BOOL;
    nExtra : OMX_U32;
    bSetError : OMX_BOOL;
    stateError : array [0 .. 1] of OMX_BOOL;
  end;

  OMX_CONFIG_VISUALISATIONTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    name : array [0 .. 15] of OMX_U8;
    _property : array [0 .. 63] of OMX_U8;
  end;

  OMX_CONFIG_BRCMAUDIODESTINATIONTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    sName : array [0 .. 15] of OMX_CHAR;
  end;

  OMX_CONFIG_BRCMAUDIOSOURCETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    sName : array [0 .. 15] of OMX_CHAR;
  end;


  OMX_CONFIG_BRCMAUDIODOWNMIXCOEFFICIENTS = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    coeff : array [0 .. 15] of OMX_U32;
  end;

  OMX_CONFIG_BRCMAUDIODOWNMIXCOEFFICIENTS8x8 = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    coeff : array [0 .. 63] of OMX_U32;
  end;

  OMX_CONFIG_BRCMAUDIOMAXSAMPLE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nMaxSample : OMX_U32;
    nTimeStamp : OMX_TICKS;
  end;

  OMX_CONFIG_PLAYMODETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eMode : OMX_PLAYMODETYPE;
  end;

  OMX_PARAM_DELIVERYFORMATTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eFormat : OMX_DELIVERYFORMATTYPE;
  end;

  OMX_PARAM_CODECCONFIGTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bCodecConfigIsComplete : OMX_U32;
    nData : array [0 .. 0] of OMX_U8;
  end;

  OMX_PARAM_STILLSFUNCTIONTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bBuffer : OMX_BOOL;
    pOpenFunc : function : OMX_PTR; cdecl;
    pCloseFunc : function : OMX_PTR; cdecl;
    pReadFunc : function : OMX_PTR; cdecl;
    pSeekFunc : function : OMX_PTR; cdecl;
    pWriteFunc : function : OMX_PTR; cdecl;
  end;

  OMX_PARAM_BUFFERADDRESSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nAllocLen : OMX_U32;
    handle : OMX_BUFFERADDRESSHANDLETYPE;
  end;

  OMX_PARAM_TUNNELSETUPTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    sSetup : OMX_TUNNELSETUPTYPE;
  end;

  OMX_PARAM_BRCMPORTEGLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bPortIsEGL : OMX_BOOL;
  end;
 (* to be fixed
  OMX_CONFIG_IMAGEFILTERPARAMSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eImageFilter : OMX_IMAGEFILTERTYPE;
    nNumParams : OMX_U32;
    nParams : array [0 .. OMX_CONFIG_IMAGEFILTERPARAMS_MAXPARAMS - 1] of OMX_U32;
  end;         *)

  OMX_CONFIG_TRANSITIONCONTROLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nPosStart : OMX_U32;
    nPosEnd : OMX_U32;
    nPosIncrement : OMX_S32;
    nFrameIncrement : OMX_TICKS;
    bSwapInputs : OMX_BOOL;
    name : array [0 .. 15] of OMX_U8;
    _property : array [0 .. 63] of OMX_U8;
  end;

  OMX_CONFIG_AUDIOMONOTRACKCONTROLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_AUDIOMONOTRACKOPERATIONSTYPE;
  end;

  OMX_PARAM_CAMERAIMAGEPOOLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nNumHiResVideoFrames : OMX_U32;
    nHiResVideoWidth : OMX_U32;
    nHiResVideoHeight : OMX_U32;
    eHiResVideoType : OMX_COLOR_FORMATTYPE;
    nNumHiResStillsFrames : OMX_U32;
    nHiResStillsWidth : OMX_U32;
    nHiResStillsHeight : OMX_U32;
    eHiResStillsType : OMX_COLOR_FORMATTYPE;
    nNumLoResFrames : OMX_U32;
    nLoResWidth : OMX_U32;
    nLoResHeight : OMX_U32;
    eLoResType : OMX_COLOR_FORMATTYPE;
    nNumSnapshotFrames : OMX_U32;
    eSnapshotType : OMX_COLOR_FORMATTYPE;
    eInputPoolMode : OMX_CAMERAIMAGEPOOLINPUTMODETYPE;
    nNumInputVideoFrames : OMX_U32;
    nInputVideoWidth : OMX_U32;
    nInputVideoHeight : OMX_U32;
    eInputVideoType : OMX_COLOR_FORMATTYPE;
    nNumInputStillsFrames : OMX_U32;
    nInputStillsWidth : OMX_U32;
    nInputStillsHeight : OMX_U32;
    eInputStillsType : OMX_COLOR_FORMATTYPE;
  end;

  OMX_PARAM_IMAGEPOOLSIZETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    width : OMX_U32;
    height : OMX_U32;
    num_pages : OMX_U32;
  end;

  OMX_BRCM_POOL_T = record
    {undefined structure}
  end;

  OMX_PARAM_IMAGEPOOLEXTERNALTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    image_pool : POMX_BRCM_POOL_T;
    image_pool2 : POMX_BRCM_POOL_T;
    image_pool3 : POMX_BRCM_POOL_T;
    image_pool4 : POMX_BRCM_POOL_T;
    image_pool5 : POMX_BRCM_POOL_T;
  end;

  _IL_FIFO_T = record
    {undefined structure}
  end;

  OMX_PARAM_RUTILFIFOINFOTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    pILFifo : P_IL_FIFO_T;
  end;

  OMX_PARAM_ILFIFOCONFIG = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nDataSize : OMX_U32;
    nHeaderCount : OMX_U32;
  end;

  OMX_CONFIG_CAMERASENSORMODETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nModeIndex : OMX_U32;
    nNumModes : OMX_U32;
    nWidth : OMX_U32;
    nHeight : OMX_U32;
    nPaddingRight : OMX_U32;
    nPaddingDown : OMX_U32;
    eColorFormat : OMX_COLOR_FORMATTYPE;
    nFrameRateMax : OMX_U32;
    nFrameRateMin : OMX_U32;
  end;

  OMX_FRAMESIZETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nWidth : OMX_U32;
    nHeight : OMX_U32;
  end;

  OMX_PARAM_SENSORMODETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nFrameRate : OMX_U32;
    bOneShot : OMX_BOOL;
    sFrameSize : OMX_FRAMESIZETYPE;
  end;

  OMX_BRCMBUFFERSTATSTYPE = record
    nOrdinal : OMX_U32;
    nTimeStamp : OMX_TICKS;
    nFilledLen : OMX_U32;
    nFlags : OMX_U32;
    crc : record
      case longint of
        0 : ( nU32 : OMX_U32 );
        1 : ( image : record
            nYpart : OMX_U32;
            nUVpart : OMX_U32;
          end );
      end;
  end;

  OMX_CONFIG_BRCMPORTBUFFERSTATSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nCount : OMX_U32;
    sData : array [0 .. 0] of OMX_BRCMBUFFERSTATSTYPE;
  end;

  OMX_CONFIG_BRCMPORTSTATSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nImageCount : OMX_U32;
    nBufferCount : OMX_U32;
    nFrameCount : OMX_U32;
    nFrameSkips : OMX_U32;
    nDiscards : OMX_U32;
    nEOS : OMX_U32;
    nMaxFrameSize : OMX_U32;
    nByteCount : OMX_TICKS;
    nMaxTimeDelta : OMX_TICKS;
    nCorruptMBs : OMX_U32;
  end;

  OMX_CONFIG_BRCMCAMERASTATSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nOutFrameCount : OMX_U32;
    nDroppedFrameCount : OMX_U32;
  end;

  OMX_BRCM_PERFSTATS = record
    count : array [0 .. OMX_BRCM_MAXIOPERFBANDS - 1] of OMX_U32;
    num : array [0 .. OMX_BRCM_MAXIOPERFBANDS - 1] of OMX_U32;
  end;

  OMX_CONFIG_BRCMIOPERFSTATSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bEnabled : OMX_BOOL;
    write : OMX_BRCM_PERFSTATS;
    flush : OMX_BRCM_PERFSTATS;
    wait : OMX_BRCM_PERFSTATS;
  end;

  OMX_CONFIG_SHARPNESSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nSharpness : OMX_S32;
  end;

  OMX_CONFIG_FLICKERCANCELTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eFlickerCancel : OMX_COMMONFLICKERCANCELTYPE;
  end;

  OMX_CONFIG_REDEYEREMOVALTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_REDEYEREMOVALTYPE;
  end;

  OMX_CONFIG_FACEDETECTIONCONTROLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_FACEDETECTIONCONTROLTYPE;
    nFrames : OMX_U32;
    nMaxRegions : OMX_U32;
    nQuality : OMX_U32;
  end;

  OMX_FACEREGIONTYPE = record
    nLeft : OMX_S16;
    nTop : OMX_S16;
    nWidth : OMX_U16;
    nHeight : OMX_U16;
    nFlags : OMX_FACEREGIONFLAGSTYPE;
    nFaceRecognitionId : record
      nLowPart : OMX_U32;
      nHighPart : OMX_U32;
    end;
  end;

  OMX_CONFIG_FACEDETECTIONREGIONTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nIndex : OMX_U32;
    nDetectedRegions : OMX_U32;
    nValidRegions : OMX_S32;
    nImageWidth : OMX_U32;
    nImageHeight : OMX_U32;
    sRegion : array [0 .. 0] of OMX_FACEREGIONTYPE;
  end;

  OMX_CONFIG_INTERLACETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_INTERLACETYPE;
    bRepeatFirstField : OMX_BOOL;
  end;

  OMX_PARAM_CAMERAISPTUNERTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    tuner_name : array [0 .. 63] of Char; // OMX_U8;
  end;

  OMX_CONFIG_IMAGEPTRTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    pImage : OMX_PTR;
  end;

  OMX_CONFIG_AFASSISTTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_AFASSISTTYPE;
  end;

  OMX_CONFIG_INPUTCROPTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    xLeft : OMX_U32;
    xTop : OMX_U32;
    xWidth : OMX_U32;
    xHeight : OMX_U32;
  end;

  OMX_PARAM_CODECREQUIREMENTSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nCallbackID : OMX_U32;
    bTryHWCodec : OMX_BOOL;
  end;

  OMX_CONFIG_BRCMEGLIMAGEMEMHANDLETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eglImage : OMX_PTR;
    memHandle : OMX_PTR;
  end;

  OMX_CONFIG_PRIVACYINDICATORTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    ePrivacyIndicatorMode : OMX_PRIVACYINDICATORTYPE;
  end;

  OMX_PARAM_CAMERAFLASHTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eFlashType : OMX_CAMERAFLASHTYPE;
    bRedEyeUsesTorchMode : OMX_BOOL;
  end;

  OMX_CONFIG_CAMERAFLASHCONFIGTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bUsePreFlash : OMX_BOOL;
    bUseFocusDistanceInfo : OMX_BOOL;
    eFlashSync : OMX_CAMERAFLASHCONFIGSYNCTYPE;
    bIgnoreChargeState : OMX_BOOL;
  end;

  OMX_CONFIG_BRCMAUDIOTRACKGAPLESSPLAYBACKTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nDelay : OMX_U32;
    nPadding : OMX_U32;
  end;

  OMX_CONFIG_BRCMAUDIOTRACKCHANGECONTROLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nSrcPortIndex : OMX_U32;
    nDstPortIndex : OMX_U32;
    nXFade : OMX_U32;
  end;

  OMX_PARAM_BRCMPIXELVALUERANGETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    ePixelValueRange : OMX_BRCMPIXELVALUERANGETYPE;
  end;

  OMX_PARAM_CAMERADISABLEALGORITHMTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eAlgorithm : OMX_CAMERADISABLEALGORITHMTYPE;
    bDisabled : OMX_BOOL;
  end;

  OMX_CONFIG_BRCMAUDIOEFFECTCONTROLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bEnable : OMX_BOOL;
    name : array [0 .. 15] of OMX_U8;
    _property : array [0 .. 255] of OMX_U8;
  end;

  OMX_CONFIG_BRCMMINIMUMPROCESSINGLATENCY = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nOffset : OMX_TICKS;
  end;

  OMX_PARAM_BRCMVIDEOAVCSEIENABLETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bEnable : OMX_BOOL;
  end;

  OMX_PARAM_BRCMALLOWMEMCHANGETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bEnable : OMX_BOOL;
  end;

  OMX_CONFIG_CAMERAUSECASETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eUseCase : OMX_CONFIG_CAMERAUSECASE;
  end;

  OMX_PARAM_BRCMDISABLEPROPRIETARYTUNNELSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bUseBuffers : OMX_BOOL;
  end;

  OMX_PARAM_BRCMRETAINMEMORYTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bEnable : OMX_BOOL;
  end;

  OMX_PARAM_BRCMOUTPUTBUFFERSIZETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nBufferSize : OMX_U32;
  end;

  OMX_CONFIG_LENSCALIBRATIONVALUETYPE = record
    nShutterDelayTime : OMX_U16;
    nNdTransparency : OMX_U16;
    nPwmPulseNearEnd : OMX_U16;
    nPwmPulseFarEnd : OMX_U16;
    nVoltagePIOutNearEnd : array [0 .. 2] of OMX_U16;
    nVoltagePIOut10cm : array [0 .. 2] of OMX_U16;
    nVoltagePIOutInfinity : array [0 .. 2] of OMX_U16;
    nVoltagePIOutFarEnd : array [0 .. 2] of OMX_U16;
    nAdcConversionNearEnd : OMX_U32;
    nAdcConversionFarEnd : OMX_U32;
  end;

  OMX_CONFIG_CAMERAINFOTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    cameraname : array [0 .. OMX_CONFIG_CAMERAINFOTYPE_NAME_LEN - 1] of OMX_U8;
    lensname : array [0 .. OMX_CONFIG_CAMERAINFOTYPE_NAME_LEN - 1] of OMX_U8;
    nModelId : OMX_U16;
    nManufacturerId : OMX_U8;
    nRevNum : OMX_U8;
    sSerialNumber : array [0 .. OMX_CONFIG_CAMERAINFOTYPE_SERIALNUM_LEN - 1] of OMX_U8;
    sEpromVersion : array [0 .. OMX_CONFIG_CAMERAINFOTYPE_EPROMVER_LEN - 1] of OMX_U8;
    sLensCalibration : OMX_CONFIG_LENSCALIBRATIONVALUETYPE;
    xFNumber : OMX_U32;
    xFocalLength : OMX_U32;
  end;

  OMX_CONFIG_CAMERAFEATURESTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eHasMechanicalShutter : OMX_CONFIG_CAMERAFEATURESSHUTTER;
    bHasLens : OMX_BOOL;
  end;

  OMX_CONFIG_REQUESTCALLBACKTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nIndex : OMX_INDEXTYPE;
    bEnable : OMX_BOOL;
  end;

  OMX_FOCUSREGIONXY = record
    xLeft : OMX_U32;
    xTop : OMX_U32;
    xWidth : OMX_U32;
    xHeight : OMX_U32;
    nWeight : OMX_U32;
    nMask : OMX_U32;
    eType : OMX_FOCUSREGIONTYPE;
  end;

  OMX_CONFIG_FOCUSREGIONXYTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nIndex : OMX_U32;
    nTotalRegions : OMX_U32;
    nValidRegions : OMX_S32;
    bLockToFaces : OMX_BOOL;
    xFaceTolerance : OMX_U32;
    sRegion : array [0 .. 0] of OMX_FOCUSREGIONXY;
  end;

  OMX_CONFIG_U8TYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nU8 : OMX_U8;
  end;
  OMX_PARAM_U8TYPE = OMX_CONFIG_U8TYPE;

  OMX_CONFIG_CAMERASETTINGSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nExposure : OMX_U32;
    nAnalogGain : OMX_U32;
    nDigitalGain : OMX_U32;
    nLux : OMX_U32;
    nRedGain : OMX_U32;
    nBlueGain : OMX_U32;
    nFocusPosition : OMX_U32;
  end;

  OMX_YUVCOLOUR = record
    nY : OMX_U8;
    nU : OMX_U8;
    nV : OMX_U8;
  end;

  OMX_CONFIG_DRAWBOXLINEPARAMS = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    xCornerSize : OMX_U32;
    nPrimaryFaceLineWidth : OMX_U32;
    nOtherFaceLineWidth : OMX_U32;
    nFocusRegionLineWidth : OMX_U32;
    sPrimaryFaceColour : OMX_YUVCOLOUR;
    sPrimaryFaceSmileColour : OMX_YUVCOLOUR;
    sPrimaryFaceBlinkColour : OMX_YUVCOLOUR;
    sOtherFaceColour : OMX_YUVCOLOUR;
    sOtherFaceSmileColour : OMX_YUVCOLOUR;
    sOtherFaceBlinkColour : OMX_YUVCOLOUR;
    bShowFocusRegionsWhenIdle : OMX_BOOL;
    sFocusRegionColour : OMX_YUVCOLOUR;
    bShowAfState : OMX_BOOL;
    bShowOnlyPrimaryAfState : OMX_BOOL;
    bCombineNonFaceRegions : OMX_BOOL;
    sAfLockPrimaryFaceColour : OMX_YUVCOLOUR;
    sAfLockOtherFaceColour : OMX_YUVCOLOUR;
    sAfLockFocusRegionColour : OMX_YUVCOLOUR;
    sAfFailPrimaryFaceColour : OMX_YUVCOLOUR;
    sAfFailOtherFaceColour : OMX_YUVCOLOUR;
    sAfFailFocusRegionColour : OMX_YUVCOLOUR;
  end;

  OMX_PARAM_CAMERARMITYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bEnabled : OMX_BOOL;
    sRmiName : array[0..(OMX_PARAM_CAMERARMITYPE_RMINAME_LEN)-1] of OMX_U8;
    nInputBufferHeight : OMX_U32;
    nRmiBufferSize : OMX_U32;
    pImagePool : ^OMX_BRCM_POOL_T;
  end;

  OMX_CONFIG_BRCMSYNCOUTPUTTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
  end;

  OMX_CONFIG_DRMVIEWTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nCurrentView : OMX_U32;
    nMaxView : OMX_U32;
  end;

  OMX_PARAM_BRCMU64TYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nLowPart : OMX_U32;
    nHighPart : OMX_U32;
  end;

  OMX_PARAM_BRCMTHUMBNAILTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bEnable : OMX_BOOL;
    bUsePreview : OMX_BOOL;
    nWidth : OMX_U32;
    nHeight : OMX_U32;
  end;

  OMX_PARAM_BRCMASPECTRATIOTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nWidth : OMX_U32;
    nHeight : OMX_U32;
  end;

  OMX_PARAM_BRCMVIDEODECODEERRORCONCEALMENTTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bStartWithValidFrame : OMX_BOOL;
  end;

  OMX_CONFIG_FLASHINFOTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    sFlashName : array[0..(OMX_CONFIG_FLASHINFOTYPE_NAME_LEN)-1] of OMX_U8;
    eFlashType : OMX_CAMERAFLASHTYPE;
    nDeviceId : OMX_U8;
    nDeviceVersion : OMX_U8;
  end;

  OMX_CONFIG_DYNAMICRANGEEXPANSIONTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eMode : OMX_DYNAMICRANGEEXPANSIONMODETYPE;
  end;

  OMX_PARAM_BRCMTHREADAFFINITYTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eAffinity : OMX_BRCMTHREADAFFINITYTYPE;
  end;

  OMX_CONFIG_SCENEDETECTTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eScene : OMX_SCENEDETECTTYPE;
  end;

  OMX_NALSTREAMFORMATTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eNaluFormat : OMX_NALUFORMATSTYPE;
  end;

//      OMX_VIDEO_PARAM_AVCTYPE = OMX_VIDEO_PARAM_MVCTYPE;

  OMX_STATICBOX = record
    xLeft : OMX_U32;
    xTop : OMX_U32;
    xWidth : OMX_U32;
    xHeight : OMX_U32;
    eType : OMX_STATICBOXTYPE;
  end;

  OMX_CONFIG_STATICBOXTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nIndex : OMX_U32;
    nTotalBoxes : OMX_U32;
    nValidBoxes : OMX_S32;
    bDrawOtherBoxes : OMX_BOOL;
    sBoxes : array [0 .. 0] of OMX_STATICBOX;
  end;

  OMX_CONFIG_PORTBOOLEANTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bEnabled : OMX_BOOL;
  end;

  OMX_PARAM_CAMERACAPTUREMODETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_CAMERACAPTUREMODETYPE;
  end;

  OMX_PARAM_BRCMDRMENCRYPTIONTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eEncryption : OMX_BRCMDRMENCRYPTIONTYPE;
    nConfigDataLen : OMX_U32;
    configData : array [0 .. 0] of OMX_U8;
  end;

  OMX_CONFIG_BUFFERSTALLTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bStalled : OMX_BOOL;
    nDelay : OMX_U32;
  end;

  OMX_CONFIG_LATENCYTARGETTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bEnabled : OMX_BOOL;
    nFilter : OMX_U32;
    nTarget : OMX_U32;
    nShift : OMX_U32;
    nSpeedFactor : OMX_S32;
    nInterFactor : OMX_S32;
    nAdjCap : OMX_S32;
  end;

  OMX_CONFIG_BRCMUSEPROPRIETARYCALLBACKTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bEnable : OMX_BOOL;
  end;

  OMX_PARAM_TIMESTAMPMODETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    eTimestampMode : OMX_TIMESTAMPMODETYPE;
  end;

  OMX_BRCMVEGLIMAGETYPE = record
    nWidth : OMX_U32;
    nHeight : OMX_U32;
    nStride : OMX_U32;
    nUmemHandle : OMX_U32;
    nUmemOffset : OMX_U32;
    nFlipped : OMX_U32;
  end;

  OMX_CONFIG_BRCMFOVTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    xFieldOfViewHorizontal : OMX_U32;
    xFieldOfViewVertical : OMX_U32;
  end;

  OMX_VIDEO_CONFIG_LEVEL_EXTEND = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nCustomMaxMBPS : OMX_U32;
    nCustomMaxFS : OMX_U32;
    nCustomMaxBRandCPB : OMX_U32;
  end;

  OMX_VIDEO_EEDE_ENABLE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    enable : OMX_U32;
  end;

  OMX_VIDEO_EEDE_LOSSRATE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    loss_rate : OMX_U32;
  end;

  OMX_PARAM_COLORSPACETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eColorSpace : OMX_COLORSPACETYPE;
  end;

  OMX_PARAM_CAPTURESTATETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eCaptureState : OMX_CAPTURESTATETYPE;
  end;

  OMX_PARAM_BRCMCONFIGFILETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    fileSize : OMX_U32;
  end;

  OMX_PARAM_BRCMCONFIGFILECHUNKTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    size : OMX_U32;
    offset : OMX_U32;
    data : array [0 .. 0] of OMX_U8;
  end;

  OMX_PARAM_BRCMFRAMERATERANGETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    xFramerateLow : OMX_U32;
    xFramerateHigh : OMX_U32;
  end;

  OMX_PARAM_S32TYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nS32 : OMX_S32;
  end;

  OMX_PARAM_BRCMVIDEODRMPROTECTBUFFERTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    size_wanted : OMX_U32;
    protect : OMX_U32;
    mem_handle : OMX_U32;
    phys_addr : OMX_PTR;
  end;

  OMX_CONFIG_ZEROSHUTTERLAGTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bZeroShutterMode : OMX_U32;
    bConcurrentCapture : OMX_U32;
  end;

  OMX_PARAM_BRCMVIDEODECODECONFIGVD3TYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    config : array [0 .. 0] of OMX_U8;
  end;

  OMX_CONFIG_CUSTOMAWBGAINSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    xGainR : OMX_U32;
    xGainB : OMX_U32;
  end;

  OMX_CONFIG_BRCMRENDERSTATSTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nValid : OMX_BOOL;
    nMatch : OMX_U32;
    nPeriod : OMX_U32;
    nPhase : OMX_U32;
    nPixelClockNominal : OMX_U32;
    nPixelClock : OMX_U32;
    nHvsStatus : OMX_U32;
    dummy0 : array [0 .. 1] of OMX_U32;
  end;

  OMX_CONFIG_BRCMANNOTATETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bEnable : OMX_BOOL;
    bShowShutter : OMX_BOOL;
    bShowAnalogGain : OMX_BOOL;
    bShowLens : OMX_BOOL;
    bShowCaf : OMX_BOOL;
    bShowMotion : OMX_BOOL;
    bShowFrameNum : OMX_BOOL;
    bEnableBackground : OMX_BOOL;
    bCustomBackgroundColour : OMX_BOOL;
    nBackgroundY : OMX_U8;
    nBackgroundU : OMX_U8;
    nBackgroundV : OMX_U8;
    dummy1 : OMX_U8;
    bCustomTextColour : OMX_BOOL;
    nTextY : OMX_U8;
    nTextU : OMX_U8;
    nTextV : OMX_U8;
    nTextSize : OMX_U8;
    sText : array [0 .. OMX_BRCM_MAXANNOTATETEXTLEN - 1] of OMX_U8;
  end;

  OMX_CONFIG_BRCMSTEREOSCOPICMODETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_BRCMSTEREOSCOPICMODETYPE;
    bDecimate : OMX_BOOL;
    bSwapEyes : OMX_BOOL;
  end;

  OMX_PARAM_CAMERAINTERFACETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_CAMERAINTERFACETYPE;
  end;

  OMX_PARAM_CAMERACLOCKINGMODETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eMode : OMX_CAMERACLOCKINGMODETYPE;
  end;
        (* to fix
  OMX_PARAM_CAMERARXCONFIG_TYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eDecode : OMX_CAMERARXDECODETYPE;
    eEncode : OMX_CAMERARXENCODETYPE;
    eUnpack : OMX_CAMERARXUNPACKYPE;
    ePack : OMX_CAMERARXPACKTYPE;
    nDataLanes : OMX_U32;
    nEncodeBlockLength : OMX_U32;
    nEmbeddedDataLines : OMX_U32;
    nImageId : OMX_U32;
  end;       *)

  OMX_PARAM_CAMERARXTIMING_TYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    nTiming1 : OMX_U32;
    nTiming2 : OMX_U32;
    nTiming3 : OMX_U32;
    nTiming4 : OMX_U32;
    nTiming5 : OMX_U32;
    nTerm1 : OMX_U32;
    nTerm2 : OMX_U32;
    nCpiTiming1 : OMX_U32;
    nCpiTiming2 : OMX_U32;
  end;

  OMX_PARAM_BAYERORDERTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    eBayerOrder : OMX_BAYERORDERTYPE;
  end;

  OMX_PARAM_LENSSHADINGOVERRIDETYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    bEnabled : OMX_BOOL;
    nGridCellSize : OMX_U32;
    nWidth : OMX_U32;
    nStride : OMX_U32;
    nHeight : OMX_U32;
    nMemHandleTable : OMX_U32;
    nRefTransform : OMX_U32;
  end;

  OMX_CCMTYPE = record
    sCcm : array [0..2, 0 .. 2] of OMX_S32;
    soffsets : array [0 .. 2] of OMX_S32;
  end;
  OMX_PARAM_CCMTYPE = OMX_CCMTYPE;

  OMX_PARAM_CUSTOMCCMTYPE = record
    nSize : OMX_U32;
    nVersion : OMX_VERSIONTYPE;
    nPortIndex : OMX_U32;
    bEnabled : OMX_BOOL;
    xColorMatrix : array [0 .. 2, 0 .. 2] of OMX_S32;
    nColorOffset : array [0 .. 2] of OMX_S32;
  end;

// omx functions
function OMX_Init : OMX_ERRORTYPE; cdecl; external;
function OMX_Deinit : OMX_ERRORTYPE; cdecl; external;
function OMX_GetHandle (pHandle : POMX_HANDLETYPE;
                        cComponentName : OMX_STRING;
                        pAppData : OMX_PTR;
                        pCallBacks : POMX_CALLBACKTYPE) : OMX_ERRORTYPE; cdecl; external;
function OMX_ComponentNameEnum (cComponentName : OMX_STRING;
                                nNameLength : OMX_U32;
                                nIndex : OMX_U32) : OMX_ERRORTYPE; cdecl; external;
function OMX_FreeHandle (hComponent : OMX_HANDLETYPE) : OMX_ERRORTYPE; cdecl; external;
function OMX_SetupTunnel (hOutput : OMX_HANDLETYPE;
                          nPortOutput : OMX_U32;
                          hInput : OMX_HANDLETYPE;
                          nPortInput : OMX_U32) : OMX_ERRORTYPE; cdecl; external;
function OMX_GetContentPipe (hPipe : POMX_HANDLETYPE;
                             szURI : OMX_STRING ) : OMX_ERRORTYPE; cdecl; external;
function OMX_GetComponentsOfRole (role : OMX_STRING;
                                  pNumComps : POMX_U32;
                                  compNames : PPOMX_U8) : OMX_ERRORTYPE; cdecl; external;
function OMX_GetRolesOfComponent (compName : OMX_STRING;
                                  pNumRoles : POMX_U32;
                                  roles : PPOMX_U8) : OMX_ERRORTYPE; cdecl; external;

// macros
function OMX_GetComponentVersion (hComponent  : OMX_HANDLETYPE;
                                  pComponentName : OMX_STRING;
                                  pComponentVersion : POMX_VERSIONTYPE;
                                  pSpecVersion : POMX_VERSIONTYPE;
                                  pComponentUUID : POMX_UUIDTYPE) : OMX_ERRORTYPE;
function OMX_GetState (hComponent : OMX_HANDLETYPE; pState : POMX_STATETYPE) : OMX_ERRORTYPE;
function OMX_GetParameter (hComponent : OMX_HANDLETYPE;
                           nParamIndex : OMX_INDEXTYPE;
                           pComponentParameterStructure : OMX_PTR) : OMX_ERRORTYPE;
function OMX_SetParameter (hComponent : OMX_HANDLETYPE;
                           nParamIndex : OMX_INDEXTYPE;
                           pComponentParameterStructure : OMX_PTR) : OMX_ERRORTYPE;
function OMX_EmptyThisBuffer (hComponent : OMX_HANDLETYPE;
                              pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE;
function OMX_FillThisBuffer (hComponent : OMX_HANDLETYPE;
                             pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE;
function OMX_SendCommand (hComponent : OMX_HANDLETYPE;
                          Cmd : OMX_COMMANDTYPE;
                          nParam1 : OMX_U32;
                          pCmdData : OMX_PTR) : OMX_ERRORTYPE;
function OMX_SetConfig (hComponent : OMX_HANDLETYPE;
                         nIndex : OMX_INDEXTYPE;
                         pComponentConfigStructure : OMX_PTR) : OMX_ERRORTYPE;
function OMX_GetExtensionIndex (hComponent : OMX_HANDLETYPE;
                                cParameterName : OMX_STRING;
                                pIndexType : POMX_INDEXTYPE) : OMX_ERRORTYPE;
function OMX_UseBuffer (hComponent : OMX_HANDLETYPE;
                        ppBufferHdr : PPOMX_BUFFERHEADERTYPE;
                        nPortIndex : OMX_U32;
                        pAppPrivate : OMX_PTR;
                        nSizeBytes : OMX_U32;
                        pBuffer : POMX_U8) : OMX_ERRORTYPE;
function OMX_AllocateBuffer (hComponent : OMX_HANDLETYPE;
                             ppBuffer : PPOMX_BUFFERHEADERTYPE;
                             nPortIndex : OMX_U32;
                             pAppPrivate : OMX_PTR;
                             nSizeBytes : OMX_U32) : OMX_ERRORTYPE;
function OMX_FreeBuffer (hComponent : OMX_HANDLETYPE;
                         nPortIndex : OMX_U32;
                         pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE;
function OMX_SetCallbacks (hComponent : OMX_HANDLETYPE;
                           pCallbacks : POMX_CALLBACKTYPE;
                           pAppData : OMX_PTR) : OMX_ERRORTYPE;
function OMX_ComponentDeInit (hComponent : OMX_HANDLETYPE) : OMX_ERRORTYPE;

// helpers
function OMX_BoolToStr (b : LongBool) : string;
function OMX_ErrToStr (err : OMX_ERRORTYPE) : string;
function OMX_StateToStr (s : OMX_STATETYPE) : string;
function OMX_EventToStr (e : OMX_EVENTTYPE) : string;

implementation

// macros

function OMX_GetComponentVersion (hComponent  : OMX_HANDLETYPE;
                                  pComponentName : OMX_STRING;
                                  pComponentVersion : POMX_VERSIONTYPE;
                                  pSpecVersion : POMX_VERSIONTYPE;
                                  pComponentUUID : POMX_UUIDTYPE) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.GetComponentVersion (hComponent, pComponentName, pComponentVersion,
                                pSpecVersion, pComponentUUID);
end;

function OMX_GetParameter (hComponent : OMX_HANDLETYPE;
                           nParamIndex : OMX_INDEXTYPE;
                           pComponentParameterStructure : OMX_PTR) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.GetParameter (hComponent, nParamIndex, pComponentParameterStructure);
end;

function OMX_SetParameter (hComponent : OMX_HANDLETYPE;
                           nParamIndex : OMX_INDEXTYPE;
                           pComponentParameterStructure : OMX_PTR) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.SetParameter (hComponent, nParamIndex, pComponentParameterStructure);
end;

function OMX_GetState (hComponent : OMX_HANDLETYPE; pState : POMX_STATETYPE) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.GetState (hComponent, pState);
end;

function OMX_SendCommand (hComponent : OMX_HANDLETYPE;
                          Cmd : OMX_COMMANDTYPE;
                          nParam1 : OMX_U32;
                          pCmdData : OMX_PTR) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.SendCommand (hComponent, Cmd, nParam1, pCmdData);
end;

function OMX_SetConfig (hComponent : OMX_HANDLETYPE;
                         nIndex : OMX_INDEXTYPE;
                         pComponentConfigStructure : OMX_PTR) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.SetConfig (hComponent, nIndex, pComponentConfigStructure);
end;

function OMX_EmptyThisBuffer (hComponent : OMX_HANDLETYPE;
                              pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.EmptyThisBuffer (hComponent, pBuffer);
end;

function OMX_FillThisBuffer (hComponent : OMX_HANDLETYPE;
                             pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.FillThisBuffer (hComponent, pBuffer);
end;

function OMX_GetExtensionIndex (hComponent : OMX_HANDLETYPE;
                                cParameterName : OMX_STRING;
                                pIndexType : POMX_INDEXTYPE) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.GetExtensionIndex (hComponent, cParameterName, pIndexType);
end;

function OMX_UseBuffer (hComponent : OMX_HANDLETYPE;
                        ppBufferHdr : PPOMX_BUFFERHEADERTYPE;
                        nPortIndex : OMX_U32;
                        pAppPrivate : OMX_PTR;
                        nSizeBytes : OMX_U32;
                        pBuffer : POMX_U8) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.UseBuffer (hComponent, ppBufferHdr, nPortIndex, pAppPrivate, nSizeBytes, pBuffer);
end;

function OMX_AllocateBuffer (hComponent : OMX_HANDLETYPE;
                             ppBuffer : PPOMX_BUFFERHEADERTYPE;
                             nPortIndex : OMX_U32;
                             pAppPrivate : OMX_PTR;
                             nSizeBytes : OMX_U32) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.AllocateBuffer (hComponent, ppBuffer, nPortIndex, pAppPrivate, nSizeBytes);
end;

function OMX_FreeBuffer (hComponent : OMX_HANDLETYPE;
                         nPortIndex : OMX_U32;
                         pBuffer : POMX_BUFFERHEADERTYPE) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.FreeBuffer (hComponent, nPortIndex, pBuffer);
end;

function OMX_SetCallbacks (hComponent : OMX_HANDLETYPE;
                           pCallbacks : POMX_CALLBACKTYPE;
                           pAppData : OMX_PTR) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.SetCallbacks (hComponent, pCallbacks, pAppData);
end;

function OMX_ComponentDeInit (hComponent : OMX_HANDLETYPE) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.ComponentDeInit (hComponent);
end;

function OMX_UseEGLImage (hComponent : OMX_HANDLETYPE;
                          ppBufferHdr : PPOMX_BUFFERHEADERTYPE;
                          nPortIndex : OMX_U32;
                          pAppPrivate : OMX_PTR;
                          eglImage : Pointer) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.UseEGLImage (hComponent,  ppBufferHdr, nPortIndex, pAppPrivate, eglImage);
end;

function OMX_ComponentRoleEnum (hComponent : OMX_HANDLETYPE;
                    		        cRole : POMX_U8;
                                nIndex : OMX_U32) : OMX_ERRORTYPE;
begin
  Result := POMX_COMPONENTTYPE (hComponent)^.ComponentRoleEnum (hComponent, cRole, nIndex);
end;

function OMX_BoolToStr (b : LongBool) : string;
begin
  if b then Result := 'TRUE' else Result := 'FALSE';
end;

function OMX_EventToStr (e : OMX_EVENTTYPE) : string;
begin
  case e of
    OMX_EventCmdComplete         : Result := 'Command Complete';
    OMX_EventError               : Result := 'Error';
    OMX_EventMark                : Result := 'Mask';
    OMX_EventPortSettingsChanged : Result := 'Port Settings Changed';
    OMX_EventBufferFlag          : Result := 'Buffer Flag';
    OMX_EventResourcesAcquired   : Result := 'Resources Acquired';
    else                           Result := 'Unknown Event (' + e.ToString + ')';
    end;
end;


function OMX_ErrToStr (err : OMX_ERRORTYPE) : string;
begin
  case err of
    OMX_ErrorNone                          : Result := 'OK';
    OMX_ErrorInsufficientResources         : Result := 'Insufficient Resources';
    OMX_ErrorUndefined                     : Result := 'Undefined';
    OMX_ErrorInvalidComponentName          : Result := 'Invalid Component Name';
    OMX_ErrorComponentNotFound             : Result := 'Component not Found';
    OMX_ErrorInvalidComponent              : Result := 'Invalid Component';
    OMX_ErrorBadParameter                  : Result := 'Bad Parameter';
    OMX_ErrorNotImplemented                : Result := 'Not Implemented';
    OMX_ErrorUnderflow                     : Result := 'Underflow';
    OMX_ErrorOverflow                      : Result := 'Overflow';
    OMX_ErrorHardware                      : Result := 'Hardware Error';
    OMX_ErrorInvalidState                  : Result := 'Invalid State';
    OMX_ErrorStreamCorrupt                 : Result := 'Corrupt Stream';
    OMX_ErrorPortsNotCompatible            : Result := 'Ports not Compatible';
    OMX_ErrorResourcesLost                 : Result := 'Resources Lost';
    OMX_ErrorNoMore                        : Result := 'No More Indicies';
    OMX_ErrorVersionMismatch               : Result := 'Version Mismatch';
    OMX_ErrorNotReady                      : Result := 'Component not Ready';
    OMX_ErrorTimeout                       : Result := 'Timeout';
    OMX_ErrorSameState                     : Result := 'Same State';
    OMX_ErrorResourcesPreempted            : Result := 'Resources Preempted';
    OMX_ErrorPortUnresponsiveDuringAllocation : Result := 'Unresponsive during Allocation';
    OMX_ErrorPortUnresponsiveDuringDeallocation : Result := 'Unresponsive during Deallocation';
    OMX_ErrorPortUnresponsiveDuringStop    : Result := 'Unresponsive during Stop';
    OMX_ErrorIncorrectStateTransition      : Result := 'Incorrect State Transition';
    OMX_ErrorIncorrectStateOperation       : Result := 'Incorrect State Operation';
    OMX_ErrorUnsupportedSetting            : Result := 'Unsupported Setting';
    OMX_ErrorUnsupportedIndex              : Result := 'Unsupported Index';
    OMX_ErrorBadPortIndex                  : Result := 'Bad Port Index';
    OMX_ErrorPortUnpopulated               : Result := 'Port Unpopulated';
    OMX_ErrorComponentSuspended            : Result := 'Component suspended';
    OMX_ErrorDynamicResourcesUnavailable   : Result := 'Dynamic Resources Unavailable';
    OMX_ErrorMbErrorsInFrame               : Result := 'Errors in Frame';
    OMX_ErrorFormatNotDetected             : Result := 'Format not Detected';
    OMX_ErrorContentPipeOpenFailed         : Result := 'Pipe Open Failed';
    OMX_ErrorContentPipeCreationFailed     : Result := 'Pipe Creation Failed';
    OMX_ErrorSeperateTablesUsed            : Result := 'Separate Table being Used';
    OMX_ErrorTunnelingUnsupported          : Result := 'Tunneling Unsupported';
    OMX_ErrorDiskFull                      : Result := 'Disk Full';
    OMX_ErrorMaxFileSize                   : Result := 'Max File Size Reached';
    OMX_ErrorDrmUnauthorised               : Result := 'DRM Unauthorised';
    OMX_ErrorDrmExpired                    : Result := 'DRM Expired';
    OMX_ErrorDrmGeneral                    : Result := 'General DRM Error';
    else                                     Result := 'Unknown Error (' + err.ToHexString (8) + ')';
  end;
end;

function OMX_StateToStr (s : OMX_STATETYPE) : string;
begin
  case s of
    OMX_StateInvalid          : Result := 'Invalid';
    OMX_StateLoaded           : Result := 'Loaded';
    OMX_StateIdle             : Result := 'Idle';
    OMX_StateExecuting        : Result := 'Executing';
    OMX_StatePause            : Result := 'Paused';
    OMX_StateWaitForResources : Result := 'Waiting for Resources';
    else                        Result := 'Unknown State (' + s.ToHexString (8) + ')';
    end;
end;

end.

