#!/bin/bash
# download_sample_data.sh
# Verifies the REAL sample NetCDF datasets bundled with this CDO training course.
# All datasets are observations or reanalysis products supplied in the repository.

set -euo pipefail

DATASETS_DIR="../datasets"
mkdir -p "$DATASETS_DIR"

echo "========================================"
echo "  CDO Training - Real Sample Data Checker"
echo "========================================"

# Real observation / reanalysis datasets bundled with the course
REQUIRED_FILES=(
    "tas_sample.nc"       # NCEP/DOE Reanalysis-2 monthly temperature
    "tas_2000.nc"         # annual reanalysis subsets for merge/split exercises
    "tas_2001.nc"
    "tas_2002.nc"
    "tas_2003.nc"
    "tas_2004.nc"
    "tas_2005.nc"
    "tas_europe.nc"       # regional European reanalysis subset
    "pr_sample.nc"        # real precipitation field
    "chirps_ethiopia.nc"  # CHIRPS monthly precipitation for Ethiopia
    "chirps_annual.nc"    # CHIRPS annual totals
    "chirps_climatology.nc"  # CHIRPS monthly climatology
)

missing=0
for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$DATASETS_DIR/$f" ]]; then
        echo "OK       $f"
    else
        echo "MISSING  $f"
        missing=1
    fi
done

if [[ $missing -ne 0 ]]; then
    echo ""
    echo "Some real datasets are missing. Restore them from the course repository,"
    echo "or download real NCEP/DOE Reanalysis-2 and CHIRPS data from their providers:"
    echo "  - NCEP/DOE Reanalysis-2: https://psl.noaa.gov/data/gridded/data.ncep.reanalysis2.html"
    echo "  - CHIRPS: https://data.chc.ucsb.edu/products/CHIRPS-2.0/"
    exit 1
fi

echo ""
echo "All real sample datasets are present in: $DATASETS_DIR"
ls -lh "$DATASETS_DIR"/*.nc
