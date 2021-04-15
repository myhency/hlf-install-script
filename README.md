오토에버 HLF(Hyperledger Fabric) 기반 블록체인 시스템
=====================================================

# HLF 정보

+ VERSION : 2.2
+ ORDERING SERVICE : raft
+ PEER STATE DB : couchdb

# HLF STAGE 별 구성

## local(Single host)

+ VM1
   + PEER      - peer0.hmg-kor peer1.hmg-kor peer2.hmg-kor
   + STATEDB   - couchdb0 couchdb1 couchdb2
   + ORDERER   - orderer0 orderer1 orderer2
   + CA SERVER - ca.hmg-kor ca.orderer-org tls-ca

## dev / prod

+ VM1
   + PEER0    - peer0.hmg-kor
   + STATEDB  - couchdb0
   + ORDERER0 - orderer0
   + TLS CA   - tls-ca
+ VM2
   + PEER1     - peer1.hmg-kor
   + STATEDB  - couchdb1
   + ORDERER1  - orderer1
   + CA SERVER - ca.hmg-kor ca.orderer-org
+ VM3
   + PEER2     - peer2.hmg-kor
   + STATEDB  - couchdb2
   + ORDERER2  - orderer2

# HLF 구동

## local STAGE

### 사전 작업

+ CA Server hosts 지정(/etc/hosts) - **[VM1]**
   + [VM1 IP] ca.hmg-kor ca.orderer-org ca.tls-ca

+ HLF Configuration 파일 수정(conf) - **[VM1]**
   + local STAGE 지정(STAGE=local)
   + VM 별, 수행 서비스 지정(CA_SERVER & NODES)
      + *CA_SERVER="tls-ca ca.hmg-kor ca.orderer-org"*
      + *NODES="orderer0 orderer1 orderer2 peer0.hmg-kor peer1.hmg-kor peer2.hmg-kor couchdb0 couchdb1 couchdb2 cli"*
   + 수행 Docker compose 파일 지정
      + *COMPOSE_FILE_NODE=${COMPOSE_FILE_PATH}/docker-compose-peer-single.yaml*
      + *COMPOSE_FILE_COUCH=${COMPOSE_FILE_PATH}/docker-compose-couch-single.yaml*

### 구동 절차

1. CA Server 구동 및 Crypto material 생성
```
   ./01_network.sh up -ca
```

2. HLF Node 구동
```
  ./01_network.sh up -node 
```

3. Channel Tx 생성 - **[VM1]**
```
   ./02_channel.sh generate
```

4. Chanenl 생성
```
   ./02_channel.sh create
```

5. Channel 가입
```
   ./02_channel.sh join
```

6. Chaincode 패키징
```
   ./03_chaincode.sh package
```

7. Chaincode 설치
```
   ./03_chaincode.sh install
```

8. Chaincode 승인
```
   ./03_chaincode.sh approve
```

9. Chaincode 배포
```
   ./03_chaincode.sh commit
```

***
**일괄수행 : 99_local-start.sh**
***

## dev / prod STAGE

### 사전 작업

+ CA Server hosts 지정(/etc/hosts) - **[VM1]**
   + [VM2 IP] ca.hmg-kor ca.orderer-org
   + [VM1_IP] ca.tls-ca

+ HLF Configuration 파일 수정(conf) - **[VM1 & VM2 & VM3]**
   + STAGE 지정(개발계 : STAGE=dev / 운영계 : STAGE=prod)
   + VM 별, 수행 서비스 지정(CA_SERVER & NODES)
      + VM1
         + *CA_SERVER="tls-ca"*
         + *NODES="orderer0 peer0.hmg-kor couchdb0 cli"*
      + VM2
         + *CA_SERVER="ca.hmg-kor ca.orderer-org"*
         + *NODES="orderer1 peer1.hmg-kor couchdb1"*
      + VM3
         + *CA_SERVER=""*
         + *NODES="orderer2 peer2.hmg-kor couchdb2"*
   + 수행 Docker compose 파일 지정
      + *COMPOSE_FILE_NODE=${COMPOSE_FILE_PATH}/docker-compose-peer.yaml*
      + *COMPOSE_FILE_COUCH=${COMPOSE_FILE_PATH}/docker-compose-couch.yaml*

## 구동 절차 - [수행 VM]

1. CA Server 구동 - **[VM2]**

2. CA Server TLS 인증서 전달 - **[VM2 -> VM1]**

3. TLS CA Server 구동 및 Crypto material 생성 - **[VM1]**
```
   ./01_network.sh up -ca
```

4. 각 HLF Node(peer / orderer)로 **[3]**에서 생성된 MSP, TLS 전달 - **[VM1 -> VM2 & VM3]**

5. HLF Node 구동 - **[VM1 & VM2 & VM3]**
```
  ./01_network.sh up -node 
```

6. Channel Tx 생성 - **[VM1]**
```
   ./02_channel.sh generate
```

7. Chanenl 생성
```
   ./02_channel.sh create
```

8. Channel 가입
```
   ./02_channel.sh join
```

9. Chaincode 패키징
```
   ./03_chaincode.sh package
```

10. Chaincode 설치
```
   ./03_chaincode.sh install
```

11. Chaincode 승인
```
   ./03_chaincode.sh approve
```

12. Chaincode 배포
```
   ./03_chaincode.sh commit
```
