unit camera;

{$mode objfpc}{$H+}

//------------------------------------------------------------------------------
//
// A simple camera unit for Ultibo using pure OMX calls
// v.0.13 alpha - 20181220
//
// Piotr Kardasz
// pik33@o2.pl
// gpl 2.0 or higher
//
// based on https://github.com/SonienTaegi/rpi-omx-tutorial
//
//------------------------------------------------------------------------------
// Instructions:
//
// - call initcamera with your desired parameters. You have to provide a buffer
// for the camera data
//
// - check the result: if it is >$C0000000 then all went OK,
//   the camera is in the idle state, and the result is the address
//   of the camera buffer
//   If it is small integer, the error occured
//
//   1 - error while loading the camera component
//   2 - error while setting camera number
//   3 - error while setting the video format
//   4 - error while switching the camera to the idle state
//   5 - error while allocating the camera buffer
//   6 - camera didn't reached the idle state
//  If all went OK, you will get pointers to y, u, v buffers in pY, pU, pV
//  and their sizes in sizey, sizeu, sizev
//
// - call startcamera. If it returned 0, the worker thread is started
//   In your main thread wait until filled=true and read the buffers
//   as fast as you can, then set filled=false
//
// - when done, call stopcamera
// - after this you can start it again or...
// ... call destroycamera which will unload it and close omx.
//
//------------------------------------------------------------------------------


interface

uses Classes, SysUtils, threads, platform, uomx, vc4;

const COMPONENT_CAMERA='OMX.broadcom.camera';

type TCameraWorkerThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

var width,height,framerate:cardinal;
    sizey,sizeu,sizev:cardinal;
    pY,pU,pV:^OMX_U8;

    err:OMX_ERRORTYPE;
    pcamera:OMX_HANDLETYPE;
    portdef:OMX_PARAM_PORTDEFINITIONTYPE;
    pCameraOutBuffer:^OMX_BUFFERHEADERTYPE;
    camerabufferfilled:OMX_BOOL=false;
    filled:boolean=false;
    frames:cardinal=0;

    callbackOMX:OMX_CALLBACKTYPE;
    portCapturing:OMX_CONFIG_PORTBOOLEANTYPE;
    deviceNumber:OMX_PARAM_U32TYPE;
    formatVideo:POMX_VIDEO_PORTDEFINITIONTYPE;

    PBuffer: POMX_BUFFERHEADERTYPE;
    cameraworkerthread:TCameraWorkerThread=nil;
    cameraworkerthreadterminate:boolean=false;
    outputbuffer:cardinal;
    camerabuffer:cardinal;
    buffersize:integer=64000; //320x200; will be changed at start

function initcamera(xres,yres,fps:integer;buffer:cardinal):cardinal;
function startcamera:cardinal;
function stopcamera:cardinal;
function destroycamera:cardinal;

const logenable=true; // logging disabled
// you have to implement your own print_log function before enable the logging

implementation
uses camera2;

procedure fastmove(from,too,len:cardinal);

// one loop moves 256 bytes of data

label p101 ;

begin
     asm
     push {r0-r12}
     ldr r12,len
     ldr r9,from
     add r12,r9
     ldr r10,too


p101:
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}
      ldm r9!, {r0-r7}
      stm r10!,{r0-r7}

     cmps r9,r12
     blt p101
     pop {r0-r12}
     end;

end;


procedure print_log(s:string);  forward;

//------------------------------------------------------------------------------
//
// Camera worker thread. Created by startcamera; working until stopcamera;
//
//------------------------------------------------------------------------------

constructor TCameraWorkerThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
cameraworkerthreadterminate:=false;
inherited Create(CreateSuspended);

end;


procedure TCameraWorkerThread.execute;

label p998;

var counter:integer=0;
begin
ThreadSetpriority(ThreadGetCurrent,6);
threadsleep(1);

OMX_FillThisBuffer(pcamera, pCameraOutBuffer);

// ----- MAIN CAPTURE LOOP -----------------------------------------------------

repeat

if camerabufferfilled then
  begin
  // print_log('******* camera buffer filled, frame '+inttostr(frames));
  frames+=1;
  camerabufferfilled:=false;
  counter:=0;
  OMX_FillThisBuffer(pcamera,pCameraOutBuffer);
  end;
threadsleep(1);
until terminated or cameraworkerthreadterminate;
print_log('Camera worker thread terminated');
cameraworkerthreadterminate:=false;
end;


//------------------------------------------------------------------------------
//
// You need to define these 3 callbacks to use OMX
//
//------------------------------------------------------------------------------


// Callback: OMX Event occured

function onOMXevent(hComponent: OMX_HANDLETYPE;
	    	      pAppData:OMX_PTR;
		        eEvent: OMX_EVENTTYPE;
		          nData1: OMX_U32;
		            nData2: OMX_U32;
		              pEventData: OMX_PTR): OMX_ERRORTYPE; cdecl;

begin
result:= OMX_ErrorNone;
end;


// Callback: Camera buffer filled

function onFillCameraOut(hComponent:OMX_HANDLETYPE; pAppData: OMX_PTR; pBuffer:POMX_BUFFERHEADERTYPE): OMX_ERRORTYPE; cdecl;

begin
fastmove(camerabuffer,outputbuffer,buffersize);
camerabufferfilled:=true;
filled:=true;
result:=OMX_ErrorNone;
end;


// Callback: Render buffer empty

function onEmptyRenderIn(hComponent:OMX_HANDLETYPE; pAppData:OMX_PTR; PBuffer:POMX_BUFFERHEADERTYPE): OMX_ERRORTYPE; cdecl;

begin
  result:= OMX_ErrorNone;
end;

//------------------------------------------------------------------------------
//
// OMX callback definitions end
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//
// Helper functions
//
//------------------------------------------------------------------------------

procedure print_log(s:string);

//This is a placeholder for your function which does the logging

begin
  if logenable then
    begin
    camerawindow2.println(s);
    end;
end;

function isState(hcomponent:POMX_HANDLETYPE; state:OMX_STATETYPE): OMX_BOOL;

var currentState: OMX_STATETYPE;

begin
if (hComponent=nil) then result:=OMX_FALSE;
OMX_GetState(hComponent,@currentState);
if currentState=state then result:=OMX_TRUE else result:=OMX_FALSE;
end;

function wait_for_state_change(state_tobe: OMX_STATETYPE; handle:OMX_HANDLETYPE): OMX_BOOL;

var isValid:OMX_BOOL=OMX_TRUE;
    timeout_counter:cardinal=0;
    state_current:OMX_STATETYPE;

begin
isValid := OMX_FALSE;
while (timeout_counter < 5000) and (isValid=OMX_FALSE) do
  begin
  timeout_counter:=0;
  OMX_GetState(handle, @state_current);
  if (state_current <> state_tobe) then begin threadsleep(1); inc(timeout_counter); end else IsValid:=OMX_TRUE;
  end;
result:=IsValid;
end;

//------------------------------------------------------------------------------
//
// Camera initialization.
// Input: xres, yres, fps, user buffer address
// Output: OMX camera buffer address if ok
// low numbers if error
// After initialization the camera is in idle state and buffers are allocated
//
//------------------------------------------------------------------------------

function initcamera(xres,yres,fps:integer;buffer:cardinal):cardinal;

label p999;

begin

// Initialize variables

outputbuffer:=buffer;
width:=xres;
height:=yres;
framerate	:= 60;

// initialize VC4.
bcmhostinit;
print_log('VC4 initialized');

// initialize OMX

OMX_Init;
print_log('OMX initialized');

// Set 3 callbacks needed by OMX components

callbackOMX.EventHandler:= @onOMXevent;
callbackOMX.EmptyBufferDone:= @onEmptyRenderIn;
callbackOMX.FillBufferDone:= @onFillCameraOut;
print_log('Callbacks set');

// Load the camera

err := OMX_GetHandle(@(pcamera), COMPONENT_CAMERA, nil, @CallbackOMX);
if (err <> OMX_ErrorNone ) then
  begin
  print_log('error loading camera'+inttostr(err));
  result:=1;       // error while loading the camera component
  goto p999;
  end;

print_log('Camera loaded: '+inttohex(cardinal(pcamera),8));

// Disable unused camera ports - we will use #71

OMX_SendCommand(pcamera, OMX_CommandPortDisable, 70, nil);
OMX_SendCommand(pcamera, OMX_CommandPortDisable, 72, nil);
OMX_SendCommand(pcamera, OMX_CommandPortDisable, 73, nil);
print_log('Camera ports 70,72,73 disabled');

// Set camera device number

FillChar (deviceNumber, SizeOf(deviceNumber), 0);
deviceNumber.nSize := sizeof(deviceNumber);
deviceNumber.nVersion.nVersion := OMX_VERSION;
deviceNumber.nPortIndex := OMX_ALL;
deviceNumber.nU32 := 0;

err := OMX_SetParameter(pcamera, OMX_IndexParamCameraDeviceNumber, @deviceNumber);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'camera set number FAIL');
  result:=2;   // error while setting camera number
  goto p999;
  end;

print_log('Camera device number set to 0');

// Set video format of #71 port and compute the camera buffer size.

  //Step 1 - get default parameters

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nPortIndex := 71;

OMX_GetParameter(pcamera, OMX_IndexParamPortDefinition, @portDef);

  //Step 2 - set needed video format

formatVideo := @portDef.format.video;
formatVideo^.eColorFormat 	:= OMX_COLOR_FormatYUV420PackedPlanar;
formatVideo^.nFrameWidth	:= width;
formatVideo^.nFrameHeight	:= height;
formatVideo^.xFramerate		:= fps shl 16;   	     // Fixed point
formatVideo^.nStride		:= formatVideo^.nFrameWidth; // has to be <>0.
formatVideo^.nSliceHeight       := height;

err := OMX_SetParameter(pcamera, OMX_IndexParamPortDefinition, @portDef);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(formatVideo^.eColorFormat)+ ' camera set format FAIL');
  result:=3;  // error while setting the video format
  goto p999;
  end;

print_log('Camera video format set to '+inttostr(formatVideo^.eColorFormat )+' '+inttostr(width)+'x'+inttostr(height));

//Step 3 - retrieve new parameters from the camera after setting and compute the buffers size

OMX_GetParameter(pcamera, OMX_IndexParamPortDefinition, @portDef);
formatVideo := @portDef.format.video;
sizey := formatVideo^.nFrameWidth * formatVideo^.nSliceHeight;
sizeu:=sizey div 4;
sizev:=sizey div 4;
buffersize:=sizey+sizeu+sizev;
print_log('Camera slice height is ' + inttostr(formatVideo^.nSliceHeight));
print_log('Camera buffer size Y: '+inttostr(sizey));
print_log('Camera buffer size U: '+inttostr(sizeU));
print_log('Camera buffer size V: '+inttostr(sizeV));

// ------------- End of video format setting -----------------------------------

//------ Change the components state from loaded to idle------------------------

err := OMX_SendCommand(pcamera, OMX_CommandStateSet, OMX_StateIdle, nil);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'camera idle request FAIL');
  result:=4;  // error while switching the camera to the idle state
  goto p999;
  end;

print_log('Camera state set to idle');

//----- Allocate buffers to the camera

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nPortIndex := 71;

OMX_GetParameter(pcamera, OMX_IndexParamPortDefinition, @portDef);
OMX_AllocateBuffer(pcamera, @pCameraOutBuffer, 71, nil, portDef.nBufferSize);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'allocate camera buffer FAIL');
  result:=5;  // error while allocating camera buffer
  goto p999;
  end;

print_log('Allocated '+inttostr(portDef.nBufferCountActual)+' camera buffers size '+inttostr(portDef.nBufferSize));

  //--- set working variables

pY:=pCameraOutBuffer^.pBuffer;
pU:=pointer(cardinal(pY) + sizey);
pV:=pointer(cardinal(pU) + sizeu);
camerabuffer:=cardinal(pY);
print_log('Y buffer at '+inttohex(cardinal(pY),8));
print_log('U buffer at '+inttohex(cardinal(pY),8));
print_log('V buffer at '+inttohex(cardinal(pY),8));

//------- wait until components state is idle

if wait_for_state_change(OMX_StateIdle, pcamera)=OMX_FALSE then
  begin
  print_log('*** Failed waiting for camera idle state');
  result:=6;  // camera didn't reached the idle state
  goto p999;
  end;

print_log('Camera state is now idle');

result:=cardinal(pY);
p999:

end;

//------------------------------------------------------------------------------
//
// Camera start.
// Switch the camera to the running state and start the worker thread
//
//------------------------------------------------------------------------------

function startcamera:cardinal;

label p999;

begin

if cameraworkerthread<>nil then goto p999;

//------ Change the components state from idle to executing---------------------

err := OMX_SendCommand(pcamera, OMX_CommandStateSet, OMX_StateExecuting, nil);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+' Camera executing FAIL');
  result:=7; // Change state to executing failed
  goto p999;
  end;

if wait_for_state_change(OMX_StateExecuting, pcamera)=OMX_FALSE then
  begin
  print_log('*** Failed waiting for renderer executing state');
  result:=8; // the camera didn't switch to executing state
  goto p999;
  end;

print_log('Camera state is now executing');

//----------- Start capturing at port 71 --------------------------------------

print_log('Capture start.');

FillChar (portCapturing, SizeOf(portCapturing), 0);
portCapturing.nSize := sizeof(portCapturing);
portCapturing.nVersion.nVersion := OMX_VERSION;
portCapturing.nPortIndex := 71;
portCapturing.bEnabled := OMX_TRUE;
OMX_SetConfig(pcamera, OMX_IndexConfigPortCapturing, @portCapturing);
frames:=0;

cameraworkerthread:=TCameraworkerthread.create(true);
cameraworkerthread.start;

result:=0;
p999:
end;

//------------------------------------------------------------------------------
//
// Camera stop.
// Switch the camera to the idle state and stop the worker thread
//
//------------------------------------------------------------------------------

function stopcamera:cardinal;

label p999;
var cnt:integer;

begin
if cameraworkerthread=nil then
  begin
  print_log(' *** Nothing to stop, exiting');
  result:=10;
  goto p999;
  end;

print_log('*** Terminating camera worker.');
cameraworkerthreadterminate:=true;
cnt:=0;
repeat cnt+=1; threadsleep(50) until (cameraworkerthreadterminate=false) or (cnt>50);
cameraworkerthread.destroy;
cameraworkerthread:=nil;
print_log('*** Camera worker destroyed.');
portCapturing.bEnabled := OMX_FALSE;
OMX_SetConfig(pcamera, OMX_IndexConfigPortCapturing, @portCapturing);
print_log('Capture stop.');
print_log('Terminating...');
if(isState(pcamera, OMX_StateExecuting))=OMX_TRUE then
  OMX_SendCommand(pcamera, OMX_CommandStateSet, OMX_StateIdle, nil);
if wait_for_state_change(OMX_StateIdle, pcamera)=OMX_FALSE then
  begin
  print_log('*** Failed waiting for renderer executing state');
  result:=9; // the camera didn't return to idle state
  end
else result:=0;
p999:
end;

//------------------------------------------------------------------------------
//
// Camera unload and switch off.
//
//------------------------------------------------------------------------------

function destroycamera:cardinal;


begin

// Idle -> Loaded

if(isState(pcamera, OMX_StateIdle)) =OMX_TRUE then
  OMX_SendCommand(pcamera, OMX_CommandStateSet, OMX_StateLoaded, nil);
threadsleep(20); // wait for state change to loaded doesn't work ?

// Loaded -> Free

if(isState(pcamera, OMX_StateLoaded))=OMX_TRUE then OMX_FreeHandle(pcamera);
OMX_Deinit();
print_log('Terminated. ');
end;



end.

