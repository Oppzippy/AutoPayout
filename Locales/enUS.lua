local addonName = ...

local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
if not L then return end

L.addon_name = "Auto Payout"

L.date_time = "%Y-%m-%d %I:%M%p"

L.payout_setup = "Payout Setup"
L.payout = "Payout"
L.payout_csv = "Payout CSV"
L.payout_history = "Payout History"

L.subject = "Subject"
L.unit = "Unit"
L.unit_with_value = "Unit: %s"
L.start_payout = "Start Payout"
L.not_assigned_gold_value = "%s is not assigned a gold value"
L.next = "Next"

L.start = "Start"
L.pause = "Pause"
L.done = "Done"
L.input = "Input"
L.output = "Output"


L.payout_in_progress = "Payout in progress. Please keep the mailbox open."
L.unsent_mail = "Unsent Mail"
L.must_be_at_mailbox = "You must be at a mailbox to start the payout."
L.can_not_assign_negative_gold = "You can not send negative gold to %s."

L.automatically_show = "Automatically show when opening mailbox"
L.default_subject = "Default Subject"
L.default_unit = "Default Unit"
L.max_history_size = "Maximum History Size"
L.max_payout_size_in_gold = "Maximum Payout Size"
L.max_payout_size_in_gold_desc = "Split payments up after this much gold"
L.max_payout_splits = "Maximum Payout Splits"
L.max_payout_splits_desc = "Payments over the specified gold limit will only be split up to this many times. After that, the remainder will all go in one payment."
