/// Данные крови сохраняют доступ к разуму без сильной ссылки, включая last_mind.
/datum/unit_test/blood_mind_reference/Run()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/datum/mind/donor_mind = allocate_mind()
	donor.mind = donor_mind
	donor_mind.current = donor
	var/list/blood_data = donor.get_blood_data()
	var/datum/weakref/mind_ref = blood_data["mind"]
	TEST_ASSERT(istype(mind_ref), "Кровь должна хранить слабую ссылку на разум.")
	TEST_ASSERT_EQUAL(mind_ref.resolve(), donor_mind, "Живой разум доступен из образца крови.")
	donor.mind = null
	donor.last_mind = donor_mind
	blood_data = donor.get_blood_data()
	TEST_ASSERT_EQUAL(blood_data["mind"], mind_ref, "Кровь покинутого тела ссылается на прежний разум.")
	donor.last_mind = null
	blood_data = donor.get_blood_data()
	TEST_ASSERT_NULL(blood_data["mind"], "Без текущего и прежнего разума ссылка отсутствует.")
	qdel(donor_mind)
	TEST_ASSERT_NULL(mind_ref.resolve(), "Образец не возвращает удалённый разум.")
	donor.mind = donor_mind
	blood_data = donor.get_blood_data()
	donor.mind = null
	TEST_ASSERT_NULL(blood_data["mind"], "Новый образец не сохраняет уже удалённый разум.")

/// Переливание и смешивание крови и всех видов жидких останков сохраняют слабую ссылку.
/datum/unit_test/blood_reagent_mind_reference/Run()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/datum/mind/donor_mind = allocate_mind()
	donor.mind = donor_mind
	donor_mind.current = donor
	var/list/samples = list()
	for(var/reagent_type in typesof(/datum/reagent/blood, /datum/reagent/liquidgibs))
		var/obj/item/reagent_containers/glass/beaker/source = allocate(/obj/item/reagent_containers/glass/beaker)
		var/obj/item/reagent_containers/glass/beaker/destination = allocate(/obj/item/reagent_containers/glass/beaker)
		source.reagents.add_reagent(reagent_type, 10, donor.get_blood_data())
		source.reagents.copy_to(destination, 2)
		source.reagents.trans_id_to(destination, reagent_type, 2)
		for(var/obj/item/reagent_containers/glass/beaker/container as anything in list(source, destination))
			var/datum/reagent/sample = container.reagents.has_reagent(reagent_type)
			TEST_ASSERT_NOTNULL(sample, "Образец [reagent_type] сохранился после переливания.")
			var/datum/weakref/mind_ref = sample.data["mind"]
			TEST_ASSERT(istype(mind_ref), "Образец [reagent_type] не должен удерживать разум напрямую.")
			TEST_ASSERT_EQUAL(mind_ref.resolve(), donor_mind, "Образец [reagent_type] сохраняет исходного донора.")
			samples += sample
	qdel(donor_mind)
	for(var/datum/reagent/sample as anything in samples)
		var/datum/weakref/mind_ref = sample.data["mind"]
		TEST_ASSERT_NULL(mind_ref.resolve(), "Образец [sample.type] не возвращает удалённый разум.")

/// Останки получают слабую ссылку на разум из данных исходного тела.
/datum/unit_test/gibs_mind_reference/Run()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/datum/mind/donor_mind = allocate_mind()
	donor.mind = donor_mind
	donor_mind.current = donor
	var/list/samples = list()
	new /obj/effect/gibspawner/human(get_turf(donor), donor)
	for(var/obj/effect/decal/cleanable/blood/gibs/gib in range(3, donor))
		var/datum/reagent/sample = gib.reagents.has_reagent(/datum/reagent/liquidgibs)
		TEST_ASSERT_NOTNULL(sample, "Останки содержат жидкий реагент.")
		var/datum/weakref/mind_ref = sample.data["mind"]
		TEST_ASSERT(istype(mind_ref), "Жидкие останки не удерживают разум напрямую.")
		TEST_ASSERT_EQUAL(mind_ref.resolve(), donor_mind, "Останки сохраняют данные исходного донора.")
		samples += sample
	TEST_ASSERT(length(samples) >= 2, "Созданы несколько отдельных образцов останков.")
	qdel(donor_mind)
	for(var/datum/reagent/sample as anything in samples)
		var/datum/weakref/mind_ref = sample.data["mind"]
		TEST_ASSERT_NULL(mind_ref.resolve(), "Останки не возвращают удалённый разум.")

/// Репликапод сохраняет пригодный образец без удержания разума и отвергает удалённого донора.
/datum/unit_test/replicapod_mind_reference/Run()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/datum/mind/donor_mind = allocate_mind()
	donor.mind = donor_mind
	donor_mind.current = donor
	var/list/blood_data = donor.get_blood_data()
	var/obj/item/seeds/replicapod/seeds = allocate(/obj/item/seeds/replicapod)
	seeds.reagents.add_reagent(/datum/reagent/blood, 1, blood_data)
	TEST_ASSERT(seeds.contains_sample, "Репликапод принимает пригодную кровь.")
	TEST_ASSERT_EQUAL(seeds.mind_ref?.resolve(), donor_mind, "Для клонирования доступен исходный разум.")
	TEST_ASSERT_EQUAL(seeds.realName, donor.real_name, "Имя донора сохранено.")
	TEST_ASSERT_EQUAL(seeds.blood_type, donor.dna.blood_type, "Группа крови донора сохранена.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human)
	donor_mind.transfer_to(new_body)
	TEST_ASSERT_EQUAL(seeds.mind_ref?.resolve(), donor_mind, "Смена тела не меняет разум в образце.")
	qdel(donor_mind)
	TEST_ASSERT_NULL(seeds.mind_ref?.resolve(), "Семена не возвращают удалённый разум.")
	var/obj/item/seeds/replicapod/empty_seeds = allocate(/obj/item/seeds/replicapod)
	empty_seeds.reagents.add_reagent(/datum/reagent/blood, 1, blood_data)
	TEST_ASSERT(!empty_seeds.contains_sample, "Кровь удалённого донора не принимается для клонирования.")
	TEST_ASSERT_NULL(empty_seeds.mind_ref, "Отклонённый образец не привязывает разум.")

/// Репликапод по-прежнему отклоняет непригодную для клонирования кровь живого донора.
/datum/unit_test/replicapod_uncloneable_sample/Run()
	var/mob/living/carbon/human/donor = allocate(/mob/living/carbon/human)
	var/datum/mind/donor_mind = allocate_mind()
	donor.mind = donor_mind
	donor_mind.current = donor
	donor.suiciding = TRUE
	var/obj/item/seeds/replicapod/seeds = allocate(/obj/item/seeds/replicapod)
	seeds.reagents.add_reagent(/datum/reagent/blood, 1, donor.get_blood_data())
	TEST_ASSERT(!seeds.contains_sample, "Непригодный для клонирования образец отклонён.")
	TEST_ASSERT_NULL(seeds.mind_ref, "Отклонённый образец не привязывает разум.")
