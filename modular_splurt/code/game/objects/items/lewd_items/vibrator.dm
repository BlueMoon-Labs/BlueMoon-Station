//Hyperstation 13 vibrator
//For all them subs/bottoms out there, that wanna give someone the power to make them cum remotely.

#define VIB_OFF 0
#define VIB_LOW 1
#define VIB_MEDIUM 2
#define VIB_HIGH 3

#define VIB_VOL_LOW 30
#define VIB_VOL_MEDIUM 60
#define VIB_VOL_HIGH 80

/datum/looping_sound/lewd/vibrator
	start_sound = 'modular_splurt/sound/lewd/vibrate.ogg'
	start_length = 1
	mid_sounds = 'modular_splurt/sound/lewd/vibrate.ogg'
	mid_length = 1
	end_sound = 'modular_splurt/sound/lewd/vibrate.ogg'
	falloff_distance = 1
	falloff_exponent = 5
	extra_range = SILENCED_SOUND_EXTRARANGE

/datum/looping_sound/lewd/vibrator/low
	volume = VIB_VOL_LOW

/datum/looping_sound/lewd/vibrator/medium
	volume = VIB_VOL_MEDIUM

/datum/looping_sound/lewd/vibrator/high
	volume = VIB_VOL_HIGH

/obj/item/electropack/vibrator
	name = "remote vibrator"
	desc = "A remote device that can deliver pleasure at a fair. It has three intensities that can be set by twisting the base."
	icon = 'modular_splurt/icons/obj/vibrator.dmi'
	icon_state = "vibe"
	item_state = "vibe"
	w_class = WEIGHT_CLASS_SMALL
	//slot_flags = ITEM_SLOT_DENYPOCKET   //no more pocket shockers
	var/mode = VIB_OFF
	var/style = "long"
	var/last = 0
	var/vibrate_constant = 0
	var/inside = FALSE
	var/timer = 0
	var/interval = 5

	var/datum/looping_sound/lewd/vibrator/low/soundloop1
	var/datum/looping_sound/lewd/vibrator/medium/soundloop2
	var/datum/looping_sound/lewd/vibrator/high/soundloop3

/obj/item/electropack/vibrator/Initialize() //give the device its own code
	. = ..()
	code = rand(1,30)
	soundloop1 = new(src, FALSE)
	soundloop2 = new(src, FALSE)
	soundloop3 = new(src, FALSE)

/obj/item/electropack/vibrator/ComponentInitialize()
	. = ..()
	var/list/procs_list = list(
		"before_inserting" = CALLBACK(src, PROC_REF(item_inserting)),
		"after_inserting" = CALLBACK(src, PROC_REF(item_inserted)),
		"after_removing" = CALLBACK(src, PROC_REF(item_removed)),
	)
	AddComponent(/datum/component/genital_equipment, list(ORGAN_SLOT_VAGINA, ORGAN_SLOT_ANUS, ORGAN_SLOT_PENIS, ORGAN_SLOT_BREASTS, ORGAN_SLOT_BUTT, ORGAN_SLOT_BELLY), procs_list, style == "small")

/obj/item/electropack/vibrator/Destroy()
	STOP_PROCESSING(SSobj,src)
	stopVibing()
	QDEL_NULL(soundloop1)
	QDEL_NULL(soundloop2)
	QDEL_NULL(soundloop3)
	. = ..()

/obj/item/electropack/vibrator/proc/item_inserting(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	if(!(G.owner.client?.prefs?.erppref == "Yes"))
		to_chat(user, span_warning("They don't want you to do that!"))
		return FALSE

	if(locate(src.type) in G.contents)
		if(user == G.owner)
			to_chat(user, span_notice("You already have a vibrator inside your [G]!"))
		else
			to_chat(user, span_notice("\The <b>[G.owner]</b>'s [G] already has a vibrator inside!"))
		return FALSE

	if(user == G.owner)
		G.owner.visible_message(span_warning("\The <b>[user]</b> is trying to [style == "long" ? "insert" : "attach"] a vibrator [style == "long" ? "inside" : "to"] themselves!"),\
			span_warning("You try to [style == "long" ? "insert" : "attach"] a vibrator [style == "long" ? "inside" : "to"] yourself!"))
	else
		G.owner.visible_message(span_warning("\The <b>[user]</b> is trying to [style == "long" ? "insert" : "attach"] a vibrator [style == "long" ? "inside" : "to"] \the <b>[G.owner]</b>!"),\
			span_warning("\The <b>[user]</b> is trying to [style == "long" ? "insert" : "attach"] a vibrator [style == "long" ? "inside" : "to"] you!"))

	if(!do_mob(user, G.owner, 5 SECONDS))
		return FALSE

/obj/item/electropack/vibrator/proc/item_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	to_chat(user, span_userlove("You attach [src] to <b>\The [G.owner]</b>'s [G]."))
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	inside = TRUE

/obj/item/electropack/vibrator/proc/item_removed(datum/source, obj/item/organ/genital/G, mob/user)
	. = TRUE
	to_chat(user, span_userlove("You retrieve [src] from <b>\The [G.owner]</b>'s [G]."))
	playsound(G.owner, 'modular_sand/sound/lewd/champ_fingering.ogg', 50, 1, -1)
	inside = FALSE

/obj/item/electropack/vibrator/small //can go anywhere
	name = "small remote vibrator"
	style = "small"
	icon_state = "vibesmall"
	item_state = "vibesmall"

/obj/item/electropack/vibrator/AltClick(mob/living/user)
	ui_interact(user)

/obj/item/electropack/vibrator/attack_self(mob/user)
	if(!istype(user))
		return
	if(isliving(user))
		playsound(user, 'sound/effects/clock_tick.ogg', 50, 1, -1)
		var/was_processing = datum_flags & DF_ISPROCESSING
		switch(mode)
			if(VIB_OFF)
				mode = VIB_LOW
				to_chat(user, span_notice("You twist the bottom of [src], setting it to the low setting."))
			if(VIB_LOW)
				mode = VIB_MEDIUM
				to_chat(user, span_notice("You twist the bottom of [src], setting it to the medium setting."))
			if(VIB_MEDIUM)
				mode = VIB_HIGH
				to_chat(user, span_warning("You twist the bottom of [src], setting it to the high setting."))
			if(VIB_HIGH)
				mode = VIB_OFF
				stopVibing()
				to_chat(user, span_notice("You twist the bottom of [src], setting it to the off."))
		if(was_processing)
			startVibing()
		return

/obj/item/electropack/vibrator/verb/toggle_constant()

	set name = "Toggle constant vibration"
	set category = "Object"

	vibrate_constant = !vibrate_constant
	playsound(usr, 'sound/effects/clock_tick.ogg', 50, 1, -1)
	if(vibrate_constant)
		to_chat(usr, "[src] режим постоянной вибрации.")
	else
		stopVibing()
		to_chat(usr, "[src] режим единичной вибрации.")



/obj/item/electropack/vibrator/receive_signal(datum/signal/signal)
	if(!signal || signal.data["code"] != code)
		return

	if(mode == VIB_OFF)	// just off
		return

	if(last > world.time)
		return

	last = world.time + 3 SECONDS //lets stop spam.

	switch(vibrate_constant)
		if(FALSE)
			stopVibing()
			vibrate_once()
		if(TRUE)
			if(datum_flags & DF_ISPROCESSING)
				stopVibing()
			else
				timer = 0
				startVibing()

/obj/item/electropack/vibrator/proc/vibrate_once()
	if(inside)
		vibe(loc)
	switch(mode)
		if(VIB_LOW)
			playsound(src, 'modular_splurt/sound/lewd/vibrate.ogg', VIB_VOL_LOW, 1, -1)
		if(VIB_MEDIUM)
			playsound(src, 'modular_splurt/sound/lewd/vibrate.ogg', VIB_VOL_MEDIUM, 1, -1)
		if(VIB_HIGH)
			playsound(src, 'modular_splurt/sound/lewd/vibrate.ogg', VIB_VOL_HIGH, 1, -1)

	if(style == "long")
		icon_state = "vibing"
		sleep(20)
		icon_state = "vibe"
	else
		icon_state = "vibingsmall"
		sleep(20)
		icon_state = "vibesmall"

/obj/item/electropack/vibrator/proc/vibe(var/genitals)
	if(!istype(genitals, /obj/item/organ/genital))
		return
	var/obj/item/organ/genital/G = genitals
	var/mob/living/carbon/U = G.owner
	var/intencity = 6*mode
	if(G)
		switch(G.type) //just being fancy
			if(/obj/item/organ/genital/breasts)
				to_chat(U, span_love("[src] vibrates against your nipples!"))
			else
				to_chat(U, span_love("[src] vibrates against your [G.name]!"))

	U.handle_post_sex(intencity, null, src) //give pleasure
	U.plug13_genital_emote(G, intencity * 5)

	switch(mode)
		if(VIB_LOW) //low, setting for RP, it wont force your character to do anything.
			to_chat(U, span_love("You feel pleasure surge through your [G.name]"))
			if(U.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
				U.do_jitter_animation() //do animation without heartbeat
		if(VIB_MEDIUM) //med, can make you cum
			to_chat(U, span_love("You feel intense pleasure surge through your [G.name]"))
			if(U.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
				U.do_jitter_animation()
		if(VIB_HIGH) //high, makes you stun
			to_chat(U, span_userdanger("You feel overpowering pleasure surge through your [G.name]"))
			if(U.client?.prefs.cit_toggles & SEX_JITTER) //By Gardelin0
				U.Jitter(3)
			U.Stun(30)
			if(prob(50))
				U.emote("moan")

/obj/item/electropack/vibrator/process(delta_time)
	if(mode == VIB_OFF)	// just off
		stopVibing()
		return

	timer -= delta_time
	if(timer >= 0) // chech interval
		return
	else
		timer = interval

	if(inside)
		vibe(loc)

/obj/item/electropack/vibrator/proc/startVibing()
	if(style == "long")
		icon_state = "vibing"
	else
		icon_state = "vibingsmall"

	switch(mode)
		if(VIB_LOW)
			soundloop2.stop()
			soundloop3.stop()
			soundloop1.start()
		if(VIB_MEDIUM)
			soundloop1.stop()
			soundloop3.stop()
			soundloop2.start()
		if(VIB_HIGH)
			soundloop1.stop()
			soundloop2.stop()
			soundloop3.start()

	START_PROCESSING(SSobj,src)

/obj/item/electropack/vibrator/proc/stopVibing()
	if(style == "long")
		icon_state = "vibe"
	else
		icon_state = "vibesmall"

	soundloop1.stop()
	soundloop2.stop()
	soundloop3.stop()

	STOP_PROCESSING(SSobj,src)

#undef VIB_OFF
#undef VIB_LOW
#undef VIB_MEDIUM
#undef VIB_HIGH

#undef VIB_VOL_LOW
#undef VIB_VOL_MEDIUM
#undef VIB_VOL_HIGH
