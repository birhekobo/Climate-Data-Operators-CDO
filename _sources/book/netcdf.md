---
title: "Module 5: Working with NetCDF Data"
subject: Climate Data Operators Training
subtitle: "NetCDF Format, Metadata, and Manipulation"
---

# Module 5: Working with NetCDF Data

## Learning Objectives

By the end of this module, you will be able to:

- Understand NetCDF file structure and components
- Interpret CF (Climate and Forecast) conventions
- Navigate NetCDF dimensions, variables, and attributes
- Apply compression to reduce file sizes
- Handle missing values and fill values
- Configure chunking for optimal performance
- Convert data between NetCDF and other formats
- Integrate CDO with NCO tools for advanced NetCDF operations
- Examine and modify metadata appropriately

---

## NetCDF Format Fundamentals

NetCDF (Network Common Data Form) is a set of software libraries and self-describing, machine-independent data formats that support the creation, access, and sharing of array-oriented scientific data.

```{note}
NetCDF is the most widely used format in climate science, supported by CMIP, CORDEX, ERA5, and virtually all climate model output.
```

### NetCDF File Structure

A NetCDF file contains three main components organized hierarchically:

```
NetCDF File (.nc)
├── Dimensions    (e.g., time, lat, lon, level)
├── Variables     (e.g., temperature, pressure)
│   ├── Data values (multidimensional arrays)
│   └── Attributes (metadata describing the variable)
└── Global Attributes (metadata describing the entire dataset)
```

### NetCDF Versions

| Version | Extension | Key Features | Max File Size |
|---------|-----------|--------------|---------------|
| **NetCDF Classic** | `.nc` | Original format | 2 GB |
| **NetCDF-4 (HDF5)** | `.nc` | HDF5 backend, compression, chunking | Unlimited |
| **NetCDF-4 Classic** | `.nc` | HDF5 backend, classic data model | Unlimited |
| **NetCDF-64bit** | `.nc` | 64-bit offsets | > 2 GB |

```{important}
NetCDF-4 (NC4) is recommended for modern climate data processing. It supports compression and files larger than 2 GB.
```

## NetCDF Components

### Dimensions

Dimensions define the axes of the data arrays:

```bash
# Show dimensions
cdo sinfo data.nc | grep -E "^[[:space:]]*(dimension|grid)"
ncdump -h data.nc | grep "^dimensions:"
ncdump -h data.nc | grep "^[[:space:]]*[a-z]"

# Typical dimensions in climate data:
# time       - unlimited dimension
# lat        - latitude (e.g., 1 to 180)
# lon        - longitude (e.g., 1 to 360)
# level      - vertical level (e.g., 1 to 37)
# nv         - vertex dimension for bounds
```

### Variables

Variables contain the actual data, with associated metadata:

```bash
# List all variables and their properties
cdo vardes data.nc
ncdump -h data.nc | grep "^[[:space:]]*float\|^[[:space:]]*double\|^[[:space:]]*int"

# Example variable definition (from ncdump):
#   float t2m(time, lat, lon) ;
#     t2m:long_name = "2m temperature" ;
#     t2m:units = "K" ;
#     t2m:standard_name = "air_temperature" ;
```

### Attributes

Attributes provide metadata about variables or the dataset:

```bash
# Show all variable attributes
cdo vardes data.nc

# Show global attributes
cdo gattr data.nc

# Show specific attribute
ncdump -h data.nc | grep -A 5 ":title"
ncdump -h data.nc | grep ":units"

# Common CF attributes:
# long_name    - Human-readable description
# units        - Physical units (K, m/s, Pa, etc.)
# standard_name - CF standard name
# cell_methods - How data was aggregated
# coordinates  - Auxiliary coordinate variables
# missing_value - Value representing missing data
# _FillValue   - Fill value for missing data
```

## CF (Climate and Forecast) Conventions

The CF conventions standardize climate data metadata to ensure interoperability:

```{note}
CF conventions are essential for data sharing and archival. Most climate data portals (CMIP, CORDEX, ESGF) require CF compliance.
```

### Key CF Requirements

| Element | Requirement | Example |
|---------|-------------|---------|
| **Units** | UDUNITS-compliant | `K`, `m s-1`, `kg m-2 s-1` |
| **Standard Names** | From CF standard name table | `air_temperature`, `eastward_wind` |
| **Coordinates** | Lat, lon, time, vertical | Proper axis attributes |
| **Cell Bounds** | For grid cell boundaries | `lat_bnds`, `lon_bnds` |
| **Cell Methods** | How statistics were computed | `time: mean` |

### Checking CF Compliance

```bash
# Check if a file follows CF conventions
ncdump -h data.nc | grep -c "cf_role\|standard_name\|cell_methods"

# Look for standard names
cdo vardes data.nc | grep "standard_name"

# Check coordinate variables
ncdump -h data.nc | grep -E "double|float.*lat|float.*lon"
```

```{tip}
Always ensure your output files contain proper units, standard names, and coordinate information to maintain CF compliance.
```

## Metadata Standards

### Essential Metadata Elements

Well-documented datasets include:

```bash
# Set essential global attributes
cdo setattribute,title="ERA5 Monthly Mean Temperature" \
    -setattribute,source="ERA5 Reanalysis" \
    -setattribute,institution="ECMWF" \
    -setattribute,references="Hersbach et al. (2020)" \
    -setattribute,history="Created by CDO training course" \
    -setattribute,Conventions="CF-1.8" \
    input.nc output.nc

# Set variable attributes
cdo setattribute,t2m@long_name="Near-Surface Air Temperature" \
    -setattribute,t2m@standard_name="air_temperature" \
    -setattribute,t2m@units="K" \
    -setattribute,t2m@cell_methods="time: mean" \
    input.nc output.nc
```

### Viewing Metadata

```bash
# Full file header (NCO)
ncdump -h data.nc

# Global attributes only
cdo gattr data.nc

# Variable attributes
cdo vardes data.nc

# Time coordinate attributes
cdo showattribute,time@units data.nc
cdo showattribute,time@calendar data.nc
```

## NetCDF Compression

Compression is critical for managing the large file sizes common in climate research.

### CDO Compression Levels

```bash
# Compression levels 0-9 (0 = no compression, 9 = maximum)
cdo -z zip_0 input.nc output.nc   # No compression
cdo -z zip_1 input.nc output.nc   # Fast, minimal compression
cdo -z zip_5 input.nc output.nc   # Good balance (recommended)
cdo -z zip_9 input.nc output.nc   # Maximum compression (slowest)
```

```{important}
Compression is lossless - the original data is perfectly reconstructed. NetCDF-4 format (HDF5-based) is required for compression.
```

### Performance Comparison

| Level | File Size | Write Time | Read Time | Use Case |
|-------|-----------|------------|-----------|----------|
| 0 | 100% | Fast | Fast | Temporary files |
| 1 | ~45% | Fast | Fast | Frequent access |
| 5 | ~30% | Moderate | Moderate | **Archival (recommended)** |
| 9 | ~25% | Slow | Slow | Long-term storage |

### Benchmarking Compression

```bash
#!/bin/bash
# Compare compression levels

INPUT="large_dataset.nc"

for level in 0 1 5 9; do
    echo "Testing compression level $level..."
    
    # Time the compression
    start=$(date +%s)
    cdo -z zip_${level} -f nc4 "$INPUT" "compressed_${level}.nc"
    end=$(date +%s)
    time=$((end - start))
    
    # Check size
    orig_size=$(stat -c%s "$INPUT")
    comp_size=$(stat -c%s "compressed_${level}.nc")
    ratio=$(echo "scale=2; $comp_size / $orig_size * 100" | bc)
    
    echo "  Level $level: ${ratio}% of original, took ${time}s"
done
```

```{tip}
For most applications, compression level 5 offers the best balance between file size and processing speed.
```

## Deflate Level Options

```bash
# Specify deflate (gzip) compression level explicitly
cdo -z zip_5 -f nc4 input.nc output.nc

# Set chunk size for better compression
cdo -z zip_5 -f nc4 -setchunk,100,100 input.nc output.nc

# Check compression of existing file
ncdump -hs data.nc | grep "_DeflateLevel\|_ChunkSizes"
```

## Missing Values Handling

Climate data often contains missing values (e.g., ocean grid points, non-overlapping regions).

### Detecting Missing Values

```bash
# Check if a file has missing values
cdo info input.nc | grep -v "Miss  :     0" | head -5

# Count missing values
cdo info input.nc | awk '{if ($5 > 0) print "Variable has", $5, "missing points"}'

# Show fraction of missing data per timestep
cdo timavg -setctomiss,0 input.nc | cdo info -

# Create a mask of valid data points
cdo gtc,0 -setctomiss,-999 input.nc mask.nc
```

### Setting Missing Values

```bash
# Set specific value as missing
cdo setmissval,-999 input.nc output.nc

# Set values equal to or greater than a threshold to missing
cdo setctomiss,300 input.nc output.nc  # Set values >= 300 to missing
cdo setrtomiss,250,300 input.nc output.nc  # Set range to missing

# Set values less than a threshold to missing
cdo setltomiss,250 input.nc output.nc
cdo setgtomiss,320 input.nc output.nc

# Replace missing values with a constant
cdo setmisstoc,0 input.nc output.nc  # Set missing to 0

# Fill missing values by interpolation
cdo intfill input.nc output.nc

# Fill missing values with nearest neighbor
cdo fillmiss input.nc output.nc
```

```{warning}
Different datasets use different missing value conventions (-999, 1e20, NaN). Always check before processing.
```

### Missing Value Workflow Example

```bash
#!/bin/bash
# Complete missing value handling workflow

INPUT="data_with_gaps.nc"
OUTPUT="cleaned_data.nc"

echo "Step 1: Identify missing value indicator"
cdo info "$INPUT" | head -10

echo "Step 2: Check missing value count"
cdo info "$INPUT" | awk '{sum += $5} END {print "Total missing:", sum}'

echo "Step 3: Apply mask (only ocean points, for example)"
cdo ifthen land_mask.nc -selname,t2m "$INPUT" masked.nc

echo "Step 4: Fill remaining missing values"
cdo fillmiss masked.nc "$OUTPUT"

echo "Step 5: Verify no missing values remain"
cdo info "$OUTPUT" | awk '{if ($5 > 0) print "WARNING: Missing values remain"}'

echo "Cleanup"
rm masked.nc
```

## NetCDF Chunking and Performance

Chunking divides NetCDF data into rectangular blocks for efficient I/O.

### Understanding Chunks

```bash
# Check current chunking
ncdump -hs data.nc | grep "_ChunkSizes"

# Set chunk sizes
cdo setchunk,100,100 input.nc output.nc  # 2D chunks

# Automatic chunk selection
cdo setchunk,auto input.nc output.nc

# Performance-related chunking
# For time series access: chunk along time
# For spatial access: chunk along lat/lon
```

```{note}
Proper chunking can dramatically improve performance. Time-series access benefits from chunking along the time dimension; spatial analysis benefits from chunking in lat/lon.
```

### Chunking Strategies

| Access Pattern | Recommended Chunking | Example |
|----------------|---------------------|---------|
| **Time series** | Small time, large space | `-setchunk,1,100,100` |
| **Spatial slice** | Large time, small space | `-setchunk,100,10,10` |
| **Single point** | Small time, small space | `-setchunk,1,1,1` |
| **Balanced** | Moderate all | `-setchunk,10,50,50` |

### Performance Benchmarking

```bash
#!/bin/bash
# Test different chunk sizes

INPUT="large.nc"
OUTPUT_DIR="./chunk_test"
mkdir -p "$OUTPUT_DIR"

for chunks in "1,100,100" "10,50,50" "100,10,10" "auto"; do
    echo "Testing chunks: $chunks"
    
    # Time the copy with chunking
    time cdo -z zip_5 -setchunk,$chunks "$INPUT" "$OUTPUT_DIR/chunk_${chunks//,/_}.nc"
done
```

## Converting to/from NetCDF

### Converting to NetCDF

```bash
# GRIB to NetCDF
cdo -f nc copy input.grib output.nc

# GRIB to NetCDF with compression
cdo -z zip_5 -f nc copy input.grib output.nc

# GRIB to NetCDF4
cdo -f nc4 -z zip_5 copy input.grib output.nc

# HDF5 to NetCDF
cdo -f nc copy input.h5 output.nc

# Extract specific variable during conversion
cdo -f nc -selname,t2m copy input.grib output.nc
```

```{warning}
When converting GRIB to NetCDF, parameter IDs and level types must be properly mapped. Use `-selname` to select specific variables during conversion.
```

### Converting from NetCDF

```bash
# NetCDF to GRIB
cdo -f grb2 copy input.nc output.grib

# NetCDF to ASCII
cdo output input.nc > data.txt

# NetCDF to CSV-like format
cdo outputf,%5.2f,1 input.nc > formatted.txt

# NetCDF to binary
cdo -b F64 copy input.nc output_f64.nc  # 64-bit floats
```

## Using ncdump and ncgen from NCO

The NCO toolkit complements CDO with low-level NetCDF operations.

### ncdump - NetCDF Dump

```bash
# View file header (metadata only)
ncdump -h data.nc

# View header with data
ncdump data.nc | head -100

# View specific variable
ncdump -v t2m data.nc

# View specific variable header only
ncdump -v t2m -h data.nc

# View attributes only
ncdump -h data.nc | grep ":"

# View dimensions
ncdump -h data.nc | grep "dimensions:" -A 10

# Optional ncdump flags:
# -c             Show coordinate data
# -p 1,5         Print string with given length
# -f [c|f|e]     Format floating point
# -l [length]    Set line length
```

### ncgen - NetCDF Generation

```bash
# Create NetCDF from CDL (text description)
ncgen -o output.nc file.cdl

# Generate CDL template
ncdump -h data.nc > template.cdl

# Modify template and regenerate
# Edit template.cdl with text editor
ncgen -o modified.nc template.cdl

# Generate Fortran/Python code from file structure
ncdump -c data.nc > code_snippet.txt
```

### Creating a CDL File

```text
netcdf sample {
dimensions:
    time = UNLIMITED ; // (10 currently)
    lat = 5 ;
    lon = 10 ;
variables:
    double time(time) ;
        time:units = "hours since 2020-01-01 00:00:00" ;
        time:calendar = "standard" ;
    double lat(lat) ;
        lat:units = "degrees_north" ;
        lat:long_name = "Latitude" ;
    double lon(lon) ;
        lon:units = "degrees_east" ;
        lon:long_name = "Longitude" ;
    float t2m(time, lat, lon) ;
        t2m:units = "K" ;
        t2m:long_name = "2m temperature" ;
        t2m:standard_name = "air_temperature" ;
        t2m:missing_value = -999.f ;

data:
    lat = 0, 1, 2, 3, 4 ;
    lon = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ;
}
```

```bash
# Generate the NetCDF file
ncgen -o sample.nc sample.cdl
ncdump -h sample.nc
```

## CDO + NCO Integration

CDO and NCO work best together, each excelling at different tasks:

### When to Use CDO vs NCO

| Task | Tool |
|------|------|
| Climate-specific operations (means, remapping) | **CDO** |
| File structure manipulation | **NCO** (ncks, ncatted) |
| Attribute editing | **Both** (CDO: setattribute, NCO: ncatted) |
| Dimension manipulation | **NCO** (ncks) |
| Variable renaming | **Both** (CDO: chname, NCO: ncrename) |
| Data subsetting | **CDO** (selname, seldate) |
| Format conversion | **CDO** (-f nc, -f grb2) |

### Common NCO Commands

```bash
# Extract hyperslab (NCO)
ncks -d lat,10,20 -d lon,10,30 input.nc output.nc

# Edit attributes (NCO)
ncatted -a units,t2m,o,c,"K" input.nc output.nc

# Rename dimension (NCO)
ncrename -d old_dim,new_dim input.nc output.nc

# Append records (NCO)
ncrcat file1.nc file2.nc combined.nc

# Weighted average (NCO)
ncwa -a lat,lon input.nc output.nc
```

### Practical Integration Example

```bash
#!/bin/bash
# CDO + NCO workflow

INPUT="model_data.nc"

echo "Step 1: CDO - select variable and compute seasonal mean"
cdo timmean -selseas,JJA -selname,t2m "$INPUT" season.nc

echo "Step 2: NCO - add detailed metadata"
ncatted -a long_name,t2m,o,c,"June-July-August Mean Temperature" season.nc
ncatted -a cell_methods,t2m,o,c,"time: mean within years time: mean over years" season.nc

echo "Step 3: CDO - convert to GRIB"
cdo -f grb2 copy season.nc season.grib

echo "Step 4: CDO - check result"
cdo sinfo season.nc
```

```{tip}
Use CDO for climate-specific processing and NCO for low-level NetCDF structure manipulation. Combining both gives you complete control.
```

## Advanced NetCDF Operations

### Working with Aggregated Data

```bash
# Compute ensemble statistics
cdo ensmean model1.nc model2.nc model3.nc ensemble_mean.nc
cdo ensstd model1.nc model2.nc model3.nc ensemble_std.nc

# Compute multi-year means
cdo yearmean input.nc annual_means.nc
cdo ymonmean input.nc monthly_climatology.nc
cdo yseasmean input.nc seasonal_climatology.nc

# Detrending
cdo detrend input.nc detrended.nc

# Smoothing
cdo smooth,9 input.nc smoothed.nc  # 9-point smoother
```

### Attribute Management

```bash
# Copy attributes from one file to another
cdo copy input.nc output.nc

# Preserve history with -h flag
cdo -h copy input.nc output.nc

# Remove all attributes
cdo setattribute,, input.nc output.nc

# Modify time axis
cdo settaxis,2020-01-01,00:00:00,1hour input.nc output.nc

# Set calendar
cdo setcalendar,standard input.nc output.nc
```

### Date/Time Manipulation

```bash
# Shift time axis
cdo shifttime,1day input.nc output.nc

# Select specific dates
cdo seldate,2020-06-01,2020-08-31 input.nc summer.nc

# Select specific time of day
cdo selhour,0,6,12,18 input.nc diurnal.nc

# Compute time mean
cdo timmean input.nc output.nc

# Compute daily statistics from hourly
cdo daymean input.nc daily.nc
cdo daymin input.nc daily_min.nc
cdo daymax input.nc daily_max.nc
```

## Hands-On Exercises

### Exercise 1: Examine NetCDF Structure

````{exercise}
:label: ex-netcdf-1
Create a test dataset and examine its structure:

```bash
# Create test data
cdo -f nc -random,50,10,10 test_structure.nc

# Examine with CDO
cdo sinfo test_structure.nc
cdo vardes test_structure.nc
cdo griddes test_structure.nc
cdo ntime test_structure.nc
cdo nlevel test_structure.nc

# Examine with NCO
ncdump -h test_structure.nc

# Answer:
1. How many dimensions does the file have?
2. What are the variable names and their dimensions?
3. Is the time dimension unlimited?
4. What attributes are set on each variable?
```
````

### Exercise 2: Compression Comparison

````{exercise}
:label: ex-netcdf-2
Compare compression levels on a large (or artificially large) dataset:

```bash
# Create a test dataset
cdo -f nc -random,5000,100,100 test_large.nc

# Compress at different levels
for level in 0 1 5 9; do
    echo "=== Compression level $level ==="
    time cdo -z zip_${level} -f nc4 test_large.nc "compress_${level}.nc"
    ls -lh "compress_${level}.nc"
done

# Create a comparison table
echo ""
echo "Level | Size | Ratio"
echo "------|------|-------"
for level in 0 1 5 9; do
    orig=$(stat -c%s "test_large.nc")
    comp=$(stat -c%s "compress_${level}.nc")
    pct=$(echo "scale=1; $comp * 100 / $orig" | bc)
    echo "$level | ${pct}%"
done

# Verify data integrity
cdo diff test_large.nc compress_9.nc && echo "Data preserved perfectly!"

# Cleanup
rm test_large.nc compress_*.nc
```
````

### Exercise 3: Missing Values

````{exercise}
:label: ex-netcdf-3
Practice working with missing values:

```bash
# Create data with missing values
cdo -f nc -random,20,10,10 test_data.nc

# Create a mask with 20% missing
cdo -f nc -random,0,10,10 -setrtomiss,0.8,9999.0 test_data.nc masked.nc

# Examine missing values
cdo info masked.nc

# Operations:
# 1. Count total missing values
cdo info masked.nc | awk '{sum += $5} END {print "Total missing:", sum}'

# 2. Fill missing values
cdo fillmiss masked.nc filled.nc

# 3. Set specific value to missing
cdo setmisstoc,-999.0 filled.nc final.nc

# 4. Verify no missing remain
cdo info final.nc | awk '{if ($5 > 0) print "WARNING: Missing values still exist"}'

# Cleanup
rm test_data.nc masked.nc filled.nc final.nc
```
````

### Exercise 4: Attribute Manipulation

````{exercise}
:label: ex-netcdf-4
Practice adding and modifying metadata:

```bash
# Create test file
cdo -f nc -random,10,5,5 raw.nc

# Add comprehensive metadata
cdo -setattribute,title="Training Dataset" \
    -setattribute,description="Created for CDO training course" \
    -setattribute,creation_date="$(date +%Y-%m-%d)" \
    -setattribute,creator="CDO Training Participant" \
    -setattribute,Conventions="CF-1.8" \
    raw.nc metadata.nc

# Add variable-specific attributes
cdo -setattribute,var1@long_name="Temperature" \
    -setattribute,var1@units="K" \
    -setattribute,var1@standard_name="air_temperature" \
    metadata.nc attrs.nc

# Verify the metadata
ncdump -h attrs.nc

# Extract specific attributes
cdo showattribute,title attrs.nc
cdo vardes attrs.nc

# Cleanup
rm raw.nc metadata.nc attrs.nc
```
````

### Exercise 5: CDO + NCO Workflow

````{exercise}
:label: ex-netcdf-5
Write a complete workflow using both CDO and NCO:

```bash
#!/bin/bash
# Integrated CDO + NCO workflow

set -e  # Exit on error

echo "=== CDO + NCO Integration Exercise ==="

# Step 1: Create test data simulating model output
echo "Creating test data..."
cdo -f nc -random,100,10,10 model_output.nc

# Step 2: Use CDO for climate operations
echo "Computing climatology..."
cdo timmean model_output.nc climatology.nc

# Step 3: Use NCO for metadata enhancement
echo "Adding CF-compliant metadata..."
ncatted -h -a long_name,var1,o,c,"Surface Temperature" climatology.nc
ncatted -h -a units,var1,o,c,"K" climatology.nc
ncatted -h -a standard_name,var1,o,c,"surface_temperature" climatology.nc
ncatted -h -a cell_methods,var1,o,c,"time: mean" climatology.nc
ncatted -h -a Conventions,global,o,c,"CF-1.8" climatology.nc

# Step 4: Verify with ncdump
echo "Final metadata:"
ncdump -h climatology.nc

# Step 5: Comparison between tools
echo "CDO rename:"
time cdo chname,var1,t2m climatology.nc renamed_cdo.nc

echo "NCO rename:"
time ncrename -v var1,t2m climatology.nc renamed_nco.nc

# Cleanup
rm -f model_output.nc climatology.nc renamed_cdo.nc renamed_nco.nc

echo "Exercise complete!"
```
````

## Quiz

```{admonition} Quiz
:class: tip
Test your knowledge of NetCDF data handling with CDO.
```

```{exercise} Question 1: Which NetCDF version supports compression and files larger than 2 GB?
:label: q-netcdf-1

A. NetCDF Classic  
B. NetCDF-3  
C. NetCDF-4 (HDF5-based)  
D. NetCDF-64bit  

```

```{solution} q-netcdf-1
C. NetCDF-4 (HDF5-based)
```

```{exercise} Question 2: What CDO flag enables compression?
:label: q-netcdf-2

A. `-c`  
B. `-z zip_N`  
C. `-compress`  
D. `-d`  

```

```{solution} q-netcdf-2
B. `-z zip_N` (where N is the compression level 0-9)
```

```{exercise} Question 3: Which CDO command replaces missing values with interpolated values?
:label: q-netcdf-3

A. `cdo setmisstoc`  
B. `cdo fillmiss`  
C. `cdo setmissval`  
D. `cdo setctomiss`  

```

```{solution} q-netcdf-3
B. `cdo fillmiss`
```

```{exercise} Question 4: What does the NCO command `ncdump -h data.nc` do?
:label: q-netcdf-4

A. Dumps the entire file contents  
B. Dumps only the header (metadata)  
C. Dumps only variable data  
D. Dumps the file in hexadecimal  

```

```{solution} q-netcdf-4
B. Dumps only the header (metadata)
```

```{exercise} Question 5: Which of the following is NOT a component of a NetCDF file?
:label: q-netcdf-5

A. Dimensions  
B. Variables  
C. Attributes  
D. Templates  

```

```{solution} q-netcdf-5
D. Templates
```

## Summary

In this module, we covered:

- **NetCDF structure**: dimensions, variables, attributes, global metadata
- **CF conventions**: standard names, units, cell methods for interoperability
- **Compression**: `-z zip_0` through `-z zip_9`, with level 5 recommended
- **Missing values**: detection (`setmissval`), filling (`fillmiss`), masking
- **Chunking**: optimizing I/O for different access patterns
- **NCO tools**: `ncdump` (viewing), `ncgen` (creating), `ncatted` (editing)
- **CDO + NCO integration**: complementary tools for complete NetCDF control
- **Format conversion**: GRIB→NetCDF, NetCDF→GRIB, binary, ASCII

```{admonition} Key Points
:class: note
- NetCDF is self-describing - use metadata to document your data
- Always use compression (level 5) for archival and large datasets
- Handle missing values carefully - different datasets use different conventions
- CF conventions ensure data interoperability across tools and platforms
- NCO complements CDO for low-level NetCDF operations
```

## References

- NetCDF Documentation: https://docs.unidata.ucar.edu/nug/current/
- CF Conventions: http://cfconventions.org/
- CF Standard Names: http://cfconventions.org/standard-names.html
- NCO Toolkit: http://nco.sourceforge.net/
- NetCDF User Guide: https://www.unidata.ucar.edu/software/netcdf/docs/
