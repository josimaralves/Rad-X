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
//  HUD drawing
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_hud;

interface

//==============================================================================
//
// RX_InitRadixHud
//
//==============================================================================
procedure RX_InitRadixHud;

//==============================================================================
//
// RX_ShutDownRadixHud
//
//==============================================================================
procedure RX_ShutDownRadixHud;

//==============================================================================
//
// RX_HudDrawer
//
//==============================================================================
procedure RX_HudDrawer;

var
  drawcrosshair: boolean = true;
  drawkeybar: boolean = true;

implementation

uses
  d_delphi,
  d_englsh,
  doomdef,
  am_map,
  d_net,
  d_player,
  d_items,
  g_game,
  mt_utils,
  mn_font,
  m_fixed,
  tables,
  p_local,
  p_maputl,
  p_mobj_h,
  p_setup,
  p_tick,
  p_user,
  r_defs,
  r_main,
  r_data,
  v_data,
  v_video,
  w_wad,
  z_zone;

const
  STATUSBAR_HEIGHT = 41;

type
  speedindicatorcolumn_t = packed array[0..6] of byte;
  Pspeedindicatorcolumn_t = ^speedindicatorcolumn_t;

var
  hud_speed_factor: float;
  radar_list: TDNumberList;
  radar_friendlist: TDNumberList;
  cockpitspeed: speedindicatorcolumn_t;
  statusbarspeed: speedindicatorcolumn_t;
  cockpit: Ppatch_t;
  statusbarimage: Ppatch_t;
  weaponimages: array[0..8] of Ppatch_t;
  WeaponNumOn: array[0..8] of Ppatch_t;
  WeaponNumOff: array[0..8] of Ppatch_t;
  WeaponNumUse: array[0..8] of Ppatch_t;
  treatimages: array[boolean] of Ppatch_t;
  ArmourBar: Ppatch_t;
  ShieldBar: Ppatch_t;
  EnergyBar: Ppatch_t;
  hud_player: Pplayer_t;
  statammo: array[0..3] of Ppatch_t;
  PowerUpIcons: array[0..4] of Ppatch_t;
  PlasmaIcon: Ppatch_t;
  crosshairs: array[0..6] of Ppatch_t;
  ckeybar: Ppatch_t;
  skeybar: Ppatch_t;
  stkeys: array[0..Ord(NUMCARDS) - 1] of Ppatch_t;

//==============================================================================
//
// RX_InitRadixHud
//
//==============================================================================
procedure RX_InitRadixHud;
var
  i: integer;
  stmp: string;
begin
  hud_speed_factor := 15 / sqrt(2 * sqr(MAXMOVETHRESHOLD / FRACUNIT));
  radar_list := TDNumberList.Create;
  radar_friendlist := TDNumberList.Create;
  cockpitspeed[0] := aprox_black;
  cockpitspeed[1] := aprox_black;
  cockpitspeed[2] := aprox_black;
  cockpitspeed[3] := aprox_black;
  cockpitspeed[4] := aprox_black;
  cockpitspeed[5] := aprox_black;
  cockpitspeed[6] := aprox_black;
  statusbarspeed[0] := 244;
  statusbarspeed[1] := 241;
  statusbarspeed[2] := 236;
  statusbarspeed[3] := 239;
  statusbarspeed[4] := 242;
  statusbarspeed[5] := 244;
  statusbarspeed[6] := 247;
  cockpit := W_CacheLumpName('COCKPIT', PU_STATIC);
  statusbarimage := W_CacheLumpName('StatusBarImage', PU_STATIC);
  for i := 0 to 6 do
  begin
    sprintf(stmp, 'Weapon%dImage', [i + 1]);
    weaponimages[i] := W_CacheLumpName(stmp, PU_STATIC);
    sprintf(stmp, 'WeaponNumOn%d', [i + 1]);
    WeaponNumOn[i] := W_CacheLumpName(stmp, PU_STATIC);
    sprintf(stmp, 'WeaponNumOff%d', [i + 1]);
    WeaponNumOff[i] := W_CacheLumpName(stmp, PU_STATIC);
    sprintf(stmp, 'WeaponNumUse%d', [i + 1]);
    WeaponNumUse[i] := W_CacheLumpName(stmp, PU_STATIC);
  end;
  weaponimages[7] := W_CacheLumpName('EnhancedEPCWeaponPicture', PU_STATIC);
  WeaponNumOn[7] := WeaponNumOn[1];
  WeaponNumOff[7] := WeaponNumOff[1];
  WeaponNumUse[7] := WeaponNumUse[1];

  weaponimages[8] := W_CacheLumpName('SuperEPCWeaponPicture', PU_STATIC);
  WeaponNumOn[8] := WeaponNumOn[1];
  WeaponNumOff[8] := WeaponNumOff[1];
  WeaponNumUse[8] := WeaponNumUse[1];

  treatimages[true] := W_CacheLumpName('ThreatOnMap', PU_STATIC);
  treatimages[false] := W_CacheLumpName('ThreatOffMap', PU_STATIC);
  ArmourBar := W_CacheLumpName('ArmourBar', PU_STATIC);
  ShieldBar := W_CacheLumpName('ShieldBar', PU_STATIC);
  EnergyBar := W_CacheLumpName('EnergyBar', PU_STATIC);

  statammo[0] := W_CacheLumpName('StatAmmo1', PU_STATIC);
  statammo[1] := W_CacheLumpName('StatAmmo4', PU_STATIC);
  statammo[2] := W_CacheLumpName('StatAmmo2', PU_STATIC);
  statammo[3] := W_CacheLumpName('StatAmmo3', PU_STATIC);

  for i := 0 to 4 do
  begin
    sprintf(stmp, 'PowerUpIcon[%d]', [i + 1]);
    PowerUpIcons[i] := W_CacheLumpName(stmp, PU_STATIC);
  end;

  PlasmaIcon := W_CacheLumpName('PlasmaIcon', PU_STATIC);

  crosshairs[0] := W_CacheLumpName('CrossHair', PU_STATIC);
  for i := 1 to 6 do
  begin
    sprintf(stmp, 'CrossLock%d', [i]);
    crosshairs[i] := W_CacheLumpName(stmp, PU_STATIC);
  end;

  ckeybar := W_CacheLumpName('CKEYBAR', PU_STATIC);
  skeybar := W_CacheLumpName('SKEYBAR', PU_STATIC);
  for i := 0 to Ord(NUMCARDS) - 1 do
  begin
    sprintf(stmp, 'STKEYS%d', [i]);
    stkeys[i] := W_CacheLumpName(stmp, PU_STATIC);
  end;
end;

//==============================================================================
//
// RX_ShutDownRadixHud
//
//==============================================================================
procedure RX_ShutDownRadixHud;
begin
  radar_list.Free;
  radar_friendlist.Free;
end;

//==============================================================================
//
// RX_HudDrawTime
//
//==============================================================================
procedure RX_HudDrawTime(const x, y: integer);
var
  secs: integer;
begin
  if leveltime <= (99 * 60 + 59) * TICRATE then
  begin
    secs := leveltime div TICRATE;
    M_WriteSmallText(x, y, IntToStrzFill(2, secs div 60) + ':', SCN_HUD);
    M_WriteSmallText(x + 14, y, IntToStrzFill(2, secs mod 60), SCN_HUD);
  end
  else
    M_WriteSmallText(x, y, 'SUCKS', SCN_HUD); // JVAL 20200316 - SUCKS easter egg
end;

//==============================================================================
//
// RX_HudDrawSpeedIndicator
//
//==============================================================================
procedure RX_HudDrawSpeedIndicator(const x, y: integer; const column: Pspeedindicatorcolumn_t; const up: boolean);
var
  speed: float;
  cnt: integer;
  dest: PByte;
  pitch: integer;
  xpos: integer;
  xadd: integer;
begin
  speed := sqrt(sqr(hud_player.mo.momx / FRACUNIT) + sqr(hud_player.mo.momy / FRACUNIT) + sqr(hud_player.mo.momz / FRACUNIT));

  cnt := GetIntegerInRange(15 - round(speed * hud_speed_factor), 0, 15);
  if not up and (cnt = 0) then
    exit;
  if up and (cnt = 15) then
    exit;

  xpos := x;
  if up then
  begin
    xadd := 2;
    cnt := 15 - cnt;
  end
  else
    xadd := -2;
  while cnt > 0 do
  begin
    pitch := V_GetScreenWidth(SCN_HUD);
    dest := @screens[SCN_HUD][pitch * y + xpos];
    dest^ := column[0];
    inc(dest, pitch);
    dest^ := column[1];
    inc(dest, pitch);
    dest^ := column[2];
    inc(dest, pitch);
    dest^ := column[3];
    inc(dest, pitch);
    dest^ := column[4];
    inc(dest, pitch);
    dest^ := column[5];
    inc(dest, pitch);
    dest^ := column[6];
    xpos := xpos + xadd;
    dec(cnt);
  end;
end;

//==============================================================================
//
// PIT_AddRadarThing
//
//==============================================================================
function PIT_AddRadarThing(thing: Pmobj_t): boolean;
begin
  if thing.health > 0 then
  begin
    if thing.flags2_ex and MF2_EX_FRIEND <> 0 then
      radar_friendlist.Add(integer(thing))
    else if thing.flags and MF_COUNTKILL <> 0 then
      radar_list.Add(integer(thing));
  end;
  result := true;
end;

//==============================================================================
//
// RX_DrawRadar
//
//==============================================================================
procedure RX_DrawRadar(const x, y: integer; const range: integer);
const
  RADAR_SHIFT_BITS = 8;
  RADAR_SHIFT_UNIT = 1 shl RADAR_SHIFT_BITS;
  RADAR_RANGE_FACTOR = 128 * (1 shl (FRACBITS - RADAR_SHIFT_BITS));
var
  r: int64;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  i, j: integer;
  mo: Pmobj_t;
  px, py: integer;
  pb: PByte;
  newcolor: byte;
  xpos, ypos: integer;
  pitch: integer;
  sqdist: integer;
  maxsqdist: integer;
  tmp: fixed_t;
  an: angle_t;
  asin, acos: fixed_t;

  procedure _draw_list(const lst: TDNumberList; const color: byte);
  var
    i: integer;
  begin
    for i := 0 to lst.Count - 1 do
    begin
      mo := Pmobj_t(lst.Numbers[i]);
      xpos := (px - mo.x div RADAR_SHIFT_UNIT);
      if xpos < 0 then
        xpos := xpos - RADAR_RANGE_FACTOR div 2
      else
        xpos := xpos + RADAR_RANGE_FACTOR div 2;
      xpos := xpos div RADAR_RANGE_FACTOR;
      ypos := (py - mo.y div RADAR_SHIFT_UNIT);
      if ypos < 0 then
        ypos := ypos - RADAR_RANGE_FACTOR div 2
      else
        ypos := ypos + RADAR_RANGE_FACTOR div 2;
      ypos := ypos div RADAR_RANGE_FACTOR;
      sqdist := xpos * xpos + ypos * ypos;
      if sqdist <= maxsqdist then
      begin
        tmp := FixedMul(ypos, asin) - FixedMul(xpos, acos);
        ypos := FixedMul(xpos, asin) + FixedMul(ypos, acos);
        xpos := x + tmp;
        ypos := y + ypos;
        screens[SCN_HUD][pitch * ypos + xpos] := color;
      end;
    end;
  end;

begin
  pitch := V_GetScreenWidth(SCN_HUD);
  if (hud_player.playerstate = PST_DEAD) or (hud_player.scannerjam and (leveltime and 16 <> 0)) then
  begin
    for i := x - range - 1 to x + range + 1 do
      for j := y - range to y + range do
      begin
        pb := @screens[SCN_HUD][pitch * j + i];
        if pb^ = 124 then
          pb^ := 63;
      end;
    exit; // JVAL: 20200324 - When true can not see the radar in hud
  end;

  // JVAL: 20200424 - Radar glow effect
  case (leveltime div 8) and 3 of
    0: newcolor := 123;
    2: newcolor := 125;
  else
    newcolor := 124;
  end;
  if newcolor <> 124 then
    for i := x - range - 1 to x + range + 1 do
      for j := y - range to y + range do
      begin
        pb := @screens[SCN_HUD][pitch * j + i];
        if pb^ = 124 then
          pb^ := newcolor;
      end;

  r := range * 128 * FRACUNIT;
  xl := MapBlockIntX(int64(hud_player.mo.x) - r - int64(bmaporgx));
  xh := MapBlockIntX(int64(hud_player.mo.x) + r - int64(bmaporgx));
  yl := MapBlockIntY(int64(hud_player.mo.y) - r - int64(bmaporgy));
  yh := MapBlockIntY(int64(hud_player.mo.y) + r - int64(bmaporgy));

  radar_list.FastClear;
  radar_friendlist.FastClear;
  for bx := xl to xh do
    for by := yl to yh do
      P_BlockThingsIterator(bx, by, PIT_AddRadarThing);

  pitch := V_GetScreenWidth(SCN_HUD);
  screens[SCN_HUD][pitch * y + x] := aprox_blue;

  an := (ANG90 - hud_player.mo.angle) div FRACUNIT;
  asin := fixedsine[an];
  acos := fixedcosine[an];

  px := hud_player.mo.x div RADAR_SHIFT_UNIT;
  py := hud_player.mo.y div RADAR_SHIFT_UNIT;
  maxsqdist := range * range;
  _draw_list(radar_friendlist, aprox_lightblue);
  _draw_list(radar_list, aprox_yellow);
end;

//==============================================================================
//
// RX_HudDrawBar
//
//==============================================================================
procedure RX_HudDrawBar(const x, y: integer; const bar: Ppatch_t; const pct: integer);
var
  i, j: integer;
  xx: integer;
  dest: PByte;
  b: byte;
  pitch: integer;
begin
  if pct <= 0 then
    exit;

  pitch := V_GetScreenWidth(SCN_HUD);
  b := screens[SCN_HUD][pitch * y + x]; // JVAL: 20200316 - Keep background color
  V_DrawPatch(x, y, SCN_HUD, bar, false);

  if pct >= 100 then
    exit;

  // Fill with background color:
  xx := bar.width * pct div 100;

  for j := y to y + bar.height - 1 do
  begin
    dest := @screens[SCN_HUD][j * pitch + x + xx];
    for i := xx to bar.width - 1 do
    begin
      dest^ := b;
      inc(dest);
    end;
  end;
end;

//==============================================================================
//
// RX_HudDrawPowerUpIcons
//
//==============================================================================
procedure RX_HudDrawPowerUpIcons;

  // JVAL: 20200322 - Flash icons at the end
  function DoDrawQuery(const x: integer): boolean;
  begin
    result := (x > 4 * 32) or (x and 8 <> 0);
  end;

begin
  // Rapid shield icon
  if DoDrawQuery(hud_player.radixpowers[Ord(rpu_rapidshield)]) then
    V_DrawPatch(300, 22, SCN_HUD, PowerUpIcons[0], false);

  // Rapid energy icon
  if DoDrawQuery(hud_player.radixpowers[Ord(rpu_rapidenergy)]) then
    V_DrawPatch(300, 42, SCN_HUD, PowerUpIcons[1], false);

  // Maneuver jets icon
  if DoDrawQuery(hud_player.radixpowers[Ord(rpu_maneuverjets)]) then
    V_DrawPatch(300, 62, SCN_HUD, PowerUpIcons[2], false);

  // Ultra shields icon
  if hud_player.health > PLAYERSPAWNSHIELD then
    V_DrawPatch(300, 82, SCN_HUD, PowerUpIcons[3], false);

  // ALDS icon
  if DoDrawQuery(hud_player.radixpowers[Ord(rpu_alds)]) then
    V_DrawPatch(300, 102, SCN_HUD, PowerUpIcons[4], false);
end;

//==============================================================================
//
// RX_HudDrawPlasmaBall
//
//==============================================================================
procedure RX_HudDrawPlasmaBall;
begin
  V_DrawPatch(282, 0, SCN_HUD, PlasmaIcon, false);
  M_WriteSmallText(305, 4, IntToStrzFill(2, hud_player.plasmabombs), SCN_HUD);
end;

//==============================================================================
//
// RX_HudDrawRestartMessage
//
//==============================================================================
procedure RX_HudDrawRestartMessage;
begin
  if hud_player.playerstate = PST_DEAD then
    M_WriteSmallTextCenter(76, S_PRESS_SPACE_RESTART, SCN_HUD);
end;

//==============================================================================
// RX_HudDrawCrossHair
//
// JVAL: 20200501 - Draw crosshair
//
//==============================================================================
procedure RX_HudDrawCrossHair;
var
  cidx: integer;
  p: Ppatch_t;
begin
  if not drawcrosshair then
    exit;

  if amstate = am_only then
    exit;

  if hud_player.playerstate = PST_DEAD then
    exit;

  if hud_player.plinetarget = nil then
    cidx := 0
  else
  begin
    cidx := leveltime - hud_player.pcrosstic + 1;
    if cidx > 6 then
      cidx := 6;
  end;

  p := crosshairs[cidx];
  if screenblocks > 10 then
    V_DrawPatch(160 - p.width div 2, 100 - p.height div 2, SCN_HUD, p, false)
  else
    V_DrawPatch(160 - p.width div 2, 100 - (STATUSBAR_HEIGHT + p.height) div 2, SCN_HUD, p, false);
end;

//==============================================================================
// RX_HudDrawKeys
//
// JVAL: 20200523 - Draw keys
//
//==============================================================================
procedure RX_HudDrawKeys(const x, y: integer; const kbar: Ppatch_t);
var
  i: integer;
begin
  if not drawkeybar then
    exit;

  V_DrawPatch(x, y, SCN_HUD, kbar, false);
  for i := 0 to Ord(NUMCARDS) - 1 do
    if hud_player.cards[i] then
      V_DrawPatch(x + i * 8 + 2, y + 2, SCN_HUD, stkeys[i], false);
end;
////////////////////////////////////////////////////////////////////////////////
// Draw Status Bar
////////////////////////////////////////////////////////////////////////////////
const
  weaponxlatpos: array[0..8] of integer =
    (0, 1, 2, 3, 4, 5, 6, 1, 1);

//==============================================================================
//
// RX_HudDrawerStatusbar
//
//==============================================================================
procedure RX_HudDrawerStatusbar;
var
  p: Ppatch_t;
  i: integer;
  stmp: string;
begin
  // Draw statusbar
  V_DrawPatch(0, 200 - STATUSBAR_HEIGHT, SCN_HUD, statusbarimage, false);

  // Draw ready weapon
  case Ord(hud_player.readyweapon) of
    0: p := weaponimages[0];
    1: p := weaponimages[1];
    2: p := weaponimages[2];
    3: p := weaponimages[3];
    4: p := weaponimages[4];
    5: p := weaponimages[5];
    6: p := weaponimages[6];
    7: p := weaponimages[7];
    8: p := weaponimages[8];
  else
    p := weaponimages[0];
  end;
  V_DrawPatch(5, 200 - STATUSBAR_HEIGHT + 4, SCN_HUD, p, false);

  // Draw Neutron Cannons Level
  if hud_player.readyweapon = wp_neutroncannons then
    V_DrawPatch(60, 200 - STATUSBAR_HEIGHT + 4, SCN_HUD, WeaponNumUse[neutroncannoninfo[hud_player.neutroncannonlevel].firelevel], false)
  // Draw Neutron Spreader Level
  else if hud_player.readyweapon = wp_plasmaspreader then
    V_DrawPatch(60, 200 - STATUSBAR_HEIGHT + 4, SCN_HUD, WeaponNumUse[neutronspreaderinfo[hud_player.neutronspreaderlevel].firelevel], false);

  // Draw weapon indicators
  for i := 0 to 8 do
  begin
    if Ord(hud_player.readyweapon) = i then
      p := WeaponNumUse[i]
    else if hud_player.weaponowned[i] <> 0 then
    begin
      if i > 6 then
        continue;
      p := WeaponNumOn[i]
    end
    else
    begin
      if i > 6 then
        continue;
      p := WeaponNumOff[i];
    end;
    V_DrawPatch(6 + weaponxlatpos[i] * 8, 200 - STATUSBAR_HEIGHT + 31, SCN_HUD, p, false);
  end;

  // Draw kills
  if hud_player.killcount > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, hud_player.killcount);
  M_WriteSmallText(204, 200 - STATUSBAR_HEIGHT + 30, stmp, SCN_HUD);

  if totalkills > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, totalkills);
  M_WriteSmallText(227, 200 - STATUSBAR_HEIGHT + 30, stmp, SCN_HUD);

  // Draw threat indicator
  V_DrawPatch(290, 200 - STATUSBAR_HEIGHT + 16, SCN_HUD, treatimages[hud_player.threat and ((leveltime shr 4) and 1 <> 0)], false);

  // Draw armor, shield and energy bars
  RX_HudDrawBar(189, 200 - STATUSBAR_HEIGHT + 7, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(189, 200 - STATUSBAR_HEIGHT + 14, ShieldBar, hud_player.health);
  RX_HudDrawBar(189, 200 - STATUSBAR_HEIGHT + 21, EnergyBar, hud_player.energy);

  // Draw time
  RX_HudDrawTime(93, 200 - STATUSBAR_HEIGHT + 30);

  // Draw speed indicator
  RX_HudDrawSpeedIndicator(128, 200 - STATUSBAR_HEIGHT + 30, @statusbarspeed, true);

  // Draw radar
  RX_DrawRadar(269, 200 - STATUSBAR_HEIGHT + 19, 12);

  // Draw ammo
  M_WriteSmallText(96, 200 - STATUSBAR_HEIGHT + 8, itoa(hud_player.ammo[0]), SCN_HUD);
  M_WriteSmallText(145, 200 - STATUSBAR_HEIGHT + 8, itoa(hud_player.ammo[1]), SCN_HUD);
  M_WriteSmallText(96, 200 - STATUSBAR_HEIGHT + 19, itoa(hud_player.ammo[2]), SCN_HUD);
  M_WriteSmallText(145, 200 - STATUSBAR_HEIGHT + 19, itoa(hud_player.ammo[3]), SCN_HUD);

  case Ord(weaponinfo[Ord(hud_player.readyweapon)].ammo) of
    0: V_DrawPatch(75, 200 - STATUSBAR_HEIGHT + 8, SCN_HUD, statammo[0], false);
    1: V_DrawPatch(124, 200 - STATUSBAR_HEIGHT + 8, SCN_HUD, statammo[1], false);
    2: V_DrawPatch(75, 200 - STATUSBAR_HEIGHT + 19, SCN_HUD, statammo[2], false);
    3: V_DrawPatch(124, 200 - STATUSBAR_HEIGHT + 19, SCN_HUD, statammo[3], false);
  end;

  // Draw power up icons
  RX_HudDrawPowerUpIcons;

  // Draw plasma balls
  RX_HudDrawPlasmaBall;

  // Gravity wave shots left
  if hud_player.readyweapon = wp_gravitywave then
    M_WriteSmallText(55, 200 - STATUSBAR_HEIGHT + 16, IntToStrzFill(2, hud_player.gravitywave), SCN_HUD);

  // Draw restart message if the player is dead
  RX_HudDrawRestartMessage;

  // Draw crosshair
  RX_HudDrawCrossHair;

  // Draw keycards
  RX_HudDrawKeys(11, 151, skeybar);
end;

type
  cockpitmode_t = (cm_fulldisplay, cm_halfdisplay);

const
  COCKPIT_UP_PART = 120;

//==============================================================================
// RX_HudDrawerCockpit
//
////////////////////////////////////////////////////////////////////////////////
// Draw Cockpit
////////////////////////////////////////////////////////////////////////////////
//
//==============================================================================
procedure RX_HudDrawerCockpit(const mode: cockpitmode_t);
var
  p: Ppatch_t;
  i: integer;
  stmp: string;
begin
  // Draw cockpit
  V_DrawPatch(0, 0, SCN_HUD, cockpit, false);

  if mode = cm_halfdisplay then
    MT_ZeroMemory(screens[SCN_HUD], 320 * COCKPIT_UP_PART);

  // Draw ready weapon
  case Ord(hud_player.readyweapon) of
    0: p := weaponimages[0];
    1: p := weaponimages[1];
    2: p := weaponimages[2];
    3: p := weaponimages[3];
    4: p := weaponimages[4];
    5: p := weaponimages[5];
    6: p := weaponimages[6];
    7: p := weaponimages[7];
    8: p := weaponimages[8];
  else
    p := weaponimages[0];
  end;
  V_DrawPatch(23, 142, SCN_HUD, p, false);

  // Draw Neutron Cannons Level
  if hud_player.readyweapon = wp_neutroncannons then
    V_DrawPatch(78, 142, SCN_HUD, WeaponNumUse[neutroncannoninfo[hud_player.neutroncannonlevel].firelevel], false)
  // Draw Neutron Spreader Level
  else if hud_player.readyweapon = wp_plasmaspreader then
    V_DrawPatch(78, 142, SCN_HUD, WeaponNumUse[neutronspreaderinfo[hud_player.neutronspreaderlevel].firelevel], false);

  // Draw weapon indicators
  for i := 0 to 8 do
  begin
    if Ord(hud_player.readyweapon) = i then
      p := WeaponNumUse[i]
    else if hud_player.weaponowned[i] <> 0 then
    begin
      if i > 6 then
        continue;
      p := WeaponNumOn[i];
    end
    else
      continue; // Already in cockpit patch
    V_DrawPatchStencil(26 + weaponxlatpos[i] * 8, 162, SCN_HUD, p, false, 0);
  end;

  // Draw kills
  if hud_player.killcount > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, hud_player.killcount);
  M_WriteSmallText(145, 141, stmp, SCN_HUD);

  if totalkills > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, totalkills);
  M_WriteSmallText(168, 141, stmp, SCN_HUD);

  // Draw threat indicator
  if mode = cm_fulldisplay then
    V_DrawPatch(147, 23, SCN_HUD, treatimages[hud_player.threat and ((leveltime shr 4) and 1 <> 0)], false);

  // Draw armor, shield and energy bars
  RX_HudDrawBar(202, 156, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(202, 171, ShieldBar, hud_player.health);
  RX_HudDrawBar(233, 186, EnergyBar, hud_player.energy);

  // Draw time
  RX_HudDrawTime(107, 183);

  // Draw speed indicator
  RX_HudDrawSpeedIndicator(136, 148, @cockpitspeed, false);

  // Draw radar
  RX_DrawRadar(163, 171, 15);

  // Draw ammo
  M_WriteSmallText(31, 174, itoa(hud_player.ammo[0]), SCN_HUD);
  M_WriteSmallText(74, 174, itoa(hud_player.ammo[1]), SCN_HUD);
  M_WriteSmallText(31, 185, itoa(hud_player.ammo[2]), SCN_HUD);
  M_WriteSmallText(74, 185, itoa(hud_player.ammo[3]), SCN_HUD);

  case Ord(weaponinfo[Ord(hud_player.readyweapon)].ammo) of
    0: V_DrawPatchStencil(10, 174, SCN_HUD, statammo[0], false, 0);
    1: V_DrawPatchStencil(53, 174, SCN_HUD, statammo[1], false, 0);
    2: V_DrawPatchStencil(10, 185, SCN_HUD, statammo[2], false, 0);
    3: V_DrawPatchStencil(54, 185, SCN_HUD, statammo[3], false, 0);
  end;

  // Draw power up icons
  RX_HudDrawPowerUpIcons;

  // Draw plasma balls
  RX_HudDrawPlasmaBall;

  // Gravity wave shots left
  if hud_player.readyweapon = wp_gravitywave then
    M_WriteSmallText(73, 154, IntToStrzFill(2, hud_player.gravitywave), SCN_HUD);

  // Draw restart message if the player is dead
  RX_HudDrawRestartMessage;

  // Draw crosshair
  RX_HudDrawCrossHair;

  // Draw keycards
  RX_HudDrawKeys(204, 134, ckeybar);
end;

//==============================================================================
// RX_HudDrawerSmall
//
////////////////////////////////////////////////////////////////////////////////
// Mini hud
////////////////////////////////////////////////////////////////////////////////
//
//==============================================================================
procedure RX_HudDrawerSmall;
begin
  // Draw armor, shield and energy bars
  RX_HudDrawBar(2, 200 - 21, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(2, 200 - 14, ShieldBar, hud_player.health);
  RX_HudDrawBar(2, 200 - 7, EnergyBar, hud_player.energy);

  // Draw power up icons
  RX_HudDrawPowerUpIcons;

  // Draw plasma balls
  RX_HudDrawPlasmaBall;

  // Draw restart message if the player is dead
  RX_HudDrawRestartMessage;

  // Draw crosshair
  RX_HudDrawCrossHair;
end;

//==============================================================================
//
// RX_HudDrawer
//
//==============================================================================
procedure RX_HudDrawer;
begin
  hud_player := @players[consoleplayer];

  if (screenblocks > 13) and (amstate <> am_only) and (hud_player.playerstate <> PST_DEAD) then
    exit;

  if firstinterpolation then
  begin

    MT_ZeroMemory(screens[SCN_HUD], 320 * 200);

    if (screenblocks > 13) and (amstate <> am_only) then
    begin
      if hud_player.playerstate = PST_DEAD then
        RX_HudDrawRestartMessage
      else
        exit;
    end
    else if (screenblocks = 11) and (amstate <> am_only) then
      RX_HudDrawerCockpit(cm_fulldisplay)
    else if (screenblocks = 12) and (amstate <> am_only) then
      RX_HudDrawerCockpit(cm_halfdisplay)
    else if (screenblocks = 13) and (amstate <> am_only) then
      RX_HudDrawerSmall
    else
      RX_HudDrawerStatusbar;
  end;

  V_CopyRectTransparent(0, 0, SCN_HUD, 320, 200, 0, 0, SCN_FG, true);
end;

end.

