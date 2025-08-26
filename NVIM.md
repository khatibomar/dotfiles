# Nvim notes

These are notes that I think they are useful to my workflow in general.

I removed which key plugin cause most of commands I already memorized.
So instead I will put new stuff I learned in nvim and cuts here.

## Editing

- to replace text within a selection, first highlight the text using `v` which
will enters the visual mode, then after that press `:` ( without pressing ESC )
then nvim will insert `:'<,'>` by default, so without a space directly enter
`s/search/replace` this will replace `{search}` with `{replace}`

## Searching

- to grep only within a file append `%` to the end of it.
Example `:grep potato%`

- to grep only specific file type, do `-t{ext}`.
Example `:grep -tgo potato` will search only in `Go` files.
