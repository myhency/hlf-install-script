#!/bin/bash

#******************************************************************#
# 파일명 : setAnchorPeer.sh
# 작성자 : 김준기 (크리에이티브힐)
# 작성일 : 2021.03.30
#
# Anchor peer 추가 스크립트
# 
# Copyright IBM Corp. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#******************************************************************#


# import utils / configuration file
. scripts/configUpdate.sh
. scripts/utils.sh
. scripts/envVar.sh

# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  
  # 채널 설정 파일
  CHANNEL_CONFIG_FILE="config.json"

  # 채널 업데이트 수행을 위한 transaction 파일
  CHANNEL_UPDATE_TX="config_update_in_envelope.pb"

  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME $CHANNEL_CONFIG_FILE

  infoln "Generating anchor peer update transaction for ${ORG} on channel $CHANNEL_NAME"

  HOST=$ANCHOR_PEER_HOST
  PORT=$ANCHOR_PEER_PORT
  
  # Modify the configuration to append the anchor peer 
  set -x
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID%MSP}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${CHANNEL_CONFIG_FILE} > modified_${CHANNEL_CONFIG_FILE}
  { set +x; } 2>/dev/null
  
  # Compute a config update, based on the differences between 
  # config.json and modified_config.json, write
  # it as a transaction to update.tx
  createConfigUpdate $CHANNEL_NAME $CHANNEL_CONFIG_FILE modified_$CHANNEL_CONFIG_FILE $CHANNEL_UPDATE_TX
}

updateAnchorPeer() {

  set -x
  peer channel update -o $TARGET_ORDERER_ADDRESS --ordererTLSHostnameOverride  $TARGET_ORDERER_NAME -c $CHANNEL_NAME -f $CHANNEL_UPDATE_TX --tls --cafile $ORDERER_CA
  res=$?
  { set +x; } 2>/dev/null
  
  verifyResult $res "Anchor peer update failed"
  
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"

}

ORG=$1
CHANNEL_NAME=$2

setGlobalsCLI $ORG 0

# 앵커피어 추가를 위한 디렉토리 생성 후, 이동
mkdir -p setAnchor; cd setAnchor

# 앵커피어 Update Transaction 생성
createAnchorPeerUpdate

updateAnchorPeer 