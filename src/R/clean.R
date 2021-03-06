library(data.table)
library(readr)


## For state labeling -----------------------------------------------------------
state.names <- c("Acre", "Alagoas", "Amapa", "Amazonas", "Bahia", "Ceara",
                 "Distrito Federal","Espirito Santo", "Goias", "Maranhao",
                 "Mato Grosso", "Mato Grosso do Sul", "Minas Gerais", "Para",
                 "Paraiba", "Parana", "Pernambuco", "Piaui", "Rio de Janeiro",
                 "Rio Grande do Norte", "Rio Grande do Sul", "Rondonia",
                 "Roraima", "Santa Catarina", "Sao Paulo", "Sergipe",
                 "Tocantins")
state.codes <- c("12", "27", "16", "13", "29", "23", "53", "32", "52", "21",
                 "51", "50", "31", "15", "25", "41", "26", "22", "33", "24",
                 "43", "11", "14", "42", "35", "28", "17")
uf_translate <- data.table(UF=state.codes,
                           uf_name=factor(state.names, ordered = TRUE))
## ------------------------------------------------------------------------------


getcoldict  <- function(dict.filename){
  # dict.filename  <- paste(pnad.data.path, "Input_PNADC_trimestral.txt", sep="/")

  input.parse <- read_delim(dict.filename, "\n", locale=locale(encoding="ISO-8859-1"), col_names=FALSE, progress=FALSE)$X1

  # Locate variable specification range in Dictionary string
  skip  <- min(grep("input", input.parse))+1
  final  <- max(grep("^;", input.parse)) - 1
  input.select  <- input.parse[skip:final]

  # Use regex to find column description/whether it's numeric/widths
  # (This part of the code is highly idiosyncratic to the dictionary file.)
  col.desc  <- gsub(".*/\\*[[:space:]]*(.*) *\\*/", "\\1",input.select)
  col.numeric  <- !grepl("\\$", input.select)
  input.widths  <- gsub("(.*)[[:space:]]*/\\*.*", "\\1", input.select)
  input.widths  <- gsub("[[:space:]]+", " ", input.widths)
  reasonable.format  <- gsub("\\@([0-9]+)[[:space:]]*([[:alpha:]].*?)[[:space:]]+\\$*([0-9]+)\\.*[[:space:]]*",
                             "\\1;\\2;\\3",
                             input.widths)

  coldict  <- as.data.table(transpose(strsplit(reasonable.format, ";")))
  coldict[, `:=`(V1 = as.integer(V1), V3=as.integer(V3), V4=col.desc, V5=col.numeric)]

  ## Sanity check: do widths and positions make sense taken together?
  coldict[, check := c(diff(V1), NA) == V3]
  if ( !coldict[, all(check, na.rm=TRUE)] ) {
    stop("Something went wrong reading PNAD column dictionary.")
  }
  coldict[, check := NULL]


  # Give meaningful names to `coldict`
  setnames(coldict, paste0("V", 1:5),
           c("Pos", "Name","Width", "Description", "IsNumeric"))
  return(coldict)
}

pnad.get.downloaded <- function(pnad.data.path="./data"){
  ## Parse Data directory for downloaded dataset zip files

  grep.fmt  <- paste("pnad_.*\\.zip", sep="")
  all.downloaded  <- list.files(pnad.data.path, pattern=grep.fmt, full.names = TRUE)

  years  <- gsub(pattern=".*/pnad_(.{4})_.*", "\\1", all.downloaded)
  qtrs  <- gsub(pattern=".*/pnad_.{4}_q(..).*", "\\1", all.downloaded)

  DT <- data.table(
    filename = all.downloaded,
    yr = as.integer(years),
    qtr = as.integer(qtrs)
  )
  DT[, lname := paste(yr, qtr, sep="-")]
  return(DT)
}

pnad.read <- function(pnad.data.path, coldict,
                      startyear, startqtr, endyear, endqtr,
                      label_states="uf_name") {
  all.years <- pnad.get.downloaded(pnad.data.path)[
    lexicompare(yr, qtr, vals=c(startyear, startqtr), binop=`>=`) &
    lexicompare(yr, qtr, vals=c(endyear, endqtr), binop=`<=`)
  ]

  lfulldata  <- lapply(all.years[,filename], pnad.raw.read, 
                       coldict=coldict, label_states=label_states)
  names(lfulldata) <- all.years[, lname]

  return(lfulldata)

}





pnad.raw.read <- function(datazip, coldict, label_states){

  DT <- read_fwf(datazip, fwf_widths(coldict$Width, coldict$Name),
                 col_types = column_specification(coldict),
                 na = c("", "."))
  DT  <- as.data.table(DT)


  if (!is.null(label_states)) {
    DT[uf_translate, uf_name := uf_name, on="UF"]
    setnames(DT, "uf_name", label_states)
  }

  ## cols.convert.numeric  <-  coldict[IsNumeric == TRUE, Name]
  ## for (col in cols.convert.numeric){
  ##   # cat("Doing ", col, "\n")
  ##   DT[, (col) := as.numeric(get(col))]
  ## }

  return(DT)

}

column_specification <- function(coldict){
  ## Auxiliary function that allows us to use `coldict` to specify column types
  ## for `read_fwf`. The output of this function is passed as `col_types` for
  ## `read_fwf`.

  ## We operate with the following convention: whatever is flagged by the IBGE
  ## crew as numeric in the dictionary, we read as numeric. Everything else is
  ## read as a factor (may slow down the reading).

  col_numeric <- coldict[, IsNumeric]

  r <- lapply(col_numeric, function(c) {
    if (c) {
      col_number()
    } else {
      col_factor()
    }
  })

  names(r) <- coldict[,Name]

  col_types = do.call(cols, r)

  return(col_types)
}


