/obj/item/mod/module/anomaly_locked/antigrav/prebuilt/locked
	core_removable = FALSE

/obj/item/mod/module/anomaly_locked/teleporter/prebuilt/locked
	core_removable = FALSE

/obj/item/mod/module/anomaly_locked/kinesis
	name = "MOD kinesis module"
	desc = "Гравитационный манипулятор перемещает и бросает предметы, незакреплённые машины и тела."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "kinesis"
	module_type = MODULE_ACTIVE
	complexity = 3
	use_power_cost = DEFAULT_CHARGE_DRAIN * 3
	incompatible_modules = list(/obj/item/mod/module/anomaly_locked/kinesis)
	cooldown_time = 0.5 SECONDS
	overlay_icon_file = 'icons/mob/clothing/modsuit/mod_modules_whitemoon.dmi'
	overlay_state_inactive = "module_kinesis"
	overlay_state_active = "module_kinesis_on"
	accepted_anomalies = list(/obj/item/assembly/signaler/anomaly/grav)
	required_modpart_index = MOD_PART_GLOVES
	have_shortcut_activation = TRUE
	var/grab_range = 8
	var/stat_required = DEAD
	var/atom/movable/grabbed_atom
	var/mob/living/carbon/human/grab_user
	var/datum/beam/kinesis_beam
	var/mutable_appearance/kinesis_icon
	var/datum/looping_sound/mod_kinesis/soundloop
	var/turf/cursor_turf
	var/cursor_x = 0
	var/cursor_y = 0
	var/old_pixel_x = 0
	var/old_pixel_y = 0
	COOLDOWN_DECLARE(hit_cooldown)

/obj/item/mod/module/anomaly_locked/kinesis/Initialize(mapload)
	. = ..()
	soundloop = new(src)

/obj/item/mod/module/anomaly_locked/kinesis/Destroy()
	clear_grab(FALSE)
	QDEL_NULL(soundloop)
	return ..()

/obj/item/mod/module/anomaly_locked/kinesis/on_deactivation(display_message = TRUE, deleting = FALSE)
	clear_grab(!deleting)
	return ..()

/obj/item/mod/module/anomaly_locked/kinesis/on_unequip()
	clear_grab(FALSE)

/obj/item/mod/module/anomaly_locked/kinesis/on_select_use(atom/target)
	if(!..())
		return FALSE
	if(grabbed_atom)
		var/atom/movable/launched = grabbed_atom
		var/mob/living/user = grab_user
		clear_grab(FALSE)
		launch(launched, user)
		return TRUE
	if(!range_check(target) || !can_grab(target))
		balloon_alert(mod.wearer, "невозможно захватить")
		return FALSE
	if(!drain_power(use_power_cost))
		return FALSE
	return grab_atom(target)

/obj/item/mod/module/anomaly_locked/kinesis/proc/can_grab(atom/target)
	if(!ismovable(target) || target == mod?.wearer || iseffect(target))
		return FALSE
	var/atom/movable/movable = target
	if(movable.anchored || movable.throwing || movable.move_resist >= MOVE_FORCE_OVERPOWERING)
		return FALSE
	if(ismob(movable))
		if(!isliving(movable))
			return FALSE
		var/mob/living/living = movable
		return !living.buckled && living.stat >= stat_required
	if(isitem(movable))
		var/obj/item/item = movable
		return item.w_class < WEIGHT_CLASS_GIGANTIC && !(item.item_flags & ABSTRACT)
	return TRUE

/obj/item/mod/module/anomaly_locked/kinesis/proc/range_check(atom/target)
	if(QDELETED(target) || !isturf(mod?.wearer?.loc) || !isturf(target.loc))
		return FALSE
	return can_see(mod.wearer, target, grab_range)

/obj/item/mod/module/anomaly_locked/kinesis/proc/grab_atom(atom/movable/target)
	if(!mod?.wearer || !can_grab(target) || !range_check(target))
		return FALSE
	clear_grab(FALSE)
	grab_user = mod.wearer
	grabbed_atom = target
	old_pixel_x = target.pixel_x
	old_pixel_y = target.pixel_y
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_grab_lost))
	RegisterSignal(target, COMSIG_OBJ_SETANCHORED, PROC_REF(on_anchor_changed))
	if(isliving(target))
		ADD_TRAIT(target, TRAIT_IMMOBILIZED, REF(src))
		ADD_TRAIT(target, TRAIT_HANDS_BLOCKED, REF(src))
		RegisterSignal(target, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_changed))
	ADD_TRAIT(target, TRAIT_NO_FLOATING_ANIM, REF(src))
	RegisterSignal(grab_user, COMSIG_PARENT_QDELETING, PROC_REF(on_grab_lost))
	RegisterSignal(grab_user, COMSIG_MOB_CLIENT_MOUSEMOVE, PROC_REF(on_cursor_moved))
	RegisterSignal(grab_user, COMSIG_MOB_CLICKON, PROC_REF(on_cursor_clicked))
	kinesis_icon = mutable_appearance('icons/effects/mod_kinesis_whitemoon.dmi', "kinesis", appearance_flags = RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM)
	target.add_overlay(kinesis_icon)
	kinesis_beam = grab_user.Beam(target, "kinesis", 'icons/effects/mod_kinesis_beam_whitemoon.dmi', INFINITY, grab_range + MOD_KINESIS_BEAM_MARGIN)
	RegisterSignal(kinesis_beam, COMSIG_PARENT_QDELETING, PROC_REF(on_beam_lost))
	soundloop.start(grab_user)
	START_PROCESSING(SSfastprocess, src)
	return TRUE

/obj/item/mod/module/anomaly_locked/kinesis/proc/clear_grab(play_sound = TRUE)
	STOP_PROCESSING(SSfastprocess, src)
	if(grab_user)
		UnregisterSignal(grab_user, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_CLIENT_MOUSEMOVE, COMSIG_MOB_CLICKON))
	grab_user = null
	cursor_turf = null
	if(kinesis_beam)
		UnregisterSignal(kinesis_beam, COMSIG_PARENT_QDELETING)
	QDEL_NULL(kinesis_beam)
	soundloop?.stop(TRUE)
	if(!grabbed_atom)
		return
	. = grabbed_atom
	UnregisterSignal(grabbed_atom, list(COMSIG_PARENT_QDELETING, COMSIG_OBJ_SETANCHORED, COMSIG_MOB_STATCHANGE))
	grabbed_atom.cut_overlay(kinesis_icon)
	REMOVE_TRAIT(grabbed_atom, TRAIT_NO_FLOATING_ANIM, REF(src))
	REMOVE_TRAIT(grabbed_atom, TRAIT_IMMOBILIZED, REF(src))
	REMOVE_TRAIT(grabbed_atom, TRAIT_HANDS_BLOCKED, REF(src))
	REMOVE_TRAIT(grabbed_atom, TRAIT_MOVE_PHASING, REF(src))
	animate(grabbed_atom, pixel_x = old_pixel_x, pixel_y = old_pixel_y, time = 0.2 SECONDS)
	if(play_sound)
		playsound(grabbed_atom, 'sound/effects/empulse.ogg', MOD_KINESIS_VOLUME, TRUE)
	grabbed_atom = null
	kinesis_icon = null

/obj/item/mod/module/anomaly_locked/kinesis/process(delta_time)
	if(!active || !grab_user?.client || grab_user != mod?.wearer || grab_user.incapacitated(ignore_grab = TRUE) || !can_grab(grabbed_atom) || !range_check(grabbed_atom) || !drain_power(use_power_cost * MOD_KINESIS_HOLD_FRACTION))
		clear_grab()
		return
	update_cursor()
	if(cursor_turf)
		move_grab(cursor_turf, cursor_x, cursor_y)

/obj/item/mod/module/anomaly_locked/kinesis/proc/on_cursor_moved()
	SIGNAL_HANDLER
	update_cursor()

/obj/item/mod/module/anomaly_locked/kinesis/proc/update_cursor()
	if(!grab_user?.client)
		return
	var/datum/position/position = mouse_absolute_datum_map_position_from_client(grab_user.client)
	if(!position)
		return
	cursor_turf = position.return_turf()
	cursor_x = position.pixel_x - MOD_KINESIS_PIXEL_CENTER
	cursor_y = position.pixel_y - MOD_KINESIS_PIXEL_CENTER
	qdel(position)

/obj/item/mod/module/anomaly_locked/kinesis/proc/move_grab(turf/destination, offset_x = 0, offset_y = 0)
	if(!grabbed_atom || !destination || destination.z != grab_user?.z)
		return FALSE
	grab_user.setDir(get_dir(grab_user, grabbed_atom))
	animate(grabbed_atom, pixel_x = old_pixel_x + offset_x, pixel_y = old_pixel_y + offset_y, time = 0.2 SECONDS)
	if(grabbed_atom.loc == destination)
		return TRUE
	var/turf/next = get_step_towards(grabbed_atom, destination)
	if(grabbed_atom.Move(next, get_dir(grabbed_atom, next)))
		if(isitem(grabbed_atom) && next == get_turf(grab_user))
			var/obj/item/item = grabbed_atom
			var/mob/living/user = grab_user
			clear_grab(FALSE)
			user.put_in_hands(item)
		return TRUE
	hit_obstacle(next)
	return FALSE

/obj/item/mod/module/anomaly_locked/kinesis/proc/hit_obstacle(turf/next)
	if(!isitem(grabbed_atom) || !COOLDOWN_FINISHED(src, hit_cooldown))
		return
	var/atom/obstacle = next.density ? next : null
	for(var/obj/object in next)
		if(object.density)
			obstacle = object
			break
	if(!obstacle)
		return
	var/obj/item/item = grabbed_atom
	item.melee_attack_chain(grab_user, obstacle)
	COOLDOWN_START(src, hit_cooldown, 1 SECONDS)

/obj/item/mod/module/anomaly_locked/kinesis/proc/on_cursor_clicked(datum/source, atom/target, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	if(modifiers[RIGHT_CLICK])
		clear_grab()
		return COMSIG_MOB_CANCEL_CLICKON

/obj/item/mod/module/anomaly_locked/kinesis/proc/on_grab_lost()
	SIGNAL_HANDLER
	clear_grab(FALSE)

/obj/item/mod/module/anomaly_locked/kinesis/proc/on_beam_lost()
	SIGNAL_HANDLER
	kinesis_beam = null
	clear_grab(FALSE)

/obj/item/mod/module/anomaly_locked/kinesis/proc/on_anchor_changed(datum/source, anchored)
	SIGNAL_HANDLER
	if(anchored)
		clear_grab()

/obj/item/mod/module/anomaly_locked/kinesis/proc/on_stat_changed(datum/source, new_stat)
	SIGNAL_HANDLER
	if(new_stat < stat_required)
		clear_grab()

/obj/item/mod/module/anomaly_locked/kinesis/proc/launch(atom/movable/target, mob/living/user)
	var/turf/destination = get_ranged_target_turf_direct(user, target, grab_range)
	target.AddComponent(/datum/component/mod_kinesis_impact)
	target.throw_at(destination, grab_range, target.density ? MOD_KINESIS_THROW_DENSE_SPEED : MOD_KINESIS_THROW_ITEM_SPEED, user, spin = isitem(target))

/datum/component/mod_kinesis_impact/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_MOVABLE_IMPACT, PROC_REF(on_impact))
	QDEL_IN(src, 10 SECONDS)

/datum/component/mod_kinesis_impact/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOVABLE_IMPACT)
	return ..()

/datum/component/mod_kinesis_impact/proc/on_impact(atom/movable/source, atom/target)
	SIGNAL_HANDLER
	if(isstructure(source) || ismachinery(source) || istype(source, /obj/vehicle))
		var/damage = source.density ? MOD_KINESIS_IMPACT_DENSE : MOD_KINESIS_IMPACT_LIGHT
		if(isliving(target))
			var/mob/living/living = target
			living.apply_damage(damage, BRUTE)
		else if(isobj(target))
			var/obj/object = target
			object.take_damage(damage, BRUTE, MELEE)
		if(!source.density && isobj(source))
			var/obj/object = source
			object.take_damage(object.max_integrity * MOD_KINESIS_SELF_DAMAGE, BRUTE, MELEE)
	qdel(src)

/datum/looping_sound/mod_kinesis
	start_sound = 'sound/items/modsuit/kinesis_start.ogg'
	start_length = 1 SECONDS
	mid_sounds = list('sound/items/modsuit/kinesis_mid1.ogg' = 12, 'sound/items/modsuit/kinesis_mid2.ogg' = 1)
	mid_length = 1.1 SECONDS
	end_sound = 'sound/items/modsuit/kinesis_end.ogg'
	volume = 20

/obj/item/mod/module/anomaly_locked/kinesis/prebuilt
	prebuilt = TRUE

/obj/item/mod/module/anomaly_locked/kinesis/prebuilt/locked
	core_removable = FALSE

/obj/item/mod/module/anomaly_locked/kinesis/prototype
	name = "MOD prototype kinesis module"
	prebuilt = TRUE
	complexity = 0
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	removable = FALSE
	core_removable = FALSE

/obj/item/mod/module/anomaly_locked/kinesis/plus
	name = "MOD kinesis+ module"
	complexity = 0
	prebuilt = TRUE
	stat_required = CONSCIOUS

/obj/item/mod/module/anomaly_locked/kinesis/admin
	name = "MOD kinesis++ module"
	complexity = 0
	grab_range = INFINITY
	use_power_cost = 0
	prebuilt = TRUE
	stat_required = CONSCIOUS
	var/phasing = FALSE

/obj/item/mod/module/anomaly_locked/kinesis/admin/can_grab(atom/target)
	if(!ismovable(target) || target == mod?.wearer)
		return FALSE
	var/atom/movable/movable = target
	return !movable.throwing

/obj/item/mod/module/anomaly_locked/kinesis/admin/range_check(atom/target)
	return !QDELETED(target) && isturf(mod?.wearer?.loc) && isturf(target.loc) && target.z == mod.wearer.z

/obj/item/mod/module/anomaly_locked/kinesis/admin/grab_atom(atom/movable/target)
	. = ..()
	if(. && phasing)
		ADD_TRAIT(target, TRAIT_MOVE_PHASING, REF(src))

/obj/item/mod/module/anomaly_locked/kinesis/admin/on_anchor_changed()
	return

/obj/item/mod/module/anomaly_locked/kinesis/admin/get_configuration()
	. = ..()
	.["phasing"] = add_ui_configuration("Прохождение сквозь стены", "bool", phasing)

/obj/item/mod/module/anomaly_locked/kinesis/admin/configure_edit(key, value)
	if(key != "phasing")
		return
	phasing = !!text2num("[value]")
	if(!grabbed_atom)
		return
	if(phasing)
		ADD_TRAIT(grabbed_atom, TRAIT_MOVE_PHASING, REF(src))
	else
		REMOVE_TRAIT(grabbed_atom, TRAIT_MOVE_PHASING, REF(src))
