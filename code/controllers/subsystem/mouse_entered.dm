/// Откладывает обработку MouseEntered до конца тика и схлопывает её до
/// последнего наведённого атома на клиента (порт tg). Быстрое ведение мыши
/// через десяток атомов раньше запускало скринтип-пайплайн на каждом из них
/// в момент ввода; теперь за тик исполняется максимум один на клиента.
SUBSYSTEM_DEF(mouse_entered)
	name = "MouseEntered"
	wait = 1
	flags = SS_NO_INIT | SS_TICKER
	priority = FIRE_PRIORITY_MOUSE_ENTERED
	runlevels = RUNLEVELS_DEFAULT | RUNLEVEL_LOBBY

	///assoc: client -> the last atom they hovered over this tick
	var/list/hovers = list()

/datum/controller/subsystem/mouse_entered/fire()
	for(var/hovering_client in hovers)
		if(!istype(hovering_client, /client)) // disconnected: drop the stale key so it cannot pin the client ref
			hovers -= hovering_client
			continue
		var/atom/hovering_atom = hovers[hovering_client]
		if(isnull(hovering_atom))
			continue
		if(QDELETED(hovering_atom)) //атом удалён между вводом и fire: обработчик подписался бы на уже прошедший QDELETING
			hovers[hovering_client] = null
			continue
		hovering_atom.on_mouse_enter(hovering_client)
		// Intentionally `= null` and not `-= hovering_client`: no list shrink
		// in a hot path, the key set stays stable per connected client.
		hovers[hovering_client] = null
