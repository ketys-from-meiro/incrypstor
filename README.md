# InCrypstor - Artemis Capstone project by hodlmao

## Deploy to anvil

```
anvil --fork-url https://holy-purple-mansion.ethereum-goerli.discover.quiknode.pro/e591c7535f3b6f737c9848435eccb36b1568a868/ --fork-block-number 7965716
---
export PRIV_KEY=privateKeyFromAnvil
---
forge create src/ApprovedTokens.sol:ApprovedTokens --private-key=$PRIV_KEY
---
export APPROVED_TOKENS_CON_ADDRESS=
--- approve tokens
--- weth
cast send --private-key $PRIV_KEY $APPROVED_TOKENS_CON_ADDRESS "approveToken(address)" 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
--- uni
cast send --private-key $PRIV_KEY $APPROVED_TOKENS_CON_ADDRESS "approveToken(address)" 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
--- link
cast send --private-key $PRIVATE_KEY $APPROVED_TOKENS_CON_ADDRESS "approveToken(address)" 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
--- deploy tokens operations (exchangeProxy, weth, approvedTokens)
forge create src/TokensOperations.sol:TokensOperations --private-key=$PRIVATE_KEY --constructor-args 0xF91bB752490473B8342a3E964E855b9f9a2A668e 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 $APPROVED_TOKENS_CON_ADDRESS
export TOKENS_OPERATIONS_CON_ADDRESS=0x457b989132c0afE0Ffbf2b00062aE9E8d8048870
--- deploy strategies manager (address approvedTokens_, address tokensOperations_)
forge create src/StrategiesManager.sol:StrategiesManager --private-key=$PRIVATE_KEY --constructor-args $APPROVED_TOKENS_CON_ADDRESS $TOKENS_OPERATIONS_CON_ADDRESS
```
