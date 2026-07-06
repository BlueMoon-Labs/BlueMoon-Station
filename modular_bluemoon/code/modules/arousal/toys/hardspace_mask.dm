#define HS_INTENCE_OFF "Выключен"
#define HS_INTENCE_LOW "Слабый"
#define HS_INTENCE_MED "Средний"
#define HS_INTENCE_HIG "Сильный"

#define HS_LUST_MULT 0.3

#define HS_LUST_LOW_MULT 1
#define HS_LUST_NORMAL_MULT 1.2
#define HS_LUST_HIGH_MULT 2

#define HS_TEXT_CHANCE 20

/obj/item/clothing/mask/hardspace_mask
	name = "Hardspace mask"
	desc = "С виду обычная маска, но сбоку наблюдается небольшая, гибкая панель."
	icon_state = "sterile"
	item_state = "sterile"
	w_class = WEIGHT_CLASS_TINY
	flags_inv = HIDEFACE
	flags_cover = MASKCOVERSMOUTH
	visor_flags_inv = HIDEFACE
	visor_flags_cover = MASKCOVERSMOUTH
	//actions_types = list(/datum/action/item_action/adjust)
	mutantrace_variation = STYLE_MUZZLE

	var/intence = HS_INTENCE_OFF

	var/mob/living/carbon/human/owner = null

	//PENITRATE
	var/static/list/penitrateLow = list(
		"Ощущаю легкое давление в области нёба. Маленький выступ плавно перемещается по поверхности, словно исследуя каждый изгиб внутри рта",
		"Легкое, едва уловимое прикосновение наполняет рот мягкой формой. Оно словно танцует на кончике языка, обещая что-то большее, чем просто тишину.",
		"Оно входит так осторожно, будто боится нарушить покой. Внутри рта чувствуется мягкое давление, которое медленно пробуждает рецепторы.",
		"Словно шелковая нить проскользнула в рот - едва заметное движение формы дразнит язык, заставляя непроизвольно прикрывать глаза от удовольствия.",
		"Тихое и ритмичное движение внутри рта создает ощущение легкого тепла. Это мягкое ласкание, которое лишь намекает на грядущую глубину.",
		"Едва ощутимое движение проникает глубже в рот, мягко касаясь задней стенки горла. Это нежный импульс, пробуждающий желание большего."
	)
	var/static/list/penitrateMed = list(
		"Во рту пульсирует мягкая форма, имитируя неспешный оральный секс. Она ласкает каждый сантиметр полости рта, заставляя забыть обо всем вокруг.",
		"В ротовой полости разворачивается плотный объем, который мягко давит на язык. Стимуляция ощущается естественно, как будто кто-то нежно ласкает меня изнутри.",
		"Фаллическая форма проникает в рот, заполняя его до краев и создавая приятное давление. Движения плавные, позволяя полностью сосредоточиться на удовольствии.",
		"Форма члена проникает глубоко, едва касаясь задней стенки горла. Доставляя идеальный уровень удовольствия!",
		"Ритмичное скольжение формы вперед-назад заполняет рот полностью. Ощущения становятся всё более отчетливыми, позволяя полностью погрузиться в удовольствие от каждого движения",
		"Форма уверенно прорезает путь внутрь моего ротика, двигаясь с идеальным ритмом. Каждое движение вперед ощущается как глубокий вдох, а движение назад — как мягкое освобождение.",
		"Форма плавно скользит вперед и назад по нёбу, заполняя рот до самого конца. Каждое движение ощущается уверенно и ритмично, словно в такт спокойному биению сердца."
	)
	var/static/list/penitrateHig = list(
		"Всё моё горло словно разрывает мощный поток энергии. Твердый член внутри проникает так глубоко, что каждый толчок ощущается до самых уголков души, заставляя меня едва не терять сознание от этого напора!",
		"Я чувствую каждый миллиметр поверхности внутри себя. Горло растягивается до предела, принимая это конский фаллос, которая буквально прошивает мое тело насквозь!",
		"Форма внутри становится невероятно выраженной. Я чувствую, как она буквально выталкивает воздух из моих легких, заполняя рот и горло своей безумной, стремительной динамикой!",
		"Моё горло словно поглощает этот огромный член целиком. Стимуляция настолько стремительная и глубокая, что я чувствую каждую вену и изгиб в каждой секунде этого бешеного, почти болезненного удовольствия!",
		"Чередующиеся толчки проникают в самые глубины горла, едва не заставляя захлебываться. Каждое движение настолько мощное и глубокое, заставляет меня едва не терять сознание!",
		"Ощущения стали острыми и дерзкими. Огромный член буквально вбивается в мой ротик, заставляя мышцы горла непроизвольно сокращаться в ответ на этот напористый, дикий ритм!"
	)

/datum/gear/mask/hardspace_mask
	name = "Hardspace mask"
	path = /obj/item/clothing/mask/hardspace_mask

/obj/item/clothing/mask/hardspace_mask/Initialize(mapload)
	. = ..()
	var/datum/action/item_action/hardspace_mask/control/button = new(src)
	button.mask = src

/*/obj/item/clothing/mask/hardspace_mask/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, list("#d9d9d9"), 1)*/

/obj/item/clothing/mask/hardspace_mask/examine(mob/user)
	. = ..()
	. += span_notice("На дисплее управления ХардСпейс:")
	. += span_notice("	<i>Интенсивность: <b>[intence] режим</b></i>")

/obj/item/clothing/mask/hardspace_mask/Destroy()
	STOP_PROCESSING(SSobj,src)
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_TONGUELESS_SPEECH, src)
		owner = null
	. = ..()

/obj/item/clothing/mask/hardspace_mask/equipped(mob/living/carbon/human/M, slot)
	.=..()
	if(slot == ITEM_SLOT_MASK)
		on_equip(M)
		return
	on_unequip(M)

/obj/item/clothing/mask/hardspace_mask/dropped(mob/user)
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_MASK)
		on_unequip(user)

/obj/item/clothing/mask/hardspace_mask/proc/on_equip(mob/user)
	if(!user)
		return
	var/mob/living/carbon/human/M = astype(user, /mob/living/carbon/human)
	if(!M)
		return
	owner = M
	if(intence == HS_INTENCE_HIG)
		ADD_TRAIT(owner, TRAIT_TONGUELESS_SPEECH, src)
	START_PROCESSING(SSobj,src)

/obj/item/clothing/mask/hardspace_mask/proc/on_unequip(mob/user)
	if(!user)
		return

	STOP_PROCESSING(SSobj,src)
	intence = HS_INTENCE_OFF

	if(!owner)
		return
	REMOVE_TRAIT(owner, TRAIT_TONGUELESS_SPEECH, src)
	owner = null



/obj/item/clothing/mask/hardspace_mask/process(delta_time)
	if(intence == HS_INTENCE_OFF)
		return

	if(!owner)
		STOP_PROCESSING(SSobj,src)
		return

	var/lust = 0

	switch(intence)
		if(HS_INTENCE_LOW)
			lust += LOW_LUST * HS_LUST_LOW_MULT * HS_LUST_MULT
			if(prob(HS_TEXT_CHANCE))
				to_chat(owner, span_lewd(pick(penitrateLow)))
		if(HS_INTENCE_MED)
			lust += NORMAL_LUST * HS_LUST_NORMAL_MULT * HS_LUST_MULT
			if(prob(HS_TEXT_CHANCE))
				to_chat(owner, span_lewd(pick(penitrateMed)))
		if(HS_INTENCE_HIG)
			lust += HIGH_LUST * HS_LUST_HIGH_MULT * HS_LUST_MULT
			if(prob(HS_TEXT_CHANCE))
				to_chat(owner, span_lewd(pick(penitrateHig)))

			if(owner.getOxyLoss() < 20)
				owner.adjustOxyLoss(25 - owner.getOxyLoss())

			if(prob(50))
				if(owner.client?.prefs.cit_toggles & SEX_JITTER)
					owner.do_jitter_animation()

			if(prob(10))
				owner.emote(pick("gasp", "gag", "choke"))

			if(prob(1))
				owner.snap_choker(owner, ITEM_SLOT_NECK)

	owner.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, lust)
	owner.handle_post_sex(lust, null, owner)



// MODE SELECTION
/obj/item/clothing/mask/hardspace_mask/proc/select_intence(mob/user, value)
	intence = value
	to_chat(user, span_notice("Был выбран режим мощности: [intence]."))
	if(!owner)
		return
	if(intence == HS_INTENCE_HIG)
		ADD_TRAIT(owner, TRAIT_TONGUELESS_SPEECH, src)
	else
		REMOVE_TRAIT(owner, TRAIT_TONGUELESS_SPEECH, src)


//ACTIONS------
/datum/action/item_action/hardspace_mask/
	var/obj/item/clothing/mask/hardspace_mask/mask

/datum/action/item_action/hardspace_mask/control
	name = "Control HS Mask"
	desc = "Выбор режима работы <b>маски</b>"
	button_icon_state = "nanite_repair"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	background_icon_state = "bg_hive"

/datum/action/item_action/hardspace_mask/Trigger()
	if(!owner)
		return
	var/mob/living/carbon/human/H = owner

	// мне все еще искренне лень писать красивый УИ
	var/picked_intence = tgui_input_list(owner, "Выберите мощность", "Панель настроек ХардСпейс Маски", list(HS_INTENCE_OFF, HS_INTENCE_LOW, HS_INTENCE_MED, HS_INTENCE_HIG))
	if(!picked_intence)
		return
	mask.select_intence(H,picked_intence)

#undef HS_INTENCE_OFF
#undef HS_INTENCE_LOW
#undef HS_INTENCE_MED
#undef HS_INTENCE_HIG

#undef HS_LUST_MULT

#undef HS_LUST_LOW_MULT
#undef HS_LUST_NORMAL_MULT
#undef HS_LUST_HIGH_MULT

#undef HS_TEXT_CHANCE
