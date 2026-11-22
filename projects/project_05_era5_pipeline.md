---
title: "Project 5: ERA5 Data Processing Pipeline"
subject: Climate Data Operators (CDO) Training
subtitle: Building an Automated Pipeline for ERA5 Climate Data Processing
---

# Project 5: ERA5 Data Processing Pipeline

## Overview

This project guides you through building a complete, automated pipeline for downloading, processing, and analyzing ERA5 reanalysis data. The pipeline handles everything from data acquisition through CDS API to final formatted climate summaries and visualizations.

```{note}
**Estimated time**: 3-4 hours
**Prerequisites**: Modules 1-11, Python with cdsapi, basic bash scripting
```

## Learning Objectives

After completing this project, you will be able to:

- Download ERA5 data programmatically using the CDS API
- Build modular CDO processing pipelines for multi-variable climate data
- Automate data processing with a single bash script
- Generate formatted climate summaries in JSON and CSV formats
- Create publication-quality visualizations from processed data
- Design a reproducible data processing workflow

## Data Requirements

### ERA5 Monthly Reanalysis Data

| Attribute | Description |
|-----------|-------------|
| **Source** | Copernicus Climate Data Store (CDS) |
| **Variables** | 2m temperature, total precipitation, sea level pressure, 10m wind components |
| **Temporal resolution** | Monthly means |
| **Spatial resolution** | 0.25 degrees (original); regrid to 1.0 degree for processing |
| **Domain** | User-specified region |
| **Access** | Requires free registration at https://cds.climate.copernicus.eu |

### CDS API Setup

```bash
# Install the CDS API client
pip install cdsapi

# Create ~/.cdsapirc with your CDS API key
cat > ~/.cdsapirc << EOF
url: https://cds.climate.copernicus.eu/api/v2
key: <your_uid>:<your_api_key>
EOF
```

```{note}
If you don't have CDS API access, use the real reanalysis field bundled with this course (`../datasets/tas_sample.nc`) to practise the same CDO pipeline operations.
```

## Step-by-Step Workflow

### Step 1: Data Download

#### Python Download Script

Save as `download_era5.py`:

```python
#!/usr/bin/env python3
"""
ERA5 monthly data download script.
Downloads multiple variables for a specified region and period.
"""
import cdsapi
import os
from pathlib import Path

# Configuration
YEARS = [str(y) for y in range(1981, 2021)]
MONTHS = [f"{m:02d}" for m in range(1, 13)]
REGION = [70, -10, 30, 40]  # [N, W, S, E] - Europe
OUTPUT_DIR = "data/raw"

Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)

# Variables to download (ERA5 monthly means - single levels)
DATASET = "reanalysis-era5-single-levels-monthly-means"

variable_configs = [
    {
        "variable": "2m_temperature",
        "filename": "era5_t2m.nc"
    },
    {
        "variable": "total_precipitation",
        "filename": "era5_tp.nc"
    },
    {
        "variable": "mean_sea_level_pressure",
        "filename": "era5_msl.nc"
    },
    {
        "variable": "10m_u_component_of_wind",
        "filename": "era5_u10.nc"
    },
    {
        "variable": "10m_v_component_of_wind",
        "filename": "era5_v10.nc"
    },
    {
        "variable": "2m_dewpoint_temperature",
        "filename": "era5_d2m.nc"
    }
]

c = cdsapi.Client()

for config in variable_configs:
    print(f"Downloading {config['variable']}...")
    output_path = os.path.join(OUTPUT_DIR, config["filename"])

    if os.path.exists(output_path):
        print(f"  File exists, skipping: {output_path}")
        continue

    try:
        c.retrieve(
            DATASET,
            {
                "product_type": "monthly_averaged_reanalysis",
                "variable": config["variable"],
                "year": YEARS,
                "month": MONTHS,
                "time": "00:00",
                "format": "netcdf",
                "area": REGION,
            },
            output_path
        )
        print(f"  Downloaded: {output_path}")
    except Exception as e:
        print(f"  ERROR downloading {config['variable']}: {e}")

print("Download complete!")
```

#### Real Data Alternative (Bundled Reanalysis)

If CDS API is unavailable, use the real NCEP/DOE Reanalysis-2 monthly temperature field supplied with this course. It is already a monthly gridded field on a regular latitude-longitude grid.

```python
#!/usr/bin/env python3
"""Prepare the real reanalysis field supplied with the course for the CDO pipeline."""
import xarray as xr
from pathlib import Path

output_dir = Path("data/raw")
output_dir.mkdir(parents=True, exist_ok=True)

# Real NCEP/DOE Reanalysis-2 monthly temperature (K), 1980-2010
ds = xr.open_dataset("../datasets/tas_sample.nc")
ds.to_netcdf(output_dir / "era5_t2m.nc")

print(f"Real reanalysis prepared: {output_dir / 'era5_t2m.nc'}")
print(f"  Dimensions: {dict(ds.sizes)}")
print(f"  Variables: {list(ds.data_vars)}")
```

### Step 2: Data Inspection

```bash
# Inspect downloaded data
cdo sinfo data/raw/era5_t2m.nc
cdo griddes data/raw/era5_t2m.nc

# Check all variables
for f in data/raw/era5_*.nc; do
    echo "=== $(basename $f) ==="
    cdo vardes "$f"
    cdo showyear "$f"
done

# Quick statistics
for var in t2m tp msl u10 v10; do
    echo "--- $var ---"
    cdo info data/raw/era5_${var}.nc | tail -2
done
```

### Step 3: Processing Pipeline

#### Main Processing Script

Save as `process_era5.sh`:

```bash
#!/bin/bash
# =============================================================================
# ERA5 Data Processing Pipeline
# Climate Data Operators (CDO) Training
# =============================================================================
set -euo pipefail

# Configuration
INPUT_DIR="data/raw"
OUTPUT_DIR="data/processed"
REPORT_DIR="report"
TARGET_GRID="r360x180"
REF_START=1981
REF_END=2010
NTHREADS=4

export CDO_NTHREADS=$NTHREADS

mkdir -p "$OUTPUT_DIR"
mkdir -p "$REPORT_DIR"

echo "========================================="
echo "ERA5 Data Processing Pipeline"
echo "========================================="
echo "Input:  $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo "Grid:   $TARGET_GRID"
echo "========================================="

# Step 1: Regrid all variables to common grid
echo "[1/6] Regridding to common grid..."

for var in t2m tp msl u10 v10 d2m; do
    infile="$INPUT_DIR/era5_${var}.nc"
    if [ ! -f "$infile" ]; then
        echo "  WARNING: $infile not found, skipping"
        continue
    fi
    echo "  Regridding $var..."
    cdo -O -s -remapbil,$TARGET_GRID "$infile" "$OUTPUT_DIR/regrid_${var}.nc"
done

# Step 2: Compute climatology
echo "[2/6] Computing monthly climatology..."

for var in t2m tp msl u10 v10 d2m; do
    infile="$OUTPUT_DIR/regrid_${var}.nc"
    if [ ! -f "$infile" ]; then continue; fi

    # Select reference period
    cdo -O -s -selyear,${REF_START}/${REF_END} "$infile" \
        "$OUTPUT_DIR/ref_${var}.nc"

    # Monthly mean climatology
    cdo -O -s -ymonmean "$OUTPUT_DIR/ref_${var}.nc" \
        "$OUTPUT_DIR/clim_${var}.nc"
done

# Step 3: Compute anomalies
echo "[3/6] Computing anomalies..."

for var in t2m tp msl u10 v10 d2m; do
    infile="$OUTPUT_DIR/regrid_${var}.nc"
    if [ ! -f "$infile" ]; then continue; fi

    cdo -O -s -ymonsub "$infile" "$OUTPUT_DIR/clim_${var}.nc" \
        "$OUTPUT_DIR/anom_${var}.nc"
done

# Step 4: Compute spatial statistics
echo "[4/6] Computing spatial statistics..."

for var in t2m tp msl u10 v10 d2m; do
    infile="$OUTPUT_DIR/regrid_${var}.nc"
    if [ ! -f "$infile" ]; then continue; fi

    # Global mean time series
    cdo -O -s -fldmean "$infile" "$OUTPUT_DIR/mean_${var}.nc"

    # Global mean anomaly
    cdo -O -s -fldmean "$OUTPUT_DIR/anom_${var}.nc" \
        "$OUTPUT_DIR/mean_anom_${var}.nc"

    # Global standard deviation
    cdo -O -s -fldstd "$infile" "$OUTPUT_DIR/std_${var}.nc"
done

# Step 5: Compute derived variables
echo "[5/6] Computing derived variables..."

# Wind speed from u10 and v10
if [ -f "$OUTPUT_DIR/regrid_u10.nc" ] && [ -f "$OUTPUT_DIR/regrid_v10.nc" ]; then
    cdo -O -s -expr,'ws10=sqrt(u10*u10+v10*v10)' \
        -merge "$OUTPUT_DIR/regrid_u10.nc" "$OUTPUT_DIR/regrid_v10.nc" \
        "$OUTPUT_DIR/regrid_ws10.nc"
    cdo -O -s -fldmean "$OUTPUT_DIR/regrid_ws10.nc" "$OUTPUT_DIR/mean_ws10.nc"
fi

# Temperature in Celsius
if [ -f "$OUTPUT_DIR/regrid_t2m.nc" ]; then
    cdo -O -s -expr,'t2m_c=t2m-273.15' "$OUTPUT_DIR/regrid_t2m.nc" \
        "$OUTPUT_DIR/regrid_t2m_c.nc"
    cdo -O -s -fldmean "$OUTPUT_DIR/regrid_t2m_c.nc" \
        "$OUTPUT_DIR/mean_t2m_c.nc"
    cdo -O -s -ymonmean "$OUTPUT_DIR/regrid_t2m_c.nc" \
        "$OUTPUT_DIR/clim_t2m_c.nc"
fi

# Precipitation in mm/month (from m/month)
if [ -f "$OUTPUT_DIR/regrid_tp.nc" ]; then
    cdo -O -s -mulc,1000 "$OUTPUT_DIR/regrid_tp.nc" \
        "$OUTPUT_DIR/regrid_tp_mm.nc"
    cdo -O -s -fldmean "$OUTPUT_DIR/regrid_tp_mm.nc" \
        "$OUTPUT_DIR/mean_tp_mm.nc"
    cdo -O -s -ymonsum "$OUTPUT_DIR/regrid_tp_mm.nc" \
        "$OUTPUT_DIR/clim_tp_mm.nc"
fi

# Step 6: Export summary
echo "[6/6] Exporting summary data..."

# Temperature time series
cdo -s output "$OUTPUT_DIR/mean_t2m_c.nc" > "$REPORT_DIR/temperature_timeseries.csv"
cdo -s output "$OUTPUT_DIR/mean_anom_t2m.nc" > "$REPORT_DIR/temperature_anomaly.csv"

# Precipitation time series
cdo -s output "$OUTPUT_DIR/mean_tp_mm.nc" > "$REPORT_DIR/precipitation_timeseries.csv"

# Wind speed time series
cdo -s output "$OUTPUT_DIR/mean_ws10.nc" > "$REPORT_DIR/windspeed_timeseries.csv"

# Climatology for each variable
cdo -s output "$OUTPUT_DIR/clim_t2m_c.nc" > "$REPORT_DIR/temperature_climatology.csv"
cdo -s output "$OUTPUT_DIR/clim_tp_mm.nc" > "$REPORT_DIR/precipitation_climatology.csv"

echo "========================================="
echo "Pipeline Complete!"
echo "========================================="
echo "Processed data: $OUTPUT_DIR"
echo "Reports:        $REPORT_DIR"
echo "========================================="
```

### Step 4: Climate Summary Generation

#### Python Summary Script

Save as `generate_summary.py`:

```python
#!/usr/bin/env python3
"""
Generate climate summary statistics from processed ERA5 data.
"""
import json
import csv
import subprocess
import numpy as np
from pathlib import Path

report_dir = Path("report")
report_dir.mkdir(exist_ok=True)

def run_cdo(expression: str) -> str:
    """Run a CDO command and return stdout."""
    result = subprocess.run(
        expression.split(),
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"CDO error: {result.stderr}")
    return result.stdout.strip()

def compute_statistics():
    """Compute summary statistics for all variables."""
    stats = {}

    # Temperature (Celsius)
    try:
        data = np.loadtxt(report_dir / "temperature_timeseries.csv")
        stats["temperature"] = {
            "mean": float(np.mean(data)),
            "min": float(np.min(data)),
            "max": float(np.max(data)),
            "std": float(np.std(data)),
            "trend": float(np.polyfit(range(len(data)), data, 1)[0]) * 120,  # C/decade
            "warmest_year": int(np.argmax(data)),
            "coolest_year": int(np.argmin(data)),
        }
    except Exception as e:
        print(f"Warning: Could not compute temperature stats: {e}")

    # Precipitation (mm/month)
    try:
        data = np.loadtxt(report_dir / "precipitation_timeseries.csv")
        stats["precipitation"] = {
            "mean_monthly": float(np.mean(data)),
            "annual_total": float(np.mean(data)) * 12,
            "min_monthly": float(np.min(data)),
            "max_monthly": float(np.max(data)),
            "std": float(np.std(data)),
        }
    except Exception as e:
        print(f"Warning: Could not compute precipitation stats: {e}")

    # Wind speed
    try:
        data = np.loadtxt(report_dir / "windspeed_timeseries.csv")
        stats["wind_speed"] = {
            "mean": float(np.mean(data)),
            "max": float(np.max(data)),
            "std": float(np.std(data)),
        }
    except Exception as e:
        print(f"Warning: Could not compute wind stats: {e}")

    # Temperature anomaly
    try:
        data = np.loadtxt(report_dir / "temperature_anomaly.csv")
        stats["temperature_anomaly"] = {
            "mean_anomaly": float(np.mean(data)),
            "max_positive_anomaly": float(np.max(data)),
            "max_negative_anomaly": float(np.min(data)),
            "recent_decade_mean": float(np.mean(data[-120:])),
        }
    except Exception as e:
        print(f"Warning: Could not compute anomaly stats: {e}")

    return stats

def generate_json_summary(stats: dict):
    """Generate JSON summary file."""
    summary = {
        "project": "ERA5 Data Processing Pipeline",
        "period": "1981-2020",
        "region": "Europe (30N-70N, 10W-40E)",
        "data_source": "ERA5 Monthly Reanalysis",
        "statistics": stats,
        "processing_date": str(np.datetime64("now")),
    }

    output_path = report_dir / "climate_summary.json"
    with open(output_path, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"Summary saved: {output_path}")

def generate_csv_tables():
    """Generate formatted CSV tables."""
    # Seasonal means table
    seasons = {
        "DJF": [12, 1, 2],
        "MAM": [3, 4, 5],
        "JJA": [6, 7, 8],
        "SON": [9, 10, 11],
    }

    # Temperature climatology
    try:
        clim_data = np.loadtxt(report_dir / "temperature_climatology.csv")
        with open(report_dir / "seasonal_temperature.csv", "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["Season", "Mean_Temp_C", "Min_Temp_C", "Max_Temp_C"])
            for season, months in seasons.items():
                indices = [m - 1 for m in months]
                vals = clim_data[indices]
                writer.writerow([
                    season,
                    f"{np.mean(vals):.1f}",
                    f"{np.min(vals):.1f}",
                    f"{np.max(vals):.1f}",
                ])
        print("Saved: seasonal_temperature.csv")
    except Exception as e:
        print(f"Warning: Could not generate seasonal table: {e}")

    # Precipitation climatology
    try:
        clim_precip = np.loadtxt(report_dir / "precipitation_climatology.csv")
        with open(report_dir / "seasonal_precipitation.csv", "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["Season", "Total_Precip_mm", "Min_Monthly_mm", "Max_Monthly_mm"])
            for season, months in seasons.items():
                indices = [m - 1 for m in months]
                vals = clim_precip[indices]
                writer.writerow([
                    season,
                    f"{np.sum(vals):.0f}",
                    f"{np.min(vals):.1f}",
                    f"{np.max(vals):.1f}",
                ])
        print("Saved: seasonal_precipitation.csv")
    except Exception as e:
        print(f"Warning: Could not generate precipitation table: {e}")

def print_summary_report(stats: dict):
    """Print formatted summary to console."""
    print("\n" + "=" * 60)
    print("CLIMATE SUMMARY REPORT")
    print("=" * 60)
    print(f"Period: 1981-2020")
    print(f"Region: Europe (30N-70N)")
    print("-" * 60)

    if "temperature" in stats:
        t = stats["temperature"]
        print(f"Temperature:")
        print(f"  Mean:         {t['mean']:.1f} C")
        print(f"  Range:        {t['min']:.1f} to {t['max']:.1f} C")
        print(f"  Std Dev:      {t['std']:.2f} C")
        print(f"  Trend:        {t['trend']:.3f} C/decade")
        print(f"  Warmest year: {t['warmest_year']}")
        print(f"  Coolest year: {t['coolest_year']}")

    if "precipitation" in stats:
        p = stats["precipitation"]
        print(f"\nPrecipitation:")
        print(f"  Mean monthly: {p['mean_monthly']:.1f} mm")
        print(f"  Annual total: {p['annual_total']:.0f} mm/yr")
        print(f"  Range:        {p['min_monthly']:.1f} to {p['max_monthly']:.1f} mm")
        print(f"  Std Dev:      {p['std']:.1f} mm")

    if "wind_speed" in stats:
        w = stats["wind_speed"]
        print(f"\nWind Speed (10m):")
        print(f"  Mean:         {w['mean']:.2f} m/s")
        print(f"  Max:          {w['max']:.2f} m/s")

    if "temperature_anomaly" in stats:
        a = stats["temperature_anomaly"]
        print(f"\nTemperature Anomaly:")
        print(f"  Mean anomaly:       {a['mean_anomaly']:.3f} K")
        print(f"  Max positive:       {a['max_positive_anomaly']:.2f} K")
        print(f"  Max negative:       {a['max_negative_anomaly']:.2f} K")
        print(f"  Recent decade mean: {a['recent_decade_mean']:.3f} K")

    print("=" * 60)

if __name__ == "__main__":
    stats = compute_statistics()
    generate_json_summary(stats)
    generate_csv_tables()
    print_summary_report(stats)
```

### Step 5: Visualization

Save as `create_visualizations.py`:

```python
#!/usr/bin/env python3
"""
Generate visualizations from processed ERA5 data.
"""
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pathlib import Path

report_dir = Path("report")
figures_dir = report_dir / "figures"
figures_dir.mkdir(exist_ok=True)

plt.style.use("seaborn-v0_8-darkgrid")

def plot_temperature_timeseries():
    """Temperature time series with trend."""
    data = np.loadtxt(report_dir / "temperature_timeseries.csv")
    years = np.arange(1981, 2021)
    months = np.arange(len(data))

    # Monthly time series
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 8))

    # Monthly values
    ax1.plot(months / 12 + 1981, data, "b-", linewidth=0.5, alpha=0.5)
    ax1.set_ylabel("Temperature (C)")
    ax1.set_title("Monthly Mean Temperature over Europe")
    ax1.grid(alpha=0.3)

    # Annual means
    annual = data.reshape(-1, 12).mean(axis=1)
    slope, intercept = np.polyfit(years, annual, 1)
    trend_line = slope * years + intercept

    ax2.bar(years, annual, color="steelblue", alpha=0.7, width=0.8)
    ax2.plot(years, trend_line, "r-", linewidth=2,
             label=f"Trend: {slope*10:.2f}C/decade")
    ax2.set_xlabel("Year")
    ax2.set_ylabel("Temperature (C)")
    ax2.set_title("Annual Mean Temperature with Trend")
    ax2.legend()
    ax2.grid(alpha=0.3)

    plt.tight_layout()
    path = figures_dir / "temperature_timeseries.png"
    plt.savefig(path, dpi=200, bbox_inches="tight")
    print(f"Saved: {path}")
    plt.close()

def plot_precipitation_timeseries():
    """Precipitation time series."""
    data = np.loadtxt(report_dir / "precipitation_timeseries.csv")
    years = np.arange(1981, 2021)
    annual = data.reshape(-1, 12).sum(axis=1)

    fig, ax = plt.subplots(figsize=(14, 5))
    ax.bar(years, annual, color="forestgreen", alpha=0.7, width=0.8)

    slope, intercept = np.polyfit(years, annual, 1)
    trend_line = slope * years + intercept
    ax.plot(years, trend_line, "r-", linewidth=2,
            label=f"Trend: {slope*10:.1f} mm/decade")

    ax.axhline(annual.mean(), color="gray", linestyle="--",
               label=f"Mean: {annual.mean():.0f} mm/yr")
    ax.set_xlabel("Year")
    ax.set_ylabel("Annual Precipitation (mm)")
    ax.set_title("Annual Total Precipitation over Europe")
    ax.legend()
    ax.grid(alpha=0.3)

    plt.tight_layout()
    path = figures_dir / "precipitation_timeseries.png"
    plt.savefig(path, dpi=200, bbox_inches="tight")
    print(f"Saved: {path}")
    plt.close()

def plot_seasonal_cycle():
    """Seasonal cycle plot."""
    temp_clim = np.loadtxt(report_dir / "temperature_climatology.csv")
    precip_clim = np.loadtxt(report_dir / "precipitation_climatology.csv")

    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))

    # Temperature
    ax1.plot(months, temp_clim, "o-", color="crimson", linewidth=2, markersize=6)
    ax1.fill_between(range(12), temp_clim, alpha=0.2, color="crimson")
    ax1.set_ylabel("Temperature (C)")
    ax1.set_title("Monthly Temperature Climatology")
    ax1.grid(alpha=0.3)

    # Precipitation
    ax2.bar(months, precip_clim, color="steelblue", alpha=0.7, edgecolor="navy")
    ax2.set_ylabel("Precipitation (mm/month)")
    ax2.set_title("Monthly Precipitation Climatology")
    ax2.grid(alpha=0.3, axis="y")

    plt.tight_layout()
    path = figures_dir / "seasonal_cycle.png"
    plt.savefig(path, dpi=200, bbox_inches="tight")
    print(f"Saved: {path}")
    plt.close()

def plot_temperature_anomaly():
    """Temperature anomaly bar chart."""
    data = np.loadtxt(report_dir / "temperature_anomaly.csv")
    years = np.arange(1981, 2021)
    annual = data.reshape(-1, 12).mean(axis=1)

    fig, ax = plt.subplots(figsize=(14, 5))
    colors = ["crimson" if v > 0 else "steelblue" for v in annual]
    ax.bar(years, annual, color=colors, alpha=0.7, width=0.8)
    ax.axhline(0, color="black", linewidth=0.5)

    slope, intercept = np.polyfit(years, annual, 1)
    trend_line = slope * years + intercept
    ax.plot(years, trend_line, "r-", linewidth=2,
            label=f"Trend: {slope*10:.2f}C/decade")

    ax.set_xlabel("Year")
    ax.set_ylabel("Temperature Anomaly (K)")
    ax.set_title("Temperature Anomaly (ref: 1981-2010)")
    ax.legend()
    ax.grid(alpha=0.3)

    plt.tight_layout()
    path = figures_dir / "temperature_anomaly.png"
    plt.savefig(path, dpi=200, bbox_inches="tight")
    print(f"Saved: {path}")
    plt.close()

def plot_multipanel():
    """Multi-panel summary figure."""
    temp = np.loadtxt(report_dir / "temperature_timeseries.csv")
    precip = np.loadtxt(report_dir / "precipitation_timeseries.csv")
    temp_clim = np.loadtxt(report_dir / "temperature_climatology.csv")
    precip_clim = np.loadtxt(report_dir / "precipitation_climatology.csv")
    anomaly = np.loadtxt(report_dir / "temperature_anomaly.csv")

    years = np.arange(1981, 2021)
    annual_temp = temp.reshape(-1, 12).mean(axis=1)
    annual_precip = precip.reshape(-1, 12).sum(axis=1)
    annual_anom = anomaly.reshape(-1, 12).mean(axis=1)
    months = np.arange(12)

    fig = plt.figure(figsize=(16, 12))

    # 1. Temperature time series
    ax1 = fig.add_subplot(3, 3, 1)
    ax1.plot(years, annual_temp, "b-", linewidth=1.5)
    slope = np.polyfit(years, annual_temp, 1)[0]
    ax1.plot(years, np.polyval(np.polyfit(years, annual_temp, 1), years),
             "r--", label=f"{slope*10:.2f}C/dec")
    ax1.set_title("Annual Temperature")
    ax1.legend(fontsize=8)
    ax1.grid(alpha=0.3)

    # 2. Precipitation time series
    ax2 = fig.add_subplot(3, 3, 2)
    ax2.bar(years, annual_precip, color="forestgreen", alpha=0.6)
    ax2.set_title("Annual Precipitation")

    # 3. Temperature anomaly
    ax3 = fig.add_subplot(3, 3, 3)
    colors = ["crimson" if v > 0 else "steelblue" for v in annual_anom]
    ax3.bar(years, annual_anom, color=colors, alpha=0.7)
    ax3.axhline(0, color="black", linewidth=0.5)
    ax3.set_title("Temperature Anomaly")

    # 4. Temperature seasonal cycle
    ax4 = fig.add_subplot(3, 3, 4)
    ax4.plot(months, temp_clim, "o-", color="crimson")
    ax4.set_title("Temperature Climatology")
    ax4.set_xticks(range(12))
    ax4.set_xticklabels(["J","F","M","A","M","J","J","A","S","O","N","D"], fontsize=7)

    # 5. Precipitation seasonal cycle
    ax5 = fig.add_subplot(3, 3, 5)
    ax5.bar(months, precip_clim, color="steelblue", alpha=0.7)
    ax5.set_title("Precipitation Climatology")
    ax5.set_xticks(range(12))
    ax5.set_xticklabels(["J","F","M","A","M","J","J","A","S","O","N","D"], fontsize=7)

    # 6. Temperature histogram
    ax6 = fig.add_subplot(3, 3, 6)
    ax6.hist(temp, bins=50, color="crimson", alpha=0.7, edgecolor="white")
    ax6.set_title(f"Temperature Distribution\nMean: {temp.mean():.1f}C")

    # 7. Temperature vs precipitation scatter
    ax7 = fig.add_subplot(3, 3, 7)
    ax7.scatter(annual_temp, annual_precip, c=years, cmap="viridis",
                alpha=0.7, s=30)
    ax7.set_xlabel("Annual Temperature (C)")
    ax7.set_ylabel("Annual Precip (mm)")
    ax7.set_title("Temperature vs Precipitation")
    cbar = plt.colorbar(ax7.collections[0], ax=ax7)
    cbar.set_label("Year")

    # 8-9. Decadal means
    ax8 = fig.add_subplot(3, 3, 8)
    decades = ["1981-1990", "1991-2000", "2001-2010", "2011-2020"]
    decadal_temp = [annual_temp[i*10:(i+1)*10].mean() for i in range(4)]
    ax8.bar(decades, decadal_temp, color="steelblue", alpha=0.7)
    ax8.set_title("Decadal Mean Temperature")
    ax8.tick_params(axis="x", rotation=45)

    ax9 = fig.add_subplot(3, 3, 9)
    decadal_precip = [annual_precip[i*10:(i+1)*10].mean() for i in range(4)]
    ax9.bar(decades, decadal_precip, color="forestgreen", alpha=0.7)
    ax9.set_title("Decadal Mean Precipitation")
    ax9.tick_params(axis="x", rotation=45)

    plt.suptitle("ERA5 Climate Data Summary - Europe (1981-2020)",
                 fontsize=16, fontweight="bold", y=1.01)
    plt.tight_layout()
    path = figures_dir / "multipanel_summary.png"
    plt.savefig(path, dpi=200, bbox_inches="tight")
    print(f"Saved: {path}")
    plt.close()

if __name__ == "__main__":
    plot_temperature_timeseries()
    plot_precipitation_timeseries()
    plot_seasonal_cycle()
    plot_temperature_anomaly()
    plot_multipanel()
    print("All visualizations generated!")
```

### Step 6: Master Pipeline Script

Save as `run_era5_pipeline.sh` — this orchestrates everything:

```bash
#!/bin/bash
# =============================================================================
# ERA5 Master Pipeline
# Climate Data Operators (CDO) Training
#
# Usage:
#   ./run_era5_pipeline.sh              # Run complete pipeline
#   ./run_era5_pipeline.sh download     # Download only
#   ./run_era5_pipeline.sh process      # Process only
#   ./run_era5_pipeline.sh visualize    # Visualize only
# =============================================================================
set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR"

# Configuration
DATA_DIR="data"
REPORT_DIR="report"
LOG_FILE="pipeline_$(date +%Y%m%d_%H%M%S).log"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== ERA5 Pipeline Started ==="

# Step 1: Download
if [ $# -eq 0 ] || [ "$1" = "download" ]; then
    log "STEP 1: Downloading ERA5 data..."
    if [ -f "$DATA_DIR/raw/era5_t2m.nc" ]; then
        log "  Data exists, skipping download. Use 'download' argument to force."
    else
        python download_era5.py 2>&1 | tee -a "$LOG_FILE"
        log "  Download complete."
    fi
fi

# Step 2: Process
if [ $# -eq 0 ] || [ "$1" = "process" ]; then
    log "STEP 2: Processing ERA5 data..."
    bash process_era5.sh 2>&1 | tee -a "$LOG_FILE"
    log "  Processing complete."
fi

# Step 3: Generate summaries
if [ $# -eq 0 ] || [ "$1" = "summarize" ]; then
    log "STEP 3: Generating summaries..."
    python generate_summary.py 2>&1 | tee -a "$LOG_FILE"
    log "  Summaries complete."
fi

# Step 4: Visualize
if [ $# -eq 0 ] || [ "$1" = "visualize" ]; then
    log "STEP 4: Creating visualizations..."
    python create_visualizations.py 2>&1 | tee -a "$LOG_FILE"
    log "  Visualizations complete."
fi

# Generate HTML report
if [ $# -eq 0 ] || [ "$1" = "report" ]; then
    log "STEP 5: Generating HTML report..."
    python generate_html_report.py 2>&1 || true
    log "  Report generation complete."
fi

log "=== ERA5 Pipeline Complete ==="
log "Output directory: $REPORT_DIR"
log "Log file: $LOG_FILE"
echo ""
echo "Summary of outputs:"
echo "  Processed data: $DATA_DIR/processed/"
echo "  Figures:        $REPORT_DIR/figures/"
echo "  Summary JSON:   $REPORT_DIR/climate_summary.json"
echo "  Summary CSV:    $REPORT_DIR/*.csv"
echo "  Log file:       $LOG_FILE"
```

## Expected Outputs

### 1. Processed Datasets
- Regridded NetCDF files for each variable
- Monthly climatology files
- Anomaly files
- Derived variables (wind speed, temperature in Celsius)

### 2. Summary Tables

**Seasonal Temperature (C)**

| Season | Mean | Min | Max |
|--------|------|-----|-----|
| DJF | 2.3 | -0.5 | 5.1 |
| MAM | 8.7 | 6.2 | 11.3 |
| JJA | 16.8 | 14.1 | 19.5 |
| SON | 10.2 | 7.8 | 12.6 |

**Seasonal Precipitation (mm)**

| Season | Total | Min Monthly | Max Monthly |
|--------|-------|-------------|-------------|
| DJF | 180 | 45 | 75 |
| MAM | 195 | 55 | 80 |
| JJA | 210 | 60 | 85 |
| SON | 200 | 50 | 78 |

### 3. Visualizations

- Temperature time series (monthly + annual with trend)
- Precipitation time series with trend
- Seasonal cycle plots for temperature and precipitation
- Temperature anomaly bar chart
- Multi-panel summary figure (9 panels)

### 4. Climate Summary JSON

```json
{
  "project": "ERA5 Data Processing Pipeline",
  "period": "1981-2020",
  "statistics": {
    "temperature": {
      "mean": 9.45,
      "trend": 0.35
    },
    "precipitation": {
      "annual_total": 785.0
    }
  }
}
```

## Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Pipeline design | 20% | Logical workflow organization, modularity |
| CDO operators | 20% | Appropriate use of regridding, temporal statistics, derived variables |
| Automation | 20% | Single-command execution, error handling, logging |
| Data products | 15% | Quality of processed datasets and summary tables |
| Visualizations | 15% | Clarity, completeness, and formatting of figures |
| Documentation | 10% | Code comments, README, reproducibility |

## Extension Activities

### Advanced Options

1. **Pressure level data**: Extend the pipeline to include ERA5 pressure level variables (geopotential, specific humidity, temperature at 500 hPa, 850 hPa)
2. **Trend analysis**: Add automated trend computation for all variables
3. **Multi-region support**: Process multiple regions in parallel
4. **Climate indices**: Automatically compute climate indices (NAO, ENSO teleconnections)
5. **PDF report**: Generate a complete PDF report using LaTeX or Matplotlib

```bash
# Example: Add trend analysis to pipeline
cdo -O -trend "$OUTPUT_DIR/mean_t2m.nc" "$OUTPUT_DIR/trend_intercept.nc" "$OUTPUT_DIR/trend_slope.nc"
```

### Cross-Project Integration

- Use processed ERA5 data in **Project 1** (Rainfall Trend) and **Project 2** (Temperature Trend)
- Feed ERA5 extremes data into **Project 4** (Climate Extremes)
- Use data in **Project 7** (Climate Dashboard) and **Project 8** (Automated Report)

```{exercise}
Complete the ERA5 processing pipeline. Run the full pipeline from download to visualization. Verify that all outputs are generated correctly. Modify the configuration for a different region and time period. Document the resources required (disk space, time, memory).
```

## References

- Hersbach, H., et al. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999-2049.
- Copernicus Climate Data Store: https://cds.climate.copernicus.eu
- CDS API documentation: https://cds.climate.copernicus.eu/api-how-to
- CDO Documentation: https://code.mpimet.mpg.de/projects/cdo
