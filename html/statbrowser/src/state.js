var State = {
	currentTab: null,
	verbTabs: [],
	verbs: [],
	permanentTabs: [],
	spellTabs: [],
	spells: [],
	splitAdminTabs: false,
	hrefToken: null,
	// Bridge protocol — null until DM's set_protocol_version handshake arrives
	protocolVersion: null,
	protocolMismatchReported: false,
	// Status tab
	globalFast: null,
	globalSlow: null,
	pingData: null,
	tidiData: null,
	mobItems: [],
	voteParts: [[null]],
	// MC tab
	mcServerData: {},
	mcSSData: [],
	mcIteration: -1,
	mcSortCol: SS_COST,
	mcSortAsc: false,
	mcFilterText: "",
	mcSections: { server: true, ping: false, key: true, subsystems: true },
	// Tickets
	tickets: [],
	interviewManager: { status: "", interviews: [] },
	// SDQL2
	sdql2: [],
	// Turf
	turfName: "",
	turfContents: [],
	turfContentsRaw: "",
	// Favorites
	favorites: {},
	// Images
	storedImages: {},
	imageRetryDelay: 500,
	imageRetryLimit: 10
};
