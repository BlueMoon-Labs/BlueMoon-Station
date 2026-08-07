// These are used in uplink_devices.dm to determine whether or not an item is purchasable.

/// This item is purchasable to traitors
#define UPLINK_TRAITORS (1 << 0)

/// This item is purchasable to nuke ops
#define UPLINK_NUKE_OPS (1 << 1)

/// This item is purchasable to clown ops
#define UPLINK_CLOWN_OPS (1 << 2)

/// Bluemoon added. This item is purchasable to syndicate dudes
#define UPLINK_SYNDICATE (1 << 3)

// Bluemoon added. Дефайт для аплинка синдистанции. В нём только разрешенная по НРП зелёная КБшка, плюс пару не контрабандных плюшек.
#define UPLINK_SYNDICATE_PACT_CREW (1 << 4)
