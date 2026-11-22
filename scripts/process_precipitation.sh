#!/bin/bash
# process_precipitation.sh
# Precipitation data processing pipeline for CDO training.
set -euo pipefail

INPUT_DIR="../datasets"
OUTPUT_DIR="../output"
SAMPLE_FILE="$INPUT_DIR/pr_sample.nc"

mkdir -p "$OUTPUT_DIR"

echo "=============================================="
echo "  Precipitation Data Processing Pipeline"
echo "=============================================="
echo "Input : $SAMPLE_FILE"
echo "Output: $OUTPUT_DIR"
echo ""

# --------------------------------------------------
# 1. Dataset information
# --------------------------------------------------
echo "[1/9] Dataset information (sinfo)"
cdo sinfo "$SAMPLE_FILE" | tee "$OUTPUT_DIR/pr_sinfo.txt"
echo ""

# --------------------------------------------------
# 2. Select time period
# --------------------------------------------------
echo "[2/9] Selecting years 2000–2010"
cdo selyear,2000/2010 "$SAMPLE_FILE" "$OUTPUT_DIR/pr_2000_2010.nc"
echo "  -> pr_2000_2010.nc"
echo ""

# --------------------------------------------------
# 3. Monthly precipitation totals
# --------------------------------------------------
echo "[3/9] Computing monthly precipitation totals"
cdo monsum "$OUTPUT_DIR/pr_2000_2010.nc" "$OUTPUT_DIR/pr_monsum.nc"
echo "  -> pr_monsum.nc"
echo ""

# --------------------------------------------------
# 4. Seasonal precipitation totals
# --------------------------------------------------
echo "[4/9] Computing seasonal precipitation totals"
cdo seassum "$OUTPUT_DIR/pr_2000_2010.nc" "$OUTPUT_DIR/pr_seassum.nc"
echo "  -> pr_seassum.nc"
echo ""

# --------------------------------------------------
# 5. Annual precipitation totals
# --------------------------------------------------
echo "[5/9] Computing annual precipitation totals"
cdo yearsum "$OUTPUT_DIR/pr_2000_2010.nc" "$OUTPUT_DIR/pr_yearsum.nc"
echo "  -> pr_yearsum.nc"
echo ""

# --------------------------------------------------
# 6. Wet-day frequency (days with pr >= 1 mm/day)
# --------------------------------------------------
echo "[6/9] Computing wet-day frequency (pr >= 1 mm/day)"
cdo gec,1.0 "$OUTPUT_DIR/pr_2000_2010.nc" "$OUTPUT_DIR/pr_wetdays_mask.nc"
cdo yearmean "$OUTPUT_DIR/pr_wetdays_mask.nc" "$OUTPUT_DIR/pr_wetday_freq.nc"
echo "  -> pr_wetday_freq.nc"
echo ""

# --------------------------------------------------
# 7. Consecutive dry days (CDD)
# --------------------------------------------------
echo "[7/9] Computing consecutive dry days (CDD)"
cdo lt,1.0 "$OUTPUT_DIR/pr_2000_2010.nc" "$OUTPUT_DIR/pr_drydays_mask.nc"
cdo consects "$OUTPUT_DIR/pr_drydays_mask.nc" "$OUTPUT_DIR/pr_cdd.nc"
echo "  -> pr_cdd.nc"
echo ""

# --------------------------------------------------
# 8. Consecutive wet days (CWD)
# --------------------------------------------------
echo "[8/9] Computing consecutive wet days (CWD)"
cdo gec,1.0 "$OUTPUT_DIR/pr_2000_2010.nc" "$OUTPUT_DIR/pr_wetdays_mask2.nc"
cdo consects "$OUTPUT_DIR/pr_wetdays_mask2.nc" "$OUTPUT_DIR/pr_cwd.nc"
echo "  -> pr_cwd.nc"
echo ""

# --------------------------------------------------
# 9. SPI-like index: 3-month running sum standardized
# --------------------------------------------------
echo "[9/9] Computing 3-month running precipitation sum (SPI-like)"
cdo runsum,3 "$OUTPUT_DIR/pr_monsum.nc" "$OUTPUT_DIR/pr_runsum3.nc"
cdo sub "$OUTPUT_DIR/pr_runsum3.nc" -timmean "$OUTPUT_DIR/pr_runsum3.nc" "$OUTPUT_DIR/pr_spi3_anomaly.nc"
cdo div "$OUTPUT_DIR/pr_spi3_anomaly.nc" -timstd "$OUTPUT_DIR/pr_runsum3.nc" "$OUTPUT_DIR/pr_spi3.nc"
echo "  -> pr_spi3.nc"
echo ""

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo "=============================================="
echo "  Precipitation processing complete!"
echo "=============================================="
echo "Outputs:"
ls -lh "$OUTPUT_DIR"/pr_*.nc
echo ""
echo "To view annual rainfall totals:"
echo "  cdo outputts $OUTPUT_DIR/pr_yearsum.nc | head -10"
