unit gltest2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GLES20, DispmanX, VC4, Math, retromalina, mwindows, threads,retro;

type Pmatrix4=^matrix4;
     matrix4=array[0..3,0..3] of glfloat;
type vector4=array[0..3] of glfloat;

type T3dflavor=(cube,tetrahedron,octahedron,dodecahedron,icosahedron,sphere,custom);
    {
type T3dobject=class
     vertices:pointer;
     vnum:cardinal;
     indices:pointer;
     inum:cardinal;
     normals:pointer;
     nnum:cardinal;
     uvs:pointer;
     unum:cardinal;
     texture:pointer;
     flavor:T3dflavor;
     constructor create(flavor:T3dflavor)
     destructor destroy;
     procedure translate(x,y,z:glfloat);
     procedure rotate(x,y,z,a:glfloat);
     procedure scale(x,y,z:glfloat);
     end;
     }

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

var programID,vertexID,colorID,texcoordID:GLuint;
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
    texture0:gluint;
    texture1:gluint;
    u_vp_matrix:GLint;
    u_texture:GLint;
    u_palette:GLint;
    a_texcoord:GLint;

    uvs:array[0..179] of GLfloat=(
     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,

     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,

     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,

     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,

     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,

     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1,


     0, 0,
     0, 1,
     1, 0,
     1, 0,
     0, 1,
     1, 1


  );

    pallette:array[0..1023] of byte;
    pallette2:TPallette absolute pallette;

const kVertexCount = 180;

//--------------------- Shaders ------------------------------------------------

const VertexSource:String =
 'precision mediump float;' +
 'uniform mat4 u_mvpMat;' +
 'attribute vec4 a_position;' +
 'attribute vec4 a_color;' +
 'attribute vec2 a_texcoord;' +
 'varying vec4 v_color;' +
 'varying mediump vec2 v_texcoord;'+
 'void main()' +
 '{' +
 '    gl_Position = u_mvpMat * a_position;' +
 '    v_color = a_color;' +
 '    v_texcoord = a_texcoord; '+
 '}';

FragmentSource:String =
 'varying lowp vec4 v_color;' +
 'varying mediump vec2 v_texcoord;'+
 'uniform sampler2D u_texture;'+
 'uniform sampler2D u_palette;'+
 'void main()' +
 '{' +
 'vec4 p0 = texture2D(u_texture, v_texcoord);'+
 'vec4 c0 = texture2D(u_palette, vec2(p0.r*(255.0/256.0)+0.0001,0.5)); '+
 'if (v_color.a==0.0) {gl_FragColor = c0;} else {gl_FragColor = v_color;} '+
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

0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
);
{
//Front
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
 }

// ---------- test tetrahedron -------------------------------------------------

const Vertices2a:array[0..35] of GLfloat = (

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

var colors2:array[0..65535] of GLfloat;

var vertices1: array[0..1023] of glfloat;
    vertices2: array[0..16384] of glfloat;


implementation

procedure makesphere(precision:integer);

var rr,x,y,z,qq:glfloat;

    vertex,vertex2,r,s:integer;

begin
for r:=0 to 255 do
  begin
  colors2[4*r]:=random;
  colors2[4*r+1]:=random;
  colors2[4*r+2]:=random;
  colors2[4*r+3]:=0;
  end;
rr:=1/precision;
vertex:=0;
for r:=0 to precision do
  begin
  if r=0 then
    begin
    y:=-1.0; x:=0; z:=0;
    vertices1[vertex]:=x;
    vertices1[vertex+1]:=y;
    vertices1[vertex+2]:=z;
    vertex+=3;
    end

  else if r=precision then
    begin
    y:=-1.0; x:=0; z:=0;
    vertices1[vertex]:=x;
    vertices1[vertex+1]:=y;
    vertices1[vertex+2]:=z;
    vertex+=3;
    end

  else for s:=0 to precision-1 do
    begin
    qq:=0; //(r mod 2)*rr/2;
    y:=sin(-pi/2+pi*r*rr);
    x:=cos(2*pi*(s*rr+qq))*sin(pi*r*rr);
    z:=sin(2*pi*(s*rr+qq))*sin(pi*r*rr);
    vertices1[vertex]:=x;
    vertices1[vertex+1]:=y;
    vertices1[vertex+2]:=z;
    vertex+=3;
    end;
  end;

//retromalina.outtextxyz(0,0,inttostr(vertex),40,5,5);
// now there is (precision*precision-1) +2 vertices
// make precision*precision-1 triangles
vertex:=0; vertex2:=0; //todo: indices
for r:=1 to precision do
  begin
  if r=1 then     // make a triangle fan     precision+2 vertices
    begin
    for s:=0 to (3*precision)+2 do
      begin
      vertices2[vertex2]:=vertices1[vertex];
      vertex+=1; vertex2+=1;
      end;

    vertices2[vertex2]:=vertices2[vertex2-3*precision];
    vertices2[vertex2+1]:=vertices2[vertex2-3*precision+1];
    vertices2[vertex2+2]:=vertices2[vertex2-3*precision+2];
    vertex2+=3;
    end

  else if r=precision then
    begin
    vertices2[vertex2]:=0;
    vertices2[vertex2+1]:=1;
    vertices2[vertex2+2]:=0;
    vertex2+=3;
    for s:=precision downto 1 do
      begin
      vertices2[vertex2]:=vertices2[3*s];
      vertices2[vertex2+1]:=-vertices2[3*s+1];
      vertices2[vertex2+2]:=vertices2[3*s+2];
      vertex2+=3;
      end;
    end


  else if (r>1) and (r<precision) then  // make a triangle strip with 2*precision+1 vertices
    begin
    for s:=0 to precision-1 do
      begin
      vertices2[vertex2+3]:=vertices1[vertex];
      vertices2[vertex2+4]:=vertices1[vertex+1];
      vertices2[vertex2+5]:=vertices1[vertex+2];
      vertices2[vertex2+0]:=vertices1[(vertex-3*precision)];
      vertices2[vertex2+1]:=vertices1[(vertex+1-3*precision)];
      vertices2[vertex2+2]:=vertices1[(vertex+2-3*precision)];
      vertex+=3;
      vertex2+=6;
      end;
    vertices2[vertex2+0]:=vertices2[vertex2-6*precision];
    vertices2[vertex2+1]:=vertices2[vertex2-6*precision+1];
    vertices2[vertex2+2]:=vertices2[vertex2-6*precision+2];
    vertices2[vertex2+3]:=vertices2[(vertex2-6*precision+3)];
    vertices2[vertex2+4]:=vertices2[(vertex2-6*precision+4)];
    vertices2[vertex2+5]:=vertices2[(vertex2-6*precision+5)];
    vertex2+=6;
    end;
  end;

background.tc:=15;
//for s:=0 to 59 do background.println(floattostr(vertices2[3*s])+' '+floattostr(vertices2[3*s+1])+' '+floattostr(vertices2[3*s+2])+' ');

end;


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
glwindow.outtextxyz(0,0,'GL texture test',20,2,2);
glwindow.outtextxyz(0,32,'GL texture test',36,2,2);
glwindow.outtextxyz(0,64,'GL texture test',52,2,2);
glwindow.outtextxyz(0,96,'GL texture test',68,2,2);
glwindow.outtextxyz(0,128,'GL texture test',84,2,2);
glwindow.outtextxyz(0,160,'GL texture test',100,2,2);
glwindow.outtextxyz(0,192,'GL texture test',116,2,2);
glwindow.outtextxyz(0,224,'GL texture test',132,2,2);
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

pallette2:=ataripallette;
//for i:=0 to 1023 do pallette[i]:=i mod 256;

for i:=0 to 255 do pallette[4*i+3]:=$FF;

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
u_vp_matrix:=glGetUniformLocation(programID,'u_vp_matrix');
u_texture:=glGetUniformLocation(programID,'u_texture');
u_palette:=glGetUniformLocation(programID,'u_palette');
a_texcoord:=glGetAttribLocation(programID,'a_texcoord');

//Generate vertex and color buffers and fill them with our cube data

glGenBuffers(1,@vertexID);
//glBindBuffer(GL_ARRAY_BUFFER,vertexID);
//glBufferData(GL_ARRAY_BUFFER,SizeOf(Vertices),@Vertices,GL_STATIC_DRAW);

glGenBuffers(1,@colorID);
//glBindBuffer(GL_ARRAY_BUFFER,colorID);
//glBufferData(GL_ARRAY_BUFFER,SizeOf(Colors),@Colors,GL_STATIC_DRAW);

glGenBuffers(1,@texcoordID);
glBindBuffer(GL_ARRAY_BUFFER,texcoordID);
glVertexAttribPointer(a_texcoord, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), nil);
glEnableVertexAttribArray(a_texcoord);
glBufferData(GL_ARRAY_BUFFER, kVertexCount * sizeof(GLfloat) * 2, @uvs[0], GL_STATIC_DRAW);


glGenTextures(1, @texture0);
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture0);
glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 256, 256, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, glwindow.canvas);

glGenTextures(1, @texture1);
glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, texture1); 	// color palette
glTexImage2D(GL_TEXTURE_2D, 0, GL_BGRA, 256, 1, 0, GL_BGRA, GL_UNSIGNED_BYTE, @pallette);
//glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 256, 1, GL_RGBA, GL_UNSIGNED_BYTE, @pallette);

glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture0);
glUniform1i(u_texture,0);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_nearest); //@note : GL_LINEAR must be implemented in shader because of palette indexes in texture
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_nearest);

glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, texture1);
glUniform1i(u_palette, 1);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_nearest);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_nearest);

// Calculate the frustum and scale the projection}




aspect:=xres/yres;
n:=1.0;
f:=10.0;
fov:=30.0;
h:=tan(2*pi*fov/360)*n;
w:=h*aspect;

// initialize the projection matrix

projectionMat:=projection(matrix4_one,-w,w,-h,h,n,f);
//projectionMat:=ortho(matrix4_one,-w,w,-h,h,n,f);

// initialize the other matrices

modelviewMat:=matrix4_one;
mvpMat:=matrix4_one;
for i:=0 to 15 do
  for j:=0 to 15 do
    glwindow.box(16*i,16*j,16,16,16*j+i);
glwindow.outtextxyz(0,104,'OpenGLES 2',15,3,3);
makesphere(12);
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


for i:=0 to 15 do
  for j:=0 to 15 do
    glwindow.box(16*i,16*j,16,16,16*j+i);
glwindow.outtextxyz(0,frames mod 208,'OpenGLES 2',(frames div 16) mod 256,3,3);

//glwindow.tc:=frames mod 256;
//glwindow.bg:=(frames div 256) mod 256;
//glwindow.println('OpenGL ES 2.0 frame '+inttostr(frames));

//k+=1;
//for i:=0 to 11 do
//  begin
//  j:=(85*i+(k div 3)) mod 256;
//  r:=ataripallette[j] and $FF;
//  g:=(ataripallette[j] and $FF00) shr 8;
//  b:=(ataripallette[j] and $FF0000) shr 16;
//  colors2[4*i]:=r/256;
//  colors2[4*i+1]:=g/256;
//  colors2[4*i]:=b/256;
//  end;

glViewport(0,0,xres,yres);                              // full screen OpenGL view;
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // clear the scene
glUseProgram(programID);                                // attach a shader program

glUniform1i(u_texture,0);
glUniform1i(u_palette,1);

glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture0);
glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, 256, 256, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, glwindow.canvas);


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

angle1+=1.11/10;
if angle1>360 then angle1-=360;
modelviewmat2:=rotate(modelviewmat2,1.0,-0.374,-0.608,angle1);

// now translate the model one unit away

modelviewmat2:=translate(modelviewmat2,0,0,-3);

// and rotate it again around Y axis

angle2+=0.82/10;
if angle2>360 then angle2-=360;

modelviewmat2:=rotate(modelviewmat2,0,1,-0,angle2);

// then translate the model 4 units away

modelviewmat2:=translate(modelviewmat2,0,0,-5); // negative are far !

// compute mvp

mvpmat:=projectionmat*modelviewmat2;
glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);

// try to texture this



//	glBindBuffer(GL_ARRAY_BUFFER, buffers[1]); SHOW_ERROR
//	glVertexAttribPointer(sh->a_texcoord, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), NULL); SHOW_ERROR
//	glEnableVertexAttribArray(sh->a_texcoord); SHOW_ERROR

//	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[2]); SHOW_ERROR

//	glDrawElements(GL_TRIANGLES, kIndexCount, GL_UNSIGNED_SHORT, 0); SHOW_ERROR

//Draw all of our triangles at once}
glDrawArrays(GL_TRIANGLES,0,36);


// try to draw a tetrahedron
//glEnableVertexAttribArray(positionLoc);
//glEnableVertexAttribArray(colorLoc);                    // the same for color buffer
glBindBuffer(GL_ARRAY_BUFFER,colorID);
glBufferData(GL_ARRAY_BUFFER,1024,@Colors2,GL_DYNAMIC_DRAW);
glVertexAttribPointer(colorLoc,4,GL_FLOAT,GL_FALSE,4 * SizeOf(GLfloat),nil);

modelviewmat2:=scale(modelviewmat,0.6,0.6,0.6);
angle3+=1.33/5;
if angle3>360 then angle3-=360;
modelviewmat2:=rotate(modelviewmat2,1.0,-0.374,-0.608,angle3);
modelviewmat2:=translate(modelviewmat2,0,0,-3);
angle4+=0.97/5;
if angle4>360 then angle4-=360;

modelviewmat2:=rotate(modelviewmat2,0,1,-0,angle4);
modelviewmat2:=translate(modelviewmat2,0,0,-5);
mvpmat:=projectionmat*modelviewmat2;
glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);

glBindBuffer(GL_ARRAY_BUFFER,vertexID);                 // vertexID is a buffer generated and filled at init by vertices
glBufferData(GL_ARRAY_BUFFER,168,@Vertices2[0],GL_DYNAMIC_DRAW);
glVertexAttribPointer(positionLoc,3,GL_FLOAT,GL_FALSE,3 * SizeOf(GLfloat),nil); // location and data format of vertex attributes:index.size,type,normalized,stride,offset



//Draw all of our triangles at once}
glDrawArrays(GL_TRIANGLE_FAN,0,14);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[42],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[120],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198+3*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198+6*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198+9*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198+12*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198+15*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198+18*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,312,@Vertices2[198+21*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_STRIP,0,26);
glBufferData(GL_ARRAY_BUFFER,168,@Vertices2[198+24*26],GL_DYNAMIC_DRAW);
glDrawArrays(GL_TRIANGLE_FAN,0,14);


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

