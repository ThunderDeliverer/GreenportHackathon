# Greenport youself smart contract notes

The following contract is adapted to be used in a simple use case where we trust our gateway node. It takes into account the current lack of support, or rather the inability to use light clients, in current version of Casper protocol since their node discovery is broken.

While the full ERC20 token would need to use addresses in stead of user IDs, we opted for the latter, until we can be certain that light nodes are operational an can be used on mobile devices. The moment this happens we will transition to the full ERC20 token, keeping all of the user data stored in this SC.

Comments are made up to the solidity standards and should be sufficient for understanding the code.

##### For a user new to the Ethereum development:
To deploy the SC, you need to have Mist browser installed. There you have to synchronise the Ropsten testnet blockchain and create a user account. Afterwards copy the content of **Greenport.sol** file to the deployment window in the Contracts menu and select `greenport()` function to deploy the SC.
