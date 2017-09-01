#!/bin/sh
CP=/usr/local/bin/gcp
filelist=$(cd override && find . -type f)
for f in ${filelist}; do
    if [ -f "${f}" ]; then
        # override only if checksum expected
        target_sha=$(shasum -a 512 "${f}" | awk '{print $1}')
        override_sha=$(grep "${f}" ${0} | awk '{print $2}')
        if [ "${target_sha}" = "${override_sha}" -o -n "${FORCE}" ]; then
            echo "Overriding existing ${f}"
            (cd override && ${CP} --parents "${f}" ..)
        else
            echo "WARNING!!! Checksum mismatch for ${f}"
        fi
    else
        # file only exists in override
        echo "Applying new ${f}"
        (cd override && ${CP} --parents "${f}" ..)
    fi
done

# override file list with sha512s of files expected to be replaced
# update with shasum -a 512 <file>
#SHA512:./debian/debian9.json 90df71f79da9df902143a678b48d48e53a613fbc39ac3bd08983759f38a4b3627af267d8886bce120a72c5f5c8f43e9e56333414d297292ef50d165982dcf08c
#SHA512:./debian/script/desktop.sh f18f96bb136e48fcd16437f36f75ef76a99b5e8d3386eebc2e947799c7a0a882f286d97ace59e83506b673e772b96bf02aff51c09a135f0e0946bdbb53529f66
#SHA512:./debian/script/vagrant.sh b6d366e2697fe5882e2985a868d3de996832ce47b039c321514829ff12c57f0103da88a3ac2f86704309ad6a5c31b7b6391aa78ab692fd98dfbceac0e62688d8  override/debian/script/vagrant.sh
#SHA512:./windows/floppy/eval-win10x64-enterprise/Autounattend.xml e64ef59f27dd74c670a7e4ce901974cbceba8c61eb2187bb2757e4fda6542543841badbc09f4145143add850e2648a022bd5c2fed816d063f4bfa6999570187c
#SHA512:./windows/script/vmtool.bat 6cd130c9ae50e5afb562ae96cf9e58037fa9de79ae4f2dd1df697577d190ae49dd83befe7ce333535018274fc8239c5a28d5ec7f1880ca899e59381272cc865f
