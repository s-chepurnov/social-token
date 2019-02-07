I.//TODO:
1. introduce PRICE variable
- (init val = 0,0001E)
- total supply = uint256(3000000000000); 3trillions || 3*(10^12);
2. change PRICE by 3 events:
- every new user; price+=+0,000001E
- every new contract || investment project; price+=0,000001E
- every 1 000 000E transactions; price+=0,000001E
3. New user get 10 000 tokens for free?
3. Token emission, send to addresses then give addresses to people for free?

4?. User could not spend their own tokens but only give to children?
5?. User could spend only 1/4 of their tokens in a year
6?. Foundation could spend only 1/4 of the fund in a year  

II.Current task or last step description:

-if user send last money, counter--

-const price in EUR, how to implement it?

-test contract with test data from readme.md

-check if this token will be available in wallet with correct price and name

-implement buy(), sell() functions: msg.sender.transfer is it working?

-analyze registerNewUser() for attacks

-test everything

