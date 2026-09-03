//This file is for clock rites, mainly used by the Sigil of Rites in clock_sigils.dm
//The rites themselves are in this file to prevent bloating the other file too much, aswell as for easier access

#define INFINITE -1

//The base clockwork rite. This should never be visible
/datum/clockwork_rite
	var/name = "Rite of THE frog" //The name of the rite
	var/desc = "Этот обряд служит для призыва легендарной лягушки, имя которой не следует произносить, уничтожительницы многих миров." //What does this rite do? Shown to servants if they choose 'Show Info' after selecting the rite.
	var/list/required_ingredients = list(/obj/item/clockwork) //What does this rite require?
	var/power_cost = 0 //How much power does this rite cost.. or does it even add power?
	var/requires_human = FALSE	//Does the rite require a ../carbon/human on the sigil?
	var/must_be_servant = TRUE //If the above is true, does the human need to be a servant?
	var/target_can_be_invoker = TRUE //Does this rite work if the invoker is also the target?
	var/requires_full_power = FALSE //Does the invoker need to be an actual full-on servant, or is this available to neutered ones aswell?
	var/cast_time = 0 //How long does the rite take to cast?
	var/limit = INFINITE //How often can this rite be used per round? Set this to INFINITE for unlimited, 0 for disallowed, anything above 0 for a limit
	var/times_used = 0 //How often has the rite already been used this shift?
	var/rite_cast_sound = 'sound/items/bikehorn.ogg' //The sound played when successfully casting the rite. If it honks, the one adding the rite forgot to set one (or was just lazy).

/datum/clockwork_rite/proc/try_cast(var/obj/effect/clockwork/sigil/rite/R, var/mob/living/invoker) //Performs a ton of checks to see if the invoker can cast the rite
	if(!istype(R))
		return FALSE
	if(!R || !R.loc)
		return FALSE
	var/turf/T = R.loc
	if(!T) //Uh oh something is fucky
		return FALSE

	if(limit != INFINITE && times_used >= limit) //Is the limit on casts exceeded?
		to_chat(invoker, "<span class='brass'>У этого ритуала закончились применения!</span>")
		return FALSE

	var/mob/living/carbon/human/H //This is only used if requires_human is TRUE
	if(requires_human) //In case this requires a target
		for(var/mob/living/carbon/human/possible_H in T)
			if((!must_be_servant || is_servant_of_ratvar(possible_H)) && (target_can_be_invoker || invoker != possible_H))
				H = possible_H
				break
		if(!H)
			to_chat(invoker, "<span class='brass'>На сигиле отсутствует цель для ритуала!</span>")
			return FALSE

	if(required_ingredients.len) //In case this requires materials
		var/is_missing_materials = FALSE
		for(var/I in required_ingredients)
			var/obj/item/Material = locate(I) in T
			if(!Material)
				is_missing_materials = TRUE
				break
		if(is_missing_materials)
			var/still_required_string = ""
			for(var/i = 1 to required_ingredients.len)
				var/obj/O = required_ingredients[i]
				if(i != 1)
					still_required_string += ", "
				still_required_string += "a [initial(O.name)]"
			to_chat(invoker, "<span class='brass'>Для этого ритуала пока не хватает некоторых материалов. Вам потребуется [still_required_string].</span>")
			return FALSE

	if(power_cost) //If this costs power
		if(!get_clockwork_power(power_cost))
			to_chat(invoker, "<span class='brass'>Для этого ритуала недостаточно энергии!</span>")
			return FALSE
	R.performing_rite = TRUE
	if(!do_after(invoker, cast_time, target = R))
		to_chat(invoker, "<span class='warning'>Ваш ритуал прерван.</span>")
		R.performing_rite = FALSE
		return FALSE
	. = cast(invoker, T, H)
	if(!.)
		to_chat(invoker, "<span class='warning'>Вы не смогли использовать [name]</span>")
		post_cast(FALSE)
	else
		to_chat(invoker, "<span class='warning'>Вы успешно применили [name]</span>")
		post_cast(TRUE)
	R.performing_rite = FALSE
	return

/datum/clockwork_rite/proc/cast(var/mob/living/invoker, var/turf/T, var/mob/living/carbon/human/target) //Casts the rite and uses up ingredients. Doublechecks some things to prevent bypassing some restrictions via funky timing or badminnery.
	if(!T || !invoker)
		return FALSE
	if(requires_human && !target)
		return FALSE
	if(power_cost && !get_clockwork_power(power_cost))
		return FALSE
	adjust_clockwork_power(-power_cost)
	if(limit != INFINITE && times_used >= limit)
		return FALSE
	if(required_ingredients.len)
		var/is_missing_materials = FALSE
		for(var/I in required_ingredients)
			var/obj/item/Material = locate(I) in T
			if(!Material)
				is_missing_materials = TRUE
				break
			qdel(Material)
		if(is_missing_materials)
			return FALSE
	playsound(T, rite_cast_sound, 50, 2)
	return TRUE

/datum/clockwork_rite/proc/post_cast(var/cast_succeeded)
	if(cast_succeeded)
		times_used++
	return TRUE

/datum/clockwork_rite/proc/build_info() //Constructs the info text of a given rite, based on the vars of the rite
	. = ""
	. += "<span class='brass'>Это <b>[name]</b>.\n"
	. += "[desc]\n"
	. += "Требуется: "
	if(required_ingredients.len)
		var/material_string = ""
		for(var/i = 1 to required_ingredients.len)
			var/obj/O = required_ingredients[i]
			if(i != 1)
				material_string += ", "
			material_string += "a [initial(O.name)]"
		. += "[material_string].\n"
	else
		. += "</span><span class='inathneq_small'><b>нет</b><span class='brass'> материалов.\n"
	. += "Он [power_cost >= 0 ? "потребляет " : "генерирует "]<span class='inathneq_small'><b>[power_cost ? "[power_cost]" : "ноль"] </b><span class='brass'>энергии.\n"
	. += "<span class='inathneq_small'><b>[requires_human ? "Требуется человек" : "Не требуется человек"]</b><span class='brass'> в качестве цели.\n"
	if(requires_human)
		. += "Цель <span class='inathneq_small'><b>[must_be_servant ? "не может быть" : "может быть"]</b><span class='brass'> не слугой.\n"
		. += "Целью <span class='inathneq_small'><b>[target_can_be_invoker ? "может быть" : "не может быть"]</b><span class='brass'> вызывающий ритуал.\n"
	. += "Он требует <span class='inathneq_small'><b>[cast_time/10]</b><span class='brass'> секунд[(cast_time/10) % 10 == 1 && (cast_time/10) % 100 != 11 ? "а" : ((cast_time/10) % 10 >= 2 && (cast_time/10) % 10 <= 4 && ((cast_time/10) % 100 < 10 || (cast_time/10) % 100 >= 20) ? "ы" : "")].\n"
	. += "Он был использован <span class='inathneq_small'><b>[times_used]</b><span class='brass'> раз, из <span class='inathneq_small'><b>[limit != INFINITE ? "[limit]" : "бесконечности"]</b><span class='brass'> доступных использований.</span>"

//Adds a organ or cybernetic implant to a servant without the need for surgery. Cannot be used with brains for.. reasons.
/datum/clockwork_rite/advancement
	name = "Rite of Advancement"
	desc = "Этот ритуал используется для того, чтобы оснастить слугу органами или кибернетическими имплантами. Для проведения обряда на печать необходимо положить выбранный орган, а также самого слугу и необходимые ингредиенты."
	required_ingredients = list(/obj/item/assembly/prox_sensor, /obj/item/stock_parts/cell)
	power_cost = 500
	requires_human = TRUE
	cast_time = 40
	rite_cast_sound = 'sound/magic/blind.ogg'

/datum/clockwork_rite/advancement/cast(var/mob/living/invoker, var/turf/T, var/mob/living/carbon/human/target)
	var/obj/item/organ/O = locate(/obj/item/organ) in T
	if(!O)
		return FALSE
	if(istype(O, /obj/item/organ/brain)) //NOPE
		return FALSE
	. = ..()
	if(!.)
		return FALSE
	O.Insert(target)
	new /obj/effect/temp_visual/ratvar/sigil/transgression(T)

//Heals all wounds (not damage) on the target, causing toxloss proportional to amount of wounds healed. 10 damage per wound.
/datum/clockwork_rite/treat_wounds
	name = "Rite of Woundmending"
	desc = "Этот ритуал используется для исцеления ран слуги, находящегося на руне. Он наносит урон от яда, пропорциональный количеству исцеленных ран. Это может оказаться смертельным, если ритуал проводится на цель, находящуюся в критическом состоянии."
	required_ingredients = list(/obj/item/stock_parts/cell, /obj/item/healthanalyzer, /obj/item/reagent_containers/food/drinks/bottle/holyoil)
	power_cost = 300
	requires_human = TRUE
	must_be_servant = FALSE
	target_can_be_invoker = FALSE
	cast_time = 80
	rite_cast_sound = 'sound/magic/staff_healing.ogg'

/datum/clockwork_rite/treat_wounds/cast(var/mob/living/invoker, var/turf/T, var/mob/living/carbon/human/target)
	if(!target)
		return FALSE
	if(!target.all_wounds || !target.all_wounds.len)
		to_chat(invoker, "<span class='inathneq_small'>[target.ru_who(TRUE)] не требует лечения.</span>")
		return FALSE
	.= ..()
	if(!.)
		return FALSE
	target.adjustToxLoss(10 * target.all_wounds.len)
	for(var/i in target.all_wounds)
		var/datum/wound/mended = i
		mended.remove_wound()
	to_chat(target, "<span class='warning'>Вы чувствуете, как заживают ваши раны, но вас охватывает сильная тошнота.</span>")
	new /obj/effect/temp_visual/ratvar/sigil/vitality(T)

//Summons a brass claw implant on the sigil, which can extend a claw that benefits from repeatedly attacking a single target. Can only be cast a limited amount of times.
/datum/clockwork_rite/summon_claw
	name = "Rite of the Claw"
	desc = "Призывает специальный имплант для руки, который, будучи установленным на конечность слуги, позволит ему по желанию выдвигать и втягивать когти. При проведении обряда не оставляйте на этой руне импланты, которые хотите сохранить."
	required_ingredients = list(/obj/item/stock_parts/cell, /obj/item/organ/cyberimp, /obj/item/assembly/flash)
	power_cost = 1000
	cast_time = 60
	limit = 4
	rite_cast_sound = 'sound/magic/clockwork/fellowship_armory.ogg'

/datum/clockwork_rite/summon_claw/cast(var/mob/living/invoker, var/turf/T, var/mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE
	var/obj/item/organ/cyberimp/arm/clockwork/claw/CL = new /obj/item/organ/cyberimp/arm/clockwork/claw(T)
	CL.visible_message("<span class='warning'>[CL] появляется из ниоткуда!</span>")
	new /obj/effect/temp_visual/ratvar/sigil/transmission(T,2)

//summons a soul vessel, which is the clockwork cult version of a soul shard. It acts like a posibrain and, as long as the target has a brain, a soul shard.
/datum/clockwork_rite/soul_vessel
	name = "Rite of the Vessel" //The name of the rite
	desc = "Этот ритуал используется для призыва сосуда души, особого позитронного мозга, который делает любого, чей мозг будет помещён в него, верным Юстициару.\
	При установке в оболочку киборга созданный киборг автоматически становится слугой Ратвара."
	required_ingredients = list(/obj/item/stack/cable_coil, /obj/item/stock_parts/cell, /obj/item/organ/cyberimp)
	power_cost = 2500 //These things are pretty strong, I won't lie
	requires_full_power = TRUE
	cast_time = 50
	limit = INFINITE
	rite_cast_sound = 'sound/magic/summon_guns.ogg'

/datum/clockwork_rite/soul_vessel/cast(var/mob/living/invoker, var/turf/T, var/mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE
	var/obj/item/mmi/posibrain/soul_vessel/SV = new /obj/item/mmi/posibrain/soul_vessel(T)
	SV.visible_message("<span class='warning'>[SV] появляется из ниоткуда!</span>")
	new /obj/effect/temp_visual/ratvar/sigil/transmission(T,2)


/datum/clockwork_rite/cyborg_transform
	name = "Rite of the Divine Form"
	desc = "Этот ритуал позволяет вознестись в киборга, получая доступ к уникальным писаниям и набору снаряжения, зависящему от выбранного модуля. Подробнее о каждом модуле смотреть на вики. Несовместимо с Улучшенной формой."
	required_ingredients = list(/obj/item/mmi/posibrain, /obj/item/stack/cable_coil, /obj/item/stock_parts/cell/super, /obj/item/bodypart/l_arm/robot, /obj/item/bodypart/r_arm/robot, /obj/item/bodypart/chest/robot, /obj/item/bodypart/head/robot, /obj/item/bodypart/r_leg/robot, /obj/item/bodypart/l_leg/robot)
	power_cost = 20000
	requires_human = TRUE
	requires_full_power = FALSE
	cast_time = 100
	limit = INFINITE
	rite_cast_sound = 'sound/magic/disable_tech.ogg'

/datum/clockwork_rite/cyborg_transform/cast(var/mob/living/invoker, var/turf/T, var/mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE
	if(isclockworkgolem(target))
		return FALSE
	target.visible_message("<span class='warning'>Роботизированные детали притягиваются к [target], а глаза новой конструкции светятся ярко-желтым светом!</span>")
	var/mob/living/silicon/robot/R = target.Robotize()
	R.cell = new /obj/item/stock_parts/cell/super(R)//takes one to use the rite to begin with
	new /obj/effect/temp_visual/ratvar/sigil/transmission(T,2)

/datum/clockwork_rite/golem_transform
	name = "Rite of the Enhanced Form"
	desc = "Этот обряд позволяет избавиться от плоти и превратиться в часового автоматона, что обеспечивает иммунитет ко многим опасностям окружающей среды, а также повышает устойчивость к получаемому урону. Несовместим с Божественной формой."
	required_ingredients = list(/obj/item/mmi/posibrain, /obj/item/stock_parts/cell/super, /obj/item/bodypart/l_arm/robot, /obj/item/bodypart/r_arm/robot, /obj/item/bodypart/chest/robot, /obj/item/bodypart/head/robot, /obj/item/bodypart/r_leg/robot, /obj/item/bodypart/l_leg/robot)
	power_cost = 20000
	requires_human = TRUE
	requires_full_power = FALSE
	cast_time = 100
	limit = INFINITE
	rite_cast_sound = 'sound/magic/disable_tech.ogg'


/datum/clockwork_rite/golem_transform/cast(var/mob/living/invoker, var/turf/T, var/mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE
	target.visible_message("<span class='warning'>Роботизированные детали притягиваются к [target], а глаз гуманоидной фигуры светится внутренним пламенем!</span>")
	to_chat(target, "<span class='bold alloy'>Сила этого обряда превращает ваше тело в часовой механизм! Теперь вы защищены от многих опасностей, а ваше тело стало более устойчивым к повреждениям!</span>")
	target.set_species(/datum/species/golem/clockwork/no_scrap)
	new /obj/effect/temp_visual/ratvar/sigil/transmission(T,2)

#undef INFINITE
