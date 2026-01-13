//Crocine .50 bullet
/obj/item/projectile/bullet/p50/lewd
	name =".50 lewd bullet"
	damage = 5
	knockdown = 100
	dismemberment = 0
	stamina = 75
	breakthings = FALSE
	wound_bonus = 0
	bare_wound_bonus = 1

/obj/item/projectile/bullet/p50/lewd/on_hit(atom/target, blocked = 0)
	if(iscarbon(target))
		var/mob/living/carbon/victim = target
		if(victim.client && victim.client.prefs.erppref == "Yes" && CHECK_BITFIELD(victim.client.prefs.toggles, VERB_CONSENT) && victim.client.prefs.nonconpref == "Yes")
			if(isrobotic(victim))
				victim.reagents.add_reagent(/datum/reagent/consumable/synthdrink/synthanol/ultralube, 20)
			else
				victim.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, 50)
			victim.emote("moan")
	return ..()
