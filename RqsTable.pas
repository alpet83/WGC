unit RqsTable;

interface
uses Windows, SysUtils, Forms, StdCtrls, ChTypes, ChShare, misk;

const
    S_BELOW = $01;
    S_ABOVE = $02;
    S_EQUIV = $04;
     S_UINC = $10;
     S_UDEC = $20;
     S_UNCH = $40;
    S_RANGE = $80;


var
   exmin, exmax: string; // Строки образца используются совместно всеми формами
   rqsUpdated: Boolean = FALSE;

procedure RqsInit (sAction: TSAction);
procedure SetRqs (exmin, exmax: string;
                  const csType, csRule : string;
                  const en : boolean;
                  var rrqs : TRequest);

procedure GetRqs (const rrqs: TRequest;
                  var exmin, exmax,
                  csType, csRule: boolean);

procedure SaveRqs;
procedure LoadRqs;
procedure UpdateRqsList;
procedure SendRqsList;


implementation
uses ChForm, ChCmd, ChConst, ChClient, ChLog, DataProvider;

var rqsHash, _rqsHash: DWORD;

procedure SendRqsList;
begin
 LogStr ('Отправка списка запросов.');
 SendMsg (CM_LDATA);
 SendDataEx (sRQSLIST, @csm.RqsLst, sizeof (TRqsList), csm.SelRqsCnt);{}
 rqsUpdated := FALSE;
 _rqsHash := rqsHash;
end;

procedure   RqsInit;
var n : byte;
begin
 if csm <> nil then
 for n := 1 to MaxRqs do
  with csm.RqsLst [n] do
   begin
    min := 0;
    max := 0;
    rule := 4;
    vsize := 4;
    sactn := sAction;
    ruleText := '=';
    typeText := 'DWORD';
   end;
end;

procedure   SetItem (var sbj : TComboBox; s : string);
var n : Integer;
begin
 n := sbj.ItemIndex;
 if n >= 0 then
    sbj.Items [n] := s
 else
  begin
   sbj.Items.Add (s);
   sbj.ItemIndex := 0;
  end;
end; // N


procedure SaveRqs;
var n : byte;
    e : Integer;
begin
 if (csm.CurrRqs >= 1) and (csm.CurrRqs <= MaxRqs) then else csm.CurrRqs := 1;
 with csm.svars.params do
 begin
  Val (MForm.ed_gbase.text,  startofs, e);
  Val (MForm.ed_gLimit.text, limitofs, e);
 end;
 with mForm do
 SetRqs (exmin, exmax,              // Examples
         btnType.caption, btnRule.caption,      // Conditions
         cb_enabled.Checked,                    // Is on
          csm.RqsLst [csm.CurrRqs]);
 csm.SelRqsCnt := 0;
 for n := 1 to 9 do
     if csm.RqsLst [n].Enabled then Inc (csm.SelRqsCnt); // увеличить кол-во активных запросов
 rqsHash := CalcHash (csm.RqsLst, sizeof (TRqsList) * 9);
 rqsUpdated := rqsHash <> _rqsHash;
end;


procedure GetRqs (const rrqs: TRequest;
                  var exmin, exmax,
                  csType, csRule: boolean);
begin
end; // GetRqs

// Выборка данных по запросу
procedure SetRqs;
var x : byte;
    s : string;
    sf : dword;
    e : integer;
    scale: Integer;
begin
 if (csType <> 'TEXT') and
     (csType <> 'WIDE') then
  begin
   exmin := StrExt (exmin);
   exmax := StrExt (exmax);
  end; 
 with mform do
 with rrqs, csm  do
  begin
   typeset := 0;
   scale := multp.Value;
   vview := _normal;
   if (scale = 0) then scale := 1;
   StrPCopy (ruleText, csRule);
   // Установка глобальных границ поиска
   s := csRule;
   enabled := en;
   sf := 0;
   // Установка флагов поиска
   for x := 1 to Length (s) do
    case s [x] of
     '>' : sf := sf or $01;
     '<' : sf := sf or $02;
     '=' : sf := sf or $04;
     '+' : sf := sf or $10; // Значение увеличилось
     '-' : sf := sf or $20; // Значение уменшилось
     '?' : sf := sf or $40; // Значение неизменилось
     '_' : sf := sf or $80;
     '*' : sf := sf or $100;
    end;
   rule := sf;
   // Установка флагов типа
   s := UpperCase (csType);
   StrPCopy (typeText, s);
   s := ConvType (s);
   // Преустановка
   _class := st_int;
   vsign := false;
   vsize := 0;
   str2type (s, _class, vsize);
   if _class = st_text then vsize := Length (exmin);
   if _class = st_wide then vsize := Length (exmin) * 2;
   if (_class = st_all) then
    begin
     // Самый тормозной тип поиска - по нескольким типам
     typeset := WHOLE2_TYPE or SINGLE_TYPE or REAL48_TYPE or DOUBLE_TYPE or EXTEND_TYPE;
     typeset := typeset or (ANTEXT_TYPE) or (WDTEXT_TYPE);
    end;
   if (_class = st_int) or (_class = st_real) then
   case vsize of
    1 : cmpOp := $38F3; // rep cmp  byte ptr []
    2 : cmpOp := $3966; // cmp  word ptr []
    4, 6, 8, 10 : cmpOp := $3990; // cmp dword ptr []
   end;

   if (_class = st_real) or (_class = st_all) then
    begin
     // replaceChar (exmin, ',', '.');
     minr := str2f (exmin) * scale;
     maxr := str2f (exmax) * scale;
     if sf and S_RANGE = 0 then maxr := minr;
    end;
   if (_class = st_int) or (_class = st_all) then
    begin
     exmin := unihex (exmin);
     exmax := unihex (exmax);
     val (exmin, min, e);
     if (pos ('$', exmin) = 1) then vview := _hex;
     if (e > 0) then
      begin
       min := Int64 (Time2dword (exmin)) * scale;
       vview := _time;
      end;
     val (exmax, max, e);
     if (e > 0) then max := Int64 (Time2dword (exmax)) * scale;
    end;
   FillChar (textEx, sizeOf (textEx), 0); // Сначала обнулить
   StrPCopy (textEx, exmin);
   //val (mform.
   if enabled then inc (csm.SelRqsCnt);
   jmpOP := $75;
   unknow := (rule in [$10..$7F]);     // Выставление поиск неизвестного значения
   with csm.SVars do
        uSearch := uSearch or Unknow;
   if not vsign then
    case rule of
     $10, $01 : jmpOP := $76; // if !(>) = JNA/JBE
     $20, $02 : jmpOP := $73; // if !(<) = JNB/JAE
     $30, $03 : jmpOP := $74; // if !(<>)= JE
$100,$40, $04 : jmpOP := $75; // if !(=) = JNE
     $14, $05 : jmpOP := $72; // if !(>=)= JNAE/JB
     $24, $06 : jmpOP := $77; // if !(<=)= JNBE/JA!
    end
   else
    case rule of
     $10, $01 : jmpOP := $7E; // if !(>) = JNG/JLE
     $20, $02 : jmpOP := $7D; // if !(<) = JNL/JGE
     $30, $03 : jmpOP := $74; // if !(<>)= JE
$100,$40, $04 : jmpOP := $75; // if !(=) = JNE
     $14, $05 : jmpOP := $7C; // if !(>=)= JNGE/JL
     $24, $06 : jmpOP := $7F; // if !(<=)= JNLE/JG
    end;

    setOP := (jmpOP and 15) or $90; // Для setcc операций
  end;
end; // SaveRqs


procedure   LoadRqs;
var
   scale: Integer;
begin
 with mform, csm.RqsLst [csm.CurrRqs] do
  begin
   scale := multp.Value;
   if (scale = 0) then scale := 1;
   btnRule.Caption := RuleText;
   btnType.Caption := TypeText;
   if _class = st_real then
    begin
     exmin := FloatToStr (minr / scale);
     if maxr <> 0 then exmax := FloatToStr (maxr / scale);
    end;
   if _class = st_int then
    begin
     if (vview = _normal) then
       begin
        exmin := IntToStr (min div scale);
        if max > 0 then exmax := IntToStr (max div scale);
       end;
     if (vview = _time) then
       begin
        exmin := dword2time (min div scale);
        if (max > 0) then exmax := dword2time (max div scale);
       end;
     if (vview = _hex) then
       begin
        exmin := format ('$%x', [min div scale]);
        if (max > 0) then exmax := format ('$%x', [max div scale]);
       end;
    end;
   cb_enabled.Checked := enabled;
  end;
 mform.SyncRqs; 
end; // LoadRqs

procedure  UpdateRqsList;

 function  ValueMin (const rqs : TRequest) : string;

 begin
  result := 'UNTYPED';
  case rqs._class of
     st_all,
     st_real : result := FloatToStr (rqs.minr);
     st_int : result := IntToStr (rqs.min);
    st_text,
    st_wide : result := '"' + rqs.textEx + '"';
  end;
 end; // ValueMin

 function  ValueMax (const rqs : TRequest) : string;

 begin
  result := 'UNTYPED';
  case rqs._class of
    st_all,
    st_real : result := FloatToStr (rqs.maxr);
     st_int : result := IntToStr (rqs.max);
    st_text,
    st_wide : result := '"' + rqs.textEx + '"';
  end;
 end; // ValueMax

var
   n,  i : byte;
       s : string;
   vmin, vmax : string;
begin
 i := 0;
 for n := 1 to MaxRqs do
 with mForm.RqsList, csm.RqsLst [n] do
  begin
   Inc (i);
   vmin := ValueMin (csm.RqsLst [n]);
   vmax := ValueMax (csm.RqsLst [n]);
   s := IntToStr (i) + '. V ';
   if rule and $02 <> 0 then s := s + '<';
   if rule and $01 <> 0 then s := s + '>';
   if rule and $04 <> 0 then s := s + '=';
   if rule and $10 <> 0 then s := s + '+';
   if rule and $20 <> 0 then s := s + '-';
   if rule and $40 <> 0 then s := s + '?';

   // Добавление образца в строку
   if rule and $80 <> 0 then s := s + 'in [' + vmin + '..' + vmax + ']'
                        else s := s + ' ' + vmin;
   s := s + ', Размер:' + IntToStr (vsize);
   s := s + ', Найдено:' +  IntToStr (csm.svars.fnds [n].foundCount);
   if enabled then s := s + ', Активен';
   while (Items.Count < i) do  items.Add (s);
   if mForm.RqsList.Items [i - 1] <> s then
      mForm.RqsList.Items [i - 1] := s;
   // ItemIndex := csm.CurrRqs - 1;
  end;
 mform.lRqsNum.caption := IntToStr (csm.CurrRqs);
end;

end.
