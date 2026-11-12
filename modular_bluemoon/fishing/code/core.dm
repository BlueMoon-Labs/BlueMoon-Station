// ядро модуля, звуки снастей, навык рыбалки и достижения


// ключи звуков, которые использует модуль рыбалки
/datum/sound_effect/default_fish_slap
	key = SFX_DEFAULT_FISH_SLAP
	file_paths = list('modular_bluemoon/fishing/sound/mobs/non-humanoids/fish/fish_slap1.ogg')

/datum/sound_effect/alt_fish_slap
	key = SFX_ALT_FISH_SLAP
	file_paths = list('modular_bluemoon/fishing/sound/mobs/non-humanoids/fish/fish_slap2.ogg')

/datum/sound_effect/fish_pickup
	key = SFX_FISH_PICKUP
	file_paths = list(
		'modular_bluemoon/fishing/sound/mobs/non-humanoids/fish/fish_pickup1.ogg',
		'modular_bluemoon/fishing/sound/mobs/non-humanoids/fish/fish_pickup2.ogg',
	)


/datum/skill/level/fishing
	name = "Fishing"
	desc = "Ваше мастерство рыбалки: от наживки до вываживания. Высокие уровни упрощают мини-игру и увеличивают дальность заброса."
	name_color = COLOR_PALE_BLUE_GRAY
	skill_traits = list(SKILL_SANITY, SKILL_INTELLIGENCE, SKILL_USE_TOOL, SKILL_TRAINING_TOOL)
	ui_category = SKILL_UI_CAT_MISC
	standard_xp_lvl_up = 100


// достижения рыбалки и прогресс рыбного декса
#ifndef MEDAL_LEGENDARY_FISHER
#define MEDAL_LEGENDARY_FISHER "Legendary Fisher"
#endif
#ifndef FISH_SCORE
#define FISH_SCORE "Fish Score"
#endif

/datum/award/achievement/skill/legendary_fisher
	name = "Legendary fisher"
	desc = "Дайте космонавту рыбу - и он сыт недолго; научите космонавта рыбачить - и он сыт до шаттла."
	database_id = MEDAL_LEGENDARY_FISHER
	icon = "fishing_hat"

/datum/award/score/progress/fish
	name = "Fish Species Caught"
	desc = "Сколько разных видов рыбы вы поймали. Поймайте их всех."
	database_id = FISH_SCORE
	default_value = list()
	track_high_scores = FALSE

/datum/award/score/progress/fish/parse_value(raw_value)
	if(islist(raw_value))
		var/list/raw_list = raw_value
		return raw_list.Copy()
	if(!istext(raw_value) || !length(raw_value))
		return list()
	return splittext(raw_value, ",")

/datum/award/score/progress/fish/load(key)
	var/list/result = ..()
	return islist(result) ? result.Copy() : list()

/datum/award/score/progress/fish/get_changed_rows(key, value)
	var/serialized = islist(value) ? jointext(value, ",") : ""
	return ..(key, serialized)

/datum/award/score/progress/fish/get_metadata_row()
	. = ..()
	.["achievement_type"] = "score"

/proc/award_fish_caught(mob/user, fish_id, fish_name)
	if(!user?.client || !fish_id)
		return
	var/list/already_caught = user.client.get_award_status(/datum/award/score/progress/fish)
	if(islist(already_caught) && (fish_id in already_caught))
		return
	user.client.give_award(/datum/award/score/progress/fish, user, fish_id)
	to_chat(user, span_nicegreen("This is the first time you've caught a <b>[fish_name || fish_id]</b>!"))
