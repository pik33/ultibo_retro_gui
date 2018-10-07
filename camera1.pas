unit Camera1;

//   Based on camera_tunnel_non.c by SonienTaegi
//   Copyright: GPLv2

interface

uses
  classes,sysutils,uIL_Client, uOMX, VC4, threads,
  retromalina, mwindows, blitter;

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


var camerathread:TCameraThread;
    cmw:pointer=nil;
    camerawindow:TWindow=nil;
    mContext:context;


procedure camera;

implementation

var camerabufferfilled:boolean;

procedure print_log(s:string);

begin
camerawindow.println(s);
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
  camera;
  repeat sleep(100) until camerawindow.needclose;
  camerawindow.destroy;
  camerawindow:=nil;
  cmw:=nil;
  p999:
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

function onFillCameraOut(hComponent:OMX_HANDLETYPE; pAppData: OMX_PTR;pBuffer:POMX_BUFFERHEADERTYPE): OMX_ERRORTYPE; cdecl;

begin
camerabufferfilled:=true;
result:=OMX_ErrorNone;
end;


// Callback: Render buffer empty

function onEmptyRenderIn(hComponent:OMX_HANDLETYPE; pAppData:OMX_PTR; PBuffer:POMX_BUFFERHEADERTYPE): OMX_ERRORTYPE; cdecl;

begin
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
//if(bWaitForCamera=OMX_TRUE) then wait_for_state_change(OMX_StateLoaded, mContext.pCamera);
//if(bWaitForRender=OMX_TRUE) then wait_for_state_change(OMX_StateLoaded, mContext.pRender);

// Loaded -> Free

if(isState(mContext.pCamera, OMX_StateLoaded))=OMX_TRUE then OMX_FreeHandle(mContext.pCamera);
if(isState(mContext.pRender, OMX_StateLoaded))=OMX_TRUE then OMX_FreeHandle(mContext.pRender);

OMX_Deinit();

print_log('Terminated. You can now close the window');

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


procedure camera;

label p999;

var err:OMX_ERRORTYPE;
    portdef:OMX_PARAM_PORTDEFINITIONTYPE;
    callbackOMX:OMX_CALLBACKTYPE;
    portCapturing:OMX_CONFIG_PORTBOOLEANTYPE;
    deviceNumber:OMX_PARAM_U32TYPE;
    formatVideo:POMX_VIDEO_PORTDEFINITIONTYPE;
    displayRegion:OMX_CONFIG_DISPLAYREGIONTYPE;

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

// Initialize variables

FillChar (mContext, SizeOf(mContext), 0);
mContext.nWidth 	:= 1024;
mContext.nHeight 	:= 768;
mContext.nFramerate	:= 25;

// initialize VC4.
bcmhostinit;
print_log('VC4 initialized');

// initialize OMX
OMX_Init;
print_log('OMX initialized');

// Set 3 callbacks needed by OMX components

callbackOMX.EventHandler	:= @onOMXevent;
callbackOMX.EmptyBufferDone	:= @onEmptyRenderIn;
callbackOMX.FillBufferDone	:= @onFillCameraOut;
print_log('Callbacks set');

// Load the camera and the renderer

err := OMX_GetHandle(@(mContext.pCamera), COMPONENT_CAMERA, @mContext, @CallbackOMX);
if (err <> OMX_ErrorNone ) then print_log('error loading camera'+inttostr(err));

print_log('Camera loaded: '+inttohex(cardinal(mContext.pCamera),8));

err := OMX_GetHandle(@(mContext.pRender), COMPONENT_RENDER, @mContext, @CallbackOMX);
if (err <> OMX_ErrorNone ) then print_log('error loading renderer'+inttostr(err));

print_log('Renderer loaded: '+inttohex(cardinal(mContext.pRender),8));

// Disable unused camera ports - we will use #71

OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 70, nil);
OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 72, nil);
OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 73, nil);
print_log('Camera ports 70,72,73 disabled');

// Set camera device number

print_log('Setting CameraDeviceNumber parameter.');

FillChar (deviceNumber, SizeOf(deviceNumber), 0);
deviceNumber.nSize := sizeof(deviceNumber);
deviceNumber.nVersion.nVersion := OMX_VERSION;
deviceNumber.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
deviceNumber.nVersion.nVersionMinor := OMX_VERSION_MINOR;
deviceNumber.nVersion.nRevision := OMX_VERSION_REVISION;
deviceNumber.nVersion.nStep := OMX_VERSION_STEP;
deviceNumber.nPortIndex := OMX_ALL;
deviceNumber.nU32 := 0;

err := OMX_SetParameter(mContext.pCamera, OMX_IndexParamCameraDeviceNumber, @deviceNumber);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'camera set number FAIL');
print_log('Camera device number set to 0');

// Set video format of #71 port and compute the camera buffer size.

  //Step 1 - get default parameters

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 71;

OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);

  //Step 2 - set needed video format

formatVideo := @portDef.format.video;
formatVideo^.eColorFormat 	:= OMX_COLOR_FormatYUV420PackedPlanar;
formatVideo^.nFrameWidth	:= mContext.nWidth;
formatVideo^.nFrameHeight	:= mContext.nHeight;
formatVideo^.xFramerate		:= mContext.nFramerate shl 16;   	// Fixed point. 1
formatVideo^.nStride		:= formatVideo^.nFrameWidth;		// Stride 0 -> Raise segment fault.
formatVideo^.nSliceHeight       := mContext.nHeight;

err := OMX_SetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'camera set format FAIL');
print_log('Camera video format set to '+inttostr(mContext.nWidth)+'x'+inttostr(mContext.nHeight));

  //Step 3 - retrieve new parameters from the camera after setting and compute the buffers size

OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
formatVideo := @portDef.format.video;
mContext.nSizeY := formatVideo^.nFrameWidth * formatVideo^.nSliceHeight;
mContext.nSizeU	:= mContext.nSizeY div 4;
mContext.nSizeV	:= mContext.nSizeY div 4;
print_log('Camera buffer size Y: '+inttostr(mContext.nSizeY)+'; U: '+inttostr(mContext.nSizeU)+'; V: '+inttostr(mContext.nSizeV));

// ------------- End of video format setting -----------------------------------

// Set video format of renderer port #90

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 90;

OMX_GetParameter(mContext.pRender, OMX_IndexParamPortDefinition, @portDef);

formatVideo := @portDef.format.video;
formatVideo^.eColorFormat 		:= OMX_COLOR_FormatYUV420PackedPlanar;
formatVideo^.eCompressionFormat	        := OMX_VIDEO_CodingUnused;
formatVideo^.nFrameWidth		:= mContext.nWidth;
formatVideo^.nFrameHeight		:= mContext.nHeight;
formatVideo^.nStride			:= mContext.nWidth;
formatVideo^.nSliceHeight		:= mContext.nHeight;
formatVideo^.xFramerate			:= mContext.nFramerate shl 16;

err := OMX_SetParameter(mContext.pRender, OMX_IndexParamPortDefinition, @portDef);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'renderer set format failed');
print_log('Renderer video format set to '+inttostr(mContext.nWidth)+'x'+inttostr(mContext.nHeight));

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
displayRegion.dest_rect.x_offset := 30;
displayRegion.dest_rect.y_offset := 30;
displayRegion.set_ := OMX_DISPLAY_SET_NUM or OMX_DISPLAY_SET_FULLSCREEN or OMX_DISPLAY_SET_MODE or OMX_DISPLAY_SET_DEST_RECT;
displayRegion.mode := OMX_DISPLAY_MODE_FILL;
displayRegion.fullscreen := OMX_FALSE;
displayRegion.num := 0;

err := OMX_SetConfig(mContext.pRender, OMX_IndexConfigDisplayRegion, @displayRegion);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'renderer set region FAIL');
print_log('Renderer video format set to '+inttostr(displayRegion.dest_rect.width)+'x'+inttostr(displayRegion.dest_rect.height ));

//------ End of renderer format setting ----------------------------------------


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
  if camerabufferfilled then
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
      OMX_EmptyThisBuffer(mContext.pRender, pBuffer);
      mContext.nBufferPoolIndex+=1;
      if(mContext.nBufferPoolIndex = mContext.nBufferPoolSize) then mContext.nBufferPoolIndex := 0;
      nFrames+=1;
      end;

    camerabufferfilled:=false;
    OMX_FillThisBuffer(mContext.pCamera, mContext.pBufferCameraOut);
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

