#!/bin/bash

set -e

export FABRIC_CFG_PATH=$PWD/config
PKG_PATH="/opt/home/chaincode/packaged/test-contract-2_1.0.0.tar.gz"
RAW_PATH="/opt/home/chaincode/raw/golang/test-contract-2"
CORE_PEER_MSPCONFIGPATH=/opt/home/users/Admin@org1.example.com/msp

# Package chaincode
function package() {
    docker exec cli peer lifecycle chaincode package ${PKG_PATH} --path ${RAW_PATH} --lang golang --label test-contract-2_1.0.0
}

# Install chaincode on --peerAddresses
function install() {
    docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer lifecycle chaincode install ${PKG_PATH} --peerAddresses peer0.org1.example.com:7051 # --tls --cafile /opt/home/peer/tls/ca.crt
}

# List of installed chaincodes
function installed() {
    local cmd="docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer lifecycle chaincode queryinstalled" # --tls --cafile /opt/home/peer/tls/ca.crt
    echo "Running: $cmd"
    eval "$cmd"
}

# Approve the chaincode
function approve() {
    PKG_ID=$1
    docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --channelID my-channel --name test-contract-2 --version 1.0.0 --package-id ${PKG_ID} --sequence 1 --peerAddresses peer0.org1.example.com:7051
}

# Chaincode approval details
function approved() {
    local cmd="docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer lifecycle chaincode queryapproved --channelID my-channel --name test-contract-2 --output json" # --tls --cafile /opt/home/peer/tls/ca.crt
    echo "Running: $cmd"
    eval "$cmd"
}

# Check commit readiness (Check for approvals)
function readiness() {
    local cmd="docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer lifecycle chaincode checkcommitreadiness --channelID my-channel --name test-contract-2 --version 1.0.0 --sequence 1 --output json" # --tls --cafile /opt/home/peer/tls/ca.crt
    echo "Running: $cmd"
    eval "$cmd"
}

# Commit chaincode to orderer
function commit() {
    docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID my-channel --name test-contract-2 --version 1.0.0 --sequence 1 # --tls --cafile /opt/home/peer/tls/ca.crt
}

# Help message
function help() {
    echo "Usage: $0 {package|install|approve|commit} [args]"
    echo "  package                  Package the chaincode"
    echo "  install                  Install the chaincode"
    echo "  approve <package_id>     Approve chaincode for org"
    echo "  commit                   Commit the chaincode"
    exit 1
}

# Entry point
case "$1" in
    package)
        package
        ;;
    install)
        install
        ;;
    installed)
        installed
        ;;
    approve)
        approve "$2"
        ;;
    approved)
        approved
        ;;
    readiness)
        readiness
        ;;
    commit)
        commit
        ;;
    *)
        help
        ;;
esac