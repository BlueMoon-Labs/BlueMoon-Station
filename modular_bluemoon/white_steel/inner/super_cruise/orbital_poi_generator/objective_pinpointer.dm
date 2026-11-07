//WHITE-STEEL PORT: пинпоинтер задания.
//Автоматически наводится на цель текущего задания Авангарда (SSorbits.current_objective).
//Сигнал ловится только на том же Z-уровне, что и цель ("один сектор"), и показывает
//примерное направление, пока цель не окажется в пределах 15 клеток (minimum_range).
/obj/item/pinpointer/objective
	name = "Vanguard objective pinpointer"
	desc = "Ручной трекер, автоматически наводящийся на цель текущего задания Авангарда. \
		Ловит сигнал только в одном секторе с целью и указывает примерное направление, \
		пока вы не окажетесь в пределах 15 клеток от неё."
	icon_state = "pinpointer_centcom"
	item_state = "electronic"
	minimum_range = 10

/obj/item/pinpointer/objective/attack_self(mob/living/user)
	. = ..()
	if(active)
		scan_for_target()
		update_icon()

/obj/item/pinpointer/objective/scan_for_target()
	var/atom/desired_target
	var/datum/orbital_objective/objective = SSorbits.current_objective
	if(objective)
		desired_target = objective.get_target()
	if(QDELETED(desired_target))
		desired_target = null
	if(target == desired_target)
		return
	if(desired_target)
		set_target(desired_target)
	else
		unset_target()
