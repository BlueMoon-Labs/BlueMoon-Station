#define MOTHER_FILE "mother.json"

/datum/hallucination/your_mother
	var/obj/effect/hallucination/simple/your_mother/mother

/datum/hallucination/your_mother/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	. = ..()
	if(QDELETED(src))
		return
	if(!C.client || C.stat == UNCONSCIOUS)
		qdel(src)
		return
	var/list/spawn_locs = list()
	for(var/turf/open/floor in view(C, 4))
		if(floor.is_blocked_turf(exclude_mobs = TRUE))
			continue
		spawn_locs += floor
	if(!length(spawn_locs))
		qdel(src)
		return
	var/turf/spawn_loc = pick(spawn_locs)
	mother = new(spawn_loc, C)
	feedback_details += "Mother: [spawn_loc.x],[spawn_loc.y],[spawn_loc.z]"
	INVOKE_ASYNC(src, PROC_REF(follow_owner))
	point_at(C)
	talk("[capitalize(C.real_name)]!!!!")
	var/list/scold_lines = list(
		pick_list_replacements(MOTHER_FILE, "do_something"),
		pick_list_replacements(MOTHER_FILE, "be_upset"),
		pick_list_replacements(MOTHER_FILE, "get_reprimanded"),
	)
	var/delay = 2 SECONDS
	for(var/line in scold_lines)
		addtimer(CALLBACK(src, PROC_REF(talk), line), delay)
		delay += 2 SECONDS
	addtimer(CALLBACK(src, PROC_REF(exit)), delay + 4 SECONDS)

/datum/hallucination/your_mother/proc/follow_owner()
	while(target && !QDELETED(target) && mother && !QDELETED(mother) && !QDELETED(src))
		if(get_dist(mother, target) > 1)
			var/turf/next_turf = get_step_towards(mother, target)
			if(next_turf && mother.loc != next_turf)
				mother.forceMove(next_turf)
				mother.setDir(get_dir(mother, target))
		sleep(2)

/datum/hallucination/your_mother/proc/point_at(atom/pointed_atom)
	var/turf/tile = get_turf(pointed_atom)
	if(!tile || !mother || QDELETED(mother))
		return
	var/obj/visual = image('icons/mob/screen_gen.dmi', mother.loc, "arrow", FLY_LAYER)
	animate(visual, pixel_x = (tile.x - mother.x) * world.icon_size, pixel_y = (tile.y - mother.y) * world.icon_size, time = 1.7, easing = QUAD_EASING|EASE_OUT)
	if(mother.owner_client)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay), visual, list(mother.owner_client), 2.5 SECONDS)

/datum/hallucination/your_mother/proc/talk(text)
	if(!target || QDELETED(target) || !mother || QDELETED(mother))
		return
	var/datum/language/understood_language = target.get_random_understood_language()
	var/spans = list("game say")

	if(target.client)
		if(target.client.prefs.chat_on_map)
			target.create_chat_message(mother, understood_language, text, spans)
		else
			var/image/speech_overlay = image('icons/mob/talk.dmi', mother, "default0", FLY_LAYER)
			INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(flick_overlay), speech_overlay, list(target.client), 30)

	var/message = target.compose_message(mother, understood_language, text, null, null, null, TRUE)
	to_chat(target, message)

/datum/hallucination/your_mother/proc/exit()
	qdel(src)

/datum/hallucination/your_mother/Destroy()
	QDEL_NULL(mother)
	return ..()

/datum/outfit/yourmother
	name = "Твоя мать"

	uniform = /obj/item/clothing/under/color/jumpskirt/red
	neck = /obj/item/clothing/neck/oldcross
	shoes = /obj/item/clothing/shoes/sandal

/datum/outfit/yourmother/post_equip(mob/living/carbon/human/user, visuals_only = FALSE)
	. = ..()
	user.hair_style = "Braided"
	user.update_hair()

/obj/effect/hallucination/simple/your_mother
	gender = FEMALE
	name = "Твоя мать"
	desc = "Она недовольна."

/obj/effect/hallucination/simple/your_mother/Initialize(mapload, mob/living/carbon/hallucinator)
	var/flat_outfit
	var/datum/preferences/flat_prefs
	if(ishuman(hallucinator) && !isplasmaman(hallucinator))
		flat_outfit = /datum/outfit/yourmother
		flat_prefs = hallucinator.client?.prefs
	else if(isplasmaman(hallucinator))
		image_icon = 'icons/turf/floors.dmi'
		image_state = "liquidplasma"
	else if(istype(hallucinator, /mob/living/simple_animal/pet/dog/corgi/Ian))
		flat_outfit = /datum/outfit/job/hop
		name = "Глава персонала"
	else
		image_icon = hallucinator.icon
		image_state = hallucinator.icon_state
		px = hallucinator.pixel_x
		py = hallucinator.pixel_y
	if(flat_outfit)
		image_icon = 'icons/effects/effects.dmi'
		image_state = "nothing"
	. = ..()
	// get_flat_human_icon уступает тик, а Initialize спать нельзя
	if(flat_outfit && . != INITIALIZE_HINT_QDEL)
		INVOKE_ASYNC(src, PROC_REF(render_flat_image), flat_prefs, flat_outfit)

/obj/effect/hallucination/simple/your_mother/proc/render_flat_image(datum/preferences/flat_prefs, flat_outfit)
	var/icon/flat_icon = get_flat_human_icon(null, null, flat_prefs, DUMMY_HUMAN_SLOT_HALLUCINATION, list(SOUTH), flat_outfit)
	if(QDELETED(src))
		return
	image_icon = flat_icon
	image_state = ""
	Show()
