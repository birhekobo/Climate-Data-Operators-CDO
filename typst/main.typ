#import "template.typ": *

#let book-title = "Climate Data Operators (CDO): Complete Training"
#let book-subtitle = "A Comprehensive Guide to Climate Data Processing, Analysis, and Visualization"
#let book-author = "Birhanu Asmerom, Department of Physics, Wollo University"
#let book-date = "July 2026"

#show: book-template.with(
  title: book-title,
  subtitle: book-subtitle,
  author: book-author,
  date: book-date,
)

= Preface

This book provides a comprehensive training in Climate Data Operators (CDO),
a command-line tool suite for efficient processing and analysis of climate and
NWP model data. The material covers everything from basic installation to
advanced workflows, with hands-on exercises using real climate datasets.

The training is designed for climate scientists, researchers, and students
who work with climate data in NetCDF, GRIB, and other formats. No prior
experience with CDO is required, but basic familiarity with the command line
is assumed.

#pagebreak()

#include "chapters/introduction.typ.gen"

#include "chapters/installation.typ.gen"

#include "chapters/basics.typ.gen"

#include "chapters/operators.typ.gen"

#include "chapters/netcdf.typ.gen"

#include "chapters/grib.typ.gen"

#include "chapters/temporal.typ.gen"

#include "chapters/spatial.typ.gen"

#include "chapters/statistics.typ.gen"

#include "chapters/climate_indices.typ.gen"

#include "chapters/workflows.typ.gen"

#include "chapters/projects.typ.gen"

#include "chapters/references.typ.gen"

#include "chapters/solution_01_intro.typ.gen"

#include "chapters/solution_02_file_ops.typ.gen"

#include "chapters/solution_03_temporal.typ.gen"

#include "chapters/solution_04_spatial.typ.gen"

#include "chapters/solution_05_statistics.typ.gen"
