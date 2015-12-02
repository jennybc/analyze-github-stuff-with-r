library(gh)
suppressPackageStartupMessages(library(dplyr))
library(tidyr)
suppressPackageStartupMessages(library(purrr))
library(readr)

owner <- "STAT545-UBC"
repo <- "Discussion"

issue_list <-
  gh("/repos/:owner/:repo/issues", owner = owner, repo = repo,
     state = "all", since = "2015-09-01T00:00:00Z", .limit = Inf)

length(issue_list) #215
str(issue_list[[100]])

issue_df <- issue_list %>%
{
  data_frame(number = map_int(., "number"),
             id = map_int(., "id"),
             title = map_chr(., "title"),
             state = map_chr(., "state"),
             n_comments = map_int(., "comments"),
             opener = map_chr(., c("user", "login")),
             created_at = map_chr(., "created_at") %>% as.Date())
}

issue_df

## get rid of issues from 2014 run that I closed in early September 2015
## the students involved do not match against this year's course list
issue_df <- issue_df %>%
  filter(created_at >= "2015-09-01T00:00:00Z")
nrow(issue_df)

## issue opening
opens <- issue_df %>%
  select(number, who = opener) %>%
  mutate(i = 0L)
opens
nrow(opens)

## get the comments: option 1
comments <- issue_df %>%
  select(number) %>%
  mutate(res = number %>% map(
    ~ gh(number = .x,
         endpoint = "/repos/:owner/:repo/issues/:number/comments",
         owner = owner, repo = repo, .limit = Inf)))
str(comments, max.level = 1)

comments %>%
  filter(number %in% c(275, 273, 272)) %>%
  select(res) %>%
  walk(str, max.level = 2, give.attr = FALSE)

comments <- comments %>%
#  mutate(who = res %>% at_depth(1, map_chr, c("user", "login"))) %>%
  mutate(who = res %>% map(. %>% map_chr(c("user", "login")))) %>%
  select(-res)
comments %>%
  filter(number %in% c(275, 273, 272))

## sidebar: exploring other ways to wrangle the comments ...

## get the comments: option 2 (from hadley)
## Not sure I like it. It's a bit simpler, but number gets coerced into a
## character, which is inelegant/troubling.
# comments <- issue_df$number %>%
#   map(~ gh(number = .x,
#            endpoint = "/repos/:owner/:repo/issues/:number/comments",
#            owner = owner, repo = repo, .limit = Inf)
#   ) %>%
#   set_names(issue_df$number)
# comments %>%
#   map(. %>% map_chr(c("user", "login"))) %>%
#   map_df(~ data_frame(who = ., i = seq_along(.)), .id = "number")

## get the comments: option 3 (from hadley)
## This almost works:
# issue_df_alt <- issue_df %>% mutate(
#   comments = map(number,
#                  ~ gh(number = .x,
#                       endpoint = "/repos/:owner/:repo/issues/:number/comments",
#                       owner = owner, repo = repo, .limit = Inf))
# )
# issue_df_alt %>%
#   mutate(who = comments %>% map(. %>% map_chr(c("user", "login")))) %>%
#   do(map_df(.$who, ~ data_frame(who = ., i = seq_along(.))))
## but we've lost number :(

## END sidebar

comments <- comments %>%
  unnest(who) %>%
  group_by(number) %>%
  mutate(i = row_number(number)) %>%
  ungroup()

## check that observed number of comments agrees with number stated by API
count_empirical <- comments %>%
  count(number)
count_stated <- issue_df %>%
  select(number, stated = n_comments)
checker <- left_join(count_empirical, count_stated)
with(checker, n == stated) %>% all() # hopefully TRUE

## row bind openers and commenters
opens
comments
atoms <- bind_rows(opens, comments)

## join to issues
finally <- atoms %>%
  left_join(issue_df) %>%
  select(number, id, opener, who, i, everything()) %>%
  arrange(desc(number), i)

finally
#finally %>% View()
finally %>%
  count(who, sort = TRUE)

#write_csv(finally, "stat545-discussion-threads.csv")


## when I was getting the comments the first time
## I was worried about what would come back
## here's a more careful approach
# poss_gh <- possibly(gh, NA_character_)
# comments <- issue_df %>%
#   select(number) %>%
#   mutate(res = number %>% map(
#     ~ poss_gh(number = .x,
#               endpoint = "/repos/:owner/:repo/issues/:number/comments",
#               owner = owner, repo = repo, .limit = Inf)))
# str(comments, max.level = 1)
# comments %>% .$res %>% is.na() %>% any() # hopefully FALSE
