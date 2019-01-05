# Wortsammler

> **plaease note**
> :   this project is not actively maintained. I try to keep it alive in
>     order to fulfil my own needs

Wortsammler (colloquial German for *word collector*) is an environment
to maintain doucmentation in markdown and publish it in various formats
for different audiences. It originated in some project specific hacks
wrapping around [pandoc](http://johnmacfarlane.net/pandoc/). But now I
refactored it since I use it in more than two projects now and think it
might be beneficial for others as well.

Typical application of Wortsammler is user manuals, project documents,
user manuals.

Particular features of wortsammler are

-   various output formats
-   support of requirement management
-   generate documents for different audiences based on single sources
-   support for snippets
-   include parts from other PDF files (only for pdf output yet)

Basically Wortsammler comprises of

-   a directory structure for source document sources
-   a manifest file to control the publication process
    -   involved input files
    -   expected output formats
    -   expected editions
    -   Requirements tracing (upstream / downstream)
-   a command line tool to produce the doucments (`wortsammler`)

Wortsammler is built on top of other open source tools, in particular:

-   pandoc
-   LaTeX
-   ruby and a bunch of gems

I did not invent new markdown syntax to implement the features mentioned
aforehead. In other words, any wortsammler flavored markdown file should
reasonably be processed in standalone pandoc. I implemented particular
patterns which are boiled down to either vanilla pandoc markdown or to
LaTeX / HTML.

The features are based on three appraoches:

1.  particular pattern in existing markdown
2.  embedded HTML/LaTeX
3.  specific syntax in strikethrouh sections (e.g. ~~ED simple~~)

## Installation

    $ gem install wortsammler

In order to use Wortsammler, you need to install the prerequisites:

-   ruby 2.5
-   pandoc 2.5 or above. Note that in this version, ean executable named
    pandoc_2.5 must be in the search path.

-   tex, in particular xelatex 3.1415926-2.4-0.9998

## getting started

### display the options

    wortsammler -h

### process markdown files

    wortsammler -pi readme.md -o.  
       -- generates readme.pdf

    wortsammler -pi readme.md -f pdf:docx:html -o. 
        -- generates readme.pdf, readme.html, readme.docx

    wortsammler -bi readme.md
        -- beautifies readme.md (normalizes the markdown)

    wortsammler -bi .
        -- recursively beautifies all markdown files in the current folder    

### initialize a project

    wortsammler init <folder>

This command generates the proposed directory structure, a first
document manifest and a rake file to do the processing.

The rakefile is in `<folder>/30_Sources/ZSUPP_Tools`

### generate document

    rake -T           -- show all rake tasks
    rake sample       -- format the sample document

## known issues

-   as usual documentation is not complete
-   requirement collection only works via manifest
-   some features (in particular referencing) should use pandoc 1.11
    features
-   HTML and DOCX styling does not work
-   It extends `String`
-   Specific syntax in strikethrough is still processed as one line
    which is not very robust
-   as of now the "framework" is hard to use in other applications
-   pdf_utilities only run on OSX

## future plans

-   improve documentation (it is flying around in German and needs to be
    consolidated, please refer to
    <https://github.com/bwl21/wortsammler/wiki>)
-   support epub

## contributing

1.  play with it
2.  give feedback to <bernhard.weichel@googlemail.com> and/or create
    issues
3.  Fork it
4.  Create your feature branch (`git checkout -b my-new-feature`)
5.  Commit your changes (`git commit -am 'Add some feature'`)
6.  Push to the branch (`git push origin my-new-feature`)
7.  Create new Pull Request

## License

MIT: http://www.opensource.org/licenses/mit-license.php

## thanks to

-   John Mc Farlane for [pandoc](http://johnmacfarlane.net/pandoc/)

## Installation of the required software

### Ruby

Please use Ruby 2.5

-   mac:
    -   installation requirex xcode with the commanline tools
    -   use Ruby Version Manager \[https://rvm.io\]\[\]
    -   rvm install ruby_2.5
    -   might take pretty long depending on what you have on your mac.
    -   after ruby is installed `gem install wortsammler`
-   windows
    -   download von
        [http://rubyinstaller.org/downloads/](https://rubyinstaller.org/downloads/)
    -   development kit installieren
        [DevKit-tdm-32-4.5.2-20111229-1559-sfx.exe](https://github.com/downloads/oneclick/rubyinstaller/DevKit-tdm-32-4.5.2-20111229-1559-sfx.exe)

        you might need this to install gems

### pandoc

-   Download \[http://code.google.com/p/pandoc/downloads/list\]\[\]
-   Homepage <https://pandoc.org/>

### TeX

-   mac: download <http://tug.org/mactex/>

-   windows:

    -   <http://www.exomatik.net/U-Latex/USBTeXEnglish#toc1>
    -   <http://www.miktex.org/2.9/setup>

    Alternatively you can use

    -   [usbtex](http://www.exomatik.net/U-Latex/USBTeXEnglish)
