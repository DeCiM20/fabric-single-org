#!/bin/bash
set -e

CHANNEL_NAME="my-channel"
GENESIS_PROFILE="GenesisProfile"
CHANNEL_PROFILE="FabricProfile"
SYSTEM_CHANNEL="system-channel"
ARTIFACTS_DIR="/opt/home/artifacts"

CORE_PEER_MSPCONFIGPATH="/opt/home/users/org1/Admin@org1.example.com/msp"
CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
CORE_PEER_LOCALMSPID="Org1MSP"

ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

# Generation of genesis block should be done by the initial org (In this case org1)
function generate() {
  echo "🧱 Generating system genesis block..."
  mkdir -p artifacts
  docker exec $ENV cli configtxgen -profile $GENESIS_PROFILE -channelID $SYSTEM_CHANNEL -outputBlock ${ARTIFACTS_DIR}/genesis.block
  
  echo "📦 Creating channel transaction..."
  docker exec $ENV cli configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx ${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

  # echo "🌐 Generating anchor peer update for Org1"
  # docker exec $ENV cli configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate ${ARTIFACTS_DIR}/Org1anchors.tx -channelID $CHANNEL_NAME -asOrg Org1
}

generate