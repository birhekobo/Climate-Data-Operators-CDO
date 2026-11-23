---
title: "Project 3: Drought Index Computation"
subject: Climate Data Operators (CDO) Training
subtitle: Computing the Standardized Precipitation Index (SPI) for Drought Monitoring
---

# Project 3: Drought Index Computation

## Overview

The Standardized Precipitation Index (SPI) is a widely used drought index that quantifies precipitation deficits at multiple timescales. This project guides you through computing SPI at different accumulation periods (1, 3, 6, and 12 months) using CDO and Python.

```{note}
**Estimated time**: 3-4 hours
**Prerequisites**: Modules 1-9 (including statistics and temporal operators)
```

## Learning Objectives

After completing this project, you will be able to:

- Understand the theoretical basis of the Standardized Precipitation Index
- Compute running precipitation sums at multiple timescales using CDO
- Apply gamma distribution fitting for accurate SPI computation
- Use CDO percentile-based approximation for rapid SPI estimation
- Identify and characterize drought events based on SPI thresholds
- Map drought severity and frequency spatially
- Analyze trends in drought frequency and intensity

## Theoretical Background

### What is SPI?

The Standardized Precipitation Index (McKee et al., 1993) quantifies precipitation deficits by standardizing accumulated precipitation at a given timescale. SPI values represent the number of standard deviations that observed cumulative precipitation deviates from the long-term median.

| SPI Value | Category | Description |
|-----------|----------|-------------|
| > 2.0 | Extremely wet | 
| 1.5 to 2.0 | Very wet |
| 1.0 to 1.5 | Moderately wet |
| -1.0 to 1.0 | Near normal |
| -1.0 to -1.5 | Moderately dry | Moderate drought |
| -1.5 to -2.0 | Severely dry | Severe drought |
| < -2.0 | Extremely dry | Extreme drought |

### Why Multiple Timescales?

- **SPI-1**: Agricultural drought, soil moisture response (weeks to 1 month)
- **SPI-3**: Short-term drought, crop stress (quarterly)
- **SPI-6**: Medium-term drought, streamflow, reservoir levels
- **SPI-12**: Long-term drought, groundwater, hydrological drought

## Data Requirements

| Attribute | Description |
|-----------|-------------|
| **Variable** | Monthly precipitation (mm/month) |
| **Minimum length** | 30 years (WMO standard) |
| **Recommended length** | 50+ years for robust distribution fitting |
| **Spatial resolution** | Any (CHIRPS, GPCC, CRU, or ERA5) |

```bash
# Use the real CHIRPS monthly precipitation supplied with the course
cdo sinfo ../datasets/chirps_ethiopia.nc

# Build the 3-, 6- and 12-month running sums needed for SPI
cdo runsum,3 ../datasets/chirps_ethiopia.nc chirps_3mon.nc
cdo runsum,6 ../datasets/chirps_ethiopia.nc chirps_6mon.nc
cdo runsum,12 ../datasets/chirps_ethiopia.nc chirps_12mon.nc
```

## Step-by-Step Workflow

### Approach A: CDO-Based SPI Approximation (Z-Score Method)

This method approximates SPI using standardized anomalies (Z-scores) of accumulated precipitation. It is faster but less accurate than gamma-based SPI for extreme values.

#### Step 1: Compute Running Precipitation Sums

```bash
# SPI-1 (1-month accumulation = original data)
cp monthly_precip.nc spi1_data.nc

# SPI-3 (3-month running sum)
cdo -O runsum,3 monthly_precip.nc spi3_data.nc

# SPI-6 (6-month running sum)
cdo -O runsum,6 monthly_precip.nc spi6_data.nc

# SPI-12 (12-month running sum)
cdo -O runsum,12 monthly_precip.nc spi12_data.nc

# SPI-24 (2-year accumulation for hydrological drought)
cdo -O runsum,24 monthly_precip.nc spi24_data.nc
```

```{note}
The `runsum` operator computes a running sum over N timesteps. The first N-1 timesteps will have incomplete accumulations — consider removing them or using `--timestep_date first`.
```

#### Step 2: Compute Climatology and Standard Deviation

For each timescale, compute the monthly climatology (mean) and standard deviation:

```bash
# For SPI-3
cdo -O ymonmean spi3_data.nc spi3_clim.nc
cdo -O ymonstd spi3_data.nc spi3_std.nc

# For SPI-6
cdo -O ymonmean spi6_data.nc spi6_clim.nc
cdo -O ymonstd spi6_data.nc spi6_std.nc

# For SPI-12
cdo -O ymonmean spi12_data.nc spi12_clim.nc
cdo -O ymonstd spi12_data.nc spi12_std.nc

# For SPI-24
cdo -O ymonmean spi24_data.nc spi24_clim.nc
cdo -O ymonstd spi24_data.nc spi24_std.nc
```

#### Step 3: Compute SPI (Z-Score Approximation)

```bash
# SPI-3: (accumulated - mean) / std
cdo -O sub spi3_data.nc spi3_clim.nc spi3_anom.nc
cdo -O div spi3_anom.nc spi3_std.nc spi3_zscore.nc

# SPI-6
cdo -O sub spi6_data.nc spi6_clim.nc spi6_anom.nc
cdo -O div spi6_anom.nc spi6_std.nc spi6_zscore.nc

# SPI-12
cdo -O sub spi12_data.nc spi12_clim.nc spi12_anom.nc
cdo -O div spi12_anom.nc spi12_std.nc spi12_zscore.nc
```

#### Step 4: Identify Drought Events

```bash
# Define drought thresholds
# Moderate drought: SPI < -1.0
cdo -O ltc,-1.0 spi12_zscore.nc moderate_drought.nc

# Severe drought: SPI < -1.5
cdo -O ltc,-1.5 spi12_zscore.nc severe_drought.nc

# Extreme drought: SPI < -2.0
cdo -O ltc,-2.0 spi12_zscore.nc extreme_drought.nc

# Drought months per year
cdo -O yearsum moderate_drought.nc drought_months_per_year.nc
cdo -O yearsum severe_drought.nc severe_months_per_year.nc

# Total drought months over the record
cdo -O timsum moderate_drought.nc total_drought.nc
cdo -O div total_drought.nc -ntime spi12_zscore.nc drought_fraction.nc
```

### Approach B: Percentile-Based SPI

An alternative approach uses percentile thresholds to map to SPI values:

```bash
# Compute percentile thresholds for each calendar month
cdo -O ydaypctl,2.3 spi12_data.nc spi12_p2.nc -ydaymin spi12_data.nc -ydaymax spi12_data.nc
cdo -O ydaypctl,15.9 spi12_data.nc spi12_p16.nc -ydaymin spi12_data.nc -ydaymax spi12_data.nc
cdo -O ydaypctl,84.1 spi12_data.nc spi12_p84.nc -ydaymin spi12_data.nc -ydaymax spi12_data.nc
cdo -O ydaypctl,97.7 spi12_data.nc spi12_p98.nc -ydaymin spi12_data.nc -ydaymax spi12_data.nc

# Map to SPI categories
# SPI < -2: precip < P2.3
# SPI -2 to -1: P2.3 < precip < P15.9
# etc.
```

```{note}
The percentiles 2.3, 15.9, 84.1, and 97.7 correspond to -2, -1, +1, and +2 standard deviations in a normal distribution.
```

### Approach C: Full Gamma Distribution SPI (Python)

The most accurate SPI computation uses the gamma distribution. Use this Python script:

```python
"""
Full Gamma-based SPI computation using scipy.
Requires: numpy, scipy, xarray, netCDF4
"""
import numpy as np
import xarray as xr
from scipy.stats import gamma, norm
import warnings
warnings.filterwarnings("ignore")

def compute_spi_gamma(precip, timescale=3):
    """
    Compute SPI using gamma distribution fitting.

    Parameters:
    -----------
    precip : numpy array (time, lat, lon)
        Monthly precipitation data
    timescale : int
        Accumulation period in months

    Returns:
    --------
    spi : numpy array (time, lat, lon)
        SPI values
    """
    # Compute running sum
    from scipy.ndimage import uniform_filter1d
    accum = uniform_filter1d(precip, size=timescale, mode="constant",
                             axis=0, origin=-(timescale//2)) * timescale

    # Adjust for incomplete accumulations
    accum[:timescale-1] = np.nan

    # Fit gamma distribution for each grid cell and month
    nt, nlat, nlon = accum.shape
    spi = np.full_like(accum, np.nan)

    for i in range(nlat):
        for j in range(nlon):
            ts = accum[:, i, j]
            if np.sum(np.isfinite(ts)) < 12:
                continue

            for m in range(12):
                # Select values for this calendar month
                month_indices = np.arange(m, nt, 12)
                month_data = ts[month_indices]
                month_data = month_data[np.isfinite(month_data)]

                if len(month_data) < 10:
                    continue

                # Fit gamma distribution
                try:
                    # Remove zeros for fitting
                    non_zero = month_data[month_data > 0]
                    if len(non_zero) < 5:
                        spi[month_indices, i, j] = -2.0  # extreme drought
                        continue

                    alpha, loc, beta = gamma.fit(non_zero, floc=0)
                    # Compute CDF for all values
                    cdf = gamma.cdf(month_data, alpha, loc=loc, scale=beta)
                    # Handle zeros
                    p_zero = np.mean(month_data == 0)
                    if p_zero > 0:
                        cdf = p_zero + (1 - p_zero) * cdf
                    # Clip to avoid infinity
                    cdf = np.clip(cdf, 0.0001, 0.9999)
                    # Transform to standard normal
                    spi[month_indices, i, j] = norm.ppf(cdf)
                except Exception:
                    continue

    return spi

# Load precipitation data
ds = xr.open_dataset("monthly_precip.nc")
precip_var = list(ds.data_vars)[0]
precip = ds[precip_var].values

# Compute SPI at different timescales
for ts in [1, 3, 6, 12, 24]:
    print(f"Computing SPI-{ts}...")
    spi_values = compute_spi_gamma(precip, timescale=ts)

    # Save to NetCDF
    ds_out = ds.copy()
    ds_out[precip_var].values = spi_values
    ds_out.to_netcdf(f"spi_{ts}_gamma.nc")
    print(f"  Saved: spi_{ts}_gamma.nc")

print("Gamma SPI computation complete.")
```

### Step 5: Spatial Analysis of Drought

```bash
# Map mean SPI over entire period
cdo -O timmean spi12_zscore.nc mean_spi12.nc

# Map minimum SPI (most extreme drought)
cdo -O timmin spi12_zscore.nc min_spi12.nc

# Number of drought events (SPI < -1 for 3+ consecutive months)
# First identify drought months
cdo -O ltc,-1.0 spi12_zscore.nc drought_mask.nc

# Use runsum to find consecutive drought months
cdo -O runsum,3 drought_mask.nc drought3consec.nc
cdo -O gec,3 drought3consec.nc drought_events.nc

# Drought event frequency
cdo -O yearsum drought_events.nc drought_events_per_year.nc

# Export spatial drought frequency
cdo -O output -fldmean drought_events_per_year.nc
```

### Step 6: Regional Drought Time Series

```bash
# Extract regional average SPI
cdo -O fldmean spi3_zscore.nc regional_spi3.nc
cdo -O fldmean spi6_zscore.nc regional_spi6.nc
cdo -O fldmean spi12_zscore.nc regional_spi12.nc

# Export time series
cdo output regional_spi3.nc > spi3_timeseries.csv
cdo output regional_spi12.nc > spi12_timeseries.csv

# Identify drought periods from time series
python << 'EOF'
import numpy as np

spi = np.loadtxt("spi12_timeseries.csv")
# Find consecutive drought periods
drought = spi < -1.0
changes = np.diff(np.concatenate(([0], drought.astype(int), [0])))
starts = np.where(changes == 1)[0]
ends = np.where(changes == -1)[0]
durations = ends - starts

print("Drought Events (SPI-12 < -1.0):")
print(f"{'Start':<10} {'End':<10} {'Duration':<10} {'Min SPI':<10}")
print("-" * 40)

# If you have year information
years = np.arange(1970, 1970 + len(spi) // 12)
for i, (s, e) in enumerate(zip(starts, ends)):
    duration = e - s
    min_spi = np.min(spi[s:e])
    start_year = years[s // 12] if s // 12 < len(years) else 0
    end_year = years[(e-1) // 12] if (e-1) // 12 < len(years) else 0
    if duration >= 3:  # Only events lasting 3+ months
        print(f"{start_year:<10} {end_year:<10} {duration:<10} {min_spi:<10.2f}")
EOF
```

### Step 7: Visualization

#### SPI Time Series Comparison (Python)

```python
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# Load SPI time series
spi3 = pd.read_csv("spi3_timeseries.csv", header=None, names=["spi3"], sep=r"\s+")
spi6 = pd.read_csv("spi6_timeseries.csv", header=None, names=["spi6"], sep=r"\s+")
spi12 = pd.read_csv("spi12_timeseries.csv", header=None, names=["spi12"], sep=r"\s+")

# Create date range
start_date = "1970-01"
dates = pd.date_range(start=start_date, periods=len(spi3), freq="MS")

fig, axes = plt.subplots(3, 1, figsize=(16, 10), sharex=True)

for ax, data, title, color in zip(
    axes,
    [spi3["spi3"], spi6["spi6"], spi12["spi12"]],
    ["SPI-1 (Agricultural Drought)", "SPI-6 (Hydrological Drought)",
     "SPI-12 (Long-term Drought)"],
    ["orange", "steelblue", "crimson"]
):
    ax.fill_between(dates, data, 0, where=(data >= 0),
                    color="blue", alpha=0.3, label="Wet")
    ax.fill_between(dates, data, 0, where=(data < 0),
                    color="red", alpha=0.3, label="Dry")

    # Drought thresholds
    ax.axhline(-1.0, color="orange", linestyle="--", alpha=0.7, label="Moderate")
    ax.axhline(-1.5, color="red", linestyle="--", alpha=0.7, label="Severe")
    ax.axhline(-2.0, color="darkred", linestyle="--", alpha=0.7, label="Extreme")
    ax.axhline(0, color="black", linewidth=0.5)

    ax.plot(dates, data, color=color, linewidth=0.8)
    ax.set_ylabel("SPI")
    ax.set_title(title, fontweight="bold")
    ax.grid(alpha=0.3)
    ax.set_ylim(-3.5, 3.5)

axes[-1].set_xlabel("Date")
plt.suptitle("Standardized Precipitation Index (SPI) at Multiple Timescales",
             fontsize=14, fontweight="bold")
plt.tight_layout()
plt.savefig("spi_multi_timescale.png", dpi=200, bbox_inches="tight")
print("Figure saved: spi_multi_timescale.png")
```

#### Drought Severity Map (Python)

```python
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import numpy as np

min_spi = xr.open_dataset("min_spi12.nc")
freq = xr.open_dataset("drought_fraction.nc")

spi_var = list(min_spi.data_vars)[0]
freq_var = list(freq.data_vars)[0]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7),
                                 subplot_kw={"projection": ccrs.PlateCarree()})

# Minimum SPI (most extreme drought)
im1 = ax1.contourf(min_spi.lon, min_spi.lat, min_spi[spi_var],
                    levels=np.linspace(-3, 0, 13),
                    transform=ccrs.PlateCarree(), cmap="YlOrRd", extend="min")
ax1.add_feature(cfeature.COASTLINE, linewidth=0.5)
ax1.add_feature(cfeature.BORDERS, linewidth=0.3, alpha=0.5)
ax1.set_title("Minimum SPI-12 (Most Extreme Drought)")
cbar1 = plt.colorbar(im1, ax=ax1, orientation="horizontal", pad=0.05,
                     label="SPI")

# Drought frequency
im2 = ax2.contourf(freq.lon, freq.lat, freq[freq_var] * 100,
                    levels=np.linspace(0, 30, 11),
                    transform=ccrs.PlateCarree(), cmap="YlOrRd")
ax2.add_feature(cfeature.COASTLINE, linewidth=0.5)
ax2.add_feature(cfeature.BORDERS, linewidth=0.3, alpha=0.5)
ax2.set_title("Drought Frequency (% months with SPI < -1)")
cbar2 = plt.colorbar(im2, ax=ax2, orientation="horizontal", pad=0.05,
                     label="%")

plt.tight_layout()
plt.savefig("drought_severity_map.png", dpi=200, bbox_inches="tight")
print("Figure saved: drought_severity_map.png")
```

#### Drought Event Timeline (Python)

```python
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

spi12 = pd.read_csv("spi12_timeseries.csv", header=None, names=["spi12"],
                    sep=r"\s+")
dates = pd.date_range(start="1970-01", periods=len(spi12), freq="MS")

# Categorize each month
categories = np.zeros(len(spi12), dtype=int)
categories[spi12["spi12"] < -2.0] = -3  # Extreme drought
categories[(spi12["spi12"] >= -2.0) & (spi12["spi12"] < -1.5)] = -2  # Severe
categories[(spi12["spi12"] >= -1.5) & (spi12["spi12"] < -1.0)] = -1  # Moderate
categories[(spi12["spi12"] > 1.0) & (spi12["spi12"] <= 1.5)] = 1   # Moderate wet
categories[(spi12["spi12"] > 1.5) & (spi12["spi12"] <= 2.0)] = 2   # Very wet
categories[spi12["spi12"] > 2.0] = 3  # Extreme wet

colors = ["darkred", "red", "orange", "lightgray", "lightblue", "blue", "darkblue"]
labels = ["Extreme Drought", "Severe Drought", "Moderate Drought", "Near Normal",
          "Moderately Wet", "Very Wet", "Extremely Wet"]

fig, ax = plt.subplots(figsize=(18, 4))

for i, (cat, color, label) in enumerate(zip([-3, -2, -1, 0, 1, 2, 3],
                                              colors, labels)):
    mask = categories == cat if cat != 0 else categories == 0
    ax.fill_between(dates, -3 if cat < 0 else 0, 3 if cat > 0 else 0,
                    where=mask, color=color, alpha=0.9,
                    label=label if label != "Near Normal" else "")

ax.axhline(0, color="black", linewidth=0.5)
ax.set_ylabel("Drought Category")
ax.set_xlabel("Year")
ax.set_title("Drought Timeline from SPI-12")
ax.set_ylim(-3.5, 3.5)
ax.set_yticks([-2, 0, 2])
ax.grid(alpha=0.3, axis="x")

# Legend
from matplotlib.patches import Patch
legend_elements = [Patch(facecolor=c, alpha=0.9, label=l)
                   for c, l in zip(colors, labels) if l != "Near Normal"]
ax.legend(handles=legend_elements, loc="upper right", ncol=3, fontsize=8)

plt.tight_layout()
plt.savefig("drought_timeline.png", dpi=200, bbox_inches="tight")
print("Figure saved: drought_timeline.png")
```

## Complete Bash Workflow Script

Save as `spi_analysis.sh`:

```bash
#!/bin/bash
# =============================================================================
# SPI Drought Index Computation Pipeline
# Climate Data Operators (CDO) Training
# =============================================================================
set -euo pipefail

# Configuration
INPUT_DATA="monthly_precip.nc"
OUTPUT_DIR="spi_output"
mkdir -p "$OUTPUT_DIR"

echo "=== SPI Computation ==="
echo "Input: $INPUT_DATA"
echo "========================="

# Step 1: Remove incomplete years at start (for runsum)
echo "[1/6] Preparing data..."
cdo -O -s selyear,1972/2020 "$INPUT_DATA" "$OUTPUT_DIR/precip_clean.nc"

# Step 2: Compute running sums
echo "[2/6] Computing running sums..."
cdo -O -s runsum,3 "$OUTPUT_DIR/precip_clean.nc" "$OUTPUT_DIR/accum3.nc"
cdo -O -s runsum,6 "$OUTPUT_DIR/precip_clean.nc" "$OUTPUT_DIR/accum6.nc"
cdo -O -s runsum,12 "$OUTPUT_DIR/precip_clean.nc" "$OUTPUT_DIR/accum12.nc"
cdo -O -s runsum,24 "$OUTPUT_DIR/precip_clean.nc" "$OUTPUT_DIR/accum24.nc"

# Step 3: Compute monthly climatology and std for each timescale
echo "[3/6] Computing climatology..."
for ts in 3 6 12 24; do
    cdo -O -s ymonmean "$OUTPUT_DIR/accum${ts}.nc" "$OUTPUT_DIR/clim_${ts}.nc"
    cdo -O -s ymonstd "$OUTPUT_DIR/accum${ts}.nc" "$OUTPUT_DIR/std_${ts}.nc"
done

# Step 4: Compute SPI (Z-score method)
echo "[4/6] Computing SPI indices..."
for ts in 3 6 12 24; do
    cdo -O -s sub "$OUTPUT_DIR/accum${ts}.nc" "$OUTPUT_DIR/clim_${ts}.nc" \
        "$OUTPUT_DIR/anom_${ts}.nc"
    cdo -O -s div "$OUTPUT_DIR/anom_${ts}.nc" "$OUTPUT_DIR/std_${ts}.nc" \
        "$OUTPUT_DIR/spi_${ts}.nc"
done

# Step 5: Drought identification
echo "[5/6] Identifying drought events..."
for ts in 3 6 12 24; do
    cdo -O -s ltc,-1.0 "$OUTPUT_DIR/spi_${ts}.nc" \
        "$OUTPUT_DIR/drought_mod_${ts}.nc"
    cdo -O -s ltc,-1.5 "$OUTPUT_DIR/spi_${ts}.nc" \
        "$OUTPUT_DIR/drought_sev_${ts}.nc"
    cdo -O -s ltc,-2.0 "$OUTPUT_DIR/spi_${ts}.nc" \
        "$OUTPUT_DIR/drought_ext_${ts}.nc"
    cdo -O -s timsum "$OUTPUT_DIR/drought_mod_${ts}.nc" \
        "$OUTPUT_DIR/total_drought_${ts}.nc"
    cdo -O -s fldmean "$OUTPUT_DIR/spi_${ts}.nc" \
        "$OUTPUT_DIR/regional_spi_${ts}.nc"
done

# Step 6: Export time series
echo "[6/6] Exporting data..."
for ts in 3 6 12 24; do
    cdo -s output "$OUTPUT_DIR/regional_spi_${ts}.nc" \
        > "$OUTPUT_DIR/spi${ts}_timeseries.csv"
done

# Summary statistics
echo "=== Summary ==="
echo "SPI-12 mean: $(cdo -s output -fldmean -timmean "$OUTPUT_DIR/spi_12.nc")"
echo "Drought fraction: $(cdo -s output -fldmean -timmean "$OUTPUT_DIR/drought_mod_12.nc")"
echo "Sample SPI-12 values: $(cdo -s output -fldmean "$OUTPUT_DIR/spi_12.nc" | head -5)"
echo "==================="
```

## Expected Outputs

### 1. Multi-Timescale SPI Time Series
Three-panel plot showing SPI-1, SPI-6, and SPI-12 with:
- Color-coded wet/dry periods
- Drought threshold lines (-1, -1.5, -2)
- Clear labeling of major drought events

### 2. Drought Severity and Frequency Maps
Spatial maps showing:
- Minimum SPI value over the record (most extreme drought)
- Percentage of months with drought conditions
- Spatial patterns in drought vulnerability

### 3. Drought Event Timeline
Color-coded timeline showing drought categories through time:
- Quick visual identification of drought periods
- Comparison of drought severity across decades

### 4. Drought Event Table
| Event # | Start Year | End Year | Duration (months) | Min SPI | Category |
|---------|------------|----------|-------------------|---------|----------|
| 1 | 1984 | 1985 | 14 | -2.3 | Extreme |
| 2 | 1991 | 1992 | 8 | -1.8 | Severe |
| 3 | ... | ... | ... | ... | ... |

## Interpretation Guidance

### What to Look For

1. **Timescale response**: Short-term SPI fluctuates rapidly; long-term SPI shows sustained dry/wet periods
2. **Drought onset**: Watch for SPI dropping below -1 and persisting
3. **Recovery**: Drought ends when SPI returns to positive values
4. **Frequency changes**: Are droughts becoming more frequent or severe in recent decades?
5. **Spatial coherence**: Do large-scale droughts affect entire regions simultaneously?

### Key Questions

- Which drought event was most severe in terms of duration? Minimum SPI?
- How do SPI-3 and SPI-12 compare in detecting the same drought event?
- Is there a trend toward more frequent or intense droughts?
- Which regions in your study area are most drought-prone?

### Limitations of the Z-Score Method

```{warning}
The Z-score approximation assumes precipitation follows a normal distribution. Precipitation is typically gamma-distributed (positively skewed, bounded at zero). The gamma-based approach (Approach C) is preferred for:
- Accurate representation of extreme drought/wet events
- Regions with highly skewed precipitation distributions
- Scientific publications and operational drought monitoring
```

## Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Understanding SPI | 15% | Correct interpretation of SPI theory and timescales |
| CDO workflow | 25% | Proper use of runsum, ymonmean, ymonstd, and arithmetic operators |
| Drought identification | 20% | Correct threshold application and event detection |
| Z-score methodology | 15% | Understanding limitations vs. gamma-based approach |
| Visualization | 15% | Clear time series, maps, and event tables |
| Interpretation | 10% | Insightful analysis of drought patterns |

## Extension Activities

### Advanced Options

1. **SPI for climate change detection**: Analyze trends in SPI values over time
2. **SPEI (Standardized Precipitation-Evapotranspiration Index)**: Incorporate temperature for drought computation considering PET
3. **Drought return period analysis**: Fit extreme value distributions to drought characteristics
4. **Agricultural drought impact**: Correlate SPI with crop yield data

```bash
# Example: Trend in drought frequency
cdo -O trend "$OUTPUT_DIR/drought_months_per_year.nc" \
    "$OUTPUT_DIR/drought_trend_intercept.nc" \
    "$OUTPUT_DIR/drought_trend_slope.nc"
```

### Cross-Project Integration

- Use CHIRPS data processed in **Project 1** for SPI computation
- Compare drought patterns with temperature extremes from **Project 4**
- Include drought analysis in the automated report from **Project 8**

```{exercise}
Complete the drought index analysis. Compute SPI-1, SPI-3, SPI-6, and SPI-12 for your region. Identify the three most severe drought events in the record. Compare SPI-3 to SPI-12 — which detects drought earlier? Which is more useful for water resource management?
```

## References

- McKee, T.B., Doesken, N.J., & Kleist, J. (1993). The relationship of drought frequency and duration to time scales. 8th Conference on Applied Climatology, 179-184.
- Svoboda, M., Hayes, M., & Wood, D. (2012). Standardized Precipitation Index User Guide. WMO-No. 1090.
- Guttman, N.B. (1999). Accepting the standardized precipitation index. Journal of the American Water Resources Association, 35(2), 311-322.
- CDO Documentation: https://code.mpimet.mpg.de/projects/cdo
