


//									IDEAS		--
//					An object that disguises your coffin while you're in it!
//
//					An object that lets your lair itself protect you from sunlight, like a coffin would (no healing tho)



// Hide a random object somewhere on the station:
//		var/turf/targetturf = get_random_station_turf()
//		var/turf/targetturf = get_safe_random_station_turf()




// 		CRYPT OBJECTS
//
//
// 	PODIUM		Stores your Relics
//
// 	ALTAR		Transmute items into sacred items.
//
//	PORTRAIT	Gaze into your past to: restore mood boost?
//
//	BOOKSHELF	Discover secrets about crew and locations. Learn languages. Learn marial arts.
//
//	BRAZER		Burn rare ingredients to gleen insights.
//
//	RUG			Ornate, and creaks when stepped upon by any humanoid other than yourself and your vassals.
//
//	X COFFIN		(Handled elsewhere)
//
//	X CANDELABRA	(Handled elsewhere)
//
//	THRONE		Your mental powers work at any range on anyone inside your crypt.
//
//	MIRROR		Find any person
//
//	BUST/STATUE	Create terror, but looks just like you (maybe just in Examine?)


//		RELICS
//
//	RITUAL DAGGER
//
// 	SKULL
//
//	VAMPIRIC SCROLL
//
//	SAINTS BONES
//
//	GRIMOIRE


// 		RARE INGREDIENTS
// Ore
// Books (Manuals)


// 										NOTE:  Look up AI and Sentient Disease to see how the game handles the selector logo that only one player is allowed to see. We could add hud for vamps to that?
//											   ALTERNATIVELY, use the Vamp Huds on relics to mark them, but only show to relevant vamps?


/obj/structure/bloodsucker
	var/mob/living/carbon/human/owner // BLUEMOON EDIT - было var/mob/living/owner, нужно в таком виде для проверки на хозяина маскировки

/*
/obj/structure/bloodsucker/bloodthrone
	name = "wicked throne"
	desc = "Twisted metal shards jut from the arm rests. Very uncomfortable looking. It would take a sadistic sort to sit on this jagged piece of furniture."

/obj/structure/bloodsucker/bloodaltar
	name = "bloody altar"
	desc = "It is marble, lined with basalt, and radiates an unnerving chill that puts your skin on edge."

/obj/structure/bloodsucker/bloodstatue
	name = "bloody countenance"
	desc = "It looks upsettingly familiar..."

/obj/structure/bloodsucker/bloodportrait
	name = "oil portrait"
	desc = "A disturbingly familiar face stares back at you. On second thought, the reds don't seem to be painted in oil..."

/obj/structure/bloodsucker/bloodbrazer
	name = "lit brazer"
	desc = "It burns slowly, but doesn't radiate any heat."

/obj/structure/bloodsucker/bloodmirror
	name = "faded mirror"
	desc = "You get the sense that the foggy reflection looking back at you has an alien intelligence to it."
*/


/obj/structure/bloodsucker/vassalrack
	name = "persuasion rack"
	desc = "Если это не было задумано как пытка, значит, у кого-то есть довольно ужасные хобби."
	icon = 'icons/obj/vamp_obj.dmi'
	icon_state = "vassalrack"
	buckle_lying = FALSE
	anchored = FALSE
	density = TRUE					// Start dense. Once fixed in place, go non-dense.
	can_buckle = TRUE
	var/useLock = FALSE				// So we can't just keep dragging ppl on here.
	var/mob/buckled
	var/convert_progress = 3		// Resets on each new character to be added to the chair. Some effects should lower it...
	var/disloyalty_confirm = FALSE	// Command & Antags need to CONFIRM they are willing to lose their role (and will only do it if the Vassal'ing succeeds)
	var/disloyalty_offered = FALSE	// Has the popup been issued? Don't spam them.


/obj/structure/bloodsucker/vassalrack/deconstruct(disassembled = TRUE)
	new /obj/item/stack/sheet/metal(src.loc, 4)
	new /obj/item/stack/rods(loc, 4)
	qdel(src)

/obj/structure/bloodsucker/vassalrack/examine(mob/user)
	var/datum/antagonist/bloodsucker/B = user.mind?.has_antag_datum(ANTAG_DATUM_BLOODSUCKER) // BLUEMOON EDIT - иначе рантайм при экзейме гостом
	. = ..()
	if(B || isobserver(user))
		. += {"<span class='cult'>Это стойка вассала, которая позволяет вам превращать членов экипажа в преданных слуг на вашей службе.</span>"}
		. += {"<span class='cult'>Сначала вам нужно закрепить стойку вассала, нажав на нее, пока она находится в вашем логове.</span>"}
		. += {"<span class='cult'>Просто нажмите и удерживайте жертву, а затем перетащите ее спрайт на стойку для вассалов. Альт-клик на стойке для вассалов, чтобы отстегнуть их.</span>"}
		. += {"<span class='cult'>Убедитесь, что жертва закована, иначе она может просто убежать или оказать сопротивление, поскольку этот процесс не мгновенный.</span>"}
		. += {"<span class='cult'>Чтобы обратить жертву в слугу, просто нажмите на саму стойку вассала. Острое оружие срабатывает быстрее, чем другие инструменты.</span>"}
		if(B) // BLUEMOON ADD - иначе рантайм при экзейме гостом
			var/vassals_left = B.bloodsucker_level - B.count_vassals(user.mind)
			var/vassals_suffix = (vassals_left % 10 == 1 && vassals_left % 100 != 11) ? "" : ((vassals_left % 10 >= 2 && vassals_left % 10 <= 4 && (vassals_left % 100 < 10 || vassals_left % 100 >= 20)) ? "а" : "ов")
			. += {"<span class='cult'> Вы имеете силу только для [vassals_left] вассал[vassals_suffix]"</span>"}
/*	if(user.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
	. += {"<span class='cult'>This is the vassal rack, which allows your master to thrall crewmembers into his minions.\n
	Aid your master in bringing their victims here and keeping them secure.\n
	You can secure victims to the vassal rack by click dragging the victim onto the rack while it is secured</span>"} */

/obj/structure/bloodsucker/vassalrack/MouseDrop_T(atom/movable/O, mob/user)
	if(!O.Adjacent(src) || O == user || !isliving(O) || !isliving(user) || useLock || has_buckled_mobs() || user.incapacitated())
		return
	if(!anchored && AmBloodsucker(user))
		to_chat(user, "<span class='danger'>Пока эта стойка не будет закреплена на месте, она не сможет выполнять свои функции.</span>")
		return
	// PULL TARGET: Remember if I was pullin this guy, so we can restore this
	var/waspulling = (O == owner.pulling)
	var/wasgrabstate = owner.grab_state
	// 		* MOVE! *
	O.forceMove(drop_location())
	// PULL TARGET: Restore?
	if(waspulling)
		owner.start_pulling(O, wasgrabstate, TRUE)
		// NOTE: in bs_lunge.dm, we use [target.grabbedby(owner)], which simulates doing a grab action. We don't want that though...we're cutting directly back to where we were in a grab.
	// Do Action!
	useLock = TRUE
	if(do_mob(user, O, 50))
		attach_victim(O,user)
	useLock = FALSE

/obj/structure/bloodsucker/vassalrack/AltClick(mob/user)
	if(!has_buckled_mobs() || !isliving(user) || useLock)
		return
	// Attempt Release (Owner vs Non Owner)
	var/mob/living/carbon/C = pick(buckled_mobs)
	if(C)
		if(user == owner)
			unbuckle_mob(C)
		else
			user_unbuckle_mob(C,user)

/obj/structure/bloodsucker/vassalrack/proc/attach_victim(mob/living/M, mob/living/user)
	// Standard Buckle Check
	if(!buckle_mob(M)) // force=TRUE))
		return
	remove_disguise() // BLUEMOON ADD - маскировка пропадает при размещении жертвы
	// Attempt Buckle
	user.visible_message("<span class='notice'>[user] закрепляет [M] ремнями на стойке, обездвиживая [M.ru_ego()].</span>", \
			  		 "<span class='boldnotice'>Вы надежно закрепляете [M] на месте. Теперь [M.ru_who()] не сбежит от вас.</span>")

	playsound(src.loc, 'sound/effects/pop_expl.ogg', 25, 1)
	//M.forceMove(drop_location()) <--- CANT DO! This cancels the buckle_mob() we JUST did (even if we foced the move)
	M.setDir(2)
	density = TRUE
	var/matrix/m180 = matrix(M.transform)
	m180.Turn(180)//90)//180
	animate(M, transform = m180, time = 2)
	M.pixel_y = -2 //M.get_standard_pixel_y_offset(120)//180)
	update_icon()
	// Torture Stuff
	convert_progress = 4 			// Goes down unless you start over.
	disloyalty_confirm = FALSE		// New guy gets the chance to say NO if he's special.
	disloyalty_offered = FALSE		// Prevents spamming torture window.

/obj/structure/bloodsucker/vassalrack/user_unbuckle_mob(mob/living/M, mob/user)
	// Attempt Unbuckle
	if(!AmBloodsucker(user))
		if(M == user)
			M.visible_message("<span class='danger'>[user] пытается освободить себя со стойки!</span>",\
							"<span class='danger'>Вы пытаетесь освободить себя со стойки!</span>") //  For sound if not seen -->  "<span class='italics'>You hear a squishy wet noise.</span>")
		else
			M.visible_message("<span class='danger'>[user] пытается стащить [M] со стойки!</span>",\
							"<span class='danger'>[user] пытается освободить вас со стойки!</span>") //  For sound if not seen -->  "<span class='italics'>You hear a squishy wet noise.</span>")
		if(!do_mob(user, M, 200))
			return
		unbuckle_mob(M)
	// Did the time. Now try to do it.
	..()

/obj/structure/bloodsucker/vassalrack/unbuckle_mob(mob/living/buckled_mob, force = FALSE)
	if(!..())
		return
	var/matrix/m180 = matrix(buckled_mob.transform)
	m180.Turn(180)//-90)//180
	animate(buckled_mob, transform = m180, time = 2)
	buckled_mob.pixel_y = buckled_mob.get_standard_pixel_y_offset(180)
	src.visible_message(text("<span class='danger'>[buckled_mob.stat==DEAD?"Труп ":""][buckled_mob] соскальзывает со стойки.</span>"))
	density = FALSE
	buckled_mob.DefaultCombatKnockdown(30)
	update_icon()
	useLock = FALSE // Failsafe

/obj/structure/bloodsucker/vassalrack/attackby(obj/item/W, mob/user, params)
	if(has_buckled_mobs()) // Attack w/weapon vs guy standing there? Don't do an attack.
		attack_hand(user)
		return FALSE
	return ..()

/obj/structure/bloodsucker/vassalrack/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	//. = ..()	// Taken from sacrificial altar in divine.dm
	//if(.)
	//	return
	// Go away. Torturing.
	if(useLock)
		return
	var/datum/antagonist/bloodsucker/B = user.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	// CHECK ONE: Am I claiming this? Is it in the right place?
	if(istype(B) && !owner)
		if(!B.lair)
			to_chat(user, "<span class='danger'>У вас нет логова. Займите гроб, чтобы сделать это место своим логовом.</span>")
		if(B.lair != get_area(src))
			to_chat(user, "<span class='danger'>Вы можете активировать эту структуру только в вашем логове: [B.lair].</span>")
			return
		switch(alert(user,"Вы уверены, что хотите закрепить эту структуру здесь? Имейте ввиду, что вы не сможете её открепить.", "Закрепить [src]", "Да", "Нет"))
			if("Да")
				owner = user
				density = FALSE
				anchored = TRUE
				return //No, you cant move this ever again
	// No One Home
	if(!has_buckled_mobs())
		return
	// CHECK TWO: Am I a non-bloodsucker?
	var/mob/living/carbon/C = pick(buckled_mobs)
	if(!istype(B))
		// Try to release this guy
		user_unbuckle_mob(C, user)
		return
	// Bloodsucker Owner! Let the boy go.
	if(C.mind)
		var/datum/antagonist/vassal/V = C.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
		if(istype(V) && V.master == B || C.stat >= DEAD)
			unbuckle_mob(C)
			useLock = FALSE // Failsafe
			return
	// Just torture the boy
	torture_victim(user, C)

#define CONVERT_COST 150

/obj/structure/bloodsucker/vassalrack/proc/torture_victim(mob/living/user, mob/living/target)
	var/datum/antagonist/bloodsucker/B = user.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	// Check Bloodmob/living/M, force = FALSE, check_loc = TRUE
	if(user.blood_volume < CONVERT_COST + 5)
		to_chat(user, "<span class='notice'>У вас недостаточно крови, чтобы инициировать тёмную связь с [target].</span>")
		return
	if(B.count_vassals(user.mind) + 1 > B.bloodsucker_level) // BLUEMOON EDIT - добавлено +1, т.к. ранее можно было иметь на 1 вассала больше, чем уровень вампира
		to_chat(user, "<span class='notice'>Ваша сила ещё слишком слаба, чтобы взять больше вассалов под контроль....</span>")
		return
	// Prep...
	useLock = TRUE
	// Step One:	Tick Down Conversion from 3 to 0
	// Step Two:	Break mindshielding/antag (on approve)
	// Step Three:	Blood Ritual
	// Conversion Process
	if(convert_progress > 0)
		to_chat(user, "<span class='notice'>Вы готовитесь к тому, чтобы привлечь [target] к службе вам.</span>")
		if(!do_torture(user,target))
			to_chat(user, "<span class='danger'><i>Ритуал был прерван!</i></span>")
		else
			convert_progress -- // Ouch. Stop. Don't.
			// All done!
			if(convert_progress <= 0)
				// FAIL: Can't be Vassal
				if(!SSticker.mode.can_make_vassal(target, user, display_warning = FALSE) || HAS_TRAIT(target, TRAIT_MINDSHIELD)) // If I'm an unconvertable Antag ONLY
					to_chat(user, "<span class='danger'>не поддается на ваши уговоры. Не похоже, что их можно заставить следовать за вами, либо у них есть mindshield, либо вам слишком сложно нарушить их внешнюю лояльность.<i>\[ALT+click to release\]</span>")
					convert_progress ++ // Pop it back up some. Avoids wasting Blood on a lost cause.
				// SUCCESS: All done!
				else
					if(RequireDisloyalty(target))
						to_chat(user, "<span class='boldwarning'>[target] имеет внешние приверженности! [target.ru_who(TRUE)] потребует <i>убеждения</i>, чтобы сломить [target.ru_who()] волю!</span>")
					else
						to_chat(user, "<span class='notice'>[target] выглядит готовым для <b>тёмной связи</b>.</span>")
			// Still Need More Persuasion...
			else
				to_chat(user, "<span class='notice'>[target] нужно [convert_progress == 1?"немного":"чуть"] больше <i>убеждения</i>.</span>")
		useLock = FALSE
		return
	// Check: Mindshield & Antag
	if(!disloyalty_confirm && RequireDisloyalty(target))
		if(!do_disloyalty(user,target))
			to_chat(user, "<span class='danger'><i>Ритуал был прерван!!</i></span>")
		else if (!disloyalty_confirm)
			to_chat(user, "<span class='danger'>[target] отказывается поддаваться на ваши уговоры. Может быть, еще немного?</span>")
		else
			to_chat(user, "<span class='notice'>[target] выглядит готовым для <b>тёмной связи</b>.</span>")
		useLock = FALSE
		return
	// Check: Blood
	if(user.blood_volume < CONVERT_COST)
		to_chat(user, "<span class='notice'>У вас недостаточно крови, чтобы инициировать тёмную связь с [target], вам нужно ещё [CONVERT_COST - user.blood_volume] юнитов крови!</span>")
		useLock = FALSE
		return
	B.AddBloodVolume(-CONVERT_COST)
	target.add_mob_blood(user, "<span class='danger'>Вы использовали [CONVERT_COST] крови, чтобы получить нового вассала!</span>")
	to_chat(user, )
	user.visible_message("<span class='notice'>[user] оставляет кровавую метку на лбу [target] и подносит запястье ко [target.ru_ego()] рту!</span>", \
				  	  "<span class='notice'>Вы рисуете кровавую метку на лбу [target], подносите запястье к [target.ru_ego()] рту, и подвергаете [target.ru_ego()] к тёмной связи.</span>")
	if(!do_mob(user, src, 50))
		to_chat(user, "<span class='danger'><i>Ритуал был прерван!</i></span>")
		useLock = FALSE
		return
	// Convert to Vassal!
	if(B && B.attempt_turn_vassal(target))
		//remove_loyalties(target) // In case of Mindshield, or appropriate Antag (Traitor, Internal, etc)
		//if (!target.buckled)
		//	to_chat(user, "<span class='danger'><i>The ritual has been interrupted!</i></span>")
		//	useLock = FALSE
		//	return
		user.playsound_local(null, 'sound/effects/explosion_distant.ogg', 40, TRUE)
		target.playsound_local(null, 'sound/effects/explosion_distant.ogg', 40, TRUE)
		target.playsound_local(null, 'sound/effects/singlebeat.ogg', 40, TRUE)
		target.Jitter(25)
		target.emote("laugh")
		//remove_victim(target) // Remove on CLICK ONLY!
	useLock = FALSE

#undef CONVERT_COST
/obj/structure/bloodsucker/vassalrack/proc/do_torture(mob/living/user, mob/living/target, mult = 1)
	var/torture_time = 15 // Fifteen seconds if you aren't using anything. Shorter with weapons and such.
	var/torture_dmg_brute = 2
	var/torture_dmg_burn = 0
	// Get Bodypart
	var/target_string = ""
	var/obj/item/bodypart/BP = null
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		BP = pick(C.bodyparts)
		if(BP)
			target_string += BP.name
	// Get Weapon
	var/obj/item/I = user.get_active_held_item()
	if(!istype(I))
		I = user.get_inactive_held_item()
	// Create Strings
	var/method_string =  I?.attack_verb?.len ? pick(I.attack_verb) : pick("вредит","пытает","выворачивает","выкручивает","избивает","ранит")
	var/weapon_string = I ? I.name : pick("голыми руками","руками","пальцами","кулаками")
	// Weapon Bonus + SFX
	if(I)
		torture_time -= I.force / 4
		torture_dmg_brute += I.force / 4
		//torture_dmg_burn += I.
		if(I.sharpness == SHARP_EDGED)
			torture_time -= 1
		else if(I.sharpness == SHARP_POINTY)
			torture_time -= 2
		if(istype(I, /obj/item/weldingtool))
			var/obj/item/weldingtool/welder = I
			welder.welding = TRUE
			torture_time -= 5
			torture_dmg_burn += 5
		I.play_tool_sound(target)
	torture_time = max(50, torture_time * 10) // Minimum 5 seconds.
	// Now run process.
	if(!do_mob(user, target, torture_time * mult))
		return FALSE
	// SUCCESS
	if(I)
		playsound(loc, I.hitsound, 30, 1, -1)
		I.play_tool_sound(target)
	target.visible_message("<span class='danger'>[user] [method_string] [target_string] [target] [weapon_string]!</span>", \
						   "<span class='userdanger'>[user] [method_string] твою [target_string] [weapon_string]!</span>")
	if(!target.is_muzzled())
		if(!HAS_TRAIT(target, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - роботы не кричат от боли
			target.emote("scream")
	target.Jitter(5)
	target.apply_damages(brute = torture_dmg_brute, burn = torture_dmg_burn, def_zone = (BP ? BP.body_zone : null)) // take_overall_damage(6,0)
	return TRUE

/obj/structure/bloodsucker/vassalrack/proc/do_disloyalty(mob/living/user, mob/living/target)

	// OFFER YES/NO NOW!
	spawn(10)
		if(useLock && target && target.client) // Are we still torturing? Did we cancel? Are they still here?
			to_chat(user, "<span class='notice'>[target] была предоставлена возможность обратиться в рабство. Вы ждете их решения...</span>")
			var/alert_text = "Вас пытают! Хотите ли вы сдаться и поклясться в вечной верности [user]?"
		/*	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
				alert_text += "\n\nYou will no longer be loyal to the station!"
			if(SSticker.mode.AmValidAntag(target.mind))  */
			alert_text += "\n\nВы не потеряете своих текущих целей, но они отойдут на второй план по сравнению с волей вашего нового хозяина!"
			switch(alert(target, alert_text,"АДСКАЯ БОЛЬ! КОГДА ЖЕ ЭТО ЗАКОНЧИТСЯ?!","Да, Господин!", "НИКОГДА!"))
				if("Да, Господин!")
					disloyalty_accept(target)
				else
					disloyalty_refuse(target)
	if(!do_torture(user,target, 2))
		return FALSE

	// NOTE: We only remove loyalties when we're CONVERTED!
	return TRUE

/obj/structure/bloodsucker/vassalrack/proc/RequireDisloyalty(mob/living/target)
	return SSticker.mode.AmValidAntag(target.mind) //|| HAS_TRAIT(target, TRAIT_MINDSHIELD)

/obj/structure/bloodsucker/vassalrack/proc/disloyalty_accept(mob/living/target)
	// FAILSAFE: Still on the rack?
	if(!(locate(target) in buckled_mobs))
		return
	// NOTE: You can say YES after torture. It'll apply to next time.
	disloyalty_confirm = TRUE
	/*if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		to_chat(target, "<span class='boldnotice'>You give in to the will of your torturer. If they are successful, you will no longer be loyal to the station!</span>")
*/
/obj/structure/bloodsucker/vassalrack/proc/disloyalty_refuse(mob/living/target)
	// FAILSAFE: Still on the rack?
	if(!(locate(target) in buckled_mobs))
		return
	// Failsafe: You already said YES.
	if(disloyalty_confirm)
		return
	to_chat(target, "<span class='notice'>Ты отказываешься сдаваться! Ты не сломаешься!</span>")


/obj/structure/bloodsucker/vassalrack/proc/remove_loyalties(mob/living/target)
	// Find Mind Implant & Destroy
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		for(var/obj/item/implant/I in target.implants)
			if(I.type == /obj/item/implant/mindshield)
				I.removed(target,silent=TRUE)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/structure/bloodsucker/candelabrum
	name = "candelabrum"
	desc = "Он горит медленно, но не выделяет никакого тепла."
	icon = 'icons/obj/vamp_obj.dmi'
	icon_state = "candelabrum"
	light_color = "#66FFFF"//LIGHT_COLOR_BLUEGREEN // lighting.dm
	light_power = 3
	light_range = 0 // to 2
	density = FALSE
	anchored = FALSE
	var/lit = FALSE
///obj/structure/bloodsucker/candelabrum/is_hot() // candle.dm
	//return FALSE

/obj/structure/bloodsucker/candelabrum/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..() //return a hint

/obj/structure/bloodsucker/candelabrum/update_icon_state()
	icon_state = "candelabrum[lit ? "_lit" : ""]"

/obj/structure/bloodsucker/candelabrum/examine(mob/user)
	. = ..()
	if((AmBloodsucker(user)) || isobserver(user))
		. += {"<span class='cult'>Это волшебная свеча, которая, пока она активна, лишает рассудка смертных, которые не находятся под вашим командованием.</span>"}
		. += {"<span class='cult'>Вы можете нажать на него альт-кликом с любого расстояния, чтобы включить удаленно, или просто находиться рядом с ним и нажимать на него, чтобы включать и выключать его в обычном режиме.</span>"}
/*	if(user.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
		. += {"<span class='cult'>This is a magical candle which drains at the sanity of the fools who havent yet accepted your master, as long as it is active.\n
		You can turn it on and off by clicking on it while you are next to it</span>"} */

/obj/structure/bloodsucker/candelabrum/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	var/datum/antagonist/vassal/T = user.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
	if(AmBloodsucker(user) || istype(T))
		toggle()

/obj/structure/bloodsucker/candelabrum/AltClick(mob/user)
	// Bloodsuckers can turn their candles on from a distance. SPOOOOKY.
	if(AmBloodsucker(user))
		toggle()

/obj/structure/bloodsucker/candelabrum/proc/toggle(mob/user)
	remove_disguise() // BLUEMOON ADD - маскировка пропадает при активации или деактивации
	lit = !lit
	if(lit)
		set_light(2, 3, "#66FFFF")
		START_PROCESSING(SSobj, src)
	else
		set_light(0)
		STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/structure/bloodsucker/candelabrum/process()
	if(!lit)
		return
	for(var/mob/living/carbon/human/H in fov_viewers(7, src))
		var/datum/antagonist/vassal/T = H.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
		if(AmBloodsucker(H) || T) //We dont want vassals or vampires affected by this
			return
		H.hallucination = 20
		SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "vampcandle", /datum/mood_event/vampcandle)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   OTHER THINGS TO USE: HUMAN BLOOD. /obj/effect/decal/cleanable/blood

/obj/item/restraints/legcuffs/beartrap/bloodsucker
