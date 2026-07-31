/datum/interaction/lewd/unholy/hard/do_facefart
	description = "Напердеть на лицо."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "на его лицо напердел"
	write_log_user = "перданул на лицо"

/datum/interaction/lewd/unholy/hard/do_facefart/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.do_facefart(target, is_hidden)

/datum/interaction/lewd/unholy/hard/do_crotchfart
	description = "Напердеть на промежность."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "на его промежность напердел"
	write_log_user = "перданул на промежность"

/datum/interaction/lewd/unholy/hard/do_crotchfart/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.do_crotchfart(target, is_hidden)

/datum/interaction/lewd/unholy/hard/do_fartfuck
	description = "Трахнуть в задницу с пердежом."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "был(а) трахнут(а) в задницу с пердежом"
	write_log_user = "трахнул(а) в задницу с пердежом"

/datum/interaction/lewd/unholy/hard/do_fartfuck/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.do_fartfuck(target, is_hidden)

	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\ Задница <b>[target]</b> смешно хонкает!</span>")

	playlewdinteractionsound(get_turf(target), 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/unholy/hard/suck_fart
	description = "Высосать газы из задницы ртом."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его газы высосал из задницы"
	write_log_user = "высосал газы из задницы"

/datum/interaction/lewd/unholy/hard/suck_fart/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.suck_fart(target, is_hidden)
