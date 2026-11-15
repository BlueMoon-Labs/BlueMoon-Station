/// Все варианты клинков богомола тратят вдвое меньше стамины на атаку.
/datum/unit_test/mantis_blade_stamina_cost/Run()
	var/expected_mass = TOTAL_MASS_HAND_REPLACEMENT * 0.5
	for(var/blade_type in list(/obj/item/melee/implantarmblade, /obj/item/melee/implantarmblade/corpo, /obj/item/melee/implantarmblade/syndie))
		var/obj/item/melee/implantarmblade/blade = allocate(blade_type)
		TEST_ASSERT_EQUAL(blade.total_mass, expected_mass, "[blade_type] должен иметь вдвое меньшую стоимость атаки по стамине")

/// Длительность всех сандевистанов увеличена вдвое.
/datum/unit_test/sandevistan_duration_balance/Run()
	var/list/expected_durations = list(
		/obj/item/organ/cyberimp/brain/sandevistan = 8 SECONDS,
		/obj/item/organ/cyberimp/brain/sandevistan/military = 12 SECONDS,
		/obj/item/organ/cyberimp/brain/sandevistan/sec_level = 8 SECONDS,
	)
	for(var/implant_type in expected_durations)
		var/obj/item/organ/cyberimp/brain/sandevistan/implant = allocate(implant_type)
		TEST_ASSERT_EQUAL(implant.duration, expected_durations[implant_type], "[implant_type] имеет неверную длительность")

/// Корпоративный сандевистан нельзя активировать на станции ниже красного кода.
/datum/unit_test/corporate_sandevistan_red_code/Run()
	var/turf/station_floor
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		station_floor = locate(/turf/open/floor) in block(locate(1, 1, station_z), locate(world.maxx, world.maxy, station_z))
		if(station_floor)
			break
	TEST_ASSERT_NOTNULL(station_floor, "На станционном уровне нашёлся пол")
	if(!station_floor)
		return

	var/old_level = GLOB.security_level
	GLOB.security_level = SEC_LEVEL_GREEN
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, station_floor)
	var/obj/item/organ/cyberimp/brain/sandevistan/sec_level/implant = allocate(/obj/item/organ/cyberimp/brain/sandevistan/sec_level)
	implant.Insert(user)
	implant.activate_sandevistan()
	var/activated_on_green = implant.active

	GLOB.security_level = SEC_LEVEL_RED
	implant.activate_sandevistan()
	var/activated_on_red = implant.active
	implant.deactivate_sandevistan()
	GLOB.security_level = old_level
	TEST_ASSERT(!activated_on_green, "Корпоративный сандевистан не должен включаться ниже красного кода")
	TEST_ASSERT(activated_on_red, "Корпоративный сандевистан должен включаться с красного кода")

/// Антагонистические киберимпланты продаются всем трём магазинам с заданной ценой и содержимым.
/datum/unit_test/cybernetic_implants_uplink/Run()
	var/list/expected_entries = list(
		/datum/uplink_item/implants/berserker = list(10, /obj/item/autosurgeon/syndicate/berserker, /obj/item/organ/cyberimp/brain/berserker/syndie),
		/datum/uplink_item/implants/ballistic_processor = list(2, /obj/item/autosurgeon/syndicate/ballistic_processor, /obj/item/organ/cyberimp/arm/ballistic_processor),
		/datum/uplink_item/implants/reinforced_skeleton = list(2, /obj/item/autosurgeon/syndicate/reinforced_skeleton, /obj/item/organ/cyberimp/chest/reinforced_skeleton),
		/datum/uplink_item/implants/subdermal_armor = list(3, /obj/item/autosurgeon/syndicate/subdermal_armor, /obj/item/organ/cyberimp/chest/subdermal_armor),
		/datum/uplink_item/implants/reinforced_tendons = list(2, /obj/item/autosurgeon/syndicate/reinforced_tendons, /obj/item/organ/cyberimp/leg/tendons),
		/datum/uplink_item/implants/fortified_ankles = list(2, /obj/item/autosurgeon/syndicate/fortified_ankles, /obj/item/organ/cyberimp/leg/ankles),
		/datum/uplink_item/implants/lynx_paws = list(2, /obj/item/autosurgeon/syndicate/lynx_paws, /obj/item/organ/cyberimp/leg/lynx_paws),
		/datum/uplink_item/implants/militech_optics = list(2, /obj/item/autosurgeon/syndicate/militech_optics, /obj/item/organ/cyberimp/eyes/optical/militech),
	)
	for(var/entry_type in expected_entries)
		var/list/config = expected_entries[entry_type]
		var/datum/uplink_item/implants/entry = new entry_type
		TEST_ASSERT_EQUAL(entry.cost, config[1], "[entry_type] имеет неверную цену")
		TEST_ASSERT_EQUAL(entry.item, config[2], "[entry_type] продаёт неверный автохирург")
		TEST_ASSERT(entry.purchasable_from & UPLINK_SYNDICATE, "[entry_type] должен быть доступен Синдикату")
		TEST_ASSERT(entry.purchasable_from & UPLINK_NUKE_OPS, "[entry_type] должен быть доступен ядерным оперативникам")
		TEST_ASSERT(entry.purchasable_from & UPLINK_TRAITORS, "[entry_type] должен быть доступен предателям")
		var/obj/item/autosurgeon/surgeon = allocate(entry.item)
		TEST_ASSERT_EQUAL(surgeon.starting_organ, config[3], "[entry_type] устанавливает неверный имплант")
		qdel(entry)

/// Риск взрыва есть только у базовых киберорганов, а не у улучшенных моделей.
/datum/unit_test/basic_cybernetic_organ_volatility/Run()
	for(var/organ_type in list(/obj/item/organ/heart/cybernetic, /obj/item/organ/liver/cybernetic, /obj/item/organ/lungs/cybernetic, /obj/item/organ/stomach/cybernetic))
		var/obj/item/organ/organ = allocate(organ_type)
		TEST_ASSERT(organ.is_volatile_basic_cybernetic(), "[organ_type] должен быть нестабильным")
	for(var/organ_type in list(
		/obj/item/organ/heart/cybernetic/tier2,
		/obj/item/organ/heart/cybernetic/tier3,
		/obj/item/organ/liver/cybernetic/tier2,
		/obj/item/organ/liver/cybernetic/tier3,
		/obj/item/organ/lungs/cybernetic/tier2,
		/obj/item/organ/lungs/cybernetic/tier3,
		/obj/item/organ/stomach/cybernetic/tier2,
		/obj/item/organ/stomach/cybernetic/tier3,
	))
		var/obj/item/organ/organ = allocate(organ_type)
		TEST_ASSERT(!organ.is_volatile_basic_cybernetic(), "[organ_type] не должен наследовать риск взрыва базовой модели")

/// Стандартная и корпоративная помпы используют 3 единицы пентетовой кислоты вместо угля.
/datum/unit_test/standard_blood_pump_reagents/Run()
	for(var/pump_type in list(/obj/item/organ/cyberimp/chest/blood_pump, /obj/item/organ/cyberimp/chest/blood_pump/sec_level))
		var/obj/item/organ/cyberimp/chest/blood_pump/pump = allocate(pump_type)
		TEST_ASSERT_EQUAL(pump.chem_list[/datum/reagent/medicine/pen_acid], 3, "[pump_type] должен содержать 3 единицы пентетовой кислоты")
		TEST_ASSERT_NULL(pump.chem_list[/datum/reagent/medicine/charcoal], "[pump_type] не должен больше содержать уголь")
	var/obj/item/organ/cyberimp/chest/blood_pump/antag/antag_pump = allocate(/obj/item/organ/cyberimp/chest/blood_pump/antag)
	TEST_ASSERT_NULL(antag_pump.chem_list[/datum/reagent/medicine/pen_acid], "Антагонистическая помпа должна сохранить собственный состав")
