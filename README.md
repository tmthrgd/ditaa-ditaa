# ditaa-ditaa

[ditaa](http://ditaa.sourceforge.net/) -- DIagrams Through Ascii Art -- by Stathis Sideris is:

> a small command-line utility written in Java, that can convert diagrams drawn using ascii art ('drawings' that contain characters that resemble lines like | / - ), into proper bitmap graphics.

Which 'is best illustrated by the following example:'

    +--------+   +-------+    +-------+
    |        | --+ ditaa +--> |       |
    |  Text  |   +-------+    |diagram|
    |Document|   |!magic!|    |       |
    |     {d}|   |       |    |       |
    +---+----+   +-------+    +-------+
        :                         ^
        |       Lots of work      |
        +-------------------------+

Which after conversion becomes:

![ditaa image](https://raw.githubusercontent.com/tmthrgd/ditaa-ditaa/master/example-one.png)

> ditaa interprets ascci art as a series of open and closed shapes, but it also uses special markup syntax to increase the possibilities of shapes and symbols that can be rendered.

## Installation

Install the ditaa command-line utility with your favourite package manager, e.g. on Ubuntu: `$ [sudo] apt-get install ditaa`, and place the `ditaa-ditaa.rb` plugin in your sites `_plugins` directory.

## Usage

ditaa-ditaa can be used in several ways, the most explicit way is to use liquid `{% ditaa %}` blocks such as:

### Liquid tags

Liquid `{% ditaa %}` blocks can be used wherever liquid is rendered.

    {% ditaa %}
    /----+  DAAP /-----+-----+ Audio  /--------+
    | PC |<------| RPi | MPD |------->| Stereo |
    +----+       +-----+-----+        +--------+
       |                 ^ ^
       |     ncmpcpp     | | mpdroid /---------+
       +--------=--------+ +----=----| Nexus S |
                                     +---------+
    {% endditaa %}

which generates an image like the following:
![ditaa image](https://raw.githubusercontent.com/tmthrgd/ditaa-ditaa/master/example-two.png)

To maintain backwards compatibility with `jekyll-ditaa` options can be passed in command-line style like `{% ditaa -S -E %}` provided the `trollop` library is installed (`$ [sudo] gem install trollop`). It is preferred that options be passed using flags and attributes such as `{% ditaa round no-separation scale:0.75 %}`. Flags must not use the attribute syntax.

### .ditaa pages

ditaa-ditaa will also process pages with the `.ditaa` extension.

    ---
    permalink: /some/path/image.png
    ditaa:
      round: true
      separation: false
      scale: 2
    ---
    
    /----+  DAAP /-----+-----+ Audio  /--------+
    | PC |<------| RPi | MPD |------->| Stereo |
    +----+       +-----+-----+        +--------+
       |                 ^ ^
       |     ncmpcpp     | | mpdroid /---------+
       +--------=--------+ +----=----| Nexus S |
                                     +---------+

When using the `.ditaa` pages options can be passed through the ditaa front-matter object.

### Code blocks

The final way in which ditaa-ditaa can be used is with code blocks when using the kramdown parser. For example:

        /----+  DAAP /-----+-----+ Audio  /--------+
        | PC |<------| RPi | MPD |------->| Stereo |
        +----+       +-----+-----+        +--------+
           |                 ^ ^
           |     ncmpcpp     | | mpdroid /---------+
           +--------=--------+ +----=----| Nexus S |
                                         +---------+
    {: .ditaa}

This is the suggested method as it degrades the most gracefully outputting the source in `<pre><code>...</code></pre>` tags.

ditaa-ditaa is invoked for code blocks when either the `.ditaa` or `.language-ditaa` classes are added (the latter to allow the simpler <code>``` language \ ... \ ```</code> syntax; although the latter may be removed in future and should not be depended upon). Flags (boolean options) can be specified using either classes, such as `.no-separation` and `.round`, or with IAL attributes with truthy or falsey values, such as `separation="false"` and `round="true"`. Valued options can be specified using IAL attributes, such as `scale="0.5"`.

### Options

ditaa-ditaa allows all relevant options that ditaa itself allows. The supported options (taken from DITAA(1)) are:

    OPTIONS
       -v, --verbose
              Makes ditaa more verbose.
    
       -A, --no-antialias
              Turns anti-aliasing off.
    
       -d, --debug
              Renders the debug grid over the resulting image.
    
       -E, --no-separation
              Prevents the separation of common edges of shapes.
    
       -e ENCODING, --encoding ENCODING
              The encoding of the input file.
    
       -r, --round-corners
              Causes all corners to be rendered as round corners.
    
       -s SCALE, --scale SCALE
              A natural number that determines the size of the rendered image.
              The units are fractions of the default  size  (2.5  renders  1.5
              times bigger than the default).
    
       -S, --no-shadows
              Turns off the drop-shadow effect.
    
       -t TABS, --tabs TABS
              Tabs  are normally interpreted as 8 spaces but it is possible to
              change that using this option. It is not advisable to  use  tabs
              in your diagrams.

The `no-` prefix is not considered to be part of the option name, for instance in a `.ditaa` page shadows are disabled using `shadows: false` and NOT `no-shadows: true`.

The liquid block and kramdown code block methods also permit the following extra options to be specified:

    dirname
        The output path of the rendered image. This may contain %{hash} which will be replaced by a hexadecimal string unquie to the image.
    
    name
        The output filename of the rendered image. This may contain %{hash} which will be replaced by a hexadecimal string unquie to the image.

#### Global Configuration

Global options may be set in your sites `_config.yml` file under the `ditaa:` key. For example:

    ditaa:
      dirname: /assets/images/
      separation: false

The jekyll-ditaa options `ditaa_output_directory:` and `ditaa_debug_mode:` are supported for backwards compatibility.

#### Defaults

The following defaults are enforced:

    :antialias => true,
    :debug => false,
    :separation => true,
    :encoding => "utf-8",
    :round => false,
    :scale => 1.0,
    :shadows => true,
    :tabs => 8,
    :verbose => false,
    :dirname => "/images/ditaa",
    :name => "ditaa-%{hash}.png"

## Future

The plugin will be broken apart into a more standard `lib/ditaa-ditaa/*.rb` layout with a short `require ...` `lib/ditaa-ditaa.rb` entry point. The code will also be more heavily commented in future.

## Acknowledgements

ditaa-ditaa was inspired by [jekyll-ditaa](https://github.com/matze/jekyll-ditaa) by [Matthias Vogelgesang](http://bloerg.net/).

The command-line [ditaa](http://ditaa.sourceforge.net/) utility was written by [Efstathios (Stathis) Sideris](http://www.stathis.co.uk/).

The DITAA(1) manual page was written by David Paleino <dapal@debian.org>, for the Debian project.
