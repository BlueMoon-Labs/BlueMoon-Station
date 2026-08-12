// ===== Базовые поведенческие тесты hostile AI =====
//
// Фиксируют СЕМАНТИКУ общих проков hostile (CanAttack/GiveTarget/
// RetaliateAgainst), которыми пользуется и адаптер-контроллер через делегацию.
//
// ВАЖНО: reserved z, поэтому ничего view()/hearers()-зависимого - все проверки
// через прямые вызовы CanAttack/GiveTarget.

/// Фракционное таргетирование: чужая фракция - цель, своя - нет
/datum/unit_test/hostile_faction_targeting/Run()
	var/mob/living/simple_animal/hostile/carp/hunter = allocate(/mob/living/simple_animal/hostile/carp)
	var/mob/living/simple_animal/hostile/carp/packmate = allocate(/mob/living/simple_animal/hostile/carp)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human)

	TEST_ASSERT(!hunter.CanAttack(packmate), "Carp must not target a same-faction carp")
	TEST_ASSERT(hunter.CanAttack(prey), "Carp must be able to target a live human")

	hunter.GiveTarget(prey)
	TEST_ASSERT_EQUAL(hunter.target, prey, "GiveTarget must store the given target")
	hunter.LoseTarget()

/// attack_same: разрешает бить свою фракцию
/datum/unit_test/hostile_attack_same/Run()
	var/mob/living/simple_animal/hostile/first = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/second = allocate(/mob/living/simple_animal/hostile)

	TEST_ASSERT(!first.CanAttack(second), "Same-faction hostiles must not target each other by default")
	first.attack_same = 1
	TEST_ASSERT(first.CanAttack(second), "attack_same hostile must be able to target its own faction")

/// Персональная обида: RetaliateAgainst делает атакующего валидной целью даже
/// своей фракции (боевой перевыбор цели идёт в контроллер, см. ai_adapter.dm)
/datum/unit_test/hostile_retaliate_grudge/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/attacker = allocate(/mob/living/simple_animal/hostile)
	QDEL_NULL(victim.ai_controller) //чистая бухгалтерия обид без контроллера

	TEST_ASSERT(!victim.CanAttack(attacker), "Sanity: same faction, no grudge yet")

	victim.RetaliateAgainst(attacker)

	TEST_ASSERT(attacker in victim.enemies, "RetaliateAgainst must add the attacker to enemies")
	TEST_ASSERT(victim.foes[attacker], "RetaliateAgainst must mark the attacker as a foe")
	TEST_ASSERT(victim.CanAttack(attacker), "A foe must be attackable despite shared faction")

///A projectile intercepted by a squadmate must not start a same-faction grudge cascade.
/datum/unit_test/hostile_ignores_stray_allied_projectile/Run()
	var/mob/living/simple_animal/hostile/victim = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/projectile/stray = allocate(/obj/item/projectile, get_turf(ally))
	stray.firer = ally
	stray.starting = get_turf(ally)

	victim.bullet_act(stray)

	TEST_ASSERT(!(ally in victim.enemies), "An allied projectile must not add its firer to enemies")
	TEST_ASSERT(!victim.foes[ally], "An allied projectile must not turn its firer into a foe")

	//A direct attack remains an intentional grudge and preserves legacy behavior.
	victim.RetaliateAgainst(ally)
	TEST_ASSERT(victim.foes[ally], "Direct retaliation against an ally must still create a foe")

/// stat_attack: охотник на трупы видит мёртвых, обычный - нет
/datum/unit_test/hostile_stat_attack_dead/Run()
	var/mob/living/simple_animal/hostile/scavenger = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/simple_animal/hostile/regular = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human)
	corpse.death()
	TEST_ASSERT_EQUAL(corpse.stat, DEAD, "Sanity: the human must be dead")

	TEST_ASSERT(!regular.CanAttack(corpse), "A default hostile must ignore corpses")

	scavenger.robust_searching = 1
	scavenger.stat_attack = DEAD
	TEST_ASSERT(scavenger.CanAttack(corpse), "A stat_attack=DEAD hostile must target corpses")

/// wanted_objects: типкэш объектов делает их валидными целями
/datum/unit_test/hostile_wanted_objects/Run()
	var/mob/living/simple_animal/hostile/collector = allocate(/mob/living/simple_animal/hostile)
	var/obj/item/toy/trophy = allocate(/obj/item/toy)

	TEST_ASSERT(!collector.CanAttack(trophy), "An object outside wanted_objects must not be a target")

	collector.wanted_objects = typecacheof(list(/obj/item/toy))
	TEST_ASSERT(collector.CanAttack(trophy), "A wanted_objects match must be a valid target")

/// Гейты валидности: годмод и невидимость исключают цель
/datum/unit_test/hostile_cannot_attack_invisible_godmode/Run()
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/godmoded = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/unseen = allocate(/mob/living/carbon/human)

	godmoded.status_flags |= GODMODE
	TEST_ASSERT(!hunter.CanAttack(godmoded), "A GODMODE mob must not be targetable")

	unseen.invisibility = INVISIBILITY_ABSTRACT
	TEST_ASSERT(!hunter.CanAttack(unseen), "A mob invisible to the hunter must not be targetable")
