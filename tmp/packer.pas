{$D-}
unit packer;

interface
uses Windows, SysUtils;

type
    TSignature = array [0..3] of char;
    TFname = array [0..11] of char;

    TBuffer = record
     ptr : pointer;
     msiz : dword;
     fsiz : dword;
    end;

    TPackRec = packed record
     sign : TSignature; // 4b
    fsize : dword; // 4b = Размер файла
    fname : TFName; // 12b = Имя файла (DOS ограничения)
    end;

procedure   PackFiles (const fnames : array of string;
                       const cnt : byte;
                       const dst : string);

function   UnpackFiles (const src : string;
                         var names : array of string;
                         const max : dword) : dword;

implementation

procedure   PackFiles;

var
   f, pf : file;
  hr : array [1..100] of TPackRec;
  bf : array [1..100] of TBuffer;
   n : byte;
   w, r : dword;
begin
 FillChar (bf, SizeOf (bf), 0);
 FillChar (hr, sizeOf (hr), '.');
 w := 0;
 for n := 1 to cnt do
 with hr [n] do
 if fileExists (fnames [n - 1]) then
  begin
   AssignFile (f, fnames [n - 1]);
   reset (f, 1);
   sign := 'PACK';
   fsize := fileSize (f);
   StrPCopy (fname, ExtractFileName (fnames [n - 1]));
   w := w + fsize;
   // Loading File To buffer
   GetMem (bf [n].ptr, fsize);
   BlockRead (f, bf [n].ptr^, fsize, r);
   bf [n].msiz := fsize;
   bf [n].fsiz := r;
   closeFile (f);
  end;
 assignFile (pf, dst);
 Rewrite (pf, 1);
 BlockWrite (pf, hr, cnt * SizeOf (TPackRec), r);
 FillChar (hr, sizeOf (hr), 0);
 hr [1].sign := 'DATA';   // Последний элемент
 hr [1].fsize := w;       // Размер всего файла
 StrPCopy (hr [1].fname, ExtractFileName (dst));
 BlockWrite (pf, hr, SizeOf (TPackRec), r);
 for n := 1 to cnt do
  begin
   BlockWrite (pf, bf [n].ptr^, bf [n].fsiz, r);
   FreeMem (bf [n].ptr, bf [n].msiz);
  end;
 CloseFile (pf);
end; // PackFiles

function   UnpackFiles;
var
   sf, df : file;
   hr : TPackRec;
   hrs : array [1..100] of TPackRec;
   r, n : dword;
   cnt : byte;
   buff : pointer;
    bsz : dword;
begin
 assignFile (sf, src);
 reset (sf, 1);
 cnt := 0;
 repeat
  blockRead (sf, hr, sizeOf (hr));
  if hr.sign = 'PACK' then // sign = 'PACK' or sign = 'DATA'
   begin
    names [cnt] := hr.fname;
    inc (cnt);
    hrs [cnt] := hr;
   end
  else break;
 until false;
 for n := 1 to cnt do
  begin
  {$I-}
   assignFile (df, hrs [n].fname);
   ReWrite (df, 1);
   bsz := hrs [n].fsize and $FFFFFF; // 16-meg limitation
   GetMem (buff, bsz);
   BlockRead (sf, buff^, bsz, r);
   BlockWrite (df, buff^, bsz, r);
   closeFile (df);
   FreeMem (buff, bsz);
  end;
 result := cnt;
 closeFile (sf);
end;

end.
