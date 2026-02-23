/mob/living/simple_animal/hostile/skeleton/alive_bones
	name = "torn-out skeleton"
	maxHealth = 300
	health = 300
	faction = list("skeleton", "wizard")
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/hostile/skeleton/alive_bones/proc/set_mage_servant(mob/living/mage)
	set waitfor = FALSE

	var/list/candidates = pollCandidatesForMob("Do you want to play as a [name]?", ROLE_ALIEN, null, ROLE_ALIEN, 5 SECONDS, src)
	if(!LAZYLEN(candidates))
		return
	var/mob/M = pick(candidates)
	if(!M.client)
		return

	src.key = M.client.ckey

	src.mind.assigned_role = "Alive Bones"
	src.mind.special_role = "alive_bones"

	var/datum/antagonist/alive_bones/bones_antag = new
	var/datum/antagonist/wizard/master_wizard = mage?.mind.has_antag_datum(/datum/antagonist/wizard)
	if(master_wizard)
		if(!master_wizard.wiz_team)
			master_wizard.create_wiz_team()
		bones_antag.wiz_team = master_wizard.wiz_team
		master_wizard.wiz_team.add_member(src.mind)
	src.mind.add_antag_datum(bones_antag)

/datum/antagonist/alive_bones
	name = "Alive Bones"
	antagpanel_category = "Other"
	antag_hud_name = "alive_bones"
	antag_hud_type = ANTAG_HUD_WIZ
	job_rank = ROLE_MINOR_ANTAG
	show_to_ghosts = TRUE
	var/datum/team/wizard/wiz_team
	var/const/intro_text = "Вы вырванный из тела и оживленный некромантией скелет. Вы должны повиноваться магам и защищать их."

/datum/antagonist/alive_bones/greet()
	. = ..()
	to_chat(owner, "<center><span class='userdanger'>Вы вырванный из тела скелет!</span></center>")
	to_chat(owner, "<center><span class='big'>[intro_text]</span></center><br>")
	SEND_SOUND(owner, sound('sound/magic/Mutate.ogg'))

/datum/antagonist/alive_bones/get_team()
	return wiz_team

/datum/antagonist/alive_bones/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, M)

/datum/antagonist/alive_bones/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	remove_antag_hud(antag_hud_type, M)
