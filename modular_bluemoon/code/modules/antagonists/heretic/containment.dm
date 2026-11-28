/// Причина, по которой задержанный еретик не может колдовать и разбить клинок, или null.
/proc/heretic_containment_reason(mob/living/user, breaks_cuffs = FALSE)
	if(!istype(user))
		return null
	if(user.restrained(ignore_grab = TRUE) && !(breaks_cuffs && heretic_only_cuffed(user)))
		return "Скованные руки не складывают знаки: в наручниках и смирительной рубашке Мансус не отзывается."
	if(heretic_mindshield_suppressed(user))
		if(!user.has_status_effect(/datum/status_effect/heretic_mindshield))
			user.apply_status_effect(/datum/status_effect/heretic_mindshield)
		return "Щит разума перекрывает зов Мансуса: магия, обряды на руне и побег клинком недоступны. Выход - [IS_HERETIC(user) ? "знание «Разум за завесой» или " : ""]извлечь имплант, подробнее в значке «Щит разума»."
	return null

/// Держат только наручники: ни смирительной рубашки, ни других пут.
/proc/heretic_only_cuffed(mob/living/carbon/user)
	if(!iscarbon(user) || !user.handcuffed || HAS_TRAIT(user, TRAIT_RESTRAINED))
		return FALSE
	var/mob/living/carbon/human/body = user
	return !ishuman(user) || !body.wear_suit?.breakouttime

/proc/heretic_mindshield_suppressed(mob/living/user)
	if(!HAS_TRAIT(user, TRAIT_MINDSHIELD) || HAS_TRAIT(user, TRAIT_HERETIC_ASCENDED))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !heretic?.get_knowledge(/datum/eldritch_knowledge/unshielded_mind)

/// Как снять глушение щитом: знание еретику, извлечение импланта всем.
/proc/heretic_mindshield_way_out(mob/living/user)
	var/datum/eldritch_knowledge/knowledge = /datum/eldritch_knowledge/unshielded_mind
	var/learn = IS_HERETIC(user) ? "изучите в кодексе побочное знание «[initial(knowledge.name)]» (открывается с [GLOB.heretic_side_knowledge[knowledge]]-й ступени пути, стоит [initial(knowledge.cost)] очка; кодекс работает и под щитом) или " : ""
	return "Чтобы вернуть силу, [learn]избавьтесь от импланта: его извлекает хирургическая операция."

/// Пока щит глушит Мансус, значок напоминает, что делать; повторные отказы остаются короткими.
/datum/status_effect/heretic_mindshield
	id = "heretic_mindshield"
	duration = -1
	tick_interval = 2 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/heretic_mindshield

/datum/status_effect/heretic_mindshield/on_apply()
	if(!(IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner)) || !heretic_mindshield_suppressed(owner))
		return FALSE
	. = ..()
	to_chat(owner, span_boldwarning("Щит разума перекрывает зов Мансуса: пока имплант в теле, магия, обряды на руне и побег клинком недоступны. [heretic_mindshield_way_out(owner)]"))

/datum/status_effect/heretic_mindshield/on_creation(mob/living/new_owner)
	. = ..()
	if(linked_alert)
		linked_alert.desc = "Пока имплант в теле, магия, обряды на руне и побег клинком недоступны. [heretic_mindshield_way_out(owner)]"

/datum/status_effect/heretic_mindshield/tick()
	if(!(IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner)) || !heretic_mindshield_suppressed(owner))
		qdel(src)

/atom/movable/screen/alert/status_effect/heretic_mindshield
	name = "Щит разума"
	desc = "Щит разума глушит зов Мансуса."
	icon_state = "mind_control"

/datum/mind
	/// Подсказка, как разжать хватку еретика, приходит раз за раунд.
	var/heretic_capture_hint_seen = FALSE

/// Первая увиденная хватка еретика объясняет экипажу вокруг и самой цели, как её разжать.
/proc/heretic_capture_crew_hint(mob/living/victim)
	for(var/mob/living/witness in get_hearers_in_view(HERETIC_CAPTURE_HINT_RANGE, victim, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS))
		heretic_capture_hint_to(witness, victim)

/proc/heretic_capture_hint_to(mob/living/witness, mob/living/victim)
	if(!witness.mind || witness.mind.heretic_capture_hint_seen || witness.stat != CONSCIOUS || IS_HERETIC(witness) || IS_HERETIC_MONSTER(witness))
		return FALSE
	// В изнанке трясти некому: разовую подсказку бережём для станции.
	if(istype(get_area(victim), /area/heretic_pocket))
		return FALSE
	witness.mind.heretic_capture_hint_seen = TRUE
	. = TRUE
	if(witness == victim)
		to_chat(witness, span_boldwarning("Вас держит хватка еретика - тёмная лужа со щупальцами у ног. Позовите на помощь: если вас потрясут пустой рукой на намерении «Помощь» [DisplayTimeText(HERETIC_CAPTURE_SHAKE_TIME)] подряд, хватка разожмётся."))
	else
		to_chat(witness, span_boldwarning("Тёмная лужа со щупальцами у ног [victim] - хватка еретика. Потрясите [victim] пустой рукой на намерении «Помощь» [DisplayTimeText(HERETIC_CAPTURE_SHAKE_TIME)] подряд, и хватка разожмётся. О еретике сообщите службе безопасности."))

/datum/eldritch_knowledge/unshielded_mind
	name = "Разум за завесой"
	summary = "Щит разума больше не глушит вашу магию, обряды и побег клинком."
	details = list(
		"С имплантом защиты разума магия, обряды на руне и побег клинком остаются доступны.",
		"Наручники и смирительная рубашка по-прежнему держат вас; наручники рвёт только Волна отчаяния.",
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
	var/reason = heretic_containment_reason(user, heretic_breaks_cuffs)
	if(reason)
		heretic_check(user, FALSE, silent, reason)
		if(!silent)
			heretic_fizzle_fx(user)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(heretic_stun_check && heretic && heretic_incapacitated(user, usable_while_grabbed))
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
		target.visible_message(span_warning("Сопротивление под кожей [target] стихает: щит разума встал на место."), span_userdanger("Щит разума смыкается над вашим сознанием, и зов Мансуса глохнет."))
		target.apply_status_effect(/datum/status_effect/heretic_mindshield)
	else
		target.visible_message(span_warning("Сопротивление под кожей [target] стихает: щит разума встал на место."), span_notice("Щит разума смыкается над вашим сознанием, но зов Мансуса проходит сквозь него."))

/obj/item/implant/mindshield/get_data()
	return ..() + "<BR><b>Против культов:</b> пока имплант в теле, последователь запретных путей (еретик) не может колдовать, проводить обряды на руне и уходить через разбитый клинок. Такой носитель сопротивляется: ввод занимает заметно дольше. Вознёсшегося и самых опытных последователей щит не удерживает."

/obj/item/implanter/mindshield/examine(mob/user)
	. = ..()
	. += span_notice("Щит разума глушит магию и обряды еретиков, пока имплант в теле. Еретик сопротивляется вводу, поэтому держите его скованным; сам себе он щит не введёт. Вознёсшегося и самых опытных еретиков щит не удерживает: для них надёжнее смирительная рубашка, а наручники еретик может раз сорвать волной.")

/obj/item/implant/mindshield/removed(mob/target, silent = FALSE, special = 0)
	var/mob/living/owner = imp_in
	. = ..()
	if(. && owner && !heretic_mindshield_suppressed(owner))
		owner.remove_status_effect(/datum/status_effect/heretic_mindshield)
	if(. && !silent && owner?.stat != DEAD && (IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner)) && !heretic_mindshield_suppressed(owner))
		to_chat(owner, span_boldnotice("Щит разума больше не держит вас: Мансус снова слышит ваш зов."))
