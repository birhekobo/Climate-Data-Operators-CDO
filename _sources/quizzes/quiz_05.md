# Quiz 5: Statistics and Climate Indices

**Instructions:** Choose the best answer for each question.

---

**1. Which operator computes the 90th percentile of a time series at each grid point?**
- A) `fldpctl,90`
- B) `timpctl,90`
- C) `percentile,90`
- D) `tim90`

**2. How many input files does `timpctl` require?**
- A) 1 (the data file)
- B) 2 (data file + min field)
- C) 3 (data file + min field + max field)
- D) 0 (it generates from internal data)

**3. What defines a frost day in climate science (when using daily temperature)?**
- A) Maximum temperature < 0°C
- B) Mean temperature < 0°C
- C) Minimum temperature < 0°C
- D) Any temperature reading < 0°C

**4. Which CDO operator counts consecutive occurrences of a condition?**
- A) `consecutive`
- B) `consects`
- C) `streak`
- D) `runlength`

**5. What is the standard threshold for defining a "wet day" in precipitation indices?**
- A) 0 mm/day
- B) 0.1 mm/day
- C) 1 mm/day
- D) 5 mm/day

**6. Which of the following is NOT a CDO statistical operator?**
- A) `timmean`
- B) `timstd`
- C) `timpctl`
- D) `timregress`

**7. What does CDD stand for in climate indices?**
- A) Climate Data Directory
- B) Consecutive Dry Days
- C) Cumulative Degree Days
- D) Cold Day Duration

**8. Which of the following operators applies a comparison (e.g., "values less than X")?**
- A) `comp`
- B) `lt`
- C) `less`
- D) `threshold`

**9. What does `cdo ge,1.0 input.nc output.nc` do?**
- A) Sets all values ≥ 1.0 to 1.0
- B) Creates a field where value is 1 if input ≥ 1.0, else 0
- C) Removes all values less than 1.0
- D) Computes the geopotential at 1.0 hPa

**10. The standardized precipitation index (SPI) is based on:**
- A) Temperature anomalies
- B) Accumulated precipitation over a given time scale
- C) Wind speed
- D) Pressure differences

---

## Answer Key

| Q | Answer |
|---|--------|
| 1 | B |
| 2 | C |
| 3 | C |
| 4 | B |
| 5 | C |
| 6 | D |
| 7 | B |
| 8 | B |
| 9 | B |
|10 | B |
