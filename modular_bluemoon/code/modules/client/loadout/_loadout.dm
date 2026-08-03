// Эффекты при спавне, например прописи владельца
/datum/gear/proc/on_spawn(mob/user, obj/item/I)
	return

// Владельца держим слабой ссылкой: предмет живёт дольше тела (шкафчик, чужой
// рюкзак, пол станции), и жёсткая ссылка не давала телу собраться весь раунд.
/datum/gear/neck/syntech/pendant/on_spawn(mob/user, obj/item/clothing/neck/syntech/I)
	I.owner_ref = WEAKREF(user)

/datum/gear/neck/syntech/choker/on_spawn(mob/user, obj/item/clothing/neck/syntech/choker/I)
	I.owner_ref = WEAKREF(user)

/datum/gear/neck/syntech/collar/on_spawn(mob/user, obj/item/clothing/neck/syntech/collar/I)
	I.owner_ref = WEAKREF(user)

/datum/gear/gloves/syntech/ring/on_spawn(mob/user, obj/item/clothing/accessory/ring/syntech/I)
	I.owner_ref = WEAKREF(user)

/datum/gear/wrists/syntech/band/on_spawn(mob/user, obj/item/clothing/wrists/syntech/I)
	I.owner_ref = WEAKREF(user)
