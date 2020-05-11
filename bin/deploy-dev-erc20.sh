#!/bin/bash

. .setup_env
cd contracts/
echo "Deploying ERC20 token for localhost"
yarn --silent deploy-dev-erc20 > $ZKSYNC_HOME/etc/tokens/localhost.json