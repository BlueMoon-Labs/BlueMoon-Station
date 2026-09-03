// Various modular computer signals.

/// From /obj/item/modular_computer/proc/turn_on: (user)
#define COMSIG_MODULAR_COMPUTER_TURNED_ON "comsig_modular_computer_turned_on"
/// From /obj/item/modular_computer/proc/shutdown_computer: (loud)
#define COMSIG_MODULAR_COMPUTER_SHUT_DOWN "comsig_modular_computer_shut_down"

/// From /obj/item/modular_computer/proc/store_file: (datum/computer_file/file_storing)
#define COMSIG_MODULAR_COMPUTER_FILE_STORE "comsig_modular_computer_file_store"
/// From /obj/item/modular_computer/proc/remove_file: (datum/computer_file/file_removing)
#define COMSIG_MODULAR_COMPUTER_FILE_DELETE "comsig_modular_computer_file_delete"
/// From /obj/item/modular_computer/proc/store_file, sent to the file itself: (obj/item/modular_computer/host)
#define COMSIG_COMPUTER_FILE_STORE "comsig_computer_file_store"
/// From /obj/item/modular_computer/proc/remove_file, sent to the file itself: ()
#define COMSIG_COMPUTER_FILE_DELETE "comsig_computer_file_delete"

/// From /obj/item/modular_computer/proc/InsertID: (inserting_id, user)
#define COMSIG_MODULAR_COMPUTER_INSERTED_ID "comsig_computer_inserted_id"
/// From /obj/item/modular_computer/proc/RemoveID: ()
#define COMSIG_MODULAR_COMPUTER_REMOVED_ID "comsig_computer_removed_id"

/// from /obj/item/modular_computer/update_id_imprint(): (name, job)
#define COMSIG_MODULAR_PDA_IMPRINT_UPDATED "comsig_modular_pda_imprint_updated"
/// from /obj/item/modular_computer/reset_id(): ()
#define COMSIG_MODULAR_PDA_IMPRINT_RESET "comsig_modular_pda_imprint_reset"

/// From /datum/computer_file/program/messenger/receive_message, sent to the computer: (signal/subspace/messaging/tablet_message/signal, sender_job, sender_name)
#define COMSIG_MODULAR_PDA_MESSAGE_RECEIVED "comsig_modular_pda_message_received"
/// From /datum/computer_file/program/messenger/send_message_signal, sent to the computer: (atom/origin, datum/signal/subspace/messaging/tablet_message/signal)
#define COMSIG_MODULAR_PDA_MESSAGE_SENT "comsig_modular_pda_message_sent"

/// From /datum/computer_file/program/messenger/receive_message
#define COMSIG_COMPUTER_RECEIVED_MESSAGE "computer_received_message"
