#!/bin/bash

#******************************************************************#
# 파일명 : 02_channel.sh
# 작성자 : 김준기 (크리에이티브힐)
# 작성일 : 2021.03.30
#
# Channel 생성 / 가입 스크립트
#
# Copyright IBM Corp. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#******************************************************************#

# import
## 로그 형식 및 HELP 메시지
. scripts/utils.sh

## 설정 파일
. conf
. scripts/envVar.sh

# Host에서 HLF 바이너리 사용을 위한 환변변수 설정
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=$CONFIGTX_PATH

# Create channeltx
function generateArtifacts() {
  
  # 바이너리 존재 확인
  which configtxgen

  if [ "$?" -ne 0 ]; then
     fatalln "configtxgen tool not found."
  fi

  set -x
  configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx $CHANNEL_TX_FILE -channelID $CHANNEL_NAME
  res=$?
  { set +x; } 2>/dev/null
  
  verifyResult $res "Failed to generate channel configuration transaction."

  successln "Channel Tx('${CHANNEL_NAME}'.tx) generated"

}

# Create channel
function createChannel() {

  # 환경변수 지정
  ## setGlobals [Org 명] [Node num]
  setGlobals "$ORG_NAME" 0

  set -x
  docker exec $ENV_PEER cli peer channel create -o $TARGET_ORDERER_ADDRESS -c $CHANNEL_NAME --ordererTLSHostnameOverride $TARGET_ORDERER_NAME -f $CHANNEL_TX_FILE --outputBlock $CHANNEL_BLOCK_FILE --tls --cafile $ORDERER_CA
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "Channel creation failed"

  successln "Channel '$CHANNEL_NAME' created"

}

# joinChannel ORG
function joinChannel() {

  for (( i = 0; i < $PEER_NUM; i++ )); do
  
    # 환경변수 지정
    setGlobals "$ORG_NAME" $i

    set -x
    docker exec $ENV_PEER cli peer channel join -b $CHANNEL_BLOCK_FILE
    res=$?
    { set +x; } 2>/dev/null

    verifyResult $res "failed to join channel '$CHANNEL_NAME'"

    successln "Channel '$CHANNEL_NAME' created"

  done

}

# Setting anchor peer
function setAnchorPeer() {

  docker exec cli ./scripts/setAnchorPeer.sh $ORG_NAME $CHANNEL_NAME

}

# Global variable
## Channel Tx block
CHANNEL_TX_FILE="./channel-artifacts/${CHANNEL_NAME}.tx"
CHANNEL_BLOCK_FILE="./channel-artifacts/${CHANNEL_NAME}.block"

# Parse commandline args
## Parse mode
command="channel"

if [[ $# -lt 1 ]] ; then
  printHelp $command
  exit 0
else
  MODE=$1
  shift
fi

# parse flags
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp $command
    exit 0
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp $command
    exit 1
    ;;
  esac
  shift
done

# Determine mode of operation and printing out what we asked for
if [ "${MODE}" == "generate" ]; then
  infoln "Generating channel create transaction '${CHANNEL_NAME}.tx'"
  generateArtifacts
elif [ "${MODE}" == "create" ]; then  
  infoln "Creating channel ${CHANNEL_NAME}"
  createChannel
elif [ "${MODE}" == "join" ]; then
  infoln "Joining peer to the channel"
  joinChannel
elif [ "$MODE" == "setanchor" ]; then  
  infoln "Setting anchor peer"
  setAnchorPeer
else
  printHelp $command
  exit 1
fi