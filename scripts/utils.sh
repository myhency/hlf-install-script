#!/bin/bash

#******************************************************************#
# 파일명 : utils.sh
# 작성자 : 김준기 (크리에이티브힐)
# 작성일 : 2021.04.05
#
# Log 형식 / Help 메시지 출력
#
# Copyright IBM Corp. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#******************************************************************#

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# Print the usage message
function printHelp() {
  USAGE="$1"
  if [ "$USAGE" == "network" ]; then
    println "Usage: "
    println "  \033[0;32m01_network.sh\033[0m COMMAND [Flags]"
    println
    println "  Generate network crypto material and Start HLF nodes"
    println
    println "    COMMAND:"
    println "    up    Generate network crypto material and start hlf services"
    println "    down  Stop and remove resources"
    println
    println "    Flags:"
    println "    -ca   Generate network crypto material and Start CA Server"
    println "    -node Start HLF services(\"peer, orderer, cli\")"
    println "    -a    Remove Crypto Material"
    println "    -h    Print this message"
    println    
    println " Possible Command and flag combinations"
    println "   \033[0;32m01_network.sh\033[0m up"
    println "   \033[0;32m01_network.sh\033[0m up -ca"
    println "   \033[0;32m01_network.sh\033[0m up -node"
    println "   \033[0;32m01_network.sh\033[0m down"
    println "   \033[0;32m01_network.sh\033[0m down -a"
  elif [ "$USAGE" == "channel" ]; then
    println "Usage: "
    println "  \033[0;32m02_channel.sh\033[0m COMMAND [Flags]"
    println
    println "  Operate a channel: generate channel tx|create|join|set anchor peer."
    println
    println "    COMMAND:"
    println "    generate  Write the application channel block to a file."
    println "    create    Create a channel"
    println "    join      Joins the peer to a channel"
    println "    setanchor Set anchor peer to a channel"
    println
    println "    Flags:"
    println "    -h        Print this message"
    println
    println " Possible Command"
    println "   \033[0;32m02_channel.sh\033[0m generate"
    println "   \033[0;32m02_channel.sh\033[0m create"
    println "   \033[0;32m02_channel.sh\033[0m join"
    println "   \033[0;32m02_channel.sh\033[0m setanchor"
  elif [ "$USAGE" == "chaincode" ]; then
    println "Usage: "
    println "  \033[0;32m03_chaincode.sh\033[0m COMMAND [Flags]"
    println
    println "  Perform chaincode operations: package|install|approveformyorg|commit|queryinstalled|checkcommitreadiness|querycommitted."
    println
    println "    COMMAND:"
    println "    package        Package a chaincode and write the package to a file"
    println "    install        Install a chaincode on a peer"
    println "    approve        Approve the chaincode definition for my organization"
    println "    commit         Commit the chaincode definition on the channel"
    println "    queryinstalled Query the installed chaincodes on a peer"
    println "    checkcommit    Check whether a chaincode definition is ready to be committed on a channel"
    println "    querycommitted Query the committed chaincode definitions by channel on a peer"
    println
    println "    Flags:"
    println "    -h - Print this message"
    println
    println " Possible Command"
    println "   \033[0;32m03_chaincode.sh\033[0m package"
    println "   \033[0;32m03_chaincode.sh\033[0m install"
    println "   \033[0;32m03_chaincode.sh\033[0m approve"
    println "   \033[0;32m03_chaincode.sh\033[0m commit"
    println "   \033[0;32m03_chaincode.sh\033[0m queryinstalled"
    println "   \033[0;32m03_chaincode.sh\033[0m checkcommit"
    println "   \033[0;32m03_chaincode.sh\033[0m querycommitted"
  fi
}

# println echos string
function println() {
  echo -e "$1"
}

# errorln echos i red color
function errorln() {
  println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

export -f errorln
export -f successln
export -f infoln
export -f warnln
