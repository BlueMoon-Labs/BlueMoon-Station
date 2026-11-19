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
	desc = "Вы чувствуете, находится ли кто-то в эстральном цикле, и можете определить точную степень возбуждения существ рядом."
	value = 0
	mob_trait = TRAIT_ESTROUS_DETECT
	flavor_quirk = TRUE
	gain_text = span_love("Ваши органы чувств адаптируются, позволяя вам ощущать фертильность окружающих.")
	lose_text = span_notice("Ваши особые чувства регрессируют и вы больше не ощущаете фертильность окружающих.")
	human_only = FALSE

// Timestamp-based estrous quirk: no SSfastprocess polling.
#define ESTRUS_UPDATE_DELAY (10 MINUTES)

/datum/quirk/estrous_active
	name = "Эстральный Цикл"
	desc = "Ваш цикл усиливает вероятность оплодотворения: +5% сразу и по +5% каждые 10 минут до +20% в сумме. Сбрасывается при кульминации и приостанавливается во время беременности."
	value = 0
	mob_trait = TRAIT_ESTROUS_ACTIVE
	flavor_quirk = TRUE
	gain_text = span_love("Ваше тело горит от либидо.")
	lose_text = span_notice("Вы чувствуете, что лучше контролируете свое тело и мысли.")
	var/heat_type = "нахождение в эстральном цикле"
	var/current_stage = 0
	var/time_bonus = 0
	var/last_heat_reset = 0
	var/tmp/heat_timer

/datum/quirk/estrous_active/add()
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_ADD, PROC_REF(update_heat_type))
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_REMOVE, PROC_REF(update_heat_type))
	RegisterSignal(quirk_holder, COMSIG_PREGNANCY_STARTED, PROC_REF(on_pregnancy_started))
	RegisterSignal(quirk_holder, COMSIG_PREGNANCY_ENDED, PROC_REF(on_pregnancy_ended))
	RegisterSignal(quirk_holder, COMSIG_MOB_CLIMAX, PROC_REF(on_climax_reset))
	last_heat_reset = world.time
	update_heat_type()
	schedule_heat_tick()

/datum/quirk/estrous_active/remove()
	deltimer(heat_timer)
	heat_timer = null
	UnregisterSignal(quirk_holder, list(COMSIG_MOB_ORGAN_ADD, COMSIG_MOB_ORGAN_REMOVE, COMSIG_PREGNANCY_STARTED, COMSIG_PREGNANCY_ENDED, COMSIG_MOB_CLIMAX))

/datum/quirk/estrous_active/proc/schedule_heat_tick()
	deltimer(heat_timer)
	heat_timer = null
	if(QDELETED(quirk_holder) || HAS_TRAIT(quirk_holder, TRAIT_PREGNANT))
		return
	if(current_stage < 3)
		heat_timer = addtimer(CALLBACK(src, PROC_REF(on_heat_tick)), ESTRUS_UPDATE_DELAY, TIMER_STOPPABLE)

/datum/quirk/estrous_active/proc/on_heat_tick()
	heat_timer = null
	if(QDELETED(quirk_holder) || HAS_TRAIT(quirk_holder, TRAIT_PREGNANT))
		return
	var/old_stage = current_stage
	get_estrous_bonus()
	if(current_stage > old_stage)
		to_chat(quirk_holder, span_love(current_stage >= 3 ? "Ваша фертильность достигла максимума." : "Гормональная активность усиливается."))
	schedule_heat_tick()

/datum/quirk/estrous_active/proc/get_estrous_bonus()
	if(HAS_TRAIT(quirk_holder, TRAIT_PREGNANT))
		return 0
	var/mob/living/L = quirk_holder
	var/last_event = max(last_heat_reset, L?.last_climax || 0)
	current_stage = clamp(round(max(0, world.time - last_event) / ESTRUS_UPDATE_DELAY), 0, 3)
	time_bonus = current_stage * 0.05
	return 5 + round(time_bonus * 100)

/datum/quirk/estrous_active/proc/update_heat_type()
	SIGNAL_HANDLER
	heat_type = HAS_TRAIT(quirk_holder, TRAIT_PREGNANT) ? "беременн[quirk_holder.ru_aya()]" : "пахнет переизбытком феромонных гормонов"

/datum/quirk/estrous_active/proc/on_climax_reset()
	SIGNAL_HANDLER
	if(HAS_TRAIT(quirk_holder, TRAIT_PREGNANT))
		return
	last_heat_reset = world.time
	current_stage = 0
	time_bonus = 0
	schedule_heat_tick()

/datum/quirk/estrous_active/proc/on_pregnancy_started()
	SIGNAL_HANDLER
	last_heat_reset = world.time
	current_stage = 0
	time_bonus = 0
	update_heat_type()
	deltimer(heat_timer)
	heat_timer = null

/datum/quirk/estrous_active/proc/on_pregnancy_ended()
	SIGNAL_HANDLER
	last_heat_reset = world.time
	current_stage = 0
	time_bonus = 0
	update_heat_type()
	schedule_heat_tick()

#undef ESTRUS_UPDATE_DELAY

/datum/quirk/dnc_order
	name = "Приказ Не Клонировать"
	desc = "На вас записан приказ 'Не клонировать', в котором, как бы это странно не звучало, говорится, что вас нельзя клонировать. Вы все еще можете быть оживлены другими способами."
	value = 0
	mob_trait = TRAIT_DNC_ORDER
	medical_record_text = "Пациент имеет приказ DNC (Не Клонировать), в результате чего попытка воспользоваться клонированием будет отклонена."
