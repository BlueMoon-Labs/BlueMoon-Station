/**
 *
 * РАЗНОЕ
 *
 */


/datum/mail_pattern/misc/kinky_handcuffs
	name = "Подарок от друга"
	description = "Розовые наручники в подарок от анонимного товарища."

	weight = MAIL_WEIGHT_DEFAULT

	letter_title = "Записка"
	letter_html = "Привет. Вот реквизит с пранка о котором я тебе писал. Мне не пригодятся, а тебя то я знаю, найдёшь им применение."
	sender = "Сам%%А%% знаешь кто"
	letter_sign = null

	initial_contents = list(
		/obj/item/restraints/handcuffs/kinky
	)

/datum/mail_pattern/misc/heart_normal
	name = "Сердечко"
	description = "Просто <3"

	weight = MAIL_WEIGHT_DEFAULT

	letter_title = "Записка из письма"
	letter_html = "<center><span style='font-size: 80px; color: #ba346e;'>&lt;3</span></center>"
	sender = "???"
	letter_sign = null

	letter_icon = 'icons/obj/toy.dmi'
	letter_icon_state = "sc_Ace of Hearts_syndicate"

	bad_feeling = "Письмо пахнет дешёвыми духами. Это чтобы что-то скрыть?"

	initial_contents = list()

/datum/mail_pattern/misc/heart_spooky
	name = "Сердечко (реальное)"
	description = "<3 + реальное сердце"

	weight = MAIL_WEIGHT_RARE

	letter_title = "Записка из письма"
	letter_desc = "На этой бумажке несколько капель крови..."
	letter_html = "<center><span style='font-size: 80px; color: #ff0000;'>&lt;3</span></center>"
	sender = "???"
	letter_sign = null

	letter_icon = 'icons/obj/toy.dmi'
	letter_icon_state = "sc_Ace of Hearts_syndicate"

	bad_feeling = "Письмо пахнет дешёвыми духами. Это чтобы что-то скрыть?"

	initial_contents = list(
		/obj/item/organ/heart
	)

/datum/mail_pattern/misc/heart_spooky/on_mail_open(mob/living/carbon/human/recipient)
	. = ..()
	recipient.emote("chill")

/datum/mail_pattern/misc/mistress_reward
	name = "Награда от госпожи"
	description = "Теннисный мячик. Хорошим девочкам и мальчикам полагается награда."

	weight = MAIL_WEIGHT_RARE

	letter_title = "Карточка с текстом"
	letter_desc = "Аккуратненькая карточка, чёрный элегантный текст которой очень осторожно выведен от руки."
	letter_html = {"<center><h3>Мо%%ЕМУ%% хорош%%ЕМУ%% %->мальчику | девочке%-</h3></center><br>
					Привет, милашка. За твоё хорошее поведение ты заслужил%%А%% подарочек!<br><br>
					Наслаждайся им :з (Только не отвлекай коллег~).<br><br>
					Жду не дождусь увидеть и пожмонькать тебя!<br><br>
					(⁠*⁠＾⁠3⁠＾⁠)⁠/⁠～⁠♡"}
	sender = "*****"
	letter_sign = null

	letter_icon = 'icons/obj/toy.dmi'
	letter_icon_state = "sc_Ace of Hearts_syndicate"

	whitelisted_quirks = list(
		/datum/quirk/well_trained
	)

	initial_contents = list(
		/obj/item/toy/fluff/tennis_poly
	)

/datum/mail_pattern/misc/mistress_reward/on_mail_open(mob/living/carbon/human/recipient)
	. = ..()
	SEND_SIGNAL(recipient, COMSIG_ADD_MOOD_EVENT, QMOOD_WELL_TRAINED, /datum/mood_event/dominant/good_boy)

/datum/mail_pattern/misc/pineapple
	name = "Ананас"
	description = "Ананас и странная записка"

	weight = MAIL_WEIGHT_DEFAULT

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "Карточка с текстом"
	letter_html = {"Держи, нет времени объяснять."}
	letter_sign = ""

	initial_contents = list(
		/obj/item/reagent_containers/food/snacks/grown/pineapple
	)

/datum/mail_pattern/misc/stockings
	name = "Чулки"
	description = "Чулки и странная записка"

	weight = MAIL_WEIGHT_RARE

	envelope_type = MAIL_TYPE_PACKAGE

	letter_title = "Карточка с текстом"
	letter_html = {"Я купил жене и дочке, тире-точки тире-точки,<br>
					Заграничные чулочки, тире-точки тире-точки<br>
					А себе и сыну, тире-точки тире-точки<br>
					Заграничную машинку, тире-точки тире-точки"}
	letter_sign = ""

/datum/mail_pattern/misc/stockings/apply(mob/living/carbon/human/recipient)
	var/static/list/stockings = typesof(/obj/item/clothing/underwear/socks/thigh/stockings)
	for(var/i=0, i<3, i++)
		var/path = pick(stockings)
		new path(parent)
	return ..()

/datum/mail_pattern/misc/drawing_contest
	name = "Конкурс рисования"
	description = "Содержит балончик с краской, мелки, холст и задание нарисовать что-то"

	weight = MAIL_WEIGHT_RARE

	envelope_type = MAIL_TYPE_PACKAGE

	sender = MAIL_SENDER_CENTCOM
	letter_title = "Уведомление о конкурсе"
	letter_html = {"<center><font color=\"RoyalBlue\"><h1>Центральное Командование - Объявление экипажу</h1></font></center>
					<hr /><br>
					Центральное Командование запускает творческий конкурс для экипажа станции. Цель проста - немного разгрузить смену и посмотреть, на что вы способны вне рамок инструкций и протоколов.<br><br>
					К участию допускаются все желающие, независимо от должности и отдела. Ограничений по стилю и теме нет, главное - не мешать работе станции и не портить критически важное оборудование.<br><br>
					<b>Как участвовать:</b><br>
					1) Используйте приложенные материалы и создайте рисунок.<br>
					2) Завершите работу в течение текущей смены.<br>
					3) Готовую работу закрепите в рамке библетеки или отеля Гилберта.<br><br>
					Вместе с письмом вам выданы: <b>холст</b>, <b>набор мелков</b> и <b>баллончик с краской</b>. Используйте их по назначению.<br><br>
					<font color=\"#FF0000\"><b>Важно:</b></font> рисование на стенах, оборудовании, шлюзах, членах экипажа и других объектах станции, не относящихся к конкурсу, будет расценено как вандализм.<br><br>
					Лучшие работы возможно будут отобраны и отмечены, если оставить их в рамке библиотеки или отеля Гилберта.<br><br>
					<hr />
					<font color=\"grey\"><div align=\"justify\">Примечание: участие добровольное. Центральное Командование не несёт ответственности за испорченные комбинезоны, случайно вдохнувших краску ассистентов и художественные споры внутри экипажа.</div></font>"}
	letter_sign = ""

	initial_contents = list(
		/obj/item/toy/crayon/spraycan/bluespace,
		/obj/item/storage/crayons,
		/obj/item/canvas/ultra_big,
	)

/datum/mail_pattern/misc/drawing_contest/on_mail_open(mob/living/carbon/human/recipient)
	. = ..()
	SEND_SIGNAL(recipient, COMSIG_ADD_MOOD_EVENT, MAIL_MOOD, /datum/mood_event/inspiration)
