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

/proc/getArmor(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)
	. = locate(ARMORID)
	if (!.)
		. = new /datum/armor(melee, bullet, laser, energy, bomb, bio, rad, fire, acid, magic, wound)

/// Assosciative list of type -> armor. Used to ensure we always hold a reference to default armor datums
GLOBAL_LIST_INIT(armor_by_type, generate_armor_type_cache())

/proc/generate_armor_type_cache()
	var/list/armor_cache = list()
	for(var/datum/armor/armor_type as anything in subtypesof(/datum/armor))
		armor_type = new armor_type
		armor_cache[armor_type.type] = armor_type
		armor_type.GenerateTag()
	return armor_cache

/datum/armor/GenerateTag()
	..()
	tag = replacetext("[type]", "/", "-")

/datum/armor
	datum_flags = DF_USE_TAG
	var/melee
	var/bullet
	var/laser
	var/energy
	var/bomb
	var/bio
	var/rad
	var/fire
	var/acid
	var/magic
	var/wound

/datum/armor/New(melee = 0, bullet = 0, laser = 0, energy = 0, bomb = 0, bio = 0, rad = 0, fire = 0, acid = 0, magic = 0, wound = 0)
	src.melee = melee
	src.bullet = bullet
	src.laser = laser
	src.energy = energy
	src.bomb = bomb
	src.bio = bio
	src.rad = rad
	src.fire = fire
	src.acid = acid
	src.magic = magic
	src.wound = wound
	tag = ARMORID

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

/datum/armor/vv_edit_var(var_name, var_value)
	if (var_name == NAMEOF(src, tag))
		return FALSE
	. = ..()
	tag = ARMORID // update tag in case armor values were edited

/// Generate a brand new armor datum with the modifiers given, if ARMOR_ALL is specified only that modifier is used
/datum/armor/proc/generate_new_with_modifiers(list/modifiers)
	var/datum/armor/new_armor = new

	var/all_keys = ARMOR_LIST_ALL()
	if(ARMOR_ALL in modifiers)
		var/modifier_all = modifiers[ARMOR_ALL]
		if(!modifier_all)
			return src
		for(var/mod in all_keys)
			new_armor.vars[mod] = vars[mod] + modifier_all
		return new_armor

	for(var/modifier in modifiers)
		if(modifier in all_keys)
			new_armor.vars[modifier] = vars[modifier] + modifiers[modifier]
		else
			stack_trace("Attempt to call generate_new_with_modifiers with illegal modifier '[modifier]'! Ignoring it")
	new_armor.tag = null // Don't put custom armor into locate() cache
	return new_armor

/// Generate a brand new armor datum with the values given, if a value is not present it carries over
/datum/armor/proc/generate_new_with_specific(list/values)
	var/datum/armor/new_armor = new

	var/all_keys = ARMOR_LIST_ALL()
	if(ARMOR_ALL in values)
		var/value_all = values[ARMOR_ALL]
		if(!value_all)
			return src
		for(var/mod in all_keys)
			new_armor.vars[mod] = value_all
		return new_armor

	for(var/armor_rating in all_keys)
		if(armor_rating in values)
			new_armor.vars[armor_rating] = values[armor_rating]
		else
			new_armor.vars[armor_rating] = vars[armor_rating]
	new_armor.tag = null // Don't put custom armor into locate() cache
	return new_armor

/// Gets the rating of armor for the specified rating
/datum/armor/proc/get_rating(rating)
	// its not that I dont trust coders, its just that I don't trust coders
	if(!(rating in ARMOR_LIST_ALL()))
		CRASH("Attempted to get a rating '[rating]' that doesnt exist")
	return vars[rating]

#undef ARMORID
