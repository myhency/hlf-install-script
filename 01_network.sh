#!/bin/bash

#******************************************************************#
# 파일명 : 01_network.sh 
# 작성자 : 김준기 (크리에이티브힐)
# 작성일 : 2021.03.29
#
# Hyperledger Fabric Node 구동 관리 및 Crypto material 생성 스크립트
#
# Copyright IBM Corp. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#******************************************************************#

# import
## 로그 형식 및 HELP 메시지
. scripts/utils.sh

## 설정 및 공통 함수
. conf
. scripts/envVar.sh

# Host에서 HLF 바이너리 사용을 위한 환변변수 설정
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=$CONFIGTX_PATH

# 필수 디렉토리 및 파일 생성 및 확인
function checkPrereqs() {

  ## binary 및 설정 파일 확인
  if [[ ! -d "./bin" || $? -ne 0 || ! -d "./config" ]] || find ./bin -maxdepth 0 -empty | read; then
    errorln "binary and configuration files not found.."
    exit 1
  fi

  if [[ ! -d channel-artifacts || ! -d system-genesis-block ]]; then
    infoln "Create required directory."
    mkdir -p channel-artifacts system-genesis-block
  fi

}

# Create Organization crypto material using cryptogen or CAs
function createOrgs() {
  
  infoln
  infoln "Generating certificates using Fabric CA"
  infoln

  # Crypto material 생성 전 명령어 수행 재확인
  confirmCommand

  # 기존에 남아있는 인증서 삭제
  if [[ -d "organizations/peerOrganizations" || -d "organizations/ordererOrganizations" ]]; then
     rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi
  
  # Create crypto material using Fabric CA
  docker-compose -f $COMPOSE_FILE_CA up -d $CA_SERVER 2>&1
  
  # org ca server의 경우, 컨테이너 구동만 수행
  if [ "$VM_NUM" == "2" ]; then
     exit 0
  fi

  sleep 3

  ## import 인증서 등록 / 발급 스크립트
  . organizations/fabric-ca/registerEnroll.sh

  ## Org MSP 등록 / 발급
  infoln "Creating $ORG_NAME Identities"
  create_${ORG_NAME} $PEER_NUM

  ## Orderer MSP 등록 / 발급
  infoln "Creating Orderer Org Identities"
  create_${ORDERER_NAME} $ORDERER_NUM

  ## TLS 등록 / 발급
  infoln "Creating TLS Identities"
  create_${TLS_CA} $PEER_NUM $ORDERER_NUM
}

# Generate orderer system channel genesis block.
function createConsortium() {

  which configtxgen

  if [ "$?" -ne 0 ]; then
     fatalln "configtxgen tool not found."
  fi

  infoln "Generating Orderer Genesis block"

  # Genesis Block 생성
  set -x
  configtxgen -profile $GENESIS_PROFILE -channelID $SYSTEM_CHANNEL_NAME -outputBlock ./system-genesis-block/genesis.block
  res=$?
  { set +x; } 2>/dev/null

  if [ $res -ne 0 ]; then
     fatalln "Failed to generate orderer genesis block..."
  fi

}

# Bring up the peer and orderer nodes using docker compose.
function networkUp() {

  checkPrereqs

  # Docker compose 환경변수 파일 STAGE 별 지정(Symbolic link)
  if [ ! -f "${COMPOSE_FILE_PATH}/.env-${STAGE}" ]; then
      echo "File does not exist"    
      exit 1
  fi
  
  # STAGE 별 docker-compose 환경변수 지정(개발계 : .env-dev / 운영계 : .env-prod)
  ln -sf ${COMPOSE_FILE_PATH}/.env-${STAGE} ${COMPOSE_FILE_PATH}/.env

  # generate certificates
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
  fi
  
  # generate genesis block
  if [ ! -f "./system-genesis-block/genesis.block" ]; then
    createConsortium
  fi
  
  # network 구동
  COMPOSE_FILES="-f $COMPOSE_FILE"
  
  if [[ "$NODES" =~ "couchdb" ]]; then
    COMPOSE_FILES="$COMPOSE_FILES -f $COMPOSE_FILE_COUCH"
  fi

  docker-compose $COMPOSE_FILES up -d $NODES 2>&1

  docker ps -a

  if [ $? -ne 0 ]; then
     fatalln "Unable to start network"
  fi

}

# Obtain Chaincode CONTAINER_IDS and remove them
function clearContainers() {

  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /'${STAGE}'.*/) {print $1}')

  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    infoln "No containers available for deletion"
  else
     docker rm -f $CONTAINER_IDS
  fi

}

# Delete Chaincode Images
function removeUnwantedImages() {

  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /'${STAGE}'.*/) {print $3}')

  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    infoln "No images available for deletion"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi

}

# Tear down running network
function networkDown() {

  # HLF 네트워크 중지 전 명령어 수행 재확인
  confirmCommand

  # stop containers
  docker-compose -f $COMPOSE_FILE_NODE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
  
  # Cleanup the chaincode containers
  clearContainers

  # Cleanup chaincode images
  removeUnwantedImages

  # Docker volume 삭제
  docker volume prune -f

  # Crypto material 삭제
  if [ $ALL == true ]; then

    # remove orderer block and other channel configuration transactions and certs
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/* channel-artifacts/'${CHANNEL_NAME}.*' organizations/peerOrganizations organizations/ordererOrganizations organizations/tlsca'

    ## remove fabric ca artifacts
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ca.'${ORG_NAME}'/msp organizations/fabric-ca/ca.'${ORG_NAME}'/tls-cert.pem organizations/fabric-ca/ca.'${ORG_NAME}'/ca-cert.pem organizations/fabric-ca/ca.'${ORG_NAME}'/IssuerPublicKey organizations/fabric-ca/ca.'${ORG_NAME}'/IssuerRevocationPublicKey organizations/fabric-ca/ca.'${ORG_NAME}'/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ca.'${ORDERER_NAME}'/msp organizations/fabric-ca/ca.'${ORDERER_NAME}'/tls-cert.pem organizations/fabric-ca/ca.'${ORDERER_NAME}'/ca-cert.pem organizations/fabric-ca/ca.'${ORDERER_NAME}'/IssuerPublicKey organizations/fabric-ca/ca.'${ORDERER_NAME}'/IssuerRevocationPublicKey organizations/fabric-ca/ca.'${ORDERER_NAME}'/fabric-ca-server.db'
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/'${TLS_CA}'/msp organizations/fabric-ca/'${TLS_CA}'/tls-cert.pem organizations/fabric-ca/'${TLS_CA}'/ca-cert.pem organizations/fabric-ca/'${TLS_CA}'/IssuerPublicKey organizations/fabric-ca/'${TLS_CA}'/IssuerRevocationPublicKey organizations/fabric-ca/'${TLS_CA}'/fabric-ca-server.db'

  fi

}

# Global Variable
## default docker-compose file
COMPOSE_FILE=$COMPOSE_FILE_NODE

## network down 시, Crypto material 삭제 Falg [true : 삭제 / false : 미삭제]
ALL=false

## Hostname 구분
NODE=`uname -n`
VM_NUM=${NODE: -1}

# Parse commandline args
## Parse mode
command="network"

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
  -ca )
    COMPOSE_FILE="$COMPOSE_FILE_CA"
    NODES="$CA_SERVER"
    ;;
  -node )
    COMPOSE_FILE="$COMPOSE_FILE_NODE"
    NODES="$NODES"
    ;;
  -a )
    ALL=true
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
if [ "${MODE}" == "up" ]; then
  infoln "Starting Hyperledger Fabric nodes"
  networkUp
elif [ "${MODE}" == "down" ]; then
  infoln "Stopping network"
  networkDown
else
  printHelp $command
  exit 1
fi