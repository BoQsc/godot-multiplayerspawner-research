import os
from PIL import Image
from collections import Counter
import math

# Configure these paths
TILES_DIR = r"C:\Users\Windows10_new\Documents\godot-multiplayerspawner-research\assets\kenney_platformer-art-deluxe\Base pack\Tiles"
OUTPUT_DIR = os.path.join(os.path.dirname(TILES_DIR), "new")
os.makedirs(OUTPUT_DIR, exist_ok=True)

ATLAS_FILENAME = "tiles_spritesheet.png"
TRES_FILENAME = "tileset_generated.tres"

# Set a standard tile size
STANDARD_SIZE = 70  # Most common size in the tileset

# Load all PNG files from the original TILES_DIR only
tiles = []
for fname in os.listdir(TILES_DIR):
    if (fname.lower().endswith(".png") and 
        not fname.endswith(".import") and 
        not fname == ATLAS_FILENAME):  # Exclude the atlas file itself
        full_path = os.path.join(TILES_DIR, fname)
        try:
            img = Image.open(full_path).convert("RGBA")
            tiles.append((fname, img))
            print(f"Loaded: {fname} ({img.width}x{img.height})")
        except Exception as e:
            print(f"Failed to load {fname}: {e}")

print(f"Total tiles loaded: {len(tiles)}")

# Process tiles - split larger tiles into multiple standard-sized tiles
processed_tiles = []
for fname, img in tiles:
    # Calculate how many tiles we need to split this image into
    cols = math.ceil(img.width / STANDARD_SIZE)
    rows = math.ceil(img.height / STANDARD_SIZE)
    
    if cols == 1 and rows == 1:
        # Tile fits within standard size, just center it
        if img.width < STANDARD_SIZE or img.height < STANDARD_SIZE:
            new_img = Image.new("RGBA", (STANDARD_SIZE, STANDARD_SIZE), (0, 0, 0, 0))
            x_offset = (STANDARD_SIZE - img.width) // 2
            y_offset = (STANDARD_SIZE - img.height) // 2
            new_img.paste(img, (x_offset, y_offset))
            processed_tiles.append((fname, new_img))
            print(f"Centered: {fname} in {STANDARD_SIZE}x{STANDARD_SIZE}")
        else:
            processed_tiles.append((fname, img))
            print(f"Kept original: {fname} ({img.width}x{img.height})")
    else:
        # Split the tile into multiple standard-sized tiles
        print(f"Splitting: {fname} into {cols}x{rows} tiles")
        for row in range(rows):
            for col in range(cols):
                # Calculate the region to extract
                left = col * STANDARD_SIZE
                upper = row * STANDARD_SIZE
                right = min((col + 1) * STANDARD_SIZE, img.width)
                lower = min((row + 1) * STANDARD_SIZE, img.height)
                
                # Extract the region
                region = img.crop((left, upper, right, lower))
                
                # If the region is smaller than standard size, center it
                if region.width < STANDARD_SIZE or region.height < STANDARD_SIZE:
                    new_img = Image.new("RGBA", (STANDARD_SIZE, STANDARD_SIZE), (0, 0, 0, 0))
                    x_offset = (STANDARD_SIZE - region.width) // 2
                    y_offset = (STANDARD_SIZE - region.height) // 2
                    new_img.paste(region, (x_offset, y_offset))
                    region = new_img
                
                # Add to processed tiles with a modified name
                part_name = f"{os.path.splitext(fname)[0]}_{row}_{col}.png"
                processed_tiles.append((part_name, region))

print(f"Total tiles after processing: {len(processed_tiles)}")

# Create grid layout
cols = 16
rows = (len(processed_tiles) + cols - 1) // cols
atlas_w = cols * STANDARD_SIZE
atlas_h = rows * STANDARD_SIZE

print(f"Creating atlas: {atlas_w}x{atlas_h} with {cols}x{rows} grid")

# Create the atlas
atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
positions = {}

# Place each tile in the grid
for idx, (fname, img) in enumerate(processed_tiles):
    x = idx % cols
    y = idx // cols
    
    # Paste the tile at the correct position
    atlas.paste(img, (x * STANDARD_SIZE, y * STANDARD_SIZE))
    positions[fname] = (x, y)
    print(f"Placed {fname} at position ({x}, {y})")

# Save the atlas
atlas_path = os.path.join(OUTPUT_DIR, ATLAS_FILENAME)
atlas.save(atlas_path)
print(f"Saved atlas: {atlas_path}")

# Write the TRES file
tres_path = os.path.join(OUTPUT_DIR, TRES_FILENAME)
# Get relative path from project root
rel_atlas_path = f"res://assets/kenney_platformer-art-deluxe/Base pack/new/{ATLAS_FILENAME}"

with open(tres_path, "w", encoding="utf-8") as f:
    f.write('[gd_resource type="TileSet" load_steps=2 format=3]\n\n')
    
    f.write(f'[ext_resource type="Texture2D" path="{rel_atlas_path}" id="1"]\n\n')
    
    f.write('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_1"]\n')
    f.write('texture = ExtResource("1")\n')
    f.write(f'texture_region_size = Vector2i({STANDARD_SIZE}, {STANDARD_SIZE})\n')
    f.write('use_texture_padding = false\n\n')

    for fname, (x, y) in positions.items():
        f.write(f'{x}:{y}/0 = 0\n')
        f.write(f'{x}:{y}/0/physics_layer_0/polygon_0/points = PackedVector2Array(0, 0, {STANDARD_SIZE}, 0, {STANDARD_SIZE}, {STANDARD_SIZE}, 0, {STANDARD_SIZE})\n')

    f.write('\n[resource]\n')
    f.write(f'tile_size = Vector2i({STANDARD_SIZE}, {STANDARD_SIZE})\n')
    f.write('sources/0 = SubResource("TileSetAtlasSource_1")\n')

print(f"Saved TRES: {tres_path}")
print(f"Processed {len(processed_tiles)} tiles successfully")