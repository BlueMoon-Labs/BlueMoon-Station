/proc/activate_after(obj, delay)

	var/endtime = world.time + delay
	. = 1
	while (world.time < endtime)
		stoplag()

/obj/item/dildo
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_righthand.dmi'
	item_state = "dildo"
	var/inside = FALSE
	var/last_heavy_message_time = 0

/obj/item/dildo/proc/update_lust()
	switch(dildo_size)
		if(5)
			lust_amount = HIGH_LUST*4
		if(4)
			lust_amount = HIGH_LUST*2
		if(3)
			lust_amount = HIGH_LUST
		if(2)
			lust_amount = NORMAL_LUST
		if(1)
			lust_amount = LOW_LUST
		// if some add bigger dildo
		else
			lust_amount = max(HIGH_LUST*dildo_size,LOW_LUST)

// proc that ensures the target's reaction to the dildo according to the size
// to_chat_mode: 0 - to_chat if dildo_size >= 4, 1 - all to_chat, else not use to_chat
/obj/item/dildo/proc/target_reaction(mob/living/target, mob/living/user = null, to_chat_mode = 0, what_cum = null, where_cum = null, use_stun = TRUE, add_lust = TRUE, use_moan = FALSE, use_jitter = TRUE, ignore_delay = FALSE)
	var/message = ""
	var/moan = FALSE
	var/stun = 0
	var/jitter = 0
	var/lust_to_target = lust_amount
	var/heavy_message_delay = 400 // 40 sec
	if(isnull(user))
		user = target
	switch(dildo_size)
		if(4)
			if(what_cum == CUM_TARGET_MOUTH || what_cum == CUM_TARGET_THROAT)
				message = pick(
					"Я чувствую, как огромный дилдо заполняет мой рот до предела!",
					"Моя глотка пульсирует, обхватывая огромный дилдо!",
					"Огромный дилдо растягивает мои челюсти, не оставляя пространства для воздуха!",
					"Каждое движение огромного дилдо вызывает у меня слезы и жар по всему телу!",
					"Огромный дилдо упирается в горло, заставляя меня задыхаться от наслаждения!")
			else
				message = pick(
					"Огромный дилдо внутри терзает вас волнами экстаза!",
					"Вы чувствуете нестерпимое удовольствие от огромного дилдо глубоко внутри!",
					"Огромный дилдо будто заполняет всё изнутри, оставляя чувство распирающего наслаждения!",
					"Каждое движение огромного дилдо вызывает сладкую боль и трепет внизу живота!",
					"Ваши мышцы сжимаются от напряжения, пока огромный дилдо двигается внутри!")
			if(ignore_delay || (world.time - last_heavy_message_time >= heavy_message_delay))
				last_heavy_message_time = world.time
				message = span_userdanger(message)
			else
				message = span_alertwarning(message)
			jitter = 5
			stun = 6
			moan = TRUE
		if(3)
			if(what_cum == CUM_TARGET_MOUTH || what_cum == CUM_TARGET_THROAT)
				message = span_love(pick(
					"Большой дилдо входит в рот, вызывая возбуждение.",
					"Мое горло натужно принимает большой дилдо.",
					"Большой дилдо мягко раздвигает губы, скользя внутрь с нарастающим жаром.",
					"С каждым толчком большой дилдо углубляется, заставляя меня стонать.",
					"Я чувствую, как большой дилдо прижимается к языку, вызывая дрожь."))
			else
				message = span_love(pick(
					"Я чувствую большой дилдо внутри себя!",
					"Вас пронзает ощутимое удовольствие от большого дилдо глубоко внутри!",
					"Большой дилдо наполняет меня приятной тяжестью, от которой перехватывает дыхание!",
					"С каждым движением большого дилдо я чувствую нарастающий жар по всему телу!"))
			jitter = 3
			stun = 3
			moan = TRUE
		if(2)
			if(what_cum == CUM_TARGET_MOUTH || what_cum == CUM_TARGET_THROAT)
				message = span_love(pick(
					"Я чувствую, как дилдо толкает в самое основание языка.",
					"Каждый раз, когда дилдо входит в рот, накатывает волна возбуждения.",
					"Дилдо приятно давит на язык и тянет слюну вниз по подбородку.",
					"Дилдо скользит во рту, все больше возбуждая."))
			else
				message = span_love(pick(
					"Я чувствую дилдо внутри себя.",
					"Приятное удовольствие от дилдо глубоко внутри, проходит сквозь меня.",
					"Дилдо достаточно глубоко внутри, вызывает жар во всём теле.",
					"Я чувствую, как средний дилдо трёт мои стенки, вызывая пульсацию.",
					"С каждым движением среднего дилдо я теряюсь в ощущениях."))
		if(1)
			if(what_cum == CUM_TARGET_MOUTH || what_cum == CUM_TARGET_THROAT)
				message = span_love(pick(
					"Небольшой дилдо удобно ложится на язык, вызывая щекочущее возбуждение.",
					"Я ощущаю, как маленький дилдо мягко упирается в заднюю стенку глотки.",
					"Маленький дилдо скользит почти незаметно, оставляя сладкий след возбуждения.",
					"Даже с таким размером — каждый толчок маленького дилдо вызывает приятную дрожь."))
			else
				message = span_love(pick(
					"Я чувствую небольшой дилдо внутри себя.",
					"Лёгкое удовольствие от небольшого дилдо глубоко внутри, проходит сквозь меня.",
					"Маленький дилдо приятно стимулирует изнутри, вызывая нежную пульсацию.",
					"Каждое движение маленького дилдо мягкое, но отчётливо чувствуемое.",
					"Небольшой дилдо дарит уютное, почти интимное ощущение заполненности."))
		// for 5 size and if some add bigger dildo
		else
			if(what_cum == CUM_TARGET_MOUTH || what_cum == CUM_TARGET_THROAT)
				message = pick(
					"Я задыхаюсь от гигантского дилдо, но удовольствие лишь нарастает!",
					"Я чувствую, как гигантский дилдо давит на горло изнутри, почти перекрывая воздух!",
					"Гигантский дилдо упирается в самую глубину, заставляя глотку трепетать от боли и желания!",
					"Каждый толчок гигантского дилдо будто сотрясает череп, оставляя за собой только жар и дрожь!",
					"Гигантский дилдо полностью захватывает горло, почти лишая меня воздуха, и разума!")
			else
				message = pick(
					"Гигантский дилдо внутри сводит вас с ума!",
					"Вы чувствуете мучительное удовольствие от гигантского дилдо глубоко внутри!",
					"Гигантский дилдо растягивает изнутри до предела, вызывая восторг и трепет.",
					"Каждое движение гигантского дилдо будто разрывает грань между болью и наслаждением.",
					"Гигантский словно пульсирует распирая изнутри, заставляя терять контроль.")
			if(ignore_delay || (world.time - last_heavy_message_time >= heavy_message_delay))
				last_heavy_message_time = world.time
				message = span_userdanger(message)
			else
				message = span_alertwarning(message)
			jitter = 6
			stun = 10
			moan = TRUE

	if(to_chat_mode == 1 || (to_chat_mode == 0 && dildo_size >= 4))
		to_chat(target, message)
	if(use_jitter && jitter && (target.client?.prefs.cit_toggles & SEX_JITTER)) //By Gardelin0
		target.Jitter(jitter)
	if(use_moan && moan)
		if(what_cum == CUM_TARGET_MOUTH || what_cum == CUM_TARGET_THROAT)
			target.emote("girlymoan") // realy small lust
		else
			target.emote("moan")
	if(use_stun && stun)
		target.Stun(stun)
	if(what_cum == CUM_TARGET_MOUTH || what_cum == CUM_TARGET_THROAT)
		lust_to_target = min(LOW_LUST*dildo_size/3, LOW_LUST) // realy small lust
	if(add_lust)
		target.handle_post_sex(lust_to_target, where_cum, user, what_cum)

	return lust_to_target // Unified lust value if you want to make your own handle_post_sex

/obj/item/dildo/Initialize(mapload)
	. = ..()
	update_lust()

/obj/item/dildo/customize(mob/living/user)
	if(!..())
		return FALSE
	update_lust()

//Dildo
/obj/item/dildo/proc/stuffed_movement(mob/living/user)
	while(inside)
		if(activate_after(src, rand(50,350))) //5 to 35 seconds, every 20 sec on average
			if(!istype(src.loc, /obj/item/organ/genital))
				return
			target_reaction(user, null, 1, null, null, TRUE, TRUE, TRUE, TRUE, TRUE)
			user.plug13_genital_emote(loc, lust_amount)

/obj/item/dildo/ComponentInitialize()
	. = ..()
	var/list/procs_list = list(
		"before_inserting" = CALLBACK(src, PROC_REF(item_inserting)),
		"after_inserting" = CALLBACK(src, PROC_REF(item_inserted)),
		"after_removing" = CALLBACK(src, PROC_REF(item_removed)),
	)
	AddComponent(/datum/component/genital_equipment, list(ORGAN_SLOT_PENIS, ORGAN_SLOT_WOMB, ORGAN_SLOT_VAGINA, ORGAN_SLOT_BREASTS, ORGAN_SLOT_ANUS), procs_list)

/obj/item/dildo/proc/item_inserting(datum/source, obj/item/organ/genital/G, mob/living/user)
	. = TRUE
	if(!(G.owner.client?.prefs?.erppref == "Yes"))
		to_chat(user, span_warning("They don't want you to do that!"))
		return FALSE

	if(!(CHECK_BITFIELD(G.genital_flags, GENITAL_CAN_STUFF)))
		to_chat(user, span_warning("This genital can't be stuffed!"))
		return FALSE

	if(locate(src.type) in G.contents)
		if(user == G.owner)
			to_chat(user, span_notice("You already have a dildo inside your [G]!"))
		else
			to_chat(user, span_notice("\The <b>[G.owner]</b>'s [G] already has a dildo inside!"))
		return FALSE

	if(user == G.owner)
		G.owner.visible_message(span_warning("\The <b>[user]</b> is trying to insert dildo inside themselves!"),\
			span_warning("You try to insert dildo inside yourself!"))
	else
		G.owner.visible_message(span_warning("\The <b>[user]</b> is trying to insert dildo inside \the <b>[G.owner]</b>!"),\
			span_warning("\The <b>[user]</b> is trying to insert dildo inside you!"))

	if(!do_mob(user, G.owner, 5 SECONDS))
		return FALSE

	target_reaction(G.owner, null, 1)
	G.owner.plug13_genital_emote(G, lust_amount)
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)

/obj/item/dildo/proc/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	to_chat(user, span_userlove("You attach [src] to <b>\The [G.owner]</b>'s [G]."))
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	inside = TRUE
	stuffed_movement(G.owner)

/obj/item/dildo/proc/item_removed(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	to_chat(user, span_userlove("You retrieve [src] from <b>\The [G.owner]</b>'s [G]."))
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	inside = FALSE

/obj/item/dildo/MouseDrop_T(mob/living/M, mob/living/user)
	var/message = ""
	var/lust_amt = 0
	if(ishuman(M) && (M?.client?.prefs?.toggles & VERB_CONSENT))
		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_GROIN)
				switch(hole)
					if(CUM_TARGET_VAGINA)
						if(M.has_vagina(REQUIRE_EXPOSED))
							message = (user == M) ? pick("распологается над '\the [src]' и начинает пихать это прямо в свою киску.", "запихивает '\the [src]' в свою киску", "постанывает и садится на '\the [src]' киской.",  "скачет на '\the [src]' киской!") : pick("насаживает <b>[M]</b> киской на '\the [src]'", "надавливает на плечи <b>[M]</b>, заставляя скакать киской на '\the [src]!'")
							lust_amt = NORMAL_LUST
					if(CUM_TARGET_ANUS)
						if(M.has_anus(REQUIRE_EXPOSED))
							message = (user == M) ? pick("распологается над '\the [src]' и начинает пихать это прямо в свою попку.","запихивает '\the [src]' прямо в свою собственную попку.", "постанывает и садится на '\the [src]' попой.",  "скачет на '\the [src]' попой!") : pick("насаживает <b>[M]</b> попой на '\the [src]'", "надавливает на плечи <b>[M]</b>, заставляя скакать попой на '\the [src]!'")
							lust_amt = NORMAL_LUST
			if(BODY_ZONE_PRECISE_MOUTH)
				if(M.has_mouth() && !M.is_mouth_covered())
					message = (user == M) ? pick("распологается над '\the [src]' и начинает пихать это прямо в свой ротик.", "запихивает '\the [src]' прямо в свой собственный ротик.", "втыкает '\the [src]' прямо в свой ротик.", "заглатывает '\the [src]' целиком!") : pick("насаживает <b>[M]</b> ротиком на '\the [src]'", "надавливает на затылок <b>[M]</b>, заставляя заглатывать '\the [src]!'")
	if(message)
		user.visible_message("<span class='lewd'><b>[user]</b> [message].</span>")
		M.handle_post_sex(lust_amt, null, user)

		switch(user.zone_selected)
			if(BODY_ZONE_PRECISE_GROIN)
				switch (hole)
					if (CUM_TARGET_VAGINA)
						user.client?.plug13.send_emote(PLUG13_EMOTE_VAGINA, min(lust_amt * 3, 100), PLUG13_DURATION_NORMAL)
					if (CUM_TARGET_ANUS)
						user.client?.plug13.send_emote(PLUG13_EMOTE_ANUS, min(lust_amt * 3, 100), PLUG13_DURATION_NORMAL)
			if (BODY_ZONE_PRECISE_MOUTH)
				user.client?.plug13.send_emote(PLUG13_EMOTE_MOUTH, 35, PLUG13_DURATION_NORMAL)

		playsound(loc, pick('modular_sand/sound/interactions/bang4.ogg',
							'modular_sand/sound/interactions/bang5.ogg',
							'modular_sand/sound/interactions/bang6.ogg'), 70, 1, -1)
