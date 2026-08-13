//traits with no real impact that can be taken freely
//MAKE SURE THESE DO NOT MAJORLY IMPACT GAMEPLAY. those should be positive or negative traits.

/datum/quirk/no_taste
	name = "Агевзия"
	desc = "Вы не чувствуете вкуса! Ядовитая еда всё ещё будет иметь пагубное воздействие."
	value = 0
	mob_trait = TRAIT_AGEUSIA
	gain_text = "<span class='notice'>Вы не чувствуете вкуса!</span>"
	lose_text = "<span class='notice'>Вы снова чувствуете вкус!</span>"
	medical_record_text = "Пациент страдает от авгезии и не способен чувствовать вкус."

/datum/quirk/snob
	name = "Сноб"
	desc = "Вас волнуют вещи утонченные, если комната выглядит некрасиво, она просто не стоит того, верно?"
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы считаете, что знаете, как должны выглядеть вещи.</span>"
	lose_text = "<span class='notice'>Кого вообще волнует декор?</span>"
	medical_record_text = "Пациент ведёт себя напыщенно."
	mob_trait = TRAIT_SNOB

/datum/quirk/pineapple_liker
	name = "Пристрастие к Ананасам"
	desc = "Вы обожаете плоды ананасового дерева. Вы никак не можете прекратить наслаждаться этим сладким вкусом!"
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>У вас появляется сильное желание вкусить мякоти ананаса.</span>"
	lose_text = "<span class='notice'>По всей видимости, ваше отношение к ананасам возвращается к нейтральному.</span>"
	medical_record_text = "У пациента проявляется патологическая любовь к ананасам."

/datum/quirk/pineapple_liker/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	species.liked_food |= PINEAPPLE

/datum/quirk/pineapple_liker/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		species.liked_food &= ~PINEAPPLE

/datum/quirk/pineapple_hater
	name = "Неприязнь к Ананасам"
	desc = "Вы испытываете сильнейшее отвращение к плодам ананасового дерева. Серьёзно, кому они нравятся? И какой безумец посмел положить их на пиццу!?"
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы задумываетесь над тем, какому идиоту вообще могут понравиться ананасы...</span>"
	lose_text = "<span class='notice'>По всей видимости, ваше отношение к ананасам возвращается к нейтральному.</span>"
	medical_record_text = "Пациент прав в своей нелюбви к ананасам."

/datum/quirk/pineapple_hater/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	species.disliked_food |= PINEAPPLE

/datum/quirk/pineapple_hater/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		species.disliked_food &= ~PINEAPPLE

/datum/quirk/deviant_tastes
	name = "Извращенные Вкусы"
	desc = "Вам не нравится то, что нравится большинству и наоборот."
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Появляется желание съесть чего-нибудь странного.</span>"
	lose_text = "<span class='notice'>Вам снова нравится есть типичную пищу.</span>"
	medical_record_text = "Пациент демонстрирует атипичные предпочтения в пище."

/datum/quirk/deviant_tastes/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	var/liked = species.liked_food
	species.liked_food = species.disliked_food
	species.disliked_food = liked

/datum/quirk/deviant_tastes/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		species.liked_food = initial(species.liked_food)
		species.disliked_food = initial(species.disliked_food)

/datum/quirk/monochromatic
	name = "Монохромазия"
	desc = "Вы страдаете от цветовой слепоты и воспринимаете мир только в чёрных и белых тонах."
	value = 0
	medical_record_text = "Пациент подвержден практически полной цветовой слепоте."

/datum/quirk/monochromatic/add()
	quirk_holder.add_client_colour(/datum/client_colour/monochrome)

/datum/quirk/monochromatic/post_add()
	if(quirk_holder.mind.assigned_role == "Detective")
		to_chat(quirk_holder, "<span class='boldannounce'>Хм-м-м. Нет ничего незапятнанного в этих коридорах. Всё лишь оттенки серого...</span>")
		quirk_holder.playsound_local(quirk_holder, 'sound/ambience/ambidet1.ogg', 50, FALSE)

/datum/quirk/monochromatic/remove()
	if(quirk_holder)
		quirk_holder.remove_client_colour(/datum/client_colour/monochrome)

/datum/quirk/maso
	name = "Мазохизм"
	desc = "Вас возбуждает боль."
	value = 0
	mob_trait = TRAIT_MASO
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Вы хотите, чтобы вам причинили боль.</span>"
	lose_text = "<span class='notice'>Боль больше не так заводит.</span>"

/datum/quirk/libido
	name = "Нимфомания"
	desc = "Вы быстрее возбуждаетесь."
	value = 0
	mob_trait = TRAIT_NYMPHO
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>У вас зудит в промежности.</span>"
	lose_text = "<span class='notice'>Вы более не чувствуете того приятного жжения.</span>"

/datum/quirk/libido/add()
	var/mob/living/carbon/human/H = quirk_holder
	H.arousal_rate = 3 * initial(H.arousal_rate)

/datum/quirk/libido/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H)
		return
	H.arousal_rate = initial(H.arousal_rate)

/datum/quirk/longtimer
	name = "Матёрый Волк"
	desc = "Вы прошли долгий путь и пережили больше, чем остальные. Вы страдаете от жутких шрамов. Какова бы ни была причина, вы отказались от их удаления или аугментации."
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>Ваше тело видало лучшие дни.</span>"
	lose_text = "<span class='notice'>Грехи можно смыть, но шрамы останутся...</span>"
	medical_record_text = "Пациент выразил отказ от удаления многочисленных шрамов."
	/// the minimum amount of scars we can generate
	var/min_scars = 3
	/// the maximum amount of scars we can generate
	var/max_scars = 7

/datum/quirk/longtimer/on_spawn()
	var/mob/living/carbon/C = quirk_holder
	C.generate_fake_scars(rand(min_scars, max_scars))

/datum/quirk/trashcan
	name = "Мусорный бак"
	desc = "Вы можете есть мусор."
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='notice'>В голову приходит мысль пожевать банку из-под содовой.</span>"
	lose_text = "<span class='notice'>Вы больше не хотите есть мусор.</span>"
	mob_trait = TRAIT_TRASHCAN

/datum/quirk/salt_sensitive
	name = "Чувствительность к Натрию"
	desc = "Ваше тело чувствительно к натрию, потому обжигается при контакте с ним. Употребление крайне не рекомендуется."
	value = 0
	medical_record_text = "Пациенту не следует входить в контакт с натрием."
	mob_trait = TRAIT_SALT_SENSITIVE

/datum/quirk/dullahan
	name = "Дуллахан"
	desc = "Ваша голова отделена от тела."
	value = 0
	medical_record_text = "Пациент имеет неизвестного рода пространственную связь с собственной отделенной головой."

/datum/quirk/dullahan/post_add()
	quirk_holder.AddComponent(/datum/component/dullahan)

/datum/quirk/photographer
	name = "Фотограф"
	desc = "Вы знаете как пользоваться фотоаппаратом, сокращая время между фотографией."
	value = 0
	flavor_quirk = TRUE
	mob_trait = TRAIT_PHOTOGRAPHER
	gain_text = "<span class='notice'>Вы знаете всё о фотографиях.</span>"
	lose_text = "<span class='danger'>Вы забываете, как работают фотокамеры.</span>"
	medical_record_text = "Пациент упоминает фотографию, как хобби для снятия стресса."

/datum/quirk/photographer/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/storage/photo_album/photo_album = new(get_turf(H))
	H.put_in_hands(photo_album)
	H.equip_to_slot(photo_album, ITEM_SLOT_BACKPACK)
	photo_album.persistence_id = "personal_[H.mind.key]" // this is a persistent album, the ID is tied to the account's key to avoid tampering
	photo_album.persistence_load()
	photo_album.name = "[H.real_name] Photo Album"
	var/obj/item/camera/camera = new(get_turf(H))
	camera.name = "[H.real_name] Camera"
	H.put_in_hands(camera)
	H.equip_to_slot(camera, ITEM_SLOT_BACKPACK) //SPLURT Edit
	H.regenerate_icons()

// HYPERSTATION TRAITS

/datum/quirk/milk_plus
	name = "Сверхпродуктивная Грудь"
	desc = "Ваша грудь производит и вмещает больше, чем обычно."
	value = 0
	flavor_quirk = TRUE
	gain_text = span_notice("Вы чувствуете давление в груди.")
	lose_text = span_notice("Вы чувствуете, что ваша грудь стала легче.")
	medical_record_text = "Грудь пациента демонстрируют высокую продуктивность."
	var/increasedcum

/datum/quirk/milk_plus/add()
	var/mob/living/carbon/M = quirk_holder
	if(M.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genital/breasts/T = M.getorganslot(ORGAN_SLOT_BREASTS)
		T.fluid_mult += 0.5 //Base is 1
		T.fluid_max_volume *= 1.75 //Fixes this.

/datum/quirk/milk_plus/remove()
	var/mob/living/carbon/M = quirk_holder
	if(!M)
		return
	if(quirk_holder.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genital/breasts/T = M.getorganslot(ORGAN_SLOT_BREASTS)
		T.fluid_mult -= 0.5 //Base is 1
		T.fluid_max_volume *= 0.25 //Base is 50

/datum/quirk/milk_plus/on_process()
	var/mob/living/carbon/M = quirk_holder //If you get balls later, then this will still proc
	if(M.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genital/breasts/T = M.getorganslot(ORGAN_SLOT_BREASTS)
		if(!increasedcum)
			T.fluid_mult = 1.5 //Base is 0.133
			T.fluid_max_volume *= 1.75
			increasedcum = TRUE

/datum/quirk/kartavii
	name = "Картавый"
	desc = "Вы не знаете, как проговаривать букву \"Р\"."
	value = 0
	mob_trait = TRAIT_KARTAVII
	flavor_quirk = TRUE
	gain_text = span_notice("Забываю как проговаривать букву \"Р\".")
	lose_text = span_danger("Вспоминаю как проговаривать букву \"Р\".")
	medical_record_text = "Пациент не может проговаривать букву \"Р\"."

proc/kartavo(message)
	var/num = rand(1, 3)
	switch(prob(75) && num)
		if(1)
			message = replacetextEx(message, "р", "г'")
			message = replacetextEx(message, "Р", "Г'")
		if(2)
			message = replacetextEx(message, "р", "гх")
			message = replacetextEx(message, "Р", "Гх")
		if(3)
			message = replacetextEx(message, "р", "гъ")
			message = replacetextEx(message, "Р", "Гъ")

	return message

/datum/quirk/asiat
	name = "Азиат"
	desc = "Долгое время работы в рисовых полях и жара палящего сверху солнца даровала вам этот прекрасный акцент."
	value = 0
	mob_trait = TRAIT_ASIAT
	flavor_quirk = TRUE
	gain_text = span_notice("Чиньг-чоньг!.")
	lose_text = span_danger("Аниме говно.")
	medical_record_text = "Пациент - азиат."

proc/asiatish(message)
	message = replacetext_char(message, "ра", "ля")
	message = replacetext_char(message, "ла", "ля")
	message = replacetext_char(message, "ло", "льо")
	message = replacetext_char(message, "да", "тя")
	message = replacetext_char(message, "бо", "по")
	message = replacetext_char(message, "за", "ся")
	message = replacetext_char(message, "чу", "сю")
	message = replacetext_char(message, "та", "тя")
	message = replacetext_char(message, "же", "се")
	message = replacetext_char(message, "хо", "ха")
	message = replacetext_char(message, "гд", "кт")
	message = replacetextEx(message, "д", "т")
	message = replacetextEx(message, "ч", "с")
	message = replacetextEx(message, "з", "с")
	message = replacetextEx(message, "р", "л")
	message = replacetextEx(message, "ы", "и")
	message = replacetextEx(message, "Д", "т")
	message = replacetextEx(message, "Ч", "с")
	message = replacetextEx(message, "З", "с")
	message = replacetextEx(message, "Р", "л")
	message = replacetextEx(message, "Ы", "и")

	return message

/datum/quirk/ukraine
	name = "Украиновый"
	desc = "Похоже, вы изучили новый язык и вы не замечаете в этом ничего необычного."
	value = 0
	flavor_quirk = TRUE
	mob_trait = TRAIT_UKRAINE
	gain_text = span_notice("А що такое?")
	lose_text = span_danger("А что такое?")
	medical_record_text = "Пациент испытывает любовь к синим и жёлтым цветам."

/proc/ukraine(message)
	message = replacetextEx_char(message, "РНД", "наукове суспільство")
	message = replacetextEx_char(message, "добро пожаловать", "ласкаво просимо")
	message = replacetextEx_char(message, "зачем", "навіщо")
	message = replacetextEx_char(message, "победа", "перемога")
	message = replacetextEx_char(message, "это", "це")
	message = replacetextEx_char(message, "почему", "чому")
	message = replacetextEx_char(message, "хлеб", "хліб")
	message = replacetextEx_char(message, "фонарик", "ліхтарик")
	message = replacetextEx_char(message, "СБ", "охорона")
	message = replacetextEx_char(message, "лук", "цибуля")
	message = replacetextEx_char(message, "хорошо", "гарно")
	message = replacetextEx_char(message, "звезда", "зірка")
	message = replacetextEx_char(message, "арбуз", "кавун")
	message = replacetextEx_char(message, "сука", "курва")
	message = replacetextEx_char(message, "бред", "маячня")
	message = replacetextEx_char(message, "мне", "мені")
	message = replacetextEx_char(message, "сигареты", "цигарки")
	message = replacetextEx_char(message, "сигарета", "цигарка")
	message = replacetextEx_char(message, "или", "чи")
	message = replacetextEx_char(message, "кто", "хто")
	message = replacetextEx_char(message, "пофиг", "байдуже")
	message = replacetextEx_char(message, "добрый день", "доброго дня")
	message = replacetextEx_char(message, "привет", "здоровенькі були")
	message = replacetextEx_char(message, "блять", "дідько")
	message = replacetextEx_char(message, "блядь", "дідько")
	message = replacetextEx_char(message, "ХОС", "дільничий")
	message = replacetextEx_char(message, "водка", "горілка")
	message = replacetextEx_char(message, "что", "шо")
	message = replacetextEx_char(message, "КМ", "комірник")
	message = replacetextEx_char(message, "СМО", "головний ліпило")
	message = replacetextEx_char(message, "ГСБ", "дільничий")
	message = replacetextEx_char(message, "маг", "чаклун")
	message = replacetextEx_char(message, "лоза", "бур'ян")
	message = replacetextEx_char(message, "культ", "нехристь")
	message = replacetextEx_char(message, "мостик", "майдан")
	message = replacetextEx_char(message, "ученый", "вчений")
	message = replacetextEx_char(message, "инженер", "слюсар")
	message = replacetextEx_char(message, "капитан", "гетьман")
	message = replacetextEx_char(message, "предатель", "зрадник")
	message = replacetextEx_char(message, "генокрад", "москаль")
	message = replacetextEx_char(message, "зажигалка", "спалахуйка")
	message = replacetextEx_char(message, "зеркало", "пикогляд")
	message = replacetextEx_char(message, "презерватив", "нацюцюрник")
	message = replacetextEx_char(message, "пизда", "піхва")
	message = replacetextEx_char(message, "хуй", "прутень")
	message = replacetextEx_char(message, "врач", "лікар")
	message = replacetextEx_char(message, "бармен", "наливайко")
	message = replacetextEx_char(message, "повар", "кухар")
	message = replacetextEx_char(message, "ы", "и")
	message = replacetextEx_char(message, "и", "і")
	message = replacetextEx_char(message, "ъ", "ї")

	return message

/datum/quirk/russian
	name = "Русский дух"
	desc = "Вы были благословлены высшими силами или каким-то иным образом наделены святой энергией. С вами Бог!"
	value = 0
	mob_trait = TRAIT_RUSSIAN
	flavor_quirk = TRUE
	gain_text = span_notice("Вы чувствуете, как Бог следит за вами!")
	lose_text = span_notice("Вы чувствуете, как угасает ваша вера в Бога...")
	medical_record_text = "У пациента обнаружен Ангел-Хранитель."

/datum/quirk/russian/add()
	// Add examine text.
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(quirk_examine_russian))

/datum/quirk/russian/remove()
	// Remove examine text
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

// Quirk examine text.
/datum/quirk/russian/proc/quirk_examine_russian(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	examine_list += "[quirk_holder.ru_who(TRUE)] излучает русский дух..."

/datum/quirk/waddle
	name = "Неуклюжесть"
	desc = "Твоя походка всегда была чуть неуклюжей."
	mob_trait = TRAIT_WADDLING
	flavor_quirk = TRUE
	value = 0
	gain_text = span_notice("Тебе кажется, что ты передвигаешься как-то по-дурацки.")
	lose_text = span_notice("Теперь ты передвигаешься нормально.")
	mail_goodies = list(/obj/item/reagent_containers/food/snacks/grown/banana, /obj/item/clothing/shoes/clown_shoes)
	medical_record_text = "Похоже, субъект ужасный танцор."

/datum/quirk/waddle/add(client/client_source)
	. = ..()
	quirk_holder.LoadComponent(/datum/component/waddling)

/datum/quirk/waddle/remove()
	. = ..()
	if(!HAS_TRAIT(quirk_holder, TRAIT_WADDLING))
		var/datum/component/waddling = GetComponent(/datum/component/waddling)
		waddling?.RemoveComponent()
