#define WIZARD_RITUAL_RUNES 5
#define WIZARD_RITUAL_CLOWNS "Великое ликование"
#define WIZARD_RITUAL_METEORS "Метеорный апокалипсис"

/proc/get_wizard_ritual_departments(list/station_areas = GLOB.the_station_areas)
	var/static/list/departments = list(
		/area/cargo = "снабжение",
		/area/command = "командный отдел",
		/area/engineering = "инженерный отдел",
		/area/medical = "медицинский отдел",
		/area/science = "научный отдел",
		/area/security = "служба безопасности",
		/area/service = "сервисный отдел",
	)
	var/list/available = list()
	for(var/area/area_type as anything in station_areas)
		if(initial(area_type.outdoors))
			continue
		for(var/department in departments)
			if(ispath(area_type, department))
				available[department] = departments[department]
				break
	return available

/proc/wizard_ritual_departments_available()
	return length(get_wizard_ritual_departments()) >= WIZARD_RITUAL_RUNES

/datum/team/wizard/ritual_coven
	name = "Ковен Великого ритуала"
	member_name = "wizard"
	var/datum/objective/wizard_grand_ritual/ritual

/datum/team/wizard/ritual_coven/proc/prepare_ritual()
	ritual = new
	if(!ritual.prepare(get_wizard_ritual_departments()))
		QDEL_NULL(ritual)
		return FALSE
	ritual.team = src
	objectives += ritual
	return TRUE

/datum/team/wizard/ritual_coven/remove_member(datum/mind/member)
	. = ..()
	if(!length(members))
		ritual?.clear_rune()

/datum/team/wizard/ritual_coven/Destroy()
	QDEL_NULL(ritual)
	return ..()

/datum/antagonist/wizard/ritualist
	name = "Маг-ритуалист"
	outfit_type = /datum/outfit/wizard/ritual_coven
	var/role_brief = "Чертите руны по маршруту. Любой маг ковена может активировать готовую руну."
	var/can_scribe = TRUE
	var/list/starting_spells = list(/obj/effect/proc_holder/spell/targeted/turf_teleport/blink)
	var/datum/objective/wizard_grand_ritual/ritual

/datum/antagonist/wizard/ritualist/on_gain()
	set waitfor = FALSE
	return ..()

/datum/antagonist/wizard/ritualist/equip_wizard()
	. = ..()
	for(var/spell_type in starting_spells)
		owner.AddSpell(new spell_type)

/datum/antagonist/wizard/ritualist/create_objectives()
	var/datum/team/wizard/ritual_coven/coven = wiz_team
	if(istype(coven))
		ritual = coven.ritual
	else
		ritual = new
		ritual.owner = owner
		if(!ritual.prepare(get_wizard_ritual_departments()))
			QDEL_NULL(ritual)
			return ..()
	objectives += ritual
	if(can_scribe)
		owner.AddSpell(new /obj/effect/proc_holder/spell/self/wizard_grand_ritual)
	to_chat(owner, span_arcane("<b>Ваша роль в ковене — [name].</b> [role_brief]"))
	owner.announce_objectives()

/datum/antagonist/wizard/ritualist/Destroy()
	if(ritual && !ritual.team)
		ritual.clear_rune()
	ritual = null
	return ..()

/datum/antagonist/wizard/ritualist/battle_mage
	name = "Боевой маг"
	outfit_type = /datum/outfit/wizard/ritual_coven/battle
	role_brief = "Прикрывайте ковен в бою и защищайте руны. У вас есть огненный шар и магические снаряды."
	can_scribe = FALSE
	starting_spells = list(
		/obj/effect/proc_holder/spell/aimed/fireball,
		/obj/effect/proc_holder/spell/targeted/projectile/magic_missile,
	)

/datum/antagonist/wizard/ritualist/support_mage
	name = "Маг поддержки"
	outfit_type = /datum/outfit/wizard/ritual_coven/support
	role_brief = "Лечите союзников посохом, закрывайте подходы силовой стеной и активируйте руны, пока вас прикрывают."
	can_scribe = FALSE
	starting_spells = list(/obj/effect/proc_holder/spell/targeted/forcewall)

/datum/outfit/wizard/ritual_coven
	name = "Ritual Wizard"
	r_hand = null
	l_hand = null

/datum/outfit/wizard/ritual_coven/battle
	name = "Battle Wizard"
	suit = /obj/item/clothing/suit/wizrobe/red
	head = /obj/item/clothing/head/wizard/red

/datum/outfit/wizard/ritual_coven/support
	name = "Support Wizard"
	suit = /obj/item/clothing/suit/wizrobe/marisa
	head = /obj/item/clothing/head/wizard/marisa
	l_hand = /obj/item/gun/magic/staff/healing

/datum/objective/wizard_grand_ritual
	name = "Великий ритуал"
	var/list/departments
	var/runes_completed = 0
	var/next_rune_at = 0
	var/drawing = FALSE
	var/obj/effect/wizard_grand_rune/active_rune

/datum/objective/wizard_grand_ritual/Destroy()
	clear_rune()
	return ..()

/datum/objective/wizard_grand_ritual/proc/prepare(list/available_departments)
	if(length(available_departments) < WIZARD_RITUAL_RUNES)
		return FALSE
	departments = list()
	var/list/remaining = available_departments.Copy()
	for(var/i in 1 to WIZARD_RITUAL_RUNES)
		var/department = pick(remaining)
		departments[department] = remaining[department]
		remaining -= department
	update_explanation_text()
	return TRUE

/datum/objective/wizard_grand_ritual/update_explanation_text()
	var/list/route = list()
	for(var/department in departments)
		route += departments[department]
	explanation_text = "Завершите Великий ритуал. Начертите и активируйте пять рун по порядку: [route.Join(" → ")]. Выполнено [runes_completed]/[WIZARD_RITUAL_RUNES]."
	if(!completed)
		explanation_text += " Следующий отдел — [departments[departments[runes_completed + 1]]]."

/datum/objective/wizard_grand_ritual/proc/clear_rune()
	QDEL_NULL(active_rune)

/datum/objective/wizard_grand_ritual/proc/get_ritual_wizard(mob/living/user)
	if(QDELETED(user) || user.mind?.current != user)
		return null
	var/datum/antagonist/wizard/ritualist/wizard = user.mind.has_antag_datum(/datum/antagonist/wizard/ritualist)
	if(wizard?.ritual == src && (!team || (user.mind in team.members)))
		return wizard
	return null

/datum/objective/wizard_grand_ritual/proc/can_channel(mob/living/user, turf/tile)
	if(completed || !get_ritual_wizard(user) || user.loc != tile || user.incapacitated())
		return FALSE
	if(!istype(tile, /turf/open/floor) || !is_station_level(tile.z))
		return FALSE
	var/area/room = get_area(tile)
	return istype(room, departments[runes_completed + 1]) && !room.outdoors

/datum/objective/wizard_grand_ritual/proc/draw_rune(mob/living/user)
	var/datum/antagonist/wizard/ritualist/wizard = get_ritual_wizard(user)
	if(!wizard?.can_scribe)
		return FALSE
	if(completed)
		to_chat(user, span_notice("Великий ритуал уже завершён."))
		return FALSE
	if(drawing || active_rune)
		to_chat(user, span_warning("Сначала завершите работу с текущей руной."))
		return FALSE
	if(world.time < next_rune_at)
		to_chat(user, span_warning("Магическая сила восстановится через [DisplayTimeText(next_rune_at - world.time)]."))
		return FALSE
	var/turf/tile = get_turf(user)
	if(!can_channel(user, tile) || (locate(/obj/effect/wizard_grand_rune) in tile))
		to_chat(user, span_warning("Встаньте на свободный пол в нужном отделе. [explanation_text]"))
		return FALSE
	drawing = TRUE
	user.visible_message(span_warning("[user] начинает чертить магические знаки на полу."))
	var/finished_drawing = do_after(user, 5 SECONDS, target = tile)
	drawing = FALSE
	if(!finished_drawing || QDELETED(src) || !can_channel(user, tile) || (locate(/obj/effect/wizard_grand_rune) in tile))
		return FALSE
	active_rune = new(tile, src)
	to_chat(user, span_notice("Любой маг ковена может встать на руну и нажать на неё пустой рукой, чтобы активировать."))
	if(runes_completed >= WIZARD_RITUAL_RUNES - 2)
		priority_announce("Обнаружено [runes_completed == WIZARD_RITUAL_RUNES - 1 ? "критическое" : "сильное"] магическое возмущение в районе [get_area_name(tile)]. Найдите и уничтожьте его источник.", "Магическая аномалия")
	return TRUE

/datum/objective/wizard_grand_ritual/proc/complete_rune(obj/effect/wizard_grand_rune/rune, mob/living/user, meteor_direction = 0)
	if(QDELETED(rune) || rune != active_rune || !can_channel(user, get_turf(rune)))
		return FALSE
	runes_completed++
	completed = runes_completed == WIZARD_RITUAL_RUNES
	clear_rune()
	update_explanation_text()
	for(var/datum/mind/member as anything in get_owners())
		to_chat(member, span_notice(explanation_text))
	if(completed)
		trigger_finale(user, meteor_direction)
	else
		next_rune_at = world.time + 1 MINUTES
	return TRUE

/obj/effect/proc_holder/spell/self/wizard_grand_ritual
	name = "Начертить руну Великого ритуала"
	desc = "Позволяет начертить руну в следующем отделе, указанном в цели Великого ритуала."
	clothes_req = NONE
	charge_max = 5 SECONDS
	action_icon = 'icons/mob/actions/actions_cult.dmi'
	action_icon_state = "draw"

/obj/effect/proc_holder/spell/self/wizard_grand_ritual/cast(mob/living/user)
	var/datum/antagonist/wizard/ritualist/wizard = user.mind?.has_antag_datum(/datum/antagonist/wizard/ritualist)
	var/datum/objective/wizard_grand_ritual/ritual = wizard?.ritual
	if(QDELETED(ritual) || !ritual.draw_rune(user))
		if(!QDELETED(src))
			revert_cast(user)

/obj/effect/wizard_grand_rune
	name = "руна Великого ритуала"
	desc = "Магический узор. Его можно стереть нуль-жезлом или хорошенько отмыть."
	icon = 'icons/obj/rune.dmi'
	icon_state = "4"
	color = "#c276ff"
	anchored = TRUE
	layer = SIGIL_LAYER
	light_range = 2
	light_color = "#c276ff"
	var/datum/objective/wizard_grand_ritual/ritual
	var/channeling = FALSE

/obj/effect/wizard_grand_rune/Initialize(mapload, datum/objective/wizard_grand_ritual/ritual)
	. = ..()
	src.ritual = ritual
	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(clean_rune))
	if(isturf(loc))
		RegisterSignal(loc, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(clean_rune))

/obj/effect/wizard_grand_rune/Destroy()
	if(ritual?.active_rune == src)
		ritual.active_rune = null
	ritual = null
	return ..()

/obj/effect/wizard_grand_rune/proc/clean_rune(datum/source, strength)
	SIGNAL_HANDLER
	if(strength >= CLEAN_MEDIUM)
		qdel(src)

/obj/effect/wizard_grand_rune/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/nullrod) || istype(item, /obj/item/storage/book/bible))
		user.visible_message(span_warning("[user] разрушает руну при помощи [item]."))
		qdel(src)
		return TRUE
	return ..()

/obj/effect/wizard_grand_rune/on_attack_hand(mob/living/user, act_intent, unarmed_attack_flags)
	. = ..()
	if(. || channeling || QDELETED(ritual) || !ritual.can_channel(user, get_turf(src)))
		return .
	channeling = TRUE
	var/duration = (15 + 5 * ritual.runes_completed) SECONDS
	var/meteor_direction = 0
	if(ritual.runes_completed == WIZARD_RITUAL_RUNES - 1)
		duration = 45 SECONDS
		meteor_direction = choose_wizard_ritual_finale(user)
		if(QDELETED(src) || QDELETED(ritual) || !ritual.can_channel(user, get_turf(src)))
			channeling = FALSE
			return TRUE
	user.visible_message(span_warning("[user] начинает активировать руну Великого ритуала."))
	var/success = do_after(user, duration, target = src)
	channeling = FALSE
	if(success && !QDELETED(src) && !QDELETED(ritual))
		ritual.complete_rune(src, user, meteor_direction)
	return TRUE

/proc/choose_wizard_ritual_finale(mob/living/invoker)
	if(!invoker.client)
		return 0
	var/list/meteor_directions = list()
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	for(var/direction in GLOB.cardinals)
		for(var/z in station_levels)
			for(var/i in 1 to 10)
				if(isspaceturf(spaceDebrisStartLoc(direction, z)))
					meteor_directions |= direction
					break
			if(direction in meteor_directions)
				break
	if(!length(meteor_directions))
		return 0
	var/choice = tgui_input_list(invoker, "Какой эффект выпустить на станцию после активации руны?", "Великий ритуал", list(WIZARD_RITUAL_CLOWNS, WIZARD_RITUAL_METEORS), default = WIZARD_RITUAL_CLOWNS, timeout = 15 SECONDS, strict_modern = TRUE)
	return choice == WIZARD_RITUAL_METEORS ? pick(meteor_directions) : 0

/datum/objective/wizard_grand_ritual/proc/trigger_finale(mob/living/invoker, meteor_direction)
	var/finale = meteor_direction ? WIZARD_RITUAL_METEORS : WIZARD_RITUAL_CLOWNS
	log_game("WIZARD GRAND RITUAL: [key_name(invoker)] completed the ritual ([finale]).")
	message_admins("Великий ритуал завершён. Финал — [finale].")
	if(meteor_direction)
		priority_announce("Великий ритуал вызвал катастрофический метеорный шторм. Немедленно укройтесь!", "Метеорный апокалипсис")
		var/datum/round_event/meteor_wave/catastrophic/wizard_ritual/wave = new
		wave.direction = meteor_direction
		return
	priority_announce("Великий ритуал превратил станцию в арену Великого ликования.", "Великое ликование")
	for(var/mob/living/carbon/human/victim as anything in GLOB.human_list.Copy())
		var/turf/tile = get_turf(victim)
		if(QDELETED(victim) || victim == invoker || !victim.mind || victim.stat == DEAD || !tile || !is_station_level(tile.z))
			continue
		victim.dna?.add_mutation(CLOWNMUT)
		if(!isplasmaman(victim) && !istype(victim.w_uniform, /obj/item/clothing/under/rank/civilian/clown))
			if(!victim.w_uniform || victim.dropItemToGround(victim.w_uniform, invdrop = FALSE))
				victim.equip_to_slot_or_del(new /obj/item/clothing/under/rank/civilian/clown(victim), ITEM_SLOT_ICLOTHING)
		if(!victim.internal && !isplasmaman(victim) && !istype(victim.wear_mask, /obj/item/clothing/mask/gas/clown_hat))
			if(!victim.wear_mask || victim.dropItemToGround(victim.wear_mask))
				victim.equip_to_slot_or_del(new /obj/item/clothing/mask/gas/clown_hat(victim), ITEM_SLOT_MASK)
		to_chat(victim, span_warning("Пространство дрожит, и вы вспоминаете, как окончили клоунское училище."))
		CHECK_TICK

/datum/round_event/meteor_wave/catastrophic/wizard_ritual/setup()
	. = ..()
	start_when = 15
	end_when = start_when + 30

#undef WIZARD_RITUAL_RUNES
#undef WIZARD_RITUAL_CLOWNS
#undef WIZARD_RITUAL_METEORS
