---
title: "Module 4: CDO Operators and File Operations"
subject: Climate Data Operators Training
subtitle: "Exploring and Manipulating Climate Data"
---

# Module 4: CDO Operators and File Operations

## Learning Objectives

By the end of this module, you will be able to:

- Understand CDO operator syntax and categories
- Explore dataset information using CDO info operators
- Perform file manipulations like merging, splitting, and copying
- Select, rename, and delete variables within datasets
- Change variable attributes such as names and units
- Compare datasets and identify differences
- Build efficient multi-step processing pipelines

---

## Overview of CDO Operators

CDO provides hundreds of operators organized into functional categories. Each operator performs a specific task on climate data.

```{note}
CDO's strength lies in its operator concept. With hundreds of operators, you can perform almost any climate data operation without writing custom code.
```

## Operator Syntax

The fundamental CDO command structure:

```bash
cdo [global_options] operator [operator_options] input_file output_file
```

### Global Options

Global options modify CDO's overall behavior and appear before the operator:

```bash
# Format selection
cdo -f nc input.grib output.nc
cdo -f grb2 input.nc output.grib

# Compression
cdo -z zip_5 input.nc output.nc

# History metadata
cdo -h input.nc output.nc

# Verbose mode
cdo -v timmean input.nc output.nc

# Suppress warnings
cdo -s timmean input.nc output.nc
```

```{tip}
Use `cdo -h` to preserve processing history in the output file's metadata - useful for reproducibility.
```

### Operator Options

Some operators accept their own specific options:

```bash
# Select with operator options
cdo selname,t2m input.nc output.nc
cdo seldate,2020-01-01,2020-12-31 input.nc output.nc
cdo sellevel,1,10,20 input.nc output.nc

# Remapping with options
cdo remapbil,grid.txt input.nc output.nc
cdo remapcon,r360x180 input.nc output.nc
```

## Operator Categories

| Category | Description | Examples |
|----------|-------------|---------|
| **File Operations** | File I/O, format conversion | `copy`, `cat`, `merge`, `split` |
| **Information** | Dataset metadata and info | `sinfo`, `info`, `vardes`, `griddes` |
| **Selection** | Variable, level, time, region | `selname`, `seldate`, `sellonlatbox` |
| **Temporal Statistics** | Time aggregation | `timmean`, `timsum`, `timmax`, `timstd` |
| **Spatial Statistics** | Spatial aggregation | `fldmean`, `fldsum`, `fldmax`, `fldstd` |
| **Vertical Statistics** | Level operations | `vertmean`, `vertsum`, `vertint` |
| **Arithmetic** | Mathematical operations | `add`, `sub`, `mul`, `div`, `sqrt` |
| **Conditional** | Masking and selection | `ifthen`, `mask`, `expr` |
| **Grid** | Grid operations and interpolation | `remapbil`, `griddes`, `setgrid` |
| **Ensemble** | Multi-member statistics | `ensmean`, `ensmax`, `ensstd` |
| **Field** | Field operations | `trend`, `detrend`, `smooth` |
| **Comparison** | Dataset comparison | `diff`, `cmp`, `min`, `max` |

```{note}
To see a complete list of all available operators with descriptions, run `cdo --help`.
```

## Exploring Dataset Information

Before processing climate data, understanding its structure is crucial.

### cdo sinfo - Dataset Information

```bash
cdo sinfo data.nc
```

Example output:
```
   File format: NetCDF4
    -1 : Institut Source   T Steptype Levels Num    Points Num Dtype : Parameter name
     1 : unknown   unknown  v instant     37   1     10692   1  F32 : t2m
     2 : unknown   unknown  v instant     37   1     10692   1  F32 : tp
   Horizontal grid  : curvilinear
   ... 
```

```{tip}
`sinfo` gives a concise overview of all variables, their dimensions, and the grid type in one view.
```

### cdo showdate / cdo showtime - Time Information

```bash
# Show all dates in the dataset
cdo showdate data.nc

# Show all timesteps
cdo showtime data.nc

# Show timestep count
cdo ntime data.nc

# Show time range
cdo showyear data.nc | tr ' ' '\n' | head -1
cdo showyear data.nc | tr ' ' '\n' | tail -1

# Compact time info
echo "Timesteps: $(cdo ntime data.nc)"
echo "Date range: $(cdo showdate data.nc | tr ' ' '\n' | head -1) to $(cdo showdate data.nc | tr ' ' '\n' | tail -1)"
```

### cdo griddes - Grid Description

```bash
# Show grid description
cdo griddes data.nc

# Save grid to file for reuse
cdo griddes data.nc > grid.txt

# Apply same grid to another dataset
cdo remapbil,grid.txt other_data.nc remapped.nc
```

Example output:
```
gridtype  = lonlat
gridsize  = 10692
xsize     = 108
ysize     = 99
xfirst    = -0.5
xinc      = 1
yfirst    = -0.5
yinc      = 1
```

### cdo ntime - Number of Timesteps

```bash
cdo ntime data.nc
```

### cdo vardes - Variable Descriptions

```bash
# Show variable descriptions (detailed)
cdo vardes data.nc

# Count variables
cdo vardes data.nc | grep -c "^[0-9]"

# List variable names only
cdo vardes data.nc | grep "^[0-9]" | awk '{print $2}'
```

### cdo nlevel - Number of Levels

```bash
# Show number of levels for each variable
cdo nlevel data.nc

# Check if data is 2D or 3D
if [ "$(cdo nlevel data.nc | head -1)" -eq 1 ]; then
    echo "Surface data (2D)"
else
    echo "3D data with multiple levels"
fi
```

### cdo diff - Compare Datasets

```bash
# Compare two datasets
cdo diff file1.nc file2.nc

# Compare with tolerance
cdo diff -t 1e-5 file1.nc file2.nc

# Check if files are identical
if cdo diff file1.nc file2.nc > /dev/null 2>&1; then
    echo "Files are identical"
else
    echo "Files differ"
    cdo diff file1.nc file2.nc
fi

# Compare specific variable
cdo diff -selname,t2m file1.nc -selname,t2m file2.nc
```

```{warning}
`cdo diff` returns an exit code of 0 if files are identical and 1 if they differ. Use this in scripts for automated checks.
```

### cdo info - Detailed Information

```bash
# Display detailed dataset info
cdo info data.nc

# Info for specific variable
cdo info -selname,t2m data.nc

# Summary statistics
cdo info data.nc | tail -1
```

Example output:
```
    -1 : Source  Date     Time    Level   Gridsize    Miss  :  Mean     Min     Max
     1 : unknown 2020-01-01 00:00:00      1     10692      0  :  285.2  250.1  310.3
     1 : unknown 2020-01-01 01:00:00      1     10692      0  :  285.3  249.8  310.5
```

## File Manipulation

### Merging Files

```bash
# Merge by record dimension (concatenate along time)
cdo mergetime jan.nc feb.nc mar.nc winter.nc

# Merge multiple files with wildcards
cdo mergetime *.nc merged.nc

# Merge files with different grids
cdo mergegrid file1.nc file2.nc merged_grid.nc

# Merge by appending time (files must be in correct order)
cdo mergetime 2020_01.nc 2020_02.nc 2020_03.nc q1_2020.nc
```

```{note}
`cdo mergetime` concatenates along the time dimension. Files must have the same variables and grids, and timesteps must not overlap.
```

### Splitting Files

```bash
# Split into individual timesteps
cdo splitsel data.nc split_

# Split by years
cdo splityear data.nc year_

# Split by months
cdo splitmon data.nc month_

# Split by seasons
cdo splitseas data.nc season_

# Split by days
cdo splitday data.nc day_

# Split selecting specific timesteps
cdo splitsel,1,10,20 data.nc selected_
```

```{tip}
Splitting is useful for parallel processing. Split a large file by years, process each year independently, then merge the results.
```

### Copy and Concatenate

```bash
# Copy (change format or compression)
cdo copy data.nc copy.nc
cdo -f nc -z zip_5 copy input.grib output.nc

# Concatenate (no time sorting)
cdo cat part1.nc part2.nc combined.nc

# Difference between mergetime and cat:
# - mergetime: sorts by time, handles gaps
# - cat: simple concatenation, no time checking
```

```{warning}
Use `cdo cat` only when you are certain the files are in the correct order. Use `cdo mergetime` for time-ordered concatenation.
```

### Selecting and Deleting Variables

```{exercise}
:label: ex-operators-1
Practice selecting and deleting variables from a dataset.
```

```bash
# Select variables by name
cdo selname,t2m,msl data.nc selected_vars.nc

# Select variables by position
cdo selvar,1,3 data.nc selected.nc

# Delete specific variables (keep all others)
cdo delete,name=tp data.nc without_precip.nc

# Delete multiple variables
cdo delete,name=tp,u10,v10 data.nc filtered.nc

# Select with operator options
cdo select,name=t2m data.nc t2m_only.nc
cdo select,code=167 data.grib selected.grib  # GRIB parameter code

# Chain selections
cdo selname,t2m -seldate,2020-01-01,2020-06-30 data.nc subset.nc
```

### Renaming Variables

```bash
# Rename a variable
cdo chname,t2m,temperature data.nc renamed.nc

# Rename multiple variables
cdo chname,t2m,temperature,msl,pressure, -setname,new_name data.nc modified.nc
```

### Setting Variable Names

```bash
# Set variable name to a different value
cdo setname,temperature data.nc updated.nc
```

### Changing Units

```bash
# Change units attribute
cdo chunit,t2m,K data.nc updated.nc

# Change multiple units
cdo chunit,t2m,K,tp,mm data.nc updated.nc
```

```{note}
Changing the units attribute does not convert the actual data values. Use dedicated conversion operators for that purpose.
```

### Practical Example: Multi-Step Processing

```bash
#!/bin/bash
# Comprehensive file manipulation example

set -e

INPUT="era5_2020.nc"
WORKDIR="./work"
OUTPUT="processed_era5_2020.nc"

mkdir -p "$WORKDIR"

echo "Step 1: Extract variables of interest"
cdo selname,t2m,msl,tp "$INPUT" "$WORKDIR/step1.nc"

echo "Step 2: Select summer months (JJA)"
cdo selmon,6/8 "$WORKDIR/step1.nc" "$WORKDIR/step2.nc"

echo "Step 3: Rename variables for clarity"
cdo chname,t2m,temperature,msl,sea_level_pressure,tp,total_precipitation \
    "$WORKDIR/step2.nc" "$WORKDIR/step3.nc"

echo "Step 4: Change units"
cdo chunit,temperature,K,sea_level_pressure,Pa,total_precipitation,m \
    "$WORKDIR/step3.nc" "$WORKDIR/step4.nc"

echo "Step 5: Set file metadata"
cdo setattribute,title="ERA5 processed data" \
    -setattribute,institution="Training Course" \
    "$WORKDIR/step4.nc" "$OUTPUT"

echo "Step 6: Clean up"
rm -r "$WORKDIR"

echo "Processing complete: $OUTPUT"
cdo sinfo "$OUTPUT"
```

## Dataset Comparison Operators

```bash
# Compare two datasets statistically
cdo min file1.nc file2.nc  # Minimum values
cdo max file1.nc file2.nc  # Maximum values
cdo sum file1.nc file2.nc  # Sum
cdo sub file1.nc file2.nc  # Difference (file1 - file2)

# Detect differences
cdo diff file1.nc file2.nc
cdo diffn file1.nc file2.nc  # Number of different grid points

# Statistical comparison
cdo timcor file1.nc file2.nc  # Temporal correlation
cdo timcov file1.nc file2.nc  # Temporal covariance

# Bias metrics
cdo sub model.nc obs.nc bias.nc
cdo timabs -sub model.nc obs.nc mae.nc
cdo sqr -timmean -sub model.nc obs.nc rmse.nc
```

## Working with File Metadata

```bash
# Set global attributes
cdo setattribute,title="My Dataset",institution="University" input.nc output.nc

# Set variable attribute
cdo setattribute,t2m@long_name="Near Surface Air Temperature" input.nc output.nc

# Set date and time
cdo setdate,2020-01-01 input.nc output.nc
cdo settime,00:00:00 input.nc output.nc

# Set calendar
cdo setcalendar,standard input.nc output.nc

# Set timestamp
cdo settaxis,2020-01-01,00:00:00,1hour input.nc output.nc

# Remove history attribute
cdo -h copy input.nc output.nc  # -h preserves history, use without it to remove

# Show variable attributes
cdo vardes input.nc

# Show global attributes
cdo gattr input.nc
```

## Grid Operations

```bash
# Get grid description
cdo griddes input.nc > grid.txt

# Set new grid
cdo setgrid,grid.txt input.nc output.nc

# Interpolate to regular grid
cdo remapbil,r360x180 input.nc output.nc  # 1-degree global grid

# Interpolate with destination grid from another file
cdo remapbil,target_grid.nc input.nc output.nc

# Different interpolation methods
cdo remapbil,...  # Bilinear interpolation
cdo remapbic,...  # Bicubic interpolation
cdo remapcon,...  # First-order conservative
cdo remapcon2,... # Second-order conservative
cdo remapdis,...  # Distance-weighted
cdo remapnn,...   # Nearest neighbor
```

```{note}
Always use conservative remapping (`remapcon`) for flux variables like precipitation, and bilinear (`remapbil`) for state variables like temperature.
```

## Chaining Multiple Operators

### Using Pipes

```bash
# Chain operators without intermediate files
cdo fldmean -timmean -selname,t2m input.nc output.nc

# The above is equivalent to:
cdo selname,t2m input.nc | cdo timmean - | cdo fldmean - output.nc

# More complex chain
cdo output -fldmean -timmean -selname,t2m -seldate,2020-06-01,2020-08-31 input.nc
```

### Using Temporary Files

```bash
# Explicit temp file approach
cdo selname,t2m input.nc temp1.nc
cdo timmean temp1.nc temp2.nc
cdo fldmean temp2.nc output.nc
rm temp1.nc temp2.nc
```

```{tip}
Use pipes for simple chains and temporary files for complex multi-step processing that needs debugging between steps.
```

### Advanced Pipeline Example

```bash
# Complete processing workflow
cdo output \
    -fldmean \
    -timmean \
    -selseas,JJA \
    -selname,t2m \
    -selyear,1990/2020 \
    input.nc > global_t2m_jja_1990_2020.txt

# Explanation:
# 1. Select years 1990-2020
# 2. Select variable t2m
# 3. Select JJA (June-August) season
# 4. Compute time mean
# 5. Compute spatial (field) mean
# 6. Output as text
```

## Error Handling and Troubleshooting

### Common Errors

```bash
# Error: "Unsupported file type"
# Solution: Specify format explicitly
cdo -f nc copy input.grib output.nc

# Error: "Insufficient memory"
# Solution: Reduce memory usage
export CDO_MEMORY=4
cdo -z zip_5 input.nc output.nc

# Error: "Different grid sizes"
# Solution: Remap to common grid first
cdo remapbil,common_grid.txt file1.nc remapped1.nc
cdo remapbil,common_grid.txt file2.nc remapped2.nc
cdo mergetime remapped1.nc remapped2.nc merged.nc
```

### Getting Help

```bash
# Help for specific operator
cdo --help | grep -A 5 "^timmean"
cdo --help | grep -A 10 "^selname"

# List operators by keyword
cdo --help | grep -i "remap\|interpolate"

# CDO documentation
cdo --help | less
```

## Hands-On Exercises

### Exercise 1: Explore a Dataset

````{exercise}
:label: ex-operators-2
Using any NetCDF or GRIB file (create a test file if needed):

```bash
# Create a test dataset
cdo -f nc -random,100,10,10 test.nc

# Explore it with these commands:
cdo sinfo test.nc
cdo vardes test.nc
cdo griddes test.nc
cdo ntime test.nc
cdo nlevel test.nc
cdo showdate test.nc
cdo info test.nc

# Answer:
1. How many variables does the file contain?
2. What is the grid type?
3. How many timesteps are there?
4. How many vertical levels?
5. What are the variable names?
```
````

### Exercise 2: Merge and Split

````{exercise}
:label: ex-operators-3
Create three monthly test files and practice merging and splitting:

```bash
# Create test files
cdo -f nc -random,50,10,10 jan.nc
cdo -f nc -random,50,10,10 feb.nc
cdo -f nc -random,50,10,10 mar.nc

# Set dates (simplified - in practice, use settaxis)
cdo settaxis,2020-01-01,00:00:00,1day jan.nc jan_dated.nc
cdo settaxis,2020-02-01,00:00:00,1day feb.nc feb_dated.nc
cdo settaxis,2020-03-01,00:00:00,1day mar.nc mar_dated.nc

# Merge
cdo mergetime jan_dated.nc feb_dated.nc mar_dated.nc q1_2020.nc
echo "Merged file created"

# Split the merged file
cdo splityear q1_2020.nc year_
cdo splitmon q1_2020.nc month_

# Verify
ls -lh
cdo sinfo q1_2020.nc
```
````

### Exercise 3: Variable Selection and Renaming

````{exercise}
:label: ex-operators-4
Practice variable manipulation:

```bash
# Create a multi-variable test file
cdo -f nc -random,50,10,10 multi.nc

# The -random operator creates variables named "var1", "var2", etc.

# Try these operations:
cdo selname,var1 only_var1.nc
cdo chname,var1,temperature renamed.nc
cdo setname,new_var_name renamed2.nc

# Delete a variable
cdo delete,name=var2 without_var2.nc

# Compare original and processed files
cdo sinfo multi.nc
cdo sinfo only_var1.nc
cdo sinfo renamed.nc
```
````

### Exercise 4: Build a Processing Pipeline

````{exercise}
:label: ex-operators-5
Create a bash script that:

1. Takes an input file and output file as arguments
2. Extracts a specific variable
3. Selects a time range
4. Computes a seasonal mean
5. Renames the variable
6. Sets appropriate attributes

```bash
#!/bin/bash
# Pipeline script

INPUT=$1
OUTPUT=$2
VAR=${3:-t2m}
YEAR=${4:-2020}

echo "Pipeline: $INPUT -> $OUTPUT"
echo "Variable: $VAR, Year: $YEAR"

cdo setname,${VAR}_seasonal \
    -timmean \
    -selseas,JJA \
    -selname,$VAR \
    -selyear,$YEAR \
    "$INPUT" "$OUTPUT"

echo "Pipeline complete"
```
````

### Exercise 5: Dataset Comparison

````{exercise}
:label: ex-operators-6
Create two slightly different datasets and practice comparison:

```bash
# Create base dataset
cdo -f nc -random,20,5,5 base.nc

# Create a modified version
cdo -f nc -random,20,5,5 modified.nc

# Compare them
cdo diff base.nc modified.nc
echo "Exit code: $?"

# Compute differences
cdo sub base.nc modified.nc diff.nc
cdo info diff.nc

# Statistical comparison
cdo timcor base.nc modified.nc correlation.nc
cdo info correlation.nc

# Answer:
1. Do the files differ?
2. What is the range of differences?
3. What is the spatial correlation between them?
```
````

## Quiz

```{admonition} Quiz
:class: tip
Test your knowledge of CDO operators and file operations.
```

```{exercise} Question 1: Which CDO operator concatenates files along the time dimension with time sorting?
:label: q-operators-1

A. `cdo cat`  
B. `cdo merge`  
C. `cdo mergetime`  
D. `cdo copy`  

```

```{solution} q-operators-1
C. `cdo mergetime`
```

```{exercise} Question 2: Which command shows the grid description of a NetCDF file?
:label: q-operators-2

A. `cdo sinfo`  
B. `cdo griddes`  
C. `cdo vardes`  
D. `cdo showgrid`  

```

```{solution} q-operators-2
B. `cdo griddes`
```

```{exercise} Question 3: What does the command `cdo selname,t2m input.nc output.nc` do?
:label: q-operators-3

A. Deletes the t2m variable from the file  
B. Selects only the t2m variable from the file  
C. Renames t2m to a new name  
D. Lists all variables except t2m  

```

```{solution} q-operators-3
B. Selects only the t2m variable from the file
```

```{exercise} Question 4: Which operator is used to split a dataset into yearly files?
:label: q-operators-4

A. `cdo split`  
B. `cdo splityear`  
C. `cdo splitmon`  
D. `cdo splitsel`  

```

```{solution} q-operators-4
B. `cdo splityear`
```

```{exercise} Question 5: In the CDO command `cdo -z zip_5 -f nc copy input.grib output.nc`, what does `-z zip_5` do?
:label: q-operators-5

A. Sets the output format to NetCDF  
B. Sets compression level 5  
C. Copies 5 files  
D. Selects 5 variables  

```

```{solution} q-operators-5
B. Sets compression level 5
```

## Summary

In this module, we covered:

- **Operator syntax**: `cdo [global_options] operator [opts] input output`
- **Information operators**: `sinfo`, `showdate`, `griddes`, `ntime`, `vardes`, `nlevel`, `diff`, `info`
- **File manipulation**: `mergetime`, `mergetime`, `splityear`, `splitmon`, `copy`, `cat`
- **Variable selection**: `selname`, `selvar`, `delete`, `select`
- **Attribute editing**: `chname`, `setname`, `chunit`, `setattribute`
- **Chaining**: pipes (`|`) and multi-operator commands
- **Processing pipelines**: combining operators for complete workflows

```{admonition} Key Points
:class: note
- Always explore a dataset with information operators before processing
- Use `mergetime` for time-based concatenation, not `cat`
- Pipes avoid intermediate files and improve efficiency
- Verify processing with `diff` or `info` after operations
- Set attributes to maintain metadata provenance
```

## References

- CDO Operator Documentation: https://code.mpimet.mpg.de/projects/cdo/wiki/Cdo
- CDO Reference Card: https://code.mpimet.mpg.de/attachments/download/26599/cdo_refcard.pdf
- CDO User Guide: https://code.mpimet.mpg.de/projects/cdo/embedded/index.html
