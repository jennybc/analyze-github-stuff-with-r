library(readr)
library(ggplot2)
library(dplyr)
library(curl)
library(purrr)

pr_df <- read_csv("r-pkgs-pr-affected-files.csv")

## gloss over Rmd vs rmd issues
pr_df <- pr_df %>%
  mutate(pr_files = tolower(pr_files))

## what order do the files / chapters appear in?
con <- curl("https://raw.githubusercontent.com/hadley/r-pkgs/master/book/r-packages.tex")
tex <- readLines(con)
close(con)
chapters <- tex %>%
  grep("^\\\\include", ., value = TRUE) %>%
  strsplit("[{}]") %>%
  map_chr(2) %>%
  paste0(".rmd")

## do all the pr_files appear in chapters?
obs_targets <- pr_df$pr_files %>% unique()
setdiff(obs_targets, chapters)
## no, of course not

## style.rmd seems to have been absorbed into r.rmd
pr_df$pr_files[pr_df$pr_files == "style.rmd"] <- "r.rmd"

## demo.rmd seems to have been absorbed into misc.rmd
pr_df$pr_files[pr_df$pr_files == "demo.rmd"] <- "misc.rmd"

## remaining targets not in chapters are book infrastructure
## let's call them "meta"
meta_files <- c("contribute.rmd", "index.rmd", "book/r-packages.tex",
                "www/highlight.css", "_includes/package-nav.html")
pr_df$pr_files[pr_df$pr_files %in% meta_files] <- "meta"

## one last check
obs_targets <- pr_df$pr_files %>% unique()
setdiff(obs_targets, chapters)

## chapter table suitable for join
ch_df <- data_frame(
  pr_files = c(chapters, "meta"),
  ch_fact = factor(pr_files, levels = rev(pr_files))
  )

foo <- pr_df %>%
  left_join(ch_df)

p <- ggplot(foo, aes(x = ch_fact)) + geom_bar() + coord_flip() +
  xlab("") + ylab("chapter is targetted by this many PRs") +
  annotate("text", x = 9.5, y = 37, label = "R Packages", size = 10)
ggsave("r-pkgs-pr-affected-files-barchart.png")
