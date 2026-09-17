// BLUEMOON ADD START - механическая система разрешений на оружие (порт Skyrat permit_pin)
GLOBAL_VAR_INIT(permit_pin_unrestricted, FALSE)

// Firing pin that can be used off station freely, and requires a permit to use on-station
/obj/item/firing_pin/permit_pin
	name = "permit-locked firing pin"
	desc = "Небольшое устройство аутентификации, блокирующее оружие на территории станции, если у стрелка нет разрешения на оружие. Вне станции оружие с этим пином работает свободно."
	icon_state = "firing_pin_explorer"
	fail_message = "<span class='warning'>ОТКАЗ РАЗРЕШЕНИЯ: У СТРЕЛКА НЕТ ПРАВ НА ОРУЖИЕ!</span>"
	pin_removeable = TRUE

/obj/item/firing_pin/permit_pin/examine(mob/user)
	. = ..()
	if(GLOB.permit_pin_unrestricted)
		. += span_notice("Механизм блокировки оружия временно отключён приказом командования.")
	else
		. += span_notice("Пин авторизует оружие на станции только для обладателей разрешения на оружие: доступа ACCESS_WEAPONS, бумажного разрешения или служебного вооружения.")

// This checks that the user isn't on the station Z-level.
/obj/item/firing_pin/permit_pin/pin_auth(mob/living/user)
	var/turf/station_check = get_turf(user)

	if(obj_flags & EMAGGED)
		return TRUE

	if(GLOB.permit_pin_unrestricted)
		return TRUE

	if(!station_check || !is_station_level(station_check.z)) //Вне станции можно стрелять свободно.
		return TRUE

	var/obj/item/card/id/the_id = user.get_idcard()

	if(!the_id)
		return FALSE

	if(ACCESS_WEAPONS in the_id.GetAccess())
		return TRUE

	// BLUEMOON ADD - проверка бумажного разрешения (старой системы), прикреплённого на или к форме
	if(ishuman(user))
		var/mob/living/carbon/human/the_human = user
		var/obj/item/clothing/under/the_uniform = the_human.w_uniform
		if(the_uniform)
			for(var/obj/item/clothing/accessory/permit/permit in the_uniform.accessories_attached)
				if(permit.authorizes_user(the_human))
					return TRUE

	return FALSE

/**
 * Отключает/восстанавливает блокировку permit-пинов. Вызывается через keycard authentication.
 */
/proc/toggle_permit_pins()
	GLOB.permit_pin_unrestricted = !GLOB.permit_pin_unrestricted
	minor_announce("Оружейные пины-разрешения теперь [GLOB.permit_pin_unrestricted ? "РАЗБЛОКИРОВАНЫ" : "ВНОВЬ ЗАБЛОКИРОВАНЫ"].", "Обновление оружейных систем:")
	SSblackbox.record_feedback("nested tally", "keycard_auths", 1, list("permit-locked pins", GLOB.permit_pin_unrestricted ? "unlocked" : "locked"))
// BLUEMOON ADD END