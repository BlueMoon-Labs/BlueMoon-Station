//These mutations change your overall "form" somehow, like size

//Epilepsy gives a very small chance to have a seizure every life tick, knocking you unconscious.
/datum/mutation/human/epilepsy
	name = "Epilepsy"
	desc = "Генетический дефект, время от времени вызывающий припадки."
	quality = NEGATIVE
	text_gain_indication = "<span class='danger'>You get a headache.</span>"
	synchronizer_coeff = 1
	power_coeff = 1

/datum/mutation/human/epilepsy/on_life()
	if(prob(1 * GET_MUTATION_SYNCHRONIZER(src)) && owner.stat == CONSCIOUS)
		owner.visible_message("<span class='danger'>[owner] падает в припадке!</span>", "<span class='userdanger'>У вас начался припадок!</span>")
		owner.Unconscious(200 * GET_MUTATION_POWER(src))
		owner.Jitter(1000 * GET_MUTATION_POWER(src))
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "epilepsy", /datum/mood_event/epilepsy)
		addtimer(CALLBACK(src, PROC_REF(jitter_less)), 90)

/datum/mutation/human/epilepsy/proc/jitter_less(mob/living/carbon/human/owner)
	if(owner)
		owner.jitteriness = 10


//Unstable DNA induces random mutations!
/datum/mutation/human/bad_dna
	name = "Unstable DNA"
	desc = "Странная мутация, заставляющая носителя случайно мутировать."
	quality = NEGATIVE
	text_gain_indication = "<span class='danger'>You feel strange.</span>"
	locked = TRUE

/datum/mutation/human/bad_dna/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	to_chat(owner, text_gain_indication)
	var/mob/new_mob
	if(prob(95))
		if(prob(50))
			new_mob = owner.easy_randmut(NEGATIVE + MINOR_NEGATIVE)
		else
			new_mob = owner.randmuti()
	else
		new_mob = owner.easy_randmut(POSITIVE)
	if(new_mob && ismob(new_mob))
		owner = new_mob
	. = owner
	on_losing(owner)


//Cough gives you a chronic cough that causes you to drop items.
/datum/mutation/human/cough
	name = "Cough"
	desc = "Хронический кашель."
	quality = MINOR_NEGATIVE
	text_gain_indication = "<span class='danger'>You start coughing.</span>"
	synchronizer_coeff = 1
	power_coeff = 1

/datum/mutation/human/cough/on_life()
	if(prob(5 * GET_MUTATION_SYNCHRONIZER(src)) && owner.stat == CONSCIOUS)
		owner.drop_all_held_items()
		owner.emote("cough")

		if(GET_MUTATION_POWER(src) > 1)
			var/cough_range = GET_MUTATION_POWER(src) * 4
			var/turf/target = get_ranged_target_turf(owner, turn(owner.dir, 180), cough_range)
			owner.throw_at(target, cough_range, GET_MUTATION_POWER(src))


//Dwarfism shrinks your body and lets you pass tables.
/datum/mutation/human/dwarfism
	name = "Dwarfism"
	desc = "Мутация, которую считают причиной карликовости."
	quality = POSITIVE
	difficulty = 16
	instability = 5
	conflicts = list(GIGANTISM)
	locked = TRUE    // Default intert species for now, so locked from regular pool.

/datum/mutation/human/dwarfism/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	ADD_TRAIT(owner, TRAIT_DWARF, GENETIC_MUTATION)
	owner.AddElement(/datum/element/dwarfism, COMSIG_HUMAN_MUTATION_LOSS, src)
	passtable_on(owner, GENETIC_MUTATION)
	owner.visible_message("<span class='danger'>[owner] suddenly shrinks!</span>", "<span class='notice'>Everything around you seems to grow..</span>")

/datum/mutation/human/dwarfism/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, TRAIT_DWARF, GENETIC_MUTATION)
	passtable_off(owner, GENETIC_MUTATION)
	owner.visible_message("<span class='danger'>[owner] suddenly grows!</span>", "<span class='notice'>Everything around you seems to shrink..</span>")


//Clumsiness has a very large amount of small drawbacks depending on item.
/datum/mutation/human/clumsy
	name = "Clumsiness"
	desc = "Геном, подавляющий некоторые функции мозга, из-за чего носитель кажется неуклюжим. Хонк"
	quality = MINOR_NEGATIVE
	text_gain_indication = "<span class='danger'>You feel lightheaded.</span>"

/datum/mutation/human/clumsy/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	ADD_TRAIT(owner, TRAIT_CLUMSY, GENETIC_MUTATION)

/datum/mutation/human/clumsy/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, TRAIT_CLUMSY, GENETIC_MUTATION)


//Tourettes causes you to randomly stand in place and shout.
/datum/mutation/human/tourettes
	name = "Tourette's Syndrome"
	desc = "Хронический тик, заставляющий носителя выражаться крепкими словечками."
	quality = NEGATIVE
	text_gain_indication = "<span class='danger'>You twitch.</span>"
	synchronizer_coeff = 1

/datum/mutation/human/tourettes/on_life()
	if(prob(10 * GET_MUTATION_SYNCHRONIZER(src)) && owner.stat == CONSCIOUS && !owner.IsStun())
		owner.Stun(200)
		switch(rand(1, 3))
			if(1)
				owner.emote("twitch")
			if(2 to 3)
				owner.say("[prob(50) ? ";" : ""][pick("ДЕРЬМО", "ХУЙ", "БЛЯДЬ", "ПИЗДА", "ХУЕСОС", "УЁБОК", "ПИДОР")]", forced="tourette's syndrome")
		var/x_offset_old = owner.pixel_x
		var/y_offset_old = owner.pixel_y
		var/x_offset = owner.pixel_x + rand(-2,2)
		var/y_offset = owner.pixel_y + rand(-1,1)
		animate(owner, pixel_x = x_offset, pixel_y = y_offset, time = 1)
		animate(owner, pixel_x = x_offset_old, pixel_y = y_offset_old, time = 1)


//Deafness makes you deaf.
/datum/mutation/human/deaf
	name = "Deafness"
	desc = "Носитель этого генома полностью глух."
	quality = NEGATIVE
	text_gain_indication = "<span class='danger'>You can't seem to hear anything.</span>"

/datum/mutation/human/deaf/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	ADD_TRAIT(owner, TRAIT_DEAF, GENETIC_MUTATION)

/datum/mutation/human/deaf/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, TRAIT_DEAF, GENETIC_MUTATION)


//Monified turns you into a monkey.
/datum/mutation/human/race
	name = "Monkified"
	desc = "Странный геном, который, как считается, отличает обезьян от людей."
	quality = NEGATIVE
	time_coeff = 2
	locked = TRUE //Species specific, keep out of actual gene pool

/datum/mutation/human/race/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	. = owner.monkeyize(TR_KEEPITEMS | TR_KEEPIMPLANTS | TR_KEEPORGANS | TR_KEEPDAMAGE | TR_KEEPVIRUS | TR_KEEPSE)

/datum/mutation/human/race/on_losing(mob/living/carbon/monkey/owner)
	if(owner && istype(owner) && owner.stat != DEAD && (owner.dna.mutations.Remove(src)))
		. = owner.humanize(TR_KEEPITEMS | TR_KEEPIMPLANTS | TR_KEEPORGANS | TR_KEEPDAMAGE | TR_KEEPVIRUS | TR_KEEPSE)


/datum/mutation/human/glow
	name = "Glowy"
	desc = "Вы постоянно излучаете свет случайного цвета и интенсивности."
	quality = POSITIVE
	text_gain_indication = "<span class='notice'>Your skin begins to glow softly.</span>"
	instability = 5
	var/obj/effect/dummy/luminescent_glow/glowth //shamelessly copied from luminescents
	var/glow_range = 2.5
	var/glow_power = 2.5
	power_coeff = 1

/datum/mutation/human/glow/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	glowth = new(owner)
	glowth.set_light(glow_range, glow_power, dna.features["mcolor"])

/datum/mutation/human/glow/modify(mob/living/carbon/human/owner)
	if(glowth)
		glowth.set_light(glow_range * GET_MUTATION_POWER(src) , glow_power * GET_MUTATION_POWER(src), dna.features["mcolor"])

/datum/mutation/human/glow/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	qdel(glowth)

/datum/mutation/human/strong
	name = "Strength"
	desc = "Мышцы носителя слегка увеличиваются."
	quality = POSITIVE
	text_gain_indication = "<span class='notice'>You feel strong.</span>"
	difficulty = 16

/datum/mutation/human/fire
	name = "Fiery Sweat"
	desc = "Кожа носителя время от времени самовозгорается, но в целом гораздо более устойчива к ожогам."
	quality = NEGATIVE
	text_gain_indication = "<span class='warning'>You feel hot.</span>"
	text_lose_indication = "<span class'notice'>You feel a lot cooler.</span>"
	difficulty = 14
	synchronizer_coeff = 1
	power_coeff = 1

/datum/mutation/human/fire/on_life()
	if(prob((1+(100-dna.stability)/10)) * GET_MUTATION_SYNCHRONIZER(src))
		owner.adjust_fire_stacks(2 * GET_MUTATION_POWER(src))
		owner.IgniteMob()

/datum/mutation/human/fire/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	owner.physiology.burn_mod *= 0.5

/datum/mutation/human/fire/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	owner.physiology.burn_mod *= 2

/datum/mutation/human/insulated
	name = "Insulated"
	desc = "Носитель не проводит электричество."
	quality = POSITIVE
	mutator_security_level = INSULATED_PRINT_CODE
	text_gain_indication = "<span class='notice'>Your fingertips go numb.</span>"
	text_lose_indication = "<span class='notice'>Your fingertips regain feeling.</span>"
	difficulty = 16
	instability = 25

/datum/mutation/human/insulated/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	ADD_TRAIT(owner, TRAIT_SHOCKIMMUNE, "genetics")

/datum/mutation/human/insulated/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, TRAIT_SHOCKIMMUNE, "genetics")


/datum/mutation/human/glow/anti
	name = "Anti-Glow"
	desc = "Ваша кожа словно притягивает и поглощает окружающий свет, создавая вокруг вас «тьму»."
	text_gain_indication = "<span class='notice'>Your light around you seems to disappear.</span>"
	glow_range = 1
	glow_power = -2 //Slightly stronger, since negating light tends to be harder than making it.
	locked = TRUE

/datum/mutation/human/glow/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	glowth = new(owner)
	glowth.set_light(glow_range, glow_power)

/datum/mutation/human/glow/anti/modify(mob/living/carbon/human/owner)
	if(glowth)
		glowth.set_light(glow_range * GET_MUTATION_POWER(src) , glow_power * GET_MUTATION_POWER(src))


/datum/mutation/human/stimmed
	name = "Stimmed"
	desc = "Химический баланс носителя более устойчив."
	quality = POSITIVE
	text_gain_indication = "<span class='notice'>You feel stimmed.</span>"
	difficulty = 18

/datum/mutation/human/paranoia
	name = "Paranoia"
	desc = "Носитель легко пугается и может страдать от галлюцинаций."
	quality = NEGATIVE
	text_gain_indication = "<span class='danger'>You feel screams echo through your mind...</span>"
	text_lose_indication = "<span class'notice'>The screaming in your mind fades.</span>"

/datum/mutation/human/paranoia/on_life()
	if(prob(5) && owner.stat == CONSCIOUS)
		owner.emote("realagony")
		owner.jitteriness = min(max(0, owner.jitteriness + 5), 30)
		if(prob(25))
			to_chat(owner,"<span class='warning'>You feel someone creeping in on you...</span>")
			owner.hallucination += 20


/datum/mutation/human/badblink
	name = "Spatial Instability"
	desc = "Носитель мутации имеет очень слабую связь с пространственной реальностью и может быть перемещён. Часто вызывает сильную тошноту."
	quality = NEGATIVE
	text_gain_indication = "<span class='warning'>The space around you twists sickeningly.</span>"
	text_lose_indication = "<span class'notice'>The space around you settles back to normal.</span>"
	difficulty = 18//high so it's hard to unlock and abuse
	instability = 10
	synchronizer_coeff = 1
	energy_coeff = 1
	power_coeff = 1
	var/warpchance = 0

/datum/mutation/human/badblink/on_life()
	if (!owner)
		return
	if(prob(warpchance))
		var/warpmessage = pick(
		"<span class='warning'>With a sickening 720-degree twist of [owner.ru_ego()] back, [owner] vanishes into thin air.</span>",
		"<span class='warning'>[owner] does some sort of strange backflip into another dimension. It looks pretty painful.</span>",
		"<span class='warning'>[owner] does a jump to the left, a step to the right, and warps out of reality.</span>",
		"<span class='warning'>[owner]'s torso starts folding inside out until it vanishes from reality, taking [owner] with it.</span>",
		"<span class='warning'>One moment, you see [owner]. The next, [owner] is gone.</span>")
		owner.visible_message(warpmessage, "<span class='userdanger'>You feel a wave of nausea as you fall through reality!</span>")
		var/warpdistance = rand(10,15) * GET_MUTATION_POWER(src)
		do_teleport(owner, get_turf(owner), warpdistance, channel = TELEPORT_CHANNEL_FREE)
		owner.adjust_disgust(GET_MUTATION_SYNCHRONIZER(src) * (warpchance * warpdistance))
		warpchance = 0
		owner.visible_message("<span class='danger'>[owner] appears out of nowhere!</span>")
	else
		warpchance += 0.25 * GET_MUTATION_ENERGY(src)

/datum/mutation/human/acidflesh
	name = "Acidic Flesh"
	desc = "Под кожей носителя накапливаются кислотные вещества. Это часто смертельно."
	quality = NEGATIVE
	text_gain_indication = "<span class='userdanger'>A horrible burning sensation envelops you as your flesh turns to acid!</span>"
	text_lose_indication = "<span class'notice'>A feeling of relief fills you as your flesh goes back to normal.</span>"
	difficulty = 18//high so it's hard to unlock and use on others
	var/msgcooldown = 0

/datum/mutation/human/acidflesh/on_life()
	if(prob(25))
		if(world.time > msgcooldown)
			to_chat(owner, "<span class='danger'>Your acid flesh bubbles...</span>")
			msgcooldown = world.time + 200
		if(prob(15))
			owner.acid_act(rand(30,50), 10)
			owner.visible_message("<span class='warning'>[owner]'s skin bubbles and pops.</span>", "<span class='userdanger'>Your bubbling flesh pops! It burns!</span>")
			playsound(owner,'sound/weapons/sear.ogg', 50, TRUE)

/datum/mutation/human/gigantism
	name = "Gigantism"//negative version of dwarfism
	desc = "Клетки носителя растягиваются, занимая больше пространства, из-за чего он кажется крупнее."
	quality = MINOR_NEGATIVE
	difficulty = 12
	conflicts = list(DWARFISM)

/datum/mutation/human/gigantism/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	ADD_TRAIT(owner, TRAIT_GIANT, GENETIC_MUTATION)
	var/size = get_size(owner)
	owner.update_size(size * 1.25)
	owner.visible_message("<span class='danger'>[owner] suddenly grows!</span>", "<span class='notice'>Everything around you seems to shrink..</span>")

/datum/mutation/human/gigantism/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	REMOVE_TRAIT(owner, TRAIT_GIANT, GENETIC_MUTATION)
	var/size = get_size(owner)
	owner.update_size(size * 0.8)
	owner.visible_message("<span class='danger'>[owner] suddenly shrinks!</span>", "<span class='notice'>Everything around you seems to grow..</span>")

/datum/mutation/human/spastic
	name = "Spastic"
	desc = "Носитель страдает от мышечных спазмов."
	quality = NEGATIVE
	text_gain_indication = "<span class='warning'>You flinch.</span>"
	text_lose_indication = "<span class'notice'>Your flinching subsides.</span>"
	difficulty = 16

/datum/mutation/human/spastic/on_acquiring()
	if(..())
		return
	if (owner)
		owner.apply_status_effect(STATUS_EFFECT_SPASMS)

/datum/mutation/human/spastic/on_losing()
	if(..())
		return
	if (owner)
		owner.remove_status_effect(STATUS_EFFECT_SPASMS)
