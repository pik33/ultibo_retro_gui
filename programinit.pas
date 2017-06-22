unit ProgramInit;

interface

uses
  GlobalConfig,GlobalConst;

implementation

initialization
 //Disable Console Autocreate
 FRAMEBUFFER_CONSOLE_AUTOCREATE:=False;
 FRAMEBUFFER_DEFAULT_MODE:= FRAMEBUFFER_MODE_IGNORED;

end.
