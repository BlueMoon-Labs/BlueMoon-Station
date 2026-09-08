/// Повторная установка ДНК-замка не должна менять описание шасси, в том числе после применения emag.
/datum/unit_test/mecha_dna_lock_description/proc/operate_lock(obj/vehicle/sealed/mecha/mech, list/href_list)
	mech.Topic(null, href_list)

/datum/unit_test/mecha_dna_lock_description/Run()
	var/obj/vehicle/sealed/mecha/working/ripley/mech = allocate(/obj/vehicle/sealed/mecha/working/ripley)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human)
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	mech.desc = "Custom chassis description."
	var/original_description = mech.desc
	for(var/cycle in 1 to 2)
		pilot.name = "Test Pilot [cycle]"
		world.PushUsr(pilot, CALLBACK(src, PROC_REF(operate_lock)), mech, list("dna_lock" = "1"))
		TEST_ASSERT_EQUAL(mech.dna_lock, pilot.dna.unique_enzymes, "The pilot must actually set the lock")
		TEST_ASSERT_EQUAL(mech.dna_lock_name, pilot.name, "The lock must remember its owner's name")
		var/list/locked_examine = mech.examine(pilot)
		var/lock_lines = 0
		for(var/line in locked_examine)
			if(findtext(line, "Этот мех заблокирован ДНК"))
				lock_lines++
		TEST_ASSERT_EQUAL(lock_lines, 1, "Examine must contain exactly one DNA lock notice")
		TEST_ASSERT_EQUAL(mech.desc, original_description, "Locking must not edit desc")
		world.PushUsr(pilot, CALLBACK(src, PROC_REF(operate_lock)), mech, list("reset_dna" = "1"))
		TEST_ASSERT_NULL(mech.dna_lock, "Reset must clear the lock")
		TEST_ASSERT_NULL(mech.dna_lock_name, "Reset must clear the display name")
		TEST_ASSERT(!findtext(jointext(mech.examine(pilot), "\n"), "Этот мех заблокирован ДНК"), "Unlocked examine must not show a stale lock")
	world.PushUsr(pilot, CALLBACK(src, PROC_REF(operate_lock)), mech, list("dna_lock" = "1"))
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	mech.emag_act(pilot, emag)
	TEST_ASSERT_NULL(mech.dna_lock_name, "Emag must also clear the display name")
	TEST_ASSERT_EQUAL(mech.desc, original_description, "Emag must preserve unrelated custom descriptions")

/datum/unit_test/portable_turret_relocation/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	for(var/turret_type in list(/obj/machinery/porta_turret, /obj/machinery/porta_turret/syndicate, /obj/machinery/porta_turret/syndicate/energy))
		var/obj/machinery/porta_turret/turret = allocate(turret_type)
		// Сначала ждём завершения начальной анимации подъёма турелей без кожуха.
		sleep(1 SECONDS)
		turret.toggle_on(FALSE)
		sleep(1 SECONDS)
		if(!turret.has_cover)
			TEST_ASSERT_EQUAL(turret.invisibility, 0, "An uncovered turret must remain visible when turned off")
		for(var/cycle in 1 to 2)
			turret.attackby(wrench, user)
			TEST_ASSERT(!turret.anchored, "The disabled turret must unanchor")
			TEST_ASSERT_NULL(turret.cover, "Unanchoring must clear the old cover reference")
			turret.forceMove(get_step(get_turf(turret), EAST))
			turret.attackby(wrench, user)
			TEST_ASSERT(turret.anchored, "The relocated turret must anchor")
			if(turret.has_cover)
				TEST_ASSERT_NOTNULL(turret.cover, "Covered turrets must rebuild their cover")
				TEST_ASSERT_EQUAL(get_turf(turret.cover), get_turf(turret), "The cover must follow relocation")
			else
				TEST_ASSERT_EQUAL(turret.invisibility, 0, "Anchoring an uncovered turret must not make it invisible")

/datum/unit_test/rebar_crossbow_ammo_lifecycle/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	for(var/crossbow_type in list(/obj/item/gun/ballistic/rebarxbow, /obj/item/gun/ballistic/rebarxbow/forced, /obj/item/gun/ballistic/rebarxbow/syndie))
		var/obj/item/gun/ballistic/rebarxbow/crossbow = allocate(crossbow_type)
		if(istype(crossbow, /obj/item/gun/ballistic/rebarxbow/forced))
			var/obj/item/gun/ballistic/rebarxbow/forced/forced_crossbow = crossbow
			forced_crossbow.can_misfire = FALSE
		TEST_ASSERT_NOTNULL(crossbow.chambered, "Initialization must not orphan the first bolt")
		TEST_ASSERT_EQUAL(crossbow.magazine.ammo_count() + 1, crossbow.magazine.max_ammo, "Initialization must retain all supplied bolts")
		var/obj/item/ammo_casing/bolt = crossbow.chambered
		crossbow.draw_time = 0
		crossbow.shoot_with_empty_chamber(user)
		TEST_ASSERT(!crossbow.bowstring_loose, "Trying to fire a loaded, loose crossbow must draw its bowstring")
		crossbow.rack(user)
		TEST_ASSERT_EQUAL(bolt.loc, get_turf(crossbow), "Loosening must drop the live bolt on the floor")
		TEST_ASSERT_NOTNULL(bolt.BB, "The ejected bolt must remain usable")
		TEST_ASSERT_NULL(crossbow.chambered, "The chamber must be clear after unloading")
		// Заряжаем тот же болт и проверяем настоящий выстрел вместе с вызовом process_chamber.
		bolt.forceMove(crossbow)
		crossbow.chambered = bolt
		crossbow.bowstring_loose = FALSE
		var/reserve_ammo = crossbow.magazine.ammo_count()
		TEST_ASSERT(crossbow.do_fire(run_loc_floor_top_right, user, FALSE), "The reloaded bolt must fire")
		TEST_ASSERT(crossbow.bowstring_loose, "Firing must loosen the bowstring")
		TEST_ASSERT_NULL(crossbow.chambered, "Firing must leave the chamber empty until the next draw")
		TEST_ASSERT(QDELETED(bolt), "The spent casing must not leak inside the crossbow")
		TEST_ASSERT_EQUAL(crossbow.magazine.ammo_count(), reserve_ammo, "Firing must not consume or seat a second bolt")

/datum/unit_test/roasted_peanut_grinding/Run()
	var/obj/machinery/reagentgrinder/grinder = allocate(/obj/machinery/reagentgrinder)
	var/obj/item/reagent_containers/food/snacks/roasted_peanuts/peanuts = allocate(/obj/item/reagent_containers/food/snacks/roasted_peanuts, grinder)
	grinder.holdingitems += peanuts
	grinder.grind_item(peanuts)
	TEST_ASSERT(abs(grinder.beaker.reagents.get_reagent_amount(/datum/reagent/consumable/peanut_butter) - 3) < 0.001, "Grinding roasted peanuts must produce 3 units of peanut butter")
	TEST_ASSERT(QDELETED(peanuts), "Grinding must consume the peanuts")
	peanuts = allocate(/obj/item/reagent_containers/food/snacks/roasted_peanuts, grinder)
	grinder.holdingitems += peanuts
	grinder.juice_item(peanuts)
	TEST_ASSERT(abs(grinder.beaker.reagents.get_reagent_amount(/datum/reagent/consumable/peanut_butter) - 6) < 0.001, "The existing juicing recipe must remain usable")

// Уникальный подтип позволяет проверять наличие предмета независимо от карты и экипировки игроков.
/obj/item/clothing/mask/gas/mime/unit_test_theft

/datum/unit_test/theft_target_availability/Run()
	var/datum/objective_item/steal/traitor/mime_mask/objective = allocate(/datum/objective_item/steal/traitor/mime_mask)
	objective.targetitem = /obj/item/clothing/mask/gas/mime/unit_test_theft
	TEST_ASSERT(!objective.ExtraCheck(), "A missing job item must not be offered for theft")
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	TEST_ASSERT(length(station_levels), "The fixture needs a station z-level")
	var/turf/station_turf = locate(1, 1, station_levels[1])
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, station_turf)
	var/obj/item/clothing/mask/gas/mime/unit_test_theft/mask = allocate(/obj/item/clothing/mask/gas/mime/unit_test_theft, bag)
	TEST_ASSERT(objective.ExtraCheck(), "An actual item inside station storage must be eligible without its job")
	mask.moveToNullspace()
	TEST_ASSERT(!objective.ExtraCheck(), "An inaccessible nullspace item must not satisfy availability")
	var/list/centcom_levels = SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	TEST_ASSERT(length(centcom_levels), "The fixture needs a Central Command z-level")
	mask.forceMove(locate(1, 1, centcom_levels[1]))
	TEST_ASSERT(!objective.ExtraCheck(), "Equipment stored at Central Command must not make a station theft available")
	mask.forceMove(bag)
	TEST_ASSERT(objective.ExtraCheck(), "A later arrival must become eligible without rebuilding the objective pool")
	qdel(mask)
	TEST_ASSERT(!objective.ExtraCheck(), "A deleted item must stop satisfying availability")

/datum/unit_test/mime_pda_and_lipstick
	var/saved_debug_signal

/datum/unit_test/mime_pda_and_lipstick/Destroy()
	if(!isnull(saved_debug_signal))
		SSnetworks.ntnet_debug_global_signal = saved_debug_signal
	return ..()

/datum/unit_test/mime_pda_and_lipstick/Run()
	var/mob/living/carbon/human/mime = allocate(/mob/living/carbon/human)
	mime.mind_initialize()
	mime.mind.miming = TRUE
	var/obj/item/modular_computer/pda/mime/source = allocate(/obj/item/modular_computer/pda/mime)
	var/obj/item/modular_computer/pda/target = allocate(/obj/item/modular_computer/pda)
	var/datum/computer_file/program/messenger/source_app = locate(/datum/computer_file/program/messenger) in source.get_all_files()
	var/datum/computer_file/program/messenger/target_app = locate(/datum/computer_file/program/messenger) in target.get_all_files()
	TEST_ASSERT(source_app?.mime_mode, "The mime PDA must use its intentional emoji-only mode")
	TEST_ASSERT_NOTNULL(target_app, "The target PDA needs messenger")
	// Открытие мессенджера и выбор получателя регистрируют приложения, установленные на HDD.
	add_messenger(source_app)
	add_messenger(target_app)
	var/list/emojis = get_emoji_list()
	TEST_ASSERT(length(emojis), "At least one emoji must be available")
	TEST_ASSERT(length(source_app.sanitize_pda_message(":[emojis[1]]:", mime)), "A miming user must be able to compose emoji messages")
	// Используем тестовый режим NTNet, чтобы не зависеть от оборудования связи на карте.
	saved_debug_signal = SSnetworks.ntnet_debug_global_signal
	SSnetworks.ntnet_debug_global_signal = TRUE
	var/datum/picture/photo = allocate(/datum/picture)
	photo.picture_image = icon('icons/obj/items_and_weapons.dmi', "photo")
	source.picture = photo
	TEST_ASSERT(source_app.send_message(mime, "", list(target_app)), "A miming user must be able to send a photo without text")
	TEST_ASSERT_NULL(source.picture, "The photo must be consumed as an attachment")
	var/obj/item/cartridge/virus/mime/disk = source.inserted_disk
	TEST_ASSERT(istype(disk), "The mime PDA must have its virus cartridge")
	var/initial_charges = disk.charges
	disk.send_virus(source, target, mime, "")
	TEST_ASSERT_EQUAL(disk.charges, initial_charges - 1, "The virus must work without a text message")
	TEST_ASSERT(target_app.alert_silenced, "The virus must silence the recipient PDA")
	var/obj/item/projectile/kiss/mime/kiss = allocate(/obj/item/projectile/kiss/mime)
	kiss.suppressed = TRUE
	kiss.harmless_on_hit(mime)
	TEST_ASSERT_EQUAL(mime.reagents.get_reagent_amount(/datum/reagent/toxin/mutetoxin), 1, "The mime air kiss must deliver its configured one-unit dose")
