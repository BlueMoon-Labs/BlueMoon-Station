/// Compatibility paths for old maps/boards. This is an ordinary information
/// server; APC service discovery never depends on its presence or power.
/obj/machinery/netrun_server/dns
	name = "information server"
	desc = "Информационный сервер станции. Обнаружение служб встроено в сеть APC."
	circuit = /obj/item/circuitboard/machine/netrun_dns
	server_security = 3

/obj/item/circuitboard/machine/netrun_dns
	name = "Information Server (Machine Board)"
	icon_state = "science"
	build_path = /obj/machinery/netrun_server/dns
	req_components = list(
		/obj/item/stack/cable_coil = 2,
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/subspace/filter = 1)
