---
title: "Module 3: Linux Basics for Climate Data Processing"
subject: Climate Data Operators Training
subtitle: "Essential Command-Line Skills"
---

# Module 3: Linux Basics for Climate Data Processing

## Learning Objectives

By the end of this module, you will be able to:

- Navigate the Linux filesystem using command-line tools
- Manage files and directories efficiently
- Write bash scripts with variables, loops, and conditionals
- Use pipes and redirections to chain commands
- Set and manage environment variables for CDO
- Use wildcards and globbing patterns for batch processing
- Process text with grep, sed, and awk
- Build complete CDO processing pipelines in bash

---

## Linux Command Line Fundamentals

CDO is a command-line tool, so familiarity with the Linux terminal is essential.

```{note}
This module assumes you have access to a Linux terminal or WSL on Windows.
```

### The Shell

The **shell** is a program that interprets commands. The most common shell is **bash** (Bourne Again SHell).

```bash
# Check which shell you are using
echo $SHELL

# Check your shell version
bash --version
```

### Command Structure

Most Linux commands follow this pattern:

```bash
command [options] [arguments]
```

Examples:

```bash
ls -la /home/user/
# command: ls (list directory)
# options: -l (long format), -a (all files)
# argument: /home/user/ (directory to list)
```

## File Management

### Navigation Commands

```bash
# Print working directory
pwd

# List files
ls                    # basic listing
ls -l                 # long format (permissions, size, date)
ls -la                # long format including hidden files
ls -lh                # human-readable sizes
ls -lt                # sorted by modification time
ls -lS                # sorted by file size
ls -R                 # recursive listing

# Change directory
cd /path/to/dir       # go to absolute path
cd ..                 # go up one level
cd ~                  # go to home directory
cd -                  # go to previous directory

# View directory tree
tree /path            # show directory tree structure
tree -L 2             # limit to 2 levels deep
```

```{tip}
Use `ls -lh` for readable file sizes, and `ls -lt` to see the most recently modified files.
```

### File Operations

```bash
# Create directories
mkdir data
mkdir -p data/raw/2024    # create parent directories as needed

# Create empty files
touch file.txt

# Copy files
cp source.nc dest.nc
cp -r source_dir dest_dir    # recursive copy for directories

# Move/Rename files
mv oldname.nc newname.nc
mv file.nc /path/to/target/

# Remove files (use with caution!)
rm file.nc
rm -rf directory_name       # remove directory and contents
rm -i *.nc                  # interactive mode (ask before each)

# View file contents
cat file.txt                # display entire file
less file.txt               # view with pagination (q to quit)
head -20 file.txt           # first 20 lines
tail -10 file.txt           # last 10 lines
```

```{warning}
The `rm -rf` command is dangerous. Always double-check the path before executing. There is no trash bin in the terminal.
```

### Working with Climate Data Files

```bash
# Check file size
ls -lh data.nc
du -h data.nc               # disk usage

# Check file type
file data.nc

# Count files matching pattern
ls *.nc | wc -l

# Find files
find . -name "*.nc"         # find all NetCDF files recursively
find . -size +1G            # files larger than 1 GB
find . -mtime -7            # files modified in last 7 days
```

## Shell Scripting Basics

### Creating Your First Script

A bash script is a text file containing shell commands.

```bash
#!/bin/bash
# My first CDO script

echo "Starting climate data processing..."

# Create output directory
mkdir -p output

# List input files
echo "Input files:"
ls -lh *.nc

echo "Done!"
```

```{note}
The first line (`#!/bin/bash`) is called a **shebang**. It tells the system which interpreter to use.
```

### Making Scripts Executable

```bash
chmod +x myscript.sh

# Run the script
./myscript.sh
# OR
bash myscript.sh
```

## Variables in Bash

### Defining and Using Variables

```bash
# Variable assignment (no spaces around =)
input_file="era5_data.nc"
output_file="processed_data.nc"

# Using variables (prefix with $)
echo "Processing $input_file"
cdo timmean $input_file $output_file

# Command substitution (store command output)
num_files=$(ls *.nc | wc -l)
echo "Found $num_files NetCDF files"

# Current date
today=$(date +%Y%m%d)
echo "Today's date: $today"
```

### Special Variables

```bash
# Script name
echo "Script name: $0"

# First argument
echo "First argument: $1"

# Second argument
echo "Second argument: $2"

# All arguments
echo "All arguments: $@"

# Number of arguments
echo "Number of arguments: $#"

# Exit status of last command
echo "Exit code: $?"

# Process ID of current shell
echo "PID: $$"
```

### Variable Scope and Export

```bash
# Local variable
my_var="hello"

# Export to subshell (environment variable)
export PATH="/custom/path:$PATH"

# Array variables
files=(*.nc)
echo "First file: ${files[0]}"
echo "All files: ${files[@]}"
echo "Number of files: ${#files[@]}"
```

## Loops

### For Loops

```bash
# Loop over a list
for file in *.nc; do
    echo "Processing $file"
    cdo timmean "$file" "${file%.nc}_mean.nc"
done

# Loop with a sequence
for year in $(seq 2000 2020); do
    echo "Year: $year"
done

# C-style for loop
for ((i=0; i<10; i++)); do
    echo "Iteration $i"
done
```

### While Loops

```bash
# Read a file line by line
while read -r line; do
    echo "Processing: $line"
    cdo sinfo "$line" >> metadata.txt
done < filelist.txt

# Counter-based loop
counter=0
while [ $counter -lt 10 ]; do
    echo "Count: $counter"
    ((counter++))
done
```

### Practical Example: Batch Processing

````{exercise}
:label: ex-basics-1
Create a script to process multiple years of data:

```bash
#!/bin/bash
# Batch process climate data by year

for year in $(seq 2010 2020); do
    infile="era5_t2m_${year}.nc"
    outfile="era5_t2m_${year}_annual_mean.nc"
    
    if [ -f "$infile" ]; then
        echo "Processing $year..."
        cdo timmean "$infile" "$outfile"
    else
        echo "WARNING: $infile not found!"
    fi
done

echo "Batch processing complete."
```
````

## Conditional Statements

### If-Else Statements

```bash
# Check if file exists
if [ -f "$filename" ]; then
    echo "Processing $filename"
    cdo sinfo "$filename"
elif [ -d "$dirname" ]; then
    echo "$dirname is a directory"
else
    echo "File not found"
fi
```

### Common Test Conditions

```bash
# File tests
[ -f file ]    # file exists and is a regular file
[ -d dir ]     # directory exists
[ -e path ]    # path exists
[ -s file ]    # file exists and is not empty
[ -r file ]    # file is readable
[ -w file ]    # file is writable
[ -x file ]    # file is executable

# String tests
[ "$a" = "$b" ]  # strings are equal
[ "$a" != "$b" ] # strings are not equal
[ -z "$a" ]      # string is empty
[ -n "$a" ]      # string is not empty

# Numeric tests
[ "$a" -eq "$b" ] # equal
[ "$a" -ne "$b" ] # not equal
[ "$a" -gt "$b" ] # greater than
[ "$a" -lt "$b" ] # less than
[ "$a" -ge "$b" ] # greater than or equal
[ "$a" -le "$b" ] # less than or equal
```

### Logical Operators

```bash
# AND
if [ -f "$file1" ] && [ -f "$file2" ]; then
    echo "Both files exist"
fi

# OR
if [ -f "$file1" ] || [ -f "$file2" ]; then
    echo "At least one file exists"
fi

# Using double brackets (bash-specific)
if [[ "$var1" == "value" && "$var2" > "2020" ]]; then
    echo "Conditions met"
fi
```

### Case Statements

```bash
case "$var" in
    start)
        echo "Starting..."
        ;;
    stop)
        echo "Stopping..."
        ;;
    restart)
        echo "Restarting..."
        ;;
    *)
        echo "Unknown command: $var"
        exit 1
        ;;
esac
```

## Pipes and Redirections

### Standard Streams

| Stream | Name | Number | Default Target |
|--------|------|--------|----------------|
| stdin | Standard Input | 0 | Keyboard |
| stdout | Standard Output | 1 | Terminal |
| stderr | Standard Error | 2 | Terminal |

### Redirections

```bash
# Redirect output to file (overwrite)
cdo sinfo input.nc > info.txt

# Redirect output to file (append)
cdo sinfo input.nc >> all_info.txt

# Redirect errors to file
cdo timmean input.nc output.nc 2> errors.log

# Redirect both stdout and stderr
cdo timmean input.nc output.nc &> all_output.log

# Redirect stderr to stdout
cdo timmean input.nc output.nc 2>&1

# Suppress output (discard)
cdo timmean input.nc output.nc > /dev/null 2>&1

# Take input from file
while read -r file; do
    cdo sinfo "$file"
done < filelist.txt

# Here document
cat << EOF > myscript.sh
#!/bin/bash
echo "Generated script"
EOF
```

### Pipes

Pipes connect the stdout of one command to the stdin of another.

```bash
# Chain commands
ls -lh *.nc | grep "Jan " | wc -l

# CDO pipeline without intermediate files
cdo timmean -seldate,2020-01-01,2020-12-31 input.nc \
    | cdo fldmean - \
    | cdo output -

# Check file sizes
ls -lh *.nc | awk '{print $5, $9}'

# Count variables in NetCDF file
cdo vardes input.nc | wc -l
```

```{important}
Pipes avoid creating intermediate files, saving disk space and I/O time for large datasets.
```

### Practical CDO Pipelines

```bash
# Pipeline: select, average, and output
cdo output \
    -fldmean \
    -timmean \
    -selname,t2m \
    input.nc

# Using intermediate files (same result, but uses disk)
cdo selname,t2m input.nc step1.nc
cdo timmean step1.nc step2.nc
cdo fldmean step2.nc result.nc
rm step1.nc step2.nc

# The pipeline version is cleaner and more efficient
```

```{tip}
Use pipes (`|`) and the `-` placeholder for output to chain CDO operations without temporary files.
```

## Environment Variables

### Viewing and Setting

```bash
# View all environment variables
env
printenv

# View specific variable
echo $HOME
echo $PATH
echo $SHELL

# Set environment variable (session only)
export MY_VAR="value"

# Set for a single command
CDO_NTHREADS=8 cdo timmean input.nc output.nc
```

### CDO-Specific Environment Variables

```bash
# Set threads for parallel processing
export CDO_NTHREADS=4

# Set temporary directory
export CDO_TEMPDIR=/scratch/tmp
mkdir -p $CDO_TEMPDIR

# Verbose mode
export CDO_VERBOSE=1

# Memory limit (GB)
export CDO_MEMORY=8

# Make settings permanent
echo 'export CDO_NTHREADS=4' >> ~/.bashrc
echo 'export CDO_TEMPDIR=/tmp/cdo' >> ~/.bashrc
```

### PATH Management

```bash
# View your PATH
echo $PATH

# Add directory to PATH
export PATH="/custom/installation/bin:$PATH"

# Add to bashrc for permanence
echo 'export PATH="$HOME/local/bin:$PATH"' >> ~/.bashrc
```

## Wildcards and Globbing

### Basic Wildcards

```bash
*       # Matches any number of any characters
?       # Matches exactly one character
[]      # Matches one character from a set
[!]     # Matches one character NOT in a set
```

### Examples

```bash
# Match all NetCDF files
*.nc

# Match files starting with "temp"
temp*.nc

# Match single year files
era5_202?.nc     # matches era5_2020.nc, era5_2021.nc, etc.

# Match specific months
data_2024_0{1,2,3}.nc     # matches months 01, 02, 03
data_2024_0[1-6].nc       # matches months 01 through 06

# Negation
data_2024_0[!5-9].nc      # matches months 01-04 only

# Brace expansion
echo {jan,feb,mar}_{2020,2021}.nc
# Output: jan_2020.nc jan_2021.nc feb_2020.nc feb_2021.nc mar_2020.nc mar_2021.nc
```

### Using Wildcards with CDO

```bash
# Merge all NetCDF files
cdo mergetime *.nc merged.nc

# Process only files matching pattern
for file in era5_202[0-5]_*.nc; do
    cdo timmean "$file" "mean_$file"
done

# Count files
echo "Processing $(ls *.nc | wc -l) files"
```

```{warning}
When using wildcards, be careful about the maximum number of arguments. For thousands of files, use loops or `find` instead.
```

## Text Processing

### grep - Pattern Search

```bash
# Search for text in files
grep "temperature" metadata.txt

# Recursive search
grep -r "t2m" /data/

# Case-insensitive search
grep -i "temperature" file.txt

# Show line numbers
grep -n "error" log.txt

# Show context
grep -B 5 -A 5 "error" log.txt   # 5 lines before and after

# Invert match
grep -v "comment" file.txt

# Count matches
grep -c "variable" metadata.txt

# Use with pipes
cdo sinfo data.nc | grep -i "temperature"
```

```{tip}
grep is invaluable for searching through CDO output and log files.
```

### sed - Stream Editor

```bash
# Replace text
sed 's/old/new/g' file.txt

# Replace in place
sed -i 's/old/new/g' file.txt

# Delete lines matching pattern
sed '/pattern/d' file.txt

# Print specific lines
sed -n '10,20p' file.txt

# CDO-specific: clean up output
cdo griddes input.nc | sed 's/  */ /g'   # remove extra spaces
```

### awk - Text Processing

```bash
# Print specific columns
ls -lh *.nc | awk '{print $5, $9}'

# Calculate sum of file sizes
ls -l *.nc | awk '{sum += $5} END {print "Total size:", sum, "bytes"}'

# Filter by condition
cdo sinfo data.nc | awk '/^[0-9]+:/ {print $2, $4}'

# Format output
cdo output -fldmean -timmean data.nc | awk '{printf "%.4f\n", $1}'

# Conditional processing
cdo output data.nc | awk '{if ($1 > 300) print $0}'
```

### Combining Text Tools

```bash
# Find all variable names in a NetCDF file
cdo vardes data.nc | grep -v "^#" | awk '{print $1}' | sort -u

# List all unique grid types in a directory
for file in *.nc; do
    cdo griddes "$file" | grep "^gridtype" | awk '{print $2}'
done | sort -u

# Get time range of all files
for file in *.nc; do
    echo -n "$file: "
    cdo showdate "$file" | tr ' ' '\n' | head -1
    echo -n " to "
    cdo showdate "$file" | tr ' ' '\n' | tail -1
done
```

## Writing Your First CDO Pipeline with Bash

### Complete Processing Pipeline

```bash
#!/bin/bash
# Comprehensive CDO pipeline for ERA5 data processing
# Usage: ./process_era5.sh <input_dir> <output_dir> <year>

set -e  # Exit on error
set -u  # Exit on undefined variable

# Configuration
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
INPUT_DIR="${1:-./data}"
OUTPUT_DIR="${2:-./output}"
YEAR="${3:-2020}"

# CDO settings
export CDO_NTHREADS=$(nproc)
export CDO_VERBOSE=0

mkdir -p "$OUTPUT_DIR"

echo "==================================="
echo "ERA5 Processing Pipeline - $YEAR"
echo "==================================="
echo "Input:  $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo "Threads: $CDO_NTHREADS"
echo "==================================="

# Step 1: Extract variables
extract_var() {
    local var=$1
    local infile="$INPUT_DIR/era5_${YEAR}_full.nc"
    local outfile="$OUTPUT_DIR/${var}_${YEAR}.nc"
    
    if [ ! -f "$infile" ]; then
        echo "ERROR: Input file not found: $infile"
        return 1
    fi
    
    echo "Extracting $var..."
    cdo selname,"$var" "$infile" "$outfile"
}

# Step 2: Compute annual mean
annual_mean() {
    local var=$1
    local infile="$OUTPUT_DIR/${var}_${YEAR}.nc"
    local outfile="$OUTPUT_DIR/${var}_${YEAR}_annual.nc"
    
    echo "Computing annual mean for $var..."
    cdo timmean "$infile" "$outfile"
}

# Step 3: Compute spatial mean
spatial_mean() {
    local var=$1
    local infile="$OUTPUT_DIR/${var}_${YEAR}_annual.nc"
    local outfile="$OUTPUT_DIR/${var}_${YEAR}_global_mean.txt"
    
    echo "Computing global mean for $var..."
    cdo output -fldmean "$infile" > "$outfile"
}

# Main processing
VARIABLES=("t2m" "tp" "msl" "u10" "v10")

for var in "${VARIABLES[@]}"; do
    echo "--------------------------------"
    echo "Processing variable: $var"
    echo "--------------------------------"
    
    extract_var "$var" || continue
    annual_mean "$var" || continue
    spatial_mean "$var" || continue
done

# Step 4: Generate summary report
SUMMARY="$OUTPUT_DIR/summary_${YEAR}.txt"
echo "Generation summary report..."

echo "ERA5 Processing Summary - $YEAR" > "$SUMMARY"
echo "=================================" >> "$SUMMARY"
echo "" >> "$SUMMARY"

for var in "${VARIABLES[@]}"; do
    result_file="$OUTPUT_DIR/${var}_${YEAR}_global_mean.txt"
    if [ -f "$result_file" ]; then
        value=$(cat "$result_file")
        echo "$var global mean: $value" >> "$SUMMARY"
    fi
done

echo "--------------------------------"
echo "Pipeline complete!"
echo "Results saved in: $OUTPUT_DIR"
echo "Summary: $SUMMARY"
echo "================================="
```

```{tip}
This pipeline script can be adapted for any climate variable or year. Save it as `process_era5.sh` and reuse it.
```

## Hands-On Exercises

### Exercise 1: File Management

````{exercise}
:label: ex-basics-2
Create a directory structure for a climate data project:

```bash
mkdir -p ~/climate_project/{data,scripts,output,figures,logs}
mkdir -p ~/climate_project/data/{raw,processed}
mkdir -p ~/climate_project/data/raw/{era5,cmip6,gfs}
```

Then:
1. Navigate to each directory using `cd`
2. Create a `readme.txt` file in `climate_project/` with a description of the project
3. List the full tree structure with `tree ~/climate_project`
4. Check disk usage with `du -sh ~/climate_project`
````

### Exercise 2: Script with Variables

```{exercise}
:label: ex-basics-3
Write a bash script called `process_variable.sh` that:

1. Takes a variable name as the first argument
2. Takes an input file as the second argument
3. Computes the timestep count, global mean, and standard deviation
4. Prints a formatted report
5. Saves the results to a timestamped output file

Example usage: `bash process_variable.sh t2m era5_data.nc`
```

### Exercise 3: Batch Processing Loop

````{exercise}
:label: ex-basics-4
Create a script that processes all NetCDF files in a directory:

```bash
#!/bin/bash
# Batch processing script

OUTPUT_DIR="./processed"
mkdir -p "$OUTPUT_DIR"

for infile in ./data/*.nc; do
    filename=$(basename "$infile")
    basename="${filename%.nc}"
    
    echo "Processing: $filename"
    cdo timmean "$infile" "$OUTPUT_DIR/${basename}_mean.nc"
    cdo fldmean "$OUTPUT_DIR/${basename}_mean.nc" "$OUTPUT_DIR/${basename}_global.txt"
done

echo "All files processed."
```

Test it by creating dummy NC files:
```bash
for i in {1..5}; do
    cdo -f nc -random,10,5,3 "data/test_${i}.nc"
done
```
````

### Exercise 4: Pipeline with Conditionals

```{exercise}
:label: ex-basics-5
Write a script that:

1. Checks if an output directory exists; if not, creates it
2. For each NetCDF file in the input directory:
   - Checks if it's larger than 100 MB
   - If yes, compresses it with `-z zip_5` and saves to output
   - If no, copies it directly
3. Generates a log file with processing details

Use conditionals (`if`, `test`) and arithmetic comparisons.
```

### Exercise 5: Text Processing Pipeline

````{exercise}
:label: ex-basics-6
Use pipes and text processing tools to create a data inventory:

```bash
# For all NC files in a directory, extract:
# - File name
# - Number of timesteps
# - Number of variables
# - Grid description

for file in *.nc; do
    ntime=$(cdo ntime "$file" 2>/dev/null || echo "N/A")
    nvar=$(cdo vardes "$file" 2>/dev/null | grep -c "^[0-9]" || echo "N/A")
    grid=$(cdo griddes "$file" 2>/dev/null | grep "^gridtype" | awk '{print $2}' || echo "N/A")
    
    echo "$file | $ntime timesteps | $nvar variables | $grid grid"
done | column -t -s '|' > inventory.txt

cat inventory.txt
```
````

## Quiz

```{admonition} Quiz
:class: tip
Test your understanding of Linux basics for climate data processing.
```

```{exercise} Question 1: What does the `ls -lh` command do?
:label: q-basics-1

A. Lists files in long format with human-readable sizes  
B. Lists only hidden files  
C. Lists files sorted by name  
D. Lists files recursively  

```

```{solution} q-basics-1
A. Lists files in long format with human-readable sizes
```

```{exercise} Question 2: Which symbol is used to connect the stdout of one command to the stdin of another?
:label: q-basics-2

A. `>`  
B. `>>`  
C. `|`  
D. `&`  

```

```{solution} q-basics-2
C. `|` (pipe)
```

```{exercise} Question 3: In bash, what does `$1` represent inside a script?
:label: q-basics-3

A. The script name  
B. The first command-line argument  
C. The process ID  
D. The exit status of the last command  

```

```{solution} q-basics-3
B. The first command-line argument
```

```{exercise} Question 4: Which wildcard matches exactly one character?
:label: q-basics-4

A. `*`  
B. `?`  
C. `[]`  
D. `{}`  

```

```{solution} q-basics-4
B. `?`
```

```{exercise} Question 5: What is the purpose of the `export` command in bash?
:label: q-basics-5

A. To save a file  
B. To make a variable available to child processes  
C. To display environment variables  
D. To remove a variable  

```

```{solution} q-basics-5
B. To make a variable available to child processes
```

## Summary

In this module, we covered:

- **File management**: `ls`, `cd`, `pwd`, `mkdir`, `cp`, `mv`, `rm`
- **Shell scripting**: shebang, variables, script arguments, exit codes
- **Loops**: `for` loops over lists and sequences, `while` loops
- **Conditionals**: `if-elif-else`, test conditions (`-f`, `-d`, `-eq`, etc.)
- **Pipes and redirections**: `|`, `>`, `>>`, `<`, `2>&1`
- **Environment variables**: `PATH`, `CDO_NTHREADS`, `CDO_TEMPDIR`
- **Wildcards**: `*`, `?`, `[]`, `{}` for batch file matching
- **Text processing**: `grep` (pattern search), `sed` (stream editing), `awk` (column processing)
- **CDO pipelines**: Chaining operators without intermediate files

```{admonition} Key Points
:class: note
- Master the Linux command line before diving deep into CDO
- Pipes and redirections are essential for efficient CDO pipelines
- Loops and conditionals automate repetitive climate data tasks
- Text processing tools help analyze CDO output metadata
- Always verify file existence before processing in scripts
```

## References

- GNU Bash Manual: https://www.gnu.org/software/bash/manual/
- Linux Command Line Basics: https://linuxcommand.org/
- Advanced Bash Scripting Guide: https://tldp.org/LDP/abs/html/
- grep Manual: https://www.gnu.org/software/grep/manual/
- sed Manual: https://www.gnu.org/software/sed/manual/
- awk Manual: https://www.gnu.org/software/gawk/manual/
