var State = {
	currentTab: null,
	verbTabs: [],
	verbs: [],
	permanentTabs: [],
	spellTabs: [],
	spells: [],
	splitAdminTabs: false,
	hrefToken: null,
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
	mcSortCol: SS_COST,
	mcSortAsc: false,
	mcSortDirty: true,
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
	cachedImages: [],
	imageRetryDelay: 500,
	imageRetryLimit: 50
};
