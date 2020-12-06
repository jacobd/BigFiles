# BigFiles

A CLI written in Swift to traverse a directory and find the largest files

```
~ % BigFiles --help
USAGE: big-files [--verbose] [--human] [--number <number>] [<path>]

ARGUMENTS:
  <path>                  The path to search 

OPTIONS:
  --verbose               Show each file analyzed 
  --human                 human readable format 
  -n, --number <number>   The number of files to display. (default: 10)
  -h, --help              Show help information.
