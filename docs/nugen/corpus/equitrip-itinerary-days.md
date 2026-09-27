# Equitrip · itinerary day reading — worked examples

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 1 · Arrival.
It has 3 rows.

09:50 | Singapore Airlines SQ 9987 Chennai → Leh
1315 hrs: Ola to The Leela Palace
13:45 – Lunch at Ichiran

### Response
{"items":[{"title":"Flight SQ 9987","time":"09:50","kind":"flight"},{"title":"Ola ride","time":"13:15","kind":"transfer"},{"title":"Lunch at Ichiran","time":"13:45","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
It has 4 rows.

08:00 Airport drop to Changi
8:15 PM: Dinner Thalassa
20:45 Amber Fort visit, meet at lobby
Lunch break

### Response
{"items":[{"title":"Airport drop","time":"08:00","kind":"transfer"},{"title":"Dinner Thalassa","time":"20:15","kind":"meal"},{"title":"Amber Fort visit","time":"20:45","kind":"activity"},{"title":"Lunch","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 3.
It has 5 rows.

11:00 AM | Coffee plantation walk, meet at lobby
16:00 | Board Ashram Express 12916 at Leh
18:10 Elephant Falls visit — 4 pax
22.30 Welcome dinner at Britto's
Scuba diving at Grande Island (guide included)

### Response
{"items":[{"title":"Coffee plantation walk","time":"11:00","kind":"activity"},{"title":"Ashram Express 12916","time":"16:00","kind":"train"},{"title":"Elephant Falls visit","time":"18:10","kind":"activity"},{"title":"Welcome dinner","time":"22:30","kind":"meal"},{"title":"Scuba diving at Grande Island","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
This day: Day 3 · Arrival.
It has 4 rows.

09:15 – Currency exchange at Thomas Cook
09:15 | Group photo at the resort
16.00 | Airport transfer Mopa Airport to Lemon Tree Premier
8:00 PM | Dinner Paragon

### Response
{"items":[{"title":"Currency exchange","time":"09:15","kind":"other"},{"title":"Group photo","time":"09:15","kind":"other"},{"title":"Airport transfer","time":"16:00","kind":"transfer"},{"title":"Dinner Paragon","time":"20:00","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 1 · Sightseeing.
It has 6 rows.

6:30 AM: Flight SG 8598 Singapore to Leh
07:45 – Sunset cruise on Mandovi, meet at lobby
08:00 – Flight AI 9515 Udaipur to Singapore
15.00 Buffer time
17:00 – Airport drop to Terminal 3
8:00 PM – Cab pickup from Ahilya by the Sea

### Response
{"items":[{"title":"Flight SG 8598","time":"06:30","kind":"flight"},{"title":"Sunset cruise on Mandovi","time":"07:45","kind":"activity"},{"title":"Flight AI 9515","time":"08:00","kind":"flight"},{"title":"Buffer time","time":"15:00","kind":"other"},{"title":"Airport drop","time":"17:00","kind":"transfer"},{"title":"Cab pickup","time":"20:00","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
It has 6 rows.

07:30 | Group photo at the resort
11:15 – Vatican Museums tour (guide included)
1:30 PM Ganga aarti at Triveni Ghat
14:45 – Lunch break
19:00: Ubud rice terraces, meet at lobby
8:10 PM – Buffer time

### Response
{"items":[{"title":"Group photo","time":"07:30","kind":"other"},{"title":"Vatican Museums tour","time":"11:15","kind":"activity"},{"title":"Ganga aarti at Triveni Ghat","time":"13:30","kind":"activity"},{"title":"Lunch","time":"14:45","kind":"meal"},{"title":"Ubud rice terraces","time":"19:00","kind":"activity"},{"title":"Buffer time","time":"20:10","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 3 · Arrival.
It has 2 rows.

1415 hrs: IndiGo 6E 3271 Phuket → Leh
21:10 Dinner Le Cafe

### Response
{"items":[{"title":"Flight 6E 3271","time":"14:15","kind":"flight"},{"title":"Dinner Le Cafe","time":"21:10","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Phuket, Thailand.
This day: Day 1 · Departure.
It has 7 rows.

6:10 AM Colosseum guided tour
9:00 AM – Paragliding at Solang Valley, meet at lobby
15:10 – Shatabdi Express (12009) dep Chennai, 3A, PNR confirmed
21:00 | Sunset cruise on Mandovi — 4 pax
22.00 | Old Town walking tour — 4 pax
10:15 PM: Welcome dinner at Trattoria da Enzo
Check in at Hotel Artemide

### Response
{"items":[{"title":"Colosseum guided tour","time":"06:10","kind":"activity"},{"title":"Paragliding at Solang Valley","time":"09:00","kind":"activity"},{"title":"Shatabdi Express 12009","time":"15:10","kind":"train"},{"title":"Sunset cruise on Mandovi","time":"21:00","kind":"activity"},{"title":"Old Town walking tour","time":"22:00","kind":"activity"},{"title":"Welcome dinner","time":"22:15","kind":"meal"},{"title":"Hotel Artemide","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 8 · Arrival.
It has 2 rows.

07:10: Flight UK 7662 (Hyderabad–Bangkok), web check-in done
1:00 PM | Lunch at Ichiran

### Response
{"items":[{"title":"Flight UK 7662","time":"07:10","kind":"flight"},{"title":"Lunch at Ichiran","time":"13:00","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
This day: Day 5 · Sightseeing.
It has 5 rows.

0610 hrs Airport drop to Dabolim Airport
12.00: Lunch break
15:15 – Ola to OYO Townhouse 142
18:45 | Ferry to Phi Phi
7:00 PM: Scooter rental for the day

### Response
{"items":[{"title":"Airport drop","time":"06:10","kind":"transfer"},{"title":"Lunch","time":"12:00","kind":"meal"},{"title":"Ola ride","time":"15:15","kind":"transfer"},{"title":"Ferry","time":"18:45","kind":"transfer"},{"title":"Scooter rental","time":"19:00","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 6 · Sightseeing.
It has 6 rows.

5:30 AM – teamLab Planets, meet at lobby
13:30: Phi Phi island hopping, meet at lobby
1550 hrs Cab pickup from Taj Holiday Village
20:30 | Hotel check-in: OYO Townhouse 142
21:00: Board Ashram Express 12916 at Mumbai
Airport transfer Fiumicino to Treebo Trend Cosmo

### Response
{"items":[{"title":"teamLab Planets","time":"05:30","kind":"activity"},{"title":"Phi Phi island hopping","time":"13:30","kind":"activity"},{"title":"Cab pickup","time":"15:50","kind":"transfer"},{"title":"OYO Townhouse 142","time":"20:30","kind":"stay"},{"title":"Ashram Express 12916","time":"21:00","kind":"train"},{"title":"Airport transfer","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
It has 3 rows.

1:50 PM: teamLab Planets — 4 pax
15:10 | Railway station drop, Jaipur Junction
16:00 | Free time for shopping at Anjuna market

### Response
{"items":[{"title":"teamLab Planets","time":"13:50","kind":"activity"},{"title":"Station drop","time":"15:10","kind":"transfer"},{"title":"Free time","time":"16:00","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Phuket, Thailand.
This day: Day 3 · Arrival.
It has 3 rows.

08:30 | Check-in Ibis Styles
17:45 Airport drop to Dabolim Airport
Check-in Alsisar Haveli

### Response
{"items":[{"title":"Ibis Styles","time":"08:30","kind":"stay"},{"title":"Airport drop","time":"17:45","kind":"transfer"},{"title":"Alsisar Haveli","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Tokyo, Japan.
This day: Day 3 · Departure.
It has 4 rows.

13:00 Cab pickup from Hotel Artemide
2210 hrs Ferry to Phi Phi
Cab pickup from OYO Townhouse 142
Hotel check-in: The Oberoi Udaivilas

### Response
{"items":[{"title":"Cab pickup","time":"13:00","kind":"transfer"},{"title":"Ferry","time":"22:10","kind":"transfer"},{"title":"Cab pickup","time":"","kind":"transfer"},{"title":"The Oberoi Udaivilas","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 5.
It has 7 rows.

06:00 | Airport drop to Mopa Airport
09:10 | Airport drop to Ngurah Rai Airport
11:10 AM River rafting Shivpuri — 4 pax
13:30: Louvre visit, meet at lobby
21:15 | Cab pickup from The Oberoi Udaivilas
21:30 – Old Town walking tour — 4 pax
Scuba diving at Grande Island

### Response
{"items":[{"title":"Airport drop","time":"06:00","kind":"transfer"},{"title":"Airport drop","time":"09:10","kind":"transfer"},{"title":"River rafting Shivpuri","time":"11:10","kind":"activity"},{"title":"Louvre visit","time":"13:30","kind":"activity"},{"title":"Cab pickup","time":"21:15","kind":"transfer"},{"title":"Old Town walking tour","time":"21:30","kind":"activity"},{"title":"Scuba diving at Grande Island","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 2 · At leisure.
It has 6 rows.

14:30 – Ubud rice terraces, meet at lobby
15:10: Dudhsagar Waterfalls tour (guide included)
17:50 | Depart Goa on UK 4779 to Paris
19.15 | Currency exchange at Thomas Cook
Hotel check-in: Zostel Manali
Welcome dinner at Trattoria da Enzo

### Response
{"items":[{"title":"Ubud rice terraces","time":"14:30","kind":"activity"},{"title":"Dudhsagar Waterfalls tour","time":"15:10","kind":"activity"},{"title":"Flight UK 4779","time":"17:50","kind":"flight"},{"title":"Currency exchange","time":"19:15","kind":"other"},{"title":"Zostel Manali","time":"","kind":"stay"},{"title":"Welcome dinner","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 4 · At leisure.
It has 5 rows.

8:15 AM: Railway station drop, Jaipur Junction
09:00 | Colosseum guided tour (guide included)
10:00 Private taxi to Munnar
13:45 | Train 12432 Trivandrum Rajdhani Hyderabad to Mumbai
22:10 | Farewell dinner

### Response
{"items":[{"title":"Station drop","time":"08:15","kind":"transfer"},{"title":"Colosseum guided tour","time":"09:00","kind":"activity"},{"title":"Private taxi","time":"10:00","kind":"transfer"},{"title":"Trivandrum Rajdhani 12432","time":"13:45","kind":"train"},{"title":"Farewell dinner","time":"22:10","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
This day: Day 1 · Arrival.
It has 2 rows.

1200 hrs | Lunch at Le Cafe
12:00 PM | Colosseum guided tour, meet at lobby

### Response
{"items":[{"title":"Lunch at Le Cafe","time":"12:00","kind":"meal"},{"title":"Colosseum guided tour","time":"12:00","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 1 · Sightseeing.
It has 3 rows.

1550 hrs: Homestay in Mawlynnong
7:30 PM Ola to Zostel Manali
20:50 Ubud rice terraces (guide included)

### Response
{"items":[{"title":"Homestay Mawlynnong","time":"15:50","kind":"stay"},{"title":"Ola ride","time":"19:30","kind":"transfer"},{"title":"Ubud rice terraces","time":"20:50","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 7.
It has 5 rows.

09.45: Cab pickup from Ibis Styles
7:00 PM Visa appointment at VFS
22:30: Dudhsagar Waterfalls tour
Ola to Treebo Trend Cosmo
Stay at Ahilya by the Sea

### Response
{"items":[{"title":"Cab pickup","time":"09:45","kind":"transfer"},{"title":"Visa appointment","time":"19:00","kind":"other"},{"title":"Dudhsagar Waterfalls tour","time":"22:30","kind":"activity"},{"title":"Ola ride","time":"","kind":"transfer"},{"title":"Ahilya by the Sea","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 4 · Departure.
It has 2 rows.

07.50 – Dudhsagar Waterfalls tour
Houseboat stay Alleppey

### Response
{"items":[{"title":"Dudhsagar Waterfalls tour","time":"07:50","kind":"activity"},{"title":"Houseboat Alleppey","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 1.
It has 5 rows.

07:30 | Ubud rice terraces (guide included)
10:50 – Ola to Hotel Artemide
16:15 Check-in Lemon Tree Premier
19:00 – Train 12009 Shatabdi Express Kochi to Goa
Ola to Grand Hyatt

### Response
{"items":[{"title":"Ubud rice terraces","time":"07:30","kind":"activity"},{"title":"Ola ride","time":"10:50","kind":"transfer"},{"title":"Lemon Tree Premier","time":"16:15","kind":"stay"},{"title":"Shatabdi Express 12009","time":"19:00","kind":"train"},{"title":"Ola ride","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 4 · Sightseeing.
It has 2 rows.

1:00 PM | Free time for shopping at Anjuna market
20.10 Dinner Britto's

### Response
{"items":[{"title":"Free time","time":"13:00","kind":"other"},{"title":"Dinner Britto's","time":"20:10","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
This day: Day 8 · Sightseeing.
It has 5 rows.

1710 hrs Amber Fort visit
21:10 | Farewell dinner
21:30 Dinner Fisherman's Wharf
22:15: Private taxi to Nubra Valley
Check-in Hotel Artemide

### Response
{"items":[{"title":"Amber Fort visit","time":"17:10","kind":"activity"},{"title":"Farewell dinner","time":"21:10","kind":"meal"},{"title":"Dinner Fisherman's Wharf","time":"21:30","kind":"meal"},{"title":"Private taxi","time":"22:15","kind":"transfer"},{"title":"Hotel Artemide","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 3 · Arrival.
It has 3 rows.

12:00 Coffee plantation walk, meet at lobby
7:15 PM | Train 16345 Netravati Express Kochi to Bengaluru
22:15: Welcome dinner at Trattoria da Enzo

### Response
{"items":[{"title":"Coffee plantation walk","time":"12:00","kind":"activity"},{"title":"Netravati Express 16345","time":"19:15","kind":"train"},{"title":"Welcome dinner","time":"22:15","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 1 · Sightseeing.
It has 4 rows.

06:45 | Elephant Falls visit (guide included)
08:00 Private taxi to Baga Beach
Buffer time
Check-out OYO Townhouse 142

### Response
{"items":[{"title":"Elephant Falls visit","time":"06:45","kind":"activity"},{"title":"Private taxi","time":"08:00","kind":"transfer"},{"title":"Buffer time","time":"","kind":"other"},{"title":"Check-out OYO Townhouse 142","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
It has 2 rows.

6:15 AM Airport transfer CSMT to Hotel Raas
20:15 – Cab pickup from Treebo Trend Cosmo

### Response
{"items":[{"title":"Airport transfer","time":"06:15","kind":"transfer"},{"title":"Cab pickup","time":"20:15","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 5 · At leisure.
It has 7 rows.

12:50 | Lunch break
1:10 PM: Lunch at Thalassa
14:50 Lunch break
Lunch break
Homestay in Mawlynnong
Currency exchange at Thomas Cook
Stay at Ahilya by the Sea

### Response
{"items":[{"title":"Lunch","time":"12:50","kind":"meal"},{"title":"Lunch at Thalassa","time":"13:10","kind":"meal"},{"title":"Lunch","time":"14:50","kind":"meal"},{"title":"Lunch","time":"","kind":"meal"},{"title":"Homestay Mawlynnong","time":"","kind":"stay"},{"title":"Currency exchange","time":"","kind":"other"},{"title":"Ahilya by the Sea","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 5 · Sightseeing.
It has 6 rows.

05.45 – Desert safari — 4 pax
06:45: Ashram Express (12916) dep Leh, 3A, PNR confirmed
12:50 | Lunch break
13:50 | Ubud rice terraces
19:00: Free time for shopping at Anjuna market
Hotel check-in: Hotel Raas

### Response
{"items":[{"title":"Desert safari","time":"05:45","kind":"activity"},{"title":"Ashram Express 12916","time":"06:45","kind":"train"},{"title":"Lunch","time":"12:50","kind":"meal"},{"title":"Ubud rice terraces","time":"13:50","kind":"activity"},{"title":"Free time","time":"19:00","kind":"other"},{"title":"Hotel Raas","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 1 · Arrival.
It has 3 rows.

8:45 AM – Louvre visit — 4 pax
15:15 – Scooter rental for the day
20:45: Airport drop to Fiumicino

### Response
{"items":[{"title":"Louvre visit","time":"08:45","kind":"activity"},{"title":"Scooter rental","time":"15:15","kind":"transfer"},{"title":"Airport drop","time":"20:45","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 2 · Departure.
It has 5 rows.

10:00 AM: Railway station drop, Jaipur Junction
11:00 | Cab pickup from Hotel Artemide
15:00: Singapore Airlines SQ 7508 Chennai → Udaipur
20:30 Colosseum guided tour (guide included)
Louvre visit (guide included)

### Response
{"items":[{"title":"Station drop","time":"10:00","kind":"transfer"},{"title":"Cab pickup","time":"11:00","kind":"transfer"},{"title":"Flight SQ 7508","time":"15:00","kind":"flight"},{"title":"Colosseum guided tour","time":"20:30","kind":"activity"},{"title":"Louvre visit","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 3 · Arrival.
It has 3 rows.

06.45 Elephant Falls visit
10:00 – Train 12951 Rajdhani Express Jaipur to Leh
3:00 PM Ganga aarti at Triveni Ghat

### Response
{"items":[{"title":"Elephant Falls visit","time":"06:45","kind":"activity"},{"title":"Rajdhani Express 12951","time":"10:00","kind":"train"},{"title":"Ganga aarti at Triveni Ghat","time":"15:00","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Phuket, Thailand.
This day: Day 8 · At leisure.
It has 3 rows.

11:50 Sunset cruise on Mandovi (guide included)
14:15 – Paragliding at Solang Valley (guide included)
Scuba diving at Grande Island (guide included)

### Response
{"items":[{"title":"Sunset cruise on Mandovi","time":"11:50","kind":"activity"},{"title":"Paragliding at Solang Valley","time":"14:15","kind":"activity"},{"title":"Scuba diving at Grande Island","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
This day: Day 6 · At leisure.
It has 4 rows.

09.00 Breakfast at hotel
1215 hrs – Airport drop to Leh Airport
21:30 Farewell dinner
Check-out Taj Holiday Village

### Response
{"items":[{"title":"Hotel breakfast","time":"09:00","kind":"meal"},{"title":"Airport drop","time":"12:15","kind":"transfer"},{"title":"Farewell dinner","time":"21:30","kind":"meal"},{"title":"Check-out Taj Holiday Village","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
It has 6 rows.

07:50 – Scooter rental for the day
16:15: River rafting Shivpuri (guide included)
18:30 Flight UK 5274 (Kochi–Denpasar), web check-in done
Train 16345 Netravati Express Delhi to Goa
Lunch at Britto's
Airport transfer Kempegowda Airport to Ibis Styles

### Response
{"items":[{"title":"Scooter rental","time":"07:50","kind":"transfer"},{"title":"River rafting Shivpuri","time":"16:15","kind":"activity"},{"title":"Flight UK 5274","time":"18:30","kind":"flight"},{"title":"Netravati Express 16345","time":"","kind":"train"},{"title":"Lunch at Britto's","time":"","kind":"meal"},{"title":"Airport transfer","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 6 · Sightseeing.
It has 3 rows.

05:00: Cab pickup from Taj Holiday Village
5:30 PM: Airport transfer CSMT to Evolve Back Coorg
22:00 Free time for shopping at Anjuna market

### Response
{"items":[{"title":"Cab pickup","time":"05:00","kind":"transfer"},{"title":"Airport transfer","time":"17:30","kind":"transfer"},{"title":"Free time","time":"22:00","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Phuket, Thailand.
It has 2 rows.

12:30 | Lunch break
Check-in Treebo Trend Cosmo

### Response
{"items":[{"title":"Lunch","time":"12:30","kind":"meal"},{"title":"Treebo Trend Cosmo","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 1 · At leisure.
It has 4 rows.

07:50 | Hotel breakfast
0830 hrs Train 16345 Netravati Express Chennai to Leh
12:45 PM | Train 22439 Vande Bharat Chennai to Delhi
16:30 | Rest day at leisure

### Response
{"items":[{"title":"Hotel breakfast","time":"07:50","kind":"meal"},{"title":"Netravati Express 16345","time":"08:30","kind":"train"},{"title":"Vande Bharat 22439","time":"12:45","kind":"train"},{"title":"Rest day","time":"16:30","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
This day: Day 7 · Departure.
It has 7 rows.

09:00 | Snorkelling at Havelock, meet at lobby
9:00 AM – Khardung La drive, meet at lobby
12:15 PM | Lunch at Gunpowder
14:30 – Scooter rental for the day
18:50 Cab pickup from Zostel Manali
8:50 PM Dinner Johnny's Cafe
Scuba diving at Grande Island, meet at lobby

### Response
{"items":[{"title":"Snorkelling at Havelock","time":"09:00","kind":"activity"},{"title":"Khardung La drive","time":"09:00","kind":"activity"},{"title":"Lunch at Gunpowder","time":"12:15","kind":"meal"},{"title":"Scooter rental","time":"14:30","kind":"transfer"},{"title":"Cab pickup","time":"18:50","kind":"transfer"},{"title":"Dinner Johnny's Cafe","time":"20:50","kind":"meal"},{"title":"Scuba diving at Grande Island","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 7.
It has 5 rows.

20.00 | Board Shatabdi Express 12009 at Goa
2245 hrs – Dinner Trattoria da Enzo
Air India AI 2086 Tokyo → Rome
Stay at Treebo Trend Cosmo
Airport transfer Dabolim Airport to Grand Hyatt

### Response
{"items":[{"title":"Shatabdi Express 12009","time":"20:00","kind":"train"},{"title":"Dinner Trattoria da Enzo","time":"22:45","kind":"meal"},{"title":"Flight AI 2086","time":"","kind":"flight"},{"title":"Treebo Trend Cosmo","time":"","kind":"stay"},{"title":"Airport transfer","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
It has 6 rows.

06:00 | Desert safari — 4 pax
0745 hrs – Board Netravati Express 16345 at Jaipur
09:00: Breakfast at hotel
8:30 PM: River rafting Shivpuri (guide included)
Check-out The Leela Palace
Airport drop to Leh Airport

### Response
{"items":[{"title":"Desert safari","time":"06:00","kind":"activity"},{"title":"Netravati Express 16345","time":"07:45","kind":"train"},{"title":"Hotel breakfast","time":"09:00","kind":"meal"},{"title":"River rafting Shivpuri","time":"20:30","kind":"activity"},{"title":"Check-out The Leela Palace","time":"","kind":"stay"},{"title":"Airport drop","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 8 · At leisure.
It has 5 rows.

07:50: Hotel breakfast
08.00 Phi Phi island hopping
10:15 | Train 12432 Trivandrum Rajdhani Mumbai to Chennai
1400 hrs | Ola to Grand Hyatt
Airport transfer CSMT to OYO Townhouse 142

### Response
{"items":[{"title":"Hotel breakfast","time":"07:50","kind":"meal"},{"title":"Phi Phi island hopping","time":"08:00","kind":"activity"},{"title":"Trivandrum Rajdhani 12432","time":"10:15","kind":"train"},{"title":"Ola ride","time":"14:00","kind":"transfer"},{"title":"Airport transfer","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 2 · Sightseeing.
It has 4 rows.

09.00: Depart Bengaluru on TG 6095 to Dubai
13:10: Currency exchange at Thomas Cook
2:45 PM – Lunch at Le Cafe
Check-out Hotel Raas

### Response
{"items":[{"title":"Flight TG 6095","time":"09:00","kind":"flight"},{"title":"Currency exchange","time":"13:10","kind":"other"},{"title":"Lunch at Le Cafe","time":"14:45","kind":"meal"},{"title":"Check-out Hotel Raas","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 2 · Arrival.
It has 3 rows.

8:15 AM: Paragliding at Solang Valley, meet at lobby
3:00 PM | Flight QP 9116 Singapore to Paris
21:10 – Dinner Paragon

### Response
{"items":[{"title":"Paragliding at Solang Valley","time":"08:15","kind":"activity"},{"title":"Flight QP 9116","time":"15:00","kind":"flight"},{"title":"Dinner Paragon","time":"21:10","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Tokyo, Japan.
It has 6 rows.

05:50 Check-out Taj Holiday Village
2:00 PM Railway station drop, Haridwar
16:45 | Old Town walking tour — 4 pax
20:45 – Welcome dinner at Johnny's Cafe
22:00 – Desert safari, meet at lobby
Houseboat stay Alleppey

### Response
{"items":[{"title":"Check-out Taj Holiday Village","time":"05:50","kind":"stay"},{"title":"Station drop","time":"14:00","kind":"transfer"},{"title":"Old Town walking tour","time":"16:45","kind":"activity"},{"title":"Welcome dinner","time":"20:45","kind":"meal"},{"title":"Desert safari","time":"22:00","kind":"activity"},{"title":"Houseboat Alleppey","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 7 · Sightseeing.
It has 7 rows.

12:00 Lunch at Karavalli
13.00 Board Ashram Express 12916 at Bengaluru
18:45 | Rest day at leisure
21:45 Cab pickup from Alsisar Haveli
Flight SQ 7812 Singapore to Goa
Free time for shopping at Anjuna market
Stay at Grand Hyatt

### Response
{"items":[{"title":"Lunch at Karavalli","time":"12:00","kind":"meal"},{"title":"Ashram Express 12916","time":"13:00","kind":"train"},{"title":"Rest day","time":"18:45","kind":"other"},{"title":"Cab pickup","time":"21:45","kind":"transfer"},{"title":"Flight SQ 7812","time":"","kind":"flight"},{"title":"Free time","time":"","kind":"other"},{"title":"Grand Hyatt","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 5 · Departure.
It has 6 rows.

06:00 | Rest day at leisure
7:10 AM | Airport drop to Fiumicino
08:50 Breakfast at hotel
3:50 PM – Check-in The Tamara
18:10 – Railway station drop, Madgaon
Vistara UK 3509 Bangkok → Udaipur

### Response
{"items":[{"title":"Rest day","time":"06:00","kind":"other"},{"title":"Airport drop","time":"07:10","kind":"transfer"},{"title":"Hotel breakfast","time":"08:50","kind":"meal"},{"title":"The Tamara","time":"15:50","kind":"stay"},{"title":"Station drop","time":"18:10","kind":"transfer"},{"title":"Flight UK 3509","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
It has 4 rows.

08:30 | Vande Bharat (22439) dep Delhi, 3A, PNR confirmed
10.00 Depart Phuket on 6E 4770 to Mumbai
16:10 Amber Fort visit
8:15 PM | Welcome dinner at Johnny's Cafe

### Response
{"items":[{"title":"Vande Bharat 22439","time":"08:30","kind":"train"},{"title":"Flight 6E 4770","time":"10:00","kind":"flight"},{"title":"Amber Fort visit","time":"16:10","kind":"activity"},{"title":"Welcome dinner","time":"20:15","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 8.
It has 3 rows.

05:15 – Buffer time
8:30 AM: Airport transfer Dabolim Airport to The Tamara
Stay at Evolve Back Coorg

### Response
{"items":[{"title":"Buffer time","time":"05:15","kind":"other"},{"title":"Airport transfer","time":"08:30","kind":"transfer"},{"title":"Evolve Back Coorg","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
It has 2 rows.

09:15 – Private taxi to Munnar
22:15 Farewell dinner

### Response
{"items":[{"title":"Private taxi","time":"09:15","kind":"transfer"},{"title":"Farewell dinner","time":"22:15","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 8 · Departure.
It has 6 rows.

06:10 – Ola to Hotel Raas
06.15: Buffer time
07:30 Ola to Taj Holiday Village
13.15: Desert safari (guide included)
3:30 PM: Depart Tokyo on SG 6664 to Bangkok
17.50 Louvre visit, meet at lobby

### Response
{"items":[{"title":"Ola ride","time":"06:10","kind":"transfer"},{"title":"Buffer time","time":"06:15","kind":"other"},{"title":"Ola ride","time":"07:30","kind":"transfer"},{"title":"Desert safari","time":"13:15","kind":"activity"},{"title":"Flight SG 6664","time":"15:30","kind":"flight"},{"title":"Louvre visit","time":"17:50","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 5 · At leisure.
It has 7 rows.

7:45 AM – Private taxi to Munnar
12:00 PM – Lunch break
22:00 – Dinner Karavalli
22:15: Phi Phi island hopping, meet at lobby
Hotel breakfast
Hotel check-in: Hotel Artemide
Homestay in Mawlynnong

### Response
{"items":[{"title":"Private taxi","time":"07:45","kind":"transfer"},{"title":"Lunch","time":"12:00","kind":"meal"},{"title":"Dinner Karavalli","time":"22:00","kind":"meal"},{"title":"Phi Phi island hopping","time":"22:15","kind":"activity"},{"title":"Hotel breakfast","time":"","kind":"meal"},{"title":"Hotel Artemide","time":"","kind":"stay"},{"title":"Homestay Mawlynnong","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
This day: Day 3 · At leisure.
It has 5 rows.

8:45 AM Depart Mumbai on TG 3715 to Leh
09:30 | Ganga aarti at Triveni Ghat — 4 pax
11:45 Airport transfer T2 to The Leela Palace
Ganga aarti at Triveni Ghat — 4 pax
Airport transfer Mopa Airport to Hotel Raas

### Response
{"items":[{"title":"Flight TG 3715","time":"08:45","kind":"flight"},{"title":"Ganga aarti at Triveni Ghat","time":"09:30","kind":"activity"},{"title":"Airport transfer","time":"11:45","kind":"transfer"},{"title":"Ganga aarti at Triveni Ghat","time":"","kind":"activity"},{"title":"Airport transfer","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 2 · Sightseeing.
It has 4 rows.

07:10 – Elephant Falls visit
19:00 | Welcome dinner at Thalassa
10:10 PM | Scooter rental for the day
Flight EK 8193 Kochi to Udaipur

### Response
{"items":[{"title":"Elephant Falls visit","time":"07:10","kind":"activity"},{"title":"Welcome dinner","time":"19:00","kind":"meal"},{"title":"Scooter rental","time":"22:10","kind":"transfer"},{"title":"Flight EK 8193","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 2 · Sightseeing.
It has 7 rows.

09:45 – Hotel breakfast
10:00 Flight SQ 8681 Paris to Denpasar
11:00 – Ola to The Tamara
11:50 | Flight EK 236 Goa to Mumbai
Stay at The Tamara
Check-out The Oberoi Udaivilas
Check-in Evolve Back Coorg

### Response
{"items":[{"title":"Hotel breakfast","time":"09:45","kind":"meal"},{"title":"Flight SQ 8681","time":"10:00","kind":"flight"},{"title":"Ola ride","time":"11:00","kind":"transfer"},{"title":"Flight EK 236","time":"11:50","kind":"flight"},{"title":"The Tamara","time":"","kind":"stay"},{"title":"Check-out The Oberoi Udaivilas","time":"","kind":"stay"},{"title":"Evolve Back Coorg","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 6.
It has 4 rows.

05:00 | Sunset cruise on Mandovi — 4 pax
07:50: Hotel breakfast
9:00 AM | Phi Phi island hopping (guide included)
11:10 – Amber Fort visit

### Response
{"items":[{"title":"Sunset cruise on Mandovi","time":"05:00","kind":"activity"},{"title":"Hotel breakfast","time":"07:50","kind":"meal"},{"title":"Phi Phi island hopping","time":"09:00","kind":"activity"},{"title":"Amber Fort visit","time":"11:10","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 3 · Sightseeing.
It has 2 rows.

15:15 Flight SQ 9277 Rome to Chennai
Homestay in Mawlynnong

### Response
{"items":[{"title":"Flight SQ 9277","time":"15:15","kind":"flight"},{"title":"Homestay Mawlynnong","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 6.
It has 3 rows.

09:00 Coffee plantation walk (guide included)
20:45: Farewell dinner
Flight SQ 383 Leh to Jaipur

### Response
{"items":[{"title":"Coffee plantation walk","time":"09:00","kind":"activity"},{"title":"Farewell dinner","time":"20:45","kind":"meal"},{"title":"Flight SQ 383","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 2 · Arrival.
It has 3 rows.

10:45 – City Palace tour — 4 pax
20:00: Welcome dinner at Karavalli
Check-in Evolve Back Coorg

### Response
{"items":[{"title":"City Palace tour","time":"10:45","kind":"activity"},{"title":"Welcome dinner","time":"20:00","kind":"meal"},{"title":"Evolve Back Coorg","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 1 · Sightseeing.
It has 7 rows.

10:45 Free time for shopping at Anjuna market
13:00 | Lunch break
1315 hrs | Vatican Museums tour, meet at lobby
15:00 – Colosseum guided tour, meet at lobby
20:15: Farewell dinner
21.45: Scooter rental for the day
Dudhsagar Waterfalls tour — 4 pax

### Response
{"items":[{"title":"Free time","time":"10:45","kind":"other"},{"title":"Lunch","time":"13:00","kind":"meal"},{"title":"Vatican Museums tour","time":"13:15","kind":"activity"},{"title":"Colosseum guided tour","time":"15:00","kind":"activity"},{"title":"Farewell dinner","time":"20:15","kind":"meal"},{"title":"Scooter rental","time":"21:45","kind":"transfer"},{"title":"Dudhsagar Waterfalls tour","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 3 · Departure.
It has 4 rows.

07:15 | Flight EK 4486 (Hyderabad–Denpasar), web check-in done
11:15: Flight QP 9857 (Bangkok–Kochi), web check-in done
1245 hrs | Ola to Taj Holiday Village
13.00 – Cab pickup from Lemon Tree Premier

### Response
{"items":[{"title":"Flight EK 4486","time":"07:15","kind":"flight"},{"title":"Flight QP 9857","time":"11:15","kind":"flight"},{"title":"Ola ride","time":"12:45","kind":"transfer"},{"title":"Cab pickup","time":"13:00","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 1 · At leisure.
It has 2 rows.

13:00: Desert safari (guide included)
20:30: Ferry to Havelock

### Response
{"items":[{"title":"Desert safari","time":"13:00","kind":"activity"},{"title":"Ferry","time":"20:30","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 4 · Sightseeing.
It has 4 rows.

1630 hrs Sunset cruise on Mandovi
Hotel check-in: OYO Townhouse 142
Old Town walking tour
Hotel check-in: Zostel Manali

### Response
{"items":[{"title":"Sunset cruise on Mandovi","time":"16:30","kind":"activity"},{"title":"OYO Townhouse 142","time":"","kind":"stay"},{"title":"Old Town walking tour","time":"","kind":"activity"},{"title":"Zostel Manali","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 8 · Departure.
It has 6 rows.

08:15 – Breakfast at hotel
11:50 – Vatican Museums tour — 4 pax
20:00 Farewell dinner
8:15 PM: Dinner Gunpowder
Homestay in Mawlynnong
Hotel check-in: Lemon Tree Premier

### Response
{"items":[{"title":"Hotel breakfast","time":"08:15","kind":"meal"},{"title":"Vatican Museums tour","time":"11:50","kind":"activity"},{"title":"Farewell dinner","time":"20:00","kind":"meal"},{"title":"Dinner Gunpowder","time":"20:15","kind":"meal"},{"title":"Homestay Mawlynnong","time":"","kind":"stay"},{"title":"Lemon Tree Premier","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 6 · Arrival.
It has 5 rows.

09:15 | Hotel breakfast
1300 hrs | Ferry to Phi Phi
17.00 Scooter rental for the day
Check in at Alsisar Haveli
Stay at Grand Hyatt

### Response
{"items":[{"title":"Hotel breakfast","time":"09:15","kind":"meal"},{"title":"Ferry","time":"13:00","kind":"transfer"},{"title":"Scooter rental","time":"17:00","kind":"transfer"},{"title":"Alsisar Haveli","time":"","kind":"stay"},{"title":"Grand Hyatt","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 5.
It has 4 rows.

0615 hrs | Hotel check-in: The Leela Palace
07:50 – Flight SG 2062 Bangkok to Denpasar
10:15 Board Ashram Express 12916 at Mumbai
4:00 PM: Currency exchange at Thomas Cook

### Response
{"items":[{"title":"The Leela Palace","time":"06:15","kind":"stay"},{"title":"Flight SG 2062","time":"07:50","kind":"flight"},{"title":"Ashram Express 12916","time":"10:15","kind":"train"},{"title":"Currency exchange","time":"16:00","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 1 · Arrival.
It has 4 rows.

1200 hrs: Emirates EK 8670 Singapore → Udaipur
20:00 | Virupaksha Temple visit (guide included)
Breakfast at hotel
Check in at The Tamara

### Response
{"items":[{"title":"Flight EK 8670","time":"12:00","kind":"flight"},{"title":"Virupaksha Temple visit","time":"20:00","kind":"activity"},{"title":"Hotel breakfast","time":"","kind":"meal"},{"title":"The Tamara","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Phuket, Thailand.
It has 5 rows.

7:45 AM: Phi Phi island hopping (guide included)
07:50 | Hotel check-in: OYO Townhouse 142
13.00 | Flight SQ 2959 Paris to Denpasar
7:15 PM – Farewell dinner
20:10 – River rafting Shivpuri, meet at lobby

### Response
{"items":[{"title":"Phi Phi island hopping","time":"07:45","kind":"activity"},{"title":"OYO Townhouse 142","time":"07:50","kind":"stay"},{"title":"Flight SQ 2959","time":"13:00","kind":"flight"},{"title":"Farewell dinner","time":"19:15","kind":"meal"},{"title":"River rafting Shivpuri","time":"20:10","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 6 · At leisure.
It has 6 rows.

6:00 AM: Singapore Airlines SQ 5846 Bengaluru → Singapore
07:00 – Phi Phi island hopping — 4 pax
9:00 AM Flight TG 6744 Bengaluru to Rome
10:45 | Cab pickup from The Tamara
12:15 | Akasa Air QP 5545 Mumbai → Bengaluru
4:00 PM – Private taxi to Rohtang Pass

### Response
{"items":[{"title":"Flight SQ 5846","time":"06:00","kind":"flight"},{"title":"Phi Phi island hopping","time":"07:00","kind":"activity"},{"title":"Flight TG 6744","time":"09:00","kind":"flight"},{"title":"Cab pickup","time":"10:45","kind":"transfer"},{"title":"Flight QP 5545","time":"12:15","kind":"flight"},{"title":"Private taxi","time":"16:00","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
It has 6 rows.

0845 hrs Private taxi to Munnar
12:15 – Lunch break
14:00 – Lunch break
22:00 | Cab pickup from Zostel Manali
2210 hrs: River rafting Shivpuri, meet at lobby
Visa appointment at VFS

### Response
{"items":[{"title":"Private taxi","time":"08:45","kind":"transfer"},{"title":"Lunch","time":"12:15","kind":"meal"},{"title":"Lunch","time":"14:00","kind":"meal"},{"title":"Cab pickup","time":"22:00","kind":"transfer"},{"title":"River rafting Shivpuri","time":"22:10","kind":"activity"},{"title":"Visa appointment","time":"","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 2 · Sightseeing.
It has 2 rows.

12.00 | Ferry to Havelock
13:30 – Ubud rice terraces, meet at lobby

### Response
{"items":[{"title":"Ferry","time":"12:00","kind":"transfer"},{"title":"Ubud rice terraces","time":"13:30","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 6 · Arrival.
It has 4 rows.

9:45 PM: Ubud rice terraces, meet at lobby
Hotel check-in: Zostel Manali
Hotel check-in: Hotel Raas
Stay at Taj Holiday Village

### Response
{"items":[{"title":"Ubud rice terraces","time":"21:45","kind":"activity"},{"title":"Zostel Manali","time":"","kind":"stay"},{"title":"Hotel Raas","time":"","kind":"stay"},{"title":"Taj Holiday Village","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 5 · Sightseeing.
It has 3 rows.

0645 hrs: Scooter rental for the day
08:00: Scooter rental for the day
22.45 | Buffer time

### Response
{"items":[{"title":"Scooter rental","time":"06:45","kind":"transfer"},{"title":"Scooter rental","time":"08:00","kind":"transfer"},{"title":"Buffer time","time":"22:45","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 1 · At leisure.
It has 2 rows.

21:10 Airport drop to CSMT
Check in at The Oberoi Udaivilas

### Response
{"items":[{"title":"Airport drop","time":"21:10","kind":"transfer"},{"title":"The Oberoi Udaivilas","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 4 · At leisure.
It has 4 rows.

06.30 | Sunset cruise on Mandovi
14:30 | River rafting Shivpuri (guide included)
19:30 – Virupaksha Temple visit, meet at lobby
9:45 PM: Rest day at leisure

### Response
{"items":[{"title":"Sunset cruise on Mandovi","time":"06:30","kind":"activity"},{"title":"River rafting Shivpuri","time":"14:30","kind":"activity"},{"title":"Virupaksha Temple visit","time":"19:30","kind":"activity"},{"title":"Rest day","time":"21:45","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Phuket, Thailand.
This day: Day 6 · Departure.
It has 7 rows.

7:15 AM – Breakfast at hotel
08.00 – Stay at Treebo Trend Cosmo
12:30 – Lunch break
15:50 | Scooter rental for the day
17:00 Amber Fort visit (guide included)
9:00 PM: Dinner Chokhi Dhani
Private taxi to Baga Beach

### Response
{"items":[{"title":"Hotel breakfast","time":"07:15","kind":"meal"},{"title":"Treebo Trend Cosmo","time":"08:00","kind":"stay"},{"title":"Lunch","time":"12:30","kind":"meal"},{"title":"Scooter rental","time":"15:50","kind":"transfer"},{"title":"Amber Fort visit","time":"17:00","kind":"activity"},{"title":"Dinner Chokhi Dhani","time":"21:00","kind":"meal"},{"title":"Private taxi","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Tokyo, Japan.
It has 5 rows.

10:10 AM City Palace tour — 4 pax
11:45 – Flight SQ 4634 (Bengaluru–Kochi), web check-in done
12:30 – Flight 6E 725 Rome to Udaipur
17:15 Board Netravati Express 16345 at Goa
19:10 | Train 12432 Trivandrum Rajdhani Leh to Mumbai

### Response
{"items":[{"title":"City Palace tour","time":"10:10","kind":"activity"},{"title":"Flight SQ 4634","time":"11:45","kind":"flight"},{"title":"Flight 6E 725","time":"12:30","kind":"flight"},{"title":"Netravati Express 16345","time":"17:15","kind":"train"},{"title":"Trivandrum Rajdhani 12432","time":"19:10","kind":"train"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 3 · At leisure.
It has 6 rows.

07:00 – Louvre visit — 4 pax
08:00 Sunset cruise on Mandovi, meet at lobby
15:00 Depart Rome on TG 9417 to Phuket
18:45 Flight SQ 5263 (Delhi–Denpasar), web check-in done
19.15 – Welcome dinner at Britto's
2230 hrs Train 12009 Shatabdi Express Chennai to Leh

### Response
{"items":[{"title":"Louvre visit","time":"07:00","kind":"activity"},{"title":"Sunset cruise on Mandovi","time":"08:00","kind":"activity"},{"title":"Flight TG 9417","time":"15:00","kind":"flight"},{"title":"Flight SQ 5263","time":"18:45","kind":"flight"},{"title":"Welcome dinner","time":"19:15","kind":"meal"},{"title":"Shatabdi Express 12009","time":"22:30","kind":"train"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Phuket, Thailand.
This day: Day 2 · Departure.
It has 6 rows.

06.45 – Virupaksha Temple visit — 4 pax
08:45: teamLab Planets, meet at lobby
17:45 – Group photo at the resort
Farewell dinner
Check-in Grand Hyatt
Hotel check-in: OYO Townhouse 142

### Response
{"items":[{"title":"Virupaksha Temple visit","time":"06:45","kind":"activity"},{"title":"teamLab Planets","time":"08:45","kind":"activity"},{"title":"Group photo","time":"17:45","kind":"other"},{"title":"Farewell dinner","time":"","kind":"meal"},{"title":"Grand Hyatt","time":"","kind":"stay"},{"title":"OYO Townhouse 142","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
This day: Day 1 · Sightseeing.
It has 4 rows.

08.00 Hotel breakfast
10:10: Private taxi to Nubra Valley
21:00: Private taxi to Old Goa
Depart Dubai on TG 5935 to Paris

### Response
{"items":[{"title":"Hotel breakfast","time":"08:00","kind":"meal"},{"title":"Private taxi","time":"10:10","kind":"transfer"},{"title":"Private taxi","time":"21:00","kind":"transfer"},{"title":"Flight TG 5935","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Tokyo, Japan.
This day: Day 6 · Departure.
It has 5 rows.

0745 hrs: Breakfast at hotel
20.15: Louvre visit (guide included)
Khardung La drive (guide included)
Snorkelling at Havelock
Airport drop to CSMT

### Response
{"items":[{"title":"Hotel breakfast","time":"07:45","kind":"meal"},{"title":"Louvre visit","time":"20:15","kind":"activity"},{"title":"Khardung La drive","time":"","kind":"activity"},{"title":"Snorkelling at Havelock","time":"","kind":"activity"},{"title":"Airport drop","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 3 · Sightseeing.
It has 3 rows.

11:30 Ferry to Havelock
12.15 Sunset cruise on Mandovi, meet at lobby
River rafting Shivpuri (guide included)

### Response
{"items":[{"title":"Ferry","time":"11:30","kind":"transfer"},{"title":"Sunset cruise on Mandovi","time":"12:15","kind":"activity"},{"title":"River rafting Shivpuri","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
This day: Day 6 · At leisure.
It has 4 rows.

10:00 AM | SpiceJet SG 6871 Bangkok → Bengaluru
Check-in Hotel Raas
Scooter rental for the day
Railway station drop, Jaipur Junction

### Response
{"items":[{"title":"Flight SG 6871","time":"10:00","kind":"flight"},{"title":"Hotel Raas","time":"","kind":"stay"},{"title":"Scooter rental","time":"","kind":"transfer"},{"title":"Station drop","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
It has 2 rows.

17:10 | Snorkelling at Havelock, meet at lobby
Depart Udaipur on AI 9895 to Paris

### Response
{"items":[{"title":"Snorkelling at Havelock","time":"17:10","kind":"activity"},{"title":"Flight AI 9895","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Tokyo, Japan.
It has 5 rows.

07:45: Hotel breakfast
8:10 AM Amber Fort visit, meet at lobby
10:10 – Scuba diving at Grande Island, meet at lobby
Sunset cruise on Mandovi (guide included)
Private taxi to Rohtang Pass

### Response
{"items":[{"title":"Hotel breakfast","time":"07:45","kind":"meal"},{"title":"Amber Fort visit","time":"08:10","kind":"activity"},{"title":"Scuba diving at Grande Island","time":"10:10","kind":"activity"},{"title":"Sunset cruise on Mandovi","time":"","kind":"activity"},{"title":"Private taxi","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
This day: Day 7 · Departure.
It has 2 rows.

10:30: Shatabdi Express (12009) dep Delhi, 3A, PNR confirmed
22:50 | Railway station drop, Jaipur Junction

### Response
{"items":[{"title":"Shatabdi Express 12009","time":"10:30","kind":"train"},{"title":"Station drop","time":"22:50","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
This day: Day 3 · Arrival.
It has 5 rows.

0710 hrs – Coffee plantation walk
09:00: Flight UK 3513 Delhi to Denpasar
1150 hrs | Sunset cruise on Mandovi — 4 pax
1430 hrs – River rafting Shivpuri — 4 pax
6:00 PM City Palace tour

### Response
{"items":[{"title":"Coffee plantation walk","time":"07:10","kind":"activity"},{"title":"Flight UK 3513","time":"09:00","kind":"flight"},{"title":"Sunset cruise on Mandovi","time":"11:50","kind":"activity"},{"title":"River rafting Shivpuri","time":"14:30","kind":"activity"},{"title":"City Palace tour","time":"18:00","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 2.
It has 6 rows.

0700 hrs | Breakfast at hotel
18:00 | Colosseum guided tour, meet at lobby
19:50 Sunset cruise on Mandovi, meet at lobby
1950 hrs Coffee plantation walk — 4 pax
22:45 – Dinner Johnny's Cafe
Flight 6E 7460 (Udaipur–Dubai), web check-in done

### Response
{"items":[{"title":"Hotel breakfast","time":"07:00","kind":"meal"},{"title":"Colosseum guided tour","time":"18:00","kind":"activity"},{"title":"Sunset cruise on Mandovi","time":"19:50","kind":"activity"},{"title":"Coffee plantation walk","time":"19:50","kind":"activity"},{"title":"Dinner Johnny's Cafe","time":"22:45","kind":"meal"},{"title":"Flight 6E 7460","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 1 · Arrival.
It has 7 rows.

05.00: teamLab Planets, meet at lobby
5:00 AM Homestay in Mawlynnong
09:10 Hotel breakfast
6:15 PM: Netravati Express (16345) dep Goa, 3A, PNR confirmed
21:00 – Farewell dinner
Group photo at the resort
Stay at The Tamara

### Response
{"items":[{"title":"teamLab Planets","time":"05:00","kind":"activity"},{"title":"Homestay Mawlynnong","time":"05:00","kind":"stay"},{"title":"Hotel breakfast","time":"09:10","kind":"meal"},{"title":"Netravati Express 16345","time":"18:15","kind":"train"},{"title":"Farewell dinner","time":"21:00","kind":"meal"},{"title":"Group photo","time":"","kind":"other"},{"title":"The Tamara","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 4 · Departure.
It has 3 rows.

16:00: Ferry to Phi Phi
22:00 Ubud rice terraces, meet at lobby
Hotel breakfast

### Response
{"items":[{"title":"Ferry","time":"16:00","kind":"transfer"},{"title":"Ubud rice terraces","time":"22:00","kind":"activity"},{"title":"Hotel breakfast","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 7 · Sightseeing.
It has 5 rows.

06:15 Ubud rice terraces — 4 pax
07:45: Breakfast at hotel
1:00 PM: Lunch at Thalassa
10:45 PM: Farewell dinner
Check-in Lemon Tree Premier

### Response
{"items":[{"title":"Ubud rice terraces","time":"06:15","kind":"activity"},{"title":"Hotel breakfast","time":"07:45","kind":"meal"},{"title":"Lunch at Thalassa","time":"13:00","kind":"meal"},{"title":"Farewell dinner","time":"22:45","kind":"meal"},{"title":"Lemon Tree Premier","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 2 · Arrival.
It has 3 rows.

05:45 | Paragliding at Solang Valley (guide included)
11:30 | Railway station drop, Madgaon
Dinner Thalassa

### Response
{"items":[{"title":"Paragliding at Solang Valley","time":"05:45","kind":"activity"},{"title":"Station drop","time":"11:30","kind":"transfer"},{"title":"Dinner Thalassa","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 6 · Sightseeing.
It has 2 rows.

11:00: Free time for shopping at Anjuna market
Farewell dinner

### Response
{"items":[{"title":"Free time","time":"11:00","kind":"other"},{"title":"Farewell dinner","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 2 · Arrival.
It has 2 rows.

13:10 | Lunch at Le Cafe
15:15 | Sunset cruise on Mandovi

### Response
{"items":[{"title":"Lunch at Le Cafe","time":"13:10","kind":"meal"},{"title":"Sunset cruise on Mandovi","time":"15:15","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 2 · Sightseeing.
It has 4 rows.

7:45 AM – Depart Delhi on SQ 5033 to Bengaluru
16:00 Scuba diving at Grande Island, meet at lobby
Stay at Lemon Tree Premier
Sunset cruise on Mandovi, meet at lobby

### Response
{"items":[{"title":"Flight SQ 5033","time":"07:45","kind":"flight"},{"title":"Scuba diving at Grande Island","time":"16:00","kind":"activity"},{"title":"Lemon Tree Premier","time":"","kind":"stay"},{"title":"Sunset cruise on Mandovi","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
It has 6 rows.

8:15 AM Breakfast at hotel
08.30: Hotel breakfast
09.30 – Hotel breakfast
18.15 | Board Shatabdi Express 12009 at Delhi
Farewell dinner
Hotel breakfast

### Response
{"items":[{"title":"Hotel breakfast","time":"08:15","kind":"meal"},{"title":"Hotel breakfast","time":"08:30","kind":"meal"},{"title":"Hotel breakfast","time":"09:30","kind":"meal"},{"title":"Shatabdi Express 12009","time":"18:15","kind":"train"},{"title":"Farewell dinner","time":"","kind":"meal"},{"title":"Hotel breakfast","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 6.
It has 6 rows.

7:00 AM: Depart Dubai on SG 8171 to Delhi
13:10 | Flight SQ 7222 (Jaipur–Bengaluru), web check-in done
18:10 | Elephant Falls visit (guide included)
6:10 PM | Ferry to Divar Island
7:45 PM – Snorkelling at Havelock (guide included)
21:15 Ganga aarti at Triveni Ghat (guide included)

### Response
{"items":[{"title":"Flight SG 8171","time":"07:00","kind":"flight"},{"title":"Flight SQ 7222","time":"13:10","kind":"flight"},{"title":"Elephant Falls visit","time":"18:10","kind":"activity"},{"title":"Ferry","time":"18:10","kind":"transfer"},{"title":"Snorkelling at Havelock","time":"19:45","kind":"activity"},{"title":"Ganga aarti at Triveni Ghat","time":"21:15","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 4 · Sightseeing.
It has 5 rows.

15:00 Railway station drop, Haridwar
21.10 Ferry to Phi Phi
21:15 Coffee plantation walk — 4 pax
Check-out Grand Hyatt
Tent stay Pangong Lake

### Response
{"items":[{"title":"Station drop","time":"15:00","kind":"transfer"},{"title":"Ferry","time":"21:10","kind":"transfer"},{"title":"Coffee plantation walk","time":"21:15","kind":"activity"},{"title":"Check-out Grand Hyatt","time":"","kind":"stay"},{"title":"Tent Pangong Lake","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 4 · At leisure.
It has 2 rows.

12:30 Lunch at Chokhi Dhani
15.50 – SpiceJet SG 9538 Bangkok → Rome

### Response
{"items":[{"title":"Lunch at Chokhi Dhani","time":"12:30","kind":"meal"},{"title":"Flight SG 9538","time":"15:50","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
This day: Day 7 · Arrival.
It has 6 rows.

2:15 PM | Ferry to Phi Phi
3:00 PM | Private taxi to Baga Beach
20:10: Farewell dinner
9:45 PM – River rafting Shivpuri, meet at lobby
10:00 PM: Dinner Gunpowder
Rest day at leisure

### Response
{"items":[{"title":"Ferry","time":"14:15","kind":"transfer"},{"title":"Private taxi","time":"15:00","kind":"transfer"},{"title":"Farewell dinner","time":"20:10","kind":"meal"},{"title":"River rafting Shivpuri","time":"21:45","kind":"activity"},{"title":"Dinner Gunpowder","time":"22:00","kind":"meal"},{"title":"Rest day","time":"","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
It has 2 rows.

Airport drop to Changi
Check in at The Leela Palace

### Response
{"items":[{"title":"Airport drop","time":"","kind":"transfer"},{"title":"The Leela Palace","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 4 · Arrival.
It has 7 rows.

05:00 | Board Rajdhani Express 12951 at Bengaluru
10:45 Phi Phi island hopping, meet at lobby
15.45 – Depart Dubai on SQ 6585 to Mumbai
17:00: Free time for shopping at Anjuna market
22:50 – Scooter rental for the day
Khardung La drive, meet at lobby
Farewell dinner

### Response
{"items":[{"title":"Rajdhani Express 12951","time":"05:00","kind":"train"},{"title":"Phi Phi island hopping","time":"10:45","kind":"activity"},{"title":"Flight SQ 6585","time":"15:45","kind":"flight"},{"title":"Free time","time":"17:00","kind":"other"},{"title":"Scooter rental","time":"22:50","kind":"transfer"},{"title":"Khardung La drive","time":"","kind":"activity"},{"title":"Farewell dinner","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
This day: Day 1 · Sightseeing.
It has 6 rows.

9:00 AM | Breakfast at hotel
1230 hrs: Railway station drop, Jaipur Junction
18:00: City Palace tour (guide included)
19:00 – Free time for shopping at Anjuna market
21:45: IndiGo 6E 5918 Denpasar → Tokyo
Train 12951 Rajdhani Express Chennai to Kochi

### Response
{"items":[{"title":"Hotel breakfast","time":"09:00","kind":"meal"},{"title":"Station drop","time":"12:30","kind":"transfer"},{"title":"City Palace tour","time":"18:00","kind":"activity"},{"title":"Free time","time":"19:00","kind":"other"},{"title":"Flight 6E 5918","time":"21:45","kind":"flight"},{"title":"Rajdhani Express 12951","time":"","kind":"train"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 5.
It has 4 rows.

08:10 Depart Rome on AI 4887 to Kochi
19:10 | Colosseum guided tour (guide included)
Colosseum guided tour (guide included)
Buffer time

### Response
{"items":[{"title":"Flight AI 4887","time":"08:10","kind":"flight"},{"title":"Colosseum guided tour","time":"19:10","kind":"activity"},{"title":"Colosseum guided tour","time":"","kind":"activity"},{"title":"Buffer time","time":"","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Goa, India.
This day: Day 4 · At leisure.
It has 5 rows.

07:45 | Hotel breakfast
11:15 AM – Ferry to Divar Island
4:50 PM | Phi Phi island hopping, meet at lobby
17:50 | Elephant Falls visit (guide included)
7:00 PM: Free time for shopping at Anjuna market

### Response
{"items":[{"title":"Hotel breakfast","time":"07:45","kind":"meal"},{"title":"Ferry","time":"11:15","kind":"transfer"},{"title":"Phi Phi island hopping","time":"16:50","kind":"activity"},{"title":"Elephant Falls visit","time":"17:50","kind":"activity"},{"title":"Free time","time":"19:00","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
This day: Day 7.
It has 4 rows.

08:00 Paragliding at Solang Valley — 4 pax
17.30 – Rest day at leisure
Check in at Alsisar Haveli
SpiceJet SG 1650 Delhi → Mumbai

### Response
{"items":[{"title":"Paragliding at Solang Valley","time":"08:00","kind":"activity"},{"title":"Rest day","time":"17:30","kind":"other"},{"title":"Alsisar Haveli","time":"","kind":"stay"},{"title":"Flight SG 1650","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
This day: Day 2 · At leisure.
It has 3 rows.

4:10 PM Elephant Falls visit (guide included)
8:00 PM: Colosseum guided tour — 4 pax
Lunch break

### Response
{"items":[{"title":"Elephant Falls visit","time":"16:10","kind":"activity"},{"title":"Colosseum guided tour","time":"20:00","kind":"activity"},{"title":"Lunch","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Jaipur, India.
This day: Day 5 · Arrival.
It has 5 rows.

09:30 – Amber Fort visit — 4 pax
13:50 – Airport drop to CDG
20.00: Dinner Britto's
Currency exchange at Thomas Cook
Check-in Zostel Manali

### Response
{"items":[{"title":"Amber Fort visit","time":"09:30","kind":"activity"},{"title":"Airport drop","time":"13:50","kind":"transfer"},{"title":"Dinner Britto's","time":"20:00","kind":"meal"},{"title":"Currency exchange","time":"","kind":"other"},{"title":"Zostel Manali","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 6.
It has 4 rows.

0800 hrs Sunset cruise on Mandovi
16.45: Scooter rental for the day
19:00 | Board Vande Bharat 22439 at Goa
Check-out Lemon Tree Premier

### Response
{"items":[{"title":"Sunset cruise on Mandovi","time":"08:00","kind":"activity"},{"title":"Scooter rental","time":"16:45","kind":"transfer"},{"title":"Vande Bharat 22439","time":"19:00","kind":"train"},{"title":"Check-out Lemon Tree Premier","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
This day: Day 7 · Sightseeing.
It has 7 rows.

06:00 Coffee plantation walk, meet at lobby
1200 hrs – Private taxi to Rohtang Pass
10:00 PM Akasa Air QP 8523 Chennai → Singapore
22:15: Old Town walking tour (guide included)
Houseboat stay Alleppey
Lunch break
Flight 6E 6381 (Rome–Hyderabad), web check-in done

### Response
{"items":[{"title":"Coffee plantation walk","time":"06:00","kind":"activity"},{"title":"Private taxi","time":"12:00","kind":"transfer"},{"title":"Flight QP 8523","time":"22:00","kind":"flight"},{"title":"Old Town walking tour","time":"22:15","kind":"activity"},{"title":"Houseboat Alleppey","time":"","kind":"stay"},{"title":"Lunch","time":"","kind":"meal"},{"title":"Flight 6E 6381","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
It has 2 rows.

2:50 PM River rafting Shivpuri, meet at lobby
21:00 | Ferry to Divar Island

### Response
{"items":[{"title":"River rafting Shivpuri","time":"14:50","kind":"activity"},{"title":"Ferry","time":"21:00","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
This day: Day 4.
It has 4 rows.

12:10: Ubud rice terraces
19:45 | Stay at Lemon Tree Premier
21.00: Train 12916 Ashram Express Bengaluru to Goa
Lunch break

### Response
{"items":[{"title":"Ubud rice terraces","time":"12:10","kind":"activity"},{"title":"Lemon Tree Premier","time":"19:45","kind":"stay"},{"title":"Ashram Express 12916","time":"21:00","kind":"train"},{"title":"Lunch","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 1 · Sightseeing.
It has 6 rows.

06:10: Buffer time
0945 hrs | Private taxi to Baga Beach
10:30: Check in at Treebo Trend Cosmo
16:45 | Currency exchange at Thomas Cook
19:15 – SpiceJet SG 5172 Bangkok → Leh
Flight QP 4700 Mumbai to Dubai

### Response
{"items":[{"title":"Buffer time","time":"06:10","kind":"other"},{"title":"Private taxi","time":"09:45","kind":"transfer"},{"title":"Treebo Trend Cosmo","time":"10:30","kind":"stay"},{"title":"Currency exchange","time":"16:45","kind":"other"},{"title":"Flight SG 5172","time":"19:15","kind":"flight"},{"title":"Flight QP 4700","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
It has 6 rows.

15:15 – teamLab Planets
20:00 | Dinner Britto's
2150 hrs | Welcome dinner at Johnny's Cafe
22.00 – Dinner Trattoria da Enzo
Hotel check-in: Taj Holiday Village
Hotel check-in: Treebo Trend Cosmo

### Response
{"items":[{"title":"teamLab Planets","time":"15:15","kind":"activity"},{"title":"Dinner Britto's","time":"20:00","kind":"meal"},{"title":"Welcome dinner","time":"21:50","kind":"meal"},{"title":"Dinner Trattoria da Enzo","time":"22:00","kind":"meal"},{"title":"Taj Holiday Village","time":"","kind":"stay"},{"title":"Treebo Trend Cosmo","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
This day: Day 5.
It has 5 rows.

7:10 AM | Flight 6E 9975 (Hyderabad–Delhi), web check-in done
13:00 Railway station drop, Ernakulam
14:00: Buffer time
7:45 PM: Virupaksha Temple visit — 4 pax
20:50 | Dinner Johnny's Cafe

### Response
{"items":[{"title":"Flight 6E 9975","time":"07:10","kind":"flight"},{"title":"Station drop","time":"13:00","kind":"transfer"},{"title":"Buffer time","time":"14:00","kind":"other"},{"title":"Virupaksha Temple visit","time":"19:45","kind":"activity"},{"title":"Dinner Johnny's Cafe","time":"20:50","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 2 · Departure.
It has 6 rows.

12.00 | Airport transfer T2 to Treebo Trend Cosmo
19:00 Board Netravati Express 16345 at Hyderabad
19:30: Airport drop to Ngurah Rai Airport
21:00: Farewell dinner
2200 hrs: Cab pickup from The Tamara
Colosseum guided tour (guide included)

### Response
{"items":[{"title":"Airport transfer","time":"12:00","kind":"transfer"},{"title":"Netravati Express 16345","time":"19:00","kind":"train"},{"title":"Airport drop","time":"19:30","kind":"transfer"},{"title":"Farewell dinner","time":"21:00","kind":"meal"},{"title":"Cab pickup","time":"22:00","kind":"transfer"},{"title":"Colosseum guided tour","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
This day: Day 6 · At leisure.
It has 5 rows.

08:45: Flight 6E 1244 Paris to Tokyo
9:45 AM – Colosseum guided tour
16:00 – Ubud rice terraces (guide included)
21:15: Scooter rental for the day
Coffee plantation walk — 4 pax

### Response
{"items":[{"title":"Flight 6E 1244","time":"08:45","kind":"flight"},{"title":"Colosseum guided tour","time":"09:45","kind":"activity"},{"title":"Ubud rice terraces","time":"16:00","kind":"activity"},{"title":"Scooter rental","time":"21:15","kind":"transfer"},{"title":"Coffee plantation walk","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Tokyo, Japan.
It has 2 rows.

09:10 Depart Tokyo on SG 562 to Phuket
10:50: Phi Phi island hopping — 4 pax

### Response
{"items":[{"title":"Flight SG 562","time":"09:10","kind":"flight"},{"title":"Phi Phi island hopping","time":"10:50","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 6 · Sightseeing.
It has 5 rows.

2:30 PM: Khardung La drive — 4 pax
19:15: Louvre visit — 4 pax
2115 hrs | SpiceJet SG 2979 Jaipur → Singapore
10:50 PM Welcome dinner at Chokhi Dhani
Air India AI 6996 Kochi → Jaipur

### Response
{"items":[{"title":"Khardung La drive","time":"14:30","kind":"activity"},{"title":"Louvre visit","time":"19:15","kind":"activity"},{"title":"Flight SG 2979","time":"21:15","kind":"flight"},{"title":"Welcome dinner","time":"22:50","kind":"meal"},{"title":"Flight AI 6996","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 3 · Sightseeing.
It has 3 rows.

10:45 | Railway station drop, Jaipur Junction
2:10 PM – Lunch at Johnny's Cafe
15.30: Visa appointment at VFS

### Response
{"items":[{"title":"Station drop","time":"10:45","kind":"transfer"},{"title":"Lunch at Johnny's Cafe","time":"14:10","kind":"meal"},{"title":"Visa appointment","time":"15:30","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 7 · At leisure.
It has 2 rows.

3:30 PM: Netravati Express (16345) dep Delhi, 3A, PNR confirmed
Hotel check-in: Hotel Raas

### Response
{"items":[{"title":"Netravati Express 16345","time":"15:30","kind":"train"},{"title":"Hotel Raas","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
This day: Day 7.
It has 7 rows.

1250 hrs | Private taxi to Baga Beach
3:50 PM – Virupaksha Temple visit — 4 pax
16:00: Board Rajdhani Express 12951 at Mumbai
16.15 | Scooter rental for the day
Lunch at Chokhi Dhani
Farewell dinner
Private taxi to Rohtang Pass

### Response
{"items":[{"title":"Private taxi","time":"12:50","kind":"transfer"},{"title":"Virupaksha Temple visit","time":"15:50","kind":"activity"},{"title":"Rajdhani Express 12951","time":"16:00","kind":"train"},{"title":"Scooter rental","time":"16:15","kind":"transfer"},{"title":"Lunch at Chokhi Dhani","time":"","kind":"meal"},{"title":"Farewell dinner","time":"","kind":"meal"},{"title":"Private taxi","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 2.
It has 3 rows.

1:00 PM: Lunch break
Cab pickup from Hotel Raas
Check-out Lemon Tree Premier

### Response
{"items":[{"title":"Lunch","time":"13:00","kind":"meal"},{"title":"Cab pickup","time":"","kind":"transfer"},{"title":"Check-out Lemon Tree Premier","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 6 · Arrival.
It has 2 rows.

10:00: Cab pickup from Alsisar Haveli
Hotel breakfast

### Response
{"items":[{"title":"Cab pickup","time":"10:00","kind":"transfer"},{"title":"Hotel breakfast","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
It has 3 rows.

05:15 – Ola to Lemon Tree Premier
6:45 AM: teamLab Planets
Homestay in Mawlynnong

### Response
{"items":[{"title":"Ola ride","time":"05:15","kind":"transfer"},{"title":"teamLab Planets","time":"06:45","kind":"activity"},{"title":"Homestay Mawlynnong","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
It has 3 rows.

19:30 Hotel check-in: The Tamara
Tent stay Pangong Lake
SpiceJet SG 8940 Delhi → Jaipur

### Response
{"items":[{"title":"The Tamara","time":"19:30","kind":"stay"},{"title":"Tent Pangong Lake","time":"","kind":"stay"},{"title":"Flight SG 8940","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 7 · Departure.
It has 2 rows.

12:50 – Dudhsagar Waterfalls tour (guide included)
13:00 | Lunch break

### Response
{"items":[{"title":"Dudhsagar Waterfalls tour","time":"12:50","kind":"activity"},{"title":"Lunch","time":"13:00","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 8 · At leisure.
It has 3 rows.

7:00 AM Hotel breakfast
4:50 PM | Stay at Treebo Trend Cosmo
Railway station drop, Haridwar

### Response
{"items":[{"title":"Hotel breakfast","time":"07:00","kind":"meal"},{"title":"Treebo Trend Cosmo","time":"16:50","kind":"stay"},{"title":"Station drop","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 7.
It has 3 rows.

7:00 AM | Phi Phi island hopping — 4 pax
12:30 | Buffer time
Colosseum guided tour

### Response
{"items":[{"title":"Phi Phi island hopping","time":"07:00","kind":"activity"},{"title":"Buffer time","time":"12:30","kind":"other"},{"title":"Colosseum guided tour","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 4.
It has 2 rows.

5:15 PM – Buffer time
19:50 Vistara UK 8292 Hyderabad → Delhi

### Response
{"items":[{"title":"Buffer time","time":"17:15","kind":"other"},{"title":"Flight UK 8292","time":"19:50","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
This day: Day 1 · Departure.
It has 4 rows.

19:45 – Welcome dinner at Karavalli
22:50 – Welcome dinner at Le Cafe
Check-out OYO Townhouse 142
Check-in Treebo Trend Cosmo

### Response
{"items":[{"title":"Welcome dinner","time":"19:45","kind":"meal"},{"title":"Welcome dinner","time":"22:50","kind":"meal"},{"title":"Check-out OYO Townhouse 142","time":"","kind":"stay"},{"title":"Treebo Trend Cosmo","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 6 · At leisure.
It has 6 rows.

07.45: Colosseum guided tour
10.50 | Check-in The Tamara
2:15 PM – Lunch at Fisherman's Wharf
5:30 PM – Check-in The Oberoi Udaivilas
20:30 | Khardung La drive, meet at lobby
22:15 Dudhsagar Waterfalls tour

### Response
{"items":[{"title":"Colosseum guided tour","time":"07:45","kind":"activity"},{"title":"The Tamara","time":"10:50","kind":"stay"},{"title":"Lunch at Fisherman's Wharf","time":"14:15","kind":"meal"},{"title":"The Oberoi Udaivilas","time":"17:30","kind":"stay"},{"title":"Khardung La drive","time":"20:30","kind":"activity"},{"title":"Dudhsagar Waterfalls tour","time":"22:15","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
It has 7 rows.

07:30 | Hotel check-in: Ibis Styles
11.15 – Stay at The Tamara
1:30 PM: Airport drop to Dabolim Airport
14:10 Lunch break
2:30 PM | teamLab Planets
2:45 PM Scooter rental for the day
17:15 Buffer time

### Response
{"items":[{"title":"Ibis Styles","time":"07:30","kind":"stay"},{"title":"The Tamara","time":"11:15","kind":"stay"},{"title":"Airport drop","time":"13:30","kind":"transfer"},{"title":"Lunch","time":"14:10","kind":"meal"},{"title":"teamLab Planets","time":"14:30","kind":"activity"},{"title":"Scooter rental","time":"14:45","kind":"transfer"},{"title":"Buffer time","time":"17:15","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
It has 2 rows.

05:00 | Cab pickup from Ibis Styles
Trivandrum Rajdhani (12432) dep Delhi, 3A, PNR confirmed

### Response
{"items":[{"title":"Cab pickup","time":"05:00","kind":"transfer"},{"title":"Trivandrum Rajdhani 12432","time":"","kind":"train"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
This day: Day 3 · Sightseeing.
It has 6 rows.

0615 hrs Cab pickup from The Tamara
1045 hrs | Airport drop to Fiumicino
10:45 PM – Visa appointment at VFS
Railway station drop, Ernakulam
Flight UK 244 (Bengaluru–Goa), web check-in done
Colosseum guided tour, meet at lobby

### Response
{"items":[{"title":"Cab pickup","time":"06:15","kind":"transfer"},{"title":"Airport drop","time":"10:45","kind":"transfer"},{"title":"Visa appointment","time":"22:45","kind":"other"},{"title":"Station drop","time":"","kind":"transfer"},{"title":"Flight UK 244","time":"","kind":"flight"},{"title":"Colosseum guided tour","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 5 · At leisure.
It has 7 rows.

05.00: Dudhsagar Waterfalls tour — 4 pax
7:45 AM Airport transfer Dabolim Airport to Zostel Manali
12.45: Dudhsagar Waterfalls tour
17:00 Private taxi to Rohtang Pass
21:00 | Welcome dinner at Paragon
Board Netravati Express 16345 at Mumbai
Cab pickup from Zostel Manali

### Response
{"items":[{"title":"Dudhsagar Waterfalls tour","time":"05:00","kind":"activity"},{"title":"Airport transfer","time":"07:45","kind":"transfer"},{"title":"Dudhsagar Waterfalls tour","time":"12:45","kind":"activity"},{"title":"Private taxi","time":"17:00","kind":"transfer"},{"title":"Welcome dinner","time":"21:00","kind":"meal"},{"title":"Netravati Express 16345","time":"","kind":"train"},{"title":"Cab pickup","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
This day: Day 8 · Arrival.
It has 6 rows.

06:50 – Cab pickup from Ibis Styles
11:00 – Flight UK 8367 Jaipur to Leh
12.00 – Lunch at Trattoria da Enzo
12:50 PM – River rafting Shivpuri
13:50: Depart Bengaluru on SQ 9080 to Tokyo
7:15 PM Depart Jaipur on EK 4615 to Rome

### Response
{"items":[{"title":"Cab pickup","time":"06:50","kind":"transfer"},{"title":"Flight UK 8367","time":"11:00","kind":"flight"},{"title":"Lunch at Trattoria da Enzo","time":"12:00","kind":"meal"},{"title":"River rafting Shivpuri","time":"12:50","kind":"activity"},{"title":"Flight SQ 9080","time":"13:50","kind":"flight"},{"title":"Flight EK 4615","time":"19:15","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 4 · Departure.
It has 2 rows.

Group photo at the resort
Netravati Express (16345) dep Mumbai, 3A, PNR confirmed

### Response
{"items":[{"title":"Group photo","time":"","kind":"other"},{"title":"Netravati Express 16345","time":"","kind":"train"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
This day: Day 2 · Arrival.
It has 5 rows.

7:45 AM – Singapore Airlines SQ 3228 Tokyo → Mumbai
15.30 – Snorkelling at Havelock — 4 pax
18:45 – Flight UK 9611 Chennai to Bengaluru
Hotel check-in: Zostel Manali
Check-in Taj Holiday Village

### Response
{"items":[{"title":"Flight SQ 3228","time":"07:45","kind":"flight"},{"title":"Snorkelling at Havelock","time":"15:30","kind":"activity"},{"title":"Flight UK 9611","time":"18:45","kind":"flight"},{"title":"Zostel Manali","time":"","kind":"stay"},{"title":"Taj Holiday Village","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
This day: Day 4.
It has 3 rows.

08:00: Breakfast at hotel
16:45 Check in at Lemon Tree Premier
City Palace tour

### Response
{"items":[{"title":"Hotel breakfast","time":"08:00","kind":"meal"},{"title":"Lemon Tree Premier","time":"16:45","kind":"stay"},{"title":"City Palace tour","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 7 · Sightseeing.
It has 2 rows.

06:45 | Khardung La drive — 4 pax
9:50 AM – Scuba diving at Grande Island — 4 pax

### Response
{"items":[{"title":"Khardung La drive","time":"06:45","kind":"activity"},{"title":"Scuba diving at Grande Island","time":"09:50","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Leh, India.
This day: Day 7 · At leisure.
It has 6 rows.

0700 hrs | Train 12916 Ashram Express Bengaluru to Delhi
07:10 | Akasa Air QP 6964 Singapore → Hyderabad
17:10: Depart Leh on TG 5871 to Delhi
19:50 – Rajdhani Express (12951) dep Jaipur, 3A, PNR confirmed
21:10: Desert safari (guide included)
Depart Kochi on 6E 753 to Rome

### Response
{"items":[{"title":"Ashram Express 12916","time":"07:00","kind":"train"},{"title":"Flight QP 6964","time":"07:10","kind":"flight"},{"title":"Flight TG 5871","time":"17:10","kind":"flight"},{"title":"Rajdhani Express 12951","time":"19:50","kind":"train"},{"title":"Desert safari","time":"21:10","kind":"activity"},{"title":"Flight 6E 753","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 1.
It has 7 rows.

4:10 PM Board Ashram Express 12916 at Delhi
17:50 | Depart Kochi on TG 4355 to Tokyo
19:00 – Welcome dinner at Bukhara
20:45 Farewell dinner
22:00 – Scooter rental for the day
10:15 PM | River rafting Shivpuri — 4 pax
Flight AI 5421 Chennai to Dubai

### Response
{"items":[{"title":"Ashram Express 12916","time":"16:10","kind":"train"},{"title":"Flight TG 4355","time":"17:50","kind":"flight"},{"title":"Welcome dinner","time":"19:00","kind":"meal"},{"title":"Farewell dinner","time":"20:45","kind":"meal"},{"title":"Scooter rental","time":"22:00","kind":"transfer"},{"title":"River rafting Shivpuri","time":"22:15","kind":"activity"},{"title":"Flight AI 5421","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
It has 7 rows.

18:10: Ferry to Phi Phi
18:15 – Dudhsagar Waterfalls tour (guide included)
18:30 Stay at The Leela Palace
20.00 Airport transfer Narita to Hotel Raas
20:30: Buffer time
Airport transfer CSMT to Treebo Trend Cosmo
Tent stay Pangong Lake

### Response
{"items":[{"title":"Ferry","time":"18:10","kind":"transfer"},{"title":"Dudhsagar Waterfalls tour","time":"18:15","kind":"activity"},{"title":"The Leela Palace","time":"18:30","kind":"stay"},{"title":"Airport transfer","time":"20:00","kind":"transfer"},{"title":"Buffer time","time":"20:30","kind":"other"},{"title":"Airport transfer","time":"","kind":"transfer"},{"title":"Tent Pangong Lake","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
It has 2 rows.

2100 hrs: Old Town walking tour, meet at lobby
Stay at Hotel Artemide

### Response
{"items":[{"title":"Old Town walking tour","time":"21:00","kind":"activity"},{"title":"Hotel Artemide","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 6 · Departure.
It has 2 rows.

8:10 PM Flight TG 4277 (Mumbai–Goa), web check-in done
21:50 | Hotel check-in: Ibis Styles

### Response
{"items":[{"title":"Flight TG 4277","time":"20:10","kind":"flight"},{"title":"Ibis Styles","time":"21:50","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
It has 2 rows.

08.10: Ola to Evolve Back Coorg
22:00: Rest day at leisure

### Response
{"items":[{"title":"Ola ride","time":"08:10","kind":"transfer"},{"title":"Rest day","time":"22:00","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
This day: Day 3 · Arrival.
It has 4 rows.

1000 hrs | Airport drop to Mopa Airport
13:10 Colosseum guided tour (guide included)
4:00 PM – Homestay in Mawlynnong
17:15: Vistara UK 4563 Kochi → Udaipur

### Response
{"items":[{"title":"Airport drop","time":"10:00","kind":"transfer"},{"title":"Colosseum guided tour","time":"13:10","kind":"activity"},{"title":"Homestay Mawlynnong","time":"16:00","kind":"stay"},{"title":"Flight UK 4563","time":"17:15","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Hampi, India.
It has 6 rows.

5:00 AM: Flight SQ 2500 Phuket to Bangkok
07:45 | Breakfast at hotel
12:00 PM Sunset cruise on Mandovi, meet at lobby
22:00: Check-out Lemon Tree Premier
Train 12916 Ashram Express Kochi to Chennai
Scooter rental for the day

### Response
{"items":[{"title":"Flight SQ 2500","time":"05:00","kind":"flight"},{"title":"Hotel breakfast","time":"07:45","kind":"meal"},{"title":"Sunset cruise on Mandovi","time":"12:00","kind":"activity"},{"title":"Check-out Lemon Tree Premier","time":"22:00","kind":"stay"},{"title":"Ashram Express 12916","time":"","kind":"train"},{"title":"Scooter rental","time":"","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
It has 5 rows.

05:10 Scooter rental for the day
7:15 AM: Ferry to Divar Island
20:50 – Vatican Museums tour
2050 hrs – Farewell dinner
Check-out Zostel Manali

### Response
{"items":[{"title":"Scooter rental","time":"05:10","kind":"transfer"},{"title":"Ferry","time":"07:15","kind":"transfer"},{"title":"Vatican Museums tour","time":"20:50","kind":"activity"},{"title":"Farewell dinner","time":"20:50","kind":"meal"},{"title":"Check-out Zostel Manali","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 7 · Departure.
It has 6 rows.

06:30 | Airport transfer CDG to Zostel Manali
11:10 AM: Ubud rice terraces — 4 pax
15:15 Rest day at leisure
8:00 PM Welcome dinner at Trattoria da Enzo
22.10 – Dinner Chokhi Dhani
Emirates EK 9490 Udaipur → Denpasar

### Response
{"items":[{"title":"Airport transfer","time":"06:30","kind":"transfer"},{"title":"Ubud rice terraces","time":"11:10","kind":"activity"},{"title":"Rest day","time":"15:15","kind":"other"},{"title":"Welcome dinner","time":"20:00","kind":"meal"},{"title":"Dinner Chokhi Dhani","time":"22:10","kind":"meal"},{"title":"Flight EK 9490","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 4 · Arrival.
It has 2 rows.

06:10 – Old Town walking tour, meet at lobby
Stay at Taj Holiday Village

### Response
{"items":[{"title":"Old Town walking tour","time":"06:10","kind":"activity"},{"title":"Taj Holiday Village","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
It has 7 rows.

11:30 | Free time for shopping at Anjuna market
15:00 Old Town walking tour (guide included)
6:00 PM: Private taxi to Baga Beach
1900 hrs Welcome dinner at Karavalli
2215 hrs | Dinner Thalassa
Akasa Air QP 1419 Phuket → Singapore
Stay at Zostel Manali

### Response
{"items":[{"title":"Free time","time":"11:30","kind":"other"},{"title":"Old Town walking tour","time":"15:00","kind":"activity"},{"title":"Private taxi","time":"18:00","kind":"transfer"},{"title":"Welcome dinner","time":"19:00","kind":"meal"},{"title":"Dinner Thalassa","time":"22:15","kind":"meal"},{"title":"Flight QP 1419","time":"","kind":"flight"},{"title":"Zostel Manali","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
It has 4 rows.

0500 hrs City Palace tour — 4 pax
08:00 | Thai Airways TG 141 Mumbai → Delhi
4:10 PM: Elephant Falls visit (guide included)
Currency exchange at Thomas Cook

### Response
{"items":[{"title":"City Palace tour","time":"05:00","kind":"activity"},{"title":"Flight TG 141","time":"08:00","kind":"flight"},{"title":"Elephant Falls visit","time":"16:10","kind":"activity"},{"title":"Currency exchange","time":"","kind":"other"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
This day: Day 2 · Departure.
It has 2 rows.

20:30 – Free time for shopping at Anjuna market
teamLab Planets — 4 pax

### Response
{"items":[{"title":"Free time","time":"20:30","kind":"other"},{"title":"teamLab Planets","time":"","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
It has 7 rows.

5:50 AM: Ferry to Divar Island
7:45 AM Train 12009 Shatabdi Express Delhi to Kochi
11:00 – Amber Fort visit
12:00 PM | Lunch break
21:10 Dinner Paragon
22:00 | Ubud rice terraces (guide included)
Stay at OYO Townhouse 142

### Response
{"items":[{"title":"Ferry","time":"05:50","kind":"transfer"},{"title":"Shatabdi Express 12009","time":"07:45","kind":"train"},{"title":"Amber Fort visit","time":"11:00","kind":"activity"},{"title":"Lunch","time":"12:00","kind":"meal"},{"title":"Dinner Paragon","time":"21:10","kind":"meal"},{"title":"Ubud rice terraces","time":"22:00","kind":"activity"},{"title":"OYO Townhouse 142","time":"","kind":"stay"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 6.
It has 3 rows.

08:15: Hotel breakfast
08:50: Hotel breakfast
15:00 Ola to Hotel Artemide

### Response
{"items":[{"title":"Hotel breakfast","time":"08:15","kind":"meal"},{"title":"Hotel breakfast","time":"08:50","kind":"meal"},{"title":"Ola ride","time":"15:00","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 8 · Sightseeing.
It has 7 rows.

06:00: teamLab Planets, meet at lobby
1600 hrs | Snorkelling at Havelock, meet at lobby
18.30 | Vatican Museums tour (guide included)
7:00 PM Dinner Chokhi Dhani
20:15 – Farewell dinner
9:00 PM: Virupaksha Temple visit, meet at lobby
21:30 Private taxi to Munnar

### Response
{"items":[{"title":"teamLab Planets","time":"06:00","kind":"activity"},{"title":"Snorkelling at Havelock","time":"16:00","kind":"activity"},{"title":"Vatican Museums tour","time":"18:30","kind":"activity"},{"title":"Dinner Chokhi Dhani","time":"19:00","kind":"meal"},{"title":"Farewell dinner","time":"20:15","kind":"meal"},{"title":"Virupaksha Temple visit","time":"21:00","kind":"activity"},{"title":"Private taxi","time":"21:30","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
It has 7 rows.

07:00 – Breakfast at hotel
09:00 Ferry to Phi Phi
9:50 AM: Rest day at leisure
13:00 | Ubud rice terraces — 4 pax
7:15 PM | Train 12951 Rajdhani Express Mumbai to Leh
7:50 PM Board Ashram Express 12916 at Mumbai
Farewell dinner

### Response
{"items":[{"title":"Hotel breakfast","time":"07:00","kind":"meal"},{"title":"Ferry","time":"09:00","kind":"transfer"},{"title":"Rest day","time":"09:50","kind":"other"},{"title":"Ubud rice terraces","time":"13:00","kind":"activity"},{"title":"Rajdhani Express 12951","time":"19:15","kind":"train"},{"title":"Ashram Express 12916","time":"19:50","kind":"train"},{"title":"Farewell dinner","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 5 · Departure.
It has 3 rows.

08:15 Hotel breakfast
14:00 – Old Town walking tour — 4 pax
21:45: Dinner Bukhara

### Response
{"items":[{"title":"Hotel breakfast","time":"08:15","kind":"meal"},{"title":"Old Town walking tour","time":"14:00","kind":"activity"},{"title":"Dinner Bukhara","time":"21:45","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 5 · Arrival.
It has 2 rows.

09:10 Rest day at leisure
2010 hrs: Colosseum guided tour (guide included)

### Response
{"items":[{"title":"Rest day","time":"09:10","kind":"other"},{"title":"Colosseum guided tour","time":"20:10","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Bali, Indonesia.
This day: Day 4 · At leisure.
It has 2 rows.

1350 hrs: Khardung La drive (guide included)
19:50: Airport transfer Fiumicino to Hotel Raas

### Response
{"items":[{"title":"Khardung La drive","time":"13:50","kind":"activity"},{"title":"Airport transfer","time":"19:50","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Udaipur, India.
This day: Day 5 · Departure.
It has 5 rows.

07:10: Group photo at the resort
9:50 AM | Hotel check-in: OYO Townhouse 142
12:00 PM | Lunch at Johnny's Cafe
12:45 PM: Ferry to Divar Island
Farewell dinner

### Response
{"items":[{"title":"Group photo","time":"07:10","kind":"other"},{"title":"OYO Townhouse 142","time":"09:50","kind":"stay"},{"title":"Lunch at Johnny's Cafe","time":"12:00","kind":"meal"},{"title":"Ferry","time":"12:45","kind":"transfer"},{"title":"Farewell dinner","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Puducherry, India.
This day: Day 4.
It has 3 rows.

07.45: Free time for shopping at Anjuna market
15:30: Ola to The Leela Palace
2045 hrs Airport drop to T2

### Response
{"items":[{"title":"Free time","time":"07:45","kind":"other"},{"title":"Ola ride","time":"15:30","kind":"transfer"},{"title":"Airport drop","time":"20:45","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 2 · Departure.
It has 6 rows.

05:50: Railway station drop, Jaipur Junction
08:00 | Free time for shopping at Anjuna market
17:00 – Stay at Alsisar Haveli
17:15 – Ferry to Divar Island
20:00 Cab pickup from Taj Holiday Village
21.50 – Dinner Chokhi Dhani

### Response
{"items":[{"title":"Station drop","time":"05:50","kind":"transfer"},{"title":"Free time","time":"08:00","kind":"other"},{"title":"Alsisar Haveli","time":"17:00","kind":"stay"},{"title":"Ferry","time":"17:15","kind":"transfer"},{"title":"Cab pickup","time":"20:00","kind":"transfer"},{"title":"Dinner Chokhi Dhani","time":"21:50","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
This day: Day 3.
It has 7 rows.

05.30 Train 12009 Shatabdi Express Goa to Chennai
1100 hrs River rafting Shivpuri (guide included)
1550 hrs Ola to Hotel Raas
4:50 PM Depart Phuket on QP 9948 to Chennai
8:00 PM: Welcome dinner at Paragon
21.30 Tent stay Pangong Lake
Dinner Ichiran

### Response
{"items":[{"title":"Shatabdi Express 12009","time":"05:30","kind":"train"},{"title":"River rafting Shivpuri","time":"11:00","kind":"activity"},{"title":"Ola ride","time":"15:50","kind":"transfer"},{"title":"Flight QP 9948","time":"16:50","kind":"flight"},{"title":"Welcome dinner","time":"20:00","kind":"meal"},{"title":"Tent Pangong Lake","time":"21:30","kind":"stay"},{"title":"Dinner Ichiran","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Manali, India.
It has 2 rows.

08:45 Desert safari, meet at lobby
10:15 AM | Louvre visit (guide included)

### Response
{"items":[{"title":"Desert safari","time":"08:45","kind":"activity"},{"title":"Louvre visit","time":"10:15","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 5 · Departure.
It has 4 rows.

09:15 Vatican Museums tour (guide included)
10.00: Flight TG 2748 (Bengaluru–Denpasar), web check-in done
11:15 – Rest day at leisure
16:50: Flight QP 1866 (Bengaluru–Delhi), web check-in done

### Response
{"items":[{"title":"Vatican Museums tour","time":"09:15","kind":"activity"},{"title":"Flight TG 2748","time":"10:00","kind":"flight"},{"title":"Rest day","time":"11:15","kind":"other"},{"title":"Flight QP 1866","time":"16:50","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Coorg, India.
This day: Day 3 · Sightseeing.
It has 2 rows.

05:10 – Airport drop to Mopa Airport
13.00: Ferry to Havelock

### Response
{"items":[{"title":"Airport drop","time":"05:10","kind":"transfer"},{"title":"Ferry","time":"13:00","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
This day: Day 2 · Sightseeing.
It has 5 rows.

7:10 AM | Breakfast at hotel
11:30 Flight EK 5819 (Paris–Bengaluru), web check-in done
13:45 | Lunch break
1830 hrs | Old Town walking tour — 4 pax
19:15 – Amber Fort visit (guide included)

### Response
{"items":[{"title":"Hotel breakfast","time":"07:10","kind":"meal"},{"title":"Flight EK 5819","time":"11:30","kind":"flight"},{"title":"Lunch","time":"13:45","kind":"meal"},{"title":"Old Town walking tour","time":"18:30","kind":"activity"},{"title":"Amber Fort visit","time":"19:15","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Singapore.
This day: Day 4 · At leisure.
It has 3 rows.

07.00: Buffer time
08:10 | Vatican Museums tour, meet at lobby
12:10 Flight 6E 6054 Hyderabad to Paris

### Response
{"items":[{"title":"Buffer time","time":"07:00","kind":"other"},{"title":"Vatican Museums tour","time":"08:10","kind":"activity"},{"title":"Flight 6E 6054","time":"12:10","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Alleppey, India.
This day: Day 4.
It has 4 rows.

06.15 | Air India AI 4772 Leh → Paris
09:30: Board Netravati Express 16345 at Bengaluru
2:45 PM: Lunch at Chokhi Dhani
Breakfast at hotel

### Response
{"items":[{"title":"Flight AI 4772","time":"06:15","kind":"flight"},{"title":"Netravati Express 16345","time":"09:30","kind":"train"},{"title":"Lunch at Chokhi Dhani","time":"14:45","kind":"meal"},{"title":"Hotel breakfast","time":"","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
This day: Day 4.
It has 5 rows.

07:15: Airport transfer Leh Airport to The Tamara
10:10 | Rest day at leisure
12:15 Phi Phi island hopping — 4 pax
1:00 PM Lunch break
1345 hrs: Lunch at Britto's

### Response
{"items":[{"title":"Airport transfer","time":"07:15","kind":"transfer"},{"title":"Rest day","time":"10:10","kind":"other"},{"title":"Phi Phi island hopping","time":"12:15","kind":"activity"},{"title":"Lunch","time":"13:00","kind":"meal"},{"title":"Lunch at Britto's","time":"13:45","kind":"meal"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rishikesh, India.
This day: Day 7 · Arrival.
It has 2 rows.

0900 hrs – Hotel breakfast
21:30: Railway station drop, Jaipur Junction

### Response
{"items":[{"title":"Hotel breakfast","time":"09:00","kind":"meal"},{"title":"Station drop","time":"21:30","kind":"transfer"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 6.
It has 2 rows.

2:00 PM – Railway station drop, Haridwar
10:00 PM: Ganga aarti at Triveni Ghat — 4 pax

### Response
{"items":[{"title":"Station drop","time":"14:00","kind":"transfer"},{"title":"Ganga aarti at Triveni Ghat","time":"22:00","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Paris, France.
This day: Day 6 · Departure.
It has 7 rows.

05.15 Phi Phi island hopping (guide included)
07:45 – Ubud rice terraces
10:15 – Louvre visit, meet at lobby
10:50 AM Airport transfer Fiumicino to OYO Townhouse 142
7:00 PM – Welcome dinner at Fisherman's Wharf
Dinner Thalassa
Flight AI 9398 (Paris–Jaipur), web check-in done

### Response
{"items":[{"title":"Phi Phi island hopping","time":"05:15","kind":"activity"},{"title":"Ubud rice terraces","time":"07:45","kind":"activity"},{"title":"Louvre visit","time":"10:15","kind":"activity"},{"title":"Airport transfer","time":"10:50","kind":"transfer"},{"title":"Welcome dinner","time":"19:00","kind":"meal"},{"title":"Dinner Thalassa","time":"","kind":"meal"},{"title":"Flight AI 9398","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Dubai, UAE.
It has 4 rows.

06.15: Ganga aarti at Triveni Ghat, meet at lobby
9:45 AM – Hotel breakfast
1000 hrs | Flight SQ 7794 Singapore to Chennai
16:45: Flight TG 2331 Leh to Rome

### Response
{"items":[{"title":"Ganga aarti at Triveni Ghat","time":"06:15","kind":"activity"},{"title":"Hotel breakfast","time":"09:45","kind":"meal"},{"title":"Flight SQ 7794","time":"10:00","kind":"flight"},{"title":"Flight TG 2331","time":"16:45","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Rome, Italy.
This day: Day 3 · At leisure.
It has 4 rows.

07:00 – Hotel breakfast
09:00 | Hotel breakfast
20:15 – Cab pickup from The Leela Palace
22:50 Louvre visit

### Response
{"items":[{"title":"Hotel breakfast","time":"07:00","kind":"meal"},{"title":"Hotel breakfast","time":"09:00","kind":"meal"},{"title":"Cab pickup","time":"20:15","kind":"transfer"},{"title":"Louvre visit","time":"22:50","kind":"activity"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Tokyo, Japan.
This day: Day 3 · Departure.
It has 6 rows.

1300 hrs – Airport transfer CDG to OYO Townhouse 142
4:10 PM | Airport drop to Ngurah Rai Airport
22.50 | Airport transfer CDG to Taj Holiday Village
Homestay in Mawlynnong
Homestay in Mawlynnong
Flight SQ 1150 Bengaluru to Dubai

### Response
{"items":[{"title":"Airport transfer","time":"13:00","kind":"transfer"},{"title":"Airport drop","time":"16:10","kind":"transfer"},{"title":"Airport transfer","time":"22:50","kind":"transfer"},{"title":"Homestay Mawlynnong","time":"","kind":"stay"},{"title":"Homestay Mawlynnong","time":"","kind":"stay"},{"title":"Flight SQ 1150","time":"","kind":"flight"}]}

### Instruction
You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal.

Trip to Shillong, India.
It has 6 rows.

0610 hrs | Board Ashram Express 12916 at Bengaluru
14:30 Check-in Evolve Back Coorg
20:45 – Dinner Karavalli
9:15 PM: Snorkelling at Havelock
teamLab Planets — 4 pax
Ganga aarti at Triveni Ghat (guide included)

### Response
{"items":[{"title":"Ashram Express 12916","time":"06:10","kind":"train"},{"title":"Evolve Back Coorg","time":"14:30","kind":"stay"},{"title":"Dinner Karavalli","time":"20:45","kind":"meal"},{"title":"Snorkelling at Havelock","time":"21:15","kind":"activity"},{"title":"teamLab Planets","time":"","kind":"activity"},{"title":"Ganga aarti at Triveni Ghat","time":"","kind":"activity"}]}
