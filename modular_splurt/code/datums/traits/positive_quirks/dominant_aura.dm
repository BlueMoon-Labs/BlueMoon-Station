/datum/quirk/dominant_aura
	name = "Аура Доминатора"
	desc = "Ваша аура силы и превосходства настолько выразительна, что пассивы ничего не могут поделать, кроме как броситься вам в ноги по щелчку пальцев."
	value = 1
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы хотите сделать кого-нибудь своим питомцем.</span>"
	lose_text = "<span class='notice'>Вы чувствуете себя менее напористо.</span>"

/datum/quirk/dominant_aura/add()
	. = ..()
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))
	RegisterSignal(quirk_holder, COMSIG_MOB_EMOTE, PROC_REF(handle_snap))

/datum/quirk/dominant_aura/remove()
	. = ..()
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)
	UnregisterSignal(quirk_holder, COMSIG_MOB_EMOTE)

/datum/quirk/dominant_aura/proc/on_examine_holder(atom/source, mob/user, list/examine_list, anonymous = FALSE)
	SIGNAL_HANDLER

	if(!ishuman(user))
		return
	var/mob/living/carbon/human/sub = user
	if(!sub.has_quirk(/datum/quirk/well_trained) || (sub == quirk_holder))
		return

	examine_list += span_lewd("\nВы испытываете сильный стыд от взгляда на [anonymous ? "него" : quirk_holder.ru_na()] и отводите свой взгляд!")
	if(!TIMER_COOLDOWN_CHECK(user, COOLDOWN_DOMINANT_EXAMINE))
		to_chat(quirk_holder, span_notice("[user] пытается посмотреть на вас, но тут же отворачивается с красным лицом..."))
		TIMER_COOLDOWN_START(user, COOLDOWN_DOMINANT_EXAMINE, 10 SECONDS)
		sub.dir = turn(get_dir(sub, quirk_holder), pick(-90, 90))
		sub.emote("blush")

/datum/quirk/dominant_aura/proc/handle_snap(datum/source, datum/emote/emote)
	SIGNAL_HANDLER

	. = FALSE
	if(TIMER_COOLDOWN_CHECK(quirk_holder, COOLDOWN_DOMINANT_SNAP) || !findtext(emote.key, "snap"))
		return
	for(var/mob/living/carbon/human/sub in hearers(DOMINANT_DETECT_RANGE, quirk_holder))
		if(!sub.has_quirk(/datum/quirk/well_trained) || (sub == quirk_holder))
			continue
		var/good_x = "питомец"
		switch(sub.gender)
			if(MALE)
				good_x = "мальчик"
			if(FEMALE)
				good_x = "девочка"
		switch(emote.key)
			if("snap")
				sub.dir = get_dir(sub, quirk_holder)
				sub.emote(pick("blush", "pant"))
				sub.visible_message(span_notice("\The <b>[sub]</b> застенчиво поворачивается и начинает покорное наблюдение за \the <b>[quirk_holder]</b>. Какая молодчинка!"),
									span_lewd("Ты покорно смотришь на \the [quirk_holder] и с трудом отводишь свой взгляд!"))
			if("snap2")
				sub.dir = get_dir(sub, quirk_holder)
				sub.KnockToFloor()
				sub.emote(pick("blush", "pant"))
				sub.visible_message(span_lewd("\The <b>[sub]</b> бросается на колени и преклоняет свою голову<b>[quirk_holder]</b>."),
									span_lewd("Ты бросаешься на свои колени и преклоняешь голову перед <b>[quirk_holder]</b>, будто бы какое-то животное!"))
			if("snap3")
				sub.KnockToFloor()
				step(sub, get_dir(sub, quirk_holder))
				sub.emote(pick("blush", "pant"))
				sub.do_jitter_animation(30) //You're being moved anyways
				sub.visible_message(span_lewd("\The <b>[sub]</b> бросается на четвереньки и приближается на своих коленях к \the <b>[quirk_holder]</b>"),
									span_lewd("Ты бросаешься на четвереньки и приближаешься на своих коленях к \the <b>[quirk_holder]</b>! [good_x] в своём репертуаре."))
		. = TRUE

	if(.)
		TIMER_COOLDOWN_START(quirk_holder, COOLDOWN_DOMINANT_SNAP, DOMINANT_SNAP_COOLDOWN)
