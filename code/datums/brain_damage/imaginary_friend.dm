/datum/brain_trauma/special/imaginary_friend
	name = "Imaginary Friend"
	desc = "Patient can see and hear an imaginary person."
	scan_desc = "partial schizophrenia"
	gain_text = "<span class='notice'>You feel in good company, for some reason.</span>"
	lose_text = "<span class='warning'>You feel lonely again.</span>"
	var/mob/camera/imaginary_friend/friend
	var/obj/effect/mob_spawn/imaginary_friend/friend_spawner	// спавнер для гостов, находится в друге
	var/friend_initialized = FALSE
	var/try_search_friend = TRUE

/datum/brain_trauma/special/imaginary_friend/on_gain()
	if(owner.stat == DEAD || !owner.client)
		return qdel(src)
	..()
	if(try_search_friend) 	// BLUEMOON ADD если ищем друга, то делаем спавнер
		make_friend_spawner()
	else
		make_friend()	// BLUEMOON ADD END если нет, то просто делаем друга

/datum/brain_trauma/special/imaginary_friend/on_life()
	if(get_dist(owner, friend) > 9)
		friend.recall()
	//if(!friend) // BLUEMOON ADD нет друга? найдём ещё одного
	//	qdel(src)
	//	return
	if((!friend || !friend.client) && friend_initialized)
		friend_initialized = FALSE
		addtimer(CALLBACK(src, PROC_REF(reroll_friend)), 1 MINUTES) // BLUEMOON ADD END

/datum/brain_trauma/special/imaginary_friend/on_death()
	..()
	if(resilience != TRAUMA_RESILIENCE_ABSOLUTE) // BLUEMOON ADD смерть не причина избавиться от ультимативной травмы
		qdel(src) //friend goes down with the ship

/datum/brain_trauma/special/imaginary_friend/on_lose()
	..()
	QDEL_NULL(friend_spawner) // спавнер держит ссылки на trauma/friend, чистим его первым, иначе они не соберутся
	QDEL_NULL(friend)

//If the friend goes afk, make a brand new friend. Plenty of fish in the sea of imagination.
/datum/brain_trauma/special/imaginary_friend/proc/reroll_friend()
	if(friend.client) //reconnected
		friend_initialized = TRUE
		return
	friend_initialized = FALSE
	QDEL_NULL(friend)
// BLUEMOON ADD вместо анонса создаём слот для гостов
	make_friend_spawner()

/datum/brain_trauma/special/imaginary_friend/proc/make_friend_spawner()
	if(!friend)
		make_friend()
	QDEL_NULL(friend_spawner) // не плодим спавнеры при рероле
	friend_spawner = new(friend, src)
// BLUEMOON ADD END

/datum/brain_trauma/special/imaginary_friend/proc/make_friend()
	friend = new(get_turf(owner), src)

/mob/camera/imaginary_friend
	name = "imaginary friend"
	real_name = "imaginary friend"
	move_on_shuttle = TRUE
	desc = "A wonderful yet fake friend."
	see_in_dark = 0
	lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	sight = NONE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	see_invisible = SEE_INVISIBLE_LIVING
	invisibility = INVISIBILITY_MAXIMUM
	var/icon/human_image
	var/image/current_image
	var/hidden = FALSE
	var/move_delay = 0
	var/mob/living/carbon/owner
	var/datum/brain_trauma/special/imaginary_friend/trauma

	var/datum/action/innate/imaginary_join/join
	var/datum/action/innate/imaginary_hide/hide

/mob/camera/imaginary_friend/Login()
	..()
	greet()
	Show()

/mob/camera/imaginary_friend/proc/greet()
		to_chat(src, "<span class='notice'><b>You are the imaginary friend of [owner]!</b></span>")
		to_chat(src, "<span class='notice'>You are absolutely loyal to your friend, no matter what.</span>")
		to_chat(src, "<span class='notice'>You cannot directly influence the world around you, but you can see what [owner] cannot.</span>")

/mob/camera/imaginary_friend/Initialize(mapload, _trauma)
	if(!_trauma)
		return INITIALIZE_HINT_QDEL
	. = ..()

	trauma = _trauma
	owner = trauma.owner

	INVOKE_ASYNC(src, PROC_REF(setup_friend))

	join = new
	join.Grant(src)
	hide = new
	hide.Grant(src)

/mob/camera/imaginary_friend/proc/setup_friend(use_pref = FALSE) //BLUEMOON ADD сетапим друга с префом зашедшего игрока
	if(use_pref && client?.prefs)
		real_name = client.prefs.real_name
		name = real_name
		human_image = get_flat_human_icon(null, pick(SSjob.occupations), client.prefs)
		return
	//BLUEMOON ADD END

	var/gender = pick(MALE, FEMALE)
	real_name = random_unique_name(gender)
	name = real_name
	human_image = get_flat_human_icon(null, pick(SSjob.occupations))

/mob/camera/imaginary_friend/proc/Show()
	if(!client) //nobody home
		return

	//Remove old image from owner and friend
	if(owner.client)
		owner.client.images.Remove(current_image)

	client.images.Remove(current_image)

	//Generate image from the static icon and the current dir
	current_image = image(human_image, src, , MOB_LAYER, dir=src.dir)
	current_image.override = TRUE
	current_image.name = name
	if(hidden)
		current_image.alpha = 150

	//Add new image to owner and friend
	if(!hidden && owner.client)
		owner.client.images |= current_image

	client.images |= current_image

/mob/camera/imaginary_friend/Destroy()
	if(owner?.client)
		owner.client.images.Remove(human_image)
	if(client)
		client.images.Remove(human_image)
	return ..()

/mob/camera/imaginary_friend/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if (!message)
		return

	if (src.client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, "You cannot send IC messages (muted).")
			return
		if (!(ignore_spam || forced) && src.client.handle_spam_prevention(message,MUTE_IC))
			return

	friend_talk(message)

/mob/camera/imaginary_friend/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	if (client?.prefs.chat_on_map && (client.prefs.see_chat_non_mob || ismob(speaker)))
		create_chat_message(speaker, message_language, raw_message, spans, message_mode)
	to_chat(src, compose_message(speaker, message_language, raw_message, radio_freq, spans, message_mode, FALSE, source))

/mob/camera/imaginary_friend/proc/friend_talk(message)
	message = capitalize(trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN)))

	if(!message)
		return

	src.log_talk(message, LOG_SAY, tag="imaginary friend")

	var/rendered = "<span class='game say'><span class='name'>[name]</span> <span class='message'>[say_quote(message)]</span></span>"
	var/dead_rendered = "<span class='game say'><span class='name'>[name] (Imaginary friend of [owner])</span> <span class='message'>[say_quote(message)]</span></span>"

	to_chat(owner, "[rendered]")
	to_chat(src, "[rendered]")

	//speech bubble
	if(owner.client)
		var/mutable_appearance/MA = mutable_appearance('icons/mob/talk.dmi', src, "default[say_test(message)]", FLY_LAYER)
		MA.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay), MA, list(owner.client), 30)

	for(var/mob/M in GLOB.dead_mob_list)
		if(!M.client || !isobserver(M))
			continue
		if(get_dist(M, owner) > 7 || M.z != owner.z)
			if(!(M.client.prefs.chat_toggles & CHAT_GHOSTEARS)) //they're talking normally and we have hearing at any range off
				continue
		to_chat(M, "[FOLLOW_LINK(M, owner)] [dead_rendered]")

/mob/camera/imaginary_friend/Move(NewLoc, Dir = 0)
	if(world.time < move_delay)
		return FALSE
	if(get_dist(src, owner) > 9)
		recall()
		move_delay = world.time + 10
		return FALSE
	forceMove(NewLoc)
	move_delay = world.time + 1

/mob/camera/imaginary_friend/forceMove(atom/destination)
	dir = get_dir(get_turf(src), destination)
	loc = destination
	Show()

/mob/camera/imaginary_friend/proc/recall()
	if(!owner || loc == owner)
		return FALSE
	forceMove(owner)

/datum/action/innate/imaginary_join
	name = "Join"
	desc = "Join your owner, following them from inside their mind."
	icon_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	background_icon_state = "bg_revenant"
	button_icon_state = "join"

/datum/action/innate/imaginary_join/Activate()
	var/mob/camera/imaginary_friend/I = owner
	I.recall()

/datum/action/innate/imaginary_hide
	name = "Hide"
	desc = "Hide yourself from your owner's sight."
	icon_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	background_icon_state = "bg_revenant"
	button_icon_state = "hide"

/datum/action/innate/imaginary_hide/proc/update_status()
	var/mob/camera/imaginary_friend/I = owner
	if(I.hidden)
		name = "Show"
		desc = "Become visible to your owner."
		button_icon_state = "unhide"
	else
		name = "Hide"
		desc = "Hide yourself from your owner's sight."
		button_icon_state = "hide"
	UpdateButtons()

/datum/action/innate/imaginary_hide/Activate()
	var/mob/camera/imaginary_friend/I = owner
	I.hidden = !I.hidden
	I.Show()
	update_status()

//down here is the trapped mind
//like imaginary friend but a lot less imagination and more like mind prison//

/datum/brain_trauma/special/imaginary_friend/trapped_owner
	name = "Trapped Victim"
	desc = "Patient appears to be targeted by an invisible entity."
	gain_text = ""
	lose_text = ""
	random_gain = FALSE
	try_search_friend = FALSE

/datum/brain_trauma/special/imaginary_friend/trapped_owner/make_friend()
	friend = new /mob/camera/imaginary_friend/trapped(get_turf(owner), src)

/datum/brain_trauma/special/imaginary_friend/trapped_owner/reroll_friend() //no rerolling- it's just the last owner's hell
	if(friend.client) //reconnected
		return
	friend_initialized = FALSE
	QDEL_NULL(friend)
	qdel(src)

/mob/camera/imaginary_friend/trapped
	name = "figment of imagination?"
	real_name = "figment of imagination?"
	desc = "The previous host of this body."

/mob/camera/imaginary_friend/trapped/greet()
	to_chat(src, "<span class='notice'><b>You have managed to hold on as a figment of the new host's imagination!</b></span>")
	to_chat(src, "<span class='notice'>All hope is lost for you, but at least you may interact with your host. You do not have to be loyal to them.</span>")
	to_chat(src, "<span class='notice'>You cannot directly influence the world around you, but you can see what the host cannot.</span>")

/mob/camera/imaginary_friend/trapped/setup_friend()
	real_name = "[owner.real_name]?"
	name = real_name
	human_image = icon('icons/mob/lavaland/lavaland_monsters.dmi', icon_state = "curseblob")
