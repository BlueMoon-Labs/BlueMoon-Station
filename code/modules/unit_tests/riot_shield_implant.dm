/// Клавиша блока не выдвигает корпоративный щит импланта ниже его уровня тревоги на станции.
/datum/unit_test/riot_shield_implant_alert_gate/Run()
	var/turf/station_floor
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		station_floor = locate(/turf/open/floor) in block(locate(1, 1, station_z), locate(world.maxx, world.maxy, station_z))
		if(station_floor)
			break
	TEST_ASSERT_NOTNULL(station_floor, "На станционном уровне нашёлся пол.")
	var/old_level = GLOB.security_level
	GLOB.security_level = SEC_LEVEL_GREEN
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, station_floor)
	var/obj/item/organ/cyberimp/arm/shield/sec_level/implant = allocate(/obj/item/organ/cyberimp/arm/shield/sec_level)
	implant.Insert(user)
	implant.on_signal(user, null, list())
	var/extended_on_green = !isnull(locate(/obj/item/shield/riot/implant) in user.held_items)
	implant.Retract(TRUE)
	GLOB.security_level = RIOT_SHIELD_SEC_LEVEL
	implant.on_signal(user, null, list())
	var/extended_on_alert = !isnull(locate(/obj/item/shield/riot/implant) in user.held_items)
	implant.Retract(TRUE)
	GLOB.security_level = old_level
	TEST_ASSERT(!extended_on_green, "На зелёном коде блок не выдвигает щит.")
	TEST_ASSERT(extended_on_alert, "На нужном уровне тревоги блок выдвигает щит.")
