# Exercise 5: Statistics and Climate Indices

## Objectives
- Compute basic statistics (mean, median, std, percentiles)
- Calculate frost days and tropical nights
- Compute consecutive dry/wet days (CDD/CWD)
- Create histograms of precipitation

## Prerequisites
- `tas_sample.nc` and `pr_sample.nc` in `datasets/`
- Python with matplotlib for histograms

---

## Task 1: Basic Statistics

### Instructions
Compute statistical properties of the temperature field:

```bash
# Time mean
cdo timmean ../datasets/tas_sample.nc tas_timmean.nc

# Time standard deviation
cdo timstd ../datasets/tas_sample.nc tas_timstd.nc

# Time minimum and maximum
cdo timmin ../datasets/tas_sample.nc tas_timmin.nc
cdo timmax ../datasets/tas_sample.nc tas_timmax.nc

# Percentiles
cdo timpctl,10 ../datasets/tas_sample.nc tas_timmin.nc tas_timmax.nc tas_p10.nc
cdo timpctl,50 ../datasets/tas_sample.nc tas_timmin.nc tas_timmax.nc tas_p50.nc
cdo timpctl,90 ../datasets/tas_sample.nc tas_timmin.nc tas_timmax.nc tas_p90.nc
```

### Questions
1. What are the three required inputs for `timpctl`? Why is the min/max needed?
2. What operator would you use for the **median**?
3. How do you compute spatial percentiles (across grid cells at one time)?
4. What is the difference between `timmean` and `fldmean`?

---

## Task 2: Frost Days and Tropical Nights

### Instructions
Frost days are defined as days when `tas < 273.15 K` (0°C).
Tropical nights are defined as days when `tas > 293.15 K` (20°C).

For **daily** data you would use comparison operators directly.
With **monthly** data, approximate these indices:

```bash
# Count months with mean temperature below 273.15 K
cdo lt,273.15 ../datasets/tas_sample.nc tas_below_0C.nc
cdo yearsum tas_below_0C.nc tas_frost_months.nc

# Count months with mean temperature above 293.15 K
cdo gt,293.15 ../datasets/tas_sample.nc tas_above_20C.nc
cdo yearsum tas_above_20C.nc tas_tropical_months.nc
```

### Questions
1. Why would monthly data give a biased estimate of frost days?
2. How could you get a more accurate count of frost days from the available data?
3. What operator counts consecutive days below a threshold?
4. What temperature thresholds are used for:
   - Ice days
   - Summer days
   - Growing season length

---

## Task 3: Consecutive Dry Days (CDD) and Consecutive Wet Days (CWD)

### Instructions
CDD is the maximum number of consecutive days with `pr < 1 mm/day`.
CWD is the maximum number of consecutive days with `pr >= 1 mm/day`.

```bash
# Create dry-day mask (pr < 1 mm/day)
cdo lt,1.0 ../datasets/pr_sample.nc pr_dry.nc

# Create wet-day mask (pr >= 1 mm/day)
cdo ge,1.0 ../datasets/pr_sample.nc pr_wet.nc

# Consecutive dry days
cdo consects pr_dry.nc pr_cdd.nc

# Consecutive wet days
cdo consects pr_wet.nc pr_cwd.nc
```

### Questions
1. What does `consects` compute exactly? (Read the documentation)
2. How would you get the maximum CDD per year?
3. What threshold is typically used for wet days in climate science?
4. How does the CDD/CWD change if you use 0.1 mm/day instead of 1 mm/day?
5. Compare the `consects` output for dry vs. wet masks — which tends to have longer spells?

---

## Task 4: Create Histograms of Precipitation

### Instructions
Use Python to create a histogram of monthly precipitation values:

```python
import xarray as xr
import matplotlib.pyplot as plt
import numpy as np

# Load precipitation data
ds = xr.open_dataset('../datasets/pr_sample.nc')
pr = ds['pr'].values.flatten()

# Remove NaN / masked values
pr = pr[~np.isnan(pr)]

# Create histogram
plt.figure(figsize=(10, 5))
plt.hist(pr, bins=50, color='steelblue', edgecolor='white', alpha=0.7)
plt.xlabel('Precipitation (mm/day)')
plt.ylabel('Frequency')
plt.title('Histogram of Monthly Precipitation (Global)')
plt.grid(alpha=0.3)
plt.axvline(np.mean(pr), color='red', linestyle='--', label=f'Mean: {np.mean(pr):.2f}')
plt.axvline(np.median(pr), color='green', linestyle='--', label=f'Median: {np.median(pr):.2f}')
plt.legend()
plt.tight_layout()
plt.savefig('precip_histogram.png', dpi=150)
print('Saved precip_histogram.png')
```

### Questions
1. Why is the precipitation distribution positively skewed (right-skewed)?
2. What fraction of grid-month values are below 1 mm/day?
3. What is the 95th percentile of precipitation?
4. How does the distribution change if you only look at tropical vs. mid-latitude regions?

---

## Bonus Challenge

1. Compute the standardized precipitation index (SPI) for a 3-month accumulation period:
   ```bash
   cdo runsum,3 -monsum ../datasets/pr_sample.nc pr_runsum3.nc
   cdo sub pr_runsum3.nc -timmean pr_runsum3.nc pr_spi_anom.nc
   cdo div pr_spi_anom.nc -timstd pr_runsum3.nc pr_spi3.nc
   ```
2. Count how many months have `SPI < -1.0` (moderate drought).
3. Plot the SPI time series for a specific grid cell near your location.

---

## Deliverables
- Statistical fields (mean, std, percentiles)
- Frost/tropical month counts
- CDD and CWD fields
- Precipitation histogram (`precip_histogram.png`)
- Written answers to all questions
