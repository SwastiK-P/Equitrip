# -*- coding: utf-8 -*-
from base import *

W, H = 980, 1470
d = Doc(W, H)

# header
d.T(70, 72, "Equitrip", 34, INK, "800")
d.T(70, 102, "How a trip is created and settled", 17, INK2, "500")
d.A(f'<line x1="70" y1="126" x2="{W-70}" y2="126" stroke="{STK}" stroke-width="1.5"/>')

RAIL = 104          # circle centre x
CX, CW = 148, W - 148 - 70

steps = [
    ("Start",   "Blank trip, a booking PDF, or a 6-character invite code.", None),
    ("Read",    "Apple Foundation Models and Vision extract the bookings.", "on device"),
    ("Verify",  "Rules check every price and date against the source text.", "deterministic"),
    ("Assign",  "Per booking: participants, who paid, which split model.", "5 split modes"),
    ("Share",   "Trip is published; members join and see the same plan.", "Supabase"),
    ("Run",     "Expenses and edits land; the ledger recomputes for all.", "realtime"),
    ("Settle",  "Balances are netted into the fewest transfers.", "planned"),
]

CH, GAP = 118, 44
y0 = 176
for i, (title, sub, tag) in enumerate(steps):
    y = y0 + i * (CH + GAP)
    planned = tag == "planned"
    # connector
    if i:
        d.PT(f"M{RAIL},{y-GAP+2} L{RAIL},{y-8}", INK, 2.0,
             dash="6 6" if planned else None)
    # number
    d.A(f'<circle cx="{RAIL}" cy="{y+30}" r="19" fill="{"none" if planned else INK}" '
        f'stroke="{INK3 if planned else "none"}" stroke-width="1.8" stroke-dasharray="5 4"/>')
    d.T(RAIL, y+37, str(i+1), 18, INK3 if planned else BG, "800", "middle")
    # card
    if planned:
        d.R(CX, y, CW, CH, 18, "#FFFFFF", INK3, 1.5, dash="7 6", op=0.85)
    else:
        d.R(CX, y, CW, CH, 18, "#FFFFFF", STK, 1.5, ex=' filter="url(#sh)"')
    d.T(CX+34, y+50, title, 25, INK3 if planned else INK, "700")
    d.T(CX+34, y+83, sub, 16.5, INK2, "400")
    if tag:
        tw = len(tag) * 8.0 + 26
        col = INK3 if planned else ACC
        d.R(CX+CW-34-tw, y+34, tw, 25, 12.5, col, op=0.12)
        d.T(CX+CW-34-tw/2, y+51, tag.upper(), 11.5, col, "800", "middle", ls=1.1)

# privacy footer
FY = y0 + 7*(CH+GAP) + 12
d.R(70, FY, W-140, 74, 16, "#FFFFFF", ACC, 1.6, dash="8 7")
d.T(102, FY+32, "Documents never leave the phone", 18, ACC, "700")
d.T(102, FY+56, "PDFs, boarding passes and passport data are read on the device only.", 15, INK2)

d.save("/Users/swastik/Developer/Equitrip/docs/equitrip-flow.svg")
print("flow ok", FY+74)
