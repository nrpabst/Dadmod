from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
W=1000; c=W/2; r=470
RED=(222,38,32,255); BLK=(14,14,14,255); OFF=(236,238,234,255)
FS='C:/Windows/Fonts/georgiab.ttf'
def P(a,rr): return (c+math.cos(a)*rr,c+math.sin(a)*rr)
def face():
    im=Image.new('RGBA',(W,W),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.ellipse((c-r-10,c-r-10,c+r+10,c+r+10),fill=(25,25,25,255))
    d.ellipse((c-r,c-r,c+r,c+r),fill=OFF)
    n=26
    for k in range(n):
        a0=k*2*math.pi/n; st=2*math.pi/n
        out=[P(a0,250),P(a0+st*0.55,250),P(a0+st*1.2,330),P(a0+st*0.95,345),P(a0+st*1.7,440),P(a0+st*0.9,400),P(a0+st*1.05,385),P(a0+st*0.3,300)]
        d.polygon(out,fill=BLK)
        inn=[P(a0+st*0.12,262),P(a0+st*0.5,262),P(a0+st*1.05,330),P(a0+st*0.85,342),P(a0+st*1.45,420),P(a0+st*0.85,388),P(a0+st*0.95,377),P(a0+st*0.35,300)]
        d.polygon(inn,fill=RED)
    hx,hy,hr=c+235,c+20,190
    d.ellipse((hx-hr-14,hy-hr-14,hx+hr+14,hy+hr+14),fill=BLK)
    d.ellipse((hx-hr,hy-hr,hx+hr,hy+hr),fill=RED)
    d.pieslice((hx-hr*0.95,hy-hr*1.15,hx+hr*0.9,hy-hr*0.1),190,350,fill=BLK)
    d.pieslice((hx-hr*0.85,hy-hr*1.05,hx+hr*0.8,hy-hr*0.2),195,345,fill=(170,20,18,255))
    for sx in (-1,1):
        gx=hx+sx*hr*0.38
        d.rounded_rectangle((gx-hr*0.3,hy-hr*0.32,gx+hr*0.3,hy+hr*0.02),hr*0.12,fill=BLK)
        d.line((gx-hr*0.18,hy-hr*0.24,gx-hr*0.02,hy-hr*0.24),fill=(255,255,255,255),width=10)
    d.line((hx-hr*0.1,hy-hr*0.2,hx+hr*0.1,hy-hr*0.2),fill=BLK,width=16)
    m=[(hx-hr*0.62,hy+hr*0.22),(hx-hr*0.3,hy+hr*0.08),(hx,hy+hr*0.16),(hx+hr*0.3,hy+hr*0.08),(hx+hr*0.62,hy+hr*0.22),(hx+hr*0.35,hy+hr*0.3),(hx,hy+hr*0.26),(hx-hr*0.35,hy+hr*0.3)]
    d.polygon(m,fill=BLK)
    d.chord((hx-hr*0.5,hy+hr*0.05,hx+hr*0.5,hy+hr*0.75),20,160,fill=BLK)
    d.chord((hx-hr*0.4,hy+hr*0.12,hx+hr*0.4,hy+hr*0.62),25,155,fill=(255,255,255,255))
    for k in range(1,6): x=hx-hr*0.4+k*hr*0.8/6; d.line((x,hy+hr*0.38,x,hy+hr*0.62),fill=BLK,width=6)
    d.ellipse((c-250,c-250,c+250,c+250),fill=OFF)
    d.ellipse((c-250,c-250,c+250,c+250),outline=BLK,width=6)
    f=ImageFont.truetype(FS,40)
    txt='DADMOD \u2022 THUG PRO \u2022 54MM \u2022 99A \u2022 '
    ang=-90; step=360/len(txt)
    for ch in txt:
        g=Image.new('RGBA',(60,60),(0,0,0,0)); ImageDraw.Draw(g).text((30,30),ch,font=f,fill=BLK,anchor='mm')
        g=g.rotate(-(ang+90),resample=Image.BICUBIC)
        x,y=P(math.radians(ang),205); im.alpha_composite(g,(int(x-30),int(y-30))); ang+=step
    d=ImageDraw.Draw(im)
    d.ellipse((c-165,c-165,c+165,c+165),fill=(22,22,24,255))
    d.ellipse((c-150,c-150,c+150,c+150),outline=(60,60,64,255),width=8)
    d.ellipse((c-110,c-110,c+110,c+110),fill=(10,10,10,255))
    d.polygon([P(math.radians(30+60*k),78) for k in range(6)],fill=(250,250,250,255))
    return im
def badge(im):
    d=ImageDraw.Draw(im); bx,by=c-330,c-40
    sh=[(bx-80,by-80),(bx+80,by-80),(bx+80,by+20),(bx,by+100),(bx-80,by+20)]
    d.polygon(sh,fill=BLK)
    sh2=[(bx-68,by-68),(bx+68,by-68),(bx+68,by+14),(bx,by+86),(bx-68,by+14)]
    d.polygon(sh2,fill=OFF)
    d.rectangle((bx-74,by-30,bx+74,by+24),fill=RED,outline=BLK,width=5)
    f=ImageFont.truetype(FS,46); d.text((bx,by-3),'99A',font=f,fill=(255,255,255,255),anchor='mm',stroke_width=2,stroke_fill=BLK)
    f2=ImageFont.truetype(FS,22); d.text((bx,by-50),'DADMOD',font=f2,fill=BLK,anchor='mm')
    return im
def gloss(im):
    g=Image.new('RGBA',(W,W),(0,0,0,0)); d=ImageDraw.Draw(g)
    d.arc((c-r+15,c-r+15,c+r-15,c+r-15),195,285,fill=(255,255,255,150),width=22)
    return Image.alpha_composite(im,g.filter(ImageFilter.GaussianBlur(6)))
BLUE=(20,150,235,255)
def tri(size):
    S=8; w=size*S; im=Image.new('RGBA',(w,w),(0,0,0,0)); d=ImageDraw.Draw(im)
    d.polygon([(0,0),(w*0.62,w*0.10),(w*0.10,w*0.62)],fill=(10,10,10,255))
    d.polygon([(w*0.06,w*0.06),(w*0.53,w*0.135),(w*0.135,w*0.53)],fill=BLUE)
    d.line([(w*0.08,w*0.08),(w*0.45,w*0.14)],fill=(150,215,255,255),width=S)
    return im.resize((size,size),Image.LANCZOS)
def cursor(rot,size):
    wl=base.rotate(-rot,resample=Image.BICUBIC).resize((int(size*0.86),int(size*0.86)),Image.LANCZOS)
    cc=Image.new('RGBA',(size,size),(0,0,0,0))
    sh=Image.new('RGBA',wl.size,(0,0,0,0)); sh.paste((0,0,0,110),(0,0),wl); sh=sh.filter(ImageFilter.GaussianBlur(max(1,size/40)))
    o=int(size*0.12)
    cc.alpha_composite(sh,(o+max(1,size//30),o+max(1,size//30))); cc.alpha_composite(wl,(o,o))
    t=tri(int(size*0.5)); ts=Image.new('RGBA',t.size,(0,0,0,0)); ts.paste((0,0,0,130),(0,0),t); ts=ts.filter(ImageFilter.GaussianBlur(max(1,size/50)))
    cc.alpha_composite(ts,(max(1,size//40),max(1,size//40))); cc.alpha_composite(t,(0,0))
    return cc
base=gloss(badge(face()))
import sys,os
out=sys.argv[1]; os.makedirs(out,exist_ok=True)
for size in (32,40,48,64):
    for i in range(24):
        cursor(360*i/24,size).save(os.path.join(out,'cur_%d_%02d.png'%(size,i)))
