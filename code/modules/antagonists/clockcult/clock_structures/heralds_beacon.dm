

//Used to "declare war" against the station. The servants' equipment will be permanently supercharged, and the Ark given extra time to prepare.
//This will send an announcement to the station, meaning that they will be warned very early in advance about the impending attack.
/obj/structure/destructible/clockwork/heralds_beacon
	name = "herald's beacon"
	desc = "Внушительный шпиль из латуни c звенящим драгоценным камнем."
	clockwork_desc = "Чрезвычайно мощный маяк. Если достаточное количество слуг решит активировать его, он пошлет на \"Ковчег\" невероятно мощный энергетический импульс, который \
	надолго активизирует многие часовые объекты и снизит все затраты на энергию на 50%, но предупредит экипаж о вашем присутствии. Ему не хватит энергии для длительного поддержания своей работы, \
	если его не активировать в течение пяти минут, он навсегда отключится."
	icon_state = "interdiction_lens"
	break_message = "<span class='warning'>Маяк сильно трескается, прежде чем рассыпаться на куски!</span>"
	max_integrity = 250
	light_color = "#EF078E"
	var/time_remaining = 300 //Amount of seconds left to vote on whether or not to activate the beacon
	var/list/voters  //People who have voted to activate the beacon
	var/votes_needed = 0 //How many votes are needed to activate the beacon
	var/available = FALSE //If the beacon can be used

/obj/structure/destructible/clockwork/heralds_beacon/Initialize(mapload)
	. = ..()
	voters = list()
	START_PROCESSING(SSprocessing, src)

/obj/structure/destructible/clockwork/heralds_beacon/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	. = ..()

/obj/structure/destructible/clockwork/heralds_beacon/process()
	if(!available)
		if(istype(SSticker.mode, /datum/game_mode/clockwork_cult))
			available = TRUE
		else
			return
	if(!SSticker.mode.servants_of_ratvar.len)
		return
	if(!votes_needed)
		var/servants = SSticker.mode.servants_of_ratvar.len
		if(servants)
			votes_needed = round(servants * 0.66)
	time_remaining--
	if(!time_remaining)
		hierophant_message("<span class='bold sevtug_small'>[src] потерял свою силу и больше не может быть активирован.</span>")
		for(var/mob/M in GLOB.player_list)
			if(isobserver(M) || is_servant_of_ratvar(M))
				M.playsound_local(M, 'sound/magic/blind.ogg', 50, FALSE)
		available = FALSE
		icon_state = "interdiction_lens_unwrenched"
		STOP_PROCESSING(SSprocessing, src)

/obj/structure/destructible/clockwork/heralds_beacon/examine(mob/user)
	. = ..()
	if(isobserver(user) || is_servant_of_ratvar(user))
		if(!available)
			if(!GLOB.ratvar_approaches)
				. += "<span class='bold alloy'>Он больше не может быть активирован.</span>"
			else
				. += "<span class='bold neovgre_small'>Он был активирован!</span>"
		else
			. += "<span class='brass'>Осталось <b>[time_remaining]</b> секунд[time_remaining % 10 == 1 && time_remaining % 100 != 11 ? "а" : (time_remaining % 10 >= 2 && time_remaining % 10 <= 4 && (time_remaining % 100 < 10 || time_remaining % 100 >= 20) ? "ы" : "")] для голосования.</span>"
			. += "<span class='big brass'>Для активации маяка собрано <b>[voters.len]/[votes_needed]</b> голосов!</span>"

/obj/structure/destructible/clockwork/heralds_beacon/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(!is_servant_of_ratvar(user))
		to_chat(user, "<span class='notice'>Вы можете сказать, насколько силен [src]; вы знаете, что к нему лучше не прикасаться.</span>")
		return
	if(!available)
		to_chat(user, "<span class='danger'>Вы больше не можете голосовать с помощью [src].</span>")
		return
	var/voting = !(user.key in voters)
	if(alert(user, "[voting ? "Проголосовать за " : "Отменить свой голос за"] активацию маяка?", "Маяк Геральда", "Изменить голос", "Отмена") == "Отмена")
		return
	if(!user.canUseTopic(src) || !is_servant_of_ratvar(user) || !available)
		return
	if(voting)
		if(user.key in voters)
			return
		voters += user.key
	else
		if(!(user.key in voters))
			return
		voters -= user.key
	var/votes_left = votes_needed - voters.len
	message_admins("[ADMIN_LOOKUPFLW(user)] has [voting ? "voted" : "undone their vote"] to activate [src]! [ADMIN_JMP(user)]")
	hierophant_message("<span class='brass'><b>[user.real_name]</b> [voting ? "проголосовал" : "отозвал свой голос"] за активацию [src]! Маяку [votes_left == 1 ? "нужен" : "нужно"] ещё [votes_left] голос[votes_left % 10 == 1 && votes_left % 100 != 11 ? "" : (votes_left % 10 >= 2 && votes_left % 10 <= 4 && (votes_left % 100 < 10 || votes_left % 100 >= 20) ? "а" : "ов")] для активации.")
	for(var/mob/M in GLOB.player_list)
		if(isobserver(M) || is_servant_of_ratvar(M))
			M.playsound_local(M, 'sound/magic/clockwork/fellowship_armory.ogg', 50, FALSE)
	if(!votes_left)
		herald_the_justiciar()

/obj/structure/destructible/clockwork/heralds_beacon/proc/herald_the_justiciar()
	priority_announce("Могущественная группа фанатичных культистов, следующих за Ратваром, нагло пожертвовала скрытностью ради власти. \
	Попытайтесь остановить их.", title = "Юстициар идёт", sound = 'sound/magic/clockwork/ark_activation.ogg')
	GLOB.ratvar_approaches = TRUE
	available = FALSE
	STOP_PROCESSING(SSprocessing, src)
	icon_state = "interdiction_lens_active"
	hierophant_message("<span class='big bold brass'>Активация маяка придала вашей команде огромную силу! Многие из ваших объектов получили постоянную энергию!</span>")
	for(var/mob/living/simple_animal/hostile/clockwork/C in GLOB.all_clockwork_mobs)
		if(C.stat == DEAD)
			continue
		C.update_values()
		to_chat(C, C.empower_string)
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(is_servant_of_ratvar(H))
			to_chat(H, "<span class='bold alloy'>Энергия маяка превращает ваше тело в часовой механизм! Теперь вы защищены от многих опасностей, а ваше тело более устойчиво к повреждениям!</span>")
			H.set_species(/datum/species/golem/clockwork/no_scrap)
	var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar
	G.recalls_remaining++
