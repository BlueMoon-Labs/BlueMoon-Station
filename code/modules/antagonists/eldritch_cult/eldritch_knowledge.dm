/datum/eldritch_knowledge
	var/name = "Основы запретного знания"
	var/desc = "Запретное знание."
	var/gain_text = ""
	var/cost = 0
	var/sacs_needed = 0
	var/list/required_atoms = list()
	var/list/result_atoms = list()
	var/route = PATH_SIDE
	var/ritual_time = 5 SECONDS
	var/ritual_hint = ""

/datum/eldritch_knowledge/proc/on_gain(mob/user)
	if(user && gain_text)
		to_chat(user, span_eldritch(gain_text))
	on_body_gain(user)

/datum/eldritch_knowledge/proc/on_lose(mob/user)
	on_body_lose(user)

/datum/eldritch_knowledge/proc/on_body_gain(mob/living/user)
	return

/datum/eldritch_knowledge/proc/on_body_lose(mob/living/user)
	return

/datum/eldritch_knowledge/proc/on_life(mob/user)
	return

/datum/eldritch_knowledge/proc/on_death(mob/user)
	return

/datum/eldritch_knowledge/proc/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return TRUE

/datum/eldritch_knowledge/proc/ritual_still_valid(mob/living/user, list/atoms, turf/ritual_turf)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(QDELETED(src) || !heretic || heretic.get_knowledge(type) != src || user.incapacitated() || !user.Adjacent(ritual_turf))
		return FALSE
	if(!length(atoms))
		return FALSE
	var/obj/effect/eldritch/rune = GLOB.heretic_ritual_reservations[atoms[1]]
	if(QDELETED(rune) || !rune.ritual_valid(user, src))
		return FALSE
	for(var/atom/ingredient as anything in atoms)
		if(GLOB.heretic_ritual_reservations[ingredient] != rune || QDELETED(ingredient) || !isturf(ingredient.loc) || get_dist(ingredient, ritual_turf) > 1 || ingredient.z != ritual_turf.z)
			return FALSE
	return TRUE

/datum/eldritch_knowledge/proc/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!length(result_atoms))
		return FALSE
	for(var/result_type in result_atoms)
		new result_type(loc)
	return TRUE

/datum/eldritch_knowledge/proc/cleanup_atoms(list/atoms)
	for(var/atom/ingredient as anything in atoms.Copy())
		if(!isliving(ingredient) && !QDELETED(ingredient))
			atoms -= ingredient
			qdel(ingredient)

/datum/eldritch_knowledge/proc/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	return FALSE

/datum/eldritch_knowledge/proc/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	return

/datum/eldritch_knowledge/proc/on_ranged_attack_eldritch_blade(atom/target, mob/user, click_parameters)
	return

/datum/eldritch_knowledge/spell
	var/obj/effect/proc_holder/spell/spell_to_add
	var/obj/effect/proc_holder/spell/granted_spell

/datum/eldritch_knowledge/spell/on_body_gain(mob/living/user)
	if(!user?.mind || !spell_to_add || !QDELETED(granted_spell))
		return
	granted_spell = new spell_to_add
	user.mind.AddSpell(granted_spell)

/datum/eldritch_knowledge/spell/on_body_lose(mob/living/user)
	// Mind сам убирает удалённый экземпляр из spell_list по сигналу.
	QDEL_NULL(granted_spell)

/datum/eldritch_knowledge/spell/Destroy()
	QDEL_NULL(granted_spell)
	return ..()

/datum/eldritch_knowledge/curse
	ritual_hint = "Дополнительно положите предмет с отпечатками цели строго на центральную клетку руны. Он не должен заменять другой ингредиент рецепта. После обряда этот предмет сохранится; остальные компоненты будут израсходованы."
	var/timer = 5 MINUTES
	var/list/fingerprints = list()
	var/list/active_curses = list()

/datum/eldritch_knowledge/curse/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	fingerprints.Cut()
	for(var/obj/item/anchor in atoms)
		if(anchor.loc != loc || !length(anchor.fingerprints) || is_type_in_list(anchor, required_atoms))
			continue
		fingerprints |= anchor.fingerprints
		selected_atoms |= anchor
	return length(fingerprints) > 0

/datum/eldritch_knowledge/curse/cleanup_atoms(list/atoms)
	for(var/obj/item/anchor in atoms.Copy())
		if(!is_type_in_list(anchor, required_atoms))
			atoms -= anchor
	return ..()

/datum/eldritch_knowledge/curse/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/list/choices = list()
	for(var/mob/living/carbon/human/victim as anything in GLOB.human_list)
		if(QDELETED(victim) || !victim.dna || victim == user || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			continue
		if(fingerprints[md5(victim.dna.uni_identity)])
			choices["[length(choices) + 1]. [victim.real_name]"] = victim
	if(!length(choices))
		to_chat(user, span_warning("Отпечатки на подношении не принадлежат доступной цели."))
		return FALSE
	var/choice = tgui_input_list(user, "Выберите цель проклятия", "Проклятие", choices)
	var/mob/living/victim = choices[choice]
	if(!choice || QDELETED(victim) || !ritual_still_valid(user, atoms, get_turf(loc)) || victim.check_magic_resistance())
		return FALSE
	end_curse(victim)
	curse(victim)
	active_curses[victim] = addtimer(CALLBACK(src, PROC_REF(end_curse), victim), timer, TIMER_STOPPABLE)
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(on_cursed_deleted))
	log_combat(user, victim, "наложил [name] на")
	return TRUE

/datum/eldritch_knowledge/curse/proc/end_curse(mob/living/victim)
	if(!(victim in active_curses))
		return
	deltimer(active_curses[victim])
	active_curses -= victim
	UnregisterSignal(victim, COMSIG_PARENT_QDELETING)
	if(!QDELETED(victim))
		uncurse(victim)

/datum/eldritch_knowledge/curse/proc/on_cursed_deleted(mob/living/source)
	SIGNAL_HANDLER
	end_curse(source)

/datum/eldritch_knowledge/curse/on_lose(mob/user)
	for(var/mob/living/victim as anything in active_curses.Copy())
		end_curse(victim)
	return ..()

/datum/eldritch_knowledge/curse/Destroy()
	on_lose(null)
	return ..()

/datum/eldritch_knowledge/curse/proc/curse(mob/living/chosen_mob)
	return

/datum/eldritch_knowledge/curse/proc/uncurse(mob/living/chosen_mob)
	return

/datum/eldritch_knowledge/summon
	ritual_hint = "После обряда нужен игрок-призрак, согласный стать вашим слугой. Если никто не откликнется, компоненты сохранятся. Учитываются предел этого призыва и общий предел свиты."
	var/mob/living/mob_to_summon
	var/summon_limit = 2
	var/summoning = FALSE

/datum/eldritch_knowledge/summon/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(summoning || !mob_to_summon || length(flesh_servants) >= summon_limit || !heretic?.can_add_servant())
		to_chat(user, span_warning("Этот призыв уже занят или достиг предела в [summon_limit] слуг."))
		return FALSE
	summoning = TRUE
	var/mob/living/summoned = new mob_to_summon(loc)
	var/list/mob/dead/observer/candidates = pollCandidatesForMob("Хотите стать [summoned.name], слугой [user.real_name]?", ROLE_HERETIC, null, FALSE, 10 SECONDS, summoned)
	summoning = FALSE
	if(!length(candidates) || QDELETED(summoned) || summoned.stat == DEAD || !ritual_still_valid(user, atoms, get_turf(loc)) || length(flesh_servants) >= summon_limit || !heretic.can_add_servant())
		qdel(summoned)
		return FALSE
	var/mob/dead/observer/chosen = pick(candidates)
	if(QDELETED(chosen) || !chosen.client)
		qdel(summoned)
		return FALSE
	summoned.forceMove(get_turf(loc))
	summoned.key = chosen.key
	var/datum/antagonist/heretic_monster/servant = new
	servant.set_master(IS_HERETIC(user))
	summoned.mind.add_antag_datum(servant)
	track_flesh_servant(servant)
	message_admins("[key_name_admin(user)] призвал [key_name_admin(summoned)] в [ADMIN_VERBOSEJMP(summoned)].")
	log_game("[key_name(user)] призвал [key_name(summoned)] в [AREACOORD(summoned)].")
	return TRUE

/datum/eldritch_knowledge/summon/on_lose(mob/user)
	release_flesh_servants()
	return ..()

/datum/eldritch_knowledge/final_eldritch
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	ritual_time = 30 SECONDS
	var/finished = FALSE
	var/parallax_scene
	var/list/ascension_traits = list()
	var/list/ascension_spells = list()
	var/damage_modifier = 0.75
	var/mob/living/applied_body
	var/list/ascension_spell_instances = list()

/datum/eldritch_knowledge/final_eldritch/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(finished || !heretic || heretic.ascended || heretic.total_sacrifices < HERETIC_ASCENSION_SACRIFICES)
		return FALSE
	var/list/bodies = list()
	for(var/mob/living/carbon/human/victim in atoms)
		if(victim == user || victim.stat != DEAD || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			continue
		bodies |= victim
		if(length(bodies) == HERETIC_ASCENSION_BODIES)
			selected_atoms |= bodies
			return TRUE
	return FALSE

/datum/eldritch_knowledge/final_eldritch/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/list/validated = list()
	if(!recipe_snowflake_check(atoms, loc, validated, user))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	finished = TRUE
	heretic.ascended = TRUE
	heretic.refresh_book_ui()
	if(parallax_scene)
		set_antag_parallax_scene(parallax_scene, "[ANTAG_PARALLAX_TOKEN_HERETIC]-[REF(src)]")
	log_game("[key_name(user)] завершает вознесение [name] в [AREACOORD(user)].")
	announce_ascension(user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/on_body_gain(mob/living/user)
	if(!finished || !user?.mind || user.stat == DEAD || applied_body == user)
		return
	if(applied_body)
		on_body_lose(applied_body)
	applied_body = user
	apply_ascension_presence(user)
	for(var/trait in ascension_traits)
		ADD_TRAIT(user, trait, REF(src))
	if(ishuman(user))
		var/mob/living/carbon/human/human = user
		human.physiology.heretic_ascension_mod = damage_modifier
	for(var/spell_type in ascension_spells)
		var/obj/effect/proc_holder/spell/spell = new spell_type
		ascension_spell_instances += spell
		user.mind.AddSpell(spell)

/datum/eldritch_knowledge/final_eldritch/on_body_lose(mob/living/user)
	if(!applied_body)
		return
	remove_ascension_presence()
	for(var/trait in ascension_traits)
		REMOVE_TRAIT(applied_body, trait, REF(src))
	if(ishuman(applied_body))
		var/mob/living/carbon/human/human = applied_body
		human.physiology.heretic_ascension_mod = 1
	applied_body = null
	QDEL_LIST(ascension_spell_instances)

/datum/eldritch_knowledge/final_eldritch/on_lose(mob/user)
	. = ..()
	if(finished && parallax_scene)
		clear_antag_parallax_scene("[ANTAG_PARALLAX_TOKEN_HERETIC]-[REF(src)]")

/datum/eldritch_knowledge/final_eldritch/on_death(mob/user)
	if(applied_body == user)
		on_body_lose(user)

/datum/eldritch_knowledge/final_eldritch/on_life(mob/living/user)
	if(!applied_body && user?.stat != DEAD)
		on_body_gain(user)

/datum/eldritch_knowledge/final_eldritch/Destroy()
	on_lose(applied_body)
	return ..()

/datum/eldritch_knowledge/final_eldritch/cleanup_atoms(list/atoms)
	. = ..()
	for(var/mob/living/carbon/human/victim in atoms.Copy())
		atoms -= victim
		victim.gib()

/datum/eldritch_knowledge/spell/basic
	ritual_hint = "Нужна назначенная в главе «Охота» цель. Живой человек должен быть связан наручниками, лежать, быть оглушён или без сознания. Ваше живое сердце сохраняется после обряда; труп назначенной цели тоже остаётся на месте."
	name = "Обряд возвращения"
	desc = "Положите своё живое сердце и назначенную цель на руну или рядом. Живую цель достаточно связать наручниками, оглушить или сбить с ног. За 8 секунд руна примет подношение; живую жертву она удерживает и защищает от кровотечения. Перемещение жертвы или прерывание еретика срывает обряд. Живая цель даёт 2 очка знаний и 1 побочное, проходит через Мансус и возвращается живой не позднее чем через 45 секунд. Труп назначенной цели даёт только 1 очко знаний без побочного: тело остаётся на месте, его можно реанимировать. Оба варианта засчитываются для вознесения. Одну душу можно принести лишь однажды за раунд, даже после реанимации."
	gain_text = "За гранью сна мне назвали первое имя."
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/mansus_grasp
	required_atoms = list(/obj/item/living_heart)
	route = "Start"
	ritual_time = 8 SECONDS

/datum/eldritch_knowledge/spell/basic/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.select_hunt_atoms(user, atoms, selected_atoms)

/datum/eldritch_knowledge/spell/basic/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.complete_hunt_ritual(user, atoms, get_turf(loc))

/datum/eldritch_knowledge/spell/basic/cleanup_atoms(list/atoms)
	return

/datum/eldritch_knowledge/spell/summon
	cost = 0
	required_atoms = list()
	route = "Start"

/datum/eldritch_knowledge/spell/summon/heart
	name = "Зов к сердцу"
	desc = "Позволяет призывать и прятать живое сердце в пучине безумия. Остальные услышат очень тихий звук призыва, только вплотную к вам."
	gain_text = "Что-то живое и тёплое откликается на мой зов."
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_summon/heart

/datum/eldritch_knowledge/spell/summon/book
	name = "Зов к кодексу"
	desc = "Позволяет призывать и прятать кодекс в тайных глубинах. Остальные услышат очень тихий звук призыва, только вплотную к вам."
	gain_text = "Я могу дотянуться до своего кодекса сквозь пространство."
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_summon/book

/datum/eldritch_knowledge/living_heart
	name = "Живое сердце"
	desc = "Обычное сердце, лужица крови и мак превращаются в живое сердце. Сожмите его, чтобы найти назначенную цель; Alt-ЛКМ вызывает новое имя. Все ваши сердца отслеживают одну цель. Для Обряда возвращения положите сердце рядом с целью на руну."
	gain_text = "Врата Мансуса открылись моему разуму."
	cost = 0
	required_atoms = list(/obj/item/organ/heart,/obj/effect/decal/cleanable/blood,/obj/item/reagent_containers/food/snacks/grown/poppy)
	result_atoms = list(/obj/item/living_heart)
	route = "Start"

/datum/eldritch_knowledge/codex_cicatrix
	name = "Кодекс Рубцов"
	desc = "Позволяет вам создать запасной Кодекс Рубцов, если вы его потеряли, используя библию, человеческую кожу, ручку и пару глаз."
	gain_text = "Их руки на моём горле, но я их не вижу."
	cost = 0
	required_atoms = list(/obj/item/organ/eyes,/obj/item/stack/sheet/animalhide/human,/obj/item/storage/book/bible,/obj/item/pen)
	result_atoms = list(/obj/item/forbidden_book)
	route = "Start"

/datum/eldritch_knowledge/spell/silence
	name = "Молчание"
	desc = "Сила Мансуса лишает цель голоса на тридцать секунд. Жертва сразу заметит воздействие."
	gain_text = "Они должны держать язык за зубами, потому что ничего не понимают."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/trigger/mute/eldritch
	route = PATH_SIDE
