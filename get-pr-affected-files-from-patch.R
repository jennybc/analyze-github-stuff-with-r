get_pr_affected_files_from_patch <- function(url) {
  con <- url %>% curl(open = "r")
  on.exit(close(con))
  patch <- con %>% readLines()
  if (length(patch) < 1) {
    ## in honor of https://github.com/hadley/r-pkgs/pull/317
    ## 1 commit but 0 files changed, so no patch file :(
    return(data_frame(file = character(), diffstuff = character()))
  }
  stop  <- grep("file[s]? changed", patch) %>% min() %>% `-`(1)
  start <- grep(            "^---", patch)
  ## in honor of https://github.com/hadley/r-pkgs/pull/108
  ## PR message itself includes the regex "^---" :(
  start <- start[start < stop] %>% max() %>% `+`(1)
  patch[start:stop] %>%
    paste(collapse = "\n") %>%
    paste0("\n") %>% # force read_delim to see as literal data (vs path)
    read_delim(delim = "|", col_names = c("file", "diffstuff"))
}
