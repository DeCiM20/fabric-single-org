#!/bin/bash
set -e

CHANNEL_NAME="my-channel"
GENESIS_PROFILE="GenesisProfile"
CHANNEL_PROFILE="FabricProfile"
SYSTEM_CHANNEL="system-channel"
CORE_PEER_MSPCONFIGPATH="/opt/home/users/Admin@org1.example.com/msp"

function generate() {
  echo "🧱 Generating system genesis block..."
  mkdir -p artifacts
  docker exec cli configtxgen -profile $GENESIS_PROFILE -channelID $SYSTEM_CHANNEL -outputBlock /opt/home/artifacts/genesis.block
  
  echo "📦 Creating channel transaction..."
  docker exec cli configtxgen -profile $CHANNEL_PROFILE -outputCreateChannelTx /opt/home/artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME

  # echo "🌐 Generating anchor peer update for Org1"
  # docker exec cli configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate /opt/home/artifacts/Org1anchors.tx -channelID $CHANNEL_NAME -asOrg Org1
}

generate