# Exercise 3: Temporal Analysis

## Objectives
- Compute daily, monthly, seasonal, and annual means
- Calculate climatology
- Compute and visualize anomalies
- Apply running means with different window sizes

## Prerequisites
- `tas_sample.nc` in `datasets/`
- Python with matplotlib (or PyGMT) for visualization

---

## Task 1: Compute Time Averages at Different Scales

### Instructions
Compute multiple temporal means from `tas_sample.nc`.

```bash
# Monthly means
cdo monmean ../datasets/tas_sample.nc tas_monmean.nc

# Seasonal means
cdo seasmean ../datasets/tas_sample.nc tas_seasmean.nc

# Annual means
cdo yearmean ../datasets/tas_sample.nc tas_yearmean.nc
```

### Questions
1. How do the file sizes compare between monmean, seasmean, and yearmean? Why?
2. How are seasons defined by CDO? (Which months go into DJF, MAM, JJA, SON?)
3. What operator would you use for daily means?
4. What is the difference between `monmean` and `monsum`?

---

## Task 2: Calculate Climatology

### Instructions
1. Compute the monthly climatology for the full period:
   ```bash
   cdo ymonmean ../datasets/tas_sample.nc tas_climatology.nc
   ```
2. Compute the seasonal climatology:
   ```bash
   cdo yseasmean ../datasets/tas_sample.nc tas_seasclim.nc
   ```
3. Compute the annual climatology:
   ```bash
   cdo yearmean ../datasets/tas_sample.nc tas_yearclim.nc
   ```

### Questions
1. How many time steps does `tas_climatology.nc` have? Why?
2. How does `ymonmean` differ from `monmean`?
3. What is `yseasmean` and what does it produce?
4. If your data spans 30 years, what does `ymonmean` compute?

---

## Task 3: Compute and Visualize Anomalies

### Instructions
1. Compute monthly anomalies by subtracting the climatology:
   ```bash
   cdo ymonsub ../datasets/tas_sample.nc tas_climatology.nc tas_anomalies.nc
   ```
2. Compute the global mean anomaly time series:
   ```bash
   cdo fldmean tas_anomalies.nc tas_global_anomaly.nc
   ```
3. View the time series:
   ```bash
   cdo outputts tas_global_anomaly.nc | head -20
   ```

### Questions
1. What do positive and negative anomaly values represent?
2. Why do we use `ymonsub` rather than `sub`?
3. What does `fldmean` do and why is it needed before plotting?
4. Plot the anomalies using Python:
   ```python
   import xarray as xr
   import matplotlib.pyplot as plt
   ds = xr.open_dataset('tas_global_anomaly.nc')
   ds['tas'].plot()
   plt.savefig('anomaly_timeseries.png')
   ```

---

## Task 4: Apply Running Means

### Instructions
Apply different running mean windows to smooth the data:

```bash
# 3-month running mean
cdo runmean,3 ../datasets/tas_sample.nc tas_runmean3.nc

# 5-month running mean
cdo runmean,5 ../datasets/tas_sample.nc tas_runmean5.nc

# 12-month running mean
cdo runmean,12 ../datasets/tas_sample.nc tas_runmean12.nc
```

### Questions
1. What happens to the time series length when you apply a running mean?
2. How does the smoothing change as the window size increases?
3. What is the difference between `runmean`, `runsum`, and `runstd`?
4. Try a 3-month running **sum** on precipitation data – what would this represent?
5. Plot all three running means on the same figure to compare smoothing levels.

---

## Bonus Challenge

Create a single-panel figure showing:
- Raw monthly global mean temperature as a thin grey line
- 12-month running mean as a thick red line
- Climatology as a dashed blue line

Use xarray or matplotlib. Include a legend.

---

## Deliverables
- All computed NetCDF files
- Anomaly time series plot (`anomaly_timeseries.png`)
- Running mean comparison plot
- Written answers to all questions
