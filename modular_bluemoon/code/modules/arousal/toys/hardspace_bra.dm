#define HS_MENU_MODE "Режим"
#define HS_MENU_INTENCE "Мощность"

#define HS_MODE_MSG_ALL "Массажа груди"
#define HS_MODE_MSG_NIP "Массажа сосков"

#define HS_INTENCE_OFF "Выключен"
#define HS_INTENCE_LOW "Слабый"
#define HS_INTENCE_MED "Средний"
#define HS_INTENCE_HIG "Сильный"

#define HS_LUST_MULT_ALL 0.15
#define HS_LUST_MULT_NIP 0.3

#define HS_LUST_LOW_MULT 1
#define HS_LUST_NORMAL_MULT 1.2
#define HS_LUST_HIGH_MULT 2

#define HS_TEXT_CHANCE 20

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra
	name = "Hardspace bra"
	desc = "С виду обычное белье, но сбоку наблюдается небольшая, гибкая панель."
	polychromic = FALSE

	var/mode = HS_MODE_MSG_ALL
	var/intence = HS_INTENCE_OFF

	var/mob/living/carbon/human/owner = null

	//BREASTS
	var/static/list/massageAllLow = list(
		"По всей поверхности груди разливается едва заметное тепло. Кажется, будто каждая клеточка ткани мягко пульсирует, пробуждая кожу от спячки и вызывая приятный трепет.",
		"Грудь словно окутывает невесомая вуаль из приятных вибраций. Стимуляция настолько деликатная, что она едва ощущается, но постоянно напоминает о себе своим мягким ритмом.",
		"Струйки приятного тепла медленно скользят по всей поверхности груди. Кажется, будто на кожу опустились сотни крошечных невидимых пальцев, ласкающих её одновременно.",
		"По всей области груди разливается мягкое, едва ощутимое гудение. Оно не перегружает чувства, а лишь создает приятный фон, заставляя каждую клеточку кожи ждать следующего движения.",
		"По груди разливается легкое, почти неуловимое тепло. Кажется, будто невидимые пальцы едва касаются кожи, пробуждая рецепторы.",
		"По коже груди пробегает едва ощутимая дрожь. Это очень деликатное прикосновение, которое заставляет кожу чуть-чуть вибрировать.",
		"Поверхность груди охватывает легкое давление, похожее на мягкое объятие. Оно не перетягивает, а просто дарит ощущение комфорта.",
		"По груди разливается едва уловимая волна удовольствия. Она не сильная, но заставляет кожу ощущать приятную, дразнящую чувствительность.",
		"Мои груди очень мягко принимают невидимый стержень между собой. Каждое движение едва уловимое, словно они просто нежно поглаживают его своими изгибами.",
		"Груди словно обнимают теплый стержень, создавая очень нежный и ровный ритм. Это приятное, дразнящее движение заставляет чувствовать каждую клеточку груди в унисон с ним."
	)
	var/static/list/massageAllMed = list(
		"Я ощущаю мерное покачивание всей груди, как будто она едва заметно танцует в такт моему дыханию. Это создает удивительное чувство гармонии.",
		"Грудь начинает откликаться на мягкое сжатие и разжатие. Кажется, что невидимые руки ласково поглаживают её, пробуждая чувствительность в каждой точке.",
		"Мою грудь словно нежно массируют, разгоняя приятные ощущения по всей поверхности. Это идеальный баланс между покоем и легким возбуждением.",
		"По всей поверхности груди разливается приятное тепло, словно кто-то невидимый мягко обволакивает её ладонями. Каждое движение ощущается как глубокий, ритмичный массаж.",
		"Грудь одновременно и слегка сдавливается, и оттягивается вперед. Ощущение очень живое и естественное!",
		"Кажется, что грудь нежно поглаживают кончиками пальцев, слегка прижимая к корпусу. Стимуляция идет равномерно, создавая приятное чувство объема и легкого волнения.",
		"Мои груди мягко охватывают невидимый член между собой. Они совершают уверенные движения вперед-назад, даря ровное и приятное ощущение плотного прилегания.",
		"Ощущение, будто груди обнимают член и медленно ведут его по поверхности тканей. Это спокойное, ритмичное сжатие дарит приятную пульсацию по всей площади груди.",
		"Словно невидимые руки бережно прижимают член к груди и начинают его мерное движение. Каждое скольжение ощущается как приятное тепло, распространяющееся по тканям."
	)
	var/static/list/massageAllHig = list(
		"Ощущения переходят грань удовольствия - это уже почти сладкая пытка! Вся грудь одновременно сжимается и расслабляется так интенсивно, что каждый миллиметр тканей пронзает приятная, острая дрожь.",
		"Кажется, будто на мою грудь одновременно действуют десятки невидимых рук. Они интенсивно разминают каждый сантиметр, создавая ощущение наполненности и мощного, непрерывного давления!",
		"Мои груди буквально перемалывают член между собой с огромной силой. Это мощный, глубокий массаж, при котором плоть груди одновременно давит на него и плавно скользит по поверхности!",
		"Мою грудь одновременно обнимают и дразнят, вызывая волну тепла, которая разливается по всему телу так стремительно, что трудно дышать!",
		"Мои груди словно охватили невидимые стальные объятия. Каждое движение ощущается как мощный, глубокий массаж, от которого по телу пробегает дрожь, а легкая пульсация доставляет щемящее наслаждение!",
		"Мою грудь словно охватили невидимые руки, которые начали с силой сдавливать каждый миллиметр ткани. Это интенсивное давление вызывает сладковатую боль, заставляя сердце биться чаще!",
		"Словно кто-то очень сильный и уверенный обхватил мои груди и начал быстро, почти неистово массировать их. Каждое движение передает мощный импульс, заставляющий трепетать от возбуждения!",
		"Грудь буквально трет невидимый член между собой с бешеной скоростью. Это мощное, плотное сжатие создает пульсирующий экстаз, заставляя груди едва заметно вибрировать от напряжения!"
	)
	//NIPPLE
	var/static/list/massageNipLow = list(
		"Соски едва заметно пульсируют, словно они пробуждаются от глубокого сна. Мягкое прикосновение вызывает волну тепла, которая медленно расходится по всей поверхности груди.",
		"По соскам пробегает легкий электрический ток, который совсем не бьет по нервам, а лишь ласково приглашает к дальнейшему взаимодействию. Грудь начинает едва заметно вибрировать от удовольствия.",
		"Соски наполняются приятным теплом, словно они впитывают солнечный свет. Это мягкое давление заставляет их чуть-чуть выступать вперед, предвкушая большую стимуляцию.",
		"Мягкое, ритмичное давление давит на соски, имитируя легкий массаж подушечками пальцев. Это создает приятное чувство предвкушения по всей груди.",
		"Соски отзываются на мягкую вибрацию едва заметным трепетом. Ощущение настолько изящное, что оно кажется почти гипнотическим в своей простоте и нежности.",
		"Легкое, едва уловимое тепло разливается по соскам, заставляя их слегка покалывать. Это мягкое раздражение пробуждает чувствительность кожи.",
		"Едва ощутимое давление на кончиках сосков создает приятное чувство предвкушения. Кажется, что они только-только начали просыпаться от нежного прикосновения."
	)
	var/static/list/massageNipMed = list(
		"Мои соски слегка покалывает, будто по ним пробегают крошечные искры. Это приятное чувство заставляет их едва заметно дрожать, словно они ждут чего-то большего.",
		"Соски приятно покалывает и немного стягивает. Это ощущение настолько отчетливое, что я невольно выпрямляю спину, наслаждаясь каждым мгновением.",
		"Кажется, мои соски слегка массируют изнутри. Стимуляция достаточно выразительная, чтобы вызвать приятную волну тепла, распространяющуюся по груди.",
		"Чувствую мягкое давление, как будто соски слегка прижимают к коже. Стимуляция очень приятная и стабильная, вызывая легкий трепет во всем теле.",
		"Кончики сосков слегка покалывают, будто по ним пробегает легкий электрический ток. Это приятное раздражение заставляет грудь невольно вздрагивать от предвкушения.",
		"Ощущаю, как соски постепенно округляются и становятся чувствительнее. Кажется, что кто-то очень осторожно и ритмично потирает их мягкой тканью в такт дыханию.",
		"Соски слегка потягивают, словно их тянут в разные стороны одновременно. Это приятное давление вызывает волну тепла, разливающуюся по всей поверхности груди."
	)
	var/static/list/massageNipHig = list(
		"Соски словно охватывают невидимые когтистые пальцы, которые с силой впиваются в кончики груди. Это приятная, почти острая пульсация, от которой перехватывает дыхание.",
		"Мои соски буквально взрываются от натиска, словно по ним одновременно ударяют маленькие молоточки. Это почти болезненный драйв, который заставляет сердце биться чаще от предвкушения.",
		"Мои соски будто охвачены стаей невидимых пальцев, которые одновременно сжимают их, тянут в разные стороны и кружат вокруг. Это почти агрессивное, но невероятно приятное давление создает ощущение пульсирующего жара.",
		"Невидимые пальцы буквально впиваются в кончики моих сосков, создавая ощущение множественных мелких нажатий одновременно. Это очень интенсивный процесс, заставляющий каждую мышцу груди реагировать на этот хаотичный натиск.",
		"Кажется, будто кто-то очень решительно и быстро выжимает из сосков всю энергию. Ритмичные, быстрые импульсы создают ощущение плотного, уверенного давления, которое граничит с приятным напряжением.",
		"Невидимые пальцы буквально вытягивают соски наружу, имитируя интенсивное доение. Это создает мощный поток ощущений, где каждая пульсация чувствуется как плотный, глубокий и очень быстрый захват.",
		"Как будто невидимые руки захватили мои соски и начали доить их с невероятной скоростью. Каждое сокращение ощущается как глубокий, волевой рывок, прошивающий грудь до самой глубины ткани."
	)



/datum/gear/shirt/bra/hardspace_bra
	name = "Hardspace bra"
	path = /obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/Initialize(mapload)
	. = ..()
	var/datum/action/item_action/hardspace_bra/control/button = new(src)
	button.bra = src

/*/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, list("#d9d9d9"), 1)*/

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/examine(mob/user)
	. = ..()
	. += span_notice("На дисплее управления ХардСпейс:")
	. += span_notice("	<i>Режим: <b>[mode]</b></i>")
	. += span_notice("	<i>Интенсивность: <b>[intence] режим</b></i>")

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/Destroy()
	STOP_PROCESSING(SSobj,src)
	owner = null
	. = ..()

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/equipped(mob/living/carbon/human/M, slot)
	.=..()
	if(slot == ITEM_SLOT_SHIRT)
		on_equip(M)
		return
	on_unequip(M)

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/dropped(mob/user)
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_SHIRT)
		on_unequip(user)

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/proc/on_equip(mob/user)
	if(!user)
		return
	var/mob/living/carbon/human/M = astype(user, /mob/living/carbon/human)
	if(!M)
		return
	owner = M
	START_PROCESSING(SSobj,src)

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/proc/on_unequip(mob/user)
	if(!user)
		return

	STOP_PROCESSING(SSobj,src)

	mode = HS_MODE_MSG_ALL
	intence = HS_INTENCE_OFF
	owner = null



/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/process(delta_time)
	if(intence == HS_INTENCE_OFF)
		return

	if(!owner)
		STOP_PROCESSING(SSobj,src)
		return

	var/breasts = owner.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts)
		return

	var/lust = 0

	switch(mode)
		if(HS_MODE_MSG_ALL)
			if(breasts)
				switch(intence)
					if(HS_INTENCE_LOW)
						lust += LOW_LUST * HS_LUST_LOW_MULT * HS_LUST_MULT_ALL
						if(prob(HS_TEXT_CHANCE))
							to_chat(owner, span_lewd(pick(massageAllLow)))
					if(HS_INTENCE_MED)
						lust += NORMAL_LUST * HS_LUST_NORMAL_MULT * HS_LUST_MULT_ALL
						if(prob(HS_TEXT_CHANCE))
							to_chat(owner, span_lewd(pick(massageAllMed)))
					if(HS_INTENCE_HIG)
						lust += HIGH_LUST * HS_LUST_HIGH_MULT * HS_LUST_MULT_ALL
						if(prob(HS_TEXT_CHANCE))
							to_chat(owner, span_lewd(pick(massageAllHig)))

		if(HS_MODE_MSG_NIP)
			if(breasts)
				switch(intence)
					if(HS_INTENCE_LOW)
						lust += LOW_LUST * HS_LUST_LOW_MULT * HS_LUST_MULT_NIP
						if(prob(HS_TEXT_CHANCE))
							to_chat(owner, span_lewd(pick(massageNipLow)))
					if(HS_INTENCE_MED)
						lust += NORMAL_LUST * HS_LUST_NORMAL_MULT * HS_LUST_MULT_NIP
						if(prob(HS_TEXT_CHANCE))
							to_chat(owner, span_lewd(pick(massageNipMed)))
					if(HS_INTENCE_HIG)
						lust += HIGH_LUST * HS_LUST_HIGH_MULT * HS_LUST_MULT_NIP
						if(prob(HS_TEXT_CHANCE))
							to_chat(owner, span_lewd(pick(massageNipHig)))

	owner.client?.plug13.send_emote(PLUG13_EMOTE_GROIN, lust)
	if(breasts)
		owner.handle_post_sex(lust, null, owner, breasts)



// MODE SELECTION
/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/proc/select_intence(mob/user, value)
	intence = value
	to_chat(user, span_notice("Был выбран режим мощности: [intence]."))

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/proc/select_mode(mob/user, value)
	mode = value
	to_chat(user, span_notice("Был выбран режим: [mode]."))


//ACTIONS------
/datum/action/item_action/hardspace_bra/
	var/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/bra

/datum/action/item_action/hardspace_bra/control
	name = "Control HS Bra"
	desc = "Выбор режима работы <b>бра</b>"
	button_icon_state = "nanite_repair"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	background_icon_state = "bg_hive"

/datum/action/item_action/hardspace_bra/control/Trigger()
	if(!owner)
		return
	var/mob/living/carbon/human/H = owner

	// мне все еще искренне лень писать красивый УИ
	var/picked_menu = tgui_input_list(owner, "Выберите настройку", "Панель настроек ХардСпейс Бра", list(HS_MENU_MODE, HS_MENU_INTENCE))
	if(!picked_menu)
		return
	if(picked_menu == HS_MENU_MODE)
		var/picked_mode = tgui_input_list(owner, "Выберите режим", "Панель настроек ХардСпейс Бра", list(HS_MODE_MSG_ALL, HS_MODE_MSG_NIP))
		if(!picked_mode)
			return
		bra.select_mode(H,picked_mode)
	if(picked_menu == HS_MENU_INTENCE)
		var/picked_intence = tgui_input_list(owner, "Выберите мощность", "Панель настроек ХардСпейс Бра", list(HS_INTENCE_OFF, HS_INTENCE_LOW, HS_INTENCE_MED, HS_INTENCE_HIG))
		if(!picked_intence)
			return
		bra.select_intence(H,picked_intence)

#undef HS_MENU_MODE
#undef HS_MENU_INTENCE

#undef HS_MODE_MSG_ALL
#undef HS_MODE_MSG_NIP

#undef HS_INTENCE_OFF
#undef HS_INTENCE_LOW
#undef HS_INTENCE_MED
#undef HS_INTENCE_HIG

#undef HS_LUST_MULT_ALL
#undef HS_LUST_MULT_NIP

#undef HS_LUST_LOW_MULT
#undef HS_LUST_NORMAL_MULT
#undef HS_LUST_HIGH_MULT

#undef HS_TEXT_CHANCE
