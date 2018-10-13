unit Camera1;

//   Based on camera_tunnel_non.c by SonienTaegi
//   Copyright: GPLv2

interface

uses
  classes,sysutils,uIL_Client, uOMX, VC4, threads,
  retromalina, mwindows, blitter, retro;

type TCameraThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


const 	COMPONENT_CAMERA='OMX.broadcom.camera';
const   COMPONENT_RENDER='OMX.broadcom.video_render';

const cxres=1280;
      cyres=720;

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
    rendertestwindow:TWindow=nil;
    mContext:context;
    at,at1,at2,t1,t2,t3,t4:int64;

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
setpallette(grayscalepallette,0);
  if camerawindow=nil then
    begin
    camerawindow:=TWindow.create(480,800,'Camera log');
    camerawindow.decoration.hscroll:=true;
    camerawindow.decoration.vscroll:=true;
    camerawindow.resizable:=true;
    camerawindow.cls(0);
    camerawindow.tc:=252;
    camerawindow.move(1200,64,480,1100,0,0);
    cmw:=camerawindow;
    end
  else goto p999;
  if rendertestwindow=nil then
    begin
    rendertestwindow:=TWindow.create(cxres,cyres,'Camera render');
    rendertestwindow.decoration.hscroll:=false;
    rendertestwindow.decoration.vscroll:=false;
    rendertestwindow.resizable:=true;
    rendertestwindow.cls(0);
    rendertestwindow.tc:=15;
    rendertestwindow.move(800,400,cxres,cyres,0,0);
    end;
  camera;
  repeat sleep(100) until camerawindow.needclose;
  camerawindow.destroy;
  camerawindow:=nil;
  rendertestwindow.destroy;
  rendertestwindow:=nil;
  cmw:=nil;
  p999:
  setpallette(ataripallette,0);
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



// Allocate buffer to camera




//for i:=0 to 16 do removeramlimits(cardinal(mContext.pSrcY)+i*4096);
// Wait up for component being idle.



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
    y,u,v,y2,u2,v2:cardinal;

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
mContext.nWidth 	:= cxres;
mContext.nHeight 	:= cyres;
mContext.nFramerate	:= 60;

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
formatVideo^.eColorFormat 	:= OMX_COLOR_FormatMonochrome; // OMX_COLOR_FormatYUV420PackedPlanar;
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
displayRegion.dest_rect.width 	:= mContext.nWidth div 2;
displayRegion.dest_rect.height 	:= mContext.nHeight div 2;
displayRegion.dest_rect.x_offset := 30;
displayRegion.dest_rect.y_offset := 30;
displayRegion.set_ := OMX_DISPLAY_SET_NUM or OMX_DISPLAY_SET_FULLSCREEN or OMX_DISPLAY_SET_MODE or OMX_DISPLAY_SET_DEST_RECT;
displayRegion.mode := OMX_DISPLAY_MODE_FILL;
displayRegion.fullscreen := OMX_FALSE;
displayRegion.num := 0;

err := OMX_SetConfig(mContext.pRender, OMX_IndexConfigDisplayRegion, @displayRegion);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'renderer set region FAIL');
print_log('Renderer display region set to '+inttostr(displayRegion.dest_rect.width)+'x'+inttostr(displayRegion.dest_rect.height ));

//------ End of renderer format setting ----------------------------------------

//------ Change the components state from loaded to idle------------------------

err := OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateIdle, nil);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'camera idle request FAIL');
print_log('Camera state set to idle');


err := OMX_SendCommand(mContext.pRender, OMX_CommandStateSet, OMX_StateIdle, nil);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'renderer idle request FAIL');
print_log('Renderer state set to idle');

//----- Allocate buffers to render

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 90;

OMX_GetParameter(mContext.pRender, OMX_IndexParamPortDefinition, @portDef);

mContext.nBufferPoolSize 	:= portDef.nBufferCountActual;
mContext.nBufferPoolIndex 	:= 0;

for i:=0 to mContext.nBufferPoolSize-1 do
  begin
  mContext.pBufferPool[i] := nil;
  err := OMX_AllocateBuffer(mContext.pRender, @(mContext.pBufferPool[i]), 90, @mContext, portDef.nBufferSize);
  if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'allocate render buffer FAIL');
  end;

print_log('Allocated '+inttostr(portDef.nBufferCountActual)+' render buffers size '+inttostr(portDef.nBufferSize));

//----- Allocate buffers to camera

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nVersion.nVersionMajor := OMX_VERSION_MAJOR;
portDef.nVersion.nVersionMinor := OMX_VERSION_MINOR;
portDef.nVersion.nRevision := OMX_VERSION_REVISION;
portDef.nVersion.nStep := OMX_VERSION_STEP;
portDef.nPortIndex := 71;

OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
OMX_AllocateBuffer(mContext.pCamera, @mContext.pBufferCameraOut, 71, @mContext, portDef.nBufferSize);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'allocate camera buffer FAIL');
print_log('Allocated '+inttostr(portDef.nBufferCountActual)+' camera buffers size '+inttostr(portDef.nBufferSize));

  //--- set working variables

mContext.pSrcY 	:= mContext.pBufferCameraOut^.pBuffer;
mContext.pSrcU	:= pointer(cardinal(mContext.pSrcY) + mContext.nSizeY);
mContext.pSrcV	:= pointer(cardinal(mContext.pSrcU) + mContext.nSizeU);

print_log('Y buffer at '+inttohex(cardinal(mContext.pSrcY),8));

//------- wait until components state is idle

if wait_for_state_change(OMX_StateIdle, mContext.pRender)=OMX_FALSE then print_log('*** Failed waiting for renderer idle state')
  else print_log('Renderer state is now idle');

if wait_for_state_change(OMX_StateIdle, mContext.pCamera)=OMX_FALSE then print_log('*** Failed waiting for camera idle state')
  else print_log('Camera state is now idle');

//------ Change the components state from loaded to idle------------------------

err := OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateExecuting, nil);
if err<>OMX_ErrorNone then print_log(inttostr(err)+' Camera executing FAIL');

err := OMX_SendCommand(mContext.pRender, OMX_CommandStateSet, OMX_StateExecuting, nil);
if err<>OMX_ErrorNone then print_log(inttostr(err)+' Renderer executing FAIL');

if wait_for_state_change(OMX_StateExecuting, mContext.pRender)=OMX_FALSE then print_log('*** Failed waiting for renderer executing state')
else print_log('Renderer state is now executing');
if wait_for_state_change(OMX_StateExecuting, mContext.pCamera)=OMX_FALSE then print_log('*** Failed waiting for renderer executing state')
else print_log('Camera state is now executing');



//----------- Start capturing at port 71 --------------------------------------

while keypressed do readkey;
print_log('Capture start. Press any key to stop');

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
nFrameMax:= mContext.nFramerate * 600;
nFrames	:= 0;

print_log('Capture will stop itself after '+inttostr(nFramemax div mContext.nFramerate)+' seconds');

// ---- Fill initial camera buffer

OMX_FillThisBuffer(mContext.pCamera, mContext.pBufferCameraOut);

// ---- Prepare addresses for fastmove

y2:=cardinal(mContext.pSrcY);
u2:=cardinal(mContext.pSrcU);
v2:=cardinal(mContext.pSrcV);

// ----- MAIN CAPTURE LOOP -----------------------------------------------------
while keypressed do readkey;
at:=0; at1:=0; at2:=0;
nframes:=0;
while(nFrames < nFrameMax) and (not keypressed) do
  begin
  if camerabufferfilled then
    begin
    t1:=gettime;

// retromachine blit test
    blit8(y2,0,0,cardinal(rendertestwindow.canvas),0,0,cxres,cyres,cxres,cxres);
    t1:=gettime-t1;  at1+=t1;
    if nframes>0 then t3:=gettime-t3 else t3:=0;
    at+=t3;
        t3:=gettime;
            nFrames+=1;
    rendertestwindow.outtextxy(4,4,inttostr(at1 div nframes),0);
    rendertestwindow.outtextxy(4,34,inttostr(at2 div nframes),0);
    if nframes>1 then rendertestwindow.outtextxy(4,64,inttostr(at div (nframes-1)),0);
    rendertestwindow.outtextxy(4,94,inttostr(nframes),0);




    camerabufferfilled:=false;
    t2:=gettime;
    OMX_FillThisBuffer(mContext.pCamera, mContext.pBufferCameraOut);
    t2:=gettime-t2; at2+=t2;
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

