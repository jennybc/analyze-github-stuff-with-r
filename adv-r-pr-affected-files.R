library(gh)
suppressPackageStartupMessages(library(dplyr))
library(tidyr)
suppressPackageStartupMessages(library(purrr))
library(curl)
suppressPackageStartupMessages(library(readr))

source("map-chr-hack.R")
source("get-pr-affected-files-from-patch.R")

owner <- "hadley"
repo <- "adv-r"
pr_list <-
  gh("/repos/:owner/:repo/pulls", owner = owner, repo = repo,
     state = "all", .limit = Inf)
length(pr_list)

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

## this takes a while ....  ~10 mins for me
## using safely() now because I had some disappointing problems
## with connections timing out and losing lots of time/results :(
system.time(
  pr_df <- pr_df %>%
    mutate(pr_files = patch_url %>%
             map(safely(get_pr_affected_files_from_patch)))
)

str(pr_df, max.level = 1)

## deal with the results and errors that safely() leaves behind
str(pr_df$pr_files, max.level = 1)
pr_files_tr <- pr_df$pr_files %>%
  transpose()
str(pr_files_tr, max.level = 1)
pr_files_tr %>% .$result %>% map_lgl(is_null) %>% table()
## all FALSE! good
pr_df$pr_files <- pr_files_tr$result

pr_df$pr_files %>% map(dim) %>% do.call(rbind, .) %>% apply(2, table)
(interesting <- pr_df$pr_files %>% map_int(nrow) %>% `==`(4) %>% which())
pr_df$pr_files[[interesting]]

nrow(pr_df)
pr_df <- pr_df %>%
  mutate(pr_files = pr_files %>% map("file")) %>%
  unnest(pr_files)
nrow(pr_df)

pr_df %>%
  select(number, id, title, state, user, pr_files) %>%
  write_csv("adv-r-pr-affected-files.csv")
