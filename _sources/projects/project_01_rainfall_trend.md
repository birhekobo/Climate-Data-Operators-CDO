---
title: "Project 1: Rainfall Trend Analysis"
subject: Climate Data Operators (CDO) Training
subtitle: Analyzing Long-Term Precipitation Trends Using CHIRPS Data
---

# Project 1: Rainfall Trend Analysis

## Overview

This project guides you through a complete rainfall trend analysis workflow using Climate Data Operators (CDO). You will process monthly precipitation data, compute annual and seasonal totals, analyze trends, and create publication-quality visualizations.

```{note}
**Estimated time**: 3-4 hours
**Prerequisites**: Modules 1-8 (CDO basics, temporal operators, statistics, spatial operations, scripting)
```

## Learning Objectives

After completing this project, you will be able to:

- Download and inspect CHIRPS or GPCC precipitation data
- Subset data to a region of interest using CDO spatial operators
- Compute annual and seasonal precipitation totals
- Calculate anomalies relative to a climatological baseline
- Perform linear trend analysis on gridded data
- Create trend maps and time series visualizations
- Interpret rainfall trends in the context of climate variability

## Data Requirements

### Primary Dataset: CHIRPS Monthly Precipitation

CHIRPS (Climate Hazards Group InfraRed Precipitation with Station data) provides global precipitation data from 1981 to present at 0.05 degree resolution.

| Attribute | Description |
|-----------|-------------|
| **Variable** | Precipitation (mm/month) |
| **Spatial resolution** | 0.05 degrees (~5 km) |
| **Temporal coverage** | 1981 - present |
| **Temporal resolution** | Monthly |
| **Domain** | Global (50S - 50N) |
| **Source** | https://www.chc.ucsb.edu/data/chirps |

### Alternative: GPCC Monthly Precipitation

| Attribute | Description |
|-----------|-------------|
| **Variable** | Precipitation (mm/month) |
| **Spatial resolution** | 1.0 degree |
| **Temporal coverage** | 1901 - 2020 |
| **Source** | https://climatedataguide.ucar.edu/climate-data |

### Real Sample Data

This course ships with real CHIRPS monthly precipitation for Ethiopia (`../datasets/chirps_ethiopia.nc`, 1981-2020). Use it directly:

```bash
# Inspect the real CHIRPS field supplied with the course
cdo sinfo ../datasets/chirps_ethiopia.nc
cdo griddes ../datasets/chirps_ethiopia.nc

# Derive annual totals and a monthly climatology from the real data
cdo yearsum ../datasets/chirps_ethiopia.nc chirps_annual.nc
cdo ymonmean ../datasets/chirps_ethiopia.nc chirps_climatology.nc
```

```{note}
All figures and results in this project are produced from the real CHIRPS dataset. For other regions, download real CHIRPS or GPCC data rather than generating artificial fields.
```

## Step-by-Step Workflow

### Step 1: Data Inspection

Before processing, inspect your data to understand its structure:

```bash
# Basic file information
cdo sinfo chirps_monthly.nc

# Grid description
cdo griddes chirps_monthly.nc

# Time information
cdo showyear chirps_monthly.nc
cdo showtimestamp chirps_monthly.nc

# Variable information
cdo vardes chirps_monthly.nc

# Global metadata
cdo -s infov chirps_monthly.nc
```

Expected output from `cdo sinfo`:

```
   File format: NetCDF
   -1 : Institut Source   T Steptype Levels Num    Points Num Dtype : Parameter name
    1 : unknown  unknown  v instant     1   1  ?   7203600  F32  : precip
   Grid coordinates:
     1 : lonlat                     : points=7203600 (7200x1001)
                        lon : -179.975 to 179.975 degrees east
                        lat : -50.025 to 50.025 degrees north
   Vertical coordinates : 1
   Time coordinate : 480 steps
   RefTime = 1981-01-01
   Timesteps in file:
        1981-01-01  1981-02-01  1981-03-01  ...  2020-12-01
```

### Step 2: Crop to Ethiopia Region

Ethiopia is located approximately between 3N-15N latitude and 33E-48E longitude.

```bash
# Define Ethiopia bounding box
# Format: sellonlatbox,lon1,lon2,lat1,lat2
cdo -O sellonlatbox,33,48,3,15 chirps_monthly.nc ethiopia_precip.nc

# Verify the subset
cdo griddes ethiopia_precip.nc
cdo sinfo ethiopia_precip.nc
```

```{note}
The `sellonlatbox` operator selects a rectangular region by longitude/latitude bounds. Always verify your region after cropping.
```

For a more precise subset using a shapefile (if available):

```bash
# Using a shapefile mask for Ethiopia
cdo -O maskregion,ethiopia.shp chirps_monthly.nc ethiopia_masked.nc

# If shapefile not available, use a latitude/longitude box with land mask
cdo -O sellonlatbox,33,48,3,15 chirps_monthly.nc ethiopia_precip.nc
```

### Step 3: Compute Annual Precipitation Totals

Annual totals show year-to-year variability in precipitation:

```bash
# Compute annual sums
cdo -O yearsum ethiopia_precip.nc annual_precip.nc

# Inspect annual totals
cdo sinfo annual_precip.nc
cdo showyear annual_precip.nc

# Extract time series for a specific grid point (e.g., Addis Ababa ~9N, 38.7E)
cdo output -selindexbox,114,114,120,120 annual_precip.nc > addis_annual.txt
```

```{tip}
`yearsum` sums all timesteps within each calendar year. Ensure your data covers complete years.
```

Compute decadal averages for a broader perspective:

```bash
# Decadal averages
cdo -O runmean,10 annual_precip.nc decadal_precip.nc

# Compare first and last decades
cdo -O timmean -seltimestep,1,10 annual_precip.nc first_decade.nc
cdo -O timmean -seltimestep,31,40 annual_precip.nc last_decade.nc
cdo -O sub last_decade.nc first_decade.nc decade_diff.nc
```

### Step 4: Compute Seasonal Totals

For Ethiopia, key seasons are:

- **MAM** (March-May): Short rains / Belg season
- **JJAS** (June-September): Long rains / Kiremt season (main rainy season)
- **OND** (October-December): Post-rains / Bega dry season onset

```bash
# Seasonal sums (using CDO season numbering: DJF=1, MAM=2, JJA=3, SON=4)
cdo -O seasum -selseas,2 ethiopia_precip.nc mam_precip.nc   # MAM (short rains)
cdo -O seasum -selseas,3 ethiopia_precip.nc jja_precip.nc   # JJA (long rains)

# Alternative: select specific months manually
cdo -O yearsum -selmonth,3/5 ethiopia_precip.nc mam_manual.nc
cdo -O yearsum -selmonth,6/9 ethiopia_precip.nc jjas_manual.nc

# Compare seasonal contributions
cdo -O output -fldmean mam_precip.nc > mam_timeseries.txt
cdo -O output -fldmean jjas_manual.nc > jjas_timeseries.txt
cdo -O output -fldmean annual_precip.nc > annual_timeseries.txt
```

Check seasonal fraction of annual total:

```bash
# JJAS fraction of annual total
cdo -O div jjas_manual.nc annual_precip.nc jjas_fraction.nc

# Regions where JJAS > 70% of annual rainfall
cdo -O gec,0.7 jjas_fraction.nc jjas_dominant.nc

# Spatial average of fraction
cdo -O output -fldmean jjas_fraction.nc
```

### Step 5: Calculate Anomalies

Anomalies are calculated relative to a reference period (typically 1981-2010 for WMO standard):

```bash
# Compute monthly climatology (1981-2010)
cdo -O selyear,1981/2010 ethiopia_precip.nc ref_period.nc
cdo -O ymonmean ref_period.nc clim_monthly.nc

# Verify climatology
cdo output clim_monthly.nc

# Compute monthly anomalies
cdo -O ymonsub ethiopia_precip.nc clim_monthly.nc precip_anom_monthly.nc

# Annual anomaly
cdo -O yearsum precip_anom_monthly.nc annual_anom.nc

# Spatial average of annual anomaly
cdo -O output -fldmean annual_anom.nc > anomaly_timeseries.txt

# Identify extreme years (anomaly > 1 std or < -1 std)
cdo -O timstd annual_anom.nc anomaly_std.nc
cdo -O gtc,1 -div annual_anom.nc anomaly_std.nc positive_anom_mask.nc
cdo -O ltc,-1 -div annual_anom.nc anomaly_std.nc negative_anom_mask.nc
```

```{note}
The WMO standard reference period is 1981-2010. When enough data is available, use this period for consistency with other studies.
```

### Step 6: Spatial Averaging

Compute regional averages for trend analysis:

```bash
# Area-weighted spatial average over Ethiopia
cdo -O fldmean annual_precip.nc ethiopia_annual_mean.nc
cdo output ethiopia_annual_mean.nc > ethiopia_annual_timeseries.csv

# Sub-regional averages
# Northern highlands (Tigray)
cdo -O fldmean -sellonlatbox,36,40,12,15 annual_precip.nc north_mean.nc
# Central highlands (Amhara, Oromia)
cdo -O fldmean -sellonlatbox,37,42,7,12 annual_precip.nc central_mean.nc
# Lowland regions (Somali, Afar)
cdo -O fldmean -sellonlatbox,42,48,3,12 annual_precip.nc east_mean.nc

# Output all regional means
cdo output north_mean.nc > north_timeseries.csv
cdo output central_mean.nc > central_timeseries.csv
cdo output east_mean.nc > east_timeseries.csv
```

### Step 7: Trend Analysis

#### CDO Trend Operator

```bash
# Linear trend on grid cells
cdo -O trend annual_precip.nc intercept.nc slope.nc

# Convert slope to mm/decade (multiply by 10 for 40 years of data? No - trend gives per timestep)
# For annual data, slope is already in mm/year
# Multiply by 10 for mm/decade
cdo -O mulc,10 slope.nc trend_per_decade.nc

# For seasonal trends
cdo -O trend mam_precip.nc mam_intercept.nc mam_slope.nc
cdo -O mulc,10 mam_slope.nc mam_trend.nc

cdo -O trend jjas_manual.nc jjas_intercept.nc jjas_slope.nc
cdo -O mulc,10 jjas_slope.nc jjas_trend.nc
```

#### Statistical Significance Testing

```bash
# Compute t-statistic for significance testing
cdo -O timstd annual_precip.nc std_annual.nc
cdo -O div slope.nc std_annual.nc t_stat.nc

# Two-tailed t-test at 95% confidence
# For n=40 years, critical value ~2.02 (df=38)
cdo -O gtc,2.02 -abs t_stat.nc significant.nc

# Mask non-significant trends
cdo -O mul trend_per_decade.nc significant.nc sig_trend.nc

# Count significant pixels
cdo output -fldsum -gtc,0 significant.nc

# Mann-Kendall trend test alternative (using Python)
```

```{tip}
The t-test provides a first-order significance estimate. For more robust results, consider the Mann-Kendall test or field significance tests.
```

#### Trend Statistics

```bash
# Spatially averaged trend
cdo output -fldmean trend_per_decade.nc

# Regional trend extraction
cdo output -fldmean -sellonlatbox,33,48,3,15 trend_per_decade.nc

# Percentage of area with significant positive/negative trends
cdo output -fldsum -mulc,100 -gtc,0 significant.nc
```

### Step 8: Visualization

#### Time Series Plot (Python)

```python
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Read annual precipitation time series
data = pd.read_csv("ethiopia_annual_timeseries.csv", header=None,
                   names=["precip"], sep=r"\s+")

# Read anomaly time series
anom = pd.read_csv("anomaly_timeseries.txt", header=None,
                   names=["anom"], sep=r"\s+")

years = np.arange(1981, 2021)

# Linear regression
slope, intercept = np.polyfit(years, data["precip"].values, 1)
trend_line = slope * years + intercept

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))

# Annual precipitation
ax1.bar(years, data["precip"], color="steelblue", alpha=0.7,
        label="Annual Precipitation")
ax1.plot(years, trend_line, "r-", linewidth=2,
         label=f"Trend: {slope*10:.1f} mm/decade")
ax1.axhline(data["precip"].mean(), color="gray", linestyle="--",
            label=f"Mean: {data['precip'].mean():.0f} mm/yr")
ax1.set_ylabel("Precipitation (mm/yr)")
ax1.set_title("Ethiopia Annual Precipitation (1981-2020)")
ax1.legend()
ax1.grid(alpha=0.3)

# Anomalies
colors = ["crimson" if v < 0 else "forestgreen" for v in anom["anom"]]
ax2.bar(years, anom["anom"], color=colors, alpha=0.7)
ax2.axhline(0, color="black", linewidth=0.5)
ax2.set_ylabel("Precipitation Anomaly (mm)")
ax2.set_xlabel("Year")
ax2.set_title("Annual Precipitation Anomaly (ref: 1981-2010)")
ax2.grid(alpha=0.3)

plt.tight_layout()
plt.savefig("ethiopia_precip_timeseries.png", dpi=200, bbox_inches="tight")
print("Figure saved: ethiopia_precip_timeseries.png")
```

#### Trend Map (Python)

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

# Load CDO outputs
trend = xr.open_dataset("trend_per_decade.nc")
sig = xr.open_dataset("significant.nc")

trend_var = list(trend.data_vars)[0]
sig_var = list(sig.data_vars)[0]

# Apply significance mask
trend_masked = trend[trend_var].where(sig[sig_var] > 0)

fig = plt.figure(figsize=(12, 8))
ax = fig.add_subplot(111, projection=ccrs.PlateCarree())

# Trend map
levels = np.linspace(-100, 100, 21)
im = ax.contourf(trend.lon, trend.lat, trend_masked,
                  levels=levels, transform=ccrs.PlateCarree(),
                  cmap="BrBG", extend="both")

# Add hatching for significance
sig_plot = ax.contourf(sig.lon, sig.lat, sig[sig_var],
                        levels=[0.5, 1.5], hatches=["", "///"],
                        transform=ccrs.PlateCarree(), colors="none")

ax.add_feature(cfeature.COASTLINE, linewidth=0.8)
ax.add_feature(cfeature.BORDERS, linewidth=0.4, alpha=0.5)
ax.add_feature(cfeature.OCEAN, color="lightgray")
ax.add_feature(cfeature.LAKES, color="lightgray")

# Ethiopia outline (approximate)
ax.set_extent([30, 50, 0, 17], crs=ccrs.PlateCarree())

cbar = plt.colorbar(im, ax=ax, orientation="horizontal",
                    pad=0.05, shrink=0.8, label="Precipitation Trend (mm/decade)")

plt.title("Annual Precipitation Trend Over Ethiopia (1981-2020)\nHatching indicates 95% significance")
plt.savefig("ethiopia_trend_map.png", dpi=200, bbox_inches="tight")
print("Figure saved: ethiopia_trend_map.png")
```

#### Seasonal Cycle Plot

```python
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np

# Load monthly climatology
clim = xr.open_dataset("clim_monthly.nc")
clim_var = list(clim.data_vars)[0]
monthly_mean = clim[clim_var].mean(dim=["lat", "lon"])

months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

fig = plt.figure(figsize=(10, 5))
ax = plt.gca()

bars = ax.bar(months, monthly_mean.values, color="steelblue", alpha=0.7,
              edgecolor="navy", linewidth=0.5)

# Highlight seasons
for i in [2, 3, 4]:  # MAM
    bars[i].set_color("orange")
    bars[i].set_alpha(0.8)
for i in [5, 6, 7, 8]:  # JJAS
    bars[i].set_color("forestgreen")
    bars[i].set_alpha(0.8)

ax.set_ylabel("Precipitation (mm/month)")
ax.set_title("Ethiopia Monthly Precipitation Climatology (1981-2010)")
ax.grid(axis="y", alpha=0.3)

# Add season labels
ax.text(1.5, max(monthly_mean.values)*0.9, "Belg\n(Short Rains)",
        ha="center", fontsize=9, fontweight="bold")
ax.text(6.5, max(monthly_mean.values)*0.9, "Kiremt\n(Long Rains)",
        ha="center", fontsize=9, fontweight="bold")

plt.savefig("ethiopia_seasonal_cycle.png", dpi=200, bbox_inches="tight")
print("Figure saved: ethiopia_seasonal_cycle.png")
```

#### Seasonal Contribution Stacked Bar Chart

```python
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np

# Load seasonal data
mam = xr.open_dataset("mam_precip.nc")
jjas = xr.open_dataset("jjas_manual.nc")
annual = xr.open_dataset("annual_precip.nc")

mam_var = list(mam.data_vars)[0]
jjas_var = list(jjas.data_vars)[0]
ann_var = list(annual.data_vars)[0]

mam_mean = mam[mam_var].mean(dim=["lat", "lon"]).values
jjas_mean = jjas[jjas_var].mean(dim=["lat", "lon"]).values
annual_mean = annual[ann_var].mean(dim=["lat", "lon"]).values

# Other seasons
other = annual_mean - mam_mean - jjas_mean

years = np.arange(1981, 2021)

fig, ax = plt.subplots(figsize=(12, 6))
ax.bar(years, mam_mean, label="MAM (Short Rains)", color="orange", alpha=0.8)
ax.bar(years, jjas_mean, bottom=mam_mean, label="JJAS (Long Rains)",
       color="forestgreen", alpha=0.8)
ax.bar(years, other, bottom=mam_mean + jjas_mean,
       label="Other Months", color="lightblue", alpha=0.8)

ax.set_ylabel("Precipitation (mm/yr)")
ax.set_xlabel("Year")
ax.set_title("Seasonal Contribution to Annual Precipitation in Ethiopia")
ax.legend()
ax.grid(alpha=0.3, axis="y")
ax.set_ylim([0, np.max(annual_mean) * 1.1])

plt.savefig("seasonal_contribution.png", dpi=200, bbox_inches="tight")
print("Figure saved: seasonal_contribution.png")
```

## Complete Bash Workflow Script

Save the following as `rainfall_trend_analysis.sh`:

```bash
#!/bin/bash
# =============================================================================
# Rainfall Trend Analysis Pipeline
# Climate Data Operators (CDO) Training
# =============================================================================
set -euo pipefail

# Configuration
INPUT_DATA="chirps_monthly.nc"
REGION="33,48,3,15"   # Ethiopia: lon1,lon2,lat1,lat2
REF_START=1981
REF_END=2010
OUTPUT_DIR="rainfall_output"

mkdir -p "$OUTPUT_DIR"

echo "=== Rainfall Trend Analysis ==="
echo "Input: $INPUT_DATA"
echo "Region: Ethiopia ($REGION)"
echo "Reference period: $REF_START-$REF_END"
echo "================================"

# Step 1: Crop to region
echo "[1/7] Cropping to region..."
cdo -O -s sellonlatbox,$REGION "$INPUT_DATA" "$OUTPUT_DIR/ethiopia_precip.nc"

# Step 2: Annual totals
echo "[2/7] Computing annual totals..."
cdo -O -s yearsum "$OUTPUT_DIR/ethiopia_precip.nc" "$OUTPUT_DIR/annual_precip.nc"

# Step 3: Seasonal totals
echo "[3/7] Computing seasonal totals..."
cdo -O -s seasum -selseas,2 "$OUTPUT_DIR/ethiopia_precip.nc" "$OUTPUT_DIR/mam_precip.nc"
cdo -O -s yearsum -selmonth,6/9 "$OUTPUT_DIR/ethiopia_precip.nc" "$OUTPUT_DIR/jjas_precip.nc"

# Step 4: Climatology and anomalies
echo "[4/7] Computing climatology..."
cdo -O -s selyear,${REF_START}/${REF_END} "$OUTPUT_DIR/ethiopia_precip.nc" \
    "$OUTPUT_DIR/ref_period.nc"
cdo -O -s ymonmean "$OUTPUT_DIR/ref_period.nc" "$OUTPUT_DIR/clim_monthly.nc"
cdo -O -s ymonsub "$OUTPUT_DIR/ethiopia_precip.nc" "$OUTPUT_DIR/clim_monthly.nc" \
    "$OUTPUT_DIR/precip_anom.nc"
cdo -O -s yearsum "$OUTPUT_DIR/precip_anom.nc" "$OUTPUT_DIR/annual_anom.nc"

# Step 5: Spatial averages
echo "[5/7] Computing spatial averages..."
cdo -O -s fldmean "$OUTPUT_DIR/annual_precip.nc" "$OUTPUT_DIR/ethiopia_mean.nc"
cdo -O -s fldmean "$OUTPUT_DIR/mam_precip.nc" "$OUTPUT_DIR/mam_mean.nc"
cdo -O -s fldmean "$OUTPUT_DIR/jjas_precip.nc" "$OUTPUT_DIR/jjas_mean.nc"

# Step 6: Trend analysis
echo "[6/7] Computing trends..."
cdo -O -s trend "$OUTPUT_DIR/annual_precip.nc" \
    "$OUTPUT_DIR/intercept.nc" "$OUTPUT_DIR/slope.nc"
cdo -O -s mulc,10 "$OUTPUT_DIR/slope.nc" "$OUTPUT_DIR/trend_per_decade.nc"

# Significance testing
cdo -O -s timstd "$OUTPUT_DIR/annual_precip.nc" "$OUTPUT_DIR/std.nc"
cdo -O -s div "$OUTPUT_DIR/slope.nc" "$OUTPUT_DIR/std.nc" "$OUTPUT_DIR/tstat.nc"
cdo -O -s gtc,2.02 -abs "$OUTPUT_DIR/tstat.nc" "$OUTPUT_DIR/significant.nc"
cdo -O -s mul "$OUTPUT_DIR/trend_per_decade.nc" \
    "$OUTPUT_DIR/significant.nc" "$OUTPUT_DIR/sig_trend.nc"

# Step 7: Export data for visualization
echo "[7/7] Exporting time series..."
cdo -O -s output "$OUTPUT_DIR/ethiopia_mean.nc" > "$OUTPUT_DIR/annual_timeseries.csv"
cdo -O -s output "$OUTPUT_DIR/annual_anom.nc" > "$OUTPUT_DIR/anomaly_timeseries.csv"

echo "=== Analysis Complete ==="
echo "Output directory: $OUTPUT_DIR"
echo "Report trend summary:"
cdo -s output -fldmean "$OUTPUT_DIR/trend_per_decade.nc"
```

## Expected Outputs

### 1. Trend Map

A spatial map showing precipitation trends (mm/decade) across Ethiopia with:
- Brown colors for drying trends
- Green colors for wetting trends
- Hatching or stippling for statistically significant areas (p < 0.05)
- Coastlines and country borders

### 2. Annual Time Series

A bar/line plot showing:
- Annual precipitation totals for each year
- Linear trend line overlaid
- Mean value reference line
- Anomaly bars colored by sign (positive/negative)

### 3. Seasonal Cycle

A bar chart showing:
- Mean monthly precipitation climatology
- Color-coded seasons (MAM, JJAS, other)
- Season labels highlighting rainy seasons

### 4. Seasonal Contribution

A stacked bar chart showing:
- Annual precipitation broken down by season
- Relative contribution of long rains, short rains, and other months

### 5. Summary Statistics Table

| Statistic | Value |
|-----------|-------|
| Mean annual precipitation | ~850 mm/yr (Ethiopia average) |
| JJAS contribution | ~65-75% of annual total |
| MAM contribution | ~15-25% of annual total |
| Trend (mm/decade) | Variable by region |
| % area with significant trend | Computed from analysis |

## Interpretation Guidance

### What to Look For

1. **Spatial patterns**: Are there coherent regions of drying or wetting? Do trends follow topographic features (highlands vs. lowlands)?

2. **Seasonal contrasts**: Is the trend driven by the long rains (JJAS) or short rains (MAM)? Different seasons may show different trends.

3. **Interannual variability**: Look at the time series — are there multi-year drought periods? Are extreme years becoming more frequent?

4. **Significance**: Focus interpretation on areas where trends are statistically significant. Non-significant trends may be due to natural variability.

### Key Questions to Answer

- Has annual precipitation increased or decreased over Ethiopia since 1981?
- Which seasons contribute most to the observed trend?
- Are there regional differences between the highlands and lowlands?
- How does the magnitude of the trend compare to natural variability?

### Common Pitfalls

```{warning}
- **Short records**: Trends computed from short records (<30 years) may not reflect long-term climate change
- **Serial correlation**: Annual precipitation is often autocorrelated, which can inflate trend significance
- **Spatial correlation**: Nearby grid cells are not independent; consider field significance
- **Data quality**: CHIRPS performs better in some regions than others; check validation studies
```

## Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| CDO commands | 25% | Correct use of spatial, temporal, and statistical operators |
| Data processing | 20% | Proper workflow ordering, temporary file management |
| Trend analysis | 20% | Correct trend computation and significance testing |
| Visualization | 20% | Clear, publication-quality figures with proper labels |
| Interpretation | 15% | Insightful analysis of results, discussion of limitations |

## Extension Activities

### Advanced Options

1. **Mann-Kendall trend test**: Implement a non-parametric trend test using Python
2. **EOF analysis**: Use CDO `eof` operator to identify dominant modes of variability
3. **Comparison with ENSO**: Correlate rainfall anomalies with ENSO indices (Niño 3.4)
4. **CMIP6 future projections**: Compare historical trends with CMIP6 model projections

```bash
# Example: EOF analysis of precipitation anomalies
cdo -O eof,3 annual_anom.nc eof_pattern.nc eof_timeseries.nc

# Example: Correlate with ENSO
# First extract Niño 3.4 index, then:
cdo -O timcor annual_anom.nc nino34_annual.nc enso_correlation.nc
```

### Cross-Project Integration

- Use the rainfall data processed here as input for **Project 3 (Drought Index Computation)**
- Compare with **Project 6 (CMIP6 Multi-Model Analysis)** to contextualize observed trends
- Include results in **Project 8 (Automated Climate Report Generator)**

```{exercise}
Complete the rainfall trend analysis. Produce the trend map, time series, and a one-page summary of your findings. Identify three regions with the strongest drying trends and three with the strongest wetting trends. Discuss possible climate drivers.
```

## References

- Funk, C., et al. (2015). The climate hazards infrared precipitation with stations — a new environmental record for monitoring extremes. Scientific Data, 2, 150066.
- Schneider, U., et al. (2014). GPCC's new land surface precipitation climatology based on quality-controlled in situ data. Journal of Climate, 27(12), 4631-4650.
- WMO (2017). WMO Guidelines on the Calculation of Climate Normals. WMO-No. 1203.
- CDO Documentation: https://code.mpimet.mpg.de/projects/cdo
