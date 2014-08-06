" ============================================================================
" File:        preview.vim
" Description: Vim global plugin to preview markup files(markdown,rdoc,textile)
" Author:      Sergey Potapov (aka Blake) <blake131313 AT gmail DOT com>
" Version:     0.8
" Homepage:    http://github.com/greyblake/vim-preview
" License:     GPLv2+ -- look it up.
" Copyright:   Copyright (C) 2010-2011 Sergey Potapov (aka Blake)
"
"              This program is free software; you can redistribute it and/or
"              modify it under the terms of the GNU General Public License as
"              published by the Free Software Foundation; either version 2 of
"              the License, or (at your option) any later version.
"
"              This program is distributed in the hope that it will be useful,
"              but WITHOUT ANY WARRANTY; without even the implied warranty of
"              MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
"              General Public License for more details.
"
"              You should have received a copy of the GNU General Public License
"              along with this program; if not, write to the Free Software
"              Foundation, Inc., 59 Temple Place, Suite 330, Boston,
"              MA 02111-1307 USA
" ============================================================================



" Set default options
" NOTE: +uname+ external call takes the most of the time. Because of this
" definition of defaults was moved to autoload from plugin directory.
if(!exists('g:PreviewBrowsers'))
    if(system("uname") =~ "Darwin")
        let g:PreviewBrowsers    = 'open,safari,firefox,chromium-browser,epiphany,google-chrome,opera'
    else
        let g:PreviewBrowsers    = 'firefox,safari,chromium-browser,epiphany,google-chrome,opera'
    endif
endif
if(!exists('g:PreviewCSSPath'))
    let g:PreviewCSSPath     = expand('<sfile>') . '/../../stylesheets/preview.css'
endif
if(!exists('g:PreviewMarkdownExt'))
    let g:PreviewMarkdownExt = 'markdown,md,mkd,mkdn,mdown'
endif
if(!exists('g:PreviewTextileExt'))
    let g:PreviewTextileExt  = 'textile'
endif
if(!exists('g:PreviewRdocExt'))
    let g:PreviewRdocExt     = 'rdoc'
endif
if(!exists('g:PreviewHtmlExt'))
    let g:PreviewHtmlExt     = 'html,htm,xht,xhtm,xhtml'
endif
if(!exists('g:PreviewRonnExt'))
    let g:PreviewRonnExt     = 'ronn'
endif
if(!exists('g:PreviewRstExt'))
    let g:PreviewRstExt      = 'rst,reStructuredText,restructuredtext'
endif
if(!exists('g:PreviewMarkdownFences'))
    let g:PreviewMarkdownFences = 1
endif



function! s:load()
ruby << END_OF_RUBY
require 'singleton'
require 'tempfile'
require 'tmpdir'
require 'rubygems'
require 'shellwords'

class Preview
  include Singleton

  EXT_OPTIONS = {
    :markdown => "g:PreviewMarkdownExt",
    :textile  => "g:PreviewTextileExt",
    :rdoc     => "g:PreviewRdocExt",
    :ronn     => "g:PreviewRonnExt",
    :html     => "g:PreviewHtmlExt",
    :rst      => "g:PreviewRstExt"
  }

  OPTIONS = {
    :browsers        => "g:PreviewBrowsers",
    :css_path        => "g:PreviewCSSPath",
    :markdown_fences => "g:PreviewMarkdownFences"
  }.merge!(EXT_OPTIONS)

  # defines the options that can be overridden with a buffer-local version
  BUFFER_OPTIONS = [:markdown_fences]

  DEPENDECIES = {
    # :format => {:gem => 'name of gem'  , :require => 'file to require'}
    :markdown => {:gem => 'redcarpet'    , :require => 'redcarpet'      },
    :textile  => {:gem => 'RedCloth'     , :require => 'redcloth'       },
    :rdoc     => {:gem => 'github-markup', :require => 'github/markup'  },
    :ronn     => {:gem => 'ronn'         , :require => 'ronn'           },
    :rst      => {:gem => 'RbST'         , :require => 'rbst'           }
  }

  def show
    update_fnames
    EXT_OPTIONS.keys.each do |opt|
      if has_option(opt) and exts_match?(option(opt).split(','))
        send "show_#{opt}"
        return
      end
    end
    error "don't know how to handle .#{filetype} format"
  rescue Exception => error
    puts "#{error.class}: #{error.message}"
    puts error.backtrace
  end

  def show_markdown
    return unless load_dependencies(:markdown)
    show_with(:browser) do
      exts = { :tables => true, :autolink => true }
      if has_option(:markdown_fences) and option(:markdown_fences).to_i != 0
        exts[:fenced_code_blocks] = true
      end
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensinos = exts)
      wrap_html markdown.render(content)
    end
  end

  def show_html
    show_with(:browser){content}
  end

  def show_rdoc
    return unless load_dependencies(:rdoc)
    show_with(:browser) do
      wrap_html GitHub::Markup::RDoc.new(content).to_html
    end
  end

  def show_textile
    return unless load_dependencies(:textile)
    show_with(:browser) do
      wrap_html RedCloth.new(content).to_html
    end
  end

  # Syntax for Ronn::Document.new is different as it expects (content) to be a file
  # TODO: Work out how to read in a string.

  def show_ronn
    return unless load_dependencies(:ronn)
    show_with(:browser) do
      tmp_file = Tempfile.new(@base_name + ".ronn"){|f| f.write(content)}
      wrap_html Ronn::Document.new(tmp_file.path).to_html
    end
  end

  def show_rst
    return unless load_dependencies(:rst)
    show_with(:browser) do
      wrap_html RbST.new(content).to_html
    end
  end

  private

  # TODO: handle errors when app can't be opened
  def show_with(app_type, ext="html")
    fpath = tmp_write(ext, yield)
    app = get_apps_by_type(app_type).find{|app| which(app.split()[0]) }
    app_path = which(app.split()[0])
    args = app.shellsplit()[1..-1] << fpath
    if app_path
      cmd = "#{app_path} #{args.shelljoin} &"
      VIM.command "call system('#{cmd}')"
      VIM.command "redraw"
    else
      error "any of applications you specified in #{OPTIONS[app_type_to_opt(app_type)]} are not available"
    end
  end

  def which(cmd)
    ENV['PATH'].split(':').each do |dir|
      fpath = File.join(dir, cmd)
      return fpath if File.executable?(fpath)
    end
    false
  end

  def update_fnames
    @filename = VIM::Buffer.current.name || Time.now.to_i.to_s
    @base_name = File.basename(@filename)
    @base_path = @filename.gsub(@base_name, "")
  end

  def get_apps_by_type(type)
    option(app_type_to_opt(type)).split(',')
  end

  def app_type_to_opt(type)
    case type
    when :browser
      :browsers
    else
      raise "Undefined application type #{type}"
    end
  end

  def exts_match?(exts)
    exts.find{|ext| ext.downcase == filetype.downcase}
  end

  def filetype
    update_fnames
    from_option = VIM.evaluate("&filetype")
    from_filename = @filename[/\.([^.]+)$/, 1]
    from_option.nil? ? from_filename : from_option
  end

  def tmp_write(ext, data)
    tmp = File.open(File.join(Dir::tmpdir, [@base_name,ext].join('.')), 'w')
    tmp.write(data)
    tmp.close
    tmp.path
  end

  def content
    text = ""
    VIM::Buffer.current.count.times do |i|
      text += VIM::Buffer.current[i+1] + "\n"
    end
    text
  end

  def error(msg)
    puts("Preview: #{msg}")
  end

  def wrap_html(body)
    <<-END_OF_HTML
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
          <title>#{@base_name}</title>
          #{css_tag}
          #{base_tag}
        </head>
        <body>
          <div id="main-container">
            #{body}
          <div>
        </body>
      </html>
    END_OF_HTML
  end

  def css_tag
  %Q(<link rel="stylesheet" href="#{option(:css_path)}" type="text/css" />)
  end

  def base_tag
    %Q{<base href="file://localhost/#{@base_path}" />}
  end

  def option(name)
    raise "Unknown option #{name.inspect}" unless OPTIONS.keys.include?(name)
    var = OPTIONS[name]
    if BUFFER_OPTIONS.include?(name)
      bvar = "b:" + var[/^g:(.*)$/, 1]
      var = bvar if VIM.evaluate("exists('#{bvar}')") != 0
    end
    VIM.evaluate(var)
  end

  def has_option(name)
    raise "Unknown option #{name.inspect}" unless OPTIONS.keys.include?(name)
    var = OPTIONS[name]
    if BUFFER_OPTIONS.include?(name)
      bvar = "b:" + var[/^g:(.*)$/, 1]
      return true if VIM.evaluate("exists('#{bvar}')") != 0
    end
    VIM.evaluate("exists('#{var}')") != 0
  end

  def load_dependencies(format)
    require DEPENDECIES[format][:require]
    true
  rescue LoadError
    error "To preview #{format} format you need to install #{DEPENDECIES[format][:gem]} gem"
    false
  end

end
END_OF_RUBY
endfunction



function! s:init()
    if(!(exists('s:loaded') && s:loaded))
        call s:load()
        let s:loaded = 1
    endif
endfunction


function! preview#show()
call s:init()
ruby << END_OF_RUBY
    Preview.instance.show
END_OF_RUBY
endfunction

function! preview#show_markdown()
call s:init()
ruby << END_OF_RUBY
    Preview.instance.show_markdown
END_OF_RUBY
endfunction

function! preview#show_textile()
call s:init()
ruby << END_OF_RUBY
    Preview.instance.show_textile
END_OF_RUBY
endfunction

function! preview#show_rdoc()
call s:init()
ruby << END_OF_RUBY
    Preview.instance.show_rdoc
END_OF_RUBY
endfunction

function! preview#show_html()
call s:init()
ruby << END_OF_RUBY
    Preview.instance.show_html
END_OF_RUBY
endfunction

function! preview#show_ronn()
call s:init()
ruby << END_OF_RUBY
    Preview.instance.show_ronn
END_OF_RUBY
endfunction

function! preview#show_rst()
call s:init()
ruby << END_OF_RUBY
    Preview.instance.show_rst
END_OF_RUBY
endfunction
