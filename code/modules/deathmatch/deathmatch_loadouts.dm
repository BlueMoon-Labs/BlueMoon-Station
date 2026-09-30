// What a deathmatch player spawns wearing and holding.
//
// Every loadout extends /datum/outfit/vr, so it inherits the dna handling, the
// id card and the bank account that the rest of the VR framework assumes, and
// nothing else from it: no sleepers, no station life.
//
// Note that this /datum/outfit has no `weapon` and no `under` var, so a melee
// weapon goes in a hand and a mask goes in `mask`.

/datum/outfit/deathmatch_loadout
	name = "Deathmatch Loadout"

/**
 * No weapon at all. Fists.
 *
 * The default, because it is the only loadout that is fair on every map without
 * the map having to be balanced around it.
 */
/datum/outfit/deathmatch_loadout/bare
	name = "Bystander"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black

/// Melee. Cheap, close range, and the only thing that works while sprinting.
/datum/outfit/deathmatch_loadout/brawler
	name = "Brawler"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/color/black
	mask = /obj/item/clothing/mask/balaclava
	l_hand = /obj/item/melee/baton

/// A sidearm. Low damage, but it does not push people out of cover.
/datum/outfit/deathmatch_loadout/sidearm
	name = "Sidearm"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	belt = /obj/item/gun/ballistic/automatic/pistol
	l_pocket = /obj/item/ammo_box/c9mm

/// Laser carbine with a self charger, so the mode never turns into a race to
/// the nearest ammo pile.
///
/// KNOWN GAP: the mode is called Instagib and promises a one shot kill. Making
/// that true needs a projectile subtype and an ammo casing to go with it, and
/// neither exists in this codebase yet, so this loadout is the honest
/// approximation: lethal, but not instakill.
/datum/outfit/deathmatch_loadout/laser
	name = "Laser"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	back = /obj/item/gun/energy/laser/carbine/deathmatch_selfcharge

/// Disabler. The Security Ring, where being shot is the point.
/datum/outfit/deathmatch_loadout/disabler
	name = "Disabler"
	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	mask = /obj/item/clothing/mask/balaclava
	back = /obj/item/gun/energy/disabler

/// A laser carbine that never runs dry, for arena modes where the round is
/// decided by positioning rather than by who found the ammo first.
/obj/item/gun/energy/laser/carbine/deathmatch_selfcharge
	name = "self-charging laser carbine"
	desc = "A laser carbine with its cell wired straight into the recharge coil. Point and click, forever."
	selfcharge = EGUN_SELFCHARGE
