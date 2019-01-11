unit glwindows;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GLES20, DispmanX, VC4, Math, retromalina, mwindows, threads,retro,platform,playerunit,blitter,simplegl;

procedure glwindows_start;

type TGLWindowsThread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;




type TGLWindow=class(TObject)
     handle:TGLWindow;
     prev,next:TGLWindow;                     // 2-way list
     x,y:integer;                           // position on screen
     l,h:integer;                           // dmensions on screen
     vx,vy:integer;                         // visible upper left
     vcl,vch:integer;                       // virtual canvas dimensions
     vcx,vcy:integer;                       // virtual canvas x,y
     mx,my,mk:integer;                      // mouse events
     wl,wh:integer;                         // windows l,h
     tcx,tcy:integer;                       // text cursor
     bg:integer;                            // background color
     tc:integer;                            // text color
     canvasx,canvasy:integer;               // position on a texture instead of graphic memory
     decoration:TDecoration;                // the decoration or nil if none
     visible:boolean;                       // visible or hidden
     resizable:boolean;                     // if true windows not resizable
     movable:boolean;                       // if true windows not movable by mouse
     redraw:boolean;                        // set true by redrawing process after redraw
     active:boolean;                        // if false, window doesn't need redrawing
     title:string;                          // window title
     buttons:TWidget;                       // widget chain start
     icons:TIcon;
     menu:TMenu;
     statusbar:TStatusbar;
     mstate:integer;                        // mouse position state
     dclick:boolean;
     needclose:boolean;
     activey:integer;
     selected:boolean;
     virtualcanvas:boolean;
     a32bit:boolean;

     // The constructor. al, ah - graphic canvas dimensions
     // atitle - title to set, if '' then windows will have no decoration

     constructor create (al,ah:integer; atitle:string);
     destructor destroy; override;

//     procedure draw(dest:integer);                                      // redraw a window
//     procedure move(ax,ay,al,ah,avx,avy:integer);                       // move and resize. ax,ay - position on screen
                                                                        // al, ah - visible dimensions without decoration
                                                                        // avy, avy - upper left visible canvas pixel
//     function checkmouse:TWindow;                                       // check and react to mouse events
//     procedure resize(nwl,nwh:integer);                                 // resize the canvas
//     procedure select;                                                  // select the window and place it on top

     // graphic methods

//     procedure cls(c:integer);                                          // clear window and fill with color
//     procedure putpixel(ax,ay,color:integer); inline;                   // put a pixel to window
//     function getpixel(ax,ay:integer):integer; inline;                  // get a pixel from window
//     procedure putchar(ax,ay:integer;ch:char;col:integer);              // put a 8x16 char on window
//     procedure putchar8(ax,ay:integer;ch:char;col:integer);              // put a 8x16 char on window
//     procedure putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);       // put a zoomed char, xz,yz - zoom
//     procedure outtextxy8(ax,ay:integer; t:string;c:integer);           // output a string from x,y position
//     procedure outtextxy(ax,ay:integer; t:string;c:integer);            // output a string from x,y position
//     procedure outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);     // output a zoomed string
//     procedure box(ax,ay,al,ah,c:integer);                              // draw a filled box
//     procedure print(line:string);                                      // print a string at the text cursor
//     procedure println(line:string);                                    // print a string and add a new line
//     procedure scrollup;

     // TODO: add the rest of graphic procedures from retromalina unit

     end;

     // Theme colors.

var      activecolor:integer=120;
         inactivecolor:integer=13;
         activetextcolor:integer=15;
         inactivetextcolor:integer=0;
         borderwidth:integer=6;
         scrollwidth:integer=16;
         borderdelta:integer=2;
         scrollcolor:integer=12;
         activescrollcolor:integer=124;
         titleheight:integer=24;
         menuheight:integer=24;
         menucolor:integer=142;



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
    u_scale:GLint;
    u_delta:GLint;
    a_texcoord:GLint;
    a_normal:GLint;
    u_mvmat:GLint;
    u_lightsourcemat:GLInt;




//---------------- end of the square definition


implementation


var programID,vertexID,colorID,texcoordID,normalID:GLuint;
    mvpLoc,positionLoc,colorLoc,lightloc:GLuint;
    mvLoc,lightsourceloc:GLuint;
    projectionMat,modelviewMat,mvpMat,lightmat,mvmat,lightsourcemat:matrix4;
    frames:integer;

    vertices1,vertices2: array[0..svertex-1] of vector3; //sphere generator vars
    suvs,suvs2:array[0..svertex-1] of vector2;
    snormals,snormals2:array[0..svertex-1] of vector3;
    pallette:array[0..1023] of byte;
    pallette2:TPallette absolute pallette;

    texaddr:cardinal;
    testbitmap:TTexturebitmap;

    GLbackground:TGLWindow=nil;


// -----------------  A square ------------------------------------------------

var square_vertices:array[0..17] of GLfloat = (
-1.0, 1.0, 0.0,-1.0,-1.0, 0.0, 1.0, 1.0, 0.0,          // Front
 1.0, 1.0, 0.0,-1.0,-1.0, 0.0, 1.0,-1.0, 0.0

);
var square_normals:array[0..17] of GLfloat = (
 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0,          // Front
 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0

);

var square_uvs:array[0..11] of GLfloat=(
 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1
);

//--------------------- Shaders ------------------------------------------------

const VertexSource:String =
     'precision highp float;' +
     'uniform mat4 u_mvpMat;' +
     'uniform vec2 u_scale;'+
     'uniform vec2 u_delta;'+
     'attribute vec4 a_position;' +
     'attribute vec2 a_texcoord;' +
     'varying highp vec2 v_texcoord;'+
     'void main()' +
     '{' +
     '    gl_Position = u_mvpMat * a_position; ' +
     '    v_texcoord = a_texcoord*u_scale+u_delta;  '+
     '}';

    FragmentSource:String =
     'precision highp float;' +
     'varying highp vec2 v_texcoord;'+
     'uniform highp sampler2D u_texture;'+
     'uniform highp sampler2D u_palette;'+

     'void main()' +
     '{' +
     'float mti = floor(4.0*fract(2048.0*v_texcoord.x)); ' +
     'vec4 p0 = texture2D(u_texture, v_texcoord)*0.996; '+
     'float p0f=(1.0-abs(sign(mti)))*p0.r+(1.0-abs(sign(mti-1.0)))*p0.g+(1.0-abs(sign(mti-2.0)))*p0.b+(1.0-abs(sign(mti-3.0)))*p0.a; '+
     'gl_FragColor = texture2D(u_palette, vec2(p0f+0.0001,0.5)); '+
      '}';




    // GLWindow procedures
constructor TGLWindow.create (al,ah:integer; atitle:string);

var who:TGLWindow;
    i,j:integer;

begin
inherited create;
semaphore:=true;
mstate:=0;
dclick:=false;
needclose:=false;
if background<>nil then   // there ia s background so create a normal window
  begin
  who:=GLbackground;
  while who.next<>nil do who:=who.next;
//  makeicon;               // Temporary icon, todo: icon class
  handle:=self;
  x:=0;                   // initialize the fields
  y:=0;
  mx:=-1;
  my:=-1;
  mk:=0;
  vx:=0;
  vy:=0;
  vcx:=0;
  vcy:=0;
  l:=0;
  h:=0;
  bg:=0;
  wl:=al;
  wh:=ah;
  vcl:=0;
  vch:=0;
  tcx:=0;
  tcy:=0;
  tc:=15;
  virtualcanvas:=false;
  buttons:=nil;
  icons:=nil;
  next:=nil;
  visible:=false;
  resizable:=true;
  prev:=who;
  canvasx:=0;                //todo: get a place on a texture    // getmem(wl*wh);  // get a memory for graphics. 8-bit only in this version
  canvasy:=0;                //todo: get a place on a texture    // getmem(wl*wh);  // get a memory for graphics. 8-bit only in this version
//  for i:=0 to wl*wh-1 do poke(cardinal(canvas)+i,0); // clear the graphic memory
  title:=atitle;
  if atitle<>'' then     // create a decoration
    begin
//    decoration:=TDecoration.create;
//    decoration.title:=getmem(wl*titleheight);
//    decoration.hscroll:=true;
//    decoration.vscroll:=true;
//    decoration.up:=true;
//    decoration.down:=true;
//    decoration.close:=true;
//    activey:=0;
    end
  else begin decoration:=nil; activey:=24; end;
  who.next:=self;
  end
else                    // no background, create one
  begin
  handle:=self;
  prev:=nil;
  next:=nil;
  x:=0;
  y:=0;                       // position on screen
  l:=al;
  h:=ah;                      // dimensions on screen
  vx:=0;
  vy:=0;                      // visible upper left
  vcx:=0;
  vcy:=0;
  wl:=al;
  wh:=ah;                     // windows l,h
  vcl:=0;
  vch:=0;
  virtualcanvas:=false;
  bg:=132;                    // todo: get color from a theme
  buttons:=nil;
  icons:=nil;
  canvasx:=0;                //todo: get a place on a texture    // getmem(wl*wh);  // get a memory for graphics. 8-bit only in this version
  canvasy:=0;                //todo: get a place on a texture    // getmem(wl*wh);  // get a memory for graphics. 8-bit only in this version
                            // todo: do not waste a main texture for the background window
                            // do not use it at all !!! It is instead a placeholder for start of the glwindows list

  visible:=true;
  redraw:=true;
  mx:=-1;
  my:=-1;
  decoration:=nil;
  title:='';
  end;
selected:=true;
semaphore:=false;
//moved:=0;
end;


//------------------------------------------------------------------------------
// TWindow destructor
//------------------------------------------------------------------------------


destructor TGLWindow.destroy;

var i,j:integer;

begin
visible:=false;
prev.next:=next;
if next<>nil then next.prev:=prev;
//if canvas<>nil then freemem(canvas);
//if decoration<>nil then
//  begin
//  decoration.destroy
//  end;
end;



//  ---------------------------------------------------------------------
//   box2(x1,y1,x2,y2,color)
//   Draw a filled rectangle, upper left at position (x1,y1)
//   lower right at position (x2,y2)
//   wrapper for box procedure
//   rev. 2015.10.17
//  ---------------------------------------------------------------------

procedure box2(x1,y1,x2,y2,color:integer);

begin
if x1>x2 then begin i:=x2; x2:=x1; x1:=i; end;
if y1>y2 then begin i:=y2; y2:=y1; y1:=i; end;
if (x1<>x2) and (y1<>y2) then  box(x1,y1,x2-x1+1, y2-y1+1,color);

end;


procedure line2(x1,y1,x2,y2,c:integer);

var d,dx,dy,ai,bi,xi,yi,x,y:integer;

begin
x:=x1;
y:=y1;
if (x1<x2) then
  begin
  xi:=1;
  dx:=x2-x1;
  end
else
  begin
   xi:=-1;
   dx:=x1-x2;
  end;
if (y1<y2) then
  begin
  yi:=1;
  dy:=y2-y1;
  end
else
  begin
  yi:=-1;
  dy:=y1-y2;
  end;

putpixel(x,y,c);
if (dx>dy) then
  begin
  ai:=(dy-dx)*2;
  bi:=dy*2;
  d:= bi-dx;
  while (x<>x2) do
    begin
    if (d>=0) then
      begin
      x+=xi;
      y+=yi;
      d+=ai;
      end
    else
      begin
      d+=bi;
      x+=xi;
      end;
    putpixel(x,y,c);
    end;
  end
else
  begin
  ai:=(dx-dy)*2;
  bi:=dx*2;
  d:=bi-dy;
  while (y<>y2) do
    begin
    if (d>=0) then
      begin
      x+=xi;
      y+=yi;
      d+=ai;
      end
    else
      begin
      d+=bi;
      y+=yi;
      end;
    putpixel(x, y,c);
    end;
  end;
end;

procedure line(x,y,dx,dy,c:integer);

begin
line2(x,y,x+dx,y+dy,c);
end;

procedure circle(x0,y0,r,c:integer);

var d,x,y,da,db:integer;

begin
d:=5-4*r;
x:=0;
y:=r;
da:=(-2*r+5)*4;
db:=3*4;
while (x<=y) do
  begin
  putpixel(x0-x,y0-y,c);
  putpixel(x0-x,y0+y,c);
  putpixel(x0+x,y0-y,c);
  putpixel(x0+x,y0+y,c);
  putpixel(x0-y,y0-x,c);
  putpixel(x0-y,y0+x,c);
  putpixel(x0+y,y0-x,c);
  putpixel(x0+y,y0+x,c);
  if d>0 then
    begin
    d+=da;
    y-=1;
    x+=1;
    da+=4*4;
    db+=2*4;
    end
  else
    begin
    d+=db;
    x+=1;
    da+=2*4;
    db+=2*4;
    end;
  end;
end;


procedure fcircle(x0,y0,r,c:integer);

var d,x,y,da,db:integer;

begin
d:=5-4*r;
x:=0;
y:=r;
da:=(-2*r+5)*4;
db:=3*4;
while (x<=y) do
  begin
  line2(x0-x,y0-y,x0+x,y0-y,c);
  line2(x0-x,y0+y,x0+x,y0+y,c);
  line2(x0-y,y0-x,x0+y,y0-x,c);
  line2(x0-y,y0+x,x0+y,y0+x,c);
  if d>0 then
    begin
    d+=da;
    y-=1;
    x+=1;
    da+=4*4;
    db+=2*4;
    end
  else
    begin
    d+=db;
    x+=1;
    da+=2*4;
    db+=2*4;
    end;
  end;
end;




procedure outtextxys(x,y:integer; t:string;c,s:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(x+s*i-s,y,t[i],c);
end;

procedure outtextxyzs(x,y:integer; t:string;c,xz,yz,s:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(x+s*xz*i,y,t[i+1],c,xz,yz);
end;






procedure makesphere(precision:integer);

var rr,x,y,z,qq:glfloat;
    i, vertex,vertex2,r,s:integer;

begin

// Pass 1. Compute all vertices and uvs. Todo: normals.

rr:=1/precision;
vertex:=0;
for r:=0 to precision do
  begin
  if r=0 then
    begin
    y:=-1.0; x:=0; z:=0;
    vertices1[vertex,0]:=x;
    vertices1[vertex,1]:=y;
    vertices1[vertex,2]:=z;
    suvs[vertex,0]:=0.5; suvs[vertex,1]:=0;
    vertex+=1;
    end

  else if r=precision then
    begin
    y:=1.0; x:=0; z:=0;
    vertices1[vertex,0]:=x;
    vertices1[vertex,1]:=y;
    vertices1[vertex,2]:=z;
    suvs[vertex,0]:=0.5; suvs[vertex,1]:=1;
    vertex+=1;
    end

  else for s:=0 to precision-1 do
    begin
    qq:=0;
    y:=sin(-pi/2+pi*r*rr);
    x:=cos(2*pi*(s*rr+qq))*sin(pi*r*rr);
    z:=sin(2*pi*(s*rr+qq))*sin(pi*r*rr);
    suvs[vertex,0]:=s*rr; suvs[vertex,1]:=r*rr;

    vertices1[vertex,0]:=x;
    vertices1[vertex,1]:=y;
    vertices1[vertex,2]:=z;
    vertex+=1;
    end;
  end;

// Pass 2. Prepare a triangle strip

vertex:=1; vertex2:=0;
for r:=1 to precision do
  begin
  if r=1 then         // make a triangle strip with degenerated triangles
    begin             // instead of a triangle fan to draw the sphere in one pass
    for s:=0 to precision-1 do
      begin
      vertices2[vertex2+1]:=vertices1[vertex];
      vertices2[vertex2]:=vertices1[0];
      suvs2[vertex2+1]:=suvs[vertex];
      suvs2[vertex2]:=suvs[0];
      vertex+=1;
      vertex2+=2;
      end;
    vertices2[vertex2]:=vertices2[vertex2-2*precision];
    vertices2[vertex2+1]:=vertices2[(vertex2-2*precision+1)];
    suvs2[vertex2]:=suvs2[vertex2-2*precision];
    suvs2[vertex2+1]:=suvs2[(vertex2-2*precision+1)];
    suvs2[vertex2,0]:=1;
    suvs2[vertex2+1,0]:=1;
    vertex2+=2;
    end

   else if r=precision then
    begin
    i:=vertex;  vertex:=i-1;
    for s:=0 to precision-1 do
      begin
      vertices2[vertex2]:=vertices1[i];
      vertices2[vertex2+1]:=vertices1[vertex];   //-precision];
      suvs2[vertex2]:=suvs[i];
      suvs2[vertex2+1]:=suvs[vertex];        // -precision];
      vertex-=1;
      vertex2+=2;
      end;
    vertices2[vertex2]:=vertices1[i];
    vertices2[vertex2+1]:=vertices2[vertex2-2*precision+1];
    suvs2[vertex2]:=suvs2[vertex2-2*precision];
    suvs2[vertex2+1]:=suvs2[(vertex2-2*precision+1)];
    suvs2[vertex2,0]:=1;
    suvs2[vertex2+1,0]:=1;
    vertex2+=2;
    end

  else if (r>1) and (r<precision) then  // make a triangle strip with 2*precision+1 vertices
    begin
    for s:=0 to precision-1 do
      begin
      vertices2[vertex2+1]:=vertices1[vertex];
      vertices2[vertex2]:=vertices1[vertex-precision];
      suvs2[vertex2+1]:=suvs[vertex];
      suvs2[vertex2]:=suvs[vertex-precision];
      vertex+=1;
      vertex2+=2;
      end;
    vertices2[vertex2]:=vertices2[vertex2-2*precision];
    vertices2[vertex2+1]:=vertices2[(vertex2-2*precision+1)];
    suvs2[vertex2]:=suvs2[vertex2-2*precision];
    suvs2[vertex2+1]:=suvs2[(vertex2-2*precision+1)];
    suvs2[vertex2,0]:=1;
    suvs2[vertex2+1,0]:=1;
    vertex2+=2;
    end;
  end;
// a sphere with r=1 has normals=points!
snormals2:=vertices2;

end;


constructor TGLWindowsThread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TGLWindowsThread.execute;

label p999;


begin
ThreadSetPriority(ThreadGetCurrent,6);
ThreadSetAffinity(ThreadGetCurrent,4);
threadsleep(10);
if glwindow=nil then
  begin
  glwindow:=TWindow.create(256 ,256 ,'OpenGL helper window');
  glwindow.decoration.hscroll:=false;
  glwindow.decoration.vscroll:=false;
  glwindow.resizable:=false;
  glwindow.cls(0);
  glwindow.move(100,100,1024,1024,0,0);
  glwindow.cls(147);
  glwindow.box(0,0,128,128,40);
  glwindow.box(0,128,128,128,120);
  glwindow.box(128,0,128,128,200);
  glwindow.box(128,128,128,128,232);
  glwindow.outtextxyz(0,frames mod 208,'OpenGLES 2',(frames div 16) mod 256,3,3);
  end
else goto p999;
//helper:=TOpenGLHelperThread.create(true);
//helper.Start;
glwindows_start;
//helper.terminate;
//helper.destroy;
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

function scale(a:matrix4;sx,sy,sz:glfloat):matrix4;

var s:matrix4;
begin
 s:=matrix4_zero;
 s[0,0]:=sx; s[1,1]:=sy; s[2,2]:=sz; s[3,3]:=1;
 result:=s*a;
end;

//----------------------translate ----------------------------------------------

function translate(a:matrix4;sx,sy,sz:glfloat):matrix4;

var s:matrix4;
begin
 s:=matrix4_one;
 s[3,0]:=sx; s[3,1]:=sy; s[3,2]:=sz;
 result:=s*a;
end;

//---------------- frustum projection ------------------------------------------

function projection(a:matrix4;l,r,b,t,n,f:glfloat):matrix4;

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

function ortho(a:matrix4;l,r,b,t,n,f:glfloat):matrix4;

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
    i,j,k:integer;

begin

// initialize a pallette
pallette2:=ataripallette;
for i:=0 to 255 do pallette[4*i+3]:=$FF;

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

mvpLoc:=glGetUniformLocation(programID,'u_mvpMat');
mvLoc:=glGetUniformLocation(programID,'u_mvMat');
lightLoc:=glGetUniformLocation(programID,'u_lightMat');
lightsourceLoc:=glGetUniformLocation(programID,'u_lightsourceMat');
positionLoc:=glGetAttribLocation(programID,'a_position');
glEnableVertexAttribArray(positionLoc);
u_vp_matrix:=glGetUniformLocation(programID,'u_vp_matrix');
u_texture:=glGetUniformLocation(programID,'u_texture');
u_palette:=glGetUniformLocation(programID,'u_palette');
u_scale:=glGetUniformLocation(programID,'u_scale');
u_delta:=glGetUniformLocation(programID,'u_delta');
a_texcoord:=glGetAttribLocation(programID,'a_texcoord');
a_normal:=glGetAttribLocation(programID,'a_normal');

//Generate vertex and color buffers and fill them with our cube data

glGenBuffers(1,@vertexID);
glBindBuffer(GL_ARRAY_BUFFER,vertexID);
glVertexAttribPointer(positionLoc,3,GL_FLOAT,GL_FALSE,3 * SizeOf(GLfloat),nil); // location and data format of vertex attributes:index.size,type,normalized,stride,offset

glGenBuffers(1,@texcoordID);
glBindBuffer(GL_ARRAY_BUFFER,texcoordID);
glVertexAttribPointer(a_texcoord, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), nil);
glEnableVertexAttribArray(a_texcoord);
//glBufferData(GL_ARRAY_BUFFER, sizeof(uvs), @uvs[0], GL_STATIC_DRAW);

glGenBuffers(1,@normalID);
glBindBuffer(GL_ARRAY_BUFFER,normalID);
glVertexAttribPointer(a_normal, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), nil);
glEnableVertexAttribArray(a_normal);

glGenTextures(1, @texture0);
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture0);
glTexImage2D(GL_TEXTURE_2D, 0, gl_rgba, 2048, 2048, 0, gl_rgba, GL_UNSIGNED_BYTE,nil); // glwindow.canvas);
glwindow.putpixel(0,0,$11);
glwindow.putpixel(1,0,$11);
glwindow.putpixel(2,0,$11);
glwindow.putpixel(3,0,$11);
glwindow.putpixel(4,0,$12);
glwindow.putpixel(5,0,$12);
glwindow.putpixel(6,0,$12);
glwindow.putpixel(7,0,$12);
glwindow.putpixel(8,0,$13);
glwindow.putpixel(9,0,$13);
glwindow.putpixel(10,0,$13);
glwindow.putpixel(11,0,$13);
glwindow.putpixel(12,0,$14);
glwindow.putpixel(13,0,$14);
glwindow.putpixel(14,0,$14);
glwindow.putpixel(15,0,$14);
glTexSubImage2D(GL_TEXTURE_2D, 0, 0,0, 64 ,256 ,GL_rgba, GL_unsigned_BYTE, glwindow.canvas); // push the texture from window canvas to GPU area

i:=$30000000; repeat i:=i+4 until ((lpeek(i)=$11111111) and (lpeek(i+4)=$12121212) and (lpeek(i+8)=$13131313) and (lpeek(i+12)=$14141414)) or (i>$3F000000) ;
testbitmap.address:=i;testbitmap.w:=256; testbitmap.l:=256;
texaddr:=i;
outtextxyz(0,0,inttohex(i,8),40,3,3);
//glwindow.canvas:=pointer(i);

//i:=$30000000; repeat i:=i+4 until (lpeek(i)=$c8c8c8c8) or (i>$3F000000) ;
//outtextxyz(0,50,inttohex(i,8),120,3,3);

//for j:=0 to 255 do lpoke(i+4*j,j);
//for j:=0 to 255 do lpoke(1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);
//for j:=0 to 255 do lpoke(2*1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);
//for j:=0 to 255 do lpoke(3*1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);
//for j:=0 to 255 do lpoke(4*1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);
//for j:=0 to 255 do lpoke(5*1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);
//for j:=0 to 255 do lpoke(6*1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);
//for j:=0 to 255 do lpoke(7*1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);
//for j:=0 to 255 do lpoke(8*1024+i+4*j,j+j shl 8+ j shl 16 + j shl 24);

//for j:=32 to 63 do lpoke(i+4*j,$28282828);

//for j:=64 to 95 do lpoke(i+4*j,$78787878);

//for j:=96 to 127 do lpoke(i+4*j,$b8b8b8b8);

//for j:=128 to 159 do lpoke(i+4*j,$44444444);

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
n:=1;
f:=10.0;
fov:=10.0;
h:=1; //tan(2*pi*fov/360)*n;
w:=h*aspect;

// initialize the projection matrix- uncomment one of them

projectionMat:=projection(matrix4_one,-w,w,-h,h,n,f);   //frustum
//projectionMat:=ortho(matrix4_one,-w,w,-h,h,n,f);      //orho

// initialize the other matrices

modelviewMat:=matrix4_one;
mvpMat:=matrix4_one;
lightMat:=matrix4_one;
makesphere(precision);
glViewport(0,0,xres,yres);                              // full screen OpenGL view;

glUseProgram(programID);                                // attach a shader program
glUniform1i(u_texture,0);                               // tell the shader what is the texture numbers
glUniform1i(u_palette,1);                               // this is a pallette so OpenGL object can show the 8-bit depth window
for i:=0 to 600 do for j:=0 to 600 do testbitmap.putpixel(i,j,getpixel(i+660,j+300));


for i:=0 to 255 do for j:=0 to 255 do testbitmap.putpixel(8192-256+i,2048-256+j,0);
//putpixeltestbitmap.box(8192-256,2048-256,128,128,40);
//testbitmap.box(8192-256,2048-256+128,128,128,120);
//testbitmap.box(8192-256+128,2048-256,128,128,200);
//testbitmap.box(8192-256+128,2048-256+128,128,128,232);
for i:=0 to 15 do testbitmap.outtextxy(8192-256,2048-256+i*16,'GL window test',i*16+88);
cleandatacacherange(testbitmap.address+$1000000-131072*16,131072*16);
 //UVs for the texture
glBindBuffer(GL_ARRAY_BUFFER,texcoordID);
glBufferData(GL_ARRAY_BUFFER, sizeof(square_uvs), @square_uvs[0], GL_static_DRAW);

//Vertices
glBindBuffer(GL_ARRAY_BUFFER,vertexID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(square_vertices),@square_vertices,GL_static_DRAW);

//Normals
glBindBuffer(GL_ARRAY_BUFFER,normalID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(square_normals),@square_normals,GL_static_DRAW);
end;


procedure gl_draw;

var modelviewmat2:matrix4;
    tb:array[0..187*885] of byte;

    tscale:array[0..1] of glfloat=(1.0,1.0);
    tdelta:array[0..1] of glfloat=(0.0,0.0);

const          t:int64=0;
const     k:integer=0;
           ddd:glfloat=-2;

begin
t:=gettime;
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // clear the scene
if mousewheel=127 then begin ddd:=ddd*1.01; mousewheel:=128; if ddd<-9.999 then ddd :=-9.999; end;
if mousewheel=129 then begin ddd:=ddd*0.99; mousewheel:=128; if ddd>-1.00001 then ddd :=-1.00001; end;

    tscale[0]:=64/2048;
    tscale[1]:=256/2048;
    tdelta[0]:=(8192-256)/8192;
    tdelta[1]:=(2048-256)/2048;
  gluniform2fv(u_scale,1,@tscale);
  gluniform2fv(u_delta,1,@tdelta);


// ------------------- Draw a square --------------------------------------------


// transform the model

// A transform matrix for lighting. As it will transform normals only
// the scale and translate transforms are omitted


lightmat:=modelviewmat;
modelviewmat2:=translate(modelviewmat,0,0,ddd);                  // move 3 units into the screen
mvmat:=modelviewmat2;                                  // todo: moving camera
mvpmat:=projectionmat*mvmat;
glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);

glDrawArrays(GL_TRIANGLES,0,6);



tscale[0]:=600/8192;
tscale[1]:=600/2048;
tdelta[0]:=0;
tdelta[1]:=0;
gluniform2fv(u_scale,1,@tscale);
gluniform2fv(u_delta,1,@tdelta);
modelviewmat2:=scale(modelviewmat,15,15,15);
modelviewmat2:=translate(modelviewmat2,0,0,-9.99);

mvmat:=modelviewmat2;                                  // todo: moving camera
mvpmat:=projectionmat*mvmat;
glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);

glDrawArrays(GL_TRIANGLES,0,6);

eglSwapBuffers(Display,Surface);
t:=gettime-t;
box(0,0,200,100,0); outtextxyz(0,0,floattostr(t),40,1,1);
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

procedure glwindows_start;

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

