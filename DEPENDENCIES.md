# gooddata-ruby

As of August  3, 2015  1:23pm. 85 total

## Summary
* 67 MIT
* 7 Apache 2.0
* 6 ruby
* 3 BSD
* 1 GPL-2
* 1 unknown



## Items


<a name="ZenTest"></a>
### <a href="https://github.com/seattlerb/zentest">ZenTest</a> v4.11.0 (development)
#### ZenTest provides 4 different tools: zentest, unit_diff, autotest, and multiruby

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

ZenTest provides 4 different tools: zentest, unit_diff, autotest, and
multiruby.

zentest scans your target and unit-test code and writes your missing
code based on simple naming rules, enabling XP at a much quicker pace.
zentest only works with Ruby and Minitest or Test::Unit. There is
enough evidence to show that this is still proving useful to users, so
it stays.

unit_diff is a command-line filter to diff expected results from
actual results and allow you to quickly see exactly what is wrong.
Do note that minitest 2.2+ provides an enhanced assert_equal obviating
the need for unit_diff

autotest is a continous testing facility meant to be used during
development. As soon as you save a file, autotest will run the
corresponding dependent tests.

multiruby runs anything you want on multiple versions of ruby. Great
for compatibility checking! Use multiruby_setup to manage your
installed versions.

<a name="addressable"></a>
### <a href="https://github.com/sporkmonger/addressable">addressable</a> v2.3.8
#### URI Implementation

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0</a> whitelisted

Addressable is a replacement for the URI implementation that is part of
Ruby's standard library. It more closely conforms to the relevant RFCs and
adds support for IRIs and URI templates.


<a name="ast"></a>
### <a href="https://whitequark.github.io/ast/">ast</a> v2.0.0
#### A library for working with Abstract Syntax Trees.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A library for working with Abstract Syntax Trees.

<a name="astrolabe"></a>
### <a href="https://github.com/yujinakayama/astrolabe">astrolabe</a> v1.3.0
#### An object-oriented AST extension for Parser

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

An object-oriented AST extension for Parser

<a name="aws-sdk"></a>
### <a href="http://aws.amazon.com/sdkforruby">aws-sdk</a> v1.64.0
#### AWS SDK for Ruby V1

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0</a> whitelisted

Version 1 of the AWS SDK for Ruby. Available as both `aws-sdk` and `aws-sdk-v1`.
Use `aws-sdk-v1` if you want to load v1 and v2 of the Ruby SDK in the same
application.

<a name="aws-sdk-v1"></a>
### <a href="http://aws.amazon.com/sdkforruby">aws-sdk-v1</a> v1.64.0
#### AWS SDK for Ruby V1

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0</a> whitelisted

Version 1 of the AWS SDK for Ruby. Available as both `aws-sdk` and `aws-sdk-v1`.
Use `aws-sdk-v1` if you want to load v1 and v2 of the Ruby SDK in the same
application.

<a name="bundler"></a>
### bundler v1.10.6 (development)
#### 

unknown manually approved

>

><cite>  2015-08-03</cite>



<a name="coderay"></a>
### <a href="http://coderay.rubychan.de">coderay</a> v1.1.0
#### Fast syntax highlighting for selected languages.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Fast and easy syntax highlighting for selected languages, written in Ruby. Comes with RedCloth integration and LOC counter.

<a name="colored"></a>
### colored v
#### 

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted



<a name="colored"></a>
### <a href="http://github.com/defunkt/colored">colored</a> v1.2
#### Add some color to your life.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

  >> puts "this is red".red
 
  >> puts "this is red with a blue background (read: ugly)".red_on_blue

  >> puts "this is red with an underline".red.underline

  >> puts "this is really bold and really blue".bold.blue

  >> logger.debug "hey this is broken!".red_on_yellow     # in rails

  >> puts Color.red "This is red" # but this part is mostly untested


<a name="coveralls"></a>
### <a href="https://coveralls.io">coveralls</a> v0.8.2 (development)
#### A Ruby implementation of the Coveralls API.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A Ruby implementation of the Coveralls API.

<a name="crack"></a>
### <a href="http://github.com/jnunemaker/crack">crack</a> v0.4.2
#### Really simple JSON and XML parsing, ripped from Merb and Rails.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Really simple JSON and XML parsing, ripped from Merb and Rails.

<a name="debase"></a>
### <a href="https://github.com/denofevil/debase">debase</a> v0.1.7 (development)
#### debase is a fast implementation of the standard Ruby debugger debug.rb for Ruby 2.0

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

    debase is a fast implementation of the standard Ruby debugger debug.rb for Ruby 2.0.
    It is implemented by utilizing a new Ruby TracePoint class. The core component
    provides support that front-ends can build on. It provides breakpoint
    handling, bindings for stack frames among other things.


<a name="debase-ruby_core_source"></a>
### <a href="http://github.com/os97673/debase-ruby_core_source">debase-ruby_core_source</a> v0.7.9
#### Provide Ruby core source files

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Provide Ruby core source files for C extensions that need them.

<a name="diff-lcs"></a>
### <a href="http://diff-lcs.rubyforge.org/">diff-lcs</a> v1.2.5
#### Diff::LCS computes the difference between two Enumerable sequences using the McIlroy-Hunt longest common subsequence (LCS) algorithm

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Diff::LCS computes the difference between two Enumerable sequences using the
McIlroy-Hunt longest common subsequence (LCS) algorithm. It includes utilities
to create a simple HTML diff output format and a standard diff-like tool.

This is release 1.2.4, fixing a bug introduced after diff-lcs 1.1.3 that did
not properly prune common sequences at the beginning of a comparison set.
Thanks to Paul Kunysch for fixing this issue.

Coincident with the release of diff-lcs 1.2.3, we reported an issue with
Rubinius in 1.9 mode
({rubinius/rubinius#2268}[https://github.com/rubinius/rubinius/issues/2268]).
We are happy to report that this issue has been resolved.

<a name="diff-lcs"></a>
### diff-lcs v
#### 

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted



<a name="docile"></a>
### <a href="https://ms-ati.github.io/docile/">docile</a> v1.1.5
#### Docile keeps your Ruby DSLs tame and well-behaved

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Docile turns any Ruby object into a DSL. Especially useful with the Builder pattern.

<a name="erubis"></a>
### <a href="http://www.kuwata-lab.com/erubis/">erubis</a> v2.7.0
#### a fast and extensible eRuby implementation which supports multi-language

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

  Erubis is an implementation of eRuby and has the following features:

  * Very fast, almost three times faster than ERB and about 10% faster than eruby.
  * Multi-language support (Ruby/PHP/C/Java/Scheme/Perl/Javascript)
  * Auto escaping support
  * Auto trimming spaces around '<% %>'
  * Embedded pattern changeable (default '<% %>')
  * Enable to handle Processing Instructions (PI) as embedded pattern (ex. '<?rb ... ?>')
  * Context object available and easy to combine eRuby template with YAML datafile
  * Print statement available
  * Easy to extend and customize in subclass
  * Ruby on Rails support


<a name="faraday"></a>
### <a href="https://github.com/lostisland/faraday">faraday</a> v0.9.1
#### HTTP/REST API client library.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted



<a name="faraday_middleware"></a>
### <a href="https://github.com/lostisland/faraday_middleware">faraday_middleware</a> v0.10.0
#### Various middleware for Faraday

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Various middleware for Faraday

<a name="ffi"></a>
### <a href="http://wiki.github.com/ffi/ffi">ffi</a> v1.9.10
#### Ruby FFI

<a href="http://en.wikipedia.org/wiki/BSD_licenses#4-clause_license_.28original_.22BSD_License.22.29">BSD</a> whitelisted

Ruby FFI library

<a name="formatador"></a>
### <a href="http://github.com/geemus/formatador">formatador</a> v0.2.5
#### Ruby STDOUT text formatting

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

STDOUT text formatting

<a name="gli"></a>
### <a href="http://davetron5000.github.com/gli">gli</a> v2.13.1
#### Build command-suite CLI apps that are awesome.

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0</a> whitelisted

Build command-suite CLI apps that are awesome.  Bootstrap your app, add commands, options and documentation while maintaining a well-tested idiomatic command-line app

<a name="gooddata"></a>
### <a href="http://github.com/gooddata/gooddata-ruby">gooddata</a> v0.6.21 (default)
#### A convenient Ruby wrapper around the GoodData RESTful API

<a href="http://en.wikipedia.org/wiki/BSD_licenses#4-clause_license_.28original_.22BSD_License.22.29">BSD</a> whitelisted

Use the GoodData::Client class to integrate GoodData into your own application or use the CLI to work with GoodData directly from the command line.

<a name="guard"></a>
### <a href="http://guardgem.org">guard</a> v2.12.7 (development)
#### Guard keeps an eye on your file modifications

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Guard is a command line tool to easily handle events on file system modifications.

<a name="guard-compat"></a>
### guard-compat v1.2.1
#### Tools for developing Guard compatible plugins

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Helps creating valid Guard plugins and testing them

<a name="guard-rspec"></a>
### <a href="https://rubygems.org/gems/guard-rspec">guard-rspec</a> v4.6.0 (development)
#### Guard gem for RSpec

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Guard::RSpec automatically run your specs (much like autotest).

<a name="hashie"></a>
### <a href="https://github.com/intridea/hashie">hashie</a> v3.4.2
#### Your friendly neighborhood hash library.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Hashie is a collection of classes and mixins that make hashes more powerful.

<a name="highline"></a>
### <a href="https://github.com/JEG2/highline">highline</a> v1.7.2
#### HighLine is a high-level command-line IO library.

<a href="http://www.ruby-lang.org/en/LICENSE.txt">ruby</a> whitelisted

A high-level IO library that provides validation, type conversion, and more for
command-line interfaces. HighLine also includes a complete menu system that can
crank out anything from simple list selection to complete shells with just
minutes of work.


<a name="httparty"></a>
### <a href="http://jnunemaker.github.com/httparty">httparty</a> v0.13.5
#### Makes http fun! Also, makes consuming restful web services dead easy.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Makes http fun! Also, makes consuming restful web services dead easy.

<a name="json"></a>
### <a href="http://flori.github.com/json">json</a> v1.8.3
#### JSON Implementation for Ruby

<a href="http://www.ruby-lang.org/en/LICENSE.txt">ruby</a> whitelisted

This is a JSON implementation as a Ruby extension in C.

<a name="json_pure"></a>
### <a href="http://flori.github.com/json">json_pure</a> v1.8.2
#### JSON Implementation for Ruby

<a href="http://www.ruby-lang.org/en/LICENSE.txt">ruby</a> whitelisted

This is a JSON implementation in pure Ruby.

<a name="license_finder"></a>
### <a href="https://github.com/pivotal/LicenseFinder">license_finder</a> v2.0.4 (development)
#### Audit the OSS licenses of your application's dependencies.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

    LicenseFinder works with your package managers to find
    dependencies, detect the licenses of the packages in them, compare
    those licenses against a user-defined whitelist, and give you an
    actionable exception report.


<a name="listen"></a>
### <a href="https://github.com/guard/listen">listen</a> v3.0.1
#### Listen to file modifications

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

The Listen gem listens to file modifications and notifies you about the changes. Works everywhere!

<a name="lumberjack"></a>
### <a href="http://github.com/bdurand/lumberjack">lumberjack</a> v1.0.9
#### A simple, powerful, and very fast logging utility that can be a drop in replacement for Logger or ActiveSupport::BufferedLogger.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A simple, powerful, and very fast logging utility that can be a drop in replacement for Logger or ActiveSupport::BufferedLogger. Provides support for automatically rolling log files even with multiple processes writing the same log file.

<a name="method_source"></a>
### <a href="http://banisterfiend.wordpress.com">method_source</a> v0.8.2
#### retrieve the sourcecode for a method

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

retrieve the sourcecode for a method

<a name="mime-types"></a>
### mime-types v
#### 

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted



<a name="mime-types"></a>
### <a href="https://github.com/mime-types/ruby-mime-types/">mime-types</a> v2.6.1
#### The mime-types library provides a library and registry for information about MIME content type definitions

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

The mime-types library provides a library and registry for information about
MIME content type definitions. It can be used to determine defined filename
extensions for MIME types, or to use filename extensions to look up the likely
MIME type definitions.

MIME content types are used in MIME-compliant communications, as in e-mail or
HTTP traffic, to indicate the type of content which is transmitted. The
mime-types library provides the ability for detailed information about MIME
entities (provided as an enumerable collection of MIME::Type objects) to be
determined and used. There are many types defined by RFCs and vendors, so the
list is long but by definition incomplete; don't hesitate to add additional
type definitions. MIME type definitions found in mime-types are from RFCs, W3C
recommendations, the {IANA Media Types
registry}[https://www.iana.org/assignments/media-types/media-types.xhtml], and
user contributions. It conforms to RFCs 2045 and 2231.

This is release 2.6 with two new experimental features. The first new feature
is a new default registry storage format that greatly reduces the initial
memory use of the mime-types library. This feature is enabled by requiring
+mime/types/columnar+ instead of +mime/types+ with a small performance cost and
no change in *total* memory use if certain methods are called (see {Columnar
Store}[#columnar-store] for more details). The second new feature is a logger
interface that conforms to the expectations of an ActiveSupport::Logger so that
warnings can be written to an application's log rather than the default
location for +warn+. This interface may be used for other logging purposes in
the future.

mime-types 2.6 is the last planned version of mime-types 2.x, so deprecation
warnings are no longer cached but provided every time the method is called.
mime-types 2.6 supports Ruby 1.9.2 or later.

<a name="mini_portile"></a>
### <a href="http://github.com/flavorjones/mini_portile">mini_portile</a> v0.6.2
#### Simplistic port-like solution for developers

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Simplistic port-like solution for developers. It provides a standard and simplified way to compile against dependency libraries without messing up your system.

<a name="multi_json"></a>
### <a href="http://github.com/intridea/multi_json">multi_json</a> v1.11.2
#### A common interface to multiple JSON libraries.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A common interface to multiple JSON libraries, including Oj, Yajl, the JSON gem (with C-extensions), the pure-Ruby JSON gem, NSJSONSerialization, gson.rb, JrJackson, and OkJson.

<a name="multi_xml"></a>
### <a href="https://github.com/sferik/multi_xml">multi_xml</a> v0.5.5
#### A generic swappable back-end for XML parsing

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Provides swappable XML backends utilizing LibXML, Nokogiri, Ox, or REXML.

<a name="multipart-post"></a>
### <a href="https://github.com/nicksieger/multipart-post">multipart-post</a> v2.0.0
#### A multipart form post accessory for Net::HTTP.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Use with Net::HTTP to do multipart form posts.  IO values that have #content_type, #original_filename, and #local_path will be posted as a binary file.

<a name="nenv"></a>
### <a href="https://github.com/e2/nenv">nenv</a> v0.2.0
#### Convenience wrapper for Ruby's ENV

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Using ENV is like using raw SQL statements in your code. We all know how that ends...

<a name="netrc"></a>
### <a href="https://github.com/geemus/netrc">netrc</a> v0.10.3
#### Library to read and write netrc files.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

This library can read and update netrc files, preserving formatting including comments and whitespace.

<a name="nokogiri"></a>
### <a href="http://nokogiri.org">nokogiri</a> v1.6.6.2
#### Nokogiri (鋸) is an HTML, XML, SAX, and Reader parser

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Nokogiri (鋸) is an HTML, XML, SAX, and Reader parser.  Among Nokogiri's
many features is the ability to search documents via XPath or CSS3 selectors.

XML is like violence - if it doesn’t solve your problems, you are not using
enough of it.

<a name="notiffany"></a>
### notiffany v0.0.6
#### Notifier library (extracted from Guard project)

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Single wrapper for most popular notification libraries

<a name="parseconfig"></a>
### <a href="http://github.com/datafolklabs/ruby-parseconfig/">parseconfig</a> v1.0.6
#### Config File Parser for Standard Unix/Linux Type Config Files

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

ParseConfig provides simple parsing of standard configuration files in the form of 'param = value'.  It also supports nested [group] sections.

<a name="parser"></a>
### <a href="https://github.com/whitequark/parser">parser</a> v2.3.0.pre.2
#### A Ruby parser written in pure Ruby.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A Ruby parser written in pure Ruby.

<a name="pmap"></a>
### pmap v
#### 

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0</a> whitelisted



<a name="pmap"></a>
### <a href="https://github.com/bruceadams/pmap">pmap</a> v1.0.2
#### Add parallel methods into Enumerable: pmap and peach

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0</a> whitelisted

Add parallel methods into Enumerable: pmap and peach

<a name="powerpack"></a>
### <a href="https://github.com/bbatsov/powerpack">powerpack</a> v0.1.1
#### A few useful extensions to core Ruby classes.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A few useful extensions to core Ruby classes.

<a name="pry"></a>
### <a href="http://pry.github.com">pry</a> v0.9.12.6
#### An IRB alternative and runtime developer console

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

An IRB alternative and runtime developer console

<a name="rainbow"></a>
### <a href="https://github.com/sickill/rainbow">rainbow</a> v2.0.0
#### Colorize printed text on ANSI terminals

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Colorize printed text on ANSI terminals

<a name="rake"></a>
### rake v
#### 

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted



<a name="rake"></a>
### rake v10.4.2 (development)
#### This rake is bundled with Ruby

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted



<a name="rake-notes"></a>
### <a href="https://github.com/fgrehm/rake-notes">rake-notes</a> v0.2.0 (development)
#### rake notes task for non-Rails' projects

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

rake notes task for non-Rails' projects

<a name="rb-fsevent"></a>
### <a href="http://rubygems.org/gems/rb-fsevent">rb-fsevent</a> v0.9.5
#### Very simple & usable FSEvents API

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

FSEvents API with Signals catching (without RubyCocoa)

<a name="rb-inotify"></a>
### <a href="http://github.com/nex3/rb-inotify">rb-inotify</a> v0.9.5
#### A Ruby wrapper for Linux's inotify, using FFI

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A Ruby wrapper for Linux's inotify, using FFI

<a name="redcarpet"></a>
### <a href="http://github.com/vmg/redcarpet">redcarpet</a> v3.3.2 (development)
#### Markdown that smells nice

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A fast, safe and extensible Markdown to (X)HTML parser

<a name="rest-client"></a>
### <a href="https://github.com/rest-client/rest-client">rest-client</a> v1.7.3
#### Simple HTTP and REST client for Ruby, inspired by microframework syntax for specifying actions.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A simple HTTP and REST client for Ruby, inspired by the Sinatra microframework style of specifying actions: get, put, post, delete.

<a name="restforce"></a>
### <a href="https://github.com/ejholmes/restforce">restforce</a> v1.5.3
#### A lightweight ruby client for the Salesforce REST api.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A lightweight ruby client for the Salesforce REST api.

<a name="rspec"></a>
### <a href="http://github.com/rspec">rspec</a> v2.99.0 (development)
#### rspec-2.99.0

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

BDD for Ruby

<a name="rspec-core"></a>
### <a href="http://github.com/rspec/rspec-core">rspec-core</a> v2.99.2
#### rspec-core-2.99.2

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

BDD for Ruby. RSpec runner and example groups.

<a name="rspec-expectations"></a>
### <a href="http://github.com/rspec/rspec-expectations">rspec-expectations</a> v2.99.2
#### rspec-expectations-2.99.2

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

rspec expectations (should[_not] and matchers)

<a name="rspec-mocks"></a>
### <a href="http://github.com/rspec/rspec-mocks">rspec-mocks</a> v2.99.4
#### rspec-mocks-2.99.4

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

RSpec's 'test double' framework, with support for stubbing and mocking

<a name="rubocop"></a>
### <a href="http://github.com/bbatsov/rubocop">rubocop</a> v0.32.1 (development)
#### Automatic Ruby code style checking tool.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

    Automatic Ruby code style checking tool.
    Aims to enforce the community-driven Ruby Style Guide.


<a name="ruby-debug-ide"></a>
### <a href="https://github.com/ruby-debug/ruby-debug-ide">ruby-debug-ide</a> v0.4.32 (development)
#### IDE interface for ruby-debug.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

An interface which glues ruby-debug to IDEs like Eclipse (RDT), NetBeans and RubyMine.


<a name="ruby-progressbar"></a>
### <a href="https://github.com/jfelchner/ruby-progressbar">ruby-progressbar</a> v1.7.5
#### Ruby/ProgressBar is a flexible text progress bar library for Ruby.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Ruby/ProgressBar is an extremely flexible text progress bar library for Ruby.
The output can be customized with a flexible formatting system including:
percentage, bars of various formats, elapsed time and estimated time remaining.


<a name="rubyzip"></a>
### rubyzip v
#### 

<a href="http://www.ruby-lang.org/en/LICENSE.txt">ruby</a> whitelisted



<a name="rubyzip"></a>
### <a href="http://github.com/rubyzip/rubyzip">rubyzip</a> v1.1.7
#### rubyzip is a ruby module for reading and writing zip files

<a href="http://www.ruby-lang.org/en/LICENSE.txt">ruby</a> whitelisted



<a name="safe_yaml"></a>
### <a href="https://github.com/dtao/safe_yaml">safe_yaml</a> v1.0.4
#### SameYAML provides an alternative implementation of YAML.load suitable for accepting user input in Ruby applications.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Parse YAML safely

<a name="salesforce_bulk_query"></a>
### <a href="https://github.com/cvengros/salesforce_bulk_query">salesforce_bulk_query</a> v0.2.0
#### Downloading data from Salesforce Bulk API made easy and scalable.

<a href="http://en.wikipedia.org/wiki/BSD_licenses#4-clause_license_.28original_.22BSD_License.22.29">BSD</a> whitelisted

A library for downloading data from Salesforce Bulk API. We only focus on querying, other operations of the API aren't supported. Designed to handle a lot of data.

<a name="shellany"></a>
### shellany v0.0.1
#### Simple, somewhat portable command capturing

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

MRI+JRuby compatible command output capturing

<a name="simplecov"></a>
### <a href="http://github.com/colszowka/simplecov">simplecov</a> v0.10.0 (development)
#### Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Code coverage for Ruby 1.9+ with a powerful configuration library and automatic merging of coverage across test suites

<a name="simplecov-html"></a>
### <a href="https://github.com/colszowka/simplecov-html">simplecov-html</a> v0.10.0
#### Default HTML formatter for SimpleCov code coverage tool for ruby 1.9+

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Default HTML formatter for SimpleCov code coverage tool for ruby 1.9+

<a name="slop"></a>
### <a href="http://github.com/leejarvis/slop">slop</a> v3.6.0
#### Simple Lightweight Option Parsing

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

A simple DSL for gathering options and parsing the command line

<a name="term-ansicolor"></a>
### <a href="http://flori.github.com/term-ansicolor">term-ansicolor</a> v1.3.2
#### Ruby library that colors strings using ANSI escape sequences

GPL-2 whitelisted

This library uses ANSI escape sequences to control the attributes of terminal output

<a name="terminal-table"></a>
### <a href="https://github.com/tj/terminal-table">terminal-table</a> v1.5.2
#### Simple, feature rich ascii table generation library

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted



<a name="thor"></a>
### <a href="http://whatisthor.com/">thor</a> v0.19.1
#### Thor is a toolkit for building powerful command-line interfaces.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

Thor is a toolkit for building powerful command-line interfaces.

<a name="thread_safe"></a>
### <a href="https://github.com/ruby-concurrency/thread_safe">thread_safe</a> v0.3.5
#### A collection of data structures and utilities to make thread-safe programming in Ruby easier

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0</a> whitelisted

Thread-safe collections and utilities for Ruby

<a name="tins"></a>
### <a href="https://github.com/flori/tins">tins</a> v1.5.4
#### Useful stuff.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

All the stuff that isn't good/big enough for a real library.

<a name="webmock"></a>
### <a href="http://github.com/bblimke/webmock">webmock</a> v1.21.0 (development)
#### Library for stubbing HTTP requests in Ruby.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

WebMock allows stubbing HTTP requests and setting expectations on HTTP requests.

<a name="xml-simple"></a>
### <a href="https://github.com/maik/xml-simple">xml-simple</a> v1.1.5
#### A simple API for XML processing.

<a href="http://www.ruby-lang.org/en/LICENSE.txt">ruby</a> whitelisted



<a name="yard"></a>
### <a href="http://yardoc.org">yard</a> v0.8.7.6 (development)
#### Documentation tool for consistent and usable documentation in Ruby.

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted

    YARD is a documentation generation tool for the Ruby programming language.
    It enables the user to generate consistent, usable documentation that can be
    exported to a number of formats very easily, and also supports extending for
    custom Ruby constructs such as custom class level definitions.


<a name="yard-rspec"></a>
### <a href="http://yardoc.org">yard-rspec</a> v0.1 (development)
#### YARD plugin to list RSpec specifications inside documentation

<a href="http://opensource.org/licenses/mit-license">MIT</a> whitelisted


