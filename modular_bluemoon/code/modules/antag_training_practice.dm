GLOBAL_LIST_INIT(antag_training_kits, list(
	"melee" = list("name" = "Ближний бой", "zone" = "melee", "items" = list("baton", "cuffs", "vest", "helmet")),
	"range" = list("name" = "Стрельба", "zone" = "range", "items" = list("pistol", "magazine", "vest", "helmet")),
	"medicine" = list("name" = "Первая помощь", "zone" = "laboratory", "items" = list("health", "firstaid", "burn_kit")),
	"workshop" = list("name" = "Строительство", "zone" = "laboratory", "items" = list("tools", "steel", "glass", "cable"))
))

/datum/antag_training_session
	var/preparing = FALSE
	var/practice_id
	var/datum/weakref/practice_target
	var/datum/antag_training_measurement/measurement
	var/practice_complete = FALSE
	var/practice_hint
	var/last_feedback
	var/last_kit
	var/list/recipe_cache
	var/recipe_cache_size = -1
	var/last_duel_result
	var/next_duel_at = 0

/datum/antag_training_session/proc/practice_message(message)
	last_feedback = message
	to_chat(current_body, span_notice(message))

/datum/antag_training_session/proc/issue_kit(kit_id)
	var/list/kit = GLOB.antag_training_kits[kit_id]
	if(!kit || !can_control(current_body) || preparing || arena.resetting || world.time < next_supply_at)
		return FALSE
	arena.prune_supplies()
	var/list/items = kit["items"]
	if(arena.supply_count + length(items) > ANTAG_TRAINING_SUPPLY_LIMIT)
		practice_message("Для комплекта не хватает места в общем лимите. Уберите свои ненужные предметы.")
		return FALSE
	preparing = TRUE
	next_supply_at = world.time + ANTAG_TRAINING_PRACTICE_DELAY
	current_body.forceMove(arena.zones[kit["zone"]]["spawn"])
	var/issued = 0
	for(var/item_id in items)
		arena.yield_work()
		if(QDELETED(src) || !can_control(current_body) || arena.resetting)
			break
		var/list/entry = GLOB.antag_training_equipment[item_id]
		if(arena.issue_item(entry["type"], get_turf(current_body), entry["amount"] || 1, src))
			issued++
	preparing = FALSE
	if(!QDELETED(src) && !finished)
		last_kit = kit_id
		practice_message("Комплект «[kit["name"]]»: выдано [issued] из [length(items)]. Вещи лежат рядом с вами; наденьте броню и возьмите инструмент в руку.")
	return issued == length(items)

/datum/antag_training_session/proc/training_recipes()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(current_body)
	if(!heretic)
		return list()
	if(recipe_cache && recipe_cache_size == length(heretic.researched_knowledge))
		return recipe_cache
	recipe_cache = list()
	recipe_cache_size = length(heretic.researched_knowledge)
	for(var/knowledge_type in heretic.researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = heretic.researched_knowledge[knowledge_type]
		if(!length(knowledge.required_atoms) && !length(knowledge.result_atoms))
			continue
		var/list/ingredients = list()
		var/list/counts = list()
		for(var/atom/ingredient_type as anything in knowledge.required_atoms)
			counts[ingredient_type] += knowledge.required_atoms[ingredient_type] || 1
		for(var/atom/ingredient_type as anything in counts)
			ingredients += "[heretic_ritual_ingredient_name(ingredient_type)] ×[counts[ingredient_type]]"
		recipe_cache += list(list("id" = REF(knowledge), "name" = knowledge.name, "ingredients" = jointext(ingredients, ", "), "hint" = knowledge.ritual_hint, "components" = !!length(knowledge.required_atoms), "result" = !!length(knowledge.result_atoms)))
	return recipe_cache

/datum/antag_training_session/proc/issue_recipe(datum/eldritch_knowledge/recipe, components = FALSE)
	var/mob/living/user = current_body
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!can_control(user) || !heretic || QDELETED(recipe) || heretic.get_knowledge(recipe.type) != recipe || preparing || arena.resetting || world.time < next_supply_at)
		return FALSE
	var/list/items = components ? recipe.required_atoms : recipe.result_atoms
	var/item_count = 0
	var/body_count = 0
	for(var/item_type in items)
		var/count = items[item_type] || 1
		if(ispath(item_type, /mob/living/carbon/human) && components)
			body_count += count
		else if(ispath(item_type, /obj/item) || ispath(item_type, /obj/structure) || ispath(item_type, /obj/effect/decal/cleanable))
			item_count += ispath(item_type, /obj/item/stack) ? 1 : count
		else
			practice_message("Для этого рецепта используйте обычный обряд: его результат или условие нельзя выдать как предмет.")
			return FALSE
	if(!item_count && !body_count)
		return FALSE
	arena.prune_supplies()
	arena.prune_targets()
	if(item_count + body_count > ANTAG_TRAINING_BATCH_LIMIT || arena.supply_count + item_count > ANTAG_TRAINING_SUPPLY_LIMIT || length(arena.targets) + body_count > ANTAG_TRAINING_TARGET_LIMIT)
		practice_message("Не хватает места в общих лимитах предметов или целей. Освободите место перед выдачей рецепта.")
		return FALSE
	if(body_count && world.time < arena.next_spawn_at)
		return FALSE
	if(!components && !recipe.training_result_available(user))
		practice_message("Предмет этого рецепта уже существует или достигнут его личный предел. Верните либо удалите прежний предмет.")
		return FALSE
	preparing = TRUE
	next_supply_at = world.time + ANTAG_TRAINING_PRACTICE_DELAY
	if(body_count)
		arena.next_spawn_at = next_supply_at
	var/issued = 0
	for(var/item_type in items)
		var/count = items[item_type] || 1
		var/is_stack = ispath(item_type, /obj/item/stack)
		for(var/index in 1 to (is_stack ? 1 : count))
			arena.yield_work()
			if(QDELETED(src) || !can_control(user) || arena.resetting || QDELETED(recipe) || heretic.get_knowledge(recipe.type) != recipe)
				preparing = FALSE
				return FALSE
			if(ispath(item_type, /mob/living/carbon/human))
				if(arena.spawn_creature("corpse", "laboratory", FALSE, src))
					issued++
				continue
			if(!components && !recipe.training_result_available(user))
				continue
			var/result_type = item_type
			if(!components && istype(recipe, /datum/eldritch_knowledge/codex_cicatrix))
				var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
				result_type = path?.book_type || item_type
			var/obj/item = arena.issue_item(result_type, get_turf(user), is_stack ? count : 1, src)
			if(!item)
				continue
			if(!components)
				recipe.configure_training_result(item, user)
			issued++
	preparing = FALSE
	practice_message("«[recipe.name]»: выдано [issued] из [item_count + body_count]. Предметы рядом с вами[body_count ? "; тела — в лаборатории" : ""].")
	return issued == item_count + body_count

/datum/eldritch_knowledge/proc/training_result_available(mob/living/user)
	for(var/result_type in result_atoms)
		if(ispath(result_type, /obj/item/heretic_path_relic) && !new_path_relic_available())
			return FALSE
	return TRUE

/datum/eldritch_knowledge/proc/configure_training_result(obj/result, mob/living/user)
	if(istype(result, /obj/item/clothing/suit/hooded/cultrobes/eldritch))
		var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = result
		robes.attune_robes(user)
	if(istype(result, /obj/item/living_heart))
		var/obj/item/living_heart/heart = result
		heart.bind(user.mind)
	if(istype(result, /obj/item/heretic_path_relic))
		var/obj/item/heretic_path_relic/relic = result
		relic.creator = WEAKREF(user.mind)
		relic.knowledge_ref = WEAKREF(src)
		new_path_relic_ref = WEAKREF(relic)

/datum/eldritch_knowledge/base_blade/training_result_available(mob/living/user)
	return recipe_snowflake_check(list(), get_turf(user), list(), user)

/datum/eldritch_knowledge/base_blade/configure_training_result(obj/result, mob/living/user)
	var/obj/item/melee/sickly_blade/duelist/blade = result
	blade.bound_mind = user.mind
	created_blades += WEAKREF(blade)

/datum/antag_training_session/proc/prepare_path(path_id, stage)
	var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
	var/mob/living/user = current_body
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!path || !heretic || !can_control(current_body) || current_body.incapacitated() || preparing || arena.resetting || world.time < next_supply_at)
		return FALSE
	if(heretic.selected_path && heretic.selected_path != path_id)
		practice_message("Для другого пути сначала начните новым персонажем в разделе «Моя роль».")
		return FALSE
	if(!isnum(stage) || !(stage in list(1, 4, 9)))
		return FALSE
	preparing = TRUE
	next_supply_at = world.time + ANTAG_TRAINING_PRACTICE_DELAY
	heretic.knowledge_points = max(heretic.knowledge_points, ANTAG_TRAINING_POINTS)
	for(var/index in 1 to min(stage, length(path.knowledge) - 1))
		arena.yield_work()
		if(QDELETED(src) || !can_control(user) || arena.resetting || QDELETED(heretic) || IS_HERETIC(user) != heretic)
			break
		var/datum/eldritch_knowledge/knowledge_type = path.knowledge[index]
		heretic.total_sacrifices = max(heretic.total_sacrifices, initial(knowledge_type.sacs_needed))
		if(!heretic.get_knowledge(knowledge_type) && !heretic.research_knowledge(knowledge_type, current_body))
			break
	preparing = FALSE
	if(!QDELETED(src) && !finished)
		practice_message("Путь «[path.name]»: изучена ступень [heretic.path_stage]. Ниже выберите рецепт оружия и нажмите «Готовый предмет» либо подготовьте компоненты для обряда.")
	return TRUE

/datum/antag_training_session/proc/stop_practice()
	QDEL_NULL(measurement)
	practice_id = null
	practice_target = null
	practice_complete = FALSE
	practice_hint = null

/datum/antag_training_session/proc/start_practice(id)
	if(!(id in list("combat", "hunt", "medicine")) || !can_control(current_body) || preparing || arena.resetting || world.time < arena.next_spawn_at)
		return FALSE
	if(id == "hunt" && !IS_HERETIC(current_body))
		practice_message("Для подношения выберите программу еретика в разделе «Моя роль».")
		return FALSE
	var/mob/living/previous = practice_target?.resolve()
	if(previous && (!can_manage_target(previous) || previous.client))
		practice_message("Прежняя цель занята другим участником. Завершите упражнение и выберите новую цель.")
		return FALSE
	arena.prune_targets()
	if(length(arena.targets) >= ANTAG_TRAINING_TARGET_LIMIT && !previous)
		practice_message("Достигнут общий предел целей. Удалите свою ненужную цель.")
		return FALSE
	arena.next_spawn_at = world.time + ANTAG_TRAINING_PRACTICE_DELAY
	preparing = TRUE
	stop_practice()
	if(previous)
		QDEL_NULL(previous.mind)
		qdel(previous)
	var/zone_id = id == "combat" ? "range" : "laboratory"
	var/mob/living/carbon/human/target = arena.spawn_creature("human", zone_id, FALSE, src)
	if(!target)
		preparing = FALSE
		return FALSE
	current_body.forceMove(arena.zones[zone_id]["spawn"])
	practice_id = id
	practice_target = WEAKREF(target)
	if(id == "hunt")
		program.target_created(src, target)
	else if(id == "medicine")
		injure_target(target, "brute")
		injure_target(target, "burn")
	measurement = new(target)
	preparing = FALSE
	update_practice()
	practice_message("Цель «[target.name]» подготовлена. [practice_hint]")
	return TRUE

/datum/antag_training_session/proc/update_practice()
	if(!practice_id || practice_complete)
		return
	var/mob/living/carbon/human/target = practice_target?.resolve()
	if(!target || target.client || !can_manage_target(target) || get_area(target) != arena.room)
		measurement?.stop()
		practice_hint = "Цель удалена или занята участником. Завершите упражнение, затем подготовьте новую цель."
		return
	if(practice_id == "combat")
		practice_complete = target.health <= HEALTH_THRESHOLD_CRIT
		practice_hint = practice_complete ? "Цель доведена до крита. Посмотрите результат и повторите попытку." : "Возьмите оружие, выйдите на линию стрельбы и доведите цель до крита. Здоровье и лечение учитываются отдельно."
		var/datum/antagonist/heretic/heretic = IS_HERETIC(current_body)
		var/datum/heretic_path/path = GLOB.heretic_paths[heretic?.selected_path]
		if(!practice_complete && path?.combat_practice)
			practice_hint = "[path.name]: [path.combat_practice] Результат упражнения — довести цель до крита; счётчик измеряет весь урон, а не выполнение приёмов."
	else if(practice_id == "medicine")
		practice_complete = target.stat != DEAD && target.health >= target.maxHealth - 1
		practice_hint = practice_complete ? "Здоровье пациента восстановлено." : "Осмотрите пациента анализатором и вылечите обычными средствами. Комплект первой помощи доступен выше."
	else
		var/datum/antagonist/heretic/heretic = IS_HERETIC(current_body)
		if(!heretic)
			return
		practice_complete = (target.mind in heretic.sacrificed_minds)
		if(practice_complete)
			practice_hint = "Учебное подношение принято. Повтор создаст новую душу."
		else if(heretic.hunt_target != target.mind)
			practice_hint = "Назначение изменилось. В разделе «Цели» назначьте эту учебную цель для охоты."
		else if(!heretic.hunt_target_ready(target))
			practice_hint = "Цель назначена. Призовите своё живое сердце и начертите руну кодексом. Свяжите, оглушите или сбейте цель с ног рядом с руной; крит тоже подходит."
		else
			practice_hint = "Цель обездвижена. Положите своё живое сердце рядом с ней на руне и проведите Обряд возвращения."
	if(practice_complete)
		measurement?.stop()
		practice_message(practice_hint)

/datum/antag_training_measurement
	var/datum/weakref/target_ref
	var/previous_health
	var/damage = 0
	var/healing = 0
	var/last_damage = 0
	var/started_at
	var/critical_after
	var/stopped = FALSE

/datum/heretic_path
	var/combat_practice

/datum/heretic_path/ash
	combat_practice = "После изучения Власти Пепла подожгите цель Хваткой и следите за угольками. Угасание оставляет огненный след: отступите через него, затем вернитесь с клинком."

/datum/heretic_path/rust
	combat_practice = "Хваткой проржавите пол, затем создайте очаг Укоренением и ведите бой клинком на подготовленной территории. Индикатор лечения различает обычный пол, ржавчину и очаг."

/datum/heretic_path/flesh
	combat_practice = "Изучив Живой шов, поразите цель с расстояния: атакующий шов не требует биомассы. Для проверки свиты создайте отдельного мёртвого человека в разделе «Цели» и поднимите его Хваткой; направляйте шов на своего раненого слугу для спасения."

/datum/heretic_path/void
	combat_practice = "Накройте цель Зимним пределом и атакуйте клинком. После изучения Хватки Пустоты обновляйте ею скованность: замедление спадает через четыре секунды без воздействия."

/datum/heretic_path/blade
	combat_practice = "Пополните Темп ударами своего клинка. Изучив Выпад, отойдите и сблизьтесь им снова. Парирование проверяйте с нападающим соперником, оставив вторую руку пустой; неподвижная мишень не атакует."

/datum/heretic_path/moon
	combat_practice = "Создайте отражения, указав сам пол, затем ударьте цель лунным клинком, чтобы направить копии в погоню. После изучения Зеркального обмена выберите свою копию и смените позицию. Следите за уроном после удара двойника."

/datum/heretic_path/cosmic
	combat_practice = "Разместите пару звёзд вдоль свободной линии рядом с целью. Перетащите мишень через нить и сравните урон с обычным ударом; новые звёзды при полном лимите заменяют старые."

/datum/heretic_path/lock
	combat_practice = "Запечатайте свободную клетку рядом с целью и пройдите сквозь свою печать. Снимите её рукой на помощи, чтобы вернуть ключ. Затем атакуйте клинком; печать задаёт границу боя, сама по себе цель до крита не доведёт."

/datum/heretic_path/tide
	combat_practice = "Встаньте так, чтобы за целью была стена, и примените Сброс давления. Следите за направлением волны и положением мишени; ударами гарпунного клинка пополняйте давление между волнами."

/datum/heretic_path/glass
	combat_practice = "Попадите Преломлённым лучом без подготовки. Изучив призмы, поставьте одну сбоку от цели и повторите выстрел в цель: связанная призма тоже наведётся на выбранную клетку. Выстрел в саму призму использует её стрелку."

/datum/heretic_path/blood
	combat_practice = "Свяжите цель, нанесите несколько ударов ланцетом для накопления долга и выберите должника способностью «Связать / взыскать». Не разрывайте видимость во время предупреждения; на разоружении взыскивается только часть долга."

/datum/heretic_path/echo
	combat_practice = "Подойдите к цели на две клетки и примените Последний удар. Сравните мгновенный урон с отложенным повтором по кресту; затем повторите попытку так, чтобы цель была за стеной."

/datum/heretic_path/sand
	combat_practice = "Встаньте рядом с целью по прямой и примените Осыпь. Сравните мгновенный удар с взрывом часов на клетке мишени; в повторной попытке оттащите её с отмеченной клетки до взрыва."

/datum/heretic_path/wax
	combat_practice = "Повернитесь к цели на расстоянии до трёх клеток и примените Снять печать. Проверьте направление веера, затем подходите с клинком, пока цель замедлена."

/datum/heretic_path/spirit
	combat_practice = "Примените Разлучение: первый удар виден в счётчике здоровья. Оттащите цель дальше одной клетки от оставленной души — связь дополнительно бьёт по выносливости, которую этот счётчик не измеряет. Коснитесь чужой души для возврата обола."

/datum/antag_training_measurement/New(mob/living/carbon/target)
	target_ref = WEAKREF(target)
	previous_health = target.health
	RegisterSignal(target, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(sample))

/datum/antag_training_measurement/proc/sample(mob/living/carbon/target)
	SIGNAL_HANDLER
	if(stopped || QDELETED(target))
		return
	var/delta = previous_health - target.health
	previous_health = target.health
	if(!delta)
		return
	if(isnull(started_at))
		started_at = world.time
	if(delta > 0)
		damage += delta
		last_damage = delta
	else
		healing -= delta
	if(isnull(critical_after) && target.health <= HEALTH_THRESHOLD_CRIT)
		critical_after = world.time - started_at

/datum/antag_training_measurement/proc/stop()
	stopped = TRUE
	var/mob/living/target = target_ref?.resolve()
	if(target)
		UnregisterSignal(target, COMSIG_CARBON_UPDATEHEALTH)

/datum/antag_training_measurement/Destroy()
	stop()
	target_ref = null
	return ..()
