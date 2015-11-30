How to obtain a bunch of GitHub issues or pull requests with R
==============================================================

I want to make [`purrr`](https://github.com/hadley/purrr) and [`dplyr`](https://github.com/hadley/dplyr) and [`tidyr`](https://github.com/hadley/tidyr) play nicely with each other. How can I use `purrr` for iteration, while still using `dplyr` and `tidyr` to manage the data frame side of of the house?

Three motivating examples, where I marshal data from the GitHub API using the excellent [`gh` package](https://github.com/gaborcsardi/gh):

-   In [STAT 545](http://stat545-ubc.github.io), 10% of the course mark is awarded for engagement. I want to use contributions to the course [Discussion](https://github.com/STAT545-UBC/Discussion/issues) as a primary input here. This is how I fell down this rabbit hole in the first place.
-   Oliver Keyes [tweeted](https://twitter.com/quominus/status/670398322696392705) that he wanted "a script that goes through all my GitHub repositories and generates a list of which ones have open issues". How could I resist this softball? Sure, there are [easier ways to do this](https://twitter.com/millerdl/status/670430991278858240), but why not use R?
-   Jordan Ellenberg, [writing for the Wall Street Journal](http://www.wsj.com/articles/the-summers-most-unread-book-is-1404417569), used Amazon's "Popular Highlights" feature to define the **Hawking Index**:

    > Take the page numbers of a book's five top highlights, average them, and divide by the number of pages in the whole book. The higher the number, the more of the book we're guessing most people are likely to have read.

    I mean, how many people really stick with "A Brief History of Time" to the bitter end? I was reading through Hadley Wickham's [Advanced R](http://adv-r.had.co.nz) when I read Jordan's article and wondered ... how many people read this entire book? Or do they start and sort of fizzle out? So I wanted to look at the distribution of pull requests. Are they evenly distributed throughout the book or do they cluster in the early chapters?

This is a glorified note-to-self. It might be interesting a few other people. But I presume a lot of experience with R and a full-on embrace of `%>%`, `dplyr`, etc.

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
```

    ##  chr [1:48] "arin" "averageimage" "batman" "billund" "ccc" ...

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
```

    ## Source: local data frame [13 x 2]
    ## 
    ##              repo n_open
    ##             (chr)  (int)
    ## 1  passbypromised      7
    ## 2   distributions      5
    ## 3          driver      5
    ## 4        practice      3
    ## 5        urltools      2
    ## 6          primes      1
    ## 7         protein      1
    ## 8      rgeolocate      1
    ## 9            rope      1
    ## 10       webreadr      1
    ## 11      WikidataR      1
    ## 12      WikipediR      1
    ## 13            wmf      1

Similar code is available as a [gist](https://gist.github.com/jennybc/092938a2e2b5fb7d27c5) and [in this repo](open-issue-count-by-repo.R).

Thanks to [`@hadley`](https://github.com/hadley) and [`@lionel-`](https://github.com/lionel-) for patiently answering all of my `purrr` questions. There have been many.
