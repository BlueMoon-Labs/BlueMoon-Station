/obj/item/cartridge
	name = "generic cartridge"
	desc = "Картридж с данными для портативных микрокомпьютеров."
	icon = 'icons/obj/pda.dmi'
	icon_state = "cart"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	rad_flags = RAD_PROTECT_CONTENTS

	var/obj/item/integrated_signaler/radio = null
	var/access = 0

/obj/item/cartridge/civil
	name = "\improper Civil cartridge"
	icon_state = "cart"
	access = CART_MANIFEST

/obj/item/cartridge/engineering
	name = "\improper Power-ON cartridge"
	icon_state = "cart-e"
	access = CART_ENGINE | CART_DRONEPHONE | CART_MANIFEST

/obj/item/cartridge/atmos
	name = "\improper BreatheDeep cartridge"
	icon_state = "cart-a"
	access = CART_ATMOS | CART_DRONEPHONE | CART_MANIFEST

/obj/item/cartridge/medical
	name = "\improper Med-U cartridge"
	icon_state = "cart-m"
	access = CART_MEDICAL | CART_MANIFEST

/obj/item/cartridge/security
	name = "\improper R.O.B.U.S.T. cartridge"
	icon_state = "cart-s"
	access = CART_SECURITY | CART_MANIFEST

/obj/item/cartridge/detective
	name = "\improper D.E.T.E.C.T. cartridge"
	icon_state = "cart-eye"
	access = CART_SECURITY | CART_MEDICAL | CART_MANIFEST

/obj/item/cartridge/janitor
	name = "\improper CustodiPRO cartridge"
	desc = "Ультимативен в решениях очисток помещений."
	icon_state = "cart-j"
	access = CART_JANITOR | CART_DRONEPHONE | CART_MANIFEST

/obj/item/cartridge/lawyer
	name = "\improper S.P.A.M. cartridge"
	desc = "Представляем вам картридж программы Station Public Announcement Messenger, с уникальной функцией вещания сообщениями, спроектировано для агентов внутренних дел Nanotrasen для рекламы их нужных и важных услуг."
	icon_state = "cart-law"
	access = CART_MANIFEST

/obj/item/cartridge/curator
	name = "\improper Lib-Tweet cartridge"
	icon_state = "cart-lib"
	access = CART_NEWSCASTER | CART_MANIFEST

/obj/item/cartridge/roboticist
	name = "\improper B.O.O.P. Remote Control cartridge"
	desc = "Снабжен тяжеловесным интерлинком связи с ботами и дронами!"
	icon_state = "cart-robo"
	access = CART_DRONEPHONE | CART_MANIFEST

/obj/item/cartridge/signal
	name = "generic signaler cartridge"
	icon_state = "cart-sig"
	desc = "Дата-картридж со встроенным радиосигналером."
	access = CART_SIGNALER

/obj/item/cartridge/signal/toxins
	name = "\improper Signal Ace 2 cartridge"
	desc = "Полноценен со встроенным радиосигналером!"
	icon_state = "cart-tox"
	access = CART_ATMOS | CART_MANIFEST | CART_SIGNALER

/obj/item/cartridge/signal/Initialize(mapload)
	. = ..()
	radio = new(src)

/obj/item/cartridge/quartermaster
	name = "space parts & space vendors cartridge"
	desc = "Идеален для квартирмейстера тут и там!"
	icon_state = "cart-q"
	access = CART_QUARTERMASTER | CART_MANIFEST

/obj/item/cartridge/head
	name = "\improper Easy-Record DELUXE cartridge"
	icon_state = "cart-h"
	access = CART_MANIFEST | CART_STATUS_DISPLAY

/obj/item/cartridge/hop
	name = "\improper HumanResources9001 cartridge"
	icon_state = "cart-h"
	access = CART_MANIFEST | CART_STATUS_DISPLAY | CART_JANITOR | CART_SECURITY | CART_NEWSCASTER | CART_QUARTERMASTER | CART_DRONEPHONE

/obj/item/cartridge/hos
	name = "\improper R.O.B.U.S.T. DELUXE cartridge"
	icon_state = "cart-hos"
	access = CART_MANIFEST | CART_STATUS_DISPLAY | CART_SECURITY

/obj/item/cartridge/ce
	name = "\improper Power-On DELUXE cartridge"
	icon_state = "cart-ce"
	access = CART_MANIFEST | CART_STATUS_DISPLAY | CART_ENGINE | CART_ATMOS | CART_DRONEPHONE

/obj/item/cartridge/cmo
	name = "\improper Med-U DELUXE cartridge"
	icon_state = "cart-cmo"
	access = CART_MANIFEST | CART_STATUS_DISPLAY | CART_MEDICAL

/obj/item/cartridge/rd
	name = "\improper Signal Ace DELUXE cartridge"
	icon_state = "cart-rd"
	access = CART_MANIFEST | CART_STATUS_DISPLAY | CART_ATMOS | CART_DRONEPHONE | CART_SIGNALER

/obj/item/cartridge/rd/Initialize(mapload)
	. = ..()
	radio = new(src)

/obj/item/cartridge/captain
	name = "\improper Value-PAK cartridge"
	desc = "Теперь полезнее на 350%!"
	icon_state = "cart-c"
	access = CART_MANIFEST | CART_ENGINE | CART_ATMOS | CART_MEDICAL | CART_SECURITY | CART_JANITOR | CART_NEWSCASTER | CART_REMOTE_DOOR | CART_STATUS_DISPLAY | CART_QUARTERMASTER | CART_HYDROPONICS | CART_DRONEPHONE | CART_SIGNALER

/obj/item/cartridge/captain/Initialize(mapload)
	. = ..()
	radio = new(src)

/obj/item/cartridge/chaplain
	name = "holy cartridge"
	desc = "Аминь!"
	icon_state = "cart-q"
	access = CART_MANIFEST

/obj/item/cartridge/proc/post_status(command, data1, data2)
	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)
	if(!frequency)
		return
	var/datum/signal/status_signal = new(list("command" = command))
	switch(command)
		if("message")
			status_signal.data["msg1"] = data1
			status_signal.data["msg2"] = data2
		if("alert")
			status_signal.data["picture_state"] = data1
	frequency.post_signal(src, status_signal)

/// Returns list of program typepaths granted by this cartridge's access flags.
/obj/item/cartridge/proc/get_programs()
	var/list/programs = list()
	if(access & CART_MANIFEST)
		programs += /datum/computer_file/program/crew_manifest
	if(access & CART_ENGINE)
		programs += /datum/computer_file/program/power_monitor
		programs += /datum/computer_file/program/supermatter_monitor
	if(access & CART_ATMOS)
		programs += /datum/computer_file/program/atmosscan
	if(access & CART_MEDICAL)
		programs += /datum/computer_file/program/radar/lifeline
	if(access & CART_SECURITY)
		programs += /datum/computer_file/program/secureye
	if(access & CART_QUARTERMASTER)
		programs += /datum/computer_file/program/budgetorders
		programs += /datum/computer_file/program/shipping
	if(access & CART_NEWSCASTER)
		programs += /datum/computer_file/program/chatclient
	if(access & CART_DRONEPHONE)
		programs += /datum/computer_file/program/robocontrol
	if(access & CART_SIGNALER)
		programs += /datum/computer_file/program/signaler
	if(access & CART_STATUS_DISPLAY)
		programs += /datum/computer_file/program/statusdisplay
	if(access & CART_REMOTE_DOOR)
		programs += /datum/computer_file/program/remotedoor
	if(access & CART_JANITOR)
		programs += /datum/computer_file/program/custodiallocator
	if(access & CART_HYDROPONICS)
		programs += /datum/computer_file/program/hydroponics
	return programs

// ---- Virus cartridges ----

/obj/item/cartridge/virus
	name = "\improper generic virus cartridge"
	desc = "Картридж, содержащий вредоносное ПО для КПК."
	/// How many charges the virus has left
	var/charges = 5

/obj/item/cartridge/virus/proc/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	if(charges <= 0)
		to_chat(user, span_notice("ERROR: Out of charges."))
		return FALSE
	if(!target)
		to_chat(user, span_notice("ERROR: Could not find device."))
		return FALSE
	return TRUE

/obj/item/cartridge/virus/clown
	name = "\improper H.O.N.K. cartridge"

/obj/item/cartridge/virus/clown/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE
	user.show_message(span_notice("Success!"))
	charges--
	target.honkvirus_amount = rand(15, 25)
	return TRUE

/obj/item/cartridge/virus/mime
	name = "\improper sound of silence cartridge"

/obj/item/cartridge/virus/mime/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE
	var/datum/computer_file/program/messenger/app = locate() in target.get_all_files()
	if(!app)
		to_chat(user, span_notice("ERROR: Target does not have messenger installed."))
		return FALSE
	user.show_message(span_notice("Success!"))
	charges--
	app.alert_silenced = TRUE
	app.ringtone = ""

/obj/item/cartridge/virus/detomatix
	name = "\improper D.E.T.O.M.A.T.I.X. cartridge"
	charges = 6

/obj/item/cartridge/virus/detomatix/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE

	var/difficulty = target.get_detomatix_difficulty()
	if(SEND_SIGNAL(target, COMSIG_TABLET_CHECK_DETONATE) & COMPONENT_TABLET_NO_DETONATE || prob(difficulty * 15))
		user.show_message(span_danger("ERROR: Target could not be bombed."), MSG_VISUAL)
		charges--
		return

	var/original_host = source
	var/fakename = sanitize_name(tgui_input_text(user, "Enter a name for the rigged message.", "Forge Message", max_length = MAX_NAME_LEN))
	if(!fakename || source != original_host || !user.canUseTopic(source, BE_CLOSE))
		return
	var/fakejob = sanitize_name(tgui_input_text(user, "Enter a job for the rigged message.", "Forge Message", max_length = MAX_NAME_LEN))
	if(!fakejob || source != original_host || !user.canUseTopic(source, BE_CLOSE))
		return

	var/datum/computer_file/program/messenger/app = locate() in source.get_all_files()
	var/datum/computer_file/program/messenger/target_app = locate() in target.get_all_files()
	if(!app || charges <= 0 || !app.send_rigged_message(user, message, list(target_app), fakename, fakejob))
		return FALSE
	charges--
	user.show_message(span_notice("Success!"))
	var/reference = REF(src)
	ADD_TRAIT(target, TRAIT_PDA_CAN_EXPLODE, reference)
	ADD_TRAIT(target, TRAIT_PDA_MESSAGE_MENU_RIGGED, reference)
	addtimer(TRAIT_CALLBACK_REMOVE(target, TRAIT_PDA_MESSAGE_MENU_RIGGED, reference), 10 SECONDS)
	addtimer(TRAIT_CALLBACK_REMOVE(target, TRAIT_PDA_CAN_EXPLODE, reference), 1 MINUTES)
	return TRUE

/obj/item/cartridge/virus/frame
	name = "\improper F.R.A.M.E. cartridge"
	/// How many telecrystals the uplink should have
	var/telecrystals = 0
	/// How much progression should be shown in the uplink, set on purchase.
	var/current_progression = 0

/obj/item/cartridge/virus/frame/attackby(obj/item/attacking_item, mob/user, params)
	. = ..()
	if(!istype(attacking_item, /obj/item/stack/telecrystal))
		return
	if(!charges)
		to_chat(user, span_notice("[src] is out of charges, it's refusing to accept [attacking_item]."))
		return
	var/obj/item/stack/telecrystal/telecrystal_stack = attacking_item
	telecrystals += telecrystal_stack.amount
	to_chat(user, span_notice("You slot [telecrystal_stack] into [src]. The next time it's used, it will also give telecrystals."))
	telecrystal_stack.use(telecrystal_stack.amount)

/obj/item/cartridge/virus/frame/send_virus(obj/item/modular_computer/pda/source, obj/item/modular_computer/pda/target, mob/living/user, message)
	. = ..()
	if(!.)
		return FALSE

	charges--
	var/unlock_code = "[rand(100,999)] [pick(GLOB.phonetic_alphabet)]"
	to_chat(user, span_notice("Success! The unlock code to the target is: [unlock_code]"))
	var/datum/component/uplink/hidden_uplink = target.GetComponent(/datum/component/uplink)
	if(!hidden_uplink)
		var/datum/mind/target_mind
		var/list/backup_players = list()
		for(var/datum/mind/player as anything in SSticker.minds)
			if(player.assigned_role == target.saved_job)
				backup_players += player
			if(player.name == target.saved_identification)
				target_mind = player
				break
		if(!target_mind)
			if(!length(backup_players))
				target_mind = user.mind
			else
				target_mind = pick(backup_players)
		hidden_uplink = target.AddComponent(/datum/component/uplink, target_mind?.key, _enabled = TRUE, starting_tc = telecrystals)
		hidden_uplink.unlock_code = unlock_code
	else
		hidden_uplink.telecrystals += telecrystals
	telecrystals = 0
	hidden_uplink.locked = FALSE
	hidden_uplink.active = TRUE

/obj/item/cartridge/hotelstaff
	name = "\improper Twin Nexus cartridge"
	desc = "The customer is always right! Except for when they're not."
	icon_state = "cart-bar"
	access = CART_MANIFEST

/obj/item/cartridge/cmo/Initialize(mapload)
	. = ..()
