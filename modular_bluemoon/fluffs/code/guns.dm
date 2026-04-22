///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit
	name = "modkit"
	desc = "A modkit for making something into something."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	w_class = WEIGHT_CLASS_SMALL
	icon_state = "sec_armor_kit"
	var/product //what it makes
	var/list/fromitem = list() //what it needs

/obj/item/modkit/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag)
		return
	if(istype(target, product))
		to_chat(user,"<span class='warning'>[target] is already modified!")
		return
	if(target.type in fromitem) //makes sure target is the right thing
		var/loc_to_spawn = target.loc || get_turf(target)
		var/atom/movable/result = new product //spawns the product
		user.visible_message("<span class='warning'>[user] modifies [target]!","<span class='warning'>You modify the [target]!")
		on_item_replace(target, result)
		qdel(target) //Gets rid of the baton
		qdel(src) //gets rid of the kit
		if(ismob(loc_to_spawn))
			var/mob/M = loc_to_spawn
			M.put_in_hands(result)
		else
			result.forceMove(loc_to_spawn)
	else
		to_chat(user, "<span class='warning'> You can't modify [target] with this kit!</span>")

// may be useful for gun/stunbaton/etc modkits
/obj/item/modkit/proc/on_item_replace(obj/old_item, obj/modified_item)
	return

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/Kovac_Kit
	name = "Kovac Gun Kit"
	desc = "A modkit for making a Enforcer Gun into a Kovac Gun."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/steyr
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/steyr
	name = "\improper Steyr MWS"
	desc = "An antique semi-automatic pistol, heavily modified by the MWS defence manufacturing company. Provided with a better ammo cartridge and reinforced parts, it fits perfectly for resolving various security tasks. You can also notice Kovac's family sign drawn on it's handgrip."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "steyr_m1912"
	can_suppress = FALSE
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/steyr_shoot.ogg'
	pin = /obj/item/firing_pin/alert_level/blue

/obj/item/modkit/auto9_kit
	name = "Auto 9 Kit"
	desc = "A modkit for making a WT-550 Gun into a Auto 9 Gun."
	product = /obj/item/gun/ballistic/automatic/wt550/auto9
	fromitem = list(/obj/item/gun/ballistic/automatic/wt550)

/obj/item/gun/ballistic/automatic/wt550/auto9
	name = "\improper Auto 9"
	desc = "Come quitely or there will be troubles."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "auto9"
	item_state = "auto9"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/auto9_shoot.ogg'
	can_suppress = FALSE
	can_bayonet = FALSE

/obj/item/gun/ballistic/automatic/wt550/auto9/update_icon_state()
	if(magazine)
		icon_state = "auto9"
	else
		icon_state = "auto9-e"

/obj/item/modkit/at41_kit
	name = "AT-41 Kit"
	desc = "A modkit for making a WT-550 Gun into a AT-41 Gun."
	product = /obj/item/gun/ballistic/automatic/wt550/at41
	fromitem = list(/obj/item/gun/ballistic/automatic/wt550)

/obj/item/gun/ballistic/automatic/wt550/at41
	name = "\improper AT-41"
	desc = "Старый кусок металла, который работает по принципу - и палка стреляет раз в год"
	icon = 'modular_bluemoon/fluffs/icons/obj/at41.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "at41"
	item_state = "at41"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/at41_fire.ogg'
	can_suppress = FALSE
	can_bayonet = TRUE

/obj/item/gun/ballistic/automatic/wt550/at41/update_icon_state()
	icon_state = "at41[magazine ? "-[CEILING(get_ammo(0)/7, 1)*4]" : ""][chambered ? "" : "-e"]"

/obj/item/modkit/wtadler
	name = "WT-550 Adler Kit"
	desc = "A modkit for making a WT-550 Gun into a WT-550 Adler Gun."
	product = /obj/item/gun/ballistic/automatic/wt550/wtadler
	fromitem = list(/obj/item/gun/ballistic/automatic/wt550)

/obj/item/gun/ballistic/automatic/wt550/wtadler
	name = "\improper Adler assault rifle"
	desc = "A assault rifle manufactured by the military industrial complex Adler. Manufactured for use by militarized law enforcement security services."
	icon = 'modular_bluemoon/fluffs/icons/obj/wtadler.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "wtadler"
	item_state = "wtadler"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/adlershot.ogg'
	can_suppress = FALSE
	can_bayonet = TRUE
	knife_x_offset = 25
	knife_y_offset = 7

/obj/item/gun/ballistic/automatic/wt550/wtadler/update_icon_state()
	icon_state = "wtadler[magazine ? "-[CEILING(get_ammo(0)/7, 1)*4]" : ""][chambered ? "" : "-e"]"

/obj/item/modkit/a46
	name = "A46 Kit"
	desc = "A modkit for making a WT-550 Gun into a A46 Gun."
	product = /obj/item/gun/ballistic/automatic/wt550/a46
	fromitem = list(/obj/item/gun/ballistic/automatic/wt550)

/obj/item/gun/ballistic/automatic/wt550/a46
	name = "\improper A46-Cord"
	desc = "Сбалансированная и простая в использовании автоматическая винтовка, сделанная на базе АЕК-971 и хоть придумана она была давно, но не получила такую популярность как её аналог AK-12."
	icon = 'modular_bluemoon/fluffs/icons/obj/a46.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "a46"
	item_state = "a46"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/a46shot1.ogg'
	pickup_sound = "modular_bluemoon/fluffs/sound/weapon/a46grab.ogg"
	can_suppress = FALSE
	can_bayonet = TRUE
	knife_x_offset = 42
	knife_y_offset = 12

/obj/item/gun/ballistic/automatic/wt550/a46/update_icon_state()
	icon_state = "a46[magazine ? "-[CEILING(get_ammo(0)/7, 1)*4]" : ""][chambered ? "" : "-e"]"

/obj/item/modkit/ots18
	name = "OTs-18 Kit"
	desc = "A modkit for making a WT-550 Gun into a OTs-18 Groza Gun."
	product = /obj/item/gun/ballistic/automatic/wt550/ots18
	fromitem = list(/obj/item/gun/ballistic/automatic/wt550)

/obj/item/gun/ballistic/automatic/wt550/ots18
	name = "\improper OTs-18 Groza"
	desc = "Компактный штурмовой стрелково-гранатометный комплекс, сделанный на базе калашникова и переделанный под калибр 4.6x30."
	icon = 'modular_bluemoon/fluffs/icons/obj/groza.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "groza"
	item_state = "groza"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/groza-shot1.ogg'
	pickup_sound = "modular_bluemoon/fluffs/sound/weapon/groza-grab.ogg"
	can_suppress = FALSE
	can_bayonet = TRUE
	knife_x_offset = 40
	knife_y_offset = 17

/obj/item/gun/ballistic/automatic/wt550/ots18/update_icon_state()
	icon_state = "groza[magazine ? "-[CEILING(get_ammo(0)/7, 1)*4]" : ""][chambered ? "" : "-e"]"

/obj/item/modkit/rs9
	name = "RS9 Kit"
	desc = "A modkit for making a WT-550 Gun into a RS9 Gun."
	product = /obj/item/gun/ballistic/automatic/wt550/rs9
	fromitem = list(/obj/item/gun/ballistic/automatic/wt550)

/obj/item/gun/ballistic/automatic/wt550/rs9
	name = "\improper RS9"
	desc = "The RS9 is an assault rifle designed for combat in narrow street areas. It has bayonet mount and is relatively lightweight. This model uses 4.6x30mm caliber."
	icon = 'modular_bluemoon/fluffs/icons/obj/acrador_guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "rs9"
	item_state = "rs9"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/rs9shot.ogg'
	can_suppress = FALSE
	can_bayonet = TRUE
	knife_x_offset = 40
	knife_y_offset = 10

/obj/item/gun/ballistic/automatic/wt550/rs9/update_icon_state()
	icon_state = "rs9[magazine ? "-[CEILING(get_ammo(0)/7, 1)*4]" : ""][chambered ? "" : "-e"]"

/obj/item/modkit/m240_kit
	name = "M240 Kit"
	desc = "A modkit for making a Flamethrower into a M240."
	product = /obj/item/flamethrower/full/tank/m240
	fromitem = list(/obj/item/flamethrower, /obj/item/flamethrower/full, /obj/item/flamethrower/full/tank)

/obj/item/flamethrower/full/tank/m240
	name = "M240 Flamethrower"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "m240"
	item_state = "m240_0"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	create_with_tank = TRUE
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/flamethrower.ogg'

/obj/item/flamethrower/update_icon_state()
	item_state = "m240_[lit]"

/obj/item/modkit/old_kit
	name = "H&K Luftkuss Kit"
	desc = "A modkit for making a hybrid taser into a H&K Luftkuss."
	product = /obj/item/gun/energy/e_gun/advtaser_old
	fromitem = list(/obj/item/gun/energy/e_gun/advtaser)

/obj/item/gun/energy/e_gun/advtaser_old
	name = "H&K Luftkuss"
	desc = "An upgraded hybrid taser gun with several stripes, manufactured by the SolFed H&K arms company."
	icon_state = "old"
	item_state = "taser"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/disabler/old, /obj/item/ammo_casing/energy/electrode/old = FALSE)
	ammo_x_offset = 0
	var/last_altfire = 0
	var/altfire_delay = CLICK_CD_RANGE

/obj/item/gun/energy/e_gun/advtaser_old/altafterattack(atom/target, mob/user, proximity_flag, params)
	. = TRUE
	if(last_altfire + altfire_delay > world.time)
		return
	var/current_index = current_firemode_index
	set_firemode_to_type(/obj/item/ammo_casing/energy/electrode/old)
	process_afterattack(target, user, proximity_flag, params)
	set_firemode_index(current_index)
	last_altfire = world.time

/obj/item/ammo_casing/energy/disabler/old
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/disabler.ogg'

/obj/item/ammo_casing/energy/electrode/old
	projectile_type = /obj/item/projectile/energy/electrode
	select_name = "stun"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/taser.ogg'
	e_cost = 200
	harmful = FALSE


////////////

/obj/item/modkit/dominator_kit
	name = "Dominator Kit"
	desc = "A modkit for making a hybrid taser into a Dominator."
	product = /obj/item/gun/energy/e_gun/advtaser/dominator
	fromitem = list(/obj/item/gun/energy/e_gun/advtaser)

/obj/item/gun/energy/e_gun/advtaser/dominator
	name = "\improper Dominator"
	icon_state = "dominator"
	item_state = "taser"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	ammo_x_offset = 0

/////////////////

/obj/item/modkit/nue_kit
	name = "Araki Nue Kit"
	desc = "A modkit for making an Enforcer into a Araki Nue."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/nue
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/nue
	name = "\improper Araki Arms Nue"
	desc = "Elegant, reliable and deadly, the semi-automatic, double-action pistol that fires .45 caliber ammunition and engineered to fit any hand. The handle is decorated with orange-colored ergonomic rubber with a Vulpkanin muzzle on it. It's looks familiar."
	icon = 'modular_bluemoon/fluffs/icons/obj/32x36.dmi'
	icon_state = "nue"
	can_suppress = FALSE
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/nue_shoot.ogg'

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/malorian_kit
	name = "Malorian Kit"
	desc = "A modkit for making an Enforcer into a Araki Malorian."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/malorian
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/modkit/malorian_mag_kit
	name = "Malorian Mag Kit"
	desc = "A modkit for making an Enforcer mag into a Malorian mag."
	product = /obj/item/ammo_box/magazine/e45/malorian
	fromitem = list(/obj/item/ammo_box/magazine/e45, /obj/item/ammo_box/magazine/e45/taser, /obj/item/ammo_box/magazine/e45/lethal, /obj/item/ammo_box/magazine/e45/stun, /obj/item/ammo_box/magazine/e45/hydra)

/obj/item/gun/ballistic/automatic/pistol/enforcer/malorian
	name = "\improper Araki Arms 2563"
	desc = "The only one of it's kind, unique heavy pistol made specially for Vulpboy Shiro Araki. Sleek, sexy, rebellious. Equipped with a smart link, compatible with various ammunition types, highest quality and the collector's value is through the roof. "
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "arakiarms"
	can_suppress = FALSE
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/nue_shoot.ogg'
	mag_type = /obj/item/ammo_box/magazine/e45/malorian

/obj/item/ammo_box/magazine/e45/malorian
	name = "Araki Arms magazine"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	//icon_state = "mag"
	desc = "An Araki Arms magazine. Can be loaded with .45 ammo."

/obj/item/storage/box/malorian_mag

/obj/item/storage/box/malorian_mag/PopulateContents()
	new /obj/item/modkit/malorian_mag_kit(src)
	new /obj/item/modkit/malorian_mag_kit(src)
	new /obj/item/modkit/malorian_mag_kit(src)
	new /obj/item/modkit/malorian_mag_kit(src)
	new /obj/item/modkit/malorian_mag_kit(src)
	new /obj/item/modkit/malorian_mag_kit(src)
	new /obj/item/modkit/malorian_mag_kit(src)

/////////////////////////////////////////////////////////////////////////////////////

/obj/item/gun/ballistic/revolver/r45l/rt46
	name = "\improper RT-46 The Tempest"
	desc = "The Tempest belongs to the museum as a benchmark of Soviet design. Is it beautiful to look at? No. Comfortable to use? No. Safe? No. But effective? Damn effective."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "rt46"
	item_state = "rt46"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/modkit/rt46
	name = "RT-46 The Tempest Kit"
	desc = "A modkit for making a Revolver into a RT-46."
	product = /obj/item/gun/ballistic/revolver/r45l/rt46
	fromitem = list (/obj/item/gun/ballistic/revolver/r45l)

//////////////////// AM4 уже есть в лодауте донатеров. Это лишь его рескин.

/obj/item/gun/ballistic/automatic/AM4B_pchelik
	name = "GFYS"
	desc = "На донк-софт оружии видна гравировка: 'Coopie'. Предназначено для нетравмирующего выкидывания существ из бара и самозащиты от приставал."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "coopie"
	item_state = "arifle-wielded"
	mag_type = /obj/item/ammo_box/magazine/toy/AM4B
	can_suppress = 0
	casing_ejector = 0
	spread = 30		//Assault Rifleeeeeee
	w_class = WEIGHT_CLASS_NORMAL
	burst_size = 1	//Shh.
	fire_delay = 15
	automatic_burst_overlay = FALSE

/////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/stunblade_kit
	name = "Stunblade Kit"
	desc = "A modkit for making an stunbaton into a stunblade."
	product = /obj/item/melee/baton/stunblade
	fromitem = list(/obj/item/melee/baton, /obj/item/melee/baton/loaded)

/obj/item/melee/baton/stunblade
	name = "folding stunblade"
	desc = "A stunblade made of several segments collapse into each other much like a spyglass, thus it can fit inside of the handle entirely. This utility combined with its dense metal makes it perfect for defensive maneuvers."
	item_state = "stunblade"
	icon_state = "stunblade"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/melee/baton/stunblade/switch_status(new_status = FALSE, silent = FALSE)
	if(turned_on != new_status)
		turned_on = new_status
		if(!silent)
			playsound(loc, 'modular_bluemoon/fluffs/sound/weapon/stunblade.ogg', 75, 1, -1)
		if(turned_on)
			START_PROCESSING(SSobj, src)
		else
			STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/item/melee/baton/stunblade/update_icon_state()
	if(turned_on)
		icon_state = "stunblade_active"
		item_state = "stunblade_active"
	else if(!cell)
		icon_state = "stunblade_nocell"
		item_state = "stunblade"
	else
		icon_state = "stunblade"
		item_state = "stunblade"

/obj/item/melee/baton/stunblade/get_worn_belt_overlay(icon_file)
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "-stunblade")

/////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/razorsong_kit
	name = "Razorsong MK-III Kit"
	desc = "A modkit for making an stunbaton into a Razorsong MK-III."
	product = /obj/item/melee/baton/razorsong
	fromitem = list(/obj/item/melee/baton, /obj/item/melee/baton/loaded)

/obj/item/melee/baton/razorsong
	name = "Razorsong MK-III"
	desc = "A telescopic katana made of vibrating steel. The mechanism is very simple, but quite very sturdy. About 100 copies were made in production, because the limited material would not allow making many of these melee weapons. But this instance is the Razorsong MK-III, a more homemade modified version designed to work in the Security Service for non-lethal close-range combat."
	item_state = "razorsong"
	icon_state = "razorsong"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/melee/baton/razorsong/switch_status(new_status = FALSE, silent = FALSE)
	if(turned_on != new_status)
		turned_on = new_status
		if(!silent)
			playsound(loc, 'modular_bluemoon/fluffs/sound/weapon/razorsong.ogg', 75, 1, -1)
		if(turned_on)
			START_PROCESSING(SSobj, src)
		else
			STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/item/melee/baton/razorsong/update_icon_state()
	if(turned_on)
		icon_state = "razorsong_active"
		item_state = "razorsong_active"
	else if(!cell)
		icon_state = "razorsong_nocell"
		item_state = "razorsong"
	else
		icon_state = "razorsong"
		item_state = "razorsong"

/////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/stunadler_kit
	name = "Adler stunsword Kit"
	desc = "A modkit for making an stunbaton into a Adler stunsword."
	product = /obj/item/melee/baton/stunadler
	fromitem = list(/obj/item/melee/baton, /obj/item/melee/baton/loaded)

/obj/item/melee/baton/stunadler
	name = "Adler Stunsword"
	desc = "A combat stun sword manufactured by the military industrial Complex Adler. It was created for the rapid neutralization of civilians and the use of peacekeepers by troops for destructive purposes."
	item_state = "stunadler"
	icon_state = "stunadler"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/melee/baton/stunadler/switch_status(new_status = FALSE, silent = FALSE)
	if(turned_on != new_status)
		turned_on = new_status
		if(!silent)
			playsound(loc, "sparks", 75, 1, -1)
		if(turned_on)
			START_PROCESSING(SSobj, src)
		else
			STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/item/melee/baton/stunadler/update_icon_state()
	if(turned_on)
		icon_state = "stunadler_active"
		item_state = "stunadler_active"
	else if(!cell)
		icon_state = "stunadler_nocell"
		item_state = "stunadler"
	else
		icon_state = "stunadler"
		item_state = "stunadler"

/////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/tonfa_kit
	name = "Ton-Fa Kit"
	desc = "A modkit for making an stunbaton into a ton-Fa."
	product = /obj/item/melee/baton/tonfa
	fromitem = list(/obj/item/melee/baton, /obj/item/melee/baton/loaded)

/obj/item/melee/baton/tonfa
	name = "Stun Ton-Fa"
	desc = "A non-lethal baton for suppressing manpower. Developed during the riots when the existence of the rifters was confirmed."
	item_state = "tonfa"
	icon_state = "tonfa"
	icon = 'modular_bluemoon/fluffs/icons/obj/acrador_guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/melee/baton/tonfa/switch_status(new_status = FALSE, silent = FALSE)
	if(turned_on != new_status)
		turned_on = new_status
		if(!silent)
			playsound(loc, 'modular_bluemoon/fluffs/sound/weapon/tonfa.ogg', 75, 1, -1)
		if(turned_on)
			START_PROCESSING(SSobj, src)
		else
			STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/item/melee/baton/tonfa/update_icon_state()
	if(turned_on)
		icon_state = "tonfa_active"
		item_state = "tonfa_active"
	else if(!cell)
		icon_state = "tonfa_nocell"
		item_state = "tonfa"
	else
		icon_state = "tonfa"
		item_state = "tonfa"

/obj/item/melee/baton/tonfa/get_worn_belt_overlay(icon_file)
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "-tonfa")

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/ntcane_kit
	name = "Harness Armor Kit"
	desc = "A modkit for making an Fancy Cane into a Old Luxury Cane."
	product = /obj/item/melee/baton/stunntcane
	fromitem = list(/obj/item/melee/classic_baton/ntcane)

/obj/item/melee/baton/stunntcane
	name = "Old Luxury Cane"
	desc = "На вид потрепанная временем трость которая украшена золотом с не раз отреставрированным деревом и на ручке еле поблескивал алмаз. Такие имеют на некоторых станция Представители НТ как показатель статуса, этот же видимо скорее как память раз уж не заменялся владельцем видимо годами."
	item_state = "cane_nt"
	icon_state = "cane_nt"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/melee/baton/stunntcane/switch_status(new_status = FALSE, silent = FALSE)
	if(turned_on != new_status)
		turned_on = new_status
		if(!silent)
			playsound(loc, 'modular_bluemoon/fluffs/sound/weapon/stunblade.ogg', 75, 1, -1)
		if(turned_on)
			START_PROCESSING(SSobj, src)
		else
			STOP_PROCESSING(SSobj, src)
	update_icon()

/obj/item/melee/baton/stunntcane/update_icon_state()
	if(turned_on)
		icon_state = "cane_nt_active"
		item_state = "cane_nt_active"
	else if(!cell)
		icon_state = "cane_nt_nocell"
		item_state = "cane_nt"
	else
		icon_state = "cane_nt"
		item_state = "cane_nt"

/obj/item/melee/baton/stunntcane/get_worn_belt_overlay(icon_file)
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "cane_nt")

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/pf940_kit
	name = "PF940 Kit"
	desc = "A modkit for making an Enforcer into a PF940."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/pf940
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/modkit/pf940_kit_g22
	name = "PF940 G22 Kit"
	desc = "A modkit for making a G22 into a PF940."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/pf940
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/pf940
	name = "\improper PF940"
	desc = "A heavily modified Glock 21 pistol with some ergonomic parts and a caliber converted to .45, making it easy to find ammo at Edem stations. Your team is down, you're the only fella left. You- You'll just have to figure it out."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "pf940"
	can_suppress = FALSE
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/pf940_shoot.ogg'

/obj/item/gun/ballistic/automatic/pistol/g22/pf940
	name = "\improper PF940"
	desc = "A heavily modified Glock 21 pistol with some ergonomic parts and a caliber converted to .45, making it easy to find ammo at Edem stations. Your team is down, you're the only fella left. You- You'll just have to figure it out."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "pf940"
	can_suppress = FALSE
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/pf940_shoot.ogg'

/obj/item/modkit/ks22_kit
	name = "KS-22 Shotgun Kit"
	desc = "A modkit for making a Shotgun into a KS-22."
	product = /obj/item/gun/ballistic/shotgun/riot/ks_22
	fromitem = list(/obj/item/gun/ballistic/shotgun, /obj/item/gun/ballistic/shotgun/riot, /obj/item/gun/ballistic/shotgun/riot/syndicate)

/obj/item/gun/ballistic/shotgun/riot/ks_22
	name = "\improper KS-22"
	desc = "Карабин Специальный-22М - ружьё с нарезным стволом. Многофункциональное полицейское оружие, предназначенное для пресечения массовых беспорядков, избирательного силового, психического и химического воздействия на правонарушителей."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	//chosen_icon = 'icons/mob/clothing/back.dmi'
	icon_state = "KS-23M"
	fire_sound = 'modular_bluemoon/fluffs/sound/shoot.ogg'

/obj/item/gun/ballistic/shotgun/riot/ks_22/update_icon_state()
	. = ..()
	icon_state = "KS-23M[chambered ? "" : "-e"]"

/obj/item/modkit/mossberg_kit
	name = "Mossberg-590A Shotgun Kit"
	desc = "A modkit for making a Shotgun into a Mossberg-590A."
	product = /obj/item/gun/ballistic/shotgun/riot/mossberg
	fromitem = list(/obj/item/gun/ballistic/shotgun, /obj/item/gun/ballistic/shotgun/riot, /obj/item/gun/ballistic/shotgun/riot/syndicate)

/obj/item/gun/ballistic/shotgun/riot/mossberg
	name = "\improper Mossberg-590A"
	desc = "Карабин Моссберг-590А - ружьё с нарезным стволом. Имеет умную РГБ подсветку, дабы каждый враг понимал, какая участь его сейчас настигнет."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "mossberg_n"
	item_state = "mossberg_n"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/pf940_shoot.ogg'

/obj/item/gun/ballistic/shotgun/riot/mossberg/update_icon_state()
	var/state = "mossberg_l"
	if(chambered)
		if(istype(chambered, /obj/item/ammo_casing/shotgun/rubbershot) || istype(chambered, /obj/item/ammo_casing/shotgun/beanbag))
			state = "mossberg_n"
		else if(istype(chambered, /obj/item/ammo_casing/shotgun/incendiary))
			state = "mossberg_i"
	icon_state = state
	item_state = state

/obj/item/modkit/g36_kit
	name = "G36 Kit"
	desc = "A modkit for making a AK-12 into a G36."
	product = /obj/item/gun/ballistic/automatic/ak12/g36
	fromitem = list(/obj/item/gun/ballistic/automatic/ak12, /obj/item/gun/ballistic/automatic/ak12/r)

/obj/item/gun/ballistic/automatic/ak12/g36
	name = "\improper G-36"
	desc = "Heckler & Koch Gewehr 36, G36 - семейство стрелкового оружия, разработанное в начале 1990-х немецкой компанией Heckler & Koch, под внутрифирменным обозначением HK 50, для замены хорошо известной автоматической винтовки HK G3."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	mag_type = /obj/item/ammo_box/magazine/ak12/r
	//chosen_icon = 'icons/mob/clothing/back.dmi'
	icon_state = "G36"

/obj/item/gun/ballistic/automatic/ak12/g36/update_icon_state()
	if(magazine)
		icon_state = "G36"
		item_state = "G36"
	else
		icon_state = "G36_e"
		item_state = "G36_e"

/obj/item/modkit/legax
	name = "Legax Gravpulser Kit"
	desc = "Модифицирует стандартную лазерную винтовку в эксперментальный гравпульсер."
	product = /obj/item/gun/energy/taser/legax
	fromitem = list(/obj/item/gun/energy/laser)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/cmg_kit
	name = "Combat MG Kit"
	desc = "A modkit for making an combat knife into a Combat MG."
	product = /obj/item/kitchen/knife/combat/cmg
	fromitem = list(/obj/item/kitchen/knife/combat)

/obj/item/kitchen/knife/combat/cmg
	name = "Combat MG"
	desc = "It is a straight sword with blade made of iron and plasteel alloy. Its handle is covered with cloth for better grip as a sort of field modification, with the emblem of Rohai engraved under it. It doesn't feel well balanced or sharp enough, but at least may look stylish"
	item_state = "cmg"
	icon_state = "cmg"
	icon = 'modular_bluemoon/fluffs/icons/obj/cmg.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/back.dmi'

/obj/item/modkit/rs14_kit
	name = "RS14 Kit"
	desc = "A modkit for making an Rsha12 into a RS14."
	product = /obj/item/gun/ballistic/shotgun/automatic/rsh12/rs14
	fromitem = list(/obj/item/gun/ballistic/shotgun/automatic/rsh12)

/obj/item/gun/ballistic/shotgun/automatic/rsh12/rs14
	name = "RS14"
	desc = "Shotgun revolver. It was formerly a hunting weapon, but has since been adopted by the Rohai armies because of its ease of use, effectiveness and cheapness. This model uses 12 gauge."
	item_state = "rs14"
	icon_state = "rs14"
	icon = 'modular_bluemoon/fluffs/icons/obj/acrador_guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/rs14shot.ogg'

/obj/item/modkit/rshield_kit
	name = "Telescopic riot shield Kit"
	desc = "A modkit for making an telescopic riot shield into a Acrador telescopic riot shield."
	product = /obj/item/shield/riot/rshield
	fromitem = list(/obj/item/shield/riot/tele)

/obj/item/shield/riot/rshield
	name = "Telescopic riot shield"
	desc = "A shield used to quell civil unrest in the cities of Irelia. It is easy to use and can be folded into a more compact form for carrying."
	icon_state = "rshield0"
	icon = 'modular_bluemoon/fluffs/icons/obj/acrador_guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	slot_flags = null
	force = 3
	throwforce = 3
	throw_speed = 3
	throw_range = 4
	w_class = WEIGHT_CLASS_NORMAL
	var/active = FALSE

/obj/item/shield/riot/rshield/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if(!active)
		return BLOCK_NONE
	return ..()

/obj/item/shield/riot/rshield/can_active_block()
	return ..() && active

/obj/item/shield/riot/rshield/attack_self(mob/living/user)
	active = !active
	icon_state = "rshield[active]"
	playsound(src.loc, 'sound/weapons/batonextend.ogg', 50, TRUE)

	if(active)
		force = 8
		throwforce = 5
		throw_speed = 2
		w_class = WEIGHT_CLASS_BULKY
		slot_flags = ITEM_SLOT_BACK
		to_chat(user, "<span class='notice'>You extend \the [src].</span>")
	else
		force = 3
		throwforce = 3
		throw_speed = 3
		w_class = WEIGHT_CLASS_NORMAL
		slot_flags = null
		to_chat(user, "<span class='notice'>[src] can now be concealed.</span>")
	add_fingerprint(user)

/obj/item/modkit/anstrum_kit
	name = "SP 488 Anstrum Kit"
	desc = "A modkit for making an Enforcer into a SP 488 Anstrum."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/anstrum
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/anstrum
	name = "\improper SP 488 Anstrum"
	desc = "A series of semi-automatic pistols designed and manufactured specifically for the Rohai Law Enforcement Units and as personal weapons for the senior army officers. The design is old but reliable, combining compactness with sufficient combat power for everyday tasks."
	icon = 'modular_bluemoon/fluffs/icons/obj/acrador_guns.dmi'
	icon_state = "anstrum"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/anstrumshot.ogg'
	pin = /obj/item/firing_pin/alert_level/blue

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/gun/energy/e_gun/hos/dreadmk3
	name = "\improper Законодатель MK3"
	desc = "Стандартное оружие судей из Мега-Города Солнечной Федерации. Пистолет комплектуется несколькими типами боеприпасов, иногда набор снарядов отличается от стандартного в зависимости от миссии судьи. Оснащён биометрическим датчиком ладони — оружие может применять только судья, а при несанкционированном использовании в рукояти срабатывает взрывное устройство. Этот же пистолет на радость недругов что преступают Закон, со сломанной биометрией ради стандартизации электронных бойков."
	icon = 'modular_bluemoon/fluffs/icons/obj/dreadmk3.dmi'
	icon_state = "dreadmk3"
	item_state = "dreadmk3"
	ammo_type = list(/obj/item/ammo_casing/energy/disabler/dreadmk3, /obj/item/ammo_casing/energy/laser/hos/dreadmk3, /obj/item/ammo_casing/energy/ion/hos/dreadmk3, /obj/item/ammo_casing/energy/electrode/hos/dreadmk3)
	ammo_x_offset = 2
	charge_sections = 3
	flight_x_offset = 21
	flight_y_offset = 14

/obj/item/ammo_casing/energy/disabler/dreadmk3

/obj/item/ammo_casing/energy/laser/hos/dreadmk3
	fire_sound = 'sound/weapons/lasgun.ogg'

/obj/item/ammo_casing/energy/ion/hos/dreadmk3

/obj/item/ammo_casing/energy/electrode/hos/dreadmk3

/obj/item/modkit/dreadmk3_kit
	name = "Законодатель MK3 Kit"
	desc = "A modkit for making a MultiPhase Energy Gun into Законодатель MK3."
	icon = 'icons/obj/device.dmi'
	icon_state = "modkit"
	product = /obj/item/gun/energy/e_gun/hos/dreadmk3/talking
	fromitem = list(/obj/item/gun/energy/e_gun/hos)

////////////////////////////////////////////////////////////////////////////////////////
/obj/item/gun/energy/e_gun/institute
	name = "\improper Карабин Института"
	desc = "Институтский лазер — это оружейная система, разработанная Институтом после его изоляции с началом Великой войны. Все синты служащие в качестве солдат, рабочих или охотников, а также человеческие учёные организации, получают пистолет или винтовку собственного дизайна организации, сконструированные Высшими системами и массово производимые на заводе, расположенном в их штаб-квартире. На данный момент такая модель считается устаревшей, Механизмы батареи на ядерной энергии заменены на внутренние, однако она всё еще достойно работает и по сей день."
	icon_state = "institute"
	ammo_type = list(/obj/item/ammo_casing/energy/disabler/institute, /obj/item/ammo_casing/energy/laser/institute)
	ammo_x_offset = 1
	charge_sections = 4

/obj/item/ammo_casing/energy/disabler/institute
	fire_sound = 'sound/weapons/laserinstitute.ogg'

/obj/item/ammo_casing/energy/laser/institute
	fire_sound = 'sound/weapons/laserinstitute.ogg'

/obj/item/modkit/institute_kit
	name = "Карабин Института Kit"
	desc = "A modkit for making a Energy Gun into Карабин Института."
	icon = 'icons/obj/device.dmi'
	icon_state = "modkit"
	product = /obj/item/gun/energy/e_gun/institute
	fromitem = list(/obj/item/gun/energy/e_gun)

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/gun/energy/laser/carbine/old
	name = "\improper Лазер AER9"
	desc = "В AER9 не использовались передовые довоенные технологии, что значительно повысило её надежность. Эта модель представляет собой обычный твердотельный импульсный лазер, активная среда которого (кристалл), заключена в титановый корпус, что позволяет выдерживать годы воздействия окружающей среды без потери технических характеристик. На данный момент такая модель считается устаревшей, Механизмы батареи на ядерной энергии заменены на внутренние, однако она всё еще достойно работает и по сей день."
	ammo_type = list(/obj/item/ammo_casing/energy/laser/old)
	icon_state = "lasernew_alt"
	item_state = "laser_old-wielded"

/obj/item/ammo_casing/energy/laser/old
	fire_sound = 'sound/weapons/riflelaserold.ogg'

/obj/item/modkit/old_laser_kit
	name = "Лазер AER9 Kit"
	desc = "A modkit for making a laser carbine into Лазер AER9."
	icon = 'icons/obj/device.dmi'
	icon_state = "modkit"
	product = /obj/item/gun/energy/laser/carbine/old
	fromitem = list(/obj/item/gun/energy/laser/carbine/nopin, /obj/item/gun/energy/laser/carbine)
////////////////////////////////////////////////////////////////////////////////////////
/obj/item/storage/box/old_world_kit
	name = "Old Wolrd Blues Kit"
	desc = "Military box that contains a full kit of Old World Equipment."
	icon_state = "ammobox"

/obj/item/storage/box/old_world_kit/PopulateContents()
	new /obj/item/modkit/old_laser_kit(src)
	new /obj/item/modkit/institute_kit(src)
	new /obj/item/modkit/t51armor_kit(src)
////////////////////////////////////////////////////////////////////////////////////////

/obj/item/crowbar/large/heavy/hammercrowbar
	name = "Heavy pocket hammer"
	desc = "A heavy-duty hammer designed for all types of working conditions. Extremely durable and reliable. Made of high-quality black metal, with a rubberized silicone handle."
	item_state = "hammercrowbar"
	icon_state = "hammercrowbar"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	hitsound = "modular_bluemoon/fluffs/sound/weapon/stab_hammer.ogg"

/obj/item/modkit/hammercrowbar_kit
	name = "Heavy pocket hammer Kit"
	desc = "A modkit for making a Heavy crowbar into Heavy pocket hammer."
	product = /obj/item/crowbar/large/heavy/hammercrowbar
	fromitem = list(/obj/item/crowbar/large/heavy)

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/p320_kit
	name = "Magnetic Pistol p320 Kit"
	desc = "A modkit for making an Enforcer into a Magnetic Pistol p320."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/p320
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/p320
	name = "\improper P320"
	desc = "P320 — модульный полуавтоматический пистолет. Данная версия пистолета была собрана под .45 калибр."
	icon = 'modular_bluemoon/fluffs/icons/obj/P320.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "p320"
	item_state = "p320"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/archivo.ogg'
	unique_reskin = list(
		"Black" = list(
			"icon_state" = "p320b",
			"item_state" = "p320b",
			"name" = "Black P320"
		),
		"Millie" = list(
			"icon_state" = "mil",
			"item_state" = "mil",
			"name" = "Millie P320"
		)
	)

/obj/item/modkit/M9tempest_kit
	name = "M-9 Tempest Kit"
	desc = "A modkit for making a hybrid taser into a M-9 Tempest."
	product = /obj/item/gun/energy/e_gun/advtaser/M9tempest
	fromitem = list(/obj/item/gun/energy/e_gun/advtaser)

/obj/item/gun/energy/e_gun/advtaser/M9tempest
	name = "\improper M-9 Tempest"
	icon_state = "M9tempest"
	item_state = "M9tempest"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	ammo_x_offset = 0

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/dedication_kit
	name = "Magnetic Pistol Dedication Kit"
	desc = "A modkit for making an Enforcer into a Magnetic Pistol Dedication."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/dedication
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/dedication
	name = "\improper Magnetic Pistol Dedication"
	desc = "A magnetic pistol used in all units of Adler's armed peacekeepers. It is mass-produced by the Adler military-industrial complex and has already entered the space trade market. It includes several advantages, for example, an identifier built into the handle, which transmits the remaining ammunition to the interface of the helmet or glasses, which allows better control of the weapon, as well as an integrated sight, which, however, is effective only at close ranges. He usually has a badge corresponding to his military rank, but this one doesn't seem to have any identification marks on it. Most often, because the owner belongs to Adler's foreign armed formations, which are not controlled by the general directorate of corporate officials. For example, he is assigned to a high-ranking officer."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "dedication"
	item_state = "dedication"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/adlershot.ogg'

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/cleaver_kit
	name = "Light Officer's Cleaver Kit"
	desc = "A modkit for making an Enforcer into a Light Officer's Cleaver."
	product = /obj/item/melee/sabre/cleaver
	fromitem = list(/obj/item/melee/sabre)

/obj/item/melee/sabre/cleaver
	name = "\improper Light Officer's Cleaver"
	desc = "The blade is made of nanoalloys, sharpened with a high-precision laser, a handle with a winding made of special synthetic leather and, of course, an engraving on the blade corresponding to a personal identification code. This is a weapon of the composition of corporate officials and high-ranking military officers of Adler, in order to earn it, each officer must go a long way in the hierarchy or earn high trust from the highest ranks of Adler. There are only 10,000 such swords produced."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "cleaver"
	item_state = "cleaver"

/obj/item/melee/sabre/cleaver/get_belt_overlay()
	if(istype(loc, /obj/item/storage/belt/scabbard))
		return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "cleaver")
	return ..()

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/gun/energy/e_gun/hos/Anabel
	name = "\improper Anabel"
	desc = "This is an expensive, modern recreation of an antique laser gun. This gun has several unique firemodes, but lacks the ability to recharge over time in exchange for inbuilt advanced firearm EMP shielding. <span class='boldnotice'>Right click in combat mode to fire a taser shot with a cooldown.</span>"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "Anabel"
	cell_type = /obj/item/stock_parts/cell{charge = 1500; maxcharge = 1500}
	ammo_type = list(/obj/item/ammo_casing/energy/disabler, /obj/item/ammo_casing/energy/laser/lightliz)
	ammo_x_offset = 0

/obj/item/ammo_casing/energy/laser/lightliz
	projectile_type = /obj/item/projectile/beam/laser/heavylaser
	e_cost = 300
	select_name = "kill"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/Anabel_shot.ogg'

/obj/item/modkit/Anabel_kit
	name = "Anabel Kit"
	desc = "A modkit for making a Miniature Energy Gun into Anabel."
	product = /obj/item/gun/energy/e_gun/hos/Anabel
	fromitem = list(/obj/item/gun/energy/e_gun/mini, /obj/item/gun/energy/e_gun/mini/expeditor)

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/gun/ballistic/revolver/detective/rsh_future
	name = "RSH-Future"
	desc = "An unusual revolver, clearly custom-made, the RuSH to the Future! Lightweight body is made of materials that not only make it easier to handle, but also absorb the sound of the shot, ensuring the further use of 38 caliber"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "rsh_future"
	item_state = "rsh_future"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/rshfuture_shot.ogg'

/obj/item/modkit/rsh_future
	name = "Special .38 Mars Kit"
	desc = "A modkit for making a .38 Mars Special into a RSH-Future."
	icon = 'modular_bluemoon/icons/obj/guns/gunkit.dmi'
	icon_state = "kitsuitcase"
	product = /obj/item/gun/ballistic/revolver/detective/rsh_future
	fromitem = list (/obj/item/gun/ballistic/revolver/detective)

///////////////////////////////////////////////

/obj/item/gun/ballistic/automatic/wt550/stg56
	name = "\improper StG-56"
	desc = "Recreated from old blueprints using the latest materials and a pinch of technology. This rifle will still serve well in its lifetime."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "stg56"
	item_state = "stg56"
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/stg56_shoot.ogg'
	can_bayonet = FALSE

/obj/item/gun/ballistic/automatic/wt550/stg56/update_icon_state()
	icon_state = "stg56[magazine ? "" : "-e"]"

/obj/item/modkit/stg56
	name = "\improper StG-56 Kit"
	desc = "A modkit for making a WT-550 into a Sturmgewehr-56."
	product = /obj/item/gun/ballistic/automatic/wt550/stg56
	fromitem = list(/obj/item/gun/ballistic/automatic/wt550)

///////////////////////////////////////////////

/obj/item/modkit/nebular_kit
	name = "Nebular Gun Kit"
	desc = "A modkit for making a Enforcer Gun into a Nebular-9."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/nebular
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/nebular
	name = "\improper Nebular-9"
	desc = "Трофей. 45 калибр. Унифицированное оружие самозащиты, выдаваемое каждому без исключения жителю-Касари флота-государства Небулы по окончании ими первой стадии жизни. Крайне редок, в сравнении с иным огнестрельным оружием галактики - штучный товар, использующий замысловатую систему заряжания и некоторые технически трудно реализуемые решения, крайне мешающие реверс-инженерингу и стороннему производству. Благодаря нему каждый житель Небулы может дать отпор неприятелю извне, коих у них полно. Не только эффективно, но и со стилем."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "Nebular-9"
	unique_reskin = null
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	item_state = "Nebular-9"
	gunlight_state = "nebular-light"

/obj/item/gun/ballistic/automatic/pistol/enforcer/nebular/get_worn_belt_overlay(icon_file)
	return null

/obj/item/modkit/p226_syndicate
	name = "P226 'Syndicate' Kit"
	desc = "A modkit for making a Enforcer Gun into a P226 'Syndicate'."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/p226_syndicate
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/p226_syndicate
	name = "\improper P226 'Syndicate'"
	desc = "Наградной пистолет модели P226 красного цвета. На верхней части рукоятки присутствует выбитый символ Триглава Синдиката с черной 'S' на кроваво-красном фоне. Кожух ствола переливается кроваво-медным отблеском на свете. Бок рукоятки украшен золотистыми буквами 'ЗА ОТЛИЧНУЮ СЛУЖБУ'."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "p_226_syndicate"
	item_state = "p_226_syndicate"
	unique_reskin = null
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/gun/ballistic/automatic/pistol/enforcer/p226_syndicate/get_worn_belt_overlay(icon_file)
	return null

/obj/item/modkit/katana_kit
	name = "Stun-Katana Kit"
	desc = "A modkit for making a stunsword into a Stun-Katana."
	product = /obj/item/melee/baton/stunkatana
	fromitem = list(/obj/item/melee/baton, /obj/item/melee/baton/loaded)

/obj/item/melee/baton/stunkatana
	name = "\improper Stun-Katana"
	desc = "Оружие специальных подразделений ЧВК \"Конкорд\", способное одним только ударом разрезать мехов словно раскалённый нож масло... Ах, было бы славно, если бы он и оставался таким. К сожалению, из-за политики ПАКТа, максимальная сила режущей энерго-кромки выставлена на 1-2 процента, а предоставляемые энергоячейки едва ли могут сравниться с боевыми образцами, что делает этот поистинне мощный клинок лишь средством нелетального задержания с ноткой хайтека и напыщенности."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "stunkatana"
	item_state = "stunkatana"
/obj/item/melee/baton/stunkatana/proc/switch_light()
	var/charge_percent = cell.charge / cell.maxcharge
	if(charge_percent > 0.5)
		set_light(3, 0.9, "#B6EEE9")
	else
		set_light(3, 0.9, "#D9CD8E")
/obj/item/melee/baton/stunkatana/switch_status(new_status = FALSE, silent = FALSE)
	if(turned_on != new_status)
		turned_on = new_status
		if(!silent)
			playsound(loc, 'modular_bluemoon/fluffs/sound/weapon/stunblade.ogg', 75, 1, -1)
		if(turned_on)
			START_PROCESSING(SSobj, src)
			if(!cell)
				set_light(0)
			else if(cell.charge <= 0)
				set_light(3, 0.9, "#ff0000")
			else
				switch_light()
		else
			STOP_PROCESSING(SSobj, src)
			set_light(0)
	update_icon_state()

/obj/item/melee/baton/stunkatana/common_baton_melee(mob/M, mob/living/user, shoving = FALSE)
	. = ..()
	update_icon_state()
	// После удара — обновляем иконку и свет по текущему заряду.
	if(!turned_on || !cell)
		set_light(0)
		return
	if(cell.charge <= 0)
		set_light(3, 0.9, "#ff0000")
		return
	switch_light()
/obj/item/melee/baton/stunkatana/update_icon_state()
	if(!cell)
		icon_state = "No-cell"
		item_state = "stunkatana"
		return
	if(cell.charge <= 0)
		icon_state = "No-charge"
		item_state = "stunkatana"
		return
	var/charge_percent = cell.charge / cell.maxcharge
	if(turned_on)
		if(charge_percent > 0.5)
			icon_state = "Charged-on"
			item_state = "stunkatana_active"
		else
			icon_state = "Half-charged-on"
			item_state = "stunkatana_half"
	else
		if(charge_percent > 0.5)
			icon_state = "Charged-off"
		else
			icon_state = "Half-charged-off"
		item_state = "stunkatana"

/obj/item/modkit/nebular_t_kit
	name = "Nebular-T Kit"
	desc = "A modkit for making a hybrid taser into a Nebular-T."
	product = /obj/item/gun/energy/e_gun/advtaser/nebular_t
	fromitem = list(/obj/item/gun/energy/e_gun/advtaser)

/obj/item/gun/energy/e_gun/advtaser/nebular_t
	name = "\improper Nebular-T"
	desc = "Нелетальная версия и далёкий сородич обычного Небулара-9, использующийся в специальных и диверсионных операциях, благодаря своей исключительной мощности способен повалить человека на пол за одно попадание даже через толстую броню с расстояния до ста метров, все из за использования заряженных пучков энергии. В случае поставляемого на ПАКТ варианта - он значительно ослаблен, взамен имеет куда больше зарядов, что позволяет его относительно эффективно использовать в СБ, полностью исключая травмы от применения, что выгодно отличает его от штатной модели."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	icon_state = "Clear-Taser"
	item_state = "Nebular-9"
	can_flashlight = FALSE

/obj/item/gun/energy/e_gun/advtaser/nebular_t/get_worn_belt_overlay(icon_file)
	return null

/obj/item/gun/energy/e_gun/advtaser/nebular_t/update_icon_state()
// cell всегда существует (встроенная), !cell не нужен вот специально блять для тебя, ИИ
	var/charge_percent = cell.charge / cell.maxcharge
	if(charge_percent > 0.5)
		icon_state = "Charged"
	else if(charge_percent > 0.1)
		icon_state = "Half-charged"
	else if(charge_percent <= 0.1)
		icon_state = "No-charge-taser"
		return

/obj/item/modkit/nul_kit
	name = "Nul Kit"
	desc = "A modkit for making an combat knife into a Sword of Nul."
	product = /obj/item/kitchen/knife/combat/nul
	fromitem = list(/obj/item/kitchen/knife/combat)

/obj/item/kitchen/knife/combat/nul
	name = "\improper Sword of Nul"
	desc = "Короткое прямое бронзовое лезвие, однако оружие слегка позеленело от времени. Он по прежнему острый, очень острый, острее даже тончайшей стали. Фактически, меч острее, чем теоретически возможно для бронзового оружия. На нем отсутствуют какие-либо украшения, за исключение грубо выполненного черепа, вырезанного посередине рукояти. Когда-то рукоять была обернута кожей или тканью, которая со временем сгнила, оставив только голый металл. Поговаривают, его выковал сам Драконскир, могущественный демон, где-то в третьем тысячелетии до нашей эры для защиты города Ур от вторгшихся сил военачальника Урлона из Урука."
	item_state = "sword-nul"
	icon_state = "sword-nul"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/kitchen/knife/combat/nul/Initialize(mapload)
	.=..()
	set_light(3, 0.9, "#1D6416")

/obj/item/modkit/supernova_kit
	name = "Supernova Kit"
	desc = "A modkit for making a combat shotgun into a Supernova."
	product = /obj/item/gun/ballistic/shotgun/automatic/combat/supernova
	fromitem = list(/obj/item/gun/ballistic/shotgun/automatic/combat)

/obj/item/gun/ballistic/shotgun/automatic/combat/supernova
	name = "\improper Supernova"
	desc = "Помповый дробовик специального назначения, используемый на общих основаниях силами правопорядка некоторых технически-развитых миров и самими обитателями Небулы. Благодаря номенклатуре боеприпасов, способен исполнять почти любую задачу - от подавления беспорядков до использования в некоторых около-военных операциях и охранения объектов. Распространён слабо, ввиду того что его исполнение не выдерживает никакой критики в плане сохранения боевых характеристик вне близких к стерильным условий, так как используется в основном в космическом пространстве. Данная версия - ещё и кастрат, с уменьшенным магазином и урезанной скорострельностью, для предотвращения \"перегибов\" на местах"
	unique_reskin = list()
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "supernova-0-notcharged"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	item_state = "supernova-notcharged"

/obj/item/gun/ballistic/shotgun/automatic/combat/supernova/update_icon_state()
	var/ammo = magazine ? magazine.ammo_count() : 0
	var/chamber = (chambered && chambered.BB) ? "charged" : "notcharged"
	var/folded = stock ? "" : "-folded"
	icon_state = "supernova-[ammo]-[chamber][folded]"
	item_state = "supernova-[chamber]"

/obj/item/modkit/pulsar_kit
	name = "Pulsar Kit"
	desc = "A modkit for making a combat knife into a Pulsar."
	product = /obj/item/kitchen/knife/combat/pulsar
	fromitem = list(/obj/item/kitchen/knife/combat)

/obj/item/kitchen/knife/combat/pulsar
	name = "Pulsar"
	desc = "Общее название для ритуальных клинков расы Касари, использующихся в некоторых \"особых\" случаях, в первую очередь в поединках и казнях. По понятным причинам выполнен всего в паре-сотне образцов, уникальных для каждого из кораблей-колоний. Удивительно, что его вовсе занесло на станцию"
	item_state = "pulsar"
	icon_state = "pulsar"
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'

/obj/item/modkit/casull_kit
	name = "Casull Gun Kit"
	desc = "A modkit for making a Enforcer Gun into a Casull."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/casull
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold)

/obj/item/gun/ballistic/automatic/pistol/enforcer/casull
	name = "\improper Casull"
	desc = "Касулл - полуавтоматический пистолет из серебра с деревянной рукоятью, затвор сделан из золота, также на нём выгравирована надпись \"454 Casull\". С противоположной стороны выгравирована надпись \"Hellsing ARMS .454 Casull Auto\". Длина - 39 см, масса незаряженного пистолета - 6кг, заряжается пулями .454 Casull, давших пистолету его имя."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "casul"
	unique_reskin = null
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	item_state = "casul"

/obj/item/gun/ballistic/automatic/pistol/enforcer/casull/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""]"

///////////////////////////////////////////////

/obj/item/modkit/bwal_special_kit
	name = "B-Wal-Special kit"
	desc = "A modkit for making an B-Wal-2572 into a B-Wal-Special."
	product = /obj/item/gun/ballistic/automatic/pistol/enforcer/bwal_special
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, /obj/item/gun/ballistic/automatic/pistol/enforcer, /obj/item/gun/ballistic/automatic/pistol/enforcerred, /obj/item/gun/ballistic/automatic/pistol/enforcergold, /obj/item/gun/ballistic/automatic/pistol/enforcer/bwal2572)

/obj/item/gun/ballistic/automatic/pistol/enforcer/bwal_special
	name = "\improper B-Wal-Special"
	desc = "A unique example of an improved pistol used by the regular Catcrin Army. The personal number AV-000492 is engraved in gold on the barrel. Judging by its appearance, it belongs to someone of high rank."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "bwal_spec"
	fire_sound = 'modular_bluemoon/fluffs/code/modules/catcrin/sounds/weapons/bwalshot.ogg'
	unique_reskin = null
	obj_flags = NONE

/obj/item/modkit/captain_rifle_kit
	name = "Antique Laser Rifle kit"
	desc = "A modkit for making an antique laser gun into a antique laser rifle."
	product = /obj/item/gun/energy/laser/captain/rifle
	fromitem = list(/obj/item/gun/energy/laser/captain)

/obj/item/gun/energy/laser/captain/rifle
	name = "Antique Laser Rifle"
	desc = "A unique, custom-made Captain's Laser. It's made of titanium and gold alloy with a nickel finish. The rifle is engraved with the serial number AV-000492 in gold. The grip is made of hard carbon fiber, treated with a layer of Kevlar. The top layer of the grip is covered in Trixan ebony, which makes it feel even more premium. It feels incredibly expensive."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "captain_rifle"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	item_state = "captain_rifle"
	fire_sound = 'modular_bluemoon/fluffs/code/modules/catcrin/sounds/weapons/Karabiner-M13/LaserOni.ogg'
	unique_reskin = null
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/back.dmi'
	alternate_worn_layer = SUIT_STORE_LAYER

/obj/item/gun/energy/laser/captain/rifle/get_examine_name(mob/user)
	. = ..()
	. += "<span class='chat-tooltip chat-tooltip--warning'>\[?\]<span class='chat-tooltip__content'>["This is captain's antique laser gun. Highrisk item!"]</span></span>"

///////////////////////////////////////////////

/obj/item/modkit/mpl21
	name = "MPL-21 Kit"
	desc = "A modkit for making an Thilium Lascarbine into a Modural Personal Laser."
	icon = 'modular_bluemoon/icons/obj/guns/gunkit.dmi'
	icon_state = "kitsuitcase"
	product = /obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21
	fromitem = list(/obj/item/gun/ballistic/automatic/laser/lasgun)

/obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21
	name = "MPL-21"
	desc = "Modural Personal Laser its a ergonomic direct heating system that uses flat box magazines with pre-charged energy cartridges."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "mpl_21"
	item_state = "mpl_21"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/mpl21_shot.ogg'
	base_pixel_x = -8
	var/const/custom_mag_type = /obj/item/ammo_box/magazine/recharge/lasgun/mpl_21

/obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21/Initialize(mapload)
	. = ..()
	if(replace_mag_to_custom())
		update_icon()

/obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21/get_examine_name(mob/user)
	. = ..()
	. += " <span class='chat-tooltip chat-tooltip--warning'>\[?\]<span class='chat-tooltip__content'>This is [/obj/item/gun/ballistic/automatic/laser/lasgun::name]</span></span>"

/obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21/update_icon_state()
	icon_state = initial(icon_state)
	item_state = initial(item_state)
	if(chambered || magazine)
		item_state += "-mag"
		if(!chambered)
			item_state += "-empty"

/obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21/update_overlays()
	. = ..()
	if(magazine)
		. += "[initial(icon_state)]-mag"
	if(chambered)
		. += "[initial(icon_state)]-charge"

/obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21/insert_mag(obj/item/ammo_box/magazine/AM, mob/user)
	. = ..()
	replace_mag_to_custom()

/obj/item/gun/ballistic/automatic/laser/lasgun/mpl_21/proc/replace_mag_to_custom()
	if(magazine && !(istype(magazine, custom_mag_type)))
		var/obj/item/ammo_box/magazine/oldmag = magazine
		magazine = new custom_mag_type(src)
		QDEL_LIST(magazine.stored_ammo)
		magazine.stored_ammo = oldmag.stored_ammo
		for(var/atom/movable/A in oldmag.stored_ammo)
			A.forceMove(magazine)
		oldmag.stored_ammo = list()
		qdel(oldmag)
		magazine.update_icon()
		return TRUE

/obj/item/ammo_box/magazine/recharge/lasgun/mpl_21
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "mpl_21_mag"

/obj/item/ammo_box/magazine/recharge/lasgun/mpl_21/update_icon_state()
	icon_state = initial(icon_state)
	if(!stored_ammo.len)
		icon_state += "-empty"

///////////////////////////////////////////////

/obj/item/modkit/lcr29
	name = "LCR-29 Kit"
	desc = "A modkit for making an Laser Gun into a Laser Combat Rifle."
	icon = 'modular_bluemoon/icons/obj/guns/gunkit.dmi'
	icon_state = "kitsuitcase"
	product = /obj/item/gun/energy/laser/lcr_29
	fromitem = list(/obj/item/gun/energy/laser)

/obj/item/gun/energy/laser/lcr_29
	name = "LCR-29"
	desc = "Laser Combat Rifle with a non-removable battery and a single lethal mode, which can only be charged from an external source through the charging port."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "lcr_29"
	item_state = null
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	ammo_type = list(/obj/item/ammo_casing/energy/lasergun/lcr_29)
	base_pixel_x = -8
	charge_sections = 2
	shaded_charge = TRUE
	modifystate = FALSE

/obj/item/gun/energy/laser/lcr_29/get_examine_name(mob/user)
	. = ..()
	. += " <span class='chat-tooltip chat-tooltip--warning'>\[?\]<span class='chat-tooltip__content'>This is [/obj/item/gun/energy/laser::name]</span></span>"

/obj/item/ammo_casing/energy/lasergun/lcr_29
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/lcr29_shot.ogg'

///////////////////////////////////////////////

/obj/item/modkit/m3predator
	name = "M-3 Predator Kit"
	desc = "A modkit for making a Hybrid Taser into an M-3 Predator"
	icon = 'modular_bluemoon/icons/obj/guns/gunkit.dmi'
	icon_state = "kitsuitcase"
	product = /obj/item/gun/energy/e_gun/advtaser/m3_predator
	fromitem = list(/obj/item/gun/energy/e_gun/advtaser)

/obj/item/gun/energy/e_gun/advtaser/m3_predator
	name = "M-3 Predator"
	desc = "Reliable, accurate, and easy to handle. The \"Predator\" is marketed by Elanus Risk Control Services as an effective and relatively inexpensive weapon from another galaxy. Although it is rarely purchased by the military due to its limited effectiveness against kinetic barriers."
	icon = 'modular_bluemoon/fluffs/icons/obj/guns.dmi'
	icon_state = "m3_predator"
	item_state = null
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	charge_sections = 2
	shaded_charge = TRUE
	modifystate = FALSE
	ammo_type = list(/obj/item/ammo_casing/energy/disabler/m3_predator, /obj/item/ammo_casing/energy/electrode/security/m3_predator = FALSE)

/obj/item/gun/energy/e_gun/advtaser/m3_predator/get_examine_name(mob/user)
	. = ..()
	. += " <span class='chat-tooltip chat-tooltip--warning'>\[?\]<span class='chat-tooltip__content'>This is [/obj/item/gun/energy/e_gun/advtaser::name]</span></span>"

/obj/item/ammo_casing/energy/disabler/m3_predator
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/m3_predator_disabler.ogg'

/obj/item/ammo_casing/energy/electrode/security/m3_predator
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/m3_predator_taser.ogg'

///////////////////////////////////////////////

/obj/item/gun/ballistic/automatic/pistol/g22/anomalist
	name = "\improper Gelriter-22 M-1"
	desc = "Prototype submachine gun of the Catcrin army. Looks like it just came from the factory, not a single scratch. Despite its dimensions, it is lightweight due to the epoxy body combined with metal elements. Equipped with additional grips and holographic sights. On the right side, the image: a hand reaches from the darkness toward the light."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/back.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_Shot.ogg'
	pickup_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_draw.ogg'
	alternate_worn_layer = SUIT_STORE_LAYER
	icon_state = "SAR-Bolt"
	item_state = "SAR-Bolt"
	load_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_reload.ogg'
	load_empty_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_reload.ogg'
	lock_back_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_Bolt.ogg'
	eject_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_unload.ogg'
	eject_empty_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_unload.ogg'
	unlock_sound = 'modular_bluemoon/fluffs/sound/weapon/SAR_Bolt_unlock.ogg'
	flight_x_offset = 32
	flight_y_offset = 14

/obj/item/gun/ballistic/automatic/pistol/g22/anomalist/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-a"]"

/obj/item/gun/ballistic/automatic/pistol/g22/anomalist/update_overlays()
	. = ..()
	if(magazine)
		. += "SAR-Mag"

/obj/item/gun/ballistic/automatic/pistol/g22/anomalist/get_examine_name(mob/user)
	. = ..()
	. += "<span class='chat-tooltip chat-tooltip--warning'>\[?\]<span class='chat-tooltip__content'>["This is Head of Security G-22 M.1. Highrisk item!"]</span></span>"

/obj/item/modkit/Gelriter_22
	name = "Gelriter-22 kit"
	desc = "A modkit for making an G-22 M.1 into a Gelriter-22 M-1."
	product = /obj/item/gun/ballistic/automatic/pistol/g22/anomalist
	fromitem = list(/obj/item/gun/ballistic/automatic/pistol/g22)

/obj/item/gun/energy/laser/captain/rifle/amogus
	name = "Fancy Laser Rifle"
	desc = "Expensive-looking, custom-made laser. To the touch: expensive polymers, combined with wood, coated in lacquer on the grip."
	icon = 'modular_bluemoon/fluffs/icons/obj/48x32.dmi'
	icon_state = "captain_rifle_s"

/obj/item/gun/energy/laser/captain/rifle/amogus/update_overlays()
	. = ..()
	if(!automatic_charge_overlays)
		return
	var/ratio = get_charge_ratio()
	var/state = "captain_rifle"
	if(ratio == 0)
		state += "_empty"
	else
		state += "_charge[ratio]"
	. += mutable_appearance(icon, state)

/obj/item/modkit/fancy_rifle_kit
	name = "Fancy Laser Rifle kit"
	desc = "A modkit for making an antique laser gun into a fancy laser rifle."
	product = /obj/item/gun/energy/laser/captain/rifle/amogus
	fromitem = list(/obj/item/gun/energy/laser/captain)
