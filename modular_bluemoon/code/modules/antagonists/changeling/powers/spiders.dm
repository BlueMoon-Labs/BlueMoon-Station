/// Override — fleshborne spider egg clusters (TG/Skyrat-style infestation).

/obj/structure/spider/eggcluster/changeling_flesh
	player_spiders = TRUE
	directive = "Tear apart whatever moves."

/datum/action/changeling/spiders/sting_action(mob/user)
	..()
	new /obj/structure/spider/eggcluster/changeling_flesh(user.drop_location())
	return TRUE
