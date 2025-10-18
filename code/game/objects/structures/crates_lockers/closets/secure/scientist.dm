/obj/structure/closet/secure_closet/RD
	name = "\proper research director's locker"
	req_access = list(ACCESS_RD)
	icon_state = "rd"

/obj/structure/closet/secure_closet/RD/PopulateContents()
	..()

	new /obj/item/cartridge/rd(src)
	new /obj/item/radio/headset/heads/rd(src)
	new /obj/item/tank/internals/air(src)
	new /obj/item/megaphone/command(src)
	new /obj/item/storage/lockbox/medal/sci(src)
	new /obj/item/clothing/suit/armor/reactive/teleport(src)
	new /obj/item/toy/eightball/science(src) //BLUEMOON REMOVE - /obj/item/assembly/flash/handheld
	new /obj/item/laser_pointer(src)
	new /obj/item/door_remote/research_director(src)
	new /obj/item/circuitboard/machine/techfab/department/science(src)
	new /obj/item/storage/photo_album/RD(src)
	new /obj/item/analyzer/hilbertsanalyzer(src)
	new /obj/item/mod/construction/armor/research(src)
	new /obj/item/mod/construction/armor/research(src)
	new /obj/item/storage/garment_case/RD(src)
	new /obj/item/small_delivery/silo_multitool(src) //BLUEMOON ADD
