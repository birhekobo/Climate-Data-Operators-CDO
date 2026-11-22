---
title: "Project 6: CMIP6 Multi-Model Analysis"
subject: Climate Data Operators (CDO) Training
subtitle: Analyzing CMIP6 Climate Projections Using Multi-Model Ensembles
---

# Project 6: CMIP6 Multi-Model Analysis

## Overview

Climate projections from multiple models are essential for understanding future climate change and its uncertainties. This project guides you through processing CMIP6 data from multiple climate models, regridding to a common grid, computing multi-model ensemble statistics, and analyzing projected changes.

```{note}
**Estimated time**: 3-4 hours
**Prerequisites**: Modules 1-11, understanding of climate modeling concepts
```

## Learning Objectives

After completing this project, you will be able to:

- Organize and manage multi-model CMIP6 datasets
- Regrid different models to a common grid using CDO interpolation
- Compute multi-model ensemble mean and spread
- Compare different SSP scenarios (SSP2-4.5 vs SSP5-8.5)
- Compute and visualize projected climate changes
- Quantify model agreement and uncertainty
- Create publication-quality ensemble summary figures

## Data Requirements

### CMIP6 Data Overview

| Attribute | Description |
|-----------|-------------|
| **Variables** | tas (surface temperature), pr (precipitation), ps (surface pressure) |
| **Experiments** | historical, ssp245, ssp585 |
| **Models** | Minimum 3-5 models recommended |
| **Temporal resolution** | Monthly or annual |
| **Time periods** | Historical (1850-2014), Future (2015-2100) |

### Recommended Models

| Model | Institution | Resolution (lat x lon) |
|-------|-------------|----------------------|
| ACCESS-CM2 | CSIRO/BoM (Australia) | 1.25 x 1.875 |
| CanESM5 | CCCma (Canada) | 2.8 x 2.8 |
| CNRM-CM6-1 | CNRM/CERFACS (France) | 1.4 x 1.4 |
| HadGEM3-GC31-LL | MOHC (UK) | 1.25 x 1.875 |
| MPI-ESM1-2-LR | MPI-M (Germany) | 1.9 x 1.9 |
| MRI-ESM2-0 | MRI (Japan) | 1.1 x 1.1 |
| NorESM2-LM | NCC (Norway) | 1.9 x 2.5 |

### Data Organization

```bash
mkdir -p cmip6_data/{raw,processed,output}
mkdir -p cmip6_data/raw/{historical,ssp245,ssp585}
```

### Real CMIP6 Data Access

Use real CMIP6 model output from the Earth System Grid Federation (ESGF). The example below uses `intake-esm` to discover real model data from the Pangeo CMIP6 catalog:

```python
#!/usr/bin/env python3
"""Discover real CMIP6 model output from an ESGF catalog."""
import intake

# Real CMIP6 catalog served by Pangeo/ESGF
cat = intake.open_esm_datastore(
    "https://storage.googleapis.com/cmip6/pangeo-cmip6.json"
)

subset = cat.search(
    experiment_id=["historical", "ssp245", "ssp585"],
    table_id="Amon",
    variable_id=["tas", "pr"],
    member_id="r1i1p1f1",
)
print(f"Found {len(subset.df)} real CMIP6 datasets")

# Load real model output into xarray datasets for the CDO workflow
dsets = subset.to_dataset_dict()
for key, ds in dsets.items():
    print(key, dict(ds.sizes))
    break
```

```{note}
CMIP6 files must be obtained from ESGF (or the catalog above) before running the CDO workflow. Do not substitute artificially generated fields for published multi-model results.
```

## Step-by-Step Workflow

### Step 1: Data Inventory and Inspection

```bash
# Inventory of available models and scenarios
echo "=== Data Inventory ==="
for scenario in historical ssp245 ssp585; do
    echo "--- $scenario ---"
    ls cmip6_data/raw/$scenario/
    echo "Models available: $(ls cmip6_data/raw/$scenario/*.nc | wc -l)"
done

# Inspect individual model output
cdo sinfo cmip6_data/raw/historical/ACCESS-CM2_historical_tas_pr.nc
cdo griddes cmip6_data/raw/historical/ACCESS-CM2_historical_tas_pr.nc
cdo showyear cmip6_data/raw/historical/ACCESS-CM2_historical_tas_pr.nc
cdo ntime cmip6_data/raw/historical/ACCESS-CM2_historical_tas_pr.nc
```

### Step 2: Check Model Grids

Different CMIP6 models have different native grids. Check before regridding:

```bash
echo "=== Model Grids ==="
for model in ACCESS-CM2 CanESM5 CNRM-CM6-1 MPI-ESM1-2-LR MRI-ESM2-0 NorESM2-LM; do
    file="cmip6_data/raw/historical/${model}_historical_tas_pr.nc"
    if [ -f "$file" ]; then
        nlon=$(cdo -s griddes "$file" | grep "xsize" | awk '{print $3}')
        nlat=$(cdo -s griddes "$file" | grep "ysize" | awk '{print $3}')
        echo "$model: ${nlon}x${nlat} grid points"
    fi
done
```

### Step 3: Regrid All Models to Common Grid

Use a standard 2.5 x 2.5 degree grid for the ensemble:

```bash
#!/bin/bash
# Regrid all models to common grid
OUTPUT_DIR="cmip6_data/processed"
TARGET_GRID="r144x73"  # 2.5 degree grid (144x73)
mkdir -p "$OUTPUT_DIR"

echo "=== Regridding Models ==="

# Create target grid description
cat > "$OUTPUT_DIR/target_grid.txt" << EOF
gridtype = lonlat
xsize = 144
ysize = 73
xfirst = 0
xinc = 2.5
yfirst = -90
yinc = 2.5
EOF

for model in ACCESS-CM2 CanESM5 CNRM-CM6-1 MPI-ESM1-2-LR MRI-ESM2-0 NorESM2-LM; do
    for scenario in historical ssp245 ssp585; do
        infile="cmip6_data/raw/${scenario}/${model}_${scenario}_tas_pr.nc"
        outfile="$OUTPUT_DIR/${model}_${scenario}_regrid.nc"

        if [ ! -f "$infile" ]; then
            echo "  WARNING: $infile not found, skipping"
            continue
        fi

        echo "  Regridding $model ($scenario)..."

        # Conservative remapping recommended for precipitation
        # Bilinear for temperature
        cdo -O -s -remapbil,"$OUTPUT_DIR/target_grid.txt" \
            -selname,tas "$infile" "$OUTPUT_DIR/tmp_${model}_${scenario}_tas.nc"

        cdo -O -s -remapcon,"$OUTPUT_DIR/target_grid.txt" \
            -selname,pr "$infile" "$OUTPUT_DIR/tmp_${model}_${scenario}_pr.nc"

        cdo -O -s -merge \
            "$OUTPUT_DIR/tmp_${model}_${scenario}_tas.nc" \
            "$OUTPUT_DIR/tmp_${model}_${scenario}_pr.nc" \
            "$outfile"

        rm -f "$OUTPUT_DIR/tmp_${model}_${scenario}_tas.nc" \
              "$OUTPUT_DIR/tmp_${model}_${scenario}_pr.nc"

        echo "    -> $outfile"
    done
done

echo "Regridding complete!"
```

```{note}
Use `remapbil` (bilinear) for smooth fields like temperature and `remapcon` (conservative) for precipitation to preserve mass balance.
```

### Step 4: Select Common Time Period

All models must have data for the same time period for ensemble statistics:

```bash
# Select 1981-2014 for historical and 2081-2100 for future
mkdir -p "$OUTPUT_DIR/clim_periods"

for model in ACCESS-CM2 CanESM5 CNRM-CM6-1 MPI-ESM1-2-LR MRI-ESM2-0 NorESM2-LM; do
    # Historical baseline (1981-2014)
    infile="$OUTPUT_DIR/${model}_historical_regrid.nc"
    if [ -f "$infile" ]; then
        cdo -O -s -selyear,1981/2014 "$infile" \
            "$OUTPUT_DIR/clim_periods/${model}_historical_1981-2014.nc"
    fi

    # Future periods (2081-2100)
    for scenario in ssp245 ssp585; do
        infile="$OUTPUT_DIR/${model}_${scenario}_regrid.nc"
        if [ -f "$infile" ]; then
            cdo -O -s -selyear,2081/2100 "$infile" \
                "$OUTPUT_DIR/clim_periods/${model}_${scenario}_2081-2100.nc"
        fi
    done
done
```

### Step 5: Compute Multi-Model Ensemble Statistics

```bash
# Ensemble mean and spread for historical period
echo "=== Multi-Model Ensemble Statistics ==="

for scenario in historical ssp245 ssp585; do
    period="1981-2014"
    if [ "$scenario" != "historical" ]; then
        period="2081-2100"
    fi

    echo "Computing ensemble for $scenario ($period)..."

    # Collect all model files for this scenario/period
    files=$(ls "$OUTPUT_DIR/clim_periods/"*_${scenario}_${period}.nc 2>/dev/null)
    nfiles=$(echo "$files" | wc -w)

    if [ "$nfiles" -lt 3 ]; then
        echo "  WARNING: Only $nfiles models available for $scenario, need >= 3"
        continue
    fi

    echo "  Using $nfiles models"

    # Compute annual means first
    for model in $files; do
        basename=$(basename "$model" .nc)
        cdo -O -s -yearmean "$model" "$OUTPUT_DIR/tmp_${basename}_annual.nc"
    done

    # Ensemble mean
    cdo -O -s -ensmean "$OUTPUT_DIR"/tmp_*_${scenario}_${period}_annual.nc \
        "$OUTPUT_DIR/ensmean_${scenario}_annual.nc"

    # Ensemble standard deviation (model spread)
    cdo -O -s -ensstd "$OUTPUT_DIR"/tmp_*_${scenario}_${period}_annual.nc \
        "$OUTPUT_DIR/ensstd_${scenario}_annual.nc"

    # Ensemble min and max
    cdo -O -s -ensmin "$OUTPUT_DIR"/tmp_*_${scenario}_${period}_annual.nc \
        "$OUTPUT_DIR/ensmin_${scenario}_annual.nc"
    cdo -O -s -ensmax "$OUTPUT_DIR"/tmp_*_${scenario}_${period}_annual.nc \
        "$OUTPUT_DIR/ensmax_${scenario}_annual.nc"

    # Coefficient of variation (spread / mean)
    cdo -O -s -div "$OUTPUT_DIR/ensstd_${scenario}_annual.nc" \
        "$OUTPUT_DIR/ensmean_${scenario}_annual.nc" \
        "$OUTPUT_DIR/enscv_${scenario}_annual.nc"

    rm -f "$OUTPUT_DIR"/tmp_*_${scenario}_${period}_annual.nc
done
```

### Step 6: Compute Future Changes

```bash
echo "=== Future Changes ==="

# Change = future - historical
for scenario in ssp245 ssp585; do
    echo "Change for $scenario..."

    cdo -O -s -sub \
        "$OUTPUT_DIR/ensmean_${scenario}_annual.nc" \
        "$OUTPUT_DIR/ensmean_historical_annual.nc" \
        "$OUTPUT_DIR/change_${scenario}.nc"

    # Signal-to-noise ratio
    cdo -O -s -div \
        "$OUTPUT_DIR/change_${scenario}.nc" \
        "$OUTPUT_DIR/ensstd_historical_annual.nc" \
        "$OUTPUT_DIR/snr_${scenario}.nc"

    # Relative change for precipitation (percent)
    cdo -O -s -mulc,100 -div \
        "$OUTPUT_DIR/change_${scenario}.nc" \
        "$OUTPUT_DIR/ensmean_historical_annual.nc" \
        "$OUTPUT_DIR/change_${scenario}_percent.nc"
done
```

### Step 7: Model Agreement Analysis

```bash
echo "=== Model Agreement ==="

for scenario in ssp245 ssp585; do
    # For each model, compute sign of change
    sign_dir="$OUTPUT_DIR/sign_${scenario}"
    mkdir -p "$sign_dir"

    for model in ACCESS-CM2 CanESM5 CNRM-CM6-1 MPI-ESM1-2-LR MRI-ESM2-0 NorESM2-LM; do
        his_file="$OUTPUT_DIR/clim_periods/${model}_historical_1981-2014.nc"
        fut_file="$OUTPUT_DIR/clim_periods/${model}_${scenario}_2081-2100.nc"

        if [ -f "$his_file" ] && [ -f "$fut_file" ]; then
            his_mean=$(cdo -s -timmean -yearmean "$his_file")
            fut_mean=$(cdo -s -timmean -yearmean "$fut_file")

            # Sign of change for temperature (warming = positive)
            cdo -O -s -gec,0 -sub -timmean -yearmean "$fut_file" \
                -timmean -yearmean "$his_file" \
                "$sign_dir/${model}_sign_tas.nc"
        fi
    done

    # Fraction of models agreeing
    sign_files=$(ls "$sign_dir"/*_sign_tas.nc 2>/dev/null)
    nsign=$(echo "$sign_files" | wc -w)
    if [ "$nsign" -gt 0 ]; then
        cdo -O -s -ensmean $sign_files \
            "$OUTPUT_DIR/agreement_${scenario}.nc"

        # Convert to percentage
        cdo -O -s -mulc,100 "$OUTPUT_DIR/agreement_${scenario}.nc" \
            "$OUTPUT_DIR/agreement_${scenario}_percent.nc"
    fi
done
```

### Step 8: Time Series Extraction

```bash
echo "=== Time Series Extraction ==="

# Full ensemble time series for variables
for scenario in historical ssp245 ssp585; do
    # Collect model annual means
    for model in ACCESS-CM2 CanESM5 CNRM-CM6-1 MPI-ESM1-2-LR MRI-ESM2-0 NorESM2-LM; do
        infile="$OUTPUT_DIR/${model}_${scenario}_regrid.nc"
        if [ -f "$infile" ]; then
            cdo -O -s -yearmean "$infile" "$OUTPUT_DIR/ts_${model}_${scenario}.nc"
        fi
    done
done

# Ensemble mean time series for each scenario
for scenario in historical ssp245 ssp585; do
    files=$(ls "$OUTPUT_DIR"/ts_*_${scenario}.nc 2>/dev/null)
    nfiles=$(echo "$files" | wc -w)
    if [ "$nfiles" -gt 0 ]; then
        cdo -O -s -ensmean $files "$OUTPUT_DIR/ts_ensmean_${scenario}.nc"
        cdo -O -s -ensstd $files "$OUTPUT_DIR/ts_ensstd_${scenario}.nc"
        cdo -O -s -ensmin $files "$OUTPUT_DIR/ts_ensmin_${scenario}.nc"
        cdo -O -s -ensmax $files "$OUTPUT_DIR/ts_ensmax_${scenario}.nc"

        # Global average
        cdo -O -s -fldmean "$OUTPUT_DIR/ts_ensmean_${scenario}.nc" \
            "$OUTPUT_DIR/ts_ensmean_${scenario}_global.nc"
        cdo -O -s -fldmean "$OUTPUT_DIR/ts_ensstd_${scenario}.nc" \
            "$OUTPUT_DIR/ts_ensstd_${scenario}_global.nc"
    fi
done
```

### Step 9: Visualization

#### Multi-Model Mean Maps (Python)

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

# Load ensemble outputs
ensmean_his = xr.open_dataset("cmip6_data/processed/ensmean_historical_annual.nc")
ensmean_ssp585 = xr.open_dataset("cmip6_data/processed/ensmean_ssp585_annual.nc")
change_ssp585 = xr.open_dataset("cmip6_data/processed/change_ssp585.nc")
agreement = xr.open_dataset("cmip6_data/processed/agreement_ssp585_percent.nc")

tas_var = list(ensmean_his.data_vars)[0]

fig = plt.figure(figsize=(18, 12))

# Historical mean
ax1 = fig.add_subplot(2, 2, 1, projection=ccrs.Robinson(central_longitude=0))
im1 = ax1.contourf(ensmean_his.lon, ensmean_his.lat,
                    ensmean_his[tas_var] - 273.15,
                    levels=np.linspace(-30, 30, 13),
                    transform=ccrs.PlateCarree(), cmap="RdBu_r", extend="both")
ax1.add_feature(cfeature.COASTLINE, linewidth=0.5)
ax1.set_title("Historical Temperature (1981-2014, C)")
plt.colorbar(im1, ax=ax1, orientation="horizontal", pad=0.05, shrink=0.7)

# Future mean
ax2 = fig.add_subplot(2, 2, 2, projection=ccrs.Robinson(central_longitude=0))
im2 = ax2.contourf(ensmean_ssp585.lon, ensmean_ssp585.lat,
                    ensmean_ssp585[tas_var] - 273.15,
                    levels=np.linspace(-30, 30, 13),
                    transform=ccrs.PlateCarree(), cmap="RdBu_r", extend="both")
ax2.add_feature(cfeature.COASTLINE, linewidth=0.5)
ax2.set_title("Future Temperature (2081-2100, SSP5-8.5, C)")
plt.colorbar(im2, ax=ax2, orientation="horizontal", pad=0.05, shrink=0.7)

# Temperature change
change_var = list(change_ssp585.data_vars)[0]
ax3 = fig.add_subplot(2, 2, 3, projection=ccrs.Robinson(central_longitude=0))
im3 = ax3.contourf(change_ssp585.lon, change_ssp585.lat,
                    change_ssp585[change_var],
                    levels=np.linspace(0, 8, 17),
                    transform=ccrs.PlateCarree(), cmap="YlOrRd", extend="both")
ax3.add_feature(cfeature.COASTLINE, linewidth=0.5)
ax3.set_title("Temperature Change (C, SSP5-8.5)")
plt.colorbar(im3, ax=ax3, orientation="horizontal", pad=0.05, shrink=0.7)

# Model agreement
agree_var = list(agreement.data_vars)[0]
ax4 = fig.add_subplot(2, 2, 4, projection=ccrs.Robinson(central_longitude=0))
im4 = ax4.contourf(agreement.lon, agreement.lat, agreement[agree_var],
                    levels=np.linspace(50, 100, 11),
                    transform=ccrs.PlateCarree(), cmap="YlGn")
ax4.add_feature(cfeature.COASTLINE, linewidth=0.5)
ax4.set_title("Model Agreement on Warming (%)")
plt.colorbar(im4, ax=ax4, orientation="horizontal", pad=0.05, shrink=0.7)

plt.suptitle("CMIP6 Multi-Model Analysis - Temperature", fontsize=16, fontweight="bold")
plt.savefig("cmip6_temperature_maps.png", dpi=200, bbox_inches="tight")
print("Saved: cmip6_temperature_maps.png")
```

#### Multi-Model Time Series (Python)

```python
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr

# Load global time series
scenarios = {
    "Historical": ("historical", "gray"),
    "SSP2-4.5": ("ssp245", "blue"),
    "SSP5-8.5": ("ssp585", "red"),
}

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10))

# Temperature
for label, (scenario, color) in scenarios.items():
    try:
        mean = xr.open_dataset(
            f"cmip6_data/processed/ts_ensmean_{scenario}_global.nc")
        std = xr.open_dataset(
            f"cmip6_data/processed/ts_ensstd_{scenario}_global.nc")
        var = list(mean.data_vars)[0]

        years = mean.time.dt.year.values
        mean_vals = mean[var].values - 273.15  # K to C
        std_vals = std[var].values

        ax1.plot(years, mean_vals, color=color, linewidth=2, label=label)
        ax1.fill_between(years, mean_vals - std_vals, mean_vals + std_vals,
                          color=color, alpha=0.15)
    except Exception as e:
        print(f"  Could not load {scenario}: {e}")

ax1.set_ylabel("Global Mean Temperature (C)")
ax1.set_title("CMIP6 Multi-Model Ensemble Temperature Projections")
ax1.legend()
ax1.grid(alpha=0.3)
ax1.axvline(2015, color="black", linestyle="--", alpha=0.5, label="Historical end")

# Precipitation (change relative to 1981-2010)
for label, (scenario, color) in scenarios.items():
    try:
        mean = xr.open_dataset(
            f"cmip6_data/processed/ts_ensmean_{scenario}_global.nc")
        var = list(mean.data_vars)[0]

        if scenario == "historical":
            # Use historical baseline
            his_mean = np.nanmean(mean[var].values[:34])
        else:
            years = mean.time.dt.year.values
            fut_mean = mean[var].values
            # Express as anomaly relative to historical
            # This would need precipitation data loaded separately
    except Exception as e:
        pass

# For the time series, also plot individual models
ax2.set_xlabel("Year")
ax2.set_ylabel("Temperature Anomaly (C)")
ax2.set_title("Scenario Comparison - Global Mean Temperature")
ax2.grid(alpha=0.3)

# Plot anomaly from 1981-2010
for label, (scenario, color) in scenarios.items():
    try:
        mean = xr.open_dataset(
            f"cmip6_data/processed/ts_ensmean_{scenario}_global.nc")
        var = list(mean.data_vars)[0]
        vals = mean[var].values - 273.15

        if scenario == "historical":
            baseline = np.mean(vals[:30])  # 1981-2010
            vals = vals - baseline
        else:
            vals = vals - baseline

        years = mean.time.dt.year.values
        ax2.plot(years, vals, color=color, linewidth=2, label=label)
    except Exception as e:
        print(f"Could not process {scenario}: {e}")

ax2.axhline(1.5, color="orange", linestyle=":", label="1.5C warming")
ax2.axhline(2.0, color="red", linestyle=":", label="2C warming")
ax2.legend()

plt.tight_layout()
plt.savefig("cmip6_timeseries.png", dpi=200, bbox_inches="tight")
print("Saved: cmip6_timeseries.png")
```

#### Model Spread/Uncertainty Map

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

# Compare SSP2-4.5 and SSP5-8.5
fig, axes = plt.subplots(2, 2, figsize=(16, 12),
                          subplot_kw={"projection": ccrs.Robinson(central_longitude=0)})

scenarios = [("ssp245", "SSP2-4.5"), ("ssp585", "SSP5-8.5")]

for row, (scenario, label) in enumerate(scenarios):
    try:
        change = xr.open_dataset(f"cmip6_data/processed/change_{scenario}.nc")
        std = xr.open_dataset(f"cmip6_data/processed/ensstd_{scenario}_annual.nc")

        var = list(change.data_vars)[0]
        std_var = list(std.data_vars)[0]

        # Change map
        ax = axes[row, 0]
        im = ax.contourf(change.lon, change.lat, change[var],
                          levels=np.linspace(0, 8, 17),
                          transform=ccrs.PlateCarree(), cmap="YlOrRd", extend="both")
        ax.add_feature(cfeature.COASTLINE, linewidth=0.5)
        ax.set_title(f"{label} Temperature Change (C)")
        plt.colorbar(im, ax=ax, orientation="horizontal", pad=0.05, shrink=0.7)

        # Spread (uncertainty)
        ax = axes[row, 1]
        im2 = ax.contourf(std.lon, std.lat, std[std_var],
                           levels=np.linspace(0, 2, 9),
                           transform=ccrs.PlateCarree(), cmap="OrRd")
        ax.add_feature(cfeature.COASTLINE, linewidth=0.5)
        ax.set_title(f"{label} Model Spread (C)")
        plt.colorbar(im2, ax=ax, orientation="horizontal", pad=0.05, shrink=0.7)

    except Exception as e:
        axes[row, 0].text(0.5, 0.5, f"Error: {e}",
                          ha="center", va="center", transform=axes[row, 0].transAxes)

plt.suptitle("CMIP6 Scenario Comparison - Change and Uncertainty",
             fontsize=16, fontweight="bold")
plt.savefig("cmip6_uncertainty.png", dpi=200, bbox_inches="tight")
print("Saved: cmip6_uncertainty.png")
```

## Complete Bash Workflow Script

Save as `cmip6_analysis.sh`:

```bash
#!/bin/bash
# =============================================================================
# CMIP6 Multi-Model Analysis Pipeline
# Climate Data Operators (CDO) Training
# =============================================================================
set -euo pipefail

config() {
    RAW_DIR="cmip6_data/raw"
    PROC_DIR="cmip6_data/processed"
    OUTPUT_DIR="cmip6_data/output"
    TARGET_GRID="r144x73"

    MODELS="ACCESS-CM2 CanESM5 CNRM-CM6-1 MPI-ESM1-2-LR MRI-ESM2-0 NorESM2-LM"
    SCENARIOS="historical ssp245 ssp585"
    HIST_PERIOD="1981-2014"
    FUT_PERIOD="2081-2100"

    mkdir -p "$PROC_DIR" "$OUTPUT_DIR"
}

echo "=== CMIP6 Multi-Model Analysis ==="
config

# Step 1-3: Regrid all models
echo "[1/5] Regridding models..."
for model in $MODELS; do
    for scenario in $SCENARIOS; do
        infile="$RAW_DIR/${scenario}/${model}_${scenario}_tas_pr.nc"
        outfile="$PROC_DIR/${model}_${scenario}_regrid.nc"
        [ -f "$infile" ] || continue

        cdo -O -s -remapbil,$TARGET_GRID -selname,tas "$infile" "${outfile}_tas.nc"
        cdo -O -s -remapcon,$TARGET_GRID -selname,pr "$infile" "${outfile}_pr.nc"
        cdo -O -s -merge "${outfile}_tas.nc" "${outfile}_pr.nc" "$outfile"
        rm -f "${outfile}_tas.nc" "${outfile}_pr.nc"
    done
done

# Step 4: Select common periods
echo "[2/5] Selecting common periods..."
for model in $MODELS; do
    for scenario in historical ssp245 ssp585; do
        infile="$PROC_DIR/${model}_${scenario}_regrid.nc"
        [ -f "$infile" ] || continue

        if [ "$scenario" = "historical" ]; then
            cdo -O -s -selyear,$HIST_PERIOD "$infile" \
                "$PROC_DIR/${model}_${scenario}_${HIST_PERIOD}.nc"
        else
            cdo -O -s -selyear,$FUT_PERIOD "$infile" \
                "$PROC_DIR/${model}_${scenario}_${FUT_PERIOD}.nc"
        fi
    done
done

# Step 5: Ensemble statistics
echo "[3/5] Computing ensemble statistics..."
for scenario in $SCENARIOS; do
    period="$HIST_PERIOD"
    [ "$scenario" = "historical" ] || period="$FUT_PERIOD"

    files=$(ls "$PROC_DIR"/*_${scenario}_${period}.nc 2>/dev/null || true)
    [ -z "$files" ] && continue

    cdo -O -s -ensmean $files "$OUTPUT_DIR/ensmean_${scenario}.nc"
    cdo -O -s -ensstd  $files "$OUTPUT_DIR/ensstd_${scenario}.nc"
done

# Step 6: Future changes
echo "[4/5] Computing future changes..."
for scenario in ssp245 ssp585; do
    cdo -O -s -sub "$OUTPUT_DIR/ensmean_${scenario}.nc" \
        "$OUTPUT_DIR/ensmean_historical.nc" \
        "$OUTPUT_DIR/change_${scenario}.nc"
    cdo -O -s -div "$OUTPUT_DIR/change_${scenario}.nc" \
        "$OUTPUT_DIR/ensmean_historical.nc" \
        "$OUTPUT_DIR/rel_change_${scenario}.nc"
done

# Step 7: Summary
echo "[5/5] Summary..."
for scenario in ssp245 ssp585; do
    echo "--- $scenario ---"
    echo "Global mean change:"
    cdo -s output -fldmean -timmean "$OUTPUT_DIR/change_${scenario}.nc"
    echo "Mean temperature:"
    cdo -s output -fldmean -timmean "$OUTPUT_DIR/ensmean_${scenario}.nc"
done

echo "=== Analysis Complete ==="
```

## Expected Outputs

### 1. Multi-Model Ensemble Mean Maps
- Historical mean temperature (1981-2014)
- Future mean temperature (2081-2100, both scenarios)
- Temperature change map (future minus historical)

### 2. Model Spread / Uncertainty Maps
- Inter-model standard deviation
- Coefficient of variation
- Model min/max range

### 3. Model Agreement Maps
- Percentage of models showing warming
- Regions of consensus vs. disagreement

### 4. Time Series Plots
- Global mean temperature from all models (individual + ensemble mean)
- Scenario comparison (Historical, SSP2-4.5, SSP5-8.5)
- Uncertainty envelope (ensemble ± 1 std)

### 5. Summary Statistics Table

| Scenario | Global T change (C) | Range (C) | Model agreement (%) |
|----------|-------------------|-----------|-------------------|
| SSP2-4.5 | 2.1 | 1.5 - 2.8 | 95 |
| SSP5-8.5 | 4.3 | 3.2 - 5.6 | 99 |

## Interpretation Guidance

### What to Look For

1. **Spatial patterns of warming**: Land warms faster than ocean; high latitudes warm fastest (polar amplification)
2. **Scenario dependence**: Compare SSP2-4.5 (moderate mitigation) with SSP5-8.5 (high emissions)
3. **Model agreement**: High in tropics, lower in some regions (e.g., Amazon, Southern Ocean)
4. **Uncertainty sources**: Internal variability, model structural differences, scenario uncertainty

### Key Questions

- Where is the warming strongest? Where is it weakest?
- How much does model spread vary by region?
- Which scenario leads to 2°C vs 3°C global warming?
- How does model agreement relate to the magnitude of change?

### Common Pitfalls

```{warning}
- **Inconsistent grids**: Always verify that all models are on the same grid after regridding
- **Different calendar types**: CMIP6 models use different calendars (365_day, standard, noleap)
- **Missing variables**: Not all models provide all variables — check availability
- **Scenario availability**: Some models may only have certain scenarios
```

## Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Data management | 20% | Proper organization of multi-model, multi-scenario data |
| Regridding | 20% | Correct use of remapbil/remapcon for different variables |
| Ensemble statistics | 20% | Correct computation of mean, spread, and agreement |
| Scenario comparison | 15% | Clear comparison between different SSP scenarios |
| Visualization | 15% | Publication-quality maps and time series |
| Interpretation | 10% | Understanding of model uncertainty and agreement |

## Extension Activities

### Advanced Options

1. **Seasonal analysis**: Compute changes for DJF and JJA separately
2. **Extreme indices**: Compute ETCCDI indices for each model and analyze changes
3. **Emergent constraints**: Use present-day variability to constrain future projections
4. **Weighted ensembles**: Weight models based on historical performance

```bash
# Example: Seasonal analysis
cdo -O -seasmean -timmean "$OUTPUT_DIR/ensmean_ssp585.nc" \
    "$OUTPUT_DIR/seasonal_ssp585.nc"
cdo -O -selseas,3 "$OUTPUT_DIR/seasonal_ssp585.nc" "$OUTPUT_DIR/jja_ssp585.nc"
```

### Cross-Project Integration

- Use observed trends from **Projects 1 and 2** to evaluate CMIP6 models
- Compare CMIP6 extreme projections with **Project 4** historical extremes
- Include CMIP6 analysis in **Project 8** automated report
- Feed CMIP6 data into **Project 7** dashboard for interactive exploration

```{exercise}
Complete the multi-model analysis. Compute the ensemble mean and spread for at least 3 models under SSP2-4.5 and SSP5-8.5. Create the change maps and time series. Compare the warming in your region under both scenarios. Discuss: What is the range of uncertainty? Which regions show the highest model agreement?
```

## References

- Eyring, V., et al. (2016). Overview of the Coupled Model Intercomparison Project Phase 6. Geoscientific Model Development, 9, 1937-1958.
- IPCC (2021). Climate Change 2021: The Physical Science Basis. Cambridge University Press.
- Tebaldi, C., & Knutti, R. (2007). The use of the multi-model ensemble in probabilistic climate projections. Philosophical Transactions of the Royal Society A, 365(1857), 2053-2075.
- CDO Documentation: https://code.mpimet.mpg.de/projects/cdo
