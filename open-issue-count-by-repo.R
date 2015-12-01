library(gh)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))

ghuser <- "ironholds"

repos <- gh("GET /users/:user/repos", user = ghuser, .limit = Inf)

iss_df <-
  data_frame(
    repo = repos %>% map_chr("name"),
    issue = repo %>%
      map(~ gh(repo = .x, endpoint = "/repos/:user/:repo/issues",
               user = ghuser, .limit = Inf))
    )
str(iss_df, max.level = 1)

iss_df %>%
  mutate(n_open = issue %>% map_int(length)) %>%
  select(-issue) %>%
  filter(n_open > 0) %>%
  arrange(desc(n_open)) %>%
  print(n = nrow(.))
