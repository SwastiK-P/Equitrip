# Equitrip overview

## What Equitrip is

Equitrip is a group travel planner with a shared expense ledger. A trip holds an itinerary of bookings (flights, stays, trains, activities, meals) and every booking carries a cost, the person who paid for it, and a split mode that decides who shares that cost. Balances, settlements and departures are all derived from those bookings. Postgres on Supabase is the only source of truth; the app never invents sample data.

## Currency

Currency belongs to the trip, not the app. A group can run a Goa trip in rupees and a Bali trip in US dollars without converting anything. Every amount on a trip is in that trip's currency.

## Privacy and security

Every table is protected by row-level security. The app's publishable key has no privileges of its own; a user only sees trips they belong to.
