#!/bin/bash

CC_IMAGE_NAME="ejortega/duo-sdk:latest"
CWD=$(pwd)
IFS=" "
COMMAND="$*"
BUILD_COMMAND=""
_UID=$(id -u)
_GID=$(id -g)
MAKE=false
correct=""

while getopts i:u:g:rya OPTION; do

  case "${OPTION}" in

    i)
      CC_IMAGE_NAME="${OPTARG}";;
    
    p)
      sudo docker pull ${CC_IMAGE_NAME};;

    u)
      _UID=${OPTARG};;

    g)
      _GID=${OPTARG};;

    r)
      _UID=0
      _GID=0;;

    y)
      correct="y";;
    
    a)
      COMMAND="cmake -DCMAKE_TOOLCHAIN_FILE=/app/milkv_duo.cmake .."
      MAKE=true;;

    *)
      echo "Unknown option";;

  esac
done

command_factory () {

  if [[ "$COMMAND" == *"cmake"* ]]; then

    BUILD_COMMAND="rm -rf /app/*CMakeCache* && "

    if [[ "$COMMAND" == *".."* ]]; then

      BUILD_COMMAND="${BUILD_COMMAND}if [[ -d /app/build ]]; then rm -rf /app/build; fi && mkdir -p /app/build && cd /app/build && ${COMMAND}"  

    elif [[ "$COMMAND" == *"--build"* ]]; then

      BUILD_COMMAND="${BUILD_COMMAND}cd /app/build && ${COMMAND}"

    else

      BUILD_COMMAND="${BUILD_COMMAND}${COMMAND}"

    fi

  else

    BUILD_COMMAND="cd /app/build && ${COMMAND}"

  fi

  echo
  echo "Build Command: ${BUILD_COMMAND}"
  echo
}

exec_command () {

  echo "Full Command: sudo docker run --rm --user \"${_UID}\":\"${_GID}\" -v \"${CWD}\":/app -t ${CC_IMAGE_NAME} /bin/bash -c \"${BUILD_COMMAND}\""
  echo

  if [[ "$correct" == "" ]]; then
    
    read -sn 1 -p "Is the command correct?[y/N]: " correct
    echo
    echo

  fi

  if [[ "$correct" == "y" ]]; then

    sudo docker run --rm --user "${_UID}":"${_GID}" -v "${CWD}":/app -t ${CC_IMAGE_NAME} /bin/bash -c "${BUILD_COMMAND}"
    ERROR=$?

  fi

}

command_factory
exec_command

if ${MAKE}; then

  COMMAND="make"
  command_factory
  exec_command

fi

echo
echo "Have a nice day!!"

exit $ERROR

