/*
//////////////////////////////////////

Itching

	Not noticable or unnoticable.
	Resistant.
	Increases stage speed.
	Little transmissibility.
	Low Level.

BONUS
	Displays an annoying message!
	Should be used for buffing your disease.

//////////////////////////////////////
*/

/datum/symptom/itching

	name = "Itching"
	desc = "Вирус раздражает кожу, вызывая зуд."
	stealth = 0
	resistance = 3
	stage_speed = 3
	transmittable = 1
	level = 1
	severity = 1
	symptom_delay_min = 5
	symptom_delay_max = 25
	var/scratch = FALSE
	threshold_desc = list(
		"Передача 6" = "Увеличивает частоту зуда.",
		"Скорость стадии 7" = "Заражённый будет чесаться при зуде, получая поверхностные повреждения.",
	)

/datum/symptom/itching/Start(datum/disease/advance/A)
	if(!..())
		return
	if(A.properties["transmittable"] >= 6) //itch more often
		symptom_delay_min = 1
		symptom_delay_max = 4
	if(A.properties["stage_rate"] >= 7) //scratch
		scratch = TRUE

/datum/symptom/itching/Activate(datum/disease/advance/A)
	if(!..())
		return
	var/mob/living/carbon/M = A.affected_mob
	var/picked_bodypart = pick(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
	var/obj/item/bodypart/bodypart = M.get_bodypart(picked_bodypart)
	if(bodypart && bodypart.is_organic_limb() && !bodypart.is_pseudopart)	 //robotic limbs will mean less scratching overall
		var/can_scratch = scratch && !M.incapacitated() && get_location_accessible(M, picked_bodypart)
		M.visible_message("[can_scratch ? "<span class='warning'>[M] чешет [M.ru_ego()] [bodypart.name].</span>" : ""]", "<span class='warning'>[bodypart.name] чешется. [can_scratch ? " Вы почесали его." : ""]</span>")
		if(can_scratch)
			// Поверхностные царапины — без ролла травм/переломов (иначе разумный вирус с частым проком кладёт неизлечимые раны).
			bodypart.receive_damage(brute = 0.5, wound_bonus = CANT_WOUND)
