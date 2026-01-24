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
	// Проверям экстракты на его свойства вместо типа как айтема
	var/slimetype = pick(GLOB.valid_slimecross)
	var/slimedata = GLOB.valid_slimecross[slimetype]
	target_colour = slimedata["colour"]
	target_effect = slimedata["effect"]

	var/colour_name = capitalize(target_colour)
	var/effect_name = capitalize(target_effect)
	name = "[colour_name] [effect_name] Slime Extr."
	description = "Nanotrasen's science lead is hunting for the rare and exotic [name]. A bounty has been offered for finding it."

	var/color_rarity = get_slimecross_rarity(slimetype)
	switch(color_rarity)
		if ("common")
			reward = 7200 + round(rand(0, 2000), 100)
		if ("rare")
			reward = 9500 + round(rand(0, 4000), 100)
		if ("highest")
			reward = 13000 + round(rand(0, 2000), 100)
		else
			reward = 5000

/datum/bounty/item/slime/crossbreeded/applies_to(obj/O)
	if(!istype(O, /obj/item/slimecross))
		return FALSE
	var/obj/item/slimecross/S = O
	if(!S.colour || !S.effect)
		return FALSE
	if(S.colour != target_colour)
		return FALSE
	if(S.effect != target_effect)
		return FALSE

	return TRUE
////////////////////////////////////////////////////////////

/// Прок для расчёта выше комбинаций экстрактов по цвету и виду.
/// 22*11 = 242, но у нас нет 242 видов скрещённых экстрактов. Прок будет это фильтровать.
/proc/get_existing_slimecross_types()
	var/static/list/blacklisted_parentals = list(
			/obj/item/slimecross,
			/obj/item/slimecross/stabilized,
			/obj/item/slimecross/selfsustaining,
			/obj/item/slimecross/charged,
			/obj/item/slimecross/burning,
			/obj/item/slimecross/chilling,
			/obj/item/slimecross/consuming,
			/obj/item/slimecross/industrial,
			/obj/item/slimecross/prismatic,
			/obj/item/slimecross/recurring,
			/obj/item/slimecross/reproductive,
			/obj/item/slimecross/regenerative,
		)
	var/list/valid_types = list()
	for (var/T in typesof(/obj/item/slimecross))
		if (T in blacklisted_parentals) // Нам не нужны в учёте родительские объекты кросс экстрактов
			continue

		var/obj/item/slimecross/slime_temporal = new T() // Мы создаём временный объект, чтобы извлечь его переменные
		if (!slime_temporal.name || !slime_temporal.effect || !slime_temporal.colour || findtext(slime_temporal.name, "slimecross"))
			qdel(slime_temporal) // Разгрузка памяти
			continue
		valid_types[T] = list( // И извлекаем эти перемнные тут
			"name" = slime_temporal.name,
			"effect" = slime_temporal.effect,
			"colour" = slime_temporal.colour
		)
		qdel(slime_temporal) // Разгрузка памяти

	return valid_types

/proc/get_slimecross_rarity(var/slimetypepath)
	var/obj/item/slimecross/slime_temporal = new slimetypepath() // аналогично выше, но теперь цвет
	var/color = slime_temporal.colour
	qdel(slime_temporal) // Разгрузка памяти
	if (color in COMMON_SLIME_COLORS)
		return "common"
	if (color in RARE_SLIME_COLORS)
		return "rare"
	if (color in HIGHEST_SLIME_COLORS)
		return "highest"
	return "unknown"

////////////////////////////////////////////////////////////
