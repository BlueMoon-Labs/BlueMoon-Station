// (MODDING) Bluemoon Pe4henika 08.03.26
// MARK: Bodycamera system
/obj/item/clothing/accessory/bodycamera
	name = "body camera"
	desc = "Camera to be placed on your jumpsuit. It starts working immediately and stops when removed."
	icon = 'modular_splurt/icons/obj/clothing/bodycam.dmi'
	icon_state = "bodycamera"
	var/obj/machinery/camera/builtInCamera = null
	var/mob/living/wearer = null

/obj/item/clothing/accessory/bodycamera/Destroy()
	unregister_wearer()
	QDEL_NULL(builtInCamera)
	return ..()

/obj/item/clothing/accessory/bodycamera/attach(obj/item/clothing/under/U, user)
	. = ..()
	if(!.)
		return .
	if(!builtInCamera)
		builtInCamera = new(src)
		builtInCamera.network = list("ss13")
		builtInCamera.internal_light = FALSE
		builtInCamera.use_power = NO_POWER_USE
		builtInCamera.view_range = 3
		builtInCamera.icon = null
		builtInCamera.invisibility = INVISIBILITY_ABSTRACT
		builtInCamera.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	update_camera_name(user)
	register_wearer(U.loc)
	GLOB.cameranet.updatePortableCamera(builtInCamera)
	return .

/obj/item/clothing/accessory/bodycamera/detach(obj/item/clothing/under/U, user)
	unregister_wearer()
	if(builtInCamera)
		QDEL_NULL(builtInCamera)
	return ..()

/obj/item/clothing/accessory/bodycamera/on_uniform_equip(obj/item/clothing/under/U, user)
	. = ..()
	update_camera_name(user)
	register_wearer(user)
	if(builtInCamera)
		GLOB.cameranet.updatePortableCamera(builtInCamera)

/obj/item/clothing/accessory/bodycamera/on_uniform_dropped(obj/item/clothing/under/U, user)
	. = ..()
	unregister_wearer()
	if(builtInCamera)
		GLOB.cameranet.updatePortableCamera(builtInCamera)

/obj/item/clothing/accessory/bodycamera/proc/update_camera_name(mob/living/user)
	if(!builtInCamera)
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/card/id/id_card = H?.wear_id?.GetID() || H?.wear_neck?.GetID()
	var/cam_name = (istype(id_card) && id_card.registered_name) ? id_card.registered_name : "Unknown"
	builtInCamera.c_tag = "Body Camera: [cam_name]"

/obj/item/clothing/accessory/bodycamera/proc/register_wearer(mob/living/new_wearer)
	if(wearer == new_wearer)
		return
	unregister_wearer()
	if(!istype(new_wearer))
		return
	wearer = new_wearer
	RegisterSignal(wearer, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))

/obj/item/clothing/accessory/bodycamera/proc/unregister_wearer()
	if(!wearer)
		return
	UnregisterSignal(wearer, COMSIG_MOVABLE_MOVED)
	wearer = null

/obj/item/clothing/accessory/bodycamera/proc/on_owner_moved(mob/living/source, atom/oldLoc)
	SIGNAL_HANDLER
	if(!builtInCamera || !source?.loc)
		return
	var/turf/old_turf = get_turf(oldLoc)
	var/turf/new_turf = get_turf(source)
	if(old_turf == new_turf)
		return
	if(old_turf)
		GLOB.cameranet.updateChunk(old_turf.x, old_turf.y, old_turf.z)
	GLOB.cameranet.updatePortableCamera(builtInCamera)
	if(new_turf)
		GLOB.cameranet.updateChunk(new_turf.x, new_turf.y, new_turf.z)
