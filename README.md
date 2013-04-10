# Wortsammler

Wortsammler (colloquial German for *collector of words*) is an
environment to maintain doucmentation in markdown and publish it in
various formats for different audiences.

Typical application of Wortsammler is user manuals, software
documentation etc.

Basically Wortsammler comprises of

-   a directory structure for source document sources
-   a manifest file to control the publication process
-   a tool to produce the doucments

Particular features of wortsammler are

-   various output formats
-   support of requirement management
-   generate documents for different audiences based on single sources

Wortsammler is built on top of other open source tools, in particular:

-   pandoc
-   LaTeX

## Installation

    $ gem install wortsammler

In order to use Wortsammler, you need to install the prerequisites:

TODO add prequisites here

## Usage

### initialize a project

    Wortsammler init <folder>

This command generates the proposed directory structure, a first
document manifest and a rake file to do the processing.

### generate document

    rake 

## Contributing

1.  Fork it
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create new Pull Request
