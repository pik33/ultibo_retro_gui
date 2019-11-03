unit shadertest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GLES20, DispmanX, VC4, Math, retromalina, mwindows, threads,retro,platform,playerunit,blitter,simplegl;



procedure shadertest_start;
procedure runshaderthread;

type TShaderThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


var programID,vertexID,colorID,texcoordID,normalID:GLuint;
    positionLoc:GLuint;
    frames:integer;

     //DispmanX window
    DispmanDisplay:DISPMANX_DISPLAY_HANDLE_T;
    DispmanElement:DISPMANX_ELEMENT_HANDLE_T;
    DispmanUpdate:DISPMANX_UPDATE_HANDLE_T;
     //EGL data
    Display:EGLDisplay;
    Surface:EGLSurface;
    Context:EGLContext;
     //EGL config
    Alpha:VC_DISPMANX_ALPHA_T;
    NativeWindow:EGL_DISPMANX_WINDOW_T;
    ConfigAttributes:array[0..14] of EGLint;
    ContextAttributes:array[0..2] of EGLint;
    glwindow:TWindow;
    texture0:gluint;
 //   u_vp_matrix:GLint;
    u_texture:GLint;
    a_texcoord:GLint;

    texaddr:cardinal;
    testbitmap:TTexturebitmap;

    shaderthread:TShaderThread=nil;

    basetime:int64;
    u_itime:glint;

//--------------------- Shaders ------------------------------------------------

const VertexSource:String =
 'precision highp float;' +
 'attribute vec4 a_position;' +
 'attribute vec2 a_texcoord;' +
 'attribute vec4 a_normal;' +
 'varying highp vec2 v_texcoord;'+
 'void main()' +
 '{' +
//   ' vec2 scale=vec2(1920./2048.,1200./1024.); '+
 '    gl_Position = a_position; ' +
 '    v_texcoord = a_texcoord;  '+
 '}';

FragmentSource:String =
 'precision highp float;' +
 'varying highp vec2 v_texcoord;'+
 'uniform highp sampler2D u_texture;'+
 'void main()' +
 '{' +
 'vec4 p0 = texture2D(u_texture, v_texcoord); '+
 'gl_FragColor = p0; '  +
  '}';

 {

const VertexSource:String =

 'attribute vec4 a_position; ' +
 'attribute vec2 a_texcoord; ' +
 'varying vec2 v_texcoord; '+
 'void main() ' +
 '{' +
 '    gl_Position = a_position; ' +
 '    v_texcoord = a_texcoord;  '+
 '}';

FragmentSource:String =
 'varying vec2 v_texcoord; '+
 'uniform sampler2D u_texture; '+
 'uniform float iTime; '+
 'void main()' +
 '{' +
 '  vec2 iResolution=vec2(1920.,1200.); '+
 '  vec2 p=(3.0*gl_FragCoord.xy-iResolution.xy)/max(iResolution.x,iResolution.y);  '+
 '  float f = cos(iTime/30.);                                                      '+
 '  float s = sin(iTime/30.);                                                      '+
 '  p = vec2(p.x*f-p.y*s, p.x*s+p.y*f);                                            '+
 '  for(float i=3.0;i<30.;i++) '+
 '    {           '+
 '    vec2 p1= (i*p.yx+iTime*vec2(.30,.30)  + vec2(.30,3.0)); '+
 '    p1= cos(p1); '+
 '    p1= abs(p1); '+
 '    p1= sqrt(p1); '+
 '    p+= .30/i * p1; '+
 '    }                                                                           '+
 '  vec3 col=vec3(.30*sin(3.0*p.x)+.30,.30*sin(3.0*p.y)+.30,sin(3.0*p.x+3.0*p.y)); '+
 '  gl_FragColor=(3.0/(3.0-(3.0/3.0)))*vec4(col, 3.0);                               '+
 '} ';

 }
// -----------------  test square ------------------------------------------------

var vertices:array[0..17] of GLfloat = (               // 6*3-1
-1.0, 1.0, 0.0,-1.0,-1.0, 0.0, 1.0, 1.0, 0.0,          // Front
 1.0, 1.0, 0.0,-1.0,-1.0, 0.0, 1.0,-1.0, 0.0
);

uvs:array[0..11] of GLfloat=(
  0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1
 );

//---------------- end of the cube definition

implementation



constructor TShaderThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TShaderThread.execute;

label p999;
  var q:cardinal;

begin
ThreadSetPriority(ThreadGetCurrent,6);
ThreadSetAffinity(ThreadGetCurrent,4);
threadsleep(10);
if glwindow=nil then
  begin
  glwindow:=TWindow.create(1280,960 ,'GLtexturetest');
  glwindow.move(200,200,800,600,0,0);
  glwindow.cls($23);
  glwindow.outtextxyz(32,32,'Test tekstury',254,4,4);
  q:=$4655434b; lpoke(cardinal(glwindow.canvas),q);
  q:=$15161718; lpoke(cardinal(glwindow.canvas)+4,q);
  end
else goto p999;
shadertest_start;
//glwindow:=nil;
p999:
end;

procedure shader_init;

// Init EGL and attach a dispmanx layer

var Config:EGLConfig;
    ConfigCount:EGLint;

    DestRect:VC_RECT_T;
    SourceRect:VC_RECT_T;

begin

//Setup some DispmanX and EGL defaults

DispmanDisplay:=DISPMANX_NO_HANDLE;
DispmanElement:=DISPMANX_NO_HANDLE;
DispmanUpdate:=DISPMANX_NO_HANDLE;
Display:=EGL_NO_DISPLAY;
Surface:=EGL_NO_SURFACE;
Context:=EGL_NO_CONTEXT;

//Setup the alpha channel state

Alpha.flags:=DISPMANX_FLAGS_ALPHA_FROM_SOURCE;
Alpha.opacity:=255;
Alpha.mask:=255;

//Setup the EGL configuration attributes

ConfigAttributes[0]:=EGL_RENDERABLE_TYPE;
ConfigAttributes[1]:=EGL_OPENGL_ES2_BIT;
ConfigAttributes[2]:=EGL_SURFACE_TYPE;
ConfigAttributes[3]:=EGL_WINDOW_BIT;
ConfigAttributes[4]:=EGL_BLUE_SIZE;
ConfigAttributes[5]:=8;
ConfigAttributes[6]:=EGL_GREEN_SIZE;
ConfigAttributes[7]:=8;
ConfigAttributes[8]:=EGL_RED_SIZE;
ConfigAttributes[9]:=8;
ConfigAttributes[10]:=EGL_ALPHA_SIZE;
ConfigAttributes[11]:=8;
ConfigAttributes[12]:=EGL_DEPTH_SIZE;
ConfigAttributes[13]:=16;
ConfigAttributes[14]:=EGL_NONE;

//Setup the EGL context attributes

ContextAttributes[0]:=EGL_CONTEXT_CLIENT_VERSION;
ContextAttributes[1]:=2;
ContextAttributes[2]:=EGL_NONE;

// create a context

Display:=eglGetDisplay(EGL_DEFAULT_DISPLAY);
eglInitialize(Display,nil,nil);
eglChooseConfig(Display,@ConfigAttributes,@Config,1,@ConfigCount);
eglBindAPI(EGL_OPENGL_ES_API);
Context:=eglCreateContext(Display,Config,EGL_NO_CONTEXT,@ContextAttributes);

//Setup the DispmanX source and destination rectangles

vc_dispmanx_rect_set(@DestRect,0,0,1024, 512);
vc_dispmanx_rect_set(@SourceRect,0,0,(2048 shl 16),(1024 shl 16));  // shl 16 all params

//Open the DispmanX display

DispmanDisplay:=vc_dispmanx_display_open(DISPMANX_ID_MAIN_LCD);

//Start a DispmanX update

DispmanUpdate:=vc_dispmanx_update_start(0);
DispmanElement:=vc_dispmanx_element_add(DispmanUpdate,DispmanDisplay,0 {Layer},@DestRect,0 {Source},@SourceRect,DISPMANX_PROTECTION_NONE,@Alpha,nil {Clamp},DISPMANX_NO_ROTATE {Transform});

//Define an EGL DispmanX native window structure

NativeWindow.Element:=DispmanElement;
NativeWindow.Width:=2048;
NativeWindow.Height:=1024;

//Submit the DispmanX update

vc_dispmanx_update_submit_sync(DispmanUpdate);

//Create an EGL window surface
Surface:=eglCreateWindowSurface(Display,Config,@NativeWindow,nil);

//Connect the EGL context to the EGL surface

eglMakeCurrent(Display,Surface,Surface,Context);
end;


procedure shader_prepare;

var Source:PChar;
    VertexShader:GLuint;
    FragmentShader:GLuint;
    i:integer;
    t:int64;

begin

//initialize clear and depth values; enable cull_face

glClearDepthf(1.0);
glClearColor(0.0,0.0,0.0,0.0);
//glEnable(GL_CULL_FACE);
glEnable(GL_DEPTH_TEST);

//Create, upload and compile the vertex shader

VertexShader:=glCreateShader(GL_VERTEX_SHADER);  // todo: check if it is not 0?
Source:=PChar(VertexSource);
glShaderSource(VertexShader,1,@Source,nil);
glCompileShader(VertexShader);                   // todo: check a compilation status with glGetShaderiv

//Create, upload and compile the pixel shader

FragmentShader:=glCreateShader(GL_FRAGMENT_SHADER);
Source:=PChar(FragmentSource);
glShaderSource(FragmentShader,1,@Source,nil);
glCompileShader(FragmentShader);

//Create and link the program

programID:=glCreateProgram;                     // todo: check if it is not 0?
glAttachShader(programID,VertexShader);
glAttachShader(programID,FragmentShader);
glLinkProgram(programID);                       // todo: check a linkstatus with glGetprogramiv

//Discard the shaders as they are linked to the program

glDeleteShader(FragmentShader);
glDeleteShader(VertexShader);

//Obtain the locations of some uniforms and attributes from our shaders

positionLoc:=glGetAttribLocation(programID,'a_position');
glEnableVertexAttribArray(positionLoc);
u_texture:=glGetUniformLocation(programID,'u_texture');
a_texcoord:=glGetAttribLocation(programID,'a_texcoord');
u_itime:=glGetUniformLocation(programID,'iTime');

//Generate vertex and color buffers and fill them with our cube data

glGenBuffers(1,@vertexID);
glBindBuffer(GL_ARRAY_BUFFER,vertexID);
glVertexAttribPointer(positionLoc,3,GL_FLOAT,GL_FALSE,3 * SizeOf(GLfloat),nil); // location and data format of vertex attributes:index.size,type,normalized,stride,offset

glGenBuffers(1,@texcoordID);
glBindBuffer(GL_ARRAY_BUFFER,texcoordID);
glVertexAttribPointer(a_texcoord, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), nil);
glEnableVertexAttribArray(a_texcoord);
glBufferData(GL_ARRAY_BUFFER, sizeof(uvs), @uvs[0], GL_STATIC_DRAW);

glGenTextures(1, @texture0);
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture0);
glTexImage2D(GL_TEXTURE_2D, 0, gl_luminance, 2048, 1024, 0, gl_luminance, GL_UNSIGNED_BYTE,nil); // glwindow.canvas);

t:=gettime;
glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 1280 ,960 ,GL_luminance, GL_unsigned_BYTE, glwindow.canvas); // push the texture from window canvas to GPU area
t:=gettime-t;
retromalina.outtextxyz(0,1000,inttostr(t),252,3,3);
//Find the testure pointer
i:=$30000000; repeat i:=i+4 until ((lpeek(i)=$4655434b) and (lpeek(i+4)=$15161718) and (lpeek(i+128)=$23232323) and (lpeek(i+192)=$23232323)) or (i>$3F000000) ;
testbitmap.address:=i;testbitmap.w:=2048; testbitmap.l:=2048;
retromalina.outtextxyz(0,0,inttohex(i,8),44,3,3);
texaddr:=i;
//glwindow.destroy;

glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture0);
glUniform1i(u_texture,0);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_nearest);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_nearest);

glViewport(0,0,2048,1024);                              // full screen OpenGL view;

glUseProgram(programID);                                // attach a shader program
glUniform1i(u_texture,0);                               // tell the shader what is the texture numbers
basetime:=gettime;
end;


procedure shader_draw;

var tttt:int64;

begin
tttt:=gettime;
glUniform1f(u_itime,(tttt-basetime)/1000000);
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // clear the scene

//UVs for the texture
glBindBuffer(GL_ARRAY_BUFFER,texcoordID);
glBufferData(GL_ARRAY_BUFFER,sizeof(uvs), @uvs[0], GL_dynamic_DRAW);

//Vertices
glBindBuffer(GL_ARRAY_BUFFER,vertexID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(Vertices),@Vertices,GL_DYNAMIC_DRAW);

// Draw it
glDrawArrays(GL_TRIANGLES,0,6);
eglSwapBuffers(Display,Surface);
frames+=1;
end;

procedure shader_cleanup;

var DispmanUpdate:DISPMANX_UPDATE_HANDLE_T;

begin

// Delete the OpenGL ES buffers
glDeleteBuffers(1,@vertexID);
glDeleteBuffers(1,@colorID);

//Delete the OpenGL ES program
glDeleteProgram(programID);

//Destroy the EGL surface
eglDestroySurface(Display,Surface);
sleep(1000);

//Release OpenGL resources and terminate EGL
eglMakeCurrent(Display,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);
eglDestroyContext(Display,Context);
eglTerminate(Display);

//Remove the dispmanx layer

DispmanUpdate:=vc_dispmanx_update_start(0);
vc_dispmanx_element_remove(DispmanUpdate,DispmanElement);
vc_dispmanx_update_submit_sync(DispmanUpdate);

//Close the DispmanX display
vc_dispmanx_display_close(DispmanDisplay);
end;

procedure shadertest_start;

begin
BCMHostInit;
shader_init;
shader_prepare;
while keypressed do readkey;
repeat shader_draw until keypressed;
while keypressed do readkey;
shader_cleanup;
BCMHostDeinit;
end;

procedure runshaderthread;
begin
shaderthread:=Tshaderthread.create(true);
shaderthread.start;
end;

initialization

applet_register('ShaderTest',@runshaderthread);
end.

