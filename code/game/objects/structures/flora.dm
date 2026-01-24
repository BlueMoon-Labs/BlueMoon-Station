/obj/structure/flora
	resistance_flags = FLAMMABLE
	max_integrity = 150
	anchored = TRUE

//trees
/obj/structure/flora/tree
	name = "tree"
	desc = "A large tree."
	density = TRUE
	pixel_x = -16
	layer = FLY_LAYER
	var/log_amount = 10
	var/spawned_wood = /obj/item/grown/log/tree
	var/spawned_stump = /obj/structure/flora/stump

/obj/structure/flora/tree/attackby(obj/item/W, mob/user, params)
	if(log_amount && (!(flags_1 & NODECONSTRUCT_1)))
		if(W.sharpness && W.force > 0)
			if(W.hitsound)
				playsound(get_turf(src), W.hitsound, 100, 0, 0)
			user.visible_message("<span class='notice'>[user] begins to cut down [src] with [W].</span>","<span class='notice'>You begin to cut down [src] with [W].</span>", "You hear the sound of sawing.")
			if(do_after(user, 1000/W.force, target = src)) //5 seconds with 20 force, 8 seconds with a hatchet, 20 seconds with a shard.
				user.visible_message("<span class='notice'>[user] fells [src] with the [W].</span>","<span class='notice'>You fell [src] with the [W].</span>", "You hear the sound of a tree falling.")
				playsound(get_turf(src), 'sound/effects/meteorimpact.ogg', 100 , 0, 0)
				for(var/i=1 to log_amount)
					new spawned_wood(get_turf(src))

				var/obj/structure/flora/stump/S = new spawned_stump(loc)
				S.name = "[name] stump"

				qdel(src)

	else
		return ..()

/obj/structure/flora/stump
	name = "stump"
	desc = "This represents our promise to the crew, and the station itself, to cut down as many trees as possible." //running naked through the trees
	icon = 'icons/obj/flora/pinetrees.dmi'
	icon_state = "tree_stump"
	density = FALSE
	pixel_x = -16
	var/wood_type = /obj/item/grown/log/tree

/obj/structure/flora/stump/attackby(obj/item/W, mob/user, params)
	if((W.tool_behaviour == TOOL_SHOVEL) && params)
		playsound(src, 'sound/effects/shovel_dig.ogg', 50, 1)
		if(do_after(user, 20))
			new wood_type(get_turf(src))
			user.visible_message("[user] digs up [src].", "<span class='notice'>You dig up [src].</span>")
			qdel(src)
	else
		return ..()

/obj/structure/flora/tree/pine
	name = "pine tree"
	desc = "A coniferous pine tree."
	icon = 'icons/obj/flora/pinetrees.dmi'
	icon_state = "pine_1"
	var/list/icon_states = list("pine_1", "pine_2", "pine_3")

/obj/structure/flora/tree/pine/Initialize(mapload)
	. = ..()

	if(islist(icon_states && icon_states.len))
		icon_state = pick(icon_states)

/obj/structure/flora/tree/pine/xmas
	name = "xmas tree"
	desc = "A wondrous decorated Christmas tree."
	icon_state = "pine_c"
	icon_states = null
	resistance_flags = INDESTRUCTIBLE  //Sorry grinch, not this time

/obj/structure/flora/tree/pine/xmas/presents
	icon_state = "pinepresents"
	desc = "A wondrous decorated Christmas tree. It has presents!"
	var/gift_type = /obj/item/a_gift/anything
	var/list/ckeys_that_took = list()

/obj/structure/flora/tree/pine/xmas/presents/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(!user.ckey)
		return

	if(ckeys_that_took[user.ckey])
		to_chat(user, "<span class='warning'>There are no presents with your name on.</span>")
		return
	to_chat(user, "<span class='warning'>After a bit of rummaging, you locate a gift with your name on it!</span>")
	ckeys_that_took[user.ckey] = TRUE
	var/obj/item/G = new gift_type(src)
	user.put_in_hands(G)

/obj/structure/flora/tree/dead
	icon = 'icons/obj/flora/deadtrees.dmi'
	desc = "A dead tree. How it died, you know not."
	icon_state = "tree_1"

/obj/structure/flora/tree/palm
	icon = 'icons/misc/beach2.dmi'
	desc = "A tree straight from the tropics."
	icon_state = "palm1"

/obj/structure/flora/tree/palm/Initialize(mapload)
	. = ..()
	icon_state = pick("palm1","palm2")
	pixel_x = 0

/obj/structure/festivus
	name = "festivus pole"
	icon = 'icons/obj/flora/pinetrees.dmi'
	icon_state = "festivus_pole"
	desc = "During last year's Feats of Strength the Research Director was able to suplex this passing immobile rod into a planter."

/obj/structure/festivus/anchored
	name = "suplexed rod"
	desc = "A true feat of strength, almost as good as last year."
	icon_state = "anchored_rod"
	anchored = TRUE

/obj/structure/flora/tree/dead/Initialize(mapload)
	icon_state = "tree_[rand(1, 6)]"
	. = ..()

/obj/structure/flora/tree/jungle
	name = "tree"
	icon_state = "tree"
	desc = "It's seriously hampering your view of the jungle."
	icon = 'icons/obj/flora/jungletrees.dmi'
	pixel_x = -48
	pixel_y = -20

/obj/structure/flora/tree/jungle/Initialize(mapload)
	icon_state = "[icon_state][rand(1, 6)]"
	. = ..()

/obj/structure/flora/tree/jungle/small
	pixel_y = 0
	pixel_x = -32
	icon = 'icons/obj/flora/jungletreesmall.dmi'

//grass
/obj/structure/flora/grass
	name = "grass"
	desc = "A patch of overgrown grass."
	icon = 'icons/obj/flora/snowflora.dmi'
	gender = PLURAL	//"this is grass" not "this is a grass"

/obj/structure/flora/grass/brown
	icon_state = "snowgrass1bb"

/obj/structure/flora/grass/brown/Initialize(mapload)
	icon_state = "snowgrass[rand(1, 3)]bb"
	. = ..()


/obj/structure/flora/grass/green
	icon_state = "snowgrass1gb"

/obj/structure/flora/grass/green/Initialize(mapload)
	icon_state = "snowgrass[rand(1, 3)]gb"
	. = ..()

/obj/structure/flora/grass/both
	icon_state = "snowgrassall1"

/obj/structure/flora/grass/both/Initialize(mapload)
	icon_state = "snowgrassall[rand(1, 3)]"
	. = ..()


//bushes
/obj/structure/flora/bush
	name = "bush"
	desc = "Some type of shrub."
	icon = 'icons/obj/flora/snowflora.dmi'
	icon_state = "snowbush1"
	anchored = TRUE

/obj/structure/flora/bush/Initialize(mapload)
	icon_state = "snowbush[rand(1, 6)]"
	. = ..()

//newbushes

/obj/structure/flora/ausbushes
	name = "bush"
	desc = "Some kind of plant."
	icon = 'icons/obj/flora/ausflora.dmi'
	icon_state = "firstbush_1"

/obj/structure/flora/ausbushes/Initialize(mapload)
	if(icon_state == "firstbush_1")
		icon_state = "firstbush_[rand(1, 4)]"
	. = ..()

/obj/structure/flora/ausbushes/reedbush
	icon_state = "reedbush_1"

/obj/structure/flora/ausbushes/reedbush/Initialize(mapload)
	icon_state = "reedbush_[rand(1, 4)]"
	. = ..()

/obj/structure/flora/ausbushes/leafybush
	icon_state = "leafybush_1"

/obj/structure/flora/ausbushes/leafybush/Initialize(mapload)
	icon_state = "leafybush_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/palebush
	icon_state = "palebush_1"

/obj/structure/flora/ausbushes/palebush/Initialize(mapload)
	icon_state = "palebush_[rand(1, 4)]"
	. = ..()

/obj/structure/flora/ausbushes/stalkybush
	icon_state = "stalkybush_1"

/obj/structure/flora/ausbushes/stalkybush/Initialize(mapload)
	icon_state = "stalkybush_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/grassybush
	icon_state = "grassybush_1"

/obj/structure/flora/ausbushes/grassybush/Initialize(mapload)
	icon_state = "grassybush_[rand(1, 4)]"
	. = ..()

/obj/structure/flora/ausbushes/fernybush
	icon_state = "fernybush_1"

/obj/structure/flora/ausbushes/fernybush/Initialize(mapload)
	icon_state = "fernybush_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/sunnybush
	icon_state = "sunnybush_1"

/obj/structure/flora/ausbushes/sunnybush/Initialize(mapload)
	icon_state = "sunnybush_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/genericbush
	icon_state = "genericbush_1"

/obj/structure/flora/ausbushes/genericbush/Initialize(mapload)
	icon_state = "genericbush_[rand(1, 4)]"
	. = ..()

/obj/structure/flora/ausbushes/pointybush
	icon_state = "pointybush_1"

/obj/structure/flora/ausbushes/pointybush/Initialize(mapload)
	icon_state = "pointybush_[rand(1, 4)]"
	. = ..()

/obj/structure/flora/ausbushes/lavendergrass
	icon_state = "lavendergrass_1"

/obj/structure/flora/ausbushes/lavendergrass/Initialize(mapload)
	icon_state = "lavendergrass_[rand(1, 4)]"
	. = ..()

/obj/structure/flora/ausbushes/ywflowers
	icon_state = "ywflowers_1"

/obj/structure/flora/ausbushes/ywflowers/Initialize(mapload)
	icon_state = "ywflowers_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/brflowers
	icon_state = "brflowers_1"

/obj/structure/flora/ausbushes/brflowers/Initialize(mapload)
	icon_state = "brflowers_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/ppflowers
	icon_state = "ppflowers_1"

/obj/structure/flora/ausbushes/ppflowers/Initialize(mapload)
	icon_state = "ppflowers_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/sparsegrass
	icon_state = "sparsegrass_1"

/obj/structure/flora/ausbushes/sparsegrass/Initialize(mapload)
	icon_state = "sparsegrass_[rand(1, 3)]"
	. = ..()

/obj/structure/flora/ausbushes/fullgrass
	icon_state = "fullgrass_1"

/obj/structure/flora/ausbushes/fullgrass/Initialize(mapload)
	icon_state = "fullgrass_[rand(1, 3)]"
	. = ..()

/obj/item/kirbyplants
	name = "potted plant"
	icon = 'icons/obj/flora/plants.dmi'
	icon_state = "plant-01"
	desc = "A little bit of nature contained in a pot."
	layer = ABOVE_MOB_LAYER
	w_class = WEIGHT_CLASS_HUGE
	force = 10
	throwforce = 13
	throw_speed = 2
	throw_range = 4

/obj/item/kirbyplants/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/tactical)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, _AddElement), list(/datum/element/beauty, 500)), 0)
	AddComponent(/datum/component/two_handed, require_twohands=TRUE, force_unwielded=10, force_wielded=10)
	// BLUEMOON ADD предметы в кустах
	AddComponent(/datum/component/storage/concrete/pockets/plants)
	// BLUEMOON ADD END

//BLUEMOON ADD прикрутить кусты, открутить кусты
/obj/item/kirbyplants/wrench_act(mob/living/user, obj/item/I)
	default_unfasten_wrench(user, I)
	return TRUE

/obj/item/kirbyplants/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		switch(anchored)
			if(TRUE)
				if(user.a_intent == INTENT_GRAB)
					var/x_shift = 0
					x_shift = input(user, "Set x shift (-16 to 16)", "Set shift", 0) as num
					x_shift = clamp(x_shift, -16, 16)
					var/y_shift = 0
					y_shift = input(user, "Set y shift (-16 to 16)", "Set shift", 0) as num
					y_shift = clamp(y_shift, -16, 16)
					if(anchored && user.CanReach(src))
						pixel_x = x_shift
						pixel_y = y_shift
			if(FALSE)
				pixel_x = 0
				pixel_y = 0

/obj/item/kirbyplants/examine(mob/user)
	. = ..()
	. += span_notice("Вы можете посмотреть что под ним при помощи <b>Alt+Click</b>.")
	if(in_range(user, src))
		if(anchored)
			. += "<span class='notice'>It is <b>bolted</b> to the ground.</span>"
		else
			. += "<span class='notice'>It is can be <b>bolted</b> to the ground. </b> On grab intent can be precise placed.</span>"
//BLUEMOON ADD END

/obj/item/kirbyplants/random
	icon = 'icons/obj/flora/_flora.dmi'
	icon_state = "random_plant"
	var/list/static/states

/obj/item/kirbyplants/random/Initialize(mapload)
	. = ..()
	icon = 'icons/obj/flora/plants.dmi'
	if(!states)
		generate_states()
	icon_state = pick(states)

/obj/item/kirbyplants/Initialize(mapload)
	. = ..()
	if(!mapload)
		return
	var/static/list/random_stuff = list(
		/obj/item/reagent_containers/syringe/heroin = 5,
		/obj/item/toy/plush/teddybear = 5,
		/obj/item/reagent_containers/pill/labebium = 1,
		/obj/item/reagent_containers/food/snacks/grown/mushroom/schizoshroom = 5,
		/obj/item/toy/plush/bm/millie = 5,
		/obj/item/genital_equipment/condom = 10,
		/obj/item/assembly/mousetrap/armed = 5,
		/obj/item/reagent_containers/food/snacks/special_candy = 5,
		/obj/item/buttplug/small = 5,
		/obj/item/reagent_containers/food/snacks/donut/semen = 10,
		/obj/item/reagent_containers/glass/bottle/semen = 1,
		/obj/item/restraints/handcuffs/fake/kinky = 10,
		/obj/item/reagent_containers/pill/pendosovka = 5,
		/obj/item/reagent_containers/pill/zvezdochka = 5,
		/obj/item/reagent_containers/food/snacks/cube/tentacles = 5,
		/obj/item/clothing/underwear/briefs/tentacle/female = 1,
		/obj/item/seeds/cannabis = 5,
		/obj/item/reagent_containers/syringe/contraband/methamphetamine = 1,
		/obj/item/reagent_containers/pill/lsd = 5,
		/obj/item/reagent_containers/pill/mdma = 5,
		/obj/item/mod/construction/broken_core = 5,
		/obj/item/trash/candy = 10,
		/obj/item/trash/syndi_cakes = 5,
		/obj/item/trash/candle = 10,
		/obj/item/soap = 10,
		/mob/living/simple_animal/pet/dog/corgi/puppy/slime = 1,
		/obj/item/slime_cookie/pink = 5,
		/obj/item/clothing/mask/cigarette/shadyjims = 5,
		/obj/item/clothing/head/kitty = 5,
		/obj/item/reagent_containers/food/snacks/intecookies = 5,
		/obj/item/binoculars = 1,
		/obj/structure/sign/poster/contraband/paws = 5,
		/obj/item/restraints/legcuffs/bola/energy = 1,
		/obj/item/stack/medical/suture/five = 5,
		/obj/item/sign/flag/rus = 1, // Пасхалко
		/obj/item/toy/figure/inteq = 1,
		/obj/item/reagent_containers/food/snacks/chips = 5)
	if(prob(40))
		var/picked = pickweight(random_stuff)
		new picked(src)

/obj/item/kirbyplants/random/proc/generate_states()
	states = list()
	for(var/i in 1 to 34)
		var/number
		if(i < 10)
			number = "0[i]"
		else
			number = "[i]"
		states += "plant-[number]"
	states += "applebush"


/obj/item/kirbyplants/dead
	name = "RD's potted plant"
	desc = "A gift from the botanical staff, presented after the RD's reassignment. There's a tag on it that says \"Y'all come back now, y'hear?\"\nIt doesn't look very healthy..."
	icon_state = "plant-25"

/obj/item/kirbyplants/photosynthetic
	name = "photosynthetic potted plant"
	desc = "A bioluminescent plant."
	icon_state = "plant-09"
	light_color = "#2cb2e8"
	light_range = 3


//a rock is flora according to where the icon file is
//and now these defines

/obj/structure/flora/rock
	icon_state = "basalt"
	desc = "A volcanic rock. Pioneers used to ride these babies for miles."
	icon = 'icons/obj/flora/rocks.dmi'
	resistance_flags = FIRE_PROOF
	density = TRUE
	/// Itemstack that is dropped when a rock is mined with a pickaxe
	var/obj/item/stack/mineResult = /obj/item/stack/ore/glass/basalt
	/// Amount of the itemstack to drop
	var/mineAmount = 20

/obj/structure/flora/rock/Initialize(mapload)
	. = ..()
	icon_state = "[icon_state][rand(1,3)]"

/obj/structure/flora/rock/attackby(obj/item/W, mob/user, params)
	if(!mineResult || W.tool_behaviour != TOOL_MINING)
		return ..()
	if(flags_1 & NODECONSTRUCT_1)
		return ..()
	to_chat(user, "<span class='notice'>You start mining...</span>")
	if(W.use_tool(src, user, 40, volume=50))
		to_chat(user, "<span class='notice'>You finish mining the rock.</span>")
		if(mineResult && mineAmount)
			new mineResult(get_turf(src), mineAmount)
		SSblackbox.record_feedback("tally", "pick_used_mining", 1, W.type)
		qdel(src)

/obj/structure/flora/rock/pile
	icon_state = "lavarocks"
	desc = "A pile of rocks."
	density = FALSE //BLUEMOON ADD это реально куча косточек на полу, оно проходимо по всей логике

//Jungle grass

/obj/structure/flora/grass/jungle
	name = "jungle grass"
	desc = "Thick alien flora."
	icon = 'icons/obj/flora/jungleflora.dmi'
	icon_state = "grassa"


/obj/structure/flora/grass/jungle/Initialize(mapload)
	icon_state = "[icon_state][rand(1, 5)]"
	. = ..()

/obj/structure/flora/grass/jungle/b
	icon_state = "grassb"

//Jungle rocks

/obj/structure/flora/rock/jungle
	icon_state = "pile of rocks"
	desc = "A pile of rocks."
	icon_state = "rock"
	icon = 'icons/obj/flora/jungleflora.dmi'
	density = FALSE

/obj/structure/flora/rock/jungle/Initialize(mapload)
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,5)]"


//Jungle bushes

/obj/structure/flora/junglebush
	name = "bush"
	desc = "A wild plant that is found in jungles."
	icon = 'icons/obj/flora/jungleflora.dmi'
	icon_state = "busha"

/obj/structure/flora/junglebush/Initialize(mapload)
	icon_state = "[icon_state][rand(1, 3)]"
	. = ..()

/obj/structure/flora/junglebush/b
	icon_state = "bushb"

/obj/structure/flora/junglebush/c
	icon_state = "bushc"

/obj/structure/flora/junglebush/large
	icon_state = "bush"
	icon = 'icons/obj/flora/largejungleflora.dmi'
	pixel_x = -16
	pixel_y = -12
	layer = ABOVE_ALL_MOB_LAYER

/obj/structure/flora/rock/pile/largejungle
	name = "rocks"
	icon_state = "rocks"
	icon = 'icons/obj/flora/largejungleflora.dmi'
	density = FALSE
	pixel_x = -16
	pixel_y = -16

/obj/structure/flora/rock/pile/largejungle/Initialize(mapload)
	. = ..()
	icon_state = "[initial(icon_state)][rand(1,3)]"
