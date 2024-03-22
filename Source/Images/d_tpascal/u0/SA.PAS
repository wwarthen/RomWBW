program SA;

const
  MaxX = 100;
  MaxY = 50;

var
  FileName: string[15];

procedure ClearScreen;

begin
  Write(con, #27,'[2J')
end;


procedure Indent;

begin
  Write(con, #27,'[10G')
end;


procedure ShowArt;

var
  F: Text;
  Line:string[255];

begin
  assign(F, FileName);
  reset(F);
  while ((not Eof(F)) and (not KeyPressed)) do begin
    readln(F, Line);
    {Indent; }
    writeln(CON, Line);
    delay(12)
  end;
  close(f)
end;


var
  Running: boolean;
  Ch: char;

begin
  if paramcount > 0 then begin
    FileName:= Paramstr(1)
  end
  else begin
    FileName:= 'ART.TXT'
  end;
  ClearScreen;
  writeln('Press Q key to exit');
  writeln;
  Running:= true;
  while Running do begin
    ShowArt;
    if KeyPressed then begin
      read(kbd, ch);
      Running:= (ch <> 'q')
    end
  end
end.