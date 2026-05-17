// Психоз-флейворные галлюцинации: единый зонтичный тип
// /datum/hallucination/psychosis с подтипами. Все эффекты видит/слышит
// только сам target - стандартный шаблон через target.client.images,
// playsound_local, to_chat.
// PSYCHOSIS_THEME_* и прочие defines объявлены в
// code/__BLUEMOONCODE/_DEFINES/psychosis.dm (включается до unit_tests).

GLOBAL_LIST_INIT(psychosis_themes, list(
	PSYCHOSIS_THEME_STALKER, PSYCHOSIS_THEME_MASSACRE, PSYCHOSIS_THEME_RITUAL,
	PSYCHOSIS_THEME_WHISPERING, PSYCHOSIS_THEME_CHILDREN, PSYCHOSIS_THEME_MACHINERY,
))

// Debug logging helpers. Активны только при #define PSYCHOSIS_DEBUG_LOG
// (см. __BLUEMOONCODE/_DEFINES/psychosis.dm). Цель - разовый сбор evidence
// по жалобе "звуки не играют, эффекты не видно".

#ifdef PSYCHOSIS_DEBUG_LOG

/proc/psy_log(text)
	var/line = "[time2text(world.timeofday, "hh:mm:ss")] [text]"
	log_world("PSY: [line]")
	text2file("[line]\n", "data/logs/psychosis_debug.log")

/// Обёртка над playsound_local с (в debug-сборке) логом давления.
/// Раньше пыталась трекать каналы и глушить их на on_remove, но
/// SSsounds.random_available_channel() возвращает общий ротируемый пул - те
/// же каналы за 5 минут психоза успевают разойтись по чужим звукам, и
/// stop_sound_channel() в итоге глушил у клиента не наш ambient, а первое
/// попавшееся. Поэтому трекинг убран: длинные эмбиенты доиграют до конца
/// сами, это меньшее зло, чем случайные обрывы постороннего аудио.
/proc/psy_play(mob/M, turf/T, soundin, vol = 30, vary = TRUE)
	if(!M || !T)
		psy_log("psy_play SKIP no_args mob=[M] turf=[T] sound=[soundin]")
		return
	var/channel = SSsounds.random_available_channel()
	var/turf/own_t = get_turf(M)
	var/datum/gas_mixture/src_env = T.return_air()
	var/datum/gas_mixture/own_env = own_t?.return_air()
	var/src_p = src_env ? src_env.return_pressure() : 0
	var/own_p = own_env ? own_env.return_pressure() : 0
	var/effective = (src_env && own_env) ? min(src_p, own_p) : 0
	var/distance = get_dist(own_t, T)
	var/marker = ""
	if(effective <= 0)
		marker = "MUTED_NO_AIR"
	else if(effective < 50)
		marker = "QUIET_LOW_AIR"
	psy_log("play mob=[M] src=[T.x],[T.y],[T.z] dist=[distance] sp=[src_p] op=[own_p] eff=[effective] vol=[vol] file=[soundin] channel=[channel] [marker]")
	M.playsound_local(T, soundin, vol, vary, channel = channel)

/proc/psy_log_visual(obj/effect/hallucination/simple/marker_obj, mob/target_mob, type_name)
	if(!marker_obj || !target_mob)
		psy_log("visual SKIP type=[type_name] marker=[marker_obj] target=[target_mob]")
		return
	var/turf/spawn_turf = get_turf(marker_obj)
	var/turf/target_turf = get_turf(target_mob)
	var/distance = get_dist(target_turf, spawn_turf)
	var/in_view = (spawn_turf in view(target_mob)) ? "yes" : "NO"
	var/has_client = target_mob.client ? "yes" : "NO"
	psy_log("visual type=[type_name] pos=[spawn_turf?.x],[spawn_turf?.y],[spawn_turf?.z] dist=[distance] in_view=[in_view] has_client=[has_client] icon=[marker_obj.image_icon] state=[marker_obj.image_state] layer=[marker_obj.image_layer]")

#else

/proc/psy_log(text)
	return

/proc/psy_log_visual(obj/effect/hallucination/simple/marker_obj, mob/target_mob, type_name)
	return

/proc/psy_play(mob/M, turf/T, soundin, vol = 30, vary = TRUE)
	if(!M || !T)
		return
	// Каналы НЕ трекаем: общий ротируемый пул random_available_channel()
	// за длительность психоза успевает разойтись по чужим звукам, и
	// stop_sound_channel() на on_remove глушил бы не наш ambient. См.
	// объяснение в debug-ветке этого же proc.
	var/channel = SSsounds.random_available_channel()
	M.playsound_local(T, soundin, vol, vary, channel = channel)

#endif

/// Случайная видимая клетка в радиусе view(). Для визуальных эффектов, где
/// попадание за стену = нулевой эффект. Fallback - random_far_turf() из базы.
/datum/hallucination/proc/random_far_view_turf(min_dist = 4)
	var/turf/target_T = get_turf(target)
	if(!target_T)
		return null
	var/list/candidates = list()
	for(var/turf/T in view(target))
		if(T == target_T)
			continue
		if(get_dist(target_T, T) < min_dist)
			continue
		candidates += T
	if(!length(candidates))
		return random_far_turf()
	return pick(candidates)

GLOBAL_LIST_EMPTY_TYPED(psychosis_pool_by_tier, /list)

/// Один раз за раунд раскладывает GLOB.psychosis_hallucination_list по трём
/// tier-пулам. Lazy-build вызывается из status_effect/psychosis.
/proc/build_psychosis_tier_pools()
	var/list/pools = list(list(), list(), list())
	for(var/type in GLOB.psychosis_hallucination_list)
		var/datum/hallucination/psychosis/proto = type
		var/tier = clamp(initial(proto.severity), PSYCHOSIS_TIER_MILD, PSYCHOSIS_TIER_SEVERE)
		pools[tier][type] = GLOB.psychosis_hallucination_list[type]
	GLOB.psychosis_pool_by_tier = pools

GLOBAL_LIST_INIT(psychosis_hallucination_list, list(
	// базовые звук+текст
	/datum/hallucination/psychosis/whisper = 40,
	/datum/hallucination/psychosis/heartbeat = 25,
	/datum/hallucination/psychosis/shadow = 20,
	/datum/hallucination/psychosis/bloodstain = 10,
	/datum/hallucination/psychosis/presence = 15,
	/datum/hallucination/psychosis/distorted_radio = 12,
	/datum/hallucination/psychosis/laughter = 18,
	/datum/hallucination/psychosis/name_call = 22,
	/datum/hallucination/psychosis/distant_scream = 10,
	/datum/hallucination/psychosis/clock_ticks = 12,
	/datum/hallucination/psychosis/phantom_steps = 18,
	/datum/hallucination/psychosis/chains_rattle = 8,
	/datum/hallucination/psychosis/horror_alarm = 10,
	/datum/hallucination/psychosis/distant_horn = 8,
	/datum/hallucination/psychosis/void_drone = 12,
	// звуковые фантомы
	/datum/hallucination/psychosis/phantom_door = 12,
	/datum/hallucination/psychosis/phantom_typing = 14,
	/datum/hallucination/psychosis/phantom_flatline = 8,
	/datum/hallucination/psychosis/phantom_gunshot = 8,
	/datum/hallucination/psychosis/phantom_bone_crack = 8,
	/datum/hallucination/psychosis/phantom_drag = 10,
	/datum/hallucination/psychosis/phantom_chant = 12,
	/datum/hallucination/psychosis/phantom_baby_cry = 8,
	/datum/hallucination/psychosis/phantom_marching = 10,
	// визуальные
	/datum/hallucination/psychosis/phantom_corpse = 8,
	/datum/hallucination/psychosis/shadow_swarm = 6,
	/datum/hallucination/psychosis/red_eyes = 10,
	/datum/hallucination/psychosis/wall_face = 9,
	/datum/hallucination/psychosis/phantom_skeleton = 7,
	/datum/hallucination/psychosis/phantom_severed_hand = 9,
	/datum/hallucination/psychosis/phantom_severed_head = 7,
	/datum/hallucination/psychosis/phantom_guts = 8,
	/datum/hallucination/psychosis/bloody_footprints = 10,
	/datum/hallucination/psychosis/phantom_blood_pool = 8,
	/datum/hallucination/psychosis/phantom_ash_silhouette = 7,
	/datum/hallucination/psychosis/phantom_plush = 9,
	/datum/hallucination/psychosis/phantom_head_on_pike = 5,
	/datum/hallucination/psychosis/phantom_rune = 9,
	/datum/hallucination/psychosis/phantom_runner = 8,
	/datum/hallucination/psychosis/phantom_crawler = 7,
	/datum/hallucination/psychosis/phantom_doppelganger = 6,
	/datum/hallucination/psychosis/phantom_scorch = 10,
	/datum/hallucination/psychosis/phantom_blood_drip = 9,
	/datum/hallucination/psychosis/phantom_sparks = 10,
	/datum/hallucination/psychosis/phantom_xeno_silhouette = 5,
	/datum/hallucination/psychosis/darken_pulse = 10,
	/datum/hallucination/psychosis/blur_pulse = 10,
	/datum/hallucination/psychosis/static_flash = 8,
	/datum/hallucination/psychosis/red_vision_pulse = 7,
	/datum/hallucination/psychosis/phantom_cobweb = 8,
	// сенсорные / телесные
	/datum/hallucination/psychosis/crawling_skin = 22,
	/datum/hallucination/psychosis/phantom_smell = 20,
	/datum/hallucination/psychosis/phantom_taste = 18,
	/datum/hallucination/psychosis/cold_touch = 14,
	/datum/hallucination/psychosis/memory_flash = 12,
	// ментальные интрузии
	/datum/hallucination/psychosis/inner_voice = 18,
	/datum/hallucination/psychosis/countdown = 8,
	/datum/hallucination/psychosis/echo_self = 12,
	// гаслайтинг
	/datum/hallucination/psychosis/fake_priority_announce = 4,
	/datum/hallucination/psychosis/fake_health_alert = 6,
	/datum/hallucination/psychosis/wrong_sign = 6,
	/datum/hallucination/psychosis/fake_pda = 5,
	// искажение других живых
	/datum/hallucination/psychosis/bloody_other = 6,
	/datum/hallucination/psychosis/wrong_face = 4,
	/datum/hallucination/psychosis/shadow_behind_other = 5,
	))

/datum/hallucination/psychosis
	abstract_hallucination_parent = /datum/hallucination/psychosis
	/// PSYCHOSIS_TIER_*. Дефолт MILD - безопасный fallback для типов без явной классификации.
	var/severity = PSYCHOSIS_TIER_MILD
	/// Список PSYCHOSIS_THEME_* строк. null - универсальный (входит в любую тему).
	var/list/themes = null

// Дешёвая чисто-текстовая галлюцинация - курсивная строка в чат, изредка с тихим звуком.

GLOBAL_LIST_INIT(psychosis_whisper_lines, list(
	"...ты их видишь?...",
	"...они смотрят...",
	"...за тобой...",
	"...беги...",
	"...тише...",
	"...уже близко...",
	"...нет выхода...",
	"...я тут...",
	"...скоро...",
	"...тебя здесь нет...",
	"...всё это сон...",
	"...не оборачивайся...",
	"...слышишь?...",
	"...они знают...",
	"...не доверяй ему...",
	"...не доверяй ей...",
	))

/datum/hallucination/psychosis/whisper
	themes = list(PSYCHOSIS_THEME_WHISPERING, PSYCHOSIS_THEME_RITUAL)

/datum/hallucination/psychosis/whisper/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/line = pick(GLOB.psychosis_whisper_lines)
	feedback_details += "Whisper: [line]"
	to_chat(target, "<span class='italics'>[line]</span>")
	if(prob(45))
		var/turf/source = random_far_turf()
		if(source)
			psy_play(target, source, pickweight(list(
				'sound/hallucinations/behind_you1.ogg' = 1,
				'sound/hallucinations/behind_you2.ogg' = 1,
				'sound/hallucinations/im_here1.ogg' = 1,
				'sound/hallucinations/im_here2.ogg' = 1,
				'sound/hallucinations/over_here1.ogg' = 1,
				'sound/hallucinations/over_here2.ogg' = 1,
				'sound/hallucinations/over_here3.ogg' = 1,
				'sound/hallucinations/psychosis/whisper_voices_1.ogg' = 1,
				'sound/hallucinations/psychosis/whisper_voices_2.ogg' = 1,
				'sound/hallucinations/psychosis/whisper_spells.ogg' = 1,
				'sound/hallucinations/psychosis/whisper_vocal.ogg' = 1,
				'sound/hallucinations/psychosis/whisper_horror.ogg' = 3,
				)), 50, TRUE)
	qdel(src)

#define PSYCHOSIS_HEARTBEAT_MIN 3
#define PSYCHOSIS_HEARTBEAT_MAX 5

/datum/hallucination/psychosis/heartbeat
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/heartbeat/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/beats = rand(PSYCHOSIS_HEARTBEAT_MIN, PSYCHOSIS_HEARTBEAT_MAX)
	feedback_details += "Beats: [beats]"
	for(var/i in 1 to beats)
		if(QDELETED(target) || target.stat == DEAD)
			break
		psy_play(target, target, pick(
			'sound/effects/heart_beat.ogg',
			'sound/hallucinations/psychosis/heartbeat_corrupted.ogg',
			), 50, FALSE)
		shake_camera(target, 1, 1)
		sleep(rand(10, 16))
	qdel(src)

#undef PSYCHOSIS_HEARTBEAT_MIN
#undef PSYCHOSIS_HEARTBEAT_MAX

// Чисто-локальное изображение через /obj/effect/hallucination/simple -
// owner_client уже отрабатывает logout/cryo корректно (см. шапку Hallucination.dm).

/obj/effect/hallucination/simple/shadow
	name = "тень"
	image_icon = 'icons/mob/human.dmi'
	image_state = "husk"
	col_mod = "#000000"
	image_layer = MOB_LAYER

/datum/hallucination/psychosis/shadow
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/obj/effect/hallucination/simple/shadow/figure

/datum/hallucination/psychosis/shadow/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/spawn_turf = random_far_view_turf()
	if(!spawn_turf)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y],[spawn_turf.z]"
	figure = new(spawn_turf, target)
	psy_log_visual(figure, target, "shadow")
	figure.setDir(pick(GLOB.cardinals))
	QDEL_IN(src, rand(40, 70))

/datum/hallucination/psychosis/shadow/Destroy()
	QDEL_NULL(figure)
	return ..()

// Без звука, чтобы можно было сочетать с другими эффектами в один тик.

/obj/effect/hallucination/simple/bloodstain
	name = "кровавое пятно"
	image_icon = 'icons/effects/blood.dmi'
	image_state = "floor1"
	image_layer = LOW_OBJ_LAYER

/datum/hallucination/psychosis/bloodstain
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/obj/effect/hallucination/simple/bloodstain/stain

/datum/hallucination/psychosis/bloodstain/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y],[spawn_turf.z]"
	stain = new(spawn_turf, target)
	psy_log_visual(stain, target, "bloodstain")
	stain.image_state = pick("floor1", "floor2", "floor3", "floor4", "floor5", "floor6", "floor7")
	stain.Show()
	QDEL_IN(src, rand(25, 50))

/datum/hallucination/psychosis/bloodstain/Destroy()
	QDEL_NULL(stain)
	return ..()

GLOBAL_LIST_INIT(psychosis_presence_lines, list(
	"<span class='warning'>Вам кажется, что за вами кто-то стоит.</span>",
	"<span class='warning'>Краем глаза вы замечаете движение.</span>",
	"<span class='warning'>По спине пробегает холодок.</span>",
	"<span class='warning'>Вы слышите чьё-то дыхание совсем рядом.</span>",
	"<span class='warning'>Вам кажется, что кто-то смотрит на вас в упор.</span>",
	"<span class='warning'>Воздух за спиной как будто шевельнулся.</span>",
	))

/datum/hallucination/psychosis/presence
	themes = list(PSYCHOSIS_THEME_STALKER, PSYCHOSIS_THEME_WHISPERING)

/datum/hallucination/psychosis/presence/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(GLOB.psychosis_presence_lines))
	psy_play(target, source, pickweight(list(
		'sound/hallucinations/i_see_you1.ogg' = 1,
		'sound/hallucinations/i_see_you2.ogg' = 1,
		'sound/hallucinations/turn_around1.ogg' = 1,
		'sound/hallucinations/turn_around2.ogg' = 1,
		'sound/hallucinations/look_up1.ogg' = 1,
		'sound/hallucinations/look_up2.ogg' = 1,
		'sound/misc/cluwne_breathing.ogg' = 1,
		'sound/hallucinations/psychosis/breath_creature_1.ogg' = 1,
		'sound/hallucinations/psychosis/breath_creature_2.ogg' = 1,
		'sound/hallucinations/psychosis/breath_ghostly.ogg' = 1,
		'sound/hallucinations/psychosis/breath_ominous.ogg' = 1,
		'sound/hallucinations/psychosis/ghosthunt.ogg' = 1,
		'sound/hallucinations/psychosis/monster_growl.ogg' = 3,
		)), 50, TRUE)
	qdel(src)

// "Радиосообщение" от лица случайного живого члена экипажа, перед сообщением -
// короткий бёрст помех.

GLOBAL_LIST_INIT(psychosis_radio_fragments, list(
	"...они уже...",
	"...не выходи...",
	"...весь экипаж...",
	"...кровь повсюду...",
	"...не верь...",
	"...слышишь меня?...",
	"...мы все мертвы...",
	"...беги отсюда...",
	"...это ловушка...",
	"...они идут за ним...",
	"...за тобой идут...",
	"...закрой двери...",
	"...всё кончено...",
	))

/datum/hallucination/psychosis/distorted_radio
	themes = list(PSYCHOSIS_THEME_WHISPERING)

/datum/hallucination/psychosis/distorted_radio/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/humans = list()
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(H == target || H.stat == DEAD || !H.mind)
			continue
		humans += H
	if(!length(humans))
		psy_log("early_out type=[type] reason=no_humans")
		qdel(src)
		return
	var/mob/living/carbon/human/source = pick(humans)
	psy_play(target, target, 'sound/effects/sparks1.ogg', 35, TRUE)
	var/fragments = pick(2, 2, 3)
	var/built = ""
	for(var/i in 1 to fragments)
		built += "[pick(GLOB.psychosis_radio_fragments)] "
	built = capitalize(trim(built))
	var/datum/language/understood_language = target.get_random_understood_language()
	var/message = target.compose_message(source, understood_language, built, "[FREQ_COMMON]", list(source.speech_span), face_name = TRUE)
	feedback_details += "Source: [source.real_name], Fragments: [built]"
	to_chat(target, message)
	qdel(src)

GLOBAL_LIST_INIT(psychosis_laughter_lines, list(
	"<span class='warning'>Вам кажется, что где-то рядом кто-то истерически смеётся.</span>",
	"<span class='warning'>Вы слышите далёкий смех, но никого не видите.</span>",
	"<span class='warning'>Смех... он становится всё ближе.</span>",
	"<span class='warning'>Кто-то хохочет, но смех быстро обрывается.</span>",
	))

/datum/hallucination/psychosis/laughter
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_CHILDREN)

/datum/hallucination/psychosis/laughter/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(GLOB.psychosis_laughter_lines))
	psy_play(target, source, pickweight(list(
		'sound/spookoween/insane_low_laugh.ogg' = 1,
		'sound/spookoween/ahaha.ogg' = 1,
		'sound/hallucinations/psychosis/laugh_minkie.ogg' = 1,
		'sound/hallucinations/psychosis/laugh_growl.ogg' = 1,
		'sound/hallucinations/psychosis/laugh_creepy.ogg' = 1,
		'sound/hallucinations/psychosis/laugh_child.ogg' = 1,
		'sound/hallucinations/psychosis/laugh_evil.ogg' = 1,
		'sound/hallucinations/psychosis/laugh_horror.ogg' = 3,
		)), 50, TRUE)
	qdel(src)

/datum/hallucination/psychosis/name_call
	themes = list(PSYCHOSIS_THEME_STALKER, PSYCHOSIS_THEME_WHISPERING)

/datum/hallucination/psychosis/name_call/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	var/named = target.first_name() || target.real_name || "ты"
	feedback_details += "Source: [source.x],[source.y],[source.z], Name: [named]"
	to_chat(target, "<span class='italics'>...[lowertext(named)]...</span>")
	psy_play(target, source, pick(
		'sound/hallucinations/im_here1.ogg',
		'sound/hallucinations/im_here2.ogg',
		'sound/hallucinations/over_here1.ogg',
		'sound/hallucinations/over_here2.ogg',
		'sound/hallucinations/over_here3.ogg',
		'sound/hallucinations/psychosis/cathedral_voice.ogg',
		'sound/hallucinations/psychosis/girl_humming.ogg',
		'sound/hallucinations/psychosis/ghost_mommy.ogg',
		), 50, TRUE)
	qdel(src)

GLOBAL_LIST_INIT(psychosis_scream_lines, list(
	"<span class='warning'>Вы отчётливо слышите далёкий крик.</span>",
	"<span class='warning'>Где-то кричат, но звук обрывается.</span>",
	"<span class='warning'>Крик, полный ужаса, доносится откуда-то издалека.</span>",
	))

/datum/hallucination/psychosis/distant_scream
	themes = list(PSYCHOSIS_THEME_MASSACRE)

/datum/hallucination/psychosis/distant_scream/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(GLOB.psychosis_scream_lines))
	psy_play(target, source, pickweight(list(
		'sound/spookoween/girlscream.ogg' = 1,
		'sound/creatures/ph_scream1.ogg' = 1,
		'sound/voice/deathgasp1.ogg' = 1,
		'sound/voice/deathgasp2.ogg' = 1,
		'sound/hallucinations/psychosis/scream.ogg' = 1,
		'sound/hallucinations/psychosis/stinger_cruel.ogg' = 1,
		'sound/hallucinations/psychosis/stinger_hit.mp3' = 3,
		)), 45, TRUE)
	qdel(src)

// Серия тиканий, постепенно учащается.
#define PSYCHOSIS_CLOCK_TICKS_MIN 6
#define PSYCHOSIS_CLOCK_TICKS_MAX 12

/datum/hallucination/psychosis/clock_ticks
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/clock_ticks/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	if(prob(35))
		psy_play(target, target, pick(
			'sound/hallucinations/psychosis/clock_slow.ogg',
			'sound/hallucinations/psychosis/clock_rhythm.ogg',
			'sound/hallucinations/psychosis/clock_echo.ogg',
			), 50, FALSE)
		feedback_details += "Loop"
		qdel(src)
		return
	var/ticks = rand(PSYCHOSIS_CLOCK_TICKS_MIN, PSYCHOSIS_CLOCK_TICKS_MAX)
	feedback_details += "Ticks: [ticks]"
	var/delay = 12
	for(var/i in 1 to ticks)
		if(QDELETED(target) || target.stat == DEAD)
			break
		psy_play(target, target, 'sound/effects/clock_tick.ogg', 50, FALSE)
		sleep(delay)
		delay = max(2, delay - 1)
	qdel(src)

#undef PSYCHOSIS_CLOCK_TICKS_MIN
#undef PSYCHOSIS_CLOCK_TICKS_MAX

// Звуки идут с разных клеток по линии - иллюзия подкрадывающихся шагов.

/datum/hallucination/psychosis/phantom_steps
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_STALKER)

/datum/hallucination/psychosis/phantom_steps/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/target_T = get_turf(target)
	if(!target_T)
		psy_log("early_out type=[type] reason=no_turf")
		qdel(src)
		return
	var/direction = pick(GLOB.cardinals)
	var/start_distance = rand(5, 7)
	var/turf/start_turf = get_ranged_target_turf(target_T, direction, start_distance)
	if(!start_turf)
		psy_log("early_out type=[type] reason=no_start_turf")
		qdel(src)
		return
	feedback_details += "Dir: [dir2text(direction)], Start: [start_turf.x],[start_turf.y]"
	var/turf/current = start_turf
	var/steps = start_distance
	for(var/i in 1 to steps)
		if(QDELETED(target) || target.stat == DEAD)
			break
		psy_play(target, current, pick(
			'sound/effects/footstep/floor1.ogg',
			'sound/effects/footstep/floor2.ogg',
			'sound/effects/footstep/floor3.ogg',
			'sound/effects/footstep/floor4.ogg',
			'sound/effects/footstep/floor5.ogg',
			), 50, FALSE)
		sleep(rand(5, 8))
		var/turf/next_turf = get_step(current, turn(direction, 180))
		if(!next_turf)
			break
		current = next_turf
	qdel(src)

GLOBAL_LIST_INIT(psychosis_chains_lines, list(
	"<span class='warning'>Откуда-то доносится звон цепей.</span>",
	"<span class='warning'>Вы слышите металлический лязг, словно где-то тащат цепь.</span>",
	"<span class='warning'>Цепи... они гремят совсем рядом.</span>",
	))

/datum/hallucination/psychosis/chains_rattle/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(GLOB.psychosis_chains_lines))
	psy_play(target, source, pickweight(list(
		'sound/spookoween/chain_rattling.ogg' = 1,
		'sound/hallucinations/psychosis/creaking_structure.ogg' = 1,
		'sound/hallucinations/psychosis/swishes.ogg' = 1,
		'sound/hallucinations/psychosis/swoosh_resonance.mp3' = 3,
		)), 50, TRUE)
	qdel(src)

GLOBAL_LIST_INIT(psychosis_alarm_lines, list(
	"<span class='warning'>Вам слышится сирена тревоги, но никто на неё не реагирует.</span>",
	"<span class='warning'>Где-то воет аварийный сигнал, но звук тут же обрывается.</span>",
	"<span class='warning'>Кажется, дальние отсеки гудят тревогой.</span>",
	))

/datum/hallucination/psychosis/horror_alarm
	themes = list(PSYCHOSIS_THEME_MACHINERY)

/datum/hallucination/psychosis/horror_alarm/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(GLOB.psychosis_alarm_lines))
	psy_play(target, source, pickweight(list(
		'sound/hallucinations/psychosis/alarm_scifi_1.ogg' = 1,
		'sound/hallucinations/psychosis/alarm_scifi_2.ogg' = 1,
		'sound/hallucinations/psychosis/alarm_scifi_3.ogg' = 1,
		'sound/hallucinations/psychosis/alarm_scifi_4.mp3' = 3,
		'sound/hallucinations/psychosis/transition_machinery.ogg' = 3,
		)), 40, TRUE)
	qdel(src)

GLOBAL_LIST_INIT(psychosis_horn_lines, list(
	"<span class='warning'>Откуда-то очень издалека доносится протяжный гудок.</span>",
	"<span class='warning'>Вы слышите гул, словно идущий из-за стен станции.</span>",
	"<span class='warning'>Низкий гудок прокатывается по отсеку и стихает.</span>",
	))

/datum/hallucination/psychosis/distant_horn/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(GLOB.psychosis_horn_lines))
	psy_play(target, source, pickweight(list(
		'sound/hallucinations/psychosis/foghorn_distant.ogg' = 1,
		'sound/hallucinations/psychosis/train_distant.ogg' = 1,
		'sound/hallucinations/psychosis/whalesong_monotron.ogg' = 1,
		'sound/hallucinations/psychosis/bass_drum.ogg' = 1,
		'sound/hallucinations/psychosis/atmosphere_dread.ogg' = 3,
		)), 50, TRUE)
	qdel(src)

// Источник - сам target, чтобы звук "шёл из черепа", а не издалека.

GLOBAL_LIST_INIT(psychosis_void_drone_lines, list(
	"<span class='warning'>В ушах нарастает глухой гул, не имеющий источника.</span>",
	"<span class='warning'>Тяжесть наваливается на затылок. Воздух будто звенит.</span>",
	"<span class='warning'>В голове встаёт мутная пелена, и где-то на самой границе слышимости тянется низкая нота.</span>",
	"<span class='warning'>Реальность как будто отодвигается на полшага. Слух заполняет монотонный фон.</span>",
	))

/datum/hallucination/psychosis/void_drone/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	to_chat(target, pick(GLOB.psychosis_void_drone_lines))
	psy_play(target, target, pickweight(list(
		'sound/hallucinations/psychosis/ambient_atmosphere.ogg' = 1,
		'sound/hallucinations/psychosis/ambient_noise.ogg' = 1,
		'sound/hallucinations/psychosis/ambient_horror.ogg' = 3,
		'sound/hallucinations/psychosis/undercurrent_dark.ogg' = 3,
		)), 50, FALSE)
	qdel(src)

// Звуковые фантомы: звук + при необходимости короткая курсивная строка.
// Никаких изображений, никаких задержек длиннее десятка секунд.

/datum/hallucination/psychosis/phantom_door
	themes = list(PSYCHOSIS_THEME_MACHINERY)

/datum/hallucination/psychosis/phantom_door/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(
		"<span class='warning'>Где-то в глубине отсеков снова и снова циклирует шлюз.</span>",
		"<span class='warning'>Слышится далёкий шум открывающейся двери, но никто не входит.</span>",
		"<span class='warning'>Откуда-то с пустых коридоров доносится скрежет двери.</span>",
		))
	psy_play(target, source, pick(
		'sound/machines/airlock.ogg',
		'sound/machines/AirlockClose.ogg',
		'sound/machines/AirlockOpen.ogg',
		'sound/machines/airlockforced.ogg',
		'sound/effects/doorcreaky.ogg',
		), 50, TRUE)
	qdel(src)

// Источник - близкая клетка, чтобы было ощущение "над плечом".

/datum/hallucination/psychosis/phantom_typing
	themes = list(PSYCHOSIS_THEME_MACHINERY)

/datum/hallucination/psychosis/phantom_typing/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/candidates = list()
	for(var/turf/T in orange(2, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/source = pick(candidates)
	feedback_details += "Source: [source.x],[source.y]"
	if(prob(50))
		to_chat(target, "<span class='warning'>Совсем рядом стучат клавиши, но за консолью никого нет.</span>")
	var/clicks = rand(6, 11)
	for(var/i in 1 to clicks)
		if(QDELETED(target) || target.stat == DEAD)
			break
		psy_play(target, source, pick(
			'sound/machines/click.ogg',
			'sound/machines/button.ogg',
			'sound/machines/button1.ogg',
			'sound/machines/button2.ogg',
			'sound/machines/button3.ogg',
			), 50, TRUE)
		sleep(rand(2, 5))
	qdel(src)

/datum/hallucination/psychosis/phantom_flatline
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MACHINERY)

/datum/hallucination/psychosis/phantom_flatline/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(
		"<span class='warning'>Издалека доносится ровный писк медицинского монитора.</span>",
		"<span class='warning'>Где-то медмонитор переходит в тон флатлайна.</span>",
		))
	var/beeps = rand(3, 5)
	for(var/i in 1 to beeps)
		if(QDELETED(target) || target.stat == DEAD)
			break
		psy_play(target, source, 'sound/machines/twobeep_high.ogg', 50, FALSE)
		sleep(rand(8, 14))
	if(!QDELETED(target) && target.stat != DEAD)
		psy_play(target, source, 'sound/machines/defib_failed.ogg', 50, FALSE)
	qdel(src)

/datum/hallucination/psychosis/phantom_gunshot
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)

/datum/hallucination/psychosis/phantom_gunshot/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(
		"<span class='warning'>Где-то далеко гремит одиночный выстрел.</span>",
		"<span class='warning'>Сквозь стены слышится глухой хлопок выстрела.</span>",
		"<span class='warning'>Откуда-то издалека прокатывается приглушённый выстрел.</span>",
		))
	psy_play(target, source, pick(
		'sound/weapons/gun/pistol/shot.ogg',
		'sound/weapons/gun/pistol/shot_alt.ogg',
		'sound/weapons/gun/pistol/shot_suppressed.ogg',
		), 32, TRUE)
	qdel(src)

/datum/hallucination/psychosis/phantom_bone_crack
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)

/datum/hallucination/psychosis/phantom_bone_crack/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/target_T = get_turf(target)
	if(!target_T)
		psy_log("early_out type=[type] reason=no_turf")
		qdel(src)
		return
	feedback_details += "Source: self"
	to_chat(target, pick(
		"<span class='warning'>Совсем рядом раздаётся мерзкий хруст.</span>",
		"<span class='warning'>Что-то с противным хрустом ломается у вас за спиной.</span>",
		"<span class='warning'>В тишине отчётливо хрустит кость.</span>",
		))
	psy_play(target, target_T, pick(
		'sound/effects/snap.ogg',
		'sound/effects/snap01.ogg',
		), 32, TRUE)
	qdel(src)

// Шорох движется к target по линии, имитируя, что кого-то тащат вдоль коридора.

/datum/hallucination/psychosis/phantom_drag
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)

/datum/hallucination/psychosis/phantom_drag/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/target_T = get_turf(target)
	if(!target_T)
		psy_log("early_out type=[type] reason=no_turf")
		qdel(src)
		return
	var/direction = pick(GLOB.cardinals)
	var/start_distance = rand(4, 6)
	var/turf/start_turf = get_ranged_target_turf(target_T, direction, start_distance)
	if(!start_turf)
		psy_log("early_out type=[type] reason=no_start_turf")
		qdel(src)
		return
	feedback_details += "Dir: [dir2text(direction)], Start: [start_turf.x],[start_turf.y]"
	to_chat(target, pick(
		"<span class='warning'>По полу что-то медленно волокут совсем рядом.</span>",
		"<span class='warning'>Слышится противный шорох - будто тело тянут по плитке.</span>",
		))
	var/turf/current = start_turf
	for(var/i in 1 to start_distance)
		if(QDELETED(target) || target.stat == DEAD)
			break
		psy_play(target, current, pick(
			'sound/effects/rustle1.ogg',
			'sound/effects/rustle2.ogg',
			'sound/effects/rustle3.ogg',
			'sound/effects/rustle4.ogg',
			'sound/effects/rustle5.ogg',
			), 50, FALSE)
		sleep(rand(7, 12))
		var/turf/next_turf = get_step(current, turn(direction, 180))
		if(!next_turf)
			break
		current = next_turf
	qdel(src)

/datum/hallucination/psychosis/phantom_chant
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_RITUAL)

/datum/hallucination/psychosis/phantom_chant/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(
		"<span class='warning'>Где-то на станции тихо тянут песнопение без слов.</span>",
		"<span class='warning'>Сквозь стены доносится монотонное чтение нараспев.</span>",
		"<span class='warning'>Откуда-то очень издалека слышится женский хорал.</span>",
		))
	psy_play(target, source, pickweight(list(
		'sound/hallucinations/psychosis/whisper_spells.ogg' = 1,
		'sound/hallucinations/psychosis/whisper_vocal.ogg' = 1,
		'sound/hallucinations/psychosis/cathedral_voice.ogg' = 1,
		'sound/hallucinations/psychosis/girl_humming.ogg' = 1,
		'sound/hallucinations/psychosis/bell_creepy.ogg' = 3,
		'sound/hallucinations/psychosis/buildup_coven.ogg' = 3,
		)), 50, TRUE)
	qdel(src)

/datum/hallucination/psychosis/phantom_baby_cry
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_CHILDREN)

/datum/hallucination/psychosis/phantom_baby_cry/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/source = random_far_turf()
	if(!source)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [source.x],[source.y],[source.z]"
	to_chat(target, pick(
		"<span class='warning'>Где-то поблизости плачет ребёнок.</span>",
		"<span class='warning'>Сквозь стену доносится детский плач, но рядом не должно быть детей.</span>",
		"<span class='warning'>Тихий, надрывный плач прокатывается по коридору и тут же стихает.</span>",
		))
	psy_play(target, source, pick(
		'sound/voice/female_cry1.ogg',
		'sound/voice/female_cry2.ogg',
		'sound/voice/light_weight_baby.ogg',
		'sound/hallucinations/psychosis/ghost_mommy.ogg',
		'sound/hallucinations/psychosis/laugh_child.ogg',
		), 32, TRUE)
	qdel(src)

// Похоже на phantom_steps, но "толпа" - много шагов в ряд, без приближения.

/datum/hallucination/psychosis/phantom_marching
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/phantom_marching/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/target_T = get_turf(target)
	if(!target_T)
		psy_log("early_out type=[type] reason=no_turf")
		qdel(src)
		return
	var/direction = pick(GLOB.cardinals)
	var/distance = rand(5, 8)
	var/turf/source = get_ranged_target_turf(target_T, direction, distance)
	if(!source)
		psy_log("early_out type=[type] reason=no_source_turf")
		qdel(src)
		return
	feedback_details += "Dir: [dir2text(direction)], Source: [source.x],[source.y]"
	to_chat(target, pick(
		"<span class='warning'>Откуда-то доносится размеренный топот множества ног.</span>",
		"<span class='warning'>За стеной как будто маршем идёт целое подразделение.</span>",
		))
	var/stomps = rand(7, 12)
	for(var/i in 1 to stomps)
		if(QDELETED(target) || target.stat == DEAD)
			break
		psy_play(target, source, pick(
			'sound/effects/footstep/floor1.ogg',
			'sound/effects/footstep/floor2.ogg',
			'sound/effects/footstep/floor3.ogg',
			'sound/effects/footstep/floor4.ogg',
			'sound/effects/footstep/floor5.ogg',
			), 50, FALSE)
		sleep(rand(4, 6))
	qdel(src)

// Визуальные галлюцинации: 1+ /obj/effect/hallucination/simple, видимые только
// target через target.client.images. Никакой механики, никаких блокировок
// движения - только визуальный декор на 2-8 секунд.

/obj/effect/hallucination/simple/psychosis_husk_floor
	name = "силуэт"
	image_icon = 'icons/mob/human.dmi'
	image_state = "husk"
	col_mod = "#0a0a0a"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_skeleton
	name = "кости"
	image_icon = 'icons/mob/human.dmi'
	image_state = "husk"
	col_mod = "#cfc8b8"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_gib
	name = "ошмётки"
	image_icon = 'icons/effects/blood.dmi'
	image_state = "gib1_guts"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_severed_hand
	name = "оторванная рука"
	image_icon = 'icons/effects/blood.dmi'
	image_state = "gibarm_flesh"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_severed_head
	name = "голова"
	image_icon = 'icons/effects/blood.dmi'
	image_state = "gibhead_flesh"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_footprint
	name = "кровавый след"
	image_icon = 'icons/effects/blood.dmi'
	image_state = "bloodyfeet"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_blood_floor
	name = "кровавая лужа"
	image_icon = 'icons/effects/blood.dmi'
	image_state = "floor1"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_ash
	name = "пепел"
	image_icon = 'icons/obj/objects.dmi'
	image_state = "big_ash"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_plush
	name = "плюшевая игрушка"
	image_icon = 'icons/obj/plushes.dmi'
	image_state = "narplush"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_headpike
	name = "голова на пике"
	image_icon = 'icons/obj/structures.dmi'
	image_state = "headpike-bone"
	image_layer = MOB_LAYER

/obj/effect/hallucination/simple/psychosis_rune
	name = "руна"
	image_icon = 'icons/effects/cult_effects.dmi'
	image_state = "bloodsparkles"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_scorch
	name = "обугленный пол"
	image_icon = 'icons/effects/effects.dmi'
	image_state = "scorch"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_drip
	name = "капли"
	image_icon = 'icons/effects/blood.dmi'
	image_state = "floor1"
	image_layer = LOW_OBJ_LAYER

/obj/effect/hallucination/simple/psychosis_sparks
	name = "искры"
	image_icon = 'icons/effects/effects.dmi'
	image_state = "sparks"
	image_layer = MOB_LAYER

/obj/effect/hallucination/simple/psychosis_xeno_static
	name = "силуэт"
	image_icon = 'icons/Xeno/castes/hunter.dmi'
	image_state = "Hunter Walking"
	col_mod = "#1a1a1a"
	image_layer = MOB_LAYER

/obj/effect/hallucination/simple/psychosis_cobweb
	name = "паутина"
	image_icon = 'icons/effects/effects.dmi'
	image_state = "cobweb1"
	image_layer = LOW_OBJ_LAYER

/datum/hallucination/psychosis/phantom_corpse
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/obj/effect/hallucination/simple/psychosis_husk_floor/body

/datum/hallucination/psychosis/phantom_corpse/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(2, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	body = new(spawn_turf, target)
	psy_log_visual(body, target, "phantom_corpse")
	body.setDir(pick(GLOB.cardinals))
	QDEL_IN(src, rand(40, 70))

/datum/hallucination/psychosis/phantom_corpse/Destroy()
	QDEL_NULL(body)
	return ..()

/datum/hallucination/psychosis/shadow_swarm
	severity = PSYCHOSIS_TIER_SEVERE
	var/list/figures = list()

/datum/hallucination/psychosis/shadow_swarm/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/count = rand(3, 5)
	for(var/i in 1 to count)
		var/turf/spawn_turf = random_far_view_turf()
		if(!spawn_turf)
			continue
		var/obj/effect/hallucination/simple/shadow/F = new(spawn_turf, target)
		psy_log_visual(F, target, "shadow_swarm")
		F.setDir(pick(GLOB.cardinals))
		figures += F
	if(!length(figures))
		psy_log("early_out type=[type] reason=no_figures")
		qdel(src)
		return
	feedback_details += "Count: [length(figures)]"
	QDEL_IN(src, rand(30, 60))

/datum/hallucination/psychosis/shadow_swarm/Destroy()
	QDEL_LIST(figures)
	return ..()

/datum/hallucination/psychosis/red_eyes
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/obj/effect/hallucination/simple/eyes/eyes_obj

/obj/effect/hallucination/simple/eyes
	name = "красные глаза"
	image_icon = 'icons/effects/effects.dmi'
	image_state = "light"
	col_mod = "#ff0000"
	image_layer = MOB_LAYER

/datum/hallucination/psychosis/red_eyes/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/spawn_turf = random_far_view_turf()
	if(!spawn_turf)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	eyes_obj = new(spawn_turf, target)
	psy_log_visual(eyes_obj, target, "red_eyes")
	if(prob(50))
		to_chat(target, "<span class='warning'>Из тёмного угла на вас смотрят два красных огонька.</span>")
	QDEL_IN(src, rand(25, 45))

/datum/hallucination/psychosis/red_eyes/Destroy()
	QDEL_NULL(eyes_obj)
	return ..()

// Силуэт на полу у самой стены - иллюзия проступающего сквозь стену лица.

/datum/hallucination/psychosis/wall_face
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/obj/effect/hallucination/simple/psychosis_husk_floor/face

/datum/hallucination/psychosis/wall_face/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/dir in GLOB.cardinals)
		var/turf/T = get_step(target, dir)
		if(!T)
			continue
		var/turf/behind = get_step(T, dir)
		if(behind && behind.density)
			candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_wall_adjacent")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	face = new(spawn_turf, target)
	psy_log_visual(face, target, "wall_face")
	face.setDir(get_dir(spawn_turf, target))
	if(prob(40))
		to_chat(target, "<span class='warning'>Сквозь стену проступает чьё-то лицо.</span>")
	QDEL_IN(src, rand(25, 45))

/datum/hallucination/psychosis/wall_face/Destroy()
	QDEL_NULL(face)
	return ..()

/datum/hallucination/psychosis/phantom_skeleton
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_RITUAL)
	var/obj/effect/hallucination/simple/psychosis_skeleton/bones

/datum/hallucination/psychosis/phantom_skeleton/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	bones = new(spawn_turf, target)
	psy_log_visual(bones, target, "phantom_skeleton")
	bones.setDir(pick(GLOB.cardinals))
	QDEL_IN(src, rand(40, 70))

/datum/hallucination/psychosis/phantom_skeleton/Destroy()
	QDEL_NULL(bones)
	return ..()

/datum/hallucination/psychosis/phantom_severed_hand
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/obj/effect/hallucination/simple/psychosis_severed_hand/hand

/datum/hallucination/psychosis/phantom_severed_hand/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(2, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	hand = new(spawn_turf, target)
	psy_log_visual(hand, target, "phantom_severed_hand")
	hand.setDir(pick(GLOB.cardinals))
	QDEL_IN(src, rand(25, 50))

/datum/hallucination/psychosis/phantom_severed_hand/Destroy()
	QDEL_NULL(hand)
	return ..()

/datum/hallucination/psychosis/phantom_severed_head
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/obj/effect/hallucination/simple/psychosis_severed_head/head

/datum/hallucination/psychosis/phantom_severed_head/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(2, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	head = new(spawn_turf, target)
	psy_log_visual(head, target, "phantom_severed_head")
	head.setDir(pick(GLOB.cardinals))
	QDEL_IN(src, rand(25, 50))

/datum/hallucination/psychosis/phantom_severed_head/Destroy()
	QDEL_NULL(head)
	return ..()

/datum/hallucination/psychosis/phantom_guts
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/obj/effect/hallucination/simple/psychosis_gib/guts

/datum/hallucination/psychosis/phantom_guts/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	guts = new(spawn_turf, target)
	psy_log_visual(guts, target, "phantom_guts")
	guts.image_state = pick("gib1_guts","gib2_guts","gib3_guts","gib5_guts","gibmid2_guts","gibmid3_guts")
	guts.Show()
	QDEL_IN(src, rand(25, 50))

/datum/hallucination/psychosis/phantom_guts/Destroy()
	QDEL_NULL(guts)
	return ..()

// Цепочка следов вдоль одного направления - будто кто-то ушёл, оставляя кровь.

/datum/hallucination/psychosis/bloody_footprints
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/list/prints = list()

/datum/hallucination/psychosis/bloody_footprints/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/target_T = get_turf(target)
	if(!target_T)
		psy_log("early_out type=[type] reason=no_turf")
		qdel(src)
		return
	var/direction = pick(GLOB.cardinals)
	var/length_steps = rand(3, 5)
	var/turf/current = get_step(target_T, direction)
	for(var/i in 1 to length_steps)
		if(!current || current.density)
			break
		var/obj/effect/hallucination/simple/psychosis_footprint/P = new(current, target)
		psy_log_visual(P, target, "bloody_footprints")
		P.image_state = pick("bloodyfeet","bloodyfeet_left","bloodyfeet_right")
		P.setDir(direction)
		P.Show()
		prints += P
		current = get_step(current, direction)
	if(!length(prints))
		psy_log("early_out type=[type] reason=no_prints_placed")
		qdel(src)
		return
	feedback_details += "Dir: [dir2text(direction)], Prints: [length(prints)]"
	QDEL_IN(src, rand(40, 70))

/datum/hallucination/psychosis/bloody_footprints/Destroy()
	QDEL_LIST(prints)
	return ..()

/datum/hallucination/psychosis/phantom_blood_pool
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/list/pool = list()

/datum/hallucination/psychosis/phantom_blood_pool/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(2, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/center = pick(candidates)
	var/obj/effect/hallucination/simple/psychosis_blood_floor/main = new(center, target)
	psy_log_visual(main, target, "phantom_blood_pool")
	main.image_state = pick("floor1","floor2","floor3","floor4","floor5","floor6","floor7")
	main.Show()
	pool += main
	for(var/dir in GLOB.cardinals)
		if(prob(55))
			var/turf/T = get_step(center, dir)
			if(!T || T.density)
				continue
			var/obj/effect/hallucination/simple/psychosis_blood_floor/extra = new(T, target)
			extra.image_state = pick("floor1","floor2","floor3","floor4","floor5","floor6","floor7")
			extra.Show()
			pool += extra
	feedback_details += "Source: [center.x],[center.y], Tiles: [length(pool)]"
	QDEL_IN(src, rand(45, 80))

/datum/hallucination/psychosis/phantom_blood_pool/Destroy()
	QDEL_LIST(pool)
	return ..()

// Пепел с тёмным силуэтом-наложением - как будто человек сгорел на этом месте.

/datum/hallucination/psychosis/phantom_ash_silhouette
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_RITUAL)
	var/obj/effect/hallucination/simple/psychosis_ash/ash
	var/obj/effect/hallucination/simple/psychosis_husk_floor/imprint

/datum/hallucination/psychosis/phantom_ash_silhouette/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	ash = new(spawn_turf, target)
	psy_log_visual(ash, target, "phantom_ash_silhouette")
	imprint = new(spawn_turf, target)
	imprint.setDir(pick(GLOB.cardinals))
	QDEL_IN(src, rand(40, 70))

/datum/hallucination/psychosis/phantom_ash_silhouette/Destroy()
	QDEL_NULL(ash)
	QDEL_NULL(imprint)
	return ..()

/datum/hallucination/psychosis/phantom_plush
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_CHILDREN, PSYCHOSIS_THEME_RITUAL)
	var/obj/effect/hallucination/simple/psychosis_plush/plush

/datum/hallucination/psychosis/phantom_plush/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	plush = new(spawn_turf, target)
	psy_log_visual(plush, target, "phantom_plush")
	plush.image_state = pick("narplush","carpplush","bubbleplush","plushie_synth","plushie_mal0","bloody_miner_plushie")
	plush.setDir(get_dir(spawn_turf, target))
	plush.Show()
	if(prob(35))
		to_chat(target, "<span class='warning'>Кажется, плюшевая игрушка повернулась к вам.</span>")
	QDEL_IN(src, rand(30, 55))

/datum/hallucination/psychosis/phantom_plush/Destroy()
	QDEL_NULL(plush)
	return ..()

/datum/hallucination/psychosis/phantom_head_on_pike
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_RITUAL)
	var/obj/effect/hallucination/simple/psychosis_headpike/pike

/datum/hallucination/psychosis/phantom_head_on_pike/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/spawn_turf = random_far_view_turf()
	if(!spawn_turf)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	pike = new(spawn_turf, target)
	psy_log_visual(pike, target, "phantom_head_on_pike")
	to_chat(target, "<span class='warning'>Вдалеке на пике торчит окровавленная голова.</span>")
	QDEL_IN(src, rand(30, 55))

/datum/hallucination/psychosis/phantom_head_on_pike/Destroy()
	QDEL_NULL(pike)
	return ..()

/datum/hallucination/psychosis/phantom_rune
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_RITUAL)
	var/obj/effect/hallucination/simple/psychosis_rune/rune

/datum/hallucination/psychosis/phantom_rune/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	rune = new(spawn_turf, target)
	psy_log_visual(rune, target, "phantom_rune")
	if(prob(40))
		to_chat(target, "<span class='warning'>На полу проступает кровавый знак.</span>")
	QDEL_IN(src, rand(30, 55))

/datum/hallucination/psychosis/phantom_rune/Destroy()
	QDEL_NULL(rune)
	return ..()

// Один и тот же simple-объект двигается forceMove'ом, на каждом шаге Moved()
// вызывает Show() и образ обновляется.

/datum/hallucination/psychosis/phantom_runner
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/obj/effect/hallucination/simple/shadow/runner

/datum/hallucination/psychosis/phantom_runner/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/target_T = get_turf(target)
	if(!target_T)
		psy_log("early_out type=[type] reason=no_turf")
		qdel(src)
		return
	var/direction = pick(GLOB.cardinals)
	var/perpendicular = turn(direction, 90)
	var/offset = rand(2, 4)
	var/length_steps = rand(6, 8)
	var/turf/start = get_ranged_target_turf(target_T, direction, CEILING(length_steps / 2, 1))
	start = get_ranged_target_turf(start, perpendicular, offset)
	if(!start)
		psy_log("early_out type=[type] reason=no_start_turf")
		qdel(src)
		return
	runner = new(start, target)
	psy_log_visual(runner, target, "phantom_runner")
	runner.setDir(turn(direction, 180))
	feedback_details += "Dir: [dir2text(direction)], Start: [start.x],[start.y]"
	var/turf/current = start
	for(var/i in 1 to length_steps)
		if(QDELETED(target) || target.stat == DEAD || QDELETED(runner))
			break
		var/turf/next_turf = get_step(current, turn(direction, 180))
		if(!next_turf)
			break
		runner.forceMove(next_turf)
		current = next_turf
		sleep(rand(2, 3))
	qdel(src)

/datum/hallucination/psychosis/phantom_runner/Destroy()
	QDEL_NULL(runner)
	return ..()

/datum/hallucination/psychosis/phantom_crawler
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/obj/effect/hallucination/simple/psychosis_husk_floor/crawler

/datum/hallucination/psychosis/phantom_crawler/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/target_T = get_turf(target)
	if(!target_T)
		psy_log("early_out type=[type] reason=no_turf")
		qdel(src)
		return
	var/direction = pick(GLOB.cardinals)
	var/start_distance = rand(4, 6)
	var/turf/start = get_ranged_target_turf(target_T, direction, start_distance)
	if(!start)
		psy_log("early_out type=[type] reason=no_start_turf")
		qdel(src)
		return
	crawler = new(start, target)
	psy_log_visual(crawler, target, "phantom_crawler")
	crawler.setDir(turn(direction, 180))
	feedback_details += "Dir: [dir2text(direction)]"
	if(prob(35))
		to_chat(target, "<span class='warning'>По полу что-то медленно ползёт в вашу сторону.</span>")
	var/turf/current = start
	for(var/i in 1 to start_distance - 1)
		if(QDELETED(target) || target.stat == DEAD || QDELETED(crawler))
			break
		var/turf/next_turf = get_step(current, turn(direction, 180))
		if(!next_turf)
			break
		crawler.forceMove(next_turf)
		current = next_turf
		sleep(rand(10, 16))
	QDEL_IN(src, rand(10, 20))

/datum/hallucination/psychosis/phantom_crawler/Destroy()
	QDEL_NULL(crawler)
	return ..()

/datum/hallucination/psychosis/phantom_doppelganger
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/obj/effect/hallucination/simple/psychosis_husk_floor/twin

/datum/hallucination/psychosis/phantom_doppelganger/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(4, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	twin = new(spawn_turf, target)
	psy_log_visual(twin, target, "phantom_doppelganger")
	twin.image_layer = MOB_LAYER
	twin.col_mod = "#202020"
	twin.Show()
	twin.setDir(get_dir(spawn_turf, target))
	to_chat(target, "<span class='warning'>Кто-то очень похожий на вас стоит неподалёку и смотрит.</span>")
	QDEL_IN(src, rand(25, 45))

/datum/hallucination/psychosis/phantom_doppelganger/Destroy()
	QDEL_NULL(twin)
	return ..()

/datum/hallucination/psychosis/phantom_scorch
	severity = PSYCHOSIS_TIER_MODERATE
	var/obj/effect/hallucination/simple/psychosis_scorch/scorch

/datum/hallucination/psychosis/phantom_scorch/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	scorch = new(spawn_turf, target)
	psy_log_visual(scorch, target, "phantom_scorch")
	scorch.image_state = pick("scorch","light_scorch")
	scorch.Show()
	QDEL_IN(src, rand(40, 70))

/datum/hallucination/psychosis/phantom_scorch/Destroy()
	QDEL_NULL(scorch)
	return ..()

/datum/hallucination/psychosis/phantom_blood_drip
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/list/drops = list()

/datum/hallucination/psychosis/phantom_blood_drip/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(2, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	feedback_details += "Drops: pending"
	var/count = rand(2, 4)
	for(var/i in 1 to count)
		if(QDELETED(target) || target.stat == DEAD)
			break
		if(!length(candidates))
			break
		var/turf/spawn_turf = pick_n_take(candidates)
		var/obj/effect/hallucination/simple/psychosis_drip/D = new(spawn_turf, target)
		psy_log_visual(D, target, "phantom_blood_drip")
		D.image_state = pick("floor1","floor2","floor3")
		D.Show()
		drops += D
		psy_play(target, spawn_turf, 'sound/effects/splat.ogg', 50, FALSE)
		sleep(rand(6, 10))
	QDEL_IN(src, rand(35, 60))

/datum/hallucination/psychosis/phantom_blood_drip/Destroy()
	QDEL_LIST(drops)
	return ..()

/datum/hallucination/psychosis/phantom_sparks
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MACHINERY)
	var/obj/effect/hallucination/simple/psychosis_sparks/sparks

/datum/hallucination/psychosis/phantom_sparks/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/spawn_turf = random_far_view_turf()
	if(!spawn_turf)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	sparks = new(spawn_turf, target)
	psy_log_visual(sparks, target, "phantom_sparks")
	psy_play(target, spawn_turf, 'sound/effects/sparks1.ogg', 50, TRUE)
	QDEL_IN(src, 12)

/datum/hallucination/psychosis/phantom_sparks/Destroy()
	QDEL_NULL(sparks)
	return ..()

/datum/hallucination/psychosis/phantom_xeno_silhouette
	severity = PSYCHOSIS_TIER_SEVERE
	var/obj/effect/hallucination/simple/psychosis_xeno_static/xeno

/datum/hallucination/psychosis/phantom_xeno_silhouette/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/turf/spawn_turf = random_far_view_turf()
	if(!spawn_turf)
		psy_log("early_out type=[type] reason=no_far_turf")
		qdel(src)
		return
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	xeno = new(spawn_turf, target)
	psy_log_visual(xeno, target, "phantom_xeno_silhouette")
	xeno.setDir(get_dir(spawn_turf, target))
	if(prob(40))
		to_chat(target, "<span class='warning'>В тёмном проёме застыло что-то отдалённо похожее на ксеноморфа.</span>")
	QDEL_IN(src, rand(25, 45))

/datum/hallucination/psychosis/phantom_xeno_silhouette/Destroy()
	QDEL_NULL(xeno)
	return ..()

// Уникальная категория фуллскрина, чтобы не сбить активные оверлеи игрока.

/datum/hallucination/psychosis/darken_pulse
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/darken_pulse/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	if(prob(30))
		to_chat(target, "<span class='warning'>На мгновение всё вокруг как будто гаснет.</span>")
	target.overlay_fullscreen("psychosis_dark", /atom/movable/screen/fullscreen/scaled/curse, 2)
	sleep(rand(8, 16))
	if(!QDELETED(target))
		target.clear_fullscreen("psychosis_dark", 15)
	qdel(src)

/datum/hallucination/psychosis/blur_pulse
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/blur_pulse/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	if(prob(30))
		to_chat(target, "<span class='warning'>Зрение на мгновение расплывается.</span>")
	target.overlay_fullscreen("psychosis_blur", /atom/movable/screen/fullscreen/tiled/blurry)
	sleep(rand(10, 18))
	if(!QDELETED(target))
		target.clear_fullscreen("psychosis_blur", 15)
	qdel(src)

/datum/hallucination/psychosis/static_flash
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/static_flash/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	target.overlay_fullscreen("psychosis_static", /atom/movable/screen/fullscreen/tiled/flash/static)
	psy_play(target, target, 'sound/effects/sparks1.ogg', 20, TRUE)
	sleep(rand(4, 8))
	if(!QDELETED(target))
		target.clear_fullscreen("psychosis_static", 6)
	qdel(src)

/datum/hallucination/psychosis/red_vision_pulse
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/red_vision_pulse/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	if(prob(35))
		to_chat(target, "<span class='warning'>Перед глазами на секунду мелькает багровая пелена.</span>")
	target.overlay_fullscreen("psychosis_red", /atom/movable/screen/fullscreen/tiled/color_vision/red)
	sleep(rand(6, 12))
	if(!QDELETED(target))
		target.clear_fullscreen("psychosis_red", 8)
	qdel(src)

/datum/hallucination/psychosis/phantom_cobweb
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_RITUAL)
	var/obj/effect/hallucination/simple/psychosis_cobweb/web

/datum/hallucination/psychosis/phantom_cobweb/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/turf/candidates = list()
	for(var/turf/open/T in view(3, target))
		if(T == get_turf(target))
			continue
		candidates += T
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/turf/spawn_turf = pick(candidates)
	feedback_details += "Source: [spawn_turf.x],[spawn_turf.y]"
	web = new(spawn_turf, target)
	psy_log_visual(web, target, "phantom_cobweb")
	web.image_state = pick("cobweb1","cobweb2","stickyweb1","stickyweb2")
	web.Show()
	QDEL_IN(src, rand(40, 70))

/datum/hallucination/psychosis/phantom_cobweb/Destroy()
	QDEL_NULL(web)
	return ..()

// Сенсорные / телесные галлюцинации: только текст плюс при необходимости очень
// тихий локальный звук. Не сдвигают камеру, не блокируют движение - это самые
// дешёвые "тиковые" эффекты, которые поддерживают фоновое ощущение неуютности.

GLOBAL_LIST_INIT(psychosis_crawling_lines, list(
	"<span class='warning'>Что-то едва ощутимо ползёт у вас под кожей.</span>",
	"<span class='warning'>По спине пробегает покалывание, будто вас касаются чьи-то пальцы.</span>",
	"<span class='warning'>Кожа на затылке начинает противно зудеть.</span>",
	"<span class='warning'>Внутри предплечий как будто что-то шевелится.</span>",
	))

/datum/hallucination/psychosis/crawling_skin/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	to_chat(target, pick(GLOB.psychosis_crawling_lines))
	qdel(src)

GLOBAL_LIST_INIT(psychosis_smell_lines, list(
	"<span class='warning'>Вы чувствуете отчётливый запах гари.</span>",
	"<span class='warning'>В воздухе мелькает запах крови.</span>",
	"<span class='warning'>Вам ударяет в нос запах гниющего мяса.</span>",
	"<span class='warning'>Пахнет озоном и горячим металлом, но рядом ничего не искрит.</span>",
	"<span class='warning'>Вас обдаёт сладковатым трупным запахом.</span>",
	"<span class='warning'>В воздухе виснет запах ладана и пыли.</span>",
	))

/datum/hallucination/psychosis/phantom_smell/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	to_chat(target, pick(GLOB.psychosis_smell_lines))
	qdel(src)

GLOBAL_LIST_INIT(psychosis_taste_lines, list(
	"<span class='warning'>Во рту появляется отчётливый привкус меди.</span>",
	"<span class='warning'>На языке - горький привкус пепла.</span>",
	"<span class='warning'>Слюна вдруг становится солёной.</span>",
	"<span class='warning'>Привкус железа во рту никак не пропадает.</span>",
	"<span class='warning'>Вы чувствуете на языке что-то склизкое, чего там быть не должно.</span>",
	))

/datum/hallucination/psychosis/phantom_taste/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	to_chat(target, pick(GLOB.psychosis_taste_lines))
	qdel(src)

GLOBAL_LIST_INIT(psychosis_touch_lines, list(
	"<span class='warning'>На ваше плечо ложится холодная ладонь и тут же исчезает.</span>",
	"<span class='warning'>Что-то ледяное скользит между лопатками.</span>",
	"<span class='warning'>Чьи-то холодные пальцы на мгновение касаются вашей шеи.</span>",
	"<span class='warning'>Вы чувствуете на щеке чужое дыхание.</span>",
	))

/datum/hallucination/psychosis/cold_touch
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_STALKER)

/datum/hallucination/psychosis/cold_touch/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	to_chat(target, pick(GLOB.psychosis_touch_lines))
	psy_play(target, target, pick(
		'sound/hallucinations/psychosis/breath_ghostly.ogg',
		'sound/hallucinations/psychosis/breath_ominous.ogg',
		), 50, FALSE)
	qdel(src)

GLOBAL_LIST_INIT(psychosis_memory_lines, list(
	"<span class='italics'>...вы вдруг вспоминаете лицо, которое не должны были помнить...</span>",
	"<span class='italics'>...в голове мелькает обрывок какой-то ссоры, давно не вашей...</span>",
	"<span class='italics'>...вы отчётливо вспоминаете чей-то крик, но не знаете, чей...</span>",
	"<span class='italics'>...перед глазами проходит чужой коридор, по которому вы никогда не шли...</span>",
	"<span class='italics'>...вы вспоминаете, как держали в руках что-то тяжёлое и тёплое... только это были не ваши руки...</span>",
	))

/datum/hallucination/psychosis/memory_flash
	themes = list(PSYCHOSIS_THEME_WHISPERING)

/datum/hallucination/psychosis/memory_flash/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	to_chat(target, pick(GLOB.psychosis_memory_lines))
	psy_play(target, target, 'sound/hallucinations/psychosis/buildup_memories.ogg', 50, FALSE)
	qdel(src)

// Ментальные интрузии.

GLOBAL_LIST_INIT(psychosis_inner_voice_lines, list(
	"<span class='italics'>...не дай им подойти ближе...</span>",
	"<span class='italics'>...их слишком много...</span>",
	"<span class='italics'>...закрой глаза, и они уйдут...</span>",
	"<span class='italics'>...ты ведь знаешь, что они врут...</span>",
	"<span class='italics'>...они тебя не отпустят...</span>",
	"<span class='italics'>...им нельзя верить...</span>",
	"<span class='italics'>...беги, пока не поздно...</span>",
	"<span class='italics'>...ты не должен был это видеть...</span>",
	"<span class='italics'>...это всё уже было...</span>",
	"<span class='italics'>...ты здесь не один...</span>",
	))

/datum/hallucination/psychosis/inner_voice
	themes = list(PSYCHOSIS_THEME_WHISPERING)

/datum/hallucination/psychosis/inner_voice/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/line = pick(GLOB.psychosis_inner_voice_lines)
	feedback_details += "Voice: [line]"
	to_chat(target, line)
	qdel(src)

// Намеренно никакой развязки после "одного" - просто тишина.

/datum/hallucination/psychosis/countdown
	severity = PSYCHOSIS_TIER_MODERATE

/datum/hallucination/psychosis/countdown/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	feedback_details += "Source: self"
	var/list/sequence = list("...пять...", "...четыре...", "...три...", "...два...", "...один...")
	var/start_index = pick(1, 2, 3)
	var/delay = 16
	for(var/i in start_index to length(sequence))
		if(QDELETED(target) || target.stat == DEAD)
			break
		to_chat(target, "<span class='italics'>[sequence[i]]</span>")
		psy_play(target, target, 'sound/effects/clock_tick.ogg', 50, FALSE)
		sleep(delay)
		delay = max(6, delay - 2)
	if(!QDELETED(target) && target.stat != DEAD)
		to_chat(target, "<span class='italics'>...</span>")
	qdel(src)

// Берёт кешированную последнюю реплику owner'а из status_effect; если кеша
// нет - выдаёт generic fallback из локального списка.

/datum/hallucination/psychosis/echo_self
	severity = PSYCHOSIS_TIER_MILD
	themes = list(PSYCHOSIS_THEME_WHISPERING)

/datum/hallucination/psychosis/echo_self/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/datum/status_effect/psychosis/eff = target.has_status_effect(/datum/status_effect/psychosis)
	if(eff && length(eff.last_said))
		feedback_details += "Echoed: [eff.last_said]"
		to_chat(target, "<span class='italics'>...вы слышите свой собственный голос со стороны: '[eff.last_said]'...</span>")
	else
		// Fallback - персонаж недавно молчал, выдаём generic "внутренний голос".
		var/list/fallback = list(
			"...тебе кажется, что ты только что говорил - но ты молчал...",
			"...твой собственный голос звучит у тебя в голове, повторяя что-то непонятное...",
			"...ты слышишь шёпот - твоим голосом, но не твоими словами...",
			"...кто-то произносит твоим голосом фразу, которую ты не успеваешь разобрать...",
		)
		var/line = pick(fallback)
		feedback_details += "Echo fallback: [line]"
		to_chat(target, "<span class='italics'>[line]</span>")
	qdel(src)

// Гаслайтинг (мимикрия под системные сообщения). Эти типы намеренно НЕ помечены
// как warning - игрок должен сомневаться, реальное это объявление или нет.

// Фальшивое приоритетное объявление - имитирует экстренное станционное с сиреной.
// SEVERE, чтобы появляться только при сильном психозе - слишком дезориентирующее
// для mild.

GLOBAL_LIST_INIT(psychosis_fake_announce_lines, list(
	list("ВНИМАНИЕ: БИОЛОГИЧЕСКАЯ УГРОЗА", "Зафиксирована вспышка биологической угрозы. Эвакуация из заражённых отсеков немедленно."),
	list("КАРАНТИН ОТСЕКА", "Отсек изолирован. Воздушные шлюзы заблокированы. Ожидайте указаний командования."),
	list("ВНИМАНИЕ: ПОТЕРЯ ДАВЛЕНИЯ", "Зафиксирована стремительная декомпрессия в нескольких отсеках одновременно. Приготовьтесь к эвакуации."),
	list("ТРЕВОГА: УРОВЕНЬ ДЕЛЬТА", "Активирована процедура самоуничтожения станции. Покиньте корабль."),
	list("СИГНАЛ ОТ КАПИТАНА", "Капитан мёртв. Командование переходит к старшим офицерам."),
))

/datum/hallucination/psychosis/fake_priority_announce
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_MACHINERY)

/datum/hallucination/psychosis/fake_priority_announce/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/picked = pick(GLOB.psychosis_fake_announce_lines)
	var/title = picked[1]
	var/body = picked[2]
	feedback_details += "Fake announce: [title]"
	to_chat(target, "<br><span class='boldannounce'>[title]</span><br><span class='alert'>[body]</span><br>")
	psy_play(target, target, 'sound/effects/siren-spooky.ogg', 50, FALSE)
	qdel(src)

// Фальшивый медицинский алерт - сообщение в стиле системного предупреждения о
// критическом состоянии здоровья.

GLOBAL_LIST_INIT(psychosis_fake_health_lines, list(
	"Ваше сердце остановилось!",
	"Критическая кровопотеря!",
	"Дыхание прекратилось.",
	"Нервная система отказывает.",
	"Жизненные показатели падают до критических значений.",
))

/datum/hallucination/psychosis/fake_health_alert
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)

/datum/hallucination/psychosis/fake_health_alert/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/line = pick(GLOB.psychosis_fake_health_lines)
	feedback_details += "Fake health: [line]"
	to_chat(target, "<span class='userdanger'>[line]</span>")
	qdel(src)

// Поверх ближайшего шлюза появляется фантомная табличка с угрожающей надписью.
// image_state = "securearea" - реальный state из icons/obj/decals.dmi (базовый
// для /obj/structure/sign/warning). maptext с красной надписью поверх иконки
// делает содержание читаемым вне зависимости от рендера state.

GLOBAL_LIST_INIT(psychosis_wrong_sign_labels, list(
	"MORGUE", "BREACH", "QUARANTINE", "DO NOT ENTER", "TOXIC",
))

/obj/effect/hallucination/simple/wrong_sign_overlay
	name = "табличка"
	image_icon = 'icons/obj/decals.dmi'
	image_state = "securearea"
	image_layer = ABOVE_OBJ_LAYER
	/// Текст на табличке - подставляется в maptext через GetImage().
	var/sign_label = ""

/obj/effect/hallucination/simple/wrong_sign_overlay/GetImage()
	var/image/I = ..()
	if(sign_label)
		I.maptext = "<span style='color:#ff3030;font-weight:bold;font-size:8pt'>[sign_label]</span>"
		I.maptext_width = 64
		I.maptext_x = -16
		I.maptext_y = 16
	return I

/datum/hallucination/psychosis/wrong_sign
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MACHINERY)
	var/obj/effect/hallucination/simple/wrong_sign_overlay/marker

/datum/hallucination/psychosis/wrong_sign/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/airlocks = list()
	for(var/obj/machinery/door/airlock/A in view(5, target))
		airlocks += A
	if(!length(airlocks))
		psy_log("early_out type=[type] reason=no_airlock_in_view")
		qdel(src)
		return
	var/obj/machinery/door/airlock/picked_airlock = pick(airlocks)
	var/turf/spawn_turf = get_turf(picked_airlock)
	var/label = pick(GLOB.psychosis_wrong_sign_labels)
	feedback_details += "Sign on [picked_airlock] -> [label]"
	marker = new(spawn_turf, target)
	marker.sign_label = label
	psy_log("wrong_sign sign_label_set marker=[marker] label=[label]")
	marker.Show()
	QDEL_IN(src, rand(50, 70))

/datum/hallucination/psychosis/wrong_sign/Destroy()
	QDEL_NULL(marker)
	return ..()

// Формат вывода точно повторяет /obj/item/pda/proc/receive_message (PDA.dm:1042),
// включая иконку устройства, имя, должность и интерактивные ссылки-пустышки.

GLOBAL_LIST_INIT(psychosis_fake_pda_lines, list(
	"встретимся в шкафу",
	"не выходи из комнаты",
	"это ты их вызвал",
	"я знаю что ты сделал",
	"они идут за тобой следующим",
	"ты меня слышишь? пожалуйста",
	"почему ты мне не отвечаешь",
))

/datum/hallucination/psychosis/fake_pda
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MACHINERY)

/datum/hallucination/psychosis/fake_pda/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/humans = list()
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(H == target || H.stat == DEAD || !H.mind)
			continue
		humans += H
	if(!length(humans))
		psy_log("early_out type=[type] reason=no_humans")
		qdel(src)
		return
	var/mob/living/carbon/human/sender = pick(humans)
	var/sender_name = sender.real_name || "Unknown"
	var/assigned_role = sender.mind?.assigned_role
	var/job = "Crew"
	if(istype(assigned_role, /datum/job))
		var/datum/job/assigned_job = assigned_role
		job = assigned_job.title || "Crew"
	else if(assigned_role)
		job = "[assigned_role]"
	var/line = pick(GLOB.psychosis_fake_pda_lines)
	feedback_details += "Fake PDA from [sender_name] ([job]): [line]"
	var/pda_icon = icon2html('icons/obj/pda_alt.dmi', target.client, "pda")
	to_chat(target, "[pda_icon] <b>Сообщение от [sender_name] ([job]), </b>[line] (<a href='byond://?src=fake;choice=Message'>Reply</a>) (<a href='byond://?src=fake;choice=toggle_block'>BLOCK/UNBLOCK</a>)")
	psy_play(target, target, 'sound/machines/twobeep.ogg', 50, FALSE)
	qdel(src)

// Искажение восприятия других живых игроков. Используют чужого моба как anchor
// для local-image. Реальный моб не меняется, никто кроме target не видит изменений.

/// Накладывает image на живого моба в view target. Возвращает image для контроля
/// жизненного цикла, либо null если кандидатов нет.
/proc/psychosis_overlay_other(mob/living/carbon/target, icon, state, range = 7, color, layer)
	psy_log("overlay_other start target=[target] icon=[icon] state=[state]")
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(range, target))
		if(H == target || H.stat == DEAD)
			continue
		candidates += H
	if(!length(candidates))
		psy_log("overlay_other NO_CANDIDATES target=[target] range=[range]")
		return null
	var/mob/living/carbon/human/anchor = pick(candidates)
	var/image/I = image(icon, anchor, state, layer || FLOAT_LAYER)
	if(color)
		I.color = color
	if(target.client)
		target.client.images |= I
	psy_log("overlay_other ATTACHED target=[target] anchor=[anchor] icon=[icon] state=[state] has_client=[target.client ? "yes" : "NO"]")
	return I

/datum/hallucination/psychosis/bloody_other
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_MASSACRE)
	var/image/blood_image

/datum/hallucination/psychosis/bloody_other/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	blood_image = psychosis_overlay_other(target, 'icons/effects/blood.dmi', "uniformblood")
	if(!blood_image)
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	feedback_details += "Bloody overlay on other"
	QDEL_IN(src, rand(40, 60))

/datum/hallucination/psychosis/bloody_other/Destroy()
	if(blood_image && target?.client)
		target.client.images -= blood_image
	blood_image = null
	return ..()

/datum/hallucination/psychosis/wrong_face
	severity = PSYCHOSIS_TIER_SEVERE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/image/face_image

/datum/hallucination/psychosis/wrong_face/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	// husk_s - иконстейт лица хаска из icons/mob/human_face.dmi.
	// Если иконстейт не совпадает визуально - подобрать альтернативу в том же файле.
	face_image = psychosis_overlay_other(target, 'icons/mob/human_face.dmi', "husk_s", color = "#400000")
	if(!face_image)
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	feedback_details += "Wrong face on other"
	QDEL_IN(src, rand(30, 40))

/datum/hallucination/psychosis/wrong_face/Destroy()
	if(face_image && target?.client)
		target.client.images -= face_image
	face_image = null
	return ..()

// За спиной живого члена экипажа появляется тёмный силуэт.

/obj/effect/hallucination/simple/shadow_behind
	name = "тень"
	image_icon = 'icons/mob/human.dmi'
	image_state = "husk"
	col_mod = "#000000"
	image_layer = MOB_LAYER

/datum/hallucination/psychosis/shadow_behind_other
	severity = PSYCHOSIS_TIER_MODERATE
	themes = list(PSYCHOSIS_THEME_STALKER)
	var/obj/effect/hallucination/simple/shadow_behind/marker

/datum/hallucination/psychosis/shadow_behind_other/New(mob/living/carbon/C, forced = TRUE)
	set waitfor = FALSE
	..()
	psy_log("start type=[type] target=[target]")
	var/list/candidates = list()
	for(var/mob/living/carbon/human/H in view(6, target))
		if(H == target || H.stat == DEAD)
			continue
		candidates += H
	if(!length(candidates))
		psy_log("early_out type=[type] reason=no_candidates")
		qdel(src)
		return
	var/mob/living/carbon/human/anchor = pick(candidates)
	var/turf/anchor_turf = get_turf(anchor)
	var/turf/behind = get_step(anchor_turf, turn(anchor.dir, 180))
	if(!behind)
		psy_log("early_out type=[type] reason=no_anchor_behind_turf")
		qdel(src)
		return
	feedback_details += "Shadow behind [anchor]"
	marker = new(behind, target)
	psy_log_visual(marker, target, "shadow_behind_other")
	marker.setDir(anchor.dir)
	QDEL_IN(src, rand(30, 40))

/datum/hallucination/psychosis/shadow_behind_other/Destroy()
	QDEL_NULL(marker)
	return ..()

// Словарь подмен для mishearing. Низкочастотные подмены ключевых слов в речи
// окружающих, применяются к hearing_args[HEARING_RAW_MESSAGE] из COMSIG_MOVABLE_HEAR.
// Цель - точечно исказить узнаваемые токены, не превращая речь в кашу.

GLOBAL_LIST_INIT(psychosis_distortion_dict, list(
	"привет"  = list("помоги", "прощай"),
	"иду"     = list("беги", "уйди"),
	"помощь"  = list("кровь", "поздно"),
	"хорошо"  = list("они здесь", "не оборачивайся"),
	"да"      = list("умри", "беги"),
	"нет"     = list("уже поздно", "ты следующий"),
	"слышишь" = list("умираешь", "горишь"),
	"hello"   = list("help", "behind"),
	"ok"      = list("die", "run"),
	"yes"     = list("kill", "watch"),
))

/// Подменяет 1-2 совпадения из словаря в исходной строке. Если совпадений нет -
/// возвращает оригинал без изменений. Поиск регистронезависимый и токеновый:
/// "ok" не сработает внутри "broken", "да" - внутри "дать".
/proc/distort_message(text)
	if(!istext(text) || !length(text))
		return text
	var/list/hits = list()
	for(var/key in GLOB.psychosis_distortion_dict)
		if(psychosis_word_regex(key).Find(text))
			hits += key
	if(!length(hits))
		return text
	var/replacements = min(rand(1, 2), length(hits))
	var/result = text
	for(var/i in 1 to replacements)
		var/key = pick(hits)
		hits -= key
		var/list/options = GLOB.psychosis_distortion_dict[key]
		var/replacement = pick(options)
		// $1/$2 - захваченные граничные символы (или пустые в начале/конце строки).
		result = psychosis_word_regex(key).Replace(result, "$1[replacement]$2")
	return result

/// Регекс с word-boundary для distort_message. Граница - всё, что не латинская
/// или кириллическая буква и не цифра. Конструируется на каждый вызов, потому
/// что регексы в DM stateful и кеширование требует ручного сброса next.
/proc/psychosis_word_regex(key)
	RETURN_TYPE(/regex)
	return regex("(^|\[^a-zа-яё0-9\])[key](\[^a-zа-яё0-9\]|$)", "i")
