/datum/mod_temporal_lock
	var/obj/item/mod/control/suit
	var/list/locked_modules = list()

/datum/mod_temporal_lock/New(obj/item/mod/control/mod)
	suit = mod
	RegisterSignal(suit, COMSIG_MOD_ACTIVATE, PROC_REF(block_suit))
	for(var/obj/item/mod/module/module as anything in suit.modules)
		locked_modules += module
		RegisterSignal(module, COMSIG_MODULE_TRIGGERED, PROC_REF(block_module))
		RegisterSignal(module, COMSIG_PARENT_QDELETING, PROC_REF(forget_module))

/datum/mod_temporal_lock/Destroy()
	UnregisterSignal(suit, COMSIG_MOD_ACTIVATE)
	for(var/obj/item/mod/module/module as anything in locked_modules)
		UnregisterSignal(module, list(COMSIG_MODULE_TRIGGERED, COMSIG_PARENT_QDELETING))
	locked_modules = null
	suit = null
	return ..()

/datum/mod_temporal_lock/proc/block_suit(datum/source, mob/user)
	SIGNAL_HANDLER
	to_chat(user, span_warning("Дождитесь завершения временного эффекта MOD."))
	return MOD_CANCEL_ACTIVATE

/datum/mod_temporal_lock/proc/block_module(datum/source)
	SIGNAL_HANDLER
	to_chat(suit?.wearer, span_warning("Модули заблокированы временным эффектом MOD."))
	return MOD_ABORT_USE

/datum/mod_temporal_lock/proc/forget_module(obj/item/mod/module/module)
	SIGNAL_HANDLER
	locked_modules -= module
	UnregisterSignal(module, list(COMSIG_MODULE_TRIGGERED, COMSIG_PARENT_QDELETING))

/obj/item/mod/module/rewinder
	name = "MOD rewinder module"
	desc = "Сохраняет положение и состояние тела, возвращая их через десять секунд. Пока идёт перемотка, костюм и остальные модули заблокированы."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "rewinder"
	module_type = MODULE_USABLE
	removable = FALSE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 20 SECONDS
	incompatible_modules = list(/obj/item/mod/module/rewinder)
	var/datum/component/dejavu/timeline/snapshot
	var/datum/mod_temporal_lock/temporal_lock

/obj/item/mod/module/rewinder/on_use()
	if(snapshot || !mod?.is_active() || !..())
		return FALSE
	if(!drain_power(use_power_cost))
		return FALSE
	temporal_lock = new(mod)
	snapshot = mod.wearer.AddComponent(/datum/component/dejavu/timeline, 1, MOD_REWIND_DELAY)
	RegisterSignal(snapshot, COMSIG_PARENT_QDELETING, PROC_REF(on_rewind_end))
	balloon_alert(mod.wearer, "точка возврата сохранена")
	playsound(src, 'sound/items/modsuit/time_anchor_set.ogg', MOD_TEMPORAL_VOLUME, TRUE)
	return TRUE

/obj/item/mod/module/rewinder/proc/on_rewind_end()
	SIGNAL_HANDLER
	UnregisterSignal(snapshot, COMSIG_PARENT_QDELETING)
	snapshot = null
	QDEL_NULL(temporal_lock)

/obj/item/mod/module/rewinder/proc/clear_rewind()
	UnregisterSignal(snapshot, COMSIG_PARENT_QDELETING)
	QDEL_NULL(snapshot)
	QDEL_NULL(temporal_lock)

/obj/item/mod/module/rewinder/on_suit_deactivation()
	clear_rewind()

/obj/item/mod/module/rewinder/on_unequip()
	clear_rewind()

/obj/item/mod/module/rewinder/on_uninstall(deleting = FALSE, user)
	clear_rewind()
	return ..()

/obj/item/mod/module/rewinder/Destroy()
	clear_rewind()
	return ..()

/datum/component/dejavu/timeline
	rewind_message = "MOD возвращает вас к сохранённой точке времени!"
	no_rewinds_message = "Перемотка завершена. Вы вернулись на десять секунд назад."
	var/stamina_loss

/datum/component/dejavu/timeline/Initialize(rewinds = 1, interval = MOD_REWIND_DELAY)
	. = ..()
	if(isliving(parent))
		var/mob/living/user = parent
		stamina_loss = user.getStaminaLoss()
	for(var/zone in saved_bodyparts)
		var/datum/saved_bodypart/saved = saved_bodyparts[zone]
		RegisterSignal(saved.old_part, COMSIG_PARENT_QDELETING, PROC_REF(forget_limb))

/datum/component/dejavu/timeline/proc/forget_limb(obj/item/bodypart/limb)
	SIGNAL_HANDLER
	for(var/zone in saved_bodyparts)
		var/datum/saved_bodypart/saved = saved_bodyparts[zone]
		if(saved.old_part == limb)
			saved.old_part = null
	UnregisterSignal(limb, COMSIG_PARENT_QDELETING)

/datum/component/dejavu/timeline/rewind_living()
	var/mob/living/user = parent
	user.setStaminaLoss(stamina_loss)
	return ..()

/datum/component/dejavu/timeline/rewind()
	playsound(parent, 'sound/items/modsuit/rewinder.ogg', MOD_TEMPORAL_VOLUME, TRUE)
	return ..()

/datum/component/dejavu/timeline/Destroy()
	for(var/zone in saved_bodyparts)
		var/datum/saved_bodypart/saved = saved_bodyparts[zone]
		UnregisterSignal(saved.old_part, COMSIG_PARENT_QDELETING)
		saved.old_part = null
	QDEL_LIST_ASSOC_VAL(saved_bodyparts)
	return ..()

/obj/item/mod/module/timestopper
	name = "MOD timestopper module"
	desc = "Останавливает время вокруг носителя, пока тот остаётся неподвижным. Остальные модули на это время заблокированы."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "timestop"
	module_type = MODULE_USABLE
	removable = FALSE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 60 SECONDS
	incompatible_modules = list(/obj/item/mod/module/timestopper)
	var/obj/effect/timestop/channelled/timestop
	var/datum/mod_temporal_lock/temporal_lock

/obj/item/mod/module/timestopper/on_use()
	if(timestop || !mod?.is_active() || !..())
		return FALSE
	if(!drain_power(use_power_cost))
		return FALSE
	temporal_lock = new(mod)
	timestop = new(get_turf(mod.wearer), MOD_TIMESTOP_RANGE, INFINITY, list(mod.wearer), FALSE)
	RegisterSignal(timestop, COMSIG_PARENT_QDELETING, PROC_REF(on_timestop_end))
	timestop.timestop()
	return TRUE

/obj/item/mod/module/timestopper/proc/on_timestop_end()
	SIGNAL_HANDLER
	UnregisterSignal(timestop, COMSIG_PARENT_QDELETING)
	timestop = null
	QDEL_NULL(temporal_lock)

/obj/item/mod/module/timestopper/proc/clear_timestop()
	UnregisterSignal(timestop, COMSIG_PARENT_QDELETING)
	QDEL_NULL(timestop)
	QDEL_NULL(temporal_lock)

/obj/item/mod/module/timestopper/on_suit_deactivation()
	clear_timestop()

/obj/item/mod/module/timestopper/on_unequip()
	clear_timestop()

/obj/item/mod/module/timestopper/on_uninstall(deleting = FALSE, user)
	clear_timestop()
	return ..()

/obj/item/mod/module/timestopper/Destroy()
	clear_timestop()
	return ..()

/obj/effect/timestop/channelled/timestop()
	target = get_turf(src)
	playsound(src, 'sound/magic/timeparadox2.ogg', MOD_TIMESTOP_VOLUME, TRUE, -1)
	for(var/atom/movable/movable as anything in immune)
		RegisterSignal(movable, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING), PROC_REF(end_channel))
	chronofield = make_field(/datum/proximity_monitor/advanced/timestop/mod_channel, list("current_range" = freezerange, "host" = src, "immune" = immune))

/obj/effect/timestop/channelled/proc/end_channel()
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/timestop/channelled/Destroy()
	for(var/atom/movable/movable as anything in immune)
		UnregisterSignal(movable, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	QDEL_NULL(chronofield)
	immune.Cut()
	target = null
	return ..()

/obj/item/mod/module/timeline_jumper
	name = "MOD timeline jumper module"
	desc = "Выводит носителя из потока времени и возвращает обратно. Пока носитель находится между временными линиями, костюм нельзя отключить."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "timeline_jumper"
	module_type = MODULE_USABLE
	removable = FALSE
	allowed_in_phaseout = TRUE
	hands_free_use = TRUE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 5 SECONDS
	incompatible_modules = list(/obj/item/mod/module/timeline_jumper)
	var/obj/effect/dummy/phased_mob/spell_jaunt/mod_chrono/phased_mob
	var/datum/action/mod_timeline_return/return_action

/obj/item/mod/module/timeline_jumper/on_select()
	if(phased_mob)
		return return_to_timeline()
	return ..()

/obj/item/mod/module/timeline_jumper/on_use()
	if(phased_mob)
		return return_to_timeline()
	if(!mod?.is_active() || !..())
		return FALSE
	var/turf/location = get_turf(mod.wearer)
	var/area/area = get_area(location)
	if(!location || area.area_flags & NOTELEPORT || location.flags_1 & NOJAUNT_1)
		to_chat(mod.wearer, span_warning("Местное поле блокирует переход между временными линиями."))
		return FALSE
	if(!isturf(mod.wearer.loc))
		return FALSE
	if(!drain_power(use_power_cost))
		return FALSE
	mod.wearer.SetAllImmobility(0)
	mod.wearer.setStaminaLoss(0)
	phased_mob = new(location)
	RegisterSignal(phased_mob, COMSIG_PARENT_QDELETING, PROC_REF(on_phase_end))
	RegisterSignal(mod, COMSIG_MOD_ACTIVATE, PROC_REF(block_shutdown))
	mod.wearer.forceMove(phased_mob)
	return_action = new(src)
	return_action.Grant(mod.wearer)
	playsound(src, 'sound/items/modsuit/time_anchor_set.ogg', MOD_TEMPORAL_VOLUME, TRUE)
	return TRUE

/obj/item/mod/module/timeline_jumper/proc/return_to_timeline()
	if(!phased_mob || !mod?.wearer || mod.wearer.loc != phased_mob)
		return FALSE
	clear_phase()
	playsound(src, 'sound/items/modsuit/time_anchor_set.ogg', MOD_TEMPORAL_VOLUME, TRUE)
	return TRUE

/obj/item/mod/module/timeline_jumper/proc/block_shutdown(datum/source, mob/user)
	SIGNAL_HANDLER
	to_chat(user, span_warning("Сначала вернитесь в поток времени."))
	return MOD_CANCEL_ACTIVATE

/obj/item/mod/module/timeline_jumper/proc/on_phase_end()
	SIGNAL_HANDLER
	UnregisterSignal(phased_mob, COMSIG_PARENT_QDELETING)
	UnregisterSignal(mod, COMSIG_MOD_ACTIVATE)
	phased_mob = null
	QDEL_NULL(return_action)

/obj/item/mod/module/timeline_jumper/proc/clear_phase()
	UnregisterSignal(phased_mob, COMSIG_PARENT_QDELETING)
	UnregisterSignal(mod, COMSIG_MOD_ACTIVATE)
	QDEL_NULL(phased_mob)
	QDEL_NULL(return_action)

/obj/item/mod/module/timeline_jumper/on_suit_deactivation()
	clear_phase()

/obj/item/mod/module/timeline_jumper/on_unequip()
	clear_phase()

/obj/item/mod/module/timeline_jumper/on_uninstall(deleting = FALSE, user)
	clear_phase()
	return ..()

/obj/item/mod/module/timeline_jumper/Destroy()
	clear_phase()
	return ..()

/datum/action/mod_timeline_return
	name = "Вернуться в поток времени"
	desc = "Выйти из фазового перехода без расхода энергии и ожидания перезарядки."
	background_icon_state = "bg_tech_blue"
	icon_icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	button_icon_state = "timeline_jumper"
	required_mobility_flags = NONE
	check_flags = AB_CHECK_ALIVE

/datum/action/mod_timeline_return/IsAvailable(silent = FALSE)
	if(!..())
		return FALSE
	var/obj/item/mod/module/timeline_jumper/module = target
	return !QDELETED(module) && module.phased_mob && module.mod?.wearer == owner && owner.loc == module.phased_mob

/datum/action/mod_timeline_return/Trigger(trigger_flags)
	if(!..())
		return FALSE
	var/obj/item/mod/module/timeline_jumper/module = target
	return module.return_to_timeline()

/obj/effect/dummy/phased_mob/spell_jaunt/mod_chrono
	name = "помехи реальности"
	verb_say = "отзывается эхом"

/obj/item/mod/module/eradication_lock
	name = "MOD eradication lock module"
	desc = "Запоминает владельца вне зависимости от его тела и стирает нарушителей из временной линии."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "eradicationlock"
	module_type = MODULE_USABLE
	removable = FALSE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 3
	cooldown_time = 0.5 SECONDS
	incompatible_modules = list(/obj/item/mod/module/eradication_lock, /obj/item/mod/module/dna_lock)
	var/true_owner_ckey

/obj/item/mod/module/eradication_lock/on_install()
	. = ..()
	RegisterSignal(mod, COMSIG_MOD_ACTIVATE, PROC_REF(on_mod_activation))
	RegisterSignal(mod, COMSIG_MOD_MODULE_REMOVAL, PROC_REF(on_mod_removal))

/obj/item/mod/module/eradication_lock/on_uninstall(deleting = FALSE, user)
	UnregisterSignal(mod, list(COMSIG_MOD_ACTIVATE, COMSIG_MOD_MODULE_REMOVAL))
	return ..()

/obj/item/mod/module/eradication_lock/on_use()
	if(!mod?.wearer?.ckey || !..() || !drain_power(use_power_cost))
		return FALSE
	true_owner_ckey = mod.wearer.ckey
	balloon_alert(mod.wearer, "владелец сохранён")
	return TRUE

/obj/item/mod/module/eradication_lock/proc/on_mod_activation(datum/source, mob/user)
	SIGNAL_HANDLER
	if(!true_owner_ckey || user?.ckey == true_owner_ckey)
		return NONE
	if(user == mod.wearer)
		eradicate(user)
	return MOD_CANCEL_ACTIVATE

/obj/item/mod/module/eradication_lock/proc/on_mod_removal(datum/source, mob/user)
	SIGNAL_HANDLER
	if(!true_owner_ckey || user?.ckey == true_owner_ckey)
		return NONE
	eradicate(user)
	return MOD_CANCEL_REMOVAL

/obj/item/mod/module/eradication_lock/proc/eradicate(mob/living/user)
	if(!isliving(user) || istype(user.loc, /obj/structure/mod_chrono_field))
		return
	to_chat(user, span_userdanger("Нарушение временной линии. Запущено стирание нарушителя."))
	user.investigate_log("was captured by the eradication lock in [mod].", INVESTIGATE_DEATHS)
	new /obj/structure/mod_chrono_field(get_turf(user), user)

/obj/item/mod/module/tem
	name = "MOD timestream eradication module"
	desc = "Создаёт луч стирания из временной линии. Для поддержания поля стойте неподвижно рядом с целью."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "chronogun"
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	removable = FALSE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 0.5 SECONDS
	incompatible_modules = list(/obj/item/mod/module/tem)
	var/obj/structure/mod_chrono_field/field
	var/turf/startpos

/obj/item/mod/module/tem/on_select_use(atom/target)
	if(!..() || !drain_power(use_power_cost))
		return FALSE
	field_disconnect(field)
	var/obj/item/projectile/energy/mod_chrono_beam/beam = new(get_turf(mod.wearer))
	beam.module_ref = WEAKREF(src)
	beam.firer = mod.wearer
	beam.preparePixelProjectile(target, mod.wearer)
	playsound(src, 'sound/items/modsuit/time_anchor_set.ogg', MOD_TEMPORAL_VOLUME, TRUE)
	INVOKE_ASYNC(beam, TYPE_PROC_REF(/obj/item/projectile, fire))
	return TRUE

/obj/item/mod/module/tem/proc/field_connect(obj/structure/mod_chrono_field/new_field)
	if(!new_field || !active || !mod?.is_active() || !mod.wearer)
		return FALSE
	var/obj/item/mod/module/tem/previous = new_field.module_ref?.resolve()
	if(previous)
		previous.field_disconnect(new_field)
		return FALSE
	field_disconnect(field)
	field = new_field
	field.module_ref = WEAKREF(src)
	field.attached = TRUE
	startpos = get_turf(mod.wearer)
	return TRUE

/obj/item/mod/module/tem/proc/field_disconnect(obj/structure/mod_chrono_field/old_field)
	if(old_field && (field == old_field || old_field.module_ref?.resolve() == src))
		old_field.module_ref = null
	if(field == old_field)
		field = null
		startpos = null

/obj/item/mod/module/tem/proc/field_check(obj/structure/mod_chrono_field/checking)
	if(checking != field || !checking || !active || !mod?.is_active() || !mod.wearer)
		return FALSE
	if(get_turf(mod.wearer) == startpos && !mod.wearer.lying && !mod.wearer.incapacitated() && (checking in view(3, mod.wearer)))
		return TRUE
	field_disconnect(checking)
	return FALSE

/obj/item/mod/module/tem/on_deactivation()
	field_disconnect(field)
	return ..()

/obj/item/mod/module/tem/on_unequip()
	field_disconnect(field)

/obj/item/mod/module/tem/on_uninstall(deleting = FALSE, user)
	field_disconnect(field)
	return ..()

/obj/item/mod/module/tem/Destroy()
	field_disconnect(field)
	return ..()

/obj/item/projectile/energy/mod_chrono_beam
	name = "луч стирания"
	icon_state = "chronobolt"
	range = 3
	nodamage = TRUE
	var/datum/weakref/module_ref

/obj/item/projectile/energy/mod_chrono_beam/on_hit(atom/target)
	var/obj/item/mod/module/tem/module = module_ref?.resolve()
	if(!module || !isliving(target))
		return ..()
	var/obj/structure/mod_chrono_field/field = new(get_turf(target), target, TRUE)
	if(!module.field_connect(field))
		field.module_ref = null
	return BULLET_ACT_HIT

/obj/item/projectile/energy/mod_chrono_beam/Destroy()
	module_ref = null
	return ..()

/obj/structure/mod_chrono_field
	name = "поле стирания"
	desc = "Аура энергии времени и блюспейса."
	icon = 'icons/effects/effects.dmi'
	icon_state = "chronofield"
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	move_resist = INFINITY
	var/mob/living/captured
	var/datum/weakref/module_ref
	var/attached = FALSE
	var/time_left = 3 SECONDS
	var/mutable_appearance/mob_underlay
	var/current_frame

/obj/structure/mod_chrono_field/Initialize(mapload, mob/living/target, linked = FALSE)
	. = ..()
	attached = linked
	if(!isliving(target))
		return INITIALIZE_HINT_QDEL
	captured = target
	RegisterSignal(captured, COMSIG_PARENT_QDELETING, PROC_REF(on_captured_deleted))
	captured.forceMove(src)
	build_snapshot()
	START_PROCESSING(SSobj, src)

/obj/structure/mod_chrono_field/proc/build_snapshot()
	var/icon/snapshot = getFlatIcon(captured)
	var/icon/frames = new()
	for(var/frame in 1 to MOD_CHRONO_FRAMES)
		var/icon/mask = icon('icons/obj/chronos.dmi', "erasing", SOUTH, frame)
		var/icon/picture = icon(snapshot)
		picture.Blend(mask, ICON_MULTIPLY)
		frames.Insert(picture, "frame[frame]")
	mob_underlay = mutable_appearance(frames, "frame1")
	update_icon()

/obj/structure/mod_chrono_field/update_icon()
	var/frame = clamp(CEILING((1 - time_left / (3 SECONDS)) * MOD_CHRONO_FRAMES, 1), 1, MOD_CHRONO_FRAMES)
	if(frame == current_frame || !mob_underlay)
		return
	current_frame = frame
	mob_underlay.icon_state = "frame[frame]"
	underlays = list(mob_underlay)

/obj/structure/mod_chrono_field/process(delta_time)
	if(QDELETED(captured))
		qdel(src)
		return
	if(time_left > (3 SECONDS))
		qdel(src)
		return
	if(time_left <= 0)
		erase_captured()
		return
	captured.Unconscious(MOD_CHRONO_UNCONSCIOUS_TIME)
	if(captured.loc != src)
		captured.forceMove(src)
	update_icon()
	var/obj/item/mod/module/tem/module = module_ref?.resolve()
	if(module && !module.field_check(src))
		return
	if(module || !attached)
		time_left -= delta_time * 1 SECONDS
	else
		time_left += delta_time * 1 SECONDS
	if(time_left <= 0)
		erase_captured()
	else if(time_left > (3 SECONDS))
		qdel(src)

/obj/structure/mod_chrono_field/proc/erase_captured()
	var/mob/living/victim = captured
	to_chat(victim, span_notice("Последний след вашего существования исчезает из потока времени."))
	victim.investigate_log("was erased by a MOD chronofield.", INVESTIGATE_DEATHS)
	var/mob/dead/observer/ghost = victim.ghostize(TRUE)
	if(ghost)
		ghost.mind = null
	qdel(victim)
	qdel(src)

/obj/structure/mod_chrono_field/proc/on_captured_deleted(mob/living/victim)
	SIGNAL_HANDLER
	UnregisterSignal(victim, COMSIG_PARENT_QDELETING)
	if(victim.loc == src)
		victim.moveToNullspace()
	captured = null
	qdel(src)

/obj/structure/mod_chrono_field/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/obj/item/mod/module/tem/module = module_ref?.resolve()
	module?.field_disconnect(src)
	UnregisterSignal(captured, COMSIG_PARENT_QDELETING)
	if(captured?.loc == src)
		captured.forceMove(get_turf(src))
	captured = null
	module_ref = null
	mob_underlay = null
	return ..()

/obj/structure/mod_chrono_field/bullet_act(obj/item/projectile/projectile)
	if(!istype(projectile, /obj/item/projectile/energy/mod_chrono_beam))
		return BULLET_ACT_HIT
	var/obj/item/projectile/energy/mod_chrono_beam/beam = projectile
	var/obj/item/mod/module/tem/module = beam.module_ref?.resolve()
	module?.field_connect(src)
	return BULLET_ACT_HIT

/obj/structure/mod_chrono_field/return_air()
	var/datum/gas_mixture/air = new()
	air.set_moles(GAS_O2, MOLES_O2STANDARD)
	air.set_moles(GAS_N2, MOLES_N2STANDARD)
	air.set_temperature(T20C)
	return air

/obj/structure/mod_chrono_field/assume_air()
	return FALSE

/obj/structure/mod_chrono_field/ex_act()
	return

/obj/structure/mod_chrono_field/singularity_act()
	return

/obj/structure/mod_chrono_field/singularity_pull()
	return

/obj/structure/mod_chrono_field/blob_act()
	return

/obj/effect/dummy/phased_mob/spell_jaunt/mod_chrono/relaymove(mob/user, direction)
	var/turf/destination = get_step(src, direction)
	var/area/area = get_area(destination)
	if(!destination || area.area_flags & NOTELEPORT)
		to_chat(user, span_warning("Местное поле блокирует переход."))
		return FALSE
	return ..()

/datum/proximity_monitor/advanced/timestop/mod_channel/freeze_atom(atom/movable/movable)
	. = ..()
	if(.)
		RegisterSignal(movable, COMSIG_PARENT_QDELETING, PROC_REF(on_frozen_deleted))

/datum/proximity_monitor/advanced/timestop/mod_channel/unfreeze_atom(atom/movable/movable)
	UnregisterSignal(movable, COMSIG_PARENT_QDELETING)
	frozen_structures -= movable
	return ..()

/datum/proximity_monitor/advanced/timestop/mod_channel/proc/on_frozen_deleted(atom/movable/movable)
	SIGNAL_HANDLER
	unfreeze_atom(movable)

/datum/outfit/chrono_agent
	name = "Timeline Eradication Agent"
	uniform = /obj/item/clothing/under/color/white
	suit_store = /obj/item/tank/internals/oxygen
	mask = /obj/item/clothing/mask/breath
	back = /obj/item/mod/control/pre_equipped/chrono

/datum/outfit/chrono_agent/post_equip(mob/living/carbon/human/agent, visuals_only)
	. = ..()
	if(visuals_only)
		return
	var/obj/item/mod/control/mod = agent.back
	if(!istype(mod))
		return
	var/obj/item/mod/module/eradication_lock/lock = locate() in mod.modules
	if(lock)
		lock.true_owner_ckey = agent.ckey

/datum/proximity_monitor/advanced/timestop/mod_channel
	var/list/mob_states = list()

/datum/proximity_monitor/advanced/timestop/mod_channel/freeze_mob(mob/living/user)
	var/list/state = list("sight" = user.sight, "hud" = user.hud_used?.hud_version)
	if(isanimal(user))
		var/mob/living/simple_animal/animal = user
		state["ai"] = animal.AIStatus
	mob_states[user] = state
	return ..()

/datum/proximity_monitor/advanced/timestop/mod_channel/unfreeze_mob(mob/living/user)
	var/list/state = mob_states[user]
	. = ..()
	if(!state)
		return
	user.sight = state["sight"]
	if(user.client && !isnull(state["hud"]))
		user.hud_used?.show_hud(state["hud"])
	if(isanimal(user))
		var/mob/living/simple_animal/animal = user
		animal.toggle_ai(state["ai"])
	mob_states -= user

/datum/proximity_monitor/advanced/timestop/mod_channel/Destroy()
	. = ..()
	mob_states = null

/datum/spellbook_entry/item/mod/Buy(mob/living/carbon/human/user, obj/item/spellbook/book)
	var/obj/item/mod/control/mod = new item_path(get_turf(user))
	var/obj/item/mod/module/eradication_lock/lock = locate() in mod.modules
	if(lock)
		lock.true_owner_ckey = user.ckey
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	return TRUE
