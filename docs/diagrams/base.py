# -*- coding: utf-8 -*-
import html
INK, INK2, INK3 = "#1A1109", "#6B5B50", "#9C8B7F"
ACC = "#4B45C6"
GRN, AMB, RED = "#1E7A55", "#D97706", "#C5442E"
STK = "#EADCD0"
BG  = "#FFFBF7"
SANS = "'SF Pro Display','SF Pro Text','Helvetica Neue',Helvetica,Arial,sans-serif"

class Doc:
    def __init__(s, w, h):
        s.w, s.h, s.o = w, h, []
        s.o.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">')
        s.o.append('<defs>'
          f'<marker id="ah" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="5.5" markerHeight="5.5" orient="auto-start-reverse"><path d="M0,1 L9,5 L0,9 z" fill="{INK}"/></marker>'
          f'<marker id="ahA" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="5.5" markerHeight="5.5" orient="auto-start-reverse"><path d="M0,1 L9,5 L0,9 z" fill="{ACC}"/></marker>'
          '<filter id="sh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="3" stdDeviation="6" flood-color="#59331A" flood-opacity="0.10"/></filter>'
          '</defs>')
        s.o.append(f'<rect width="{w}" height="{h}" fill="{BG}"/>')
    def A(s, x): s.o.append(x)
    def T(s,x,y,t,size=15,fill=INK2,wt="400",anc="start",ls=0,op=1.0):
        s.A(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{SANS}" font-size="{size}" font-weight="{wt}" '
            f'fill="{fill}" text-anchor="{anc}" letter-spacing="{ls}" opacity="{op}">{html.escape(t,quote=False)}</text>')
    def R(s,x,y,w,h,r,fill,stroke=None,sw=1.5,dash=None,op=1.0,ex=""):
        d=f' stroke-dasharray="{dash}"' if dash else ""
        st=f' stroke="{stroke}" stroke-width="{sw}"{d}' if stroke else ""
        s.A(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill}"{st} opacity="{op}"{ex}/>')
    def PT(s,d,stroke=INK,sw=2.2,dash=None,head="ah",op=1.0):
        dd=f' stroke-dasharray="{dash}"' if dash else ""
        mk=f' marker-end="url(#{head})"' if head else ""
        s.A(f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"{dd}{mk} opacity="{op}"/>')
    def save(s, path):
        s.o.append('</svg>')
        open(path,"w").write("\n".join(s.o))
