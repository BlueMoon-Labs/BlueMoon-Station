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
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	incompatible_modules = list(/obj/item/mod/module/microwave_beam)
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
	name = "MOD waddle module"
	desc = "Гравитонные приводы в корпусе MOD-костюма заставляют носителя забавно покачиваться и подпрыгивать под писк. \
		Работают при ходьбе ногами и движении опорным хвостом, не требуют ботинок."
	icon_state = "waddle"
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	module_type = MODULE_TOGGLE
	removable = FALSE
	incompatible_modules = list(/obj/item/mod/module/waddle)
	required_modpart_index = MOD_PART_CHEST
	startup_with_suit = TRUE
	var/datum/component/squeak/squeak_component

/obj/item/mod/module/waddle/on_activation()
	if(active || !mod?.wearer)
		return FALSE
	if(!mod.wearer.get_num_supporting_limbs())
		mod.balloon_alert(mod.wearer, "нет действующей опоры!")
		return FALSE
	. = ..()
	if(!.)
		return FALSE
	squeak_component = required_modpart.AddComponent(/datum/component/squeak, list('sound/effects/clownstep1.ogg'=1,'sound/effects/clownstep2.ogg'=1), 50)
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(on_waddle_move))
	ADD_TRAIT(mod.wearer, TRAIT_WADDLING, REF(src))
	mod.wearer.LoadComponent(/datum/component/waddling)
	if(mod.wearer.mind && HAS_TRAIT(mod.wearer.mind, TRAIT_CLOWN_MENTALITY))
		SEND_SIGNAL(mod.wearer, COMSIG_CLEAR_MOOD_EVENT, "noshoes")

/obj/item/mod/module/waddle/on_deactivation()
	if(!active)
		return FALSE
	. = ..()
	UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
	QDEL_NULL(squeak_component)
	REMOVE_TRAIT(mod.wearer, TRAIT_WADDLING, REF(src))
	if(!HAS_TRAIT(mod.wearer, TRAIT_WADDLING))
		var/datum/component/waddling/waddle_component = mod.wearer.GetComponent(/datum/component/waddling)
		waddle_component?.RemoveComponent()
	if(mod.wearer.mind && HAS_TRAIT(mod.wearer.mind, TRAIT_CLOWN_MENTALITY))
		SEND_SIGNAL(mod.wearer, COMSIG_ADD_MOOD_EVENT, "noshoes", /datum/mood_event/noshoes)

/obj/item/mod/module/waddle/on_suit_deactivation()
	if(active)
		on_deactivation()
	return ..()

/obj/item/mod/module/waddle/on_unequip()
	if(active)
		on_deactivation()
	return ..()

/obj/item/mod/module/waddle/proc/on_waddle_move(mob/living/source)
	SIGNAL_HANDLER
	if(source.lying || !source.get_num_supporting_limbs() || !source.has_gravity())
		return
	squeak_component?.step_squeak()
