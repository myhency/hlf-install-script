#/bin/bash

#******************************************************************#
# 파일명 : envVar.sh
# 작성자 : 김준기 (크리에이티브힐)
# 작성일 : 2021.03.30
#
# peer / cli 환경변수 지정 스크립트
#
# Copyright IBM Corp. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#******************************************************************#

# 공통 변수 지정
commonGlobals() {

  BASE_DIR=$1

  TARGET_ORDERER_NAME=orderer0
  TARGET_ORDERER_PORT=7050
  TARGET_ORDERER_ADDRESS=${TARGET_ORDERER_NAME}:${TARGET_ORDERER_PORT}
  ORDERER_CA=${BASE_DIR}/organizations/ordererOrganizations/orderers/orderer0/msp/tlscacerts/tlsca.orderer-cert.pem

}

# docker exec cLi 명령 수행을 위한 환경 변수 지정
setGlobals() {

  ORG=$1
  NODE_NUM=$2
  
  if [ "$ORG" == "hmg-kor" ]; then 

    # cli working directory
    BASE_DIR=`docker exec cli pwd`

    commonGlobals $BASE_DIR

    PEER_TLS_ROOTCERT_FILE=${BASE_DIR}/organizations/peerOrganizations/hmg-kor/peers/peer0.hmg-kor/tls/ca.crt
    PEER_PORT=7051
    ENV_PEER="
      -e "CORE_PEER_TLS_ENABLED=true" \
      -e "CORE_PEER_LOCALMSPID=HmgKorMSP" \
      -e "CORE_PEER_TLS_ROOTCERT_FILE=${PEER_TLS_ROOTCERT_FILE}" \
      -e "CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/organizations/peerOrganizations/hmg-kor/users/Admin@hmg-kor/msp" \
      -e "CORE_PEER_ADDRESS=peer${NODE_NUM}.hmg-kor:${PEER_PORT}"
    "
  fi

}

# docker exec cLi 명령 수행을 위한 환경 변수 지정
setGlobalsCLI() {

  ORG=$1
  NODE_NUM=$2
  
  if [ "$ORG" == "hmg-kor" ]; then 

    # cli working directory
    BASE_DIR=$PWD

    commonGlobals $BASE_DIR

    ANCHOR_PEER_HOST=peer0.hmg-kor
    ANCHOR_PEER_PORT=7051
    
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID=HmgKorMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_DIR}/organizations/peerOrganizations/hmg-kor/peers/peer0.hmg-kor/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/organizations/peerOrganizations/hmg-kor/users/Admin@hmg-kor/msp
    export CORE_PEER_ADDRESS=peer${NODE_NUM}.hmg-kor:7051

  fi

}

# 수행 결과 확인 함수
verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}


# 명령 수행 확인 메시지
function confirmCommand() {
  while true; do
    read -p "* Please confirm your command.
  Allow command Input? [y/n]?" yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit 1;;
      * ) echo "Please answer Y or N.";;
    esac
  done
}
