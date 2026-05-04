//predominantly positive traits
//this file is named weirdly so that positive traits are listed above negative ones

/datum/quirk/alcohol_tolerance
	name = "Устойчивость к Алкоголю"
	desc = "Эффект опьянения наступает медленней, побочные эффекты алкоголя облегчены."
	value = 1
	mob_trait = TRAIT_ALCOHOL_TOLERANCE
	gain_text = "<span class='notice'>Вы чувствуете, что могли бы осушить целую бочку спиртного!</span>"
	lose_text = "<span class='danger'>Вы более не ощущаете себя устойчивым к алкоголю. Почему-то.</span>"
	medical_record_text = "Пациент демонстрирует высокую устойчивость к алкоголю."
	flavor_quirk = TRUE

/datum/quirk/apathetic
	name = "Равнодушный"
	desc = "Вам на всё наплевать. Круто жить в таком мире, наверное."
	value = 1
	mood_quirk = TRUE
	flavor_quirk = TRUE
	medical_record_text = "Пациенту была предложена Шкала Оценки Апатии, но он не удосужился её заполнить."

/datum/quirk/apathetic/add()
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier = 0.8

/datum/quirk/apathetic/remove()
	if(quirk_holder)
		var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
		if(mood)
			mood.mood_modifier = 1 //Change this once/if species get their own mood modifiers.

/datum/quirk/drunkhealing
	name = "Пьяный Угар"
	desc = "Пьяному море по колено. В состоянии опьянения вы медленно восстанавливаетесь от полученных травм."
	value = 2
	mob_trait = TRAIT_DRUNK_HEALING
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы чувствуете, что от выпивки одни только плюсы.</span>"
	lose_text = "<span class='danger'>Вы чувствуете, что выпивка больше не облегчит боль.</span>"
	medical_record_text = "У пациента чрезвычайно ускоренный печоночный метаболизм, позволяющий исцелять раны путем употребления алкоголя."

/datum/quirk/empath
	name = "Эмпат"
	desc = "Будь то шестое чувство или тщательное изучения языка тела, вы можете с определить настроение цели посмотрев на неё."
	value = 1
	mob_trait = TRAIT_EMPATH
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы чувствуете себя в гармонии с другими.</span>"
	lose_text = "<span class='danger'>Вы чувствуете себя изолированно.</span>"
	medical_record_text = "Пациент с легкостью распознает социальные сигналы, возможно обладает ЭСВ. Необходимо последующее тестирование."

/datum/quirk/freerunning
	name = "Паркурщик"
	desc = "Вы отлично справляетесь с выполнением быстрых движений! Вы сможете залезать на столы гораздо быстрее."
	value = 2
	mob_trait = TRAIT_FREERUNNING
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы чувствуете легкость в ногах!</span>"
	lose_text = "<span class='danger'>Вы снова чувствуете себя неуклюже.</span>"
	medical_record_text = "У пациент продемонстрировал высокие показатели во время кардио-теста."

/datum/quirk/friendly
	name = "Дружелюбный"
	desc = "Вы лучше всех обнимаетесь, особенно при правильном настроении."
	value = 1
	mob_trait = TRAIT_FRIENDLY
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы хотите кого-нибудь обнять.</span>"
	lose_text = "<span class='danger'>Вы больше не чувствуете желания обниматься с другими.</span>"
	mood_quirk = TRUE
	medical_record_text = "Пациент более раскрепощен физически и имеет хорошо развитые руки. Просьба другому врачу взять на себя его дело."

/datum/quirk/jolly
	name = "Жизнерадостный"
	desc = "Иногда вы просто счастливы."
	value = 1
	mob_trait = TRAIT_JOLLY
	flavor_quirk = TRUE
	mood_quirk = TRUE
	medical_record_text = "Пациент демонстрирует постоянную жизнерадостность, необычную для окружающей обстановки. Даже слишком, если честно."
	processing_quirk = TRUE

/datum/quirk/jolly/on_process()
	if(prob(0.05))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "jolly", /datum/mood_event/jolly)

/datum/quirk/light_step
	name = "Легкая Походка"
	desc = "Вы ловки, удачливы и всегда осторожны. Хождение по разбитому стеклу и острым предметам менее болезненно и тише в вашем случае, к тому же вы не оставляете за собой следов."
	value = 1
	mob_trait = TRAIT_LIGHT_STEP
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы ступаете с лёгкостью.</span>"
	lose_text = "<span class='danger'>Вы топаете также, как и прежде.</span>"
	medical_record_text = "Ловкость пациента означает способность к скрытности."

/datum/quirk/quick_step
	name = "Быстрый Шаг"
	desc = "Во время ходьбы вы двигаетесь решительно, в своем ритме."
	value = 2
	mob_trait = TRAIT_SPEEDY_STEP
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы чувствуете себя решительно. Нельзя терять времени.</span>"
	lose_text = "<span class='danger'>Вы чувствуете себя менее решительно. К чему такая спешка?</span>"
	medical_record_text = "Пациент продемонстрировал высокие результаты в спортивной ходьбе."

/datum/quirk/musician
	name = "Музыкант"
	desc = "Вы можете настраивать ручные инструменты для игры мелодий, что снимают определенные негативные эффекты и успокаивают душу."
	value = 1
	mob_trait = TRAIT_MUSICIAN
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы знаете всё о музыкальных инструментах.</span>"
	lose_text = "<span class='danger'>Вы забываете, как работают музыкальные инструменты.</span>"
	medical_record_text = "Снимки мозга пациента показывают высокоразвитые слуховые пути."

/datum/quirk/musician/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/choice_beacon/music/B = new(get_turf(H))
	H.put_in_hands(B)
	H.equip_to_slot_if_possible(B, ITEM_SLOT_BACKPACK)
	var/obj/item/musicaltuner/musicaltuner = new(get_turf(H))
	H.put_in_hands(musicaltuner)
	H.equip_to_slot_if_possible(musicaltuner, ITEM_SLOT_BACKPACK)
	H.regenerate_icons()

/datum/quirk/selfaware
	name = "Сознательный"
	desc = "Вы хорошо знаете собственное тело и можете точно оценивать серьёзность ваших ран."
	value = 2
	mob_trait = TRAIT_SELF_AWARE
	flavor_quirk = TRUE
	medical_record_text = "У пациента поразительная способность к самодиагностике."

/datum/quirk/skittish
	name = "Шустрый"
	desc = "Вы можете прятаться при опасности. <b>Ctrl-Shift-Click</b> по закрытому шкафчику, чтобы запрыгнуть его, пока имеется доступ."
	value = 2
	flavor_quirk = TRUE
	mob_trait = TRAIT_SKITTISH
	medical_record_text = "Пациент избегает опасностей. Описывал, что прячется в контейнерах от страха."

/datum/quirk/spiritual
	name = "Духовный"
	desc = "Вы в гармонии с богами и ваши молитвы с большей вероятностью будут услышаны. Или нет."
	value = 1
	flavor_quirk = TRUE
	mob_trait = TRAIT_SPIRITUAL
	gain_text = "<span class='notice'>Ваша вера в богов крепнет.</span>"
	lose_text = "<span class='danger'>Ваша вера в богов слабнет.</span>"
	medical_record_text = "Пациент верит в высшие силы."

/datum/quirk/tagger
	name = "Граффити-Художник"
	desc = "Вы - художник с опытом. Рисуя граффити, вы тратите в два раза меньше краски."
	value = 1
	flavor_quirk = TRUE
	mob_trait = TRAIT_TAGGER
	gain_text = "<span class='notice'>Вы знаете, как правильно разрисовывать стены.</span>"
	lose_text = "<span class='danger'>Вы забываете, как правильно разрисовывать стены.</span>"
	medical_record_text = "Пациент был недавно замечен за вдыханием паров краски."

/datum/quirk/tagger/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/toy/crayon/spraycan/spraycan = new(get_turf(H))
	H.put_in_hands(spraycan)
	H.equip_to_slot(spraycan, ITEM_SLOT_BACKPACK)
	H.regenerate_icons()

/datum/quirk/voracious
	name = "Прожорливый"
	desc = "Ничто не встанет между вами и вашей едой. Вы едите в два раза быстрее!"
	value = 1
	flavor_quirk = TRUE
	mob_trait = TRAIT_VORACIOUS
	gain_text = "<span class='notice'>Вы преголодны.</span>"
	lose_text = "<span class='danger'>Жор отступает.</span>"
	medical_record_text = "Пациент демонстрирует умопомрачительную способность к приему пищи."

/datum/quirk/trandening
	name = "Глаза с Повышенной Светимостью"
	desc = "Когда новый классный имплант вышел, вы просто не могли его не купить! Вы начинаете смену с кибернетическими глазами, которые могут сиять разными цветами."
	value = 1
	gain_text = "<span class='notice'>Вы следите за последними трендами кибернетики!</span>"
	lose_text = "<span class='danger'>Высокомощные лазеры из глаз? О чем вы только думали...</span>"

/datum/quirk/trandening/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return
	var/datum/species/species = H.dna?.species
	// Species-native night vision eyes (xeno hybrid, xenochimera, lizards, etc.) — keep them; implant would strip NV and flash quirks tied to those organs.
	if(species?.mutanteyes && ispath(species.mutanteyes, /obj/item/organ/eyes/night_vision))
		return

	var/obj/item/organ/eyes/old_eyes = H.getorganslot(ORGAN_SLOT_EYES)
	var/obj/item/organ/eyes/robotic/glow/new_eyes = new
	// Glow eyes default to "000"; Insert() would overwrite prefs — preserve character colors.
	new_eyes.left_eye_color = H.left_eye_color
	new_eyes.right_eye_color = H.right_eye_color
	new_eyes.current_color_string = "#[H.left_eye_color]"

	qdel(old_eyes)
	new_eyes.Insert(quirk_holder)

/datum/quirk/trandening/remove()
	// Get targets
	var/obj/item/organ/eyes/old_eyes = quirk_holder.getorganslot(ORGAN_SLOT_EYES)
	var/mob/living/carbon/human/qurk_mob = quirk_holder

	// Check for eyes existing
	if(!old_eyes)
		return

	// Check for quirk eyes
	if(!istype(old_eyes, /obj/item/organ/eyes/robotic/glow))
		return

	// Define new eyes
	var/species_eyes = /obj/item/organ/eyes

	// Check for mutant eyes
	if(qurk_mob.dna.species && qurk_mob.dna.species.mutanteyes)
		// Set eyes to mutant type
		species_eyes = qurk_mob.dna.species.mutanteyes

	// Create new eyes item
	var/obj/item/organ/eyes/new_eyes = new species_eyes()

	// Replace eyes
	qdel(old_eyes)
	new_eyes.Insert(quirk_holder)

/datum/quirk/bloodpressure
	name = "Истинная полицитемия"
	desc = "У вас Истинная полицитемия в ремиссии, повышающая общее количество крови и скорость её восстановления!"
	value = 2 //I honeslty dunno if this is a good trait? I just means you use more of medbays blood and make janitors madder, but you also regen blood a lil faster.
	mob_trait = TRAIT_HIGH_BLOOD
	gain_text = "<span class='notice'>Вы чувствуете себя полным крови!</span>"
	lose_text = "<span class='notice'>Кажется, ваше кровяное давление понизилось.</span>"
	medical_record_text = "Анализы крови пациента показывают превышающее норму количество кровяных клеток."

/datum/quirk/bloodpressure/add()
	quirk_holder.blood_ratio = 1.2
	quirk_holder.blood_volume += BLOOD_VOLUME_NORMAL * (quirk_holder.blood_ratio - 1)

/datum/quirk/bloodpressure/remove()
	if(quirk_holder)
		quirk_holder.blood_ratio = 1

/datum/quirk/night_vision
	name = "Ночное Зрение"
	desc = "Вы видите лучше большинства в кромешной тьме."
	value = 1
	mob_trait = TRAIT_NIGHT_VISION
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Тени кажутся светлее.</span>"
	lose_text = "<span class='danger'>Всё кажется чуточку темнее.</span>"

/datum/quirk/night_vision/post_add() //BLUEMOON EDIT
	. = ..()						 //BLUEMOON ADD
	var/mob/living/carbon/human/H = quirk_holder
	H.update_sight()

/datum/quirk/night_vision/remove()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	H.update_sight()

/datum/quirk/hard_soles
	name = "Твёрдые ступни" // BLUEMOON EDIT - typo
	desc = "Вы привыкли ходить босиком, а потому осколки стекла и мусор никак не вредят вашим ногам."
	value = 1 // BLUEMOON EDIT - было 2
	mob_trait = TRAIT_HARD_SOLES
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Мусор под ногами теперь вам не помеха.</span>"
	lose_text = "<span class='danger'>Вы чувствуете, как пол под вашими ногами становится грубее.</span>"

///datum/quirk/bomber
//	name = "Подрывник-Самоубийца"
//	desc = "Благодаря своим связям с Красной Бригадой вы получили специальный имплант для самоуничтожения! Ну или почему-то вы решили ввести себе какую-то зелёную штуку из имплантера с мусорки и теперь вы научились делать что-то потрясное..."
//	value = 4
//
///datum/quirk/bomber/add()
//	. = ..()
//	var/mob/living/carbon/human/H = quirk_holder
//	if (!H)
//		return
//	var/obj/item/implant/explosive/E = new
//	E.implant(H)
//	H.update_icons()

/datum/quirk/breathing_tube
	name = "Трубка для Горлового Дыхания"
	desc = "Похоже, что вам не нравятся стандартные противогазы и прочие методы дыхания в безвоздушных условиях. Есть решение!"
	value = 1
	mood_quirk = FALSE
	processing_quirk = FALSE

/datum/quirk/breathing_tube/on_spawn()
	. = ..()

	// Create a new augment item
	var/obj/item/organ/cyberimp/mouth/breathing_tube/put_in = new

	// Apply the augment to the quirk holder
	put_in.Insert(quirk_holder, null, TRUE, TRUE)
