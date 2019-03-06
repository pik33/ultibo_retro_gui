unit camera2;

// A sandbox for picture filtering and recognition
// pik33@o2.pl
// gpl >=2.0
// 20181230

{$mode objfpc}{$H+}

interface

uses
  classes,sysutils, threads,
  retromalina, mwindows, blitter, retro, platform, camera, simpleaudio;

type TCameraThread2=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


type TPAThread2=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;

const cxres=640;
      cyres=480;
      cframerate=60;

type cbuffer=array[0..cxres*cyres-1] of byte;
type cbufferl=array[0..(cxres*cyres div 4)-1] of cardinal;
type cbuffer2=array[0..2*cxres*cyres-1] of byte;

type TPoint=array[0..4] of integer;                           //x,y,diameter,brightness
     TMinMaxPoint=array[0..3] of integer;

var camerathread2:TCameraThread2;
    PAthread2:TPAThread2;
      cmw2:pointer=nil;
      camerawindow2:TWindow=nil;
      rendertestwindow2:TWindow=nil;
      miniwindow2:TWindow=nil;
      at,at1,at2,at3,at4,t1,t2,t3,t4:int64;
      testbuf1, testbuf2, testbuf3, testbuf4: cbuffer;
      tb4l:cbufferl absolute testbuf4;
      s1:integer=0;
      nFrames:cardinal=0;
      camerabuffer:cbuffer2;
      points:array[0..3900] of TPoint;
      pointnum:integer=0;
      i,j,k,l,m:integer;
      processed:boolean=false;

  const maxpoint=6;

  var   points1: array[0..4*maxpoint-1] of integer;
        points1a:array[0..maxpoint-1] of TMinMaxPoint absolute points1;
//        points2: array[0..6*maxpoint-1] of integer;
        points2a:array[0..maxpoint-1] of TPoint; // absolute points2;
        points3: array[0..maxpoint-1] of TPoint;

        maxpoint3:integer=0;
        brightness:integer=0;

procedure diff(b1,b2,b3,count:cardinal);
procedure diff2(b1,b2,b3,count,t:cardinal);
procedure diff3(b1,b2,b3,count,t:cardinal);
procedure diff4(b1,b2,b3,count,t:cardinal);
procedure scale4(from,too,length,bpl:integer);
procedure scale4c(from,too,lines,bpl:integer);
procedure scale4b(from,too,length,bpl:integer);
procedure blur2(b1,b2,count:integer);
procedure blur3u(b1,b2,count:cardinal);
procedure blur3(b1,b2,count:cardinal);
procedure blur3v(b1,b2,count:cardinal);
function findpoints2(b1,b2,count:integer):integer;
function avg(b1,count:cardinal):cardinal;
function fmax(b1,count:cardinal):cardinal;


implementation

uses playerunit; // for sprites :)

constructor TPAThread2.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

constructor TCameraThread2.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);

end;

procedure TPAThread2.execute;

// todo @20181230
// persistent found points list
// check if point active using unprocessed image; if not active, delete it from the list
// attach new points to the old list; if move<delta, updae point else create new one.

label p101,p102,p103,p104, p105;

const delta=72;  // max distance
      delta2=48; // min brightness

var td:int64;
    td2:int64=0;
    i,j,k:integer;
    p:integer;
    maxx,minx,maxy,miny,xx,yy:integer;
    tf:textfile;
    n:integer=1;
    d1,d2,d:integer;
        average:cardinal;

// the thread detects light spots

begin
at1:=0;
ThreadSetpriority(ThreadGetCurrent,5);
threadsleep(1);
prepare_sprites;
for i:=0 to maxpoint-1 do for j:=0 to 3 do points3[i,j]:=0;
repeat
  repeat threadsleep(1) until processed or terminated;
  processed:=false;
  if n<180 then goto p104;    // wait 3 seconds to establish the background picture

  SchedulerPreemptDisable(CPUGetCurrent);
  pointnum:=findpoints2(cardinal(miniwindow2.canvas),cardinal(@testbuf4),cxres*cyres) ;
  SchedulerPreemptEnable(CPUGetCurrent);

  if pointnum=0 then begin     box(0,200,200,200,80);  goto p104; end;  //no points found, nothing to do

  for i:=0 to maxpoint-1 do       // clear the temporary table
    begin
    points1a[i][0]:=32767; //minx
    points1a[i][1]:=-1;    //maxx
    points1a[i][2]:=32767; //miny
    points1a[i][3]:=-1;    //maxy
    points2a[i][0]:=-1;
    points2a[i][1]:=-1;
    end;

  for i:=0 to pointnum-1 do
    begin
    xx:=tb4l[i] mod 640;                    // compute x,y from the address
    yy:=tb4l[i] div 640;                    // todo: use xres, yres instead of consts
    p:=0;

p101:

    if points2a[p][0]<>-1 then              // the point is in the table
      begin
      if (xx>points1a[p][0]-6)
       and (xx<points1a[p][1]+6)
        and (yy>points1a[p][2]-6)
         and (yy<points1a[p][3]+6) then   // the pixel belongs to the point

        begin
        if xx<points1a[p][0] then points1a[p][0]:=xx          // update min and max values for the point
        else if xx>points1a[p][1] then points1a[p][1]:=xx;
        if yy<points1a[p][2] then points1a[p][2]:=yy
        else if yy>points1a[p][3] then points1a[p][3]:=yy;
        end

      else                      //  the pixel doesn't belong to point #p
        begin
        p+=1;                   //  check the next point or end the process if max number of allowed points reached
        if p<maxpoint then goto p101 else goto p102;
        end;
      end
    else                        // We are here if the pixel doesn't belong to any existent pointa and the max point number is not reached
      begin                   // so we have to add a new point to the list
      points1a[p][0]:=xx;
      points1a[p][1]:=xx;
      points1a[p][2]:=yy;
      points1a[p][3]:=yy;
      points2a[p][0]:=xx;
      points2a[p][1]:=yy;
      end;

p102:
    end;

// now compute position and diameter of found points
  p:=0;
  for i:=0 to maxpoint-1 do
    begin
    if points2a[i][1]>-1 then
      begin
      p+=1;
      d1:=points1a[i,1]-points1a[i,0];
      d2:=points1a[i,3]-points1a[i,2];
      d:=(d1+d2) div 2;
      xx:=(points1a[i][0]+points1a[i][1]) div 2;
      yy:=(points1a[i][2]+points1a[i][3]) div 2;
      points2a[i][0]:=xx;
      points2a[i][1]:=yy;
      points2a[i][2]:=d;
      points2a[i][3]:=testbuf3[xx+640*yy];
      end;
    end;

  if p>0 then for i:=0 to p-1 do
    begin

  // check if the point is in the table

    if maxpoint3=0 then // no points in the table
      begin
      points3[0]:=points2a[i];
      maxpoint3:=1;
      goto p103;
      end;
    for j:=0 to maxpoint3-1 do
      begin
      if (abs(points3[j,0]-points2a[i,0])<delta) and (abs(points3[j,1]-points2a[i,1])<delta) then // point found
        begin
        points3[j]:=points2a[i];
        goto p103
        end;
      end;
                                               // if we are here, no existing point found
    if maxpoint3=maxpoint then goto p103; // no place for new points
    points3[maxpoint3]:=points2a[i];
    maxpoint3+=1;
                                             // add a point
p103:
    end;





p104:

  if n<180 then camerawindow2.println(inttostr(n));
  n+=1;


  // we have to control all points and remove if not active.
    if maxpoint3>0 then
       for j:=0 to maxpoint3-1 do
         begin
         if testbuf3[640*points3[j,1]+points3[j,0]]<delta2 then //delete a point
           begin
           for k:=j to maxpoint3-1 do points3[k]:=points3[k+1];
           for k:=0 to 3 do points3[maxpoint3-1,k]:=0;
           maxpoint3-=1;
           goto p105 // one point at once
           end;
         end;
  // display the points
 p105:

  if maxpoint3>0 then begin
  box(0,0,300,200,0);
  for j:=0 to maxpoint3-1 do outtextxy(0,j*16,inttostr(j)+' '+inttostr(points3[j,0])+' '+inttostr(points3[j,1])+' '+inttostr(points3[j,2])+' '+inttostr(points3[j,3])+' '+inttostr(testbuf3[640*points3[j,1]+points3[j,0]]),255);
  outtextxy(0,180,inttostr(maxpoint3),255);
  outtextxy(0,160,inttostr(p),255);
  end else box(0,0,300,200,80);

    for i:=0 to maxpoint3-1 do
      begin
      d:=points3[i][2];
      dpoke(base+_spritebase+8*i,miniwindow2.x-32+points3[i][0]);
      dpoke(base+_spritebase+8*i+2,miniwindow2.y-32+points3[i][1]);
      end;
    for i:=maxpoint3 to 6 do
      begin
      dpoke(base+_spritebase+8*i,2048);
      dpoke(base+_spritebase+8*i+2,2048);
      end;
//  led brightness autocontrol

  average:=fmax(cardinal(@testbuf3),cxres*cyres);
  if average<180 then brightness+=1;
  if average>190 then brightness-=1;
  if brightness>1024 then brightness:=1024 ;
  if brightness<16 then brightness:=16;
  setpwm(0,brightness);

until terminated;
camerawindow2.println('PAThread terminating;');
//closefile(tf);
end;

procedure TCameraThread2.execute;

label p999,p998;

const maxframe=360000;  //1 minute

var frames2:integer;
    buffer:cardinal;


begin
ThreadSetpriority(ThreadGetCurrent,6);
threadsleep(1);
at1:=0; at2:=0; at3:=0; at4:=0;
setpallette(grayscalepallette,0);
  if camerawindow2=nil then
    begin
    camerawindow2:=TWindow.create(480,600,'Camera log 2');
    camerawindow2.decoration.hscroll:=true;
    camerawindow2.decoration.vscroll:=true;
    camerawindow2.resizable:=true;
    camerawindow2.cls(0);
    camerawindow2.tc:=252;
    camerawindow2.move(1200,64,480,600,0,0);
    cmw2:=camerawindow2;
    end
  else goto p999;
  if rendertestwindow2=nil then
    begin
    rendertestwindow2:=TWindow.create(cxres,cyres,'Camera render');
    rendertestwindow2.decoration.hscroll:=false;
    rendertestwindow2.decoration.vscroll:=false;
    rendertestwindow2.resizable:=true;
    rendertestwindow2.cls(0);
    rendertestwindow2.tc:=15;
    rendertestwindow2.move(500,400,cxres,cyres,0,0);
    end;
  if miniwindow2=nil then
    begin
    miniwindow2:=TWindow.create(cxres,cyres,'Camera processed');
    miniwindow2.decoration.hscroll:=false;
    miniwindow2.decoration.vscroll:=false;
    miniwindow2.resizable:=true;
    miniwindow2.cls(0);
    miniwindow2.tc:=15;
    miniwindow2.move(100,100,cxres,cyres,0,0);
    end;

buffer:=initcamera(640,480,60,cardinal(@camerabuffer));
camerawindow2.println ('----- Camera buffer at '+inttohex(buffer,8));
if buffer<$C0000000 then goto p999;
initpwm(1000,1024);
sleep(10);
setpwm(0, brightness);
startcamera;
while keypressed do readkey;
for frames2:=1 to maxframe do
  begin
  repeat threadsleep(1) until filled;
  filled:=false;
//  SchedulerPreemptDisable(CPUGetCurrent);
//  t1:=gettime;
  blur3 (cardinal(@camerabuffer),cardinal(@testbuf1),cyres*cxres) ;
//  t1:=gettime-t1; at1+=t1;
//  t2:=gettime;
  blur3v(cardinal(@testbuf1),cardinal(@testbuf3),cxres*cyres);
//  t2:=gettime-t2;  at2+=t2;
//  t3:=gettime;
  diff4(cardinal(@testbuf3), cardinal(@testbuf2), cardinal(miniwindow2.canvas),cxres*cyres,32);
    processed:=true;

//  box(0,500,200,50,34);
//  outtextxy(0,500,inttostr(average),104);

//  t3:=gettime-t3;  at3+=t3;
//  t4:=gettime;
  fastmove(cardinal(@camerabuffer),cardinal(rendertestwindow2.canvas), cxres*cyres);
//  t4:=gettime-t4;  at4+=t4;
//  SchedulerPreemptenable(CPUGetCurrent);
//  box(0,0,100,100,0); outtextxy(0,0,inttostr(at1 div frames),255); outtextxy(0,20,inttostr(at2 div frames),255); outtextxy(0,40,inttostr(at3 div frames),255);outtextxy(0,60,inttostr(at4 div frames),255);
  if keypressed then goto p998;
  end;

p998:
ThreadSetpriority(ThreadGetCurrent,1);
threadsleep(1);
stopcamera;
camerawindow2.println ('----- Camera stopped ');
camerawindow2.println ('----- Main loop ended ');
setpallette(ataripallette,0);
repeat threadsleep(100) until camerawindow2.needclose;
camerawindow2.println ('----- Close button clicked ');

p999:
destroycamera;
camerawindow2.println ('----- Camera destroyed ');
setpallette(ataripallette,0);
rendertestwindow2.destroy;
rendertestwindow2:=nil;
camerawindow2.println ('----- render window destroyed ');
cmw2:=nil;
PAThread2.terminate;
PAThread2.destroy;
miniwindow2.destroy;
miniwindow2:=nil;
camerawindow2.println ('----- mini window destroyed ');
threadsleep(2000);
camerawindow2.destroy;
camerawindow2:=nil;
threadsleep(100);
end;


procedure diff(b1,b2,b3,count:cardinal);

// --- rev 20181226
// --- create differential picture from 2 frames
// --- b1 - input buffer1 address
// --- b2 - input buffer2 address
// --- b3 - output buffer address
// --- count - pixel count
// --- output pixel:=abs(input pixel 1 - inpput pixel 2)

label p101;

begin

                  asm
                  push {r0-r6}
                  ldr r0,b1
                  ldr r1,b2
                  ldr r2,b3
                  ldr r3,count


p101:             ldrb r4,[r0],#1
                  ldrb r5,[r1],#1

                  cmps r4,r5
                  subge r6,r4,r5
                  sublt r6,r5,r4
                  strb r6,[r2],#1

                  subs r3,#1
                  bgt  p101
                  pop {r0-r6}
                  end;
end;


procedure diff2(b1,b2,b3,count,t:cardinal);

// --- rev 20181226
// --- create differential picture from 2 frames
// --- b1 - input buffer1 address
// --- b2 - input buffer2 address
// --- b3 - output buffer address
// --- count - pixel count
// --- t - threshold
// --- difference:=abs(input pixel 1 - inpput pixel 2)
// --- if difference<threshold then result:=0 else result:=difference
// --- output pixel:=result

label p101;

begin
                  asm
                  push {r0-r8}
                  ldr r0,b1
                  ldr r1,b2
                  ldr r2,b3
                  ldr r3,count
                  ldr r8,t
                  mov r7,#0

p101:             ldrb r4,[r0],#1
                  ldrb r5,[r1],#1

                  cmps r4,r5
                  subge r6,r4,r5
                  sublt r6,r5,r4
                  cmps r6,r8
                  movlt r4,#0
                  strb r4,[r2],#1

                  subs r3,#1
                  bgt  p101
                  pop {r0-r8}
                  end;
end;

procedure diff3(b1,b2,b3,count,t:cardinal);

 // --- rev 20181226
 // --- create differential picture from 2 frames
 // --- b1 - input buffer1 address
 // --- b2 - input buffer2 address
 // --- b3 - output buffer address
 // --- count - pixel count
 // --- t - threshold
 // --- difference:=abs(input pixel 1 - inpput pixel 2)
 // --- if difference<threshold then result:=0 else result:=255
 // --- output pixel:=result


label p101;

begin

                  asm
                  push {r0-r8}
                  ldr r0,b1
                  ldr r1,b2
                  ldr r2,b3
                  ldr r3,count
                  ldr r8,t
                  mov r7,#0

p101:             ldrb r4,[r0],#1
                  ldrb r5,[r1],#1

                  cmps r4,r5
                  subge r6,r4,r5
                  sublt r6,r5,r4
                  cmps r6,r8
                  movge r4,#255
                  movlt r4,#0
                  strb r4,[r2],#1

                  subs r3,#1
                  bgt  p101
                  pop {r0-r8}
                  end;
end;

procedure diff4(b1,b2,b3,count,t:cardinal);

// This procedure gets new frames in b1
// then computes moving average in b2
// and compute difference between new b2 and b1.
// If the difference>threshold, result:=255 else result:=0

// --- rev 20181226
// --- create differential picture from 2 frames
// --- b1 - input buffer1 address
// --- b2 - background (average) buffer address, init it to all zeros at the start of the program
// --- b3 - output buffer address
// --- count - pixel count
// --- t - threshold
// --- pixel in b2:=(7*old pixel in b2+pixel in b1) div 8
// --- difference:=abs(input pixel 1 - input pixel 2)
// --- if difference<threshold then result:=0 else result:=255
// --- output pixel:=result

label p101;

begin

                 asm
                 push {r0-r8}
                 ldr r0,b1
                 ldr r1,b2
                 ldr r2,b3
                 ldr r3,count
                 ldr r8,t
                 mov r7,#0

p101:            ldrb r4,[r0],#1
                 ldrb r5,[r1]
                 add r6,r5,r5,lsl #1
                 add r6,r6,r5,lsl #2
                 add r6,r6,r5,lsl #3
                 add r6,r4
                 lsr r6,#4
                 strb r6,[r1],#1
                 sub r6,r4,r5
                 cmps r6,r8
                 movge r4,#255
                 movlt r4,#0
                 strb r4,[r2],#1

                 subs r3,#1
                 bgt  p101
                 pop {r0-r8}
                 end;
end;


procedure scale4(from,too,length,bpl:integer);

// --- rev 20181230
// Shrink the picture 4:1 using 4x4 pixel average
// Not optimized!

label p101,p102,p999;
var lines:integer;

begin
lines:=(length div bpl) div 4;

                  asm
                  push {r0-r12}
                  ldr r0,from
                  ldr r1,too
                  ldr r2,lines
                  ldr r3,bpl

p102:             mov r7,r3

p101:             mov r12,#0
                  ldrb r6,[r0],#1
                  ldrb r8,[r0],#1
                  ldrb r9,[r0],#1
                  ldrb r10,[r0],#-3
                  add r6,r8
                  add r9,r10
                  add r12,r9,r6
                  mov r4,r12

                  add r0,r3
                  ldrb r6,[r0],#1
                  ldrb r8,[r0],#1
                  ldrb r9,[r0],#1
                  ldrb r10,[r0],#-3
                  add r6,r8
                  add r9,r10
                  add r12,r9,r6
                  add r4,r12

                  add r0,r3
                  ldrb r6,[r0],#1
                  ldrb r8,[r0],#1
                  ldrb r9,[r0],#1
                  ldrb r10,[r0],#-3
                  add r6,r8
                  add r9,r10
                  add r12,r9,r6
                  add r4,r12

                  add r0,r3
                  ldrb r6,[r0],#1
                  ldrb r8,[r0],#1
                  ldrb r9,[r0],#1
                  ldrb r10,[r0],#1
                  add r6,r8
                  add r9,r10
                  add r12,r9,r6
                  add r4,r12

                  sub r0,r3
                  sub r0,r3
                  sub r0,r3

                  lsr r4,#4

                  strb r4,[r1],#1

                  subs r7,#4
                  bgt  p101

                  add r0,r0,r3
                  add r0,r0,r3
                  add r0,r0,r3

                  subs r2,#1
                  bgt p102
                  pop {r0-r12}
                  end;
p999:
end;


procedure scale4c(from,too,lines,bpl:integer);

// --- rev 20181230
// --- shrink the picture 4:1 without any averaging

label p101,p102;

begin

                  asm
                  push {r0-r12}
                  ldr r0,from
                  ldr r1,too
                  ldr r2,lines
                  ldr r3,bpl

p102:             mov r7,r3

p101:             mov r12,#0

                  ldrb r6,[r0],#4
                  strb r6,[r1],#1

                  subs r7,#4
                  bgt  p101

                  add r0,r0,r3
                  add r0,r0,r3
                  add r0,r0,r3

                  subs r2,#1
                  bgt p102
                  pop {r0-r12}
                  end;
end;



procedure scale4b(from,too,length,bpl:integer);

// --- rev 20181013
// USAD8 can help here!

label p101,p102,p999, p998, p997, temp1,temp2,temp3;

var lines:integer;

begin
lines:=(length div bpl) div 4;

                  asm
                  push {r0-r12,r14}
                  ldr r0,from
                  ldr r1,too
                  ldr r2,lines
                  ldr r3,bpl

p102:             mov r14,r3

p101:             ldm r0,{r4-r7}  // 16 pixels

                  mov r8,r4,  lsr #8
                  mov r9,r4,  lsr #16
                  mov r10,r4, lsr #24
                  and r4,#0xFF
                  and r8,#0xFF00
                  and r9,#0xFF0000
                  orr r4,r8
                  orr r9,r10
                  orr r12,r9,r4        // 4 pixels sum in r12, r4 free

                  mov r8,r5,  lsr #8
                  mov r9,r5,  lsr #16
                  mov r10,r5, lsr #24
                  and r5,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r5,r8
                  add r9,r10
                  mov r4,#0
                  add r4,r9,r5       // 4 pixels sum in r4, r5 free

                  mov r8,r6,  lsr #8
                  mov r9,r6,  lsr #16
                  mov r10,r6, lsr #24
                  and r6,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r6,r8
                  add r9,r10
                  mov r5,#0
                  add r5,r9,r6    // 4 pixels sum in r5, r6 free

                  mov r8,r7,  lsr #8
                  mov r9,r7,  lsr #16
                  mov r10,r7, lsr #24
                  and r7,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r7,r8
                  add r9,r10
                  mov r5,#0
                  add r6,r9,r7    // 4 pixels sum in r6, r7 free

                  lsr r12,#2
                  lsr r4,#2
                  lsr r5,#2
                  lsr r6,#2

                  add r12,r12,r4,lsl #8
                  add r12,r12,r5,lsl #16
                  add r12,r12,r6,lsl #24 // 4 pixels in r12


                  str r12,temp1

                  // line #2

                  add r0,r3


                  ldm r0,{r4-r7}  // 16 pixels
                  mov r12,#0


                  mov r8,r4,  lsr #8
                  mov r9,r4,  lsr #16
                  mov r10,r4, lsr #24
                  and r4,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r4,r8
                  add r9,r10
                  add r12,r9,r4        // 4 pixels sum in r12, r4 free

                  mov r8,r5,  lsr #8
                  mov r9,r5,  lsr #16
                  mov r10,r5, lsr #24
                  and r5,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r5,r8
                  add r9,r10
                  mov r4,#0
                  add r4,r9,r5       // 4 pixels sum in r4, r5 free

                  mov r8,r6,  lsr #8
                  mov r9,r6,  lsr #16
                  mov r10,r6, lsr #24
                  and r6,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r6,r8
                  add r9,r10
                  mov r5,#0
                  add r5,r9,r6    // 4 pixels sum in r5, r6 free

                  mov r8,r7,  lsr #8
                  mov r9,r7,  lsr #16
                  mov r10,r7, lsr #24
                  and r7,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r7,r8
                  add r9,r10
                  mov r5,#0
                  add r6,r9,r7    // 4 pixels sum in r6, r7 free

                  lsr r12,#2
                  lsr r4,#2
                  lsr r5,#2
                  lsr r6,#2

                  add r12,r12,r4,lsl #8
                  add r12,r12,r5,lsl #16
                  add r12,r12,r6,lsl #24 // 4 pixels in r12


                  str r12,temp2



                  // line #3

                  add r0,r3

                  ldm r0,{r4-r7}  // 16 pixels
                  mov r12,#0

                  mov r8,r4,  lsr #8
                  mov r9,r4,  lsr #16
                  mov r10,r4, lsr #24
                  and r4,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r4,r8
                  add r9,r10
                  add r12,r9,r4        // 4 pixels sum in r12, r4 free

                  mov r8,r5,  lsr #8
                  mov r9,r5,  lsr #16
                  mov r10,r5, lsr #24
                  and r5,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r5,r8
                  add r9,r10
                  mov r4,#0
                  add r4,r9,r5       // 4 pixels sum in r4, r5 free

                  mov r8,r6,  lsr #8
                  mov r9,r6,  lsr #16
                  mov r10,r6, lsr #24
                  and r6,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r6,r8
                  add r9,r10
                  mov r5,#0
                  add r5,r9,r6    // 4 pixels sum in r5, r6 free

                  mov r8,r7,  lsr #8
                  mov r9,r7,  lsr #16
                  mov r10,r7, lsr #24
                  and r7,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r7,r8
                  add r9,r10
                  mov r5,#0
                  add r6,r9,r7    // 4 pixels sum in r6, r7 free

                  lsr r12,#2
                  lsr r4,#2
                  lsr r5,#2
                  lsr r6,#2

                  add r12,r12,r4,lsl #8
                  add r12,r12,r5,lsl #16
                  add r12,r12,r6,lsl #24 // 4 pixels in r12


                  str r12,temp3


                  // line #4

                  add r0,r3

                  ldm r0!,{r4-r7}  // 16 pixels
                  mov r12,#0

                  mov r8,r4,  lsr #8
                  mov r9,r4,  lsr #16
                  mov r10,r4, lsr #24
                  and r4,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r4,r8
                  add r9,r10
                  add r12,r9,r4        // 4 pixels sum in r12, r4 free

                  mov r8,r5,  lsr #8
                  mov r9,r5,  lsr #16
                  mov r10,r5, lsr #24
                  and r5,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r5,r8
                  add r9,r10
                  mov r4,#0
                  add r4,r9,r5       // 4 pixels sum in r4, r5 free

                  mov r8,r6,  lsr #8
                  mov r9,r6,  lsr #16
                  mov r10,r6, lsr #24
                  and r6,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r6,r8
                  add r9,r10
                  mov r5,#0
                  add r5,r9,r6    // 4 pixels sum in r5, r6 free
                  mov r8,r7,  lsr #8
                  mov r9,r7,  lsr #16
                  mov r10,r7, lsr #24
                  and r7,#0xFF
                  and r8,#0xFF
                  and r9,#0xFF
                  add r7,r8
                  add r9,r10
                  mov r5,#0
                  add r6,r9,r7    // 4 pixels sum in r6, r7 free

                  lsr r12,#2
                  lsr r4,#2
                  lsr r5,#2
                  lsr r6,#2

                  add r12,r12,r4,lsl #8
                  add r12,r12,r5,lsl #16
                  add r12,r12,r6,lsl #24 // 4 pixels in r12


                  sub r0,r3
                  sub r0,r3
                  sub r0,r3


                  mov r4,r12
                  mov r5,r12,lsr #8
                  mov r6,r12,lsr #16
                  mov r7,r12,lsr #24
                  and r4,#0xFF
                  and r5,#0xFF
                  and r6,#0xFF

                  ldr r12,temp1

                  mov r9,r12
                  mov r10,r12,lsr #8
                  and r9,#0xff
                  and r10,#0xff
                  add r4,r9
                  and r5,r10
                  mov r9,r12,lsr #16
                  mov r10,r12,lsr #24
                  and r9,#0xff
                  and r10,#0xff
                  add r6,r9
                  and r7,r10

                  ldr r12,temp2

                  mov r9,r12
                  mov r10,r12,lsr #8
                  and r9,#0xff
                  and r10,#0xff
                  add r4,r9
                  and r5,r10
                  mov r9,r12,lsr #16
                  mov r10,r12,lsr #24
                  and r9,#0xff
                  and r10,#0xff
                  add r6,r9
                  and r7,r10

                  ldr r12,temp3

                  mov r9,r12
                  mov r10,r12,lsr #8
                  and r9,#0xff
                  and r10,#0xff
                  add r4,r9
                  and r5,r10
                  mov r9,r12,lsr #16
                  mov r10,r12,lsr #24
                  and r9,#0xff
                  and r10,#0xff
                  add r6,r9
                  and r7,r10

                  lsr r4,#2
                  lsr r5,#2
                  lsr r6,#2
                  lsr r7,#2


                  add r4,r4,r5,lsl #8
                  add r4,r4,r6,lsl #16
                  add r4,r4,r7,lsl #24


p997:
                ldr r4,temp1

                  str r4,[r1],#4

                  subs r14,#16
                  bgt  p101

                 add r0,r0,r3
                 add r0,r0,r3
                 add r0,r0,r3

                  subs r2,#1
                  bgt p102
                  b p998


temp1:            .long 0
temp2:            .long 0
temp3:            .long 0

p998:
                  pop {r0-r12,r14}
                  end;
p999:
end;



procedure blur2(b1,b2,count:integer);

// 4x2 pixel averaging
// rev 20181230

label p101;

begin


                 asm
                 push {r0-r12}
                 ldr r0,b1
                 ldr r1,b2
                 ldr r2,count
                 mov r3,#640 // todo - line count
                 mov r4,#0
                 mov r5,#0
                 mov r6,#0
                 mov r7,#0
                 mov r8,#0
                 mov r9,#0
                 mov r10,#0
                 mov r12,#0

p101:            add r12,r10
                 add r12,r9
                 add r12,r8
                 add r12,r7
                 add r12,r6
                 ldrb r5,[r0,r3]
                 add r12,r5
                 ldrb r4,[r0],#1
                 add r12,r4
                 lsr r12,#2
                 strb r12,[r1],#1
                 mov r12,r9
                 mov r10,r8
                 mov r9,r7
                 mov r8,r6
                 mov r7,r5
                 mov r6,r4
                 subs r2,#1
                 bne p101

                 pop {r0-r12}
                 end;


end;


procedure blur3u(b1,b2,count:cardinal);

label p101;

// Make an average of 8 pixels using USAD8 instruction
// rev 20181230

begin


                 asm
                 push {r0-r12,r14}
                 ldr r0,b1
                 ldr r1,b2
                 ldr r2,count
                 mov r3,#0
                 mov r4,#0
                 mov r5,#0
                 mov r6,#0
                 mov r7,#0
                 mov r8,#0
                 mov r9,#0
                 mov r10,#0
                 mov r12,#0

p101:            ldr r3,[r0],#4
                 ldr r4,[r0],#-3
                 usad8 r5,r3,r6
                 usada8 r5,r3,r6,r5
                 lsr r5,#3
                 strb r5,[r1],#1

                 subs r2,#1
                 bgt p101

                 pop {r0-r12,r14}
                 end;
end;


function avg(b1,count:cardinal):cardinal;

label p101;

// Make an average of 8 pixels, optimized
// rev 20190202

begin


                 asm
                 ldr r0,b1
                 mov r1,#0
                 ldr r2,count

p101:            ldrb r3,[r0],#1
                 add r1,r3
                 subs r2,#1
                 bgt p101

//                 ldr r2,count
//                 udiv r1,r1,r2

                 str r1,result
                 end ['r0','r1','r2','r3'];

result:=result div count;
end;


function fmax(b1,count:cardinal):cardinal;

label p101;

// Make an average of 8 pixels, optimized
// rev 20190202

begin


                 asm
                 ldr r0,b1
                 mov r1,#0
                 ldr r2,count

p101:            ldrb r3,[r0],#1
                 cmps r1,r3
                 movle r1,r3
                 subs r2,#1
                 bgt p101

//                 ldr r2,count
//                 udiv r1,r1,r2

                 str r1,result
                 end ['r0','r1','r2','r3'];

end;

procedure blur3(b1,b2,count:cardinal);

label p101;

// Make an average of 8 pixels, optimized
// rev 20181230

begin


                 asm
                 push {r0-r12,r14}
                 ldr r0,b1
                 ldr r1,b2
                 ldr r2,count
                 mov r3,#0
                 mov r4,#0
                 mov r5,#0
                 mov r6,#0
                 mov r7,#0
                 mov r8,#0
                 mov r9,#0
                 mov r10,#0
                 mov r12,#0

p101:            sub r12,r3
                 ldrb r3,[r0],#1
                 add r12,r3
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 sub r12,r4
                 ldrb r4,[r0],#1
                 add r12,r4
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 sub r12,r5
                 ldrb r5,[r0],#1
                 add r12,r5
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 sub r12,r6
                 ldrb r6,[r0],#1
                 add r12,r6
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 sub r12,r7
                 ldrb r7,[r0],#1
                 add r12,r7
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 sub r12,r8
                 ldrb r8,[r0],#1
                 add r12,r8
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 sub r12,r9
                 ldrb r9,[r0],#1
                 add r12,r9
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 sub r12,r10
                 ldrb r10,[r0],#1
                 add r12,r10
                 lsr r14,r12,#3
                 strb r14,[r1],#1

                 subs r2,#8
                 bgt p101

                 pop {r0-r12,r14}
                 end;


end;

procedure blur3v(b1,b2,count:cardinal);

label p101,p102;

// Make an average of 8 pixels, vertically

begin


                 asm
                 push {r0-r12,r14}
                 ldr r0,b1
                 ldr r1,b2
                 mov r2,#640
                 mov r3,#0
                 mov r4,#0
                 mov r5,#0
                 mov r6,#0
                 mov r7,#0
                 mov r8,#0
                 mov r9,#0
                 mov r10,#0
                 mov r12,#0

p102:            push {r2}


                 mov r2,#60

p101:            sub r12,r3
                 ldrb r3,[r0],#640
                 add r12,r3
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 sub r12,r4
                 ldrb r4,[r0],#640
                 add r12,r4
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 sub r12,r5
                 ldrb r5,[r0],#640
                 add r12,r5
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 sub r12,r6
                 ldrb r6,[r0],#640
                 add r12,r6
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 sub r12,r7
                 ldrb r7,[r0],#640
                 add r12,r7
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 sub r12,r8
                 ldrb r8,[r0],#640
                 add r12,r8
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 sub r12,r9
                 ldrb r9,[r0],#640
                 add r12,r9
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 sub r12,r10
                 ldrb r10,[r0],#640
                 add r12,r10
                 lsr r14,r12,#3
                 strb r14,[r1],#640

                 subs r2,#1
                 bgt p101

                 sub r0,#307200
                 sub r1,#307200
                 add r0,#1
                 add r1,#1

                 pop {r2}
                 subs r2,#1
                 bgt p102

                 pop {r0-r12,r14}
                 end;


end;


function findpoints2(b1,b2,count:integer):integer;

// --- rev 20181227
// --- The procedure finds light points on a dark background
// --- filtering out one point light spots
// --- b1: source picture address
// --- b2: target buffer. 32bit addresses of light spots
//         relative to the picture start

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

                 streq r7,[r6],#4    //streq
                 addeq r2,#1         //addeq
                 cmps r2,#8192
                 bge p102
                 subs r1,#1
                 bne p101

p102:            str r2,result
                 pop {r0-r7}
                 end;


end;


initialization

removeramlimits(cardinal(@scale4b));

end.

