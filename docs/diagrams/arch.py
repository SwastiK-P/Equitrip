# -*- coding: utf-8 -*-
"""Equitrip system architecture — 700x900, plain group/box style, transparent."""
import base64, html, os
W, H = 700, 660
ROOT = "/Users/swastik/Developer/Equitrip"
F = "'Helvetica Neue',Helvetica,Arial,sans-serif"
INK, SUB, ARR, GRP = "#1F1F23", "#55555E", "#5A5A5A", "#9C9C9C"
FRONT=("#D6E6F7","#7FA9CF"); AI=("#D9EFE1","#6FAE89")
CORE=("#E4DEF6","#8B80C9");  BACK=("#F2DFF2","#B57FB5"); EXT=("#FBEED6","#D3A84F")

o=[]
def A(s): o.append(s)
def T(x,y,s,sz=11,fill=INK,wt="400",anc="middle"):
    A(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{F}" font-size="{sz}" font-weight="{wt}" '
      f'fill="{fill}" text-anchor="{anc}">{html.escape(s,quote=False)}</text>')
def R(x,y,w,h,fill="none",stroke=GRP,sw=1.0,r=3):
    A(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill}" '
      f'stroke="{stroke}" stroke-width="{sw}"/>')
def P(d,sw=1.1,head=True):
    mk=' marker-end="url(#a)"' if head else ""
    A(f'<path d="{d}" fill="none" stroke="{ARR}" stroke-width="{sw}"{mk}/>')

_c={}
def img(name,x,y,s):
    if name not in _c: _c[name]=base64.b64encode(open(os.path.join(ROOT,name),'rb').read()).decode()
    A(f'<image x="{x:.1f}" y="{y:.1f}" width="{s}" height="{s}" xlink:href="data:image/png;base64,{_c[name]}"/>')
GM=('<path fill="#4285f4" d="M58 108h14V74L52 59v43c0 3.32 2.69 6 6 6"/>'
    '<path fill="#34a853" d="M120 108h14c3.32 0 6-2.69 6-6V59l-20 15"/>'
    '<path fill="#fbbc04" d="M120 48v26l20-15v-8c0-7.42-8.47-11.65-14.4-7.2"/>'
    '<path fill="#ea4335" d="M72 74V48l24 18 24-18v26L96 92"/>'
    '<path fill="#c5221f" d="M52 51v8l20 15V48l-5.6-4.2c-5.94-4.45-14.4-.22-14.4 7.2"/>')
def gmail(x,y,s):
    A(f'<g transform="translate({x:.1f},{y+s*0.14:.1f}) scale({s/88.0:.4f}) translate(-52,-42)">{GM}</g>')

def group(x,y,w,h,title):
    R(x,y,w,h); T(x+w/2, y+18, title, 12, "#333", "600")

def tech(x,y,w,h,pal,icon,l1,l2=None,isz=22):
    R(x,y,w,h,pal[0],pal[1],1.1,4)
    if icon:
        iy = y+h/2-isz/2
        if icon=="gmail": gmail(x+12, iy, isz)
        else: img(icon, x+12, iy, isz)
        cx = x+42+(w-52)/2
    else:
        cx = x+w/2
    if l2:
        T(cx, y+h/2-2, l1, 11.5, INK, "600"); T(cx, y+h/2+14, l2, 10, SUB)
    else:
        T(cx, y+h/2+4, l1, 11.5, INK, "600")

A(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
  f'width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
A(f'<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="5.5" markerHeight="5.5" '
  f'orient="auto-start-reverse"><path d="M0,2 L9,5 L0,8 z" fill="{ARR}"/></marker></defs>')

# 1. Frontend
group(20, 28, 400, 84, "Frontend")
tech(100, 54, 240, 40, FRONT, "swift.png", "Swift + SwiftUI", "iPhone App", 20)

# 2. On-device intelligence
group(20, 136, 400, 100, "On-Device Intelligence")
tech(44, 166, 168, 48, AI, "vision.png", "Apple Vision", "PDFKit", 18)
tech(228, 166, 168, 48, AI, "Foundation.png", "Apple Foundation", "Models", 18)
P("M216,190 L224,190")

# 3. Equitrip Core
group(20, 260, 400, 218, "Equitrip Core")
rows = ["Booking Validation","Trip & Itinerary Engine","Participant & Split Engine",
        "Dynamic Ledger","Settlement Algorithm"]
for i,nm in enumerate(rows):
    y = 292 + i*36
    tech(44, y, 352, 28, CORE, None, nm)
    if i: P(f"M120,{y-8} L120,{y-2}")

# 4. Backend
group(20, 504, 400, 112, "Backend")
tech(40, 540, 196, 46, BACK, "supabase.png", "Supabase", "Auth · Realtime · Storage", 20)
cx0, cy0, cw, ch, e = 282, 538, 84, 46, 9
A(f'<path d="M{cx0},{cy0+e} L{cx0},{cy0+ch-e} A{cw/2},{e} 0 0 0 {cx0+cw},{cy0+ch-e} L{cx0+cw},{cy0+e} Z" '
  f'fill="{BACK[0]}" stroke="{BACK[1]}" stroke-width="1.1"/>')
A(f'<ellipse cx="{cx0+cw/2}" cy="{cy0+e}" rx="{cw/2}" ry="{e}" fill="{BACK[0]}" stroke="{BACK[1]}" stroke-width="1.1"/>')
T(cx0+cw/2, cy0+ch+18, "PostgreSQL", 11, INK, "600")
P(f"M240,563 L{cx0-4},563")

# 5. External APIs
group(446, 260, 234, 218, "External APIs")
ext = [("aviationstack.png","AviationStack","live flight info", 292, 342),
       ("mapkit.png","MapKit","maps and places",              352, 342),
       ("gmail","Gmail API","receipt emails",                  412, 414)]
for icon, nm, sub, y, ty in ext:
    tech(462, y, 202, 48, EXT, icon, nm, sub, 18)
    P(f"M458,{y+24} C430,{y+24} 424,{ty} 400,{ty}")

# connections
P("M220,96 C220,124 128,132 128,162")
P("M312,216 C312,250 220,250 220,288")
P("M100,80 C26,120 14,270 40,342")
P("M140,466 C140,494 140,510 140,536")
P("M322,536 C322,516 300,500 300,482")

A('</svg>')
open("/Users/swastik/Developer/Equitrip/docs/equitrip-architecture.svg","w").write("\n".join(o))
print("ok")
