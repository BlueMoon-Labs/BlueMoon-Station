/datum/status_effect/heretic_void_chill
	id = "heretic_void_chill"
	duration = 4 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_void_chill

/datum/status_effect/heretic_void_chill/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	to_chat(owner, span_warning("Пустота сковывает ваши движения!"))

/datum/status_effect/heretic_void_chill/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	return ..()

/datum/movespeed_modifier/heretic_void_chill
	multiplicative_slowdown = 2
	conflicts_with = /datum/movespeed_modifier/heretic_void_chill

/obj/effect/heretic_combat_zone/void/Initialize(mapload, datum/mind/master)
	. = ..()
	var/datum/movespeed_modifier/chill_modifier = get_cached_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	zone_slowdown.multiplicative_slowdown = chill_modifier.multiplicative_slowdown
	zone_slowdown.conflicts_with = chill_modifier.conflicts_with
	var/mob/living/user = master?.current
	if(!QDELETED(user) && user.stat != DEAD && IS_HERETIC(user))
		tick_zone(user)

/atom/movable/screen/alert/status_effect/heretic_void_chill
	name = "Скованность Пустоты"
	desc = "Магия Пустоты замедляет ваши движения независимо от температуры тела. Эффект проходит через 4 секунды после последнего воздействия. Выйдите из зимнего поля и оторвитесь от еретика, чтобы скованность спала. Повторные воздействия обновляют время, не усиливая замедление."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_void"

/obj/item/melee/sickly_blade/void/examine(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	var/datum/eldritch_knowledge/void_blade_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	if(!upgrade)
		. += span_notice("Для сдвига к отмеченному врагу нужно знание «Ищущий клинок» Пути Пустоты.")
		return
	. += span_notice("Держите клинок в активной руке и нажмите ЛКМ по врагу с Меткой Пустоты вне досягаемости удара, в поле зрения и не дальше 5 клеток. Shift не требуется. Возле цели нужна клетка без препятствий; защита от магии блокирует сдвиг.")
	var/cooldown_text = COOLDOWN_FINISHED(upgrade, blink_cooldown) ? "Ищущий клинок: сдвиг готов." : "Ищущий клинок: сдвиг восстановится через [DisplayTimeText(COOLDOWN_TIMELEFT(upgrade, blink_cooldown))]."
	. += span_notice(cooldown_text)
