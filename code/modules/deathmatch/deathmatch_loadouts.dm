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
	r_pocket = /obj/item/kitchen/knife/combat
	back = /obj/item/storage/backpack
	backpack_contents = list(
		/obj/item/kitchen/knife/combat = 4,
	)

/// A sidearm. Low damage, but it does not push people out of cover.
/datum/outfit/vr/deathmatch_loadout/sidearm
	name = "Sidearm"
	display_name = "Sidearm"
	desc = "A cheap pistol and a spare magazine. Low damage, but it will not push anyone out of cover."
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	belt = /obj/item/gun/ballistic/automatic/pistol
	l_pocket = /obj/item/ammo_box/magazine/m10mm

/// Laser carbine with a self charger, so the mode never turns into a race to
/// the nearest ammo pile.
///
/// KNOWN GAP: the mode is called Instagib and promises a one shot kill. Making
/// that true needs a projectile subtype and an ammo casing to go with it, and
/// neither exists in this codebase yet, so this loadout is the honest
/// approximation: lethal, but not instakill.
/datum/outfit/vr/deathmatch_loadout/laser
	name = "Laser"
	display_name = "Laser Carbine"
	desc = "A self-charging laser carbine, so the round never becomes a race for the nearest ammo pile."
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	back = /obj/item/gun/energy/laser/carbine/deathmatch_selfcharge

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
	l_hand = /obj/item/melee/transforming/energy/sword
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
	belt = /obj/item/melee/transforming/energy/sword/bananium
	shoes = /obj/item/clothing/shoes/clown_shoes/combat
	r_hand = /obj/item/pneumatic_cannon/pie/selfcharge
	l_hand = /obj/item/bikehorn/golden
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
	)

/datum/outfit/vr/deathmatch_loadout/mime
	name = "Mime"
	display_name = "Mime"
	desc = "..."

	uniform = /obj/item/clothing/under/rank/civilian/mime
	belt = /obj/item/reagent_containers/food/snacks/baguette/combat
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
	)

/datum/outfit/vr/deathmatch_loadout/mime/post_equip(mob/living/carbon/human/H, visuals_only = FALSE, client/preference_source)
	..()
	if(visuals_only || !H.mind)
		return
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

/// A laser carbine that never runs dry, for arena modes where the round is
/// decided by positioning rather than by who found the ammo first.
/obj/item/gun/energy/laser/carbine/deathmatch_selfcharge
	name = "self-charging laser carbine"
	desc = "A laser carbine with its cell wired straight into the recharge coil. Point and click, forever."
	selfcharge = EGUN_SELFCHARGE

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