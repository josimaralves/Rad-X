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
//  Items: key cards, artifacts, weapon, ammunition.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit d_items;

interface

uses
  doomdef,
  info_h;

type
  { Weapon info: sprite frames, ammunition use. }
  weaponinfo_t = record
    ammo: ammotype_t;
    upstate: integer;
    downstate: integer;
    readystate: integer;
    atkstate: integer;
    flashstate: integer;
    refiretics: integer;
    altrefiretics: integer;
    selecttext: string[64];
  end;
  Pweaponinfo_t = ^weaponinfo_t;

//
// PSPRITE ACTIONS for waepons.
// This struct controls the weapon animations.
//
// Each entry is:
//   ammo/amunition type
//   upstate
//   downstate
//   readystate
//   atkstate, i.e. attack/fire/hit frame
//   flashstate, muzzle flash
//

var
  weaponinfo: array[0..Ord(NUMWEAPONS) - 1] of weaponinfo_t = (
    // Neutron Cannon
    (ammo: am_noammo;            upstate: Ord(S_PUNCHUP);   downstate: Ord(S_PUNCHDOWN);
     readystate: Ord(S_PUNCH);   atkstate: Ord(S_PUNCH1);   flashstate: Ord(S_NULL);
     refiretics: 5;              altrefiretics: 3;          selecttext: 'Neutron Cannons Selected'),
    // Standard EPC
    (ammo: am_radixshell;        upstate: Ord(S_PISTOLUP);  downstate: Ord(S_PISTOLDOWN);
     readystate: Ord(S_PISTOL);  atkstate: Ord(S_PISTOL1);  flashstate: Ord(S_PISTOLFLASH);
     refiretics: 2;              altrefiretics: 2;          selecttext: 'Standard Explosive Projectile Cannons Selected'),
    // Plasma Spreader
    (ammo: am_noammo;            upstate: Ord(S_SGUNUP);    downstate: Ord(S_SGUNDOWN);
     readystate: Ord(S_SGUN);    atkstate: Ord(S_SGUN1);    flashstate: Ord(S_SGUNFLASH1);
     refiretics: 5;              altrefiretics: 3;          selecttext: 'Plasma Spreader Selected'),
    // Seeking Missiles
    (ammo: am_radixmisl;         upstate: Ord(S_CHAINUP);   downstate: Ord(S_CHAINDOWN);
     readystate: Ord(S_CHAIN);   atkstate: Ord(S_CHAIN1);   flashstate: Ord(S_CHAINFLASH1);
     refiretics: 20;             altrefiretics: 18;         selecttext: 'Conventional Missiles Selected'),
    // Nuke
    (ammo: am_radixnuke;         upstate: Ord(S_MISSILEUP); downstate: Ord(S_MISSILEDOWN);
     readystate: Ord(S_MISSILE); atkstate: Ord(S_MISSILE1); flashstate: Ord(S_MISSILEFLASH1);
     refiretics: 18;             altrefiretics: 16;         selecttext: 'Neuclear Missiles Selected'),
    // Phase Torpedoes
    (ammo: am_radixtorp;         upstate: Ord(S_PLASMAUP);  downstate: Ord(S_PLASMADOWN);
     readystate: Ord(S_PLASMA);  atkstate: Ord(S_PLASMA1);  flashstate: Ord(S_PLASMAFLASH1);
     refiretics: 20;             selecttext: 'Phase Torpedoes Selected'),
    // Gravity Device
    (ammo: am_noammo;            upstate: Ord(S_BFGUP);     downstate: Ord(S_BFGDOWN);
     readystate: Ord(S_BFG);     atkstate: Ord(S_BFG1);     flashstate: Ord(S_BFGFLASH1);
     refiretics: 35;             altrefiretics: 30;         selecttext: 'Gravity Wave Selected'),
    // Enhanced EPC
    (ammo: am_radixshell;        upstate: Ord(S_SAWUP);     downstate: Ord(S_SAWDOWN);
     readystate: Ord(S_SAW);     atkstate: Ord(S_SAW1);     flashstate: Ord(S_NULL);
     refiretics: 2;              altrefiretics: 2;          selecttext: 'Enhanced Explosive Projectile Cannons Selected'),
    // Super EPC
    (ammo: am_radixshell;        upstate: Ord(S_DSGUNUP);   downstate: Ord(S_DSGUNDOWN);
     readystate: Ord(S_DSGUN);   atkstate: Ord(S_DSGUN1);   flashstate: Ord(S_DSGUNFLASH1);
     refiretics: 3;              altrefiretics: 3;          selecttext: 'Super Explosive Projectile Cannons Selected')
  );

implementation

end.

