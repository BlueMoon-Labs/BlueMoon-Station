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
	var/had_research_scanner = FALSE

/obj/item/mod/module/reagent_scanner/advanced/on_activation()
	. = ..()
	if(!.)
		return
	had_research_scanner = mod.wearer.research_scanner
	mod.wearer.research_scanner = TRUE
	RegisterSignal(SSdcs, COMSIG_GLOB_EXPLOSION, PROC_REF(sense_explosion))

/obj/item/mod/module/reagent_scanner/advanced/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	mod.wearer.research_scanner = had_research_scanner
	had_research_scanner = FALSE
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
	desc = "Модуль, использующий гравитационное ядро для полного обнуления веса пользователя."
	icon_state = "antigrav"
	module_type = MODULE_TOGGLE
	complexity = 3
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.7
	incompatible_modules = list(/obj/item/mod/module/anomaly_locked)
	cooldown_time = 0.5 SECONDS
	accepted_anomalies = list(/obj/item/assembly/signaler/anomaly/grav)
	mod_module_flags = MOD_MODULE_SCIENCE // BLUEMOON ADD

/obj/item/mod/module/anomaly_locked/antigrav/on_activation()
	. = ..()
	if(!.)
		return
	if(mod.wearer.has_gravity())
		new /obj/effect/temp_visual/mook_dust(get_turf(mod))
	mod.wearer.AddElement(/datum/element/forced_gravity, 0)
	mod.wearer.update_gravity(mod.wearer.has_gravity())
	playsound(mod, 'sound/effects/gravhit.ogg', 50)

/obj/item/mod/module/anomaly_locked/antigrav/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	mod.wearer.RemoveElement(/datum/element/forced_gravity, 0)
	mod.wearer.update_gravity(mod.wearer.has_gravity())
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
	mod_module_flags = MOD_MODULE_SCIENCE // BLUEMOON ADD

/obj/item/mod/module/anomaly_locked/teleporter/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	var/turf/open/target_turf = get_turf(target)
	if(!istype(target_turf) || is_blocked_turf(target_turf) || !(target_turf in view(mod.wearer)))
		mod.balloon_alert(mod.wearer, "неверная цель!")
		return
	mod.balloon_alert(mod.wearer, "телепортируем...")
	var/matrix/pre_matrix = matrix()
	pre_matrix.Scale(4, 0.25)
	var/matrix/post_matrix = matrix()
	post_matrix.Scale(0.25, 4)
	animate(mod.wearer, teleport_time, color = COLOR_CYAN, transform = pre_matrix.Multiply(mod.wearer.transform), easing = SINE_EASING|EASE_OUT)
	if(!do_after(mod.wearer, teleport_time, target = mod))
		mod.balloon_alert(mod.wearer, "прервано!")
		animate(mod.wearer, teleport_time*0.1, color = null, transform = post_matrix.Multiply(mod.wearer.transform), easing = SINE_EASING|EASE_IN)
		return
	animate(mod.wearer, teleport_time*0.1, color = null, transform = post_matrix.Multiply(mod.wearer.transform), easing = SINE_EASING|EASE_IN)
	if(!do_teleport(mod.wearer, target_turf, asoundin = 'sound/effects/phasein.ogg'))
		return
	drain_power(use_power_cost)

/obj/item/mod/module/anomaly_locked/teleporter/prebuilt
	prebuilt = TRUE
