unit gltest2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GLES20, DispmanX, VC4, Math, retromalina;

type Pmatrix4=^matrix4;
     matrix4=array[0..3,0..3] of glfloat;
type vector4=array[0..3] of glfloat;

const matrix4_zero:matrix4=((0,0,0,0),(0,0,0,0),(0,0,0,0),(0,0,0,0));
const matrix4_one:matrix4=((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));

operator +(a,b:matrix4):matrix4;
operator *(a,b:matrix4):matrix4;

//function rotate(a:matrix4; x,y,z,angle:glfloat):matrix4;

var programID,vertexID,colorID:GLuint;
    mvpLoc,positionLoc,colorLoc:GLuint;
    projectionMat,modelviewMat,mvpMat:matrix4;

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
    ConfigAttributes:array[0..10] of EGLint;
    ContextAttributes:array[0..2] of EGLint;


//--------------------- Shaders ------------------------------------------------

const VertexSource:String =
 'precision mediump float;' +
 'uniform mat4 u_mvpMat;' +
 'attribute vec4 a_position;' +
 'attribute vec4 a_color;' +
 'varying vec4 v_color;' +
 'void main()' +
 '{' +
 '    gl_Position = u_mvpMat * a_position;' +
 '    v_color = a_color;' +
 '}';

FragmentSource:String =
 'varying lowp vec4 v_color;' +
 'void main()' +
 '{' +
 '    gl_FragColor = v_color;' +
 '}';


// -----------------  test cube ------------------------------------------------

const Vertices:array[0..(6 * 6 * 3) - 1] of GLfloat = (

// Front
 -0.5,  0.5,  0.5,
 -0.5, -0.5,  0.5,
  0.5,  0.5,  0.5,
  0.5,  0.5,  0.5,
 -0.5, -0.5,  0.5,
  0.5, -0.5,  0.5,
//Right
  0.5,  0.5,  0.5,
  0.5, -0.5,  0.5,
  0.5,  0.5, -0.5,
  0.5,  0.5, -0.5,
  0.5, -0.5,  0.5,
  0.5, -0.5, -0.5,
//Back
  0.5,  0.5, -0.5,
  0.5, -0.5, -0.5,
 -0.5,  0.5, -0.5,
 -0.5,  0.5, -0.5,
  0.5, -0.5, -0.5,
 -0.5, -0.5, -0.5,
//Left
 -0.5,  0.5, -0.5,
 -0.5, -0.5, -0.5,
 -0.5,  0.5,  0.5,
 -0.5,  0.5,  0.5,
 -0.5, -0.5, -0.5,
 -0.5, -0.5,  0.5,
//Top
 -0.5,  0.5, -0.5,
 -0.5,  0.5,  0.5,
  0.5,  0.5, -0.5,
  0.5,  0.5, -0.5,
 -0.5,  0.5,  0.5,
  0.5,  0.5,  0.5,
//Bottom
 -0.5, -0.5,  0.5,
 -0.5, -0.5, -0.5,
  0.5, -0.5,  0.5,
  0.5, -0.5,  0.5,
 -0.5, -0.5, -0.5,
  0.5, -0.5, -0.5
);

Colors:array[0..(6 * 6 * 4) - 1] of GLfloat = (

//Front}
 1.0,0.521,0.0,1.0,
 1.0,0.521,0.0,1.0,
 1.0,0.521,0.0,1.0,
 1.0,0.521,0.0,1.0,
 1.0,0.521,0.0,1.0,
 1.0,0.521,0.0,1.0,
//Right
 1.0,0.0,0.0,1.0,
 1.0,0.0,0.0,1.0,
 1.0,0.0,0.0,1.0,
 1.0,0.0,0.0,1.0,
 1.0,0.0,0.0,1.0,
 1.0,0.0,0.0,1.0,
//Back
 1.0,1.0,1.0,1.0,
 1.0,1.0,1.0,1.0,
 1.0,1.0,1.0,1.0,
 1.0,1.0,1.0,1.0,
 1.0,1.0,1.0,1.0,
 1.0,1.0,1.0,1.0,
//Left
 1.0,1.0,0.0,1.0,
 1.0,1.0,0.0,1.0,
 1.0,1.0,0.0,1.0,
 1.0,1.0,0.0,1.0,
 1.0,1.0,0.0,1.0,
 1.0,1.0,0.0,1.0,
//Top
 0.0,0.7333,0.0,1.0,
 0.0,0.7333,0.0,1.0,
 0.0,0.7333,0.0,1.0,
 0.0,0.7333,0.0,1.0,
 0.0,0.7333,0.0,1.0,
 0.0,0.7333,0.0,1.0,
//Bottom
 0.752,0.752,0.752,1.0,
 0.752,0.752,0.752,1.0,
 0.752,0.752,0.752,1.0,
 0.752,0.752,0.752,1.0,
 0.752,0.752,0.752,1.0,
 0.752,0.752,0.752,1.0
);


implementation

//--------------------- Operators overloading ----------------------------------

operator +(a,b:matrix4):matrix4;

var i,j:integer;

begin
for i:=0 to 3 do
  for j:=0 to 3 do
    result[i,j]:=a[i,j]+b[i,j];
end;

operator *(a,b:matrix4):matrix4;

var i,j:integer;

begin
for i:=0 to 3 do
  for j:=0 to 3 do
    result[i,j]:=a[0,j]*b[i,0]+a[1,j]*b[i,1]+a[2,j]*b[i,2]+a[3,j]*b[i,3];
end;

//------------------------------------------------------------------------------
//---------------------- Helper functions --------------------------------------
//------------------------------------------------------------------------------

//------------------------ rotate ----------------------------------------------

function rotate(var a:matrix4; x,y,z,angle:glfloat):matrix4;

var
 sinAngle,cosAngle,mag:GLfloat;
 xx,yy,zz,xy,yz,zx,xs,ys,zs:GLfloat;
 oneminuscos:GLfloat;
 rotation:matrix4;

begin
mag:=sqrt(x*x+y*y+z*z);
sinangle:=sin(angle*pi/180.0);
cosangle:=cos(angle*pi/180.0);
if mag > 0.0 then
  begin
  x:=x/mag;
  y:=y/mag;
  z:=z/mag;
  xx:=x*x;
  yy:=y*y;
  zz:=z*z;
  xy:=x*y;
  yz:=y*z;
  zx:=z*x;
  xs:=x*sinAngle;
  ys:=y*sinAngle;
  zs:=z*sinAngle;

// compute a rotation matrix

  oneminuscos:=1.0 - cosAngle;

  Rotation[0][0]:=(oneMinusCos*xx)+cosAngle;
  Rotation[0][1]:=(oneMinusCos*xy)-zs;
  Rotation[0][2]:=(oneMinusCos*zx)+ys;
  Rotation[0][3]:=0.0;

  Rotation[1][0]:=(oneMinusCos * xy) + zs;
  Rotation[1][1]:=(oneMinusCos * yy) + cosAngle;
  Rotation[1][2]:=(oneMinusCos * yz) - xs;
  Rotation[1][3]:=0.0;

  Rotation[2][0]:=(oneMinusCos * zx) - ys;
  Rotation[2][1]:=(oneMinusCos * yz) + xs;
  Rotation[2][2]:=(oneMinusCos * zz) + cosAngle;
  Rotation[2][3]:=0.0;

  Rotation[3][0]:=0.0;
  Rotation[3][1]:=0.0;
  Rotation[3][2]:=0.0;
  Rotation[3][3]:=1.0;

  result:=rotation*a;
  end
else result:=matrix4_zero;
end;

//------------------------ scale -----------------------------------------------

function scale(var a:matrix4;sx,sy,sz:glfloat):matrix4;

var s:matrix4;
begin
 s:=matrix4_zero;
 s[0,0]:=sx; s[1,1]:=sy; s[2,2]:=sz; s[3,3]:=1;
 result:=s*a;
end;

//------------------------ projection ------------------------------------------

function projection(var a:matrix4;l,r,b,t,n,f:glfloat):matrix4;

label p999;

var dx,dy,dz:glfloat;
    frust:matrix4;


begin
dx:=r-l;
dy:=t-b;
dz:=f-n;

if (n<=0.0) or (f<=0.0) or (dx<=0.0) or (dy<=0.0) or (dz<=0.0) then

  begin
  result:=a;
  goto p999; // do nothing
  end;

frust[0][0]:=2.0*n/dx;
frust[0][1]:=0.0;
frust[0][2]:=0.0;
frust[0][3]:=0.0;

frust[1][0]:=0.0;
frust[1][1]:=2.0*n/dy;
frust[1][2]:=0.0;
frust[1][3]:=0.0;

frust[2][0]:=(r+l)/dx;
frust[2][1]:=(t+b)/dy;
frust[2][2]:=-(n+f)/dz;
frust[2][3]:=-1.0;

frust[3][0]:=0.0;
frust[3][1]:=0.0;
frust[3][2]:=-2.0*f*n/dz;
frust[3][3]:=0.0;

result:=frust*a;
p999:
end;

//------------------------------------------------------------------------------

procedure gl_init;

// Init EGL and attach a dispmanx layer

var Config:EGLConfig;
    ConfigCount:EGLint;
    EGLResult:EGLBoolean;

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

Alpha.flags:=DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS;
Alpha.opacity:=128;
Alpha.mask:=0;

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
ConfigAttributes[10]:=EGL_NONE;

//Setup the EGL context attributes

ContextAttributes[0]:=EGL_CONTEXT_CLIENT_VERSION;
ContextAttributes[1]:=2;
ContextAttributes[2]:=EGL_NONE;

// create a context

Display:=eglGetDisplay(EGL_DEFAULT_DISPLAY);
EGLResult:=eglInitialize(Display,nil,nil);
EGLResult:=eglChooseConfig(Display,@ConfigAttributes,@Config,1,@ConfigCount);
EGLResult:=eglBindAPI(EGL_OPENGL_ES_API);
Context:=eglCreateContext(Display,Config,EGL_NO_CONTEXT,@ContextAttributes);

//Setup the DispmanX source and destination rectangles

vc_dispmanx_rect_set(@DestRect,0,0,xres,yres);
vc_dispmanx_rect_set(@SourceRect,0,0,xres shl 16,yres shl 16);  // shl 16 all params

//Open the DispmanX display

DispmanDisplay:=vc_dispmanx_display_open(DISPMANX_ID_MAIN_LCD);

//Start a DispmanX update

DispmanUpdate:=vc_dispmanx_update_start(0);
DispmanElement:=vc_dispmanx_element_add(DispmanUpdate,DispmanDisplay,0 {Layer},@DestRect,0 {Source},@SourceRect,DISPMANX_PROTECTION_NONE,@Alpha,nil {Clamp},DISPMANX_NO_ROTATE {Transform});

//Define an EGL DispmanX native window structure

NativeWindow.Element:=DispmanElement;
NativeWindow.Width:=xres;
NativeWindow.Height:=yres;

//Submit the DispmanX update

vc_dispmanx_update_submit_sync(DispmanUpdate);

//Create an EGL window surface
Surface:=eglCreateWindowSurface(Display,Config,@NativeWindow,nil);

//Connect the EGL context to the EGL surface

EGLResult:=eglMakeCurrent(Display,Surface,Surface,Context);

end;


procedure gl_prepare;

var aspect,n,f,w,h:GLfloat;
    Source:PChar;
    VertexShader:GLuint;
    FragmentShader:GLuint;

begin

//initialize clear and depth values; enable cull_face

glClearDepthf(1.0);
glClearColor(0.0,0.0,0.0,1.0);
glEnable(GL_CULL_FACE);

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
glLinkProgram(programID);                 // todo: check a linkstatus with glGetprogramiv

//Discard the shaders as they are linked to the program

glDeleteShader(FragmentShader);
glDeleteShader(VertexShader);

//Obtain the locations of some uniforms and attributes from our shaders

mvpLoc:=glGetUniformLocation(programID,'u_mvpMat');
positionLoc:=glGetAttribLocation(programID,'a_position');
colorLoc:=glGetAttribLocation(programID,'a_color');

//Generate vertex and color buffers and fill them with our cube data

glGenBuffers(1,@vertexID);
glBindBuffer(GL_ARRAY_BUFFER,vertexID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(Vertices),@Vertices,GL_STATIC_DRAW);

glGenBuffers(1,@colorID);
glBindBuffer(GL_ARRAY_BUFFER,colorID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(Colors),@Colors,GL_STATIC_DRAW);

// Calculate the frustum and scale the projection}

aspect:=xres/yres;
n:=1.0;
f:=8.0;
h:=1;
w:=h*aspect;

// initialize the projection matrix

projectionMat:=projection(matrix4_one,-w,w,-h,h,n,f);

if w>h then projectionMat:=scale(projectionMat,h/w,1,1) else projectionMat:=scale(projectionMat,1,w/h,1);

// initialize the other matrices

modelviewMat:=matrix4_one;
mvpMat:=matrix4_one;
end;


procedure gl_draw;

const frames:integer=0;

var modelviewmat2:matrix4;

begin
glViewport(0,0,xres,yres);                              // full screen OpenGL view;
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // clear the scene
glUseProgram(programID);                                // attach a shader program

glEnableVertexAttribArray(positionLoc);                 // positionloc is a pointer to a_position obtained by glGetAttribLocation while initializing the scene
glBindBuffer(GL_ARRAY_BUFFER,vertexID);                 // vertexID is a buffer generated and filled at init by vertices
glVertexAttribPointer(positionLoc,3,GL_FLOAT,GL_FALSE,3 * SizeOf(GLfloat),nil); // location and data format of vertex attributes:index.size,type,normalized,stride,offset

glEnableVertexAttribArray(colorLoc);                    // the same for color buffer
glBindBuffer(GL_ARRAY_BUFFER,colorID);
glVertexAttribPointer(colorLoc,4,GL_FLOAT,GL_FALSE,4 * SizeOf(GLfloat),nil);

//Rotate the model

modelviewmat2:=rotate(modelviewMat,1.0,-0.374,-0.608,0.923);

// compute mvp

mvpmat:=modelviewmat*projectionmat;
glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);

//Draw all of our triangles at once}
glDrawArrays(GL_TRIANGLES,0,36);

//Disable the attribute arrays}
glDisableVertexAttribArray(positionLoc);
glDisableVertexAttribArray(colorLoc);

   {Swap the buffers to display the new scene}

eglSwapBuffers(Display,Surface);

frames+=1;

end;





end.

