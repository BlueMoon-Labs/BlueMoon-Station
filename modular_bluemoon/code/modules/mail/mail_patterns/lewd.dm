/**
 *
 * ПОШЛОЕ
 *
 */

/datum/mail_pattern/lewd/heart_cum
	name = "Сердечко (with Cum)"
	description = "<3 + бутылка сами-знаете-с-чем"

	weight = MAIL_WEIGHT_RARE

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "Записка из письма"
	letter_desc = "Она немного липкая"
	letter_html = "<center><span style='font-size: 80px; color: #ba346e;'>&lt;3</span></center>"
	sender = "???"
	letter_sign = null

	letter_icon = 'icons/obj/toy.dmi'
	letter_icon_state = "sc_Ace of Hearts_syndicate"

	bad_feeling = "Письмо пахнет дешёвыми духами. Это чтобы что-то скрыть?"

	blacklisted_species = MAIL_RECIPIENT_SYNTH

/datum/mail_pattern/lewd/heart_cum/apply(mob/living/carbon/human/recipient)
	. = ..()
	var/obj/item/reagent_containers/food/condiment/milk/milky = new(parent)
	milky.reagents.remove_reagent(/datum/reagent/consumable/milk, 50)
	milky.reagents.add_reagent(/datum/reagent/consumable/semen, 50)
	milky.name = "Странная коробочка"
	if(prob(42))
		milky.name = "Cum Chalice"
	milky.desc = "Странная липковатая коробочка с белой жидкостью. Молоко или..?"

/datum/mail_pattern/lewd/heart_cum/regenerate_weight(mob/living/carbon/human/recipient)
	. = ..()
	if(.)
		if(HAS_TRAIT(recipient, TRAIT_DUMB_CUM_CRAVE) || recipient.has_quirk(/datum/quirk/succubus))
			. *= 3

/datum/mail_pattern/lewd/lewd_message
	name = "Пошлое послание"
	description = "Что-то вроде спама с предложениями перепихона. Есть особые варианты для разных рас"

	weight = MAIL_WEIGHT_DEFAULT

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "Признание"
	letter_desc = "А это точно по адресу?.."
	letter_html = "%случайное признание в любви%"
	sender = MAIL_SENDER_RANDOM_NAME
	letter_sign = "С любовью~, %%подпись%%"

	letter_icon = 'icons/obj/toy.dmi'
	letter_icon_state = "sc_Ace of Hearts_syndicate"

/datum/mail_pattern/lewd/lewd_message/apply(mob/living/carbon/human/recipient)
	initial_contents += pick(
		/obj/item/reagent_containers/food/snacks/grown/poppy,
		/obj/item/reagent_containers/food/snacks/grown/poppy/geranium,
		/obj/item/reagent_containers/food/snacks/grown/poppy/lily,
		/obj/item/bouquet/rose)
	if(isrobotic(recipient))
		initial_contents += /obj/item/stock_parts/cell/bluespace
	else
		initial_contents += /obj/item/storage/fancy/heart_box

	var/love_message = null
	if(recipient.dna?.species?.name)
		switch(recipient.dna.species.name)
			if("Human")
				love_message = "Я просто ОБОЖАЮ людей! Такие властные, сильные и умные… ммф… встретимся?"
			if("Anthropomorph")
				love_message = pick(
					"Я просто БЕЗ УМА от вульпакин! Хочу пошевелить с тобой хвостиками! Скинь аудио как ты воешь!",
					"Все таяры такие милые? Обещаю почесать за ушком когда мы встретимся <3")
			if("Xenobiological Slime Entity")
				love_message = "Легендарная гибкость и влажность слаймоменов… Хочу опробовать на себе!"
			if("Vox")
				love_message = "Все остальные такие неженки… а вот воксы — самое то. Особенно пираты, ух… Встретимся?"
			if("Anthropomorphic Plant")
				love_message = "Надеюсь что диона переживёт отсутствие света под одеялом?~"
			if("Abductor")
				love_message = "Ты действительно абдуктор... Ты похитил%%А%% моё сердечко! <3"
			if("Arachnid")
				love_message = "А что ты можешь делать всеми этими ручками... или ножками? Хи-хи~"
			if("Teshari")
				love_message = "А все тешари такие милые? И... нет, это не Лазарь. Честно!"
			if("Dwarf")
				love_message = "Такой сильный и суровый дворф... И размер совсем не главное! Встретимся?~"
			if("Felinid")
				love_message = "Что может быть лучше, чем фелинид на коленках? Помурлычешь в ответном письме? <3"
			if("Xenomorph Hybrid")
				love_message = "Ксеноморф?... Одолжишь мне своего лицехвата?~"
	if(isrobotic(recipient))
		love_message = "Говорят что синтетики не устают в постели… это правда? Если так, то это свидание!"
	if(iszombie(recipient)) // некрофилы идут нахуй
		qdel(parent)
		qdel(src)
		return
	if(!love_message)
		love_message = pick(
			"Слушай, у меня мало времени. Ты хочешь большой и чистой любви? Если хочешь, то ответь. Ещё никто не ответил…",
			pick(GLOB.flirts))
	letter_html = replacetext(letter_html, "%случайное признание в любви%", love_message)
	. = ..()

/datum/mail_pattern/lewd/aphrodisiac
	name = "Афродизиак"
	description = "Несколько бутылей с афродизиаками"

	weight = MAIL_WEIGHT_UNCOMMON

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "Письмо преданному клиенту!"
	letter_desc = "На этой бумажке есть парочка розовых пятен..."
	letter_html = "Самому преданному клиенту нашего прекрасного <i>неразборчиво из-за кроцинового пятна</i> высылаем самую-самую лучшую партию товара для личной дегустации~"
	sender = "НЕРАЗБОРЧИВО"
	letter_sign = null

	letter_icon_state = "cpaper_words"

	bad_feeling = "Письмо чертовски сильно пахнет афродизиаком..."

	initial_contents = list(
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin
	)

/datum/mail_pattern/lewd/aphrodisiac_large
	name = "Много афродизиака"
	description = "Много! бутылей с афродизиаками"

	weight = MAIL_WEIGHT_EXTREMELY_RARE

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "Приказ №422"
	letter_desc = "Заляпанный пивом и кроцином листок с небрежно набросанным текстом."
	letter_html = {"Так, пидорасы слащавые, у нас горит, блять, срок по нашему основному проекту.
					 Нам нужно отправить, блять, огромную партию кроцина в какой-то гигабордель имени Трейзена,
					 который строится НТшниками для ебейшего расширения этой говноаномалии. Васёк опять проебал
					 наш грузовой шаттл, так что отправляем заказ по частям почтой НТ. У них тут какие-то ебанутые
					 блюспейс-технологии упаковки, поэтому в одной посылке можно сразу нихуёвую часть заказа притарабанить.
					 Кладу в посылку этот приказ, чтобы вы, когда протрезвели, вспомнили, на кой хуй вам эта коробка.
					 <br><br><b>P.S.ЕСЛИ КТО-ТО, БЛЯТЬ, ДОПУСТИТ, ЧТОБЫ ЭТА ХУЙНЯ ПОПАЛА НЕ ПО АДРЕСУ - Я НОГИ ИЗ ЖОПЫ ПОВЫРЫВАЮ!!!</b>"}
	sender = "Транспортный департамент Нанотрейзен"
	letter_sign = "С ебучим уважением, ваш ебучий бригадир"

	letter_icon_state = "cpaper_words"

	bad_feeling = "Письмо чертовски сильно пахнет афродизиаком..."

	initial_contents = list(
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/crocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin,
		/obj/item/reagent_containers/glass/bottle/hexacrocin
	)

/datum/mail_pattern/lewd/pregnancy
	name = "Оповещение о беременности"
	description = "Посылка с использованным тестером на беременность."

	weight = MAIL_WEIGHT_RARE

	envelope_type = MAIL_TYPE_ENVELOPE

	letter_icon_state = "scrap"

	letter_title = "!!!"
	letter_desc = "Почерк кажется очень нернвым, большая часть письма нечитаема из-за разводов от слёз. Может быть, оно не по адресу?..."
	letter_html = "...и уеха...! подл.... я подам в су...."
	sender = "Ты знаешь, от кого!!!"
	letter_sign = ""

	blacklisted_species = MAIL_RECIPIENT_SYNTH
	whitelisted_genitals = MAIL_GENITALS_MALE_FULL

/datum/mail_pattern/lewd/pregnancy/apply(mob/living/carbon/human/recipient)
	var/obj/item/pregnancytest/tester = new(parent)
	tester.name = "positive pregnancy test"
	tester.results = "positive"
	tester.update_appearance()
	. = ..()

/datum/mail_pattern/lewd/used_condom
	name = "Использованный презерватив"
	description = "Письмо с просьбой не оставлять больше презерватив и использованный презерватив"

	weight = MAIL_WEIGHT_DEFAULT

	letter_title = "Признание"
	letter_desc = "Черт, не могу вспомнить..."
	letter_html = "%%гневное письмо%%"
	sender = MAIL_SENDER_RANDOM_NAME
	letter_sign = ""

	bad_feeling = "Кажется, письмо слегка липкое..."

	blacklisted_species = MAIL_RECIPIENT_SYNTH
	whitelisted_genitals = MAIL_GENITALS_MALE_FULL

/datum/mail_pattern/lewd/used_condom/apply(mob/living/carbon/human/recipient)
	var/obj/item/organ/genital/testicles/balls = recipient.getorganslot(ORGAN_SLOT_TESTICLES)
	var/datum/reagent/liuqid = balls?.fluid_id
	if(liuqid)
		var/obj/item/genital_equipment/condom/open/condom = new(parent)
		var/amount = balls?.get_fluid() || rand(1, condom.reagents.maximum_volume)
		condom.reagents.add_reagent(liuqid, amount)
	else
		new /obj/item/genital_equipment/condom/open/used(parent)

	// Выбираем пол отправителя
	if(pick(50))
		// ЖЕНСКИЙ
		sender = MAIL_SENDER_RANDOM_FEMALE
		letter_html = pick(
			"Ты оставил[recipient.ru_a()] это во мне!\n\
			Я не собираюсь разбираться с последствиями!!\n\
			Забирай своё обратно и больше не пиши!\n\
			Ты отвратител[recipient.ru_en()]!!!", \
			\
			"Ты улетел[recipient.ru_a()], оставив после себя мусор в моей киске!\n\
			Настолько наплевательского отношения я ещё не видела.\n\
			Забирай своё обратно и не приближайся ко мне больше!", \
			\
			"Ты умудри[recipient.ru_sya()] оставить это во мне и просто свалить!\n\
			Такое поведение говорит о тебе всё.\n\
			И больше со мной не связывайся, животное!", \
			\
			"А ты мне понрави[recipient.ru_sya()] слад[recipient.ru_aya_iy()]~\n\
			Заходи еще в гости, как будешь рядом.\n\
			А это твой трофей, на пямять.", \
			\
			"Заставила своего «парня» вылизывать мою киску после тебя.\n\
			Ты бы видел[recipient.ru_a()], как он искренне наслаждался. А сразу после, кончил от прикосновения моей ножки, хах.\n\
			И да, классно, что ты предохраняешься, но не оставляй такие штуки внутри."\
		)
	else
		// МУЖСКОЙ
		sender = MAIL_SENDER_RANDOM_FEMALE
		letter_html = pick(
			"Ты оставил[recipient.ru_a()] после себя мусор в моей девушке!\n\
			Я не знаю, как ты вообще до этого докатил[recipient.ru_sya()], но забирай своё обратно и держись подальше!\n\
			Увижу, набю морду!!!", \
			\
			"Ты оставил[recipient.ru_a()] это в моей девушке. Я не собираюсь убирать за тобой.\n\
			Был[recipient.ru_a()] бы ты радом, запихал бы тебе этот гондон в глотку!! Подавись своим обратно и исчезни!", \
			\
			"Ты умудри[recipient.ru_sya()] оставить это в моей шлюшке, ну ты и свиня, хах.\n\
			А классно ты ее отодрал[recipient.ru_a()], придется ей разрабатываь другие места, пока не восстановит форму после твоей дуры.\n\
			Если захочешь групповушку, пиши, разложим ее вместе.", \
			\
			"Ты что-то забыл[recipient.ru_a()] после себя в моей, эээ... Подруге.\n\
			Это твоя ответственность, но надеюсь обойдется...\n\
			Так что забери обратно и не появляйся больше рядом с ней... Пожалуйста", \
			\
			"Я 30 минут чистил после тебя прекрасную киску своей госпожи, ах-х-х~...\n\
			Не знаю, как ты умудри[recipient.ru_sya()] затолкать его так далеко, но уже под конец я вытащил его своим язычком.\n\
			Она приказала отправить тебе и приглашает еще в гости..."\
		)

	return ..()

/datum/mail_pattern/lewd/sex_toys
	name = "Секс-игрушки"
	description = "Посылка с набором секс-игрушек. Очень оригинально, да?"

	weight = MAIL_WEIGHT_UNCOMMON

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "Преданному клиенту"
	letter_html = "Эта бумажка немного липкая..."
	letter_html = {"Приветик! К сожалению, моё... заведение... закрыли из-за, жалоб на какие-то изнасилования со стороны персонала...
	 				Это всё неправда! =( В общем, я высылаю оставшийся... реквизит всем, кто посещал наш скромный домик
					 больше всех! Приятного пользования, может быть, ещё увидимся! <3"}
	sender = MAIL_SENDER_RANDOM_FEMALE
	letter_sign = null

	initial_contents = list(
		/obj/item/dildo/random,
		/obj/item/dildo/random,
		/obj/item/lewd_spellbook,
		/obj/item/magicwand/blackwand,
		/obj/item/magicwand,
		/obj/item/electropack/vibrator
	)

/datum/mail_pattern/lewd/bag_of_dildos
	name = "Сумка с дилдаками"
	description = "Сумка с дилдаками от мистера K."

	weight = MAIL_WEIGHT_RARE

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "..?"
	letter_html = "Эта бумажка немного липкая..."
	letter_html = {"Спасибо, что скинул%%А%% свой адрес. Как и обещал."}
	sender = "???"
	letter_sign = null

/datum/mail_pattern/lewd/bag_of_dildos/apply(mob/living/carbon/human/recipient)
	. = ..()
	var/obj/item/storage/backpack/duffelbag/syndie/our_bag = new(parent)
	our_bag.name = "Таинственная сумка"
	our_bag.desc = "На ней вышито \"Мистер К.\""
	for(var/i = 1, i <= rand(7, 10), i++)
		new /obj/item/dildo/random(our_bag)
