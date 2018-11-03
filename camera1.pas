unit camera1;

//   Based on camera_tunnel_non.c by SonienTaegi
//   Copyright: GPLv2

interface

uses
  classes,sysutils, uOMX, VC4, threads,
  retromalina, mwindows, blitter, retro, platform;

type TCameraThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


type TPAThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


const 	COMPONENT_CAMERA='OMX.broadcom.camera';


const cxres=640;
      cyres=480;
      cframerate=60;

type cbuffer=array[0..cxres*cyres-1] of byte;
type cbufferl=array[0..(cxres*cyres div 4)-1] of cardinal;

type PContext=^context;


    context=record
            pcamera:OMX_HANDLETYPE;
            iscameraready:OMX_BOOL;
            nwidth,nheight,nframerate:cardinal;
            pBufferCameraOut:^OMX_BUFFERHEADERTYPE;
            pSrcY,pSrcU,pSrcV:^OMX_U8;
            nSizeY, nSizeU, nSizeV:cardinal;
            isFilled:OMX_BOOL;
            end;

type TPoint=array[0..1] of integer;

var camerathread:TCameraThread;
    PAthread:TPAThread;
    cmw:pointer=nil;
    camerawindow:TWindow=nil;
    rendertestwindow:TWindow=nil;
    miniwindow:TWindow=nil;
    mContext:context;
    at,at1,at2,at3,t1,t2,t3,t4:int64;
    testbuf1, testbuf2, testbuf3, testbuf4: cbuffer;
    tb4l:cbufferl absolute testbuf4;
    s1:integer=0;
    nFrames:cardinal=0;

    points:array[0..3900] of TPoint;
    pointnum:integer=0;
    i,j,k,l,m:integer;

procedure camera;

implementation

procedure soap(b1,b2,count:integer);

label p101;

begin


                 asm
                 push {r0-r7}
                 ldr r0,b1
                 ldr r1,b2
                 ldr r2,count
                 mov r3,#0

p101:            add r7,r6
                 add r7,r5
                 ldrb r4,[r0],#1
                 add r7,r4
                 lsr r7,#2
                 strb r7,[r1],#1
                 mov r7,r6
                 mov r6,r5
                 mov r5,r4
                 subs r2,#1
                 bne p101

                 pop {r0-r7}
                 end;


end;





function findpoints(b1,b2,count:integer):integer;

// --- rev 20181102

label p101,p102;

begin


                 asm
                 push {r0-r7}
                 ldr r0,b1
                 ldr r6,b2
                 ldr r1,count
                 mov r2,#0
                 mov r4,#0
                 mov r5,#0
                 mov r7,#0

p101:            mov r5,r4
                 mov r4,r3
                 ldrb r3,[r0],#1
                 add r7,#1
                 add r5,r4
                 add r5,r5,r3,lsl #1
                 cmps r5, #1020

                 streq r7,[r6],#4
                 addeq r2,#1
                 cmps r2,#100
                 bge p102
                 subs r1,#1
                 bne p101

p102:            str r2,result
                 pop {r0-r7}
                 end;


end;





var camerabufferfilled:boolean;

procedure print_log(s:string);

begin
camerawindow.println(s);
end;

constructor TPAThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

constructor TCameraThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);

end;

procedure TPAThread.execute;

var td:int64;
    td2:int64=0;
    n:integer=1;
    i:integer;
    maxx,minx,maxy,miny,xx,yy:integer;

begin
ThreadSetpriority(ThreadGetCurrent,5);
threadsleep(1);
repeat
threadsleep(1);
if s1>0 then

  begin
   SchedulerPreemptDisable(CPUGetCurrent);
  td:=gettime;
 // if s1=1 then diff3(cardinal(@testbuf1),cardinal(@testbuf2),cardinal(@testbuf3),cxres*cyres,8 );
 // if s1=2 then diff3(cardinal(@testbuf2),cardinal(@testbuf1),cardinal(@testbuf3),cxres*cyres,8 );
  diff4(cardinal(@testbuf1),cardinal(@testbuf2),cardinal(@testbuf3),cxres*cyres,24 );
  pointnum:=findpoints(cardinal(@testbuf3),cardinal(@testbuf4),cxres*cyres);


  fastmove(cardinal(@testbuf3),cardinal(miniwindow.canvas),cxres*cyres);
  td:=gettime-td;
   SchedulerPreemptEnable(CPUGetCurrent);
  td2+=td;
  minx:=640; miny:=480; maxx:=-1; maxy:=-1;
    if pointnum>1 then
      begin
      for i:=0 to pointnum-1 do
        begin
        xx:=tb4l[i] mod 640;
        yy:=tb4l[i] div 640;
        if xx<minx then minx:=xx;
        if xx>maxx then maxx:=xx;
        if yy<miny then miny:=yy;
        if yy>maxy then maxy:=yy;

        camerawindow.print(inttostr(xx));
        camerawindow.print(' ');
        camerawindow.println(inttostr(yy));
        end;
      yy:=(miny+maxy) div 2;
      xx:=(minx+maxx) div 2;
      mousex:=miniwindow.x+xx;
      mousey:=miniwindow.y+yy;
      camerawindow.println('');
      end;

  miniwindow.outtextxyz(0,0,inttostr(td2 div n),255,2,2);
  miniwindow.outtextxyz(0,40,inttostr(pointnum),255,2,2);
  n+=1;
  s1:=0;
  end;

until terminated;
end;

procedure TCameraThread.execute;

label p999;

begin
//ThreadSetAffinity(ThreadGetCurrent,2);
//ThreadSetCPU(ThreadGetCurrent,1);
ThreadSetpriority(ThreadGetCurrent,7);
threadsleep(1);

setpallette(grayscalepallette,0);
  if camerawindow=nil then
    begin
    camerawindow:=TWindow.create(480,600,'Camera log');
    camerawindow.decoration.hscroll:=true;
    camerawindow.decoration.vscroll:=true;
    camerawindow.resizable:=true;
    camerawindow.cls(0);
    camerawindow.tc:=252;
    camerawindow.move(1200,64,480,600,0,0);
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
  if miniwindow=nil then
    begin
    miniwindow:=TWindow.create(cxres,cyres,'Camera diff');
    miniwindow.decoration.hscroll:=false;
    miniwindow.decoration.vscroll:=false;
    miniwindow.resizable:=true;
    miniwindow.cls(0);
    miniwindow.tc:=15;
    miniwindow.move(100,100,cxres,cyres,0,0);
    end;
  camera;
  setpallette(ataripallette,0);
  repeat threadsleep(100) until camerawindow.needclose;
  camerawindow.destroy;
  camerawindow:=nil;
  miniwindow.destroy;
  miniwindow:=nil;
  rendertestwindow.destroy;
  rendertestwindow:=nil;
  cmw:=nil;
  p999:
  setpallette(ataripallette,0);
//  PAThread.terminate;
//  PAThread.destroy;
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
//print_log('Waiting for '+inttohex(cardinal(handle),8));
isValid := OMX_FALSE;
while (timeout_counter < 5000) and (isValid=OMX_FALSE) do
  begin
  timeout_counter:=0;
  OMX_GetState(handle, @state_current);
  if (state_current <> state_tobe) then begin threadsleep(1); inc(timeout_counter); end else IsValid:=OMX_TRUE;
  end;
result:=IsValid;
end;


procedure camera;

label p999;

var err:OMX_ERRORTYPE;
    portdef:OMX_PARAM_PORTDEFINITIONTYPE;
    callbackOMX:OMX_CALLBACKTYPE;
    portCapturing:OMX_CONFIG_PORTBOOLEANTYPE;
    deviceNumber:OMX_PARAM_U32TYPE;
    formatVideo:POMX_VIDEO_PORTDEFINITIONTYPE;

    y2:cardinal;

    nOffsetU, nOffsetV, nFrameMax:cardinal;
    PBuffer: POMX_BUFFERHEADERTYPE;

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

// Disable unused camera ports - we will use #71

OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 70, nil);
OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 72, nil);
OMX_SendCommand(mContext.pCamera, OMX_CommandPortDisable, 73, nil);
print_log('Camera ports 70,72,73 disabled');

// Set camera device number

FillChar (deviceNumber, SizeOf(deviceNumber), 0);
deviceNumber.nSize := sizeof(deviceNumber);
deviceNumber.nVersion.nVersion := OMX_VERSION;
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
if err<>OMX_ErrorNone then print_log(inttostr(formatVideo^.eColorFormat)+ ' camera set format FAIL')
else print_log('Camera video format set to '+inttostr(formatVideo^.eColorFormat )+' '+inttostr(mContext.nWidth)+'x'+inttostr(mContext.nHeight));

//Step 3 - retrieve new parameters from the camera after setting and compute the buffers size

OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
formatVideo := @portDef.format.video;
mContext.nSizeY := formatVideo^.nFrameWidth * formatVideo^.nSliceHeight;
print_log('Camera slice height is ' + inttostr(formatVideo^.nSliceHeight));
print_log('Camera buffer size Y: '+inttostr(mContext.nSizeY));

// ------------- End of video format setting -----------------------------------

//------ Change the components state from loaded to idle------------------------

err := OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateIdle, nil);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'camera idle request FAIL');
print_log('Camera state set to idle');

//----- Allocate buffers to camera

FillChar (portDef, SizeOf(portDef), 0);
portDef.nSize := sizeof(portDef);
portDef.nVersion.nVersion := OMX_VERSION;
portDef.nPortIndex := 71;

OMX_GetParameter(mContext.pCamera, OMX_IndexParamPortDefinition, @portDef);
OMX_AllocateBuffer(mContext.pCamera, @mContext.pBufferCameraOut, 71, @mContext, portDef.nBufferSize);
if err<>OMX_ErrorNone then print_log(inttostr(err)+ 'allocate camera buffer FAIL');
print_log('Allocated '+inttostr(portDef.nBufferCountActual)+' camera buffers size '+inttostr(portDef.nBufferSize));

  //--- set working variables

mContext.pSrcY 	:= mContext.pBufferCameraOut^.pBuffer;
print_log('Y buffer at '+inttohex(cardinal(mContext.pSrcY),8));

//------- wait until components state is idle

if wait_for_state_change(OMX_StateIdle, mContext.pCamera)=OMX_FALSE then print_log('*** Failed waiting for camera idle state')
  else print_log('Camera state is now idle');

//------ Change the components state from loaded to idle------------------------

err := OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateExecuting, nil);
if err<>OMX_ErrorNone then print_log(inttostr(err)+' Camera executing FAIL');

if wait_for_state_change(OMX_StateExecuting, mContext.pCamera)=OMX_FALSE then print_log('*** Failed waiting for renderer executing state')
else print_log('Camera state is now executing');

//----------- Start capturing at port 71 --------------------------------------

while keypressed do readkey;
print_log('Capture start. Press any key to stop');

FillChar (portCapturing, SizeOf(portCapturing), 0);
portCapturing.nSize := sizeof(portCapturing);
portCapturing.nVersion.nVersion := OMX_VERSION;
portCapturing.nPortIndex := 71;
portCapturing.bEnabled := OMX_TRUE;
OMX_SetConfig(mContext.pCamera, OMX_IndexConfigPortCapturing, @portCapturing);

nFrameMax:= mContext.nFramerate * 60;
nFrames	:= 0;

print_log('Capture will stop itself after '+inttostr(nFramemax div mContext.nFramerate)+' seconds');

// ---- Fill initial camera buffer

OMX_FillThisBuffer(mContext.pCamera, mContext.pBufferCameraOut);

// ---- Prepare addresses for fastmove

y2:=cardinal(mContext.pSrcY);  at:=0; at2:=0; at3:=0; t1:=gettime;     t2:=t1; t3:=t1;

// ----- MAIN CAPTURE LOOP -----------------------------------------------------

while keypressed do readkey;
while(nFrames < nFrameMax) and (not keypressed) do
  begin
  if camerabufferfilled then
    begin
    nFrames+=1;

//    scale4c(y2,cardinal(miniwindow.canvas),cyres div 4,cxres) ;
//    if (nframes mod 2) =0 then scale4c(y2,cardinal(@testbuf1),cyres div 4,cxres)
//    else scale4c(y2,cardinal(@testbuf2),cyres div 4,cxres) ;
   // if (nframes mod 2) =0 then fastmove(y2,cardinal(@testbuf1),cyres*cxres)
   // else
    soap(y2,cardinal(@testbuf1),cyres*cxres) ;
    s1:=(nframes mod 2) +1;
    t3:=gettime;
    soap(y2,cardinal(rendertestwindow.canvas),cxres*cyres);
    t3:=gettime-t3;
    t2:=gettime;
     OMX_FillThisBuffer(mContext.pCamera, mContext.pBufferCameraOut);
    t2:=gettime-t2;


    t1:=gettime-t1; if nframes>1 then begin at+=t1; rendertestwindow.outtextxyz(4,44,inttostr(at div (nframes-1)),255,2,2); end; t1:=gettime;
    if nframes>1 then begin at2+=t2; rendertestwindow.outtextxyz(4,84,inttostr(at2 div (nframes-1)),255,2,2); end;
    if nframes>1 then begin at3+=t3; rendertestwindow.outtextxyz(4,124,inttostr(at3 div (nframes-1)),255,2,2); end;
    rendertestwindow.outtextxyz(4,4,inttostr(nframes),255,2,2);
    camerabufferfilled:=false;
    end;
  threadsleep(1);
  end;

while keypressed do readkey;
//PAThread.terminate;
//PAThread.destroy;
//threadsleep(10);

// ----- MAIN CAPTURE LOOP END -------------------------------------------------

portCapturing.bEnabled := OMX_FALSE;
OMX_SetConfig(mContext.pCamera, OMX_IndexConfigPortCapturing, @portCapturing);
print_log('Capture stop.');

p999:

// ----------    Cleanup

camerawindow.println('Terminating...');
if(isState(mContext.pCamera, OMX_StateExecuting))=OMX_TRUE then
  OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateIdle, nil);
wait_for_state_change(OMX_StateIdle, mContext.pCamera);

// Idle -> Loaded

if(isState(mContext.pCamera, OMX_StateIdle)) =OMX_TRUE then
  OMX_SendCommand(mContext.pCamera, OMX_CommandStateSet, OMX_StateLoaded, nil);
threadsleep(20); // wait for state change to loaded doesn't work ?

// Loaded -> Free

if(isState(mContext.pCamera, OMX_StateLoaded))=OMX_TRUE then OMX_FreeHandle(mContext.pCamera);
OMX_Deinit();
print_log('Terminated. You can now close the window');
end;




end.

