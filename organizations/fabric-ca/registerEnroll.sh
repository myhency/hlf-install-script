#!/bin/bash
# 인증서 등록 / 발급 스크립트
## 함수명은 "create_[Org 명]"으로 지정

# HmgKor MSP 발급
function create_hmg-kor() {

  # 공통 변수 지정
  MSP_BASE_DIR="${PWD}/organizations/peerOrganizations/hmg-kor/"
  TLS_CERTIFICATES="${PWD}/organizations/fabric-ca/ca.hmg-kor/tls-cert.pem"
  CA_NAME="ca.hmg-kor"
  CA_PORT="7054"
  CA_SERVER_ADDRESS="${CA_NAME}:${CA_PORT}"
  NODEOUS_CERTIFICATE=$(echo ${CA_SERVER_ADDRESS}-${CA_NAME} | sed 's/[.:]/-/g').pem
  PEER_NUM=$1

  # CA Admin 인증서 발급
  infoln "Enrolling the CA admin"
  mkdir -p $MSP_BASE_DIR

  export FABRIC_CA_CLIENT_HOME=$MSP_BASE_DIR

  commonEnroll "https://admin:adminpw@${CA_SERVER_ADDRESS}" $CA_NAME "${FABRIC_CA_CLIENT_HOME}/msp" "NA" "NA" $TLS_CERTIFICATES

  # Generate Nodeous File
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/'${NODEOUS_CERTIFICATE}'
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/'${NODEOUS_CERTIFICATE}'
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/'${NODEOUS_CERTIFICATE}'
    OrganizationalUnitIdentifier: admin' >${MSP_BASE_DIR}/msp/config.yaml


  # 인증서 등록
  ## commonRegister [caname] [node id] [node secret] [node type] [tls ca certificate]
  ## -> fabric-ca-client register --caname [caname] --id.name [node id] --id.secret [node secret] --id.type [node type] --id.attrs "hf.GenCRL=true" --tls.certfiles [tls ca certificate]

  for (( i = 0; i < $PEER_NUM; i++ )); do

    infoln "Registering peer${i}"
    commonRegister $CA_NAME "peer${i}" "peer${i}pw" "peer" $TLS_CERTIFICATES

  done

  infoln "Registering user"  
  commonRegister $CA_NAME "user1" "user1pw" "client" $TLS_CERTIFICATES

  infoln "Registering the org admin"
  commonRegister $CA_NAME "hmg-kor-admin" "hmg-kor-adminpw" "admin" $TLS_CERTIFICATES


  # 인증서 발급 및 NodeOUs 파일 복사 
  ## commonEnroll [ca server enroll url] [caname] [msp path] [csr hosts : 값이 없는 경우 - "NA"] [tls ca certificate]
  ## -> fabric-ca-client enroll -u [ca server enroll url] --caname [caname] -M [msp path] [--csr.hosts [csr hosts]] [--enrollment.profile] --tls.certfiles [tls ca certificate]

  for (( i = 0; i < $PEER_NUM; i++ )); do

    infoln "Generating the peer${i} msp"
    commonEnroll "https://peer${i}:peer${i}pw@${CA_SERVER_ADDRESS}" $CA_NAME "${MSP_BASE_DIR}/peers/peer${i}.hmg-kor/msp" "peer${i}.hmg-kor" "NA" $TLS_CERTIFICATES

    cp ${MSP_BASE_DIR}/msp/config.yaml ${MSP_BASE_DIR}/peers/peer${i}.hmg-kor/msp/config.yaml
    
  done
  
  infoln "Generating the user msp"
  commonEnroll "https://user1:user1pw@${CA_SERVER_ADDRESS}" $CA_NAME "${MSP_BASE_DIR}/users/User1@hmg-kor/msp" "NA" "NA" $TLS_CERTIFICATES
  
  cp ${MSP_BASE_DIR}/msp/config.yaml ${MSP_BASE_DIR}/users/User1@hmg-kor/msp/config.yaml

  infoln "Generating the org admin msp"
  commonEnroll "https://hmg-kor-admin:hmg-kor-adminpw@${CA_SERVER_ADDRESS}" $CA_NAME "${MSP_BASE_DIR}/users/Admin@hmg-kor/msp" "NA" "NA" $TLS_CERTIFICATES
  
  cp ${MSP_BASE_DIR}/msp/config.yaml ${MSP_BASE_DIR}/users/Admin@hmg-kor/msp/config.yaml

}

# Orderer MSP 발급
function create_orderer-org() {

  # 공통 변수 지정
  MSP_BASE_DIR="${PWD}/organizations/ordererOrganizations"
  TLS_CERTIFICATES="${PWD}/organizations/fabric-ca/ca.orderer-org/tls-cert.pem"
  CA_NAME="ca.orderer-org"
  CA_PORT="8054"
  CA_SERVER_ADDRESS="${CA_NAME}:${CA_PORT}"
  NODEOUS_CERTIFICATE=$(echo ${CA_SERVER_ADDRESS}-${CA_NAME} | sed 's/[.:]/-/g').pem
  ORDERER_NUM=$1

  infoln "Enrolling the CA admin"
  mkdir -p $MSP_BASE_DIR

  export FABRIC_CA_CLIENT_HOME=$MSP_BASE_DIR

  commonEnroll "https://admin:adminpw@${CA_SERVER_ADDRESS}" $CA_NAME "${FABRIC_CA_CLIENT_HOME}/msp" "NA" "NA" $TLS_CERTIFICATES

  echo 'NodeOUs:
  Enable: true
  AdminOUIdentifier:
    Certificate: cacerts/'${NODEOUS_CERTIFICATE}'
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/'${NODEOUS_CERTIFICATE}'
    OrganizationalUnitIdentifier: orderer' >${MSP_BASE_DIR}/msp/config.yaml

  # 인증서 등록
  ## commonRegister [caname] [node id] [node secret] [node type] [tls ca certificate]
  ## -> fabric-ca-client register --caname [caname] --id.name [node id] --id.secret [node secret] --id.type [node type] --id.attrs "hf.GenCRL=true" --tls.certfiles [tls ca certificate]


  for (( i = 0; i < $ORDERER_NUM; i++ )); do

    infoln "Registering orderer${i}"
    commonRegister $CA_NAME "orderer${i}" "orderer${i}pw" "orderer" $TLS_CERTIFICATES

  done

  infoln "Registering the orderer admin"
  commonRegister $CA_NAME "orderer-admin" "orderer-adminpw" "admin" $TLS_CERTIFICATES


  # 인증서 발급 및 NodeOUs 파일 복사 
  ## commonEnroll [ca server enroll url] [caname] [msp path] [csr hosts : 값이 없는 경우 - "NA"] [tls ca certificate]
  ## -> fabric-ca-client enroll -u [ca server enroll url] --caname [caname] -M [msp path] [--csr.hosts [csr hosts]] [--enrollment.profile] --tls.certfiles [tls ca certificate]

  for (( i = 0; i < $ORDERER_NUM; i++ )); do

    infoln "Generating the orderer${i} msp"
    commonEnroll "https://orderer${i}:orderer${i}pw@${CA_SERVER_ADDRESS}" $CA_NAME "${MSP_BASE_DIR}/orderers/orderer${i}/msp" "orderer${i}" "NA" $TLS_CERTIFICATES
    
    cp ${MSP_BASE_DIR}/msp/config.yaml ${MSP_BASE_DIR}/orderers/orderer${i}/msp/config.yaml

  done

  infoln "Generating the admin msp"
  commonEnroll "https://orderer-admin:orderer-adminpw@${CA_SERVER_ADDRESS}" $CA_NAME "${MSP_BASE_DIR}/users/Admin@orderer/msp" "NA" "NA" $TLS_CERTIFICATES

  cp ${MSP_BASE_DIR}/msp/config.yaml ${MSP_BASE_DIR}/users/Admin@orderer/msp/config.yaml
  
}

# TLS 발급
function create_tls-ca() {

  # 공통 변수 지정
  TLS_BASE_DIR="${PWD}/organizations/tlsca"
  PEER_MSP_BASE_DIR="${PWD}/organizations/peerOrganizations/hmg-kor"
  ORDERER_MSP_BASE_DIR="${PWD}/organizations/ordererOrganizations"
  TLS_CERTIFICATES="${PWD}/organizations/fabric-ca/tls-ca/tls-cert.pem"
  CA_NAME="tls-ca"
  CA_PORT="7052"
  CA_SERVER_ADDRESS="${CA_NAME}:${CA_PORT}"
  PEER_NUM=$1
  ORDERER_NUM=$2

  infoln "Enrolling the CA admin"
  mkdir -p $TLS_BASE_DIR

  export FABRIC_CA_CLIENT_HOME=$TLS_BASE_DIR

  commonEnroll "https://tls-ca-admin:tls-ca-adminpw@${CA_SERVER_ADDRESS}" $CA_NAME "${FABRIC_CA_CLIENT_HOME}/msp" "NA" "NA" $TLS_CERTIFICATES

  # 인증서 등록 / 발급 / 이름 변경(docker-compose 파일에 고정된 값 설정을 위함)
  ## commonRegister [caname] [node id] [node secret] [node type] [tls ca certificate]
  ## -> fabric-ca-client register --caname [caname] --id.name [node id] --id.secret [node secret] --id.type [node type] --id.attrs "hf.GenCRL=true" --tls.certfiles [tls ca certificate]

  ### PEER TLS 인증서 발급
  for (( i = 0; i < $PEER_NUM; i++ )); do

    TLS_CERT_DIR="${PEER_MSP_BASE_DIR}/peers/peer${i}.hmg-kor/tls"

    infoln "Registering peer${i} tls"
    commonRegister $CA_NAME "tls-peer${i}" "tls-peer${i}pw" "peer" $TLS_CERTIFICATES

    infoln "Generating the peer${i}-tls certificates"
    commonEnroll "https://tls-peer${i}:tls-peer${i}pw@${CA_SERVER_ADDRESS}" $CA_NAME "${TLS_CERT_DIR}" "peer${i}.hmg-kor" "tls" $TLS_CERTIFICATES

    cp ${TLS_CERT_DIR}/tlscacerts/* ${TLS_CERT_DIR}/ca.crt
    cp ${TLS_CERT_DIR}/signcerts/* ${TLS_CERT_DIR}/server.crt
    cp ${TLS_CERT_DIR}/keystore/* ${TLS_CERT_DIR}/server.key

  done

  mkdir -p ${PEER_MSP_BASE_DIR}/msp/tlscacerts
  cp ${PEER_MSP_BASE_DIR}/peers/peer0.hmg-kor/tls/tlscacerts/* ${PEER_MSP_BASE_DIR}/msp/tlscacerts/ca.crt

  mkdir -p ${PEER_MSP_BASE_DIR}/tlsca
  cp ${PEER_MSP_BASE_DIR}/peers/peer0.hmg-kor/tls/tlscacerts/* ${PEER_MSP_BASE_DIR}/tlsca/tlsca.hmg-kor-cert.pem

  mkdir -p ${PEER_MSP_BASE_DIR}/ca
  cp ${PEER_MSP_BASE_DIR}/peers/peer0.hmg-kor/msp/cacerts/* ${PEER_MSP_BASE_DIR}/ca/ca.hmg-kor-cert.pem

  ### ORDERER TLS 인증서 발급
  for (( i = 0; i < $ORDERER_NUM; i++ )); do

    TLS_CERT_DIR="${ORDERER_MSP_BASE_DIR}/orderers/orderer${i}/tls"

    infoln "Registering orderer${i} tls"
    commonRegister $CA_NAME "tls-orderer${i}" "tls-orderer${i}pw" "orderer" $TLS_CERTIFICATES

    infoln "Generating the orderer${i}-tls certificates"
    commonEnroll "https://tls-orderer${i}:tls-orderer${i}pw@${CA_SERVER_ADDRESS}" $CA_NAME "${ORDERER_MSP_BASE_DIR}/orderers/orderer${i}/tls" "orderer${i}" "tls" $TLS_CERTIFICATES

    cp ${TLS_CERT_DIR}/tlscacerts/* ${TLS_CERT_DIR}/ca.crt
    cp ${TLS_CERT_DIR}/signcerts/* ${TLS_CERT_DIR}/server.crt
    cp ${TLS_CERT_DIR}/keystore/* ${TLS_CERT_DIR}/server.key

  done

  mkdir -p ${ORDERER_MSP_BASE_DIR}/orderers/orderer0/msp/tlscacerts
  cp ${ORDERER_MSP_BASE_DIR}/orderers/orderer0/tls/tlscacerts/* ${ORDERER_MSP_BASE_DIR}/orderers/orderer0/msp/tlscacerts/tlsca.orderer-cert.pem

  mkdir -p ${ORDERER_MSP_BASE_DIR}/msp/tlscacerts
  cp ${ORDERER_MSP_BASE_DIR}/orderers/orderer0/tls/tlscacerts/* ${ORDERER_MSP_BASE_DIR}/msp/tlscacerts/tlsca.orderer-cert.pem

}

# 인증서 등록 공통 함수
function commonRegister() {

  if [ $# != 5 ]; then
    errorln "[registerEnroll.sh][commonRegister] Check your parameters."
    exit
  fi

  CA_NAME=$1
  ID=$2
  SECRET=$3
  NODE_TYPE=$4
  TLS_CERTS=$5

  set -x
  fabric-ca-client register --caname $CA_NAME --id.name $ID --id.secret $SECRET --id.type $NODE_TYPE --id.attrs "hf.GenCRL=true" --tls.certfiles $TLS_CERTS
  { set +x; } 2>/dev/null
  
}

# 인증서 발급 공통 함수
function commonEnroll() {

  if [ $# != 6 ]; then
    errorln "[registerEnroll.sh][commonEnroll] Check your parameters."
    exit
  fi

  CA_SERVER_ENROLL_URL=${1}
  CA_NAME=${2}
  MSP_PATH=${3}
  CSR_HOSTS=${4}
  ENROLLMENT_PROFILE=${5}
  TLS_CERTS=${6}

  if [ $CSR_HOSTS == "NA" ]; then
    CSR_HOSTS=""
  else 
    CSR_HOSTS="--csr.hosts $CSR_HOSTS"
  fi

  if [ $ENROLLMENT_PROFILE == "NA" ]; then
    ENROLLMENT_PROFILE=""
  else 
    ENROLLMENT_PROFILE="--enrollment.profile $ENROLLMENT_PROFILE"
  fi

  set -x
  fabric-ca-client enroll -u $CA_SERVER_ENROLL_URL --caname $CA_NAME -M $MSP_PATH $CSR_HOSTS $ENROLLMENT_PROFILE --tls.certfiles $TLS_CERTS
  { set +x; } 2>/dev/null
  
}