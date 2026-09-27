# Departures, imports and offline use

## Leaving a trip early (departures)

When someone leaves a trip early, Equitrip shows a departure preview. The preview builds a hypothetical trip without that person on future bookings and asks it the same share and balance questions as the real trip. There is no separate arithmetic for departures, so the preview always agrees with the ledger.

## Importing bookings

Booking PDFs and payment emails are read on the device with Apple Intelligence. The model never produces money: amounts and times are copied from the source text, and names must appear in it. If an amount is not in the source, it is left for the user to enter.

## Offline use

Offline, the app shows the last synced copy of each trip. Booking and expense writes, trip creation, audit rows and notifications go into an ordered outbox that is replayed on reconnect. A write is kept when the failure is a connectivity error and dropped and reported when the server refuses it.
