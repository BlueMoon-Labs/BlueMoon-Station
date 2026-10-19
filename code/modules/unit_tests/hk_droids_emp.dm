#define HK_TEST_HEAVY_EMP 100
#define HK_TEST_LIGHT_EMP 20
#define HK_TEST_SHORT_STUN (1 SECONDS)

/// Сильный ЭМИ отключает шасси HK на HK_EMP_HEAVY_STUN и открывает перепрошивку; повторно - только после HK_EMP_STUN_COOLDOWN.
/datum/unit_test/hk_emp_heavy_stun

/datum/unit_test/hk_emp_heavy_stun/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/datum/species/ipc/hk/chassis = droid.dna.species
	droid.emp_act(HK_TEST_HEAVY_EMP)
	TEST_ASSERT_EQUAL(round(droid.AmountParalyzed(), 1), HK_EMP_HEAVY_STUN, "heavy EMP shuts the HK chassis down for the full time")
	TEST_ASSERT(is_hk_droid_disabled(droid), "EMP-stunned HK counts as disabled for reprogramming")
	droid.SetParalyzed(HK_TEST_SHORT_STUN)
	droid.emp_act(HK_TEST_HEAVY_EMP)
	TEST_ASSERT_EQUAL(round(droid.AmountParalyzed(), 1), HK_TEST_SHORT_STUN, "second EMP inside the immunity window does not extend the stun")

	droid.SetParalyzed(0)
	droid.rollback_emp_protection()
	var/corruption = droid.getToxLoss()
	droid.emp_act(HK_TEST_HEAVY_EMP)
	TEST_ASSERT(droid.getToxLoss() > corruption, "after the generic immunity EMP still corrupts HK systems")
	TEST_ASSERT(!droid.IsParalyzed(), "EMP inside HK_EMP_STUN_COOLDOWN does not paralyze again")

	droid.rollback_emp_protection()
	COOLDOWN_RESET(chassis, emp_stun_cooldown)
	droid.emp_act(HK_TEST_HEAVY_EMP)
	TEST_ASSERT_EQUAL(round(droid.AmountParalyzed(), 1), HK_EMP_HEAVY_STUN, "EMP after HK_EMP_STUN_COOLDOWN paralyzes again")

/// Слабый ЭМИ отключает любое шасси HK на HK_EMP_LIGHT_STUN, обычный IPC так не оглушается.
/datum/unit_test/hk_emp_light_stun

/datum/unit_test/hk_emp_light_stun/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	droid.emp_act(HK_TEST_LIGHT_EMP)
	TEST_ASSERT_EQUAL(round(droid.AmountParalyzed(), 1), HK_EMP_LIGHT_STUN, "light EMP shuts the HK chassis down for the short time")
	var/mob/living/carbon/human/ipc = allocate(/mob/living/carbon/human)
	ipc.set_species(/datum/species/ipc)
	ipc.emp_act(HK_TEST_HEAVY_EMP)
	TEST_ASSERT(!ipc.IsParalyzed(), "plain IPC keeps its own EMP reaction")

/// Пока ЭМИ держит шасси, глаза и их свет гаснут и загораются, когда паралич кончается; корпус без жизни на ЭМИ не отвечает.
/datum/unit_test/hk_emp_blackout

/datum/unit_test/hk_emp_blackout/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	var/datum/species/ipc/hk/chassis = droid.dna.species
	var/obj/effect/dummy/lighting_obj/moblight/hk_eyes/glow = locate() in droid
	TEST_ASSERT(chassis.eyes_drawn && glow.light_on, "a working HK shows its eyes")
	droid.emp_act(HK_TEST_HEAVY_EMP)
	TEST_ASSERT(!chassis.eyes_drawn, "EMP turns the eyes off")
	TEST_ASSERT(!glow.light_on, "EMP turns the eye light off")
	chassis.spec_life(droid)
	TEST_ASSERT(!chassis.eyes_drawn, "the eyes stay dark while the chassis is down")
	droid.SetParalyzed(0)
	chassis.spec_life(droid)
	TEST_ASSERT(chassis.eyes_drawn && glow.light_on, "the eyes light up once the chassis is back")
	chassis.end_emp_blackout(WEAKREF(droid))
	TEST_ASSERT(!chassis.emp_blackout, "the blackout ends with the stun timer")

	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human)
	corpse.set_species(/datum/species/ipc/hk/hk47)
	var/datum/species/ipc/hk/dead_chassis = corpse.dna.species
	corpse.death()
	corpse.emp_act(HK_TEST_HEAVY_EMP)
	TEST_ASSERT(COOLDOWN_FINISHED(dead_chassis, emp_stun_cooldown), "EMP on a dead HK spends no stun cooldown")
	TEST_ASSERT(!dead_chassis.emp_blackout, "EMP on a dead HK does not start a blackout")

#undef HK_TEST_HEAVY_EMP
#undef HK_TEST_LIGHT_EMP
#undef HK_TEST_SHORT_STUN
