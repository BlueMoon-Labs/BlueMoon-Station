// What a deathmatch player spawns wearing and holding.
//
// Every loadout extends /datum/outfit/vr, so it inherits the dna handling, the
// id card and the bank account that the rest of the VR framework assumes, and
// nothing else from it: no sleepers, no station life.
//
// Note that this /datum/outfit has no `weapon` and no `under` var, so a melee
// weapon goes in a hand and a mask goes in `mask`.

/datum/outfit/vr/deathmatch_loadout
	name = "Deathmatch Loadout"
	/// Name shown in the deathmatch picker. Separate from `name` because `name` is
	/// what the outfit system itself prints in admin logs and debug output, and the
	/// picker wants something a player would recognise in a list. Falls back to
	/// `name`, so a loadout that only set the old var still reads correctly.
	var/display_name = ""
	/// One line describing what the kit is for, shown beside the picker so a
	/// player can tell Sniper from Sniper Elite without opening the loadout screen.
	var/desc = ""
	/// If set, the wearer is turned into this species before the outfit is applied.
	var/datum/species/species_override
	/// Handed out by a team mode's own rotation rather than by the deathmatch
	/// picker. These are halves of a team pair - one side's shotgun, the other
	/// side's sniper - so the free-for-all picker must not offer them: a player
	/// who picked "Counter-Terrorist Pistols" in a free-for-all would be choosing
	/// a side that does not exist there.
	var/tdm_only = FALSE

/// What the picker calls this loadout.
///
/// display_name when somebody bothered to write one, name otherwise.
/datum/outfit/vr/deathmatch_loadout/proc/get_display_name()
	return display_name || name

/datum/outfit/vr/deathmatch_loadout/pre_equip(mob/living/carbon/human/H, visuals_only = FALSE, client/preference_source)
	. = ..()
	if(!isnull(species_override))
		H.set_species(species_override)
	else if(!isnull(H.dna.species.outfit_important_for_life)) //plasmamen get lit on fire and die
		H.set_species(/datum/species/human)

/**
 * No weapon at all. Fists.
 *
 * The default, because it is the only loadout that is fair on every map without
 * the map having to be balanced around it.
 */
/datum/outfit/vr/deathmatch_loadout/bare
	name = "Bystander"
	display_name = "Bystander"
	desc = "Grey sweats and nothing else. Fists only."
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black


/// Melee. Cheap and close range: a vest keeps you alive on the way in, and a
/// fistful of combat knives does the rest. Knives throw, which is what "brawled"
/// looks like at range.
/datum/outfit/vr/deathmatch_loadout/brawler
	name = "Brawler"
	display_name = "Brawler"
	desc = "An armored vest and a handful of throwing knives. Cheap, and the knives still work while sprinting."
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/color/black
	suit = /obj/item/clothing/suit/armor/vest
	l_hand = /obj/item/kitchen/knife/combat
	r_pocket = /obj/item/kitchen/knife/combat/marksman
	back = /obj/item/storage/backpack
	backpack_contents = list(
		/obj/item/kitchen/knife/combat/marksman = 4,
	)

/// A sidearm. Low damage, but it does not push people out of cover.
/datum/outfit/vr/deathmatch_loadout/sidearm
	name = "Sidearm"
	display_name = "Sidearm"
	desc = "A cheap pistol and a spare magazine. Low damage, but it will not push anyone out of cover."
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	belt = /obj/item/gun/ballistic/automatic/pistol/m9mmpistol
	l_pocket = /obj/item/ammo_box/magazine/m9/inc

/// The one-shot rifle every instagib round runs on. One touch, one kill: the
/// arena is the whole loadout, and the loadout is just the rifle.
/datum/outfit/vr/deathmatch_loadout/instakill
	name = "Instakill"
	display_name = "Instakill"
	desc = "A one-shot laser rifle. Instagib, as advertised."
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/energy/laser/instakill

/**
 * Disabler, Security Ring kit. Being shot is the whole point of that arena, so
 * this is what a security officer actually walks onto the ring in: the jumpsuit,
 * boots, helmet, webbing and vest, and a taser instead of a sidearm.
 *
 * KNOWN GAP: the loadout this was ported from handed out a hybrid taser. There is
 * no hybrid taser in this codebase, so it gets the plain taser: the same
 * non-lethal tradeoff, minus the ballistic half.
 */
/datum/outfit/vr/deathmatch_loadout/officer
	name = "Officer"
	display_name = "Officer"
	desc = "The Security Ring kit: helmet, vest, webbing, and a taser instead of a gun."
	uniform = /obj/item/clothing/under/rank/security/officer
	shoes = /obj/item/clothing/shoes/jackboots
	head = /obj/item/clothing/head/helmet
	belt = /obj/item/storage/belt/security/full
	suit = /obj/item/clothing/suit/armor/vest
	r_hand = /obj/item/gun/energy/e_gun/advtaser

/// A grey jumpsuit and nothing else. No boots, no helmet, no gun.
///
/// Offered on every arena, because it is the option that makes the other ones
/// mean something: a Security Ring where both the officer in the vest and the
/// civilian in grey are worth the same number of points is an arena about not
/// having armour, which the disabler loadout is otherwise all about.
/datum/outfit/vr/deathmatch_loadout/butt_naked
	name = "Butt Naked"
	display_name = "Butt Naked"
	desc = "A grey jumpsuit and nothing else. The option that gives the other kits something to be worth."
	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/sneakers/black

/// Sniper rifle and one magazine. Sniper Elite, which is about the shot rather
/// than the trade.
/datum/outfit/vr/deathmatch_loadout/sniper
	name = "Sniper"
	display_name = "Sniper"
	desc = "A sniper rifle, one magazine and sunglasses. All about the shot."
	uniform = /obj/item/clothing/under/suit/black
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/color/black
	back = /obj/item/gun/ballistic/automatic/sniper_rifle
	l_pocket = /obj/item/ammo_box/magazine/sniper_rounds
	glasses = /obj/item/clothing/glasses/sunglasses
	accessory = list(/obj/item/clothing/accessory/waistcoat)

/// Final Destination's big leagues: one strong kit per archetype, the same set
/// of ten the mode was balanced around on the upstream, minus the two arenas'
/// own kits. These are the kits that make "1 stock, Final Destination" mean a
/// brief and honest fight.

/datum/outfit/vr/deathmatch_loadout/captain
	name = "Captain"
	display_name = "Captain"
	desc = "Draw your sword and show the syndicate scum no quarter."

	head = /obj/item/clothing/head/caphat/parade
	ears = /obj/item/radio/headset/heads/captain/alt
	uniform = /obj/item/clothing/under/rank/captain
	suit = /obj/item/clothing/suit/toggle/captains_parade
	suit_store = /obj/item/gun/energy/e_gun
	shoes = /obj/item/clothing/shoes/laceup
	neck = /obj/item/bedsheet/captain
	glasses = /obj/item/clothing/glasses/sunglasses
	gloves = /obj/item/clothing/gloves/color/captain
	belt = /obj/item/storage/belt/sabre
	l_hand = /obj/item/gun/energy/laser/captain
	r_pocket = /obj/item/assembly/flash
	l_pocket = /obj/item/melee/classic_baton/telescopic

/datum/outfit/vr/deathmatch_loadout/head_of_security
	name = "Head of Security"
	display_name = "Head of Security"
	desc = "Finally, nobody to stop the power from going to your head."

	head = /obj/item/clothing/head/HoS/beret
	ears = /obj/item/radio/headset/heads/hos
	uniform = /obj/item/clothing/under/rank/security/head_of_security/alt
	shoes = /obj/item/clothing/shoes/jackboots
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	suit = /obj/item/clothing/suit/armor/hos/trenchcoat
	suit_store = /obj/item/gun/ballistic/shotgun/automatic/combat
	gloves = /obj/item/clothing/gloves/tackler/combat
	belt = /obj/item/gun/energy/e_gun/hos
	r_hand = /obj/item/melee/baton/loaded
	l_hand = /obj/item/shield/riot/tele
	l_pocket = /obj/item/grenade/flashbang
	r_pocket = /obj/item/restraints/legcuffs/bola/energy

/datum/outfit/vr/deathmatch_loadout/traitor
	name = "Traitor"
	display_name = "Traitor"
	desc = "The classic: an energy sword and a crossbow, donning a reflector trenchcoat."

	head = /obj/item/clothing/head/chameleon
	uniform = /obj/item/clothing/under/chameleon
	mask = /obj/item/clothing/mask/chameleon
	suit = /obj/item/clothing/suit/hooded/ablative
	shoes = /obj/item/clothing/shoes/chameleon/noslip
	glasses = /obj/item/clothing/glasses/thermal/syndi
	gloves = /obj/item/clothing/gloves/combat
	suit_store = /obj/item/gun/energy/kinetic_accelerator/crossbow
	l_hand = /obj/item/melee/transforming/energy/sword/saber
	r_pocket = /obj/item/reagent_containers/hypospray/medipen/stimulants
	l_pocket = /obj/item/soap/syndie
	belt = /obj/item/gun/ballistic/revolver

/datum/outfit/vr/deathmatch_loadout/nukie
	name = "Nuclear Operative"
	display_name = "Nuclear Operative"
	desc = "Gear afforded to Lone Operatives. Your mission is simple."

	uniform = /obj/item/clothing/under/syndicate/tacticool
	back = /obj/item/mod/control/pre_equipped/nuclear
	r_hand = /obj/item/gun/ballistic/automatic/shotgun/bulldog/unrestricted
	belt = /obj/item/gun/ballistic/automatic/pistol/APS
	r_pocket = /obj/item/reagent_containers/hypospray/medipen/stimulants
	l_pocket = /obj/item/grenade/syndieminibomb
	implants = list(/obj/item/implant/explosive)

	backpack_contents = list(
		/obj/item/ammo_box/magazine/pistolm9mm = 2,
		/obj/item/ammo_box/magazine/m12g = 2,
		/obj/item/pen/edagger,
		/obj/item/reagent_containers/hypospray/medipen/atropine,
	)

/datum/outfit/vr/deathmatch_loadout/nukie/post_equip(mob/living/carbon/human/H, visuals_only = FALSE, client/preference_source)
	..()
	if(visuals_only || !H.mind)
		return
	var/obj/item/mod/control/MOD = H.back
	if(!istype(MOD))
		return
	MOD.quick_activation()

/datum/outfit/vr/deathmatch_loadout/tider
	name = "Tider"
	display_name = "Tider"
	desc = "A very high power level Assistant."

	back = /obj/item/melee/baton/cattleprod
	r_hand = /obj/item/fireaxe
	uniform = /obj/item/clothing/under/color/grey/glorf
	mask = /obj/item/clothing/mask/gas
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/cut
	l_pocket = /obj/item/reagent_containers/hypospray/medipen/stimulants
	r_pocket = /obj/item/stock_parts/cell/high
	belt = /obj/item/storage/belt/utility/full

/datum/outfit/vr/deathmatch_loadout/abductor
	name = "Abductor"
	display_name = "Abductor"
	desc = "We come in peace."

	species_override = /datum/species/abductor
	uniform = /obj/item/clothing/under/abductor
	head = /obj/item/clothing/head/helmet/abductor
	suit = /obj/item/clothing/suit/armor/abductor/vest
	l_pocket = /obj/item/reagent_containers/hypospray/medipen/atropine
	r_pocket = /obj/item/grenade/gluon
	l_hand = /obj/item/gun/energy/alien
	r_hand = /obj/item/gun/energy/alien
	belt = /obj/item/gun/energy/shrink_ray

/datum/outfit/vr/deathmatch_loadout/master_chef
	name = "Master Chef"
	display_name = "Master Chef"
	desc = "Let him cook."

	belt = /obj/item/gun/magic/hook
	uniform = /obj/item/clothing/under/rank/civilian/chef
	suit = /obj/item/clothing/suit/toggle/chef
	suit_store = /obj/item/kitchen/knife
	head = /obj/item/clothing/head/chefhat
	mask = /obj/item/clothing/mask/fakemoustache/italian
	gloves = /obj/item/clothing/gloves/the_sleeping_carp
	back = /obj/item/storage/backpack

	backpack_contents = list(
		/obj/item/pizzabox/bomb/armed = 3,
		/obj/item/kitchen/knife/butcher,
		/obj/item/sharpener,
	)

/datum/outfit/vr/deathmatch_loadout/clown_commando
	name = "Clown Commando"
	display_name = "Clown Commando"
	desc = "They were bound to show up sooner or later."

	uniform = /obj/item/clothing/under/rank/civilian/clown
	shoes = /obj/item/clothing/shoes/clown_shoes/combat
	r_hand = /obj/item/melee/transforming/energy/sword/bananium/deathmatch_sword
	l_hand = /obj/item/shield/energy/bananium
	box = /obj/item/storage/box/hug/reverse_revolver
	back = /obj/item/storage/backpack/clown

	backpack_contents = list(
		/obj/item/paperplane/syndicate = 1,
		/obj/item/restraints/legcuffs/bola/tactical = 1,
		/obj/item/restraints/legcuffs/beartrap = 1,
		/obj/item/reagent_containers/food/snacks/grown/banana = 1,
		/obj/item/reagent_containers/food/snacks/pie/cream = 1,
		/obj/item/dnainjector/clumsymut,
		/obj/item/sbeacondrop/clownbomb,
		/obj/item/pneumatic_cannon/pie/selfcharge = 1,
		/obj/item/bikehorn/golden = 1,
	)

/datum/outfit/vr/deathmatch_loadout/mime
	name = "Mime"
	display_name = "Mime"
	desc = "..."

	uniform = /obj/item/clothing/under/rank/civilian/mime
	belt = /obj/item/reagent_containers/food/snacks/baguette/combat/deathmatch
	head = /obj/item/clothing/head/beret
	shoes = /obj/item/clothing/shoes/sneakers/mime
	mask = /obj/item/clothing/mask/gas/mime
	back = /obj/item/storage/backpack/mime
	box = /obj/item/storage/box/survival
	l_pocket = /obj/item/toy/crayon/spraycan/mimecan
	r_pocket = /obj/item/reagent_containers/food/snacks/grown/banana/mime
	gloves = /obj/item/clothing/gloves/color/white

	backpack_contents = list(
		/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing,
		/obj/item/gun/ballistic/automatic/pistol,
		/obj/item/ammo_box/magazine/m10mm,
		/obj/item/suppressor,
	)

/datum/outfit/vr/deathmatch_loadout/mime/post_equip(mob/living/carbon/human/H, visuals_only = FALSE, client/preference_source)
	..()
	if(visuals_only || !H.mind)
		return
	H.mind.miming = 1
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/conjure/mime_wall(null))
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/mime/speak(null))
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/forcewall/mime(null))
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/aimed/finger_guns(null))
	H.mind.AddSpell(new /obj/effect/proc_holder/spell/targeted/touch/mimerope(null))

/datum/outfit/vr/deathmatch_loadout/pete
	name = "Disciple of Pete"
	display_name = "Disciple of Pete"
	desc = "You took a lesson from Cuban Pete."

	back = /obj/item/storage/backpack/santabag
	head = /obj/item/clothing/head/collectable/petehat
	uniform = /obj/item/clothing/under/pants/camo
	suit = /obj/item/clothing/suit/poncho
	belt = /obj/item/storage/belt/grenade/full
	shoes = /obj/item/clothing/shoes/workboots
	l_hand = /obj/item/reagent_containers/food/drinks/bottle/rum
	r_hand = /obj/item/sbeacondrop/bomb
	l_pocket = /obj/item/grenade/syndieminibomb
	r_pocket = /obj/item/grenade/syndieminibomb
	implants = list(/obj/item/implant/explosive/macro)
	backpack_contents = list(
		/obj/item/assembly/signaler = 10,
	)

/// The clown commando's sword, unfolded before anyone ever holds it: the arena
/// version of the trick is that the blade is out and slippery the moment the
/// clown spawns, not after a manual toggle nobody reads about.
/obj/item/melee/transforming/energy/sword/bananium/deathmatch_sword
	name = "bananium sword"
	desc = "An elegant weapon, for a more civilized age."

/obj/item/melee/transforming/energy/sword/bananium/deathmatch_sword/Initialize(mapload)
	. = ..()
	transform_weapon(null, TRUE)

/// The mime's baguette, already battle-ready: the arena is no place for toggling
/// swordplay behind a vow check, so it is a sword with or without a mind that
/// honours the mime's silence, and the toggle still works for anyone with an
/// obet of their own.
/obj/item/reagent_containers/food/snacks/baguette/combat/deathmatch
	name = "combat baguette"
	desc = "Deadly bread, already wielded like a sword."
	force = 20
	block_chance = 50

/obj/item/reagent_containers/food/snacks/baguette/combat/deathmatch/attack_self(mob/user, modifiers)
	if(fake_swordplay)
		end_swordplay(user)
	else
		begin_swordplay(user)

/// Gloves that teach the wearer the art of the sleeping carp. The art sticks only
/// while the gloves are on, so dropping them mid-round quietly reverts the
/// wearer to their default fighting style.
/obj/item/clothing/gloves/the_sleeping_carp
	name = "sleeping carp gloves"
	desc = "Legend says the style was invented by an angry fish. They rest on your hands now."
	icon_state = "fightgloves"
	item_state = "fightgloves"
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	var/datum/martial_art/the_sleeping_carp/style = new

/obj/item/clothing/gloves/the_sleeping_carp/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user) && slot == ITEM_SLOT_GLOVES)
		var/mob/living/carbon/human/H = user
		style.teach(H, 1)

/obj/item/clothing/gloves/the_sleeping_carp/dropped(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.get_item_by_slot(ITEM_SLOT_GLOVES) == src)
		style.remove(H)

/// A pizza bomb that is already live. No wiring, no timer prompt: throw it and it
/// detonates on impact like a grenade.
/obj/item/pizzabox/bomb/armed
	name = "armed pizza bomb"
	desc = "Special delivery! This box is already live - throw it to detonate."

/obj/item/pizzabox/bomb/armed/Initialize(mapload)
	. = ..()
	bomb_active = TRUE
	bomb_defused = FALSE

/obj/item/pizzabox/bomb/armed/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(bomb && !bomb_defused)
		bomb_timer = 0
		process()

//
// Team Deathmatch kits.
//
// /datum/deathmatch_lobby/team_deathmatch hands these out on a fixed rotation,
// one pair of kits per round: both teams get the same weapon family, but each
// side gets its own version of it. They are all tdm_only so the free-for-all
// picker does not offer one side's half of a pair.
//
// The kits assume the map is an open arena where a fight lasts a round, not a
// shift, so a kit is a weapon, what it needs to keep firing, and nothing else -
// no armour, no medkits, no backpack to rummage through.

/// The riot shotgun's internal magazine, loaded with buckshot instead of the
/// non-lethal rubber the armory version ships with. TDM has no crowd to control.
/obj/item/ammo_box/magazine/internal/shot/riot/lethal
	name = "riot shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot

/// The Counter-Terrorist shotgun: a stock riot shotgun with a lethal magazine.
/obj/item/gun/ballistic/shotgun/riot/deathmatch
	mag_type = /obj/item/ammo_box/magazine/internal/shot/riot/lethal

/// The Terrorist shotgun: the syndicate Peacebreaker, same lethal magazine.
/obj/item/gun/ballistic/shotgun/riot/syndicate/deathmatch
	mag_type = /obj/item/ammo_box/magazine/internal/shot/riot/lethal

/// A bandolier that spawns already full of buckshot.
/obj/item/storage/belt/bandolier/deathmatch
	desc = "A bandolier for holding ammunition. This one is already full of buckshot."

/obj/item/storage/belt/bandolier/deathmatch/PopulateContents()
	for(var/shell in 1 to 12)
		new /obj/item/ammo_casing/shotgun/buckshot(src)

/// An extended Enforcer magazine loaded with armour-piercing .45 ACP. The
/// codebase has a lethal extended magazine but no AP one, and the kit calls for
/// AP, so the round has to be defined here.
/obj/item/ammo_box/magazine/e45/e45_extended/ap
	name = "Extended Enforcer magazine (.45 ACP)"
	desc = "An extended Mk. 58 magazine. Loaded with armour-piercing rounds."
	ammo_type = /obj/item/ammo_casing/c45/armour

/// The Enforcer the Counter-Terrorist sidearm kit ships with: same pistol, but
/// loaded from an extended AP magazine instead of the eight-round rubber one.
/obj/item/gun/ballistic/automatic/pistol/enforcer/deathmatch
	mag_type = /obj/item/ammo_box/magazine/e45/e45_extended/ap

/// Ammo pouch for the Terrorist sidearm round: three spare Makarov magazines.
/// The pouch holds exactly three, so the whole kit is one pistol, one reload
/// band and a knife.
/obj/item/storage/bag/ammo/deathmatch_makarov
/obj/item/storage/bag/ammo/deathmatch_makarov/PopulateContents()
	for(var/magazine in 1 to 3)
		new /obj/item/ammo_box/magazine/m10mm(src)

/// Ammo pouch for the Counter-Terrorist sidearm round: three spare extended AP
/// Enforcer magazines.
/obj/item/storage/bag/ammo/deathmatch_enforcer
/obj/item/storage/bag/ammo/deathmatch_enforcer/PopulateContents()
	for(var/magazine in 1 to 3)
		new /obj/item/ammo_box/magazine/e45/e45_extended/ap(src)

/// Ammo pouch for the Desert Eagle round: two spare .50 AE magazines.
/obj/item/storage/bag/ammo/deathmatch_deagle
/obj/item/storage/bag/ammo/deathmatch_deagle/PopulateContents()
	for(var/magazine in 1 to 2)
		new /obj/item/ammo_box/magazine/m50(src)

/// The knife round's weapon.
///
/// Thirty force, an instant kill from behind, and a speed bonus that exists
/// only while the blade is actually in a hand. The speed is applied through a
/// variable movespeed modifier rather than a fixed number because "half again
/// as fast" has to stay half again as fast whatever the server's configured run
/// delay is.
/datum/movespeed_modifier/deathmatch_knife
	variable = TRUE

/obj/item/kitchen/knife/combat/deathmatch
	name = "deathmatch combat knife"
	desc = "A combat knife issued for the knife round. It kills instantly from behind, and its balance makes carrying it faster than not."
	force = 30
	throwforce = 25
	w_class = WEIGHT_CLASS_SMALL

/obj/item/kitchen/knife/combat/deathmatch/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_HANDS || !ishuman(user) || QDELETED(user))
		return
	var/mob/living/carbon/human/wielder = user
	// Recompute from the unboosted speed. A knife can pass from one hand to the
	// other, and the speed already cached includes the boost from the first hand,
	// so the old modifier has to come off before the base speed is read.
	wielder.remove_movespeed_modifier(/datum/movespeed_modifier/deathmatch_knife)
	var/base_slowdown = wielder.cached_multiplicative_slowdown
	if(base_slowdown > 0)
		wielder.add_or_update_variable_movespeed_modifier(
			/datum/movespeed_modifier/deathmatch_knife,
			multiplicative_slowdown = -base_slowdown / 3,
		)

/obj/item/kitchen/knife/combat/deathmatch/dropped(mob/user)
	. = ..()
	if(!ishuman(user) || QDELETED(user))
		return
	var/mob/living/carbon/human/wielder = user
	wielder.remove_movespeed_modifier(/datum/movespeed_modifier/deathmatch_knife)

/**
 * Whether a strike counts as a stab in the back.
 *
 * "Behind" is the same reading the backstab knives in modular_bluemoon use: the
 * victim is facing the same way the attacker is, or is already on the floor. A
 * GODMODE or TRAIT_NODEATH victim is not a backstab target - the codebase uses
 * those flags to mean "deaths do not apply here" and a knife is not an exception
 * to that.
 */
/obj/item/kitchen/knife/combat/deathmatch/proc/is_backstab(mob/living/carbon/victim, mob/living/carbon/user)
	if(!istype(victim) || !istype(user) || victim == user || victim.stat == DEAD)
		return FALSE
	if(user.lying)
		return FALSE
	if(HAS_TRAIT(victim, TRAIT_NODEATH) || (victim.status_flags & GODMODE))
		return FALSE
	return victim.lying || victim.dir == user.dir

/// A stab in the back is a kill, not a big hit. Armour is irrelevant to it the
/// same way it is to a decapitation: `adjustBruteLoss()` writes past the armour
/// check that `apply_damage()` would have run.
///
/// The explicit death() afterwards is not redundant. `adjustBruteLoss()` only
/// takes a body to `-maxHealth` health, and death happens at -100, so a species
/// squishier than a baseline human would survive its own instant kill.
/obj/item/kitchen/knife/combat/deathmatch/attack(mob/living/carbon/victim, mob/living/carbon/user)
	if(is_backstab(victim, user))
		user.visible_message(
			span_danger("[user] buries [src] in [victim]'s back!"),
			span_danger("You bury [src] in [victim]'s back!"),
		)
		playsound(victim, 'sound/weapons/bladeslice.ogg', 75, TRUE)
		victim.adjustBruteLoss(victim.maxHealth * 2)
		if(victim.stat != DEAD)
			victim.death()
		log_combat(user, victim, "backstabbed", src)
		return TRUE
	return ..()

/// The Terrorist shotgun kit: Peacebreaker, a bandolier of spare buckshot and a
/// combat knife.
/datum/outfit/vr/deathmatch_loadout/tdm_shotgun_terror
	name = "TDM Shotguns (Terrorist)"
	display_name = "Terrorist Shotguns"
	desc = "A Peacebreaker shotgun loaded with buckshot, a bandolier of spare shells and a combat knife."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/ballistic/shotgun/riot/syndicate/deathmatch
	belt = /obj/item/storage/belt/bandolier/deathmatch
	r_pocket = /obj/item/kitchen/knife/combat

/// The Counter-Terrorist shotgun kit: the stock riot shotgun, same ammunition.
/datum/outfit/vr/deathmatch_loadout/tdm_shotgun_counter
	name = "TDM Shotguns (Counter-Terrorist)"
	display_name = "Counter-Terrorist Shotguns"
	desc = "A riot shotgun loaded with buckshot, a bandolier of spare shells and a combat knife."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/ballistic/shotgun/riot/deathmatch
	belt = /obj/item/storage/belt/bandolier/deathmatch
	r_pocket = /obj/item/kitchen/knife/combat

/// The Terrorist sidearm kit: a Makarov, three spare magazines and a knife.
/datum/outfit/vr/deathmatch_loadout/tdm_pistol_terror
	name = "TDM Pistols (Terrorist)"
	display_name = "Terrorist Pistols"
	desc = "A Makarov pistol, an ammo pouch with three spare magazines and a combat knife."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/ballistic/automatic/pistol
	l_pocket = /obj/item/storage/bag/ammo/deathmatch_makarov
	r_pocket = /obj/item/kitchen/knife/combat

/// The Counter-Terrorist sidearm kit: an Enforcer with an extended AP magazine,
/// three more of the same and a knife. The round is the trade between volume
/// and penetration, so the CT half pays for its AP with a slower reload.
/datum/outfit/vr/deathmatch_loadout/tdm_pistol_counter
	name = "TDM Pistols (Counter-Terrorist)"
	display_name = "Counter-Terrorist Pistols"
	desc = "An Enforcer loaded with an extended armour-piercing magazine, three more magazines and a combat knife."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/ballistic/automatic/pistol/enforcer/deathmatch
	l_pocket = /obj/item/storage/bag/ammo/deathmatch_enforcer
	r_pocket = /obj/item/kitchen/knife/combat

/// The Desert Eagle kit. Both teams get it; a .50 hand cannon is the same
/// answer to "what beats a pistol" on either side.
/datum/outfit/vr/deathmatch_loadout/tdm_deagle
	name = "TDM Desert Eagle"
	display_name = "Desert Eagle"
	desc = "A .50 AE Desert Eagle, an ammo pouch with two spare magazines and a combat knife."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/ballistic/automatic/pistol/deagle
	l_pocket = /obj/item/storage/bag/ammo/deathmatch_deagle
	r_pocket = /obj/item/kitchen/knife/combat

/// The Terrorist sniper kit: the m40a1 and one spare magazine.
/datum/outfit/vr/deathmatch_loadout/tdm_sniper_terror
	name = "TDM Snipers (Terrorist)"
	display_name = "Terrorist Snipers"
	desc = "An m40a1 sniper rifle, one spare magazine and a combat knife. One shot, one kill, if you can place it."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/ballistic/automatic/sniper_rifle/m4oa1
	l_pocket = /obj/item/ammo_box/magazine/sniper_rounds/m4oa1
	r_pocket = /obj/item/kitchen/knife/combat

/// The Counter-Terrorist sniper kit: the standard sniper rifle and one spare
/// magazine.
/datum/outfit/vr/deathmatch_loadout/tdm_sniper_counter
	name = "TDM Snipers (Counter-Terrorist)"
	display_name = "Counter-Terrorist Snipers"
	desc = "A sniper rifle, one spare magazine and a combat knife. One shot, one kill, if you can place it."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/gun/ballistic/automatic/sniper_rifle
	l_pocket = /obj/item/ammo_box/magazine/sniper_rounds
	r_pocket = /obj/item/kitchen/knife/combat

/// The knife round. Both teams get the same blade; nothing else at all.
/datum/outfit/vr/deathmatch_loadout/tdm_knives
	name = "TDM Knives"
	display_name = "Knives"
	desc = "One knife: thirty damage, an instant kill from behind and half again the normal speed while it is in your hand. Nothing else."
	tdm_only = TRUE
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_hand = /obj/item/kitchen/knife/combat/deathmatch
