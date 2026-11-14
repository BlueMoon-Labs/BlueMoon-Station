/obj/item/decoration
	name = "decoration"
	desc = "Winter is coming!"
	icon = 'modular_bluemoon/icons/obj/holidays/new_year/decorations.dmi'
	icon_state = "santa"
	layer = 4.1

/obj/item/decoration/attack_hand(mob/user)
	var/choice = input("Do you want to take \the [src]?") in list("Yes", "Cancel")
	if(choice == "Yes" && get_dist(src, user) <= 1)
		..()

/obj/item/decoration/afterattack(atom/target, mob/user, proximity, params)
	if(!proximity)
		return
	if(iswallturf(target))
		usr.dropItemToGround(src)
		forceMove(target)

// Garland
/obj/item/decoration/garland
	name = "garland"
	desc = "Beautiful lights! Shinee!"
	icon_state = "garland_on"
	var/icon_state_off = "garland"
	var/light_colors = list("#ff0000", "#6111ff", "#ffa500", "#44faff")
	var/on = TRUE
	var/brightness = 4

/obj/item/decoration/garland/proc/update_garland()
	if(on)
		icon_state = "[icon_state_off]_on"
		set_light(brightness)
	else
		icon_state = "[icon_state_off]"
		set_light(0)

/obj/item/decoration/garland/Initialize(mapload)
	. = ..()
	light_color = pick(light_colors)
	update_garland()

/obj/item/decoration/garland/attack_self(mob/user)
	. = ..()
	if(do_after(user, 5, target = src))
		toggle()

/obj/item/decoration/garland/verb/toggle()
	set name = "Toggle garland"
	set category = "Object"
	set src in view(1)

	var/mob/living/carbon/C = usr
	on = !on
	C.visible_message("<span class='notice'>[C] turns \the [src] [on ? "on" : "off"].</span>", "<span class='notice'>You turn \the [src] [on ? "on" : "off"].</span>")
	update_garland()

/obj/item/decoration/halloween
	desc = "Everybody scream!"
	icon = 'modular_bluemoon/icons/obj/holidays/halloween/decorations.dmi'
	icon_state = "1"

/obj/item/weapon/carved_pumpkin
	name = "carved pumpkin"
	desc = "Everybody hail to the pumkin song!"
	icon = 'modular_bluemoon/icons/obj/holidays/halloween/decorations.dmi'
	icon_state = "pumpkin"
	var/icon_state_off = "pumpkin"
	var/obj/item/candle/candle
	var/candled = FALSE

/obj/item/weapon/carved_pumpkin/candled
	candled = TRUE

/obj/item/weapon/carved_pumpkin/Initialize(mapload)
	. = ..()
	icon_state_off = "pumpkin_[rand(1, 8)]"
	icon_state = icon_state_off

	if(candled)
		candle = new(src)
		candle.light()
		update_icon()

/obj/item/weapon/carved_pumpkin/update_icon()
	if(candle)
		icon_state = "[icon_state_off]_on"
		light_color = candle.light_color
		set_light(3)
	else
		icon_state = icon_state_off
		set_light(0)

/obj/item/weapon/carved_pumpkin/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/candle) && !candle)
		var/obj/item/candle/new_candle = I
		if(!new_candle.lit)
			return
		user.dropItemToGround(new_candle, src)
		candle = new_candle
		update_icon()
		return
	return ..()

/obj/item/weapon/carved_pumpkin/attack_self(mob/user)
	. = ..()

	if(do_after(user, 5, target = src))
		user.put_in_hands(candle)
		candle = null
		update_icon()

// Garland
/obj/item/decoration/garland/halloween
	desc = "Beautiful lights! Shinee!"
	icon = 'modular_bluemoon/icons/obj/holidays/halloween/decorations.dmi'
	icon_state = "garland"
	light_colors = list("#f8731e", "#ffd401", "#ef0001")
	var/random = TRUE
	var/variations = 7

/obj/item/decoration/garland/halloween/Initialize(mapload)
	if(random)
		icon_state_off = "garland_[rand(1, variations)]"
	. = ..()

/obj/item/decoration/garland/halloween/long
	icon_state = "garland_1"
	icon_state_off = "garland_1"
	random = FALSE

/obj/item/decoration/garland/halloween/medium
	icon_state = "garland_2"
	icon_state_off = "garland_2"
	random = FALSE

/obj/item/decoration/garland/halloween/short
	icon_state = "garland_3"
	icon_state_off = "garland_3"
	random = FALSE

// Tinsels
/obj/item/decoration/tinsel
	name = "tinsel"
	desc = "Soft tinsel, pleasant to the touch. Ahhh..."
	icon = 'modular_bluemoon/icons/obj/holidays/new_year/tinsel.dmi'
	icon_state = "1"
	var/variations = 4
	var/random = TRUE // random color

/obj/item/decoration/tinsel/Initialize(mapload)
	. = ..()
	if(random)
		icon_state = "[rand(1, variations)]"

/obj/item/decoration/tinsel/green
	icon_state = "1"
	random = FALSE

/obj/item/decoration/tinsel/red
	icon_state = "2"
	random = FALSE

/obj/item/decoration/tinsel/yellow
	icon_state = "3"
	random = FALSE

/obj/item/decoration/tinsel/white
	icon_state = "4"
	random = FALSE

// Tinsels - hw
/obj/item/decoration/tinsel/halloween
	desc = "Everybody scream! Everybody scream! In our town of Halloween!"
	icon = 'modular_bluemoon/icons/obj/holidays/halloween/tinsel.dmi'
	icon_state = "1"
	variations = 20
	random = TRUE

/obj/item/decoration/tinsel/halloween/attack_self(mob/user)
	. = ..()
	setDir(turn(dir,-90))

/obj/item/decoration/tinsel/halloween/pumkings
	icon_state = "1"
	random = FALSE

/obj/item/decoration/tinsel/halloween/ghosts
	icon_state = "2"
	random = FALSE

/obj/item/decoration/tinsel/halloween/bats
	icon_state = "14"
	random = FALSE

// Во время Хэллоуина гирлянда вешается только на замапленные fulltile-окна.
// Направленные (directional) окна, в том числе из спавнеров, пропускаются.
/obj/structure/window/Initialize(mapload, direct)
	. = ..()
	if(mapload && fulltile && SSholidays.holidays && SSholidays.holidays[HALLOWEEN])
		var/turf/window_turf = get_turf(src)
		// Угловые окна ставятся по два на турф - гирлянда нужна одна.
		if(window_turf && !(locate(/obj/item/decoration/garland/halloween) in window_turf))
			new /obj/item/decoration/garland/halloween(window_turf)
