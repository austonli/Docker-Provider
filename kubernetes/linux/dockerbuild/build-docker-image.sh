#!/bin/bash
#
# Execute this directly in Azure Cloud Shell (https://shell.azure.com) by pasting (SHIFT+INS on Windows, CTRL+V on Mac or Linux)
# the following line (beginning with curl...) at the command prompt and then replacing the args:
#  This scripts builds docker image ad push to specified docker repo

set -e
set -o pipefail

image=""
imageTag=""
dockerUser=""
usage()
{
    local basename=`basename $0`
    echo
    echo "Build and publish docker image:"
    echo "$basename --image <name of docker image> "
}

parse_args()
{

 if [ $# -le 1 ]
  then
    usage
    exit 1
 fi

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--image")  set -- "$@" "-i" ;;
    "--"*)   usage ;;
    *)        set -- "$@" "$arg"
  esac
done

local OPTIND opt

while getopts 'hi:' opt; do
    case "$opt" in
      h)
      usage
        ;;

      i)
        image="$OPTARG"
        echo "image is $OPTARG"
        ;;

      ?)
        usage
        exit 1
        ;;
    esac
  done
  shift "$(($OPTIND -1))"


 if [ -z "$image" ]; then
    echo "-e invalid image. please try with valid values"
    exit 1
 fi

 # extract image tag
 imageTag=$(echo ${image} | sed "s/.*://")

 if [ -z "$imageTag" ]; then
    echo "-e invalid image. please try with valid values"
    exit 1
 fi

if [ $image = $imageTag ]; then
  echo "-e invalid image format. please try with valid values"
  exit 1
fi

#  if [ -z "$dockerUser" ]; then
#     echo "-e missing docker username. please try with valid username for the docker login"
#     exit 1
#  fi

}

build_docker_provider()
{
  echo "building docker provider shell bundle"
  cd $buildDir
  echo "trigger make to build docker build provider shell bundle"
  make
  echo "building docker provider shell bundle completed"
}

login_to_docker()
{
  echo "login to docker with provided creds"
  # sudo docker login --username=$dockerUser
  sudo docker login
  echo "login to docker with provided creds completed"
}

build_docker_image()
{
  echo "build docker image: $image and image tage is $imageTag"
  cd $baseDir/kubernetes/linux
  docker build -t $image --build-arg IMAGE_TAG=$imageTag  .

  echo "publishing docker image to docker repo"
  docker push  $image

  echo "build docker image completed"
}

publish_docker_image()
{
  echo "publishing docker image: $image"
  docker push  $image
}

# parse and validate args
parse_args $@

currentDir=$PWD

## TODO figureout better way than this
dockerBuildDir=$(dirname $PWD)
linuxDir=$(dirname $dockerBuildDir)
kubernetsDir=$(dirname $linuxDir)
baseDir=$(dirname $kubernetsDir)
buildDir=$baseDir/build/linux
dockerFileDir=$baseDir/kubernetes/linux

echo "sour code base directory: $baseDir"
echo "build directory for docker provider: $buildDir"
echo "docker file directory: $dockerFileDir"

# login to docker
login_to_docker

# build docker provider shell bundle
build_docker_provider

# build docker image
build_docker_image

# publish docker image
publish_docker_image

cd $currentDir


