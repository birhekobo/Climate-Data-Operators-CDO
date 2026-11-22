---
title: "Project 4: Climate Extremes Detection"
subject: Climate Data Operators (CDO) Training
subtitle: Computing ETCCDI Climate Extreme Indices with CDO
---

# Project 4: Climate Extremes Detection

## Overview

Climate extremes have significant impacts on ecosystems, agriculture, infrastructure, and human health. This project guides you through computing the Expert Team on Climate Change Detection and Indices (ETCCDI) extreme indices using daily temperature and precipitation data with CDO.

```{note}
**Estimated time**: 3-4 hours
**Prerequisites**: Modules 1-10 (including temporal statistics and conditional operators)
```

## Learning Objectives

After completing this project, you will be able to:

- Understand the ETCCDI climate extreme indices and their definitions
- Compute temperature-based extremes (FD, SU, TR, GSL, TXx, TNn, WSDI, CSDI)
- Compute precipitation-based extremes (Rx1day, Rx5day, R10mm, R20mm, CDD, CWD, SDII)
- Analyze trends in extreme event frequency and intensity
- Create comprehensive extreme indices dashboards
- Interpret changes in extremes in the context of climate change

## ETCCDI Indices Overview

### Temperature Indices

| Index | Name | Definition | Unit |
|-------|------|------------|------|
| FD | Frost Days | Annual count of days with TG < 0°C | days |
| SU | Summer Days | Annual count of days with TX > 25°C | days |
| TR | Tropical Nights | Annual count of days with TN > 20°C | days |
| GSL | Growing Season Length | Annual count between first span of >5 days TG > 5°C and last span | days |
| TXx | Max Tmax | Monthly maximum of daily maximum temperature | °C |
| TNn | Min Tmin | Monthly minimum of daily minimum temperature | °C |
| WSDI | Warm Spell Duration | Annual count of ≥6 consecutive days TX > 90th percentile | days |
| CSDI | Cold Spell Duration | Annual count of ≥6 consecutive days TN < 10th percentile | days |

### Precipitation Indices

| Index | Name | Definition | Unit |
|-------|------|------------|------|
| Rx1day | Max 1-day precipitation | Annual maximum of daily precipitation | mm |
| Rx5day | Max 5-day precipitation | Annual maximum of 5-day running sum | mm |
| R10mm | Heavy precipitation days | Annual count of days with PR ≥ 10mm | days |
| R20mm | Very heavy precipitation days | Annual count of days with PR ≥ 20mm | days |
| R50mm | Extreme precipitation days | Annual count of days with PR ≥ 50mm | days |
| CDD | Consecutive Dry Days | Maximum length of dry spell (PR < 1mm) | days |
| CWD | Consecutive Wet Days | Maximum length of wet spell (PR ≥ 1mm) | days |
| SDII | Simple Daily Intensity Index | Total precipitation divided by number of wet days | mm/day |
| PRCPTOT | Total wet-day precipitation | Annual total precipitation from wet days (≥1mm) | mm |

## Data Requirements

| Attribute | Description |
|-----------|-------------|
| **Variables** | tasmin (TN), tasmax (TX), tas (TG), pr (PR) |
| **Temporal resolution** | Daily |
| **Minimum length** | 30 years |
| **Spatial resolution** | Any (ERA5, station data, or CMIP6) |

### Real Data Source

Climate-extreme indices must be computed from real observations or reanalysis. This course provides real gridded fields for practising the CDO operator chain:

```bash
# Inspect the real reanalysis fields supplied with the course
cdo sinfo ../datasets/tas_sample.nc
cdo sinfo ../datasets/pr_sample.nc

# For daily indices (TX/TN, frost days), obtain real daily ERA5-Land or station data
# from the Copernicus Climate Data Store; the CDO commands below work unchanged.
```

```{note}
The bundled monthly fields are sufficient to demonstrate the CDO workflow. Replace them with real daily data from CDS or a national meteorological agency for published climate-extreme results.
```

```{warning}
Daily data files can be very large. Process step by step and remove intermediate files. Use CDO's `-O` flag to overwrite files.
```

## Step-by-Step Workflow

### Step 1: Data Quality Control

Before computing indices, perform quality checks:

```bash
# Check for missing values
cdo info daily_tg.nc | grep -c "miss"

# Check for physically implausible values
cdo output -timmin daily_tn.nc   # Minimum TN
cdo output -timmax daily_tx.nc   # Maximum TX
cdo output -timmean daily_tg.nc  # Mean TG

# Remove leap days for consistency (optional)
cdo -O -del29feb daily_tg.nc daily_tg_noleap.nc
cdo -O -del29feb daily_tx.nc daily_tx_noleap.nc
cdo -O -del29feb daily_tn.nc daily_tn_noleap.nc
cdo -O -del29feb daily_pr.nc daily_pr_noleap.nc
```

```{tip}
Removing February 29 ensures all years have 365 days, which simplifies comparison of annual statistics across years.
```

### Step 2: Temperature Extremes

#### Frost Days (FD): Annual count of days with TG < 0°C

```bash
# Identify frost days
cdo -O ltc,0 daily_tg.nc frost_mask.nc  # 1 where TG < 0

# Annual count
cdo -O yearsum frost_mask.nc fd.nc

# Spatial average
cdo -O fldmean fd.nc fd_region.nc
cdo output fd_region.nc > fd_timeseries.csv
```

#### Summer Days (SU): Annual count of days with TX > 25°C

```bash
cdo -O gtc,25 daily_tx.nc summer_mask.nc
cdo -O yearsum summer_mask.nc su.nc
cdo -O fldmean su.nc su_region.nc
cdo output su_region.nc > su_timeseries.csv
```

#### Tropical Nights (TR): Annual count of days with TN > 20°C

```bash
cdo -O gtc,20 daily_tn.nc tropical_mask.nc
cdo -O yearsum tropical_mask.nc tr.nc
cdo -O fldmean tr.nc tr_region.nc
cdo output tr_region.nc > tr_timeseries.csv
```

#### Growing Season Length (GSL)

```bash
# Identify days with TG > 5°C
cdo -O gtc,5 daily_tg.nc gsl_mask.nc

# First day of growing season (first span of >5 consecutive days TG > 5°C)
# This requires more complex processing — use Python
```

#### Monthly Maximum Tmax (TXx)

```bash
cdo -O monmax daily_tx.nc txx.nc
cdo -O yearmax txx.nc txx_annual.nc
cdo -O fldmean txx_annual.nc txx_region.nc
```

#### Monthly Minimum Tmin (TNn)

```bash
cdo -O monmin daily_tn.nc tnn.nc
cdo -O yearmin tnn.nc tnn_annual.nc
cdo -O fldmean tnn_annual.nc tnn_region.nc
```

#### Warm Spell Duration Index (WSDI)

WSDI counts annual days in spans of ≥6 consecutive days where TX > 90th percentile (based on a 5-day window centered on each calendar day).

```bash
# Step 1: Compute daily 90th percentile for each calendar day
# Using a 5-day window centered on each day
cdo -O ydaypctl,90 daily_tx.nc tx90.nc -ydaymin daily_tx.nc -ydaymax daily_tx.nc

# Step 2: Identify days exceeding the 90th percentile
cdo -O gec,daily_tx.nc tx90.nc tx_exceed90.nc

# Step 3: Find runs of 6+ consecutive exceedance days
cdo -O runsum,6 tx_exceed90.nc tx_run6.nc
cdo -O ge,6 tx_run6.nc wsdi_days.nc

# Step 4: Annual sum
cdo -O yearsum wsdi_days.nc wsdi.nc
```

#### Cold Spell Duration Index (CSDI)

Similar to WSDI but for TN < 10th percentile:

```bash
# Step 1: Compute daily 10th percentile
cdo -O ydaypctl,10 daily_tn.nc tn10.nc -ydaymin daily_tn.nc -ydaymax daily_tn.nc

# Step 2: Identify days below the 10th percentile
cdo -O lec,daily_tn.nc tn10.nc tn_below10.nc

# Step 3: Find runs of 6+ consecutive days
cdo -O runsum,6 tn_below10.nc tn_run6.nc
cdo -O ge,6 tn_run6.nc csdi_days.nc

# Step 4: Annual sum
cdo -O yearsum csdi_days.nc csdi.nc
```

### Step 3: Precipitation Extremes

#### Maximum 1-Day Precipitation (Rx1day)

```bash
cdo -O yearmax daily_pr.nc rx1day.nc
cdo -O fldmean rx1day.nc rx1day_region.nc
cdo output rx1day_region.nc > rx1day_timeseries.csv
```

#### Maximum 5-Day Precipitation (Rx5day)

```bash
# Running 5-day sum
cdo -O runsum,5 daily_pr.nc pr_5day.nc

# Annual maximum of 5-day sum
cdo -O yearmax pr_5day.nc rx5day.nc
cdo -O fldmean rx5day.nc rx5day_region.nc
cdo output rx5day_region.nc > rx5day_timeseries.csv
```

#### Heavy Precipitation Days (R10mm, R20mm, R50mm)

```bash
# Days with PR >= 10mm
cdo -O gec,10 daily_pr.nc r10mm_mask.nc
cdo -O yearsum r10mm_mask.nc r10mm.nc

# Days with PR >= 20mm
cdo -O gec,20 daily_pr.nc r20mm_mask.nc
cdo -O yearsum r20mm_mask.nc r20mm.nc

# Days with PR >= 50mm
cdo -O gec,50 daily_pr.nc r50mm_mask.nc
cdo -O yearsum r50mm_mask.nc r50mm.nc

# Regional averages
for index in r10mm r20mm r50mm; do
    cdo -O fldmean "${index}.nc" "${index}_region.nc"
    cdo output "${index}_region.nc" > "${index}_timeseries.csv"
done
```

#### Consecutive Dry Days (CDD)

CDD is the maximum annual length of consecutive days with PR < 1mm. This requires year-by-year processing:

```bash
#!/bin/bash
# CDD computation
for year in $(seq 1991 2020); do
    echo "Computing CDD for $year..."

    # Extract year
    cdo -O -selyear,$year daily_pr.nc "${year}_pr.nc"

    # Identify dry days (PR < 1mm)
    cdo -O -ltc,1 "${year}_pr.nc" "${year}_dry.nc"

    # Consecutive dry days: runsum with varying lengths
    # Use consects to find consecutive sections
    cdo -O -consects "${year}_dry.nc" "${year}_consec.nc"

    # Take the maximum consecutive value for each grid cell
    cdo -O -timmax "${year}_consec.nc" "${year}_cdd.nc"
done

# Merge all years
cdo -O -mergetime *_cdd.nc cdd.nc
rm -f *_cdd.nc *_dry.nc *_pr.nc *_consec.nc
```

```{note}
The `consects` operator counts consecutive timesteps where the condition is true. This is ideal for CDD/CWD computation.
```

#### Consecutive Wet Days (CWD)

```bash
#!/bin/bash
# CWD computation
for year in $(seq 1991 2020); do
    echo "Computing CWD for $year..."

    cdo -O -selyear,$year daily_pr.nc "${year}_pr.nc"

    # Identify wet days (PR >= 1mm)
    cdo -O -gec,1 "${year}_pr.nc" "${year}_wet.nc"

    # Consecutive wet days
    cdo -O -consects "${year}_wet.nc" "${year}_consec.nc"

    # Maximum consecutive value
    cdo -O -timmax "${year}_consec.nc" "${year}_cwd.nc"
done

cdo -O -mergetime *_cwd.nc cwd.nc
rm -f *_cwd.nc *_wet.nc *_pr.nc *_consec.nc
```

```{tip}
Parallelize the CDD/CWD computation using GNU Parallel:
```bash
seq 1991 2020 | parallel -j 4 'cdo -O -selyear,{} daily_pr.nc {}_pr.nc && cdo -O -ltc,1 {}_pr.nc {}_dry.nc && cdo -O -consects {}_dry.nc {}_consec.nc && cdo -O -timmax {}_consec.nc {}_cdd.nc && rm -f {}_pr.nc {}_dry.nc {}_consec.nc'
```

#### Simple Daily Intensity Index (SDII)

```bash
# Total precipitation from wet days (PR >= 1mm)
cdo -O -yearsum -gec,1 daily_pr.nc total_wet.nc

# Number of wet days
cdo -O -yearsum -gec,1 daily_pr.nc wet_days.nc

# SDII = total precipitation / number of wet days
cdo -O div total_wet.nc wet_days.nc sdii.nc

# Remove infinities (where wet_days = 0)
cdo -O setctomiss,inf sdii.nc sdii_clean.nc
```

#### Total Wet-Day Precipitation (PRCPTOT)

```bash
cdo -O -yearsum -gec,1 daily_pr.nc prcptot.nc
cdo -O fldmean prcptot.nc prcptot_region.nc
```

### Step 4: Trend Analysis for Extreme Indices

```bash
# Compute trends for all indices
for index in fd su tr txx tnn wsdi csdi rx1day rx5day r10mm r20mm sdii cdd cwd prcptot; do
    if [ -f "${index}.nc" ]; then
        echo "Trend for $index..."
        cdo -O -trend "${index}.nc" "trend_${index}_intercept.nc" "trend_${index}_slope.nc"
        cdo -O -mulc,10 "trend_${index}_slope.nc" "trend_${index}_per_dec.nc"

        # Regional trend
        trend_val=$(cdo -s output -fldmean "trend_${index}_per_dec.nc")
        echo "$index: $trend_val per decade"
    fi
done
```

### Step 5: Visualization

#### Extreme Indices Dashboard (Python)

```python
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np
import pandas as pd

years = np.arange(1991, 2021)

# Temperature indices
temp_indices = {
    "Frost Days (FD)": "fd_region.nc",
    "Summer Days (SU)": "su_region.nc",
    "Tropical Nights (TR)": "tr_region.nc",
    "Max Tmax (TXx, C)": "txx_region.nc",
    "Min Tmin (TNn, C)": "tnn_region.nc",
    "Warm Spell (WSDI)": "wsdi_region.nc",
}

# Precipitation indices
precip_indices = {
    "Max 1-day Precip (mm)": "rx1day_region.nc",
    "Max 5-day Precip (mm)": "rx5day_region.nc",
    "Heavy Precip Days (R10mm)": "r10mm_region.nc",
    "Very Heavy Precip Days (R20mm)": "r20mm_region.nc",
    "SDII (mm/wet day)": "sdii_region.nc",
    "Consecutive Dry Days (CDD)": "cdd_region.nc",
    "Consecutive Wet Days (CWD)": "cwd_region.nc",
    "Total Wet-day Precip (mm)": "prcptot_region.nc",
}

fig, axes = plt.subplots(4, 4, figsize=(20, 16))
axes = axes.flatten()

idx = 0

# Plot temperature indices
for name, file in temp_indices.items():
    ax = axes[idx]
    try:
        ds = xr.open_dataset(file)
        var = list(ds.data_vars)[0]
        data = ds[var].values
        if len(data) > len(years):
            data = data[:len(years)]

        # Trend
        slope = np.polyfit(years[:len(data)], data, 1)[0]
        trend_line = slope * years[:len(data)] + np.polyfit(years[:len(data)], data, 1)[1]

        ax.plot(years[:len(data)], data, "o-", color="steelblue", markersize=4)
        ax.plot(years[:len(data)], trend_line, "r--", linewidth=1.5,
                label=f"{slope*10:.2f}/dec")
        ax.set_title(name, fontsize=10, fontweight="bold")
        ax.legend(fontsize=8, loc="upper left")
        ax.grid(alpha=0.3)
    except Exception as e:
        ax.text(0.5, 0.5, f"No data\n{file}", ha="center", va="center")
    idx += 1

# Plot precipitation indices
for name, file in precip_indices.items():
    ax = axes[idx]
    try:
        ds = xr.open_dataset(file)
        var = list(ds.data_vars)[0]
        data = ds[var].values
        if len(data) > len(years):
            data = data[:len(years)]

        # Trend
        slope, intercept = np.polyfit(years[:len(data)], data, 1)
        trend_line = slope * years[:len(data)] + intercept

        ax.bar(years[:len(data)], data, color="forestgreen", alpha=0.6)
        ax.plot(years[:len(data)], trend_line, "r-", linewidth=1.5,
                label=f"{slope*10:.1f}/dec")
        ax.set_title(name, fontsize=10, fontweight="bold")
        ax.legend(fontsize=8, loc="upper left")
        ax.grid(alpha=0.3)
    except Exception as e:
        ax.text(0.5, 0.5, f"No data\n{file}", ha="center", va="center")
    idx += 1

# Hide unused subplots
for i in range(idx, len(axes)):
    axes[i].set_visible(False)

plt.suptitle("ETCCDI Climate Extreme Indices (1991-2020)",
             fontsize=16, fontweight="bold", y=0.98)
plt.tight_layout()
plt.savefig("extremes_dashboard.png", dpi=150, bbox_inches="tight")
print("Dashboard saved: extremes_dashboard.png")
```

#### Extreme Indices Trend Map (Python)

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

indices_to_map = {
    "Summer Days Trend": "trend_su_per_dec.nc",
    "Frost Days Trend": "trend_fd_per_dec.nc",
    "Rx1day Trend (mm/dec)": "trend_rx1day_per_dec.nc",
    "CDD Trend (days/dec)": "trend_cdd_per_dec.nc",
}

fig, axes = plt.subplots(2, 2, figsize=(16, 10),
                          subplot_kw={"projection": ccrs.PlateCarree()})
axes = axes.flatten()

for ax, (name, file) in zip(axes, indices_to_map.items()):
    try:
        ds = xr.open_dataset(file)
        var = list(ds.data_vars)[0]
        data = ds[var]

        # Choose appropriate color scheme
        if "Summer" in name or "heat" in name.lower():
            cmap = "YlOrRd"
            levels = np.linspace(-5, 10, 16) if "Summer" in name else None
        elif "Frost" in name:
            cmap = "RdBu"
            levels = np.linspace(-5, 5, 16)
        elif "Rx1day" in name:
            cmap = "BrBG"
            levels = np.linspace(-5, 5, 16)
        else:
            cmap = "RdBu"
            levels = np.linspace(-3, 3, 16)

        im = ax.contourf(ds.lon, ds.lat, data,
                          levels=levels,
                          transform=ccrs.PlateCarree(),
                          cmap=cmap, extend="both")
        ax.add_feature(cfeature.COASTLINE, linewidth=0.5)
        ax.add_feature(cfeature.BORDERS, linewidth=0.3, alpha=0.3)

        cbar = plt.colorbar(im, ax=ax, orientation="horizontal",
                            pad=0.05, shrink=0.7)
        ax.set_title(name, fontweight="bold")
    except Exception as e:
        ax.text(0.5, 0.5, f"Error:\n{str(e)}", ha="center", va="center")

plt.tight_layout()
plt.savefig("extremes_trend_maps.png", dpi=200, bbox_inches="tight")
print("Figure saved: extremes_trend_maps.png")
```

## Complete Bash Workflow Script

Save as `climate_extremes.sh`:

```bash
#!/bin/bash
# =============================================================================
# ETCCDI Climate Extremes Computation Pipeline
# Climate Data Operators (CDO) Training
# =============================================================================
set -euo pipefail

# Configuration
DATA_PREFIX="daily"
OUTPUT_DIR="extremes_output"
FIRST_YEAR=1991
LAST_YEAR=2020
mkdir -p "$OUTPUT_DIR"

echo "=== ETCCDI Climate Extremes Analysis ==="
echo "Period: $FIRST_YEAR-$LAST_YEAR"
echo "========================================="

# Step 1: Temperature indices
echo "[1/4] Computing temperature indices..."

# FD: Frost days (TG < 0C)
cdo -O -s yearsum -ltc,0 "${DATA_PREFIX}_tg.nc" "$OUTPUT_DIR/fd.nc"

# SU: Summer days (TX > 25C)
cdo -O -s yearsum -gtc,25 "${DATA_PREFIX}_tx.nc" "$OUTPUT_DIR/su.nc"

# TR: Tropical nights (TN > 20C)
cdo -O -s yearsum -gtc,20 "${DATA_PREFIX}_tn.nc" "$OUTPUT_DIR/tr.nc"

# TXx: Monthly max Tmax
cdo -O -s monmax "${DATA_PREFIX}_tx.nc" "$OUTPUT_DIR/txx.nc"

# TNn: Monthly min Tmin
cdo -O -s monmin "${DATA_PREFIX}_tn.nc" "$OUTPUT_DIR/tnn.nc"

# Step 2: Precipitation indices
echo "[2/4] Computing precipitation indices..."

# Rx1day
cdo -O -s yearmax "${DATA_PREFIX}_pr.nc" "$OUTPUT_DIR/rx1day.nc"

# Rx5day
cdo -O -s yearmax -runsum,5 "${DATA_PREFIX}_pr.nc" "$OUTPUT_DIR/rx5day.nc"

# R10mm, R20mm, R50mm
cdo -O -s yearsum -gec,10 "${DATA_PREFIX}_pr.nc" "$OUTPUT_DIR/r10mm.nc"
cdo -O -s yearsum -gec,20 "${DATA_PREFIX}_pr.nc" "$OUTPUT_DIR/r20mm.nc"

# PRCPTOT
cdo -O -s yearsum -gec,1 "${DATA_PREFIX}_pr.nc" "$OUTPUT_DIR/prcptot.nc"

# SDII
cdo -O -s div -yearsum -gec,1 "${DATA_PREFIX}_pr.nc" \
    -yearsum -gec,1 "${DATA_PREFIX}_pr.nc" "$OUTPUT_DIR/sdii.nc"

# CDD and CWD (year-by-year)
echo "[3/4] Computing CDD and CWD..."
for year in $(seq $FIRST_YEAR $LAST_YEAR); do
    cdo -O -s -selyear,$year "${DATA_PREFIX}_pr.nc" "$OUTPUT_DIR/yy_pr.nc"
    cdo -O -s -ltc,1 "$OUTPUT_DIR/yy_pr.nc" "$OUTPUT_DIR/yy_dry.nc"
    cdo -O -s -consects "$OUTPUT_DIR/yy_dry.nc" "$OUTPUT_DIR/yy_consec_dry.nc"
    cdo -O -s -timmax "$OUTPUT_DIR/yy_consec_dry.nc" "$OUTPUT_DIR/yy_cdd.nc"
    cdo -O -s -gec,1 "$OUTPUT_DIR/yy_pr.nc" "$OUTPUT_DIR/yy_wet.nc"
    cdo -O -s -consects "$OUTPUT_DIR/yy_wet.nc" "$OUTPUT_DIR/yy_consec_wet.nc"
    cdo -O -s -timmax "$OUTPUT_DIR/yy_consec_wet.nc" "$OUTPUT_DIR/yy_cwd.nc"
done
cdo -O -s -mergetime "$OUTPUT_DIR"/yy_cdd_*.nc "$OUTPUT_DIR/cdd.nc"
cdo -O -s -mergetime "$OUTPUT_DIR"/yy_cwd_*.nc "$OUTPUT_DIR/cwd.nc"
rm -f "$OUTPUT_DIR"/yy_*.nc

# Step 4: Regional averages and trends
echo "[4/4] Computing regional averages and trends..."
for index in fd su tr rx1day rx5day r10mm r20mm prcptot sdii cdd cwd; do
    cdo -O -s fldmean "$OUTPUT_DIR/${index}.nc" "$OUTPUT_DIR/${index}_region.nc"
    cdo -O -s trend "$OUTPUT_DIR/${index}.nc" \
        "$OUTPUT_DIR/trend_${index}_int.nc" "$OUTPUT_DIR/trend_${index}_slp.nc"
    cdo -O -s mulc,10 "$OUTPUT_DIR/trend_${index}_slp.nc" \
        "$OUTPUT_DIR/trend_${index}_per_dec.nc"
done

# Summary
echo "========================================="
echo "Extremes Analysis Complete!"
echo "Output directory: $OUTPUT_DIR"
echo "-----------------------------------------"
echo "Trends (per decade):"
for index in fd su tr rx1day rx5day r10mm r20mm prcptot sdii cdd cwd; do
    val=$(cdo -s output -fldmean "$OUTPUT_DIR/trend_${index}_per_dec.nc" 2>/dev/null | head -1)
    echo "  $index: $val"
done
echo "========================================="
```

## Expected Outputs

### 1. Extreme Indices Dashboard
16-panel figure showing time series of all ETCCDI indices with:
- Annual values as bars or points
- Linear trend lines
- Trend values annotated

### 2. Trend Maps for Key Indices
Spatial maps showing decadal trends for selected indices:
- Summer Days (SU) showing regions of increasing heat days
- Frost Days (FD) highlighting decreasing cold events
- Rx1day revealing changes in extreme precipitation
- CDD indicating drought risk changes

### 3. Summary Trend Table

| Index | Regional Trend | Units | Direction |
|-------|---------------|-------|-----------|
| FD | -2.3 | days/decade | Decreasing |
| SU | +4.1 | days/decade | Increasing |
| TR | +3.2 | days/decade | Increasing |
| Rx1day | +1.5 | mm/decade | Increasing |
| Rx5day | +3.8 | mm/decade | Increasing |
| R10mm | +0.8 | days/decade | Increasing |
| CDD | +1.2 | days/decade | Increasing |

## Interpretation Guidance

### What to Look For

1. **Temperature extremes**: Are hot extremes (SU, TR, TXx) increasing? Are cold extremes (FD, TNn) decreasing?
2. **Precipitation intensity**: Is Rx1day/Rx5day increasing (more intense storms)?
3. **Dry/wet spells**: Are CDD (dry spells) lengthening? Is CWD changing?
4. **Consistency**: Do the indices tell a coherent story about climate change in your region?

### Key Questions

- How have frost days changed in your region? Is the frost-free season lengthening?
- Are summer days and tropical nights increasing at the same rate?
- Is precipitation becoming more intense even if total amounts aren't changing?
- Are there differences in extreme behavior between different climate zones in your domain?

### Common Pitfalls

```{warning}
- **Threshold selection**: The ETCCDI thresholds (25°C, 20°C, 0°C, 1mm) may not be appropriate for all climates. Consider regional thresholds.
- **Data quality**: Daily data often contains unrealistic values. Always check the min/max of each variable.
- **Incomplete years**: Ensure each year has a complete (or nearly complete) daily record.
- **Leap years**: February 29 can introduce small biases. Use `-del29feb` for consistency.
```

## Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Temperature indices | 20% | Correct computation of FD, SU, TR, TXx, TNn, WSDI |
| Precipitation indices | 20% | Correct computation of Rx1day, Rx5day, R10mm, R20mm, CDD, CWD, SDII |
| CDO operators | 25% | Appropriate use of ltc, gtc, yearsum, runsum, consects, ydaypctl |
| Trend analysis | 15% | Correct trend computation and interpretation |
| Visualization | 10% | Clear dashboard presentation |
| Interpretation | 10% | Understanding of extreme index behavior |

## Extension Activities

### Advanced Options

1. **Heat wave characterization**: Define heat waves as ≥3 consecutive days with TX exceeding a threshold, and analyze their frequency, duration, and intensity
2. **Flood risk assessment**: Combine Rx5day with antecedent soil moisture conditions
3. **Percentile-based thresholds**: Use locally-defined percentiles instead of fixed thresholds
4. **Extreme value analysis**: Fit GEV/GPD distributions to annual maxima

```bash
# Example: Heat wave identification (TX > 35C for 3+ consecutive days)
cdo -O -yearsum -ge,3 -runsum,3 -gtc,35 daily_tx.nc heatwave_days.nc
```

### Cross-Project Integration

- Compare extreme trends with mean climate changes from **Projects 1 and 2**
- Use extreme indices as predictors for drought analysis in **Project 3**
- Include extremes in the automated report from **Project 8**
- Compare with CMIP6 projections of extremes from **Project 6**

```{exercise}
Complete the climate extremes detection. Compute at least 10 ETCCDI indices for your region. Create the dashboard and trend maps. Which extremes are changing fastest in your region? Are temperature and precipitation extremes changing consistently with global warming expectations?
```

## References

- Zhang, X., et al. (2011). Indices for monitoring changes in extremes based on daily temperature and precipitation data. WIREs Climate Change, 2(6), 851-870.
- Karl, T.R., et al. (1999). CLIVAR/GCOS/WMO workshop on indices and indicators for climate extremes. Climatic Change, 42(1), 3-7.
- Sillmann, J., et al. (2013). Climate extremes indices in the CMIP5 multimodel ensemble. Journal of Geophysical Research, 118(4), 1718-1733.
- CDO Documentation: https://code.mpimet.mpg.de/projects/cdo
