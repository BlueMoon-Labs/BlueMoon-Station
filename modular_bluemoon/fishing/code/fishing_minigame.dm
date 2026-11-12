// поплавок мирно покачивается на воде
#define WAIT_PHASE 1
// этап, на котором кликом запускается tgui
#define BITING_PHASE 2
// сам этап мини-игры в интерфейсе
#define MINIGAME_PHASE 3

/// минимальная скорость, при которой приманка ещё отскакивает
#define BAIT_MIN_VELOCITY_BOUNCE 150

/// насколько сложность снижает стартовый прогресс
#define MAX_FISH_COMPLETION_MALUS 15
/// сколько времени есть между поклёвкой и возвратом к забросу
#define BITING_TIME_WINDOW 4 SECONDS

/// множитель, с которым сложность урезает высоту приманки
#define BAIT_HEIGHT_DIFFICULTY_MALUS 1.3

/// константы, задающие движение приманки на ползунке мини-игры
#define REELING_STATE_IDLE 0
#define REELING_STATE_UP 1
#define REELING_STATE_DOWN 2

/// высота полосы мини-игры в пикселях
#define MINIGAME_SLIDER_HEIGHT 76
/// обычная высота приманки в пикселях
#define MINIGAME_BAIT_HEIGHT 27
/// сколько пикселей отведено верхушке и низу приманки
#define MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT 6
/// обычная высота рыбы в пикселях (по пикселю срезано с боков ради лучшего вида спрайта)
#define MINIGAME_FISH_HEIGHT 4
/// высота полосы прогресса в пикселях
#define MINIGAME_COMPLETION_BAR_HEIGHT 80

GLOBAL_LIST_EMPTY(fishing_challenges_by_user)

/datum/fishing_challenge
	/// момент старта мини-игры в интерфейсе
	var/start_time
	/// закончено ли испытание победой, поражением или закрытием окна
	var/completed = FALSE
	/// модификаторы правил вроде утяжелённой приманки
	var/special_effects = NONE
	/// список возможных активных эффектов. Если он не пуст, время от времени один из них включается.
	var/list/active_effects
	/// пауза между сменой активных эффектов
	COOLDOWN_DECLARE(active_effect_cd)
	/// эффект, который работает прямо сейчас
	var/current_active_effect
	/// путь к награде
	var/reward_path = FISHING_DUD
	/// сложность текущей мини-игры
	var/difficulty = FISHING_DEFAULT_DIFFICULTY
	/// этап, на котором всё остановилось
	var/phase = WAIT_PHASE
	/// таймер, отсчитывающий до следующего этапа
	var/next_phase_timer
	/// нижняя и верхняя границы ожидания поклёвки
	var/list/wait_time_range = list(3 SECONDS, 25 SECONDS)
	/// когда игрок последний раз кликнул на этапе заброса
	var/last_baiting_click
	/// защита от двойной обработки одного клика через mousedown и clickon
	var/last_input_time = -1
	/// моб, который удит рыбу
	var/mob/living/user
	/// удочка, которой ловят
	var/obj/item/fishing_rod/used_rod
	/// поплавок, который видит игрок
	var/obj/effect/fishing_float/float
	/// место рыбалки, над которым висит поплавок
	var/atom/location
	/// состояние фоновой иконки из fishing_hud.dmi
	var/background = "background_default"
	/// состояние иконки рыбы из fishing_hud.dmi
	var/fish_icon = FISH_ICON_DEF

	/// леска, натянутая от удочки к поплавку
	var/datum/beam/fishing_line

	var/experience_multiplier = 1

	/// сколько места рыба занимает на ползунке
	var/fish_height = 50
	/// сколько места приманка занимает на ползунке
	var/bait_height = 360
	/// высота приманки в пикселях
	var/bait_pixel_height = MINIGAME_BAIT_HEIGHT
	/// высота рыбы в пикселях
	var/fish_pixel_height = MINIGAME_FISH_HEIGHT
	/// где рыба стоит на ползунке
	var/fish_position = 0
	/// где приманка стоит на ползунке
	var/bait_position = 0
	/// с какой скоростью приманка движется сейчас
	var/bait_velocity = 0

	/// прогресс вываживания. На 100 рыба поймана, на 0 она уходит.
	var/completion = 30
	/// сколько прогресса сгорает в секунду, пока приманка вне рыбы
	var/completion_loss = 6
	/// сколько прогресса капает в секунду, пока приманка на рыбе
	var/completion_gain = 5

	var/datum/fish_movement/mover

	/// приманка висит, подматывается вверх или травится вниз (ЛКМ и ПКМ)
	var/reeling_state = REELING_STATE_IDLE
	/// ускорение приманки, когда её не подматывают
	var/gravity_velocity = -800
	/// ускорение приманки во время подмотки
	var/reeling_velocity = 1200
	/// насколько приманка отскакивает от краёв ползунка. Не больше 1
	var/bait_bounce_mult = 0.6
	/// множитель торможения, когда приманка меняет направление
	var/deceleration_mult = 1.8
	/// множитель скорости, пока приманка накрывает рыбу
	var/overlap_velocity_mult = 0.6

	/// фон мини-игры, он же контейнер для остальных оверлеев
	var/atom/movable/screen/fishing_hud/fishing_hud

	/// источник рыбы, откуда берётся награда
	var/datum/fish_source/fish_source

/datum/fishing_challenge/New(datum/component/fishing_spot/comp, obj/item/fishing_rod/rod, mob/living/user)
	src.user = user
	used_rod = rod
	location = comp.parent
	float = new(get_turf(location), location)
	float.spin_frequency = rod.spin_frequency
	RegisterSignal(location, COMSIG_QDELETING, PROC_REF(on_spot_gone))
	RegisterSignal(comp, COMSIG_QDELETING, PROC_REF(on_spot_gone))
	register_reward_signals(comp.fish_source)
	RegisterSignal(fish_source, COMSIG_FISHING_SOURCE_INTERRUPT_CHALLENGE, PROC_REF(interrupt_challenge))
	background = comp.fish_source.background
	if(comp.fish_source.wait_time_range)
		wait_time_range = comp.fish_source.wait_time_range
	if(float.spin_frequency) // блесна немного сужает разброс, причём в обе стороны сразу
		wait_time_range = list(wait_time_range[1] + 8 SECONDS, wait_time_range[2] - 8 SECONDS)
	var/bite_speed = 1
	if(istype(rod.bait, /obj/item/bait/worm/premium))
		bite_speed = 0.5
	else if(istype(rod.bait, /obj/item/bait/worm))
		bite_speed = 0.7
	if(bite_speed != 1)
		wait_time_range = list(wait_time_range[1] * bite_speed, wait_time_range[2] * bite_speed)
	// продвинутые удочки умеют работать и без наживки
	if(!rod.bait && !rod.baitless_fishing)
		completion -= 10
	SEND_SIGNAL(user, COMSIG_MOB_BEGIN_FISHING, src)
	SEND_SIGNAL(rod, COMSIG_ROD_BEGIN_FISHING, src)
	GLOB.fishing_challenges_by_user[user] = src

	/// включаем особые параметры
	if(rod.line)
		completion_gain += 1 // даже простая леска немного помогает
		if(rod.line.fishing_line_traits & FISHING_LINE_BOUNCY)
			completion_loss -= 2
		if(rod.line.fishing_line_traits & FISHING_LINE_STIFF)
			completion_loss += 1
			completion_gain -= 1
		if(rod.line.fishing_line_traits & FISHING_LINE_AUTOREEL)
			special_effects |= FISHING_MINIGAME_AUTOREEL
	if(rod.hook)
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_WEIGHTED)
			bait_bounce_mult = 0.1
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_BIDIRECTIONAL)
			special_effects |= FISHING_MINIGAME_RULE_BIDIRECTIONAL
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_NO_ESCAPE)
			special_effects |= FISHING_MINIGAME_RULE_NO_ESCAPE
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_ENSNARE)
			completion_loss -= 2
		if(rod.hook.fishing_hook_traits & FISHING_HOOK_KILL)
			special_effects |= FISHING_MINIGAME_RULE_KILL

	// чем выше навык, тем быстрее заканчивается мини-игра
	var/fishing_level = user.mind?.get_skill_level(/datum/skill/level/fishing) || 0
	completion_loss -= fishing_level * 0.8
	completion_gain += fishing_level * 0.5

	reeling_velocity *= rod.bait_speed_mult
	completion_gain *= rod.completion_speed_mult
	bait_bounce_mult *= rod.bounciness_mult
	deceleration_mult *= rod.deceleration_mult
	gravity_velocity *= rod.gravity_mult
	/**
	 * Множитель перекрытия по умолчанию меньше 1, а степень делает его ещё меньше,
	 * чтобы сгладить неудобное управление при необычной скорости приманки.
	 */
	overlap_velocity_mult = overlap_velocity_mult ** rod.bait_speed_mult

/datum/fishing_challenge/Destroy(force)
	if(user)
		if(GLOB.fishing_challenges_by_user[user] == src)
			GLOB.fishing_challenges_by_user -= user
		GLOB.fishing_challenges_by_user.Remove(user)
	if(!completed)
		complete(win = FALSE)
	if(fishing_line)
		// чтобы сообщение об обрыве лески не всплывало каждый раз после мини-игры
		UnregisterSignal(fishing_line, COMSIG_QDELETING)
	if(used_rod && !QDELETED(used_rod))
		used_rod.clear_fishing_line()
	fishing_line = null
	QDEL_NULL(float)
	SStgui.close_uis(src)
	if(user)
		UnregisterSignal(user, COMSIG_MOB_CLICKON)
	if(user?.client)
		UnregisterSignal(user.client, list(COMSIG_CLIENT_MOUSEDOWN, COMSIG_CLIENT_MOUSEUP))
	user = null
	used_rod = null
	location = null
	QDEL_NULL(mover)
	return ..()

/**
 * Регистрирует сигналы сложности, награды и завершения испытания.
 * Вызывайте, если нужно подменить источник рыбы для выбора награды, лучше всего до этапа мини-игры.
 */
/datum/fishing_challenge/proc/register_reward_signals(datum/fish_source/new_fish_source)
	if(fish_source)
		fish_source.UnregisterSignal(src, list(
			COMSIG_FISHING_CHALLENGE_ROLL_REWARD,
		))
		fish_source.UnregisterSignal(user, COMSIG_MOB_COMPLETE_FISHING)
	fish_source = new_fish_source
	fish_source.RegisterSignal(src, COMSIG_FISHING_CHALLENGE_ROLL_REWARD, TYPE_PROC_REF(/datum/fish_source, roll_reward_minigame))
	fish_source.RegisterSignal(user, COMSIG_MOB_COMPLETE_FISHING, TYPE_PROC_REF(/datum/fish_source, on_challenge_completed))

/datum/fishing_challenge/proc/send_alert(message)
	location?.balloon_alert(user, message)

/datum/fishing_challenge/proc/on_spot_gone(datum/source)
	SIGNAL_HANDLER
	send_alert("место рыбалки исчезло!")
	interrupt()

/datum/fishing_challenge/proc/interrupt_challenge(datum/source, reason)
	SIGNAL_HANDLER
	if(reason)
		send_alert(reason)
	interrupt()

/datum/fishing_challenge/proc/start(mob/living/user)
	/// создаём визуал лески
	if(!used_rod.internal)
		fishing_line = used_rod.create_fishing_line(float, user, target_py = float.pixel_y + 4)
		if(isnull(fishing_line)) // леску создать не вышло, скорее всего её не видно
			qdel(src)
			return
		RegisterSignal(fishing_line, COMSIG_QDELETING, PROC_REF(on_line_deleted))
	else // без лески рыбалка обрывается, стоит игроку уйти
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_float_or_user_move))
		RegisterSignal(float, COMSIG_MOVABLE_MOVED, PROC_REF(on_float_or_user_move))
		RegisterSignal(user, SIGNAL_ADDTRAIT(TRAIT_HANDS_BLOCKED), PROC_REF(on_hands_blocked))
	RegisterSignal(user, SIGNAL_REMOVETRAIT(TRAIT_PROFOUND_FISHER), PROC_REF(no_longer_fishing))
	active_effects = bitfield_to_list(special_effects & FISHING_MINIGAME_ACTIVE_EFFECTS)
	// леска потеряла видимость, удочка выпала или её удалили
	RegisterSignal(used_rod, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_attack_self))
	if(user.client)
		RegisterSignal(user.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(handle_mousedown))
	RegisterSignal(user, COMSIG_MOB_CLICKON, PROC_REF(handle_click))
	start_baiting_phase()
	to_chat(user, span_notice("You start fishing..."))
	playsound(location, 'sound/effects/splash.ogg', 100)

/// расставляет таймеры для блесны, которую надо подсекать через равные промежутки
/datum/fishing_challenge/proc/set_lure_timers()
	float.spin_ready = FALSE
	addtimer(CALLBACK(src, PROC_REF(set_lure_ready)), float.spin_frequency[1], TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)
	addtimer(CALLBACK(src, PROC_REF(missed_lure)), float.spin_frequency[2], TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)
	float.update_appearance(UPDATE_OVERLAYS)

/datum/fishing_challenge/proc/set_lure_ready()
	if(phase != WAIT_PHASE)
		return
	float.spin_ready = TRUE
	float.update_appearance(UPDATE_OVERLAYS)
	if(special_effects & FISHING_MINIGAME_AUTOREEL)
		addtimer(CALLBACK(src, PROC_REF(auto_spin)), 0.2 SECONDS)
	playsound(float, 'sound/machines/ping.ogg', 20, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)

/datum/fishing_challenge/proc/auto_spin()
	if(phase != WAIT_PHASE || !float.spin_ready)
		return
	float.spin_ready = FALSE
	float.update_appearance(UPDATE_OVERLAYS)
	set_lure_timers()
	send_alert("подсекли")

/datum/fishing_challenge/proc/missed_lure()
	if(phase != WAIT_PHASE)
		return
	send_alert("промах!")
	start_baiting_phase(TRUE) // за неподсечённую блесну накидывает ещё 3-5 секунд

/datum/fishing_challenge/proc/on_line_deleted(datum/source)
	SIGNAL_HANDLER
	fishing_line = null
	if(used_rod && !QDELETED(used_rod))
		used_rod.fishing_line = null
		used_rod.currently_hooked = null
	/// поплавок может скрыться за углом, поэтому сообщение всплывает прямо над ним
	user.balloon_alert(user, user.is_holding(used_rod) ? "леска оборвалась" : "удочка выпала")
	interrupt()

/datum/fishing_challenge/proc/on_float_or_user_move(datum/source)
	SIGNAL_HANDLER

	if(get_dist(user, location) > 4)
		user.balloon_alert(user, "слишком далеко!")
		interrupt()

/datum/fishing_challenge/proc/on_hands_blocked(datum/source)
	SIGNAL_HANDLER
	if(completed) // удочка выпала, так что испытание уже закрыто
		return
	user.balloon_alert(user, "руки заняты!")
	interrupt()

/datum/fishing_challenge/proc/no_longer_fishing(datum/source)
	SIGNAL_HANDLER
	if(completed) // мы уже победили или проиграли
		return
	user.balloon_alert(user, "прервано!")
	interrupt()

/datum/fishing_challenge/proc/handle_mousedown(client/source, datum/object, location, control, params)
	SIGNAL_HANDLER
	if(QDELETED(user) || !user.client)
		return
	if(last_input_time == world.time)
		return
	last_input_time = world.time
	var/list/click_mods = params2list(params || "")
	if(LAZYACCESS(click_mods, "right") && !LAZYACCESS(click_mods, "left"))
		return
	if(phase == WAIT_PHASE)
		if(world.time < last_baiting_click + 0.25 SECONDS)
			return // не наказываем за случайный двойной клик
		if(float.spin_frequency)
			if(!float.spin_ready)
				send_alert("слишком рано!")
				start_baiting_phase(TRUE) // за эту ошибку накидываем ещё 3-5 секунд
			else
				send_alert("подсекли")
				last_baiting_click = world.time
			float.spin_ready = FALSE
			set_lure_timers()
		else
			send_alert("промах!")
			start_baiting_phase(TRUE) // и за эту ошибку тоже накидываем 3-5 секунд
	else if(phase == BITING_PHASE)
		start_minigame_phase()

/datum/fishing_challenge/proc/handle_click(mob/living/source, atom/target, params)
	SIGNAL_HANDLER
	handle_mousedown(source?.client, target, null, null, params)

/// испытание прервано чем-то извне
/datum/fishing_challenge/proc/interrupt()
	if(!completed)
		experience_multiplier *= 0.5
		complete(FALSE)

/datum/fishing_challenge/proc/on_attack_self(obj/item/source, mob/living/user)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(stop_fishing), source, user)

/datum/fishing_challenge/proc/stop_fishing(obj/item/rod, mob/living/user)
	if((phase != MINIGAME_PHASE || do_after(user, 3 SECONDS, rod)) && !QDELETED(src) && !completed)
		experience_multiplier *= 0.5
		send_alert("рыбалка остановлена")
		complete(FALSE)

/// множитель штрафа к опыту, если уровень рыбака заметно выше сложности
#define EXPERIENCE_MALUS_MULT 0.08

/datum/fishing_challenge/proc/complete(win = FALSE)
	if(completed)
		return
	if(next_phase_timer && next_phase_timer != -1)
		deltimer(next_phase_timer)
	completed = TRUE
	if(user && GLOB.fishing_challenges_by_user[user] == src)
		GLOB.fishing_challenges_by_user -= user
		GLOB.fishing_challenges_by_user.Remove(user)
	if(phase == MINIGAME_PHASE)
		remove_minigame_hud()

	if(!QDELETED(user) && user.mind && start_time && !(special_effects & FISHING_MINIGAME_RULE_NO_EXP))
		var/seconds_spent = (world.time - start_time) * 0.1
		var/extra_exp_malus = user.mind.get_skill_level(/datum/skill/level/fishing) - difficulty * 0.1
		if(extra_exp_malus > 0)
			experience_multiplier /= (1 + extra_exp_malus * EXPERIENCE_MALUS_MULT)
		experience_multiplier *= used_rod.experience_multiplier
		user.mind.auto_gain_experience(/datum/skill/level/fishing, round(seconds_spent * FISHING_SKILL_EXP_PER_SECOND * experience_multiplier * 100, 1))
		if(user.mind.get_skill_level(/datum/skill/level/fishing) >= STD_MAX_LVL)
			user.client?.give_award(/datum/award/achievement/skill/legendary_fisher, user)

	if(!win)
		if(user)
			SEND_SIGNAL(user, COMSIG_MOB_COMPLETE_FISHING, src, FALSE)
		if(!QDELETED(src))
			qdel(src)
		return

	if(reward_path != FISHING_DUD)
		playsound(location, 'modular_bluemoon/fishing/sound/effects/bigsplash.ogg', 100)

	var/valid_achievement_catch = FALSE
	if(ispath(reward_path, /obj/item/fish))
		valid_achievement_catch = TRUE
	else if(isfish(reward_path))
		var/obj/item/fish/fishy_individual = reward_path
		if(!HAS_TRAIT(fishy_individual, TRAIT_NO_FISHING_ACHIEVEMENT) && fishy_individual.status == FISH_ALIVE)
			valid_achievement_catch = TRUE

	if(valid_achievement_catch)
		var/obj/item/fish/fish_reward = reward_path
		var/obj/item/fish/path_to_use = initial(fish_reward.fish_id_redirect_path) || fish_reward
		var/fish_id = initial(path_to_use.fish_id)
		if(fish_id)
			award_fish_caught(user, fish_id, initial(path_to_use.name))

	if(user)
		SEND_SIGNAL(user, COMSIG_MOB_COMPLETE_FISHING, src, TRUE)
	if(!QDELETED(src))
		qdel(src)

#undef EXPERIENCE_MALUS_MULT

/datum/fishing_challenge/proc/start_baiting_phase(penalty = FALSE)
	reward_path = null // если поклёвку пропустили, сбрасываем путь обратно в null
	var/wait_time
	last_baiting_click = world.time
	if(penalty)
		wait_time = min(timeleft(next_phase_timer) + rand(3 SECONDS, 5 SECONDS), 30 SECONDS)
	else
		wait_time = rand(wait_time_range[1], wait_time_range[2])
		if(special_effects & FISHING_MINIGAME_AUTOREEL && wait_time >= 15 SECONDS)
			wait_time = max(wait_time - 7.5 SECONDS, 15 SECONDS)
	if(next_phase_timer && next_phase_timer != -1)
		deltimer(next_phase_timer)
	phase = WAIT_PHASE
	// поплавок мерно покачивается
	animate(float, pixel_z = 1, time = 1 SECONDS, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_z = -1, time = 1 SECONDS, flags = ANIMATION_RELATIVE)
	next_phase_timer = addtimer(CALLBACK(src, PROC_REF(start_biting_phase)), wait_time, TIMER_STOPPABLE|TIMER_DELETE_ME)
	if(float.spin_frequency)
		set_lure_timers()

/datum/fishing_challenge/proc/start_biting_phase()
	phase = BITING_PHASE

	var/list/rewards = list()
	SEND_SIGNAL(src, COMSIG_FISHING_CHALLENGE_ROLL_REWARD, used_rod, user, location, rewards)
	if(length(rewards))
		reward_path = pick(rewards)
	playsound(location, 'modular_bluemoon/fishing/sound/effects/fish_splash.ogg', 100)

	if(HAS_MIND_TRAIT(user, TRAIT_REVEAL_FISH))
		var/possible_icon
		if(isdatum(reward_path))
			var/datum/reward = reward_path
			possible_icon = GLOB.specific_fish_icons[reward.type]
		else
			possible_icon = GLOB.specific_fish_icons[reward_path]
		fish_icon = possible_icon || FISH_ICON_DEF
		switch(fish_icon)
			if(FISH_ICON_DEF)
				send_alert("рыба!!!")
			if(FISH_ICON_HOSTILE)
				send_alert("враждебное!!!")
			if(FISH_ICON_STAR)
				send_alert("морская звезда!!!")
			if(FISH_ICON_CHUNKY)
				send_alert("круглая рыба!!!")
			if(FISH_ICON_JELLYFISH)
				send_alert("медуза!!!")
			if(FISH_ICON_SLIME)
				send_alert("слизь!!!")
			if(FISH_ICON_COIN)
				send_alert("ценность!!!")
			if(FISH_ICON_GEM)
				send_alert("руда!!!")
			if(FISH_ICON_CRAB)
				send_alert("ракообразное!!!")
			if(FISH_ICON_BONE)
				send_alert("кости!!!")
			if(FISH_ICON_ELECTRIC)
				send_alert("электрическое!!!")
			if(FISH_ICON_WEAPON)
				send_alert("оружие!!!")
			if(FISH_ICON_CRITTER)
				send_alert("зверёк!!!")
			if(FISH_ICON_SEED)
				send_alert("семена!!!")
			if(FISH_ICON_BOTTLE)
				send_alert("бутылка!!!")
			if(FISH_ICON_ORGAN)
				send_alert("орган!!!")
	else
		send_alert("!!")
	animate(float, pixel_z = 3, time = 5, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_z = -3, time = 5, flags = ANIMATION_RELATIVE)
	if(special_effects & FISHING_MINIGAME_AUTOREEL)
		addtimer(CALLBACK(src, PROC_REF(automatically_start_minigame)), 0.2 SECONDS)
	// готовим следующий этап
	next_phase_timer = addtimer(CALLBACK(src, PROC_REF(start_baiting_phase)), BITING_TIME_WINDOW, TIMER_STOPPABLE|TIMER_DELETE_ME)
	/// с блесной поплавок на этапе мини-игры должен гореть зелёным, а не красным
	float.spin_ready = TRUE
	float.update_appearance(UPDATE_OVERLAYS)

/datum/fishing_challenge/proc/automatically_start_minigame()
	if(phase == BITING_PHASE)
		start_minigame_phase(auto_reel = TRUE)

/// сколько урона в секунду получает рыба при FISHING_MINIGAME_RULE_KILL
#define FISH_DAMAGE_PER_SECOND 2

/// игрока больше нет, так что мини-игру прерываем
/datum/fishing_challenge/proc/on_user_logout(datum/source)
	SIGNAL_HANDLER
	interrupt()

/datum/fishing_challenge/proc/on_reward_removed(datum/source)
	SIGNAL_HANDLER
	send_alert("награда исчезла!")
	interrupt()

/datum/fishing_challenge/proc/on_fish_death(obj/item/fish/source)
	SIGNAL_HANDLER
	if(source.status == FISH_DEAD)
		win_anyway()

/datum/fishing_challenge/proc/win_anyway()
	if(completed)
		return
	// победа по таймауту или смерть рыбы не должны давать полный опыт
	experience_multiplier *= 0.5
	complete(TRUE)

/datum/fishing_challenge/proc/hurt_fish(datum/source, obj/item/fish/reward)
	SIGNAL_HANDLER
	if(istype(reward))
		var/damage = CEILING((world.time - start_time)/10 * FISH_DAMAGE_PER_SECOND, 1)
		reward.damage_fish(damage)

/datum/fishing_challenge/proc/get_difficulty()
	var/new_difficulty = fish_source?.calculate_difficulty_minigame(src, reward_path, used_rod, user) || initial(difficulty)

	// если снаряжение и навык давят сложность в ноль, сразу выдаём награду
	if(new_difficulty <= 0)
		complete(TRUE)
		return FALSE

	difficulty = clamp(round(new_difficulty), FISHING_MINIMUM_DIFFICULTY, 100)
	return TRUE

/datum/fishing_challenge/proc/update_difficulty()
	if(phase != MINIGAME_PHASE)
		return
	var/old_difficulty = difficulty
	// ранний выход, если сложность та же или уже ноль
	if(!get_difficulty() || difficulty == old_difficulty)
		return
	bait_height = initial(bait_height) * used_rod.bait_height_mult
	experience_multiplier -= difficulty * FISHING_SKILL_DIFFIULTY_EXP_MULT
	mover.reset_difficulty_values()
	adjust_to_difficulty()

/datum/fishing_challenge/proc/adjust_to_difficulty()
	mover.adjust_to_difficulty()
	bait_height -= round(difficulty * BAIT_HEIGHT_DIFFICULTY_MALUS)
	bait_pixel_height = round(MINIGAME_BAIT_HEIGHT * (bait_height/initial(bait_height)), 1)
	experience_multiplier += difficulty * FISHING_SKILL_DIFFIULTY_EXP_MULT
	fishing_hud.hud_bait.adjust_to_difficulty(src)

/// считает сложность и прочие переменные, затем запускает мини-игру
/datum/fishing_challenge/proc/start_minigame_phase(auto_reel = FALSE)
	SEND_SIGNAL(user, COMSIG_MOB_BEGIN_FISHING_MINIGAME, src)
	if(!get_difficulty()) // сложность ноль или ниже, значит победа сразу
		return

	if(difficulty > FISHING_DEFAULT_DIFFICULTY)
		completion -= MAX_FISH_COMPLETION_MALUS * (difficulty * 0.01)

	var/is_fish_instance = isfish(reward_path)

	/// подтягиваем свойства рыбы для мини-игры
	if(ispath(reward_path,/obj/item/fish) || is_fish_instance)
		var/obj/item/fish/fish = reward_path
		var/movement_path = initial(fish.fish_movement_type)
		mover = new movement_path(src)
		// накладываем модификаторы от черт рыбы
		var/list/fish_traits = is_fish_instance ? fish.fish_traits : SSfishing.fish_properties[fish][FISH_PROPERTIES_TRAITS]
		for(var/fish_trait in fish_traits)
			var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait]
			trait.minigame_mod(used_rod, user, src)
	else
		mover = new /datum/fish_movement(src)

	SEND_SIGNAL(src, COMSIG_FISHING_CHALLENGE_MOVER_INITIALIZED, mover)

	if(auto_reel)
		completion *= 1.3
	else
		var/time_left = timeleft(next_phase_timer)
		switch(time_left)
			if(0 to BITING_TIME_WINDOW - 3 SECONDS)
				completion *= 0.65
			if(BITING_TIME_WINDOW - 3 SECONDS to BITING_TIME_WINDOW - 2 SECONDS)
				completion *= 0.82
			if(BITING_TIME_WINDOW - 1 SECONDS to BITING_TIME_WINDOW - 0.5 SECONDS)
				completion *= 1.2
			if(BITING_TIME_WINDOW - 0.5 SECONDS to BITING_TIME_WINDOW)
				completion *= 1.4
	// немного разбрасываем позицию рыбы
	fish_position = rand(0, (FISHING_MINIGAME_AREA - fish_height) * 0.8)
	var/diff_dist = 100 + difficulty
	bait_position = clamp(round(fish_position + rand(-diff_dist, diff_dist) - bait_height * 0.5), 0, FISHING_MINIGAME_AREA - bait_height)

	if(!prepare_minigame_hud())
		get_stack_trace("couldn't prepare minigame hud for a fishing challenge.") // на всякий случай, случиться такого не должно
		qdel(src)
		return

	adjust_to_difficulty()

	phase = MINIGAME_PHASE
	if(next_phase_timer && next_phase_timer != -1)
		deltimer(next_phase_timer)
	if((special_effects & FISHING_MINIGAME_RULE_KILL) && ispath(reward_path, /obj/item/fish))
		var/obj/item/fish/fish = reward_path
		var/wait_time = ((initial(fish.max_integrity) * (1 - initial(fish.integrity_failure))) / FISH_DAMAGE_PER_SECOND) SECONDS
		addtimer(CALLBACK(src, PROC_REF(win_anyway)), wait_time, TIMER_DELETE_ME)
	else if(ismovable(reward_path))
		var/atom/movable/reward = reward_path
		RegisterSignal(reward, COMSIG_MOVABLE_MOVED, PROC_REF(on_reward_removed))
		if(is_fish_instance)
			RegisterSignal(reward, COMSIG_FISH_STATUS_CHANGED, PROC_REF(on_fish_death))
	start_time = world.time

/// выбрасывает стек-трейс с нашим текстом
/datum/fishing_challenge/proc/get_stack_trace(init_text)
	var/text = "[init_text] "
	text += "used rod: [used_rod || "null"], "
	if(used_rod)
		text += "bait: [used_rod.bait || "null"], "
	text += "reward: [reward_path || "null"], "
	text += "user: [user || "null"]"
	if(user)
		if(QDELING(user))
			text += ", user qdeling"
		else if(!user.client)
			text += ", user clientless"
	text += "."
	stack_trace(text)

#undef FISH_DAMAGE_PER_SECOND

/// поднимает HUD мини-игры и вешает нужные сигналы
/datum/fishing_challenge/proc/prepare_minigame_hud()
	if(!user.client || user.stat != CONSCIOUS)
		return FALSE
	. = TRUE
	fishing_hud = new
	fishing_hud.prepare_minigame(src)
	RegisterSignal(user.client, COMSIG_CLIENT_MOUSEDOWN, PROC_REF(start_reeling), override = TRUE)
	RegisterSignal(user.client, COMSIG_CLIENT_MOUSEUP, PROC_REF(stop_reeling), override = TRUE)
	RegisterSignal(user, COMSIG_MOB_LOGOUT, PROC_REF(on_user_logout))
	if(length(active_effects))
		// даём игроку время подготовиться к активным эффектам
		COOLDOWN_START(src, active_effect_cd, rand(5, 9) SECONDS)

/// убирает HUD мини-игры и связанные ссылки
/datum/fishing_challenge/proc/remove_minigame_hud()
	QDEL_NULL(fishing_hud)

/// пока кнопка мыши зажата, приманка ползёт вверх, а по ПКМ вниз, если включено двунаправленное правило
/datum/fishing_challenge/proc/start_reeling(client/source, datum/object, location, control, params)
	SIGNAL_HANDLER
	var/bidirectional = special_effects & FISHING_MINIGAME_RULE_BIDIRECTIONAL
	var/list/modifiers = params2list(params)
	if(bidirectional && LAZYACCESS(modifiers, RIGHT_CLICK))
		reeling_state = REELING_STATE_DOWN
	else
		reeling_state = REELING_STATE_UP

/// отпустили кнопку, приманка снова в покое
/datum/fishing_challenge/proc/stop_reeling(client/source, datum/object, location, control, params)
	SIGNAL_HANDLER
	reeling_state = REELING_STATE_IDLE

/// обновляет рыбу, приманку и HUD
/datum/fishing_challenge/process(seconds_per_tick)
	if(completed)
		return
	if(QDELETED(user) || QDELETED(mover))
		interrupt()
		return
	if(length(active_effects) && COOLDOWN_FINISHED(src, active_effect_cd))
		select_active_effect()
	mover.move_fish(seconds_per_tick)
	move_bait(seconds_per_tick)
	if(!QDELETED(fishing_hud))
		update_visuals(seconds_per_tick)

/// крутит эффекты вроде переворота HUD или искажения движения
/datum/fishing_challenge/proc/select_active_effect()
	/// включаем активный эффект
	if(isnull(current_active_effect))
		current_active_effect = pick(active_effects)
		switch(current_active_effect)
			if(FISHING_MINIGAME_RULE_ANTIGRAV)
				fishing_hud.icon_state = "background_antigrav"
				SEND_SOUND(user, sound('modular_bluemoon/fishing/sound/effects/arcade_jump.ogg', volume = 50))
				COOLDOWN_START(src, active_effect_cd, rand(6, 9) SECONDS)
			if(FISHING_MINIGAME_RULE_FLIP)
				fishing_hud.icon_state = "background_flip"
				fishing_hud.transform = fishing_hud.transform.Scale(1, -1)
				SEND_SOUND(user, sound('modular_bluemoon/fishing/sound/effects/boing.ogg'))
				COOLDOWN_START(src, active_effect_cd, rand(5, 6) SECONDS)
			if(FISHING_MINIGAME_RULE_CAMO)
				fishing_hud.icon_state = "background_camo"
				SEND_SOUND(user, sound('modular_bluemoon/fishing/sound/effects/nightmare_poof.ogg', volume = 15))
				COOLDOWN_START(src, active_effect_cd, rand(6, 8) SECONDS)
				animate(fishing_hud.hud_fish, alpha = 7, time = 2 SECONDS)
		return

	/// возвращаемся к норме
	switch(current_active_effect)
		if(FISHING_MINIGAME_RULE_ANTIGRAV)
			var/sound/inverted_sound = sound('modular_bluemoon/fishing/sound/effects/arcade_jump.ogg', volume = 50)
			inverted_sound.frequency = -1
			SEND_SOUND(user, inverted_sound)
			COOLDOWN_START(src, active_effect_cd, rand(10, 13) SECONDS)
		if(FISHING_MINIGAME_RULE_FLIP)
			fishing_hud.transform = fishing_hud.transform.Scale(1, -1)
			COOLDOWN_START(src, active_effect_cd, rand(8, 12) SECONDS)
		if(FISHING_MINIGAME_RULE_CAMO)
			COOLDOWN_START(src, active_effect_cd, rand(9, 16) SECONDS)
			SEND_SOUND(user, sound('modular_bluemoon/fishing/sound/effects/nightmare_reappear.ogg', volume = 15))
			animate(fishing_hud.hud_fish, alpha = 255, time = 1.2 SECONDS)

	fishing_hud.icon_state = background
	current_active_effect = null

/// двигает приманку, в основном как в старом TGUI
/datum/fishing_challenge/proc/move_bait(seconds_per_tick)
	var/should_bounce = abs(bait_velocity) > BAIT_MIN_VELOCITY_BOUNCE
	bait_position += bait_velocity * seconds_per_tick
	// упёрлись в верхний край
	if(bait_position > FISHING_MINIGAME_AREA - bait_height)
		bait_position = FISHING_MINIGAME_AREA - bait_height
		if(reeling_state == REELING_STATE_UP || !should_bounce)
			bait_velocity = 0
		else
			bait_velocity = -bait_velocity * bait_bounce_mult
	// упёрлись в дно
	else if(bait_position < 0)
		bait_position = 0
		if(reeling_state == REELING_STATE_DOWN || !should_bounce)
			bait_velocity = 0
		else
			bait_velocity = -bait_velocity * bait_bounce_mult

	var/fish_on_bait = (fish_position + fish_height >= bait_position) && (bait_position + bait_height >= fish_position)

	var/bidirectional = special_effects & FISHING_MINIGAME_RULE_BIDIRECTIONAL

	var/velocity_change
	switch(reeling_state)
		if(REELING_STATE_UP)
			velocity_change = reeling_velocity
		if(REELING_STATE_DOWN)
			velocity_change = -reeling_velocity
		if(REELING_STATE_IDLE)
			if(!bidirectional || bait_velocity > 0)
				velocity_change = gravity_velocity
			else
				velocity_change = -gravity_velocity
	velocity_change *= (fish_on_bait ? overlap_velocity_mult : 1) * seconds_per_tick

	velocity_change = round(velocity_change)

	if(current_active_effect == FISHING_MINIGAME_RULE_ANTIGRAV)
		velocity_change = -velocity_change

	if(reeling_state == REELING_STATE_IDLE && (special_effects & FISHING_MINIGAME_AUTOREEL))
		var/bait_center = bait_position + bait_height / 2
		var/auto_adjustment = reeling_velocity * 0.2
		if(fish_position > bait_center)
			velocity_change += auto_adjustment
		else
			velocity_change -= auto_adjustment

	/**
	 * Притормаживаем, если скорость и ускорение смотрят в разные стороны.
	 * Так приманка меньше скользит и слушается лучше.
	 */
	if(bait_velocity > 0 && velocity_change < 0)
		bait_velocity += max(-bait_velocity, velocity_change * deceleration_mult)
	else if(bait_velocity < 0 && velocity_change > 0)
		bait_velocity += min(-bait_velocity, velocity_change * deceleration_mult)

	/// двунаправленная приманка в покое сохраняет плавучесть
	if(bidirectional && reeling_state == REELING_STATE_IDLE)
		if(velocity_change < 0)
			bait_velocity = max(bait_velocity + velocity_change, 0)
		else if(velocity_change > 0)
			bait_velocity = min(bait_velocity + velocity_change, 0)
	else
		bait_velocity += velocity_change

	// проверяем, что рыба всё ещё пересекается с приманкой после движения
	if(fish_on_bait)
		completion += completion_gain * seconds_per_tick
		if(completion >= 100)
			complete(TRUE)
	else
		completion -= completion_loss * seconds_per_tick
		if(completion <= 0 && !(special_effects & FISHING_MINIGAME_RULE_NO_ESCAPE))
			user.balloon_alert(user, "рыба сорвалась!")
			complete(FALSE)

	completion = clamp(completion, 0, 100)

/// двигает рыбу и приманку по вертикали и обновляет полосу прогресса
/datum/fishing_challenge/proc/update_visuals(seconds_per_tick)
	var/bait_offset_mult = bait_position / FISHING_MINIGAME_AREA
	animate(fishing_hud.hud_bait, pixel_z = MINIGAME_SLIDER_HEIGHT * bait_offset_mult, time = seconds_per_tick SECONDS)
	var/fish_offset_mult = fish_position / FISHING_MINIGAME_AREA
	animate(fishing_hud.hud_fish, pixel_z = MINIGAME_SLIDER_HEIGHT * fish_offset_mult, time = seconds_per_tick SECONDS)
	fishing_hud.hud_completion.update_state(completion, seconds_per_tick)

/// экранный объект, к которому привязаны приманка, рыба и полоса прогресса
/atom/movable/screen/fishing_hud
	icon = 'modular_bluemoon/fishing/icons/hud/fishing_hud.dmi'
	screen_loc = "CENTER+1:8,CENTER:2"
	name = "fishing minigame"
	appearance_flags = APPEARANCE_UI|KEEP_TOGETHER
	/// рыба на экране мини-игры
	var/atom/movable/screen/hud_fish/hud_fish
	/// приманка на экране мини-игры
	var/atom/movable/screen/hud_bait/hud_bait
	/// полоса прогресса на экране мини-игры
	var/atom/movable/screen/hud_completion/hud_completion
	var/datum/weakref/master_ref

/// создаёт приманку, рыбу и полосу прогресса и цепляет их к этому экранному объекту
/atom/movable/screen/fishing_hud/proc/prepare_minigame(datum/fishing_challenge/challenge)
	icon_state = challenge.background
	add_overlay(challenge.used_rod?.get_frame(challenge) || "frame_wood")
	hud_bait = new(null, null, challenge)
	hud_fish = new(null, null, challenge)
	hud_completion = new(null, null)
	vis_contents += list(hud_bait, hud_fish, hud_completion)
	challenge.user.client.screen += src
	challenge.update_visuals(0) // выставляем стартовые позиции, чтобы элементы не прыгали на старте
	master_ref = WEAKREF(challenge)

/atom/movable/screen/fishing_hud/Destroy()
	var/datum/fishing_challenge/challenge = master_ref?.resolve()
	if(!isnull(challenge) && challenge.user?.client)
		challenge.user.client.screen -= src
	QDEL_NULL(hud_fish)
	QDEL_NULL(hud_bait)
	QDEL_NULL(hud_completion)
	return ..()

/atom/movable/screen/hud_bait
	icon = 'modular_bluemoon/fishing/icons/hud/fishing_hud.dmi'
	icon_state = "bait_bottom"
	vis_flags = VIS_INHERIT_ID
	var/cur_height = MINIGAME_BAIT_HEIGHT

/atom/movable/screen/hud_bait/Initialize(mapload, datum/hud/hud_owner, datum/fishing_challenge/challenge)
	. = ..()
	if(!challenge || challenge.bait_pixel_height == MINIGAME_BAIT_HEIGHT)
		update_icon()
		return

	adjust_to_difficulty(challenge)

/atom/movable/screen/hud_bait/proc/adjust_to_difficulty(datum/fishing_challenge/challenge)
	cur_height = challenge.bait_pixel_height
	update_icon()

/atom/movable/screen/hud_bait/update_overlays()
	. = ..()
	var/mutable_appearance/bait_top = mutable_appearance(icon, "bait_top")
	bait_top.pixel_z += cur_height - MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT
	. += bait_top
	for (var/i in 1 to (cur_height - MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT))
		var/mutable_appearance/bait_bar = mutable_appearance(icon, "bait_bar")
		bait_bar.pixel_z += i
		. += bait_bar

/atom/movable/screen/hud_fish
	icon = 'modular_bluemoon/fishing/icons/hud/fishing_hud.dmi'
	icon_state = "fish"
	vis_flags = VIS_INHERIT_ID

/atom/movable/screen/hud_fish/Initialize(mapload, datum/hud/hud_owner, datum/fishing_challenge/challenge)
	. = ..()
	if(challenge)
		icon_state = challenge.fish_icon

/atom/movable/screen/hud_completion
	icon = 'modular_bluemoon/fishing/icons/hud/fishing_hud.dmi'
	icon_state = "completion_overlay"
	vis_flags = VIS_INHERIT_ID

/atom/movable/screen/hud_completion/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	add_filter("completion_mask", 1, alpha_mask_filter(icon = icon(icon, "completion_overlay")))

/atom/movable/screen/hud_completion/proc/update_state(completion, seconds_per_tick)
	animate(get_filter("completion_mask"), y = -MINIGAME_COMPLETION_BAR_HEIGHT * (1 - completion * 0.01), time = seconds_per_tick SECONDS)

/// визуал, который всплывает над местом рыбалки
/obj/effect/fishing_float
	name = "float"
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "float"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/**
	 * Пара значений задаёт окно подсечки, в которое надо кликнуть во время рыбалки.
	 * Если он задан, появляется светящийся оверлей, зелёный когда блесну пора подсекать, иначе красный.
	 */
	var/list/spin_frequency
	/// пора ли подсекать блесну
	var/spin_ready = FALSE

/obj/effect/fishing_float/Initialize(mapload, atom/spot)
	. = ..()
	if(!spot)
		return
	if(ismovable(spot)) // поплавок и леска должны оставаться привязанными к месту рыбалки
		RegisterSignal(spot, COMSIG_MOVABLE_MOVED, PROC_REF(follow_movable))
	pixel_x = spot.pixel_x
	pixel_y = spot.pixel_y
	pixel_w = spot.pixel_w
	pixel_z = spot.pixel_z
	// ранний выход для мест с плоскостью ниже нашей. Плоскость пола это topdown, её слои нам не нужны.
	if(spot.plane < plane)
		return
	if(spot.plane > plane) // так поплавок рисуется поверх места рыбалки
		var/turf/turf = get_turf(spot)
		SET_PLANE_EXPLICIT(src, PLANE_TO_TRUE(spot.plane), turf)
	if(spot.layer > layer) // то же самое. При равном слое новое рисуется поверх старого, если память не врёт (с оговорками).
		layer = spot.layer

/obj/effect/fishing_float/proc/follow_movable(atom/movable/source)
	SIGNAL_HANDLER

	set_glide_size(source.glide_size)
	forceMove(source.loc)

/obj/effect/fishing_float/update_overlays()
	. = ..()
	if(!spin_frequency)
		return
	var/mutable_appearance/overlay = mutable_appearance(icon, "lure_light")
	overlay.color = spin_ready ? COLOR_GREEN : COLOR_RED
	. += overlay
	. += emissive_appearance(icon, "lure_light_emissive", alpha = src.alpha, offset_spokesman = src)

#undef WAIT_PHASE
#undef BITING_PHASE
#undef MINIGAME_PHASE

#undef MINIGAME_SLIDER_HEIGHT
#undef MINIGAME_BAIT_HEIGHT
#undef MINIGAME_FISH_HEIGHT
#undef MINIGAME_BAIT_TOP_AND_BOTTOM_HEIGHT
#undef MINIGAME_COMPLETION_BAR_HEIGHT

#undef BAIT_HEIGHT_DIFFICULTY_MALUS

#undef REELING_STATE_IDLE
#undef REELING_STATE_UP
#undef REELING_STATE_DOWN

#undef BAIT_MIN_VELOCITY_BOUNCE

#undef MAX_FISH_COMPLETION_MALUS
#undef BITING_TIME_WINDOW
