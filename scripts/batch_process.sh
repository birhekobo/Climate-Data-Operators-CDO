#!/bin/bash
# batch_process.sh
# Batch processing of multiple NetCDF files with progress reporting.
set -euo pipefail

INPUT_DIR="../datasets"
OUTPUT_DIR="../output"
MERGED_DIR="$OUTPUT_DIR/merged"
PROCESSED_DIR="$OUTPUT_DIR/processed"

mkdir -p "$MERGED_DIR" "$PROCESSED_DIR"

echo "============================================"
echo "  Batch Processing Pipeline"
echo "============================================"
echo "Input dir : $INPUT_DIR"
echo "Output dir: $OUTPUT_DIR"
echo ""

# --------------------------------------------------
# Find all NetCDF files matching pattern
# --------------------------------------------------
FILES=($(ls "$INPUT_DIR"/tas_2???.nc 2>/dev/null || true))
TOTAL=${#FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "ERROR: No files matching 'tas_2???.nc' found in $INPUT_DIR."
    echo "Run ./download_sample_data.sh first or place files manually."
    exit 1
fi

echo "Found $TOTAL files to process."
echo ""

# --------------------------------------------------
# Process each file in a for loop
# --------------------------------------------------
COUNT=0
for FILE in "${FILES[@]}"; do
    COUNT=$((COUNT + 1))
    BASENAME=$(basename "$FILE" .nc)
    echo "[$COUNT/$TOTAL] Processing: $BASENAME"

    # Extract year for output naming
    YEAR=$(echo "$BASENAME" | grep -oE '[0-9]{4}' || echo "unknown")

    # 1. Get basic info
    cdo sinfo "$FILE" > "$PROCESSED_DIR/${BASENAME}_sinfo.txt" 2>/dev/null

    # 2. Compute annual mean (though file is already annual, this demonstrates the pattern)
    cdo yearmean "$FILE" "$PROCESSED_DIR/${BASENAME}_yearmean.nc" 2>/dev/null

    # 3. Compute spatial average
    cdo fldmean "$FILE" "$PROCESSED_DIR/${BASENAME}_fldmean.nc" 2>/dev/null

    # 4. Detrend (linear)
    cdo detrend "$FILE" "$PROCESSED_DIR/${BASENAME}_detrend.nc" 2>/dev/null

    echo "  Done: $BASENAME"
done

echo ""
echo "All files processed."
echo ""

# --------------------------------------------------
# Merge all processed results
# --------------------------------------------------
echo "Merging individual results into single files..."

# Merge the original time series
cd "$MERGED_DIR"
cdo mergetime "$INPUT_DIR"/tas_2???.nc merged_tas_timeseries.nc 2>/dev/null && \
    echo "  -> merged_tas_timeseries.nc"

# Merge fldmean outputs
cdo mergetime "$PROCESSED_DIR"/tas_*_fldmean.nc merged_fldmean.nc 2>/dev/null && \
    echo "  -> merged_fldmean.nc"

# Merge detrended outputs
cdo mergetime "$PROCESSED_DIR"/tas_*_detrend.nc merged_detrend.nc 2>/dev/null && \
    echo "  -> merged_detrend.nc"

cd "$OLDPWD"

echo ""

# --------------------------------------------------
# Compute statistics on merged time series
# --------------------------------------------------
echo "Computing statistics on merged time series..."
if [ -f "$MERGED_DIR/merged_tas_timeseries.nc" ]; then
    cdo timmean "$MERGED_DIR/merged_tas_timeseries.nc" "$MERGED_DIR/merged_timmean.nc" 2>/dev/null
    cdo timstd "$MERGED_DIR/merged_tas_timeseries.nc" "$MERGED_DIR/merged_timstd.nc" 2>/dev/null
    cdo trend "$MERGED_DIR/merged_tas_timeseries.nc" "$MERGED_DIR/merged_trend.nc" 2>/dev/null
    echo "  Statistics computed: timmean, timstd, trend"
fi

echo ""

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo "============================================"
echo "  Batch processing complete!"
echo "============================================"
echo "Processed $TOTAL files."
echo ""
echo "Output structure:"
echo "  $PROCESSED_DIR/  (per-file outputs)"
echo "  $MERGED_DIR/     (merged products)"
echo ""
echo "To check merged time series:"
echo "  cdo sinfo $MERGED_DIR/merged_tas_timeseries.nc"
