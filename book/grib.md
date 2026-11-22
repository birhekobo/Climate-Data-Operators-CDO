---
title: "Module 6: Working with GRIB Data"
subject: Climate Data Operators Training
subtitle: "GRIB Format, Conversion, and Manipulation"
---

# Module 6: Working with GRIB Data

## Learning Objectives

By the end of this module, you will be able to:

- Understand GRIB format structure (GRIB1 vs GRIB2)
- Navigate WMO GRIB standards and conventions
- Explore and extract metadata from GRIB files
- Identify GRIB parameter IDs, level types, and centers
- Convert GRIB to NetCDF and other formats
- Filter GRIB files by parameter, level, and time
- Manipulate GRIB metadata
- Work with ECMWF, GFS, and ICON model data in GRIB format
- Process ensemble forecasts in GRIB format

---

## GRIB Format Fundamentals

GRIB (GRIdded Binary) is the World Meteorological Organization (WMO) standard format for meteorological data. It is widely used by operational weather centers worldwide.

```{note}
GRIB is designed for efficient storage and exchange of meteorological data. Unlike NetCDF, GRIB files are not self-documenting in the same way - understanding requires knowledge of GRIB tables and codes.
```

### GRIB1 vs GRIB2

| Feature | GRIB1 (Edition 1) | GRIB2 (Edition 2) |
|---------|-------------------|-------------------|
| **Introduced** | 1985 | 2003 |
| **Section Structure** | PDS, GDS, BMS, BDS | 7 sections (0-6) |
| **Parameter Identification** | Center + Parameter Number | Discipline + Category + Number |
| **Compression** | Simple Packing | Complex Packing, JPEG2000, PNG |
| **Grid Types** | Limited | Extensive (including unstructured) |
| **Ensemble Support** | Basic | Comprehensive |
| **Satellite Data** | Limited | Full support |
| **Product Templates** | 1 | 15+ |

### GRIB2 Section Structure

Each GRIB2 file contains multiple messages, each with 7 sections:

```
GRIB2 Message
+-- Section 0: Indicator Section (file identification)
+-- Section 1: Identification Section (date, center, process)
+-- Section 2: Local Use Section (optional)
+-- Section 3: Grid Definition Section (grid description)
+-- Section 4: Product Definition Section (parameter, level)
+-- Section 5: Data Representation Section (packing method)
+-- Section 6: Bit-Map Section (missing data)
+-- Section 7: Data Section (actual values)

Section 8: End Section ("7777")
```

## WMO GRIB Standards

The WMO maintains international standards for GRIB encoding:

```{important}
GRIB files are only meaningful with their associated parameter tables. Common table sources include ECMWF, NCEP, DWD, and JMA.
```

### Key GRIB Tables

| Table | Description | Values |
|-------|-------------|--------|
| **Table 0** | Discipline | 0=Meteorological, 1=Hydrological, 2=Land, 3=Space |
| **Table 1** | Category (within discipline) | Temperature, Moisture, Momentum, etc. |
| **Table 4.2** | Parameter Number | Specific parameter within category |
| **Table 4.5** | Type of Level | 100=isobaric, 103=height above sea, etc. |
| **Table 3.1** | Grid Definition | 0=lat/lon, 10=mercator, 30=Lambert, 40=Gaussian |
| **Table 0.0** | Center ID | 7=NCEP, 78=ECMWF, 80=DWD, 34=JMA |

### Common GRIB Center IDs

| Center ID | Center Name | Source |
|-----------|-------------|--------|
| **7** | NCEP (US National Weather Service) | GFS, HRRR |
| **34** | Japan Meteorological Agency | JMA, JRA-55 |
| **58** | Met Office (UK) | UKV, MOGREPS |
| **78** | ECMWF | ERA5, IFS HRES, ENS |
| **80** | DWD (German Weather Service) | ICON, ICON-EPS |
| **85** | Meteo-France | ARPEGE, AROME |
| **98** | ECCC (Environment Canada) | GDPS, RDPS |

## ECMWF Products and ERA5 in GRIB

ECMWF distributes ERA5 reanalysis and IFS operational data primarily in GRIB format.

### ERA5 GRIB Structure

```{note}
ERA5 in GRIB format contains 240+ parameters at multiple pressure levels and surface fields.
```

Common ERA5 parameters and their GRIB codes:

| Parameter | GRIB Code | Type of Level | Short Name |
|-----------|-----------|---------------|------------|
| 2m Temperature | 167 | Surface | 2t |
| Total Precipitation | 228 | Surface | tp |
| Mean Sea Level Pressure | 151 | Surface | msl |
| 10m U Wind | 165 | Surface | 10u |
| 10m V Wind | 166 | Surface | 10v |
| Geopotential | 129 | Isobaric | z |
| Temperature | 130 | Isobaric | t |
| Specific Humidity | 133 | Isobaric | q |
| U Wind | 131 | Isobaric | u |
| V Wind | 132 | Isobaric | v |
| Vertical Velocity | 135 | Isobaric | w |

### Viewing ERA5 GRIB Metadata

```bash
cdo sinfo era5_2020.grib
cdo -P showparam era5_2020.grib
cdo -P showlevel era5_2020.grib
cdo showdate era5_2020.grib
```

## GFS Model Output in GRIB

The Global Forecast System (GFS) from NCEP is one of the most widely used forecast datasets.

### GFS GRIB Characteristics

- GRIB2 format (since 2015)
- 0.25 degree global grid (~13 km)
- 16-day forecast horizon
- 4 forecast cycles per day (00, 06, 12, 18 UTC)
- Hourly output for first 120 hours
- 127 vertical levels (up to ~80 km)

### Common GFS Parameters

```bash
# NCEP GRIB parameter codes
# TMP   = Temperature (K)
# UGRD  = U-component of wind (m/s)
# VGRD  = V-component of wind (m/s)
# PRMSL = Pressure reduced to MSL (Pa)
# APCP  = Total precipitation (kg/m^2)
# RH    = Relative humidity (%)
# HGT   = Geopotential height (gpm)
# PWAT  = Precipitable water (kg/m^2)
```

### Exploring GFS Data

```bash
cdo sinfo gfs_20240101_00.grib2
cdo -P showparam gfs_20240101_00.grib2
cdo -P showlevel gfs_20240101_00.grib2
cdo seltimestep,1/24 gfs.grib2 first_24h.grib2
```

## ICON Model Data

The ICON (Icosahedral Non-hydrostatic) model from DWD uses an unstructured icosahedral grid.

```{important}
ICON uses an unstructured grid, which is not a standard latitude-longitude grid. CDO has special support for ICON grids.
```

### ICON GRIB Features

- Unstructured (triangular) grid
- Global 13 km, nested domains at 6.5 km
- 90 vertical levels
- 7-day forecast
- GRIB2 encoding

### Working with ICON Data

```bash
cdo sinfo icon_output.grib2
cdo remapbil,r0.5x0.5 icon_output.grib2 regular.nc
cdo remapcon,r0.25x0.25 icon_output.grib2 regular_con.nc
```

```{tip}
For ICON data, use conservative remapping for flux variables and bilinear for state variables.
```

## Exploring GRIB Files

### cdo sinfo for GRIB

```bash
cdo sinfo data.grib
```

Example output:
```
   File format: GRIB2
    -1 : Institut Source   T Steptype Levels Num    Points Num Dtype : Parameter name
     1 : ECMWF    unknown  v instant      1   1     10692   1  F32 : t2m
     2 : ECMWF    unknown  v instant      1   1     10692   1  F32 : tp
   Horizontal grid  : regular lonlat
```

### cdo gribmap - GRIB Parameter Mapping

```bash
cdo gribmap data.grib
```

```{note}
The cdo gribmap command is essential for understanding which parameters are in a GRIB file and how they map to CDO internal naming.
```

### Additional GRIB Exploration Commands

```bash
cdo showparam data.grib
cdo showlevel data.grib
cdo showcode data.grib
cdo showcode -ct data.grib
cdo showdate data.grib
cdo showtime data.grib
cdo output -griddes data.grib
cdo -s ntime data.grib
```

## GRIB Parameter IDs and Level Types

### Understanding Parameter Identification

GRIB uses a hierarchical parameter identification system:

```bash
# GRIB2 parameter identification:
# Discipline (Table 0) + Category (Table 1) + Parameter Number (Table 4.2)

# Example: Temperature at 500 hPa
# Discipline: 0 (Meteorological)
# Category: 0 (Temperature)
# Parameter: 0 (Temperature)
# Type of Level: 100 (Isobaric surface)
# Level Value: 50000 (Pa)

# In CDO, select by GRIB parameter code
cdo selcode,130 data.grib t500.grib
cdo sellevel,50000 data.grib t500.grib
cdo select,code=130,level=50000 data.grib t500_500hPa.grib
```

### Common GRIB Parameter Codes

```bash
# ECMWF codes (for ERA5, IFS)
# Surface parameters
cdo selcode,167 data.grib   # 2m temperature
cdo selcode,228 data.grib   # Total precipitation
cdo selcode,151 data.grib   # Mean sea level pressure
cdo selcode,165 data.grib   # 10m U wind
cdo selcode,166 data.grib   # 10m V wind
cdo selcode,134 data.grib   # Surface pressure

# Pressure level parameters
cdo selcode,130 data.grib   # Temperature
cdo selcode,129 data.grib   # Geopotential
cdo selcode,131 data.grib   # U wind
cdo selcode,132 data.grib   # V wind
cdo selcode,133 data.grib   # Specific humidity
cdo selcode,135 data.grib   # Vertical velocity
cdo selcode,157 data.grib   # Relative humidity
```

### Level Types

```bash
# sfc  - Surface (single level)
# pl   - Isobaric pressure levels (hPa)
# ml   - Model levels
# pt   - Potential temperature levels
# hl   - Height levels above ground
# pv   - Potential vorticity levels

cdo select,levtype=pl data.grib  # Pressure level data only
cdo select,levtype=sfc data.grib # Surface data only
```

## Converting GRIB to NetCDF

### Basic Conversion

```bash
cdo -f nc copy input.grib output.nc
cdo -z zip_5 -f nc copy input.grib output.nc
cdo -f nc -selname,t2m copy input.grib output.nc
```

### Managing Conversion Issues

```bash
cdo -f nc -t ecmean copy input.grib output.nc
cdo -t ecmwf -f nc copy input.grib output.nc
cdo -f nc -select,name=t2m,msl -t ecmwf copy input.grib output.nc
cdo -f nc -remapbil,r360x180 -selname,t2m copy input.grib output.nc
```

```{warning}
When converting GRIB to NetCDF, parameter names may not map correctly without the correct parameter table. Use the -t option to specify the table.
```

### Batch Conversion

```bash
#!/bin/bash
INPUT_DIR="./grib_files"
OUTPUT_DIR="./netcdf_files"
mkdir -p "$OUTPUT_DIR"

for gribfile in "$INPUT_DIR"/*.grib; do
    fname=$(basename "$gribfile")
    name="${fname%.grib}"
    echo "Converting: $fname"
    cdo -z zip_5 -f nc -t ecmwf \
        copy "$gribfile" "$OUTPUT_DIR/${name}.nc"
done

echo "Batch conversion complete"
```

## GRIB File Manipulation

### Filtering by Parameter

```bash
cdo selname,t2m input.grib output.grib
cdo selcode,167 input.grib output.grib
cdo selname,t2m,tp,msl input.grib output.grib
cdo delete,name=t2m input.grib without_t2m.grib
```

### Filtering by Level

```bash
cdo sellevel,50000 input.grib 500hPa.grib
cdo sellevel,85000,70000,50000,20000 input.grib multi_level.grib
cdo sellevel,1000/100000 input.grib all_pressure.grib
cdo select,levtype=sfc input.grib surface.grib
```

### Filtering by Time

```bash
cdo seltimestep,1 input.grib first.grib
cdo seltimestep,1/24 input.grib first_24h.grib
cdo seldate,2020-06-01,2020-06-30 input.grib june_2020.grib
cdo selseas,JJA input.grib summer.grib
```

### Spatial Subsetting

```bash
cdo sellonlatbox,-10,30,35,70 input.grib europe.grib
cdo sellonlatbox,0,360,-90,90 input.grib global.grib
cdo sellonlatbox,0,360,-30,30 input.grib tropics.grib
```

```{tip}
Use sellonlatbox for geographic subsetting. The order is: lon_min, lon_max, lat_min, lat_max.
```

## GRIB Metadata Handling

### Viewing GRIB Metadata

```bash
grib_ls input.grib
grib_dump input.grib | head -50
cdo sinfo input.grib
cdo -P showparam input.grib
cdo -P showlevel input.grib
cdo griddes input.grib
cdo showattribute,centre input.grib
```

### Modifying GRIB Metadata

```bash
cdo setattribute,centre="ECMWF" input.grib output.grib
cdo setdate,2020-01-01 input.grib output.grib
cdo settime,00:00:00 input.grib output.grib
cdo chname,t2m,Temperature input.grib output.grib
cdo chunit,t2m,K input.grib output.grib
```

### Complete Metadata Workflow

```bash
#!/bin/bash
INPUT="ecmwf_forecast.grib"

echo "=== GRIB File Analysis ==="
echo "File: $INPUT"
echo ""

echo "1. Basic Info:"
cdo sinfo "$INPUT" 2>/dev/null | head -20

echo ""
echo "2. Available Parameters:"
cdo -P showparam "$INPUT" 2>/dev/null

echo ""
echo "3. Levels:"
cdo -P showlevel "$INPUT" 2>/dev/null

echo ""
echo "4. Grid Description:"
cdo griddes "$INPUT" 2>/dev/null

echo ""
echo "5. Time Range:"
start=$(cdo showdate "$INPUT" 2>/dev/null | awk '{print $1}')
end=$(cdo showdate "$INPUT" 2>/dev/null | awk '{print $NF}')
echo "Start: $start"
echo "End:   $end"

echo ""
echo "=== Analysis Complete ==="
```

## Working with Ensemble Forecasts

GRIB2 has comprehensive support for ensemble forecast data.

### Ensemble Identification

```bash
cdo -P showmember input_ensemble.grib
cdo selmember,1 input_ensemble.grib member1.grib
cdo selmember,1/10 input_ensemble.grib first_10.grib
cdo ensmean member1.grib member2.grib member3.grib ens_mean.grib
cdo ensstd member1.grib member2.grib member3.grib ens_spread.grib
cdo ensmin member*.grib ens_min.grib
cdo ensmax member*.grib ens_max.grib
```

### Ensemble Processing with Wildcards

```bash
cdo ensmean mem_*.grib ensemble_mean.grib
cdo selmember,0 eps.grib control.grib
cdo expr,'prob = (t2m > 303.15) ? 1 : 0' -ensmean member*.grib prob_exceed.grib
```

## Practical GRIB Processing Workflows

### ECMWF Forecast Processing

```bash
#!/bin/bash
set -e

FCST_DIR="./forecast"
OUTPUT_DIR="./processed"
DATE=$(date +%Y%m%d)
mkdir -p "$OUTPUT_DIR"

echo "Processing ECMWF forecast for $DATE"

echo "Extracting surface parameters..."
cdo selname,t2m,msl,tp \
    "$FCST_DIR/${DATE}_ens.grib" \
    "$OUTPUT_DIR/${DATE}_surface.grib"

echo "Extracting 500 hPa height..."
cdo sellevel,50000 -selname,z \
    "$FCST_DIR/${DATE}_ens.grib" \
    "$OUTPUT_DIR/${DATE}_z500.grib"

echo "Computing ensemble mean..."
cdo ensmean "$OUTPUT_DIR/${DATE}_surface.grib" \
    "$OUTPUT_DIR/${DATE}_z500.grib" \
    "$OUTPUT_DIR/${DATE}_ens_mean.grib"

echo "Converting to NetCDF..."
cdo -z zip_5 -f nc copy \
    "$OUTPUT_DIR/${DATE}_ens_mean.grib" \
    "$OUTPUT_DIR/${DATE}_ens_mean.nc"

echo "Processing complete"
```

### GFS Operational Workflow

```bash
#!/bin/bash
OUTPUT_DIR="./gfs_processed"
mkdir -p "$OUTPUT_DIR"

echo "Selecting parameters and region..."
cdo sellonlatbox,-130,-60,25,50 \
    -selname,TMP,PRMSL,UGRD,VGRD \
    gfs_20240101_00z.grib2 \
    "$OUTPUT_DIR/gfs_conus.grib2"

echo "Converting temperature to Celsius..."
cdo expr,'TMP_C = TMP - 273.15' \
    "$OUTPUT_DIR/gfs_conus.grib2" \
    "$OUTPUT_DIR/gfs_conus_celsius.grib2"

echo "Saving as compressed NetCDF..."
cdo -z zip_5 -f nc copy \
    "$OUTPUT_DIR/gfs_conus_celsius.grib2" \
    "$OUTPUT_DIR/gfs_conus.nc"

echo "Data processed successfully"
cdo sinfo "$OUTPUT_DIR/gfs_conus.nc"
```

### GRIB to NetCDF with Metadata Preservation

```bash
#!/bin/bash
INPUT="$1"
OUTPUT="${INPUT%.grib}.nc"

echo "Converting $INPUT to $OUTPUT"

echo "Input parameters:"
cdo -P showparam "$INPUT" 2>/dev/null

echo "Converting with ECMWF tables..."
cdo -z zip_5 -f nc -t ecmwf copy "$INPUT" "$OUTPUT"

echo "Verifying output..."
ncdump -h "$OUTPUT" | head -30

echo "Conversion complete: $OUTPUT"
```

## GRIB Filters and Advanced Selection

### Complex Selection Criteria

```bash
cdo select,code=130,level=50000 data.grib t_500hPa.grib
cdo select,name=t2m,levtype=sfc data.grib surface_t2m.grib
cdo delete,name=tp,levtype=sfc data.grib no_precip.grib
cdo select,member=1,code=130 data.grib member1_t.grib
```

### Handling GRIB Edition Detection

```bash
cdo -f grb2 copy input.grib output.grib2
cdo -f grb copy input.grib output.grib1
cdo sinfo input.grib | grep "File format"
```

## Troubleshooting GRIB Issues

### Common Problems

```bash
# Problem: "Unknown parameter name"
# Solution: Use parameter code instead of name
cdo selcode,167 input.grib output.grib

# Problem: "Different grid types in file"
# Solution: Split and process separately
cdo select,levtype=sfc input.grib surface.grib
cdo select,levtype=pl input.grib pressure.grib

# Problem: "GRIB API error in field"
# Solution: Check file integrity
grib_ls input.grib 2>&1 | grep ERROR
```

## Hands-On Exercises

### Exercise 1: Explore a GRIB File

````{exercise}
:label: ex-grib-1
If you have a GRIB file available, explore it with CDO:

```bash
cdo sinfo data.grib
cdo -P showparam data.grib
cdo -P showlevel data.grib
cdo griddes data.grib
cdo showdate data.grib
cdo ntime data.grib
```

If you do not have a GRIB file, create a test file and explore:
```bash
cdo -f grb2 -random,50,10,10 test.grib
cdo griddes test.grib
cdo -P showparam test.grib
```

Answer these questions:
1. What is the GRIB edition?
2. How many parameters are in the file?
3. What level types are present?
4. What is the grid type and size?
````

### Exercise 2: Convert GRIB to NetCDF

````{exercise}
:label: ex-grib-2
Convert a GRIB file to NetCDF with different options:

```bash
# Basic conversion
cdo -f nc copy input.grib basic.nc

# With compression
cdo -z zip_5 -f nc copy input.grib compressed.nc

# Select specific parameter
cdo -f nc -selname,t2m copy input.grib t2m_only.nc

# Compare file sizes
ls -lh input.grib basic.nc compressed.nc t2m_only.nc

# Verify content
cdo sinfo basic.nc
cdo sinfo compressed.nc

# Compare data integrity
cdo diff basic.nc compressed.nc
```
````

### Exercise 3: Filter GRIB by Parameter and Level

````{exercise}
:label: ex-grib-3
Practice filtering GRIB data:

```bash
# Create multi-level test GRIB
cdo -f grb2 -random,50,10,10 multi.grib
cdo settaxis,2020-01-01,00:00:00,1day multi.grib dated.grib

# Extract surface parameters
cdo select,levtype=sfc dated.grib surface.grib
cdo sinfo surface.grib

# Extract pressure level data only
cdo select,levtype=pl dated.grib pressure.grib
cdo sinfo pressure.grib

# Select all data except first variable
cdo delete,name=var1 dated.grib no_var1.grib
cdo sinfo no_var1.grib

# Clean up
rm multi.grib dated.grib surface.grib pressure.grib no_var1.grib
```
````

### Exercise 4: Batch GRIB Processing Script

````{exercise}
:label: ex-grib-4
Write a batch processing script for multiple GRIB files:

```bash
#!/bin/bash
# batch_process_grib.sh

INPUT_DIR="./grib_input"
OUTPUT_DIR="./processed_output"
mkdir -p "$OUTPUT_DIR"

echo "Batch processing GRIB files..."

for file in "$INPUT_DIR"/*.grib*; do
    [ -f "$file" ] || continue
    bname=$(basename "$file")
    name="${bname%.*}"

    echo "Processing: $bname"

    # Convert to compressed NetCDF
    cdo -z zip_5 -f nc copy "$file" "$OUTPUT_DIR/${name}.nc"

    # Extract metadata summary
    cdo sinfo "$file" > "$OUTPUT_DIR/${name}_info.txt"
done

echo "Batch processing complete."
ls -lh "$OUTPUT_DIR/"
```
````

### Exercise 5: Multi-Format Workflow

````{exercise}
:label: ex-grib-5
Build a workflow that processes GRIB and NetCDF data together:

```bash
#!/bin/bash
# multi-format workflow

echo "=== Multi-Format Processing ==="

# Step 1: Create test files
echo "Creating test data..."
cdo -f grb2 -random,100,10,10 model_output.grib2
cdo -f nc -random,100,10,10 observations.nc

# Step 2: Convert model to NetCDF
echo "Converting model data..."
cdo -z zip_5 -f nc copy model_output.grib2 model.nc

# Step 3: Select same variable from both
echo "Selecting common variable..."
cdo selname,var1 model.nc model_var1.nc
cdo selname,var1 observations.nc obs_var1.nc

# Step 4: Compute bias
echo "Computing model bias..."
cdo sub model_var1.nc obs_var1.nc bias.nc
cdo info bias.nc

# Step 5: Generate statistics
echo "Statistics:"
model_mean=$(cdo output -fldmean -timmean model_var1.nc 2>/dev/null)
obs_mean=$(cdo output -fldmean -timmean obs_var1.nc 2>/dev/null)
bias_mean=$(cdo output -fldmean -timmean bias.nc 2>/dev/null)
echo "Model mean: $model_mean"
echo "Obs mean:   $obs_mean"
echo "Bias mean:  $bias_mean"

# Clean up
rm -f model_output.grib2 model.nc model_var1.nc obs_var1.nc bias.nc observations.nc

echo "=== Workflow Complete ==="
```
````

## Quiz

```{admonition} Quiz
:class: tip
Test your knowledge of GRIB data handling with CDO.
```

```{exercise} Question 1: What is the difference between GRIB1 and GRIB2?
:label: q-grib-1

A. GRIB2 is older than GRIB1
B. GRIB2 uses a different file extension
C. GRIB2 has more sections, better compression, and comprehensive ensemble support
D. There is no difference

```

```{solution} q-grib-1
C. GRIB2 has 7 sections, supports JPEG2000/PNG compression, and has comprehensive ensemble support.
```

```{exercise} Question 2: Which CDO command shows the GRIB parameter mapping?
:label: q-grib-2

A. cdo sinfo
B. cdo gribmap
C. cdo param
D. cdo showcode

```

```{solution} q-grib-2
B. cdo gribmap
```

```{exercise} Question 3: What does 'cdo -f nc copy input.grib output.nc' do?
:label: q-grib-3

A. Copies the GRIB file to a new location
B. Converts GRIB to NetCDF format
C. Merges two files
D. Renames the file

```

```{solution} q-grib-3
B. Converts GRIB to NetCDF format
```

```{exercise} Question 4: Which option selects a specific GRIB parameter by its code number?
:label: q-grib-4

A. cdo selname,167
B. cdo selcode,167
C. cdo select,param=167
D. cdo sellparam,167

```

```{solution} q-grib-4
B. cdo selcode,167
```

```{exercise} Question 5: What is the ECMWF center ID in GRIB tables?
:label: q-grib-5

A. 7
B. 34
C. 78
D. 80

```

```{solution} q-grib-5
C. 78
```

## Summary

In this module, we covered:

- **GRIB format**: GRIB1 vs GRIB2, section structure (0-7), WMO standards
- **Key GRIB tables**: Discipline, Category, Parameter Number, Level Type, Center ID
- **Center identification**: ECMWF (78), NCEP (7), DWD (80), JMA (34)
- **Data sources**: ERA5, GFS, ICON, ensemble forecasts
- **Exploration commands**: sinfo, gribmap, showparam, showlevel, showcode
- **Parameter selection**: selcode, selname, sellevel, select with conditions
- **Format conversion**: -f nc copy for GRIB to NetCDF, -t ecmwf for table handling
- **Spatial/temporal filtering**: sellonlatbox, seldate, seltimestep
- **Ensemble processing**: selmember, ensmean, ensstd
- **Metadata management**: setattribute, grib_ls, grib_dump

```{admonition} Key Points
:class: note
- GRIB2 is the modern standard with better compression and ensemble support
- Always specify the parameter table (-t option) when converting to NetCDF
- Use code numbers (selcode) when parameter names are not recognized
- CDO treats GRIB and NetCDF similarly for most operations
- Ensemble forecasts require GRIB2 format for full support
```

## References

- WMO GRIB2 Specification: https://www.wmo.int/pages/prog/www/WMOCodes/ManualonGRIB2.pdf
- ECMWF GRIB Documentation: https://confluence.ecmwf.int/display/UDOC/GRIB
- eccodes (grib_ls, grib_dump): https://github.com/ecmwf/eccodes
- ICON Model Data: https://www.dwd.de/EN/ourservices/icon_global/icon_global.html
- GFS Data Access: https://www.ncdc.noaa.gov/data-access/model-data/model-datasets/global-forcast-system-gfs
- CDO GRIB Guide: https://code.mpimet.mpg.de/projects/cdo/wiki/Grib
