GLOBAL_LIST_INIT(blood_bond_tier_actions, list(
	"0" = list(/datum/action/cooldown/blood_bond/whisper, /datum/action/cooldown/blood_bond/recruit),
	"1" = list(/datum/action/cooldown/blood_bond/blood_for_blood),
	"2" = list(),
))

/// Пассивки ступеней для вкладки «Связь»: сами живут на датуме и в статус-эффектах
GLOBAL_LIST_INIT(blood_bond_tier_passives, list(
	"0" = list(/datum/blood_bond_passive/sense),
	"1" = list(),
	"2" = list(/datum/blood_bond_passive/fury),
))

/// Тексты пассивки связи; экземпляры не создаются, поля читаются через initial()
/datum/blood_bond_passive
	var/name
	var/desc
	var/bond_how
	var/cooldown_time = 0

/datum/blood_bond_passive/sense
	name = "Чутьё брата"
	desc = "На каждого брата справа сверху висит значок: стрелка показывает, куда идти, подсказка - что с ним (в порядке, ранен, без сознания, мёртв, в наручниках, связь заглушена). Если брат на другом этаже, значок покажет вверх или вниз, а в какую сторону идти, будет написано в подсказке."
	bond_how = "Работает само. Наведите курсор на значок, чтобы прочитать состояние брата."

/datum/action/cooldown/blood_bond
	name = "Blood Bond"
	icon_icon = 'modular_bluemoon/icons/mob/blood_brothers/actions.dmi'
	button_icon_state = null
	button_icon = 'modular_bluemoon/icons/mob/blood_brothers/actions.dmi'
	background_icon_state = "bg_blood_bond"
	check_flags = AB_CHECK_CONSCIOUS
	var/datum/antagonist/brother/brother
	/// Минимальная ступень связи
	var/min_tier = 0
	/// Как применить; показывается в подсказке кнопки и во вкладке «Связь»
	var/bond_how
	/// Состояние луча из effects/blood_brothers.dmi на время bond_do_after()
	var/beam_state
	var/datum/beam/bond_beam

/datum/action/cooldown/blood_bond/Destroy()
	QDEL_NULL(bond_beam)
	brother = null
	return ..()

/datum/action/cooldown/blood_bond/IsAvailable(silent = FALSE)
	. = ..()
	if(!.)
		return
	if(!brother?.team || (brother.owner in brother.team.departed_minds) || brother.is_muted() || brother.team.bond_tier < min_tier)
		return FALSE

/// Кулдаун-кнопка зовёт IsAvailable() без silent на каждом обновлении, поэтому подсказка о глушении - только на нажатие
/datum/action/cooldown/blood_bond/Trigger(trigger_flags, atom/target)
	if(owner && brother?.is_muted())
		owner.balloon_alert(owner, "связь заглушена")
		return FALSE
	return ..()

/datum/action/cooldown/blood_bond/UpdateButton(atom/movable/screen/movable/action_button/button, status_only = FALSE, force = FALSE)
	. = ..()
	if(!button || status_only)
		return
	var/muted_line = brother?.is_muted() ? "<b>Связь заглушена: [brother.mute_text()].</b><br>" : ""
	button.desc = "[muted_line][desc]<br><i>[bond_how]</i>"

/datum/action/cooldown/blood_bond/proc/bond_cooldown()
	return cooldown_time * (brother?.team?.cooldown_multiplier || 1)

/// do_after владельца с лучом beam_state к цели, пока идёт ожидание
/datum/action/cooldown/blood_bond/proc/bond_do_after(atom/target, delay)
	var/mob/living/user = owner
	QDEL_NULL(bond_beam)
	if(beam_state)
		bond_beam = user.Beam(target, beam_state, 'modular_bluemoon/icons/effects/blood_brothers.dmi', delay)
	. = do_after(user, delay, target)
	QDEL_NULL(bond_beam)

/// Тексты способности для окна по типу действия или пассивки
/proc/blood_bond_ability_data(ability_type)
	if(ispath(ability_type, /datum/blood_bond_passive))
		var/datum/blood_bond_passive/passive = ability_type
		return list(
			"name" = initial(passive.name),
			"desc" = initial(passive.desc),
			"how" = initial(passive.bond_how),
			"cooldown" = initial(passive.cooldown_time) / (1 SECONDS),
			"passive" = TRUE,
		)
	var/datum/action/cooldown/blood_bond/action = ability_type
	return list(
		"name" = initial(action.name),
		"desc" = initial(action.desc),
		"how" = initial(action.bond_how),
		"cooldown" = initial(action.cooldown_time) / (1 SECONDS),
		"passive" = FALSE,
	)

/// Лестница связи для окна, все ступени, включая закрытые
/datum/antagonist/brother/proc/bond_ladder_data()
	var/list/ladder = list()
	for(var/tier_key in GLOB.blood_bond_tier_actions)
		var/list/abilities = list()
		for(var/passive_type in GLOB.blood_bond_tier_passives[tier_key])
			abilities += list(blood_bond_ability_data(passive_type))
		for(var/action_type in GLOB.blood_bond_tier_actions[tier_key])
			abilities += list(blood_bond_ability_data(action_type))
		ladder += list(list("tier" = text2num(tier_key), "abilities" = abilities))
	var/datum/blood_oath/oath = team?.oath
	if(length(oath?.extra_actions))
		var/list/oath_abilities = list()
		for(var/action_type in oath.extra_actions)
			oath_abilities += list(blood_bond_ability_data(action_type))
		ladder += list(list("tier" = 0, "abilities" = oath_abilities, "label" = "Клятва «[oath.name]» даёт"))
	for(var/datum/blood_oath/fulfilled as anything in team?.all_fulfilled_oaths())
		if(fulfilled.capstone_type)
			ladder += list(list("tier" = BLOOD_BOND_TIER_MAX, "abilities" = list(blood_bond_ability_data(fulfilled.capstone_type)), "label" = "Венец исполненной клятвы «[fulfilled.name]»"))
	return ladder
