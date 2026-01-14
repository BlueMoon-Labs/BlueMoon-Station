/datum/mood_event/handcuffed
	description = span_warning("Похоже, мои выходки привели к печальным последствиям...\n")
	mood_change = -1

/datum/mood_event/broken_vow //Used for when mimes break their vow of silence
	description = span_boldwarning("I have brought shame upon my name, and betrayed my fellow mimes by breaking our sacred vow...\n")
	mood_change = -8

/datum/mood_event/on_fire
	description = span_boldwarning("Я ГОРЮ!!!\n")
	mood_change = -8

/datum/mood_event/suffocation
	description = span_boldwarning("НЕ МОГУ... ДЫШАТЬ...\n")
	mood_change = -6

/datum/mood_event/burnt_thumb
	description = span_warning("Играть с огнём было плохой идеей...\n")
	mood_change = -1
	timeout = 2 MINUTES

/datum/mood_event/cold
	description = span_warning("Здесь становится холодно.\n")
	mood_change = -2

/datum/mood_event/hot
	description = span_warning("Здесь становится жарковато.\n")
	mood_change = -2

/datum/mood_event/creampie
	description = span_warning("Меня обдали сгущёнкой. По вкусу напоминает пирог...\n")
	mood_change = -2
	timeout = 3 MINUTES

// BLUEMOON ADD START - от операции на живую очень больно
/datum/mood_event/surgery_pain
	description = span_boldwarning("Меня оперировали без наркоза! Это было чудовищно больно!</span>\n")
	mood_change = -6
	timeout = 5 MINUTES

// Вариация операции для персонажей с высоким болевым порогом
/datum/mood_event/surgery_pain/lesser
	description = "<span class='danger'>Меня оперировали без наркоза... Это было чертовски больно.</span>\n"
	mood_change = -4
	timeout = 4 MINUTES

// Вариация для оперирования персонажей, которые боятся операций
/datum/mood_event/surgery_pain/trait
	description = span_boldwarning("Меня оперировали без наркоза! Я больше никогда не доверюсь врачу!</span>\n")
	mood_change = -8
	timeout = 6 MINUTES

// от операции на живую очень больно
/datum/mood_event/surgery_pain/painkiller
	description = span_warning("Меня оперировали под наркозом... Это было очень странно.</span>\n")
	mood_change = -2
	timeout = 3 MINUTES
// BLUEMOON ADD END

/datum/mood_event/slipped
	mood_change = -2
	timeout = 3 MINUTES

/datum/mood_event/slipped/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_warning("Я подскользну[owner_mob.ru_sya()]. В следующий раз стоит быть аккуратнее...</span>\n")

/datum/mood_event/eye_stab
	description = span_boldwarning("Раньше меня тоже вела дорога приключений, а потом у меня в глазу оказалась отвертка...\n")
	mood_change = -4
	timeout = 3 MINUTES

/datum/mood_event/delam //SM delamination
	description = span_boldwarning("Эти чертовы инженеры вообще ничего умеют...\n")
	mood_change = -8
	timeout = 4 MINUTES

/datum/mood_event/depression
	description = span_warning("Мне грустно безо всякой причины.\n")
	mood_change = -9
	timeout = 2 MINUTES

/datum/mood_event/shameful_suicide //suicide_acts that return SHAME, like sord
	description = span_boldwarning("Я даже не могу нормально закончить всё это!\n")
	mood_change = -10
	timeout = 10 MINUTES

/datum/mood_event/dismembered
	description = span_boldwarning("АХ! ЭТО ЖЕ МОЯ КОНЕЧНОСТЬ!\n")
	mood_change = -8
	timeout = 4 MINUTES

/datum/mood_event/noshoes
	description = span_warning(">Я везде ломаю комедию!\n")
	mood_change = -5

/datum/mood_event/tased
	description = span_warning("Что неприятно может обозначать буква \"т\" в слове \"тазер\"? Это ток!\n")
	mood_change = -3
	timeout = 2 MINUTES

/datum/mood_event/embedded
	description = span_boldwarning("Вытащи это!\n")
	mood_change = -7

/datum/mood_event/table_limbsmash
	description = span_warning("Долбанный стол. Это, чёрт возьми, больно...\n")
	mood_change = -3
	timeout = 3 MINUTES

/datum/mood_event/table_limbsmash/add_effects(obj/item/bodypart/banged_limb)
	if(banged_limb)
		description = span_warning("Моя грёбанная конечность, [banged_limb.ru_name]! Чёрт возьми, это больно...\n")

/datum/mood_event/table/add_effects()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(iscatperson(H))
			H.dna.species.start_wagging_tail(H)
			addtimer(CALLBACK(H.dna.species, TYPE_PROC_REF(/datum/species, stop_wagging_tail), H), 30)
			description =  span_nicegreen("Они хотят поиграть на столе!\n")
			mood_change = 2

/datum/mood_event/brain_damage
	mood_change = -3

/datum/mood_event/brain_damage/add_effects()
	// BLUEMOON EDIT START - это проклято и не должно так работать, но увы
	var/datum/component/mood/parent_element = owner
	if(istype(parent_element))
		var/mob/living/carbon/human/human_owner = parent_element.parent
		if(istype(human_owner) && isrobotic(human_owner))
			var/damage_message = pick_list_replacements(BRAIN_DAMAGE_FILE, "synth_brain_damage")
			description = span_warning("K-k-k-k-ERNEL ERR$@OR: [damage_message]\n")
			return
	// BLUEMOON EDIT END
	var/damage_message = pick_list_replacements(BRAIN_DAMAGE_FILE, "brain_damage")
	description = span_warning("Хр-р-р р-р-р... [damage_message]\n")

/datum/mood_event/hulk //Entire duration of having the hulk mutation
	description = span_warning("ХАЛК КРУШИТЬ!\n")
	mood_change = -4

/datum/mood_event/epilepsy //Only when the mutation causes a seizure
	description = span_warning("Следует ответственее относиться к предупреждениям об эпилепсии.\n")
	mood_change = -3
	timeout = 5 MINUTES

/datum/mood_event/nyctophobia
	description = span_warning("Вокруг довольно темно...\n")
	mood_change = -3

/datum/mood_event/brightlight
	description = span_warning("Свет вокруг становится невыносимым...\n")
	mood_change = -3

/datum/mood_event/family_heirloom_missing
	description = span_warning("Я скучаю по своей семейной реликвии...\n")
	mood_change = -8

/datum/mood_event/healsbadman
	description = span_warning("Чувствую себя намного лучше, но неприятный осадок ещё остался.\n")
	mood_change = -4
	timeout = 2 MINUTES

/datum/mood_event/jittery
	description = span_warning("Я на грани нервного срыва и больше так не могу!!\n")
	mood_change = -2

/datum/mood_event/vomit
	description = span_warning("I just threw up. Gross.\n")
	mood_change = -2
	timeout = 2 MINUTES

/datum/mood_event/vomit/add_effects(param)
	. = ..()
	description = span_warning("Меня только что вырвало. Неприятно.</span>\n")

/datum/mood_event/vomitself
	mood_change = -4
	timeout = 3 MINUTES

/datum/mood_event/vomitself/add_effects(param)
	. = ..()
	description = span_warning("Меня только что вырвало на себя. Мерзость.</span>\n")

/datum/mood_event/painful_medicine
	description = span_warning("Лекарства делают своё дело, но боль ещё не успела затихнуть.\n")
	mood_change = -5
	timeout = 1 MINUTES

/datum/mood_event/painful_limb_regrowth
	description = span_warning("Прекрасно вернуть себе конечности, но боль все ещё никуда не ушла.\n")
	mood_change = -5
	timeout = 1 MINUTES

/datum/mood_event/loud_gong
	description = span_warning("Этот громкий звук вдарил по моим ушам!\n")
	mood_change = -3
	timeout = 2 MINUTES

/datum/mood_event/spooked
	description = span_warning("Постукивания этих костей...все ещё меня напрягают.\n")
	mood_change = -4
	timeout = 4 MINUTES

/datum/mood_event/graverobbing
	mood_change = -8
	timeout = 3 MINUTES

/datum/mood_event/graverobbing/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_boldwarning("Я осквернил[owner_mob.ru_a()] чью-то могилу... Не могу поверить, что я это сделал[owner_mob.ru_a()]...</span>\n")

/datum/mood_event/gates_of_mansus
	description = span_boldwarning("ПЕРЕД МОИМИ ГЛАЗАМИ ПРОМЕЛЬКНУЛ УЖАС ЗА ГРАНЬЮ ЭТОГО МИРА! РЕАЛЬНОСТЬ ВЫВЕРНУЛАСЬ БУДТО НАИЗНАНКУ!\n")
	mood_change = -25
	timeout = 4 MINUTES

// These are unused so far but I want to remember them to use them later

/datum/mood_event/cloned_corpse
	mood_change = -12

/datum/mood_event/cloned_corpse/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_boldwarning("Я только что увидел[owner_mob.ru_a()] собственный труп...</span>\n")

/datum/mood_event/surgery
	description = span_boldwarning("МЕНЯ КТО-ТО РЕЖЕТ!!\n")
	mood_change = -16

// End unused

/datum/mood_event/sad_empath
	description = span_warning("Кто-то рядом расстроен... это удручает...\n")
	mood_change = -2
	timeout = 1 MINUTES

/datum/mood_event/sad_empath/add_effects(mob/sadtarget)
	description = span_warning("[sadtarget.name] выглядит расстроенно... это удручает...\n")

/datum/mood_event/revenant_blight
	description = span_umbra("Просто сдайся, хонк...\n")
	mood_change = -5

/datum/mood_event/revenant_blight/add_effects()
	description = span_umbra("Просто сдайся, [pick("ты никому не нужен", "ты бесполезен", "даже клоун полезнее тебя", "имеет ли это значение, в конце-концов?")]...\n")

/datum/mood_event/plushjack
	description = span_warning("I have butchered a plush recently.\n")
	mood_change = -1
	timeout = 2 MINUTES

/datum/mood_event/plushjack/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_warning("Я только что выпотрошил[owner_mob.ru_a()] плюшевую игрушку.</span>\n")

/datum/mood_event/plush_nostuffing
	description = span_warning("В плюшевой игрушке не было наполнителя...\n")
	mood_change = -1
	timeout = 2 MINUTES

/datum/mood_event/plush_bite
	description = span_warning("ОНО МЕНЯ УКУСИЛО!! АЙ!\n")
	mood_change = -3
	timeout = 2 MINUTES

// Cursed stuff below

/datum/mood_event/emptypred
	mood_change = -2
	timeout = 1 MINUTES

/datum/mood_event/emptypred/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Я позволил[owner_mob.ru_a()] кому-то уйти.</span>\n"

/datum/mood_event/emptyprey
	description = span_nicegreen("Здесь прохладно.\n")
	mood_change = -2
	timeout = 1 MINUTES

// Cursed stuff end.

/datum/mood_event/vampcandle
	description = span_umbra("Что-то заставляет вас мыслить... потерянно...\n")
	mood_change = -15
	timeout = 1 MINUTES

/datum/mood_event/drankblood_bad
	mood_change = -4
	timeout = 8 MINUTES

/datum/mood_event/drankblood_bad/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_boldwarning("Я выпил[owner_mob.ru_a()] кровь низшего существа. Мерзость.</span>\n")

/datum/mood_event/drankblood_dead
	mood_change = -7
	timeout = 10 MINUTES

/datum/mood_event/drankblood_dead/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_boldwarning("Я выпил[owner_mob.ru_a()] кровь мертвеца. Нужно быть выше этого.</span>\n")

/datum/mood_event/drankblood_synth
	mood_change = -7
	timeout = 15 MINUTES

/datum/mood_event/drankblood_synth/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_boldwarning("Я выпил[owner_mob.ru_a()] синтетическую кровь. Да что со мной не так?</span>\n")

/datum/mood_event/drankkilled
	description = span_boldwarning("Моя жертва умерла от потери крови! Что я творю!?</span>\n")
	mood_change = -12
	timeout = 25 MINUTES

/datum/mood_event/madevamp
	description = span_boldwarning("Чья-то душа оказалась обречена стать нежитью из-за меня.</span>\n")
	mood_change = -10
	timeout = 30 MINUTES

/datum/mood_event/vampatefood
	description = span_boldwarning("Пища смертных более меня не насыщает. Чувствую себя плохо.</span>\n")
	mood_change = -6
	timeout = 10 MINUTES

/datum/mood_event/daylight_1
	description = span_boldwarning("В самодельном гробу плохо спится, особенно днём.</span>\n")
	mood_change = -3
	timeout = 10 MINUTES

/datum/mood_event/daylight_2
	description = span_boldwarning("Лучи Солнца обожгли моё тело.</span>\n")
	mood_change = -6
	timeout = 15 MINUTES

/datum/mood_event/bloodsucker_disgust
	description = span_boldwarning("Недавняя моя пища была отвратительной.</span>\n")
	mood_change = -5
	timeout = 5 MINUTES

/datum/mood_event/nanite_sadness
	//description = span_warning("+++++++ПОДАВЛЕНИЕ СЧАСТЬЯ+++++++</span>\n")
	mood_change = -7

/datum/mood_event/nanite_sadness/add_effects(message)
	description = span_warning("+++++++[message]+++++++\n")

/datum/mood_event/artbad
	description = span_warning("Можно было бы сделать и лучше, чем это рукожопие.</span>\n")
	mood_change = -2
	timeout = 2 MINUTES

/datum/mood_event/tripped
	description = span_boldwarning("Не могу поверить, что меня провели этим старым как мир трюком!</span>\n")
	mood_change = -6
	timeout = 2 MINUTES

/datum/mood_event/tripped/bola
	description = span_boldwarning("Чёртова бола!</span>\n")
	mood_change = -6
	timeout = 1 MINUTES

/datum/mood_event/untied
	description = span_boldwarning("Ненавижу, когда моя обувь развязана!</span>\n")
	mood_change = -3
	timeout = 1 MINUTES

/datum/mood_event/high_five_alone
	description = span_boldwarning("Какая жалость, никто не дал мне пять!</span>\n")
	mood_change = -2
	timeout = 1 MINUTES

/datum/mood_event/high_five_full_hand
	description = span_boldwarning("Господи, даже не знаю как правильно дать пять...</span>\n")
	mood_change = -1
	timeout = 45 SECONDS

/datum/mood_event/left_hanging
	description = span_boldwarning("Но ведь все любят давать пять! Может окружающие попросту... ненавидят меня?</span>\n")
	mood_change = -2
	timeout = 1.5 MINUTES

/datum/mood_event/too_slow
	description = span_boldwarning("НЕТ! ПОЧЕМУ ВСЕ ВОКРУГ.... ТАКОЕ МЕДЛЕННОЕ???</span>\n")
	mood_change = -2 // multiplied by how many people saw it happen, up to 8, so potentially massive. the ULTIMATE prank carries a lot of weight
	timeout = 2 MINUTES

/datum/mood_event/too_slow/add_effects(param)
	var/people_laughing_at_you = 1 // start with 1 in case they're on the same tile or something
	for(var/mob/living/carbon/iter_carbon in oview(owner, 7))
		if(iter_carbon.stat == CONSCIOUS)
			people_laughing_at_you++
			if(people_laughing_at_you > 7)
				break

	mood_change *= people_laughing_at_you
	return ..()

/datum/mood_event/sacrifice_bad
	description = span_warning("Проклятые дикари!</span>\n")
	mood_change = -5
	timeout = 2 MINUTES

/datum/mood_event/uncomfortably
	description = span_warning("Я что-то защемил!</span>\n")
	mood_change = -12
	timeout = 6 MINUTES

//BM ADD
/datum/mood_event/knotting_painful
	description = span_danger("Боль пронзает тело — узел вырвался слишком резко!\n")
	mood_change = -4
	timeout = 5 MINUTES
