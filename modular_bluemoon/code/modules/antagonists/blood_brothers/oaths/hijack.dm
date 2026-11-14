/datum/blood_oath/hijack
	name = "Угон"
	key = "hijack"
	summary = "добыть ценности и доступ на мостик, угнать аварийный шаттл"
	weight = 2
	round_types = list(ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	requires_violence = TRUE
	capstone_type = /datum/action/cooldown/blood_bond/capstone/stash
	kit_items = list(BROTHER_KIT_BREAKIN, /obj/item/clothing/mask/balaclava)

/datum/blood_oath/hijack/available(datum/team/brother_team/for_team)
	return !for_team.training && ..()

/datum/blood_oath/hijack/prepare(datum/team/brother_team/for_team)
	. = ..()
	if(for_team.training)
		return FALSE
	if(!add_loot_steps(for_team))
		return FALSE
	add_step(new /datum/blood_oath_step/hijack_access)
	var/list/loot_names = loot_step_names()
	story = "Станция вам больше не нужна, а её шаттл нужен. Добудьте [loot_names[1]] и [loot_names[2]], достаньте карту с доступом на мостик и уведите аварийный шаттл: несколько раз взломайте его консоль (ALT-клик), каждая попытка поднимает тревогу."
	return TRUE

/datum/blood_oath/hijack/on_sworn()
	. = ..()
	if(!team.training)
		message_admins("Кровные братья [team.name] поклялись угнать аварийный шаттл.")
	log_game("Blood brothers [team.name] swore to hijack the emergency shuttle.")

/datum/blood_oath/hijack/finale_extra_complete()
	return SSshuttle.emergency?.mode == SHUTTLE_ENDGAME && SSshuttle.emergency.is_hijacked()

/datum/blood_oath/hijack/finale_extra_text()
	return "шаттл угнан"

/// Заглушённый и ушедший брат шаттл не взламывает
/datum/antagonist/brother/hijack_speed()
	if(!istype(team?.oath, /datum/blood_oath/hijack))
		return ..()
	if(is_muted() || (owner in team.departed_minds))
		return 0
	return BROTHER_HIJACK_SPEED

/datum/blood_oath_step/hijack_access
	name = "Ключ от мостика"
	desc = "ID-карта с доступом на мостик у любого из братьев."

/datum/blood_oath_step/hijack_access/can_seal(mob/living/sealer)
	for(var/obj/item/card/id/card as anything in brother_team_items(oath.team, /obj/item/card/id))
		if(ACCESS_HEADS in card.GetAccess())
			return TRUE
	return "на брате нет карты с доступом на мостик"

/datum/blood_oath_step/hijack_access/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"
