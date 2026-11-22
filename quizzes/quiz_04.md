# Quiz 4: Spatial Analysis

**Instructions:** Choose the best answer for each question.

---

**1. Which operator crops data to a specific longitude/latitude bounding box?**
- A) `crop`
- B) `sellonlatbox`
- C) `region`
- D) `subregion`

**2. What is the main advantage of conservative remapping (`remapcon`)?**
- A) It is the fastest method
- B) It preserves global integrals (e.g., total mass, energy)
- C) It produces the smoothest field
- D) It works only for regular grids

**3. Which interpolation method is best suited for categorical data (e.g., land use, soil type)?**
- A) Bilinear
- B) Conservative
- C) Nearest-neighbor
- D) Bicubic

**4. What does `fldmean` compute?**
- A) The mean over time at each grid point
- B) The area-weighted spatial mean at each time step
- C) The mean of the field between two time steps
- D) The mean of all grid points over all time

**5. How does CDO weight grid cells in `fldmean`?**
- A) Equal weights for all cells
- B) Cosine of latitude weighting
- C) Grid-cell area weighting
- D) No weighting — arithmetic mean

**6. What is the difference between `fldmean` and `fldavg`?**
- A) They are identical
- B) `fldmean` is area-weighted; `fldavg` is arithmetic (unweighted)
- C) `fldavg` is area-weighted; `fldmean` is arithmetic
- D) `fldmean` works on time dimension; `fldavg` on space

**7. Which operator computes the zonal mean (average along a latitude band)?**
- A) `zonmean`
- B) `zonalmean`
- C) `latmean`
- D) `zonestat`

**8. When regridding from a fine grid (1°) to a coarse grid (2°), total number of grid cells:**
- A) Increases by factor of 4
- B) Decreases by factor of 4
- C) Stays the same
- D) Doubles

**9. Which of the following is NOT a CDO remapping operator?**
- A) `remapbil`
- B) `remapcon`
- C) `remapspline`
- D) `remapnn`

**10. What is the purpose of creating a target grid description file for regridding?**
- A) It tells CDO where to save the output
- B) It defines the output grid's resolution and extent
- C) It lists the variables to remap
- D) It is required only for GRIB files

---

## Answer Key

| Q | Answer |
|---|--------|
| 1 | B |
| 2 | B |
| 3 | C |
| 4 | B |
| 5 | B |
| 6 | B |
| 7 | A |
| 8 | B |
| 9 | C |
|10 | B |
