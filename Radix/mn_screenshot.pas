//
//  RAD: Recreation of the game "Radix - beyond the void"
//       powered by the DelphiDoom engine
//
//  Copyright (C) 1995 by Epic MegaGames, Inc.
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//   Save/Load screen preview
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit mn_screenshot;

interface

const
  MN_SCREENSHOTWIDTH = 94;
  MN_SCREENSHOTHEIGHT = 72;
  MN_SCREENSHOTSIZE = MN_SCREENSHOTWIDTH * MN_SCREENSHOTHEIGHT;

type
  menuscreenbuffer_t = packed array[0..MN_SCREENSHOTSIZE - 1] of byte;
  Pmenuscreenbuffer_t = ^menuscreenbuffer_t;

var
  mn_screenshotbuffer: menuscreenbuffer_t;
  mn_makescreenshot: boolean = false;

//==============================================================================
//
// MN_ScreenShotFromBlitBuffer
//
//==============================================================================
procedure MN_ScreenShotFromBlitBuffer;

//==============================================================================
//
// MN_ScreenShotFromSaveGame
//
//==============================================================================
procedure MN_ScreenShotFromSaveGame(const path: string; const outbuff: Pmenuscreenbuffer_t);

implementation

uses
  d_delphi,
  doomdef,
  {$IFDEF OPENGL}
  gl_main,
  {$ELSE}
  i_video,
  {$ENDIF}
  r_draw,
  v_video;

//==============================================================================
//
// MN_ScreenShotFromBlitBuffer
//
//==============================================================================
procedure MN_ScreenShotFromBlitBuffer;
var
  x, y: integer;
  bufsize: integer;
  buf: PByteArray;
  xlinesource: PByteArray;
  c: LongWord;
  xpos, ypos: integer;
begin
  {$IFNDEF OPENGL}
  I_BlitBuffer;
  {$ENDIF}
  bufsize := SCREENWIDTH * SCREENHEIGHT * 4;
  buf := malloc(bufsize);
  I_ReadScreen32(buf);

  for y := 0 to MN_SCREENSHOTHEIGHT - 1 do
  begin
    ypos := viewwindowy + ((y * viewheight) div MN_SCREENSHOTHEIGHT);
    {$IFDEF OPENGL}
    ypos := SCREENHEIGHT - ypos - 1;
    {$ENDIF}
    ypos := GetIntegerInRange(ypos, 0, SCREENHEIGHT - 1);
    xlinesource := @buf[ypos * SCREENWIDTH * 4];
    for x := 0 to MN_SCREENSHOTWIDTH - 1 do
    begin
      xpos := viewwindowx + ((x * viewwidth) div MN_SCREENSHOTWIDTH);
      xpos := GetIntegerInRange(xpos, 0, SCREENWIDTH - 1);
      c := xlinesource[xpos * 4 + 2] shl 16 + xlinesource[xpos * 4 + 1] shl 8 + xlinesource[xpos * 4];
      mn_screenshotbuffer[y * MN_SCREENSHOTWIDTH + x] := V_FindAproxColorIndex(@videopal, c, 1, 255);
    end;
  end;
  memfree(pointer(buf), bufsize);
  mn_makescreenshot := false;
end;

//==============================================================================
//
// MN_ScreenShotFromSaveGame
//
//==============================================================================
procedure MN_ScreenShotFromSaveGame(const path: string; const outbuff: Pmenuscreenbuffer_t);
var
  f: TFile;
begin
  if not fexists(path) then
  begin
    ZeroMemory(outbuff, SizeOf(menuscreenbuffer_t));
    exit;
  end;

  f := TFile.Create(path, fOpenReadOnly);
  if f.Size < SizeOf(menuscreenbuffer_t) then
  begin
    ZeroMemory(outbuff, SizeOf(menuscreenbuffer_t));
    f.Free;
    exit;
  end;

  f.Read(outbuff^, SizeOf(menuscreenbuffer_t));
  f.Free;
end;

end.
