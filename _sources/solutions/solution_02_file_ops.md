# Solution 2: File Operations

## Task 1: Merge Multiple Files

### Command:
```bash
cdo mergetime ../datasets/tas_2000.nc ../datasets/tas_2001.nc ../datasets/tas_2002.nc \
              ../datasets/tas_2003.nc ../datasets/tas_2004.nc ../datasets/tas_2005.nc \
              merged.nc
```

Or with a wildcard:
```bash
cdo mergetime ../datasets/tas_2???.nc merged.nc
```

### Answers:
1. **Number of time steps:** 72 (6 years × 12 months)
2. **Time range:** 2000-01-01 to 2005-12-01
3. **Difference between `mergetime` and `merge`:**
   - `mergetime` concatenates files along the time dimension (assumes same variables/grid)
   - `merge` combines files with **different variables** (joins along the variable/field dimension)
   - Use `mergetime` for time-slices, `merge` for different variables on the same time axis
4. **Does `cdo copy` change file size?** Generally no (unless used with compression flags like `-z zip`). `copy` just copies the data with the same encoding.

---

## Task 2: Split a File by Year and Month

### Commands:
```bash
cdo splityear ../datasets/tas_sample.nc tas_year_
cdo splitmon ../datasets/tas_sample.nc tas_mon_
cdo splitsel,1 ../datasets/tas_sample.nc tas_step_
```

### Answers:
1. **splityear produces:** 31 files (one per year, 1980–2010). Each contains 12 monthly time steps.
2. **splitmon produces:** 12 files (one per month). Each contains 31 time steps (one for each year).
3. **Naming patterns:**
   - `splityear`: `tas_year_1980.nc`, `tas_year_1981.nc`, ...
   - `splitmon`: `tas_mon_01.nc`, `tas_mon_02.nc`, ... (01 = January)
   - `splitsel`: `tas_step_001.nc`, `tas_step_002.nc`, ...
4. **Split by season:** Use `splitseas`. Produces 4 files per year (DJF, MAM, JJA, SON).

---

## Task 3: Select and Drop Variables

### Commands:
```bash
cdo selname,tas ../datasets/tas_sample.nc tas_only.nc
cdo delname,tas ../datasets/tas_sample.nc without_tas.nc
```

### Answers:
1. **Drop the only variable:** CDO will produce an error — the output file would be empty (no variables).
2. **Select multiple variables:** `cdo selname,tas,pr,psl input.nc output.nc`
3. **`selname` vs `selcode`:**
   - `selname` selects by variable name (e.g., `tas`, `pr`)
   - `selcode` selects by GRIB code number (e.g., 167 = 2m temperature, 172 = precipitation)

---

## Task 4: Rename Variables

### Command:
```bash
cdo chname,tas,temperature ../datasets/tas_sample.nc renamed.nc
```

### Answers:
1. **Does renaming change data values?** No — it only modifies the variable name in the metadata.
2. **Does it preserve all metadata attributes?** Yes — all attributes (units, long_name, etc.) are preserved. Only the variable name string is changed.
3. **Rename multiple variables:** `cdo chname,tas,temp,pr,precip input.nc output.nc`

---

## Task 5: Compress at Different Levels

### Commands:
```bash
cdo -z zip_1 copy ../datasets/tas_sample.nc tas_zip1.nc
cdo -z zip_5 copy ../datasets/tas_sample.nc tas_zip5.nc
cdo -z zip_9 copy ../datasets/tas_sample.nc tas_zip9.nc
```

### Typical size comparison (sample file ~50 MB uncompressed):
| Level | File Size | Ratio |
|-------|-----------|-------|
| none  | 50 MB     | 1.00  |
| zip_1 | 18 MB     | 0.36  |
| zip_5 | 15 MB     | 0.30  |
| zip_9 | 14 MB     | 0.28  |

### Answers:
1. **Size reduction:** Level 1 gives significant reduction; levels 5–9 give diminishing returns.
2. **Compression is lossless** — decompressed data is bit-identical to the original.
3. **Trade-off of level 9:** Slightly better compression but significantly slower read/write times. Level 4–6 is usually recommended for the best balance.
4. **Other compression methods:** CDO supports `szip` (SZIP), `grib` (GRIB packing), and `shap` (bit-shaving). Check with `cdo --help | grep -i compress`.

---

## Bonus Challenge

### One-liner:
```bash
cdo -z zip_6 -chname,tas,temperature -selyear,2000/2005 ../datasets/tas_sample.nc final_output.nc
```
