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
//  DESCRIPTION:
//   Radix A.I.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_logic;

interface

uses
  radix_level;

var
  radixactions: Pradixaction_tArray;
  numradixactions: integer;
  radixtriggers: Pradixtrigger_tArray;
  numradixtriggers: integer;

//==============================================================================
//
// RX_RunTriggers
//
//==============================================================================
procedure RX_RunTriggers;

//==============================================================================
//
// RX_RunTrigger
//
//==============================================================================
procedure RX_RunTrigger(const trig_id: integer);

//==============================================================================
//
// RX_RunActions
//
//==============================================================================
procedure RX_RunActions;

var
  radixplayer: integer; // The player that activates a radix trigger

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  g_game,
  radix_actions,
  radix_grid;

//==============================================================================
//
// RX_RunTriggerAction
//
//==============================================================================
procedure RX_RunTriggerAction(const ra: Pradixtriggeraction_t);
begin
  case ra.activationflags of
    SPR_FLG_ACTIVATE:
      begin
        radixactions[ra.actionid].suspend := 0;
        radixactions[ra.actionid].enabled := 1;
      end;
    SPR_FLG_DEACTIVATE:
      radixactions[ra.actionid].suspend := 1; // Distinguist from $FFFF in radix.dat
    SPR_FLG_ACTIVATEONSPACE: ; // ?
    SPR_FLG_TONGLE:
      if radixactions[ra.actionid].suspend = 0 then
        radixactions[ra.actionid].suspend := 1
      else
      begin
        radixactions[ra.actionid].suspend := 0;
        radixactions[ra.actionid].enabled := 1;
      end;
  end;
end;

//==============================================================================
//
// RX_RunTrigger
//
//==============================================================================
procedure RX_RunTrigger(const trig_id: integer);
var
  trig: Pradixtrigger_t;
  i: integer;
begin
  trig := @radixtriggers[trig_id];
  if trig.suspended = 0 then
    for i := 0 to trig.numactions - 1 do
      RX_RunTriggerAction(@trig.actions[i]);
end;

//==============================================================================
// RX_RunTriggers
//
// JVAL: Handle radix triggers
// Note: No voodoo dolls
//
//==============================================================================
procedure RX_RunTriggers;
var
  i, p: integer;
  gridpositions: gridmovementpositions_t;
  grid_id: integer;
  trig_id: integer;
  T: TDNumberList;
begin
  T := TDNumberList.Create;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      radixplayer := i;
      gridpositions := RX_PosInGrid(players[i].mo);
      for p := 0 to gridpositions.numpositions - 1 do
      begin
        grid_id := gridpositions.positions[p];
        if (grid_id >= 0) and (grid_id < RADIXGRIDSIZE) then
        begin
          trig_id := radixgrid[grid_id];
          if players[i].last_grid_trigger <> trig_id then // JVAL: 20200313 - Don't trigger twice the trigger
          begin
            players[i].last_grid_trigger := trig_id;
            if trig_id >= 0 then
              if T.IndexOf(trig_id) < 0 then  // JVAL: 20200408 - Do not run trigger twice
              begin
                RX_RunTrigger(trig_id);
                T.Add(trig_id);
              end;
          end;
        end;
      end;
      T.FastClear;
    end;
  T.Free;
end;

//==============================================================================
//
// RX_RunAction
//
//==============================================================================
procedure RX_RunAction(const action: Pradixaction_t);
begin
  case action.action_type of
     0: RA_ScrollingWall(action);
     1: RA_MovingSurface(action);
     2: RA_SwitchWallBitmap(action);
     3: RA_SwitchSecBitmap(action);
     4: RA_ToggleWallBitmap(action);
     5: RA_ToggleSecBitmap(action);
     6: RA_CircleBitmap(action);
     7: RA_LightFlicker(action);
     8: RA_LightsOff(action);
     9: RA_LightsOn(action);
    10: RA_LightOscilate(action);
    11: RA_PlaneTeleport(action);
    12: RA_PlaneTranspo(action);
    13: RA_NewMovingSurface(action);
    14: RA_PlaySound(action);
    15: RA_RandLightsFlicker(action);
    16: RA_EndOfLevel(action);
    17: RA_SpriteTriggerActivate(action);
    18: RA_SectorBasedGravity(action);
    19: RA_DeactivateTrigger(action);
    20: RA_ActivateTrigger(action);
    21: RA_CompleteMissileWall(action);
    22: RA_ScannerJam(action);
    23: RA_PrintMessage(action);
    24: RA_FloorMissileWall(action);
    25: RA_CeilingMissileWall(action);
    26: RA_BigSpriteTrig(action);
    27: RA_MassiveExplosion(action);
    28: RA_WallDeadCheck(action);
    29: RA_SecondaryObjective(action);
    30: RA_SeekCompleteMissileWall(action);
    31: RA_LightMovement(action);
    32: RA_MultLightOscilate(action);
    33: RA_MultRandLightsFlicker(action);
    34: RA_KillRatio(action);
    35: RA_HurtPlayerExplosion(action);
    36: RA_SwitchShadeType(action);
    37: RA_SixLightMovement(action);
    38: RA_SurfacePowerUp(action);
    39: RA_SecretSprite(action);
    40: RA_BossEyeHandler(action);
    41: RA_VertExplosion(action);
    42: RA_ChangeFloorOffsets(action);
    43: RA_MassiveLightMovement(action);
  end;
end;

//==============================================================================
//
// RX_RunActions
//
//==============================================================================
procedure RX_RunActions;
var
  i: integer;
  action: Pradixaction_t;
begin
  action := @radixactions[0];
  for i := 0 to numradixactions - 1 do
  begin
    if action.enabled = 1 then
      if action.suspend = 0 then
        RX_RunAction(action);
    inc(action);
  end;
end;

end.

