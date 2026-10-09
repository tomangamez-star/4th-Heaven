# Road artwork

Generated with the built-in image-generation tool; integrated into game PNG chunks.

Source files: `asphalt.png`, `pavement.png`.
Runtime assets: `road_*.png` plus `map.json`.

Asphalt prompt: seamless tileable square HD dark charcoal asphalt surface, subtle
fine aggregate, softly painted 2D game-art finish, neutral flat light, no perspective,
markings, curbs, objects or text; visually quiet for a doodle desert-city game.

Pavement prompt: seamless tileable square HD top-down warm light beige concrete
slabs, fine recessed seams, chalky grain and gentle edge wear, polished hand-painted
game material, neutral flat illumination, no perspective, objects, curbs or text.

The source PNGs are sampled at fixed world scale. The offline build unions all
road footprints before painting outside curbs, then rasterizes the complete map
into 1024px PNG chunks. Geometry in map.json is used only for road-surface driving
queries. There are no road polygon draw calls in the active runtime renderer.

Rebuild: Python with Shapely and Inkscape CLI, `python tools/bake_roads.py`.
