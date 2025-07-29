#!/bin/bash
set -e

export FABRIC_CFG_PATH=$PWD/config

function generate() {
  echo "🔧 Generating crypto material using cryptogen..."
  cryptogen generate --config ./config/crypto-config.yaml --output ./crypto
}

generate