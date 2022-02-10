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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit rtl_types;

interface

uses
  d_delphi,
  doomdef;

const
  RTL_ST_SPAWN = 1;
  RTL_ST_SEE = 2;
  RTL_ST_MELEE = 4;
  RTL_ST_MISSILE = 8;
  RTL_ST_PAIN = 16;
  RTL_ST_DEATH = 32;
  RTL_ST_XDEATH = 64;
  RTL_ST_RAISE = 128;
  RTL_ST_HEAL = 256;
  RTL_ST_CRASH = 512;
  {$IFDEF DOOM_OR_STRIFE}
  RTL_ST_INTERACT = 1024;
  {$ENDIF}

type
  rtl_state_t = record
    sprite: string;
    frame: integer;
    tics: integer;
    tics2: integer;
    action: string;
    nextstate: integer;
    misc1: integer;
    misc2: integer;
    flags_ex: integer;
    bright: boolean;
    has_goto: boolean;
    gotostr_needs_calc: boolean;
    gotostr_calc: string;
    alias: string;
    savealias: string;
  end;
  Prtl_state_t = ^rtl_state_t;

type
  rtl_mobjinfo_t = record
    name: string;
    {$IFDEF STRIFE}
    name2: string;
    {$ENDIF}
    inheritsfrom: string;
    doomednum: integer;
    spawnstate: integer;
    spawnhealth: integer;
    seestate: integer;
    seesound: string;
    reactiontime: integer;
    attacksound: string;
    painstate: integer;
    painchance: integer;
    painsound: string;
    meleestate: integer;
    missilestate: integer;
    deathstate: integer;
    xdeathstate: integer;
    deathsound: string;
    speed: integer;
    radius: integer;
    height: integer;
    mass: integer;
    damage: integer;
    activesound: string;
    flags: string;
    {$IFDEF HERETIC_OR_HEXEN}
    flags2: string;
    {$ENDIF}
    flags_ex: string;
    flags2_ex: string;
    flags3_ex: string;
    flags4_ex: string;
    raisestate: integer;
    customsound1: string;
    customsound2: string;
    customsound3: string;
    dropitem: string;
    missiletype: string;
    explosiondamage: integer;
    explosionradius: integer;
    meleedamage: integer;
    meleesound: string;
    renderstyle: string;
    alpha: integer;
    healstate: integer;
    crashstate: integer;
    {$IFDEF DOOM_OR_STRIFE}
    interactstate: integer;
    missileheight: integer;
    {$ENDIF}
    vspeed: float;
    pushfactor: float;
    statesdefined: LongWord;
    replacesid: integer;
    scale: float;
    gravity: float;
    armour_inc: integer;  // JVAL 20200321 - Armour inc for pickable objects
    energy_inc: integer;  // JVAL 20200321 - Energy inc for pickable objects
    shield_inc: integer;  // JVAL 20200321 - Shield inc for pickable objects
    armour_set: integer;  // JVAL 20200321 - Armour set for pickable objects
    energy_set: integer;  // JVAL 20200321 - Energy set for pickable objects
    shield_set: integer;  // JVAL 20200321 - Shield set for pickable objects
    rapidshield: integer; // JVAL 20200322 - Rapid shield regenerator tics
    rapidenergy: integer; // JVAL 20200322 - Rapid energy regenerator tics
    maneuverjets: integer;  // JVAL 20200322 - Maneuver jets tics
    nightvision: integer; // JVAL 20200322 - Night vision tics
    alds: integer;  // JVAL 20200322 - Automated Laset Defence System tics
    plasmabomb: integer;  // JVAL: 20200322 - Give player Plasma bomb
    ammo_inc: array[0..Ord(NUMAMMO) - 1] of integer;  // JVAL 20200321 - Ammo inc for pickable objects
    weapon_inc: array[0..Ord(NUMWEAPONS) - 1] of boolean; // JVAL 20200321 - Weapon pickable objects
    pickupmessage: string[64];  // JVAL 20200321 - Custom pickup message
    pickupsound: string;  // JVAL 20200321 - Custom pickup sound
    touchdamage: integer; // JVAL: 20200417 - Damage when touched
    patrolrange: integer; // JVAL: 20200501 - Maximum Patrol Range
    altdamage: integer; // JVAL: 20200608 - Alternate damage
  end;
  Prtl_mobjinfo_t = ^rtl_mobjinfo_t;

implementation

end.
