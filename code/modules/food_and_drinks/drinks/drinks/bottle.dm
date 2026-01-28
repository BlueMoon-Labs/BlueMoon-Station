

///////////////////////////////////////////////Alchohol bottles! -Agouri //////////////////////////
//Functionally identical to regular drinks. The only difference is that the default bottle size is 100. - Darem
//Bottles now knockdown and break when smashed on people's heads. - Giacom

/obj/item/reagent_containers/food/drinks/bottle
	amount_per_transfer_from_this = 10
	volume = 100
	force = 15
	throwforce = 15
	item_state = "broken_beer" //Generic held-item sprite until unique ones are made.
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	var/knockdown_duration = 13 //Directly relates to the 'knockdown' duration. Lowered by armor (i.e. helmets)
	isGlass = TRUE
	foodtype = ALCOHOL

/obj/item/reagent_containers/food/drinks/bottle
	var/hole = CUM_TARGET_VAGINA

/obj/item/reagent_containers/food/drinks/bottle/verb/verb_spin()
	set src in view(1)
	set category = "Object"
	set name = "Spin"

	if(usr.incapacitated() || !Adjacent(usr) || isobserver(usr) || isdead(usr)) //  || usr.lying
		return

	var/matrix/M = matrix(transform)
	var/datum/reagents/r = src.reagents
	if(r.total_volume < r.maximum_volume && r.total_volume > 0)
		M.Turn(rand(-170,170))
		transform = M
		visible_message("<span class='notice'>[usr] закручивает бутылочку, но жидкость внутри не дает ей вращаться.</span>")
		return

	var/list/mobs_around = list()
	mobs_around += "пустоту"
	for(var/mob/living/L in oview(1,src))
		mobs_around += L
	visible_message("<span class='notice'>[usr] тянется к бутылочке и закручивает ее...</span>")
	src.SpinAnimation(2,9)
	var/mob/living/chosen_mob = pick(mobs_around)
	var/chosen_mob_name
	if(istype(chosen_mob))
		chosen_mob_name = chosen_mob.name
		M = turn(matrix(), 0)
		M.Turn(Get_Angle(src, chosen_mob))
	else
		chosen_mob_name = chosen_mob
		M.Turn(rand(-170,170))
	transform = M
	playsound(src, 'sound/effects/rollingbottle.ogg', 30, TRUE)
	visible_message("<span class='notice'>Бутылочка указывает на [chosen_mob_name].</span>")

/obj/item/reagent_containers/food/drinks/bottle/CtrlShiftClick(mob/living/carbon/human/user as mob)
	hole = hole == CUM_TARGET_VAGINA ? CUM_TARGET_ANUS : CUM_TARGET_VAGINA
	to_chat(user, "<span class='notice'>Я целюсь в... [hole].</span>")

/obj/item/reagent_containers/food/drinks/bottle/attack(mob/living/target, mob/living/user)
	user.DelayNextAction(CLICK_CD_RANGE)
	if (user.zone_selected == BODY_ZONE_PRECISE_GROIN && user.a_intent == INTENT_HELP)
		do_eblya(target, user)
	else
		. = ..()

/obj/item/reagent_containers/food/drinks/bottle/proc/do_eblya(mob/living/target, mob/living/user)
	var/message = ""
	var/lust_amt = 0
	if(!user.canUseTopic(target, BE_CLOSE))
		return
	if(ishuman(target) && (target?.client?.prefs?.toggles & VERB_CONSENT))
		if(user.zone_selected == BODY_ZONE_PRECISE_GROIN)
			switch(hole)
				if(CUM_TARGET_VAGINA)
					if(target.has_vagina() == HAS_EXPOSED_GENITAL)
						message = (user == target) ? pick("крепко обхватывает '\the [src]' и начинает пихать это прямо в свою киску.", "запихивает '\the [src]' в свою киску", "постанывает и садится на '\the [src]'.") : pick("трахает <b>[target]</b> прямо в киску с помощью '\the [src]'", "засовывает '\the [src]' прямо в киску <b>[target]</b>.")
						lust_amt = NORMAL_LUST
				if(CUM_TARGET_ANUS)
					if(target.has_anus() == HAS_EXPOSED_GENITAL)
						message = (user == target) ? pick("крепко обхватывает '\the [src]' и начинает пихать это прямо в свою попку.","запихивает '\the [src]' прямо в свою собственную попку.", "постанывает и садится на '\the [src]'.") : pick("трахает <b>[target]</b> прямо в попку '\the [src]'", "активно суёт '\the [src]' прямо в попку <b>[target]</b>.")
						lust_amt = NORMAL_LUST
	if(message)
		user.visible_message("<span class='lewd'><b>[user]</b> [message].</span>")
		target.handle_post_sex(lust_amt, null, user)

		switch (hole)
			if (CUM_TARGET_VAGINA)
				user.client?.plug13.send_emote(PLUG13_EMOTE_VAGINA, min(lust_amt*3, 100), PLUG13_DURATION_NORMAL)
			if (CUM_TARGET_ANUS)
				user.client?.plug13.send_emote(PLUG13_EMOTE_ANUS, min(lust_amt*3, 100), PLUG13_DURATION_NORMAL)

		playsound(loc, pick('modular_sand/sound/interactions/bang4.ogg',
							'modular_sand/sound/interactions/bang5.ogg',
							'modular_sand/sound/interactions/bang6.ogg'), 70, 1, -1)
		if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
			new /obj/effect/temp_visual/heart(target.loc)

/obj/item/reagent_containers/food/drinks/bottle/attack(mob/living/target, mob/living/user)

	if(!target)
		return

	if(user.a_intent != INTENT_HARM || !isGlass)
		return ..()

	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, "<span class='warning'>You don't want to harm [target]!</span>")
		return

	var/obj/item/bodypart/affecting = user.zone_selected //Find what the player is aiming at

	var/headarmor = 0 // Target's head armor
	var/armor_block = min(90, target.run_armor_check(affecting, MELEE, null, null,armour_penetration)) // For normal attack damage

	//If they have a hat/helmet and the user is targeting their head.
	if(affecting == BODY_ZONE_HEAD)
		var/obj/item/I = target.get_item_by_slot(ITEM_SLOT_HEAD)
		if(I)
			headarmor = I.armor.melee

	//Calculate the knockdown duration for the target.
	var/armor_duration = (knockdown_duration - headarmor) + force

	//Apply the damage!
	target.apply_damage(force, BRUTE, affecting, armor_block)

	// You are going to knock someone out for longer if they are not wearing a helmet.
	var/head_attack_message = ""
	if(affecting == BODY_ZONE_HEAD && iscarbon(target))
		head_attack_message = " on the head"
		//Knockdown the target for the duration that we calculated and divide it by 5.
		if(armor_duration)
			if(target.mob_weight < MOB_WEIGHT_HEAVY_SUPER) // BLUEMOON ADDITION - вы не можете опрокинуть сверхтяжёлого персонажа ударом бутылки о голову
				target.DefaultCombatKnockdown(min(armor_duration, 200)) // Never knockdown more than a flash!

	//Display an attack message.
	if(target != user)
		target.visible_message("<span class='danger'>[user] has hit [target][head_attack_message] with a bottle of [src.name]!</span>", \
				"<span class='userdanger'>[user] has hit [target][head_attack_message] with a bottle of [src.name]!</span>")
	else
		user.visible_message("<span class='danger'>[target] hits [target.p_them()]self with a bottle of [src.name][head_attack_message]!</span>", \
				"<span class='userdanger'>[target] hits [target.p_them()]self with a bottle of [src.name][head_attack_message]!</span>")

	//Attack logs
	log_combat(user, target, "attacked", src)

	//The reagents in the bottle splash all over the target, thanks for the idea Nodrak
	SplashReagents(target)

	//Finally, smash the bottle. This kills (del) the bottle.
	smash(target, user)

	return

//Keeping this here for now, I'll ask if I should keep it here.
/obj/item/broken_bottle
	name = "Broken Bottle"
	desc = "A shattered glass container with sharp edges."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "broken_bottle"
	force = 9
	throwforce = 5
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY
	item_state = "beer"
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("stabbed", "slashed", "attacked")
	var/icon/broken_outline = icon('icons/obj/drinks.dmi', "broken")
	sharpness = SHARP_EDGED

/obj/item/broken_bottle/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 200, 55)

/obj/item/reagent_containers/food/drinks/bottle/gin
	name = "Griffeater Gin"
	desc = "A bottle of high quality gin, produced in the New London Space Station."
	icon_state = "ginbottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/gin = 100)

/obj/item/reagent_containers/food/drinks/bottle/gin/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/whiskey
	name = "Uncle Git's Special Reserve"
	desc = "A premium single-malt whiskey, gently matured inside the tunnels of a nuclear shelter. TUNNEL WHISKEY RULES."
	icon_state = "whiskeybottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/whiskey = 100)

/obj/item/reagent_containers/food/drinks/bottle/whiskey/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/vodka
	name = "Tunguska Triple Distilled"
	desc = "Aah, vodka. Prime choice of drink AND fuel by Russians worldwide."
	icon_state = "vodkabottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/vodka = 100)

/obj/item/reagent_containers/food/drinks/bottle/vodka/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/vodka/badminka
	name = "Badminka Vodka"
	desc = "The label's written in Cyrillic. All you can make out is the name and a word that looks vaguely like 'Vodka'."
	icon_state = "badminka"

/obj/item/reagent_containers/food/drinks/bottle/tequila
	name = "Caccavo Guaranteed Quality Tequila"
	desc = "Made from premium petroleum distillates, pure thalidomide and other fine quality ingredients!"
	icon_state = "tequilabottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/tequila = 100)

/obj/item/reagent_containers/food/drinks/bottle/tequila/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing
	name = "Bottle of Nothing"
	desc = "A bottle filled with nothing."
	icon_state = "bottleofnothing"
	list_reagents = list(/datum/reagent/consumable/nothing = 100)
	foodtype = NONE

/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/patron
	name = "Wrapp Artiste Patron"
	desc = "Silver laced tequila, served in space night clubs across the galaxy."
	icon_state = "patronbottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/patron = 100)

/obj/item/reagent_containers/food/drinks/bottle/patron/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/rum
	name = "Captain Pete's Cuban spiced rum"
	desc = "This isn't just rum, oh no. It's practically GRIFF in a bottle."
	icon_state = "rumbottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/rum = 100)

/obj/item/reagent_containers/food/drinks/bottle/rum/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/holywater
	name = "Flask of Holy Water"
	desc = "A flask of the chaplain's holy water."
	icon_state = "holyflask"
	list_reagents = list(/datum/reagent/water/holywater = 100)
	foodtype = NONE

/obj/item/reagent_containers/food/drinks/bottle/holywater/hell
	desc = "A flask of holy water...it's been sitting in the Necropolis a while though."
	list_reagents = list(/datum/reagent/hellwater = 100)

/obj/item/reagent_containers/food/drinks/bottle/holyoil
	name = "Flask of Zelus Oil"
	desc = "A brass flask of Zelus oil, a viscous fluid scenting of brass. Can be thrown to deal damage from afar."
	icon_state = "zelusflask"
	list_reagents = list(/datum/reagent/fuel/holyoil = 30)
	volume = 30
	foodtype = NONE
	force = 18
	throwforce = 18
	knockdown_duration = 18

/obj/item/reagent_containers/food/drinks/bottle/holyoil/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/vermouth
	name = "Goldeneye vermouth"
	desc = "Sweet, sweet dryness~"
	icon_state = "vermouthbottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/vermouth = 100)

/obj/item/reagent_containers/food/drinks/bottle/vermouth/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/kahlua
	name = "Robert Robust's coffee liqueur"
	desc = "A widely known, Mexican coffee-flavoured liqueur. In production since 1936, HONK."
	icon_state = "kahluabottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/kahlua = 100)
	foodtype = VEGETABLES

/obj/item/reagent_containers/food/drinks/bottle/kahlua/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/goldschlager
	name = "College Girl goldschlager"
	desc = "Because they are the only ones who will drink 100 proof cinnamon schnapps."
	icon_state = "goldschlagerbottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/goldschlager = 100)

/obj/item/reagent_containers/food/drinks/bottle/goldschlager/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/cognac
	name = "Chateau de Baton premium cognac"
	desc = "A sweet and strongly alchoholic drink, made after numerous distillations and years of maturing. You might as well not scream 'SHITCURITY' this time."
	icon_state = "cognacbottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/cognac = 100)

/obj/item/reagent_containers/food/drinks/bottle/cognac/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/wine
	name = "Doublebeard's bearded special wine"
	desc = "A faint aura of unease and asspainery surrounds the bottle."
	icon_state = "winebottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/wine = 100)
	foodtype = FRUIT | ALCOHOL

/obj/item/reagent_containers/food/drinks/bottle/wine/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/absinthe
	name = "Extra-Strong Absinthe"
	desc = "An strong alcoholic drink brewed and distributed by"
	icon_state = "absinthebottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/absinthe = 100)

/obj/item/reagent_containers/food/drinks/bottle/absinthe/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/absinthe/Initialize(mapload)
	. = ..()
	redact()

/obj/item/reagent_containers/food/drinks/bottle/absinthe/proc/redact()
	// There was a large fight in the coderbus about a player reference
	// in absinthe. Ergo, this is why the name generation is now so
	// complicated. Judge us kindly.
	var/shortname = pickweight(
		list("T&T" = 1, "A&A" = 1, "Generic" = 1))
	var/fullname
	var/removals = GLOB.redacted_strings.Copy()
	switch(shortname)
		if("T&T")
			fullname = "Teal and Tealer"
		if("A&A")
			fullname = "Ash and Asher"
		if("Generic")
			fullname = "Nanotrasen Cheap Imitations"
	var/chance = 50

	if(prob(chance))
		shortname = pick_n_take(removals)

	var/list/final_fullname = list()
	for(var/word in splittext(fullname, " "))
		if(prob(chance))
			word = pick_n_take(removals)
		final_fullname += word

	fullname = jointext(final_fullname, " ")

	// Actually finally setting the new name and desc
	name = "[shortname] [name]"
	desc = "[desc] [fullname] Inc."


/obj/item/reagent_containers/food/drinks/bottle/absinthe/premium
	name = "Gwyn's premium absinthe"
	desc = "A potent alcoholic beverage, almost makes you forget the ash in your lungs."
	icon_state = "absinthepremium"

/obj/item/reagent_containers/food/drinks/bottle/absinthe/premium/redact()
	return

/obj/item/reagent_containers/food/drinks/bottle/lizardwine
	name = "Bottle of Lizard Wine"
	desc = "An alcoholic beverage from Space China, made by infusing lizard tails in ethanol. Inexplicably popular among command staff."
	icon_state = "lizardwine"
	list_reagents = list(/datum/reagent/consumable/ethanol/lizardwine = 100)
	foodtype = FRUIT | ALCOHOL

/obj/item/reagent_containers/food/drinks/bottle/hcider
	name = "Jian Hard Cider"
	desc = "Apple juice for adults."
	icon_state = "hcider"
	volume = 50
	list_reagents = list(/datum/reagent/consumable/ethanol/hcider = 50)

/obj/item/reagent_containers/food/drinks/bottle/hcider/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/amaretto
	name = "Luini Amaretto"
	desc = "A gentle and syrup-like drink that tastes of almonds and apricots."
	icon_state = "disaronno"
	list_reagents = list(/datum/reagent/consumable/ethanol/amaretto = 100)

/obj/item/reagent_containers/food/drinks/bottle/amaretto/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/grappa
	name = "Phillipes well-aged Grappa"
	desc = "Bottle of Grappa."
	icon_state = "grappabottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/grappa = 100)

/obj/item/reagent_containers/food/drinks/bottle/grappa/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/sake
	name = "Ryo's traditional sake"
	desc = "Sweet as can be, and burns like fire going down."
	icon_state = "sakebottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/sake = 100)

/obj/item/reagent_containers/food/drinks/bottle/sake/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/sake/Initialize(mapload)
	. = ..()
	if(prob(10))
		name = "Fluffy Tail Sake"
		desc += " On the bottle is a picture of a kitsune with nine touchable tails."
		icon_state = "sakebottle_k"
	else if(prob(10))
		name = "Inubashiri's Home Brew"
		desc += " Awoo."
		icon_state = "sakebottle_i"

/obj/item/reagent_containers/food/drinks/bottle/fernet
	name = "Fernet Bronca"
	desc = "A bottle of pure Fernet Bronca, produced in Cordoba Space Station"
	icon_state = "fernetbottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/fernet = 100)

/obj/item/reagent_containers/food/drinks/bottle/fernet/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/applejack
	name = "Buckin' Bronco's Applejack"
	desc = "Kicks like a horse, tastes like an apple!"
	custom_price = PRICE_CHEAP
	icon_state = "applejack_bottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/applejack = 100)
	foodtype = FRUIT

/obj/item/reagent_containers/food/drinks/bottle/applejack/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/champagne
	name = "Eau d' Dandy Brut Champagne"
	desc = "Finely sourced from only the most pretentious French vineyards."
	icon_state = "champagne_bottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/champagne = 100)

/obj/item/reagent_containers/food/drinks/bottle/champagne/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/blazaam
	name = "Ginbad's Blazaam"
	desc = "You feel like you should give the bottle a good rub before opening."
	icon_state = "blazaambottle"
	list_reagents = list(/datum/reagent/consumable/ethanol/blazaam = 100)

/obj/item/reagent_containers/food/drinks/bottle/blazaam/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/trappist
	name = "Mont de Requin Trappistes Bleu"
	desc = "Brewed in space-Belgium. Fancy!"
	custom_premium_price = PRICE_ABOVE_NORMAL
	icon_state = "trappistbottle"
	volume = 50
	list_reagents = list(/datum/reagent/consumable/ethanol/trappist = 50)

/obj/item/reagent_containers/food/drinks/bottle/trappist/empty
	list_reagents = null

//////////////////////////JUICES AND STUFF ///////////////////////

/obj/item/reagent_containers/food/drinks/bottle/orangejuice
	name = "Orange Juice"
	desc = "Full of vitamins and deliciousness!"
	custom_price = PRICE_CHEAP
	icon_state = "orangejuice"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	isGlass = FALSE
	list_reagents = list(/datum/reagent/consumable/orangejuice = 100)
	foodtype = FRUIT| BREAKFAST

/obj/item/reagent_containers/food/drinks/bottle/bio_carton
	name = "Small Carton Box"
	desc = "A small biodegradable carton box made from plant biomatter."
	icon_state = "eco_box"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	volume = 50
	isGlass = FALSE

/obj/item/reagent_containers/food/drinks/bottle/cream
	name = "Milk Cream"
	desc = "It's cream. Made from milk. What else did you think you'd find in there?"
	custom_price = PRICE_CHEAP
	icon_state = "cream"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	isGlass = FALSE
	list_reagents = list(/datum/reagent/consumable/cream = 100)
	foodtype = DAIRY

/obj/item/reagent_containers/food/drinks/bottle/tomatojuice
	name = "Tomato Juice"
	desc = "Well, at least it LOOKS like tomato juice. You can't tell with all that redness."
	custom_price = PRICE_CHEAP
	icon_state = "tomatojuice"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	isGlass = FALSE
	list_reagents = list(/datum/reagent/consumable/tomatojuice = 100)
	foodtype = VEGETABLES

/obj/item/reagent_containers/food/drinks/bottle/limejuice
	name = "Lime Juice"
	desc = "Sweet-sour goodness."
	custom_price = PRICE_CHEAP
	icon_state = "limejuice"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	isGlass = FALSE
	list_reagents = list(/datum/reagent/consumable/limejuice = 100)
	foodtype = FRUIT

/obj/item/reagent_containers/food/drinks/bottle/pineapplejuice
	name = "Pineapple Juice"
	desc = "Extremely tart, yellow juice."
	icon_state = "pineapplejuice"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	isGlass = FALSE
	list_reagents = list(/datum/reagent/consumable/pineapplejuice = 100)
	foodtype = FRUIT | PINEAPPLE

/obj/item/reagent_containers/food/drinks/bottle/strawberryjuice
	name = "Strawberry Juice"
	desc = "Slushy, reddish juice."
	icon_state = "strawberryjuice"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	isGlass = FALSE
	list_reagents = list(/datum/reagent/consumable/strawberryjuice = 100)
	foodtype = FRUIT

/obj/item/reagent_containers/food/drinks/bottle/menthol
	name = "Menthol"
	desc = "Tastes naturally minty, and imparts a very mild numbing sensation."
	custom_price = PRICE_CHEAP
	icon_state = "mentholbox"
	item_state = "carton"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	isGlass = FALSE
	list_reagents = list(/datum/reagent/consumable/menthol = 100)

/obj/item/reagent_containers/food/drinks/bottle/grenadine
	name = "Jester Grenadine"
	desc = "Contains 0% real cherries!"
	custom_price = PRICE_CHEAP
	icon_state = "grenadine"
	isGlass = TRUE
	list_reagents = list(/datum/reagent/consumable/grenadine = 100)
	foodtype = FRUIT

/obj/item/reagent_containers/food/drinks/bottle/grenadine/empty
	list_reagents = null

/obj/item/reagent_containers/food/drinks/bottle/blank //Don't let players print these from a lathe, bottles should be obtained in mass from the bar only.
	name = "Glass Bottle"
	desc = "This blank bottle is unyieldingly anonymous, offering no clues to it's contents."
	icon_state = "glassbottle"
	volume = 90
	spillable = TRUE
	obj_flags = UNIQUE_RENAME

/obj/item/reagent_containers/food/drinks/bottle/blank/update_icon()
	..()
	add_overlay("[initial(icon_state)]shine")

/obj/item/reagent_containers/food/drinks/bottle/blank/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/reagent_containers/food/drinks/bottle/blank/get_part_rating()
	return reagents.maximum_volume

/obj/item/reagent_containers/food/drinks/bottle/blank/on_reagent_change(changetype)
	update_icon()

/obj/item/reagent_containers/food/drinks/bottle/blank/update_overlays()
	. = ..()
	if(!cached_icon)
		cached_icon = icon_state

	if(reagents.total_volume)
		var/mutable_appearance/filling = mutable_appearance('icons/obj/reagentfillings.dmi', "[cached_icon]10", color = mix_color_from_reagents(reagents.reagent_list))

		var/percent = round((reagents.total_volume / volume) * 100)
		switch(percent)
			if(0 to 9)
				filling.icon_state = "[cached_icon]0"
			if(10 to 19)
				filling.icon_state = "[cached_icon]10"
			if(20 to 29)
				filling.icon_state = "[cached_icon]20"
			if(30 to 39)
				filling.icon_state = "[cached_icon]30"
			if(40 to 49)
				filling.icon_state = "[cached_icon]40"
			if(50 to 59)
				filling.icon_state = "[cached_icon]50"
			if(60 to 69)
				filling.icon_state = "[cached_icon]60"
			if(70 to 79)
				filling.icon_state = "[cached_icon]70"
			if(80 to 89)
				filling.icon_state = "[cached_icon]80"
			if(90 to INFINITY)
				filling.icon_state = "[cached_icon]90"
		. += filling

/obj/item/reagent_containers/food/drinks/bottle/blank/small
	name = "Small Glass Bottle"
	desc = "This small bottle is unyieldingly anonymous, offering no clues to it's contents."
	icon_state = "glassbottlesmall"
	volume = 60

/obj/item/reagent_containers/food/drinks/bottle/blank/pitcher
	name = "Glass Pitcher"
	desc = "This is a pitcher for large amounts of liquid of any kind."
	icon_state = "unipitcher"
	volume = 120

////////////////////////// MOLOTOV ///////////////////////
/obj/item/reagent_containers/food/drinks/bottle/molotov
	name = "Molotov Cocktail"
	desc = "A throwing weapon used to ignite things, typically filled with an accelerant. Recommended highly by rioters and revolutionaries. Light and toss."
	icon_state = "vodkabottle"
	list_reagents = list()
	var/list/accelerants = list(	/datum/reagent/consumable/ethanol, /datum/reagent/fuel, /datum/reagent/clf3, /datum/reagent/phlogiston,
							/datum/reagent/napalm, /datum/reagent/hellwater, /datum/reagent/toxin/plasma, /datum/reagent/toxin/spore_burning)
	var/active = 0

/obj/item/reagent_containers/food/drinks/bottle/molotov/CheckParts(list/parts_list)
	..()
	var/obj/item/reagent_containers/food/drinks/bottle/B = locate() in contents
	if(B)
		icon_state = B.icon_state
		B.reagents.copy_to(src,100)
		if(!B.isGlass)
			desc += " You're not sure if making this out of a carton was the brightest idea."
			isGlass = FALSE
	return

/obj/item/reagent_containers/food/drinks/bottle/molotov/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/fire_power = reagents.get_total_accelerant_quality()
	if(active && fire_power > 0)
		hit_atom.fire_act()
		if(isliving(hit_atom))
			var/mob/living/L = hit_atom
			L.adjust_fire_stacks()
		if(fire_power > 10)
			var/turf/center_turf = get_turf(hit_atom)
			if(isclosedturf(center_turf) && isopenturf(get_turf(src)))
				center_turf = get_turf(src) // if it hits a wall, light the floor in front of the wall on fire, not the wall itself
			center_turf.IgniteTurf(fire_power)
			for(var/turf/T in center_turf.reachableAdjacentAtmosTurfs())
				if(prob(fire_power))
					T.IgniteTurf(fire_power)
	return ..()

/obj/item/reagent_containers/food/drinks/bottle/molotov/attackby(obj/item/I, mob/user, params)
	if(I.get_temperature() && !active)
		active = 1
		var/message = "[ADMIN_LOOKUP(user)] has primed a [name] for detonation at [ADMIN_VERBOSEJMP(user)]."
		GLOB.bombers += message
		message_admins(message)
		log_game("[key_name(user)] has primed a [name] for detonation at [AREACOORD(user)].")

		to_chat(user, "<span class='info'>You light [src] on fire.</span>")
		add_overlay(GLOB.fire_overlay)
		if(!isGlass)
			spawn(50)
				if(active)
					var/counter
					var/target = src.loc
					for(counter = 0, counter<2, counter++)
						if(istype(target, /obj/item/storage))
							var/obj/item/storage/S = target
							target = S.loc
					if(istype(target, /atom))
						var/atom/A = target
						SplashReagents(A)
						A.fire_act()
					qdel(src)

/obj/item/reagent_containers/food/drinks/bottle/molotov/attack_self(mob/user)
	if(active)
		if(!isGlass)
			to_chat(user, "<span class='danger'>The flame's spread too far on it!</span>")
			return
		to_chat(user, "<span class='info'>You snuff out the flame on [src].</span>")
		cut_overlay(GLOB.fire_overlay)
		active = 0

/obj/item/export/bottle/attack_self(mob/user)
	to_chat(user, "<span class='danger'>The seal seems fine. Best to not open it.</span>")
	return

/obj/item/export/bottle
	name = "Report this please"
	desc = "A sealed bottle of alcohol, ready to be exported"
	icon = 'icons/obj/drinks.dmi'
	force = 0
	throwforce = 0
	throw_speed = 0
	throw_range = 0
	w_class = WEIGHT_CLASS_TINY
	item_state = "beer"
	attack_verb = list("boop", "thunked", "shown")

/obj/item/export/bottle/gin
	icon_state = "ginbottle"
	name = "Sealed Gin"

/obj/item/export/bottle/wine
	icon_state = "winebottle"
	name = "Sealed Wine"

/obj/item/export/bottle/whiskey
	icon_state = "whiskeybottle"
	name = "Sealed Whiskey"

/obj/item/export/bottle/vodka
	icon_state = "vodkabottle"
	name = "Sealed Vodka"

/obj/item/export/bottle/tequila
	icon_state = "tequilabottle"
	name = "Sealed Tequila"

/obj/item/export/bottle/patron
	icon_state = "patronbottle"
	name = "Sealed Patron"

/obj/item/export/bottle/rum
	icon_state = "rumbottle"
	name = "Sealed Rum"

/obj/item/export/bottle/vermouth
	icon_state = "vermouthbottle"
	name = "Sealed Vermouth"

/obj/item/export/bottle/kahlua
	icon_state = "kahluabottle"
	name = "Sealed Kahlua"

/obj/item/export/bottle/goldschlager
	icon_state = "goldschlagerbottle"
	name = "Sealed Goldschlager"

/obj/item/export/bottle/hcider
	icon_state = "hcider"
	name = "Sealed Cider"

/obj/item/export/bottle/amaretto
	icon_state = "disaronno"
	name = "Sealed Amaretto"

/obj/item/export/bottle/cognac
	icon_state = "cognacbottle"
	name = "Sealed Cognac"

/obj/item/export/bottle/absinthe
	icon_state = "absinthebottle"
	name = "Sealed Unmarked Absinthe"

/obj/item/export/bottle/grappa
	icon_state = "grappabottle"
	name = "Sealed Grappa"

/obj/item/export/bottle/sake
	icon_state = "sakebottle"
	name = "Sealed Sake"

/obj/item/export/bottle/fernet
	icon_state = "fernetbottle"
	name = "Sealed Fernet"

/obj/item/export/bottle/applejack
	icon_state = "applejack_bottle"
	name = "Sealed Applejack"

/obj/item/export/bottle/champagne
	icon_state = "champagne_bottle"
	name = "Sealed Champagne"

/obj/item/export/bottle/blazaam
	icon_state = "blazaambottle"
	name = "Sealed Blazaam"

/obj/item/export/bottle/trappist
	icon_state = "trappistbottle"
	name = "Sealed Trappist"

/obj/item/export/bottle/grenadine
	icon_state = "grenadine"
	name = "Sealed Grenadine"

/obj/item/export/bottle/minikeg
	name = "Mini-Beer Keg"
	icon_state = "keggy"
	desc = "A small wooden barrle with metal rings, untapped beer inside."

/obj/item/export/bottle/blooddrop
	icon_state = "champagne_selling_bottle"
	name = "Blood Drop"
	desc = "Large red bottle filled with a mix of wine and other named brands."

/obj/item/export/bottle/slim_gold
	name = "Slim Gold "
	icon_state = "selling_bottle_alt"
	desc = "A gold looking yellow bottle that has a mix of different named brands."

/obj/item/export/bottle/white_bloodmoon
	name = "White Bloodmoon"
	icon_state = "selling_bottle_basic"
	desc = "Rather simple bottle for this kind of drink."

/obj/item/export/bottle/greenroad
	name = "Green Road"
	icon_state = "selling_bottle"
	desc = "Ironic name as the fruit used is from ashy plants."
