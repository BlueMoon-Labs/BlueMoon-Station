//Science modules for MODsuits

///Reagent Scanner - Lets the user scan reagents.
/obj/item/mod/module/reagent_scanner
	name = "MOD reagent scanner module"
	desc = "Модуль, основанный на исследовательских дисплеях Nanotrasen, способный сканировать содержимое \
		контейнеров и отображать информацию в удобном для чтения формате на экране носителя. \
		Он не может определять вкусы, так что это зависит от вас."
	icon_state = "scanner"
	module_type = MODULE_TOGGLE
	complexity = 1
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	incompatible_modules = list(/obj/item/mod/module/reagent_scanner)
	cooldown_time = 0.5 SECONDS
	mod_module_flags = MOD_MODULE_SCIENCE // BLUEMOON ADD

/obj/item/mod/module/reagent_scanner/on_activation()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(mod.wearer, TRAIT_REAGENT_SCANNER, MOD_TRAIT)

/obj/item/mod/module/reagent_scanner/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	REMOVE_TRAIT(mod.wearer, TRAIT_REAGENT_SCANNER, MOD_TRAIT)

/obj/item/mod/module/reagent_scanner/advanced
	name = "MOD advanced reagent scanner module"
	complexity = 0
	removable = FALSE
	var/explosion_detection_dist = 21

/obj/item/mod/module/reagent_scanner/advanced/on_unequip()
	if(active)
		on_deactivation()

/obj/item/mod/module/reagent_scanner/advanced/on_activation()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(mod.wearer, TRAIT_RESEARCH_SCANNER, MOD_TRAIT)
	RegisterSignal(SSdcs, COMSIG_GLOB_EXPLOSION, PROC_REF(sense_explosion))

/obj/item/mod/module/reagent_scanner/advanced/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	REMOVE_TRAIT(mod.wearer, TRAIT_RESEARCH_SCANNER, MOD_TRAIT)
	UnregisterSignal(SSdcs, COMSIG_GLOB_EXPLOSION)

/obj/item/mod/module/reagent_scanner/advanced/proc/sense_explosion(datum/source, turf/epicenter,
	devastation_range, heavy_impact_range, light_impact_range, took, orig_dev_range, orig_heavy_range, orig_light_range)
	SIGNAL_HANDLER
	var/turf/wearer_turf = get_turf(mod.wearer)
	if(wearer_turf.z == epicenter.z)
		return
	if(get_dist(epicenter, wearer_turf) > explosion_detection_dist)
		return
	to_chat(mod.wearer, span_notice("Explosion detected! Epicenter: [devastation_range], Outer: [heavy_impact_range], Shock: [light_impact_range]"))

///Anti-Gravity - Makes the user weightless.
/obj/item/mod/module/anomaly_locked/antigrav
	name = "MOD anti-gravity module"
	desc = "Модуль, использующий гравитационное ядро для полного обнуления веса пользователя. К сожалению, не способен работать когда пользователь лежит."
	icon_state = "antigrav"
	module_type = MODULE_TOGGLE
	complexity = 2
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.7
	incompatible_modules = list(/obj/item/mod/module/anomaly_locked)
	cooldown_time = 0.5 SECONDS
	accepted_anomalies = list(/obj/item/assembly/signaler/anomaly/grav)
	mod_module_flags = MOD_MODULE_SCIENCE // BLUEMOON ADD

/obj/item/mod/module/anomaly_locked/antigrav
	var/resume_on_standing = FALSE

/obj/item/mod/module/anomaly_locked/antigrav/on_equip()
	. = ..()
	RegisterSignal(mod.wearer, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(check_lying_down))

/obj/item/mod/module/anomaly_locked/antigrav/on_unequip()
	UnregisterSignal(mod.wearer, COMSIG_LIVING_SET_BODY_POSITION)
	resume_on_standing = FALSE
	if(active)
		on_deactivation()
	return ..()

/obj/item/mod/module/anomaly_locked/antigrav/on_suit_deactivation()
	resume_on_standing = FALSE
	return ..()

/obj/item/mod/module/anomaly_locked/antigrav/proc/check_lying_down(datum/source)
	SIGNAL_HANDLER
	if(mod.wearer.body_position == LYING_DOWN)
		if(active)
			on_deactivation()
			resume_on_standing = TRUE
		return
	if(resume_on_standing && mod.is_active() && !mod.is_activating())
		on_activation()

/obj/item/mod/module/anomaly_locked/antigrav/on_select(atom/target)
	if(!mod?.wearer)
		return FALSE
	if(mod.wearer.body_position == LYING_DOWN)
		balloon_alert(mod.wearer, "Модуль сбоит!")
		to_chat(mod.wearer, span_boldwarning("Антиграв нельзя использовать лёжа!"))
		return FALSE
	. = ..()

/obj/item/mod/module/anomaly_locked/antigrav/on_activation()
	if(!mod?.wearer || mod.wearer.body_position == LYING_DOWN)
		return FALSE
	. = ..()
	if(!.)
		return
	resume_on_standing = FALSE
	if(mod.wearer.has_gravity())
		new /obj/effect/temp_visual/mook_dust(get_turf(mod))
	mod.wearer.AddElement(/datum/element/forced_gravity, 0)
	mod.wearer.refresh_gravity()
	playsound(mod, 'sound/effects/gravhit.ogg', 50)

/obj/item/mod/module/anomaly_locked/antigrav/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	resume_on_standing = FALSE
	mod.wearer.RemoveElement(/datum/element/forced_gravity, 0)
	mod.wearer.refresh_gravity()
	if(deleting)
		return
	if(mod.wearer.has_gravity())
		new /obj/effect/temp_visual/mook_dust(get_turf(mod))
	playsound(mod, 'sound/effects/gravhit.ogg', 50)

/obj/item/mod/module/anomaly_locked/antigrav/prebuilt
	prebuilt = TRUE

///Teleporter - Lets the user teleport to a nearby location.
/obj/item/mod/module/anomaly_locked/teleporter
	name = "MOD teleporter module"
	desc = "Модуль, использующий блюспейс-ядро для перемещения частиц пользователя в другое место."
	icon_state = "teleporter"
	module_type = MODULE_ACTIVE
	complexity = 3
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 5 SECONDS
	accepted_anomalies = list(/obj/item/assembly/signaler/anomaly/bluespace)
	/// Time it takes to teleport
	var/teleport_time = 3 SECONDS
	var/mob/living/carbon/human/teleporting_user
	var/matrix/teleport_transform
	var/teleport_color
	mod_module_flags = MOD_MODULE_SCIENCE // BLUEMOON ADD
	have_shortcut_activation = TRUE

/obj/item/mod/module/anomaly_locked/teleporter/on_select_use(atom/target)
	if(teleporting_user || !..())
		return FALSE
	var/turf/open/target_turf = get_turf(target)
	if(!istype(target_turf) || is_blocked_turf(target_turf) || !(target_turf in view(mod.wearer)))
		mod.balloon_alert(mod.wearer, "неверная цель!")
		return FALSE
	var/mob/living/carbon/human/user = mod.wearer
	mod.balloon_alert(user, "телепортируем...")
	begin_teleport(user)
	var/ready = do_after(user, teleport_time, target = mod)
	if(teleporting_user != user)
		return FALSE
	end_teleport()
	if(!ready || !active || mod?.wearer != user || !check_required_modpart() || QDELETED(core))
		return FALSE
	if(!check_power(use_power_cost) || is_blocked_turf(target_turf) || !(target_turf in view(user)))
		return FALSE
	if(!do_teleport(user, target_turf, asoundin = 'sound/effects/phasein.ogg'))
		return FALSE
	drain_power(use_power_cost)
	return TRUE

/obj/item/mod/module/anomaly_locked/teleporter/proc/begin_teleport(mob/living/carbon/human/user)
	teleporting_user = user
	teleport_transform = matrix(user.transform)
	teleport_color = user.color
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_teleport_user_deleted))
	var/matrix/stretch = matrix(teleport_transform)
	stretch.Scale(MOD_TELEPORT_STRETCH, 1 / MOD_TELEPORT_STRETCH)
	animate(user, teleport_time, color = COLOR_CYAN, transform = stretch, easing = SINE_EASING | EASE_OUT)

/obj/item/mod/module/anomaly_locked/teleporter/proc/end_teleport()
	if(teleporting_user)
		UnregisterSignal(teleporting_user, COMSIG_PARENT_QDELETING)
		animate(teleporting_user)
		teleporting_user.transform = teleport_transform
		teleporting_user.color = teleport_color
	teleporting_user = null
	teleport_transform = null
	teleport_color = null

/obj/item/mod/module/anomaly_locked/teleporter/proc/on_teleport_user_deleted(datum/source)
	SIGNAL_HANDLER
	end_teleport()

/obj/item/mod/module/anomaly_locked/teleporter/on_deactivation(display_message = TRUE, deleting = FALSE)
	end_teleport()
	return ..()

/obj/item/mod/module/anomaly_locked/teleporter/Destroy()
	end_teleport()
	return ..()

/obj/item/mod/module/anomaly_locked/teleporter/prebuilt
	prebuilt = TRUE

/obj/item/mod/module/jump_jet
	complexity = 3
	name = "Jump Jet Module"
	icon_state = "jump_jet"
	desc = "Специализированный нагнетатель газа, которы при наборе нужного давления способен \
	с огромной силой высвободить накопленный безвредный газ, чтобы отправить пользователя в непродолжительный\
	полет. Работает как в атмосфере, так и в космосе, благодаря встроенным бакам. Несовместим с джетпаком, потому что \
	крепится ровно туда же."
	incompatible_modules = list(/obj/item/mod/module/jetpack, /obj/item/mod/module/jump_jet)
	module_type = MODULE_USABLE
	cooldown_time = 10 SECONDS
	required_modpart_index = MOD_PART_FEET
	var/beam_icon = 'icons/effects/effects.dmi'
	var/beam_state = "ion_fade"
	var/jumpdistance = 5
	var/jumpspeed = 3
	var/target_limit = 0
	var/attack_targets = FALSE
	var/mark_targets = FALSE
	var/list/jump_color
	var/trail_type = /obj/effect/ebeam
	var/mob/living/carbon/human/jump_user
	var/list/jump_targets = list()
	var/list/jump_markers = list()
	var/client/selection_client
	var/saved_cursor
	var/saved_mouse_up
	var/saved_mouse_down
	var/jump_timer
	var/selection_end = 0
	var/selecting_targets = FALSE
	var/jump_id = 0

/obj/item/mod/module/jump_jet/on_use()
	if(target_limit && (jump_user || !can_jump(mod?.wearer)))
		if(mod?.wearer)
			to_chat(mod.wearer, span_warning("Прыжок недоступен: нужны включённый MOD, надетые ботинки и возможность свободно стоять на тайле."))
		return FALSE
	. = ..()
	if(!.)
		return
	if(target_limit)
		begin_selection()
		return TRUE
	var/turf/start_from = mod.wearer.loc
	if(mod.wearer.body_position == LYING_DOWN)
		balloon_alert(mod.wearer, "Нужна опора!")
		return
	var/atom/target = get_edge_target_turf(mod.wearer, mod.wearer.dir)
	if(mod.wearer.throw_at(target, jumpdistance, jumpspeed, spin = FALSE, diagonals_first = TRUE))
		start_from.Beam(mod.wearer, beam_state, beam_icon, 0.5 SECONDS)
		playsound(mod, 'sound/effects/stealthoff.ogg', 50, 1, 1)
		mod.wearer.visible_message("<span class='warning'>[mod.wearer] мгновенно срывается вперёд, взмывая в воздух!</span>")
	else
		to_chat(mod.wearer, "<span class='warning'>Что-то мешает вам это сделать!</span>")

/obj/item/mod/module/jump_jet/Destroy()
	clear_jumps()
	return ..()

/obj/item/mod/module/jump_jet/on_suit_deactivation()
	clear_jumps()
	return ..()

/obj/item/mod/module/jump_jet/on_unequip()
	clear_jumps()
	return ..()

/obj/item/mod/module/jump_jet/on_uninstall(deleting = FALSE, user)
	clear_jumps()
	return ..()

/obj/item/mod/module/jump_jet/on_deactivation()
	clear_jumps()
	return ..()

/obj/item/mod/module/jump_jet/on_process(delta_time)
	. = ..()
	if(jump_user && !can_jump(jump_user))
		clear_jumps()

/obj/item/mod/module/jump_jet/proc/can_jump(mob/living/carbon/human/user)
	if(QDELETED(user) || user != mod?.wearer)
		return FALSE
	if(!mod.is_active() || mod.is_activating() || !check_required_modpart() || !check_power(use_power_cost) || !mod.get_charge())
		return FALSE
	return isturf(user.loc) && !user.buckled && !user.incapacitated() && user.body_position != LYING_DOWN

/obj/item/mod/module/jump_jet/proc/begin_selection()
	jump_user = mod.wearer
	selecting_targets = TRUE
	selection_end = world.time + MOD_JUMP_SELECTION_TIME
	RegisterSignal(jump_user, COMSIG_MOB_CLICKON, PROC_REF(on_target_click))
	RegisterSignal(jump_user, COMSIG_PARENT_QDELETING, PROC_REF(on_jump_user_deleted))
	RegisterSignal(jump_user, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_jump_user_deleted))
	RegisterSignal(jump_user, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_jump_item_removed))
	set_selection_cursor()
	jump_timer = addtimer(CALLBACK(src, PROC_REF(finish_selection)), MOD_JUMP_SELECTION_TIME, TIMER_STOPPABLE)
	to_chat(jump_user, span_notice("Выберите до [target_limit] целей обычным кликом за [MOD_JUMP_SELECTION_TIME / (1 SECONDS)] секунды. Прыжки начнутся после завершения выбора."))

/obj/item/mod/module/jump_jet/proc/on_target_click(mob/source, atom/target, params)
	SIGNAL_HANDLER
	if(source != jump_user || !selecting_targets || istype(target, /atom/movable/screen))
		return
	var/list/modifiers = params2list(params)
	if(modifiers[RIGHT_CLICK] || modifiers[SHIFT_CLICK] || modifiers[CTRL_CLICK] || modifiers[ALT_CLICK] || modifiers[MIDDLE_CLICK])
		return
	if(!can_jump(jump_user))
		clear_jumps()
		return COMSIG_MOB_CANCEL_CLICKON
	if(world.time < selection_end)
		select_target(target)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/mod/module/jump_jet/proc/select_target(atom/target)
	if(!selecting_targets || world.time >= selection_end || !can_jump(jump_user) || QDELETED(target) || target == jump_user || length(jump_targets) >= target_limit)
		return FALSE
	if(!(isturf(target) || isitem(target) || isliving(target)))
		return FALSE
	if(!(target in view(jump_user.client?.view || world.view, jump_user)))
		return FALSE
	if(!isturf(target) && !isturf(target.loc))
		return FALSE
	for(var/datum/weakref/selected as anything in jump_targets)
		if(selected.resolve() == target)
			return FALSE
	var/datum/weakref/selected = WEAKREF(target)
	jump_targets += selected
	if(mark_targets)
		jump_markers[selected] = new /datum/mod_jump_marker(jump_user, target)
	to_chat(jump_user, span_notice("Цель [length(jump_targets)]/[target_limit]: [target]."))
	return TRUE

/obj/item/mod/module/jump_jet/proc/finish_selection()
	if(jump_timer)
		deltimer(jump_timer)
		jump_timer = null
	selecting_targets = FALSE
	restore_selection_cursor()
	if(jump_user)
		UnregisterSignal(jump_user, COMSIG_MOB_CLICKON)
	if(!length(jump_targets))
		if(jump_user)
			to_chat(jump_user, span_notice("Цели не выбраны. Прыжок отменён."))
		reset_jump_cooldown()
		clear_jumps()
		return
	jump_step()

/obj/item/mod/module/jump_jet/proc/reset_jump_cooldown()
	COOLDOWN_RESET(src, cooldown_current_timer)
	var/list/abilities = list()
	if(jump_user)
		abilities |= jump_user.actions
	if(mod?.ai)
		abilities |= mod.ai.actions
	for(var/datum/action/cooldown/module_action/action in abilities)
		if(action.target == src)
			action.StartCooldownSelf(0)
	jump_user?.update_inv_back()

/obj/item/mod/module/jump_jet/proc/jump_step()
	jump_timer = null
	if(!can_jump(jump_user) || !length(jump_targets))
		clear_jumps()
		return
	var/datum/weakref/selected = jump_targets[1]
	jump_targets.Cut(1, 2)
	var/datum/mod_jump_marker/marker = jump_markers[selected]
	jump_markers -= selected
	qdel(marker)
	var/current_jump = jump_id
	jump_to_target(selected.resolve())
	if(current_jump != jump_id)
		return
	if(!length(jump_targets))
		clear_jumps()
		return
	jump_timer = addtimer(CALLBACK(src, PROC_REF(jump_step)), MOD_JUMP_STEP_DELAY, TIMER_STOPPABLE)

/obj/item/mod/module/jump_jet/proc/jump_to_target(atom/target)
	if(!can_jump(jump_user) || QDELETED(target))
		return FALSE
	var/turf/destination = get_turf(target)
	if(!destination || destination.z != jump_user.z || is_blocked_turf(destination, exclude_mobs = TRUE))
		return FALSE
	var/mob/living/carbon/human/user = jump_user
	user.face_atom(target)
	var/obj/effect/temp_visual/dir_setting/ninja/phase/out/departure = new(get_turf(user), user.dir)
	departure.color = jump_color
	if(!do_teleport(user, destination, asoundin = 'sound/magic/blink.ogg', asoundout = 'sound/magic/blink.ogg', no_effects = TRUE, channel = TELEPORT_CHANNEL_FREE, forced = TRUE))
		qdel(departure)
		return FALSE
	var/obj/effect/temp_visual/dir_setting/ninja/phase/arrival = new(get_turf(user), user.dir)
	arrival.color = jump_color
	departure.Beam(arrival, "blur", time = MOD_JUMP_TRAIL_TIME, beam_type = trail_type)
	attack_jump_target(user, target)
	return TRUE

/obj/item/mod/module/jump_jet/proc/attack_jump_target(mob/living/carbon/human/user, atom/target)
	if(!attack_targets || !can_jump(user) || QDELETED(target) || isturf(target))
		return
	var/obj/item/weapon = user.get_active_held_item()
	if(weapon && user.Adjacent(target) && user.CanReach(target, weapon))
		weapon.melee_attack_chain(user, target, "", ATTACK_IGNORE_CLICKDELAY)

/obj/item/mod/module/jump_jet/proc/clear_jumps()
	jump_id++
	if(jump_timer)
		deltimer(jump_timer)
	jump_timer = null
	restore_selection_cursor()
	QDEL_LIST_ASSOC_VAL(jump_markers)
	if(jump_user)
		UnregisterSignal(jump_user, list(COMSIG_MOB_CLICKON, COMSIG_PARENT_QDELETING, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_CLIENT_LOGOUT))
	jump_user = null
	jump_targets.Cut()
	selecting_targets = FALSE
	selection_end = 0

/obj/item/mod/module/jump_jet/proc/on_jump_user_deleted()
	SIGNAL_HANDLER
	clear_jumps()

/obj/item/mod/module/jump_jet/proc/on_jump_item_removed(mob/source, obj/item/item)
	SIGNAL_HANDLER
	if(item == required_modpart || item == mod)
		clear_jumps()

/obj/item/mod/module/jump_jet/proc/set_selection_cursor()
	if(!mark_targets || !jump_user?.client)
		return
	selection_client = jump_user.client
	saved_cursor = selection_client.mouse_override_icon
	saved_mouse_up = selection_client.mouse_up_icon
	saved_mouse_down = selection_client.mouse_down_icon
	selection_client.mouse_override_icon = 'icons/effects/mouse_pointers/mod_jump_target.dmi'
	selection_client.mouse_up_icon = 'icons/effects/mouse_pointers/mod_jump_target.dmi'
	selection_client.mouse_down_icon = 'icons/effects/mouse_pointers/mod_jump_target.dmi'
	selection_client.mouse_pointer_icon = 'icons/effects/mouse_pointers/mod_jump_target.dmi'

/obj/item/mod/module/jump_jet/proc/restore_selection_cursor()
	if(selection_client)
		if(selection_client.mouse_override_icon == 'icons/effects/mouse_pointers/mod_jump_target.dmi')
			selection_client.mouse_override_icon = saved_cursor
		if(selection_client.mouse_up_icon == 'icons/effects/mouse_pointers/mod_jump_target.dmi')
			selection_client.mouse_up_icon = saved_mouse_up
		if(selection_client.mouse_down_icon == 'icons/effects/mouse_pointers/mod_jump_target.dmi')
			selection_client.mouse_down_icon = saved_mouse_down
		if(selection_client.mouse_pointer_icon == 'icons/effects/mouse_pointers/mod_jump_target.dmi')
			selection_client.mouse_pointer_icon = saved_cursor
			selection_client.mob?.update_mouse_pointer()
	selection_client = null
	saved_cursor = null
	saved_mouse_up = null
	saved_mouse_down = null

/datum/mod_jump_marker
	var/datum/weakref/target_ref
	var/image/marker_image
	var/client/viewer

/datum/mod_jump_marker/New(mob/user, atom/target)
	target_ref = WEAKREF(target)
	viewer = user.client
	marker_image = image('icons/effects/mouse_pointers/mod_jump_target.dmi', get_turf(target), "all", ABOVE_ALL_MOB_LAYER)
	marker_image.plane = ABOVE_LIGHTING_PLANE
	marker_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	viewer?.images += marker_image
	START_PROCESSING(SSfastprocess, src)

/datum/mod_jump_marker/process()
	var/atom/target = target_ref?.resolve()
	marker_image.loc = get_turf(target)
	if(!marker_image.loc)
		return PROCESS_KILL

/datum/mod_jump_marker/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	viewer?.images -= marker_image
	viewer = null
	target_ref = null
	QDEL_NULL(marker_image)
	return ..()

/obj/effect/ebeam/mod_jump_inteq
	color = list(COLOR_YELLOW, COLOR_YELLOW, COLOR_YELLOW)
