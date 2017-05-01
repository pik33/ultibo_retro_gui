unit scripttest;

{$mode objfpc}{$H+}

interface

uses
  uPSCompiler,
  uPSRuntime,
  retromalina;

const

  Script = 'program IPSTest; begin; box(0,128,400,32,0); outtextxyz(0,128,''hello from script'',15,2,2); end.';

procedure script1;

implementation

//The mandatory ScriptOnUses function which registers the functions for each included unit

function ScriptOnUses(Sender: TPSPascalCompiler; const Name: AnsiString): Boolean;

begin
  if Name = 'SYSTEM' then
  begin
    Sender.AddDelphiFunction('procedure outtextxyz(x,y:integer; t:string;c,xz,yz:integer)');
    Sender.AddDelphiFunction('procedure box(x,y,l,h,c:integer)');
  Result := True;
  end
else
  Result := False;
end;

//The execute script function which creates the objects, registers the functions and runs the script

procedure ExecuteScript(const Script: string);
var
  Compiler: TPSPascalCompiler;
  Exec: TPSExec;
  Data: AnsiString;


begin
  Compiler := TPSPascalCompiler.Create; // create an instance of the compiler.
  Compiler.OnUses := @ScriptOnUses; // assign the OnUses event.
  if not Compiler.Compile(Script) then  // Compile the Pascal script into bytecode.
  begin
    Compiler.Free;
    Exit;
  end;

  Compiler.GetOutput(Data); // Save the output of the compiler in the string Data.
  Compiler.Free; // After compiling the script, there is no need for the compiler anymore.

  Exec:=TPSExec.Create;  // Create an instance of the executer.

  Exec.RegisterDelphiFunction(@outtextxyz, 'outtextxyz', cdRegister);
  Exec.RegisterDelphiFunction(@box, 'box', cdRegister);

  if not Exec.LoadData(Data) then // Load the data from the Data string.
  begin
    Exec.Free;
    Exit;
  end;

  Exec.RunScript; // Run the script.
  Exec.Free; // Free the executer.
end;

procedure script1;

begin
  ExecuteScript(Script);
end;


end.


