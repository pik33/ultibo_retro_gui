unit camera2;

{$mode objfpc}{$H+}

interface

uses
  classes,sysutils, threads,
  retromalina, mwindows, blitter, retro, platform, camera;

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



  type TPoint=array[0..1] of integer;
       TMinMaxPoint=array[0..3] of integer;

  var camerathread2:TCameraThread2;
      PAthread2:TPAThread2;
      cmw2:pointer=nil;
      camerawindow2:TWindow=nil;
      rendertestwindow2:TWindow=nil;
      miniwindow2:TWindow=nil;
      at,at1,at2,at3,t1,t2,t3,t4:int64;
      testbuf1, testbuf2, testbuf3, testbuf4: cbuffer;
      tb4l:cbufferl absolute testbuf4;
      s1:integer=0;
      nFrames:cardinal=0;

      points:array[0..3900] of TPoint;
      pointnum:integer=0;
      i,j,k,l,m:integer;

  const maxpoint=5;

  var   points1: array[0..4*maxpoint-1] of integer;
        points1a:array[0..maxpoint-1] of TMinMaxPoint absolute points1;
        points2: array[0..2*maxpoint-1] of integer;
        points2a:array[0..maxpoint-1] of TPoint absolute points2;

implementation

uses playerunit; // for sprites :)

procedure soap2(b1,b2,count:integer);

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
                 //lsr r12,#2
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


procedure soap3(b1,b2,count:integer);

label p101;

// Make an average of 8 pixels


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
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 sub r12,r4
                 ldrb r4,[r0],#1
                 add r12,r4
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 sub r12,r5
                 ldrb r5,[r0],#1
                 add r12,r5
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 sub r12,r6
                 ldrb r6,[r0],#1
                 add r12,r6
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 sub r12,r7
                 ldrb r7,[r0],#1
                 add r12,r7
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 sub r12,r8
                 ldrb r8,[r0],#1
                 add r12,r8
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 sub r12,r9
                 ldrb r9,[r0],#1
                 add r12,r9
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 sub r12,r10
                 ldrb r10,[r0],#1
                 add r12,r10
                 lsr r14,r12,#2
                 strb r14,[r1],#1

                 subs r2,#8
                 bgt p101

                 pop {r0-r14}
                 end;


end;

procedure soap3v(b1,b2,count:integer);

label p101,p102;

// Make an average of 8 pixels


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
                 lsr r14,r12,#2
                 strb r14,[r1],#640

                 sub r12,r4
                 ldrb r4,[r0],#640
                 add r12,r4
                 lsr r14,r12,#2
                 strb r14,[r1],#640

                 sub r12,r5
                 ldrb r5,[r0],#640
                 add r12,r5
                 lsr r14,r12,#2
                 strb r14,[r1],#640

                 sub r12,r6
                 ldrb r6,[r0],#640
                 add r12,r6
                 lsr r14,r12,#2
                 strb r14,[r1],#640

                 sub r12,r7
                 ldrb r7,[r0],#640
                 add r12,r7
                 lsr r14,r12,#2
                 strb r14,[r1],#640

                 sub r12,r8
                 ldrb r8,[r0],#640
                 add r12,r8
                 lsr r14,r12,#2
                 strb r14,[r1],#640

                 sub r12,r9
                 ldrb r9,[r0],#640
                 add r12,r9
                 lsr r14,r12,#2
                 strb r14,[r1],#640

                 sub r12,r10
                 ldrb r10,[r0],#640
                 add r12,r10
                 lsr r14,r12,#2
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

label p101,p102;

var td:int64;
    td2:int64=0;
    n:integer=1;
    i:integer;
    p:integer;
    maxx,minx,maxy,miny,xx,yy:integer;
    tf:textfile;

begin
//assignfile(tf,'c:\cameratest');
//rewrite(tf);
ThreadSetpriority(ThreadGetCurrent,5);
threadsleep(1);
prepare_sprites;
repeat
threadsleep(1);
if (s1>0) and (n>60)  then

  begin
  SchedulerPreemptDisable(CPUGetCurrent);
  td:=gettime;
  diff4(cardinal(@rendertestwindow2.canvas),cardinal(@testbuf2),cardinal(@testbuf3),cxres*cyres,12 );
  pointnum:=findpoints2(cardinal(@testbuf3),cardinal(@testbuf4),cxres*cyres);
  fastmove(cardinal(@testbuf3),cardinal(miniwindow2.canvas),cxres*cyres);
  td:=gettime-td;
  SchedulerPreemptEnable(CPUGetCurrent);
  td2+=td;

// initialize minmax and points tables
//  camerawindow.println('Initializing tables') ;

  for i:=0 to maxpoint-1 do
    begin
    points1a[i][0]:=32767; //minx
    points1a[i][1]:=-1;    //maxx
    points1a[i][2]:=32767; //miny
    points1a[i][3]:=-1;    //maxy
    points2a[i][0]:=-1;
    points2a[i][1]:=-1;
    end;

//  camerawindow.println('Point number is '+inttostr(pointnum));

  if pointnum>1 then
    begin
    for i:=0 to pointnum-1 do
      begin
      xx:=tb4l[i] mod 640;
      yy:=tb4l[i] div 640;
      p:=0;
p101:
      if points2a[p][0]<>-1 then  // the point is in the table
        begin
        if (xx>points1a[p][0]-4)
          and (xx<points1a[p][1]+4)
            and (yy>points1a[p][2]-4)
              and (yy<points1a[p][3]+4) then // the pixel belongs to the point
          begin
//          camerawindow.println('point# '+inttostr(p)+' updated: '+inttostr(xx)+'  '+inttostr(yy));
          if xx<points1a[p][0] then points1a[p][0]:=xx
            else if xx>points1a[p][1] then points1a[p][1]:=xx;
          if yy<points1a[p][2] then points1a[p][2]:=yy
            else if yy>points1a[p][3] then points1a[p][3]:=yy;
          end

        else begin p+=1; if p<maxpoint then goto p101 else goto p102; end;
        end
      else   // add a new point
        begin
 //       camerawindow.println('point# '+inttostr(p)+' added: '+inttostr(xx)+'  '+inttostr(yy));
        points1a[p][0]:=xx;
        points1a[p][1]:=xx;
        points1a[p][2]:=yy;
        points1a[p][3]:=yy;
        points2a[p][0]:=xx;
        points2a[p][1]:=yy;
        end;
p102:
      end;
    p:=0;
    for i:=0 to maxpoint-1 do
      begin
      if points2a[i][0]>-1 then p+=1;
      if points2a[i][0]>-1 then points2a[i][0]:=(points1a[i][0]+points1a[i][1]) div 2;
      if points2a[i][1]>-1 then points2a[i][1]:=(points1a[i][2]+points1a[i][3]) div 2;
      xx:=points2a[i][0];
      yy:=points2a[i][1];
      if xx>-1 then
        begin

        camerawindow2.println(inttostr(i)+' '+inttostr(xx)+' '+inttostr(yy));

        end;
      end;

    waitvbl;
    for i:=0 to p-1 do
      begin
      dpoke(base+_spritebase+8*i,miniwindow2.x-32+points2a[i][0]);
      dpoke(base+_spritebase+8*i+2,miniwindow2.y-32+points2a[i][1]);
      end;
    for i:=p to 6 do
      begin
      dpoke(base+_spritebase+8*i,2048);
      dpoke(base+_spritebase+8*i+2,2048);
      end;


    yy:=points2a[0][1];
    xx:=points2a[0][0];
    end;
  miniwindow2.outtextxyz(0,0,inttostr(td2 div (n-60)),255,2,2);
  miniwindow2.outtextxyz(0,40,inttostr(pointnum),255,2,2);
  miniwindow2.outtextxyz(0,80,inttostr(p),255,2,2);
  camerawindow2.println('');
  s1:=0;
  end;
n+=1;


until terminated;
camerawindow2.println('PAThread terminating;');
//closefile(tf);
end;

procedure TCameraThread2.execute;

label p999,p998;

const maxframe=3600;  //1 minute

var frames2:integer;
    buffer:cardinal;

begin
//ThreadSetAffinity(ThreadGetCurrent,2);
//ThreadSetCPU(ThreadGetCurrent,1);
ThreadSetpriority(ThreadGetCurrent,7);
threadsleep(1);

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
    rendertestwindow2:=TWindow.create(cxres,cyres,'Camera render 2');
    rendertestwindow2.decoration.hscroll:=false;
    rendertestwindow2.decoration.vscroll:=false;
    rendertestwindow2.resizable:=true;
    rendertestwindow2.cls(0);
    rendertestwindow2.tc:=15;
    rendertestwindow2.move(500,400,cxres,cyres,0,0);
    end;
  if miniwindow2=nil then
    begin
    miniwindow2:=TWindow.create(cxres,cyres,'Camera diff 2');
    miniwindow2.decoration.hscroll:=false;
    miniwindow2.decoration.vscroll:=false;
    miniwindow2.resizable:=true;
    miniwindow2.cls(0);
    miniwindow2.tc:=15;
    miniwindow2.move(100,100,cxres,cyres,0,0);
    end;

buffer:=initcamera(640,480,60);
camerawindow2.println ('----- Camera buffer at '+inttohex(buffer,8));
if buffer<$C0000000 then goto p999;
startcamera;
while keypressed do readkey;
for frames2:=1 to maxframe do
  begin
  repeat threadsleep(1) until filled;
  t3:=gettime;
  soap3(buffer,cardinal(@testbuf1),cyres*cxres) ;
  t3:=gettime-t3;
  filled:=false;
  s1:=(frames mod 2) +1;
    t3:=gettime;
  soap3v(cardinal(@testbuf1),cardinal(rendertestwindow2.canvas),cxres*cyres);
    t3:=gettime-t3;
 // t1:=gettime-t1; if frames>1 then begin at+=t1; rendertestwindow2.outtextxyz(4,44,inttostr(at div (frames-1)),255,2,2); end; t1:=gettime;
 // if frames2>1 then begin at3+=t3; rendertestwindow2.outtextxyz(4,124,inttostr(at3 div (frames2-1)),255,2,2); end;
 // rendertestwindow2.outtextxyz(4,4,inttostr(frames),255,2,2);
  if keypressed then goto p998;
  end;
p998:
stopcamera;
camerawindow2.println ('----- Camera stopped ');
camerawindow2.println ('----- Main loop ended ');


  // for i:=0 to 10000 do camerawindow.println(inttostr(i));
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
end;


end.

