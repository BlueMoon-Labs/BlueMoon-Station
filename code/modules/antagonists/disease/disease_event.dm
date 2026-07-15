
/datum/round_event_control/sentient_disease
	name = "Spawn Sentient Disease"
	typepath = /datum/round_event/ghost_role/sentient_disease
	weight = 10
	max_occurrences = 1
	// Лёгкая фоновая гост-угроза для раннего разнообразия: чтобы первые полчаса гост-пул не сводился
	// к одному Devil (единственный лёгкий гост-рулсет без earliest_start), пара дешёвых гост-событий
	// доступна с 20-й минуты наравне с ним.
	earliest_start = 20 MINUTES
	min_players = 5
	category = EVENT_CATEGORY_HEALTH
	severity = DIRECTOR_SEVERITY_GHOST // антаг из призраков - гост-пул, а не MODERATE от категории
	cost = 8
	intensity = 10 // медленная фоновая угроза, лечится вирусологией
	director_ghost_jobban = ROLE_ALIEN
	director_ghost_preference = ROLE_ALIEN
	family = "sentient_disease" // с рулсетом-двойником динамика: не подряд
	// Не экста и не Light: цель болезни - заражать экипаж, а мягкие профили оставляем
	// к экипажу антагов (враждебное - по запросу через OPFOR/администрацию).
	required_round_type = list(ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_TEAMBASED)
	description = "Spawns a sentient disease, who wants to infect as many people as possible."

/datum/round_event/ghost_role/sentient_disease
	role_name = "sentient disease"

/datum/round_event/ghost_role/sentient_disease/spawn_role()
	var/list/candidates = get_candidates(ROLE_ALIEN, null, ROLE_ALIEN)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/observer/selected = pick_n_take(candidates)

	var/mob/camera/disease/virus = new /mob/camera/disease(SSmapping.get_station_center())
	selected.transfer_ckey(virus, FALSE)
	INVOKE_ASYNC(virus, TYPE_PROC_REF(/mob/camera/disease, pick_name))
	message_admins("[ADMIN_LOOKUPFLW(virus)] has been made into a sentient disease by an event.")
	log_game("[key_name(virus)] was spawned as a sentient disease by an event.")
	spawned_mobs += virus
	return SUCCESSFUL_SPAWN
