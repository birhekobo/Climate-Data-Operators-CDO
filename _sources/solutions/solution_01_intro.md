# Solution 1: CDO Basics

## Task 1: Install and Verify CDO

### Command to check version:
```bash
cdo --version
```

### Example output:
```
Climate Data Operators version 2.4.0 (https://mpimet.mpg.de/cdo)
Copyright: (C) 2005-2024 Max Planck Institute for Meteorology
Based on: NetCDF 4.9.2 | HDF5 1.14.3 | JasPer 4.0.0 | ...
Features: OpenMP 16 threads, HDF5, NC4/HDF5, SZIP, ZLIB, S3
```

### Answers:
1. **What command shows the installed CDO version?** `cdo --version` or `cdo -V`
2. **What is your installed CDO version?** (Will vary; example: 2.4.0)
3. **What is the installed NetCDF library version?** Look at the "Based on" line in `cdo --version` output.

---

## Task 2: Explore CDO Operators

### Example table of 10 operators:

| # | Operator | Category | Description |
|---|----------|----------|-------------|
| 1 | `sinfo`  | INFO     | Prints information about a dataset |
| 2 | `copy`   | FILE OPERATIONS | Copies a dataset (can also compress) |
| 3 | `selyear`| SELECT   | Selects a specific time period by year |
| 4 | `mergetime` | FILE OPERATIONS | Merges multiple files along the time axis |
| 5 | `monmean`| STATISTICS | Computes monthly mean values |
| 6 | `yearmean` | STATISTICS | Computes annual mean values |
| 7 | `fldmean` | STATISTICS | Computes spatial (field) mean |
| 8 | `remapbil`| REMAPPING | Bilinear interpolation to a target grid |
| 9 | `sub`    | ARITHMETIC | Subtracts two fields (field1 - field2) |
|10 | `outputts` | OUTPUT | Prints time series as ASCII table |

---

## Task 3: Run `sinfo` on a Sample File

### Command:
```bash
cdo sinfo ../datasets/tas_sample.nc > sinfo_output.txt
```

### Example output:
```
   File format: NetCDF4
    -1 : Institut Source   Steptype Levels Num    Points Num Dtype : Parameter name
     1 : unknown/mixed     instant      1   1     64800   1  F32  : tas
   Grid coord : lonlat
   Grid size  : 64800 (360 x 180)
   Grid origin: -179.5 / -89.5
   Grid inc   : 1 / 1
   Vertical coordinates : 0 Pa
   Time range : 372 steps
   Time range : 1980-01-01 00:00:00 - 2010-12-01 00:00:00
   Calendar   : standard
   ...
```

### Answers:
1. **How many variables?** 1 variable: `tas`
2. **Grid type and dimensions?** lonlat (regular latitude-longitude), 360×180 cells (64800 points)
3. **Time range?** 1980-01-01 to 2010-12-01 (372 months, 31 years)
4. **How many time steps?** 372
5. **Calendar type?** standard (Gregorian)
6. **Data type?** F32 (32-bit float)

---

## Task 4: CDO Architecture Questions

### 1. What does CDO stand for?
CDO = **Climate Data Operators**. It is a command-line tool for manipulating and analyzing climate and forecast data (NetCDF, GRIB, etc.).

### 2. How does CDO handle memory for large datasets?
CDO uses a stream-based processing model. It reads data in chunks (tiles) and processes them without loading the entire dataset into memory. The `-buffersize` option controls the chunk size. For very large datasets, CDO can use the `-t` (tile) option to process data in spatial tiles, and can work with external memory (file-based temporary storage).

### 3. File formats CDO can read/write (5+ formats):
- NetCDF3/4 (.nc)
- GRIB1/GRIB2 (.grb, .grib)
- SERVICE (DAP/OPeNDAP URLs)
- EXTRA (various binary formats)
- IEG (IEEE binary)
- CSV / ASCII table
- GRB (GRIB)
- HDF5 (.h5, via NetCDF4)

### 4. Difference between operator and modifier:
- **Operator**: Performs an action on the data (e.g., `monmean`, `copy`, `selname`)
- **Modifier**: Changes how operators behave (e.g., `-f nc4` changes output format, `-z zip` compresses, `-selname` restricts which variables are processed). Modifiers are prefixed with `-` and can be combined.

### 5. The pipe (`-`) meaning:
The pipe character `-` tells CDO to read from stdin or write to stdout. This enables chaining multiple CDO commands without intermediate files:
```bash
cdo monmean -selyear,2000/2010 input.nc - | cdo yearmean - output.nc
```
This is useful because it avoids writing temporary files to disk, saving I/O and disk space.

### 6. Purpose of `--no_metadata`:
The `--no_metadata` option suppresses the output of metadata in ASCII output commands like `outputtab`, `outputts`, etc. It produces cleaner, machine-readable tables without header lines.

---

## Bonus Challenge

### Command:
```bash
cdo yearmean -fldmean -selyear,2000/2005 ../datasets/tas_sample.nc output.nc
```

### Explanation (right to left):
1. `-selyear,2000/2005` selects time steps from years 2000 to 2005
2. `-fldmean` computes the spatial (field) mean at each time step → global mean time series
3. `cdo yearmean` computes the annual mean of the global mean time series
4. Result: one value per year (2000–2005) of global mean temperature
