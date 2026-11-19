/// Заказы, которые попадают на доску: пул отделов и особые стартовые заказы ЦК.
/proc/econ_test_board_bounty_types()
	. = GLOB.econ_roundstart_special_bounties.Copy()
	var/list/by_department = econ_bounty_types_by_department()
	for(var/department_id in by_department)
		. |= by_department[department_id]

/// Варианты, из которых New() выбирает заказ: аудит проходит по каждому.
/datum/bounty/proc/econ_test_variants()
	return list(null)

/datum/bounty/proc/econ_test_use_variant(variant)
	return

/// Предметы, которыми игрок закрыл бы заказ целиком; obtainable подсказывает, что из принимаемого добывается на станции.
/datum/bounty/proc/econ_test_sample(turf/where, datum/econ_test_obtainable/obtainable)
	return list()

/// Добывается ли на станции то, что принимает заказ. Возвращает пояснение, если нет.
/datum/bounty/proc/econ_test_unobtainable(datum/econ_test_obtainable/obtainable)
	return "аудит не знает, как проверить заказ [type]"

/datum/bounty/item/proc/econ_test_accepted_types()
	. = list()
	for(var/accepted in wanted_types)
		if(!ispath(accepted, /atom/movable))
			continue
		if(include_subtypes && is_type_in_typecache(accepted, exclude_types))
			continue
		. += accepted

/datum/bounty/item/proc/econ_test_pick_type(datum/econ_test_obtainable/obtainable)
	var/list/accepted = econ_test_accepted_types()
	for(var/accepted_type in accepted)
		if(obtainable?.items[accepted_type])
			return accepted_type
	return length(accepted) ? accepted[1] : null

/// Доводит созданный предмет до того, что просит заказ: газ в баллон, огонь в костёр.
/datum/bounty/item/proc/econ_test_prepare(atom/movable/thing)
	return

/datum/bounty/item/econ_test_sample(turf/where, datum/econ_test_obtainable/obtainable)
	. = list()
	var/accepted = econ_test_pick_type(obtainable)
	if(!accepted)
		return
	var/left = required_count
	while(left > 0)
		var/atom/movable/thing
		if(ispath(accepted, /obj/item/stack))
			var/obj/item/stack/stack_type = accepted
			thing = new accepted(where, min(left, initial(stack_type.max_amount)), FALSE)
			var/obj/item/stack/stack = thing
			left -= stack.amount
		else
			thing = new accepted(where)
			left--
		econ_test_prepare(thing)
		. += thing

/datum/bounty/item/econ_test_unobtainable(datum/econ_test_obtainable/obtainable)
	var/list/accepted = econ_test_accepted_types()
	if(!length(accepted))
		return "не принимает ни одного предмета: [jointext(wanted_types, ", ")]"
	for(var/accepted_type in accepted)
		if(obtainable.items[accepted_type])
			return null
	return "ничего из принимаемого не добыть на станции без покупки: [jointext(accepted.Copy(1, min(length(accepted), 6) + 1), ", ")][obtainable.missing_for(accepted)]"

/datum/bounty/item/engineering/gas/econ_test_prepare(obj/item/tank/tank)
	tank.air_contents.set_moles(gas_type, moles_required)

/datum/bounty/item/assistant/condom/econ_test_prepare(obj/item/genital_equipment/condom/condom)
	condom.reagents.add_reagent(/datum/reagent/consumable/semen, 20)

/datum/bounty/item/botany/bonfire/econ_test_prepare(obj/structure/bonfire/bonfire)
	bonfire.StartBurning()

/datum/bounty/item/roboticist/endoskeleton/econ_test_prepare(obj/item/robot_suit/frame)
	frame.l_arm = new(frame)
	frame.r_arm = new(frame)
	frame.l_leg = new(frame)
	frame.r_leg = new(frame)
	frame.chest = new(frame)
	frame.head = new(frame)

/datum/bounty/item/slime/crossbreeded/econ_test_variants()
	. = list()
	for(var/crossbreed_type in GLOB.valid_slimecross)
		. += crossbreed_type

/datum/bounty/item/slime/crossbreeded/econ_test_use_variant(variant)
	set_target(variant)

/// Скрещённый экстракт, который выдаст слайм: первый тип с такими цветом и эффектом.
/datum/bounty/item/slime/crossbreeded/proc/econ_test_crossbreed_type()
	for(var/obj/item/slimecross/crossbreed_type as anything in subtypesof(/obj/item/slimecross))
		if(initial(crossbreed_type.colour) == target_colour && initial(crossbreed_type.effect) == target_effect)
			return crossbreed_type

/// Самоподдерживающийся экстракт при создании делится на доли: образец - всё, что появилось на турфе.
/datum/bounty/item/slime/crossbreeded/econ_test_sample(turf/where, datum/econ_test_obtainable/obtainable)
	var/crossbreed_type = econ_test_crossbreed_type()
	if(!crossbreed_type)
		return list()
	var/list/before = where.contents.Copy()
	new crossbreed_type(where)
	return where.contents - before

/datum/bounty/item/slime/crossbreeded/econ_test_unobtainable(datum/econ_test_obtainable/obtainable)
	var/obj/item/slimecross/crossbreed_type = econ_test_crossbreed_type()
	if(!crossbreed_type)
		return "нет скрещённого экстракта [target_colour] [target_effect]"
	if(!(replacetext(target_colour, " ", "") in SLIME_COLORS))
		return "нет слайма цвета [target_colour]"
	for(var/obj/item/slime_extract/extract_type as anything in subtypesof(/obj/item/slime_extract))
		if(initial(extract_type.effectmod) == target_effect && obtainable.inputs[extract_type])
			return null
	return "нет экстракта с эффектом [target_effect]"

/datum/bounty/reagent/proc/econ_test_reagent_type()
	return ispath(wanted_reagent) ? wanted_reagent : wanted_reagent.type

/datum/bounty/reagent/econ_test_variants()
	return possible_reagents() || list(null)

/datum/bounty/reagent/econ_test_use_variant(variant)
	if(variant)
		wanted_reagent = new variant
		name = wanted_reagent.name

/datum/bounty/reagent/econ_test_sample(turf/where, datum/econ_test_obtainable/obtainable)
	. = list()
	var/left = required_volume
	while(left > 0)
		var/obj/item/reagent_containers/glass/beaker/noreact/beaker = new(where)
		var/amount = min(left, beaker.volume)
		beaker.reagents.add_reagent(econ_test_reagent_type(), amount)
		left -= amount
		. += beaker

/datum/bounty/reagent/econ_test_unobtainable(datum/econ_test_obtainable/obtainable)
	var/reagent_type = econ_test_reagent_type()
	return obtainable.reagents[reagent_type] ? null : "реагент [reagent_type] не добыть на станции"

/datum/bounty/virus/econ_test_variants()
	. = list()
	for(var/value in 4 to 11)
		. += value
		. += -value

/datum/bounty/virus/econ_test_use_variant(variant)
	stat_value = variant

/// Переменная симптома, которую суммирует заказ.
/datum/bounty/virus/proc/econ_test_symptom_var()
	return null

/datum/bounty/virus/resistance/econ_test_symptom_var()
	return "resistance"

/datum/bounty/virus/stage_speed/econ_test_symptom_var()
	return "stage_speed"

/datum/bounty/virus/stealth/econ_test_symptom_var()
	return "stealth"

/datum/bounty/virus/transmit/econ_test_symptom_var()
	return "transmittable"

/datum/bounty/virus/econ_test_sample(turf/where, datum/econ_test_obtainable/obtainable)
	. = list()
	var/list/combo = obtainable.symptom_combo(econ_test_symptom_var(), stat_value)
	if(!combo)
		return
	var/datum/disease/advance/disease = new
	for(var/symptom_type in combo)
		disease.symptoms += new symptom_type
	disease.Refresh()
	var/obj/item/reagent_containers/glass/beaker/noreact/beaker = new(where)
	beaker.reagents.add_reagent(/datum/reagent/blood, 10, list("viruses" = list(disease), "blood_type" = "O-"))
	qdel(disease)
	. += beaker

/datum/bounty/virus/econ_test_unobtainable(datum/econ_test_obtainable/obtainable)
	if(!econ_test_symptom_var())
		return "аудит не знает, какой показатель вируса ищет [type]"
	if(!obtainable.symptom_combo(econ_test_symptom_var(), stat_value))
		return "вирус с [stat_name] [stat_value] не собрать из получаемых симптомов (до [VIRUS_SYMPTOM_LIMIT])"

/// То, что экипаж добывает способом, которого сборщик не видит: тип -> как добыть.
GLOBAL_LIST_INIT(econ_test_obtained_otherwise, list(
	/obj/item/documents/syndicate = "документы в руинах Синдиката на Лаваленде, Айсмуне и в космосе",
	/obj/singularity/energy_ball = "тесла-генератор из снабжения под ускорителем частиц",
	/obj/item/gun/ballistic/shotgun/riot = "оружейная СБ на станции",
	/obj/item/stack/license_plates/filled = "пресс номерных знаков в тюрьме",
	/obj/item/soap/homemade = "реакция мыла в химии",
	/obj/item/paperplane = "сложить лист бумаги",
	/obj/item/storage/box/clown = "штамп клоуна на картоне",
	/obj/item/reagent_containers/food/snacks/icecream = "автомат мороженого на кухне",
	/obj/item/reagent_containers/food/snacks/deadmouse = "мышь из техтоннелей",
	/obj/item/pipe = "раздатчик труб и RPD",
))

/// Реагенты не из реакций, раздатчиков, растений и измельчителя: тип -> как добыть.
GLOBAL_LIST_INIT(econ_test_reagents_otherwise, list(
	/datum/reagent/water = "краны и раковины",
	/datum/reagent/blood = "кровь экипажа и доноров",
))

/// Превращения, которые предмет сам задаёт в Initialize или реакции на огонь: что -> во что и чем.
GLOBAL_LIST_INIT(econ_test_handmade, list(
	list(/obj/item/reagent_containers/food/snacks/dough, /obj/item/reagent_containers/food/snacks/flatdough, "раскатать тесто скалкой"),
	list(/obj/item/reagent_containers/food/snacks/cakebatter, /obj/item/reagent_containers/food/snacks/piedough, "раскатать тесто для торта скалкой"),
	list(/obj/item/reagent_containers/food/snacks/meat/slab/goliath, /obj/item/reagent_containers/food/snacks/meat/steak/goliath, "мясо голиафа в огне или лаве"),
))

/// Звери станции и Лаваленда, которых разделывают: их туши и шкуры добываются.
GLOBAL_LIST_INIT(econ_test_butchered_mobs, list(
	/mob/living/carbon/monkey = "мартышка",
	/mob/living/simple_animal/pet/dog/corgi = "корги",
	/mob/living/simple_animal/cow = "корова",
	/mob/living/simple_animal/chicken = "курица",
	/mob/living/simple_animal/hostile/asteroid/goliath/beast = "голиаф с Лаваленда",
	/mob/living/simple_animal/hostile/asteroid/basilisk/watcher = "наблюдатель с Лаваленда",
))

/// Что экипаж добывает сам. Купленное в автоматах и через снабжение контракт не засчитывает, но оно годится в дело: из него крафтят, его режут и растят.
/datum/econ_test_obtainable
	/// Тип предмета, который можно отправить по контракту -> откуда он берётся
	var/list/items = list()
	/// Тип, который есть в руках у экипажа, купленный тоже -> откуда
	var/list/inputs = list()
	/// Тип -> TRUE, если в руках есть он сам или его подтип: рецепты ищут ингредиент по istype
	var/list/input_kinds = list()
	/// Тип реагента -> откуда
	var/list/reagents = list()
	/// Семена, которые можно посадить: из автомата, снабжения и мутаций тоже, ведь урожай уже не покупка
	var/list/plantable = list()
	var/list/seed_instances = list()
	/// Предметы, уже разобранные на реагенты и содержимое
	var/list/examined = list()
	/// Показатель симптома -> "число симптомов:сумма" -> типы симптомов
	var/list/symptom_sums = list()
	var/list/stack_recipes
	var/list/reactions
	/// Где создавать разбираемые предметы: часть из них при создании смотрит на то, где лежит
	var/turf/examine_spot

/datum/econ_test_obtainable/New(mob/living/carbon/human/body)
	. = ..()
	examine_spot = get_turf(body)
	collect_designs()
	collect_starting_gear()
	collect_loot()
	collect_body(body)
	collect_mining()
	collect_slimes()
	collect_butchering()
	for(var/item_type in GLOB.econ_test_obtained_otherwise)
		add_item(item_type, GLOB.econ_test_obtained_otherwise[item_type])
	for(var/reagent_type in GLOB.econ_test_reagents_otherwise)
		add_reagent(reagent_type, GLOB.econ_test_reagents_otherwise[reagent_type])
	collect_dispensers()
	collect_purchases()
	var/changed = TRUE
	while(changed)
		changed = collect_plants()
		changed = collect_contents() || changed
		changed = collect_reactions() || changed
		changed = collect_recipes() || changed
		changed = collect_transforms() || changed

/datum/econ_test_obtainable/Destroy()
	QDEL_LIST_ASSOC_VAL(seed_instances)
	return ..()

/datum/econ_test_obtainable/proc/add_item(item_type, source)
	add_input(item_type, source)
	if(!ispath(item_type, /atom/movable) || items[item_type])
		return FALSE
	items[item_type] = source
	return TRUE

/datum/econ_test_obtainable/proc/add_input(item_type, source)
	if(!ispath(item_type, /atom/movable) || inputs[item_type])
		return FALSE
	inputs[item_type] = source
	for(var/kind = item_type; kind && !input_kinds[kind]; kind = type2parent(kind))
		input_kinds[kind] = TRUE
	if(ispath(item_type, /obj/item/seeds))
		plant(item_type)
	return TRUE

/datum/econ_test_obtainable/proc/add_reagent(reagent_type, source)
	if(!ispath(reagent_type, /datum/reagent) || reagents[reagent_type])
		return FALSE
	reagents[reagent_type] = source
	return TRUE

/// Печатное: предмет фабрикатора и реагенты биогенератора. Напечатанные ящики открывает collect_contents().
/datum/econ_test_obtainable/proc/collect_designs()
	var/list/researchable = list()
	for(var/node_id in SSresearch.techweb_nodes)
		var/datum/techweb_node/node = SSresearch.techweb_nodes[node_id]
		for(var/design_id in node.design_ids)
			researchable[design_id] = TRUE
	var/without_research = AUTOLATHE | TOYLATHE | BIOGENERATOR | LIMBGROWER | SMELTER | AUTOBOTTLER
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/design = SSresearch.techweb_designs[design_id]
		if(!researchable[design_id] && !(design.build_type & without_research))
			continue
		for(var/reagent_type in design.make_reagents)
			add_reagent(reagent_type, "фабрикатор: [design.name]")
		add_item(design.build_path, "фабрикатор: [design.name]")

/datum/econ_test_obtainable/proc/collect_starting_gear()
	for(var/datum/job/job as anything in SSjob.occupations)
		if(job.faction != "Station")
			continue
		var/list/found = list()
		for(var/outfit_type in list(job.outfit, job.plasma_outfit))
			if(ispath(outfit_type, /datum/outfit))
				econ_note_outfit_items(outfit_type, found)
		for(var/item_type in found)
			add_item(item_type, "снаряжение должности [job.title]")
	for(var/datum/gear/gear_type as anything in subtypesof(/datum/gear))
		if(initial(gear_type.path) && !initial(gear_type.donator_group_id) && !initial(gear_type.geargroupID))
			add_item(initial(gear_type.path), "лоадаут: [initial(gear_type.name)]")

/datum/econ_test_obtainable/proc/collect_loot()
	for(var/item_type in GLOB.arcade_prize_pool)
		add_item(item_type, "приз аркады")
	var/list/found = list()
	for(var/entry in GLOB.maintenance_loot)
		if(ispath(entry, /obj/effect/spawner/lootdrop))
			econ_note_loot_items(entry, found)
		else
			found[entry] = TRUE
	for(var/item_type in found)
		add_item(item_type, "лут техтоннелей")

/// Органы и части тела экипажа: из тела человека и мутантные органы рас.
/datum/econ_test_obtainable/proc/collect_body(mob/living/carbon/human/body)
	for(var/obj/item/organ/organ as anything in body.internal_organs)
		add_item(organ.type, "тело члена экипажа")
	for(var/obj/item/bodypart/part as anything in body.bodyparts)
		add_item(part.type, "тело члена экипажа")
	for(var/species_id in GLOB.roundstart_races)
		var/datum/species/species_type = GLOB.species_list[species_id]
		if(!species_type)
			continue
		for(var/organ_type in list(initial(species_type.mutant_brain), initial(species_type.mutant_heart), initial(species_type.mutantlungs), initial(species_type.mutanteyes), initial(species_type.mutantears), initial(species_type.mutanttongue), initial(species_type.mutantliver), initial(species_type.mutantstomach), initial(species_type.mutantappendix), initial(species_type.mutanttail)))
			add_item(organ_type, "тело расы [species_id]")
		var/datum/species/species = GLOB.species_datums[species_id]
		for(var/organ_type in species?.mutant_organs)
			add_item(organ_type, "тело расы [species_id]")

/// Руда со стен астероида и шахт и то, во что её переплавляет ORM.
/datum/econ_test_obtainable/proc/collect_mining()
	for(var/turf/closed/mineral/rock as anything in typesof(/turf/closed/mineral))
		var/obj/item/stack/ore/ore_type = initial(rock.mineralType)
		if(!ore_type)
			continue
		add_item(ore_type, "добыча руды")
		add_item(initial(ore_type.refined_type), "переплавка руды")

/datum/econ_test_obtainable/proc/collect_slimes()
	for(var/colour in SLIME_COLORS)
		add_item(text2path("/obj/item/slime_extract/[colour]"), "ксенобиология: [colour] слайм")

/datum/econ_test_obtainable/proc/collect_butchering()
	for(var/mob_type in GLOB.econ_test_butchered_mobs)
		var/mob/living/animal = new mob_type(examine_spot)
		for(var/list/results in list(animal.butcher_results, animal.guaranteed_butcher_results))
			for(var/item_type in results)
				add_item(item_type, "разделка: [GLOB.econ_test_butchered_mobs[mob_type]]")
		qdel(animal)

/datum/econ_test_obtainable/proc/collect_dispensers()
	var/list/dispenser_types = list(/obj/machinery/chem_dispenser, /obj/machinery/chem_dispenser/drinks, /obj/machinery/chem_dispenser/drinks/beer, /obj/machinery/chem_dispenser/mutagen, /obj/machinery/chem_dispenser/mutagensaltpeter)
	for(var/dispenser_type in dispenser_types)
		var/obj/machinery/chem_dispenser/dispenser = new dispenser_type(null)
		for(var/list/offered in list(dispenser.dispensable_reagents, dispenser.upgrade_reagents, dispenser.upgrade_reagents2, dispenser.upgrade_reagents3, dispenser.upgrade_reagents4))
			for(var/reagent_type in offered)
				add_reagent(reagent_type, "раздатчик [dispenser.name]")
		qdel(dispenser)

/// Купленное в автоматах станции и через снабжение: само по контракту не идёт, но годится в дело.
/datum/econ_test_obtainable/proc/collect_purchases()
	for(var/item_type in collect_vending_product_types(GLOB.econ_contraband_offstation_vendors, ACCESS_SYNDICATE))
		add_input(item_type, "автомат")
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(length(pack.exclusive_consoles))
			continue
		for(var/item_type in pack.contains)
			add_input(item_type, "снабжение: [pack.name]")

/datum/econ_test_obtainable/proc/plant(seed_type)
	if(!ispath(seed_type, /obj/item/seeds) || plantable[seed_type])
		return FALSE
	plantable[seed_type] = TRUE
	return TRUE

/datum/econ_test_obtainable/proc/seed(seed_type)
	if(!seed_instances[seed_type])
		seed_instances[seed_type] = new seed_type(null)
	return seed_instances[seed_type]

/// Урожай посаженного, мутации и реагенты растений.
/datum/econ_test_obtainable/proc/collect_plants()
	. = FALSE
	for(var/seed_type in plantable.Copy())
		var/obj/item/seeds/plant_seed = seed(seed_type)
		if(add_item(plant_seed.product, "урожай: [plant_seed.plantname]"))
			. = TRUE
		for(var/mutation in plant_seed.mutatelist)
			if(plant(mutation))
				. = TRUE
		for(var/reagent_type in plant_seed.reagents_add)
			if(add_reagent(reagent_type, "растение: [plant_seed.plantname]"))
				. = TRUE

/// Что лежит внутри коробок и ящиков и какие реагенты дают тара, еда и измельчитель.
/datum/econ_test_obtainable/proc/collect_contents()
	. = FALSE
	var/static/list/examined_kinds = list(/obj/item/storage, /obj/structure/closet, /obj/item/stack, /obj/item/reagent_containers, /obj/item/toy/crayon, /obj/item/slime_extract, /obj/item/grown)
	for(var/item_type in inputs.Copy())
		if(examined[item_type])
			continue
		examined[item_type] = TRUE
		var/kind_matched = FALSE
		for(var/kind in examined_kinds)
			if(ispath(item_type, kind))
				kind_matched = TRUE
				break
		if(!kind_matched || ispath(item_type, /obj/item/reagent_containers/food/snacks/grown))
			continue
		var/obj/item/thing = new item_type(examine_spot)
		var/shippable = items[item_type]
		for(var/atom/movable/packed as anything in thing.GetAllContents() - thing)
			if(shippable ? add_item(packed.type, "внутри [thing.name]") : add_input(packed.type, "внутри [thing.name]"))
				. = TRUE
		var/list/found_reagents = list()
		for(var/datum/reagent/reagent as anything in thing.reagents?.reagent_list)
			found_reagents += reagent.type
		if(isitem(thing))
			found_reagents += thing.grind_results
			found_reagents += thing.juice_results
		for(var/reagent_type in found_reagents)
			if(add_reagent(reagent_type, "из [thing.name]"))
				. = TRUE
		qdel(thing)

/// Реакции, чьи реагенты и катализаторы уже добываются.
/datum/econ_test_obtainable/proc/collect_reactions()
	. = FALSE
	if(!reactions)
		reactions = list()
		for(var/reagent_type in GLOB.chemical_reactions_list)
			reactions |= GLOB.chemical_reactions_list[reagent_type]
	for(var/datum/chemical_reaction/reaction as anything in reactions)
		if(!has_reagents(reaction.required_reagents) || !has_reagents(reaction.required_catalysts))
			continue
		if(reaction.required_container && !input_kinds[reaction.required_container])
			continue
		for(var/reagent_type in reaction.results)
			if(add_reagent(reagent_type, "реакция [reaction.name]"))
				. = TRUE
		var/datum/chemical_reaction/food/food_reaction = reaction
		if(istype(food_reaction) && add_item(food_reaction.resulting_food_path, "реакция [reaction.name]"))
			. = TRUE
	if(reagents[/datum/reagent/consumable/eggyolk] && add_reagent(/datum/reagent/consumable/mayonnaise, "измельчитель: смешать желтки"))
		. = TRUE
	if(reagents[/datum/reagent/consumable/milk] && add_item(/obj/item/reagent_containers/food/snacks/butter, "измельчитель: сбить молоко"))
		. = TRUE

/// Чего не хватает рецептам, которые сделали бы что-то из wanted: подсказка в сообщении теста.
/datum/econ_test_obtainable/proc/missing_for(list/wanted)
	. = list()
	for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
		if(!(recipe.result in wanted))
			continue
		var/list/missing = list()
		for(var/requirement in recipe.reqs)
			if(ispath(requirement, /datum/reagent) ? !reagents[requirement] : !input_kinds[requirement])
				missing += requirement
		. += "рецепту [recipe.name] не хватает [jointext(missing, ", ")]"
	return length(.) ? "; [jointext(., "; ")]" : ""

/datum/econ_test_obtainable/proc/has_reagents(list/required)
	for(var/reagent_type in required)
		if(!reagents[reagent_type])
			return FALSE
	return TRUE

/// Крафт на столе, рецепты стопок и рецепты из материалов.
/datum/econ_test_obtainable/proc/collect_recipes()
	. = FALSE
	for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
		if(!recipe.result || items[recipe.result])
			continue
		var/ready = TRUE
		for(var/requirement in recipe.reqs)
			if(ispath(requirement, /datum/reagent) ? !reagents[requirement] : !input_kinds[requirement])
				ready = FALSE
				break
		if(ready && add_item(recipe.result, "крафт: [recipe.name]"))
			. = TRUE
	if(isnull(stack_recipes))
		stack_recipes = list()
		var/list/recipe_lists = list(SSmaterials.base_stack_recipes, SSmaterials.rigid_stack_recipes)
		for(var/var_name in GLOB.vars)
			var/list/candidate = GLOB.vars[var_name]
			if(islist(candidate) && length(candidate) && (istype(candidate[1], /datum/stack_recipe) || istype(candidate[1], /datum/stack_recipe_list)))
				recipe_lists += list(candidate)
		for(var/list/recipe_list as anything in recipe_lists)
			for(var/entry in recipe_list)
				var/datum/stack_recipe_list/sublist = entry
				if(istype(sublist))
					stack_recipes += sublist.recipes
				else if(istype(entry, /datum/stack_recipe))
					stack_recipes += entry
		for(var/datum/stack_recipe/stack_recipe in stack_recipes)
			if(add_item(stack_recipe.result_type, "из стопки: [stack_recipe.title]"))
				. = TRUE

/// Нарезка, готовка, объедки, доски из брёвен, семена из урожая, своя плата - в машину, своё шасси - в меха, кухонный процессор, флора Лаваленда.
/datum/econ_test_obtainable/proc/collect_transforms()
	. = FALSE
	for(var/item_type in inputs.Copy())
		if(ispath(item_type, /obj/item/reagent_containers/food/snacks))
			var/obj/item/reagent_containers/food/snacks/snack = item_type
			for(var/result in list(initial(snack.slice_path), initial(snack.cooked_type), initial(snack.trash)))
				if(add_item(result, "из [initial(snack.name)]"))
					. = TRUE
		if(ispath(item_type, /obj/item/reagent_containers/food/snacks/grown))
			var/obj/item/reagent_containers/food/snacks/grown/produce = item_type
			if(add_item(initial(produce.seed), "экстрактор семян"))
				. = TRUE
		if(ispath(item_type, /obj/item/grown))
			var/obj/item/grown/produce = item_type
			if(add_item(initial(produce.seed), "экстрактор семян"))
				. = TRUE
		if(ispath(item_type, /obj/item/grown/log))
			var/obj/item/grown/log/log = item_type
			if(add_item(initial(log.plank_type), "доски из брёвен"))
				. = TRUE
	for(var/item_type in items.Copy())
		if(ispath(item_type, /obj/item/circuitboard))
			var/obj/item/circuitboard/board = item_type
			if(add_item(initial(board.build_path), "сборка по плате [initial(board.name)]"))
				. = TRUE
		if(ispath(item_type, /obj/item/mecha_parts/chassis))
			var/obj/item/mecha_parts/chassis/chassis = item_type
			var/datum/component/construction/unordered/frame = initial(chassis.construct_type)
			var/datum/component/construction/assembly = frame && initial(frame.result)
			if(assembly && add_item(initial(assembly.result), "сборка меха из [initial(chassis.name)]"))
				. = TRUE
	for(var/list/handmade as anything in GLOB.econ_test_handmade)
		if(input_kinds[handmade[1]] && add_item(handmade[2], handmade[3]))
			. = TRUE
	for(var/datum/food_processor_process/processing as anything in subtypesof(/datum/food_processor_process))
		if(input_kinds[initial(processing.input)] && add_item(initial(processing.output), "кухонный процессор"))
			. = TRUE
	for(var/obj/structure/flora/ash/flora as anything in typesof(/obj/structure/flora/ash))
		if(add_item(initial(flora.harvest), "флора Лаваленда"))
			. = TRUE
	for(var/obj/effect/anomaly/anomaly as anything in subtypesof(/obj/effect/anomaly))
		if(add_item(initial(anomaly.aSignal), "ядро нейтрализованной аномалии"))
			. = TRUE
	for(var/obj/item/slimecross/industrial/crossbreed as anything in subtypesof(/obj/item/slimecross/industrial))
		if(add_item(initial(crossbreed.itempath), "промышленный экстракт: [initial(crossbreed.colour)]"))
			. = TRUE

/// Симптомы, которые дают мутации вируса реакциями: тип -> экземпляр.
/datum/econ_test_obtainable/proc/obtainable_symptoms()
	var/list/levels = list()
	for(var/datum/chemical_reaction/mix_virus/mix in reactions)
		if(has_reagents(mix.required_reagents) && has_reagents(mix.required_catalysts))
			levels += list(list(mix.level_min, mix.level_max))
	. = list()
	for(var/symptom_type in subtypesof(/datum/symptom))
		var/datum/symptom/symptom = new symptom_type
		for(var/list/range as anything in levels)
			if(symptom.naturally_occuring && symptom.level >= range[1] && symptom.level <= range[2])
				.[symptom_type] = symptom
				break
		if(!.[symptom_type])
			qdel(symptom)

/// Набор разных симптомов (не больше VIRUS_SYMPTOM_LIMIT), чей показатель stat_var в сумме равен value, или null.
/datum/econ_test_obtainable/proc/symptom_combo(stat_var, value)
	if(!stat_var)
		return null
	var/list/sums = symptom_sums[stat_var]
	if(!sums)
		sums = list("0:0" = list())
		var/list/symptoms = obtainable_symptoms()
		for(var/symptom_type in symptoms)
			var/datum/symptom/symptom = symptoms[symptom_type]
			var/delta = symptom.vars[stat_var]
			for(var/key in sums.Copy())
				var/list/combo = sums[key]
				if(length(combo) >= VIRUS_SYMPTOM_LIMIT)
					continue
				var/next_key = "[length(combo) + 1]:[text2num(copytext(key, findtext(key, ":") + 1)) + delta]"
				if(!sums[next_key])
					sums[next_key] = combo + symptom_type
		QDEL_LIST_ASSOC_VAL(symptoms)
		symptom_sums[stat_var] = sums
	for(var/count in 1 to VIRUS_SYMPTOM_LIMIT)
		if(sums["[count]:[value]"])
			return sums["[count]:[value]"]
	return null

/// Каждый вариант каждого заказа доски можно добыть на станции без покупки.
/datum/unit_test/economy_contracts_obtainable/Run()
	var/datum/econ_test_obtainable/obtainable = new(allocate(/mob/living/carbon/human))
	for(var/bounty_type in econ_test_board_bounty_types())
		var/datum/bounty/bounty = new bounty_type
		for(var/variant in bounty.econ_test_variants())
			bounty.econ_test_use_variant(variant)
			var/problem = bounty.econ_test_unobtainable(obtainable)
			if(problem)
				TEST_FAIL("[bounty_type] ([bounty.name][variant ? ", [variant]" : ""]): [problem]")
		qdel(bounty)
	qdel(obtainable)

/datum/unit_test/economy_contracts_deliverable
	var/list/stashed_contracts
	var/list/saved_market
	var/list/contract_moves = list()
	var/saved_repeat_limit

/// Один курьер сдаёт все варианты каждого заказа: лимит повторов на человека здесь не проверяется.
/datum/unit_test/economy_contracts_deliverable/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	saved_market = econ_test_swap_market()
	saved_repeat_limit = SSeconomy.settings.contract_repeat_per_person
	SSeconomy.settings.contract_repeat_per_person = 0

/datum/unit_test/economy_contracts_deliverable/Destroy()
	SSeconomy.settings.contract_repeat_per_person = saved_repeat_limit
	econ_test_restore_contracts(stashed_contracts)
	econ_test_restore_market(saved_market)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	return ..()

/datum/unit_test/economy_contracts_deliverable/proc/on_moved(datum/source, datum/bank_account/from, datum/bank_account/target, amount, reason, mob/actor)
	SIGNAL_HANDLER
	if(reason == ECON_CONTRACT)
		contract_moves[target] += amount

/// Каждый вариант каждого заказа доски закрывается отправкой с пада подработки: контракт выполнен, отделу и взявшему заплачено.
/datum/unit_test/economy_contracts_deliverable/Run()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/mob/living/carbon/human/courier = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/bank_account/taker = new("econ_test_courier")
	allocated += taker
	courier.account_id = taker.account_id
	var/obj/machinery/computer/piratepad_control/civilian/console = econ_test_contract_pad(courier, station_turf, src)
	var/turf/pad_turf = get_turf(console.linked_pad())
	var/datum/econ_test_obtainable/obtainable = new(courier)
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))
	var/list/pad_turf_before = pad_turf.contents.Copy()
	var/list/saved_balances = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[department] = department.account.account_balance
	for(var/bounty_type in econ_test_board_bounty_types())
		var/datum/bounty/probe = new bounty_type
		var/list/variants = probe.econ_test_variants()
		qdel(probe)
		for(var/variant in variants)
			var/problem
			try
				problem = econ_test_deliver(bounty_type, variant, taker, courier, console, pad_turf, obtainable)
			catch(var/exception/error)
				problem = "ошибка [error] ([error.file]:[error.line])"
			if(problem)
				TEST_FAIL("[bounty_type][variant ? " ([variant])" : ""]: [problem]")
			var/list/leftovers = pad_turf.contents - pad_turf_before
			QDEL_LIST(leftovers)
	SSeconomy.contract_demand.Cut()
	for(var/datum/economy_department/department as anything in saved_balances)
		econ_test_set_balance(department.account, saved_balances[department])
	qdel(obtainable)

/// Выставляет заказ контрактом отдела, берёт его счётом taker и отправляет образец с пада. Возвращает, что пошло не так.
/datum/unit_test/economy_contracts_deliverable/proc/econ_test_deliver(bounty_type, variant, datum/bank_account/taker, mob/living/courier, obj/machinery/computer/piratepad_control/civilian/console, turf/pad_turf, datum/econ_test_obtainable/obtainable)
	var/datum/bounty/bounty = new bounty_type
	bounty.econ_test_use_variant(variant)
	if(!bounty.name || !bounty.description)
		qdel(bounty)
		return "без названия или описания заказ не выйдет на доску"
	var/department_id = econ_bounty_department_of(bounty_type) || ACCOUNT_CAR
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	var/datum/econ_contract/delivery/contract = new(department_id, bounty)
	department.contracts.Insert(1, contract)
	if(!contract.take(taker))
		qdel(contract)
		return "контракт не взять: [contract.take_refusal(taker)]"
	var/list/sample = bounty.econ_test_sample(pad_turf, obtainable)
	if(!length(sample))
		qdel(contract)
		return "не из чего собрать образец"
	var/accepted = FALSE
	for(var/atom/movable/thing as anything in sample)
		for(var/atom/movable/candidate as anything in econ_contract_candidates(thing))
			accepted = accepted || bounty.applies_to(candidate)
	if(!accepted)
		var/atom/movable/first = sample[1]
		qdel(contract)
		return "заказ не принимает [first] ([first.type])"
	var/reward = contract.payout()
	var/share = round(reward * contract.performer_share() / 100)
	contract_moves.Cut()
	econ_test_click(courier, console, "send")
	if(!contract.completed)
		var/progress = contract.progress_text()
		qdel(contract)
		return "отправка с пада не закрыла контракт ([progress]): [console.status_report]"
	if((contract_moves[department.account] || 0) != reward - share)
		return "отделу [department_id] пришло [contract_moves[department.account] || 0] вместо [reward - share]"
	if(!(contract_moves[taker] >= share))
		return "взявшему пришло [contract_moves[taker] || 0] вместо [share]"

/proc/econ_test_click(mob/user, obj/machinery/console, action, list/params = list())
	var/datum/tgui/window = new(user, console, "contracts")
	window.status = UI_INTERACTIVE
	usr = user
	console.ui_act(action, params, window)
	usr = null
	qdel(window)

/// Пад и пульт подработки, связанные мультитулом, на станционном турфе. Не горят: зажжённый костёр для заказа поджигает всё на турфе.
/proc/econ_test_contract_pad(mob/user, turf/where, datum/unit_test/test)
	var/obj/machinery/piratepad/civilian/pad = test.allocate(/obj/machinery/piratepad/civilian, where)
	pad.warmup_time = 0
	var/obj/machinery/computer/piratepad_control/civilian/console = test.allocate(/obj/machinery/computer/piratepad_control/civilian, where)
	pad.resistance_flags |= FIRE_PROOF
	console.resistance_flags |= FIRE_PROOF
	var/obj/item/multitool/tool = test.allocate(/obj/item/multitool)
	pad.multitool_act(user, tool)
	console.multitool_act(user, tool)
	return console

/datum/unit_test/economy_contracts_bought_container
	var/list/stashed_contracts
	var/saved_service

/datum/unit_test/economy_contracts_bought_container/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	var/datum/bank_account/service = SSeconomy.get_dep_account(ACCOUNT_SRV)
	saved_service = service.account_balance

/datum/unit_test/economy_contracts_bought_container/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	econ_test_set_balance(SSeconomy.get_dep_account(ACCOUNT_SRV), saved_service)
	return ..()

/datum/unit_test/economy_contracts_bought_container/proc/post(department_id, datum/bounty/bounty)
	var/datum/econ_contract/delivery/contract = new(department_id, bounty)
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	department.contracts.Insert(1, contract)
	return contract

/// Заказу нужен не сам купленный предмет, а то, что в него вложил игрок: наполненный презерватив и коктейль в стакане из автомата засчитываются, купленное уже с нужным реагентом - нет.
/datum/unit_test/economy_contracts_bought_container/Run()
	var/datum/bounty/item/assistant/condom/condom_bounty = new
	condom_bounty.required_count = 1
	var/datum/econ_contract/delivery/condom_contract = post(ACCOUNT_CIV, condom_bounty)
	var/obj/item/genital_equipment/condom/condom = allocate(/obj/item/genital_equipment/condom)
	econ_mark_vended(condom, 10)
	condom.reagents.add_reagent(/datum/reagent/consumable/semen, 20)
	TEST_ASSERT_EQUAL(econ_contracts_imported_matches(condom), 0, "Пад не называет наполненный презерватив купленным")
	TEST_ASSERT(econ_contracts_ship(condom), "Наполненный презерватив из автомата засчитан")
	TEST_ASSERT(condom_contract.completed, "Контракт на презервативы выполнен")

	var/datum/bounty/reagent/simple_drink/drink_bounty = new
	drink_bounty.econ_test_use_variant(/datum/reagent/consumable/ethanol/gintonic)
	var/datum/econ_contract/delivery/drink_contract = post(ACCOUNT_SRV, drink_bounty)
	var/obj/item/reagent_containers/food/drinks/drinkingglass/bottled = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass)
	bottled.reagents.add_reagent(/datum/reagent/consumable/ethanol/gintonic, 10)
	econ_mark_vended(bottled, 30)
	TEST_ASSERT_EQUAL(econ_contracts_imported_matches(bottled), 1, "Пад называет купленный готовым напиток")
	TEST_ASSERT(!econ_contracts_ship(bottled), "Напиток, купленный готовым, не засчитан")
	var/obj/item/reagent_containers/food/drinks/drinkingglass/glass = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass)
	econ_mark_vended(glass, 5)
	glass.reagents.add_reagent(/datum/reagent/consumable/ethanol/gintonic, 10)
	TEST_ASSERT(econ_contracts_ship(glass), "Свой коктейль в стакане из автомата засчитан")
	TEST_ASSERT(drink_contract.completed, "Контракт на напиток выполнен")

/datum/unit_test/economy_work/activity_contracts_all
	var/list/contract_moves = list()

/datum/unit_test/economy_work/activity_contracts_all/proc/on_moved(datum/source, datum/bank_account/from, datum/bank_account/target, amount, reason, mob/actor)
	SIGNAL_HANDLER
	if(reason == ECON_CONTRACT)
		contract_moves[target] += amount

/datum/unit_test/economy_work/activity_contracts_all/Destroy()
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	return ..()

/// Каждый вид контракта деятельности засчитывается записями настоящей работы и платит: взятый - взявшему и отделу, работа всего отдела - людям на смене.
/datum/unit_test/economy_work/activity_contracts_all/Run()
	setup_pair()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))
	for(var/department_id in GLOB.econ_activity_contracts)
		var/datum/economy_department/department = SSeconomy.get_department(department_id)
		var/saved_budget = department.account.account_balance
		for(var/contract_type in GLOB.econ_activity_contracts[department_id])
			performer_account.department_id = department_id
			var/datum/econ_contract/activity/contract = new contract_type(department_id)
			department.contracts += contract
			if(contract.takeable && !contract.take(performer_account))
				TEST_FAIL("[contract_type]: не взять ([contract.take_refusal(performer_account)])")
				qdel(contract)
				continue
			var/reward = contract.payout()
			var/share = contract.takeable ? round(reward * contract.performer_share() / 100) : 0
			var/price = SSeconomy.settings.work_prices[contract.work_type]
			var/paid_based = contract.contract_units(1, 7) == 7
			var/amount = paid_based ? CEILING(contract.target / price, 1) : max(CEILING(1 / price, 1), 1)
			contract_moves.Cut()
			for(var/attempt in 1 to contract.target + 1)
				if(contract.completed)
					break
				SSeconomy.record_work(department_id, contract.work_type, amount, performer)
			if(!contract.completed)
				TEST_FAIL("[contract_type]: работа не закрыла контракт ([contract.progress_text()])")
				qdel(contract)
				continue
			if(!(contract_moves[performer_account] > 0))
				TEST_FAIL("[contract_type]: исполнителю ничего не пришло")
			var/to_budget = contract.people_only ? 0 : reward - (contract.takeable ? share : round(reward * SSeconomy.settings.contract_team_share / 100))
			if((contract_moves[department.account] || 0) != to_budget)
				TEST_FAIL("[contract_type]: отделу пришло [contract_moves[department.account] || 0] вместо [to_budget]")
		econ_test_set_balance(department.account, saved_budget)

/datum/unit_test/economy_contracts_deliverable/chain

/// Серия поставок из пула доходит до конца: каждый этап закрывается отправкой с пада и платит, последний - с премией, после него серия закрыта.
/datum/unit_test/economy_contracts_deliverable/chain/Run()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/mob/living/carbon/human/courier = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/bank_account/taker = new("econ_test_courier")
	allocated += taker
	courier.account_id = taker.account_id
	var/obj/machinery/computer/piratepad_control/civilian/console = econ_test_contract_pad(courier, station_turf, src)
	var/turf/pad_turf = get_turf(console.linked_pad())
	var/datum/econ_test_obtainable/obtainable = new(courier)
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))
	var/list/pad_turf_before = pad_turf.contents.Copy()
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/saved_budget = civilian.account.account_balance
	SSeconomy.contract_demand.Cut()
	var/list/by_department = econ_bounty_types_by_department()
	var/list/civilian_types = by_department[ACCOUNT_CIV]
	var/list/bounty_types = civilian_types.Copy()
	var/datum/econ_contract/delivery/chain/chain = SSeconomy.generate_chain(ACCOUNT_CIV, SSeconomy.pick_bounty(bounty_types), bounty_types)
	TEST_ASSERT(istype(chain), "Серия собрана из пула CIV")
	TEST_ASSERT_EQUAL(chain.stages_total, ECON_CONTRACT_CHAIN_STAGES, "Этапов в серии")
	civilian.contracts.Insert(1, chain)
	TEST_ASSERT(chain.take(taker), "Серия взята")
	var/stages_paid = 0
	for(var/stage in 1 to ECON_CONTRACT_CHAIN_STAGES)
		var/datum/bounty/bounty = chain.bounty
		var/reward = chain.payout()
		if(stage == ECON_CONTRACT_CHAIN_STAGES)
			chain.stages_total++
			var/base = chain.payout()
			chain.stages_total--
			TEST_ASSERT_EQUAL(reward, base + round((stages_paid + base) * SSeconomy.settings.contract_chain_bonus / 100), "Последний этап платит премию от суммы этапов")
		var/share = round(reward * chain.performer_share() / 100)
		contract_moves.Cut()
		bounty.econ_test_sample(pad_turf, obtainable)
		econ_test_click(courier, console, "send")
		TEST_ASSERT_EQUAL(contract_moves[civilian.account] || 0, reward - share, "Этап [stage] ([bounty.name]) заплатил отделу")
		TEST_ASSERT(contract_moves[taker] >= share, "Этап [stage] ([bounty.name]) заплатил взявшему")
		stages_paid += reward
		if(stage < ECON_CONTRACT_CHAIN_STAGES)
			TEST_ASSERT(!chain.completed && chain.stage == stage + 1, "После этапа [stage] серия перешла к следующему ([chain.stage])")
		var/list/leftovers = pad_turf.contents - pad_turf_before
		QDEL_LIST(leftovers)
	TEST_ASSERT(chain.completed, "Серия закрыта после последнего этапа")
	SSeconomy.contract_demand.Cut()
	econ_test_set_balance(civilian.account, saved_budget)
	qdel(obtainable)

/datum/unit_test/economy_contracts_deliverable/relay

/// Каждая эстафета отделов доходит до конца настоящей работой: этап закрывается записью работы или отправкой с пада, следующий выходит на доску своего отдела, последний платит премию, а вся эстафета - не больше потолка серий.
/datum/unit_test/economy_contracts_deliverable/relay/Run()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/mob/living/carbon/human/courier = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/bank_account/helper = new("econ_test_relay")
	allocated += helper
	courier.account_id = helper.account_id
	var/obj/machinery/computer/piratepad_control/civilian/console = econ_test_contract_pad(courier, station_turf, src)
	var/turf/pad_turf = get_turf(console.linked_pad())
	var/list/pad_turf_before = pad_turf.contents.Copy()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_moved))
	var/list/saved_balances = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[department] = department.account.account_balance
	var/cap = SSeconomy.settings.contract_chain_reward_cap
	for(var/list/template as anything in GLOB.econ_relay_templates)
		var/title = template["title"]
		var/list/stages = template["stages"]
		SSeconomy.contract_demand.Cut()
		contract_moves.Cut()
		var/datum/econ_contract/first = SSeconomy.begin_relay(template)
		if(!first)
			TEST_FAIL("[title]: первый этап не выставлен")
			continue
		var/datum/econ_relay/relay = first.relay
		var/paid = 0
		for(var/number in 1 to length(stages))
			var/list/spec = stages[number]
			var/datum/econ_contract/current = relay.current
			var/datum/economy_department/department = SSeconomy.get_department(spec["department"])
			if(!(current in department?.contracts))
				TEST_FAIL("[title]: этап [number] ([spec["label"]]) не на доске отдела [spec["department"]]")
				break
			var/reward = current.final_payout()
			if(number == length(stages))
				var/base = current.payout()
				TEST_ASSERT_EQUAL(reward, econ_chain_capped(base + round((paid + base) * SSeconomy.settings.contract_chain_bonus / 100), paid), "[title]: последний этап без премии от суммы этапов")
			var/problem
			try
				problem = econ_test_finish_stage(current, courier, console, pad_turf)
			catch(var/exception/error)
				problem = "ошибка [error] ([error.file]:[error.line])"
			var/list/leftovers = pad_turf.contents - pad_turf_before
			QDEL_LIST(leftovers)
			if(problem)
				TEST_FAIL("[title]: этап [number] ([spec["label"]]): [problem]")
				break
			paid += reward
			if(number < length(stages))
				TEST_ASSERT(!QDELETED(relay) && relay.stage == number + 1, "[title]: после этапа [number] эстафета не перешла к следующему")
		TEST_ASSERT(QDELETED(relay), "[title]: эстафета не закрыта после последнего этапа")
		var/moved = 0
		for(var/datum/bank_account/account as anything in contract_moves)
			moved += contract_moves[account]
		TEST_ASSERT(moved > 0, "[title]: эстафета ничего не заплатила")
		if(cap)
			TEST_ASSERT(moved <= cap, "[title]: эстафета заплатила [moved] кр. при потолке [cap]")
	SSeconomy.contract_demand.Cut()
	for(var/datum/economy_department/department as anything in saved_balances)
		econ_test_set_balance(department.account, saved_balances[department])

/// Закрывает этап эстафеты настоящим путём: деятельность - записями работы курьера, поставку - образцом с пада. Возвращает, что пошло не так.
/datum/unit_test/economy_contracts_deliverable/relay/proc/econ_test_finish_stage(datum/econ_contract/stage_contract, mob/living/courier, obj/machinery/computer/piratepad_control/civilian/console, turf/pad_turf)
	var/datum/econ_contract/activity/activity = stage_contract
	if(istype(activity))
		var/price = SSeconomy.settings.work_prices[activity.work_type]
		var/amount = activity.contract_units(1, 7) == 7 ? CEILING(activity.target / price, 1) : max(CEILING(1 / price, 1), 1)
		for(var/attempt in 1 to activity.target + 1)
			if(activity.completed)
				break
			SSeconomy.record_work(activity.department_id, activity.work_type, amount, courier)
		return activity.completed ? null : "работа не закрыла этап ([activity.progress_text()])"
	var/datum/econ_contract/delivery/delivery = stage_contract
	if(!istype(delivery))
		return "этап неизвестного вида [stage_contract.type]"
	if(!length(delivery.bounty.econ_test_sample(pad_turf, null)))
		return "не из чего собрать образец"
	econ_test_click(courier, console, "send")
	return delivery.completed ? null : "отправка не закрыла этап ([delivery.progress_text()]): [console.status_report]"

/// Невыполнимые заказы не попадают ни в пул отделов, ни в особые заказы ЦК по событию.
/datum/unit_test/economy_contracts_unobtainable_not_posted/Run()
	var/list/board = econ_test_board_bounty_types()
	for(var/bounty_type in GLOB.econ_bounty_unobtainable)
		TEST_ASSERT(!(bounty_type in board), "[bounty_type] в пуле отделов")
		var/datum/bounty/bounty = new bounty_type
		var/datum/econ_contract/contract = SSeconomy.post_special_contract(bounty)
		if(contract)
			qdel(contract)
			TEST_FAIL("[bounty_type] выставлен особым заказом")
		else
			qdel(bounty)
