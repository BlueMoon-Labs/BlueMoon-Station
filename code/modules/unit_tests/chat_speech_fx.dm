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
	var/fake = target.compose_fake_speech(person, /datum/language/common, "Привет", null, list(person.speech_span))
	TEST_ASSERT(findtext(fake, "hear_druggy"), "Фальшивая речь получает эффекты слушателя: [fake]")
	TEST_ASSERT(findtext(fake, SPAN_DRUNK), "Фальшивая речь несёт состояние говорящего: [fake]")
	var/fake_radio = target.compose_fake_speech(person, /datum/language/common, "Помогите", "[FREQ_COMMON]", list(person.speech_span))
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
