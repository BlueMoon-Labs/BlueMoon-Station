// (MODDING) Bluemoon Pe4henika 08.03.26
// MARK: Bodycamera system
/obj/item/clothing/accessory/bodycamera
	name = "body camera"
	desc = "Camera to be placed on your jumpsuit. It starts working immediately and stops when removed."
	icon = 'modular_splurt/icons/obj/clothing/bodycam.dmi'
	icon_state = "bodycamera"
	var/obj/machinery/camera/builtInCamera = null

/obj/item/clothing/accessory/bodycamera/Destroy()
	QDEL_NULL(builtInCamera)
	return ..()

/obj/item/clothing/accessory/bodycamera/attach(obj/item/clothing/under/U, user)
	. = ..()
	if(!builtInCamera)
		builtInCamera = new(src)
		builtInCamera.network = list("ss13")
		builtInCamera.internal_light = FALSE
		builtInCamera.use_power = NO_POWER_USE
		builtInCamera.view_range = 3
		builtInCamera.icon = null
		builtInCamera.invisibility = INVISIBILITY_ABSTRACT
		builtInCamera.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	var/mob/living/carbon/human/H = user
	if(istype(H))
		var/obj/item/card/id/id_card = H.wear_id?.GetID() || H.wear_neck?.GetID()
		var/cam_name = (istype(id_card) && id_card.registered_name) ? id_card.registered_name : "Unknown"
		builtInCamera.c_tag = "Body Camera: [cam_name]"

		RegisterSignal(H, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
		builtInCamera.forceMove(H.loc)
		GLOB.cameranet.updateChunk(builtInCamera.x, builtInCamera.y, builtInCamera.z)
	return .

/obj/item/clothing/accessory/bodycamera/detach(obj/item/clothing/under/U, user)
	if(user)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	if(builtInCamera)
		builtInCamera.toggle_cam(null, FALSE)
		QDEL_NULL(builtInCamera)
	return ..()

/obj/item/clothing/accessory/bodycamera/proc/on_owner_moved(mob/living/source)
	SIGNAL_HANDLER
	if(!builtInCamera || !source?.loc)
		return
	var/old_x = builtInCamera.x
	var/old_y = builtInCamera.y
	var/old_z = builtInCamera.z
	builtInCamera.forceMove(source.loc)
	if(old_x != builtInCamera.x || old_y != builtInCamera.y || old_z != builtInCamera.z)
		if(old_z)
			GLOB.cameranet.updateChunk(old_x, old_y, old_z)
		GLOB.cameranet.updateChunk(builtInCamera.x, builtInCamera.y, builtInCamera.z)
