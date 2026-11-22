---
title: "References and Further Resources"
subject: Climate Data Operators (CDO) Training
subtitle: Comprehensive Reference for Climate Data Analysis
---

# References and Further Resources

## Learning Objectives

After reviewing this reference module, you will be able to:

- Locate official CDO documentation and operator references
- Identify appropriate climate data sources for your research
- Understand NetCDF and GRIB data conventions
- Access key software tools for climate data analysis
- Troubleshoot common CDO issues
- Follow best practices for climate data processing

## A. Official CDO Documentation

### A.1 Primary CDO Resources

| Resource | URL / Location | Description |
|----------|----------------|-------------|
| CDO Homepage | https://code.mpimet.mpg.de/projects/cdo | Project page, downloads, documentation |
| CDO User Guide | https://code.mpimet.mpg.de/projects/cdo/embedded/index.html | Complete reference manual |
| CDO Git Repository | https://github.com/MPI-MagDE/cdo | Source code and issue tracker |
| CDO Mailing List | https://code.mpimet.mpg.de/projects/cdo/lists | User support and announcements |

### A.2 CDO Operator Categories

The complete CDO operator reference is organized into these categories:

| Category | Description | Example Operators |
|----------|-------------|-------------------|
| File Operations | File manipulation, metadata | `copy`, `info`, `show`, `nmlist` |
| Selection | Selecting data subsets | `selname`, `seldate`, `sellonlatbox` |
| Comparison | Binary and relational | `eq`, `ne`, `gt`, `lt`, `ge`, `le` |
| Arithmetic | Mathematical operations | `add`, `sub`, `mul`, `div`, `sqrt` |
| Statistics | Statistical operators | `mean`, `std`, `timpctl`, `histcount` |
| Temporal | Time dimension operations | `daymean`, `monmean`, `ymonsub` |
| Spatial | Grid and space operations | `remapbil`, `griddes`, `fldmean` |
| Ensemble | Multi-file statistics | `ensmean`, `ensstd`, `enspctl` |
| Vertical | Level operations | `vertmean`, `vertint`, `mlev` |
| Climate Indices | Dedicated index operators | `eca_fd`, `eca_cdd`, `eca_r10mm` |

## B. NetCDF Documentation and CF Conventions

### B.1 NetCDF Resources

- **NetCDF Official Site**: https://www.unidata.ucar.edu/software/netcdf/
- **NetCDF User Guide**: https://docs.unidata.ucar.edu/netcdf-c/current/
- **NetCDF Operators (NCO)**: http://nco.sourceforge.net/
- **NCO User Guide**: https://nco.readthedocs.io/en/latest/

### B.2 CF Conventions

The Climate and Forecast (CF) conventions are the standard for climate and forecast data stored in NetCDF format.

- **CF Conventions Homepage**: https://cfconventions.org/
- **CF Metadata Conventions (PDF)**: https://cfconventions.org/Data/cf-conventions/cf-conventions-1.11/cf-conventions.html
- **Standard Variable Names**: https://cfconventions.org/Data/cf-standard-names/current/build/cf-standard-name-table.html

```{note}
Always verify that your NetCDF files follow CF conventions. CDO and most climate analysis tools rely on CF-compliant metadata for correct operation.
```

### B.3 Key CF Concepts

- **Coordinate variables**: Latitude (`lat`), longitude (`lon`), time (`time`), vertical (`lev`/`plev`)
- **Standard names**: Standardized variable names like `air_temperature`, `precipitation_amount`
- **Units**: CF-compliant units (K for temperature, kg m-2 s-1 for precipitation rate, etc.)
- **Bounds**: Cell boundaries for grid cells and time intervals
- **Cell methods**: Description of how data was processed (e.g., `time: mean`)

```bash
# Check CF compliance of a file
cdo nmlist temperature.nc | findstr "standard_name"
cdo nmlist temperature.nc | findstr "units"
cdo nmlist temperature.nc | findstr "cell_methods"
```

## C. GRIB Documentation and WMO Standards

### C.1 GRIB Resources

- **GRIB Specification (WMO)**: https://github.com/wmo-im/GRIB2
- **ECMWF GRIB Guide**: https://confluence.ecmwf.int/display/UDOC/GRIB+data+files
- **cfgrib (Python GRIB reader)**: https://github.com/ecmwf/cfgrib

### C.2 Working with GRIB in CDO

```bash
# Get GRIB information
cdo sinfo grib_file.grib

# Convert GRIB to NetCDF
cdo -f nc copy grib_file.grib netcdf_file.nc

# Select GRIB parameters by shortName
cdo selname,t grib_file.grib temperature.grib

# Select by GRIB level
cdo sellev,500 pressure_level.grib
```

```{warning}
GRIB files can contain multiple parameters, levels, and time steps in a single file. Always use `cdo sinfo` to understand the file structure before processing.
```

### C.3 Key GRIB Concepts

- **GRIB Edition**: GRIB1 (older, limited), GRIB2 (current standard)
- **Parameter**: Variable identified by parameter number (e.g., 130 = temperature in GRIB1)
- **Level type**: Pressure level, surface, height above ground, etc.
- **Data representation**: Grid type (regular lat-lon, Gaussian, reduced Gaussian)
- **Bits per value**: Precision of packed data (more bits = higher precision)

## D. Climate Data Sources

### D.1 Reanalysis Datasets

| Dataset | Provider | Resolution | Period | Access |
|---------|----------|------------|--------|--------|
| ERA5 | ECMWF | 0.25 degree | 1940-present | https://cds.climate.copernicus.eu |
| ERA-Interim | ECMWF | 0.75 degree | 1979-2019 | https://apps.ecmwf.int/datasets |
| MERRA-2 | NASA GMAO | 0.5 x 0.625 degree | 1980-present | https://disc.gsfc.nasa.gov |
| JRA-55 | JMA | 0.5625 degree | 1958-present | https://jra.kishou.go.jp |
| NCEP/NCAR Reanalysis | NOAA | 2.5 degree | 1948-present | https://psl.noaa.gov/data/reanalysis |
| CFSR | NOAA | 0.5 degree | 1979-present | https://cfs.ncep.noaa.gov |

```{tip}
ERA5 is generally preferred for most applications due to its high resolution, long record, and comprehensive validation. It has largely replaced ERA-Interim.
```

### D.2 Gridded Observation Datasets

| Dataset | Variable | Resolution | Period | Access |
|---------|----------|------------|--------|--------|
| CRU TS | Temperature, precipitation | 0.5 degree | 1901-present | https://crudata.uea.ac.uk/cru/data/hrg |
| GPCC | Precipitation | 1.0/0.5/0.25 degree | 1891-present | https://www.dwd.de/gpcc |
| GPCP | Precipitation | 2.5/1.0 degree | 1979-present | https://psl.noaa.gov/data/gridded/gpcp |
| CHIRPS | Precipitation | 0.05 degree | 1981-present | https://www.chc.ucsb.edu/data/chirps |
| CMAP | Precipitation | 2.5 degree | 1979-present | https://psl.noaa.gov/data/gridded |
| GISTEMP | Temperature | 2 x 2 degree | 1880-present | https://data.giss.nasa.gov/gistemp |
| HadCRUT5 | Temperature | 5 degree | 1850-present | https://www.metoffice.gov.uk/hadobs |

### D.3 CMIP6 and Climate Projections

- **CMIP6 Data Archive (ESGF)**: https://esgf-node.llnl.gov/projects/esgf-llnl/
- **CDS CMIP6 Access**: https://cds.climate.copernicus.eu/cdsapp#!/dataset/projections-cmip6
- **CMIP6 Model Documentation**: https://wcrp-cmip.github.io/CMIP6_CVs/
- **CMIP6 ScenarioMIP**: https://esgf-node.llnl.gov/search/cmip6

```bash
# ESGF search and download tools
# Option 1: CDS API (Python)
# Option 2: esgf-pyclient (Python)
# Option 3: synda (command line)
```

### D.4 Regional Climate Data

| Region | Dataset | Provider | Access |
|--------|---------|----------|--------|
| Europe | E-OBS | KNMI | https://www.ecad.eu |
| Africa | ARC2 | NOAA | https://psl.noaa.gov/data/gridded/data.arc2.html |
| Africa | ENACTS | IRI | https://iri.columbia.edu/resources/enacts |
| Asia | APHRODITE | Chuo University | http://www.chikyu.ac.jp/precip |
| South America | PISCO | SENAMHI Peru | https://pisco.iri.columbia.edu |
| Global | WorldClim | UC Berkeley | https://www.worldclim.org |

## E. Books and Papers on Climate Data Analysis

### E.1 Essential Reading

- **Wilks, D.S. (2019)**: "Statistical Methods in the Atmospheric Sciences" (4th ed.), Academic Press. *The definitive reference for climate statistics.*
- **von Storch, H. & Zwiers, F.W. (1999)**: "Statistical Analysis in Climate Research", Cambridge University Press. *Comprehensive statistical methods for climate data.*
- **Hartmann, D.L. (2016)**: "Global Physical Climatology" (2nd ed.), Elsevier. *Fundamental climate science background.*

### E.2 CDO-Specific Publications

- **Schulzweida, U. (2023)**: "CDO User Guide", https://code.mpimet.mpg.de/projects/cdo/embedded/index.html
- **Schulzweida, U. (2019)**: "CDO - Climate Data Operators", https://doi.org/10.5281/zenodo.3539275

### E.3 Climate Extremes References

- **ETCCDI Indices**: https://www.wcrp-climate.org/etccdi
- **IPCC AR6 WG1 (2021)**: "Climate Change 2021: The Physical Science Basis", Cambridge University Press.
- **Sillmann, J. et al. (2013)**: "Climate extremes indices in the CMIP5 multimodel ensemble", JGR Atmospheres, 118, 1718-1732.
- **Zhang, X. et al. (2011)**: "Indices for monitoring changes in extremes based on daily temperature and precipitation data", WIREs Climate Change, 2, 851-870.

```{note}
The ETCCDI indices (described in Module 10) are the internationally accepted standard for climate extreme analysis. Always cite the relevant ETCCDI documentation when using these indices.
```

## F. Software Tools for Climate Data

### F.1 CDO Alternatives and Complements

| Tool | Description | Language | Best For |
|------|-------------|----------|----------|
| **NCO** | NetCDF Operators | C, CLI | NetCDF file manipulation, metadata editing |
| **NCL** | NCAR Command Language | NCL Script | Plotting, analysis (legacy) |
| **Ferret** | Ocean/atmosphere analysis | Ferret Script | Subsetting, regridding, visualization |
| **Panoply** | NetCDF viewer | Java GUI | Quick data inspection, basic plots |
| **Climate Data Store Toolbox** | CDS tools | Python | ERA5 data access and analysis |
| **xarray** | Labeled arrays | Python | Flexible analysis, integration with Python ecosystem |
| **Iris** | CF-compliant analysis | Python | CF-focused climate analysis |
| **cf-python** | CF data model | Python | CF conventions implementation |
| **cfgrib** | GRIB to Python | Python | Reading GRIB files in Python |
| **ecCodes** | GRIB/BUFR toolkit | C/Python | Encoding/decoding GRIB and BUFR |

### F.2 Installation Commands

```bash
# Conda environment (recommended for Python tools)
conda create -n climate python=3.11
conda activate climate
conda install -c conda-forge cdo nco xarray netcdf4 matplotlib cartopy
conda install -c conda-forge plotly pandas numpy jupyter

# CDO standalone (Windows via conda)
conda install -c conda-forge cdo

# CDO on Ubuntu/Debian
sudo apt-get install cdo

# CDO on macOS
brew install cdo
```

### F.3 Python Environment Setup

```python
# requirements.txt for climate analysis
"""
cdo
xarray>=2023.0
netCDF4
matplotlib>=3.5
cartopy>=0.20
numpy
pandas
plotly
jupyter
scipy
cfgrib
cdsapi
"""
```

## G. Glossary of Terms

| Term | Definition |
|------|------------|
| **Anomaly** | Deviation of a value from its climatological mean |
| **CF Conventions** | Climate and Forecast metadata conventions for NetCDF |
| **Climatology** | Long-term average of a climate variable (usually 30 years) |
| **CMIP** | Coupled Model Intercomparison Project |
| **Ensemble** | Collection of model runs with different initial conditions or physics |
| **ESGF** | Earth System Grid Federation - CMIP data distribution |
| **ETCCDI** | Expert Team on Climate Change Detection and Indices |
| **GRIB** | GRIdded Binary - WMO standard format for meteorological data |
| **NetCDF** | Network Common Data Form - self-describing scientific data format |
| **Reanalysis** | Gridded dataset combining observations with model forecasts via data assimilation |
| **Regridding** | Interpolating data from one grid to another |
| **Remapping** | Same as regridding (CDO terminology) |
| **SPI** | Standardized Precipitation Index |
| **Trend** | Long-term change in a variable, usually computed by linear regression |
| **Unstructured Grid** | Grid without regular spatial structure (e.g., triangular mesh) |

## H. Frequently Asked Questions (FAQ)

### H.1 General CDO Questions

**Q: CDO says "Error: Unsupported grid type" - what does this mean?**
A: Your file may use a grid type that CDO does not support for the requested operation. Try `cdo griddes` to see the grid type. For reduced Gaussian or unstructured grids, remap to a regular grid first.

**Q: How do I process very large files without running out of memory?**
A: Use the `-L` flag for large-file mode, process data in chunks by year or variable, and use piped operations to avoid intermediate files.

**Q: What is the difference between `cdo mean` and `cdo timmean`?**
A: `mean` averages over ALL dimensions. `timmean` averages only over the time dimension, preserving spatial structure.

**Q: How do I select a specific variable from a multi-variable file?**
A: Use `cdo selname,varname input.nc output.nc` or `cdo selvar,varname input.nc output.nc`.

**Q: CDO is slow on my Windows machine. What can I do?**
A: Use the `-P N` flag for parallel processing. Install via conda-forge (better optimization). Use pipes. Consider Windows Subsystem for Linux (WSL).

### H.2 Data-Specific Questions

**Q: My NetCDF file has longitude values from 0 to 360. How do I convert to -180 to 180?**
A: Use `cdo sellonlatbox,-180,180,-90,90 input.nc output.nc` or `cdo remapbil,r360x180 input.nc output.nc`.

**Q: How do I handle missing values in CDO?**
A: CDO automatically recognizes missing values from the NetCDF `_FillValue` or missing_value attribute. You can set missing values with `cdo setmissval,new_value`.

**Q: What do I do if my time axis is in "days since ..." but I need dates?**
A: CDO automatically interprets time units. Use `cdo showdate` to see calendar dates, `cdo showtime` for times.

**Q: My GRIB file won't load in CDO. What's wrong?**
A: Check if ecCodes is installed (CDO needs it for GRIB2). Try `cdo -v` to verify GRIB support. Convert to NetCDF first.

### H.3 Error Troubleshooting

**Q: "Segmentation fault" when running CDO - what now?**
A: This usually indicates a memory issue. Try: reduce parallel threads, add `-L` flag, process smaller chunks, update CDO to latest version.

**Q: "Error: Too many open files"**
A: Increase your system's open file limit. On Linux: `ulimit -n 4096`. In pipes, ensure each operator completes before the next starts.

**Q: "Error: cdo remapbil: Input file contains grid cell corners? Use remapycon instead?"**
A: This happens when the input has curvilinear coordinates. Try `remapycon` (conservative remapping for curvilinear grids) or preprocess with `cdo setgridtype,regular`.

## I. Best Practices Checklist

### I.1 Data Management

- [ ] Use descriptive filenames (e.g., `era5_t2m_1980_2020_monthly.nc`)
- [ ] Keep raw data separate from processed data
- [ ] Document processing steps in scripts (not manual commands)
- [ ] Use version control (git) for analysis scripts
- [ ] Maintain a data inventory (what, where, when, how)
- [ ] Compress large files with `-z zip_5`
- [ ] Verify data integrity after download (checksums)

### I.2 Workflow Practices

- [ ] Always use `-O` flag in scripts (overwrite without prompting)
- [ ] Use `-P N` for CPU-intensive operations
- [ ] Pre-compute remapping weights when processing multiple files
- [ ] Chain operations with pipes to avoid intermediate files
- [ ] Log all processing steps with timestamps
- [ ] Use error handling (`set -euo pipefail` in bash)
- [ ] Test pipelines on small subsets before full data runs

### I.3 Quality Assurance

- [ ] Inspect data with `cdo info` before processing
- [ ] Check for missing values and outliers
- [ ] Verify time axis with `cdo showdate`
- [ ] Check grid description with `cdo griddes`
- [ ] Validate results against known values or benchmarks
- [ ] Document assumptions and thresholds used
- [ ] Cross-check with independent datasets

### I.4 Reproducibility

- [ ] Save all processing commands in version-controlled scripts
- [ ] Record software versions (CDO, Python libraries)
- [ ] Document data sources with DOIs or access dates
- [ ] Use random seeds where applicable
- [ ] Package results with scripts and data citations
- [ ] Create README files explaining the workflow

## J. References Cited Throughout the Course

### Module 1-3: Introduction and File Operations
- CDO Project Page: https://code.mpimet.mpg.de/projects/cdo
- NetCDF Format: https://www.unidata.ucar.edu/software/netcdf/
- CF Conventions: https://cfconventions.org/

### Module 4: Data Selection
- CDO Selection Operators: https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-480004.2
- GRIB Parameter Database: https://apps.ecmwf.int/codes/grib/param-db/

### Module 5: Arithmetic Operations
- CDO Expression Syntax: https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-700005.2

### Module 6: Comparison and Conditional Operators
- CDO Comparison Operators: https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-610005.2

### Module 7: Temporal Operators
- Schulzweida, U. (2023). Temporal Statistics. CDO User Guide.
- Trenberth, K.E. (1983). What are the Seasons? BAMS, 64, 1276-1282.

### Module 8: Spatial Operators
- Jones, P.W. (1999). First- and Second-Order Conservative Remapping Schemes. MWR, 127, 2204-2210.
- CDO Remapping Documentation: https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-870006.2

### Module 9: Statistical Operators
- Wilks, D.S. (2019). Statistical Methods in the Atmospheric Sciences (4th ed.). Academic Press.
- CDO Statistics Documentation: https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-580005.2

### Module 10: Climate Indices and Extremes
- ETCCDI Indices: https://www.wcrp-climate.org/etccdi
- Zhang, X. et al. (2011). Indices for monitoring changes in extremes. WIREs Climate Change, 2, 851-870.
- Sillmann, J. et al. (2013). Climate extremes indices in CMIP5. JGR Atmospheres, 118, 1718-1732.
- McKee, T.B. et al. (1993). The relationship of drought frequency and duration to time scales. AMS Conference.

### Module 11: Advanced Workflows and Automation
- xarray Documentation: https://docs.xarray.dev/
- Cartopy Documentation: https://scitools.org.uk/cartopy/
- Plotly Documentation: https://plotly.com/python/
- CDS API: https://cds.climate.copernicus.eu/api-how-to

### Module 12: Capstone Projects
- GPCC Precipitation Data: https://www.dwd.de/gpcc
- CHIRPS Precipitation Data: https://www.chc.ucsb.edu/data/chirps
- CRU TS Temperature Data: https://crudata.uea.ac.uk/cru/data/hrg
- ERA5 Reanalysis: https://cds.climate.copernicus.eu
- CMIP6 Data: https://esgf-node.llnl.gov/projects/esgf-llnl/

## K. Online Resources and Communities

### K.1 Forums and Q&A

- **CDO Mailing List**: https://code.mpimet.mpg.de/projects/cdo/lists - Official user support
- **Stack Overflow (cdo tag)**: https://stackoverflow.com/questions/tagged/cdo - Community Q&A
- **ResearchGate CDO Topics**: https://www.researchgate.net/topics - Climate data analysis discussions
- **GitHub Discussions**: https://github.com/MPI-MagDE/cdo/discussions - Community discussions

### K.2 Tutorials and Courses

- **CDO Examples Gallery**: https://code.mpimet.mpg.de/projects/cdo/wiki/Examples - Official examples
- **NCAR CDO Tutorial**: https://www.cgd.ucar.edu/cert/cdo_tutorial.pdf - Comprehensive tutorial
- **ECMWF CDO Training**: https://confluence.ecmwf.int/display/CUSF - ECMWF ODB/CDO resources
- **YouTube Tutorials**: Search "CDO climate data operators" for video walkthroughs

### K.3 Blogs and Articles

- **Climate Data Guide (NCAR)**: https://climatedataguide.ucar.edu - Dataset reviews and guidance
- **RealClimate**: https://www.realclimate.org - Climate science commentary
- **Carbon Brief**: https://www.carbonbrief.org - Climate science explained
- **Climate Lab Book**: https://www.climate-lab-book.ac.uk - Visualization and analysis examples

### K.4 Conferences and Workshops

- **EGU General Assembly**: https://www.egu.eu - Annual European geosciences conference
- **AGU Fall Meeting**: https://www.agu.org/annual-meeting - Major US geosciences meeting
- **NCAR CDO Workshops**: Periodic training sessions organized by NCAR
- **ECMWF Annual Seminar**: https://www.ecmwf.int - Annual meteorological seminars

### K.5 Data Portals

- **Copernicus Climate Data Store**: https://cds.climate.copernicus.eu
- **NASA Earthdata**: https://earthdata.nasa.gov
- **NOAA PSL Data**: https://psl.noaa.gov/data
- **IRI Data Library**: https://iridl.ldeo.columbia.edu
- **World Bank Climate Data**: https://climateknowledgeportal.worldbank.org

## L. Troubleshooting Guide

### L.1 Installation Problems

**Problem: CDO not found after installation**
```bash
# Check if installed
cdo --version
# If not found, add to PATH
export PATH=/path/to/cdo/bin:$PATH   # Linux/macOS
# On Windows, ensure conda environment is activated
conda activate climate
```

**Problem: GRIB support missing**
```bash
# Check GRIB support
cdo -v | findstr grib
# Install ecCodes alongside CDO
conda install -c conda-forge cdo eccodes
```

**Problem: Compilation errors (building from source)**
Check dependencies: zlib, hdf5, netcdf-c, eccodes, proj, udunits.
```bash
sudo apt-get install libhdf5-dev libnetcdf-dev libeccodes-dev   # Ubuntu
brew install hdf5 netcdf eccodes                                  # macOS
```

### L.2 Runtime Errors

**Problem: "Segmentation fault (core dumped)"**
- Cause: Usually memory exhaustion or incompatible file format
- Solution: Use `-L` flag, reduce threads with `-P 2`, process smaller chunks

**Problem: "Unsupported grid type"**
- Cause: Reduced Gaussian, curvilinear, or unstructured grid
- Solution: Convert to regular grid first with `cdo remapbil,r360x180`

**Problem: "Time axis not monotonic"**
- Cause: File contains unsorted or duplicate time steps
- Solution: Use `cdo sorttimestamp` or `cdo mergetime` to fix

**Problem: "Operator not found"**
- Cause: Typo or operator not available in your CDO version
- Solution: Check spelling, update CDO, or use alternative operator

**Problem: "Too many open files"**
- Cause: System file descriptor limit reached
- Solution: Increase limit: `ulimit -n 10000` (Linux/macOS)

### L.3 Data Issues

**Problem: Missing values not recognized**
```bash
# Set missing value explicitly
cdo setmissval,-999 data.nc fixed.nc
```

**Problem: Longitude range 0-360 vs -180 to 180 mismatch**
```bash
# Convert 0-360 to -180 to 180
cdo sellonlatbox,-180,180,-90,90 data_360.nc data_180.nc
```

**Problem: Inconsistent time units between files**
```bash
# CDO may fail when merging files with different time units
# Use setreftime to standardize
cdo setreftime,1900-01-01,00:00:00,days file1.nc file1_fixed.nc
```

**Problem: Variables renamed or missing expected names**
```bash
# Find available variables
cdo showname data.nc
# Rename if needed
cdo chname,old_var,new_var data.nc renamed.nc
```

### L.4 Performance Troubleshooting

**Issue: CDO is very slow**
- Use `-P N` with appropriate N (number of cores)
- Avoid intermediate files -- use pipes
- Check disk speed (SSD recommended for large files)
- Use `-f nc4 -z zip_1` for faster compression
- Precompute remapping weights

**Issue: Out of memory**
- Use `-L` flag for large-file mode
- Process in temporal chunks (e.g., year by year)
- Select only needed variables with `selname`
- Use `-f nc4` which is more memory-efficient than classic NetCDF

## M. Key CDO Commands Quick Reference

```bash
# File Information
cdo infov file.nc              # Variable info with statistics
cdo sinfo file.grib             # GRIB file structure
cdo griddes file.nc             # Grid description
cdo showdate file.nc            # Time steps as dates
cdo showyear file.nc            # Years present
cdo nmlist file.nc              # NetCDF metadata dump

# Selection
cdo selname,tas file.nc out.nc  # Select variable
cdo seldate,2000-01-01 file.nc  # Select by date
cdo sellonlatbox,lon1,lon2,lat1,lat2 file.nc  # Spatial crop
cdo seltimestep,1/10 file.nc    # Select timesteps 1-10

# Temporal
cdo daymean file.nc out.nc      # Daily mean
cdo monmean file.nc out.nc      # Monthly mean
cdo yearmean file.nc out.nc     # Annual mean
cdo ymonmean file.nc out.nc     # Monthly climatology
cdo ymonsub file.nc out.nc      # Monthly anomaly

# Spatial
cdo fldmean file.nc out.nc      # Spatial mean
cdo remapbil,target.nc src.nc out.nc  # Bilinear remap
cdo genbil,target.nc src.nc w.nc     # Generate weights

# Statistics
cdo timmean file.nc out.nc      # Temporal mean
cdo timpctl,90 file.nc min.nc max.nc out.nc  # 90th percentile
cdo ensmean f1.nc f2.nc f3.nc out.nc  # Ensemble mean

# Indices
cdo yearsum -ltc,0 tn.nc fd.nc  # Frost days
cdo yearmax -runsum,5 pr.nc rx5day.nc  # Max 5-day precip
```

```{tip}
Save this quick reference as a cheat sheet. The most commonly used CDO operators are: `selname`, `sellonlatbox`, `seldate`, `fldmean`, `timmean`, `monmean`, `yearmean`, `ymonsub`, `remapbil`, `ensmean`, and `output`.
```

## N. Version Information

```bash
# Check your CDO version
cdo --version

# Check installed components (NetCDF, GRIB, etc.)
cdo -v

# Check Python library versions
python -c "import xarray; print(xarray.__version__)"
python -c "import cartopy; print(cartopy.__version__)"
python -c "import matplotlib; print(matplotlib.__version__)"
```

```{note}
This course was written for CDO version 2.x. Most commands are also compatible with CDO 1.9.x, but some newer operators may not be available. Check the CDO changelog for version-specific features.
```

## O. Contributing and Feedback

This training course is maintained by the course authors. Contributions, corrections, and suggestions are welcome.

- **Course Repository**: [Course URL / GitHub link]
- **Issue Tracker**: [Link to issue tracker]
- **License**: CC BY 4.0 International

```{warning}
The examples in this course use sample data paths and filenames. Adapt these paths to your local data organization. All commands have been tested but results may vary depending on CDO version, operating system, and data characteristics.
```

## Summary of References

This reference module provides:

- Complete documentation and links for CDO, NetCDF, GRIB, and CF conventions
- Comprehensive list of climate data sources (reanalysis, observations, projections)
- FAQ section addressing common CDO errors and solutions
- Best practices checklist for data management and reproducibility
- Glossary of key climate data terminology
- Quick reference of most frequently used CDO commands
- All references cited throughout the 12-module course

```{tip}
Bookmark this reference module for quick access during your climate data analysis work. The best practices checklist (Section I) is particularly useful when setting up new analysis projects.
```

This concludes the Climate Data Operators (CDO) Training Course. Thank you for your dedication to learning climate data analysis.
