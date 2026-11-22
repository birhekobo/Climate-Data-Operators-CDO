---
title: "Module 9: Statistical Operators"
subject: Climate Data Operators (CDO) Training
subtitle: Statistical Analysis of Climate Data
---

# Module 9: Statistical Operators

## Learning Objectives

After completing this module, you will be able to:

- Compute basic statistical measures (mean, median, min, max, sum, std, var, range) over any dimension
- Calculate ensemble statistics across multiple model runs or members
- Apply temporal statistics (time mean, time max, time std, time sum)
- Compute percentiles and histogram statistics
- Perform multi-model ensemble analysis
- Use statistics for climate data quality control

## Prerequisites

This module assumes you have completed Modules 1-8 and are comfortable with basic CDO commands, file operations, and data selection.

```{note}
You will need both single-file datasets and multi-file ensembles for the examples. The course data repository contains sample files including CMIP6-style output with multiple ensemble members.
```

```{figure} ../assets/fig_global_timeseries.png
:name: fig-statistics-timeseries

A real temperature time series used to demonstrate temporal statistics, anomalies, and trend analysis with CDO and Python.
```


## 9.1 Basic Statistics

Basic statistical operators in CDO compute aggregate values over the entire dataset, collapsing all dimensions.

### 9.1.1 Mean and Average

```bash
cdo mean temperature.nc mean_temp.nc
cdo avg temperature.nc avg_temp.nc
```

The `mean` and `avg` operators are identical — both compute the arithmetic mean over all grid points and time steps.

```{tip}
`mean` is the most commonly used CDO operator. It is often the final step in a pipeline, producing a single value or profile from a multidimensional field.
```

### 9.1.2 Median

```bash
cdo median temperature.nc median_temp.nc
```

The median is less sensitive to outliers than the mean. For skewed distributions (e.g., precipitation), the median can be more representative.

### 9.1.3 Maximum and Minimum

```bash
cdo max temperature.nc max_temp.nc           # global maximum
cdo min temperature.nc min_temp.nc           # global minimum
cdo fldmax temperature.nc max_per_time.nc     # spatial max at each time
cdo yearmax temperature.nc annual_max.nc      # annual maximum
cdo daymax temperature.nc daily_max.nc        # daily maximum
```

```{exercise}
:label: ex-statistics-1
Find the absolute maximum temperature in your dataset and determine when and where it occurs.
```

````{solution} ex-statistics-1
```bash
cdo output -max temperature.nc
cdo output -timmax -fldmax temperature.nc
```
Combine `fldmax` and `timmax` to find the spatial location and time of the absolute maximum.
````

### 9.1.4 Sum

```bash
cdo sum precipitation.nc total_precip.nc
cdo yearsum precipitation.nc annual_total.nc
cdo monsum precipitation.nc monthly_total.nc
```

```{warning}
The `sum` operator is dimension-dependent. For precipitation, `sum` over time gives total accumulation. For temperature, summing over time is rarely physically meaningful.
```

### 9.1.5 Standard Deviation and Variance

```bash
cdo std temperature.nc std_temp.nc           # population standard deviation
cdo var temperature.nc var_temp.nc           # population variance
```

For sample statistics (n-1 denominator):

```bash
cdo std1 temperature.nc std_sample.nc        # sample standard deviation
cdo var1 temperature.nc var_sample.nc        # sample variance
```

```{note}
CDO distinguishes between population statistics (`std`, `var`) and sample statistics (`std1`, `var1`). Population stats use N in the denominator; sample stats use N-1. For large climate datasets, the difference is negligible.
```

### 9.1.6 Range

```bash
cdo range temperature.nc range_temp.nc
```

The range is simply `max - min` and provides a quick measure of the total variability in the dataset.

### 9.1.7 Comparison of Basic Operators

| Operator   | Description              | Use Case                          |
|------------|--------------------------|-----------------------------------|
| `mean`     | Arithmetic mean          | Average temperature/pressure      |
| `avg`      | Alias for mean           | Same as mean                      |
| `median`   | Median (50th percentile) | Skewed distributions (precip)     |
| `max`      | Maximum value            | Extremes, peak temperature        |
| `min`      | Minimum value            | Extremes, minimum temperature     |
| `sum`      | Sum of values            | Total precipitation, accumulation |
| `std`      | Population std deviation | Variability (N denominator)       |
| `var`      | Population variance      | Variability squared (N denom)     |
| `std1`     | Sample std deviation     | Small sample variability          |
| `var1`     | Sample variance          | Small sample variance             |
| `range`    | Max minus min            | Total spread                      |

## 9.2 Ensemble Statistics

Ensemble operators combine multiple input files, computing statistics across the "ensemble member" dimension.

### 9.2.1 Ensemble Mean

```bash
cdo ensmean model1.nc model2.nc model3.nc ens_mean.nc
```

This computes the mean across all input files at each grid point and time step.

```{tip}
`ensmean` is widely used in climate science to compute multi-model ensemble means, which typically outperform any single model in forecast skill.
```

### 9.2.2 Other Ensemble Operators

```bash
cdo ensmax model1.nc model2.nc model3.nc ens_max.nc     # ensemble maximum
cdo ensmin model1.nc model2.nc model3.nc ens_min.nc     # ensemble minimum
cdo ensstd model1.nc model2.nc model3.nc ens_std.nc     # ensemble std dev
cdo ensvar model1.nc model2.nc model3.nc ens_var.nc     # ensemble variance
cdo ensrange model1.nc model2.nc model3.nc ens_range.nc # ensemble range
cdo ensmedian model1.nc model2.nc model3.nc ens_median.nc
```

### 9.2.3 Ensemble Spread Analysis

```bash
cdo ensmean m1.nc m2.nc m3.nc m4.nc m5.nc ens_mean.nc
cdo ensstd m1.nc m2.nc m3.nc m4.nc m5.nc ens_std.nc
cdo div ens_std.nc ens_mean.nc cv.nc      # coefficient of variation
```

```{note}
The ensemble spread (standard deviation) measures inter-model or inter-member uncertainty. A large spread indicates low confidence in the ensemble mean.
```

### 9.2.4 Ensemble Percentiles

Using `enspctl`:

```bash
cdo enspctl,10 m1.nc m2.nc m3.nc m4.nc m5.nc p10.nc  # 10th percentile
cdo enspctl,50 m1.nc m2.nc m3.nc m4.nc m5.nc p50.nc  # median
cdo enspctl,90 m1.nc m2.nc m3.nc m4.nc m5.nc p90.nc  # 90th percentile
```

```{exercise}
:label: ex-statistics-2
Compute the ensemble mean, 10th percentile, and 90th percentile from 10 ensemble members. Visualize the spread as a shaded region in a time series plot.
```

````{solution} ex-statistics-2
```bash
cdo ensmean mem01.nc mem02.nc mem03.nc mem04.nc mem05.nc \
         mem06.nc mem07.nc mem08.nc mem09.nc mem10.nc ens_mean.nc
cdo enspctl,10 mem*.nc p10.nc
cdo enspctl,90 mem*.nc p90.nc
```
The 10th-90th percentile range characterizes the ensemble spread and can be plotted as a shaded envelope around the ensemble mean.
````

### 9.2.5 Wildcard Processing

For many ensemble members, use wildcards:

```bash
cdo ensmean member_*.nc ensemble_mean.nc
```

```{warning}
When using wildcards, ensure the files are sorted correctly. CDO processes them in alphabetical order. For numeric sorting (member_01, member_02, ... member_10), use leading zeros in filenames.
```

## 9.3 Multi-Variable (Temporal) Statistics

Temporal operators compute statistics along the time dimension only, preserving spatial structure.

### 9.3.1 Time Mean

```bash
cdo timmean temperature.nc clim_mean.nc
```

This is equivalent to `mean` but only collapses the time dimension, leaving spatial dimensions intact.

```bash
cdo timmean monthly_data.nc monthly_clim.nc          # mean over all months
cdo timmean -selmonth,1 monthly_data.nc jan_clim.nc  # mean January only
```

### 9.3.2 Time Max, Min, and Sum

```bash
cdo timmax temperature.nc max_at_each_grid.nc         # max at each grid point
cdo timmin temperature.nc min_at_each_grid.nc         # min at each grid point
cdo timsum precipitation.nc total_at_each_grid.nc     # accumulation at each point
```

### 9.3.3 Time Standard Deviation and Variance

```bash
cdo timstd temperature.nc interannual_std.nc          # temporal std
cdo timvar temperature.nc interannual_var.nc          # temporal variance
```

```{tip}
`timstd` shows where interannual variability is largest. For temperature, this is typically over continents at high latitudes and over the mid-latitude storm tracks.
```

### 9.3.4 Time Range and Median

```bash
cdo timrange temperature.nc range_at_each_grid.nc     # temporal range
cdo timmedian temperature.nc median_at_each_grid.nc   # temporal median
```

### 9.3.5 Temporal Percentiles

```bash
cdo timpctl,10 temperature.nc p10.nc                  # 10th percentile
cdo timpctl,50 temperature.nc p50.nc                  # 50th percentile (median)
cdo timpctl,90 temperature.nc p90.nc                  # 90th percentile
cdo timpctl,95 temperature.nc p95.nc                  # 95th percentile
cdo timpctl,99 temperature.nc p99.nc                  # 99th percentile
```

```{note}
The `timpctl` operator requires an additional file specifying the percentile number. For example, `cdo timpctl,90 temperature.nc temperature.nc p90.nc` — the second `temperature.nc` provides the number of timesteps.
```

Actually, the correct syntax is:

```bash
cdo timpctl,90 temperature.nc -timmin temperature.nc -timmax temperature.nc p90.nc
```

The `timpctl` operator requires both the minimum and maximum as separate inputs.

### 9.3.6 Daily Percentile Climatology

```bash
cdo ydaypctl,90 temperature.nc -ydaymin temperature.nc -ydaymax temperature.nc p90_clim.nc
```

### 9.3.7 Monthly Percentile Climatology

```bash
cdo ymonpctl,90 temperature.nc -ymonmin temperature.nc -ymonmax temperature.nc p90_clim.nc
```

```{exercise}
:label: ex-statistics-3
Compute the 90th percentile of daily maximum temperature for each calendar month from a multi-year dataset.
```

````{solution} ex-statistics-3
```bash
cdo ymonpctl,90 daily_tmax.nc -ymonmin daily_tmax.nc -ymonmax daily_tmax.nc tmax90_clim.nc
```
This produces 12 maps showing the 90th percentile daily maximum temperature for each month.
````

### 9.3.8 Summary of Temporal Statistics

| Operator     | Description                        | Result Dimensions  |
|--------------|------------------------------------|--------------------|
| `timmean`    | Mean over time                     | (lat, lon)         |
| `timmax`     | Maximum over time                  | (lat, lon)         |
| `timmin`     | Minimum over time                  | (lat, lon)         |
| `timsum`     | Sum over time                      | (lat, lon)         |
| `timstd`     | Std deviation over time            | (lat, lon)         |
| `timvar`     | Variance over time                 | (lat, lon)         |
| `timrange`   | Range (max-min) over time          | (lat, lon)         |
| `timmedian`  | Median over time                   | (lat, lon)         |
| `timpctl`    | Percentile over time               | (lat, lon)         |
| `ydaypctl`   | Daily percentile climatology       | (day, lat, lon)    |
| `ymonpctl`   | Monthly percentile climatology     | (mon, lat, lon)    |

## 9.4 Percentiles and Histograms

CDO provides histogram operators for analyzing the distribution of values.

### 9.4.1 Histogram Count

```bash
cdo histcount temperature.nc histogram.nc
```

This counts the number of grid cells in each value bin. By default, CDO creates 10 equal-width bins.

```bash
cdo histcount,20 temperature.nc histogram_20bins.nc   # 20 bins
cdo histcount,5,-10,40 temperature.nc custom_bins.nc   # 5 bins from -10 to 40
```

### 9.4.2 Histogram Frequency

```bash
cdo histfreq temperature.nc hist_freq.nc               # as fraction (0-1)
cdo histfreq,15 temperature.nc hist_15bins.nc
```

### 9.4.3 Empirical Distribution Functions

```bash
cdo vertsum -histfreq,50 temperature.nc distribution.nc
```

### 9.4.4 Extreme Value Analysis

Use percentiles to define thresholds for extremes:

```bash
# Define the 95th percentile threshold
cdo timpctl,95 temperature.nc -timmin temperature.nc -timmax temperature.nc threshold.nc

# Count exceedances
cdo ge temperature.nc threshold.nc exceedances.nc
cdo timsum exceedances.nc n_exceedances.nc
```

```{tip}
The `ge` operator sets grid cells to 1 where the value is greater than or equal to the threshold, and 0 otherwise. Summing these over time gives the count of extreme events.
```

## 9.5 Multi-Model Statistics

Multi-model analysis is essential for climate projections and uncertainty quantification.

### 9.5.1 Multi-Model Ensemble Mean

```bash
cdo ensmean modelA.nc modelB.nc modelC.nc modelD.nc modelE.nc mme_mean.nc
```

### 9.5.2 Multi-Model Spread

```bash
cdo ensstd modelA.nc modelB.nc modelC.nc modelD.nc modelE.nc mme_spread.nc
```

### 9.5.3 Model Agreement

Compute the fraction of models agreeing on the sign of change:

```bash
# Compute change for each model
cdo sub modelA_future.nc modelA_historical.nc change_A.nc
cdo sub modelB_future.nc modelB_historical.nc change_B.nc
# ... etc.

# Sign agreement (1 if positive, 0 if negative)
cdo gec,0 change_A.nc sign_A.nc
# ...
cdo ensmean sign_A.nc sign_B.nc sign_C.nc agreement.nc
```

```{note}
An agreement value of 0.8 means 80% of models show a positive change. Values above 0.67 are often considered robust in the IPCC assessment reports.
```

### 9.5.4 Signal-to-Noise Ratio

```bash
cdo ensmean model*.nc mme_mean.nc
cdo ensstd model*.nc mme_std.nc
cdo div mme_mean.nc mme_std.nc snr.nc
```

A signal-to-noise ratio > 1 indicates that the multi-model mean is larger than the inter-model spread.

```{warning}
Multi-model spread does not capture all sources of uncertainty. Structural biases common to all models will not appear in the ensemble spread.
```

## 9.6 Statistical Quality Control

Statistical operators can identify data quality issues.

### 9.6.1 Detecting Outliers

```bash
# Compute mean and std
cdo timmean temperature.nc mean.nc
cdo timstd temperature.nc std.nc

# Define thresholds (mean +/- 4*std)
cdo sub mean.nc -mulc,4 std.nc lower_thresh.nc
cdo add mean.nc -mulc,4 std.nc upper_thresh.nc

# Find values outside range
cdo lt temperature.nc lower_thresh.nc too_low.nc
cdo gt temperature.nc upper_thresh.nc too_high.nc
cdo add too_low.nc too_high.nc outliers.nc
```

### 9.6.2 Checking for Missing Data

```bash
cdo info temperature.nc | find "miss"     # count missing values per variable
cdo timsum -eqc,-999 temperature.nc missing_count.nc
```

### 9.6.3 Temporal Consistency Checks

```bash
# Check for unrealistic jumps (>5°C between consecutive days)
cdo sub -shifttime,1day temperature.nc temperature.nc diff.nc
cdo gt -abs diff.nc 5 unrealistic_jumps.nc
cdo timsum unrealistic_jumps.nc n_jumps.nc
```

```{exercise}
:label: ex-statistics-4
Perform a quality control check on a temperature dataset: flag any daily grid cell value that differs by more than 10°C from the monthly mean at that location.
```

````{solution} ex-statistics-4
```bash
# Compute monthly mean
cdo monmean temperature.nc monthly_mean.nc

# Expand monthly mean back to daily resolution
cdo inttime,monthly_mean.nc daily_mean.nc

# Compute difference
cdo sub temperature.nc daily_mean.nc diff.nc

# Flag outliers
cdo gt -abs diff.nc 10 flag.nc
cdo timsum flag.nc total_flags.nc
```
````

## 9.7 Practical Workflow Examples

### 9.7.1 Multi-Year Statistical Summary

```bash
cdo timmean temperature.nc longterm_mean.nc
cdo timstd temperature.nc interannual_std.nc
cdo timpctl,5 temperature.nc -timmin temperature.nc -timmax temperature.nc p5.nc
cdo timpctl,95 temperature.nc -timmin temperature.nc -timmax temperature.nc p95.nc
```

### 9.7.2 Ensemble Forecast Verification

```bash
# Observation vs ensemble mean
cdo sub observation.nc -ensmean mem01.nc mem02.nc ... mem10.nc bias.nc

# Ensemble spread
cdo ensstd mem01.nc mem02.nc ... mem10.nc spread.nc

# Ratio of bias to spread
cdo div -abs bias.nc spread.nc normalized_bias.nc
```

### 9.7.3 Seasonal Extremes

```bash
# 90th percentile for each season
cdo seasmean -ymonpctl,90 temperature.nc -ymonmin temperature.nc -ymonmax temperature.nc seasonal_p90.nc
```

### 9.7.4 Trend Significance

Compute the linear trend and its statistical significance:

```bash
cdo trend temperature.nc intercept.nc slope.nc
cdo timstd temperature.nc variability.nc
cdo div slope.nc variability.nc t_stat.nc
```

## 9.8 Hands-On Exercises

### Exercise 9.1: Multi-Year Statistics

```{exercise}
:label: ex-statistics-5
Using a 30-year daily temperature dataset:
1. Compute the long-term mean temperature
2. Compute the interannual standard deviation
3. Compute the 5th and 95th percentiles
4. Identify grid points where the 95th percentile exceeds 35°C
```

````{solution} ex-statistics-5
```bash
cdo timmean temperature.nc clim_mean.nc
cdo timstd temperature.nc clim_std.nc
cdo timpctl,5 temperature.nc -timmin temperature.nc -timmax temperature.nc p5.nc
cdo timpctl,95 temperature.nc -timmin temperature.nc -timmax temperature.nc p95.nc
cdo gtc,35 p95.nc hot_spots.nc
cdo output -fldsum hot_spots.nc
```
````

### Exercise 9.2: Ensemble Statistics

```{exercise}
:label: ex-statistics-6
Given 10 CMIP6 model outputs for 2081-2100 temperature under SSP5-8.5:
1. Compute the multi-model ensemble mean
2. Compute the ensemble standard deviation (model spread)
3. Compute the signal-to-noise ratio
4. Which regions have SNR > 2?
```

````{solution} ex-statistics-6
```bash
cdo ensmean cmip6_model_*.nc mme_mean.nc
cdo ensstd cmip6_model_*.nc mme_spread.nc
cdo div mme_mean.nc mme_spread.nc snr.nc
cdo gtc,2 snr.nc robust_regions.nc
cdo output -fldsum robust_regions.nc
```
````

### Exercise 9.3: Percentile Analysis

```{exercise}
:label: ex-statistics-7
Compute the 90th percentile of daily precipitation for each month. Then count the number of days exceeding this threshold in each year. How has the frequency of extreme precipitation days changed?
```

````{solution} ex-statistics-7
```bash
# Compute threshold
cdo ymonpctl,90 daily_precip.nc -ymonmin daily_precip.nc -ymonmax daily_precip.nc p90_clim.nc

# For each year, count exceedances
for year in $(seq 1990 2020); do
  cdo timsum -ge -selyear,$year daily_precip.nc p90_clim.nc "exceed_$year.nc"
done

# Combine and analyze trend
cdo ensmean exceed_*.nc trend_exceed.nc
cdo trend exceed_*.nc intercept.nc slope.nc
cdo output -fldmean slope.nc
```
````

### Exercise 9.4: Histogram Analysis

```{exercise}
:label: ex-statistics-8
Generate a histogram of global temperature values from a climate model. Compare histograms for 1850-1900 (pre-industrial) vs 1995-2014 (present-day). How has the distribution shifted?
```

````{solution} ex-statistics-8
```bash
cdo selyear,1850/1900 temperature.nc preindustrial.nc
cdo selyear,1995/2014 temperature.nc present.nc

cdo histcount,50 preindustrial.nc hist_pre.nc
cdo histcount,50 present.nc hist_present.nc

cdo fldmean -histfreq,50 preindustrial.nc histfreq_pre.nc
cdo fldmean -histfreq,50 present.nc histfreq_present.nc
```
The distribution for the present period is shifted toward warmer values, and the tail of hot extremes has extended.
````

### Exercise 9.5: Statistical Downscaling Verification

```{exercise}
:label: ex-statistics-9
Given a coarse-resolution dataset and a high-resolution reference:
1. Compute the mean bias (coarse minus reference)
2. Compute the spatial correlation between the two datasets
3. Compute the root-mean-square error (RMSE)
```

````{solution} ex-statistics-9
```bash
# Bias
cdo sub coarse_data.nc reference_data.nc bias.nc

# Differences for RMSE
cdo sqr -sub coarse_data.nc reference_data.nc sqr_diff.nc
cdo fldmean sqr_diff.nc mse.nc
cdo sqrt mse.nc rmse.nc

# The RMSE combines bias and pattern error into a single metric.
```
````

## 9.9 Quiz

```{exercise} Question 1
:label: q-statistics-1

What is the difference between `cdo mean` and `cdo timmean`?

a) They are identical operators
b) `mean` collapses all dimensions, `timmean` collapses only the time dimension
c) `timmean` is faster for large datasets
d) `mean` works on files, `timmean` works on streams

```

```{solution} q-statistics-1
The correct answer is **b**. `cdo mean` averages over all non-record dimensions (time, spatial, vertical), producing a single value per variable. `cdo timmean` averages only over the time dimension, preserving spatial structure.
```

```{exercise} Question 2
:label: q-statistics-2

When computing ensemble statistics, what does `cdo ensstd` represent?

a) The standard deviation of values within each grid cell across time
b) The standard deviation of values across ensemble members at each grid cell and time step
c) The temporal standard deviation of the ensemble mean
d) The spatial standard deviation averaged across ensemble members

```

```{solution} q-statistics-2
The correct answer is **b**. `cdo ensstd` computes the standard deviation across all input files (ensemble members) at each grid cell and each time step. It measures inter-model or inter-member spread.
```

```{exercise} Question 3
:label: q-statistics-3

Which operator would you use to compute the 90th percentile of daily temperature for each calendar day across 30 years?

a) `cdo timpctl,90`
b) `cdo ymonpctl,90`
c) `cdo ydaypctl,90`
d) `cdo enspctl,90`

```

```{solution} q-statistics-3
The correct answer is **c**. `cdo ydaypctl,90` computes the 90th percentile for each calendar day (1-366) across all years. `timpctl` would give a single 90th percentile map, not a daily climatology.
```

```{exercise} Question 4
:label: q-statistics-4

What is the ensemble mean of model projections primarily used for?

a) Identifying which model performs best
b) Reducing random errors and producing a more robust estimate than any single model
c) Computing the maximum possible future change
d) Removing all uncertainty from climate projections

```

```{solution} q-statistics-4
The correct answer is **b**. The multi-model ensemble mean typically outperforms any single model because random errors from different models tend to cancel out. However, it cannot remove systematic biases common to all models.
```

```{exercise} Question 5
:label: q-statistics-5

If you want to count the number of days exceeding 35°C at each grid point, which sequence of CDO commands would you use?

a) `cdo timmean -gtc,35 temperature.nc`
b) `cdo gtc,35 temperature.nc exceed.nc && cdo timsum exceed.nc`
c) `cdo timsum -gec,35 temperature.nc`
d) `cdo histfreq temperature.nc`

```

```{solution} q-statistics-5
The correct answer is **b** (or equivalently **c**). `cdo gtc,35` creates a mask (1 where > 35, 0 elsewhere). `cdo timsum` sums this over time to get counts. `cdo timsum -gec,35 temperature.nc` does the same in one pipeline step. Option **a** computes the mean of the mask, not the count. Option **d** creates a histogram, not an exceedance count.
```

## Summary

In this module, you learned about CDO's comprehensive statistical capabilities:

- **Basic statistics**: `mean`, `median`, `max`, `min`, `sum`, `std`, `var`, `range` for simple aggregations
- **Ensemble statistics**: `ensmean`, `ensmax`, `ensmin`, `ensstd`, `ensvar`, `ensrange`, `ensmedian`, `enspctl` for multi-file analysis
- **Temporal statistics**: `timmean`, `timmax`, `timmin`, `timstd`, `timvar`, `timsum`, `timpctl` for time-reduced fields
- **Percentile climatologies**: `ydaypctl`, `ymonpctl` for extreme value thresholds
- **Histograms**: `histcount`, `histfreq` for distribution analysis
- **Multi-model analysis**: Ensemble mean and spread for projections and uncertainty quantification
- **Quality control**: Outlier detection, consistency checks using statistical operators

```{tip}
Statistical operators in CDO are building blocks that can be chained in powerful ways. A single pipeline can compute extreme event frequencies, multi-model consensus maps, or detect data quality issues. Invest time in understanding the operator combinations — they will save you hours of scripting in other languages.
```

Proceed to Module 10 to learn about climate indices and extreme event detection using CDO.
