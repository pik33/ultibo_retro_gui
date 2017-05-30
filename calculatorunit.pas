unit calculatorunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, math, threads, retromalina, mwindows;

type TCalculatorthread=class (TThread)

     private
     protected
       procedure Execute; override;
     public
       Constructor Create(CreateSuspended : boolean);
     end;


var cw:TWindow=nil;

implementation

operator mod(const a,b:double) c:double;inline;
begin
  c:= a-b * Int(a/b);
end;

constructor TCalculatorthread.create(CreateSuspended : boolean);

begin
FreeOnTerminate := True;
inherited Create(CreateSuspended);
end;



procedure TCalculatorthread.Execute;

var scr,a,c1,c2,x,y,l,h:integer;
    wh:TWindow;
    b00,b01,b02,b03,b04,b05,b06,b07,b08,b09:TButton;
    bpl,bmi,bmul,bdiv,beq,bc,bmr,bms,bsin,bcos, btan,blog,bsqrt,bdot,binv,batn:TButton;
    a1s,a2s,ws,ds:string;
    cstate:integer=0;
    a1,a2,w:double;
    opcode:integer=0;




procedure sadd(var s:string; c:char);

var i:integer;
    dot:boolean;

begin

if c<>'.' then if length(s)<12 then
  begin
  s:=s+c;
  if (s[1]='0') and (s[2]<>'.') then s:=copy(s,2,length(s)-1);
  end;
if c='.' then
  begin
  dot:=false;
  for i:=1 to length(s) do if s[i]='.' then dot:=true;
  if not dot then s:=s+'.';
  end;
end;

function translate(a:double):string;

var s:string;
    i,eformat:integer;

begin
  try
    s:=floattostr(a);
    eformat:=0;
    for i:=1 to length(s) do if (s[i]='e') or (s[i]='E') then eformat:=i;
    if eformat<>0 then s:=copy(s,1,11-(length(s)-eformat))+copy(s,eformat,length(s)-eformat+1)
    else s:=copy(s,1,12);
    if s[12]='.' then s:=copy(s,1,11);
  except
    s:='E';
  end;
result:=s;
end;



begin
ThreadSetAffinity(ThreadGetCurrent,4);
sleep(1);
cw:=Twindow.create(296,352,'Calculator');
cw.bg:=147;
cw.cls(147);
cw.decoration.hscroll:=false;
cw.decoration.vscroll:=false;
c1:=211; c2:=215;
a:=-2;
x:=8; y:=8; l:=280; h:=48;
cw.box(8,8,l,h,c1+a);
cw.box(8,8+3,l-3,h-3,c1-a);
cw.putpixel(x,y+1,c1-a); cw.putpixel(x,y+2,c1-a); cw.putpixel(x+1,y+2,c1-a);
cw.putpixel(x+l-3,y+h-2,c1-a); cw.putpixel(x+l-3,y+h-1,c1-a); cw.putpixel(x+l-2,y+h-1,c1-a);


b07:=Tbutton.create(8,64,52,52,150,158,'7',cw);
b07.fsx:=2; b07.fsy:=2; b07.draw;
b08:=b07.append(65,64,52,52,150,158,'8');
b09:=b08.append(122,64,52,52,150,158,'9');
b04:=b09.append(8,121,52,52,150,158,'4');
b05:=b04.append(65,121,52,52,150,158,'5');
b06:=b05.append(122,121,52,52,150,158,'6');
b01:=b06.append(8,178,52,52,150,158,'1');
b02:=b01.append(65,178,52,52,150,158,'2');
b03:=b02.append(122,178,52,52,150,158,'3');
bpl:=b03.append(179,64,52,52,150,158,'+');
bmi:=bpl.append(179,121,52,52,150,158,'-');
bmul:=bmi.append(179,178,52,52,150,158,'*');
b00:=bmi.append(8,235,52,52,150,158,'0');
bc:=bmi.append(236,64,52,52,36,46,'C');
bms:=bmi.append(236,121,52,52,164,172,'MS');
bmr:=bmi.append(236,178,52,52,164,172,'MR');
beq:=bmi.append(236,235,52,52,180,188,'=');

bdiv:=bmi.append(179,235,52,52,150,158,'/');
bdot:=bmi.append(65,235,52,52,150,158,'.');
bsin:=bmi.append(8,292,52,52,150,158,'sin');
bsin.fsx:=1; bsin.fsy:=1; bsin.draw;
bcos:=bsin.append(65,292,52,52,150,158,'cos');
btan:=bsin.append(122,292,52,52,150,158,'tg');
blog:=bsin.append(179,292,52,52,150,158,'log');
bsqrt:=bsin.append(236,292,52,52,150,158,'sqrt');
binv:=bsin.append(122,235,52,52,150,158,'1/x');

cw.move(600,400,296,352,0,0);
a1s:='0'; a2s:='0'; ws:='0'; ds:='';
repeat
waitvbl;

//cw.buttons.checkall;
if bc.clicked=1 then begin a1s:='0'; bc.clicked:=0; cstate:=0; end;

if cstate=0 then
  begin
  if b01.clicked=1 then begin sadd(a1s,'1'); b01.clicked:=0; end;
  if b02.clicked=1 then begin sadd(a1s,'2'); b02.clicked:=0; end;
  if b03.clicked=1 then begin sadd(a1s,'3'); b03.clicked:=0; end;
  if b04.clicked=1 then begin sadd(a1s,'4'); b04.clicked:=0; end;
  if b05.clicked=1 then begin sadd(a1s,'5'); b05.clicked:=0; end;
  if b06.clicked=1 then begin sadd(a1s,'6'); b06.clicked:=0; end;
  if b07.clicked=1 then begin sadd(a1s,'7'); b07.clicked:=0; end;
  if b08.clicked=1 then begin sadd(a1s,'8'); b08.clicked:=0; end;
  if b09.clicked=1 then begin sadd(a1s,'9'); b09.clicked:=0; end;
  if b00.clicked=1 then begin sadd(a1s,'0'); b00.clicked:=0; end;
  if bdot.clicked=1 then begin sadd(a1s,'.'); bdot.clicked:=0; end;
  if bsin.clicked=1 then
    begin
      bsin.clicked:=0;
      try
        a1:=strtofloat(a1s);
        w:=sin(a1*2*pi/360);
        cstate:=9;
        ws:=translate(w);
        cw.box(8+3,8+3,l-6,h-6,c1);
        cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
      except
        ws:='E';
        cstate:=9;
      end;
    end;

  if bcos.clicked=1 then
    begin
      bcos.clicked:=0;
      try
        a1:=strtofloat(a1s);
        w:=cos(a1*2*pi/360);
        cstate:=9;
        ws:=translate(w);


        cw.box(8+3,8+3,l-6,h-6,c1);
        cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
      except
        ws:='E';
        cstate:=9;
      end;
    end;

    if btan.clicked=1 then
    begin
      btan.clicked:=0;
      try
        a1:=strtofloat(a1s);
        if (a1 mod 180.0)=90 then ws:='E'
          else
          begin
          w:=tan(a1*2*pi/360);
          ws:=translate(w);


          if length(ws)>12 then ws:=copy(ws,1,12);
          end;
        cstate:=9;
        cw.box(8+3,8+3,l-6,h-6,c1);
        cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
      except
        ws:='E';
        cstate:=9;
      end;
    end;

    if blog.clicked=1 then
      begin
        blog.clicked:=0;
        try
          a1:=strtofloat(a1s);
          w:=log10(a1);
          cstate:=9;
          ws:=translate(w);


          cw.box(8+3,8+3,l-6,h-6,c1);
          cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
        except
          ws:='E';
          cstate:=9;
        end;
      end;

    if bsqrt.clicked=1 then
      begin
        bsqrt.clicked:=0;
        try
          a1:=strtofloat(a1s);
          w:=sqrt(a1);

          cstate:=9;
          ws:=translate(w);


          cw.box(8+3,8+3,l-6,h-6,c1);
          cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
        except
          ws:='E';
          cstate:=9;
        end;
      end;

    if binv.clicked=1 then
      begin
        binv.clicked:=0;
        try
          a1:=strtofloat(a1s);
          w:=1/a1;
          cstate:=9;
          ws:=translate(w);

          if copy(ws,length(ws)-2,3)='Inf' then ws:='E';
          if length(ws)>12 then ws:=copy(ws,1,12);
          cw.box(8+3,8+3,l-6,h-6,c1);
          cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
        except
          ws:='E';
          cstate:=9;
        end;
      end;

    if bpl.clicked=1 then
      begin
      bpl.clicked:=0;
      try
        a1:=strtofloat(a1s);
        opcode:=1;
        cstate:=2;
        a2s:=a1s;
      except
        cstate:=0;
      end;
      end;
    if bmi.clicked=1 then
      begin
      bmi.clicked:=0;
      try
        a1:=strtofloat(a1s);
        a2s:=a1s;
        opcode:=2;
        cstate:=2;
      except
        cstate:=0;
      end;
      end;
    if bmul.clicked=1 then
      begin
      bmul.clicked:=0;
      try
        a1:=strtofloat(a1s);
        a2s:=a1s;
        opcode:=3;
        cstate:=2;
      except
        cstate:=0;
      end;
      end;
    if bdiv.clicked=1 then
      begin
      bdiv.clicked:=0;
      try
        a1:=strtofloat(a1s);
        a2s:=a1s;
        opcode:=4;
        cstate:=2;
      except
        cstate:=0;
      end;
      end;
  cw.box(8+3,8+3,l-6,h-6,c1);
  cw.outtextxyz(278-16*length(a1s),16,a1s,c2,2,2);
  end
else if cstate=9 then
  begin
  if (b01.clicked=1)
    or (b02.clicked=1)
      or (b03.clicked=1)
        or (b04.clicked=1)
          or (b05.clicked=1)
            or (b06.clicked=1)
              or (b07.clicked=1)
                or (b08.clicked=1)
                  or (b09.clicked=1)
                    or (b00.clicked=1)
                      or (bdot.clicked=1)
                        then begin a1s:=''; cstate:=0; end;
  if (bsin.clicked=1)
    or (bcos.clicked=1)
      or (btan.clicked=1)
        or (binv.clicked=1)
          or (bsqrt.clicked=1)
            or (blog.clicked=1)
              then begin a1s:=ws; cstate:=0; end;

  cw.box(8+3,8+3,l-6,h-6,c1);
  cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);


      if bpl.clicked=1 then
      begin
      bpl.clicked:=0;
      try
        a1:=strtofloat(ws);
        opcode:=1;
        cstate:=2;
        a2s:=ws;
      except
        cstate:=0;
      end;
      end;
    if bmi.clicked=1 then
      begin
      bmi.clicked:=0;
      try
        a1:=strtofloat(ws);
        a2s:=ws;
        opcode:=2;
        cstate:=2;
      except
        cstate:=0;
      end;
      end;
    if bmul.clicked=1 then
      begin
      bmul.clicked:=0;
      try
        a1:=strtofloat(ws);
        a2s:=ws;
        opcode:=3;
        cstate:=2;
      except
        cstate:=0;
      end;
      end;
    if bdiv.clicked=1 then
      begin
      bdiv.clicked:=0;
      try
        a1:=strtofloat(ws);
        a2s:=ws;
        opcode:=4;
        cstate:=2;
      except
        cstate:=0;
      end;
      end;


  end

else if cstate=2 then
  begin
  if (b01.clicked=1)
    or (b02.clicked=1)
      or (b03.clicked=1)
        or (b04.clicked=1)
          or (b05.clicked=1)
            or (b06.clicked=1)
              or (b07.clicked=1)
                or (b08.clicked=1)
                  or (b09.clicked=1)
                    or (b00.clicked=1)
                      or (bdot.clicked=1)
                        then begin a2s:=''; cstate:=3; end;

  if beq.clicked=1 then
    begin
    beq.clicked:=0;
       try
          a2:=strtofloat(a2s);
          if opcode=1 then w:=a1+a2;
          if opcode=2 then w:=a1-a2;
          if opcode=3 then w:=a1*a2;
          if opcode=4 then w:=a1/a2;
          cstate:=9;
          ws:=translate(w);
          cw.box(8+3,8+3,l-6,h-6,c1);
          cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
        except
          ws:='E';
          cstate:=9;
        end;
     end;
  end

else if cstate=3 then
  begin
  if b01.clicked=1 then begin sadd(a2s,'1'); b01.clicked:=0; end;
  if b02.clicked=1 then begin sadd(a2s,'2'); b02.clicked:=0; end;
  if b03.clicked=1 then begin sadd(a2s,'3'); b03.clicked:=0; end;
  if b04.clicked=1 then begin sadd(a2s,'4'); b04.clicked:=0; end;
  if b05.clicked=1 then begin sadd(a2s,'5'); b05.clicked:=0; end;
  if b06.clicked=1 then begin sadd(a2s,'6'); b06.clicked:=0; end;
  if b07.clicked=1 then begin sadd(a2s,'7'); b07.clicked:=0; end;
  if b08.clicked=1 then begin sadd(a2s,'8'); b08.clicked:=0; end;
  if b09.clicked=1 then begin sadd(a2s,'9'); b09.clicked:=0; end;
  if b00.clicked=1 then begin sadd(a2s,'0'); b00.clicked:=0; end;
  if bdot.clicked=1 then begin sadd(a2s,'.'); bdot.clicked:=0; end;
  if beq.clicked=1 then
    begin
    beq.clicked:=0;
       try
          a2:=strtofloat(a2s);
          if opcode=1 then w:=a1+a2;
          if opcode=2 then w:=a1-a2;
          if opcode=3 then w:=a1*a2;
          if opcode=4 then w:=a1/a2;
          cstate:=9;
          ws:=translate(w);
          cw.box(8+3,8+3,l-6,h-6,c1);
          cw.outtextxyz(278-16*length(ws),16,ws,c2,2,2);
        except
          ws:='E';
          cstate:=9;
        end;
     end;

  cw.box(8+3,8+3,l-6,h-6,c1);
  cw.outtextxyz(278-16*length(a2s),16,a2s,c2,2,2);
  end;

until terminated;
cw.destroy;
cw:=nil;
end;

end.

