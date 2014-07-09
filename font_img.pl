#!/usr/bin/perl -w

################################################################################
#
# Copyright (c) 2014 Leos Kafka (leos<dot>kafka<at>gmail<dot>com)
# 
# This file is part of Micro Graphics Toolkit.
# 
# Micro Graphics Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
#
# Name
# font_img.pl - Font Image Generator
#
# Synopsis
# font_img.pl [--width_min <int>] [--width_max <int>]
#             [--height_min <int>] [--height_max <int>]
#             [--char_gap <int>]
#             [--cell_grid]
#             [--fontname <string>] [--fonstsize <int>]
#             [--textfile <string>]
#             [--outdir <string>]
#             [--help]
#
# Description:
# This tool generates a font image for given font and size.
# Character cell dimensions may be specified through arguments.
# The generated font image can be converted to a C file by Font Maker UTFT tool,
# http://www.henningkarlsen.com/electronics/t_make_font_file.php .
#
# Parameters (optional)
#   --width_min <int>   - minimal width of a cell for a single character 
#   --width_max <int>   - maximal width of a cell for a single character
#   --height_min <int>  - minimal height of a cell for a single character
#   --height_max <int>  - maximal height of a cell for a single character
#   --char_gap <int>    - extra space between two characters
#   --cell_grid         - cell boundaries enabled in the image
#   --fontname <string> - font name
#   --fonstsize <int>   - font size
#   --textfile <string> - text to be drawn into the image
#   --outdir <string>   - a directory where the image will be written to
#   --help              - this text
#
# Dependencies
# - Perl Imager library, http://search.cpan.org/~tonyc/Imager-0.99
#
# Versions
# - See history in GitHub
#
################################################################################

use strict;

use Imager;
use Getopt::Long;

#-------------------------------------------------------------------------------
# Constants

# Background colour
my $BG_COLOR      = "#000000";
# Cell boundary colour
my $CB_COLOR      = "#101010";
# Font colour
my $TXT_COLOR     = "#FFFFFF";

my $HELP_MSG      = "\
  font_img.pl - Font Image Generator
  
  font_img.pl [--width_min <int>] [--width_max <int>]
              [--height_min <int>] [--height_max <int>]
              [--char_gap <int>]
              [--cell_grid]
              [--fontname <string>] [--fonstsize <int>]
              [--textfile <string>]
              [--outdir <string>]
              [--help]

  --width_min <int>   - minimal width of a cell for a single character 
  --width_max <int>   - maximal width of a cell for a single character
  --height_min <int>  - minimal height of a cell for a single character
  --height_max <int>  - maximal height of a cell for a single character
  --char_gap <int>    - extra space between two characters
  --cell_grid         - cell boundaries enabled in the image
  --fontname <string> - font name
  --fonstsize <int>   - font size
  --textfile <string> - text to be drawn into the image
  --outdir <string>   - a directory where the image will be written to
  --help              - this help
  ";

# Directory in which the script will search for font files
my $FONT_DIR      = "/usr/share/fonts/truetype";

#-------------------------------------------------------------------------------
# Function Prototypes

sub error($);
sub parse_opt();
sub check_opt($);
sub load_txt_2d($);
sub get_txt_2d_dim($);
sub eval_cell_dim($$);
sub gen_image_str($$);

#-------------------------------------------------------------------------------
# Main

# A reference to a hash that contains both script parameters and variables
# derived from these parameters. If a parameter value is not provided from
# a command line, a default value is used instead.
my $cmd_opt;
# A reference to 2D array of characters that are to be drawn on the image
my $text;
# A reference to the final image
my $img;

# Load script parameters (either user-provided or default values)
if ((not defined ($cmd_opt = parse_opt())) or
    ($cmd_opt -> {help})){
  die $HELP_MSG . "\n";
}

# Check the parameters and evaluate derived variables
if (defined (my $errmsg = check_opt($cmd_opt))) {
  error($errmsg);
}

# Load a text that is to be drawn on the image
$text = load_txt_2d($cmd_opt -> {textfile});

# Evaluate optimal width, height and baseline of the character cell
eval_cell_dim($text, $cmd_opt);

# Draw the text on the image
$img = gen_image_str($text, $cmd_opt);

# Store the image to the PNG file
$img -> write(
  file => $cmd_opt -> {outdir} . "/" . $cmd_opt -> {fontname} . "_" . 
          sprintf("%02d", $cmd_opt -> {fontsize}) . ".png",
  type => "png"
);

#-------------------------------------------------------------------------------
# Common error-reporting routine

sub error($) {
  
  my $msg_r = shift;
  
  die "ERROR : $$msg_r\n";
  
}

#-------------------------------------------------------------------------------
# Auxiliary routines

sub min($$) {
  
  my ($a, $b) = @_;
  
  if ($a < $b) {
    return $a;
  }
  else {
    return $b
  }

}

sub max($$) {
  
  my ($a, $b) = @_;
  
  if ($a > $b) {
    return $a;
  }
  else {
    return $b
  }

}


#-------------------------------------------------------------------------------
# A procedure that load script parameters into a hash

sub parse_opt() {
  
  # Assign default values to all parameters
  my $c_w_min     =  8;
  my $c_w_max     = 24;
  my $c_h_min     =  8;
  my $c_h_max     = 72;
  my $char_gap    =  1;
  my $cell_grid   =  0;
  my $fontname    = "FreeMono";
  my $fontsize    = 24;
  my $textfile    = "data/UTFT_full_font_text.txt";
  my $outdir      = "out";
  my $help        =  0;

  # A hash of all parameters
  my %cmd_opt;
  
  # Update parameters using values provided by a user
  my $getopt_ret = GetOptions (
                     "width_min=i"  => \$c_w_min,
                     "width_max=i"  => \$c_w_max,
                     "height_min=i" => \$c_h_min,
                     "height_max=i" => \$c_h_max,
                     "char_gap=i"   => \$char_gap,
                     "cell_grid"    => \$cell_grid,
                     "fontname=s"   => \$fontname,
                     "fontsize=i"   => \$fontsize,
                     "textfile=s"   => \$textfile,
                     "outdir=s"     => \$outdir,
                     "help"         => \$help
                   );
  
  
  if ( ! $getopt_ret ) {
    return undef;
  }
  
  # Store parameters into a hash for easier further manipulation
  $cmd_opt{width_min}  = $c_w_min;
  $cmd_opt{width_max}  = $c_w_max;
  $cmd_opt{height_min} = $c_h_min;
  $cmd_opt{height_max} = $c_h_max;
  $cmd_opt{char_gap}   = $char_gap;
  $cmd_opt{cell_grid}  = $cell_grid;    
  $cmd_opt{fontname}   = $fontname;
  $cmd_opt{fontsize}   = $fontsize;
  $cmd_opt{textfile}   = $textfile;
  $cmd_opt{outdir}     = $outdir;
  $cmd_opt{help}       = $help;

  return \%cmd_opt;
  
}

#-------------------------------------------------------------------------------
# Basic check of parameter values

sub check_opt($) {
  
  my $cmd_opt = shift;
  
  if ($cmd_opt -> {width_min} % 8) { 
    return \"Parameter width_min is not an integer multiple of 8.";
  }

  if ($cmd_opt -> {width_min} <= 0) {
    return \"Parameter width_min is not bigger than 0";
  }

  if ($cmd_opt -> {width_max} % 8) {
    return \"Parameter width_max is not an integer multiple of 8.";
  }

  if ($cmd_opt -> {width_max} <= 0) {
    return \"Parameter width_max is not bigger than 0.";
  }
  
  if ($cmd_opt -> {height_min} <= 0) {
    return \"Parameter height_min is not bigger than 0.";
  }

  if ($cmd_opt -> {height_max} <= 0) {
    return \"Parameter height_max is not bigger than 0.";
  }
  
  if ( ! -f $cmd_opt -> {textfile} ) {
    return \("Cannot find file '" . $cmd_opt -> {textfile} . "'.");
  }

  if ( ! -d $cmd_opt -> {outdir} ) {
    return \("Cannot use directory '" . $cmd_opt -> {outdir} . "'.");
  }
  
  my $find_ffile_cmd = "find $FONT_DIR -iname " . $cmd_opt -> {fontname} . ".ttf";
  my $find_ffile_ret = `$find_ffile_cmd`;
  my @font_files = split("\n", $find_ffile_ret);
  $cmd_opt -> {fontfile} = $font_files[0];
  if ( ! defined $cmd_opt -> {fontfile} ) {
    return \("Cannot find font file for font '" . $cmd_opt -> {fontname} . "'.");
  }
  
  return undef;
  
}

#-------------------------------------------------------------------------------
# A procedure that loads text file into a 2D array

sub load_txt_2d($) {
  
  my $text_filename = shift;
  
  my @txt;
  
  open(FILE, "<$text_filename") or error(\"Cannot open file '$text_filename'");
  while (my $row = <FILE>) {
    chomp($row);
    my @chars = split("", $row);
    push @txt, \@chars;
  }  
  close(FILE);
  
  return \@txt;
  
}

#-------------------------------------------------------------------------------
# A procedure that returns dimension of 2D array

sub get_txt_2d_dim($) {
  
  my $text    = shift;
  
  my $columns_max = 1;
  
  my $rows = scalar @$text;
  
  for (my $row_i = 0; $row_i < $rows; $row_i++) {
    $columns_max = max($columns_max, scalar(@{$text -> [$row_i]}))
  }

  return($columns_max, $rows);
  
}

#-------------------------------------------------------------------------------
# A procedure that evaluates minimal size of the character cell for selected
# font name and font size

sub eval_cell_dim($$) {
  
  my $text    = shift;
  my $cmd_opt = shift;
  
  my $cell_width = 0;
  my $cell_height = 0;
  
  # Evaluate text array width x height
  my ($text_width_ch, $text_height_ch) = get_txt_2d_dim($text);
  
  my $img_tmp = Imager -> new(
    xsize => $cmd_opt -> {width_max},
    ysize => $cmd_opt -> {height_max},
    bi_level => 1
  );

  my $font = Imager::Font -> new(
    file => $cmd_opt -> {fontfile},
    size => $cmd_opt -> {fontsize},
    color => Imager::Color -> new($TXT_COLOR)
  );
  
  # Try to draw all characters of the 2D text array and evaluate
  # maximal character width and height
  my $char_top   = $cmd_opt -> {height_max};
  my $char_bottom = 0;
  for (my $row_i = 0; $row_i < $text_height_ch; $row_i++) {
    for (my $col_i = 0; $col_i < scalar(@{$text -> [$row_i]}); $col_i++) {
      # left, top, right and bottom boundary
      my ($lb, $tb, $rb, $bb) = $img_tmp -> align_string(
        x => 0,
        y => 0,
        halign => 'left',
        valign => 'start',
        string => $text -> [$row_i] -> [$col_i],
        font => $font
      );
      $cell_width = max($cell_width, $rb);
      $char_top = min($char_top, $tb);
      $char_bottom = max($char_bottom, $bb);
    }
  }
  
  # Evaluate character cell width from maximal character width.
  # It must (a) allow required inter-character gap,
  # (b) be an integer multiple of 7 and (c,d) fall into predefined range
  $cell_width = $cell_width + $cmd_opt -> {char_gap};
  $cell_width = int(($cell_width + 7) / 8) * 8;
  $cell_width = max($cell_width, $cmd_opt -> {width_min});
  $cell_width = min($cell_width, $cmd_opt -> {width_max});
  
  # Evaluate character cell height from maximal character height.
  $cell_height = $char_bottom - $char_top + 1 - 2; # lowered by 2 is still enough
  $cell_height = max($cell_height, $cmd_opt -> {height_min});
  $cell_height = min($cell_height, $cmd_opt -> {height_max});
  
  # Add evaluated numbers into a hash of parameters
  $cmd_opt -> {width}    = $cell_width;
  $cmd_opt -> {height}   = $cell_height;
  $cmd_opt -> {baseline} = - $char_top;
  
}

#-------------------------------------------------------------------------------
# A procedure that draws the text on the image

sub gen_image_str($$) {

  my $text    = shift;
  my $cmd_opt = shift;
  
  my $cell_width = $cmd_opt -> {width};
  my $cell_height = $cmd_opt -> {height};
  
  # Evaluate text array width x height
  my ($text_width_ch, $text_height_ch) = get_txt_2d_dim($text);
  
  # Create a new image
  
  my $img_output = Imager -> new(
    xsize => $text_width_ch * $cell_width,
    ysize => $text_height_ch * $cell_height,
    bi_level => 1
  );

  # Fill the background
  $img_output -> box(
    xmin => 0, ymin => 0,
    xmax => $text_width_ch * $cell_width - 1,
    ymax => $text_height_ch * $cell_height - 1,
    color => Imager::Color -> new($BG_COLOR),
    filled => 1
  );
  
  # Draw a cell grit, if required. Each line cross point [0,0] of the
  # corresponding character cell, i.e. it is upper and left boundary of the cell
  if ($cmd_opt -> {cell_grid}) {
  
    # Horizontal
    for (my $row_i = 0; $row_i < $text_height_ch; $row_i++) {
      $img_output -> line(
        x1 => 0, x2 => $text_width_ch * $cell_width,
        y1 => $row_i * $cell_height, y2 => $row_i * $cell_height,
        color => Imager::Color -> new($CB_COLOR)
      );
    }
    
    # Vertical
    for (my $col_i = 0; $col_i < $text_width_ch; $col_i++) {
      $img_output -> line(
        x1 => $col_i * $cell_width, x2 => $col_i * $cell_width,
        y1 => 0, y2 => $text_height_ch * $cell_height,
        color => Imager::Color -> new($CB_COLOR)
      );
    }
    
  }
  
  # Prepare a font
  my $font = Imager::Font -> new(
    file => $cmd_opt -> {fontfile},
    size => $cmd_opt -> {fontsize},
    color => Imager::Color -> new($TXT_COLOR)
  );

  # Draw all characters of the 2D text array
  for (my $row_i = 0; $row_i < $text_height_ch; $row_i++) {
    for (my $col_i = 0; $col_i < scalar(@{$text -> [$row_i]}); $col_i++) {
      $img_output -> align_string(
        x => $col_i * $cell_width + int($cell_width / 2) + 1,
        y => $row_i * $cell_height + $cmd_opt -> {baseline},
        halign => 'center',
        valign => 'start',
        string => $text -> [$row_i] -> [$col_i],
        font => $font
      );
    }
  }

  # Return the final image
  return $img_output;

}

################################################################################
# EOF
################################################################################

