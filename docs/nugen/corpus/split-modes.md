# Split modes and shares

## Split modes

There are five split modes. Each one answers the question "whose cost is this?" differently.
- Split equally (equal): the cost is divided evenly across everyone on the trip, whether or not they are on this booking.
- Only participants (participants): the cost is divided evenly, but only across the people named on this booking.
- Exact amounts (custom): someone types what each person owes. The amounts must add up to the cost. It is the only mode where shares are not derived from the cost.
- Organiser pays (organiser): the trip's organisers carry the cost, divided between them if there is more than one organiser.
- One person (individual): one named person carries the whole cost.
An older sixth mode called "room" was removed because it behaved exactly like "Only participants"; old rows stored as room are read as participants so nobody's arithmetic changes.

## Whole-unit shares

Even splits are made in whole units. Nobody settles 333.33 rupees; they settle 333. Everyone gets the whole share and the leftover (less than one unit per head, plus any fraction already in the cost) lands on one person, the holder, so the parts always add up exactly to the cost. Example: 1000 rupees split equally across 3 people gives shares of 333, 333 and 334.
