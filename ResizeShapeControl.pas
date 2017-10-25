{*
 * Resizeable Shape: A Delphi component written in Pascal offering resizeable shapes and also a container where it can be created.
 * Jonas Raoni Soares da Silva <http://raoni.org>
 * https://github.com/jonasraoni/resizeable-shape-component
 *}

unit ResizeShapeControl;

interface

uses
  Forms, SysUtils, Classes, Graphics, ExtCtrls, Controls, ResizeShape;

type

  TShapeEvent = procedure(Shape: TResizeShape; const Index: Integer) of object;

  TOnAfterAddShapeEvent = procedure(Shape: TResizeShape) of object;

  TResizeShapeControl = class(TScrollBox)
  private
    FShapeList: TList;
    FImage: TImage;
    FRealSize: TPoint;
    FCanDraw: Boolean;
    FIsHandlingShape: Boolean;
    FCurrentShape: TResizeShape;
    FAutoCreate: Boolean;
    FSizeRatio: TRatioRange;
    FOnAddShape: TShapeEvent;
    FOnRemoveShape: TShapeEvent;
    FOnAfterAddShape: TOnAfterAddShapeEvent;

    procedure MyMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MyMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MyMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure SetShape(Index: Integer; const Value: TResizeShape);
    procedure SetImage(const Value: TPicture);
    procedure SetSizeRatio(const Value: TRatioRange);

    function GetShape(Index: Integer): TResizeShape;
    function GetImage: TPicture;
    function GetShapeCount: Integer;

  protected
    property ShapeList: TList read FShapeList write FShapeList;

    procedure Loaded; override;

  public
    InternalData: Pointer;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function IndexOf(const Shape: TResizeShape): Integer;
    function AddShape : TResizeShape;

    procedure CancelShape;
    procedure NewShape;
    procedure DeleteShape( const Index: Integer);
    procedure LoadFromFile( const FileName: String);
    procedure UpdateIt;
    procedure ClearShapes;

    property IsHandling: Boolean read FIsHandlingShape write FIsHandlingShape;
    property Shapes[Index: Integer]: TResizeShape read GetShape write SetShape; Default;
    property ShapeCount: Integer read GetShapeCount;

  published
    property OnAddShape: TShapeEvent read FOnAddShape write FOnAddShape;
    property OnAfterAddShape: TOnAfterAddShapeEvent read FOnAfterAddShape write FOnAfterAddShape;
    property OnRemoveShape: TShapeEvent read FOnRemoveShape write FOnRemoveShape;
    property AutoCreate: Boolean read FAutoCreate write FAutoCreate;
    property SizeRatio: TRatioRange read FSizeRatio write SetSizeRatio;
    property Image: TPicture read GetImage write SetImage;
  end;

implementation

{ TResizeShapeControl }

constructor TResizeShapeControl.Create(AOwner: TComponent);
begin
  inherited;
  VertScrollBar.Style := ssHotTrack;
  HorzScrollBar.Style := ssHotTrack;

  FSizeRatio := 100;
  FAutoCreate := True;
  ControlStyle:= ControlStyle - [csAcceptsControls];
  FShapeList := TList.Create;

  FImage := TImage.Create( Self );
  FImage.Stretch := True;  
  with FImage do begin
    ControlStyle:= ControlStyle - [csFramed];
    Parent := Self;
    Top := 0;
    Width := 0;
    Left := 0;
    Height := 0;
    OnMouseDown := MyMouseDown;
    OnMouseMove := MyMouseMove;
    OnMouseUp := MyMouseUp;
  end;
  GetMem( InternalData, SizeOf(TPoint) );
end;

destructor TResizeShapeControl.Destroy;
begin
  FImage.Free;
  ClearShapes;
  FShapeList.Free;
  FreeMem( InternalData );
  inherited Destroy;
end;

procedure TResizeShapeControl.DeleteShape(const Index: Integer);
begin
  if Assigned( FShapeList.Items[Index] ) then begin
    if Assigned( FOnRemoveShape ) then
      FOnRemoveShape( FShapeList.Items[Index], Index);
    TResizeShape( FShapeList.Items[Index] ).Free;
    FShapeList.Delete( Index );
  end;
end;

procedure TResizeShapeControl.MyMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
begin
  Dec( X, HorzScrollBar.Position );
  Dec( Y, VertScrollBar.Position );
  if Button = mbLeft then begin
    if FAutoCreate then
      NewShape;
    if FIsHandlingShape then begin
      FCanDraw := True;
      FCurrentShape := TResizeShape.Create( Self );
      with FCurrentShape do begin
        Parent := Self;
        BoundsRatio := FSizeRatio;
        Left := X;
        Top := Y;
        Width := 0;
        Height := 0;
      end;
      Index := FShapeList.Add( FCurrentShape );
      if Assigned( FOnAddShape ) then
        FOnAddShape( FCurrentShape, Index );
    end;
  end;
end;

procedure TResizeShapeControl.MyMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  Dec( X, HorzScrollBar.Position );
  Dec( Y, VertScrollBar.Position );
  if FCanDraw then begin
    FCurrentShape.Width := X-FCurrentShape.Left;
    FCurrentShape.Height := Y-FCurrentShape.Top;
  end;
  Application.ProcessMessages;
  PPoint(InternalData)^.X := HorzScrollBar.Position;
  PPoint(InternalData)^.Y := VertScrollBar.Position;
end;

procedure TResizeShapeControl.MyMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FIsHandlingShape then begin
    FCanDraw := False;
    FIsHandlingShape := False;
    Cursor := crDefault;
    with FCurrentShape do begin
      if Width < 0 then begin
        Width := Abs(Width);
        Left := Left-Width;
      end;
      if Height < 0 then begin
        Height:= Abs(Height);
        Top:= Top-Height;
      end;
      RealBounds:=Bounds(
        FCurrentShape.Left+HorzScrollBar.Position,
        FCurrentShape.Top+VertScrollBar.Position,
        FCurrentShape.Width,
        FCurrentShape.Height
      );
    end;

    if Assigned(FOnAfterAddShape) then
      FOnAfterAddShape(FCurrentShape);
    FCurrentShape := nil;
  end;
end;

function TResizeShapeControl.GetShape(Index: Integer): TResizeShape;
begin
  Result := nil;
  if ( Index > -1 ) and ( Index < FShapeList.Count ) then 
    Result:= TResizeShape(FShapeList.Items[Index]);
end;

function TResizeShapeControl.IndexOf(const Shape: TResizeShape): Integer;
begin
  Result := FShapeList.IndexOf(Shape);
end;

procedure TResizeShapeControl.NewShape;
begin
  if Assigned( FImage.Picture ) then begin
    FIsHandlingShape := True;
    Cursor := crCross;
  end;
end;

procedure TResizeShapeControl.CancelShape;
begin
  if FIsHandlingShape then
    if Assigned( FCurrentShape ) then
      FCurrentShape.Free;
  FCanDraw := False;
  FIsHandlingShape:= False;
  Cursor := crDefault;
end;

procedure TResizeShapeControl.SetShape(Index: Integer;
  const Value: TResizeShape);
begin
  if ( Index > -1 ) and ( Index < FShapeList.Count ) then
    FShapeList.Items[Index] := Value;
end;

function TResizeShapeControl.GetImage: TPicture;
begin
  Result := FImage.Picture;
end;

procedure TResizeShapeControl.SetImage(const Value: TPicture);
begin
  if Assigned( Value ) and ( Value <> FImage.Picture ) then begin
    FImage.Picture.Assign( Value );
    UpdateIt;
  end;
end;

procedure TResizeShapeControl.SetSizeRatio(const Value: TRatioRange);
var
  I: Integer;
  Rate: Double;
begin
  if Assigned( FImage.Picture ) then begin
    FSizeRatio := Value;
    Rate := FSizeRatio/100;
    FImage.Width := Round( FRealSize.X * Rate );
    FImage.Height := Round( FRealSize.Y * Rate );

    for I := 0 to Pred( FShapeList.Count ) do
      TResizeShape( FShapeList[I] ).SetBoundsRate( FSizeRatio, VertScrollBar.Position, HorzScrollBar.Position );
  end;
end;

procedure TResizeShapeControl.Loaded;
begin
  inherited Loaded;
  UpdateIt;
end;

procedure TResizeShapeControl.LoadFromFile(const FileName: String);
begin
  if FileExists( FileName ) then begin
    FImage.Picture.LoadFromFile( FileName );

    FRealSize.X := FImage.Picture.Width;
    FRealSize.Y := FImage.Picture.Height;
    
    FImage.Width := Round( FSizeRatio/100*FRealSize.X );
    FImage.Height := Round( FSizeRatio/100*FRealSize.Y );
  end;
end;

function TResizeShapeControl.GetShapeCount: Integer;
begin
  Result := FShapeList.Count;
end;

procedure TResizeShapeControl.UpdateIt;
begin
  HorzScrollBar.Position := 0;
  VertScrollBar.Position := 0;
  FImage.Top := 0;
  FImage.Left := 0;
  FRealSize.X := FImage.Picture.Width;
  FRealSize.Y := FImage.Picture.Height;
  FImage.Stretch := True;
  FImage.Width := FRealSize.X;
  FImage.Height := FRealSize.Y;
end;

function TResizeShapeControl.AddShape: TResizeShape;
var
  Index: Integer;
begin
  Result := TResizeShape.Create( Self );
  with Result do begin
    Parent := Self;
    BoundsRatio := FSizeRatio;
    Left := 0;
    Top := 0;
    Width := 0;
    Height := 0;
  end;
  Index := FShapeList.Add( Result );
  if Assigned( FOnAddShape ) then
    FOnAddShape( Result, Index );
end;

procedure TResizeShapeControl.ClearShapes;
begin
  while FShapeList.Count > 0 do begin
    TResizeShape( FShapeList.Items[0] ).Free;
    FShapeList.Delete( 0 );
  end;
end;

end.
