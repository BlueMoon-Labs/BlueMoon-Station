/obj/effect/temp_visual/heretic_hammer
	icon = HERETIC_HAMMER_FX_ICON
	duration = 0.6 SECONDS
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_hammer/grasp
	icon_state = "crush_ring"
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_hammer/crush_ring
	icon_state = "crush_ring"
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_hammer/wall_impact
	icon_state = "wall_impact"
	duration = 0.9 SECONDS

/obj/effect/temp_visual/heretic_hammer/quake_ring
	icon_state = "quake_ring"
	duration = 1 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_hammer/quake_ring/Initialize(mapload)
	. = ..()
	for(var/turf/open/floor in range(HERETIC_HAMMER_QUAKE_RANGE, loc))
		if(floor != loc && heretic_hammer_reaches(loc, floor))
			new /obj/effect/temp_visual/heretic_hammer/quake_ripple(floor, get_dist(loc, floor))

/// Волна Сотрясения доходит до клетки: в иконке задержка по расстоянию, так волна катится от центра.
/obj/effect/temp_visual/heretic_hammer/quake_ripple
	icon_state = "quake_ripple_1"
	duration = 1 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_hammer/quake_ripple/Initialize(mapload, distance = 1)
	icon_state = "quake_ripple_[clamp(distance, 1, HERETIC_HAMMER_QUAKE_RANGE)]"
	return ..()

/obj/effect/temp_visual/heretic_hammer/fissure
	icon_state = "fissure"
	duration = 1 SECONDS
	randomdir = FALSE
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_hammer/anvil_land
	icon_state = "anvil_land"
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_hammer/anvil_break
	icon_state = "anvil_break"
	duration = 1.2 SECONDS

/obj/effect/temp_visual/heretic_hammer/mark_shatter
	icon_state = "mark_shatter"
	duration = 0.9 SECONDS

/obj/effect/temp_visual/heretic_hammer/rage
	icon_state = "rage"
	duration = 0.9 SECONDS

/obj/effect/temp_visual/heretic_hammer/catch
	icon_state = "catch"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_hammer/quench
	icon_state = "quench_steam"
	duration = 1 SECONDS

/obj/effect/temp_visual/heretic_hammer/anvil_shadow
	icon_state = "anvil_shadow"
	duration = HERETIC_HAMMER_ANVIL_TELEGRAPH
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_hammer/great_shockwave
	icon = HERETIC_HAMMER_LARGE_ICON
	icon_state = "great_shockwave"
	duration = 1 SECONDS
	pixel_x = -16
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_hammer/floor_crack
	icon_state = "floor_crack_1"
	duration = HERETIC_HAMMER_CRACKS_TIME
	layer = ABOVE_OPEN_TURF_LAYER
	plane = FLOOR_PLANE

/obj/effect/temp_visual/heretic_hammer/floor_crack/Initialize(mapload)
	icon_state = "floor_crack_[rand(1, 3)]"
	. = ..()
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/datum/movespeed_modifier/heretic_hammer_swing
	multiplicative_slowdown = HERETIC_HAMMER_SWING_SLOWDOWN

/datum/movespeed_modifier/heretic_hammer_dazed
	multiplicative_slowdown = 1

/// Замах: секунду Молот над головой, затем окно, в котором удар в двух руках - Сокрушающий.
/datum/status_effect/heretic_hammer_swing
	id = "heretic_hammer_swing"
	duration = HERETIC_HAMMER_SWING_WINDUP + HERETIC_HAMMER_SWING_WINDOW
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_hammer_swing
	examine_text = span_warning("SUBJECTPRONOUN держит тяжёлый молот над головой: отойдите, пока он не опустился.")
	var/datum/weakref/hammer_ref
	var/ready = FALSE
	var/ready_timer
	var/mutable_appearance/raised

/datum/status_effect/heretic_hammer_swing/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_hammer/hammer)
	hammer_ref = WEAKREF(hammer)
	return ..()

/datum/status_effect/heretic_hammer_swing/on_apply()
	. = ..()
	if(!. || !hammer_ref?.resolve())
		return FALSE
	raised = mutable_appearance(HERETIC_HAMMER_FX_ICON, "windup", ABOVE_MOB_LAYER)
	raised.pixel_y = 12
	raised.appearance_flags = RESET_COLOR | KEEP_APART
	owner.add_overlay(raised)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_swing)
	heretic_hammer_sound(owner, "windup", 50, TRUE)
	owner.visible_message(span_warning("[owner] заносит тяжёлый молот над головой!"), span_notice("Вы заносите Молот. Через [HERETIC_HAMMER_SWING_WINDUP / (1 SECONDS)] секунду удар в двух руках станет Сокрушающим."))
	ready_timer = addtimer(CALLBACK(src, PROC_REF(become_ready)), HERETIC_HAMMER_SWING_WINDUP, TIMER_STOPPABLE)
	return TRUE

/datum/status_effect/heretic_hammer_swing/proc/become_ready()
	ready_timer = null
	if(QDELETED(src))
		return
	ready = TRUE
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_swing)
	owner.add_filter("heretic_hammer_swing", 2, list("type" = "outline", "color" = "#ffd9a0", "size" = 1))
	to_chat(owner, span_notice("Молот занесён: следующий удар в двух руках за [HERETIC_HAMMER_SWING_WINDOW / (1 SECONDS)] секунды будет Сокрушающим."))
	if(linked_alert)
		linked_alert.desc = "Молот занесён: следующий удар в двух руках - Сокрушающий, +[HERETIC_HAMMER_CRUSH_DAMAGE] урона и полёт на [HERETIC_HAMMER_CRUSH_THROW] клетки."

/datum/status_effect/heretic_hammer_swing/proc/cancel(reason)
	if(reason)
		to_chat(owner, span_warning(reason))
	qdel(src)

/datum/status_effect/heretic_hammer_swing/on_remove()
	if(ready_timer)
		deltimer(ready_timer)
		ready_timer = null
	if(raised)
		owner.cut_overlay(raised)
		raised = null
	owner.remove_filter("heretic_hammer_swing")
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_swing)
	hammer_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_hammer_swing
	name = "Замах"
	desc = "Молот поднимается над головой. Опустите его из двух рук - и замах сорвётся."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "hammer_swing"

/// Подхват после Хватки кузни: снова взять Молот в две руки - и следующий удар будет Сокрушающим.
/datum/status_effect/heretic_hammer_catch
	id = "heretic_hammer_catch"
	duration = HERETIC_HAMMER_CATCH_TIME
	status_type = STATUS_EFFECT_REFRESH
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_hammer_catch
	var/primed = FALSE

/datum/status_effect/heretic_hammer_catch/refresh()
	if(primed)
		return
	return ..()

/datum/status_effect/heretic_hammer_catch/proc/prime()
	if(primed)
		return FALSE
	primed = TRUE
	duration = world.time + HERETIC_HAMMER_SWING_WINDOW
	heretic_hammer_sound(owner, "catch", 50, TRUE)
	new /obj/effect/temp_visual/heretic_hammer/catch(get_turf(owner))
	to_chat(owner, span_notice("Подхват! Следующий удар Молотом в двух руках - Сокрушающий, без Замаха."))
	if(linked_alert)
		linked_alert.desc = "Подхват: следующий удар Молотом в двух руках - Сокрушающий."
	return TRUE

/atom/movable/screen/alert/status_effect/heretic_hammer_catch
	name = "Подхват"
	desc = "Хватка ударила: возьмите Молот в две руки, пока горит значок, и следующий удар будет Сокрушающим."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "hammer_catch"

/datum/status_effect/heretic_hammer_dazed
	id = "heretic_hammer_dazed"
	duration = HERETIC_HAMMER_QUAKE_SLOW
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/heretic_hammer_dazed/on_apply()
	. = ..()
	if(.)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_dazed)

/datum/status_effect/heretic_hammer_dazed/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_dazed)
	return ..()

/obj/effect/heretic_hammer_nail_crack
	name = "cracked floor"
	desc = "Пол вокруг проломлен, будто в него что-то вбили с огромной силой."
	icon = HERETIC_HAMMER_FX_ICON
	icon_state = "nail_crack"
	layer = ABOVE_OPEN_TURF_LAYER
	plane = FLOOR_PLANE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Вбитый в пол: не встаёт и не ходит, тащить его может только еретик, руки свободны.
/datum/status_effect/heretic_hammer_nailed
	id = "heretic_hammer_nailed"
	duration = HERETIC_HAMMER_NAIL_TIME
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_hammer_nailed
	examine_text = span_warning("SUBJECTPRONOUN по плечи в проломленном полу и не может встать: выдерните ломом или растолкайте.")
	var/datum/weakref/hammer_ref
	var/mob/living/nailer
	var/obj/effect/heretic_hammer_nail_crack/crack
	var/applied = FALSE
	var/held_since = 0
	var/sunk = 0

/datum/status_effect/heretic_hammer_nailed/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_hammer/hammer)
	hammer_ref = WEAKREF(hammer)
	nailer = hammer?.hammer_body
	return ..()

/datum/status_effect/heretic_hammer_nailed/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
	if(!. || !hammer || QDELETED(nailer) || owner.stat == DEAD || !isturf(owner.loc))
		return FALSE
	applied = TRUE
	held_since = world.time
	hammer.nailed += src
	ADD_TRAIT(owner, TRAIT_FLOORED, id)
	ADD_TRAIT(owner, TRAIT_MOBILITY_NOMOVE, id)
	owner.update_mobility()
	sunk = HERETIC_HAMMER_NAIL_SINK
	animate(owner, pixel_z = owner.pixel_z + sunk, time = 0.2 SECONDS, flags = ANIMATION_PARALLEL)
	crack = new(owner.loc)
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(shaken_off))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice_starting))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_ATOM_EX_ACT, PROC_REF(on_explosion))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(nailer, COMSIG_PARENT_QDELETING, PROC_REF(on_nailer_deleted))
	heretic_capture_hold(owner, HERETIC_HAMMER_CAPTURE)
	heretic_capture_lock_pull(owner, nailer, HERETIC_HAMMER_CAPTURE)
	if(linked_alert)
		linked_alert.desc = "Вас вбили в пол: вы не встанете и не уйдёте ещё [HERETIC_HAMMER_NAIL_TIME / (1 SECONDS)] секунд, но руки свободны. Выдернуть вас может член экипажа с ломом за [HERETIC_HAMMER_NAIL_PRY_TIME / (1 SECONDS)] секунды, растолкать - за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)]."
	return TRUE

/datum/status_effect/heretic_hammer_nailed/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(istype(item, /obj/item/nullrod))
		free("вас коснулись нулевым жезлом", "[owner.ru_ego()] коснулись нулевым жезлом", user)
		return COMPONENT_NO_AFTERATTACK
	if(item.tool_behaviour != TOOL_CROWBAR || user == source || user == nailer || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(pry), user, item)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_hammer_nailed/proc/pry(mob/living/user, obj/item/tool)
	if(LAZYFIND(user.do_afters, owner))
		return FALSE
	user.visible_message(span_warning("[user] поддевает [owner] ломом, выламывая из пола."), span_notice("Вы выдираете [owner] из пола. Не отходите [DisplayTimeText(HERETIC_HAMMER_NAIL_PRY_TIME)]."))
	playsound(owner, 'sound/items/crowbar.ogg', 60, TRUE)
	if(!do_after(user, HERETIC_HAMMER_NAIL_PRY_TIME, owner, extra_checks = CALLBACK(src, PROC_REF(still_nailed))))
		return FALSE
	if(QDELETED(src))
		return FALSE
	free("вас выдернули ломом", "[owner.ru_ego()] выдернули ломом", user)
	return TRUE

/datum/status_effect/heretic_hammer_nailed/proc/still_nailed()
	return !QDELETED(src)

/datum/status_effect/heretic_hammer_nailed/proc/on_explosion(datum/source, severity, target)
	SIGNAL_HANDLER
	free("взрыв выбил вас из пола", "взрыв выбил [owner.ru_ego()] из пола")

/datum/status_effect/heretic_hammer_nailed/proc/shaken_off(datum/source)
	SIGNAL_HANDLER
	free("вас растолкали", "[owner.ru_ego()] растолкали")

/datum/status_effect/heretic_hammer_nailed/proc/on_death(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Тащить вбитого может только вбивший: пролом едет следом, любое другое перемещение выбивает из пола.
/datum/status_effect/heretic_hammer_nailed/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	if(!crack || crack.loc == owner.loc)
		return
	if(isturf(owner.loc) && owner.pulledby && owner.pulledby == nailer)
		crack.forceMove(owner.loc)
		return
	free("вас сдвинули с места", "[owner.ru_ego()] сдвинули с места")

/// Удар Молота по вбитому сокращает вбивку; когда срок вышел, вбитый свободен.
/datum/status_effect/heretic_hammer_nailed/proc/struck()
	duration -= HERETIC_HAMMER_NAIL_HIT_CUT
	if(duration <= world.time)
		free("удары выбили вас из пола", "удары выбили [owner.ru_ego()] из пола")

/datum/status_effect/heretic_hammer_nailed/proc/on_sacrifice_starting(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_hammer_nailed/proc/on_nailer_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Вбитый свободен раньше срока: self_text - ему самому, other_text - еретику и в логи.
/datum/status_effect/heretic_hammer_nailed/proc/free(self_text, other_text, mob/living/rescuer)
	if(QDELETED(src))
		return
	owner.visible_message(span_notice("[owner] вырывается из проломленного пола."), span_notice("Вы снова можете встать: [self_text]."))
	heretic_hammer_sound(owner, "nail_free", 50, TRUE)
	if(!QDELETED(nailer))
		to_chat(nailer, span_warning("[owner] больше не вбит в пол: [other_text]."))
	if(rescuer)
		log_combat(rescuer, owner, "освобождает из Вбить в пол", null, other_text)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
	hammer?.lesson_event("nail_free", owner, other_text)
	qdel(src)

/datum/status_effect/heretic_hammer_nailed/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_EX_ACT, COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED))
		if(nailer)
			UnregisterSignal(nailer, COMSIG_PARENT_QDELETING)
		REMOVE_TRAIT(owner, TRAIT_FLOORED, id)
		REMOVE_TRAIT(owner, TRAIT_MOBILITY_NOMOVE, id)
		owner.update_mobility()
		animate(owner, pixel_z = owner.pixel_z - sunk, time = 0.2 SECONDS, flags = ANIMATION_PARALLEL)
		sunk = 0
		var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
		hammer?.nailed -= src
		hammer?.lesson_event("nail_end", owner)
		heretic_capture_unlock_pull(owner, HERETIC_HAMMER_CAPTURE)
		heretic_capture_unhold(owner, HERETIC_HAMMER_CAPTURE)
		heretic_capture_release(owner, HERETIC_HAMMER_CAPTURE, 0, heretic_capture_held_for(held_since))
	QDEL_NULL(crack)
	nailer = null
	hammer_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_hammer_nailed
	name = "Вбит в пол"
	desc = "Вас вбили в пол: вы не встанете и не уйдёте, но руки свободны. Член экипажа с ломом выдернет вас, растолкать тоже можно."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "hammer_nailed"

/// Разбитая броня: третья трещина Звона наковальни.
/datum/status_effect/heretic_hammer_shattered
	id = "heretic_hammer_shattered"
	duration = HERETIC_HAMMER_SHATTER_TIME
	status_type = STATUS_EFFECT_REFRESH
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_hammer_shattered
	examine_text = span_warning("SUBJECTPRONOUN в треснувшей броне и одежде, будто по ним ударили кувалдой.")
	var/armored = FALSE

/datum/status_effect/heretic_hammer_shattered/on_apply()
	. = ..()
	if(!.)
		return FALSE
	if(ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.physiology.armor = human_owner.physiology.armor.modifyRating(melee = -HERETIC_HAMMER_SHATTER_ARMOR, bullet = -HERETIC_HAMMER_SHATTER_ARMOR, laser = -HERETIC_HAMMER_SHATTER_ARMOR, energy = -HERETIC_HAMMER_SHATTER_ARMOR)
		armored = TRUE
	return TRUE

/datum/status_effect/heretic_hammer_shattered/on_remove()
	if(armored && ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		human_owner.physiology.armor = human_owner.physiology.armor.modifyRating(melee = HERETIC_HAMMER_SHATTER_ARMOR, bullet = HERETIC_HAMMER_SHATTER_ARMOR, laser = HERETIC_HAMMER_SHATTER_ARMOR, energy = HERETIC_HAMMER_SHATTER_ARMOR)
	armored = FALSE
	return ..()

/atom/movable/screen/alert/status_effect/heretic_hammer_shattered
	name = "Разбитая броня"
	desc = "Звон наковальни расколол защиту: 10 секунд броня держит удары, пули и лазеры на 40 хуже."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "hammer_shattered"

/// Звон наковальни: удары Молотом в двух руках добавляют трещины, третья раскалывает броню.
/datum/status_effect/eldritch/hammer
	id = "hammer_mark"
	mark_name = "Звон наковальни"
	mark_alert_state = "sigil_hammer"
	effect_sprite_icon = HERETIC_HAMMER_FX_ICON
	effect_sprite = "mark_crack_1"
	effect_sprite_layer = ABOVE_MOB_LAYER
	detonation_sound = 'modular_bluemoon/sound/heretic/hammer_mark_shatter.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_hammer/mark_shatter
	examine_text = span_warning("По телу бегут тонкие светящиеся трещины, как по раскалённому железу. Не подставляйтесь под молот: третья трещина раскалывает броню.")
	var/datum/weakref/hammer_ref
	/// Еретик Молота, чей удар сейчас дошёл до меченого: трещину даёт его Молот, а не Молот того, кто ставил метку.
	var/datum/weakref/striker_ref
	var/cracks = 0
	var/applied = FALSE

/datum/status_effect/eldritch/hammer/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_hammer/hammer)
	hammer_ref = WEAKREF(hammer)
	. = ..()
	if(linked_alert)
		linked_alert.desc = "По вам бегут трещины. Каждый удар молотом еретика в двух руках добавит новую, третья на [HERETIC_HAMMER_SHATTER_TIME / (1 SECONDS)] секунд ослабит броню на [HERETIC_HAMMER_SHATTER_ARMOR] и собьёт с ног."

/datum/status_effect/eldritch/hammer/on_apply()
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
	if(!hammer || !..())
		return FALSE
	applied = TRUE
	hammer.marks += src
	return TRUE

/datum/status_effect/eldritch/hammer/update_owner_underlay(atom/source, list/overlays)
	marked_underlay.icon_state = "mark_crack_[clamp(cracks, 1, HERETIC_HAMMER_MARK_CRACKS)]"
	marked_underlay.alpha = cracks ? 255 : HERETIC_HAMMER_MARK_FAINT_ALPHA
	overlays += marked_underlay

/// Удар клинком пути по меченому: трещина, только если Молот в двух руках; третья раскалывает.
/datum/status_effect/eldritch/hammer/on_effect()
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
	var/mob/living/smith = striker_ref?.resolve()
	striker_ref = null
	if(!hammer || !smith || !heretic_hammer_held(smith, TRUE) || owner.stat == DEAD)
		return
	cracks++
	owner.update_icon()
	hammer.lesson_event("crack", owner, cracks)
	if(cracks < HERETIC_HAMMER_MARK_CRACKS)
		heretic_hammer_sound(owner, "mark_ring", 50, TRUE)
		return
	owner.apply_status_effect(/datum/status_effect/heretic_hammer_shattered)
	owner.Knockdown(HERETIC_HAMMER_SHATTER_KNOCKDOWN)
	shake_camera(owner, 3, 2)
	owner.visible_message(span_danger("По [owner] с громким звоном расходятся трещины!"), span_userdanger("Звон наковальни раскалывает вашу защиту!"))
	log_combat(smith, owner, "раскалывает броню Звоном наковальни")
	hammer.lesson_event("shatter", owner)
	return ..()

/datum/status_effect/eldritch/hammer/on_remove()
	if(applied)
		var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
		hammer?.marks -= src
	hammer_ref = null
	striker_ref = null
	return ..()

/// Клеймо кузни в стене: гудит, когда мимо идёт экипаж; сварка или нулевой жезл стирают его.
/obj/effect/heretic_hammer_brand
	name = "hammer dent"
	desc = "Глубокая вмятина в металле стены, на дне её тлеет оттиск молота. Металл вокруг ещё тёплый. Сварка или нулевой жезл сотрут её."
	icon = HERETIC_HAMMER_FX_ICON
	icon_state = "brand"
	layer = ABOVE_ALL_MOB_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_ICON
	var/datum/weakref/hammer_ref
	var/erasing = FALSE
	COOLDOWN_DECLARE(owner_notice)
	COOLDOWN_DECLARE(hum_sound)
	var/static/list/sense_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)

/obj/effect/heretic_hammer_brand/Initialize(mapload, datum/eldritch_knowledge/base_hammer/hammer)
	. = ..()
	if(!hammer || !iswallturf(loc))
		return INITIALIZE_HINT_QDEL
	hammer_ref = WEAKREF(hammer)
	hammer.brands += src
	add_overlay(emissive_appearance(icon, "brand", offset_spokesman = src))
	RegisterSignal(loc, COMSIG_TURF_CHANGE, PROC_REF(on_turf_change))
	AddComponent(/datum/component/connect_range, src, sense_connections, HERETIC_HAMMER_BRAND_RANGE, FALSE)

/obj/effect/heretic_hammer_brand/Destroy()
	if(loc)
		UnregisterSignal(loc, COMSIG_TURF_CHANGE)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
	hammer?.on_brand_removed(src)
	hammer_ref = null
	return ..()

/obj/effect/heretic_hammer_brand/proc/on_turf_change(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/heretic_hammer_brand/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/mob/living/passerby = arrived
	if(!heretic_hammer_brand_hears(passerby))
		return
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_ref?.resolve()
	if(!hammer)
		return
	if(hammer.on_brand_hum(src, passerby) || COOLDOWN_FINISHED(src, hum_sound))
		COOLDOWN_START(src, hum_sound, HERETIC_HAMMER_BRAND_NOTICE_GAP)
		heretic_hammer_sound(src, "brand_ring", 20, TRUE, -4)

/obj/effect/heretic_hammer_brand/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/nullrod))
		user.visible_message(span_notice("[user] проводит нулевым жезлом по вмятине, и тлеющий оттиск гаснет."), span_notice("Оттиск гаснет под жезлом."))
		log_game("[key_name(user)] стирает Клеймо кузни нулевым жезлом в [AREACOORD(src)].")
		qdel(src)
		return TRUE
	if(item.tool_behaviour == TOOL_WELDER)
		INVOKE_ASYNC(src, PROC_REF(weld), user, item)
		return TRUE
	return loc.attackby(item, user, params)

/obj/effect/heretic_hammer_brand/attack_hand(mob/user, act_intent, attackchain_flags)
	return loc.attack_hand(user, act_intent, attackchain_flags)

/obj/effect/heretic_hammer_brand/proc/weld(mob/living/user, obj/item/tool)
	if(erasing)
		return FALSE
	erasing = TRUE
	user.visible_message(span_notice("[user] заваривает вмятину в стене."), span_notice("Вы завариваете вмятину. Не отходите [DisplayTimeText(HERETIC_HAMMER_BRAND_WELD_TIME)]."))
	var/done = tool.use_tool(src, user, HERETIC_HAMMER_BRAND_WELD_TIME, amount = 1, volume = 50)
	erasing = FALSE
	if(!done || QDELETED(src))
		return FALSE
	user.visible_message(span_notice("[user] заваривает вмятину, и оттиск под швом гаснет."))
	log_game("[key_name(user)] заваривает Клеймо кузни в [AREACOORD(src)].")
	qdel(src)
	return TRUE

/// Наковальня с неба: плотная, её можно разбить, сама исчезает.
/obj/structure/heretic_hammer_anvil
	name = "fallen anvil"
	desc = "Огромная чёрная наковальня, рухнувшая с потолка. Металл под ней прогнулся. Её можно разбить, а скоро она и сама рассыплется окалиной."
	icon = HERETIC_HAMMER_FX_ICON
	icon_state = "anvil"
	anchored = TRUE
	density = TRUE
	max_integrity = HERETIC_HAMMER_ANVIL_INTEGRITY
	resistance_flags = FIRE_PROOF | LAVA_PROOF

/obj/structure/heretic_hammer_anvil/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj, deconstruct), FALSE), HERETIC_HAMMER_ANVIL_LIFETIME, TIMER_DELETE_ME)

/obj/structure/heretic_hammer_anvil/deconstruct(disassembled = TRUE)
	var/turf/place = get_turf(src)
	if(place)
		visible_message(span_notice("[src] раскалывается и осыпается окалиной."))
		heretic_hammer_sound(place, "anvil_break", 50, TRUE)
		new /obj/effect/temp_visual/heretic_hammer/anvil_break(place)
	return ..()

#define HERETIC_MANSUS_HAMMER_CYCLE (3 SECONDS)
#define HERETIC_MANSUS_HAMMER_TELEGRAPH (1.2 SECONDS)
#define HERETIC_MANSUS_HAMMER_SPREAD 2
#define HERETIC_MANSUS_HAMMER_SHADOWS 4

/datum/heretic_mansus_rule/hammer
	hint = "Это Кузня изнанки. Над залом ходит огромный молот: на пол падает его тень, и через секунду он бьёт туда. Кто стоит в тени в миг удара, того сбивает с ног. Смотрите под ноги и сходите с тени."
	reminder = "Сходите с тени молота."
	var/list/turf/shadowed = list()

/datum/heretic_mansus_rule/hammer/on_danger()
	schedule(CALLBACK(src, PROC_REF(raise)), HERETIC_MANSUS_HAMMER_CYCLE)

/// Тень молота ложится на клетку под жертвой и на несколько клеток рядом.
/datum/heretic_mansus_rule/hammer/proc/raise()
	if(!active())
		return FALSE
	shadowed.Cut()
	var/turf/position = get_turf(visit.victim)
	if(visit.contains(position) && !visit.is_safe(position))
		shadowed += position
	var/list/turf/around = list()
	for(var/turf/open/spot in range(HERETIC_MANSUS_HAMMER_SPREAD, position))
		if(spot != position && visit.contains(spot) && !visit.is_safe(spot))
			around += spot
	while(length(around) && length(shadowed) < HERETIC_MANSUS_HAMMER_SHADOWS)
		shadowed += pick_n_take(around)
	for(var/turf/spot as anything in shadowed)
		new /obj/effect/temp_visual/heretic_mansus_hammer_shadow(spot)
	playsound(visit.victim, visit.theme["warning"], 40, FALSE)
	schedule(CALLBACK(src, PROC_REF(strike)), HERETIC_MANSUS_HAMMER_TELEGRAPH)
	return TRUE

/datum/heretic_mansus_rule/hammer/proc/strike()
	if(!active())
		return FALSE
	schedule(CALLBACK(src, PROC_REF(raise)), HERETIC_MANSUS_HAMMER_CYCLE)
	for(var/turf/spot as anything in shadowed)
		new /obj/effect/temp_visual/heretic_mansus_hammer_strike(spot)
	playsound(visit.victim, visit.theme["hit"], 50, FALSE)
	var/turf/position = get_turf(visit.victim)
	var/hit = (position in shadowed)
	shadowed.Cut()
	if(!hit)
		return FALSE
	shake_camera(visit.victim, 3, 2)
	to_chat(visit.victim, span_warning("Молот изнанки бьёт прямо по вам! Сходите с его тени."))
	visit.suffer_hazard(visit.victim)
	return TRUE

/datum/heretic_mansus_rule/hammer/cleanup()
	shadowed.Cut()

/obj/effect/temp_visual/heretic_mansus_hammer_shadow
	icon = HERETIC_MANSUS_RULES_ICON
	icon_state = "hammer_shadow"
	duration = HERETIC_MANSUS_HAMMER_TELEGRAPH
	randomdir = FALSE
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_mansus_hammer_strike
	icon = HERETIC_MANSUS_RULES_ICON
	icon_state = "hammer_strike"
	duration = 0.5 SECONDS
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER

#undef HERETIC_MANSUS_HAMMER_CYCLE
#undef HERETIC_MANSUS_HAMMER_TELEGRAPH
#undef HERETIC_MANSUS_HAMMER_SPREAD
#undef HERETIC_MANSUS_HAMMER_SHADOWS
