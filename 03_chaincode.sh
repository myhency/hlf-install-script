#!/bin/bash

#******************************************************************#
# 파일명 : 03_chaincode.sh 
# 작성자 : 김준기 (크리에이티브힐)
# 작성일 : 2021.03.31
#
# Chaincode 관리 스크립트
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

# chaincode 패키징
function packageChaincode() {

  set -x
  peer lifecycle chaincode package channel-artifacts/${CHAINCODE_NAME}.tar.gz --path ${CHAINCODE_SRC_PATH} --lang ${CHAINCODE_LANGUAGE} --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}
  res=$?
  { set +x; } 2>/dev/null
  
  verifyResult $res "Failed to packaging chaincode."

  successln "Chaincode packaged as '${CHAINCODE_NAME}.tar.gz'"

}

# install chaincode
function installChaincode() {
  
  for (( i = 0; i < $PEER_NUM; i++ )); do
  
    # 환경변수 지정
    setGlobals "$ORG_NAME" $i

    set -x
    docker exec ${ENV_PEER} cli peer lifecycle chaincode install ./channel-artifacts/${CHAINCODE_NAME}.tar.gz
    res=$?
    { set +x; } 2>/dev/null

    verifyResult $res "failed to install chaincode '$CHAINCODE_NAME'"

    successln "Chaincode '$CHAINCODE_NAME' installed"

  done

}

# query installed chaincode
function queryInstalled() {

  # 환경변수 지정
  setGlobals "$ORG_NAME" 0

  set -x
  docker exec ${ENV_PEER} cli peer lifecycle chaincode queryinstalled > ./channel-artifacts/installedChaincode.txt
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "failed to query installed chaincode '$CHAINCODE_NAME'"

  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" ./channel-artifacts/installedChaincode.txt)

  successln "Chaincode id : $PACKAGE_ID"

}

# approve the definition
function approveForMyOrg() {

  # 환경변수 지정
  setGlobals "$ORG_NAME" 0

  # Package Id 설정
  queryInstalled

  PACKAGE_IDS=$(echo $PACKAGE_ID | tr " " "\n")

  # Channel/Application/LifecycleEndorsement 정책에 맞는 Peer 지정
  for ID in $PACKAGE_IDS
  do

    if [[ "$ID" =~ "${CHAINCODE_NAME}_${CHAINCODE_VERSION}" ]]; then
      PACKAGE_ID=$ID
      break
    fi
    
  done

  set -x
  docker exec $ENV_PEER cli peer lifecycle chaincode approveformyorg -o $TARGET_ORDERER_ADDRESS --ordererTLSHostnameOverride $TARGET_ORDERER_NAME --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --package-id $PACKAGE_ID --sequence $CHAINCODE_SEQUENCE $INIT_REQUIRED $ENDORSEMENT_POLICY $COLLECTION_CONFIG
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "failed to approveformyorg chaincode '$CHAINCODE_NAME'"

  successln "Chaincode '$CHAINCODE_NAME' approved"

}

# chaincode definition approvals 확인
function checkCommitReadiness() {

  # 환경변수 지정
  setGlobals "$ORG_NAME" 0

  set -x
  docker exec $ENV_PEER cli peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence $CHAINCODE_SEQUENCE $INIT_REQUIRED $ENDORSEMENT_POLICY $COLLECTION_CONFIG --output json
  res=$?
  { set +x; } 2>/dev/null

  successln "Checking the commit readiness of the chaincode definition successful on ${ORG_NAME} on channel '$CHANNEL_NAME'"
}

# chaincode 배포
function commitChaincodeDefinition() {
  
  # Org가 여러개일 경우, 공백으로 구분
  ORGS=$(echo $CHAINCODE_COMMIT_ORGS | tr " " "\n")
  PEER_CONN_PARMS=()
  PEERS=""

  # Channel/Application/LifecycleEndorsement 정책에 맞는 Peer 지정
  for ORG in $ORGS
  do

    setGlobals "$ORG" 0

    PEER="peer0.${ORG}"
    PEERS="$PEERS $PEER"
  
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $PEER:$PEER_PORT)

    # Set path to TLS certificate
    TLSINFO="--tlsRootCertFiles ${PEER_TLS_ROOTCERT_FILE}"

    PEER_CONN_PARMS=(${PEER_CONN_PARMS[@]} ${TLSINFO[@]})
    
  done

  setGlobals "$ORG_NAME" 0
  
  set -x
  docker exec $ENV_PEER cli peer lifecycle chaincode commit -o $TARGET_ORDERER_ADDRESS --ordererTLSHostnameOverride $TARGET_ORDERER_NAME --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name $CHAINCODE_NAME "${PEER_CONN_PARMS[@]}" --version $CHAINCODE_VERSION --sequence $CHAINCODE_SEQUENCE $INIT_REQUIRED $ENDORSEMENT_POLICY $COLLECTION_CONFIG
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "Chaincode definition commit failed on ${ORG_NAME} on channel '$CHANNEL_NAME' failed"

  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

# 배포된 chaincode 확인
function queryCommitted() {

  setGlobals "$ORG_NAME" 0

  set -x
  docker exec $ENV_PEER cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME
  res=$?
  { set +x; } 2>/dev/null

  verifyResult $res "Query chaincode definition result on ${ORG_NAME} is INVALID!d"

  successln "Query chaincode definition successful on ${ORG_NAME} on channel '$CHANNEL_NAME'"
}

# Chaincode Configuration
## Chainocde Init Required
INIT_REQUIRED=""
### Chaincode Init Required : Init() 함수 수행 여부
if [ "$CHAINCODE_INIT_REQUIRED" == "true" ]; then
  INIT_REQUIRED="--init-required"
fi

ENDORSEMENT_POLICY=""
## Chaincode Endorsement Policy
if [ ! -z $CHAINCODE_ENDORSEMENT_POLICY ]; then
  ENDORSEMENT_POLICY="--signature-policy $CHAINCODE_ENDORSEMENT_POLICY"
  # ENDORSEMENT_POLICY='"'$ENDORSEMENT_POLICY'"  "'${CHAINCODE_ENDORSEMENT_POLICY}'"'
fi

## Chaincode PDC Configuration
COLLECTION_CONFIG=""
if [ ! -z "$CHAINCODE_COLLECTION_CONFIG" ]; then
  COLLECTION_CONFIG="--collections-config $CHAINCODE_COLLECTION_CONFIG"
fi

# Parse commandline args
## Parse mode
command="chaincode"

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
if [ "${MODE}" == "package" ]; then
  infoln "Package the chaincode : ${CHAINCODE_NAME}"
  packageChaincode
elif [ "${MODE}" == "install" ]; then  
  infoln "Installing chaincode on ${CHANNEL_NAME}"
  installChaincode
elif [ "${MODE}" == "queryinstalled" ]; then
  infoln "Query installed chaincode on ${CHANNEL_NAME}"
  queryInstalled
elif [ "${MODE}" == "approve" ]; then
  infoln "Approve the definition for ${ORG_NAME}"
  approveForMyOrg
elif [ "${MODE}" == "checkcommit" ]; then
  infoln "Checking the commit readiness of the chaincode definition on ${ORG_NAME} on channel '$CHANNEL_NAME'"
  checkCommitReadiness
elif [ "${MODE}" == "commit" ]; then
  infoln "Commit the definition"
  commitChaincodeDefinition
elif [ "${MODE}" == "querycommitted" ]; then
  infoln "Querying chaincode definition on ${ORG_NAME} on channel '$CHANNEL_NAME'"
  queryCommitted
else
  printHelp $command
  exit 1
fi

