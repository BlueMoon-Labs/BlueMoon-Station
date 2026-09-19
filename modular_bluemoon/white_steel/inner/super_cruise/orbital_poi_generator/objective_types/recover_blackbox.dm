/datum/orbital_objective/recover_blackbox
	name = "Спасение чёрного ящика"
	var/generated = FALSE
	//The blackbox required to recover.
	var/obj/item/blackbox/objective/linked_blackbox
	//Relatively easy mission.
	min_payout = 10 * CARGO_CRATE_VALUE
	max_payout = 50 * CARGO_CRATE_VALUE

/datum/orbital_objective/recover_blackbox/generate_objective_stuff(turf/chosen_turf)
	generated = TRUE
	linked_blackbox = new(chosen_turf)
	linked_blackbox.setup_recover(src)

/datum/orbital_objective/recover_blackbox/get_text()
	. = "Аванпост [station_name] недавно погрузился во тьму и больше оттуда не поступало сигналов. Отправьтесь туда и найдите чёрный ящик, вознаграждение в [payout] кредитов окупит затраты."
	if(linked_beacon)
		. += " Станция находится в точке [linked_beacon.name]. Успехов."

/datum/orbital_objective/recover_blackbox/check_failed()
	if(!QDELETED(linked_blackbox) || !generated)
		return FALSE
	return TRUE

/*
 * Blackbox Item: Objective target, handles completion
 * Traitors can steal the Nanotrasen blackbox to prevent the station
 * from completing their objective and recover invaluable data.
 */
/obj/item/blackbox/objective
	name = "повреждённый чёрный ящик"
	w_class = WEIGHT_CLASS_BULKY
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/item/blackbox/objective/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/gps, "BLACKBOX #[rand(1000, 9999)]", TRUE)

/obj/item/blackbox/objective/proc/setup_recover(linked_mission)
	AddComponent(/datum/component/recoverable, linked_mission)

/obj/item/blackbox/objective/examine(mob/user)
	. = ..()
	. += "<hr><span class='notice'>Доставьте его на станцию и отправьте его через <b>терминал сдачи контрабанды</b>, чтобы завершить контракт.</span>"

/datum/component/recoverable
	var/recovered = FALSE
	var/datum/orbital_objective/recover_blackbox/linked_obj

/datum/component/recoverable/Initialize(_linked_obj)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	linked_obj = _linked_obj
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, .proc/attack_self)

/datum/component/recoverable/proc/attack_self(mob/user)
	SIGNAL_HANDLER
	var/atom/movable/pA = parent
	pA.say("Чёрный ящик должен быть отправлен NanoTrasen через терминал сдачи контрабанды на станции.")

/datum/component/recoverable/proc/initiate_recovery()
	var/atom/movable/parentobj = parent
	if(recovered)
		return
	recovered = TRUE
	//Prevent picking up
	parentobj.anchored = TRUE
	//Drop to ground
	parentobj.forceMove(get_turf(parent))
	//Complete objective
	if(linked_obj)
		linked_obj.complete_objective()
	else
		parentobj.say("Малоприоритетный предмен обнаружен, выдаём награду в размере 200 кредитов.")
		new /obj/item/stack/spacecash/c100(get_turf(parent), 2)
	//Fly away
	var/mutable_appearance/balloon
	var/mutable_appearance/balloon2
	var/obj/effect/extraction_holder/holder_obj = new(parentobj.loc)
	holder_obj.appearance = parentobj.appearance
	parentobj.forceMove(holder_obj)
	balloon2 = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_expand")
	balloon2.pixel_y = 10
	balloon2.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	holder_obj.add_overlay(balloon2)
	sleep(4)
	balloon = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_balloon")
	balloon.pixel_y = 10
	balloon.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	holder_obj.cut_overlay(balloon2)
	holder_obj.add_overlay(balloon)
	playsound(holder_obj.loc, 'sound/items/fultext_deploy.ogg', 50, 1, -3)
	animate(holder_obj, pixel_z = 10, time = 20)
	sleep(20)
	animate(holder_obj, pixel_z = 15, time = 10)
	sleep(10)
	animate(holder_obj, pixel_z = 10, time = 10)
	sleep(10)
	animate(holder_obj, pixel_z = 15, time = 10)
	sleep(10)
	animate(holder_obj, pixel_z = 10, time = 10)
	sleep(10)
	playsound(holder_obj.loc, 'sound/items/fultext_launch.ogg', 50, 1, -3)
	animate(holder_obj, pixel_z = 1000, time = 30)
	sleep(30)
	qdel(parent)
	qdel(holder_obj)
	qdel(src)
