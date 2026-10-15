/// All armors, preferable in the order as seen above
#define ARMOR_LIST_ALL(...) list(MELEE, BULLET, LASER, ENERGY, BOMB, BIO, RAD, FIRE, ACID, MAGIC, WOUND)

#define ARMOR_ALL "all_damage_types"

#define ARMORID "armor-[melee]-[bullet]-[laser]-[energy]-[bomb]-[bio]-[rad]-[fire]-[acid]-[magic]-[wound]"

#define MELEE 	"melee"
#define BULLET 	"bullet"
#define LASER 	"laser"
#define ENERGY 	"energy"
#define BOMB 	"bomb"
#define BIO 	"bio"
#define RAD 	"rad"
#define FIRE 	"fire"
#define ACID 	"acid"
#define MAGIC 	"magic"
#define WOUND 	"wound"

// BLUEMOON ADD START - BR (Bullet Rating) классы пробития для пуль.
#define BULLET_BR0   0
#define BULLET_BR1   5
#define BULLET_BR2   10
#define BULLET_BR3   15
#define BULLET_BR4   20
#define BULLET_BR5   25
#define BULLET_BR6   30
#define BULLET_BR7   35
#define BULLET_BR8   40
#define BULLET_BR9   45
#define BULLET_BR10  50
#define BULLET_BR11  55
#define BULLET_BR12  60
#define BULLET_BR13  65
#define BULLET_BR14  70
#define BULLET_BR15  75
#define BULLET_BR16  80
#define BULLET_BR17  85
#define BULLET_BR18  90
#define BULLET_BR19  95
#define BULLET_BR20  100

// BRC бонус костюмов (brc_mitigation_bonus) — общая шкала уровней // BLUEMOON ADD
#define BRC_MITIGATION_5	5
#define BRC_MITIGATION_10	10
#define BRC_MITIGATION_15	15
#define BRC_MITIGATION_20	20
#define BRC_MITIGATION_25	25

/proc/getArmor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)
	. = locate(ARMORID)
	if (!.)
		var/datum/armor/new_armor = new /datum/armor()
		new_armor.melee = melee
		new_armor.bullet = bullet
		new_armor.laser = laser
		new_armor.energy = energy
		new_armor.bomb = bomb
		new_armor.bio = bio
		new_armor.rad = rad
		new_armor.fire = fire
		new_armor.acid = acid
		new_armor.magic = magic
		new_armor.wound = wound
		new_armor.GenerateTag()
		return new_armor

/// Type aliases hold references to shared armor, interned by all eleven ratings.
GLOBAL_LIST_INIT(armor_by_type, generate_armor_type_cache())

/proc/generate_armor_type_cache()
	var/list/armor_cache = list()
	// Resolve zero-valued namespace types to the explicit unarmored profile.
	var/list/armor_types = list(/datum/armor/none)
	armor_types |= subtypesof(/datum/armor)
	for(var/datum/armor/armor_type as anything in armor_types)
		resolve_armor_profile(armor_type, armor_cache, list())
	return armor_cache

/// Resolve linked profiles before interning them, independently of declaration order.
/proc/resolve_armor_profile(datum/armor/armor_type, list/armor_cache, list/resolving)
	if(armor_cache[armor_type])
		return armor_cache[armor_type]
	if(armor_type in resolving)
		CRASH("Cyclic armor profile dependency: [armor_type]")
	resolving += armor_type
	var/datum/armor/source_type = initial(armor_type.base_armor_type)
	if(source_type)
		if(!ispath(source_type, /datum/armor))
			CRASH("Invalid base armor profile [source_type] on [armor_type]")
		var/datum/armor/source_armor = resolve_armor_profile(source_type, armor_cache, resolving)
		var/datum/armor/derived_armor = source_armor.setRating(\
			bullet = max(0, source_armor.bullet - 15),\
			laser = max(0, source_armor.laser - 15))
		armor_cache[armor_type] = derived_armor
		resolving -= armor_type
		return derived_armor
	else
		// Inspect defaults before allocation: equivalent types need no new datum.
		var/melee = initial(armor_type.melee)
		var/bullet = initial(armor_type.bullet)
		var/laser = initial(armor_type.laser)
		var/energy = initial(armor_type.energy)
		var/bomb = initial(armor_type.bomb)
		var/bio = initial(armor_type.bio)
		var/rad = initial(armor_type.rad)
		var/fire = initial(armor_type.fire)
		var/acid = initial(armor_type.acid)
		var/magic = initial(armor_type.magic)
		var/wound = initial(armor_type.wound)
		var/datum/armor/shared_armor = locate(ARMORID)
		if(!shared_armor)
			shared_armor = new armor_type
			shared_armor.GenerateTag()
		armor_cache[armor_type] = shared_armor
		resolving -= armor_type
		return shared_armor

/datum/armor/GenerateTag()
	..()
	// Named profiles and getArmor() use the same value-based cache.
	tag = ARMORID

/datum/armor
	datum_flags = DF_USE_TAG
	/// Linked hardsuit profile. MOD armor inherits it with bullet and laser reduced by 15, down to zero.
	var/base_armor_type
	var/melee = 0
	var/bullet = 0
	var/laser = 0
	var/energy = 0
	var/bomb = 0
	var/bio = 0
	var/rad = 0
	var/fire = 0
	var/acid = 0
	var/magic = 0
	var/wound = 0
	// tag = ARMORID

//Вы что конченные? Какое зануление параметров при New(). Как тогда создавать готовые датумы? Через жопу?
// /datum/armor/New(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)
// 	src.melee = melee
// 	src.bullet = bullet
// 	src.laser = laser
// 	src.energy = energy
// 	src.bomb = bomb
// 	src.bio = bio
// 	src.rad = rad
// 	src.fire = fire
// 	src.acid = acid
// 	src.magic = magic
// 	src.wound = wound
// 	tag = ARMORID

/datum/armor/proc/modifyRating(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)
  return getArmor(src.melee+melee, src.bullet+bullet, src.laser+laser, src.energy+energy, src.bomb+bomb, src.bio+bio, src.rad+rad, src.fire+fire, src.acid+acid, src.magic+magic, src.wound+wound)

/datum/armor/proc/modifyAllRatings(modifier = 0)
	return getArmor(melee+modifier, bullet+modifier, laser+modifier, energy+modifier, bomb+modifier, bio+modifier, rad+modifier, fire+modifier, acid+modifier, magic+modifier, wound+modifier)

/datum/armor/proc/setRating(melee, bullet, laser, energy, bomb, bio, rad, fire, acid, magic, wound)
	return getArmor((isnull(melee) ? src.melee : melee),\
					(isnull(bullet) ? src.bullet : bullet),\
					(isnull(laser) ? src.laser : laser),\
					(isnull(energy) ? src.energy : energy),\
					(isnull(bomb) ? src.bomb : bomb),\
					(isnull(bio) ? src.bio : bio),\
					(isnull(rad) ? src.rad : rad),\
					(isnull(fire) ? src.fire : fire),\
					(isnull(acid) ? src.acid : acid),\
				  (isnull(magic) ? src.magic : magic),\
				  (isnull(wound) ? src.wound : wound))

/datum/armor/proc/getRating(rating)
	return vars[rating]

/datum/armor/proc/getList()
	 return list(MELEE = melee, BULLET = bullet, LASER = laser, ENERGY = energy, BOMB = bomb, BIO = bio, RAD = rad, FIRE = fire, ACID = acid, MAGIC = magic, WOUND = wound)

/datum/armor/proc/attachArmor(datum/armor/AA)
	return getArmor(melee+AA.melee, bullet+AA.bullet, laser+AA.laser, energy+AA.energy, bomb+AA.bomb, bio+AA.bio, rad+AA.rad, fire+AA.fire, acid+AA.acid, magic+AA.magic, wound+AA.wound)

/datum/armor/proc/detachArmor(datum/armor/AA)
 	return getArmor(melee-AA.melee, bullet-AA.bullet, laser-AA.laser, energy-AA.energy, bomb-AA.bomb, bio-AA.bio, rad-AA.rad, fire-AA.fire, acid-AA.acid, magic-AA.magic, wound-AA.wound)

/datum/armor/proc/upgradeArmor(datum/armor/AA)
	return getArmor(max(melee,AA.melee), max(bullet,AA.bullet), max(laser,AA.laser), max(energy,AA.energy), max(bomb,AA.bomb), max(bio,AA.bio), max(rad,AA.rad), max(fire,AA.fire), max(acid,AA.acid), max(magic,AA.magic), max(wound,AA.wound))

/datum/armor/vv_edit_var(var_name, var_value)
	if (var_name == NAMEOF(src, tag))
		return FALSE
	. = ..()
	if(datum_flags & DF_USE_TAG)
		tag = ARMORID // Private copies must remain outside the shared cache.

/// Generate a brand new armor datum with the modifiers given, if ARMOR_ALL is specified only that modifier is used
/datum/armor/proc/generate_new_with_modifiers(list/modifiers)
	var/datum/armor/new_armor = new
	new_armor.tag = null
	new_armor.datum_flags &= ~DF_USE_TAG

	var/list/all_keys = ARMOR_LIST_ALL()
	if(ARMOR_ALL in modifiers)
		var/modifier_all = modifiers[ARMOR_ALL]
		for(var/mod in all_keys)
			new_armor.vars[mod] = vars[mod] + modifier_all
		new_armor.tag = null // Don't put custom armor into locate() cache
		return new_armor

	for(var/mod in all_keys)
		new_armor.vars[mod] = vars[mod]
	for(var/modifier in modifiers)
		if(modifier in all_keys)
			new_armor.vars[modifier] += modifiers[modifier]
		else
			stack_trace("Attempt to call generate_new_with_modifiers with illegal modifier '[modifier]'! Ignoring it")
	new_armor.tag = null // Don't put custom armor into locate() cache
	new_armor.datum_flags &= ~DF_USE_TAG
	return new_armor

/// Generate a brand new armor datum with the values given, if a value is not present it carries over
/datum/armor/proc/generate_new_with_specific(list/values)
	var/datum/armor/new_armor = new
	new_armor.tag = null
	new_armor.datum_flags &= ~DF_USE_TAG

	var/all_keys = ARMOR_LIST_ALL()
	if(ARMOR_ALL in values)
		var/value_all = values[ARMOR_ALL]
		for(var/mod in all_keys)
			new_armor.vars[mod] = value_all
		return new_armor

	for(var/armor_rating in all_keys)
		if(armor_rating in values)
			new_armor.vars[armor_rating] = values[armor_rating]
		else
			new_armor.vars[armor_rating] = vars[armor_rating]
	new_armor.tag = null // Don't put custom armor into locate() cache
	new_armor.datum_flags &= ~DF_USE_TAG
	return new_armor

/// Gets the rating of armor for the specified rating
/datum/armor/proc/get_rating(rating)
	// its not that I dont trust coders, its just that I don't trust coders
	if(!(rating in ARMOR_LIST_ALL()))
		CRASH("Attempted to get a rating '[rating]' that doesnt exist")
	return vars[rating]


//У меня уже жопа горит от этой тупой реализации armor. Я просто взял проки с новоТГ, потом надо будет
//сделать броню иначе.
//Реверенс Novastation: code\datums\armor\_atom_armor.dm Novastation
//                      code\datums\armor\_armor.dm

/atom
	/// Initial armor profile type path. Runtime modifiers change armor, not this.
	var/armor_type = /datum/armor/none
	/// Resolved armor datum: shared cached profile or private modified copy.
	var/datum/armor/armor

/datum/armor/none

/atom/proc/initialize_armor()
	if(isnull(armor))
		normal_set_armor(new_tg_get_armor_by_type(armor_type))
	else if(islist(armor))
		normal_set_armor(getArmor(arglist(armor)))
	else if(!istype(armor, /datum/armor))
		CRASH("Invalid armor [armor] on [type]; assign profile paths to armor_type")

/// Explicitly change the base profile and reset runtime armor to that profile.
/atom/proc/set_armor_type(new_armor_type)
	var/datum/armor/new_armor = new_tg_get_armor_by_type(new_armor_type)
	armor_type = new_armor_type
	normal_set_armor(new_armor)

/atom/proc/normal_set_armor(datum/armor/armor)
	if(!isnull(armor) && !istype(armor, /datum/armor))
		CRASH("normal_set_armor requires a datum; use set_armor_type for a profile path")
	if(src.armor == armor)
		return
	// Both type-cached profiles and getArmor() results are shared. Only a
	// private, untagged instance belongs to the atom replacing it.
	if(istype(src.armor, /datum/armor) && !src.armor.tag)
		qdel(src.armor)
	src.armor = armor

/proc/new_tg_get_armor_by_type(armor_type)
	var/datum/armor/armor = GLOB.armor_by_type[armor_type]
	if(armor)
		return armor
	if(armor_type == /datum/armor)
		CRASH("Attempted to get the base armor type, you probably meant to use /datum/armor/none")
	CRASH("Attempted to get an armor type that did not exist! '[armor_type]'")


#undef ARMORID
