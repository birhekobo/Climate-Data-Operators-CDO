# Solution 3: Temporal Analysis

## Task 1: Compute Time Averages at Different Scales

### Commands:
```bash
cdo monmean ../datasets/tas_sample.nc tas_monmean.nc
cdo seasmean ../datasets/tas_sample.nc tas_seasmean.nc
cdo yearmean ../datasets/tas_sample.nc tas_yearmean.nc
```

### Answers:
1. **File size comparison:** `yearmean` < `seasmean` < `monmean`.
   - monmean: 372 → 372 steps (same as input, since input is already monthly)
   - seasmean: 372 → 124 steps (4 seasons × 31 years)
   - yearmean: 372 → 31 steps (1 per year)
2. **Season definition in CDO:** DJF (Dec–Feb), MAM (Mar–May), JJA (Jun–Aug), SON (Sep–Nov). December of the previous year is included with DJF of the current year.
3. **Daily means:** `cdo daymean` — but this only works if the input has sub-daily resolution.
4. **`monmean` vs `monsum`:**
   - `monmean`: average of all values in each month
   - `monsum`: sum of all values in each month (useful for precipitation totals)

---

```{figure} ../assets/sol03_task1_time_averages.png
:name: fig-sol03-1

Time-step counts for monthly, seasonal and annual means, with monthly vs annual series from real reanalysis data.
```

## Task 2: Calculate Climatology

### Commands:
```bash
cdo ymonmean ../datasets/tas_sample.nc tas_climatology.nc
cdo yseasmean ../datasets/tas_sample.nc tas_seasclim.nc
cdo yearmean ../datasets/tas_sample.nc tas_yearclim.nc
```

### Answers:
1. **Time steps in climatology:** 12 (one per month). `ymonmean` collapses all years into a 12-month cycle.
2. **`ymonmean` vs `monmean`:**
   - `monmean`: Computes one mean per month in the time series (e.g., 372 values for 31 years)
   - `ymonmean`: Computes the **multi-year average for each calendar month** (e.g., Jan average = mean of all 31 Januaries) → 12 values total
3. **`yseasmean`:** Computes the multi-year average for each season — produces 4 values (DJF, MAM, JJA, SON).
4. **For 30 years of data:** `ymonmean` computes the average of all Januarys, all Februarys, etc. → 12 monthly climatology values.

---

```{figure} ../assets/sol03_task2_climatology.png
:name: fig-sol03-2

The 12-month climatology from `ymonmean` and the four-season climatology from `yseasmean`, computed from real data.
```

## Task 3: Compute and Visualize Anomalies

### Commands:
```bash
cdo ymonsub ../datasets/tas_sample.nc tas_climatology.nc tas_anomalies.nc
cdo fldmean tas_anomalies.nc tas_global_anomaly.nc
cdo outputts tas_global_anomaly.nc | head -20
```

### Example output:
```
# Field mean of variable tas [K]
# Date           Value
1980-01-01       -0.23
1980-02-01        0.15
1980-03-01       -0.08
...
```

### Answers:
1. **Positive/negative anomalies:** Positive = warmer than the climatological average; negative = cooler.
2. **Why `ymonsub` instead of `sub`:** `ymonsub` subtracts the **monthly climatology** (the 12-month cycle), so January values are compared against the January climatology, etc. `sub` would just subtract the first time step from the second, which is not meaningful for anomaly calculation.
3. **Purpose of `fldmean`:** It reduces the spatial field to a single global mean value per time step, making it possible to plot a 1-D time series.
4. **Python plot:**
   ```python
   import xarray as xr; import matplotlib.pyplot as plt
   ds = xr.open_dataset('tas_global_anomaly.nc')
   ds['tas'].plot()
   plt.savefig('anomaly_timeseries.png')
   ```

---

```{figure} ../assets/sol03_task3_anomalies.png
:name: fig-sol03-3

Global temperature anomalies computed with `ymonsub` and `fldmean` from real reanalysis data.
```

## Task 4: Apply Running Means

### Commands:
```bash
cdo runmean,3 ../datasets/tas_sample.nc tas_runmean3.nc
cdo runmean,5 ../datasets/tas_sample.nc tas_runmean5.nc
cdo runmean,12 ../datasets/tas_sample.nc tas_runmean12.nc
```

### Answers:
1. **Effect on time series length:** The series is shortened by `N-1` time steps, where `N` is the window size. A 3-month running mean loses 2 steps (1 at start, 1 at end): 372 → 370 steps.
2. **Smoothing vs window size:** Larger windows produce smoother series but lose more short-term variability and more data at the edges.
3. **`runmean` vs `runsum` vs `runstd`:**
   - `runmean`: running average (smoothed)
   - `runsum`: running total (e.g., 3-month precipitation accumulation)
   - `runstd`: running standard deviation (measure of variability)
4. **3-month running sum on precipitation:** Represents a 3-month accumulated precipitation, which is the basis for the Standardized Precipitation Index (SPI-3).

### Python code for comparison plot:
```python
import xarray as xr; import matplotlib.pyplot as plt

raw = xr.open_dataset('../datasets/tas_sample.nc')
rm3 = xr.open_dataset('tas_runmean3.nc')
rm12 = xr.open_dataset('tas_runmean12.nc')

plt.figure(figsize=(12, 4))
plt.plot(raw.time, raw.tas[:, 90, 180], 'grey', lw=0.5, label='Raw (grid cell)')
plt.plot(rm3.time, rm3.tas[:, 90, 180], 'orange', lw=1, label='3-month runmean')
plt.plot(rm12.time, rm12.tas[:, 90, 180], 'red', lw=2, label='12-month runmean')
plt.legend(); plt.grid(alpha=0.3); plt.tight_layout()
plt.savefig('running_means_comparison.png', dpi=150)
```

```{figure} ../assets/sol03_task4_running_means.png
:name: fig-sol03-4

Raw monthly series compared with 3-, 5- and 12-month running means (real reanalysis data).
```

