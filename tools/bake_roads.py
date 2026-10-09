"""Build unified PNG map chunks. Run with shapely and cairosvg installed.

Geometry is authoring data only: the shipped game displays raster PNG chunks.
The union is computed BEFORE curbs or paint, never masked with outlined boxes.
"""
import base64
import json
from pathlib import Path
import subprocess
import tempfile
from shapely.geometry import LineString, box, Point
from shapely.ops import unary_union

ROOT = Path(__file__).resolve().parents[1]
def render(svg, destination):
    with tempfile.NamedTemporaryFile(suffix='.svg',mode='w') as source:
        source.write(svg); source.flush()
        subprocess.run(['inkscape',source.name,'--export-type=png',f'--export-filename={destination}'],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
OUT = ROOT / 'assets/roads'
OUT.mkdir(parents=True, exist_ok=True)
loop = [(-1260,-178),(-840,-178),(-420,-178),(0,-178),(420,-178),(840,-178),(1260,-178),(1500,120),(1500,760),(1180,1040),(600,1040),(0,1040),(-600,1040),(-1180,1040),(-1500,760),(-1500,120)]
oval = LineString(loop + [loop[0]])
east = LineString([(1500,440),(2860,440)])
north = LineString([(2350,-1500),(2350,1500)])
# A lower clear aisle gives all three parking bays usable reversing space.
driveway = LineString([(2050,-570),(2350,-570)])
lot = box(1550,-1035,2110,-390).buffer(24).buffer(-24)
roads = unary_union([oval.buffer(190),east.buffer(190),north.buffer(190),driveway.buffer(110),lot])
walks = unary_union([oval.buffer(365),east.buffer(365),north.buffer(365),driveway.buffer(190),lot.buffer(85)])

def polygons(g):
    return [g] if g.geom_type == 'Polygon' else list(g.geoms)

def path(g):
    result=[]
    for p in polygons(g):
        for ring in [p.exterior,*p.interiors]:
            coords=list(ring.coords)
            result.append('M'+' L'.join(f'{x:.2f},{y:.2f}' for x,y in coords)+' Z')
    return ' '.join(result)

def fill(g, color):
    return f'<path d="{path(g)}" fill="{color}" fill-rule="evenodd"/>'

def pattern(name, size):
    data=base64.b64encode((OUT/f'{name}.png').read_bytes()).decode()
    return f'<pattern id="{name}" width="{size}" height="{size}" patternUnits="userSpaceOnUse"><image width="{size}" height="{size}" xlink:href="data:image/png;base64,{data}"/></pattern>'

parts=[fill(walks.buffer(16),'#66584a'),fill(walks.buffer(5),'#b0a18a'),fill(walks,'url(#pavement)'),fill(roads.buffer(13),'#ada99a'),fill(roads.buffer(5),'#66686a'),fill(roads,'url(#asphalt)')]
# One consistent narrow dashed centre marking, excluded from all junctions.
excluded=unary_union([box(1210,180,1790,700),box(2040,130,2660,750),box(2110,-740,2590,-400)])
for line in [oval,east,north]:
    for distance in range(0,int(line.length),105):
        dash=LineString([line.interpolate(distance),line.interpolate(min(distance+45,line.length))]).difference(excluded)
        if not dash.is_empty:
            parts.append(f'<path d="{path(dash.buffer(2.5,cap_style=2))}" fill="#e5d09b"/>')
# Four crosswalks with a clear unpainted middle; aligned to sidewalks.
for offset in [-245,245]:
    for stripe in range(6):
        parts.append(fill(box(2350+offset-48,440-144+stripe*48,2350+offset+48,440-120+stripe*48),'#eae5d1'))
        parts.append(fill(box(2350-144+stripe*48,440+offset-48,2350-120+stripe*48,440+offset+48),'#eae5d1'))
for x in [1595,1760,1925]:
    for xx in [x,x+140]:
        parts.append(fill(box(xx-2,-970,xx+2,-680),'#e2ddc9'))
    parts.append(fill(box(x+22,-950,x+118,-942),'#a39e90'))
defs='<defs>'+pattern('asphalt',384)+pattern('pavement',512)+'</defs>'
body=''.join(parts)
tiles=[]
for y in range(-2048,2048,1024):
    for x in range(-3072,3072,1024):
        if not walks.buffer(16).intersects(box(x,y,x+1024,y+1024)): continue
        name=f'road_{x}_{y}.png'
        svg=f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="{x} {y} 1024 1024">{defs}{body}</svg>'
        render(svg,OUT/name)
        tiles.append({'file':name,'x':x,'y':y})
manifest={'tiles':tiles,'roads':[{'outer':list(p.exterior.coords),'holes':[list(r.coords) for r in p.interiors]} for p in polygons(roads)]}
(OUT/'map.json').write_text(json.dumps(manifest,separators=(',',':')))
# Reproducible overview for visual review; not used by the game.
svg=f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1536" height="1024" viewBox="-3072 -2048 6144 4096"><rect x="-3072" y="-2048" width="6144" height="4096" fill="#a57843"/>{defs}{body}</svg>'
render(svg,OUT/'overview.png')
# Geometry regression: all connections and the driveway must be asphalt.
for p in [(1500,440),(1750,440),(2350,440),(2180,-570),(2250,-570)]:
    assert roads.contains(Point(p)),p
assert len(polygons(roads))==1, 'Road network is disconnected'
print(f'Baked {len(tiles)} PNG chunks; one connected road surface; topology checks passed')
