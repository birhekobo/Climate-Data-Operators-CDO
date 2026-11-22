# Quiz 3: Temporal Analysis

**Instructions:** Choose the best answer for each question.

---

**1. Which operator computes monthly mean values?**
- A) `monthmean`
- B) `monmean`
- C) `timmean`
- D) `ymonmean`

**2. What is the difference between `monmean` and `ymonmean`?**
- A) `monmean` averages over time; `ymonmean` averages over space
- B) `monmean` computes one mean per month; `ymonmean` computes the multi-year average of each calendar month
- C) `monmean` works only with daily data
- D) They are identical

**3. How many time steps does `ymonmean` produce from a 30-year monthly dataset?**
- A) 30
- B) 12
- C) 360
- D) 4

**4. Which operator would you use to compute anomalies by subtracting the monthly climatology?**
- A) `sub`
- B) `ymonsub`
- C) `anomaly`
- D) `diff`

**5. What is a climatology in climate science?**
- A) The study of climate
- B) The average weather conditions over a 30-year period
- C) A forecast model
- D) A type of temperature

**6. Which operator applies a running mean with a window of N time steps?**
- A) `runavg,N`
- B) `runmean,N`
- C) `smooth,N`
- D) `moving,N`

**7. What happens to the time series when a running mean is applied?**
- A) It becomes longer
- B) It becomes shorter by N-1 steps
- C) It stays the same length
- D) It becomes shorter by N steps

**8. How does CDO define seasons in `seasmean`?**
- A) DJF, MAM, JJA, SON
- B) JFM, AMJ, JAS, OND
- C) Jan-Mar, Apr-Jun, Jul-Sep, Oct-Dec
- D) Winter, Spring, Summer, Fall (fixed calendar months)

**9. Which operator would you use to compute annual means?**
- A) `yearmean`
- B) `annualmean`
- C) `ymean`
- D) `timymean`

**10. Why is it important to compute `fldmean` before plotting a time series of global temperature anomalies?**
- A) It converts units to Celsius
- B) It reduces the spatial field to a single value per time step
- C) It removes the seasonal cycle
- D) It detrends the data

---

## Answer Key

| Q | Answer |
|---|--------|
| 1 | B |
| 2 | B |
| 3 | B |
| 4 | B |
| 5 | B |
| 6 | B |
| 7 | B |
| 8 | A |
| 9 | A |
|10 | B |
