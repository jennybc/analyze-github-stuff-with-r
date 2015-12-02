What have I learned about diffing with GitHub API?

You can't really. Not in general. See main README for more on that. And [this thread on SO](http://stackoverflow.com/questions/26925312/github-api-how-to-compare-2-commits).

If I return to this, here's a bit more info.

Some promising things in the JSON returned for a pull request:

`$patch_url`

  * they look like so: <https://github.com/hadley/r-pkgs/pull/247.patch>
  * I use these currently and go after these bits
  
        ---
         man.rmd     | 10 +++++-----
         package.rmd |  4 ++--
         2 files changed, 7 insertions(+), 7 deletions(-)

`$diff_url`

  * they look like so: <https://github.com/hadley/r-pkgs/pull/247.diff>
  * you could retrieve that file and do regex stuff; you would focus on these bits (patch files seemed better for my purposes):
  
        diff --git a/man.rmd b/man.rmd
        index 1d16b4d..f254c64 100644
        --- a/man.rmd
        +++ b/man.rmd
        @@ -106,7 +106,7 @@ The first documentation workflow is very fast, but it has one limitation: the pr
        diff --git a/package.rmd b/package.rmd
        index 7970aa2..34e86ca 100644
        --- a/package.rmd
        +++ b/package.rmd
        @@ -237,7 +237,7 @@ You can prevent files in the package bundle from being included in the installed

`$merge_commit_sha`

  * this sounds useful but damn if I can tell what it is
  * for the example PR above, it's 35c1b2a1b6c1eb01f760ad1fd3984c2ed2d42e3b

HEAD of pull requesters's PR branch

```
# $head
# $head$label
# [1] "dlukes:master"
# $head$sha
# [1] "c564f2e0be65970e17561686218c82429c183ef4"
```

parent commit (in hadley) that the PR is based on

```
# $base
# $base$label
# [1] "hadley:master"
# $base$sha
# [1] "aa154bf74b890689856a5502282bef8f1a2db376"
```
