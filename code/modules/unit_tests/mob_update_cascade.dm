/// Tests for the cost of the carbon health-update cascade.
///
/// `updatehealth()` -> `update_stat()` -> everything is the hottest mob path on
/// the server (12.9% of all Master Controller time in round 9800, at ~112 calls
/// per second). These tests pin down which parts of that cascade are allowed to
/// run on every single health change and which are not.

/// Human that counts how often the expensive tail procs are re-entered, so the
/// tests can assert on call counts instead of on side effects that need a client
/// to observe.
/mob/living/carbon/human/cascade_probe
	var/mobility_updates = 0
	var/health_updates = 0
	var/filter_rebuilds = 0
	var/body_updates = 0
	var/movespeed_updates = 0
	///Пересборки мутантных частей тела, которые РЕАЛЬНО дошли до species-процa
	///(отложенные во время regenerate_icons сюда не попадают).
	var/mutant_bodypart_rebuilds = 0

/mob/living/carbon/human/cascade_probe/update_mobility()
	mobility_updates++
	return ..()

/mob/living/carbon/human/cascade_probe/update_mutant_bodyparts(block_recursive_calls = FALSE)
	if(!defer_mutant_bodyparts_update)
		mutant_bodypart_rebuilds++
	return ..()

/mob/living/carbon/human/cascade_probe/updatehealth()
	health_updates++
	return ..()

/mob/living/carbon/human/cascade_probe/update_filters()
	filter_rebuilds++
	return ..()

/mob/living/carbon/human/cascade_probe/update_body()
	body_updates++
	return ..()

/mob/living/carbon/human/cascade_probe/update_movespeed(updating = TRUE)
	movespeed_updates++
	return ..()

/mob/living/carbon/human/cascade_probe/proc/reset_counters()
	mobility_updates = 0
	health_updates = 0
	filter_rebuilds = 0
	body_updates = 0
	movespeed_updates = 0
	mutant_bodypart_rebuilds = 0

/// Plain atom that counts filter-list rebuilds. `filters[n]` hands back a fresh
/// wrapper on every read, so filter identity cannot be compared — count the
/// rebuilds instead.
/obj/effect/filter_rebuild_probe
	var/rebuilds = 0

/obj/effect/filter_rebuild_probe/update_filters()
	rebuilds++
	return ..()

// -----------------------------------------------------------------------------
// update_stat() used to recompute mobility on every updatehealth(). Mobility
// only depends on `stat` at that point in the proc — every other input (stuns,
// grabs, resting, limbs, traits) refreshes mobility from its own setter — so a
// health change that leaves `stat` alone must not pay for it.
// -----------------------------------------------------------------------------

/datum/unit_test/update_stat_skips_mobility_when_stat_unchanged

/datum/unit_test/update_stat_skips_mobility_when_stat_unchanged/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)

	// Settle any transitions left over from spawning.
	patient.updatehealth()
	patient.reset_counters()

	patient.updatehealth()
	patient.updatehealth()
	patient.updatehealth()

	TEST_ASSERT_EQUAL(patient.mobility_updates, 0, "A health change that leaves stat alone must not recompute mobility")

/datum/unit_test/update_stat_refreshes_mobility_when_stat_changes

/datum/unit_test/update_stat_refreshes_mobility_when_stat_changes/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)

	patient.updatehealth()
	TEST_ASSERT_EQUAL(patient.stat, CONSCIOUS, "Test human should start conscious")
	patient.reset_counters()

	// update_stat() knocks a carbon out above 50 oxyloss.
	patient.adjustOxyLoss(60)

	TEST_ASSERT_EQUAL(patient.stat, UNCONSCIOUS, "Sanity: 60 oxyloss should have knocked the mob out")
	TEST_ASSERT(patient.mobility_updates > 0, "A stat transition must still refresh mobility")

// -----------------------------------------------------------------------------
// Dropping the per-updatehealth refresh means nothing re-evaluates mobility for
// state that changes without calling update_mobility itself. Life keeps a
// once-per-tick catch-all so such state can never get stuck for longer than one
// Life cycle.
// -----------------------------------------------------------------------------

/datum/unit_test/life_refreshes_mobility_as_catch_all

/datum/unit_test/life_refreshes_mobility_as_catch_all/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)

	patient.updatehealth()
	patient.reset_counters()

	patient.BiologicalLife(2 SECONDS, 1)

	TEST_ASSERT(patient.mobility_updates > 0, "Life must refresh mobility once per tick as a catch-all")

// -----------------------------------------------------------------------------
// heal_damage() ran the whole owner.updatehealth() cascade even when it changed
// no damage value at all — the common case for regeneration ticking against a
// limb that is already whole.
// -----------------------------------------------------------------------------

/datum/unit_test/heal_damage_skips_cascade_when_nothing_changed

/datum/unit_test/heal_damage_skips_cascade_when_nothing_changed/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	var/obj/item/bodypart/chest = patient.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(chest, "Test human should have a chest")
	TEST_ASSERT_EQUAL(chest.brute_dam, 0, "Sanity: a fresh chest should be undamaged")

	patient.updatehealth()
	patient.reset_counters()

	chest.heal_damage(brute = 10, burn = 10, stamina = 10, only_organic = FALSE)

	TEST_ASSERT_EQUAL(patient.health_updates, 0, "Healing an already-whole limb must not run the health cascade")

/datum/unit_test/heal_damage_runs_cascade_when_damage_changes

/datum/unit_test/heal_damage_runs_cascade_when_damage_changes/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	var/obj/item/bodypart/chest = patient.get_bodypart(BODY_ZONE_CHEST)

	chest.receive_damage(brute = 20, wound_bonus = CANT_WOUND, can_dismember = FALSE)
	patient.updatehealth()
	patient.reset_counters()

	chest.heal_damage(brute = 5, only_organic = FALSE)

	TEST_ASSERT_EQUAL(chest.brute_dam, 15, "Healing a damaged limb must still apply the heal")
	TEST_ASSERT_EQUAL(patient.health_updates, 1, "A heal that changed damage must still run the cascade exactly once")
	TEST_ASSERT_EQUAL(patient.health, patient.maxHealth - 15, "Mob health must follow the healed limb")

// -----------------------------------------------------------------------------
// update_crit_status() tore down and re-added the hardcrit screen filter on
// every single update_stat(), which rebuilds the atom's whole filter list.
// -----------------------------------------------------------------------------

/datum/unit_test/crit_filter_not_rebuilt_when_state_unchanged

/datum/unit_test/crit_filter_not_rebuilt_when_state_unchanged/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)

	// Healthy: no hardcrit filter, and repeating the check must not create one.
	patient.update_crit_status()
	TEST_ASSERT_NULL(patient.get_filter("hardcrit"), "A healthy mob should have no hardcrit filter")
	patient.reset_counters()
	patient.update_crit_status()
	TEST_ASSERT_EQUAL(patient.filter_rebuilds, 0, "A healthy mob must not rebuild its filters on every crit check")

	// Drop into crit and let the filter appear. Oxyloss is used because it maps
	// straight onto health, without each limb's body_damage_coeff in the way.
	patient.adjustOxyLoss(patient.maxHealth - patient.crit_threshold + 5)
	TEST_ASSERT(patient.health <= patient.crit_threshold, "Sanity: the mob should be past its crit threshold")
	TEST_ASSERT_NOTNULL(patient.get_filter("hardcrit"), "A mob past crit_threshold should have the hardcrit filter")

	// Re-running the check with the state unchanged must leave the filter alone.
	patient.reset_counters()
	patient.update_crit_status()
	patient.update_crit_status()
	TEST_ASSERT_EQUAL(patient.filter_rebuilds, 0, "An unchanged crit state must not rebuild the hardcrit filter")
	TEST_ASSERT_NOTNULL(patient.get_filter("hardcrit"), "The hardcrit filter must survive the repeated checks")

/datum/unit_test/remove_filter_no_op_leaves_filters_alone

/datum/unit_test/remove_filter_no_op_leaves_filters_alone/Run()
	var/obj/effect/filter_rebuild_probe/target = allocate(/obj/effect/filter_rebuild_probe)
	target.add_filter("keepme", 1, list("type" = "outline", "size" = 1, "color" = "#FFFFFF"))
	TEST_ASSERT_NOTNULL(target.get_filter("keepme"), "Sanity: the filter should have been added")

	target.rebuilds = 0
	target.remove_filter("never_added")
	TEST_ASSERT_EQUAL(target.rebuilds, 0, "Removing a filter that was never added must not rebuild the filter list")
	TEST_ASSERT_NOTNULL(target.get_filter("keepme"), "The existing filter must survive a no-op removal")

	// Negative control: the counter really does see rebuilds.
	target.remove_filter("keepme")
	TEST_ASSERT_EQUAL(target.rebuilds, 1, "Removing a filter that exists must still rebuild the filter list")
	TEST_ASSERT_NULL(target.get_filter("keepme"), "A real removal must actually drop the filter")

// -----------------------------------------------------------------------------
// Nanite healing programs walked every damaged limb and let each limb run its
// own full updatehealth(). One aggregate update at the end is equivalent and
// costs a fraction — /mob/living/carbon/heal_overall_damage already works this
// way, the nanite programs did not.
// -----------------------------------------------------------------------------

/datum/unit_test/nanite_regeneration_updates_health_once

/datum/unit_test/nanite_regeneration_updates_health_once/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)

	// Damage several limbs so the program has more than one to walk.
	var/list/hurt_zones = list(BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG)
	for(var/zone in hurt_zones)
		var/obj/item/bodypart/limb = patient.get_bodypart(zone)
		limb.receive_damage(brute = 10, wound_bonus = CANT_WOUND, can_dismember = FALSE)

	patient.updatehealth()
	patient.reset_counters()

	var/datum/nanite_program/regenerative/program = new
	program.host_mob = patient
	program.active_effect()

	TEST_ASSERT_EQUAL(patient.health_updates, 1, "Nanite regeneration must run the health cascade once, not once per limb")

	for(var/zone in hurt_zones)
		var/obj/item/bodypart/limb = patient.get_bodypart(zone)
		TEST_ASSERT(limb.brute_dam < 10, "Every damaged limb must still be healed ([zone] is still at [limb.brute_dam])")

	// The single aggregate update must leave health consistent with the limbs.
	var/expected_health = patient.maxHealth
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		expected_health -= (limb.brute_dam + limb.burn_dam) * limb.body_damage_coeff
	TEST_ASSERT_EQUAL(patient.health, round(expected_health, DAMAGE_PRECISION), "Health must match the limbs after the aggregate update")

/datum/unit_test/nanite_aggressive_replication_still_hurts

/datum/unit_test/nanite_aggressive_replication_still_hurts/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	var/datum/component/nanites/colony = patient.AddComponent(/datum/component/nanites, 200)

	var/datum/nanite_program/aggressive_replication/program = new
	program.host_mob = patient
	program.nanites = colony

	var/health_before = patient.health
	var/volume_before = colony.nanite_volume
	program.active_effect()

	TEST_ASSERT(patient.health < health_before, "Aggressive Replication must still damage its host")
	TEST_ASSERT(colony.nanite_volume > volume_before, "Aggressive Replication must still grow the colony")

// -----------------------------------------------------------------------------
// Nanite HUD bookkeeping runs from the component's Destroy(), which for a dying
// mob happens after /mob/Destroy() has already dropped hud_list. Round 9800's
// runtime log is full of the resulting "bad index".
// -----------------------------------------------------------------------------

/datum/unit_test/nanite_hud_setters_survive_lost_hud_list

/datum/unit_test/nanite_hud_setters_survive_lost_hud_list/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	var/datum/component/nanites/colony = patient.AddComponent(/datum/component/nanites, 50)

	var/bar_before = colony.last_nanite_percent_bar

	// Exactly the state /mob/Destroy() leaves behind before components tear down.
	patient.hud_list = null

	patient.hud_set_nanite_indicator()
	colony.set_nanite_bar()
	colony.set_nanite_bar(remove = TRUE)

	// Reaching this line at all means none of the three calls threw; the value
	// check pins that they bailed out rather than half-applying.
	TEST_ASSERT_EQUAL(colony.last_nanite_percent_bar, bar_before, "The nanite HUD setters must bail out when hud_list is already gone")

// -----------------------------------------------------------------------------
// cure_husk() on a mob that is not husked used to run the full update_body()
// (plus update_hair() on humans) and report success. Round 9803's profile caught
// the resulting dead loop: a dead skeleton with heavy burn damage runs
// updatehealth() -> become_husk("burn") -> (skeletons cannot husk) -> cure_husk()
// on every single health change - 3869 body rebuilds in 2.6 minutes, 12% of all
// SSmobs time. Curing a state the mob is not in must cost nothing.
// -----------------------------------------------------------------------------

/datum/unit_test/cure_husk_on_unhusked_mob_is_free

/datum/unit_test/cure_husk_on_unhusked_mob_is_free/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)

	patient.reset_counters()
	TEST_ASSERT(!patient.cure_husk("burn"), "cure_husk() on a mob that was never husked must report no change")
	TEST_ASSERT_EQUAL(patient.body_updates, 0, "cure_husk() on a mob that was never husked must not rebuild the body")

	patient.become_husk("burn")
	TEST_ASSERT(HAS_TRAIT(patient, TRAIT_HUSK), "Sanity: become_husk must husk a plain human")

	// A husk held by two sources only clears when the last one is gone, and the
	// no-op guard must not short-circuit that.
	patient.become_husk(CHANGELING_DRAIN)
	patient.reset_counters()
	TEST_ASSERT(!patient.cure_husk("burn"), "Clearing one of two husk sources must not report a cure")
	TEST_ASSERT(HAS_TRAIT(patient, TRAIT_HUSK), "Clearing one of two husk sources must leave the mob husked")
	TEST_ASSERT_EQUAL(patient.body_updates, 0, "Clearing one of two husk sources must not rebuild the body")

	patient.reset_counters()
	TEST_ASSERT(patient.cure_husk(CHANGELING_DRAIN), "Clearing the last husk source must report a cure")
	TEST_ASSERT(!HAS_TRAIT(patient, TRAIT_HUSK), "Clearing the last husk source must un-husk the mob")
	TEST_ASSERT(!HAS_TRAIT(patient, TRAIT_DISFIGURED), "Clearing the last husk source must clear the husk disfigurement")
	TEST_ASSERT_EQUAL(patient.body_updates, 1, "Clearing the last husk source must rebuild the body exactly once")

/// The production shape of the same loop: skeletons refuse to husk, so every
/// updatehealth() on a burned skeleton corpse re-enters become_husk().
/datum/unit_test/dead_skeleton_health_updates_do_not_rebuild_body

/datum/unit_test/dead_skeleton_health_updates_do_not_rebuild_body/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	patient.set_species(/datum/species/skeleton)

	patient.reset_counters()
	patient.become_husk("burn")
	patient.become_husk("burn")
	patient.become_husk("burn")

	TEST_ASSERT(!HAS_TRAIT(patient, TRAIT_HUSK), "Sanity: a skeleton must not become a husk")
	TEST_ASSERT_EQUAL(patient.body_updates, 0, "become_husk() on a skeleton must not rebuild the body on every call")

// -----------------------------------------------------------------------------
// update_mobility() runs once per Life tick as a catch-all, and its autostand
// branch queued a timer for every standing player with the preference on -
// ~70 throwaway timers every two seconds on a full server. resist_a_rest()
// returns FALSE immediately unless the mob is actually resting, so the timer
// only ever had work to do in that case.
// -----------------------------------------------------------------------------

/datum/unit_test/autostand_does_not_queue_timers_while_standing

/datum/unit_test/autostand_does_not_queue_timers_while_standing/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	patient.combat_flags &= ~COMBAT_FLAG_INTENTIONALLY_RESTING

	// No client means no autostand preference, so drive the branch's own gate
	// instead: standing must skip it, resting must not.
	TEST_ASSERT(!patient.resting, "Sanity: a freshly spawned human must be standing")
	TEST_ASSERT(CHECK_MOBILITY(patient, MOBILITY_MOVE), "Sanity: a freshly spawned human must be able to move")
	TEST_ASSERT(!patient.resist_a_rest(TRUE), "resist_a_rest() on a standing mob must be a no-op, so scheduling it is pure waste")

	patient.set_resting(TRUE, TRUE)
	TEST_ASSERT(patient.resting, "Sanity: set_resting must put the mob down")
	TEST_ASSERT(patient.resist_a_rest(TRUE, TRUE), "resist_a_rest() must still stand a resting mob back up")
	TEST_ASSERT(!patient.resting, "resist_a_rest() must leave the mob standing")

// -----------------------------------------------------------------------------
// Три статьи внутри human/BiologicalLife, где работа делалась при отсутствии
// изменений. Round 9803: BiologicalLife = 4.26с из 7.9с всего SSmobs.
// -----------------------------------------------------------------------------

/// check_breath() зовёт adjustOxyLoss(-breathModifier) на КАЖДОМ удачном вдохе.
/// У здорового игрока oxyloss уже 0, клампится обратно в 0 - и всё равно гнало
/// весь каскад updatehealth -> update_stat -> HUD (0.8с на 5762 вызова в проде).
/datum/unit_test/oxyloss_without_change_skips_cascade

/datum/unit_test/oxyloss_without_change_skips_cascade/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)
	patient.setOxyLoss(0)
	patient.updatehealth()
	TEST_ASSERT_EQUAL(patient.getOxyLoss(), 0, "Sanity: тестовый человек должен начинать без кислородного урона")

	// Ровно то, что делает вдох здорового игрока.
	patient.reset_counters()
	patient.adjustOxyLoss(-5)
	patient.adjustOxyLoss(-5)
	TEST_ASSERT_EQUAL(patient.getOxyLoss(), 0, "Лечение кислорода на нуле не должно уводить oxyloss ниже нуля")
	TEST_ASSERT_EQUAL(patient.health_updates, 0, "adjustOxyLoss без изменения обязан пропустить каскад updatehealth")

	// Реальное изменение обязано пройти каскад ровно один раз.
	patient.reset_counters()
	patient.adjustOxyLoss(10)
	TEST_ASSERT_EQUAL(patient.getOxyLoss(), 10, "adjustOxyLoss обязан применить урон")
	TEST_ASSERT_EQUAL(patient.health_updates, 1, "adjustOxyLoss с изменением обязан прогнать каскад один раз")

	// И обратно, включая клампящееся лечение с перебором.
	patient.reset_counters()
	patient.adjustOxyLoss(-100)
	TEST_ASSERT_EQUAL(patient.getOxyLoss(), 0, "Лечение с перебором обязано упереться в ноль")
	TEST_ASSERT_EQUAL(patient.health_updates, 1, "Лечение, дошедшее до нуля, обязано прогнать каскад один раз")

	// setOxyLoss тем же правилом.
	patient.reset_counters()
	patient.setOxyLoss(0)
	TEST_ASSERT_EQUAL(patient.health_updates, 0, "setOxyLoss в то же значение обязан пропустить каскад")
	patient.setOxyLoss(7)
	TEST_ASSERT_EQUAL(patient.health_updates, 1, "setOxyLoss в новое значение обязан прогнать каскад")

/// update_mobility() каждый Life-тик зовёт setMovetype(movement_type | CRAWLING).
/// Родительский /atom/movable/setMovetype выходит раньше, если значение то же, но
/// /mob/setMovetype всё равно доходил до update_movespeed().
/datum/unit_test/setmovetype_without_change_skips_movespeed

/datum/unit_test/setmovetype_without_change_skips_movespeed/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe)

	patient.reset_counters()
	patient.setMovetype(patient.movement_type)
	patient.setMovetype(patient.movement_type)
	TEST_ASSERT_EQUAL(patient.movespeed_updates, 0, "setMovetype тем же значением обязан пропустить пересчёт скорости")

	patient.reset_counters()
	var/original_movetype = patient.movement_type
	patient.setMovetype(original_movetype | CRAWLING)
	TEST_ASSERT(patient.movement_type & CRAWLING, "setMovetype обязан применить новый флаг")
	TEST_ASSERT_EQUAL(patient.movespeed_updates, 1, "setMovetype с изменением обязан пересчитать скорость")

	patient.reset_counters()
	patient.setMovetype(original_movetype)
	TEST_ASSERT(!(patient.movement_type & CRAWLING), "setMovetype обязан снять флаг обратно")
	TEST_ASSERT_EQUAL(patient.movespeed_updates, 1, "Снятие флага тоже обязано пересчитать скорость")

	// Ноль как старое значение - отдельный случай: `. = movement_type` вернёт 0, а
	// это не null. Проверка изменения обязана его различать (null != 0 в DM).
	patient.setMovetype(NONE)
	patient.reset_counters()
	patient.setMovetype(CRAWLING)
	TEST_ASSERT_EQUAL(patient.movespeed_updates, 1, "Переход из movement_type = 0 обязан считаться изменением")
	patient.setMovetype(original_movetype)

/// processes_on_life = FALSE снимает орган с обхода handle_organs(). Ставить его
/// можно только тем органам, чей on_life() и так ничего не делает - иначе орган
/// тихо перестанет работать. Тест проверяет это для КАЖДОГО такого типа.
/datum/unit_test/organs_marked_lifeless_really_do_nothing

/datum/unit_test/organs_marked_lifeless_really_do_nothing/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	var/checked = 0
	for(var/obj/item/organ/organ_type as anything in subtypesof(/obj/item/organ))
		if(initial(organ_type.processes_on_life))
			continue
		checked++
		var/obj/item/organ/organ = allocate(organ_type)
		organ.owner = host
		organ.applyOrganDamage(10)
		var/damage_before = organ.damage
		var/result = organ.on_life(2 SECONDS, 1)
		TEST_ASSERT(!result, "[organ_type] помечен processes_on_life = FALSE, но on_life() что-то вернул")
		TEST_ASSERT_EQUAL(organ.damage, damage_before, "[organ_type] помечен processes_on_life = FALSE, но on_life() изменил урон органа")
		organ.owner = null

	TEST_ASSERT(checked > 0, "Ни один тип органа не помечен processes_on_life = FALSE - тест перестал что-либо проверять")

/// Полная перерисовка гуманоида трогает семь слотов одежды, и каждый дёргал
/// update_mutant_bodyparts() -> handle_mutant_bodyparts(). Отсрочка обязана
/// свести это к одной пересборке в конце.
/datum/unit_test/regenerate_icons_batches_mutant_bodyparts/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe, run_loc_floor_bottom_left)
	patient.reset_counters()

	patient.regenerate_icons()

	TEST_ASSERT_EQUAL(patient.mutant_bodypart_rebuilds, 1, "Полная перерисовка обязана пересобирать мутантные части тела ровно один раз, получено [patient.mutant_bodypart_rebuilds]")
	TEST_ASSERT_EQUAL(patient.defer_mutant_bodyparts_update, 0, "Счётчик отсрочки обязан вернуться в ноль после regenerate_icons")

/// Одиночное обновление слота одежды отсрочкой НЕ затрагивается: оно и должно
/// пересобирать мутантные части сразу.
/datum/unit_test/single_slot_update_still_rebuilds_mutant_bodyparts/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe, run_loc_floor_bottom_left)
	patient.reset_counters()

	patient.update_inv_w_uniform()

	TEST_ASSERT_EQUAL(patient.mutant_bodypart_rebuilds, 1, "Обновление одного слота обязано пересобрать мутантные части немедленно, получено [patient.mutant_bodypart_rebuilds]")

/// give_genitals(clean = TRUE) больше не сносит и не создаёт комплект заново:
/// органы, которые по ДНК должны остаться, обязаны выжить теми же инстансами.
/datum/unit_test/give_genitals_reuses_existing_organs/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	patient.dna.features["has_breasts"] = TRUE
	patient.give_genitals(TRUE)

	var/obj/item/organ/genital/breasts = patient.getorganslot(ORGAN_SLOT_BREASTS)
	TEST_ASSERT_NOTNULL(breasts, "ДНК с has_breasts обязана дать орган груди")

	patient.give_genitals(TRUE)

	var/obj/item/organ/genital/breasts_after = patient.getorganslot(ORGAN_SLOT_BREASTS)
	TEST_ASSERT_EQUAL(breasts_after, breasts, "Повторный give_genitals(TRUE) обязан оставить тот же орган, а не пересоздать его")
	TEST_ASSERT(!QDELETED(breasts), "Уцелевший орган не должен быть удалён")

/// А вот орган, которого по ДНК быть не должно, обязан исчезнуть.
/datum/unit_test/give_genitals_drops_organs_absent_from_dna/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	patient.dna.features["has_breasts"] = TRUE
	patient.give_genitals(TRUE)
	TEST_ASSERT_NOTNULL(patient.getorganslot(ORGAN_SLOT_BREASTS), "ДНК с has_breasts обязана дать орган груди")

	patient.dna.features["has_breasts"] = FALSE
	patient.give_genitals(TRUE)

	TEST_ASSERT_NULL(patient.getorganslot(ORGAN_SLOT_BREASTS), "Орган, выключенный в ДНК, обязан быть удалён")

/// Несколько выключенных разом органов обязаны исчезнуть ВСЕ. qdel вычищает орган
/// из internal_organs, поэтому обход по живому списку сдвигал хвост и пропускал
/// каждый второй - комплект оставался наполовину собранным.
/datum/unit_test/give_genitals_drops_every_organ_absent_from_dna/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/static/list/tested_slots = list(ORGAN_SLOT_VAGINA, ORGAN_SLOT_WOMB, ORGAN_SLOT_BREASTS)
	patient.dna.features["has_vag"] = TRUE
	patient.dna.features["has_womb"] = TRUE
	patient.dna.features["has_breasts"] = TRUE
	patient.give_genitals(TRUE)
	for(var/slot in tested_slots)
		TEST_ASSERT_NOTNULL(patient.getorganslot(slot), "ДНК обязана выдать орган в слот [slot]")

	patient.dna.features["has_vag"] = FALSE
	patient.dna.features["has_womb"] = FALSE
	patient.dna.features["has_breasts"] = FALSE
	patient.give_genitals(TRUE)

	for(var/slot in tested_slots)
		TEST_ASSERT_NULL(patient.getorganslot(slot), "Орган в слоте [slot] выключен в ДНК и обязан быть удалён")

/// Кэш процессящихся органов обязан переживать вставку и удаление органа.
/datum/unit_test/life_processing_organ_cache_tracks_changes/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	patient.handle_organs(2 SECONDS, 1) //прогреваем кэш
	var/list/cached = patient.life_processing_organs
	TEST_ASSERT_NOTNULL(cached, "handle_organs обязан собрать кэш процессящихся органов")
	TEST_ASSERT(length(cached) > 0, "У гуманоида обязаны быть органы с processes_on_life")

	var/obj/item/organ/liver = patient.getorganslot(ORGAN_SLOT_LIVER)
	TEST_ASSERT_NOTNULL(liver, "У гуманоида обязана быть печень")
	liver.Remove()
	TEST_ASSERT_NULL(patient.life_processing_organs, "Удаление органа обязано сбросить кэш")

	patient.handle_organs(2 SECONDS, 2)
	TEST_ASSERT(!(liver in patient.life_processing_organs), "Удалённая печень не должна остаться в кэше")

	liver.Insert(patient)
	TEST_ASSERT_NULL(patient.life_processing_organs, "Вставка органа обязана сбросить кэш")
	patient.handle_organs(2 SECONDS, 3)
	TEST_ASSERT((liver in patient.life_processing_organs), "Вернувшаяся печень обязана снова попасть в кэш")

/// Кэтч-олл мобильности из Life не должен пересчитывать флаги, пока входы не
/// изменились, и обязан пересчитать их сразу после смены stat.
/datum/unit_test/mobility_catchall_skips_unchanged_state/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe, run_loc_floor_bottom_left)
	patient.life_periodic_phase = 0
	patient.update_mobility_if_dirty(1) //первый прогон заполняет подпись
	patient.reset_counters()

	//times_fired = 2: не кратен принудительной каденсе, входы не менялись
	patient.update_mobility_if_dirty(2)
	TEST_ASSERT_EQUAL(patient.mobility_updates, 0, "Без изменения входов кэтч-олл обязан пропустить update_mobility, получено [patient.mobility_updates]")

	patient.set_stat(UNCONSCIOUS)
	patient.reset_counters()
	patient.update_mobility_if_dirty(3)
	TEST_ASSERT_EQUAL(patient.mobility_updates, 1, "После смены stat кэтч-олл обязан пересчитать мобильность")

/// Принудительный прогон раз в четыре тика - страховка от источников, которых
/// подпись не видит. Он обязан срабатывать даже на неизменных входах.
/datum/unit_test/mobility_catchall_forced_cadence/Run()
	var/mob/living/carbon/human/cascade_probe/patient = allocate(/mob/living/carbon/human/cascade_probe, run_loc_floor_bottom_left)
	patient.life_periodic_phase = 0
	patient.update_mobility_if_dirty(1)
	patient.reset_counters()

	patient.update_mobility_if_dirty(4) //4 % 4 == 0
	TEST_ASSERT_EQUAL(patient.mobility_updates, 1, "Принудительный прогон обязан пересчитать мобильность даже без изменений")

/// Кэш гравитации: пока моб стоит на месте, has_gravity не опрашивается заново,
/// а перемещение обязано пометить кэш протухшим.
/datum/unit_test/gravity_cache_invalidated_by_movement/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	patient.refresh_gravity()
	TEST_ASSERT(!patient.gravity_cache_dirty, "refresh_gravity обязан снять флаг протухания")

	patient.handle_gravity()
	TEST_ASSERT(!patient.gravity_cache_dirty, "Стоящий на месте моб не должен помечать кэш гравитации протухшим")

	patient.forceMove(get_step(patient, EAST))
	TEST_ASSERT(patient.gravity_cache_dirty, "Перемещение обязано пометить кэш гравитации протухшим")

	patient.handle_gravity()
	TEST_ASSERT(!patient.gravity_cache_dirty, "handle_gravity обязан пересчитать гравитацию после перемещения")
