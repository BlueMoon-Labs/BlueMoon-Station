/datum/quirk/bluemoon_devourer
	name = "Пожиратель"
	desc = "Ваши размеры огромны, а голод неутолим. Всё, что съедобно, для вас еда, а ожирение не помеха. Особенности вашей физиологии позволяют вам \
	передвигаться на порядок быстрее, однако тело более восприимчиво к повреждениям. Вы не можете быть лёгким или сверхтяжёлым, а нормалазер на вас не действует."
	value = 3
	mob_trait = TRAIT_BLUEMOON_DEVOURER
	medical_record_text = "Субъект проявляет признаки гигантизма и аномальной прожорливости, а также способность усваивать любую пищу."
	gain_text = span_notice("Вы чувствуете неумалимый голод.")
	lose_text = span_notice("Ваш голод проходит.")
	processing_quirk = TRUE

/datum/quirk/bluemoon_devourer/add()
	// да, кушать можно всё, но нужно сильно больше
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	species.disliked_food = null
	H.physiology.hunger_mod *= 2
	if(H.mob_weight != MOB_WEIGHT_NORMAL)
		H.mob_weight = MOB_WEIGHT_NORMAL
		H.update_weight(H.mob_weight)
	H.maxHealth *= 0.75 // -50% от доп хп.
	// Действие на сборс сытости
	var/datum/action/innate/vomit/act_vomit = new
	act_vomit.Grant(H)

	var/datum/action/innate/secrete_chemicals/act_secrete_chemicals = new
	act_secrete_chemicals.Grant(H)
	// Add examine text
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))
	ADD_TRAIT(H,TRAIT_BLUEMOON_ANTI_NORMALIZER, ROUNDSTART_TRAIT)


/datum/quirk/bluemoon_devourer/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species

		species.liked_food = initial(species.liked_food)
		species.disliked_food = initial(species.disliked_food)

		//удаляем все модификаторы урона и скорости
		H.remove_movespeed_modifier(/datum/movespeed_modifier/devourer_quirk_boost)

		var/datum/physiology/P = H.physiology
		if(P)
			P.hunger_mod /= 2

		H.maxHealth *= 1.34

		var/datum/action/innate/vomit/act_vomit = locate() in H.actions
		if(act_vomit)
			act_vomit.Remove(H)

		var/datum/action/innate/secrete_chemicals/act_secrete_chemicals = locate() in H.actions
		if(act_secrete_chemicals)
			act_secrete_chemicals.Remove(H)

		UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)
		REMOVE_TRAIT(H,TRAIT_BLUEMOON_ANTI_NORMALIZER, ROUNDSTART_TRAIT)

// Quirk examine text
/datum/quirk/bluemoon_devourer/proc/on_examine_holder(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	examine_list += "[quirk_holder.ru_ego(TRUE)] явно мучает голод."


/datum/quirk/bluemoon_devourer/proc/update_size_modifiers(new_size, cur_size)
	if (check_mob_size() && new_size != cur_size) // не даём уменьшиться, в т.ч. если мёртв
		var/mob/living/carbon/human/H= quirk_holder

		var/user_slowdown = (abs(new_size - 1) * CONFIG_GET(number/body_size_slowdown_multiplier))

		H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/devourer_quirk_boost, TRUE, user_slowdown * -0.8) // убираем 80% от замедления


/datum/quirk/bluemoon_devourer/proc/check_mob_size()
	if(!isliving(quirk_holder))
		return FALSE

	var/mob/living/owner = quirk_holder

	if(get_size(owner) < 2)
		to_chat(owner, "Ваш размер невозможно изменить")
		owner.update_size(2)
		return FALSE
	return TRUE

/datum/quirk/bluemoon_devourer/on_spawn()
	. = ..()
	var/mob/living/H = quirk_holder
	// Этот участок фиксит проблемы, когда надевается нормалайзер раундстартом (из лодаута) и перк пожирателя. Они наслаиваются и по итогу ломается скорость и размер
	var/datum/component/size_normalized/comp = H.GetComponent(/datum/component/size_normalized)
	if(comp)
		qdel(comp)
	// конец участка
	update_size_modifiers(get_size(H), 1)

/*
Действия
*/

/datum/action/innate/vomit
	name = "Vomit"
	desc = "Vomit some digested food from your body."
	icon_icon = 'icons/mob/actions/actions_xeno.dmi'
	button_icon_state = "alien_barf"

/datum/action/innate/vomit/Activate()
	var/mob/living/carbon/human/H = owner
	H.vomit(lost_nutrition = 50, stun = FALSE)
	H.adjustToxLoss(-10)

/datum/action/innate/secrete_chemicals
	name = "Screte Chemicals"
	desc = "Screte some chemicals into your blood."
	icon_icon = 'icons/mob/actions/actions_xeno.dmi'
	button_icon_state = "alien_acid"

/datum/action/innate/secrete_chemicals/Activate()
	var/mob/living/carbon/human/H = owner
	if(H.nutrition >= NUTRITION_LEVEL_WELL_FED)
		H.reagents.add_reagent(/datum/reagent/medicine/salglu_solution, 10)
		H.reagents.add_reagent(/datum/reagent/drug/aphrodisiac, 5)
		H.add_lust(20)
		H.adjust_nutrition(100)
		to_chat(owner, "<span class='notice'>Вы разлагаете часть ваших пищевых запасов, выпуская в кровь смесь реагентов.</span>")
	else
		to_chat(owner, "<span class='notice'>Вы слишком голодны для этого.</span>")
