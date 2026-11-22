# Exercise 2: File Operations

## Objectives
- Merge multiple NetCDF files
- Split a file by time periods
- Select and drop variables
- Rename variables
- Compress NetCDF files at different levels

## Prerequisites
- CDO installed
- Multiple single-year files: `tas_2000.nc` through `tas_2005.nc`
- One multi-year file: `tas_sample.nc`
- All in the `datasets/` directory

---

## Task 1: Merge Multiple Files

### Instructions
1. Use `cdo mergetime` to merge `tas_2000.nc` through `tas_2005.nc` into a single file.

```bash
cdo mergetime ../datasets/tas_2000.nc ../datasets/tas_2001.nc ... merged.nc
```

2. Verify the merged file with `cdo sinfo`.

### Questions
1. How many time steps does the merged file contain?
2. What is the time range of the merged file?
3. What is the difference between `mergetime` and `merge`? When would you use each?
4. Try using `cdo copy` on input first – does it change the file size? Why?

---

## Task 2: Split a File by Year and Month

### Instructions
1. Split `tas_sample.nc` into individual years:
   ```bash
   cdo splityear ../datasets/tas_sample.nc tas_year_
   ```
2. Split `tas_sample.nc` into individual months:
   ```bash
   cdo splitmon ../datasets/tas_sample.nc tas_mon_
   ```
3. Split `tas_sample.nc` into individual timesteps:
   ```bash
   cdo splitsel,1 ../datasets/tas_sample.nc tas_step_
   ```

### Questions
1. How many files does `splityear` produce? Why?
2. How many files does `splitmon` produce? Why?
3. What naming pattern does each split operator use?
4. Can you split by season? Which operator would you use?

---

## Task 3: Select and Drop Variables

### Instructions
1. Use `cdo selname` to select only the `tas` variable from a file.
2. Use `cdo delname` to drop a variable.

```bash
cdo selname,tas ../datasets/tas_sample.nc tas_only.nc
cdo delname,tas ../datasets/tas_sample.nc without_tas.nc
```

### Questions
1. What happens if you try to drop the only variable in a file?
2. How would you select multiple variables at once?
3. What is the difference between `selname` and `selcode`?

---

## Task 4: Rename Variables

### Instructions
1. Rename the variable `tas` to `temperature`:
   ```bash
   cdo chname,tas,temperature ../datasets/tas_sample.nc renamed.nc
   ```
2. Verify with `cdo sinfo` and `ncdump -h`.

### Questions
1. Does renaming change the underlying data values?
2. Does it preserve all metadata attributes?
3. How would you rename multiple variables in one command?

---

## Task 5: Compress at Different Levels

### Instructions
1. Compress the file with different deflate levels (1–9):
   ```bash
   cdo -z zip_1 copy ../datasets/tas_sample.nc tas_zip1.nc
   cdo -z zip_5 copy ../datasets/tas_sample.nc tas_zip5.nc
   cdo -z zip_9 copy ../datasets/tas_sample.nc tas_zip9.nc
   ```
2. Compare file sizes:
   ```bash
   ls -lh tas_zip*.nc ../datasets/tas_sample.nc
   ```
3. Try `-z szip` if supported by your build.

### Questions
1. What is the size reduction at each compression level?
2. Is the compression lossless or lossy?
3. What is the trade-off of using maximum compression (level 9)?
4. What other compression methods does CDO support (check `cdo --help`)?

---

## Bonus Challenge

Write a one-liner that:
1. Selects years 2000–2005 from `tas_sample.nc`
2. Renames `tas` to `temperature`
3. Compresses with deflate level 6
4. Outputs to `final_output.nc`

---

## Deliverables
- Merged, split, selected, renamed, and compressed files
- Written answers to all questions
- The one-liner bonus command
