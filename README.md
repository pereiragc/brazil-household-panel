# Brazil Household Panel

**Work in progress.**

*PNAD contínua* is a comprehensive household survey conducted by the [Brazilian Institute of Geography and Statistics (IBGE)](https://www.ibge.gov.br). There are two uncomfortable things about the way IBGE distributes the micro-data of *PNAD Contínua*:

1.  Data are provided in \`fixed width format\`, along with a dictionary that maps column names to start and end positions. The provided dictionary, however, does not work "out of the box" with R
2.  Every quarter, when IBGE releases new PNAD waves, the filenames of *all* previous datasets also change. For example, the files for the 2017 data are named as follows (as of the time I'm writing this README file):
    
        PNADC_012017_20190729.zip
        PNADC_022017_20190729.zip
        PNADC_032017_20190729.zip
        PNADC_042017_20190729.zip

This package seeks to address these two issues. It provides:

-   [X] A shell script for downloading PNAD data in a given range of years
-   [X] An R script for reading the downloaded data into R

See [here](#org8b0220b) for details.

**Comparison with alternatives.**

-   **lodown/adsfree:** Check it out [here](http://asdfree.com/pesquisa-nacional-por-amostra-de-domicilios-continua-pnadc.html). Comparison TBA.
-   **microdadosBrasil:** See [here](https://github.com/lucasmation/microdadosBrasil). Didn't work for me because it requires maintainers to update the package whenever the filename suffix &#x2013; as exemplified above &#x2013; changes. I can't &#x2013; as of Jan 2nd, 2020 &#x2013; get the package to download PNAD in my system.
-   **Data Zoom:** [Link](http://www.econ.puc-rio.br/datazoom/english/index.html). Only works with Stata, therefore I haven't tested that.

## Dependencies

<a id="orgb546c22"></a>

The versions listed below were the ones used in the testing process, not necessarily the oldest compatible version.

| Type   | Dep        | Version |
|------ |---------- |------- |
| System |            |         |
|        | bash       | 5.0.11  |
|        | curl       | 7.67.0  |
|        | sed        | 4.7     |
|        | R          | 3.6.2   |
| R      |            |         |
|        | data.table | 1.12.8  |
|        | readr      | 1.3.1   |

This package was only tested in a Linux system, although it should work on Mac and other Unix based OSs, provided the dependencies are met.

## How to use

<a id="org8b0220b"></a>

1.  Clone the repo. For example, you might run
    
    ```shell
    git clone https://github.com/pereiragc/brazil-household-panel /home/johndoe/PNAD
    ```
    
    if your home folder is `/home/johndoe`. This will set up the repository in `/home/johndoe/PNAD/`.

2.  In a terminal, navigate to the `src/shell` directory, and run
    
    ```shell
    ./pnad_dl.sh -b 2012 -e 2015
    ```
    
    this specifies that years in the 2012-2015 range should be downloaded. For our fictitious user, the output will be in `/home/johndoe/PNAD/data`
    
    The column dictionary is automatically downloaded to the same data directory.
3.  To load the data, edit `run.r`, making sure the variable `proj.path` points to the right directory, and date range is correctly specified. Then simply run an instance of R and `source` `run.r`.
    
    The variable \`list\_dt\` will contain data for the specified range.

## Documentation

### pnad\_dl.sh

Download all *PNAD Contínua* microdata within a specified range of years. All available quarters are downloaded for the specified years.

This shell script is located in `path_to_projroot/src/shell/pnad_dl.sh`.

Notes:

-   You must be in the `src/shell` directory when you execute the script
-   All output is saved to the `data` directory

Options

-   **-b YYYY:** Start year. Defaults to 2012 if `-e` unset; equal to `-e` otherwise
-   **-e YYYY:** End year. Defaults to 2012 if `-b` unset; equal to `-b` otherwise
-   **-d (yes|no|only):** If `yes`, downloads the variable dictionary. If `no`, skip downloading it. If `only`, download only the variable dictionary. Defaults to `yes`.
