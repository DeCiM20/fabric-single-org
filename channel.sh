#!/bin/bash
set -e

CHANNEL_NAME="my-channel"
CORE_PEER_MSPCONFIGPATH="/opt/home/users/Admin@org1.example.com/msp"

function createChannel() {
  echo "📡 Creating channel '${CHANNEL_NAME}'..."
  docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer channel create -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f /opt/home/artifacts/${CHANNEL_NAME}.tx --outputBlock /opt/home/artifacts/${CHANNEL_NAME}.block # --tls --cafile /opt/home/orderer/tls/ca.crt
  echo "✅ Channel '${CHANNEL_NAME}' created successfully."
}

function joinChannel() {
  echo ">>> ${CORE_PEER_ADDRESS} joining channel '${CHANNEL_NAME}'"
  docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer channel join -b /opt/home/artifacts/${CHANNEL_NAME}.block
  echo "✅ ${CORE_PEER_ADDRESS} joined the channel."
}

function updateAnchorPeers() {
  echo "🧭 Updating anchor peers..."
  docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH cli peer channel update -o orderer.example.com:7050 -c ${CHANNEL_NAME} -f /opt/home/artifacts/Org1anchors.tx
  echo "🔄 Anchor peer updated for Org1"
}

createChannel
joinChannel
# updateAnchorPeers