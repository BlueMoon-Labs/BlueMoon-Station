/// Отзыв питомца в капсулу отпускает всех, кто был у него внутри, и удаляет питомца через qdel, а не del().
/datum/unit_test/pet_capsule_recall_releases_prey
	requires_full_map = FALSE

/datum/unit_test/pet_capsule_recall_releases_prey/Run()
	var/turf/pet_turf = run_loc_floor_bottom_left
	var/obj/item/pet_capsule/capsule = allocate(/obj/item/pet_capsule, pet_turf)
	capsule.selected_pet = /mob/living/simple_animal/hostile/carp/pet_carp
	capsule.pet_picked = TRUE
	capsule.pet_capsule_triggered(pet_turf)

	var/mob/living/simple_animal/pet = capsule.stored_pet
	TEST_ASSERT_NOTNULL(pet, "бросок капсулы обязан выпустить питомца")
	TEST_ASSERT(capsule.open, "после броска капсула открыта")

	pet.lazy_init_belly()
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, pet_turf)
	prey.forceMove(pet.vore_selected)
	var/mob/living/carbon/human/held = allocate(/mob/living/carbon/human, pet_turf)
	held.forceMove(pet)

	capsule.pet_capsule_triggered(pet_turf)

	TEST_ASSERT(!capsule.open, "после отзыва капсула закрыта")
	TEST_ASSERT_NULL(capsule.stored_pet, "ссылка на отозванного питомца обязана обнулиться")
	TEST_ASSERT(QDELETED(pet), "питомец обязан уйти через qdel")
	TEST_ASSERT_EQUAL(prey.loc, pet_turf, "добыча из живота обязана оказаться на турфе питомца")
	TEST_ASSERT_EQUAL(held.loc, pet_turf, "моб из contents питомца обязан оказаться на турфе питомца")
	TEST_ASSERT(!QDELETED(prey), "добыча не должна удаляться вместе с питомцем")
	TEST_ASSERT(prey in GLOB.mob_list, "добыча обязана остаться в mob_list")

/// process() элемента dusts_on_catatonia переживает null в attached_mobs и вычищает его.
/datum/unit_test/dusts_on_catatonia_null_tolerance
	requires_full_map = FALSE

/datum/unit_test/dusts_on_catatonia_null_tolerance/Run()
	var/mob/living/carbon/human/visitor = allocate(/mob/living/carbon/human)
	visitor.key = "unit_test_dusts_visitor"
	visitor.AddElement(/datum/element/dusts_on_catatonia)
	var/datum/element/dusts_on_catatonia/element = SSdcs.GetElement(list(/datum/element/dusts_on_catatonia))
	TEST_ASSERT(visitor in element.attached_mobs, "элемент обязан числить моба после Attach")

	element.attached_mobs += null
	TEST_ASSERT(null in element.attached_mobs, "тест обязан подложить null в список")
	element.process()

	TEST_ASSERT(!(null in element.attached_mobs), "process обязан вычистить null из attached_mobs")
	TEST_ASSERT(visitor in element.attached_mobs, "живой моб с ключом обязан остаться в списке")
	visitor.RemoveElement(/datum/element/dusts_on_catatonia)

	element.attached_mobs += null
	START_PROCESSING(SSprocessing, element)
	element.process()
	TEST_ASSERT(!element.attached_mobs.len, "список из одного null обязан опустеть")
	TEST_ASSERT(!(element in SSprocessing.processing), "пустой после чистки элемент обязан выйти из SSprocessing")

/// Открытая капсула с уже удалённым питомцем закрывается и сбрасывает ссылку без рантайма.
/datum/unit_test/pet_capsule_recall_deleted_pet
	requires_full_map = FALSE

/datum/unit_test/pet_capsule_recall_deleted_pet/Run()
	var/turf/pet_turf = run_loc_floor_bottom_left
	var/obj/item/pet_capsule/capsule = allocate(/obj/item/pet_capsule, pet_turf)
	capsule.selected_pet = /mob/living/simple_animal/hostile/carp/pet_carp
	capsule.pet_picked = TRUE
	capsule.pet_capsule_triggered(pet_turf)

	var/mob/living/simple_animal/pet = capsule.stored_pet
	TEST_ASSERT_NOTNULL(pet, "бросок капсулы обязан выпустить питомца")
	qdel(pet)
	TEST_ASSERT(QDELETED(pet), "предпосылка: питомец удалён до отзыва")

	capsule.pet_capsule_triggered(pet_turf)

	TEST_ASSERT(!capsule.open, "капсула без питомца обязана закрыться")
	TEST_ASSERT_NULL(capsule.stored_pet, "ссылка на удалённого питомца обязана обнулиться")

	capsule.stored_pet = pet
	capsule.recall_pet()
	TEST_ASSERT_NULL(capsule.stored_pet, "прямой отзыв удалённого питомца обязан обнулить ссылку")

/// get_all_ghost_role_eligible переживает null в GLOB.ghost_eligible_mobs и вычищает его из обоих списков.
/datum/unit_test/ghost_role_eligible_null_tolerance
	requires_full_map = FALSE

/datum/unit_test/ghost_role_eligible_null_tolerance/Run()
	var/mob/living/carbon/human/candidate = allocate(/mob/living/carbon/human)
	GLOB.ghost_eligible_mobs |= candidate
	GLOB.ghost_eligible_mobs_priority |= candidate
	GLOB.ghost_eligible_mobs += null
	GLOB.ghost_eligible_mobs_priority += null

	var/list/found = get_all_ghost_role_eligible(TRUE)
	TEST_ASSERT(candidate in found, "живой кандидат обязан попасть в выборку")
	TEST_ASSERT(!(null in found), "null не должен попадать в выборку")
	TEST_ASSERT(!(null in GLOB.ghost_eligible_mobs), "null обязан быть вычищен из ghost_eligible_mobs")
	TEST_ASSERT(!(null in GLOB.ghost_eligible_mobs_priority), "null обязан быть вычищен из ghost_eligible_mobs_priority")

	var/list/priority = get_all_ghost_role_eligible(TRUE, priority_only = TRUE)
	TEST_ASSERT(candidate in priority, "приоритетный список тоже обязан отдавать кандидата")

	GLOB.ghost_eligible_mobs -= candidate
	GLOB.ghost_eligible_mobs_priority -= candidate
