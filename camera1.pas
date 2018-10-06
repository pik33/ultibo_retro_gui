unit Camera1;

interface

{$mode delphi}{$H+}
//{$define use_tftp}    // if PI not connected to LAN and set for DHCP then remove this

uses
  classes,sysutils,uIL_Client, uOMX, VC4, threads,
  retromalina, mwindows,blitter;



(* based on hjimbens camera example
   https://www.raspberrypi.org/forums/viewtopic.php?t=44852

   pjde 2018 *)

const
  kRendererInputPort                       = 90;
  kClockOutputPort0                        = 80;
  kCameraCapturePort                       = 71;  //71
  kCameraClockPort                         = 73;

type TCameraThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


const 	COMPONENT_CAMERA='OMX.broadcom.camera';
const   COMPONENT_RENDER='OMX.broadcom.video_render';


type PContext=^context;


  context=record
  pcamera:OMX_HANDLETYPE;
  prender:OMX_HANDLETYPE;
  iscameraready:OMX_BOOL;
  nwidth,nheight,nframerate:cardinal;
  pBufferCameraOut:^OMX_BUFFERHEADERTYPE;
  pSrcY,pSrcU,pSrcV:^OMX_U8;
  nSizeY, nSizeU, nSizeV:cardinal;
  pBufferPool:array[0..15] of ^OMX_BUFFERHEADERTYPE;  //	OMX_BUFFERHEADERTYPE**
  nBufferPoolSize,nBufferPoolIndex:cardinal;
  isFilled:OMX_BOOL;
  end;




procedure camera_tunnel_not;

var camerathread:TCameraThread;
    cmw:pointer=nil;
    camerawindow:TWindow=nil;

    mContext:context;

    bc: PILCLIENT_BUFFER_CALLBACK_T;

implementation

procedure print_log(s:string);

begin
camerawindow.println(s);
end;


procedure bc1(userdata : pointer; comp : PCOMPONENT_T); cdecl;

begin
  camerawindow.println('Callback called');
end;

constructor TCameraThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TCameraThread.execute;

label p999;

begin
ThreadSetpriority(ThreadGetCurrent,6);
sleep(1);
  if camerawindow=nil then
    begin
    camerawindow:=TWindow.create(480,3200,'Camera log');
    camerawindow.decoration.hscroll:=true;
    camerawindow.decoration.vscroll:=true;
    camerawindow.resizable:=true;
    camerawindow.cls(147);
    camerawindow.tc:=154;
    camerawindow.move(1200,64,480,1100,0,0);
    cmw:=camerawindow;
    end
  else goto p999;
  camera_tunnel_not;
  repeat sleep(100) until camerawindow.needclose;
  camerawindow.destroy;
  camerawindow:=nil;
  cmw:=nil;
  p999:
end;


//  /----------------------------------------------------------------------------------------------------------
//   ============================================================================
//   Name        : camera_tunnel_non.c
//   Author      : SonienTaegi ( https://github.com/SonienTaegi/rpi-omx-tutorial )
//   Version     :
//   Copyright   : GPLv2
//   Description : This is tutorial of OpenMAX to play currently captured video frames.
//                 Without tunneling, client handles any events of components and
//                 copy camera buffer to renderer buffer if it needs.
//                 Finally client requests empty buffer to renderer so renderer shows
//                 the captured frame on user screen.
//
//                 Without propriety communication, it costs large amount of CPU works.
//                 So it is slow and not so efficient. But this technique may need when
//                 modulate current captured buffer directly.
//   ============================================================================
//   */

// Event Handler : OMX Event */

// OMX_IN ???

function onOMXevent (
		hComponent: OMX_HANDLETYPE;
		pAppData:OMX_PTR;
		eEvent: OMX_EVENTTYPE;
		nData1: OMX_U32;
		nData2: OMX_U32;
		pEventData: OMX_PTR): OMX_ERRORTYPE; cdecl;

begin

  print_log('Callback called '+inttostr(ndata1)+' '+inttostr(ndata2)) ;// hComponent, eEvent, nData1, nData2);

  case eEvent of
  OMX_EventParamOrConfigChanged :
                begin
                print_log('Param or config changed ');
		if(nData2 = OMX_IndexParamCameraDeviceNumber) then
                        begin
			Pcontext(pAppData)^.isCameraReady := OMX_TRUE;
			camerawindow.println('Camera device is ready.');
                        end;
                end;
  end;

result:= OMX_ErrorNone;
end;


//* Callback : Camera-out buffer is filled */

function onFillCameraOut (
		hComponent:OMX_HANDLETYPE;
		pAppData: OMX_PTR;
		pBuffer: POMX_BUFFERHEADERTYPE): OMX_ERRORTYPE; cdecl;

begin
	mContext.isFilled := OMX_TRUE;
	result:=OMX_ErrorNone;
end;


//* Callback : Render-in buffer is emptied */

function onEmptyRenderIn(
		hComponent: OMX_HANDLETYPE;
		pAppData:  OMX_PTR;
	        PBuffer: POMX_BUFFERHEADERTYPE):OMX_ERRORTYPE ; cdecl;

begin
 // camerawindow.println('buffer '+ inttohex(cardinal(pbuffer),8)+' emptied');
  result:= OMX_ErrorNone;
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
camerawindow.println('Waiting for '+inttohex(cardinal(handle),8));
isValid := OMX_FALSE;
while (timeout_counter < 5000) and (isValid=OMX_FALSE) do
  begin
  timeout_counter:=0;
  OMX_GetState(handle, @state_current);
  if (state_current <> state_tobe) then begin threadsleep(1); inc(timeout_counter); end else IsValid:=OMX_TRUE;
  end;
result:=IsValid;
end;

procedure terminate;

var state:OMX_STATETYPE;
    bWaitForCamera, bWaitForRender: OMX_BOOL;


begin
camerawindow.println('On terminating...');
bWaitForCamera := OMX_FALSE;
bWaitForRender := OMX_FALSE;
if(isState(mContext.pCamera, OMX_StateExecuting))=OMX_TRUE then
  begin
  OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateIdle, nil);
  bWaitForCamera := OMX_TRUE;
  end;
if(isState(mContext.pRender, OMX_StateExecuting))=OMX_TRUE then
  begin
  OMX_SendCommand(mContext.pRender, OMX_CommandStateSet, OMX_StateIdle, nil);
  bWaitForRender := OMX_TRUE;
  end;
if(bWaitForCamera=OMX_TRUE) then wait_for_state_change(OMX_StateIdle, mContext.pCamera);
if(bWaitForRender=OMX_TRUE) then wait_for_state_change(OMX_StateIdle, mContext.pRender);

// Idle -> Loaded

bWaitForCamera := OMX_FALSE;
bWaitForRender := OMX_FALSE;

if(isState(mContext.pCamera, OMX_StateIdle)) =OMX_TRUE then
  begin
  OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateLoaded, nil);
  bWaitForCamera := OMX_TRUE;
  end;
if(isState(mContext.pRender, OMX_StateIdle)) then
  begin
  OMX_SendCommand(mContext.pRender, OMX_CommandStateSet, OMX_StateLoaded, nil);
  bWaitForRender := OMX_TRUE;
  end;
if(bWaitForCamera=OMX_TRUE) then wait_for_state_change(OMX_StateLoaded, mContext.pCamera);
if(bWaitForRender=OMX_TRUE) then wait_for_state_change(OMX_StateLoaded, mContext.pRender);

// Loaded -> Free

if(isState(mContext.pCamera, OMX_StateLoaded))=OMX_TRUE then OMX_FreeHandle(mContext.pCamera);
if(isState(mContext.pRender, OMX_StateLoaded))=OMX_TRUE then OMX_FreeHandle(mContext.pRender);

OMX_Deinit();

camerawindow.println('Press enter to terminate.');
while keypressed do readkey;
repeat until keypressed;
end;


procedure componentLoad(pCallbackOMX:POMX_CALLBACKTYPE);

var err:OMX_ERRORTYPE;

begin

// Loading component

//print_log('Load ' +COMPONENT_CAMERA);
err := OMX_GetHandle(@(mContext.pCamera), COMPONENT_CAMERA, @mContext, pCallbackOMX);
if (err <> OMX_ErrorNone ) then
  begin
  print_log('error loading camera'+inttostr(err));
  terminate();
  //exit(-1);
  end;
//mcontext.pcamera:=pointer(cardinal(mcontext.pcamera) and $3FFFFFFF);

print_log('Handler address: camera '+inttohex(cardinal(mContext.pCamera),8));

print_log('Load ' +COMPONENT_RENDER);
err := OMX_GetHandle(@(mContext.pRender), COMPONENT_RENDER, @mContext, pCallbackOMX);
if (err <> OMX_ErrorNone ) then
  begin
  print_log('error loading renderer'+inttostr(err));
  terminate();
  //exit(-1);
  end;
//mcontext.prender:=pointer(cardinal(mcontext.prender) and $3FFFFFFF);
print_log('Handler address: renderer '+inttohex(cardinal(mContext.pRender),8));
end;


procedure componentConfigure;

var err: OMX_ERRORTYPE;
    portDef: OMX_PARAM_PORTDEFINITIONTYPE;
    formatVideo:POMX_VIDEO_PORTDEFINITIONTYPE;
    configCameraCallback:OMX_CONFIG_REQUESTCALLBACKTYPE;
    deviceNumber:OMX_PARAM_U32TYPE;
    displayRegion:OMX_CONFIG_DISPLAYREGIONTYPE;

begin

// Disable any unused ports

OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 70, nil);
OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 72, nil);
OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 73, nil);

// Configure OMX_IndexParamCameraDeviceNumber callback enable to ensure whether camera is initialized properly.

print_log('Configure DeviceNumber callback enable.');
FillChar (configCameraCallback, SizeOf(configCameraCallback), 0);
configCameraCallback.nSize := sizeof(configCameraCallback);
configCameraCallback.nVersion.nVersion := OMX_VERSION;
configCameraCallback.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
configCameraCallback.nVersion.nVersionMinor := OMX_VERSION_MINOR;
configCameraCallback.nVersion.nRevision := OMX_VERSION_REVISION;
configCameraCallback.nVersion.nStep := OMX_VERSION_STEP;

configCameraCallback.nPortIndex	:= OMX_ALL;	// Must Be OMX_ALL
configCameraCallback.nIndex 	:= OMX_IndexParamCameraDeviceNumber;
configCameraCallback.bEnable 	:= OMX_TRUE;

err := OMX_SetConfig(mContext.pCamera, OMX_IndexConfigRequestCallback, @configCameraCallback);
if err<> OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'camera set config FAIL');
  terminate();
//exit(-1);
  end;

// OMX CameraDeviceNumber set -> will trigger Camera Ready callback

print_log('Set CameraDeviceNumber parameter.');
FillChar (deviceNumber, SizeOf(deviceNumber), 0);
deviceNumber.nSize := sizeof(deviceNumber);
deviceNumber.nVersion.nVersion := OMX_VERSION;
deviceNumber.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
deviceNumber.nVersion.nVersionMinor := OMX_VERSION_MINOR;
deviceNumber.nVersion.nRevision := OMX_VERSION_REVISION;
deviceNumber.nVersion.nStep := OMX_VERSION_STEP;
deviceNumber.nPortIndex := OMX_ALL;
deviceNumber.nU32 := 0;	// Mostly zero
err := OMX_SetParameter(mContext.pCamera, OMX_IndexParamCameraDeviceNumber, @deviceNumber);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'camera set number FAIL');
  terminate();
  //exit(-1);
  end;

// Set video format of #71 port.

print_log('Set video format of the camera : Using #71.');
FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 71;

print_log('Get non-initialized definition of #71.');
OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);

print_log('Set up parameters of video format of #71.');

formatVideo := @portDef.format.video;
formatVideo^.eColorFormat 	:= OMX_COLOR_FormatYUV420PackedPlanar;
formatVideo^.nFrameWidth	:= mContext.nWidth;
formatVideo^.nFrameHeight	:= mContext.nHeight;
formatVideo^.xFramerate		:= mContext.nFramerate shl 16;   	// Fixed point. 1
formatVideo^.nStride		:= formatVideo^.nFrameWidth;		// Stride 0 -> Raise segment fault.
formatVideo^.nSliceHeight:=768;
err := OMX_SetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'camera set format FAIL');
  terminate();
  //exit(-1);
  end;

OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
formatVideo := @portDef.format.video;
mContext.nSizeY := formatVideo^.nFrameWidth * formatVideo^.nSliceHeight;
mContext.nSizeU	:= mContext.nSizeY div 4;
mContext.nSizeV	:= mContext.nSizeY div 4;
print_log(inttostr(mContext.nSizeY)+' '+inttostr(mContext.nSizeU)+' '+inttostr(mContext.nSizeV));

// Set video format of #90 port.

print_log('Set video format of the render : Using #90.');

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 90;

print_log('Get default definition of #90.');
OMX_GetParameter(mContext.pRender, OMX_IndexParamPortDefinition, @portDef);

print_log('Set up parameters of video format of #90.');

formatVideo := @portDef.format.video;
formatVideo^.eColorFormat 		:= OMX_COLOR_FormatYUV420PackedPlanar;
formatVideo^.eCompressionFormat	        := OMX_VIDEO_CodingUnused;
formatVideo^.nFrameWidth		:= mContext.nWidth;
formatVideo^.nFrameHeight		:= mContext.nHeight;
formatVideo^.nStride			:= mContext.nWidth;
formatVideo^.nSliceHeight		:= mContext.nHeight;
formatVideo^.xFramerate			:= mContext.nFramerate shl 16;

err := OMX_SetParameter(mContext.pRender, OMX_IndexParamPortDefinition, @portDef);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'renderer set format FAIL');
  terminate();
  //exit(-1);
  end;

// Configure rendering region

FillChar (displayRegion, SizeOf(displayRegion), 0);
displayRegion.nSize := sizeof(displayRegion);
displayRegion.nVersion.nVersion := OMX_VERSION;
displayRegion.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
displayRegion.nVersion.nVersionMinor := OMX_VERSION_MINOR;
displayRegion.nVersion.nRevision := OMX_VERSION_REVISION;
displayRegion.nVersion.nStep := OMX_VERSION_STEP;

displayRegion.nPortIndex := 90;
displayRegion.dest_rect.width 	:= mContext.nWidth;
displayRegion.dest_rect.height 	:= mContext.nHeight;
displayRegion.set_ := OMX_DISPLAY_SET_NUM or OMX_DISPLAY_SET_FULLSCREEN or OMX_DISPLAY_SET_MODE or OMX_DISPLAY_SET_DEST_RECT;
displayRegion.mode := OMX_DISPLAY_MODE_FILL;
displayRegion.fullscreen := OMX_FALSE;
displayRegion.num := 0;

err := OMX_SetConfig(mContext.pRender, OMX_IndexConfigDisplayRegion, @displayRegion);

if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'renderer set region FAIL');
  terminate();
  //exit(-1);
  end;

// Wait up for camera being ready.

print_log('Waiting until camera device is ready');
//while (mContext.isCameraReady=OMX_FALSE) do
//  begin
//
//  end;
sleep(2000);
print_log('Camera is ready');
end;


procedure componentPrepare;


var err:OMX_ERRORTYPE;
    portDef:OMX_PARAM_PORTDEFINITIONTYPE;
    i:cardinal;

begin

// Request state of components to be IDLE.
// The command will turn the component into waiting mode.
// After allocating buffer to all enabled ports than the component will be IDLE.

print_log('STATE : CAMERA - IDLE request');
err := OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateIdle, nil);

if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'camera idle request FAIL');
  terminate();
  //exit(-1);
  end;

print_log('STATE : RENDER - IDLE request');
err := OMX_SendCommand(mContext.pRender, OMX_CommandStateSet, OMX_StateIdle, nil);

if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+ 'renderer idle request FAIL');
  terminate();
  //exit(-1);
  end;

// Allocate buffers to render

print_log('Allocate buffer to renderer #90 for input.');
FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 90;

OMX_GetParameter(mContext.pRender, OMX_IndexParamPortDefinition, @portDef);
print_log('Size of render predefined buffer :'+inttostr(portDef.nBufferSize)+' '+inttostr(portDef.nBufferCountActual));

mContext.nBufferPoolSize 	:= portDef.nBufferCountActual;
mContext.nBufferPoolIndex 	:= 0;
//mContext.pBufferPool		:= getmem(sizeof(pointer) * mContext.nBufferPoolSize); // OMX_BUFFERHEADERTYPE* - pointer?

for i:=0 to mContext.nBufferPoolSize-1 do
  begin
  mContext.pBufferPool[i] := nil;
  err := OMX_AllocateBuffer(mContext.pRender, @(mContext.pBufferPool[i]), 90, @mContext, portDef.nBufferSize);
  if err<>OMX_ErrorNone then
    begin
    print_log(inttostr(err)+ 'allocate render buffer FAIL');
    terminate();
    //exit(-1);
    end;
  end;

// Allocate buffer to camera

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 71;

OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
print_log('Size of camera predefined buffer :'+inttostr(portDef.nBufferSize)+' '+inttostr(portDef.nBufferCountActual));
OMX_AllocateBuffer(mContext.pCamera, @mContext.pBufferCameraOut, 71, @mContext, portDef.nBufferSize);

  if err<>OMX_ErrorNone then
    begin
    print_log(inttostr(err)+ 'allocate camera buffer FAIL');
    terminate();
    //exit(-1);
    end;

mContext.pSrcY 	:= mContext.pBufferCameraOut^.pBuffer;
mContext.pSrcU	:= pointer(cardinal(mContext.pSrcY) + mContext.nSizeY);
mContext.pSrcV	:= pointer(cardinal(mContext.pSrcU) + mContext.nSizeU);
print_log(inttohex(cardinal(mContext.pSrcY),8)+' '+inttohex(cardinal(mContext.pSrcU),8)+' '+inttohex(cardinal(mContext.pSrcV),8));
for i:=0 to 16 do removeramlimits(cardinal(mContext.pSrcY)+i*4096);
// Wait up for component being idle.

if wait_for_state_change(OMX_StateIdle, mContext.pRender)=OMX_FALSE then
  begin
  print_log('FAIL waiting for idle state');
  terminate();
//  exit(-1);
  end;

if wait_for_state_change(OMX_StateIdle, mContext.pCamera)=OMX_FALSE then
  begin
  print_log('FAIL waiting for idle state');
  terminate();
//  exit(-1);
  end;

print_log('STATE : IDLE OK!');
end;

// -- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


procedure camera_tunnel_not;

label p999;

///* Temporary variables */

var err:OMX_ERRORTYPE;
    portdef:OMX_PARAM_PORTDEFINITIONTYPE;
    callbackOMX:OMX_CALLBACKTYPE;
    portCapturing:OMX_CONFIG_PORTBOOLEANTYPE;
    py:POMX_U8=nil;
    pu:POMX_U8=nil;
    pv:POMX_U8=nil;
    py2:POMX_U8=nil;
    pu2:POMX_U8=nil;
    pv2:POMX_U8=nil;
    nOffsetU, nOffsetV, nFrameMax, nFrames:cardinal;
    PBuffer: POMX_BUFFERHEADERTYPE;
    i:integer;
    qqq:int64;

begin
//* Initialize application variables */

FillChar (mContext, SizeOf(mContext), 0);
mContext.nWidth 	:= 1024;
mContext.nHeight 	:= 768;
mContext.nFramerate	:= 25;

// RPI initialize.
bcmhostinit;

// OMX initialize.
print_log('Initialize OMX');
err := OMX_Init;
if err<> OMX_ErrorNone then
  begin
  print_log(inttostr(err)+' OMX init FAIL');
  OMX_Deinit();
  goto p999;
  end;

// For loading component, Callback shall provide.

callbackOMX.EventHandler	:= onOMXevent;
callbackOMX.EmptyBufferDone	:= onEmptyRenderIn;
callbackOMX.FillBufferDone	:= onFillCameraOut;

componentLoad(@callbackOMX);
componentConfigure();
componentPrepare();

// Request state of component to be EXECUTE.

print_log('STATE : CAMERA - EXECUTING request');
err := OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateExecuting, nil);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+' Camera executing FAIL');
  goto p999;
  end;

print_log('STATE : RENDER - EXECUTING request');
err := OMX_SendCommand(mContext.pRender, OMX_CommandStateSet, OMX_StateExecuting, nil);
if err<>OMX_ErrorNone then
  begin
  print_log(inttostr(err)+' Renderer executing FAIL');
  goto p999;
  end;

if wait_for_state_change(OMX_StateExecuting, mContext.pCamera)=OMX_FALSE then
  begin
  print_log(inttostr(err)+' Camera wait for executing FAIL');
  goto p999;
  end;

if wait_for_state_change(OMX_StateExecuting, mContext.pRender)=OMX_FALSE then
  begin
  print_log(inttostr(err)+' Renderer wait for executing FAIL');
  goto p999;
  end;

print_log('STATE : EXECUTING OK!');

// Since #71 is capturing port, needs capture signal like other handy capture devices

print_log('Capture start.');

FillChar (portCapturing, SizeOf(portCapturing), 0);
portCapturing.nSize := sizeof(portCapturing);
portCapturing.nVersion.nVersion := OMX_VERSION;
portCapturing.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portCapturing.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portCapturing.nVersion.nRevision := OMX_VERSION_REVISION;
portCapturing.nVersion.nStep := OMX_VERSION_STEP;

portCapturing.nPortIndex := 71;
portCapturing.bEnabled := OMX_TRUE;
OMX_SetConfig(mContext.pCamera, OMX_IndexConfigPortCapturing, @portCapturing);

pY := nil;
pU := nil;
pV := nil;
nOffsetU := mContext.nWidth * mContext.nHeight;
nOffsetV := (nOffsetU * 5) div 4;
nFrameMax:= mContext.nFramerate * 60;
nFrames	:= 0;

print_log('Capture for '+inttostr(nFramemax)+' frames.');
OMX_FillThisBuffer(mContext.pCamera, mContext.pBufferCameraOut);

while(nFrames < nFrameMax) do
  begin
  if (mContext.isFilled) then
    begin

    pBuffer := mContext.pBufferPool[mContext.nBufferPoolIndex];

    if(pBuffer^.nFilledLen = 0) then
      begin
      pY := pBuffer^.pBuffer;
      pU := pointer(cardinal(pY) + nOffsetU);
      pV := pointer(cardinal(pY) + nOffsetV);
      end;
    py:=pointer(cardinal(py));// and $3FFFFFFF);
    pu:=pointer(cardinal(pu));// and $3FFFFFFF);
    pv:=pointer(cardinal(pv));//; and $3FFFFFFF);
    py2:=pointer(cardinal(mContext.pSrcY));//; and $3FFFFFFF);
    pu2:=pointer(cardinal(mContext.pSrcU));// and $3FFFFFFF);
    pv2:=pointer(cardinal(mContext.pSrcV));// and $3FFFFFFF);

  //    print_log('nsizey is '+inttostr(mcontext.nsizey));

    fastmove(integer(pY2), integer(py), mContext.nSizeY);	pY := pointer(cardinal(py)+mContext.nSizeY);
    fastmove(integer(pU2), integer(pu), mContext.nSizeU);	pU := pointer(cardinal(pu)+mContext.nSizeU);
    fastmove(integer(pV2), integer(pv), mContext.nSizeV);	pV := pointer(cardinal(pv)+mContext.nSizeV);
    pBuffer^.nFilledLen += mContext.pBufferCameraOut^.nFilledLen;


    if (mContext.pBufferCameraOut^.nFlags and OMX_BUFFERFLAG_ENDOFFRAME)<>0 then
      begin
      print_log('BUFFER '+inttohex(cardinal(pbuffer),8)+' filled');
      OMX_EmptyThisBuffer(mContext.pRender, pBuffer);
      mContext.nBufferPoolIndex+=1;
      if(mContext.nBufferPoolIndex = mContext.nBufferPoolSize) then mContext.nBufferPoolIndex := 0;
      nFrames+=1;
      end;

    mContext.isFilled := OMX_FALSE;
    qqq:=gettime;
    OMX_FillThisBuffer(mContext.pCamera, mContext.pBufferCameraOut);
    qqq:=gettime-qqq;
    print_log('time is '+inttostr(qqq));
    end;
  threadsleep(1);
  end;

portCapturing.bEnabled := OMX_FALSE;
OMX_SetConfig(mContext.pCamera, OMX_IndexConfigPortCapturing, @portCapturing);
print_log('Capture stop.');
p999:
terminate;
end;




end.

