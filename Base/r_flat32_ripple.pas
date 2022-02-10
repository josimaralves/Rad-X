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
//  Multithreading flat rendering - 32 bit color (ripple)
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_flat32_ripple;

interface

//==============================================================================
//
// R_DrawSpanNormal_RippleMT
//
//==============================================================================
procedure R_DrawSpanNormal_RippleMT(const fi: pointer);

implementation

uses
  d_delphi,
  m_fixed,
  r_draw,
  r_precalc,
  r_span,
  r_flat32,
  r_zbuffer;

//==============================================================================
//
// R_DrawSpanNormal_RippleMT
//
//==============================================================================
procedure R_DrawSpanNormal_RippleMT(const fi: pointer);
var
  ds_source32: PLongWordArray;
  ds_y, ds_x1, ds_x2: integer;
  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;
  ds_scale: dsscale_t;
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  destl: PLongWord;
  count: integer;
  i: integer;
  spot: integer;

  r1, g1, b1: byte;
  c: LongWord;
  lfactor: integer;
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
  rpl: PIntegerArray;
  docheckzbuffer3dfloors: boolean;
  db_distance: LongWord;
  x: integer;
begin
  ds_source32 := Pflatrenderinfo32_t(fi).ds_source32;
  ds_y := Pflatrenderinfo32_t(fi).ds_y;
  ds_x1 := Pflatrenderinfo32_t(fi).ds_x1;
  ds_x2 := Pflatrenderinfo32_t(fi).ds_x2;
  ds_xfrac := Pflatrenderinfo32_t(fi).ds_xfrac;
  ds_yfrac := Pflatrenderinfo32_t(fi).ds_yfrac;
  ds_xstep := Pflatrenderinfo32_t(fi).ds_xstep;
  ds_ystep := Pflatrenderinfo32_t(fi).ds_ystep;
  ds_scale := Pflatrenderinfo32_t(fi).ds_scale;
  docheckzbuffer3dfloors := Pflatrenderinfo32_t(fi).ds_checkzbuffer3dfloors;

  destl := @((ylookupl[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  x := ds_x1;
  count := ds_x2 - x;

  rpl := Pflatrenderinfo32_t(fi).ds_ripple;
  lfactor := Pflatrenderinfo32_t(fi).ds_lightlevel;

  if docheckzbuffer3dfloors then
  begin
    db_distance := Pflatrenderinfo32_t(fi).db_distance;
    if lfactor >= 0 then // Use hi detail lightlevel
    begin
      R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
      {$DEFINE RIPPLE}
      {$UNDEF INVERSECOLORMAPS}
      {$UNDEF TRANSPARENTFLAT}
      {$DEFINE CHECK3DFLOORSZ}
      {$I R_DrawSpanNormal.inc}
    end
    else // Use inversecolormap
    begin
      {$DEFINE RIPPLE}
      {$DEFINE INVERSECOLORMAPS}
      {$UNDEF TRANSPARENTFLAT}
      {$DEFINE CHECK3DFLOORSZ}
      {$I R_DrawSpanNormal.inc}
    end;
  end
  else
  begin
    if lfactor >= 0 then // Use hi detail lightlevel
    begin
      R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
      {$DEFINE RIPPLE}
      {$UNDEF INVERSECOLORMAPS}
      {$UNDEF TRANSPARENTFLAT}
      {$UNDEF CHECK3DFLOORSZ}
      {$I R_DrawSpanNormal.inc}
    end
    else // Use inversecolormap
    begin
      {$DEFINE RIPPLE}
      {$DEFINE INVERSECOLORMAPS}
      {$UNDEF TRANSPARENTFLAT}
      {$UNDEF CHECK3DFLOORSZ}
      {$I R_DrawSpanNormal.inc}
    end;
  end;
end;

end.

