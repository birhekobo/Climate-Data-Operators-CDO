---
title: "Project 7: Climate Dashboard"
subject: Climate Data Operators (CDO) Training
subtitle: Building an Interactive Climate Data Dashboard with CDO and Plotly
---

# Project 7: Climate Dashboard

## Overview

This project guides you through creating an interactive climate data dashboard that combines CDO data processing with Plotly visualization. The dashboard provides an intuitive interface for exploring temperature, precipitation, and climate extreme data through interactive maps, time series, and statistical summaries.

```{note}
**Estimated time**: 3-4 hours
**Prerequisites**: Modules 1-11, Python with Plotly and xarray
```

## Learning Objectives

After completing this project, you will be able to:

- Process multiple climate variables with CDO for dashboard consumption
- Export CDO-processed data to CSV and NetCDF formats suitable for web visualization
- Create interactive time series with Plotly Express and Graph Objects
- Build interactive map visualizations with Plotly
- Design a multi-panel dashboard layout
- Automate dashboard generation from raw data

## Data Requirements

### Data Sources

This project can use data from any previous project, including:
- Processed precipitation data from **Project 1**
- Temperature data from **Project 2**
- Drought indices from **Project 3**
- Climate extremes from **Project 4**

Alternatively, use the real reanalysis and precipitation fields bundled with this course.

```bash
# Inspect the real data bundled with the course
cdo sinfo ../datasets/tas_sample.nc
cdo sinfo ../datasets/chirps_ethiopia.nc

# Prepare a combined monthly temperature field from the real reanalysis
cdo ymonmean ../datasets/tas_sample.nc t2m_mean.nc
```

## Step-by-Step Workflow

### Step 1: Data Preparation with CDO

Prepare multiple climate variables and indices for the dashboard:

```bash
# =============================================================================
# Data Preparation for Dashboard
# =============================================================================
mkdir -p dashboard_data

# --- Temperature Variables ---
# Monthly mean temperature (Celsius)
cdo -O -expr,'t2m_c=t2m-273.15' era5_t2m.nc dashboard_data/t2m_c.nc

# Temperature anomalies
cdo -O -selyear,1981/2010 dashboard_data/t2m_c.nc dashboard_data/ref.nc
cdo -O -ymonmean dashboard_data/ref.nc dashboard_data/clim.nc
cdo -O -ymonsub dashboard_data/t2m_c.nc dashboard_data/clim.nc \
    dashboard_data/anom.nc

# Annual and seasonal means
cdo -O -yearmean dashboard_data/t2m_c.nc dashboard_data/t2m_annual.nc
cdo -O -fldmean dashboard_data/t2m_annual.nc dashboard_data/t2m_global.nc

# Regional averages
cdo -O -fldmean -sellonlatbox,-10,10,35,50 dashboard_data/t2m_c.nc \
    dashboard_data/t2m_southern.nc
cdo -O -fldmean -sellonlatbox,-10,10,50,70 dashboard_data/t2m_c.nc \
    dashboard_data/t2m_northern.nc

# --- Precipitation Variables ---
cdo -O -mulc,1000 -selname,tp era5_tp.nc dashboard_data/tp_mm.nc
cdo -O -yearsum dashboard_data/tp_mm.nc dashboard_data/tp_annual.nc
cdo -O -fldmean dashboard_data/tp_annual.nc dashboard_data/tp_global.nc

# Seasonal precipitation
cdo -O -seasum dashboard_data/tp_mm.nc dashboard_data/tp_seasonal.nc

# --- Climate Extreme Indices ---
# Frost days (from daily data or approximate from monthly)
# Summer days
# Heavy precipitation days

# --- Export time series to CSV ---
echo "Exporting time series..."
for var in t2m_global t2m_southern t2m_northern tp_global; do
    cdo outputts dashboard_data/${var}.nc > dashboard_data/${var}.csv
done

# Seasonal climatology
cdo output -ymonmean dashboard_data/t2m_c.nc > dashboard_data/t2m_clim.csv
cdo output -ymonsum dashboard_data/tp_mm.nc > dashboard_data/tp_clim.csv

# --- Spatial data for maps ---
# Long-term mean map
cdo -O -timmean dashboard_data/t2m_c.nc dashboard_data/t2m_mean_map.nc
cdo -O -timmean dashboard_data/anom.nc dashboard_data/anom_mean_map.nc

# Trend maps
cdo -O -trend dashboard_data/t2m_annual.nc \
    dashboard_data/trend_int.nc dashboard_data/trend_slope.nc
cdo -O -mulc,10 dashboard_data/trend_slope.nc dashboard_data/trend_per_dec.nc
```

### Step 2: CSV Data Export Functions

Create data export utilities:

```bash
#!/bin/bash
# export_dashboard_data.sh
# Export CDO-processed data to CSV for dashboard ingestion

export_to_csv() {
    local nc_file=$1
    local csv_file="${nc_file%.nc}.csv"

    if [ -f "$nc_file" ]; then
        # Export with headers
        cdo outputts "$nc_file" > "$csv_file"
        echo "Exported: $csv_file"
    else
        echo "WARNING: $nc_file not found"
    fi
}

# Spatially averaged time series
echo "=== Exporting Dashboard Data ==="
for var in t2m_global t2m_southern t2m_northern t2m_central \
           tp_global anom_global; do
    export_to_csv "dashboard_data/${var}.nc"
done

# Export spatial grids for map visualization
cdo outputf,"%.2f",1 -timmean dashboard_data/t2m_c.nc > dashboard_data/t2m_mean_grid.csv
cdo outputf,"%.2f",1 -timmean dashboard_data/tp_mm.nc > dashboard_data/tp_mean_grid.csv
cdo outputf,"%.4f",1 dashboard_data/trend_per_dec.nc > dashboard_data/trend_grid.csv

# Export coordinate grids
cat > dashboard_data/lonlat.txt << 'EOF'
# Grid coordinates extracted from CDO
EOF
cdo griddes dashboard_data/t2m_c.nc | grep -E "^(xsize|ysize|xfirst|yfirst|xinc|yinc)" \
    > dashboard_data/grid_info.txt

echo "Dashboard data export complete!"
```

### Step 3: Interactive Dashboard with Plotly

Save as `create_dashboard.py`:

```python
#!/usr/bin/env python3
"""
Interactive Climate Data Dashboard using Plotly.
Generates a self-contained HTML dashboard from CDO-processed data.
"""
import numpy as np
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import json
from pathlib import Path

DATA_DIR = Path("dashboard_data")
OUTPUT_DIR = Path("dashboard_output")
OUTPUT_DIR.mkdir(exist_ok=True)

def load_timeseries(filename):
    """Load CDO outputts CSV file."""
    path = DATA_DIR / filename
    if not path.exists():
        print(f"Warning: {path} not found")
        return None

    try:
        df = pd.read_csv(path, header=None, names=["time", "value"], sep=r"\s+")
        df["time"] = pd.to_datetime(df["time"])
        return df
    except Exception as e:
        print(f"Error loading {path}: {e}")
        return None

def create_temperature_panel():
    """Temperature time series panel."""
    df_global = load_timeseries("t2m_global.csv")
    df_north = load_timeseries("t2m_northern.csv")
    df_south = load_timeseries("t2m_southern.csv")

    fig = go.Figure()

    if df_global is not None:
        # Annual mean from monthly
        df_annual = df_global.copy()
        df_annual["year"] = df_annual["time"].dt.year
        annual = df_annual.groupby("year")["value"].mean()

        # Trend line
        years = annual.index.values
        values = annual.values
        slope = np.polyfit(years, values, 1)[0]
        trend_line = np.polyval(np.polyfit(years, values, 1), years)

        fig.add_trace(go.Scatter(
            x=years, y=values,
            mode="lines+markers",
            name="Global Mean Temperature",
            line=dict(color="crimson", width=2),
            marker=dict(size=6)
        ))

        fig.add_trace(go.Scatter(
            x=years, y=trend_line,
            mode="lines",
            name=f"Trend: {slope*10:.2f}C/decade",
            line=dict(color="black", width=2, dash="dash")
        ))

    fig.update_layout(
        title="<b>Temperature Time Series</b>",
        xaxis_title="Year",
        yaxis_title="Temperature (C)",
        hovermode="x unified",
        legend=dict(yanchor="bottom", y=0.01, xanchor="right", x=0.99)
    )

    return fig

def create_anomaly_panel():
    """Temperature anomaly panel."""
    df = load_timeseries("t2m_global.csv")
    if df is None:
        return go.Figure()

    # Compute anomalies relative to 1981-2010
    ref = df[(df["time"].dt.year >= 1981) & (df["time"].dt.year <= 2010)]
    ref_mean = ref["value"].mean() if len(ref) > 0 else df["value"].mean()

    df["anomaly"] = df["value"] - ref_mean
    df_annual = df.copy()
    df_annual["year"] = df_annual["time"].dt.year
    annual = df_annual.groupby("year")["anomaly"].mean()

    colors = ["red" if v > 0 else "blue" for v in annual.values]

    fig = go.Figure()
    fig.add_trace(go.Bar(
        x=annual.index, y=annual.values,
        marker_color=colors,
        name="Temperature Anomaly"
    ))

    fig.update_layout(
        title="<b>Temperature Anomaly (ref: 1981-2010)</b>",
        xaxis_title="Year",
        yaxis_title="Anomaly (C)",
        hovermode="x unified",
        showlegend=False
    )

    return fig

def create_precipitation_panel():
    """Precipitation time series panel."""
    df = load_timeseries("tp_global.csv")
    if df is None:
        return go.Figure()

    df["year"] = df["time"].dt.year
    annual = df.groupby("year")["value"].sum()

    fig = go.Figure()
    fig.add_trace(go.Bar(
        x=annual.index, y=annual.values,
        marker_color="steelblue",
        name="Annual Precipitation",
        marker_line_color="navy",
        marker_line_width=1
    ))

    # Mean line
    mean_val = annual.values.mean()
    fig.add_hline(y=mean_val, line_dash="dot", line_color="gray",
                  annotation_text=f"Mean: {mean_val:.0f} mm/yr")

    fig.update_layout(
        title="<b>Annual Precipitation</b>",
        xaxis_title="Year",
        yaxis_title="Precipitation (mm)",
        hovermode="x unified",
        showlegend=False
    )

    return fig

def create_seasonal_cycle_panel():
    """Seasonal cycle climatology panel."""
    t2m_clim = load_timeseries("t2m_clim.csv")
    tp_clim = load_timeseries("tp_clim.csv")

    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    fig = make_subplots(specs=[[{"secondary_y": True}]])

    if t2m_clim is not None and len(t2m_clim) >= 12:
        vals = t2m_clim["value"].values[:12]
        fig.add_trace(
            go.Scatter(x=months, y=vals,
                       mode="lines+markers",
                       name="Temperature",
                       marker=dict(color="crimson", size=8),
                       line=dict(color="crimson", width=2)),
            secondary_y=False
        )

    if tp_clim is not None and len(tp_clim) >= 12:
        vals = tp_clim["value"].values[:12]
        fig.add_trace(
            go.Bar(x=months, y=vals,
                   name="Precipitation",
                   marker_color="steelblue",
                   opacity=0.6),
            secondary_y=True
        )

    fig.update_layout(
        title="<b>Seasonal Cycle Climatology</b>",
        hovermode="x unified",
        legend=dict(yanchor="top", y=0.99, xanchor="left", x=0.01)
    )
    fig.update_yaxes(title_text="Temperature (C)", secondary_y=False)
    fig.update_yaxes(title_text="Precipitation (mm)", secondary_y=True)

    return fig

def create_temperature_map():
    """Interactive temperature map using Plotly."""
    try:
        import xarray as xr
        ds = xr.open_dataset(DATA_DIR / "t2m_mean_map.nc")
        var = list(ds.data_vars)[0]
        data = ds[var].values - 273.15 if ds[var].units == "K" else ds[var].values
        lons, lats = ds.lon.values, ds.lat.values
    except Exception:
        # Fallback: use the real reanalysis field bundled with the course
        import xarray as xr
        ds = xr.open_dataset("../datasets/tas_sample.nc").isel(time=0)
        data = ds.tas.values - 273.15
        lons, lats = ds.lon.values, ds.lat.values

    fig = go.Figure(data=go.Contour(
        z=data,
        x=lons,
        y=lats,
        colorscale="RdBu_r",
        contours=dict(coloring="heatmap", showlabels=True),
        colorbar=dict(title="Temperature (C)")
    ))

    fig.update_layout(
        title="<b>Mean Temperature Map</b>",
        xaxis_title="Longitude",
        yaxis_title="Latitude",
        height=500,
        hovermode="closest"
    )

    return fig

def create_extremes_panel():
    """Climate extremes summary panel."""
    indices = {
        "Annual Mean T": "t2m_global.csv",
        "Annual Precip": "tp_global.csv"
    }

    fig = go.Figure()

    # Create a radar/bullet chart or summary table
    try:
        t2m = load_timeseries("t2m_global.csv")
        tp = load_timeseries("tp_global.csv")

        if t2m is not None:
            t2m_annual = t2m.copy()
            t2m_annual["year"] = t2m_annual["time"].dt.year
            annual_temp = t2m_annual.groupby("year")["value"].mean()

            fig.add_trace(go.Indicator(
                mode="number+delta",
                value=annual_temp.iloc[-1],
                delta={"reference": annual_temp.iloc[0]},
                title={"text": "Latest Temperature (C)"},
                domain={"row": 0, "column": 0}
            ))

        if tp is not None:
            tp_annual = tp.copy()
            tp_annual["year"] = tp_annual["time"].dt.year
            annual_precip = tp_annual.groupby("year")["value"].sum()

            fig.add_trace(go.Indicator(
                mode="number+delta",
                value=annual_precip.iloc[-1],
                delta={"reference": annual_precip.iloc[0]},
                title={"text": "Latest Precip (mm/yr)"},
                domain={"row": 0, "column": 1}
            ))
    except Exception as e:
        fig.add_annotation(text=f"Could not load extremes data: {e}",
                          showarrow=False)

    fig.update_layout(
        title="<b>Climate Extremes Summary</b>",
        grid={"rows": 1, "columns": 2},
        height=250
    )

    return fig

def build_dashboard():
    """Assemble all components into the full dashboard."""
    print("Building dashboard panels...")

    # Create individual figures
    fig_temp = create_temperature_panel()
    fig_anom = create_anomaly_panel()
    fig_precip = create_precipitation_panel()
    fig_seasonal = create_seasonal_cycle_panel()
    fig_map = create_temperature_map()
    fig_extremes = create_extremes_panel()

    # Create combined dashboard using make_subplots
    fig = make_subplots(
        rows=4, cols=3,
        subplot_titles=(
            "Temperature Time Series",
            "Temperature Anomaly",
            "Annual Precipitation",
            "Seasonal Cycle",
            "Temperature Map",
            "Climate Summary"
        ),
        specs=[
            [{"type": "scatter"}, {"type": "scatter"}, {"type": "bar"}],
            [{"type": "scatter", "secondary_y": True}, {"type": "contour"}, {"type": "domain"}],
            [{"type": "scatter"}, {"type": "scatter"}, {"type": "scatter"}],
            [{"type": "xy"}, {"type": "xy"}, {"type": "xy"}]
        ],
        vertical_spacing=0.08,
        horizontal_spacing=0.05,
        row_heights=[0.3, 0.3, 0.2, 0.2]
    )

    # Add traces from temperature panel
    for trace in fig_temp.data:
        fig.add_trace(trace, row=1, col=1)

    # Add traces from anomaly panel
    for trace in fig_anom.data:
        fig.add_trace(trace, row=1, col=2)

    # Add traces from precipitation panel
    for trace in fig_precip.data:
        fig.add_trace(trace, row=1, col=3)

    # Add traces from seasonal cycle panel
    for trace in fig_seasonal.data:
        if hasattr(trace, "yaxis") and trace.yaxis == "y2":
            fig.add_trace(trace, row=2, col=1, secondary_y=True)
        else:
            fig.add_trace(trace, row=2, col=1)

    # Add traces from map
    for trace in fig_map.data:
        fig.add_trace(trace, row=2, col=2)

    # Add extremes summary
    for trace in fig_extremes.data:
        fig.add_trace(trace, row=2, col=3)

    fig.update_layout(
        title={
            "text": "<b>Climate Data Dashboard</b><br>"
                    "<sub>ERA5 Data | 1981-2020 | Interactive Visualization</sub>",
            "font": {"size": 20}
        },
        height=1400,
        hovermode="x unified",
        template="plotly_white",
        showlegend=True
    )

    # Save as HTML
    output_path = OUTPUT_DIR / "climate_dashboard.html"
    fig.write_html(str(output_path), include_plotlyjs="cdn",
                   config={"scrollZoom": True, "displaylogo": False})
    print(f"Dashboard saved: {output_path}")
    print(f"File size: {output_path.stat().st_size / 1024:.1f} KB")

def create_simple_dashboard():
    """Alternative: simple multi-panel dashboard for faster loading."""
    print("Creating simple dashboard...")

    fig = make_subplots(
        rows=2, cols=2,
        subplot_titles=(
            "Temperature (Annual Mean)",
            "Precipitation (Annual Total)",
            "Temperature Seasonal Cycle",
            "Temperature Anomaly"
        )
    )

    # Panel 1: Temperature
    df = load_timeseries("t2m_global.csv")
    if df is not None:
        df_ann = df.copy()
        df_ann["year"] = df_ann["time"].dt.year
        annual = df_ann.groupby("year")["value"].mean()
        fig.add_trace(
            go.Scatter(x=annual.index, y=annual.values,
                       mode="lines+markers", name="Temperature",
                       line=dict(color="crimson")),
            row=1, col=1
        )

    # Panel 2: Precipitation
    df = load_timeseries("tp_global.csv")
    if df is not None:
        df_ann = df.copy()
        df_ann["year"] = df_ann["time"].dt.year
        annual = df_ann.groupby("year")["value"].sum()
        fig.add_trace(
            go.Bar(x=annual.index, y=annual.values, name="Precipitation",
                   marker_color="steelblue"),
            row=1, col=2
        )

    # Panel 3: Seasonal cycle
    df = load_timeseries("t2m_clim.csv")
    if df is not None and len(df) >= 12:
        months = ["J","F","M","A","M","J","J","A","S","O","N","D"]
        vals = df["value"].values[:12]
        fig.add_trace(
            go.Scatter(x=months, y=vals, mode="lines+markers",
                       name="Climatology", line=dict(color="crimson")),
            row=2, col=1
        )

    # Panel 4: Anomaly
    df = load_timeseries("t2m_global.csv")
    if df is not None:
        ref = df[(df["time"].dt.year >= 1981) & (df["time"].dt.year <= 2010)]
        ref_mean = ref["value"].mean()
        df["anom"] = df["value"] - ref_mean
        df_ann = df.copy()
        df_ann["year"] = df_ann["time"].dt.year
        annual_anom = df_ann.groupby("year")["anom"].mean()
        colors = ["red" if v > 0 else "blue" for v in annual_anom.values]
        fig.add_trace(
            go.Bar(x=annual_anom.index, y=annual_anom.values,
                   marker_color=colors, name="Anomaly"),
            row=2, col=2
        )

    fig.update_layout(
        title="<b>Climate Dashboard (Simple)</b>",
        height=800,
        template="plotly_white",
        showlegend=False
    )

    output_path = OUTPUT_DIR / "climate_dashboard_simple.html"
    fig.write_html(str(output_path))
    print(f"Simple dashboard saved: {output_path}")

if __name__ == "__main__":
    Path(OUTPUT_DIR).mkdir(exist_ok=True)
    build_dashboard()
    create_simple_dashboard()
    print("Dashboard generation complete!")
```

### Step 4: Regional Selection Dashboard

Add interactive regional analysis:

```python
#!/usr/bin/env python3
"""Regional climate analysis dashboard."""
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import pandas as pd
import numpy as np

regions = {
    "Northern Europe (35-50N)": {"lat": (35, 50), "lon": (-10, 10)},
    "Southern Europe (50-70N)": {"lat": (50, 70), "lon": (-10, 10)},
    "Mediterranean": {"lat": (30, 45), "lon": (-5, 30)},
    "Scandinavia": {"lat": (55, 70), "lon": (5, 30)},
}

fig = make_subplots(
    rows=2, cols=2,
    subplot_titles=list(regions.keys()),
    specs=[[{"type": "scatter"}, {"type": "scatter"}],
           [{"type": "scatter"}, {"type": "scatter"}]]
)

for idx, (region_name, bounds) in enumerate(regions.items()):
    row = idx // 2 + 1
    col = idx % 2 + 1

    # Use real regional temperature from the bundled reanalysis
    import xarray as xr
    ds_reg = xr.open_dataset("../datasets/tas_sample.nc")
    lon_min, lon_max = bounds["lon"]
    lons_sel = [x for x in ds_reg.lon.values
                if lon_min <= ((x + 180) % 360 - 180) <= lon_max]
    reg = ds_reg.tas.sel(lat=slice(*bounds["lat"]), lon=lons_sel)
    reg = reg.mean(dim=("lat", "lon")) - 273.15
    annual = reg.groupby("time.year").mean("time")
    years, temps = annual.year.values, annual.values

    fig.add_trace(
        go.Scatter(x=years, y=temps, mode="lines+markers",
                   name=region_name, showlegend=False),
        row=row, col=col
    )

    # Add trend line
    slope = np.polyfit(years, temps, 1)[0]
    trend_line = np.polyval(np.polyfit(years, temps, 1), years)
    fig.add_trace(
        go.Scatter(x=years, y=trend_line, mode="lines",
                   line=dict(dash="dash", color="gray"),
                   showlegend=False),
        row=row, col=col
    )

fig.update_layout(
    title="<b>Regional Temperature Trends</b>",
    height=700,
    template="plotly_white"
)

output_path = Path("dashboard_output") / "regional_dashboard.html"
output_path.parent.mkdir(exist_ok=True)
fig.write_html(str(output_path))
print(f"Regional dashboard saved: {output_path}")
```

### Step 5: Automation Script

Save as `generate_dashboard.sh`:

```bash
#!/bin/bash
# =============================================================================
# Automated Climate Dashboard Generator
# Climate Data Operators (CDO) Training
# =============================================================================
set -euo pipefail

# Configuration
ERA5_DIR="data/raw"
OUTPUT_DIR="dashboard_output"
mkdir -p "$OUTPUT_DIR"

echo "=== Automated Dashboard Generator ==="

# Step 1: Process data with CDO
echo "[1/4] Processing climate data..."

# Temperature
cdo -O -expr,'t2m_c=var131-273.15' "$ERA5_DIR/era5_t2m.nc" \
    "$OUTPUT_DIR/t2m_c.nc" 2>/dev/null || {
    echo "Using bundled real reanalysis data..."
    cdo -O -expr,'t2m_c=tas-273.15' ../datasets/tas_sample.nc "$OUTPUT_DIR/t2m_c.nc"
}

# Annual and seasonal means
cdo -O -yearmean "$OUTPUT_DIR/t2m_c.nc" "$OUTPUT_DIR/t2m_annual.nc"
cdo -O -fldmean "$OUTPUT_DIR/t2m_annual.nc" "$OUTPUT_DIR/t2m_global.nc"
cdo -O -fldmean "$OUTPUT_DIR/t2m_c.nc" "$OUTPUT_DIR/t2m_global_monthly.nc"

# Climatology
cdo -O -selyear,1981/2010 "$OUTPUT_DIR/t2m_c.nc" "$OUTPUT_DIR/ref.nc"
cdo -O -ymonmean "$OUTPUT_DIR/ref.nc" "$OUTPUT_DIR/t2m_clim.nc"
cdo -O -output "$OUTPUT_DIR/t2m_clim.nc" > "$OUTPUT_DIR/t2m_clim.csv"

# Export time series
echo "[2/4] Exporting time series..."
cdo outputts "$OUTPUT_DIR/t2m_global.nc" > "$OUTPUT_DIR/t2m_global.csv"
cdo outputts "$OUTPUT_DIR/t2m_global_monthly.nc" > "$OUTPUT_DIR/t2m_global_monthly.csv"

# Step 3: Python dashboard generation
echo "[3/4] Generating dashboard..."
python create_dashboard.py 2>&1

# Step 4: Summary
echo "[4/4] Summary..."
echo "Dashboard files:"
ls -lh "$OUTPUT_DIR"/*.html 2>/dev/null
echo "Data files:"
ls -lh "$OUTPUT_DIR"/*.csv 2>/dev/null

echo "=== Dashboard Generation Complete ==="
echo "Open dashboard_output/climate_dashboard.html in your browser"
```

## Expected Outputs

### 1. Interactive HTML Dashboard (`climate_dashboard.html`)
Self-contained HTML file with:
- Temperature time series with trend line overlay
- Temperature anomaly bar chart (colored by sign)
- Precipitation annual totals with mean reference
- Seasonal cycle climatology (dual-axis: temperature + precipitation)
- Mean temperature contour map
- Climate extremes summary indicators

### 2. Simple Dashboard (`climate_dashboard_simple.html`)
Lightweight 2x2 panel version with faster loading.

### 3. Regional Dashboard (`regional_dashboard.html`)
Four-panel dashboard comparing temperature trends across European sub-regions.

## Dashboard Features

### Interactivity
- **Hover**: Tooltip shows exact values on hover
- **Zoom**: Click and drag to zoom on any panel
- **Pan**: Click and drag after zooming
- **Autoscale**: Double-click to reset view
- **Legend**: Click to toggle data series visibility
- **Download**: Camera icon to save as PNG

### Design
- Clean white template with high contrast
- Consistent color scheme across panels
- Clear axis labels and titles
- Responsive layout

## Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| CDO data processing | 20% | Correct use of operators for dashboard data preparation |
| Data export | 15% | Proper CSV and NetCDF export formats |
| Plotly visualization | 25% | Effective use of Plotly for interactive figures |
| Dashboard design | 20% | Layout, organization, and visual design |
| Automation | 10% | Scriptable generation from raw data |
| Interactivity | 10% | Zoom, hover, and interactive features working |

## Extension Activities

### Advanced Features

1. **Animation**: Add animation slider for temporal map visualization
2. **Dropdown selectors**: Add region/variable selection menus
3. **Dash framework**: Convert to a live Dash web application
4. **CMIP6 integration**: Add future projection data from **Project 6**
5. **Real-time updates**: Integrate with operational data streams

```python
# Example: Add dropdown selector
import plotly.graph_objects as go

fig = go.Figure()
fig.update_layout(
    updatemenus=[
        dict(
            buttons=[
                dict(label="Temperature", method="update",
                     args=[{"visible": [True, False]}]),
                dict(label="Precipitation", method="update",
                     args=[{"visible": [False, True]}]),
            ],
            direction="down",
            showactive=True,
        )
    ]
)
```

### Cross-Project Integration

- Use processed data from **Projects 1-6** as dashboard data sources
- Integrate the dashboard into the automated report from **Project 8**
- Add a tab comparing historical data with CMIP6 projections from **Project 6**

```{exercise}
Complete the climate dashboard. Generate the interactive HTML dashboard with at least 6 panels showing different climate variables. Ensure all panels have proper titles, axis labels, and interactive features. Add at least one custom feature (e.g., regional selector, animation, or comparison overlay).
```

## References

- Plotly Python Documentation: https://plotly.com/python/
- Plotly Express: https://plotly.com/python/plotly-express/
- xarray Documentation: https://docs.xarray.dev/
- CDO Documentation: https://code.mpimet.mpg.de/projects/cdo
