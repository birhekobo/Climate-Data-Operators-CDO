# Quiz 2: File Operations

**Instructions:** Choose the best answer for each question.

---

**1. Which operator merges multiple files along the time dimension?**
- A) `merge`
- B) `mergetime`
- C) `cat`
- D) `join`

**2. What is the difference between `mergetime` and `merge`?**
- A) They are identical in function
- B) `mergetime` concatenates time steps; `merge` combines different variables
- C) `merge` concatenates time steps; `mergetime` combines different variables
- D) `mergetime` works only for GRIB files

**3. Which operator splits a file into individual years?**
- A) `splityear`
- B) `yearsplit`
- C) `split`
- D) `divyear`

**4. How many files does `cdo splitmon input.nc output_` produce from 10 years of monthly data?**
- A) 10
- B) 12
- C) 120
- D) 1

**5. Which operator selects only specific variables by name?**
- A) `selcode`
- B) `selname`
- C) `select`
- D) `pick`

**6. Which operator renames a variable?**
- A) `rename`
- B) `chname`
- C) `setname`
- D) `mv`

**7. What compression levels are available with `-z zip` in CDO?**
- A) 0–3
- B) 1–9
- C) 0–100
- D) Only on/off (0 or 1)

**8. When you compress a NetCDF file with deflate, is the compression lossless or lossy?**
- A) Lossless — decompression returns identical data
- B) Lossy — some precision is sacrificed
- C) Depends on the deflate level
- D) CDO does not support compression

**9. Which operator would you use to select only January months from a multi-year dataset?**
- A) `selmon,1`
- B) `selyear,1`
- C) `janselect`
- D) `seldate,01`

**10. What does `cdo copy input.nc output.nc` do?**
- A) Copies the file with potential format/compression changes
- B) Performs a bit-identical copy only
- C) Compresses the file by default
- D) Deletes the input file

---

## Answer Key

| Q | Answer |
|---|--------|
| 1 | B |
| 2 | B |
| 3 | A |
| 4 | B |
| 5 | B |
| 6 | B |
| 7 | B |
| 8 | A |
| 9 | A |
|10 | A |
