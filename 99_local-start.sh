#!/bin/bash

#******************************************************************#
# 테스트용, 삭제 예정
#******************************************************************#

echo
echo "======================================="
echo " > Generate Artifacts / Start HLF Node"
echo "  ./01_network.sh up"
echo "======================================="
echo
./01_network.sh up

if [ $? -eq 1 ]; then
  echo "failed command [./01_network.sh up]"
  exit 1
fi

sleep 3

echo
echo "==========================="
echo " > Generate Channel Tx"
echo "  ./02_channel.sh generate"
echo "==========================="
echo

./02_channel.sh generate

if [ $? -eq 1 ]; then
  echo "failed command [./02_channel.sh generate]"
  exit 1
fi

echo
echo "==========================="
echo " > Create Channel"
echo "  ./02_channel.sh create"
echo "==========================="
echo

./02_channel.sh create

if [ $? -eq 1 ]; then
  echo "failed command [./02_channel.sh create]"
  exit 1
fi

sleep 10

echo
echo "==========================="
echo " > Join Channel"
echo "  ./02_channel.sh join"
echo "==========================="
echo

./02_channel.sh join

if [ $? -eq 1 ]; then
  echo "failed command [./02_channel.sh join]"
  exit 1
fi

sleep 5

echo
echo "==========================="
echo " > Set Anchor Peer"
echo "  ./02_channel.sh setanchor"
echo "==========================="
echo

./02_channel.sh setanchor

if [ $? -eq 1 ]; then
  echo "failed command [./02_channel.sh setanchor]"
  exit 1
fi

echo
echo "============================="
echo " > Generate Chaincode Package"
echo "  ./03_chaincode.sh package"
echo "============================="
echo

./03_chaincode.sh package

if [ $? -eq 1 ]; then
  echo "failed command [./03_chaincode.sh package]"
  exit 1
fi

echo
echo "============================="
echo " > Install Chaincode Package"
echo "  ./03_chaincode.sh install"
echo "============================="
echo

./03_chaincode.sh install

if [ $? -eq 1 ]; then
  echo "failed command [./03_chaincode.sh install]"
  exit 1
fi

echo
echo "============================="
echo " > Approve Chaincode"
echo "  ./03_chaincode.sh approve"
echo "============================="
echo

./03_chaincode.sh approve

if [ $? -eq 1 ]; then
  echo "failed command [./03_chaincode.sh approve]"
  exit 1
fi

echo
echo "============================="
echo " > Commit Chaincode Package"
echo "  ./03_chaincode.sh commit"
echo "============================="
echo

./03_chaincode.sh commit

if [ $? -eq 1 ]; then
  echo "failed command [./03_chaincode.sh commit]"
  exit 1
fi

echo
echo "============================="
echo " > Test Chaincode : Invoke"
echo "============================="
echo

cd test
./01-CreateSample.sh T001
