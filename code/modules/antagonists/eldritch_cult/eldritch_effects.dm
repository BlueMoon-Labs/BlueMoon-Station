/obj/effect/eldritch
	name = "руна трансмутации"
	desc = "Круг неизвестных знаков, заполненный густой чёрной смолой."
	anchored = TRUE
	icon_state = ""
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = SIGIL_LAYER
	var/is_in_use = FALSE
	var/ritual_interrupted = FALSE
	var/mob/living/ritual_user
	var/obj/effect/temp_visual/heretic_ritual/ritual_visual
	var/list/reserved_atoms = list()
	var/list/reserved_locations = list()
	var/list/reserved_stack_amounts = list()
	var/list/ascension_body_images = list()
	var/client/ascension_preview_client
	var/datum/mind/ascension_preview_mind
	var/mob/living/carbon/human/stasis_target

/obj/effect/eldritch/Initialize(mapload)
	. = ..()
	var/image/silicon_image = image(icon = 'icons/effects/eldritch.dmi', icon_state = null, loc = src)
	silicon_image.override = TRUE
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/silicons, "heretic_rune", silicon_image)

/obj/effect/eldritch/Destroy()
	if(!ritual_visual && isturf(loc))
		new /obj/effect/temp_visual/heretic_ritual/erase(loc, rune_path)
	release_atoms()
	return ..()

/obj/effect/eldritch/examine(mob/user)
	. = ..()
	if(IS_HERETIC(user))
		. += span_notice("Положите компоненты на руну или рядом с ней и коснитесь круга, чтобы выбрать изученный ритуал. Перемещение компонентов прервёт обряд.")

/obj/effect/eldritch/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!.)
		try_activate(user)

/obj/effect/eldritch/proc/try_activate(mob/living/user)
	if(!IS_HERETIC(user) || user.incapacitated() || !Adjacent(user) || is_in_use)
		return
	is_in_use = TRUE
	INVOKE_ASYNC(src, PROC_REF(activate), user)

/obj/effect/eldritch/attackby(obj/item/item, mob/living/user)
	. = ..()
	if(istype(item, /obj/item/storage/book/bible) || istype(item, /obj/item/nullrod))
		to_chat(user, span_notice("Вы разрушаете ритуальный круг с помощью [item]."))
		qdel(src)

/obj/effect/eldritch/proc/activate(mob/living/user)
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	if(!heretic)
		is_in_use = FALSE
		return
	var/list/rituals = list()
	for(var/knowledge_type in heretic.researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = heretic.researched_knowledge[knowledge_type]
		if(length(knowledge.required_atoms))
			rituals[knowledge.name] = knowledge
	var/choice = tgui_input_list(user, "Какой обряд провести? Компоненты должны лежать на руне или в одной клетке от неё.", "Трансмутация", rituals)
	if(!QDELETED(src) && !QDELETED(user) && IS_HERETIC(user) && !user.incapacitated() && Adjacent(user) && rituals[choice])
		var/datum/eldritch_knowledge/ritual = rituals[choice]
		if(ritual.type == /datum/eldritch_knowledge/spell/basic && !heretic.hunt_target_available(heretic.hunt_target))
			heretic.ensure_hunt_target(user)
		else
			do_ritual(user, ritual)
	if(!QDELETED(src))
		release_atoms()
		is_in_use = FALSE

/obj/effect/eldritch/proc/collect_ritual_atoms(mob/living/user)
	. = list()
	for(var/atom/movable/nearby in range(1, src))
		if(nearby == src || nearby == user || !isturf(nearby.loc) || nearby.invisibility || GLOB.heretic_ritual_reservations[nearby])
			continue
		if(isitem(nearby))
			var/obj/item/item = nearby
			if(item.item_flags & ABSTRACT)
				continue
		. += nearby

/// Подбор с возвратом: нож не должен занимать общее требование «предмет», если он нужен отдельному требованию.
/obj/effect/eldritch/proc/match_recipe_requirements(list/requirements, index, list/candidates, list/usage)
	if(index > length(requirements))
		return TRUE
	var/required_type = requirements[index]
	for(var/atom/movable/candidate in candidates)
		if(!istype(candidate, required_type))
			continue
		var/available = 1
		if(isstack(candidate))
			var/obj/item/stack/stack = candidate
			if(stack.is_cyborg)
				continue
			available = stack.amount
		var/used = usage[candidate] || 0
		if(used >= available)
			continue
		usage[candidate] = used + 1
		if(match_recipe_requirements(requirements, index + 1, candidates, usage))
			return TRUE
		if(used)
			usage[candidate] = used
		else
			usage -= candidate
	return FALSE

/obj/effect/eldritch/proc/select_recipe_atoms(datum/eldritch_knowledge/ritual, list/atoms, list/selected_atoms, list/stack_usage, mob/living/user)
	if(!ritual.recipe_snowflake_check(atoms, get_turf(src), selected_atoms, user))
		return FALSE
	if(istype(ritual, /datum/eldritch_knowledge/final_eldritch))
		for(var/mob/living/carbon/human/body in atoms.Copy())
			if(!(body in selected_atoms))
				atoms -= body
	for(var/mob/living/living_ingredient in atoms.Copy())
		if(living_ingredient.stat != DEAD && !(ritual.type == /datum/eldritch_knowledge/spell/basic && (living_ingredient in selected_atoms)))
			atoms -= living_ingredient
	var/list/usage = list()
	if(!match_recipe_requirements(ritual.required_atoms, 1, atoms, usage))
		return FALSE
	for(var/atom/movable/ingredient in usage)
		selected_atoms |= ingredient
		if(isstack(ingredient))
			stack_usage[ingredient] = usage[ingredient]
	return TRUE

/obj/effect/eldritch/proc/reserve_atoms(list/selected_atoms)
	for(var/atom/movable/ingredient in selected_atoms)
		if(QDELETED(ingredient) || GLOB.heretic_ritual_reservations[ingredient])
			return FALSE
	ritual_interrupted = FALSE
	for(var/atom/movable/ingredient in selected_atoms)
		reserved_atoms |= ingredient
		reserved_locations[ingredient] = ingredient.loc
		GLOB.heretic_ritual_reservations[ingredient] = src
		if(isstack(ingredient))
			var/obj/item/stack/stack = ingredient
			reserved_stack_amounts[stack] = stack.amount
		RegisterSignal(ingredient, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(on_ingredient_changed))
	return TRUE

/obj/effect/eldritch/proc/on_ingredient_changed()
	SIGNAL_HANDLER
	ritual_interrupted = TRUE
	clear_hunt_stasis()
	clear_ascension_body_preview()

/obj/effect/eldritch/proc/apply_hunt_stasis(datum/eldritch_knowledge/ritual, mob/living/user)
	if(ritual.type != /datum/eldritch_knowledge/spell/basic)
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/mob/living/carbon/human/target = heretic?.hunt_target?.current
	if(QDELETED(target) || target.stat == DEAD || !(target in reserved_atoms))
		return
	stasis_target = target
	target.apply_status_effect(/datum/status_effect/grouped/stasis, REF(src))

/obj/effect/eldritch/proc/clear_hunt_stasis()
	if(!QDELETED(stasis_target))
		stasis_target.remove_status_effect(/datum/status_effect/grouped/stasis, REF(src))
	stasis_target = null

/// Подсвечивается только зарезервированная тройка. Appearance тел остаётся нетронутым для остальных игроков.
/obj/effect/eldritch/proc/show_ascension_body_preview(mob/living/user)
	clear_ascension_body_preview()
	if(user != ritual_user || !IS_HERETIC(user))
		return FALSE
	for(var/mob/living/carbon/human/body in reserved_atoms)
		if(body.stat != DEAD || IS_HERETIC(body) || IS_HERETIC_MONSTER(body))
			continue
		var/image/body_image = image(loc = body)
		body_image.appearance = body.appearance
		body_image.appearance_flags |= KEEP_TOGETHER
		body_image.filters += filter(arglist(outline_filter(1, "#54ff73")))
		ascension_body_images += body_image
	if(length(ascension_body_images) != HERETIC_ASCENSION_BODIES)
		clear_ascension_body_preview()
		return FALSE
	ascension_preview_client = user.client
	if(ascension_preview_client)
		ascension_preview_client.images |= ascension_body_images
	ascension_preview_mind = user.mind
	RegisterSignal(user, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_ingredient_changed))
	RegisterSignal(ascension_preview_mind, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING), PROC_REF(on_ingredient_changed))
	return TRUE

/obj/effect/eldritch/proc/clear_ascension_body_preview()
	if(ascension_preview_client)
		ascension_preview_client.images -= ascension_body_images
	ascension_preview_client = null
	if(!QDELETED(ritual_user))
		UnregisterSignal(ritual_user, COMSIG_MOB_CLIENT_LOGOUT)
	if(!QDELETED(ascension_preview_mind))
		UnregisterSignal(ascension_preview_mind, list(COMSIG_MIND_TRANSFER, COMSIG_PARENT_QDELETING))
	ascension_preview_mind = null
	for(var/image/body_image as anything in ascension_body_images)
		body_image.loc = null
	QDEL_LIST(ascension_body_images)

/obj/effect/eldritch/proc/release_atoms()
	clear_hunt_stasis()
	QDEL_NULL(ritual_visual)
	clear_ascension_body_preview()
	if(!QDELETED(ritual_user))
		UnregisterSignal(ritual_user, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	for(var/atom/movable/ingredient in reserved_atoms)
		if(GLOB.heretic_ritual_reservations[ingredient] == src)
			GLOB.heretic_ritual_reservations -= ingredient
		if(!QDELETED(ingredient))
			UnregisterSignal(ingredient, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	reserved_atoms.Cut()
	reserved_locations.Cut()
	reserved_stack_amounts.Cut()
	ritual_user = null

/obj/effect/eldritch/proc/ritual_valid(mob/living/user, datum/eldritch_knowledge/ritual)
	if(QDELETED(src) || QDELETED(user) || ritual_interrupted || user.incapacitated() || !Adjacent(user))
		return FALSE
	if(ritual_user && ritual_user != user)
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	if(!heretic || heretic.get_knowledge(ritual.type) != ritual)
		return FALSE
	for(var/atom/movable/ingredient in reserved_atoms)
		if(QDELETED(ingredient) || ingredient.loc != reserved_locations[ingredient] || !isturf(ingredient.loc) || get_dist(ingredient, src) > 1)
			return FALSE
		if(GLOB.heretic_ritual_reservations[ingredient] != src)
			return FALSE
		if(isstack(ingredient))
			var/obj/item/stack/stack = ingredient
			if(stack.amount != reserved_stack_amounts[stack])
				return FALSE
	var/list/recheck_atoms = reserved_atoms.Copy()
	var/list/recheck_selected = list()
	return ritual.recipe_snowflake_check(recheck_atoms, get_turf(src), recheck_selected, user)

/obj/effect/eldritch/proc/do_ritual(mob/living/user, datum/eldritch_knowledge/ritual)
	var/list/atoms = collect_ritual_atoms(user)
	var/list/selected_atoms = list()
	var/list/stack_usage = list()
	if(!select_recipe_atoms(ritual, atoms, selected_atoms, stack_usage, user))
		to_chat(user, span_warning("Ритуал «[ritual.name]» не готов. [recipe_failure_reason(ritual, user)]"))
		return FALSE
	if(!reserve_atoms(selected_atoms))
		to_chat(user, span_warning("Компоненты уже заняты другим обрядом или исчезли. Дождитесь его окончания либо принесите другие."))
		return FALSE
	ritual_user = user
	apply_hunt_stasis(ritual, user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/final_eldritch/ascension_ritual = ritual
	var/area/ascension_area = get_area(src)
	var/ascension_announced = istype(ascension_ritual) && ascension_ritual.begin_ascension_ritual(user, src)
	if(istype(ascension_ritual) && !ascension_announced)
		release_atoms()
		if(world.time < heretic.ascension_ready_at)
			to_chat(user, span_warning("Завеса ещё укреплена после предупреждения станции. До начала вознесения: [DisplayTimeText(heretic.ascension_ready_at - world.time)]."))
		else
			to_chat(user, span_warning("Завеса ещё не успокоилась. Между попытками начать вознесение должно пройти три минуты."))
		return FALSE
	var/ascension_started_at = world.time
	if(ascension_announced)
		show_ascension_body_preview(user)
	inscribe_path(heretic.selected_path)
	ritual_visual = new(get_turf(src), heretic.selected_path, ritual.ritual_time + 1 SECONDS)
	RegisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(on_ingredient_changed))
	to_chat(user, span_notice("Вы начинаете ритуал «[ritual.name]». Сохраняйте неподвижность и не трогайте компоненты."))
	flick("[icon_state]_active", src)
	playsound(src, 'modular_bluemoon/sound/heretic/ritual_begin.ogg', 50, TRUE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_exponent = 10, ignore_walls = FALSE)
	if(!do_after(user, ritual.ritual_time, src, extra_checks = CALLBACK(src, PROC_REF(ritual_valid), user, ritual)) || !ritual_valid(user, ritual))
		if(ascension_announced && !QDELETED(ascension_ritual))
			ascension_ritual.abort_ascension_ritual(ascension_area, world.time - ascension_started_at)
		release_atoms()
		to_chat(user, span_warning("Ритуал прерван. Компоненты не израсходованы."))
		return FALSE
	// Стопки расходуются поштучно только после успешного завершения обряда.
	var/succeeded = ritual.on_finished_recipe(user, selected_atoms, get_turf(src))
	if(succeeded)
		if(istype(ascension_ritual))
			heretic.update_combat_resource_alert()
		new /obj/effect/temp_visual/heretic_script(get_turf(src), heretic.selected_path)
		for(var/obj/item/stack/stack in stack_usage)
			if(stack in selected_atoms)
				selected_atoms -= stack
				if(!QDELETED(stack))
					stack.use(stack_usage[stack])
		ritual.cleanup_atoms(selected_atoms)
		to_chat(user, span_notice("Ритуал «[ritual.name]» завершён."))
	release_atoms()
	return succeeded

/obj/effect/eldritch/proc/recipe_failure_reason(datum/eldritch_knowledge/ritual, mob/living/user)
	var/list/available_atoms = collect_ritual_atoms(user)
	var/list/missing = list()
	var/list/requirements = list()
	for(var/required_type in ritual.required_atoms)
		requirements[required_type]++
	for(var/required_type in requirements)
		var/available = 0
		for(var/atom/movable/candidate in available_atoms)
			if(!istype(candidate, required_type))
				continue
			if(isliving(candidate))
				var/mob/living/body = candidate
				if(body.stat != DEAD && ritual.type != /datum/eldritch_knowledge/spell/basic)
					continue
			if(isstack(candidate))
				var/obj/item/stack/stack = candidate
				if(!stack.is_cyborg)
					available += stack.amount
			else
				available++
		var/shortfall = requirements[required_type] - available
		if(shortfall > 0)
			missing += "[heretic_ritual_ingredient_name(required_type)] ×[shortfall]"
	if(length(missing))
		return "Не хватает свободных компонентов: [jointext(missing, ", ")]. Компоненты другого незавершённого обряда недоступны."
	if(ritual.type == /datum/eldritch_knowledge/spell/basic)
		return "Нужны ваше живое сердце и назначенная живая цель без сознания."
	if(istype(ritual, /datum/eldritch_knowledge/final_eldritch))
		return "Нужны [HERETIC_ASCENSION_SACRIFICES] назначенных душ и [HERETIC_ASCENSION_BODIES] человеческих тела. Тела еретиков и их слуг не подходят."
	return "Особые условия обряда не выполнены. Проверьте требования выбранного ритуала в кодексе."

/obj/effect/eldritch/big
	icon = 'icons/obj/rune.dmi'
	icon_state = "eld"
	appearance_flags = PIXEL_SCALE

/obj/effect/eldritch/big/Initialize(mapload)
	. = ..()
	transform = matrix() * HERETIC_RUNE_SCALE

/obj/effect/eldritch/huge
	icon = 'icons/obj/rune.dmi'
	icon_state = "eld"

#define HERETIC_NETWORK_INFLUENCE_LIMIT 12

/// Смена тела или повторная выдача роли не сбрасывает личную историю разломов за раунд.
/datum/reality_smash_tracker
	var/list/smashes = list()
	var/list/targets = list()
	var/list/tracked_bodies = list()
	var/list/harvest_counts = list()
	var/list/history_minds = list()
	var/initial_influences_seeded = FALSE
	var/next_influence_at = 0
	var/influence_timer

/datum/reality_smash_tracker/Destroy(force, ...)
	cancel_influence_timer()
	for(var/datum/mind/mind in targets.Copy())
		RemoveMind(mind)
	for(var/datum/mind/mind in history_minds)
		UnregisterSignal(mind, COMSIG_PARENT_QDELETING)
	history_minds.Cut()
	harvest_counts.Cut()
	QDEL_LIST(smashes)
	return ..()

/datum/reality_smash_tracker/proc/ReworkNetwork()
	SIGNAL_HANDLER
	for(var/datum/mind/mind in targets.Copy())
		if(QDELETED(mind))
			RemoveMind(mind)
			continue
		var/mob/old_body = tracked_bodies[mind]
		if(old_body != mind.current)
			if(!QDELETED(old_body))
				UnregisterSignal(old_body, list(COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_CLIENT_LOGOUT))
			tracked_bodies[mind] = mind.current
			if(mind.current)
				RegisterSignal(mind.current, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(ReworkNetwork))
				RegisterSignal(mind.current, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_body_logout))
		for(var/obj/effect/reality_smash/influence in smashes)
			influence.AddMind(mind)

/datum/reality_smash_tracker/proc/on_body_logout(mob/source)
	SIGNAL_HANDLER
	for(var/datum/mind/mind in targets)
		if(tracked_bodies[mind] != source)
			continue
		for(var/obj/effect/reality_smash/influence in smashes)
			influence.RemoveMind(mind)

/datum/reality_smash_tracker/proc/Generate(mob/caller, fake_count = 0)
	if(fake_count)
		for(var/index in 1 to min(fake_count, HERETIC_NETWORK_INFLUENCE_LIMIT))
			var/turf/location = find_spawn_turf()
			if(location)
				var/obj/effect/broken_illusion/trace = new(location)
				trace.fake = TRUE
		return
	if(!length(targets))
		return
	if(!initial_influences_seeded)
		if(length(smashes) < HERETIC_INFLUENCE_INITIAL_COUNT)
			for(var/index in length(smashes) + 1 to HERETIC_INFLUENCE_INITIAL_COUNT)
				if(!RandomSpawnSmash(TRUE))
					break
		// Если станция ещё не готова, первый успешный запуск сохранит стартовый запас.
		initial_influences_seeded = !!length(smashes)
		ReworkNetwork()
	if(!next_influence_at)
		next_influence_at = world.time + HERETIC_INFLUENCE_INTERVAL
	schedule_next_influence()

/datum/reality_smash_tracker/proc/network_influence_limit()
	return min(6 + 2 * length(targets), HERETIC_NETWORK_INFLUENCE_LIMIT)

/datum/reality_smash_tracker/proc/cancel_influence_timer()
	if(influence_timer)
		deltimer(influence_timer)
		influence_timer = null

/// Поздний еретик не получает новую стартовую пачку и не отодвигает существующий срок.
/datum/reality_smash_tracker/proc/schedule_next_influence()
	if(QDELETED(src) || !length(targets) || length(smashes) >= network_influence_limit())
		cancel_influence_timer()
		return
	if(influence_timer)
		return
	influence_timer = addtimer(CALLBACK(src, PROC_REF(spawn_scheduled_influence)), max(1, next_influence_at - world.time), TIMER_STOPPABLE)

/datum/reality_smash_tracker/proc/spawn_scheduled_influence()
	cancel_influence_timer()
	if(QDELETED(src) || !length(targets) || length(smashes) >= network_influence_limit())
		return FALSE
	if(world.time < next_influence_at)
		schedule_next_influence()
		return FALSE
	if(!initial_influences_seeded)
		// Generate мог прийти до готовности карты; первый запас всё ещё ограничен тремя.
		next_influence_at = world.time + HERETIC_INFLUENCE_INTERVAL
		Generate()
		return FALSE
	var/spawned = RandomSpawnSmash(TRUE)
	// После простоя появляется максимум один разлом, пропущенные интервалы не копятся.
	next_influence_at = world.time + HERETIC_INFLUENCE_INTERVAL
	if(spawned)
		ReworkNetwork()
		for(var/datum/mind/mind in targets)
			var/datum/antagonist/heretic/heretic = mind.has_antag_datum(/datum/antagonist/heretic)
			if(!heretic || heretic.role_removed || heretic.influences_harvested >= HERETIC_INFLUENCE_LIMIT || !mind.current || mind.current.stat == DEAD)
				continue
			to_chat(mind.current, span_eldritch("На станции приоткрылся новый разлом. За завесой снова шепчут."))
	schedule_next_influence()
	return spawned

/datum/reality_smash_tracker/proc/find_spawn_turf()
	if(!length(GLOB.the_station_areas))
		return null
	for(var/attempt in 1 to 30)
		var/turf/location = get_safe_random_station_turf()
		if(!location || !is_station_level(location.z))
			continue
		var/list/nearby = range(1, location)
		if(locate(/obj/effect/reality_smash) in nearby)
			continue
		if(locate(/obj/effect/broken_illusion) in nearby)
			continue
		return location
	return null

/datum/reality_smash_tracker/proc/RandomSpawnSmash(deferred = FALSE)
	if(length(smashes) >= HERETIC_NETWORK_INFLUENCE_LIMIT)
		return FALSE
	var/turf/location = find_spawn_turf()
	if(!location)
		return FALSE
	new /obj/effect/reality_smash(location, src)
	if(!deferred)
		ReworkNetwork()
	return TRUE

/datum/reality_smash_tracker/proc/AddMind(datum/mind/heretic)
	if(QDELETED(heretic))
		return
	var/datum/antagonist/heretic/heretic_datum = heretic.has_antag_datum(/datum/antagonist/heretic)
	if(heretic_datum)
		heretic_datum.influences_harvested = max(heretic_datum.influences_harvested, harvest_counts[heretic] || 0)
	track_history_mind(heretic)
	if(!(heretic in targets))
		targets |= heretic
		RegisterSignal(heretic, COMSIG_MIND_TRANSFER, PROC_REF(ReworkNetwork))
	Generate()
	ReworkNetwork()

/datum/reality_smash_tracker/proc/on_mind_deleted(datum/mind/source)
	SIGNAL_HANDLER
	RemoveMind(source)
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	history_minds -= source
	harvest_counts -= source
	GLOB.heretic_sacrificed_minds -= source
	for(var/obj/effect/reality_smash/influence in smashes)
		influence.harvested_minds -= source
		influence.harvesting_minds -= source
	for(var/datum/antagonist/heretic/heretic in GLOB.antagonists)
		heretic.sacrificed_minds -= source
		if(heretic.hunt_target == source)
			heretic.set_hunt_target(null)

/// История живёт до удаления разума, даже если роль уже снята.
/datum/reality_smash_tracker/proc/track_history_mind(datum/mind/mind)
	if(QDELETED(mind) || (mind in history_minds))
		return
	history_minds |= mind
	RegisterSignal(mind, COMSIG_PARENT_QDELETING, PROC_REF(on_mind_deleted))

/datum/reality_smash_tracker/proc/RemoveMind(datum/mind/heretic)
	if(!heretic)
		return
	UnregisterSignal(heretic, COMSIG_MIND_TRANSFER)
	var/mob/old_body = tracked_bodies[heretic]
	if(!QDELETED(old_body))
		UnregisterSignal(old_body, list(COMSIG_MOB_CLIENT_LOGIN, COMSIG_MOB_CLIENT_LOGOUT))
	tracked_bodies -= heretic
	targets -= heretic
	for(var/obj/effect/reality_smash/influence in smashes)
		influence.RemoveMind(heretic)
	schedule_next_influence()

/datum/reality_smash_tracker/proc/RandomRiftName(obj/rift, set_name = "", use_afteruse = FALSE)
	var/static/list/prefixes = list("тревожное", "мимолётное", "шепчущее", "сокрытое", "забытое", "далёкое")
	var/static/list/suffixes = list("присутствие", "воспоминание", "видение", "мерцание", "эхо", "наваждение")
	var/base = set_name || "[pick(prefixes)] [pick(suffixes)]"
	rift.name = use_afteruse ? "отголосок: [base]" : base

/obj/effect/broken_illusion
	name = "пронзённая реальность"
	desc = "В воздухе дрожит тёмный след. При взгляде на него трудно вспомнить, о чём вы только что думали."
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "pierced_illusion"
	anchored = TRUE
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	alpha = 0
	var/fake = FALSE

/obj/effect/broken_illusion/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(show_presence)), 5 SECONDS)
	QDEL_IN(src, 3 MINUTES)
	var/image/silicon_image = image('icons/effects/eldritch.dmi', src, null, OBJ_LAYER)
	silicon_image.override = TRUE
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/silicons, "pierced_reality", silicon_image)

/obj/effect/broken_illusion/proc/show_presence()
	animate(src, alpha = 220, time = 5 SECONDS)

/obj/effect/broken_illusion/proc/remove_presence()
	qdel(src)

/obj/effect/broken_illusion/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(. || !ishuman(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return
	touch_mansus(user)

/obj/effect/broken_illusion/attack_tk(mob/user)
	if(isliving(user) && !IS_HERETIC(user) && !IS_HERETIC_MONSTER(user))
		touch_mansus(user, telekinetic = TRUE)

/obj/effect/broken_illusion/examine(mob/user)
	. = ..()
	if(!IS_HERETIC(user))
		. += span_warning("Кто-то недавно потревожил завесу в этом месте. Не касайтесь разрыва: он запоминает прикосновение и ранит тех, кто тянется к нему снова.")

/obj/effect/reality_smash
	name = "разрыв реальности"
	icon = 'icons/effects/eldritch.dmi'
	anchored = TRUE
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	invisibility = INVISIBILITY_OBSERVER
	var/image_state = "reality_smash"
	var/list/minds = list()
	var/list/harvested_minds = list()
	var/list/harvesting_minds = list()
	var/list/visible_clients = list()
	var/image/img
	var/datum/weakref/trace_ref
	var/datum/weakref/network_ref

/obj/effect/reality_smash/Initialize(mapload, datum/reality_smash_tracker/network)
	. = ..()
	network ||= GLOB.reality_smash_track
	network_ref = WEAKREF(network)
	network.smashes |= src
	img = image(icon, src, image_state, OBJ_LAYER)
	network.RandomRiftName(src)

/obj/effect/reality_smash/Destroy()
	var/datum/reality_smash_tracker/network = network_ref?.resolve()
	if(!QDELETED(network))
		network.smashes -= src
		network.schedule_next_influence()
	network_ref = null
	on_destroy()
	return ..()

/obj/effect/reality_smash/proc/on_destroy()
	for(var/datum/mind/mind in minds.Copy())
		RemoveMind(mind)
	harvested_minds.Cut()
	harvesting_minds.Cut()
	img = null

/obj/effect/reality_smash/proc/AddMind(datum/mind/heretic)
	var/client/old_client = visible_clients[heretic]
	if(old_client)
		old_client.images -= img
	visible_clients -= heretic
	minds |= heretic
	var/datum/antagonist/heretic/heretic_datum = heretic?.has_antag_datum(/datum/antagonist/heretic)
	if(!heretic_datum || heretic_datum.influences_harvested >= HERETIC_INFLUENCE_LIMIT || (heretic in harvested_minds))
		return
	var/client/current_client = heretic.current?.client
	if(current_client)
		current_client.images |= img
		visible_clients[heretic] = current_client

/obj/effect/reality_smash/proc/RemoveMind(datum/mind/heretic)
	var/client/old_client = visible_clients[heretic]
	if(old_client)
		old_client.images -= img
	visible_clients -= heretic
	minds -= heretic

/obj/effect/reality_smash/proc/can_harvest(mob/living/user, obj/item/forbidden_book/book)
	if(QDELETED(src) || QDELETED(user) || QDELETED(book) || user.incapacitated() || !Adjacent(user) || !(book in user.GetAllContents()))
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	return heretic && heretic.influences_harvested < HERETIC_INFLUENCE_LIMIT && !(user.mind in harvested_minds)

/obj/effect/reality_smash/proc/harvest(mob/living/user, obj/item/forbidden_book/book)
	if(!can_harvest(user, book) || (user.mind in harvesting_minds))
		return FALSE
	var/datum/mind/researcher = user.mind
	var/datum/antagonist/heretic/original_heretic = IS_HERETIC(user)
	harvesting_minds |= researcher
	to_chat(user, span_notice("Вы вслушиваетесь в шёпот разлома..."))
	var/completed = do_after(user, 10 SECONDS, src, extra_checks = CALLBACK(src, PROC_REF(can_harvest), user, book))
	harvesting_minds -= researcher
	if(QDELETED(src) || !completed || user.mind != researcher || IS_HERETIC(user) != original_heretic || !can_harvest(user, book))
		return FALSE
	var/datum/antagonist/heretic/heretic = researcher.has_antag_datum(/datum/antagonist/heretic)
	harvested_minds |= researcher
	heretic.influences_harvested++
	var/datum/reality_smash_tracker/network = network_ref?.resolve()
	if(!QDELETED(network))
		network.harvest_counts[researcher] = heretic.influences_harvested
	heretic.knowledge_points++
	heretic.refresh_book_ui()
	if(!trace_ref?.resolve())
		var/obj/effect/broken_illusion/trace = new(get_turf(src))
		trace_ref = WEAKREF(trace)
	if(!QDELETED(network))
		network.ReworkNetwork()
	to_chat(user, span_notice("Вы получили 1 очко знаний. Исследовано разломов: [heretic.influences_harvested]/[HERETIC_INFLUENCE_LIMIT]. Дальнейший путь требует подношений."))
	return TRUE

#undef HERETIC_NETWORK_INFLUENCE_LIMIT
