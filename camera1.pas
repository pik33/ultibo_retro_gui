unit Camera1;

interface

{$mode delphi}{$H+}
//{$define use_tftp}    // if PI not connected to LAN and set for DHCP then remove this

uses
  classes,sysutils,uIL_Client, uOMX, VC4, threads,
  retromalina, mwindows;



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

procedure camera;
var camerathread:TCameraThread;
    cmw:pointer=nil;
    camerawindow:TWindow=nil;

    bc: PILCLIENT_BUFFER_CALLBACK_T;

implementation

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
  if camerawindow=nil then
    begin
    camerawindow:=TWindow.create(480,320,'Camera log');
    camerawindow.decoration.hscroll:=false;
    camerawindow.decoration.vscroll:=false;
    camerawindow.resizable:=false;
    camerawindow.cls(147);
    camerawindow.tc:=154;
    camerawindow.move(50,500,480,320,0,0);
    cmw:=camerawindow;
    end
  else goto p999;
  camera;
//  repeat sleep(100) until camerawindow.needclose;
  camerawindow.destroy;
  camerawindow:=nil;
  cmw:=nil;
  p999:
end;



procedure camera;
var
  cstate : OMX_TIME_CONFIG_CLOCKSTATETYPE;
  cameraport : OMX_CONFIG_PORTBOOLEANTYPE;
  displayconfig : OMX_CONFIG_DISPLAYREGIONTYPE;
  camera, video_render, clock : PCOMPONENT_T;
  list : array [0..3] of PCOMPONENT_T;
  tunnel : array [0..3] of TUNNEL_T;
  client : PILCLIENT_T;
  q,height, w, h, x, y, layer : integer;
   camerastructure:OMX_PARAM_PORTDEFINITIONTYPE;

begin
  bc:=@bc1;
  BCMHostInit;
  height := 600;
  w := (4 * height) div 3;
  h := height;
  x := (xres-w) div 2;
  y := (yres-h) div 2;
  layer := 0;
  list[0] := nil;   // suppress hint
  FillChar (list, SizeOf (list), 0);
  tunnel[0].sink_port := 0;   // suppress hint
  FillChar (tunnel, SizeOf (tunnel), 0);
  client := ilclient_init;
  if client <> nil then
    camerawindow.println ('IL Client initialised OK.')
  else
    begin
      camerawindow.println ('IL Client failed to initialise.');
      exit;
    end;
  if OMX_Init = OMX_ErrorNone then
    camerawindow.println ('OMX Initialised OK.')
  else
    begin
      camerawindow.println ('OMX failed to Initialise.');
      exit;
    end;
  // create camera
  if (ilclient_create_component (client, @camera, 'camera', ILCLIENT_DISABLE_ALL_PORTS or ILCLIENT_ENABLE_OUTPUT_BUFFERS) = 0) then
   camerawindow.println ('camera created ok')
  else
   exit;
  list[0] := camera;
  // create video_render
  if (ilclient_create_component(client, @video_render, 'video_render', ILCLIENT_DISABLE_ALL_PORTS) = 0) then
    camerawindow.println ('Video Render created ok')
  else
    exit;
  list[1] := video_render;
  // create clock
  if (ilclient_create_component(client, @clock, 'clock', ILCLIENT_DISABLE_ALL_PORTS) = 0) then
    camerawindow.println ('Clock created ok.')
  else
    exit;
  list[2] := clock;
   // enable the capture port of the camera
  cameraport.nSize := 0;  // suppress hint
  FillChar (cameraport, sizeof (cameraport), 0);
    FillChar (camerastructure, sizeof (camerastructure), 0);
  cameraport.nSize := sizeof (cameraport);
  cameraport.nVersion.nVersion := OMX_VERSION;
  cameraport.nPortIndex := kCameraCapturePort;
  cameraport.bEnabled := OMX_TRUE;
  if (OMX_SetParameter (ilclient_get_handle (camera), OMX_IndexConfigPortCapturing, @cameraport) = OMX_ErrorNone) then
    camerawindow.println ('Capture port set ok.')
  else
    exit;
  // configure the renderer to display the content in a 4:3 rectangle in the middle of a 1280x720 screen
  displayconfig.nSize := 0; // suppress hint
  FillChar (displayconfig, SizeOf (displayconfig), 0);
  displayconfig.nSize := SizeOf (displayconfig);
  displayconfig.nVersion.nVersion := OMX_VERSION;
  displayconfig.set_ := OMX_DISPLAY_SET_FULLSCREEN or OMX_DISPLAY_SET_DEST_RECT or OMX_DISPLAY_SET_LAYER;
  displayconfig.nPortIndex := kRendererInputPort;

  if (w > 0) and (h > 0) then
    displayconfig.fullscreen := OMX_FALSE
  else
    displayconfig.fullscreen := OMX_TRUE;
  displayconfig.dest_rect.x_offset := x;
  displayconfig.dest_rect.y_offset := y;
  displayconfig.dest_rect.width := w;
  displayconfig.dest_rect.height := h;
  displayconfig.layer := layer;
  camerawindow.print('dest rect: '); camerawindow.print(inttostr(x)+', ' );  camerawindow.print(inttostr(y)+', ') ;  camerawindow.print(inttostr(w)+', ') ;  camerawindow.println(inttostr(h)+', ' );
  camerawindow.println ('layer: '+inttostr(displayconfig.layer));
  if (OMX_SetParameter (ilclient_get_handle (video_render), OMX_IndexConfigDisplayRegion, @displayconfig) = OMX_ErrorNone) then
     camerawindow.println ('Render Region set ok.')
  else
    exit;
  // create a tunnel from the camera to the video_render component
  set_tunnel (@tunnel[0], camera, kCameraCapturePort, video_render, kRendererInputPort);
  // create a tunnel from the clock to the camera
  set_tunnel (@tunnel[1], clock, kClockOutputPort0, camera, kCameraClockPort);
  // setup both tunnels
//  if ilclient_setup_tunnel (@tunnel[0], 0, 0) = 0 then
//    camerawindow.println ('First tunnel created ok.')
  //else
  //  exit;
  if ilclient_setup_tunnel (@tunnel[1], 0, 0) = 0 then
    camerawindow.println ('Second tunnel created ok.')
  else
    exit;
       ///  try to enable a buffer
     q:=ilclient_enable_port_buffers (camera,71,nil,nil,nil);
   camerawindow.println ('buffer created result '+inttostr(q));


  OMX_GetParameter(ilclient_get_handle(camera), OMX_IndexParamPortDefinition, @camerastructure) ;
   camerawindow.println ( 'Size of predefined buffer :'+inttostr(camerastructure.nBufferSize)+' '+inttostr(camerastructure.nBufferCountActual));





  ///  try to set callbacks

    ilclient_set_fill_buffer_done_callback(client,bc,nil);
       camerawindow.println('trying to set a callback ');



  // change state of components to executing
  ilclient_change_component_state (camera, OMX_StateExecuting);
  ilclient_change_component_state (video_render, OMX_StateExecuting);
  ilclient_change_component_state (clock, OMX_StateExecuting);
  // start the camera by changing the clock state to running
  cstate.nSize := 0;  // suppress hint
  FillChar (cstate, SizeOf (cstate), 0);
  cstate.nSize := sizeOf (displayconfig);
  cstate.nVersion.nVersion := OMX_VERSION;
  cstate.eState := OMX_TIME_ClockStateRunning;
  OMX_SetParameter (ilclient_get_handle (clock), OMX_IndexConfigTimeClockState, @cstate);
  camerawindow.println ('Press any key to exit.');
  repeat threadsleep(100) until keypressed or camerawindow.needclose;
  while keypressed do readkey;
  ilclient_disable_tunnel (@tunnel[0]);
  ilclient_disable_tunnel (@tunnel[1]);
  ilclient_teardown_tunnels (@tunnel[0]);
  ilclient_state_transition (@list, OMX_StateIdle);
  ilclient_state_transition (@list, OMX_StateLoaded);
  ilclient_cleanup_components (@list);
  OMX_Deinit;
  ilclient_destroy (client);
  bcmhostdeinit;
end;

end.

