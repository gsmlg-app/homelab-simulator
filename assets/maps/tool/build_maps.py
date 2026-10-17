#!/usr/bin/env python3
"""Build original editable SVG art, PNG atlas, catalog and reference room views."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import shutil
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
W, H = 1024, 768
FRAMES = {}
PARTS = []

def rect(x,y,w,h,fill,stroke=None,r=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="2"' if stroke else '')+'/>'
def line(x,y,a,b,color,width=2):
    return f'<path d="M{x} {y} L{a} {b}" fill="none" stroke="{color}" stroke-width="{width}"/>'
def text(x,y,value,color='#a9c1c7',size=8):
    return f'<text x="{x}" y="{y}" fill="{color}" font-family="DejaVu Sans" font-size="{size}" letter-spacing="1">{value}</text>'
def tile(name,x,y,body):
    FRAMES[name]=[x,y,64,64]
    PARTS.append(f'<g id="{name}" transform="translate({x} {y})">{body}</g>')
def prop(name,x,y,w,h,body):
    FRAMES[name]=[x,y,w,h]
    PARTS.append(f'<g id="{name}" transform="translate({x} {y})">{body}</g>')

def create_source(regenerate=False):
    for i,name in enumerate(['floor.metal','floor.alt','floor.grate','floor.service','floor.path']):
        b=rect(0,0,64,64,['#35434d','#384750','#283941','#354149','#3b484d'][i])
        b+=line(1,63,63,63,'#202e37')+line(0,1,64,1,'#485b64')
        b+=line(63,0,63,64,'#2c3942')
        for a,c in [(5,5),(58,5),(5,58),(58,58)]:
            b+=rect(a,c,2,2,'#627078')
        b+=line(12,18,49,18,'#3e4d57',1)+line(16,43,54,43,'#303f49',1)
        if i==2:
            b+=rect(6,6,52,52,'#1d2c34','#4e6068',3)
            for z in range(12,54,6): b+=line(11,z,53,z,'#617078',2)+line(11,z+2,53,z+2,'#101f27',2)
        if i==3:
            b+=rect(6,5,52,54,'#3a474e','#667078',3)+rect(12,11,40,42,'#34424a')
            b+=text(17,35,'SVC','#879595',9)
        if i==4:
            b+=rect(0,28,64,7,'#a48a57')+line(0,29,64,29,'#c3b179',1)
        tile(name,i*64,0,b)
    for i,name in enumerate(['wall.north','wall.south','wall.west','wall.east','wall.corner','door.east','door.west']):
        b=rect(0,0,64,64,'#1b2a34')
        if name=='wall.north' or name=='wall.corner':
            b+=rect(0,0,64,12,'#819198')+rect(0,12,64,46,'#4d606b')+rect(4,18,56,34,'#394c58','#657983',3)
            b+=line(4,18,60,18,'#91a0a3')+rect(0,58,64,6,'#13232d')+rect(10,54,44,3,'#5cb1b8')
            b+=rect(8,23,5,22,'#2a3c49')+rect(51,23,5,22,'#2a3c49')
        elif name=='wall.south':
            b+=rect(0,0,64,10,'#91a0a5')+rect(0,10,64,18,'#536671')+rect(0,28,64,36,'#1d2e39')+line(0,29,64,29,'#0e202a',3)
            b+=rect(6,15,52,4,'#657c85')
        elif name.startswith('door.'):
            b=rect(0,0,64,64,'#31434c')+rect(0,0,64,8,'#8b9b9f')+rect(0,56,64,8,'#1a2d36')
            b+=rect(7,8,50,48,'#283c47','#6e8790',2)+line(32,10,32,54,'#10222d',3)
            b+=rect(10,12,3,39,'#63c8ca')+rect(51,12,3,39,'#63c8ca')
            b+=text(19,39,'›' if name=='door.east' else '‹','#d9c18a',28)
        else:
            xx=0 if name=='wall.west' else 44
            b+=rect(xx,0,20,64,'#5e737f')+rect(xx+4,4,12,56,'#405562')+line(xx+3,0,xx+3,64,'#9ba9aa')
            b+=rect(22 if xx==0 else 0,0,42,64,'#263944')
            b+=line(25 if xx==0 else 39,0,25 if xx==0 else 39,64,'#122630',3)
        tile(name,i*64,64,b)
    # Tall racks: deep plinth, bevelled enclosure, separate trays and cable channels.
    for idx,name in enumerate(['rack.compute','rack.storage']):
        b='<ellipse cx="67" cy="184" rx="60" ry="7" fill="#0a171f" opacity=".55"/>'
        b+=rect(6,12,116,172,'#14232d','#0e1c24',5)+rect(8,6,108,12,'#72828a','#9ba7a7',3)
        b+=rect(10,18,106,158,'#455965','#819099',3)+rect(18,24,90,144,'#172b36','#263e4b',2)
        b+=rect(12,24,5,144,'#809097')+rect(109,24,4,144,'#1b303d')
        for row in range(7):
            yy=29+row*19
            b+=rect(23,yy,80,15,'#435460' if row%2==0 else '#3a4e5a','#647982',2)
            b+=rect(27,yy+4,48,6,'#142b37',None,1)
            if idx==0:
                for k in range(6): b+=rect(30+k*7,yy+5,3,4,'#617883')
            else:
                for k in range(4): b+=rect(29+k*12,yy+3,9,9,'#273e4b','#71848b',1)
            b+=rect(82,yy+5,5,3,'#6dc7c2')+rect(93,yy+5,4,3,'#d1aa60' if row==2 else '#86a6a8')
        b+=rect(22,172,82,6,'#223c49')+text(27,14,'NODE /' if idx==0 else 'STORE /','#e0d5b9',6)
        prop(name,idx*144,160,128,192,b)
    # Cooling tower.
    b='<ellipse cx="34" cy="153" rx="28" ry="6" fill="#10212a" opacity=".5"/>'
    b+=rect(7,10,50,142,'#283e4b','#90a0a4',5)+rect(11,4,42,12,'#85969c','#aab5b5',3)
    b+=rect(12,19,40,115,'#526975','#778d96',3)
    for cy in [48,99]:
        b+=f'<circle cx="32" cy="{cy}" r="18" fill="#233b48" stroke="#8ba0a6" stroke-width="2"/>'
        for angle in [0,90,180,270]: b+=f'<path d="M32 {cy} C17 {cy-15} 49 {cy-21} 40 {cy-5} Z" fill="#64828c" transform="rotate({angle} 32 {cy})"/>'
        b+=f'<circle cx="32" cy="{cy}" r="4" fill="#a0b2b4"/>'
    b+=rect(16,139,29,4,'#70c5c9')
    prop('cooling',304,160,64,160,b)
    # UPS two-cell cabinet.
    b='<ellipse cx="64" cy="89" rx="58" ry="6" fill="#10212a" opacity=".5"/>'
    b+=rect(7,20,114,68,'#394e5b','#7c929a',4)+rect(7,9,108,16,'#829096','#b5bcba',3)
    b+=rect(15,30,97,45,'#273e4b','#5b7480',3)+rect(22,37,30,22,'#91babe','#b3cecc',2)
    b+=text(26,52,'UPS','#223b44',9)+rect(59,39,43,5,'#a58d55')
    for y in [53,59,65]: b+=line(61,y,104,y,'#0f2834',3)
    prop('ups',384,160,128,96,b)
    # Bench and terminal have shared industrial blue-grey / pale warm laminate.
    for name,x,y,w,h,terminal in [('workbench',528,160,192,128,False),('terminal',736,160,128,128,True)]:
        b=f'<ellipse cx="{w/2}" cy="{h-7}" rx="{w/2-4}" ry="6" fill="#10212a" opacity=".45"/>'
        b+=rect(9,48,w-18,h-59,'#2a4250','#728690',4)+rect(5,38,w-14,34,'#a7ada6','#d0d2bd',4)
        b+=rect(10,43,w-25,19,'#899b99')+rect(12,h-24,w-28,11,'#1e3543')
        b+=rect(22,5,w-51,37,'#253c48','#8c9c9e',4)+rect(28,11,w-63,23,'#4e8f98','#76b9ba',2)
        b+=line(33,17,w-43,17,'#a9d6cd',2)+line(33,23,w-65,23,'#84b5b0',2)
        b+=rect(w/2-8,41,9,8,'#334f59')+rect(28,51,w-78,9,'#3d5960',None,2)
        for k in range(int((w-84)/8)): b+=line(32+k*8,53,32+k*8,57,'#9aaead',1)
        b+=rect(w-42,50,17,12,'#566e74',None,3)+rect(w-27,18,6,15,'#c5ad78',None,2)
        if terminal: b+=text(22,h-33,'ACCESS','#9fc2c3',8)
        else: b+=rect(w-55,80,31,24,'#657d86','#99a6a6',3)+text(21,91,'LAB / 01','#99b3b8',9)
        prop(name,x,y,w,h,b)
    # Operations table, upholstered stool, planter.
    b='<ellipse cx="96" cy="149" rx="88" ry="8" fill="#10212a" opacity=".5"/>'
    b+=rect(30,54,129,96,'#2d4653','#6e8991',6)+rect(7,17,174,91,'#a9aaa0','#d7d0b5',8)+rect(14,24,160,74,'#788f91',None,5)
    b+=rect(57,35,80,45,'#2d4854','#aabeb8',4)+rect(64,42,66,30,'#47727b',None,2)
    b+=line(75,49,120,49,'#9cc5bd')+line(75,56,110,56,'#9cc5bd')+rect(25,38,17,27,'#c4c4af',None,2)+rect(143,70,19,12,'#bba77d',None,2)
    prop('ops.table',0,384,192,160,b)
    b='<ellipse cx="31" cy="73" rx="25" ry="5" fill="#10212a" opacity=".5"/>'+rect(14,21,37,49,'#243c49','#738b94',7)+rect(9,6,43,34,'#64838b','#a4b2b1',8)+rect(14,12,33,19,'#4b6d78',None,5)+rect(17,49,28,18,'#839496',None,4)
    prop('ops.chair',208,384,64,80,b)
    b='<ellipse cx="33" cy="89" rx="26" ry="5" fill="#10212a" opacity=".5"/>'+rect(13,53,39,35,'#779096','#b0beb8',7)+rect(18,49,29,11,'#273f42',None,5)
    for xx,yy,rr in [(19,25,16),(39,19,17),(44,42,16),(24,43,19),(30,10,10)]: b+=f'<ellipse cx="{xx}" cy="{yy}" rx="{rr}" ry="{rr*.75}" fill="#4c7b6e" stroke="#81a58c" stroke-width="2"/>'
    b+=line(31,60,31,22,'#a1b593',2)
    prop('planter',288,384,64,96,b)
    # Wall sign is only visual; no telemetry or fabricated status.
    b=rect(3,9,184,61,'#182f3c','#7c969d',5)+rect(9,15,172,48,'#2f4b58',None,3)+rect(15,22,5,32,'#62b6ba')+text(29,39,'HOMELAB','#d2d6c2',17)+text(30,54,'INFRASTRUCTURE / 01','#93b2b5',7)
    prop('wall.sign',384,384,192,80,b)
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><title>Homelab original environment atlas</title>'+''.join(PARTS)+'</svg>'
    if regenerate or not (ROOT/'source/homelab_atlas.svg').exists():
        (ROOT/'source/homelab_atlas.svg').write_text(svg+'\n')

def catalog():
    tiles=[dict(id=k,frame=v,blocksMovement=k.startswith('wall.'),blocksPlacement=k.startswith('wall.') or k.startswith('door.')) for k,v in FRAMES.items() if k.startswith(('floor.','wall.','door.'))]
    sizes={'rack.compute':(2,1,64,96),'rack.storage':(2,1,64,96),'cooling':(1,2,32,80),'ups':(2,1,64,48),'workbench':(3,1,96,64),'terminal':(2,1,64,64),'ops.table':(3,2,96,80),'ops.chair':(1,1,32,40),'planter':(1,1,32,48),'wall.sign':(3,1,96,40)}
    prefabs=[dict(id=k,frame=FRAMES[k],width=v[0],height=v[1],drawWidth=v[2],drawHeight=v[3],blocksMovement=k!='wall.sign',blocksPlacement=True) for k,v in sizes.items()]
    maps=[]
    def room(mid,name,w,h,door,spawn,objects,target):
        cells=[]
        for y in range(h):
            row=[]
            for x in range(w):
                if y==0: t='wall.north'
                elif y==h-1: t='wall.south'
                elif x==0: t='wall.west'
                elif x==w-1: t='wall.east'
                else: t='floor.alt' if (x*7+y*13)%9==0 else 'floor.metal'
                if x in [4,13] and 1<y<h-2: t='floor.grate'
                if y==h-3 and 4<x<w-3: t='floor.path'
                row.append(t)
            cells.append(row)
        dx= w-1 if door=='right' else 0
        dy=8 if door=='right' else 7
        cells[dy][dx]='door.east' if door=='right' else 'door.west'
        # The low southern sill is foreground; it never covers a character's head.
        fg=[[None]*w for _ in range(h)]
        fg[-1]=cells[-1]
        cells[-1]=['floor.metal']*w
        maps.append(dict(id=mid,name=name,width=w,height=h,spawns={'entry':spawn,'center':[w//2,h-3]},terminalPosition=[2,2],layers=[dict(id='architecture',foreground=False,cells=cells),dict(id='front-sill',foreground=True,cells=fg)],objects=objects,portals=[dict(id='to-'+target,targetMapId=target,wallSide=door,wallPosition=dy,targetSpawnId='entry')]))
    def obj(oid,p,x,y,**kw):return dict(id=oid,prefabId=p,position=[x,y],**kw)
    room('server-lab','Server Lab',20,12,'right',[18,8],[obj('lab-terminal','terminal',2,2,interaction='shop'),obj('compute-a','rack.compute',5,3,bindingSlot='compute-a'),obj('compute-b','rack.compute',8,3,bindingSlot='compute-b'),obj('storage-a','rack.storage',11,3,bindingSlot='storage-a'),obj('compute-c','rack.compute',5,6,bindingSlot='compute-c'),obj('storage-b','rack.storage',8,6,bindingSlot='storage-b'),obj('storage-c','rack.storage',11,6,bindingSlot='storage-c'),obj('cooling-a','cooling',2,5),obj('lab-ups','ups',2,9),obj('lab-workbench','workbench',15,3),obj('lab-planter','planter',16,9),obj('lab-sign','wall.sign',15,1)],'operations')
    room('operations','Operations',16,10,'left',[1,7],[obj('ops-terminal','terminal',2,2,interaction='shop'),obj('ops-console','workbench',6,2,bindingSlot='operations-console'),obj('ops-console-2','workbench',10,2),obj('ops-table','ops.table',6,5),obj('ops-chair-a','ops.chair',5,6),obj('ops-chair-b','ops.chair',10,6),obj('ops-planter','planter',13,7),obj('ops-ups','ups',2,5),obj('ops-sign','wall.sign',10,1)],'server-lab')
    data=dict(schemaVersion=1,atlasAsset='assets/maps/homelab_atlas.png',initialMapId='server-lab',tiles=tiles,prefabs=prefabs,maps=maps)
    (ROOT/'catalog.json').write_text(json.dumps(data,indent=2)+'\n')
    return data

def raster(source,destination):
    subprocess.run(['magick','-background','none',str(source),'-define','png:exclude-chunks=date,time','PNG32:'+str(destination)],check=True)

def previews(data):
    source=ET.parse(ROOT/'source/homelab_atlas.svg').getroot()
    ns='{http://www.w3.org/2000/svg}'
    groups={g.attrib['id']:ET.tostring(g,encoding='unicode') for g in source if g.tag==ns+'g'}
    def art(aid,x,y,sx,sy):
        frame=FRAMES[aid]
        return f'<g transform="translate({x} {y}) scale({sx} {sy}) translate({-frame[0]} {-frame[1]})">{groups[aid]}</g>'
    for m in data['maps']:
        body=rect(0,0,m['width']*64,m['height']*64,'#172732')
        for layer in m['layers']:
            if layer['foreground']: continue
            for y,row in enumerate(layer['cells']):
                for x,t in enumerate(row):
                    if t:body+=art(t,x*64,y*64,1,1)
        for o in sorted(m['objects'],key=lambda o:o['position'][1]+next(p['height'] for p in data['prefabs'] if p['id']==o['prefabId'])):
            p=next(p for p in data['prefabs'] if p['id']==o['prefabId']); f=p['frame']; x,y=o['position']
            dw,dh=p['drawWidth']*2,p['drawHeight']*2
            body+=art(p['id'],x*64+p['width']*32-dw/2,(y+p['height'])*64-dh,dw/f[2],dh/f[3])
        for y,row in enumerate(m['layers'][-1]['cells']):
            for x,t in enumerate(row):
                if t:body+=art(t,x*64,y*64,1,1)
        path=ROOT/'source'/f"preview_{m['id']}.svg"
        path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{m["width"]*64}" height="{m["height"]*64}" viewBox="0 0 {m["width"]*64} {m["height"]*64}">{body}</svg>\n')
        raster(path,ROOT/f"preview_{m['id']}.png")

def build(regenerate=False):
    create_source(regenerate)
    data=catalog()
    raster(ROOT/'source/homelab_atlas.svg',ROOT/'homelab_atlas.png')
    previews(data)


def validate(data):
    dimensions=subprocess.check_output(['magick','identify','-format','%w %h',str(ROOT/'homelab_atlas.png')],text=True).split()
    assert list(map(int,dimensions)) == [W,H], 'Unexpected atlas dimensions'
    for definition in data['tiles']+data['prefabs']:
        x,y,w,h=definition['frame']
        assert 0<=x and 0<=y and w>0 and h>0 and x+w<=W and y+h<=H, definition['id']
    for m in data['maps']:
        assert all(len(layer['cells'])==m['height'] and all(len(row)==m['width'] for row in layer['cells']) for layer in m['layers']), m['id']


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true',help='Validate assets and compare a clean temporary rebuild without changing files')
    parser.add_argument('--regenerate-source',action='store_true',help='Replace the editable SVG with its original programmatic construction')
    args=parser.parse_args()
    if args.check:
        original=ROOT
        validate(json.loads((ROOT/'catalog.json').read_text()))
        with tempfile.TemporaryDirectory(prefix='homelab-map-art-') as temporary:
            ROOT=Path(temporary)
            (ROOT/'source').mkdir()
            shutil.copyfile(original/'source/homelab_atlas.svg',ROOT/'source/homelab_atlas.svg')
            build()
            for name in ['catalog.json','homelab_atlas.png','preview_server-lab.png','preview_operations.png']:
                if name.endswith('.png'):
                    # PNG metadata/encoder versions may vary; compare decoded pixels.
                    result=subprocess.run(['magick','compare','-metric','AE',str(original/name),str(ROOT/name),'null:'],capture_output=True,text=True)
                    assert result.returncode==0 and result.stderr.split()[0]=='0', f'{name}: pixel difference {result.stderr}'
                else:
                    assert (original/name).read_bytes()==(ROOT/name).read_bytes(), f'{name}: differs from rebuild'
        print('Validated 22 atlas frames, two rectangular maps, and exact decoded-pixel reproduction of all three PNGs.')
    else:
        build(args.regenerate_source)
        validate(json.loads((ROOT/'catalog.json').read_text()))
        print('Built editable SVG, atlas, two catalog maps and composed previews.')
