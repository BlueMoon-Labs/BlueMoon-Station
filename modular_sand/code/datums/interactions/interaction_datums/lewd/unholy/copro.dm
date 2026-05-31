/datum/interaction/lewd/unholy/do_faceshit
	description = "Насрать на лицо."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его лицо было обосрано"
	write_log_user = "насрал на лицо"

/datum/interaction/lewd/unholy/do_faceshit/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.do_faceshit(target, is_hidden)

/datum/interaction/lewd/unholy/do_crotchshit/
	description = "Насрать на промежность."
	required_from_target_exposed = NONE
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его промежность была обосрана"
	write_log_user = "насрал на промежность"

/datum/interaction/lewd/unholy/do_crotchshit/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.do_crotchshit(target, is_hidden)

/datum/interaction/lewd/unholy/do_shitfuck
	description = "Трахнуть в задницу с говнецом."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user_exposed = INTERACTION_REQUIRE_PENIS
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "трахнут в задницу с говнецом"
	write_log_user = "трахнул в задницу с говнецом"

/datum/interaction/lewd/unholy/do_shitfuck/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.do_shitfuck(target, is_hidden)

	if(!(isclownjob(target) || isclownjob(user)))
		return

	if(prob(50) && isclownjob(target))
		target.visible_message("<span class='lewd'>\ Жопа <b>[target]</b>забавно хонкает!</span>")

	playlewdinteractionsound(get_turf(target), 'sound/items/bikehorn.ogg', 40, 1, -1)

/datum/interaction/lewd/unholy/suck_shit
	description = "Высосать говно из задницы."
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	required_from_target_unexposed = NONE
	required_from_user = INTERACTION_REQUIRE_MOUTH
	required_from_user_unexposed = NONE
	max_distance = 1
	interaction_sound = null
	write_log_target = "его говно высосал из задницы"
	write_log_user = "высосал говно из задницы"

/datum/interaction/lewd/unholy/suck_shit/display_interaction(mob/living/user, mob/living/target, is_hidden)
	user.suck_shit(target, is_hidden)
