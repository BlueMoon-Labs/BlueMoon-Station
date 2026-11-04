//Service modules for MODsuits

///Bike Horn - Plays a bike horn sound.
/obj/item/mod/module/bikehorn
	name = "MOD bike horn module"
	desc = "Установленное на плече тяжёлое звуковое орудие, этот модуль использует лучшую фемтоманипуляторную технологию, чтобы \
		точно доставить почти смертельное сжатие... велосипедному гудку, производя крайне запоминающийся звук."
	icon_state = "bikehorn"
	module_type = MODULE_USABLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/bikehorn)
	cooldown_time = 1 SECONDS

/obj/item/mod/module/bikehorn/on_use()
	. = ..()
	if(!.)
		return
	playsound(mod, 'sound/items/bikehorn.ogg', 100, FALSE)
	drain_power(use_power_cost)

///Microwave Beam - Microwaves items instantly.
/obj/item/mod/module/microwave_beam
	name = "MOD microwave beam module"
	desc = "Удивительно бытовое устройство, этот модуль устанавливается в ладонь пользователя, \
		подключаясь к кулинарным сканерам, расположенным в шлеме, чтобы облучать еду точной микроволновой радиацией, \
		позволяя готовить еду на расстоянии с наибольшей лёгкостью. Не рекомендуется использовать против винограда."
	icon_state = "microwave_beam"
	module_type = MODULE_ACTIVE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	incompatible_modules = list(/obj/item/mod/module/microwave_beam)
	have_shortcut_activation = TRUE
	required_modpart_index = MOD_PART_GLOVES
	cooldown_time = 10 SECONDS
	var/obj/machinery/microwave/microwave

/obj/item/mod/module/microwave_beam/Initialize(mapload)
	microwave = new()
	. = ..()

/obj/item/mod/module/microwave_beam/Destroy()
	QDEL_NULL(microwave)
	. = ..()

/obj/item/mod/module/microwave_beam/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	if(!isitem(target))
		return
	if(!isturf(target.loc))
		mod.balloon_alert(mod.wearer, "должно быть на полу!")
		return
	var/obj/item/microwave_target = target
	var/turf/microwave_target_loc = target.loc
	var/datum/effect_system/spark_spread/spark_effect = new()
	spark_effect.set_up(2, 1, mod.wearer)
	spark_effect.start()
	mod.wearer.Beam(target,icon_state="lightning[rand(1,12)]", time = 5)
	if(microwave_target.microwave_act(microwave))
		playsound(mod, 'sound/machines/microwave/microwave-end.ogg', 50, FALSE)
	else
		mod.balloon_alert(mod.wearer, "не может быть облучено микроволнами!")
	var/datum/effect_system/spark_spread/spark_effect_two = new()
	spark_effect_two.set_up(2, 1, microwave_target_loc)
	spark_effect_two.start()
	drain_power(use_power_cost)

//Waddle

/obj/item/mod/module/waddle
	complexity = 1
	mod_module_flags = MOD_MODULE_GENERAL
	name = "MOD waddle module"
	desc = "Гравитонные приводы в корпусе MOD-костюма заставляют носителя покачиваться и подпрыгивать под писк. \
		Работают при ходьбе ногами и движении опорным хвостом, не требуют ботинок."
	icon_state = "waddle"
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	module_type = MODULE_TOGGLE
	incompatible_modules = list(/obj/item/mod/module/waddle)
	required_modpart_index = MOD_PART_CHEST
	startup_with_suit = TRUE
	var/mob/living/carbon/human/waddle_user
	var/datum/component/squeak/mod_waddle/squeak_component

/obj/item/mod/module/waddle/on_activation()
	if(active || !mod?.wearer)
		return FALSE
	if(!mod.wearer.get_num_supporting_limbs())
		mod.balloon_alert(mod.wearer, "нет действующей опоры!")
		return FALSE
	. = ..()
	if(!.)
		return
	waddle_user = mod.wearer
	ADD_TRAIT(waddle_user, TRAIT_WADDLING, REF(src))
	waddle_user.LoadComponent(/datum/component/waddling)
	squeak_component = required_modpart.AddComponent(/datum/component/squeak/mod_waddle, list('sound/effects/clownstep1.ogg' = 1, 'sound/effects/clownstep2.ogg' = 1), MOD_WADDLE_VOLUME)
	RegisterSignal(waddle_user, COMSIG_MOVABLE_MOVED, PROC_REF(on_waddle_move))
	if(waddle_user.mind && HAS_TRAIT(waddle_user.mind, TRAIT_CLOWN_MENTALITY))
		SEND_SIGNAL(waddle_user, COMSIG_CLEAR_MOOD_EVENT, "noshoes")

/obj/item/mod/module/waddle/on_deactivation()
	clear_waddle()
	return ..()

/obj/item/mod/module/waddle/on_suit_deactivation()
	if(active)
		on_deactivation()
	return ..()

/obj/item/mod/module/waddle/on_unequip()
	clear_waddle()
	return ..()

/obj/item/mod/module/waddle/on_uninstall(deleting = FALSE, user)
	clear_waddle()
	return ..()

/obj/item/mod/module/waddle/Destroy()
	clear_waddle()
	return ..()

/obj/item/mod/module/waddle/proc/clear_waddle()
	QDEL_NULL(squeak_component)
	if(!waddle_user)
		return
	UnregisterSignal(waddle_user, COMSIG_MOVABLE_MOVED)
	REMOVE_TRAIT(waddle_user, TRAIT_WADDLING, REF(src))
	if(!HAS_TRAIT(waddle_user, TRAIT_WADDLING))
		qdel(waddle_user.GetComponent(/datum/component/waddling))
	if(waddle_user.mind && HAS_TRAIT(waddle_user.mind, TRAIT_CLOWN_MENTALITY))
		SEND_SIGNAL(waddle_user, COMSIG_ADD_MOOD_EVENT, "noshoes", /datum/mood_event/noshoes)
	waddle_user = null

/obj/item/mod/module/waddle/proc/on_waddle_move(mob/living/source)
	SIGNAL_HANDLER
	if(source.lying || !source.get_num_supporting_limbs() || !source.has_gravity())
		return
	squeak_component?.step_squeak()

/datum/component/squeak/mod_waddle
