unit mwindows;

{$mode objfpc}{$H+}

//------------------------------------------------------------------------------
// The window manager unit for use with the retromachine
// v.0.03 - 20180127
// Piotr Kardasz pik33@o2.pl
// gpl v. 2.0 or higher
// alpha code quality
//------------------------------------------------------------------------------

interface

uses
  Classes, SysUtils, threads, retro, icons, retromalina, platform, vc4;

const mapbase=mainscreen+$800000;
      framewidth=4;
      moved:integer=-10;
      wt:int64=0;

type TWindow=class;
     TDecoration=class;
     TWidget=class;
     TButton=class;
     TIcon=class;
     TMenuItem=class;
     TMenu=class;
     TStatusBar=class;


     TWindows= class(TThread)
     private
     protected
       procedure Execute; override;
     public
      Constructor Create(CreateSuspended : boolean);
     end;

//------------------------------------------------------------------------------
// Basic window class
//------------------------------------------------------------------------------

type TWindow=class(TObject)
     handle:TWindow;
     prev,next:TWindow;                     // 2-way list
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
     canvas:pointer;                        // graphic memory
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

     procedure draw(dest:integer);                                      // redraw a window
     procedure move(ax,ay,al,ah,avx,avy:integer);                       // move and resize. ax,ay - position on screen
                                                                        // al, ah - visible dimensions without decoration
                                                                        // avy, avy - upper left visible canvas pixel
     function checkmouse:TWindow;                                       // check and react to mouse events
     procedure resize(nwl,nwh:integer);                                 // resize the canvas
     procedure select;                                                  // select the window and place it on top

     // graphic methods

     procedure cls(c:integer);                                          // clear window and fill with color
     procedure putpixel(ax,ay,color:integer); inline;                   // put a pixel to window
     function getpixel(ax,ay:integer):integer; inline;                  // get a pixel from window
     procedure putchar(ax,ay:integer;ch:char;col:integer);              // put a 8x16 char on window
     procedure putchar8(ax,ay:integer;ch:char;col:integer);              // put a 8x16 char on window
     procedure putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);       // put a zoomed char, xz,yz - zoom
     procedure outtextxy8(ax,ay:integer; t:string;c:integer);           // output a string from x,y position
     procedure outtextxy(ax,ay:integer; t:string;c:integer);            // output a string from x,y position
     procedure outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);     // output a zoomed string
     procedure box(ax,ay,al,ah,c:integer);                              // draw a filled box
     procedure print(line:string);                                      // print a string at the text cursor
     procedure println(line:string);                                    // print a string and add a new line
     procedure scrollup;

     // TODO: add the rest of graphic procedures from retromalina unit

     end;

type TWindow32=class(TObject)
     handle:TWindow32;
     prev,next:TWindow32;                   // 2-way list
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
     canvas:pointer;                        // graphic memory
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

     procedure draw(dest:integer);                                      // redraw a window
     procedure move(ax,ay,al,ah,avx,avy:integer);                       // move and resize. ax,ay - position on screen
                                                                        // al, ah - visible dimensions without decoration
                                                                        // avy, avy - upper left visible canvas pixel
     function checkmouse:TWindow;                                       // check and react to mouse events
     procedure resize(nwl,nwh:integer);                                 // resize the canvas
     procedure select;                                                  // select the window and place it on top

     // graphic methods

     procedure cls(c:integer);                                          // clear window and fill with color
     procedure putpixel(ax,ay,color:integer); inline;                   // put a pixel to window
     function getpixel(ax,ay:integer):integer; inline;                  // get a pixel from window
     procedure putchar(ax,ay:integer;ch:char;col:integer);              // put a 8x16 char on window
     procedure putchar8(ax,ay:integer;ch:char;col:integer);              // put a 8x16 char on window
     procedure putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);       // put a zoomed char, xz,yz - zoom
     procedure outtextxy8(ax,ay:integer; t:string;c:integer);           // output a string from x,y position
     procedure outtextxy(ax,ay:integer; t:string;c:integer);            // output a string from x,y position
     procedure outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);     // output a zoomed string
     procedure box(ax,ay,al,ah,c:integer);                              // draw a filled box
     procedure print(line:string);                                      // print a string at the text cursor
     procedure println(line:string);                                    // print a string and add a new line

     // TODO: add the rest of graphic procedures from retromalina unit

     end;


//------------------------------------------------------------------------------
// Panel. A special window displayed at the bottom of the screen.
// A place for start button, minimized windows, speedbuttons etc
// Always on top
//------------------------------------------------------------------------------


     Tpanel=class(TWindow)
     constructor create;
     end;

//------------------------------------------------------------------------------
// File selector. A window with methods for directory display and file select.
//------------------------------------------------------------------------------

type Tfileselector=class(Twindow)
     done:boolean;
     currentdir:string;
     currentdir2:string;
     filename:string;
     sr:TSearchRec;
     s:string;
     filenames:array[0..1000,0..2] of string;
     ilf,ild:integer;
     sel:integer;
     selstart:integer;
     drivetable:array['A'..'Z'] of boolean;
     dir:string;
     constructor create(adir:string);
     procedure dirlist;
     procedure sort;
     procedure checkselected;
     procedure selectnext;

// TODO: remove the mess. Add "Selectnext" method

    end;

//------------------------------------------------------------------------------
// Window decoration
//------------------------------------------------------------------------------


type TDecoration=class(TObject)

     title:pointer;
     parent:TWindow;
     hscroll,vscroll,menu,status,up,down,close:boolean;
     leftc,rightc,upc,downc:pointer;
     ll,lh,rl,rh,ul,uh,dl,dh:integer;
     constructor create;
     destructor destroy;
     procedure draw;
     end;


type TWidget=class(TObject)

     next,prev:TWidget;
     granny:TWindow;
     procedure draw;
     procedure checkall;
     procedure setparent(parent:TWidget);
     procedure setdesc(desc:TWidget);
     function gofirst:TWidget;

     end;


//------------------------------------------------------------------------------
// Button
//------------------------------------------------------------------------------


type TButton=class(TWidget)
     x,y:integer;                                                      // upper left pixel position on window
     l,h:integer;                                                      // dimensions
     c1,c2:integer;                                                    // basic background color, text color
     clicked:integer;                                                  // mouse event
     s:string;                                                         // title
     fsx,fsy:integer;                                                  // font size x,y

     value:integer;
     canvas:pointer;
     visible,highlighted,selected,radiobutton,selectable,down:boolean;
     radiogroup:integer;

     constructor create(ax,ay,al,ah,ac1,ac2:integer;aname:string;g:TWindow);
     destructor destroy; override;
     function append(ax,ay,al,ah,ac1,ac2:integer;aname:string):TButton;
     function checkmouse:boolean;
     procedure highlight;
     procedure unhighlight;
     procedure show;
     procedure hide;
     procedure select;
     procedure unselect;
     procedure draw;
     function findselected:TButton;
     procedure setvalue(v:integer);
     procedure checkall;
     procedure box(ax,ay,al,ah,c:integer);
     end;


type TIcon=class(TObject)

     x,y,l,h:integer;
     mx,my:integer;
     size:integer;
     title:string;
     granny:TWindow;
     g2:TMenuItem;
     icon16:TIcon16;
     icon32:TIcon32;
     icon48:TIcon48;
     highlighted:boolean;
     bg:array[0..12287] of byte;
     next,prev:TIcon;
     clicked,dblclicked:boolean;
     constructor create(atitle:string;g:TWindow);
     procedure draw;
     procedure move(ax,ay:integer);
     function append(atitle:string):TIcon;
     function checkmouse:boolean;
     procedure highlight;
     procedure unhighlight;
     procedure arrange;
     procedure checkall;

     end;


//

type TMenuItem=class(TObject)
     title:string;
     icon:TIcon;
     next,prev,sub:TMenuItem;
     x,y,l:integer;
     level:integer;
     visible:boolean;
     selected:boolean;
     highlighted:boolean;
     clicked:boolean;
     horizontal:boolean;
     granny:TWindow;
     constructor create(atitle:string; w:twindow);
     function append(atitle:string):TMenuItem;
     function addsub(atitle:string):TMenuItem;
     procedure draw(dest:integer);
     function checkmouse:boolean;
     end;

     TMenu=class (TObject)
     item:TMenuItem;
     granny:TWindow;
     horizontal:boolean;
     constructor create(g:TWindow);
     function append(atitle:string):TMenuItem;
     procedure checkall(dest:integer);
     end;

     TStatusBar=class (TObject)
     height:integer;
     canvas:pointer;
     end;

type PRectangle=^TRectangle;

     trectangle=record
     x1,y1,x2,y2,handle:integer;
     next,prev:PRectangle
     end;

var background:TWindow=nil;  // A mother of all windows except the panel
    background32:TWindow32=nil; // 32bit version

    panel:TPanel=nil;        // The panel
    vertex:array[0..1023,0..2] of integer;  // x, y, handle
    rectangles:array[0..4096,0..4] of integer; //x, y, l, h, handle
    xtable, ytable:array[0..63] of integer;
    lastchecked:TWindow;
    Arectangle:TRectangle;

// Theme colors.

    activecolor:integer=120;
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

// A temporary icon. TODO: Icon class and methods

    icon:array[0..15,0..15] of byte;

    semaphore:boolean=false;


//------------------------------------------------------------------------------
// Helper procedures
//------------------------------------------------------------------------------

procedure gouttextxy(g:pointer;x,y:integer; t:string;c:integer);
procedure gputpixel(g:pointer; x,y,color:integer); inline;
procedure gpouttextxy(g:pointer;x,y:integer; t:string;c,pitch:integer);
procedure gpputpixel(g:pointer; x,y,color,pitch:integer); inline;
procedure makeicon;
procedure getrectanglelist;


implementation

uses blitter;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Main window thread
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

constructor TWindows.Create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;

procedure TWindows.Execute;

var scr2,scr:integer;
    wh:TWindow;
    t:int64;
    q:integer=0;

const dblinvalid=0;

begin
Arectangle.handle:=-1;
q:=0;
scr:=mainscreen+$800000;
ThreadSetAffinity(ThreadGetCurrent,4);
threadsleep(1);
cls(100);

repeat
  inc(q);
 // getrectanglelist;
  t:=gettime;
  lastchecked:=background.checkmouse;
  getrectanglelist;
  windowsdone:=false;
  wh:=background;
  repeat
  //  if scr=mainscreen+$800000 then scr2:=integer(p2) else scr2:=integer(p2+(xres+64)*(yres));
    wh.draw(scr) ;
    wh:=wh.next;
  until wh=nil;
  panel.draw(scr);
  windowsdone:=true;
  wt:=gettime-t;
  repeat threadsleep(1) until screenaddr<>scr;
  scr:=screenaddr;
until terminated;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Window methods
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// TWindow constructor.
// Parameters:
// wl: window canvas length
// wh: window canvas height (the canvas can be resized later)
// title - if empt, windows will have no decoration
//------------------------------------------------------------------------------

constructor TWindow.create (al,ah:integer; atitle:string);

var who:TWindow;
    i,j:integer;

begin
inherited create;
semaphore:=true;
mstate:=0;
dclick:=false;
needclose:=false;
if background<>nil then   // there ia s background so create a normal window
  begin
  who:=background;
  while who.next<>nil do who:=who.next;
  makeicon;               // Temporary icon, todo: icon class
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
  canvas:=getmem(wl*wh);  // get a memory for graphics. 8-bit only in this version
  for i:=0 to wl*wh-1 do poke(cardinal(canvas)+i,0); // clear the graphic memory
  title:=atitle;
  if atitle<>'' then     // create a decoration
    begin
    decoration:=TDecoration.create;
    decoration.title:=getmem(wl*titleheight);
    decoration.hscroll:=true;
    decoration.vscroll:=true;
    decoration.up:=true;
    decoration.down:=true;
    decoration.close:=true;
    activey:=0;
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
  canvas:=pointer(backgroundaddr);  // graphic memory address
                                   // The window manager works at the top
                                   // of the retromachine. The background window
                                   // replaces the retromachine background with
                                   // graphic memory a the same address, so
                                   // non-windowed retromachine programs will not
                                   // notice any difference when running on
                                   // the window manager

  decoration:=nil;            //+48
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


destructor TWindow.destroy;

var i,j:integer;

begin
visible:=false;
prev.next:=next;
if next<>nil then next.prev:=prev;
if canvas<>nil then freemem(canvas);
if decoration<>nil then
  begin
  decoration.destroy
  end;
end;

//------------------------------------------------------------------------------
// TWindow draw method
// Draw a window on compositing canvas
// dest - address of the canvas
//------------------------------------------------------------------------------

procedure TWindow.draw(dest:integer);

var dt,dg,dh,dx,dy,dx2,dy2,dl,dsh,dsv,i,j,c,ct,a,dm:integer;
   dxr,dyr:integer;
   wt1:int64;
   q1,q2,q3:integer;
   hsw,vsh,hsp,vsp:integer;
   rectangle:PRectangle;

begin
redraw:=false; // tell the other procedures that the drawing is on its way
if decoration=nil then  // adjust window dimensions
  begin
  dg:=0;
  dh:=0;
  dt:=0;
  dl:=0;
  dsh:=0;
  dsv:=0;
  hsw:=0;
  vsh:=0;
  hsp:=0;
  vsp:=0;
  end
else
  begin
  dt:=titleheight;
  dl:=borderwidth;
  dg:=borderwidth;
  dh:=borderwidth;
  if decoration.hscroll then dsh:=scrollwidth else dsh:=0;
  if decoration.vscroll then dsv:=scrollwidth else dsv:=0;
  if decoration.menu then dm:=menuheight else dm:=0;
  if not virtualcanvas then
    begin
    hsw:=round((l/wl)*l); if hsw<11 then hsw:=10;
    vsh:=round((h/wh)*h); if vsh<11 then vsh:=10;
    hsp:=round((vx/(wl-l))*(l-hsw));
    vsp:=round((vy/(wh-h))*(h-vsh));
    end
  else
    begin
    hsw:=round((l/vcl)*l); if hsw<11 then hsw:=10;
    vsh:=round((h/vch)*h); if vsh<11 then vsh:=10;
    hsp:=round((vcx/(vcl-l))*(l-hsw));
    vsp:=round((vcy/(vch-h))*(h-vsh));
    end;
  end;



//if self=background then begin fastmove(mainscreen,dest,xres*yres); end
//else
  begin

  if buttons<>nil then buttons.draw;                      // update the wigdets

  // instead of full window, draw rectangles
  if self is tpanel then blit8(integer(canvas),vx,vy,dest,x,y,l,h,wl,xres)
  else begin
  rectangle:=@arectangle;
  repeat
//    wt1:=gettime;

    repeat rectangle:=rectangle^.next until (rectangle^.handle=integer(self.handle)) or (rectangle^.next=nil);
//    wt1:=gettime-wt1;
//    retromalina.box(0,0,100,32,0);retromalina.outtextxy(0,0,inttostr(wt1),15);
    if rectangle^.handle=integer(self.handle) then
      begin
      dxr:=rectangle^.x1-x;   // todo if dxr<0, correct the rectangle
      dyr:=rectangle^.y1-y;
      blit8(integer(canvas),vx+dxr,vy+dyr,dest,rectangle^.x1,rectangle^.y1, rectangle^.x2-rectangle^.x1+1,rectangle^.y2-rectangle^.y1+1,wl,xres);
      end;
  until rectangle^.next=nil;
  end;
//  blit8(integer(canvas),vx,vy,dest,x,y,l,h,wl,xres); // then blit the window to the canvas
  if next<>nil then                                       // and draw the decoration
    begin
    selected:=false;
    c:=inactivecolor;
    ct:=inactivetextcolor;
    a:=0;
    end
  else
    begin
    selected:=true;
    c:=activecolor;
    ct:=activetextcolor;
    a:=32
    end;
  if decoration<>nil then
    begin
    if (mousex>(x+l+dsv-60)) and (mousey>(y-titleheight-dm+4)) and (mousex<(x+l+dsv-44)) and (mousey<(y-4)-dm) then q1:=122 else q1:=0;
    if (mousex>(x+l+dsv-40)) and (mousey>(y-titleheight-dm+4)) and (mousex<(x+l+dsv-24)) and (mousey<(y-4-dm)) then q2:=122 else q2:=0;
    if (mousex>(x+l+dsv-20)) and (mousey>(y-titleheight-dm+4)) and (mousex<(x+l+dsv-4)) and (mousey<(y-4-dm)) then begin q3:=32; a:=32; end else q3:=0;
    if selected and (mx>(l+dsv-20)) and (my>(-titleheight-dm+4)) and (mx<(l+dsv-4)) and (my<(-4-dm)) and (mousek=1) then needclose:=true;


      fill2d(dest,x-dl,y-dt-dm-dl,l+dl+dsv,dl,xres,c+borderdelta);         //upper border

      fill2d(dest,x-dl,y-dt-dm,l+dl+dsv,dt,xres,c);                        //title bar
      fill2d(dest,x-dl,y-dm,l+dl+dsv,dm,xres,menucolor);                        //menu

      if (decoration.menu) and (menu<>nil) then menu.checkall(dest);
      fill2d(dest,x-dl,y-dt-dl-dm,dl,h+dt+dl+dsh+dh+dm,xres,c+borderdelta);   //left border
      fill2d(dest,x-dl,y+h+dsh,l+dl+dg+dsv,dh,xres,c+borderdelta);      //lower border
      fill2d(dest,x+l+dsv,y-dt-dl-dm,dg,h+dt+dl+dsh+dl+dm,xres,c+borderdelta);//right border

      fill2d(dest,x,y+h,l,dsh,xres,scrollcolor);                        //horizontal scroll bar
      fill2d(dest,x+3+hsp,y+h+3,hsw-6,dsh-6,xres,activescrollcolor);    //horizontal scroll bar active part

      fill2d(dest,x+l,y,dsv,h,xres,scrollcolor);                        //vertical scroll bar
      fill2d(dest,x+l+3,y+3+vsp,dsv-6,vsh-6,xres,activescrollcolor);    //vertical scroll bar active part


      fill2d(dest,x+l,y+h,dsv,dsh,xres,c);                  //down right corner
      gouttextxy(pointer(dest),x+32,y-titleheight-dm+4,title,ct);


    for i:=0 to 15 do for j:=0 to 15 do if down_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-60+i,y-titleheight-dm+4+j,down_icon[i+16*j]);
    if q1<>0 then
       for i:=0 to 15 do
         for j:=0 to 15 do
           if down_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-60+i,y-titleheight-dm+4+j,down_icon[i+16*j])
                                  else gputpixel(pointer(dest),x+l+dsv-60+i,y-titleheight-dm+4+j,q1);
    if q2<>0 then
       for i:=0 to 15 do
         for j:=0 to 15 do
           if up_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-40+i,y-titleheight-dm+4+j,up_icon[i+16*j])
                                else gputpixel(pointer(dest),x+l+dsv-40+i,y-titleheight-dm+4+j,q2)
    else for i:=0 to 15 do for j:=0 to 15 do if up_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-40+i,y-titleheight-dm+4+j,up_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if close_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-20+i,y-titleheight-dm+4+j,a+q3+close_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if icon[i,j]>0 then gputpixel(pointer(dest),x+4+i,y-titleheight-dm+4+j,icon[i,j]);
    end;
  end;
  redraw:=true;
wt1:=gettime-wt;
end;


//------------------------------------------------------------------------------
// TWindow move method
// move and resize the window
// ax,ay - new position on screen if >-2048
// al,ah - new visible dimensions without decoration if >0
// avy,avy - new upper left visible canvas pixel if >-1
//------------------------------------------------------------------------------

procedure TWindow.move(ax,ay,al,ah,avx,avy:integer);

var q:integer;

begin
if ay>yres-25 then ay:=yres-25;
if al>0 then begin l:=al; end;        // now set new window parameters
if ah>0 then begin h:=ah; end;

q:=8*length(title)+96;
if (decoration<>nil) and (al>0) and (al<q) then l:=q;
if (ah>0) and (ah<64) then h:=64;
if al>wl then l:=wl;
if ah>wh then h:=wh;

if ax>-2048 then begin x:=ax; end;
if ay>-2048 then begin y:=ay; end;
if avx>-1 then vx:=avx;
if avy>-1 then vy:=avy;

end;


//------------------------------------------------------------------------------
// Twindow checkmouse function
// This function should be called every vblank for the background window
// Called for any window returns the window handler for the window on which
// there is the mouse cursor and reacts to events:
// by selecting, resizing or moving the clicked window
//------------------------------------------------------------------------------

function TWindow.checkmouse:TWindow;

label p999;

var window:TWindow;
    mmx,mmy,mmk,mmw,dt,dg,dh,dl,dsh,dsv,dm:integer;
    i,j,x1,y1,x2,y2,q,q2,sy2,vcount,rcount:integer;

    ttttt:int64;
      rect,r2:PRectangle;

const state:integer=0;
      deltax:integer=0;
      deltay:integer=0;
      sx:integer=0;
      sy:integer=0;
      hsw:integer=0;
      vsp:integer=0;
      vsh:integer=0;
      hsp:integer=0;
      oldhsp:integer=0;
      oldvsp:integer=0;

      qqqqq:integer=0;
begin

result:=background;

mmx:=mousex;
mmy:=mousey;
mmk:=mousek;
mmw:=mousewheel;

if mmk=0 then
  begin
  state:=6;
  window:=background;
  while (window.next<>nil) do begin window.mk:=0; window:=window.next; end;
  end;

// if mouse key pressed and there is a window set to move, move it

if mmk=1 then // find a window with mk=1
  begin
  window:=background;
  while (window.next<>nil) and (window.mk<>1) do window:=window.next;

  if window.mk=1 then
    begin


    if state=0 then window.move(mmx-window.mx,mmy-window.my,0,0,-1,-1)
    else if state=1 then
      begin
      q:=mmx-window.x+deltax;
      if q+window.vx>window.wl then begin window.vx:=window.wl-q; if window.vx<0 then begin window.vx:=0; q:=window.wl; end; end;
      window.move(window.x,window.y, q ,window.h,-1,-1)
      end
    else if state=2 then
      begin
       q:=mmy-window.y+deltay;
       if q+window.vy>window.wh then begin window.vy:=window.wh-q; if window.vy<0 then begin window.vy:=0; q:=window.wh; end; end;
       window.move(window.x,window.y, window.l, q,-1,-1)
       end

    else if state=3 then
      begin
      q:=mmx-window.x+deltax;
      if q+window.vx>window.wl then begin window.vx:=window.wl-q; if window.vx<0 then begin window.vx:=0; q:=window.wl; end; end;
      q2:=mmy-window.y+deltay;
      if q2+window.vy>window.wh then begin window.vy:=window.wh-q2; if window.vy<0 then begin window.vy:=0; q2:=window.wh; end; end;


      window.move(window.x,window.y, q ,q2, -1, -1)
      end
    else if state=4 then
      begin
      if not window.virtualcanvas then
        begin
        q:=round((mmy-window.y-sy)*(window.wh-window.h)/(window.h-vsh));
        if q<0 then q:=0;
        if q>window.wh-window.h then q:=window.wh-window.h;
        window.move(window.x,window.y,0,0,-1,q);
        end
      else
        begin
        q:=round((mmy-window.y-sy)*(window.vch-window.h)/(window.h-vsh));
        if q<0 then q:=0;
        if q>window.vch-window.h then q:=window.vch-window.h;
        window.vcy:=q;
        end;
      end
    else if state=5 then
      begin
      if not window.virtualcanvas then
        begin
        q:=round((mmx-window.x-sx)*(window.wl-window.l)/(window.l-hsw));
        if q<0 then q:=0;
        if q>window.wl-window.l then q:=window.wl-window.l;
        window.move(window.x,window.y,0,0,q,-1);
        end
      else
        begin
        q:=round((mmx-window.x-sx)*(window.vcl-window.l)/(window.l-hsw));
        if q<0 then q:=0;
        if q>window.vcl-window.l then q:=window.vcl-window.l;
        window.vcx:=q;
        end;
      end;
    result:=window;
 //   getrectanglelist;
    goto p999;
    end;
  end;

// we are here if mousekey=0 or there is no windows to move



window:=background;
while window.next<>nil do  window:=window.next;


if window.decoration=nil then
  begin
  dg:=0;
  dh:=0;
  dt:=0;
  dl:=0;
  dsh:=0;
  dsv:=0;
  dm:=0;
  end
else
  begin
  dt:=titleheight;
  dl:=borderwidth;
  dg:=borderwidth;
  dh:=borderwidth;
  if window.decoration.menu then dm:=menuheight else dm:=0;
  if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
  if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
  end;

// go back with windows chain until you found the window on which there is the mouse cursor

while ((mmx<window.x-dg) or (mmx>window.x+window.l+dg+dsv) or (mmy<window.y-dt-dg-dm) or (mmy>window.y+window.h+dh+dsh)) and (window.prev<>nil) do
  begin
  window.mx:=-1;
  window.my:=-1;
  window.mk:=-1;
  window:=window.prev;

  if window.decoration=nil then
    begin
    dg:=0;
    dh:=0;
    dt:=0;
    dl:=0;
    dsh:=0;
    dsv:=0;
    dm:=0;
    end
  else
    begin
    dt:= titleheight;
    dl:=borderwidth;
    dg:=borderwidth;
    dh:=borderwidth;
    if window.decoration.menu then dm:=menuheight else dm:=0;
    if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
    if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
    end
  end;
result:=window;

// todo: HERE::::: check all widgets on this window !!!
if window.buttons<> nil then window.buttons.checkall;
// now, here no windows to move and window=window to select
// if the window is not selected, select it

if (mmk=1) and (window.mk=0) then

  if semaphore=false then window.select;

//and set mouse correction amount
window.mx:=mmx-window.x;
window.my:=mmy-window.y;
window.mk:=mmk;
if not window.virtualcanvas then
  begin
  hsw:=round((window.l/window.wl)*window.l); if hsw<11 then hsw:=10;
  vsh:=round((window.h/window.wh)*window.h); if vsh<11 then vsh:=10;
  hsp:=round((window.vx/(window.wl-window.l))*(window.l-hsw));
  vsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh));
  end
else
  begin
  hsw:=round((window.l/window.vcl)*window.l); if hsw<11 then hsw:=10;
  vsh:=round((window.h/window.vch)*window.h); if vsh<11 then vsh:=10;
  hsp:=round((window.vcx/(window.vcl-window.l))*(window.l-hsw));
  vsp:=round((window.vcy/(window.vch-window.h))*(window.h-vsh));
  end;

// now set the state according to clicked area
if (not(window.resizable)) and (mmy>window.y+window.activey) then begin state:=6; goto p999; end;

if not(window.resizable) or ((mmx<(window.x+window.l)) and (mmy<(window.y-dm{window.h}))) then begin state:=0; deltax:=0; deltay:=0 end      // window

else if (mmx<(window.x+window.l)) and (mmy<(window.y)) then begin state:=7; deltax:=0; deltay:=0 end      // window

else if (mmx<(window.x+window.l)) and (mmy<(window.y + window.h )) then begin state:=6; deltax:=0; deltay:=0 end      // window
else if (mmx>=(window.x+window.l)) and (mmx<(window.x+window.l+scrollwidth-1)) and (mmy<(window.y+vsp+vsh-3)) and (mmy>(window.y+vsp+3)) then
  begin
  state:=4;
  if not window.virtualcanvas then oldvsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh))
  else oldvsp:=round((window.vcy/(window.vch-window.h))*(window.h-vsh));
  sy:=mmy-window.y-vsp;
  end                                   // vertical scroll bar


else if (mmx>=(window.x+window.l)) and (mmy<(window.y+window.h)) then begin state:=1; deltax:=window.x+window.l-mmx; deltay:=0; end      // right border
else if (mmx<(window.x+hsp+hsw-3)) and (mmx>(window.x+hsp+3)) and (mmy>=(window.y+window.h)) and (mmy<(window.y+window.h+scrollwidth-1)) then
  begin
  state:=5;
  if not window.virtualcanvas then oldhsp:=round((window.vx/(window.wl-window.l))*(window.l-hsw))
  else oldhsp:=round((window.vcx/(window.vcl-window.l))*(window.l-hsw));
  sx:=mmx-window.x-hsp;
  end                               // horizontal scroll bar

else if (mmx<(window.x+window.l)) and (mmy>=(window.y+window.h)) then begin state:=2; deltax:=0; deltay:=window.y+window.h-mmy; end      // down border
else begin state:=3; deltax:=window.x+window.l-mmx; deltay:=window.y+window.h-mmy; end ;                                                 // corner
window.mstate:=state;
if mmw=129 then begin mousewheel:=128; q:=window.vy-16; if q<0 then q:=0; window.vy:=q; end;
if mmw=127 then begin mousewheel:=128; q:=window.vy+16; if q+window.h>window.wh then q:=window.wh-window.h; window.vy:=q; end;
if window is TFileselector then TFileselector(window).checkselected;
p999:
end;


//------------------------------------------------------------------------------
// TWindow resize method
// Resize the window canvas
//------------------------------------------------------------------------------


procedure TWindow.resize(nwl,nwh:integer);

label p999;

var gd,gd2:pointer;
    bl,bh:integer;
    i:integer;

begin
if (nwl=wl) and (nwh=wh) then goto p999; // nothing to resize
gd:=getmem(nwl*nwh);
for i:=0 to nwl*nwh-1 do poke(integer(gd)+i,bg);
if nwl>wl then bl:=wl else bl:=nwl;
if nwh>wh then bh:=wh else bh:=nwh;
blit(integer(canvas),0,0,integer(gd),0,0,bl,bh,wl,nwl);
gd2:=canvas;
canvas:=gd;
wl:=nwl; wh:=nwh;
waitvbl;
waitvbl;
freemem(gd2);
if l>wl then l:=wl;
if h>wh then h:=wh;
if vx+l>wl then vx:=wl-l;
if vy+h>wh then vy:=wh-h;
p999:
end;

//------------------------------------------------------------------------------
// TWindow select method
// select the window and place it on top
//------------------------------------------------------------------------------

procedure Twindow.select;

var who,whh:TWindow;

begin
who:=background;
while who.next<>nil do begin who.selected:=false; who:=who.next; end;
who:=self;
if (who.next<>nil) and (who<>background) then
  begin
  who.prev.next:=who.next;
  who.next.prev:=who.prev;
  whh:=who;
  repeat whh:=whh.next until whh.next=nil;
  who.next:=nil;
  who.prev:=whh;
  whh.next:=who;
  end;
selected:=true;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TWindow graphic methods
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// cls - clear window and fill with color

procedure TWindow.cls(c:integer);

var i,al:integer;

begin
box(0,0,wl,wh,c);
bg:=c;
end;


//putpixel - put a pixel to window at ay, ay position in color color

procedure TWindow.putpixel(ax,ay,color:integer); inline;

label p999;

var adr:integer;

begin
if (ax<0) or (ax>=wl) or (ay<0) or (ay>wh) then goto p999;
adr:=cardinal(canvas)+ax+wl*ay;
poke(adr,color);
p999:
end;


// getpixel - get a pixel color at position ax, ay

function TWindow.getpixel(ax,ay:integer):integer; inline;

label p999;

var adr:integer;

begin
if (ax<0) or (ax>=wl) or (ay<0) or (ay>wh) then goto p999;
adr:=cardinal(canvas)+ax+wl*ay;
result:=peek(adr);
p999:
end;


// putchar - put a 8x16 char ch on the window at ax,ay with color col
// The char definitions are in SystemFont array

procedure TWindow.putchar(ax,ay:integer;ch:char;col:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      putpixel(ax+j,ay+i,col);
    end;
  end;
end;

procedure TWindow.putchar8(ax,ay:integer;ch:char;col:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 7 do
  begin
  b:=atari8font[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (128 shr j))<>0 then
      putpixel(ax+j,ay+i,col);
    end;
  end;
end;

// putcharz - put a zoomed char, xz,yz - zoom

procedure TWindow.putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);


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
           putpixel(ax+j*xz+ll,ay+i*yz+k,col);
    end;
  end;
end;


// outtextxy - output a string from x,y position; c-color

procedure TWindow.outtextxy(ax,ay:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(ax+8*i-8,ay,t[i],c);
end;

procedure TWindow.outtextxy8(ax,ay:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar8(ax+8*i-8,ay,t[i],c);
end;



// outtextxyz - output a zoomed string

procedure TWindow.outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(ax+8*xz*i,ay,t[i+1],c,xz,yz);
end;

procedure TWindow.print(line:string);

var i:integer;

begin
for i:=1 to length(line) do
  begin
  box(8*tcx,16*tcy,8,16,bg);
  putchar(8*tcx,16*tcy,line[i],tc);
  tcx+=1;
  if tcx>=(wl div 8) then
    begin
    tcx:=0;
    tcy+=1;
    if tcy>=(wh div 16) then
      begin
      scrollup;  //todo - add this
      tcy:=(wh div 16) -1;
      end;
    end;
  end;
end;

procedure TWindow.println(line:string);

begin
print(line);
tcy+=1;
tcx:=0;
if tcy>=(wh div 16) then
  begin
  scrollup;
  tcy:=(wh div 16) -1;
  end;
end;


procedure TWindow.scrollup;

begin
blit8(cardinal(canvas),0,16,cardinal(canvas),0,0,wl,16*(wh div 16)-16,wl,wl);
box(0,16*((wh div 16)-1),wl,16+(wh mod 16),bg);
end;

// box - draw a filled box

procedure TWindow.box(ax,ay,al,ah,c:integer);

label p101,p102,p999;

var screenptr:cardinal;
    xres,yres:integer;

begin

screenptr:=integer(canvas);
xres:=wl;
yres:=wh;
if ax<0 then begin al:=al+ax; ax:=0; if al<1 then goto p999; end;
if ax>=xres then goto p999;
if ay<0 then begin ah:=ah+ay; ay:=0; if ah<1 then goto p999; end;
if ay>=yres then goto p999;
if ax+al>=xres then al:=xres-ax;
if ay+ah>=yres then ah:=yres-ay;


             asm
             push {r0-r6}
             ldr r2,ay
             ldr r3,xres
             ldr r1,ax
             mul r3,r3,r2
             ldr r4,al
             add r3,r1
             ldr r0,screenptr
             add r0,r3
             ldrb r3,c
             ldr r6,ah

p102:        mov r5,r4
p101:        strb r3,[r0],#1  // inner loop
             subs r5,#1
             bne p101
             ldr r1,xres
             add r0,r1
             sub r0,r4
             subs r6,#1
             bne p102

             pop {r0-r6}
             end;

p999:
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Window methods - 32bit versions
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// TWindow constructor.
// Parameters:
// wl: window canvas length
// wh: window canvas height (the canvas can be resized later)
// title - if empt, windows will have no decoration
//------------------------------------------------------------------------------

constructor TWindow32.create (al,ah:integer; atitle:string);

var who:TWindow32;
    i,j:integer;

begin
inherited create;
semaphore:=true;
mstate:=0;
dclick:=false;
needclose:=false;
if background32<>nil then   // there ia s background so create a normal window
  begin
  who:=background32;
  while who.next<>nil do who:=who.next;
  makeicon;               // Temporary icon, todo: icon class
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
  canvas:=getmem(wl*wh);  // get a memory for graphics. 8-bit only in this version
  for i:=0 to wl*wh-1 do poke(cardinal(canvas)+i,0); // clear the graphic memory
  title:=atitle;
  if atitle<>'' then     // create a decoration
    begin
    decoration:=TDecoration.create;
    decoration.title:=getmem(wl*titleheight);
    decoration.hscroll:=true;
    decoration.vscroll:=true;
    decoration.up:=true;
    decoration.down:=true;
    decoration.close:=true;
    activey:=0;
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
  canvas:=pointer(backgroundaddr);  // graphic memory address
                                   // The window manager works at the top
                                   // of the retromachine. The background window
                                   // replaces the retromachine background with
                                   // graphic memory a the same address, so
                                   // non-windowed retromachine programs will not
                                   // notice any difference when running on
                                   // the window manager

  decoration:=nil;            //+48
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


destructor TWindow32.destroy;

var i,j:integer;

begin
visible:=false;
prev.next:=next;
if next<>nil then next.prev:=prev;
if canvas<>nil then freemem(canvas);
if decoration<>nil then
  begin
  decoration.destroy
  end;
end;

//------------------------------------------------------------------------------
// TWindow draw method
// Draw a window on compositing canvas
// dest - address of the canvas
//------------------------------------------------------------------------------

procedure TWindow32.draw(dest:integer);

var dt,dg,dh,dx,dy,dx2,dy2,dl,dsh,dsv,i,j,c,ct,a,dm:integer;
   dxr,dyr:integer;
   wt1:int64;
   q1,q2,q3:integer;
   hsw,vsh,hsp,vsp:integer;
   rectangle:PRectangle;

begin
redraw:=false; // tell the other procedures that the drawing is on its way
if decoration=nil then  // adjust window dimensions
  begin
  dg:=0;
  dh:=0;
  dt:=0;
  dl:=0;
  dsh:=0;
  dsv:=0;
  hsw:=0;
  vsh:=0;
  hsp:=0;
  vsp:=0;
  end
else
  begin
  dt:=titleheight;
  dl:=borderwidth;
  dg:=borderwidth;
  dh:=borderwidth;
  if decoration.hscroll then dsh:=scrollwidth else dsh:=0;
  if decoration.vscroll then dsv:=scrollwidth else dsv:=0;
  if decoration.menu then dm:=menuheight else dm:=0;
  if not virtualcanvas then
    begin
    hsw:=round((l/wl)*l); if hsw<11 then hsw:=10;
    vsh:=round((h/wh)*h); if vsh<11 then vsh:=10;
    hsp:=round((vx/(wl-l))*(l-hsw));
    vsp:=round((vy/(wh-h))*(h-vsh));
    end
  else
    begin
    hsw:=round((l/vcl)*l); if hsw<11 then hsw:=10;
    vsh:=round((h/vch)*h); if vsh<11 then vsh:=10;
    hsp:=round((vcx/(vcl-l))*(l-hsw));
    vsp:=round((vcy/(vch-h))*(h-vsh));
    end;
  end;



//if self=background then begin fastmove(mainscreen,dest,xres*yres); end
//else
  begin

  if buttons<>nil then buttons.draw;                      // update the wigdets

  // instead of full window, draw rectangles
 // if self is tpanel then blit8(integer(canvas),vx,vy,dest,x,y,l,h,wl,xres)
 // else
  begin
  rectangle:=@arectangle;
  repeat
//    wt1:=gettime;

    repeat rectangle:=rectangle^.next until (rectangle^.handle=integer(self.handle)) or (rectangle^.next=nil);
//    wt1:=gettime-wt1;
//    retromalina.box(0,0,100,32,0);retromalina.outtextxy(0,0,inttostr(wt1),15);
    if rectangle^.handle=integer(self.handle) then
      begin
      dxr:=rectangle^.x1-x;   // todo if dxr<0, correct the rectangle
      dyr:=rectangle^.y1-y;
      blit8(integer(canvas),vx+dxr,vy+dyr,dest,rectangle^.x1,rectangle^.y1, rectangle^.x2-rectangle^.x1+1,rectangle^.y2-rectangle^.y1+1,wl,xres);
      end;
  until rectangle^.next=nil;
  end;
//  blit8(integer(canvas),vx,vy,dest,x,y,l,h,wl,xres); // then blit the window to the canvas
  if next<>nil then                                       // and draw the decoration
    begin
    selected:=false;
    c:=inactivecolor;
    ct:=inactivetextcolor;
    a:=0;
    end
  else
    begin
    selected:=true;
    c:=activecolor;
    ct:=activetextcolor;
    a:=32
    end;
  if decoration<>nil then
    begin
    if (mousex>(x+l+dsv-60)) and (mousey>(y-titleheight-dm+4)) and (mousex<(x+l+dsv-44)) and (mousey<(y-4)-dm) then q1:=122 else q1:=0;
    if (mousex>(x+l+dsv-40)) and (mousey>(y-titleheight-dm+4)) and (mousex<(x+l+dsv-24)) and (mousey<(y-4-dm)) then q2:=122 else q2:=0;
    if (mousex>(x+l+dsv-20)) and (mousey>(y-titleheight-dm+4)) and (mousex<(x+l+dsv-4)) and (mousey<(y-4-dm)) then begin q3:=32; a:=32; end else q3:=0;
    if selected and (mx>(l+dsv-20)) and (my>(-titleheight-dm+4)) and (mx<(l+dsv-4)) and (my<(-4-dm)) and (mousek=1) then needclose:=true;


      fill2d(dest,x-dl,y-dt-dm-dl,l+dl+dsv,dl,xres,c+borderdelta);         //upper border

      fill2d(dest,x-dl,y-dt-dm,l+dl+dsv,dt,xres,c);                        //title bar
      fill2d(dest,x-dl,y-dm,l+dl+dsv,dm,xres,menucolor);                        //menu

      if (decoration.menu) and (menu<>nil) then menu.checkall(dest);
      fill2d(dest,x-dl,y-dt-dl-dm,dl,h+dt+dl+dsh+dh+dm,xres,c+borderdelta);   //left border
      fill2d(dest,x-dl,y+h+dsh,l+dl+dg+dsv,dh,xres,c+borderdelta);      //lower border
      fill2d(dest,x+l+dsv,y-dt-dl-dm,dg,h+dt+dl+dsh+dl+dm,xres,c+borderdelta);//right border

      fill2d(dest,x,y+h,l,dsh,xres,scrollcolor);                        //horizontal scroll bar
      fill2d(dest,x+3+hsp,y+h+3,hsw-6,dsh-6,xres,activescrollcolor);    //horizontal scroll bar active part

      fill2d(dest,x+l,y,dsv,h,xres,scrollcolor);                        //vertical scroll bar
      fill2d(dest,x+l+3,y+3+vsp,dsv-6,vsh-6,xres,activescrollcolor);    //vertical scroll bar active part


      fill2d(dest,x+l,y+h,dsv,dsh,xres,c);                  //down right corner
      gouttextxy(pointer(dest),x+32,y-titleheight-dm+4,title,ct);


    for i:=0 to 15 do for j:=0 to 15 do if down_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-60+i,y-titleheight-dm+4+j,down_icon[i+16*j]);
    if q1<>0 then
       for i:=0 to 15 do
         for j:=0 to 15 do
           if down_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-60+i,y-titleheight-dm+4+j,down_icon[i+16*j])
                                  else gputpixel(pointer(dest),x+l+dsv-60+i,y-titleheight-dm+4+j,q1);
    if q2<>0 then
       for i:=0 to 15 do
         for j:=0 to 15 do
           if up_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-40+i,y-titleheight-dm+4+j,up_icon[i+16*j])
                                else gputpixel(pointer(dest),x+l+dsv-40+i,y-titleheight-dm+4+j,q2)
    else for i:=0 to 15 do for j:=0 to 15 do if up_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-40+i,y-titleheight-dm+4+j,up_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if close_icon[i+16*j]>0 then gputpixel(pointer(dest),x+l+dsv-20+i,y-titleheight-dm+4+j,a+q3+close_icon[i+16*j]);
    for i:=0 to 15 do for j:=0 to 15 do if icon[i,j]>0 then gputpixel(pointer(dest),x+4+i,y-titleheight-dm+4+j,icon[i,j]);
    end;
  end;
  redraw:=true;
wt1:=gettime-wt;
end;


//------------------------------------------------------------------------------
// TWindow move method
// move and resize the window
// ax,ay - new position on screen if >-2048
// al,ah - new visible dimensions without decoration if >0
// avy,avy - new upper left visible canvas pixel if >-1
//------------------------------------------------------------------------------

procedure TWindow32.move(ax,ay,al,ah,avx,avy:integer);

var q:integer;

begin
if ay>yres-25 then ay:=yres-25;
if al>0 then begin l:=al; end;        // now set new window parameters
if ah>0 then begin h:=ah; end;

q:=8*length(title)+96;
if (decoration<>nil) and (al>0) and (al<q) then l:=q;
if (ah>0) and (ah<64) then h:=64;
if al>wl then l:=wl;
if ah>wh then h:=wh;

if ax>-2048 then begin x:=ax; end;
if ay>-2048 then begin y:=ay; end;
if avx>-1 then vx:=avx;
if avy>-1 then vy:=avy;

end;


//------------------------------------------------------------------------------
// Twindow checkmouse function
// This function should be called every vblank for the background window
// Called for any window returns the window handler for the window on which
// there is the mouse cursor and reacts to events:
// by selecting, resizing or moving the clicked window
//------------------------------------------------------------------------------

function TWindow32.checkmouse:TWindow;

label p999;

var window:TWindow;
    mmx,mmy,mmk,mmw,dt,dg,dh,dl,dsh,dsv,dm:integer;
    i,j,x1,y1,x2,y2,q,q2,sy2,vcount,rcount:integer;

    ttttt:int64;
      rect,r2:PRectangle;

const state:integer=0;
      deltax:integer=0;
      deltay:integer=0;
      sx:integer=0;
      sy:integer=0;
      hsw:integer=0;
      vsp:integer=0;
      vsh:integer=0;
      hsp:integer=0;
      oldhsp:integer=0;
      oldvsp:integer=0;

      qqqqq:integer=0;
begin

result:=background;

mmx:=mousex;
mmy:=mousey;
mmk:=mousek;
mmw:=mousewheel;

if mmk=0 then
  begin
  state:=6;
  window:=background;
  while (window.next<>nil) do begin window.mk:=0; window:=window.next; end;
  end;

// if mouse key pressed and there is a window set to move, move it

if mmk=1 then // find a window with mk=1
  begin
  window:=background;
  while (window.next<>nil) and (window.mk<>1) do window:=window.next;

  if window.mk=1 then
    begin


    if state=0 then window.move(mmx-window.mx,mmy-window.my,0,0,-1,-1)
    else if state=1 then
      begin
      q:=mmx-window.x+deltax;
      if q+window.vx>window.wl then begin window.vx:=window.wl-q; if window.vx<0 then begin window.vx:=0; q:=window.wl; end; end;
      window.move(window.x,window.y, q ,window.h,-1,-1)
      end
    else if state=2 then
      begin
       q:=mmy-window.y+deltay;
       if q+window.vy>window.wh then begin window.vy:=window.wh-q; if window.vy<0 then begin window.vy:=0; q:=window.wh; end; end;
       window.move(window.x,window.y, window.l, q,-1,-1)
       end

    else if state=3 then
      begin
      q:=mmx-window.x+deltax;
      if q+window.vx>window.wl then begin window.vx:=window.wl-q; if window.vx<0 then begin window.vx:=0; q:=window.wl; end; end;
      q2:=mmy-window.y+deltay;
      if q2+window.vy>window.wh then begin window.vy:=window.wh-q2; if window.vy<0 then begin window.vy:=0; q2:=window.wh; end; end;


      window.move(window.x,window.y, q ,q2, -1, -1)
      end
    else if state=4 then
      begin
      if not window.virtualcanvas then
        begin
        q:=round((mmy-window.y-sy)*(window.wh-window.h)/(window.h-vsh));
        if q<0 then q:=0;
        if q>window.wh-window.h then q:=window.wh-window.h;
        window.move(window.x,window.y,0,0,-1,q);
        end
      else
        begin
        q:=round((mmy-window.y-sy)*(window.vch-window.h)/(window.h-vsh));
        if q<0 then q:=0;
        if q>window.vch-window.h then q:=window.vch-window.h;
        window.vcy:=q;
        end;
      end
    else if state=5 then
      begin
      if not window.virtualcanvas then
        begin
        q:=round((mmx-window.x-sx)*(window.wl-window.l)/(window.l-hsw));
        if q<0 then q:=0;
        if q>window.wl-window.l then q:=window.wl-window.l;
        window.move(window.x,window.y,0,0,q,-1);
        end
      else
        begin
        q:=round((mmx-window.x-sx)*(window.vcl-window.l)/(window.l-hsw));
        if q<0 then q:=0;
        if q>window.vcl-window.l then q:=window.vcl-window.l;
        window.vcx:=q;
        end;
      end;
    result:=window;
 //   getrectanglelist;
    goto p999;
    end;
  end;

// we are here if mousekey=0 or there is no windows to move



window:=background;
while window.next<>nil do  window:=window.next;


if window.decoration=nil then
  begin
  dg:=0;
  dh:=0;
  dt:=0;
  dl:=0;
  dsh:=0;
  dsv:=0;
  dm:=0;
  end
else
  begin
  dt:=titleheight;
  dl:=borderwidth;
  dg:=borderwidth;
  dh:=borderwidth;
  if window.decoration.menu then dm:=menuheight else dm:=0;
  if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
  if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
  end;

// go back with windows chain until you found the window on which there is the mouse cursor

while ((mmx<window.x-dg) or (mmx>window.x+window.l+dg+dsv) or (mmy<window.y-dt-dg-dm) or (mmy>window.y+window.h+dh+dsh)) and (window.prev<>nil) do
  begin
  window.mx:=-1;
  window.my:=-1;
  window.mk:=-1;
  window:=window.prev;

  if window.decoration=nil then
    begin
    dg:=0;
    dh:=0;
    dt:=0;
    dl:=0;
    dsh:=0;
    dsv:=0;
    dm:=0;
    end
  else
    begin
    dt:= titleheight;
    dl:=borderwidth;
    dg:=borderwidth;
    dh:=borderwidth;
    if window.decoration.menu then dm:=menuheight else dm:=0;
    if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
    if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
    end
  end;
result:=window;

// todo: HERE::::: check all widgets on this window !!!
if window.buttons<> nil then window.buttons.checkall;
// now, here no windows to move and window=window to select
// if the window is not selected, select it

if (mmk=1) and (window.mk=0) then

  if semaphore=false then window.select;

//and set mouse correction amount
window.mx:=mmx-window.x;
window.my:=mmy-window.y;
window.mk:=mmk;
if not window.virtualcanvas then
  begin
  hsw:=round((window.l/window.wl)*window.l); if hsw<11 then hsw:=10;
  vsh:=round((window.h/window.wh)*window.h); if vsh<11 then vsh:=10;
  hsp:=round((window.vx/(window.wl-window.l))*(window.l-hsw));
  vsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh));
  end
else
  begin
  hsw:=round((window.l/window.vcl)*window.l); if hsw<11 then hsw:=10;
  vsh:=round((window.h/window.vch)*window.h); if vsh<11 then vsh:=10;
  hsp:=round((window.vcx/(window.vcl-window.l))*(window.l-hsw));
  vsp:=round((window.vcy/(window.vch-window.h))*(window.h-vsh));
  end;

// now set the state according to clicked area
if (not(window.resizable)) and (mmy>window.y+window.activey) then begin state:=6; goto p999; end;

if not(window.resizable) or ((mmx<(window.x+window.l)) and (mmy<(window.y-dm{window.h}))) then begin state:=0; deltax:=0; deltay:=0 end      // window

else if (mmx<(window.x+window.l)) and (mmy<(window.y)) then begin state:=7; deltax:=0; deltay:=0 end      // window

else if (mmx<(window.x+window.l)) and (mmy<(window.y + window.h )) then begin state:=6; deltax:=0; deltay:=0 end      // window
else if (mmx>=(window.x+window.l)) and (mmx<(window.x+window.l+scrollwidth-1)) and (mmy<(window.y+vsp+vsh-3)) and (mmy>(window.y+vsp+3)) then
  begin
  state:=4;
  if not window.virtualcanvas then oldvsp:=round((window.vy/(window.wh-window.h))*(window.h-vsh))
  else oldvsp:=round((window.vcy/(window.vch-window.h))*(window.h-vsh));
  sy:=mmy-window.y-vsp;
  end                                   // vertical scroll bar


else if (mmx>=(window.x+window.l)) and (mmy<(window.y+window.h)) then begin state:=1; deltax:=window.x+window.l-mmx; deltay:=0; end      // right border
else if (mmx<(window.x+hsp+hsw-3)) and (mmx>(window.x+hsp+3)) and (mmy>=(window.y+window.h)) and (mmy<(window.y+window.h+scrollwidth-1)) then
  begin
  state:=5;
  if not window.virtualcanvas then oldhsp:=round((window.vx/(window.wl-window.l))*(window.l-hsw))
  else oldhsp:=round((window.vcx/(window.vcl-window.l))*(window.l-hsw));
  sx:=mmx-window.x-hsp;
  end                               // horizontal scroll bar

else if (mmx<(window.x+window.l)) and (mmy>=(window.y+window.h)) then begin state:=2; deltax:=0; deltay:=window.y+window.h-mmy; end      // down border
else begin state:=3; deltax:=window.x+window.l-mmx; deltay:=window.y+window.h-mmy; end ;                                                 // corner
window.mstate:=state;
if mmw=129 then begin mousewheel:=128; q:=window.vy-16; if q<0 then q:=0; window.vy:=q; end;
if mmw=127 then begin mousewheel:=128; q:=window.vy+16; if q+window.h>window.wh then q:=window.wh-window.h; window.vy:=q; end;
if window is TFileselector then TFileselector(window).checkselected;
p999:
end;


//------------------------------------------------------------------------------
// TWindow resize method
// Resize the window canvas
//------------------------------------------------------------------------------


procedure TWindow32.resize(nwl,nwh:integer);

label p999;

var gd,gd2:pointer;
    bl,bh:integer;
    i:integer;

begin
if (nwl=wl) and (nwh=wh) then goto p999; // nothing to resize
gd:=getmem(nwl*nwh);
for i:=0 to nwl*nwh-1 do poke(integer(gd)+i,bg);
if nwl>wl then bl:=wl else bl:=nwl;
if nwh>wh then bh:=wh else bh:=nwh;
blit(integer(canvas),0,0,integer(gd),0,0,bl,bh,wl,nwl);
gd2:=canvas;
canvas:=gd;
wl:=nwl; wh:=nwh;
waitvbl;
waitvbl;
freemem(gd2);
if l>wl then l:=wl;
if h>wh then h:=wh;
if vx+l>wl then vx:=wl-l;
if vy+h>wh then vy:=wh-h;
p999:
end;

//------------------------------------------------------------------------------
// TWindow select method
// select the window and place it on top
//------------------------------------------------------------------------------

procedure Twindow32.select;

var who,whh:TWindow32;

begin
who:=background32;
while who.next<>nil do begin who.selected:=false; who:=who.next; end;
who:=self;
if (who.next<>nil) and (who<>background32) then
  begin
  who.prev.next:=who.next;
  who.next.prev:=who.prev;
  whh:=who;
  repeat whh:=whh.next until whh.next=nil;
  who.next:=nil;
  who.prev:=whh;
  whh.next:=who;
  end;
selected:=true;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TWindow graphic methods
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// cls - clear window and fill with color

procedure TWindow32.cls(c:integer);

var i,al:integer;

begin
box(0,0,wl,wh,c);
bg:=c;
end;


//putpixel - put a pixel to window at ay, ay position in color color

procedure TWindow32.putpixel(ax,ay,color:integer); inline;

label p999;

var adr:integer;

begin
if (ax<0) or (ax>=wl) or (ay<0) or (ay>wh) then goto p999;
adr:=cardinal(canvas)+ax+wl*ay;
poke(adr,color);
p999:
end;


// getpixel - get a pixel color at position ax, ay

function TWindow32.getpixel(ax,ay:integer):integer; inline;

label p999;

var adr:integer;

begin
if (ax<0) or (ax>=wl) or (ay<0) or (ay>wh) then goto p999;
adr:=cardinal(canvas)+ax+wl*ay;
result:=peek(adr);
p999:
end;


// putchar - put a 8x16 char ch on the window at ax,ay with color col
// The char definitions are in SystemFont array

procedure TWindow32.putchar(ax,ay:integer;ch:char;col:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      putpixel(ax+j,ay+i,col);
    end;
  end;
end;

procedure TWindow32.putchar8(ax,ay:integer;ch:char;col:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 7 do
  begin
  b:=atari8font[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (128 shr j))<>0 then
      putpixel(ax+j,ay+i,col);
    end;
  end;
end;

// putcharz - put a zoomed char, xz,yz - zoom

procedure TWindow32.putcharz(ax,ay:integer;ch:char;col,xz,yz:integer);


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
           putpixel(ax+j*xz+ll,ay+i*yz+k,col);
    end;
  end;
end;


// outtextxy - output a string from x,y position; c-color

procedure TWindow32.outtextxy(ax,ay:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar(ax+8*i-8,ay,t[i],c);
end;

procedure TWindow32.outtextxy8(ax,ay:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do putchar8(ax+8*i-8,ay,t[i],c);
end;



// outtextxyz - output a zoomed string

procedure TWindow32.outtextxyz(ax,ay:integer; t:string;c,xz,yz:integer);

var i:integer;

begin
for i:=0 to length(t)-1 do putcharz(ax+8*xz*i,ay,t[i+1],c,xz,yz);
end;

procedure TWindow32.print(line:string);

var i:integer;

begin
for i:=1 to length(line) do
  begin
  box(8*tcx,16*tcy,8,16,bg);
  putchar(8*tcx,16*tcy,line[i],tc);
  tcx+=1;
  if tcx>=(wl div 8) then
    begin
    tcx:=0;
    tcy+=1;
    if tcy>=(wh div 16) then
      begin
      // scrollup;  //todo - add this
      tcy:=(wh div 16) -1;
      end;
    end;
  end;
end;

procedure TWindow32.println(line:string);

begin
print(line);
tcy+=1;
tcx:=0;
if tcy>=(wh div 16) then
  begin
  //scrollup;
  tcy:=(wh div 16) -1;
  end;
end;

// box - draw a filled box

procedure TWindow32.box(ax,ay,al,ah,c:integer);

label p101,p102,p999;

var screenptr:cardinal;
    xres,yres:integer;

begin

screenptr:=integer(canvas);
xres:=wl;
yres:=wh;
if ax<0 then begin al:=al+ax; ax:=0; if al<1 then goto p999; end;
if ax>=xres then goto p999;
if ay<0 then begin ah:=ah+ay; ay:=0; if ah<1 then goto p999; end;
if ay>=yres then goto p999;
if ax+al>=xres then al:=xres-ax;
if ay+ah>=yres then ah:=yres-ay;


             asm
             push {r0-r6}
             ldr r2,ay
             ldr r3,xres
             ldr r1,ax
             mul r3,r3,r2
             ldr r4,al
             add r3,r1
             ldr r0,screenptr
             add r0,r3
             ldrb r3,c
             ldr r6,ah

p102:        mov r5,r4
p101:        strb r3,[r0],#1  // inner loop
             subs r5,#1
             bne p101
             ldr r1,xres
             add r0,r1
             sub r0,r4
             subs r6,#1
             bne p102

             pop {r0-r6}
             end;

p999:
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TPanel methods
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------


constructor TPanel.create;

var i,j:integer;

begin
  handle:=self;
  x:=0;
  y:=yres-25;
  mx:=-1;
  my:=-1;
  mk:=0;
  vx:=0;
  vy:=0;
  l:=xres;
  h:=25;
  bg:=11;
  wl:=l;
  wh:=h;
  buttons:=nil;
  next:=nil;
  visible:=false;
  resizable:=false;
  prev:=nil;
  canvas:=getmem(wl*wh);
  for i:=0 to wl*wh-1 do poke(cardinal(canvas)+i,bg);
  decoration:=nil;
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TFileSelector methods
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Constructor. A starting directory as a parameter
//------------------------------------------------------------------------------


constructor TFileselector.create(adir:string);


var who:TWindow;
    i,j:integer;

begin
semaphore:=true;
mstate:=0;
who:=background;
while who.next<>nil do who:=who.next;
dir:=adir;
handle:=self;
x:=0;
y:=0;
mx:=-1;
my:=-1;
mk:=0;
vx:=0;
vy:=0;
l:=0;
h:=0;
bg:=0;
wl:=480;
wh:=500;
canvas:=getmem(wl*wh);
dirlist;
makeicon;
buttons:=nil;
next:=nil;
visible:=false;
resizable:=true;
prev:=who;
title:=copy (adir,1,48);
decoration:=TDecoration.create;
decoration.title:=getmem(wl*titleheight);
decoration.hscroll:=true;
decoration.vscroll:=true;
decoration.up:=true;
decoration.down:=true;
decoration.close:=true;
who.next:=self;
semaphore:=false;
end;


//------------------------------------------------------------------------------
// TFileselector dirlist method
// Lists a directory in the file selector
// To be called when there is a need to change directory
//------------------------------------------------------------------------------


procedure TFileselector.dirlist;

var c:char;
    i,j:integer;
    dd:boolean;

begin
for c:='C' to 'F' do drivetable[c]:=directoryexists(c+':\');
currentdir2:=dir;
setcurrentdir(currentdir2);
currentdir2:=getcurrentdir;
if copy(currentdir2,length(currentdir2),1)<>'\' then currentdir2:=currentdir2+'\';
s:=currentdir2;
ilf:=0;
if length(currentdir2)=3 then
for c:='A' to 'Z' do
  begin
  if drivetable[c] then
    begin
    filenames[ilf,0]:=c+':\';
    filenames[ilf,1]:='(DIR)';
    ilf+=1;
    end;
  end;

currentdir:=currentdir2+'*';
if findfirst(currentdir,fadirectory,sr)=0 then
  repeat
  if (sr.attr and faDirectory) = faDirectory then
    begin
    filenames[ilf,0]:=sr.name;
    filenames[ilf,1]:='(DIR)';
    ilf+=1;
    end;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

// ntfs no .. patch

dd:=false;
for i:=0 to ilf do if filenames[i,0]='..' then dd:=true;
if (not dd) and (length(currentdir2)>3) then
  begin
  filenames[ilf,0]:='..';
  filenames[ilf,1]:='(DIR)';
  ilf+=1;
  end;

currentdir:=currentdir2+'*.*';
if findfirst(currentdir,$20,sr)=0 then
  repeat
  filenames[ilf,0]:=sr.name;
  filenames[ilf,1]:='z';
  filenames[ilf,2]:=inttostr(sr.size);
  ilf+=1;
  until (findnext(sr)<>0) or (ilf=1000);
sysutils.findclose(sr);

sort;
bg:=147;
j:= 16*ilf+16;
if j<500 then j:=500;
resize(480,j) ;
vx:=0; vy:=0;
if wh<500 then h:=wh else h:=500;
cls(bg);
for i:=0 to ilf-1 do
  begin
  s:=filenames[i,0];
  if length(s)>40 then begin s:=copy(s,1,40); {l:=40;} end;
  for j:=1 to length(s) do if s[j]='_' then s[j]:=' ';
  if filenames[i,1]<>'(DIR)' then if length(filenames[i,2])<10 then for j:=10 downto length(filenames[i,2])+1 do filenames[i,2]:=' '+filenames[i,2];
  if filenames[i,1]<>'(DIR)' then filenames[i,2]:=copy(filenames[i,2],1,1)+' '+copy(filenames[i,2],2,3)+' '+copy(filenames[i,2],5,3)+' '+copy(filenames[i,2],8,3);

  if filenames[i,1]<>'(DIR)' then begin outtextxy(8,8+16*i,s,157);  outtextxy(360,8+16*i,filenames[i,2],157);   end;
  if filenames[i,1]='(DIR)' then begin outtextxy(8,8+16*i,s,157);  outtextxy(400,8+16*i,'(DIR)',157);   end;
  end;
sel:=0; selstart:=0;
end;


//------------------------------------------------------------------------------
// TFileselector sort method
// A simple bubble sort for filenames
// -----------------------------------------------------------------------------


procedure TFileselector.sort;

var i,j:integer;
    s1,s2,s3:string;

begin
repeat
  j:=0;
  for i:=0 to ilf-2 do
    begin
    if (copy(filenames[i,0],3,1)<>'\') and (lowercase(filenames[i,1]+filenames[i,0])>lowercase(filenames[i+1,1]+filenames[i+1,0])) then
      begin
      s1:=filenames[i,0]; s2:=filenames[i,1]; s3:=filenames[i,2];
      filenames[i,0]:=filenames[i+1,0];
      filenames[i,1]:=filenames[i+1,1];
      filenames[i,2]:=filenames[i+1,2];
      filenames[i+1,0]:=s1; filenames[i+1,1]:=s2; filenames[i+1,2]:=s3;
      j:=1;
      end;
    end;
until j=0;
end;


//------------------------------------------------------------------------------
// TFileselector checkselected method;
// On clicks, select a file entry
// On double click, set filename variable to clicked file name
//------------------------------------------------------------------------------

procedure TFileselector.checkselected;

label p999;

var s1:string;
    sel1:integer;

begin
if dblclick then
  begin
  if filenames[sel,1]='(DIR)' then
    begin
    if copy(filenames[sel,0],2,1)<>':' then begin dir:=(currentdir2+filenames[sel,0]+'\'); dirlist; end
    else begin currentdir2:=filenames[sel,0] ; dir:=currentdir2; dirlist; end;
    title:=copy(currentdir2,1,48);
    end
  else filename:={lowercase}(currentdir2+filenames[sel,0]);
  end;

if mk=0 then goto p999;
sel1:=(my+vy-8) div 16;
if sel1=sel then goto p999;
if sel1>ilf-1 then goto p999;
if (my<8) or (my>h-8) then goto p999;
if (mx<4) or (mx>l-4) then goto p999;
box(4,16*sel+8,476,16,147);
s1:=filenames[sel,0];
if length(s1)>40 then begin s1:=copy(s1,1,40); end;
if filenames[sel,1]<>'(DIR)' then begin outtextxy(8,8+16*sel,s1,157);  outtextxy(360,8+16*sel,filenames[sel,2],157);   end;
if filenames[sel,1]='(DIR)' then begin outtextxy(8,8+16*sel,s1,157);  outtextxy(400,8+16*sel,'(DIR)',157);   end;

sel:=sel1;

box(4,16*sel+8,476,16,157);
s1:=filenames[sel,0];
if length(s1)>40 then begin s1:=copy(s1,1,40); end;
if filenames[sel,1]<>'(DIR)' then begin outtextxy(8,8+16*sel,s1,147);  outtextxy(360,8+16*sel,filenames[sel,2],147);   end;
if filenames[sel,1]='(DIR)' then begin outtextxy(8,8+16*sel,s1,147);  outtextxy(400,8+16*sel,'(DIR)',147);   end;
p999:
end;


//------------------------------------------------------------------------------
// TFileselector selectnext method
// A temporary method for selecting next entry in the file list
//------------------------------------------------------------------------------

procedure TFileselector.selectnext;

var s1:string;

begin
if sel<ilf-1 then
  begin
  sel:=sel+1;
  if filenames[sel,1]='(DIR)' then
    begin
    if copy(filenames[sel,0],2,1)<>':' then begin dir:=(currentdir2+filenames[sel,0]+'\'); dirlist; end
    else begin currentdir2:=filenames[sel,0] ; dir:=currentdir2; dirlist; end;
    title:=currentdir2;
    end
  else filename:=lowercase(currentdir2+filenames[sel,0]);

  box(4,16*sel-8,476,16,147);
  s1:=filenames[sel-1,0];
  if length(s1)>40 then begin s1:=copy(s1,1,40); end;
  if filenames[sel-1,1]<>'(DIR)' then begin outtextxy(8,8+16*sel-16,s1,157);  outtextxy(360,8+16*sel-16,filenames[sel-1,2],157);   end;
  if filenames[sel-1,1]='(DIR)' then begin outtextxy(8,8+16*sel-16,s1,157);  outtextxy(400,8+16*sel-16,'(DIR)',157);   end;
  box(4,16*sel+8,476,16,157);
  s1:=filenames[sel,0];
  if length(s1)>40 then begin s1:=copy(s1,1,40); end;
  if filenames[sel,1]<>'(DIR)' then begin outtextxy(8,8+16*sel,s1,147);  outtextxy(360,8+16*sel,filenames[sel,2],147);   end;
  if filenames[sel,1]='(DIR)' then begin outtextxy(8,8+16*sel,s1,147);  outtextxy(400,8+16*sel,'(DIR)',147);   end;
  end;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Window decoration
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


// Constructor

constructor TDecoration.create;

begin
inherited create;
title:=nil;
hscroll:=false;
vscroll:=false;
up:=false;
down:=false;
close:=false;
end;


// Destructor

destructor TDecoration.destroy;

begin
if title<>nil then freemem(title);
end;

procedure TDecoration.draw;

var c,ct,a,q1,q2,q3,dest,dsv,dsh,dm:cardinal;
    dt,dl2,dg,dh2,x,y,l,h:integer;
    hsp,vsh,vsp,hsw:integer;

begin
end;


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TWidget - universal widget class
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

procedure TWidget.draw;

begin
if self is Tbutton then TButton(self).draw;
end;

procedure TWidget.checkall;

begin
if self is Tbutton then TButton(self).checkall;
end;


//------------------------------------------------------------------------------
// TWidget setparent, setdesc methods - set the parent/descendent in the widget chain
//------------------------------------------------------------------------------

procedure TWidget.setparent(parent:TWidget);

begin
prev:=parent;
end;

procedure TWidget.setdesc(desc:TWidget);

begin
next:=desc;
end;


//------------------------------------------------------------------------------
// TWidget gofirst - find the first widget in the widget chain
//------------------------------------------------------------------------------

function TWidget.gofirst:TWidget;

begin
result:=self;
while result.prev<>nil do result:=result.prev;
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TButton - a button widget
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// TButton constructor
// Parameters: ax,ay: position in window
// al,ah - width and height
// ac1 - button main color
// ac2 - button text color
// aname - text on the button
// g - windows on which the button will be displayed
// todo: icon
//------------------------------------------------------------------------------

constructor TButton.create(ax,ay,al,ah,ac1,ac2:integer;aname:string;g:TWindow);

begin
inherited create;
x:=ax; y:=ay; l:=al; h:=ah; c1:=ac1; c2:=ac2; s:=aname;
canvas:=getmem(4*al*ah);
granny:=g;
if granny.buttons=nil then granny.buttons:=self;
visible:=false; highlighted:=false; selected:=false; radiobutton:=false;
selectable:=false; down:=false;
next:=nil; prev:=nil;
fsx:=1; fsy:=1;
radiogroup:=0;
self.show;
end;


//------------------------------------------------------------------------------
// TButton destructor
//------------------------------------------------------------------------------


destructor TButton.destroy;

begin
if visible then hide;
freemem(canvas);
if (prev=nil) and (next<>nil) then next.setparent(nil)
else if next<>nil then next.setparent(prev);
if (next=nil) and (prev<>nil) then prev.setdesc(nil)
else if prev<>nil then prev.setdesc(next);
if prev=nil then granny.buttons:=nil;
inherited destroy;
end;

//------------------------------------------------------------------------------
// TButton append function
// Creates a button and appends it to the widget chain
//------------------------------------------------------------------------------

function TButton.append(ax,ay,al,ah,ac1,ac2:integer;aname:string):TButton;

var temp:TWidget;
    temp2:TButton;

begin
temp:=self;
while temp.next<>nil do temp:=temp.next;
temp.next:=TButton.create(ax,ay,al,ah,ac1,ac2,aname,temp.granny);
next.setparent(temp);
temp2:=TButton(temp.next);
result:=temp2; //:=temp.next;
temp2.fsx:=fsx;
temp2.fsy:=fsy;                                                  // font size x,y
temp2.draw;
end;

//------------------------------------------------------------------------------
// TButton checkmouse method
// Check if the mouse cursor is on the button
//------------------------------------------------------------------------------

function TButton.checkmouse:boolean;

var mx,my:integer;

begin
mx:=mousex-granny.x+granny.vx;
my:=mousey-granny.y+granny.vy;
if {((background.checkmouse=granny) or (granny=panel)) and }((granny.mstate=0) or (granny.mstate=6)) and (my>y) and (my<y+h) and (mx>x) and (mx<x+l) then checkmouse:=true else checkmouse:=false;
end;


//------------------------------------------------------------------------------
// TButton highlight metod - highlight the button
//------------------------------------------------------------------------------

procedure TButton.highlight;

var c:integer;

begin
if visible and not highlighted then begin
  c1+=2;
  draw;
  highlighted:=true;
  end;
end;

//------------------------------------------------------------------------------
// TButton unhighlight metod - restore the button's normal color
//------------------------------------------------------------------------------


procedure TButton.unhighlight;

begin

if visible and highlighted then begin
  c1-=2;
  draw;
  highlighted:=false;
  end;
end;


//------------------------------------------------------------------------------
// TButton show metod - make a button visible. Obsolete in this version
// The visible atribute change now changes visibility without need to call this
//------------------------------------------------------------------------------

procedure TButton.show;

var i,j,k:integer;
    p:^integer;

begin
if not visible then
  begin
  p:=canvas;
  k:=0;
  for i:=y to y+h-1 do
    for j:=x to x+l-1 do
      begin
      (p+k)^:=granny.getpixel(j,i);
      k+=1;
      end;
  draw;
  visible:=true;
  end;
end;

//------------------------------------------------------------------------------
// TButton hide metod - make a button disappear. Obsolete in this version
//------------------------------------------------------------------------------

procedure TButton.hide;

var i,j,k:integer;
    p:^integer;

begin
if visible then begin
  p:=canvas;
  k:=0;
  for i:=y to y+h-1 do
    for j:=x to x+l-1 do
      begin
      granny.putpixel(j,i,(p+k)^);
      k+=1;
      end;
  visible:=false;
  end;
end;


//------------------------------------------------------------------------------
// TButton select method.
// -----------------------------------------------------------------------------

procedure TButton.select;

// TODO: use radiobutton groups

var c:integer;
    temp:TButton;

begin
if visible and selectable and not selected then begin
  selected:=true;
  draw;
  temp:=self;
  while temp.prev<>nil do
    begin
    temp:=tbutton(temp.prev);
    if temp.radiogroup=self.radiogroup then temp.unselect;
    end;
  temp:=self;
  while temp.next<>nil do
    begin
    temp:=tbutton(temp.next);
    if temp.radiogroup=self.radiogroup then temp.unselect;
    end;
   end;
end;


//------------------------------------------------------------------------------
// TButton unselect method.
// -----------------------------------------------------------------------------

procedure TButton.unselect;

begin

if visible and selectable and selected then begin
  selected:=false;
  draw;
  end;
end;


//------------------------------------------------------------------------------
//TButton draw method
//------------------------------------------------------------------------------

procedure TButton.draw;

var l2,a:integer;

begin
if selected or down then a:=-2 else a:=2;
granny.box(x,y,l,h,c1+a);
granny.box(x,y+3,l-3,h-3,c1-a);
granny.putpixel(x,y+1,c1-a); granny.putpixel(x,y+2,c1-a); granny.putpixel(x+1,y+2,c1-a);
granny.putpixel(x+l-3,y+h-2,c1-a); granny.putpixel(x+l-3,y+h-1,c1-a); granny.putpixel(x+l-2,y+h-1,c1-a);
granny.box(x+3,y+3,l-6,h-6,c1);
l2:=length(s)*4*fsx;
granny.outtextxyz(x+(l div 2)-l2,y+(h div 2)-8*fsy,s,c2,fsx,fsy);
end;



//------------------------------------------------------------------------------
// TButton findselected - find the selected button in the widget chain
//------------------------------------------------------------------------------

function TButton.findselected:TButton;

// todo:use radiobutton groups

var temp:TButton;

begin
temp:=tbutton(self.gofirst);
while not (temp=nil) do
  begin
  if temp.selected then break else temp:=tbutton(temp.next);
  end;
result:=temp;
end;


//------------------------------------------------------------------------------
// TButton setvalue - set a value property of the button
//------------------------------------------------------------------------------

procedure TButton.setvalue(v:integer);

begin
value:=v;
end;


//------------------------------------------------------------------------------
// TButton checkall metod
// checks all widgets in the chain for events
// and reacts
//------------------------------------------------------------------------------

procedure TButton.checkall;

label p999;

var temp:TButton;
    cm:boolean;

begin
temp:=tbutton(self.gofirst);
while temp<>nil do
  begin
  cm:=temp.checkmouse;
  if cm and  temp.down and (mousek=0) then temp.clicked:=1;
  if cm and (mousek=0) then begin temp.down:=false; temp.highlight; end;
  if cm and (mousek=1) then begin temp.down:=true; temp.unhighlight;  end;
  if not cm then begin temp.down:=false; temp.unhighlight; end;
  if cm then dblclick;
  temp:=tbutton(temp.next);
  end;
p999:
end;


//------------------------------------------------------------------------------
// TButton box method
// draw a box on the button surface
//------------------------------------------------------------------------------

procedure TButton.box(ax,ay,al,ah,c:integer);

label p101,p102,p999;

var screenptr:cardinal;
    xres,yres:integer;

begin

screenptr:=integer(canvas);
xres:=l;
yres:=h;
if ax<0 then begin al:=al+ax; ax:=0; if al<1 then goto p999; end;
if ax>=xres then goto p999;
if ay<0 then begin ah:=ah+ay; ay:=0; if ah<1 then goto p999; end;
if ay>=yres then goto p999;
if ax+al>=xres then al:=xres-ax;
if ay+ah>=yres then ah:=yres-ay;


             asm
             push {r0-r6}
             ldr r2,ay
             ldr r3,xres
             ldr r1,ax
             mul r3,r3,r2
             ldr r4,al
             add r3,r1
             ldr r0,screenptr
             add r0,r3
             ldrb r3,c
             ldr r6,ah

p102:        mov r5,r4
p101:        strb r3,[r0],#1  // inner loop
             subs r5,#1
             bne p101
             ldr r1,xres
             add r0,r1
             sub r0,r4
             subs r6,#1
             bne p102

             pop {r0-r6}
             end;

p999:
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TIcon class
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


constructor TIcon.create(atitle:string; g:TWindow);
begin
inherited create;
title:=atitle;
granny:=g;
if granny.icons=nil then granny.icons:=self;
next:=nil; prev:=nil;
clicked:=false; dblclicked:=false;
highlighted:=false;
end;


function TIcon.append(atitle:string):TIcon;

var temp,temp2:TIcon;

begin
temp:=TIcon.create(atitle,granny);
temp2:=self;
while temp2.next<>nil do temp2:=temp2.next;
temp2.next:=temp;
temp.prev:=temp2;
result:=temp;
end;


procedure Ticon.draw;

var i,j,ll:integer;

begin
blit8(integer(granny.canvas),x,y,integer(@bg),0,0,128,96,granny.wl,128);
for i:=0 to 47 do
  for j:=0 to 47 do
    begin
    if icon48[j+48*i]<>0 then granny.putpixel(40+x+j,16+y+i,icon48[j+48*i]);
    end;
ll:=length(title);
if ll=15 then begin title:=copy(title,1,15); ll:=15; end;
granny.outtextxy(x+64-(ll *4),y+72,title,0);
granny.outtextxy(x+65-(ll *4),y+73,title,15);
end;

procedure TIcon.move(ax,ay:integer);

label p999;

var i,j:integer;

begin
if (ax=x) and (ay=y) then goto p999;
//moved:=0;
blit8(integer(@bg),0,0,integer(granny.canvas),x,y,128,96,128,granny.wl);
x:=ax; y:=ay; draw;
p999:
end;

function TIcon.checkmouse:boolean;

var mmx,mmy:integer;

begin
if granny<>background then
  begin
  mmx:=mousex-granny.x+granny.vx;
  mmy:=mousey-granny.y+granny.vy;
  end
else
  begin
  mmx:=mousex;
  mmy:=mousey;
  end;
if ((lastchecked=granny) or (granny=panel)) and (granny.mstate=0) and (mmy>y) and (mmy<y+h) and (mmx>x) and (mmx<x+l) then checkmouse:=true else checkmouse:=false;
end;

procedure TIcon.highlight;

var i,j,q,c1,c2,ll:integer;

begin
if not highlighted then
  begin
  highlighted:=true;
  blit8(integer(@bg),0,0,integer(granny.canvas),x,y,128,96,128,granny.wl);
  for i:=0 to 95 do
    begin
    for j:=0 to 127 do
      begin
      q:=granny.getpixel(x+j,y+i);
      c1:=q and $F0; c2:=q and $0F; c2:=c2 div 2; if c2<0 then c2:=0; q:=c1+c2;
      granny.putpixel(x+j,y+i,q);
      end;
    end;
  for i:=0 to 47 do
    for j:=0 to 47 do
      begin
      if icon48[j+48*i]<>0 then granny.putpixel(40+x+j,16+y+i,icon48[j+48*i]);
      end;
  ll:=length(title);
  if ll=15 then begin title:=copy(title,1,15); ll:=15; end;
  granny.outtextxy(x+64-(ll *4),y+72,title,0);
  granny.outtextxy(x+65-(ll *4),y+73,title,15);

  end;
end;

procedure TIcon.unhighlight;

var i,j,q,ll:integer;

begin
if highlighted then
  begin
  highlighted:=false;
  blit8(integer(@bg),0,0,integer(granny.canvas),x,y,128,96,128,granny.wl);
  for i:=0 to 47 do
    for j:=0 to 47 do
      begin
      if icon48[j+48*i]<>0 then granny.putpixel(40+x+j,16+y+i,icon48[j+48*i]);
      end;
  ll:=length(title);
  if ll=15 then begin title:=copy(title,1,15); ll:=15; end;
  granny.outtextxy(x+64-(ll *4),y+72,title,0);
  granny.outtextxy(x+65-(ll *4),y+73,title,15);
  end;
end;

procedure TIcon.arrange;

var temp,temp2:TIcon;
    ax,ay:integer;

begin
temp:=self;
while temp.next<>nil do temp:=temp.next;
ax:=128*round(temp.x/128);
ay:=96*round(temp.y/96);
temp2:=temp;
while temp2.prev<>nil do
  begin
  temp2:=temp2.prev;
  if (temp2.x=ax) and (temp2.y=ay) then
    begin
    ay:=ay+96;
    if ay>1100 then begin ay:=0; ax:=ax+128; end;
    end;
  end;
temp.move(ax,ay);
end;

procedure TIcon.checkall;

label p999;
var temp,temp3:TIcon;
mk:integer;
const state:integer=0;
      mmx:integer=0;
      mmy:integer=0;
      temp2:TIcon=nil;

begin
temp:=self;
mk:=mousek;
while temp.prev<>nil do temp:=temp.prev;
if mk=0 then state:=0;
if (state=0) then arrange;
if (state=1) and (mk=1) then
  begin
  temp2.unhighlight;
  temp2.move(mousex-temp2.mx,mousey-temp2.my);
  goto p999;
  end;

repeat
  if temp.checkmouse and dblclick then temp.dblclicked:=true;
  if temp.checkmouse and (mk=0) then
    begin
    temp.highlight;
    temp.mx:=mousex-temp.x;
    temp.my:=mousey-temp.y;
    while temp.next<>nil do begin temp:=temp.next; temp.unhighlight; end;
    goto p999;
    end
  else if temp.checkmouse and (mk=1) then
    begin
    if state=0 then
      begin
      state:=1;
      temp2:=temp;
      if temp2.prev<>nil then temp2.prev.next:=temp2.next else begin granny.icons:=temp2.next; granny.icons.prev:=nil; end;;
      if temp2.next<>nil then temp2.next.prev:=temp2.prev;
      temp3:=granny.icons; while temp3.next<>nil do temp3:=temp3.next;
      temp3.next:=temp2; temp2.prev:=temp3; temp2.next:=nil;
      end
    else
      begin
      temp.unhighlight;
      temp.move(mousex-temp.mx,mousey-temp.my);
      end;
    end
    else temp.unhighlight;
  temp:=temp.next;
until temp=nil;
p999:
end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// TMenu class
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------


//type TMenuItem=class(TObject)
//     title:string;
//     icon:TIcon;
//     next,prev,sub:TMenuItem;
//     x,y,l:integer;
//     level:integer;
//     visible:boolean;
//     selected:boolean;
//     highlighted:boolean;
//     clicked:boolean;
//////     constructor create(atitle:string);
//////     procedure append(atitle:string);
//////     procedure addsub(atitle:string);
//     procedure draw;
//     function checkmouse:boolean;
//     end;

//     TMenu=class (TObject)
//     item:TMenuItem;
//     granny:TWindow;
//     horizontal:boolean;
//     constructor create(g:TWindow);
//     procedure append(atitle:string);
//     procedure checkall;
//     end;


constructor TMenuItem.create(atitle:string; w:TWindow);

begin
title:=atitle;
x:=0;
y:=0;
l:=length(atitle)*8+16;
icon:=nil;
next:=nil; prev:=nil; sub:=nil;
level:=0;
visible:=false;
selected:=false;
clicked:=false;
highlighted:=false;
horizontal:=false;
granny:=w;
end;

function TMenuItem.append(atitle:string):TMenuItem;

var temp,temp2:TMenuItem;
    ll:integer;

begin
temp2:=self;
while temp2.next<>nil do temp2:=temp2.next;
temp:=TMenuItem.create(atitle,granny);
result:=temp;
if horizontal and (level=0) then temp.x:=temp2.x+l else temp.x:=temp2.x;
if horizontal and (level=0) then temp.y:=temp2.y else temp.y:=temp2.y+menuheight;
temp.prev:=temp2;
temp.granny:=granny;
temp2.next:=temp;
if level>0 then  // vertical menu length equalize
  begin
  ll:=l;
  temp2:=temp;
  while temp2.prev<>nil do
    begin
    if temp2.l>ll then ll:=temp2.l;
    temp2:=temp2.prev;
    end;
  while temp2.next<>nil do
    begin
    temp2.l:=ll;
    temp2:=temp2.next;
    end;
  end;
if horizontal and (level=0) then temp.visible:=true;
end;

function TMenuItem.addsub(atitle:string):TMenuItem;

var temp,temp2:TMenuItem;

begin
temp:=TMenuItem.create(atitle,granny);
temp.x:=x;
temp.y:=y+menuheight;
sub:=temp;
result:=temp;
end;

procedure TMenuItem.draw(dest:integer);

begin
if visible then
  begin
  if not highlighted then
    begin
    fill2d(dest,  granny.x+borderwidth+x,  granny.y-menuheight+y, l,menuheight, xres, menucolor);                 //menu
    gouttextxy(pointer(dest),granny.x+borderwidth+x+8,granny.y-menuheight+y+4,title,0);
    end
  else
    begin
    fill2d(dest,granny.x+borderwidth+x,granny.y-menuheight+y,l,menuheight,xres,0);                 //menu
    gouttextxy(pointer(dest),granny.x+borderwidth+x+8,granny.y-menuheight+y+4,title, menucolor);
    end;
  end;
end;

function tmenuitem.checkmouse:boolean;

begin
if granny.selected then
  begin
  if (granny.mx>x) and (granny.mx<x+l) and (granny.my>y-menuheight) and (granny.my<y) and granny.selected and visible then result:=true else result:=false;
  end;
end;

constructor TMenu.create(g:TWindow);

begin
horizontal:=true; //default
granny:=g;
item:=nil;
g.menu:=self;
end;


function tmenu.append(atitle:string):TMenuItem;

begin
item:=tmenuitem.create(atitle,granny);
item.granny:=granny;
item.horizontal:=horizontal;
if horizontal then item.visible:=true;
result:=item;
end;

procedure tmenu.checkall(dest:integer);

var temp,temp2:TMenuitem;

begin
//if granny.selected then begin

temp:=item;
while temp<>nil do
  begin
  if temp.visible then
    begin
    if granny.selected and temp.checkmouse then temp.highlighted:=true else temp.highlighted:=false;
    if (temp.checkmouse) and (mousek=1) then temp.clicked:=true;
    temp.draw(dest);
    if temp.sub<>nil then
      begin
      temp2:=temp.sub;
      if temp.checkmouse then
        begin
        while temp2.next<>nil do
          begin
          temp2.visible:=true;
          temp2:=temp2.next;
          end;
        temp2.visible:=true;
        temp2:=temp.sub
        end
      else
        begin
        while temp2.next<>nil do
          begin
          temp2.visible:=false;
          temp2:=temp2.next;
          end;
        temp2.visible:=false;
        temp2:=temp.sub
        end ;

      while temp2<>nil do
        begin
        if temp2.visible then
          begin
          if granny.selected and temp2.checkmouse then temp2.highlighted:=true else temp2.highlighted:=false;
          if (temp2.checkmouse) and (mousek=1) then temp.clicked:=true;
           temp2.draw(dest);
          end;
        temp2:=temp2.next;
        end;
      end;
    temp:=temp.next;
    end;
  end;


end;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Additional temporary helper procedures
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

// Put pixel on a non assigned canvas given by the pointer

procedure gputpixel(g:pointer; x,y,color:integer); inline;

label p999;

var adr:integer;

begin
if (x<0) or (x>=xres) or (y<0) or (y>yres) then goto p999;
adr:=cardinal(g)+x+xres*y;
poke(adr,color);
p999:
end;


// Put pixel on a non assigned canvas given by the pointer with pitch

procedure gpputpixel(g:pointer; x,y,color,pitch:integer); inline;

label p999;

var adr:integer;

begin
if (x<0) or (x>=xres) or (y<0) or (y>yres) then goto p999;
adr:=cardinal(g)+4*x+pitch*y;
lpoke(adr,color);
p999:
end;

// Put char on a non assigned canvas given by the pointer

procedure gputchar(g:pointer; x,y:integer;ch:char;col:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      gputpixel(g,x+j,y+i,col);
    end;
  end;
end;

procedure gpputchar(g:pointer; x,y:integer;ch:char;col,pitch:integer);


var i,j,start:integer;
  b:byte;

begin
for i:=0 to 15 do
  begin
  b:=systemfont[ord(ch),i];
  for j:=0 to 7 do
    begin
    if (b and (1 shl j))<>0 then
      gpputpixel(g,x+j,y+i,col,pitch);
    end;
  end;
end;


// Output a string on a non assigned canvas given by the pointer


procedure gouttextxy(g:Pointer;x,y:integer; t:string;c:integer);

var i:integer;

begin
for i:=1 to length(t) do gputchar(g,x+8*i-8,y,t[i],c);
end;

procedure gpouttextxy(g:Pointer;x,y:integer; t:string;c,pitch:integer);

var i:integer;

begin
for i:=1 to length(t) do gpputchar(g,x+8*i-8,y,t[i],c,pitch);
end;


// Make a temporary icon for a window from the red ball sprite

procedure makeicon;

var x,y,q:integer;

begin
for x:=0 to 15 do
  for y:=0 to 15 do
    begin
    q:=balls[2*x+2*y*32];
    if ((q shr 8) and 255) >= (q and 255) then icon[x,y]:=((q and 255) shr 4) else icon[x,y]:=32+(q and 255) shr 4;
    if q=0 then icon[x,y]:=0;
    end;
end;

//------------------------------------------------------------------------------
// Get a rectangle list
// Call this when windows moved, created or destroyed
//------------------------------------------------------------------------------


procedure getrectanglelist;

var rect,r2:PRectangle ;

    window:TWindow;
    dg,dh,dt,dl,dsh,dsv,dm:integer;
    x1,x2,y1,y2:integer;
    vcount,rcount:integer;
    lllll: integer;
    ttttt: int64;

begin

if arectangle.handle=0 then
  begin
  rect:=Arectangle.next;
  while rect^.next<>nil do rect:=rect^.next;
  while rect^.prev<>nil do begin rect:=rect^.prev; dispose(rect^.next); end;
  end;

window:=background;
Arectangle.next:=nil;
Arectangle.prev:=nil;
Arectangle.x1:=0;
Arectangle.x2:=0;
Arectangle.y1:=0;
Arectangle.y2:=0;
Arectangle.handle:=0;


vcount:=0;
ttttt:=gettime;
// go to the top window and count vertices

while window<>nil do
  begin

  if window.decoration=nil then
    begin
    dg:=0;
    dh:=0;
    dt:=0;
    dl:=0;
    dsh:=0;
    dsv:=0;
    dm:=0;
    end
  else
    begin
    dt:=titleheight;
    dl:=borderwidth;
    dg:=borderwidth;
    dh:=borderwidth;
    if window.decoration.menu then dm:=menuheight else dm:=0;
    if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
    if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
    end ;

  x1:=window.x-dg; x2:=window.x+window.l+dg+dsv; if x2>=xres then x2:=xres; if x1<0 then x1:=0;
  y1:=window.y-dg-dm-dt; y2:=window.y+window.h+dg+dsh; if y2>=yres then y2:=yres; if y1<0 then y1:=0;
  if vcount=0 then begin xtable[vcount]:=x1; ytable[vcount]:=y1; inc(vcount); end
  else
    begin
    i:=0;
    while (x1>xtable[i]) and (i<vcount) do i:=i+1;
    for j:=vcount downto i+1 do xtable[j]:=xtable[j-1];
    xtable[i]:=x1;
    i:=0;
    while (y1>ytable[i]) and (i<vcount) do i:=i+1;
    for j:=vcount downto i+1 do ytable[j]:=ytable[j-1];
    ytable[i]:=y1;
    inc(vcount);
    end;


  i:=0;
  while (x2>xtable[i]) and (i<vcount) do i:=i+1;
  for j:=vcount downto i+1 do xtable[j]:=xtable[j-1];
  xtable[i]:=x2;
  i:=0;
  while (y2>ytable[i]) and (i<vcount) do i:=i+1;
  for j:=vcount downto i+1 do ytable[j]:=ytable[j-1];
  ytable[i]:=y2;
  inc(vcount);

  window:=window.next;        // go to the top window
  end;

// delete duplicate vertices

i:=0;
repeat
  if (xtable[i]=xtable[i+1]) and (ytable[i]=ytable[i+1]) then
    begin
    for j:=i+1 to vcount-1 do
      begin
      xtable[j]:=xtable[j+1];
      ytable[j]:=ytable[j+1];
      end;
    xtable[vcount-1]:=0;
    ytable[vcount-1]:=0;
    vcount-=1;
    end;
  i:=i+1;
until i>=vcount-1;



// make a rectangle list

rect:=@Arectangle;
for i:=0 to vcount-2 do
  for j:=0 to vcount-2 do
    begin
    if (xtable[j+1]>xtable[j]) and (ytable[i+1]>ytable[i]) then
      begin
      rect^.next:= new(PRectangle);
      rect^.next^.prev:=rect;
      rect^.next^.next:=nil;
      rect:=rect^.next;
      rect^.x1:=xtable[j];
      rect^.y1:=ytable[i];
      rect^.x2:=xtable[j+1]-1;
      rect^.y2:=ytable[i+1]-1;
      rect^.handle:=0;
      end;
    end;


// assign rectangles to windows

window:=background;

// go to the top window

while window.next<>nil do  window:=window.next;

// find rectangles in the window

while window<>nil do
  begin
    if window.decoration=nil then
    begin
    dg:=0;
    dh:=0;
    dt:=0;
    dl:=0;
    dsh:=0;
    dsv:=0;
    dm:=0;
    end
  else
    begin
    dt:=titleheight;
    dl:=borderwidth;
    dg:=borderwidth;
    dh:=borderwidth;
    if window.decoration.menu then dm:=menuheight else dm:=0;
    if window.decoration.hscroll then dsh:=scrollwidth else dsh:=0;
    if window.decoration.vscroll then dsv:=scrollwidth else dsv:=0;
    end ;

  rect:=Arectangle.next;
  x1:=window.x-dg; x2:=window.x+window.l+dg+dsv;
  y1:=window.y-dg-dm-dt; y2:=window.y+window.h+dg+dsh;



  while rect<>nil do begin
    if (rect^.x1>=x1) and (rect^.y1>=y1)and (rect^.x2<x2) and (rect^.y2<y2) and (rect^.handle=0) then rect^.handle:=integer(window);
    rect:=rect^.next;
    end;

  window:=window.prev;
  end ;

// merge adjacent rectangles

  rect:=Arectangle.next;
  while rect^.next<>nil do
    begin
    if (rect^.x2+1=rect^.next^.x1) and (rect^.handle=rect^.next^.handle) then
      begin
      r2:=rect^.next;
      rect^.x2:=rect^.next^.x2;
      rect^.next:=rect^.next^.next;
      dispose(r2);
      if rect^.next<>nil then rect^.next^.prev:=rect;
      end
    else
      rect:=rect^.next;
    end;

// debug --- count the rectangles
rect:=Arectangle.next;
lllll:=1;
while rect^.next<>nil do
  begin
  lllll+=1;
  rect:=rect^.next;
  end;

retromalina.box(0,0,100,100,0);
retromalina.outtextxyz(16,16,inttostr(lllll),15,2,2);

ttttt:=gettime-ttttt;

//-------debug

{
retromalina.box(500,0,100,50,0); retromalina.outtextxy(500,0,inttostr(ttttt),15);
retromalina.box(0,0,380,1000,0);
for i:=0 to vcount-1 do background.outtextxy8(280,8*i,inttostr(xtable[i])+' '+inttostr(ytable[i]),15);
rect:=Arectangle.next;
i:=0;
while rect<>nil do begin
                                              retromalina.outtextxy(0,i*16,inttostr(rect^.x1),15);
                                              retromalina.outtextxy(50,i*16,inttostr(rect^.y1),15);
                                              retromalina.outtextxy(100,i*16,inttostr(rect^.x2),15);
                                              retromalina.outtextxy(150,i*16,inttostr(rect^.y2),15);
                                              retromalina.outtextxy(200,i*16,inttostr(rect^.handle),15);
rect:=rect^.next;  i:=i+1;
end;}


end;


//------------------------------------------------------------------------------
// The end of the unit
//------------------------------------------------------------------------------

end.


