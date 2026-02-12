#!/bin/zsh

# Checking if ImageMagick is installed...
magick_path=$(where magick)

if [[ $magick_path == *"not found"* ]]; then
  echo "Image Magick needs to be installed!"
  echo "You can install it by running 'brew install imagemagick'"
  exit
fi;


# Reading logo file name...
echo "Please insert the image file path: "
IFS=. read file extension

input_file=$(pwd)/${file}.${extension}
output_path=$(pwd)/tmp/${file}

echo "Generating icons..."

mkdir -p $output_path
for size in 16 32 128 256 512; do
  double_size=$((2*$size))

  echo "Generating ${size}x${size}"
  magick $input_file -resize ${size}x${size}\! $output_path/icon_${size}x${size}.png

  echo "Generating ${size}x${size}@2x"
  magick $input_file -resize ${double_size}x${double_size}\! $output_path/icon_${size}x${size}@2x.png
done

echo "Generating iconset..."
mv $output_path ${output_path}.iconset

echo "Generating icns file..."
# iconutil -c icns ${output_path}.iconset -o ${file}.icns

echo "Cleaning..."
# rm -r ./tmp

echo "Done!"