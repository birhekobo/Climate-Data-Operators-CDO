# Exercise 1: CDO Basics

## Objectives
- Install and verify CDO
- Learn fundamental CDO operators
- Explore CDO's architecture

## Prerequisites
- A computer with Linux, macOS, or WSL on Windows
- Internet connection (for installation)
- Sample NetCDF file (`tas_sample.nc` in the `datasets/` directory)

---

## Task 1: Install and Verify CDO

### Instructions
1. Install CDO using your system package manager:
   - **Ubuntu/Debian:** `sudo apt install cdo`
   - **Fedora:** `sudo dnf install cdo`
   - **macOS (Homebrew):** `brew install cdo`
   - **conda:** `conda install -c conda-forge cdo`
2. Verify the installation by checking the version.

### Questions
1. What command shows the installed CDO version?
2. What is your installed CDO version?
3. What is the installed NetCDF library version?

---

## Task 2: Explore CDO Operators

### Instructions
Run `cdo --help` and review the operator categories. List **10 different CDO operators** with:
- The operator name
- The category it belongs to (e.g., FILE OPERATIONS, COMPARISON, etc.)
- A one-sentence description of what it does

Record them in a table like this:

| # | Operator | Category | Description |
|---|----------|----------|-------------|
| 1 | `sinfo`  | INFO     | Prints information about a dataset |
| 2 | ...      | ...      | ... |

---

## Task 3: Run `sinfo` on a Sample File

### Instructions
1. Navigate to the `datasets/` directory (or use the full path).
2. Run `cdo sinfo` on `tas_sample.nc`.
3. Save the output to a text file.

### Questions (answer from the sinfo output)
1. How many variables does the file contain? Name them.
2. What is the horizontal grid type and dimensions (number of lon/lat cells)?
3. What is the time range covered by the dataset?
4. How many time steps are there?
5. What is the calendar type used?
6. What is the data type of the variable (e.g., F32, F64)?

---

## Task 4: CDO Architecture Questions

Answer the following questions by reading the CDO documentation (`cdo -h` or online at https://code.mpimet.mpg.de/projects/cdo):

1. **What does CDO stand for and what is its main purpose?**
2. **How does CDO handle memory for large datasets?**
   - Hint: look for the `-buffersize` option or documentation about chunking.
3. **What file formats can CDO read and write?** (List at least 5.)
4. **What is the difference between an *operator* and a *modifier* in CDO?**
5. **Explain what the pipe (`-`) means in CDO command syntax. Why is it useful?**
6. **What is the purpose of the `--no_metadata` option?**

---

## Bonus Challenge

Run the following command and explain what each part does:

```bash
cdo yearmean -fldmean -selyear,2000/2005 ../datasets/tas_sample.nc output.nc
```

Write your explanation in a few sentences.

---

## Deliverables
- A text file `sinfo_output.txt` with the output from `cdo sinfo`
- Written answers to all questions
- Table of 10 CDO operators
