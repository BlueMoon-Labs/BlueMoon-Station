/obj/effect/mob_spawn/imaginary_friend
	//job_description ставим при иницализации
	short_desc = "Вы воображаемый друг. Вы абсолютно преданы своему другу, несмотря ни на что."
	flavour_text = "Главное не косплейте одного рокера с протезом."
	important_info = "Учитывайте, павергейм наказуем."
	show_flavour = TRUE
	banType = ROLE_PAI
	loadout_enabled = FALSE
	can_load_appearance = TRUE
	roundstart = FALSE
	category = "trauma"
	mob_type = /mob/living/carbon/human // чат верим? Нужно чтобы не менять проверку на can_load_appearance
	var/mob/camera/imaginary_friend/friend
	var/datum/brain_trauma/special/imaginary_friend/trauma
	var/mob/living/carbon/owner

/obj/effect/mob_spawn/imaginary_friend/Initialize(mapload, datum/brain_trauma/special/imaginary_friend/quirk)
	trauma = quirk
	friend = quirk.friend
	job_description = "[trauma.owner.real_name] Imaginary Friend"
	. = ..()

/obj/effect/mob_spawn/imaginary_friend/create(ckey, name, load_character)
	if(!ckey || trauma.friend_initialized)
		return
	trauma.friend_initialized = TRUE
	var/mob/new_user = get_mob_by_ckey(ckey) // я сам в шоке, что в crate передаётся ckey, а не моб юзер
	new_user.transfer_ckey(friend, FALSE)
	friend.setup_friend(load_character)
	trauma.friend_spawner = null
	friend.reset_perspective(owner)
	QDEL_NULL(src)

/mob/camera/imaginary_friend/reset_perspective(atom/A)
	if(!client)
		return
	client.set_eye(owner)
	client.perspective = EYE_PERSPECTIVE
	SEND_SIGNAL(src, COMSIG_MOB_RESET_PERSPECTIVE, A)
	return TRUE
