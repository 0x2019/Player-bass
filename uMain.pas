unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, bass, StdCtrls, Buttons, ExtCtrls, ShellApi;

type
  TfrmMain = class(TForm)
    sOpenTrackFile: TOpenDialog;
    tmrPlayBack: TTimer;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    btnPause: TBitBtn;
    btnStop: TBitBtn;
    btnOpenTrackFile: TBitBtn;
    btnPlay: TBitBtn;
    Panel1: TPanel;
    sPlayBack: TScrollBar;
    sVolumeBar: TScrollBar;
    sPlayList1: TListBox;
    sPlayList2: TListBox;
    btnAddPlayList: TSpeedButton;
    btnDeletePlayList: TSpeedButton;
    btnOpenPlayList: TSpeedButton;
    btnSavePlayList: TSpeedButton;
    sOpenPlayList: TOpenDialog;
    sSavePlayList: TSaveDialog;
    PaintBox1: TPaintBox;
    PaintBox2: TPaintBox;
    tmrPlay: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure tmrPlayBackTimer(Sender: TObject);
    procedure sPlayBackScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure btnOpenTrackFileClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnAddPlayListClick(Sender: TObject);
    procedure btnDeletePlayListClick(Sender: TObject);
    procedure sPlayList1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure sPlayList1DblClick(Sender: TObject);
    procedure sVolumeBarScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure btnSavePlayListClick(Sender: TObject);
    procedure btnOpenPlayListClick(Sender: TObject);
    procedure tmrPlayTimer(Sender: TObject);

  private
     procedure AddFiles(FileName: string);
     procedure DropFiles(var Msg: TWMDropFiles);  message WM_DROPFILES;
     procedure PlayItem(Item: Integer);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  bChan: DWORD;
  bFloatable: DWORD;
  bTrack: boolean;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DragAcceptFiles(Handle, True);
  if BASS_Init(-1, 44100, 0, Handle, nil) then
    Exit;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  BASS_Free();
end;

procedure TfrmMain.btnPauseClick(Sender: TObject);
begin
  BASS_ChannelPause(bChan);
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  BASS_ChannelStop(bChan);
  BASS_ChannelSetPosition(bChan, 0, 0);
end;

procedure TfrmMain.tmrPlayBackTimer(Sender: TObject);
begin
  if bTrack = False then
    sPlayBack.Position:= BASS_ChannelGetPosition(bChan, 0);
end;

procedure TfrmMain.sPlayBackScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
  if ScrollCode = scEndScroll then
  begin
    BASS_ChannelSetPosition(bChan, sPlayBack.Position, 0);
    bTrack := False;
  end else
    bTrack := True;
end;

procedure TfrmMain.btnOpenTrackFileClick(Sender: TObject);
begin
  if sOpenTrackFile.Execute = False then Exit;
    AddFiles(sOpenTrackFile.FileName);
    sPlayList1.ItemIndex := sPlayList1.Items.Count -1;
    PlayItem(sPlayList1.ItemIndex);
end;

procedure TfrmMain.btnPlayClick(Sender: TObject);
begin
  if BASS_ChannelisActive(bChan) = BASS_ACTIVE_PAUSED then
    BASS_ChannelPlay(bChan, False)
  else
    PlayItem(sPlayList1.ItemIndex);
end;
Procedure TfrmMain.AddFiles(FileName: string);
begin
  sPlayList2.Items.Add(FileName);
  sPlayList1.Items.Add(ExtractFileName(FileName));

  if sPlayList1.ItemIndex = -1 then
    sPlayList1.ItemIndex := sPlayList1.Items.Count -1;
end;

procedure TfrmMain.btnAddPlayListClick(Sender: TObject);
begin
  if sOpenPlayList.Execute = False then Exit;
    AddFiles(sOpenPlayList.FileName);
end;

procedure TfrmMain.PlayItem(Item: Integer);
begin
  if Item < 0 then Exit;
  if bChan <> 0 then
    BASS_MusicFree(bChan);
    bChan := BASS_MusicLoad(False, PChar(sPlayList2.Items.Strings[Item]), 0, 0, BASS_MUSIC_PRESCAN or bFloatable {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF}, 1);
  if bChan = 0 then
    ShowMessage('Error!')
  else begin
    Panel1.Caption := ExtractFileName(sPlayList1.Items.Strings[Item]);
    sPlayBack.Min := 0;
    sPlayBack.Max := BASS_ChannelGetLength(bChan, 0) -1;
    sPlayBack.Position := 0;
    BASS_ChannelPlay(bChan, False);
  end;
end;

procedure TfrmMain.btnDeletePlayListClick(Sender: TObject);
var
  Inindex: Integer;
begin
  Inindex:= sPlayList1.ItemIndex;
  sPlayList1.Items.Delete(Inindex);
  sPlayList1.Items.Delete(Inindex);

  if Inindex > sPlayList1.Items.Count -1 then
    Inindex := sPlayList1.Items.Count -1;
    sPlayList1.ItemIndex := Inindex;
end;

procedure TfrmMain.sPlayList1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_DELETE then
    btnDeletePlayList.Click;
end;

procedure TfrmMain.sPlayList1DblClick(Sender: TObject);
begin
  PlayItem(sPlayList1.ItemIndex);
end;

procedure TfrmMain.sVolumeBarScroll(Sender: TObject; ScrollCode: TScrollCode;
  var ScrollPos: Integer);
begin
  BASS_ChannelSetAttribute(bchan, BASS_ATTRIB_VOL, sVolumeBar.Position / 100);
end;

procedure TfrmMain.btnSavePlayListClick(Sender: TObject);
begin
  if sSavePlayList.Execute then
    sPlayList2.Items.SaveToFile(sSavePlayList.FileName);
end;

procedure TfrmMain.btnOpenPlayListClick(Sender: TObject);
var i: Integer;
begin
  if sOpenPlayList.Execute = False then Exit;
    sPlayList2.Items.LoadFromFile(sOpenPlayList.FileName);
    sPlayList1.Items.LoadFromFile(sOpenPlayList.FileName);
  for i := 0 to sPlayList1.Items.Count -1 do
    sPlayList1.Items.Strings[i] := ExtractFileName(sPlayList1.Items.Strings[i]);
end;

Procedure TfrmMain.DropFiles(var Msg: TWMDropFiles);
var
  CFileName: array[0.. MAX_PATH] of Char;
begin
try
  if DragQueryFile(Msg.Drop, 0, CFileName, MAX_PATH) > 0 then
  begin
    AddFiles(CFileName);
    Msg.Result := 0;
    end;
  finally
    DragFinish(Msg.Drop);
  end;
end;

procedure TfrmMain.tmrPlayTimer(Sender: TObject);
var
  L, R, L1, R1: Integer;
  Level: DWORD;
begin
  if BASS_ChannelIsActive(bChan) <> BASS_ACTIVE_PLAYING then Exit;
    Level:= BASS_ChannelGetLevel(bChan);
    L:= HiWORD(Level);
    R:= LOWORD(Level);
    PaintBox1.Canvas.Brush.Color := clWhite;
    PaintBox1.Canvas.FillRect(PaintBox1.Canvas.Cliprect);
    PaintBox2.Canvas.Brush.Color := clWhite;
    PaintBox2.Canvas.FillRect(PaintBox1.Canvas.Cliprect);

    L1:=Round(L / (32768 / PaintBox1.Height));
    R1:=Round(R / (32768 / PaintBox2.Height));
    PaintBox1.Canvas.Brush.Color := clBlue;
    PaintBox2.Canvas.Brush.Color := clBlue;
    PaintBox1.Canvas.Rectangle (0, PaintBox1.Height-L1, PaintBox1.Width, PaintBox1.Height);
    PaintBox2.Canvas.Rectangle (0, PaintBox2.Height-R1, PaintBox2.Width, PaintBox2.Height);
end;

end.
