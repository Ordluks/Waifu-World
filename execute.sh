#!/usr/bin/env bash

set -e # exit on error
# set -x # echo executed lines

PACK_VERSION="0.1"
GAME_VERSION="1.4.4"

SOURCE_XNB_FOLDER=$HOME/.steam/steam/steamapps/common/Terraria/Content/Images
SOURCE_PNG_FOLDER=source-pngs
CONTENT_FOLDER=Content
EXTRACTED_FOLDER=out/1-extracted
DOWNSCALED_FOLDER=out/2-downscaled
NO_SEPARATORS_FOLDER=out/3-no-seps
MAGNIFIED_FOLDER=out/4-magnified
REFILLED_FOLDER=out/5-refilled
# RELEASE_FOLDER=release
TEXTURE_PACK_FOLDER=out/6-texture-pack
# TARGET_XNB_FOLDER=temp/6-xnb

function extractPngsFromTerraria() {
    echo "calling TExtract $SOURCE_XNB_FOLDER => $EXTRACTED_FOLDER"
    java -jar "tools/TExtract 1.6.0.jar" --outputDirectory $EXTRACTED_FOLDER.temp $SOURCE_XNB_FOLDER
    mv $EXTRACTED_FOLDER.temp/Images $EXTRACTED_FOLDER
    rm -rf $EXTRACTED_FOLDER.temp
}
function moveAdditionalPngs() {
    echo "add PNGs from $SOURCE_PNG_FOLDER => $EXTRACTED_FOLDER"
    cp -r $SOURCE_PNG_FOLDER/* $EXTRACTED_FOLDER
}
function downscalePngs() {
    echo "downscaling images $EXTRACTED_FOLDER => $DOWNSCALED_FOLDER"
    mkdir -p $DOWNSCALED_FOLDER
    mkdir -p $DOWNSCALED_FOLDER/UI
    wine tools/downscale_pngs.exe "$EXTRACTED_FOLDER" "$DOWNSCALED_FOLDER"
    wine tools/downscale_pngs.exe "$EXTRACTED_FOLDER/UI" "$DOWNSCALED_FOLDER/UI"
}
function removeSeparators() {
    echo "removing separators $DOWNSCALED_FOLDER => $NO_SEPARATORS_FOLDER"
    mkdir -p $NO_SEPARATORS_FOLDER
    mkdir -p $NO_SEPARATORS_FOLDER/UI
    python tools/remove_separators.py "$DOWNSCALED_FOLDER" "$NO_SEPARATORS_FOLDER"
    python tools/remove_separators.py "$DOWNSCALED_FOLDER/UI" "$NO_SEPARATORS_FOLDER/UI"
}
function magnifyPngs() {
    echo "magnifying images $NO_SEPARATORS_FOLDER => $MAGNIFIED_FOLDER"
    mkdir -p $MAGNIFIED_FOLDER
    mkdir -p $MAGNIFIED_FOLDER/UI
    mkdir -p $MAGNIFIED_FOLDER/Items
    rsync -ax --delete-after $NO_SEPARATORS_FOLDER/ $MAGNIFIED_FOLDER/Others/
    rsync -ax --delete-after $NO_SEPARATORS_FOLDER/UI/ $MAGNIFIED_FOLDER/UI/
    mv $MAGNIFIED_FOLDER/Others/Item_* $MAGNIFIED_FOLDER/Items/
    rm -rf $MAGNIFIED_FOLDER/Others/UI/
    if [ "$1" = "blend" ]; then
        wine tools/image_filter.exe "XBR" -wrap $MAGNIFIED_FOLDER/Items $MAGNIFIED_FOLDER
        wine tools/image_filter.exe "XBRz" $MAGNIFIED_FOLDER/Others $MAGNIFIED_FOLDER
        wine tools/image_filter.exe "XBRz" $NO_SEPARATORS_FOLDER/UI $MAGNIFIED_FOLDER/UI
    else
        wine tools/image_filter.exe "XBR-NoBlend" -wrap $MAGNIFIED_FOLDER/Items $MAGNIFIED_FOLDER
        wine tools/image_filter.exe "XBR-NoBlend" $MAGNIFIED_FOLDER/Others $MAGNIFIED_FOLDER
        wine tools/image_filter.exe "XBR-NoBlend" $NO_SEPARATORS_FOLDER/UI $MAGNIFIED_FOLDER/UI
    fi
}
function refillMissingPixels() {
    echo "refilling missing pixels in Walls and Tiles $2 => $3"
    mkdir -p $REFILLED_FOLDER
    mkdir -p $REFILLED_FOLDER/UI
    wine tools/refill_missing_pixels.exe $EXTRACTED_FOLDER $MAGNIFIED_FOLDER $REFILLED_FOLDER
    wine tools/refill_missing_pixels.exe $EXTRACTED_FOLDER/UI $MAGNIFIED_FOLDER/UI $REFILLED_FOLDER/UI
}
function pngsToXnbs() {
    echo "converting to XNB's $1 => $2"
    mkdir -p $2
    mkdir -p $2/UI
    wine tools/png_to_xnb.exe $1 $2
    wine tools/png_to_xnb.exe $1/UI $2/UI
}
function createRelease() {
    version=$1
    out_file=Images-$version.zip
    echo "Creating zip file Images-$version.zip with all XNB's"
    mkdir -p $3/Images
    rm -f $out_file
    rsync -ax --delete-after $2/ $3/
    rm -rf $3/Images/Accessories
    rm -rf $3/Images/Armor
    rm -rf $3/Images/Backgrounds
    rm -rf $3/Images/Misc
    rm -rf $3/Images/SplashScreens
    rm -rf $3/Images/TownNPCs
    rm -rf $3/Images/UI/Bestiary
    rm -rf $3/Images/UI/CharCreation
    rm -rf $3/Images/UI/Creative
    rm -rf $3/Images/UI/Minimap
    rm -rf $3/Images/UI/PlayerResourceSets
    rm -rf $3/Images/UI/WorldCreation
    rm -rf $3/Images/UI/WorldGen
    rm -rf $3/Images/UI/Button*
    echo "Enhanced version of the textures of Terraria 1.4.0.2" > $3/README.txt
    echo "" >> $3/README.txt
    echo "Crated by Andras Suller, `date +%F`, $version." >> $3/README.txt
    echo "For more information visit: http://forums.terraria.org/index.php?threads/enhanced-version-of-the-textures-of-terraria-1-3-0-8.39115/" >> $3/README.txt
    cd $3
    zip -r ../$out_file README.txt Images pack.json
    cd ..
}
function createTexturePack() {
    version="v$PACK_VERSION-$GAME_VERSION"
    out_file=WaifuWorld-$version.zip
    echo "Creating zip file $out_file with all PNG's"
    mkdir -p $TEXTURE_PACK_FOLDER/Content/Images
    rm -f $out_file
    rsync -ax --delete-after $REFILLED_FOLDER/ $TEXTURE_PACK_FOLDER/Content/Images/
    rm -rf $TEXTURE_PACK_FOLDER/Content/Images/Backgrounds
    rm -rf $TEXTURE_PACK_FOLDER/Content/Images/Misc
    rm -rf $TEXTURE_PACK_FOLDER/Content/Images/UI/WorldGen
    rm -rf $TEXTURE_PACK_FOLDER/Content/Images/UI/Button*
    cp -r $CONTENT_FOLDER/* $TEXTURE_PACK_FOLDER/Content
    cp pack.json $TEXTURE_PACK_FOLDER
    cp icon.png $TEXTURE_PACK_FOLDER
    echo "Crated by Ordluks based on creation of Andras Suller, `date +%F`, $version." >> $TEXTURE_PACK_FOLDER/README.txt
    echo "Source repo: https://github.com/Ordluks/Waifu-World" >> $TEXTURE_PACK_FOLDER/README.txt
    echo "Original repo: https://github.com/sullerandras/terraria-hd-textures" >> $TEXTURE_PACK_FOLDER/README.txt
    cd $TEXTURE_PACK_FOLDER
    zip -r ../$out_file README.txt Content pack.json icon.png
    cd ..
}
#SOURCE_XNB_FOLDER="/home/andras/Downloads/Terraria_Soft_Pack_1-10-2016"

extractPngsFromTerraria
moveAdditionalPngs
downscalePngs
removeSeparators
magnifyPngs blend
refillMissingPixels
createTexturePack

# downscalePngs $EXTRACTED_FOLDER $DOWNSCALED_FOLDER
# removeSeparators $DOWNSCALED_FOLDER $NO_SEPARATORS_FOLDER
# magnifyPngs $NO_SEPARATORS_FOLDER $MAGNIFIED_FOLDER "blend"
# refillMissingPixels $EXTRACTED_FOLDER $MAGNIFIED_FOLDER $REFILLED_FOLDER
# createTexturePack "v$PACK_VERSION-$GAME_VERSION" $REFILLED_FOLDER $TEXTURE_PACK_FOLDER $CONTENT_FOLDER

# pngsToXnbs $REFILLED_FOLDER $TARGET_XNB_FOLDER
# createRelease "v$PACK_VERSION-$GAME_VERSION" $TARGET_XNB_FOLDER $RELEASE_FOLDER
# createRelease v0.8-noblend-1.3.4.2 $TARGET_XNB_FOLDER $RELEASE_FOLDER
