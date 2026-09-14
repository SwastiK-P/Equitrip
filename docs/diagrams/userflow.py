# -*- coding: utf-8 -*-
"""Equitrip user flow — vertical, 700x900, transparent."""
import base64, html, os
W, H = 700, 900
ROOT = "/Users/swastik/Developer/Equitrip"
SANS = "'SF Pro Display','SF Pro Text','Helvetica Neue',Helvetica,Arial,sans-serif"
INK, INK2, INK3 = "#1A1109", "#6B5B50", "#8E8899"
ACC, GRN, AMB, BLU, VIO, RED, STONE = "#4B45C6","#1E7A55","#D97706","#2F6FED","#7C4DE0","#C5442E","#7A6E63"
STK, LINE = "#EDE4DA", "#8C8378"

o=[]
def A(s): o.append(s)
def esc(s): return html.escape(s, quote=False)
def wrap(t,size,maxw,f=0.50):
    ws,ls,cur=t.split(),[],""
    for w in ws:
        c=(cur+" "+w).strip()
        if len(c)*size*f<=maxw or not cur: cur=c
        else: ls.append(cur); cur=w
    if cur: ls.append(cur)
    return ls
def T(x,y,s,sz=12,fill=INK2,wt="400",anc="start",ls=0):
    A(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{SANS}" font-size="{sz}" font-weight="{wt}" '
      f'fill="{fill}" text-anchor="{anc}" letter-spacing="{ls}">{esc(s)}</text>')
def PARA(x,y,t,sz,maxw,fill=INK2,lh=15,mx=2):
    for i,l in enumerate(wrap(t,sz,maxw)[:mx]): T(x,y+i*lh,l,sz,fill)
def R(x,y,w,h,r,fill,stroke=None,sw=1.3,op=1.0,ex=""):
    st=f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    A(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill}"{st} opacity="{op}"{ex}/>')
def P(d,stroke=LINE,sw=1.5,dash=None,head=True):
    dd=f' stroke-dasharray="{dash}"' if dash else ""
    mk=' marker-end="url(#ah)"' if head else ""
    A(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" '
      f'stroke-linejoin="round"{dd}{mk}/>')

_c={}
def logo(name,x,y,s):
    if name not in _c: _c[name]=base64.b64encode(open(os.path.join(ROOT,name),'rb').read()).decode()
    A(f'<image x="{x:.1f}" y="{y:.1f}" width="{s}" height="{s}" xlink:href="data:image/png;base64,{_c[name]}"/>')
GM=('<path fill="#4285f4" d="M58 108h14V74L52 59v43c0 3.32 2.69 6 6 6"/>'
    '<path fill="#34a853" d="M120 108h14c3.32 0 6-2.69 6-6V59l-20 15"/>'
    '<path fill="#fbbc04" d="M120 48v26l20-15v-8c0-7.42-8.47-11.65-14.4-7.2"/>'
    '<path fill="#ea4335" d="M72 74V48l24 18 24-18v26L96 92"/>'
    '<path fill="#c5221f" d="M52 51v8l20 15V48l-5.6-4.2c-5.94-4.45-14.4-.22-14.4 7.2"/>')
def gmail(x,y,s): A(f'<g transform="translate({x:.1f},{y+s*0.14:.1f}) scale({s/88.0:.4f}) translate(-52,-42)">{GM}</g>')

# ── glyphs (drawn at 0..1 in a unit box, scaled into the tile) ────────
def glyph(kind,cx,cy,s,col):
    k=s/24.0
    def p(d,fill="none",sw=1.9): A(f'<path d="{d}" fill="{fill}" stroke="{col}" stroke-width="{sw*k}" stroke-linecap="round" stroke-linejoin="round"/>')
    x,y=cx-s/2,cy-s/2
    if kind=="spark":
        for (ox,oy,r) in [(0.5,0.42,0.30),(0.82,0.80,0.16)]:
            X,Y,Rr=x+ox*s,y+oy*s,r*s
            p(f"M{X},{Y-Rr} C{X+Rr*0.16},{Y-Rr*0.16} {X+Rr*0.16},{Y-Rr*0.16} {X+Rr},{Y} "
              f"C{X+Rr*0.16},{Y+Rr*0.16} {X+Rr*0.16},{Y+Rr*0.16} {X},{Y+Rr} "
              f"C{X-Rr*0.16},{Y+Rr*0.16} {X-Rr*0.16},{Y+Rr*0.16} {X-Rr},{Y} "
              f"C{X-Rr*0.16},{Y-Rr*0.16} {X-Rr*0.16},{Y-Rr*0.16} {X},{Y-Rr} Z", col, 0)
    elif kind=="pencil":
        p(f"M{x+.22*s},{y+.78*s} L{x+.30*s},{y+.58*s} L{x+.66*s},{y+.22*s} L{x+.80*s},{y+.36*s} "
          f"L{x+.44*s},{y+.72*s} Z")
    elif kind=="qr":
        for (a,b) in [(.18,.18),(.60,.18),(.18,.60)]:
            A(f'<rect x="{x+a*s}" y="{y+b*s}" width="{.22*s}" height="{.22*s}" rx="{.05*s}" fill="none" stroke="{col}" stroke-width="{1.9*k}"/>')
        A(f'<rect x="{x+.62*s}" y="{y+.62*s}" width="{.18*s}" height="{.18*s}" rx="{.04*s}" fill="{col}"/>')
    elif kind=="mail":
        A(f'<rect x="{x+.16*s}" y="{y+.26*s}" width="{.68*s}" height="{.48*s}" rx="{.08*s}" fill="none" stroke="{col}" stroke-width="{1.9*k}"/>')
        p(f"M{x+.20*s},{y+.32*s} L{x+.50*s},{y+.54*s} L{x+.80*s},{y+.32*s}")
    elif kind=="doc":
        p(f"M{x+.26*s},{y+.16*s} L{x+.60*s},{y+.16*s} L{x+.76*s},{y+.34*s} L{x+.76*s},{y+.84*s} "
          f"L{x+.26*s},{y+.84*s} Z")
        p(f"M{x+.38*s},{y+.52*s} L{x+.64*s},{y+.52*s}"); p(f"M{x+.38*s},{y+.66*s} L{x+.64*s},{y+.66*s}")
    elif kind=="bulb":
        A(f'<circle cx="{cx}" cy="{cy-.09*s}" r="{.26*s}" fill="none" stroke="{col}" stroke-width="{1.9*k}"/>')
        p(f"M{cx-.12*s},{cy+.24*s} L{cx+.12*s},{cy+.24*s}")
        p(f"M{cx-.08*s},{cy+.36*s} L{cx+.08*s},{cy+.36*s}")
    elif kind=="case":
        A(f'<rect x="{x+.14*s}" y="{y+.34*s}" width="{.72*s}" height="{.48*s}" rx="{.08*s}" fill="none" stroke="{col}" stroke-width="{1.9*k}"/>')
        p(f"M{x+.36*s},{y+.34*s} L{x+.36*s},{y+.20*s} L{x+.64*s},{y+.20*s} L{x+.64*s},{y+.34*s}")
    elif kind=="card":
        A(f'<rect x="{x+.14*s}" y="{y+.28*s}" width="{.72*s}" height="{.44*s}" rx="{.08*s}" fill="none" stroke="{col}" stroke-width="{1.9*k}"/>')
        p(f"M{x+.14*s},{y+.44*s} L{x+.86*s},{y+.44*s}")
    elif kind=="grid":
        for (a,b) in [(.18,.18),(.54,.18),(.18,.54),(.54,.54)]:
            A(f'<rect x="{x+a*s}" y="{y+b*s}" width="{.28*s}" height="{.28*s}" rx="{.07*s}" fill="{col}"/>')
    elif kind=="person":
        A(f'<circle cx="{cx}" cy="{cy-.14*s}" r="{.18*s}" fill="none" stroke="{col}" stroke-width="{1.9*k}"/>')
        p(f"M{cx-.28*s},{cy+.30*s} C{cx-.24*s},{cy+.06*s} {cx+.24*s},{cy+.06*s} {cx+.28*s},{cy+.30*s}")
    elif kind=="net":
        pts=[(.50,.20),(.22,.72),(.78,.72)]
        for (a,b) in pts: A(f'<circle cx="{x+a*s}" cy="{y+b*s}" r="{.10*s}" fill="{col}"/>')
        p(f"M{x+.50*s},{y+.20*s} L{x+.22*s},{y+.72*s} M{x+.50*s},{y+.20*s} L{x+.78*s},{y+.72*s} "
          f"M{x+.22*s},{y+.72*s} L{x+.78*s},{y+.72*s}", sw=1.5)

def tile(x,y,s,tint,kind,white=False):
    R(x,y,s,s,s*0.28,"#FFFFFF" if white else tint, op=0.16 if not white else 0.18)
    glyph(kind,x+s/2,y+s/2,s*0.62,"#FFFFFF" if white else tint)

def chip(x,y,label,mark):
    w = len(label)*5.6 + (30 if mark else 14)
    R(x,y,w,20,10,"#F4F1F7")
    if mark=="gmail": gmail(x+6,y+3,14)
    elif mark: logo(mark,x+6,y+3,14)
    T(x+(26 if mark else 8), y+14, label, 10, INK, "700")
    return w

def card(x,y,w,h,tint,kind,title,detail,ch=None,mark=None,ts=15.5,ds=11.5):
    R(x,y,w,h,16,"#FFFFFF",STK,1.3,ex=' filter="url(#sh)"')
    tile(x+16,y+15,34,tint,kind)
    T(x+60,y+37,title,ts,INK,"700")
    PARA(x+16,y+70,detail,ds,w-32,INK2,14,1)
    if ch: chip(x+16,y+80,ch,mark)

A(f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
  f'width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
A('<defs>'
  f'<marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="5.5" markerHeight="5.5" orient="auto-start-reverse"><path d="M0,2 L9,5 L0,8 z" fill="{LINE}"/></marker>'
  '<filter id="sh" x="-25%" y="-25%" width="150%" height="160%"><feDropShadow dx="0" dy="2" stdDeviation="5" flood-color="#59331A" flood-opacity="0.10"/></filter>'
  f'<linearGradient id="pg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{ACC}"/><stop offset="1" stop-color="#3A34A8"/></linearGradient>'
  '</defs>')

def stage(y,t): T(24,y,t,10.5,INK3,"800",ls=1.7)

# R1
stage(20,"STARTING A TRIP")
pills = [("spark",ACC,"Auto detection","Gmail, ticket PDFs, photos"),
         ("pencil",STONE,"Build it by hand","Days, bookings and costs"),
         ("qr",GRN,"Join a trip","Scan the organiser's QR")]
for i,(g,tint,t,d) in enumerate(pills):
    x = 24 + i*224
    R(x,32,204,58,16,"#FFFFFF",STK,1.3,ex=' filter="url(#sh)"')
    tile(x+12,47,28,tint,g)
    T(x+50,55,t,12.5,INK,"700"); T(x+50,72,d,10,INK2)

# R2
stage(132,"DATA SOURCES")
card(24,144,314,100,RED,"mail","Gmail",
     "Receipts that land while you are away.","Gmail API","gmail")
card(362,144,314,100,BLU,"doc","Tickets and photos",
     "Confirmations, boarding passes, bills.","PDFKit · Vision","vision.png")

# R3
stage(268,"ON-DEVICE PROCESSING")
card(24,280,314,100,ACC,"spark","Read and place it",
     "Vendor, amount, date and travellers.","Foundation Models","Foundation.png")
dcx,dcy,dw,dh = 181,438,92,40
A(f'<path d="M{dcx},{dcy-dh} L{dcx+dw},{dcy} L{dcx},{dcy+dh} L{dcx-dw},{dcy} Z" fill="#FFFFFF" '
  f'stroke="{AMB}" stroke-width="1.6"/>')
T(dcx,dcy-4,"Conflicts or",12.5,INK,"700","middle"); T(dcx,dcy+13,"duplicates?",12.5,INK,"700","middle")
card(362,390,314,100,AMB,"bulb","Suggested fixes",
     "Merge duplicates and fill in the gaps.","Foundation Models","Foundation.png")

# R4
stage(516,"TRIP CREATION")
card(24,528,314,100,ACC,"case","Trip created",
     "Itinerary, bookings and travellers.","Supabase","supabase.png")
card(362,528,314,100,GRN,"card","Expense ledger",
     "Every cost tied to the people in it.")

# R5
stage(654,"SETTLEMENT")
R(24,666,652,86,18,"url(#pg)")
tile(44,684,34,"#FFF","net",white=True)
T(92,702,"Settlement engine",18,"#FFFFFF","800")
PARA(92,724,"Nets everyone off and finds the fewest transfers.",
     12,410,"#D9D6FA",15,1)
T(578,703,"Who pays whom,",11.5,"#FFFFFF","700","middle")
T(578,719,"and how much",11.5,"#FFFFFF","700","middle")

# R6
stage(776,"OUTPUTS")
outs = [("grid",BLU,"Trip dashboard","Plan, spend and balances","SwiftUI · MapKit","mapkit.png"),
        ("person",VIO,"Personal view","Your share, what you owe","SwiftUI","Swifti.png"),
        ("doc",GRN,"Statements","A PDF for each traveller","PDFKit · Swift","swift.png")]
for i,(g,tint,t,d,cl,mk) in enumerate(outs):
    x = 24 + i*224
    R(x,788,204,96,16,"#FFFFFF",STK,1.3,ex=' filter="url(#sh)"')
    tile(x+14,802,28,tint,g)
    T(x+52,821,t,12.5,INK,"700")
    PARA(x+14,844,d,10.5,176,INK2,13,1)
    chip(x+14,856,cl,mk)

# edges
P("M126,92 L126,100 L160,100 L160,140")
P("M126,100 L519,100 L519,140")
P("M350,92 L350,112 L12,112 L12,578 L20,578")
P("M574,92 L574,112", head=False)
T(392,126,"typed in · invited",9.5,INK3,"600")
P("M160,246 L160,276")
P("M519,246 L519,262 L210,262 L210,276")
P("M181,382 L181,394")
P("M273,438 L358,438"); T(300,431,"Yes",10.5,AMB,"800")
P("M181,480 L181,524"); T(190,508,"No",10.5,GRN,"800")
P("M519,492 L519,510 L260,510 L260,524")
P("M340,578 L358,578")
P("M519,630 L519,662")
P("M350,754 L350,772 L126,772 L126,784")
P("M350,772 L350,784")
P("M350,772 L574,772 L574,784")
A('</svg>')
open("/Users/swastik/Developer/Equitrip/docs/equitrip-userflow.svg","w").write("\n".join(o))
print("ok")
