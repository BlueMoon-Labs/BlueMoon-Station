/datum/reagent/psyshillium
	name = "psyshillium spores"
	reagent_state = GAS
	description = ""
	color = "#4E3259"
	taste_description = "crazy"
	overdose_threshold = 150
	metabolization_rate = 0.25




/datum/reagent/psyshillium/on_mob_metabolize(mob/living/M)
	sleep(rand(100,600))
	var/sound/sound = sound(pick('modular_bluemoon/sound/hallucinations/shizoshroom/Gazeblya1.ogg','modular_bluemoon/sound/hallucinations/shizoshroom/Gazeblya2.ogg', \
	'modular_bluemoon/sound/hallucinations/shizoshroom/Gazeblya3.ogg'), TRUE)
	sound.environment = 35
	sound.volume = 75
	SEND_SOUND(M.client, sound)
	M.sound_environment_override = SOUND_ENVIRONMENT_DRUGGED
	M.playsound_local(M, 'modular_bluemoon/sound/hallucinations/shizoshroom/mechsound.ogg', 100, FALSE)
	M.overlay_fullscreen("depression", /atom/movable/screen/fullscreen/scaled/depression, 3)
	M.clear_fullscreen("depression", 3000)
	M.overlay_fullscreen("dark", /atom/movable/screen/fullscreen/scaled/oxy, 6)
	if(M.client)
		M.add_client_colour(/datum/client_colour/psyshillium)
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		var/list/screens = list(C.hud_used.get_game_screen_plate())
		var/matrix/skew = matrix()
		skew.Scale(2)
		var/matrix/newmatrix = skew
		for(var/whole_screen in screens)
			animate(whole_screen, transform = newmatrix, time = 2, easing = QUAD_EASING, loop = -1)
			animate(transform = -newmatrix, time = 2, easing = QUAD_EASING)

	var/atom/movable/plane_master_controller/game_plane_master_controller = M.hud_used.plane_master_controllers[PLANE_MASTERS_GAME]

	game_plane_master_controller.add_filter("psihota", 1, list("type" = "wave", "size" = 2, "x" = 32, "y" = 32))

	for(var/filter in game_plane_master_controller.get_filters("psihota"))
		animate(filter, time = 256 SECONDS, loop = -1, easing = LINEAR_EASING, offset = 32, flags = ANIMATION_PARALLEL)


/datum/reagent/psyshillium/on_mob_life(mob/living/carbon/M)
	if(prob(1))
		M.emote(pick("pain","realagony"))
		M.playsound_local(M, 'modular_bluemoon/sound/hallucinations/shizoshroom/mechsound.ogg', 100, FALSE)
		M.overlay_fullscreen("FUCK", /atom/movable/screen/fullscreen/wakeup)
		M.clear_fullscreen("FUCK", 20)
	if(prob(5))
		M.playsound_local(M, 'modular_bluemoon/sound/hallucinations/shizoshroom/mechsound.ogg', 100, FALSE)
		M.overlay_fullscreen("staticeffect", /atom/movable/screen/fullscreen/staticeffect)
		M.clear_fullscreen("staticeffect", 20)
	..()


/datum/reagent/psyshillium/on_mob_end_metabolize(mob/living/M)
	if(M.client)
		M.remove_client_colour(/datum/client_colour/psyshillium)
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		var/list/screens = list(C.hud_used.get_game_screen_plate())
		for(var/whole_screen in screens)
			animate(whole_screen, transform = matrix(), time = 5, easing = QUAD_EASING)
	to_chat(M, "<span class='danger'>I feel mentally retarded</span>")
	M.playsound_local(M, 'modular_bluemoon/sound/hallucinations/shizoshroom/mechsound.ogg', 100, FALSE)
	M.SetSleeping(100)
	M.clear_fullscreen("depression")
	M.clear_fullscreen("dark")
	var/atom/movable/plane_master_controller/game_plane_master_controller = M.hud_used.plane_master_controllers[PLANE_MASTERS_GAME]
	game_plane_master_controller.remove_filter("psihota")
	DIRECT_OUTPUT(M.client, sound(null))


/datum/reagent/psyshillium/overdose_process(mob/living/carbon/M)
	M.adjustToxLoss(10, 0)
	if(prob(10))
		if(M.can_heartattack())
			M.set_heartattack(TRUE)




/atom/movable/screen/fullscreen/wakeup
	icon = 'modular_bluemoon/icons/screen/drug_fullscreen.dmi'
	screen_loc = "CENTER-7,SOUTH"
	icon_state = "wake_up"


/atom/movable/screen/fullscreen/staticeffect
	icon = 'modular_bluemoon/icons/screen/drug_fullscreen.dmi'
	screen_loc = "CENTER-7,SOUTH"
	icon_state = "wake_up1"
	var/size_x = 15
	var/size_y = 15




/datum/client_colour/psyshillium
	colour = list(1.2,0,0,0, 0.3,0,0,0, 0.15,0,0,0, 0,0,0,1, -0.100,0,0,-0.15)
	priority = 6




/obj/item/seeds/schizoshroom
	name = "pack of podrakovinik mycelium"
	desc = "This mycelium grows into podrakovinik mushrooms."
	icon = 'modular_bluemoon/icons/obj/moredrugs.dmi'
	icon_state = "mycelium-podrakovinik"
	species = "podrakovinik"
	plantname = "podrakovinik"
	product = /obj/item/reagent_containers/food/snacks/grown/mushroom/schizoshroom
	maturation = 7
	production = 1
	yield = 5
	potency = 15
	growthstages = 3
	genes = list(/datum/plant_gene/trait/plant_type/fungal_metabolism)
	growing_icon = 'modular_bluemoon/icons/obj/moredrugs.dmi'
	reagents_add = list(/datum/reagent/psyshillium = 0.15, /datum/reagent/consumable/nutriment = 0.02)

/obj/item/reagent_containers/food/snacks/grown/mushroom/schizoshroom
	seed = /obj/item/seeds/schizoshroom
	name = "Podrakovinik"
	desc = "Те самые грибы, которые растут в общественных туалетах."
	icon = 'modular_bluemoon/icons/obj/moredrugs.dmi'
	icon_state = "podrakovinik"
	filling_color = "#DAA520"
	wine_power = 80
