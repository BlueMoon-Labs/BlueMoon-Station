/datum/quirk/hypnotic_stupor //straight from skyrat
	name = "Гипнотический Ступор"
	desc = "Вы склонны к приступам крайнего ступора, который делает вас чрезвычайно внушаемым."
	value = 0
	human_only = TRUE
	gain_text = null // Handled by trauma.
	lose_text = null
	medical_record_text = "Пациент имеет не поддающееся лечению заболевание мозга, в результате чего он становится чрезвычайно... внушаемым...."

/datum/quirk/hypnotic_stupor/add()
	var/datum/brain_trauma/severe/hypnotic_stupor/T = new()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(T, TRAUMA_RESILIENCE_ABSOLUTE)
/*
/datum/quirk/infertile
	name = "Infertile"
	desc = "For one reason or another you simply don't seem able to get pregnant, no matter how hard you try."
	value = 0
	human_only = TRUE
	mob_trait = TRAIT_INFERTILE
	gain_text = "<span class='notice'>Your womb starts feeling dry and empty, all the life in it begins to fade away...</span>"
	lose_text = "<span class='love'>You feel the warm blow of life flooding your womb, full of newfound, vibrant fertility!</span>"
	medical_record_text = "Patient doesn't seem able to ovulate properly..."
*/

/datum/quirk/estrous_detection
	name = "Обнаружение Эструса"
	desc = "Вы обладаете особым чувством, чтобы определить, находится ли кто-то в эстральном цикле."
	value = 0
	mob_trait = TRAIT_ESTROUS_DETECT
	flavor_quirk = TRUE
	gain_text = span_love("Ваши органы чувств адаптируются, позволяя вам ощущать фертильность окружающих.")
	lose_text = span_notice("Ваши особые чувства регрессируют и вы больше не ощущаете фертильность окружающих.")
	human_only = FALSE

/datum/quirk/estrous_active
	name = "Эстральный Цикл"
	desc = "Ваш организм сгорает от желания совокупиться ради размножения. Удовлетворение вашей похоти сделает вас счастливей и ваша похоть кажется усилила шанс на оплодотворение, игнорирование этого желания может привести к тому что вы с каждыми условными 10 минут становитесь плодовитей на условные 5% (до 20% макс) пока вы не разрядитесь. Также увеличивает шансы чтобы заузлить партнера (Если есть член с узлом и у обоих префы Allow Knotting включен)"
	value = 0
	mob_trait = TRAIT_ESTROUS_ACTIVE
	flavor_quirk = TRUE
	gain_text = span_love("Ваше тело горит от желания заняться размножением.")
	lose_text = span_notice("Вы чувствуете, что лучше контролируете свое тело и мысли.")

	// Default heat message for examine text
	var/heat_type = "нахождение в эстральном цикле"

	// Type of interaction to be performed
	// Intended for use with downstream quirks
	var/positional_orientation = "принять участие в совокуплении ради размножения"

/datum/quirk/estrous_active/add()
	// Add examine hook
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(quirk_examine_estrous_active))
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_ADD, PROC_REF(update_heat_type))
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_REMOVE, PROC_REF(update_heat_type))

	// === ADD START ===
	RegisterSignal(quirk_holder, COMSIG_PREGNANCY_STARTED, PROC_REF(on_pregnancy_started))
	RegisterSignal(quirk_holder, COMSIG_PREGNANCY_ENDED, PROC_REF(on_pregnancy_ended))
	RegisterSignal(quirk_holder, COMSIG_MOB_CLIMAX, PROC_REF(_on_climax_reset))
	// === ADD END ===

/datum/quirk/estrous_active/remove()
	if(!QDELETED(quirk_holder))
		STOP_PROCESSING(SSfastprocess, src)

	UnregisterSignal(quirk_holder, list(
		COMSIG_MOB_ORGAN_ADD,
		COMSIG_MOB_ORGAN_REMOVE,
		COMSIG_PARENT_EXAMINE,
		COMSIG_PREGNANCY_STARTED,
		COMSIG_PREGNANCY_ENDED,
		COMSIG_MOB_CLIMAX, // добавим в п. B
	))


/datum/quirk/estrous_active/post_add()
	update_heat_type()

	if(isliving(quirk_holder))
		var/mob/living/L = quirk_holder
		if(!L.last_climax)
			L.last_climax = world.time

		START_PROCESSING(SSfastprocess, src)

// === СИСТЕМА ОБНОВЛЕНИЯ ЭСТРАЛЬНОГО ЦИКЛА ===

// Как часто обновлять (в проде 10 MINUTES, в тесте можно 1 MINUTES)
#define ESTRUS_UPDATE_DELAY (10 MINUTES)

/datum/quirk/estrous_active
	var/current_stage = 0       // текущая стадия (0–5)
	var/time_bonus = 0          // текущий бонус (0–0.15)
	var/last_update = 0         // время последнего апдейта

// Вызывается при добавлении трейта
/datum/quirk/estrous_active/post_add()
	update_heat_type()

	if(isliving(quirk_holder))
		var/mob/living/L = quirk_holder
		if(!L.last_climax)
			L.last_climax = world.time

		START_PROCESSING(SSfastprocess, src) // запускаем автообновление

// Останавливаем процесс при снятии трейта
/datum/quirk/estrous_active/remove()
	if(!QDELETED(quirk_holder))
		STOP_PROCESSING(SSfastprocess, src)
	UnregisterSignal(quirk_holder, list(COMSIG_MOB_ORGAN_ADD, COMSIG_MOB_ORGAN_REMOVE, COMSIG_PARENT_EXAMINE))

// Основной цикл
/datum/quirk/estrous_active/process()
	if(QDELETED(quirk_holder))
		STOP_PROCESSING(SSfastprocess, src)
		return
	if(!isliving(quirk_holder))
		return
	if(HAS_TRAIT(quirk_holder, TRAIT_PREGNANT))
		return // пауза цикла на период беременности

	var/mob/living/L = quirk_holder
	var/time_since_last_climax = max(world.time - L.last_climax, 0)

	// Расчёт бонуса
	var/new_stage = round(time_since_last_climax / (10 MINUTES))
	var/new_bonus = clamp((time_since_last_climax / (10 MINUTES)) * 0.05, 0, 0.15)

	if(new_stage > current_stage)
		current_stage = new_stage
		if(current_stage < 3)
			to_chat(L, span_love("Воздержание для вас становится всё мучительней, гормоны бурлят в вас усиливая эффекты"))
		else
			to_chat(L, span_love("Ваши репродуктивные органы от воздержания просто горят, ваши шансы достигли максимума."))

	if(new_bonus != time_bonus)
		time_bonus = new_bonus


/datum/quirk/estrous_active/proc/update_heat_type()
	// Define temporary list of heat phrases
	var/list/heat_phrases = list()

	// Check for male hormonal organ
	if(quirk_holder.has_balls())
		heat_phrases += "сильный стояк"

	// Check for female hormonal organ
	if(quirk_holder.getorganslot(ORGAN_SLOT_WOMB))
		heat_phrases += "сильную течку"

	// Check for synthetic
	if(isrobotic(quirk_holder))
		heat_phrases += "множество ошибок в гормональной программе"

	// Build English list
	heat_type = english_list(heat_phrases, nothing_text = "переизбыток гормонов")

/datum/quirk/estrous_active/proc/_on_climax_reset(datum/source, datum/reagents/R, atom/target, obj/item/organ/genital/sender, obj/item/organ/genital/receiver, spill, anon)
	SIGNAL_HANDLER

	if(!isliving(quirk_holder))
		return
	if(HAS_TRAIT(quirk_holder, TRAIT_PREGNANT))
		return // во время беременности цикл "спит"

	current_stage = 0
	time_bonus = 0

/datum/quirk/estrous_active/proc/quirk_examine_estrous_active(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	SIGNAL_HANDLER

	// Check if human examiner exists
	if(!istype(examiner))
		return

	// Check if examiner lacks the trait, or is self examining
	if(!HAS_TRAIT(examiner, TRAIT_ESTROUS_DETECT) || (examiner == quirk_holder))
		return

	// Add quirk message
	examine_list += span_love("<b>[quirk_holder.ru_who(TRUE)]</b> испытывает [heat_type], однозначно желая [positional_orientation].")

// === НОВЫЕ ПРОЦЕДУРЫ ДЛЯ БЕРЕМЕННОСТИ ===

/datum/quirk/estrous_active/proc/on_pregnancy_started(datum/source)
	SIGNAL_HANDLER

	if(!isliving(quirk_holder))
		return

	var/mob/living/L = quirk_holder

	// Если уже беременна — не дублируем сообщение
	if(HAS_TRAIT(L, TRAIT_PREGNANT) && heat_type == "беременность")
		return

	to_chat(L, span_love("Вы ощущаете, как внутри вас зарождается новая жизнь... Ваш эстральный цикл стихает."))
	current_stage = 0
	time_bonus = 0
	heat_type = "беременность"


/datum/quirk/estrous_active/proc/on_pregnancy_ended(datum/source)
	SIGNAL_HANDLER

	if(!isliving(quirk_holder))
		return

	var/mob/living/L = quirk_holder

	// Проверяем, что действительно была беременна
	if(!HAS_TRAIT(L, TRAIT_PREGNANT) && heat_type == "беременность")
		to_chat(L, span_love("Ваш организм приходит в себя после родов, и вы чувствуете, как гормоны вновь начинают бурлить..."))
		update_heat_type()
		current_stage = 0
		time_bonus = 0

/datum/quirk/dnc_order
	name = "Приказ Не Клонировать"
	desc = "На вас записан приказ 'Не клонировать', в котором, как бы это странно не звучало, говорится, что вас нельзя клонировать. Вы все еще можете быть оживлены другими способами."
	value = 0
	mob_trait = TRAIT_DNC_ORDER
	medical_record_text = "Пациент имеет приказ DNC (Не Клонировать), в результате чего попытка воспользоваться клонированием будет отклонена."
