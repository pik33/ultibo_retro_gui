unit Unit6502;

{$mode objfpc}{$H+}
{$MACRO ON}

interface

uses Classes, SysUtils;

//var ram:array[-2..65537] of byte;

var instructions:integer=0;      //keep track of total instructions executed
    clockticks6502:integer=0;
    clockgoal6502:integer=0;
    jsrcnt:integer=0;

function read6502(address:integer):byte;
procedure write6502(address:integer; value:byte);
procedure reset6502;
procedure nmi6502;
procedure irq6502;
procedure exec6502(tickcount:integer);
procedure fast6502(tickcount:integer);
procedure step6502;
procedure jsr6502(aa:word; addr:integer);

implementation

uses retromalina;

// **********************************************************
// * 65032 CPU emulator core                                *
// * Pascal code by pik33 (pik33@o2.pl)                     *
// * based on Fake6502 C code                               *
// **********************************************************
// * Original Fake6502 LICENSE:                             *
// * (c)2011 Mike Chambers (miker00lz@gmail.com)            *
// * This source code is released into the                  *
// * public domain, but if you use it please do give        *
// * credit. I put a lot of effort into writing this!       *
// **********************************************************

procedure imp; forward;
procedure indx; forward;
procedure zp; forward;
procedure imm; forward;
procedure acc; forward;
procedure abso; forward;
procedure rel; forward;
procedure indy; forward;
procedure absy; forward;
procedure absx; forward;
procedure ind; forward;
procedure zpx; forward;
procedure zpy; forward;

//65c02
procedure izp; forward; //ok
procedure iax; forward; //ok

procedure brk; forward;
procedure ora; forward;
procedure nop; forward;
procedure ana; forward;
procedure slo; forward;
procedure asl; forward;
procedure bpl; forward;
procedure php; forward;
procedure clc; forward;
procedure jsr; forward;
procedure rla; forward;
procedure bit; forward;
procedure rol; forward;
procedure bmi; forward;
procedure plp; forward;
procedure sec; forward;
procedure rti; forward;
procedure eor; forward;
procedure sre; forward;
procedure lsr; forward;
procedure pha; forward;
procedure bvc; forward;
procedure cli; forward;
procedure jmp; forward;
procedure rts; forward;
procedure adc; forward;
procedure bvs; forward;
procedure rra; forward;
procedure ror; forward;
procedure pla; forward;
procedure sei; forward;
procedure sta; forward;
procedure sax; forward;
procedure stx; forward;
procedure sty; forward;
procedure dey; forward;
procedure txa; forward;
procedure bcc; forward;
procedure tya; forward;
procedure txs; forward;
procedure ldy; forward;
procedure lda; forward;
procedure ldx; forward;
procedure lax; forward;
procedure tay; forward;
procedure tax; forward;
procedure bcs; forward;
procedure clv; forward;
procedure tsx; forward;
procedure cpy; forward;
procedure cmp; forward;
procedure dcp; forward;
procedure dea; forward;
procedure iny; forward;
procedure dex; forward;
procedure bne; forward;
procedure cld; forward;
procedure cpx; forward;
procedure isb; forward;
procedure inx; forward;
procedure beq; forward;
procedure sbc; forward;
procedure ina; forward;
procedure sed; forward;
procedure anc; forward;
procedure alr; forward;
procedure arr; forward;
procedure xaa; forward;
procedure ahx; forward;
procedure shx; forward;
procedure tas; forward;
procedure shy; forward;
procedure las; forward;
procedure axs; forward;
procedure atx; forward;
procedure dop; forward;
procedure top; forward;

// 65c02
procedure bra; forward; //ok
procedure phx; forward; //ok
procedure phy; forward; //ok
procedure plx; forward; //ok
procedure ply; forward; //ok
procedure stz; forward; //ok
procedure trb; forward; //ok
procedure tsb; forward; //ok
//65032
procedure ldc; forward;
procedure stc; forward;
procedure ldd; forward;
procedure std; forward;
procedure phc; forward; //ok
procedure phd; forward; //ok
procedure pld; forward; //ok
procedure plc; forward; //ok

type

Taddr=procedure;
TOpcode=procedure;

var addrtable:array[0..255] of TAddr=(
//        |  0   |  1   |  2   |  3   |  4   |  5   |  6   |  7   |  8   |  9   |  A   |  B   |  C   |  D   |  E   |  F  |
{  0  }     @imp, @indx,  @imp, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @acc,  @imm, @abso, @abso, @abso, @abso, {  0  }
{  1  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpx,  @zpx,  @imp, @absy,  @imp, @absy, @absx, @absx, @absx, @absx, {  1  }
{  2  }    @abso, @indx,  @imp, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @acc,  @imm, @abso, @abso, @abso, @abso, {  2  }
{  3  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpx,  @zpx,  @imp, @absy,  @imp, @absy, @absx, @absx, @absx, @absx, {  3  }
{  4  }     @imp, @indx,  @imp, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @acc,  @imm, @abso, @abso, @abso, @abso, {  4  }
{  5  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpx,  @zpx,  @imp, @absy,  @imp, @absy, @absx, @absx, @absx, @absx, {  5  }
{  6  }     @imp, @indx,  @imp, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @acc,  @imm,  @ind, @abso, @abso, @abso, {  6  }
{  7  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpx,  @zpx,  @imp, @absy,  @imp, @absy,  @iax, @absx, @absx, @absx, {  7  }
{  8  }     @imm, @indx,  @imm, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @imp,  @imm, @abso, @abso, @abso, @abso, {  8  }
{  9  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpy,  @zpy,  @imp, @absy,  @imp, @absy, @absx, @absx, @absy, @absy, {  9  }
{  A  }     @imm, @indx,  @imm, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @imp,  @imm, @abso, @abso, @abso, @abso, {  A  }
{  B  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpy,  @zpy,  @imp, @absy,  @imp, @absy, @absx, @absx, @absy, @absy, {  B  }
{  C  }     @imm, @indx,  @imm, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @imp,  @imm, @abso, @abso, @abso, @abso, {  C  }
{  D  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpx,  @zpx,  @imp, @absy,  @imp, @absy, @absx, @absx, @absx, @absx, {  D  }
{  E  }     @imm, @indx,  @imm, @indx,   @zp,   @zp,   @zp,   @zp,  @imp,  @imm,  @imp,  @imm, @abso, @abso, @abso, @abso, {  E  }
{  F  }     @rel, @indy,  @imp, @indy,  @zpx,  @zpx,  @zpx,  @zpx,  @imp, @absy,  @imp, @absy, @absx, @absx, @absx, @absx  {  F  }
);

var optable:array[0..255] of TOpcode=(
//         |  0   |   1  |   2  |   3  |   4  |   5  |   6  |   7  |   8  |   9  |   A  |   B  |   C  |   D  |   E  |   F  |
{  0  }      @brk,  @ora,  @nop,  @slo,  @dop,  @ora,  @asl,  @slo,  @php,  @ora,  @asl,  @anc,  @top,  @ora,  @asl,  @slo, {  0  }
{  1  }      @bpl,  @ora,  @nop,  @slo,  @dop,  @ora,  @asl,  @slo,  @clc,  @ora,  @nop,  @slo,  @top,  @ora,  @asl,  @slo, {  1  }
{  2  }      @jsr,  @ana,  @nop,  @rla,  @bit,  @ana,  @rol,  @rla,  @plp,  @ana,  @rol,  @anc,  @bit,  @ana,  @rol,  @rla, {  2  }
{  3  }      @bmi,  @ana,  @nop,  @rla,  @dop,  @ana,  @rol,  @rla,  @sec,  @ana,  @nop,  @rla,  @top,  @ana,  @rol,  @rla, {  3  }
{  4  }      @rti,  @eor,  @nop,  @sre,  @dop,  @eor,  @lsr,  @sre,  @pha,  @eor,  @lsr,  @alr,  @jmp,  @eor,  @lsr,  @sre, {  4  }
{  5  }      @bvc,  @eor,  @nop,  @sre,  @dop,  @eor,  @lsr,  @sre,  @cli,  @eor,  @nop,  @sre,  @top,  @eor,  @lsr,  @sre, {  5  }
{  6  }      @rts,  @adc,  @nop,  @rra,  @dop,  @adc,  @ror,  @rra,  @pla,  @adc,  @ror,  @arr,  @jmp,  @adc,  @ror,  @rra, {  6  }
{  7  }      @bvs,  @adc,  @nop,  @rra,  @dop,  @adc,  @ror,  @rra,  @sei,  @adc,  @nop,  @rra,  @top,  @adc,  @ror,  @rra, {  7  }
{  8  }      @dop,  @sta,  @dop,  @sax,  @sty,  @sta,  @stx,  @sax,  @dey,  @dop,  @txa,  @xaa,  @sty,  @sta,  @stx,  @sax, {  8  }
{  9  }      @bcc,  @sta,  @nop,  @ahx,  @sty,  @sta,  @stx,  @sax,  @tya,  @sta,  @txs,  @tas,  @shy,  @sta,  @shx,  @ahx, {  9  }
{  A  }      @ldy,  @lda,  @ldx,  @lax,  @ldy,  @lda,  @ldx,  @lax,  @tay,  @lda,  @tax,  @atx,  @ldy,  @lda,  @ldx,  @lax, {  A  }
{  B  }      @bcs,  @lda,  @nop,  @lax,  @ldy,  @lda,  @ldx,  @lax,  @clv,  @lda,  @tsx,  @las,  @ldy,  @lda,  @ldx,  @lax, {  B  }
{  C  }      @cpy,  @cmp,  @dop,  @dcp,  @cpy,  @cmp,  @dea,  @dcp,  @iny,  @cmp,  @dex,  @axs,  @cpy,  @cmp,  @dea,  @dcp, {  C  }
{  D  }      @bne,  @cmp,  @nop,  @dcp,  @dop,  @cmp,  @dea,  @dcp,  @cld,  @cmp,  @nop,  @dcp,  @top,  @cmp,  @dea,  @dcp, {  D  }
{  E  }      @cpx,  @sbc,  @dop,  @isb,  @cpx,  @sbc,  @ina,  @isb,  @inx,  @sbc,  @nop,  @sbc,  @cpx,  @sbc,  @ina,  @isb, {  E  }
{  F  }      @beq,  @sbc,  @nop,  @isb,  @dop,  @sbc,  @ina,  @isb,  @sed,  @sbc,  @nop,  @isb,  @top,  @sbc,  @ina,  @isb  {  F  }
);

var ticktable:array[0..255] of byte = (
{         |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  A  |  B  |  C  |  D  |  E  |  F  |      }
{  0  }      7,    6,    7,    8,    5,    3,    5,    5,    3,    2,    2,    2,    6,    4,    6,    6,  {  0  }
{  1  }      2,    5,    5,    8,    5,    4,    6,    6,    2,    4,    2,    7,    6,    4,    7,    7,  {  1  }
{  2  }      6,    6,    7,    8,    3,    3,    5,    5,    4,    2,    2,    2,    4,    4,    6,    6,  {  2  }
{  3  }      2,    5,    5,    8,    4,    4,    6,    6,    2,    4,    2,    7,    4,    4,    7,    7,  {  3  }
{  4  }      6,    6,    7,    8,    7,    3,    5,    5,    3,    2,    2,    2,    3,    4,    6,    6,  {  4  }
{  5  }      2,    5,    5,    8,    4,    4,    6,    6,    2,    4,    3,    7,    4,    4,    7,    7,  {  5  }
{  6  }      6,    6,    7,    8,    3,    3,    5,    5,    4,    2,    2,    2,    5,    4,    6,    6,  {  6  }
{  7  }      2,    5,    5,    8,    4,    4,    6,    6,    2,    4,    4,    7,    6,    4,    7,    7,  {  7  }
{  8  }      3,    6,    7,    6,    3,    3,    3,    3,    2,    2,    2,    2,    4,    4,    4,    4,  {  8  }
{  9  }      2,    6,    5,    6,    4,    4,    4,    4,    2,    5,    2,    5,    4,    5,    5,    5,  {  9  }
{  A  }      2,    6,    2,    6,    3,    3,    3,    3,    2,    2,    2,    2,    4,    4,    4,    4,  {  A  }
{  B  }      2,    5,    5,    5,    4,    4,    4,    4,    2,    4,    2,    4,    4,    4,    4,    4,  {  B  }
{  C  }      2,    6,    6,    8,    3,    3,    5,    5,    2,    2,    2,    2,    4,    4,    6,    6,  {  C  }
{  D  }      2,    5,    5,    8,    4,    4,    6,    6,    2,    4,    3,    7,    4,    4,    7,    7,  {  D  }
{  E  }      2,    6,    6,    8,    3,    3,    5,    5,    2,    2,    2,    2,    4,    4,    6,    6,  {  E  }
{  F  }      2,    5,    5,    8,    4,    4,    6,    6,    2,    4,    4,    7,    4,    4,    7,    7   {  F  }
);

{$define FLAG_CARRY:=$01}
{$define FLAG_ZERO:=$02}
{$define FLAG_INTERRUPT:=$04}
{$define FLAG_DECIMAL:=$08}
{$define FLAG_BREAK:=$10}
{$define FLAG_CONSTANT:=$20}
{$define FLAG_OVERFLOW:=$40}
{$define FLAG_SIGN:=$80}
{$define BASE_STACK:=$100}

//flag modifier macros

{$define setcarry:= status :=status or FLAG_CARRY}
{$define clearcarry:= status := status and not(FLAG_CARRY)}
{$define setzero:= status :=status or FLAG_ZERO}
{$define clearzero:= status:= status and not(FLAG_ZERO)}
{$define setinterrupt:= status :=status or FLAG_INTERRUPT}
{$define clearinterrupt:= status:= status and not(FLAG_INTERRUPT)}
{$define setdecimal:= status :=status or FLAG_DECIMAL}
{$define cleardecimal:= status := status and not(FLAG_DECIMAL)}
{$define setoverflow:= status :=status or FLAG_OVERFLOW}
{$define clearoverflow:= status := status and not(FLAG_OVERFLOW)}
{$define setsign:= status :=status or FLAG_SIGN}
{$define clearsign:= status := status and not(FLAG_SIGN)}

//6502 CPU registers

var pc:word;
var sp,a,x,y,status:byte;


//helper variables

var
    oldpc,ea,reladdr,value,aresult:word;
    opcode:byte;
    penaltyop,penaltyaddr:byte;
    csa,dsa,csi,dsi:integer;
 //   cs,ds:^integer;


 function read6502(address:integer):byte;

 begin
 address:=address and $FFFF;
 result:=peek(base+address); //ram[address and $FFFF];
 end;

 procedure write6502(address:integer; value:byte);

 begin
 address:=address and $FFFF;
 poke(base+address,value); //ram[address and $FFFF]:=value;
 end;

 //a few general functions used by various other functions

 procedure push32(pushval:cardinal);

 begin
 write6502(BASE_STACK+sp,(pushval shr 24) and $FF);
 write6502(BASE_STACK+((sp-1) and $FF),(pushval shr 16) and $FF);
 write6502(BASE_STACK+((sp-2) and $FF),(pushval shr 8) and $FF);
 write6502(BASE_STACK+((sp-3) and $FF),pushval and $FF);
 sp-=4;
 end;

 procedure push16(pushval:word);

 begin
 write6502(BASE_STACK+sp,(pushval shr 8) and $FF);
 write6502(BASE_STACK+((sp-1) and $FF),pushval and $FF);
 sp-=2;
 end;

 procedure push8(pushval:word);

 begin
 write6502(BASE_STACK+sp,pushval);
 dec(sp);
 end;

 function pull32:cardinal;

 var temp32:cardinal;

 begin
 temp32:=read6502(BASE_STACK + ((sp + 4) and $FF));
 temp32:=(temp32 shl 8) + read6502(BASE_STACK + ((sp + 3) and $FF));
 temp32:=(temp32 shl 8) + read6502(BASE_STACK + ((sp + 2) and $FF));
 temp32:=(temp32 shl 8) + read6502(BASE_STACK + ((sp + 1) and $FF));
 result:=temp32;
 sp+=4;
 end;

 function pull16:word;

 var temp16:word;

 begin
 temp16:=read6502(BASE_STACK + ((sp + 2) and $FF));
 temp16:=(temp16 shl 8) + read6502(BASE_STACK + ((sp + 1) and $FF));
 result:=temp16;
 sp+=2;
 end;

 function pull8:byte;

 begin
 inc(sp);
 result:=(read6502(BASE_STACK + sp));
 end;

 function getvalue:word;

 var ea2:integer;

 begin
 ea2:=ea;
 if (addrtable[opcode] = @acc) then
   result:=a
 else
   result:=read6502(ea2);
 end;

 function getvalue16:word;

 var ea2:integer;

 begin
 ea2:=ea;
 result:=word(read6502(ea2)) or (word(read6502(ea2+1)) shl 8);
 end;

 function getvalue32:cardinal;

 var ea2:integer;

 begin

 ea2:=ea;

 result:=cardinal(read6502(ea2))
   or (cardinal(read6502(ea2+1)) shl 8)
     or (cardinal(read6502(ea2+2)) shl 16)
       or (cardinal(read6502(ea2+3)) shl 24);
 end;

 procedure putvalue(saveval:word);

 var ea2:integer;

 begin
 ea2:=ea;
 if (addrtable[opcode] = @acc) then a := byte(saveval and $00FF) else write6502(ea2, (saveval and $00FF));
 end;

 procedure putvalue32(saveval:cardinal);

 var ea2:integer;

 begin

 ea2:=ea;

 write6502(ea2, (saveval and $000000FF));
 write6502(ea2+1, ((saveval shl 8) and $000000FF));
 write6502(ea2+2, ((saveval shl 16) and $000000FF));
 write6502(ea2+3, ((saveval shl 24) and $000000FF));
 end;

 procedure reset6502;

 begin
 //for x:=0 to 15 do for y:=0 to 15 do box(16*(x),16*(y),14,14,36);
 pc := word(read6502($FFFC)) or (word(read6502($FFFD) shl 8));
 a := 0;
 x := 0;
 y := 0;
 sp := $FD;
 //ds:=@dsa;
 //cs:=@csa;
 //:=0; ds^:=0; csi:=0; dsi:=0;
 status:=status or FLAG_CONSTANT;
 clockgoal6502:=0;
 instructions:=0;
 clockticks6502:=0;

 end;

 procedure nmi6502;

 begin
 push16(pc);
 push8(status);
 status :=status or FLAG_INTERRUPT;
 pc := word(read6502($FFFA)) or (word(read6502($FFFB)) << 8);
 //cs:=@csi;
 //ds:=@dsi;
 end;

 procedure irq6502;

 begin
 push16(pc);
 push8(status);
 status :=status or FLAG_INTERRUPT;
 pc := word(read6502($FFFE)) or (word(read6502($FFFF)) << 8);
 //cs:=@csi;
 //ds:=@dsi;
 end;

 procedure exec6502(tickcount:integer);

 begin
 clockgoal6502 += tickcount;
 while (clockticks6502 < clockgoal6502) do
   begin
   opcode := read6502(pc);
   pc+=1;
 //  status := status or FLAG_CONSTANT;
   penaltyop := 0;
   penaltyaddr := 0;
   addrtable[opcode];
   optable[opcode];
   clockticks6502 += ticktable[opcode];
   if (penaltyop<>0) and (penaltyaddr<>0) then  clockticks6502+=1;
   instructions+=1;
   end;
 end;

 procedure fast6502(tickcount:integer);

 begin
 clockgoal6502 += tickcount;
 while (clockticks6502 < clockgoal6502) do
   begin
   opcode := read6502(pc);
   pc+=1;
   addrtable[opcode];
   optable[opcode];
   clockticks6502 += 1;
   instructions+=1;
   end;
 end;

 procedure step6502;

 begin
 opcode := read6502(pc);
 pc+=1;
 status :=status or FLAG_CONSTANT;
 penaltyop := 0;
 penaltyaddr := 0;
 addrtable[opcode];
 optable[opcode];
 clockticks6502 += ticktable[opcode];
 if (penaltyop<>0) and (penaltyaddr<>0) then clockticks6502+=1;
 clockgoal6502 := clockticks6502;
 instructions+=1;
 end;


 procedure jsr6502(aa:word; addr:integer);

 var depth:integer;

 begin
 inc(jsrcnt) ;
 //box(100,100,500,20,33);
 //outtextxy(100,100,'entered jsr at '+inttohex(addr,4),44);
 pc:=addr;
 sp := $FD;
 depth:=0;
 if aa<256 then begin a:=aa; x:=0; y:=0; status:=0; end;
 instructions:=0;
 repeat
   opcode := read6502(pc);
 //  box(16*(opcode mod 16),16*(opcode div 16),14,14,15);
   if opcode=$20 then inc(depth);
   if opcode=$60 then dec(depth);
     begin
     pc+=1;
     addrtable[opcode];
     optable[opcode];
     instructions+=1;
     end;
   until (depth<0) or (instructions>3000);
 //  box(100,200,500,20,33);
 //outtextxy(100,200,'exited jsr after '+inttostr(instructions)+' jsr count '+inttostr(jsrcnt),44);

 end;

//addressing mode functions, calculates effective addresses

procedure imp; //implied

begin
ea:=-1
end;

procedure acc;  //accumulator

begin
ea:=-1
end;

procedure imm;  //immediate

begin
ea := pc;
inc(pc);
end;

procedure zp;  //zero-page

begin
ea := word(read6502(pc));
inc(pc);
end;

procedure zpx; //zero-page,X

begin
ea := ((read6502(pc)+x) and $FF); //zero-page wraparound
inc(pc)
end;

procedure zpy; //zero-page,Y

begin
ea := ((read6502(pc)+y) and $FF); //zero-page wraparound
inc(pc)
end;

procedure rel; //relative for branch ops (8-bit immediate value, sign-extended)

begin
reladdr := word(read6502(pc));
inc(pc);
if (reladdr and $80)<>0 then reladdr:=reladdr or $FF00;
ea:=reladdr;
end;

procedure abso; //absolute

begin
ea := word(read6502(pc)) or (word(read6502(pc+1)) shl 8);
pc += 2;
end;

procedure absx;  //absolute,X

var startpage:word;

begin
ea := word(read6502(pc)) or (word(read6502(pc+1)) shl 8);
startpage := ea and $FF00;
ea += x;
if (startpage <> (ea and $FF00)) then penaltyaddr := 1;   //one cycle penalty for page-crossing on some opcodes
pc += 2;
end;

procedure absy;  //absolute,Y

var startpage:word;

begin
ea := word(read6502(pc)) or (word(read6502(pc+1)) shl 8);
startpage := ea and $FF00;
ea += y;
if (startpage <> (ea and $FF00)) then penaltyaddr := 1; //one cycle penalty for page-crossing on some opcodes
pc += 2;
end;

procedure ind;  //indirect

var eahelp, eahelp2:word;

begin
eahelp := word(read6502(pc)) or (word(read6502(pc+1)) shl 8);
eahelp2 := (eahelp and $FF00) or ((eahelp + 1) and $00FF); //replicate 6502 page-boundary wraparound bug
ea := word(read6502(eahelp)) or (word(read6502(eahelp2)) shl 8);
pc += 2;
end;

procedure izp;  // (indirect,zp)

var eahelp:word;

begin
eahelp := word(read6502(pc)) and $FF; //zero-page wraparound for table pointer
inc(pc);
ea := word(read6502(eahelp and $00FF)) or (word(read6502((eahelp+1) and $00FF)) shl 8);
end;


procedure indx;  // (indirect,zp,X)

var eahelp:word;

begin
eahelp := (word(read6502(pc) + x) and $FF); //zero-page wraparound for table pointer
inc(pc);
ea := word(read6502(eahelp and $00FF)) or (word(read6502((eahelp+1) and $00FF)) shl 8);
end;

procedure iax;  // (indirect,X)

var eahelp:word;

begin
eahelp := word(read6502(pc))+(word(read6502(pc+1) shl 8)+ y); //zero-page wraparound for table pointer
pc+=2;
ea := word(read6502(eahelp and $00FF)) or (word(read6502((eahelp+1) and $00FF)) shl 8);
end;

procedure indy; // (indirect),zp,Y

var eahelp, eahelp2, startpage: word;

begin
eahelp := word(read6502(pc));
inc(pc);
eahelp2 := (eahelp and $FF00) or ((eahelp + 1) and $00FF); //zero-page wraparound
ea := word(read6502(eahelp)) or (word(read6502(eahelp2)) shl 8);
startpage := ea and $FF00;
ea += y;
if (startpage <> (ea and $FF00)) then penaltyaddr := 1; //one cycle penalty for page-crossing on some opcodes
end;

// addr modes end

//instruction handler functions

procedure adc;

begin
penaltyop := 1;
value := getvalue;
aresult := word(value)+a+(status and FLAG_CARRY);
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if ((aresult xor a) and (aresult xor value) and $0080)<>0 then
  setoverflow
else
  clearoverflow;
if (aresult and $0080)<>0 then setsign else clearsign;
if (status and FLAG_DECIMAL)<>0 then
  begin
  inc(clockticks6502);
  clearcarry;
  if ((a and $0F) > $09) then a += $06;
  if ((a and $F0) > $90) then
    begin
    a += $60;
    setcarry;
    end;
  end;
a:=byte(aresult and $00FF);
end;

procedure ana;

begin
penaltyop := 1;
value := getvalue;
aresult := a and value;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
a:=byte(aresult and $00FF);
end;

procedure asl;

begin
value := getvalue;
aresult := value shl 1;
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
putvalue(aresult);
end;

procedure bcc;

begin
if ((status and FLAG_CARRY) = 0) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
            else clockticks6502+=1;
  end;
end;

procedure bcs;

begin
if ((status and FLAG_CARRY) = FLAG_CARRY) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
            else clockticks6502+=1;
  end;
end;

procedure beq;

begin
if ((status and FLAG_ZERO) = FLAG_ZERO) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
  else clockticks6502+=1;
  end;
end;

procedure bit;

begin
value := getvalue;;
aresult := a and value;
if (aresult and $00FF)<>0 then clearzero else setzero;
status := (status and $3F) or (value and $C0);
end;

procedure bmi;

begin
if ((status and FLAG_SIGN) = FLAG_SIGN) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
  else clockticks6502+=1;
  end;
end;

procedure bne;

begin
if ((status and FLAG_ZERO) = 0) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
  else clockticks6502+=1;
  end;
end;

procedure bpl;

begin
if ((status and FLAG_SIGN) = 0) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
  else clockticks6502+=1;
  end;
end;

procedure bra;

begin
oldpc := pc;
pc += reladdr;
if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
else clockticks6502+=1;
end;

procedure brk;

begin
pc+=1;
push16(pc); //push next instruction address onto stack
push8(status or FLAG_BREAK); //push CPU status to stack
setinterrupt; //set interrupt flag
pc := word(read6502($FFFE)) or (word(read6502($FFFF)) shl 8);
end;

procedure bvc;

begin
if ((status and FLAG_OVERFLOW) = 0) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
  else clockticks6502+=1;
  end;
end;

procedure bvs;

begin
if ((status and FLAG_OVERFLOW) = FLAG_OVERFLOW) then
  begin
  oldpc := pc;
  pc += reladdr;
  if ((oldpc and $FF00) <> (pc and $FF00)) then clockticks6502 += 2 //check if jump crossed a page boundary
  else clockticks6502+=1;
  end;
end;

procedure clc;

begin
clearcarry;
end;

procedure cld;

begin
cleardecimal;
end;

procedure cli;

begin
clearinterrupt;
end;

procedure clv;

begin
clearoverflow;
end;

procedure cmp;

begin
penaltyop := 1;
value := byte(getvalue);
aresult := word(a) - value;
if (a >= (value and $00FF)) then setcarry else clearcarry;
if (a = (byte(value and $00FF))) then setzero else clearzero;
if (aresult and $0080)<>0 then setsign else clearsign;
end;

procedure cpx;

begin
value := getvalue;;
aresult := word(x) - value;
if (x >= (value and $00FF)) then setcarry else clearcarry;
if (x = (byte(value and $00FF))) then setzero else clearzero;
if (aresult and $0080)<>0 then setsign else clearsign;
end;

procedure cpy;

begin
value := getvalue;;
aresult := word(y) - value;
if (y >= (value and $00FF)) then setcarry else clearcarry;
if (y = (value and $00FF)) then setzero else clearzero;
if (aresult and $0080)<>0 then setsign else clearsign;
end;

procedure dea;

begin
value := getvalue;;
aresult := value - 1;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
putvalue(aresult);
end;

procedure dex;

begin
x-=1;
if (x and $0080)<>0 then setsign else clearsign;
if (x and $00FF)<>0 then clearzero else setzero;
end;

procedure dey;

begin
y-=1;
if (y and $0080)<>0 then setsign else clearsign;
if (y and $00FF)<>0 then clearzero else setzero;
end;

procedure eor;

begin
penaltyop := 1;
value := getvalue;
aresult := a xor value;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
a:=byte(aresult and $00FF);
end;

procedure ina;

begin
value := getvalue;
aresult := value + 1;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
putvalue(aresult);
end;

procedure inx;

begin
x+=1;
if (x and $0080)<>0 then setsign else clearsign;
if (x and $00FF)<>0 then clearzero else setzero;
end;

procedure iny;

begin
y+=1;
if (y and $0080)<>0 then setsign else clearsign;
if (y and $00FF)<>0 then clearzero else setzero;
end;

procedure jmp;

begin
pc := ea;
end;

procedure jsr;

begin
push16(pc - 1);
pc := ea;
end;

procedure lda;

begin
penaltyop := 1;
value := getvalue;
a := (value and $00FF);
if (a and $0080)<>0 then setsign else clearsign;
if (a and $00FF)<>0 then clearzero else setzero;
end;


procedure ldc;

begin
//:=getvalue32 shl 8;
end;

procedure ldd;

begin
//ds^:=getvalue32 shl 8;
end;


procedure ldx;

begin
penaltyop := 1;
value := getvalue;
x := (value and $00FF);
if (x and $0080)<>0 then setsign else clearsign;
if (x and $00FF)<>0 then clearzero else setzero;
end;

procedure ldy;

begin
penaltyop := 1;
value := getvalue;;
y := (value and $00FF);
if (y and $0080)<>0 then setsign else clearsign;
if (y and $00FF)<>0 then clearzero else setzero;
end;

procedure lsr;

begin
value := getvalue and $FF;
aresult := value shr 1;
if (value and 1)=1 then setcarry else clearcarry;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
putvalue(aresult);
end;

procedure nop;

begin
end;

procedure ora;

begin
penaltyop := 1;
value := getvalue;;
aresult := a or value;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
a:=byte(aresult and $00FF);
end;

procedure pha;

begin
push8(a);
end;

procedure phc;

begin
//push32( shr 8);
end;

procedure phd;

begin
//push32(ds^ shr 8);
end;

procedure phx;

begin
push8(x);
end;

procedure phy;

begin
push8(y);
end;

procedure php;

begin
push8(status or FLAG_BREAK);
end;

procedure pla;

begin
a := pull8;
if (a and $0080)<>0 then setsign else clearsign;
if (a and $00FF)<>0 then clearzero else setzero;
end;

procedure plc;

begin
//:=pull32 shl 8;
end;

procedure pld;

begin
//ds^:=pull32 shl 8;
end;

procedure plx;

begin
x := pull8;
if (x and $0080)<>0 then setsign else clearsign;
if (x and $00FF)<>0 then clearzero else setzero;
end;

procedure ply;

begin
y := pull8;
if (y and $0080)<>0 then setsign else clearsign;
if (y and $00FF)<>0 then clearzero else setzero;
end;

procedure plp;

begin
status := pull8 or FLAG_CONSTANT;
end;

procedure rol;

begin
value := getvalue;;
aresult := (value shl 1) or (status and FLAG_CARRY);
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
putvalue(aresult);
end;

procedure ror;

begin
value := getvalue;;
aresult := (value shr 1) or ((status and FLAG_CARRY) shl 7);
if (value and 1)=1 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
putvalue(aresult);
end;

procedure rti;

begin
status := pull8;
value := pull16;
pc := value;
//cs:=@csa;
//ds:=@dsa;
end;

procedure rts;

begin
value := pull16;
pc := value + 1;
end;

procedure sbc;

begin
penaltyop := 1;
value := getvalue xor $00FF;
aresult := word(a) + value + (status and FLAG_CARRY);
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if ((aresult xor a) and (aresult xor value) and $0080)<>0 then setoverflow else clearoverflow;
if (aresult and $0080)<>0 then setsign else clearsign;

if (status and FLAG_DECIMAL)<>0 then
  begin
  inc(clockticks6502);
  clearcarry;
  if ((a and $0F) > $09) then a += $06;
  if ((a and $F0) > $90) then
    begin
    a += $60;
    setcarry;
    end;
  end;

a:=byte(aresult and $00FF);
end;

procedure sec;

begin
setcarry;
end;

procedure sed;

begin
setdecimal;
end;

procedure sei;

begin
setinterrupt;
end;

procedure sta;

begin
putvalue(a);
end;

procedure stc;

begin
//putvalue32(shr 8);
end;

procedure std;

begin
//putvalue32(ds^ shr 8);
end;

procedure stx;

begin
putvalue(x);
end;

procedure sty;

begin
putvalue(y);
end;

procedure stz;

begin
putvalue(0);
end;

procedure tax;

begin
x := a;
if (x and $0080)<>0 then setsign else clearsign;
if (x and $00FF)<>0 then clearzero else setzero;
end;

procedure tay;

begin
y := a;
if (y and $0080)<>0 then setsign else clearsign;
if (y and $00FF)<>0 then clearzero else setzero;
end;

procedure trb;

begin
value:=getvalue;
aresult:=value and (not a);
putvalue(aresult);
if (aresult and $00FF)<>0 then clearzero else setzero;
end;

procedure tsb;

begin
value:=getvalue;
aresult:=value or a;
putvalue(aresult);
if (aresult and $00FF)<>0 then clearzero else setzero;
end;

procedure tsx;

begin
x := sp;
if (x and $0080)<>0 then setsign else clearsign;
if (x and $00FF)<>0 then clearzero else setzero;
end;

procedure txa;

begin
a := x;
if (a and $0080)<>0 then setsign else clearsign;
if (a and $00FF)<>0 then clearzero else setzero;
end;

procedure txs;

begin
sp := x;
end;

procedure tya;

begin
a := y;
if (a and $0080)<>0 then setsign else clearsign;
if (a and $00FF)<>0 then clearzero else setzero;
end;

//undocumented instructions

procedure lax;

begin
value := getvalue;
a:=(value and $00FF);
x:=a;
if (a and $0080)<>0 then setsign else clearsign;
if (a and $00FF)<>0 then clearzero else setzero;
end;


procedure sax;

begin
putvalue(a and x);
if (a and x and $0080)<>0 then setsign else clearsign;
if (a and x and $00FF)<>0 then clearzero else setzero;
end;

procedure dcp;

begin
value:=getvalue;
value:=(value-1) and 255;
putvalue(value);
cmp;
end;

procedure isb;

begin
value:=(getvalue+1) and 255;
putvalue(value);
value := value xor $00FF;
aresult := word(a) + value + (status and FLAG_CARRY);
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if ((aresult xor a) and (aresult xor value) and $0080)<>0 then setoverflow else clearoverflow;
if (aresult and $0080)<>0 then setsign else clearsign;

if (status and FLAG_DECIMAL)<>0 then
  begin
  inc(clockticks6502);
  clearcarry;
  if ((a and $0F) > $09) then a += $06;
  if ((a and $F0) > $90) then
    begin
    a += $60;
    setcarry;
    end;
  end;

a:=byte(aresult and $00FF);
end;

procedure slo;

begin
value := getvalue;
aresult := value shl 1;
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
putvalue(aresult);
value := aresult;
aresult := a or value;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
a:=byte(aresult and $00FF);
end;


procedure rla;

begin
value := getvalue;;
aresult := (value shl 1) or (status and FLAG_CARRY);
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
putvalue(aresult);
aresult := a and aresult;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
a:=byte(aresult and $00FF);
if (penaltyop<>0) and (penaltyaddr<>0) then dec (clockticks6502);
end;

procedure sre;

begin
value := getvalue and $FF;
aresult := value shr 1;
if (value and 1)=1 then setcarry else clearcarry;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
putvalue(aresult);
aresult := a xor aresult;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
a:=byte(aresult and $00FF);
end;

procedure rra;

begin
value := getvalue;;
aresult := (value shr 1) or ((status and FLAG_CARRY) shl 7);
if (value and 1)=1 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
putvalue(aresult);

value := aresult;
aresult := word(value)+a+(status and FLAG_CARRY);
if (aresult and $FF00) <>0 then setcarry else clearcarry;
if (aresult and $00FF)<>0 then clearzero else setzero;
if ((aresult xor a) and (aresult xor value) and $0080)<>0 then
  setoverflow
else
  clearoverflow;
if (aresult and $0080)<>0 then setsign else clearsign;
if (status and FLAG_DECIMAL)<>0 then
  begin
  inc(clockticks6502);
  clearcarry;
  if ((a and $0F) > $09) then a += $06;
  if ((a and $F0) > $90) then
    begin
    a += $60;
    setcarry;
    end;
  end;
a:=byte(aresult and $00FF);
end;

procedure anc;

begin
ana;
if (a and $80)>0 then setcarry else clearcarry;
end;

procedure alr;

begin;
value := getvalue;
aresult := (a and value) shr 1;
if (aresult and $0080)<>0 then setsign else clearsign;
if (aresult and $00FF)<>0 then clearzero else setzero;
a:=aresult;
end;

procedure arr;

begin;
value := getvalue;
aresult := a and value;
aresult := (aresult shr 1) or ((status and FLAG_CARRY) shl 7);
if (aresult and 96)=96 then begin setcarry; clearoverflow; end
else if (aresult  and 96)=0 then begin clearcarry; clearoverflow; end
else if (aresult  and 96)=32 then begin clearcarry; setoverflow; end
else begin setcarry; setoverflow; end;
a:=aresult;
end;

procedure xaa;

begin;
a:=x;
value:=getvalue;
aresult := a and value;
if (aresult and $00FF)<>0 then clearzero else setzero;
if (aresult and $0080)<>0 then setsign else clearsign;
a:=byte(aresult and $00FF);
end;

procedure ahx;

begin;
aresult:=a and x and 7;
putvalue(aresult);
end;

procedure tas;

begin;
sp:=a and x and (ea shr 8) +1;
putvalue(sp);
end;

procedure shy;

begin;
value:=(((ea) shr 8) and y) +1;
putvalue(value);
end;

procedure shx;

begin;
value:=(((ea) shr 8) and x) +1;
putvalue(value);
end;

procedure las;

begin;
value:=getvalue and sp;
sp:=value;
x:=value;
a:=value;
end;

procedure axs;

begin;
value := getvalue;;
x := word(a and x) - value;
if (x >= (value and $00FF)) then setcarry else clearcarry;
if (x = (byte(value and $00FF))) then setzero else clearzero;
if (x and $0080)<>0 then setsign else clearsign;
end;

procedure atx;

begin;
value := getvalue;;
a:=(a and value and $00FF);
x:=a;
if (a and $0080)<>0 then setsign else clearsign;
if (a and $00FF)<>0 then clearzero else setzero;
end;

procedure dop;

begin
// double nop
end;

procedure top;

begin
// double nop
end;

// end of opcodes

end.


