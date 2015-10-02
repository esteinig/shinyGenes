# shinyGenes

![](https://github.com/esteinig/shinyGenes/blob/master/examples/example_screen.png)

Shiny application for annotating and plotting short gene segments with Prokka, BLAST and genoPlotR. The application is designed for comparison of short gene segments (rather than whole genomes) such as mobile genetic elements, viruses or other interesting genome fragments from prokaryotic organisms.

*Alpha Version: several options in the interface are not wired up, error checks are not properly implemented, plot downloads are not implemented; please use with patience.*

## Run

```
shiny::runGitHub('shinyGenes', 'esteinig')
```

## Input

**Files**

1. **Single** GenBank format from NCBI. This allows for the download of gene segments from GenBank. Files are converted to FASTA for comparison with BLASTN.
2. **Single** FASTA format when annotating with Prokka. This allows for the input of unannotated gene fragments, which are piped and annotated locally with Prokka. Requires a local installation of Prokka.

**Note**

- All file names need to be ordered by the desired final placement of segments in the plot - this can best be achieved by numbering the files in the desired order
- When annotating with Prokka, contig names in the FASTA files must be less than 20 character
- Two or more files must be loaded for plotting with shinyGenes

**Examples**

* `1_SCCmec_IV_M03-68.gbk` , `2_SCCmec_IV_CM11.gbk`, `...`
* `1_SCCmec_IV_M03-68.fasta` , `2_SCCmec_IV_CM11.fasta`, `...`


## Dependencies

**R version > 3.2**

Install packages manually or use `install.R` from within R:

`source(install.R)`

**Packages**:

* shiny
* shinydashboard
* shinyjs
* seqinr
* DT
* genoPlotR

**BLAST**:

Very simple to set up on Ubuntu, head over to NCBI to check the process for Windows OS.

`sudo apt-get install ncbi-blast+`

**Prokka (optional)**:

[Victorian Bioinformatics Consortium](http://www.bioinformatics.net.au/software.prokka.shtml)

Note that if you would like to use the annotation with Prokka, this is only possible on Linux and Mac OS X. For more information and installation guidelines, head over to Torsten Seemann's excellent [GitHub](https://github.com/tseemann/prokka). 

Prokka is very easy to set up, for Ubuntu the only dependency that needed to be installed was BioPerl:

`sudo apt-get install bioperl`

*It seems like there is a clash between RStudio and the system function ability to find programs placed in the user PATH. If you want to use Prokka, please run the application directly from R in the Terminal.*

## Walkthrough

This is a simple tutorial to operate the user interface of shinyGenes. A more detailed manual is in preperation and will be included in the release version.

*Step 1*: Load example files (GenBank) in `Settings` and `Pipeline`.

*Step 2*: Check the annotation box in `Plot`

*Step 3*: Press `Run` in `Pipeline`

*Step 4*: Switch to `Data`. You can change the names and colours of the segments here and select additional options for the plot in `Settings` and `Plot`

*Step 5*: Switch to `Plot` and look at those shiny Genes!

## Issues

...

## Updates

...

## Citations

**Prokka**:

Seemann T. (2014), Prokka: rapid prokaryotic genome annotation, Bioinformatics, 30(14):2068-9. [PMID:24642063](http://www.ncbi.nlm.nih.gov/pubmed/?term=24642063)

**genoPlotR**:

Lionel G., Kultima, J.R. and Andersson, S.E.G (2010): genoPlotR: comparative gene and genome visualization in R. Bioinformatics, 26(18):2334-2335

Please give some love to the brilliant people behind the packages used in this applications, including:

- [Shiny](http://shiny.rstudio.com/)
- [Shiny Dashboards](https://rstudio.github.io/shinydashboard/index.html)
- [Shiny JS](https://github.com/daattali/shinyjs)
- [genoPlotR](http://genoplotr.r-forge.r-project.org/)
