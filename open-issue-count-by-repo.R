library(gh)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))

ghuser <- "ironholds"

repos <- gh("GET /users/:user/repos", user = ghuser, .limit = Inf)
repo_names <- repos %>%
  map_chr("name")

issue_list <- repo_names %>%
  map(~ gh(repo = .x, endpoint = "/repos/:user/:repo/issues",
           user = ghuser, .limit = Inf))

issue_list %>%
{
  data_frame(repo = repo_names,
             n_open = map_int(., length))
} %>%
  arrange(desc(n_open)) %>%
  filter(n_open > 0) %>%
  print(n = length(repo_names))
