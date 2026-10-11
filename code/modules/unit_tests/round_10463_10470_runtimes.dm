/// Извлечённый имплант варпа перестаёт записывать шаги бывшего носителя.
/datum/unit_test/warp_implant_removed_stops_tracking/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	var/obj/item/implant/warp/implant = allocate(/obj/item/implant/warp)
	TEST_ASSERT(implant.implant(host, null, TRUE), "test premise: имплант должен встать в носителя")

	implant.removed(host, TRUE)
	host.forceMove(run_loc_floor_top_right)

	TEST_ASSERT_EQUAL(length(implant.positions), 0, "Извлечённый имплант не должен копить позиции бывшего носителя")

/// Имплант варпа без записанных позиций не телепортирует и не падает.
/datum/unit_test/warp_implant_without_history/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	var/obj/item/implant/warp/implant = allocate(/obj/item/implant/warp)
	TEST_ASSERT(implant.implant(host, null, TRUE), "test premise: имплант должен встать в носителя")
	var/turf/start = get_turf(host)
	implant.clear_positions()
	implant.last_use = world.time - implant.cooldown - 1

	implant.activate()

	TEST_ASSERT_EQUAL(get_turf(host), start, "Без истории позиций варп должен остаться на месте")

/// Мусорный ключ в NTNet-пакете схемы читается как отсутствие ключа.
/datum/unit_test/netdata_garbage_passkey/Run()
	var/datum/netdata/packet = new
	packet.data["encrypted_passkey"] = strtohex(XorEncrypt("not a passkey", SScircuit.cipherkey))

	packet.pre_send(null)

	TEST_ASSERT_NULL(packet.passkey, "Нерасшифровываемый ключ не должен становиться ключом пакета")

/// Урон стамине от блока предметом не в руке уходит в тело целиком.
/datum/unit_test/active_block_stamina_without_hand/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/obj/item/shield/riot/tele/shield = allocate(/obj/item/shield/riot/tele)

	shield.active_block_do_stamina_damage(owner, null, 10, "test", ATTACK_TYPE_MELEE, 0, null, BODY_ZONE_CHEST, 100, list())

	TEST_ASSERT(owner.getStaminaLoss() > 0, "Блок предметом не в руке должен нанести урон стамине")

/// Перезарядка двух револьверов с пояса сохраняет все каморы барабана.
/datum/unit_test/dual_belt_reload_keeps_cylinder/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	var/obj/item/storage/belt/buscadero/belt = allocate(/obj/item/storage/belt/buscadero)
	var/obj/item/gun/ballistic/revolver/Condemnation/main = allocate(/obj/item/gun/ballistic/revolver/Condemnation)
	var/obj/item/gun/ballistic/revolver/Salvation/offhand = allocate(/obj/item/gun/ballistic/revolver/Salvation)
	TEST_ASSERT(user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "test premise: комбинезон должен надеться")
	TEST_ASSERT(user.equip_to_slot_if_possible(belt, ITEM_SLOT_BELT), "test premise: пояс должен надеться")
	for(var/i in 1 to 3)
		new /obj/item/ammo_casing/g45l(belt)
	user.put_in_active_hand(main)
	user.put_in_inactive_hand(offhand)

	main.attack_self(user)

	TEST_ASSERT_EQUAL(length(main.magazine.stored_ammo), main.magazine.max_ammo, "Барабан основного револьвера потерял каморы")
	TEST_ASSERT_EQUAL(length(offhand.magazine.stored_ammo), offhand.magazine.max_ammo, "Барабан второго револьвера потерял каморы")
	TEST_ASSERT_EQUAL(main.magazine.ammo_count(FALSE), 3, "Все три патрона с пояса должны лечь в основной револьвер")
	TEST_ASSERT_EQUAL(offhand.magazine.ammo_count(FALSE), 0, "Второй револьвер после разрядки остаётся пустым")
	for(var/i in 1 to offhand.magazine.max_ammo + 1)
		offhand.magazine.get_round()

/// Диск BEPIS, созданный после исчерпания экспериментальных технологий, выходит пустым.
/datum/unit_test/bepis_disk_without_experimental_nodes
	var/list/saved_nodes

/datum/unit_test/bepis_disk_without_experimental_nodes/Run()
	saved_nodes = SSresearch.techweb_nodes_experimental
	SSresearch.techweb_nodes_experimental = list()

	var/obj/item/disk/tech_disk/major/disk = allocate(/obj/item/disk/tech_disk/major)

	TEST_ASSERT_NOTNULL(disk.stored_research, "Диск должен создаться и без экспериментальных технологий")

/datum/unit_test/bepis_disk_without_experimental_nodes/Destroy()
	if(saved_nodes)
		SSresearch.techweb_nodes_experimental = saved_nodes
	saved_nodes = null
	return ..()

/// Ретровирус, оставшийся без носителя, не падает на шаге стадии.
/datum/unit_test/dnaspread_without_host/Run()
	var/datum/disease/dnaspread/disease = new

	disease.stage_act()

	TEST_ASSERT_NULL(disease.affected_mob, "test premise: у болезни нет носителя")
	qdel(disease)

/// Консоль врат без врат рядом открывает пустые данные.
/datum/unit_test/gateway_console_without_gateway/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/machinery/computer/gateway_control/console = allocate(/obj/machinery/computer/gateway_control)
	TEST_ASSERT_NULL(console.G, "test premise: рядом с консолью нет врат")

	var/list/data = console.ui_data(user)

	TEST_ASSERT_NULL(data["gateway_mapkey"], "Без врат у консоли нет карты портала")

/// Киборг у гнезда не может приклеить в него человека и не падает.
/datum/unit_test/nest_buckle_by_cyborg/Run()
	var/obj/structure/bed/nest/nest = allocate(/obj/structure/bed/nest)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, get_step(run_loc_floor_bottom_left, EAST))

	nest.user_buckle_mob(victim, borg)

	TEST_ASSERT_NULL(victim.buckled, "Киборг без органов ксеноморфа не должен приклеивать к гнезду")

/// Травма «тёмного пассажира» у тела без разума не падает ни при получении, ни при излечении.
/datum/unit_test/dark_passenger_without_mind/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(body.mind, "test premise: у тела нет разума")

	var/datum/brain_trauma/trauma = body.gain_trauma(/datum/brain_trauma/severe/dark_passenger)
	TEST_ASSERT_NOTNULL(trauma, "test premise: травма должна встать")
	body.cure_trauma_type(/datum/brain_trauma/severe/dark_passenger, TRAUMA_RESILIENCE_ABSOLUTE)

	TEST_ASSERT(!body.has_trauma_type(/datum/brain_trauma/severe/dark_passenger), "Травма должна сняться")

/// Противопожарная пена над космосом гаснет, не оставляя лужу плазмы.
/datum/unit_test/firefighting_foam_over_space/Run()
	var/turf/space_turf = get_step(run_loc_floor_bottom_left, NORTH)
	space_turf.ChangeTurf(/turf/open/space)
	var/obj/effect/particle_effect/foam/firefighting/foam = allocate(/obj/effect/particle_effect/foam/firefighting, space_turf)
	foam.absorbed_plasma = 10

	foam.kill_foam()

	TEST_ASSERT_NULL(locate(/obj/effect/decal/cleanable/plasma) in space_turf, "На космосе лужа плазмы не держится")
	space_turf.ChangeTurf(/turf/open/floor/plasteel)

/// Паук, выросший из паучка без матери, кусает ядом своего вида.
/datum/unit_test/spiderling_keeps_species_poison/Run()
	var/obj/structure/spider/spiderling/spiderling = allocate(/obj/structure/spider/spiderling)
	var/turf/nest_turf = get_turf(spiderling)
	spiderling.grow_as = /mob/living/simple_animal/hostile/poison/giant_spider/hunter/viper
	spiderling.amount_grown = 100

	spiderling.process()

	var/mob/living/simple_animal/hostile/poison/giant_spider/hunter/viper/viper = locate() in nest_turf
	TEST_ASSERT_NOTNULL(viper, "test premise: паучок должен вырасти в гадюку")
	TEST_ASSERT_EQUAL(viper.poison_type, /datum/reagent/toxin/venom, "Гадюка из паучка должна кусать своим ядом")
	qdel(viper)

/// Филактерия мёртвого лича добавляет угрозу в подсчёт SSactivity.
/datum/unit_test/phylactery_reports_threat
	var/datum/game_mode/saved_mode

/datum/unit_test/phylactery_reports_threat/Run()
	saved_mode = SSticker.mode
	SSticker.mode = allocate(/datum/game_mode/extended)
	var/mob/living/carbon/human/lich = allocate(/mob/living/carbon/human)
	lich.mind_initialize()
	lich.death()
	var/obj/item/phylactery/phylactery = allocate(/obj/item/phylactery, run_loc_floor_bottom_left, lich.mind)
	var/list/threats = list()

	SEND_SIGNAL(SSactivity, COMSIG_THREAT_CALC, threats)

	TEST_ASSERT_EQUAL(threats["phylactery"], 25, "Филактерия мёртвого лича должна добавить угрозу")
	qdel(phylactery)

/datum/unit_test/phylactery_reports_threat/Destroy()
	. = ..()
	SSticker.mode = saved_mode
	saved_mode = null
