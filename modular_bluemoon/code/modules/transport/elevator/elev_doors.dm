GLOBAL_LIST_EMPTY(elevator_doors)

/obj/machinery/door/window/elevator
	name = "elevator door"
	desc = "Не даёт таким идиотам, как вы, шагнуть в открытую шахту лифта."
	icon_state = "left"
	base_state = "left"
	CanAtmosPass = ATMOS_PASS_DENSITY // elevator shaft is airtight when closed
	req_access = list(ACCESS_TCOMSAT)

/obj/machinery/door/window/elevator/left

/obj/machinery/door/window/elevator/right
	icon_state = "right"
	base_state = "right"

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/door/window/elevator/left, 0)
MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/door/window/elevator/right, 0)
