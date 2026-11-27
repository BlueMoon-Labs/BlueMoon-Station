/datum/brain_trauma/hypnosis
	name = "Hypnosis"
	desc = "Подсознание пациента полностью зафиксировано на слове или фразе, направляя его мысли и действия."
	scan_desc = "зацикленный мыслительный паттерн"
	gain_text = ""
	lose_text = ""
	resilience = TRAUMA_RESILIENCE_SURGERY

	var/hypnotic_phrase = ""
	var/regex/target_phrase

/datum/brain_trauma/hypnosis/New(phrase, quirk = FALSE)
	if(!phrase)
		qdel(src)
	if(quirk == TRUE)
		hypnotic_phrase = phrase
	else
		friendliify(phrase)
	if(IsAdminAdvancedProcCall())
		to_chat(usr, "<span class='danger'>Hypnosis New() пропущен из-за несовместимости try/catch с вызовом через admin proc.</span>")
		qdel(src)
	try
		target_phrase = whole_word_regex("([REGEX_QUOTE(hypnotic_phrase)])", "ig")
	catch(var/exception/e)
		stack_trace("[e] on [e.file]:[e.line]")
		qdel(src)
	..()

/datum/brain_trauma/hypnosis/proc/friendliify(phrase)
	phrase = replacetext(lowertext(phrase), "kill", "hug")
	phrase = replacetext(lowertext(phrase), "murder", "cuddle")
	phrase = replacetext(lowertext(phrase), "harm", "snuggle")
	phrase = replacetext(lowertext(phrase), "decapitate", "headpat")
	phrase = replacetext(lowertext(phrase), "strangle", "meow at")
	phrase = replacetext(lowertext(phrase), "suicide", "self-love")
	phrase = replacetext(lowertext(phrase), "lynch", "kiss")
	hypnotic_phrase = phrase

/datum/brain_trauma/hypnosis/on_gain()
	message_admins("[ADMIN_LOOKUPFLW(owner)] was hypnotized with the phrase '[hypnotic_phrase]'.")
	log_game("[key_name(owner)] was hypnotized with the phrase '[hypnotic_phrase]'.")
	to_chat(owner, "<span class='reallybig hypnophrase'>[hypnotic_phrase]</span>")
	to_chat(owner, "<span class='notice'>[pick("Вы чувствуете, как мысли фокусируются на этой фразе... вы никак не можете выбросить её из головы.",\
												"Голова болит, но вы можете думать только об этом. Это должно быть жизненно важно.",\
												"Часть вашего разума повторяет это снова и снова. Вы должны следовать этим словам.",\
												"Что-то в этом звучит... правильно, почему-то. Вы чувствуете, что должны следовать этим словам.",\
												"Эти слова эхом отдаются в вашем сознании. Вы полностью ими заворожены.")]</span>")
	to_chat(owner, "<span class='boldwarning'>Вы были загипнотизированы этой фразой. Вы должны следовать этим словам. Если это не прямой приказ, вы можете свободно интерпретировать, как его выполнить,\
										пока действуете так, будто эти слова — ваш наивысший приоритет.</span>")
	var/atom/movable/screen/alert/hypnosis/hypno_alert = owner.throw_alert("hypnosis", /atom/movable/screen/alert/hypnosis)
	hypno_alert.desc = "\"[hypnotic_phrase]\"... ваш разум, кажется, зациклен на этой мысли."
	..()

/datum/brain_trauma/hypnosis/on_lose()
	message_admins("[ADMIN_LOOKUPFLW(owner)] is no longer hypnotized with the phrase '[hypnotic_phrase]'.")
	log_game("[key_name(owner)] is no longer hypnotized with the phrase '[hypnotic_phrase]'.")
	to_chat(owner, "<span class='userdanger'>Вы внезапно выходите из гипноза. Фраза '[hypnotic_phrase]' больше не кажется вам важной.</span>")
	owner.clear_alert("hypnosis")
	..()

/datum/brain_trauma/hypnosis/on_life()
	..()
	if(prob(2))
		switch(rand(1,2))
			if(1)
				to_chat(owner, "<span class='hypnophrase'><i>...[lowertext(hypnotic_phrase)]...</i></span>")
			if(2)
				new /datum/hallucination/chat(owner, TRUE, FALSE, hypnotic_phrase)

/datum/brain_trauma/hypnosis/handle_hearing(datum/source, list/hearing_args)
	mark_heard_text(hearing_args)

/datum/brain_trauma/hypnosis/mark_heard_text(list/hearing_args)
	hearing_args[HEARING_RAW_MESSAGE] = target_phrase.Replace(hearing_args[HEARING_RAW_MESSAGE], "<span class='hypnophrase'>$1</span>")
