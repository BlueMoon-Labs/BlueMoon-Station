/obj/structure/reagent_dispensers
	name = "Dispenser"
	desc = "..."
	icon = 'icons/obj/objects.dmi'
	icon_state = "water"
	density = TRUE
	anchored = FALSE
	pressure_resistance = 2*ONE_ATMOSPHERE
	max_integrity = 300
	var/tank_volume = 1000 //In units, how much the dispenser can hold
	var/reagent_id = /datum/reagent/water //The ID of the reagent that the dispenser uses

/obj/structure/reagent_dispensers/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && obj_integrity > 0)
		if(tank_volume && (damage_flag == BULLET || damage_flag == LASER))
			boom()

/obj/structure/reagent_dispensers/attackby(obj/item/W, mob/user, params)
	if(W.is_refillable())
		return FALSE //so we can refill them via their afterattack.
	else
		return ..()

/obj/structure/reagent_dispensers/Initialize(mapload)
	create_reagents(tank_volume, DRAINABLE | AMOUNT_VISIBLE)
	if(reagent_id)
		reagents.add_reagent(reagent_id, tank_volume)
	. = ..()

// BLUEMOON ADD START
/obj/structure/reagent_dispensers/examine(mob/user)
	. = ..()
	if(anchored)
		. += span_notice("It is <b>bolted</b> to the floor.")

/obj/structure/reagent_dispensers/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(density)
		default_unfasten_wrench(user, I)
		return TRUE
// BLUEMOON ADD END

//BLUEMOON CHANGE - FUELTANK
/obj/structure/reagent_dispensers/proc/boom()
	var/datum/reagent/fuel/volatiles = reagents.has_reagent(/datum/reagent/fuel)
	var/fuel_amt = 0
	if(istype(volatiles) && volatiles.volume >= 25)
		fuel_amt = volatiles.volume
		reagents.del_reagent(/datum/reagent/fuel) // not actually used for the explosion
	if(reagents.total_volume)
		if(!fuel_amt)
			visible_message(span_danger("\The [src] ruptures!"))
		// Leave it up to future terrorists to figure out the best way to mix reagents with fuel for a useful boom here
		chem_splash(loc, 2 + (reagents.total_volume + fuel_amt) / 1000, list(reagents), extra_heat=(fuel_amt / 50), adminlog=(fuel_amt<25))

	if(fuel_amt) // with that done, actually explode
		visible_message(span_danger("\The [src] explodes!"))
		// old code for reference:
		// standard fuel tank = 1000 units = heavy_impact_range = 1, light_impact_range = 5, flame_range = 5
		// big fuel tank = 5000 units = devastation_range = 1, heavy_impact_range = 2, light_impact_range = 7, flame_range = 12
		// It did not account for how much fuel was actually in the tank at all, just the size of the tank.
		// I encourage others to better scale these numbers in the future.
		// As it stands this is a minor nerf in exchange for an easy bombing technique working that has been broken for a while.
		switch(volatiles.volume)
			if(25 to 150)
				explosion(src, light_impact_range = 1, flame_range = 2)
			if(150 to 300)
				explosion(src, light_impact_range = 2, flame_range = 3)
			if(300 to 750)
				explosion(src, heavy_impact_range = 1, light_impact_range = 3, flame_range = 5)
			if(750 to 1500)
				explosion(src, heavy_impact_range = 1, light_impact_range = 4, flame_range = 6)
			if(1500 to INFINITY)
				explosion(src, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 6, flame_range = 8)
	qdel(src)

/obj/structure/reagent_dispensers/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(!disassembled)
			boom()
	else
		qdel(src)

///////////////
//Water Tanks//
///////////////

/obj/structure/reagent_dispensers/watertank
	name = "water tank"
	desc = "A water tank."
	icon_state = "water"

/obj/structure/reagent_dispensers/watertank/high
	name = "high-capacity water tank"
	desc = "A highly pressurized water tank made to hold gargantuan amounts of water."
	icon_state = "water_high" //I was gonna clean my room...
	tank_volume = 3000

/obj/structure/reagent_dispensers/watertank/holy
	name = "BIG HOLY FLASK"
	desc = "A VERY large and VERY holy flask, pure holy waterness!"
	icon_state = "holyflask"
	reagent_id = /datum/reagent/water/holywater
	layer = ABOVE_ALL_MOB_LAYER // Big sprite

/obj/structure/reagent_dispensers/watertank/holy/Initialize(mapload)
	. = ..()
	var/const/scale = 2
	var/matrix/m = matrix()
	m.Scale(scale)
	// смещаем спрайт вверх
	var/shift = (scale - 1) * 16
	m.Translate(0, shift)
	transform = m

/obj/structure/reagent_dispensers/foamtank
	name = "firefighting foam tank"
	desc = "A tank full of firefighting foam."
	icon_state = "foam"
	reagent_id = /datum/reagent/firefighting_foam
	tank_volume = 500

/obj/structure/reagent_dispensers/water_cooler
	name = "liquid cooler"
	desc = "A machine that dispenses liquid to drink."
	icon = 'icons/obj/vending.dmi'
	icon_state = "water_cooler"
	anchored = TRUE
	tank_volume = 500
	var/paper_cups = 25 //Paper cups left from the cooler

/obj/structure/reagent_dispensers/water_cooler/examine(mob/user)
	. = ..()
	if (paper_cups > 1)
		. += "There are [paper_cups] paper cups left."
	else if (paper_cups == 1)
		. += "There is one paper cup left."
	else
		. += "There are no paper cups left."

/obj/structure/reagent_dispensers/water_cooler/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(!paper_cups)
		to_chat(user, "<span class='warning'>There aren't any cups left!</span>")
		return
	user.visible_message("<span class='notice'>[user] takes a cup from [src].</span>", "<span class='notice'>You take a paper cup from [src].</span>")
	var/obj/item/reagent_containers/food/drinks/sillycup/S = new(get_turf(src))
	user.put_in_hands(S)
	paper_cups--

/obj/structure/reagent_dispensers/plumbed
	name = "stationairy water tank"
	anchored = TRUE
	icon_state = "water_stationairy"
	desc = "A stationairy, plumbed, water tank."

/obj/structure/reagent_dispensers/plumbed/wrench_act(mob/living/user, obj/item/I)
	default_unfasten_wrench(user, I)
	return TRUE

/obj/structure/reagent_dispensers/plumbed/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		user.visible_message("<span class='notice'>[user.name] [anchored ? "fasten" : "unfasten"] [src]</span>", \
		"<span class='notice'>You [anchored ? "fasten" : "unfasten"] [src]</span>")
		var/datum/component/plumbing/CP = GetComponent(/datum/component/plumbing)
		if(anchored)
			CP.enable()
		else
			CP.disable()

/obj/structure/reagent_dispensers/plumbed/ComponentInitialize()
	AddComponent(/datum/component/plumbing/simple_supply)

/obj/structure/reagent_dispensers/plumbed/storage
	name = "stationairy storage tank"
	icon_state = "tank_stationairy"
	reagent_id = null //start empty

/obj/structure/reagent_dispensers/plumbed/storage/ComponentInitialize()
	AddComponent(/datum/component/plumbing/tank)

//////////////
//Fuel Tanks//
//////////////

/obj/structure/reagent_dispensers/fueltank
	name = "fuel tank"
	desc = "A tank full of industrial welding fuel. Do not consume."
	icon_state = "fuel"
	reagent_id = /datum/reagent/fuel

/obj/structure/reagent_dispensers/fueltank/high
	name = "high-capacity fuel tank"
	desc = "A now illegal tank, full of highly pressurized industrial welding fuel. Do not consume or have a open flame close to this tank."
	icon_state = "fuel_high"
	tank_volume = 5000

/obj/structure/reagent_dispensers/fueltank/limitka
	name = "Топливный Держатель MK. Лимитка"
	desc = "<font size=+2><b>Пиздец, блядь, нахуй!</b></font>"
	icon_state = "fuel_pizdec"
	tank_volume = 100000

/obj/structure/reagent_dispensers/fueltank/limitka/explode()
	explosion(src, heavy_impact_range = 7, light_impact_range = 14, flame_range = 21, flash_range = 34)
	qdel(src)

/obj/structure/reagent_dispensers/fueltank/proc/explode()
	explosion(get_turf(src), 0, 1, 5, flame_range = 5)
	qdel(src)

/obj/structure/reagent_dispensers/fueltank/high/explode()
	explosion(get_turf(src), 0, 2, 5, flame_range = 12)
	qdel(src)


/obj/structure/reagent_dispensers/fueltank/blob_act(obj/structure/blob/B)
	boom()

/obj/structure/reagent_dispensers/fueltank/ex_act(severity, target, origin)
	explode()

/obj/structure/reagent_dispensers/fueltank/fire_act(exposed_temperature, exposed_volume)
	explode()

/obj/structure/reagent_dispensers/fueltank/zap_act(power, zap_flags, shocked_objects)
	..() //extend the zap
	if(ZAP_OBJ_DAMAGE & zap_flags)
		explode()

/obj/structure/reagent_dispensers/fueltank/bullet_act(obj/item/projectile/hitting_projectile)
	if(hitting_projectile.damage > 0 && ((hitting_projectile.damage_type == BURN) || (hitting_projectile.damage_type == BRUTE)))
		var/boom_message = "[ADMIN_LOOKUPFLW(hitting_projectile.firer)] triggered a fueltank explosion via projectile."
		GLOB.bombers += boom_message
		message_admins(boom_message)
		hitting_projectile.firer.log_message("triggered a fueltank explosion via projectile.", LOG_ATTACK)
		explode() //Bluemoon change

/obj/structure/reagent_dispensers/fueltank/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WELDER)
		if(!reagents.has_reagent(/datum/reagent/fuel))
			to_chat(user, "<span class='warning'>[src] is out of fuel!</span>")
			return
		var/obj/item/weldingtool/W = I
		if(!W.welding)
			if(W.reagents.has_reagent(/datum/reagent/fuel, W.max_fuel))
				to_chat(user, "<span class='warning'>Your [W.name] is already full!</span>")
				return
			reagents.trans_to(W, W.max_fuel, log = TRUE)
			user.visible_message("<span class='notice'>[user] refills [user.ru_ego()] [W.name].</span>", "<span class='notice'>You refill [W].</span>")
			playsound(src, 'sound/effects/refill.ogg', 50, 1)
			W.update_icon()
		else
			// if(!HAS_TRAIT(user, TRAIT_DUMB))
			// 	to_chat(user, "<span class='danger'>That would be stupid.</span>")
			// 	return
			var/turf/T = get_turf(src)
			user.visible_message("<span class='warning'>[user] catastrophically fails at refilling [user.ru_ego()] [W.name]!</span>", "<span class='userdanger'>That was stupid of you.</span>")

			var/message_admins = "[ADMIN_LOOKUPFLW(user)] triggered a fueltank explosion via welding tool at [ADMIN_VERBOSEJMP(T)]."
			GLOB.bombers += message_admins
			message_admins(message_admins)

			user.log_message("triggered a fueltank explosion via welding tool.", LOG_ATTACK)
			explode() //Bluemoon change
		return
	return ..()

///////////////////
//Misc Dispenders//
///////////////////

/obj/structure/reagent_dispensers/peppertank
	name = "pepper spray refiller"
	desc = "Contains condensed capsaicin for use in law \"enforcement.\""
	icon_state = "pepper"
	plane = ABOVE_WALL_PLANE
	anchored = TRUE
	density = FALSE
	reagent_id = /datum/reagent/consumable/condensedcapsaicin

/obj/structure/reagent_dispensers/peppertank/Initialize(mapload)
	. = ..()
	if(prob(1))
		desc = "IT'S PEPPER TIME, BITCH!"

/obj/structure/reagent_dispensers/peppertank/directional/north //Pixel offsets get overwritten on New()
	dir = SOUTH
	pixel_y = 24

/obj/structure/reagent_dispensers/peppertank/directional/south
	dir = NORTH
	pixel_y = -24

/obj/structure/reagent_dispensers/peppertank/directional/east
	dir = WEST
	pixel_x = 24

/obj/structure/reagent_dispensers/peppertank/directional/west
	dir = EAST
	pixel_x = -24

/obj/structure/reagent_dispensers/virusfood
	name = "virus food dispenser"
	desc = "A dispenser of low-potency virus mutagenic."
	icon_state = "virus_food"
	plane = ABOVE_WALL_PLANE
	anchored = TRUE
	density = FALSE
	reagent_id = /datum/reagent/consumable/virus_food

/obj/structure/reagent_dispensers/cooking_oil
	name = "vat of cooking oil"
	desc = "A huge metal vat with a tap on the front. Filled with cooking oil for use in frying food."
	icon_state = "vat"
	anchored = TRUE
	reagent_id = /datum/reagent/consumable/cooking_oil

/obj/structure/reagent_dispensers/servingdish
	name = "serving dish"
	desc = "A dish full of food slop for your bowl."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "serving"
	anchored = TRUE
	reagent_id = /datum/reagent/consumable/nutraslop

////////
//Kegs//
////////

/obj/structure/reagent_dispensers/beerkeg
	name = "Beer Keg"
	desc = "Кега с пивом. Кега выглядит совсем немного вздутой."
	icon_state = "beer"
	reagent_id = /datum/reagent/consumable/ethanol/beer

// BLUEMOON EDIT START
/obj/structure/reagent_dispensers/beerkeg/attack_animal(mob/living/simple_animal/M)
	var/explosion_chance = 10
	if(!isdog(M))
		explosion_chance = 0
	else
		if(M.a_intent == INTENT_HARM)
			explosion_chance += 30

	M.visible_message(span_danger("[M] играется с пивной кегой!"),
		span_nicegreen("Ты играешься с пивной кегой!"),
		span_hear("Кто-то катает пивную кегу рядом с вами!"))

	if(prob(explosion_chance))
		explosion(src, light_impact_range = 3, flame_range = 5, flash_range = 10)
		playsound(src, 'sound/effects/kega.ogg', 100, 1)
		if(!QDELETED(src))
			qdel(src)
		return TRUE
	else
		playsound(M, 'sound/weapons/thudswoosh.ogg', 100, TRUE, 1)
		do_jitter_animation()
	. = ..()

/obj/structure/reagent_dispensers/beerkeg/on_attack_hand(mob/living/carbon/M)
	. = ..()

	var/explosion_chance = 10
	if(!(ismammal(M) || ismonkey(M)))
		explosion_chance = 0
	else
		if(M.a_intent == INTENT_HARM)
			explosion_chance += 10
		if(ismonkey(M))
			explosion_chance += 10

	var/message = ""
	var/self_message = ""
	var/blind_message = span_hear("Кто-то катает пивную кегу рядом с вами!")

	if(isdwarf(M)) // ROCK AND STONE!
		message = span_nicegreen("[M] мастерски играется с пивной кегой!")
		self_message = span_nicegreen("Ты мастерски играешься с пивной кегой!")
	else
		if(explosion_chance != 0 && M.a_intent == INTENT_HARM)
			message = span_danger("[M] пинает пивную кегу!")
			self_message = span_danger("Ты пинаешь пивную кегу!")
			blind_message = span_hear("Кто-то пинает пивную кегу рядом с вами!")
		else
			message = span_danger("[M] играется с пивной кегой!")
			self_message = "[span_nicegreen("Ты играешься с пивной кегой!")][explosion_chance != 0 ? (span_warning(" Кажется это небезопасно...")) : ""]"
	M.visible_message(message, self_message, blind_message)

	if(prob(explosion_chance))
		explosion(src, light_impact_range = 3, flame_range = 5, flash_range = 10)
		playsound(src, 'sound/effects/kega.ogg', 100, 1)
		if(!QDELETED(src))
			qdel(src)
		return TRUE
	else
		playsound(M, 'sound/weapons/thudswoosh.ogg', 100, TRUE, 1)
		do_jitter_animation()
// BLUEMOON EDIT END

/obj/structure/reagent_dispensers/beerkeg/blob_act(obj/structure/blob/B)
	explosion(src, light_impact_range = 3, flame_range = 5, flash_range = 10)
	if(!QDELETED(src))
		qdel(src)

/obj/structure/reagent_dispensers/keg
	name = "keg"
	desc = "A keg."
	icon_state = "keg"

/obj/structure/reagent_dispensers/keg/mead
	name = "keg of mead"
	desc = "A keg of mead."
	icon_state = "orangekeg"
	reagent_id = /datum/reagent/consumable/ethanol/mead

/obj/structure/reagent_dispensers/keg/milk
	name = "keg of milk"
	desc = "A keg of pasteurised, homogenised, filtered and semi-skimmed space milk."
	icon_state = "whitekeg"
	reagent_id = /datum/reagent/consumable/milk

/obj/structure/reagent_dispensers/keg/gargle
	name = "keg of pan galactic gargleblaster"
	desc = "A keg of... wow that's a long name."
	icon_state = "bluekeg"
	reagent_id = /datum/reagent/consumable/ethanol/gargle_blaster
	tank_volume = 100

//kegs given by the travelling trader's bartender subtype

/obj/structure/reagent_dispensers/keg/quintuple_sec
	name = "keg of quintuple sec"
	desc = "A keg of pure justice."
	icon_state = "redkeg"
	reagent_id = /datum/reagent/consumable/ethanol/quintuple_sec
	tank_volume = 250

/obj/structure/reagent_dispensers/keg/narsour
	name = "keg of narsour"
	desc = "A keg of eldritch terrors."
	icon_state = "redkeg"
	reagent_id = /datum/reagent/consumable/ethanol/narsour
	tank_volume = 250

/obj/structure/reagent_dispensers/keg/red_queen
	name = "keg of red queen"
	desc = "A strange keg, filled with a kind of tea."
	icon_state = "redkeg"
	reagent_id = /datum/reagent/consumable/red_queen
	tank_volume = 250

/obj/structure/reagent_dispensers/keg/hearty_punch
	name = "keg of hearty punch"
	desc = "A keg that will get you right back on your feet."
	icon_state = "redkeg"
	reagent_id = /datum/reagent/consumable/ethanol/hearty_punch
	tank_volume = 100 //this usually has a 15:1 ratio when being made, so we provide less of it

/obj/structure/reagent_dispensers/keg/neurotoxin
	name = "keg of neurotoxin"
	desc = "A keg of the sickly substance known as 'neurotoxin'."
	icon_state = "bluekeg"
	reagent_id = /datum/reagent/consumable/ethanol/neurotoxin
	tank_volume = 100 //2.5x less than the other kegs because it's harder to get

/obj/structure/reagent_dispensers/keg/catnip
	name = "keg of catnip"
	desc = "A keg full of hapiness for your cat or felinid."
	icon_state = "greenkeg"
	reagent_id = /datum/reagent/pax/catnip
	tank_volume = 250

/obj/structure/reagent_dispensers/spacecleanertank
	name = "Space Cleaner Refiller"
	desc = "Refills space cleaner bottles."
	icon_state = "cleaner"
	anchored = TRUE
	density = FALSE
	plane = ABOVE_WALL_PLANE
	tank_volume = 5000
	reagent_id = /datum/reagent/space_cleaner
