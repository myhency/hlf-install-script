#!/bin/bash

#******************************************************************#
# 테스트용, Sample Chaincode Invoke Test
#******************************************************************#

# import
. ../conf

# cli base directory
BASE_DIR="/opt/gopath/src/github.com/hyperledger/fabric/peer"

KEY="$1"
PEER0_AUTO_CA=${BASE_DIR}/organizations/peerOrganizations/hmg-kor/peers/peer0.hmg-kor/tls/ca.crt
ORDERER_CA="${BASE_DIR}/organizations/ordererOrganizations/orderers/orderer0/msp/tlscacerts/tlsca.orderer-cert.pem"
ORDERER_NAME="orderer0"
ORDERER_ADDRESS="${ORDERER_NAME}:7050"


ENV_PEER0="
  -e "CORE_PEER_TLS_ENABLED=true" \
  -e "CORE_PEER_LOCALMSPID=HmgKorMSP" \
  -e "CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_AUTO_CA" \
  -e "CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/organizations/peerOrganizations/hmg-kor/users/Admin@hmg-kor/msp" \
  -e "CORE_PEER_ADDRESS=peer0.hmg-kor:7051"
"

ARGS='{"function":"CreateSample","Args":["'${KEY}'","오토","20"]}'

docker exec $ENV_PEER0 cli peer chaincode invoke -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_NAME --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME --peerAddresses peer0.hmg-kor:7051 --tlsRootCertFiles ${PEER0_AUTO_CA} -c $ARGS
