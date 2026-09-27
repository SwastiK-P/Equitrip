#!/usr/bin/env python3
"""Builds the Nugen alignment corpus and benchmark for Equitrip.

Two tasks, each written in exactly the prompt format the aligned model is
sent. DAY_SYSTEM below must stay identical to the one in
`supabase/functions/nugen-reader/index.ts`, and the day prompt to
`TripExtractor.dayPrompt`. Only read_day is used by the app; read_query was
part of the first alignment run and is kept so the corpus can be rebuilt as it was:

  read_query  Equi: a question (English, Hindi or Hinglish) -> which trip,
              what topic, narrowed to what. Mirrors `EquiQueryDraft`.
  read_day    Booking import: one day of an itinerary -> one entry per row.
              Mirrors `ExtractedDayPlan`.

The model classifies and copies; it never produces an amount. Nothing here
asks for one.

Writes:
  docs/nugen/corpus/equitrip-glossary.txt      hand-written domain notes (copied)
  docs/nugen/corpus/equitrip-questions.txt     read_query worked examples
  docs/nugen/corpus/equitrip-itinerary-days.txt read_day worked examples
  docs/nugen/benchmark.json                     held-out samples, Nugen upload format

Deterministic: same seed, same files.
"""

import json
import random
import shutil
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "nugen"
SEED = 2026

QUERY_TRAIN, QUERY_BENCH = 420, 60
DAY_TRAIN, DAY_BENCH = 180, 40

QUERY_SYSTEM = """You sort questions for Equi, the assistant in a group-trip app. Never answer the question, only classify it. Reply with one JSON object and nothing else.
topic: overview (one trip as a whole: when, how it's going, a recap) | schedule (what's next, today, tomorrow, when something happens) | bookings (what is booked of one kind) | spending (what things cost, where the money went, budget) | balance (who owes whom, settling up) | people (who is on a trip, who paid) | trips (several trips: list, count, compare) | gaps (what's missing: nights with no stay, empty days) | advice (packing, weather, sights, food to try) | chat (greetings, thanks, anything not about travel)
trip: named (copy the trip's exact title into tripTitle) | current | next | previous | all | unspecified
category: anything | flight | train | transfer | stay | activity | food | other
person: a traveller's first name when the question is about one person other than the user, else ""
day: anyDay | today | tomorrow
A place that is a listed trip's destination means that trip. A short follow-up keeps the previous question's topic. Questions may be in English, Hindi or Hinglish."""

DAY_SYSTEM = """You read one day of a travel itinerary and name what is on it. Reply with one JSON object and nothing else: {"items":[{"title":"","time":"","kind":""}]}
One entry per row, in the order written. Never merge two rows, split one, or add one.
title: the row's name for the thing, two to four words, with what makes it this booking (a flight or train number, a place's name). Never the whole row, never a bare "Flight" or "Hotel".
time: 24-hour HH:mm from the row, or "" when the row has no time. Never guess one.
kind: flight | train | transfer | stay | activity | meal | other. Getting to or from an airport or station is a transfer; only the thing that flies is a flight. Checking into a hotel is a stay. Hotel breakfast is a meal."""

# MARK: - Trips and people

TRIPS = [
    ("Goa Getaway", "Goa, India", "Goa"),
    ("Manali Snow Run", "Manali, India", "Manali"),
    ("Rome in Spring", "Rome, Italy", "Rome"),
    ("Bali Bros", "Bali, Indonesia", "Bali"),
    ("Jaipur Weekend", "Jaipur, India", "Jaipur"),
    ("Kerala Backwaters", "Alleppey, India", "Kerala"),
    ("Ladakh Ride", "Leh, India", "Ladakh"),
    ("Dubai Long Weekend", "Dubai, UAE", "Dubai"),
    ("Thailand Trip", "Phuket, Thailand", "Phuket"),
    ("Coorg Coffee Trail", "Coorg, India", "Coorg"),
    ("Rishikesh Rafting", "Rishikesh, India", "Rishikesh"),
    ("Tokyo 2026", "Tokyo, Japan", "Tokyo"),
    ("Paris Escape", "Paris, France", "Paris"),
    ("Udaipur Wedding", "Udaipur, India", "Udaipur"),
    ("Pondy Chill", "Puducherry, India", "Pondicherry"),
    ("Meghalaya Monsoon", "Shillong, India", "Shillong"),
    ("Singapore Stopover", "Singapore", "Singapore"),
    ("Hampi Heritage", "Hampi, India", "Hampi"),
]
# Places people ask about that aren't anyone's trip here.
OTHER_PLACES = ["Kyoto", "Lisbon", "Sikkim", "Andaman", "Istanbul", "Vietnam", "Ooty", "Munnar"]

PEOPLE = ["Rahul", "Priya", "Kim", "Aditi", "Arjun", "Sneha", "Vikram", "Meera", "Rohan", "Ananya",
          "Kabir", "Isha", "Dev", "Neha", "Sam", "Tanvi", "Karan", "Zoya", "Omar", "Leela"]

PHASE_WORD = {"upcoming": "upcoming", "live": "under way now", "past": "finished"}
TODAY = date(2026, 9, 27)


def make_trip_list(rng):
    """3–6 trips with phases and dates, at most one under way."""
    picks = rng.sample(TRIPS, rng.randint(3, 6))
    trips = []
    live_used = False
    for title, dest, place in picks:
        phase = rng.choice(["past", "past", "upcoming", "upcoming", "live"])
        if phase == "live" and live_used:
            phase = "upcoming"
        live_used |= phase == "live"
        if phase == "past":
            start = TODAY - timedelta(days=rng.randint(20, 400))
        elif phase == "live":
            start = TODAY - timedelta(days=rng.randint(0, 3))
        else:
            start = TODAY + timedelta(days=rng.randint(5, 200))
        end = start + timedelta(days=rng.randint(2, 9))
        trips.append({"title": title, "dest": dest, "place": place, "phase": phase, "start": start, "end": end})
    return trips


def trip_lines(trips):
    fmt = lambda d: f"{d.day} {d.strftime('%b %Y')}"
    return "\n".join(
        f'- "{t["title"]}" — {t["dest"]}, {fmt(t["start"])} to {fmt(t["end"])}, {PHASE_WORD[t["phase"]]}'
        for t in trips
    )


# MARK: - Question templates
#
# Each: (topic, text, category, day). {T} = a trip reference, {P} = a person,
# {D} = a place. A template without {T} leaves the trip unspecified unless it
# names a place.

EN = [
    # overview
    ("overview", "how is {T} going?", "anything", "anyDay"),
    ("overview", "give me a recap of {T}", "anything", "anyDay"),
    ("overview", "quick summary of {T}", "anything", "anyDay"),
    ("overview", "tell me about {T}", "anything", "anyDay"),
    ("overview", "when is {T}?", "anything", "anyDay"),
    ("overview", "how many days is {T}?", "anything", "anyDay"),
    ("overview", "how's the trip going so far?", "anything", "anyDay"),
    # schedule
    ("schedule", "what's next on {T}?", "anything", "anyDay"),
    ("schedule", "what's the plan tomorrow on {T}?", "anything", "tomorrow"),
    ("schedule", "what are we doing today?", "anything", "today"),
    ("schedule", "what's on today's agenda", "anything", "today"),
    ("schedule", "when is our flight on {T}?", "flight", "anyDay"),
    ("schedule", "what time is hotel check-in tomorrow?", "stay", "tomorrow"),
    ("schedule", "when does the train leave?", "train", "anyDay"),
    ("schedule", "what time is the airport pickup today?", "transfer", "today"),
    ("schedule", "anything planned for dinner tomorrow?", "food", "tomorrow"),
    ("schedule", "what's first thing tomorrow morning", "anything", "tomorrow"),
    # bookings
    ("bookings", "where are we staying on {T}?", "anything", "anyDay"),
    ("bookings", "which hotel did we book for {T}?", "stay", "anyDay"),
    ("bookings", "which flights are booked for {T}?", "flight", "anyDay"),
    ("bookings", "what activities do we have on {T}?", "activity", "anyDay"),
    ("bookings", "any train tickets for {T}?", "train", "anyDay"),
    ("bookings", "show me the restaurant bookings", "food", "anyDay"),
    ("bookings", "is the airport pickup booked?", "transfer", "anyDay"),
    ("bookings", "list everything booked for {T}", "anything", "anyDay"),
    # spending
    ("spending", "how much did we spend on {T}?", "anything", "anyDay"),
    ("spending", "how much did food cost on {T}?", "food", "anyDay"),
    ("spending", "what was the most expensive thing on {T}?", "anything", "anyDay"),
    ("spending", "where did all the money go?", "anything", "anyDay"),
    ("spending", "how much did the hotel cost?", "stay", "anyDay"),
    ("spending", "am I over budget on {T}?", "anything", "anyDay"),
    ("spending", "what's the damage on dinners?", "food", "anyDay"),
    ("spending", "total cab spend on {T}?", "transfer", "anyDay"),
    ("spending", "how much have we spent today?", "anything", "today"),
    ("spending", "what did the flights come to?", "flight", "anyDay"),
    # balance
    ("balance", "who owes whom on {T}?", "anything", "anyDay"),
    ("balance", "how much do I owe {P}?", "anything", "anyDay"),
    ("balance", "does {P} owe me anything?", "anything", "anyDay"),
    ("balance", "what's my balance on {T}?", "anything", "anyDay"),
    ("balance", "do I need to settle up with anyone?", "anything", "anyDay"),
    ("balance", "how much do I get back from {T}?", "anything", "anyDay"),
    ("balance", "what do I owe {P} for {T}?", "anything", "anyDay"),
    ("balance", "am I even with {P}?", "anything", "anyDay"),
    # people
    ("people", "who's coming on {T}?", "anything", "anyDay"),
    ("people", "who paid for the villa?", "stay", "anyDay"),
    ("people", "how much has {P} paid so far?", "anything", "anyDay"),
    ("people", "who paid for the flights on {T}?", "flight", "anyDay"),
    ("people", "is {P} on {T}?", "anything", "anyDay"),
    ("people", "who paid for dinner last night?", "food", "anyDay"),
    ("people", "how many of us are going on {T}?", "anything", "anyDay"),
    # gaps
    ("gaps", "what's missing from {T}?", "anything", "anyDay"),
    ("gaps", "any nights without a hotel on {T}?", "stay", "anyDay"),
    ("gaps", "is anything not booked yet for {T}?", "anything", "anyDay"),
    ("gaps", "do we have free days on {T}?", "anything", "anyDay"),
    ("gaps", "have we booked a way to get there?", "anything", "anyDay"),
    # advice
    ("advice", "what should I pack for {T}?", "anything", "anyDay"),
    ("advice", "what's the weather like in {D} this time of year?", "anything", "anyDay"),
    ("advice", "best things to do in {D}?", "activity", "anyDay"),
    ("advice", "what food should we try in {D}?", "food", "anyDay"),
    ("advice", "any tips for {T}?", "anything", "anyDay"),
    ("advice", "is {D} safe at night?", "anything", "anyDay"),
    # chat
    ("chat", "hi", "anything", "anyDay"),
    ("chat", "thanks!", "anything", "anyDay"),
    ("chat", "thank you Equi", "anything", "anyDay"),
    ("chat", "good morning", "anything", "anyDay"),
    ("chat", "who made you?", "anything", "anyDay"),
    ("chat", "tell me a joke", "anything", "anyDay"),
    ("chat", "ok cool", "anything", "anyDay"),
]

HI = [
    ("overview", "{T} ka summary batao", "anything", "anyDay"),
    ("overview", "{T} kaisi chal rahi hai?", "anything", "anyDay"),
    ("overview", "{T} kab hai?", "anything", "anyDay"),
    ("overview", "{T} kitne din ki hai?", "anything", "anyDay"),
    ("schedule", "aaj kya plan hai?", "anything", "today"),
    ("schedule", "kal ka plan kya hai {T} mein?", "anything", "tomorrow"),
    ("schedule", "flight kitne baje hai?", "flight", "anyDay"),
    ("schedule", "kal subah sabse pehle kya hai?", "anything", "tomorrow"),
    ("schedule", "{T} mein next kya hai?", "anything", "anyDay"),
    ("schedule", "aaj check-in kitne baje hai?", "stay", "today"),
    ("schedule", "train kab chhootegi?", "train", "anyDay"),
    ("bookings", "{T} mein hum kahan ruk rahe hain?", "stay", "anyDay"),
    ("bookings", "kaunsi flights book hain {T} ke liye?", "flight", "anyDay"),
    ("bookings", "airport pickup book hai kya?", "transfer", "anyDay"),
    ("bookings", "kya kya activities hain {T} mein?", "activity", "anyDay"),
    ("spending", "{T} mein total kitna kharcha hua?", "anything", "anyDay"),
    ("spending", "khane pe kitna gaya?", "food", "anyDay"),
    ("spending", "sabse mehenga kya tha {T} mein?", "anything", "anyDay"),
    ("spending", "hotel ka kitna laga?", "stay", "anyDay"),
    ("spending", "flights pe kitna kharch hua {T} mein?", "flight", "anyDay"),
    ("spending", "aaj kitna kharcha ho gaya?", "anything", "today"),
    ("spending", "budget se upar toh nahi gaye?", "anything", "anyDay"),
    ("balance", "{P} ko kitna dena hai?", "anything", "anyDay"),
    ("balance", "{P} se kitna lena hai?", "anything", "anyDay"),
    ("balance", "hisaab kitna baaki hai?", "anything", "anyDay"),
    ("balance", "{T} mein mera kitna banta hai?", "anything", "anyDay"),
    ("balance", "kaun kisko kitna dega?", "anything", "anyDay"),
    ("balance", "kisi se settle karna baaki hai kya?", "anything", "anyDay"),
    ("balance", "{P} ka udhaar kitna hai?", "anything", "anyDay"),
    ("people", "{T} mein kaun kaun aa raha hai?", "anything", "anyDay"),
    ("people", "{P} ne ab tak kitna pay kiya?", "anything", "anyDay"),
    ("people", "hotel kisne pay kiya?", "stay", "anyDay"),
    ("people", "dinner ka bill kisne bhara?", "food", "anyDay"),
    ("gaps", "{T} mein kuch book karna baaki hai?", "anything", "anyDay"),
    ("gaps", "kisi raat hotel nahi hai kya?", "stay", "anyDay"),
    ("gaps", "koi din khali hai kya {T} mein?", "anything", "anyDay"),
    ("advice", "{D} mein kya khana chahiye?", "food", "anyDay"),
    ("advice", "{T} ke liye kya pack karu?", "anything", "anyDay"),
    ("advice", "{D} mein ghoomne ki best jagah kaunsi hai?", "activity", "anyDay"),
    ("advice", "{D} mein mausam kaisa hoga?", "anything", "anyDay"),
    ("chat", "kaise ho?", "anything", "anyDay"),
    ("chat", "shukriya", "anything", "anyDay"),
    ("chat", "namaste Equi", "anything", "anyDay"),
    ("chat", "theek hai, thanks", "anything", "anyDay"),
]

TRIPS_EN = [
    ("list all my trips", "all"), ("how many trips have I taken?", "all"),
    ("which trip cost the most?", "all"), ("compare my trips by spend", "all"),
    ("what trips do I have coming up?", "all"), ("show my past trips", "all"),
    ("which was my cheapest trip?", "all"), ("what's my balance across all trips?", "all"),
]
TRIPS_HI = [
    ("meri saari trips dikhao", "all"), ("kitni trips ho gayi ab tak?", "all"),
    ("sabse mehengi trip kaunsi thi?", "all"), ("aage kaunsi trips hain?", "all"),
]

FOLLOW_UPS = [
    ("and the other one?", None, "anyDay"),
    ("what about tomorrow?", None, "tomorrow"),
    ("and for {T}?", None, "anyDay"),
    ("aur {T} mein?", None, "anyDay"),
    ("kal ka?", None, "tomorrow"),
    ("same for {P}?", None, "anyDay"),
]
FOLLOW_TOPICS = ["spending", "balance", "bookings", "schedule", "people", "gaps"]


def trip_ref(rng, trips, hindi):
    """Picks a way of pointing at a trip; returns (phrase, trip label, title)."""
    options = ["named", "named", "named", "current"]
    if any(t["phase"] == "upcoming" for t in trips):
        options.append("next")
    if any(t["phase"] == "past" for t in trips):
        options.append("previous")
    kind = rng.choice(options)
    if kind == "named":
        t = rng.choice(trips)
        if hindi:
            phrase = rng.choice([f"{t['title']} wali trip", t["title"], f"{t['place']} wali trip"])
        else:
            phrase = rng.choice([f"the {t['title']} trip", t["title"], f"the {t['place']} trip", f"our {t['place']} trip"])
        return phrase, "named", t["title"]
    phrases = {
        ("current", False): ["this trip", "the trip", "our trip"],
        ("current", True): ["is trip", "is trip", "abhi wali trip"],
        ("next", False): ["my next trip", "the next trip", "our upcoming trip"],
        ("next", True): ["agli trip", "next trip"],
        ("previous", False): ["my last trip", "the previous trip", "our last trip"],
        ("previous", True): ["pichli trip", "last wali trip"],
    }
    return rng.choice(phrases[(kind, hindi)]), kind, ""


def place_ref(rng, trips):
    """A place: most often a listed trip's destination, which then names that trip."""
    if rng.random() < 0.75:
        t = rng.choice(trips)
        return t["place"], "named", t["title"]
    return rng.choice(OTHER_PLACES), "unspecified", ""


def roughen(rng, text):
    """How people actually type: lowercase, no question mark, now and then."""
    if rng.random() < 0.3:
        text = text.lower()
    if rng.random() < 0.25:
        text = text.rstrip("?!")
    if rng.random() < 0.1:
        text = text[0].upper() + text[1:]
    return text


def label(topic, trip, title, category, person, day):
    return json.dumps(
        {"topic": topic, "trip": trip, "tripTitle": title, "category": category, "person": person, "day": day},
        ensure_ascii=False, separators=(",", ":"),
    )


def query_prompt(trips, question, focus=None, previous=None):
    prompt = "Trips:\n" + trip_lines(trips) + "\n"
    if focus:
        prompt += f'Being discussed: "{focus}"\n'
    if previous:
        prompt += f"Previous question: {previous}\n"
    return prompt + f"Question: {question}"


def make_query(rng):
    trips = make_trip_list(rng)
    live = next((t for t in trips if t["phase"] == "live"), None)
    focus = live["title"] if live and rng.random() < 0.5 else None
    roll = rng.random()

    if roll < 0.10:  # several trips
        text, trip = rng.choice(TRIPS_HI if rng.random() < 0.35 else TRIPS_EN)
        return query_prompt(trips, roughen(rng, text), focus), label("trips", trip, "", "anything", "", "anyDay")

    if roll < 0.20:  # follow-up that keeps the previous topic
        topic = rng.choice(FOLLOW_TOPICS)
        pool = [q for q in EN + HI if q[0] == topic]
        prev_tpl = rng.choice(pool)
        prev = fill(rng, prev_tpl[1], trips, hindi=prev_tpl in HI)[0]
        text, _, day = rng.choice(FOLLOW_UPS)
        q, trip, title, person = fill(rng, text, trips, hindi=text.startswith("aur") or text == "kal ka?")
        cat = prev_tpl[2]
        return (query_prompt(trips, roughen(rng, q), focus, previous=prev),
                label(topic, trip, title, cat, person, day))

    hindi = rng.random() < 0.4
    topic, text, category, day = rng.choice(HI if hindi else EN)
    q, trip, title, person = fill(rng, text, trips, hindi)
    return query_prompt(trips, roughen(rng, q), focus), label(topic, trip, title, category, person, day)


def fill(rng, text, trips, hindi):
    """Fills a template's slots; returns (question, trip, tripTitle, person)."""
    trip, title, person = "unspecified", "", ""
    if "{T}" in text:
        phrase, trip, title = trip_ref(rng, trips, hindi)
        text = text.replace("{T}", phrase)
    if "{D}" in text:
        place, trip, title = place_ref(rng, trips)
        text = text.replace("{D}", place)
    if "{P}" in text:
        person = rng.choice(PEOPLE)
        text = text.replace("{P}", person)
    return text, trip, title, person


# MARK: - Itinerary days
#
# Each row maker returns (row text, title, kind, has_time).

AIRLINES = [("6E", "IndiGo"), ("AI", "Air India"), ("UK", "Vistara"), ("QP", "Akasa Air"), ("SG", "SpiceJet"),
            ("EK", "Emirates"), ("SQ", "Singapore Airlines"), ("TG", "Thai Airways")]
CITIES = ["Mumbai", "Delhi", "Bengaluru", "Goa", "Chennai", "Hyderabad", "Kochi", "Jaipur", "Leh", "Dubai",
          "Singapore", "Bangkok", "Phuket", "Rome", "Paris", "Tokyo", "Denpasar", "Udaipur"]
AIRPORTS = ["Dabolim Airport", "Mopa Airport", "CSMT", "T2", "Terminal 3", "Kempegowda Airport", "CDG",
            "Fiumicino", "Ngurah Rai Airport", "Narita", "Changi", "Leh Airport"]
TRAINS = [("12951", "Rajdhani Express"), ("22439", "Vande Bharat"), ("12009", "Shatabdi Express"),
          ("16345", "Netravati Express"), ("12432", "Trivandrum Rajdhani"), ("12916", "Ashram Express")]
HOTELS = ["Taj Holiday Village", "Zostel Manali", "The Leela Palace", "Hotel Raas", "Ahilya by the Sea",
          "Lemon Tree Premier", "Treebo Trend Cosmo", "The Oberoi Udaivilas", "Grand Hyatt", "Hotel Artemide",
          "Ibis Styles", "Evolve Back Coorg", "Alsisar Haveli", "The Tamara", "OYO Townhouse 142"]
STAY_ROWS = ["Check-in {h}", "Hotel check-in: {h}", "Check in at {h}", "Check-out {h}", "Stay at {h}"]
HOUSEBOATS = ["Houseboat stay Alleppey", "Tent stay Pangong Lake", "Homestay in Mawlynnong"]
ACTIVITIES = ["Dudhsagar Waterfalls tour", "Paragliding at Solang Valley", "Sunset cruise on Mandovi",
              "Vatican Museums tour", "Scuba diving at Grande Island", "Colosseum guided tour",
              "Amber Fort visit", "River rafting Shivpuri", "Coffee plantation walk", "Khardung La drive",
              "Desert safari", "Old Town walking tour", "Ubud rice terraces", "Elephant Falls visit",
              "City Palace tour", "Louvre visit", "teamLab Planets", "Phi Phi island hopping",
              "Ganga aarti at Triveni Ghat", "Virupaksha Temple visit", "Snorkelling at Havelock"]
RESTAURANTS = ["Britto's", "Thalassa", "Gunpowder", "Karavalli", "Trattoria da Enzo", "Johnny's Cafe",
               "Chokhi Dhani", "Paragon", "Ichiran", "Bukhara", "Le Cafe", "Fisherman's Wharf"]
MEAL_ROWS = [("Lunch at {r}", "Lunch at {r}"), ("Dinner {r}", "Dinner {r}"), ("Hotel breakfast", "Hotel breakfast"),
             ("Breakfast at hotel", "Hotel breakfast"), ("Welcome dinner at {r}", "Welcome dinner"),
             ("Farewell dinner", "Farewell dinner"), ("Lunch break", "Lunch")]
OTHER_ROWS = [("Free time for shopping at Anjuna market", "Free time"), ("Rest day at leisure", "Rest day"),
              ("Visa appointment at VFS", "Visa appointment"), ("Currency exchange at Thomas Cook", "Currency exchange"),
              ("Group photo at the resort", "Group photo"), ("Buffer time", "Buffer time")]


MEAL_HOURS = {"breakfast": (7, 9), "lunch": (12, 14), "dinner": (19, 22)}


def clock(rng, title=""):
    hours = next((r for word, r in MEAL_HOURS.items() if word in title.lower()), (5, 22))
    h, m = rng.randint(*hours), rng.choice([0, 0, 15, 30, 45, 10, 50])
    hhmm = f"{h:02d}:{m:02d}"
    style = rng.random()
    if style < 0.55:
        shown = hhmm
    elif style < 0.8:
        h12 = h % 12 or 12
        shown = f"{h12}:{m:02d} {'AM' if h < 12 else 'PM'}"
    elif style < 0.9:
        shown = f"{h:02d}{m:02d} hrs"
    else:
        shown = f"{h:02d}.{m:02d}"
    return hhmm, shown


def row_flight(rng):
    code, name = rng.choice(AIRLINES)
    num = f"{code} {rng.randint(100, 9999)}"
    a, b = rng.sample(CITIES, 2)
    text = rng.choice([f"Flight {num} {a} to {b}", f"{name} {num} {a} → {b}", f"Flight {num} ({a}–{b}), web check-in done",
                       f"Depart {a} on {num} to {b}"])
    return text, f"Flight {num}", "flight"


def row_train(rng):
    num, name = rng.choice(TRAINS)
    a, b = rng.sample(CITIES[:9], 2)
    text = rng.choice([f"Train {num} {name} {a} to {b}", f"{name} ({num}) dep {a}, 3A, PNR confirmed",
                       f"Board {name} {num} at {a}"])
    return text, f"{name} {num}", "train"


def row_transfer(rng):
    airport = rng.choice(AIRPORTS)
    hotel = rng.choice(HOTELS)
    options = [
        (f"Airport transfer {airport} to {hotel}", "Airport transfer"),
        (f"Airport drop to {airport}", "Airport drop"),
        (f"Cab pickup from {hotel}", "Cab pickup"),
        (f"Private taxi to {rng.choice(['Rohtang Pass', 'Baga Beach', 'Old Goa', 'Nubra Valley', 'Munnar'])}", "Private taxi"),
        (f"Railway station drop, {rng.choice(['Madgaon', 'Jaipur Junction', 'Haridwar', 'Ernakulam'])}", "Station drop"),
        (f"Ferry to {rng.choice(['Havelock', 'Phi Phi', 'Divar Island'])}", "Ferry"),
        (f"Scooter rental for the day", "Scooter rental"),
        (f"Ola to {hotel}", "Ola ride"),
    ]
    text, title = rng.choice(options)
    return text, title, "transfer"


def row_stay(rng):
    if rng.random() < 0.15:
        text = rng.choice(HOUSEBOATS)
        return text, text.replace(" stay", "").replace("Homestay in", "Homestay"), "stay"
    h = rng.choice(HOTELS)
    tpl = rng.choice(STAY_ROWS)
    title = f"Check-out {h}" if tpl.startswith("Check-out") else h
    return tpl.format(h=h), title, "stay"


def row_activity(rng):
    a = rng.choice(ACTIVITIES)
    text = rng.choice([a, f"{a} (guide included)", f"{a}, meet at lobby", f"{a} — 4 pax"])
    return text, a, "activity"


def row_meal(rng):
    tpl, title = rng.choice(MEAL_ROWS)
    r = rng.choice(RESTAURANTS)
    return tpl.format(r=r), title.format(r=r), "meal"


def row_other(rng):
    text, title = rng.choice(OTHER_ROWS)
    return text, title, "other"


ROW_MAKERS = [(row_flight, 2), (row_train, 1), (row_transfer, 3), (row_stay, 2), (row_activity, 4),
              (row_meal, 3), (row_other, 1)]


def make_day(rng):
    place = rng.choice(TRIPS)
    n = rng.randint(2, 7)
    rows = []
    makers = [m for m, w in ROW_MAKERS for _ in range(w)]
    for _ in range(n):
        text, title, kind = rng.choice(makers)(rng)
        timed = kind != "stay" or rng.random() < 0.4
        if rng.random() < 0.85 and timed:
            hhmm, shown = clock(rng, title)
            sep = rng.choice([" ", " – ", " | ", ": "])
            text = f"{shown}{sep}{text}"
        else:
            hhmm = ""
        rows.append((hhmm, text, title, kind))
    rows.sort(key=lambda r: r[0] or "99")  # itineraries are written in time order; untimed rows last
    day_no = rng.randint(1, 8)
    heading = rng.choice([f"Day {day_no}", f"Day {day_no} · Arrival", f"Day {day_no} · Sightseeing",
                          f"Day {day_no} · Departure", f"Day {day_no} · At leisure", ""])
    lines = [f"Trip to {place[1]}."]
    if heading:
        lines.append(f"This day: {heading}.")
    lines.append(f"It has {n} row{'s' if n != 1 else ''}.")
    lines.append("")
    lines += [r[1] for r in rows]
    answer = {"items": [{"title": r[2], "time": r[0], "kind": r[3]} for r in rows]}
    return "\n".join(lines), json.dumps(answer, ensure_ascii=False, separators=(",", ":"))


# MARK: - Output

def example(system, prompt, response):
    return f"### Instruction\n{system}\n\n{prompt}\n\n### Response\n{response}\n"


def unique(maker, rng, count, seen):
    out = []
    while len(out) < count:
        prompt, response = maker(rng)
        if prompt in seen:
            continue
        seen.add(prompt)
        out.append((prompt, response))
    return out


def main():
    rng = random.Random(SEED)
    corpus = OUT / "corpus"
    corpus.mkdir(parents=True, exist_ok=True)

    seen = set()
    queries = unique(make_query, rng, QUERY_TRAIN + QUERY_BENCH, seen)
    days = unique(make_day, rng, DAY_TRAIN + DAY_BENCH, seen)
    q_train, q_bench = queries[:QUERY_TRAIN], queries[QUERY_TRAIN:]
    d_train, d_bench = days[:DAY_TRAIN], days[DAY_TRAIN:]

    (corpus / "equitrip-questions.txt").write_text(
        "Equitrip · Equi question reading — worked examples\n\n"
        + "\n".join(example(QUERY_SYSTEM, p, r) for p, r in q_train), encoding="utf-8")
    (corpus / "equitrip-itinerary-days.txt").write_text(
        "Equitrip · itinerary day reading — worked examples\n\n"
        + "\n".join(example(DAY_SYSTEM, p, r) for p, r in d_train), encoding="utf-8")
    shutil.copy(OUT / "glossary.txt", corpus / "equitrip-glossary.txt")

    bench = [(QUERY_SYSTEM, p, r) for p, r in q_bench] + [(DAY_SYSTEM, p, r) for p, r in d_bench]
    rng.shuffle(bench)
    samples = [{"sample_num": i + 1, "instruction": f"{s}\n\n{p}", "response": r} for i, (s, p, r) in enumerate(bench)]
    (OUT / "benchmark.json").write_text(json.dumps(samples, ensure_ascii=False, indent=1), encoding="utf-8")

    for f in sorted(corpus.iterdir()):
        print(f"{f.relative_to(ROOT)}  {f.stat().st_size / 1024:.0f} KB")
    print(f"docs/nugen/benchmark.json  {len(samples)} samples")


if __name__ == "__main__":
    main()
