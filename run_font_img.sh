#!/bin/bash

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
# This script shows how to use the font_img.pl tool to generate font images.
# It searches for font files in the $FONTDIR directory, using either a file mask
# provided as a script parameter or the default file mask $FONTNAME_MASK_DEFAULT.
# It generates a set of images for each font file; using font size range defined
# through the $FONTSIZE_MIN and $FONTSIZE_MAX constants.
# It stores the generated images into a directory defined through the $OUTDIR
# constant.
# Extra parameter can be provided through the $FI_ARGS constant.
#
################################################################################

#-------------------------------------------------------------------------------
# Constants

FONTDIR="/usr/share/fonts/truetype"
FONTNAME_MASK_DEFAULT="*FreeMono*"

FONTSIZE_MIN=16
FONTSIZE_MAX=32

OUTDIR="./out"

FI_ARGS=" --cell_grid "
#FI_ARGS=""

#-------------------------------------------------------------------------------
# Main

# Check script parameters
fontname_mask=$1
if [ -z "$fontname_mask" ] ; then
  fontname_mask=$FONTNAME_MASK_DEFAULT
fi

# Prepare a directory for generated font images
if [ ! -d $OUTDIR ] ; then
  mkdir -p $OUTDIR || exit -1;
fi

# Find font files and generate corresponding font images using this font
# and a predefined range of font sizes.
for fontfile in `find $FONTDIR -iname $fontname_mask` ; do
  
  echo "$fontfile"
  
  # font name is name of the font file without a file extension
  fontname=$(basename $fontfile)
  fontname=${fontname%%.*}

  # generate font images for all sizes in the predefined range
  for (( fontsize=$FONTSIZE_MIN; fontsize<=$FONTSIZE_MAX; fontsize++ ))  ; do  
    
    ./font_img.pl \
      $FI_ARGS \
      --fontname $fontname \
      --fontsize $fontsize \
      --outdir $OUTDIR
      
  done

done  

################################################################################
# EOF
################################################################################