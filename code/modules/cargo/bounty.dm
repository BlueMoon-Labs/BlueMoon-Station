/datum/bounty
	var/name
	var/description
	var/reward = 1000 // In credits.
	var/high_priority = FALSE

// Displayed on bounty UI screen.
/datum/bounty/proc/completion_string()
	return ""

/datum/bounty/proc/can_claim()
	return TRUE

// If an item sent in the cargo shuttle can satisfy the bounty.
/datum/bounty/proc/applies_to(obj/O)
	return FALSE

// Called when an object is shipped on the cargo shuttle.
/datum/bounty/proc/ship(obj/O)
	return

// When randomly generating the bounty list, duplicate bounties must be avoided.
// This proc is used to determine if two bounties are duplicates, or incompatible in general.
/datum/bounty/proc/compatible_with(other_bounty)
	return TRUE

/datum/bounty/proc/mark_high_priority(scale_reward = 2)
	if(high_priority)
		return
	high_priority = TRUE
	reward = round(reward * scale_reward)

/// Выставляет баунти особым контрактом NT. FALSE, если такой заказ уже есть.
/proc/try_add_bounty(datum/bounty/new_bounty)
	return !!SSeconomy.post_special_contract(new_bounty)

// Returns a new bounty of random type without posting it.
/proc/random_bounty(var/guided = 0)
	var/bounty_num
	if(guided && (guided != CIV_JOB_RANDOM))
		bounty_num = guided
	else
		bounty_num = rand(1,18)
	switch(bounty_num)
		if(1)
			var/subtype = pick(subtypesof(/datum/bounty/item/assistant))
			return new subtype
		if(2)
			var/list/choices = list( // Процентный шанс пика определённой категории баунти. Применено ввиду неравности шансов выпадения.
				/datum/bounty/item/mech = 25,
				/datum/bounty/item/roboticist = 35,
				/datum/bounty/item/cyborglimbs = 35,
				/datum/bounty/item/bot = 35
				)
			var/subtype_category = pickweight(choices)
			var/list/subtypes = subtypesof(subtype_category)
			var/subtype = pick(subtypes)
			return new subtype
		if(3)
			var/subtype = pick(subtypesof(/datum/bounty/item/chef))
			return new subtype
		if(4)
			var/subtype = pick(subtypesof(/datum/bounty/item/security))
			return new subtype
		if(5)
			if(prob(50))
				return new /datum/bounty/reagent/simple_drink
			else
				return new /datum/bounty/reagent/complex_drink
		if(6)
			return new /datum/bounty/reagent/chemical
		if(7)
			var/subtype = pick(subtypesof(/datum/bounty/virus))
			return new subtype
		if(8)
			var/subtype
			if(prob(50))
				subtype = pick(subtypesof(/datum/bounty/item/science))
			else
				subtype = pick(subtypesof(/datum/bounty/item/slime))
			return new subtype
		if(9)
			var/subtype = pick(subtypesof(/datum/bounty/item/engineering))
			return new subtype
		if(10)
			var/subtype = pick(subtypesof(/datum/bounty/item/mining))
			return new subtype
		if(11)
			var/subtype = pick(subtypesof(/datum/bounty/item/medical) + /datum/bounty/reagent/blood)
			return new subtype
		if(12)
			var/subtype = pick(subtypesof(/datum/bounty/item/botany))
			return new subtype
		if(13)
			var/subtype = pick(subtypesof(/datum/bounty/item/silly))
			return new subtype
		if(14, 15)
			var/subtype = pick(subtypesof(/datum/bounty/item/gardencook))
			return new subtype
		if(16)
			var/subtype = pick(subtypesof(/datum/bounty/lewd))
			return new subtype
		if(17)
			var/subtype
			if(prob(50))
				return new /datum/bounty/reagent/chemical
			else
				subtype = pick(subtypesof(/datum/bounty/item/medical))
			return new subtype
		if(18)
			var/subtype
			switch(rand(1,4))
				if(1)
					subtype = pick(subtypesof(/datum/bounty/item/mech))
				if(2)
					subtype = pick(subtypesof(/datum/bounty/item/roboticist))
				if(3)
					subtype = pick(subtypesof(/datum/bounty/item/science))
				if(4)
					subtype = pick(subtypesof(/datum/bounty/item/slime))
			return new subtype
	if(guided == CIV_JOB_BASIC)
		var/list/assistant_bounties = subtypesof(/datum/bounty/item/assistant)
		if(length(assistant_bounties))
			var/subtype = pick(assistant_bounties)
			return new subtype
	return null
