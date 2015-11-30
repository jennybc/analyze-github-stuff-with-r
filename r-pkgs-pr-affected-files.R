library(gh)
suppressPackageStartupMessages(library(dplyr))
library(tidyr)
suppressPackageStartupMessages(library(purrr))
library(curl)
suppressPackageStartupMessages(library(readr))

owner <- "hadley"
repo <- "r-pkgs"
pr_list <-
  gh("/repos/:owner/:repo/pulls", owner = owner, repo = repo,
     state = "all", .limit = Inf)
length(pr_list)

map_chr_hack <- function(.x, .f, ...) {
  map(.x, .f, ...) %>%
    map_if(is.null, ~ NA_character_) %>%
    flatten_chr()
}

pr_df <- pr_list %>%
{
  data_frame(number = map_int(., "number"),
             id = map_int(., "id"),
             title = map_chr(., "title"),
             state = map_chr(., "state"),
             user = map_chr(., c("user", "login")),
             commits_url = map_chr(., "commits_url"),
             diff_url = map_chr(., "diff_url"),
             patch_url = map_chr(., "patch_url"),
             merge_commit_sha = map_chr_hack(., "merge_commit_sha"),
             pr_HEAD_label = map_chr(., c("head", "label")),
             pr_HEAD_sha = map_chr(., c("head", "sha")),
             pr_base_label = map_chr(., c("base", "label")),
             pr_base_sha = map_chr(., c("base", "sha")),
             created_at = map_chr(., "created_at") %>% as.Date(),
             closed_at = map_chr_hack(., "closed_at") %>% as.Date(),
             merged_at = map_chr_hack(., "merged_at") %>% as.Date())
}
pr_df

jdiff <- function(url) {
  con <- url %>% curl()
  patch <- con %>% readLines()
  close(con)
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

pr_df <- pr_df %>%
  mutate(pr_files = patch_url %>% map(jdiff))

pr_df$pr_files %>% map(dim) %>% do.call(rbind, .) %>% apply(2, table)
pr_df$pr_files[[69]]

nrow(pr_df)
pr_df <- pr_df %>%
  mutate(pr_files = pr_files %>% map("file")) %>%
  unnest(pr_files)
nrow(pr_df)

pr_df %>%
  select(number, id, title, state, user, pr_files) %>%
  write_csv("r-pkgs-pr-affected-files.csv")
