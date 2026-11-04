/datum/species/jelly/living_latex
	name = "Unknown latex lifeform"
	default_color = "2c2c2c"
	say_mod = "states"
	coldmod = 1.5
	heatmod = 1.2
	burnmod = 1.2
	brutemod = 0.5

/datum/antagonist/living_latex
	name = "Living latex"
	show_to_ghosts = TRUE
	antag_moodlet = /datum/mood_event/focused
	var/current_controller = BODY_OWNER
	var/alert_has_been_viewed = FALSE
	var/stage = 0
	var/evolve_points = 0
	var/mergingDelay = DEFAULT_MERGING_DELAY
	var/hide_latexorgan_on_healscan = FALSE
	var/leave_traces = TRUE
	var/latex_name = "Сгусток латекса"
	var/datum/evolution_store/evolution_store
	var/datum/latex_capture/capture
	var/obj/item/organ/latexOrgan/host_organ
	var/list/available_abilities = list()
	var/list/avaible_reagents = list(
		/datum/reagent/medicine/epinephrine,
		/datum/reagent/medicine/antitoxin,
		/datum/reagent/medicine/tricordrazine,
		/datum/reagent/drug/aphrodisiac,
		/datum/reagent/drug/anaphrodisiac,
	)
	var/list/second_stage_reagents = list(
		/datum/reagent/medicine/salbutamol,
		/datum/reagent/medicine/kelotane,
		/datum/reagent/medicine/neurine,
		/datum/reagent/medicine/oculine,
		/datum/reagent/drug/space_drugs,
		/datum/reagent/medicine/morphine,
	)
	var/list/last_stage_reagents = list(
		/datum/reagent/medicine/antihol,
		/datum/reagent/medicine/strange_reagent,
		/datum/reagent/medicine/pen_acid/pen_jelly,
		/datum/reagent/medicine/potass_iodide,
		/datum/reagent/drug/aphrodisiacplus,
		/datum/reagent/drug/anaphrodisiacplus,
	)
	var/list/all_abilities = list(
		/datum/action/cooldown/latexmob/takeControl,
		/datum/action/cooldown/latexmob/venomAction,
		/datum/action/cooldown/latexmob/ferral_form,
		/datum/action/cooldown/latexmob/medscan,
		/datum/action/cooldown/latexmob/heal,
		/datum/action/cooldown/latexmob/stasis,
		/datum/action/cooldown/latexmob/leak_out,
		/datum/action/cooldown/latexmob/human_form,
		/datum/action/cooldown/latexmob/mimicry,
	)
	var/list/base_mimicry_types = list(/obj/item)
	var/list/advanced_mimicry_types = list(/obj/structure/bed, /obj/structure/chair, /obj/structure/closet, /obj/machinery/sleeper)
	var/list/superior_special_mimicry_types = list(/obj/machinery/vending, /obj/machinery/computer, /obj/machinery/washing_machine)

/datum/antagonist/living_latex/on_gain()
	. = ..()
	evolution_store = new(src)
	for(var/ability_type in list(/datum/action/cooldown/latexmob/venomAction, /datum/action/cooldown/latexmob/takeControl, /datum/action/cooldown/latexmob/traces, /datum/action/cooldown/latexmob/evolution_store))
		var/datum/action/cooldown/latexmob/ability = new ability_type
		ability.my_living_latex = src
		available_abilities += ability
	grant_abilities(owner.current)
	START_PROCESSING(SSprocessing, src)
	INVOKE_ASYNC(src, PROC_REF(set_name), owner.current)

/datum/antagonist/living_latex/process(seconds_per_tick)
	if(!owner?.current || owner.current.stat == DEAD)
		return
	var/rate = host_organ ? POINTS_REGEN_NORMAL : POINTS_REGEN_HOSTLESS
	evolve_points = clamp(evolve_points + rate * seconds_per_tick, 0, LATEX_MAX_POINTS)

/datum/antagonist/living_latex/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	grant_abilities(new_body)
	if(islatexmob(old_body))
		var/mob/living/simple_animal/latexmob/latex_body = old_body
		latex_body.go_back()
	if(!QDELETED(capture))
		qdel(capture)

/datum/antagonist/living_latex/proc/set_name(mob/living/user)
	if(!user?.client)
		return
	var/chosen_name = tgui_input_text(user, "Введите псевдоним", "Living latex", latex_name, MAX_NAME_LEN)
	if(QDELETED(src) || QDELETED(user) || owner?.current != user || !chosen_name)
		return
	latex_name = chosen_name
	user.name = chosen_name
	user.real_name = chosen_name

/datum/antagonist/living_latex/proc/grant_abilities(mob/living/user)
	for(var/datum/action/cooldown/latexmob/ability as anything in available_abilities)
		ability.my_living_latex = src
		ability.Grant(user)

/datum/antagonist/living_latex/proc/get_ability_by_path(path)
	for(var/datum/action/cooldown/latexmob/ability as anything in available_abilities)
		if(ability.type == path)
			return ability
	return null

/datum/antagonist/living_latex/proc/search_ability_name(ability_name)
	for(var/ability_type in all_abilities)
		var/datum/action/cooldown/latexmob/template = ability_type
		if(initial(template.name) != ability_name)
			continue
		var/datum/action/cooldown/latexmob/ability = get_ability_by_path(ability_type)
		if(ability)
			if(ability.stage >= min(stage, ability.finall_stage) || evolve_points < ability.points_need_to_upgrade)
				return FALSE
			ability.update_stage()
			return TRUE
		if(stage < initial(template.stage_required) || evolve_points < initial(template.points_need_to_purchase))
			return FALSE
		ability = new ability_type
		ability.my_living_latex = src
		available_abilities += ability
		evolve_points -= ability.points_need_to_purchase
		ability.Grant(owner.current)
		return TRUE
	return FALSE

/datum/antagonist/living_latex/proc/upgrade_stage(new_stage)
	if(!isnum(new_stage) || new_stage != stage + 1 || new_stage > LATEX_MAX_STAGE || evolve_points < LATEX_MAX_POINTS)
		return FALSE
	stage = new_stage
	evolve_points = 0
	return TRUE

/datum/antagonist/living_latex/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	QDEL_NULL(capture)
	if(islatexmob(owner?.current))
		var/mob/living/simple_animal/latexmob/latex_body = owner.current
		latex_body.go_back()
	if(!QDELETED(host_organ))
		host_organ.release(TRUE)
	QDEL_NULL(evolution_store)
	QDEL_LIST(available_abilities)
	return ..()

/obj/effect/mob_spawn/horny_venom
	name = "Living latex"
	mob_name = "Living latex"
	mob_type = /mob/living/simple_animal/latexmob
	death = FALSE
	roundstart = FALSE
	random = FALSE
	uses = 1
	category = "special"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	assignedrole = "Living latex"
	flavour_text = "Вы — живой латекс. Найдите носителя и развивайте симбиоз."
	important_info = "Роль направлена на ролевое взаимодействие. Уважайте границы других игроков."

/obj/effect/mob_spawn/horny_venom/special(mob/living/new_spawn)
	new_spawn.mind?.add_antag_datum(/datum/antagonist/living_latex)

/obj/effect/mob_spawn/horny_venom/attack_ghost(mob/user, latejoinercalling)
	if(GLOB.master_mode != "Extended")
		to_chat(user, span_warning("Эта роль доступна только в режиме Extended."))
		return
	return ..()

/obj/effect/temp_visual/latexmob
	icon = 'modular_bluemoon/horny_venom/icons/sybm_icons.dmi'
	duration = 1 SECONDS

/obj/effect/temp_visual/latexmob/venom_in
	icon_state = "synt_on"

/obj/effect/temp_visual/latexmob/venom_out
	icon_state = "synt_off"

/mob/living/simple_animal/latexmob
	name = "Сгусток латекса"
	icon = 'modular_bluemoon/horny_venom/icons/latexmob.dmi'
	icon_state = "slime_form"
	icon_living = "slime_form"
	desc = "Плотный чёрный сгусток живого латекса."
	melee_damage_lower = 2
	melee_damage_upper = 5
	pass_flags = PASSTABLE | PASSMOB
	wander = FALSE
	var/mimicry_in_use = FALSE
	var/obj/mimic_shell

/mob/living/simple_animal/latexmob/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	if(!isbackseatmob(src))
		AddComponent(/datum/component/latex_contact)

/mob/living/simple_animal/latexmob/Destroy()
	go_back()
	return ..()

/mob/living/simple_animal/latexmob/debug
	name = "Отладочный живой латекс"
	desc = "Живой латекс с максимальной стадией и всеми улучшенными способностями."

/mob/living/simple_animal/latexmob/debug/Initialize(mapload)
	. = ..()
	mind_initialize()
	var/datum/antagonist/living_latex/latex = mind.add_antag_datum(/datum/antagonist/living_latex)
	latex.stage = LATEX_MAX_STAGE
	for(var/ability_type in latex.all_abilities)
		unlock_ability(latex, ability_type)
	latex.evolve_points = LATEX_MAX_POINTS

/mob/living/simple_animal/latexmob/debug/proc/unlock_ability(datum/antagonist/living_latex/latex, ability_type)
	var/datum/action/cooldown/latexmob/template = ability_type
	var/datum/action/cooldown/latexmob/ability = latex.get_ability_by_path(ability_type)
	if(!ability)
		latex.evolve_points = LATEX_MAX_POINTS
		latex.search_ability_name(initial(template.name))
		ability = latex.get_ability_by_path(ability_type)
	while(ability.stage < min(latex.stage, ability.finall_stage))
		latex.evolve_points = LATEX_MAX_POINTS
		if(!latex.search_ability_name(initial(template.name)))
			break

/mob/living/simple_animal/latexmob/ferral
	name = "Маленькое латексное существо"
	desc = "Небольшое существо с блестящей чёрной кожей."
	icon_state = "ferral"
	icon_living = "ferral"
	health = 150
	maxHealth = 150
	dextrous = TRUE
	dextrous_hud_type = /datum/hud/dextrous/latexmob
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)
	damage_coeff = list(BRUTE = 0.5, BURN = 1.3, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	held_items = list(null, null)

/mob/living/simple_animal/latexmob/venom
	name = "Внутренний голос"
	real_name = "unknown conscience"
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	status_flags = GODMODE
	var/mob/living/carbon/human/body
	var/obj/item/organ/latexOrgan/organ

/mob/living/simple_animal/latexmob/venom/Login()
	..()
	LOGIN_NOTICE_MESSAGE(src)
	var/datum/antagonist/living_latex/latex = mind?.has_antag_datum(/datum/antagonist/living_latex)
	if(latex && !latex.alert_has_been_viewed)
		latex.alert_has_been_viewed = TRUE
		INVOKE_ASYNC(src, PROC_REF(show_warning))

/mob/living/simple_animal/latexmob/venom/proc/show_warning()
	LOGIN_WARNING_MESSAGE(src)

/mob/living/simple_animal/latexmob/venom/Destroy()
	if(!QDELETED(organ))
		organ.release(TRUE)
	body = null
	organ = null
	return ..()

/mob/living/simple_animal/latexmob/venom/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!length(message) || !body)
		return
	message = html_encode(strip_html(message, MAX_MESSAGE_LEN))
	to_chat(body, span_notice("Внутренний голос: [message]"))
	to_chat(src, span_notice("Вы говорите носителю: [message]"))

/mob/living/simple_animal/latexmob/venom/emote(act, m_type = null, message = null, intentional = FALSE)
	if(!length(message) || !body)
		return
	message = html_encode(strip_html(message, MAX_MESSAGE_LEN))
	to_chat(body, span_notice("Внутренний голос: [message]"))
	to_chat(src, span_notice("Вы передаёте носителю: [message]"))
