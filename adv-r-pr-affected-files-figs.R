library(readr)
library(ggplot2)
library(dplyr)
library(curl)
library(purrr)

pr_df <- read_csv("adv-r-pr-affected-files.csv")

## gloss over Rmd vs rmd and case, in general
pr_df <- pr_df %>%
  mutate(pr_files = tolower(pr_files))

## what order do the files / chapters appear in?
con <- curl("https://raw.githubusercontent.com/hadley/adv-r/master/book/advanced-r.tex")
tex <- readLines(con)
close(con)
chapters <- tex %>%
  grep("^\\\\include", ., value = TRUE) %>%
  strsplit("[{}]") %>%
  map_chr(2) %>%
  paste0(".rmd") %>%
  tolower()

## do all the pr_files appear in chapters?
obs_targets <- pr_df$pr_files %>% unique()
setdiff(obs_targets, chapters)
## nooooo, of course not

## these seem to be book instrastructure
## we'll call them "meta"
meta_files <- c("_layouts/default.html", ".travis.yml", "index.rmd",
                "www/highlight.css", "book/tex/environments.tex",
                "extras/redirects.r", "contribute.rmd", "book/advanced-r.tex")
pr_df$pr_files[pr_df$pr_files %in% meta_files] <- "meta"

## assign these to their rmd counterparts
tex_subs <-
  c("book/tex/functional-programming.tex", "environments.tex",
    "book/tex/environments.tex", "book/tex/introduction.tex",
    "book/tex/computing-on-the-language.tex", "book/tex/expressions.tex",
    "book/tex/function-operators.tex", "book/tex/functions.tex")
pr_df$pr_files[pr_df$pr_files %in% tex_subs] <-
  pr_df$pr_files[pr_df$pr_files %in% tex_subs] %>%
  gsub('book/tex/', '', .) %>%
  gsub('\\.tex$', '.rmd', .)

## I think these topics moved to r-pkgs
## https://github.com/hadley/adv-r/blob/master/extras/redirects.R
r_pkgs <- c("documenting-functions.rmd", "documenting-packages.rmd",
            "package-basics.rmd", "namespaces.rmd", "git.rmd", "philosophy.rmd",
            "testing.rmd", "package-development-cycle.rmd", "release.rmd",
            "package-quick-reference.rmd")
pr_df$pr_files[pr_df$pr_files %in% r_pkgs] <- "r-pkgs"

## one-offs and guesses
pr_df$pr_files[pr_df$pr_files == "s4.rmd"] <- "oo-essentials.rmd"
pr_df$pr_files[pr_df$pr_files == "beyond-exception-handling.rmd"] <-
  "exceptions-debugging.rmd"
pr_df$pr_files[pr_df$pr_files %in% c("formulas.rmd",
                                     "special-environments.rmd",
                                     "memory.rmd~")] <- NA_character_
## one last check
obs_targets <- pr_df$pr_files %>% unique()
setdiff(obs_targets, chapters)

## chapter table suitable for join
ch_df <- data_frame(
  pr_files = c(chapters, "meta", "r-pkgs"),
  ch_fact = factor(pr_files, levels = rev(pr_files))
  )

foo <- pr_df %>%
  filter(!is.na(pr_files), pr_files != "r-pkgs") %>%
  left_join(ch_df)

p <- ggplot(foo, aes(x = ch_fact)) + geom_bar() + coord_flip() +
  xlab("") + ylab("chapter is targetted by this many PRs") +
  annotate("text", x = 5, y = 57, label = "Advanced R", size = 10)
p
ggsave("adv-r-pr-affected-files-barchart.png")
