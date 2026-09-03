/datum/keybinding/ai
	category = CATEGORY_ROBOT
	weight = WEIGHT_ROBOT

/datum/keybinding/ai/can_use(client/user)
	return isAI(user.mob)

/datum/keybinding/ai/restore_camera_1
	hotkey_keys = list("1")
	name = "ai_restore_camera_1"
	full_name = "AI Camera Recall 1"
	description = "Returns the AI eye to saved slot 1."

/datum/keybinding/ai/restore_camera_1/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(1)

/datum/keybinding/ai/restore_camera_2
	hotkey_keys = list("2")
	name = "ai_restore_camera_2"
	full_name = "AI Camera Recall 2"
	description = "Returns the AI eye to saved slot 2."

/datum/keybinding/ai/restore_camera_2/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(2)

/datum/keybinding/ai/restore_camera_3
	hotkey_keys = list("3")
	name = "ai_restore_camera_3"
	full_name = "AI Camera Recall 3"
	description = "Returns the AI eye to saved slot 3."

/datum/keybinding/ai/restore_camera_3/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(3)

/datum/keybinding/ai/restore_camera_4
	hotkey_keys = list("4")
	name = "ai_restore_camera_4"
	full_name = "AI Camera Recall 4"
	description = "Returns the AI eye to saved slot 4."

/datum/keybinding/ai/restore_camera_4/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(4)

/datum/keybinding/ai/restore_camera_5
	hotkey_keys = list("5")
	name = "ai_restore_camera_5"
	full_name = "AI Camera Recall 5"
	description = "Returns the AI eye to saved slot 5."

/datum/keybinding/ai/restore_camera_5/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(5)

/datum/keybinding/ai/restore_camera_6
	hotkey_keys = list("6")
	name = "ai_restore_camera_6"
	full_name = "AI Camera Recall 6"
	description = "Returns the AI eye to saved slot 6."

/datum/keybinding/ai/restore_camera_6/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(6)

/datum/keybinding/ai/restore_camera_7
	hotkey_keys = list("7")
	name = "ai_restore_camera_7"
	full_name = "AI Camera Recall 7"
	description = "Returns the AI eye to saved slot 7."

/datum/keybinding/ai/restore_camera_7/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(7)

/datum/keybinding/ai/restore_camera_8
	hotkey_keys = list("8")
	name = "ai_restore_camera_8"
	full_name = "AI Camera Recall 8"
	description = "Returns the AI eye to saved slot 8."

/datum/keybinding/ai/restore_camera_8/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(8)

/datum/keybinding/ai/restore_camera_9
	hotkey_keys = list("9")
	name = "ai_restore_camera_9"
	full_name = "AI Camera Recall 9"
	description = "Returns the AI eye to saved slot 9."

/datum/keybinding/ai/restore_camera_9/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.restore_camera_position(9)

/datum/keybinding/ai/save_camera_1
	hotkey_keys = list("Ctrl1")
	name = "ai_save_camera_1"
	full_name = "AI Camera Save 1"
	description = "Saves the AI eye position to slot 1."

/datum/keybinding/ai/save_camera_1/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(1)

/datum/keybinding/ai/save_camera_2
	hotkey_keys = list("Ctrl2")
	name = "ai_save_camera_2"
	full_name = "AI Camera Save 2"
	description = "Saves the AI eye position to slot 2."

/datum/keybinding/ai/save_camera_2/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(2)

/datum/keybinding/ai/save_camera_3
	hotkey_keys = list("Ctrl3")
	name = "ai_save_camera_3"
	full_name = "AI Camera Save 3"
	description = "Saves the AI eye position to slot 3."

/datum/keybinding/ai/save_camera_3/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(3)

/datum/keybinding/ai/save_camera_4
	hotkey_keys = list("Ctrl4")
	name = "ai_save_camera_4"
	full_name = "AI Camera Save 4"
	description = "Saves the AI eye position to slot 4."

/datum/keybinding/ai/save_camera_4/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(4)

/datum/keybinding/ai/save_camera_5
	hotkey_keys = list("Ctrl5")
	name = "ai_save_camera_5"
	full_name = "AI Camera Save 5"
	description = "Saves the AI eye position to slot 5."

/datum/keybinding/ai/save_camera_5/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(5)

/datum/keybinding/ai/save_camera_6
	hotkey_keys = list("Ctrl6")
	name = "ai_save_camera_6"
	full_name = "AI Camera Save 6"
	description = "Saves the AI eye position to slot 6."

/datum/keybinding/ai/save_camera_6/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(6)

/datum/keybinding/ai/save_camera_7
	hotkey_keys = list("Ctrl7")
	name = "ai_save_camera_7"
	full_name = "AI Camera Save 7"
	description = "Saves the AI eye position to slot 7."

/datum/keybinding/ai/save_camera_7/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(7)

/datum/keybinding/ai/save_camera_8
	hotkey_keys = list("Ctrl8")
	name = "ai_save_camera_8"
	full_name = "AI Camera Save 8"
	description = "Saves the AI eye position to slot 8."

/datum/keybinding/ai/save_camera_8/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(8)

/datum/keybinding/ai/save_camera_9
	hotkey_keys = list("Ctrl9")
	name = "ai_save_camera_9"
	full_name = "AI Camera Save 9"
	description = "Saves the AI eye position to slot 9."

/datum/keybinding/ai/save_camera_9/down(client/user)
	var/mob/living/silicon/ai/AI = user.mob
	return AI.save_camera_position(9)
