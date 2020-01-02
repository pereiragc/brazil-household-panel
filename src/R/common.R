## ------------------------------------------------------
## Store the  functions that may be used across scripts. |
## ------------------------------------------------------

start.logging <- function(log.path, base.name){
  curr.time <- format(Sys.time(), "%Y%m%d_%H%M%S")
  warn.dircreate  <- F

  if (!dir.exists(log.path)) {
    dir.create(log.path)
    warn.dircreate  <- T
  }

  sink(file=paste(log.path,
                  paste0(base.name, "_run_", curr.time, ".log"),
                  sep = "/"), split=TRUE)

  if(warn.dircreate)
    cat("Log directory ", log.path,
        " didn't exist prior to execution. It was created  now.\n")
}

end.logging <- function(){
    sink()
}


lexicompare  <- function(..., vals, binop = `<=`){
  ## Row-wise lexicographic comparison
  ## For use within data.table.
  ##
  ## Example:
  ## DT <- data.table(c1 = c(3,3,1,3,4), c2 = c(3,2,2,1,1), c3 = c(1,1,-2,3,5))
  ## vals <- c(3,2,1)
  ## DT[, cmp := lexicompare(c1,c2,c3, vals=vals)]

  lcols  <- list(...)

  if (length(lcols) != length(vals))
    stop("[lexicompare] Either too many or too few values.")

  vec.result  <- tie  <- rep(TRUE, length(lcols[[1]]))
  retteb  <- better  <- rep(NA, length(lcols[[1]]))

  for (i in 1:length(lcols)){
    better[tie] <- binop(lcols[[i]][tie], vals[i])
    retteb[tie]  <- binop(vals[i], lcols[[i]][tie])
    tie  <- better & retteb

    vec.result[!tie]  <- better[!tie]

    if(!any(tie)){
      break
    }
  }

  return(vec.result)
}



column.names.verify <- function(list.DT){
  ## Inputs:
  ##   list.DT       :: (list)       :: list with data tables
  ## Outputs:
  ##   name.analysis :: (data.table) :: data table with output of column name analysis


  list.names  <- sapply(list.DT, colnames)
  maximal.name  <- Reduce(union, list.names)


  name.analysis  <- data.table(
    colname = maximal.name
  )

  in.maximal  <- as.data.table(lapply(list.DT,
                                      function(DT) colnames(DT) %in% maximal.name))
  name.analysis  <- cbind(name.analysis, in.maximal)
}
