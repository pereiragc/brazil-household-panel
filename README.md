# Brazil Household Panel

**Work in progress.**

This package downloads and reads the *PNAD Contínua* survey datasets. *PNAD contínua* is conducted by [Brazilian Institute of Geography and Statistics (IBGE)](https://www.ibge.gov.br).

There are two peculiarities about the way IBGE operates:

1.  Data are provided in \`fixed width format\` along with a dictionary mapping start/end positions to column names. The provided dictionary, however, does not work "out of the box" with R
2.  Every quarter, when IBGE releases new PNAD waves, the filenames of *all* previous datasets also change. For example, the files for the 2017 waves are named as follows (as of the writing of this README file):
    
        PNADC_012017_20190729.zip
        PNADC_022017_20190729.zip
        PNADC_032017_20190729.zip
        PNADC_042017_20190729.zip

This package provides:

-   [X] A shell script for downloading PNAD data in a given range of years
-   [ ] An R script for reading the downloaded data into R

See [here](#org970ab78) for details.

This package was only tested in a Linux system, although it should work on Mac and other Unix based OSs, provided the [dependencies](#org6c5617b) are met.

**Comparison with alternatives.**

-   **lodown/adsfree:** Check it out [here](http://asdfree.com/pesquisa-nacional-por-amostra-de-domicilios-continua-pnadc.html). Didn't work for me because it requires maintainers to update the package whenever the filename suffix &#x2013; as exemplified above &#x2013; changes. The package doesn't work as of Jan 1st, 2020.
-   **Datazoom:** [Link](http://www.econ.puc-rio.br/datazoom/english/index.html). Only works with Stata, therefore I haven't tested that.

## Dependencies

<a id="org6c5617b"></a>

| Type   | Dep  | Version (todo) |
|--------|------|----------------|
| System |      |                |
|        | bash |                |
|        | curl |                |
|        | sed  |                |

## How to use

<a id="org970ab78"></a>

1.  Clone the repo.
2.  In a terminal, navigate to the `src/shell` directory, and run
    
    ```sh
    ./pnad_dl.sh -b 2012 -e 2015
    ```
    
    this specifies that years in the 2012-2015 range should be downloaded.
    
    See the documentation section for more information.

## Documentation

### pnad\_dl.sh

Download all *PNAD Contínua* microdata within a specified range of years. All available quarters are downloaded for the specified years.

This shell script is located in `path_to_projroot/src/shell/pnad_dl.sh`.

Notes:

-   You must be in the `src/shell` directory when you execute the script
-   All output is saved to `path_to_projroot/data`

Options

-   **-b YYYY:** Start year. Defaults to 2012 if `-e` unset; equal to `-e` otherwise
-   **-e YYYY:** End year. Defaults to 2012 if `-b` unset; equal to `-b` otherwise
-   **-d (yes|no|only):** If `yes`, downloads the variable dictionary. If `no`, skip downloading it. If `only`, download only the variable dictionary. Defaults to `yes`.
