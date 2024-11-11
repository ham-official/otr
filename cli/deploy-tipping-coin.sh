#!/bin/bash
source .env

forge script script/DeployTippy.s.sol:Run --rpc-url $HAM_RPC -vvvv --chain-id 5112 --broadcast
