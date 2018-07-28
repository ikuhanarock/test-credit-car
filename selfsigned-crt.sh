#!/usr/bin/env bash

#/ Usage: selfsigned-crt <domain...>
#/
#/ Generate self-signed SSL certificate.
#/
#/ Options:
#/   -h        Show help.
#/   -v        Print version.
#/   -o DIR    Specify the output directory.
#/
#/ Example:
#/   selfsigned-crt foo.bar.10.0.0.1.xip.io
#/   selfsigned-crt hoge.10.0.0.1.xip.io foo.bar.10.0.0.1.xip.io
#/
#/ Description:
#/   Copyright (c) Kohki Makimoto <kohki.makimoto@gmail.com>
#/   The MIT License (MIT)
#/
set -eu

progname=$(basename $0)
progversion="0.1.0"

if [ "${TERM:-dumb}" != "dumb" ]; then
    txtunderline=$(tput sgr 0 1)     # Underline
    txtbold=$(tput bold)             # Bold
    txtred=$(tput setaf 1)           # red
    txtgreen=$(tput setaf 2)         # green
    txtyellow=$(tput setaf 3)        # yellow
    txtblue=$(tput setaf 4)          # blue
    txtreset=$(tput sgr0)            # Reset
else
    txtunderline=""
    txtbold=""
    txtred=""
    txtgreen=""
    txtyellow=""
    txtblue=$""
    txtreset=""
fi

abort() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "${txtred}${progname} error: $*${txtreset}"
    fi
  } >&2
  exit 1
}

error_info() {
    echo "${txtred}fail! the command exited with status $?${txtreset}"
}

print_help() {
    local filepath="$(abs_dirname "$0")/$progname"
    grep '^#/' <"$filepath" | cut -c4-
}

resolve_link() {
  $(type -p greadlink readlink | head -1) "$1"
}

abs_dirname() {
  local cwd="$(pwd)"
  local path="$1"

  while [ -n "$path" ]; do
    cd "${path%/*}"
    local name="${path##*/}"
    path="$(resolve_link "$name" || true)"
  done

  pwd
  cd "$cwd"
}

trap error_info ERR

outdir=""

# parse arguments and options.
declare -a params=()
for opt in "$@"; do
    case "$opt" in
        '-h')
            print_help
            exit 0
            ;;
        '-v')
            echo $progversion
            exit 0
            ;;
        '-o')
            if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
                abort "option '$1' requires an argument."
            fi
            outdir="$2"
            shift 2
            ;;
        '-o='*)
            optval="${opt:3}"
            if [ -z "$optval" ]; then
                abort "option '$1' requires an argument."
            fi
            outdir="$optval"
            shift 1
            ;;


        '--'|'-' )
            shift 1
            params+=( "$@" )
            break
            ;;
        -*)
            abort "illegal option '$(echo $1 | sed 's/^-*//')'"
            ;;
        *)
            if [[ ! -z "${1:-}" ]] && [[ ! "${1:-}" =~ ^-+ ]]; then
                params+=( "$1" )
                shift 1
            fi
            ;;
    esac
done

if [ ${#params[@]} -lt 1 ]; then
    print_help
    exit 0
fi

if [ -n "$outdir" ]; then
    if [ ! -d "$outdir" ]; then
        mkdir -p "$outdir"
    fi
    cd $outdir
fi

for domain in "${params[@]}"
do
    echo "${txtgreen}${txtbold}Creating certificate for ${txtyellow}$domain${txtreset}"

    echo "Creating KEY: ${txtbold}${txtyellow}${domain}-selfsigned.key${txtreset}"
    openssl genrsa -out ${domain}-selfsigned.key 2048

    echo "Creating CSR: ${txtbold}${txtyellow}${domain}-selfsigned.csr${txtreset}"
    openssl req -new -key ${domain}-selfsigned.key -out ${domain}-selfsigned.csr -subj "/CN=${domain}"

    tmpfile=$(mktemp -t prefix.XXXXXXXX)
    echo "Creating extfile: $tmpfile"

    # see https://stackoverflow.com/questions/43665243/chrome-invalid-self-signed-ssl-cert-subject-alternative-name-missing
    cat << EOF > $tmpfile
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${domain}
EOF

    echo "Creating CRT: ${txtbold}${txtyellow}${domain}-selfsigned.crt${txtreset}"
    openssl x509 -req -days 36500 -in ${domain}-selfsigned.csr -signkey ${domain}-selfsigned.key -out ${domain}-selfsigned.crt -sha256 -extfile ${tmpfile}

    echo "Removing extfile: $tmpfile"
    rm -f $tmpfile
done

