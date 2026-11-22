# Climate Data Operators (CDO): Complete Training for Climate Data Processing, Analysis, and Visualization

[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://www.python.org/)
[![CDO](https://img.shields.io/badge/CDO-2.4.0-green?logo=linux)](https://code.mpimet.mpg.de/projects/cdo)
[![NCO](https://img.shields.io/badge/NCO-5.2.0-orange)](https://nco.sourceforge.net/)
[![Jupyter Book](https://img.shields.io/badge/Jupyter%20Book-1.0-red?logo=jupyter)](https://jupyterbook.org/)
[![MyST](https://img.shields.io/badge/MyST-1.0-purple)](https://mystmd.org/)
[![MIT License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Conda](https://img.shields.io/badge/conda--forge-cdo--training-success?logo=anaconda)](environment.yml)

A comprehensive, project-based training course for processing, analyzing, and visualizing climate data using the Climate Data Operators (CDO) toolkit.

---

## Description

This course provides a structured learning path from foundational CDO commands to advanced climate data workflows. Designed for researchers, students, and professionals working with climate model outputs, reanalysis datasets, and observational data, it covers NetCDF and GRIB file handling, temporal and spatial analysis, statistical methods, and real-world climate index computation.

All material is delivered via interactive Jupyter Notebooks, rendered as a static website with Jupyter Book.

## Course Modules

| Module | Topics | File |
|--------|--------|------|
| Introduction | Course overview, learning objectives | `book/introduction.md` |
| Installation | CDO setup, conda environment, verification | `book/installation.md` |
| CDO Basics | File info, metadata, operators overview | `book/basics.md` |
| Core Operators | Select, merge, split, remap, math | `book/operators.md` |
| NetCDF Operations | Attributes, dimensions, variables, CF conventions | `book/netcdf.md` |
| GRIB Operations | GRIB edition 1 & 2, parameter conversion | `book/grib.md` |
| Temporal Analysis | Time series, seasonal/diurnal cycles, anomalies | `book/temporal.md` |
| Spatial Analysis | Regional extraction, regridding, masks | `book/spatial.md` |
| Statistics | Climatologies, percentiles, correlations | `book/statistics.md` |
| Climate Indices | Heat waves, drought indices, ETCCDI | `book/climate_indices.md` |
| Workflows | Automation, shell scripts, parallel processing | `book/workflows.md` |
| Projects | Guided case studies with real datasets | `book/projects.md` |
| References | Bibliography, dataset sources, further reading | `book/references.md` |

## Prerequisites

- Basic command-line experience
- Familiarity with climate data formats (NetCDF / GRIB) is helpful but not required
- A computer running Linux, macOS, or Windows (WSL recommended for Windows)

## Installation

Create the conda environment:

```bash
conda env create -f environment.yml
conda activate cdo-training
```

Verify the installation:

```bash
cdo --version
python -c "import xarray; print(xarray.__version__)"
```

To install via pip only:

```bash
pip install -r requirements.txt
```

## Learning Outcomes

By the end of this course you will be able to:

- Navigate and manipulate NetCDF and GRIB files with CDO
- Perform temporal and spatial subsetting, aggregation, and regridding
- Compute climate indices (e.g., heat wave duration, drought indices)
- Automate large-scale data processing workflows
- Visualize climate data with Matplotlib, Cartopy, and PyGMT
- Build and publish interactive training materials with Jupyter Book

## Tech Stack

- **Climate Data Operators (CDO)** — command-line climate data processing
- **NCO** — netCDF Operators for file-level manipulation
- **xarray** — labeled multi-dimensional arrays in Python
- **Matplotlib / Cartopy / PyGMT** — visualization and mapping
- **Jupyter Book / MyST** — documentation and publishing
- **Conda / pip** — environment management

## Project Structure

```
Climate-Data-Operators-CDO/
├── README.md
├── LICENSE
├── CITATION.cff
├── environment.yml
├── requirements.txt
├── myst.yml
├── _toc.yml
├── _config.yml
├── book/
│   ├── introduction.md
│   ├── installation.md
│   ├── basics.md
│   ├── operators.md
│   ├── netcdf.md
│   ├── grib.md
│   ├── temporal.md
│   ├── spatial.md
│   ├── statistics.md
│   ├── climate_indices.md
│   ├── workflows.md
│   ├── projects.md
│   ├── references.md
│   └── references.bib
├── assets/
│   ├── logo.png
│   └── favicon.ico
├── notebooks/
├── data/
│   ├── real_temperature.nc        # Real NCEP/DOE Reanalysis-2 temperature field
│   ├── real_temp.nc               # Real temperature subset (notebook 01)
│   ├── real_monthly_temp.nc       # Real monthly temperature (notebook 02)
│   ├── real_spatial_temp.nc       # Real spatial temperature (notebook 03)
│   ├── real_climate_indices.nc    # Real temperature + CHIRPS precipitation (notebook 04)
│   └── real_visualization_data.nc # Real temperature + precipitation (notebook 06)
└── docs/
```

All files under `data/` are derived from real observational or reanalysis datasets
(NCEP/DOE Reanalysis-2 and CHIRPS). No synthetic fields are included.

## Contributing

Contributions are welcome. Please open an issue or submit a pull request on [GitHub](https://github.com/climate-data-science/Climate-Data-Operators-CDO).

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## License

This course material is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.  
Course content is licensed under [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).

## Citation

If you use this course in your work, please cite it as:

```bibtex
@misc{cdo_training_2025,
  author       = {Climate Data Science Community},
  title        = {{Climate Data Operators (CDO): Complete Training for Climate Data Processing, Analysis, and Visualization}},
  year         = {2025},
  version      = {1.0.0},
  url          = {https://github.com/climate-data-science/Climate-Data-Operators-CDO}
}
```

---

<p align="center">
  <b>Climate Data Science Community</b> — <a href="https://github.com/climate-data-science/Climate-Data-Operators-CDO">github.com/climate-data-science/Climate-Data-Operators-CDO</a>
</p>
