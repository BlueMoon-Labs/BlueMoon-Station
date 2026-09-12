/datum/eldritch_knowledge/base_rust
	name = "История кузнеца"
	desc = "Открывает Путь Ржавчины: превращайте станцию в свою территорию и выращивайте лечащие очаги. Кухонный нож и мусор превращаются в ржавый клинок. Укоренение расходует нарост и создаёт временный ржавый очаг."
	gain_text = "Кузнец протянул мне клинок. Под его ногами металл дышал."
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/trash)
	result_atoms = list(/obj/item/melee/sickly_blade/rust)
	cost = 0
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist
	name = "Хватка Ржавчины"
	desc = "Хватка покрывает полы и стены ржавчиной, а повторное касание разрушает ржавую стену. Новая поверхность даёт нарост для Укоренения, не чаще раза в 15 секунд."
	gain_text = "Теперь я чувствую, где сталь готова пустить корни."
	cost = 1
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!isfloorturf(target) && !iswallturf(target))
		return FALSE
	var/turf/surface = target
	var/was_rust = is_heretic_rust_turf(surface)
	var/surface_x = surface.x
	var/surface_y = surface.y
	var/surface_z = surface.z
	surface.rust_heretic_act()
	var/turf/changed = locate(surface_x, surface_y, surface_z)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!was_rust && is_heretic_rust_turf(changed) && heretic)
		heretic.advance_deed(heretic.deed_key_for(changed), changed, silent = TRUE)
		if(COOLDOWN_FINISHED(src, resource_harvest))
			var/datum/eldritch_knowledge/base_rust/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
			path?.gain_combat_resource()
			COOLDOWN_START(src, resource_harvest, 15 SECONDS)
	return was_rust || is_heretic_rust_turf(changed)

/datum/eldritch_knowledge/rust_regen
	name = "Ржавая поступь"
	desc = "На ржавом полу вы восстанавливаете ушибы, ожоги, отравление и выносливость. Укоренение усиливает это лечение; уход с подготовленной территории лишает вас её защиты."
	gain_text = "Под ногами скрипит металл, но этот звук успокаивает меня."
	cost = 1
	route = PATH_RUST

/datum/eldritch_knowledge/rust_regen/on_life(mob/user)
	if(!isliving(user) || user.stat == DEAD || !istype(get_turf(user), /turf/open/floor/plating/rust))
		return
	var/mob/living/living_user = user
	var/healing_multiplier = passive_values[passive_level]
	living_user.adjustBruteLoss(-2 * healing_multiplier, FALSE)
	living_user.adjustFireLoss(-2 * healing_multiplier, FALSE)
	living_user.adjustToxLoss(-healing_multiplier, FALSE, TRUE)
	living_user.adjustStaminaLoss(-4 * healing_multiplier)

/datum/eldritch_knowledge/rust_mark
	name = "Метка Ржавчины"
	desc = "Хватка накладывает Метку Ржавчины. Удар ржавым клинком активирует её: 15 отравления, повреждение предметов в руках и верхней одежды, один нарост для Укоренения. Метка сама не уничтожает снаряжение."
	gain_text = "Плоть, как и металл, можно научить распаду."
	cost = 2
	route = PATH_RUST

/datum/eldritch_knowledge/rust_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/rust)
	return TRUE

/datum/eldritch_knowledge/spell/area_conversion
	name = "Агрессивный выброс"
	desc = "Распространяет ржавчину по ближайшим поверхностям; заржавевшие стены разрушаются. Соедините сердце, кабель и железо, чтобы создать семя ржавчины. Один нарост позволит посадить его на минуту: разрушаемый очаг расширяет ржавчину и лечит хозяина со свитой."
	required_atoms = list(/obj/item/organ/heart, /obj/item/stack/cable_coil, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/heretic_relic/rust_seed)
	gain_text = "Ржавые холмы растут там, где я разрешаю им расти."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/aoe_turf/rust_conversion
	route = PATH_RUST

/datum/eldritch_knowledge/spell/rust_wave
	name = "Досягаемость покровителя"
	desc = "Выпускает заряд ржавчины, который отравляет цель и оставляет ржавый проход. Подходит для наступления с подготовленной территории."
	gain_text = "Кузнецу не нужно касаться металла, чтобы услышать его."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/aimed/rust_wave
	route = PATH_RUST

/datum/eldritch_knowledge/rust_blade_upgrade
	name = "Токсичный клинок"
	desc = "Каждое ранение ржавым клинком дополнительно наносит 5 отравления."
	gain_text = "На острие моего клинка созревает ещё одна жизнь."
	cost = 2
	route = PATH_RUST

/datum/eldritch_knowledge/rust_blade_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(isliving(target))
		var/mob/living/victim = target
		victim.adjustToxLoss(5)

/datum/eldritch_knowledge/spell/entropic_plume
	name = "Энтропийный шлейф"
	desc = "Волна ржавчины ослепляет и дезориентирует врагов, заставляя их нападать на окружающих. Наносит от 10 отравления вблизи до 2 на краю. Поверхности на её пути покрываются ржавчиной."
	gain_text = "Нет края между моим садом и тем, что ещё не успело стать им."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/cone/staggered/entropic_plume
	route = PATH_RUST

/datum/eldritch_knowledge/armor
	name = "Ритуал оружейника — броня"
	desc = "Создаёт броню еретика: мантию с защитным капюшоном из стола и противогаза."
	ritual_hint = "Нужен готовый стол, а не каркас или материалы. Начертите руну рядом: стол должен оказаться в пределах одной клетки от её центра, включая диагонали. Разбирать стол не нужно. Положите туда же противогаз, сняв его с лица. Стол и противогаз будут израсходованы."
	gain_text = "Кузнец показал мне, как носить то, что другие называют отходами."
	cost = 1
	required_atoms = list(/obj/structure/table, /obj/item/clothing/mask/gas)
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/eldritch)

/datum/eldritch_knowledge/essence
	name = "Ритуал священника"
	desc = "Соедините бак с водой и осколок стекла, чтобы получить древнюю эссенцию — лекарство для еретика и яд для непосвящённых."
	ritual_hint = "Нужен целый бак для воды, а не стакан или мензурка с водой. Поставьте бак в пределах одной клетки от центра руны и положите рядом осколок стекла. Бак будет израсходован вместе с осколком."
	gain_text = "Старый рецепт оказался записан на внутренней стороне века."
	cost = 1
	required_atoms = list(/obj/structure/reagent_dispensers/watertank, /obj/item/shard)
	result_atoms = list(/obj/item/reagent_containers/glass/beaker/eldritch)

/datum/eldritch_knowledge/rust_fist_upgrade
	name = "Мерзкая хватка"
	desc = "Хватка покрывает ржавчиной пол под противником: даже вдали от очага можно создать небольшой плацдарм для лечения."
	gain_text = "Под чужими ногами уже пускает корни мой сад."
	cost = 2
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist_upgrade/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	var/turf/floor = get_turf(victim)
	if(isfloorturf(floor))
		floor.rust_heretic_act()
	return TRUE

/datum/eldritch_knowledge/spell/grasp_of_decay
	name = "Хватка распада"
	desc = "Сбивает врага с ног на 2 секунды и накладывает распад на 20 секунд: ушибы, головокружение и повреждения органов. Перезарядка 2 минуты."
	gain_text = "Ржавчина перестала отличать железо от крови."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay
	route = PATH_RUST

/datum/eldritch_knowledge/final_eldritch/rust_final
	name = "Клятва Посланника Ржавчины"
	desc = "После трёх подношений принесите три мёртвых тела на руну. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. Вознесение запускает волну ржавчины и даёт устойчивость к среде. На ржавом полу ваше восстановление резко ускоряется; вне его вы уязвимы."
	gain_text = "Кузнец оставил свой молот. Сад принимает нового хозяина."
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	route = PATH_RUST
	parallax_scene = ANTAG_SCENE_HERETIC_RUST
	ascension_traits = list(TRAIT_NOBREATH, TRAIT_RESISTCOLD, TRAIT_RESISTHEAT, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE)
	var/datum/rust_spread/spread

/datum/eldritch_knowledge/final_eldritch/rust_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	user.client?.give_award(/datum/award/achievement/misc/rust_ascension, user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/rust_final/on_body_gain(mob/living/user)
	. = ..()
	if(finished && !spread && user.stat != DEAD)
		spread = new(get_turf(user))

/datum/eldritch_knowledge/final_eldritch/rust_final/on_body_lose(mob/living/user)
	QDEL_NULL(spread)
	return ..()

/datum/eldritch_knowledge/final_eldritch/rust_final/on_death(mob/user)
	QDEL_NULL(spread)
	return ..()

/datum/eldritch_knowledge/final_eldritch/rust_final/on_life(mob/user)
	. = ..()
	if(!finished || !isliving(user) || user.stat == DEAD)
		return
	if(!spread)
		spread = new(get_turf(user))
	if(!istype(get_turf(user), /turf/open/floor/plating/rust))
		return
	var/mob/living/living_user = user
	living_user.adjustBruteLoss(-4, FALSE)
	living_user.adjustFireLoss(-4, FALSE)
	living_user.adjustToxLoss(-3, FALSE, TRUE)
	living_user.adjustOxyLoss(-4, FALSE)
	living_user.adjustStaminaLoss(-12)

/// Фронт распространения ограничен шестью поверхностями за тик. Посещённые клетки не обходятся заново.
/datum/rust_spread
	var/list/edge_turfs = list()
	var/list/visited = list()
	var/static/list/blacklisted_turfs = typecacheof(list(/turf/open/indestructible, /turf/closed/indestructible, /turf/open/space, /turf/open/lava, /turf/open/chasm))
	var/spread_per_tick = 6
	var/queue_index = 1
	var/max_turfs = 6000

/datum/rust_spread/New(loc)
	. = ..()
	var/turf/initial_turf = get_turf(loc)
	if(!initial_turf)
		return
	edge_turfs += initial_turf
	visited["[initial_turf.x],[initial_turf.y],[initial_turf.z]"] = TRUE
	START_PROCESSING(SSprocessing, src)

/datum/rust_spread/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	edge_turfs.Cut()
	visited.Cut()
	return ..()

/datum/rust_spread/process()
	for(var/i in 1 to spread_per_tick)
		if(queue_index > length(edge_turfs))
			return PROCESS_KILL
		var/turf/surface = edge_turfs[queue_index++]
		if(!surface || is_type_in_typecache(surface, blacklisted_turfs))
			continue
		var/surface_x = surface.x
		var/surface_y = surface.y
		var/surface_z = surface.z
		surface.rust_heretic_act()
		surface = locate(surface_x, surface_y, surface_z)
		if(!is_heretic_rust_turf(surface))
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(surface, direction)
			if(!neighbor || length(visited) >= max_turfs || is_type_in_typecache(neighbor, blacklisted_turfs))
				continue
			var/key = "[neighbor.x],[neighbor.y],[neighbor.z]"
			if(visited[key])
				continue
			visited[key] = TRUE
			edge_turfs += neighbor
	if(queue_index > 256)
		edge_turfs.Cut(1, queue_index)
		queue_index = 1

/proc/is_heretic_rust_turf(turf/surface)
	return istype(surface, /turf/open/floor/plating/rust) || istype(surface, /turf/closed/wall/rust) || istype(surface, /turf/closed/wall/r_wall/rust)
