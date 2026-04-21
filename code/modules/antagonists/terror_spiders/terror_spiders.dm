/datum/team/terror_spiders
	name = "Terror Spiders"

//Simply lists them.
/datum/team/terror_spiders/roundend_report()
	var/list/parts = list()
	parts += "<span class='header'>The [name] were:</span>"
	parts += printplayerlist(members)
	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/antagonist/terror_spiders
	name = "Terror Spiders"
	job_rank = ROLE_TERROR_SPIDER
	show_in_antagpanel = TRUE
	show_to_ghosts = TRUE
	var/datum/team/terror_spiders/terror_team
	threat = 2

/datum/antagonist/terror_spiders/threat()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/spider = owner?.current
	if(!istype(spider))
		return ..()
	. = 2** spider.spider_tier

/datum/antagonist/terror_spiders/create_team(datum/team/terror_spiders/new_team)
	if(!new_team)
		for(var/datum/antagonist/terror_spiders/S in GLOB.antagonists)
			if(!S.owner || !S.terror_team)
				continue
			terror_team = S.terror_team
			return
		terror_team = new
	else
		if(!istype(new_team))
			CRASH("Wrong terror team type provided to create_team")
		terror_team = new_team

/datum/antagonist/terror_spiders/get_team()
	return terror_team

/datum/antagonist/terror_spiders/proc/addMemories()
	antag_memory += "Я - Паук Ужаса. <font color='red'><B>Мне нужно уничтожить всё живое и разумное за исключением себе подобных</B></font>!<br>"

/datum/antagonist/terror_spiders/on_gain()
	. = ..()
	addMemories()

//Terror
/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/mind_initialize()
	..()
	if(!mind.has_antag_datum(/datum/antagonist/terror_spiders))
		mind.add_antag_datum(/datum/antagonist/terror_spiders)
