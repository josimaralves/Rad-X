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
//  Handling interactions (i.e., collisions).
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit p_inter;

interface

uses
  doomdef,
  dstrings,
  d_englsh,
  m_rnd,
  i_system,
  am_map,
  p_local,
  p_mobj_h,
  s_sound,
  d_player;

//==============================================================================
//
// P_GivePower
//
//==============================================================================
function P_GivePower(player: Pplayer_t; power: integer): boolean;

//==============================================================================
//
// P_TouchSpecialThing
//
//==============================================================================
procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);

//==============================================================================
//
// P_DamageMobj
//
//==============================================================================
procedure P_DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);

const
// a weapon is found with two clip loads,
// a big item has five clip loads
  maxammo: array[0..Ord(NUMAMMO) - 1] of integer = (5000, 400, 1500, 50);
  clipammo: array[0..Ord(NUMAMMO) - 1] of integer = (50, 4, 10, 1);

//==============================================================================
//
// P_CmdSuicide
//
//==============================================================================
procedure P_CmdSuicide;

var
  p_maxhealth: integer = 200;
  p_soulspherehealth: integer = 100;
  p_megaspherehealth: integer = 200;
  p_medikithealth: integer = 25;
  p_stimpackhealth: integer = 10;
  p_bonushealth: integer = 1;
  p_maxarmor: integer = 200;
  p_greenarmorclass: integer = 1;
  p_bluearmorclass: integer = 2;

implementation

uses
  c_cmds,
  d_delphi,
  info_h,
  info,
  m_fixed,
  d_items,
  g_game,
  p_tick,
  p_mobj,
  p_pspr,
  ps_main, // JVAL: Script Events
  radix_things,
  r_defs,
  r_main,
  tables,
  sound_data;

const
  BONUSADD = 6;

//==============================================================================
//
// GET STUFF
//
// P_GiveAmmo
//
//==============================================================================
function P_GiveAmmo(player: Pplayer_t; ammo: ammotype_t; num: integer): boolean;
var
  oldammo: integer;
begin
  if ammo = am_noammo then
  begin
    result := false;
    exit;
  end;

  if (gameepisode = 1) then
    if (ammo = am_radixtorp) or (ammo = am_radixnuke) then
    begin
      result := false;
      exit;
    end;

  if (Ord(ammo) < 0) or (Ord(ammo) > Ord(NUMAMMO)) then
    I_Error('P_GiveAmmo(): bad type %d', [Ord(ammo)]);

  if player.ammo[Ord(ammo)] = player.maxammo[Ord(ammo)] then
  begin
    result := false;
    exit;
  end;

  if gameskill = sk_nightmare then
  begin
    // give double ammo in nightmare
    num := num * 2
  end;

  oldammo := player.ammo[Ord(ammo)];
  player.ammo[Ord(ammo)] := player.ammo[Ord(ammo)] + num;

  if player.ammo[Ord(ammo)] > player.maxammo[Ord(ammo)] then
    player.ammo[Ord(ammo)] := player.maxammo[Ord(ammo)];

  // If non zero ammo,
  // don't change up weapons,
  // player was lower on purpose.
  if oldammo <> 0 then
  begin
    result := true;
    exit;
  end;

  // We were down to zero,
  // so select a new weapon.
  // Preferences are not user selectable.
  case ammo of
    am_radixshell:
      begin
        if player.readyweapon = wp_neutroncannons then
        begin
          if player.weaponowned[Ord(wp_standardepc)] <> 0 then
            player.pendingweapon := wp_standardepc;
        end;
      end;
    am_radixmisl:
      begin
        if (player.readyweapon = wp_neutroncannons) or
           (player.readyweapon = wp_standardepc) then
        begin
          if player.weaponowned[Ord(wp_seekingmissiles)] <> 0 then
            player.pendingweapon := wp_seekingmissiles;
        end;
      end;
    am_radixtorp:
      begin
        if (player.readyweapon = wp_neutroncannons) or
           (player.readyweapon = wp_standardepc) then
        begin
          if player.weaponowned[Ord(wp_phasetorpedoes)] <> 0 then
            player.pendingweapon := wp_phasetorpedoes;
        end;
      end;
    am_radixnuke:
      begin
        if (player.readyweapon = wp_neutroncannons) or
           (player.readyweapon = wp_standardepc) then
        begin
          if player.weaponowned[Ord(wp_nuke)] <> 0 then
            player.pendingweapon := wp_nuke;
        end
      end;
  end;

  result := true;
end;

//==============================================================================
//
// P_GiveWeapon
// The weapon name may have a MF_DROPPED flag ored in.
//
//==============================================================================
function P_GiveWeapon(player: Pplayer_t; weapon: weapontype_t; dropped: boolean): boolean;
var
  gaveammo: boolean;
  gaveweapon: boolean;
  ammo: ammotype_t;
begin
  ammo := weaponinfo[Ord(weapon)].ammo;
  if netgame and (deathmatch <> 2) and not dropped then
  begin
  // leave placed weapons forever on net games
    if player.weaponowned[Ord(weapon)] <> 0 then
    begin
      result := false;
      exit;
    end;

    player.bonuscount := player.bonuscount + BONUSADD;
    player.weaponowned[Ord(weapon)] := 1;

    if deathmatch <> 0 then
      P_GiveAmmo(player, ammo, clipammo[Ord(ammo)] * 5)
    else
      P_GiveAmmo(player, ammo, clipammo[Ord(ammo)] * 2);
    if weapon = wp_gravitywave then
      player.gravitywave := MAXGRAVITYWAVE;

    player.pendingweapon := weapon;

    if (player = @players[consoleplayer]) then
      S_StartSound(nil, Ord(sfx_wpnup));

    result := false;
    exit;
  end;

  if ammo <> am_noammo then
  begin
  // give one clip with a dropped weapon,
  // two clips with a found weapon
    if dropped then
      gaveammo := P_GiveAmmo(player, ammo, clipammo[Ord(ammo)] * 1)
    else
      gaveammo := P_GiveAmmo(player, ammo, clipammo[Ord(ammo)] * 2);
  end
  else
  begin
    if (weapon = wp_gravitywave) and (player.gravitywave < MAXGRAVITYWAVE) then
    begin
      player.gravitywave := MAXGRAVITYWAVE;
      gaveammo := true;
    end
    else
      gaveammo := false;
  end;

  if player.weaponowned[Ord(weapon)] <> 0 then
    gaveweapon := false
  else
  begin
    gaveweapon := true;
    player.weaponowned[Ord(weapon)] := 1;
    player.pendingweapon := weapon;
  end;

  result := gaveweapon or gaveammo;
end;

//==============================================================================
//
// P_GiveBody
// Returns false if the body isn't needed at all
//
//==============================================================================
function P_GiveBody(player: Pplayer_t; num: integer): boolean;
begin
  if player.health >= mobjinfo[Ord(MT_PLAYER)].spawnhealth then
  begin
    result := false;
    exit;
  end;

  player.health := player.health + num;
  if player.health > mobjinfo[Ord(MT_PLAYER)].spawnhealth then
    player.health := mobjinfo[Ord(MT_PLAYER)].spawnhealth;
  player.mo.health := player.health;

  result := true;
end;

//==============================================================================
//
// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.
//
//==============================================================================
function P_GiveArmor(player: Pplayer_t; armortype: integer): boolean;
var
  hits: integer;
begin
  hits := armortype * 100;
  if player.armorpoints >= hits then
  begin
    result := false;  // don't pick up
    exit;
  end;

  player.armortype := armortype;
  player.armorpoints := hits;

  result := true;
end;

//==============================================================================
//
// JVAL 20200321 - New function
// P_GiveEnergy
//   Increases player energy
//
//==============================================================================
function P_GiveEnergy(player: Pplayer_t; ammount: integer): boolean;
begin
  if player.energy >= PLAYERMAXENERGY then
  begin
    result := false;
    exit;
  end;

  player.energy := player.energy + ammount;
  if player.energy > PLAYERMAXENERGY then
    player.energy := PLAYERMAXENERGY;

  result := true;
end;

//==============================================================================
//
// P_GiveCard
//
//==============================================================================
procedure P_GiveCard(player: Pplayer_t; card: card_t);
begin
  if player.cards[Ord(card)] then
    exit;

  player.bonuscount := BONUSADD;
  player.cards[Ord(card)] := true;
end;

//==============================================================================
//
// P_GivePower
//
//==============================================================================
function P_GivePower(player: Pplayer_t; power: integer): boolean;
begin
  if power = Ord(pw_invulnerability) then
  begin
    player.powers[power] := INVULNTICS;
    result := true;
    exit;
  end;

  if power = Ord(pw_invisibility) then
  begin
    player.powers[power] := INVISTICS;
    player.mo.flags := player.mo.flags or MF_SHADOW;
    result := true;
    exit;
  end;

  if power = Ord(pw_infrared) then
  begin
    player.powers[power] := INFRATICS;
    result := true;
    exit;
  end;

  if power = Ord(pw_ironfeet) then
  begin
    player.powers[power] := IRONTICS;
    result := true;
    exit;
  end;

  if power = Ord(pw_strength) then
  begin
    P_GiveBody(player, 100);
    player.powers[power] := 1;
    result := true;
    exit;
  end;

  if player.powers[power] <> 0 then
    result := false // already got it
  else
  begin
    player.powers[power] := 1;
    result := true;
  end;
end;

//==============================================================================
//
// P_GiveRapidShield
//
//==============================================================================
function P_GiveRapidShield(const p: Pplayer_t; const tics: integer): boolean;
begin
  if p.radixpowers[Ord(rpu_rapidshield)] < tics then
  begin
    p.radixpowers[Ord(rpu_rapidshield)] := tics;
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_GiveRapidEnergy
//
//==============================================================================
function P_GiveRapidEnergy(const p: Pplayer_t; const tics: integer): boolean;
begin
  if p.radixpowers[Ord(rpu_rapidenergy)] < tics then
  begin
    p.radixpowers[Ord(rpu_rapidenergy)] := tics;
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_GiveManeuverJets
//
//==============================================================================
function P_GiveManeuverJets(const p: Pplayer_t; const tics: integer): boolean;
begin
  if p.radixpowers[Ord(rpu_maneuverjets)] < tics then
  begin
    p.radixpowers[Ord(rpu_maneuverjets)] := tics;
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_GiveNightVision
//
//==============================================================================
function P_GiveNightVision(const p: Pplayer_t; const tics: integer): boolean;
begin
  if p.radixpowers[Ord(rpu_nightvision)] < tics then
  begin
    p.radixpowers[Ord(rpu_nightvision)] := tics;
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_GiveALDS
//
//==============================================================================
function P_GiveALDS(const p: Pplayer_t; const tics: integer): boolean;
begin
  if p.radixpowers[Ord(rpu_alds)] < tics then
  begin
    p.radixpowers[Ord(rpu_alds)] := tics;
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_GivePlasmaBombs
//
//==============================================================================
function P_GivePlasmaBombs(const p: Pplayer_t; const bombs: integer): boolean;
begin
  if p.plasmabombs < PLAYERMAXPLASMABOMBS then
  begin
    p.plasmabombs := p.plasmabombs + bombs;
    if p.plasmabombs > PLAYERMAXPLASMABOMBS then
      p.plasmabombs := PLAYERMAXPLASMABOMBS;
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_UpgradeNeutronCannons
//
//==============================================================================
function P_UpgradeNeutronCannons(const p: Pplayer_t): boolean;
begin
  if p.neutroncannonlevel < MAXNEUTRONCANNONLEVEL - 1 then
  begin
    inc(p.neutroncannonlevel);
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_UpgradeNeutronSpreader
//
//==============================================================================
function P_UpgradeNeutronSpreader(const p: Pplayer_t): boolean;
begin
  if p.neutronspreaderlevel < MAXNEUTRONCANNONLEVEL - 1 then
  begin
    inc(p.neutronspreaderlevel);
    result := true;
  end
  else
    result := false;
end;

//==============================================================================
//
// P_TouchSpecialThing
//
//==============================================================================
procedure P_TouchSpecialThing(special: Pmobj_t; toucher: Pmobj_t);
var
  player: Pplayer_t;
  i: integer;
  delta: fixed_t;
  sound: integer;
// JVAL: To display correct message about the number of cells taken
  oldshells: integer;
  pickedshells: integer;
  pmsg: string;
  oldhealth: integer;
  didbonus: boolean;
  didneutronbonus: boolean;
  didspreaderbonus: boolean;
  didepcupgrade: integer;
  giveweapon: weapontype_t;
  hadspreader: boolean;
begin
  delta := special.z - toucher.z;

  if (delta > toucher.height) or (delta < - special.height) then
  // out of reach
    exit;

  player := toucher.player;
  if player.lastbonustime = leveltime then
    exit;

  // Dead thing touching.
  // Can happen with a sliding player corpse.
  if toucher.health <= 0 then
    exit;

  if special.flags3_ex and MF3_EX_CUSTOMPICKUP <> 0 then
  begin
    didbonus := false;

    if special.armour_inc > 0 then
    begin
      if P_GiveArmor(player, special.armour_inc) then
        didbonus := true;
    end;

    if special.energy_inc > 0 then
    begin
      if P_GiveEnergy(player, special.energy_inc) then
        didbonus := true;
    end;

    if special.shield_inc > 0 then
    begin
      if P_GiveBody(player, special.shield_inc) then
        didbonus := true;
    end;

    if special.armour_set > player.armorpoints then
    begin
      if P_GiveArmor(player, special.armour_set - player.armorpoints) then
        didbonus := true;
    end;

    if special.energy_set > player.energy then
    begin
      if P_GiveEnergy(player, special.energy_set - player.energy) then
        didbonus := true;
    end;

    if special.shield_set > player.health then
    begin
      if P_GiveBody(player, special.shield_set - player.health) then
        didbonus := true;
    end;

    for i := 0 to Ord(NUMAMMO) - 1 do
    begin
      if special.ammo_inc[i] > 0 then
        if P_GiveAmmo(player, ammotype_t(i), special.ammo_inc[i]) then
          didbonus := true;
    end;

    didepcupgrade := 0;
    hadspreader := player.weaponowned[Ord(wp_plasmaspreader)] <> 0;
    for i := 0 to Ord(NUMWEAPONS) - 1 do
    begin
      if special.weapon_inc[i] then
      begin
        giveweapon := weapontype_t(i);
        // JVAL: 20200514 - STANDARDEPC pickup upgrades to wp_superepc in 2nd and third episodes
        if giveweapon = wp_standardepc then
        begin
          if (player.weaponowned[Ord(wp_enchancedepc)] <> 0) and (gameepisode <> 1) then
            giveweapon := wp_superepc
          else if player.weaponowned[Ord(wp_standardepc)] <> 0 then
            giveweapon := wp_enchancedepc
        end;
        if P_GiveWeapon(player, giveweapon, special.flags and MF_DROPPED <> 0) then
        begin
          didbonus := true;
          if giveweapon = wp_superepc then
            didepcupgrade := 2
          else if giveweapon = wp_enchancedepc then
            didepcupgrade := 1;
        end;
      end;
    end;

    if special.info.rapidshield > 0 then
      if P_GiveRapidShield(player, special.info.rapidshield) then
        didbonus := true;

    if special.info.rapidenergy > 0 then
      if P_GiveRapidEnergy(player, special.info.rapidenergy) then
        didbonus := true;

    if special.info.maneuverjets > 0 then
      if P_GiveManeuverJets(player, special.info.maneuverjets) then
        didbonus := true;

    if special.info.nightvision > 0 then
      if P_GiveNightVision(player, special.info.nightvision) then
        didbonus := true;

    if special.info.alds > 0 then
      if P_GiveALDS(player, special.info.alds) then
        didbonus := true;

    if special.info.plasmabomb > 0 then
      if P_GivePlasmaBombs(player, special.info.plasmabomb) then
        didbonus := true;

    didneutronbonus := false;
    if special.info.doomednum = MT_LEVEL2NEUTRONCANNONS then
      didneutronbonus := P_UpgradeNeutronCannons(player);

    didspreaderbonus := false;
    if special.info.doomednum = MT_LEVEL1PLASMASPREADER then
      if hadspreader then // Alreader had plasma spreader
        didspreaderbonus := P_UpgradeNeutronSpreader(player);

    if not didbonus then
      if not didneutronbonus then
        if not didspreaderbonus then
          if didepcupgrade = 0 then
            exit;

    player.lastbonustime := leveltime;

    if didneutronbonus then
      player._message := neutroncannoninfo[player.neutroncannonlevel].msg
    else if didspreaderbonus then
      player._message := neutronspreaderinfo[player.neutronspreaderlevel].msg
    else if didepcupgrade in [1, 2] then
      player._message := epcupgrademessages[didepcupgrade]
    else
      player._message := special.info.pickupmessage;

    sound := Ord(special.info.pickupsound);
  end
  else
  begin
    player.lastbonustime := leveltime;

    sound := Ord(sfx_itemup);
    // Identify by sprite.
    case special.sprite of
    // armor
      Ord(SPR_ARM1):
        begin
          if not P_GiveArmor(player, p_greenarmorclass) then
            exit;
          player._message := GOTARMOR;
        end;

      Ord(SPR_ARM2):
        begin
          if not P_GiveArmor(player, p_bluearmorclass) then
            exit;
          player._message := GOTMEGA;
        end;

    // bonus items
      Ord(SPR_BON1):
        begin
          player.health := player.health + p_bonushealth; // can go over 100%
          if player.health > p_maxhealth then
            player.health := p_maxhealth;
          player.mo.health := player.health;
          player._message := GOTHTHBONUS;
        end;

      Ord(SPR_BON2):
        begin
          player.armorpoints := player.armorpoints + 1; // can go over 100%
          if player.armorpoints > p_maxarmor then
            player.armorpoints := p_maxarmor;
          if player.armortype = 0 then
            player.armortype := 1;
          player._message := GOTARMBONUS;
        end;

      Ord(SPR_SOUL):
        begin
          player.health := player.health + p_soulspherehealth;
          if player.health > p_maxhealth then
            player.health := p_maxhealth;
          player.mo.health := player.health;
          player._message := GOTSUPER;
          sound := Ord(sfx_getpow);
        end;

      Ord(SPR_MEGA):
        begin
          player.health := 200;
          player.mo.health := player.health;
          P_GiveArmor(player, p_bluearmorclass);
          player._message := GOTMSPHERE;
          sound := Ord(sfx_getpow);
        end;

    // cards
    // leave cards for everyone
      Ord(SPR_BKEY):
        begin
          if not player.cards[Ord(it_bluecard)] then
            player._message := GOTBLUECARD;
          P_GiveCard(player, it_bluecard);
        if netgame then
          exit;
        end;

      Ord(SPR_YKEY):
        begin
          if not player.cards[Ord(it_yellowcard)] then
            player._message := GOTYELWCARD;
          P_GiveCard(player, it_yellowcard);
          if netgame then
            exit;
        end;

      Ord(SPR_RKEY):
        begin
          if not player.cards[Ord(it_redcard)] then
            player._message := GOTREDCARD;
          P_GiveCard(player, it_redcard);
          if netgame then
            exit;
        end;

      Ord(SPR_BSKU):
        begin
          if not player.cards[Ord(it_blueskull)] then
            player._message := GOTBLUESKUL;
          P_GiveCard(player, it_blueskull);
          if netgame then
            exit;
        end;

      Ord(SPR_YSKU):
        begin
          if not player.cards[Ord(it_yellowskull)] then
            player._message := GOTYELWSKUL;
          P_GiveCard(player, it_yellowskull);
          if netgame then
            exit;
        end;

      Ord(SPR_RSKU):
        begin
          if not player.cards[Ord(it_redskull)] then
            player._message := GOTREDSKULL;
          P_GiveCard(player, it_redskull);
          if netgame then
            exit;
        end;

    // medikits, heals
      Ord(SPR_STIM):
        begin
          if not P_GiveBody(player, p_stimpackhealth) then
            exit;
          player._message := GOTSTIM;
        end;

      Ord(SPR_MEDI):
        begin
          oldhealth := player.health;
          if not P_GiveBody(player, p_medikithealth) then
            exit;

          // JVAL 20171210 Fix the https://doomwiki.org/wiki/Picked_up_a_medikit_that_you_REALLY_need! bug
          if player.mo <> nil then
          begin
            if oldhealth < player.mo.info.spawnhealth div 4 then
              player._message := GOTMEDINEED
            else
              player._message := GOTMEDIKIT;
          end
          else
          begin
            if player.health < p_medikithealth then
              player._message := GOTMEDINEED
            else
              player._message := GOTMEDIKIT;
          end;
        end;

    // power ups
      Ord(SPR_PINV):
        begin
          if not P_GivePower(player, Ord(pw_invulnerability)) then
            exit;
          player._message := GOTINVUL;
          sound := Ord(sfx_getpow);
        end;

      Ord(SPR_PSTR):
        begin
          if not P_GivePower(player, Ord(pw_strength)) then
            exit;
          player._message := GOTBERSERK;
          if player.readyweapon <> wp_neutroncannons then
            player.pendingweapon := wp_neutroncannons;
          sound := Ord(sfx_getpow);
        end;

      Ord(SPR_PINS):
        begin
          if not P_GivePower(player, Ord(pw_invisibility)) then
            exit;
          player._message := GOTINVIS;
          sound := Ord(sfx_getpow);
        end;

      Ord(SPR_SUIT):
        begin
          if not P_GivePower(player, Ord(pw_ironfeet)) then
            exit;
          player._message := GOTSUIT;
          sound := Ord(sfx_getpow);
        end;

      Ord(SPR_PMAP):
        begin
          if not P_GivePower(player, Ord(pw_allmap)) then
            exit;
          player._message := GOTMAP;
          sound := Ord(sfx_getpow);
        end;

      Ord(SPR_PVIS):
        begin
          if not P_GivePower(player, Ord(pw_infrared)) then
            exit;
          player._message := GOTVISOR;
          sound := Ord(sfx_getpow);
        end;

    // ammo
      Ord(SPR_CLIP):
        begin
          if special.flags and MF_DROPPED <> 0 then
          begin
            if not P_GiveAmmo(player, am_radixshell, clipammo[Ord(am_radixshell)] div 2) then
              exit;
          end
          else
          begin
            if not P_GiveAmmo(player, am_radixshell, clipammo[Ord(am_radixshell)]) then
              exit;
          end;
          player._message := GOTCLIP;
        end;

      Ord(SPR_AMMO):
        begin
          if not P_GiveAmmo(player, am_radixshell, clipammo[Ord(am_radixshell)] * 5) then
            exit;
          player._message := GOTCLIPBOX;
        end;

      Ord(SPR_ROCK):
        begin
          if not P_GiveAmmo(player, am_radixnuke, clipammo[Ord(am_radixnuke)] * 1) then
            exit;
          player._message := GOTROCKET;
        end;

      Ord(SPR_BROK):
        begin
          if not P_GiveAmmo(player, am_radixnuke, clipammo[Ord(am_radixnuke)] * 5) then
            exit;
          player._message := GOTROCKBOX;
        end;

      Ord(SPR_CELL):
        begin
          if not P_GiveAmmo(player, am_radixtorp, clipammo[Ord(am_radixtorp)] * 1) then
            exit;
          player._message := GOTCELL;
        end;

      Ord(SPR_CELP):
        begin
          if not P_GiveAmmo(player, am_radixtorp, clipammo[Ord(am_radixtorp)] * 5) then
            exit;
          player._message := GOTCELLBOX;
        end;

      Ord(SPR_SHEL):
        begin
        // JVAL: 7/12/2007 display exact number of picked-up shells.
          oldshells := player.ammo[Ord(am_radixmisl)];

          if not P_GiveAmmo(player, am_radixmisl, clipammo[Ord(am_radixmisl)] * 1) then
            exit;

          pickedshells := player.ammo[Ord(am_radixmisl)] - oldshells;
          if pickedshells > 0 then
          begin
            case pickedshells of
              4: player._message := GOTSHELLS;
              1: player._message := GOTONESHELL;
            else
              begin
                sprintf(pmsg, GOTMANYSHELLS, [pickedshells]);
                player._message := pmsg;
              end;
            end;
          end;
        end;

      Ord(SPR_SBOX):
        begin
          if not P_GiveAmmo(player, am_radixmisl, clipammo[Ord(am_radixmisl)] * 5) then
            exit;
          player._message := GOTSHELLBOX;
        end;

      Ord(SPR_BPAK):
        begin
          if not player.backpack then
          begin
            for i := 0 to Ord(NUMAMMO) - 1 do
              player.maxammo[i] := player.maxammo[i] * 2;
            player.backpack := true;
          end;
          for i := 0 to Ord(NUMAMMO) - 1 do
            P_GiveAmmo(player, ammotype_t(i), clipammo[i] * 1);
          player._message := GOTBACKPACK;
        end;

    // weapons
      Ord(SPR_BFUG):
        begin
          if not P_GiveWeapon(player, wp_gravitywave, false) then
            exit;
          player._message := GOTBFG9000;
          sound := Ord(sfx_wpnup);
        end;

      Ord(SPR_MGUN):
        begin
          if not P_GiveWeapon(player, wp_seekingmissiles, special.flags and MF_DROPPED <> 0) then
            exit;
          player._message := GOTCHAINGUN;
          sound := Ord(sfx_wpnup);
        end;

      Ord(SPR_CSAW):
        begin
          if not P_GiveWeapon(player, wp_enchancedepc, false) then
            exit;
          player._message := GOTCHAINSAW;
          sound := Ord(sfx_wpnup);
        end;

      Ord(SPR_LAUN):
        begin
          if not P_GiveWeapon(player, wp_nuke, false) then
            exit;
          player._message := GOTLAUNCHER;
          sound := Ord(sfx_wpnup);
        end;

      Ord(SPR_PLAS):
        begin
          if not P_GiveWeapon(player, wp_phasetorpedoes, false) then
            exit;
          player._message := GOTPLASMA;
          sound := Ord(sfx_wpnup);
        end;

      Ord(SPR_SHOT):
        begin
          if not P_GiveWeapon(player, wp_plasmaspreader, special.flags and MF_DROPPED <> 0) then
            exit;
          player._message := GOTSHOTGUN;
          sound := Ord(sfx_wpnup);
        end;

      Ord(SPR_SGN2):
        begin
          if not P_GiveWeapon(player, wp_superepc, special.flags and MF_DROPPED <> 0) then
            exit;
          player._message := GOTSHOTGUN2;
          sound := Ord(sfx_wpnup);
        end;

    else
      I_Error('P_TouchSpecialThing(): Unknown gettable thing');
    end;
  end;

  if special.flags and MF_COUNTITEM <> 0 then
    player.itemcount := player.itemcount + 1;
  P_RemoveMobj(special);
  player.bonuscount := player.bonuscount + BONUSADD;
  if sound > 0 then
    if player = @players[consoleplayer] then
      S_StartSound(nil, sound);
end;

//==============================================================================
// P_SpawnDroppedMobj
//
// KillMobj
//
//==============================================================================
function P_SpawnDroppedMobj(x, y, z: fixed_t; _type: integer): Pmobj_t;
begin
  result := P_SpawnMobj(x, y, z, _type);
  result.flags := result.flags or MF_DROPPED; // special versions of items
  // JVAL Dropped items fall down to floor.
  if not compatibilitymode then
  begin
    result.z := result.z + 32 * FRACUNIT;
    result.momz := 4 * FRACUNIT;
    result.momx := 64 * N_Random;
    result.momy := 64 * N_Random;
  end;
end;

//==============================================================================
//
// P_KillMobj
//
//==============================================================================
procedure P_KillMobj(source: Pmobj_t; target: Pmobj_t);
var
  item: integer;
  sp, tp: Pplayer_t;
begin
  target.flags := target.flags and (not (MF_SHOOTABLE or MF_FLOAT or MF_SKULLFLY));
  target.flags3_ex := target.flags3_ex and not MF3_EX_BOUNCE;

  if target._type <> Ord(MT_SKULL) then
    target.flags := target.flags and not MF_NOGRAVITY;

  target.flags := target.flags or (MF_CORPSE or MF_DROPOFF);
  target.flags2_ex := target.flags2_ex and not MF2_EX_PASSMOBJ;
  target.height := target.height div 4;

  if (source <> nil) and (source.player <> nil) then
  begin
    sp := source.player;
    // count for intermission
    if target.flags and MF_COUNTKILL <> 0 then
      sp.killcount := sp.killcount + 1;

    if target.player <> nil then
      sp.frags[pDiff(target.player, @players[0], SizeOf(player_t))] :=
        sp.frags[pDiff(target.player, @players[0], SizeOf(player_t))] + 1;
  end
  else if not netgame and (target.flags and MF_COUNTKILL <> 0) then
  begin
    // count all monster deaths,
    // even those caused by other monsters
    players[0].killcount := players[0].killcount + 1;
  end;

  if target.player <> nil then
  begin
    tp := target.player;
    // count environment kills against you
    if source = nil then
      tp.frags[pDiff(target.player, @players[0], SizeOf(player_t))] :=
        tp.frags[pDiff(target.player, @players[0], SizeOf(player_t))] + 1;

    target.flags := target.flags and not MF_SOLID;
    tp.playerstate := PST_DEAD;

    // JVAL
    // Save the attacker coordinates
    if tp.attacker <> nil then
    begin
      tp.attackerx := tp.attacker.x;
      tp.attackery := tp.attacker.y;
    end;

    P_DropWeapon(tp);

    if (tp = @players[consoleplayer]) and (amstate = am_only) then
    begin
      // don't die in auto map,
      // switch view prior to dying
      amstate := am_inactive;
      AM_Stop;
    end;

  end;

  if (target.health < -target.info.spawnhealth) and (target.info.xdeathstate <> 0) then
    P_SetMobjState(target, statenum_t(target.info.xdeathstate))
  else
    P_SetMobjState(target, statenum_t(target.info.deathstate));
  target.tics := target.tics - (P_Random and 3);

  if target.tics < 1 then
    target.tics := 1;

  if target.player <> nil then    // JVAL: Script Events
    PS_EventPlayerDied(pDiff(@players[0], target.player, SizeOf(player_t)), source);
  PS_EventActorDied(target, source); // JVAL: Script Events

  // Drop stuff.
  // This determines the kind of object spawned
  // during the death frame of a thing.

  item := target.info.dropitem;

// JVAL: Check if dropitem is set to drop a custom item.
  if target.flags2_ex and MF2_EX_CUSTOMDROPITEM <> 0 then
    item := target.dropitem;

// JVAL: 20200301 - Fix P_SpawnDroppedMobj() bug
  if item <= 0 then
    Exit;

  if Psubsector_t(target.subsector).sector.midsec >= 0 then // JVAL: 3d Floors
    P_SpawnDroppedMobj(target.x, target.y, target.z, item)
  else
    P_SpawnDroppedMobj(target.x, target.y, ONFLOORZ, item);
end;

//==============================================================================
//
// P_DamageMobj
// Damages both enemies and players
// "inflictor" is the thing that caused the damage
//  creature or missile, can be NULL (slime, etc)
// "source" is the thing to target after taking damage
//  creature or NULL
// Source and inflictor are the same for melee attacks.
// Source can be NULL for slime, barrel explosions
// and other environmental stuff.
//
//==============================================================================
procedure P_DamageMobj(target, inflictor, source: Pmobj_t; damage: integer);
var
  ang: angle_t;
  saved: integer;
  player: Pplayer_t;
  thrust: fixed_t;
  mass: integer;
begin
  if target.flags and MF_SHOOTABLE = 0 then
  begin
  // 19/9/2009 JVAL: Display a warning message for debugging
    I_DevWarning('P_DamageMobj(): Trying to damage unshootable mobj "%s"'#13#10, [target.info.name]);
//    target.tics := -1;
    exit; // shouldn't happen...
  end;

  // JVAL: Invulnerable monsters
  if target.flags_ex and MF_EX_INVULNERABLE <> 0 then
    exit;

  if target.flags2_ex and MF2_EX_NODAMAGE <> 0 then
    exit;

  if target.health <= 0 then
    exit;

  if target.flags and MF_SKULLFLY <> 0 then
  begin
    target.momx := 0;
    target.momy := 0;
    target.momz := 0;
  end;

  player := target.player;
  if player <> nil then
  begin
    if gameskill <> sk_nightmare then
    begin
      damage := damage * (1 + Ord(gameskill)) div (1 + Ord(sk_nightmare));
      if damage < 1 then
        damage := 1;
    end;
    damage := (damage * (128 + P_Random)) div 384;
    if damage < 1 then
      damage := 1;
  end;

  if (inflictor <> nil) and (target.flags_ex and MF_EX_FIRERESIST <> 0) then
  begin
    if damage > 1 then
      damage := damage div 2;
  end;

  // Some close combat weapons should not
  // inflict thrust and push the victim out of reach,
  // thus kick away
  if (inflictor <> nil) and (target.flags and MF_NOCLIP = 0) then
  begin
    ang := R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y);

    mass := target.info.mass;
    if mass = 0 then
    begin
      I_DevWarning('P_DamageMobj(): Target (%s) mass is zero'#13#10, [target.info.name]);
      thrust := 0;
    end
    else
      thrust := (damage * $2000 * 100) div mass;

    // make fall forwards sometimes
    if (damage < 40) and (damage > target.health) and
       (target.z - inflictor.z > 64 * FRACUNIT) and (P_Random and 1 <> 0) then
    begin
      ang := ang + ANG180;
      thrust := thrust * 4;
    end;

    ang := ang shr ANGLETOFINESHIFT;
    target.momx := target.momx + FixedMul(thrust, finecosine[ang]);
    target.momy := target.momy + FixedMul(thrust, finesine[ang]);
  end;

  // player specific
  if player <> nil then
  begin
    // end of game hell hack
    if (Psubsector_t(target.subsector).sector.special = 11) and (damage >= target.health) then
      damage := target.health - 1;

    // Below certain threshold,
    // ignore damage in GOD mode, or with INVUL power.
    if (damage < 1000) and
       ((player.cheats and CF_GODMODE <> 0) or (player.powers[Ord(pw_invulnerability)] <> 0)) then
      exit;

    if player.armortype <> 0 then
    begin
      if player.armortype = 1 then
        saved := damage div 3
      else
        saved := damage div 2;

      if player.armorpoints <= saved then
      begin
        // armor is used up
        saved := player.armorpoints;
        player.armortype := 0;
      end;
      player.armorpoints := player.armorpoints - saved;
      damage := damage - saved;
    end;
    player.health := player.health - damage;  // mirror mobj health here for Dave
    if player.health < 0 then
      player.health := 0;

    player.attacker := source;
    player.damagecount := player.damagecount + damage;  // add damage after armor / invuln

    if player.damagecount > 100 then
      player.damagecount := 100;  // teleport stomp does 10k points...

    player.hardbreathtics := player.damagecount * 10;
  end;

  // do the damage
  target.health := target.health - damage;
  if target.health <= 0 then
  begin
    P_KillMobj(source, target);
    exit;
  end;

  if (P_Random < target.info.painchance) and
     ((target.flags and MF_SKULLFLY) = 0) then
  begin
    target.flags := target.flags or MF_JUSTHIT; // fight back!
    P_SetMobjState(target, statenum_t(target.info.painstate));
  end;

  target.reactiontime := 0; // we're awake now...

  if ((target.threshold = 0) or (target._type = Ord(MT_VILE))) and
     (source <> nil) and (source <> target) and (source._type <> Ord(MT_VILE)) then
  begin
    // if not intent on another player,
    // chase after this one
    if target.flags2_ex and MF2_EX_DONTINFIGHTMONSTERS = 0 then
    begin
      target.target := source;
      target.threshold := BASETHRESHOLD;
      if (target.state = @states[target.info.spawnstate]) and
         (target.info.seestate <> Ord(S_NULL)) then
        P_SetMobjState(target, statenum_t(target.info.seestate));
    end;
  end;
end;

//==============================================================================
//
// P_CmdSuicide
//
//==============================================================================
procedure P_CmdSuicide;
begin
  if demoplayback then
  begin
    I_Warning('P_CmdSuicide(): You can''t suicide during demo playback.'#13#10);
    exit;
  end;
  if demorecording then
  begin
    I_Warning('P_CmdSuicide(): You can''t suicide during demo recording.'#13#10);
    exit;
  end;

  if (gamestate = GS_LEVEL) and (players[consoleplayer].mo <> nil) then
  begin
    if players[consoleplayer].health > 0 then
    begin
      C_ExecuteCmd('closeconsole');
      P_DamageMobj(players[consoleplayer].mo, nil, nil, 1000);
      players[consoleplayer]._message := 'You give up too easy';
    end
    else
      printf('You''re already dead.'#13#10);
  end
  else
    I_Warning('P_CmdSuicide(): You can''t suicide if you aren''t playing.'#13#10);
end;

end.

