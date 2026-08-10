// ПОРТАТИВНЫЙ КАЛЬЯН by Pingvas

/obj/item/hookah
	name = "portable hookah"
	desc = "Компактный кальян. Разверните на ровном месте, чтобы использовать."
	icon = 'modular_bluemoon/icons/obj/hookah.dmi'
	icon_state = "kalik_truba"
	item_state = "kalik_truba"
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 2
	throw_speed = 1
	throw_range = 4
	custom_price = 200

/obj/item/hookah/attack_self(mob/user)
	deploy_hookah(user, get_turf(user))

/obj/item/hookah/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(proximity && isopenturf(target) && user.CanReach(target))
		deploy_hookah(user, target)

/obj/item/hookah/proc/deploy_hookah(mob/user, turf/location)
	if(!isopenturf(location))
		to_chat(user, span_warning("Нужно ровное место."))
		return
	user.visible_message(span_notice("[user] разворачивает [src]."), span_notice("Вы разворачиваете [src]."))
	playsound(src, 'sound/items/ratchet.ogg', 30, TRUE)
	var/obj/structure/hookah/H = new(location)
	H.add_fingerprint(user)
	transfer_fingerprints_to(H)
	qdel(src)

/obj/effect/temp_visual/smoke_ring
	icon = 'icons/effects/atmospherics.dmi'
	icon_state = "water_vapor"
	duration = 15
	alpha = 120
	pixel_x = -8
	pixel_y = -8

/obj/effect/temp_visual/smoke_ring/Initialize(mapload)
	. = ..()
	animate(src, transform = matrix()*2, alpha = 0, time = duration)

// шланг
/obj/item/clothing/mask/hookah_hose
	name = "hookah hose"
	desc = "Гибкий шланг с мундштуком."
	icon = 'modular_bluemoon/icons/obj/hookah.dmi'
	icon_state = "hookah_hose"
	item_state = "hookah_hose"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_MASK
	body_parts_covered = null
	throwforce = 0
	var/obj/structure/hookah/hookah = null
	var/datum/beam/hose_beam = null

/obj/item/clothing/mask/hookah_hose/Destroy()
	QDEL_NULL(hose_beam)
	UnregisterSignal(loc, COMSIG_MOVABLE_MOVED)
	if(hookah)
		hookah.hose = null
		hookah.update_icon()
		hookah = null
	return ..()

/obj/item/clothing/mask/hookah_hose/on_attack_hand(mob/user, act_intent, unarmed_attack_flags)
	if(hookah && get_dist(user, hookah) > hookah.range)
		return FALSE
	return ..()

/obj/item/clothing/mask/hookah_hose/equipped(mob/user, slot, initial)
	. = ..()
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_move))

/obj/item/clothing/mask/hookah_hose/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	if(hookah)
		hookah.update_icon()

/obj/item/clothing/mask/hookah_hose/Moved(atom/OldLoc, Dir)
	. = ..()
	update_beam()
	if(hookah)
		hookah.update_icon()
	if(hookah && !ismob(OldLoc) && get_dist(hookah, src) > hookah.range && ismob(loc))
		var/mob/M = loc
		M.dropItemToGround(src, TRUE)

/obj/item/clothing/mask/hookah_hose/on_enter_storage(obj/item/storage/S)
	. = ..()
	if(hookah)
		hookah.update_icon()

/obj/item/clothing/mask/hookah_hose/proc/on_mob_move(atom/old_loc, dir)
	SIGNAL_HANDLER
	if(hookah && get_dist(hookah, src) > hookah.range && ismob(loc))
		var/mob/M = loc
		M.dropItemToGround(src, TRUE)

/obj/item/clothing/mask/hookah_hose/proc/update_beam()
	QDEL_NULL(hose_beam)
	if(!hookah || loc == hookah)
		return
	if(ismob(loc))
		hose_beam = loc.Beam(hookah, icon_state="wire", icon='modular_bluemoon/icons/effects/beam.dmi', time=INFINITY, maxdistance=10, beam_sleep_time=1)
	else
		hose_beam = Beam(hookah, icon_state="wire", icon='modular_bluemoon/icons/effects/beam.dmi', time=INFINITY, maxdistance=10, beam_sleep_time=1)

/obj/item/clothing/mask/hookah_hose/attack_self(mob/user)
	if(!hookah)
		to_chat(user, span_warning("Шланг не подключен к кальяну."))
		return
	if(!hookah.lit)
		to_chat(user, span_warning("Кальян не горит."))
		return
	if(hookah.reagents.total_volume <= 0)
		to_chat(user, span_warning("Колба пуста."))
		return
	if(get_dist(src, hookah) > hookah.range)
		to_chat(user, span_warning("Шланг слишком далеко от кальяна!"))
		return

	user.visible_message(span_notice("[user] начинает делать глубокую затяжку..."), span_notice("Вы начинаете делать глубокую затяжку..."))
	if(!do_after(user, 2 SECONDS, target = user))
		return
	if(hookah.reagents.total_volume <= 0)
		to_chat(user, span_warning("Колба опустела!"))
		return
	user.visible_message(span_notice("[user] делает глубокую затяжку."), span_notice("Вы делаете глубокую затяжку."))
	playsound(user, 'modular_bluemoon/sound/effects/hookah_inhale.ogg', 40, TRUE) // затяжка плейсхолдер

	// Усиленная доза
	var/fraction = min(REAGENTS_METABOLISM * 3 / hookah.reagents.total_volume, 1)
	hookah.reagents.reaction(user, INGEST, fraction)
	hookah.reagents.trans_to(user, REAGENTS_METABOLISM * 3)

	SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "hookah", /datum/mood_event/hookah_smoked)

	// Бурление затяг
	playsound(hookah, 'modular_bluemoon/sound/items/hookah/bubble.ogg', 90, TRUE)

	user.dizziness += 3

	// Дым
	var/turf/user_turf = get_turf(user)
	for(var/i in 1 to 2)
		new /obj/effect/particle_effect/smoke/cigsmoke(user_turf)

	// Кольцо
	if(prob(40))
		var/obj/effect/temp_visual/smoke_ring/R = new(user_turf)
		R.setDir(user.dir)

	// Облако дыма при затяжке у кальяна
	var/turf/T = get_turf(hookah)
	var/mixcolor = mix_color_from_reagents(hookah.reagents.reagent_list)
	for(var/i in 1 to 3)
		var/obj/effect/temp_visual/small_smoke/halfsecond/S = new(T)
		if(mixcolor)
			S.color = mixcolor
		S.alpha = 220
		S.pixel_x = rand(-14, 14)
		S.pixel_y = rand(-6, 14)
