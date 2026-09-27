# Equitrip · Equi question reading — worked examples

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 4 Nov 2025 to 12 Nov 2025, finished
- "Singapore Stopover" — Singapore, 24 Sep 2026 to 3 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 6 Sep 2026 to 9 Sep 2026, finished
Being discussed: "Singapore Stopover"
Question: thanks

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 26 Nov 2025 to 2 Dec 2025, finished
- "Singapore Stopover" — Singapore, 27 Jan 2027 to 31 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 25 Sep 2026 to 27 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 3 Jan 2027 to 12 Jan 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 25 Oct 2026 to 2 Nov 2026, upcoming
Question: have we booked a way to get there?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 10 Feb 2027 to 12 Feb 2027, upcoming
- "Singapore Stopover" — Singapore, 26 Sep 2026 to 30 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 12 Sep 2025 to 15 Sep 2025, finished
- "Udaipur Wedding" — Udaipur, India, 19 Jan 2027 to 28 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 4 Jan 2026 to 9 Jan 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 22 Oct 2025 to 31 Oct 2025, finished
Question: total cab spend on the next trip?

### Response
{"topic":"spending","trip":"next","tripTitle":"","category":"transfer","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 22 Aug 2026 to 26 Aug 2026, finished
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 3 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 22 Nov 2026 to 28 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 29 Jan 2027 to 7 Feb 2027, upcoming
- "Singapore Stopover" — Singapore, 21 Feb 2027 to 23 Feb 2027, upcoming
- "Pondy Chill" — Puducherry, India, 22 Dec 2026 to 31 Dec 2026, upcoming
Question: what trips do I have coming up?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 8 Nov 2026 to 17 Nov 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 22 Jul 2026 to 24 Jul 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 27 Feb 2027 to 2 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 26 Sep 2026 to 1 Oct 2026, under way now
- "Manali Snow Run" — Manali, India, 25 Oct 2025 to 27 Oct 2025, finished
- "Bali Bros" — Bali, Indonesia, 9 Dec 2026 to 16 Dec 2026, upcoming
Being discussed: "Kerala Backwaters"
Question: thanks!

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 30 Jun 2026 to 6 Jul 2026, finished
- "Singapore Stopover" — Singapore, 24 Sep 2026 to 2 Oct 2026, under way now
- "Coorg Coffee Trail" — Coorg, India, 15 Dec 2025 to 20 Dec 2025, finished
- "Manali Snow Run" — Manali, India, 5 Oct 2026 to 8 Oct 2026, upcoming
- "Ladakh Ride" — Leh, India, 20 Oct 2026 to 22 Oct 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 16 Mar 2027 to 23 Mar 2027, upcoming
Question: Kabir ne ab tak kitna pay kiya?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"Kabir","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 10 Mar 2027 to 17 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 4 Mar 2027 to 9 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 1 Dec 2025 to 9 Dec 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 30 May 2026 to 3 Jun 2026, finished
- "Thailand Trip" — Phuket, Thailand, 11 Oct 2025 to 13 Oct 2025, finished
- "Bali Bros" — Bali, Indonesia, 13 Apr 2027 to 18 Apr 2027, upcoming
Question: quick summary of Bali Bros

### Response
{"topic":"overview","trip":"named","tripTitle":"Bali Bros","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 24 Sep 2026 to 27 Sep 2026, under way now
- "Paris Escape" — Paris, France, 19 Dec 2026 to 23 Dec 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 15 Nov 2026 to 21 Nov 2026, upcoming
- "Ladakh Ride" — Leh, India, 6 Feb 2027 to 14 Feb 2027, upcoming
Being discussed: "Kerala Backwaters"
Previous question: is trip mein kaun kaun aa raha hai?
Question: kal ka?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 16 Mar 2027 to 23 Mar 2027, upcoming
- "Goa Getaway" — Goa, India, 18 Feb 2027 to 22 Feb 2027, upcoming
- "Rome in Spring" — Rome, Italy, 11 Mar 2026 to 15 Mar 2026, finished
- "Pondy Chill" — Puducherry, India, 22 Feb 2027 to 27 Feb 2027, upcoming
Previous question: have we booked a way to get there?
Question: kal ka?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 27 Jan 2026 to 31 Jan 2026, finished
- "Jaipur Weekend" — Jaipur, India, 22 Sep 2025 to 24 Sep 2025, finished
- "Bali Bros" — Bali, Indonesia, 4 Apr 2027 to 8 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 22 Dec 2025 to 29 Dec 2025, finished
- "Singapore Stopover" — Singapore, 1 Mar 2027 to 4 Mar 2027, upcoming
Question: khane pe kitna gaya

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 2 Apr 2026 to 5 Apr 2026, finished
- "Goa Getaway" — Goa, India, 21 Sep 2025 to 28 Sep 2025, finished
- "Manali Snow Run" — Manali, India, 26 Jan 2027 to 28 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 21 Dec 2026 to 26 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 24 Sep 2026 to 2 Oct 2026, under way now
Question: good morning

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 15 Dec 2026 to 18 Dec 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 16 Jan 2027 to 23 Jan 2027, upcoming
- "Goa Getaway" — Goa, India, 27 Sep 2026 to 4 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 24 Nov 2025 to 26 Nov 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 16 Jun 2026 to 19 Jun 2026, finished
Being discussed: "Goa Getaway"
Previous question: kaunsi flights book hain last wali trip ke liye?
Question: and the other one

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 27 Sep 2026 to 5 Oct 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 8 Nov 2026 to 13 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 30 Aug 2026 to 5 Sep 2026, finished
- "Paris Escape" — Paris, France, 1 Feb 2027 to 9 Feb 2027, upcoming
- "Rome in Spring" — Rome, Italy, 21 Dec 2026 to 25 Dec 2026, upcoming
- "Singapore Stopover" — Singapore, 24 Oct 2026 to 28 Oct 2026, upcoming
Question: who made you?

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 25 Sep 2025 to 29 Sep 2025, finished
- "Goa Getaway" — Goa, India, 1 Apr 2027 to 8 Apr 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 24 Nov 2025 to 30 Nov 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 22 Nov 2026 to 29 Nov 2026, upcoming
- "Singapore Stopover" — Singapore, 27 Jan 2027 to 5 Feb 2027, upcoming
Question: do i need to settle up with anyone?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 15 Oct 2025 to 19 Oct 2025, finished
- "Singapore Stopover" — Singapore, 7 Apr 2026 to 14 Apr 2026, finished
- "Udaipur Wedding" — Udaipur, India, 25 Sep 2026 to 29 Sep 2026, under way now
Previous question: what's the damage on dinners?
Question: same for Omar

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"Omar","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 26 Dec 2026 to 1 Jan 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 12 Oct 2026 to 17 Oct 2026, upcoming
- "Rome in Spring" — Rome, Italy, 11 Apr 2026 to 17 Apr 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 25 Sep 2026 to 2 Oct 2026, under way now
Being discussed: "Meghalaya Monsoon"
Question: give me a recap of our upcoming trip

### Response
{"topic":"overview","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 26 Sep 2026 to 30 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 10 Jul 2026 to 12 Jul 2026, finished
- "Kerala Backwaters" — Alleppey, India, 18 Oct 2026 to 25 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 26 Nov 2026 to 30 Nov 2026, upcoming
Question: aaj kitna kharcha ho gaya?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 27 Nov 2025 to 2 Dec 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 25 Mar 2027 to 3 Apr 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 25 Sep 2026 to 28 Sep 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 25 Jul 2026 to 3 Aug 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 8 Dec 2026 to 13 Dec 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 25 Mar 2026 to 2 Apr 2026, finished
Question: thank you Equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 24 Sep 2026 to 29 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 24 Jan 2026 to 28 Jan 2026, finished
- "Udaipur Wedding" — Udaipur, India, 9 Dec 2026 to 16 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 28 Mar 2026 to 3 Apr 2026, finished
Question: kaise ho?

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 12 Jan 2027 to 14 Jan 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 25 Sep 2026 to 3 Oct 2026, under way now
- "Pondy Chill" — Puducherry, India, 26 Oct 2026 to 4 Nov 2026, upcoming
Question: tell me a joke

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 20 Mar 2026 to 28 Mar 2026, finished
- "Goa Getaway" — Goa, India, 2 Feb 2027 to 9 Feb 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 19 Aug 2026 to 24 Aug 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 4 Oct 2025 to 10 Oct 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 6 Oct 2026 to 11 Oct 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 10 Feb 2027 to 16 Feb 2027, upcoming
Question: Koi din khali hai kya pichli trip mein

### Response
{"topic":"gaps","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 11 Sep 2025 to 17 Sep 2025, finished
- "Pondy Chill" — Puducherry, India, 21 Nov 2025 to 29 Nov 2025, finished
- "Ladakh Ride" — Leh, India, 26 Sep 2026 to 29 Sep 2026, under way now
- "Coorg Coffee Trail" — Coorg, India, 22 Apr 2026 to 30 Apr 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 5 Jun 2026 to 10 Jun 2026, finished
Question: who's coming on the Ladakh trip?

### Response
{"topic":"people","trip":"named","tripTitle":"Ladakh Ride","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 5 Dec 2026 to 14 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 3 Mar 2026 to 9 Mar 2026, finished
- "Jaipur Weekend" — Jaipur, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 14 Nov 2025 to 16 Nov 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 18 Oct 2026 to 24 Oct 2026, upcoming
Question: tell me a joke

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 24 Sep 2026 to 27 Sep 2026, under way now
- "Rome in Spring" — Rome, Italy, 25 Nov 2026 to 27 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 2 Dec 2026 to 7 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 9 Feb 2027 to 13 Feb 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 25 Nov 2026 to 1 Dec 2026, upcoming
Question: theek hai, thanks

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 30 Aug 2025 to 3 Sep 2025, finished
- "Ladakh Ride" — Leh, India, 6 Oct 2025 to 8 Oct 2025, finished
- "Jaipur Weekend" — Jaipur, India, 17 Apr 2026 to 23 Apr 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 28 Jun 2026 to 4 Jul 2026, finished
- "Thailand Trip" — Phuket, Thailand, 25 Sep 2026 to 29 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 14 Nov 2026 to 18 Nov 2026, upcoming
Question: Is anything not booked yet for our last trip?

### Response
{"topic":"gaps","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 10 Nov 2026 to 17 Nov 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 7 Sep 2025 to 9 Sep 2025, finished
- "Rome in Spring" — Rome, Italy, 3 Oct 2026 to 5 Oct 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 11 Mar 2026 to 17 Mar 2026, finished
Question: dinner ka bill kisne bhara?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 1 Mar 2026 to 5 Mar 2026, finished
- "Kerala Backwaters" — Alleppey, India, 24 Sep 2026 to 2 Oct 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 2 Jan 2027 to 7 Jan 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 12 Mar 2027 to 21 Mar 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 6 Mar 2027 to 15 Mar 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 22 May 2026 to 27 May 2026, finished
Being discussed: "Kerala Backwaters"
Question: which trip cost the most

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 4 Oct 2026 to 13 Oct 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 3 Feb 2027 to 7 Feb 2027, upcoming
- "Singapore Stopover" — Singapore, 26 Jun 2026 to 1 Jul 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 26 Jan 2027 to 3 Feb 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 13 Mar 2027 to 15 Mar 2027, upcoming
Question: khane pe kitna gaya

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 9 Nov 2025 to 11 Nov 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 11 Dec 2025 to 20 Dec 2025, finished
- "Manali Snow Run" — Manali, India, 27 Sep 2026 to 5 Oct 2026, under way now
Question: hi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 8 Dec 2025 to 14 Dec 2025, finished
- "Paris Escape" — Paris, France, 15 Aug 2026 to 18 Aug 2026, finished
- "Rome in Spring" — Rome, Italy, 27 Sep 2026 to 4 Oct 2026, under way now
Question: what do I owe Meera for our trip?

### Response
{"topic":"balance","trip":"current","tripTitle":"","category":"anything","person":"Meera","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 11 Jul 2026 to 20 Jul 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 24 Sep 2026 to 3 Oct 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 6 Oct 2026 to 15 Oct 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 23 Feb 2026 to 25 Feb 2026, finished
- "Rome in Spring" — Rome, Italy, 29 Jan 2027 to 2 Feb 2027, upcoming
- "Singapore Stopover" — Singapore, 2 Dec 2026 to 9 Dec 2026, upcoming
Being discussed: "Meghalaya Monsoon"
Question: tell me about Rome in Spring

### Response
{"topic":"overview","trip":"named","tripTitle":"Rome in Spring","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 15 Jul 2026 to 23 Jul 2026, finished
- "Kerala Backwaters" — Alleppey, India, 3 Oct 2026 to 8 Oct 2026, upcoming
- "Pondy Chill" — Puducherry, India, 12 Aug 2026 to 18 Aug 2026, finished
- "Ladakh Ride" — Leh, India, 13 Dec 2025 to 19 Dec 2025, finished
Question: train kab chhootegi

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 10 Feb 2027 to 12 Feb 2027, upcoming
- "Manali Snow Run" — Manali, India, 9 Oct 2025 to 18 Oct 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 11 Apr 2026 to 14 Apr 2026, finished
Previous question: how much have we spent today?
Question: What about tomorrow?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 4 Dec 2025 to 11 Dec 2025, finished
- "Kerala Backwaters" — Alleppey, India, 7 Dec 2025 to 15 Dec 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 24 Oct 2026 to 29 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 31 Aug 2026 to 8 Sep 2026, finished
- "Udaipur Wedding" — Udaipur, India, 21 Feb 2027 to 24 Feb 2027, upcoming
Question: any train tickets for Kerala Backwaters?

### Response
{"topic":"bookings","trip":"named","tripTitle":"Kerala Backwaters","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 3 Jul 2026 to 8 Jul 2026, finished
- "Rome in Spring" — Rome, Italy, 28 Mar 2027 to 1 Apr 2027, upcoming
- "Goa Getaway" — Goa, India, 15 Nov 2026 to 24 Nov 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 27 Sep 2026 to 1 Oct 2026, under way now
Being discussed: "Kerala Backwaters"
Question: thank you Equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 3 Dec 2026 to 9 Dec 2026, upcoming
- "Goa Getaway" — Goa, India, 26 Sep 2026 to 2 Oct 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 4 Oct 2026 to 6 Oct 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 8 Apr 2027 to 12 Apr 2027, upcoming
- "Manali Snow Run" — Manali, India, 2 Mar 2027 to 5 Mar 2027, upcoming
Being discussed: "Goa Getaway"
Question: Good morning

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 5 Dec 2026 to 7 Dec 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 6 Mar 2027 to 12 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 24 Feb 2026 to 26 Feb 2026, finished
Question: kya kya activities hain Coorg Coffee Trail wali trip mein?

### Response
{"topic":"bookings","trip":"named","tripTitle":"Coorg Coffee Trail","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 16 Dec 2026 to 23 Dec 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 17 Jul 2026 to 19 Jul 2026, finished
- "Pondy Chill" — Puducherry, India, 21 May 2026 to 27 May 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 28 Nov 2026 to 5 Dec 2026, upcoming
- "Hampi Heritage" — Hampi, India, 18 Jul 2026 to 23 Jul 2026, finished
- "Ladakh Ride" — Leh, India, 3 Nov 2026 to 10 Nov 2026, upcoming
Question: Hampi mein mausam kaisa hoga?

### Response
{"topic":"advice","trip":"named","tripTitle":"Hampi Heritage","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 7 Apr 2026 to 11 Apr 2026, finished
- "Kerala Backwaters" — Alleppey, India, 22 Mar 2027 to 26 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 6 Jan 2027 to 15 Jan 2027, upcoming
- "Goa Getaway" — Goa, India, 29 Oct 2025 to 4 Nov 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 6 Nov 2025 to 13 Nov 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 25 Sep 2026 to 3 Oct 2026, under way now
Being discussed: "Meghalaya Monsoon"
Question: who made you?

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 24 Sep 2026 to 2 Oct 2026, under way now
- "Paris Escape" — Paris, France, 3 Jan 2027 to 8 Jan 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 28 Feb 2027 to 8 Mar 2027, upcoming
- "Goa Getaway" — Goa, India, 10 Apr 2027 to 12 Apr 2027, upcoming
- "Ladakh Ride" — Leh, India, 10 May 2026 to 15 May 2026, finished
Being discussed: "Tokyo 2026"
Question: What activities do we have on our trip

### Response
{"topic":"bookings","trip":"current","tripTitle":"","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 16 Jan 2026 to 23 Jan 2026, finished
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 5 Oct 2026, under way now
- "Paris Escape" — Paris, France, 27 Mar 2026 to 2 Apr 2026, finished
Question: sabse mehengi trip kaunsi thi?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 26 Sep 2026 to 29 Sep 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 14 Mar 2026 to 19 Mar 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 23 Jan 2026 to 1 Feb 2026, finished
Question: Have we booked a way to get there

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 30 Dec 2026 to 2 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 11 Feb 2026 to 15 Feb 2026, finished
- "Pondy Chill" — Puducherry, India, 14 Mar 2027 to 17 Mar 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 2 Apr 2027 to 7 Apr 2027, upcoming
- "Goa Getaway" — Goa, India, 29 Oct 2026 to 5 Nov 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 2 Sep 2026 to 6 Sep 2026, finished
Question: how much have we spent today?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 16 Nov 2025 to 22 Nov 2025, finished
- "Rome in Spring" — Rome, Italy, 19 Jan 2027 to 25 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 24 Aug 2025 to 28 Aug 2025, finished
- "Pondy Chill" — Puducherry, India, 24 Sep 2026 to 30 Sep 2026, under way now
Being discussed: "Pondy Chill"
Question: does Neha owe me anything?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Neha","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 4 Nov 2025 to 11 Nov 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 6 Apr 2027 to 9 Apr 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 13 Jan 2027 to 21 Jan 2027, upcoming
- "Pondy Chill" — Puducherry, India, 28 Jan 2027 to 5 Feb 2027, upcoming
- "Manali Snow Run" — Manali, India, 1 Mar 2026 to 9 Mar 2026, finished
Question: hisaab kitna baaki hai?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 13 Oct 2026 to 15 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 17 Feb 2027 to 19 Feb 2027, upcoming
- "Goa Getaway" — Goa, India, 22 Mar 2026 to 30 Mar 2026, finished
- "Kerala Backwaters" — Alleppey, India, 8 Jan 2027 to 14 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 2 Oct 2026 to 7 Oct 2026, upcoming
Question: Goa wali trip mein hum kahan ruk rahe hain

### Response
{"topic":"bookings","trip":"named","tripTitle":"Goa Getaway","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 29 Nov 2026 to 2 Dec 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 16 Jul 2026 to 19 Jul 2026, finished
- "Bali Bros" — Bali, Indonesia, 24 Sep 2026 to 26 Sep 2026, under way now
Being discussed: "Bali Bros"
Question: tell me about the Jaipur trip

### Response
{"topic":"overview","trip":"named","tripTitle":"Jaipur Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 14 Mar 2027 to 18 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 18 Jan 2026 to 26 Jan 2026, finished
Question: how is Udaipur Wedding going?

### Response
{"topic":"overview","trip":"named","tripTitle":"Udaipur Wedding","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 9 Oct 2026 to 12 Oct 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 12 Jan 2026 to 20 Jan 2026, finished
- "Kerala Backwaters" — Alleppey, India, 7 Mar 2026 to 15 Mar 2026, finished
- "Paris Escape" — Paris, France, 2 Sep 2026 to 9 Sep 2026, finished
Question: koi din khali hai kya rishikesh rafting mein?

### Response
{"topic":"gaps","trip":"named","tripTitle":"Rishikesh Rafting","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 12 Jun 2026 to 16 Jun 2026, finished
- "Pondy Chill" — Puducherry, India, 29 Nov 2025 to 5 Dec 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 20 Feb 2026 to 26 Feb 2026, finished
Question: list everything booked for the Dubai trip

### Response
{"topic":"bookings","trip":"named","tripTitle":"Dubai Long Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 31 Jan 2027 to 2 Feb 2027, upcoming
- "Manali Snow Run" — Manali, India, 9 Nov 2026 to 15 Nov 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 10 Jan 2027 to 13 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 3 Apr 2026 to 6 Apr 2026, finished
- "Bali Bros" — Bali, Indonesia, 24 Mar 2027 to 1 Apr 2027, upcoming
Question: sabse mehengi trip kaunsi thi?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 27 May 2026 to 1 Jun 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 27 Sep 2026 to 29 Sep 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 22 Nov 2026 to 24 Nov 2026, upcoming
Question: abhi wali trip mein kuch book karna baaki hai?

### Response
{"topic":"gaps","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 2 Jan 2027 to 7 Jan 2027, upcoming
- "Hampi Heritage" — Hampi, India, 25 Sep 2026 to 2 Oct 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 16 Feb 2027 to 19 Feb 2027, upcoming
- "Goa Getaway" — Goa, India, 29 Jan 2026 to 7 Feb 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 13 Oct 2025 to 15 Oct 2025, finished
Being discussed: "Hampi Heritage"
Question: anything planned for dinner tomorrow?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 28 Nov 2026 to 3 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 25 Nov 2026 to 4 Dec 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 7 Jul 2026 to 9 Jul 2026, finished
Question: who paid for the villa?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 14 Dec 2026 to 22 Dec 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 21 Feb 2027 to 1 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 24 Jul 2026 to 1 Aug 2026, finished
- "Jaipur Weekend" — Jaipur, India, 4 Jan 2027 to 9 Jan 2027, upcoming
Question: thanks!

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 29 Jul 2026 to 7 Aug 2026, finished
- "Rome in Spring" — Rome, Italy, 18 May 2026 to 23 May 2026, finished
- "Ladakh Ride" — Leh, India, 10 Mar 2027 to 18 Mar 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 26 Jan 2027 to 28 Jan 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 4 Apr 2027 to 10 Apr 2027, upcoming
Question: who owes whom on the trip

### Response
{"topic":"balance","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 1 Nov 2026 to 3 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 26 Sep 2026 to 1 Oct 2026, under way now
- "Rome in Spring" — Rome, Italy, 26 Feb 2027 to 5 Mar 2027, upcoming
- "Manali Snow Run" — Manali, India, 25 Apr 2026 to 1 May 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2025 to 1 Oct 2025, finished
- "Hampi Heritage" — Hampi, India, 22 Nov 2025 to 28 Nov 2025, finished
Question: what are we doing today

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 13 Apr 2027 to 15 Apr 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 27 Sep 2026 to 30 Sep 2026, under way now
- "Paris Escape" — Paris, France, 30 Aug 2026 to 1 Sep 2026, finished
- "Manali Snow Run" — Manali, India, 13 Mar 2027 to 17 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 28 Aug 2026 to 6 Sep 2026, finished
- "Singapore Stopover" — Singapore, 29 Aug 2026 to 1 Sep 2026, finished
Being discussed: "Kerala Backwaters"
Question: Which trip cost the most?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 24 Jan 2027 to 27 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 1 Apr 2027 to 9 Apr 2027, upcoming
- "Hampi Heritage" — Hampi, India, 16 Jul 2026 to 22 Jul 2026, finished
- "Jaipur Weekend" — Jaipur, India, 2 Dec 2026 to 9 Dec 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 28 Jul 2026 to 30 Jul 2026, finished
- "Udaipur Wedding" — Udaipur, India, 24 Aug 2026 to 29 Aug 2026, finished
Question: how's the trip going so far

### Response
{"topic":"overview","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 24 Jan 2026 to 27 Jan 2026, finished
- "Kerala Backwaters" — Alleppey, India, 5 Feb 2027 to 8 Feb 2027, upcoming
- "Paris Escape" — Paris, France, 30 Dec 2026 to 3 Jan 2027, upcoming
Question: Coorg Coffee Trail kab hai?

### Response
{"topic":"overview","trip":"named","tripTitle":"Coorg Coffee Trail","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 6 Feb 2027 to 10 Feb 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 26 Sep 2026 to 1 Oct 2026, under way now
- "Goa Getaway" — Goa, India, 9 Feb 2027 to 12 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 30 May 2026 to 8 Jun 2026, finished
Being discussed: "Meghalaya Monsoon"
Previous question: what's on today's agenda
Question: kal ka?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 2 Oct 2025 to 10 Oct 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 28 Dec 2026 to 4 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 18 Feb 2027 to 25 Feb 2027, upcoming
- "Pondy Chill" — Puducherry, India, 3 Feb 2026 to 11 Feb 2026, finished
Question: budget se upar toh nahi gaye?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Pondy Chill" — Puducherry, India, 1 Nov 2026 to 10 Nov 2026, upcoming
- "Ladakh Ride" — Leh, India, 27 Feb 2026 to 5 Mar 2026, finished
- "Jaipur Weekend" — Jaipur, India, 11 Feb 2026 to 19 Feb 2026, finished
Question: pichli trip kaisi chal rahi hai?

### Response
{"topic":"overview","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 5 Nov 2026 to 13 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 14 Dec 2025 to 19 Dec 2025, finished
- "Singapore Stopover" — Singapore, 28 Mar 2027 to 30 Mar 2027, upcoming
- "Goa Getaway" — Goa, India, 25 Sep 2026 to 27 Sep 2026, under way now
Being discussed: "Goa Getaway"
Question: Tell me a joke

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 27 Sep 2026 to 30 Sep 2026, under way now
- "Bali Bros" — Bali, Indonesia, 12 May 2026 to 16 May 2026, finished
- "Pondy Chill" — Puducherry, India, 16 Nov 2026 to 24 Nov 2026, upcoming
Question: list everything booked for the previous trip

### Response
{"topic":"bookings","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 11 Mar 2027 to 14 Mar 2027, upcoming
- "Manali Snow Run" — Manali, India, 21 Jul 2026 to 26 Jul 2026, finished
- "Jaipur Weekend" — Jaipur, India, 25 Sep 2026 to 3 Oct 2026, under way now
- "Singapore Stopover" — Singapore, 17 Jan 2026 to 19 Jan 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 14 Jun 2026 to 18 Jun 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 3 Dec 2025 to 11 Dec 2025, finished
Question: budget se upar toh nahi gaye

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 1 Nov 2026 to 3 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 27 Jan 2026 to 1 Feb 2026, finished
- "Manali Snow Run" — Manali, India, 20 Oct 2026 to 29 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 12 Oct 2025 to 15 Oct 2025, finished
- "Bali Bros" — Bali, Indonesia, 22 Apr 2026 to 27 Apr 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 20 Oct 2025 to 27 Oct 2025, finished
Question: sabse mehengi trip kaunsi thi?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 14 Jul 2026 to 22 Jul 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 17 Aug 2026 to 22 Aug 2026, finished
- "Thailand Trip" — Phuket, Thailand, 25 Jun 2026 to 29 Jun 2026, finished
Question: sneha ko kitna dena hai?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Sneha","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 26 Sep 2026 to 2 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 21 Nov 2025 to 23 Nov 2025, finished
- "Thailand Trip" — Phuket, Thailand, 5 Nov 2026 to 10 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 13 Jan 2027 to 16 Jan 2027, upcoming
- "Manali Snow Run" — Manali, India, 28 Feb 2026 to 4 Mar 2026, finished
Question: Manali wali trip mein hum kahan ruk rahe hain

### Response
{"topic":"bookings","trip":"named","tripTitle":"Manali Snow Run","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 19 Dec 2026 to 23 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 9 Jan 2027 to 16 Jan 2027, upcoming
- "Manali Snow Run" — Manali, India, 24 Mar 2027 to 28 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 6 Nov 2026 to 15 Nov 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 9 Dec 2026 to 12 Dec 2026, upcoming
- "Goa Getaway" — Goa, India, 28 Oct 2025 to 6 Nov 2025, finished
Question: what's the weather like in shillong this time of year?

### Response
{"topic":"advice","trip":"named","tripTitle":"Meghalaya Monsoon","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 4 Oct 2025 to 11 Oct 2025, finished
- "Hampi Heritage" — Hampi, India, 7 Oct 2026 to 13 Oct 2026, upcoming
- "Paris Escape" — Paris, France, 24 Sep 2026 to 1 Oct 2026, under way now
Question: show my past trips

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Paris Escape" — Paris, France, 14 Dec 2026 to 22 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 19 Dec 2026 to 21 Dec 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 15 Jan 2026 to 19 Jan 2026, finished
- "Manali Snow Run" — Manali, India, 31 Mar 2026 to 8 Apr 2026, finished
- "Goa Getaway" — Goa, India, 3 Dec 2026 to 7 Dec 2026, upcoming
Question: how is the trip going?

### Response
{"topic":"overview","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 22 Feb 2027 to 26 Feb 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 4 Oct 2025 to 9 Oct 2025, finished
- "Manali Snow Run" — Manali, India, 24 Sep 2026 to 28 Sep 2026, under way now
Question: what's my balance across all trips?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 24 Sep 2026 to 2 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 23 Aug 2026 to 27 Aug 2026, finished
- "Goa Getaway" — Goa, India, 3 Nov 2026 to 7 Nov 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 29 Dec 2025 to 31 Dec 2025, finished
- "Paris Escape" — Paris, France, 21 Oct 2025 to 29 Oct 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 8 Nov 2026 to 14 Nov 2026, upcoming
Being discussed: "Rome in Spring"
Question: how's the trip going so far?

### Response
{"topic":"overview","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 10 Dec 2026 to 18 Dec 2026, upcoming
- "Ladakh Ride" — Leh, India, 10 Dec 2026 to 15 Dec 2026, upcoming
- "Rome in Spring" — Rome, Italy, 21 Oct 2025 to 26 Oct 2025, finished
- "Udaipur Wedding" — Udaipur, India, 29 Jan 2026 to 7 Feb 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 24 Jan 2027 to 28 Jan 2027, upcoming
Question: sabse mehengi trip kaunsi thi

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 15 Nov 2026 to 18 Nov 2026, upcoming
- "Pondy Chill" — Puducherry, India, 27 Sep 2026 to 2 Oct 2026, under way now
- "Paris Escape" — Paris, France, 13 Jun 2026 to 16 Jun 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 30 Aug 2025 to 7 Sep 2025, finished
- "Rome in Spring" — Rome, Italy, 9 Feb 2027 to 17 Feb 2027, upcoming
Previous question: am I even with Kim?
Question: what about tomorrow?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 16 Oct 2025 to 23 Oct 2025, finished
- "Rome in Spring" — Rome, Italy, 27 Oct 2025 to 31 Oct 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 30 Dec 2025 to 5 Jan 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 19 Mar 2026 to 27 Mar 2026, finished
- "Goa Getaway" — Goa, India, 5 Feb 2027 to 10 Feb 2027, upcoming
Question: Any nights without a hotel on the tokyo trip?

### Response
{"topic":"gaps","trip":"named","tripTitle":"Tokyo 2026","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 5 Jan 2027 to 11 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 10 Oct 2026 to 18 Oct 2026, upcoming
- "Goa Getaway" — Goa, India, 13 Mar 2027 to 19 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 9 Apr 2027 to 11 Apr 2027, upcoming
- "Manali Snow Run" — Manali, India, 16 Jan 2026 to 22 Jan 2026, finished
- "Pondy Chill" — Puducherry, India, 25 Sep 2026 to 28 Sep 2026, under way now
Question: what time is the airport pickup today

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 28 Nov 2025 to 3 Dec 2025, finished
- "Manali Snow Run" — Manali, India, 9 Feb 2027 to 12 Feb 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 25 Sep 2026 to 3 Oct 2026, under way now
- "Paris Escape" — Paris, France, 31 Aug 2026 to 3 Sep 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 11 Jul 2026 to 18 Jul 2026, finished
Question: do I need to settle up with anyone?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 12 Mar 2026 to 18 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 27 Sep 2026 to 1 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 30 Nov 2025 to 2 Dec 2025, finished
- "Paris Escape" — Paris, France, 28 Feb 2027 to 7 Mar 2027, upcoming
- "Manali Snow Run" — Manali, India, 31 Jul 2026 to 6 Aug 2026, finished
- "Goa Getaway" — Goa, India, 17 May 2026 to 26 May 2026, finished
Question: Vietnam mein kya khana chahiye

### Response
{"topic":"advice","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 27 Sep 2026 to 4 Oct 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 9 Dec 2026 to 11 Dec 2026, upcoming
- "Pondy Chill" — Puducherry, India, 4 Jan 2027 to 11 Jan 2027, upcoming
- "Hampi Heritage" — Hampi, India, 31 Dec 2026 to 8 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 24 Mar 2026 to 28 Mar 2026, finished
Question: what are we doing today?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 20 May 2026 to 27 May 2026, finished
- "Goa Getaway" — Goa, India, 2 Jan 2027 to 4 Jan 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 28 Feb 2027 to 6 Mar 2027, upcoming
- "Ladakh Ride" — Leh, India, 7 Feb 2026 to 15 Feb 2026, finished
Question: anything planned for dinner tomorrow?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 27 Jan 2027 to 5 Feb 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 8 Jan 2027 to 13 Jan 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 24 Sep 2026 to 27 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 4 Oct 2026 to 10 Oct 2026, upcoming
- "Goa Getaway" — Goa, India, 21 Oct 2026 to 29 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 12 May 2026 to 18 May 2026, finished
Being discussed: "Dubai Long Weekend"
Question: how much do i get back from this trip?

### Response
{"topic":"balance","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 15 Apr 2027 to 22 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 22 Jan 2027 to 25 Jan 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 8 Nov 2026 to 14 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 12 Jan 2027 to 18 Jan 2027, upcoming
- "Goa Getaway" — Goa, India, 12 Jun 2026 to 16 Jun 2026, finished
Question: give me a recap of the Goa trip

### Response
{"topic":"overview","trip":"named","tripTitle":"Goa Getaway","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 24 Sep 2026 to 27 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 6 Jan 2027 to 15 Jan 2027, upcoming
- "Pondy Chill" — Puducherry, India, 5 Dec 2026 to 13 Dec 2026, upcoming
Previous question: next trip mein kaun kaun aa raha hai?
Question: and for the trip

### Response
{"topic":"people","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 24 Sep 2026 to 1 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 3 Aug 2026 to 11 Aug 2026, finished
- "Udaipur Wedding" — Udaipur, India, 27 Apr 2026 to 3 May 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 26 Jan 2027 to 29 Jan 2027, upcoming
- "Goa Getaway" — Goa, India, 25 Jan 2027 to 31 Jan 2027, upcoming
Question: who owes whom on ladakh ride?

### Response
{"topic":"balance","trip":"named","tripTitle":"Ladakh Ride","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 10 Oct 2026 to 17 Oct 2026, upcoming
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 6 Oct 2026, under way now
- "Rishikesh Rafting" — Rishikesh, India, 29 Jan 2027 to 5 Feb 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 31 Dec 2026 to 9 Jan 2027, upcoming
Question: which was my cheapest trip?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 4 Jan 2026 to 10 Jan 2026, finished
- "Ladakh Ride" — Leh, India, 2 Nov 2026 to 8 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 28 Mar 2026 to 31 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 25 Mar 2026 to 30 Mar 2026, finished
Question: list everything booked for the trip

### Response
{"topic":"bookings","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 16 May 2026 to 19 May 2026, finished
- "Rome in Spring" — Rome, Italy, 22 Apr 2026 to 29 Apr 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 30 Nov 2025 to 9 Dec 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 31 Oct 2026 to 5 Nov 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 31 Aug 2025 to 9 Sep 2025, finished
Question: give me a recap of the Rome in Spring trip

### Response
{"topic":"overview","trip":"named","tripTitle":"Rome in Spring","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 30 May 2026 to 6 Jun 2026, finished
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 2 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 27 Oct 2026 to 2 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 26 Dec 2026 to 4 Jan 2027, upcoming
Being discussed: "Ladakh Ride"
Question: aaj kitna kharcha ho gaya?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 13 Mar 2027 to 17 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 4 Jan 2027 to 7 Jan 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2025 to 3 Oct 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 18 Feb 2026 to 25 Feb 2026, finished
- "Hampi Heritage" — Hampi, India, 26 Sep 2026 to 3 Oct 2026, under way now
- "Goa Getaway" — Goa, India, 17 Oct 2026 to 21 Oct 2026, upcoming
Being discussed: "Hampi Heritage"
Question: show my past trips

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 21 Oct 2025 to 23 Oct 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 19 Oct 2026 to 25 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 24 Dec 2026 to 31 Dec 2026, upcoming
- "Manali Snow Run" — Manali, India, 25 Jan 2027 to 29 Jan 2027, upcoming
Question: kisi raat hotel nahi hai kya

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Paris Escape" — Paris, France, 10 May 2026 to 16 May 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 7 Sep 2026 to 14 Sep 2026, finished
- "Hampi Heritage" — Hampi, India, 3 Apr 2027 to 5 Apr 2027, upcoming
Previous question: how much has Arjun paid so far?
Question: aur Rishikesh Rafting wali trip mein?

### Response
{"topic":"people","trip":"named","tripTitle":"Rishikesh Rafting","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 22 Oct 2026 to 29 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 9 Mar 2027 to 14 Mar 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 26 Sep 2026 to 29 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 13 Oct 2026 to 18 Oct 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 25 Oct 2026 to 30 Oct 2026, upcoming
Question: is trip mein total kitna kharcha hua?

### Response
{"topic":"spending","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 23 Sep 2025 to 28 Sep 2025, finished
- "Singapore Stopover" — Singapore, 13 Jan 2027 to 16 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 17 Mar 2026 to 22 Mar 2026, finished
- "Goa Getaway" — Goa, India, 26 Sep 2026 to 3 Oct 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 24 Dec 2026 to 29 Dec 2026, upcoming
Being discussed: "Goa Getaway"
Question: tell me about my next trip

### Response
{"topic":"overview","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 11 Nov 2026 to 20 Nov 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 28 Nov 2026 to 6 Dec 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 27 Sep 2026 to 3 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 8 Jul 2026 to 10 Jul 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 28 Mar 2027 to 31 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 11 Nov 2026 to 19 Nov 2026, upcoming
Being discussed: "Jaipur Weekend"
Question: budget se upar toh nahi gaye

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 24 Jan 2027 to 31 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 11 Feb 2026 to 13 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 22 Feb 2027 to 25 Feb 2027, upcoming
Question: who paid for the villa?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 3 Nov 2025 to 6 Nov 2025, finished
- "Goa Getaway" — Goa, India, 25 Jul 2026 to 3 Aug 2026, finished
- "Pondy Chill" — Puducherry, India, 6 Feb 2027 to 8 Feb 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 14 Oct 2026 to 17 Oct 2026, upcoming
Question: Dev ne ab tak kitna pay kiya?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"Dev","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 12 Jan 2026 to 21 Jan 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 31 Mar 2027 to 2 Apr 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 12 Apr 2026 to 16 Apr 2026, finished
- "Ladakh Ride" — Leh, India, 20 Feb 2026 to 27 Feb 2026, finished
- "Thailand Trip" — Phuket, Thailand, 24 Sep 2026 to 2 Oct 2026, under way now
- "Coorg Coffee Trail" — Coorg, India, 7 Jun 2026 to 15 Jun 2026, finished
Question: what did the flights come to?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 16 Jan 2026 to 22 Jan 2026, finished
- "Hampi Heritage" — Hampi, India, 3 Feb 2026 to 11 Feb 2026, finished
- "Ladakh Ride" — Leh, India, 31 Aug 2026 to 6 Sep 2026, finished
- "Bali Bros" — Bali, Indonesia, 10 Jan 2027 to 13 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 27 Sep 2026 to 30 Sep 2026, under way now
Question: Flight kitne baje hai

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 17 Jul 2026 to 25 Jul 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Bali Bros" — Bali, Indonesia, 7 Feb 2027 to 13 Feb 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 28 Mar 2027 to 2 Apr 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 18 Jan 2026 to 23 Jan 2026, finished
Being discussed: "Coorg Coffee Trail"
Question: abhi wali trip mein hum kahan ruk rahe hain?

### Response
{"topic":"bookings","trip":"current","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 31 Aug 2025 to 8 Sep 2025, finished
- "Bali Bros" — Bali, Indonesia, 12 Aug 2026 to 15 Aug 2026, finished
- "Pondy Chill" — Puducherry, India, 8 Aug 2026 to 12 Aug 2026, finished
- "Jaipur Weekend" — Jaipur, India, 9 Jan 2027 to 13 Jan 2027, upcoming
- "Paris Escape" — Paris, France, 3 Mar 2027 to 12 Mar 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 5 Feb 2026 to 14 Feb 2026, finished
Question: kisi se settle karna baaki hai kya

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 21 Nov 2025 to 27 Nov 2025, finished
- "Rome in Spring" — Rome, Italy, 26 Oct 2025 to 31 Oct 2025, finished
- "Udaipur Wedding" — Udaipur, India, 23 Feb 2027 to 4 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 7 Mar 2027 to 15 Mar 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 30 Jun 2026 to 6 Jul 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 8 Apr 2027 to 10 Apr 2027, upcoming
Question: what trips do I have coming up?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 11 Oct 2026 to 17 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 6 Nov 2025 to 15 Nov 2025, finished
- "Udaipur Wedding" — Udaipur, India, 17 Dec 2026 to 19 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 12 Mar 2026 to 16 Mar 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 20 Nov 2025 to 28 Nov 2025, finished
- "Singapore Stopover" — Singapore, 6 Jan 2026 to 14 Jan 2026, finished
Question: have we booked a way to get there?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 24 Sep 2026 to 2 Oct 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 1 Sep 2025 to 6 Sep 2025, finished
- "Manali Snow Run" — Manali, India, 27 Dec 2026 to 29 Dec 2026, upcoming
Being discussed: "Coorg Coffee Trail"
Question: thanks!

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 11 Jul 2026 to 20 Jul 2026, finished
- "Kerala Backwaters" — Alleppey, India, 19 Jan 2026 to 28 Jan 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 27 Dec 2026 to 2 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 26 Sep 2026 to 2 Oct 2026, under way now
Previous question: hisaab kitna baaki hai?
Question: and for Coorg Coffee Trail

### Response
{"topic":"balance","trip":"named","tripTitle":"Coorg Coffee Trail","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 27 Sep 2026 to 6 Oct 2026, under way now
- "Manali Snow Run" — Manali, India, 27 Jul 2026 to 4 Aug 2026, finished
- "Thailand Trip" — Phuket, Thailand, 20 Nov 2026 to 27 Nov 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 10 Feb 2027 to 13 Feb 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 16 Nov 2026 to 19 Nov 2026, upcoming
- "Pondy Chill" — Puducherry, India, 27 Apr 2026 to 30 Apr 2026, finished
Being discussed: "Udaipur Wedding"
Question: How much do I owe Tanvi?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Tanvi","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 5 Jan 2027 to 14 Jan 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 8 Feb 2027 to 17 Feb 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 27 Sep 2026 to 29 Sep 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 1 Sep 2026 to 4 Sep 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 1 Jul 2026 to 6 Jul 2026, finished
Being discussed: "Meghalaya Monsoon"
Question: what's next on the trip?

### Response
{"topic":"schedule","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 8 Dec 2025 to 17 Dec 2025, finished
- "Jaipur Weekend" — Jaipur, India, 20 Aug 2026 to 26 Aug 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 4 Dec 2026 to 9 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 14 Feb 2026 to 17 Feb 2026, finished
- "Paris Escape" — Paris, France, 27 Sep 2026 to 3 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 21 Nov 2026 to 26 Nov 2026, upcoming
Being discussed: "Paris Escape"
Question: kal ka plan kya hai Rome in Spring wali trip mein

### Response
{"topic":"schedule","trip":"named","tripTitle":"Rome in Spring","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 26 Sep 2026 to 30 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 4 Nov 2026 to 11 Nov 2026, upcoming
- "Goa Getaway" — Goa, India, 29 Dec 2025 to 31 Dec 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 2 May 2026 to 10 May 2026, finished
- "Kerala Backwaters" — Alleppey, India, 24 Jan 2027 to 1 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 4 Jul 2026 to 12 Jul 2026, finished
Being discussed: "Bali Bros"
Previous question: who paid for the villa?
Question: what about tomorrow?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 26 Sep 2026 to 30 Sep 2026, under way now
- "Manali Snow Run" — Manali, India, 27 Oct 2026 to 4 Nov 2026, upcoming
- "Ladakh Ride" — Leh, India, 26 May 2026 to 30 May 2026, finished
- "Rome in Spring" — Rome, Italy, 25 Dec 2026 to 28 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 14 Aug 2026 to 18 Aug 2026, finished
- "Hampi Heritage" — Hampi, India, 16 Dec 2026 to 20 Dec 2026, upcoming
Question: who owes whom on Kerala Backwaters?

### Response
{"topic":"balance","trip":"named","tripTitle":"Kerala Backwaters","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 9 Apr 2027 to 17 Apr 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 29 Oct 2025 to 5 Nov 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 11 Aug 2026 to 18 Aug 2026, finished
Question: when does the train leave?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 14 Jan 2027 to 23 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 15 Jul 2026 to 23 Jul 2026, finished
- "Thailand Trip" — Phuket, Thailand, 1 Aug 2026 to 5 Aug 2026, finished
- "Goa Getaway" — Goa, India, 1 Sep 2025 to 4 Sep 2025, finished
- "Manali Snow Run" — Manali, India, 19 Feb 2027 to 25 Feb 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 30 Dec 2026 to 6 Jan 2027, upcoming
Question: total cab spend on my last trip?

### Response
{"topic":"spending","trip":"previous","tripTitle":"","category":"transfer","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 25 Sep 2026 to 30 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 19 Dec 2026 to 22 Dec 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 9 Nov 2025 to 11 Nov 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 8 Oct 2026 to 11 Oct 2026, upcoming
Question: pichli trip ke liye kya pack karu?

### Response
{"topic":"advice","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 18 Mar 2026 to 20 Mar 2026, finished
- "Singapore Stopover" — Singapore, 22 Nov 2025 to 25 Nov 2025, finished
- "Goa Getaway" — Goa, India, 24 Sep 2026 to 1 Oct 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 8 Aug 2026 to 10 Aug 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 14 Oct 2025 to 20 Oct 2025, finished
Being discussed: "Goa Getaway"
Question: kaunsi flights book hain Rome in Spring ke liye

### Response
{"topic":"bookings","trip":"named","tripTitle":"Rome in Spring","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 6 Jan 2027 to 10 Jan 2027, upcoming
- "Goa Getaway" — Goa, India, 8 Aug 2026 to 11 Aug 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 28 Aug 2026 to 6 Sep 2026, finished
- "Bali Bros" — Bali, Indonesia, 28 Nov 2026 to 30 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 5 Oct 2026 to 7 Oct 2026, upcoming
- "Ladakh Ride" — Leh, India, 15 Mar 2026 to 20 Mar 2026, finished
Question: what time is hotel check-in tomorrow?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 8 Apr 2027 to 15 Apr 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 25 Sep 2026 to 27 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 5 Jan 2027 to 9 Jan 2027, upcoming
Question: kaunsi flights book hain Pondicherry wali trip ke liye

### Response
{"topic":"bookings","trip":"named","tripTitle":"Pondy Chill","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 27 Sep 2026 to 5 Oct 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 25 Dec 2026 to 30 Dec 2026, upcoming
- "Singapore Stopover" — Singapore, 11 Oct 2026 to 19 Oct 2026, upcoming
- "Goa Getaway" — Goa, India, 1 Nov 2026 to 6 Nov 2026, upcoming
Being discussed: "Udaipur Wedding"
Question: who paid for dinner last night?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 3 Dec 2026 to 7 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 2 Sep 2025 to 4 Sep 2025, finished
- "Pondy Chill" — Puducherry, India, 29 Jan 2027 to 2 Feb 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 3 Feb 2027 to 10 Feb 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 25 Mar 2027 to 27 Mar 2027, upcoming
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 29 Sep 2026, under way now
Question: airport pickup book hai kya?

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 23 Jan 2027 to 28 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 25 Sep 2026 to 1 Oct 2026, under way now
- "Manali Snow Run" — Manali, India, 7 Mar 2026 to 10 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 8 Apr 2027 to 13 Apr 2027, upcoming
Question: what are we doing today?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 21 Jun 2026 to 23 Jun 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 25 Sep 2026 to 3 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 17 Oct 2026 to 22 Oct 2026, upcoming
Question: Ananya se kitna lena hai

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Ananya","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 29 Oct 2026 to 6 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 11 Feb 2026 to 20 Feb 2026, finished
- "Bali Bros" — Bali, Indonesia, 27 Dec 2026 to 29 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 1 Apr 2027 to 5 Apr 2027, upcoming
- "Goa Getaway" — Goa, India, 25 Dec 2026 to 28 Dec 2026, upcoming
Question: last wali trip mein total kitna kharcha hua?

### Response
{"topic":"spending","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 2 Jun 2026 to 11 Jun 2026, finished
- "Paris Escape" — Paris, France, 12 Feb 2027 to 19 Feb 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 26 Sep 2026 to 2 Oct 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 27 Dec 2025 to 3 Jan 2026, finished
Question: theek hai, thanks

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 30 Aug 2025 to 7 Sep 2025, finished
- "Ladakh Ride" — Leh, India, 10 May 2026 to 13 May 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 16 Feb 2027 to 23 Feb 2027, upcoming
Question: Kerala Backwaters kab hai?

### Response
{"topic":"overview","trip":"named","tripTitle":"Kerala Backwaters","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 19 Nov 2026 to 26 Nov 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 26 Sep 2026 to 30 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 26 Feb 2026 to 3 Mar 2026, finished
- "Paris Escape" — Paris, France, 12 Aug 2026 to 19 Aug 2026, finished
- "Thailand Trip" — Phuket, Thailand, 4 Oct 2025 to 7 Oct 2025, finished
Being discussed: "Kerala Backwaters"
Question: is trip mein next kya hai?

### Response
{"topic":"schedule","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 27 Oct 2026 to 1 Nov 2026, upcoming
- "Rome in Spring" — Rome, Italy, 26 Nov 2026 to 3 Dec 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 24 Sep 2026 to 1 Oct 2026, under way now
- "Pondy Chill" — Puducherry, India, 15 Mar 2027 to 23 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 22 Aug 2026 to 29 Aug 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 12 Dec 2026 to 19 Dec 2026, upcoming
Question: aaj check-in kitne baje hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 2 Oct 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 6 Apr 2027 to 13 Apr 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 17 Jan 2026 to 20 Jan 2026, finished
Being discussed: "Udaipur Wedding"
Question: what's the damage on dinners?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 2 Dec 2026 to 9 Dec 2026, upcoming
- "Manali Snow Run" — Manali, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Singapore Stopover" — Singapore, 1 Jan 2027 to 5 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 1 Apr 2027 to 4 Apr 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 20 Feb 2027 to 23 Feb 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 23 Aug 2026 to 31 Aug 2026, finished
Question: how many trips have i taken?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 27 Apr 2026 to 1 May 2026, finished
- "Manali Snow Run" — Manali, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 16 Nov 2026 to 22 Nov 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 2 Sep 2026 to 4 Sep 2026, finished
- "Paris Escape" — Paris, France, 14 Oct 2026 to 21 Oct 2026, upcoming
Being discussed: "Manali Snow Run"
Question: namaste Equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 9 Feb 2027 to 14 Feb 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 14 Dec 2025 to 20 Dec 2025, finished
- "Hampi Heritage" — Hampi, India, 4 Dec 2026 to 7 Dec 2026, upcoming
Question: Thailand trip ka summary batao

### Response
{"topic":"overview","trip":"named","tripTitle":"Thailand Trip","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 22 Dec 2026 to 28 Dec 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 15 Feb 2027 to 19 Feb 2027, upcoming
- "Goa Getaway" — Goa, India, 16 Apr 2026 to 20 Apr 2026, finished
Question: Kisi raat hotel nahi hai kya?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 1 Feb 2027 to 10 Feb 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 25 Sep 2026 to 3 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 14 Oct 2026 to 18 Oct 2026, upcoming
Question: do we have free days on the next trip?

### Response
{"topic":"gaps","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 10 Feb 2027 to 13 Feb 2027, upcoming
- "Goa Getaway" — Goa, India, 24 Sep 2026 to 1 Oct 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 18 Aug 2026 to 20 Aug 2026, finished
- "Singapore Stopover" — Singapore, 12 Dec 2026 to 20 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 4 Mar 2027 to 12 Mar 2027, upcoming
Question: theek hai, thanks

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 14 Jan 2026 to 21 Jan 2026, finished
- "Singapore Stopover" — Singapore, 30 Nov 2025 to 3 Dec 2025, finished
- "Bali Bros" — Bali, Indonesia, 28 Oct 2025 to 5 Nov 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 22 Apr 2026 to 1 May 2026, finished
Question: how many of us are going on the Bali Bros trip?

### Response
{"topic":"people","trip":"named","tripTitle":"Bali Bros","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 15 Apr 2027 to 18 Apr 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 14 Apr 2027 to 23 Apr 2027, upcoming
- "Rome in Spring" — Rome, Italy, 3 Dec 2026 to 5 Dec 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 7 Jun 2026 to 16 Jun 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 10 Feb 2026 to 15 Feb 2026, finished
Question: Udaipur Wedding kab hai?

### Response
{"topic":"overview","trip":"named","tripTitle":"Udaipur Wedding","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 24 Sep 2026 to 3 Oct 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 10 May 2026 to 18 May 2026, finished
- "Paris Escape" — Paris, France, 4 Nov 2026 to 13 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 4 Mar 2026 to 13 Mar 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 24 Dec 2026 to 30 Dec 2026, upcoming
Being discussed: "Dubai Long Weekend"
Question: show my past trips

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 2 Aug 2026 to 11 Aug 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 2 Nov 2025 to 4 Nov 2025, finished
- "Bali Bros" — Bali, Indonesia, 3 Feb 2027 to 9 Feb 2027, upcoming
- "Manali Snow Run" — Manali, India, 28 Oct 2026 to 5 Nov 2026, upcoming
Question: anything planned for dinner tomorrow?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 25 Aug 2026 to 31 Aug 2026, finished
- "Thailand Trip" — Phuket, Thailand, 26 Mar 2026 to 1 Apr 2026, finished
- "Kerala Backwaters" — Alleppey, India, 10 Dec 2025 to 19 Dec 2025, finished
Question: kerala mein mausam kaisa hoga

### Response
{"topic":"advice","trip":"named","tripTitle":"Kerala Backwaters","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 3 Jan 2026 to 5 Jan 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 26 Jul 2026 to 4 Aug 2026, finished
- "Kerala Backwaters" — Alleppey, India, 28 Mar 2027 to 3 Apr 2027, upcoming
- "Ladakh Ride" — Leh, India, 18 Jan 2027 to 25 Jan 2027, upcoming
Previous question: is anything not booked yet for my next trip?
Question: and for the previous trip?

### Response
{"topic":"gaps","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 23 Dec 2026 to 29 Dec 2026, upcoming
- "Rome in Spring" — Rome, Italy, 24 Sep 2026 to 26 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 9 Oct 2026 to 13 Oct 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 29 Aug 2025 to 2 Sep 2025, finished
- "Manali Snow Run" — Manali, India, 4 Jun 2026 to 10 Jun 2026, finished
- "Paris Escape" — Paris, France, 17 Jan 2027 to 24 Jan 2027, upcoming
Question: Khane pe kitna gaya?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 27 Jun 2026 to 3 Jul 2026, finished
- "Bali Bros" — Bali, Indonesia, 17 Jun 2026 to 20 Jun 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 12 Dec 2026 to 19 Dec 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 28 Dec 2026 to 2 Jan 2027, upcoming
Question: Bali wali trip mein kuch book karna baaki hai

### Response
{"topic":"gaps","trip":"named","tripTitle":"Bali Bros","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 25 Sep 2026 to 27 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 10 Jun 2026 to 14 Jun 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 8 Nov 2026 to 12 Nov 2026, upcoming
- "Paris Escape" — Paris, France, 23 Dec 2025 to 29 Dec 2025, finished
Question: compare my trips by spend

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 25 Feb 2027 to 27 Feb 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 25 Sep 2026 to 2 Oct 2026, under way now
- "Manali Snow Run" — Manali, India, 23 Jan 2027 to 25 Jan 2027, upcoming
- "Paris Escape" — Paris, France, 19 Dec 2026 to 26 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 3 Dec 2026 to 8 Dec 2026, upcoming
Question: tell me about the next trip

### Response
{"topic":"overview","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 5 Jan 2027 to 10 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 6 Dec 2026 to 14 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 9 Apr 2026 to 17 Apr 2026, finished
- "Goa Getaway" — Goa, India, 5 Jan 2026 to 11 Jan 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 24 Apr 2026 to 27 Apr 2026, finished
Question: Is trip kitne din ki hai?

### Response
{"topic":"overview","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 25 Jan 2026 to 1 Feb 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 27 Sep 2026 to 30 Sep 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 15 Oct 2026 to 23 Oct 2026, upcoming
- "Manali Snow Run" — Manali, India, 13 Jun 2026 to 16 Jun 2026, finished
- "Paris Escape" — Paris, France, 22 May 2026 to 25 May 2026, finished
- "Hampi Heritage" — Hampi, India, 14 Jul 2026 to 20 Jul 2026, finished
Being discussed: "Tokyo 2026"
Question: aaj kitna kharcha ho gaya?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 24 Jan 2027 to 29 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 2 Sep 2026 to 10 Sep 2026, finished
- "Udaipur Wedding" — Udaipur, India, 25 Sep 2026 to 30 Sep 2026, under way now
Being discussed: "Udaipur Wedding"
Question: khane pe kitna gaya?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 10 Nov 2026 to 12 Nov 2026, upcoming
- "Goa Getaway" — Goa, India, 25 May 2026 to 28 May 2026, finished
- "Singapore Stopover" — Singapore, 27 Oct 2026 to 31 Oct 2026, upcoming
Question: priya ko kitna dena hai?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Priya","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 21 Feb 2027 to 2 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 11 Apr 2027 to 17 Apr 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 27 Sep 2026 to 6 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 6 Apr 2027 to 9 Apr 2027, upcoming
Being discussed: "Dubai Long Weekend"
Question: omar ka udhaar kitna hai?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Omar","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 16 Mar 2027 to 25 Mar 2027, upcoming
- "Singapore Stopover" — Singapore, 7 Jan 2027 to 12 Jan 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 8 Dec 2026 to 11 Dec 2026, upcoming
- "Hampi Heritage" — Hampi, India, 13 Jun 2026 to 18 Jun 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 26 Sep 2026 to 3 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 11 Oct 2025 to 19 Oct 2025, finished
Being discussed: "Dubai Long Weekend"
Question: kisi se settle karna baaki hai kya?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 27 Apr 2026 to 3 May 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 28 Dec 2025 to 2 Jan 2026, finished
- "Goa Getaway" — Goa, India, 3 Feb 2027 to 7 Feb 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 9 Jan 2026 to 12 Jan 2026, finished
Question: compare my trips by spend

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 13 Sep 2025 to 21 Sep 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 5 Mar 2027 to 11 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 31 Mar 2026 to 7 Apr 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 13 Oct 2025 to 21 Oct 2025, finished
Question: how much did we spend on Paris Escape

### Response
{"topic":"spending","trip":"named","tripTitle":"Paris Escape","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 6 Apr 2027 to 9 Apr 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 15 Oct 2025 to 24 Oct 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 10 Jan 2027 to 14 Jan 2027, upcoming
- "Paris Escape" — Paris, France, 11 Jul 2026 to 13 Jul 2026, finished
- "Jaipur Weekend" — Jaipur, India, 4 Jul 2026 to 11 Jul 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 25 Sep 2026 to 28 Sep 2026, under way now
Being discussed: "Dubai Long Weekend"
Question: which flights are booked for the Jaipur trip?

### Response
{"topic":"bookings","trip":"named","tripTitle":"Jaipur Weekend","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 8 Nov 2026 to 15 Nov 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 26 Sep 2026 to 30 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 1 Dec 2026 to 9 Dec 2026, upcoming
- "Ladakh Ride" — Leh, India, 3 Aug 2026 to 9 Aug 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 7 Jan 2027 to 13 Jan 2027, upcoming
Being discussed: "Bali Bros"
Question: agli trip mein kuch book karna baaki hai

### Response
{"topic":"gaps","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 31 Oct 2026 to 3 Nov 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 5 Nov 2026 to 11 Nov 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 2 Mar 2026 to 10 Mar 2026, finished
Question: where did all the money go?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 6 Dec 2026 to 13 Dec 2026, upcoming
- "Goa Getaway" — Goa, India, 26 Sep 2026 to 4 Oct 2026, under way now
- "Pondy Chill" — Puducherry, India, 30 Jun 2026 to 5 Jul 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 18 Mar 2026 to 23 Mar 2026, finished
- "Bali Bros" — Bali, Indonesia, 26 Dec 2026 to 29 Dec 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 26 Nov 2026 to 2 Dec 2026, upcoming
Question: what did the flights come to?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 26 Sep 2026 to 4 Oct 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 14 Nov 2026 to 16 Nov 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 26 Jun 2026 to 30 Jun 2026, finished
- "Udaipur Wedding" — Udaipur, India, 20 Aug 2026 to 24 Aug 2026, finished
- "Bali Bros" — Bali, Indonesia, 8 Mar 2027 to 17 Mar 2027, upcoming
Question: Sabse mehengi trip kaunsi thi?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 25 Sep 2026 to 4 Oct 2026, under way now
- "Pondy Chill" — Puducherry, India, 9 Nov 2025 to 13 Nov 2025, finished
- "Singapore Stopover" — Singapore, 18 Oct 2026 to 20 Oct 2026, upcoming
Question: kal subah sabse pehle kya hai

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 1 Apr 2026 to 3 Apr 2026, finished
- "Singapore Stopover" — Singapore, 19 Oct 2026 to 28 Oct 2026, upcoming
- "Ladakh Ride" — Leh, India, 13 Mar 2026 to 17 Mar 2026, finished
- "Pondy Chill" — Puducherry, India, 9 Oct 2026 to 17 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 24 Sep 2026 to 29 Sep 2026, under way now
Question: Kisi raat hotel nahi hai kya

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 13 Oct 2026 to 18 Oct 2026, upcoming
- "Rome in Spring" — Rome, Italy, 19 May 2026 to 27 May 2026, finished
- "Ladakh Ride" — Leh, India, 10 Apr 2026 to 15 Apr 2026, finished
- "Jaipur Weekend" — Jaipur, India, 1 Jan 2026 to 9 Jan 2026, finished
- "Manali Snow Run" — Manali, India, 2 Jun 2026 to 4 Jun 2026, finished
Question: how much has Sam paid so far?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"Sam","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 17 Feb 2027 to 26 Feb 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 23 Jun 2026 to 30 Jun 2026, finished
- "Singapore Stopover" — Singapore, 20 Apr 2026 to 23 Apr 2026, finished
- "Udaipur Wedding" — Udaipur, India, 23 Jun 2026 to 29 Jun 2026, finished
Question: what's my balance on udaipur wedding?

### Response
{"topic":"balance","trip":"named","tripTitle":"Udaipur Wedding","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 3 Mar 2026 to 10 Mar 2026, finished
- "Udaipur Wedding" — Udaipur, India, 11 Oct 2026 to 18 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 24 Jan 2026 to 29 Jan 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 8 Dec 2026 to 10 Dec 2026, upcoming
- "Hampi Heritage" — Hampi, India, 28 Jun 2026 to 4 Jul 2026, finished
Question: what trips do I have coming up?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 19 Oct 2026 to 26 Oct 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 15 Oct 2025 to 22 Oct 2025, finished
- "Rome in Spring" — Rome, Italy, 7 Jul 2026 to 16 Jul 2026, finished
- "Singapore Stopover" — Singapore, 1 Apr 2026 to 4 Apr 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 14 Jan 2027 to 21 Jan 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 27 Sep 2026 to 30 Sep 2026, under way now
Being discussed: "Dubai Long Weekend"
Question: Arjun ko kitna dena hai?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Arjun","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 23 Aug 2025 to 28 Aug 2025, finished
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Ladakh Ride" — Leh, India, 11 Mar 2027 to 15 Mar 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 23 Dec 2026 to 1 Jan 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 21 Oct 2025 to 28 Oct 2025, finished
Question: thank you Equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 17 Mar 2027 to 20 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 3 Jan 2027 to 12 Jan 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 17 Oct 2026 to 23 Oct 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 24 Sep 2026 to 30 Sep 2026, under way now
- "Rome in Spring" — Rome, Italy, 24 Sep 2025 to 3 Oct 2025, finished
- "Jaipur Weekend" — Jaipur, India, 31 Mar 2027 to 7 Apr 2027, upcoming
Being discussed: "Tokyo 2026"
Question: what's my balance across all trips?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 4 Mar 2027 to 11 Mar 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 3 Oct 2025 to 8 Oct 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 8 Oct 2026 to 14 Oct 2026, upcoming
- "Rome in Spring" — Rome, Italy, 14 Nov 2026 to 19 Nov 2026, upcoming
- "Pondy Chill" — Puducherry, India, 24 Sep 2026 to 29 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 11 Sep 2025 to 18 Sep 2025, finished
Being discussed: "Pondy Chill"
Question: last wali trip mein next kya hai?

### Response
{"topic":"schedule","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 27 Feb 2027 to 8 Mar 2027, upcoming
- "Hampi Heritage" — Hampi, India, 28 Dec 2026 to 5 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 2 Apr 2027 to 9 Apr 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 27 Jan 2027 to 31 Jan 2027, upcoming
Previous question: is the airport pickup booked?
Question: same for sam?

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"transfer","person":"Sam","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 20 Jun 2026 to 25 Jun 2026, finished
- "Rome in Spring" — Rome, Italy, 28 Mar 2026 to 31 Mar 2026, finished
- "Jaipur Weekend" — Jaipur, India, 2 Feb 2027 to 10 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 29 Mar 2027 to 6 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 13 Mar 2027 to 15 Mar 2027, upcoming
Being discussed: "Udaipur Wedding"
Question: Dev ne ab tak kitna pay kiya?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"Dev","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 3 Mar 2027 to 8 Mar 2027, upcoming
- "Hampi Heritage" — Hampi, India, 21 Oct 2025 to 28 Oct 2025, finished
- "Kerala Backwaters" — Alleppey, India, 20 Jul 2026 to 23 Jul 2026, finished
Question: Hampi wali trip mein kaun kaun aa raha hai?

### Response
{"topic":"people","trip":"named","tripTitle":"Hampi Heritage","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 18 Nov 2026 to 23 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 16 Apr 2026 to 23 Apr 2026, finished
- "Paris Escape" — Paris, France, 22 Oct 2026 to 26 Oct 2026, upcoming
Question: how many days is manali snow run?

### Response
{"topic":"overview","trip":"named","tripTitle":"Manali Snow Run","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 24 Sep 2026 to 28 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 3 Nov 2026 to 10 Nov 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 7 Nov 2026 to 12 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 4 Feb 2027 to 9 Feb 2027, upcoming
- "Singapore Stopover" — Singapore, 27 Jul 2026 to 31 Jul 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 7 Nov 2025 to 15 Nov 2025, finished
Question: sabse mehengi trip kaunsi thi?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 16 Oct 2025 to 24 Oct 2025, finished
- "Hampi Heritage" — Hampi, India, 22 Jan 2027 to 24 Jan 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 27 Jan 2027 to 4 Feb 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 30 Oct 2026 to 1 Nov 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 29 May 2026 to 4 Jun 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 24 Sep 2026 to 2 Oct 2026, under way now
Previous question: is the airport pickup booked?
Question: Same for Leela?

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"transfer","person":"Leela","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 20 Feb 2026 to 24 Feb 2026, finished
- "Pondy Chill" — Puducherry, India, 22 Nov 2026 to 30 Nov 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 29 Jan 2027 to 4 Feb 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 23 Nov 2026 to 2 Dec 2026, upcoming
- "Rome in Spring" — Rome, Italy, 2 Oct 2025 to 10 Oct 2025, finished
Question: how many days is Dubai Long Weekend?

### Response
{"topic":"overview","trip":"named","tripTitle":"Dubai Long Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 13 Mar 2027 to 21 Mar 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 17 Jan 2026 to 25 Jan 2026, finished
- "Jaipur Weekend" — Jaipur, India, 1 Dec 2026 to 10 Dec 2026, upcoming
Question: how much do I get back from the Ladakh trip?

### Response
{"topic":"balance","trip":"named","tripTitle":"Ladakh Ride","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 31 May 2026 to 7 Jun 2026, finished
- "Udaipur Wedding" — Udaipur, India, 28 Dec 2025 to 30 Dec 2025, finished
- "Thailand Trip" — Phuket, Thailand, 22 Nov 2026 to 29 Nov 2026, upcoming
- "Manali Snow Run" — Manali, India, 9 Jan 2027 to 14 Jan 2027, upcoming
Question: quick summary of my next trip

### Response
{"topic":"overview","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 4 Dec 2026 to 6 Dec 2026, upcoming
- "Manali Snow Run" — Manali, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 7 Feb 2027 to 15 Feb 2027, upcoming
- "Ladakh Ride" — Leh, India, 5 Nov 2026 to 8 Nov 2026, upcoming
Being discussed: "Manali Snow Run"
Question: am i over budget on manali snow run?

### Response
{"topic":"spending","trip":"named","tripTitle":"Manali Snow Run","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 20 Aug 2026 to 28 Aug 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 26 Jan 2026 to 3 Feb 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 29 Jan 2027 to 5 Feb 2027, upcoming
- "Singapore Stopover" — Singapore, 17 Sep 2025 to 24 Sep 2025, finished
- "Jaipur Weekend" — Jaipur, India, 27 Sep 2026 to 5 Oct 2026, under way now
Being discussed: "Jaipur Weekend"
Question: aaj kya plan hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 24 Jun 2026 to 2 Jul 2026, finished
- "Bali Bros" — Bali, Indonesia, 1 Sep 2025 to 7 Sep 2025, finished
- "Singapore Stopover" — Singapore, 25 Dec 2026 to 30 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 4 Dec 2025 to 13 Dec 2025, finished
- "Kerala Backwaters" — Alleppey, India, 25 Sep 2026 to 29 Sep 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 18 Nov 2025 to 20 Nov 2025, finished
Question: Is istanbul safe at night?

### Response
{"topic":"advice","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 23 Sep 2025 to 26 Sep 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 15 Oct 2025 to 18 Oct 2025, finished
- "Hampi Heritage" — Hampi, India, 11 Mar 2026 to 20 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 27 Feb 2026 to 1 Mar 2026, finished
Question: Ananya ko kitna dena hai

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Ananya","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 2 Jul 2026 to 7 Jul 2026, finished
- "Ladakh Ride" — Leh, India, 23 Oct 2025 to 31 Oct 2025, finished
- "Singapore Stopover" — Singapore, 11 Oct 2026 to 20 Oct 2026, upcoming
Question: how much have we spent today?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 25 Sep 2026 to 27 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 10 Oct 2025 to 16 Oct 2025, finished
- "Kerala Backwaters" — Alleppey, India, 16 Nov 2026 to 21 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 5 Apr 2027 to 14 Apr 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 27 Jan 2027 to 4 Feb 2027, upcoming
Being discussed: "Meghalaya Monsoon"
Question: meri saari trips dikhao

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 6 Mar 2027 to 10 Mar 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 20 Jan 2027 to 27 Jan 2027, upcoming
- "Goa Getaway" — Goa, India, 6 Oct 2026 to 13 Oct 2026, upcoming
- "Hampi Heritage" — Hampi, India, 10 Nov 2025 to 17 Nov 2025, finished
Question: kal subah sabse pehle kya hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 6 May 2026 to 11 May 2026, finished
- "Rome in Spring" — Rome, Italy, 26 Aug 2026 to 4 Sep 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 17 Jul 2026 to 25 Jul 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 5 Dec 2026 to 11 Dec 2026, upcoming
- "Manali Snow Run" — Manali, India, 15 Nov 2026 to 23 Nov 2026, upcoming
- "Goa Getaway" — Goa, India, 9 Oct 2026 to 14 Oct 2026, upcoming
Question: who paid for dinner last night?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 26 Sep 2026 to 5 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 12 Apr 2027 to 15 Apr 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 30 Jan 2027 to 4 Feb 2027, upcoming
Question: which hotel did we book for our Rishikesh trip?

### Response
{"topic":"bookings","trip":"named","tripTitle":"Rishikesh Rafting","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 13 Feb 2026 to 16 Feb 2026, finished
- "Manali Snow Run" — Manali, India, 2 Sep 2025 to 9 Sep 2025, finished
- "Ladakh Ride" — Leh, India, 24 Sep 2026 to 27 Sep 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 22 Mar 2026 to 29 Mar 2026, finished
Question: Kitni trips ho gayi ab tak?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 5 Mar 2027 to 12 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 12 Apr 2027 to 15 Apr 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 30 Mar 2027 to 6 Apr 2027, upcoming
Question: kitni trips ho gayi ab tak

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 4 Apr 2027 to 12 Apr 2027, upcoming
- "Singapore Stopover" — Singapore, 24 Sep 2026 to 1 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 3 Mar 2027 to 12 Mar 2027, upcoming
- "Rome in Spring" — Rome, Italy, 18 Jan 2026 to 21 Jan 2026, finished
Being discussed: "Singapore Stopover"
Question: kal subah sabse pehle kya hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 24 Feb 2027 to 27 Feb 2027, upcoming
- "Paris Escape" — Paris, France, 15 Mar 2027 to 23 Mar 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 27 Sep 2026 to 4 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 9 Mar 2027 to 14 Mar 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 27 Dec 2026 to 4 Jan 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 19 Feb 2027 to 23 Feb 2027, upcoming
Previous question: kya kya activities hain is trip mein?
Question: and the other one?

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 13 Jul 2026 to 19 Jul 2026, finished
- "Manali Snow Run" — Manali, India, 4 Apr 2026 to 8 Apr 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 25 Sep 2025 to 3 Oct 2025, finished
Previous question: what's first thing tomorrow morning
Question: and for our trip?

### Response
{"topic":"schedule","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 22 Dec 2026 to 31 Dec 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 6 Dec 2026 to 14 Dec 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 5 Nov 2025 to 14 Nov 2025, finished
Being discussed: "Coorg Coffee Trail"
Question: What was the most expensive thing on our last trip

### Response
{"topic":"spending","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 24 Sep 2026 to 1 Oct 2026, under way now
- "Pondy Chill" — Puducherry, India, 15 Oct 2026 to 24 Oct 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 18 Nov 2026 to 21 Nov 2026, upcoming
- "Manali Snow Run" — Manali, India, 7 Jun 2026 to 14 Jun 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 19 Oct 2026 to 24 Oct 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 9 Mar 2027 to 11 Mar 2027, upcoming
Question: Kitni trips ho gayi ab tak?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 4 Nov 2025 to 11 Nov 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 1 Apr 2027 to 3 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 10 Jul 2026 to 13 Jul 2026, finished
Question: what did the flights come to?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 22 Feb 2027 to 28 Feb 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 20 Dec 2026 to 22 Dec 2026, upcoming
- "Singapore Stopover" — Singapore, 23 Mar 2026 to 30 Mar 2026, finished
- "Ladakh Ride" — Leh, India, 9 Feb 2027 to 17 Feb 2027, upcoming
Question: which hotel did we book for our singapore trip

### Response
{"topic":"bookings","trip":"named","tripTitle":"Singapore Stopover","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 24 Sep 2026 to 27 Sep 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 24 Jul 2026 to 27 Jul 2026, finished
- "Bali Bros" — Bali, Indonesia, 21 Oct 2025 to 24 Oct 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 2 Nov 2026 to 9 Nov 2026, upcoming
- "Goa Getaway" — Goa, India, 17 Jan 2027 to 20 Jan 2027, upcoming
Being discussed: "Tokyo 2026"
Question: what did the flights come to

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 16 Oct 2026 to 19 Oct 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 4 Feb 2026 to 11 Feb 2026, finished
- "Goa Getaway" — Goa, India, 26 Sep 2026 to 3 Oct 2026, under way now
Being discussed: "Goa Getaway"
Question: how is Coorg Coffee Trail going?

### Response
{"topic":"overview","trip":"named","tripTitle":"Coorg Coffee Trail","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 28 Mar 2027 to 5 Apr 2027, upcoming
- "Manali Snow Run" — Manali, India, 8 May 2026 to 15 May 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 15 Feb 2027 to 20 Feb 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 1 Nov 2026 to 3 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 22 Dec 2026 to 29 Dec 2026, upcoming
Question: Kya kya activities hain pichli trip mein?

### Response
{"topic":"bookings","trip":"previous","tripTitle":"","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 27 Sep 2026 to 4 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 30 Dec 2025 to 2 Jan 2026, finished
- "Rome in Spring" — Rome, Italy, 19 Mar 2027 to 25 Mar 2027, upcoming
Question: when does the train leave?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 9 Sep 2025 to 13 Sep 2025, finished
- "Manali Snow Run" — Manali, India, 31 Jan 2026 to 7 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 5 Feb 2026 to 13 Feb 2026, finished
- "Bali Bros" — Bali, Indonesia, 15 Mar 2026 to 19 Mar 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 27 Sep 2026 to 29 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 10 Apr 2026 to 15 Apr 2026, finished
Being discussed: "Rishikesh Rafting"
Question: does Kim owe me anything?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Kim","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 22 Nov 2025 to 27 Nov 2025, finished
- "Thailand Trip" — Phuket, Thailand, 10 Feb 2027 to 14 Feb 2027, upcoming
- "Ladakh Ride" — Leh, India, 18 Feb 2027 to 25 Feb 2027, upcoming
Question: ladakh ride wali trip mein next kya hai?

### Response
{"topic":"schedule","trip":"named","tripTitle":"Ladakh Ride","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 25 Jan 2027 to 27 Jan 2027, upcoming
- "Goa Getaway" — Goa, India, 20 May 2026 to 26 May 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 21 Mar 2027 to 24 Mar 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 7 Jan 2026 to 11 Jan 2026, finished
- "Bali Bros" — Bali, Indonesia, 4 Oct 2026 to 7 Oct 2026, upcoming
- "Ladakh Ride" — Leh, India, 30 Jul 2026 to 1 Aug 2026, finished
Question: goa mein mausam kaisa hoga?

### Response
{"topic":"advice","trip":"named","tripTitle":"Goa Getaway","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 18 Feb 2026 to 21 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 20 Oct 2026 to 28 Oct 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 12 Sep 2025 to 21 Sep 2025, finished
- "Jaipur Weekend" — Jaipur, India, 19 Sep 2025 to 21 Sep 2025, finished
Question: What's the weather like in Rishikesh this time of year?

### Response
{"topic":"advice","trip":"named","tripTitle":"Rishikesh Rafting","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 24 Sep 2026 to 28 Sep 2026, under way now
- "Rome in Spring" — Rome, Italy, 26 Jun 2026 to 4 Jul 2026, finished
- "Singapore Stopover" — Singapore, 19 Dec 2026 to 24 Dec 2026, upcoming
Question: pichli trip mein total kitna kharcha hua?

### Response
{"topic":"spending","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 3 Oct 2026, under way now
- "Paris Escape" — Paris, France, 14 Apr 2026 to 22 Apr 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2025 to 30 Sep 2025, finished
- "Thailand Trip" — Phuket, Thailand, 2 Nov 2025 to 10 Nov 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 11 Feb 2026 to 15 Feb 2026, finished
Being discussed: "Ladakh Ride"
Question: Paris mein kya khana chahiye

### Response
{"topic":"advice","trip":"named","tripTitle":"Paris Escape","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 5 Oct 2026 to 11 Oct 2026, upcoming
- "Singapore Stopover" — Singapore, 16 Feb 2027 to 19 Feb 2027, upcoming
Question: give me a recap of my next trip

### Response
{"topic":"overview","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 25 Sep 2026 to 1 Oct 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 7 Jul 2026 to 16 Jul 2026, finished
- "Ladakh Ride" — Leh, India, 4 Sep 2026 to 11 Sep 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 13 Nov 2025 to 20 Nov 2025, finished
Previous question: have we booked a way to get there?
Question: same for Arjun?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"Arjun","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 21 Nov 2026 to 26 Nov 2026, upcoming
- "Pondy Chill" — Puducherry, India, 24 Sep 2026 to 3 Oct 2026, under way now
- "Manali Snow Run" — Manali, India, 31 Mar 2027 to 5 Apr 2027, upcoming
Being discussed: "Pondy Chill"
Question: am I over budget on Pondy Chill?

### Response
{"topic":"spending","trip":"named","tripTitle":"Pondy Chill","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 26 Jan 2026 to 31 Jan 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 24 Sep 2026 to 2 Oct 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 21 Apr 2026 to 29 Apr 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 11 Apr 2026 to 13 Apr 2026, finished
- "Paris Escape" — Paris, France, 16 Dec 2025 to 24 Dec 2025, finished
- "Pondy Chill" — Puducherry, India, 24 Oct 2026 to 26 Oct 2026, upcoming
Being discussed: "Meghalaya Monsoon"
Previous question: when is our flight on the Paris trip?
Question: what about tomorrow

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 25 Nov 2025 to 2 Dec 2025, finished
- "Bali Bros" — Bali, Indonesia, 3 Oct 2026 to 9 Oct 2026, upcoming
- "Singapore Stopover" — Singapore, 25 Sep 2026 to 27 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 18 Oct 2026 to 24 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 14 Dec 2026 to 20 Dec 2026, upcoming
- "Pondy Chill" — Puducherry, India, 7 Oct 2026 to 11 Oct 2026, upcoming
Being discussed: "Singapore Stopover"
Question: which trip cost the most

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 24 Feb 2027 to 1 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 19 Sep 2025 to 22 Sep 2025, finished
- "Thailand Trip" — Phuket, Thailand, 5 Jun 2026 to 12 Jun 2026, finished
- "Rome in Spring" — Rome, Italy, 28 Dec 2026 to 4 Jan 2027, upcoming
Question: tanvi ne ab tak kitna pay kiya?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"Tanvi","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 10 Nov 2025 to 12 Nov 2025, finished
- "Goa Getaway" — Goa, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 8 Nov 2025 to 13 Nov 2025, finished
Question: Kitni trips ho gayi ab tak?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 5 Oct 2025 to 12 Oct 2025, finished
- "Jaipur Weekend" — Jaipur, India, 24 Sep 2026 to 3 Oct 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 5 May 2026 to 13 May 2026, finished
Being discussed: "Jaipur Weekend"
Question: Do we have free days on our trip?

### Response
{"topic":"gaps","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 12 Oct 2026 to 14 Oct 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 3 Nov 2026 to 10 Nov 2026, upcoming
- "Rome in Spring" — Rome, Italy, 20 Nov 2026 to 29 Nov 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 20 Oct 2026 to 26 Oct 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 25 Sep 2026 to 29 Sep 2026, under way now
- "Ladakh Ride" — Leh, India, 12 Jun 2026 to 20 Jun 2026, finished
Question: namaste equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 12 May 2026 to 16 May 2026, finished
- "Jaipur Weekend" — Jaipur, India, 20 Mar 2026 to 22 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 30 Jun 2026 to 9 Jul 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 3 Dec 2025 to 12 Dec 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 30 Jan 2026 to 2 Feb 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 21 Mar 2026 to 25 Mar 2026, finished
Question: when does the train leave?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 9 Jan 2026 to 11 Jan 2026, finished
- "Manali Snow Run" — Manali, India, 19 Apr 2026 to 21 Apr 2026, finished
- "Singapore Stopover" — Singapore, 5 Sep 2025 to 8 Sep 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 10 Dec 2025 to 15 Dec 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 14 Apr 2026 to 21 Apr 2026, finished
Question: kisi se settle karna baaki hai kya?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 13 Aug 2026 to 22 Aug 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 26 Sep 2026 to 1 Oct 2026, under way now
- "Paris Escape" — Paris, France, 22 Jan 2027 to 27 Jan 2027, upcoming
- "Hampi Heritage" — Hampi, India, 20 Aug 2026 to 28 Aug 2026, finished
- "Jaipur Weekend" — Jaipur, India, 18 Feb 2027 to 27 Feb 2027, upcoming
Being discussed: "Meghalaya Monsoon"
Question: any train tickets for the Jaipur trip?

### Response
{"topic":"bookings","trip":"named","tripTitle":"Jaipur Weekend","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 25 Aug 2026 to 30 Aug 2026, finished
- "Ladakh Ride" — Leh, India, 2 Feb 2027 to 5 Feb 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 4 Jul 2026 to 6 Jul 2026, finished
- "Singapore Stopover" — Singapore, 21 Mar 2027 to 23 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 9 Dec 2026 to 17 Dec 2026, upcoming
Question: abhi wali trip ke liye kya pack karu?

### Response
{"topic":"advice","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 28 Mar 2027 to 2 Apr 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 25 Mar 2027 to 27 Mar 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 8 Jul 2026 to 16 Jul 2026, finished
Question: Dubai wali trip ke liye kya pack karu?

### Response
{"topic":"advice","trip":"named","tripTitle":"Dubai Long Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 3 Mar 2027 to 10 Mar 2027, upcoming
- "Singapore Stopover" — Singapore, 4 Dec 2026 to 8 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 29 Mar 2026 to 3 Apr 2026, finished
Question: what's next on our Singapore trip?

### Response
{"topic":"schedule","trip":"named","tripTitle":"Singapore Stopover","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 24 Jan 2026 to 30 Jan 2026, finished
- "Bali Bros" — Bali, Indonesia, 3 Mar 2026 to 9 Mar 2026, finished
- "Kerala Backwaters" — Alleppey, India, 2 Nov 2026 to 10 Nov 2026, upcoming
- "Goa Getaway" — Goa, India, 3 Dec 2026 to 5 Dec 2026, upcoming
- "Manali Snow Run" — Manali, India, 27 Sep 2026 to 1 Oct 2026, under way now
Previous question: what time is hotel check-in tomorrow?
Question: same for Meera?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"stay","person":"Meera","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 1 Nov 2026 to 6 Nov 2026, upcoming
- "Ladakh Ride" — Leh, India, 10 Aug 2026 to 19 Aug 2026, finished
- "Udaipur Wedding" — Udaipur, India, 14 Dec 2026 to 17 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 19 Nov 2026 to 24 Nov 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 22 Mar 2026 to 28 Mar 2026, finished
- "Goa Getaway" — Goa, India, 3 Nov 2026 to 8 Nov 2026, upcoming
Question: what food should we try in udaipur?

### Response
{"topic":"advice","trip":"named","tripTitle":"Udaipur Wedding","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 26 Sep 2026 to 4 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 9 Jan 2027 to 17 Jan 2027, upcoming
- "Manali Snow Run" — Manali, India, 29 Nov 2026 to 7 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 8 Jan 2027 to 10 Jan 2027, upcoming
Being discussed: "Meghalaya Monsoon"
Question: What time is the airport pickup today

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 9 Nov 2026 to 18 Nov 2026, upcoming
- "Manali Snow Run" — Manali, India, 23 Jan 2026 to 29 Jan 2026, finished
- "Jaipur Weekend" — Jaipur, India, 10 Oct 2026 to 16 Oct 2026, upcoming
Question: Who made you?

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 8 Nov 2026 to 15 Nov 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2026 to 2 Oct 2026, under way now
- "Goa Getaway" — Goa, India, 14 Nov 2026 to 19 Nov 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 23 Mar 2026 to 27 Mar 2026, finished
- "Paris Escape" — Paris, France, 3 Feb 2026 to 8 Feb 2026, finished
- "Hampi Heritage" — Hampi, India, 24 Aug 2026 to 31 Aug 2026, finished
Question: Pichli trip mein hum kahan ruk rahe hain?

### Response
{"topic":"bookings","trip":"previous","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 26 Sep 2026 to 28 Sep 2026, under way now
- "Ladakh Ride" — Leh, India, 30 Oct 2026 to 3 Nov 2026, upcoming
- "Paris Escape" — Paris, France, 23 Jan 2027 to 28 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 20 Jan 2026 to 25 Jan 2026, finished
- "Goa Getaway" — Goa, India, 24 Jan 2027 to 2 Feb 2027, upcoming
Question: who paid for dinner last night?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 14 Oct 2026 to 17 Oct 2026, upcoming
- "Goa Getaway" — Goa, India, 15 Apr 2027 to 24 Apr 2027, upcoming
- "Rome in Spring" — Rome, Italy, 19 Nov 2026 to 22 Nov 2026, upcoming
- "Pondy Chill" — Puducherry, India, 23 Feb 2027 to 3 Mar 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 30 Dec 2025 to 5 Jan 2026, finished
Being discussed: "Ladakh Ride"
Question: who's coming on the rome trip?

### Response
{"topic":"people","trip":"named","tripTitle":"Rome in Spring","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 31 Aug 2025 to 2 Sep 2025, finished
- "Singapore Stopover" — Singapore, 9 Dec 2026 to 14 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 25 Nov 2026 to 2 Dec 2026, upcoming
- "Ladakh Ride" — Leh, India, 12 Mar 2027 to 16 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 26 Sep 2026 to 3 Oct 2026, under way now
Question: is Neha on our Jaipur trip?

### Response
{"topic":"people","trip":"named","tripTitle":"Jaipur Weekend","category":"anything","person":"Neha","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 31 Dec 2026 to 4 Jan 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 26 Oct 2026 to 2 Nov 2026, upcoming
- "Pondy Chill" — Puducherry, India, 25 Sep 2026 to 2 Oct 2026, under way now
- "Rome in Spring" — Rome, Italy, 26 Jan 2027 to 1 Feb 2027, upcoming
Question: what are we doing today?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 25 Sep 2026 to 30 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 5 Mar 2027 to 11 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 22 Jan 2026 to 25 Jan 2026, finished
- "Hampi Heritage" — Hampi, India, 31 Mar 2027 to 2 Apr 2027, upcoming
- "Pondy Chill" — Puducherry, India, 29 Jan 2026 to 2 Feb 2026, finished
Being discussed: "Kerala Backwaters"
Question: kisi raat hotel nahi hai kya?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 28 Sep 2026, under way now
- "Ladakh Ride" — Leh, India, 3 Jan 2027 to 5 Jan 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 3 Mar 2026 to 6 Mar 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 30 Sep 2025 to 8 Oct 2025, finished
- "Bali Bros" — Bali, Indonesia, 18 Mar 2027 to 25 Mar 2027, upcoming
Previous question: Neha ko kitna dena hai?
Question: and for my next trip?

### Response
{"topic":"balance","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 7 Sep 2026 to 16 Sep 2026, finished
- "Bali Bros" — Bali, Indonesia, 14 Apr 2027 to 23 Apr 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 9 Mar 2027 to 13 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 24 Sep 2026 to 26 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 26 Dec 2026 to 2 Jan 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 19 Feb 2027 to 27 Feb 2027, upcoming
Being discussed: "Paris Escape"
Question: kitni trips ho gayi ab tak

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 22 Jun 2026 to 1 Jul 2026, finished
- "Hampi Heritage" — Hampi, India, 21 Dec 2025 to 27 Dec 2025, finished
- "Bali Bros" — Bali, Indonesia, 26 Sep 2026 to 29 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 16 Mar 2027 to 19 Mar 2027, upcoming
- "Manali Snow Run" — Manali, India, 23 Sep 2025 to 2 Oct 2025, finished
Being discussed: "Bali Bros"
Question: good morning

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 2 Mar 2026 to 9 Mar 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 6 Jan 2026 to 14 Jan 2026, finished
- "Bali Bros" — Bali, Indonesia, 26 Mar 2027 to 1 Apr 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 8 Jan 2026 to 12 Jan 2026, finished
Previous question: how much do I owe Meera?
Question: same for omar?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Omar","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 28 Jan 2026 to 31 Jan 2026, finished
- "Manali Snow Run" — Manali, India, 20 Nov 2026 to 24 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 1 Feb 2026 to 6 Feb 2026, finished
- "Thailand Trip" — Phuket, Thailand, 24 Sep 2026 to 3 Oct 2026, under way now
Being discussed: "Thailand Trip"
Question: what was the most expensive thing on Manali Snow Run?

### Response
{"topic":"spending","trip":"named","tripTitle":"Manali Snow Run","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 1 Apr 2026 to 3 Apr 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 27 Feb 2027 to 4 Mar 2027, upcoming
- "Rome in Spring" — Rome, Italy, 19 May 2026 to 28 May 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 27 Sep 2026 to 5 Oct 2026, under way now
Question: do i need to settle up with anyone?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 30 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 9 Feb 2027 to 18 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 7 Mar 2027 to 10 Mar 2027, upcoming
- "Rome in Spring" — Rome, Italy, 26 Oct 2026 to 28 Oct 2026, upcoming
- "Paris Escape" — Paris, France, 4 Mar 2027 to 12 Mar 2027, upcoming
Being discussed: "Ladakh Ride"
Question: when is the paris trip?

### Response
{"topic":"overview","trip":"named","tripTitle":"Paris Escape","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 14 Feb 2026 to 17 Feb 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 25 Apr 2026 to 2 May 2026, finished
- "Singapore Stopover" — Singapore, 27 Apr 2026 to 3 May 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 11 Jun 2026 to 19 Jun 2026, finished
Question: who paid for the flights on the Singapore trip?

### Response
{"topic":"people","trip":"named","tripTitle":"Singapore Stopover","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 3 Nov 2026 to 12 Nov 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 13 Apr 2027 to 20 Apr 2027, upcoming
- "Pondy Chill" — Puducherry, India, 23 Sep 2025 to 26 Sep 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 24 Sep 2026 to 2 Oct 2026, under way now
- "Coorg Coffee Trail" — Coorg, India, 13 Apr 2026 to 17 Apr 2026, finished
- "Bali Bros" — Bali, Indonesia, 29 Apr 2026 to 7 May 2026, finished
Being discussed: "Tokyo 2026"
Previous question: is anything not booked yet for Pondy Chill?
Question: kal ka?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 13 Apr 2027 to 20 Apr 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 4 Jun 2026 to 12 Jun 2026, finished
- "Bali Bros" — Bali, Indonesia, 5 Mar 2027 to 8 Mar 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 9 Nov 2026 to 11 Nov 2026, upcoming
Question: hotel kisne pay kiya?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 18 Feb 2027 to 21 Feb 2027, upcoming
- "Manali Snow Run" — Manali, India, 12 May 2026 to 17 May 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 12 Jan 2027 to 18 Jan 2027, upcoming
Question: kaun kisko kitna dega?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 4 Aug 2026 to 8 Aug 2026, finished
- "Rome in Spring" — Rome, Italy, 27 Sep 2026 to 5 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 27 Dec 2025 to 30 Dec 2025, finished
Being discussed: "Rome in Spring"
Question: koi din khali hai kya pichli trip mein

### Response
{"topic":"gaps","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 26 Sep 2026 to 29 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 23 Feb 2027 to 4 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 19 Oct 2026 to 23 Oct 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 16 Apr 2026 to 25 Apr 2026, finished
Question: hotel ka kitna laga?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 11 Nov 2026 to 18 Nov 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 15 Feb 2026 to 24 Feb 2026, finished
- "Kerala Backwaters" — Alleppey, India, 11 Jan 2026 to 16 Jan 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 1 Jan 2027 to 6 Jan 2027, upcoming
Question: when does the train leave?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 26 Sep 2026 to 29 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 6 Jan 2026 to 10 Jan 2026, finished
- "Udaipur Wedding" — Udaipur, India, 10 Feb 2027 to 19 Feb 2027, upcoming
Question: bali wali trip mein kuch book karna baaki hai?

### Response
{"topic":"gaps","trip":"named","tripTitle":"Bali Bros","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 29 Aug 2025 to 2 Sep 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 15 Apr 2027 to 20 Apr 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 27 Oct 2026 to 5 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 23 Oct 2026 to 25 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 1 Jul 2026 to 7 Jul 2026, finished
- "Rome in Spring" — Rome, Italy, 25 Sep 2026 to 27 Sep 2026, under way now
Question: kaise ho?

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 8 Jan 2027 to 13 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 4 Jun 2026 to 6 Jun 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 31 Jul 2026 to 6 Aug 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 6 Jan 2027 to 12 Jan 2027, upcoming
- "Paris Escape" — Paris, France, 25 Jul 2026 to 27 Jul 2026, finished
Question: kya kya activities hain Udaipur Wedding mein?

### Response
{"topic":"bookings","trip":"named","tripTitle":"Udaipur Wedding","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 7 Jan 2027 to 9 Jan 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 5 Oct 2025 to 7 Oct 2025, finished
- "Goa Getaway" — Goa, India, 14 Mar 2027 to 17 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 1 Nov 2025 to 5 Nov 2025, finished
- "Manali Snow Run" — Manali, India, 30 Dec 2026 to 7 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 3 Oct 2026 to 11 Oct 2026, upcoming
Question: how many trips have i taken

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 2 Apr 2027 to 5 Apr 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 11 Oct 2025 to 14 Oct 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 5 Feb 2027 to 13 Feb 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 19 Jan 2026 to 24 Jan 2026, finished
Previous question: have we booked a way to get there?
Question: What about tomorrow?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 2 Apr 2026 to 4 Apr 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 22 Oct 2025 to 30 Oct 2025, finished
- "Hampi Heritage" — Hampi, India, 6 Jun 2026 to 11 Jun 2026, finished
- "Rome in Spring" — Rome, Italy, 2 Nov 2025 to 10 Nov 2025, finished
- "Singapore Stopover" — Singapore, 3 Dec 2026 to 8 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 25 Sep 2026 to 2 Oct 2026, under way now
Previous question: khane pe kitna gaya?
Question: what about tomorrow?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 30 May 2026 to 3 Jun 2026, finished
- "Jaipur Weekend" — Jaipur, India, 24 Sep 2026 to 27 Sep 2026, under way now
- "Goa Getaway" — Goa, India, 11 Oct 2026 to 13 Oct 2026, upcoming
Being discussed: "Jaipur Weekend"
Question: Paris Escape ke liye kya pack karu?

### Response
{"topic":"advice","trip":"named","tripTitle":"Paris Escape","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 17 Dec 2026 to 23 Dec 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 20 Jan 2026 to 22 Jan 2026, finished
- "Udaipur Wedding" — Udaipur, India, 8 Dec 2025 to 14 Dec 2025, finished
- "Singapore Stopover" — Singapore, 9 Jun 2026 to 16 Jun 2026, finished
- "Kerala Backwaters" — Alleppey, India, 2 Sep 2025 to 6 Sep 2025, finished
- "Paris Escape" — Paris, France, 5 Mar 2027 to 11 Mar 2027, upcoming
Question: where did all the money go?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 20 Feb 2027 to 1 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 19 Oct 2026 to 21 Oct 2026, upcoming
- "Rome in Spring" — Rome, Italy, 19 Mar 2027 to 25 Mar 2027, upcoming
- "Manali Snow Run" — Manali, India, 5 Jan 2027 to 7 Jan 2027, upcoming
- "Hampi Heritage" — Hampi, India, 16 Jan 2027 to 24 Jan 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 24 Sep 2026 to 3 Oct 2026, under way now
Question: aaj kitna kharcha ho gaya?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 7 Mar 2027 to 11 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 12 Sep 2025 to 20 Sep 2025, finished
- "Ladakh Ride" — Leh, India, 8 Nov 2026 to 10 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 15 Jul 2026 to 21 Jul 2026, finished
- "Hampi Heritage" — Hampi, India, 22 Aug 2026 to 31 Aug 2026, finished
Previous question: which flights are booked for the Dubai trip?
Question: aur agli trip mein?

### Response
{"topic":"bookings","trip":"next","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 25 Aug 2026 to 3 Sep 2026, finished
- "Bali Bros" — Bali, Indonesia, 21 Dec 2026 to 26 Dec 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 24 Feb 2027 to 4 Mar 2027, upcoming
- "Ladakh Ride" — Leh, India, 7 Feb 2026 to 14 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 6 Nov 2026 to 12 Nov 2026, upcoming
Question: How many trips have I taken?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 20 Sep 2025 to 23 Sep 2025, finished
- "Jaipur Weekend" — Jaipur, India, 2 Apr 2026 to 9 Apr 2026, finished
- "Udaipur Wedding" — Udaipur, India, 13 Nov 2026 to 22 Nov 2026, upcoming
Question: who paid for the flights on the previous trip

### Response
{"topic":"people","trip":"previous","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 15 Dec 2026 to 20 Dec 2026, upcoming
- "Ladakh Ride" — Leh, India, 25 Apr 2026 to 27 Apr 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 25 Dec 2026 to 27 Dec 2026, upcoming
Question: what's missing from our trip

### Response
{"topic":"gaps","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 19 Sep 2025 to 27 Sep 2025, finished
- "Pondy Chill" — Puducherry, India, 6 Dec 2025 to 12 Dec 2025, finished
- "Kerala Backwaters" — Alleppey, India, 22 Nov 2025 to 26 Nov 2025, finished
Question: shukriya

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 30 Nov 2025 to 8 Dec 2025, finished
- "Paris Escape" — Paris, France, 24 Sep 2026 to 3 Oct 2026, under way now
- "Rome in Spring" — Rome, Italy, 13 Apr 2027 to 17 Apr 2027, upcoming
- "Pondy Chill" — Puducherry, India, 7 Feb 2026 to 15 Feb 2026, finished
Question: Goa mein ghoomne ki best jagah kaunsi hai?

### Response
{"topic":"advice","trip":"named","tripTitle":"Goa Getaway","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 14 Jan 2026 to 17 Jan 2026, finished
- "Goa Getaway" — Goa, India, 5 Dec 2026 to 7 Dec 2026, upcoming
- "Hampi Heritage" — Hampi, India, 25 Jun 2026 to 27 Jun 2026, finished
- "Bali Bros" — Bali, Indonesia, 2 Feb 2026 to 4 Feb 2026, finished
- "Thailand Trip" — Phuket, Thailand, 12 Feb 2026 to 19 Feb 2026, finished
- "Rome in Spring" — Rome, Italy, 27 Sep 2025 to 1 Oct 2025, finished
Question: kaun kisko kitna dega?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 6 Sep 2025 to 12 Sep 2025, finished
- "Kerala Backwaters" — Alleppey, India, 8 Feb 2027 to 15 Feb 2027, upcoming
- "Ladakh Ride" — Leh, India, 5 Jan 2026 to 12 Jan 2026, finished
- "Paris Escape" — Paris, France, 1 Mar 2027 to 7 Mar 2027, upcoming
Previous question: is the airport pickup booked?
Question: kal ka

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 24 Jun 2026 to 2 Jul 2026, finished
- "Rome in Spring" — Rome, Italy, 11 Apr 2026 to 17 Apr 2026, finished
- "Hampi Heritage" — Hampi, India, 23 Mar 2026 to 30 Mar 2026, finished
- "Kerala Backwaters" — Alleppey, India, 5 Mar 2027 to 8 Mar 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2026 to 30 Sep 2026, under way now
Being discussed: "Tokyo 2026"
Question: what's the weather like in rome this time of year

### Response
{"topic":"advice","trip":"named","tripTitle":"Rome in Spring","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 12 Apr 2027 to 18 Apr 2027, upcoming
- "Singapore Stopover" — Singapore, 4 May 2026 to 10 May 2026, finished
- "Paris Escape" — Paris, France, 24 Sep 2026 to 29 Sep 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 5 Feb 2027 to 9 Feb 2027, upcoming
Being discussed: "Paris Escape"
Question: give me a recap of the dubai trip

### Response
{"topic":"overview","trip":"named","tripTitle":"Dubai Long Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 13 Sep 2025 to 18 Sep 2025, finished
- "Thailand Trip" — Phuket, Thailand, 24 Feb 2026 to 28 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 9 Feb 2027 to 15 Feb 2027, upcoming
Question: what's the weather like in Kerala this time of year

### Response
{"topic":"advice","trip":"named","tripTitle":"Kerala Backwaters","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 8 Feb 2026 to 14 Feb 2026, finished
- "Udaipur Wedding" — Udaipur, India, 28 Dec 2026 to 30 Dec 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 5 Dec 2025 to 9 Dec 2025, finished
Question: udaipur mein ghoomne ki best jagah kaunsi hai?

### Response
{"topic":"advice","trip":"named","tripTitle":"Udaipur Wedding","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 13 Nov 2026 to 20 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 3 Feb 2027 to 10 Feb 2027, upcoming
- "Singapore Stopover" — Singapore, 27 Sep 2026 to 3 Oct 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 4 Dec 2025 to 10 Dec 2025, finished
Being discussed: "Singapore Stopover"
Question: Goa wali trip ka summary batao

### Response
{"topic":"overview","trip":"named","tripTitle":"Goa Getaway","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 25 Jun 2026 to 30 Jun 2026, finished
- "Pondy Chill" — Puducherry, India, 19 Jan 2027 to 27 Jan 2027, upcoming
- "Manali Snow Run" — Manali, India, 26 Sep 2026 to 1 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 24 Jan 2027 to 27 Jan 2027, upcoming
- "Singapore Stopover" — Singapore, 28 Nov 2026 to 7 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 2 Jan 2027 to 10 Jan 2027, upcoming
Question: what time is hotel check-in tomorrow?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 24 Aug 2025 to 30 Aug 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 15 Aug 2026 to 20 Aug 2026, finished
- "Hampi Heritage" — Hampi, India, 22 Jun 2026 to 25 Jun 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 20 Oct 2026 to 29 Oct 2026, upcoming
Question: What was the most expensive thing on the kerala trip?

### Response
{"topic":"spending","trip":"named","tripTitle":"Kerala Backwaters","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 26 Feb 2027 to 7 Mar 2027, upcoming
- "Manali Snow Run" — Manali, India, 26 Sep 2026 to 4 Oct 2026, under way now
- "Singapore Stopover" — Singapore, 15 Jan 2027 to 19 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 7 Jan 2027 to 14 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 11 Oct 2025 to 20 Oct 2025, finished
Question: meri saari trips dikhao

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 14 Dec 2026 to 22 Dec 2026, upcoming
- "Rome in Spring" — Rome, Italy, 20 Mar 2026 to 22 Mar 2026, finished
- "Manali Snow Run" — Manali, India, 25 Nov 2026 to 3 Dec 2026, upcoming
- "Ladakh Ride" — Leh, India, 14 Mar 2027 to 17 Mar 2027, upcoming
Being discussed: "Coorg Coffee Trail"
Previous question: is Sam on our Ladakh trip?
Question: same for kabir

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"Kabir","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 30 Aug 2025 to 2 Sep 2025, finished
- "Goa Getaway" — Goa, India, 29 Mar 2027 to 31 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 14 Oct 2025 to 18 Oct 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 21 Dec 2026 to 28 Dec 2026, upcoming
Question: namaste Equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 3 Sep 2025 to 8 Sep 2025, finished
- "Manali Snow Run" — Manali, India, 1 Mar 2026 to 5 Mar 2026, finished
- "Rome in Spring" — Rome, Italy, 27 Apr 2026 to 3 May 2026, finished
- "Jaipur Weekend" — Jaipur, India, 20 Oct 2026 to 24 Oct 2026, upcoming
- "Singapore Stopover" — Singapore, 22 Jan 2026 to 31 Jan 2026, finished
- "Goa Getaway" — Goa, India, 27 Aug 2026 to 4 Sep 2026, finished
Question: Goa Getaway kaisi chal rahi hai?

### Response
{"topic":"overview","trip":"named","tripTitle":"Goa Getaway","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 29 May 2026 to 1 Jun 2026, finished
- "Goa Getaway" — Goa, India, 2 Jan 2026 to 8 Jan 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 29 Jan 2026 to 4 Feb 2026, finished
- "Ladakh Ride" — Leh, India, 5 Dec 2025 to 13 Dec 2025, finished
- "Thailand Trip" — Phuket, Thailand, 16 Mar 2027 to 24 Mar 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 25 Sep 2026 to 1 Oct 2026, under way now
Being discussed: "Rishikesh Rafting"
Question: aaj kya plan hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 17 Dec 2026 to 26 Dec 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 22 Jul 2026 to 26 Jul 2026, finished
- "Kerala Backwaters" — Alleppey, India, 17 Nov 2026 to 26 Nov 2026, upcoming
Question: any nights without a hotel on our Dubai trip?

### Response
{"topic":"gaps","trip":"named","tripTitle":"Dubai Long Weekend","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 25 Jan 2027 to 28 Jan 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 27 Sep 2026 to 2 Oct 2026, under way now
- "Coorg Coffee Trail" — Coorg, India, 8 Feb 2027 to 14 Feb 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 7 Mar 2027 to 11 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 15 Feb 2026 to 21 Feb 2026, finished
Question: khane pe kitna gaya

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 5 Apr 2027 to 8 Apr 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 18 Nov 2025 to 22 Nov 2025, finished
- "Singapore Stopover" — Singapore, 9 Oct 2025 to 13 Oct 2025, finished
Question: is anything not booked yet for the Singapore Stopover trip?

### Response
{"topic":"gaps","trip":"named","tripTitle":"Singapore Stopover","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 26 Sep 2026 to 3 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 31 Aug 2025 to 8 Sep 2025, finished
- "Paris Escape" — Paris, France, 30 May 2026 to 8 Jun 2026, finished
Question: ok cool

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 24 Sep 2026 to 30 Sep 2026, under way now
- "Singapore Stopover" — Singapore, 12 Dec 2025 to 20 Dec 2025, finished
- "Udaipur Wedding" — Udaipur, India, 6 Mar 2027 to 11 Mar 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 1 Feb 2027 to 8 Feb 2027, upcoming
- "Pondy Chill" — Puducherry, India, 1 Feb 2026 to 10 Feb 2026, finished
Being discussed: "Dubai Long Weekend"
Question: Udaipur mein mausam kaisa hoga?

### Response
{"topic":"advice","trip":"named","tripTitle":"Udaipur Wedding","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Manali Snow Run" — Manali, India, 20 Dec 2025 to 28 Dec 2025, finished
- "Rome in Spring" — Rome, Italy, 11 Feb 2027 to 15 Feb 2027, upcoming
Being discussed: "Hampi Heritage"
Question: good morning

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 18 Nov 2025 to 26 Nov 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 2 Apr 2027 to 4 Apr 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 24 Sep 2026 to 26 Sep 2026, under way now
Being discussed: "Thailand Trip"
Question: How is my last trip going

### Response
{"topic":"overview","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 15 Mar 2026 to 23 Mar 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 7 Feb 2027 to 12 Feb 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 2 May 2026 to 4 May 2026, finished
Question: thank you Equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 16 Jan 2027 to 22 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 19 Mar 2027 to 28 Mar 2027, upcoming
- "Manali Snow Run" — Manali, India, 30 Nov 2026 to 5 Dec 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 29 Mar 2026 to 7 Apr 2026, finished
- "Kerala Backwaters" — Alleppey, India, 10 Oct 2025 to 15 Oct 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 29 Mar 2026 to 2 Apr 2026, finished
Question: thank you Equi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 27 Sep 2026 to 2 Oct 2026, under way now
- "Goa Getaway" — Goa, India, 18 Feb 2027 to 27 Feb 2027, upcoming
- "Paris Escape" — Paris, France, 29 Aug 2026 to 4 Sep 2026, finished
Being discussed: "Thailand Trip"
Question: how many trips have I taken

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 26 Feb 2027 to 1 Mar 2027, upcoming
- "Ladakh Ride" — Leh, India, 2 Jan 2027 to 10 Jan 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 19 Jul 2026 to 22 Jul 2026, finished
- "Thailand Trip" — Phuket, Thailand, 31 Mar 2027 to 3 Apr 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 23 Feb 2027 to 25 Feb 2027, upcoming
Question: what's my balance on this trip

### Response
{"topic":"balance","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 2 Mar 2026 to 6 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 8 Mar 2027 to 10 Mar 2027, upcoming
- "Singapore Stopover" — Singapore, 1 Jan 2027 to 9 Jan 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 23 Nov 2026 to 2 Dec 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 23 Apr 2026 to 28 Apr 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 5 Mar 2027 to 7 Mar 2027, upcoming
Question: what trips do i have coming up?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 11 Mar 2027 to 16 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 24 Feb 2026 to 26 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 5 Oct 2025 to 14 Oct 2025, finished
- "Udaipur Wedding" — Udaipur, India, 22 May 2026 to 29 May 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 3 Oct 2026 to 6 Oct 2026, upcoming
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 4 Oct 2026, under way now
Question: aaj kya plan hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 13 Dec 2026 to 21 Dec 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 13 Nov 2026 to 21 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 21 Aug 2026 to 27 Aug 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 10 Feb 2027 to 15 Feb 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 5 Jan 2027 to 10 Jan 2027, upcoming
Question: shukriya

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 21 Mar 2026 to 25 Mar 2026, finished
- "Rome in Spring" — Rome, Italy, 27 Jan 2027 to 4 Feb 2027, upcoming
- "Hampi Heritage" — Hampi, India, 27 Sep 2026 to 30 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 23 Jun 2026 to 28 Jun 2026, finished
- "Jaipur Weekend" — Jaipur, India, 17 Jan 2026 to 23 Jan 2026, finished
Being discussed: "Hampi Heritage"
Question: am i even with karan?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Karan","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2026 to 30 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 2 Nov 2026 to 10 Nov 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 12 Feb 2027 to 18 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 21 Dec 2026 to 30 Dec 2026, upcoming
Question: total cab spend on our Tokyo trip

### Response
{"topic":"spending","trip":"named","tripTitle":"Tokyo 2026","category":"transfer","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 12 Jan 2026 to 17 Jan 2026, finished
- "Manali Snow Run" — Manali, India, 6 Feb 2026 to 8 Feb 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 21 Jul 2026 to 24 Jul 2026, finished
- "Hampi Heritage" — Hampi, India, 12 Nov 2026 to 15 Nov 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 26 Sep 2026 to 1 Oct 2026, under way now
Question: sabse mehengi trip kaunsi thi

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 25 Sep 2026 to 3 Oct 2026, under way now
- "Pondy Chill" — Puducherry, India, 25 Jan 2026 to 30 Jan 2026, finished
- "Thailand Trip" — Phuket, Thailand, 11 Apr 2027 to 18 Apr 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 5 Nov 2026 to 14 Nov 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 21 Oct 2026 to 29 Oct 2026, upcoming
Question: sabse mehenga kya tha Dubai Long Weekend wali trip mein

### Response
{"topic":"spending","trip":"named","tripTitle":"Dubai Long Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 15 Apr 2027 to 19 Apr 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 12 Nov 2026 to 18 Nov 2026, upcoming
- "Ladakh Ride" — Leh, India, 3 Apr 2027 to 11 Apr 2027, upcoming
Question: is trip ka summary batao

### Response
{"topic":"overview","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 17 Oct 2026 to 21 Oct 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 27 Sep 2026 to 4 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 14 Feb 2026 to 16 Feb 2026, finished
- "Singapore Stopover" — Singapore, 2 Oct 2026 to 9 Oct 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 9 Apr 2026 to 14 Apr 2026, finished
Question: koi din khali hai kya is trip mein?

### Response
{"topic":"gaps","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 27 Sep 2026 to 3 Oct 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 18 Apr 2026 to 23 Apr 2026, finished
- "Jaipur Weekend" — Jaipur, India, 9 Nov 2025 to 17 Nov 2025, finished
- "Paris Escape" — Paris, France, 5 Dec 2025 to 10 Dec 2025, finished
- "Kerala Backwaters" — Alleppey, India, 17 Feb 2027 to 26 Feb 2027, upcoming
- "Manali Snow Run" — Manali, India, 3 Mar 2027 to 12 Mar 2027, upcoming
Question: when is our Manali trip?

### Response
{"topic":"overview","trip":"named","tripTitle":"Manali Snow Run","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 31 Jul 2026 to 3 Aug 2026, finished
- "Bali Bros" — Bali, Indonesia, 10 Dec 2026 to 14 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 16 Oct 2026 to 22 Oct 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 9 Jan 2026 to 18 Jan 2026, finished
- "Pondy Chill" — Puducherry, India, 20 Nov 2026 to 25 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 3 Nov 2026 to 5 Nov 2026, upcoming
Question: how is our Kerala trip going?

### Response
{"topic":"overview","trip":"named","tripTitle":"Kerala Backwaters","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 16 Dec 2026 to 25 Dec 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 21 Nov 2026 to 24 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 9 Apr 2027 to 16 Apr 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 26 Sep 2026 to 28 Sep 2026, under way now
Being discussed: "Coorg Coffee Trail"
Question: hi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 18 Jan 2027 to 26 Jan 2027, upcoming
- "Hampi Heritage" — Hampi, India, 12 Dec 2026 to 19 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 17 Mar 2027 to 20 Mar 2027, upcoming
- "Pondy Chill" — Puducherry, India, 8 Jan 2026 to 16 Jan 2026, finished
- "Singapore Stopover" — Singapore, 10 Jul 2026 to 15 Jul 2026, finished
- "Udaipur Wedding" — Udaipur, India, 26 Sep 2026 to 5 Oct 2026, under way now
Being discussed: "Udaipur Wedding"
Question: meri saari trips dikhao

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 27 Nov 2025 to 2 Dec 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 11 Jan 2027 to 18 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 24 Sep 2026 to 28 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 28 Mar 2026 to 30 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 16 Jan 2027 to 18 Jan 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 5 Mar 2027 to 13 Mar 2027, upcoming
Being discussed: "Rome in Spring"
Question: hi

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 5 Mar 2027 to 14 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 12 Oct 2026 to 17 Oct 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 16 Dec 2025 to 25 Dec 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 4 Apr 2027 to 13 Apr 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 2 Sep 2026 to 6 Sep 2026, finished
- "Singapore Stopover" — Singapore, 11 Nov 2025 to 18 Nov 2025, finished
Question: do we have free days on the previous trip

### Response
{"topic":"gaps","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 13 Dec 2025 to 18 Dec 2025, finished
- "Udaipur Wedding" — Udaipur, India, 6 Jul 2026 to 11 Jul 2026, finished
- "Hampi Heritage" — Hampi, India, 1 Apr 2026 to 7 Apr 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 14 Oct 2026 to 18 Oct 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 7 Oct 2026 to 13 Oct 2026, upcoming
Question: Tell me a joke

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 20 Jan 2027 to 29 Jan 2027, upcoming
- "Hampi Heritage" — Hampi, India, 1 Mar 2026 to 6 Mar 2026, finished
- "Kerala Backwaters" — Alleppey, India, 10 Jan 2027 to 14 Jan 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 2 Oct 2025 to 6 Oct 2025, finished
Previous question: where are we staying on our Rome trip?
Question: what about tomorrow

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 1 Feb 2026 to 7 Feb 2026, finished
- "Thailand Trip" — Phuket, Thailand, 15 Mar 2027 to 23 Mar 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 28 Jul 2026 to 1 Aug 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 27 May 2026 to 31 May 2026, finished
- "Manali Snow Run" — Manali, India, 26 Sep 2026 to 29 Sep 2026, under way now
Question: How much did food cost on our last trip?

### Response
{"topic":"spending","trip":"previous","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2026 to 30 Sep 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 8 May 2026 to 14 May 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 20 Oct 2025 to 22 Oct 2025, finished
- "Hampi Heritage" — Hampi, India, 16 Nov 2026 to 19 Nov 2026, upcoming
Question: show my past trips

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 26 Mar 2027 to 28 Mar 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 11 Mar 2027 to 18 Mar 2027, upcoming
- "Singapore Stopover" — Singapore, 24 Oct 2026 to 1 Nov 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 31 May 2026 to 2 Jun 2026, finished
Previous question: kal subah sabse pehle kya hai?
Question: aur Singapore Stopover mein?

### Response
{"topic":"schedule","trip":"named","tripTitle":"Singapore Stopover","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 8 Mar 2027 to 11 Mar 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 7 Oct 2025 to 14 Oct 2025, finished
- "Pondy Chill" — Puducherry, India, 12 Jan 2027 to 15 Jan 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 19 Feb 2027 to 21 Feb 2027, upcoming
Question: does meera owe me anything?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Meera","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 25 Nov 2026 to 27 Nov 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 18 Aug 2026 to 27 Aug 2026, finished
- "Hampi Heritage" — Hampi, India, 15 Jan 2027 to 23 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 27 Sep 2026 to 3 Oct 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 11 Mar 2027 to 16 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 2 Jan 2027 to 7 Jan 2027, upcoming
Question: what was the most expensive thing on the next trip?

### Response
{"topic":"spending","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 9 Nov 2025 to 13 Nov 2025, finished
- "Paris Escape" — Paris, France, 23 Mar 2027 to 1 Apr 2027, upcoming
- "Manali Snow Run" — Manali, India, 27 Mar 2027 to 5 Apr 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 24 Sep 2025 to 27 Sep 2025, finished
- "Pondy Chill" — Puducherry, India, 25 Mar 2027 to 28 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 7 Nov 2026 to 10 Nov 2026, upcoming
Question: good morning

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 1 Dec 2026 to 8 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 24 Jan 2026 to 30 Jan 2026, finished
- "Bali Bros" — Bali, Indonesia, 8 Apr 2027 to 11 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 28 Dec 2026 to 31 Dec 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 2 Jul 2026 to 6 Jul 2026, finished
Question: quick summary of our upcoming trip

### Response
{"topic":"overview","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 11 Jun 2026 to 14 Jun 2026, finished
- "Bali Bros" — Bali, Indonesia, 9 Dec 2026 to 13 Dec 2026, upcoming
- "Pondy Chill" — Puducherry, India, 11 Mar 2026 to 19 Mar 2026, finished
Question: am I over budget on our Bali trip?

### Response
{"topic":"spending","trip":"named","tripTitle":"Bali Bros","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 26 Sep 2026 to 2 Oct 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 4 Jan 2027 to 13 Jan 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 31 Dec 2026 to 5 Jan 2027, upcoming
- "Pondy Chill" — Puducherry, India, 28 Oct 2026 to 5 Nov 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 12 Oct 2026 to 18 Oct 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 10 Nov 2026 to 18 Nov 2026, upcoming
Question: meri saari trips dikhao

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 30 Jan 2027 to 8 Feb 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 2 Dec 2025 to 10 Dec 2025, finished
- "Kerala Backwaters" — Alleppey, India, 22 Dec 2026 to 26 Dec 2026, upcoming
Question: how's the trip going so far

### Response
{"topic":"overview","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 24 Sep 2026 to 26 Sep 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 4 Oct 2025 to 11 Oct 2025, finished
- "Manali Snow Run" — Manali, India, 13 Jan 2026 to 20 Jan 2026, finished
- "Jaipur Weekend" — Jaipur, India, 9 Apr 2027 to 12 Apr 2027, upcoming
- "Rome in Spring" — Rome, Italy, 25 Jan 2027 to 3 Feb 2027, upcoming
Question: sabse mehengi trip kaunsi thi

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 6 Jan 2027 to 9 Jan 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 26 Mar 2027 to 2 Apr 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 24 Sep 2026 to 2 Oct 2026, under way now
Being discussed: "Bali Bros"
Question: who paid for the villa?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 8 Feb 2026 to 11 Feb 2026, finished
- "Kerala Backwaters" — Alleppey, India, 25 Mar 2026 to 2 Apr 2026, finished
- "Singapore Stopover" — Singapore, 23 Mar 2027 to 28 Mar 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 26 Sep 2025 to 3 Oct 2025, finished
- "Paris Escape" — Paris, France, 8 Mar 2026 to 17 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 5 Feb 2026 to 14 Feb 2026, finished
Question: hotel ka kitna laga?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 13 Feb 2027 to 16 Feb 2027, upcoming
- "Goa Getaway" — Goa, India, 27 Sep 2026 to 4 Oct 2026, under way now
- "Ladakh Ride" — Leh, India, 27 Jan 2027 to 30 Jan 2027, upcoming
Question: am I over budget on our Goa trip?

### Response
{"topic":"spending","trip":"named","tripTitle":"Goa Getaway","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 8 Oct 2026 to 17 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 24 Sep 2026 to 29 Sep 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 31 Oct 2026 to 5 Nov 2026, upcoming
- "Hampi Heritage" — Hampi, India, 5 Nov 2026 to 14 Nov 2026, upcoming
Question: Hampi Heritage wali trip kaisi chal rahi hai?

### Response
{"topic":"overview","trip":"named","tripTitle":"Hampi Heritage","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 4 Feb 2027 to 12 Feb 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 19 Jun 2026 to 27 Jun 2026, finished
- "Thailand Trip" — Phuket, Thailand, 22 Mar 2027 to 28 Mar 2027, upcoming
Previous question: flight kitne baje hai?
Question: kal ka?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 6 Mar 2027 to 9 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 4 Dec 2025 to 9 Dec 2025, finished
- "Bali Bros" — Bali, Indonesia, 14 Nov 2026 to 16 Nov 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 12 Jan 2027 to 20 Jan 2027, upcoming
- "Pondy Chill" — Puducherry, India, 7 Feb 2026 to 15 Feb 2026, finished
Question: hotel ka kitna laga?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 26 Sep 2026 to 29 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 23 Mar 2026 to 27 Mar 2026, finished
- "Goa Getaway" — Goa, India, 11 Jan 2027 to 17 Jan 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 3 Oct 2026 to 9 Oct 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 14 Jun 2026 to 22 Jun 2026, finished
Being discussed: "Thailand Trip"
Question: dinner ka bill kisne bhara?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 26 Sep 2026 to 1 Oct 2026, under way now
- "Goa Getaway" — Goa, India, 9 Mar 2027 to 13 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 1 Mar 2027 to 5 Mar 2027, upcoming
Being discussed: "Rome in Spring"
Question: what food should we try in Rome

### Response
{"topic":"advice","trip":"named","tripTitle":"Rome in Spring","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 9 Oct 2025 to 18 Oct 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 20 Jun 2026 to 22 Jun 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 24 Sep 2026 to 1 Oct 2026, under way now
Being discussed: "Dubai Long Weekend"
Question: compare my trips by spend

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 27 Nov 2026 to 6 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 13 Aug 2026 to 22 Aug 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 1 Nov 2026 to 7 Nov 2026, upcoming
- "Paris Escape" — Paris, France, 24 Jan 2027 to 30 Jan 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 11 Feb 2026 to 16 Feb 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 2 May 2026 to 8 May 2026, finished
Previous question: what's my balance on the Hampi trip?
Question: kal ka

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 22 May 2026 to 28 May 2026, finished
- "Ladakh Ride" — Leh, India, 5 Feb 2027 to 12 Feb 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 8 Aug 2026 to 10 Aug 2026, finished
- "Bali Bros" — Bali, Indonesia, 24 Oct 2025 to 30 Oct 2025, finished
- "Goa Getaway" — Goa, India, 7 Feb 2027 to 15 Feb 2027, upcoming
Question: last wali trip kab hai

### Response
{"topic":"overview","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 19 Jan 2027 to 23 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 25 Sep 2026 to 1 Oct 2026, under way now
- "Singapore Stopover" — Singapore, 26 Aug 2026 to 4 Sep 2026, finished
Being discussed: "Ladakh Ride"
Question: how many trips have I taken?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 31 Aug 2025 to 3 Sep 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 5 Nov 2025 to 14 Nov 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 25 Sep 2026 to 30 Sep 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 9 Mar 2027 to 15 Mar 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 14 Dec 2026 to 21 Dec 2026, upcoming
Being discussed: "Rishikesh Rafting"
Question: Quick summary of this trip

### Response
{"topic":"overview","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 16 Mar 2026 to 21 Mar 2026, finished
- "Bali Bros" — Bali, Indonesia, 25 Sep 2026 to 27 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 3 Jan 2027 to 6 Jan 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 16 Oct 2025 to 20 Oct 2025, finished
Question: what did the flights come to?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 24 Sep 2026 to 30 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 6 Apr 2026 to 14 Apr 2026, finished
- "Jaipur Weekend" — Jaipur, India, 17 Dec 2026 to 26 Dec 2026, upcoming
Being discussed: "Rishikesh Rafting"
Question: is anything not booked yet for the next trip?

### Response
{"topic":"gaps","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 9 Jul 2026 to 14 Jul 2026, finished
- "Hampi Heritage" — Hampi, India, 26 Nov 2026 to 3 Dec 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 14 Apr 2027 to 20 Apr 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 19 Jan 2027 to 28 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 10 Feb 2026 to 13 Feb 2026, finished
- "Bali Bros" — Bali, Indonesia, 16 Oct 2026 to 21 Oct 2026, upcoming
Question: is the airport pickup booked?

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 23 Jul 2026 to 28 Jul 2026, finished
- "Goa Getaway" — Goa, India, 5 Nov 2025 to 10 Nov 2025, finished
- "Paris Escape" — Paris, France, 24 Sep 2026 to 26 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 19 Mar 2027 to 24 Mar 2027, upcoming
Question: is jaipur safe at night?

### Response
{"topic":"advice","trip":"named","tripTitle":"Jaipur Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 16 Nov 2026 to 23 Nov 2026, upcoming
- "Goa Getaway" — Goa, India, 27 Jan 2026 to 31 Jan 2026, finished
- "Udaipur Wedding" — Udaipur, India, 31 Dec 2026 to 4 Jan 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 4 Nov 2025 to 9 Nov 2025, finished
Question: what trips do I have coming up?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 27 Sep 2026 to 29 Sep 2026, under way now
- "Manali Snow Run" — Manali, India, 7 Jan 2026 to 9 Jan 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 3 Aug 2026 to 8 Aug 2026, finished
- "Jaipur Weekend" — Jaipur, India, 31 May 2026 to 3 Jun 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 21 Jan 2027 to 26 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 12 Dec 2025 to 16 Dec 2025, finished
Question: Meri saari trips dikhao

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 18 Apr 2026 to 21 Apr 2026, finished
- "Goa Getaway" — Goa, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 14 Oct 2026 to 17 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 12 Dec 2026 to 16 Dec 2026, upcoming
Question: any nights without a hotel on Coorg Coffee Trail?

### Response
{"topic":"gaps","trip":"named","tripTitle":"Coorg Coffee Trail","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 31 Mar 2027 to 2 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 21 Nov 2025 to 29 Nov 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 8 Jan 2026 to 16 Jan 2026, finished
- "Manali Snow Run" — Manali, India, 23 Jul 2026 to 25 Jul 2026, finished
- "Rome in Spring" — Rome, Italy, 24 Nov 2026 to 1 Dec 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 27 Sep 2026 to 6 Oct 2026, under way now
Being discussed: "Tokyo 2026"
Question: flight kitne baje hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 31 Jan 2026 to 6 Feb 2026, finished
- "Thailand Trip" — Phuket, Thailand, 30 Apr 2026 to 2 May 2026, finished
- "Rome in Spring" — Rome, Italy, 13 Jul 2026 to 20 Jul 2026, finished
- "Singapore Stopover" — Singapore, 18 Dec 2026 to 24 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 27 Sep 2026 to 6 Oct 2026, under way now
Being discussed: "Bali Bros"
Question: what time is the airport pickup today?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 18 Dec 2026 to 23 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 27 Sep 2026 to 4 Oct 2026, under way now
- "Coorg Coffee Trail" — Coorg, India, 6 Oct 2026 to 13 Oct 2026, upcoming
Question: total cab spend on our trip

### Response
{"topic":"spending","trip":"current","tripTitle":"","category":"transfer","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 14 Sep 2025 to 23 Sep 2025, finished
- "Meghalaya Monsoon" — Shillong, India, 26 Jun 2026 to 5 Jul 2026, finished
- "Kerala Backwaters" — Alleppey, India, 7 Aug 2026 to 9 Aug 2026, finished
- "Singapore Stopover" — Singapore, 14 Jan 2027 to 18 Jan 2027, upcoming
Question: how's the trip going so far?

### Response
{"topic":"overview","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 27 Sep 2026 to 2 Oct 2026, under way now
- "Singapore Stopover" — Singapore, 5 Apr 2027 to 7 Apr 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 30 Mar 2027 to 5 Apr 2027, upcoming
- "Pondy Chill" — Puducherry, India, 11 Oct 2026 to 18 Oct 2026, upcoming
- "Rome in Spring" — Rome, Italy, 7 Nov 2026 to 11 Nov 2026, upcoming
Being discussed: "Hampi Heritage"
Question: which hotel did we book for the Singapore trip

### Response
{"topic":"bookings","trip":"named","tripTitle":"Singapore Stopover","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 1 Mar 2027 to 7 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 28 Oct 2026 to 5 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 1 Oct 2026, under way now
- "Manali Snow Run" — Manali, India, 23 Feb 2027 to 28 Feb 2027, upcoming
Question: udaipur wedding wali trip mein mera kitna banta hai?

### Response
{"topic":"balance","trip":"named","tripTitle":"Udaipur Wedding","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 26 Sep 2026 to 5 Oct 2026, under way now
- "Rome in Spring" — Rome, Italy, 13 Oct 2025 to 16 Oct 2025, finished
- "Singapore Stopover" — Singapore, 8 Feb 2027 to 13 Feb 2027, upcoming
- "Ladakh Ride" — Leh, India, 5 Feb 2026 to 7 Feb 2026, finished
- "Bali Bros" — Bali, Indonesia, 1 Jan 2026 to 5 Jan 2026, finished
Being discussed: "Rishikesh Rafting"
Question: kal subah sabse pehle kya hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 5 Dec 2026 to 14 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 30 Nov 2025 to 4 Dec 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 1 Jan 2027 to 5 Jan 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 26 Dec 2025 to 4 Jan 2026, finished
Question: good morning

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 25 Sep 2026 to 28 Sep 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 18 May 2026 to 25 May 2026, finished
- "Ladakh Ride" — Leh, India, 11 Oct 2026 to 15 Oct 2026, upcoming
Question: last wali trip kaisi chal rahi hai?

### Response
{"topic":"overview","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 7 Apr 2026 to 14 Apr 2026, finished
- "Udaipur Wedding" — Udaipur, India, 27 Sep 2026 to 4 Oct 2026, under way now
- "Rome in Spring" — Rome, Italy, 2 Mar 2026 to 8 Mar 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 24 Mar 2027 to 30 Mar 2027, upcoming
Previous question: how much did the hotel cost?
Question: aur agli trip mein?

### Response
{"topic":"spending","trip":"next","tripTitle":"","category":"stay","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 25 Dec 2026 to 27 Dec 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 8 Feb 2026 to 11 Feb 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 4 May 2026 to 11 May 2026, finished
Question: koi din khali hai kya is trip mein?

### Response
{"topic":"gaps","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 30 Mar 2026 to 3 Apr 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 27 Sep 2026 to 1 Oct 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 28 Oct 2026 to 2 Nov 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 16 Feb 2027 to 18 Feb 2027, upcoming
Question: how many days is the dubai trip?

### Response
{"topic":"overview","trip":"named","tripTitle":"Dubai Long Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 25 Sep 2026 to 28 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 22 Mar 2026 to 26 Mar 2026, finished
- "Manali Snow Run" — Manali, India, 12 Jan 2027 to 16 Jan 2027, upcoming
Question: How much did food cost on the previous trip

### Response
{"topic":"spending","trip":"previous","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 10 Nov 2025 to 13 Nov 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 11 Nov 2026 to 19 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 29 Jan 2027 to 6 Feb 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 22 Dec 2025 to 30 Dec 2025, finished
- "Rome in Spring" — Rome, Italy, 24 Sep 2026 to 29 Sep 2026, under way now
- "Kerala Backwaters" — Alleppey, India, 21 Feb 2027 to 26 Feb 2027, upcoming
Being discussed: "Rome in Spring"
Question: aaj check-in kitne baje hai

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 13 Apr 2026 to 20 Apr 2026, finished
- "Kerala Backwaters" — Alleppey, India, 26 Jul 2026 to 2 Aug 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 7 Sep 2026 to 11 Sep 2026, finished
- "Ladakh Ride" — Leh, India, 9 Oct 2026 to 17 Oct 2026, upcoming
- "Rome in Spring" — Rome, Italy, 23 Oct 2026 to 27 Oct 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 31 Aug 2025 to 8 Sep 2025, finished
Question: what's missing from the previous trip

### Response
{"topic":"gaps","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 22 May 2026 to 26 May 2026, finished
- "Hampi Heritage" — Hampi, India, 2 Oct 2025 to 7 Oct 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 20 Oct 2026 to 26 Oct 2026, upcoming
Question: is trip ke liye kya pack karu?

### Response
{"topic":"advice","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 24 Sep 2026 to 2 Oct 2026, under way now
- "Rome in Spring" — Rome, Italy, 28 Oct 2026 to 4 Nov 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 5 Apr 2027 to 8 Apr 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 4 Sep 2026 to 7 Sep 2026, finished
Question: what are we doing today?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 23 Feb 2027 to 2 Mar 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 28 Nov 2026 to 7 Dec 2026, upcoming
- "Manali Snow Run" — Manali, India, 21 Jan 2026 to 27 Jan 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 13 Jul 2026 to 22 Jul 2026, finished
- "Pondy Chill" — Puducherry, India, 5 Jun 2026 to 11 Jun 2026, finished
Question: What's next on our pondicherry trip?

### Response
{"topic":"schedule","trip":"named","tripTitle":"Pondy Chill","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 13 Mar 2026 to 16 Mar 2026, finished
- "Manali Snow Run" — Manali, India, 7 Mar 2027 to 14 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 15 Apr 2026 to 20 Apr 2026, finished
Question: flight kitne baje hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 14 Dec 2025 to 20 Dec 2025, finished
- "Rome in Spring" — Rome, Italy, 26 Sep 2026 to 29 Sep 2026, under way now
- "Bali Bros" — Bali, Indonesia, 8 Dec 2026 to 12 Dec 2026, upcoming
- "Hampi Heritage" — Hampi, India, 3 Feb 2026 to 5 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 25 May 2026 to 28 May 2026, finished
Being discussed: "Rome in Spring"
Question: who paid for the flights on our trip?

### Response
{"topic":"people","trip":"current","tripTitle":"","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 26 Nov 2025 to 3 Dec 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 24 Sep 2026 to 3 Oct 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 20 Jan 2027 to 29 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 28 Apr 2026 to 7 May 2026, finished
Previous question: what's first thing tomorrow morning
Question: kal ka?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 12 Feb 2026 to 15 Feb 2026, finished
- "Udaipur Wedding" — Udaipur, India, 15 Aug 2026 to 20 Aug 2026, finished
- "Pondy Chill" — Puducherry, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Singapore Stopover" — Singapore, 18 Jan 2027 to 24 Jan 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 2 Sep 2026 to 9 Sep 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 14 Mar 2026 to 20 Mar 2026, finished
Being discussed: "Pondy Chill"
Question: kisi se settle karna baaki hai kya?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 10 May 2026 to 19 May 2026, finished
- "Thailand Trip" — Phuket, Thailand, 15 Feb 2027 to 20 Feb 2027, upcoming
Being discussed: "Meghalaya Monsoon"
Question: theek hai, thanks

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 24 Sep 2026 to 27 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 27 Dec 2026 to 30 Dec 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 21 Mar 2027 to 26 Mar 2027, upcoming
- "Ladakh Ride" — Leh, India, 27 Mar 2027 to 31 Mar 2027, upcoming
- "Goa Getaway" — Goa, India, 19 Jan 2027 to 23 Jan 2027, upcoming
Being discussed: "Rishikesh Rafting"
Question: where did all the money go

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 17 Aug 2026 to 23 Aug 2026, finished
- "Pondy Chill" — Puducherry, India, 11 Nov 2026 to 13 Nov 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 27 Sep 2026 to 29 Sep 2026, under way now
- "Ladakh Ride" — Leh, India, 29 Jul 2026 to 7 Aug 2026, finished
Question: where are we staying on the Dubai Long Weekend trip

### Response
{"topic":"bookings","trip":"named","tripTitle":"Dubai Long Weekend","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 15 Apr 2027 to 24 Apr 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 21 Aug 2026 to 27 Aug 2026, finished
- "Singapore Stopover" — Singapore, 24 Sep 2026 to 28 Sep 2026, under way now
- "Ladakh Ride" — Leh, India, 3 Oct 2026 to 7 Oct 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 18 Jan 2026 to 25 Jan 2026, finished
- "Pondy Chill" — Puducherry, India, 16 Mar 2026 to 22 Mar 2026, finished
Question: sabse mehengi trip kaunsi thi?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 24 May 2026 to 31 May 2026, finished
- "Singapore Stopover" — Singapore, 25 Sep 2026 to 4 Oct 2026, under way now
- "Bali Bros" — Bali, Indonesia, 16 Dec 2025 to 25 Dec 2025, finished
- "Paris Escape" — Paris, France, 5 Jan 2027 to 9 Jan 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 3 Apr 2027 to 11 Apr 2027, upcoming
- "Hampi Heritage" — Hampi, India, 12 Nov 2026 to 20 Nov 2026, upcoming
Question: what's the damage on dinners?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 30 Dec 2026 to 5 Jan 2027, upcoming
- "Manali Snow Run" — Manali, India, 24 Jan 2027 to 27 Jan 2027, upcoming
Being discussed: "Kerala Backwaters"
Previous question: who paid for dinner last night?
Question: aur next trip mein?

### Response
{"topic":"people","trip":"next","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 1 Dec 2025 to 7 Dec 2025, finished
- "Goa Getaway" — Goa, India, 26 Nov 2026 to 30 Nov 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 22 Mar 2027 to 28 Mar 2027, upcoming
- "Pondy Chill" — Puducherry, India, 27 Sep 2026 to 29 Sep 2026, under way now
Previous question: budget se upar toh nahi gaye?
Question: aur kerala wali trip mein

### Response
{"topic":"spending","trip":"named","tripTitle":"Kerala Backwaters","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 30 Oct 2026 to 6 Nov 2026, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 14 Oct 2025 to 18 Oct 2025, finished
- "Singapore Stopover" — Singapore, 13 Feb 2027 to 18 Feb 2027, upcoming
- "Paris Escape" — Paris, France, 14 Aug 2026 to 20 Aug 2026, finished
- "Manali Snow Run" — Manali, India, 25 Sep 2026 to 28 Sep 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 9 Oct 2026 to 18 Oct 2026, upcoming
Being discussed: "Manali Snow Run"
Question: who owes whom on the rishikesh rafting trip?

### Response
{"topic":"balance","trip":"named","tripTitle":"Rishikesh Rafting","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 15 Apr 2026 to 20 Apr 2026, finished
- "Manali Snow Run" — Manali, India, 11 Aug 2026 to 19 Aug 2026, finished
- "Bali Bros" — Bali, Indonesia, 18 Feb 2026 to 23 Feb 2026, finished
- "Ladakh Ride" — Leh, India, 25 Sep 2026 to 4 Oct 2026, under way now
Question: is anything not booked yet for our trip?

### Response
{"topic":"gaps","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 24 Nov 2026 to 29 Nov 2026, upcoming
- "Pondy Chill" — Puducherry, India, 10 Feb 2027 to 13 Feb 2027, upcoming
- "Paris Escape" — Paris, France, 25 Sep 2026 to 30 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 5 Dec 2025 to 11 Dec 2025, finished
Being discussed: "Paris Escape"
Question: which was my cheapest trip

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 26 Aug 2026 to 28 Aug 2026, finished
- "Thailand Trip" — Phuket, Thailand, 20 Sep 2025 to 26 Sep 2025, finished
- "Coorg Coffee Trail" — Coorg, India, 5 Oct 2025 to 12 Oct 2025, finished
- "Singapore Stopover" — Singapore, 25 Sep 2026 to 1 Oct 2026, under way now
Question: Aditi ka udhaar kitna hai

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Aditi","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 10 Jun 2026 to 14 Jun 2026, finished
- "Manali Snow Run" — Manali, India, 6 Mar 2026 to 14 Mar 2026, finished
- "Pondy Chill" — Puducherry, India, 26 Sep 2026 to 29 Sep 2026, under way now
Being discussed: "Pondy Chill"
Question: anything planned for dinner tomorrow?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 1 Mar 2027 to 6 Mar 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 22 Nov 2026 to 28 Nov 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 16 Mar 2026 to 24 Mar 2026, finished
- "Ladakh Ride" — Leh, India, 13 Sep 2025 to 16 Sep 2025, finished
- "Jaipur Weekend" — Jaipur, India, 21 Dec 2025 to 26 Dec 2025, finished
Question: what time is the airport pickup today

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 16 Nov 2026 to 22 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Singapore Stopover" — Singapore, 6 Dec 2025 to 8 Dec 2025, finished
- "Manali Snow Run" — Manali, India, 2 Nov 2026 to 5 Nov 2026, upcoming
- "Ladakh Ride" — Leh, India, 22 Feb 2027 to 24 Feb 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 1 May 2026 to 8 May 2026, finished
Question: What trips do I have coming up?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Thailand Trip" — Phuket, Thailand, 23 Nov 2026 to 25 Nov 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 24 May 2026 to 26 May 2026, finished
- "Jaipur Weekend" — Jaipur, India, 25 Nov 2025 to 4 Dec 2025, finished
Previous question: what time is hotel check-in tomorrow?
Question: what about tomorrow?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 26 Sep 2026 to 28 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 18 Mar 2027 to 25 Mar 2027, upcoming
- "Tokyo 2026" — Tokyo, Japan, 27 Nov 2026 to 3 Dec 2026, upcoming
- "Manali Snow Run" — Manali, India, 7 Feb 2027 to 12 Feb 2027, upcoming
Question: which trip cost the most?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 18 May 2026 to 26 May 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 12 Jul 2026 to 20 Jul 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 19 Dec 2025 to 28 Dec 2025, finished
- "Manali Snow Run" — Manali, India, 13 Apr 2027 to 18 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 1 Feb 2027 to 8 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 1 Oct 2026, under way now
Being discussed: "Udaipur Wedding"
Question: what's next on our last trip?

### Response
{"topic":"schedule","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 31 Aug 2025 to 7 Sep 2025, finished
- "Thailand Trip" — Phuket, Thailand, 6 Feb 2026 to 11 Feb 2026, finished
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 5 Oct 2026, under way now
Question: how much have we spent today?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 21 Mar 2027 to 30 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 18 Dec 2026 to 21 Dec 2026, upcoming
- "Thailand Trip" — Phuket, Thailand, 31 May 2026 to 9 Jun 2026, finished
- "Hampi Heritage" — Hampi, India, 4 Jul 2026 to 8 Jul 2026, finished
Question: aage kaunsi trips hain

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 16 Aug 2026 to 20 Aug 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 1 Apr 2026 to 5 Apr 2026, finished
- "Ladakh Ride" — Leh, India, 26 Jul 2026 to 31 Jul 2026, finished
- "Jaipur Weekend" — Jaipur, India, 1 Dec 2026 to 3 Dec 2026, upcoming
Question: sneha ka udhaar kitna hai?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Sneha","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 11 Sep 2025 to 15 Sep 2025, finished
- "Hampi Heritage" — Hampi, India, 26 Feb 2027 to 2 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 6 Jan 2027 to 12 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 25 Feb 2027 to 3 Mar 2027, upcoming
- "Paris Escape" — Paris, France, 30 Aug 2026 to 3 Sep 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 27 Sep 2026 to 1 Oct 2026, under way now
Question: am I even with Rahul?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Rahul","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 27 Sep 2026 to 2 Oct 2026, under way now
- "Hampi Heritage" — Hampi, India, 6 Sep 2026 to 14 Sep 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 27 Dec 2026 to 5 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 7 Mar 2027 to 10 Mar 2027, upcoming
Being discussed: "Ladakh Ride"
Question: what should I pack for our trip

### Response
{"topic":"advice","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 28 Dec 2026 to 2 Jan 2027, upcoming
- "Rome in Spring" — Rome, Italy, 15 Feb 2026 to 21 Feb 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 23 Sep 2025 to 30 Sep 2025, finished
Question: sabse mehenga kya tha Meghalaya Monsoon mein?

### Response
{"topic":"spending","trip":"named","tripTitle":"Meghalaya Monsoon","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 30 Aug 2025 to 2 Sep 2025, finished
- "Kerala Backwaters" — Alleppey, India, 17 Nov 2026 to 26 Nov 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 2 Nov 2025 to 6 Nov 2025, finished
Question: what's my balance across all trips?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 24 Oct 2026 to 30 Oct 2026, upcoming
- "Singapore Stopover" — Singapore, 24 Mar 2026 to 30 Mar 2026, finished
- "Hampi Heritage" — Hampi, India, 8 Jun 2026 to 11 Jun 2026, finished
- "Ladakh Ride" — Leh, India, 17 Nov 2026 to 20 Nov 2026, upcoming
Being discussed: "Pondy Chill"
Question: how many days is our trip?

### Response
{"topic":"overview","trip":"current","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 24 Sep 2026 to 2 Oct 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 26 Sep 2025 to 28 Sep 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 6 Apr 2027 to 8 Apr 2027, upcoming
- "Pondy Chill" — Puducherry, India, 3 Oct 2025 to 12 Oct 2025, finished
- "Goa Getaway" — Goa, India, 5 Sep 2025 to 9 Sep 2025, finished
- "Bali Bros" — Bali, Indonesia, 6 Nov 2025 to 11 Nov 2025, finished
Question: aaj kitna kharcha ho gaya

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Bali Bros" — Bali, Indonesia, 20 Mar 2026 to 26 Mar 2026, finished
- "Ladakh Ride" — Leh, India, 29 Nov 2026 to 5 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 26 Dec 2026 to 1 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 14 Aug 2026 to 16 Aug 2026, finished
- "Goa Getaway" — Goa, India, 8 Nov 2026 to 12 Nov 2026, upcoming
Previous question: Ladakh Ride wali trip mein kaun kaun aa raha hai?
Question: Kal ka?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 6 Nov 2025 to 11 Nov 2025, finished
- "Kerala Backwaters" — Alleppey, India, 6 Jan 2027 to 13 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 4 Sep 2026 to 13 Sep 2026, finished
- "Hampi Heritage" — Hampi, India, 14 Dec 2025 to 19 Dec 2025, finished
Question: which was my cheapest trip

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Pondy Chill" — Puducherry, India, 26 Sep 2026 to 29 Sep 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 26 Sep 2025 to 5 Oct 2025, finished
- "Ladakh Ride" — Leh, India, 20 Oct 2025 to 24 Oct 2025, finished
Being discussed: "Pondy Chill"
Question: isha ne ab tak kitna pay kiya?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"Isha","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 10 Jan 2026 to 17 Jan 2026, finished
- "Jaipur Weekend" — Jaipur, India, 5 Oct 2026 to 14 Oct 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 13 Jul 2026 to 16 Jul 2026, finished
Question: what time is the airport pickup today

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 7 May 2026 to 9 May 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 21 Aug 2026 to 26 Aug 2026, finished
- "Bali Bros" — Bali, Indonesia, 27 Oct 2026 to 5 Nov 2026, upcoming
- "Rome in Spring" — Rome, Italy, 25 May 2026 to 1 Jun 2026, finished
- "Kerala Backwaters" — Alleppey, India, 9 Jan 2026 to 11 Jan 2026, finished
- "Pondy Chill" — Puducherry, India, 22 Jun 2026 to 29 Jun 2026, finished
Question: is dev on the hampi trip?

### Response
{"topic":"people","trip":"named","tripTitle":"Hampi Heritage","category":"anything","person":"Dev","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 7 May 2026 to 13 May 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 16 Mar 2026 to 18 Mar 2026, finished
- "Pondy Chill" — Puducherry, India, 22 May 2026 to 26 May 2026, finished
Question: when does the train leave?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"train","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 16 Feb 2027 to 23 Feb 2027, upcoming
- "Manali Snow Run" — Manali, India, 27 Dec 2026 to 31 Dec 2026, upcoming
- "Udaipur Wedding" — Udaipur, India, 10 Oct 2025 to 19 Oct 2025, finished
- "Pondy Chill" — Puducherry, India, 4 Mar 2026 to 10 Mar 2026, finished
Question: kisi se settle karna baaki hai kya?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 25 Jan 2027 to 29 Jan 2027, upcoming
- "Pondy Chill" — Puducherry, India, 28 Nov 2025 to 30 Nov 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 13 Jun 2026 to 15 Jun 2026, finished
- "Hampi Heritage" — Hampi, India, 27 Sep 2026 to 3 Oct 2026, under way now
Being discussed: "Hampi Heritage"
Question: best things to do in Hampi?

### Response
{"topic":"advice","trip":"named","tripTitle":"Hampi Heritage","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 13 Nov 2025 to 21 Nov 2025, finished
- "Paris Escape" — Paris, France, 25 Sep 2026 to 30 Sep 2026, under way now
- "Bali Bros" — Bali, Indonesia, 10 Aug 2026 to 18 Aug 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 24 Dec 2026 to 27 Dec 2026, upcoming
- "Tokyo 2026" — Tokyo, Japan, 26 Jul 2026 to 31 Jul 2026, finished
- "Singapore Stopover" — Singapore, 12 Jan 2026 to 15 Jan 2026, finished
Question: what's next on our Bali trip?

### Response
{"topic":"schedule","trip":"named","tripTitle":"Bali Bros","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 17 Oct 2025 to 25 Oct 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 16 Dec 2025 to 21 Dec 2025, finished
- "Hampi Heritage" — Hampi, India, 25 Sep 2026 to 29 Sep 2026, under way now
- "Thailand Trip" — Phuket, Thailand, 12 Jan 2027 to 17 Jan 2027, upcoming
- "Pondy Chill" — Puducherry, India, 22 Oct 2025 to 28 Oct 2025, finished
- "Paris Escape" — Paris, France, 19 Nov 2026 to 23 Nov 2026, upcoming
Question: theek hai, thanks

### Response
{"topic":"chat","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 25 Sep 2026 to 29 Sep 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 1 Feb 2027 to 7 Feb 2027, upcoming
- "Hampi Heritage" — Hampi, India, 18 Feb 2027 to 21 Feb 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 24 Jan 2027 to 31 Jan 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 16 Feb 2027 to 20 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 28 Feb 2026 to 6 Mar 2026, finished
Question: do i need to settle up with anyone

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 13 May 2026 to 18 May 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 26 Sep 2026 to 4 Oct 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 14 Oct 2025 to 22 Oct 2025, finished
- "Ladakh Ride" — Leh, India, 2 Oct 2026 to 4 Oct 2026, upcoming
- "Kerala Backwaters" — Alleppey, India, 11 Sep 2025 to 19 Sep 2025, finished
Question: kitni trips ho gayi ab tak?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 27 Oct 2025 to 29 Oct 2025, finished
- "Paris Escape" — Paris, France, 19 Sep 2025 to 22 Sep 2025, finished
- "Thailand Trip" — Phuket, Thailand, 2 Sep 2025 to 4 Sep 2025, finished
- "Manali Snow Run" — Manali, India, 14 Jan 2027 to 19 Jan 2027, upcoming
Question: which trip cost the most

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 24 Apr 2026 to 1 May 2026, finished
- "Bali Bros" — Bali, Indonesia, 4 Oct 2026 to 9 Oct 2026, upcoming
- "Pondy Chill" — Puducherry, India, 23 Nov 2026 to 1 Dec 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 16 Mar 2027 to 22 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 1 Sep 2026 to 6 Sep 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 10 Nov 2026 to 17 Nov 2026, upcoming
Question: aaj check-in kitne baje hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"stay","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 26 May 2026 to 4 Jun 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 22 Dec 2025 to 30 Dec 2025, finished
- "Bali Bros" — Bali, Indonesia, 21 Dec 2025 to 30 Dec 2025, finished
Question: Bali Bros wali trip mein kuch book karna baaki hai?

### Response
{"topic":"gaps","trip":"named","tripTitle":"Bali Bros","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 10 Dec 2026 to 15 Dec 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 18 Nov 2026 to 25 Nov 2026, upcoming
- "Ladakh Ride" — Leh, India, 21 Aug 2026 to 24 Aug 2026, finished
- "Rishikesh Rafting" — Rishikesh, India, 27 Sep 2026 to 4 Oct 2026, under way now
Question: have we booked a way to get there?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 1 Mar 2027 to 8 Mar 2027, upcoming
- "Ladakh Ride" — Leh, India, 24 Sep 2026 to 2 Oct 2026, under way now
- "Udaipur Wedding" — Udaipur, India, 29 Mar 2027 to 2 Apr 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 8 Jan 2027 to 16 Jan 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 21 Dec 2026 to 29 Dec 2026, upcoming
Question: sabse mehenga kya tha Paris Escape mein

### Response
{"topic":"spending","trip":"named","tripTitle":"Paris Escape","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 22 Jan 2026 to 31 Jan 2026, finished
- "Udaipur Wedding" — Udaipur, India, 4 Apr 2027 to 13 Apr 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 8 Dec 2025 to 10 Dec 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 24 Sep 2026 to 26 Sep 2026, under way now
- "Meghalaya Monsoon" — Shillong, India, 30 Aug 2025 to 8 Sep 2025, finished
Question: Airport pickup book hai kya?

### Response
{"topic":"bookings","trip":"unspecified","tripTitle":"","category":"transfer","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 27 Mar 2026 to 1 Apr 2026, finished
- "Manali Snow Run" — Manali, India, 27 Sep 2026 to 1 Oct 2026, under way now
- "Hampi Heritage" — Hampi, India, 2 Sep 2026 to 11 Sep 2026, finished
Being discussed: "Manali Snow Run"
Question: Hampi Heritage ka summary batao

### Response
{"topic":"overview","trip":"named","tripTitle":"Hampi Heritage","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 26 Jan 2027 to 1 Feb 2027, upcoming
- "Thailand Trip" — Phuket, Thailand, 24 Jun 2026 to 3 Jul 2026, finished
- "Kerala Backwaters" — Alleppey, India, 9 Nov 2025 to 17 Nov 2025, finished
- "Hampi Heritage" — Hampi, India, 20 Jan 2027 to 27 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 25 Apr 2026 to 1 May 2026, finished
- "Udaipur Wedding" — Udaipur, India, 24 Sep 2026 to 3 Oct 2026, under way now
Being discussed: "Udaipur Wedding"
Question: leela ko kitna dena hai

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Leela","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 27 Oct 2025 to 5 Nov 2025, finished
- "Rishikesh Rafting" — Rishikesh, India, 8 Nov 2026 to 10 Nov 2026, upcoming
- "Bali Bros" — Bali, Indonesia, 12 May 2026 to 20 May 2026, finished
Previous question: is anything not booked yet for our Bali trip?
Question: and the other one

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rome in Spring" — Rome, Italy, 6 Feb 2027 to 10 Feb 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 16 Nov 2026 to 24 Nov 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 26 Sep 2026 to 3 Oct 2026, under way now
- "Hampi Heritage" — Hampi, India, 13 Jan 2026 to 16 Jan 2026, finished
- "Meghalaya Monsoon" — Shillong, India, 15 Aug 2026 to 22 Aug 2026, finished
Question: where are we staying on the next trip?

### Response
{"topic":"bookings","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 30 Sep 2025 to 6 Oct 2025, finished
- "Rome in Spring" — Rome, Italy, 8 Apr 2026 to 12 Apr 2026, finished
- "Udaipur Wedding" — Udaipur, India, 10 Apr 2027 to 15 Apr 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 27 Sep 2026 to 3 Oct 2026, under way now
Being discussed: "Coorg Coffee Trail"
Question: agli trip mein kaun kaun aa raha hai?

### Response
{"topic":"people","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Tokyo 2026" — Tokyo, Japan, 12 Jan 2027 to 20 Jan 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 30 Jun 2026 to 3 Jul 2026, finished
- "Bali Bros" — Bali, Indonesia, 14 Nov 2026 to 22 Nov 2026, upcoming
- "Meghalaya Monsoon" — Shillong, India, 20 Oct 2025 to 28 Oct 2025, finished
- "Dubai Long Weekend" — Dubai, UAE, 3 Apr 2027 to 10 Apr 2027, upcoming
Previous question: flight kitne baje hai?
Question: aur Udaipur Wedding wali trip mein?

### Response
{"topic":"schedule","trip":"named","tripTitle":"Udaipur Wedding","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Rome in Spring" — Rome, Italy, 13 Sep 2025 to 18 Sep 2025, finished
- "Thailand Trip" — Phuket, Thailand, 29 Dec 2026 to 1 Jan 2027, upcoming
- "Ladakh Ride" — Leh, India, 2 Apr 2027 to 9 Apr 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 10 Dec 2026 to 14 Dec 2026, upcoming
- "Pondy Chill" — Puducherry, India, 21 Dec 2026 to 28 Dec 2026, upcoming
Question: is Rome safe at night?

### Response
{"topic":"advice","trip":"named","tripTitle":"Rome in Spring","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Meghalaya Monsoon" — Shillong, India, 28 Jan 2027 to 2 Feb 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 24 Sep 2026 to 30 Sep 2026, under way now
- "Hampi Heritage" — Hampi, India, 24 Oct 2026 to 26 Oct 2026, upcoming
Being discussed: "Dubai Long Weekend"
Previous question: dinner ka bill kisne bhara?
Question: kal ka

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Paris Escape" — Paris, France, 27 Sep 2026 to 5 Oct 2026, under way now
- "Manali Snow Run" — Manali, India, 23 Oct 2026 to 29 Oct 2026, upcoming
- "Goa Getaway" — Goa, India, 27 Dec 2026 to 3 Jan 2027, upcoming
- "Pondy Chill" — Puducherry, India, 28 Oct 2026 to 30 Oct 2026, upcoming
Question: What was the most expensive thing on Goa Getaway?

### Response
{"topic":"spending","trip":"named","tripTitle":"Goa Getaway","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Dubai Long Weekend" — Dubai, UAE, 21 Dec 2025 to 24 Dec 2025, finished
- "Rome in Spring" — Rome, Italy, 26 Sep 2026 to 4 Oct 2026, under way now
- "Coorg Coffee Trail" — Coorg, India, 25 Oct 2026 to 3 Nov 2026, upcoming
Being discussed: "Rome in Spring"
Question: what's my balance on the previous trip?

### Response
{"topic":"balance","trip":"previous","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 18 Mar 2027 to 24 Mar 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 25 Apr 2026 to 29 Apr 2026, finished
- "Singapore Stopover" — Singapore, 11 Nov 2026 to 17 Nov 2026, upcoming
Question: have we booked a way to get there?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Coorg Coffee Trail" — Coorg, India, 25 Sep 2026 to 4 Oct 2026, under way now
- "Tokyo 2026" — Tokyo, Japan, 18 Mar 2027 to 25 Mar 2027, upcoming
- "Hampi Heritage" — Hampi, India, 14 Apr 2026 to 22 Apr 2026, finished
- "Paris Escape" — Paris, France, 28 Jun 2026 to 1 Jul 2026, finished
Question: hisaab kitna baaki hai?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Goa Getaway" — Goa, India, 24 Jan 2027 to 1 Feb 2027, upcoming
- "Bali Bros" — Bali, Indonesia, 17 Oct 2026 to 19 Oct 2026, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 22 Nov 2026 to 27 Nov 2026, upcoming
- "Coorg Coffee Trail" — Coorg, India, 21 Dec 2026 to 25 Dec 2026, upcoming
Question: who paid for dinner last night?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"food","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Udaipur Wedding" — Udaipur, India, 18 Jan 2026 to 21 Jan 2026, finished
- "Manali Snow Run" — Manali, India, 10 May 2026 to 18 May 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 25 Dec 2025 to 1 Jan 2026, finished
Question: what's on today's agenda

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"today"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Jaipur Weekend" — Jaipur, India, 23 Dec 2026 to 29 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 21 Oct 2026 to 27 Oct 2026, upcoming
- "Hampi Heritage" — Hampi, India, 27 Sep 2026 to 1 Oct 2026, under way now
Previous question: what did the flights come to?
Question: same for Isha?

### Response
{"topic":"spending","trip":"unspecified","tripTitle":"","category":"flight","person":"Isha","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Kerala Backwaters" — Alleppey, India, 26 Sep 2026 to 1 Oct 2026, under way now
- "Jaipur Weekend" — Jaipur, India, 19 Oct 2026 to 26 Oct 2026, upcoming
- "Rome in Spring" — Rome, Italy, 2 Nov 2026 to 6 Nov 2026, upcoming
- "Paris Escape" — Paris, France, 19 Apr 2026 to 21 Apr 2026, finished
- "Hampi Heritage" — Hampi, India, 5 Jun 2026 to 11 Jun 2026, finished
Being discussed: "Kerala Backwaters"
Question: kitni trips ho gayi ab tak?

### Response
{"topic":"trips","trip":"all","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 24 Mar 2027 to 30 Mar 2027, upcoming
- "Udaipur Wedding" — Udaipur, India, 25 Sep 2026 to 1 Oct 2026, under way now
- "Dubai Long Weekend" — Dubai, UAE, 8 Feb 2026 to 12 Feb 2026, finished
Being discussed: "Udaipur Wedding"
Question: Hampi mein ghoomne ki best jagah kaunsi hai?

### Response
{"topic":"advice","trip":"named","tripTitle":"Hampi Heritage","category":"activity","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 24 Mar 2026 to 27 Mar 2026, finished
- "Hampi Heritage" — Hampi, India, 26 Oct 2025 to 1 Nov 2025, finished
- "Pondy Chill" — Puducherry, India, 24 Sep 2026 to 26 Sep 2026, under way now
- "Manali Snow Run" — Manali, India, 15 Mar 2027 to 19 Mar 2027, upcoming
- "Goa Getaway" — Goa, India, 16 Jul 2026 to 25 Jul 2026, finished
Previous question: how much has Isha paid so far?
Question: and the other one?

### Response
{"topic":"people","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Bali Bros" — Bali, Indonesia, 31 Jul 2026 to 4 Aug 2026, finished
- "Dubai Long Weekend" — Dubai, UAE, 25 Sep 2026 to 29 Sep 2026, under way now
- "Pondy Chill" — Puducherry, India, 30 Nov 2026 to 8 Dec 2026, upcoming
- "Jaipur Weekend" — Jaipur, India, 18 May 2026 to 25 May 2026, finished
- "Udaipur Wedding" — Udaipur, India, 28 Aug 2025 to 5 Sep 2025, finished
- "Tokyo 2026" — Tokyo, Japan, 4 Dec 2026 to 6 Dec 2026, upcoming
Being discussed: "Dubai Long Weekend"
Question: who paid for the flights on our tokyo trip?

### Response
{"topic":"people","trip":"named","tripTitle":"Tokyo 2026","category":"flight","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Hampi Heritage" — Hampi, India, 25 Feb 2027 to 2 Mar 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 31 Jan 2027 to 2 Feb 2027, upcoming
- "Jaipur Weekend" — Jaipur, India, 25 Sep 2026 to 1 Oct 2026, under way now
- "Rishikesh Rafting" — Rishikesh, India, 24 Oct 2026 to 2 Nov 2026, upcoming
Question: does isha owe me anything?

### Response
{"topic":"balance","trip":"unspecified","tripTitle":"","category":"anything","person":"Isha","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Ladakh Ride" — Leh, India, 20 Sep 2025 to 26 Sep 2025, finished
- "Hampi Heritage" — Hampi, India, 9 Jun 2026 to 15 Jun 2026, finished
- "Pondy Chill" — Puducherry, India, 13 Apr 2027 to 20 Apr 2027, upcoming
- "Coorg Coffee Trail" — Coorg, India, 7 Jan 2027 to 14 Jan 2027, upcoming
- "Singapore Stopover" — Singapore, 31 Mar 2026 to 7 Apr 2026, finished
- "Udaipur Wedding" — Udaipur, India, 14 Mar 2026 to 22 Mar 2026, finished
Question: agli trip ke liye kya pack karu?

### Response
{"topic":"advice","trip":"next","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Singapore Stopover" — Singapore, 28 Jan 2027 to 6 Feb 2027, upcoming
- "Hampi Heritage" — Hampi, India, 6 Dec 2026 to 13 Dec 2026, upcoming
- "Paris Escape" — Paris, France, 28 May 2026 to 1 Jun 2026, finished
- "Bali Bros" — Bali, Indonesia, 26 Feb 2026 to 6 Mar 2026, finished
- "Kerala Backwaters" — Alleppey, India, 21 Dec 2025 to 25 Dec 2025, finished
- "Ladakh Ride" — Leh, India, 19 Mar 2027 to 27 Mar 2027, upcoming
Previous question: have we booked a way to get there?
Question: and the other one?

### Response
{"topic":"gaps","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Rishikesh Rafting" — Rishikesh, India, 31 Mar 2027 to 7 Apr 2027, upcoming
- "Paris Escape" — Paris, France, 6 Mar 2027 to 12 Mar 2027, upcoming
- "Hampi Heritage" — Hampi, India, 10 Mar 2027 to 17 Mar 2027, upcoming
- "Rome in Spring" — Rome, Italy, 2 Mar 2027 to 11 Mar 2027, upcoming
Question: when is the rome in spring trip?

### Response
{"topic":"overview","trip":"named","tripTitle":"Rome in Spring","category":"anything","person":"","day":"anyDay"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 18 Jun 2026 to 26 Jun 2026, finished
- "Thailand Trip" — Phuket, Thailand, 10 Apr 2026 to 16 Apr 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 29 Mar 2027 to 3 Apr 2027, upcoming
- "Kerala Backwaters" — Alleppey, India, 30 Jul 2026 to 4 Aug 2026, finished
- "Tokyo 2026" — Tokyo, Japan, 25 Mar 2027 to 28 Mar 2027, upcoming
Question: kal subah sabse pehle kya hai?

### Response
{"topic":"schedule","trip":"unspecified","tripTitle":"","category":"anything","person":"","day":"tomorrow"}

### Instruction
You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish.

Trips:
- "Manali Snow Run" — Manali, India, 2 Mar 2027 to 8 Mar 2027, upcoming
- "Rishikesh Rafting" — Rishikesh, India, 21 Mar 2027 to 30 Mar 2027, upcoming
- "Dubai Long Weekend" — Dubai, UAE, 28 Dec 2026 to 4 Jan 2027, upcoming
- "Meghalaya Monsoon" — Shillong, India, 1 Apr 2026 to 5 Apr 2026, finished
- "Coorg Coffee Trail" — Coorg, India, 25 Sep 2026 to 29 Sep 2026, under way now
- "Singapore Stopover" — Singapore, 17 Oct 2026 to 24 Oct 2026, upcoming
Question: how much do I get back from the Singapore Stopover trip?

### Response
{"topic":"balance","trip":"named","tripTitle":"Singapore Stopover","category":"anything","person":"","day":"anyDay"}
