/datum/unit_test/speech_fx_spans
	var/list/last_spans

/datum/unit_test/speech_fx_spans/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(length(speaker.get_speech_fx_spans()), 0, "Здоровая речь без эффектов.")

	speaker.stuttering = 5
	TEST_ASSERT(SPAN_TREMBLE in speaker.get_speech_fx_spans(), "Заикание дрожит.")
	speaker.stuttering = 0
	speaker.jitteriness = SPEECH_FX_JITTER_MIN
	TEST_ASSERT(SPAN_TREMBLE in speaker.get_speech_fx_spans(), "Сильный тремор дрожит.")
	speaker.jitteriness = 0

	speaker.drunkenness = SPEECH_FX_DRUNK_MIN
	TEST_ASSERT(SPAN_DRUNK in speaker.get_speech_fx_spans(), "Пьяная речь плывёт.")
	speaker.drunkenness = 0

	speaker.adjustOxyLoss(SPEECH_FX_OXY_MIN)
	TEST_ASSERT(SPAN_GASP in speaker.get_speech_fx_spans(), "Удушье гасит речь.")
	speaker.setOxyLoss(0)

	speaker.bodytemperature = BODYTEMP_COLD_DAMAGE_LIMIT - 1
	TEST_ASSERT(SPAN_SHIVER in speaker.get_speech_fx_spans(), "Холод даёт озноб.")
	speaker.bodytemperature = BODYTEMP_NORMAL

	var/obj/item/clothing/mask/muzzle/gag = allocate(/obj/item/clothing/mask/muzzle)
	gag.mute = MUFFLE_LOW
	TEST_ASSERT(speaker.equip_to_slot_if_possible(gag, ITEM_SLOT_MASK), "Кляп надевается.")
	TEST_ASSERT(SPAN_MUFFLED in speaker.get_speech_fx_spans(), "Кляп приглушает речь.")
	gag.mute = MUFFLE_MUTE
	TEST_ASSERT(!(SPAN_MUFFLED in speaker.get_speech_fx_spans()), "Немой кляп речь не пропускает вовсе.")
	qdel(gag)

	TEST_ASSERT_EQUAL(length(speaker.get_speech_fx_spans()), 0, "Эффекты снимаются вместе с состоянием.")

	ADD_TRAIT(speaker, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)
	speaker.stuttering = 5
	TEST_ASSERT(!(SPAN_TREMBLE in speaker.get_speech_fx_spans()), "Робот-заика глючит, а не дрожит.")
	REMOVE_TRAIT(speaker, TRAIT_ROBOTIC_ORGANISM, TRAIT_GENERIC)

	RegisterSignal(speaker, COMSIG_LIVING_SEND_SPEECH, PROC_REF(record_speech))
	speaker.say("Проверка дрожи.", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT(SPAN_TREMBLE in last_spans, "Спан доходит до рассылки речи.")
	UnregisterSignal(speaker, COMSIG_LIVING_SEND_SPEECH)

/datum/unit_test/speech_fx_spans/proc/record_speech(datum/source, message, message_range, obj/source_obj, bubble_type, list/spans, datum/language/message_language, message_mode)
	SIGNAL_HANDLER
	last_spans = spans?.Copy()

/// Удушье и кляп видны в речи, пока персонаж говорит; жестам они не мешают.
/datum/unit_test/speech_fx_say_states
	var/list/last_spans

/datum/unit_test/speech_fx_say_states/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	RegisterSignal(speaker, COMSIG_LIVING_SEND_SPEECH, PROC_REF(record_speech))

	// При 50 урона от удушья carbon падает без сознания, речь удушья должна начинаться раньше.
	for(var/oxy in list(SPEECH_FX_OXY_MIN, 40))
		speaker.setOxyLoss(oxy)
		last_spans = null
		speaker.say("Воздуха.", language = /datum/language/common, ignore_spam = TRUE)
		TEST_ASSERT_EQUAL(speaker.stat, CONSCIOUS, "При [oxy] урона от удушья персонаж в сознании.")
		TEST_ASSERT(SPAN_GASP in last_spans, "При [oxy] урона от удушья речь задыхается: [json_encode(last_spans)]")
	speaker.setOxyLoss(0)

	var/obj/item/clothing/mask/muzzle/gag = allocate(/obj/item/clothing/mask/muzzle)
	gag.mute = MUFFLE_LOW
	TEST_ASSERT(speaker.equip_to_slot_if_possible(gag, ITEM_SLOT_MASK), "Кляп надевается.")
	speaker.setOxyLoss(SPEECH_FX_OXY_MIN)
	speaker.jitteriness = SPEECH_FX_JITTER_MIN
	last_spans = null
	speaker.say("Помогите.", language = /datum/language/signlanguage, ignore_spam = TRUE)
	TEST_ASSERT_NOTNULL(last_spans, "Жесты в кляпе показываются.")
	TEST_ASSERT(!(SPAN_MUFFLED in last_spans), "Кляп не приглушает жесты: [json_encode(last_spans)]")
	TEST_ASSERT(!(SPAN_GASP in last_spans), "Удушье не гасит жесты: [json_encode(last_spans)]")
	TEST_ASSERT(SPAN_TREMBLE in last_spans, "Дрожь рук в жестах остаётся: [json_encode(last_spans)]")
	speaker.jitteriness = 0
	speaker.setOxyLoss(0)
	qdel(gag)
	UnregisterSignal(speaker, COMSIG_LIVING_SEND_SPEECH)

/datum/unit_test/speech_fx_say_states/proc/record_speech(datum/source, message, message_range, obj/source_obj, bubble_type, list/spans, datum/language/message_language, message_mode)
	SIGNAL_HANDLER
	last_spans = spans?.Copy()

/datum/unit_test/hearing_fx_wrap

/datum/unit_test/hearing_fx_wrap/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/listener = allocate(/mob/living/carbon/human, get_step(speaker, EAST))
	var/line = "<span class='say'>Привет</span>"
	TEST_ASSERT_EQUAL(listener.apply_hearing_fx(line, speaker), line, "Здоровый слушатель получает строку как есть.")

	listener.druggy = 10
	TEST_ASSERT(findtext(listener.apply_hearing_fx(line, speaker), "hear_druggy"), "Под веществами строка сдвигается по цвету.")
	TEST_ASSERT_EQUAL(listener.apply_hearing_fx(line, listener), line, "Своя речь не искажается.")
	var/obj/item/radio/radio = allocate(/obj/item/radio)
	var/atom/movable/virtualspeaker/own_voice = new(null, listener, radio)
	TEST_ASSERT_EQUAL(listener.apply_hearing_fx(line, own_voice), line, "Своя речь эхом по рации не искажается.")
	qdel(own_voice)
	listener.druggy = 0

	listener.dizziness = SPEECH_FX_DIZZY_MIN
	TEST_ASSERT(findtext(listener.apply_hearing_fx(line, speaker), "hear_dizzy"), "Головокружение качает строку.")
	listener.dizziness = 0

	listener.hallucination = 50
	var/wrapped = 0
	for(var/i in 1 to 200)
		if(findtext(listener.apply_hearing_fx(line, speaker), "hear_hallucination"))
			wrapped++
	TEST_ASSERT(wrapped > 0 && wrapped < 200, "Галлюцинации искажают только часть сообщений ([wrapped]/200).")
	listener.hallucination = 0

	var/obj/item/organ/ears/ears = listener.getorganslot(ORGAN_SLOT_EARS)
	TEST_ASSERT_NOTNULL(ears, "У слушателя есть уши.")
	ears.damage = ears.low_threshold + 1
	ears.deaf = 0
	TEST_ASSERT(findtext(listener.apply_hearing_fx(line, speaker), "hear_muffled"), "Повреждённые уши приглушают речь.")
	TEST_ASSERT(!findtext(listener.apply_hearing_fx(line, speaker, /datum/language/signlanguage), "hear_muffled"), "Жесты уши не приглушают.")
	listener.druggy = 10
	TEST_ASSERT(findtext(listener.apply_hearing_fx(line, speaker, /datum/language/signlanguage), "hear_druggy"), "Остальные эффекты слушателя жесты получают.")
	listener.druggy = 0
	ears.damage = 0

/mob/living/carbon/human/speech_fx_probe
	var/list/shown = list()
	var/list/heard_spans

/mob/living/carbon/human/speech_fx_probe/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	heard_spans = spans?.Copy()
	return ..()

/mob/living/carbon/human/speech_fx_probe/show_message(msg, type, alt_msg, alt_type)
	shown += "[msg]"
	return ..()

/mob/living/carbon/human/speech_fx_probe/Destroy()
	shown = null
	heard_spans = null
	return ..()

/// Эффекты слушающего и помехи доходят до чата через Hear() и вещание рации.
/datum/unit_test/hearing_fx_wiring

/datum/unit_test/hearing_fx_wiring/Run()
	var/mob/living/carbon/human/speech_fx_probe/listener = allocate(/mob/living/carbon/human/speech_fx_probe, run_loc_floor_bottom_left)
	// Без клиента Hear() выходит сразу; перенаправление держит слушателя в игре.
	listener.audiovisual_redirect = allocate(/mob/living/carbon/human, get_step(listener, NORTH))
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(listener, EAST))
	listener.druggy = 10
	crew.say("Проверка слуха.", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT(length(listener.shown), "Слушатель слышит речь рядом.")
	TEST_ASSERT(findtext(jointext(listener.shown, " | "), "hear_druggy"), "Речь рядом приходит со сдвигом цвета: [jointext(listener.shown, " | ")]")
	listener.druggy = 0

	var/obj/item/radio/radio = allocate(/obj/item/radio, get_step(listener, WEST))
	var/atom/movable/virtualspeaker/virt = new(null, crew, radio)
	var/datum/signal/subspace/vocal/signal = new(radio, FREQ_COMMON, virt, /datum/language/common, "Проверка помех.", list())
	signal.transmission_method = TRANSMISSION_RADIO
	signal.data["compression"] = 30
	listener.heard_spans = null
	signal.broadcast()
	TEST_ASSERT(SPAN_RADIO_STATIC in listener.heard_spans, "Сжатый сигнал доходит до слушателя с помехами.")
	signal.data["compression"] = 0
	listener.heard_spans = null
	signal.broadcast()
	TEST_ASSERT_NOTNULL(listener.heard_spans, "Чистый сигнал доходит до слушателя.")
	TEST_ASSERT(!(SPAN_RADIO_STATIC in listener.heard_spans), "Чистый сигнал без помех.")
	qdel(virt)

	listener.druggy = 10
	var/atom/movable/virtualspeaker/own_voice = new(null, listener, radio)
	var/datum/signal/subspace/vocal/own_signal = new(radio, FREQ_COMMON, own_voice, /datum/language/common, "Своё эхо.", list())
	own_signal.transmission_method = TRANSMISSION_RADIO
	own_signal.data["compression"] = 0
	listener.shown.Cut()
	own_signal.broadcast()
	TEST_ASSERT(length(listener.shown), "Своя реплика возвращается по рации.")
	TEST_ASSERT(!findtext(jointext(listener.shown, " | "), "hear_druggy"), "Своя реплика по рации не искажается: [jointext(listener.shown, " | ")]")
	qdel(own_voice)

/// Голос галлюцинации оформлен как настоящая речь: по чату его не отличить.
/datum/unit_test/hallucination_speech_fx

/datum/unit_test/hallucination_speech_fx/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human, get_step(target, EAST))
	target.druggy = 10
	person.drunkenness = SPEECH_FX_DRUNK_MIN
	var/fake = target.hear_fake_speech(person, /datum/language/common, "Привет")
	TEST_ASSERT(findtext(fake, "hear_druggy"), "Фальшивая речь получает эффекты слушателя: [fake]")
	TEST_ASSERT(findtext(fake, SPAN_DRUNK), "Фальшивая речь несёт состояние говорящего: [fake]")
	var/fake_radio = target.hear_fake_speech(person, /datum/language/common, "Помогите", FREQ_COMMON)
	TEST_ASSERT(findtext(fake_radio, "hear_druggy"), "Фальшивая рация получает эффекты слушателя: [fake_radio]")
	TEST_ASSERT(findtext(fake_radio, SPAN_DRUNK), "Фальшивая рация несёт состояние говорящего: [fake_radio]")

/datum/unit_test/radio_static_spans

/datum/unit_test/radio_static_spans/Run()
	var/list/original = list(SPAN_YELL)
	var/list/result = radio_broadcast_spans(original, 0)
	TEST_ASSERT(!(SPAN_RADIO_STATIC in result), "Чистый сигнал без помех.")
	result = radio_broadcast_spans(original, 30)
	TEST_ASSERT(SPAN_RADIO_STATIC in result, "Сжатый сигнал несёт помехи.")
	TEST_ASSERT(SPAN_YELL in result, "Остальные спаны сохраняются.")
	TEST_ASSERT(!(SPAN_RADIO_STATIC in original), "Исходный список не мутирует.")
	TEST_ASSERT(SPAN_RADIO_STATIC in radio_broadcast_spans(null, 30), "Пустой список спанов тоже получает помехи.")

/obj/item/radio/headset/fake_speech_probe

/obj/item/radio/headset/fake_speech_probe/talk_into_impl(atom/movable/M, message, channel, list/spans, datum/language/language)
	var/atom/movable/virtualspeaker/virt = new(null, M, src)
	var/datum/signal/subspace/vocal/signal = new(src, frequency, virt, language, message, spans)
	signal.transmission_method = TRANSMISSION_RADIO
	signal.data["compression"] = 0
	signal.broadcast()
	qdel(virt)

/// Строка галлюцинации совпадает со строкой настоящей речи того же говорящего рядом и по рации, вместе с искажением текста.
/datum/unit_test/fake_speech_matches_real
	var/mob/living/carbon/human/speech_fx_probe/listener
	var/mob/living/carbon/human/speaker

/datum/unit_test/fake_speech_matches_real/Run()
	listener = allocate(/mob/living/carbon/human/speech_fx_probe, run_loc_floor_bottom_left)
	listener.audiovisual_redirect = allocate(/mob/living/carbon/human, get_step(listener, NORTH))
	speaker = allocate(/mob/living/carbon/human, get_step(listener, EAST))
	speaker.real_name = "John Doe"
	speaker.name = speaker.get_visible_name()

	var/real = compare("Открытое лицо", "Проверка связи.")
	TEST_ASSERT(findtext(real, ">John Doe<"), "Открытое лицо: [real]")

	var/obj/item/clothing/mask/gas/mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(speaker.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Противогаз надевается.")
	speaker.name = speaker.get_visible_name()
	real = compare("Закрытое лицо", "Кто здесь?")
	TEST_ASSERT(findtext(real, "John Doe (как неизвестный)"), "Закрытое лицо выдаёт голос: [real]")
	qdel(mask)

	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = "Bob Roe"
	card.assignment = "Medical Doctor"
	speaker.equip_to_slot(card, ITEM_SLOT_ID)
	speaker.name = speaker.get_visible_name()
	real = compare("Чужая карта", "Это не моя карта.")
	TEST_ASSERT(findtext(real, "John Doe (как Bob Roe)"), "Чужая карта: [real]")

	ADD_TRAIT(speaker, TRAIT_ASIAT, TRAIT_GENERIC)
	real = compare("Акцент", "Да, рад видеть.")
	TEST_ASSERT(spoken_text(real) != "Да, рад видеть.", "Акцент искажает настоящую речь: [real]")
	REMOVE_TRAIT(speaker, TRAIT_ASIAT, TRAIT_GENERIC)

	speaker.slurring = 50
	real = compare("Невнятная речь", "So sad, you can see us all, ok? Sure, so sorry, Oscar.", random_text = TRUE)
	TEST_ASSERT(findtext(real, SPAN_SLURRING), "Невнятная речь: [real]")
	speaker.slurring = 0

	speaker.grant_language(/datum/language/machine)
	listener.grant_language(/datum/language/machine)
	real = compare("Язык со спанами", "Бип.", /datum/language/machine)
	TEST_ASSERT(findtext(real, SPAN_ROBOT), "Язык со спанами: [real]")

	var/turf/speaker_turf = get_turf(speaker)
	var/datum/gas_mixture/air = speaker_turf.return_air()
	var/datum/gas_mixture/removed = air.remove_ratio(0.8)
	real = compare("Разреженный воздух", "Душно.")
	air.merge(removed)
	TEST_ASSERT(findtext(real, SPAN_ITALICS), "Разреженный воздух: [real]")

	var/turf/far = locate(listener.x, listener.y + 12, listener.z)
	TEST_ASSERT_NOTNULL(far, "Есть клетка вдали от слушателя.")
	speaker.forceMove(far)
	allocate(/obj/item/radio, run_loc_floor_bottom_left)
	var/obj/item/radio/headset/fake_speech_probe/headset = allocate(/obj/item/radio/headset/fake_speech_probe)
	TEST_ASSERT(speaker.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_LEFT), "Гарнитура надевается.")
	real = compare("Рация", ";Помогите!", radio_freq = FREQ_COMMON)
	TEST_ASSERT(findtext(real, "\[Medical Doctor\]"), "Рация с тегом должности: [real]")
	TEST_ASSERT(!findtext(real, "class='small'"), "Рация издалека не мельчит: [real]")

/// Сравнивает строку настоящей речи speaker у listener со строкой фальшивки; возвращает настоящую. Случайное искажение сравнивается без самого текста.
/datum/unit_test/fake_speech_matches_real/proc/compare(label, text, language = /datum/language/common, radio_freq, random_text = FALSE)
	listener.shown.Cut()
	speaker.say(text, language = language, ignore_spam = TRUE)
	var/real = jointext(listener.shown, " | ")
	var/raw = radio_freq ? copytext_char(text, 2) : text
	var/fake = listener.hear_fake_speech(speaker, language, raw, radio_freq)
	if(random_text)
		if(spoken_text(real) == raw)
			TEST_FAIL("[label]: настоящая речь не искажена: [real]")
		if(spoken_text(fake) == raw)
			TEST_FAIL("[label]: текст фальшивки не искажён: [fake]")
		fake = replacetext(fake, spoken_text(fake), "")
		if(fake != replacetext(real, spoken_text(real), ""))
			TEST_FAIL("[label]: фальшивка [fake], настоящая [real]")
		return real
	if(fake != real)
		TEST_FAIL("[label]: фальшивка [fake], настоящая [real]")
	return real

/datum/unit_test/fake_speech_matches_real/proc/spoken_text(line)
	var/text_end = findlasttext(line, "</span>\"")
	var/text_start = findlasttext(line, "'>", text_end) + 2
	return copytext(line, text_start, text_end)

/// Подсветка слов фобии слушателя есть и в настоящей речи, и в фальшивке.
/datum/unit_test/fake_speech_listener_marks

/datum/unit_test/fake_speech_listener_marks/Run()
	var/mob/living/carbon/human/speech_fx_probe/listener = allocate(/mob/living/carbon/human/speech_fx_probe, run_loc_floor_bottom_left)
	listener.audiovisual_redirect = allocate(/mob/living/carbon/human, get_step(listener, NORTH))
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human, get_step(listener, EAST))
	var/datum/brain_trauma/mild/phobia/phobia = listener.gain_trauma(/datum/brain_trauma/mild/phobia, TRAUMA_RESILIENCE_ABSOLUTE, "skeletons")
	TEST_ASSERT(istype(phobia), "Фобия скелетов выдаётся.")
	var/trigger
	for(var/word in phobia.trigger_words)
		if(length(word) == length_char(word))
			trigger = word
			break
	TEST_ASSERT_NOTNULL(trigger, "У фобии скелетов есть латинское слово.")
	var/text = "Look, [trigger] here."
	var/fake = listener.hear_fake_speech(speaker, /datum/language/common, text)
	listener.shown.Cut()
	speaker.say(text, language = /datum/language/common, ignore_spam = TRUE)
	var/real = jointext(listener.shown, " | ")
	TEST_ASSERT(findtext(real, "class='phobia'"), "Настоящая речь подсвечивает фобию: [real]")
	TEST_ASSERT_EQUAL(fake, real, "Фальшивка подсвечивает фобию так же.")

/// Галлюцинация не говорит голосом того, чей голос не виден по лицу или карте: иначе она выдаёт замаскированного.
/datum/unit_test/hallucination_voice_disguise

/datum/unit_test/hallucination_voice_disguise/Run()
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	person.real_name = "John Doe"
	TEST_ASSERT(!hallucination_voice_gives_away(person), "Открытое лицо голос не выдаёт.")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = "Bob Roe"
	person.equip_to_slot(card, ITEM_SLOT_ID)
	TEST_ASSERT(!hallucination_voice_gives_away(person), "Лицо видно, чужая карта голос не выдаёт.")
	var/obj/item/clothing/mask/gas/mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(person.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Противогаз надевается.")
	TEST_ASSERT(hallucination_voice_gives_away(person), "Под маской с чужой картой голос выдаёт.")
	card.registered_name = "John Doe"
	TEST_ASSERT(!hallucination_voice_gives_away(person), "Под маской со своей картой голос совпадает с картой.")
	qdel(card)
	TEST_ASSERT(hallucination_voice_gives_away(person), "Под маской без карты голос выдаёт.")

/// Галлюцинация говорит голосом ближайшего открытого лица, а по рации только голосом того, чья карта и гарнитура при нём.
/datum/unit_test/hallucination_talker_pick

/datum/unit_test/hallucination_talker_pick/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/near = allocate(/mob/living/carbon/human, get_step(target, EAST))
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, get_step(get_step(target, EAST), EAST))
	TEST_ASSERT(hallucination_pick_talker(target, list(target, far, near)) == near, "Говорит ближайший.")
	var/obj/item/clothing/mask/gas/near_mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(near.equip_to_slot_if_possible(near_mask, ITEM_SLOT_MASK), "Противогаз надевается.")
	TEST_ASSERT(hallucination_pick_talker(target, list(target, far, near)) == far, "Замаскированный пропускается.")
	var/obj/item/clothing/mask/gas/far_mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(far.equip_to_slot_if_possible(far_mask, ITEM_SLOT_MASK), "Второй противогаз надевается.")
	TEST_ASSERT_NULL(hallucination_pick_talker(target, list(target, far, near)), "Без открытых лиц галлюцинация уходит в рацию.")

	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(target, NORTH))
	crew.mind_initialize()
	crew.mind.assigned_role = "Medical Doctor"
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = crew.real_name
	card.assignment = "Medical Doctor"
	crew.equip_to_slot(card, ITEM_SLOT_ID)
	TEST_ASSERT(!hallucination_radio_voice_ok(crew), "Без гарнитуры по рации не говорят.")
	var/obj/item/radio/headset/headset = allocate(/obj/item/radio/headset)
	TEST_ASSERT(crew.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_LEFT), "Гарнитура надевается.")
	TEST_ASSERT(hallucination_radio_voice_ok(crew), "Честный носитель своей карты говорит по рации.")
	card.assignment = "Captain"
	TEST_ASSERT(!hallucination_radio_voice_ok(crew), "Чужая должность на карте не попадает в рацию.")
	card.assignment = "Medical Doctor"
	card.registered_name = "Bob Roe"
	TEST_ASSERT(!hallucination_radio_voice_ok(crew), "Чужая карта не попадает в рацию.")
	card.registered_name = crew.real_name
	TEST_ASSERT(!(crew in hallucination_radio_talkers(target)), "Вне станции по рации никто не говорит.")
	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	TEST_ASSERT(length(station_levels), "На карте есть станция.")
	var/turf/home = get_turf(crew)
	crew.forceMove(locate(10, 10, station_levels[1]))
	var/list/talkers = hallucination_radio_talkers(target)
	crew.forceMove(home)
	TEST_ASSERT(crew in talkers, "Честный носитель на станции говорит по рации.")

	TEST_ASSERT(crew.temporarilyRemoveItemFromInventory(headset, TRUE), "Гарнитура снимается.")
	var/obj/item/clothing/ears/earmuffs/muffs = allocate(/obj/item/clothing/ears/earmuffs)
	TEST_ASSERT(crew.equip_to_slot_if_possible(muffs, ITEM_SLOT_EARS_LEFT), "Наушники в левое ухо.")
	TEST_ASSERT(crew.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_RIGHT), "Гарнитура в правое ухо.")
	TEST_ASSERT(!hallucination_radio_voice_ok(crew), "Гарнитура в правом ухе молчит, пока левое занято.")
	qdel(muffs)
	TEST_ASSERT(hallucination_radio_voice_ok(crew), "Гарнитура в правом ухе говорит при пустом левом.")

/// Слова фобии и гипнофразы подсвечиваются целыми русскими словами, в настоящей речи и в фальшивке.
/datum/unit_test/hearing_marks_cyrillic
	var/mob/living/carbon/human/speech_fx_probe/listener
	var/mob/living/carbon/human/speaker

/datum/unit_test/hearing_marks_cyrillic/Run()
	listener = allocate(/mob/living/carbon/human/speech_fx_probe, run_loc_floor_bottom_left)
	listener.audiovisual_redirect = allocate(/mob/living/carbon/human, get_step(listener, NORTH))
	speaker = allocate(/mob/living/carbon/human, get_step(listener, EAST))

	var/datum/brain_trauma/mild/phobia/phobia = listener.gain_trauma(/datum/brain_trauma/mild/phobia, TRAUMA_RESILIENCE_ABSOLUTE, "spiders")
	TEST_ASSERT(istype(phobia), "Фобия пауков выдаётся.")
	var/trigger
	for(var/word in phobia.trigger_words)
		if(length(word) != length_char(word) && !findtext(word, " "))
			trigger = word
			break
	TEST_ASSERT_NOTNULL(trigger, "У фобии пауков есть русское слово.")
	var/list/lines = real_and_fake("Там [trigger] сидит.")
	TEST_ASSERT(findtext(lines[1], "class='phobia'"), "Русское слово фобии подсвечивается: [lines[1]]")
	TEST_ASSERT_EQUAL(lines[2], lines[1], "Фальшивка подсвечивает русскую фобию так же.")
	lines = real_and_fake("Там [trigger]ище сидит.")
	TEST_ASSERT(!findtext(lines[1], "class='phobia'"), "Часть слова не подсвечивается: [lines[1]]")
	TEST_ASSERT_EQUAL(lines[2], lines[1], "Фальшивка не подсвечивает часть слова.")
	listener.cure_trauma_type(/datum/brain_trauma/mild/phobia, TRAUMA_RESILIENCE_ABSOLUTE)

	listener.gain_trauma(new /datum/brain_trauma/hypnosis("усни сейчас", TRUE), TRAUMA_RESILIENCE_ABSOLUTE)
	lines = real_and_fake("Усни сейчас.")
	TEST_ASSERT(findtext(lines[1], "hypnophrase"), "Русская гипнофраза подсвечивается: [lines[1]]")
	TEST_ASSERT_EQUAL(lines[2], lines[1], "Фальшивка подсвечивает гипнофразу так же.")
	listener.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_ABSOLUTE)

	var/datum/brain_trauma/induced_hypnosis/goggles = new("слушай меня")
	listener.gain_trauma(goggles, TRAUMA_RESILIENCE_ABSOLUTE)
	var/fake = listener.hear_fake_speech(speaker, /datum/language/common, goggles.hypnotic_phrase)
	TEST_ASSERT(findtext(fake, "hypnophrase"), "Фраза гипноочков подсвечивается в фальшивке: [fake]")
	speaker.stuttering = 20
	fake = listener.hear_fake_speech(speaker, /datum/language/common, goggles.hypnotic_phrase)
	speaker.stuttering = 0
	TEST_ASSERT(!findtext(fake, "&lt;"), "Заикание не ломает разметку фразы: [fake]")
	listener.cure_trauma_type(/datum/brain_trauma/induced_hypnosis, TRAUMA_RESILIENCE_ABSOLUTE)

/// Строка настоящей речи speaker и фальшивки с тем же текстом.
/datum/unit_test/hearing_marks_cyrillic/proc/real_and_fake(text)
	var/fake = listener.hear_fake_speech(speaker, /datum/language/common, text)
	listener.shown.Cut()
	speaker.say(text, language = /datum/language/common, ignore_spam = TRUE)
	return list(jointext(listener.shown, " | "), fake)

/// Галлюцинация смерти показывает deadchat в том же виде, что настоящий.
/datum/unit_test/fake_deadchat_matches_real

/datum/unit_test/fake_deadchat_matches_real/Run()
	GLOB.unit_test_deadchat_messages = list()
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	ghost.say("git gud")
	var/real = jointext(GLOB.unit_test_deadchat_messages, " | ")
	var/fake = hallucination_deadchat_say(ghost, "git gud")
	if(fake != real)
		TEST_FAIL("Речь призрака: фальшивка [fake], настоящая [real]")

	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	victim.mind_initialize()
	victim.mind.active = TRUE
	victim.mind.name = "Jane Roe"
	fake = hallucination_deathrattle(victim)
	GLOB.unit_test_deadchat_messages = list()
	victim.death()
	real = jointext(GLOB.unit_test_deadchat_messages, " | ")
	GLOB.unit_test_deadchat_messages = null
	TEST_ASSERT(findtext(real, "Jane Roe"), "Смерть объявляется в deadchat: [real]")
	if(fake != real)
		TEST_FAIL("Предсмертное сообщение: фальшивка [fake], настоящая [real]")
