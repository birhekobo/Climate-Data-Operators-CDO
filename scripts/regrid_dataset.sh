#!/bin/bash
# regrid_dataset.sh
# Spatial regridding pipeline demonstrating different interpolation methods.
set -euo pipefail

INPUT_DIR="../datasets"
OUTPUT_DIR="../output"
SAMPLE_FILE="$INPUT_DIR/tas_sample.nc"

mkdir -p "$OUTPUT_DIR"

echo "============================================"
echo "  Spatial Regridding Pipeline"
echo "============================================"
echo "Input: $SAMPLE_FILE"
echo ""

# --------------------------------------------------
# 1. Read input dataset information
# --------------------------------------------------
echo "[1/7] Input dataset grid info"
cdo griddes "$SAMPLE_FILE" > "$OUTPUT_DIR/input_griddes.txt"
echo "  Grid description saved -> input_griddes.txt"
echo ""

# --------------------------------------------------
# 2. Generate target grid description (2° x 2°)
# --------------------------------------------------
echo "[2/7] Generating target grid (2°x2° regular grid)"
cat > "$OUTPUT_DIR/target_grid.txt" << 'EOF'
gridtype = lonlat
xsize = 180
ysize = 90
xfirst = -179.0
xinc = 2.0
yfirst = -89.0
yinc = 2.0
EOF
echo "  Target grid: 180 x 90 cells (2° resolution)"
echo ""

# --------------------------------------------------
# 3. Bilinear interpolation
# --------------------------------------------------
echo "[3/7] Bilinear remapping"
cdo remapbil,"$OUTPUT_DIR/target_grid.txt" "$SAMPLE_FILE" "$OUTPUT_DIR/tas_bilinear.nc"
echo "  -> tas_bilinear.nc"
echo ""

# --------------------------------------------------
# 4. Conservative remapping
# --------------------------------------------------
echo "[4/7] Conservative remapping (first-order)"
cdo remapcon,"$OUTPUT_DIR/target_grid.txt" "$SAMPLE_FILE" "$OUTPUT_DIR/tas_conservative.nc"
echo "  -> tas_conservative.nc"
echo ""

# --------------------------------------------------
# 5. Nearest-neighbor remapping
# --------------------------------------------------
echo "[5/7] Nearest-neighbor remapping"
cdo remapnn,"$OUTPUT_DIR/target_grid.txt" "$SAMPLE_FILE" "$OUTPUT_DIR/tas_nearest.nc"
echo "  -> tas_nearest.nc"
echo ""

# --------------------------------------------------
# 6. Compare output grid sizes
# --------------------------------------------------
echo "[6/7] Comparing output grid sizes"
echo "Original:"
cdo nusers "$SAMPLE_FILE"
echo ""
echo "Bilinear:"
cdo nusers "$OUTPUT_DIR/tas_bilinear.nc"
echo ""
echo "Conservative:"
cdo nusers "$OUTPUT_DIR/tas_conservative.nc"
echo ""
echo "Nearest-neighbor:"
cdo nusers "$OUTPUT_DIR/tas_nearest.nc"
echo ""

# --------------------------------------------------
# 7. Compute area-weighted global means for comparison
# --------------------------------------------------
echo "[7/7] Area-weighted global means (fldmean)"
echo "Original:  $(cdo fldmean "$SAMPLE_FILE" | cdo outputts - 2>/dev/null | head -3)"
echo "Bilinear:  $(cdo fldmean "$OUTPUT_DIR/tas_bilinear.nc" | cdo outputts - 2>/dev/null | head -3)"
echo "Conservative: $(cdo fldmean "$OUTPUT_DIR/tas_conservative.nc" | cdo outputts - 2>/dev/null | head -3)"
echo "Nearest:   $(cdo fldmean "$OUTPUT_DIR/tas_nearest.nc" | cdo outputts - 2>/dev/null | head -3)"
echo ""

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo "============================================"
echo "  Regridding complete!"
echo "============================================"
echo "Outputs:"
ls -lh "$OUTPUT_DIR"/tas_bilinear.nc "$OUTPUT_DIR"/tas_conservative.nc "$OUTPUT_DIR"/tas_nearest.nc
echo ""
echo "Interpolation methods compared:"
echo "  remapbil - Bilinear (smooth, weights by distance)"
echo "  remapcon - Conservative (conserves flux, weights by area overlap)"
echo "  remapnn  - Nearest neighbor (fast, preserves original values)"
