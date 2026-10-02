/// Причина, по которой задержанный еретик не может колдовать и разбить клинок, или null.
/proc/heretic_containment_reason(mob/living/user)
	if(!istype(user))
		return null
	if(user.restrained(ignore_grab = TRUE))
		return "Скованные руки не складывают знаки: в наручниках и смирительной рубашке Мансус не отзывается."
	if(heretic_mindshield_suppressed(user))
		return "Щит разума перекрывает зов Мансуса. Пока имплант в теле, магия, обряды на руне и побег клинком недоступны."
	return null

/proc/heretic_mindshield_suppressed(mob/living/user)
	if(!HAS_TRAIT(user, TRAIT_MINDSHIELD) || HAS_TRAIT(user, TRAIT_HERETIC_ASCENDED))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !heretic?.get_knowledge(/datum/eldritch_knowledge/unshielded_mind)

/datum/eldritch_knowledge/unshielded_mind
	name = "Разум за завесой"
	summary = "Щит разума больше не глушит вашу магию, обряды и побег клинком."
	details = list(
		"С имплантом защиты разума магия, обряды на руне и побег клинком остаются доступны.",
		"Наручники и смирительная рубашка по-прежнему держат вас.",
		"Вознёсшегося щит не держит и без этого знания.",
	)
	role = HERETIC_ROLE_PASSIVE
	passive_desc = "Имплант защиты разума не подавляет вашу магию, обряды и побег клинком."
	gain_text = "Они поставили замок на дверь, которой у меня больше нет."
	cost = 2

/obj/effect/proc_holder/spell/can_cast(mob/user = usr, skipcharge = FALSE, silent = FALSE)
	. = ..()
	// У всех способностей еретика этот фон кнопки, у чужих его нет.
	if(!. || action_background_icon_state != "bg_ecult")
		return
	var/reason = heretic_containment_reason(user)
	if(reason)
		heretic_check(user, FALSE, silent, reason)
		if(!silent)
			heretic_fizzle_fx(user)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(heretic_stun_check && heretic && !heretic.ascended && user.incapacitated(ignore_grab = usable_while_grabbed))
		heretic_check(user, FALSE, silent)
		if(!silent)
			heretic_fizzle_fx(user)
		return FALSE

/obj/item/implant/mindshield/implant(mob/living/target, mob/user, silent = FALSE)
	if(!istype(target) || !(IS_HERETIC(target) || IS_HERETIC_MONSTER(target)))
		return ..()
	if(user == target)
		to_chat(user, span_warning("Рука не поднимается: Мансус не даёт вам самому запереть свой разум щитом."))
		return FALSE
	if(user)
		target.visible_message(span_warning("Имплант не приживается: под кожей [target] что-то бьётся против щита разума."), span_userdanger("Щит разума пытается сомкнуться над вашим сознанием, и Мансус сопротивляется!"))
		if(!do_after(user, HERETIC_MINDSHIELD_RESIST_TIME, target = target) || QDELETED(src) || QDELETED(target))
			return FALSE
	. = ..()
	if(!. || silent)
		return
	if(heretic_mindshield_suppressed(target))
		target.visible_message(span_warning("Сопротивление под кожей [target] стихает: щит разума встал на место."), span_userdanger("Щит разума смыкается над вашим сознанием, и зов Мансуса глохнет. Пока имплант в теле, магия, обряды на руне и побег клинком недоступны; извлечь его можно хирургически."))
	else
		target.visible_message(span_warning("Сопротивление под кожей [target] стихает: щит разума встал на место."), span_notice("Щит разума смыкается над вашим сознанием, но зов Мансуса проходит сквозь него."))

/obj/item/implant/mindshield/get_data()
	return ..() + "<BR><b>Против культов:</b> пока имплант в теле, последователь запретных путей (еретик) не может колдовать, проводить обряды на руне и уходить через разбитый клинок. Такой носитель сопротивляется: ввод занимает заметно дольше. Вознёсшегося и самых опытных последователей щит не удерживает."

/obj/item/implanter/mindshield/examine(mob/user)
	. = ..()
	. += span_notice("Щит разума глушит магию и обряды еретиков, пока имплант в теле. Еретик сопротивляется вводу, поэтому держите его скованным; сам себе он щит не введёт. Вознёсшегося и самых опытных еретиков щит не удерживает: для них надёжнее наручники.")

/obj/item/implant/mindshield/removed(mob/target, silent = FALSE, special = 0)
	var/mob/living/owner = imp_in
	. = ..()
	if(. && !silent && owner?.stat != DEAD && (IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner)) && !heretic_mindshield_suppressed(owner))
		to_chat(owner, span_boldnotice("Щит разума больше не держит вас: Мансус снова слышит ваш зов."))
