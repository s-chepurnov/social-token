//TODO:
1. introduce PRICE variable
- (init val = 0,0001E)
- total sypply = uint256(3000000000000); 3trillions || 3*(10^12);
2. change PRICE by 3 events:
- every new user; price+=+0,000001E
- every new contract || investment project; price+=0,000001E
- every 1 000 000E transactions; price+=0,000001E
3. New user get 10 000 tokens for free

3. Token emission or transactions?
4. Token on Ethereum or our own blockchain
-how to make free transactions on Ethereum
-how to make free transactions on our own Blockchain
5. User couldnot spend their own tokens but only give to children?


Current task or last step description:

-implement buy(), sell() functions: msg.sender.transfer is it working?
-analyze registerNewUser() for attacks
-implement EventLogs
-check if this token will be available in wallet with correct price and name
-test everything
-create front-end for this project
-IDE for solidity with syntax highlighting (Vim with solidity plugin?)
