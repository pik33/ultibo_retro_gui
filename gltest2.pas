unit gltest2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GLES20, DispmanX, VC4, Math, retromalina, mwindows, threads,retro;

type Pmatrix4=^matrix4;
     matrix4=array[0..3,0..3] of glfloat;
type vector4=array[0..3] of glfloat;

const matrix4_zero:matrix4=((0,0,0,0),(0,0,0,0),(0,0,0,0),(0,0,0,0));
const matrix4_one:matrix4=((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));

operator +(a,b:matrix4):matrix4;
operator *(a,b:matrix4):matrix4;

procedure gltest2_start;

type TOpenGLThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

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
    ConfigAttributes:array[0..14] of EGLint;
    ContextAttributes:array[0..2] of EGLint;
    glwindow:TWindow;

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
 -1.0,  1.0,  1.0,
 -1.0, -1.0,  1.0,
  1.0,  1.0,  1.0,
  1.0,  1.0,  1.0,
 -1.0, -1.0,  1.0,
  1.0, -1.0,  1.0,
//Right
  1.0,  1.0,  1.0,
  1.0, -1.0,  1.0,
  1.0,  1.0, -1.0,
  1.0,  1.0, -1.0,
  1.0, -1.0,  1.0,
  1.0, -1.0, -1.0,
//Back
  1.0,  1.0, -1.0,
  1.0, -1.0, -1.0,
 -1.0,  1.0, -1.0,
 -1.0,  1.0, -1.0,
  1.0, -1.0, -1.0,
 -1.0, -1.0, -1.0,
//Left
 -1.0,  1.0, -1.0,
 -1.0, -1.0, -1.0,
 -1.0,  1.0,  1.0,
 -1.0,  1.0,  1.0,
 -1.0, -1.0, -1.0,
 -1.0, -1.0,  1.0,
//Top
 -1.0,  1.0, -1.0,
 -1.0,  1.0,  1.0,
  1.0,  1.0, -1.0,
  1.0,  1.0, -1.0,
 -1.0,  1.0,  1.0,
  1.0,  1.0,  1.0,
//Bottom
 -1.0, -1.0,  1.0,
 -1.0, -1.0, -1.0,
  1.0, -1.0,  1.0,
  1.0, -1.0,  1.0,
 -1.0, -1.0, -1.0,
  1.0, -1.0, -1.0
);

Colors:array[0..(6 * 6 * 4) - 1] of GLfloat = (

//Front}
 0.0,0.0,1.0,1.0,
 0.0,0.0,1.0,1.0,
 0.0,0.0,1.0,1.0,
 0.0,0.0,1.0,1.0,
 0.0,0.0,1.0,1.0,
 0.0,0.0,1.0,1.0,
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

// ---------- test tetrahedron -------------------------------------------------

const Vertices2:array[0..35] of GLfloat = (

// 1
 -1.0, -1.0,  1.0,
  -1.0,  1.0, -1.0,
  1.0,  1.0,  1.0,



  // 2
 -1.0,  1.0, -1.0,

 -1.0, -1.0,  1.0,
   1.0, -1.0, -1.0,

 //3
 -1.0, -1.0,  1.0,
   1.0,  1.0,  1.0,
  1.0, -1.0, -1.0,


//4
  1.0,  1.0,  1.0,
 -1.0,  1.0, -1.0,
  1.0, -1.0, -1.0

);

colors2:array[0..47] of GLfloat = (

//1
1.0,0.0,0.0,1.0,
0.0,1.0,0.0,1.0,
0.0,0.0,1.0,1.0,

//2
1.0,1.0,0.5,1.0,
0.0,1.0,1.0,1.0,
1.0,0.0,1.0,1.0,

//3
1.0,0.5,0.0,1.0,
0.0,1.0,0.5,1.0,
0.5,0.0,1.0,1.0,

//4
1.0,1.0,1.0,1.0,
0.6,0.6,0.6,1.0,
0.2,0.2,0.2,1.0

);


implementation


constructor TOpenGLThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TOpenGLThread.execute;

label p999;

begin
ThreadSetPriority(ThreadGetCurrent,7);
threadsleep(1);
if glwindow=nil then
  begin
  glwindow:=TWindow.create(256,256,'OpenGL helper window');
  glwindow.decoration.hscroll:=false;
  glwindow.decoration.vscroll:=false;
  glwindow.resizable:=false;
  glwindow.cls(0);
  glwindow.move(300,400,256,256,0,0);
  end
else goto p999;
gltest2_start;
glwindow.destroy;
glwindow:=nil;
p999:
end;

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

function rotate(a:matrix4; x,y,z,angle:glfloat):matrix4;

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

//----------------------translate ----------------------------------------------

function translate(var a:matrix4;sx,sy,sz:glfloat):matrix4;

var s:matrix4;
begin
 s:=matrix4_one;
 s[3,0]:=sx; s[3,1]:=sy; s[3,2]:=sz;
 result:=s*a;
end;

//---------------- frustum projection ------------------------------------------

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

frust:=matrix4_zero;

frust[0,0]:=2.0*n/dx;
frust[1,1]:=2.0*n/dy;
frust[2,0]:=(r+l)/dx;
frust[2,1]:=(t+b)/dy;
frust[2,2]:=-(n+f)/dz;
frust[2,3]:=-1.0;
frust[3,2]:=-2.0*f*n/dz;

result:=frust*a;
p999:
end;

//---------------- orthogonal projection ---------------------------------------
// simplified for symmetric top,bottom,left,right

function ortho(var a:matrix4;l,r,b,t,n,f:glfloat):matrix4;

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

frust:=matrix4_zero;

frust[0,0]:=1/r;
frust[1,1]:=1/t;
frust[2,2]:=-2/dz;
frust[3,3]:=1.0;
frust[3,2]:=-(f+n)/dz;

result:=frust*a;
p999:
end;

//------------------------------------------------------------------------------

procedure gl_init;

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

eglMakeCurrent(Display,Surface,Surface,Context);

end;


procedure gl_prepare;

var aspect,n,f,w,h,fov:GLfloat;
    Source:PChar;
    VertexShader:GLuint;
    FragmentShader:GLuint;

begin

//initialize clear and depth values; enable cull_face

glClearDepthf(1.0);
glClearColor(0.0,0.0,0.0,0.0);
glEnable(GL_CULL_FACE);
glEnable(GL_DEPTH_TEST);
//gldepthfunc(GL_LEQUAL);
//gldepthmask(1);

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
glEnableVertexAttribArray(positionLoc);
glEnableVertexAttribArray(colorLoc);

//Generate vertex and color buffers and fill them with our cube data

glGenBuffers(1,@vertexID);
//glBindBuffer(GL_ARRAY_BUFFER,vertexID);
//glBufferData(GL_ARRAY_BUFFER,SizeOf(Vertices),@Vertices,GL_STATIC_DRAW);

glGenBuffers(1,@colorID);
//glBindBuffer(GL_ARRAY_BUFFER,colorID);
//glBufferData(GL_ARRAY_BUFFER,SizeOf(Colors),@Colors,GL_STATIC_DRAW);

// Calculate the frustum and scale the projection}

aspect:=xres/yres;
n:=1.0;
f:=8.0;
fov:=30.0;
h:=tan(2*pi*fov/360)*n;
w:=h*aspect;

// initialize the projection matrix

projectionMat:=projection(matrix4_one,-w,w,-h,h,n,f);
//projectionMat:=ortho(matrix4_one,-w,w,-h,h,n,f);

// initialize the other matrices

modelviewMat:=matrix4_one;
mvpMat:=matrix4_one;
end;


procedure gl_draw;

const frames:integer=0;
      angle1:glfloat=0;
      angle2:glfloat=0;
      angle3:glfloat=0;
      angle4:glfloat=0;
      k:integer=0;
var   i,j:integer;
      r,g,b:glfloat;



var modelviewmat2,translatemat:matrix4;


begin

k+=1;
for i:=0 to 11 do
  begin
  j:=(85*i+(k div 3)) mod 256;
  r:=ataripallette[j] and $FF;
  g:=(ataripallette[j] and $FF00) shr 8;
  b:=(ataripallette[j] and $FF0000) shr 16;
  colors2[4*i]:=r/256;
  colors2[4*i+1]:=g/256;
  colors2[4*i]:=b/256;
  end;

glViewport(0,0,xres,yres);                              // full screen OpenGL view;
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // clear the scene
glUseProgram(programID);                                // attach a shader program

//glEnableVertexAttribArray(positionLoc);                 // positionloc is a pointer to a_position obtained by glGetAttribLocation while initializing the scene
glBindBuffer(GL_ARRAY_BUFFER,vertexID);                 // vertexID is a buffer generated and filled at init by vertices
glBufferData(GL_ARRAY_BUFFER,SizeOf(Vertices),@Vertices,GL_DYNAMIC_DRAW);
glVertexAttribPointer(positionLoc,3,GL_FLOAT,GL_FALSE,3 * SizeOf(GLfloat),nil); // location and data format of vertex attributes:index.size,type,normalized,stride,offset

//glEnableVertexAttribArray(colorLoc);                    // the same for color buffer
glBindBuffer(GL_ARRAY_BUFFER,colorID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(Colors),@Colors,GL_DYNAMIC_DRAW);
glVertexAttribPointer(colorLoc,4,GL_FLOAT,GL_FALSE,4 * SizeOf(GLfloat),nil);

// reduce the model size

modelviewmat2:=scale(modelviewmat,0.5,0.5,0.5);

//Rotate the model around the skewed axis

angle1+=1.11;
if angle1>360 then angle1-=360;
modelviewmat2:=rotate(modelviewmat2,1.0,-0.374,-0.608,angle1);

// now translate the model one unit away

modelviewmat2:=translate(modelviewmat2,0,0,-2);

// and rotate it again around Y axis

angle2+=0.82;
if angle2>360 then angle2-=360;

modelviewmat2:=rotate(modelviewmat2,0,1,-0,angle2);

// then translate the model 4 units away

modelviewmat2:=translate(modelviewmat2,0,0,-5); // negative are far !

// compute mvp

mvpmat:=projectionmat*modelviewmat2;
glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);

//Draw all of our triangles at once}
glDrawArrays(GL_TRIANGLES,0,36);


// try to draw a tetrahedron
//glEnableVertexAttribArray(positionLoc);
glBindBuffer(GL_ARRAY_BUFFER,vertexID);                 // vertexID is a buffer generated and filled at init by vertices
glBufferData(GL_ARRAY_BUFFER,SizeOf(Vertices2),@Vertices2,GL_DYNAMIC_DRAW);
glVertexAttribPointer(positionLoc,3,GL_FLOAT,GL_FALSE,3 * SizeOf(GLfloat),nil); // location and data format of vertex attributes:index.size,type,normalized,stride,offset
//glEnableVertexAttribArray(colorLoc);                    // the same for color buffer
glBindBuffer(GL_ARRAY_BUFFER,colorID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(Colors2),@Colors2,GL_DYNAMIC_DRAW);
glVertexAttribPointer(colorLoc,4,GL_FLOAT,GL_FALSE,4 * SizeOf(GLfloat),nil);

modelviewmat2:=scale(modelviewmat,0.6,0.6,0.6);
angle3+=1.33;
if angle3>360 then angle3-=360;
modelviewmat2:=rotate(modelviewmat2,1.0,-0.374,-0.608,angle3);
modelviewmat2:=translate(modelviewmat2,0,0,-2);
angle4+=0.97;
if angle4>360 then angle4-=360;

modelviewmat2:=rotate(modelviewmat2,0,1,-0,angle4);
modelviewmat2:=translate(modelviewmat2,0,0,-5);
mvpmat:=projectionmat*modelviewmat2;
glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);

//Draw all of our triangles at once}
glDrawArrays(GL_TRIANGLES,0,12);

//Disable the attribute arrays}
//glDisableVertexAttribArray(positionLoc);
//glDisableVertexAttribArray(colorLoc);

   {Swap the buffers to display the new scene}

eglSwapBuffers(Display,Surface);

frames+=1;

end;

procedure gl_cleanup;

var

 Success:Integer;
 DispmanUpdate:DISPMANX_UPDATE_HANDLE_T;

begin

// Delete the OpenGL ES buffers
glDeleteBuffers(1,@vertexID);
glDeleteBuffers(1,@colorID);

//Delete the OpenGL ES program
glDeleteProgram(programID);

//Destroy the EGL surface
eglDestroySurface(Display,Surface);

//Remove the dispmanx layer
DispmanUpdate:=vc_dispmanx_update_start(0);
vc_dispmanx_element_remove(DispmanUpdate,DispmanElement);
vc_dispmanx_update_submit_sync(DispmanUpdate);

//Close the DispmanX display
vc_dispmanx_display_close(DispmanDisplay);

//Release OpenGL resources and terminate EGL
eglMakeCurrent(Display,EGL_NO_SURFACE,EGL_NO_SURFACE,EGL_NO_CONTEXT);
eglDestroyContext(Display,Context);
eglTerminate(Display);

end;

procedure gltest2_start;


begin
BCMHostInit;
gl_init;
gl_prepare;
while keypressed do readkey;
repeat gl_draw until keypressed;
gl_cleanup;
BCMHostDeinit;
end;


end.

