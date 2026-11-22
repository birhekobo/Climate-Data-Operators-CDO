#!/bin/bash
# automated_report.sh
# Automated climate data report generator.
set -euo pipefail

INPUT_DIR="../datasets"
OUTPUT_DIR="../output"
REPORT_DIR="../report"
mkdir -p "$REPORT_DIR"

TAS_FILE="$INPUT_DIR/tas_sample.nc"
PR_FILE="$INPUT_DIR/pr_sample.nc"

echo "============================================"
echo "  Automated Climate Data Report Generator"
echo "============================================"
echo ""

LOG_FILE="$REPORT_DIR/report.log"
exec 2>"$LOG_FILE"  # redirect stderr to log

# --------------------------------------------------
# Helper: log + echo
# --------------------------------------------------
log() {
    echo "$1"
    echo "$1" >> "$LOG_FILE"
}

log "Report generated: $(date)"
log ""

# --------------------------------------------------
# 1. Process temperature
# --------------------------------------------------
log "--- Temperature Processing ---"
cdo selyear,2000/2005 "$TAS_FILE" "$REPORT_DIR/tas_subset.nc" 2>/dev/null
cdo yearmean "$REPORT_DIR/tas_subset.nc" "$REPORT_DIR/tas_yearmean.nc" 2>/dev/null
cdo fldmean "$REPORT_DIR/tas_yearmean.nc" "$REPORT_DIR/tas_global_mean.nc" 2>/dev/null

# Global mean temperature per year
log "Global mean temperature (K) per year:"
cdo outputts "$REPORT_DIR/tas_global_mean.nc" 2>/dev/null >> "$LOG_FILE" || \
    log "  (output not available)"

log ""

# --------------------------------------------------
# 2. Process precipitation
# --------------------------------------------------
log "--- Precipitation Processing ---"
cdo selyear,2000/2005 "$PR_FILE" "$REPORT_DIR/pr_subset.nc" 2>/dev/null
cdo yearsum "$REPORT_DIR/pr_subset.nc" "$REPORT_DIR/pr_yearsum.nc" 2>/dev/null
cdo fldmean "$REPORT_DIR/pr_yearsum.nc" "$REPORT_DIR/pr_global_sum.nc" 2>/dev/null

log "Global mean precipitation (mm/year):"
cdo outputts "$REPORT_DIR/pr_global_sum.nc" 2>/dev/null >> "$LOG_FILE" || \
    log "  (output not available)"

log ""

# --------------------------------------------------
# 3. Summary statistics (ASCII table)
# --------------------------------------------------
log "--- Summary Statistics ---"

# Temperature statistics
TAS_MEAN=$(cdo timmean -fldmean "$TAS_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")
TAS_STD=$(cdo timstd -fldmean "$TAS_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")
TAS_MIN=$(cdo timmin -fldmean "$TAS_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")
TAS_MAX=$(cdo timmax -fldmean "$TAS_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")

log "+----------------------------+----------+"
log "| Temperature (K)            | Value    |"
log "+----------------------------+----------+"
log "| Mean                       | $TAS_MEAN |"
log "| Std                        | $TAS_STD  |"
log "| Min                        | $TAS_MIN  |"
log "| Max                        | $TAS_MAX  |"
log "+----------------------------+----------+"
log ""

# Precipitation statistics
PR_MEAN=$(cdo timmean -fldmean "$PR_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")
PR_STD=$(cdo timstd -fldmean "$PR_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")
PR_MIN=$(cdo timmin -fldmean "$PR_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")
PR_MAX=$(cdo timmax -fldmean "$PR_FILE" 2>/dev/null | cdo outputval - 2>/dev/null || echo "N/A")

log "+----------------------------+----------+"
log "| Precipitation (mm/day)     | Value    |"
log "+----------------------------+----------+"
log "| Mean                       | $PR_MEAN  |"
log "| Std                        | $PR_STD   |"
log "| Min                        | $PR_MIN   |"
log "| Max                        | $PR_MAX   |"
log "+----------------------------+----------+"
log ""

# --------------------------------------------------
# 4. Temporal plot via Matplotlib
# --------------------------------------------------
if command -v python3 &>/dev/null; then
    log "--- Generating Plot ---"

    python3 << 'PYEOF'
import warnings
warnings.filterwarnings('ignore')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np

# Temperature time series
try:
    ds = xr.open_dataset('../report/tas_global_mean.nc')
    tas_ts = ds['tas'].values.flatten()
    years = ds['time'].values.astype('datetime64[Y]').astype(int) + 1970
    plt.figure(figsize=(10, 4))
    plt.plot(years, tas_ts, 'r-o', markersize=4)
    plt.xlabel('Year')
    plt.ylabel('Global Mean Temperature (K)')
    plt.title('Global Mean Near-Surface Temperature (2000–2005)')
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig('../report/tas_timeseries.png', dpi=150)
    print('  Saved tas_timeseries.png')
    ds.close()
except Exception as e:
    print(f'  Temperature plot skipped: {e}')

# Precipitation time series
try:
    ds = xr.open_dataset('../report/pr_global_sum.nc')
    pr_ts = ds['pr'].values.flatten()
    years = ds['time'].values.astype('datetime64[Y]').astype(int) + 1970
    plt.figure(figsize=(10, 4))
    plt.bar(years, pr_ts, color='steelblue', width=0.6)
    plt.xlabel('Year')
    plt.ylabel('Global Mean Precipitation (mm/year)')
    plt.title('Global Mean Annual Precipitation (2000–2005)')
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig('../report/pr_timeseries.png', dpi=150)
    print('  Saved pr_timeseries.png')
    ds.close()
except Exception as e:
    print(f'  Precipitation plot skipped: {e}')

print('Plots complete.')
PYEOF

    log "Plots generated in report/ directory."
else
    log "python3 not found – skipping plot generation."
fi

log ""

# --------------------------------------------------
# 5. Generate HTML report
# --------------------------------------------------
log "--- Generating HTML Report ---"

cat > "$REPORT_DIR/report.html" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>CDO Training – Automated Report</title>
<style>
body { font-family: sans-serif; margin: 2em; }
table { border-collapse: collapse; margin: 1em 0; }
th, td { border: 1px solid #ccc; padding: 0.5em 1em; }
th { background: #2c5f8a; color: #fff; }
h1 { color: #2c5f8a; }
h2 { color: #3a7bb5; }
</style>
</head>
<body>
<h1>Climate Data Operators – Automated Report</h1>
<p>Generated: $(date)</p>

<h2>Temperature Statistics</h2>
<table>
<tr><th>Statistic</th><th>Value (K)</th></tr>
<tr><td>Mean</td><td>$TAS_MEAN</td></tr>
<tr><td>Std</td><td>$TAS_STD</td></tr>
<tr><td>Min</td><td>$TAS_MIN</td></tr>
<tr><td>Max</td><td>$TAS_MAX</td></tr>
</table>

<h2>Precipitation Statistics</h2>
<table>
<tr><th>Statistic</th><th>Value (mm/day)</th></tr>
<tr><td>Mean</td><td>$PR_MEAN</td></tr>
<tr><td>Std</td><td>$PR_STD</td></tr>
<tr><td>Min</td><td>$PR_MIN</td></tr>
<tr><td>Max</td><td>$PR_MAX</td></tr>
</table>

<h2>Figures</h2>
<img src="tas_timeseries.png" alt="Temperature time series" style="max-width:100%">
<img src="pr_timeseries.png" alt="Precipitation time series" style="max-width:100%">

<h2>Processing Log</h2>
<pre>$(cat "$LOG_FILE")</pre>
</body>
</html>
HTMLEOF

log "HTML report saved: $REPORT_DIR/report.html"

echo ""
echo "============================================"
echo "  Report generation complete!"
echo "============================================"
echo "Open $REPORT_DIR/report.html in a browser."
echo "Log: $LOG_FILE"
