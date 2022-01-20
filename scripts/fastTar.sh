#!/bin/bash -

# =================================
# Purpose:
# Wrap pigz in a bash friendly script to tar files in parallel
#
# Version Notes: 1.1.1
#  - 1.1.1,
#    svect, removed “-“ from “-chvf” and “-chf”
#    svect, added example use of fastTar
#    svect, add pigz -l output for reduced % of compressed file
#
#  - 1.2.0,
#    svect, adding option, -b 1000, to increase block size
#                from default 128KB to 1000KB to improve speed
#
#  - 1.1.X,
#
#   TODO:
#    - add unit test option for fastTar
#    - estimated time until done compressing
# =================== Function Definitions ================= #

# method: helpText

# purpose:

helpText()
{

                echo “Use just like tar.”
                echo “”
                echo “Simple (without options): “
                echo “    fastTar <destination> <source>”
                echo “”
                echo “Advanced (with options): “
                echo “    fastTar <options> <destination> <source>”
                echo “”
                echo “Tar Options:”
                echo “    -H: help”
                echo “    -v: verbose”
                echo “    -h: follow hyperlinks”
                echo “”
                echo “Pigz Options:”
                echo “    -k: tar compression option (default 9 -- highest compression, least speed)”
                echo “    -p: number of cores (default 22)”
                echo “”
                echo “Example:”
                echo “    >>>> fastTar -hv -k 7 -p 44 path/to/compressed.tar.gz path/to/uncompressed”
                exit 1
}

# method: usageText()
# purpose:
usageText()
{
                echo “Usage: fastTar [ -v | --verbose ] [ -k | -- compression ] [ -h | --dereference ]”
                echo “                          [ -p | --cores      ] [ -H | --help]”
                echo “                          < DESTINATION > < SOURCE >”
                echo “”
                echo “Try \”fastTar -H\” for more information.”
                exit 1
}
 
# method: echoIfVerbose()
# purpose: To echo outputs based on verbosity
#
# arguments:
#     - $1: The boolean “verbose” (to indicate whether or not to print)
#     - $2: The string to print, if verbose
#
echoIfVerbose()
{

                if [[ $1 == true ]]; then

                    echo $2

                fi

}

# =========================================================== #

echo “”
echo “Welcome to fastTar!”

# Boolean variables

VERBOSE=false
HYPERLINK=false

# Location variables
sourceArg=()
destArg=””

# Invoke getopt() to parse input options elegantly
PARSED_ARGUMENTS=$(getopt -a -n fastTar -o vhHp:k: --long verbose,dereference,cores:,compression:,usage -- “$@”)
VALID_ARGUMENTS=$? # this line needs to be right after the line where getopt is called

if [ “$VALID_ARGUMENTS” != “0” ]; then
                usageText
fi

# puts the parsed arguments on the command line as if the user called fastTar with them in the first place
eval set -- “$PARSED_ARGUMENTS”

# parse the options that getopt() collected
while :
do
                case “$1” in
                                -v | --verbose)          VERBOSE=true       ; shift ;;
                                -h | --dereference)  HYPERLINK-true     ; shift ;;
                                -H | --help)                helpText                  ;; # helpText exits the program
                                --usage)                      usageText               ;; # usageText exists the program
                                -p | --cores)
if [[ -z $2 ]]
                                                then
                                                                CORES=22; shift
                                                else
                                                                CORES=$2; shift

fi
                                       shift; ;;
                                -k | --compression)
                                                if [[ -z $2 ]]
                                                then
                                                                COMPRESSION=”-9”; shift
                                                else
                                                                COMPRESSION=”-$2”; shift
                                                fi
                                                shift; ;;
                                --) shift; break ;; # getopt produces this b/n options and arguments
                esac
done

# Now the only arguments remaining in $@ *should* be DESTINATION and SOURCE. All options have been parsed and removed from $@
# Make sure there are 2 arguments in $@; presumably corresponding to D and S.

case “$#” in
usageText ;; # no arguments given
echo “fastTar: Please provide a DESTINATION and SOURCE.”; usageText ;; # one input argument given
esac

destArg=$1
sourceArg=$2
tarOpts=”cf”

if [[ $VERBOSE == true ]]; then
                tarOpts+=”v”
fi

if [[ $HYPERLINK == true ]]; then
                tarOpts+=”h”
fi

if [[ -z $CORES ]]; then
                CORES=22 # default to 22 cores
fi

if [[ -z $COMPRESSION ]]; then
                COMPRESSION=”-9” # default to highest compression
fi

# Makes everything .tar.gz, in case people don’t write it in
if [[ ! $destArg:${#destArg}-7 == “.tar.gz” && ! ${destArg:${#destArg}-4 == “.tar” ]]; then
                destArg=”${destArg}.tar.gz”
elif [[ ${destArg:${#destArg}-4} == “.tar” ]]; then
                destArg=”${destArg}.gz”
fi

# Call tar to create tarball and compress using pigz binary
echoIfVerbose $VERBOSE “Calling tar with: Options: $tarOpts; Number of cores: $CORES; Creating tar file titled: $destArg; Tar option: $COMPRESSION”

tar $tarOpts - ${sourceArg[@]} | pigz -b 1000 $COMPRESSION -p $CORES > $destArg

echo “”
echo “Created $destArg”
compressResults=$(pigz -l ${destArg})
echo “”
echo “${compressResults}”
echo “”
echo “fastTar complete!”
