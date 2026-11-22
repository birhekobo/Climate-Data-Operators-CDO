---
title: "Project 2: Temperature Trend Mapping"
subject: Climate Data Operators (CDO) Training
subtitle: Mapping Surface Temperature Trends Across Africa Using ERA5 Data
---

# Project 2: Temperature Trend Mapping

## Overview

This project focuses on analyzing surface temperature trends across Africa using ERA5 monthly reanalysis data. You will compute annual and seasonal means, calculate temperature anomalies, perform grid-cell trend analysis, and create spatial trend maps.

```{note}
**Estimated time**: 3-4 hours
**Prerequisites**: Modules 1-8 (CDO basics, temporal operators, statistics, spatial operations)
```

## Learning Objectives

After completing this project, you will be able to:

- Process ERA5 monthly temperature data with CDO
- Compute annual and seasonal temperature means
- Calculate temperature anomalies relative to a reference period
- Perform per-grid-cell linear trend analysis
- Create publication-quality trend maps for multiple seasons
- Identify regions of rapid warming (hotspots) and cooling
- Compare seasonal warming rates across the continent

## Data Requirements

### Primary Dataset: ERA5 Monthly 2m Temperature

| Attribute | Description |
|-----------|-------------|
| **Variable** | 2m temperature (t2m) in Kelvin |
| **Spatial resolution** | 0.25 degrees (~28 km) |
| **Temporal coverage** | 1940 - present |
| **Temporal resolution** | Monthly |
| **Domain** | Global |
| **Source** | Copernicus Climate Data Store |

### Alternative: CRU TS Monthly Temperature

| Attribute | Description |
|-----------|-------------|
| **Variable** | Mean temperature (tmp) in Celsius |
| **Spatial resolution** | 0.5 degrees |
| **Temporal coverage** | 1901 - 2020 |
| **Source** | https://crudata.uea.ac.uk/cru/data/hrg/ |

### Real Sample Data

This course ships with real reanalysis temperature fields. Use them directly:

```bash
# Inspect the real temperature reanalysis supplied with the course
cdo sinfo ../datasets/tas_sample.nc
cdo griddes ../datasets/tas_sample.nc

# Prepare a regional subset for the trend analysis
cdo sellonlatbox,-20,50,-35,40 ../datasets/tas_sample.nc tas_africa.nc
```

```{note}
All figures and results in this project are produced from real NCEP/DOE Reanalysis-2 data. For other regions, obtain real ERA5 or CRU temperature data from the providers listed above.
```

## Step-by-Step Workflow

### Step 1: Data Inspection

```bash
# Inspect the ERA5 temperature file
cdo sinfo era5_t2m_monthly.nc

# Variable details
cdo vardes era5_t2m_monthly.nc

# Time coverage
cdo showyear era5_t2m_monthly.nc
cdo ntime era5_t2m_monthly.nc

# Grid description
cdo griddes era5_t2m_monthly.nc

# Quick statistics
cdo info era5_t2m_monthly.nc
```

Expected `cdo sinfo` output:

```
   File format: NetCDF
    -1 : Institut Source   T Steptype Levels Num    Points Num Dtype : Parameter name
     1 : unknown  unknown  v instant     1   1  ? 10382400  F32  : t2m
   Grid coordinates:
     1 : lonlat                     : points=10382400 (2880x3605)
                        lon : -179.875 to 179.875 degrees east
                        lat : -90.125 to 90.125 degrees north
   Time coordinate : 480 steps
   RefTime = 1981-01-01
```

### Step 2: Crop to Africa Region

Africa spans approximately from 35S to 40N latitude and -20W to 55E longitude.

```bash
# Define Africa bounding box
cdo -O sellonlatbox,-20,55,-35,40 era5_t2m_monthly.nc africa_t2m.nc

# Verify subset
cdo griddes africa_t2m.nc
cdo sinfo africa_t2m.nc
cdo output -fldmean -timmean africa_t2m.nc
```

### Step 3: Convert Temperature Units

ERA5 temperature is in Kelvin. Convert to Celsius for analysis:

```bash
# Convert K to Celsius (subtract 273.15)
cdo -O expr,'t2m_c=t2m-273.15' africa_t2m.nc africa_t2m_c.nc

# Verify conversion
cdo output -fldmean -timmean africa_t2m_c.nc

# Keep both units if needed
cdo -O expr,'t2m_k=t2m; t2m_c=t2m-273.15' africa_t2m.nc africa_t2m_dual.nc
```

```{tip}
Always document your unit conversions. For trend analysis, the units affect the interpretation of the slope.
```

### Step 4: Compute Annual and Seasonal Means

```bash
# Annual mean temperature
cdo -O yearmean africa_t2m_c.nc annual_t2m.nc

# Seasonal means
cdo -O seasmean africa_t2m_c.nc seasonal_t2m.nc

# Extract specific seasons
cdo -O selseas,1 seasonal_t2m.nc djf_t2m.nc   # Dec-Feb (Winter)
cdo -O selseas,2 seasonal_t2m.nc mam_t2m.nc    # Mar-May (Spring)
cdo -O selseas,3 seasonal_t2m.nc jja_t2m.nc    # Jun-Aug (Summer)
cdo -O selseas,4 seasonal_t2m.nc son_t2m.nc    # Sep-Nov (Fall)

# Alternative: select by months for custom seasons
cdo -O timmean -selmonth,12,1,2 africa_t2m_c.nc djf_alt.nc
cdo -O timmean -selmonth,6,7,8 africa_t2m_c.nc jja_alt.nc
```

### Step 5: Calculate Climatology and Anomalies

```bash
# Reference period: 1981-2010 (WMO standard)
cdo -O selyear,1981/2010 africa_t2m_c.nc ref_period.nc

# Monthly climatology
cdo -O ymonmean ref_period.nc clim_monthly.nc

# Annual climatology
cdo -O yearmean ref_period.nc clim_annual.nc

# Monthly anomalies
cdo -O ymonsub africa_t2m_c.nc clim_monthly.nc t2m_anom_monthly.nc

# Annual anomalies
cdo -O yearmean t2m_anom_monthly.nc t2m_anom_annual.nc

# Regional average anomaly time series
cdo -O fldmean t2m_anom_annual.nc africa_anom_ts.nc
cdo output africa_anom_ts.nc > africa_temp_anomaly.csv
```

### Step 6: Trend Analysis

#### Per-Grid-Cell Trends

```bash
# Annual temperature trend
cdo -O trend annual_t2m.nc intercept_annual.nc slope_annual.nc

# Convert to degrees Celsius per decade
cdo -O mulc,10 slope_annual.nc trend_annual_per_dec.nc

# Seasonal trends
for season in djf mam jja son; do
    cdo trend "${season}_t2m.nc" "intercept_${season}.nc" "slope_${season}.nc"
    cdo mulc,10 "slope_${season}.nc" "trend_${season}_per_dec.nc"
done

# Combined multi-season trend file
cdo -O merge trend_annual_per_dec.nc trend_djf_per_dec.nc \
    trend_mam_per_dec.nc trend_jja_per_dec.nc trend_son_per_dec.nc \
    all_season_trends.nc
```

#### Statistical Significance

```bash
# Compute t-statistic for annual trends
cdo -O timstd annual_t2m.nc std_annual.nc
cdo -O div slope_annual.nc std_annual.nc t_stat.nc

# Degrees of freedom (n-2 for linear regression)
# For 40 years: df = 38, critical t = 2.02 (95% two-tailed)
cdo -O gtc,2.02 -abs t_stat.nc significant_annual.nc

# Mask non-significant trends
cdo -O mul trend_annual_per_dec.nc significant_annual.nc sig_trend_annual.nc

# Percentage of continent with significant warming
cdo output -fldsum -mulc,100 -gtc,0 significant_annual.nc

# Percentage with significant cooling
cdo output -fldsum -mulc,100 -ltc,0 significant_annual.nc
```

#### Regional Trend Extraction

```bash
# Continental average trend
cdo output -fldmean trend_annual_per_dec.nc

# Sub-regions of Africa
# North Africa (Sahara)
cdo output -fldmean -sellonlatbox,-15,35,20,40 trend_annual_per_dec.nc
# West Africa (Sahel)
cdo output -fldmean -sellonlatbox,-15,15,5,20 trend_annual_per_dec.nc
# East Africa (Horn of Africa)
cdo output -fldmean -sellonlatbox,30,50,-5,15 trend_annual_per_dec.nc
# Southern Africa
cdo output -fldmean -sellonlatbox,10,40,-35,-5 trend_annual_per_dec.nc
# Central Africa (Congo Basin)
cdo output -fldmean -sellonlatbox,10,30,-5,5 trend_annual_per_dec.nc
```

```{tip}
Create a CSV file with all regional trends for easy comparison:
```bash
echo "Region,Annual_Trend,Significant" > regional_trends.csv
for region in "North_Africa -15,35,20,40" "West_Africa -15,15,5,20" "East_Africa 30,50,-5,15" "Southern_Africa 10,40,-35,-5"; do
    name=$(echo "$region" | cut -d' ' -f1)
    box=$(echo "$region" | cut -d' ' -f2-)
    trend_val=$(cdo output -fldmean -sellonlatbox,$box trend_annual_per_dec.nc)
    sig_val=$(cdo output -fldmean -sellonlatbox,$box significant_annual.nc)
    echo "$name,$trend_val,$sig_val" >> regional_trends.csv
done
```

### Step 7: Visualization

#### Annual Trend Map (Python)

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

# Load CDO outputs
trend = xr.open_dataset("trend_annual_per_dec.nc")
sig = xr.open_dataset("significant_annual.nc")

trend_var = list(trend.data_vars)[0]
sig_var = list(sig.data_vars)[0]

# Mask non-significant areas
trend_masked = trend[trend_var].where(sig[sig_var] > 0)

fig = plt.figure(figsize=(14, 10))
ax = fig.add_subplot(111, projection=ccrs.Robinson(central_longitude=20))

# Plot trend
levels = np.linspace(-0.5, 1.0, 16)
im = ax.contourf(trend.lon, trend.lat, trend_masked,
                  levels=levels, transform=ccrs.PlateCarree(),
                  cmap="RdBu_r", extend="both")

# Stippling for significance
sig_plot = ax.contourf(sig.lon, sig.lat, sig[sig_var],
                        levels=[0.5, 1.5], hatches=["", "..."],
                        transform=ccrs.PlateCarree(), colors="none", alpha=0.0)

ax.add_feature(cfeature.COASTLINE, linewidth=0.8)
ax.add_feature(cfeature.BORDERS, linewidth=0.3, alpha=0.5)
ax.add_feature(cfeature.OCEAN, color="lightblue", alpha=0.3)

# Country labels for major African countries
ax.set_extent([-25, 60, -40, 45], crs=ccrs.PlateCarree())

cbar = plt.colorbar(im, ax=ax, orientation="horizontal", pad=0.05,
                    shrink=0.7, label="Temperature Trend (C/decade)")
cbar.ax.tick_params(labelsize=10)

plt.title("Surface Temperature Trend over Africa (1981-2020)\n"
          "Dots indicate 95% significance", fontsize=14, fontweight="bold")
plt.savefig("africa_temp_trend.png", dpi=200, bbox_inches="tight")
print("Figure saved: africa_temp_trend.png")
```

#### Seasonal Comparison Panel (Python)

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

seasons = ["DJF", "MAM", "JJA", "SON"]
files = ["trend_djf_per_dec.nc", "trend_mam_per_dec.nc",
         "trend_jja_per_dec.nc", "trend_son_per_dec.nc"]

fig, axes = plt.subplots(2, 2, figsize=(16, 12),
                          subplot_kw={"projection": ccrs.PlateCarree()})
axes = axes.flatten()

for ax, season, file in zip(axes, seasons, files):
    ds = xr.open_dataset(file)
    var = list(ds.data_vars)[0]
    data = ds[var]

    im = ax.contourf(ds.lon, ds.lat, data,
                      levels=np.linspace(-0.5, 1.0, 16),
                      transform=ccrs.PlateCarree(),
                      cmap="RdBu_r", extend="both")
    ax.add_feature(cfeature.COASTLINE, linewidth=0.5)
    ax.add_feature(cfeature.BORDERS, linewidth=0.3, alpha=0.3)
    ax.set_extent([-20, 55, -35, 40], crs=ccrs.PlateCarree())
    ax.set_title(f"{season} Trend", fontweight="bold")

plt.suptitle("Seasonal Temperature Trends over Africa (1981-2020)",
             fontsize=16, fontweight="bold", y=0.95)

cbar = fig.colorbar(im, ax=axes, orientation="horizontal",
                    pad=0.02, shrink=0.6, label="C/decade")

plt.savefig("africa_seasonal_trends.png", dpi=200, bbox_inches="tight")
print("Figure saved: africa_seasonal_trends.png")
```

#### Regional Time Series (Python)

```python
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Read anomaly data
anom = pd.read_csv("africa_temp_anomaly.csv", header=None, names=["anomaly"],
                   sep=r"\s+")
years = np.arange(1981, 2021)

# Fit trend
slope, intercept = np.polyfit(years, anom["anomaly"].values, 1)
trend_line = slope * years + intercept

fig, ax = plt.subplots(figsize=(12, 6))

ax.bar(years, anom["anomaly"], color="lightgray", edgecolor="gray", alpha=0.7)
ax.plot(years, trend_line, "r-", linewidth=2,
        label=f"Trend: {slope*10:.2f} C/decade")

# Color bars by positive/negative
for i, val in enumerate(anom["anomaly"]):
    if val > 0:
        ax.get_children()[i].set_color("crimson")
    else:
        ax.get_children()[i].set_color("steelblue")

ax.axhline(0, color="black", linewidth=0.5)
ax.set_xlabel("Year", fontsize=12)
ax.set_ylabel("Temperature Anomaly (C)", fontsize=12)
ax.set_title("Africa Mean Temperature Anomaly (ref: 1981-2010)", fontsize=14)
ax.legend(fontsize=11)
ax.grid(alpha=0.3)

# Add annotation for warmest/coolest years
warmest = years[np.argmax(anom["anomaly"].values)]
coolest = years[np.argmin(anom["anomaly"].values)]
ax.annotate(f"Warmest: {warmest}", xy=(warmest, anom["anomaly"].max()),
            xytext=(warmest+2, anom["anomaly"].max()-0.1),
            fontsize=10, color="darkred")
ax.annotate(f"Coolest: {coolest}", xy=(coolest, anom["anomaly"].min()),
            xytext=(coolest+2, anom["anomaly"].min()+0.1),
            fontsize=10, color="darkblue")

plt.tight_layout()
plt.savefig("africa_temp_timeseries.png", dpi=200, bbox_inches="tight")
print("Figure saved: africa_temp_timeseries.png")
```

#### Hotspot Identification Plot

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

trend = xr.open_dataset("trend_annual_per_dec.nc")
trend_var = list(trend.data_vars)[0]
data = trend[trend_var]

# Define hotspots: top 10% warming areas
threshold = data.quantile(0.9)
hotspots = data.where(data > threshold)

fig = plt.figure(figsize=(12, 8))
ax = fig.add_subplot(111, projection=ccrs.PlateCarree())

im = ax.contourf(trend.lon, trend.lat, data,
                  levels=np.linspace(-0.5, 1.0, 16),
                  transform=ccrs.PlateCarree(), cmap="RdBu_r", extend="both")

# Highlight hotspots
ax.contourf(trend.lon, trend.lat, hotspots,
            levels=[threshold.values, data.max().values],
            transform=ccrs.PlateCarree(), colors="none",
            hatches=["////"])

ax.add_feature(cfeature.COASTLINE, linewidth=0.8)
ax.add_feature(cfeature.BORDERS, linewidth=0.3, alpha=0.5)
ax.set_extent([-20, 55, -35, 40], crs=ccrs.PlateCarree())

cbar = plt.colorbar(im, ax=ax, orientation="horizontal", pad=0.05,
                    shrink=0.7, label="Temperature Trend (C/decade)")

plt.title("Temperature Hotspots over Africa\n"
          "Hatching shows top 10% fastest warming areas",
          fontsize=14, fontweight="bold")
plt.savefig("africa_hotspots.png", dpi=200, bbox_inches="tight")
print("Figure saved: africa_hotspots.png")
```

#### Temperature Trend Summary Bar Chart

```python
import matplotlib.pyplot as plt
import numpy as np

regions = ["North Africa", "West Africa", "Central Africa",
           "East Africa", "Southern Africa", "Continent Avg"]
trends = []  # Fill these from your regional_trends.csv

# Read from CSV
with open("regional_trends.csv") as f:
    lines = f.readlines()[1:]  # Skip header

region_names = []
trend_values = []
sig_values = []

for line in lines:
    parts = line.strip().split(",")
    region_names.append(parts[0].replace("_", " "))
    trend_values.append(float(parts[1]))
    sig_values.append(float(parts[2]))

fig, ax = plt.subplots(figsize=(10, 6))
colors = ["crimson" if t > 0 else "steelblue" for t in trend_values]
bars = ax.bar(region_names, trend_values, color=colors, alpha=0.7)

# Add significance markers
for i, (bar, sig) in enumerate(zip(bars, sig_values)):
    if sig > 0.5:  # Majority of grid cells significant
        ax.text(bar.get_x() + bar.get_width()/2, bar.get_height(),
                "*", ha="center", va="bottom" if bar.get_height() > 0 else "top",
                fontsize=16, fontweight="bold")

ax.axhline(0, color="black", linewidth=0.5)
ax.set_ylabel("Temperature Trend (C/decade)", fontsize=12)
ax.set_title("Regional Temperature Trends over Africa (1981-2020)", fontsize=14)
ax.tick_params(axis="x", rotation=45)
ax.grid(axis="y", alpha=0.3)

# Legend
from matplotlib.patches import Patch
legend_elements = [Patch(facecolor="crimson", alpha=0.7, label="Warming"),
                   Patch(facecolor="steelblue", alpha=0.7, label="Cooling"),
                   plt.Line2D([0], [0], marker="*", color="w", label="p < 0.05",
                              markerfacecolor="black", markersize=12)]
ax.legend(handles=legend_elements)

plt.tight_layout()
plt.savefig("africa_regional_trends.png", dpi=200, bbox_inches="tight")
print("Figure saved: africa_regional_trends.png")
```

## Complete Bash Workflow Script

Save as `temperature_trend_analysis.sh`:

```bash
#!/bin/bash
# =============================================================================
# Temperature Trend Mapping Pipeline
# Climate Data Operators (CDO) Training
# =============================================================================
set -euo pipefail

# Configuration
INPUT_DATA="era5_t2m_monthly.nc"
AFRICA_BOX="-20,55,-35,40"
REF_START=1981
REF_END=2010
OUTPUT_DIR="temp_trend_output"

mkdir -p "$OUTPUT_DIR"

echo "=== Temperature Trend Analysis ==="
echo "Region: Africa ($AFRICA_BOX)"
echo "Reference period: $REF_START-$REF_END"
echo "==================================="

# Step 1: Crop and convert units
echo "[1/7] Cropping to Africa..."
cdo -O -s sellonlatbox,$AFRICA_BOX "$INPUT_DATA" "$OUTPUT_DIR/africa_raw.nc"
cdo -O -s expr,'t2m_c=t2m-273.15' "$OUTPUT_DIR/africa_raw.nc" \
    "$OUTPUT_DIR/africa_t2m.nc"

# Step 2: Annual and seasonal means
echo "[2/7] Computing annual and seasonal means..."
cdo -O -s yearmean "$OUTPUT_DIR/africa_t2m.nc" "$OUTPUT_DIR/annual_t2m.nc"
cdo -O -s seasmean "$OUTPUT_DIR/africa_t2m.nc" "$OUTPUT_DIR/seasonal_t2m.nc"

for season in djf mam jja son; do
    case $season in
        djf) sid=1;; mam) sid=2;; jja) sid=3;; son) sid=4;;
    esac
    cdo -O -s selseas,$sid "$OUTPUT_DIR/seasonal_t2m.nc" \
        "$OUTPUT_DIR/${season}_t2m.nc"
done

# Step 3: Climatology
echo "[3/7] Computing climatology..."
cdo -O -s selyear,${REF_START}/${REF_END} "$OUTPUT_DIR/africa_t2m.nc" \
    "$OUTPUT_DIR/ref_period.nc"
cdo -O -s ymonmean "$OUTPUT_DIR/ref_period.nc" "$OUTPUT_DIR/clim_monthly.nc"

# Step 4: Anomalies
echo "[4/7] Computing anomalies..."
cdo -O -s ymonsub "$OUTPUT_DIR/africa_t2m.nc" "$OUTPUT_DIR/clim_monthly.nc" \
    "$OUTPUT_DIR/anom_monthly.nc"
cdo -O -s yearmean "$OUTPUT_DIR/anom_monthly.nc" "$OUTPUT_DIR/anom_annual.nc"
cdo -O -s fldmean "$OUTPUT_DIR/anom_annual.nc" "$OUTPUT_DIR/africa_anom_ts.nc"

# Step 5: Trends
echo "[5/7] Computing trends..."
cdo -O -s trend "$OUTPUT_DIR/annual_t2m.nc" \
    "$OUTPUT_DIR/intercept.nc" "$OUTPUT_DIR/slope.nc"
cdo -O -s mulc,10 "$OUTPUT_DIR/slope.nc" \
    "$OUTPUT_DIR/trend_annual.nc"

# Seasonal trends
for season in djf mam jja son; do
    cdo -O -s trend "$OUTPUT_DIR/${season}_t2m.nc" \
        "$OUTPUT_DIR/intercept_${season}.nc" "$OUTPUT_DIR/slope_${season}.nc"
    cdo -O -s mulc,10 "$OUTPUT_DIR/slope_${season}.nc" \
        "$OUTPUT_DIR/trend_${season}.nc"
done

# Step 6: Significance
echo "[6/7] Computing significance..."
cdo -O -s timstd "$OUTPUT_DIR/annual_t2m.nc" "$OUTPUT_DIR/std.nc"
cdo -O -s div "$OUTPUT_DIR/slope.nc" "$OUTPUT_DIR/std.nc" "$OUTPUT_DIR/tstat.nc"
cdo -O -s gtc,2.02 -abs "$OUTPUT_DIR/tstat.nc" "$OUTPUT_DIR/significant.nc"
cdo -O -s mul "$OUTPUT_DIR/trend_annual.nc" "$OUTPUT_DIR/significant.nc" \
    "$OUTPUT_DIR/sig_trend_annual.nc"

# Step 7: Export
echo "[7/7] Exporting time series..."
cdo -O -s output "$OUTPUT_DIR/africa_anom_ts.nc" > "$OUTPUT_DIR/temp_anomaly.csv"

# Regional trends
echo "Region,Trend_C_per_decade,Significant_Fraction" \
    > "$OUTPUT_DIR/regional_trends.csv"
for region in "North_Africa -15,35,20,40" "West_Africa -15,15,5,20" \
              "Central_Africa 10,30,-5,5" "East_Africa 30,50,-5,15" \
              "Southern_Africa 10,40,-35,-5"; do
    name=$(echo "$region" | cut -d' ' -f1)
    box=$(echo "$region" | cut -d' ' -f2-)
    trend_val=$(cdo -s output -fldmean -sellonlatbox,$box \
        "$OUTPUT_DIR/trend_annual.nc")
    sig_val=$(cdo -s output -fldmean -sellonlatbox,$box \
        "$OUTPUT_DIR/significant.nc")
    echo "$name,$trend_val,$sig_val" >> "$OUTPUT_DIR/regional_trends.csv"
done

echo "==================================="
echo "Analysis Complete!"
echo "Output directory: $OUTPUT_DIR"
cdo -s output -fldmean "$OUTPUT_DIR/trend_annual.nc"
echo "C/decade (Africa average)"
echo "==================================="
```

## Expected Outputs

### 1. Annual Trend Map
A spatial map of temperature trends (C/decade) over Africa with:
- Red colors indicating warming
- Blue colors indicating cooling
- Stippling/hatching for statistical significance
- Coastlines and country borders

### 2. Seasonal Trend Panel
Four-panel figure showing trends for DJF, MAM, JJA, and SON seasons, enabling comparison of seasonal warming patterns.

### 3. Regional Time Series
Annual temperature anomaly time series with:
- Bar chart showing anomalies from reference period
- Overlaid linear trend line
- Statistically significant trend annotation
- Identification of record warm/cold years

### 4. Regional Trends Bar Chart
Comparative bar chart of trends across African sub-regions with significance markers.

### 5. Hotspot Map
Map highlighting the top 10% fastest-warming areas.

## Interpretation Guidance

### Key Findings to Look For

1. **Continental warming**: Most of Africa shows warming, with the strongest trends in North Africa (Sahara) and Southern Africa
2. **Seasonal contrasts**: Warming may be stronger in certain seasons (e.g., JJA in the Sahel)
3. **Topographic effects**: Highlands may warm differently than surrounding lowlands
4. **Coastal vs. inland**: Coastal regions may warm slower due to oceanic influence
5. **Significance patterns**: Are significant trends spatially coherent or scattered?

### Discussion Questions

- Which regions of Africa are warming fastest? Slowest?
- Is there evidence of enhanced warming in semi-arid regions?
- How do seasonal trends differ? What might drive these differences?
- How does Africa's warming rate compare to the global average?
- Are there any regions showing cooling? If so, what might explain it?

### Common Pitfalls

```{warning}
- **Urban heat island**: CRU data includes station data from urban areas; trends may be locally enhanced
- **ERA5 inhomogeneities**: While ERA5 is consistent, changes in observation density over time can affect trends
- **Serial correlation**: Temperature time series are strongly autocorrelated; adjust degrees of freedom accordingly
- **Multiple testing**: Testing trends at thousands of grid cells inflates false positives; consider field significance
```

## Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Data processing | 20% | Correct cropping, unit conversion, and temporal aggregation |
| Trend computation | 25% | Proper use of CDO trend operator and significance testing |
| Visualization | 25% | Clear trend maps, time series, and seasonal comparison |
| Regional analysis | 15% | Extraction and comparison of regional trends |
| Interpretation | 15% | Insightful analysis of spatial and seasonal patterns |

## Extension Activities

### Advanced Options

1. **Elevation-dependent warming**: Correlate trends with elevation using a digital elevation model
2. **Diurnal temperature range**: Analyze trends in Tmax and Tmin separately
3. **Heatwave indices**: Compute warm spell duration index (WSDI) using daily data
4. **Urbanization effects**: Compare urban vs. rural station trends

```bash
# Example: Elevation analysis
cdo -O merge trend_annual.nc elevation.nc trend_with_elev.nc
cdo output -fldcor trend_annual.nc elevation.nc
```

### Cross-Project Integration

- Compare temperature trends with precipitation trends from **Project 1**
- Use temperature data for bias-correcting CMIP6 models in **Project 6**
- Include temperature analysis in **Project 8** automated report

```{exercise}
Complete the temperature trend mapping. Produce the annual trend map, seasonal comparison, and regional time series. Write a one-page interpretation: Which regions are warming fastest? Are there seasonal differences? What are the implications for Africa?
```

## References

- Hersbach, H., et al. (2020). The ERA5 global reanalysis. Quarterly Journal of the Royal Meteorological Society, 146(730), 1999-2049.
- Harris, I., et al. (2020). Version 4 of the CRU TS monthly high-resolution gridded multivariate climate dataset. Scientific Data, 7, 109.
- IPCC (2021). Climate Change 2021: The Physical Science Basis. Cambridge University Press.
- Engelbrecht, F., et al. (2015). Projections of rapidly rising surface temperatures over Africa. Environmental Research Letters, 10(8), 085004.
