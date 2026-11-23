# Exercise 4: Spatial Analysis

## Objectives
- Crop data to a specific region
- Regrid from fine to coarse resolution
- Compare interpolation methods
- Compute regional averages

## Prerequisites
- `tas_sample.nc` in `datasets/`
- CDO installed with NetCDF and GRIB support

---

## Task 1: Crop Data to a Specific Region

### Instructions
1. Crop the global temperature data to Africa (-20°E to 50°E, -35°S to 40°N):

```bash
cdo sellonlatbox,-20,50,-35,40 ../datasets/tas_sample.nc tas_africa.nc
```

2. Try other regions:
   - **Europe:** `sellonlatbox,-10,40,35,70`
   - **South America:** `sellonlatbox,-85,-30,-60,15`
   - **Southeast Asia:** `sellonlatbox,90,150,-15,30`

### Questions
1. What happens at the boundaries — are the points inclusive?
2. Does `sellonlatbox` work with 0–360 longitude? If not, what operator should you use?
3. How would you crop using a mask file? (Hint: see `cdo maskregion`)

---

## Task 2: Regrid from 1° to 2° Resolution

### Instructions
1. Create a target grid description file (`target_grid.txt`) for a 2°×2° global grid:

```
gridtype = lonlat
xsize = 180
ysize = 90
xfirst = -179.0
xinc = 2.0
yfirst = -89.0
yinc = 2.0
```

2. Apply bilinear remapping:
```bash
cdo remapbil,target_grid.txt ../datasets/tas_sample.nc tas_2deg_bil.nc
```

### Questions
1. Compare the number of grid cells before and after regridding.
2. Has the global mean temperature changed? Why or why not?
3. What command shows the new grid dimensions? (Hint: `cdo griddes`)

---

## Task 3: Compare Bilinear vs Conservative Remapping

### Instructions
1. Apply three remapping methods:

```bash
cdo remapbil,target_grid.txt ../datasets/tas_sample.nc tas_bil.nc
cdo remapcon,target_grid.txt ../datasets/tas_sample.nc tas_con.nc
cdo remapnn,target_grid.txt ../datasets/tas_sample.nc tas_nn.nc
```

2. Compute the difference between bilinear and conservative:
```bash
cdo sub tas_bil.nc tas_con.nc tas_diff_bil_con.nc
cdo fldmean tas_diff_bil_con.nc
```

### Questions
1. What are the main differences between bilinear, conservative, and nearest-neighbor remapping?
2. For which type of variable (smooth vs. discontinuous) is each method best suited?
3. Why does conservative remapping preserve global integrals?
4. When would you use nearest-neighbor over the other methods?
5. Look at the difference field — where are the largest differences?

---

## Task 4: Compute Regional Averages

### Instructions
Compute area-weighted averages for different regions:

```bash
# Global mean
cdo fldmean ../datasets/tas_sample.nc tas_global.nc

# Tropical mean (23.5S–23.5N)
cdo fldmean -sellonlatbox,0,359,-23.5,23.5 ../datasets/tas_sample.nc tas_tropics.nc

# Northern hemisphere extra-tropics (23.5N–90N)
cdo fldmean -sellonlatbox,0,359,23.5,90 ../datasets/tas_sample.nc tas_nh_extratropics.nc

# Southern hemisphere extra-tropics (90S–23.5S)
cdo fldmean -sellonlatbox,0,359,-90,-23.5 ../datasets/tas_sample.nc tas_sh_extratropics.nc
```

### Questions
1. Which region has the highest mean temperature? Why?
2. Does `fldmean` apply area weighting automatically? How can you verify?
3. What operator would you use for an unweighted average?
4. Compare `fldmean` with `fldsum` — when would you use each?

---

## Bonus Challenge

1. Create a 5°×5° target grid.
2. Remap the data using conservative remapping.
3. Compute the latitude-weighted zonal mean:
   ```bash
   cdo zonmean tas_5deg.nc tas_zonal.nc
   ```
4. Plot the zonal mean temperature as a function of latitude.

---

## Deliverables
- Cropped files for at least 2 regions
- Regridded files (bilinear, conservative, nearest-neighbor)
- Difference field between methods
- Regional mean time series files
- Zonal mean plot (bonus)
- Written answers to all questions
