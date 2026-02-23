/**
 *
 * ПИСЬМА, СВЯЗАННЫЕ С РАЗНЫМИ АНТАГОНИСТАМИ
 * Могут как действительно вербовать в антагов, так и просто подшучивать.
 *
 */

/datum/mail_pattern/antag/inteq_mobilization
	name = "Мобилизация в InteQ"
	description = "Делает персонажа предателем, если он уже не антагонист / имплантированный майндшилдом."

	envelope_type = MAIL_TYPE_ENVELOPE

	sender = "НЕИЗВЕСТЕН"

	bad_feeling = "От этого письма исходит зловещая аура."

	weight = MAIL_WEIGHT_RARE

	whitelisted_roundtypes = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD)
	mindshield_prohibited = TRUE

	letter_title = "???"
	letter_html = {"<center>
		Агент %номер агента%, начинайте действовать. <i>Устройство</i> отправлено вам.
		Кодовые слова - %кодовые слова%.
		Смерть корпоратам!
		</center>
	"}
	letter_icon_state = "docs_red"
	letter_desc = "Жутковатая бумажка с печатью в форме щита внизу..."
	letter_sign = null

/datum/mail_pattern/antag/anecdote/apply(mob/living/carbon/human/recipient)
	if(prob(10))
		letter_html = "<img src='https://vgorode.ua/img/article/12082/19_main-v1654070622.jpg'>"
	else
		letter_html = replacetext(letter_html, "%номер агента%", pick(GLOB.phonetic_alphabet))
		letter_html = replacetext(letter_html, "%кодовые слова%", jointext(GLOB.syndicate_code_phrase, ", "))
	. = ..()

/datum/mail_pattern/antag/anecdote/on_mail_open(mob/living/carbon/human/recipient)
	. = ..()
	sleep(70)
	// То, что письмо было отфильтровано при первоначальном выпадении, не означает, что получателя не
	// проимплантируют / завербуют в антажку позже
	if(!recipient.mind?.has_antag_datum(/datum/antagonist, TRUE) && !HAS_TRAIT(recipient, TRAIT_MINDSHIELD))
		recipient.mind.add_antag_datum(/datum/antagonist/traitor)
		message_admins("[ADMIN_LOOKUPFLW(recipient)] был сделан предателем через почту!")
	else
		to_chat(recipient, span_warning("Вы вспоминаете о своих клятвах, данных до начала смены... Но теперь у вас другая цель. Обстоятельства изменились."))
	sleep(20)
	if(istype(parent) && istype(parent.included_letter))
		parent.included_letter.fire_act(1000)
		if(recipient.get_active_held_item() == parent.included_letter || recipient.get_inactive_held_item() == parent.included_letter)
			recipient.dropItemToGround(parent.included_letter)
			to_chat(recipient, span_boldwarning("[parent.included_letter] внезапно загорается!"))

/datum/mail_pattern/antag/inteq_mobilization_fake
	name = "Мобилизация в InteQ (Фейк)"
	description = "Письмо не по адресу"

	envelope_type = MAIL_TYPE_ENVELOPE

	sender = "НЕИЗВЕСТЕН"

	bad_feeling = "От этого письма исходит зловещая аура."

	weight = MAIL_WEIGHT_DEFAULT

	letter_title = "???"
	letter_html = {"<center>Кодировка Zeta 17 код 11</center><br>
					 Агент, шифровки по следующей миссии находятся в zeta 12.1/6,под лавкой в парке, сожгите это письмо после прочтения.<br>Ваш индификационный номер на данную миссию "агент XXX".<br>
					 Ваша миссия: Проникнуть на секретную базу Nanotrasen и выкрасть документы связанные с добычей особой руды. Желательно сделать всё без шума и пыли.<br>
					 Дополнительные данные, а так же оборудование вы можете запросить по коду AlphaZ64."}
	letter_icon_state = "docs_red"
	letter_desc = "Жутковатая бумажка с печатью в форме щита внизу..."
	letter_sign = null

/datum/mail_pattern/antag/hogwarts
	name = "Письмо из Хогвартса"
	description = "Делает персонажа магом. Доступно только в эксту, но если ты хочешь щитспавнить в динамик креативно..."

	envelope_type = MAIL_TYPE_PACKAGE

	sender = "Администрация Академии Волшебников"

	bad_feeling = "Вы чувствуете как от посылки исходит магическая аура..."

	weight = MAIL_WEIGHT_EXTREMELY_RARE

	letter_title = "Письмо из Академии"
	letter_desc = "Забавный почерк?.."
	letter_html = {"<center><font color="RoyalBlue"> Хотите попасть в мир магии?</center></font><br>
					 Добро пожаловать в школу магии имени Frost Storm! Здесь вас ждут невероятные приключения, магические сражения и незабываемые уроки волшебства. Окунитесь в мир магии и станьте настоящим магом!<br>
					 Приглашаем вас присоединиться к нашей школе магии и стать частью удивительного сообщества волшебников. Здесь вы сможете развить свои навыки, научиться контролировать стихии и создавать настоящие чудеса.<br>
					 Чтобы ваше путешествие в мир магии было комфортным и успешным, мы составили список необходимых вещей и одежды.<br>
					 Вещи:<br>
					 Волшебная палочка (обязательно);<br>
					 Котёл (для приготовления зелий);<br>
					 Набор стеклянных или хрустальных флаконов (для хранения зелий);<br>
					 Телескоп (для наблюдения за звёздами и планетами);<br>
					 Медные весы (для точного измерения ингредиентов).<br>
					 Одежда:<br>
					 Синяя мантия (три комплекта);<br>
					 Остроконечная синяя шляпа (для повседневного ношения);<br>
					 Защитные перчатки (кожа дракона или аналогичный материал);<br>
					 Зимний чёрный плащ с серебряными застёжками.<br>
					 Не забудьте также свою любимую сову, кошку или жабу, если хотите взять их с собой.<br><br>
					 Самые важные принадлежности мы положили вам в конверт. Не обращайте внимания, что он гораздо вместительнее, чем должен быть. Магия!<br><br>
					 <font color="#FF0000">Не упустите свой шанс стать учеником школы магии Frost Storm и окунуться в мир волшебства и загадок!</font><br>
					 <font size="1">Мы не несём ответственности за травмы полученные в процессе обучения, так же соглашаясь с приглашением, вы полностью отказываетесь от претензий в случае летального исхода, травм и прочих непредвиденных обстоятельств.</font>"}
	letter_sign = "С чудесным приветом, %%подпись%%"

	whitelisted_roundtypes = list(
		ROUNDTYPE_EXTENDED
	)

	initial_contents = list(
		/obj/item/clothing/shoes/sandal,
		/obj/item/teleportation_scroll
	)

/datum/mail_pattern/antag/hogwarts/apply(mob/living/carbon/human/recipient)
	if(prob(50))
		letter_html = "<img src='https://i.ibb.co/tTHRTY3z/image.png'>" // ВЖУХ
	if(recipient.gender == FEMALE)
		initial_contents += /obj/item/clothing/suit/wizrobe/marisa
		initial_contents += /obj/item/clothing/head/wizard/marisa
	else
		initial_contents += /obj/item/clothing/suit/wizrobe
		initial_contents += /obj/item/clothing/head/wizard
	var/obj/item/spellbook/our_spellbook = new(parent)
	our_spellbook.owner = recipient
	our_spellbook.name = "Стандартная книга заклинаний, курс I"
	our_spellbook.uses = 5
	our_spellbook.desc = "Учебник Миранды Гуссокл из серии «Стандартных книг заклинаний» для первого курса магических школ. Немного ограниченнее, чем то, что вы могли себе вообразить."
	. = ..()

/datum/mail_pattern/antag/hogwarts/on_mail_open(mob/living/carbon/human/recipient)
	. = ..()
	recipient.visible_message(span_abductor("[recipient] обдаёт магической энергией из [parent]!"), span_abductor("Вас обдаёт магической энергией из [parent]!"))
	playsound(parent, 'sound/effects/magic.ogg')
	message_admins("[ADMIN_LOOKUPFLW(recipient)] получил магическую книжку письмом из Хогвартса!")

/datum/mail_pattern/antag/clown_car
	name = "Клоунская машинка"
	description = "Содержит клоунскую машинку и мегафон. Доступно только в эксту, но если ты хочешь щитспавнить в динамик креативно..."

	envelope_type = MAIL_TYPE_PACKAGE

	bad_feeling = "Вы чувствуете как от посылки исходит аура хонка..."

	weight = MAIL_WEIGHT_EXTREMELY_RARE

	letter_icon_state = "scrap"
	letter_title = "Письмо от Хонкоматери"
	letter_html = {"Ты знаешь что делать, сын мой."}
	letter_sign = ""
	sender = "HONK"

	whitelisted_roundtypes = list(
		ROUNDTYPE_EXTENDED
	)
	whitelisted_jobs = list(
		"Clown"
	)

	initial_contents = list(
		/obj/item/choice_beacon/vehicle/clown_car,
		/obj/item/megaphone/clown,
	)
