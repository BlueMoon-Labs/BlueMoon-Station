#define ECSTATIC_SANITY_PEN -1
#define SLIGHT_INSANITY_PEN 1
#define MINOR_INSANITY_PEN 5
#define MAJOR_INSANITY_PEN 10
#define MOOD_INSANITY_MALUS 0.13 // 13% debuff per sanity_level above the default of 4 (higher is worser), overall a 39% debuff to skills at rock bottom depression.

/datum/component/mood
	var/mood //Real happiness
	var/sanity = 100 //Current sanity
	var/shown_mood //Shown happiness, this is what others can see when they try to examine you, prevents antag checking by noticing traitors are always very happy.
	var/mood_level = 5 //To track what stage of moodies they're on
	var/sanity_level = 3 //To track what stage of sanity they're on
	var/mood_modifier = 1 //Modifier to allow certain mobs to be less affected by moodlets
	var/list/datum/mood_event/mood_events = list()
	/// Ассоциативный список "категория мудлета" -> id таймера его истечения.
	/// Без него снятый досрочно мудлет оставлял висеть таймер до самого срока (а это до
	/// 30 минут), и колесо SStimer копило сотни мёртвых записей при полном сервере.
	var/list/mood_event_timers = list()
	var/insanity_effect = 0 //is the owner being punished for low mood? If so, how much?
	var/atom/movable/screen/mood/screen_obj
	var/datum/skill_modifier/bad_mood/malus
	var/datum/skill_modifier/great_mood/bonus
	var/static/malus_id = 0
	var/static/list/free_maluses = list()
	var/atom/movable/screen/sanity/screen_obj_sanity

/datum/component/mood/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/owner = parent
	if(owner.stat != DEAD)
		START_PROCESSING(SSobj, src)

	RegisterSignal(parent, COMSIG_ADD_MOOD_EVENT, PROC_REF(add_event))
	RegisterSignal(parent, COMSIG_CLEAR_MOOD_EVENT, PROC_REF(clear_event))
	RegisterSignal(parent, COMSIG_MODIFY_SANITY, PROC_REF(modify_sanity))
	RegisterSignal(parent, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))
	RegisterSignal(parent, COMSIG_MOB_HUD_CREATED, PROC_REF(modify_hud))
	RegisterSignal(parent, COMSIG_MOB_DEATH, PROC_REF(stop_processing))
	RegisterSignal(parent, COMSIG_VOID_MASK_ACT, PROC_REF(direct_sanity_drain))
	RegisterSignal(parent, COMSIG_ENTER_AREA, PROC_REF(update_beauty))


	if(owner.hud_used)
		modify_hud()
		var/datum/hud/hud = owner.hud_used
		hud.show_hud(hud.hud_version)

/datum/component/mood/Destroy()
	QDEL_LIST_ASSOC_VAL(mood_events)
	STOP_PROCESSING(SSobj, src)
	unmodify_hud()
	return ..()

/datum/component/mood/UnregisterFromParent()
	. = ..()
	if(!QDELETED(src))
		qdel(src) // компонент нельзя трансферить другим сущностям + у каждого моба свой собственный.

/datum/component/mood/proc/stop_processing()
	STOP_PROCESSING(SSobj, src)

/datum/component/mood/proc/print_mood(mob/user)
	var/mob/living/owner = parent
	var/robotic_user = isrobotic(owner)
	var/msg = span_info("<EM>Вы изучаете [robotic_user? "свой статус" : "cвоё настроение"]</EM>\n")
	msg += span_notice("[robotic_user? "Статус нагрузки" : "Ментальное состояние"]: ") //Long term
	switch(sanity)
		if(SANITY_GREAT to INFINITY)
			msg += span_nicegreen("[robotic_user? "в моих регистрах ни единого бита мусора!" : "мой разум - словно чистейший храм!"]\n")
		if(SANITY_NEUTRAL to SANITY_GREAT)
			msg += span_nicegreen("[robotic_user? "высокая продуктивность." : "чувствую себя отлично!"]\n")
		if(SANITY_DISTURBED to SANITY_NEUTRAL)
			msg += span_nicegreen("[robotic_user? "все системы в норме" : "в последнее время чувствую себя нормально"].\n")
		if(SANITY_UNSTABLE to SANITY_DISTURBED)
			msg += span_warning("[robotic_user? "системы слегка тормозят." : "чувствую себя расстроенно..."]\n")
		if(SANITY_CRAZY to SANITY_UNSTABLE)
			msg += span_boldwarning("[robotic_user? "позитронка троттлит!!" : "у меня крыша едет!!"]\n")
		if(SANITY_INSANE to SANITY_CRAZY)
			msg += span_boldwarning("[robotic_user? "0xDEADBEEF 0x00000000 0xBADF00D!!" : "АХАХАХАХАХАХАХАХАХХА!!"]\n")

	msg += span_notice("Текущее [robotic_user? "состояние" : "настроение"]: ") //Short term
	switch(mood_level)
		if(1)
			msg += span_boldwarning("[robotic_user ? "проще пойти под пресс!" : "лучше сдохнуть!"]\n")
		if(2)
			msg += span_boldwarning("[robotic_user ? "аппаратные сбои системных узлов..." : "чувствую себя ужасно..."]\n")
		if(3)
			msg += span_boldwarning("[robotic_user ? "неудовлетворительные показатели." : "чувствую разочарование."]\n")
		if(4)
			msg += span_boldwarning("[robotic_user ? "лёгкое напряжение систем." : "мне грустно."]\n")
		if(5)
			msg += span_nicegreen("[robotic_user ? "функционирую штатно." : "я в порядке."]\n")
		if(6)
			msg += span_nicegreen("[robotic_user ? "скорость шины стабильна." : "мне вполне себе хорошо."]\n")
		if(7)
			msg += span_nicegreen("[robotic_user ? "системы работают в оптимуме." : "мне хорошо."]\n")
		if(8)
			msg += span_nicegreen("[robotic_user ? "отклик систем минимален!" : "я чувствую себя чудесно!"]\n")
		if(9)
			msg += span_nicegreen("[robotic_user ? "исполнение программы идеально!" : "я люблю эту жизнь!"]\n")

	msg += span_notice("Факторы:\n")//All moodlets
	if(mood_events.len)
		for(var/i in mood_events)
			var/datum/mood_event/event = mood_events[i]
			if(event?.description)
				if(robotic_user && event.description_robotic) // Если синт и ЕСЛИ есть синт-версия описания
					msg += "– [event.description_robotic]"
				else
					msg += "– [event.description]"
	else
		msg += span_nicegreen("Мне не на что сейчас реагировать.\n")
	to_chat(user || parent, examine_block(msg))

///Called after moodevent/s have been added/removed.
/datum/component/mood/proc/update_mood()
	mood = 0
	shown_mood = 0
	for(var/i in mood_events)
		var/datum/mood_event/event = mood_events[i]
		if(!event)
			continue
		mood += event.mood_change
		if(!event.hidden)
			shown_mood += event.mood_change
		mood *= mood_modifier
		shown_mood *= mood_modifier

	switch(mood)
		if(-INFINITY to MOOD_LEVEL_SAD4)
			mood_level = 1
		if(MOOD_LEVEL_SAD4 to MOOD_LEVEL_SAD3)
			mood_level = 2
		if(MOOD_LEVEL_SAD3 to MOOD_LEVEL_SAD2)
			mood_level = 3
		if(MOOD_LEVEL_SAD2 to MOOD_LEVEL_SAD1)
			mood_level = 4
		if(MOOD_LEVEL_SAD1 to MOOD_LEVEL_HAPPY1)
			mood_level = 5
		if(MOOD_LEVEL_HAPPY1 to MOOD_LEVEL_HAPPY2)
			mood_level = 6
		if(MOOD_LEVEL_HAPPY2 to MOOD_LEVEL_HAPPY3)
			mood_level = 7
		if(MOOD_LEVEL_HAPPY3 to MOOD_LEVEL_HAPPY4)
			mood_level = 8
		if(MOOD_LEVEL_HAPPY4 to INFINITY)
			mood_level = 9
	update_mood_icon()


/datum/component/mood/proc/update_mood_icon()
	var/mob/living/owner = parent
	if(owner.client && owner.hud_used)
		if(sanity < 25)
			screen_obj.icon_state = "mood_insane"
		else if (owner.has_status_effect(/datum/status_effect/chem/enthrall))//Fermichem enthral chem, maybe change?
			screen_obj.icon_state = "mood_entrance"
		else
			screen_obj.icon_state = "mood[mood_level]"
		screen_obj_sanity.icon_state = "sanity[sanity_level]" // Sandstorm sanity vis

/datum/component/mood/process() //Called on SSobj process
	if(QDELETED(parent)) // workaround to an obnoxious sneaky periodical runtime.
		qdel(src)
		return
	var/mob/living/owner = parent

	switch(mood_level)
		if(1)
			setSanity(sanity-0.2)
		if(2)
			setSanity(sanity-0.125, minimum=SANITY_CRAZY)
		if(3)
			setSanity(sanity-0.075, minimum=SANITY_UNSTABLE)
		if(4)
			setSanity(sanity-0.025, minimum=SANITY_DISTURBED)
		if(5)
			setSanity(sanity+0.1)
		if(6)
			setSanity(sanity+0.15)
		if(7)
			setSanity(sanity+0.20)
		if(8)
			setSanity(sanity+0.25, maximum=SANITY_GREAT)
		if(9)
			setSanity(sanity+0.4, maximum=SANITY_AMAZING)

	HandleNutrition(owner)
	HandleThirst(owner)

/datum/component/mood/proc/setSanity(amount, minimum=SANITY_INSANE, maximum=SANITY_NEUTRAL)//I'm sure bunging this in here will have no negative repercussions.
	var/mob/living/master = parent

	if(amount == sanity)
		return
	// If we're out of the acceptable minimum-maximum range move back towards it in steps of 0.5
	// If the new amount would move towards the acceptable range faster then use it instead
	if(sanity < minimum && amount < sanity + 0.5)
		amount = sanity + 0.5
	else if(sanity > maximum && amount > sanity - 0.5)
		amount = sanity - 0.5

	// Disturbed stops you from getting any more sane
	if(HAS_TRAIT(master, TRAIT_UNSTABLE))
		sanity = min(amount,sanity)
	else
		sanity = amount

	var/old_sanity_level = sanity_level
	switch(sanity)
		if(-INFINITY to SANITY_CRAZY)
			setInsanityEffect(MAJOR_INSANITY_PEN)
			master.add_movespeed_modifier(/datum/movespeed_modifier/sanity/insane)
			master.add_actionspeed_modifier(/datum/actionspeed_modifier/low_sanity)
			if(master?.client?.prefs.mood_vignette)
				master.overlay_fullscreen("depression", /atom/movable/screen/fullscreen/scaled/depression, 3)
			sanity_level = 6
		if(SANITY_CRAZY to SANITY_UNSTABLE)
			setInsanityEffect(MINOR_INSANITY_PEN)
			master.add_movespeed_modifier(/datum/movespeed_modifier/sanity/crazy)
			master.add_actionspeed_modifier(/datum/actionspeed_modifier/low_sanity)
			if(master?.client?.prefs.mood_vignette)
				master.overlay_fullscreen("depression", /atom/movable/screen/fullscreen/scaled/depression, 2)
			sanity_level = 5
		if(SANITY_UNSTABLE to SANITY_DISTURBED)
			setInsanityEffect(SLIGHT_INSANITY_PEN)
			master.add_movespeed_modifier(/datum/movespeed_modifier/sanity/disturbed)
			master.add_actionspeed_modifier(/datum/actionspeed_modifier/low_sanity)
			if(master?.client?.prefs.mood_vignette)
				master.overlay_fullscreen("depression", /atom/movable/screen/fullscreen/scaled/depression, 1)
			sanity_level = 4
		if(SANITY_DISTURBED to SANITY_NEUTRAL)
			setInsanityEffect(0)
			master.remove_movespeed_modifier(MOVESPEED_ID_SANITY)
			master.remove_actionspeed_modifier(ACTIONSPEED_ID_SANITY)
			master.clear_fullscreen("depression")
			sanity_level = 3
		if(SANITY_NEUTRAL+1 to SANITY_GREAT+1) //shitty hack but +1 to prevent it from responding to super small differences
			setInsanityEffect(0)
			master.remove_movespeed_modifier(MOVESPEED_ID_SANITY)
			master.add_actionspeed_modifier(/datum/actionspeed_modifier/high_sanity)
			sanity_level = 2
		if(SANITY_GREAT+1 to INFINITY)
			setInsanityEffect(ECSTATIC_SANITY_PEN) //It's not a penalty but w/e
			master.remove_movespeed_modifier(MOVESPEED_ID_SANITY)
			master.add_actionspeed_modifier(/datum/actionspeed_modifier/high_sanity)
			sanity_level = 1

	// Crazy or insane = add some uncommon hallucinations
	if(sanity_level >= SANITY_CRAZY)
		master.hallucination = min(master.hallucination + 10, 50)
	else
		master.hallucination = 0

	if(sanity_level != old_sanity_level)
		if(sanity_level >= 4)
			if(!malus)
				if(!length(free_maluses))
					ADD_SKILL_MODIFIER_BODY(/datum/skill_modifier/bad_mood, malus_id++, master, malus)
				else
					malus = pick_n_take(free_maluses)
					if(master.mind)
						master.mind.add_skill_modifier(malus.identifier)
					else
						malus.RegisterSignal(master, COMSIG_MOB_ON_NEW_MIND, TYPE_PROC_REF(/datum/skill_modifier, on_mob_new_mind), TRUE)
			malus.value_mod = malus.level_mod = 1 - (sanity_level - 3) * MOOD_INSANITY_MALUS
		else if(malus)
			if(master.mind)
				master.mind.remove_skill_modifier(malus.identifier)
			else
				malus.UnregisterSignal(master, COMSIG_MOB_ON_NEW_MIND)
			free_maluses += malus
			malus = null

	update_mood_icon() // Sandstorm uncommented

/datum/component/mood/proc/setInsanityEffect(newval)//More code so that the previous proc works
	if(newval == insanity_effect)
		return

	var/mob/living/L = parent
	if(newval == ECSTATIC_SANITY_PEN && !bonus)
		ADD_SKILL_MODIFIER_BODY(/datum/skill_modifier/great_mood, null, L, bonus)
	else if(bonus)
		REMOVE_SKILL_MODIFIER_BODY(/datum/skill_modifier/great_mood, null, L)
		bonus = null

	insanity_effect = newval

/datum/component/mood/proc/modify_sanity(datum/source, amount, minimum = SANITY_INSANE, maximum = SANITY_AMAZING)
	setSanity(sanity + amount, minimum, maximum)

/datum/component/mood/proc/add_event(datum/source, category, type, param) //Category will override any events in the same category, should be unique unless the event is based on the same thing like hunger.
	var/datum/mood_event/the_event
	if(mood_events[category])
		the_event = mood_events[category]
		if(the_event.type != type)
			clear_event(null, category)
		else
			if(the_event.timeout)
				schedule_event_timeout(category, the_event.timeout)
			return FALSE //Don't have to update the event.
	the_event = new type(src, param)//This causes a runtime for some reason, was this me? No - there's an event floating around missing a definition.

	mood_events[category] = the_event
	update_mood()

	if(the_event.timeout)
		schedule_event_timeout(category, the_event.timeout)

/// Взводит таймер истечения мудлета, снимая предыдущий таймер той же категории.
/datum/component/mood/proc/schedule_event_timeout(category, timeout)
	clear_event_timer(category)
	mood_event_timers[category] = addtimer(CALLBACK(src, PROC_REF(clear_event), null, category), timeout, TIMER_STOPPABLE)

/// Снимает таймер истечения мудлета, если он был взведён. Повторный вызов безопасен:
/// deltimer уже отработавшего или несуществующего id - это no-op.
/datum/component/mood/proc/clear_event_timer(category)
	var/timer_id = mood_event_timers[category]
	mood_event_timers -= category
	if(isnull(timer_id))
		return
	deltimer(timer_id)

/datum/component/mood/proc/clear_event(datum/source, category)
	clear_event_timer(category)
	var/datum/mood_event/event = mood_events[category]
	if(!event)
		return FALSE

	mood_events -= category
	qdel(event)
	update_mood()

/datum/component/mood/proc/remove_temp_moods() //Removes all temp moods
	// Список правится прямо в цикле, поэтому идём по копии ключей: иначе сдвиг индексов
	// пропускал каждый второй временный мудлет, и он оставался висеть вместе с таймером.
	for(var/category in mood_events.Copy())
		var/datum/mood_event/moodlet = mood_events[category]
		if(!moodlet || !moodlet.timeout)
			continue
		clear_event_timer(category)
		mood_events -= category
		qdel(moodlet)
	update_mood()

/datum/component/mood/proc/modify_hud(datum/source)
	var/mob/living/owner = parent
	var/datum/hud/hud = owner.hud_used
	screen_obj = new(null, hud)
	screen_obj_sanity = new(null, hud)
	hud.infodisplay += screen_obj
	hud.infodisplay += screen_obj_sanity // Sandstorm sanity
	RegisterSignal(hud, COMSIG_PARENT_QDELETING, PROC_REF(unmodify_hud))
	RegisterSignal(screen_obj, COMSIG_SCREEN_ELEMENT_CLICK, PROC_REF(hud_click))

/datum/component/mood/proc/unmodify_hud(datum/source)
	if(!screen_obj || !parent)
		return
	var/mob/living/owner = parent
	var/datum/hud/hud = owner.hud_used
	if(hud && hud.infodisplay)
		hud.infodisplay -= screen_obj
		hud.infodisplay -= screen_obj_sanity // Sandstorm sanity
	QDEL_NULL(screen_obj)
	QDEL_NULL(screen_obj_sanity) // Sandstorm sanity

/datum/component/mood/proc/hud_click(datum/source, location, control, params, mob/user)
	print_mood(user)


/datum/component/mood/proc/HandleNutrition(mob/living/L)
	if(isethereal(L))
		HandleCharge(L)
	if(HAS_TRAIT(L, TRAIT_NOHUNGER))
		return FALSE //no mood events for nutrition
	switch(L.nutrition)
		if(NUTRITION_LEVEL_FULL to INFINITY)
			if(!(HAS_TRAIT(L, TRAIT_INCUBUS) || HAS_TRAIT(L, TRAIT_SUCCUBUS)))
			//No bad fat mood for incubi/succubi, voracious gets a positive mood in needs_events.dm
				add_event(null, "nutrition", /datum/mood_event/fat)
		if(NUTRITION_LEVEL_WELL_FED to NUTRITION_LEVEL_FULL)
			add_event(null, "nutrition", /datum/mood_event/wellfed)
		if(NUTRITION_LEVEL_FED to NUTRITION_LEVEL_WELL_FED)
			add_event(null, "nutrition", /datum/mood_event/fed)
		if(NUTRITION_LEVEL_HUNGRY to NUTRITION_LEVEL_FED)
			clear_event(null, "nutrition")
		if(NUTRITION_LEVEL_STARVING to NUTRITION_LEVEL_HUNGRY)
			add_event(null, "nutrition", /datum/mood_event/hungry)
		if(0 to NUTRITION_LEVEL_STARVING)
			add_event(null, "nutrition", /datum/mood_event/starving)

/datum/component/mood/proc/HandleThirst(mob/living/L)
	if(HAS_TRAIT(L, TRAIT_NOTHIRST))
		return FALSE //no mood events for thirst
	if(L.thirst >= THIRST_LEVEL_THRESHOLD)
		L.set_thirst(clamp(L.thirst, 0, THIRST_LEVEL_THRESHOLD))
	switch(get_thirst(L))
		if(THIRST_LEVEL_QUENCHED to INFINITY)
			add_event(null, "thirst", /datum/mood_event/quenched)
		if(THIRST_LEVEL_THIRSTY to THIRST_LEVEL_QUENCHED)
			clear_event(null, "thirst")
		if(THIRST_LEVEL_PARCHED to THIRST_LEVEL_THIRSTY)
			add_event(null, "thirst", /datum/mood_event/thirsty)
		if(0 to THIRST_LEVEL_PARCHED)
			add_event(null, "thirst", /datum/mood_event/dehydrated)

/datum/component/mood/proc/HandleCharge(mob/living/carbon/human/H)
	var/datum/species/ethereal/E = H.dna.species
	switch(E.get_charge(H))
		if(ETHEREAL_CHARGE_NONE to ETHEREAL_CHARGE_LOWPOWER)
			add_event(null, "charge", /datum/mood_event/decharged)
		if(ETHEREAL_CHARGE_LOWPOWER to ETHEREAL_CHARGE_NORMAL)
			add_event(null, "charge", /datum/mood_event/lowpower)
		if(ETHEREAL_CHARGE_NORMAL to ETHEREAL_CHARGE_ALMOSTFULL)
			clear_event(null, "charge")
		if(ETHEREAL_CHARGE_ALMOSTFULL to ETHEREAL_CHARGE_FULL)
			add_event(null, "charge", /datum/mood_event/charged)
		if(ETHEREAL_CHARGE_FULL to ETHEREAL_CHARGE_OVERLOAD)
			add_event(null, "charge", /datum/mood_event/overcharged)
		if(ETHEREAL_CHARGE_OVERLOAD to ETHEREAL_CHARGE_DANGEROUS)
			add_event(null, "charge", /datum/mood_event/supercharged)

/datum/component/mood/proc/update_beauty(datum/source, area/A)
	if(A.outdoors) //if we're outside, we don't care.
		clear_event(null, "area_beauty")
		return FALSE
	if(HAS_TRAIT(parent, TRAIT_SNOB))
		switch(A.beauty)
			if(-INFINITY to BEAUTY_LEVEL_HORRID)
				add_event(null, "area_beauty", /datum/mood_event/horridroom)
				return
			if(BEAUTY_LEVEL_HORRID to BEAUTY_LEVEL_BAD)
				add_event(null, "area_beauty", /datum/mood_event/badroom)
				return
	switch(A.beauty)
		if(-INFINITY to BEAUTY_LEVEL_DECENT)
			clear_event(null, "area_beauty")
		if(BEAUTY_LEVEL_DECENT to BEAUTY_LEVEL_GOOD)
			add_event(null, "area_beauty", /datum/mood_event/decentroom)
		if(BEAUTY_LEVEL_GOOD to BEAUTY_LEVEL_GREAT)
			add_event(null, "area_beauty", /datum/mood_event/goodroom)
		if(BEAUTY_LEVEL_GREAT to INFINITY)
			add_event(null, "area_beauty", /datum/mood_event/greatroom)

///Called when parent is revived.
/datum/component/mood/proc/on_revive(datum/source, full_heal)
	START_PROCESSING(SSobj, src)
	if(!full_heal)
		return
	remove_temp_moods()
	setSanity(initial(sanity))

///Causes direct drain of someone's sanity, call it with a numerical value corresponding how badly you want to hurt their sanity
/datum/component/mood/proc/direct_sanity_drain(datum/source, amount)
	setSanity(sanity + amount)

#undef ECSTATIC_SANITY_PEN
#undef SLIGHT_INSANITY_PEN
#undef MINOR_INSANITY_PEN
#undef MAJOR_INSANITY_PEN
#undef MOOD_INSANITY_MALUS
