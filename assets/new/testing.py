import os
from PIL import Image
from collections import Counter

# Configure these paths
TILES_DIR = r"C:\Users\Windows10_new\Documents\godot-multiplayerspawner-research\assets\kenney_platformer-art-deluxe\Base pack\Tiles"
OUTPUT_DIR = os.path.join(os.path.dirname(TILES_DIR), "new")
os.makedirs(OUTPUT_DIR, exist_ok=True)

ATLAS_FILENAME = "tiles_spritesheet.png"
TRES_FILENAME = "tileset_generated.tres"

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

# Find the most common tile size to use as our minimum size
size_counter = Counter(im.size for _, im in tiles)
most_common_size = size_counter.most_common(1)[0][0]
min_w, min_h = most_common_size

print(f"Minimum tile size: {min_w}x{min_h}")

# Process tiles - resize smaller ones to minimum size, keep larger ones as-is
processed_tiles = []
for fname, img in tiles:
    if img.width < min_w or img.height < min_h:
        # Resize smaller tiles to minimum size
        new_img = Image.new("RGBA", (min_w, min_h), (0, 0, 0, 0))
        
        # Calculate position to center the original image
        x_offset = (min_w - img.width) // 2
        y_offset = (min_h - img.height) // 2
        
        # Paste the original image onto the new image
        new_img.paste(img, (x_offset, y_offset))
        processed_tiles.append((fname, new_img))
        print(f"Resized: {fname} from {img.width}x{img.height} to {min_w}x{min_h}")
    else:
        # Keep larger tiles as they are
        processed_tiles.append((fname, img))
        print(f"Kept original: {fname} ({img.width}x{img.height})")

# Find the maximum dimensions after processing
max_w = max(im.width for _, im in processed_tiles)
max_h = max(im.height for _, im in processed_tiles)

print(f"Maximum tile size after processing: {max_w}x{max_h}")

# Create grid layout using the maximum dimensions
cols = 16
rows = (len(processed_tiles) + cols - 1) // cols
atlas_w = cols * max_w
atlas_h = rows * max_h

print(f"Creating atlas: {atlas_w}x{atlas_h} with {cols}x{rows} grid")

# Create the atlas
atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
positions = {}

# Place each tile in the grid, centering them in their cells
for idx, (fname, img) in enumerate(processed_tiles):
    x = idx % cols
    y = idx // cols
    
    # Calculate offset to center the tile in its cell
    x_offset = (max_w - img.width) // 2
    y_offset = (max_h - img.height) // 2
    
    # Paste the tile at the correct position
    atlas.paste(img, (x * max_w + x_offset, y * max_h + y_offset))
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
    f.write(f'texture_region_size = Vector2i({max_w}, {max_h})\n')
    f.write('use_texture_padding = false\n\n')

    for fname, (x, y) in positions.items():
        f.write(f'{x}:{y}/0 = 0\n')
        f.write(f'{x}:{y}/0/physics_layer_0/polygon_0/points = PackedVector2Array(0, 0, {max_w}, 0, {max_w}, {max_h}, 0, {max_h})\n')

    f.write('\n[resource]\n')
    f.write(f'tile_size = Vector2i({max_w}, {max_h})\n')
    f.write('sources/0 = SubResource("TileSetAtlasSource_1")\n')

print(f"Saved TRES: {tres_path}")
print(f"Processed {len(processed_tiles)} tiles successfully")