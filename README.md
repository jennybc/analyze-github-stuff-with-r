How to obtain a bunch of GitHub issues or pull requests with R
==============================================================

I want to make [`purrr`](https://github.com/hadley/purrr) and [`dplyr`](https://github.com/hadley/dplyr) and [`tidyr`](https://github.com/hadley/tidyr) play nicely with each other. How can I use `purrr` for iteration, while still using `dplyr` and `tidyr` to manage the data frame side of of the house?

Three motivating examples, where I marshal data from the GitHub API using the excellent [`gh` package](https://github.com/gaborcsardi/gh):

-   In [STAT 545](http://stat545-ubc.github.io), 10% of the course mark is awarded for engagement. I want to use contributions to the course [Discussion](https://github.com/STAT545-UBC/Discussion/issues) as a primary input here. This is how I fell down this rabbit hole in the first place.
-   Oliver Keyes [tweeted](https://twitter.com/quominus/status/670398322696392705) that he wanted "a script that goes through all my GitHub repositories and generates a list of which ones have open issues". How could I resist this softball? Sure, there are [easier ways to do this](https://twitter.com/millerdl/status/670430991278858240), but why not use R?
-   Jordan Ellenberg, [writing for the Wall Street Journal](http://www.wsj.com/articles/the-summers-most-unread-book-is-1404417569), used Amazon's "Popular Highlights" feature to define the **Hawking Index**:

    > Take the page numbers of a book's five top highlights, average them, and divide by the number of pages in the whole book. The higher the number, the more of the book we're guessing most people are likely to have read.

    I mean, how many people really stick with "A Brief History of Time" to the bitter end? I was reading through Hadley Wickham's [Advanced R](http://adv-r.had.co.nz) when I read Jordan's article and wondered ... how many people read this entire book? Or do they start and sort of fizzle out? So I wanted to look at the distribution of pull requests. Are they evenly distributed throughout the book or do they cluster in the early chapters?

This is a glorified note-to-self. It might be interesting to a few other people. But I presume a lot of experience with R and a full-on embrace of `%>%`, `dplyr`, etc.

-   [Oliver's open issues](#olivers-open-issues)
-   [Pull requests on a repo](#pull-requests-on-a-repo)
-   [Issue threads](#issue-threads)

### Oliver's open issues

Let's start with the easiest task: does have Oliver issues? If so, can we be more specific?

First, load packages. Install `gh` and `purrr` from GitHub, if necessary. `gh` is not on CRAN and `purrr` is under active development; I doubt my code code would work with CRAN version.

``` r
# install_github("gaborcsardi/gh")
# install_github("hadley/purrr")
library(gh)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(purrr))
```

Use `gh()` to retrieve all of Oliver's public GitHub repositories. Use `map_chr()` from `purrr` to extract all elements named `name` from the resulting list. The map functions are much like base `lapply()` or `vapply()`. There is a lot of flexibility around how to specify the function to apply over the input list. Here I use a shortcut: the character vector `"name"` is converted into an extractor function.

``` r
repos <- gh("/users/ironholds/repos", .limit = Inf)
repo_names <- repos %>% 
  map_chr("name")
str(repo_names)
#>  chr [1:48] "arin" "averageimage" "batman" "billund" "ccc" ...
```

Now we retrieve the issues for all of these repositories. Again, we use a map function, in this case to provide vectorization for `gh()`. We use a new shortcut this time: the `~` formula syntax creates an anonymous function on-the-fly, where `.x` stands for "the input".

``` r
issue_list <- repo_names %>% 
  map(~ gh(repo = .x, endpoint = "/repos/ironholds/:repo/issues", .limit = Inf))
```

Finally, we put this in a sorted, tabulated data frame for a decent display of how many open issue there are on each repo. I'm not even bothering with `knitr::kable()` here because these experiments are definitely not about presentation.

``` r
issue_list %>% 
{
  data_frame(repo = repo_names,
             n_open = map_int(., length))
} %>% 
  arrange(desc(n_open)) %>% 
  filter(n_open > 0) %>% 
  print(n = length(repo_names))
#> Source: local data frame [13 x 2]
#> 
#>              repo n_open
#>             (chr)  (int)
#> 1  passbypromised      7
#> 2   distributions      5
#> 3          driver      5
#> 4        practice      3
#> 5        urltools      2
#> 6          primes      1
#> 7         protein      1
#> 8      rgeolocate      1
#> 9            rope      1
#> 10       webreadr      1
#> 11      WikidataR      1
#> 12      WikipediR      1
#> 13            wmf      1
```

Similar code is available as a [gist](https://gist.github.com/jennybc/092938a2e2b5fb7d27c5) and [in this repo](open-issue-count-by-repo.R).

### Pull requests on a repo

*Even though it was [Advanced R](http://adv-r.had.co.nz) that got me thinking about this, I first started playing around with [R Packages](http://r-pkgs.had.co.nz). I plan to do same for Advanced R (or maybe someone else will!), but Advanced R will have to do for now.*

Load packages. Even more this time.

``` r
library(gh)
suppressPackageStartupMessages(library(dplyr))
library(tidyr)
suppressPackageStartupMessages(library(purrr))
library(curl)
suppressPackageStartupMessages(library(readr))
```

Use `gh()` to retrieve all pull requests on [`hadley/r-pkgs`](https://github.com/hadley/r-pkgs).

``` r
owner <- "hadley"
repo <- "r-pkgs"
pr_list <-
  gh("/repos/:owner/:repo/pulls", owner = owner, repo = repo,
     state = "all", .limit = Inf)
length(pr_list)
#> [1] 295
```

Define a little helper function that [won't be necessary forever](https://github.com/hadley/purrr/issues/110), but is useful below when we dig info out of `pr_list`.

``` r
map_chr_hack <- function(.x, .f, ...) {
  map(.x, .f, ...) %>%
    map_if(is.null, ~ NA_character_) %>%
    flatten_chr()
}
```

Use `map_*()` functions to extract and data-frame-ize the potentially useful parts of the pull request list. I'm extracting much more than I ultimately use, which betrays how overly optimistic I was when I started. So far I can't figure out how to use the API to directly compare two commits, but I haven't given up yet.

``` r
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
#> Source: local data frame [295 x 16]
#> 
#>    number       id                                             title
#>     (int)    (int)                                             (chr)
#> 1     327 51398771                `.rda` extension is case sensitive
#> 2     326 48678175          modified git command for deleting branch
#> 3     324 47463575                                  Update tests.rmd
#> 4     323 47457827                                    Update man.rmd
#> 5     322 47344525 slightly modified in the "Binary builds" section.
#> 6     320 43412833                     removed extraneous word "are"
#> 7     319 43271518                                      Fixing typos
#> 8     318 42719902                         Homogenize LaTeX spelling
#> 9     317 42078372          Merge pull request #1 from scw/git-typos
#> 10    316 42037653                        Fix small typos in src.Rmd
#> ..    ...      ...                                               ...
#> Variables not shown: state (chr), user (chr), commits_url (chr), diff_url
#>   (chr), patch_url (chr), merge_commit_sha (chr), pr_HEAD_label (chr),
#>   pr_HEAD_sha (chr), pr_base_label (chr), pr_base_sha (chr), created_at
#>   (date), closed_at (date), merged_at (date).
```

I want to know which files are affected by each PR. If I had all this stuff locally, I would do [something like this](http://stackoverflow.com/questions/1552340/how-to-list-the-file-names-only-that-changed-between-two-commits):

``` shell
git diff --name-only SHA1 SHA2
```

I have to emulate that with the GitHub API It seems the [compare two commits feature](https://developer.github.com/v3/repos/commits/#compare-two-commits) only works for two branches or two tags, but not two arbitrary SHAs. Please enlighten me and answer [this question on StackOverflow](http://stackoverflow.com/questions/26925312/github-api-how-to-compare-2-commits) if you know how to do this.

I'm getting info out of the patch file in a rather icky way, but it works. Here's the helper function I need to run on each pull request. Or, more specifically, on the URL for its patch file.

``` r
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
```

Add a list-column to the data frame of pull requests. It holds one data frame per PR, which itself has one row per modified file. We use `map()` again and also use `dplyr` and `purrr` together here, in order to preserve association between the existing PR info and the modified files. *This takes around 4 minutes for me FYI.*

``` r
pr_df <- pr_df %>%
    mutate(pr_files = patch_url %>% map(jdiff))
```

Sanity check the `pr_files` list-column. Do all these data frames have exactly two variables -- `file` and `diffstuff`? What's the distribution of the number of rows? I expect to see that the vast majority of PRs affect exactly 1 file, because there are lots of typo corrections. Let's also look at one list-column element.

``` r
pr_df$pr_files %>% map(dim) %>% do.call(rbind, .) %>% apply(2, table)
#> [[1]]
#> 
#>   0   1   2   6 
#>   1 285   8   1 
#> 
#> [[2]]
#> 
#>   2 
#> 295
pr_df$pr_files[[69]]
#> Source: local data frame [2 x 2]
#> 
#>          file     diffstuff
#>         (chr)         (chr)
#> 1     man.rmd 10 +++++-----
#> 2 package.rmd        4 ++--
```

Simplify the list-column elements from data frame to character vector. Then use `tidyr::unnest()` to "explode" things, i.e. give each element its own row. Each element here is a file modified in a PR.

``` r
nrow(pr_df)
#> [1] 295
pr_df <- pr_df %>%
  mutate(pr_files = pr_files %>% map("file")) %>%
  unnest(pr_files)
nrow(pr_df)
#> [1] 307
```

Write `pr_df` out to file, omitting lots of the variables I currently have no use for.

``` r
pr_df %>%
  select(number, id, title, state, user, pr_files) %>%
  write_csv("r-pkgs-pr-affected-files.csv")
```

This is the ready-to-analyze data re: are earlier chapters the target of more PRs? See it here: [r-pkgs-pr-affected-files.csv](r-pkgs-pr-affected-files.csv)

The code up til this point can be found in [r-pkgs-pr-affected-files.R](r-pkgs-pr-affected-files.R).

Here's a figure depicting how often each chapter has been the target of a pull request. I'm not adjusting for length of the chapter or anything, so take it with a huge grain of salt. But no obvious evidence that people read and edit the earlier chapters more. We like to make suggestions about Git apparently!.

![](r-pkgs-pr-affected-files-barchart.png)

The script to make the figure is here: [r-pkgs-pr-affected-files-figs.R](r-pkgs-pr-affected-files-figs.R).

### Issue threads

*bring some suitably redacted version of this over*

------------------------------------------------------------------------

Thanks to [`@hadley`](https://github.com/hadley) and [`@lionel-`](https://github.com/lionel-) for patiently answering all of my `purrr` questions. There have been many.

------------------------------------------------------------------------

``` r
devtools::session_info()
#> Session info --------------------------------------------------------------
#>  setting  value                       
#>  version  R version 3.2.2 (2015-08-14)
#>  system   x86_64, darwin13.4.0        
#>  ui       X11                         
#>  language (EN)                        
#>  collate  en_CA.UTF-8                 
#>  tz       America/Vancouver           
#>  date     2015-11-30
#> Packages ------------------------------------------------------------------
#>  package    * version    date       source                       
#>  assertthat   0.1        2013-12-06 CRAN (R 3.2.0)               
#>  curl       * 0.9.3      2015-08-25 CRAN (R 3.2.0)               
#>  DBI          0.3.1      2014-09-24 CRAN (R 3.2.0)               
#>  devtools     1.9.1.9000 2015-11-16 local                        
#>  digest       0.6.8      2014-12-31 CRAN (R 3.2.0)               
#>  dplyr      * 0.4.3.9000 2015-11-24 Github (hadley/dplyr@4f2d7f8)
#>  evaluate     0.8        2015-09-18 CRAN (R 3.2.0)               
#>  formatR      1.2.1      2015-09-18 CRAN (R 3.2.0)               
#>  gh         * 1.0.0      2015-11-27 local                        
#>  htmltools    0.2.6      2014-09-08 CRAN (R 3.2.0)               
#>  httr         1.0.0      2015-06-25 CRAN (R 3.2.0)               
#>  jsonlite     0.9.17     2015-09-06 CRAN (R 3.2.0)               
#>  knitr        1.11.16    2015-11-23 Github (yihui/knitr@6e8ce0c) 
#>  lazyeval     0.1.10     2015-01-02 CRAN (R 3.2.0)               
#>  magrittr     1.5        2014-11-22 CRAN (R 3.2.0)               
#>  memoise      0.2.1      2014-04-22 CRAN (R 3.2.0)               
#>  purrr      * 0.1.0.9000 2015-11-24 Github (hadley/purrr@7d41ee9)
#>  R6           2.1.1      2015-08-19 CRAN (R 3.2.0)               
#>  Rcpp         0.12.2     2015-11-15 CRAN (R 3.2.2)               
#>  readr      * 0.2.2      2015-10-22 CRAN (R 3.2.0)               
#>  rmarkdown    0.8.1      2015-10-10 CRAN (R 3.2.2)               
#>  rstudioapi   0.3.1      2015-04-07 CRAN (R 3.2.0)               
#>  stringi      1.0-1      2015-10-22 CRAN (R 3.2.0)               
#>  stringr      1.0.0      2015-04-30 CRAN (R 3.2.0)               
#>  tidyr      * 0.3.1.9000 2015-11-09 Github (hadley/tidyr@c714c72)
#>  yaml         2.1.13     2014-06-12 CRAN (R 3.2.0)
```
