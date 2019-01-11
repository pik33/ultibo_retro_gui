unit SimpleGL;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gles20, retromalina, retro;

type Pmatrix4=^matrix4;
     matrix4=array[0..3,0..3] of glfloat;
type vector4=array[0..3] of glfloat;
type vector3=array[0..2] of glfloat;
type vector2=array[0..1] of glfloat;

const matrix4_zero:matrix4=((0,0,0,0),(0,0,0,0),(0,0,0,0),(0,0,0,0));
const matrix4_one:matrix4=((1,0,0,0),(0,1,0,0),(0,0,1,0),(0,0,0,1));

const precision=40;  // for a sphere generator
const svertex=2*precision*(precision+1); // vertices count for sphere

var vertices1,vertices2: array[0..svertex-1] of vector3; //sphere generator vars
    suvs,suvs2:array[0..svertex-1] of vector2;
    snormals,snormals2:array[0..svertex-1] of vector3;


operator +(a,b:matrix4):matrix4;
operator *(a,b:matrix4):matrix4;


type TTexturebitmap=object     // test!!
   address:cardinal;
   w,l:integer;
   procedure putpixel(x,y:cardinal;color:byte);
   procedure box(x,y,l1,h:cardinal;c:byte);
   procedure putchar(x,y:integer;ch:char;col:integer);
   procedure putcharz(x,y:integer;ch:char;col,xz,yz:integer);
   procedure outtextxy(x,y:integer; t:string;c:integer);
   procedure outtextxyz(x,y:integer; t:string;c,xz,yz:integer);
   end;


     //TODO: generic 3D object class
     //type T3dflavor=(cube,tetrahedron,octahedron,dodecahedron,icosahedron,sphere,custom);

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


procedure makesphere(precision:integer);

implementation

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

procedure TTexturebitmap.putpixel(x,y:cardinal;color:byte);  // test procedure

// for 2048x2048 32bit

var  aa:cardinal;
 //    debug1:cardinal;

begin
aa:=address;

       asm
       ldr r0,x
       ldr r1,y
       and r2,r0,#0b00001111
       and r3,r0,#0b00110000
       orr r2,r2,r3,lsl #2
       and r3,r1,#0b00000011
       orr r2,r2,r3,lsl #4               //a

       and r3,r1,#0b00001100
       orr r2,r2,r3,lsl #6               // 10 bits in r2

       and r3,r0,#0b01000000
       and r4,r1,#0b00010000
       eor r4,r4,r3,lsr #2
       orr r2,r2,r4,lsl #6              // bit 11 - xor

       mov r3,r0,lsl #5
       tst r1,#0b00100000
       mvnne r3,r3
       and r3,#0b111111100000000000
       orr r2,r3

       and r3,r1,#0b11111100000
       orr r2,r2,r3,lsl #13
       ldr r3,aa
       add r2,r3
       ldrb r3,color
       strb r3,[r2]

       end  ['R0','R1','R2','R3','R4']    ;


end;


procedure TTexturebitmap.box(x,y,l1,h:cardinal;c:byte);

label p101,p102,p999;

var i,j:cardinal;

begin

for i:=x to x+l1-1 do
  for j:=y to y+h-1 do
    putpixel(i,j,c);
//cleandatacacherange(address+131072*(y div 16),131072*(2+l1 div 16));
end;


//  ---------------------------------------------------------------------
//   putchar(x,y,ch,color)
//   Draw a 8x16 character at position (x1,y1)
//   rev. 20190111
//  ---------------------------------------------------------------------

procedure TTexturebitmap.putchar(x,y:integer;ch:char;col:integer);

var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      putpixel(x+j,y+i,col);
    end;
  end;
end;

procedure TTexturebitmap.putcharz(x,y:integer;ch:char;col,xz,yz:integer);

// --- TODO: translate to asm, use system variables

var i,j,k,ll:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      for k:=0 to yz-1 do
        for ll:=0 to xz-1 do
           putpixel(x+j*xz+ll,y+i*yz+k,col);
    end;
  end;
end;

procedure TTexturebitmap.outtextxy(x,y:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(x+8*i-8,y,t[i],c);
end;

procedure TTexturebitmap.outtextxyz(x,y:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(x+8*xz*i,y,t[i+1],c,xz,yz);
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



end.

