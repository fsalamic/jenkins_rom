#!/bin/bash


GITHUB_USER="${GITHUB_USER}"
GITHUB_EMAIL=${GITHUB_EMAIL}

KBUILD_BUILD_USER="${KBUILD_BUILD_USER}"
KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST}"

export oem=${OEM}
export device=${DEVICE}

if [[ "${ROMname}" =~ "LineageOS" ]]; then
ROM="LineageOS"
manifest_url="https://github.com/LineageOS/android"
export rom_vendor_name="lineage"
branch="lineage-16.0"
echo "using LineageOS";
elif [[ "${ROMname}" =~ "CrDroid" ]]; then
ROM="CrDroid"
manifest_url="https://github.com/crdroidandroid/android"
export rom_vendor_name="lineage"
branch="9.0"
echo "using CrDroid";
elif [[ "${ROMname}" =~ "EvoX" ]]; then
ROM="EvoX"
manifest_url="https://github.com/Evolution-X/platform_manifest"
export rom_vendor_name="aosp"
branch="pie"
echo "building EvoX";
elif [[ "${ROMname}" =~ "RR" ]]; then
ROM="RR"
manifest_url="https://github.com/ResurrectionRemix/platform_manifest"
export rom_vendor_name="rr"
branch="pie"
echo "using RR";
elif [[ "${ROMname}" =~ "Havoc" ]]; then
ROM="Havoc"
manifest_url="https://github.com/Havoc-OS/android_manifest"
export rom_vendor_name="havoc"
branch="pie"
echo "building havoc";
elif [[ "${ROMname}" =~ "PE" ]]; then
ROM="PE"
manifest_url="https://github.com/PixelExperience/manifest"
export rom_vendor_name="aosp"
branch="pie"
echo "Building PE";
elif [[ -n "$string" ]]; then
  echo "String is not empty";
fi

telegram -M "Sync Started for ["$ROM"]("$manifest_url")"


release_repo="bluedogerino/symmetrical-broccoli"

timezone="Europe/Sarajevo"

mkdir "$ROM"
cd "$ROM"

git clone https://bluedogerino:"${GITHUB_TOKEN}"@github.com/bluedogerino/google-git-cookies.git >/dev/null  2>&1
if [ -e google-git-cookies ]; then
    cd google-git-cookies
    bash setup_cookies.sh
    cd ../
    rm -rf google-git-cookies
else
    echo "google-git-cookies repo not found on your account, see steps on README"
fi

repo init -u "$manifest_url" -b "$branch" --depth 1 >/dev/null  2>&1
function trim_darwin() {
    cd .repo/manifests
    cat default.xml | grep -v darwin  >temp  && cat temp >default.xml  && rm temp
    git commit -a -m "Magic"
    cd ../
    cat manifest.xml | grep -v darwin  >temp  && cat temp >manifest.xml  && rm temp
    cd ../
}
export outdir="out/target/product/$device"
mkdir .repo/local_manifests -p
wget ${ROOMSERVICE} -O .repo/local_manifests/roomservice.xml
echo "Sync started for "$manifest_url""
SYNC_START=$(date +"%s")
trim_darwin >/dev/null   2>&1
repo sync --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j64 -q 
SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))
if [ -e frameworks/base ]; then
    echo "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    echo "Build Started"
    telegram -M "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds
Build Started: [See Progress]("https://jenkins.turbox.uk/job/${JOB_NAME}/${BUILD_NUMBER}/console")"

    BUILD_START=$(date +"%s")

    . build/envsetup.sh >/dev/null  2>&1
    lunch "$rom_vendor_name"_"$device"-userdebug >/dev/null  2>&1
    mka bacon -j64 | grep "$device"
    BUILD_END=$(date +"%s")
    BUILD_DIFF=$((BUILD_END - BUILD_START))

    export finalzip_path=$(ls "$outdir"/*201*.zip | tail -n -1)
    export finaljson_path=$(ls "$outdir"/*.json | tail -n -1)
    export finaltxt_path=$(ls "$outdir"/*.txt | tail -n -1)
    export finalmd5sum_path=$(ls "$outdir"/*.md5sum | tail -n -1)
    mkdir zip
    cp $finalzip_path $finaltxt_path $finaljson_path $finalmd5sum_path zip
    export final=$(ls "$soutdir"/zip/* ls * | tail -n -8)
    export zip_name=$(echo "$finalzip_path" | sed "s|"$outdir"/||")
    export tag=$( echo "$zip_name" | sed 's|.zip||')
    if [ -e "$finalzip_path" ]; then
        echo "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

        echo "Uploading"

        github-release "$release_repo" "$tag" "master" ""$ROM" for "$device"
Date: $(env TZ="$timezone" date)" "$final"

        echo "Uploaded"

        telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds
Download: ["$zip_name"](https://github.com/"$release_repo"/releases/download/"$tag"/"$zip_name")"

    else
        echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        exit 1
    fi
else
    echo "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    telegram -N -M "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    exit 1
fi
