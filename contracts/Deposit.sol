// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./Passbook.sol";
import "./util/IBEP20.sol";
import "./Comptroller.sol";
import "./Reserve.sol";

contract Deposit	{

	bytes32 adminDeposit;
    address adminDepositAddress;

    TokenList markets = TokenList(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Comptroller comptroller = Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Reserve reserve = Reserve(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
    Passbook passbook = passbook(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
	IBEP20 token;

	event NewDeposit(address indexed account, bytes32 indexed market, bytes32 commmitment, uint indexed amount);

	constructor()	{
		adminDepositAddress = msg.sender;
	}

	function Deposit(bytes32 market_, bytes32 commitment_, uint amount_) external returns (bool success)	{
		address marketAddress;
		_preDepositProcess(msg.sender, market_, amount_);
		token.transfer(msg.sender, payable(address(reserve)), amount_);		
		_updateYield(msg.sender, market_, commitment_);
		_processDeposit(msg.sender,market_,commitment_,amount_);
		emit NewDeposit(msg.sender, market_,commitment_,amount_);
		return bool(success);
	}
	
	}
	function savingsBalance() external{}
	function withdrawFunds() external{}
	function convertDeposit() external 	{}
	function convertYield() external 	{}

	function _preDepositProcess( address account_, bytes32 market_, uint amount_) internal 	{
		_isMarketSupported(market_);
		_hasAccount(account_);
		_connectMarket(market_, amount_);
		return this;
	}

	function _hasAccount(address account_) internal  {
		SavingsAcccount storage savingsAccount = passbook.savingsPassbook[account_];
		
		if (savingsAccount.accOpenTime = 0)	{
			savingsAccount.accOpenTime = block.timestamp;
			savingsAccount.account = account_;
		} 
    }

	function _isMarketSupported(bytes32 market_) internal 	{
		require(!markets.tokenSupportCheck[market_] = false, "Unsupported market");
	}

	function _connectMarket(bytes32 market_, uint amount_) internal {
		MarketData  marketData = markets.indTokenDetails[market_];
		marketAddress = marketData.tokenAddress;
		token = IBEP20(marketAddress);
		amount_ *= marketData.decimals;
	}

	function _updateYield(address account_, bytes32 market_, bytes32 commitment_) internal{
        
        Yield storage yield = passbook.indYieldRecords[account_][market_][commitment_];
        DepositRecords storage deposit = passbook.indDepositRecord[account_][market_][commitment_];
        APY storage apy = comptroller.indAPYRecords[commitment_];

		uint index = yield.oldLengthAccruedYield - 1;
		uint blockNum = yield.oldBlockNum;
		uint aggregateYield = yield.accruedYield;

		if (apy.blockNumbers[index] < blockNum)	{

			uint newIndex = index+1;
			aggregateYield += (apy.blockNumbers[newIndex] - blockNum)*apy.apyChangeRecords[index]/100;
			
			for (uint i = newIndex; i<apy.apyChangeRecords.length; i++)	{
				uint blockDiff = apy.blockNumbers[i+1] - apy.blockNumbers[i] ;
				aggregateYield += blockDiff**apy.apyChangeRecords[newIndex]/100;
			}
		} else if (apy.blockNumbers[index] == blockNum)	{
			for (uint i = index; i<apy.apyChangeRecords.length; i++)	{
				uint blockDiff = apy.blockNumbers[i+1] - apy.blockNumbers[i] ;
				aggregateYield += blockDiff**apy.apyChangeRecords[index]/100;
			}
		}
		if (block.number > apy.blockNumbers[apy.blockNumbers.length-1])	{
			aggregateYield += (block.Number - apy.blockNumbers[apy.blockNumbers.length-1])*apy.apyChangeRecords[apy.blockNumbers.length-1]/100;
		}
		yield.accruedYield += deposit.amount*aggregatedYield;
		yield.oldLengthAccruedYield = apy.blockNumbers.length;
		yield.oldBlockNum = block.number;
    }

	function _processDeposit(address account_, bytes32 market_, bytes32 commitment_, uint amount_) internal {
		DepositRecords storage deposit = passbook.indDepositRecord[account_][market_][commitment__];
		SavingsAccount storage savingsAccount = passbook.savingsPassbook[account_];
		Yield storage yield = passbook.indYieldRecord[account_][market_][commitment_];
		APY storage apy = comptroller.indAPYRecords[commitment_];
		
        
        if (deposit.firstDeposit == 0 && commitment_!=comptroller.commitment[0])  {
			if (savingsAccount.deposits.length == 0)	{
				uint id = 1;
			} else {
				uint id = savingsAccount.deposits.length+1;
			}
            deposit = DepositRecords({id:id,firstDeposit:block.number,market_:market_, commitment_:commitment_, amount_:amount_,lastDeposit:block.number});
            savingsAccount.deposits.push(deposit);
			yield = Yield({
				id:id,
				oldLengthAccruedYield: apy.blockNumbers.length,
				oldBlockNum: block.number,
				market:market_,
				accruedYield: 0,
				timelock: true,
				timelockValidity: 86400,
				timelockActivated: false,
				activatedBlockNum:0
			});

        }	else if (deposit.firstDeposit == 0 && commitment_==comptroller.commitment[0])  {
			if (savingsAccount.deposits.length == 0)	{
				uint id = 1;
			} else {
				uint id = savingsAccount.deposits.length+1;
			}
			uint id = savingsAccount.deposits.length;
            deposit = DepositRecords({id:id,firstDeposit:block.number,market_:market_, commitment_:commitment_, amount_:amount_,lastDeposit:block.number});
            savingsAccount.deposits.push(deposit);
			yield = Yield({
				id:id,
				oldLengthAccruedYield: apy.blockNumbers.length,
				oldBlockNum: block.number,
				market:market_,
				accruedYield: 0,
				timelock: false,
				timelockValidity: 0,
				timelockActivated: true,
				activatedBlockNum:0
			});

        }	else if (!deposit.firstDeposit = 0)    {
            deposit.amount_ += amount_;
            deposit.lastDeposit = block.number;
			savingsAccount.deposits[deposit.id].amount += amount_;
			savingsAccount.deposits[deposit.id].lastDeposit += block.number;
        }
    }

	modifier  auth() {
		require(msg.sender == adminDepositAddress, "Only Admin can access this function");
		_;
	}
}