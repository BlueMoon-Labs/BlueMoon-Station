/// Разделитель REF и токена идентичности в строке меню орбиты. В REF-е двоеточия не
/// бывает, поэтому разбор однозначен, а tgui таскает строку как непрозрачный идентификатор.
#define ORBIT_REF_TOKEN_SEPARATOR ":"

/// Идентификатор POI для окна орбиты: ссылка плюс токен, доказывающий, что за ней тот же атом.
/proc/orbit_poi_ref(atom/movable/poi)
	if(!istype(poi))
		return REF(poi)
	return "[REF(poi)][ORBIT_REF_TOKEN_SEPARATOR][poi.get_follow_token()]"

/datum/orbit_menu
	var/mob/dead/observer/owner
	var/auto_observe = FALSE
	var/compact_mode = TRUE // BLUEMOON ADD - компактный режим без ненужной информации

/datum/orbit_menu/New(mob/dead/observer/new_owner)
	if(!istype(new_owner))
		qdel(src)
	owner = new_owner

/datum/orbit_menu/ui_state(mob/user)
	return GLOB.observer_state

/datum/orbit_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "Orbit")
		ui.open()

/datum/orbit_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if (..())
		return

	switch(action)
		if ("orbit")
			// Строка меню несёт REF и токен идентичности через двоеточие: REF - это индекс в
			// таблице BYOND, и он переиспользуется, как только атом удалён, а список уехал
			// клиенту снимком минуты назад. Без токена locate() честно отдаёт ТО, ЧТО заняло
			// слот, и "in GLOB.mob_list" такую подмену пропускает - оба ведь мобы.
			var/raw_ref = params["ref"]
			var/list/ref_parts = raw_ref ? splittext(raw_ref, ORBIT_REF_TOKEN_SEPARATOR) : list()
			var/ref = length(ref_parts) ? ref_parts[1] : null
			var/expected_token = length(ref_parts) > 1 ? text2num(ref_parts[2]) : 0
			var/atom/movable/poi = (locate(ref) in GLOB.mob_list) || (locate(ref) in GLOB.poi_list)
			if (poi && expected_token && poi.follow_token != expected_token)
				poi = null
			if (poi == null)
				// Список POI лежит в ui_static_data, то есть уезжает клиенту СНИМКОМ при
				// открытии окна и сам по себе больше не обновляется. Через пару минут
				// половина строк в нём указывает на удалённых мобов, и клик по такой
				// строке раньше молча не делал НИЧЕГО - ни следования, ни объяснения.
				// Именно так выглядела жалоба раунда 10127 на "рандомную невозможность
				// орбититься". Промах теперь сам пересобирает список: второй клик по
				// живой цели срабатывает, а мёртвая строка из окна пропадает.
				to_chat(owner, span_warning("Цель уже не существует - список обновлён."))
				update_static_data(owner, ui)
				. = TRUE
				return
			owner.ManualFollow(poi)
			owner.reset_perspective(null)
			if (auto_observe)
				owner.do_observe(poi)
			. = TRUE
		if ("refresh")
			update_static_data(owner, ui)
			. = TRUE
		if ("toggle_observe")
			auto_observe = !auto_observe
			if (auto_observe && owner.orbit_target)
				owner.do_observe(owner.orbit_target)
			else
				owner.reset_perspective(null)
		// BLUEMOON ADD START - компактный режим без ненужной информации
		if ("toggle_compact_mode")
			compact_mode = !compact_mode
			update_static_data(owner, ui)
			. = TRUE
		// BLUEMOON ADD END

/datum/orbit_menu/ui_data(mob/user)
	var/list/data = list()
	data["auto_observe"] = auto_observe
	data["compact_mode"] = compact_mode // BLUEMOON ADD - компактный режим без ненужной информации
	return data

// BLUEMOON EDIT START - правки орбита. В основном, изменение отображения гостролей
/datum/orbit_menu/ui_static_data(mob/user)
	var/list/data = list()
	var/list/alive = list()
	var/list/antagonists = list()
	var/list/dead = list()
	var/list/dead_players = list()
	var/list/ghosts = list()
	var/list/misc = list()
	var/list/npcs = list()
	var/list/ghost_roles = list()

	var/list/pois = getpois(mobs_only = compact_mode, skip_mindless = !compact_mode, specify_dead_role = FALSE)
	for (var/name in pois)
		var/list/serialized = list()
		serialized["name"] = name

		var/poi = pois[name]

		serialized["ref"] = orbit_poi_ref(poi)

		var/mob/M = poi
		if (istype(M))
			if (istype(M, /mob/dead/new_player))
				continue
			if (isobserver(M))
				ghosts += list(serialized)
			else if (M.mind == null && M.stat == DEAD && !compact_mode)
				dead += list(serialized)
			else if (M.mind && M.stat == DEAD)
				dead_players += list(serialized)
			else if (M.mind == null)
				if(!compact_mode)
					npcs += list(serialized)
			else
				if (isswarmer(M)) // BLUEMOON ADD - свармеры уходят в категорию "Ghost-Visible Antagonists"
					serialized["assignment"] = "swarmer"
					serialized["antag"] = "Swarmer"
					antagonists += list(serialized)
					continue
				var/number_of_orbiters = M.orbiters?.orbiters?.len
				if (number_of_orbiters)
					serialized["orbiters"] = number_of_orbiters

				var/datum/mind/mind = M.mind
				var/was_special = FALSE

				for (var/_A in mind.antag_datums)
					var/datum/antagonist/A = _A
					if(istype(A, /datum/antagonist/ghost_role))
						was_special = TRUE
						serialized["role"] = A.name
						ghost_roles += list(serialized)
						break // Я не верю, что гострольки могут быть антагами. Не хочу верить...
					else if (user.client?.holder || A?.show_to_ghosts || GLOB.master_mode == ROUNDTYPE_EXTENDED)
						was_special = TRUE
						serialized["antag"] = A.name
						antagonists += list(serialized)
						break

				var/assignment = "no_id"

				if(ishuman(M)) // Владос уверяет, что это уменьшит лишние такты процессору
					var/obj/item/card/id/card = M.get_idcard()
					if(card)
						assignment = "[ckey(card.get_job_name())]"

				else if(issilicon(M) || isdrone(M)) // Для отображения иконок силиконов в orbit
					if(iscyborg(M))
						assignment = "cyborg"
					else if(isdrone(M))
						assignment = "drone"
					else if(ispAI(M))
						assignment = "pai"
					else if(isAI(M))
						assignment = "ai"

				else if(isbrain(M))
					var/mob/living/brain/brain_mob = M
					var/obj/item/brain_item = brain_mob.container
					if(istype(brain_item, /obj/item/mmi/posibrain))
						assignment = "posibrain"
					else if(istype(brain_item, /obj/item/mmi))
						assignment = "mmibrain"
					else
						assignment = "brain"

				else if(isalien(M))
					assignment = "alien"

				else if(ishostile(M) || iscameramob(M))
					if(isterrorspider(M))
						assignment = "terrorspider"
					else if(isswarmer(M))
						assignment = "swarmer"
					else if(isovermind(M))
						assignment = "blobmind"
					else if(isblobmonster(M))
						assignment = "blobbernaut"

				serialized["assignment"] = assignment

				if (!was_special)
					alive += list(serialized)
		else if(!compact_mode)
			if(istype(poi, /obj/item/deactivated_swarmer) || istype(poi, /obj/effect/mob_spawn/swarmer))
				continue
			misc += list(serialized)

	for (var/atom/A as anything in GLOB.poi_list)
		if(!istype(A, /obj/item/deactivated_swarmer) && !istype(A, /obj/effect/mob_spawn/swarmer))
			continue
		if(!A.loc)
			continue
		var/list/serialized = list()
		var/area/area = get_area(A)
		serialized["name"] = area ? "[A.name] \[[area.name]\]" : A.name
		serialized["ref"] = orbit_poi_ref(A)
		serialized["assignment"] = "swarmer"
		serialized["antag"] = "Swarmer"
		antagonists += list(serialized)

	data["alive"] = alive
	data["antagonists"] = antagonists
	data["dead"] = dead
	data["dead_players"] = dead_players
	data["ghosts"] = ghosts
	data["misc"] = misc
	data["npcs"] = npcs
	data["ghost_roles"] = ghost_roles

	return data
// BLUEMOON EDIT END

/datum/orbit_menu/ui_assets()
	. = ..() || list()
	. += get_asset_datum(/datum/asset/simple/orbit)
	. += get_asset_datum(/datum/asset/spritesheet_batched/jobs)

#undef ORBIT_REF_TOKEN_SEPARATOR
