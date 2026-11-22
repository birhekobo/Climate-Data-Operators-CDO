#!/bin/bash
# process_temperature.sh
# Comprehensive temperature data processing pipeline for CDO training.
set -euo pipefail

INPUT_DIR="../datasets"
OUTPUT_DIR="../output"
SAMPLE_FILE="$INPUT_DIR/tas_sample.nc"

mkdir -p "$OUTPUT_DIR"

echo "============================================"
echo "  Temperature Data Processing Pipeline"
echo "============================================"
echo "Input : $SAMPLE_FILE"
echo "Output: $OUTPUT_DIR"
echo ""

# --------------------------------------------------
# 1. Get dataset info
# --------------------------------------------------
echo "[1/8] Dataset information (sinfo)"
cdo sinfo "$SAMPLE_FILE" | tee "$OUTPUT_DIR/tas_sinfo.txt"
echo ""

# --------------------------------------------------
# 2. Select specific time period (2000–2010)
# --------------------------------------------------
echo "[2/8] Selecting years 2000–2010"
cdo selyear,2000/2010 "$SAMPLE_FILE" "$OUTPUT_DIR/tas_2000_2010.nc"
echo "  -> tas_2000_2010.nc"
echo ""

# --------------------------------------------------
# 3. Monthly means
# --------------------------------------------------
echo "[3/8] Computing monthly means"
cdo monmean "$OUTPUT_DIR/tas_2000_2010.nc" "$OUTPUT_DIR/tas_monmean.nc"
echo "  -> tas_monmean.nc"
echo ""

# --------------------------------------------------
# 4. Seasonal means (DJF, MAM, JJA, SON)
# --------------------------------------------------
echo "[4/8] Computing seasonal means"
cdo seasmean "$OUTPUT_DIR/tas_2000_2010.nc" "$OUTPUT_DIR/tas_seasmean.nc"
echo "  -> tas_seasmean.nc"
echo ""

# --------------------------------------------------
# 5. Annual means
# --------------------------------------------------
echo "[5/8] Computing annual means"
cdo yearmean "$OUTPUT_DIR/tas_2000_2010.nc" "$OUTPUT_DIR/tas_yearmean.nc"
echo "  -> tas_yearmean.nc"
echo ""

# --------------------------------------------------
# 6. Climatology (monthly climatology over reference period)
# --------------------------------------------------
echo "[6/8] Computing monthly climatology (ymonmean)"
cdo ymonmean "$OUTPUT_DIR/tas_2000_2010.nc" "$OUTPUT_DIR/tas_climatology.nc"
echo "  -> tas_climatology.nc"
echo ""

# --------------------------------------------------
# 7. Anomalies (field minus climatology)
# --------------------------------------------------
echo "[7/8] Computing monthly anomalies"
cdo ymonsub "$OUTPUT_DIR/tas_2000_2010.nc" "$OUTPUT_DIR/tas_climatology.nc" "$OUTPUT_DIR/tas_anomalies.nc"
echo "  -> tas_anomalies.nc"
echo ""

# --------------------------------------------------
# 8. Spatial average → global mean anomaly time series
# --------------------------------------------------
echo "[8/8] Computing global mean anomaly (fldmean)"
cdo fldmean "$OUTPUT_DIR/tas_anomalies.nc" "$OUTPUT_DIR/tas_global_anomaly.nc"
echo "  -> tas_global_anomaly.nc"
echo ""

# --------------------------------------------------
# Summary
# --------------------------------------------------
echo "============================================"
echo "  Temperature processing complete!"
echo "============================================"
echo "Outputs:"
ls -lh "$OUTPUT_DIR"/tas_*.nc
echo ""
echo "To view global anomaly time series:"
echo "  cdo outputts $OUTPUT_DIR/tas_global_anomaly.nc | head -20"
