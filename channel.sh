#!/bin/bash
set -e

# Usage: ./channel.sh <ORG_NUMBER>
if [ -z "$1" ]; then
  echo "❌ Usage: $0 <ORG_NUMBER>"
  exit 1
fi

ORG="$1"

CHANNEL_NAME="my-channel"
CHANNEL_PROFILE="FabricProfile"
ARTIFACTS_DIR="/opt/home/artifacts"

function generateAnchorPeerUpdate() {
  local CORE_PEER_MSPCONFIGPATH="/opt/home/org$ORG/users/Admin@org$ORG.example.com/msp"
  local PORT=$((7051 + (ORG - 1) * 1000))
  local CORE_PEER_ADDRESS="peer0.org$ORG.example.com:${PORT}"
  local CORE_PEER_LOCALMSPID="Org${ORG}MSP"

  local ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

  echo "🌐 Generating anchor peer update for Org${ORG}"
  docker exec $ENV cli configtxgen -profile $CHANNEL_PROFILE -outputAnchorPeersUpdate ${ARTIFACTS_DIR}/Org${ORG}anchors.tx -channelID $CHANNEL_NAME -asOrg Org${ORG}
}

function createChannel() {
  local CORE_PEER_MSPCONFIGPATH="/opt/home/org1/users/Admin@org1.example.com/msp"
  local CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
  local CORE_PEER_LOCALMSPID="Org1MSP"

  local ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

  echo "📡 Creating channel '${CHANNEL_NAME}'..."
  docker exec $ENV cli peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f ${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx --outputBlock ${ARTIFACTS_DIR}/${CHANNEL_NAME}.block # --tls --cafile /opt/home/orderer/tls/ca.crt
  echo "✅ Channel '${CHANNEL_NAME}' created successfully."
}

function joinChannel() {
  local CORE_PEER_MSPCONFIGPATH="/opt/home/org1/users/Admin@org1.example.com/msp"
  local CORE_PEER_ADDRESS="peer0.org1.example.com:7051"
  local CORE_PEER_LOCALMSPID="Org1MSP"

  local ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

  echo ">>> peer0.org${ORG}.example.com joining channel '${CHANNEL_NAME}'"
  docker exec $ENV cli peer channel join -b ${ARTIFACTS_DIR}/${CHANNEL_NAME}.block
  echo "✅ peer0.org${ORG}.example.com joined the channel."
}

function updateAnchorPeers() {
  local CORE_PEER_MSPCONFIGPATH="/opt/home/org$ORG/users/Admin@org$ORG.example.com/msp"
  local PORT=$((7051 + (ORG - 1) * 1000))
  local CORE_PEER_ADDRESS="peer0.org$ORG.example.com:${PORT}"
  local CORE_PEER_LOCALMSPID="Org${ORG}MSP"

  local ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

  echo "🧭 Updating anchor peers..."
  docker exec $ENV cli peer channel update -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f ${ARTIFACTS_DIR}/Org${ORG}anchors.tx
  echo "🔄 Anchor peer updated for Org${ORG}"
}

function joinExistingChannel() {
  local CORE_PEER_MSPCONFIGPATH="/opt/home/org$ORG/users/Admin@org$ORG.example.com/msp"
  local PORT=$((7051 + (ORG - 1) * 1000))
  local CORE_PEER_ADDRESS="peer0.org$ORG.example.com:${PORT}"
  local CORE_PEER_LOCALMSPID="Org${ORG}MSP"

  local ENV="-e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"

  echo ">>> Getting the initial block for channel $CHANNEL_NAME ..."
  docker exec $ENV cli peer channel fetch 0 $ARTIFACTS_DIR/${CHANNEL_NAME}-join.block -o orderer.example.com:7050 -c ${CHANNEL_NAME}

  echo ">>> peer0.org${ORG}.example.com joining channel '${CHANNEL_NAME}'"
  docker exec $ENV cli peer channel join -b ${ARTIFACTS_DIR}/${CHANNEL_NAME}-join.block
  echo "✅ peer0.org${ORG}.example.com joined the channel."
}

# Only create channel with org1
if [ "$ORG" -eq 1 ]; then
  generateAnchorPeerUpdate
  createChannel
  joinChannel
  updateAnchorPeers
else
  echo "▶️ Detected Org${ORG} – will skip channel creation"
  generateAnchorPeerUpdate
  joinExistingChannel
  updateAnchorPeers
fi
