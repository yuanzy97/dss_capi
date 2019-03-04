unit CAPI_Fuses;

{$inline on}

interface

uses
    CAPI_Utils;

procedure Fuses_Get_AllNames(var ResultPtr: PPAnsiChar; ResultCount: PInteger); CDECL;
procedure Fuses_Get_AllNames_GR(); CDECL;
function Fuses_Get_Count(): Integer; CDECL;
function Fuses_Get_First(): Integer; CDECL;
function Fuses_Get_Name(): PAnsiChar; CDECL;
function Fuses_Get_Next(): Integer; CDECL;
procedure Fuses_Set_Name(const Value: PAnsiChar); CDECL;
function Fuses_Get_MonitoredObj(): PAnsiChar; CDECL;
function Fuses_Get_MonitoredTerm(): Integer; CDECL;
function Fuses_Get_SwitchedObj(): PAnsiChar; CDECL;
procedure Fuses_Set_MonitoredObj(const Value: PAnsiChar); CDECL;
procedure Fuses_Set_MonitoredTerm(Value: Integer); CDECL;
procedure Fuses_Set_SwitchedObj(const Value: PAnsiChar); CDECL;
function Fuses_Get_SwitchedTerm(): Integer; CDECL;
procedure Fuses_Set_SwitchedTerm(Value: Integer); CDECL;
function Fuses_Get_TCCcurve(): PAnsiChar; CDECL;
procedure Fuses_Set_TCCcurve(const Value: PAnsiChar); CDECL;
function Fuses_Get_RatedCurrent(): Double; CDECL;
procedure Fuses_Set_RatedCurrent(Value: Double); CDECL;
function Fuses_Get_Delay(): Double; CDECL;
procedure Fuses_Open(); CDECL;
procedure Fuses_Close(); CDECL;
procedure Fuses_Set_Delay(Value: Double); CDECL;
function Fuses_IsBlown(): Wordbool; CDECL;
function Fuses_Get_idx(): Integer; CDECL;
procedure Fuses_Set_idx(Value: Integer); CDECL;
function Fuses_Get_NumPhases(): Integer; CDECL;

implementation

uses
    CAPI_Constants,
    Executive,
    Sysutils,
    Fuse,
    Pointerlist,
    DSSGlobals;

procedure Set_Parameter(const parm: String; const val: String);
var
    cmd: String;
begin
    if not Assigned(ActiveCircuit) then
        exit;
    SolutionAbort := FALSE;  // Reset for commands entered from outside
    cmd := Format('Fuse.%s.%s=%s', [TFuseObj(FuseClass.GetActiveObj).Name, parm, val]);
    DSSExecutive.Command := cmd;
end;
//------------------------------------------------------------------------------
procedure Fuses_Get_AllNames(var ResultPtr: PPAnsiChar; ResultCount: PInteger); CDECL;
var
    Result: PPAnsiCharArray;
    elem: TFuseObj;
    pList: TPointerList;
    k: Integer;

begin
    Result := DSS_RecreateArray_PPAnsiChar(ResultPtr, ResultCount, (0) + 1);
    Result[0] := DSS_CopyStringAsPChar('NONE');
    if ActiveCircuit <> NIL then
    begin
        if FuseClass.ElementList.ListSize > 0 then
        begin
            pList := FuseClass.ElementList;
            DSS_RecreateArray_PPAnsiChar(Result, ResultPtr, ResultCount, (pList.ListSize - 1) + 1);
            k := 0;
            elem := pList.First;
            while elem <> NIL do
            begin
                Result[k] := DSS_CopyStringAsPChar(elem.Name);
                Inc(k);
                elem := pList.next;
            end;
        end;
    end;

end;

procedure Fuses_Get_AllNames_GR(); CDECL;
// Same as Fuses_Get_AllNames but uses global result (GR) pointers
begin
    Fuses_Get_AllNames(GR_DataPtr_PPAnsiChar, GR_CountPtr_PPAnsiChar)
end;

//------------------------------------------------------------------------------
function Fuses_Get_Count(): Integer; CDECL;
begin
    Result := 0;
    if ActiveCircuit <> NIL then
        Result := FuseClass.ElementList.ListSize;
end;
//------------------------------------------------------------------------------
function Fuses_Get_First(): Integer; CDECL;
var
    pElem: TFuseObj;
begin
    Result := 0;
    if ActiveCircuit <> NIL then
    begin
        pElem := FuseClass.ElementList.First;
        if pElem <> NIL then
            repeat
                if pElem.Enabled then
                begin
                    ActiveCircuit.ActiveCktElement := pElem;
                    Result := 1;
                end
                else
                    pElem := FuseClass.ElementList.Next;
            until (Result = 1) or (pElem = NIL);
    end;
end;
//------------------------------------------------------------------------------
function Fuses_Get_Name_AnsiString(): Ansistring; inline;
var
    elem: TFuseObj;
begin
    Result := '';
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Result := elem.Name;
end;

function Fuses_Get_Name(): PAnsiChar; CDECL;
begin
    Result := DSS_GetAsPAnsiChar(Fuses_Get_Name_AnsiString());
end;
//------------------------------------------------------------------------------
function Fuses_Get_Next(): Integer; CDECL;
var
    pElem: TFuseObj;
begin
    Result := 0;
    if ActiveCircuit <> NIL then
    begin
        pElem := FuseClass.ElementList.Next;
        if pElem <> NIL then
            repeat
                if pElem.Enabled then
                begin
                    ActiveCircuit.ActiveCktElement := pElem;
                    Result := FuseClass.ElementList.ActiveIndex;
                end
                else
                    pElem := FuseClass.ElementList.Next;
            until (Result > 0) or (pElem = NIL);
    end;
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_Name(const Value: PAnsiChar); CDECL;
// Set element active by name

begin
    if ActiveCircuit <> NIL then
    begin
        if FuseClass.SetActive(Value) then
        begin
            ActiveCircuit.ActiveCktElement := FuseClass.ElementList.Active;
        end
        else
        begin
            DoSimpleMsg('Fuse "' + Value + '" Not Found in Active Circuit.', 77003);
        end;
    end;
end;
//------------------------------------------------------------------------------
function Fuses_Get_MonitoredObj_AnsiString(): Ansistring; inline;
var
    elem: TFuseObj;
begin
    Result := '';
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Result := elem.MonitoredElementName;
end;

function Fuses_Get_MonitoredObj(): PAnsiChar; CDECL;
begin
    Result := DSS_GetAsPAnsiChar(Fuses_Get_MonitoredObj_AnsiString());
end;
//------------------------------------------------------------------------------
function Fuses_Get_MonitoredTerm(): Integer; CDECL;
var
    elem: TFuseObj;
begin
    Result := 0;
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Result := elem.MonitoredElementTerminal;
end;
//------------------------------------------------------------------------------
function Fuses_Get_SwitchedObj_AnsiString(): Ansistring; inline;
var
    elem: TFuseObj;
begin
    Result := '';
    elem := FuseClass.ElementList.Active;
    if elem <> NIL then
        Result := elem.ElementName;
end;

function Fuses_Get_SwitchedObj(): PAnsiChar; CDECL;
begin
    Result := DSS_GetAsPAnsiChar(Fuses_Get_SwitchedObj_AnsiString());
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_MonitoredObj(const Value: PAnsiChar); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Set_parameter('monitoredObj', Value);
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_MonitoredTerm(Value: Integer); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Set_parameter('monitoredterm', IntToStr(Value));
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_SwitchedObj(const Value: PAnsiChar); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Set_parameter('SwitchedObj', Value);
end;
//------------------------------------------------------------------------------
function Fuses_Get_SwitchedTerm(): Integer; CDECL;
var
    elem: TFuseObj;
begin
    Result := 0;
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Result := elem.ElementTerminal;
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_SwitchedTerm(Value: Integer); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Set_parameter('SwitchedTerm', IntToStr(Value));
end;
//------------------------------------------------------------------------------
function Fuses_Get_TCCcurve_AnsiString(): Ansistring; inline;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Result := elem.FuseCurve.Name
    else
        Result := 'No Fuse Active!';
end;

function Fuses_Get_TCCcurve(): PAnsiChar; CDECL;
begin
    Result := DSS_GetAsPAnsiChar(Fuses_Get_TCCcurve_AnsiString());
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_TCCcurve(const Value: PAnsiChar); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Set_parameter('FuseCurve', Value);
end;
//------------------------------------------------------------------------------
function Fuses_Get_RatedCurrent(): Double; CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Result := elem.RatedCurrent
    else
        Result := -1.0;
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_RatedCurrent(Value: Double); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Set_parameter('RatedCurrent', Format('%.8g ', [Value]));
end;
//------------------------------------------------------------------------------
function Fuses_Get_Delay(): Double; CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Result := elem.DelayTime
    else
        Result := -1.0;
end;
//------------------------------------------------------------------------------
procedure Fuses_Open(); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        elem.ControlledElement.Closed[0] := FALSE; // Open all phases
end;
//------------------------------------------------------------------------------
procedure Fuses_Close(); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        elem.Reset;
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_Delay(Value: Double); CDECL;
var
    elem: TFuseObj;
begin
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
        Set_parameter('Delay', Format('%.8g ', [Value]));
end;
//------------------------------------------------------------------------------
function Fuses_IsBlown(): Wordbool; CDECL;
// Return TRUE if any phase blown
var
    elem: TFuseObj;
    i: Integer;
begin
    Result := FALSE;
    elem := FuseClass.GetActiveObj;
    if elem <> NIL then
    begin
        for i := 1 to elem.nphases do
            if not elem.ControlledElement.Closed[i] then
                Result := TRUE;
    end;
end;
//------------------------------------------------------------------------------
function Fuses_Get_idx(): Integer; CDECL;
begin
    if ActiveCircuit <> NIL then
        Result := FuseClass.ElementList.ActiveIndex
    else
        Result := 0;
end;
//------------------------------------------------------------------------------
procedure Fuses_Set_idx(Value: Integer); CDECL;
var
    pFuse: TFuseObj;
begin
    if ActiveCircuit <> NIL then
    begin
        pFuse := FuseClass.Elementlist.Get(Value);
        if pFuse <> NIL then
            ActiveCircuit.ActiveCktElement := pFuse;
    end;
end;
//------------------------------------------------------------------------------
function Fuses_Get_NumPhases(): Integer; CDECL;
var
    pFuse: TFuseObj;
begin
    Result := 0;
    if ActiveCircuit <> NIL then
    begin
        pFuse := FuseClass.GetActiveObj;
        if pFuse <> NIL then
            Result := pFuse.NPhases;
    end;
end;
//------------------------------------------------------------------------------
end.