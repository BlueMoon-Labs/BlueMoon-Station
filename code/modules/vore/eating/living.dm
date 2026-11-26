///////////////////// Mob Living /////////////////////
/mob/living
	var/vore_flags = 0
	// Determines if the mechanical vore preferences button will be displayed on the mob or not.
	var/showvoreprefs = TRUE
	/// Default to no vore capability.
	var/obj/belly/vore_selected
	/// List of vore containers inside a mob
	var/list/vore_organs = list()
	/// What the character tastes like
	var/taste_desc
	/// What the character smells like
	var/smell_desc
	/// Next time vore sounds get played for the prey, do not change manually as it is intended to be set automatically
	var/next_preyloop
	/// Глобальная приватность поглощения,.. если включена, режим "Default" у нутра ведёт себя тихо
	var/eating_privacy_global = FALSE
	/// Имя до переименования поглощённой добычей (для восстановления)
	var/vore_absorbed_old_name

//
// Hook for generic creation of stuff on new creatures
//
/hook/living_new/proc/vore_setup(mob/living/M)
	if(M.vore_flags & NO_VORE) //If the mob isn't supposed to have a stomach, let's not give it an insidepanel so it can make one for itself, or a stomach.
		return TRUE
	add_verb(M, /mob/living/proc/insidePanel)

	//Tries to load prefs if a client is present otherwise gives freebie stomach
	spawn(2 SECONDS) // long delay because the server delays in its startup. just on the safe side.
		if(M)
			M.init_vore()

	//return TRUE to hook-caller
	return TRUE

/mob/living/proc/init_vore()
	vore_flags |= VORE_INIT
	//Something else made organs, meanwhile.
	if(LAZYLEN(vore_organs))
		return TRUE

	//We'll load our client's organs if we have one
	if(client?.prefs)
		if(!copy_from_prefs_vr())
			to_chat(src,"<span class='warning'>ERROR: You seem to have saved vore prefs, but they couldn't be loaded.</span>")
			return FALSE
		if(LAZYLEN(vore_organs))
			vore_selected = vore_organs[1]
			return TRUE

/mob/living/proc/lazy_init_belly()
	if(!length(vore_organs))
		LAZYINITLIST(vore_organs)
		var/obj/belly/B = new /obj/belly(src)
		vore_selected = B
		B.immutable = TRUE
		B.name = "Stomach"
		B.desc = "It appears to be rather warm and wet. Makes sense, considering it's inside [name]."
		B.can_taste = TRUE
		return TRUE

// Handle being clicked, perhaps with something to devour
//

			// Refactored to use centralized vore code system - Leshana

			// Critical adjustments due to TG grab changes - Poojawa

/mob/living/proc/vore_attack(var/mob/living/user, var/mob/living/prey, var/mob/living/pred)
	set waitfor = FALSE
	if(!user || !prey || !pred)
		return

	if(!isliving(pred)) //no badmin, you can't feed people to ghosts or objects.
		return

	lazy_init_belly()
	if(pred == prey) //you click your target
		if(!(pred.vore_flags & FEEDING))
			to_chat(user, "<span class='notice'>They aren't able to be fed.</span>")
			to_chat(pred, "<span class='notice'>[user] tried to feed you themselves, but you aren't voracious enough to be fed.</span>")
			return
		feed_self_to_grabbed(user, pred)

	else if(pred == user) //you click yourself
		feed_grabbed_to_self(user, prey)

	else // click someone other than you/prey
		if(!(pred.vore_flags & FEEDING))
			to_chat(user, "<span class='notice'>They aren't voracious enough to be fed.</span>")
			to_chat(pred, "<span class='notice'>[user] tried to feed you [prey], but you aren't voracious enough to be fed.</span>")
			return
		if(!(prey.vore_flags & FEEDING))
			to_chat(user, "<span class='notice'>They aren't able to be fed to someone.</span>")
			to_chat(prey, "<span class='notice'>[user] tried to feed you to [pred], but you aren't able to be fed to them.</span>")
			return
		feed_grabbed_to_other(user, prey, pred)
//
// Eating procs depending on who clicked what
//
/mob/living/proc/feed_grabbed_to_self(var/mob/living/user, var/mob/living/prey)
	user.lazy_init_belly()
	var/belly = user.vore_selected
	return perform_the_nom(user, prey, user, belly)

/mob/living/proc/feed_self_to_grabbed(var/mob/living/user, var/mob/living/pred)
	pred.lazy_init_belly()
	var/belly = input("Choose Belly") in pred.vore_organs
	return perform_the_nom(user, user, pred, belly)

/mob/living/proc/feed_grabbed_to_other(var/mob/living/user, var/mob/living/prey, var/mob/living/pred)
	pred.lazy_init_belly()
	var/belly = input("Choose Belly") in pred.vore_organs
	return perform_the_nom(user, prey, pred, belly)

//
// Master vore proc that actually does vore procedures
//

/mob/living/proc/perform_the_nom(var/mob/living/user, var/mob/living/prey, var/mob/living/pred, var/obj/belly/belly, var/delay)
	//Sanity
	if(!user || !prey || !pred || !istype(belly) || !(belly in pred.vore_organs))
		testing("[user] attempted to feed [prey] to [pred], via [lowertext(belly.name)] but it went wrong.")
		return

	if(!(prey.vore_flags & DEVOURABLE))
		to_chat(user, "Это нельзя съесть!")
		return FALSE

	// Согласие ссд, не трогать отключившихся игроков без разрешения
	if(prey.ckey && !prey.client && !prey.stat && (prey.vore_flags & NO_AFK_PREY))
		to_chat(user, span_warning("Добыча не разрешает есть себя, пока она AFK."))
		return FALSE
	if(pred.ckey && !pred.client && (pred.vore_flags & NO_AFK_PRED))
		to_chat(user, span_warning("Хищник не разрешает кормить себя, пока он AFK."))
		return FALSE

	if(!belly.feedable && user != belly.owner)
		to_chat(user, span_warning("Это нутро не принимает кормление со стороны."))
		to_chat(belly.owner, span_warning("Кто-то пытался покормить вас, но ваш [belly.get_display_name_lower()] к этому не готов."))
		return FALSE

	// Ограничение вместимости действует только для простых мобов
	if(isanimal(pred) && belly.vore_capacity > 0)
		var/inside_count = 0
		for(var/mob/living/M in belly.contents)
			inside_count++
		if(inside_count >= belly.vore_capacity)
			to_chat(user, span_warning("Это нутро уже полное."))
			return FALSE

	// BLUEMOON ADD START - сверхтяжёлых персонажей нельзя перемещать с помощью Vore, если жрёт не такой же сверхтяж
	if(prey.mob_weight > MOB_WEIGHT_HEAVY && pred.mob_weight < MOB_WEIGHT_HEAVY_SUPER)
		to_chat(user, span_warning("[prey] слишком тяжёлый для этого!"))
		return FALSE
	// BLUEMOON ADD END

	// The belly selected at the time of noms
	var/attempt_msg = "ERROR: Vore message couldn't be created. Notify a dev. (at)"
	var/success_msg = "ERROR: Vore message couldn't be created. Notify a dev. (sc)"

	// Prepare messages
	if(user == pred) //Feeding someone to yourself
		attempt_msg = span_warning("[pred.name] пытается [lowertext(belly.vore_verb)] [prey.name] в свой [belly.get_display_name_lower()]!")
		success_msg = span_warning("[pred.name] умудряется [lowertext(belly.vore_verb)] [prey.name] в свой [belly.get_display_name_lower()]!")
	else //Feeding someone to another person
		attempt_msg = span_warning("[user.name] пытается [pred.name] [lowertext(belly.vore_verb)] [prey.name] в свой [belly.get_display_name_lower()]!")
		success_msg = span_warning("[user.name] умудряется [pred.name] [lowertext(belly.vore_verb)] [prey.name] в свой [belly.get_display_name_lower()]!")

	if(!prey.Adjacent(user)) // let's not even bother attempting it yet if they aren't next to us.
		return FALSE

	var/message_range = belly.get_privacy_range()

	// Announce that we start the attempt!
	user.visible_message(attempt_msg, vision_distance = message_range)

	// Now give the prey time to escape... return if they did
	var/swallow_time
	if(delay)
		swallow_time = delay
	else
		swallow_time = istype(prey, /mob/living/carbon/human) ? belly.human_prey_swallow_time : belly.nonhuman_prey_swallow_time

	//Timer and progress bar
	if(!do_after(user, swallow_time, prey))
		return FALSE // Prey escaped (or user disabled) before timer expired.

	if(!prey.Adjacent(user)) //double check'd just in case they moved during the timer and the do_mob didn't fail for whatever reason
		return FALSE

	// If we got this far, nom successful! Announce it!
	user.visible_message(success_msg, vision_distance = message_range)

	// Actually shove prey into the belly.
	belly.nom_mob(prey, user)
	stop_pulling()

	// Flavor handling
	if(belly.can_taste && prey.get_taste_message(FALSE))
		to_chat(belly.owner, span_notice("[prey] ощущается по вкусу как [prey.get_taste_message(FALSE)]."))

	// Inform Admins
	var/prey_braindead
	var/prey_stat
	if(prey.ckey)
		prey_stat = prey.stat//only return this if they're not an unmonkey or whatever
		if(!prey.client)//if they disconnected, tell us
			prey_braindead = TRUE
	if (pred == user)
		message_admins("[ADMIN_LOOKUPFLW(pred)] ate [ADMIN_LOOKUPFLW(prey)][!prey_braindead ? "" : " (BRAINDEAD)"][prey_stat ? " (DEAD/UNCONSCIOUS)" : ""].")
		pred.log_message("[key_name(pred)] ate [key_name(prey)].", LOG_ATTACK, target = prey)
		prey.log_message("[key_name(prey)] was eaten by [key_name(pred)].", LOG_ATTACK, target = pred)
	else
		message_admins("[ADMIN_LOOKUPFLW(user)] forced [ADMIN_LOOKUPFLW(pred)] to eat [ADMIN_LOOKUPFLW(prey)].")
		user.log_message("[key_name(user)] forced [key_name(pred)] to eat [key_name(prey)].", LOG_ATTACK, target = pred)
		pred.log_message("[key_name(user)] forced [key_name(pred)] to eat [key_name(prey)].", LOG_ATTACK, target = prey)
		prey.log_message("[key_name(user)] forced [key_name(pred)] to eat [key_name(prey)].", LOG_ATTACK, target = pred)
	return TRUE

//
//End vore code.


//
// Our custom resist catches for /mob/living
//
/mob/living/proc/vore_process_resist()

	//Are we resisting from inside a belly?
	if(isbelly(loc))
		var/obj/belly/B = loc
		B.relay_resist(src)
		return TRUE //resist() on living does this TRUE thing.

	//Other overridden resists go here

	return FALSE

// internal slimy button in case the loop stops playing but the player wants to hear it
/mob/living/proc/preyloop_refresh()
	stop_sound_channel(CHANNEL_PREYLOOP) // sanity just in case
	if(isbelly(loc))
		var/sound/preyloop = sound('sound/vore/prey/loop.ogg')
		SEND_SOUND(src, preyloop)
	else
		to_chat(src, span_alert("Ты не находишься в ком-либо, закуска ты этакая!"))

// OOC Escape code for pref-breaking or AFK preds
//
/mob/living/proc/escapeOOC()
	//You're in a belly!
	if(isbelly(loc))
		var/obj/belly/B = loc
		var/confirm = alert(src, "Ты внутри хищника. Используй это, если не можешь выбраться сам, а хищник AFK или отключился.", "Подтверждение", "Да", "Отмена")
		if(confirm != "Да" || loc != B)
			return
		//Actual escaping
		B.release_specific_contents(src,TRUE) //we might as well take advantage of that specific belly's handling. Else we stay blinded forever.
		message_admins("[src] used OOC escape to escape from [B.owner]'s belly.")
		log_consent("[src] used OOC escape to escape from [B.owner]'s belly.")
		src.stop_sound_channel(CHANNEL_PREYLOOP)
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "fedprey", /datum/mood_event/fedprey)
		for(var/mob/living/simple_animal/SA in range(10))
			SA.prey_excludes[src] = world.time

		if(isanimal(B.owner))
			var/mob/living/simple_animal/SA = B.owner
			SA.update_icons()

	//You're in a dogborg!
	else if(istype(loc, /obj/item/dogborg/sleeper))
		var/obj/item/dogborg/sleeper/belly = loc //The belly!

		var/confirm = alert(src, "Ты в слипере борга. Это для выхода из нарушающих предпочтения ситуаций или если хищник отключился. Можно также выбраться сопротивлением.", "Подтверждение", "Да", "Отмена")
		if(confirm != "Да" || loc != belly)
			return
		//Actual escaping
		belly.go_out(src) //Just force-ejects from the borg as if they'd clicked the eject button.
		message_admins("[src] used OOC escape from a dogborg sleeper.")
		log_consent("[src] used OOC escape from a dogborg sleeper.")
	else
		to_chat(src, span_alert("Закуска, ты ни в ком не находишься для использования этой возможности."))

/mob/living/proc/copy_to_prefs_vr()
	if(!client || !client.prefs)
		to_chat(src,"<span class='warning'>Ты пытаешься сохранить настройки воре, но у персонажа нет client.prefs. Сообщи разработчику.</span>")
		return FALSE

	client.prefs.vore_flags = vore_flags // there's garbage data in here, but it doesn't matter
	client.prefs.eating_privacy_global = eating_privacy_global

	var/list/serialized = list()
	for(var/belly in vore_organs)
		var/obj/belly/B = belly
		serialized += list(B.serialize()) //Can't add a list as an object to another list in Byond. Thanks.

	client.prefs.belly_prefs = serialized

	client.prefs.save_character()

	return TRUE

//
//	Proc for applying vore preferences, given bellies
//
/mob/living/proc/copy_from_prefs_vr()
	if(!client || !client.prefs)
		to_chat(src,"<span class='warning'>Ты пытаешься применить настройки воре, но у персонажа нет client.prefs. Сообщи разработчику.</span>")
		return FALSE
	vore_flags |= VOREPREF_INIT
	COPY_SPECIFIC_BITFIELDS(vore_flags, client.prefs.vore_flags, DIGESTABLE | DEVOURABLE | FEEDING | LICKABLE | SMELLABLE | ABSORBABLE | MOBVORE | NO_HEALBELLY | NO_TEMPERATURE | NO_AUTOTRANSFER | NO_REMAINS | NO_AFK_PREY | NO_AFK_PRED)
	eating_privacy_global = client.prefs.eating_privacy_global

	release_vore_contents(silent = TRUE)
	QDEL_LIST(vore_organs)
	for(var/entry in client.prefs.belly_prefs)
		list_to_object(entry,src)
	if(LAZYLEN(vore_organs))
		vore_selected = vore_organs[1]

	return TRUE

//
// Release everything in every vore organ
//
/mob/living/proc/release_vore_contents(var/include_absorbed = TRUE, var/silent = FALSE)
	for(var/belly in vore_organs)
		var/obj/belly/B = belly
		B.release_all_contents(include_absorbed, silent)

//
// Returns examine messages for bellies
//
/mob/living/proc/examine_bellies()
	if(!show_pudge()) //Some clothing or equipment can hide this.
		return ""

	var/message = ""
	for (var/belly in vore_organs)
		var/obj/belly/B = belly
		message += B.get_examine_msg()

	return message

//
// Whether or not people can see our belly messages
//
/mob/living/proc/show_pudge()
	return TRUE //Can override if you want.

/mob/living/carbon/human/show_pudge()
	//A uniform could hide it.
	if(istype(w_uniform,/obj/item/clothing))
		var/obj/item/clothing/under = w_uniform
		if(under.hides_bulges)
			return FALSE

	//We return as soon as we find one, no need for 'else' really.
	if(istype(wear_suit,/obj/item/clothing))
		var/obj/item/clothing/suit = wear_suit
		if(suit.hides_bulges)
			return FALSE


	return ..()

/mob/living/proc/get_taste_message(allow_generic = TRUE)
	if(taste_desc)
		. += "[taste_desc]"
	else if(allow_generic)
		if(ishuman(src))
			var/mob/living/carbon/human/H = src
			. += "нормальный [H.custom_species ? H.custom_species : H.dna.species]"
		else
			. += "старый добрый [name]"
	return .

/mob/living/proc/get_smell_message()
	if(smell_desc)
		. += "[smell_desc]"
	else if(ishuman(src))
		var/mob/living/carbon/human/H = src
		. += "нормальный [H.custom_species ? H.custom_species : H.dna.species]"
	else
		. += "старый добрый [name]"
	return .

//	Check if an object is capable of eating things, based on vore_organs
//
/proc/has_vore_belly(var/mob/living/O)
	if(istype(O))
		if(O.vore_organs.len > 0)
			return TRUE

	return FALSE
