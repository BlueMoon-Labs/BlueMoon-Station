/datum/eldritch_knowledge
	var/name = "Основы запретного знания"
	var/desc = ""
	/// Одно предложение для лида записи в кодексе.
	var/summary
	/// Факты записи по одному на строку.
	var/list/details
	/// Одна из HERETIC_ROLE_*.
	var/role
	var/gain_text = ""
	var/cost = 0
	var/sacs_needed = 0
	var/list/required_atoms = list()
	var/list/result_atoms = list()
	var/route = PATH_SIDE
	var/ritual_time = 5 SECONDS
	var/ritual_hint = ""
	var/list/ritual_hints
	/// Причина последнего провала on_finished_recipe; руна показывает её исполнителю и пишет в лог.
	var/finish_failure_reason
	/// Слабые ссылки на созданные этим знанием клинки, старые первыми; общий предел HERETIC_BLADE_LIMIT. Ленивый список: только LAZY*-макросы, пустой - null.
	var/list/created_blades

/datum/eldritch_knowledge/New()
	. = ..()
	if(!desc && summary && length(details))
		desc = "[summary] [jointext(details, " ")]"
	if(!ritual_hint && length(ritual_hints))
		ritual_hint = jointext(ritual_hints, " ")
	if(!combat_resource_desc && length(resource_rules))
		combat_resource_desc = jointext(resource_rules, " ")

/datum/eldritch_knowledge/proc/on_gain(mob/user)
	if(user && gain_text)
		to_chat(user, span_eldritch(gain_text))
	on_body_gain(user)
	bind_innate(user)

/datum/eldritch_knowledge/proc/on_lose(mob/user)
	innate?.unbind()
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

/// Причина отказа обряда, не зависящая от компонентов на руне, или null.
/datum/eldritch_knowledge/proc/recipe_block_reason(mob/living/user)
	return blade_limit_reason(user)

/datum/eldritch_knowledge/proc/crafts_blade()
	for(var/result_type in result_atoms)
		if(ispath(result_type, /obj/item/melee/sickly_blade))
			return TRUE
	return FALSE

/datum/eldritch_knowledge/proc/prune_blades()
	for(var/datum/weakref/blade_ref as anything in created_blades)
		if(!blade_ref?.resolve())
			LAZYREMOVE(created_blades, blade_ref)

/// Старейший свой клинок не при еретике: на полу, в чужих руках или в контейнере.
/datum/eldritch_knowledge/proc/reclaimable_blade(mob/living/user)
	for(var/datum/weakref/blade_ref as anything in created_blades)
		var/obj/item/melee/sickly_blade/blade = blade_ref.resolve()
		if(blade && get_atom_on_turf(blade) != user)
			return blade

/datum/eldritch_knowledge/proc/blade_limit_reason(mob/living/user)
	if(!crafts_blade())
		return null
	prune_blades()
	if(LAZYLEN(created_blades) < HERETIC_BLADE_LIMIT || reclaimable_blade(user))
		return null
	return "Достигнут предел связанных клинков: [HERETIC_BLADE_LIMIT], и все они при вас. Новый клинок рассыпает старейший из тех, что вы уронили, отдали или потеряли."

/datum/eldritch_knowledge/proc/crumble_blade(obj/item/melee/sickly_blade/blade, reason = "при создании нового клинка")
	LAZYREMOVE(created_blades, WEAKREF(blade))
	var/turf/place = get_turf(blade)
	var/mob/holder = get_atom_on_turf(blade, /mob)
	if(ismob(holder))
		to_chat(holder, span_warning("[blade] рассыпается в пепел прямо у вас в руках."))
	if(place)
		place.visible_message(span_warning("[blade] темнеет и рассыпается пеплом."))
		new /obj/effect/decal/cleanable/ash(place)
		playsound(place, 'modular_bluemoon/sound/heretic/blade_crumble.ogg', 40, TRUE)
	log_game("HERETIC BLADE: [blade] рассыпается [reason] в [AREACOORD(place)].")
	qdel(blade)

/// Новый клинок сверх предела рассыпает старейший из тех, что не при еретике.
/datum/eldritch_knowledge/proc/track_blade(obj/item/melee/sickly_blade/blade, mob/living/user)
	prune_blades()
	while(LAZYLEN(created_blades) >= HERETIC_BLADE_LIMIT)
		var/obj/item/melee/sickly_blade/oldest = reclaimable_blade(user)
		if(!oldest)
			break
		crumble_blade(oldest)
	LAZYADD(created_blades, WEAKREF(blade))

/// Причина не начинать обряд, который иначе сорвётся на середине, или null.
/datum/eldritch_knowledge/proc/ritual_start_reason(mob/living/user, turf/location, duration)
	return null

/// Причина для living/incapacitated(): что именно мешает исполнителю обряда.
/proc/heretic_incapacitated_reason(mob/living/user)
	if(user.stat == DEAD)
		return "Вы не можете действовать: вы погибли."
	if(user.stat || user.IsUnconscious())
		return "Вы не можете действовать: вы потеряли сознание."
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic?.ascended && (user.IsStun() || user.IsParalyzed()))
		return "Вы не можете действовать: вас оглушили."
	if(!heretic?.ascended && (user.combat_flags & COMBAT_FLAG_HARD_STAMCRIT))
		return "Вы не можете действовать: вы выбились из сил."
	if(user.restrained(ignore_grab = heretic?.ascended))
		return "Вы не можете действовать: вас связали или держат в захвате."
	if(IS_IN_STASIS(user))
		return "Вы не можете действовать: вас держит стазис."
	return "Вы не можете действовать: оглушены, связаны или без сознания."

/datum/eldritch_knowledge/proc/ritual_still_valid(mob/living/user, list/atoms, turf/ritual_turf)
	return !ritual_invalid_reason(user, atoms, ritual_turf)

/datum/eldritch_knowledge/proc/ritual_invalid_reason(mob/living/user, list/atoms, turf/ritual_turf)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(QDELETED(src) || !heretic || heretic.get_knowledge(type) != src)
		return "Знание обряда больше недоступно."
	if(heretic_incapacitated(user))
		return heretic_incapacitated_reason(user)
	if(!user.Adjacent(ritual_turf))
		return "Вы отошли от руны."
	if(!length(atoms))
		return "Компоненты обряда исчезли."
	var/obj/effect/eldritch/rune = GLOB.heretic_ritual_reservations[atoms[1]]
	if(QDELETED(rune))
		return "Руна больше недоступна."
	if(!rune.ritual_valid(user, src))
		return rune.ritual_interrupt_reason || "Обряд прерван."
	for(var/atom/ingredient as anything in atoms)
		if(GLOB.heretic_ritual_reservations[ingredient] != rune || QDELETED(ingredient) || !isturf(ingredient.loc) || get_dist(ingredient, ritual_turf) > 1 || ingredient.z != ritual_turf.z)
			return "Компонент обряда перемещён или удалён."
	return null

/datum/eldritch_knowledge/proc/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!length(result_atoms))
		return FALSE
	var/limit_reason = blade_limit_reason(user)
	if(limit_reason)
		finish_failure_reason = limit_reason
		return FALSE
	for(var/result_type in result_atoms)
		var/atom/result = new result_type(loc)
		if(istype(result, /obj/item/melee/sickly_blade))
			track_blade(result, user)
	return TRUE

/datum/eldritch_knowledge/proc/cleanup_atoms(list/atoms)
	for(var/atom/ingredient as anything in atoms.Copy())
		if(!isliving(ingredient) && !QDELETED(ingredient))
			atoms -= ingredient
			qdel(ingredient)

/datum/eldritch_knowledge/proc/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	return FALSE

/// Клик Хваткой не вплотную; TRUE тратит заряд руки.
/datum/eldritch_knowledge/proc/on_mansus_grasp_ranged(atom/target, mob/user, click_parameters)
	return FALSE

/datum/eldritch_knowledge/proc/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	return

/datum/eldritch_knowledge/proc/on_eldritch_blade_damage(mob/living/target, mob/living/user, strike_damage)
	return

/datum/eldritch_knowledge/proc/on_ranged_attack_eldritch_blade(atom/target, mob/user, click_parameters)
	return

/datum/eldritch_knowledge/spell
	var/obj/effect/proc_holder/spell/spell_to_add
	var/obj/effect/proc_holder/spell/granted_spell
	var/spell_ready_at = 0

/datum/eldritch_knowledge/spell/on_body_gain(mob/living/user)
	if(!user?.mind || !spell_to_add || !QDELETED(granted_spell))
		return
	granted_spell = new spell_to_add
	if(granted_spell.charge_type == "recharge" && spell_ready_at > world.time)
		granted_spell.charge_counter = max(0, granted_spell.charge_max - (spell_ready_at - world.time))
		granted_spell.start_recharge()
	user.mind.AddSpell(granted_spell)

/datum/eldritch_knowledge/spell/on_body_lose(mob/living/user)
	if(!QDELETED(granted_spell) && granted_spell.charge_type == "recharge")
		spell_ready_at = world.time + (granted_spell.recharging ? max(0, granted_spell.charge_max - granted_spell.charge_counter) : 0)
	// Mind сам убирает удалённый экземпляр из spell_list по сигналу.
	QDEL_NULL(granted_spell)

/datum/eldritch_knowledge/spell/Destroy()
	QDEL_NULL(granted_spell)
	return ..()

/datum/eldritch_knowledge/curse
	ritual_hints = list(
		"Дополнительно положите предмет с отпечатками цели в центр руны: он не заменяет ингредиент рецепта.",
		"Этот предмет останется после обряда, остальное израсходуется.",
	)
	role = HERETIC_ROLE_RITUAL
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
		if(!can_target(user, victim))
			continue
		if(fingerprints[md5(victim.dna.uni_identity)])
			choices["[length(choices) + 1]. [victim.real_name]"] = victim
	if(!length(choices))
		to_chat(user, span_warning("Отпечатки на подношении не принадлежат доступной цели."))
		return FALSE
	var/choice = tgui_input_list(user, "Выберите цель проклятия", "Проклятие", choices)
	var/mob/living/victim = choices[choice]
	if(!choice || !can_target(user, victim) || !ritual_still_valid(user, atoms, get_turf(loc)) || victim.check_magic_resistance())
		return FALSE
	end_curse(victim)
	curse(victim)
	active_curses[victim] = addtimer(CALLBACK(src, PROC_REF(end_curse), victim), timer, TIMER_STOPPABLE)
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(on_cursed_deleted))
	log_combat(user, victim, "наложил [name] на")
	return TRUE

/datum/eldritch_knowledge/curse/proc/can_target(mob/living/user, mob/living/carbon/human/victim)
	return !QDELETED(victim) && victim.dna && victim != user && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim) && user.training_origin == victim.training_origin

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
	ritual_hints = list(
		"После обряда нужен игрок-призрак, согласный стать вашим слугой.",
		"Если никто не откликнется, компоненты сохранятся, а позвать снова можно через 90 секунд.",
		"Учитываются предел этого призыва и общий предел свиты.",
	)
	role = HERETIC_ROLE_RITUAL
	var/mob/living/mob_to_summon
	var/summon_limit = 2
	var/summoning = FALSE

/datum/eldritch_knowledge/summon/recipe_block_reason(mob/living/user)
	return servant_poll_wait_reason()

/datum/eldritch_knowledge/summon/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	return ..() && !recipe_block_reason(user)

/datum/eldritch_knowledge/summon/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(summoning || !mob_to_summon || length(flesh_servants) >= summon_limit || !heretic?.can_add_servant())
		finish_failure_reason = "Этот призыв уже занят или достиг предела в [summon_limit] слуг."
		return FALSE
	summoning = TRUE
	var/mob/living/summoned = new mob_to_summon(loc)
	if(heretic.simulated)
		summoning = FALSE
		summoned.mind_initialize()
		var/datum/antagonist/heretic_monster/servant = new
		servant.show_in_roundend = FALSE
		servant.soft_antag = TRUE
		servant.set_master(heretic)
		summoned.mind.add_antag_datum(servant)
		track_flesh_servant(servant)
		to_chat(user, span_notice("Создан учебный слуга без игрока. Опрос призраков не требуется."))
		return TRUE
	var/list/mob/dead/observer/candidates = list()
	if(!servant_poll_wait_reason())
		to_chat(user, span_notice("Мансус ищет душу для [summoned.name]. Пока идёт отклик, не отходите от руны и не трогайте компоненты."))
		candidates = poll_servant_candidates("Хотите стать [summoned.name], слугой [user.real_name]?", summoned, HERETIC_SERVANT_POLL_DURATION)
	summoning = FALSE
	if(!length(candidates) && summon_soulless(user, atoms, loc, summoned))
		return TRUE
	finish_failure_reason = summon_poll_failure_reason(user, atoms, loc, candidates, summoned)
	var/mob/dead/observer/chosen = finish_failure_reason ? null : pick(candidates)
	if(!finish_failure_reason && (QDELETED(chosen) || !chosen.client))
		finish_failure_reason = "Откликнувшаяся душа ушла до вселения."
	if(finish_failure_reason)
		qdel(summoned)
		return FALSE
	summoned.forceMove(get_turf(loc))
	summoned.key = chosen.key
	var/datum/antagonist/heretic_monster/servant = new
	servant.set_master(IS_HERETIC(user))
	summoned.mind.add_antag_datum(servant)
	track_flesh_servant(servant)
	summon_ensouled(summoned, servant.master)
	message_admins("[key_name_admin(user)] призвал [key_name_admin(summoned)] в [ADMIN_VERBOSEJMP(summoned)].")
	log_game("[key_name(user)] призвал [key_name(summoned)] в [AREACOORD(summoned)].")
	return TRUE

/datum/eldritch_knowledge/summon/proc/summon_poll_failure_reason(mob/living/user, list/atoms, loc, list/candidates, mob/living/summoned)
	if(!length(candidates))
		return servant_poll_came_back_empty("Ни одна душа не откликнулась.")
	if(QDELETED(summoned) || summoned.stat == DEAD)
		return "Призванное тело погибло до вселения."
	var/invalid_reason = ritual_invalid_reason(user, atoms, get_turf(loc))
	if(invalid_reason)
		return invalid_reason
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(length(flesh_servants) >= summon_limit || !heretic.can_add_servant())
		return "Свита заполнилась, пока шёл отклик."
	return null

/datum/eldritch_knowledge/summon/on_lose(mob/user)
	release_flesh_servants()
	return ..()

/datum/eldritch_knowledge/final_eldritch
	ritual_hints = list(
		"Любое вознесение делает вас целью всей станции и даёт общую стойкость.",
		"Здоровья 150, на ногах вы держитесь до крита, ушибы и ожоги слабее на 40%, по выносливости проходит лишь 30% урона.",
		"Оглушения, сбивания, обездвиживание и потеря сознания вчетверо короче, раны не замедляют.",
		"Оглушение и чужой захват не мешают приёмам пути; наручники, сон и стазис - мешают.",
		"Снотворное и нарколепсия не усыпляют, электрошок почти не действует.",
		"Дышать не нужно, холод и давление не страшны, наручники рвутся за 5 секунд.",
		"Имплант защиты разума вашу магию не глушит.",
		"Если вас 5 секунд не ранят, каждые 2 секунды заживает по 2 ушиба и 2 ожога; кровь восполняется сама.",
		"После вознесения побег клинком закрыт.",
		"Экипаж видит при осмотре, что станы и снотворное вас почти не берут, а светошумовые валят после завесы явления.",
		"Смерть снимает всё это, оживление возвращает.",
		"Уже на обряде над станцией встаёт Знак пути и звучит небо; вознёсшись, вы затмеваете им планету, со смертью он тускнеет.",
		"Финальный обряд проводится только на станции: шахта, Лаваленд и шаттлы вне станции не подходят.",
		"Открытый космос не годится, даже на своей площадке с воздухом.",
		"После отлёта эвакуационного шаттла со станции вознесение уже не начать и не завершить.",
	)
	role = HERETIC_ROLE_ASCENSION
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	ritual_time = 30 SECONDS
	var/finished = FALSE
	var/simulated = FALSE
	var/list/ascension_traits = list()
	var/list/ascension_spells = list()
	var/mob/living/applied_body
	var/list/ascension_spell_instances = list()
	var/list/ascension_spell_ready_at = list()

/datum/eldritch_knowledge/final_eldritch/New()
	var/list/hints = ritual_hints.Copy()
	hints.Insert(2,
		"Нужны [HERETIC_ASCENSION_BODIES] трупа людей, которыми управлял игрок: экипаж, гости, антагонисты. Ищите их в морге.",
		"Первые [HERETIC_ASCENDED_EMERGENCE_SECONDS] секунд - явление: оглушения не действуют, урон ещё на [HERETIC_ASCENDED_EMERGENCE_DAMAGE_CUT]% слабее.",
		"Явление видно всем: вокруг вас дрожит завеса, а когда она спадает, экипаж слышит это и снова может вас ранить.",
	)
	ritual_hints = hints
	return ..()

/proc/heretic_ascension_in_open_space(atom/rune_loc)
	var/turf/rune_turf = get_turf(rune_loc)
	if(!rune_turf)
		return TRUE
	return istype(get_area(rune_turf), /area/space) && !SSmapping.level_trait(rune_turf.z, ZTRAIT_RESERVED)

/// Место и время финального обряда; учебный еретик на полигоне проверяется только на открытый космос.
/datum/eldritch_knowledge/final_eldritch/proc/ascension_block_reason(mob/living/user, turf/ritual_turf)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(heretic_ascension_in_open_space(ritual_turf))
		return "Финальный обряд нельзя провести в зоне открытого космоса, даже на своей площадке с воздухом. Начертите руну в помещении станции."
	if(heretic?.simulated)
		return null
	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		return "Эвакуационный шаттл уже покинул станцию: смена окончена, и завеса больше не разорвётся."
	if(!ritual_turf || !is_station_level(ritual_turf.z))
		return "Финальный обряд проводится только на станции, а руна сейчас в зоне «[get_area_name(ritual_turf, TRUE) || "вне карты"]». Шахта, Лаваленд, аванпосты и шаттлы вне станции не подходят."
	return null

/// Годится только труп, которым когда-то управлял игрок: очеловеченные мартышки и пустые тела отклоняются.
/proc/heretic_ascension_body_valid(mob/living/carbon/human/body, mob/living/user)
	if(!istype(body) || body == user || body.stat != DEAD || IS_HERETIC(body) || IS_HERETIC_MONSTER(body))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !!(heretic?.simulated || body.mind || body.last_mind)

/// Какие тела годятся для вознесения, где их искать и сколько подходящих уже лежит у руны.
/proc/heretic_ascension_body_hint(list/available_atoms, mob/living/user)
	var/valid = 0
	var/unsuitable = 0
	for(var/mob/living/carbon/human/body in available_atoms)
		if(body == user || body.stat != DEAD)
			continue
		if(heretic_ascension_body_valid(body, user))
			valid++
		else
			unsuitable++
	return "Годятся трупы людей, которыми когда-либо управлял игрок: экипаж, гости станции, чужие антагонисты. Ищите их в морге - выньте из холодильника или мешка и положите на руну или рядом. Мартышки, пустые клоны, живые, еретики и их слуги не подходят. Сейчас у руны подходящих тел: [valid] из [HERETIC_ASCENSION_BODIES][unsuitable ? ", неподходящих: [unsuitable]" : ""]."

/datum/eldritch_knowledge/final_eldritch/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(finished || !heretic || heretic.ascended || heretic.total_sacrifices < HERETIC_ASCENSION_SACRIFICES)
		return FALSE
	if(heretic_ascension_in_open_space(loc))
		return FALSE
	var/list/bodies = list()
	for(var/mob/living/carbon/human/victim in atoms)
		if(!heretic_ascension_body_valid(victim, user))
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
	simulated = heretic.simulated
	heretic.ascended = TRUE
	heretic.refresh_objective_completion()
	heretic.refresh_book_ui()
	GLOB.heretic_sky.ascend(src, get_turf(loc) || get_turf(user))
	log_game("[key_name(user)] завершает вознесение [name] в [AREACOORD(user)].")
	announce_ascension(user)
	on_body_gain(user)
	user.apply_status_effect(/datum/status_effect/heretic_emergence)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/on_body_gain(mob/living/user)
	if(!finished || !user?.mind || user.stat == DEAD || applied_body == user)
		return
	if(applied_body)
		on_body_lose(applied_body)
	applied_body = user
	GLOB.heretic_sky.rise(src)
	apply_ascension_presence(user)
	for(var/trait in ascension_traits)
		ADD_TRAIT(user, trait, REF(src))
	user.apply_status_effect(/datum/status_effect/heretic_ascended)
	for(var/spell_type in ascension_spells)
		var/obj/effect/proc_holder/spell/spell = new spell_type
		if(spell.charge_type == "recharge" && ascension_spell_ready_at[spell_type] > world.time)
			// Откат может быть длиннее charge_max (гибель червя Плоти): отрицательный счётчик доходит до заряда за весь срок.
			spell.charge_counter = spell.charge_max - (ascension_spell_ready_at[spell_type] - world.time)
			spell.start_recharge()
		ascension_spell_instances += spell
		user.mind.AddSpell(spell)

/datum/eldritch_knowledge/final_eldritch/on_body_lose(mob/living/user)
	if(!applied_body)
		return
	GLOB.heretic_sky.fall(src)
	remove_ascension_presence()
	for(var/trait in ascension_traits)
		REMOVE_TRAIT(applied_body, trait, REF(src))
	applied_body.remove_status_effect(/datum/status_effect/heretic_ascended)
	applied_body = null
	for(var/obj/effect/proc_holder/spell/spell as anything in ascension_spell_instances)
		if(!QDELETED(spell) && spell.charge_type == "recharge")
			ascension_spell_ready_at[spell.type] = world.time + max(0, spell.charge_max - spell.charge_counter)
	QDEL_LIST(ascension_spell_instances)

/datum/eldritch_knowledge/final_eldritch/on_lose(mob/user)
	. = ..()
	GLOB.heretic_sky.end(src)

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
	name = "Обряд возвращения"
	summary = "Обряд живым сердцем над обезвреженной назначенной целью даёт вам знания, а её душу уводит в Мансус."
	details = list(
		"Коснитесь цели живым сердцем или положите сердце и цель на руну; обряд длится 8 секунд и идёт только на станции.",
		"Живая цель подходит, если она в наручниках, оглушена или сбита с ног; цель в крите подходит и без наручников.",
		"Живая жертва даёт 2 очка знаний и 1 побочное и возвращается живой не позже чем через 3 минуты.",
		"Труп назначенной цели даёт 1 очко без побочного; Мансус выбрасывает его в коридор станции.",
		"Оба варианта идут в счёт вознесения; одну душу можно принести лишь раз за раунд.",
		"Круг держит жертву, не даёт истечь кровью, копии её не бьют; сдвиг жертвы или уход еретика от руны срывают обряд.",
		"Знание даёт Хватку Мансуса: 10 ушибов, 60 выносливости и 2 секунды на полу, перезарядка 12 секунд.",
	)
	role = HERETIC_ROLE_RITUAL
	ritual_hints = list(
		"Нужна цель, назначенная в главе «Охота».",
		"Шахта, Лаваленд и шаттлы вне станции не в счёт: тело цели должно лежать на станции.",
		"Не отрубайте цели голову: душа уйдёт в мозг, и тело рядом не примут, пока голову не пришьют обратно.",
		"Руна не обязательна: коснитесь сердцем обезвреженной цели, и обряд пройдёт прямо под её телом.",
		"Сердце после обряда остаётся у вас, труп назначенной цели Мансус выбрасывает в коридор.",
		"Дион приносите живыми: при смерти они распадаются на нимф и не оставляют тела.",
		"Если цель распалась, выберите новую через сердце.",
	)
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
	summary = "Достаёт живое сердце в руку или прячет его за завесой."
	details = list(
		"Потерянное сердце возвращается, если 5 секунд стоять на месте; уничтоженное восстанавливается.",
		"Сердце в чужих руках, чужом рюкзаке или в идущем обряде вернуть нельзя.",
		"Звук призыва слышен только вплотную.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Что-то живое и тёплое откликается на мой зов."
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_summon/heart

/datum/eldritch_knowledge/spell/summon/book
	name = "Зов к кодексу"
	summary = "Достаёт кодекс в руку и открывает его; кодекс в руке прячет за завесу."
	details = list(
		"Потерянный личный кодекс возвращается после 20 секунд неподвижности.",
		"Запертый в шкафу или сумке кодекс возвращается после 60 секунд; уничтоженный восстанавливается.",
		"Книгу в чужом инвентаре или в идущем обряде вернуть нельзя.",
		"Звук слышен только вплотную.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Я могу спрятать кодекс за завесой и призвать его обратно."
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_summon/book

/datum/eldritch_knowledge/living_heart
	name = "Изготовить запасное живое сердце"
	summary = "Сердце, лужица крови и мак дают запасное живое сердце."
	details = list(
		"Сожмите сердце, чтобы найти назначенную цель; Alt-ЛКМ по сердцу назначает новую цель.",
		"Все ваши сердца следят за одной целью.",
		"Для обряда коснитесь сердцем обезвреженной цели или положите их вместе на руну.",
	)
	role = HERETIC_ROLE_RITUAL
	ritual_hints = list(
		"Это запасное сердце: выданное вызывается способностью «Призвать живое сердце».",
		"Потерянное сердце возвращается после 5 секунд неподвижности.",
	)
	gain_text = "Врата Мансуса открылись моему разуму."
	cost = 0
	required_atoms = list(/obj/item/organ/heart,/obj/effect/decal/cleanable/blood,/obj/item/reagent_containers/food/snacks/grown/poppy)
	result_atoms = list(/obj/item/living_heart)
	route = "Start"

/datum/eldritch_knowledge/codex_cicatrix
	name = "Кодекс Рубцов"
	summary = "Глаза, человеческая кожа, библия и ручка дают запасной Кодекс Рубцов."
	details = list(
		"Выданная в начале книга спрятана за завесой: сначала попробуйте «Призвать кодекс».",
		"Потерянный личный кодекс возвращается за 20 секунд неподвижности, из шкафа или сумки - за 60 секунд.",
	)
	role = HERETIC_ROLE_RITUAL
	ritual_hints = list(
		"Это запасная книга: выданную в начале можно вернуть способностью «Призвать кодекс», без всяких компонентов.",
		"Кодекс в чужом инвентаре или в идущем обряде призвать нельзя.",
	)
	gain_text = "Их руки на моём горле, но я их не вижу."
	cost = 0
	required_atoms = list(/obj/item/organ/eyes,/obj/item/stack/sheet/animalhide/human,/obj/item/storage/book/bible,/obj/item/pen)
	result_atoms = list(/obj/item/forbidden_book)
	route = "Start"

/datum/eldritch_knowledge/spell/silence
	name = "Молчание"
	summary = "Лишает выбранную цель голоса на 30 секунд."
	details = list(
		"Укажите живую цель: 30 секунд она не может говорить.",
		"Жертва сразу замечает воздействие. Перезарядка 3 минуты.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Они должны держать язык за зубами, потому что ничего не понимают."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/trigger/mute/eldritch
	route = PATH_SIDE
