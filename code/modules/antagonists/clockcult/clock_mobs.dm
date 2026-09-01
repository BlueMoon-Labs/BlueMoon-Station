//The base for clockwork mobs
/mob/living/simple_animal/hostile/clockwork
	faction = list("neutral", "ratvar")
	gender = NEUTER
	icon = 'icons/mob/clockwork_mobs.dmi'
	unique_name = 1
	minbodytemp = 0
	unsuitable_atmos_damage = 0
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0) //Robotic
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	healable = FALSE
	del_on_death = TRUE
	speak_emote = list("лязгает", "звенит", "грохочет", "гремит")
	verb_ask = "запрашивает"
	verb_exclaim = "заявляет"
	verb_whisper = "передаёт"
	verb_yell = "разглагольствует"
	initial_language_holder = /datum/language_holder/clockmob
	bubble_icon = "clock"
	light_color = "#E42742"
	death_sound = 'sound/magic/clockwork/anima_fragment_death.ogg'
	speech_span = SPAN_ROBOT
	var/playstyle_string = "<span class='heavy_brass'>Ты жук, кричи на того, кто тебя породил!</span>"
	var/empower_string = "<span class='heavy_brass'>Вам нечего расширять, кричите на программистов!</span>" //Shown to the mob when the herald beacon activates
	typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/clock

/mob/living/simple_animal/hostile/clockwork/Initialize(mapload)
	. = ..()
	update_values()

/mob/living/simple_animal/hostile/clockwork/Login()
	..()
	add_servant_of_ratvar(src, TRUE)
	to_chat(src, playstyle_string)
	if(GLOB.ratvar_approaches)
		to_chat(src, empower_string)

/mob/living/simple_animal/hostile/clockwork/ratvar_act()
	fully_heal(TRUE)

/mob/living/simple_animal/hostile/clockwork/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	return FALSE //ouch, my metal-unlikely-to-be-damaged-by-electricity-body

/mob/living/simple_animal/hostile/clockwork/examine(mob/user)
	var/t_He = ru_who(TRUE)
	// var/t_s = p_s() Комментим, т.к эта штука применима только к английскому. Мы же переводим текст и оно нам не надо
	var/msg = "<span class='brass'>Это [icon2html(src, user)] <b>[src]</b>!\n"
	if(desc)
		msg += "<hr>[desc]\n"
	if(health < maxHealth)
		msg += "<hr><span class='warning'>"
		if(health >= maxHealth/2)
			msg += "[t_He] выглядит немного поврежденным.\n"
		else
			msg += "<b>[t_He] выглядит серьёзно поврежденным!</b>\n"
		msg += "</span>"
	var/addendum = examine_info()
	if(addendum)
		msg += "<hr>[addendum]\n"
	msg += "</span>"

	return list(msg)

/mob/living/simple_animal/hostile/clockwork/proc/examine_info() //Override this on a by-mob basis to have unique examine info
	return

/mob/living/simple_animal/hostile/clockwork/proc/update_values() //This is called by certain things to check GLOB.ratvar_awakens and GLOB.ratvar_approaches
