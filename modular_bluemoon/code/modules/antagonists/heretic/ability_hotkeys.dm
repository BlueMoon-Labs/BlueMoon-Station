/datum/antagonist/heretic
	var/list/ability_hotkey_types = list(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)

/datum/antagonist/heretic/proc/format_ability_hotkey_help(datum/preferences/preferences)
	var/datum/keybinding/grasp = GLOB.keybindings_by_name["ability_slot_1"]
	var/datum/keybinding/cancel = GLOB.keybindings_by_name["cancel_ability"]
	var/datum/keybinding/drop = GLOB.keybindings_by_name["drop_item"]
	return "Хватка Мансуса: [grasp.format_keys(preferences)]. Отмена подготовки: [cancel.format_keys(preferences)] или [drop.format_keys(preferences)]. Остальные сочетания — в подсказках кнопок и в кодексе («Знания»). Переназначение — в настройках клавиш: «Способность 1–10»."

/datum/action/spell_action/format_tooltip(mob/viewer, base_description)
	. = ..()
	if(viewer != owner || !IS_HERETIC(viewer))
		return
	var/datum/antagonist/heretic/heretic = IS_HERETIC(viewer)
	var/list/spells = list()
	heretic.collect_combat_spells(spells)
	if(!(target in spells))
		return
	var/obj/effect/proc_holder/spell/spell = target
	var/slot = heretic.ability_hotkey_types.Find(spell.type)
	if(!slot || slot > ABILITY_HOTKEY_SLOTS)
		return
	var/datum/preferences/preferences = viewer.client?.prefs
	var/datum/keybinding/binding = GLOB.keybindings_by_name["ability_slot_[slot]"]
	var/datum/keybinding/cancel = GLOB.keybindings_by_name["cancel_ability"]
	var/datum/keybinding/drop = GLOB.keybindings_by_name["drop_item"]
	. += "<br><b>Горячая клавиша:</b> [html_encode(binding.format_keys(preferences))] (Способность [slot])."
	. += "<br><b>Отмена подготовки:</b> [html_encode(cancel.format_keys(preferences))] или [html_encode(drop.format_keys(preferences))]. Клавиши можно переназначить в настройках управления."

/datum/antagonist/heretic/proc/collect_combat_spells(list/spells)
	for(var/knowledge_type in researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = researched_knowledge[knowledge_type]
		if(!QDELETED(knowledge.combat_power))
			spells |= knowledge.combat_power
		if(istype(knowledge, /datum/eldritch_knowledge/base_moon))
			var/datum/eldritch_knowledge/base_moon/moon = knowledge
			spells |= moon.reflection_spell
		if(istype(knowledge, /datum/eldritch_knowledge/base_cosmic))
			var/datum/eldritch_knowledge/base_cosmic/cosmic = knowledge
			spells |= cosmic.manifest_spell
		if(istype(knowledge, /datum/eldritch_knowledge/base_lock))
			var/datum/eldritch_knowledge/base_lock/lock = knowledge
			spells |= lock.seal_spell
		if(istype(knowledge, /datum/eldritch_knowledge/spell) && !istype(knowledge, /datum/eldritch_knowledge/spell/summon))
			var/datum/eldritch_knowledge/spell/spell_knowledge = knowledge
			if(!QDELETED(spell_knowledge.granted_spell))
				spells |= spell_knowledge.granted_spell
		if(istype(knowledge, /datum/eldritch_knowledge/final_eldritch))
			var/datum/eldritch_knowledge/final_eldritch/final_knowledge = knowledge
			spells |= final_knowledge.ascension_spell_instances
	for(var/obj/effect/proc_holder/spell/spell as anything in spells.Copy())
		if(QDELETED(spell) || !(spell in owner?.spell_list))
			spells -= spell
			continue
		ability_hotkey_types |= spell.type

/datum/antagonist/heretic/activate_ability_hotkey(mob/living/user, slot)
	if(role_removed || owner?.current != user || user.mind != owner)
		return FALSE
	var/list/spells = list()
	collect_combat_spells(spells)
	if(slot < 1 || slot > ABILITY_HOTKEY_SLOTS || slot > length(ability_hotkey_types))
		return FALSE
	for(var/obj/effect/proc_holder/spell/spell as anything in spells)
		if(spell.type != ability_hotkey_types[slot])
			continue
		if(istype(spell, /obj/effect/proc_holder/spell/targeted/touch))
			var/obj/effect/proc_holder/spell/targeted/touch/touch_spell = spell
			if(touch_spell.attached_hand)
				return touch_spell.cancel_cast(user)
		if(user.ranged_ability == spell)
			spell.remove_ranged_ability(span_notice("Прицеливание отменено."))
			return TRUE
		if(user.incapacitated())
			to_chat(user, span_warning("Сейчас вы не можете использовать способность."))
			return TRUE
		spell.Trigger(user, FALSE)
		return TRUE
	return FALSE
