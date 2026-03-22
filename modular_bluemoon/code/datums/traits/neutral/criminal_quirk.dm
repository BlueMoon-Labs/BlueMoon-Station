GLOBAL_VAR_INIT(bluemoon_criminal_quirk_warden_name, "") // имя для вардена, чтобы во всех записях было одинаковым
GLOBAL_VAR_INIT(bluemoon_criminal_quirk_sergeants_names, "")
GLOBAL_VAR_INIT(bluemoon_criminal_quirk_hos_name, "")
GLOBAL_VAR_INIT(bluemoon_criminal_quirk_commander_name, "")
GLOBAL_LIST_EMPTY(bluemoon_criminal_characters)

#define ISSUER_TYPE_SECURITY_OFFICER 	1 // типы написания для корректировки послесловий, чтобы коммандер не писал "я увольняюсь"
#define ISSUER_TYPE_SECURITY_WARDEN		2
#define ISSUER_TYPE_SECURITY_SERGEANT 	3
#define ISSUER_TYPE_SECURITY_HEAD 		4
#define ISSUER_TYPE_COMMANDER			5
#define ISSUER_TYPE_INTERN 				6

/datum/quirk/bluemoon_criminal
	name = "Нарушитель закона"
	desc = "Пока вы были вне станции, вы успели что-то натворить, а может даже и в прошлые смены. В вашем личном деле будет находиться запись о нарушении (или даже нескольких) \
	статей из 100-ой и 200-ой категорий. Нужно будет как-то решить вопрос со службой безопасности... В добавок, ваш персонаж может не знать, что именно он натворил. \
	Если повезёт, статус ареста с начала смены не будет выставлен вовсе, оставляя только заметку в базе, которую могут не заметить."
	value = 0
	gain_text = span_warning("Ты любишь преступать закон, не так ли?")
	on_spawn_immediate = FALSE

/datum/quirk/bluemoon_criminal/on_spawn()
	. = ..()
	if(!GLOB.bluemoon_criminal_quirk_warden_name)
		GLOB.bluemoon_criminal_quirk_warden_name = random_unique_name(pick(MALE,FEMALE))
		GLOB.bluemoon_criminal_quirk_sergeants_names = random_unique_name(pick(MALE,FEMALE))
		GLOB.bluemoon_criminal_quirk_hos_name = random_unique_name(pick(MALE,FEMALE))
		GLOB.bluemoon_criminal_quirk_commander_name = random_unique_name(pick(MALE,FEMALE))

	var/mob/living/carbon/human/H = quirk_holder
	var/time_before_creating_crimes = 1 MINUTES
	if(quirk_holder.real_name in GLOB.bluemoon_criminal_characters)
		qdel(src) // Предотвращает повторную выдачу квирка, если персонажа актуализируют
		return
	H.start_create_security_crime_timer(time_before_creating_crimes)
	addtimer(CALLBACK(src, PROC_REF(on_crime_creation)), time_before_creating_crimes + 10 SECONDS, TIMER_DELETE_ME) // Если вызвать qdel сразу после объявления таймера, будет рантайм

/datum/quirk/bluemoon_criminal/Destroy()
	if(!(quirk_holder.real_name in GLOB.bluemoon_criminal_characters))
		GLOB.bluemoon_criminal_characters += quirk_holder.name
	. = ..()

/datum/quirk/bluemoon_criminal/proc/on_crime_creation()
	qdel(src)

/mob/living/carbon/human/proc/start_create_security_crime_timer(var/time_to_create_crimes = 1 MINUTES) // таймер меньше времени, чем занимает старт раунда, может привести к отсутствию внесения данных, т.к. нет БД
	addtimer(CALLBACK(src, /mob/living/carbon/human/proc/create_security_crime), time_to_create_crimes, TIMER_UNIQUE|TIMER_DELETE_ME)

/mob/living/carbon/human/proc/create_security_crime()
	var/datum/data/record/target_records = GLOB.data_core.security_by_name[name]
	if(!target_records)
		to_chat(src, span_danger("Кажется, у вас не существует базы данных, чтобы добавить в неё нарушения закона."))
		return

	// Профы жертв
	var/list/victim_job_generic = list( // обычные профессии
		"офицер СБ", "врач", "старший сотрудник", "ботаник", "ассистент", "бармен",
		"повар", "библиотекарь", "механик", "психолог", "священник", "продавец", "уборщик")
	var/list/victim_job_senior = list( // профессии посерьезнее
		"СЕ", "СИ", "Старший Инженер", "Главный Инженер", "КМ", "Квартирмейстер", "Каптёр",
		"СМО", "Старший Врач", "Главврач", "Офицер Командования", "Офицер Мостика")
	var/list/victim_job_command = list( // за оскорбление этих людей можно сесть
		"ГП", "ХОП", "Глава Персонала", "Капитан", "Адмирал НТ", "Директор Сектора", "Администратор",
		"НТР", "Представитель Корпорации", "Представитель НТ", "Представитель Синдиката", "Адмирал Синдиката")

	// Фактическая информация о заметке в базе данных
	var/crime_time = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)  //"[rand(0,23)]:[rand(0,59)]:[rand(0,59)]"
	var/crime_issued_by_officer = "[random_unique_name(pick(MALE,FEMALE))]"
	var/crime_issued_by_officer_type = ISSUER_TYPE_SECURITY_OFFICER
	switch(rand(1,10))
		if(1 to 5)
			crime_issued_by_officer = "Central Command Security Officer [random_unique_name(pick(MALE,FEMALE))]"
		if(6)
			crime_issued_by_officer = "Central Command Warden [GLOB.bluemoon_criminal_quirk_warden_name]"
			crime_issued_by_officer_type = ISSUER_TYPE_SECURITY_WARDEN
		if(7)
			crime_issued_by_officer = "Central Command Security Sergeant [GLOB.bluemoon_criminal_quirk_sergeants_names]"
			crime_issued_by_officer_type = ISSUER_TYPE_SECURITY_SERGEANT
		if(8)
			crime_issued_by_officer = "Central Command Head Of Security [GLOB.bluemoon_criminal_quirk_hos_name]"
			crime_issued_by_officer_type = ISSUER_TYPE_SECURITY_HEAD
		if(9)
			crime_issued_by_officer = "Central Command Commander [GLOB.bluemoon_criminal_quirk_commander_name]"
			crime_issued_by_officer_type = ISSUER_TYPE_COMMANDER
		if(10)
			crime_issued_by_officer = "Central Command Intern [random_unique_name(pick(MALE,FEMALE))]"
			crime_issued_by_officer_type = ISSUER_TYPE_INTERN

	target_records.fields["criminal"] = SEC_RECORD_STATUS_ARREST
	sec_hud_set_security_status()

	to_chat(src, span_info("OOC: Наличие квирка нарушителя НЕ ЯВЛЯЕТСЯ оправданием для самоантагонизма. Он создан для интересных ситуаций и взаимодействия СБ с персоналом на почве нарушений вне станции. Be cool."))

	var/know_about_crime_title = pick( // заголовок
	"Вы нарушили закон!", "За вами охотятся арбитры!", "Ваши нарушения не остались без внимания!", "О вас не забыли!", "О вас не забудут!", \
	"Вы в розыске!", "За вами охотится охрана!", "Охрана на хвосте!", "WOOP, WOOP - THIS IS SOUND OF THE POLICE!")

	var/crime_list = pick(6;1, 3;2, 1;3)
	for(var/i in 1 to crime_list)

		// Переменные для жертв преступлений
		var/victim_job = pick(victim_job_generic)
		var/victim_name = "WRONG, REPORT2DEV" // имя жертвы преступления
		switch(rand(1,80))
			if(1 to 20)
				victim_name = random_unique_name(MALE)
			if(21 to 40)
				victim_name = random_unique_name(FEMALE)
			if(41 to 50)
				victim_name = "[pick(GLOB.posibrain_names)]"
				if(prob(50))
					victim_name += "-[rand(1,999)]"
			if(51 to 55)
				victim_name = random_unique_lizard_name(MALE)
			if(56 to 60)
				victim_name = random_unique_lizard_name(FEMALE)
			if(61 to 65)
				victim_name = random_unique_moth_name()
			if(66 to 70)
				victim_name = random_unique_plasmaman_name()
	//		if(71 to 80) (нет файла)
	//			victim_name = random_unique_arachnid_name()
			if(71 to 75)
				victim_name = vox_name()
			if(76 to 80)
				victim_name = random_unique_ethereal_name()

		// Места преступлений
		var/possible_random_places = pick("бара","кафе","брига","мостика","медицинского отсека","сада","инженерного отсека","голодека","общежития","жилого комплекса","бильярдной","клуба","VR-зала","развлекательного центра")

		// Сообщения игроку в случае, если он знает, что совершил преступление.
		var/know_about_crime = FALSE
		var/know_about_crime_description // описание ниже заголовка
		if(prob(50))
			know_about_crime = TRUE

		// Нарушения для базы данных
		var/crime_number = "???" // Номер статьи
		var/crime_description = "-" // Описание нарушения
		switch(rand(1,16))


	// СТАТЬИ 100-ОЙ КАТЕГОРИИ
			if(1) // Порча имущества
				crime_number = "100"
				crime_description = pick(\
				"Порча [pick("имущества","личных вещей","пожитков")] [pick("[victim_name]","[victim_name] ([victim_job])")]")
				know_about_crime = TRUE
				know_about_crime_description = pick(\
				"С трудом помнится прошлый вечер... Кажется, вы что-то отобрали у [victim_name] и сломали. Даже не помните, почему.", \
				"Вы вспоминаете, что устроили перепалку с [victim_name] и даже что-то у него испортили. Так и надо, мудаку.")

			if(2) // Оскорбления младших глав
				victim_job = pick(victim_job_senior)
				crime_number = "101"
				crime_description = pick(\
				"[pick("Выкрикивал[ru_a()] оскорбительные выражения о", "Очень много ругани о", "Оскорбление", "Оскорбления", "Унижение личного достоинства")] [victim_name] ([victim_job])")
				know_about_crime_description = pick("Кажется, вы наговорили много лишнего и оскорбительного в адрес [victim_name]... Кажется, это был [victim_job]?...")

			if(3) // Оскорбления младших сотрудников
				crime_number = "101"
				crime_description = pick(\
				"[pick("Выкрикивал[ru_a()] оскорбительные выражения о", "Очень много ругани о", "Оскорбление", "Оскорбления", "Унижение личного достоинства")] [victim_name] ([victim_job])")
				know_about_crime_description = pick("Кажется, вы наговорили много лишнего и оскорбительного в адрес [victim_name]... Это кажется был [victim_job]?")

			if(4) // Засорение эфира
				crime_number = "101"
				crime_description = pick(\
				"[pick("Засорял[ru_a()] эфир", "Неприлично спорил[ru_a()] в радиоканал", "Засорение рации", "Долго руга[ru_sya()] в радио")]")
				know_about_crime_description = pick("Вы очень неплохо поругались с кем-то в рацию не так давно. Почему ощущение, что это может аукнуться?")
			if(5) // Оскорбления глав/корпораций
				var/major_disgrace = FALSE
				var/major_name = pick("НаноТрейзен", "НТ", "Синдиката", "Триглава", "Корпорации")
				if(prob(50))
					major_disgrace = TRUE
					crime_description = pick(\
					"[pick("Выкрикивал[ru_a()] оскорбительные выражения о", "Очень много ругани о", "Оскорбление", "Оскорбления", "Распространние недостоверных слухов о", "Распространение клеветы о", "Распространение слухов о", "Клевета в адрес", "Оскорбление сотрудников")] [major_name]")
				else
					victim_job = pick(victim_job_command)
				crime_number = "101"
				crime_description = pick(\
				"[pick("Выкрикивал[ru_a()] оскорбительные выражения о", "Очень много ругани о", "Оскорбление", "Оскорбления", "Унижение личного достоинства")] [victim_name] ([victim_job])")
				if(major_disgrace)
					know_about_crime_description = pick("Вы не так давно кричали оскорбления в адрес [major_name]... За вами ведь не придут? Да?")
				else
					know_about_crime_description = pick("Кажется, вы наговорили много лишнего и оскорбительного в адрес [victim_name]... Кажется, это был [victim_job]?")

	// СТАТЬИ 200-ОЙ КАТЕГОРИИ
			if(6) // Драка
				crime_number = "202"
				crime_description = pick(\
				"[pick("Побил[ru_a()]","Вступил[ru_a()] в драку с","Нападение на","Напал[ru_a()] на","Атаковал[ru_a()]","Ударил[ru_a()]","Ударил[ru_a()] несколько раз")] [victim_name] ([victim_job])")
				know_about_crime_description = pick("Вы [pick("устроили драку","подрались")] с [victim_name] ([victim_job])")
				know_about_crime_description += pick(\
				", но уже плохо помните, за что.", " за оскорбление вашего родственника. Повезло, что вас оттащили друзья - иначе синяками бы не отделался.",\
				" из-за какой-то хрени... Даже стыдно сейчас.", " из-за разных политических взглядов. С такими иначе не получается.")
				know_about_crime = TRUE // Будет странно, если персонаж не будет помнить, как подрался

			if(7) // Нежелательный контакт
				victim_job = pick(victim_job_generic + victim_job_senior + victim_job_command)
				crime_number = "205"
				crime_description = pick(\
				"[pick("Приставал[ru_a()] к", "Постоянно трётся рядом с", "Сексуальное домогательство", "Унизительные сексуальные комментарии по отношению к")] [victim_name]")
				know_about_crime_description = pick(\
				"Кажется, вы были не в себе, когда пытались флиртовать с [victim_name]...",\
				"Вы переживаете - что ответит [victim_name] на ваши неловкие попытки флирта? Воспримет за шутку?",\
				"Вы на спор попытались переспать с [victim_name]. То, как вам ответили - отличная смешная история, которую можно будет рассказать друзьям.")

			if(8) // Превышение самообороны
				crime_number = "302"
				crime_description = pick(\
				"Во время драки с [victim_name] превысил[ru_a()] самооборону, чуть не убив", \
				"Добивал[ru_a()] лежавшего на полу [victim_name] после нападения на себя", \
				"Вырывал[ru_a()] [victim_name] из рук СБ и наносил[ru_a()] удары в месть за нападение", \
				"Избивал[ru_a()] нападавшего, когда он сдался")
				know_about_crime_description = pick(\
				"Вы помните, как на вас напал какой-то обмудок, из-за чего вы жёстко его избили. Охране это не понравилось, но удалось уйти.",\
				"На вас кто-то напал и пришлось защититься, но кажется, вы превысили самооборону...",\
				"Этот мудила, что влетев на вас с ножом, явно не ожидал, что один удар ногой сложит его пополам. Интересно, после пятого удара ногой в голову он вообще живой остался?")
				know_about_crime = TRUE // Будет странно, если персонаж не будет помнить, как подрался

			if(9) // Неисполнение приказа
				crime_number = "203"
				crime_description = pick(\
				"Очень долго не покидал[ru_a()] место преступления после требований офицеров охраны", \
				"Отказ от выполнения приказа в одной из смен, убытков нет", \
				"Неподчинение офицеру на таможне в требовании показать сумку. Куда-то пропал[ru_a()] вместе с ней в толпе")
				know_about_crime_description = pick(\
				"Кажется, вас о чём-то просила охрана? Почему вы только сейчас об этом вспоминаете?")

			if(10) // Незаконное пилотирование
				crime_number = "204"
				crime_description = pick(\
				"Ката[ru_sya()] на чужом экзокостюме без привязки к доступу", \
				"Убегал[ru_a()] на мехе, не возвращал, пострадавших нет", \
				"Угнал[ru_a()] мех с роботехнической палубы")
				know_about_crime = TRUE
				know_about_crime_description = pick("Вы не так давно весело покатались на мехе! Ещё веселее было смеяться над охраной, что не могла вас догнать... Правда, без меха уже не смешно.")

			if(11) // Вандализм
				crime_number = "201"
				crime_description = pick(\
				"[pick("Ломал","Бил","Крушил","Повреждал")][ru_a()] [pick("стёкла","столы","горшки","лампочки")] у [possible_random_places]", \
				"Устроил[ru_a()] погром у [possible_random_places]", \
				"Дебоширил[ru_a()] у [possible_random_places]")
				know_about_crime = TRUE
				know_about_crime_description = pick(\
				"С трудом помнится прошлый вечер... Кажется, вы что-то ломали у [possible_random_places].", \
				"Вы хорошо повеселились у [possible_random_places] с друзьями, но охрана вас разогнала. Что если они помнят вас?", \
				"Вы устроили драку у [possible_random_places], в процессе пустив в ход мебель. Чудо, что удалось избежать тогда задержания!")

			if(12) // Неуважение к умершим
				crime_number = "201"
				crime_description = pick(\
				"[pick("Нелицеприятно","Оскорбительно","Грубо","Отвратительно")] [pick("шутил[ru_a()]","выража[ru_sya()]","высказыва[ru_sya()]","отзыва[ru_sya()]","говорил[ru_a()]")] о [pick("погибших","умерших","усопших","кадаврах","трупах","ушедших","мертвых")]")
				know_about_crime_description = pick(\
				"Вы неплохо пошутили над фактом смерти, но возможно, кто-то запомнил этот поступок. Ведь так нельзя.", \
				"Вы попробовали разрядить ужасную атмосферу чёрной шуткой, но кажется, не все могли оценить... Плохое чувство.")

			if(13) // Мелкая кража
				crime_number = "206"
				crime_description = pick(\
				"[pick("Совершил[ru_a()]","Произвел[ru_a()]")] кражу [pick("фамильной ценности","личных вещей","предметов","пожитков")] [pick("[victim_name]","[victim_name] ([victim_job])")]", \
				"[pick("Украл[ru_a()]", "Своровал[ru_a()]","Выкрал[ru_a()]")] [pick("фамильную ценность","личные вещей","предметы","пожитки")] у  [pick("[victim_name]","[victim_name] ([victim_job])")]")
				know_about_crime = TRUE
				know_about_crime_description = pick(\
				"Вы помните, как что-то украли у [victim_name]... Кажется, он [victim_job].", \
				"[victim_name], [victim_job] что-то кричал о том, что его обокрали. Вы были рядом. На вас ведь не подумают? Верно?")

			if(14) // Угрозы насилием
				crime_number = "201"
				crime_description = pick(\
				"[pick("Выкрикивал[ru_a()] угрозы в адрес", "Угрозы", "Угрожал[ru_a()]", "Угрозы насилием", "Угрозы физической расправы", "Обещал[ru_a()] избить", "Обещал[ru_a()] нанести увечья",)] [victim_name] ([victim_job])")
				know_about_crime = TRUE
				know_about_crime_description = pick(\
				"Кажется, вы наговорили много лишнего в адрес [victim_name]... Вроде, это был [victim_job]? Даже обещали побить или что-то сломать. Уже тяжело вспомнить, из-за чего.",\
				"Вы обещали побить [victim_name]. Будет за языком следить в следующий раз.")

			if(15) // Незаконное пребывание
				crime_number = "207"
				crime_description = pick(\
				"[pick("Отказыва[ru_sya()] выходить из [possible_random_places] после требований покинуть зону от персонала", \
				"Не выходил[ru_a()] из [possible_random_places] по требованию от сотрудников СБ")]")
				know_about_crime_description = pick("Вас просили выйти из [possible_random_places], от чего вы отказывались.")

			if(16) // Хулиганство
				var/severity = rand(1,3)
				crime_number = "201"
				switch(severity)
					if(1)
						crime_description = pick(\
						"[pick("Разукрашивал","Портил")][ru_a()] [pick("пол","стёкла","потолок (как?)","стены","шлюзы")] у [possible_random_places]")
						know_about_crime_description = pick(\
						"Вы хорошо помните, как разукрашивали местность у [possible_random_places]. Возможно, охрана была недовольна.")
					if(2)
						crime_description = pick(\
						"[pick("Писал","Наносил")][ru_a()] оскорбительные надписи у [possible_random_places]")
						know_about_crime_description = pick(\
						"Вы хорошо помните, как писали оскорбления у [possible_random_places]. Возможно, охрана была недовольна.")
					if(3)
						crime_description = pick(\
						"Написал[ru_a()] \"[pick("СБ свиньи","СБ пидарасы","нахуй СБ","ГСБ хуесос","ГСБ пидорас","детектив ЧМО","СБ гандоны","щиткурити")]\" напротив [pick("корпуса охраны","брига","отсека охраны")]")
						know_about_crime_description = pick(\
						"Вы в холодном поту вспоминаете, как писали оскорбления в адрес охраны. Почему ощущение, что в эту смену оно может аукнуться?")
				know_about_crime = TRUE // Будет странно, если персонаж не будет помнить, как писал гадости о ГСБ

		// Оповещаем цель, если ей повезло помнить свои нарушения
		if(know_about_crime)
			if(know_about_crime_title)
				to_chat(src, span_userdanger(know_about_crime_title))
				know_about_crime_title = null
			to_chat(src, span_danger(know_about_crime_description))

		// Различные дополнения от различных должностей
		crime_description += ". "
		switch(crime_issued_by_officer_type)
			if(ISSUER_TYPE_SECURITY_OFFICER, ISSUER_TYPE_SECURITY_SERGEANT)
				if(prob(70))
					if(prob(70))
						crime_description += "[pick("Оформить не успели - поставьте там нужный статус и комментарий, как наказание понесёт",\
							"На запросы не отзыва[ru_sya()]. Сделайте что нужно и поставьте статус, а также комментарий, как наказание понесёт", \
							"Наказание не понесено", "Оформить наказание не успели", "Оформить наказание позже с занесением в комментарии", "Пока писали и подтвержила ордер, смена кончилась", \
							"Смена заканчивается, потом оформите", "На допрос не яви[ru_sya()]", \
							"Наказание не [pick("назначено","оформлено")] - [pick("произведите","оформите","накажите","сделайте что нужно")] и поставьте отметку в комментарии со статусом нужным")]."
					else
						crime_description += "[pick(\
							"Ордер сделайте пожалуйста кто-нибудь, ГСБ болеет и подписать не может", "Моя смена кончилась, пока-пока", "Я увольняюсь", "Наказывайте сами, я в этом участие принимать не буду",\
							"Какой срок ставать не сказали", crime_number,
							"Наказание не [pick("назначено","оформлено")] - [pick("произведите","оформите","накажите","сделайте что нужно")] и поставьте отметку в комментарии со статусом нужным")]."

			if(ISSUER_TYPE_SECURITY_WARDEN)
				if(prob(85))
					crime_description += "[pick("Оформить не успели - поставьте там нужный статус и комментарий, как наказание понесёт",\
						"На запросы на отзыва[ru_sya()]. Сделайте что нужно и поставьте статус, а также комментарий, как наказание понесёт",\
						"Наказание не понесено", "Оформить наказание не успели", "Оформить наказание позже с занесением в комментарии",\
						"Смена заканчивается, потом оформите", "На допрос не яви[ru_sya()]", \
						"Наказание не [pick("назначено","оформлено")] - [pick("произведите","оформите","накажите","сделайте что нужно")] и поставьте отметку в комментарии со статусом нужным")]."

			if(ISSUER_TYPE_SECURITY_HEAD)
				crime_description += "[pick("Клянусь Богом, я снесу башню тому офицеру, что [ru_ego()] отпустил. Коллеги, пожалуйста, закончите работу",\
					"У офицеров проблемы с дисциплиной, решаем по мере возможного. Наказание не выдано, выдайте самостоятельно. Рассчитываю на вас",\
					"Наказание не понесено", "Оформить наказание не успели, субъект скрылся", "Оформить наказание позже с занесением в комментарии",\
					"На допрос не яви[ru_sya()]", "Это последний день, когда я заполняю за этих дегенератов базу данных",\
					"Наказание не [pick("назначено","оформлено")] - [pick("произведите","оформите","накажите","сделайте что нужно")] и поставьте отметку в комментарии со статусом нужным")]."

			if(ISSUER_TYPE_COMMANDER)
				if(prob(50))
					crime_description += "[pick("Если вы это читаете, то возможно, ГСБ уже уволен за халатность",\
						"Поправьте, если статью неправильно указал, у меня другие дела помимо этой чертовой базы данных",\
						"Я надеюсь, что НТР доволен тем, что я делаю, сидя и строча в базе данных заместо всего персонала Службы Безопасности",\
						"Наказание не [pick("назначено","оформлено")] - [pick("произведите","оформите","накажите","сделайте что нужно")] и поставьте отметку в комментарии со статусом нужным")]."

			if(ISSUER_TYPE_INTERN)
				crime_description = "[pick(crime_number, "я кушать хочу...", "???", "Накажите там", "---")]"

		crime_description += " (Ордер обязателен)"

		// Добавление записи в БД
		var/crime = GLOB.data_core.createCrimeEntry(crime_number, crime_description, crime_issued_by_officer, crime_time, TRUE)
		GLOB.data_core.addMinorCrime(target_records.fields["id"], crime)


#undef ISSUER_TYPE_SECURITY_OFFICER
#undef ISSUER_TYPE_SECURITY_WARDEN
#undef ISSUER_TYPE_SECURITY_SERGEANT
#undef ISSUER_TYPE_SECURITY_HEAD
#undef ISSUER_TYPE_COMMANDER
#undef ISSUER_TYPE_INTERN
