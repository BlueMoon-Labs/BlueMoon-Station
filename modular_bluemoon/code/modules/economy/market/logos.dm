/// Логотипы компаний биржи (по тикеру) и торговых партнёров (по id) для окон снабжения и биржи.
/datum/asset/spritesheet/simple/economy_logos
	name = "economy_logos"
	assets = list(
		"logo-ntrn" = 'tgui/packages/tgui/assets/economy/ntrn.png',
		"logo-prsp" = 'tgui/packages/tgui/assets/economy/prsp.png',
		"logo-vymd" = 'tgui/packages/tgui/assets/economy/vymd.png',
		"logo-nkmr" = 'tgui/packages/tgui/assets/economy/nkmr.png',
		"logo-agro" = 'tgui/packages/tgui/assets/economy/agro.png',
		"logo-solx" = 'tgui/packages/tgui/assets/economy/solx.png',
		"logo-cybs" = 'tgui/packages/tgui/assets/economy/cybs.png',
		"logo-eins" = 'tgui/packages/tgui/assets/economy/eins.png',
		"logo-nt_logistics" = 'tgui/packages/tgui/assets/economy/ntrn.png',
		"logo-prospectors" = 'tgui/packages/tgui/assets/economy/prsp.png',
		"logo-vey_med" = 'tgui/packages/tgui/assets/economy/vymd.png',
		"logo-nakamura" = 'tgui/packages/tgui/assets/economy/nkmr.png',
		"logo-agrarian" = 'tgui/packages/tgui/assets/economy/agro.png',
		"logo-sol_federation" = 'tgui/packages/tgui/assets/economy/sol_federation.png',
		"logo-free_traders" = 'tgui/packages/tgui/assets/economy/free_traders.png',
	)

/obj/machinery/computer/cargo/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/simple/economy_logos))

/obj/machinery/computer/stock_terminal/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/simple/economy_logos))

/datum/computer_file/program/cargo_orders/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/simple/economy_logos))

/datum/computer_file/program/stock_exchange/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet/simple/economy_logos))
