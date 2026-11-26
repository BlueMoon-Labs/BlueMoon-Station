/datum/unit_test/proc/heretic_tails_last_round(datum/eldritch_knowledge/base_lead/lead, mob/living/target)
	var/mob/living/carbon/human/user = lead.lead_body
	var/obj/item/projectile/bullet/heretic_lead/last_round/bullet = new(get_turf(user))
	bullet.firer = user
	bullet.lead_ref = WEAKREF(lead)
	bullet.preparePixelProjectile(target, user)
	bullet.fire()
	heretic_lead_test_fly(bullet, 2)

/// Последний патрон за попадание Свинец не возвращает, а убитый им человек отдаёт те же три, что и обычная пуля.
/datum/unit_test/heretic_lead_last_round_kill_refund/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/survivor = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	lead.combat_resource = 0
	heretic_tails_last_round(lead, survivor)
	TEST_ASSERT(survivor.stat != DEAD && survivor.getBruteLoss() > 0, "Последний патрон попал и не убил: [survivor.getBruteLoss()].")
	TEST_ASSERT_EQUAL(lead.combat_resource, 0, "Попадание Последнего патрона без убийства Свинец не возвращает.")
	survivor.forceMove(heretic_lead_test_spot(2, 0))
	var/mob/living/carbon/human/doomed = heretic_lead_test_crew(heretic_lead_test_spot(0, 4))
	doomed.setOxyLoss(170)
	TEST_ASSERT(doomed.stat != DEAD, "Цель ещё жива.")
	heretic_tails_last_round(lead, doomed)
	TEST_ASSERT(doomed.stat == DEAD, "Последний патрон добил цель: здоровье [doomed.health].")
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_KILL_LEAD, "Убийство Последним патроном возвращает [HERETIC_LEAD_KILL_LEAD] Свинца.")
	heretic_tails_last_round(lead, doomed)
	TEST_ASSERT_EQUAL(lead.combat_resource, HERETIC_LEAD_KILL_LEAD, "Выстрел в труп Свинец не возвращает.")
