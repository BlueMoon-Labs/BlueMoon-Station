/datum/species/jelly/roundstartslime/living_latex
	name = "Unknown latex lifeform" //Мы не знаем что это такое, если мы знали что это такое, мы не знаем что это такое
	default_color = "2c2c2c"
	say_mod = "states"
	coldmod = 1.5 //застывает и становится хрупким
	heatmod = 1.2 //плавится и теряет форму
	burnmod = 1.2
	brutemod = 0.5 //Латекс мягкий и гибкий и ему легче переносить удары твердыми предметами

/datum/antagonist/living_latex
	name = "Living latex"
	show_to_ghosts = TRUE
	antag_moodlet = /datum/mood_event/focused
	var/current_controller
	var/alert_has_been_viewed = FALSE
	var/stage = 0
	var/evolve_points = 0
	var/mergingDelay = DEBUG_MERGING_DELAY
	var/hide_latexorgan_on_healscan = FALSE
	var/datum/species/old_host_spec
	var/datum/species/jelly/roundstartslime/living_latex/self_species
	var/datum/evolution_store
	var/list/available_abilities = list(
		new /datum/action/cooldown/latexmob/venomAction,
		new /datum/action/cooldown/latexmob/takeControl
	)

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

	var/alist/all_abilities = alist(
		/datum/action/cooldown/latexmob/takeControl = "Захватить контроль над телом",
		/datum/action/cooldown/latexmob/venomAction = "Поглотить/освободить",
		/datum/action/cooldown/latexmob/ferral_form = "Форма животного",
		/datum/action/cooldown/latexmob/medscan     = "Проверить здоровье",
		/datum/action/cooldown/latexmob/heal        = "Лечение",
		/datum/action/cooldown/latexmob/stasis      = "Стазис",
		/datum/action/cooldown/latexmob/leak_out    = "Проползти под шлюзом",
		/datum/action/cooldown/latexmob/human_form  = "Сформировать человеческое тело",
		/datum/action/cooldown/latexmob/mimicry     = "Мимикрия",
	)

	var/list/only_for_ui_abilities_list = list(
		new /datum/action/cooldown/latexmob/takeControl,
		new /datum/action/cooldown/latexmob/venomAction,
		new /datum/action/cooldown/latexmob/ferral_form,
		new /datum/action/cooldown/latexmob/medscan,
		new /datum/action/cooldown/latexmob/heal,
		new /datum/action/cooldown/latexmob/stasis,
		new /datum/action/cooldown/latexmob/leak_out,
		new /datum/action/cooldown/latexmob/human_form,
		new /datum/action/cooldown/latexmob/mimicry,
	)

	var/list/base_mimicry_types = list(
		/obj/item,
		/obj/item/book,
		/obj/item/clothing,
		/obj/item/reagent_containers/food,
	)

	var/list/advanced_mimicry_types = list(
		/obj/structure/bed,
		/obj/structure/chair,
		/obj/structure/closet,
		/obj/machinery/sleeper,
		/obj/structure/closet/crate,
	)

	var/list/superior_special_mimicry_types = list(
		/obj/machinery/vending,
		/obj/machinery/computer,
		/obj/machinery/washing_machine,
	)

/datum/antagonist/living_latex/process()
	. = ..()
	var/needed_for_full = 1 - evolve_points
	if(needed_for_full <= (evolve_points + POINTS_REGEN_DEBUG))
		evolve_points += needed_for_full
	else
		evolve_points += POINTS_REGEN_DEBUG

/datum/antagonist/living_latex/proc/get_ability_by_path(path)
	for(var/datum/action/ability in available_abilities)
		if(istype(ability, path))
			return ability
		else
			continue
	return FALSE

/datum/antagonist/living_latex/on_gain()
	. = ..()
	var/datum/evolution_store/ev_store = new(src)
	self_species = new /datum/species/jelly/roundstartslime/living_latex
	evolution_store = ev_store
	available_abilities += new /datum/action/cooldown/latexmob/evolution_store
	set_name(usr)
	grant_abilities(usr)

/datum/antagonist/living_latex/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	for(var/datum/action/cooldown/latexmob/all_powers as anything in available_abilities)
		all_powers.Remove(old_body)
		all_powers.Grant(new_body)

/datum/antagonist/living_latex/proc/set_name(var/mob/living/user)
	user.name = tgui_input_text(user, "Введите псевдоним", "Set name", "Сгусток латекса", 30)
	if(!user.name)
		user.name = "Сгусток латекса"

/datum/antagonist/living_latex/proc/grant_abilities(user)
	for(var/datum/action/cooldown/latexmob/action in available_abilities)
		action.my_living_latex = src
		action.Grant(user)

/datum/antagonist/living_latex/proc/search_ability_name(ability_name)
	for(var/ability_typepath in src.all_abilities)
		if(src.all_abilities[ability_typepath] == ability_name)
			var/datum/action/cooldown/latexmob/new_player_ability = new ability_typepath
			new_player_ability.my_living_latex = src
			add_new_ability(new_player_ability)
			return

/datum/antagonist/living_latex/proc/add_new_ability(var/datum/action/cooldown/latexmob/ability_to_grant)

//Блок УЛУЧШЕНИЯ абилки
	var/datum/action/cooldown/latexmob/located_ability = locate(ability_to_grant) in available_abilities

	if (located_ability && located_ability.stage < located_ability.finall_stage && located_ability.stage < stage)
		if(evolve_points < located_ability.points_need_to_upgrade)
			to_chat(usr, "<span class='warning'>У вас не хватает очков эволюции, чтобы улучшить данную способность!</span>")
			return
		located_ability.update_stage()
		ABILITY_IS_UPDATED(usr, ability_to_grant)
		return

//Блок ПОКУПКИ новой абилки
	if (ability_to_grant.stage_required <= stage && evolve_points >= 1 && !located_ability)
		available_abilities += ability_to_grant
		evolve_points -= ability_to_grant.points_need_to_purchase
		grant_abilities(usr)
	else
		var/message
		message = located_ability ? "<span class='warning'>Cпособность [ability_to_grant.name] уже куплена и улучшена! Если это не так, проверьте текущую стадию.</span>" : "<span class='warning'>У вас не хватает стадии или очков эволюции, чтобы приобрести данную способность!</span>"
		to_chat(usr, message)

/datum/antagonist/living_latex/proc/inject_reagent(reagent_name)
	for(var/path in src.avaible_reagents)
		var/datum/reagent/reagent = path
		var/datum/reagent/R = new path
		if(R.name == reagent_name)
			usr.reagents.add_reagent(reagent, 5)
			evolve_points -= 0.1
		qdel(R)

/datum/antagonist/living_latex/proc/upgrade_stage(NewStage)
	if(evolve_points == 1)
		var/old_stage = stage
		if((old_stage + 1) != NewStage)
			return
		stage = NewStage
		evolve_points = 0

/datum/antagonist/living_latex/Destroy()
	. = ..()
	QDEL_NULL(evolution_store)

/datum/antagonist/living_latex/proc/merging(mob/living/carbon/T)
	var/mob/living/old_body = owner.current
	var/obj/item/organ/latexOrgan/O = new /obj/item/organ/latexOrgan(my_antag_datum = src)
	new /obj/effect/temp_visual/latexmob/venom_in(T.loc)
	O.Insert(T)
	O.ObserverBackseat = new /mob/living/simple_animal/latexmob/venom(T)
	old_body.mind.transfer_to(O.ObserverBackseat)
	grant_abilities(O.ObserverBackseat)
	qdel(old_body)

/obj/effect/mob_spawn/horny_venom
	name = "Living latex"
	mob_name = "Living latex"
	mob_type = 	/mob/living/simple_animal/latexmob
	death = FALSE
	roundstart = FALSE
	random = FALSE
	uses = 1
	category = "special"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	assignedrole = "Living latex"
	flavour_text = "Вы - живой латекс. Пришелец, возможно результат чьих-то экспериментов. Найдите себе носителя и эволюционируйте."
	important_info = "НЕ ГРИФЕРИТЬ, ИНАЧЕ ВАС ЗАБАНЯТ!!\n Ваша роль направленна впервую очерень на ролевое взаимодействие. Уважайте других игроков."

/obj/effect/temp_visual/latexmob
	icon = 'modular_bluemoon/horny_venom/icons/sybm_icons.dmi'
	duration = 12

/obj/effect/temp_visual/latexmob/venom_in
	icon_state = "synt_on"

/obj/effect/temp_visual/latexmob/venom_out
	icon_state = "synt_off"

/obj/effect/mob_spawn/horny_venom/attack_ghost(mob/user, latejoinercalling)
	if(GLOB.master_mode == "Extended")
		. = ..()
	else
		return to_chat(user, "<span class='warning'>Игра за ЕРП-антагонистов допускается лишь в Режим Extended!</span>")

/mob/living/simple_animal/latexmob
	name = "Сгусток латекса"
	icon = 'modular_bluemoon/horny_venom/icons/latexmob.dmi'
	icon_state = "slime_form"
	desc = "На первый взгляд, это обычный черный слайм, однако он выглядит в разы плотнее и быстрее."
	reagents = new /datum/reagents
	melee_damage_lower = 2
	melee_damage_upper = 5
	pass_flags = PASSTABLE | PASSMOB
	var/mimicry_in_use = FALSE

/mob/living/simple_animal/latexmob/CtrlClickOn(atom/movable/A)
	. = ..()
	var/object_valid_for_mimicry
	var/datum/antagonist/living_latex/antag_datum = src.mind ? locate(/datum/antagonist/living_latex) in src.mind.antag_datums : FALSE
	var/datum/action/cooldown/latexmob/mimicry/mimic_ability = locate(/datum/action/cooldown/latexmob/mimicry) in antag_datum.available_abilities
	if(!mimic_ability)
		return

	mimic_ability.Activate(try_copy = TRUE)
	var/list/avaible_types = mimic_ability.avaible_types_for_mimicry
	object_valid_for_mimicry = check_type_for_mimicry(A.parent_type, avaible_types)

	if(object_valid_for_mimicry)
		mimic_ability.copied_object = A
		balloon_alert(src, "Объект скопирован")
		return
	else
		balloon_alert(src, "Недоступно!") //недостаточная стадия, невалидный объект и т.д

/mob/living/simple_animal/latexmob/Life(seconds, times_fired)
	. = ..()
	if(!src.mind)
		stack_trace("Latexmob Life() called without mind!")
		return
	var/datum/antagonist/living_latex/my_antag_datum = locate(/datum/antagonist/living_latex) in src.mind.antag_datums
	my_antag_datum?.process()

/obj/item/organ/latexOrgan
	name = "strange black organ"
	//icon =
	zone = BODY_ZONE_HEAD
	organ_flags = ORGAN_NO_SPOIL
	var/mob/living/simple_animal/latexmob/venom/ObserverBackseat
	var/datum/antagonist/living_latex/antag_datum
	var/is_hiding = FALSE

/obj/item/organ/latexOrgan/New(loc, ..., var/datum/antagonist/my_antag_datum)
	. = ..()
	antag_datum = my_antag_datum

/obj/item/organ/latexOrgan/proc/update_hiding_state()
	is_hiding = antag_datum.hide_latexorgan_on_healscan

/mob/living/simple_animal/latexmob/Initialize(mapload, new_colour, new_is_adult)
	. = ..()
	var/mob/living/simple_animal/latexmob/latexmob = src
	latexmob.mind = new
	latexmob.LL_apply_latex_overlay(DEFAULT_LL_OVERLAY_ICON, DEFAULT_LL_OVERLAY_ICON_STATE)
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)

/mob/living/simple_animal/latexmob/ferral
	name = "Маленькое латексное существо"
	desc = "Маленькое существо, с блестящей черной кожей, чем-то напоминающей слайма. Оно с голодными глазами смотрит на вас."
	icon = 'modular_bluemoon/horny_venom/icons/latexmob.dmi'
	icon_state = "ferral"
	health = 150
	maxHealth = 150
	speak = list() //Добавить сюда галлком хотя бы
	dextrous = TRUE
	dextrous_hud_type = /datum/hud/dextrous/latexmob
	possible_a_intents = list(INTENT_HELP, INTENT_HARM)
	damage_coeff = list(BRUTE = 0.5, BURN = 1.3, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	held_items = list(null, null)
	var/current_stage //1,2,3
	var/can_be_held = TRUE //mob holder element.
	var/need_to_next_stade //200u, 500u, 1000u of semen/femcum. Yeeah )O)

/mob/living/simple_animal/latexmob/ferral/Initialize(mapload, new_colour, new_is_adult)
	. = ..()

/mob/living/simple_animal/latexmob/venom
	name = "split personality"
	real_name = "unknown conscience"
	var/mob/living/carbon/human/body
	var/obj/item/organ/latexOrgan/organ

/mob/living/simple_animal/latexmob/venom/Login()
	..()
	body = src.loc
	LOGIN_NOTICE_MESSAGE(src)
	var/datum/antagonist/living_latex/antag_datum = src.mind ? locate(/datum/antagonist/living_latex) in src.mind.antag_datums : FALSE
	if(antag_datum && !antag_datum.alert_has_been_viewed) //Показывается только один раз и только носителю антаг датума.
		LOGIN_WARNING_MESSAGE(src)
		antag_datum.alert_has_been_viewed = TRUE

/mob/living/simple_animal/latexmob/venom/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(length(message) && body)
		to_chat(body, span_bold("Странный голос раздается эхом и гласит: \"[message]\""))
		to_chat(src, span_bold("Вы говорите: [message]"))
	return

/mob/living/simple_animal/latexmob/venom/emote(act, m_type = null, message = null, intentional = FALSE)
	if(length(message) && body)
		to_chat(body, span_love("[message]"))
		to_chat(src, span_warning("Вы совершили действие над хостом:")+span_love("[message]"))
	return
