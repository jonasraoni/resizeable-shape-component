{*
 * Resizeable Shape: A Delphi component written in Pascal offering resizeable shapes and also a container where it can be created.
 * Jonas Raoni Soares da Silva <http://raoni.org>
 * https://github.com/jonasraoni/resizeable-shape-component
 *}

unit ResizeShape;

interface

uses
  SysUtils, Classes, Graphics, Controls, ExtCtrls;

Type
  TResizeType = (
    rtTopLeft, rtTopMiddle, rtTopRight,
    rtMiddleLeft, rtCenter, rtMiddleRight,
    rtBottomLeft, rtBottomMiddle, rtBottomRight
  );

  PPoint = ^TPoint;
  TPoint = Record
    X, Y: Integer;
  End;

  TRatioRange = 1..MaxInt;

  TBounds = record
      Left, Top, Width, Height: Integer;
  end;

  TFocusType = (ftClick, ftMove);

  TMsg = packed record
    hwnd: Cardinal;
    message: Cardinal;
    wParam: Integer;
    lParam: Integer;
    time: LongWord;
    pt: TPoint;
  end;

  TResizeShape = Class(TGraphicControl)
  private
    FPenBuffer: Record
      Color: TColor;
      PenStyle: TPenStyle;
    End;
    FResizeType: TResizeType;
    FOrigin: TPoint;
    FFocused: Boolean;
    FDrawDots: Boolean;
    FResizeable: Boolean;
    FIsResizing: Boolean;
    FOnMouseEnter: TNotifyEvent;
    FOnMouseOut: TNotifyEvent;
    FDotSize: Integer;
    FFocusType: TFocusType;
    FRealBounds: TBounds;
    FBoundsRatio: TRatioRange;
    FDrawBox: Boolean;
    procedure SetFocused(const Value: Boolean);
    procedure SetDrawDots(const Value: Boolean);
    procedure SetResizeType(const Value: TResizeType);
    property ResizeType: TResizeType read FResizeType write SetResizeType;
    procedure SetDotSize(const Value: Integer);
    procedure SetRealBounds(const Value: TBounds);
    procedure SetBoundsRatio(const Value: TRatioRange);
    procedure SetDrawBox(const Value: Boolean);
    
  protected
    procedure MouseEnter(var Msg: TMsg); Message CM_MOUSEENTER;
    procedure MouseLeave(var Msg: TMsg); Message CM_MOUSELEAVE;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure Click; override;
    procedure Loaded; override;

  public
    UserData: Pointer;

    constructor Create(AOwner: TComponent); override;

    procedure SetBoundsRate(Const Ratio: TRatioRange; Const T:Integer=0; L:Integer=0; W:Integer=0; H:Integer=0);
    procedure ApplyRealBounds;

    property RealBounds: TBounds read FRealBounds write SetRealBounds;
    property BoundsRatio: TRatioRange read FBoundsRatio write SetBoundsRatio;
    property IsResizing: Boolean read FIsResizing write FIsResizing;
    property Focused: Boolean read FFocused write SetFocused;

  published
    property DotSize: Integer read FDotSize write SetDotSize;
    property DrawBox: Boolean read FDrawBox write SetDrawBox;
    property DrawDots: Boolean read FDrawDots write SetDrawDots;
    property Resizeable: Boolean read FResizeable write FResizeable;
    property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
    property OnMouseOut: TNotifyEvent read FOnMouseOut write FOnMouseOut;
    property FocusType: TFocusType read FFocusType write FFocusType;
    property OnClick;
    property OnDblClick;

    //inherited properties
    property Align;
    property Anchors;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Constraints;
    property ParentShowHint;
    property ShowHint;
    property Visible;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

function Distance(Const X1,Y1,X2,Y2: Extended): Extended; forward;
function MiddlePt(Const A, B: Extended): Double; forward;
function Bounds(Const L, T, W, H: Integer): TBounds; forward;

implementation

uses ResizeShapeControl;

function Bounds;
begin
  with Result do begin
    Left:=L;
    Top:=T;
    Width:=W;
    Height:=H;
  end;
end;

function Ceil(X: Extended): Integer;
begin
  Result := Integer(Trunc(X));
  if Frac(X) > 0 then
    Inc(Result);
end;

function Distance;
begin
  Result:= Sqrt(Sqr(X1-X2) + Sqr(Y1-Y2));
end;

function MiddlePt;
begin
  Result:= (A+B)/2;
end;

function Point(X,Y: Integer): TPoint;
begin
  Result.X:=X;
  Result.Y:=Y;
end;

{ TResizeShape }

procedure TResizeShape.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if not FResizeable then exit;
  if Button = mbLeft then begin
    FOrigin:= Point(X,Y);
    FIsResizing := true;
    FPenBuffer.PenStyle:=Canvas.Pen.Style;
    FPenBuffer.Color:=Canvas.Pen.Color;
    Canvas.Pen.Style:=psSolid;
    Canvas.Pen.Color:= clGray;
  end;
end;

procedure TResizeShape.MouseEnter(var Msg: TMsg);
begin
  if FFocusType = ftMove then SetFocused(true);
  if Assigned(FOnMouseEnter) then FOnMouseEnter(Self);
end;

procedure TResizeShape.MouseLeave(var Msg: TMsg);
begin
  if FFocusType = ftMove then SetFocused(false);
  if Assigned(FOnMouseOut) then FOnMouseOut(Self);
end;

procedure TResizeShape.MouseMove(Shift: TShiftState; X, Y: Integer);
const
  Threshold = 10;
begin
  inherited Mousemove(Shift, X, Y);
  if not FResizeable then exit;
  if not FIsResizing then begin
         if Distance(0,0,X,Y) < Threshold then SetResizeType(rtTopLeft)
    else if Distance(0,Height/2,X,Y) < Threshold then SetResizeType(rtMiddleLeft)
    else if Distance(0,Height,X,Y) < Threshold then SetResizeType(rtBottomLeft)
    else if Distance(Width/2,Height,X,Y) < Threshold then SetResizeType(rtBottomMiddle)
    else if Distance(Width,Height,X,Y) < Threshold then SetResizeType(rtBottomRight)
    else if Distance(Width,Height/2,X,Y) < Threshold then SetResizeType(rtMiddleRight)
    else if Distance(Width,0,X,Y) < Threshold then SetResizeType(rtTopRight)
    else if Distance(Width/2,0,X,Y) < Threshold then SetResizeType(rtTopMiddle)
    else SetResizeType(rtCenter);
  end
  else case FResizeType of
    rtTopLeft: begin
      Top:= Top + (Y-FOrigin.y);
      Height := Height - (Y-FOrigin.y);
      Left:= Left + (X-FOrigin.x);
      Width := Width - (X-FOrigin.x);
    end;
    rtTopMiddle: begin
      Top:= Top + (Y-FOrigin.y);
      Height := Height - (Y-FOrigin.y);
    end;
    rtTopRight: begin
      Top:= Top + (Y-FOrigin.y);
      Height := Height - (Y-FOrigin.y);
      Width := X;
    end;
    rtMiddleLeft: begin
      Left:= Left + (X-FOrigin.x);
      Width := Width - (X-FOrigin.x);
    end;
    rtCenter: begin
      Top:= Top + (Y-FOrigin.y);
      Left:= Left + (X-FOrigin.x);
    end;
    rtMiddleRight: begin
      Width := X;
    end;
    rtBottomLeft: begin
      Height := Y;
      Left:= Left + (X-FOrigin.x);
      Width := Width - (X-FOrigin.x);
    end;
    rtBottomMiddle: begin
      Height := Y;
    end;
    rtBottomRight: begin
      Height := Y;
      Width := X;
    end;
  end;
end;

procedure TResizeShape.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if FIsResizing then begin
    Cursor:=crDefault;
    FIsResizing:=False;

    Canvas.Pen.Style := FPenBuffer.PenStyle;
    Canvas.Pen.Color := FPenBuffer.Color;
    if Width<0 then begin
      Width:= Abs(Width);
      Left:= Left-Width;
    end;
    if Height<0 then begin
      Height:= Abs(Height);
      Top:= Top-Height;
    end;
    if Parent is TResizeShapeControl then
      SetRealBounds(Bounds(Left+PPoint(TResizeShapeControl(Parent).InternalData)^.X, Top+PPoint(TResizeShapeControl(Parent).InternalData)^.Y, Width, Height))
    else
      SetRealBounds(Bounds(Left, Top, Width, Height));
  end;
end;

procedure TResizeShape.SetDrawDots(const Value: Boolean);
begin
  FDrawDots := Value;
  Invalidate;
end;

procedure TResizeShape.SetFocused(const Value: Boolean);
begin
  FFocused := Value;
  Invalidate;
end;

procedure TResizeShape.SetResizeType(const Value: TResizeType);
begin
  FResizeType := Value;
  case ResizeType of
    rtTopLeft: Cursor:= crSizeNWSE;
    rtTopMiddle: Cursor:= crSizeNS;
    rtTopRight: Cursor:= crSizeNESW;
    rtMiddleLeft: Cursor:= crSizeWE;
    rtCenter: Cursor:= crSizeAll;
    rtMiddleRight: Cursor:= crSizeWE;
    rtBottomLeft: Cursor:= crSizeNESW;
    rtBottomMiddle: Cursor:= crSizeNS;
    rtBottomRight: Cursor:= crSizeNWSE;
  end;
end;

procedure TResizeShape.Paint;

  procedure Fill(X1,Y1,X2,Y2: Integer);
  begin
    Canvas.FillRect(Rect(X1,Y1,X2,Y2));
  end;

begin
  if FDrawBox then
    Canvas.Rectangle( 0, 0, Width, Height );
  if FFocused And FDrawDots then begin
    Canvas.Brush.Style:= bsSolid;
    Canvas.Brush.Color:= clBlack;
    Fill(0,0,FDotSize,FDotSize);
    Fill(0,Ceil(Height/2-FDotSize/2), FDotSize, Ceil(Height/2+FDotSize/2));
    Fill(0,Height-FDotSize,FDotSize,Height);
    Fill(Ceil(Width/2-FDotSize/2),Height-FDotSize,Ceil(Width/2+FDotSize/2),Height);
    Fill(Width-FDotSize,Height-FDotSize,Width,Height);
    Fill(Width-FDotSize,Ceil(Height/2-FDotSize/2),Width,Ceil(Height/2+FDotSize/2));
    Fill(Width-FDotSize,0,Width,FDotSize);
    Fill(Ceil(Width/2-FDotSize/2),0,Ceil(Width/2+FDotSize/2),FDotSize);
    Canvas.Brush.Style:=bsClear;
  end
end;

constructor TResizeShape.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psDot;
  FDrawBox := true;
  FResizeable := true;
  FBoundsRatio := 100;
  FDrawDots := true;
  FFocusType := ftMove;
  UserData := nil;
  FDotSize := 4;
end;

procedure TResizeShape.SetDotSize(const Value: Integer);
begin
  FDotSize := Value;
  Invalidate;
end;

procedure TResizeShape.Click;
begin
  inherited Click;
  if FFocusType = ftClick then SetFocused(not FFocused);
end;

procedure TResizeShape.SetRealBounds(const Value: TBounds);
var Rate: Double;
begin
  Rate := FBoundsRatio/100;
  with FRealBounds do begin
    Left := Round( Value.Left/Rate );
    Top := Round( Value.Top/Rate );
    Width := Round( Value.Width/Rate );
    Height := Round( Value.Height/Rate );
  end;
end;

procedure TResizeShape.SetBoundsRatio(const Value: TRatioRange);
var Rate: Double;
begin
  Rate := FBoundsRatio/100;
  FBoundsRatio := Value;
  with FRealBounds do SetBounds(
    Round( Left*Rate ),
    Round( Top*Rate ),
    Round( Width*Rate ),
    Round( Height*Rate )
  );
end;

procedure TResizeShape.Loaded;
begin
  inherited Loaded;
  SetRealBounds( Bounds( Left, Top, Width, Height ) );
end;

procedure TResizeShape.SetBoundsRate(Const Ratio: TRatioRange; Const T:Integer=0; L:Integer=0; W:Integer=0; H:Integer=0);
var
  Rate: Double;
begin
  FBoundsRatio := Ratio;
  Rate := FBoundsRatio/100;
  with FRealBounds do
    SetBounds(
      Round( Left   * Rate ) - L,
      Round( Top    * Rate ) - T,
      Round( Width  * Rate ) - W,
      Round( Height * Rate ) - H
    );
end;

procedure TResizeShape.ApplyRealBounds;
var
  Rate: Double;
begin
  Rate := FBoundsRatio/100;
  with FRealBounds do
    SetBounds(
      Round( Left   * Rate ),
      Round( Top    * Rate ),
      Round( Width  * Rate ),
      Round( Height * Rate )
    );
end;

procedure TResizeShape.SetDrawBox(const Value: Boolean);
begin
  FDrawBox := Value;
  Invalidate;
end;

end.
