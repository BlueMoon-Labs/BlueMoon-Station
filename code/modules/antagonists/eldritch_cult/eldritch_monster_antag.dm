/**
 * Проверяет, годится ли тело для подъёма в слуги еретика.
 *
 * Возвращает причину отказа (готовую строку для еретика) или null, если препятствий нет.
 */
/proc/heretic_conversion_block_reason(mob/living/carbon/human/target)
	if(!ishuman(target))
		return "Мансус не находит в этом теле плоти, за которую можно ухватиться."
	if(IS_HERETIC_MONSTER(target))
		return "Это тело уже поднято чужой волей."
	if(IS_HERETIC(target))
		return "Этот разум уже принадлежит Мансусу и не станет ничьим рабом."
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		return "Разум этого тела закрыт щитом - хватка соскальзывает."
	if(isrobotic(target))
		return "Это не плоть, а машина. Поднимать нечего."
	if(istype(target.dna?.species, /datum/species/skeleton))
		return "От этого тела остались одни кости - плоть уже кто-то забрал."
	if(target.mind?.unconvertable)
		return "Этот разум невозможно подчинить."
	return null

///Tracking reasons
/datum/antagonist/heretic_monster
	name = "Древний ужас"
	roundend_category = "Heretics"
	antagpanel_category = "Heretic Beast"
	antag_moodlet = /datum/mood_event/heretics
	job_rank = ROLE_HERETIC
	antag_hud_type = ANTAG_HUD_HERETIC
	antag_hud_name = "heretic_beast"
	show_in_antagpanel = FALSE
	soft_antag = TRUE //BLUEMOON ADD - дружелюбные, малозначимые гостроли не должны считаться за антагонистов (ломает динамик)
	///Датум еретика, которому подчинён этот монстр.
	var/datum/antagonist/master
	///Имя хозяина на момент обращения: нужно, когда хозяина уже нет, а объяснить роль всё ещё надо.
	var/master_name
	///До какого максимума здоровья ужимается тело. Ноль - тело не трогаем (призванным монстрам своё здоровье менять не надо).
	var/health_cap = 0
	///Максимум здоровья тела до обращения, чтобы вернуть его при снятии роли.
	var/pre_conversion_max_health = 0
	///Кнопка "кто я такой" в панели действий: без неё игрок остаётся без единого источника информации о роли.
	var/datum/action/heretic_monster_briefing/briefing_button

/datum/antagonist/heretic_monster/Destroy()
	QDEL_NULL(briefing_button)
	master = null
	return ..()

/datum/antagonist/heretic_monster/admin_add(datum/mind/new_owner, mob/admin)
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has heresized [key_name_admin(new_owner)].")
	log_admin("[key_name(admin)] has heresized [key_name(new_owner)].")

/**
 * Привязывает монстра к его еретику и выдаёт цель.
 *
 * Вызывать ДО add_antag_datum(): приветствие уходит игроку внутри on_gain(), и если хозяин
 * ещё не проставлен, игрок узнаёт о своей роли из сообщения, в котором нет ни хозяина, ни целей.
 */
/datum/antagonist/heretic_monster/proc/set_master(datum/antagonist/new_master)
	master = new_master
	var/mob/living/master_mob = new_master?.owner?.current
	master_name = master_mob?.real_name

	var/datum/objective/master_objective = new
	master_objective.owner = owner
	master_objective.explanation_text = "Помогай своему хозяину[master_name ? " ([master_name])" : ""] всем, чем можешь."
	master_objective.completed = TRUE
	objectives += master_objective

/datum/antagonist/heretic_monster/on_gain()
	//set_master() обычно отрабатывает до выдачи датума, когда owner ещё пуст - проставляем владельца целям здесь.
	for(var/datum/objective/objective as anything in objectives)
		if(!objective.owner)
			objective.owner = owner
	return ..()

/datum/antagonist/heretic_monster/greet()
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ecult_op.ogg', 100, FALSE, pressure_affected = FALSE)//subject to change
	send_briefing()

/datum/antagonist/heretic_monster/farewell()
	to_chat(owner, span_boldannounce("Хватка Мансуса разжимается. [master_name ? "[master_name] больше не властен" : "Чужая воля больше не властна"] над тобой, и ты снова принадлежишь себе."))

///Имя хозяина: живое, пока хозяин цел, и запомненное при обращении, когда его уже нет.
/datum/antagonist/heretic_monster/proc/get_master_name()
	var/mob/living/master_mob = master?.owner?.current
	return master_mob?.real_name || master_name

/**
 * Полный инструктаж по роли.
 *
 * Отправляется при обращении, при переносе разума в новое тело и по кнопке в панели действий -
 * игрок обязан иметь возможность в любой момент перечитать, кто он и что ему можно.
 */
/datum/antagonist/heretic_monster/proc/send_briefing(mob/living/receiver)
	receiver = receiver || owner?.current
	if(!receiver)
		return
	var/resolved_master = get_master_name()
	to_chat(receiver, span_boldannounce("Ты - [name], поднятый из мёртвых слуга еретика[resolved_master ? " по имени [resolved_master]" : ""]."))
	to_chat(receiver, span_danger(briefing_text()))
	to_chat(receiver, span_danger("Мансус признаёт тебя своим: клинки еретика не бьют тебя по рукам и разбиваются тобой ради телепортации, \
		его одежда и тигли работают в твоих руках, а ловушки культа тебя не трогают."))
	to_chat(receiver, span_danger("Ты - не самостоятельный антагонист. Твоя единственная цель - помогать хозяину; своей игры у тебя нет."))
	owner?.announce_objectives()

///Текст, объясняющий конкретный вид слуги. Переопределяется подтипами.
/datum/antagonist/heretic_monster/proc/briefing_text()
	return "Твоё тело выпрошено у Мансуса и держится только чужой волей."

/datum/antagonist/heretic_monster/apply_innate_effects(mob/living/mob_override)
	. = ..()
	//Родитель зовёт нас как из on_gain() (без аргумента), так и из on_body_transfer() (с новым телом).
	//Опора на owner.current во втором случае промахивается: разум к этому моменту уже переехал.
	var/mob/living/affected = mob_override || owner?.current
	if(!affected)
		return
	add_antag_hud(antag_hud_type, antag_hud_name, affected)
	affected.faction |= "heretics"
	apply_health_cap(affected)
	if(!briefing_button)
		briefing_button = new(src, src)
	briefing_button.Grant(affected)

/datum/antagonist/heretic_monster/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/affected = mob_override || owner?.current
	if(!affected)
		return
	remove_antag_hud(antag_hud_type, affected)
	affected.faction -= "heretics"
	restore_health_cap(affected)
	briefing_button?.Remove(affected)

/datum/antagonist/heretic_monster/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	//Разум переехал в новое тело (клон, пересадка мозга) вместе с ролью - игрок обязан
	//узнать, что рабство переехало с ним, иначе он снова остаётся без единого сообщения.
	//Клиент прицепляется к телу уже после on_body_transfer(), поэтому ждём следующего тика.
	addtimer(CALLBACK(src, PROC_REF(send_briefing)), 1 SECONDS)

///Ужимает тело до положенного слуге максимума здоровья, запоминая исходный.
/datum/antagonist/heretic_monster/proc/apply_health_cap(mob/living/affected)
	if(!health_cap || affected.maxHealth <= health_cap)
		return
	if(!pre_conversion_max_health)
		pre_conversion_max_health = affected.maxHealth
	affected.setMaxHealth(health_cap)
	affected.updatehealth()

///Возвращает телу его прежний максимум здоровья при снятии роли.
/datum/antagonist/heretic_monster/proc/restore_health_cap(mob/living/affected)
	if(!health_cap || affected.maxHealth > health_cap)
		return
	affected.setMaxHealth(pre_conversion_max_health || initial(affected.maxHealth))
	affected.updatehealth()

/datum/antagonist/heretic_monster/ghoul
	name = "Гуль"

/datum/antagonist/heretic_monster/ghoul/briefing_text()
	return "Плоть твоего тела истончилась: со стороны ты выглядишь как хаск, а твоего здоровья осталось \
		лишь [health_cap] единиц - убить тебя теперь куда проще, чем прежде."

/datum/antagonist/heretic_monster/voiceless_dead
	name = "Безмолвный мертвец"

/datum/antagonist/heretic_monster/voiceless_dead/briefing_text()
	return "Ритуал забрал твой голос: говорить ты больше не можешь. Взамен твоё тело крепче обычного гуля - \
		[health_cap] очков здоровья, но выглядишь ты всё тем же хаском."

/**
 * Кнопка в панели действий, по которой слуга в любой момент перечитывает свой инструктаж.
 *
 * Живёт на самом антаг-датуме, а не на теле, чтобы переезжать вместе с ролью в новое тело.
 */
/datum/action/heretic_monster_briefing
	name = "Кто я такой?"
	desc = "Напоминает, кем ты стал, кому служишь и что тебе теперь доступно."
	button_icon_state = "round_end"
	background_icon_state = "bg_ecult"
	var/datum/antagonist/heretic_monster/monster_datum

/datum/action/heretic_monster_briefing/New(Target, datum/antagonist/heretic_monster/monster_datum)
	. = ..()
	src.monster_datum = monster_datum
	if(monster_datum)
		name = "Кто я такой? ([monster_datum.name])"

/datum/action/heretic_monster_briefing/Destroy()
	if(monster_datum?.briefing_button == src)
		monster_datum.briefing_button = null
	monster_datum = null
	return ..()

/datum/action/heretic_monster_briefing/Trigger()
	if(!monster_datum || !owner)
		return
	monster_datum.send_briefing(owner)

/datum/action/heretic_monster_briefing/IsAvailable()
	return TRUE
