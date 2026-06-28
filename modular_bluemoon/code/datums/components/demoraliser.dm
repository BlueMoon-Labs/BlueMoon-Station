/*
 * Applies a role-based mood if you can see the parent.
 *
 * - Applies a mood to people who are in visible range of the item.
 * - Does not re-apply mood to people who already have it.
 * - Sends a signal if a mood is successfully applied.
 */

#define FEAR_LEVEL_CAPTAIN 1
#define FEAR_LEVEL_SECURITY 2
#define FEAR_LEVEL_HEADS 3
#define FEAR_LEVEL_MINDSHIELD 4
#define FEAR_LEVEL_CHAPLAIN 5
#define FEAR_LEVEL_OTHERS 6

/// How often a propaganda host (poster/flag) re-scans view() for new victims.
/// The expensive part is the view() sweep; throttling it well below the per-tick
/// SSobj cadence is the whole point. The per-victim was_scared cooldown and
/// next_scare keep the actual mood spam in check, so this only governs CPU.
#define DEMORALISER_SCAN_INTERVAL (6 SECONDS)

/// Tiles around the host that the propaganda scare sweep reaches.
#define DEMORALISER_SCARE_RANGE 5
/// Minimum delay between successive scare applications from one host's sweep
/// (the mood-spam throttle, distinct from the can_scan() CPU throttle above).
#define DEMORALISER_SCARE_COOLDOWN (12 SECONDS)

// Чтобы из-за 10 плакатов все вокруг не охуевали каждые 5 наносекунд. Не самое лучшее решение, ну и ладно
/mob/living/carbon/human
	/// Last fear effect apply. Primarily used in inteq propaganda
	var/was_scared = 0

/datum/proximity_monitor/advanced/demoraliser
	var/next_scare = 0
	/// world.time before which the host should skip its view() scan (CPU throttle).
	var/next_scan = 0

/// Returns TRUE at most once per DEMORALISER_SCAN_INTERVAL, so a host's process()
/// only runs the costly view() sweep on a throttled cadence instead of every tick.
/datum/proximity_monitor/advanced/demoraliser/proc/can_scan()
	if(world.time < next_scan)
		return FALSE
	next_scan = world.time + DEMORALISER_SCAN_INTERVAL
	return TRUE

/// Sweeps view() around the host and applies the scare to each living mob in range.
/// Shared by the poster (contraband.dm) and flag (item.dm) hosts, which delegate here.
/datum/proximity_monitor/advanced/demoraliser/proc/do_scare_scan()
	if(world.time < next_scare)
		return
	var/scared_someone = FALSE
	for(var/mob/living/viewer in view(DEMORALISER_SCARE_RANGE, host))
		pugach(viewer)
		scared_someone = TRUE
	if(scared_someone)
		next_scare = world.time + DEMORALISER_SCARE_COOLDOWN


/datum/proximity_monitor/advanced/demoraliser/New(atom/_host, range, _ignore_if_not_on_turf = TRUE)
	. = ..()
	host = _host
	RegisterSignal(_host, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/proximity_monitor/advanced/demoraliser/proc/on_examine(datum/source, mob/examiner)
	SIGNAL_HANDLER
	if(isliving(examiner))
		pugach(examiner)

/datum/proximity_monitor/advanced/demoraliser/proc/pugach(mob/living/viewer)
	if(!ishuman(viewer))
		return
	var/mob/living/carbon/human/beholder = viewer
	if(beholder.was_scared > world.time)
		return
	if (beholder.stat != CONSCIOUS)
		return
	if(beholder.is_blind())
		return
	if(!beholder.mind)
		return
	if(HAS_TRAIT(beholder, TRAIT_FEARLESS))
		return
	if(IS_INTEQ(beholder))
		SEND_SIGNAL(beholder, COMSIG_ADD_MOOD_EVENT, "inteq_propagand", /datum/mood_event/inteq_happy)
		return
	if(beholder.mind.antag_datums) // все антажки
		return
	beholder.was_scared = world.time + 5 SECONDS
	var/fear_level = get_fear_level(beholder)
	SEND_SIGNAL(beholder, COMSIG_ADD_MOOD_EVENT, "inteq_propagand", /datum/mood_event/inteq_scared, fear_level)
	if(prob(50))
		var/message = pick("крайне вас напрягает.", "напоминает вам, что вы тут не в безопасности.", "просто отвратительно!", "возмутительно!")
		to_chat(beholder, "<span class='warning'>Судя по [host], наёмники из InteQ уже рядом! Это [message]</span>")

	// Эффекты, помимо муда, стакающиеся друг с другом. Чем страшнее челику, тем больше стакается эффектов
	// Эффекты для глав и круче
	if(prob(30))
		beholder.emote("scowl")
		beholder.pointed(host)
	if(fear_level < FEAR_LEVEL_MINDSHIELD)
		return

	// Эффекты для остальных сильных духом
	if(prob(30))
		beholder.Jitter(7)
		beholder.emote("chill")
	if(fear_level < FEAR_LEVEL_OTHERS)
		return

	// Эффекты для вообще остальных
	var/reaction = rand(1,5)
	switch(reaction)
		if(1)
			beholder.Confused(15)
			beholder.pointed(host)
			beholder.say("Какого чёрта?!", forced="phobia")
		if(2)
			beholder.emote("tremble")
			beholder.Jitter(15)
			beholder.say("Наёмники уже близко!!", forced = "phobia")
			beholder.pointed(host)
		if(3)
			beholder.emote("scream")
			beholder.Jitter(15)
			beholder.say("InteQ уже здесь!! Куда смотрят офицеры?!!", forced = "phobia")
			beholder.pointed(host)
		if(4)
			beholder.emote("mumbles")
			beholder.stuttering += 15
			beholder.pointed(host)
		if(5)
			beholder.Confused(20)

/datum/proximity_monitor/advanced/demoraliser/proc/get_fear_level(mob/living/carbon/human/victim)
	if(victim.mind.assigned_role == "Captain")
		return FEAR_LEVEL_CAPTAIN
	if(victim.mind.assigned_role in list("Head of Security","Warden","Security Officer","Brig Physisician","Detective", "Blueshield"))
		return FEAR_LEVEL_SECURITY
	if(victim.mind.assigned_role in list("NanoTrasen Representative","Head Of Personnel","Research Director","Chief Medical Officer","Chief Engineer","Quartermaster","Bridge Officer"))
		return FEAR_LEVEL_HEADS
	if(HAS_TRAIT(victim, TRAIT_MINDSHIELD))
		return FEAR_LEVEL_MINDSHIELD
	if(victim.mind.assigned_role == "Chaplain")
		return FEAR_LEVEL_CHAPLAIN
	return FEAR_LEVEL_OTHERS

/datum/mood_event/inteq_scared
	description = "InteQ на борту!\n"
	mood_change = -1
	timeout = 7 MINUTES

/datum/mood_event/inteq_scared/add_effects(fear_level)
	var/message = "InteQ на борту!"
	switch(fear_level)
		if(FEAR_LEVEL_CAPTAIN)
			message = "Кто развешивает эти тряпки на МОЕЙ станции?! Кишки на гафель намотаю!"
			mood_change = -2
		if(FEAR_LEVEL_SECURITY)
			message = "Наёмники на борту. Нужно смотреть в оба!"
			mood_change = -4
		if(FEAR_LEVEL_HEADS)
			message = "Проклятые наёмники среди нас! А вдруг это кто-то из моих подчинённых?..."
			mood_change = -6
		if(FEAR_LEVEL_MINDSHIELD)
			message = "Среди нас гуляют убийцы и бандиты! Хорошо, что имплант у меня в голове меня немножко успокаивает..."
			mood_change = -8
		if(FEAR_LEVEL_CHAPLAIN)
			message = "Алчные убийцы прячутся среди прихожан. Проклят гнев их, ибо жесток, и ярость их, ибо свирепа."
			mood_change = -10
		if(FEAR_LEVEL_OTHERS)
			message = "InteQ где-то рядом!!! Я на это не подписывался!! КУДА СМОТРИТ СЛУЖБА БЕЗОПАСНОСТИ?!!"
			mood_change = -18
	description = span_boldwarning(message)


/datum/mood_event/inteq_happy
	description = span_greenannounce("Да здравствует Адмирал Браун!\n")
	mood_change = 18
	timeout = 7 MINUTES

#undef FEAR_LEVEL_CAPTAIN
#undef FEAR_LEVEL_SECURITY
#undef FEAR_LEVEL_HEADS
#undef FEAR_LEVEL_MINDSHIELD
#undef FEAR_LEVEL_CHAPLAIN
#undef FEAR_LEVEL_OTHERS
#undef DEMORALISER_SCAN_INTERVAL
#undef DEMORALISER_SCARE_RANGE
#undef DEMORALISER_SCARE_COOLDOWN
