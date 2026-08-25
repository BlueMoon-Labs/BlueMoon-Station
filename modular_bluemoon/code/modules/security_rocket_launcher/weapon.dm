// Ракетница СБ «VARS» - порт с Bubberstation (modular_zubbers/code/modules/security_rocket_launcher).

/obj/item/gun/ballistic/rocketlauncher/security
	name = "\improper \"VARS\" Ракетная Система Переменного Активного Радара"
	desc = "Относительно дешёвый многоразовый ракетный комплекс, собранный умельцами из лабораторий вооружений НаноТрейзен для борьбы с докучливыми космическими пиратами. \
	Использует особые запатентованные 69-мм ракеты «выстрелил - и забудь», которые наводятся на цели с крупной радиолокационной сигнатурой: стены, полы и, что важнее всего, люди."
	magazine_wording = "ракету"

	//Иконки
	icon = 'icons/obj/weapons/sec_missile.dmi'
	icon_state = "rocketlauncher"
	item_state = "rocketlauncher"
	lefthand_file = 'icons/mob/inhands/weapons/sec_missile_inhands.dmi'
	righthand_file = 'icons/mob/inhands/weapons/sec_missile_inhands.dmi'

	//Звук
	fire_sound = 'sound/weapons/sec_missile/shoot.ogg'
	load_sound = 'sound/weapons/sec_missile/insert.ogg'

	//Внутренности
	mag_type = /obj/item/ammo_box/magazine/internal/security_rocketlauncher
	pin = /obj/item/firing_pin

	//Характеристики
	fire_delay = 2 SECONDS
	weapon_weight = WEAPON_HEAVY
	slot_flags = null

	var/self_targeting = FALSE //эмэг-взаимодействие
	var/warning_label //генерируется при первом осмотре

/obj/item/gun/ballistic/rocketlauncher/security/update_icon_state()
	if(chambered)
		icon_state = "rocketlauncher_loaded"
	else
		icon_state = "rocketlauncher"

/obj/item/gun/ballistic/rocketlauncher/security/proc/generate_warning_label()
	. = ""

	var/list/possible_good_instructions = list(
		"ПРОВЕРЬТЕ УКРЫТИЕ НА ПОВРЕЖДЕНИЯ ПЕРЕД ВЫСТРЕЛОМ",
		"ПРОВЕРЬТЕ ЗАДНЮЮ СТРУЮ ПЕРЕД ВЫСТРЕЛОМ",
		"ФРОНТОМ К ПРОТИВНИКУ",
		"ОГОНЬ ТОЛЬКО С ПЛЕЧА",
		"НЕ ИСПОЛЬЗОВАТЬ В ПОМЕЩЕНИЯХ",
		"НЕ ВДЫХАТЬ СОДЕРЖИМОЕ ТРУБЫ",
		"НЕ ВСТАВЛЯТЬ ПОСТОРОННИЕ ПРЕДМЕТЫ В ТРУБУ",
		"ИСПОЛЬЗУЙТЕ ЗАЩИТУ ДЛЯ ГЛАЗ",
		"ИСПОЛЬЗУЙТЕ ЗАЩИТУ ДЛЯ СЛУХА",
		"ДЕРЖИТЕ РОВНО ПРИ ВЫСТРЕЛЕ",
		"НЕ ШЕВЕЛИТЕСЬ ПРИ ВЫСТРЕЛЕ",
		"НЕ ВСКРЫВАЙТЕ ЭЛЕКТРОНИКУ",
	)

	var/list/possible_bad_instructions = list(
		"НЕ ЕСТЬ",
		"НЕ ПОМЕЩАТЬ ПОСТОРОННИЕ ВЕЩЕСТВА В ТРУБУ",
		"БЕРЕЧЬ ОТ ЭЛЕКТРИЧЕСКОЙ ИНФЕТТЕРЕНЦИИ", //Я видел Райана Гослинга в продуктовом магазине в Лос-Анджелесе вчера.
		"ВСЕГДА ЧИТАЙТЕ ПРЕДУПРЕЖДЕНИЕ ПЕРЕД ИСПОЛЬЗОВАНИЕМ",
		"ТОЛЬКО ДЛЯ НАРУЖНОГО ПРИМЕНЕНИЯ",
		"ГОРЯЧЕЕ",
		"ТОКСИЧНОЕ",
		"ИЗБЕГАТЬ ПОПАДАНИЯ В ГЛАЗА",
		"НЕ ХРАНИТЬ ПРИ ТЕМПЕРАТУРАХ ВЫШЕ 313.15 КЕЛЬВИНА",
		"КЛОУНЫ ДОЛЖНЫ ИСПОЛЬЗОВАТЬ ПРОДУКТ ПОД НАБЛЮДЕНИЕМ",
		"НЕ ДАВАТЬ КЛОУНУ",
		"ДЕРЖАТЬ ПОДАЛЬШЕ ОТ КЛОУНОВ",
		" НЕ ПОГРУЖАТЬ ",
		"НЕ ГЛОТАТЬ.",
		"ОПАСНО ПРИ ПРОГЛАТЫВАНИИ",
		"ПРИ ПРОГЛАТЫВАНИИ ОБРАТИТЕСЬ К ВРАЧУ",
		"НЕ НАНОСИТЬ НА ПОВРЕЖДЁННУЮ КОЖУ",
		"ПРИ ПОЯВЛЕНИИ СЫПИ ПРЕКРАТИТЕ ИСПОЛЬЗОВАНИЕ",
		"ИСПОЛЬЗОВАТЬ ТОЛЬКО ПО НАЗНАЧЕНИЮ",
		"НЕ УПРАВЛЯТЬ ТЯЖЁЛОЙ ТЕХНИКОЙ ВО ВРЕМЯ ИСПОЛЬЗОВАНИЯ",
		"МОЖЕТ ВЫЗЫВАТЬ СОНЛИВОСТЬ",
		"НИКОГДА НЕ ПРОВЕРЯЙТЕ НАЛИЧИЕ БОЕПРИПАСА С ПОМОЩЬЮ ГОРЕЮЩЕЙ СПИЧКИ",
		"НЕ ИСПОЛЬЗОВАТЬ ВО СНЕ",
		"ПРОДУКТ МОЖЕТ СОДЕРЖАТЬ: ЯЙЦА, ОРЕХИ, СОЮ И МИНДАЛЬ",
		"НЕ ВСТАВЛЯТЬ КОНЕЧНОСТИ В ТРУБУ",
		"НЕ ИСПОЛЬЗОВАТЬ ДЛЯ НАВИГАЦИИ",
		"НЕ ПРИГОДНО В ПИЩУ",
		"НЕ ИСПОЛЬЗОВАТЬ ДЛЯ ЛИЧНОЙ ГИГИЕНЫ",
		"ОПАСНОСТЬ УДУШЬЯ: МОЖЕТ СОДЕРЖАТЬ МЕЛКИЕ ДЕТАЛИ",
		"НЕ ПЫТАЙТЕСЬ",
		"МОЖЕТ РАЗДРАЖАТЬ ГЛАЗА",
		"ПОЖАРООПАСНО ПРИ ЗАРЯЖАНИИ",
		"ГИРАНТИЯ АННУЛИРУЕТСЯ ПРИ ПРОЧТЕНИИ",
		"ГИРАНТИЯ НЕ ДЕЙСТВИТЕЛЬНА",
		"МОЖЕТ РАЗДРАЖАТЬ ЧЛЕНОВ ЭКИПАЖА",
		"МОЖЕТ СОДЕРЖАТЬ ВЗРЫВЧАТКУ",
		"НЕ ПРИЧИНЯЙ ВРЕДА",
		"НЕ РУГАЙСЯ",
		"НЕ",
		"ЭТО НЕ ТЕЛЕСКОП",
		"НЕ ПРОДАЁТСЯ ОТДЕЛЬНО",
		"НЕ РЕПОСТИТЬ",
	)

	var/total_good_length_mod = FLOOR(length(possible_good_instructions) * 0.5, 1)

	//Первая половина - всегда полезные советы.
	for(var/i in 1 to total_good_length_mod)
		. += "[pick_n_take(possible_good_instructions)]<br>"

	//А вот вторая половина...
	for(var/i in 1 to total_good_length_mod)
		if(!prob(80)) // lore optimization
			. += "[pick_n_take(possible_bad_instructions)]<br>"
		else
			. += "[pick_n_take(possible_good_instructions)]<br>"

/obj/item/gun/ballistic/rocketlauncher/security/examine(mob/user)
	. = ..()

	if(isobserver(user))
		return

	// Наградим чтением только тех, кто вообще способен читать.
	if(!user.has_language(/datum/language/common, UNDERSTOOD_LANGUAGE))
		if(!user.is_blind())
			. += "<hr>Вы всматриваетесь в предупреждающую наклейку, пытаясь разобрать надписи..."
			. += span_warning("...Но вы не понимаете ни слова.")
		return

	var/obj/item/organ/eyes/eye
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		eye = carbon_user.getorganslot(ORGAN_SLOT_EYES)
	if(isnull(eye))
		return

	if(eye.damage >= eye.low_threshold || user.eye_blurry)
		. += "<hr>Вы щуритесь на предупреждающую наклейку..."
		. += span_warning("...Но буквы слишком мелкие, чтобы что-то разобрать...")
		return

	if(!warning_label)
		warning_label = generate_warning_label()

	. += span_warning("Предупреждающая наклейка на боку гласит:")

	. += span_danger(warning_label)

/obj/item/gun/ballistic/rocketlauncher/security/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(self_targeting)
		return FALSE
	self_targeting = TRUE
	balloon_alert(user, "системы наведения взломаны")
	do_sparks(2, FALSE, src)
	return TRUE

//Внутренний магазин
/obj/item/ammo_box/magazine/internal/security_rocketlauncher
	name = "missile launcher internal magazine"
	ammo_type = /obj/item/ammo_casing/caseless/security_missile
	caliber = "69mm"
	max_ammo = 1

//Отладочная ерунда.
/obj/item/gun/ballistic/rocketlauncher/security/debug
	fire_delay = 0
	mag_type = /obj/item/ammo_box/magazine/internal/security_rocketlauncher/debug
	item_flags = NEEDS_PERMIT|ABSTRACT //ABSTRACT - чтобы не спавнился в случайных рождественских подарках
	burst_size = 5

/obj/item/ammo_box/magazine/internal/security_rocketlauncher/debug
	max_ammo = 69
