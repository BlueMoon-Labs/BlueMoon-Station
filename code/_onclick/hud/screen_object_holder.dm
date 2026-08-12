/// A helper instance that will handle adding objects from the client's screen
/// to easily remove from later.
/datum/screen_object_holder
	VAR_PRIVATE
		client/client
		list/screen_objects = list()
		list/protected_screen_objects = list()

/datum/screen_object_holder/New(client/client)
	ASSERT(istype(client))

	src.client = client

	RegisterSignal(client, COMSIG_PARENT_QDELETING, PROC_REF(on_parent_qdel))

/datum/screen_object_holder/Destroy()
	if(client)
		UnregisterSignal(client, COMSIG_PARENT_QDELETING)
	clear()
	client = null

	return ..()

/// Gives the screen object to the client, qdel'ing it when it's cleared
/datum/screen_object_holder/proc/give_screen_object(atom/screen_object)
	ASSERT(istype(screen_object))

	screen_objects += screen_object
	stamp_owner(screen_object)
	client?.screen += screen_object

/// Gives the screen object to the client, but does not qdel it when it's cleared
/datum/screen_object_holder/proc/give_protected_screen_object(atom/screen_object)
	ASSERT(istype(screen_object))

	protected_screen_objects += screen_object
	client?.screen += screen_object

/// Объекты меню живут без hud, поэтому снять себя с экрана они могут только по прямой
/// ссылке на владельца - проставляем её здесь, а не в каждом конструкторе страницы.
/// Штампуем только те объекты, которые держатель сам и удаляет: protected - это GLOB-синглтоны
/// (заголовок и подпись меню), их Destroy() возвращает QDEL_HINT_LETMELIVE не доходя до
/// родителя, поле в них никто не прочитает, а держать в общем синглтоне ссылку на конкретного
/// клиента незачем.
/datum/screen_object_holder/proc/stamp_owner(atom/screen_object)
	PRIVATE_PROC(TRUE)

	var/atom/movable/screen/escape_menu/menu_object = screen_object
	if(istype(menu_object))
		menu_object.owner_client = client

/datum/screen_object_holder/proc/remove_screen_object(atom/screen_object)
	ASSERT(istype(screen_object))
	ASSERT((screen_object in screen_objects) || (screen_object in protected_screen_objects))

	screen_objects -= screen_object
	protected_screen_objects -= screen_object
	client?.screen -= screen_object

/datum/screen_object_holder/proc/clear()
	for(var/atom/movable/screen/S in screen_objects)
		S.screen_loc = null
	// Protected objects are singletons managed externally - don't null their screen_loc
	// or they'll be invisible next time they're shown (screen_loc won't auto-restore)

	client?.screen -= screen_objects
	client?.screen -= protected_screen_objects

	QDEL_LIST(screen_objects)
	protected_screen_objects.Cut()

// We don't qdel here, as clients leaving should not be a concern for consumers
// Consumers ought to be qdel'ing this on their own Destroy, but we shouldn't
// hard del because they aren't watching for the client, that's our job.
/datum/screen_object_holder/proc/on_parent_qdel()
	PRIVATE_PROC(TRUE)
	SIGNAL_HANDLER

	clear()
	client = null
