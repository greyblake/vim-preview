# Preview - Vim plugin for previewing markup files
by Sergey Potapov (aka Blake)


## Intro

Preview plugin is a tool developed to help you to preview markup files such as
.markdown, .rdoc, .textile and .html when you are editing them. It builds
html files and opens them in your browser.


## Supported Formats

The plugin supports the next formats:

* markdown(md, mkd, mkdn, mdown) - depends on `redcarpet` ruby gem
* rdoc - depends on `github-markup` ruby gem
* textile - depends on `RedCloth` ruby gem
* html(htm)
* ronn - depends on `ronn` ruby gem
* reStructuredText(rst) - depends on `RbST` ruby gem and `rst2html` system util


## Dependencies

The plugin requires a builtin ruby interpreter. It means that your Vim
should be compiled with `--enable-rubyinterp` option.
To find out does your Vim have builtin ruby interpreter you can do the next:
    :echo has('ruby')

If output is `1` the ruby interpreter is builtin.

The second thing you should verify is that you have installed all necessary
ruby gems. Please see "Supported Formats" section to find out what gems you need.

For reStructuredText(rst) format except `RbST` ruby gem you also need `rst2html`.
To get `rst2html` util you probably should install `python-docutils` package. Otherwise PreviewRst vim command will show empty html file.


## Installation

To install the plugin just copy `autoload`, `plugin`, `doc` directories into your .vim directory.


## Usage

* \<Leader\>P - will open current file converted to HTML in your browser.

I want to remind that \<Leader\> in most cases is "\\" key.

## Troubleshooting

If you encountered this *err* when you press \<Leader\>P.

    Preview: don't know how to handle .modula2 format

You may add this piece of code to .vimrc

    autocmd BufNewFile,BufRead \*.{md,mdwn,mkd,mkdn,mark\*} set filetype=markdown



## Know bugs

* In some cases vim can do fork if it uses ruby 1.9. To avoid this trouble fork is done via python.

If you found a bug, please report it. Or better send me a pull request:)


## TODO

* Make more unique names for temporary files than just base name ending with `.html`. There should be `vim_preview` prefix, PID of Vim and number of buffer to guarantee avoiding conflicts.
* Add ability to use alternative gems for processing markdown and other formats.
* Handle exception when 'rubygems' is not found.


## Credits

* [Potapov Sergey](https://github.com/greyblake) - main developer
* [Donald Ephraim Curtis](https://github.com/decurtis) - some support for OSX and Safari, fixing bugs
* [Sung Pae](https://github.com/guns) - fixing bugs
* [Steve Francia](https://github.com/spf13) - fixing bugs
* [Rdark](https://github.com/rdark) - support for ronn file format
* [Bertrand Cachet](https://github.com/bcachet) - return RST back
* [Charles-Axel Dein](https://github.com/charlax) - fixing bugs
* [David Arvelo](https://github.com/darvelo) - fixing bugs
* [Kevin Ballard](https://github.com/kballard) - support for Markdown fenced code blocks


## License

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston,
MA 02111-1307 USA
