/obj/item/BoH_inert
	name = "inert bag of nothing"
	desc = "В нынешнем состоянии – габаритный кусок металла со слотом, готовым принять ядро блюспейс-аномалии."
	icon = 'modular_bluemoon/phenyamomota/code/modules/holdingfashion_port/icons/items.dmi'
	icon_state = "bag-inert"
	var/backpack_type = /obj/item/storage/backpack/holding

/obj/item/BoH_inert/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(I.type == /obj/item/assembly/signaler/anomaly/bluespace && !(user.a_intent == INTENT_HARM))
		if(INTERACTING_WITH(user, src))
			return
		to_chat(user, span_notice("Вы начинаете вставлять [I] в [src]."))
		if(!do_after(user, 30, src))
			return
		user.temporarilyRemoveItemFromInventory(src)
		var/created_boh = new backpack_type(loc)
		if(loc == user)
			user.put_in_hands(created_boh)
		qdel(I)
		qdel(src)

/obj/item/BoH_inert/bag
	name = "inert bag of holding"
	backpack_type = /obj/item/storage/backpack/holding

/obj/item/BoH_inert/satchel
	name = "inert satchel of holding"
	icon_state = "satchel-inert"
	backpack_type = /obj/item/storage/backpack/holding/satchel

/obj/item/BoH_inert/duffel
	name = "inert duffel bag of holding"
	icon_state = "duff-inert"
	backpack_type = /obj/item/storage/backpack/holding/duffel

////////////////////////////////////////////////////////////////

/obj/item/storage/backpack/holding
	var/second_chance = TRUE
	verb_say = "states"

/obj/item/storage/backpack/holding/Initialize(mapload)
	. = ..()
	desc += span_info("<br>Можно рекалибровать на твёрдой поверхности нейтрализатором аномалий.")

/obj/item/storage/backpack/holding/examine()
	. = ..()
	var/stability = round(obj_integrity/max_integrity, 0.01) * 100
	. += span_info("<br>Стабильность ядра: [stability]%.")

/obj/item/storage/backpack/holding/proc/teleport_damage(tele_damage, force_destruction = FALSE)
	obj_integrity = max(0, obj_integrity - tele_damage)
	var/stability = round(obj_integrity/max_integrity, 0.01) * 100
	if(stability == 0 && second_chance && !force_destruction)
		second_chance = FALSE
		obj_integrity = max_integrity * 0.01
		stability = 1

	switch(stability)
		if(0)
			say("Внимание, стабильность конструкции изменена и составляет 0%. Разрушение оболочки неизбежно.")
			SEND_SIGNAL(src, COMSIG_TRY_STORAGE_QUICK_EMPTY)
			new /obj/effect/anomaly/bluespace(get_turf(src))
			qdel(src)
		if(1 to 25)
			say("Внимание, стабильность конструкции изменена и составляет [stability]%. Требуется срочная рекалибровка.")
		if(26 to 50)
			say("Cтабильность конструкции изменена и составляет [stability]%. Крайне рекомендуется рекалибровка.")
		if(51 to 75)
			say("Cтабильность конструкции изменена и составляет [stability]%. Рекомендуется рекалибровка.")
		if(76 to 100)
			say("Cтабильность конструкции изменена и составляет [stability]%.")

/obj/item/storage/backpack/holding/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/anomaly_neutralizer) && loc != user && !(user.a_intent == INTENT_HELP))
		if(INTERACTING_WITH(user, src))
			return
		to_chat(user, span_notice("Вы начинаете рекалибровку [src] при помощи [I]."))
		if(do_after(user, 20 SECONDS, src))
			to_chat(user, span_notice("Электроника [I] сгорает после процесса рекалибрации [src]!"))
			obj_integrity = max_integrity
			say("Рекалибровка конструкции завершена. Целостность составляет 100%.")
			qdel(I)
			return

	return ..()
