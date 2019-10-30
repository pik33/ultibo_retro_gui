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
    mvpLoc,positionLoc,colorLoc,lightloc:GLuint;
    mvLoc,lightsourceloc:GLuint;
    projectionMat,modelviewMat,mvpMat,lightmat,mvmat,lightsourcemat:matrix4;
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


    pallette:array[0..1023] of byte;
    pallette2:TPallette absolute pallette;

    texaddr:cardinal;
    testbitmap:TTexturebitmap;

    shaderthread:TShaderThread=nil;

    basetime:int64;
    u_itime:glint;

    //chuj:cardinal;

//--------------------- Shaders ------------------------------------------------

{const VertexSource:String =
 'precision highp float;' +
 'attribute vec4 a_position;' +
 'attribute vec2 a_texcoord;' +
 'attribute vec4 a_normal;' +
 'varying highp vec2 v_texcoord;'+
 'void main()' +
 '{' +
   ' vec2 scale=vec2(1920./2048.,1200./2048.); '+
 '    gl_Position = a_position; ' +
 '    v_texcoord = a_texcoord*scale;  '+
 '}';

FragmentSource:String =
 'precision highp float;' +
 'varying highp vec2 v_texcoord;'+
 'uniform highp sampler2D u_texture;'+
 'void main()' +
 '{' +

 'vec4 p0 = texture2D(u_texture, v_texcoord); '+
 'gl_FragColor =  p0; '  +


  '}';
 }


const VertexSource:String =

 'attribute vec4 a_position; ' +
 'attribute vec2 a_texcoord; ' +
 'varying vec2 v_texcoord; '+
 'void main() ' +
 '{' +
 '    gl_Position = a_position; ' +
// '    v_texcoord = vec2(800./2048.,600./2048.)*a_texcoord;  '+
 '    v_texcoord = a_texcoord;  '+
 '}';

FragmentSource:String =
 'varying vec2 v_texcoord; '+
 'uniform sampler2D u_texture; '+
 'uniform float iTime; '+
 'void main()' +
 '{' +
   ' vec2 iResolution=vec2(960.,600.); '+
   ' vec2 p=(3.0*gl_FragCoord.xy-iResolution.xy)/max(iResolution.x,iResolution.y);  '+
   'float f = cos(iTime/30.);                                                     '+
   'float s = sin(iTime/30.);                                                     '+
   'p = vec2(p.x*f-p.y*s, p.x*s+p.y*f);                                         '+

   'for(float i=3.0;i<30.;i++) '+
'	{           '+
 '    vec2 p1= (i*p.yx+iTime*vec2(.30,.30)  + vec2(.30,3.0)); '+
 '    p1= cos(p1); '+
 '    p1= abs(p1); '+
 '    p1= sqrt(p1); '+
 '    p+= .30/i * p1; '+
// '    p+= .30/i * sqrt(abs(cos(i*p.yx+iTime*vec2(.30,.30)  + vec2(.30,3.0)))); '+
'	}                                                                           '+
'	vec3 col=vec3(.30*sin(3.0*p.x)+.30,.30*sin(3.0*p.y)+.30,sin(3.0*p.x+3.0*p.y)); '+
'	gl_FragColor=(3.0/(3.0-(3.0/3.0)))*vec4(col, 3.0);                               '+
'} ';

// -----------------  test square ------------------------------------------------

var vertices:array[0..17] of GLfloat = (               // 6*3-1
-1.0, 1.0, 0.0,-1.0,-1.0, 0.0, 1.0, 1.0, 0.0,          // Front
 1.0, 1.0, 0.0,-1.0,-1.0, 0.0, 1.0,-1.0, 0.0
);

var normals:array[0..17] of GLfloat = (               // 6*3-1
  0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0,
  0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0
);

uvs:array[0..71] of GLfloat=(
  0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1,
  0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1,
  0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1,
  0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1,
  0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1,
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
  glwindow:=TWindow.create(256 ,256 ,'');
  glwindow.cls($23);
  q:=$4655434b; lpoke(cardinal(glwindow.canvas),q);
  q:=$15161718; lpoke(cardinal(glwindow.canvas)+4,q);

  end
else goto p999;
shadertest_start;
glwindow:=nil;
p999:
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

vc_dispmanx_rect_set(@DestRect,0,0,xres, yres );
vc_dispmanx_rect_set(@SourceRect,0,0,(xres shl 16),(yres shl 16));  // shl 16 all params

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


procedure shader_prepare;

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

glGenBuffers(1,@normalID);
glBindBuffer(GL_ARRAY_BUFFER,normalID);
glVertexAttribPointer(a_normal, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), nil);
glEnableVertexAttribArray(a_normal);

glGenTextures(1, @texture0);
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture0);
glTexImage2D(GL_TEXTURE_2D, 0, gl_luminance, 2048, 2048, 0, gl_luminance, GL_UNSIGNED_BYTE,nil); // glwindow.canvas);

glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 256 ,256 ,GL_luminance, GL_unsigned_BYTE, glwindow.canvas); // push the texture from window canvas to GPU area

//Find the testure pointer
i:=$30000000; repeat i:=i+4 until ((lpeek(i)=$4655434b) and (lpeek(i+4)=$15161718) and (lpeek(i+128)=$23232323) and (lpeek(i+192)=$23232323)) or (i>$3F000000) ;
testbitmap.address:=i;testbitmap.w:=2048; testbitmap.l:=2048;
retromalina.outtextxyz(0,0,inttohex(i,8),44,3,3);
texaddr:=i;
glwindow.destroy;


glGenTextures(1, @texture1);
glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, texture1); 	// color palette
glTexImage2D(GL_TEXTURE_2D, 0, GL_BGRA, 256, 1, 0, GL_BGRA, GL_UNSIGNED_BYTE, @pallette);



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
fov:=30.0;
h:=tan(2*pi*fov/360)*n;
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
basetime:=gettime;
end;


procedure shader_draw;

// The procedure draws a sphere and a cube lighted by a light source


const angle1:glfloat=0;
      angle2:glfloat=0;
      angle3:glfloat=0;
      angle4:glfloat=0;
      angle5:glfloat=0;
      angle6:glfloat=0;
      speed:integer=1;

var modelviewmat2:matrix4;
    tscale:array[0..1] of glfloat=(1.0,1.0);
    tdelta:array[0..1] of glfloat=(0.0,0.0);
    i,j:integer;
    tttt:int64;

begin
tttt:=gettime;
glUniform1f(u_itime,(tttt-basetime)/1000000);
//for j:=1 to 2 do begin
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);    // clear the scene

//tscale[0]:=64/2048;
//tscale[1]:=256/2048;
//tdelta[0]:=0;
//tdelta[1]:=0;
//g/luniform2fv(u_scale,1,@tscale);
//gluniform2fv(u_delta,1,@tdelta);

// A moving light source

//angle5+=0.05*speed;
//if angle5>360 then angle5:=0;
//lightsourcemat:=translate(matrix4_one,25,0.1,0);
//lightsourcemat:=rotate(lightsourcemat,0,1,0,angle5);
//lightsourcemat:=translate(lightsourcemat,0,0,-5);

// ------------------- Draw a cube --------------------------------------------

// compute rotate angles
//angle1+=1.11*speed;
//if angle1>360 then angle1-=360;
//angle2+=0.82*speed;
//if angle2>360 then angle2-=360;

// transform the model

// A transform matrix for lighting. As it will transform normals only
// the scale and translate transforms are omitted

//lightmat:=rotate(modelviewmat,1.0,-0.374,-0.608,angle1);
//lightmat:=rotate(lightmat,0,1,0,angle2);

//modelviewmat2:=scale(modelviewmat,0.5,0.5,0.5);                  // reduce size
//modelviewmat2:=rotate(modelviewmat2,1.0,-0.374,-0.608,angle1);   // rotate (around the axis)
//modelviewmat2:=translate(modelviewmat2,0,0,-3);                  // move 3 units into the screen
//modelviewmat2:=rotate(modelviewmat2,0,1,-0,angle2);              // rotate again, now all modell will rotate around the center of the scene
//modelviewmat2:=translate(modelviewmat2,0,0,-5);                  // push it 5 units again or you will not see it
//mvmat:=modelviewmat2;                                            // todo: moving camera
//mvpmat:=projectionmat*mvmat;
//glUniformMatrix4fv(mvpLoc,1,GL_FALSE,@mvpMat);
//glUniformMatrix4fv(lightLoc,1,GL_FALSE,@lightMat);
//glUniformMatrix4fv(mvLoc,1,GL_FALSE,@mvMat);
//glUniformMatrix4fv(lightsourceLoc,1,GL_FALSE,@lightsourceMat);

//UVs for the texture
glBindBuffer(GL_ARRAY_BUFFER,texcoordID);
glBufferData(GL_ARRAY_BUFFER, sizeof(uvs), @uvs[0], GL_dynamic_DRAW);

//Vertices
glBindBuffer(GL_ARRAY_BUFFER,vertexID);
glBufferData(GL_ARRAY_BUFFER,SizeOf(Vertices),@Vertices,GL_DYNAMIC_DRAW);

//Normals
//glBindBuffer(GL_ARRAY_BUFFER,normalID);
//glBufferData(GL_ARRAY_BUFFER,SizeOf(Normals),@normals,GL_DYNAMIC_DRAW);

// Draw it
glDrawArrays(GL_TRIANGLES,0,6);


// Update the texture

//testbitmap.box(0,0,128,128,40);
//testbitmap.box(0,128,128,128,120);
//testbitmap.box(128,0,128,128,200);
//testbitmap.box(128,128,128,128,232);
//testbitmap.outtextxyz(0,frames mod 208,' Frame# '+inttostr(frames),(frames div 16) mod 256,2,2);
//cleandatacacherange(testbitmap.address,131072*32);
eglSwapBuffers(Display,Surface);

frames+=1;

//if frames=60 then begin
//for i:=16 to 16383 do poke(texaddr+i,255);
//cleandatacacherange(texaddr,16384);
//;
//if frames=128 then begin
//i:=$30000000; repeat i:=i+4 until ((dpeek(i)=$4b4b) and (dpeek(i+4)=$4343) and (dpeek(i+8)=$5555) and (dpeek(i+12)=$4646) and (dpeek(i+128)=$FFFF) and (i<>texaddr)) or (i>$3F000000) ;
//retromalina.outtextxyz(0,100,inttohex(i,8),202,3,3);

end;

procedure shader_cleanup;

var

 Success:Integer;
 DispmanUpdate:DISPMANX_UPDATE_HANDLE_T;

 i:integer;
begin




// Delete the OpenGL ES buffers
glDeleteBuffers(1,@vertexID);
glDeleteBuffers(1,@colorID);

//Delete the OpenGL ES program
glDeleteProgram(programID);

//Destroy the EGL surface
eglDestroySurface(Display,Surface);
sleep(1000);
//Remove the dispmanx layer

//  test: fill the dispmanx



while keypressed do readkey;
repeat until keypressed;

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

procedure shadertest_start;

begin
BCMHostInit;
shader_init;
shader_prepare;
while keypressed do readkey;
repeat shader_draw until keypressed;
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

