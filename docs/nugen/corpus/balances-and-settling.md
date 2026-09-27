# Balances and settling up

## Balances

A traveller's balance is what they paid minus their share of every booking. A positive balance means the group owes them money. A negative balance means they owe the group. Remaining balance also accounts for direct settlements that have already been confirmed. A balance smaller than one unit of the trip's currency counts as settled, so fractions never create a transfer.

## Settling up

Equitrip suggests the fewest transfers that clear every balance, in two passes. First, cancel exact matches: any debtor whose balance exactly mirrors a creditor's settles with one transfer between just those two. Second, greedy on the remainder: sort by size and let the largest creditor absorb as much of the largest debtor's balance as it can, repeating until both lists are empty. With n people carrying a balance this needs at most n minus 1 transfers. Example: balances +8000, +4000, -3000, -4000, -5000 settle in three transfers because +4000 and -4000 cancel first; pure greedy would need four.

## Settlement confirmation

A settlement is a direct transfer between two travellers outside any booking. The payer records it and it starts as pending. Only the recipient can move it out of pending, by confirming or declining it. The payer can only create or withdraw it. This is enforced by the database row-level security policy settlements_respond. A balance nobody can move by typing a number into their own app is a balance worth trusting. A pending settlement does not change anyone's balance until the recipient confirms it.

## Audit trail

Every change to money is written to an append-only audit trail. Rows are never updated or deleted; a correction is a new row. The audit trail is separate from notifications.
