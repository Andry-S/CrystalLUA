unit CrystalLUA;

{******************************************************************************}
{ Copyright (c) 2010-2017 Dmitry Mozulyov                                      }
{                                                                              }
{ Permission is hereby granted, free of charge, to any person obtaining a copy }
{ of this software and associated documentation files (the "Software"), to deal}
{ in the Software without restriction, including without limitation the rights }
{ to use, copy, modify, merge, publish, distribute, sublicense, and/or sell    }
{ copies of the Software, and to permit persons to whom the Software is        }
{ furnished to do so, subject to the following conditions:                     }
{                                                                              }
{ The above copyright notice and this permission notice shall be included in   }
{ all copies or substantial portions of the Software.                          }
{                                                                              }
{ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   }
{ IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     }
{ FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  }
{ AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       }
{ LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,}
{ OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN    }
{ THE SOFTWARE.                                                                }
{                                                                              }
{ email: softforyou@inbox.ru                                                   }
{ skype: dimandevil                                                            }
{ repository: https://github.com/d-mozulyov/CrystalLUA                         }
{******************************************************************************}

// you can define LUA_INITIALIZE to create and destroy Lua: TLua instance automatically
//{$define LUA_INITIALIZE}

// you can choose encoding by define LUA_UNICODE or LUA_ANSI directly
// but if you ignore - it will be defined automatically by UNICODE directive case
//{$define LUA_UNICODE}
//{$define LUA_ANSI}

// you can disable Classes unit using if you want.
// it may minimize exe size for simple applications, such as a console
//{$define LUA_NOCLASSES}


// compiler directives
{$ifdef FPC}
  {$mode delphi}
  {$asmmode intel}
  {$define INLINESUPPORT}
  {$define INLINESUPPORTSIMPLE}
  {$ifdef CPU386}
    {$define CPUX86}
  {$endif}
  {$ifdef CPUX86_64}
    {$define CPUX64}
  {$endif}
{$else}
  {$if CompilerVersion >= 24}
    {$LEGACYIFEND ON}
  {$ifend}
  {$if CompilerVersion >= 15}
    {$WARN UNSAFE_CODE OFF}
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CAST OFF}
  {$ifend}
  {$if CompilerVersion >= 20}
    {$define INLINESUPPORT}
  {$ifend}
  {$if CompilerVersion >= 17}
    {$define INLINESUPPORTSIMPLE}
  {$ifend}
  {$if CompilerVersion < 23}
    {$define CPUX86}
  {$ifend}
  {$if CompilerVersion >= 23}
    {$define UNITSCOPENAMES}
    {$define RETURNADDRESS}
  {$ifend}
  {$if CompilerVersion >= 21}
    {$WEAKLINKRTTI ON}
    {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
  {$ifend}
  {$if (not Defined(NEXTGEN)) and (CompilerVersion >= 20)}
    {$define INTERNALCODEPAGE}
  {$ifend}
{$endif}
{$U-}{$V+}{$B-}{$X+}{$T+}{$P+}{$H+}{$J-}{$Z1}{$A4}
{$O+}{$R-}{$I-}{$Q-}{$W-}
{$if Defined(CPUX86) or Defined(CPUX64)}
  {$define CPUINTEL}
{$ifend}
{$if Defined(CPUX64) or Defined(CPUARM64)}
  {$define LARGEINT}
{$ifend}
{$if (not Defined(CPUX64)) and (not Defined(CPUARM64))}
  {$define SMALLINT}
{$ifend}
{$if Defined(FPC) or (CompilerVersion >= 18)}
  {$define OPERATORSUPPORT}
{$ifend}
{$ifdef KOL_MCK}
  {$define KOL}
{$endif}
{$ifdef KOL}
  {$defined LUA_NOCLASSES}
{$endif}

{$if Defined(LUA_UNICODE) and Defined(LUA_ANSI)}
  {$MESSAGE ERROR 'defined both encodings: LUA_UNICODE and LUA_ANSI'}
{$ifend}
{$if (not Defined(LUA_UNICODE)) and (not Defined(LUA_ANSI))}
   {$ifdef UNICODE}
      {$define LUA_UNICODE}
   {$else}
      {$define LUA_ANSI}
   {$endif}
{$ifend}

interface
  uses {$ifdef UNITSCOPENAMES}System.Types, System.TypInfo{$else}Types, TypInfo{$endif},
       {$ifdef MSWINDOWS}{$ifdef UNITSCOPENAMES}Winapi.Windows{$else}Windows{$endif},{$endif}
       {$ifdef POSIX}Posix.Base, Posix.String_, Posix.Unistd, Posix.SysTypes, Posix.PThread,{$endif}
       {$ifdef KOL}
         KOL, err
       {$else}
         {$ifdef UNITSCOPENAMES}System.SysUtils{$else}SysUtils{$endif}
       {$endif}
       {$ifNdef LUA_NOCLASSES}
         {$ifdef UNITSCOPENAMES}, System.Classes{$else}, Classes{$endif}
       {$endif};

type
  // standard types
  {$ifdef FPC}
    PUInt64 = ^UInt64;
  {$else}
    {$if CompilerVersion < 15}
      UInt64 = Int64;
      PUInt64 = ^UInt64;
    {$ifend}
    {$if CompilerVersion < 19}
      NativeInt = Integer;
      NativeUInt = Cardinal;
    {$ifend}
    {$if CompilerVersion < 22}
      PNativeInt = ^NativeInt;
      PNativeUInt = ^NativeUInt;
    {$ifend}
  {$endif}
  {$if Defined(FPC) or (CompilerVersion < 23)}
  TExtended80Rec = Extended;
  PExtended80Rec = ^TExtended80Rec;
  {$ifend}
  TBytes = array of Byte;
  PBytes = ^TBytes;

  // exception class
  ELua = class(Exception)
  {$ifdef KOL}
    constructor Create(const Msg: string);
    constructor CreateFmt(const Msg: string; const Args: array of const);
    constructor CreateRes(Ident: NativeUInt); overload;
    constructor CreateRes(ResStringRec: PResStringRec); overload;
    constructor CreateResFmt(Ident: NativeUInt; const Args: array of const); overload;
    constructor CreateResFmt(ResStringRec: PResStringRec; const Args: array of const); overload;
  {$endif}
  end;

  // CrystalLUA string types      
  {$if Defined(LUA_UNICODE) or Defined(NEXTGEN)}
    {$ifdef UNICODE}
      LuaString = UnicodeString;
      PLuaString = PUnicodeString;
    {$else}
      LuaString = WideString;
      PLuaString = PWideString;
    {$endif}
    LuaChar = WideChar;
    PLuaChar = PWideChar;
  {$else}
    LuaString = AnsiString;
    PLuaString = PAnsiString;
    LuaChar = AnsiChar;
    PLuaChar = PAnsiChar;
  {$ifend}

  // internal string identifier: utf8 or ansi
  __luaname = type {$ifdef NEXTGEN}PByte{$else}PAnsiChar{$endif};
  // internal character pointer: utf8 or ansi
  __luadata = type {$ifdef NEXTGEN}PByte{$else}PAnsiChar{$endif};
  // internal character storage: utf8 or ansi
  __luabuffer = type {$ifdef NEXTGEN}TBytes{$else}AnsiString{$endif};
  // internal memory offset (optional pointer in 32-bit platforms)
  __luapointer = type Integer;
  
  // internal containers
  __TLuaList = array[1..24{$ifdef LARGEINT}* 2{$endif}] of Byte;
  __TLuaDictionary = array[1..20{$ifdef LARGEINT}* 2{$endif}] of Byte;
  __TLuaCFunctionHeap = array[1..8{$ifdef LARGEINT}* 2{$endif}] of Byte;


type
  TLua = class;
  PLuaArg = ^TLuaArg;
//  PLuaTable = ^TLuaTable;
//  PLuaModule = ^TLuaModule;

  // incorrect script use exception
  ELuaScript = class(ELua);

  // Lua types, that is used between script and native side
  TLuaArgType = (
    // simple types
    ltEmpty, ltBoolean, ltInteger, ltDouble, ltString, ltPointer,
    // difficult types
    ltClass, ltObject, ltRecord, ltArray, ltSet, ltTable
    {ToDo: ltInterface, ltMethod, ltReference }
    );

  // internal base stucture for records, arrays, sets, etc (inside TLuaArg)
  __lua_difficult_type__ = object
  protected
    {$hints off}Align: array[0..1] of Byte; {FLuaType + align} {$hints on}
    FIsRef: Boolean;
    FIsConst: Boolean;
  public
    Data: Pointer;
    { info: information type }
    property IsRef: Boolean read FIsRef write FIsRef;
    property IsConst: Boolean read FIsConst write FIsConst;
  end;

  // internal types information
  __TLuaType = record
  (*  kind: integer;
    name: __luaname; 
    namespace: array[0..27] of byte; {__TLuaHashArray(__PLuaIdentifier)}
    metatable: integer; {ref}
    Lua: TLua;*)

  // TODO ��������!!!!!!  
  (*     // ������������ �������-������������/�����������
     __Create, __Free: pointer; //lua_CFunction
       // �������������� (�����������) �����������
       constructor_address: pointer;
       constructor_args_count: integer;
       // ��������� �� ����� assign(arg: tluaarg)
       assign_address: pointer; *)
  end;
  __PLuaType = ^__TLuaType;

  // Record instance information: Pointer/IsRef/IsConst/RecordInfo
  PLuaRecordInfo = Pointer;//^TLuaRecordInfo;
  TLuaRecord = object(__lua_difficult_type__)
  public
    Info: PLuaRecordInfo;
  end;
  PLuaRecord = ^TLuaRecord;

  // Array instance information: Pointer/IsRef/IsConst/ArrayInfo
  PLuaArrayInfo = Pointer;//^TLuaArrayInfo;
  TLuaArray = object(__lua_difficult_type__)
  public
    Info: PLuaArrayInfo;
  end;
  PLuaArray = ^TLuaArray;

  // Set instance information: Pointer/IsRef/IsConst/SetInfo
  PLuaSetInfo = Pointer;//^TLuaSetInfo;
  TLuaSet = object(__lua_difficult_type__)
  public
    Info: PLuaSetInfo;
  end;
  PLuaSet = ^TLuaSet;

  // universal CrystalLUA argument
  TLuaArg = object
  private
   // str_data: string;
  //  FLuaType: TLuaArgType;
    {$hints off} align: array[0..2] of byte;{ <-- �������������� ������. ����� �������� ��� TLuaTable}{$hints on} 
  //  Data: array[0..1] of integer;
 (*   procedure Assert(const NeededType: TLuaArgType; const CodeAddr: pointer);

    function  GetLuaTypeName: string;    
    function  GetEmpty: boolean;
    procedure SetEmpty(const Value: boolean);
    function  GetBoolean: boolean;
    procedure SetBoolean(const Value: boolean);
    function  GetInteger: integer;
    procedure SetInteger(const Value: integer);
    function  GetDouble: double;
    procedure SetDouble(Value: double);
    function  GetString: string;
    procedure SetString(const Value: string);
    function  GetPointer: pointer;
    procedure SetPointer(const Value: pointer);
    function  GetVariant: Variant;
    procedure SetVariant(const Value: Variant);
    function  GetClass: TClass;
    procedure SetClass(const Value: TClass);
    function  GetObject: TObject;
    procedure SetObject(const Value: TObject);
    function  GetRecord: TLuaRecord;
    procedure SetRecord(const Value: TLuaRecord);
    function  GetArray: TLuaArray;
    procedure SetArray(const Value: TLuaArray);
    function  GetSet: TLuaSet;
    procedure SetSet(const Value: TLuaSet);
    function  GetTable: PLuaTable;    *)
  public
  (*  property LuaType: TLuaArgType read FLuaType;
    property LuaTypeName: string read GetLuaTypeName;
    property Empty: boolean read GetEmpty write SetEmpty;
    property AsBoolean: boolean read GetBoolean write SetBoolean;
    property AsInteger: integer read GetInteger write SetInteger;
    property AsDouble: double read GetDouble write SetDouble;
    property AsString: string read GetString write SetString;
    property AsPointer: pointer read GetPointer write SetPointer;
    property AsVariant: Variant read GetVariant write SetVariant;
    property AsClass: TClass read GetClass write SetClass;
    property AsObject: TObject read GetObject write SetObject;
    property AsRecord: TLuaRecord read GetRecord write SetRecord;
    property AsArray: TLuaArray read GetArray write SetArray;
    property AsSet: TLuaSet read GetSet write SetSet;
    property AsTable: PLuaTable read GetTable;

    function ForceBoolean: boolean;
    function ForceInteger: integer;
    function ForceDouble: double;
    function ForceString: string;
    function ForcePointer: pointer;
    function ForceVariant: Variant;
    function ForceClass: TClass;
    function ForceObject: TObject;
    function ForceRecord: TLuaRecord;
    function ForceArray: TLuaArray;
    function ForceSet: TLuaSet;
    function ForceTable: PLuaTable; *)
  end;
  TLuaArgs = array of TLuaArg;

                           (*
  // highlevel interface to traverse table items with pair <Key, Value>
  TLuaPair = object
  private
  {$hints off}
    Mode: integer; // ������. ��������. �����.
    Lua: TLua;
    Handle: pointer; // TLua.Handle
    Index: integer; // ����������� ������ �������
    KeyIndex, ValueIndex: integer; // ����������� ������� ��� ����� � ��������
    FIteration: integer; // ������� ��������

    procedure ThrowNotInitialized(const CodeAddr: pointer);
    procedure ThrowValueType(const CodeAddr: pointer; const pop: boolean=false);
    procedure ThrowBroken(const CodeAddr: pointer; const Action: string);
    function  Initialize(const ALua: TLua; const AIndex: integer; const UseKey: boolean): boolean;
    function  GetKey: string;
    function  GetKeyEx: Variant;
    function  GetValue: Variant;
    function  GetValueEx: TLuaArg;
    procedure SetValue(const AValue: Variant);
    procedure SetValueEx(const AValue: TLuaArg);
    function  GetBroken: boolean;
  public
    function  Next(): boolean;
    procedure Break();

    property Iteration: integer read FIteration;
    property Broken: boolean read GetBroken;
    property Key: string read GetKey;
    property KeyEx: Variant read GetKeyEx;
    property Value: Variant read GetValue write SetValue;
    property ValueEx: TLuaArg read GetValueEx write SetValueEx;
  end;
  {$hints on}      *)
                               (*
  // highlevel interface to read and modify Lua-tables
  TLuaTable = object
  private
    {$hints off}none: byte; {TLuaArgType = ltTable} {$hints on}
    {$hints off}
    {����� 3 ��������� �����} align: array[0..2] of byte;  
    Lua: TLua;
    Index_: integer;
    function  GetLength: integer;
    function  GetCount: integer;

    procedure ThrowValueType(const CodeAddr: pointer; const pop: boolean=false);
    function  GetValue(const AIndex: integer): Variant;
    procedure SetValue(const AIndex: integer; const NewValue: Variant);
    function  GetValueEx(const AIndex: integer): TLuaArg;
    procedure SetValueEx(const AIndex: integer; const NewValue: TLuaArg);
    function  GetKeyValue(const Key: string): Variant;
    procedure SetKeyValue(const Key: string; const NewValue: Variant);
    function  GetKeyValueEx(const Key: Variant): TLuaArg;
    procedure SetKeyValueEx(const Key: Variant; const NewValue: TLuaArg);
  public
    // ������� ���������
    function Pairs(var Pair: TLuaPair): boolean; overload;
    function Pairs(var Pair: TLuaPair; const FromKey: Variant): boolean; overload;

    // ������
    property Length: integer read GetLength; // ������ (��� ��������)
    property Count: integer read GetCount; // ����� ���������� ���������

    // ��������
    property Value[const Index: integer]: Variant read GetValue write SetValue;
    property KeyValue[const Key: string]: Variant read GetKeyValue write SetKeyValue;
    property ValueEx[const Index: integer]: TLuaArg read GetValueEx write SetValueEx;
    property KeyValueEx[const Key: Variant]: TLuaArg read GetKeyValueEx write SetKeyValueEx;
  end;
  {$hints on}       *)
                      (*
  // ������
  // ������� ��� �������� ������������ ����������� ���������, ����������� ��� Lua
  TLuaReference = class
  private
    Index: integer;
    Data: TLuaTable;
    FLocked: boolean;

    procedure Initialize(const ALua: TLua);
    procedure ThrowLocked(const Operation: string; const CodeAddr: pointer);
    procedure ThrowValueType(const CodeAddr: pointer);
    function  GetValue: Variant;
    function  GetValueEx: TLuaArg;
    procedure SetValue(const NewValue: Variant);
    procedure SetValueEx(const NewValue: TLuaArg);
  private
    property Lua: TLua read Data.Lua write Data.Lua;
    property Locked: boolean read FLocked write FLocked;
  public
    destructor Destroy; override;
    function AsTableBegin(var Table: PLuaTable): boolean;
    function AsTableEnd(var Table: PLuaTable): boolean;

    property Value: Variant read GetValue write SetValue;
    property ValueEx: TLuaArg read GetValueEx write SetValueEx;
  end;
  TLuaReferenceDynArray = array of TLuaReference;
  {$hints on}     *)

  // operators
  TLuaOperator = (loNeg, loAdd, loSub, loMul, loDiv, loMod, loPow, loCompare);
  TLuaOperators = set of TLuaOperator;
  TLuaOperatorCallback = procedure(var _Result, _X1, _X2; const Kind: TLuaOperator);

         (*
  // all information (such as name, field, methods)
  // you should use it to operate records between native and script
  // todo ����������� ���� ?
  TLuaRecordInfo = object
  private
    FLua: TLua; // FType: __TLuaType;
    FClassIndex: integer;
    FTypeInfo: ptypeinfo;
    FName: string;
    FSize: integer;
    FOperators: TLuaOperators;
    FOperatorCallback: TLuaOperatorCallback;

    function  GetFieldsCount: integer;
    procedure InternalRegField(const FieldName: string; const FieldOffset: integer; const tpinfo: pointer; const CodeAddr: pointer);
    procedure SetOperators(const Value: TLuaOperators);
    procedure SetOperatorCallback(const Value: TLuaOperatorCallback);
  public
    procedure RegField(const FieldName: string; const FieldOffset: integer; const tpinfo: pointer); overload;
    procedure RegField(const FieldName: string; const FieldPointer: pointer; const tpinfo: pointer; const pRecord: pointer = nil); overload;
    procedure RegProc(const ProcName: string; const Proc: TLuaClassProc; const ArgsCount: integer=-1);

    property Name: string read FName;
    property Size: integer read FSize;
    property FieldsCount: integer read GetFieldsCount;
    property Operators: TLuaOperators read FOperators write SetOperators;
    property OperatorCallback: TLuaOperatorCallback read FOperatorCallback write SetOperatorCallback;
  end;    *)
            (*
  // information needed to use arrays between native and script side
  // ���������� � �������
  TLuaArrayInfo = object
  private
    // FType: __TLuaType;
    // ��������
    FName: string;
    FClassIndex: integer;    
    FIsDynamic: boolean;
    ItemInfo: array[0..31] of byte; // TLuaPropertyInfo;

    // �����������
    FBoundsData: TIntegerDynArray; // ����������� ������ ��� �����������
    FBounds: pinteger;
    FDimention: integer;
    FItemSize: integer; // ������ ��������. ����� ��� ������� ��������    
    FMultiplies: TIntegerDynArray; // ��������� (����) � typeinfo (���)

    // ��� �����������
    FTypeInfo: ptypeinfo; // �������� ������� ����������� (��� nil). ��� �������� c typeinfo - ��� ��� ������
    FItemsCount: integer; // ���������� ���������. ��� �������� c typeinfo - 1
    FSize: integer; // ������ ������ ������� �������. ��� ������������ - 4
  public
    property Name: string read FName;
    property IsDynamic: boolean read FIsDynamic;
    property Bounds: pinteger read FBounds;
    property Dimention: integer read FDimention;
  end;        *)
                        (*
  // information needed to use set between native and script side
  // todo ����������� ���� ?
  TLuaSetInfo = object
  private
    // FType: __TLuaType;
    FName: string;
    FClassIndex: integer;
    FTypeInfo: ptypeinfo;
    FSize: integer;
    FLow: integer;
    FHigh: integer;
    FCorrection: integer;
    FRealSize: integer; // ��� ���� ����� ������ ��� ���� ����� �������� ������������� 3� ������� (� sizeof = 4) ���������
    FAndMasks: integer; // ��� ��������� ��� �������������� (�������� ����) or (��������� ���� shl 8)

    //function  EnumName(const Value: integer): string;
    function  Description(const X: pointer): string;
  public
    property Name: string read FName;
    property Size: integer read FSize;
    property Low: integer read FLow;
    property High: integer read FHigh;
  end;        *)


  // ���������� ������ ��� �������� ------------------------------------------
  {|}   { ���������� �� ��������� }
  {|}   TLuaProcInfo = record
  {|}     ProcName: string;
  {|}
  {|}     ArgsCount: integer;
  {|}     Address: pointer;
  {|}     with_class: boolean; // class function ProcName(...)
  {|}     lua_CFunction: pointer; // ��������������� "callback" ������� ������������ � lua. �� ������������ ����� � TLua.CallbackProc
  {|}   end;
  {|}   PLuaProcInfo = ^TLuaProcInfo;
  {|}   TLuaProcInfoDynArray = array of TLuaProcInfo;
  {|}
  {|}
  {|}   // ��� ������������� ������� ������� ����� ������������ (� ������������ CrystalLUA)
  {|}   TLuaPropertyKind = (pkUnknown, pkBoolean, pkInteger, pkInt64, pkFloat,
  {|}                       pkObject, pkString, pkVariant, pkInterface,
  {|}                       pkPointer, pkClass, pkRecord, pkArray, pkSet, pkUniversal);
  {|}
  {|}   // ������������� ����� ��������
  {|}   TLuaPropBoolType = (btBoolean, btByteBool, btWordBool, btLongBool);
  {|}
  {|}   // ������������� "�����"
  {|}   TLuaPropStringType = (stShortString, stAnsiString, stWideString, {todo UnicodeString?,} stAnsiChar, stWideChar);
  {|}
  {|}   // ������� ����������
  {|}   TLuaPropertyInfoBase = packed record
  {|}     Information: pointer; // typeinfo ��� ��������������� ����������: �� �����������, ��������� � �����������
  {|}     Kind: TLuaPropertyKind; // ��� ��������
  {|}     case Integer of
  {|}       0: (OrdType: {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.TOrdType);
  {|}       1: (FloatType: {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.TFloatType);
  {|}       2: (StringType: TLuaPropStringType; str_max_len: byte {��� shortstring-��});
  {|}       3: (BoolType: TLuaPropBoolType);
  {|}   end;
  {|}
  {|}   // ���������� ����������� ������ ��� ���������������� ��������
  {|}   TLuaPropertyInfoCompact = object
  {|}     // ������� ����������: ���, �������������, "typeinfo"
  {|}     Base: TLuaPropertyInfoBase;
  {|}
  {|}     // ������ ������ � ������; ���, ������� ��� ��������
  {|}     read_mode: integer;
  {|}     write_mode: integer;
  {|}   end;
  {|}
  {|}   { ������ ������ �� �������� }
  {|}   { ���������� �� ����������� ������ � ������������ ������ �� ������� (+ ������������� �� RTTI) }
  {|}   TLuaPropertyInfo = object(TLuaPropertyInfoCompact)
  {|}     PropertyName: string;
  {|}
  {|}     // ���������� � ��������
  {|}     IsRTTI: boolean;
  {|}     PropInfo: PPropInfo;
  {|}
  {|}     // ��� ������������������� ������� (INDEXED_PROPERTY, NAMED_PROPERTY ��� PLuaRecordInfo)
  {|}     Parameters: pointer;
  {|}              (*
  {|}     // ������
  {|}     procedure Cleanup();
  {|}     procedure Fill(const RTTIPropInfo: PPropInfo; const PropBase: TLuaPropertyInfoBase); overload;
  {|}     procedure Fill(const class_info; const PropBase: TLuaPropertyInfoBase; const PGet, PSet: pointer; const AParameters: PLuaRecordInfo); overload;
  {|}
  {|}     // �������� (���, �������, r/w)
  {|}     function Description(): string;  *)
  {|}   end;
  {|}   PLuaPropertyInfo = ^TLuaPropertyInfo;
  {|}   TLuaPropertyInfoDynArray = array of TLuaPropertyInfo;
  {|}
  {|}   { ��������� ���������, ������� ������������ ��� push/pop ������� ��� ������������ __index/__newindex }
  {|}   TLuaPropertyStruct = packed record
  {|}     PropertyInfo: PLuaPropertyInfo;
  {|}     Instance: pointer;
  {|}     Index: pointer; // ��������� �� ��������� ��� ������ ������� �������
  {|}     ReturnAddr: pointer; // ���� �� nil, �� ���������� �� �������� �������
  {|}
  {|}     case boolean of
  {|}       false: (IsConst: boolean); // ����� �������� ��� __index_prop_push
  {|}        true: (StackIndex: integer); // ����� �������� ��� __newindex_prop_set
  {|}   end;
  {|}   PLuaPropertyStruct = ^TLuaPropertyStruct;
  {|}
  {|}   { ���������� � ���������� ����������: ������ Lua ��� �������� }
  {|}   TLuaGlobalKind = (gkType, gkVariable, gkProc, gkConst, gkLuaData);
  {|}   TLuaGlobalVariable  = packed record
  {|}     _Name: string;
  {|}     _Kind: TLuaGlobalKind;
  {|}     IsConst: boolean; // ���� ���������, �� ������ ������ �� ���� ��� ��� ����� Variables[]
  {|}     case boolean of
  {|}       false: (Ref: integer); // ������ � ������� LUA_GLOBALSINDEX
  {|}        true: (Index: integer); // �������� ������. ������������� ��� ������� � ������������� ��� ������� (���������� ����������)
  {|}   end;
  {|}   PLuaGlobalVariable = ^TLuaGlobalVariable;
  {|}   TLuaGlobalVariableDynArray = array of TLuaGlobalVariable;
  {|}
  {|}   { ��� - ��������� ��� ������-�� ��������}
  {|}   { ��� �� �������� ������ . � ������ �������� Hash }
  {|}   TLuaHashIndex = record
  {|}     Hash: integer;
  {|}     Index: integer;
  {|}   end;
  {|}   TLuaHashIndexDynArray = array of TLuaHashIndex;
  {|}
  {|}   { ���������� �� ������ . ��� ��������� � �������� }
  {|}   { � ��� �� ������ ��� }
  {|}   TLuaClassKind = (ckClass, ckRecord, ckArray, ckSet);
  {|}   TLuaClassInfo = object
  {|}   private
  {|}     // ������ ��������� ���. ����� ��� ���� ����� ��������� �������� � ������������ ���
  {|}     //Names: TLuaHashIndexDynArray;
  {|}     // ���������� ������. ������������� (��� �������) ��� ������������� (��� �������)
  {|}     //function  InternalAddName(const Name: string; const AsProc: boolean; var Initialized: boolean; const CodeAddr: pointer): integer;
  {|}   private
  {|}     // ������������ �������-������������/�����������
  {|}     (*__Create, __Free: pointer; //lua_CFunction
  {|}     // �������������� (�����������) �����������
  {|}     constructor_address: pointer;
  {|}     constructor_args_count: integer;
  {|}     // ��������� �� ����� assign(arg: tluaarg)
  {|}     assign_address: pointer;
  {|}
  {|}     // ������ ������ ��� ������� �������. Index = {1: is_proc, 15: class_index, 16: index}
  {|}     // � global native ������������ ��� ������ �� ���� ���������� ���������� (���� ��������)
  {|}     NameSpace: TLuaHashIndexDynArray;     *)
  {|}     //function NameSpacePlace(const Lua: TLua; const Name: pchar; const NameLength: integer; var ProcInfo, PropertyInfo: pointer): integer;
  {|}   public  
  {|}     _Class: pointer;  // TClass, PLuaRecordInfo, PLuaArrayInfo, PLuaSetInfo
  {|}     _ClassKind: TLuaClassKind;
  {|}     _ClassSimple: boolean; // ��� ������������ ������ � ������� ������� � ����������
  {|}     _ClassName: string; // ��� ����: ������ ��� ���������
  {|}     _ClassIndex: integer;
  {|}     _DefaultProperty: integer; // �������� �� ���������: (AX: ClassIndex, AY: PropertyIndex)
  {|}     ParentIndex: integer;
  {|}     Ref: integer;
  {|}
  {|}     Procs: TLuaProcInfoDynArray; // ������, �������
  {|}     Properties: TLuaPropertyInfoDynArray; // ��������
  {|}
  {|}     //function  PropertyIdentifier(const Name: string = ''): string;
  {|}     //procedure Cleanup();
  {|}   end;
  {|}   PLuaClassInfo = ^TLuaClassInfo;
  {|}   TLuaClassInfoDynArray = array of TLuaClassInfo;
  {|}
  {|}   TLuaClassIndex = record
  {|}     _Class: pointer; // TClass ��� PLuaRecordInfo ��� PLuaArrayInfo ��� typeinfo(Record) ��� typeinfo(DynamicArray)
  {|}     Index: integer;
  {|}   end;
  {|}   TLuaClassIndexDynArray = array of TLuaClassIndex;
  {|}
  {|}   TLuaGlobalModifyInfo = packed record
  {|}     Name: string;
  {|}     CodeAddr: pointer;
  {|}     IsVariant: boolean;
  {|}     case boolean of
  {|}       false: (Arg: PLuaArg);
  {|}        true: (V: PVariant);
  {|}   end;
  {|}
  {|}   // TObject, ��������� �� ���������, ������, ����������� ������,
  {|}   // ������� �������� �������� ��� ���������. ����� ������� ������
  {|}   TLuaUserData = packed record
  {|}     instance: pointer; // ������, ��� ������� ������������ ��������
  {|}
  {|}     // �����
  {|}     kind: (ukInstance, ukArray, ukProperty, ukSet);
  {|}     array_params: byte; // ����������(4bits)/����������(4bits) ���������� �� �������� � ������� ���������
  {|}     is_const: boolean; // ��� ������������ �������� � ��������
  {|}     gc_destroy: boolean; // �������������� ���������� ������ lua
  {|}
  {|}     // Info
  {|}     case integer of
  {|}       0: (ClassIndex: integer); // integer, ������ ��� �������� ������������ user data
  {|}       1: (ArrayInfo: PLuaArrayInfo); // ������ ���������
  {|}       2: (SetInfo: PLuaSetInfo); // ������ ���������
  {|}       3: (PropertyInfo: PLuaPropertyInfo); // ���������. ������� ������������ ���������
  {|}   end;
  {|}   PLuaUserData = ^TLuaUserData;
  {|}
  {|}   TLuaResultBuffer = object
  {|}   private
  {|}    (* Memory: pointer;
  {|}     Size: integer;
  {|}     items_count: integer;
  {|}     tpinfo: ptypeinfo;
  {|}                   *)
  {|}     //procedure Finalize(const free_mem: boolean=false);
  {|}   public
  {|}     (*function  AllocRecord(const RecordInfo: PLuaRecordInfo): pointer;
  {|}     function  AllocArray(const ArrayInfo: PLuaArrayInfo): pointer;
  {|}     function  AllocSet(const SetInfo: PLuaSetInfo): pointer;  *)
  {|}   end;
  // <<-- ���������� ������ ��� �������� -------------------------------------


  TLuaUnitLineInfo = record
    Str: pchar;
    Length: integer;
  end;
  TLuaUnitLineInfoDynArray = array of TLuaUnitLineInfo;

  
  TLuaUnit = class(TObject)
  private    (*
    FName: string;
    FFileName: string;
    FText: string;
    FLinesCount: integer;
    FLinesInfo: TLuaUnitLineInfoDynArray; *)
     (*
    procedure InitializeLinesInfo();
    function GetLine(index: integer): string;
    function GetLineInfo(index: integer): TLuaUnitLineInfo; *)
  public
   (* procedure SaveToStream(const Stream: TStream);
    procedure SaveToFile(const FileName: string); overload;
    procedure SaveToFile(); overload;

    property Name: string read FName;
    property FileName: string read FFileName;
    property Text: string read FText;
    property LinesCount: integer read FLinesCount;
    property Lines[index: integer]: string read GetLine; default;
    property LinesInfo[index: integer]: TLuaUnitLineInfo read GetLineInfo;*)
  end;
  TLuaUnitDynArray = array of TLuaUnit;


{ TLua class
  Script and registered types/functions manager }

  TLua = class(TObject)
  private
    // unicode routine
    FCodePage: Word;
    FUnicodeTable: array[Byte] of Word;
    FUTF8Table: array[Byte] of Cardinal;

    procedure SetCodePage(Value: Word);
    function AnsiFromUnicode(ADest: PAnsiChar; ACodePage: Word; ASource: PWideChar; ALength: Integer): Integer;
    procedure UnicodeFromAnsi(ADest: PWideChar; ASource: PAnsiChar; ACodePage: Word; ALength: Integer);
    { class function Utf8FromUnicode(ADest: PAnsiChar; ASource: PWideChar; ALength: Integer): Integer; static; }
    { class function UnicodeFromUtf8(ADest: PWideChar; ASource: PAnsiChar; ALength: Integer): Integer; static; }
    function Utf8FromAnsi(ADest: PAnsiChar; ASource: PAnsiChar; ACodePage: Word; ALength: Integer): Integer;
    function AnsiFromUtf8(ADest: PAnsiChar; ACodePage: Word; ASource: PAnsiChar; ALength: Integer): Integer;
    function AnsiFromAnsi(ADest: PAnsiChar; ADestCodePage: Word; ASource: PAnsiChar; ASourceCodePage: Word; ALength: Integer): Integer;

  private
    // �������������� ����
   (* FHandle: pointer;
    FPreprocess: boolean;
    //FBufferArg: TLuaArg;
    FResultBuffer: TLuaResultBuffer;
 //   FReferences: TLuaReferenceDynArray; // ������ ������ (LUA_REGISTRYINDEX)
    FUnitsCount: integer;
    FUnits: TLuaUnitDynArray; *)
 (*   procedure Check(const ret: integer; const CodeAddr: pointer; AUnit: TLuaUnit=nil); // ��������� �� ������
    procedure InternalLoadScript(var Memory: string; const UnitName, FileName: string; CodeAddr: pointer);
    function  InternalCheckArgsCount(PArgs: pinteger; ArgsCount: integer; const ProcName: string; const AClass: TClass): integer;
    function  StackArgument(const Index: integer): string;
    function  GetUnit(const index: integer): TLuaUnit;
    function  GetUnitByName(const Name: string): TLuaUnit;   *)
                                                 (*
    // ������� ����
    function  push_userdata(const ClassInfo: TLuaClassInfo; const gc_destroy: boolean; const Data: pointer): PLuaUserData;
    function  push_difficult_property(const Instance: pointer; const PropertyInfo: TLuaPropertyInfo): PLuaUserData;
    function  push_variant(const Value: Variant): boolean;
    function  push_luaarg(const LuaArg: TLuaArg): boolean;
    function  push_argument(const Value: TVarRec): boolean;
    *)  (*
    // �������������� �� ������
    procedure stack_pop(const count: integer=1);
    function  stack_variant(var Ret: Variant; const StackIndex: integer): boolean;
    function  stack_luaarg(var Ret: TLuaArg; const StackIndex: integer; const lua_table_available: boolean): boolean;  *)
  private
    // ���������� ������������
    // ���������� ���������, ����������, ������� ���������� ���������� �� Lua
   (* FRef: integer;
    GlobalNative: TLuaClassInfo; // ��������: ������ � ���������
    GlobalVariables: TLuaGlobalVariableDynArray; // ������ ������ ������� Lua-����������
  //  property  NameSpaceHash: TLuaHashIndexDynArray read GlobalNative.NameSpace; // Hash �� ���� ���������� ���������� � ��������
  *)           (*
    // ������ � ���������� ���-��������
    procedure global_alloc_ref(var ref: integer);
    procedure global_free_ref(var ref: integer);
    procedure global_fill_value(const ref: integer);
    procedure global_push_value(const ref: integer);     *)

    // ����� ���������� ����������. ���� false, �� Index - place � hash ������ ���������� ���
 //   function  GlobalVariablePos(const Name: pchar; const NameLength: integer; var Index: integer; const auto_create: boolean=false): boolean;
  private
    // �������������, ���������� �� �������
   (* FInitialized: boolean;
    ClassesInfo: TLuaClassInfoDynArray;
    mt_properties: integer;
    cfunction_assign: pointer;
    cfunction_inherits_from: pointer;
    cfunction_tostring: pointer; // �������������� ���������� � userdata � ������
    cfunction_dynarray_resize: pointer;
    cfunction_array_include: pointer;
    cfunction_set_include: pointer;
    cfunction_set_exclude: pointer;
    cfunction_set_contains: pointer;
    ClassesIndexes: TLuaClassIndexDynArray; // ������� ��������� �� �������, ���������� � ��������
    ClassesIndexesByName: TLuaClassIndexDynArray; // �� �� ����� �� ������
    EnumerationList: TIntegerDynArray; // ������ enumeration typeinfo, ����� �� ��������� ��� �� �������������� Enum-�
  *)     (*
    procedure INITIALIZE_NAME_SPACE();
    function  internal_class_index(AClass: pointer; const look_class_parents: boolean = false): integer;
    function  internal_class_index_by_name(const AName: string): integer;
    function  internal_add_class_info(const is_global_space: boolean = false): integer;
    function  internal_add_class_index(const AClass: pointer; const AIndex: integer): integer;
    function  internal_add_class_index_by_name(const AName: string; const AIndex: integer): integer;
    function  internal_register_global(const Name: string; const Kind: TLuaGlobalKind; const CodeAddr: pointer): PLuaGlobalVariable;
    function  internal_register_metatable(const CodeAddr: pointer; const GlobalName: string=''; const ClassIndex: integer = -1; const is_global_space: boolean = false): integer;
    function  InternalAddClass(AClass: TClass; UsePublished: boolean; const CodeAddr: pointer): integer;
    function  InternalAddRecord(const Name: string; tpinfo, CodeAddr: pointer): integer;
    function  InternalAddArray(Identifier, itemtypeinfo, CodeAddr: pointer; const ABounds: array of integer): integer;
    function  InternalAddSet(tpinfo, CodeAddr: pointer): integer;
    function  InternalAddProc(const IsClass: boolean; AClass: pointer; const ProcName: string; ArgsCount: integer; const with_class: boolean; Address, CodeAddr: pointer): integer;
    function  InternalAddProperty(const IsClass: boolean; AClass: pointer; const PropertyName: string; tpinfo: ptypeinfo; const IsConst, IsDefault: boolean; const PGet, PSet, Parameters, CodeAddr: pointer): integer;
               *) (*
    function __tostring(): integer;
    function __inherits_from(): integer;
    function __assign(): integer;
    function __initialize_by_table(const userdata: PLuaUserData; const stack_index: integer): integer;
    function __tmethod_call(const Method: TMethod): integer;
    function __index_prop_push(const ClassInfo: TLuaClassInfo; const prop_struct: PLuaPropertyStruct): integer;
    function __newindex_prop_set(const ClassInfo: TLuaClassInfo; const prop_struct: PLuaPropertyStruct): integer;
    function __len(const ClassInfo: TLuaClassInfo): integer;
    function __operator(const ClassInfo: TLuaClassInfo; const Kind: integer): integer;
    function __constructor(const ClassInfo: TLuaClassInfo; const __create: boolean): integer;
    function __destructor(const ClassInfo: TLuaClassInfo; const __free: boolean): integer;
    function __call(const ClassInfo: TLuaClassInfo): integer;
    function __global_index(const native: boolean; const info: TLuaGlobalModifyInfo): integer;
    function __global_newindex(const native: boolean; const info: TLuaGlobalModifyInfo): integer;
    function __array_index(const ClassInfo: TLuaClassInfo; const is_property: boolean): integer;
    function __array_newindex(const ClassInfo: TLuaClassInfo; const is_property: boolean): integer;
    function __array_dynamic_resize(): integer;
    function __array_include(const mode: integer{constructor, include, concat}): integer;
    function __set_method(const is_construct: boolean; const method: integer{0..2}): integer;
    function  ProcCallback(const ClassInfo: TLuaClassInfo; const ProcInfo: TLuaProcInfo): integer;  *)
  private
   // FArgs: TLuaArgs;
   // FArgsCount: integer;
                (*
    function  GetRecordInfo(const Name: string): PLuaRecordInfo;
    function  GetArrayInfo(const Name: string): PLuaArrayInfo;
    function  GetSetInfo(const Name: string): PLuaSetInfo;
    function  GetVariable(const Name: string): Variant;
    procedure SetVariable(const Name: string; const Value: Variant);
    function  GetVariableEx(const Name: string): TLuaArg;
    procedure SetVariableEx(const Name: string; const Value: TLuaArg);      *)
  public
    constructor Create;(*
    destructor Destroy; override;
    procedure GarbageCollection();
    procedure SaveNameSpace(const FileName: string); dynamic;
    function CreateReference(const global_name: string=''): TLuaReference;
    class function GetProcAddress(const ProcName: pchar; const throw_exception: boolean = false): pointer; // ������ �������. ����� ������� lua.dll
                         *) (*
    // �������� � ������ ��������
    procedure RunScript(const Script: string);
    procedure LoadScript(const FileName: string); overload;
    procedure LoadScript(const ScriptBuffer: pointer; const ScriptBufferSize: integer; const UnitName: string=''); overload;
 *)  (*
    // �������� ��� �������
    procedure ScriptAssert(const FmtStr: string; const Args: array of const); // ������� Exception �� Lua
    function  CheckArgsCount(const ArgsCount: array of integer; const ProcName: string=''; const AClass: TClass=nil): integer; overload;
    function  CheckArgsCount(const ArgsCount: TIntegerDynArray; const ProcName: string=''; const AClass: TClass=nil): integer; overload;
    procedure CheckArgsCount(const ArgsCount: integer; const ProcName: string=''; const AClass: TClass=nil); overload;
      *)  (*
    // ������
    function VariableExists(const Name: string): boolean;
    function ProcExists(const ProcName: string): boolean;
    function Call(const ProcName: string; const Args: TLuaArgs): TLuaArg; overload;
    function Call(const ProcName: string; const Args: array of const): TLuaArg;  overload;
        *)  (*
    // �����������
    procedure RegClass(const AClass: TClass; const use_published: boolean = true);
    procedure RegClasses(const AClasses: array of TClass; const use_published: boolean = true);
    function  RegRecord(const Name: string; const tpinfo: ptypeinfo): PLuaRecordInfo;
    function  RegArray(const Identifier: pointer; const itemtypeinfo: pointer; const Bounds: array of integer): PLuaArrayInfo;
    function  RegSet(const tpinfo: ptypeinfo): PLuaSetInfo;
    procedure RegProc(const ProcName: string; const Proc: TLuaProc; const ArgsCount: integer=-1); overload;
    procedure RegProc(const AClass: TClass; const ProcName: string; const Proc: TLuaClassProc; const ArgsCount: integer=-1; const with_class: boolean=false); overload;
    procedure RegProperty(const AClass: TClass; const PropertyName: string; const tpinfo: pointer; const PGet, PSet: pointer; const parameters: PLuaRecordInfo=nil; const default: boolean=false);
    procedure RegVariable(const VariableName: string; const X; const tpinfo: pointer; const IsConst: boolean = false);
    procedure RegConst(const ConstName: string; const Value: Variant); overload;
    procedure RegConst(const ConstName: string; const Value: TLuaArg); overload;
    procedure RegEnum(const EnumTypeInfo: ptypeinfo); 
                  *) (*
    // ��������������� ��������
    property ResultBuffer: TLuaResultBuffer read FResultBuffer;
    property Variable[const Name: string]: Variant read GetVariable write SetVariable;
    property VariableEx[const Name: string]: TLuaArg read GetVariableEx write SetVariableEx;
    property RecordInfo[const Name: string]: PLuaRecordInfo read GetRecordInfo;
    property ArrayInfo[const Name: string]: PLuaArrayInfo read GetArrayInfo;
    property SetInfo[const Name: string]: PLuaSetInfo read GetSetInfo;
   *)  (*
    // �������� ��������
    property Handle: pointer read FHandle;
    property Args: TLuaArgs read FArgs;
    property ArgsCount: integer read FArgsCount;

    // ����������� ������
    property UnitsCount: integer read FUnitsCount;
    property Units[const index: integer]: TLuaUnit read GetUnit;
    property UnitByName[const Name: string]: TLuaUnit read GetUnitByName;   *)
  end;

const
  // ����� �� �������� ��� ������� ������������ � assign()
  LUA_CONSTRUCTOR = 'constructor';
  LUA_ASSIGN = 'assign';

  // ��������� typeinfo
  typeinfoTClass  = ptypeinfo($7FFF0000);
  typeinfoPointer = ptypeinfo($7EEE0000);
  typeinfoUniversal = ptypeinfo($7DDD0000);


  // ��������� ������� �������
  INDEXED_PROPERTY = PLuaRecordInfo($7EEEEEEE);
  NAMED_PROPERTY   = PLuaRecordInfo($7AAAAAAA);

  // ������ ���� ����������
  ALL_OPERATORS: TLuaOperators = [low(TLuaOperator)..high(TLuaOperator)];


// helper functions
function CreateLua: TLua;
(*function LuaArgs(const Count: integer): TLuaArgs;
function LuaArg(const Value: boolean): TLuaArg; overload;
function LuaArg(const Value: integer): TLuaArg; overload;
function LuaArg(const Value: double): TLuaArg; overload;
function LuaArg(const Value: string): TLuaArg; overload;
function LuaArg(const Value: pointer): TLuaArg; overload;
function LuaArg(const Value: TClass): TLuaArg; overload;
function LuaArg(const Value: TObject): TLuaArg; overload;
function LuaArg(const Value: TLuaRecord): TLuaArg; overload;
function LuaArg(const Value: TLuaArray): TLuaArg; overload;
function LuaArg(const Value: TLuaSet): TLuaArg; overload;
function LuaArg(const Value: Variant): TLuaArg; overload;
function LuaRecord(const Data: pointer; const Info: PLuaRecordInfo; const IsRef: boolean=true; const IsConst: boolean=false): TLuaRecord;
function LuaArray(const Data: pointer; const Info: PLuaArrayInfo; const IsRef: boolean=true; const IsConst: boolean=false): TLuaArray;
function LuaSet(const Data: pointer; const Info: PLuaSetInfo; const IsRef: boolean=true; const IsConst: boolean=false): TLuaSet;

function LuaProc(const Proc: TLuaProc0): TLuaProc; overload;
function LuaProc(const Proc: TLuaProc1): TLuaProc; overload;
function LuaProc(const Proc: TLuaProc2): TLuaProc; overload;
function LuaProc(const Proc: TLuaProc3): TLuaProc; overload;
function LuaProc(const Proc: TLuaProc4): TLuaProc; overload;
function LuaProc(const Proc: TLuaProc5): TLuaProc; overload;
function LuaProc(const Proc: TLuaProc6): TLuaProc; overload;
function LuaClassProc(const Proc: TLuaClassProc0): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc1): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc2): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc3): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc4): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc5): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc6): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc7): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc8): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc9): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc10): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc11): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc12): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc13): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc14): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc15): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc16): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc17): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc18): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc19): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc20): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc21): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc22): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc23): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc24): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc25): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc26): TLuaClassProc; overload;
function LuaClassProc(const Proc: TLuaClassProc27): TLuaClassProc; overload;
function LuaClassProcPtr(const Proc: pointer): TLuaClassProc;
       *)


var
  { user defined library path, used at the first TLua class constructor }
  LuaLibraryPath: string =
    {$if Defined(CPUX86)}
      'lua.dll'
    {$elseif Defined(CPUX64)}
      'lua64.dll'
    {$else}
      {$MESSAGE ERROR 'Planform not yet supported'}
    {$ifend}
  ;

{$ifdef LUA_INITIALIZE}
var
  Lua: TLua;
{$endif}

implementation


{ ELua }

{$ifdef KOL}
constructor ELua.Create(const Msg: string);
begin
  inherited Create(e_Custom, Msg);
end;

constructor ELua.CreateFmt(const Msg: string;
  const Args: array of const);
begin
  inherited CreateFmt(e_Custom, Msg, Args);
end;

type
  PStrData = ^TStrData;
  TStrData = record
    Ident: Integer;
    Str: string;
  end;

function EnumStringModules(Instance: Longint; Data: Pointer): Boolean;
var
  Buffer: array [0..1023] of Char;
begin
  with PStrData(Data)^ do
  begin
    SetString(Str, Buffer, Windows.LoadString(Instance, Ident, Buffer, sizeof(Buffer)));
    Result := Str = '';
  end;
end;

function FindStringResource(Ident: Integer): string;
var
  StrData: TStrData;
begin
  StrData.Ident := Ident;
  StrData.Str := '';
  EnumResourceModules(EnumStringModules, @StrData);
  Result := StrData.Str;
end;

function LoadStr(Ident: Integer): string;
begin
  Result := FindStringResource(Ident);
end;

constructor ELua.CreateRes(Ident: NativeUInt);
begin
  inherited Create(e_Custom, LoadStr(Ident));
end;

constructor ELua.CreateRes(ResStringRec: PResStringRec);
begin
  inherited Create(e_Custom, System.LoadResString(ResStringRec));
end;

constructor ELua.CreateResFmt(Ident: NativeUInt;
  const Args: array of const);
begin
  inherited CreateFmt(e_Custom, LoadStr(Ident), Args);
end;

constructor ELua.CreateResFmt(ResStringRec: PResStringRec;
  const Args: array of const);
begin
  inherited CreateFmt(e_Custom, System.LoadResString(ResStringRec), Args);
end;
{$endif}


{ Lua API routine }

var
  LuaHandle: THandle;
  LuaPath: string;
  LuaInitialized: Boolean;

type
  Plua_State = Pointer;
  lua_CFunction = function(L: Plua_State): Integer; cdecl;
  lua_Number = Double;
  lua_Integer = NativeInt;
  size_t = NativeUInt;
  Psize_t = ^size_t;

  lua_Debug = record
    event: Integer;
    name: __luaname;                 { (n) }
    namewhat: __luaname;             { (n) `global', `local', `field', `method' }
    what: __luaname;                 { (S) `Lua', `C', `main', `tail'}
    source: __luaname;               { (S) }
    currentline: Integer;            { (l) }
    nups: Integer;                   { (u) number of upvalues }
    linedefined: Integer;            { (S) }
    short_src: array[0..59] of Byte; { (S) }
    i_ci: Integer;
    gap: array[0..7] of Byte;        { lua_getstack bug fix }
  end;
  Plua_Debug = ^lua_Debug;

var
  LUA_VERSION_52: Boolean = False;
  LUA_REGISTRYINDEX: integer = -10000;

const
  LUA_MULTRET = -1;

  LUA_TNONE          = -1;
  LUA_TNIL           = 0;
  LUA_TBOOLEAN       = 1;
  LUA_TLIGHTUSERDATA = 2;
  LUA_TNUMBER        = 3;
  LUA_TSTRING        = 4;
  LUA_TTABLE         = 5;
  LUA_TFUNCTION      = 6;
  LUA_TUSERDATA      = 7;

var
  lua_open: function: Plua_State; cdecl;
  luaL_openlibs: procedure(L: Plua_State); cdecl;
  lua_close: procedure(L: Plua_State); cdecl;
  lua_gc: function(L: Plua_State; what: Integer; data: Integer): Integer; cdecl;
  luaL_loadbuffer: function(L: Plua_State; const buff: __luadata; size: size_t; const name: __luaname): Integer; cdecl;
  luaL_loadbufferx: function(L: Plua_State; const buff: __luadata; size: size_t; const name, mode: __luaname): Integer; cdecl;
  lua_pcall: function(L: Plua_State; nargs, nresults, errf: Integer): Integer; cdecl;
  lua_pcallk: function(L: Plua_State; nargs, nresults, errf, ctx: Integer; k: lua_CFunction): Integer; cdecl;
  lua_error: function(L: Plua_State): Integer; cdecl;
  lua_next: function(L: Plua_State; idx: Integer): Integer; cdecl;
  lua_getstack: function(L: Plua_State; level: Integer; ar: Plua_Debug): Integer; cdecl;
  lua_getinfo: function(L: Plua_State; const what: __luaname; ar: Plua_Debug): Integer; cdecl;

  lua_type: function(L: Plua_State; idx: Integer): Integer; cdecl;
  lua_gettop: function(L: Plua_State): Integer; cdecl;
  lua_settop: procedure(L: Plua_State; idx: Integer); cdecl;
  lua_remove: procedure(L: Plua_State; idx: Integer); cdecl;
  lua_insert: procedure(L: Plua_State; idx: Integer); cdecl;

  lua_pushnil: procedure(L: Plua_State); cdecl;
  lua_pushboolean: procedure(L: Plua_State; b: LongBool); cdecl;
  lua_pushinteger: procedure(L: Plua_State; n: lua_Integer); cdecl;
  lua_pushnumber: procedure(L: Plua_State; n: lua_Number); cdecl;
  lua_pushlstring: procedure(L: Plua_State; const s: __luadata; l_: size_t); cdecl;
  lua_pushcclosure: procedure(L: Plua_State; fn: lua_CFunction; n: Integer); cdecl;
  lua_pushlightuserdata: procedure(L: Plua_State; p: Pointer); cdecl;
  lua_newuserdata: function(L: Plua_State; sz: size_t): Pointer; cdecl;
  lua_pushvalue: procedure(L: Plua_State; Idx: Integer); cdecl;
  lua_toboolean: function(L: Plua_State; idx: Integer): LongBool; cdecl;
  lua_tonumber: function(L: Plua_State; idx: Integer): lua_Number; cdecl;
  lua_tonumberx: function(L: Plua_State; idx: Integer; isnum: PInteger): lua_Number; cdecl;
  lua_tolstring: function(L: Plua_State; idx: Integer; len: Psize_t): __luadata; cdecl;
  lua_tocfunction: function(L: Plua_State; idx: Integer): lua_CFunction; cdecl;
  lua_touserdata: function(L: Plua_State; idx: Integer): Pointer; cdecl;
  lua_objlen: function(L: Plua_State; idx: Integer): size_t; cdecl;

  lua_rawgeti: procedure(L: Plua_State; idx, n: Integer); cdecl;
  lua_rawseti: procedure(L: Plua_State; idx, n: Integer); cdecl;
  lua_rawget: procedure(L: Plua_State; idx: Integer); cdecl;
  lua_rawset: procedure(L: Plua_State; idx: Integer); cdecl;
  lua_createtable: procedure(L: Plua_State; narr: Integer; nrec: Integer); cdecl; { old newtable }
  lua_setmetatable: function(L: Plua_State; objindex: Integer): Integer; cdecl;

// for 5.2+ versions
function luaL_loadbuffer_52(L: Plua_State; const buff: __luadata; size: size_t; const name: __luaname): Integer; cdecl;
begin
  Result := luaL_loadbufferx(L, buff, size, name, nil);
end;

function lua_pcall_52(L: Plua_State; nargs, nresults, errf: Integer): Integer; cdecl;
begin
  Result := lua_pcallk(L, nargs, nresults, errf, 0, nil);
end;

function lua_tonumber_52(L: Plua_State; idx: Integer): lua_Number; cdecl;
begin
  Result := lua_tonumberx(L, idx, nil);
end;

function LoadLuaLibrary: THandle;
var
  S: string;
  Buffer: array[0..1024] of Char;
  BufferPtr: PChar;
begin
  if (LuaPath = '') then
  begin
    if (FileExists(LuaLibraryPath)) then
    begin
      LuaPath := ExpandFileName(LuaLibraryPath);
    end else
    begin
      BufferPtr := @Buffer[0];
      SetString(S, BufferPtr, GetModuleFileName(hInstance, BufferPtr, High(Buffer)));
      LuaPath := ExtractFilePath(S) + ExtractFileName(LuaLibraryPath);
    end;

    LuaHandle := LoadLibrary(PChar(LuaPath));
  end;

  Result := LuaHandle;
end;

procedure FreeLuaLibrary;
begin
  if (LuaHandle <> 0) then
  begin
    FreeLibrary(LuaHandle);
    LuaHandle := 0;
  end;
end;

// initialize Lua library, load and emulate API
function InitializeLua: Boolean;
var
  Buffer: Pointer;

  function FailLoad(var Proc; const ProcName: PChar): Boolean;
  begin
    Pointer(Proc) := GetProcAddress(LuaHandle, ProcName);
    Result := (Pointer(Proc) = nil);
  end;

begin
  Result := False;
  if (not LuaInitialized) then
  begin
    if (LoadLuaLibrary = 0) then Exit;

    LUA_VERSION_52 := not FailLoad(Buffer, 'lua_tounsignedx');
    if (LUA_VERSION_52) then LUA_REGISTRYINDEX := (-1000000 - 1000);

    if FailLoad(@lua_open, 'luaL_newstate') then Exit;
    if FailLoad(@luaL_openlibs, 'luaL_openlibs') then Exit;
    if FailLoad(@lua_close, 'lua_close') then Exit;
    if FailLoad(@lua_gc, 'lua_gc') then Exit;
    if (LUA_VERSION_52) then
    begin
      if FailLoad(@luaL_loadbufferx, 'luaL_loadbufferx') then Exit;
      luaL_loadbuffer := luaL_loadbuffer_52;
    end else
    begin
      if FailLoad(@luaL_loadbuffer, 'luaL_loadbuffer') then Exit;
    end;
    if (LUA_VERSION_52) then
    begin
      if FailLoad(@lua_pcallk, 'lua_pcallk') then Exit;
      lua_pcall := lua_pcall_52;
    end else
    begin
      if FailLoad(@lua_pcall, 'lua_pcall') then Exit;
    end;
    if FailLoad(@lua_error, 'lua_error') then Exit;
    if FailLoad(@lua_next, 'lua_next') then Exit;
    if FailLoad(@lua_getstack, 'lua_getstack') then Exit;
    if FailLoad(@lua_getinfo, 'lua_getinfo') then Exit;

    if FailLoad(@lua_type, 'lua_type') then Exit;
    if FailLoad(@lua_gettop, 'lua_gettop') then Exit;
    if FailLoad(@lua_settop, 'lua_settop') then Exit;
    if FailLoad(@lua_remove, 'lua_remove') then Exit;
    if FailLoad(@lua_insert, 'lua_insert') then Exit;

    if FailLoad(@lua_pushnil, 'lua_pushnil') then Exit;
    if FailLoad(@lua_pushboolean, 'lua_pushboolean') then Exit;
    if FailLoad(@lua_pushinteger, 'lua_pushinteger') then Exit;
    if FailLoad(@lua_pushnumber, 'lua_pushnumber') then Exit;
    if FailLoad(@lua_pushlstring, 'lua_pushlstring') then Exit;
    if FailLoad(@lua_pushcclosure, 'lua_pushcclosure') then Exit;
    if FailLoad(@lua_pushlightuserdata, 'lua_pushlightuserdata') then Exit;
    if FailLoad(@lua_newuserdata, 'lua_newuserdata') then Exit;
    if FailLoad(@lua_pushvalue, 'lua_pushvalue') then Exit;
    if FailLoad(@lua_toboolean, 'lua_toboolean') then Exit;
    if (LUA_VERSION_52) then
    begin
      if FailLoad(@lua_tonumberx, 'lua_tonumberx') then Exit;
      lua_tonumber := lua_tonumber_52;
    end else
    begin
      if FailLoad(@lua_tonumber, 'lua_tonumber') then Exit;
    end;
    if FailLoad(@lua_tolstring, 'lua_tolstring') then Exit;
    if FailLoad(@lua_tocfunction, 'lua_tocfunction') then Exit;
    if FailLoad(@lua_touserdata, 'lua_touserdata') then Exit;
    if (LUA_VERSION_52) then
    begin
      if FailLoad(@lua_objlen, 'lua_rawlen') then Exit;
    end else
    begin
      if FailLoad(@lua_objlen, 'lua_objlen') then Exit;
    end;

    if FailLoad(@lua_rawgeti, 'lua_rawgeti') then Exit;
    if FailLoad(@lua_rawseti, 'lua_rawseti') then Exit;
    if FailLoad(@lua_rawget, 'lua_rawget') then Exit;
    if FailLoad(@lua_rawset, 'lua_rawset') then Exit;
    if FailLoad(@lua_createtable, 'lua_createtable') then Exit;
    if FailLoad(@lua_setmetatable, 'lua_setmetatable') then Exit;

    LuaInitialized := True;
  end;

  Result := True;
end;

// safe TLua constuctor
function CreateLua: TLua;
begin
  if (not InitializeLua) then
  begin
    Result := nil;
  end else
  begin
    Result := TLua.Create;
  end;
end;


{ Lookup routine }

const
  BIT_SCANS: array[Byte] of Byte = ({failure}8, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0,
    2, 0, 1, 0, 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 5, 0, 1, 0, 2,
    0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0,
    1, 0, 6, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 4, 0, 1, 0, 2, 0, 1,
    0, 3, 0, 1, 0, 2, 0, 1, 0, 5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
    4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 7, 0, 1, 0, 2, 0, 1, 0, 3,
    0, 1, 0, 2, 0, 1, 0, 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 5, 0,
    1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1,
    0, 2, 0, 1, 0, 6, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 4, 0, 1, 0,
    2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0, 5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2,
    0, 1, 0, 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
  );

var
  CODEPAGE_DEFAULT: Word;
  UTF8CHAR_SIZE: array[Byte] of Byte;

procedure InitUnicodeLookups;
type
  TNativeUIntArray = array[0..256 div SizeOf(NativeUInt) - 1] of NativeUInt;
var
  i, X: NativeUInt;
  NativeArr: ^TNativeUIntArray;
begin
  CODEPAGE_DEFAULT := GetACP;
  NativeArr := Pointer(@UTF8CHAR_SIZE);

  // 0..127
  X := {$ifdef LARGEINT}$0101010101010101{$else}$01010101{$endif};
  for i := 0 to 128 div SizeOf(NativeUInt) - 1 do
  NativeArr[i] := X;

  // 128..191 (64) fail (0)
  Inc(NativeUInt(NativeArr), 128);
  X := 0;
  for i := 0 to 64 div SizeOf(NativeUInt) - 1 do
  NativeArr[i] := X;

  // 192..223 (32)
  Inc(NativeUInt(NativeArr), 64);
  X := {$ifdef LARGEINT}$0202020202020202{$else}$02020202{$endif};
  for i := 0 to 32 div SizeOf(NativeUInt) - 1 do
  NativeArr[i] := X;

  // 224..239 (16)
  Inc(NativeUInt(NativeArr), 32);
  X := {$ifdef LARGEINT}$0303030303030303{$else}$03030303{$endif};
  {$ifdef LARGEINT}
    NativeArr[0] := X;
    NativeArr[1] := X;
  {$else}
    NativeArr[0] := X;
    NativeArr[1] := X;
    NativeArr[2] := X;
    NativeArr[3] := X;
  {$endif}

  // 240..247 (8)
  Inc(NativeUInt(NativeArr), 16);
  {$ifdef LARGEINT}
    NativeArr[0] := $0404040404040404;
  {$else}
    NativeArr[0] := $04040404;
    NativeArr[1] := $04040404;
  {$endif}

  // 248..251 (4) --> 5
  // 252..253 (2) --> 6
  // 254..255 (2) --> fail (0)
  {$ifdef LARGEINT}
    NativeArr[1] := $0000060605050505;
  {$else}
    NativeArr[2] := $05050505;
    NativeArr[3] := $00000606;
  {$endif}
end;


{ RTTI routine }

type
  PFieldInfo = ^TFieldInfo;
  TFieldInfo = packed record
    TypeInfo: PPTypeInfo;
    Offset: Cardinal;
    {$ifdef LARGEINT}
    _Padding: Integer;
    {$endif}
  end;

  PFieldTable = ^TFieldTable;
  TFieldTable = packed record
    X: Word;
    Size: Cardinal;
    Count: Cardinal;
    Fields: array [0..0] of TFieldInfo;
  end;

  PDynArrayRec = ^TDynArrayRec;
  TDynArrayRec = packed record
    {$ifdef LARGEINT}
    _Padding: Integer;
    {$endif}
    RefCnt: Integer;
    Length: NativeInt;
  end;

function IsManagedTypeInfo(Value: PTypeInfo): Boolean;
var
  i: Cardinal;
  {$ifdef WEAKREF}
  WeakMode: Boolean;
  {$endif}
  FieldTable: PFieldTable;
begin
  Result := False;

  if Assigned(Value) then
  case Value.Kind of
    tkVariant,
    {$ifdef AUTOREFCOUNT}
    tkClass,
    {$endif}
    {$ifdef WEAKINSTREF}
    tkMethod,
    {$endif}
    {$ifdef FPC}
    tkAString,
    {$endif}
    tkWString, tkLString, {$ifdef UNICODE}tkUString,{$endif} tkInterface, tkDynArray:
    begin
      Result := True;
      Exit;
    end;
    tkArray{static array}:
    begin
      FieldTable := PFieldTable(NativeUInt(Value) + PByte(@Value.Name)^);
      if (FieldTable.Fields[0].TypeInfo <> nil) then
        Result := IsManagedTypeInfo(FieldTable.Fields[0].TypeInfo^);
    end;
    tkRecord:
    begin
      FieldTable := PFieldTable(NativeUInt(Value) + PByte(@Value.Name)^);
      if FieldTable.Count > 0 then
      begin
        {$ifdef WEAKREF}
        WeakMode := False;
        {$endif}
        for i := 0 to FieldTable.Count - 1 do
        begin
         {$ifdef WEAKREF}
          if FieldTable.Fields[i].TypeInfo = nil then
          begin
            WeakMode := True;
            Continue;
          end;
          if (not WeakMode) then
          begin
          {$endif}
            if (IsManagedTypeInfo(FieldTable.Fields[i].TypeInfo^)) then
            begin
              Result := True;
              Exit;
            end;
          {$ifdef WEAKREF}
          end else
          begin
            Result := True;
            Exit;
          end;
          {$endif}
        end;
      end;
    end;
  end;
end;


{$if Defined(FPC)}
function fpc_Copy_internal(Src, Dest, TypeInfo: Pointer): SizeInt; [external name 'FPC_COPY'];
procedure CopyRecord(const Dest, Source, TypeInfo: Pointer); inline;
begin
  fpc_Copy_internal(Source, Dest, TypeInfo);
end;
{$elseif Defined(CPUINTEL)}
procedure CopyRecord(const Dest, Source, TypeInfo: Pointer);
asm
  jmp System.@CopyRecord
end;
{$else}
procedure CopyRecord(const Dest, Source, TypeInfo: Pointer); inline;
begin
  System.CopyArray(Dest, Source, TypeInfo, 1);
end;
{$ifend}

procedure CopyObject(const Dest, Src: TObject);
var
  InitTable: Pointer;
  BaseSize, DestSize: NativeInt;
  BaseClass, DestClass, SrcClass: TClass;
begin
  if (Dest = nil) or (Src = nil) then Exit;

  DestClass := TClass(Pointer(Dest)^);
  SrcClass := TClass(Pointer(Src)^);

  if (DestClass = SrcClass) then BaseClass := DestClass
  else
  if (DestClass.InheritsFrom(SrcClass)) then BaseClass := SrcClass
  else
  if (SrcClass.InheritsFrom(DestClass)) then BaseClass := DestClass
  else
  begin
    BaseClass := DestClass;

    while (BaseClass <> nil) and (not SrcClass.InheritsFrom(BaseClass)) do
    begin
      BaseClass := BaseClass.ClassParent;
    end;

    if (BaseClass = nil) then Exit;
  end;

  DestSize := BaseClass.InstanceSize;
  while (BaseClass <> TObject) do
  begin
    InitTable := PPointer(Integer(BaseClass) + vmtInitTable)^;
    if (InitTable <> nil) then
    begin
      CopyRecord(Pointer(Dest), Pointer(Src), InitTable);
      Break;
    end;
    BaseClass := BaseClass.ClassParent;
  end;

  BaseSize := BaseClass.InstanceSize;
  if (BaseSize <> DestSize) then
  begin
    System.Move(Pointer(NativeInt(Src) + BaseSize)^,
      Pointer(NativeInt(Dest) + BaseSize)^, DestSize - BaseSize);
  end;
end;

{$if Defined(FPC)}
procedure CopyArray(const Dest, Source: Pointer; const TypeInfo: PTypeInfo; const Count: NativeInt);
var
  ItemDest, ItemSrc: Pointer;
  ItemSize, i: NativeInt;
begin
  ItemDest := Dest;
  ItemSrc := Source;

  case TypeInfo.Kind of
    tkVariant: ItemSize := SizeOf(Variant);
    tkLString, tkWString, tkInterface, tkDynArray, tkAString: ItemSize := SizeOf(Pointer);
      tkArray, tkRecord, tkObject: ItemSize := PFieldTable(NativeUInt(TypeInfo) + PByte(@TypeInfo.Name)^).Size;
  else
    Exit;
  end;

  for i := 1 to Count do
  begin
    fpc_Copy_internal(ItemSrc, ItemDest, TypeInfo);

    Inc(NativeInt(ItemDest), ItemSize);
    Inc(NativeInt(ItemSrc), ItemSize);
  end;
end;
{$elseif (CompilerVersion <= 20)}
procedure CopyArray(const Dest, Source: Pointer; const TypeInfo: PTypeInfo; const Count: NativeInt);
asm
  cmp byte ptr [ecx], tkArray
  jne @1
  push eax
  push edx
    movzx edx, [ecx + TTypeInfo.Name]
    mov eax, [ecx + edx + 6]
    mov ecx, [ecx + edx + 10]
    mul Count
    mov ecx, [ecx]
    mov Count, eax
  pop edx
  pop eax
  @1:

  pop ebp
  jmp System.@CopyArray
end;
{$ifend}

{$if Defined(FPC)}
procedure int_Initialize(Data, TypeInfo: Pointer); [external name 'FPC_INITIALIZE'];
procedure InitializeArray(const Item: Pointer; const TypeInfo: PTypeInfo; const Count: NativeInt);
var
  ItemPtr: Pointer;
  ItemSize, i: NativeInt;
begin
  ItemPtr := Item;

  case TypeInfo.Kind of
    tkVariant: ItemSize := SizeOf(Variant);
    tkLString, tkWString, tkInterface, tkDynArray, tkAString: ItemSize := SizeOf(Pointer);
      tkArray, tkRecord, tkObject: ItemSize := PFieldTable(NativeUInt(TypeInfo) + PByte(@TypeInfo.Name)^).Size;
  else
    Exit;
  end;

  for i := 1 to Count do
  begin
    int_Initialize(ItemPtr, TypeInfo);
    Inc(NativeInt(ItemPtr), ItemSize);
  end;
end;
{$elseif (CompilerVersion <= 20)}
procedure InitializeArray(const Item: Pointer; const TypeInfo: PTypeInfo; const Count: NativeInt);
asm
  jmp System.@InitializeArray
end;
{$ifend}

{$if Defined(FPC)}
procedure int_Finalize(Data, TypeInfo: Pointer); [external name 'FPC_FINALIZE'];
procedure FinalizeArray(const Item: Pointer; const TypeInfo: PTypeInfo; const Count: NativeInt);
var
  ItemPtr: Pointer;
  ItemSize, i: NativeInt;
begin
  ItemPtr := Item;

  case TypeInfo.Kind of
    tkVariant: ItemSize := SizeOf(Variant);
    tkLString, tkWString, tkInterface, tkDynArray, tkAString: ItemSize := SizeOf(Pointer);
      tkArray, tkRecord, tkObject: ItemSize := PFieldTable(NativeUInt(TypeInfo) + PByte(@TypeInfo.Name)^).Size;
  else
    Exit;
  end;

  for i := 1 to Count do
  begin
    int_Finalize(ItemPtr, TypeInfo);
    Inc(NativeInt(ItemPtr), ItemSize);
  end;
end;
{$elseif (CompilerVersion <= 20)}
procedure FinalizeArray(const Item: Pointer; const TypeInfo: PTypeInfo; const Count: NativeInt);
asm
  jmp System.@FinalizeArray
end;
{$ifend}

function DynArrayLength(P: Pointer): NativeInt;
begin
  Result := NativeInt(P);
  if (Result <> 0) then
  begin
    Dec(Result, SizeOf(NativeInt));
    Result := PNativeInt(Result)^;
    {$ifdef FPC}
      Inc(Result);
    {$endif}
  end;
end;

{$if Defined(FPC)}
procedure fpc_dynarray_incr_ref(P: Pointer); [external name 'FPC_DYNARRAY_INCR_REF'];
procedure DynArrayAddRef(P: Pointer); inline;
begin
  fpc_dynarray_incr_ref(P);
end;
{$elseif Defined(CPUINTEL)}
procedure DynArrayAddRef(P: Pointer);
asm
  jmp System.@DynArrayAddRef
end;
{$else}
procedure DynArrayAddRef(P: Pointer);
var
  Rec: PDynArrayRec;
begin
  if (P <> nil) then
  begin
    Rec := P;
    Dec(Rec);
    if (Rec.RefCnt >= 0) then
    begin
      AtomicIncrement(Rec.RefCnt);
    end;
  end;
end;
{$ifend}

{$ifdef FPC}
procedure fpc_dynarray_clear (var P: Pointer; TypeInfo: Pointer); external name 'FPC_DYNARRAY_CLEAR';
procedure DynArrayClear(var P: Pointer; TypeInfo: Pointer); inline;
begin
  fpc_dynarray_clear(P, TypeInfo);
end;
{$endif}

var
  TypInfoGetStrProp: function(Instance: TObject; PropInfo: PPropInfo): string;
  TypInfoSetStrProp: procedure(Instance: TObject; PropInfo: PPropInfo; const Value: string);
  TypInfoGetVariantProp: function(Instance: TObject; PropInfo: PPropInfo): Variant;
  TypInfoSetVariantProp: procedure(Instance: TObject; PropInfo: PPropInfo; const Value: Variant);
  TypInfoGetInterfaceProp: function(Instance: TObject; PropInfo: PPropInfo): IInterface;
  TypInfoSetInterfaceProp: procedure(Instance: TObject; PropInfo: PPropInfo; const Value: IInterface);

procedure InitTypInfoProcs;
begin
  TypInfoGetStrProp := {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.GetStrProp;
  TypInfoSetStrProp := {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.SetStrProp;
  TypInfoGetVariantProp := {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.GetVariantProp;
  TypInfoSetVariantProp := {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.SetVariantProp;
  TypInfoGetInterfaceProp := {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.GetInterfaceProp;
  TypInfoSetInterfaceProp := {$ifdef UNITSCOPENAMES}System.{$endif}TypInfo.SetInterfaceProp;
end;


{ LuaCFunction routine }

const
  MEMORY_PAGE_SIZE = 4 * 1024;
  MEMORY_PAGE_CLEAR = -MEMORY_PAGE_SIZE;
  MEMORY_PAGE_TEST = MEMORY_PAGE_SIZE - 1;
  MEMORY_BLOCK_SIZE = 64 * 1024;
  MEMORY_BLOCK_CLEAR = -MEMORY_BLOCK_SIZE;
  MEMORY_BLOCK_TEST = MEMORY_BLOCK_SIZE - 1;
  MEMORY_BLOCK_MARKER_LOW = Ord('C') + Ord('r') shl 8 + Ord('y') shl 16 + Ord('s') shl 24;
  MEMORY_BLOCK_MARKER_HIGH = Ord('C') + Ord('L') shl 8 + Ord('u') shl 16 + Ord('a') shl 24;

type
  PLuaCFunctionData = ^TLuaCFunctionData;
  TLuaCFunctionData = object
    {$if Defined(CPUX86)}
      Bytes: array[0..19] of Byte;
    {$elseif Defined(CPUX64)}
      Bytes: array[0..33] of Byte;
    {$else}
      Bytes: array[0..0] of Byte;
    {$ifend}

    procedure Init(const Lua: TLua; const P1, P2: __luapointer; const Callback: Pointer);
  end;

  PLuaCFunctionPage = ^TLuaCFunctionPage;
  TLuaCFunctionPage = object
    Items: PLuaCFunctionData;
    Allocated: Cardinal;

    procedure Init;
    function Alloc: Pointer;
    function Free(const P: Pointer): Boolean;
  end;

  PLuaCFunctionBlock = ^TLuaCFunctionBlock;
  TLuaCFunctionBlock = object(TLuaCFunctionPage)
    // er
    // 00 - decommited page
    // 01 - full page
    // 10 - impossible case
    // 11 - contains empties
    Reserved: Word;
    Empties: Word;
    // CrysCLua
    MarkerLow: Integer;
    MarkerHigh: Integer;
    // single linked list
    Next: PLuaCFunctionBlock;
  end;

  TLuaCFunctionHeap = object
  public
    {$WARNINGS OFF}
    FakeField: NativeUInt;
    {$WARNINGS ON}
    Blocks: PLuaCFunctionBlock;

    function Alloc(const Lua: TLua; const P1, P2: __luapointer; const Callback: Pointer): Pointer;
    procedure Free(const LuaCFunction: Pointer);
    procedure Clear;
  end;

function BitScan16(const Value: Integer{Word}): NativeInt;
begin
  if (Value <> 0) then
  begin
    if (Value and $ff <> 0) then
    begin
      Result := BIT_SCANS[Byte(Value)];
    end else
    begin
      Result := 8 + BIT_SCANS[Value shr 8];
    end;
  end else
  begin
    Result := -1;
  end;
end;

procedure TLuaCFunctionData.Init(const Lua: TLua; const P1, P2: __luapointer; const Callback: Pointer);
var
  Offset: NativeInt;
begin
  {$ifdef CPUX86}
    // mov eax, Lua
    Bytes[0] := $B8;
    PPointer(@Bytes[1])^ := Lua;
    // mov edx, P1
    Bytes[5] := $BA;
    PInteger(@Bytes[6])^ := P1;
    // mov ecx, P2
    Bytes[10] := $B9;
    PInteger(@Bytes[11])^ := P2;
    // jmp Callback
    Offset := NativeInt(Callback) - (NativeInt(@Bytes[15]) + 5);
    Bytes[15] := $E9;
    PInteger(@Bytes[16])^ := Offset;
  {$endif}

  {$ifdef CPUX64}
    // mov rcx, Lua
    Bytes[0] := $48;
    Bytes[1] := $B9;
    PPointer(@Bytes[2])^ := Lua;
    // mov edx, P1
    Bytes[10] := $BA;
    PInteger(@Bytes[11])^ := P1;
    // mov r8d, P2
    Bytes[15] := $41;
    Bytes[16] := $B8;
    PInteger(@Bytes[17])^ := P2;
    // jump
    Offset := NativeInt(Callback) - (NativeInt(@Bytes[21]) + 5);
    case Integer(Offset shr 32) of
      -1, 0:
      begin
        // jmp Callback
        Bytes[21] := $E9;
        PInteger(@Bytes[22])^ := Offset;
      end;
    else
      // mov rax, Callback
      Bytes[21] := $48;
      Bytes[22] := $B8;
      PPointer(@Bytes[23])^ := Callback;
      // jmp rax
      Bytes[31] := $48;
      Bytes[32] := $FF;
      Bytes[33] := $E0;
    end;
  {$endif}
end;

procedure TLuaCFunctionPage.Init;
type
  TList = array[0..MEMORY_PAGE_SIZE div SizeOf(TLuaCFunctionData) - 1] of TLuaCFunctionData;
var
  i, Count: NativeInt;
  List: ^TList;
begin
  List := Pointer(@Self);
  if (NativeInt(List) and MEMORY_BLOCK_TEST <> 0) then
  begin
    Inc(NativeInt(List), SizeOf(TLuaCFunctionPage));
    Count := (MEMORY_PAGE_SIZE - SizeOf(TLuaCFunctionPage)) div SizeOf(TLuaCFunctionData);
  end else
  begin
    Inc(NativeInt(List), SizeOf(TLuaCFunctionBlock));
    Count := (MEMORY_PAGE_SIZE - SizeOf(TLuaCFunctionBlock)) div SizeOf(TLuaCFunctionData);
  end;

  for i := 0 to Count - 2 do
  begin
    PPointer(@List[i])^ := @List[i + 1];
  end;
  PPointer(@List[Count - 1])^ := nil;

  Items := @List[0];
  Allocated := 0;
end;

function TLuaCFunctionPage.Alloc: Pointer;
begin
  Result := Items;
  if (Result <> nil) then
  begin
    Inc(Allocated);
    Items := PPointer(Result)^;
  end;
end;

function TLuaCFunctionPage.Free(const P: Pointer): Boolean;
var
  Count: Cardinal;
begin
  PPointer(P)^ := Items;
  Items := P;

  Count := Allocated - 1;
  Allocated := Count;
  Result := (Count = 0);
end;

procedure TLuaCFunctionHeap.Clear;
var
  Block, Next: PLuaCFunctionBlock;
begin
  Block := Blocks;
  Blocks := nil;

  while (Block <> nil) do
  begin
    Next := Block.Next;

    {$if Defined(MSWINDOWS)}
      VirtualFree(Block, 0, MEM_RELEASE);
    {$else}
    {$ifend}

    Block := Next;
  end;
end;

function TLuaCFunctionHeap.Alloc(const Lua: TLua; const P1, P2: __luapointer; const Callback: Pointer): Pointer;
var
  Index: NativeInt;
  Block: PLuaCFunctionBlock;
  Page: PLuaCFunctionPage;

  function CommitPage(const ABlock: PLuaCFunctionBlock; const AIndex: NativeInt): PLuaCFunctionPage; far;
  begin
    Result := Pointer(NativeInt(ABlock) + AIndex * MEMORY_PAGE_SIZE);

    {$if Defined(MSWINDOWS)}
      VirtualAlloc(Result, MEMORY_PAGE_SIZE, MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    {$else}
    {$ifend}

    ABlock.Empties := ABlock.Empties or (1 shl AIndex);
    ABlock.Reserved := ABlock.Reserved or (1 shl AIndex);

    Result.Init;
  end;

begin
  Result := nil;

  Block := Self.Blocks;
  while (Block <> nil) do
  begin
    Index := BitScan16(Block.Empties);
    if (Index >= 0) then
    begin
      Page := Pointer(NativeInt(Block) + Index * MEMORY_PAGE_SIZE);
      Result := Page.Alloc;
      if (Page.Items = nil) then
      begin
        Block.Empties := Block.Empties and (not (1 shl Index));
      end;
      Break;
    end else
    if (Block.Reserved <> $ffff) then
    begin
      Index := BitScan16(not Block.Reserved);
      Result := CommitPage(Block, Index).Alloc;
      Break;
    end;

    Block := Block.Next;
  end;

  if (Result = nil) then
  begin
    {$if Defined(MSWINDOWS)}
      Block := VirtualAlloc(nil, MEMORY_BLOCK_SIZE, MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    {$else}
    {$ifend}

    if (Block <> nil) then
    begin
      Result := CommitPage(Block, 0).Alloc;
      Block.MarkerLow := MEMORY_BLOCK_MARKER_LOW;
      Block.MarkerHigh := MEMORY_BLOCK_MARKER_HIGH;
      Block.Next := Self.Blocks;
      Self.Blocks := Block;
    end;
  end;

  if (Result = nil) then System.Error(reOutOfMemory);
  PLuaCFunctionData(Result).Init(Lua, P1, P2, Callback);
end;

procedure TLuaCFunctionHeap.Free(const LuaCFunction: Pointer);
var
  Index: NativeInt;
  Page: PLuaCFunctionPage;
  Block, Item: PLuaCFunctionBlock;
  Parent: ^PLuaCFunctionBlock;
begin
  Page := Pointer(NativeInt(LuaCFunction) and MEMORY_PAGE_CLEAR);
  Block := Pointer(NativeInt(Page) and MEMORY_BLOCK_CLEAR);
  Index := NativeInt(NativeUInt(Page) div MEMORY_PAGE_SIZE) and 15;
  if (not Page.Free(LuaCFunction)) then
  begin
    Block.Empties := Block.Empties or (1 shl Index);
    Exit;
  end;

  // decommit page (not first)
  if (Index <> 0) then
  begin
    Block.Empties := Block.Empties and (not (1 shl Index));
    Block.Reserved := Block.Reserved and (not (1 shl Index));
    {$if Defined(MSWINDOWS)}
      VirtualFree(Page, MEMORY_PAGE_SIZE, MEM_DECOMMIT);
    {$else}
    {$ifend}
  end;

  // check empty block
  if (Block.Empties <> 1) or (Block.Allocated <> 0) then
  begin
    Exit;
  end;

  // remove block
  Parent := @Blocks;
  repeat
    Item := Parent^;
    if (Item = Block) then
    begin
      Parent^ := Item.Next;
      {$if Defined(MSWINDOWS)}
        VirtualFree(Item, 0, MEM_RELEASE);
      {$else}
      {$ifend}
      Break;
    end;

    Parent := @Item.Next;
  until (False);
end;


{ Containers }

type
  TLuaList = object{<T>}
  private
    FBytes: TBytes;
    F: packed record
      Managed: Boolean;
      Padding: array[1..SizeOf(NativeUInt) - SizeOf(Boolean)] of Byte;
    end;
    FItemSize: NativeInt;
    FTypeInfo: PTypeInfo;
    FCapacity: NativeInt;
    FCount: NativeInt;

    procedure SetCapacity(const Value: NativeInt);
    function GetItem(const AIndex: NativeInt): Pointer;
  public
    procedure Init(const AItemSize: NativeInt; const ATypeInfo: PTypeInfo);
    procedure Clear;
    procedure TrimExcess;
    function Add: Pointer;

    property Bytes: TBytes read FBytes;
    property Managed: Boolean read F.Managed;
    property ItemSize: NativeInt read FItemSize;
    property TypeInfo: PTypeInfo read FTypeInfo;
    property Capacity: NativeInt read FCapacity write SetCapacity;
    property Count: NativeInt read FCount;
    property Items[const AIndex: NativeInt]: Pointer read GetItem;
  end;

  PLuaDictionaryItem = ^TLuaDictionaryItem;
  TLuaDictionaryItem = packed record
    Key: Pointer;
    Value: __luapointer;
    Next: Integer;
  end;

  TLuaDictionary = object{<Pointer,__luapointer>}
  private
    FItems: array of TLuaDictionaryItem;
    FHashes: array of Integer;
    FHashesMask: NativeInt;
    FCapacity: NativeInt;
    FCount: NativeInt;

    procedure Grow;
    function NewItem(const Key: Pointer): PLuaDictionaryItem;
    function InternalFind(const Key: Pointer; const ModeCreate: Boolean): PLuaDictionaryItem;
  public
    procedure Clear;
    procedure TrimExcess;
    function Find(const Key: Pointer): PLuaDictionaryItem; {$ifdef INLINESUPPORT}inline;{$endif}
    procedure Add(const Key: Pointer; const Value: __luapointer);

    property Capacity: NativeInt read FCapacity;
    property Count: NativeInt read FCount;
  end;

procedure SwapPtr(var Left, Right: Pointer);
var
  Temp: Pointer;
begin
  Temp := Left;
  Left := Right;
  Right := Temp;
end;

procedure TLuaList.Init(const AItemSize: NativeInt; const ATypeInfo: PTypeInfo);
begin
  Clear;
  SetCapacity(0);

  FItemSize := AItemSize;
  FTypeInfo := AtypeInfo;
  F.Managed := IsManagedTypeInfo(ATypeInfo);
end;

procedure TLuaList.SetCapacity(const Value: NativeInt);
var
  NewBytes: TBytes;
begin
  if (Value = Count) then
    Exit;
  if (Value < Count) then
    raise ELua.CreateFmt('Invalid capacity value %d, items count: %d', [Value, Count]);

  SetLength(NewBytes, Value * FItemSize);
  System.Move(Pointer(FBytes)^, Pointer(NewBytes)^, Count * FItemSize);
  FBytes := NewBytes;
  FCapacity := Value;
end;

procedure TLuaList.Clear;
begin
  if (Managed) and (Count <> 0) then
    FinalizeArray(Pointer(FBytes), TypeInfo, Count);
end;

procedure TLuaList.TrimExcess;
begin
  Self.Capacity := Count;
end;

function TLuaList.Add: Pointer;
label
  start;
var
  Index, Size: NativeInt;
begin
start:
  Index := FCount;
  if (Index <> FCapacity) then
  begin
    Inc(Index);
    FCount := Index;
    Dec(Index);
    Size := FItemSize;
    Result := @FBytes[Index * Size];

    if (F.Managed) then
    begin
      if (Size > 16) and (Assigned(FTypeInfo)) then
      begin
        InitializeArray(Result, FTypeInfo, 1);
      end else
      begin
        System.FillChar(Result^, Size, #0);
      end;
    end;

    Exit;
  end else
  begin
    if (FCapacity = 0) then
    begin
      SetCapacity(4);
    end else
    begin
      SetCapacity(FCapacity * 2);
    end;

    goto start;
  end;
end;

function TLuaList.GetItem(const AIndex: NativeInt): Pointer;
begin
  if (NativeUInt(AIndex) < NativeUInt(FCount)) then
  begin
    Result := @FBytes[AIndex * FItemSize];
    Exit;
  end else
  begin
    raise ELua.CreateFmt('Invalid item index %d, items count: %d', [AIndex, Count]);
  end;
end;

procedure TLuaDictionary.Clear;
begin
  FItems := nil;
  FHashes := nil;
  FHashesMask := 0;
  FCapacity := 0;
  FCount := 0;
end;

procedure TLuaDictionary.TrimExcess;
var
  NewItems: array of TLuaDictionaryItem;
begin
  SetLength(NewItems, FCount);
  System.Move(Pointer(FItems)^, Pointer(NewItems)^, FCount * SizeOf(TLuaDictionaryItem));
  SwapPtr(Pointer(FItems), Pointer(NewItems));
  FCapacity := FCount;
end;

procedure TLuaDictionary.Grow;
var
  i: NativeInt;
  Item: PLuaDictionaryItem;
  HashCode: Integer;
  Parent: PInteger;
  Pow2, NewCapacity: NativeInt;
  NewHashes: array of Integer;
begin
  Pow2 := FHashesMask;
  if (Pow2 <> 0) then
  begin
    Inc(Pow2);
    NewCapacity := (Pow2 shr 2) + (Pow2 shr 1);
    if (NewCapacity = Count) then
    begin
      Pow2 := Pow2 * 2;
      SetLength(NewHashes, Pow2);
      FillChar(Pointer(NewHashes)^, Pow2 * SizeOf(Integer), $ff);

      Item := Pointer(FItems);
      for i := 0 to Count - 1 do
      begin
        {$ifdef LARGEINT}
          HashCode := (NativeInt(Item.Key) shr 4) xor (NativeInt(Item.Key) shr 32);
        {$else .SMALLINT}
          HashCode := NativeInt(Item.Key) shr 4;
        {$endif}
        Inc(HashCode, (HashCode shr 16) * -1660269137);

        Parent := @NewHashes[NativeInt(HashCode) and FHashesMask];
        Item.Next := Parent^;
        Parent^ := i;

        Inc(Item);
      end;

      NewCapacity := (Pow2 shr 2) + (Pow2 shr 1);
      SwapPtr(Pointer(FHashes), Pointer(NewHashes));
    end;
    SetLength(FItems, NewCapacity);
    FCapacity := NewCapacity;
  end else
  begin
    SetLength(FItems, 3);
    SetLength(FHashes, 4);
    System.FillChar(Pointer(FHashes)^, 4 * SizeOf(Integer), $ff);
    FHashesMask := 3;
    FCapacity := 3;
  end;
end;

function TLuaDictionary.NewItem(const Key: Pointer): PLuaDictionaryItem;
label
  start;
var
  Index: NativeInt;
  HashCode: Integer;
  Parent: PInteger;
begin
start:
  Index := FCount;
  if (Index <> FCapacity) then
  begin
    Inc(Index);
    FCount := Index;
    Dec(Index);

    {$ifdef LARGEINT}
      HashCode := (NativeInt(Key) shr 4) xor (NativeInt(Key) shr 32);
    {$else .SMALLINT}
      HashCode := NativeInt(Key) shr 4;
    {$endif}
    Inc(HashCode, (HashCode shr 16) * -1660269137);

    Parent := @FHashes[NativeInt(HashCode) and FHashesMask];
    Result := @FItems[Index];
    Result.Key := Key;
    Result.Next := Parent^;
    Parent^ := Index;
  end else
  begin
    Grow;
    goto start;
  end;
end;

function TLuaDictionary.InternalFind(const Key: Pointer; const ModeCreate: Boolean): PLuaDictionaryItem;
var
  HashCode: Integer;
  HashesMask: NativeInt;
  Index: NativeInt;
begin
  {$ifdef LARGEINT}
    HashCode := (NativeInt(Key) shr 4) xor (NativeInt(Key) shr 32);
  {$else .SMALLINT}
    HashCode := NativeInt(Key) shr 4;
  {$endif}
  Inc(HashCode, (HashCode shr 16) * -1660269137);

  HashesMask := FHashesMask;
  if (HashesMask <> 0) then
  begin
    Index := FHashes[NativeInt(HashCode) and HashesMask];
    if (Index >= 0) then
    repeat
      Result := @FItems[Index];
      if (Result.Key = Key) then Exit;
      Index := Result.Next;
    until (Index < 0);
  end;

  if (ModeCreate) then
  begin
    Result := NewItem(Key);
  end else
  begin
    Result := nil;
  end;
end;

function TLuaDictionary.Find(const Key: Pointer): PLuaDictionaryItem;
{$ifdef INLINESUPPORT}
begin
  Result := InternalFind(Key, False);
end;
{$else}
asm
  xor ecx, ecx
  jmp TLuaDictionary.InternalFind
end;
{$endif}

procedure TLuaDictionary.Add(const Key: Pointer; const Value: __luapointer);
begin
  InternalFind(Key, True).Value := Value;
end;



               (*
function IsMemoryZeroed(const Memory: pointer; const Size: integer): boolean;
asm
  push edi
  mov ecx, edx
  mov edi, eax
  xor eax, eax

  test edi, edi
  jz @fail
  test ecx, ecx
  jle @fail

// ��������� ������� dword-��
  shr ecx, 2
  jz @bytes

  REPE SCASD
  jne @fail
  
// ��������� ���������� ������� ���� 0..3 (edx)
@bytes:
  test edx, 2
  jz @_1_byte
  cmp [edi], ax
  jnz @fail
  add edi, 2

@_1_byte:
  test edx, 1
  jz @ret_true
  cmp [edi], al
  jnz @fail

@ret_true:
  mov eax, 1
  pop edi
  ret
@fail:
  xor eax, eax
  pop edi
end;         *)

          (*
// ��������� ������ ������
const NULL_CHAR: char = #0;

procedure lua_push_pchar(const L: Plua_State; const S: PChar; const any4bytes: integer=0); cdecl;
asm
  pop ebp
  mov eax, [esp+8]
  test eax, eax
  jnz @1
  mov [esp+8], OFFSET NULL_CHAR
  jmp @2

// ������� ������
@1:xor ecx, ecx
   mov edx, eax
   @loop:
     cmp cl, [eax+0]
     je @_0
     cmp cl, [eax+1]
     je @_1
     cmp cl, [eax+2]
     je @_2
     cmp cl, [eax+3]
     je @_3
     add eax, 4
   jmp @loop
   @_3: inc eax
   @_2: inc eax
   @_1: inc eax
   @_0: sub eax, edx

// �����
@2:mov [esp+12], eax
   jmp lua_pushlstring
end;
      *)
                 (*
procedure lua_push_pascalstring(const L: Plua_State; const S: string; const any4bytes: integer=0); cdecl;
asm
  pop ebp
  mov eax, [esp+8]
  test eax, eax
  jnz @1
  mov [esp+8], OFFSET NULL_CHAR
  jmp @2

// ������� ������
@1:mov eax, [eax-4]

// �����
@2:mov [esp+12], eax
   jmp lua_pushlstring
end;
         *)
           (*
procedure AnsiFromPCharLen(var Dest: AnsiString; Source: PAnsiChar; Length: Integer);
{$ifdef fpc}
begin
  if (Dest <> '') then Dest := '';
  if (Length > 0) then
  begin
    SetLength(Dest, Length);
    Move(Source^, pointer(Dest)^, Length);
  end;
end;
{$else}
asm
  cmp [eax], 0
  jz @1
  push eax
  push edx
  push ecx
  call System.@LStrClr
  pop ecx
  pop edx
  pop eax
@1:
  test ecx, ecx
  jz @exit
  jmp System.@LStrFromPCharLen
@exit:
end;
{$endif}
            *)
              (*
procedure lua_to_pascalstring(var Dest: AnsiString; L: Plua_State; const Index: integer);
{$ifdef FPC} // todo �������������� ��� ��� ?
var
  Len: integer;
  S: pchar;
begin
  if (Dest <> '') then Dest := '';
  S := lua_tolstring(L, Index, @Len);

  if (Len <> 0) then
  begin
    SetLength(Dest, Len);
    Move(S^, pointer(Dest)^, Len);
  end;
end;
{$else}
var
  __Dest, __Len: integer;
asm
  mov __Dest, eax

  cmp [eax], 0
  jz @1
  push edx
  push ecx
  call System.@LStrClr
  pop ecx
  pop edx

@1:
  // lua_tolstring: function(L: Plua_State; idx: Integer; len: pinteger=nil): PChar; cdecl;
  lea eax, __Len
  push eax
  push ecx
  push edx
  call lua_tolstring
  add esp, $0c
  cmp __Len, 0
  jz @exit

  // LStrFromPCharLen
  mov edx, eax
  mov ecx, __Len
  mov eax, __Dest
  //call System.@LStrFromPCharLen
  mov esp, ebp
  pop ebp
  jmp System.@LStrFromPCharLen

@exit:
end;
{$endif}
           *)
             (*
function lua_toint64(L: Plua_State; idx: Integer): int64; register;
asm
  push edx
  push eax
  call lua_tonumber

  // ��������
  fistp qword ptr [esp]
  pop eax
  pop edx
end;
       *)

                     (*
// ����������� ����� ���-����
// pchar, ��� ����� ������� �������� �������, �� ��������� ������ LStrClr � HandleFinally
function LuaTypeName(const luatype: integer): pchar;
begin
  case luatype of
    LUA_TNONE         : Result := 'LUA_TNONE';
    LUA_TNIL          : Result := 'LUA_TNIL';
    LUA_TBOOLEAN      : Result := 'LUA_TBOOLEAN';
    LUA_TLIGHTUSERDATA: Result := 'LUA_TLIGHTUSERDATA';
    LUA_TNUMBER       : Result := 'LUA_TNUMBER';
    LUA_TSTRING       : Result := 'LUA_TSTRING';
    LUA_TTABLE        : Result := 'LUA_TTABLE';
    LUA_TFUNCTION     : Result := 'LUA_TFUNCTION';
    LUA_TUSERDATA     : Result := 'LUA_TUSERDATA';
  else
    Result := 'UNKNOWN';
  end;
end;       *)
             (*
function TypeKindName(const Kind: TTypeKind): string;
begin
  Result := EnumName(typeinfo(TTypeKind), byte(Kind));
end;

// �������� "��������" ���� userdata
// ����� ���� ������� ���������� �����, ����� ��������� ���������� �������� ! (������)
procedure GetUserDataType(var Result: string; const Lua: TLua; const userdata: PLuaUserData);
begin
  if (userdata = nil) then
  begin
    Result := 'nil userdata';
    exit;
  end;
  if (byte(userdata.kind) > byte(ukSet)) then
  begin
    Result := 'unknown userdata';
    exit;
  end;
  if (userdata.instance = nil) then
  begin
    Result := 'already destroyed';
    exit;
  end;

  case userdata.kind of
    ukInstance: Result := Lua.ClassesInfo[userdata.ClassIndex]._ClassName;
       ukArray: Result := userdata.ArrayInfo.Name;
         ukSet: Result := userdata.SetInfo.Name;
    ukProperty: Result := Format('difficult property ''%s''', [userdata.PropertyInfo.PropertyName]);
  end;
end; *)

 
          (*
// ����� ��������� �� �������� ������-�������, ���� �������� CFunction
// ����� ��� ������� ���-���������.
//
// ������ ���� ������� ����������������, �� ������������ �������� �������
// � ���� ������� ������ lua, �� ������������ ��� ����
function CFunctionPtr(CFunction: Lua_CFunction): pointer;
var
  ProcInfo: ^TLuaProcInfo;
begin
  Result := @CFunction;

  if (InsortedPos4(integer(@CFunction), CFunctionDumps) >= 0) then
  begin
    ProcInfo := ppointer(integer(@CFunction) + 11)^;
    if (ProcInfo <> nil) and (ProcInfo.Address <> nil) then Result := ProcInfo.Address;
  end;
end;     *)
           (*
type
  GLOBAL_NAME_SPACE = class(TObject); // ��� ��������� ��������� �����
  TForceString = procedure(const Arg: TLuaArg; var Ret: string);
  TForceVariant = procedure(const Arg: TLuaArg; var Ret: Variant);
  TStackArgument = procedure(const ALua: TLua; const Index: integer; var Ret: string);
               *)

              (*
procedure __LuaArgs(const Count: integer; var Result: TLuaArgs; const ReturnAddr: pointer);
begin
  if (Count < 0) then
  ELua.Assert('Can''t create an array lenght of %d arguments', [Count], ReturnAddr);

  SetLength(Result, Count);

  if (Count <> 0) then
  ZeroMemory(pointer(Result), Count*sizeof(TLuaArg));
end;       *)
            (*
function LuaArgs(const Count: integer): TLuaArgs;
asm
  mov ecx, [esp]
  jmp __LuaArgs
end;

function LuaArg(const Value: boolean): TLuaArg;
begin
  Result.AsBoolean := Value;
end;

function LuaArg(const Value: integer): TLuaArg;
begin
  Result.AsInteger := Value;
end;

function LuaArg(const Value: double): TLuaArg;
begin
  Result.AsDouble := Value;
end;

function LuaArg(const Value: string): TLuaArg;
begin
  Result.AsString := Value;
end;

function LuaArg(const Value: pointer): TLuaArg;
begin
  Result.AsPointer := Value;
end;

function LuaArg(const Value: TClass): TLuaArg;
begin
  Result.AsClass := Value;
end;

function LuaArg(const Value: TObject): TLuaArg;
begin
  Result.AsObject := Value;
end;

function LuaArg(const Value: TLuaRecord): TLuaArg;
begin
  Result.AsRecord := Value;
end;

function LuaArg(const Value: TLuaArray): TLuaArg;
begin
  Result.AsArray := Value;
end;

function LuaArg(const Value: TLuaSet): TLuaArg;
begin
  Result.AsSet := Value;
end;

function LuaArg(const Value: Variant): TLuaArg;
begin
  Result.AsVariant := Value;
end;

function LuaRecord(const Data: pointer; const Info: PLuaRecordInfo; const IsRef, IsConst: boolean): TLuaRecord;
begin
  Result.Data := Data;
  Result.Info := Info;
  Result.FIsRef := IsRef;
  Result.FIsConst := IsConst;
end;

function LuaArray(const Data: pointer; const Info: PLuaArrayInfo; const IsRef, IsConst: boolean): TLuaArray;
begin
  Result.Data := Data;
  Result.Info := Info;
  Result.FIsRef := IsRef;
  Result.FIsConst := IsConst;
end;

function LuaSet(const Data: pointer; const Info: PLuaSetInfo; const IsRef, IsConst: boolean): TLuaSet;
begin
  Result.Data := Data;
  Result.Info := Info;
  Result.FIsRef := IsRef;
  Result.FIsConst := IsConst;
end;     *)

{function NumberToInteger(var Number: double; var IntValue: integer): boolean;
begin
  Result := (frac(Number) = 0) and (abs(Number) <= MAXINT);
  if (Result) then IntValue := trunc(Number);
end;}
                      (*
function NumberToInteger(var Number: double; var IntValue: integer): boolean; overload;
asm
  sub esp, 16 {4, Int64, single}
  mov ecx, edx {���������}
  fld qword ptr [eax]
  fld st(0)

  // st(0) -> Int64
  FNSTCW word ptr[esp]
  FNSTCW word ptr[esp+2]
  OR word ptr[esp+2], $0F00  // trunc toward zero, full precision
  FLDCW word ptr[esp+2]
  FISTP qword ptr [esp+4]
  FLDCW word ptr[esp]

  // Frac
  fild qword ptr [esp+4]
  fsubp st(1), st(0)
  fstp dword ptr [esp+12]

  // Frac 0
  cmp [esp+12], 0
  jne @fail

  // Int64 -> integer
  mov eax, [esp+4]
  mov edx, [esp+8]
  sar eax, $1f
  cmp eax, edx
  jnz @fail

  mov edx, [esp+4]
  add esp, 16
  mov [ecx], edx
  mov eax, 1
  ret

@fail:
  xor eax, eax
  add esp, 16
  mov [ecx], eax
end;     *)
               (*
function NumberToInteger(var Number; const Handle: pointer; const Index: integer): boolean; overload;
asm
  push eax
  push ecx
  push edx
  call [lua_tonumber]
  add esp, 8
  pop ecx

  { luanumber � st(0), ������ �� ��������� - � eax }
  sub esp, 16 {4, Int64, single}
  fld st(0) // �����

  // st(0) -> Int64
  FNSTCW word ptr[esp]
  FNSTCW word ptr[esp+2]
  OR word ptr[esp+2], $0F00  // trunc toward zero, full precision
  FLDCW word ptr[esp+2]
  FISTP qword ptr [esp+4]
  FLDCW word ptr[esp]

  // Frac
  fild qword ptr [esp+4]
  fsub st(0), st(1)
  fstp dword ptr [esp+12]

  // Frac 0
  cmp [esp+12], 0
  jne @ret_double

  // Int64 -> integer
  mov eax, [esp+4]
  mov edx, [esp+8]
  sar eax, $1f
  cmp eax, edx
  jnz @ret_double

  // return integer
  ffree st(0)
  mov edx, [esp+4]
  add esp, 16
  mov [ecx], edx
  mov eax, 1
  ret

@ret_double:
  fstp qword ptr [ecx]
  add esp, 16
  xor eax, eax
end;   *)
                (*

// ������� ����� ���� TClass ��� PLuaRecordInfo ��� TLuaTable
// ������� ���������� ClassIndex � ������ TLuaClassInfo ��� -1 � ������ TLuaTable 
function LuaTableToClass(const Handle: pointer; const Index: integer): integer;
var
  Number: double;
  IntValue: integer absolute Number;
begin
  Result := -1;

  lua_rawgeti(Handle, Index, 0);
  if (lua_type(Handle, -1) = LUA_TNUMBER) then
  begin
    if (NumberToInteger(Number, Handle, -1)) and (IntValue and integer($FFFF0000) = integer(typeinfoTClass))
    then Result := IntValue and $0000FFFF;
  end;
  lua_settop(Handle, -1-1);  
end;       *)


(*
const
  GLOBAL_INDEX_KINDS: set of TLuaGlobalKind = [gkType, gkConst, gkLuaData];
  CONST_GLOBAL_KINDS: set of TLuaGlobalKind = [gkType, gkProc, gkConst];
  NATIVE_GLOBAL_KINDS: set of TLuaGlobalKind = [gkVariable, gkProc];
  RECORD_TYPES: set of TTypeKind = [tkRecord{$ifdef fpc},tkObject{$endif}];
  VARIANT_SUPPORT = [varEmpty, varNull, varSmallint, varInteger, varSingle,
                     varDouble, varCurrency, varDate, varOleStr, varBoolean, varError{as Empty},
                     varShortInt, varByte, varWord, varLongWord, varInt64{, ������-�� �� ��������� varString}];
  VARIANT_SIMPLE = VARIANT_SUPPORT - [varOleStr];

  

function LuaProc(const Proc: TLuaProc0): TLuaProc;
begin Result := TLuaProc(Proc); end;
function LuaProc(const Proc: TLuaProc1): TLuaProc;
begin Result := TLuaProc(Proc); end;
function LuaProc(const Proc: TLuaProc2): TLuaProc;
begin Result := TLuaProc(Proc); end;
function LuaProc(const Proc: TLuaProc3): TLuaProc;
begin Result := TLuaProc(Proc); end;
function LuaProc(const Proc: TLuaProc4): TLuaProc;
begin Result := TLuaProc(Proc); end;
function LuaProc(const Proc: TLuaProc5): TLuaProc;
begin Result := TLuaProc(Proc); end;
function LuaProc(const Proc: TLuaProc6): TLuaProc;
begin Result := TLuaProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc0): TLuaClassProc;
begin Result := TLuaClassProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc1): TLuaClassProc;
begin Result := TLuaClassProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc2): TLuaClassProc;
begin Result := TLuaClassProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc3): TLuaClassProc;
begin Result := TLuaClassProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc4): TLuaClassProc;
begin Result := TLuaClassProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc5): TLuaClassProc;
begin Result := TLuaClassProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc6): TLuaClassProc;
begin Result := TLuaClassProc(Proc); end;
function LuaClassProc(const Proc: TLuaClassProc7): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc8): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc9): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc10): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc11): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc12): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc13): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc14): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc15): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc16): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc17): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc18): TLuaClassProc;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc19): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc20): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc21): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc22): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc23): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc24): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc25): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc26): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProc(const Proc: TLuaClassProc27): TLuaClassProc; overload;
begin TMethod(Result).Code := @Proc; end;
function LuaClassProcPtr(const Proc: pointer): TLuaClassProc;
begin TMethod(Result).Code := Proc; end;
                         *)
                                (*
// -----------   �������� � �����������   -------------
type
  _set1 = set of 0..7;
  _set2 = set of 0..15;
  _set4 = set of 0..31;

procedure IncludeSetBit(const _Set: pointer; const Bit: integer);
asm
  bts [eax], edx
end;

procedure ExcludeSetBit(const _Set: pointer; const Bit: integer);
asm
  btr [eax], edx
end;

function SetBitContains(const _Set: pointer; const Bit: integer): boolean;
asm
  bt [eax], edx
  setc al
end;


// ����� �� System � ��������������
function  _SetLe(const X1, X2: pointer; const Size: integer): boolean;
asm
  test ecx, 3
  jnz @@loop

  push ebx
  shr ecx, 2
@@loop_dwords:
        mov ebx, [edx]
        not ebx
        and ebx, [eax]
        jne @@pop_ebx_exit
        add edx, 4
        add eax, 4
        dec ecx
        jnz @@loop_dwords
        jmp @@pop_ebx_exit

@@loop:
        MOV     CH,[EDX]
        NOT     CH
        AND     CH,[EAX]
        JNE     @@exit
        INC     EDX
        INC     EAX
        DEC     CL
        JNZ     @@loop
        JMP     @@exit

@@pop_ebx_exit:
  pop ebx
@@exit:
  setz al
  and  eax, $FF
end;

// �� �������� � System, ������ ���� ����� ��������������
function _SetEq(const X1, X2: pointer; const Size: integer): boolean;
asm
  push ebx
  jmp @1

@@dwords:
    mov ebx, [eax]
    cmp ebx, [edx]
    jne @@exit
    add eax, 4
    add edx, 4
@1: sub ecx, 4
    jge @@dwords
    je  @@exit

@@bytes: add ecx, 4
@@loop:
    mov bl, [eax+ecx-1]
    cmp bl, [edx+ecx-1]
    jne @@exit
    dec ecx
    jnz @@loop

@@exit:
  pop ebx
  sete al
  and  eax, $FF
end;
            *)
              (*
// ��������� ��������
// ���� "subset"  �������� "�������� �� X1 ������������� X2"
// � ��������� ������� ���� �������� �� ���������
// Result = 0 ���� True � 1 ���� False (������� = subset)
function SetsCompare(const X1, X2: pointer; const Size: integer; const subset: boolean): integer; overload;
var
  Ret: boolean;
begin
  if (subset) then
  begin
    case (Size) of
      1: Ret := (_set1(X1^) <= _set1(X2^));
      2: Ret := (_set2(X1^) <= _set2(X2^));
      4: Ret := (_set4(X1^) <= _set4(X2^));
    else
      Ret := _SetLe(X1, X2, Size);
    end;
  end else
  begin
    case (Size) of
      1: Ret := (_set1(X1^) = _set1(X2^));
      2: Ret := (_set2(X1^) = _set2(X2^));
      4: Ret := (_set4(X1^) = _set4(X2^));
    else
      Ret := _SetEq(X1, X2, Size);
    end;
  end;

  // ���������
  Result := ord(not Ret);  
end;

// ������������� �������
// ��������� 32-������� ����� ������ � ��������� i-� ����
function __bit_include(var X2; const Bit: integer): pointer;
asm
  xor ecx, ecx
  mov [eax +  0], ecx
  mov [eax +  4], ecx
  mov [eax +  8], ecx
  mov [eax + 12], ecx
  mov [eax + 16], ecx
  mov [eax + 20], ecx
  mov [eax + 24], ecx
  mov [eax + 28], ecx

  bts [eax], edx
  {push ebx
  mov ecx, edx
  mov ebx, 1
  and ecx, 7
  shr edx, 3
  shl ebx, cl
  mov [eax + edx], bl
  pop ebx }
end;
         *)
             (*
function SetsCompare(const X1: pointer; const Value, Size: integer; const subset: boolean): integer; overload;
var
  X2: array[0..31] of byte;
  Ret: boolean;
begin
  if (subset) then
  begin
    case (Size) of
      {$ifndef fpc}
      1: Ret := (_set1(X1^) <= _set1(byte(1 shl Value)));
      2: Ret := (_set2(X1^) <= _set2(word(1 shl Value)));
      {$endif}
      4: Ret := (_set4(X1^) <= _set4(integer(1 shl Value)));
    else
      // ������� �������
      Ret := _SetLe(X1, __bit_include(X2, Value), Size);
    end;
  end else
  begin
    case (Size) of
      {$ifndef fpc}
      1: Ret := (_set1(X1^) = _set1(byte(1 shl Value)));
      2: Ret := (_set2(X1^) = _set2(word(1 shl Value)));
      {$endif}
      4: Ret := (_set4(X1^) = _set4(integer(1 shl Value)));
    else
      Ret := _SetEq(X1, __bit_include(X2, Value), Size);
    end;
  end;

  // ���������
  Result := ord(not Ret);  
end;     *)
           (*
// ����������� ��������
procedure SetsUnion(const Dest, X1, X2: pointer; const Size: integer); overload;
asm
  push ebx
  jmp  @@start

@@dwords:
  mov ebx, [edx]
  add edx, 4
  or  ebx, [ecx]
  add ecx, 4
  mov [eax], ebx
  add eax, 4
@@start:
  sub Size, 4
  jg @@dwords
  je @@4

@@bytes:
  inc Size
  jz @@3
  inc Size
  jz @@2

@@1:
  mov bl, [edx]
  or  bl, [ecx]
  mov [eax], bl
  jmp @@exit
@@2:
  mov bx, [edx]
  or  bx, [ecx]
  mov [eax], bx
  jmp @@exit
@@3:
  mov bx, [edx]
  or  bx, [ecx]
  mov [eax], bx
  mov bl, [edx+2]
  or  bl, [ecx+2]
  mov [eax+2], bl
  jmp @@exit
@@4:
  mov ebx, [edx]
  or  ebx, [ecx]
  mov [eax], ebx
@@exit:
  pop ebx
end;    *)
          (*
procedure SetsUnion(const Dest, X1: pointer; const Value, Size: integer); overload;
var
  X2: array[0..31] of byte;
begin
  case Size of
    {$ifndef fpc}
    1: _set1(Dest^) := _set1(X1^) + _set1(byte(1 shl Value));
    2: _set2(Dest^) := _set2(X1^) + _set2(word(1 shl Value));
    {$endif}
    4: _set4(Dest^) := _set4(X1^) + _set4(integer(1 shl Value));
  else
    SetsUnion(Dest, X1, __bit_include(X2, Value), Size);
  end;                             
end;    *)
              (*
// �������� ��������
procedure SetsDifference(const Dest, X1, X2: pointer; const Size: integer); overload;
asm
  push ebx
  jmp  @@start

@@dwords:
  mov ebx, [edx]
  add edx, 4
  xor ebx, [ecx]
  add ecx, 4
  mov [eax], ebx
  add eax, 4
@@start:
  sub Size, 4
  jg @@dwords
  je @@4

@@bytes:
  inc Size
  jz @@3
  inc Size
  jz @@2

@@1:
  mov bl, [edx]
  xor bl, [ecx]
  mov [eax], bl
  jmp @@exit
@@2:
  mov bx, [edx]
  xor bx, [ecx]
  mov [eax], bx
  jmp @@exit
@@3:
  mov bx, [edx]
  xor bx, [ecx]
  mov [eax], bx
  mov bl, [edx+2]
  xor bl, [ecx+2]
  mov [eax+2], bl
  jmp @@exit
@@4:
  mov ebx, [edx]
  xor ebx, [ecx]
  mov [eax], ebx
@@exit:
  pop ebx
end;      *)
           (*
procedure SetsDifference(const Dest, X1: pointer; const Value, Size: integer; const Exchenge: boolean); overload;
var
  X2: array[0..31] of byte;
begin
  if (not Exchenge) then
  begin
    case Size of
      {$ifndef fpc}
      1: _set1(Dest^) := _set1(X1^) - _set1(byte(1 shl Value));
      2: _set2(Dest^) := _set2(X1^) - _set2(word(1 shl Value));
      {$endif}
      4: _set4(Dest^) := _set4(X1^) - _set4(integer(1 shl Value));
    else
      SetsDifference(Dest, X1, __bit_include(X2, Value), Size);
    end;
  end else
  begin
  case Size of
      {$ifndef fpc}
      1: _set1(Dest^) := _set1(byte(1 shl Value)) - _set1(X1^);
      2: _set2(Dest^) := _set2(word(1 shl Value)) - _set2(X1^);
      {$endif}
      4: _set4(Dest^) := _set4(integer(1 shl Value))- _set4(X1^);
    else
      SetsDifference(Dest, __bit_include(X2, Value), X1, Size);
    end;
  end;
end;   *)
         (*
// ����������� ��������
procedure SetsIntersection(const Dest, X1, X2: pointer; const Size: integer); overload;
asm
  push ebx
  jmp  @@start

@@dwords:
  mov ebx, [edx]
  add edx, 4
  and ebx, [ecx]
  add ecx, 4
  mov [eax], ebx
  add eax, 4
@@start:
  sub Size, 4
  jg @@dwords
  je @@4

@@bytes:
  inc Size
  jz @@3
  inc Size
  jz @@2

@@1:
  mov bl, [edx]
  and bl, [ecx]
  mov [eax], bl
  jmp @@exit
@@2:
  mov bx, [edx]
  and bx, [ecx]
  mov [eax], bx
  jmp @@exit
@@3:
  mov bx, [edx]
  and bx, [ecx]
  mov [eax], bx
  mov bl, [edx+2]
  and bl, [ecx+2]
  mov [eax+2], bl
  jmp @@exit
@@4:
  mov ebx, [edx]
  and ebx, [ecx]
  mov [eax], ebx
@@exit:
  pop ebx
end;      *)
            (*
procedure SetsIntersection(const Dest, X1: pointer; const Value, Size: integer); overload;
var
  X2: array[0..31] of byte;
begin
  case Size of
    {$ifndef fpc}
    1: _set1(Dest^) := _set1(X1^) * _set1(byte(1 shl Value));
    2: _set2(Dest^) := _set2(X1^) * _set2(word(1 shl Value));
    {$endif}
    4: _set4(Dest^) := _set4(X1^) * _set4(integer(1 shl Value));
  else
    SetsIntersection(Dest, X1, __bit_include(X2, Value), Size);
  end;                             
end;     *)
           (*
procedure SetInvert(const Dest, X1: pointer; const AndMasks, Size: integer);
asm
  push eax
  push ebx
  jmp  @@start

@@dwords:
  mov ebx, [edx]
  add eax, 4
  not ebx
  add edx, 4
  mov [eax-4], ebx
@@start:
  sub Size, 4
  jg @@dwords
  je @@4

@@bytes:
  inc Size
  jz @@3
  inc Size
  jz @@2

@@1:
  mov bl, [edx]
  not ebx
  and ebx, ecx // and bl, cl
  mov [eax], bl
  jmp @@exit
@@2:
  mov bx, [edx]
  not ebx
  mov [eax], bx
  and [eax+1], cl
  jmp @@exit
@@3:
  mov bx, [edx]
  not ebx
  mov [eax], bx
  mov bl, [edx+2]
  not ebx
  and ebx, ecx // and bl, cl
  mov [eax+2], bl
  jmp @@exit
@@4:
  mov ebx, [edx]
  not ebx
  mov [eax], ebx
  and [eax+3], cl
@@exit:
  pop ebx
  pop eax
  and [eax], ch
end;      *)


                (*

{ TLuaArg }

procedure TLuaArg.Assert(const NeededType: TLuaArgType; const CodeAddr: pointer);

  function TypeToString(T: TLuaArgType; const DelPrefics:boolean = false): string;
  begin
    Result := EnumName(typeinfo(TLuaArgType), byte(T));
    if (DelPrefics) then Delete(Result, 1, 2);
  end;
begin
  if (LuaType <> NeededType) then
  ELua.Assert('Argument can''t be getted as %s because current type is "%s"',
             [TypeToString(NeededType), TypeToString(LuaType, true)], CodeAddr);
end;

function TLuaArg.GetLuaTypeName: string;
begin
  Result := EnumName(typeinfo(TLuaArgType), byte(FLuaType));
end;

function TLuaArg.GetEmpty: boolean;
begin
  GetEmpty := (FLuaType = ltEmpty);
end;

procedure TLuaArg.SetEmpty(const Value: boolean);
begin
  if (Value) then
  begin
    str_data := '';
    pinteger(@FLuaType)^ := 0;
    Data[0] := 0;
    Data[1] := 0;
  end;
end;

function __TLuaArgGetBoolean(const Self: TLuaArg; const ReturnAddr: pointer): boolean;
begin
  if (Self.LuaType <> ltBoolean) then Self.Assert(ltBoolean, ReturnAddr);
  __TLuaArgGetBoolean := (Self.Data[0] <> 0);
end;

function TLuaArg.GetBoolean(): boolean;
asm
  mov edx, [esp]
  jmp __TLuaArgGetBoolean
end;

procedure TLuaArg.SetBoolean(const Value: boolean);
begin
  FLuaType := ltBoolean;
  Data[0] := ord(Value);
end;

function __TLuaArgGetInteger(const Self: TLuaArg; const ReturnAddr: pointer): integer;
begin
  if (Self.LuaType <> ltInteger) then Self.Assert(ltInteger, ReturnAddr);
  __TLuaArgGetInteger := Self.Data[0];
end;

function TLuaArg.GetInteger(): integer;
asm
  mov edx, [esp]
  jmp __TLuaArgGetInteger
end;

procedure TLuaArg.SetInteger(const Value: integer);
begin
  FLuaType := ltInteger;
  Data[0] := Value;
end;

function __TLuaArgGetDouble(const Self: TLuaArg; const ReturnAddr: pointer): double;
begin
  if (Self.LuaType = ltInteger) then __TLuaArgGetDouble := Self.Data[0]
  else
  begin
    if (Self.LuaType <> ltDouble) then Self.Assert(ltDouble, ReturnAddr);
    __TLuaArgGetDouble := pdouble(@Self.Data)^;
  end;
end;

function TLuaArg.GetDouble(): double;
asm
  mov edx, [esp]
  jmp __TLuaArgGetDouble
end;

procedure TLuaArg.SetDouble(Value: double);
begin
  if (NumberToInteger(Value, Data[0])) then
  begin
    FLuaType := ltInteger;
  end else
  begin
    FLuaType := ltDouble;
    pdouble(@Data)^ := Value;
  end;
end;

procedure __TLuaArgGetString(const Self: TLuaArg; var Result: string; const ReturnAddr: pointer);
begin
  if (Self.LuaType <> ltString) then Self.Assert(ltString, ReturnAddr);
  Result := Self.str_data;
end;

function TLuaArg.GetString(): string;
asm
  mov ecx, [esp]
  jmp __TLuaArgGetString
end;

procedure TLuaArg.SetString(const Value: string);
begin
  str_data := Value;
  FLuaType := ltString;
end;

function __TLuaArgGetPointer(const Self: TLuaArg; const ReturnAddr: pointer): pointer;
begin
  if (Self.LuaType = ltEmpty) then __TLuaArgGetPointer := nil
  else
  begin
    if (Self.LuaType <> ltPointer) then Self.Assert(ltPointer, ReturnAddr);
    __TLuaArgGetPointer := pointer(Self.Data[0]);
  end;
end;

function TLuaArg.GetPointer(): pointer;
asm
  mov edx, [esp]
  jmp __TLuaArgGetPointer
end;

procedure TLuaArg.SetPointer(const Value: pointer);
begin
  pointer(Data[0]) := Value;

  if (Value <> nil) then FLuaType := ltPointer
  else FLuaType := ltEmpty;
end;

procedure __TLuaArgGetVariant(var Self: TLuaArg; var Result: Variant; const ReturnAddr: pointer);
begin
  if (Self.FLuaType in [ltEmpty, ltBoolean, ltInteger, ltDouble, ltString]) then Result := Self.ForceVariant
  else
  begin
    Self.str_data := EnumName(typeinfo(TLuaArgType), byte(Self.FLuaType));
    ELua.Assert('Argument can''t be getted as Variant because current type is "%s"', [Self.str_data], ReturnAddr);
  end;
end;

function TLuaArg.GetVariant(): Variant;
asm
  mov ecx, [esp]
  jmp __TLuaArgGetVariant
end;      *)
            (*
// 0: TDateTime, 1: TDate, 2: TTime
function InspectDateTime(const Value: PDateTime): integer;
var
  TR: integer;
  FR: integer;
asm
  fld qword ptr [eax]
  fld st(0)

  sub esp, 4
  FNSTCW word ptr[esp]
  FNSTCW word ptr[esp+2]
  OR word ptr[esp+2], $0F00  // trunc toward zero, full precision
  FLDCW word ptr[esp+2]
  FISTP TR
  FLDCW word ptr[esp]
  add esp, 4
  mov edx, TR

  fisub TR
  fstp FR
  mov ecx, FR

  // ���������
  xor  eax, eax
  test edx, edx
  jnz @1
  add eax, 2
  @1:
  test ecx, ecx
  jnz @2
  inc eax
  @2:
  cmp eax, 3
  jne @3
  xor eax, eax
  @3:
end;         *)
               (*
procedure __TLuaArgSetVariant(var Self: TLuaArg; const Value: Variant; const ReturnAddr: pointer);
type
  TDateProc = procedure(const DateTime: TDateTime; var Ret: string);

begin
  with TVarData(Value) do
  case (VType) of
    varEmpty, varNull: Self.FLuaType := ltEmpty;
    varSmallint: Self.SetInteger(VSmallInt);
    varInteger : Self.SetInteger(VInteger);
    varSingle  : Self.SetDouble(VSingle);
    varDouble  : Self.SetDouble(VDouble);
    varCurrency: Self.SetDouble(VCurrency);
    varDate    : begin
                   // SetString(DateTimeToStr(VDate));
                   Self.FLuaType := ltString;
                   if (Self.str_data <> '') then Self.str_data := '';
                   case InspectDateTime(@VDate) of
                     0: TDateProc(@DateTimeToStr)(VDate, Self.str_data);
                     1: TDateProc(@DateToStr)(VDate, Self.str_data);
                     2: TDateProc(@TimeToStr)(VDate, Self.str_data);
                   end;
                 end;
    varOleStr  : begin
                   // SetString(ansistring(VOleStr));
                   Self.FLuaType := ltString;
                   Self.str_data := VOleStr;
                 end;
    varBoolean : Self.SetBoolean(VBoolean);
    varShortInt: Self.SetInteger(VShortInt);
    varByte    : Self.SetInteger(VByte);
    varWord    : Self.SetInteger(VWord);
    varLongWord: Self.SetInteger(VLongWord);
    varInt64   : Self.SetDouble(VInt64);
    varString  : Self.SetString(string(VString));
  else
    ELua.Assert('Unknown variant type %d in "TLuaArg.SetVariant" procedure', [VType], ReturnAddr);
  end;
end;

procedure TLuaArg.SetVariant(const Value: Variant);
asm
  mov ecx, [esp]
  jmp __TLuaArgSetVariant
end;

function __TLuaArgGetClass(const Self: TLuaArg; const ReturnAddr: pointer): TClass;
begin
  if (Self.LuaType = ltEmpty) then __TLuaArgGetClass := nil
  else
  begin
    if (Self.LuaType <> ltClass) then Self.Assert(ltClass, ReturnAddr);
    __TLuaArgGetClass := TClass(Self.Data[0]);
  end;
end;

function TLuaArg.GetClass(): TClass;
asm
  mov edx, [esp]
  jmp __TLuaArgGetClass
end;


procedure TLuaArg.SetClass(const Value: TClass);
begin
  TClass(Data[0]) := Value;

  if (Value <> nil) then FLuaType := ltClass
  else FLuaType := ltEmpty;
end;

function __TLuaArgGetObject(const Self: TLuaArg; const ReturnAddr: pointer): TObject;
begin
  if (Self.LuaType = ltEmpty) then __TLuaArgGetObject := nil
  else begin
    if (Self.LuaType <> ltObject) then Self.Assert(ltObject, ReturnAddr);
    __TLuaArgGetObject := TObject(Self.Data[0]);
  end;
end;

function TLuaArg.GetObject(): TObject;
asm
  mov edx, [esp]
  jmp __TLuaArgGetObject
end;


procedure TLuaArg.SetObject(const Value: TObject);
begin
  TObject(Data[0]) := Value;

  if (Value <> nil) then FLuaType := ltObject
  else FLuaType := ltEmpty;
end;

procedure __TLuaArgGetRecord(const Self: TLuaArg; var Result: TLuaRecord; const ReturnAddr: pointer);
begin
  if (Self.LuaType <> ltRecord) then Self.Assert(ltRecord, ReturnAddr);
  Result := PLuaRecord(@Self.FLuaType)^;
end;

function TLuaArg.GetRecord(): TLuaRecord;
asm
  mov ecx, [esp]
  jmp __TLuaArgGetRecord
end;
          *)
            (*
procedure __TLuaArgSetRecord(var Self: TLuaArg; const Value: TLuaRecord; const ReturnAddr: pointer);
begin
  if (Value.Data = nil) then
  ELua.Assert('LuaRecord.Data = nil. LuaRecord should point to a record', ReturnAddr);

  if (Value.Info = nil) then
  ELua.Assert('LuaRecord.Info is not defined', ReturnAddr);

  if (byte(Value.FIsRef) > 1) then
  ELua.Assert('LuaRecord.IsRef is not defined', ReturnAddr);

  PLuaRecord(@Self.FLuaType)^ := Value;
  Self.FLuaType := ltRecord;
end;

procedure TLuaArg.SetRecord(const Value: TLuaRecord);
asm
  mov ecx, [esp]
  jmp __TLuaArgSetRecord
end;

procedure __TLuaArgGetArray(const Self: TLuaArg; var Result: TLuaArray; const ReturnAddr: pointer);
begin
  if (Self.LuaType <> ltArray) then Self.Assert(ltArray, ReturnAddr);
  Result := PLuaArray(@Self.FLuaType)^;
end;

function  TLuaArg.GetArray: TLuaArray;
asm
  mov ecx, [esp]
  jmp __TLuaArgGetArray
end;

procedure __TLuaArgSetArray(var Self: TLuaArg; const Value: TLuaArray; const ReturnAddr: pointer);
begin
  if (Value.Data = nil) then
  ELua.Assert('LuaArray.Data = nil. LuaArray should point to an array', ReturnAddr);

  if (Value.Info = nil) then
  ELua.Assert('LuaArray.Info is not defined', ReturnAddr);

  if (byte(Value.FIsRef) > 1) then
  ELua.Assert('LuaArray.IsRef is not defined', ReturnAddr);

  PLuaArray(@Self.FLuaType)^ := Value;
  Self.FLuaType := ltArray;
end;

procedure TLuaArg.SetArray(const Value: TLuaArray);
asm
  mov ecx, [esp]
  jmp __TLuaArgSetArray
end;

procedure __TLuaArgGetSet(const Self: TLuaArg; var Result: TLuaSet; const ReturnAddr: pointer);
begin
  if (Self.LuaType <> ltSet) then Self.Assert(ltSet, ReturnAddr);
  Result := PLuaSet(@Self.FLuaType)^;
end;

function  TLuaArg.GetSet: TLuaSet;
asm
  mov ecx, [esp]
  jmp __TLuaArgGetSet
end;

procedure __TLuaArgSetSet(var Self: TLuaArg; const Value: TLuaSet; const ReturnAddr: pointer);
begin
  if (Value.Data = nil) then
  ELua.Assert('LuaSet.Data = nil. LuaSet should point to an array', ReturnAddr);

  if (Value.Info = nil) then
  ELua.Assert('LuaSet.Info is not defined', ReturnAddr);

  if (byte(Value.FIsRef) > 1) then
  ELua.Assert('LuaSet.IsRef is not defined', ReturnAddr);

  PLuaSet(@Self.FLuaType)^ := Value;
  Self.FLuaType := ltSet;
end;

procedure TLuaArg.SetSet(const Value: TLuaSet);
asm
  mov ecx, [esp]
  jmp __TLuaArgSetSet
end;

function __TLuaArgGetTable(const Self: TLuaArg; const ReturnAddr: pointer): PLuaTable;
begin
  if (Self.LuaType <> ltTable) then Self.Assert(ltTable, ReturnAddr);
  __TLuaArgGetTable := PLuaTable(@Self.FLuaType);
end;

function TLuaArg.GetTable(): PLuaTable;
asm
  mov edx, [esp]
  jmp __TLuaArgGetTable
end;       *)
                                          
            (*
// 0 - false
// 1 - true
// <0 - fail
function __cast_string_as_boolean(const S: string): integer;
// generated by "Static Serializer"
type
  __TAnsiPointerData = packed record
  case integer of
    0: (chars: array[0..high(integer)-1] of ansichar);
    1: (words: array[0..high(integer)div 2-1] of word);
    2: (dwords: array[0..high(integer)div 4-1] of dword);
  end;
begin
  Result := low(integer); {fail = not defined}

  { not case sensitive, ansi }
  with __TAnsiPointerData(pointer(S)^) do
  case (Length(S)) of
   0: Result := 0; // empty string
   1: case (chars[0]) of
        '0': Result := 0; // "0"
        '1': Result := 1; // "1"
      end;
   2: case (words[0]) of
        $6F6E,$6F4E,$4F6E,$4F4E: Result := 0; // "no"
        $6B6F,$6B4F,$4B6F,$4B4F: Result := 1; // "ok"
      end;
   3: if (chars[0]in['y','Y'])and(chars[1]in['e','E'])and(chars[2]in['s','S']) then Result := 1; // "yes"
   4: case (words[0]) of
        $6F6E,$6F4E,$4F6E,$4F4E: if (chars[2]in['n','N'])and(chars[3]in['e','E']) then Result := 0; // "none"
        $7274,$7254,$5274,$5254: if (chars[2]in['u','U'])and(chars[3]in['e','E']) then Result := 1; // "true"
      end;
   5: if ((dwords[0]=$736C6166)or((chars[0]in['f','F'])and(chars[1]in['a','A'])and
          (chars[2]in['l','L'])and(chars[3]in['s','S'])))
      and(chars[4]in['e','E']) then Result := 0; // "false"

   6: if ((dwords[0]=$636E6163)or((chars[0]in['c','C'])and(chars[1]in['a','A'])and
          (chars[2]in['n','N'])and(chars[3]in['c','C'])))
      and(chars[4]in['e','E'])and(chars[5]in['l','L']) then Result := 0; // "cancel"
  end;
end;      *)

            (*
function TLuaArg.ForceBoolean: boolean;
begin
  case LuaType of
      ltEmpty: ForceBoolean := false;
    ltBoolean: ForceBoolean := (Data[0] <> 0);
    ltInteger: ForceBoolean := (Data[0] > 0);
     ltDouble: ForceBoolean := (pdouble(@Data)^ > 0);
     ltString: ForceBoolean := (__cast_string_as_boolean(str_data) > 0);
  else
    ForceBoolean := (Data[0] <> 0);;
  end;
end;

function TLuaArg.ForceInteger: integer;
begin
  case LuaType of
      ltEmpty: ForceInteger := 0;
     ltDouble: ForceInteger := Trunc(pdouble(@Data)^);
     ltString: ForceInteger := StrToIntDef(str_data, 0);
     ltObject: ForceInteger := TObject(Data[0]).InstanceSize;
     ltRecord: ForceInteger := integer(PLuaRecord(@FLuaType).Info.Size);
   ltTable: ForceInteger := PLuaTable(@FLuaType).Length;
  else
    ForceInteger := Data[0];
  end;
end;

function TLuaArg.ForceDouble: double;
begin
  case LuaType of
      ltEmpty: ForceDouble := 0;
    ltBoolean: ForceDouble := Data[0];
    ltInteger: ForceDouble := Data[0];
     ltDouble: ForceDouble := pdouble(@Data)^;
     ltString: ForceDouble := StrToFloatDef(str_data, 0);
  else
    ForceDouble := 0;
  end;
end;

function TLuaArg.ForceString: string;
const
  BOOLEANS: array[boolean] of string = ('false', 'true');
begin
  case LuaType of
    ltBoolean: ForceString := BOOLEANS[Data[0] <> 0];
    ltInteger: ForceString := IntToStr(Data[0]);
     ltDouble: ForceString := Format('%0.2f', [pdouble(@Data)^]);
     ltString: ForceString := str_data;
    ltPointer: ForceString := IntToHex(Data[0], 8);
      ltClass: ForceString := TClass(Data[0]).ClassName;
     ltObject: begin
                if (TObject(Data[0]) is TComponent) then ForceString := TComponent(Data[0]).Name
                else ForceString := TObject(Data[0]).ClassName;
               end;
     ltRecord: ForceString := PLuaRecord(@FLuaType).Info.Name;
      ltArray: ForceString := PLuaArray(@FLuaType).Info.Name;
        ltSet: with PLuaSet(@FLuaType)^ do ForceString := Info.Description(Data);
      ltTable: ForceString := 'LuaTable';
  else
    {ltEmpty:}
    ForceString := 'nil';
  end;
end;

function TLuaArg.ForcePointer: pointer;
begin
  case LuaType of
    ltPointer, ltClass, ltObject, ltRecord, ltArray, ltSet: ForcePointer := pointer(Data[0]);
    ltString: ForcePointer := pointer(str_data);
     ltTable: ForcePointer := PLuaTable(@FLuaType);
  else
    ForcePointer := nil;
  end;
end;

function TLuaArg.ForceVariant: Variant;
var
  VarData: TVarData absolute Result;
begin
  // ������� ���� ��� �����
  if (VarData.VType = varString) or (not (VarData.VType in VARIANT_SIMPLE)) then VarClear(Result);

  // ��������� ��������
  case (LuaType) of
    ltBoolean: begin
                 VarData.VType := varBoolean;
                 VarData.VBoolean := Data[0] <> 0;
               end;
    ltInteger: begin
                 VarData.VType := varInteger;
                 VarData.VInteger := Data[0];
               end;
     ltDouble: begin
                 VarData.VType := varDouble;
                 VarData.VDouble := double(Data);
               end;
     ltString: begin
                 { Unicode ? todo}
                 VarData.VType := varString;
                 VarData.VInteger := 0;

                 if (str_data <> '') then
                 string(VarData.VString) := str_data;
               end;
   else
     {ltEmpty � ��:}
     VarData.VType := varEmpty;
  end;
end;

function TLuaArg.ForceClass: TClass;
begin
  case LuaType of
    ltClass: ForceClass := TClass(Data[0]);
   ltObject: ForceClass := TClass(pointer(Data[0])^);
  else
    ForceClass := nil;
  end;
end;

function TLuaArg.ForceObject: TObject;
begin
  case LuaType of
    ltObject: ForceObject := TObject(Data[0]);
  else
    ForceObject := nil;
  end;  
end;

function TLuaArg.ForceRecord: TLuaRecord;
begin
  case LuaType of
    ltRecord: Result := PLuaRecord(@FLuaType)^;
  else
    ZeroMemory(@Result, sizeof(Result));
  end;
end;

function TLuaArg.ForceArray: TLuaArray;
begin
  case LuaType of
    ltArray: Result := PLuaArray(@FLuaType)^;
  else
    ZeroMemory(@Result, sizeof(Result));
  end;
end;

function TLuaArg.ForceSet: TLuaSet;
begin
  case LuaType of
    ltSet: Result := PLuaSet(@FLuaType)^;
  else
    ZeroMemory(@Result, sizeof(Result));
  end;
end;

function TLuaArg.ForceTable: PLuaTable;
begin
  case LuaType of
    ltTable: ForceTable := PLuaTable(@FLuaType);
  else
    ForceTable := nil;
  end;
end;
       *)
              (*
{ TLuaTableItem }

const
  PAIRS_ITERATING = high(integer)-1;
  PAIRS_BROKEN = high(integer)-0;

procedure TLuaPair.ThrowNotInitialized(const CodeAddr: pointer);
begin
  ELua.Assert('TLuaTableItem operation is not available, because an item is not initialized', [], CodeAddr);
end;

procedure TLuaPair.ThrowValueType(const CodeAddr: pointer; const pop: boolean);
begin
  if (pop) then Lua.stack_pop();
  ELua.Assert('Unsupported value type = "%s"', [Lua.FBufferArg.str_data], CodeAddr);
end;

procedure TLuaPair.ThrowBroken(const CodeAddr: pointer; const Action: string);
begin
  ELua.Assert('Can''t %s, because the Item is broken', [Action], CodeAddr);
end;

function TLuaPair.Initialize(const ALua: TLua; const AIndex: integer; const UseKey: boolean): boolean;
const
  MODES: array[boolean] of integer = (PAIRS_BROKEN, PAIRS_ITERATING);
begin
  Lua := ALua;
  Handle := ALua.Handle;
  KeyIndex := lua_gettop(Handle);
  ValueIndex := KeyIndex+1;

  Index := AIndex;
  if (AIndex < 0) then Index := KeyIndex+AIndex; // 1 ���������� �� ����, ������ ��� �� ��� � �����

  // �������� ������ ���� (� ����������� �� ����������� �����)
  if (not UseKey) then
  begin
    Result := (lua_next(Handle, Index) <> 0);
  end else
  begin
    lua_pushvalue(Handle, -1);
    lua_rawget(Handle, Index);
    Result := (lua_type(Handle, -1) <> LUA_TNIL);

    if (not Result) then lua_settop(Handle, -1 -2);
  end;

  // ������������� � ����������� �� ���������� 
  FIteration := ord(Result);
  Mode := MODES[Result];
end;

function __TLuaPairGetBroken(const Self: TLuaPair; const ReturnAddr: pointer): boolean;
begin
  case (Self.Mode) of
    PAIRS_ITERATING: Result := false;
    PAIRS_BROKEN: Result := true;
  else
    Result := false;
    Self.ThrowNotInitialized(ReturnAddr);
  end;
end;

function TLuaPair.GetBroken: boolean;
asm
  mov edx, [esp]
  jmp __TLuaPairGetBroken
end;

procedure __TLuaPairGetKey(const Self: TLuaPair; var Result: string; const ReturnAddr: pointer);
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: ThrowBroken(ReturnAddr, 'get key');
    PAIRS_ITERATING:
    begin
      if (lua_type(Handle, KeyIndex) = LUA_TSTRING) then
      begin
        lua_to_pascalstring(Result, Handle, KeyIndex);
      end else
      with Lua do
      begin
        stack_luaarg(FBufferArg, KeyIndex, false);
        TForceString(@TLuaArg.ForceString)(FBufferArg, Result);
      end;
    end;
  else
    ThrowNotInitialized(ReturnAddr);
  end;
end;

function TLuaPair.GetKey: string;
asm
  mov ecx, [esp]
  jmp __TLuaPairGetKey
end;


procedure __TLuaPairGetKeyEx(const Self: TLuaPair; var Result: Variant; const ReturnAddr: pointer);
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: ThrowBroken(ReturnAddr, 'get key');
    PAIRS_ITERATING: Lua.stack_variant(Result, KeyIndex);
  else
    ThrowNotInitialized(ReturnAddr);
  end;
end;

function TLuaPair.GetKeyEx: Variant;
asm
  mov ecx, [esp]
  jmp __TLuaPairGetKeyEx
end;

procedure __TLuaPairGetValue(const Self: TLuaPair; var Result: Variant; const ReturnAddr: pointer);
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: ThrowBroken(ReturnAddr, 'get value');
    PAIRS_ITERATING: Lua.stack_variant(Result, ValueIndex);
  else
    ThrowNotInitialized(ReturnAddr);
  end;
end;

function TLuaPair.GetValue: Variant;
asm
  mov ecx, [esp]
  jmp __TLuaPairGetValue
end;

procedure __TLuaPairSetValue(const Self: TLuaPair; const AValue: Variant; const ReturnAddr: pointer);
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: ThrowBroken(ReturnAddr, 'change value');
 PAIRS_ITERATING: begin
                    // <Key, Value>
                    lua_pushvalue(Handle, KeyIndex);
                    if (not Lua.push_variant(AValue)) then ThrowValueType(ReturnAddr, true);

                    // ����������� � KeyValue
                    lua_remove(Handle, ValueIndex);
                    lua_pushvalue(Handle, -1);
                    lua_insert(Handle, ValueIndex);

                    // ������� � �������
                    lua_rawset(Handle, Index);
                  end;
  else
    ThrowNotInitialized(ReturnAddr);
  end;
end;

procedure TLuaPair.SetValue(const AValue: Variant);
asm
  mov ecx, [esp]
  jmp __TLuaPairSetValue
end;

procedure __TLuaPairGetValueEx(const Self: TLuaPair; var Result: TLuaArg; const ReturnAddr: pointer);
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: ThrowBroken(ReturnAddr, 'get value');
    PAIRS_ITERATING: Lua.stack_luaarg(Result, ValueIndex, true);
  else
    ThrowNotInitialized(ReturnAddr);
  end;
end;

function TLuaPair.GetValueEx: TLuaArg;
asm
  mov ecx, [esp]
  jmp __TLuaPairGetValueEx
end;

procedure __TLuaPairSetValueEx(const Self: TLuaPair; const AValue: TLuaArg; const ReturnAddr: pointer);
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: ThrowBroken(ReturnAddr, 'change value');
 PAIRS_ITERATING: begin
                    // <Key, Value>
                    lua_pushvalue(Handle, KeyIndex);
                    if (not Lua.push_luaarg(AValue)) then ThrowValueType(ReturnAddr, true);

                    // ����������� � KeyValue
                    lua_remove(Handle, ValueIndex);
                    lua_pushvalue(Handle, -1);
                    lua_insert(Handle, ValueIndex);

                    // ������� � �������
                    lua_rawset(Handle, Index);
                  end;
  else
    ThrowNotInitialized(ReturnAddr);
  end;
end;

procedure TLuaPair.SetValueEx(const AValue: TLuaArg);
asm
  mov ecx, [esp]
  jmp __TLuaPairSetValueEx
end;

function __TLuaPairNext(var Self: TLuaPair; const ReturnAddr: pointer): boolean;
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: Result := false;
 PAIRS_ITERATING: begin
                    lua_settop(Handle, -1 -1);
                    Result := (lua_next(Handle, Index) <> 0);
                    inc(FIteration);
                    if (not Result) then Mode := PAIRS_BROKEN;
                  end;
  else
    Result := false;
    ThrowNotInitialized(ReturnAddr);
  end;
end;

function TLuaPair.Next(): boolean;
asm
  mov edx, [esp]
  jmp __TLuaPairNext
end;

procedure __TLuaPairBreak(var Self: TLuaPair; const ReturnAddr: pointer);
begin
  with Self do
  case (Mode) of
    PAIRS_BROKEN: ;
 PAIRS_ITERATING: Mode := PAIRS_BROKEN;
  else
    ThrowNotInitialized(ReturnAddr);
  end;
end;

procedure TLuaPair.Break();
asm
  mov edx, [esp]
  jmp __TLuaPairBreak
end;
       *)

          (*
{ TLuaTable }

procedure TLuaTable.ThrowValueType(const CodeAddr: pointer; const pop: boolean);
begin
  if (pop) then Lua.stack_pop();
  ELua.Assert('Unsupported value type = "%s"', [Lua.FBufferArg.str_data], CodeAddr);
end;

// ������������ ������ �������������� �������
function TLuaTable.GetLength: integer;
begin
  GetLength := lua_objlen(Lua.Handle, Index_);
end;

// ���������� ��������� � �������
function TLuaTable.GetCount: integer;
var
  Handle: pointer;
  Index: integer;  
begin
  Result := 0;
  Handle := Lua.Handle;
  Index := Index_;
  if (Index < 0) then Index := lua_gettop(Handle)+1+Index;

  lua_pushnil(Handle);
  while (lua_next(Handle, Index) <> 0) do
  begin
    inc(Result);
    lua_settop(Handle, -1-1);
  end;
end;

function TLuaTable.Pairs(var Pair: TLuaPair): boolean;
begin
  lua_pushnil(Lua.Handle);
  Result := Pair.Initialize(Lua, Index_, false);
end;

function __TLuaTablePairs(const Self: TLuaTable; var Pair: TLuaPair; const FromKey: Variant; const ReturnAddr: pointer): boolean;
begin
  if (not Self.Lua.push_variant(FromKey)) then Self.ThrowValueType(ReturnAddr);
  Result := Pair.Initialize(Self.Lua, Self.Index_, true);
end;

function TLuaTable.Pairs(var Pair: TLuaPair; const FromKey: Variant): boolean;
asm
  push [esp]
  jmp __TLuaTablePairs
end;

procedure __TLuaTableGetValue(const Self: TLuaTable; const AIndex: integer; var Result: Variant; const ReturnAddr: pointer);
begin
  with Self do
  begin
    lua_rawgeti(Lua.Handle, Index_, AIndex);
    if (not Lua.stack_variant(Result, -1)) then ThrowValueType(ReturnAddr, true);
    lua_settop(Lua.Handle, -1-1);
  end;
end;

function  TLuaTable.GetValue(const AIndex: integer): Variant;
asm
  push [esp]
  jmp  __TLuaTableGetValue
end;

procedure __TLuaTableSetValue(const Self: TLuaTable; const AIndex: integer; const NewValue: Variant; const ReturnAddr: pointer);
begin
  if (not Self.Lua.push_variant(NewValue)) then Self.ThrowValueType(ReturnAddr);
  lua_rawseti(Self.Lua.Handle, Self.Index_, AIndex);
end;

procedure TLuaTable.SetValue(const AIndex: integer; const NewValue: Variant);
asm
  push [esp]
  jmp __TLuaTableSetValue
end;

procedure __TLuaTableGetValueEx(const Self: TLuaTable; const AIndex: integer; var Result: TLuaArg; const ReturnAddr: pointer);
begin
  with Self do
  begin
    lua_rawgeti(Lua.Handle, Index_, AIndex);
    if (not Lua.stack_luaarg(Result, -1, false)) then ThrowValueType(ReturnAddr, true);
    lua_settop(Lua.Handle, -1-1);
  end;
end;

function  TLuaTable.GetValueEx(const AIndex: integer): TLuaArg;
asm
  push [esp]
  jmp __TLuaTableGetValueEx
end;

procedure __TLuaTableSetValueEx(const Self: TLuaTable; const AIndex: integer; const NewValue: TLuaArg; const ReturnAddr: pointer);
begin
  if (not Self.Lua.push_luaarg(NewValue)) then Self.ThrowValueType(ReturnAddr);
  lua_rawseti(Self.Lua.Handle, Self.Index_, AIndex);
end;

procedure TLuaTable.SetValueEx(const AIndex: integer; const NewValue: TLuaArg);
asm
  push [esp]
  jmp __TLuaTableSetValueEx
end;

procedure __TLuaTableGetKeyValue(const Self: TLuaTable; const Key: string; var Result: Variant; const ReturnAddr: pointer);
begin
  with Self do
  begin
    lua_push_pascalstring(Lua.Handle, Key);
    lua_rawget(Lua.Handle, Index_);
    if (not Lua.stack_variant(Result, -1)) then ThrowValueType(ReturnAddr, true);
    lua_settop(Lua.Handle, -1-1);
  end;
end;

function  TLuaTable.GetKeyValue(const Key: string): Variant;
asm
  push [esp]
  jmp __TLuaTableGetKeyValue
end;

procedure __TLuaTableSetKeyValue(const Self: TLuaTable; const Key: string; const NewValue: Variant; const ReturnAddr: pointer);
begin
  with Self do
  begin
    lua_push_pascalstring(Lua.Handle, Key);
    if (not Lua.push_variant(NewValue)) then ThrowValueType(ReturnAddr, true);
    lua_rawset(Lua.Handle, Index_);
  end;
end;

procedure TLuaTable.SetKeyValue(const Key: string; const NewValue: Variant);
asm
  push [esp]
  jmp __TLuaTableSetKeyValue
end;

procedure __TLuaTableGetKeyValueEx(const Self: TLuaTable; const Key: Variant; var Result: TLuaArg; const ReturnAddr: pointer);
begin
  with Self do
  begin
    if (not Lua.push_variant(Key)) then ThrowValueType(ReturnAddr);
    lua_rawget(Lua.Handle, Index_);
    if (not Lua.stack_luaarg(Result, -1, false)) then ThrowValueType(ReturnAddr, true);
    lua_settop(Lua.Handle, -1-1);
  end;
end;

function  TLuaTable.GetKeyValueEx(const Key: Variant): TLuaArg;
asm
  push [esp]
  jmp __TLuaTableGetKeyValueEx
end;         

procedure __TLuaTableSetKeyValueEx(const Self: TLuaTable; const Key: Variant; const NewValue: TLuaArg; const ReturnAddr: pointer);
begin
  with Self do
  begin
    if (not Lua.push_variant(Key)) then ThrowValueType(ReturnAddr);
    if (not Lua.push_luaarg(NewValue)) then ThrowValueType(ReturnAddr, true);
    lua_rawset(Lua.Handle, Index_);
  end;
end;

procedure TLuaTable.SetKeyValueEx(const Key: Variant; const NewValue: TLuaArg);
asm
  push [esp]
  jmp __TLuaTableSetKeyValueEx
end;  *)

        (*

{ TLuaReference }

destructor TLuaReference.Destroy;
var
  P, Len: integer;
begin
  if (Locked) then ThrowLocked('destroy reference', nil {����� ����� ��������� ������ ������ �����});

  if (Lua <> nil) then
  with Lua do
  begin
    // �������� �� Lua
    global_free_ref(Index); //luaL_unref(Handle, LUA_REGISTRYINDEX, Index);

    // �������� �� ������
    Len := Length(FReferences);
    P := IntPos(integer(Self), pinteger(FReferences), Len);
    if (P >= 0) then
    begin
      dec(Len);
      if (P <> Len) then FReferences[P] := FReferences[Len];
      SetLength(FReferences, Len);
    end;
  end;

  Lua := nil;
  Index := 0;
  inherited;
end;

// �� ������� ����� ��������� ��������, ������� ���� ������������
procedure TLuaReference.Initialize(const ALua: TLua);
var
  Len: integer;
begin
  Lua := ALua;

  // ������ ������, ��������� ��������
  with Lua do
  if (lua_type(Handle, -1) = LUA_TNIL) then
  begin
    lua_pushboolean(Handle, true);
    global_alloc_ref(Index); //Index := luaL_ref(Handle, LUA_REGISTRYINDEX);
    lua_rawseti(Handle, LUA_REGISTRYINDEX, Index); // nil, ������� ��� � �����
  end else
  begin
    global_alloc_ref(Index); //Index := luaL_ref(Handle, LUA_REGISTRYINDEX);
  end;

  // �������� ���� � ������ Lua.FReferences
  Len := Length(Lua.FReferences);
  SetLength(Lua.FReferences, Len+1);
  Lua.FReferences[Len] := Self;
end;

procedure TLuaReference.ThrowLocked(const Operation: string; const CodeAddr: pointer);
begin
  ELua.Assert('Can''t %s, because the reference is locked by table value', [Operation], CodeAddr);
end;

procedure TLuaReference.ThrowValueType(const CodeAddr: pointer);
begin
  ELua.Assert('Unsupported value type = "%s"', [Lua.FBufferArg.str_data], CodeAddr);
end;

procedure __TLuaReferenceGetValue(const Self: TLuaReference; var Result: Variant; const ReturnAddr: pointer);
begin
  if (Self.Locked) then Self.ThrowLocked('get value', ReturnAddr);

  with Self.Lua do
  begin
    lua_rawgeti(Handle, LUA_REGISTRYINDEX, Self.Index);
    stack_variant(Result, -1);
    lua_settop(Handle, -1-1);
  end;
end;

function  TLuaReference.GetValue(): Variant;
asm
  mov ecx, [esp]
  jmp __TLuaReferenceGetValue
end;

procedure __TLuaReferenceSetValue(const Self: TLuaReference; const NewValue: Variant; const ReturnAddr: pointer);
begin
  with Self do
  begin
    if (Locked) then ThrowLocked('change value', ReturnAddr);
    if (not Lua.push_variant(NewValue)) then ThrowValueType(ReturnAddr);
    lua_rawseti(Lua.Handle, LUA_REGISTRYINDEX, Index);
  end;
end;

procedure TLuaReference.SetValue(const NewValue: Variant);
asm
  mov ecx, [esp]
  jmp __TLuaReferenceSetValue
end;

procedure __TLuaReferenceGetValueEx(const Self: TLuaReference; var Result: TLuaArg; const ReturnAddr: pointer);
begin
  if (Self.Locked) then Self.ThrowLocked('get value', ReturnAddr);
  with Self.Lua do
  begin
    lua_rawgeti(Handle, LUA_REGISTRYINDEX, Self.Index);
    stack_luaarg(Result, -1, false);
    lua_settop(Handle, -1-1);
  end;
end;

function  TLuaReference.GetValueEx(): TLuaArg;
asm
  mov ecx, [esp]
  jmp __TLuaReferenceGetValueEx
end;

procedure __TLuaReferenceSetValueEx(const Self: TLuaReference; const NewValue: TLuaArg; const ReturnAddr: pointer);
begin
  with Self do
  begin
    if (Locked) then ThrowLocked('change value', ReturnAddr);

    // Push
    if (NewValue.LuaType = ltTable) then
    begin
      lua_pushvalue(Lua.Handle, PLuaTable(@NewValue.FLuaType).Index_);
    end else
    if (not Lua.push_luaarg(NewValue)) then ThrowValueType(ReturnAddr);

    // SetValue
    lua_rawseti(Lua.Handle, LUA_REGISTRYINDEX, Index);
  end;
end;

procedure TLuaReference.SetValueEx(const NewValue: TLuaArg);
asm
  mov ecx, [esp]
  jmp __TLuaReferenceSetValueEx
end;
           *)
             (*
function __TLuaReferenceAsTableBegin(const Self: TLuaReference; var Table: PLuaTable; const ReturnAddr: pointer): boolean;
begin
  with Self do
  begin
    if (Locked) then
    ELua.Assert('Can''t lock table value, because the reference is already locked', [], ReturnAddr);

    // ���������� �� ������, ������� ���������
    with Lua do
    begin
      lua_rawgeti(Handle, LUA_REGISTRYINDEX, Index);
      Result := (lua_type(Handle, -1) = LUA_TTABLE);
      if (Result) then
      begin
        Data.Index_ := lua_gettop(Handle);
        Table := @Data;
      end else
      begin
        Table := nil;
        lua_settop(Handle, -1 -1);
      end;
    end;

    // ���� "locked"
    FLocked := Result;
  end;
end;

function TLuaReference.AsTableBegin(var Table: PLuaTable): boolean;
asm
  mov ecx, [esp]
  jmp __TLuaReferenceAsTableBegin
end;

function __TLuaReferenceAsTableEnd(const Self: TLuaReference; var Table: PLuaTable; const ReturnAddr: pointer): boolean;
var
  Delta: integer;
begin
  with Self do
  begin
    Result := (Table <> nil);
    if (not Result) then exit;

    if (not Locked) then
    ELua.Assert('Can''t unlock table value, because the reference is not locked', [], ReturnAddr);

    if (Table <> @Data) then
    ELua.Assert('Can''t unlock table value: incorrect parameter "Table"', [], ReturnAddr);

    // ������� ����������� �����
    Delta := abs(lua_gettop(Lua.Handle)-Data.Index_);
    if (Delta <> 0) then
    ELua.Assert('Can''t unlock table value: lua stack size difference = %d', [Delta], ReturnAddr);

    // �����������
    Table := nil;
    FLocked := false;
    lua_settop(Lua.Handle, -1 -1);
  end;
end;

function TLuaReference.AsTableEnd(var Table: PLuaTable): boolean;
asm
  mov ecx, [esp]
  jmp __TLuaReferenceAsTableEnd
end;
          *)

            (*
{ TLuaRecordInfo }

function TLuaRecordInfo.GetFieldsCount: integer;
begin
  Result := Length(FLua.ClassesInfo[FClassIndex].Properties);
end;

// tpinfo ����� ����:
// - typeinfo(type)
// - PLuaRecordInfo
procedure TLuaRecordInfo.InternalRegField(const FieldName: string; const FieldOffset: integer; const tpinfo: pointer; const CodeAddr: pointer);
type
  TDataBuffer = array[0..sizeof(TLuaPropertyInfo)-1] of byte;
var
  i, j: integer;
  Buffer: TDataBuffer;
begin
  // ������� ?

  // �����������
  FLua.InternalAddProperty(false, @Self, FieldName, tpinfo, false, false,
       pointer(FieldOffset), pointer(FieldOffset), nil, CodeAddr);

  // ���������� ����� �� �����������
  with FLua.ClassesInfo[FClassIndex] do
  for i := 0 to Length(Properties)-2 do
  for j := i+1 to Length(Properties)-1 do
  if (integer(Properties[i].read_mode) > integer(Properties[j].read_mode)) then
  begin
    // swap i <--> j
    Buffer := TDataBuffer(Properties[i]);
    TDataBuffer(Properties[i]) := TDataBuffer(Properties[j]);
    TDataBuffer(Properties[j]) := Buffer;
  end;
end;


procedure __TLuaRecordInfoRegField_1(const Self: TLuaRecordInfo; const FieldName: string;
          const FieldOffset: integer; const tpinfo: pointer; const ReturnAddr: pointer);
begin
  Self.InternalRegField(FieldName, FieldOffset, tpinfo, ReturnAddr);
end;

procedure TLuaRecordInfo.RegField(const FieldName: string; const FieldOffset: integer; const tpinfo: pointer);
asm
  pop ebp
  push [esp]
  jmp __TLuaRecordInfoRegField_1
end;

procedure __TLuaRecordInfoRegField_2(const Self: TLuaRecordInfo; const FieldName: string;
          const FieldPointer: pointer; const tpinfo: pointer; const pRecord: pointer; const ReturnAddr: pointer);
begin
  if (integer(pRecord) > integer(FieldPointer)) then
  ELua.Assert('Illegal parameters using: FieldPointer and pRecord', [ReturnAddr]);

  Self.InternalRegField(FieldName, integer(FieldPointer)-integer(pRecord), tpinfo, ReturnAddr);
end;

procedure TLuaRecordInfo.RegField(const FieldName: string; const FieldPointer: pointer; const tpinfo: pointer; const pRecord: pointer = nil);
asm
  pop ebp
  push [esp]
  jmp __TLuaRecordInfoRegField_2
end;


procedure __TLuaRecordInfoRegProc(const Self: TLuaRecordInfo; const ProcName: string; const Proc: TLuaClassProc;
                                  const ArgsCount: integer; const ReturnAddr: pointer);
begin
  Self.FLua.InternalAddProc(false, @Self, ProcName, ArgsCount, false, TMethod(Proc).Code, ReturnAddr);
end;

procedure TLuaRecordInfo.RegProc(const ProcName: string; const Proc: TLuaClassProc; const ArgsCount: integer=-1);
asm
  pop ebp
  push [esp]
  jmp __TLuaRecordInfoRegProc
end;

procedure TLuaRecordInfo.SetOperators(const Value: TLuaOperators);
begin
  if (FOperators <> Value) then
  begin
    FOperators := Value;
    FLua.FInitialized := false;
  end;  
end;

procedure TLuaRecordInfo.SetOperatorCallback(const Value: TLuaOperatorCallback);
begin
  if (@FOperatorCallback <> @Value) then
  begin
    FOperatorCallback := Value;
    FLua.FInitialized := false;
  end;
end;   *)

         (*
{ TLuaSetInfo }

function TLuaSetInfo.Description(const X: pointer): string;
var
  P1, P2, i: integer;

  procedure Add();
  const
    CHARS: array[boolean] of string = (', ', '..');
  begin
    if (P1 < 0) then exit;
    if (Result <> '') then Result := Result + ', ';
    Result := Result + TypInfo.GetEnumName(FTypeInfo, P1);
    if (P2 <> P1) then Result := Result + CHARS[P2>P1+1] + TypInfo.GetEnumName(FTypeInfo, P2);

    P1 := -1;
    P2 := -1;
  end;
begin
  P1 := -1;
  P2 := -1;

  for i := FLow to FHigh do
  if (SetBitContains(X, i-FCorrection)) then
  begin
    if (P1 < 0) then P1 := i;
    P2 := i;
  end else
  begin
    if (P1 >= 0) then Add();
  end;

  Add();
  Result := '['+Result+']';
end;
         *)
           (*
{ TLuaPropertyInfo }

const
  PROP_NONE_USE = pointer($80000000);
  TMETHOD_CLASS_INDEX = 1;
  TLUA_REFERENCE_CLASS_INDEX = 2;

  MODE_NONE_USE = integer(PROP_NONE_USE);
  MODE_PROC_USE = -1;


function IsTypeInfo_Boolean(const tpinfo: ptypeinfo): boolean;
begin
  Result := (tpinfo <> nil) and
  ((tpinfo = typeinfo(boolean)) or (tpinfo = typeinfo(bytebool)) or
   (tpinfo = typeinfo(wordbool)) or (tpinfo = typeinfo(longbool)) );
end;

function GetOrdinalTypeName(const tpinfo: ptypeinfo): string;
const
  INT_STRS: array[TOrdType] of string = ('shortint', 'byte', 'smallint', 'word', 'integer', 'dword');
var
  TypeData: ptypedata;
begin
  TypeData := GetTypeData(tpinfo);

  case (tpinfo.Kind) of
   tkInteger: Result := INT_STRS[TypeData.OrdType];
   tkEnumeration: if (IsTypeInfo_Boolean(tpinfo)) then
                  begin
                    case (TypeData.OrdType) of
                      otUByte: Result := 'boolean';
                      otSByte: Result := 'ByteBool';
                      otSWord, otUWord: Result := 'WordBool';
                      otSLong, otULong: Result := 'LongBool';
                    end;
                  end
                  else Result := tpinfo.Name;
  else
    Result := '';
  end;
end;


function GetLuaPropertyBase(const Lua: TLua; const Prefix, PropertyName: string; const tpinfo, CodeAddr: pointer; const auto_registrate: boolean=false): TLuaPropertyInfoBase;
var
  ClassIndex: integer;

  procedure ThrowUnknown();
  begin
    ELua.Assert('Can''t register "%s%s" because its type is unknown'#13+
                'typeinfo.Name = %s, typeinfo.Kind = %s',
                [Prefix, PropertyName, ptypeinfo(tpinfo).Name, TypeKindName(ptypeinfo(tpinfo).Kind)], CodeAddr);
  end;
begin
  Result.Information := tpinfo;
  Result.Kind := pkUnknown;
  Result.str_max_len := 0;
  byte(Result.OrdType) := 0;


  // ������������������ ����
  ClassIndex := Lua.internal_class_index(tpinfo);
  if (ClassIndex >= 0) then
  begin
    with Lua.ClassesInfo[ClassIndex] do
    case _ClassKind of
      ckClass: begin
                 ELua.Assert('Can''t register "%s%s", because typeinfo is not correct - %s is defined', [Prefix, PropertyName, _ClassName], CodeAddr);
               end;
     ckRecord: begin
                 Result.Kind := pkRecord;
                 Result.Information := _Class;
               end;

      ckArray: begin
                 Result.Kind := pkArray;
                 Result.Information := _Class;
               end;

        ckSet: begin
                 Result.Kind := pkSet;
                 Result.Information := _Class;
               end;
    end;

    exit;
  end;


  if (tpinfo = typeinfoPointer) then
  begin
    Result.Kind := pkPointer;
    Result.Information := typeinfo(integer);
    exit;
  end;

  if (tpinfo = typeinfoTClass) then
  begin
    Result.Kind := pkClass;
    Result.Information := typeinfo(integer);
    exit;
  end;

  if (tpinfo = typeinfoUniversal) then
  begin
    Result.Kind := pkUniversal;
    Result.Information := typeinfo(TLuaArg);
    exit;
  end;


  if (IsTypeInfo_Boolean(tpinfo)) then
  begin
    Result.Kind := pkBoolean;

    case (GetTypeData(tpinfo).OrdType) of
      otUByte: Result.BoolType := btBoolean;
      otSByte: Result.BoolType := btByteBool;
      otSWord, otUWord: Result.BoolType := btWordBool;
      otSLong, otULong: Result.BoolType := btLongBool;
    end;

    exit;
  end;

  case ptypeinfo(tpinfo).Kind of
 {$ifdef fpc}tkBool: begin
                       Result.Kind := pkBoolean;
                       Result.BoolType := btBoolean; // todo ���������
                     end;
 {$endif}

          tkInteger: begin
                       Result.Kind := pkInteger;
                       Result.OrdType := GetTypeData(tpinfo).OrdType;
                     end;

      tkEnumeration: begin
                       Result.Kind := pkInteger;
                       Result.OrdType := GetTypeData(tpinfo).OrdType; 
                       if (auto_registrate) then Lua.RegEnum(tpinfo);
                     end;

{$ifdef fpc}tkQWord,{$endif}
            tkInt64: Result.Kind := pkInt64;

            tkFloat: begin
                       Result.Kind := pkFloat;
                       Result.FloatType := GetTypeData(tpinfo).FloatType;
                     end;

             tkChar: begin
                       Result.Kind := pkString;
                       Result.StringType := stAnsiChar;
                     end;

            tkWChar: begin
                       Result.Kind := pkString;
                       Result.StringType := stWideChar;
                     end;

           tkString: begin
                       Result.Kind := pkString;
                       Result.StringType := stShortString;
                       Result.str_max_len := GetTypeData(tpinfo).MaxLength;
                     end;

{$ifdef fpc}tkAString,{$endif}                     
          tkLString: begin
                       Result.Kind := pkString;
                       Result.StringType := stAnsiString;
                     end;

          tkWString: begin
                       Result.Kind := pkString;
                       Result.StringType := stWideString;
                     end;

          tkVariant: Result.Kind  := pkVariant;

        tkInterface: Result.Kind  := pkInterface;

            tkClass: Result.Kind  := pkObject;

           tkMethod: begin
                       Result.Kind := pkRecord;
                       Result.Information := Lua.ClassesInfo[TMETHOD_CLASS_INDEX]._Class;
                     end;

           tkRecord, {$ifdef fpc}tkObject,{$endif}
            tkArray,
         tkDynArray: begin
                       // Unregistered difficult type
                     end;

              tkSet: begin
                       // Unregistered difficult type
                       if (auto_registrate) then
                       begin
                         Result.Kind := pkSet;
                         Result.Information := Lua.ClassesInfo[Lua.InternalAddSet(tpinfo, CodeAddr)]._Class;
                       end;
                     end;
  end;

  if (Result.Kind = pkUnknown) then
  ThrowUnknown();
end;


// ���-�� ���� InspectType
function GetLuaItemSize(const Base: TLuaPropertyInfoBase): integer;
begin
  Result := 0;
  if (Base.Information = nil) then exit;

  case Base.Kind of
   pkBoolean: case (Base.BoolType) of
                btBoolean: Result := sizeof(boolean);
                btWordBool: Result := sizeof(wordbool);
                btLongBool: Result := sizeof(longbool);
              end;

   pkInteger: case (Base.OrdType) of
                otSByte, otUByte: Result := sizeof(byte);
                otSWord, otUWord: Result := sizeof(word);
                otSLong, otULong: Result := sizeof(dword);
              end;

     pkFloat: case (Base.FloatType) of
                ftSingle: Result := sizeof(single);
                ftDouble: Result := sizeof(double);
                ftExtended: Result := sizeof(extended);
                ftComp: Result := sizeof(Comp);
                ftCurr: Result := sizeof(Currency);
              end;

    pkString: case (Base.StringType) of
                stShortString: Result := Base.str_max_len+1;

                {todo UnicodeString?,}
                stAnsiString,
                stWideString: Result := sizeof(pointer);

                stAnsiChar: Result := sizeof(AnsiChar);
                stWideChar: Result := sizeof(WideChar);
              end;

   pkVariant: Result := sizeof(Variant);
     pkInt64: Result := sizeof(int64);
    pkObject, pkInterface, pkPointer, pkClass: Result := sizeof(Pointer);
    pkRecord: Result := PLuaRecordInfo(Base.Information).FSize;
     pkArray: Result := PLuaArrayInfo(Base.Information).FSize;
       pkSet: Result := PLuaSetInfo(Base.Information).FSize;

       //pkUniversal? �������� �� ���� - ��� ������ � ��������
  end;          
end;

// ���� �������� ����, ���������� ���������� - �������� �� ��� ��� �������
// ���������� �� ��� ����������������/��������������
function GetLuaDifficultTypeInfo(const Base: TLuaPropertyInfoBase): ptypeinfo;
begin
  Result := nil;

  case Base.Kind of
    pkVariant: Result := typeinfo(Variant);
  pkInterface: Result := typeinfo(IInterface);
     pkRecord: Result := PLuaRecordInfo(Base.Information).FTypeInfo;
      pkArray: Result := PLuaArrayInfo(Base.Information).FTypeInfo;

     pkString: if (Base.StringType in [stAnsiString, stWideString {todo Unicode ?}]) then
               Result := Base.Information;
  end;
end;


// ������� ������������ ��� ������ TypInfo-������� ��� ������ �� ����������, ������ ����� ������� �������
// ��� ������� -��������/-��������/-��������
// ������ ������� �������� �������� � ������ ��� push � ���� Lua (user data)
procedure GetPushDifficultTypeProp(const Lua: TLua; const Instance: pointer; const IsConst: boolean; const Info: TLuaPropertyInfo);
type
  TGetterProc = procedure(const instance: pointer; var Result);
  TSimpleGetterProc = function(const instance: pointer): integer;
  TIndexedGetterProc = procedure(const instance: pointer; const index: integer; var Result);
  TIndexedSimpleGetterProc = function(const instance: pointer; const index: integer): integer;
var
  PValue: pointer;
  Value: dword absolute PValue;
  Data: pointer;
  IsSimple: boolean;
begin

  if (Info.read_mode >= 0) then
  begin
    // ����� ������� ������
    // Instance ��� ��������� �� ���������/������/��������� 
    // � Lua ����� ��������� ������ ��������� (IsRef)
    Data := Instance;
  end else
  begin
    // �������� ����� ������� � �������� � ResultBuffer
    // ������� ������������ � �������
    PValue := Info.PropInfo.GetProc;
    if (Value >= $FE000000) then PValue := pointer(pointer(dword(Instance^) + (Value and $00FFFFFF))^);

    // ��������� �� ������ � ������� �������� ���������� (��� � eax)
    case (Info.Base.Kind) of
      pkRecord: begin
                  Data := Lua.FResultBuffer.AllocRecord(PLuaRecordInfo(Info.Base.Information));

                  with PLuaRecordInfo(Info.Base.Information)^ do
                  IsSimple := (FSize <= 4{��� ���� single?}) and (FTypeInfo = nil);
                end;
       pkArray: begin
                  Data := Lua.FResultBuffer.AllocArray(PLuaArrayInfo(Info.Base.Information));

                  with PLuaArrayInfo(Info.Base.Information)^ do
                  IsSimple := (FSize <= 4) and (FTypeInfo = nil);
                end;
    else
      Data := Lua.FResultBuffer.AllocSet(PLuaSetInfo(Info.Base.Information));

      with PLuaSetInfo(Info.Base.Information)^ do
      IsSimple := (FSize <= 4);
    end;

    // �������� ������ �� �������
    // "� eax" ��� � ���������
    with Info.PropInfo^ do
    if (IsSimple) then
    begin
      if (Index = integer(PROP_NONE_USE)) then
        integer(Data^) := TSimpleGetterProc(PValue)(instance)
      else
        integer(Data^) := TIndexedSimpleGetterProc(PValue)(instance, Index);
    end else
    begin
      if (Index = integer(PROP_NONE_USE)) then
        TGetterProc(PValue)(Instance, Data^)
      else
        TIndexedGetterProc(PValue)(Instance, Index, Data^);
    end;
  end;


  {  �����������  }

  // TMethod
  if (Info.Base.Kind = pkRecord) and (PLuaRecordInfo(Info.Base.Information).FClassIndex = TMETHOD_CLASS_INDEX)
  and (pint64(Instance)^ = 0) then
  begin
    lua_pushnil(Lua.Handle);
    exit;
  end;

  // push-�� ��������
  Value := PLuaRecordInfo(Info.Base.Information).FClassIndex; // FClassIndex � ���� �� ������ ��������!!!
  Lua.push_userdata(Lua.ClassesInfo[Value], (Info.read_mode < 0), Data).is_const := IsConst;
end;

// ���������� ������� ���������� ��� ������ TypInfo-������� ��� ������ �� �������� ����������:
// ���������, �������, ���������
//
// ������ ������� ���� �������� �� ����� � ����������� "��������" 
function PopSetDifficultTypeProp(const Lua: TLua; const instance: pointer; const stack_index: integer; const Info: TLuaPropertyInfo): boolean;
type
  TSetterProc = procedure(const instance: pointer; const Value: integer);
  TIndexedSetterProc = procedure(const instance: pointer; const Index, Value: integer);
var
  userdata: PLuaUserData;

  PValue: pointer;
  ProcValue: integer; // Value � �������
  luatype: integer absolute ProcValue;

  // ������ ��� ����������� � ���������
  DataSize: integer;
  SimpleType: boolean;
  ItemTypeInfo: ptypeinfo;
  ItemsCount: integer;
begin
  Result := false;

  // ������������ � userdata, ����� Clear(userdata=nil) � Result
  userdata := nil;
  luatype := lua_type(Lua.Handle, stack_index);
  case luatype of
         LUA_TNIL: {������ �� ������ - ����� Clear};
    LUA_TUSERDATA: begin
                     userdata := lua_touserdata(Lua.Handle, stack_index);

                     if (userdata = nil) or (userdata.instance = nil) or
                        (byte(userdata.kind) > byte(ukSet)) then
                     begin
                       GetUserDataType(Lua.FBufferArg.str_data, Lua, userdata);
                       exit;
                     end;
                   end;
  else
    Lua.FBufferArg.str_data := LuaTypeName(luatype);
    exit;
  end;

  
  // ����� ���������� � ������� ������������� (���� ���� userdata)
  case Info.Base.Kind of
    pkRecord: begin
                with PLuaRecordInfo(Info.Base.Information)^ do
                begin
                  DataSize := FSize;
                  ItemTypeInfo := FTypeInfo;
                  SimpleType := (ItemTypeInfo = nil);
                  ItemsCount := 1;
                end;

                if (userdata <> nil) then
                with userdata^ do
                if (kind <> ukInstance) or (Lua.ClassesInfo[ClassIndex]._Class <> Info.Base.Information) then
                begin
                  GetUserDataType(Lua.FBufferArg.str_data, Lua, userdata);
                  exit;
                end;
              end;

     pkArray: begin
                with PLuaArrayInfo(Info.Base.Information)^ do
                begin
                  DataSize := FSize;
                  ItemTypeInfo := FTypeInfo;
                  SimpleType := (ItemTypeInfo = nil);
                  ItemsCount := FItemsCount;
                end;

                if (userdata <> nil) then
                with userdata^ do
                if (kind <> ukArray) or (ArrayInfo <> Info.Base.Information) then
                begin
                  GetUserDataType(Lua.FBufferArg.str_data, Lua, userdata);
                  exit;
                end;
              end;

       pkSet: begin
                DataSize := PLuaSetInfo(Info.Base.Information).FSize;
                ItemTypeInfo := nil;
                SimpleType := true;
                ItemsCount := 1;

                if (userdata <> nil) then
                with userdata^ do
                if (kind <> ukSet) or (SetInfo <> Info.Base.Information) then
                begin
                  GetUserDataType(Lua.FBufferArg.str_data, Lua, userdata);
                  exit;
                end;
              end;
  else
    Lua.FBufferArg.str_data := 'unknown property?';
    exit; // warnings off            
  end;


  { -- ���� userdata nil - ��� ����� ��������� ���������� -- }
  Result := true; // ���� ������ ����� - ������ �� ���������

  if (Info.write_mode >= 0) then
  begin
    // ������� �����, ��� instance ��������� �� ����������
    if (userdata = nil {ClearMode}) then
    begin
      if (not SimpleType) then Finalize(instance, ItemTypeInfo, ItemsCount);
      FillChar(instance^, DataSize, #0);
    end else
    begin
      if (SimpleType) then Move(userdata.instance^, instance^, DataSize)
      else CopyArray(instance, userdata.instance, ItemTypeInfo, ItemsCount);
    end;
  end else
  begin
    // ������� �����, ��� ����� ��������� �� �������
    PValue := Info.PropInfo.SetProc;
    if (dword(PValue) >= $FE000000) then PValue := pointer(pointer(dword(Instance^) + dword(PValue) and $00FFFFFF)^);

    // �������� �������
    if (userdata = nil {ClearMode}) then
    begin
      if (DataSize <= 4) then ProcValue := 0
      else
      // ������������ �������������� ResultBuffer.Memory
      with Lua.ResultBuffer do
      begin
        if (tpinfo <> nil) then Finalize();
        if (Size < DataSize) then
        begin
          Size := (DataSize+3) and (not 3);
          ReallocMem(Memory, Size);
        end;
        FillChar(Memory^, DataSize, #0);
        ProcValue := integer(Memory);
      end;
    end else
    begin
      ProcValue := integer(userdata.instance);

      case (DataSize) of
        1: ProcValue := pbyte(ProcValue)^;
        2: ProcValue := pword(ProcValue)^;
        3: ProcValue := integer(pword(ProcValue)^) or (ord(pansichar(ProcValue)[2]) shl 16);
        4: ProcValue := pinteger(ProcValue)^;
      end;
    end;

    // ��������� (������� ������)
    with Info.PropInfo^ do
    if (Index = integer(PROP_NONE_USE)) then TSetterProc(PValue)(instance, ProcValue)
    else TIndexedSetterProc(PValue)(instance, Index, ProcValue);
  end;
end;


// ����������� ������ ��� ������������� �������
//
// ������������� �������� ���������� ���, ��� ���������� TLuaArg
// � ����� ���� �������� PropertyName � �������
procedure GetPushUniversalTypeProp(const Lua: TLua; Instance: pointer; const IsConst: boolean; const Info: TLuaPropertyInfo);
type
  TGetterProc = procedure(const instance: pointer; const PropertyName: string; var Result: TLuaArg);
  TIndexedGetterProc = procedure(const instance: pointer; const PropertyName: string; const index: integer; var Result: TLuaArg);

var
  PValue: pointer;
begin
  if (Info.read_mode >= 0) then
  begin
    // ���������������� ���������
    // ������ �� ������
  end else
  begin
    // ����� �������
    PValue := Info.PropInfo.GetProc;
    if (dword(PValue) >= $FE000000) then PValue := pointer(pointer(dword(Instance^) + dword(PValue) and $00FFFFFF)^);

    // �������� ������ �� �������
    with Info.PropInfo^ do
    begin
      if (Index = integer(PROP_NONE_USE)) then
        TGetterProc(PValue)(Instance, Info.PropertyName, Lua.FBufferArg)
      else
        TIndexedGetterProc(PValue)(Instance, Info.PropertyName, Index, Lua.FBufferArg);
    end;

    Instance := @Lua.FBufferArg;
  end;

  // ���-�� ��������
  // ���� ��� ����� ����������, ��� �������� �� �������
  // �� ����� nil (���� � �� ����������� �������� ����� push ����� �� ����������)
  if (not Lua.push_luaarg(PLuaArg(Instance)^)) then
  begin
    lua_pushnil(Lua.Handle);
  end;
end;

// �������� ������������� �������� (����� TLuaArg)
function PopSetUniversalTypeProp(const Lua: TLua; const instance: pointer; const stack_index: integer; const Info: TLuaPropertyInfo): boolean;
type
  TSetterProc = procedure(const instance: pointer; const PropertyName: string; const Value: TLuaArg);
  TIndexedSetterProc = procedure(const instance: pointer; const PropertyName: string; const index: integer; const Value: TLuaArg);

var
  PValue: pointer;
begin
  if (Info.write_mode >= 0) then
  begin
    Result := Lua.stack_luaarg(PLuaArg(instance)^, stack_index, false{?});
  end else
  begin
    // ����� �������
    PValue := Info.PropInfo.SetProc;
    if (dword(PValue) >= $FE000000) then PValue := pointer(pointer(dword(Instance^) + dword(PValue) and $00FFFFFF)^);

    // �������� ��������
    Result := Lua.stack_luaarg(Lua.FBufferArg, stack_index, false{?});

    // ������� ������ ������ �� �������
    with Info.PropInfo^ do
    begin
      if (Index = integer(PROP_NONE_USE)) then
        TSetterProc(PValue)(Instance, Info.PropertyName, Lua.FBufferArg)
      else
        TIndexedSetterProc(PValue)(Instance, Info.PropertyName, Index, Lua.FBufferArg);
    end;
  end;
end;



function VMTMethodsCount(const AClass: TClass): integer;
{$ifdef fpc}
const
  vmtSelfPtr = 0; {TODO !!!}
{$endif}
asm
        PUSH    EBX
        MOV     ECX, 8
        MOV     EBX, -1
        MOV     EDX, vmtSelfPtr
@@cycle:
        ADD     EDX, 4
        CMP     [EAX + EDX], EAX
        JE      @@vmt_not_found
        JB      @@continue
        CMP     [EAX + EDX], EBX
        JAE     @@continue
        MOV     EBX, [EAX + EDX]
@@continue:
        DEC     ECX
        JNZ     @@cycle
        SUB     EBX, EAX
        SHR     EBX, 2
        MOV     EAX, EBX
        JMP     @@exit
@@vmt_not_found:
        XOR     EAX, EAX
@@exit:
        POP     EBX
end;          *)
                (*
// ��������� ��������� �� ������� TypInfo
procedure PackPointer(const ClassInfo: TLuaClassInfo; var Dest: pointer; const P: pointer);
var
  VmtIndex: integer;
begin
  if (ClassInfo._Class = GLOBAL_NAME_SPACE) then
  begin
    // � global_name_space ������ �������� ������ ���������
    integer(Dest) := integer(P);
  end else
  if (ClassInfo._ClassKind <> ckClass) then
  begin
    // ���������
    integer(Dest) := integer($FF000000) or integer(P);
  end else
  begin
    // �����
    if (P = nil) then exit;
    if (integer(P) < TClass(ClassInfo._Class).InstanceSize) then
    begin
      integer(Dest) := integer($FF000000) or integer(P);
    end else
    begin
      VmtIndex := IntPos(integer(P), PInteger(ClassInfo._Class), VMTMethodsCount(ClassInfo._Class));

      if (VmtIndex < 0) then Dest := P
      else integer(Dest) := integer($FE000000) or VmtIndex*4;
    end;
  end;
end;

// ���������� "�����" ������ ��� ������ �� ��������� �� �������
// � ������� ����� �� ��������� �� ���������� ����������
function PropMode(const P: pointer): integer;
var
  Value: dword absolute P;
begin
  if (P = PROP_NONE_USE) then Result := MODE_NONE_USE
  else
  if (Value and $FF000000 = $FF000000) then Result := Value and $00FFFFFF // ��������
  else
  Result := MODE_PROC_USE;
end;
         *)
           (*
     *)


                                     (*
// ���������� ������������ ������ - PropInfo �
procedure TLuaPropertyInfo.Cleanup();
begin
  if (not IsRTTI) and (PropInfo <> nil) then
  begin
    FreeMem(PropInfo);
    PropInfo := nil;
  end;

  PropertyName := '';
end;


// ���������� ���������� ����������� �� PropInfo, ��������� RTTI
procedure TLuaPropertyInfo.Fill(const RTTIPropInfo: PPropInfo; const PropBase: TLuaPropertyInfoBase);
begin
  if (Self.IsRTTI) and (Self.PropInfo = RTTIPropInfo) then exit;

  // �������� ����������� propinfo
  if (IsRTTI) then PropInfo := nil;
  if (PropInfo <> nil) then
  begin
    FreeMem(PropInfo);
    PropInfo := nil;
  end;

  // ������� ����� ���������
  Self.IsRTTI := true;
  Self.Base := PropBase;
  Self.Parameters := nil;
  Self.PropInfo := RTTIPropInfo;

  // ������ ������-������
  read_mode := PropMode(PropInfo.GetProc);
  write_mode := PropMode(PropInfo.SetProc);
end;


// ������������ �������, ��������� PropInfo (���� �����)
// � ����������� ��� ����������� ����
procedure TLuaPropertyInfo.Fill(const class_info; const PropBase: TLuaPropertyInfoBase;
                                const PGet, PSet: pointer; const AParameters: PLuaRecordInfo);
var
  ClassInfo: TLuaClassInfo absolute class_info;
  Len: integer;

  _GetProc, _SetProc: pointer;
  _read_mode, _write_mode: integer;
begin
  // �������� ����������� propinfo ���� ��������� �� ���������
  if (IsRTTI) then PropInfo := nil;

  // ������������� �����, ������� ����� ����
  // �������� �� ������ ������������ ��� ������������ ����������
  if (ClassInfo._Class = GLOBAL_NAME_SPACE) then
  begin
    _read_mode := integer(PGet);
    _write_mode := _read_mode;
    _GetProc := PROP_NONE_USE;
    _SetProc := PROP_NONE_USE;

    if (Self.Base.Information = PropBase.Information) and
       (Self.Parameters = AParameters) and (_read_mode = Self.read_mode) then exit;
  end else
  begin
    _GetProc := PROP_NONE_USE;
    _SetProc := PROP_NONE_USE;
    PackPointer(ClassInfo, _GetProc, PGet);
    PackPointer(ClassInfo, _SetProc, PSet);
    _read_mode := PropMode(_GetProc);
    _write_mode := PropMode(_SetProc);
    if (_read_mode >= 0) then _GetProc := PROP_NONE_USE;
    if (_write_mode >= 0) then _SetProc := PROP_NONE_USE;

    if (Self.Base.Information = PropBase.Information) and (Self.Parameters = AParameters) and
       (_read_mode = Self.read_mode) and (_write_mode = Self.write_mode) then
    begin
      // �������� �������
      if ((_GetProc <> PROP_NONE_USE) or (_SetProc <> PROP_NONE_USE)) = (PropInfo = nil) then
      begin
        if (PropInfo = nil) then exit;
        if (PropInfo.GetProc = _GetProc) and (PropInfo.SetProc = _SetProc) then exit;
      end;
    end;
  end;

  // �������� ������ PropInfo(���� �����)
  if (PropInfo <> nil) then
  begin
    FreeMem(PropInfo);
    PropInfo := nil;
  end;

  // ���������� ������� �����
  Self.IsRTTI := false;
  Self.Base := PropBase;
  Self.Parameters := AParameters;
  Self.read_mode := _read_mode;
  Self.write_mode := _write_mode; 

  // �������� ������ PPropInfo (���� �����)
  if (_GetProc <> PROP_NONE_USE) or (_SetProc <> PROP_NONE_USE) then
  begin
    Len := sizeof(TPropInfo) - sizeof({TPropInfo.Name}ShortString) + 1 + Length(PropertyName) + 4;
    GetMem(PropInfo, Len);
    ZeroMemory(PropInfo, Len);

    PropInfo.Name := PropertyName;
    PropInfo.PropType := pointer(integer(PropInfo)+Len-4);
    PropInfo.PropType{$ifndef fpc}^{$endif} := PropBase.Information;
    PropInfo.GetProc := _GetProc;
    PropInfo.SetProc := _SetProc;
    PropInfo.StoredProc := PROP_NONE_USE;
    PropInfo.Index := integer(PROP_NONE_USE);
  end;
end;


function TLuaPropertyInfo.Description(): string;
const
  BOOL_STRS: array[TLuaPropBoolType] of string = ('boolean', 'ByteBool', 'WordBool', 'LongBool');
  FLOAT_STRS: array[TFloatType] of string = ('single', 'double', 'extended', 'Comp', 'currency');
  STRING_STRS: array[TLuaPropStringType] of string = ('string[%d]', 'AnsiString', 'WideString', {todo UnicodeString?,} 'AnsiChar', 'WideChar');
var
  i: integer;
  params, typename: string;
  Readable, Writable: boolean;
begin
  Result := PropertyName;

  // ������ ����������
  params := '';
  if (Parameters <> nil) then
  begin
    if (Parameters = INDEXED_PROPERTY) then params := 'index'
    else if (Parameters = NAMED_PROPERTY) then params := 'name'
    else
    with PLuaRecordInfo(Parameters).FLua.ClassesInfo[PLuaRecordInfo(Parameters).FClassIndex] do
    for i := 0 to Length(Properties)-1 do
    begin
      if (i <> 0) then params := params + ', ';
      params := params + Properties[i].PropertyName;
    end;
  end;
  if (params <> '') then Result := Result + '[' + params + ']';

  // ��� ����
  case Base.Kind of
    pkUnknown: typename := 'ERROR';
  pkUniversal: typename := 'unknown';
    pkBoolean: typename := BOOL_STRS[Base.BoolType];
      pkInt64: typename := 'int64';
      pkFloat: typename := FLOAT_STRS[Base.FloatType];
     pkObject: typename := 'TObject';
     pkString: begin
                 typename := STRING_STRS[Base.StringType];
                 if (Base.StringType = stShortString) then typename := Format(typename, [Base.str_max_len]);
               end;
    pkVariant: typename := 'variant';
  pkInterface: typename := 'IInterface';
    pkPointer: typename := 'pointer';
      pkClass: typename := 'TClass';
      pkArray: typename := PLuaArrayInfo(Base.Information).Name;
        pkSet: typename := PLuaSetInfo(Base.Information).Name;
     pkRecord: with PLuaRecordInfo(Base.Information)^ do
               if (FClassIndex = TMETHOD_CLASS_INDEX) then typename := 'Event' else typename := Name;
  else
     // pkInteger {Enum}
     typename := GetOrdinalTypeName(PropInfo.PropType^);
  end;


  // �����������
  begin
    Readable := (read_mode <> MODE_NONE_USE);
    Writable := (write_mode <> MODE_NONE_USE);
    Result := Result + ': ' + typename + ' ';

    if (Readable and Writable) then Result := Result + 'R/W'
    else
    if (Readable) then Result := Result + 'R'
    else Result := Result + 'W';
  end;
end;   *)


{ TLuaClassInfo }
                 (*
// ���������� ������. ������������� (��� �������) ��� ������������� (��� �������)
function TLuaClassInfo.InternalAddName(const Name: string; const AsProc: boolean; var Initialized: boolean; const CodeAddr: pointer): integer;
const
  PROC_STR: array[boolean] of string = ('Property', 'Procedure');
var
  AHash: integer;

  function GetNamePos(): integer;
  label
    Done;
  var
    Len, Index: integer;
  begin
    Index := 0;
    // Result := InsortedPos8(AHash, Names);
    // if (Result < 0) then exit;
    Len := Length(Names);
    Result := InsortedPlace8(AHash, pointer(Names), Len);
    
    while (Result < Len) and (AHash = Names[Result].Hash) do
    begin
      Index := Names[Result].Index;

      if (Index >= 0) then
      begin
        if (SameStrings(Name, Procs[Index].ProcName)) then goto Done;
      end else
      begin
        if (SameStrings(Name, Properties[{InvertIndex} not (Index)].PropertyName)) then goto Done;
      end;

      inc(Result);
    end;

    Result := -1;
    exit;
  Done:
    // ��������� ������. �������� ���������������� ��������� � ����� �� ������, ��� ��������
    // ��� ��������
    if (AsProc <> (Index >= 0)) then
    ELua.Assert('%s with name "%s" is already contains in %s. That is why you can''t add a %s with a same name',
               [PROC_STR[not AsProc], Name, _ClassName, PROC_STR[AsProc]], CodeAddr);
  end;

begin
  // ����� � ������ ���
  AHash := StringHash(Name);
  Result := GetNamePos();
  if (Result >= 0) then
  begin
    Result := Names[Result].Index; // ������ ������������� �� ����, �� ��� ����������
    exit;
  end;
  Initialized := false;


  // ���������� �����
  if (AsProc) then
  begin
    Result := Length(Procs);
    SetLength(Procs, Result+1);
    ZeroMemory(@Procs[Result], sizeof(TLuaProcInfo));
    Procs[Result].ProcName := Name;
    Procs[Result].ArgsCount := -1;
  end else
  begin
    Result := Length(Properties);
    SetLength(Properties, Result+1);
    ZeroMemory(@Properties[Result], sizeof(TLuaPropertyInfo));
    Properties[Result].PropertyName := Name;
    Result := {InvertIndex} not (Result);
  end;

  // �������� � ������ Names
  with TLuaHashIndex(DynArrayInsert(Names, typeinfo(TLuaHashIndexDynArray), InsortedPlace8(AHash, pointer(Names), Length(Names)))^) do
  begin
    Hash := AHash;
    Index := Result;
  end;
end;    *)
                        (*
// ������� ����� �������� (� ������� "������")
// ������� ��� � �������� ��� ������� ��������
procedure FastFindProperty(const Properties: TLuaPropertyInfoDynArray; const Name: pchar; const NameLength: integer; var PropertyInfo: pointer);
const
  PROPERTY_SIZE = sizeof(TLuaPropertyInfo);
asm
  test eax, eax
  jz @ret
  push edi // ������� Length(Properties)
  push esi // ������������ ������
  push ebx // ����� ��� ���������
  push ebp // �������������� ������ ��� �������� NameLength

  mov edi, [eax-4]
  {$ifdef fpc} inc edi {$endif}
  mov ebp, ecx
@property_loop:
  mov esi, [eax + TLuaPropertyInfo.PropertyName]
  cmp ecx, [esi-4]
  jne @property_next

  { ��������� ������ esi � edx. ������ = ecx }
     jmp @1
     @loop_byte:
       dec ecx
       mov bl, [esi+ecx]
       cmp bl, [edx+ecx]
       jne @exit_compare
     @1:test ecx, 3
     jnz @loop_byte

     shr ecx, 2
     jz  @exit // ���� ������ �������

     @loop_dword:
       mov ebx, [esi + ecx*4 - 4]
       cmp ebx, [edx + ecx*4 - 4]
       jne @exit_compare
     dec ecx
     jnz @loop_dword
     jmp @exit // ���� ������ �������

     // ������ �� �����, "�����"
     @exit_compare: mov ecx, ebp
  { <-- ��������� ������ esi � edx }
@property_next:
  add eax, PROPERTY_SIZE
  dec edi
  jnz @property_loop
  xor eax, eax // ���� �� ������
@exit:
  pop ebp
  pop ebx
  pop esi
  pop edi
@ret:
  mov edx, PropertyInfo
  mov [edx], eax
end;
           *)            (*
// ����� ������ � ������ ���������� ���
function TLuaClassInfo.NameSpacePlace(const Lua: TLua; const Name: pchar; const NameLength: integer; var ProcInfo, PropertyInfo: pointer): integer;
var
  Len, Value: integer;
  NameHash: integer;
  ClassInfo: ^TLuaClassInfo;
  HashInfo: ^TLuaHashIndex;
begin
  if (_ClassSimple) then
  begin                           
    ProcInfo := nil;
    FastFindProperty(Properties, Name, NameLength, PropertyInfo);
    Result := 0; { ��������� ����� ������ � AddToNameSpace(), �� �� ��� ������ ���� _ClassSimple �������� }
    exit;
  end;

  NameHash := StringHash(Name, NameLength);
  Len := Length(NameSpace);
  Result := InsortedPlace8(NameHash, pointer(NameSpace), Len);

  HashInfo := pointer(integer(NameSpace) + Result*sizeof(TLuaHashIndex));
  while (Result < Len) and (HashInfo.Hash = NameHash) do
  begin
    Value := HashInfo.Index;
    ClassInfo := @Lua.ClassesInfo[word(Value)];

    if (Value >= 0) then
    begin
      ProcInfo := @ClassInfo.Procs[Value shr 16];

      if (SameStrings(PLuaProcInfo(ProcInfo).ProcName, Name, NameLength)) then
      begin
        PropertyInfo := nil;
        exit;
      end;
    end else
    begin
      PropertyInfo := @ClassInfo.Properties[not smallint(Value shr 16)];

      if (SameStrings(PLuaPropertyInfo(PropertyInfo).PropertyName, Name, NameLength)) then
      begin
        ProcInfo := nil;
        exit;
      end;
    end;               

    inc(Result);
    inc(HashInfo);
  end;

  ProcInfo := nil;
  PropertyInfo := nil;
end;

function  TLuaClassInfo.PropertyIdentifier(const Name: string = ''): string;
var
  S: string;
begin
  if (_Class = GLOBAL_NAME_SPACE) then Result := 'global variable'
  else
  if (_ClassKind <> ckClass) then Result := 'field'
  else
  Result := 'property';

  // ������ �������
  if (Name <> '') then
  begin
    if (_Class = GLOBAL_NAME_SPACE) then S := Format(' "%s"', [Name])
    else S := Format(' %s.%s', [_ClassName, Name]);

    Result := Result + S;
  end;
end;

procedure TLuaClassInfo.Cleanup();
var
  i: integer;
begin
  // �������� ���������� �� �����
  if (TClass(_Class) <> GLOBAL_NAME_SPACE) then
  case _ClassKind of
    ckRecord: Dispose(PLuaRecordInfo(_Class));
       ckSet: Dispose(PLuaSetInfo(_Class));
     ckArray: begin
                TLuaPropertyInfo(PLuaArrayInfo(_Class).ItemInfo).Cleanup();
                Dispose(PLuaArrayInfo(_Class));
              end;
  end;

  // ���������� ������������� PPropInfo � ���������
  for i := 0 to Length(Properties)-1 do
  Properties[i].Cleanup();

  Names := nil;
  NameSpace := nil;
  Procs := nil;
  Properties := nil;
  _ClassName := '';
end;          *)


{ TLuaResultBuffer }
                                  (*
procedure TLuaResultBuffer.Finalize(const free_mem: boolean=false);
begin
  if (tpinfo <> nil) then
  begin
    {$ifdef NO_CRYSTAL}
      CrystalLUA.Finalize(Memory, tpinfo, items_count);
    {$else}
      SysUtilsEx.Finalize(Memory, tpinfo, items_count);
    {$endif}

    tpinfo := nil;
  end;

  if (free_mem) and (Memory <> nil) then
  begin
    FreeMem(Memory);
    Memory := nil;
    Size := 0;    
  end;
end;

function  TLuaResultBuffer.AllocRecord(const RecordInfo: PLuaRecordInfo): pointer;
var
  NewSize: integer;
begin
  if (tpinfo <> nil) then Finalize();

  if (RecordInfo = nil) then
  begin
    AllocRecord := nil;
    exit;
  end;

  NewSize := (RecordInfo.FSize+3) and (not 3);
  if (NewSize > Size) then
  begin
    Size := NewSize;
    ReallocMem(Memory, Size);
  end;

  tpinfo := RecordInfo.FTypeInfo;
  items_count := 1;
  FillDword(Memory^, NewSize shr 2, 0); // ZeroMemory

  AllocRecord := Memory;
end;

function TLuaResultBuffer.AllocArray(const ArrayInfo: PLuaArrayInfo): pointer;
var
  NewSize: integer;
begin
  if (tpinfo <> nil) then Finalize();

  if (ArrayInfo = nil) then
  begin
    AllocArray := nil;
    exit;
  end;

  NewSize := (ArrayInfo.FSize+3) and (not 3);
  if (NewSize > Size) then
  begin
    Size := NewSize;
    ReallocMem(Memory, Size);
  end;

  tpinfo := ArrayInfo.FTypeInfo;
  items_count := ArrayInfo.FItemsCount;

  if (NewSize = 4) then PInteger(Memory)^ := 0
  else FillDword(Memory^, NewSize shr 2, 0); // ZeroMemory

  AllocArray := Memory;
end;

function TLuaResultBuffer.AllocSet(const SetInfo: PLuaSetInfo): pointer;
var
  NewSize: integer;
begin
  if (tpinfo <> nil) then Finalize();

  if (SetInfo = nil) then
  begin
    AllocSet := nil;
    exit;
  end;

  NewSize := (SetInfo.FSize+3) and (not 3);
  if (NewSize > Size) then
  begin
    Size := NewSize;
    ReallocMem(Memory, Size);
  end;

  if (NewSize = 4) then PInteger(Memory)^ := 0
  else FillDword(Memory^, NewSize shr 2, 0); // ZeroMemory

  AllocSet := Memory;
end;       *)


{ TLua }
                             (*
// ������ �������. ����� ������� lua.dll
function __TLuaGetProcAddress(const Self: TClass; const ProcName: pchar;
         const throw_exception: boolean; const ReturnAddr: pointer): pointer;
begin
  if (LoadLuaLibrary = 0) and (throw_exception) then
  ELua.Assert('Lua library not found'#13'"%s"', [LuaPath], ReturnAddr);

  // ��������� �������
  if (LuaLibrary = 0) then Result := nil
  else Result := {$ifdef NO_CRYSTAL}Windows{$else}SysUtilsEx{$endif}.GetProcAddress(LuaLibrary, ProcName);

  // ���� �� �������
  if (Result = nil) and (throw_exception) then
  ELua.Assert('Proc "%s" not found in library'#13'"%s"', [ProcName, LuaPath], ReturnAddr);
end;

class function TLua.GetProcAddress(const ProcName: pchar; const throw_exception: boolean = false): pointer;
asm
  push [esp]
  jmp __TLuaGetProcAddress
end;
                       *)
                           (*
procedure TMethodConstructor(var X; const Args: TLuaArgs);
var
  M: TMethod absolute X;
  i: integer;
begin
  for i := 0 to Length(Args)-1 do
  case i of
    0: M.Code := Args[0].ForcePointer;
    1: M.Data := Args[1].ForcePointer;
  else
    exit;
  end;
end;

const
  SIGNS: array[boolean] of integer = (-1, 1);

// ���������� ������ ��������� �� ���������
// ������������ �� �������� � TPoint
procedure TMethodOperator(var _Result, _X1, _X2; const Kind: TLuaOperator);
var
  Result: integer absolute _Result;
  P1: TPoint absolute _X1;
  P2: TPoint absolute _X2;
begin
  if (P1.X <> P2.X) then Result := SIGNS[P1.X > P2.X]
  else
  if (P1.Y <> P2.Y) then Result := SIGNS[P1.Y > P2.Y]
  else
  Result := 0;
end;  
                *)

constructor TLua.Create();
var
  i: Integer;
begin
  if (not InitializeLua) then
    raise ELua.CreateFmt('Lua library was not initialized:'#13'"%s"', [LuaPath]);



  (*

  FHandle := lua_open();
  luaL_openlibs(Handle);

  // ���� �������������� (������ '.' �� ':')
  FPreprocess := true;   *)

  // unicode
  for i := 0 to 127 do
  begin
    FUnicodeTable[i] := i;
    FUTF8Table[i] := i + $01000;
  end;
  SetCodePage(0);

  (*
  // ����������� ��� ������� �������
  mt_properties := internal_register_metatable(nil);

  // ������� ������������� ����������� ������������
  internal_add_class_info(TRUE);
  GlobalNative._Class := GLOBAL_NAME_SPACE;
  GlobalNative._ClassName := 'GLOBAL_NAME_SPACE';
  GlobalNative.Ref := internal_register_metatable(nil, '', -1, TRUE);

  // TObject
  InternalAddClass(TObject, false, nil);

  // TMethod: ��������� ��� �������� �������
  with RegRecord('TMethod', pointer(sizeof(TMethod)))^, TMethod(nil^) do
  begin
    RegField('Code', @Code, typeinfoPointer);
    RegField('Data', @Data, typeinfoPointer);
    RegProc(LUA_CONSTRUCTOR, LuaClassProc(TMethodConstructor));
    Operators := [loCompare];
    OperatorCallback := TMethodOperator;
  end;

  // TLuaReference
  InternalAddClass(TLuaReference, false, nil);   *)
end;
               (*
// ����������
destructor TLua.Destroy();
var
  i: integer;
begin
  // ���������� ������
  FArgs := nil;
  if (FHandle <> nil) then lua_close(FHandle);
  FResultBuffer.Finalize(true);
  DeleteCFunctionDumps(Self);

  // ������ ������
  for i := 0 to Length(FReferences)-1 do FReferences[i].FreeInstance();
  FReferences := nil;

  // ���������� ������
  GlobalNative.Cleanup();
  for i := 0 to Length(ClassesInfo)-1 do ClassesInfo[i].Cleanup();

  // �����
  for i := 0 to Length(FUnits)-1 do FUnits[i].Free;
  FUnits := nil;
  FUnitsCount := 0;
  

  inherited;
end;           *)

procedure TLua.SetCodePage(Value: Word);
var
  i, X, Y: Integer;
  Dest, Src, TopSrc: Pointer;
  Buffer: array[128..255] of AnsiChar;
begin
  // code page
  if (Value = 0) then Value := CODEPAGE_DEFAULT;
  FCodePage := Value;

  // unicode table (128..255)
  if (Value = $ffff) then
  begin
    Dest := @FUnicodeTable[128];
    X := 128 + (129 shl 16);
    for i := 1 to (128 div (SizeOf(Integer) div SizeOf(WideChar))) do
    begin
      PInteger(Dest)^ := X;
      Inc(X, $00010001);
      Inc(NativeInt(Dest), SizeOf(Integer));
    end;
  end else
  begin
    Dest := @Buffer;
    X := 128 + (129 shl 8) + (130 shl 16) + (131 shl 24);
    for i := 1 to (128 div SizeOf(Integer)) do
    begin
      PInteger(Dest)^ := X;
      Inc(X, $01010101);
      Inc(NativeInt(Dest), SizeOf(Integer));
    end;

    {$ifdef MSWINDOWS}
      MultiByteToWideChar(Value, 0, Pointer(@Buffer), 128, Pointer(@FUnicodeTable[128]), 128);
    {$else}
      UnicodeFromLocaleChars(Value, 0, Pointer(@Buffer), 128, Pointer(@FUnicodeTable[128]), 128);
    {$endif}
  end;

  // utf8 table (128..255)
  Src := @FUnicodeTable[128];
  TopSrc := @FUnicodeTable[High(FUnicodeTable)];
  Dest := Pointer(@FUTF8Table[128]);
  Dec(NativeInt(Src), SizeOf(WideChar));
  Dec(NativeInt(Dest), SizeOf(Cardinal));
  repeat
    if (Src = TopSrc) then Break;
    Inc(NativeInt(Src), SizeOf(WideChar));
    Inc(NativeInt(Dest), SizeOf(Cardinal));

    X := PWord(Src)^;
    if (X <= $7ff) then
    begin
      if (X > $7f) then
      begin
        Y := (X and $3f) shl 8;
        X := (X shr 6) + $020080c0;
        Inc(X, Y);
        PCardinal(Dest)^ := X;
      end else
      begin
        X := X + $01000000;
        PCardinal(Dest)^ := X;
      end;
    end else
    begin
      Y := ((X and $3f) shl 16) + ((X and ($3f shl 6)) shl (8-6));
      X := (X shr 12) + $038080E0;
      Inc(X, Y);
      PCardinal(Dest)^ := X;
    end;
  until (False);
end;

function TLua.AnsiFromUnicode(ADest: PAnsiChar; ACodePage: Word; ASource: PWideChar; ALength: Integer): Integer;
const
  CHARS_PER_ITERATION = SizeOf(Integer) div SizeOf(WideChar);
var
  Dest: PAnsiChar;
  Source: PWideChar;
  Count, X: Integer;
begin
  Count := ALength;
  Dest := ADest;
  Source := ASource;

  if (Count >= CHARS_PER_ITERATION) then
  repeat
    X := PInteger(Source)^;
    if (X and $ff80ff80 <> 0) then Break;

    Inc(X, X shr 8);
    Dec(Count, CHARS_PER_ITERATION);
    PWord(Dest)^ := X;
    Inc(Source, CHARS_PER_ITERATION);
    Inc(Dest, CHARS_PER_ITERATION);
  until (Count < CHARS_PER_ITERATION);

  if (Count <> 0) then
  begin
    X := PWord(Source)^;
    if (X and $ff80 = 0) then
    begin
      PByte(Dest)^ := X;
      Dec(Count);
      Inc(Source);
      Inc(Dest);
    end;

    if (Count <> 0) then
    Inc(Dest,
      {$ifdef MSWINDOWS}
        WideCharToMultiByte(ACodePage, 0, Source, Count, Pointer(Dest), Count, nil, nil)
      {$else}
        LocaleCharsFromUnicode(ACodePage, 0, Source, Count, Pointer(Dest), Count, nil, nil)
      {$endif} );
  end;

  Result := NativeInt(Dest) - NativeInt(ADest);
end;

procedure TLua.UnicodeFromAnsi(ADest: PWideChar; ASource: PAnsiChar; ACodePage: Word; ALength: Integer);
const
  CHARS_PER_ITERATION = SizeOf(Integer) div SizeOf(AnsiChar);
type
  TUnicodeTable = array[Byte] of Word;
var
  Dest: PWideChar;
  Source: PAnsiChar;
  Count, X: Integer;
  UnicodeTable: ^TUnicodeTable;
begin
  if (ACodePage = 0) then ACodePage := CODEPAGE_DEFAULT;
  if (ACodePage <> FCodePage) then SetCodePage(ACodePage);

  Count := ALength;
  Dest := ADest;
  Source := ASource;
  UnicodeTable := Pointer(@FUnicodeTable);

  if (Count >= CHARS_PER_ITERATION) then
  repeat
    X := PInteger(Source)^;
    if (X and $8080 = 0) then
    begin
      if (X and $80808080 = 0) then
      begin
        PCardinal(Dest)^ := Byte(X) + (X and $ff00) shl 8;
        X := X shr 16;
        Dec(Count, 2);
        Inc(Source, 2);
        Inc(Dest, 2);
      end;

      PCardinal(Dest)^ := Byte(X) + (X and $ff00) shl 8;
      Dec(Count, 2);
      Inc(Source, 2);
      Inc(Dest, 2);

      if (Count < CHARS_PER_ITERATION) then Break;
    end else
    begin
      X := Byte(X);
      {$ifdef CPUX86}if (X > $7f) then{$endif} X := UnicodeTable[X];
      PWord(Dest)^ := X;

      Dec(Count);
      Inc(Source);
      Inc(Dest);
      if (Count < CHARS_PER_ITERATION) then Break;
    end;
  until (False);

  if (Count <> 0) then
  repeat
    X := PByte(Source)^;
    {$ifdef CPUX86}if (X > $7f) then{$endif} X := UnicodeTable[X];
    PWord(Dest)^ := X;

    Dec(Count);
    Inc(Source);
    Inc(Dest);
  until (Count = 0);
end;

function Utf8FromUnicode(ADest: PAnsiChar; ASource: PWideChar; ALength: Integer): Integer;
label
  process4, look_first, process_standard, process_character, unknown,
  small_length, done;
const
  MASK_FF80_SMALL = $FF80FF80;
  MASK_FF80_LARGE = $FF80FF80FF80FF80;
  UNKNOWN_CHARACTER = Ord('?');
var
  X, U, Count: NativeUInt;
  Dest: PAnsiChar;
  Source: PWideChar;
{$ifdef CPUX86}
const
  MASK_FF80 = MASK_FF80_SMALL;
{$else .CPUX64/.CPUARM}
var
  MASK_FF80: NativeUInt;
{$endif}
begin
  Count := ALength;
  Dest := ADest;
  Source := ASource;

  if (Count = 0) then goto done;
  Inc(Count, Count);
  Inc(Count, NativeUInt(Source));
  Dec(Count, (2 * SizeOf(Cardinal)));

  {$ifNdef CPUX86}
  MASK_FF80 := {$ifdef LARGEINT}MASK_FF80_LARGE{$else}MASK_FF80_SMALL{$endif};
  {$endif}

  // conversion loop
  if (NativeUInt(Source) > Count{TopSource}) then goto small_length;
  {$ifdef SMALLINT}
    X := Word(Source[0]);
    U := Word(Source[1]);
    if ((X or U) and Integer(MASK_FF80) = 0) then
  {$else}
    X := PNativeUInt(Source)^;
    if (X and MASK_FF80 = 0) then
  {$endif}
  begin
    repeat
    process4:
      {$ifdef LARGEINT}
      U := X shr 32;
      {$endif}
      X := X + (X shr 8);
      U := U + (U shr 8);
      X := Word(X);
      {$ifdef LARGEINT}
      U := Word(U);
      {$endif}
      U := U shl 16;
      Inc(X, U);

      Inc(Source, SizeOf(Cardinal));
      PCardinal(Dest)^ := X;
      Inc(Dest, SizeOf(Cardinal));

      if (NativeUInt(Source) > Count{TopSource}) then goto small_length;
    {$ifdef SMALLINT}
      X := Word(Source[0]);
      U := Word(Source[1]);
    until ((X or U) and Integer(MASK_FF80) <> 0);
    {$else}
      X := PNativeUInt(Source)^;
    until (X and MASK_FF80 <> 0);
    {$endif}
    goto look_first;
  end else
  begin
  look_first:
    {$ifdef LARGEINT}
    X := Cardinal(X);
    {$endif}
  process_standard:
    Inc(Source);
    U := Word(X);
    if (X and $FF80 = 0) then
    begin
      if (X and MASK_FF80 = 0) then
      begin
        // ascii_2
        X := X shr 8;
        Inc(Source);
        Inc(X, U);
        PWord(Dest)^ := X;
        Inc(Dest, 2);
      end else
      begin
        // ascii_1
        PByte(Dest)^ := X;
        Inc(Dest);
      end;
    end else
    if (U < $d800) then
    begin
    process_character:
      if (U <= $7ff) then
      begin
        if (U > $7f) then
        begin
          X := (U shr 6) + $80C0;
          U := (U and $3f) shl 8;
          Inc(X, U);
          PWord(Dest)^ := X;
          Inc(Dest, 2);
        end else
        begin
          PByte(Dest)^ := U;
          Inc(Dest);
        end;
      end else
      begin
        X := (U and $0fc0) shl 2;
        Inc(X, (U and $3f) shl 16);
        U := (U shr 12);
        Inc(X, $8080E0);
        Inc(X, U);

        PWord(Dest)^ := X;
        Inc(Dest, 2);
        X := X shr 16;
        PByte(Dest)^ := X;
        Inc(Dest);
      end;
    end else
    begin
      if (U >= $e000) then goto process_character;
      if (U >= $dc00) then
      begin
      unknown:
        PByte(Dest)^ := UNKNOWN_CHARACTER;
        Inc(Dest);
      end else
      begin
        Inc(Source);
        X := X shr 16;
        Dec(U, $d800);
        Dec(X, $dc00);
        if (X >= ($e000-$dc00)) then goto unknown;

        U := U shl 10;
        Inc(X, $10000);
        Inc(X, U);

        U := (X and $3f) shl 24;
        U := U + ((X and $0fc0) shl 10);
        U := U + (X shr 18);
        X := (X shr 4) and $3f00;
        Inc(U, Integer($808080F0));
        Inc(X, U);

        PCardinal(Dest)^ := X;
        Inc(Dest, 4);
      end;
    end;
  end;

  if (NativeUInt(Source) > Count{TopSource}) then goto small_length;
  {$ifdef SMALLINT}
    X := Word(Source[0]);
    U := Word(Source[1]);
    if ((X or U) and Integer(MASK_FF80) = 0) then goto process4;
  {$else}
    X := PNativeUInt(Source)^;
    if (X and MASK_FF80 = 0) then goto process4;
  {$endif}
  goto look_first;

small_length:
  U := Count{TopSource} + (2 * SizeOf(Cardinal));
  if (U = NativeUInt(Source)) then goto done;
  Dec(U, NativeUInt(Source));
  if (U >= SizeOf(Cardinal)) then
  begin
    X := PCardinal(Source)^;
    goto process_standard;
  end;
  U := PWord(Source)^;
  Inc(Source);
  if (U < $d800) then goto process_character;
  if (U >= $e000) then goto process_character;
  if (U >= $dc00) then goto unknown;

  PByte(Dest)^ := UNKNOWN_CHARACTER;
  Inc(Dest);

  // result
done:
  Result := NativeInt(Dest) - NativeInt(ADest);
end;

function UnicodeFromUtf8(ADest: PWideChar; ASource: PAnsiChar; ALength: Integer): Integer;
label
  process4, look_first, process1_3,
  ascii_1, ascii_2, ascii_3,
  process_standard, process_character, unknown,
  next_iteration, small_length, done;
const
  MASK_80_SMALL = $80808080;
  MAX_UTF8CHAR_SIZE = 6;
  UNKNOWN_CHARACTER = Ord('?');
var
  X, U, Count: NativeUInt;
  Dest: PWideChar;
  Source: PAnsiChar;
{$ifdef CPUINTEL}
const
  MASK_80 = MASK_80_SMALL;
{$else .CPUARM}
var
  MASK_80: NativeUInt;
{$endif}
begin
  Count := ALength;
  Dest := ADest;
  Source := ASource;

  if (Count = 0) then goto done;
  Inc(Count, NativeUInt(Source));
  Dec(Count, MAX_UTF8CHAR_SIZE);

  {$ifdef CPUARM}
    MASK_80 := MASK_80_SMALL;
  {$endif}

  // conversion loop
  if (NativeUInt(Source) > Count{TopSource}) then goto small_length;
  X := PCardinal(Source)^;
  if (X and Integer(MASK_80) = 0) then
  begin
    repeat
    process4:
      Inc(Source, SizeOf(Cardinal));

      {$ifNdef LARGEINT}
        PCardinal(Dest)^ := (X and $7f) + ((X and $7f00) shl 8);
        X := X shr 16;
        Inc(Dest, 2);
        PCardinal(Dest)^ := (X and $7f) + ((X and $7f00) shl 8);
        Inc(Dest, 2);
      {$else}
        PNativeUInt(Dest)^ := (X and $7f) + ((X and $7f00) shl 8) +
          ((X and $7f0000) shl 16) + ((X and $7f000000) shl 24);
        Inc(NativeUInt(Dest), SizeOf(NativeUInt));
      {$endif}

      if (NativeUInt(Source) > Count{TopSource}) then goto small_length;
      X := PCardinal(Source)^;
    until (X and Integer(MASK_80) <> 0);
    goto look_first;
  end else
  begin
  look_first:
    if (X and $80 = 0) then
    begin
    process1_3:
      {$ifNdef LARGEINT}
        PCardinal(Dest)^ := (X and $7f) + ((X and $7f00) shl 8);
        Inc(Dest, 2);
        PCardinal(Dest)^ := ((X shr 16) and $7f);
      {$else}
        PNativeUInt(Dest)^ := (X and $7f) + ((X and $7f00) shl 8) +
          ((X and $7f0000) shl 16);
      {$endif}

      if (X and $8000 <> 0) then goto ascii_1;
      if (X and $800000 <> 0) then goto ascii_2;
      ascii_3:
        Inc(Source, 3);
        Inc(Dest, 3{$ifdef SMALLINT}- 2{$endif});
        goto next_iteration;
      ascii_2:
        X := X shr 16;
        Inc(Source, 2);
        {$ifdef LARGEINT}Inc(Dest, 2);{$endif}
        if (UTF8CHAR_SIZE[Byte(X)] <= 2) then goto process_standard;
        goto next_iteration;
      ascii_1:
        X := X shr 8;
        Inc(Source);
        Inc(Dest, 1{$ifdef SMALLINT}- 2{$endif});
        if (UTF8CHAR_SIZE[Byte(X)] <= 3) then goto process_standard;
        // goto next_iteration;
    end else
    begin
    process_standard:
      if (X and $C0E0 = $80C0) then
      begin
        X := ((X and $1F) shl 6) + ((X shr 8) and $3F);
        Inc(Source, 2);

      process_character:
        PWord(Dest)^ := X;
        Inc(Dest);
      end else
      begin
        U := UTF8CHAR_SIZE[Byte(X)];
        case (U) of
          1:
          begin
            X := X and $7f;
            Inc(Source);
            PWord(Dest)^ := X;
            Inc(Dest);
          end;
          3:
          begin
            if (X and $C0C000 = $808000) then
            begin
              U := (X and $0F) shl 12;
              U := U + (X shr 16) and $3F;
              X := (X and $3F00) shr 2;
              Inc(Source, 3);
              Inc(X, U);
              if (U shr 11 = $1B) then X := $fffd;
              PWord(Dest)^ := X;
              Inc(Dest);
              goto next_iteration;
            end;
            goto unknown;
          end;
          4:
          begin
            if (X and $C0C0C000 = $80808000) then
            begin
              U := (X and $07) shl 18;
              U := U + (X and $3f00) shl 4;
              U := U + (X shr 10) and $0fc0;
              X := (X shr 24) and $3f;
              Inc(X, U);

              U := (X - $10000) shr 10 + $d800;
              X := (X - $10000) and $3ff + $dc00;
              X := (X shl 16) + U;

              PCardinal(Dest)^ := X;
              Inc(Dest, 2);
              goto next_iteration;
            end;
            goto unknown;
          end;
        else
        unknown:
          PWord(Dest)^ := UNKNOWN_CHARACTER;
          Inc(Dest);
          Inc(Source, U);
          Inc(Source, NativeUInt(U = 0));
        end;
      end;
    end;
  end;

next_iteration:
  if (NativeUInt(Source) > Count{TopSource}) then goto small_length;
  X := PCardinal(Source)^;
  if (X and Integer(MASK_80) = 0) then goto process4;
  if (X and $80 = 0) then goto process1_3;
  goto process_standard;

small_length:
  U := Count{TopSource} + MAX_UTF8CHAR_SIZE;
  if (U = NativeUInt(Source)) then goto done;
  X := PByte(Source)^;
  if (X <= $7f) then
  begin
    PWord(Dest)^ := X;
    Inc(Source);
    Inc(Dest);
    if (NativeUInt(Source) <> Count{TopSource}) then goto small_length;
    goto done;
  end;
  X := UTF8CHAR_SIZE[X];
  Dec(U, NativeUInt(Source));
  if (X{char size} > U{available source length}) then
  begin
    PWord(Dest)^ := UNKNOWN_CHARACTER;
    Inc(Dest);
    goto done;
  end;

  case X{char size} of
    2:
    begin
      X := PWord(Source)^;
      goto process_standard;
    end;
    3:
    begin
      Inc(Source, 2);
      X := Byte(Source^);
      Dec(Source, 2);
      X := (X shl 16) or PWord(Source)^;
      goto process_standard;
    end;
  else
    // 4..5
    goto unknown;
  end;

  // result
done:
  Result := (NativeInt(Dest) - NativeInt(ADest)) shr 1;
end;

function TLua.Utf8FromAnsi(ADest: PAnsiChar; ASource: PAnsiChar; ACodePage: Word; ALength: Integer): Integer;
label
  process4, look_first, process1_3,
  ascii_1, ascii_2, ascii_3,
  process_not_ascii,
  small_4, small_3, small_2, small_1,
  small_length, done;
const
  MASK_80_SMALL = $80808080;
type
  TUTF8Table = array[Byte] of Cardinal;
var
  {$ifdef CPUX86}
  Store: record
    TopSource: NativeUInt;
  end;
  {$endif}

  X, U, Count: NativeUInt;
  Dest: PAnsiChar;
  Source: PAnsiChar;
  {$ifNdef CPUX86}
  TopSource: NativeUInt;
  {$endif}
  UTF8Table: ^TUTF8Table;

{$ifdef CPUINTEL}
const
  MASK_80 = MASK_80_SMALL;
{$else .CPUARM}
var
  MASK_80: NativeUInt;
{$endif}
begin
  if (ACodePage = 0) then ACodePage := CODEPAGE_DEFAULT;
  if (ACodePage <> FCodePage) then SetCodePage(ACodePage);

  Count := ALength;
  Dest := ADest;
  Source := ASource;

  if (Count = 0) then goto done;
  Inc(Count, NativeUInt(Source));
  Dec(Count, SizeOf(Cardinal));
  {$ifdef CPUX86}Store.{$endif}TopSource := Count;
  UTF8Table := Pointer(@FUTF8Table);

  {$ifdef CPUARM}
    MASK_80 := MASK_80_SMALL;
  {$endif}

  // conversion loop
  if (NativeUInt(Source) > {$ifdef CPUX86}Store.{$endif}TopSource) then goto small_length;
  X := PCardinal(Source)^;
  if (X and Integer(MASK_80) = 0) then
  begin
    repeat
    process4:
      Inc(Source, SizeOf(Cardinal));
      PCardinal(Dest)^ := X;
      Inc(Dest, SizeOf(Cardinal));

      if (NativeUInt(Source) > {$ifdef CPUX86}Store.{$endif}TopSource) then goto small_length;
      X := PCardinal(Source)^;
    until (X and Integer(MASK_80) <> 0);
    goto look_first;
  end else
  begin
  look_first:
    if (X and $80 = 0) then
    begin
    process1_3:
      PCardinal(Dest)^ := X;
      if (X and $8000 <> 0) then goto ascii_1;
      if (X and $800000 <> 0) then goto ascii_2;
      ascii_3:
        X := X shr 24;
        Inc(Source, 3);
        Inc(Dest, 3);
        goto small_1;
      ascii_2:
        X := X shr 16;
        Inc(Source, 2);
        Inc(Dest, 2);
        goto small_2;
      ascii_1:
        X := X shr 8;
        Inc(Source);
        Inc(Dest);
        goto small_3;
    end else
    begin
    process_not_ascii:
      if (X and $8000 = 0) then goto small_1;
      if (X and $800000 = 0) then goto small_2;
      if (X and $80000000 = 0) then goto small_3;

      small_4:
        U := UTF8Table[Byte(X)];
        X := X shr 8;
        Inc(Source);
        PCardinal(Dest)^ := U;
        U := U shr 24;
        Inc(Dest, U);
      small_3:
        U := UTF8Table[Byte(X)];
        X := X shr 8;
        Inc(Source);
        PCardinal(Dest)^ := U;
        U := U shr 24;
        Inc(Dest, U);
      small_2:
        U := UTF8Table[Byte(X)];
        X := X shr 8;
        Inc(Source);
        PCardinal(Dest)^ := U;
        U := U shr 24;
        Inc(Dest, U);
      small_1:
        U := UTF8Table[Byte(X)];
        Inc(Source);
        X := U;
        PWord(Dest)^ := U;
        U := U shr 24;
        Inc(Dest, U);
        if (X >= (3 shl 24)) then
        begin
          Dec(Dest);
          X := X shr 16;
          PByte(Dest)^ := X;
          Inc(Dest);
        end;
    end;
  end;

  if (NativeUInt(Source) > {$ifdef CPUX86}Store.{$endif}TopSource) then goto small_length;
  X := PCardinal(Source)^;
  if (X and Integer(MASK_80) = 0) then goto process4;
  if (X and $80 = 0) then goto process1_3;
  goto process_not_ascii;

small_length:
  case (NativeUInt(Source) - {$ifdef CPUX86}Store.{$endif}TopSource) of
   3{1}: begin
           X := PByte(Source)^;
           goto small_1;
         end;
   2{2}: begin
           X := PWord(Source)^;
           goto small_2;
         end;
   1{3}: begin
           Inc(Source, 2);
           X := Byte(Source^);
           Dec(Source, 2);
           X := (X shl 16) or PWord(Source)^;
           goto small_3;
         end;
  end;

  // result
done:
  Result := NativeUInt(Dest) - NativeUInt(ADest);
end;


type
  TUnicodeConvertDesc = record
    CodePage: Word;
    Dest: Pointer;
    Source: Pointer;
    Count: NativeUInt;
  end;

function InternalAnsiFromUtf8(const ConvertDesc: TUnicodeConvertDesc): Integer;
label
  ascii, ascii_write, unicode_write, non_ascii, unknown;
type
  TUnicodeTable = array[Byte] of Word;
  PUnicodeTable = ^TUnicodeTable;
const
  MASK_80_SMALL = $80808080;
  UNKNOWN_CHARACTER = Ord('?');
  BUFFER_SIZE = 1024;
var
  X, U, Count: NativeUInt;
  Dest: PAnsiChar;
  Source: PAnsiChar;
  BufferDest: PWideChar;
  BufferCount: NativeUInt;
  Buffer: array[0..BUFFER_SIZE + 4] of WideChar;
  Stored: record
    CodePage: Word;
    X: NativeUInt;
    Dest: Pointer;
  end;
{$ifdef CPUINTEL}
const
  MASK_80 = MASK_80_SMALL;
{$else .CPUARM}
var
  MASK_80: NativeUInt;
{$endif}
begin
  Stored.CodePage := ConvertDesc.CodePage;
  Dest := ConvertDesc.Dest;
  Source := ConvertDesc.Source;
  Count := ConvertDesc.Count;
  Stored.Dest := Dest;

  BufferDest := @Buffer[0];
  {$ifdef CPUARM}
    MASK_80 := MASK_80_SMALL;
  {$endif}

  repeat
    if (Count = 0) then Break;
    if (Count <= SizeOf(Cardinal)) then
    begin
      X := PCardinal(Source)^;
      if (X and $80 = 0) then
      begin
      ascii:
        if (BufferDest = @Buffer[0]) then
        begin
        ascii_write:
          PCardinal(Dest)^ := X;
          if (X and MASK_80 = 0) then
          begin
            Dec(Count, SizeOf(Cardinal));
            Inc(Source, SizeOf(Cardinal));
            Inc(Dest, SizeOf(Cardinal));
          end else
          begin
            U := Byte(X and $8080 = 0);
            X := Byte(X and $808080 = 0);
            Inc(X, U);
            Dec(Count);
            Inc(Source);
            Inc(Dest);
            Dec(Count, X);
            Inc(Source, X);
            Inc(Dest, X);
            if (Count = 0) then Break;
            X := PByte(Source)^;
            goto non_ascii;
          end;
        end else
        begin
        unicode_write:
          Stored.X := X;
          begin
            BufferCount := (NativeUInt(BufferDest) - NativeUInt(@Buffer[0])) shr 1;
            Inc(Dest,
            {$ifdef MSWINDOWS}
              WideCharToMultiByte(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
            {$else}
              LocaleCharsFromUnicode(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
            {$endif} );
            BufferDest := @Buffer[0];
          end;
          X := Stored.X;
          if (X <> NativeUInt(-1)) then goto ascii_write;
        end;
      end else
      begin
        goto non_ascii;
      end;
    end else
    begin
      X := PByte(Source)^;
      Inc(X, $ffffff00);
      if (X and $80 = 0) then goto ascii;
    non_ascii:
      U := UTF8CHAR_SIZE[Byte(X)];
      if (U <= Count) then
      begin
        case U of
          2:
          begin
            X := PWord(Source)^;
            Dec(Count, 2);
            Inc(Source, 2);
            if (X and $C0E0 <> $80C0) then goto unknown;

            X := ((X and $1F) shl 6) + ((X shr 8) and $3F);
          end;
          3:
          begin
            Inc(Source, SizeOf(Word));
            X := PByte(Source)^;
            Dec(Source, SizeOf(Word));
            X := X shl 16;
            Inc(X, PWord(Source)^);
            Dec(Count, 3);
            Inc(Source, 3);
            if (X and $C0C000 <> $808000) then goto unknown;

            U := (X and $0F) shl 12;
            U := U + (X shr 16) and $3F;
            X := (X and $3F00) shr 2;
            Inc(X, U);
            if (U shr 11 = $1B) then goto unknown;
          end;
        else
          Inc(U, Byte(U = 0));
          Dec(Count, U);
          Inc(Source, U);
        unknown:
          X := UNKNOWN_CHARACTER;
        end;

        PWord(BufferDest)^ := X;
        Inc(BufferDest);
        X := NativeUInt(-1);
        if (NativeUInt(BufferDest) >= NativeUInt(@Buffer[BUFFER_SIZE])) then goto unicode_write;
      end else
      begin
        if (BufferDest <> @Buffer[0]) then
        begin
          PWord(BufferDest)^ := UNKNOWN_CHARACTER;
          Inc(BufferDest);
        end else
        begin
          PByte(Dest)^ := UNKNOWN_CHARACTER;
          Inc(Dest);
        end;
        Break;
      end;
    end;
  until (False);

  // last chars
  if (BufferDest <> @Buffer[0]) then
  begin
    BufferCount := (NativeUInt(BufferDest) - NativeUInt(@Buffer[0])) shr 1;
    Inc(Dest,
    {$ifdef MSWINDOWS}
      WideCharToMultiByte(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
    {$else}
      LocaleCharsFromUnicode(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
    {$endif} );
  end;

  // result
  Result := NativeInt(Dest) - NativeInt(Stored.Dest);
end;

function TLua.AnsiFromUtf8(ADest: PAnsiChar; ACodePage: Word; ASource: PAnsiChar; ALength: Integer): Integer;
var
  ConvertDesc: TUnicodeConvertDesc;
begin
  if (ACodePage = 0) then ACodePage := CODEPAGE_DEFAULT;
  ConvertDesc.CodePage := ACodePage;
  ConvertDesc.Dest := ADest;
  ConvertDesc.Source := ASource;
  ConvertDesc.Count := ALength;

  Result := InternalAnsiFromUtf8(ConvertDesc);
end;

function InternalAnsiFromAnsi(const ConvertDesc: TUnicodeConvertDesc; const UnicodeTable: Pointer): Integer;
label
  ascii, ascii_write, unicode_write, non_ascii;
type
  TUnicodeTable = array[Byte] of Word;
  PUnicodeTable = ^TUnicodeTable;
const
  MASK_80_SMALL = $80808080;
  UNKNOWN_CHARACTER = Ord('?');
  BUFFER_SIZE = 1024;
var
  X, U, Count: NativeUInt;
  Dest: PAnsiChar;
  Source: PAnsiChar;
  BufferDest: PWideChar;
  BufferCount: NativeUInt;
  Buffer: array[0..BUFFER_SIZE + 4] of WideChar;
  Stored: record
    CodePage: Word;
    X: NativeUInt;
    Dest: Pointer;
  end;
{$ifdef CPUINTEL}
const
  MASK_80 = MASK_80_SMALL;
{$else .CPUARM}
var
  MASK_80: NativeUInt;
{$endif}
begin
  Stored.CodePage := ConvertDesc.CodePage;
  Dest := ConvertDesc.Dest;
  Source := ConvertDesc.Source;
  Count := ConvertDesc.Count;
  Stored.Dest := Dest;

  BufferDest := @Buffer[0];
  {$ifdef CPUARM}
    MASK_80 := MASK_80_SMALL;
  {$endif}

  repeat
    if (Count = 0) then Break;
    if (Count <= SizeOf(Cardinal)) then
    begin
      X := PCardinal(Source)^;
      if (X and $80 = 0) then
      begin
      ascii:
        if (BufferDest = @Buffer[0]) then
        begin
        ascii_write:
          PCardinal(Dest)^ := X;
          if (X and MASK_80 = 0) then
          begin
            Dec(Count, SizeOf(Cardinal));
            Inc(Source, SizeOf(Cardinal));
            Inc(Dest, SizeOf(Cardinal));
          end else
          begin
            U := Byte(X and $8080 = 0);
            X := Byte(X and $808080 = 0);
            Inc(X, U);
            Dec(Count);
            Inc(Source);
            Inc(Dest);
            Dec(Count, X);
            Inc(Source, X);
            Inc(Dest, X);
            if (Count = 0) then Break;
            X := PByte(Source)^;
            goto non_ascii;
          end;
        end else
        begin
        unicode_write:
          Stored.X := X;
          begin
            BufferCount := (NativeUInt(BufferDest) - NativeUInt(@Buffer[0])) shr 1;
            Inc(Dest,
            {$ifdef MSWINDOWS}
              WideCharToMultiByte(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
            {$else}
              LocaleCharsFromUnicode(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
            {$endif} );
            BufferDest := @Buffer[0];
          end;
          X := Stored.X;
          if (X <> NativeUInt(-1)) then goto ascii_write;
        end;
      end else
      begin
        goto non_ascii;
      end;
    end else
    begin
      X := PByte(Source)^;
      Inc(X, $ffffff00);
      if (X and $80 = 0) then goto ascii;
    non_ascii:
      PWord(BufferDest)^ := PUnicodeTable(UnicodeTable)[Byte(X)];
      Inc(BufferDest);
      Inc(Source);
      Dec(Count);
      X := NativeUInt(-1);
      if (NativeUInt(BufferDest) >= NativeUInt(@Buffer[BUFFER_SIZE])) then goto unicode_write;
    end;
  until (False);

  // last chars
  if (BufferDest <> @Buffer[0]) then
  begin
    BufferCount := (NativeUInt(BufferDest) - NativeUInt(@Buffer[0])) shr 1;
    Inc(Dest,
    {$ifdef MSWINDOWS}
      WideCharToMultiByte(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
    {$else}
      LocaleCharsFromUnicode(Stored.CodePage, 0, Pointer(@Buffer[0]), BufferCount, Pointer(Dest), BufferCount, nil, nil)
    {$endif} );
  end;

  // result
  Result := NativeInt(Dest) - NativeInt(Stored.Dest);
end;

function TLua.AnsiFromAnsi(ADest: PAnsiChar; ADestCodePage: Word; ASource: PAnsiChar;
  ASourceCodePage: Word; ALength: Integer): Integer;
var
  ConvertDesc: TUnicodeConvertDesc;
  SourceCodePage: Word;
begin
  ConvertDesc.Dest := ADest;
  ConvertDesc.Source := ASource;
  ConvertDesc.Count := ALength;

  if (ADestCodePage = 0) then ADestCodePage := CODEPAGE_DEFAULT;
  SourceCodePage := ASourceCodePage;
  if (SourceCodePage = 0) then SourceCodePage := CODEPAGE_DEFAULT;

  if (ADestCodePage = SourceCodePage) then
  begin
    System.Move(ConvertDesc.Source^, ConvertDesc.Dest^, ConvertDesc.Count);
    Result := ConvertDesc.Count;
  end else
  begin
    ConvertDesc.CodePage := ADestCodePage;
    if (SourceCodePage <> FCodePage) then SetCodePage(SourceCodePage);
    Result := InternalAnsiFromAnsi(ConvertDesc, @Self.FUnicodeTable);
  end;
end;

                 (*
procedure __TLuaGarbageCollection(const Self: TLua; const ReturnAddr: pointer);
var
  ret: integer;
begin
  ret := lua_gc(Self.Handle, 2{LUA_GCCOLLECT}, 0);
  if (ret <> 0) then Self.Check(ret, ReturnAddr);
end;

procedure TLua.GarbageCollection();
asm
  mov edx, [esp]
  jmp __TLuaGarbageCollection
end;        *)

              (*
// ��������� ��������� � ����
type TLuaStringList = class(TStringList) public Lua: TLua; end;
procedure TLua.SaveNameSpace(const FileName: string);
const
  CHARS: array[0..5] of char = (#13, #10, #9, #32, #32, #32);
var
  NameSpace, M: TMemoryStream;

  // ������
  procedure Enter();
  begin NameSpace.Write(CHARS[0], 2*sizeof(char)); end;

  procedure Write(C: char); overload;
  begin NameSpace.Write(C, sizeof(C)); end;

  procedure Write(const S: string; use_enter: boolean=true; tabs_count: integer=1); overload;
  var
    i: integer;
  begin
    for i := 0 to tabs_count-1 do NameSpace.Write(CHARS[2], sizeof(char));
    if (S <> '') then NameSpace.Write(pointer(S)^, Length(S));
    if (use_enter) then NameSpace.Write(CHARS[0], 2*sizeof(char));
  end;

  procedure Write(Lines: TStringList; tabs_count: integer=1; const prefics: string=''; const postfix: string=''); overload;
  var
    i: integer;
  begin
    if (Lines.Count = 0) then exit;

    for i := 0 to Lines.Count-1 do
    begin
      // tab
      if (tabs_count > 0) then NameSpace.Write(CHARS[2], sizeof(char));
      // spaces
      if (tabs_count > 1) then NameSpace.Write(CHARS[3], 3*sizeof(char));

      // prefics
      if (prefics <> '') then
      begin
        Write(prefics, false, 0);
        NameSpace.Write(CHARS[3], sizeof(char)); // #32
      end;

      // string
      Write(Lines[i], (postfix=''), 0);

      // postfix
      if (postfix <> '') then Write(postfix, true, 0);
    end;
  end;

  procedure WriteIdent(const Ident: string);
  const
    RowWidth = 80;
  var
    S: string;
    Len, L: integer;
  begin
    if (NameSpace.Size <> 0) then
    begin
      Enter;
      Enter;
    end;

    SetLength(S, RowWidth);
    FillChar(pointer(S)^, RowWidth, ord('*'));

    pchar(pointer(S))[0] := '(';
    pchar(pointer(S))[RowWidth-1] := ')';

    Len := Length(Ident);
    L := (RowWidth-Len) div 2;
    CopyMemory(@pchar(pointer(S))[L], pointer(Ident), Len);

    pchar(pointer(S))[L-1] := #32;
    pchar(pointer(S))[L-2] := #32;
    pchar(pointer(S))[L+Len] := #32;
    pchar(pointer(S))[L+Len+1] := #32;

    Write(S, true, 0);
  end;

  procedure WriteToLine(Lines: TStringList);
  const
    Limit = 80- 20;
  var
    i, Count: integer;
    Buffer: string;
  begin
    Buffer := '';

    Count := Lines.Count;
    for i := 1 to Count do
    begin
      Buffer := Buffer + Lines[i-1];

      if (i = Count) then
      begin
        Write(Buffer);
      end else
      begin
        Buffer := Buffer + ', ';
        if (Length(Buffer) >= Limit) then
        begin
          Write(Buffer);
          Buffer := '';
        end;
      end;
    end;               
  end;

  function global_index_type(const Ref: integer): integer;
  begin
    lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
    Result := lua_type(Handle, -1);
    lua_settop(Handle, -1-1);
  end;

  function global_index_value(const Ref: integer): string;
  begin
    lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
    stack_luaarg(FBufferArg, -1, true);

    if (FBufferArg.LuaType = ltString) then Result := '"' + FBufferArg.str_data + '"'
    else Result := FBufferArg.ForceString;

    if (FBufferArg.LuaType = ltTable) then Result := Result + '(...)';

    lua_settop(Handle, -1-1);
  end;

var
  S, Cl: string;
  P, i, j, Len: integer;
  tpinfo: ptypeinfo;
  typedata: ptypedata;
  str: PShortString;
  native_consts, native_variables, native_methods, enumerates,
  lua_variables, lua_methods,
  sets, arrays,
  records, classes,
  type_base, type_properties, type_methods, type_events: TStringList;

  procedure create_lists();
    procedure create(var l: TStringList); begin l := TLuaStringList.Create; TLuaStringList(l).Lua := Self; end;
  begin
    create(native_consts); create(native_variables); create(native_methods);
    create(lua_variables); create(lua_methods);
    create(enumerates); create(sets);
    create(arrays); create(records); create(classes);
    create(type_base); create(type_properties); create(type_methods); create(type_events);
  end;

  procedure destroy_lists();
    procedure destroy(var l: TStringList); begin FreeAndNil(l); end;
  begin
    destroy(native_consts); destroy(native_variables); destroy(native_methods);
    destroy(lua_variables); destroy(lua_methods);
    destroy(enumerates); destroy(sets);
    destroy(arrays); destroy(records); destroy(classes);
    destroy(type_base); destroy(type_properties); destroy(type_methods); destroy(type_events);
  end;

  procedure enter_if_lists(const lists: array of TStringList);
  var i: integer;
  begin
    for i := 0 to High(lists) do
    if (lists[i].Count > 0) then begin Enter(); exit; end;
  end;

  procedure sort_lists(const lists: array of TStringList);
  var i: integer;
  begin
    for i := 0 to High(lists) do lists[i].Sort;
  end;

  function class_level(aclass: TClass): integer; far;
  asm
    mov edx, eax
    xor eax, eax

    { TClass(AClass) := TClass(AClass).ClassParent; }
    @loop:
      inc eax
      mov edx, [edx + vmtParent]
      {$ifndef fpc}
        test edx, edx
        jz @exit
        mov edx, [edx]
      {$endif}
    test edx, edx
    jnz @loop

    @exit:
  end;

  function classes_sort(list: TStringList; index1, index2: integer): integer; far;
  var
    info1, info2: ^TLuaClassInfo;
  begin
    info1 := pointer(list.Objects[index1]);
    info2 := pointer(list.Objects[index2]);

    Result := class_level(TClass(info1._Class))-class_level(TClass(info2._Class));
    if (Result = 0) then
    begin
      if (info1.ParentIndex <> info2.ParentIndex) then
      begin
        info1 := @TLuaStringList(list).Lua.ClassesInfo[info1.ParentIndex];
        info2 := @TLuaStringList(list).Lua.ClassesInfo[info2.ParentIndex];
      end;

      Result := CompareStr(info1._ClassName, info2._ClassName);
    end;
  end;

  function array_description(const ArrayInfo: TLuaArrayInfo): string;
  var
    i: integer;
    typename, desc: string;
  begin
    // �������� ���
    typename := TLuaPropertyInfo(ArrayInfo.ItemInfo).Description;
    Delete(typename, 1, 2);
    SetLength(typename, CharPos(#32, typename)-1);

    if (ArrayInfo.IsDynamic) then
    begin
      for i := 0 to ArrayInfo.Dimention-1 do
      begin
        if (i = 0) then desc := 'array of'
        else desc := desc + ' array of';
      end;
    end else
    begin
      for i := 0 to ArrayInfo.Dimention-1 do
      begin
        if (i <> 0) then desc := desc + ', ';
        desc := Format('%s%d..%d', [desc, ArrayInfo.FBoundsData[i*2], ArrayInfo.FBoundsData[i*2+1]]);
      end;

      desc := '[' + desc + '] of';
    end;

    Result := ArrayInfo.Name + ' = ' + desc + ' ' + typename;
  end;

  // �������� ��������� ��� �����
  procedure write_type(const info: TLuaClassInfo);
  const
    OPERATORS_SIMBOLS: array[TLuaOperator] of string = ('neg','+','-','*','/','%','^','compare');
  var
    o: TLuaOperator;
    i, p, Index: integer;    
    is_class: boolean;
    record_info: PLuaRecordInfo;
    description, prop_prefix, operators, propdesc: string;
    class_info: ^TLuaClassInfo;
    proc_info: ^TLuaProcInfo;
    property_info: ^TLuaPropertyInfo;
  begin
    type_base.Clear(); type_properties.Clear(); type_methods.Clear(); type_events.Clear();
    is_class := (info._ClassKind = ckClass);
    if (is_class) then
    begin
      prop_prefix := 'property';
      description := info._ClassName + ' = class';
      if (TClass(info._Class) <> TObject) then description := description + '(' + TClass(info._Class).ClassParent.ClassName + ')';
      record_info := nil;
    end else
    begin
      prop_prefix := '';
      description := info._ClassName + ' = record';
      record_info := PLuaRecordInfo(info._Class);
    end;  

    // type_base
    if (info.constructor_address <> nil) then type_base.Add('CONSTRUCTOR ()');
    if (not is_class) and (assigned(record_info.OperatorCallback)) and (record_info.Operators <> []) then
    begin
      operators := '';
      for o := Low(TLuaOperator) to High(TLuaOperator) do
      if (o in record_info.Operators) then
      begin
        if (operators = '') then operators := OPERATORS_SIMBOLS[o]
        else operators := operators + ', ' + OPERATORS_SIMBOLS[o];
      end;

      type_base.Add('OPERATORS: ' + operators);
    end;

    // ��������, ������, �������
    for i := 0 to Length(info.NameSpace)-1 do
    begin
      Index := info.NameSpace[i].Index;
      class_info := @Self.ClassesInfo[word(Index)];

      if (Index >= 0) then
      begin
        proc_info := @class_info.Procs[Index shr 16];
        type_methods.Add(proc_info.ProcName);
      end else
      begin
        property_info := @class_info.Properties[not smallint(Index shr 16)];
        propdesc := property_info.Description;

        // ������ R/W ��� c�������
        if (not is_class) then
        begin
          for p := Length(propdesc) downto 1 do
          if (propdesc[p] = #32) then
          begin
            SetLength(propdesc, p-1);
            break;
          end;
        end;

        // default property
        if (info._DefaultProperty >= 0) and (word(info._DefaultProperty) = word(Index)) and
           (smallint(info._DefaultProperty shr 16) = not smallint(Index shr 16)) then
            propdesc := propdesc + ' default';

        // event ��� property
        if (is_class) and (property_info.Base.Kind = pkRecord) and (property_info.Parameters = nil) and
           (PLuaRecordInfo(property_info.Base.Information).FClassIndex = TMETHOD_CLASS_INDEX)
        then type_events.Add(propdesc)
        else type_properties.Add(propdesc);
      end;
    end;

    // ������
    Enter;
    Enter;
    Write(description);
    Write('public');
    sort_lists([type_base, type_properties, type_methods, type_events]);

    // ������� ����������
    Write(type_base, 2);

    // ����(��������), ������, �������. ������� ������� �� is_class
    if (is_class) then
    begin
      if (type_methods.Count <> 0) then
      begin
        enter_if_lists([type_base]);
        Write(type_methods, 2, 'method', '()');
      end;
      if (type_properties.Count <> 0) then
      begin
        enter_if_lists([type_base, type_methods]);
        Write(type_properties, 2, prop_prefix);
      end;
      if (type_events.Count <> 0) then
      begin
        enter_if_lists([type_base, type_methods, type_properties]);
        Write(type_events, 2);
      end;
    end else
    begin
      if (type_properties.Count <> 0) then
      begin
        enter_if_lists([type_base]);
        Write(type_properties, 2, prop_prefix);
      end;
      if (type_methods.Count <> 0) then
      begin
        enter_if_lists([type_base, type_properties]);
        Write(type_methods, 2, 'method', '()');
      end;
    end;

    // end
    if (type_base.Count = 0) and (type_properties.Count = 0) and
       (type_methods.Count = 0) and (type_events.Count = 0) then Enter();
    Write('end');
  end;

begin
  INITIALIZE_NAME_SPACE;
  NameSpace := TMemoryStream.Create;
  create_lists();

  // ������������� ���������� ����������
  for i := 0 to Length(GlobalVariables)-1 do
  with GlobalVariables[i] do
  case _Kind of
    gkType: begin
              global_push_value(Ref);
              P := LuaTableToClass(Handle, -1);
              lua_settop(Handle, -1-1);

              if (P >= 0) then
              case ClassesInfo[P]._ClassKind of
                ckClass: classes.AddObject(_Name, TObject(@ClassesInfo[P]));
               ckRecord: records.AddObject(_Name, TObject(@ClassesInfo[P]));
                ckArray: arrays.Add(array_description(PLuaArrayInfo(ClassesInfo[P]._Class)^));
                  ckSet: sets.Add(_Name + ' = set of ' + GetOrdinalTypeName(PLuaSetInfo(ClassesInfo[P]._Class).FTypeInfo));
              end;
            end;
gkVariable: begin
              S := GlobalNative.Properties[not Index].Description();

              // ������ ���� TObject �� ������
              with GlobalNative.Properties[not Index] do
              if (Base.Kind = pkObject) and (read_mode >= 0) then
              if (ppointer(read_mode)^ <> nil) then
              begin
                P := integer{TObject}(pointer(read_mode)^);
                if (P <> 0) and (TClass(pointer(P)^) <> TObject) then
                begin
                  Cl := TObject(P).ClassName;
                  P := Pos(' TObject ', S);
                  if (P <> 0) then
                  begin
                    Delete(S, P+1, 7);
                    Insert(Cl, S, P+1);
                  end;
                end;
              end;

              // ������� r/w �� const
              for P := Length(S) downto 1 do
              if (S[P] = #32) then
              begin
                SetLength(S, P-1);
                break;
              end;
              if (IsConst) then S := S + ' const';

              native_variables.Add(S);
            end;
    gkProc: native_methods.Add(_Name);
   gkConst: native_consts.AddObject(_Name, TObject(Ref));
 gkLuaData: begin
              if (global_index_type(Ref) = LUA_TFUNCTION) then
                lua_methods.AddObject(_Name, TObject(Ref))
              else
                lua_variables.AddObject(_Name + ' = ' + global_index_value(Ref), TObject(Ref));
            end;  
  end;  

  // �������������� Enumerations
  native_consts.Sorted := true;
  for i := 0 to Length(EnumerationList)-1 do
  begin
    tpinfo := ptypeinfo(EnumerationList[i]);
    S := tpinfo.Name + ' = (';

    // �� ������� enum value
    typedata := GetTypeData(tpinfo);
    Len := typedata.MaxValue-typedata.MinValue+1;
    typedata := GetTypeData(typedata^.BaseType^);
    str := PShortString(@typedata.NameList);
    for j := 0 to Len-1 do
    begin
      Cl := str^;
      Inc(Integer(str), Length(str^) + 1);

      // ������� �� native_consts
      P := native_consts.IndexOf(Cl);
      if (P >= 0) then native_consts.Delete(P);

      // �������� � S
      if (j = 0) then S := S + Cl
      else S := S + ', ' + Cl;
    end;

    S := S + ')';
    enumerates.Add(S);
  end;

  // ���������� �������� native ��������
  native_consts.Sorted := false;
  for i := 0 to native_consts.Count-1 do
  native_consts[i] := native_consts[i] + ' = ' + global_index_value(integer(native_consts.Objects[i]));

  // ������ ������� �����: native/lua name space, enumerates
  WriteIdent('NATIVE_NAME_SPACE');
    sort_lists([native_consts, native_consts, native_methods, native_consts]);

    Write(native_consts);
    if (native_variables.Count > 0) then
    begin
      enter_if_lists([native_consts]);
      Write(native_variables);
    end;
    if (native_methods.Count > 0) then
    begin
      enter_if_lists([native_consts, native_variables]);
      Write(native_methods, 1, 'method', '()');
    end;
    if (enumerates.Count > 0) then
    begin
      enter_if_lists([native_consts, native_variables, native_methods]);
      Write(enumerates);
    end;

  WriteIdent('LUA_NAME_SPACE');
    sort_lists([lua_variables, lua_methods]);
    Write(lua_variables);
    if (lua_methods.Count > 0) then
    begin
      if (lua_variables.Count > 0) then Enter;
      Write(lua_methods, 1, 'function', '()');
    end;

  // ���������
  WriteIdent('SETS');
     sets.Sort;
     Write(sets);

  // �������
  WriteIdent('ARRAYS');
     arrays.Sort;
     Write(arrays);

  // ��������� (records)
  WriteIdent('STRUCTURES');
     records.Sort;
     WriteToLine(records);
     for i := 0 to records.Count-1 do write_type(TLuaClassInfo(pointer(records.Objects[i])^));

  // ������
  WriteIdent('CLASSES');
     classes.CustomSort(pointer(@classes_sort));
     WriteToLine(classes);
     for i := 0 to classes.Count-1 do write_type(TLuaClassInfo(pointer(classes.Objects[i])^));   



  destroy_lists();
  // ����������, �������� ����������� ������
  // ��������� � ���������� ������� - ����� �� ������ svn (��� ������ ���������� �����)
  try
    if (not FileExists(FileName)) then
    begin
      NameSpace.SaveToFile(FileName);
    end else
    begin
      M := TMemoryStream.Create;
      try
        M.LoadFromFile(FileName);

        if (NameSpace.Size <> M.Size) or (not CompareMem(NameSpace.Memory, M.Memory, NameSpace.Size)) then
        NameSpace.SaveToFile(FileName);
      finally
        M.Free;
      end;
    end;
  finally
    NameSpace.Free;
  end;
end;       *)
             (*

// ���� ������� ���������� ���, �� �������� �������� � ����. ���� �� ������� - �� �������� nil
// TLuaReference.Create/Initialize ����������� � ������ ������ � ���������� ������������� � Lua
function __TLuaCreateReference(const Self: TLua; const global_name: string{=''}; const ReturnAddr: pointer): TLuaReference;
var
  Ind: integer;
  prop_struct: TLuaPropertyStruct;
begin
  with Self do
  begin
    // �������� nil ��� ���������� ���������� ��� Exception
    if (global_name = '') then
    begin
      lua_pushnil(Handle);
    end else
    if (GlobalVariablePos(pchar(global_name), Length(global_name), Ind)) then
    with GlobalVariables[Ind] do
    begin
      if (_Kind in GLOBAL_INDEX_KINDS) then
      begin
        lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
      end else
      if (Index >= 0) then
      begin
        lua_pushcclosure(Handle, GlobalNative.Procs[Index].lua_CFunction, 0);
      end else
      begin
        // ��������� �������� ���������� ���������� � ���-����
        prop_struct.PropertyInfo := @GlobalNative.Properties[not Index];
        prop_struct.Instance := nil;
        prop_struct.IsConst := IsConst;
        prop_struct.Index := nil;
        prop_struct.ReturnAddr := ReturnAddr;
        Self.__index_prop_push(GlobalNative, @prop_struct);
      end;
    end else
    ELua.Assert('Global variable "%s" not found', [global_name], ReturnAddr);


    // ������� Instance � �������������������
    Result := TLuaReference.Create;
    Result.Initialize(Self);
  end;
end;    *)
                       (*
function TLua.CreateReference(const global_name: string=''): TLuaReference;
asm
  mov ecx, [esp]
  jmp __TLuaCreateReference
end;                  *)

                     (*

// ��������� ���������� �� ������
procedure TLua.Check(const ret: integer; const CodeAddr: pointer; AUnit: TLuaUnit=nil);

  procedure ThrowAssertation();
  var
    Err: string;
    err_str: pchar;
    P1, P2, i: integer;
    UnitName, line_fmt: string;
    UnitLine: integer;
    MinLine, MaxLine: integer;
  begin
    lua_to_pascalstring(Err, Handle, -1);
    stack_pop();
    if (Err = '') then exit;

    // �������� Err - ������ ��� ����� � ����� ������
    UnitLine := 0;
    if (Err[1] = '[') then
    begin
      P1 := CharPos('"', Err);
      P2 := CharPos(']', Err);
      if (P1 <> 0) and (P2 <> 0) then
      begin
        UnitName := Copy(Err, P1+1, P2-P1-2);
        Delete(Err, 1, P2);

        if (Err <> '') and (Err[1] = ':') then
        begin
          P1 := 1;
          P2 := CharPosEx(':', Err, 2);
          if (P2 <> 0) then
          begin
            UnitLine := StrToIntDef(Copy(Err, P1+1, P2-P1-1), 0);
            if (UnitLine > 0) then dec(UnitLine);
            Delete(Err, 1, P2);
            if (Err <> '') and (Err[1] = #32) then Delete(Err, 1, 1);
          end;
        end;
      end;
    end;

    // ������������ � ������
    if (UnitName = '') then
    begin
      AUnit := nil;
      UnitName := 'GLOBAL_NAME_SPACE';
    end else
    begin
      if (AUnit = nil) then AUnit := Self.UnitByName[UnitName];
      if (AUnit <> nil) and (dword(UnitLine) >= dword(AUnit.FLinesCount)) then AUnit := nil;
    end;

    // ������������ � ������� ���������
    Err := Format('unit "%s", line %d.'#13'%s', [UnitName, UnitLine, Err]);

    if (AUnit <> nil) then
    begin
      MinLine := UnitLine-2; if (MinLine < 0) then MinLine := 0;
      if (MinLine <> UnitLine) and (Trim(AUnit[MinLine]) = '') then inc(MinLine);
      MaxLine := UnitLine+2; if (MaxLine >= AUnit.FLinesCount) then MaxLine := AUnit.FLinesCount-1;
      if (MaxLine <> UnitLine) and (Trim(AUnit[MaxLine]) = '') then dec(MaxLine);
      line_fmt := Format(#13'%%%dd:  ', [Length(IntToStr(MaxLine))]);
      Err := Err + #13#13'Code:';

      for i := MinLine to MaxLine do
      begin
        Err := Err + Format(line_fmt, [i]);
        if (i = UnitLine) then Err := Err + '-->> ';
        Err := Err + AUnit[i];
      end;
    end;

    // ���������������� #13 --> #10 (��� ������� �������)
    err_str := pointer(Err);
    for i := 0 to Length(Err)-1 do
    if (err_str[i] = #13) then err_str[i] := #10;  

    // exception
    ELuaScript.Assert(Err, CodeAddr);
  end;

begin
  if (ret <> 0) then ThrowAssertation();
end;             *)
                   (*
function  TLua.InternalCheckArgsCount(PArgs: pinteger; ArgsCount: integer; const ProcName: string; const AClass: TClass): integer;
var
  Arg: pinteger;

  procedure ThrowAssertation();
  var
    i: integer;
    S, Required: string;
  begin
    S := ProcName;
    if (S <> '') and (AClass <> nil) then S := AClass.ClassName + '.' + S;
    if (S <> '') then S := ' in Proc "' + S + '"';

    Arg := PArgs;
    for i := 0 to ArgsCount-1 do
    begin
      if (Arg^ >= 0) then
      begin
        if (Required = '') then Required := IntToStr(Arg^)
        else Required := Format('%s or %d', [Required, Arg^]);
      end;

      inc(Arg);
    end;

    // (UNKNOWN). ��� ��������� = -1
    if (Required = '') then exit;

    // ����� ������
    if (ArgsCount <> 1) then Required := '(' + Required + ')';
    ScriptAssert('Wrong arguments count (%d)%s. Required %s.', [Self.FArgsCount, S, Required]);
  end;  

begin
  // ����� ����������� ����� ����������
  Arg := PArgs;
  for Result := 0 to ArgsCount-1 do
  begin
    if (Arg^ = Self.FArgsCount) then exit;
    inc(Arg);
  end;  

  // ������ ������
  Result := -1;
  ThrowAssertation();
end;                 *)
                           (*
// ��������� �������� ���������
// � �������� ��� �������� ������
function  TLua.StackArgument(const Index: integer): string;
var
  Buf: TLuaArg;
begin
  if (not stack_luaarg(Buf, Index, true)) then Result := FBufferArg.str_data
  else Result := Buf.ForceString;

  if (Result = '') then Result := 'nil';
end;

// ������� Exception �� Lua
procedure __TLuaScriptAssert(const Self: TLua; const FmtStr: string; const Args: array of const; const ReturnAddr: pointer);
var
  S: string;
  DebugInfo: lua_Debug;
begin
  // �������� Debug-����������
  ZeroMemory(@DebugInfo, sizeof(DebugInfo));
  lua_getstack(Self.Handle, 1, @DebugInfo);
  lua_getinfo(Self.Handle, 'Sln', @DebugInfo);

  if (DebugInfo.currentline < 0) then
  ELua.Assert(FmtStr, Args, ReturnAddr); // ��������� ������ ������ TLua.ScriptAssert

  // ����� ��������� (����������� ���)
  S := Format('%s:%d: ', [pchar(@DebugInfo.short_src[4]), DebugInfo.currentline]);
  lua_push_pascalstring(Self.Handle, S + Format(FmtStr, Args));
  lua_error(Self.Handle);
end;

procedure TLua.ScriptAssert(const FmtStr: string; const Args: array of const);
asm
  pop ebp
  push [esp]
  jmp __TLuaScriptAssert
end;
             *)
                           (*
// ��������� ������������� �������
// �� ������ ������ ��� ������ ������ ����� �� ���������
procedure PreprocessScript(var Memory: string);
const
  SPACES = [#32, #9];
  ENTER = [#13, #10];
  IGNORS = SPACES + ENTER;
  STR_PREPS = ['!','?','.',',','"','''','`',':',';','#','�','$','%','&','(',')',
               '[',']','{','}','/','|','\','~','^','*','+','-','<','=','>'] - ['_'];
  STD_NAME_SPACES: array[0..7] of string = ('coroutine', 'package', 'string', 'table', 'math', 'io', 'os', 'debug');
  STD_HASHES: array[0..7] of integer = ($5C958D0E, $61FFBC58, $37EF079, $1FF4007F, $4C000063, $4000046E, $40000457, $3E6C006F);

  // ���������� "������" ����� ������ � �������� �� ����������� ���������
  function TestStdNameSpace(P: integer): boolean;
  var
    obj, i: integer;
    C: char;
    S: string;
  begin
    Result := false;

    obj := 0;
    for i := P downto 1 do
    begin
      C := Memory[i];

      if (obj <> 0) then
      begin
        if (C in (STR_PREPS + IGNORS)) then
        begin
          S := Copy(Memory, i+1, obj-i);
          P := IntPos(StringHash(S), pointer(@STD_HASHES), Length(STD_HASHES));

          Result := (P >= 0) and (SameStrings(S, STD_NAME_SPACES[P]));
          exit;
        end;
      end else
      if (not (C in IGNORS)) then
      begin
        obj := i;
        if (C in STR_PREPS) then exit;
      end;
    end;
  end;

var
  C: char;
  FuncFound, IgnoresFound: boolean;
  P, i: integer;
begin
  P := 0;
 
  while true do
  begin
    P := CharPosEx('(', Memory, P+1);
    if (P = 0) then break;

    FuncFound := false;
    IgnoresFound := false;
    for i := P-1 downto 1 do
    begin
      C := Memory[i];

      if (FuncFound) then
      begin
        if (C = '.') then
        begin
          if (i <> 1) and (Memory[i-1] <> '.'{�������� ..})
          and (not TestStdNameSpace(i-1)) then Memory[i] := ':'; {+Unique}

          break;
        end;

        if (not IgnoresFound) then
        begin
          IgnoresFound := (C in IGNORS);
          if (IgnoresFound) then continue;
        end;

        // ���� ������ ���� (� ��� �� �����) �� ��������� ����
        if (C in STR_PREPS) then break;

        // ���� ������ �� ���� � �� ������������ ������ (���� ������������ ��� �����������) - ������ ��� ���� ����������� ������� 
        if (IgnoresFound) and (not (C in IGNORS)) then break;

        continue;
      end else
      begin
        FuncFound := not(C in SPACES);
        if (FuncFound{�� ������}) and (C in (STR_PREPS + ENTER)) {��������� ��� ������ ������} then break;
        continue;
      end;

      break;
    end;
  end;
end;             *)
                       (*
// �������� �������
procedure TLua.InternalLoadScript(var Memory: string; const UnitName, FileName: string; CodeAddr: pointer);
var
  ret, unit_index: integer;
  internal_exception: Exception;
  AUnit, LastUnit: TLuaUnit;
  CW: word;

  // � ������ ������ �������� ������������ ������ ���� � Lua
  // ��� ���� ��������� Exception - ����� �� ����� �����������
  procedure OnExceptionRetrieve(const E: Exception);
  begin
    internal_exception := Exception(E.ClassType.NewInstance);
    CopyObject(internal_exception, E);
    AUnit.Free;

    if (LastUnit <> nil) then
    begin
      Memory := LastUnit.Text;
      PreprocessScript(Memory);
      try
        ret := luaL_loadbuffer(Handle, pchar(Memory), Length(Memory), pchar(LastUnit.Name));
        if (ret = 0) then ret := lua_pcall(Handle, 0, 0, 0);
        if (ret = 0) then {ret := }lua_gc(Handle, 2{LUA_GCCOLLECT}, 0);
      except
      end;
    end;
  end;
begin
  // ������������ � �������
  if (UnitName = '') then
  begin
    AUnit := nil;
    LastUnit := nil;
    unit_index := -1;
  end else
  begin
    if (UnitName[1] = #32) or (UnitName[Length(UnitName)] = #32) then
    ELua.Assert('Unit name "%s" contains left or/and right spaces', [UnitName], CodeAddr);
    //UnitName := StringLower(UnitName);

    // ���������� ����
    LastUnit := Self.UnitByName[UnitName];
    unit_index := IntPos(integer(LastUnit), pinteger(FUnits), Length(FUnits));

    // ���� ������� ���� - ����������, ���� ������ ����� � �������������
    if (LastUnit <> nil) and (SameStrings(LastUnit.Text, Memory)) then
    begin
      AUnit := LastUnit;
      LastUnit := nil;
    end else
    begin
      AUnit := TLuaUnit.Create;
      AUnit.FName := UnitName;
      AUnit.FFileName := FileName;
      AUnit.FText := Memory;
      AUnit.InitializeLinesInfo();
    end;
  end;


  // ��������� ����
  // ���� �� ������ �������, �� ��������/�������� ���� � ������
  // ���� ������� ��� �� RunScript �����
  internal_exception := nil;
  try
    // ��������� �������������
    PreprocessScript(Memory);

    // ��������� ������
    if (not FInitialized) then INITIALIZE_NAME_SPACE();

    // ��������� �����
    begin
      CW := Get8087CW();
      Set8087CW($037F {default intel C++ mode});
      try
        ret := luaL_loadbuffer(Handle, pansichar(Memory), Length(Memory), pansichar(UnitName));
      finally
        Set8087CW(CW);
      end;
    end;

    // �����, ������, ��������
    if (ret = 0) then ret := lua_pcall(Handle, 0, 0, 0);
    if (ret = 0) then ret := lua_gc(Handle, 2{LUA_GCCOLLECT}, 0);
    if (ret <> 0) then Check(ret, CodeAddr, AUnit);

    // ������������� ����� ������ �������, ������� � ������ ������
    if (unit_index{���� � ����� ������ ��� ���} >= 0) then
    begin
      if (LastUnit <> nil) then LastUnit.Free;
      FUnits[unit_index] := AUnit;
    end else
    if (AUnit <> nil) then
    begin
      unit_index := FUnitsCount;
      inc(FUnitsCount);
      SetLength(FUnits, FUnitsCount);
      FUnits[unit_index] := AUnit;
    end;
  except
    on E: Exception do OnExceptionRetrieve(E);
  end;
  
  if (internal_exception <> nil) then raise internal_exception at CodeAddr;
end;        *)
            (*
// �������� ������� ���� ��� ������� �����: �������� ������, ��������, �������� � ��������
function  TLua.push_userdata(const ClassInfo: TLuaClassInfo; const gc_destroy: boolean; const Data: pointer): PLuaUserData;
var
  DataSize: integer;
  SimpleFill: boolean;
begin

  with ClassInfo do
  if (not gc_destroy) or (_ClassKind = ckClass) then
  begin
    // ������� �������. sizeof(Result^) = sizeof(TLuaUserData)
    Result := PLuaUserData(lua_newuserdata(Handle, sizeof(TLuaUserData)));
    Result.instance := Data;
    pinteger(@Result.kind)^ := 0; // ��� �����

    case (_ClassKind) of
       ckArray: begin
                  Result.kind := ukArray;
                  Result.array_params := PLuaArrayInfo(_Class).Dimention shl 4;
                  Result.ArrayInfo := PLuaArrayInfo(_Class);
                end;
         ckSet: begin
                  Result.kind := ukSet;
                  Result.SetInfo := PLuaSetInfo(_Class);
                end;
    else
      Result.gc_destroy := gc_destroy; // ����� ���� true ��� _ClassKind = ckClass
      Result.ClassIndex := _ClassIndex;
      { kind �� ��������� = ukInstance }
    end;
  end else
  begin
    // ��������� ��� ������ � ��� "���� �������"
    case (_ClassKind) of
      ckRecord: DataSize := PLuaRecordInfo(_Class).FSize;
       ckArray: DataSize := PLuaArrayInfo(_Class).FSize;
    else
      // ckSet
      DataSize := PLuaSetInfo(_Class).FSize;
    end;
    Result := PLuaUserData(lua_newuserdata(Handle, sizeof(TLuaUserData)+DataSize));
    Result.instance := pointer(integer(Result)+sizeof(TLuaUserData));
    pinteger(@Result.kind)^ := 0; // ��� �����
    Result.gc_destroy := gc_destroy;

    // ����������� ��� ��������, ����� ��������� �� ���������� ������
    if (Data = nil) then SimpleFill := true
    else
    if (Data = FResultBuffer.Memory) then
    begin
      SimpleFill := true;
      FResultBuffer.tpinfo := nil;
    end
    else
    SimpleFill := false;


    // ����� � ����������� (����� simple)
    case (_ClassKind) of
      ckRecord: begin
                  Result.kind := ukInstance;
                  Result.ClassIndex := _ClassIndex;

                  if (not SimpleFill) then
                  with PLuaRecordInfo(_Class)^ do
                  if (FTypeInfo = nil) then SimpleFill := true
                  else
                  begin
                    FillChar(Result.instance^, DataSize, #0);
                    CopyRecord(Result.instance, Data, FTypeInfo);
                  end;
                end;

       ckArray: begin
                  Result.kind := ukArray;
                  Result.array_params := PLuaArrayInfo(_Class).Dimention shl 4;
                  Result.ArrayInfo := _Class;

                  if (not SimpleFill) then
                  with PLuaArrayInfo(_Class)^ do
                  if (FTypeInfo = nil) then SimpleFill := true
                  else
                  begin
                    if (IsDynamic) then
                    begin
                      pinteger(Result.instance)^ := pinteger(Data)^;
                      if (pinteger(Result.instance)^ <> 0) then DynArrayAddRef(Result.instance^);
                    end else
                    begin
                      FillChar(Result.instance^, DataSize, #0);
                      CopyArray(Result.instance, Data, FTypeInfo, FItemsCount);
                    end;
                 end;
               end;
      else
        // ckSet
        Result.kind := ukSet;
        Result.SetInfo := _Class;
        SimpleFill := true;
    end;

    // ������� �����������
    if (SimpleFill) then
    begin
      if (Data <> nil) then Move(Data^, Result.instance^, DataSize)
      else FillChar(Result.instance^, DataSize, #0);
    end;
  end;


  // �������� �����������
  lua_rawgeti(Handle, LUA_REGISTRYINDEX, ClassInfo.Ref); // global_push_value(Ref);
  lua_setmetatable(Handle, -2);
end;
        *)
          (*
// �������� ��������
function  TLua.push_difficult_property(const Instance: pointer; const PropertyInfo: TLuaPropertyInfo): PLuaUserData;
var
  Size: integer;
  array_params: byte;
  gc_destroy: boolean;
  Parameters: PLuaRecordInfo;
begin
  // ����������
  Parameters := PropertyInfo.Parameters;
  case (integer(Parameters)) of
    integer(INDEXED_PROPERTY): begin
                                 Size := sizeof(TLuaUserData) + sizeof(integer);
                                 gc_destroy := false;
                                 array_params := (1 shl 4);
                               end;
      integer(NAMED_PROPERTY): begin
                                 Size := sizeof(TLuaUserData) + sizeof(string);
                                 gc_destroy := true;
                                 array_params := (1 shl 4);
                               end;
  else
    Size := (sizeof(TLuaUserData) + Parameters.Size + 3) and (not 3);
    gc_destroy := (Parameters.FTypeInfo <> nil);

    array_params := Length(ClassesInfo[Parameters.FClassIndex].Properties);
    if (array_params > 15) then array_params := 15;
    array_params := (array_params shl 4);
  end;

  // ����������
  Result := PLuaUserData(lua_newuserdata(Handle, Size));
  FillChar(Result^, Size, #0);
  Result.instance := Instance;
  Result.kind := ukProperty;
  Result.array_params := array_params;
  Result.gc_destroy := gc_destroy;
  Result.PropertyInfo := @PropertyInfo;

  // �������� �����������
  lua_rawgeti(Handle, LUA_REGISTRYINDEX, mt_properties); // global_push_value(Ref);
  lua_setmetatable(Handle, -2);
end;   *)
         (*

function TLua.push_variant(const Value: Variant): boolean;
type
  TDateProc = procedure(const DateTime: TDateTime; var Ret: string);
  TIntToStr = procedure(const Value: integer; var Ret: string);
  
var
  VType: integer;
  PValue: pointer;
begin
  // �������� ��� � ��������� �� ��������
  VType := TVarData(Value).VType;
  PValue := @TVarData(Value).VWords[3];

  // ���� Variant ������ �� ������
  if (VType and varByRef <> 0) then
  begin
    VType := VType and (not varByRef);
    PValue := ppointer(PValue)^;
  end;

  // push
  case (VType) of
    varEmpty, varNull, varError{EmptyParam}: lua_pushnil(Handle);
    varSmallint: lua_pushinteger(Handle, PSmallInt(PValue)^);
    varInteger : lua_pushinteger(Handle, PInteger(PValue)^);
    varSingle  : lua_pushnumber(Handle, PSingle(PValue)^);
    varDouble  : lua_pushnumber(Handle, PDouble(PValue)^);
    varCurrency: lua_pushnumber(Handle, PCurrency(PValue)^);
    varDate    : with FBufferArg do
                 begin
                   if (str_data <> '') then str_data := '';
                   case InspectDateTime(PValue) of
                     0: TDateProc(@DateTimeToStr)(PDate(PValue)^, str_data);
                     1: TDateProc(@DateToStr)(PDate(PValue)^, str_data);
                     2: TDateProc(@TimeToStr)(PDate(PValue)^, str_data);
                   end;
                   lua_push_pascalstring(Handle, str_data);
                 end;
    varOleStr  : with FBufferArg do
                 begin
                   str_data := PWideString(PValue)^;
                   lua_push_pascalstring(Handle, str_data);
                 end;
    varBoolean : lua_pushboolean(Handle, PBoolean(PValue)^);
    varShortInt: lua_pushinteger(Handle, PShortInt(PValue)^);
    varByte    : lua_pushinteger(Handle, PByte(PValue)^);
    varWord    : lua_pushinteger(Handle, PWord(PValue)^);
    varLongWord: lua_pushnumber(Handle, PLongWord(PValue)^);
    varInt64   : lua_pushnumber(Handle, PInt64(PValue)^);
    varString  : lua_push_pascalstring(Handle, PString(PValue)^);
  else
    if (FBufferArg.str_data <> '') then FBufferArg.str_data := '';
    TIntToStr(@IntToStr)(VType, FBufferArg.str_data);
    push_variant := false;
    exit;
  end;

  push_variant := true;
end;           *)
                 (*
function TLua.push_luaarg(const LuaArg: TLuaArg): boolean;
type
  TIntToStr = procedure(const Value: integer; var Ret: string);
  
begin
  with LuaArg do
  case (LuaType) of
      ltEmpty: lua_pushnil(Handle);
    ltBoolean: lua_pushboolean(Handle, LongBool(Data[0]));
    ltInteger: lua_pushinteger(Handle, Data[0]);
     ltDouble: lua_pushnumber(Handle, pdouble(@Data)^);
     ltString: lua_push_pascalstring(Handle, str_data);
    ltPointer: lua_pushlightuserdata(Handle, pointer(Data[0]));
      ltClass: lua_rawgeti(Handle, LUA_REGISTRYINDEX, ClassesInfo[internal_class_index(pointer(Data[0]), true)].Ref);
     ltObject: begin
                 if (TClass(pointer(Data[0])^) = TLuaReference) then lua_rawgeti(Handle, LUA_REGISTRYINDEX, TLuaReference(Data[0]).Index)
                 else
                 push_userdata(ClassesInfo[internal_class_index(TClass(pointer(Data[0])^), true)], false, pointer(Data[0]));
               end;
     ltRecord: begin
                 with PLuaRecord(@FLuaType)^, Info^ do
                 push_userdata(ClassesInfo[FClassIndex], not IsRef, Data).is_const := IsConst;
               end;
      ltArray: begin
                 with PLuaArray(@FLuaType)^, Info^ do
                 push_userdata(ClassesInfo[FClassIndex], not IsRef, Data).is_const := IsConst;
               end;
        ltSet: begin
                 with PLuaSet(@FLuaType)^, Info^ do
                 push_userdata(ClassesInfo[FClassIndex], not IsRef, Data).is_const := IsConst;
               end;
      ltTable: begin
                 FBufferArg.str_data := 'LuaTable';
                 push_luaarg := false;
                 exit;
               end;
  else
    if (FBufferArg.str_data <> '') then FBufferArg.str_data := '';
    TIntToStr(@IntToStr)(byte(FLuaType), FBufferArg.str_data);
    push_luaarg := false;
    exit;
  end;

  push_luaarg := true;
end;  *)

        (*
function TLua.push_argument(const Value: TVarRec): boolean;
type
  TIntToStr = procedure(const Value: integer; var Ret: string);
var
  Buf: array[0..3] of char;
begin
  with Value do
  case (VType) of
    vtInteger:   lua_pushinteger(Handle, VInteger);
    vtBoolean:   lua_pushboolean(Handle, VBoolean);
    vtChar:      begin
                   Buf[0] := VChar;
                   Buf[1] := #0;
                   lua_push_pchar(Handle, @Buf[0]);
                 end;
    vtExtended:  lua_pushnumber(Handle, VExtended^);
    vtString:    with FBufferArg do
                 begin
                   str_data := VString^;
                   lua_push_pascalstring(Handle, str_data);
                 end;
    vtPointer:   if (VPointer = nil) then lua_pushnil(Handle) else lua_pushlightuserdata(Handle, VPointer);
    vtPChar:     lua_push_pchar(Handle, VPChar);
    vtObject:    if (VObject = nil) then lua_pushnil(Handle) else
                 begin
                   if (TClass(pointer(VObject)^) = TLuaReference) then lua_rawgeti(Handle, LUA_REGISTRYINDEX, TLuaReference(VObject).Index)
                   else
                   push_userdata(ClassesInfo[internal_class_index(TClass(pointer(VObject)^), true)], false, pointer(VObject));
                 end;  
    vtClass:     if (VClass = nil) then lua_pushnil(Handle) else lua_rawgeti(Handle, LUA_REGISTRYINDEX, ClassesInfo[internal_class_index(pointer(VClass), true)].Ref);
    vtWideChar:  begin
                   integer(Buf) := 0;
                   PWideChar(@Buf)^ := VWideChar;
                   FBufferArg.str_data := PWideChar(@Buf);
                   lua_push_pascalstring(Handle, FBufferArg.str_data);
                 end;
    vtPWideChar: begin
                   FBufferArg.str_data := VPWideChar;
                   lua_push_pascalstring(Handle, FBufferArg.str_data);
                 end;
    vtAnsiString:lua_push_pascalstring(Handle, string(VAnsiString));
    vtCurrency:  lua_pushnumber(Handle, VCurrency^);
    vtVariant:   begin
                   push_argument := push_variant(VVariant^);
                   exit;
                 end;  
    vtWideString:begin
                   FBufferArg.str_data := pwidestring(VWideString)^;
                   lua_push_pascalstring(Handle, FBufferArg.str_data);
                 end;
    vtInt64:     lua_pushnumber(Handle, VInt64^);
  else
    if (FBufferArg.str_data <> '') then FBufferArg.str_data := '';
    TIntToStr(@IntToStr)(VType, FBufferArg.str_data);
    push_argument := false;
    exit;
  end;

  push_argument := true;
end;        *)

{procedure TLua.stack_pop(const count: integer);
begin
  lua_settop(Handle, -count - 1);//lua_pop(Handle, count);
end; }      (*
procedure TLua.stack_pop(const count: integer);
asm
  not edx
  mov eax, [eax + TLua.FHandle]
  push edx
  push eax
  call lua_settop
  add esp, 8
end;       *)
                     (*
function TLua.stack_variant(var Ret: Variant; const StackIndex: integer): boolean;
var
  VarData: TVarData absolute Ret;
  Number: double;
  IntValue: integer absolute Number;
  luatype: integer;
begin
  // ������� ���� ��� �����
  if (VarData.VType = varString) or (not (VarData.VType in VARIANT_SIMPLE)) then VarClear(Ret);

  // ��������� ����������
  luatype := lua_type(Handle, StackIndex);
  case (luatype) of
        LUA_TNIL: begin
                    VarData.VType := varEmpty;
                  end;  
    LUA_TBOOLEAN: begin
                    VarData.VType := varBoolean;
                    VarData.VBoolean := lua_toboolean(Handle, StackIndex);
                  end;
     LUA_TNUMBER: if (NumberToInteger(Number, Handle, StackIndex)) then
                  begin
                    VarData.VType := varInteger;
                    VarData.VInteger := IntValue;
                  end else
                  begin
                    VarData.VType := varDouble;
                    VarData.VDouble := Number;
                  end;
     LUA_TSTRING: begin
                    VarData.VType := varString;
                    VarData.VInteger := 0;

                    { Unicode ??? todo }
                    lua_to_pascalstring(string(VarData.VString), Handle, StackIndex);
                  end;

  else
    VarData.VType := varEmpty;

    // ��������� ��������
    FBufferArg.str_data := LuaTypeName(luatype);

    // ��������� - false
    stack_variant := false;
    exit;
  end;

  stack_variant := true;
end;         *)
               (*
function TLua.stack_luaarg(var Ret: TLuaArg; const StackIndex: integer; const lua_table_available: boolean): boolean;
var
  userdata: PLuaUserData;
  ClassIndex: integer;
  LuaTable: PLuaTable;
  luatype: integer;
begin
  Result := true;

  Ret.FLuaType := ltEmpty;
  luatype := lua_type(Handle, StackIndex);
  case (luatype) of
    LUA_TNIL          : {�� ������};
    LUA_TBOOLEAN      : begin
                          //Ret.AsBoolean := lua_toboolean(Handle, StackIndex);
                          Ret.FLuaType := ltBoolean;
                          Ret.Data[0] := ord(lua_toboolean(Handle, StackIndex));
                        end;
    LUA_TNUMBER       : begin
                          // Ret.AsDouble := lua_tonumber(Handle, StackIndex); // �������������� �������� �� Int ��������
                          if (NumberToInteger(Ret.Data, Handle, StackIndex)) then
                          Ret.FLuaType := ltInteger else Ret.FLuaType := ltDouble;
                        end;
    LUA_TSTRING       : begin
                          // Ret.AsString := lua_tolstring(Handle, StackIndex, 0);
                          // �� ��������� LStrClr � HandleFinally
                          Ret.FLuaType := ltString;
                          lua_to_pascalstring(Ret.str_data, Handle, StackIndex);
                        end;
    LUA_TLIGHTUSERDATA: begin
                          // Ret.AsPointer := lua_touserdata(Handle, StackIndex);
                          Ret.FLuaType := ltPointer;
                          pointer(Ret.Data[0]) := lua_touserdata(Handle, StackIndex);
                        end;
    LUA_TFUNCTION     : {��������� �� �������}
                        begin
                          // Ret.AsPointer := CFunctionPtr(lua_tocfunction(Handle, StackIndex));
                          Ret.FLuaType := ltPointer;
                          pointer(Ret.Data[0]) := CFunctionPtr(lua_tocfunction(Handle, StackIndex));

                          // ����� ���� ���-�� ��� ?
                          if (dword(Ret.Data[0]) >= $FE000000) then
                          begin
                            Ret.FLuaType := ltInteger;
                            Ret.Data[0] := Ret.Data[0] and $00FFFFFF;
                          end;
                        end;

    LUA_TUSERDATA     : begin
                          // ������ ������ ��� ��������� ��� ������ ��� ...
                          userdata := lua_touserdata(Handle, StackIndex);
                          Result := (userdata <> nil);

                          if (Result) then
                          with userdata^ do
                          case kind of
                             ukInstance: with ClassesInfo[ClassIndex] do
                                         if (_ClassKind = ckClass) then
                                         begin
                                           if (instance <> nil) then
                                           begin
                                             // Ret.AsObject := TObject(instance);
                                             Ret.FLuaType := ltObject;
                                             pointer(Ret.Data[0]) := instance;
                                           end;
                                         end else
                                         begin
                                           // Ret.AsRecord := LuaRecord(instance, PLuaRecordInfo(_Class), not gc_destroy, is_const);
                                           Ret.FLuaType := ltRecord;
                                           with PLuaRecord(@Ret.FLuaType)^ do
                                           begin
                                             Data := instance;
                                             Info := PLuaRecordInfo(_Class);
                                             FIsRef := not gc_destroy;
                                             FIsConst := is_const;
                                           end;
                                         end;

                                ukArray: begin
                                           // ckArray
                                           if (array_params and $f = 0) then
                                           begin
                                             // Ret.AsArray := LuaArray(instance, ArrayInfo, not gc_destroy, is_const)
                                             Ret.FLuaType := ltArray;
                                             with PLuaArray(@Ret.FLuaType)^ do
                                             begin
                                               Data := instance;
                                               Info := ArrayInfo;
                                               FIsRef := not gc_destroy;
                                               FIsConst := is_const;
                                             end;
                                           end else
                                           begin
                                             // Ret.AsPointer := instance;
                                             Ret.FLuaType := ltPointer;
                                             pointer(Ret.Data[0]) := instance;
                                           end;
                                         end;

                                  ukSet: begin
                                           // Ret.AsSet := LuaSet(instance, SetInfo, not gc_destroy, is_const);
                                           Ret.FLuaType := ltSet;
                                           with PLuaSet(@Ret.FLuaType)^ do
                                           begin
                                             Data := instance;
                                             Info := SetInfo;
                                             FIsRef := not gc_destroy;
                                             FIsConst := is_const;
                                           end;
                                         end;

                            ukProperty: Result := false; // Ret.Empty ��� = true
                          end;

                          if (not Result) then
                          GetUserDataType(FBufferArg.str_data, Self, userdata);
                        end;
    LUA_TTABLE        : begin
                          // TClass, Info ��� �������
                          ClassIndex := LuaTableToClass(Handle, StackIndex);

                          if (ClassIndex >= 0) then
                          begin
                            with ClassesInfo[ClassIndex] do
                            if (_ClassKind = ckClass) then
                            begin
                              // Ret.AsClass := TClass(_Class);
                              Ret.FLuaType := ltClass;
                              pointer(Ret.Data[0]) := _Class;
                            end else
                            begin
                              // ���������� �� ���������, ������� ��� ���������
                              // Ret.AsPointer := _Class;
                              Ret.FLuaType := ltPointer;
                              pointer(Ret.Data[0]) := _Class;
                            end;
                          end else
                          if (lua_table_available) then
                          begin
                            // ���-�������
                            Ret.FLuaType := ltTable;
                            LuaTable := PLuaTable(@Ret.FLuaType);
                            pinteger(@LuaTable.align)^ := 0; // ������ �������� align

                            LuaTable.Index_ := StackIndex;
                            LuaTable.Lua := Self;
                          end else
                          begin
                            Result := false;
                            FBufferArg.str_data := LuaTypeName(luatype{LUA_TTABLE});
                          end;
                        end;
    else
      // ��������� ��������
      FBufferArg.str_data := LuaTypeName(luatype);
      Result := false;
  end;
end;       *)
             (*
procedure TLua.global_alloc_ref(var ref: integer);
begin
  if (ref = 0) then
  begin
    dec(FRef); 
    ref := FRef;
  end;
end;  *)
          (*
procedure TLua.global_free_ref(var ref: integer);
begin
  if (ref < 0) then
  begin
    lua_pushnil(Handle);
    lua_rawseti(Handle, LUA_REGISTRYINDEX, ref);
    ref := 0;
  end;
end;      *)
              (*
procedure TLua.global_fill_value(const ref: integer);
{begin
  if (ref <= 0) then stack_pop()
  else lua_rawseti(Handle, LUA_REGISTRYINDEX, ref);
end;}
asm
  mov ecx, [eax + TLua.FHandle]
  test edx, edx
  jl @rawset
    mov edx, 1
    jmp TLua.stack_pop
@rawset:
  push edx
  push LUA_REGISTRYINDEX
  push ecx
  call [lua_rawseti]
  add esp, 12
end;      *)

(*procedure TLua.global_push_value(const ref: integer);
{begin
  if (ref <= 0) then lua_pushnil(Handle)
  else lua_rawgeti(Handle, LUA_REGISTRYINDEX, ref);
end;}
asm
  mov ecx, [eax + TLua.FHandle]
  test edx, edx
  jl @rawget
    push ecx
    call [lua_pushnil]
    pop eax
    ret
@rawget:
  push edx
  push LUA_REGISTRYINDEX
  push ecx
  call [lua_rawgeti]
  add esp, 12
end;    *)
                          (*
// Index - ������� ���������� � ���������� ������ GlobalVariables ���� ��������� = true
// ���� false, �� Index = place � ������� NameSpaceHash
// ���� ��������� ���� auto_create, �� ���������� ��������, �� ��������� ������� False
function  TLua.GlobalVariablePos(const Name: pchar; const NameLength: integer; var Index: integer; const auto_create: boolean): boolean;
var
  NameHash, Len, Ret: integer;
begin
  NameHash := StringHash(Name, NameLength);
  Len := Length(NameSpaceHash);
  Ret := InsortedPlace8(NameHash, pointer(NameSpaceHash), Len);

  // �����
  while (Ret < Len) and (NameSpaceHash[Ret].Hash = NameHash) do
  begin
    Index := NameSpaceHash[Ret].Index;
    if (SameStrings(GlobalVariables[Index]._Name, Name, NameLength)) then
    begin
      Result := true;
      exit;
    end;

    inc(Ret);
  end;

  // �� ������
  Index := Ret;
  Result := false;

  // ���� ���������� �������
  if (auto_create) then
  begin
    Len := Length(GlobalVariables);
    SetLength(GlobalVariables, Len+1);

    // ������������� ����������
    with GlobalVariables[Len] do
    begin
      _Name := Name;
      _Kind := low(TLuaGlobalKind);
      IsConst := false;
      Ref := 0; 
    end;

    // ���������� � Hash-������
    with TLuaHashIndex(DynArrayInsert(GlobalNative.NameSpace, typeinfo(TLuaHashIndexDynArray), Ret)^) do
    begin
      Hash := NameHash;
      Index := Len;
    end;

    // ���������
    Index := Len;
  end;
end;      *)
            (*

procedure __TLuaRunScript(const Self: TLua; const Script: string; const ReturnAddr: pointer);
var
  Memory: string;
begin
  Memory := Script;
  Self.InternalLoadScript(Memory, '', '', ReturnAddr);
end;        *)
              (*
procedure TLua.RunScript(const Script: string);
asm
  mov ecx, [esp]
  jmp __TLuaRunScript
end;          *)
                (*
procedure __TLuaLoadScript_file(const Self: TLua; const FileName: string; const ReturnAddr: pointer);
var
  F: TFileStream;
  Size: integer;
  Memory: string;
begin
  if (not FileExists(FileName)) then
  begin
    ELua.Assert('File "%s" not found', [FileName], ReturnAddr);
  end;

  F := SharedFileStream(FileName);
  try
    Size := F.Size;
    if (Size <> 0) then
    begin
      SetLength(Memory, Size);
      F.Read(pointer(Memory)^, Size);
    end;
  finally
    F.Free;
  end;

  Self.InternalLoadScript(Memory, ExtractFileName(FileName), FileName, ReturnAddr);
end;            *)
                  (*
procedure TLua.LoadScript(const FileName: string);
asm
  mov ecx, [esp]
  jmp __TLuaLoadScript_file
end;

procedure __TLuaLoadScript_buffer(const Self: TLua; const ScriptBuffer: pointer;
          const ScriptBufferSize: integer; const UnitName: string; const ReturnAddr: pointer);
var
  Memory: string;
begin
  if (ScriptBufferSize >= 0) then
  begin
    SetLength(Memory, ScriptBufferSize);
    Move(ScriptBuffer^, pointer(Memory)^, ScriptBufferSize);
  end;

  Self.InternalLoadScript(Memory, UnitName, '', ReturnAddr);
end;

procedure TLua.LoadScript(const ScriptBuffer: pointer; const ScriptBufferSize: integer; const UnitName: string);
asm
  pop ebp
  push [esp]
  jmp __TLuaLoadScript_buffer
end;         *)

               (*

function TLua.internal_class_index_by_name(const AName: string): integer;
{begin
  for Result := 0 to Length(ClassesInfo)-1 do
  if (SameStrings(AName, ClassesInfo[Result]._ClassName)) then exit;

  Result := -1;
end;}
var
  Len, Index: integer;
  NameHash: integer;
  HashInfo: ^TLuaHashIndex;
begin
  NameHash := StringHash(AName);
  Len := Length(ClassesIndexesByName);
  Index := InsortedPlace8(NameHash, pointer(ClassesIndexesByName), Len);

  HashInfo := pointer(integer(ClassesIndexesByName) + Index*sizeof(TLuaHashIndex));
  while (Index < Len) and (HashInfo.Hash = NameHash) do
  begin
    if (SameStrings(AName, ClassesInfo[HashInfo.Index]._ClassName)) then
    begin
      Result := HashInfo.Index;
      exit;
    end;

    inc(Index);
    inc(HashInfo);
  end;

  Result := -1;
end;            *)
                  (*
function TLua.GetRecordInfo(const Name: string): PLuaRecordInfo;
var
  Index: integer;
begin
  Index := internal_class_index_by_name(Name);

  if (Index < 0) then GetRecordInfo := nil
  else
  with ClassesInfo[Index] do
  if (_ClassKind <> ckRecord) then GetRecordInfo := nil
  else
  GetRecordInfo := _Class;
end;          *)
                (*
function TLua.GetArrayInfo(const Name: string): PLuaArrayInfo;
var
  Index: integer;
begin
  Index := internal_class_index_by_name(Name);

  if (Index < 0) then GetArrayInfo := nil
  else
  with ClassesInfo[Index] do
  if (_ClassKind <> ckArray) then GetArrayInfo := nil
  else
  GetArrayInfo := _Class;
end;       *)
             (*
function TLua.GetSetInfo(const Name: string): PLuaSetInfo;
var
  Index: integer;
begin
  Index := internal_class_index_by_name(Name);

  if (Index < 0) then GetSetInfo := nil
  else
  with ClassesInfo[Index] do
  if (_ClassKind <> ckSet) then GetSetInfo := nil
  else
  GetSetInfo := _Class;
end;       *)
             (*
procedure __TLuaGetVariable(const Self: TLua; const Name: string; var Result: Variant; const ReturnAddr: pointer);
var
  modify_info: TLuaGlobalModifyInfo;
begin
  modify_info.Name := Name;
  modify_info.CodeAddr := ReturnAddr;
  modify_info.IsVariant := true;
  modify_info.V := @Result;

  Self.__global_index(true, modify_info);
end;      *)
          (*
function TLua.GetVariable(const Name: string): Variant;
asm
  push [esp]
  jmp __TLuaGetVariable
end;   *)

                  (*
procedure __TLuaSetVariable(const Self: TLua; const Name: string; const Value: Variant; const ReturnAddr: pointer);
var
  modify_info: TLuaGlobalModifyInfo;
begin
  modify_info.Name := Name;
  modify_info.CodeAddr := ReturnAddr;
  modify_info.IsVariant := true;
  modify_info.V := @Value;

  Self.__global_newindex(true, modify_info);
end;

procedure TLua.SetVariable(const Name: string; const Value: Variant);
asm
  push [esp]
  jmp __TLuaSetVariable
end;                    *)
                          (*
procedure __TLuaGetVariableEx(const Self: TLua; const Name: string; var Result: TLuaArg; const ReturnAddr: pointer);
var
  modify_info: TLuaGlobalModifyInfo;
begin
  modify_info.Name := Name;
  modify_info.CodeAddr := ReturnAddr;
  modify_info.IsVariant := false;
  modify_info.Arg := @Result;

  Self.__global_index(true, modify_info);
end;              *)
                      (*
function  TLua.GetVariableEx(const Name: string): TLuaArg;
asm
  push [esp]
  jmp __TLuaGetVariableEx
end;                *)
                      (*
procedure __TLuaSetVariableEx(const Self: TLua; const Name: string; const Value: TLuaArg; const ReturnAddr: pointer);
var
  modify_info: TLuaGlobalModifyInfo;
begin
  modify_info.Name := Name;
  modify_info.CodeAddr := ReturnAddr;
  modify_info.IsVariant := false;
  modify_info.Arg := @Value;

  Self.__global_newindex(true, modify_info);
end;             *)
                   (*
procedure TLua.SetVariableEx(const Name: string; const Value: TLuaArg);
asm
  push [esp]
  jmp __TLuaSetVariableEx
end;              *)

                    (*
// ���������������� ���������� ����������
// ��� ������������� �������/������� Ref � Index
// ������������� ��������� ��� ������� exception
// Kind - Type (Class ��� Record), Variable, Proc ��� Enum
// ������������� gkLuaData ���������� � global_newindex ���� ���������� �� �������
function TLua.internal_register_global(const Name: string; const Kind: TLuaGlobalKind; const CodeAddr: pointer): PLuaGlobalVariable;
const
  KIND_NAMES: array[TLuaGlobalKind] of string = ('type', 'variable', 'method', 'enum', '');
var
  Ind: integer;
  new: boolean;
begin
  // �������� �� ������������ �����
  if (not IsValidIdent(Name)) then
  ELua.Assert('Non-supported %s name "%s"', [KIND_NAMES[Kind], Name], CodeAddr);

  // ������� ��� ����� ���������
  new := (not GlobalVariablePos(pchar(Name), Length(Name), Ind, true));
  Result := @GlobalVariables[Ind];

  // ������������� ���������
  if (not new) then
  begin
    // ���� Kind-� �����, �� ���������� ���, ������ ����� �������� ���������
    // ���� �� �����, �� 100% ��������
    // ���� ������� �������� �� LuaData, �� 100% exception
    if (Result._Kind = Kind) then
    begin
      exit;
    end;

    // ���� ������� �������� �������� � GLOBAL_INDEX,
    // �� ���� ���������� ��� � nil, ���� ����������������� Ref
    if (Result._Kind = gkLuaData) then
    begin
      if (Kind in GLOBAL_INDEX_KINDS) then
      begin
        // �������� lua-����������, �� Ref �� �������
        lua_pushnil(Handle);
        global_fill_value(Result.Ref);
      end else
      begin
        // ��� ������ ������ ����� ���������������� ������ �������� ��������
        // ���������� ��������� ��� ���������� ���������
        global_free_ref(Result.Ref);
      end;

    end else
    begin
      ELua.Assert('Global %s "%s" is already registered', [KIND_NAMES[Result._Kind], Name], CodeAddr);
    end;
  end;


// ������������������� ����������.
// �������� ���� � new ������, ���� ����� ���� ��� ������������ ��������
// � Ref ��� ��������. ���� ����� ���� � ������� � ������ new
  Result._Kind := Kind;
  Result.IsConst := (Kind in CONST_GLOBAL_KINDS);

  // Ref ��� Index
  if (Kind in NATIVE_GLOBAL_KINDS) then
  begin
    Result.Index := GlobalNative.InternalAddName(Name, (Kind = gkProc), FInitialized, CodeAddr);
  end else
  begin
    global_alloc_ref(Result.Ref);
  end;

  // ������ ���� ������������� ����������� ������������ ���
  if (Kind <> gkConst) then FInitialized := false;
end;               *)
                     (*
// ������� � ������������������� �����������
function  TLua.internal_register_metatable(const CodeAddr: pointer; const GlobalName: string=''; const ClassIndex: integer = -1; const is_global_space: boolean = false): integer;
const
  LUA_GLOBALSINDEX = -10002;
  LUA_RIDX_GLOBALS = 2;
begin
  // �������� Ref
  // ���� ����� = ���������������� ����� ���������� ������� �������
  if (GlobalName <> '') then Result := internal_register_global(GlobalName, gkType, CodeAddr).Ref
  else
  begin
    Result := 0;
    global_alloc_ref(Result);
  end;

  // ������� �����������, ��������� ClassIndex
  lua_createtable(Handle, 0, 0);
  if (ClassIndex <> -1) then
  begin
    lua_pushinteger(Handle, integer(typeinfoTClass) or ClassIndex);
    lua_rawseti(Handle, -2, 0);
  end;
  global_fill_value(Result);


  if (is_global_space) then
  begin
    if (LUA_VERSION_52) then
    begin
      lua_rawgeti(Handle, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
      global_push_value(Result);
      lua_setmetatable(Handle, -2);
      stack_pop();
    end else
    begin
      global_push_value(Result);
      lua_setmetatable(Handle, LUA_GLOBALSINDEX);
    end;
  end else
  begin
    global_push_value(Result);
    lua_pushvalue(Handle, 1);
    lua_setmetatable(Handle, -2);
    stack_pop();
  end;
end;       *)
             (*
function  TLua.internal_add_class_info(const is_global_space: boolean = false): integer;
var
  ClassInfo: ^TLuaClassInfo;
begin
  if (is_global_space) then
  begin
    Result := -1;
    ClassInfo := @GlobalNative;
  end else
  begin
    Result := Length(ClassesInfo);
    SetLength(ClassesInfo, Result+1);
    ClassInfo := @ClassesInfo[Result];
  end;

  // ����������
  ZeroMemory(ClassInfo, sizeof(TLuaClassInfo));
  ClassInfo._ClassIndex := Result;
  ClassInfo._DefaultProperty := -1;
  ClassInfo.ParentIndex := -1;
end;          *)
                (*
function  TLua.internal_add_class_index(const AClass: pointer; const AIndex: integer): integer;
begin
  Result := InsortedPlace8(integer(AClass), pointer(ClassesIndexes), Length(ClassesIndexes));
  with TLuaClassIndex(DynArrayInsert(ClassesIndexes, typeinfo(TLuaClassIndexDynArray), Result)^) do
  begin
    _Class := AClass;
    Index := AIndex;
  end;
end;      *)
            (*
function  TLua.internal_add_class_index_by_name(const AName: string; const AIndex: integer): integer;
var
  AHash: integer;
begin
  AHash := StringHash(AName);

  Result := InsortedPlace8(integer(AHash), pointer(ClassesIndexesByName), Length(ClassesIndexesByName));
  with TLuaClassIndex(DynArrayInsert(ClassesIndexesByName, typeinfo(TLuaClassIndexDynArray), Result)^) do
  begin
    _Class := pointer(AHash);
    Index := AIndex;
  end;
end;        *)

// ������ ����� ������ ������ � ������� ClassesInfo
//function TLua.internal_class_index(AClass: pointer; const look_class_parents: boolean): integer;
(*begin
  Result := -1;

  while (AClass <> nil) do
  begin
    Result := InsortedPos8(integer(AClass), ClassesIndexes);
    if (Result >= 0) or (not look_class_parents) then break;

    // look_parents-�������: TClass(AClass) := TClass(AClass).ClassParent;
    AClass := ppointer(integer(AClass) + vmtParent)^;
    {$ifndef fpc}if (AClass <> nil) then AClass := TClass(AClass^);{$endif}
  end;

  // ���������
  if (Result >= 0) then Result := ClassesIndexes[Result].Index;
end;*)  (*
asm
  test edx, edx
  jz   @fail
  mov  eax, [eax + TLua.ClassesIndexes]
  test eax, eax
  jnz @1
@fail:
  mov eax, -1
  ret
@1:
  push edi // look_class_parents
  push ebx // ��������� AClass
  // edx - ��������� �� ClassesIndexes, �� ���������� ��� ������ InsortedPlace
  // ecx - Length(ClassesIndexes), �� ���������� ��� ������ InsortedPlace

  mov ebx, edx
  mov edi, ecx
  mov edx, eax
  mov ecx, [eax-4]
  {$ifdef fpc} inc ecx {$endif}

@loop:
  mov eax, ebx
  call InsortedPlace8
  cmp eax, ecx  // if (Result >= ArrLength)
  jge @next

  // if (pinteger( integer(Arr)+Result*8 )^ <> Value)
  cmp ebx, [edx + eax*8]
  jne @next

  // return ClassesIndexes[Result].Index;
  mov eax, [edx + eax*8 + 4]
  jmp @exit

@next:
  test edi, edi
  jz @exit_fail // ���� �� look_class_parents
  
  { TClass(AClass) := TClass(AClass).ClassParent; }
  mov ebx, [ebx + vmtParent]
  {$ifndef fpc}
    test ebx, ebx
    jz @exit_fail
    mov ebx, [ebx]
  {$endif}
  test ebx, ebx
  jnz @loop

@exit_fail:
  mov eax, -1
@exit:
  pop ebx
  pop edi
end;   *)

            (*
// �������� �����, ���� ������ ���
// ���� UsePublished, �� ��������� ��� ��� �� �� ��������� � published
// ���� ��� �����������, �� ���������������� �� ��� ������������������ ������
function TLua.InternalAddClass(AClass: TClass; UsePublished: boolean; const CodeAddr: pointer): integer;
var
  InstanceSize: integer;
  ClassRegistrator: TClass;
  ClassParentIndex: integer;

  // �������� �� ����� ������������� lua
  function IsRegistrator(const _Class: TClass): boolean;
  begin
    Result := (_Class <> nil) and (EqualStrings('lua', Copy(_Class.ClassName, 1, 3)));
  end;

  // �������� ������ �� ����������� ������ �������
  procedure AddPublishedMethods(const _Class: TClass);
  type
    TMethodEntry = packed record
      len: Word;
      adr: Pointer;
      name: ShortString;
    end;
  var
    i: word;
    MC: pword;
    MethodEntry: ^TMethodEntry;
    MethodName: string;
  begin
    // Registrator mode
    if (ClassRegistrator <> nil) and (_Class.ClassParent <> AClass) then AddPublishedMethods(_Class.ClassParent);

    MC := pword(ppointer(integer(_Class)+vmtMethodtable)^);
    if (MC = nil) then exit;
    MethodEntry := pointer(integer(MC)+2);

    for i := 1 to MC^ do
    begin
      MethodName := MethodEntry.name;

      if (EqualStrings(Copy(MethodName, 1, 3), 'lua')) then
      begin
        Delete(MethodName, 1, 3);
        InternalAddProc(true, AClass, MethodName, -1, false, MethodEntry.adr, CodeAddr);
      end;

      inc(integer(MethodEntry), integer(MethodEntry.len));
    end;
  end;

  // �������� published-��������
  procedure AddPublishedProperties(const _Class: TClass);
  var
    PropCount, i, PropIndex: integer;
    tpinfo: TypInfo.PTypeInfo;
    PropList: TypInfo.PPropList;
    PropInfo: TypInfo.PPropInfo;
    PropName, Prefix: string;
    PropBase: TLuaPropertyInfoBase;
  begin
    tpinfo := _Class.ClassInfo;
    if (tpinfo = nil) then exit;

    PropCount := GetPropList(tpinfo, PropList);
    if (PropCount <> 0) then
    try
      Prefix := _Class.ClassName + '.';

      for i := 0 to PropCount-1 do
      begin
        PropInfo := PropList[i];
        PropName := PropInfo.Name;

        // �������� ��� ������ �� ���� ������ ������������
        if (ClassRegistrator <> nil) then
        with PropInfo^ do
        begin
          if ((dword(GetProc) >= $FF000000) and (integer(GetProc) and $00FFFFFF >= InstanceSize))
          or ((dword(SetProc) >= $FF000000) and (integer(SetProc) and $00FFFFFF >= InstanceSize)) then
          ELua.Assert('Class registrator "%s" can''t have own fields. Property "%s"', [ClassRegistrator.ClassName, PropName], CodeAddr);
        end;

        // �����������
        tpinfo := PropInfo.PropType{$ifndef fpc}^{$endif};
        PropBase := GetLuaPropertyBase(Self, Prefix, PropName, tpinfo, CodeAddr, true);
        PropIndex := ClassesInfo[Result].InternalAddName(PropName, false, FInitialized, CodeAddr);
        ClassesInfo[Result].Properties[{InvertIndex} not (PropIndex)].Fill(PropInfo, PropBase);
      end;
    finally
      FreeMem(PropList);
    end;  
  end;

  // ��� published ����. ������
  procedure AddPublishedFields(const _Class: TClass);
  type
    TUsedClassesTable = packed record
      Count: word;
      Classes: array[0..8191] of ^TClass;
    end;
    PClassFieldInfo = ^TClassFieldInfo;
    TClassFieldInfo = packed record
      Offset: integer;
      TypeIndex: Word;
      Name: ShortString;
    end;
    PClassFieldTable = ^TClassFieldTable;
    TClassFieldTable = packed record
      Count: word;
      UsedClasses: ^TUsedClassesTable;
      Fields: array[0..0] of TClassFieldInfo;
    end;
  var
    i: integer;
    Table: PClassFieldTable;
    Field: PClassFieldInfo;
  begin
    if (_Class = nil) then exit
    else AddPublishedFields(_Class.ClassParent);

    Table := PClassFieldTable(pointer(integer(_Class)+vmtFieldTable)^);
    if (Table = nil) then exit;

    // ����������� �������
    if (Table.UsedClasses <> nil) then
    for i := 0 to Table.UsedClasses.Count-1 do
    InternalAddClass(Table.UsedClasses.Classes[i]^, True, CodeAddr);

    // ����������� �����
    Field := @Table.Fields[0];
    for i := 0 to Table.Count-1 do
    begin
      // �������� ��� ������ �� ���� ������ ������������
      if (ClassRegistrator <> nil) and (Field.Offset >= InstanceSize) then
      ELua.Assert('Class registrator "%s" can''t have own fields. Field "%s"', [ClassRegistrator.ClassName, Field.Name], CodeAddr);

      // �����������
      InternalAddProperty(true, ClassesInfo[Result]._Class, Field.Name, typeinfo(TObject), false, false, pointer(Field.Offset), pointer(Field.Offset), nil, CodeAddr);
      inc(integer(Field), sizeof(integer)+sizeof(word)+sizeof(byte)+pbyte(@Field.Name)^);
    end;
  end;

begin
  if (AClass = nil) then
  ELua.Assert('AClass is not defined', [], CodeAddr);

  // ����� ���������
  Result := internal_class_index(AClass, false);
  if (Result >= 0) and (not UsePublished) then exit;

  // �������� �� ����� �����������
  if (not IsRegistrator(AClass)) then
  begin
    ClassRegistrator := nil;
  end else
  begin
    ClassRegistrator := AClass;

    while (AClass <> nil) do
    begin
      AClass := AClass.ClassParent;
      if (not IsRegistrator(AClass)) then break;
    end;

    if (AClass = nil) then
    ELua.Assert('ClassRegistrator is defined, but really Class not found', [], CodeAddr);

    // ����� ���������
    Result := internal_class_index(AClass, false);
  end;

  // ���� �� ���������������, �� ����������������, ��������������� ��� ���� ������
  if (Result < 0) then
  begin
    // �������� �� ��������� RecordInfo ��� ������ ����
    if (internal_class_index_by_name(AClass.ClassName) >= 0) then
    ELua.Assert('Type "%s" is already registered', [AClass.ClassName]);

    // ���������������� �������
    if (AClass.ClassParent = nil) then ClassParentIndex := -1
    else ClassParentIndex := InternalAddClass(AClass.ClassParent, UsePublished, CodeAddr);

    // ���������� � ������, ���������� � ������, ����������� �����������
    Result := internal_add_class_info();
    with ClassesInfo[Result] do
    begin
      _Class := AClass;
      _ClassKind := ckClass;      
      _ClassName := AClass.ClassName;
      ParentIndex := ClassParentIndex;
      Ref := internal_register_metatable(CodeAddr, _ClassName, Result);

      // �����������, ��������� ��������
      if (ClassParentIndex >= 0) then
      begin
        constructor_address := ClassesInfo[ClassParentIndex].constructor_address;
        constructor_args_count := ClassesInfo[ClassParentIndex].constructor_args_count;
        _DefaultProperty := ClassesInfo[ClassParentIndex]._DefaultProperty;
      end;
    end;

    // �������� � ������ �������� ������  
    internal_add_class_index(AClass, Result);
    internal_add_class_index_by_name(ClassesInfo[Result]._ClassName, Result);
  end;

  // �� ������������ ����� ������ � ��������
  InstanceSize := AClass.InstanceSize;
  if (ClassRegistrator <> nil) then
  begin
    // published-������
    AddPublishedMethods(ClassRegistrator);

    // published-��������
    AddPublishedProperties(ClassRegistrator);

    // published ���� � �� ������ (��� ���� published ����� � ����� - ������ � �.�. - ����������)
    AddPublishedFields(ClassRegistrator);
  end else
  if (UsePublished) then
  begin
    // ���������������� published-���������� ���� �� ����� ������
    AddPublishedMethods(AClass);
    AddPublishedProperties(AClass);
    AddPublishedFields(AClass);
  end;
end;     *)
           (*
// tpinfo ����� ����:
// - typeinfo(struct)
// - typeinfo(DynArray of struct)
// - sizeof(struct)
function TLua.InternalAddRecord(const Name: string; tpinfo, CodeAddr: pointer): integer;
var
  RecordTypeInfo: ptypeinfo;
  RecordSize: integer;
  TypeData: PTypeData;
  FieldTable: PFieldTable absolute TypeData;
  RecordInfo: PLuaRecordInfo;
begin
  if (not IsValidIdent(Name)) then
  ELua.Assert('Non-supported record type name ("%s")', [Name], CodeAddr);

  // ������� tpinfo, ����� sizeof � �������� typeinfo
  begin
    if (tpinfo = nil) then
    ELua.Assert('TypeInfo of record "%s" is not defined', [Name], CodeAddr);

    RecordTypeInfo := nil;
    RecordSize := 0;

    if (integer(tpinfo) < $FFFF) then
    begin
      // sizeof()
      RecordSize := integer(tpinfo);
    end else
    begin
      TypeData := GetTypeData(tpinfo);

      // ������ ��� ������������ ������
      if (TTypeInfo(tpinfo^).Kind in RECORD_TYPES) then
      begin
        RecordSize := FieldTable.Size;
        RecordTypeInfo := tpinfo;
      end else
      if (TTypeInfo(tpinfo^).Kind = tkDynArray) then
      begin
        RecordSize := TypeData.elSize;

        if (TypeData.elType <> nil) then
        begin
          RecordTypeInfo := TypeData.elType^;
          if (RecordTypeInfo <> nil) and (not (RecordTypeInfo.Kind in RECORD_TYPES)) then
          ELua.Assert('Sub dynamic type "%s" is not record type (%s)', [RecordTypeInfo.Name, TypeKindName(RecordTypeInfo.Kind)], CodeAddr);
        end;
      end else
      begin
        ELua.Assert('Type "%s" is not record and subdynamic type (%s)', [Name, TypeKindName(ptypeinfo(tpinfo).Kind)], CodeAddr);
      end;
    end;
  end;

  // ����� ���������
  if (RecordTypeInfo <> nil) then
  begin
    if (not SameStrings(RecordTypeInfo.Name, Name)) then
    ELua.Assert('Mismatch of names: typeinfo "%s" and "%s" as parameter "Name"', [RecordTypeInfo.Name, Name], CodeAddr);

    Result := internal_class_index(RecordTypeInfo);
  end else
  begin
    Result := -1;
  end;

  if (Result < 0) then Result := internal_class_index_by_name(Name);
  if (Result >= 0) then
  with ClassesInfo[Result] do
  begin
    if (_ClassKind <> ckRecord) then
    ELua.Assert('Type "%s" is already registered', [Name], CodeAddr);

    // �������� �� ������������
    with PLuaRecordInfo(_Class)^ do
    begin
      if (Size <> RecordSize) then
      ELua.Assert('Size of %s (%d) differs from the previous value (%d)', [Name, RecordSize, Size], CodeAddr);

      if (FTypeInfo = nil) then FTypeInfo := RecordTypeInfo
      else
      if (FTypeInfo <> RecordTypeInfo) then
      ELua.Assert('TypeInfo of "%s" differs from the previous value', [Name], CodeAddr);
    end;

    exit;
  end;

  // ����������������� RecordInfo
  new(RecordInfo);
  with RecordInfo^ do
  begin
    FLua := Self;
    FTypeInfo := RecordTypeInfo;
    FSize := RecordSize;
    FOperators := [];
    FOperatorCallback := nil;
  end;

  // �������� � ������ ClassesInfo
  Result := internal_add_class_info();
  with ClassesInfo[Result] do
  begin
    _Class := RecordInfo;
    _ClassKind := ckRecord;    
    _ClassName := Name;
    Ref := internal_register_metatable(CodeAddr, _ClassName, Result);

    RecordInfo.FName := Name;
    RecordInfo.FClassIndex := Result;
  end;

  // �������� � ������ �������� ������
  internal_add_class_index(RecordInfo, Result);
  internal_add_class_index_by_name(Name, Result);
  if (RecordTypeInfo <> nil) then internal_add_class_index(RecordTypeInfo, Result);
end; *)
       (*

// itemtypeinfo - ������� ��� ��� recordinfo ��� arrayinfo
function TLua.InternalAddArray(Identifier, itemtypeinfo, CodeAddr: pointer; const ABounds: array of integer): integer;
const
  STATIC_DYNAMIC: array[boolean] of string = ('static', 'dynamic');
var
  i: integer;
  Dest: TLuaArrayInfo;

  arraytypeinfo: ptypeinfo;
  PropertyInfo: PLuaPropertyInfo;

  elType: PPTypeInfo;
  FBufSize: integer;
  buftypeinfo: ptypeinfo;
  buftypekind: TTypeKind;
begin
  ZeroMemory(@Dest, sizeof(Dest));
  PropertyInfo := PLuaPropertyInfo(@Dest.ItemInfo);

  // �������������: ���, typeinfo
  if (Identifier = nil) then
  ELua.Assert('Array identifier is not defined', CodeAddr);
  try
    if (TTypeKind(Identifier^) in [tkArray, tkDynArray]) then
    begin
      arraytypeinfo := ptypeinfo(Identifier);
      Dest.FName := arraytypeinfo.Name;
    end else
    begin
      Dest.FName := pchar(Identifier); // todo Unicode ?
      arraytypeinfo := nil;
    end;
  except
    ELua.Assert('Array identifier is not correct', CodeAddr);
    Result := -1;
    exit;
  end;
  if (not IsValidIdent(Dest.Name)) then
  ELua.Assert('Non-supported array type name ("%s")', [Dest.Name], CodeAddr);

  // ���� ����������
  with Dest do
  begin
      // �������� ����������
      Result := internal_class_index_by_name(Name);
      if (Result < 0) and (arraytypeinfo <> nil) then Result := internal_class_index(arraytypeinfo);
      if (Result >= 0) and (ClassesInfo[Result]._ClassKind <> ckArray) then ELua.Assert('Type "%s" is already registered', [Name], CodeAddr);

      // IsDymanic
      FIsDynamic := (arraytypeinfo <> nil) and (arraytypeinfo.Kind = tkDynArray);
      FBoundsData := IntegerDynArray(ABounds);
      FBounds := pointer(FBoundsData);
      if (IsDynamic <> (Bounds=nil)) then
      begin
        if (IsDynamic) then ELua.Assert('Dynamic array "%s" has no bounds', [Name], CodeAddr)
        else ELua.Assert('Array information of "%s" is not defined', [Name], CodeAddr);
      end;

      // �������� itemtypeinfo, Kind, ������
      if (itemtypeinfo = nil) then
      ELua.Assert('"%s" registering... The typeinfo of %s array item is not defined', [Name, STATIC_DYNAMIC[IsDynamic]], CodeAddr);
      PropertyInfo.Base := GetLuaPropertyBase(Self, '', Name, ptypeinfo(itemtypeinfo), CodeAddr);
      itemtypeinfo := PropertyInfo.Base.Information;
      FItemSize := GetLuaItemSize(PropertyInfo.Base);
      if (FItemSize = 0) then ELua.Assert('"%s" registering... The size of %s array item is not defined', [Name, STATIC_DYNAMIC[IsDynamic]], CodeAddr);


      // ������� Dimention, �������� Bounds, Multiplies
      if (IsDynamic) then
      begin
          buftypeinfo := arraytypeinfo;
          while (buftypeinfo <> nil) do
          begin
            inc(FDimention);
            elType := GetTypeData(buftypeinfo).elType;

            if (elType = nil) then
            begin
              if (FItemSize = GetTypeData(buftypeinfo).elSize) then break;
            end else
            begin
              buftypeinfo := elType^;
              if (buftypeinfo = itemtypeinfo) then break;

              buftypekind := ptypeinfo(buftypeinfo).kind;
              if (buftypekind = tkDynArray) then
              begin
                if (PLuaArrayInfo(itemtypeinfo).FTypeInfo = buftypeinfo) then break;
                continue;
              end else
              if (buftypekind = tkArray) then
              begin
                if (PLuaArrayInfo(itemtypeinfo).FTypeInfo = buftypeinfo) or
                   (PLuaArrayInfo(itemtypeinfo).FSize = integer(PFieldTable(GetTypeData(buftypeinfo)).Size)) then break;
              end else
              if (buftypekind in RECORD_TYPES) then
              begin
                if (PLuaRecordInfo(itemtypeinfo).FTypeInfo = buftypeinfo) then break;
              end;
            end;

            ELua.Assert('Incorrect itemtypeinfo of dynamic array "%s"', [Name], CodeAddr);
          end;

          buftypeinfo := arraytypeinfo;
          SetLength(FMultiplies, Dimention);
          ptypeinfo(FMultiplies[0]) := buftypeinfo;
          for i := 1 to Dimention-1 do
          begin
            buftypeinfo := GetTypeData(buftypeinfo).elType^;
            ptypeinfo(FMultiplies[i]) := buftypeinfo;
          end;                       
      end else
      begin
        FDimention := Length(FBoundsData);
        if (Dimention and 1 = 1) then ELua.Assert('"%s" registering... Bounds size should be even. %d is an incorrect size', [Name, Dimention], CodeAddr);
        FDimention := FDimention div 2;

        for i := 0 to Dimention-1 do
        if (ABounds[i*2] > ABounds[i*2+1]) then
        ELua.Assert('"%s" registering... Incorrect bounds: "%d..%d"', [Name, ABounds[i*2], ABounds[i*2+1]], CodeAddr);

        SetLength(FMultiplies, Dimention);
        FMultiplies[Dimention-1] := FItemSize;
        for i := Dimention-2 downto 0 do
        FMultiplies[i] := FMultiplies[i+1]*(ABounds[(i+1)*2+1] - ABounds[(i+1)*2] + 1);
      end;


      // ���������� ���������� ��� �����������
      if (arraytypeinfo <> nil) then
      begin
        FTypeInfo := arraytypeinfo;
        FItemsCount := 1;

        if (IsDynamic) then
        begin
          FSize := sizeof(pointer);
        end else
        begin
          FSize := PFieldTable(GetTypeData(arraytypeinfo)).Size;

          // �������������� �������� �������
          FBufSize := FItemSize;
          for i := 0 to Dimention-1 do
          FBufSize := FBufSize*(ABounds[i*2+1]-ABounds[i*2]+1);

          if (FSize <> FBufSize) then
          ELua.Assert('Incorrect bounds of static array "%s"', [Name], CodeAddr);
        end;
      end else
      begin
        // 100% ����������� ������
        // ��������� itemtypeinfo.

        // �������� ������� ����������� - FTypeInfo: ptypeinfo
        PropertyInfo.Base.Information := itemtypeinfo;
        FTypeInfo := GetLuaDifficultTypeInfo(PropertyInfo.Base);

        // ���������� ����� ���������� ��������� �� Bounds
        FItemsCount := 1;
        if (PropertyInfo.Base.Kind = pkArray) then FItemsCount := PLuaArrayInfo(itemtypeinfo).FItemsCount;

        for i := 0 to Dimention-1 do
        FItemsCount := FItemsCount*(ABounds[i*2+1]-ABounds[i*2]+1);

        // ������ ������������ �������
        FSize := FItemSize*FItemsCount;
      end;                   
  end;

  // ���� ������, �� �������� ���� ItemInfo, � ���� �� ������, �� �������
  if (Result >= 0) then
  begin
    Dest.FClassIndex := Result;
    TLuaPropertyInfo(PLuaArrayInfo(ClassesInfo[Result]._Class).ItemInfo).Cleanup();
  end else
  begin
    Result := internal_add_class_info();
    Dest.FClassIndex := Result;    
    FInitialized := false;

    with ClassesInfo[Result] do
    begin
      new(PLuaArrayInfo(_Class));
      _ClassKind := ckArray;
      _ClassName := Dest.Name;
      Ref := internal_register_metatable(CodeAddr, _ClassName, Result);

      // �������� � ������ �������� ������
      internal_add_class_index(_Class, Result);
      internal_add_class_index_by_name(_ClassName, Result);
      if (arraytypeinfo <> nil) then internal_add_class_index(arraytypeinfo, Result);
    end;
  end;

  // � ����� ������ ��������� ArrayInfo
  PLuaArrayInfo(ClassesInfo[Result]._Class)^ := Dest;

  // ���������� PropertyInfo �������� �������
  TLuaPropertyInfo(PLuaArrayInfo(ClassesInfo[Result]._Class).ItemInfo).Fill(
                   ClassesInfo[Result], PropertyInfo.Base, nil, nil, nil);
end;
         *)
            (*
// tpinfo - ������ typeinfo(Set)
function TLua.InternalAddSet(tpinfo, CodeAddr: pointer): integer;
const
  MASK_3 = $FF shl 3;
var
  Name: string;
  TypeData: PTypeData;  
  SetInfo: PLuaSetInfo;
begin
  // �������� tpinfo
  if (tpinfo = nil) then
  ELua.Assert('TypeInfo of set is not defined', [], CodeAddr);
  if (ptypeinfo(tpinfo).Kind <> tkSet) then ELua.Assert('TypeInfo of set is not correct: TypeKind = %s', [TypeKindName(ptypeinfo(tpinfo).Kind)], CodeAddr);

  // ���
  Name := ptypeinfo(tpinfo).Name;

  // ����� ����������
  Result := internal_class_index(tpinfo);
  if (Result < 0) then Result := internal_class_index_by_name(Name); 
  if (Result >= 0) and (ClassesInfo[Result]._ClassKind <> ckSet) then ELua.Assert('Type "%s" is already registered', [Name], CodeAddr);

  // ����������
  if (Result < 0) then
  begin
    Result := internal_add_class_info();
    FInitialized := false;

    new(SetInfo);
    with ClassesInfo[Result] do
    begin
      _Class := SetInfo;
      _ClassKind := ckSet;
      _ClassName := Name;
      Ref := internal_register_metatable(CodeAddr, _ClassName, Result);

      // �������� � ������ �������� ������
      internal_add_class_index(_Class, Result);
      internal_add_class_index_by_name(_ClassName, Result);
      internal_add_class_index(tpinfo, Result);
    end;

    // ��������� ����
    SetInfo.FName := Name;
    SetInfo.FClassIndex := Result;
    SetInfo.FTypeInfo := GetTypeData(tpinfo).{$ifdef fpc}CompType{$else}CompType^{$endif};
    TypeData := GetTypeData(SetInfo.FTypeInfo);
    SetInfo.FLow := TypeData.MinValue;
    SetInfo.FHigh := TypeData.MaxValue;
    if (SetInfo.FTypeInfo.Kind = tkEnumeration) and (not IsTypeInfo_Boolean(SetInfo.FTypeInfo)) then Self.RegEnum(SetInfo.FTypeInfo);

    // ������ ������� ���������
    with SetInfo^ do
    begin
      {$ifdef fpc}
         if (FHigh > 31) then FSize := 32 else FSize := 4;
         FRealSize := FSize;
         FCorrection := 0;
         FAndMasks := $0000FFFF;
      {$else}
         FSize := (((FHigh+7+1)and MASK_3)-(FLow and MASK_3))shr 3;
         FRealSize := FSize;
         if (FSize = 3) then FSize := 4;
         FCorrection := (FLow and MASK_3);
         pchar(@FAndMasks)[0] := char($FF shr (7 - (FHigh and 7)));
         pchar(@FAndMasks)[1] := char($FF shl (FLow - FCorrection));
      {$endif}
    end;
  end;
end;   *)
         (*
function TLua.InternalAddProc(const IsClass: boolean; AClass: pointer; const ProcName: string; ArgsCount: integer; const with_class: boolean; Address, CodeAddr: pointer): integer;
var
  Index: integer;
  IsConstructor: boolean;
  ClassInfo: ^TLuaClassInfo;
  ProcInfo: ^TLuaProcInfo;

  // ����������� ���������� ������ �� ������������ ��������
  procedure FillConstructor(const ClassIndex: integer; const Address: pointer; const ArgsCount: integer);
  var
    LastAddress: pointer;
    i, LastArgsCount: integer;
  begin
    LastAddress := ClassesInfo[ClassIndex].constructor_address;
    LastArgsCount := ClassesInfo[ClassIndex].constructor_args_count;
    if (LastAddress = Address) and (LastArgsCount = ArgsCount) then exit;

    for i := 0 to Length(ClassesInfo)-1 do
    with ClassesInfo[i] do
    if (ParentIndex = ClassIndex) then
    begin
      if (constructor_address = LastAddress) and (constructor_args_count = LastArgsCount) then
      FillConstructor(i, Address, ArgsCount);
    end;

    ClassesInfo[ClassIndex].constructor_address := Address;
    ClassesInfo[ClassIndex].constructor_args_count := ArgsCount;

    FInitialized := false;
  end;


  // ����������� ���������� ��������� �� ����� Assign()
  procedure FillAssignProc(const ClassIndex: integer; const Address: pointer);
  var
    i: integer;
    LastAddress: pointer;
  begin
    LastAddress := ClassesInfo[ClassIndex].assign_address;
    if (LastAddress = Address) then exit;

    for i := 0 to Length(ClassesInfo)-1 do
    with ClassesInfo[i] do
    if (ParentIndex = ClassIndex) then
    begin
      if (assign_address = LastAddress) then FillAssignProc(i, Address);
    end;                                                                

    ClassesInfo[ClassIndex].assign_address := Address;
    FInitialized := false;
  end;


begin
  // ��������
  if (Address = nil) then
  ELua.Assert('ProcAddress = NIL', CodeAddr);

  if (ArgsCount < -1) or (ArgsCount > 20) then
  ELua.Assert('Non-available ArgsCount value (%d)', [ArgsCount], CodeAddr);

  if (not IsValidIdent(ProcName)) then
  ELua.Assert('Non-supported ProcName ("%s")', [ProcName], CodeAddr);

  // ������������� Address
  if (IsClass) and (AClass <> nil) then
  begin
    Index := IntPos(integer(Address), PInteger(AClass), VMTMethodsCount(AClass));
    if (Index >= 0) then integer(Address) := integer($FE000000) or Index*4;      
  end;

  // �����������
  IsConstructor := (AClass <> nil) and (SameStrings(LUA_CONSTRUCTOR, ProcName));
  if (IsConstructor) then
  begin
    if (with_class) then
    ELua.Assert('Contructor can''t be a class method', CodeAddr);

    if IsClass then Index := InternalAddClass(AClass, False, CodeAddr)
    else Index := internal_class_index(AClass);

    FillConstructor(Index, Address, ArgsCount);
    Result := -1;
    exit;
  end;

  // ����� Assign()
  if (AClass <> nil) and (SameStrings(LUA_ASSIGN, ProcName)) then
  begin
    if (with_class) then
    ELua.Assert('Assign() method can''t be a class method', CodeAddr);

    if IsClass then Index := InternalAddClass(AClass, False, CodeAddr)
    else Index := internal_class_index(AClass);

    if (ArgsCount <> -1) and (ArgsCount <> 1) then
    ELua.Assert('Assign() method should have just 1 argument', CodeAddr);

    FillAssignProc(Index, Address);
    Result := -1;
    exit;                          
  end;


  // ���������������� �����, ���������� ���������� (���� �����) � �������� ��������� �� ProcInfo
  if (AClass = nil) then
  begin
    Result := internal_register_global(ProcName, gkProc, CodeAddr).Index;
    ProcInfo := @GlobalNative.Procs[Result];
  end else
  begin
    if IsClass then Index := InternalAddClass(AClass, False, CodeAddr)
    else Index := internal_class_index(AClass);

    ClassInfo := @ClassesInfo[Index];
    Result := ClassInfo.InternalAddName(ProcName, true, FInitialized, CodeAddr);
    ProcInfo := @ClassInfo.Procs[Result];
  end;

  // ����������
  ProcInfo.ArgsCount := ArgsCount;
  ProcInfo.with_class := with_class;
  ProcInfo.Address := Address;
end;     *)
           (*
// IsConst ����� �������� ������ ��� ���������� ���������� (AClass = GLOBAL_NAME_SPACE)
// tpinfo ����� ���� ��� ������� typeinfo, ��� � PLuaRecordInfo
// �������� �������� ������ ��� �������, �������� (����) � ���������� ���������
function  TLua.InternalAddProperty(const IsClass: boolean; AClass: pointer; const PropertyName: string; tpinfo: ptypeinfo; const IsConst, IsDefault: boolean; const PGet, PSet, Parameters, CodeAddr: pointer): integer;
var
  IsGlobal: boolean;
  Index: integer;
  ClassInfo: ^TLuaClassInfo;
  GlobalVariable: PLuaGlobalVariable;
  PropBase: TLuaPropertyInfoBase;
  PropInfo: ^TLuaPropertyInfo;

  // ����������� ���������� ������ �� ���������� �������� � ��������
  procedure FillDefaultProperty(const ClassIndex: integer; const Value: integer);
  var
    i: integer;
    LastValue: integer;
  begin
    LastValue := ClassesInfo[ClassIndex]._DefaultProperty;
    if (LastValue = Value) then exit;

    for i := 0 to Length(ClassesInfo)-1 do
    with ClassesInfo[i] do
    if (ParentIndex = ClassIndex) then
    begin
      if (_DefaultProperty = LastValue) then FillDefaultProperty(i, Value);
    end;

    ClassesInfo[ClassIndex]._DefaultProperty := Value;
    FInitialized := false;
  end;
begin
  // ������������ ClassInfo, ����� ��� ���������������� ��� �������������
  IsGlobal := (AClass = GLOBAL_NAME_SPACE);
  if (IsGlobal) then ClassInfo := @GlobalNative
  else
  begin
    if (IsClass) then Index := InternalAddClass(AClass, False, CodeAddr)
    else Index := internal_class_index(AClass);

    ClassInfo := @ClassesInfo[Index];
  end;

  // ��������
  if (not IsValidIdent(PropertyName)) then
  ELua.Assert('Non-supported %s name "%s"', [ClassInfo.PropertyIdentifier, PropertyName], CodeAddr);

  if (tpinfo = nil) then
  ELua.Assert('TypeInfo of %s "%s" is not defined', [ClassInfo.PropertyIdentifier, PropertyName], CodeAddr);

  if (IsDefault) and (Parameters = nil) then
  ELua.Assert('Simple property ("%s") can''t be default property', [PropertyName], CodeAddr);

  case integer(Parameters) of
    0, integer(INDEXED_PROPERTY), integer(NAMED_PROPERTY): ;
    else
      if (PLuaRecordInfo(Parameters).FieldsCount = 0) then
      ELua.Assert('Property information "%s" has no fields', [PLuaRecordInfo(Parameters).Name], CodeAddr);
  end;  

  // ����������� ������� ����������
  PropBase := GetLuaPropertyBase(Self, '', PropertyName, tpinfo, CodeAddr);

  // �����/��������/���������������� ��������
  if (not IsGlobal) then
  begin
    Result := ClassInfo.InternalAddName(PropertyName, false, FInitialized, CodeAddr);

    if (IsDefault) then
    begin
      //ClassInfo._DefaultProperty := (not Result);
      FillDefaultProperty(ClassInfo._ClassIndex, integer(SmallPoint(ClassInfo._ClassIndex, not Result)));
    end;  
  end else
  begin
    GlobalVariable := internal_register_global(PropertyName, gkVariable, CodeAddr);
    GlobalVariable.IsConst := IsConst;
    Result := GlobalVariable.Index;
  end;                            
  PropInfo := @ClassInfo.Properties[not Result];

  // ��������� ����������
  PropInfo.Fill(ClassInfo^, PropBase, PGet, PSet, Parameters);
  if (IsConst) then PropInfo.write_mode := MODE_NONE_USE;
end;
       *)

const
  PTR_FALSE = pointer(ord(false));
  PTR_TRUE = pointer(ord(true));
  OPERATOR_NEG = 0;
  OPERATOR_ADD = 1;
  OPERATOR_SUB = 2;
  OPERATOR_MUL = 3;
  OPERATOR_DIV = 4;
  OPERATOR_MOD = 5;
  OPERATOR_POW = 6;
  OPERATOR_EQUAL = 7;
  OPERATOR_LESS = 8;
  OPERATOR_LESS_EQUAL = 9;
  OPERATOR_CONCAT = 10; {��������. ������ ��� ������������ ��������}

         (*
// ������������������� ������������ ��� � ������� �������
procedure TLua.INITIALIZE_NAME_SPACE();
var
  i: integer;

  // �������� ���������� ��� � ���� ������
  procedure AddToNameSpace(var ClassInfo: TLuaClassInfo; const Name: string;
                          const IsProc: boolean; const ClassIndex, Ind: integer);
  var
    NewValue, P: integer;
    ProcInfo, PropertyInfo: pointer;
  begin
    // NewValue := (ord(IsProc) shl 31) or (ClassIndex shl 16) or (Ind);
    NewValue := ClassIndex; // word part
    with TSmallPoint(NewValue) do
    begin y := Ind; if (not IsProc) then y := not y; end;
    P := ClassInfo.NameSpacePlace(Self, pchar(Name), Length(Name), ProcInfo, PropertyInfo);

    if (ProcInfo = nil) and (PropertyInfo = nil) then
    begin
      // ��������
      with TLuaHashIndex(DynArrayInsert(ClassInfo.NameSpace, typeinfo(TLuaHashIndexDynArray), P)^) do
      begin
        Hash := StringHash(Name);
        Index := NewValue;
      end;
    end else
    begin
      // ��������
      ClassInfo.NameSpace[P].Index := NewValue;
    end;
  end;

  // ������ ��� ����������� � �����
  procedure add_metatable_callback(const proc_name: pchar; const CFunctionProc: pointer); overload;
  begin
    lua_push_pchar(Handle, proc_name);

    if (CFunctionProc = nil) then lua_pushnil(Handle)
    else lua_pushcclosure(Handle, CFunctionProc, 0);

    lua_rawset(Handle, -3);
  end;
  // ���������������� � �������� ������
  procedure add_metatable_callback(const proc_name: pchar; const CallbackProc: pointer; const P1: pointer; const P2: pointer); overload;
  begin
    if (CallbackProc = nil) then add_metatable_callback(proc_name, nil)
    else add_metatable_callback(proc_name, pointer(AddLuaCallbackProc(Self, P1, P2, CallbackProc)));
  end;

  // ������������� � ��������� ��� �������
  procedure CreateCallbacks(var ClassInfo: TLuaClassInfo);
  var
    i: integer;
    Operators: TLuaOperators;


    // ������ ��� ����������� � �����
    procedure register_callback(const proc_name: pchar; const CallbackProc: pointer; const Value: pointer=nil);
    var
      P1: pointer;
    begin
      P1 := @ClassInfo;
      if (@ClassInfo = @GlobalNative) then P1 := PTR_FALSE;

      add_metatable_callback(proc_name, CallbackProc, P1, Value);
    end;

    // ���������������� ��������
    // �������� ������ Operators
    procedure register_operator(const Value: integer);
    const
      OPERATORS_NAME: array[OPERATOR_NEG..OPERATOR_CONCAT]
      of pansichar = ('__unm','__add','__sub','__mul','__div','__mod','__pow','__eq','__lt','__le','__concat');
    var
      CallbackProc: pointer;
    begin
      CallbackProc := @TLua.__operator;

      if (Value in [OPERATOR_NEG..OPERATOR_POW]) then
      begin
        if (not (TLuaOperator(Value) in Operators)) then CallbackProc := nil;
      end else
      if (Value = OPERATOR_CONCAT) then with ClassInfo do
      begin
         if (_ClassKind <> ckArray) or (PLuaArrayInfo(_Class).Dimention <> 1)
         or (not PLuaArrayInfo(_Class).IsDynamic) then CallbackProc := nil;
      end else
      begin
        if (not (loCompare in Operators)) then CallbackProc := nil;
        if (Value = OPERATOR_LESS) and (ClassInfo._ClassKind = ckSet) then CallbackProc := nil;
      end;

      add_metatable_callback(OPERATORS_NAME[Value], CallbackProc, @ClassInfo, pointer(Value));
    end;

  begin
    // �������� �����������
    global_push_value(ClassInfo.Ref);

    // ���������� ����������� �������� ���������
    if (@ClassInfo = @GlobalNative) then
    begin
      // ���������� ������������
      register_callback('__index', @TLua.__global_index);
      register_callback('__newindex', @TLua.__global_newindex);
    end else
    if (ClassInfo._ClassKind = ckArray) then
    begin
      // ������
      register_callback('__index', @TLua.__array_index, PTR_FALSE);
      register_callback('__newindex', @TLua.__array_newindex, PTR_FALSE);
      register_callback('__len', @TLua.__len);
      register_callback('__call', @TLua.__call);
      register_callback('__gc', @TLua.__destructor, PTR_FALSE);

      // �������� ������������
      register_operator(OPERATOR_CONCAT);
    end else
    begin
      // �����, ��������� ��� ���������
      register_callback('__index', @TLua.__index_prop_push);
      register_callback('__newindex', @TLua.__newindex_prop_set);
      register_callback('__len', @TLua.__len);
      register_callback('__call', @TLua.__call);
      register_callback('__gc', @TLua.__destructor, PTR_FALSE);
      

      // ������������ �������-������������/�����������
      if (ClassInfo._ClassKind = ckClass) then ClassInfo.__Create := pointer(AddLuaCallbackProc(Self, @ClassInfo, PTR_TRUE, @TLua.__constructor));
      if (ClassInfo._ClassKind = ckClass) then ClassInfo.__Free := pointer(AddLuaCallbackProc(Self, @ClassInfo, PTR_TRUE, @TLua.__destructor));

      // ��������� ��� �������� � ��������
      case ClassInfo._ClassKind of
        ckRecord: begin
                    Operators := PLuaRecordInfo(ClassInfo._Class).FOperators;
                    if (@PLuaRecordInfo(ClassInfo._Class).FOperatorCallback = nil) then Operators := [];
                  end;

           ckSet: Operators := [loNeg, loAdd, loSub, loMul, loCompare];                  
      else
         Operators := [];
      end;
      if (ClassInfo._ClassKind <> ckClass) then
      for i := OPERATOR_NEG to OPERATOR_LESS_EQUAL do register_operator(i);
    end;
    
    // ���������� ������ __tostring
    if (@ClassInfo <> @GlobalNative) then
    begin
      lua_push_pchar(Handle, '__tostring');
      lua_pushcclosure(Handle, cfunction_tostring, 0);
      lua_rawset(Handle, -3);
    end;

    // �������� ����
    lua_settop(Handle, 0);

    // ������� ������� ��� �������
    for i := 0 to Length(ClassInfo.Procs)-1 do
    ClassInfo.Procs[i].lua_CFunction := pointer(AddLuaCallbackProc(Self, @ClassInfo, @ClassInfo.Procs[i], @TLua.ProcCallback));
  end;

  // ������� ���������� ������������ ��� ��� ������,
  // ������� ������������ ��� ������
  procedure FillNameSpace(var AlreadyInitialized: TBooleanDynArray; var ClassInfo: TLuaClassInfo; const ClassIndex: integer); overload;
  var
    i, ParentIndex: integer;
  begin
    if (AlreadyInitialized[ClassIndex]) then exit;
    ClassInfo._ClassSimple := false;

    // ���������������� ������, ����� ��� ������� ���������� ���
    ParentIndex := ClassInfo.ParentIndex;
    if (ParentIndex >= 0) then
    begin
      FillNameSpace(AlreadyInitialized, ClassesInfo[ParentIndex], ParentIndex);
      DynArrayCopy(ClassInfo.NameSpace, ClassesInfo[ParentIndex].NameSpace, typeinfo(TLuaHashIndexDynArray));
    end else
    begin
      ClassInfo.NameSpace := nil;
    end;

    // ��������� ���������� � �������
    for i := 0 to Length(ClassInfo.Procs)-1 do
    AddToNameSpace(ClassInfo, ClassInfo.Procs[i].ProcName, true, ClassIndex, i);

    // �������� ���������� � ������ �� �������
    for i := 0 to Length(ClassInfo.Properties)-1 do
    AddToNameSpace(ClassInfo, ClassInfo.Properties[i].PropertyName, false, ClassIndex, i);


    // ����������, �������� �� ����� "�������"
    // ��� ������ ��� � ���� ��� �������, ���������� ������� <= 10 � ��� ���������� � ��� Properties
    ClassInfo._ClassSimple := (ClassInfo.Procs = nil) and (Length(ClassInfo.Properties) <= 10);
    if (ClassInfo._ClassSimple) then
    for i := 0 to Length(ClassInfo.NameSpace)-1 do
    if (ClassInfo.NameSpace[i].Index and $FFFF <> ClassIndex) then
    begin
      ClassInfo._ClassSimple := false;
      break;
    end;

    // ��������, ��� ����������������
    AlreadyInitialized[ClassIndex] := true;
  end;

  // ������� ������ ��������������� ������� � �������
  // ������� ������ � �������� �������
  // !!! ��� GlobalNative ����� ������ �� �����. ���������� ���������� ������ ���������
  procedure FillNameSpace(); overload;
  var
    i, Count: integer;
    AlreadyInitialized: TBooleanDynArray;
  begin
    // ������������� �������
    Count := Length(ClassesInfo);
    SetLength(AlreadyInitialized, Count);
    if (Count <> 0) then ZeroMemory(pointer(AlreadyInitialized), Count);

    // ������������� �������
    for i := 0 to Count-1 do
    FillNameSpace(AlreadyInitialized, ClassesInfo[i], i);
  end;

begin
  if (FInitialized) then exit;
  DeleteCFunctionDumps(Self);

  // ������� ������ ��������������� ������� � �������
  // ������� ������ � �������� �������
  // !!! ��� GlobalNative ����� ������ �� �����. ���������� ���������� ������ ���������
  FillNameSpace();


  // ������� ������������� �������
  begin
    cfunction_tostring := pointer(AddLuaCallbackProc(Self, nil, nil, @TLua.__tostring));
    cfunction_inherits_from := pointer(AddLuaCallbackProc(Self, nil, nil, @TLua.__inherits_from));
    cfunction_assign := pointer(AddLuaCallbackProc(Self, nil, nil, @TLua.__assign));
    cfunction_dynarray_resize := pointer(AddLuaCallbackProc(Self, nil, nil, @TLua.__array_dynamic_resize));
    cfunction_array_include := pointer(AddLuaCallbackProc(Self, pointer(1), nil, @TLua.__array_include));
    cfunction_set_include  := pointer(AddLuaCallbackProc(Self, PTR_FALSE, pointer(0), @TLua.__set_method));
    cfunction_set_exclude  := pointer(AddLuaCallbackProc(Self, PTR_FALSE, pointer(1), @TLua.__set_method));
    cfunction_set_contains := pointer(AddLuaCallbackProc(Self, PTR_FALSE, pointer(2), @TLua.__set_method));
  end;

  // ������������� � ��������� ����������� �������
  begin
    CreateCallbacks(GlobalNative);

    for i := 0 to Length(ClassesInfo)-1 do
    CreateCallbacks(ClassesInfo[i]);

    // ������� ��������
    global_push_value(mt_properties);
    add_metatable_callback('__index', @TLua.__array_index, nil, PTR_TRUE);
    add_metatable_callback('__newindex', @TLua.__array_newindex, nil, PTR_TRUE);
    add_metatable_callback('__gc', @TLua.__destructor, nil, nil);
    add_metatable_callback('__tostring', cfunction_tostring);
    lua_settop(Handle, 0);
  end;

  // ������������� ������� CFunctionDumps
  {$ifdef NO_CRYSTAL}
    QuickSort4(pointer(CFunctionDumps), 0, Length(CFunctionDumps)-1);
  {$else}
    SortArray4(CFunctionDumps);
  {$endif}

  // ���� "�� ��������������������"
  FInitialized := true;  
end;
        *)
          (*
// �������������� userdata ��� ����������� � ������
function __arrayindex_description(const Prefix, Value: string; const Index, Dimention: integer): string; forward;
function TLua.__tostring(): integer;
var
  userdata: PLuaUserData;

  // �������� difficult �������� - ��� ��������� ���� 
  procedure FillPropertyDescription();
  begin
    with userdata^, FBufferArg do
    str_data := __arrayindex_description('NON FINSHED DIFFICULT PROPERTY: ' + PropertyInfo.PropertyName,
               'xxx', integer(array_params) and $F - 1, array_params shr 4);
  end;

  // �� �� ����� ��� ������� ����������� ��������
  procedure FillArrayDescription();
  begin
    with userdata^, FBufferArg do
    str_data := __arrayindex_description(ArrayInfo.Name, 'xxx', integer(array_params) and $F - 1, array_params shr 4);
  end;


begin
  Result := 1;

  if (lua_type(Handle, 1) = LUA_TTABLE) then
  begin
    lua_push_pascalstring(Handle, ClassesInfo[LuaTableToClass(Handle, 1)]._ClassName);
  end else
  begin
    userdata := lua_touserdata(Handle, 1);

    if (userdata = nil) or (userdata.instance = nil) then lua_push_pascalstring(Handle, 'Incorrect userdata')
    else
    with userdata^ do
    if (kind = ukProperty) then
    begin
      FillPropertyDescription();
      lua_push_pascalstring(Handle, FBufferArg.str_data);
    end else
    if (kind = ukArray) and (array_params and $F <> 0) then
    begin
      FillArrayDescription();
      lua_push_pascalstring(Handle, FBufferArg.str_data);
    end else
    begin
      // TObject, Record, Set
      stack_luaarg(FBufferArg, 1, true); 

      with FBufferArg do
      begin
        if (LuaType <> ltEmpty) and (LuaType <> ltString) then
        begin
          if (str_data <> '') then str_data := '';
          TForceString(@TLuaArg.ForceString)(FBufferArg, str_data);
        end;

        if (LuaType = ltEmpty) or (str_data = '') then
          lua_push_pascalstring(Handle, 'nil')
        else
          lua_push_pascalstring(Handle, str_data);
      end;
    end;
  end;    
end;      *)
            (*

// �������� �� ������ ����������� (������, PLuaRecordInfo, PLuaArrayInfo, PLuaSetInfo)
function TLua.__inherits_from(): integer;
label
  Exit;
var
  Ret: boolean;
  userdata: PLuaUserData;
  ClassIndex1, ClassIndex2: integer;
  ClassInfo1, ClassInfo2: ^TLuaClassInfo;
begin
  Ret := false;
  Result := 1;

  if (lua_gettop(Handle) <> 2) then
  ScriptAssert('Wrong arguments count(%d) in InheritsForm() method', [lua_gettop(Handle)]);

  if (lua_type(Handle, 2) <> LUA_TTABLE) then goto Exit; 
  ClassIndex2 := LuaTableToClass(Handle, 2);
  if (ClassIndex2 < 0) then goto Exit;

  case (lua_type(Handle, 1)) of
    LUA_TUSERDATA: begin
                     userdata := lua_touserdata(Handle, 1);
                     if (userdata = nil) or (userdata.instance = nil) then goto Exit;

                     case userdata.kind of
                       ukInstance: ClassIndex1 := userdata.ClassIndex;
                            ukSet: ClassIndex1 := userdata.SetInfo.FClassIndex;
                          ukArray: if (userdata.array_params and $F <> 0) then goto Exit
                                   else ClassIndex1 := userdata.ArrayInfo.FClassIndex;
                     else
                       goto Exit;
                     end;
                   end;
       LUA_TTABLE: begin
                     ClassIndex1 := LuaTableToClass(Handle, 1);
                     if (ClassIndex1 < 0) then goto Exit;
                   end;
  else
    goto Exit;
  end;

  // ���������
  Ret := (ClassIndex1 = ClassIndex2);
  if (Ret) then goto Exit;

  // ��� �������
  ClassInfo1 := @ClassesInfo[ClassIndex1];
  ClassInfo2 := @ClassesInfo[ClassIndex2];
  Ret := (ClassInfo1._ClassKind = ckClass) and (ClassInfo1._ClassKind = ckClass)
     and (TClass(ClassInfo1._Class).InheritsFrom(TClass(ClassInfo2._Class)));

Exit:  
  lua_pushboolean(Handle, Ret);
end;
      *)
        (*
// ����� ���������� ������������� �������� ������ ����������
// ���-�� ���� �����������
//
// ��� assign() �������� � ������ ������������� �� �������
function TLua.__assign(): integer;
var
  Dest, Src: PLuaUserData;
  src_luatype: integer;
  assign_addr: pointer;

  // �������� ������, ��� ���������� ��������� assign
  procedure ThrowWrongParameters(const Description: string='Wrong types.');
  var
    X1, X2: TLuaArg;
  begin
    stack_luaarg(X1, 1, true);
    stack_luaarg(X2, 2, true);

    ScriptAssert('Can''t realize %s.Assign(%s). %s', [X1.ForceString, X2.ForceString, Description]);
  end;

begin
  Result := 0;

  if (lua_gettop(Handle) <> 2) then
  ScriptAssert('Not found instance or wrong arguments count in an Assign() method', []);

  // �������������� ������ ��������
  // �������� ��� ������� (����� ������������� �����)
  // � ����� ���� � �����-�� ����� (� ���� ������ ������)
  src_luatype := lua_type(Handle, 2);
  if (src_luatype = LUA_TTABLE) then
  begin
    if (LuaTableToClass(Handle, 2) >= 0) then ThrowWrongParameters();
  end;

  // �������� �����
  if (lua_type(Handle, 1) <> LUA_TUSERDATA) or (not (src_luatype in [LUA_TUSERDATA, LUA_TTABLE]))
  then ThrowWrongParameters();

  // �������� Dest (Self)
  Dest := lua_touserdata(Handle, 1);
  if (Dest.instance = nil) then ThrowWrongParameters('Instance is already destroyed.');

  // ���� ����� �������������
  if (src_luatype = LUA_TTABLE) then
  begin
    // ������������� �� ������� �������� ������ ��� ������� � �������� (ukInstance)
    if (Dest.kind <> ukInstance) then ThrowWrongParameters();

    // �����
    Self.__initialize_by_table(Dest, 2);

    exit;
  end;

  // �������� Dest � Src
  Src := lua_touserdata(Handle, 2);
  if (Src.instance = nil) then ThrowWrongParameters('Argument is already destroyed.');
  if (Dest.kind <> Src.kind) or (Dest.kind = ukProperty) then ThrowWrongParameters();

  
  if (Dest.kind = ukSet) then
  begin
    if (Dest.SetInfo <> Src.SetInfo) then ThrowWrongParameters();
    Move(Src.instance^, Dest.instance^, Dest.SetInfo.FSize);
  end else
  if (Dest.kind = ukArray) then
  begin
    if (Dest.ArrayInfo <> Src.ArrayInfo) then ThrowWrongParameters();

    with Dest.ArrayInfo^ do
    if (FTypeInfo = nil) then Move(Src.instance^, Dest.instance^, FSize)
    else CopyArray(Dest.instance, Src.instance, FTypeInfo, FItemsCount);
  end else
  with ClassesInfo[Dest.ClassIndex] do
  begin
    if (_ClassKind <> ClassesInfo[Src.ClassIndex]._ClassKind) then ThrowWrongParameters();

    // ���� ���������������� ����������� ������� Assign(const Arg: TLuaArg)
    if (assign_address <> nil) then
    begin
      FArgsCount := 1;
      SetLength(FArgs, 1);
      stack_luaarg(FArgs[0], 2, false);
      assign_addr := assign_address;
      if (dword(assign_addr) >= $FE000000) then assign_addr := ppointer(dword(Dest.instance^) + dword(assign_addr) and $00FFFFFF)^;

      TLuaClassProc16(assign_addr)(Dest.instance^, FArgs, TLuaArg(nil^));
      FArgsCount := 0;
      exit;
    end;

    { -- ����������� ���������� -- }

    if (_ClassKind = ckRecord) then
    begin
      // ����������� ���������
      if (Dest.ClassIndex <> Src.ClassIndex) then ThrowWrongParameters();

      with PLuaRecordInfo(_Class)^ do
      if (FTypeInfo <> nil) then CopyRecord(Dest.instance, Src.instance, FTypeInfo)
      else Move(Src.instance^, Dest.instance^, FSize);      
    end else
    if (TObject(Dest.instance) is TPersistent) and (TObject(Src.instance) is TPersistent) then
    begin
      TPersistent(Dest.instance).Assign(TPersistent(Src.instance));
    end else
    begin
      // ����������� TObject
      CopyObject(TObject(Dest.instance), TObject(Src.instance));
    end;
  end;
end;      *)
            (*
// ��� ��������� �������� �� ������������
// ������� (�����) ������ ��� ��������� �� �������.
// ������� ����������� (�.�. ����� ���������������� ��������� ��������� � ���������� ������)
//
// ������� �������� �� ���������� �� Lua, �� ����� ������ ����������
// ������ ����� �������� � ����� ��� �������� �������.
// � ������ ������� ������� 100% ���������� �� �� �������� �������, ������� � ������ ������ - ScriptAssert()
//
// stack_index ����� ������ � ������ ���������!
function TLua.__initialize_by_table(const userdata: PLuaUserData; const stack_index: integer): integer;
const
  FIELD_PROPERTY: array[boolean] of string = ('Field', 'Property');

var
  S: pansichar;
  SLength: integer;
  ClassInfo: PLuaClassInfo;
  is_class: boolean;
  ProcInfo: ^TLuaProcInfo;
  PropertyInfo: ^TLuaPropertyInfo;
  prop_struct: TLuaPropertyStruct;
  recursive_userdata: TLuaUserData;

  // � ������ ������
  procedure ThrowKeyValue(const Description: string);
  var
    key_arg, value_arg: TLuaArg;
  begin
    stack_luaarg(key_arg, -2, true);
    if (key_arg.LuaType <> ltString) then key_arg.AsString := '"' + key_arg.ForceString + '"';
    stack_luaarg(value_arg, -1, true);

    ScriptAssert('Can''t change %s.%s to "%s". %s.', [ClassInfo._ClassName,
                  key_arg.ForceString, value_arg.ForceString, Description]);
  end;

  // ����� � ������ ����� �������, ��� ��� ���� ��� ��������
  procedure ThrowFieldProp(const Desc: string); overload;
  begin
    ThrowKeyValue(FIELD_PROPERTY[is_class] + ' ' + Desc);
  end;

begin
  Result := 0; // ��������� � ���������� �� ����� ��������

  // ClassInfo, prop_struct
  ClassInfo := @ClassesInfo[userdata.ClassIndex];
  is_class := (ClassInfo._ClassKind = ckClass);
  prop_struct.Instance := userdata.instance;
  prop_struct.Index := nil;
  prop_struct.ReturnAddr := nil;
  prop_struct.StackIndex := lua_gettop(Handle)+2;

  // ������������ ���������
  if (userdata.is_const) then
  ScriptAssert('"%s" instance is constant', [ClassInfo._ClassName]);

  // ���� �� ���� ���������
  lua_pushnil(Handle);
  while (lua_next(Handle, stack_index) <> 0) do
  begin
    // Key
    if (lua_type(Handle, -2) <> LUA_TSTRING) then ThrowKeyValue('Incorrect key');

    // �������� ��������� ������������� �����
    // �������� �������� � ����� ������ ���� �����.
    // � ������� ����� ����� ��������� ��� �� "����������� ��������" (todo)
    begin
      S := lua_tolstring(Handle, -2, @SLength);
      ProcInfo := nil;
      PropertyInfo := nil;
      ClassInfo.NameSpacePlace(Self, S, SLength, pointer(ProcInfo), pointer(PropertyInfo));

      if (ProcInfo <> nil) then
      ThrowKeyValue('Method can''t be changed');

      if (PropertyInfo = nil) then
      ThrowFieldProp('not found');

      if (PropertyInfo.write_mode = MODE_NONE_USE) then
      ThrowFieldProp('is readonly');

      if (PropertyInfo.Parameters <> nil) then
      ThrowFieldProp('is difficult to initialize');
    end;

    // ���� ���� ��� ������ �������� ���������� ��� ����������� ������
    // � � Value �������, �� ����� ������� ��������
    // (+ �������� ��� ��������)
    if (lua_type(Handle, -1) = LUA_TTABLE) and (LuaTableToClass(Handle,-1)<0) then
    begin
      // �������� �� ���������� ���
      if (not(PropertyInfo.Base.Kind in [pkObject, pkRecord])) then ThrowKeyValue('Incompatible types');

      // ���� ����/�������� �������������
      if (PropertyInfo.read_mode = MODE_NONE_USE) then ThrowFieldProp('is writeonly');

      // ���� �������� �� �������
      if (PropertyInfo.read_mode < 0) then ThrowFieldProp('is difficult to initialize, because it has a getter function');

      // ���������� ������ ��� ������������ ������
      pinteger(@recursive_userdata.kind)^ := 0; // ����� ��� ����
      if (PropertyInfo.Base.Kind = pkObject) then
      begin
        // �������������� ��������� ������
        recursive_userdata.instance := ppointer(integer(userdata.instance)+PropertyInfo.read_mode)^;
        if (recursive_userdata.instance = nil) then ThrowFieldProp('is nil');
        recursive_userdata.ClassIndex := internal_class_index(TClass(recursive_userdata.instance^));
      end else
      begin
        // ��������� (�� ������)
        recursive_userdata.instance := pointer(integer(userdata.instance)+PropertyInfo.read_mode);
        recursive_userdata.ClassIndex := PLuaRecordInfo(PropertyInfo.Base.Information).FClassIndex;
      end;

      // ��� �����
      __initialize_by_table(@recursive_userdata, lua_gettop(Handle));
    end else
    begin
      // ������� �����������
      prop_struct.PropertyInfo := PropertyInfo;
      __newindex_prop_set(ClassInfo^, @prop_struct);
    end;

    // next iteration
    lua_settop(Handle, -1-1);
  end;
end;    *)
          (*

// ����� ������ + ���������� �������������� �����
procedure TMethod_Call(const ASelf, P1, P2: integer; const Code: pointer);
asm
  push esi
  mov esi, esp
    CALL [EBP+8]
  mov esp, esi
  pop esi
end;
           *)(*
// ������� ����� ������� � 2�� ���������� �������� ������
function TLua.__tmethod_call(const Method: TMethod): integer;
var
  userdata: PLuaUserData;
  Offset, ArgsCount, i: integer;
  P_DATA: array[0..1] of integer;
  S_DATA: array[0..1] of string;
  P: pinteger;
  S: pstring;
  Number: double;
  IntValue: integer absolute Number;  

  // ��������, ��� �������� �� �������� ��� ������ ������
  procedure ThrowWrongParameter(const i: integer; const ParamType: pchar);
  begin
    ScriptAssert('%d parameter of TMethod() call has unsupported type: "%s"' , [i+1, ParamType]);
  end;

  // ���� ���������� ���������, �� ���������������� �
  procedure CorrectPointer(var Value: integer; const Size: integer);
  begin
    case (Size) of
      1: Value := pbyte(Value)^;
      2: Value := pword(Value)^;
      3: Value := integer(pword(Value)^) or (ord(pchar(Value)[2]) shl 16);
      4: Value := pinteger(Value)^;
    end;
  end;
  
begin
  Result := 0;

  // �������� �� ����������� ������
  if (Method.Code = nil) then
  ScriptAssert('Method is not assigned (Code = %p, Data = %p)', [Method.Code, Method.Data]);  

  // ������������ � Offset
  // Stack[1] 100% = Method. � ��� �� ������ ���������� ����� ���� ��������
  LuaTypeName(lua_type(Handle, 2));
  userdata := lua_touserdata(Handle, 2);
  Offset := ord((userdata <> nil) or (userdata.kind <> ukInstance));

  // ���������� ����������
  ArgsCount := lua_gettop(Handle)-1-Offset;
  if (ArgsCount < 0) or (ArgsCount > 2) then
  ScriptAssert('Wrong TMethod() arguments count = %d. Max arguments count = 2', [ArgsCount]);

  // ���� ����������
  P_DATA[0] := 0;
  P_DATA[1] := 0;
  P := @P_DATA[0];
  S := @S_DATA[0];
  for i := 1 to ArgsCount do
  begin
    case lua_type(Handle, 1+Offset+i) of
    LUA_TNIL           : ;  
    LUA_TBOOLEAN      : if (lua_toboolean(Handle, 1+Offset+i)) then P^ := 1;
    LUA_TNUMBER       : begin
                          if (NumberToInteger(Number, Handle, 1+Offset+i)) then
                          P^ := IntValue
                          else
                          P^ := Trunc(Number);
                        end;
    LUA_TSTRING       : begin
                          lua_to_pascalstring(S^, Handle, 1+Offset+i);
                          P^ := integer(S^);
                        end;
    LUA_TLIGHTUSERDATA: ppointer(P)^ := lua_touserdata(Handle, 1+Offset+i);
    LUA_TFUNCTION     : begin
                          ppointer(P)^ := CFunctionPtr(lua_tocfunction(Handle, 1+Offset+i));
                          if (pdword(P)^ >= $FE000000) then pdword(P)^ := pdword(P)^ and $00FFFFFF;
                        end;
    LUA_TUSERDATA     : begin
                          // ������ ������ ��� ��������� ��� ������ ��� ...
                          userdata := lua_touserdata(Handle, 1+Offset+i);
                          if (userdata <> nil) then
                          with userdata^ do
                          begin
                            P^ := integer(instance);
                            case kind of
                               ukInstance: with ClassesInfo[ClassIndex] do
                                             if (_ClassKind <> ckClass) then
                                             with PLuaRecordInfo(_Class)^ do
                                             if (FSize <= 4) then CorrectPointer(P^, FSize);
                                  ukArray: with ArrayInfo^ do
                                             if (FSize <= 4) then CorrectPointer(P^, FSize);
                                    ukSet: with SetInfo^ do
                                             if (FSize <= 4) then CorrectPointer(P^, FSize);
                            else
                              { ukProperty }
                              ThrowWrongParameter(i, 'DifficultProperty');
                            end;
                          end;
                        end;
    LUA_TTABLE        : begin
                          // TClass, Info ��� �������
                          IntValue := LuaTableToClass(Handle, 1+Offset+i);

                          if (IntValue >= 0) then
                          begin
                            pointer(P^) := ClassesInfo[IntValue]._Class;
                          end else
                          begin
                            ThrowWrongParameter(i, 'LuaTable');
                          end;
                        end;
    else
      // ���������������� ���
      ThrowWrongParameter(i, LuaTypeName(lua_type(Handle, 1+Offset+i)));
    end;


    inc(P);
    inc(S);
  end;

  // �����
  TMethod_Call(integer(Method.Data), P_DATA[0], P_DATA[1], Method.Code);
end;
       *)

const
  // ��� ���� userdata (����� ������� �������)
  STD_TYPE = 1;
  STD_TYPE_NAME = 2;
  STD_TYPE_PARENT = 3;
  STD_INHERITS_FROM = 4;
  STD_ASSIGN = 5;
  STD_IS_REF = 6;
  STD_IS_CONST = 7;
  STD_IS_CLASS = 8;
  STD_IS_RECORD = 9;
  STD_IS_ARRAY = 10;
  STD_IS_SET = 11;
  STD_IS_EMPTY = 12;

  // ��� �������
  STD_CREATE = 13;
  STD_FREE = 14;

  // �������
  STD_LOW = 15;
  STD_HIGH = 16;
  STD_LENGTH = 17;
  STD_RESIZE = 18;

  // ���������
  STD_INCLUDE = 19;
  STD_EXCLUDE = 20;
  STD_CONTAINS = 21;

  // TLuaReference
  STD_VALUE = 22;


             (*
// ����� 2 ������ ��������� � �������
// ���� ������ �������� �� ������� - Result = false
function __read_lua_arguments(const Handle: pointer; var userdata: PLuaUserData;
                                  var S: pchar; var luatype, SLength, stdindex: integer): boolean;
type
  T12bytes = array[0..2] of integer;
var
  Data: ^T12bytes;// absolute S;
const
  _Type = $65707954;
  _Name = $656D614E;
  _Pare = $65726150;
  _nt   = $0000746E;
  _Inhe = $65686E49;
  _rits = $73746972;
  _From = $6D6F7246;
  _Assi = $69737341;
  _gn   = $00006E67;
  _IsRe = $65527349;
  _f    = $00000066;
  _IsCo = $6F437349;
  _nst  = $0074736E;
  _IsCl = $6C437349;
  _ass  = $00737361;
  _cord = $64726F63;
  _IsAr = $72417349;
  _ray  = $00796172;
  _IsSe = $65537349;
  _t    = $00000074;
  _IsEm = $6D457349;
  _pty  = $00797470;
  _Crea = $61657243;
  _te   = $00006574;
  _Free = $65657246;
  _Low  = $00776F4C;
  _High = $68676948;
  _Leng = $676E654C;
  _th   = $00006874;
  _Resi = $69736552;
  _ze   = $0000657A;
  _Incl = $6C636E49;
  _ude  = $00656475;
  _Excl = $6C637845;
  _Cont = $746E6F43;
  _ains = $736E6961;
  _Valu = $756C6156;
  _e    = $00000065;

begin
  case lua_type(Handle, 1) of
    LUA_TTABLE: begin
                  userdata := nil;
                  Result := true;
                end;
 LUA_TUSERDATA: begin
                  userdata := lua_touserdata(Handle, 1);
                  Result := (userdata <> nil);
                end;
  else
    Result := false;
    exit;
  end;
  if (not Result) then exit;


  SLength := 0;
  luatype := lua_type(Handle, 2);
  if (luatype = LUA_TSTRING) then S := lua_tolstring(Handle, 2, @SLength);
  if (SLength = 0) then
  begin
    S := nil;
    stdindex := -1;
    exit;
  end;

  //  ----------- STD_INDEX ����� -------------
  Data := pointer(S);
  case (SLength) of
    3: begin
         if (Data[0] = _Low) then stdindex := STD_LOW
         else stdindex := 0;
       end;
    4: begin
         if (Data[0] = _Type) then stdindex := STD_TYPE
         else
         if (Data[0] = _Free) then stdindex := STD_FREE
         else
         if (Data[0] = _High) then stdindex := STD_HIGH
         else
         stdindex := 0;
       end;
    5: begin
         if (Data[0] = _IsRe) and (word(Data[1]) = _f) then stdindex := STD_IS_REF
         else
         if (Data[0] = _IsSe) and (word(Data[1]) = _t) then stdindex := STD_IS_SET
         else
         if (Data[0] = _Valu) and (word(Data[1]) = _e) then stdindex := STD_VALUE
         else
         stdindex := 0;
       end;
    6: begin
         if (Data[0] = _Crea) and (word(Data[1]) = _te) then stdindex := STD_CREATE
         else
         if (Data[0] = _Leng) and (word(Data[1]) = _th) then stdindex := STD_LENGTH
         else
         if (Data[0] = _Resi) and (word(Data[1]) = _ze) then stdindex := STD_RESIZE
         else
         if (Data[0] = _Assi) and (word(Data[1]) = _gn) then stdindex := STD_ASSIGN
         else
         stdindex := 0;
       end;
    7: begin
         if (Data[0] = _IsCo) and (Data[1] = _nst) then stdindex := STD_IS_CONST
         else
         if (Data[0] = _IsCl) and (Data[1] = _ass) then stdindex := STD_IS_CLASS
         else
         if (Data[0] = _IsEm) and (Data[1] = _pty) then stdindex := STD_IS_EMPTY
         else
         if (Data[0] = _IsAr) and (Data[1] = _ray) then stdindex := STD_IS_ARRAY
         else
         if (Data[0] = _Incl) and (Data[1] = _ude) then stdindex := STD_INCLUDE
         else
         if (Data[0] = _Excl) and (Data[1] = _ude) then stdindex := STD_EXCLUDE
         else
         stdindex := 0;
       end;
    8: begin
         if (Data[0] = _Type) and (Data[1] = _Name) then stdindex := STD_TYPE_NAME
         else
         if (Data[0] = _IsRe) and (Data[1] = _cord) then stdindex := STD_IS_RECORD
         else
         if (Data[0] = _Cont) and (Data[1] = _ains) then stdindex := STD_CONTAINS
         else
         stdindex := 0;
       end;
   10: begin
         if (Data[0] = _Type) and (Data[1] = _Pare) and (word(Data[2]) = _nt) then
           stdindex := STD_TYPE_PARENT
         else
           stdindex := 0;
       end;
   12: begin
         if (Data[0] = _Inhe) and (Data[1] = _rits) and (Data[2] = _From) then
           stdindex := STD_INHERITS_FROM
         else
           stdindex := 0;
       end;
  else
    stdindex := 0;
  end;
end;      *)

           (*
// �������� �� ������������ ������ ���������� ��������
function __can_jump_default_property(const Lua: TLua; const luatype: integer; const PropInfo: TLuaPropertyInfo): boolean;
begin
  Result := (luatype <> LUA_TSTRING);

  // ��������, ���� �������� - ������
  if (not Result) then
  with PropInfo, PLuaRecordInfo(Parameters)^ do
  if (Parameters <> INDEXED_PROPERTY) then                                       {todo ����� ���������� ����� ��������}
  Result := (Parameters = NAMED_PROPERTY) or (Lua.ClassesInfo[FClassIndex].Properties[0].Base.Kind = pkString);
end;            *)
                  (*
// ������� ������ ������������ �������� ��� ������.
// ������� ���������� �����, ������� �������� � ��������� ���
// true ���� "�����"
function __push_std_prop(const Lua: TLua; const _ClassInfo: TLuaClassInfo; const stdindex: integer; const userdata: PLuaUserData; const S: pansichar): boolean;

  // ���������� ������� �����, ������ ��� �������� - ���������
  procedure ThrowConst();
  begin
    Lua.ScriptAssert('%s() method can''t be called, because %s instance is const', [S, _ClassInfo._ClassName]);
  end;
begin
  Result := false;

    with Lua do
    case (stdindex) of
           STD_TYPE: begin
                       global_push_value(_ClassInfo.Ref);
                       Result := true;
                     end;
      STD_TYPE_NAME: begin
                       lua_push_pascalstring(Handle, _ClassInfo._ClassName);
                       Result := true;
                     end;
    STD_TYPE_PARENT: begin
                       if (_ClassInfo.ParentIndex < 0) then lua_pushnil(Handle)
                       else global_push_value(ClassesInfo[_ClassInfo.ParentIndex].Ref);

                       Result := true;
                     end;
  STD_INHERITS_FROM: begin
                       lua_pushcclosure(Handle, lua_CFunction(cfunction_inherits_from), 0);
                       Result := true;
                     end;
         STD_ASSIGN: begin
                       if (userdata <> nil) then
                       begin
                         if (_ClassInfo._ClassKind <> ckClass) and (userdata.is_const) then ThrowConst();
                         lua_pushcclosure(Handle, lua_CFunction(cfunction_assign), 0);
                         Result := true;
                       end;
                     end;
         STD_IS_REF: begin
                       lua_pushboolean(Handle, (userdata <> nil) and (not userdata.gc_destroy));
                       Result := true;
                     end;
       STD_IS_CONST: begin
                       lua_pushboolean(Handle, (userdata <> nil) and (userdata.is_const));
                       Result := true;
                     end;
       STD_IS_CLASS: begin
                       lua_pushboolean(Handle, _ClassInfo._ClassKind = ckClass);
                       Result := true;
                     end;
      STD_IS_RECORD: begin
                       lua_pushboolean(Handle, _ClassInfo._ClassKind = ckRecord);
                       Result := true;
                     end;
         STD_IS_SET: begin
                       lua_pushboolean(Handle, _ClassInfo._ClassKind = ckSet);
                       Result := true;
                     end;
       STD_IS_EMPTY: begin
                       if (userdata = nil) or (userdata.instance = nil) then lua_pushboolean(Handle, true)
                       else
                       case _ClassInfo._ClassKind of
                         ckClass: lua_pushboolean(Handle, false{todo ?});
                        ckRecord: lua_pushboolean(Handle, IsMemoryZeroed(userdata.instance, PLuaRecordInfo(_ClassInfo._Class).FSize));
                           ckSet: lua_pushboolean(Handle, IsMemoryZeroed(userdata.instance, PLuaSetInfo(_ClassInfo._Class).FSize));
                       end;

                       Result := true;
                     end;
         STD_CREATE: begin
                       if (userdata = nil) and (_ClassInfo._ClassKind = ckClass) then
                       begin
                         lua_pushcclosure(Handle, lua_CFunction(_ClassInfo.__Create), 0);
                         Result := true;
                       end;
                     end;
           STD_FREE: begin
                       if (userdata <> nil) and (_ClassInfo._ClassKind = ckClass) then
                       begin
                         lua_pushcclosure(Handle, lua_CFunction(_ClassInfo.__Free), 0);
                         Result := true;
                       end;
                     end;
            STD_LOW: begin
                       if (_ClassInfo._ClassKind = ckSet) then
                       begin
                         lua_pushinteger(Handle, PLuaSetInfo(_ClassInfo._Class).FLow);
                         Result := true;
                       end;
                     end;
           STD_HIGH: begin
                       if (_ClassInfo._ClassKind = ckSet) then
                       begin
                         lua_pushinteger(Handle, PLuaSetInfo(_ClassInfo._Class).FHigh);
                         Result := true;
                       end;
                     end;
        STD_INCLUDE: begin
                       if (_ClassInfo._ClassKind = ckSet) and (userdata <> nil) then
                       begin
                         if (userdata.is_const) then ThrowConst();
                         lua_pushcclosure(Handle, lua_CFunction(cfunction_set_include), 0);
                         Result := true;
                       end;
                     end;
        STD_EXCLUDE: begin
                       if (_ClassInfo._ClassKind = ckSet) and (userdata <> nil) then
                       begin
                         if (userdata.is_const) then ThrowConst();
                         lua_pushcclosure(Handle, lua_CFunction(cfunction_set_exclude), 0);
                         Result := true;
                       end;
                     end;
       STD_CONTAINS: begin
                       if (_ClassInfo._ClassKind = ckSet) and (userdata <> nil) then
                       begin
                         lua_pushcclosure(Handle, lua_CFunction(cfunction_set_contains), 0);
                         Result := true;
                       end;
                     end;
          STD_VALUE: begin
                       if (_ClassInfo._ClassIndex = TLUA_REFERENCE_CLASS_INDEX) and (userdata <> nil) and (userdata.instance <> nil) then
                       begin
                         lua_rawgeti(Handle, LUA_REGISTRYINDEX, TLuaReference(userdata.instance).Index);
                         Result := true;
                       end;
                     end;
    end;
end;
       *)

type
  // ������������� ��� ��� ��������� ������ ��� get/set �������
  TPackedValue = packed record
    case Integer of
      0: (b: boolean);
      1: (i: integer);
      2: (i64: int64);
      3: (e: extended);
      4: (v: TVarData);
      5: (lb: LongBool);
      6: (p: pointer);
  end;

           (*
// ����� ���������������� �����
// ����� � ������/��������� ����� ����� �������� ��� �����. � ���� ������ prop_struct = nil
//
// �� ��� ��� ��������� ������� ���������������� � CrystalLUA, �� ����� �� ���� ��������
// ������� ��� ������ ������ ��� �� �� ��������, ����������� ������������, ��� �������� ����������.
// � ���� ������ prop_struct �������� (<> nil)
function TLua.__index_prop_push(const ClassInfo: TLuaClassInfo; const prop_struct: PLuaPropertyStruct): integer;
label
  PROP_PUSHING;
type
  TGetStrProp = procedure(Instance: TObject; PropInfo: PPropInfo; var Ret: string);
  TGetVariantProp = procedure(Instance: TObject; PropInfo: PPropInfo; var Ret: Variant);
  TGetInterfaceProp = procedure(Instance: TObject; PropInfo: PPropInfo; var Ret: IInterface);

  TGetUniversal = procedure(const instance: pointer; var Result: TLuaArg);
  TSetIndexedUniversal = procedure(const instance: pointer; const index: integer; var Result: TLuaArg);

var
  S: pansichar;
  luatype, SLength, stdindex: integer;
  // todo ��-�� � ���� �������

  jump_to_default: boolean;
  userdata: PLuaUserData;
  ProcInfo: ^TLuaProcInfo;
  PropertyInfo: ^TLuaPropertyInfo;

  is_const: boolean absolute jump_to_default;
  instance: pointer absolute userdata;
  Obj: TObject absolute instance;
  Value: TPackedValue;

  // ������: ������ �� �a�����
  procedure ThrowFoundNothing();
  const
    instance_type: array[boolean] of string = ('instance', 'type');
  begin
    TStackArgument(@TLua.StackArgument)(Self, 2, FBufferArg.str_data);
    ScriptAssert('"%s" not found in %s %s', [FBufferArg.str_data, ClassInfo._ClassName, instance_type[userdata = nil]]);
  end;

  // ���� ���-�� �� ��� � user-data
  procedure ThrowFailInstance();
  begin
    // ������ userdata
    if (userdata = nil) then
    ScriptAssert('%s.%s property is not class property', [ClassInfo._ClassName, PropertyInfo.PropertyName]);

    // instance empty ?
    if (userdata.instance = nil) then
    ScriptAssert('Instance (%s) is already destroyed', [ClassInfo._ClassName]);

    // writeonly
    if (PropertyInfo.read_mode = MODE_NONE_USE) then
    ScriptAssert('%s.%s property is writeonly property', [ClassInfo._ClassName, PropertyInfo.PropertyName]);
  end;

begin
  Result := 1;

  // ������� ����� ���������� �� ������ ���������� - �� __index �� ������/���������
  // �� ��� �� � �� ������ ������ ����.
  // � ���� ������ prop_struct - �� nil
  if (prop_struct <> nil) then
  begin
    PropertyInfo := prop_struct.PropertyInfo;
    instance := prop_struct.Instance;
    is_const := prop_struct.IsConst;
    if (PropertyInfo.Parameters <> nil) then PropertyInfo.PropInfo.Index := integer(prop_struct.Index); // ������ ��� ��������� �� ���������
    goto PROP_PUSHING;
  end;


  // ����������� ������
  // ������� ������ userdata � ���������� �� ������� ���������
  if (not __read_lua_arguments(Handle, userdata, S, luatype, SLength, stdindex)) then
  begin
    lua_pushnil(Handle);
    exit;
  end;

  // ��� ����������� �������
  if (stdindex > 0) and (__push_std_prop(Self, ClassInfo, stdindex, userdata, S)) then exit;

  // ��� �� "����������" �����/��������
  // ����� �����
  ProcInfo := nil;
  PropertyInfo := nil;
  ClassInfo.NameSpacePlace(Self, S, SLength, pointer(ProcInfo), pointer(PropertyInfo));

  // �������
  if (ProcInfo <> nil) then
  begin
    lua_pushcclosure(Handle, ProcInfo.lua_CFunction, 0);
    exit;
  end;

  // ��������
  jump_to_default := false;
  if (PropertyInfo = nil) {�������� ���������} then
  with ClassInfo do
  if (_DefaultProperty >= 0) then
  begin
    PropertyInfo := @ClassesInfo[_DefaultProperty and $FFFF].Properties[_DefaultProperty shr 16];

    if (__can_jump_default_property(Self, luatype, PropertyInfo^)) then jump_to_default := true
    else PropertyInfo := nil;
  end;

  // ������: ������ �� �a�����
  if (PropertyInfo = nil) then
  ThrowFoundNothing();

  // ���� ���-�� �� ��� � user-data
  if (userdata = nil) or (userdata.instance = nil) or
     ((PropertyInfo.Parameters = nil) and (PropertyInfo.read_mode = MODE_NONE_USE)) then
     ThrowFailInstance();


  // ���� ������� ��������, �� ������� �� ��������, � ������ �� ��������
  // ��� �������� � ������ __array_index
  if (PropertyInfo.Parameters <> nil) then
  begin
    push_difficult_property(userdata.instance, PropertyInfo^);

    if (jump_to_default) then
    begin
      lua_remove(Handle, 1);
      lua_insert(Handle, 1);
      __array_index(TLuaClassInfo(nil^){TODO ?}, true);
    end;
    exit;
  end;

  // ������� ���������
  is_const := userdata.is_const;
  instance := userdata.instance;


PROP_PUSHING:  
  // �������� ��� ������� - ����� � ���� �������� ��������
  with PropertyInfo^ do
  begin
    if (read_mode >= 0) then inc(integer(instance), read_mode);

    case Base.Kind of
        pkBoolean: begin
                     if (read_mode >= 0) then
                     begin
                       case Base.BoolType of
                         btBoolean: Value.i := pbyte(instance)^;
                        btByteBool: Value.i := pbyte(instance)^;
                        btWordBool: Value.i := pword(instance)^;
                        btLongBool: Value.i := pinteger(instance)^;
                       end;
                     end
                     else Value.i := TypInfo.GetOrdProp(Obj, PropInfo);

                     if (Value.i <> 0) then Value.i := -1;
                     lua_pushboolean(Handle, Value.lb);
                   end;
        pkInteger: begin
                     if (read_mode >= 0) then
                     begin
                       case Base.OrdType of
                         otSByte: Value.i := pshortint(instance)^;
                         otUByte: Value.i := pbyte(instance)^;
                         otSWord: Value.i := psmallint(instance)^;
                         otUWord: Value.i := pword(instance)^;
                         otSLong,
                         otULong: Value.i := pinteger(instance)^;
                       end;
                     end
                     else Value.i := TypInfo.GetOrdProp(Obj, PropInfo);

                     if (Base.OrdType <> otULong) then lua_pushinteger(Handle, Value.i)
                     else lua_pushnumber(Handle, dword(Value.i));
                   end;
          pkInt64: begin
                     if (read_mode >= 0) then Value.i64 := pint64(instance)^
                     else Value.i64 := TypInfo.GetInt64Prop(Obj, PropInfo);

                     lua_pushnumber(Handle, Value.i64);
                   end;
          pkFloat: begin
                     if (read_mode >= 0) then
                     begin
                       case Base.FloatType of
                         ftSingle: lua_pushnumber(Handle, psingle(instance)^);
                         ftDouble: lua_pushnumber(Handle, pdouble(instance)^);
                       ftExtended: lua_pushnumber(Handle, pextended(instance)^);
                           ftComp: lua_pushnumber(Handle, PComp(instance)^);
                           ftCurr: lua_pushnumber(Handle, PCurrency(instance)^);
                       end;
                     end
                     else lua_pushnumber(Handle, TypInfo.GetFloatProp(Obj, PropInfo));
                   end;
         pkString: with FBufferArg do
                   begin
                     if (str_data <> '') then str_data := '';
                     {todo UnicodeString?,}

                     if (not (Base.StringType in [stAnsiChar, stWideChar])) then
                     begin
                       // ������
                       if (read_mode >= 0) then
                       begin        {todo ����� ����������}
                         case Base.StringType of
                         stShortString: if (pbyte(instance)^ <> 0) then str_data := pshortstring(instance)^;
                          stAnsiString: if (ppointer(instance)^ <> nil) then str_data := pansistring(instance)^;
                          stWideString: if (ppointer(instance)^ <> nil) then str_data := pwidestring(instance)^;
                         end;
                       end
                       else TGetStrProp(TypInfoGetStrProp)(Obj, PropInfo, str_data);
                     end else
                     begin
                       // AnsiChar or WideChar
                       if (read_mode >= 0) then
                       begin
                         if (Base.StringType = stAnsiChar) then Value.i := pbyte(instance)^
                         else Value.i := pword(instance)^;
                       end
                       else Value.i := TypInfo.GetOrdProp(Obj, PropInfo);

                       if (Value.i <> 0) then
                       begin
                         if (Base.StringType = stAnsiChar) then str_data := ansichar(Value.i)
                         else System.WideCharLenToStrVar(PWideChar(@Value.i), 1, str_data);
                       end;
                     end;

                     lua_push_pascalstring(Handle, str_data);
                   end;

        pkVariant: begin
                     // "��������" ��������
                     Value.v.VType := varEmpty;
                     if (not(read_mode >= 0)) then
                     begin
                       TGetVariantProp(TypInfoGetVariantProp)(Obj, PropInfo, PVariant(@Value.v)^);
                       instance := @Value.v;
                     end;

                     // push: Variant ��� nil
                     if (not push_variant(PVariant(instance)^)) then lua_pushnil(Handle);

                     // ������� ���� ��� �����
                     if (Value.v.VType = varString) or (not (Value.v.VType in VARIANT_SIMPLE)) then VarClear(PVariant(instance)^);
                   end;

      pkInterface,
        pkPointer,
          pkClass,
         pkObject: begin
                     if (read_mode >= 0) then
                     begin
                       Value.p := ppointer(instance)^;
                     end else
                     if (Base.Kind = pkInterface) then
                     begin
                       Value.p := nil;
                       TGetInterfaceProp(TypInfoGetInterfaceProp)(Obj, PropInfo, IInterface(Value.p));
                       if (Value.p <> nil) then IInterface(Value.p)._Release;
                     end else
                     begin
                       Value.i := TypInfo.GetOrdProp(Obj, PropInfo);
                     end;

                     if (Value.p = nil) then lua_pushnil(Handle)
                     else
                     if (Base.Kind in [pkInterface,pkPointer]) then lua_pushlightuserdata(Handle, Value.p)
                     else
                     if (Base.Kind = pkClass) then lua_rawgeti(Handle, LUA_REGISTRYINDEX, ClassesInfo[internal_class_index(Value.p, true)].Ref)
                     else
                     // pkObject
                     if (TClass(Value.p^) = TLuaReference) then lua_rawgeti(Handle, LUA_REGISTRYINDEX, TLuaReference(Value.p).Index)
                     else
                     push_userdata(ClassesInfo[internal_class_index(TClass(Value.p^), true)], false, Value.p);
                   end;
         pkRecord,
          pkArray,
            pkSet: CrystalLUA.GetPushDifficultTypeProp(Self, instance, is_const, PropertyInfo^);

      pkUniversal: CrystalLUA.GetPushUniversalTypeProp(Self, instance, is_const, PropertyInfo^);
      end;
  end;
end;        *)
              (*
// �������� ��������
// �������� ������� ������ !
function TLua.__newindex_prop_set(const ClassInfo: TLuaClassInfo; const prop_struct: PLuaPropertyStruct): integer;
label
  PROP_POPSET;
type
  PInterface = ^IInterface;  
const
  instance_type: array[boolean] of string = ('instance', 'type');  
var
  S: pansichar;
  luatype, SLength, stdindex: integer;
  // todo ��-�� � ���� �������

  jump_to_default: boolean;
  userdata: PLuaUserData;
  ProcInfo: ^TLuaProcInfo;
  PropertyInfo: ^TLuaPropertyInfo;

  stack_index: integer; // ������ ����� �������� (��� ����������)
  instance: pointer absolute userdata;
  Obj: TObject absolute instance;
  PV: PVarData absolute instance;
  ClassIndex: integer absolute SLength;
  Value: TPackedValue;

  // ������: ������ �� �a�����
  procedure ThrowFoundNothing();
  begin
    TStackArgument(@TLua.StackArgument)(Self, 2, FBufferArg.str_data);
    ScriptAssert('"%s" not found in %s %s', [FBufferArg.str_data, ClassInfo._ClassName, instance_type[userdata = nil]]);
  end;

  // ���� ���-�� �� ��� � user-data
  procedure ThrowFailInstance();
  begin
    // ������ userdata
    if (userdata = nil) then
    ScriptAssert('%s.%s property is not class property', [ClassInfo._ClassName, PropertyInfo.PropertyName]);

    // instance empty ?
    if (userdata.instance = nil) then
    ScriptAssert('Instance (%s) is already destroyed', [ClassInfo._ClassName]);

    // ������������ ���������
    if (UserData.is_const) then
    ScriptAssert('Field "%s" is a constant field', [PropertyInfo.PropertyName]);

    // readonly
    if (PropertyInfo.write_mode = MODE_NONE_USE) then
    ScriptAssert('%s.%s property is readonly property', [ClassInfo._ClassName, PropertyInfo.PropertyName]);
  end;

  // ���� �� ���������� ��������� ("���" � FBufferArg.str_data)
  procedure ThrowAssignValue(const look_luatype: boolean=false);
  var
    ReturnAddr: pointer;
    Desc: string;
  begin
    if (look_luatype) then FBufferArg.str_data := LuaTypeName(luatype);

    Desc := '';
    if (prop_struct = nil) then
    begin
      Desc := Format('%s.%s property', [ClassInfo._ClassName, PropertyInfo.PropertyName]);
    end else
    if (@ClassInfo <> nil) then
    begin
      if (ClassInfo._Class = GLOBAL_NAME_SPACE) then Desc := 'global variable ' + PropertyInfo.PropertyName
      else Desc := ClassInfo._ClassName + '.' + PropertyInfo.PropertyName + ' property';
    end;

    // total description of error
    if (Desc <> '') then Desc := Desc + ' ';
    Desc := Format('Can''t assign "%s" as %svalue', [FBufferArg.str_data, Desc]);

    // native or from script
    ReturnAddr := nil;
    if (prop_struct <> nil) then ReturnAddr := prop_struct.ReturnAddr;

    // call
    if (ReturnAddr <> nil) then ELua.Assert(Desc, ReturnAddr)
    else ScriptAssert(Desc, []);
  end;

  // ������������� �������� � ����� � �����
  // ��� �������� ������
  function CastValueAsNumber(): extended;
  begin
    Result := 0;

    case luatype of
         LUA_TNIL: {��� 0};
     LUA_TBOOLEAN: if (lua_toboolean(Handle, stack_index)) then Result := 1;
      LUA_TNUMBER: Result := lua_tonumber(Handle, stack_index);
      LUA_TLIGHTUSERDATA: Result := integer(lua_touserdata(Handle, stack_index));
      LUA_TUSERDATA: begin
                      Value.p := lua_touserdata(Handle, stack_index);
                      if (Value.p <> nil) then Result := integer(PLuaUserData(Value.p).instance);
                     end;
      LUA_TSTRING: begin
                     lua_to_pascalstring(FBufferArg.str_data, Handle, stack_index);

                     System.Val(FBufferArg.str_data, Result, luatype);
                     if (luatype <> 0) then ThrowAssignValue({false});
                   end;
    else
      ThrowAssignValue(true);
    end;
  end;

  // ��������� datauser, ����������� � Value.p �� ��������� ������
  // ���� �� ��� - ���������� ������
  // ���� �� ������ - �� � Value.p ��������� instance (TObject)
  procedure CastUserDataAsTObject();
  begin
    ClassIndex := -1;
    if (Value.p <> nil) and (PLuaUserData(Value.p).instance <> nil)
    and (PLuaUserData(Value.p).kind = ukInstance) then
      ClassIndex := PLuaUserData(Value.p).ClassIndex;

    if (ClassIndex >= 0) and (ClassesInfo[ClassIndex]._ClassKind = ckClass) then
    Value.p := PLuaUserData(Value.p).instance
    else
    ClassIndex := -1;

    if (Value.p = nil) or (ClassIndex < 0) then
    begin
      GetUserDataType(FBufferArg.str_data, Self, PLuaUserData(Value.p));
      ThrowAssignValue();
    end;
  end;


  // � ������ ��������� "������������ ��������"
  // true ���� "���������"
  function change_std_prop(): boolean;
  begin
    Result := false;

    // ��������� �������� TLuaReference
    if (ClassInfo._ClassIndex = TLUA_REFERENCE_CLASS_INDEX) and (stdindex = STD_VALUE) and
       (userdata <> nil) and (userdata.instance <> nil) then
    begin
      lua_pushvalue(Handle, 3);
      lua_rawseti(Handle, LUA_REGISTRYINDEX, TLuaReference(userdata.instance).Index);
      Result := true;
      exit;
    end;

    // �������� �� ��������� ������������ ����
    if (stdindex in [STD_TYPE..STD_IS_EMPTY]) or ((ClassInfo._ClassKind=ckClass)=(stdindex in [STD_CREATE, STD_FREE]))
    or ((ClassInfo._ClassKind=ckSet)=(stdindex in [STD_LOW, STD_HIGH, STD_INCLUDE..STD_CONTAINS]))
    then
    ScriptAssert('Standard field "%s" can not be changed in %s %s', [S, ClassInfo._ClassName, instance_type[userdata = nil]]);
  end;


begin
  Result := 0;

  // ������� ����� ���������� �� ������ ���������� - �� __index �� ������/���������
  // �� ��� �� � �� ������ ������ ����.
  // � ���� ������ prop_struct - �� nil
  if (prop_struct <> nil) then
  begin
    PropertyInfo := prop_struct.PropertyInfo;
    instance := prop_struct.Instance;
    stack_index := prop_struct.StackIndex;
    if (PropertyInfo.Parameters <> nil) then PropertyInfo.PropInfo.Index := integer(prop_struct.Index); // ������ ��� ��������� �� ���������
    goto PROP_POPSET;
  end;

  // ��������� userdata � ���������� �� ������� ���������
  if (not __read_lua_arguments(Handle, userdata, S, luatype, SLength, stdindex)) then
  begin
    exit;
  end;

  // ��� ����������� �������
  if (stdindex > 0) and change_std_prop() then exit;

  // ��� �� "����������" �����/��������
  // ����� �����
  ProcInfo := nil;
  PropertyInfo := nil;
  ClassInfo.NameSpacePlace(Self, S, SLength, pointer(ProcInfo), pointer(PropertyInfo));

  // ������ ������ ������
  if (ProcInfo <> nil) then
  ScriptAssert('Method %s.%s can not be changed', [ClassInfo._ClassName, S]);

  // ��������
  jump_to_default := false;
  if (PropertyInfo = nil) {�������� ���������} then
  with ClassInfo do
  if (_DefaultProperty >= 0) then
  begin
    PropertyInfo := @ClassesInfo[_DefaultProperty and $FFFF].Properties[_DefaultProperty shr 16];

    if (__can_jump_default_property(Self, luatype, PropertyInfo^)) then jump_to_default := true
    else PropertyInfo := nil;
  end;


  // ������: ������ �� �a�����
  if (PropertyInfo = nil) then
  ThrowFoundNothing();

  // ���� ���-�� �� ��� � user-data
  if (userdata = nil) or (userdata.instance = nil) or (userdata.is_const) or
     ((PropertyInfo.Parameters = nil) and (PropertyInfo.read_mode = MODE_NONE_USE)) then
     ThrowFailInstance();


  // ���� ������������������� ��������
  if (PropertyInfo.Parameters <> nil) then
  begin
    if (jump_to_default) then
    begin
      push_difficult_property(userdata.instance, PropertyInfo^);

      lua_remove(Handle, 1);
      lua_insert(Handle, 1);
      __array_newindex(TLuaClassInfo(nil^){TODO ?}, true);
    end else
    begin
      ScriptAssert('%s.%s property should have parameters', [ClassInfo._ClassName, PropertyInfo.PropertyName])
    end;

    exit;
  end;

  // ������� ���������
  instance := userdata.instance;
  stack_index := 3;


PROP_POPSET:
  // ����� �����, ����� ��� �������� ���������
  // ���� �� ���������� - ���� �������� ������
  luatype := lua_type(Handle, stack_index);

  // �������� ��� ������� - ���� �������� �� ����� � ����������� ��������
  with PropertyInfo^ do
  begin
    if (write_mode >= 0) then inc(integer(instance), write_mode);

    case Base.Kind of
      pkBoolean: begin
                   case (luatype) of
                         LUA_TNIL: Value.i := 0;
                     LUA_TBOOLEAN: Value.i := integer(lua_toboolean(Handle, stack_index)) and 1;
                      LUA_TSTRING: begin
                                     lua_to_pascalstring(FBufferArg.str_data, Handle, stack_index);
                                     Value.i := __cast_string_as_boolean(FBufferArg.str_data);
                                     if (Value.i < 0) then ThrowAssignValue({false});
                                   end;
                   else
                     ThrowAssignValue(true);
                   end;

                   // "���������" ����
                   if (Base.BoolType <> btBoolean) and (Value.i <> 0) then Value.i := -1;

                   // ����������
                   if (write_mode >= 0) then
                   begin
                     case Base.BoolType of
                       btBoolean: pboolean(instance)^ := Value.lb;
                      btByteBool: pbyte(instance)^ := pbyte(@Value.lb)^;
                      btWordBool: pword(instance)^ := pword(@Value.lb)^;
                      btLongBool: pdword(instance)^ := pdword(@Value.lb)^;
                     end;
                   end
                   else TypInfo.SetOrdProp(Obj, PropInfo, Value.i);
                 end;
      pkInteger: begin
                   if (luatype = LUA_TNUMBER) then Value.i64 := lua_toint64(Handle, stack_index)
                   else Value.i64 := round(CastValueAsNumber());

                   if (write_mode >= 0) then
                   begin
                     case Base.OrdType of
                       otSByte: pshortint(instance)^ := Value.i;
                       otUByte: pbyte(instance)^ := Value.i;
                       otSWord: psmallint(instance)^ := Value.i;
                       otUWord: pword(instance)^ := Value.i;
                       otSLong,
                       otULong: pinteger(instance)^ := Value.i;
                     end;
                   end
                   else TypInfo.SetOrdProp(Obj, PropInfo, Value.i);
                 end;
        pkInt64: begin
                   if (luatype = LUA_TNUMBER) then Value.i64 := lua_toint64(Handle, stack_index)
                   else Value.i64 := round(CastValueAsNumber());

                   if (write_mode >= 0) then
                   begin
                     pint64(instance)^ := Value.i64;
                   end else
                   begin
                     TypInfo.SetInt64Prop(Obj, PropInfo, Value.i64);
                   end;
                 end;
        pkFloat: begin
                   if (write_mode >= 0) and (luatype = LUA_TNUMBER) then
                   begin
                     case Base.FloatType of
                       ftSingle: psingle(instance)^ := lua_tonumber(Handle, stack_index);
                       ftDouble: pdouble(instance)^ := lua_tonumber(Handle, stack_index);
                     ftExtended: pextended(instance)^ := lua_tonumber(Handle, stack_index);
                         ftComp: PComp(instance)^ := lua_tonumber(Handle, stack_index);
                         ftCurr: PCurrency(instance)^ := lua_tonumber(Handle, stack_index);
                     end;
                   end else
                   begin
                     if (luatype <> LUA_TNUMBER) then TypInfo.SetFloatProp(Obj, PropInfo, CastValueAsNumber())
                     else TypInfo.SetFloatProp(Obj, PropInfo, lua_tonumber(Handle, stack_index));
                   end;
                 end;
       pkString: begin
                   // Cast as string (soft mode)
                   if (luatype = LUA_TSTRING) then lua_to_pascalstring(FBufferArg.str_data, Handle, stack_index)
                   else
                   begin
                     if (not Self.stack_luaarg(FBufferArg, stack_index, true{����� ������������ "LuaTable"})) then ThrowAssignValue({false});
                     TForceString(@TLuaArg.ForceString)(FBufferArg, FBufferArg.str_data);
                   end;

                   {todo UnicodeString?,}

                   {todo ����� ����� ��������������}

                   if (not (Base.StringType in [stAnsiChar, stWideChar])) then
                   begin
                     // ������
                     if (write_mode >= 0) then
                     begin
                       case Base.StringType of
                       stShortString: pshortstring(instance)^ := FBufferArg.str_data;
                        stAnsiString: pansistring(instance)^ := FBufferArg.str_data;
                        stWideString: pwidestring(instance)^ := FBufferArg.str_data;
                       end;
                     end
                     else TypInfo.SetStrProp(Obj, PropInfo, FBufferArg.str_data);
                   end else
                   begin
                     // AnsiChar or WideChar
                     if (FBufferArg.str_data = '') then Value.i := 0
                     else
                     if (Base.StringType = stAnsiChar) then Value.i := pbyte(FBufferArg.str_data)^
                     else
                     System.StringToWideChar(FBufferArg.str_data, pwidechar(@Value.i), 1);

                     if (write_mode >= 0) then
                     begin
                       if (Base.StringType = stAnsiChar) then pansichar(instance)^ := ansichar(Value.i)
                       else pwidechar(instance)^ := widechar(Value.i);
                     end
                     else TypInfo.SetOrdProp(Obj, PropInfo, Value.i);
                   end;
                 end;
      pkVariant: begin
                   if (write_mode >= 0) then
                   begin
                     if (not Self.stack_variant(PVariant(PV)^, stack_index)) then ThrowAssignValue({false});
                   end else
                   begin
                     if (not Self.stack_variant(PVariant(PV)^, stack_index)) then ThrowAssignValue({false});
                     TypInfo.SetVariantProp(Obj, PropInfo, PVariant(@Value.v)^);

                     // ������� ������
                     if (Value.v.VType = varString) or (not (Value.v.VType in VARIANT_SIMPLE)) then VarClear(PVariant(@Value.v)^);
                   end;
                 end;  
    pkInterface: begin

                   if (luatype = LUA_TNIL) then Value.p := nil
                   else
                   if (luatype = LUA_TLIGHTUSERDATA) then Value.p := lua_touserdata(Handle, stack_index)
                   else
                   ThrowAssignValue(true);

                   if (write_mode >= 0) then
                   begin
                     if (Value.p = nil) then PInterface(instance)^ := nil
                     else PInterface(instance)^ := IInterface(Value.p);
                   end else
                   begin
                     TypInfo.SetInterfaceProp(Obj, PropInfo, IInterface(Value.p));
                   end;
                 end;  
      pkPointer: begin
                   Value.p := nil;
                   case (luatype) of
                                  LUA_TNIL: {�� ������};
                               LUA_TSTRING: Value.p := lua_tolstring(Handle, stack_index, nil);
                        LUA_TLIGHTUSERDATA: Value.p := lua_touserdata(Handle, stack_index);
                             LUA_TUSERDATA: begin
                                              Value.p := lua_touserdata(Handle, stack_index);
                                              if (Value.p <> nil) then Value.p := PLuaUserData(Value.p).instance;
                                            end;
                             LUA_TFUNCTION: begin
                                              Value.p := pointer(lua_tocfunction(Handle, stack_index));
                                              if (Value.p <> nil) then Value.p := CFunctionPtr(Value.p);

                                              // �������� � ������� ���-�� �����
                                              if (dword(Value.p) >= $FE000000) then Value.p := nil; {todo ?}
                                            end;
                                LUA_TTABLE: begin
                                              ClassIndex := LuaTableToClass(Handle, stack_index);
                                              if (ClassIndex >= 0) then Value.p := ClassesInfo[ClassIndex]._Class
                                              else ThrowAssignValue(true{LUA_TTABLE});
                                            end;
                   else
                     ThrowAssignValue(true);
                   end;

                   // �����������
                   if (write_mode >= 0) then ppointer(instance)^ := Value.p
                   else TypInfo.SetOrdProp(Obj, PropInfo, Value.i);
                 end;
        pkClass: begin
                   Value.p := nil;
                   case (luatype) of
                        LUA_TNIL: {�� ������}; 
                      LUA_TTABLE: begin
                                    ClassIndex := LuaTableToClass(Handle, stack_index);

                                    if (ClassIndex < 0) then
                                    ThrowAssignValue(true{LUA_TTABLE});

                                    if (ClassesInfo[ClassIndex]._ClassKind = ckClass) then
                                    begin
                                      Value.p := ClassesInfo[ClassIndex]._Class;
                                    end else
                                    begin
                                      FBufferArg.str_data := ClassesInfo[ClassIndex]._ClassName;
                                      ThrowAssignValue({false});
                                    end;  
                                  end;
                   LUA_TUSERDATA: begin
                                    Value.p := lua_touserdata(Handle, stack_index);
                                    CastUserDataAsTObject();
                                    {get class} Value.p := ppointer(Value.p)^;
                                  end;
                   else
                     ThrowAssignValue(true);
                   end;

                   // �����������
                   if (write_mode >= 0) then ppointer(instance)^ := Value.p
                   else TypInfo.SetOrdProp(Obj, PropInfo, Value.i);
                 end;
       pkObject: begin
                   Value.p := nil;
                   case (luatype) of
                        LUA_TNIL: {�� ������}; 
                   LUA_TUSERDATA: begin
                                    Value.p := lua_touserdata(Handle, stack_index);
                                    CastUserDataAsTObject();
                                  end;
                   else
                     ThrowAssignValue(true);
                   end;         

                   // �����������
                   if (write_mode >= 0) then ppointer(instance)^ := Value.p
                   else TypInfo.SetOrdProp(Obj, PropInfo, Value.i);
                 end;
       pkRecord,
        pkArray,
          pkSet: if (not CrystalLUA.PopSetDifficultTypeProp(Self, instance, stack_index, PropertyInfo^)) then
                 ThrowAssignValue({false});

    pkUniversal: if (not CrystalLUA.PopSetUniversalTypeProp(Self, instance, stack_index, PropertyInfo^)) then
                 ThrowAssignValue({false});
    end;    
  end;
end;    *)
             (*
// ������ TypeInfo
function TLua.__len(const ClassInfo: TLuaClassInfo): integer;
begin
  Result := 1;

  case (ClassInfo._ClassKind) of
    ckClass: lua_pushinteger(Handle, TClass(ClassInfo._Class).InstanceSize);
   ckRecord: lua_pushinteger(Handle, PLuaRecordInfo(ClassInfo._Class).FSize);
    ckArray: lua_pushinteger(Handle, PLuaArrayInfo(ClassInfo._Class).FSize);
      ckSet: lua_pushinteger(Handle, PLuaSetInfo(ClassInfo._Class).FSize);
  else
    lua_pushinteger(Handle, 0);
  end;
end;
           *)
                         (*
// ��������� ��� ����������� � �����������
// neg, add, sub, mul, div, mod, pow, equal, less, less_equal
// ��������� ��� ����������� ��� ��������: neg, +, -, *, <=, ==

// ��������� ��� ����������� �����������. �� ���� �����������
// ��� ��������� Result - ��� ��������� ���������,
// ��� ��������� neg - X1 � X2 ����� - ��� �������� ���������
// +,- � ��������� - �������� c ����� ���������� �����������
// ��� *,/,% � ^ - ������ ������� - double
function TLua.__operator(const ClassInfo: TLuaClassInfo; const Kind: integer): integer;
var
  INDEXES: array[boolean] of integer;

  X1_type, X2_type: integer;
  Dest, X1, X2: PLuaUserData;
  DestCompare: integer;
  sizeofSet: integer; // ������ � ������� ��������

  X2_Value: pointer;
  Number: double;
  IntValue: integer;

  // ����������, ����� ������� ������ ��������
  procedure ThrowWrongOperands();
  const
    operators: array[OPERATOR_NEG..OPERATOR_POW] of string = ('neg', '+', '-', '*', '/', '%', '^');
  var
    X1, X2: TLuaArg;
    _kind, part2: string;
  begin
    if (Kind = OPERATOR_CONCAT) then _kind := '..'
    else
    if (Kind > OPERATOR_POW) then _kind := 'compare'
    else
    _kind := operators[Kind];


    if (Kind <> OPERATOR_NEG) then
    begin
      stack_luaarg(X1, 1, true);
      stack_luaarg(X2, 2, true);
      part2 := Format('s "%s" and "%s"', [X1.ForceString, X2.ForceString]);
    end else
    begin
      stack_luaarg(X1, 1, true);
      part2 := Format(' "%s"', [X1.ForceString]);
    end;

    ScriptAssert('Fail operation "%s" with operand%s', [_kind, part2]);
  end;

begin
  Result := 1;

  // ������ ������ - ������������, � ����� ��������� ����������� ������������� �������
  if (Kind = OPERATOR_CONCAT) then
  begin
    push_userdata(ClassInfo, true, nil);
    __array_include(2{concat_mode});
    exit;
  end;

  // sizeofSet
  if (ClassInfo._ClassKind = ckRecord) then sizeofSet := 0
  else sizeofSet := PLuaSetInfo(ClassInfo._Class).FSize;

  // ������� �������� ��������� - ���� ������ ������
  if (Kind = OPERATOR_NEG) then
  begin
    X1 := lua_touserdata(Handle, 1);
    if (X1 = nil) then ThrowWrongOperands();
    Dest := push_userdata(ClassInfo, true, nil);

    if (sizeofSet = 0) then
    begin
      // ������������� ���������
      PLuaRecordInfo(ClassInfo._Class).FOperatorCallback(Dest.instance^, X1.instance^, X1.instance^, TLuaOperator(Kind))
    end else
    begin
      // ������������� ���������
      with PLuaSetInfo(ClassInfo._Class)^ do
      SetInvert(Dest.instance, X1.instance, FAndMasks, FRealSize);
    end;

    exit;
  end;

  // �������� - ���� �������������� (+,-,*,/) ���� ��������� (<= � �.�.)
  // ������ ������� - 100% TUserData � ������ ����� ��������� � ClassInfo
  X1_type := lua_type(Handle, 1);
  X2_type := lua_type(Handle, 2);
  if (X1_type = LUA_TUSERDATA) then
  begin
    INDEXES[false] := 1;
    INDEXES[true] := 2;
  end else
  begin
    // � ���� ������� ���� ����������
    if (sizeofSet = 0) and (Kind in [OPERATOR_DIV..OPERATOR_POW]) then ThrowWrongOperands();

    // swap
    INDEXES[false] := 2;
    INDEXES[true] := 1;
    X2_type := X1_type; // ����� �������� ��� ������� ��������
  end;
  X1 := lua_touserdata(Handle, INDEXES[false]);
  if (X1 = nil) or ((X1.kind=ukSet)<>(ClassInfo._ClassKind=ckSet)) then ThrowWrongOperands();

  // �������� ������� ��������
  if (X2_type = LUA_TNUMBER) then
  begin
    Number := lua_tonumber(Handle, INDEXES[true]);

    if (sizeofSet = 0) then
    begin
      if (not (Kind in [OPERATOR_MUL..OPERATOR_POW])) then ThrowWrongOperands();
    end else
    begin
      if (not NumberToInteger(Number, IntValue)) then ThrowWrongOperands();

      with PLuaSetInfo(ClassInfo._Class)^ do
      if (IntValue < Low) or (IntValue > High) then ThrowWrongOperands();
    end;
  end else
  begin
    if (X2_type <> LUA_TUSERDATA) then ThrowWrongOperands();
    if (sizeofSet = 0) and (Kind in [OPERATOR_MUL..OPERATOR_POW]) then ThrowWrongOperands();
  end;


  if (X2_type = LUA_TNUMBER) then
  begin
    if (sizeofSet = 0) then X2_Value := @Number
    else integer(X2_Value) := IntValue
  end else
  begin
    X2 := lua_touserdata(Handle, INDEXES[true]);
    if (X2 = nil) or (X2.ClassIndex <> X1.ClassIndex{��� SetInfo}) then ThrowWrongOperands();
    X2_Value := X2.instance;
  end;


  // ��������� � ������� ���������
  if (Kind in [OPERATOR_EQUAL..OPERATOR_LESS_EQUAL]) then
  begin
    // ���������
    if (sizeofSet = 0) then PLuaRecordInfo(ClassInfo._Class).FOperatorCallback(DestCompare, X1.instance^, X2_Value^, loCompare)
    else
    if (X2_type = LUA_TNUMBER) then DestCompare := SetsCompare(X1.instance, integer(X2_Value), sizeofSet, Kind=OPERATOR_LESS_EQUAL)
    else
    DestCompare := SetsCompare(X1.instance, X2_Value, sizeofSet, Kind=OPERATOR_LESS_EQUAL);

    // ��������� DestCompare ���� ��� ����
    if (INDEXES[false] <> 1) then DestCompare := -DestCompare;
    
    // ���������
    case (Kind) of
            OPERATOR_EQUAL: lua_pushboolean(Handle, (DestCompare = 0));
             OPERATOR_LESS: lua_pushboolean(Handle, (DestCompare < 0));
       OPERATOR_LESS_EQUAL: lua_pushboolean(Handle, (DestCompare <= 0));
    end;
  end else
  begin
    // ���������� ��������
    Dest := push_userdata(ClassInfo, true, nil);

    if (sizeofSet = 0) then PLuaRecordInfo(ClassInfo._Class).FOperatorCallback(Dest.instance^, X1.instance^, X2_Value^, TLuaOperator(Kind))
    else
    if (X2_type = LUA_TNUMBER) then
    case (Kind) of
      OPERATOR_ADD: SetsUnion(Dest.instance, X1.instance, integer(X2_Value), sizeofSet);
      OPERATOR_SUB: SetsDifference(Dest.instance, X1.instance, integer(X2_Value), sizeofSet, (INDEXES[false] <> 1));
      OPERATOR_MUL: SetsIntersection(Dest.instance, X1.instance, integer(X2_Value), sizeofSet);
    end
    else
    case (Kind) of
      OPERATOR_ADD: SetsUnion(Dest.instance, X1.instance, X2_Value, sizeofSet);
      OPERATOR_SUB: SetsDifference(Dest.instance, X1.instance, X2_Value, sizeofSet);
      OPERATOR_MUL: SetsIntersection(Dest.instance, X1.instance, X2_Value, sizeofSet);
    end;
  end;
end;
           *)

             (*
// �� ��������� ���� �������� ������ ������������ Create() ��� �������.
// �� ���� ��� �� ���������������� ������������ "�� �����" �� __call(create = false)
// �� ������ �� �������, �� ��� �� �� ��������, ��������, ��������
//
// ������� � ����� ������� ������������, ������ �������� �������� ��������-"�������"
// ��� ������� �������������� ��� ��� ��������� ������ �������� (���� ��� - ������)
function TLua.__constructor(const ClassInfo: TLuaClassInfo; const __create: boolean): integer;
const
  OFFSET = 1; // ����� �� ��������� ������ ��������, ������� �������-"�����"
var
  i: integer;
  userdata: PLuaUserData;
  constructor_address: pointer;
  ArgsCount: integer;
  initialize_mode: boolean;
begin
  Result := 1;

  // �������� �� ������������ �������������
  // ���� ����� ��� ����� ��������� (���� �� ���� ������)
  if (lua_type(Handle,1)<>LUA_TTABLE) or (ClassInfo._ClassIndex<>LuaTableToClass(Handle,1)) then
  ScriptAssert('Incorrect usage of %s constructor.', [ClassInfo._ClassName]);

  // �������� userdata, ��������� ������� �������������
  // ���� � ������ ������ - ����� Instance, ���� � ������ ������� ���� - ��������� �� ������ ������ ����
  userdata := push_userdata(ClassInfo, not __create, nil);
  if (ClassInfo._ClassKind = ckClass) then userdata.instance := pointer(TClass(ClassInfo._Class).NewInstance);


  // ���������� ���������� ����������,
  // �������� �� ��������� �������� "���������������� ��������"
  initialize_mode := false;
  ArgsCount := lua_gettop(Handle)-OFFSET-{userdata}1;
  if (ArgsCount > 0) then
  begin
     if (lua_type(Handle,-2)=LUA_TTABLE) and (LuaTableToClass(Handle,-2)<0) then
     begin
       initialize_mode := true;
       dec(ArgsCount);
     end;
  end;

  // �������� �� ����������� ������������� �� �������
  // � ������� �������� ����� ������������� �� ���� �����
  // todo ?
  if (initialize_mode) and (userdata.kind <> ukInstance) then
  ScriptAssert('%s can not be initialized by a table.', [ClassInfo._ClassName]);


  // ���� �� ukInstance
  case (userdata.kind) of
      ukArray:  begin
                  __array_include(0{constructor_mode});
                  exit;
                end;
        ukSet:  begin
                  __set_method(true, 0{include_mode});
                  exit;
                end;
  else
    if (userdata.kind <> ukInstance) then {������ ���� �� ������} exit;

    // TLuaReference - ������ ������, ��� ���� ������������ ���� ����������� (�� �����)
    if (ClassInfo._ClassIndex = TLUA_REFERENCE_CLASS_INDEX) then
    begin
      if (ArgsCount < 0) or (ArgsCount > 1) then ScriptAssert('Wrong arguments count(%d) of TLuaReference() constructor', [ArgsCount]);

      // ������������������� ������
      if (ArgsCount = 0) then lua_pushnil(Handle) else lua_pushvalue(Handle, -2);
      TLuaReference(userdata.instance).Initialize(Self);

      exit;
    end;
  end;


  // ����� ���� �������� �����������
  // ���� �������� - �������� (�������������� �����������)
  if (ClassInfo.constructor_address <> nil) then
  begin
    // ��������� ������ ����������
    FArgsCount := ArgsCount;
    SetLength(FArgs, ArgsCount);
    for i := 0 to ArgsCount-1 do stack_luaarg(FArgs[i], i+OFFSET+1, true);

    // �������� �� ���������� ����������
    if (ClassInfo.constructor_args_count >= 0) and (FArgsCount <> ClassInfo.constructor_args_count) then
    ScriptAssert('Constructor of %s should have %d arguments', [ClassInfo._ClassName]);

    // �����
    begin
      constructor_address := ClassInfo.constructor_address;
      if (dword(constructor_address) >= $FE000000) then constructor_address := ppointer(dword(userdata.instance^) + dword(constructor_address) and $00FFFFFF)^;

      TLuaClassProc16(constructor_address)(userdata.instance^, FArgs, TLuaArg(nil^));
    end;

    // �������� ���������� ����������, �� ������ ��� ���� FArgs
    FArgsCount := 0;

    // ������ ������ ��� TMethod
    if (ClassInfo._ClassIndex = TMETHOD_CLASS_INDEX) and (pint64(userdata.instance)^ = 0) then
    begin
      lua_remove(Handle, -1);
      lua_pushnil(Handle);
    end;
  end;

  // ���� ��������� �������� ������������� ���� ���������������� �������
  // �� �������� ��������������� (�����������) ����������
  if (initialize_mode) then
  __initialize_by_table(userdata, lua_gettop(Handle)-1 {������ -2 � ������ ���������})
end;            *)
                  (*
function TLua.__destructor(const ClassInfo: TLuaClassInfo; const __free: boolean): integer;
var
  luatype: integer;
  userdata: PLuaUserData;
begin
  Result := 0;

  luatype := lua_type(Handle, 1);
  if (luatype <> LUA_TUSERDATA) then
  ScriptAssert('Wrong destruction type "%s"', [LuaTypeName(luatype)]);

  userdata := lua_touserdata(Handle, 1);

  // �� ���� ������� ������� ��� __gc, ���� �� ����� ���������������� �����
  if (not __free) and (not userdata .gc_destroy) then exit;

  // ���� ��� �����
  if (userdata.instance = nil) then
  begin
    if (__free) then
    ScriptAssert('Instance of %s type is already destroyed', [ClassInfo._ClassName]);

    exit;
  end;

  // �������� ������ ��� �������� � ������� �������
  if (@ClassInfo = nil) then
  with userdata^ do
  begin
    if (kind = ukProperty) then
    with PropertyInfo^ do
    begin
      if (Parameters = NAMED_PROPERTY) then
        pstring(integer(userdata)+sizeof(TLuaUserData))^ := ''
      else
        Finalize(pointer(integer(userdata)+sizeof(TLuaUserData)), PLuaRecordInfo(Parameters).FTypeInfo);
    end;

    instance := nil;
    exit;
  end;

  // ������� ��������� Object-� ��� �������� ���������
  case (ClassInfo._ClassKind) of
     ckClass: TObject(userdata.instance).Free;
    ckRecord: begin
                // �������� Record ������ UserData
                with PLuaRecordInfo(ClassInfo._Class)^ do
                if (FTypeInfo <> nil) then Finalize(userdata.instance, FTypeInfo);
              end;
     ckArray: begin
                // �������� �������
                with PLuaArrayInfo(ClassInfo._Class)^ do
                if (FTypeInfo <> nil) then Finalize(userdata.instance, FTypeInfo, FItemsCount);
              end;
  end;            

  // �������� � ����� ������
  userdata.instance := nil;
end;
                 *)
                   (*
// ������ �������� ����� ������ ����!
// ������ ���������� �����, ����� � ���� (�����, ���������, ������, ���������)
// ��� ��� ���������� ���������� �����
// �������� ���: TButton(Form1), TPoint(12, 13), Form1. OnClick(), ArrayInstance(/*������*/)
//
// ������ ��� �� ���������� ��� ������������� ��������
// �������� ���:
// Button1 {Caption="Text", Color=clBtnFace}
//
// �������������� ����� � ����� ������:
// Button1( {Caption="Text", Color=clBtnFace} )
//
// ��� ��������� ������ ��� �� ����� ���������
function TLua.__call(const ClassInfo: TLuaClassInfo): integer;
var
  userdata: PLuaUserData;
begin
  Result := 0;

  // ���� ������ �������� ������ ����� - �� ������������ � �����������
  if (lua_type(Handle,1)=LUA_TTABLE) and (ClassInfo._ClassIndex=LuaTableToClass(Handle,1)) then
  begin
    Result := __constructor(ClassInfo, false);
    exit;
  end;

  // ������� ������ ����� ���������� "�����" ����������
  // ���� �������, ���� "������������� �� �������", ���� ������


  // "event"
  if (ClassInfo._ClassIndex = TMETHOD_CLASS_INDEX) then
  begin
    userdata := lua_touserdata(Handle, 1);
    if (userdata = nil) or (userdata.ClassIndex <> TMETHOD_CLASS_INDEX) then  ScriptAssert('Wrong TMethod usage', []);

    Result := __tmethod_call(TMethod(userdata.instance^));
    exit;
  end;

  // ���� ���������� ������������� �� �������
  if (lua_gettop(Handle)=2) and (lua_type(Handle,2)=LUA_TTABLE) and (LuaTableToClass(Handle,2)<0) then
  begin
    userdata := lua_touserdata(Handle, 1);
    if (userdata = nil) {�� ������ ���� �� ������} then ScriptAssert('Unsupported operation.', []);

    // �������� �� ����������� ������������� �� �������
    // � ������� �������� ����� ������������� �� ���� �����
    // todo ?
    if (userdata.kind <> ukInstance) then
    ScriptAssert('%s can not be initialized by a table.', [ClassInfo._ClassName]);

    // �����
    __initialize_by_table(userdata, 2);
  end else
  begin
    // 100% ��������� �������� ������ ������������ �� ����������
    // �� � ������������� ����� � ����������� (��� ������ ��������� ���������)
    Result := __constructor(ClassInfo, false);
  end;
end;
             *)
               (*
// �������� ������� �� ������ �������� ���������� ����������
// ������ � ���� ���������
// native - ������ ����� ������� �������� � info
// ����� - ���������� �� lua, ���� ������� �������� � ����
// ��� Exception !
function TLua.__global_index(const native: boolean; const info: TLuaGlobalModifyInfo): integer;
var
  Name: pchar;
  luatype, NameLen, Ind: integer;

  // ������� ������
  procedure Assert(const FmtStr: string; const Args: array of const);
  begin
    if (native) then ELua.Assert(FmtStr, Args, info.CodeAddr)
    else ScriptAssert(FmtStr, Args);
  end;

  // ���� �� ���������� ��������� Variant ��� TLuaArg
  // ���������� � native ������
  procedure AssertUnsupported();
  begin
    lua_settop(Handle, -1-1); //stack_pop(); - ������ �������� �� �����
    Assert('Can''t get global variable "%s" of type "%s"', [info.Name, FBufferArg.str_data]);
  end;

  // �������� ���������� ����������
  procedure PushGlobalProp(const Index: integer; const IsConst: boolean);
  var
    prop_struct: TLuaPropertyStruct;
  begin
    prop_struct.PropertyInfo := @GlobalNative.Properties[not Index];
    prop_struct.Instance := nil;
    prop_struct.IsConst := IsConst;
    prop_struct.Index := nil;
    prop_struct.ReturnAddr := nil;
    if (native) then prop_struct.ReturnAddr := info.CodeAddr;
    
    Self.__index_prop_push(GlobalNative, @prop_struct);
  end;

begin
  // ���������� ������������ ����������
  Result := ord(not native);

  // ��������� �����. ��������
  if (native) then
  begin
    Name := pchar(info.Name);
    NameLen := Length(info.Name);
  end else
  begin
    luatype := lua_type(Handle, 2);
    if (luatype <> LUA_TSTRING) then Assert('Global key should be a string. Type %s is not available as global key', [LuaTypeName(luatype)]);
    Name := lua_tolstring(Handle, 2, @NameLen);
  end;

  // ��������� ��� ������
  if (not GlobalVariablePos(Name, NameLen, Ind)) then
  Assert('Global variable "%s" not found', [Name]);

  // ����: ���� ���������� �� ���� lua
  if (not native) then
  begin
    with GlobalVariables[Ind] do
    begin
      if (_Kind in GLOBAL_INDEX_KINDS) then
      begin
        lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
      end else
      if (Index >= 0) then
      begin
        lua_pushcclosure(Handle, GlobalNative.Procs[Index].lua_CFunction, 0);
      end else
      begin
        // ��������� �������� ���������� ���������� � ���-����
        PushGlobalProp(Index, IsConst);
      end;
    end;

    exit;
  end;

  // ����: ��������� ���� ������� � info.Arg^
  if (not info.IsVariant) then
  begin
    with GlobalVariables[Ind] do
    begin
      if (_Kind in GLOBAL_INDEX_KINDS) then
      begin
        lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
        if (not stack_luaarg(info.Arg^, -1, false)) then AssertUnsupported();
        lua_settop(Handle, -1-1); //stack_pop();
      end else
      if (Index >= 0) then
      begin
        info.Arg.AsPointer := GlobalNative.Procs[Index].Address;
      end else
      begin
        PushGlobalProp(Index, IsConst);
        if (not stack_luaarg(info.Arg^, -1, false)) then AssertUnsupported();
        lua_settop(Handle, -1-1); //stack_pop();        
      end;
    end;

    exit;
  end;

  // ����: ��������� ���� ������� � info.V^: variant
  begin
    with GlobalVariables[Ind] do
    begin
      if (_Kind in GLOBAL_INDEX_KINDS) then
      begin
        lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
        if (not stack_variant(info.V^, -1)) then AssertUnsupported();
        lua_settop(Handle, -1-1); //stack_pop();
      end else
      if (Index >= 0) then
      begin
        Assert('"%s" is a method. Variant type does not support methods', [Name]);
      end else
      begin
        // ��������� ��������, �� �� � Arg, � � Variant
        PushGlobalProp(Index, IsConst);
        if (not stack_variant(info.V^, -1)) then AssertUnsupported();
        lua_settop(Handle, -1-1); //stack_pop();
      end;
    end;

    exit;
  end;      
end;
         *) (*
// �������� ������� �� ��������� �������� ���������� ����������
// � ���� ���������
// native - ������ ��� � �������� ������� �� info
// ����� - �� �����
// ���� ���������� ���������� �����������, �� Exception !
function TLua.__global_newindex(const native: boolean; const info: TLuaGlobalModifyInfo): integer;
type
  TIntToStr = procedure(const Value: integer; var Ret: string);

var
  Name: pchar;
  luatype, NameLen, Ind: integer;
  GlobalVariable: ^TLuaGlobalVariable;

  // ������� ������
  procedure Assert(const FmtStr: string; const Args: array of const);
  begin
    if (native) then ELua.Assert(FmtStr, Args, info.CodeAddr)
    else ScriptAssert(FmtStr, Args);
  end;

  // push ����� ������, ������� ���� ������� Exception
  procedure AssertUnsupported();
  const
    DESCRIPTION: array[boolean] of string = ('argument', 'variant');
  begin
    Assert('Unsupported %s type = "%s"', [DESCRIPTION[info.IsVariant], FBufferArg.str_data]);
  end;

  // ����� �������� �� ����� � ��������� ����� �������� ���������� ����������
  procedure FillGlobalProp(const Index: integer);
  var
    prop_struct: TLuaPropertyStruct;
  begin
    prop_struct.PropertyInfo := @GlobalNative.Properties[not Index];
    prop_struct.Instance := nil;
    prop_struct.StackIndex := -1;
    prop_struct.Index := nil;
    prop_struct.ReturnAddr := nil;
    if (native) then prop_struct.ReturnAddr := info.CodeAddr;

    Self.__newindex_prop_set(GlobalNative, @prop_struct);
  end;

begin
  Result := 0;

  // ��������� �����. ��������
  if (native) then
  begin
    Name := pchar(info.Name);
    NameLen := Length(info.Name);
  end else
  begin
    luatype := lua_type(Handle, 2);
    if (luatype <> LUA_TSTRING) then Assert('Global key should be a string. Type %s is not available as global key', [LuaTypeName(luatype)]);
    Name := lua_tolstring(Handle, 2, @NameLen);
  end;

  // ����: ����� ���������� ����������
  // ���� �� �������, �� ������� ����� (��� gkLuaData), ��������� ���������
  if (not GlobalVariablePos(Name, NameLen, Ind, true)) then
  begin
    with GlobalVariables[Ind] do
    begin
      _Kind := gkLuaData;
      IsConst := false;
      global_alloc_ref(Ref);

      if (not native) then lua_pushvalue(Handle, 3)
      else
      if (not info.IsVariant) then
      begin
        if (not push_luaarg(info.Arg^)) then AssertUnsupported()
      end else
      if (not push_variant(info.V^)) then AssertUnsupported();

      global_fill_value(Ref);
    end;

    exit;    
  end;

  // �������� �� ����������� ���������
  GlobalVariable := @GlobalVariables[Ind];
  if (GlobalVariable.IsConst) then
  Assert('Global const "%s" can not be changed', [Name]);

  { �� ������� ������ �������� ��������� ����������: }
  { gkLuaData � gkVariable. �� ! ������ Variable 100% �� �����������! }


  // ����: ���������� ���������� �� ���� lua
  if (not native) then
  begin
    with GlobalVariable^ do
    if (_Kind = gkLuaData) then
    begin
      lua_pushvalue(Handle, 3);
      lua_rawseti(Handle, LUA_REGISTRYINDEX, Ref); //global_fill_value(Ref);
    end else
    begin
      // ����� ������� �� ����� � �������� � ���������� ����������
      FillGlobalProp(Index);
    end;

    exit;
  end;

  // ����: ���������� ���������� �� info.Arg^
  if (not info.IsVariant) then
  begin
    with GlobalVariable^ do
    if (_Kind = gkLuaData) then
    begin
      if (not push_luaarg(info.Arg^)) then AssertUnsupported();
      lua_rawseti(Handle, LUA_REGISTRYINDEX, Ref); //global_fill_value(Ref);
    end else
    begin
      if (not push_luaarg(info.Arg^)) then AssertUnsupported();
      FillGlobalProp(Index);
      lua_settop(Handle, -1-1); //stack_pop();
    end;

    exit;
  end;

  // ����: ���������� ���������� �� info.V^: Variant
  begin
    with GlobalVariable^ do
    if (_Kind = gkLuaData) then
    begin
      if (not push_variant(info.V^)) then AssertUnsupported();
      lua_rawseti(Handle, LUA_REGISTRYINDEX, Ref); //global_fill_value(Ref);
    end else
    begin
      if (not push_variant(info.V^)) then AssertUnsupported();
      FillGlobalProp(Index);
      lua_settop(Handle, -1-1); //stack_pop();
    end;

    exit;       
  end;
end;     *)
           (*
// �������� ���� Prefix[...][...][Value][...][...][...]
// ��� Prefix[...][...].Value
function __arrayindex_description(const Prefix, Value: string; const Index, Dimention: integer): string;
var
  i: integer;
begin
  Result := Prefix;

  if (Dimention > 0) then
  begin
    // array style
    for i := 0 to Dimention-1 do
    if (i = Index) then Result := Result + '[' + Value + ']'
    else Result := Result + '[...]';
  end else
  begin
    // property style
    for i := 0 to Index-1 do
    Result := Result + '[...]';

    Result := Result + '.' + Value;
  end;  
end;     *)
           (*
// ��������� �������� �� lua-����� �� ������� 2 � ������� � ��������� �������� (��� �������� ��������)
// ���� ������ - �� ��������� ������ !
// ���������� true ���� ����� ����� ���������� ������
// index = (property: ������ ���������� ��������), (array: ��������� �� �������� ������)
function __read_array_parameter(const Lua: TLua; const userdata: PLuaUserData; var index: pointer): boolean;
var
  Value: double;
  param_number, low, high: integer;
  array_index: integer absolute index;

  // Exception ��������� ������� � �������
  procedure ThrowBounds();
  var
    array_instance: pointer;
    S: string;
  begin
    with userdata^ do
    begin
      array_instance := userdata.instance;
      if (userdata.ArrayInfo.IsDynamic) then array_instance := ppointer(array_instance)^;

      S := __arrayindex_description(ArrayInfo.Name, IntToStr(array_index), param_number, ArrayInfo.Dimention)
    end;
    
    Lua.ScriptAssert('Wrong bounds in array %s. Array pointer = %p. Available bounds = %d..%d', [S, array_instance, low, high]);
  end;

  // ��������� (������ � ����� - 2)
  procedure FillPropValue(const PropertyInfo: PLuaPropertyInfo);
  var
    prop_struct: TLuaPropertyStruct;
  begin
    prop_struct.PropertyInfo := PropertyInfo;
    prop_struct.Instance := index;
    prop_struct.Index := nil;
    prop_struct.StackIndex := 2;
    prop_struct.ReturnAddr := nil; // ������ ��������� � �������� ���������� - ������ �� �������

    Lua.__newindex_prop_set(Lua.GlobalNative, @prop_struct);
  end;  

begin
  with userdata^ do
  if (kind = ukArray) then
  begin
    // ��� ��������
    param_number := integer(array_params) and $F;

    with ArrayInfo^ do
    begin
      // ����� �������
      if (IsDynamic) then
      begin
        if (pinteger(instance)^ = 0) then
        begin
          low := 0;
          high := 0;
          ThrowBounds();
        end else
        begin
          low := 0;
          high := DynArrayLength(instance^)-1;
        end;
      end else
      begin
        low := FBoundsData[param_number*2];
        high := FBoundsData[param_number*2+1];
      end;

      // ����� �� �������
      if (array_index < low) or (array_index > high) then
      ThrowBounds();

      // ������ ��������� ���������
      if (array_index = low) then
      begin
        // �������, ����� �������� �� ��������������
        if (not IsDynamic) then index := instance
        else index := ppointer(instance)^;
      end else
      if (not IsDynamic) then
      begin
        // �������� �� ������������ �������
        index := pointer(integer(instance)+(array_index-low)*FMultiplies[param_number]);
      end else
      begin
        // �������� �� ������������� �������
        if (param_number = Dimention-1) then index := pointer(pinteger(instance)^+array_index*FItemSize)
        else index := pointer(pdword(instance)^+dword(array_index)*4)
      end;              
    end;

    __read_array_parameter := (byte((param_number+1)and$F) = (array_params shr 4));
  end else
  begin
    // ��������
    index := pointer(integer(userdata)+sizeof(TLuaUserData));

    with PropertyInfo^ do
    case integer(Parameters) of
      integer(INDEXED_PROPERTY): begin
                                   Value := lua_tonumber(Lua.Handle, 2);
                                   NumberToInteger(Value, pinteger(index)^);
                                   index := ppointer(index)^;
                                 end;
        integer(NAMED_PROPERTY): begin
                                   lua_to_pascalstring(pstring(index)^, Lua.Handle, 2);
                                   index := ppointer(index)^;
                                 end;
    else
      with Lua, ClassesInfo[PLuaRecordInfo(Parameters).FClassIndex] do
      begin
        //stack_luaarg(FBufferArg, 2, false);
        //Properties[array_params and $F]._Set(Lua, index, FBufferArg);
        FillPropValue(@Properties[array_params and $F]);

        if (PLuaRecordInfo(Parameters).Size <= 4) then  // �� ������ �� ����� ? todo
        index := ppointer(index)^;
      end;
    end;

    inc(array_params);
    __read_array_parameter := (array_params and $F = (array_params shr 4));
  end;
end;       *)
             (*
// ������� ������, ��������� � ������������ �������� ������� ��� ��������
procedure __throw_array_index(const Lua: TLua; const ClassInfo: TLuaClassInfo; const userdata: PLuaUserData; const is_getter: boolean);
const
  CHANGE_GET: array[boolean] of string = ('change', 'get');
  ITEM_PROPERTY: array[boolean] of string = ('item', 'property');
var
  IsClass: boolean;
  IsProperty: boolean;
  Index, Dimention: integer;
  Description: string;

  instance: pointer;
  Error: string;
begin
  IsClass := (userdata = nil);
  IsProperty := (IsClass) or (lua_type(Lua.Handle, 2) = LUA_TSTRING);

  if (IsClass) then Index := 0
  else Index := (userdata.array_params and $F);

  if (IsProperty) then Dimention := 0
  else Dimention := userdata.ArrayInfo.Dimention;

  Description := __arrayindex_description(ClassInfo._ClassName, Lua.StackArgument(2), Index, Dimention);


  // �������� ������
  Error := Format('Can''t %s value of %s %s', [CHANGE_GET[is_getter], Description, ITEM_PROPERTY[IsProperty]]);

  // instance
  if (not IsClass) then
  begin
    instance := userdata.instance;
    if (userdata.ArrayInfo.IsDynamic) then instance := ppointer(instance)^;

    Error := Error + Format('. Array pointer = %p', [instance]);
  end;  

  // ������
  Lua.ScriptAssert(Error, []);
end;
        *)
            (*
// �������� �� ������������� user-data ��������
function TLua.__array_index(const ClassInfo: TLuaClassInfo; const is_property: boolean): integer;
const
  FAIL_USAGE = pchar(1);
var
  userdata, dest: PLuaUserData;
  S: pchar;
  luatype, SLength, stdindex: integer;

  Number: double; 
  index: pointer absolute Number;
  array_index: integer absolute index;

  // ���������� ������� �����, ������ ��� �������� - ���������
  procedure ThrowConst();
  begin
    ScriptAssert('%s() method can''t be called, because %s instance is const', [S, ClassInfo._ClassName]);
  end;

  // push �������� ��������
  procedure PushPropertyValue(const PropertyInfo: PLuaPropertyInfo; const Instance: pointer; const IsConst: boolean; const Index: pointer);
  var
    prop_struct: TLuaPropertyStruct;
  begin
    prop_struct.PropertyInfo := PropertyInfo;
    prop_struct.Instance := Instance;
    prop_struct.IsConst := IsConst;
    prop_struct.Index := Index;
    prop_struct.ReturnAddr := nil; // ������ ��������� � �������� ���������� - ������ �� �������
    
    Self.__index_prop_push(ClassInfo, @prop_struct);
  end;


begin
  Result := 1;

  // ��������� userdata � ���������� �� ������� ���������
  if (not __read_lua_arguments(Handle, userdata, S, luatype, SLength, stdindex)) then
  begin
    lua_pushnil(Handle);
    exit;
  end;


  { -- ��������� �������� �������� -- }
  if (is_property) then
  begin
    // ��������� ��������� ��������
    // ���� ��������� ���������� ����������, �� ������� �������� �� ��������
    if (__read_array_parameter(Self, userdata, index)) then
    begin
      PushPropertyValue(userdata.PropertyInfo, userdata.instance, false, index);
    end else
    begin
      // ������� Userdata � �������� ����������
      lua_insert(Handle, 1); // swap. param -> userdata
      lua_pushnil(Handle);
      lua_insert(Handle, 1); // nil, param, userdata (result)
    end;

    // �����
    exit;
  end;

  { -- ������ ��� ���� ������ ��� �������� -- }


  // ���������� ��������� ������������� �������
  // ����������� ���� �������� (������� ���� ������ ����� �� ��������� � ����������)
  // ���� ������� (��� "�������" � �������� �������� - ���� ������)
  if (stdindex < 0) then
  begin
    if (userdata = nil) then S := FAIL_USAGE
    else
    if (luatype = LUA_TNUMBER) then
    begin
      if (not NumberToInteger(Number, Handle, 2)) then S := FAIL_USAGE;
    end else
    S := FAIL_USAGE;
  end;

  // ����������� �������� ��� ����� �������
  if (stdindex > 0) then
  begin
    // ��� ����������� ���
    case (stdindex) of
         // �����������
           STD_TYPE: begin
                       if (userdata = nil) or (userdata.array_params and $F = 0) then
                         global_push_value(ClassInfo.Ref)
                       else
                         lua_pushnil(Handle);
                         
                       exit;
                     end;
      STD_TYPE_NAME: begin
                       if (userdata = nil) or (userdata.array_params and $F = 0) then
                         lua_push_pascalstring(Handle, ClassInfo._ClassName)
                       else
                         lua_push_pascalstring(Handle, 'UNKNOWN_ARRAY');

                       exit;
                     end;
    STD_TYPE_PARENT: begin
                       lua_pushnil(Handle);
                       exit;
                     end;
  STD_INHERITS_FROM: begin
                       lua_pushcclosure(Handle, lua_CFunction(cfunction_inherits_from), 0);
                       exit;
                     end;                     
         STD_ASSIGN: begin
                       if (userdata <> nil) and (userdata.array_params and $F = 0) then
                       begin
                         if (userdata.is_const) then ThrowConst();
                         lua_pushcclosure(Handle, lua_CFunction(cfunction_assign), 0);
                         exit;
                       end;
                     end;
         STD_IS_REF: begin
                       lua_pushboolean(Handle, (userdata <> nil) and (not userdata.gc_destroy));
                       exit;
                     end;
       STD_IS_CONST: begin
                       lua_pushboolean(Handle, (userdata <> nil) and (userdata.is_const));
                       exit;
                     end;                                       
       STD_IS_CLASS: begin
                       lua_pushboolean(Handle, false);
                       exit;
                     end;
      STD_IS_RECORD: begin
                       lua_pushboolean(Handle, false);
                       exit;
                     end;
       STD_IS_ARRAY: begin
                       lua_pushboolean(Handle, true);
                       exit;
                     end;
         STD_IS_SET: begin
                       lua_pushboolean(Handle, false);
                       exit;
                     end;
       STD_IS_EMPTY: begin
                       if (userdata = nil) then lua_pushboolean(Handle, false)
                       else
                       if (userdata.ArrayInfo.IsDynamic) then lua_pushboolean(Handle, integer(userdata.instance^) = 0)
                       else
                       lua_pushboolean(Handle, IsMemoryZeroed(userdata.instance, PLuaArrayInfo(ClassInfo._Class).FSize));

                       exit;
                     end;   
        // �� ��������
            STD_LOW: begin
                       with PLuaArrayInfo(ClassInfo._Class)^ do
                       if (IsDynamic) then lua_pushinteger(Handle, 0)
                       else
                       if (userdata = nil) then lua_pushinteger(Handle, FBoundsData[0])
                       else
                       lua_pushinteger(Handle, FBoundsData[(userdata.array_params and $F) * 2]);

                       exit;
                     end;
           STD_HIGH: begin
                       with PLuaArrayInfo(ClassInfo._Class)^ do
                       if (IsDynamic) then
                       begin
                         if (userdata = nil) then lua_pushinteger(Handle, -1)
                         else lua_pushinteger(Handle, DynArrayLength(userdata.instance^)-1);
                       end else
                       begin
                         if (userdata = nil) then lua_pushinteger(Handle, FBoundsData[1])
                         else
                         lua_pushinteger(Handle, FBoundsData[(userdata.array_params and $F) * 2 + 1]);
                       end;

                       exit;
                     end;
         STD_LENGTH: begin
                       with PLuaArrayInfo(ClassInfo._Class)^ do
                       if (IsDynamic) then
                       begin
                         if (userdata = nil) then lua_pushinteger(Handle, 0)
                         else lua_pushinteger(Handle, DynArrayLength(userdata.instance^));
                       end else
                       begin
                         if (userdata = nil) then array_index := 0
                         else array_index := (userdata.array_params and $F) * 2;

                         lua_pushinteger(Handle, FBoundsData[array_index+1]-FBoundsData[array_index]+1);
                       end;

                       exit;
                     end;
         STD_RESIZE: if (userdata <> nil)and (PLuaArrayInfo(ClassInfo._Class)^.IsDynamic) then
                     begin
                       if (userdata.is_const) then ThrowConst();
                       lua_pushcclosure(Handle, lua_CFunction(cfunction_dynarray_resize), 0);
                       exit;
                     end;
        STD_INCLUDE: if (userdata <> nil) and (userdata.array_params and $F + 1 = userdata.array_params shr 4) then
                     begin
                       if (userdata.is_const) then ThrowConst();
                       lua_pushcclosure(Handle, lua_CFunction(cfunction_array_include), 0);
                       exit;
                     end;        
    end;
  end;

  
  // ���� ������������ ������������� ������� - �� ������� ������
  if (S <> nil) then
  begin
    __throw_array_index(Self, ClassInfo, userdata, true);
  end;
                                

  // ���������� ����� � �������� �������� ��� ������������� ��������
  // ����������� ������ = array_index
  // ����� �����! �� ����� index - ��� array index, � �� ������ ��� ���������������� ��������� !

  if (__read_array_parameter(Self, userdata, index)) then
  begin
    PushPropertyValue(@TLuaPropertyInfo(userdata.ArrayInfo.ItemInfo), index, userdata.is_const, nil);
  end else
  begin
    // ������� Userdata � �������� ����������
    dest := PLuaUserData(lua_newuserdata(Handle, sizeof(TLuaUserData)));
    dest^ := userdata^;

    with dest^ do
    begin
      instance := index;
      inc(array_params);
      gc_destroy := false;
    end;

    // �����������
    lua_rawgeti(Handle, LUA_REGISTRYINDEX, ClassInfo.Ref); // global_push_value(Ref);
    lua_setmetatable(Handle, -2);
  end;
  
end;     *)
           (*
// �������� userdata-������
function TLua.__array_newindex(const ClassInfo: TLuaClassInfo; const is_property: boolean): integer;
const
  FAIL_USAGE = pchar(1);
var
  userdata: PLuaUserData;
  S: pchar;
  luatype, SLength, stdindex: integer;

  Number: double;
  index: pointer absolute Number;
  array_index: integer absolute index;

  // ������������ ���������� ����� ���-�� ��������
  procedure ThrowBounds();
  var
    params: integer;
    Kind, Prefix, Value: string;
  begin
    if (is_property) then
    begin
      Kind := 'property';
      Prefix := userdata.PropertyInfo.PropertyName;
    end else
    begin
      Kind := 'array';
      Prefix := userdata.ArrayInfo.Name;
    end;
    Value := StackArgument(2);
    params := userdata.array_params;

    ScriptAssert('Can not change %s %s: not anought parameters',
                [Kind, __arrayindex_description(Prefix, Value, (params-ord(is_property))and $F, params shr 4)]);
  end;


  // ���������� ���� ������������ ������� ��������� ������������ �������
  procedure ThrowConstant();
  var
    params: integer;
    Err: string;
  begin
    params := userdata.array_params;
    Err := __arrayindex_description(ClassInfo._ClassName, StackArgument(2), params and $F, params shr 4);

    if (stdindex = STD_LENGTH) then Err := 'Can not change Length of constant array '+Err
    else Err := 'Can not change constant array %s'+Err;

    ScriptAssert(Err, []);
  end;


  // ������������� ����� �������� ������ ������������� �������
  // � �������� ����������� - (-1) ��� ������ �� integer
  procedure ThrowLengthValue();
  var
    Err: string;
  begin
    Err := __arrayindex_description(ClassInfo._ClassName, 'Length', userdata.array_params and $F, 0);

    ScriptAssert('Can''t change %s property, because "%s" is not correct length value', [Err, StackArgument(3)]);
  end;


  // ����� �������� �� �������� ��������� � ���������
  procedure FillPropValue(const PropertyInfo: PLuaPropertyInfo; const Instance: pointer);
  var
    prop_struct: TLuaPropertyStruct;
  begin
    prop_struct.PropertyInfo := PropertyInfo;
    prop_struct.Instance := Instance;
    prop_struct.StackIndex := 3;
    prop_struct.Index := nil;
    prop_struct.ReturnAddr := nil; // ������ ��������� � �������� ���������� - ������ �� �������

    Self.__newindex_prop_set(ClassInfo, @prop_struct);
  end;


begin
  Result := 0;

  // ��������� userdata � ���������� �� ������� ���������
  if (not __read_lua_arguments(Handle, userdata, S, luatype, SLength, stdindex)) then
  begin
    exit;
  end;

  // ��������� �������� 3
  // ���� ��������� ����������, �� ���������, ����� ������
  if (is_property) then
  begin
    if (__read_array_parameter(Self, userdata, index)) then
    begin
      //stack_luaarg(FBufferArg, 3, false);
      //userdata.PropertyInfo._Set(Self, userdata.instance, FBufferArg, index);
      FillPropValue(userdata.PropertyInfo, userdata.instance);
    end else
    begin
      ThrowBounds();
    end;

    exit;
  end;

  { -- ������ ��� ���� ������ ��� �������� -- }

  // ���������� ��������� ������������� �������
  // ����������� ���� �������� (������� ���� ������ ����� �� ��������� � ����������)
  // ���� ������� (��� "�������" � �������� �������� - ���� ������)
  if (stdindex < 0) then
  begin
    if (userdata = nil) then S := FAIL_USAGE
    else
    if (luatype = LUA_TNUMBER) then
    begin
      if (not NumberToInteger(Number, Handle, 2)) then S := FAIL_USAGE;
    end else
    S := FAIL_USAGE;
  end;

  // �������� ����� ������ ������ � � ������������ ��������
  if (stdindex = STD_LENGTH) and (userdata <> nil) and (PLuaArrayInfo(ClassInfo._Class).IsDynamic) then
  begin
    // ���� ������������ ������ �����������, �� � ���� ������ ������ ������
    if (userdata.is_const) then ThrowConstant();

    // �������� �������� Length
    if (lua_type(Handle, 3) <> LUA_TNUMBER) or (not NumberToInteger(Number, Handle, 3))
    or (array_index < 0) then ThrowLengthValue();

    // �������� Length ������������� �������
    with userdata^ do
    DynArraySetLength(pointer(instance^), ptypeinfo(ArrayInfo.FMultiplies[array_params and $F]), 1, @array_index);

    exit;
  end;

  // ���� ������������ ������������� ������� - �� ������� ������
  if (S <> nil) then
  begin
    __throw_array_index(Self, ClassInfo, userdata, false);
  end;

  // ������������ ������
  if (UserData.is_const) then ThrowConstant();
  

  // ���������� ��� ������ - ��������� Bounds
  if (__read_array_parameter(Self, userdata, index)) then
  begin
    //stack_luaarg(FBufferArg, 3, false);
    //TLuaPropertyInfo(userdata.ArrayInfo.ItemInfo)._Set(Self, index, FBufferArg);
    FillPropValue(@TLuaPropertyInfo(userdata.ArrayInfo.ItemInfo), index);
  end else
  begin
    ThrowBounds();
  end;
end;


// �������� ������� ������� � ����� (���������� ����������, ��������)
// � userdata - ������ ��� ������� ������������ ��������
// � �������� ��� ����� ��� ������� ���������������/�������������
// ���� ������������ false, �� userdata �� ������ (������ � ������ ������� ������, �� �����������)
function __inspect_proc_stack(const is_construct: boolean; const Handle: pointer;
           var userdata: PLuaUserData; var ArgsCount, Offset: integer): boolean;
begin
  Result := false;

  if (is_construct) then
  begin
    Offset := ord(lua_type(Handle, 1) = LUA_TTABLE);
    userdata := PLuaUserData(lua_touserdata(Handle, -1));
    ArgsCount := lua_gettop(Handle)-{userdata}1-Offset;
  end else
  begin
    userdata := PLuaUserData(lua_touserdata(Handle,  1));
    Offset := ord(lua_type(Handle, 1) = LUA_TUSERDATA);
    if (Offset = 0) or (userdata = nil) or (userdata.instance = nil) then exit;
    ArgsCount := lua_gettop(Handle)-{userdata}1;
  end;

  if (ArgsCount < 0) then ArgsCount := 0;
  Result := true;  
end;                              


// �������� ������ ������������� ������� (userdata - ������ ��������)
// 2 ������: ������ (is_construct) � ������ (.Resize(...))
function TLua.__array_dynamic_resize(): integer;
var
  userdata: PLuaUserData;
  tpinfo: ptypeinfo;
  ArgsCount, Offset, Dimention, i: integer;
  Arguments: TIntegerDynArray;


  // ���� i-� �������� �� �������� ��� ���� �����
  // ������������ � ��������� �����������
  procedure ThrowArgument(const N: integer);
  begin
    ScriptAssert('Wrong argument �%d of Resize() method = "%s"', [N, FBufferArg.ForceString]);
  end;
begin
  Result := 0;

  if (not __inspect_proc_stack(false, Handle, userdata, ArgsCount, Offset)) then
  ScriptAssert('The first operand of Resize() method should be a dynamic array', []);

  // ���������� �������� ����������� ������������� �������
  tpinfo := userdata.ArrayInfo.FTypeInfo;
  Dimention := 1;
  while (true) do
  begin
    tpinfo := pointer(GetTypeData(tpinfo).elType);
    if (tpinfo <> nil) then tpinfo := ppointer(tpinfo)^;
    if (tpinfo = nil) or (tpinfo.Kind <> tkDynArray) then break;
    inc(Dimention);
  end;

  // �������� ArgsCount
  Dimention := Dimention - userdata.array_params and $F;
  if (ArgsCount = 0) then ScriptAssert('Resize() method has no arguments', []);
  if (ArgsCount > Dimention) then ScriptAssert('Resize(%d arguments) method can''t be called, because maximum array dimention is %d', [ArgsCount, Dimention]);

  // ���������� �������
  SetLength(Arguments, ArgsCount);
  ZeroMemory(pointer(Arguments), ArgsCount*sizeof(integer));
  for i := 1 to ArgsCount do
  begin
    stack_luaarg(FBufferArg, i+Offset, true); 

    with FBufferArg do
    if (LuaType = ltInteger) then
    begin
      if (Data[0] < 0) then ThrowArgument(i);
      if (Data[0] = 0) then break;
      Arguments[i-1] := Data[0];
    end else
    begin
      ThrowArgument(i);
    end;
  end;


  // ��������� ������� �������
  with userdata^ do
  DynArraySetLength(ppointer(instance)^, ptypeinfo(ArrayInfo.FMultiplies[array_params and $F]), ArgsCount, pointer(Arguments));
end;     *)
           (*

// ������� ����� 3 ����������.
// � ������ �������� �� ���������� ���������� (��������) ����� �������
// � ����������� �������� ���������� ���������� "� ����"
// � ������������ - ����������� � �����
// �������� - (��������) �������� ������� ��� (��������) �������, ��� �������� ���������
function TLua.__array_include(const mode: integer{constructor, include, concat}): integer;
const
  DESCRIPTION: array[0..2] of string = (LUA_CONSTRUCTOR, 'Include() method', 'operator ".."');

var
  userdata: PLuaUserData;
  Instance: pointer;
  PropertyInfo: PLuaPropertyInfo;
  DynamicInfo: ptypeinfo;
  ArgsCount, Offset, i: integer;

  UseOneArgument: boolean;
  Len{������� ����������}, CurLen{����������� ����������}, MaxLen{������������ ������ (��� �����������)}: integer;  
  FLow: integer; // Low (��� ��������� �������� � ���������� ��������)
  item_class_index: integer; // ����� ������� �������� ���� ���������� ������� ������� (userdata)

  ItemKind: TLuaPropertyKind;
  ItemInfomation: pointer; // typeinfo ��� __lua_difficult_type__.Info - ������ ������������� ��������
  ItemTypeInfo: ptypeinfo; // nil (��� Move) ��� ������ �������� (��� CopyArray)
  ItemsCount: integer; // ��������� ��� �����������/�����������
  ItemSize: integer; // ������ �������� (��� �����������)

  CopyCount: integer;
  DestInstance, SrcInstance: pointer;

  // ����������� ������
  function MethodName: pchar;
  begin
    FBufferArg.str_data := DESCRIPTION[mode];
    if (userdata <> nil) then FBufferArg.str_data := userdata.ArrayInfo.Name + '.' + FBufferArg.str_data;
    Result := pchar(FBufferArg.str_data);
  end;

  // ���� i-� �������� �� �������� ��� ���� ����� �������� ��� ��� ��� ��������
  procedure ThrowArgument(const N: integer);
  const
    NULL_S: array[boolean] of string = ('', 's');
  var
    Count: integer;
    Description, Bounds: string;
  begin
    stack_luaarg(FBufferArg, N+Offset, true);
    Description := FBufferArg.ForceString;

    if (MaxLen <> 0) and (CurLen > MaxLen) then
    begin
      Count := (CurLen-Len);
      Bounds := Format('. Can''t overflow an array by %d item%s, because max index is %d', [Count, NULL_S[Count>1], (MaxLen-1)+FLow]);
    end;

    ScriptAssert('Wrong argument �%d of %s = "%s"%s', [N, MethodName, Description, Bounds]);
  end;

  // ����� �������� �� ����� � ������� � Instance
  procedure FillPropValue(const StackIndex: integer; const Instance: pointer);
  var
    prop_struct: TLuaPropertyStruct;
  begin
    prop_struct.PropertyInfo := PropertyInfo;
    prop_struct.Instance := Instance;
    prop_struct.StackIndex := StackIndex;
    prop_struct.Index := nil;
    prop_struct.ReturnAddr := nil; // ������ ��������� � �������� ���������� - ������ �� �������

    Self.__newindex_prop_set(Self.ClassesInfo[userdata.ArrayInfo^.FClassIndex], @prop_struct);
  end;

begin
  Result := 0;

  if (not __inspect_proc_stack({is_construct}mode<>1, Handle, userdata, ArgsCount, Offset)) then
  ScriptAssert('The first operand of %s should be an array', [MethodName]);

  if (ArgsCount = 0) then
  begin
    if (mode = 1{Include()}) then ScriptAssert('%s has no arguments', [MethodName]);
    exit;
  end;

  // ���� ����������
  Instance := userdata.instance;
  Len := userdata.array_params and $F;
  CurLen := 0;
  with userdata.ArrayInfo^ do
  begin
    if (mode = 0) and (Dimention > 1) then ScriptAssert('%s should have no arguments, because array dimention = %d', [MethodName, Dimention]);

    PropertyInfo := @TLuaPropertyInfo(ItemInfo);
    ItemKind := PropertyInfo.Base.Kind;
    ItemInfomation := PropertyInfo.Base.Information;
    ItemTypeInfo := GetLuaDifficultTypeInfo(PropertyInfo.Base);
    ItemSize := FItemSize;
    {�������������� ���������} if (ItemKind = pkArray) then ItemsCount := PLuaArrayInfo(ItemInfomation).FItemsCount else ItemsCount := 1;

    // ��� �������� ����������� � userdata-�������
    case (ItemKind) of
      pkObject: item_class_index := 0; 
      pkRecord: item_class_index := PLuaRecordInfo(ItemInfomation).FClassIndex;
       pkArray: item_class_index := integer(ItemInfomation);
         pkSet: item_class_index := integer(ItemInfomation);
    else
      item_class_index := integer($FFFFFFFF);
    end;

    // ��������� ������� ���������� � ������������ ������
    if (IsDynamic) then
    begin
      FLow := 0;
      MaxLen := 0;
      DynamicInfo := ptypeinfo(FMultiplies[Len]);
      if (pinteger(Instance)^ = 0) then Len := 0 else Len := DynArrayLength(ppointer(Instance)^);
    end else
    begin
      inc(Len, Len);
      FLow := FBoundsData[Len];
      MaxLen := FBoundsData[Len+1]-FLow+1;
      DynamicInfo := nil;
      Len := 0;
    end;
  end;


  // ������ ����������
  SrcInstance := nil;
  CopyCount := 0;
  for i := 1 to ArgsCount do
  begin
    UseOneArgument := (lua_type(Handle, i+Offset) <> LUA_TUSERDATA);

    if (not UseOneArgument) then
    begin
      // ��������, ����� �������� - userdata
      // � ������ ������� userdata ����� ���� ��������� ������ �������
      // ������� ���������� ��������. ���� ������� ��������, �� ������������ ���� UseOneArgumnt
      // ���� userdata �������� (���������� ������) � �� �������� - �� ����� ����������� �������
      // � ��������� ������ ThrowArgument(i).

      userdata := lua_touserdata(Handle, i+Offset);
      if (userdata = nil) or (userdata.instance = nil) then continue;


      with userdata^ do
      if (ClassIndex = item_class_index) then UseOneArgument := true
      else
      if (kind = ukArray) and (array_params and $F + 1 = array_params shr 4) then
      begin
        // userdata.instance - ��������(��������������) ������

        with TLuaPropertyInfo(ArrayInfo.ItemInfo) do     
        if (ItemKind = Base.Kind) and (ItemInfomation = Base.Information) then
        begin
          // �� ��������
          // ���������� ������������ � ���������� �� ������ � ����������� ���������� ���������

          if (ArrayInfo.IsDynamic) then
          begin
            SrcInstance := ppointer(userdata.instance)^;
            if (SrcInstance = nil) then continue; // empty dyn array
            CopyCount := DynArrayLength(userdata.instance^);
          end else
          begin
            SrcInstance := userdata.instance;
            CopyCount := ((array_params and $F) shl 1);

            with ArrayInfo^ do
            CopyCount := FBoundsData[CopyCount+1]-FBoundsData[CopyCount]+1;
          end; 
        end else
        ThrowArgument(i);
        
      end else
      if (kind = ukInstance) and (item_class_index = 0{TObject}) and (ClassesInfo[ClassIndex]._ClassKind = ckClass) then
      begin
        UseOneArgument := true;
      end else
      ThrowArgument(i);
    end;


    // �����������. 1�� �������� ��� (�����������) �������
    if (UseOneArgument) then
    begin
      // �������� ���� �������� - ��� ������� � �����
      //stack_luaarg(FBufferArg, i+Offset, false);

      if (MaxLen = 0) then
      begin
        // ������������
        inc(Len);
        DynArraySetLength(pointer(Instance^), DynamicInfo, 1, @Len);
        //PropertyInfo._Set(Self, pointer(pinteger(Instance)^ + (Len-1)*ItemSize), FBufferArg);
        FillPropValue(i+Offset, pointer(pinteger(Instance)^ + (Len-1)*ItemSize));
      end else
      begin
        // �����������
        CurLen := Len+1;
        if (CurLen > MaxLen) then ThrowArgument(i);
        //PropertyInfo._Set(Self, pointer(integer(Instance) + Len*ItemSize), FBufferArg);
        FillPropValue(i+Offset, pointer(integer(Instance) + Len*ItemSize));
        Len := CurLen;
      end;
    end else
    begin
      // �������� ������ ���������
      CurLen := Len+CopyCount;

      if (MaxLen = 0) then
      begin
        // ������������
        DynArraySetLength(pointer(Instance^), DynamicInfo, 1, @CurLen);
        DestInstance := pointer(pinteger(Instance)^ + Len*ItemSize);
      end else
      begin
        // �����������
        if (CurLen > MaxLen) then ThrowArgument(i);
        DestInstance := pointer(integer(Instance) + Len*ItemSize);
      end;

      // ���������� ������ ��� ������ ����� ����������� (����� RTTI)
      if (ItemTypeInfo = nil) then
      begin
        Move(SrcInstance^, DestInstance^, CopyCount*ItemSize);
      end else
      begin
        CopyArray(DestInstance, SrcInstance, ItemTypeInfo, CopyCount*ItemsCount);
      end;

      Len := CurLen;
    end;
  end;      
end;
         *)
           (*
// ������� ��� ����������� ������ �� ������� � ��������� Dest
function  _SetLe_Wrap(const Dest, X1, X2: pointer; const Size: integer): boolean;
begin _SetLe_Wrap := _SetLe(X2, Dest, Size); end;
                 *)
                   (*
// �������� ��� ��������� �����/��������� �� ��������� (userdata) � �����
// ����� ��� �� ���������� � ������������ ��������
function TLua.__set_method(const is_construct: boolean; const method: integer{0..2}): integer;
const
  METHOD_NAME: array[0..2] of string = ('Include() method', 'Exclude() method', 'Contains() method');
var
  Ret: byte;
  userdata: PLuaUserData;
  ArgsCount, Offset, i: integer;

  FDest: pointer;
  FSetInfo: PLuaSetInfo;
  FSize, FLow, FHigh, FCorrection: integer;
  FBitProc: function(const _Set: pointer; const Bit: integer): byte;
  FSetProc: function(const Dest, X1, X2: pointer; const Size: integer): byte;

  // ����������� ������
  function MethodName: pchar;
  begin
    with FBufferArg do
    begin
      if (is_construct) then str_data := LUA_CONSTRUCTOR else str_data := METHOD_NAME[method];
      if (userdata <> nil) then str_data := userdata.ArrayInfo.Name + '.' + str_data;
      Result := pchar(str_data);
    end;
  end;

  // ���� i-� �������� �� ��������
  procedure ThrowArgument(const N: integer);
  begin
    ScriptAssert('Wrong argument �%d of %s = "%s"', [N, MethodName, FBufferArg.ForceString]);
  end;
begin
  Result := ord(method=2); // ���� ����� "Contains", �� ���� ���������� boolean

  if (not __inspect_proc_stack(is_construct, Handle, userdata, ArgsCount, Offset)) then
  ScriptAssert('The first operand of %s() method should be a set', [MethodName]);

  // ���� ��� ����������
  if (ArgsCount = 0) then
  begin
    if (not is_construct) then ScriptAssert('%s() method has no arguments', [MethodName]);
    exit;
  end;  

  // ���������
  FDest := userdata.instance;
  FSetInfo := userdata.SetInfo;
  FSize := FSetInfo.FSize;
  FLow := FSetInfo.FLow;
  FHigh := FSetInfo.FHigh;
  FCorrection := FSetInfo.FCorrection;

  // �����
  case method of
    0: begin
         FBitProc := pointer(@IncludeSetBit);
         FSetProc := pointer(@SetsUnion);
       end;

    1: begin
         FBitProc := pointer(@ExcludeSetBit);
         FSetProc := pointer(@SetsDifference);
       end;
  else
    //2:
    FBitProc := pointer(@SetBitContains);
    FSetProc := pointer(@_SetLe_Wrap);
  end;



  // ����������
  Ret := 0;
  for i := 1 to ArgsCount do
  begin
    stack_luaarg(FBufferArg, i+Offset, true); 

    with FBufferArg do
    if (LuaType = ltInteger) then
    begin
      if (Data[0] < FLow) or (Data[0] > FHigh) then ThrowArgument(i);
      Ret := FBitProc(FDest, Data[0]-FCorrection);
    end else
    if (LuaType = ltSet) then
    begin
      if (pointer(Data[0]) = nil) or (pointer(Data[1]) <> FSetInfo) then ThrowArgument(i);
      Ret := FSetProc(FDest, FDest, pointer(Data[0]), FSize);
    end else
    begin
      ThrowArgument(i);
    end;

    // ��������� ("Contains")
    if (method = 2) and (Ret = 0) then break;
  end;


  // ��������� ��� "Contains"
  if (method = 2) then
  begin
    lua_pushboolean(Handle, boolean(Ret));
  end;
end;      *)
            (*

function TLua.ProcCallback(const ClassInfo: TLuaClassInfo; const ProcInfo: TLuaProcInfo): integer;
var
  userdata: PLuaUserData;
  luatype, i, class_index: integer;
  arg_offset: integer;
  proc_address: pointer;
  proc_class: TClass;
begin
  FBufferArg.Empty := true;
  FArgsCount := lua_gettop(Handle);

  // �������� Object
  userdata := nil;
  class_index := -1;
  arg_offset := 1;
  if (ClassInfo._Class <> GLOBAL_NAME_SPACE) then
  begin
    // pointer(userdata^) ��� � ������ ������ - nil
    luatype := lua_type(Handle, 1);
    case lua_type(Handle, 1) of
      LUA_TTABLE: begin
                    userdata := nil;
                    class_index := LuaTableToClass(Handle, 1);

                    if (class_index < 0) then ELua.Assert('Operand of "%s" method is not a class', [ProcInfo.ProcName]);
                  end;
   LUA_TUSERDATA: begin
                    userdata := lua_touserdata(Handle, 1);
                    if (userdata = nil) then
                    begin
                      Result := 0; // �� �� ���� ������ �� ������ ����
                      exit;
                    end;
                  end;
    else
      ScriptAssert('Can''t call proc "%s.%s" because the instance is unknown (%s)', [ClassInfo._ClassName, ProcInfo.ProcName, LuaTypeName(luatype)]);
    end;

    // ����������� �������
    if (userdata = nil) and (not ProcInfo.with_class) then
    ScriptAssert('%s.%s is not class method', [ClassInfo._ClassName, ProcInfo.ProcName]);

    // ���� ������� ��� �����
    if (userdata <> nil) and (userdata.instance = nil) then
    ScriptAssert('%s instance is already destroyed. Proc "%s"', [ClassInfo._ClassName, ProcInfo.ProcName]);

    // �������� ������ �����, ���������� ������� ������
    inc(arg_offset); 
    dec(FArgsCount);
  end;

  // ��������� ������ ����������
  SetLength(FArgs, ArgsCount);
  for i := 0 to ArgsCount-1 do stack_luaarg(FArgs[i], i+arg_offset, true);

  // �������� �� ���������� ����������
  if (ProcInfo.ArgsCount >= 0) and (FArgsCount <> ProcInfo.ArgsCount) then
  begin
    if (ClassInfo._Class = GLOBAL_NAME_SPACE) or (ClassInfo._ClassKind <> ckClass) then
      CheckArgsCount(ProcInfo.ArgsCount, ProcInfo.ProcName)
    else
      CheckArgsCount(ProcInfo.ArgsCount, ProcInfo.ProcName, TClass(ClassInfo._Class));
  end;

  // �������
  proc_address := ProcInfo.Address;
  begin
    if (ClassInfo._Class = GLOBAL_NAME_SPACE) then
    begin
      TLuaProc2(ProcInfo.Address)(FArgs, FBufferArg) // ����������
    end else
    begin
      if (userdata = nil) then proc_class := TClass(ClassesInfo[class_index]._Class) else proc_class := TClass(userdata.instance^);
      if (dword(proc_address) >= $FE000000) then proc_address := ppointer(dword(proc_class) + dword(proc_address) and $00FFFFFF)^;

      if (userdata = nil) then
        TLuaClassProc23(proc_address)(proc_class, FArgs, FBufferArg) // ���������
      else
      if (ProcInfo.with_class) then
        TLuaClassProc23(proc_address)(proc_class, FArgs, FBufferArg) // ���������, �� ����� ������
      else
        TLuaClassProc9(proc_address)(TObject(userdata.instance), FArgs, FBufferArg) // ������� � �������� ������
    end;
  end;

  // ���������
  FArgsCount := 0; // FArgs �� ����������, ����� �������� �������������� ��������� � �������������
  if (not push_luaarg(FBufferArg)) then ELua.Assert('Can''t return value type "%s"', [FBufferArg.str_data], proc_address);
  Result := 1; // �.�. ��������� ������ ����, ���� ���� nil
end;    *)
          (*
function TLua.VariableExists(const Name: string): boolean;
var
  Ind: integer;
  luatype: integer;
begin
  if (not FInitialized) then INITIALIZE_NAME_SPACE();

  if (GlobalVariablePos(pchar(Name), Length(Name), Ind)) then
  with GlobalVariables[Ind] do
  if (_Kind in [gkType, gkVariable, gkConst]) then
  begin
    // ��� (�����/���������), �������� ���������� ��� Enum
    Result := true;
    exit;
  end else
  if (_Kind = gkLuaData) then
  begin
    // ���������� � ���������� �������
    lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
    luatype := (lua_type(Handle, -1));
    lua_settop(Handle, -1-1); //stack_pop();

    Result := (luatype <> LUA_TNONE) and (luatype <> LUA_TFUNCTION);
    exit;
  end;

  Result := false;
end;   *)
         (*
function TLua.ProcExists(const ProcName: string): boolean;
var
  Ind: integer;
begin
  if (not FInitialized) then INITIALIZE_NAME_SPACE();

  if (GlobalVariablePos(pchar(ProcName), Length(ProcName), Ind)) then
  with GlobalVariables[Ind] do
  if (_Kind = gkProc) then
  begin
    // �������� ���������� ���������
    Result := true;
    exit;
  end else
  if (_Kind = gkLuaData) then
  begin
    // ���������� � ���������� �������
    lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
    Result := (lua_type(Handle, -1) = LUA_TFUNCTION);
    lua_settop(Handle, -1-1); //stack_pop();
    exit;
  end;

  Result := false;
end;    *)
          (*
procedure __TLuaCall_luaargs(const Self: TLua; const ProcName: string; const _Args: TLuaArgs;
                            var Result: TLuaArg; const ReturnAddr: pointer);
var
  Found: boolean;
  i, Ind, ret,RetCount: integer;    
begin
  with Self do
  begin
    if (not FInitialized) then INITIALIZE_NAME_SPACE();

    // �������� ��������������� cfunction ���� ������
    Found := GlobalVariablePos(pchar(ProcName), Length(ProcName), Ind);
    if (Found) then
    with GlobalVariables[Ind] do
    if (_Kind = gkLuaData) then
    begin
      lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
      if (lua_type(Handle, -1) <> LUA_TFUNCTION) then
      begin
        Found := false;
        stack_pop();
      end;
    end else
    begin
      Found := (_Kind = gkProc);
      if (Found) then lua_pushcclosure(Handle, GlobalNative.Procs[Index].lua_CFunction, 0);
    end;

    // ���� ������� �� �������
    if (not Found) then
    ELua.Assert('Lua function "%s" not found', [ProcName], ReturnAddr);

    // ��������� ���������
    for i := 0 to Length(_Args)-1 do
    if (not push_luaarg(_Args[i])) then
    begin
      lua_settop(Handle, 0);
      ELua.Assert('Unknown argument type "%s" (arg �%d)', [FBufferArg.str_data, i+1], ReturnAddr)
    end;

    // �����
    ret := lua_pcall(Handle, Length(_Args), LUA_MULTRET, 0);
    if (ret = 0) then ret := lua_gc(Handle, 2{LUA_GCCOLLECT}, 0);
    if (ret <> 0) then Check(ret, ReturnAddr);

    // ���������
    Result.FLuaType := ltEmpty;
    RetCount := lua_gettop(Handle);
    if (RetCount <> 0) then
    begin
      stack_luaarg(Result, 1, false);
      lua_settop(Handle, 0);
    end;
  end;
end;   *)
         (*
function TLua.Call(const ProcName: string; const Args: TLuaArgs): TLuaArg;
asm
  pop ebp
  push [esp]
  jmp __TLuaCall_luaargs
end;    *)

          (*
procedure __TLuaCall__arguments(const Self: TLua; const ProcName: string; const _Args: array of const;
                                var Result: TLuaArg; const ReturnAddr: pointer);
var
  Found: boolean;
  i, Ind, ret, RetCount: integer;
begin
  with Self do
  begin
    if (not FInitialized) then INITIALIZE_NAME_SPACE();

    // �������� ��������������� cfunction ���� ������
    Found := GlobalVariablePos(pchar(ProcName), Length(ProcName), Ind);
    if (Found) then
    with GlobalVariables[Ind] do
    if (_Kind = gkLuaData) then
    begin
      lua_rawgeti(Handle, LUA_REGISTRYINDEX, Ref); //global_push_value(Ref);
      if (lua_type(Handle, -1) <> LUA_TFUNCTION) then
      begin
        Found := false;
        stack_pop();
      end;
    end else
    begin
      Found := (_Kind = gkProc);
      if (Found) then lua_pushcclosure(Handle, GlobalNative.Procs[Index].lua_CFunction, 0);
    end;

    // ���� ������� �� �������
    if (not Found) then
    ELua.Assert('Lua function "%s" not found', [ProcName], ReturnAddr);

    // ��������� ���������
    for i := 0 to Length(_Args)-1 do
    if (not push_argument(_Args[i])) then
    begin
      lua_settop(Handle, 0);
      ELua.Assert('Unknown argument type "%s" (arg �%d)', [FBufferArg.str_data, i+1], ReturnAddr)
    end;

    // �����
    ret := lua_pcall(Handle, Length(_Args), LUA_MULTRET, 0);
    if (ret = 0) then ret := lua_gc(Handle, 2{LUA_GCCOLLECT}, 0);
    if (ret <> 0) then Check(ret, ReturnAddr);

    // ���������
    Result.FLuaType := ltEmpty;
    RetCount := lua_gettop(Handle);
    if (RetCount <> 0) then
    begin
      stack_luaarg(Result, 1, false);
      lua_settop(Handle, 0);
    end;
  end;
end;      *)

            (*
function TLua.Call(const ProcName: string; const Args: array of const): TLuaArg;
asm
  pop ebp
  push [esp]
  jmp __TLuaCall__arguments
end;
        *)
                                           (*
// ��������� ���������� ��������� � ����� ��
// ������������ ���������� ���������� ����������
function __TLuaCheckArgsCount__1(const Self: TLua; const ArgsCount: TIntegerDynArray;
         const ProcName: string; const AClass: TClass; const ReturnAddr: pointer): integer;
begin
  if (Length(ArgsCount) = 0) then
  ELua.Assert('ArgsCount set is not difined', [], ReturnAddr);

  Result := Self.InternalCheckArgsCount(pinteger(ArgsCount), Length(ArgsCount), ProcName, AClass);
end;

function TLua.CheckArgsCount(const ArgsCount: TIntegerDynArray; const ProcName: string=''; const AClass: TClass=nil): integer;
asm
  pop ebp
  push [esp]
  jmp __TLuaCheckArgsCount__1
end;            *)
                     (*
function __TLuaCheckArgsCount_2(const Self: TLua; const ArgsCount: array of integer;
         const ProcName: string; const AClass: TClass; const ReturnAddr: pointer): integer;
begin
  if (Length(ArgsCount) = 0) then
  ELua.Assert('ArgsCount set is not difined', [], ReturnAddr);

  Result := Self.InternalCheckArgsCount(@ArgsCount[0], Length(ArgsCount), ProcName, AClass);
end;

function TLua.CheckArgsCount(const ArgsCount: array of integer; const ProcName: string=''; const AClass: TClass=nil): integer;
asm
  pop ebp
  push [esp]
  jmp __TLuaCheckArgsCount_2
end;              *)
                    (*
procedure TLua.CheckArgsCount(const ArgsCount: integer; const ProcName: string=''; const AClass: TClass=nil);
begin
  InternalCheckArgsCount(@ArgsCount, 1, ProcName, AClass);
end;

procedure __TLuaRegClass(const Self: TLua; const AClass: TClass; const use_published: boolean; const ReturnAddr: pointer);
begin
  Self.InternalAddClass(AClass, use_published, ReturnAddr);
end;

procedure TLua.RegClass(const AClass: TClass; const use_published: boolean);
asm
  push [esp]
  jmp __TLuaRegClass
end;          *)
                   (*
procedure __TLuaRegClasses(const Self: TLua; const AClasses: array of TClass; const use_published: boolean; const ReturnAddr: pointer);
var
  i: integer;
begin
  for i := 0 to high(AClasses) do
  Self.InternalAddClass(AClasses[i], use_published, ReturnAddr);
end;

procedure TLua.RegClasses(const AClasses: array of TClass; const use_published: boolean);
asm
  pop ebp
  push [esp]
  jmp __TLuaRegClasses
end;
        *)
          (*
// tpinfo ����� ����:
// - typeinfo(struct)
// - typeinfo(DynArray of struct)
// - sizeof(struct)
function  __TLuaRegRecord(const Self: TLua; const Name: string; const tpinfo: ptypeinfo; const ReturnAddr: pointer): PLuaRecordInfo;
begin
  Result := PLuaRecordInfo(Self.ClassesInfo[Self.InternalAddRecord(Name, tpinfo, ReturnAddr)]._Class);
end;

function  TLua.RegRecord(const Name: string; const tpinfo: ptypeinfo): PLuaRecordInfo;
asm
  push [esp]
  jmp __TLuaRegRecord
end;             *)
                        (*
// itemtypeinfo - ������� ��� ��� recordinfo ��� arrayinfo
function  __TLuaRegArray(const Self: TLua; const Identifier: pointer; const itemtypeinfo: pointer; const Bounds: array of integer; const ReturnAddr: pointer): PLuaArrayInfo;
begin
  Result := Self.ClassesInfo[Self.InternalAddArray(Identifier, itemtypeinfo, ReturnAddr, Bounds)]._Class;
end;

function  TLua.RegArray(const Identifier: pointer; const itemtypeinfo: pointer; const Bounds: array of integer): PLuaArrayInfo;
asm
  pop ebp
  push [esp]
  jmp __TLuaRegArray
end;
          *)
            (*
function  __TLuaRegSet(const Self: TLua; const tpinfo: ptypeinfo; const ReturnAddr: pointer): PLuaSetInfo;
begin
  Result := Self.ClassesInfo[Self.InternalAddSet(tpinfo, ReturnAddr)]._Class;
end;

function  TLua.RegSet(const tpinfo: ptypeinfo): PLuaSetInfo;
asm
  mov ecx, [esp]
  jmp __TLuaRegSet
end;          *)
                         (*
procedure __TLuaRegProc_global(const Self: TLua; const ProcName: string; const Proc: TLuaProc;
                               const ArgsCount: integer; const ReturnAddr: pointer);
begin
  Self.InternalAddProc(true, nil, ProcName, ArgsCount, false, @Proc, ReturnAddr);
end;

procedure TLua.RegProc(const ProcName: string; const Proc: TLuaProc; const ArgsCount: integer);
asm
  pop ebp
  push [esp]
  jmp __TLuaRegProc_global
end;   *)

         (*
procedure __TLuaRegProc_class(const Self: TLua; const AClass: TClass; const ProcName: string;
          const Proc: TLuaClassProc; const ArgsCount: integer; const with_class: boolean; const ReturnAddr: pointer);
begin
  if (AClass = nil) then
  ELua.Assert('AClass is not defined', [], ReturnAddr);

  Self.InternalAddProc(true, AClass, ProcName, ArgsCount, with_class, TMethod(Proc).Code, ReturnAddr);
end;

procedure TLua.RegProc(const AClass: TClass; const ProcName: string; const Proc: TLuaClassProc; const ArgsCount: integer; const with_class: boolean);
asm
  pop ebp
  push [esp]
  jmp __TLuaRegProc_class
end;
       *)
                 (*
// ���������������� ��������
procedure __TLuaRegProperty(const Self: TLua; const AClass: TClass; const PropertyName: string; const tpinfo: pointer;
          const PGet, PSet: pointer; const parameters: PLuaRecordInfo; const default: boolean; const ReturnAddr: pointer);
begin
  // ������� ��������
  if (AClass = nil) then
  ELua.Assert('AClass is not defined', [], ReturnAddr);

  if (PGet = nil) and (PSet = nil) then
  ELua.Assert('The %s.%s property has no setter and getter', [AClass.ClassName, PropertyName], ReturnAddr);

  // �����������
  Self.InternalAddProperty(true, AClass, PropertyName, tpinfo, false, default, PGet, PSet, parameters, ReturnAddr);
end;

procedure TLua.RegProperty(const AClass: TClass; const PropertyName: string; const tpinfo: pointer; const PGet, PSet: pointer; const parameters: PLuaRecordInfo; const default: boolean);
asm
  pop ebp
  push [esp]
  jmp __TLuaRegProperty
end;    *)
          (*
procedure __TLuaRegVariable(const Self: TLua; const VariableName: string; const X; const tpinfo: pointer; const IsConst: boolean; const ReturnAddr: pointer);
var
  P: pointer;

begin
  P := @X;
  if (P = nil) then
  ELua.Assert('Pointer to variable "%s" is not defined', [VariableName], ReturnAddr);

  // �����������
  Self.InternalAddProperty(true, GLOBAL_NAME_SPACE, VariableName, tpinfo, IsConst, false, P, P, nil, ReturnAddr);
end;

procedure TLua.RegVariable(const VariableName: string; const X; const tpinfo: pointer; const IsConst: boolean);
asm
  pop ebp
  push [esp]
  jmp __TLuaRegVariable
end;     *)
           (*
procedure __TLuaRegConst_variant(const Self: TLua; const ConstName: string; const Value: Variant; const ReturnAddr: pointer);
var
  Ref: integer;
  VarData: TVarData absolute Value;
begin
  // ��������
  if (not IsValidIdent(ConstName)) then
  ELua.Assert('Invalid constant name "%s"', [ConstName], ReturnAddr);

  // ��������� �� Variant
  if (VarData.VType <> varString) and (not(VarData.VType in VARIANT_SUPPORT)) then
  ELua.Assert('Not supported variant value', [], ReturnAddr);

  // �����������
  Ref := Self.internal_register_global(ConstName, gkConst, ReturnAddr).Ref;

  // ���
  if (not Self.push_variant(Value)) then
  ELua.Assert('Not supported variant value "%s"', [Self.FBufferArg.str_data], ReturnAddr);

  // ����������
  Self.global_fill_value(Ref);
end;


procedure TLua.RegConst(const ConstName: string; const Value: Variant);
asm
  push [esp]
  jmp __TLuaRegConst_variant
end;       *)
                          (*
procedure __TLuaRegConst_luaarg(const Self: TLua; const ConstName: string; const Value: TLuaArg; const ReturnAddr: pointer);
var
  Ref: integer;
begin
  // ��������
  if (not IsValidIdent(ConstName)) then
  ELua.Assert('Invalid constant name "%s"', [ConstName], ReturnAddr);

  // ��������� �� Value
  if (byte(Value.LuaType) >= byte(ltTable)) then
  ELua.Assert('Not supported argument value', [], ReturnAddr);

  // �����������
  Ref := Self.internal_register_global(ConstName, gkConst, ReturnAddr).Ref;

  // ���
  if (not Self.push_luaarg(Value)) then
  ELua.Assert('Not supported argument value "%s"', [Self.FBufferArg.str_data], ReturnAddr);

  // ����������
  Self.global_fill_value(Ref);
end;

procedure TLua.RegConst(const ConstName: string; const Value: TLuaArg);
asm
  push [esp]
  jmp __TLuaRegConst_luaarg
end;      *)
                            (*
procedure __TLuaRegEnum(const Self: TLua; const EnumTypeInfo: ptypeinfo; const ReturnAddr: pointer);
var
  i, Ref: integer;
  S: string;
begin
  with Self do
  begin
    // ���� � ������ ����� ��� �������
    if (InsortedPos4(integer(EnumTypeInfo), EnumerationList) >= 0) then exit;

    // ��������
    if (EnumTypeInfo = nil) then
    ELua.Assert('EnumTypeInfo is not defined', ReturnAddr);

    if (EnumTypeInfo.Kind <> tkEnumeration) or (IsTypeInfo_Boolean(EnumTypeInfo)) then
    ELua.Assert('Type "%s" (kind: %s) is not enumeration',
               [EnumTypeInfo.Name, TypeKindName(EnumTypeInfo.Kind)], ReturnAddr);


    // �������� � ������ EnumerationList
    i := InsortedPlace4(integer(EnumTypeInfo), pointer(EnumerationList), Length(EnumerationList));
    ptypeinfo(DynArrayInsert(EnumerationList, typeinfo(TIntegerDynArray), i)^) := EnumTypeInfo;

    // ����������� ������� enum-�
    with GetTypeData(EnumTypeInfo)^ do
    for i := MinValue to MaxValue do
    begin
      S := GetEnumName(EnumTypeInfo, byte(i));

      Ref := internal_register_global(S, gkConst, ReturnAddr).Ref;
      lua_pushinteger(Handle, i);
      global_fill_value(Ref);
    end;
  end;
end;

procedure TLua.RegEnum(const EnumTypeInfo: ptypeinfo);
asm
  mov ecx, [esp]
  jmp __TLuaRegEnum
end;
         *)
                         (*
function TLua.GetUnit(const index: integer): TLuaUnit;
begin
  if (dword(index) >= dword(FUnitsCount)) then
  {$ifdef NO_CRYSTAL}TExcept{$else}EWrongParameter{$endif}.Assert('Can''t get unit[%d]. Units count = %d', [index, FUnitsCount]);

  GetUnit := FUnits[index];
end;

function TLua.GetUnitByName(const Name: string): TLuaUnit;
var
  i: integer;
begin
  for i := 0 to FUnitsCount-1 do
  begin
    Result := FUnits[i];
    if (EqualStrings(Result.FName, Name)) then exit;
  end;

  Result := nil;
end;         *)


{ TLuaUnit }
                     (*
// ������������� Text, ������� ���������� �� �������
procedure TLuaUnit.InitializeLinesInfo();
var
  Last, Current, Max: pchar;

  procedure Add();
  begin
    inc(FLinesCount);
    SetLength(FLinesInfo, FLinesCount);
    with FLinesInfo[FLinesCount-1] do
    begin
      Str := Last;
      Length := integer(Current)-integer(Last);
    end;

    // inc Current
    if (Current^ = #13) and (Current <> Max) and (Current[1] = #10) then inc(Current, 2)
    else inc(Current, 1);

    // Last
    Last := Current;
  end;
begin
  FLinesCount := 0;
  FLinesInfo := nil;
  if (FText = '') then exit;

  Last := pchar(pointer(FText));
  Current := Last;
  Max := pchar(@Last[Length(FText)-1]);

  while (integer(Current) <= integer(Max)) do
  begin
    if (Current^ in [#13, #10]) then Add()
    else
    inc(Current);
  end;

  if (Last <> Current) then Add();
end;

procedure TLuaUnit.SaveToStream(const Stream: TStream);
begin
  Stream.WriteBuffer(pointer(FText)^, Length(FText));
end;

procedure TLuaUnit.SaveToFile(const FileName: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(F);
  finally
    F.Free;
  end;
end;

procedure TLuaUnit.SaveToFile();
begin
  if (FileName <> '') then SaveToFile(FileName)
  else SaveToFile(Name);
end;

function TLuaUnit.GetLine(index: integer): string;
begin
  if (dword(index) >= dword(FLinesCount)) then
  {$ifdef NO_CRYSTAL}TExcept{$else}EWrongParameter{$endif}.Assert('Can''t get line %d from unit "%s". Lines count = %d', [index, Name, FLinesCount]);

  with FLinesInfo[index] do
  AnsiFromPCharLen(Result, Str, Length);
end;

function TLuaUnit.GetLineInfo(index: integer): TLuaUnitLineInfo;
begin
  if (dword(index) >= dword(FLinesCount)) then
  {$ifdef NO_CRYSTAL}TExcept{$else}EWrongParameter{$endif}.Assert('Can''t get line info %d from unit "%s". Lines count = %d', [index, Name, FLinesCount]);

  GetLineInfo := FLinesInfo[index];
end;     *)



initialization
  InitUnicodeLookups;
  InitTypInfoProcs;
  {$ifdef LUA_INITIALIZE}Lua := CreateLua;{$endif}

finalization
  {$ifdef LUA_INITIALIZE}FreeAndNil(Lua);{$endif}
  FreeLuaLibrary;


end.
