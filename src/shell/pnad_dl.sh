#!/bin/bash


err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $@" >&2; exit 1;
}

usage() { echo "Usage: $0 [-b YYYY] [-e YYYY] [-d (yes|no|only)]" 1>&2; exit 1; }



while getopts "d:b:e:" opt; do
    case $opt in
        d)
            dic_opt=$OPTARG
            [[ "$dic_opt" == "yes" || "$dic_opt" == "no" ]] || \
                [[ "$dic_opt" == "only" ]] || \
                usage
            ;;
        b)
            year_begin=$OPTARG
            [[ "$year_begin" =~ 20[012][0-9] ]] || usage
            ;;
        e)
            year_end=$OPTARG
            [[ "$year_end" =~ 20[012][0-9] ]] || usage

            # Verify that it makes sense given $year_begin
            [[ "$dic_opt" == "only"  ]] || [[ -z "$year_begin" ]] || \
                [[ $year_begin -le $year_end ]] || \
                err "Please use sensible begin/end dates"
            ;;
        :)
            echo "Option $opt requires an argument." >&2
            exit 1
            ;;
    esac
done

# DEFAULT ARGS  -----------------------------------------------------------------
# For dictionary:
if [[ -z "$dic_opt" ]]; then
   dic_opt=yes
fi

if [[ "$dic_opt" == "only" ]]; then
    [[ -n "$year_begin" ]] && echo "Option -b set with -d only; overriding"
    [[ -n "$year_end" ]] && echo "Option -e set with -d only; overriding"
    year_begin="[doc_only]"
    year_end="[doc_only]"
fi


# For download range:
if [[ -z "$year_begin" ]] && [[ -n "$year_end" ]]; then
    year_begin=$year_end
fi
if [[ -z "$year_end" ]] && [[ -n "$year_begin" ]]; then
    year_end=$year_begin
fi


echo " "
echo "Proceeding to download. Options:"
echo ".. Start year: $year_begin"
echo ".. End year: $year_end"
echo ".. Dictionary: $dic_opt"


# CHECK DIRECTORY ---------------------------------------------------------------

currpath=$(pwd)
currdir=${currpath##*/}
prevdirpath=$(dirname $currpath)
prevdir=${prevdirpath##*/}

if [[ "$currdir" != "shell" || "$prevdir" != "src" ]]; then
    err "Script not being run from \$proj_path/src/shell"
    exit 1
fi

# If non existent, create data & tmp directory
mkdir -p ../../data
mkdir -p .tmp
cd .tmp




# START MAIN PART
base_url="ftp://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/Trimestral/Microdados"
rest_time=2


if [[ "$dic_opt" != "no" ]]; then

    echo " "
    echo "Downloading dictionary..."


    # Try to find dictionary: how many matches?
    lfiles=$(curl -s -l "$base_url/Documentacao/")
    nm=$(echo $lfiles | grep -c "Dicionario_e_input")
    if [[ $nm -eq 0 ]]; then
        # zero matches
        cd ..
        err "Dictionary file not found"
    fi
    if [[ $nm -gt 2 ]]; then
        # more than one match
        echo "WARNING: Multiple dictionary files; downloading first one"
    fi

    dict_file=$(grep -m 1 "Dicionario_e_input" <<<$lfiles)
    curl -# "$base_url/Documentacao/$dict_file" -o "doc.zip"

    doc_contents=$(unzip -ql doc.zip)
    file_check="Input_PNADC_trimestral.txt"

    nm=$(grep -c "$file_check" <<<$doc_contents)
    if [[ $nm -eq 0 ]]; then
        # This means `Input_PNADC_trimestral.txt` doesn't show up in
        # Dicionario_e_input.zip
        cd ..
        err "Input dictionary not found in zip file."
    fi


    # If reach here, everything seems fine, so download and move dictionary.
    unzip -q doc.zip $file_check
    mv $file_check ../../../data
    sleep $rest_time
fi

if [[ "$dic_opt" == "only" ]]; then
   exit 0
fi

echo " "
echo "Starting data download."

this_year=$year_begin
while [[ "$this_year" -ge "$year_begin" && "$this_year" -le "$year_end" ]]; do

    # List files in current year
    lfiles=$(curl -s -l "$base_url/$this_year/" | grep "\.zip$")

    while IFS= read -r f; do

        q=$(echo $f | sed -e "s/PNADC_\(0.\)[0-9]\{4\}.*\.zip$/\1/")
        newname="pnad_${this_year}_q${q}.zip"

        curl -# "$base_url/$this_year/$f" -o \
             "$newname"

        # Move file to adequate place
        mv $newname ../../../data
    done  <<< "$lfiles"

    echo " "
    echo "Year $this_year downloaded."

    sleep $rest_time
    this_year=$((this_year+1))
done

