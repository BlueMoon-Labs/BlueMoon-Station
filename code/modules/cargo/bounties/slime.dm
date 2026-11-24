/datum/bounty/item/slime
	reward = 3000
	required_count = 6

/datum/bounty/item/slime/New()
	..()
	description = "Nanotrasen's science lead is hunting for generic [name]. A bounty has been offered for finding it."
	reward += rand(2, 5) * 450

/datum/bounty/item/slime/green
	name = "Green Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/green)

/datum/bounty/item/slime/pink
	name = "Pink Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/pink)

/datum/bounty/item/slime/gold
	name = "Gold Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/gold)

/datum/bounty/item/slime/oil
	name = "Oil Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/oil)

/datum/bounty/item/slime/black
	name = "Black Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/black)

/datum/bounty/item/slime/lightpink
	name = "Light Pink Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/lightpink)

/datum/bounty/item/slime/adamantine
	name = "Adamantine Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/adamantine)

/datum/bounty/item/slime/rainbow
	name = "Rainbow Slime Extracts"
	wanted_types = list(/obj/item/slime_extract/rainbow)

////////////////////////////////////////////////////////////
GLOBAL_LIST_INIT(valid_slimecross, get_existing_slimecross_types())

/datum/bounty/item/slime/crossbreeded
	required_count = 1
	var/target_colour
	var/target_effect

/datum/bounty/item/slime/crossbreeded/New()
	..()
	set_target(pick(GLOB.valid_slimecross))

/// Заказ на скрещённый экстракт того же цвета и эффекта, что у crossbreed_type.
/datum/bounty/item/slime/crossbreeded/proc/set_target(obj/item/slimecross/crossbreed_type)
	target_colour = initial(crossbreed_type.colour)
	target_effect = initial(crossbreed_type.effect)
	name = "[capitalize(target_colour)] [capitalize(target_effect)] Slime Extr."
	description = "Научному руководству NT нужен редкий скрещённый экстракт [name]."
	if(target_effect == "self-sustaining")
		description += " Самоподдерживающийся экстракт сразу делится на четыре доли: отправьте любую."
	switch(get_slimecross_rarity(crossbreed_type))
		if("common")
			reward = 7200 + round(rand(0, 2000), 100)
		if("rare")
			reward = 9500 + round(rand(0, 4000), 100)
		if("highest")
			reward = 13000 + round(rand(0, 2000), 100)
		else
			reward = 5000

/datum/bounty/item/slime/crossbreeded/applies_to(obj/O)
	var/obj/item/autoslime/split = O
	if(istype(split))
		return target_effect == "self-sustaining" && istype(split.extract, econ_selfsustaining_extract(target_colour))
	if(!istype(O, /obj/item/slimecross))
		return FALSE
	var/obj/item/slimecross/S = O
	return S.colour == target_colour && S.effect == target_effect

/// Экстракт, который лежит в самоподдерживающихся долях скрещённого экстракта цвета colour.
/proc/econ_selfsustaining_extract(colour)
	for(var/obj/item/slimecross/selfsustaining/crossbreed_type as anything in subtypesof(/obj/item/slimecross/selfsustaining))
		if(initial(crossbreed_type.colour) == colour)
			return initial(crossbreed_type.extract_type)
////////////////////////////////////////////////////////////

/// Скрещённые экстракты, которые даёт слайм: цвет есть у слаймов, эффект - у экстрактов, и каждая пара цвета и эффекта один раз.
/// Самоподдерживающийся экстракт при создании делится на четыре, поэтому типы читаются через initial(), без экземпляров.
/proc/get_existing_slimecross_types()
	var/list/effects = list()
	for(var/obj/item/slime_extract/extract_type as anything in subtypesof(/obj/item/slime_extract))
		if(initial(extract_type.effectmod))
			effects[initial(extract_type.effectmod)] = TRUE
	var/list/valid_types = list()
	var/list/seen = list()
	for(var/obj/item/slimecross/crossbreed_type as anything in subtypesof(/obj/item/slimecross))
		var/colour = initial(crossbreed_type.colour)
		var/effect = initial(crossbreed_type.effect)
		if(!effects[effect] || !(replacetext(colour, " ", "") in SLIME_COLORS) || seen["[colour]|[effect]"])
			continue
		seen["[colour]|[effect]"] = TRUE
		valid_types[crossbreed_type] = list(
			"name" = "[effect] [colour] extract",
			"effect" = effect,
			"colour" = colour,
		)
	return valid_types

/proc/get_slimecross_rarity(obj/item/slimecross/slimetypepath)
	var/color = replacetext(initial(slimetypepath.colour), " ", "")
	if (color in COMMON_SLIME_COLORS)
		return "common"
	if (color in RARE_SLIME_COLORS)
		return "rare"
	if (color in HIGHEST_SLIME_COLORS)
		return "highest"
	return "unknown"

////////////////////////////////////////////////////////////
