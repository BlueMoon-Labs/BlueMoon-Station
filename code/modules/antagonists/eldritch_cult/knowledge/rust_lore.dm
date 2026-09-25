#define HERETIC_RUST_GRASP_SPREAD 1

/datum/eldritch_knowledge/base_rust
	name = "История кузнеца"
	summary = "Хватка ржавит полы и стены и ломает шлюзы, Укоренение за нарост ставит лечащий очаг."
	details = list(
		"Хватка по полу или стене ржавит их, повторное касание сносит ржавую стену.",
		"Хватка по обычному шлюзу разрушает его; укреплённая стена поддаётся с шансом 50%.",
		"Новая ржавая поверхность даёт нарост раз в 15 секунд, новый отдел идёт в дело пути.",
		"Укоренение за 1 нарост: один очаг на 30 секунд ржавит пол 5×5 и лечит вас и слуг на ржавчине.",
		"Новый очаг заменяет прежний и ставится только на ржавеющий пол. Перезарядка 30 секунд.",
		"Готовую цель на ржавчине своего очага сердце уводит в изнанку за 1 секунду; из изнанки можно выйти к очагу.",
		"Нож и мусор на руне дают ржавый клинок.",
	)
	role = HERETIC_ROLE_CRAFT
	ritual_hints = list(
		"Мусор - пустая упаковка от чипсов или изюма; полная пачка, бумага и металлолом не подходят.",
		"Положите нож и упаковку на руну или в клетку рядом.",
	)
	resource_rules = list(
		"Запас до 4 наростов.",
		"Новая ржавая поверхность от хватки даёт нарост раз в 15 секунд.",
		"Взрыв Метки Ржавчины клинком даёт нарост.",
		"Укоренение и семя ржавчины тратят по 1 наросту.",
	)
	gain_text = "Кузнец протянул мне клинок. Под его ногами металл дышал."
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/trash)
	result_atoms = list(/obj/item/melee/sickly_blade/rust)
	cost = 0
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist
	name = "Хватка Ржавчины"
	summary = "Хватка обрушивает обычную стену с одного касания."
	details = list(
		"Обычная стена ржавеет и рушится от одной хватки.",
		"Укреплённую стену сначала ржавят, потом ломают; каждое касание срабатывает с шансом 50%.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Теперь я чувствую, где сталь готова пустить корни."
	cost = 1
	route = PATH_RUST

/datum/eldritch_knowledge/base_rust/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag)
		return FALSE
	if(istype(target, /obj/machinery/door))
		var/obj/machinery/door/door = target
		var/old_integrity = door.obj_integrity
		door.rust_heretic_act()
		return QDELETED(door) || door.obj_integrity < old_integrity
	if(!isfloorturf(target) && !iswallturf(target))
		return FALSE
	var/turf/surface = target
	if(isfloorturf(surface))
		var/turf/open/floor/floor = surface
		if(!floor.heretic_rustable)
			floor.balloon_alert(user, "не поддаётся ржавчине")
			return FALSE
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
			gain_combat_resource()
			COOLDOWN_START(src, resource_harvest, 15 SECONDS)
	var/affected = was_rust || is_heretic_rust_turf(changed)
	if(!was_rust && istype(changed, /turf/closed/wall/rust) && heretic?.get_knowledge(/datum/eldritch_knowledge/rust_fist))
		changed.rust_heretic_act()
	return affected

/datum/eldritch_knowledge/rust_regen
	name = "Ржавая поступь"
	summary = "На ржавом полу каждую секунду лечатся ушибы, ожоги, отравление, удушье, выносливость и кровь."
	details = list(
		"Каждую секунду на ржавчине: 2 ушиба, 2 ожога, 1 отравления, 1 удушья и 4 выносливости.",
		"Потерянная кровь тоже восполняется, так что кровотечение на своей территории не добьёт.",
		"Улучшения усиливают лечение до 125 и 150%.",
		"Складывается с Живой ржавчиной и очагом Укоренения.",
		"Вне ржавчины лечения нет: вас будут выманивать с неё.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "Под ногами скрипит металл, но этот звук успокаивает меня."
	cost = 1
	route = PATH_RUST

/datum/eldritch_knowledge/rust_regen/on_life(mob/user)
	if(!isliving(user) || user.stat == DEAD || !istype(get_turf(user), /turf/open/floor/plating/rust))
		return
	var/mob/living/living_user = user
	var/healing_multiplier = passive_values[passive_level]
	heretic_heal_damage(living_user, 2 * healing_multiplier, 2 * healing_multiplier)
	living_user.adjustToxLoss(-healing_multiplier, FALSE, TRUE, toxins_type = TOX_OMNI)
	living_user.adjustOxyLoss(-healing_multiplier)
	living_user.adjustStaminaLoss(-4 * healing_multiplier)
	if(iscarbon(living_user) && living_user.blood_volume && living_user.blood_volume < BLOOD_VOLUME_NORMAL)
		living_user.blood_volume = min(BLOOD_VOLUME_NORMAL, living_user.blood_volume + 2 * healing_multiplier)

/datum/eldritch_knowledge/rust_mark
	name = "Метка Ржавчины"
	summary = "Хватка ставит метку на 15 секунд, удар ржавым клинком её взрывает."
	details = list(
		"Взрыв: 15 урона коррозией - 5 ожогов и 10 отравления, у синтетика вместо отравления повреждение систем.",
		"Вещи в руках и верхняя одежда ржавеют, но не разрушаются.",
		"Взрыв даёт нарост для Укоренения.",
		"Слизни и борги получают только ожоги.",
		"Метка спадает через 15 секунд.",
	)
	role = HERETIC_ROLE_MARK
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
	summary = "Ржавчина расходится по поверхностям в 6 клетках; сердце, кабель и железо дают семя ржавчины."
	details = list(
		"Полы и стены вокруг ржавеют: рядом наверняка, к 6 клеткам всё реже. Перезарядка 30 секунд.",
		"Сердце, кабель и лист железа на руне дают семя ржавчины.",
		"Семя, использованное в руке на ржавеющем полу, за 3 секунды и 1 нарост прорастает в очаг 5×5 на 60 секунд.",
		"Очаг лечит вас и свиту на ржавчине; такой очаг у вас один, семя тратится, между посадками 20 секунд.",
		"Коснитесь очага пустой рукой на «Вреде» - через секунду он лопнет и нанесёт врагам рядом 18 урона коррозией.",
		"Очаг видно, его можно разбить; стены и защита от магии спасают от взрыва.",
	)
	role = HERETIC_ROLE_CONTROL
	required_atoms = list(/obj/item/organ/heart, /obj/item/stack/cable_coil, /obj/item/stack/sheet/metal)
	result_atoms = list(/obj/item/heretic_relic/rust_seed)
	gain_text = "Ржавые холмы растут там, где я разрешаю им расти."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/aoe_turf/rust_conversion
	route = PATH_RUST

/datum/eldritch_knowledge/spell/rust_wave
	name = "Досягаемость покровителя"
	summary = "Заряд ржавчины летит на 15 клеток: 50 урона отравлением цели и ржавая полоса за ним."
	details = list(
		"Прицельтесь и выстрелите: заряд бьёт первого на пути на 50 отравления.",
		"По пути полоса шириной до 5 клеток местами ржавеет.",
		"Даётся любому пути: лечения и других сил Ржавчины не даёт.",
		"Перезарядка 35 секунд; до вознесения не колдуется под оглушением и в стамкрите.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Кузнецу не нужно касаться металла, чтобы услышать его."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/aimed/rust_wave
	route = PATH_RUST

/datum/eldritch_knowledge/rust_blade_upgrade
	name = "Токсичный клинок"
	summary = "Каждый удар ржавым клинком добавляет 5 урона коррозией."
	details = list(
		"Треть коррозии - ожоги, остальное - отравление, у синтетика - повреждение систем.",
		"Слизни и борги получают только ожоги; коррозия никого не лечит.",
	)
	role = HERETIC_ROLE_PASSIVE
	gain_text = "На острие моего клинка созревает ещё одна жизнь."
	cost = 2
	route = PATH_RUST

/datum/eldritch_knowledge/rust_blade_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(isliving(target))
		var/mob/living/victim = target
		heretic_corrosion(victim, 5)

/datum/eldritch_knowledge/spell/entropic_plume
	name = "Энтропийное облако"
	summary = "Конус ржавчины слепит и путает врагов, те бросаются на соседей; до 10 урона коррозией."
	details = list(
		"Облако расходится конусом перед вами и ржавит поверхности на пути.",
		"Враги слепнут, теряют рассудок и нападают на окружающих.",
		"Коррозия от 10 вблизи до 2 на краю: треть ожогами, остальное отравлением.",
		"У синтетика вместо отравления повреждение систем, слизни и борги получают только ожоги.",
		"Вдали ослепление сильнее, а коррозия слабее.",
		"Стены задерживают облако; защита от магии спасает. Перезарядка 30 секунд.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Нет края между моим садом и тем, что ещё не успело стать им."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/cone/staggered/entropic_plume
	route = PATH_RUST

/datum/eldritch_knowledge/armor
	name = "Ритуал оружейника — броня"
	summary = "Стол и противогаз дают мантию еретика с капюшоном: 50% защиты от ударов, пуль и лазеров."
	details = list(
		"Мантия держит 50% ударов, пуль, лазеров и энергии и 35% взрыва.",
		"На мантии носятся клинок, кодекс и живое сердце.",
		"Капюшон закрывает голову и защищает глаза от вспышек.",
	)
	role = HERETIC_ROLE_RELIC
	ritual_hints = list(
		"Нужен готовый стол, а не каркас или материалы; разбирать его не нужно.",
		"Стол должен стоять в клетке от центра руны, включая диагонали.",
		"Противогаз снимите с лица и положите туда же; стол и противогаз израсходуются.",
	)
	gain_text = "Кузнец показал мне, как носить то, что другие называют отходами."
	cost = 1
	required_atoms = list(/obj/structure/table, /obj/item/clothing/mask/gas)
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/eldritch)

/datum/eldritch_knowledge/essence
	name = "Ритуал священника"
	summary = "Бак с водой и осколок стекла дают 50 единиц эссенции: она лечит еретика и срезает оглушение."
	details = list(
		"Каждое усвоение лечит раны, отравление и 30 выносливости, сокращает оглушение и неподвижность на 8 секунд.",
		"Пейте заранее: оглушённый не выпьет, а от новых ударов эссенция не защищает.",
		"Для непосвящённых это яд.",
	)
	role = HERETIC_ROLE_RELIC
	ritual_hints = list(
		"Нужен целый бак для воды, а не стакан или мензурка с водой.",
		"Поставьте бак в клетку от центра руны, рядом положите осколок стекла; оба израсходуются.",
	)
	gain_text = "Старый рецепт оказался записан на внутренней стороне века."
	cost = 1
	required_atoms = list(/obj/structure/reagent_dispensers/watertank, /obj/item/shard)
	result_atoms = list(/obj/item/reagent_containers/glass/beaker/eldritch)

/datum/eldritch_knowledge/rust_fist_upgrade
	name = "Мерзкая хватка"
	summary = "Хватка по врагу ржавит пол 3×3 вокруг него - плацдарм для лечения даже вдали от очага."
	details = list(
		"Ржавеют только полы, которые поддаются ржавчине; стены закрывают клетки за собой.",
		"На этом полу работают Ржавая поступь и Живая ржавчина.",
		"Защита от магии срывает эффект.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Под чужими ногами уже пускает корни мой сад."
	cost = 2
	route = PATH_RUST

/datum/eldritch_knowledge/rust_fist_upgrade/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	for(var/turf/open/floor/floor in heretic_field_view(HERETIC_RUST_GRASP_SPREAD, target))
		floor.rust_heretic_act()
	return TRUE

/datum/eldritch_knowledge/spell/grasp_of_decay
	name = "Хватка распада"
	summary = "Касание валит врага на 2 секунды и 20 секунд гноит тело и органы."
	details = list(
		"Подготовьте руку и коснитесь врага: 2 секунды он на полу.",
		"Распад 20 секунд: ушибы, головокружение и повреждение органов.",
		"Сбитого с ног можно начать приносить в жертву.",
		"Защита от магии поглощает касание. Перезарядка 2 минуты.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Ржавчина перестала отличать железо от крови."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay
	route = PATH_RUST

/datum/eldritch_knowledge/final_eldritch/rust_final
	name = "Клятва Посланника Ржавчины"
	summary = "Ржавое сердце растит ржавчину по станции, ржавый пол лечит и бережёт силы, открывается Коррозийный вал."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место и 30 секунд может помешать.",
		"Общая стойкость вознесения и защита от жары; с живым сердцем ржавый пол лечит сильнее и вдвое режет урон выносливости.",
		"Ржавое сердце на 300 прочности растёт на руне и растит ржавчину; если руна над космосом или в завале - у ваших ног.",
		"Коррозийный вал раз в 40 секунд: 20 коррозии врагам в 5 клетках, кроме защищённых от магии; не оглушает.",
		"Вал ржавит полы и рушит внутренние стены; наружные и корпус шаттла стоят, укреплённые только ржавеют.",
		"Стены и закрытые двери держат вал: он бьёт только то, что видно.",
		"Слабость: сердце на виду, его можно разбить оружием, и тогда ржавый пол навсегда теряет силу вознесения.",
	)
	role = HERETIC_ROLE_ASCENSION
	gain_text = "Кузнец оставил свой молот. Сад принимает нового хозяина. Его сердце бьётся в полу, и пока оно бьётся, ржавчина не остановится."
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	route = PATH_RUST
	parallax_scene = ANTAG_SCENE_HERETIC_RUST
	ascension_traits = list(TRAIT_RESISTHEAT)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/rust_corrosive_wave)
	var/datum/rust_spread/spread
	var/obj/structure/heretic_rust_ascension_heart/ascension_heart
	var/datum/weakref/heart_master

/datum/eldritch_knowledge/final_eldritch/rust_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	plant_ascension_heart(loc, user)
	if(!simulated)
		user.client?.give_award(/datum/award/achievement/misc/rust_ascension, user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/rust_final/on_body_gain(mob/living/user)
	. = ..()
	if(!finished || applied_body != user)
		return
	user.AddComponent(/datum/component/heretic_rust_ascension, src)
	start_spread()

/datum/eldritch_knowledge/final_eldritch/rust_final/on_body_lose(mob/living/user)
	QDEL_NULL(spread)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_rust_ascension))
	return ..()

/datum/eldritch_knowledge/final_eldritch/rust_final/Destroy()
	if(ascension_heart)
		UnregisterSignal(ascension_heart, COMSIG_PARENT_QDELETING)
		QDEL_NULL(ascension_heart)
	QDEL_NULL(spread)
	heart_master = null
	return ..()

/datum/eldritch_knowledge/final_eldritch/rust_final/proc/heart_alive()
	return !QDELETED(ascension_heart)

/datum/eldritch_knowledge/final_eldritch/rust_final/proc/start_spread()
	if(spread || !heart_alive() || !applied_body)
		return
	spread = new(get_turf(ascension_heart))

/datum/eldritch_knowledge/final_eldritch/rust_final/proc/plant_ascension_heart(turf/ritual_turf, mob/living/user)
	var/turf/heart_turf = get_turf(ritual_turf)
	if(!isopenturf(heart_turf) || isspaceturf(heart_turf) || isgroundlessturf(heart_turf) || heart_turf.is_blocked_turf(TRUE))
		heart_turf = get_turf(user)
	if(!heart_turf)
		return
	ascension_heart = new(heart_turf)
	heart_master = WEAKREF(user.mind)
	RegisterSignal(ascension_heart, COMSIG_PARENT_QDELETING, PROC_REF(on_heart_destroyed))
	start_spread()
	var/datum/component/heretic_rust_ascension/aspect = applied_body?.GetComponent(/datum/component/heretic_rust_ascension)
	aspect?.update_stamina()
	to_chat(user, span_notice("На месте обряда пульсирует Ржавое сердце. Пока оно цело, ржавчина растёт и бережёт вас; экипаж попытается его разбить."))

/datum/eldritch_knowledge/final_eldritch/rust_final/proc/on_heart_destroyed(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	ascension_heart = null
	QDEL_NULL(spread)
	var/datum/component/heretic_rust_ascension/aspect = applied_body?.GetComponent(/datum/component/heretic_rust_ascension)
	aspect?.update_stamina()
	var/datum/mind/master = heart_master?.resolve()
	if(master?.current)
		to_chat(master.current, span_userdanger("Ржавое сердце разбито! Ржавчина больше не расползается, а ржавый пол теряет силу вознесения."))

/datum/eldritch_knowledge/final_eldritch/rust_final/on_death(mob/user)
	QDEL_NULL(spread)
	return ..()

/datum/eldritch_knowledge/final_eldritch/rust_final/on_life(mob/user)
	. = ..()
	if(!finished || !isliving(user) || user.stat == DEAD)
		return
	start_spread()
	var/datum/component/heretic_rust_ascension/aspect = user.GetComponent(/datum/component/heretic_rust_ascension)
	aspect?.update_stamina()
	if(!heart_alive() || !istype(get_turf(user), /turf/open/floor/plating/rust))
		return
	var/mob/living/living_user = user
	heretic_heal_damage(living_user, 4, 4)
	living_user.adjustToxLoss(-3, FALSE, TRUE, toxins_type = TOX_OMNI)
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

#undef HERETIC_RUST_GRASP_SPREAD
