
/datum/mutation/human/bm
	var/mob_trait


/datum/mutation/human/bm/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	if(mob_trait)
		if(HAS_TRAIT(owner, mob_trait))
			instability = 0
			return
		else
			ADD_TRAIT(owner, mob_trait, GENETIC_MUTATION)
			passtable_on(owner, GENETIC_MUTATION)


/datum/mutation/human/bm/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	if(mob_trait)
		if(HAS_TRAIT(owner, mob_trait))
			REMOVE_TRAIT(owner, mob_trait, GENETIC_MUTATION)
			passtable_off(owner, GENETIC_MUTATION)


////////////////

/datum/mutation/human/bm/alcohol_tolerance
	name = "Устойчивость к Алкоголю"
	desc = "Эффект опьянения наступает медленней, побочные эффекты алкоголя облегчены."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_ALCOHOL_TOLERANCE
	text_gain_indication = "<span class='notice'>Вы чувствуете, что могли бы осушить целую бочку спиртного!</span>"
	text_lose_indication = "<span class='danger'>Вы более не ощущаете себя устойчивым к алкоголю. Почему-то.</span>"


/datum/mutation/human/bm/apathetic
	name = "Равнодушный"
	desc = "Вам на всё наплевать. Круто жить в таком мире, наверное."
	quality = POSITIVE
	difficulty = 12
	instability = 20

/datum/mutation/human/bm/apathetic/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/datum/component/mood/mood = owner.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier = 0.8

/datum/mutation/human/bm/apathetic/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(owner)
		var/datum/component/mood/mood = owner.GetComponent(/datum/component/mood)
		if(mood)
			mood.mood_modifier = 1 //Change this once/if species get their own mood modifiers.

/datum/mutation/human/bm/drunkhealing
	name = "Пьяный Угар"
	desc = "Пьяному море по колено. В состоянии опьянения вы медленно восстанавливаетесь от полученных травм."
	quality = POSITIVE
	difficulty = 16
	instability = 30
	mob_trait = TRAIT_DRUNK_HEALING
	text_gain_indication = "<span class='notice'>Вы чувствуете, что от выпивки одни только плюсы.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, что выпивка больше не облегчит боль.</span>"

/datum/mutation/human/bm/empath
	name = "Эмпат"
	desc = "Будь то шестое чувство или тщательное изучения языка тела, вы можете с определить настроение цели посмотрев на неё."
	quality = POSITIVE
	difficulty = 12
	instability = 20 // SPLURT EDIT
	mob_trait = TRAIT_EMPATH
	text_gain_indication = "<span class='notice'>Вы чувствуете себя в гармонии с другими.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете себя изолированно.</span>"

/datum/mutation/human/bm/freerunning
	name = "Паркурщик"
	desc = "Вы отлично справляетесь с выполнением быстрых движений! Вы сможете залезать на столы гораздо быстрее."
	quality = POSITIVE
	difficulty = 16
	instability = 30
	mob_trait = TRAIT_FREERUNNING
	text_gain_indication = "<span class='notice'>Вы чувствуете легкость в ногах!</span>"
	text_lose_indication = "<span class='danger'>Вы снова чувствуете себя неуклюже.</span>"

/datum/mutation/human/bm/friendly
	name = "Дружелюбный"
	desc = "Вы лучше всех обнимаетесь, особенно при правильном настроении."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_FRIENDLY
	text_gain_indication = "<span class='notice'>Вы хотите кого-нибудь обнять.</span>"
	text_lose_indication = "<span class='danger'>Вы больше не чувствуете желания обниматься с другими.</span>"


/datum/mutation/human/bm/jolly
	name = "Жизнерадостный"
	desc = "Иногда вы просто счастливы."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_JOLLY


/datum/mutation/human/bm/jolly/on_life()
	if(prob(0.05))
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "jolly", /datum/mood_event/jolly)

/datum/mutation/human/bm/light_step
	name = "Легкая Походка"
	desc = "Вы ловки, удачливы и всегда осторожны. Хождение по разбитому стеклу и острым предметам менее болезненно и тише в вашем случае, к тому же вы не оставляете за собой следов."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_LIGHT_STEP
	text_gain_indication = "<span class='notice'>Вы ступаете с лёгкостью.</span>"
	text_lose_indication = "<span class='danger'>Вы топаете также, как и прежде.</span>"

/datum/mutation/human/bm/quick_step
	name = "Быстрый Шаг"
	desc = "Во время ходьбы вы двигаетесь решительно, в своем ритме."
	quality = POSITIVE
	difficulty = 16
	instability = 30
	mob_trait = TRAIT_SPEEDY_STEP
	text_gain_indication = "<span class='notice'>Вы чувствуете себя решительно. Нельзя терять времени.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете себя менее решительно. К чему такая спешка?</span>"

/datum/mutation/human/bm/musician
	name = "Музыкант"
	desc = "Вы можете настраивать ручные инструменты для игры мелодий, что снимают определенные негативные эффекты и успокаивают душу."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_MUSICIAN
	text_gain_indication = "<span class='notice'>Вы знаете всё о музыкальных инструментах.</span>"
	text_lose_indication = "<span class='danger'>Вы забываете, как работают музыкальные инструменты.</span>"



/datum/mutation/human/bm/selfaware
	name = "Сознательный"
	desc = "Вы хорошо знаете собственное тело и можете точно оценивать серьёзность ваших ран."
	quality = POSITIVE
	difficulty = 16
	instability = 30
	mob_trait = TRAIT_SELF_AWARE

/datum/mutation/human/bm/skittish
	name = "Шустрый"
	desc = "Вы можете прятаться при опасности в шкаф, пока имеется доступ."
	quality = POSITIVE
	difficulty = 16
	instability = 30
	mob_trait = TRAIT_SKITTISH

/datum/mutation/human/bm/spiritual
	name = "Духовный"
	desc = "Вы в гармонии с богами и ваши молитвы с большей вероятностью будут услышаны. Или нет."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_SPIRITUAL
	text_gain_indication = "<span class='notice'>Ваша вера в богов крепнет.</span>"
	text_lose_indication = "<span class='danger'>Ваша вера в богов слабнет.</span>"

/datum/mutation/human/bm/tagger
	name = "Граффити-Художник"
	desc = "Вы - художник с опытом. Рисуя граффити, вы тратите в два раза меньше краски."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_TAGGER
	text_gain_indication = "<span class='notice'>Вы знаете, как правильно разрисовывать стены.</span>"
	text_lose_indication = "<span class='danger'>Вы забываете, как правильно разрисовывать стены.</span>"



/datum/mutation/human/bm/voracious
	name = "Прожорливый"
	desc = "Ничто не встанет между вами и вашей едой. Вы едите в два раза быстрее!"
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_VORACIOUS
	text_gain_indication = "<span class='notice'>Вы преголодны.</span>"
	text_lose_indication = "<span class='danger'>Жор отступает.</span>"


/datum/mutation/human/bm/bloodpressure
	name = "Истинная полицитемия"
	desc = "У вас Истинная полицитемия в ремиссии, повышающая общее количество крови и скорость её восстановления!"
	quality = POSITIVE
	difficulty = 16
	instability = 30 //I honeslty dunno if this is a good trait? I just means you use more of medbays blood and make janitors madder, but you also regen blood a lil faster.
	mob_trait = TRAIT_HIGH_BLOOD
	text_gain_indication = "<span class='notice'>Вы чувствуете себя полным крови!</span>"
	text_lose_indication = "<span class='notice'>Кажется, ваше кровяное давление понизилось.</span>"

/datum/mutation/human/bm/bloodpressure/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	owner.blood_ratio = 1.2
	owner.blood_volume += BLOOD_VOLUME_NORMAL * (owner.blood_ratio - 1)

/datum/mutation/human/bm/bloodpressure/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(owner)
		owner.blood_ratio = 1

/datum/mutation/human/bm/night_vision
	name = "Ночное Зрение"
	desc = "Вы видите лучше большинства в кромешной тьме."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_NIGHT_VISION
	text_gain_indication = "<span class='notice'>Тени кажутся светлее.</span>"
	text_lose_indication = "<span class='danger'>Всё кажется чуточку темнее.</span>"

/datum/mutation/human/bm/night_vision/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	owner.update_sight()

/datum/mutation/human/bm/hard_soles
	name = "Твёрдые ступни" // BLUEMOON EDIT - typo
	desc = "Вы привыкли ходить босиком, а потому осколки стекла и мусор никак не вредят вашим ногам."
	quality = POSITIVE
	difficulty = 12
	instability = 20 // BLUEMOON EDIT - было 2
	mob_trait = TRAIT_HARD_SOLES
	text_gain_indication = "<span class='notice'>Мусор под ногами теперь вам не помеха.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, как пол под вашими ногами становится грубее.</span>"

//predominantly negative traits

/datum/mutation/human/bm/blooddeficiency
	name = "Острое Малокровие"
	desc = "Ваше тело не производит достаточно крови для поддержания себя."
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	text_gain_indication = "<span class='danger'>Вы чувствуете, как ваши силы угасают.</span>"
	text_lose_indication = "<span class='notice'>Былые силы возвращаются.</span>"

/datum/mutation/human/bm/blooddeficiency/on_life()

	if(NOBLOOD in owner.dna.species.species_traits) //can't lose blood if your species doesn't have any
		return
	else
		owner.blood_volume -= 0.2

/datum/mutation/human/bm/depression
	name = "Депрессия"
	desc = "Иногда вы просто ненавидите жизнь."
	mob_trait = TRAIT_DEPRESSION
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	text_gain_indication = "<span class='danger'>У вас начинается депрессия.</span>"
	text_lose_indication = "<span class='notice'>У вас больше нет депрессии.</span>" //if only it were that easy!


/datum/mutation/human/bm/depression/on_life()
	if(prob(0.05))
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "depression", /datum/mood_event/depression)


/datum/mutation/human/bm/heavy_sleeper
	name = "Крепко спящий"
	desc = "Вы спите как убитый! Ваш сон длится чуть дольше."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_HEAVY_SLEEPER
	text_gain_indication = "<span class='danger'>Вы чувствуете сонливость.</span>"
	text_lose_indication = "<span class='notice'>Вы снова чувствуете себя бодрым!.</span>"

/datum/mutation/human/bm/brainproblems
	name = "Опухоль головного мозга"
	desc = "В вашей голове есть маленький друг, который медленно разрушает мозг. Следует прихватить с собой маннитол!"
	quality = NEGATIVE
	difficulty = 8
	instability = -30
	text_gain_indication = "<span class='danger'>Вы чувствуете, как ваши извилины разглаживаются.</span>"
	text_lose_indication = "<span class='notice'>Извилины снова появляются на вашем мозгу.</span>"



/datum/mutation/human/bm/brainproblems/on_life()
	owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.2)



/datum/mutation/human/bm/nyctophobia
	name = "Никтофобия"
	desc = "Вы боитесь тьмы и осторожничаете, пребывая в ней."
	quality = NEGATIVE
	difficulty = 8
	instability = -10

/datum/mutation/human/bm/nyctophobia/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_holder_moved))

/datum/mutation/human/bm/nyctophobia/on_losing(mob/living/carbon/human/owner)
	. = ..()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "nyctophobia")

/// Called when the quirk holder moves. Updates the quirk holder's mood.
/datum/mutation/human/bm/nyctophobia/proc/on_holder_moved(mob/living/source, atom/old_loc, dir, forced)
	if(owner.stat != CONSCIOUS || owner.IsSleeping() || owner.IsUnconscious())
		return

	var/mob/living/carbon/human/human_holder = owner

	if(human_holder.dna?.species.id in list(SPECIES_SHADOW, SPECIES_NIGHTMARE))
		return

	if((human_holder.sight & SEE_TURFS) == SEE_TURFS)
		return

	var/turf/holder_turf = get_turf(owner)

	var/lums = holder_turf.get_lumcount()

	if(lums > 0.2)
		SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "nyctophobia")
		return

	if(owner.m_intent == MOVE_INTENT_RUN)
		to_chat(owner, span_warning("Не торопись... ты в кромешной тьме..."))
		owner.toggle_move_intent()
	SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "nyctophobia", /datum/mood_event/nyctophobia)

/datum/mutation/human/bm/lightless
	name = "Светочувствительность"
	desc = "Яркий свет вызывает у вас раздражение. Глаза начинают слезиться, кожа чешется под действием ионизирующего излучения, а волосы становятся сухими и непослушными. Возможно, это болезнь. Если бы только Nanotrasen учитывали ваши потребности..."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	text_gain_indication = "<span class='danger'>Яркий свет раздражает вас.</span>"
	text_lose_indication = "<span class='notice'>Вы не боитесь не бояться света.</span>"

/datum/mutation/human/bm/lightless/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_holder_moved))

/datum/mutation/human/bm/lightless/on_losing(mob/living/carbon/human/owner)
	. = ..()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "brightlight")

/datum/mutation/human/bm/lightless/proc/on_holder_moved(mob/living/source, atom/old_loc, dir, forced)
	if(owner.stat != CONSCIOUS || owner.IsSleeping() || owner.IsUnconscious())
		return

	var/mob/living/carbon/human/human_holder = owner

	if(human_holder.dna?.species.id in list(SPECIES_SHADOW, SPECIES_NIGHTMARE))
		return

	if((human_holder.sight & SEE_TURFS) == SEE_TURFS)
		return

	var/turf/holder_turf = get_turf(owner)

	var/lums = holder_turf.get_lumcount()

	if(lums < 0.8)
		SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "brightlight")
		return

	SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "brightlight", /datum/mood_event/brightlight)


/datum/mutation/human/bm/lightless/on_life()
	var/turf/T = get_turf(owner)
	var/lums = T.get_lumcount()
	if(lums >= 0.8)
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, "brightlight", /datum/mood_event/brightlight)
	else
		SEND_SIGNAL(owner, COMSIG_CLEAR_MOOD_EVENT, "brightlight")

/datum/mutation/human/bm/nonviolent
	name = "Пацифист"
	desc = "Насилие противно вам настолько, что вы не можете никому навредить."
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	mob_trait = TRAIT_PACIFISM
	text_gain_indication = "<span class='danger'>Вы отвергаете саму мысль о возможном насилии!</span>"
	text_lose_indication = "<span class='notice'>Вам кажется, что вы снова можете постоять за себя.</span>"


/datum/mutation/human/bm/paraplegic
	name = "Парализованный"
	desc = "Ваши ноги не работают. Ничто и никогда не исправит это. Подумайте о хорошем — о бесплатной инвалидной коляске!"
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = -40
	mob_trait = TRAIT_PARA
	text_gain_indication = null // Handled by trauma.
	text_lose_indication = null

/datum/mutation/human/bm/paraplegic/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/datum/brain_trauma/severe/paralysis/paraplegic/T = new()

	owner.gain_trauma(T, TRAUMA_RESILIENCE_ABSOLUTE)

/*
/datum/mutation/human/bm/poor_aim
	name = "Ужасный стрелок"
	desc = "Ваши навыки обращения с оружием не позволяют точно прицелиться даже для того, чтобы спасти свою жизнь. Стрельба с двух рук даже не обсуждается."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_POOR_AIM
*/

/datum/mutation/human/bm/prosopagnosia
	name = "Прозопагнозия"
	desc = "Расстройство не позволяет вам различать лица, совсем."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_PROSOPAGNOSIA

/datum/mutation/human/bm/insanity
	name = "Диссоциативное расстройство"
	desc = "Вы страдаете от тяжелого расстройства и видите яркие галлюцинации. ЛСД подавляет болезнь, к побочному эффекту этого вещества у вас невосприимчивость."
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	//no mob trait because it's handled uniquely
	text_gain_indication = "<span class='userdanger'>...</span>"
	text_lose_indication = "<span class='notice'>Вы чувствуете себя в гармонии с миром.</span>"


/datum/mutation/human/bm/insanity/on_life()
	if(owner.reagents.has_reagent(/datum/reagent/toxin/mindbreaker))
		owner.hallucination = 0
		return
	if(prob(2)) //we'll all be mad soon enough
		madness()

/datum/mutation/human/bm/insanity/proc/madness()
	owner.hallucination += rand(10, 25)

/datum/mutation/human/bm/insanity/on_acquiring(mob/living/carbon/human/owner)
	. = ..() //I don't /think/ we'll need this but for newbies who think "roleplay as insane" = "license to kill" it's probably a good thing to have
	if(!owner.mind || owner.mind.special_role)
		return
	to_chat(owner, "<span class='big bold info'>Пожалуйста учтите, что диссоциативное расстройство НЕ даёт права атаковать или вмешиваться в \
	раунд. Вы не антагонист и правила будут к вам применены те же, что и к обычным членам экипажа.</span>")


/datum/mutation/human/bm/phobia
	name = "Фобия"
	desc = "Прошлое нанесло вам травму на всю жизнь и продолжает преследовать, когда вы встречаетесь с величайшими из своих страхов."
	quality = NEGATIVE
	difficulty = 8
	instability = -20 // It can hardstun you. You can be a job that your phobia targets...
	text_gain_indication = "<span class='danger'>Вы начинаете трястись, когда всепоглощающий страх захватывает ваш разум.</span>"
	text_lose_indication = "<span class='notice'>Ваша уверенность сметает страх, что терзал вас долгое время.</span>"
	var/datum/brain_trauma/mild/phobia/phobia

/datum/mutation/human/bm/phobia/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	phobia = new
	owner.gain_trauma(phobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/mutation/human/bm/phobia/on_losing(mob/living/carbon/human/owner)
	. = ..()

	owner?.cure_trauma_type(phobia, TRAUMA_RESILIENCE_ABSOLUTE)




/datum/mutation/human/bm/unstable
	name = "Нестабильный"
	desc = "Душевные раны делают восстановление рассудка после его потери невозможным. Аккуратнее с управлением настроением!"
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	mob_trait = TRAIT_UNSTABLE
	text_gain_indication = "<span class='danger'>Слишком многое творится в вашей голове.</span>"
	text_lose_indication = "<span class='notice'>Ваш разум наконец-то успокоился.</span>"



/datum/mutation/human/bm/coldblooded
	name = "Холоднокровие"
	desc = "Ваше тело не генерирует тепло, из-за чего требуется внешняя регуляция."
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	mob_trait = TRAIT_COLDBLOODED
	text_gain_indication = "<span class='notice'>Вы чувствуете, как кровь стынет в жилах.</span>"
	text_lose_indication = "<span class='notice'>Вы чувствуете себя теплокровнее.</span>"

/datum/mutation/human/bm/monophobia
	name = "Монофобия"
	desc = "Вы испытываете стресс, когда не находитесь в компании других, вызывающий реакции от болезненного состояния до инфарктов."
	quality = NEGATIVE
	difficulty = 8
	instability = -30 // Might change it to 4.
	text_gain_indication = "<span class='danger'>Вы чувствуете себя одиноко...</span>"
	text_lose_indication = "<span class='notice'>Вы чувствуете, что одному быть не так уж и плохо.</span>"

/datum/mutation/human/bm/monophobia/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	owner.gain_trauma(/datum/brain_trauma/severe/monophobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/mutation/human/bm/monophobia/on_losing(mob/living/carbon/human/owner)
	. = ..()

	owner?.cure_trauma_type(/datum/brain_trauma/severe/monophobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/mutation/human/bm/no_smell
	name = "Аносмия"
	desc = "Вы не ощущаете запахи! Вы не сможете обнаружать определенные бесцветные газы."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_ANOSMIA
	text_gain_indication = "<span class='notice'>Вы не чувствуете запахов!</span>"
	text_lose_indication = "<span class='notice'>Вы снова чувствуете запахи!</span>"

/datum/mutation/human/bm/paper_skin
	name = "Бумажная Кожа"
	desc = "Вы слабы плотью, порезаться становится гораздо легче."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_PAPER_SKIN
	text_gain_indication = "<span class='notice'>Вы чувствуете, что ваша плоть слаба!</span>"
	text_lose_indication = "<span class='notice'>Ваша плоть снова крепка!</span>"

/datum/mutation/human/bm/glass_bones
	name = "Хрустальные Кости"
	desc = "Ваши кости гораздо более хрупкие, потому уязвимы к переломам."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_GLASS_BONES
	text_gain_indication = "<span class='notice'>Ваши кости ощущаются слабыми!</span>"
	text_lose_indication = "<span class='notice'>Ваши кости ощущаются более прочными!</span>"



/datum/mutation/human/bm/alcohol_intolerance
	name = "Непереносимость Алкоголя"
	desc = "Вы получаете урон токсинами вместо того, чтобы пьянеть при употреблении алкоголя."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_TOXIC_ALCOHOL


/datum/mutation/human/bm/alcohol_intolerance/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/datum/species/species = owner.dna.species
	species.disliked_food |= ALCOHOL

/datum/mutation/human/bm/alcohol_intolerance/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(owner)
		var/datum/species/species = owner.dna.species
		species.disliked_food &= ~ALCOHOL
//traits with no real impact that can be taken freely
//MAKE SURE THESE DO NOT MAJORLY IMPACT GAMEPLAY. those should be positive or negative traits.

/datum/mutation/human/bm/no_taste
	name = "Агевзия"
	desc = "Вы не чувствуете вкуса! Ядовитая еда всё ещё будет иметь пагубное воздействие."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_AGEUSIA
	text_gain_indication = "<span class='notice'>Вы не чувствуете вкуса!</span>"
	text_lose_indication = "<span class='notice'>Вы снова чувствуете вкус!</span>"


/datum/mutation/human/bm/snob
	name = "Сноб"
	desc = "Вас волнуют вещи утонченные, если комната выглядит некрасиво, она просто не стоит того, верно?"
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = "<span class='notice'>Вы считаете, что знаете, как должны выглядеть вещи.</span>"
	text_lose_indication = "<span class='notice'>Кого вообще волнует декор?</span>"
	mob_trait = TRAIT_SNOB

/datum/mutation/human/bm/pineapple_liker
	name = "Пристрастие к Ананасам"
	desc = "Вы обожаете плоды ананасового дерева. Вы никак не можете прекратить наслаждаться этим сладким вкусом!"
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = "<span class='notice'>У вас появляется сильное желание вкусить мякоти ананаса.</span>"
	text_lose_indication = "<span class='notice'>По всей видимости, ваше отношение к ананасам возвращается к нейтральному.</span>"

/datum/mutation/human/bm/pineapple_liker/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/datum/species/species = owner.dna.species
	species.liked_food |= PINEAPPLE

/datum/mutation/human/bm/pineapple_liker/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(owner)
		var/datum/species/species = owner.dna.species
		species.liked_food &= ~PINEAPPLE

/datum/mutation/human/bm/pineapple_hater
	name = "Неприязнь к Ананасам"
	desc = "Вы испытываете сильнейшее отвращение к плодам ананасового дерева. Серьёзно, кому они нравятся? И какой безумец посмел положить их на пиццу!?"
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = "<span class='notice'>Вы задумываетесь над тем, какому идиоту вообще могут понравиться ананасы...</span>"
	text_lose_indication = "<span class='notice'>По всей видимости, ваше отношение к ананасам возвращается к нейтральному.</span>"

/datum/mutation/human/bm/pineapple_hater/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/datum/species/species = owner.dna.species
	species.disliked_food |= PINEAPPLE

/datum/mutation/human/bm/pineapple_hater/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(owner)
		var/datum/species/species = owner.dna.species
		species.disliked_food &= ~PINEAPPLE

/datum/mutation/human/bm/deviant_tastes
	name = "Извращенные Вкусы"
	desc = "Вам не нравится то, что нравится большинству и наоборот."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = "<span class='notice'>Появляется желание съесть чего-нибудь странного.</span>"
	text_lose_indication = "<span class='notice'>Вам снова нравится есть типичную пищу.</span>"

/datum/mutation/human/bm/deviant_tastes/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/datum/species/species = owner.dna.species
	var/liked = species.liked_food
	species.liked_food = species.disliked_food
	species.disliked_food = liked

/datum/mutation/human/bm/deviant_tastes/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(owner)
		var/datum/species/species = owner.dna.species
		species.liked_food = initial(species.liked_food)
		species.disliked_food = initial(species.disliked_food)


/datum/mutation/human/bm/maso
	name = "Мазохизм"
	desc = "Вас возбуждает боль."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_MASO
	text_gain_indication = "<span class='notice'>Вы хотите, чтобы вам причинили боль.</span>"
	text_lose_indication = "<span class='notice'>Боль больше не так заводит.</span>"
/// закладка.
/datum/mutation/human/bm/libido
	name = "Нимфомания"
	desc = "Вы быстрее возбуждаетесь."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_NYMPHO
	text_gain_indication = "<span class='notice'>У вас зудит в промежности.</span>"
	text_lose_indication = "<span class='notice'>Вы более не чувствуете того приятного жжения.</span>"

/datum/mutation/human/bm/libido/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	owner.arousal_rate = 3 * initial(owner.arousal_rate)

/datum/mutation/human/bm/libido/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(!owner)
		return
	owner.arousal_rate = initial(owner.arousal_rate)

/datum/mutation/human/bm/trashcan
	name = "Мусорный бак"
	desc = "Вы можете есть мусор."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = "<span class='notice'>В голову приходит мысль пожевать банку из-под содовой.</span>"
	text_lose_indication = "<span class='notice'>Вы больше не хотите есть мусор.</span>"
	mob_trait = TRAIT_TRASHCAN

// Moved Colorist quirk to a loadout item

/datum/mutation/human/bm/salt_sensitive
	name = "Чувствительность к Натрию"
	desc = "Ваше тело чувствительно к натрию, потому обжигается при контакте с ним. Употребление крайне не рекомендуется."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_SALT_SENSITIVE



/datum/mutation/human/bm/photographer
	name = "Фотограф"
	desc = "Вы знаете как пользоваться фотоаппаратом, сокращая время между фотографией."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_PHOTOGRAPHER
	text_gain_indication = "<span class='notice'>Вы знаете всё о фотографиях.</span>"
	text_lose_indication = "<span class='danger'>Вы забываете, как работают фотокамеры.</span>"


/datum/mutation/human/bm/steel_ass
	name = "Стальные Булки"
	desc = "Вы ни разу не пропускали день ягодиц. У вас полный иммунитет ко всем формам ударов по заднице, и любой, кто попытается наградить вас шлепком, как правило, получит перелом кисти."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_STEEL_ASS
	text_gain_indication = "<span class='notice'>Ваш зад может составить конкуренцию големскому.</span>"
	text_lose_indication = "<span class='danger'>Ваш зад ощущается более мягким и уязвимым к шлепкам.</span>"

/datum/mutation/human/bm/spiky
	name = "Колючий"
	desc = "Ваше тело частично или полностью покрыто острыми иглами. Любой, кто попытается вас потрогать, рискует пораниться."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_SPIKY
	text_gain_indication = "<span class='notice'>Ваше тело покрывается колючими иголками.</span>"
	text_lose_indication = "<span class='danger'>Ваше тело больше не ощущается колючим.</span>"

/datum/mutation/human/bm/jiggly_ass
	name = "Булки Грома"
	desc = "Твоя задница, растягивающая штаны, настолько же приятна, насколько трудно удержать равновесие, когда ее шлепают!"
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_JIGGLY_ASS
	text_gain_indication = "<span class='notice'>Ваш зад кажется очень удобным для шлепков.</span>"
	text_lose_indication = "<span class='danger'>Ваша задница снова чувствует себя нормально.</span>"

/datum/mutation/human/bm/clearly_audible
	name = "Хорошо слышимый"
	desc = "Объясняя вашу маленькость вас уж точно услышат (позволяет при маленьком размере иметь хорошо слышимую речь)"
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_BLUEMOON_CLEARLY_AUDIBLE
	text_gain_indication = "<span class='notice'>Ваш голос звучит ещё более звонко!</span>"
	text_lose_indication = "<span class='danger'>Кхе-кхе...</span>"



/datum/mutation/human/bm/high_pain_threshold
	name = "Высокий болевой порог"
	desc = "Жизнь, генетика, или что-то ещё научило вас если и не жить, то терпеть физическую боль. \
	Вы можете выдержать хирургическую операцию без наркоза легче, чем большинство вашего рода. Не повышает шанс при самооперации."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_BLUEMOON_HIGH_PAIN_THRESHOLD
	text_gain_indication = "<span class='notice'>Боль - иллюзия чувств. И вы предпочитаете жить не в иллюзиях.</span>"
	text_lose_indication = "<span class='warning'>Вам кажется, что ваше тело стало более чувствительным к боли...</span>"

/datum/mutation/human/bm/fear_of_surgeons
	name = "Боязнь хирургов"
	desc = "Мысль о том, чтобы лечь под скальпель, ввергает вас в тихий ужас. Едва ли вы согласитесь на это без веской необходимости. \
	Только анастезия поможет вытерпеть операцию, ведь если будете в сознании... Врачам будет сложнее оперировать вас. Самого себя, естественно, невозможно."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_BLUEMOON_FEAR_OF_SURGEONS
	text_gain_indication = "<span class='warning'>Вид хирургических инструментов вызывает у вас панику, а мысль лечь под нож без анестезии заставляет чаще дышать от страха.</span>"
	text_lose_indication = "<span class='notice'>Возможно, вы были не правы и хирургия не такая уж и страшная отрасль медицины...</span>"


/datum/mutation/human/bm/hypnotic_stupor //straight from skyrat
	name = "Гипнотический Ступор"
	desc = "Вы склонны к приступам крайнего ступора, который делает вас чрезвычайно внушаемым."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = null // Handled by trauma.
	text_lose_indication = null


/datum/mutation/human/bm/hypnotic_stupor/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/datum/brain_trauma/severe/hypnotic_stupor/T = new()

	owner.gain_trauma(T, TRAUMA_RESILIENCE_ABSOLUTE)


/datum/mutation/human/bm/estrous_detection
	name = "Обнаружение Эструса"
	desc = "Вы обладаете особым чувством, чтобы определить, находится ли кто-то в эстральном цикле."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_ESTROUS_DETECT
	text_gain_indication = "<span class='love'>Ваши органы чувств адаптируются, позволяя вам ощущать фертильность окружающих.</span>"
	text_lose_indication = "<span class='danger'>Ваши особые чувства регрессируют и вы больше не ощущаете фертильность окружающих.</span>"

/datum/mutation/human/bm/dnc_order
	name = "Приказ Не Клонировать"
	desc = "На вас записан приказ 'Не клонировать', в котором, как бы это странно не звучало, говорится, что вас нельзя клонировать. Вы все еще можете быть оживлены другими способами."
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	mob_trait = TRAIT_DNC_ORDER

/datum/mutation/human/bm/tough
	name = "Стойкость"
	desc = "Ваше аномально крепкое тело не воспринимает физический урон ниже 10 единиц"
	quality = POSITIVE
	difficulty = 14
	instability = 30
	mob_trait = TRAIT_TOUGHT
	locked = TRUE
	text_gain_indication = "<span class='notice'>Вы чувствуете крепость в мышцах.</span>"
	text_lose_indication = "<span class='notice'>Вы чувствуете себя менее крепким.</span>"

/*
/datum/mutation/human/bm/tough/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	owner.maxHealth *= 1.20

/datum/mutation/human/bm/tough/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(!owner)
		return
	owner.maxHealth *= 0.909 //close enough
*/

/datum/mutation/human/bm/ashresistance
	name = "Пепельная Устойчивость"
	desc = "Ваше тело адаптировалось к пылающим покровам пепла, которые застилают вулканические миры, но это не значит, что вы не будете уставать."
	quality = POSITIVE
	difficulty = 14
	instability = 30 //Is not actually THAT good. Does not grant breathing and does stamina damage to the point you are unable to attack. Crippling on lavaland, but you'll survive. Is not a replacement for SEVA suits for this reason. Can be adjusted.
	mob_trait = TRAIT_ASHRESISTANCE

	text_gain_indication = "<span class='notice'>Вы чувствуете себя устойчивее против горящей серы.</span>"
	text_lose_indication = "<span class='notice'>Ваша плоть становится более легковоспламеняемой.</span>"

/* --FALLBACK SYSTEM INCASE THE TRAIT FAILS TO WORK. Do NOT enable this without editing ash_storm.dm to deal stamina damage with ash immunity.
/datum/mutation/human/bm/ashresistance/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	owner.weather_immunities |= "ash"

/datum/mutation/human/bm/ashresistance/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(!owner)
		return
	owner.weather_immunities -= "ash"
*/

/datum/mutation/human/bm/rad_fiend
	name = "Рад Фьенд"
	desc = "Вас благословил согревающий свет Атома, заставляющий вас постоянно излучать едва заметное свечение. Только особо интенсивное излучение способно проникнуть через ваш защитный барьер."
	quality = POSITIVE
	difficulty = 14
	instability = 30
	mob_trait = TRAIT_RAD_FIEND

	text_gain_indication = "<span class='notice'>Вы чувствуете в себе силы благодаря свечению Атома.</span>"
	text_lose_indication = "<span class='danger'>Вы понимаете, что радиация не такая уж безопасная.</span>"

/datum/mutation/human/bm/rad_fiend/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk holder mob
	var/mob/living/carbon/human/quirk_mob = owner
	// Add glow control action
	var/datum/action/rad_fiend/update_glow/quirk_action = new
	quirk_action.Grant(quirk_mob)

/datum/mutation/human/bm/rad_fiend/on_losing(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk holder mob
	var/mob/living/carbon/human/quirk_mob = owner

	// Remove glow control action
	var/datum/action/rad_fiend/update_glow/quirk_action = locate() in quirk_mob.actions
	quirk_action.Remove(quirk_mob)

	// Remove glow effect
	quirk_mob.remove_filter("rad_fiend_glow")

/datum/mutation/human/bm/arachnid
	name = "Арахнид"
	desc = "Ваша анатомия позволяет плести паутину и коконы, будучи не арахнидом! (Учтите, что этот навык ничего не даёт расе арахнидов)"
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_ARACHNID
	text_gain_indication = "<span class='notice'>У вас появляется странное ощущение рядом с анусом...</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, что больше не можете вить паутину...</span>"


/datum/mutation/human/bm/arachnid/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	if(is_species(owner,/datum/species/arachnid))
		to_chat(owner, "<span class='warning'>Этот навык ничего не даёт арахнидам, так как является встроенным для расы.</span>")
		return
	var/datum/action/innate/spin_web/SW = new
	var/datum/action/innate/spin_cocoon/SC = new
	SC.Grant(owner)
	SW.Grant(owner)

/datum/mutation/human/bm/arachnid/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(is_species(owner,/datum/species/arachnid))
		return
	var/datum/action/innate/spin_web/SW = locate(/datum/action/innate/spin_web) in owner.actions
	var/datum/action/innate/spin_cocoon/SC = locate(/datum/action/innate/spin_cocoon) in owner.actions
	SC?.Remove(owner)
	SW?.Remove(owner)

/datum/mutation/human/bm/flutter
	name = "Парение"
	desc = "Вы можете свободно двигаться в герметичной среде с низкой гравитацией при помощи крыльев, магии или другой физиологической чуши."
	quality = POSITIVE
	difficulty = 12
	instability = 20
	mob_trait = TRAIT_FLUTTER

/datum/mutation/human/bm/cloth_eater
	name = "Пожиратель Одежды"
	desc = "Вы можете съесть большинство одежды, чтобы получить прибавку к настроению и питательные вещества. (Насекомые владеют этим навыком.)"
	quality = POSITIVE
	difficulty = 12
	instability = 20
	var/mood_category ="cloth_eaten"
	mob_trait = TRAIT_CLOTH_EATER

/datum/mutation/human/bm/ropebunny
	name = "Верёвочный Кролик"
	desc = "Вы обучены искусно вязать верёвки любой формы. Вы можете создавать веревку из ткани, а из этой веревки - болы!"
	quality = POSITIVE
	difficulty = 14
	instability = 30

/datum/mutation/human/bm/ropebunny/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	if (!owner)
		return
	var/datum/action/ropebunny/conversion/C = new
	C.Grant(owner)

/datum/mutation/human/bm/ropebunny/on_losing(mob/living/carbon/human/owner)
	. = ..()

	var/datum/action/ropebunny/conversion/C = locate() in owner.actions
	C.Remove(owner)
	. = ..()

/datum/mutation/human/bm/hallowed
	name = "Святой Дух"
	desc = "Вы были благословлены высшими силами или каким-то иным образом наделены святой энергией. Святая вода восстановит ваше здоровье!"
	quality = POSITIVE
	difficulty = 14
	instability = 30
	mob_trait = TRAIT_HALLOWED
	text_gain_indication = "<span class='notice'>Вы чувствуете, как святая энергия начинает течь по вашему телу.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, как угасает ваша святая энергия...</span>"

/datum/mutation/human/bm/russian
	name = "Русский дух"
	desc = "Вы были благословлены высшими силами или каким-то иным образом наделены святой энергией. С вами Бог!"
	quality = POSITIVE
	difficulty = 3
	instability = 5
	mob_trait = TRAIT_RUSSIAN
	text_gain_indication = "<span class='notice'>Вы чувствуете, как Бог следит за вами!</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, как угасает ваша вера в Бога...</span>"


/datum/mutation/human/bm/restorative_metabolism
	name = "Регенеративный Метаболизм"
	desc = "Ваше органическое тело способно медленнно востанавливаться после ранений, лучше, чем у некоторых самовосстанавливающихся существ. Обратите внимание: критические травмы, ранения или генетические повреждения все равно потребуют медицинской помощи."
	quality = POSITIVE
	difficulty = 32
	instability = 40
	mob_trait = TRAIT_RESTORATIVE_METABOLISM
	locked = TRUE
	text_gain_indication = "<span class='notice'>Вы чувствуете прилив регенерации, проходящей через ваше тело...</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, что ваше тело уже не самоподдерживает себя и раны не затягиваются...</span>"

/datum/mutation/human/bm/restorative_metabolism/on_life()
	//Works only for organics #biopank_power
	//person who'll be healed

	var/total_brute = owner.getBruteLoss_nonProsthetic()
	var/total_burn = owner.getFireLoss_nonProsthetic()
	var/total_toxloss = owner.getToxLoss()
	var/total_damage = total_brute + total_burn + total_toxloss

	if (total_damage == 0) // Раз метаболизм не лечит окси урон, не нужно прогонять прок при его наличии
		return
	var/consumed_damage = owner.getFireLoss() * 2 + owner.getBruteLoss() // the damage, the person have. Burn is bad for regeneration, so its multiplied
	var/heal_multiplier = owner.getMaxHealth() / 100 // the heal is scaled by persons health, big guys heals faster
	var/bruteheal = -0.6
	var/burnheal = -0.2
	var/toxheal = -0.2
	if (consumed_damage > 50 * heal_multiplier) // if the damage exceeds the threshold the speed of healing significantly reduse
		heal_multiplier *= 0.5
	owner.adjustBruteLoss(bruteheal * heal_multiplier, forced = TRUE)
	owner.adjustFireLoss(burnheal * heal_multiplier, forced = TRUE)

	if (!HAS_TRAIT(owner, TRAIT_TOXINLOVER)) // спасаем слаймов
		owner.adjustToxLoss(toxheal * heal_multiplier, forced = TRUE)

/datum/mutation/human/bm/breathless
	name = "Недышащий"
	desc = "Благодаря генной инженерии, технологиям или магии блюспейса вам больше не нужен воздух для жизнедеятельности. Это также означает, что проведение таких жизненно важных манипуляций, как искусственное дыхание, станет невозможным."
	quality = POSITIVE
	difficulty = 32
	instability = 40
	locked = TRUE
	text_gain_indication = "<span class='notice'>Вам больше не нужно дышать.</span>"
	text_lose_indication = "<span class='danger'>Вам нужно снова дышать...</span>"




/datum/mutation/human/bm/breathless/on_life()


	owner.adjustOxyLoss(-3) /* Bandaid-fix for a defibrillator "bug",
	Which causes oxy damage to stack for mobs that don't breathe */

//Own stuff
/datum/mutation/human/bm/no_guns
	name = "Толстые пальцы"
	desc = "Из-за формы пальцев, ширины или вообще отсутствия - вы не можете стрелять из оружия без особого улучшения."
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	mob_trait = TRAIT_CHUNKYFINGERS
	text_gain_indication = "<span class='notice'>Ваши пальцы ощущаются... толстыми.</span>"
	text_lose_indication = "<span class='notice'>Вы чувствуете, что ваши пальцы вернулись к норме.</span>"

/datum/mutation/human/bm/illiterate
	name = "Неграмотность"
	desc = "Всё просто - вы не умеете ни писать, ни читать."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_ILLITERATE
	text_gain_indication = "<span class='notice'>Знание грамоты... ускользает от вас.</span>"
	text_lose_indication = "<span class='notice'>Написанные слова снова обретают смысл."

/datum/mutation/human/bm/flimsy
	name = "Хрупкость"
	desc = "Ваше тело слабее, чем у большинства, здоровье уменьшено на 20%."
	quality = NEGATIVE
	difficulty = 8
	instability = -20

	text_gain_indication = "<span class='notice'>Вы чувствуете, что вас могли бы снести с одного удара.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете себя крепче.</span>"

/datum/mutation/human/bm/flimsy/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	owner.maxHealth *= 0.8

/datum/mutation/human/bm/flimsy/on_losing(mob/living/carbon/human/owner)
	. = ..() //how do admins even remove traits?
	if(!owner)
		return
	owner.maxHealth *= 1.25

/datum/mutation/human/bm/hypersensitive
	name = "Гиперчувствительность"
	desc = "Всё вокруг влияет на ваше настроение больше, чем должно."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	text_gain_indication = "<span class='danger'>Вы делаете из мухи слона.</span>"
	text_lose_indication = "<span class='notice'>Вы больше не преувеличиваете значимость событий вокруг вас.</span>"


/datum/mutation/human/bm/hypersensitive/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/datum/component/mood/mood = owner.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier += 0.5

/datum/mutation/human/bm/hypersensitive/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(!owner)
		return
	var/datum/component/mood/mood = owner.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier -= 0.5



// Small issue with this. If the quirk holder has NO_HUNGER or NO_THIRST, this trait can still be taken and they will still get the benefits of it.
// It's unlikely that someone will be both, especially at round start, but vampirism makes me wary of having these separate.
/datum/mutation/human/bm/hungry
	name = "Бездонный Желудок"
	desc = "В вас быстрее просыпаются голод и жажда. Необходимо есть и пить в два раза больше."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	text_gain_indication = "<span class='notice'>Вы хотите есть и пить чаще.</span>"
	text_lose_indication = "<span class='danger'>Жор идёт на спад.</span>"

/datum/mutation/human/bm/hungry/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/datum/physiology/P = owner.physiology
	P.hunger_mod *= 2

/datum/mutation/human/bm/hungry/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(owner)
		var/datum/physiology/P = owner.physiology
		if(P)
			P.hunger_mod /= 2

/datum/mutation/human/bm/thirsty
	name = "Жаждущий"
	desc = "Вам необычайно хочется пить. Приходится пить в два раза больше, чем обычно."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	text_gain_indication = "<span class='notice'>Вы начинаете испытывать жажду гораздо быстрее.</span>"
	text_lose_indication = "<span class='danger'>Ваша повышенная тяга к воде начинает угасать.</span>"

/datum/mutation/human/bm/thirsty/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/datum/physiology/P = owner.physiology
	P.thirst_mod *= 2

/datum/mutation/human/bm/thirsty/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(owner)
		var/datum/physiology/P = owner.physiology
		if(P)
			P.thirst_mod /= 2

/datum/mutation/human/bm/less_nightmare
	name = "Отпрыск Ночного Кошмара"
	desc = "Вы очень схожи с так называемыми Ночными Кошмарами. Каким бы образом это не получилось, теперь всякое свечение вам опасно."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = -40
	mob_trait = TRAIT_LESS_NIGHTMARE
	text_gain_indication = "<span class='notice'>Ваше тело становится уязвимым к свету...</span>"
	text_lose_indication = "<span class='danger'>Ваше тело более устойчивым, чем раньше.</span>"

/datum/mutation/human/bm/less_nightmare/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/human/C = owner
	C.AddElement(/datum/element/photosynthesis, 1, 1, 0, 0, 0, 0, SHADOW_SPECIES_LIGHT_THRESHOLD, SHADOW_SPECIES_LIGHT_THRESHOLD)

/datum/mutation/human/bm/less_nightmare/on_losing(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/human/C = owner
	C.RemoveElement(/datum/element/photosynthesis, 1, 1, 0, 0, 0, 0, SHADOW_SPECIES_LIGHT_THRESHOLD, SHADOW_SPECIES_LIGHT_THRESHOLD)


/datum/mutation/human/bm/choke_slut
	name = "Асфиксиофилия"
	desc = "Вас возбуждает удушье."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_CHOKE_SLUT
	text_gain_indication = "<span class='notice'>Вы хотите ощутить пальцы вокруг шеи, сжимающие её до тех пор, пока не отключитесь или кончите... а может, всё сразу?</span>"
	text_lose_indication = "<span class='danger'>Похоже, вас больше не возбуждает асфиксия.</span>"

/datum/mutation/human/bm/pharmacokinesis //Supposed to prevent unwanted organ additions. But i don't think it's really working rn
	name = "Острый Печеночный Фармакокинез" //copypasting dumbo
	desc = "У вас генетическое заболевание, которое заставляет печень усваивать семя инкуба и молоко суккуба при попадании их в организм."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	mob_trait = TRAIT_PHARMA
	text_lose_indication = "<span class='danger'>Ваша печень ощущается... по-иному.</span>"


/datum/mutation/human/bm/cursed_blood
	name = "Проклятая Кровь"
	desc = "На вашем роду лежит проклятие бледной крови. Лучше держаться подальше от святой воды... а вот адской воды, напротив..."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_CURSED_BLOOD
	text_gain_indication = "<span class='notice'>Проклятие с земель, где люди возвращаются зверьми, течёт в вашей крови.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, что тяжесть проклятия крови наконец пропала.</span>"

/datum/mutation/human/bm/headpat_hater
	name = "Отстраненность"
	desc = "Вам нет дела до ласки со стороны других. Будь то вследствие сдержанности или самоконтроля, получаемые поглаживания не заставят вилять хвостом, если таковой есть, ласка может даже разгневать."
	mob_trait = TRAIT_DISTANT
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = "<span class='notice'>Чужие прикосновения раздражают вас...</span>"
	text_lose_indication = "<span class='danger'>Теперь поглаживания не кажутся настолько уж плохими...</span>"

/datum/mutation/human/bm/headpat_hater/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/mob/living/carbon/human/quirk_mob = owner

	var/datum/action/cooldown/toggle_distant/act_toggle = new
	act_toggle.Grant(quirk_mob)

/datum/mutation/human/bm/headpat_hater/on_losing(mob/living/carbon/human/owner)
	. = ..()

	var/mob/living/carbon/human/quirk_mob = owner

	var/datum/action/cooldown/toggle_distant/act_toggle = locate() in quirk_mob.actions
	if(act_toggle)
		act_toggle.Remove(quirk_mob)

/datum/mutation/human/bm/headpat_slut
	name = "Тактилофилия"
	desc = "Вам нравится, когда другие прикасаются к вашей голове! Может, даже слишком... когда другие гладят вас по голове, это повышает ваше настроение и возбуждает вас."
	mob_trait = TRAIT_HEADPAT_SLUT
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	text_gain_indication = "<span class='notice'>Вы жаждете ласки!</span>"
	text_lose_indication = "<span class='danger'>Ваша зависимость от ласки исчезает.</span>"

/datum/mutation/human/bm/headpat_slut/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	owner.AddElement(/datum/element/wuv/headpat, null, null, /datum/mood_event/pet_animal)

/datum/mutation/human/bm/headpat_slut/on_losing(mob/living/carbon/human/owner)
	. = ..()
	owner.RemoveElement(/datum/element/wuv/headpat)

/datum/mutation/human/bm/Hypnotic_gaze
	name = "Гипнотический Взгляд"
	desc = "Вследствие мистических узоров, мерцающих цветов или какой-нибудь генетической странности, длительный визуальный контакт с вами поместит наблюдателя в легковнушаемый гипнотический транс."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_HYPNOTIC_GAZE
	text_gain_indication = "<span class='notice'>Ваши глаза завораживающе мерцают...</span>"
	text_lose_indication = "<span class='danger'>Ваша глаза становятся обычными.</span>"


/datum/mutation/human/bm/Hypnotic_gaze/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = owner

	// Add quirk ability action datum
	var/datum/action/cooldown/hypnotize/act_hypno = new
	act_hypno.Grant(quirk_mob)

	// Add examine text
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/mutation/human/bm/Hypnotic_gaze/on_losing(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = owner

	// Remove quirk ability action datum
	var/datum/action/cooldown/hypnotize/act_hypno = locate() in quirk_mob.actions
	act_hypno.Remove(quirk_mob)

	// Remove examine text
	UnregisterSignal(owner, COMSIG_PARENT_EXAMINE)

// Quirk examine text
/datum/mutation/human/bm/Hypnotic_gaze/proc/on_examine_holder(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	examine_list += "[owner.ru_ego(TRUE)] глаза необычайно сверкают..."

/datum/mutation/human/bm/overweight
	name = "Лишний Вес"
	desc = "Вы обожаете еду. Вы с лишним весом."
	quality = NEGATIVE
	difficulty = 8
	instability = -10
	text_gain_indication = "<span class='notice'>Вы чувствуете себя толстым!</span>"
	mob_trait = TRAIT_FAT
	//no text_lose_indication cause why would there be?



/datum/mutation/human/bm/vegetarian
	name = "Вегетарианец"
	desc = "Мысли о поедании мяса для вас отвратительны."
	quality = MINOR_NEGATIVE
	difficulty = 8
	text_gain_indication = "<span class='notice'>Вы чувствуете отвращение от мысли о поедании мяса.</span>"
	text_lose_indication = "<span class='danger'>Вы думаете, что поесть мяса не так уж и плохо.</span>"

/datum/mutation/human/bm/vegetarian/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	var/datum/species/species = owner.dna.species
	species.liked_food &= ~MEAT
	species.disliked_food |= MEAT

/datum/mutation/human/bm/vegetarian/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if(owner)
		var/datum/species/species = owner.dna.species
		if(initial(species.liked_food) & MEAT)
			species.liked_food |= MEAT
		if(initial(species.disliked_food) & ~MEAT)
			species.disliked_food &= ~MEAT


/*
/datum/mutation/human/bm/undead
    name = "Не-мёртвый"
    desc = "Ваше тело, будь то аномальное или просто отказывающееся умирать, действительно стало нежитью. Из-за этого вы испытываете сильный голод."
    quality = POSITIVE
	difficulty = 14
	instability = 30
    mob_trait = TRAIT_UNDEAD

/datum/mutation/human/bm/undead/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
    . = ..()

    if(owner.mob_biotypes == MOB_ROBOTIC)
        return FALSE //Lol, lmao, even
    owner.mob_biotypes += MOB_UNDEAD
    for(var/A = 1, A <= zperks.len, A++)
        ADD_TRAIT(owner,zperks[A],ROUNDSTART_TRAIT)

/datum/mutation/human/bm/undead/on_losing(mob/living/carbon/human/owner)
	. = ..()
    . = ..()

    owner.mob_biotypes -= MOB_UNDEAD
    for(var/A = 1, A <= zperks.len, A++)
        REMOVE_TRAIT(owner,zperks[A], null)

/datum/mutation/human/bm/undead/on_life()

	owner.adjust_nutrition(-0.025)
	owner.adjust_thirst(-0.025)
	owner.set_screwyhud(SCREWYHUD_HEALTHY)
	owner.adjustOxyLoss(-3) //Stops a defibrilator bug. Note to future self: Fix defib bug.
*/
/datum/mutation/human/bm/cum_plus
	name = "Сверхпродуктивные Гениталии"
	desc = "Ваши гениталии производят и вмещают больше, чем обычно."
	quality = MINOR_NEGATIVE
	difficulty = 8
	text_gain_indication = "<span class='notice'>Вы чувствуете давление в паху.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, как ваш пах стал легче.</span>"
	var/increasedcum

/datum/mutation/human/bm/cum_plus/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/M = owner
	if(M.getorganslot(ORGAN_SLOT_TESTICLES))
		var/obj/item/organ/genital/testicles/T = M.getorganslot(ORGAN_SLOT_TESTICLES)
		T.fluid_mult += 0.5 //Base is 1
		T.fluid_max_volume *= 1.75 //Fixes this.

/datum/mutation/human/bm/cum_plus/on_losing(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/M = owner
	if(!M)
		return
	if(owner.getorganslot(ORGAN_SLOT_TESTICLES))
		var/obj/item/organ/genital/testicles/T = M.getorganslot(ORGAN_SLOT_TESTICLES)
		T.fluid_mult -= 0.5 //Base is 1
		T.fluid_max_volume *= 0.25 //Base is 50

/datum/mutation/human/bm/cum_plus/on_life()
	var/mob/living/carbon/M = owner //If you get balls later, then this will still proc
	if(M.getorganslot(ORGAN_SLOT_TESTICLES))
		var/obj/item/organ/genital/testicles/T = M.getorganslot(ORGAN_SLOT_TESTICLES)
		if(!increasedcum)
			T.fluid_mult = 1.5 //Base is 0.133
			T.fluid_max_volume *= 1.75
			increasedcum = TRUE

/datum/mutation/human/bm/milk_plus
	name = "Сверхпродуктивная Грудь"
	desc = "Ваша грудь производит и вмещает больше, чем обычно."
	quality = MINOR_NEGATIVE
	difficulty = 8
	text_gain_indication = "<span class='notice'>Вы чувствуете давление в груди.</span>"
	text_lose_indication = "<span class='danger'>Вы чувствуете, что ваша грудь стала легче.</span>"
	var/increasedcum

/datum/mutation/human/bm/milk_plus/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/M = owner
	if(M.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genital/breasts/T = M.getorganslot(ORGAN_SLOT_BREASTS)
		T.fluid_mult += 0.5 //Base is 1
		T.fluid_max_volume *= 1.75 //Fixes this.

/datum/mutation/human/bm/milk_plus/on_losing(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/M = owner
	if(!M)
		return
	if(owner.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genital/breasts/T = M.getorganslot(ORGAN_SLOT_BREASTS)
		T.fluid_mult -= 0.5 //Base is 1
		T.fluid_max_volume *= 0.25 //Base is 50

/datum/mutation/human/bm/milk_plus/on_life()
	var/mob/living/carbon/M = owner //If you get balls later, then this will still proc
	if(M.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genital/breasts/T = M.getorganslot(ORGAN_SLOT_BREASTS)
		if(!increasedcum)
			T.fluid_mult = 1.5 //Base is 0.133
			T.fluid_max_volume *= 1.75
			increasedcum = TRUE

//You are a CIA agent.
/datum/mutation/human/bm/cosglow
	name = "Косметическая подсветка"
	desc = "Ваше тело слегка светится! Что бы это не значило - излучение от радиации или люминисцентных грибов вдоль кожного покрова.."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_COSGLOW
	text_gain_indication = "<span class='notice'>Вы ощущаете приток света вокруг себя!</span>"
	text_lose_indication = "<span class='danger'>Вы осознаете, что косплеить космическое ЦРУ совсем не для вас!</span>"

/datum/mutation/human/bm/cosglow/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk holder mob
	var/mob/living/carbon/human/quirk_mob = owner
	// Add glow control action
	var/datum/action/cosglow/update_glow/quirk_action = new
	quirk_action.Grant(quirk_mob)

/datum/mutation/human/bm/cosglow/on_losing(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk holder mob
	var/mob/living/carbon/human/quirk_mob = owner

	// Remove glow control action
	var/datum/action/cosglow/update_glow/quirk_action = locate() in quirk_mob.actions
	quirk_action.Remove(quirk_mob)

	// Remove glow effect
	quirk_mob.remove_filter("rad_fiend_glow")



//Own traits
/datum/mutation/human/bm/cum_sniff
	name = "Дегустатор Гениталий"
	desc = "Вы набрались столько опыта, обсасывая чужие гениталии, что с легкостью можете сказать, какая жидкость находится внутри них, исключая реагенты в крови."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_GFLUID_DETECT
	text_gain_indication = "<span class='notice'>Вы начинаете ощущать специфические запахи, исходящие от чужих промежностей...</span>"
	text_lose_indication = "<span class='danger'>Чужие гениталии начинают пахнуть для вас одинаково...</span>"


//succubus and incubus below
/datum/mutation/human/bm/incubus
	name = "Инкуб"
	desc = "Ваш голод может быть утолен только молоком. (И семенем, если вы также Суккуб.)"
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	mob_trait = TRAIT_INCUBUS

/datum/mutation/human/bm/incubus/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	ADD_TRAIT(owner,TRAIT_NO_PROCESS_FOOD,ROUNDSTART_TRAIT)
	ADD_TRAIT(owner,TRAIT_NOTHIRST,ROUNDSTART_TRAIT)

/datum/mutation/human/bm/incubus/on_losing(mob/living/carbon/human/owner)
	. = ..()

	REMOVE_TRAIT(owner,TRAIT_NO_PROCESS_FOOD,ROUNDSTART_TRAIT)
	REMOVE_TRAIT(owner,TRAIT_NOTHIRST,ROUNDSTART_TRAIT)

/datum/mutation/human/bm/incubus/on_life()


	owner.adjust_nutrition(-0.09)//increases their nutrition loss rate to encourage them to gain a partner they can essentially leech off of

/datum/mutation/human/bm/succubus
	name = "Суккуб"
	desc = "Ваш голод может быть утолен только семенем. (И молоком, если вы также Инкуб.)"
	quality = NEGATIVE
	difficulty = 8
	instability = -20
	mob_trait = TRAIT_SUCCUBUS

/datum/mutation/human/bm/succubus/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	ADD_TRAIT(owner,TRAIT_NO_PROCESS_FOOD,ROUNDSTART_TRAIT)
	ADD_TRAIT(owner,TRAIT_NOTHIRST,ROUNDSTART_TRAIT)

/datum/mutation/human/bm/succubus/on_losing(mob/living/carbon/human/owner)
	. = ..()

	REMOVE_TRAIT(owner,TRAIT_NO_PROCESS_FOOD,ROUNDSTART_TRAIT)
	REMOVE_TRAIT(owner,TRAIT_NOTHIRST,ROUNDSTART_TRAIT)

/datum/mutation/human/bm/succubus/on_life()


	owner.adjust_nutrition(-0.09)//increases their nutrition loss rate to encourage them to gain a partner they can essentially leech off of
/*
/datum/mutation/human/bm/gargoyle //Mmmm yes stone time
	name = "Горгулья"
	desc = "Вы относитесь к какому-то виду горгульи! Вы можете выходить из каменной формы на определенное время, но вам придётся в неё вернуться, чтобы восстановить энергию. С другой стороны, вы лечитесь, будучи в камне!"
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	var/energy = 0
	var/transformed = 0
	var/cooldown = 0
	var/paused = 0
	var/turf/position
	var/obj/structure/statue/gargoyle/current = null

/datum/mutation/human/bm/gargoyle/on_acquiring(mob/living/carbon/human/owner)
	. = ..()

	if (!owner)
		return
	var/datum/action/gargoyle/transform/T = new
	var/datum/action/gargoyle/check/C = new
	var/datum/action/gargoyle/pause/P = new
	energy = 100
	cooldown = 30
	T.Grant(owner)
	C.Grant(owner)
	P.Grant(owner)

/datum/mutation/human/bm/gargoyle/on_life()



	if (!owner)
		return

	if(paused && owner.loc != position)
		paused = 0
		energy -= 20

	if(cooldown > 0)
		cooldown--

	if(!transformed && !paused && energy > 0)
		energy -= 0.05

	if(transformed)
		energy = min(energy + 0.3, 100)
		if (owner.getBruteLoss() > 0 || owner.getFireLoss() > 0)
			owner.adjustBruteLoss(-0.5, forced = TRUE)
			owner.adjustFireLoss(-0.5, forced = TRUE)
		else if (owner.getOxyLoss() > 0 || owner.getToxLoss() > 0)
			owner.adjustToxLoss(-0.3, forced = TRUE)
			owner.adjustOxyLoss(-0.5, forced = TRUE) //oxyloss heals by itself, doesn't need a nerfed heal
		else if (owner.getCloneLoss() > 0)
			owner.adjustCloneLoss(-0.3, forced = TRUE)
		else if (current && current.obj_integrity < current.max_integrity) //health == maxHealth is true since we checked all damages above
			current.obj_integrity = min(current.obj_integrity + 0.1, current.max_integrity)

	if(!transformed && energy <= 0)
		var/datum/action/gargoyle/transform/T = locate() in owner.actions
		if (!T)
			T = new
			T.Grant(owner)
		cooldown = 0
		T?.Trigger()

/datum/mutation/human/bm/gargoyle/on_losing(mob/living/carbon/human/owner)
	. = ..()

	if (!owner)
		return ..()
	var/datum/action/gargoyle/transform/T = locate() in owner.actions
	var/datum/action/gargoyle/check/C = locate() in owner.actions
	var/datum/action/gargoyle/pause/P = locate() in owner.actions
	T?.Remove(owner)
	C?.Remove(owner)
	P?.Remove(owner)
	. = ..()

*/

/datum/mutation/human/bm/masked_mook
	name = "Синдром Бейна"
	desc = "По какой-то причине вам... не по себе без противогаза на лице."
	text_gain_indication = "<span class='notice'>Вы начинаете чувствовать себя нехорошо без противогаза.</span>"
	text_lose_indication = "<span class='danger'>У вас больше нет нужды в ношении противогаза.</span>"
	quality = NEGATIVE
	difficulty = 8
	instability = -10


/datum/mutation/human/bm/masked_mook/on_life()

	var/obj/item/clothing/mask/gas/gasmask = owner.get_item_by_slot(ITEM_SLOT_MASK)
	if(istype(gasmask))
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, QMOOD_MASKED_MOOK, /datum/mood_event/masked_mook)
	else
		SEND_SIGNAL(owner, COMSIG_ADD_MOOD_EVENT, QMOOD_MASKED_MOOK, /datum/mood_event/masked_mook_incomplete)


/datum/mutation/human/bm/body_morpher
	name = "Изменятель Тела"
	desc = "Каким-то образом вы развили способность, позволяющую вашему телу морфировать и изменять свои части тела, подобно тому, как это может делать слаймик."
	quality = POSITIVE
	difficulty = 14
	instability = 30
	mob_trait = TRAIT_BODY_MORPHER
	text_gain_indication = "<span class='notice'>Ваше тело становится более податливым...</span>"
	text_lose_indication = "<span class='danger'>Ваше тело более упругое, чем раньше.</span>"

	var/datum/action/innate/ability/humanoid_customization/alter_form_action

/datum/mutation/human/bm/body_morpher/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = owner

	// Add quirk ability action datum
	alter_form_action = new
	alter_form_action.Grant(quirk_mob)

/datum/mutation/human/bm/body_morpher/on_losing(mob/living/carbon/human/owner)
	. = ..()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = owner

	// Remove quirk ability action datum
	alter_form_action.Remove(quirk_mob)
	QDEL_NULL(alter_form_action)

/datum/mutation/human/bm/modular
	name = "Модульные Конечности"
	desc = "Ваши конечности можно легко присоединять и отсоединять... к сожалению, все окружающие тоже могут изменять ваши конечности! Щелкните правой кнопкой мыши на себе, чтобы использовать эту причуду."
	quality = POSITIVE
	difficulty = 12
	instability = 20

/datum/mutation/human/bm/modular/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/human/C = owner
	add_verb(C,/mob/living/proc/alterlimbs)

/datum/mutation/human/bm/modular/on_losing(mob/living/carbon/human/owner)
	. = ..()
	var/mob/living/carbon/human/C = owner
	remove_verb(C,/mob/living/proc/alterlimbs)

/datum/mutation/human/bm/messy
	name = "Грязнуля"
	desc = "Из-за биологических особенностей вашего тела или блюспейс аномалии вы всегда устраиваете бардак, когда кончаете. Даже в тех обстоятельствах, когда это казалось бы невозможно."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_MESSY
	text_gain_indication = "<span class='notice'>Вы хотите покрыть что-то с помощью своих органических жидкостей.</span>"
	text_lose_indication = "<span class='danger'>Вы более не ощущаете себя 'грязнулей'.</span>"

/datum/mutation/human/bm/kiss_slut
	name = "Чувствительные Губы"
	desc = "Одна только мысль о поцелуе заставляет вас краснеть и возбуждаться, эффективно усиляя ваше возбуждение с каждым поцелуем."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_KISS_SLUT
	text_gain_indication = "<span class='lewd'>Вам хочется поцеловать кого-нибудь....</span>"
	text_lose_indication = "<span class='danger'>Вас больше не тянет целоваться....</span>"
//////
/datum/mutation/human/bm/lewd_summon
	name = "Призываемый"
	desc = "Вы были одарены силой демонов похоти или же сами являлись её источником, что давала возможность осмелившимся безумцам призывать вас при помощи рун. Сможете ли вы исполнить их фантазии?."
	quality = MINOR_NEGATIVE
	difficulty = 8
	instability = 0
	mob_trait = TRAIT_LEWD_SUMMON
	text_gain_indication = "<span class='lewd'>Вас наполняет демоническая похоть....</span>"
	text_lose_indication = "<span class='danger'>Вас больше не наполняет демоническая похоть....</span>"
//////
/datum/mutation/human/bm/onelife
	name = "Одна Жизнь"
	desc = "С вас буквально сыпется песок. И... кажется если вы погибнете - никто этот песок собрать воедино больше не сможет."
	mob_trait = TRAIT_ONELIFE
	quality = NEGATIVE
	difficulty = 8
	instability = -60
	text_gain_indication = "<span class='danger'>Вы чувствуете, что вам нельзя умирать.</span>"
	text_lose_indication = "<span class='notice'>Жизнь для вас снова ничто.</span>" //if only it were that easy!


/datum/mutation/human/bm/onelife/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	RegisterSignal(owner, COMSIG_MOB_DEATH, PROC_REF(get_rid_of_them))
	RegisterSignal(owner, COMSIG_MOB_EMOTE, PROC_REF(get_rid_of_them_emote))

/datum/mutation/human/bm/onelife/on_losing(mob/living/carbon/human/owner)
	. = ..()
	remove_signals()

/datum/mutation/human/bm/onelife/proc/remove_signals()
	if(!QDELETED(owner))
		UnregisterSignal(owner, list(COMSIG_MOB_DEATH, COMSIG_MOB_EMOTE))

/datum/mutation/human/bm/onelife/proc/get_rid_of_them(mob/user, datum/emote/emote)
	if(owner.stat == DEAD)
		remove_signals()
		owner.dust(TRUE, TRUE)

/datum/mutation/human/bm/onelife/proc/get_rid_of_them_emote(mob/user, datum/emote/emote)
	var/key = emote.key
	if(key == "deathgasp")
		remove_signals()
		owner.dust(TRUE, TRUE)
//

/datum/mutation/human/bm/waddle
	name = "Неуклюжесть"
	desc = "Незначительное отклонение, заставляющее вас подпрыгивать при движении."
	mob_trait = TRAIT_WADDLING
	quality = MINOR_NEGATIVE
	instability = 0
	text_gain_indication = span_notice("Тебе кажется, что ты передвигаешься как-то по-дурацки.")
	text_lose_indication = span_notice("Теперь ты передвигаешься нормально.")

/datum/mutation/human/bm/waddle/on_acquiring(mob/living/carbon/human/owner)
	. = ..()
	owner.LoadComponent(/datum/component/waddling)

/datum/mutation/human/bm/waddle/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(!HAS_TRAIT(owner, TRAIT_WADDLING))
		var/datum/component/waddling = GetComponent(/datum/component/waddling)
		waddling?.RemoveComponent()
