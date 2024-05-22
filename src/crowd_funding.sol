//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Crowd funding by running campaigns
/// @author Shahidkhan
/// @notice You can use this contract for crowd funding events
contract crowdFunding {
    IERC20 public immutable usdt;

    constructor(address USDT) {
        usdt = IERC20(USDT);
    }

    uint256 public count;
    struct Campaign {
        address CampaignOwner;
        string purpose;
        uint256 startAt;
        uint256 goal;
        uint256 donationAmount;
        uint256 endAt;
        bool claimed;
    }
    mapping(uint256 => Campaign) public campaigners;
    mapping(uint256 => mapping(address => uint256)) public donationAmount;

    /// @notice startCampaign to raise funds
    /// @dev endtime of campaign should be more than starting time
    /// @param _purpose The purpose for which raising funds
    /// @param _goal The minimum target of amount set by campaignOwner for funds
    /// @param _endAt The maximum time limit when campaign will get over
    function startCampaign(
        string memory _purpose,
        uint256 _goal,
        uint256 _endAt
    ) external {
        require(block.timestamp <= _endAt, "you can not end before start");
        count += 1;
        campaigners[count] = Campaign({
            CampaignOwner: msg.sender,
            purpose: _purpose,
            startAt: block.timestamp,
            goal: _goal,
            donationAmount: 0,
            endAt: _endAt,
            claimed: false
        });
    }
    /// @notice donate funds for running campaigns
    /// @dev donated funds will be stored into smart contract until it reached to the goal
    /// @param _id the id of campaign in which donor wants to donate
    /// @param _amount the amount which donor wants to donate
    function donate(uint _id, uint _amount) external {
        Campaign storage campaign = campaigners[_id];
        require(block.timestamp <= campaign.endAt, "Campaign ended");
        require(usdt.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(
            usdt.allowance(msg.sender, address(this)) >= _amount,
            "Insufficient Allowance"
        );
        usdt.transferFrom(msg.sender, address(this), _amount);
        campaign.donationAmount += _amount;
        donationAmount[_id][msg.sender] += _amount;
    }

    ///@notice checking for refunds if it is not reached to required goal
    ///@param _id the id of particular campaign to check for refunds
    ///@return boolean value after checking donationAmount compared to goal
    function checkRefund(uint _id) public view returns (bool) {
        Campaign memory campaign = campaigners[_id];
        if (campaign.donationAmount <= campaign.goal) {
            return true;
        } else {
            return false;
        }
    }

    ///@notice claiming donation for campaign after it ends
    ///@dev After claiming funds will be transfered in campaignowner's account from smart contract
    ///@param _id the id of particular campaign to claim funds
    function claimOfDonation(uint _id) external {
        Campaign storage campaign = campaigners[_id];
        require(
            msg.sender == campaign.CampaignOwner,
            "Caller is not an campaign owner"
        );
        require(block.timestamp >= campaign.endAt , "Campaign still running");
        require(
            campaign.donationAmount >= campaign.goal,
            "Can't get required funds"
        );
        usdt.transfer(msg.sender, campaign.donationAmount);
        campaign.claimed = true;
    }

    ///@notice getting refund of whatever donor has donated in campaign
    ///@dev donors will get their amount only after campaign ends and at that time it did'nt receive required funds
    ///@param _id the id of particular campaign to cget refund from it
    function refund(uint _id) external {
        Campaign memory campaign = campaigners[_id];
        require(block.timestamp >= campaign.endAt , "Campaign still running");
        require(
            campaign.donationAmount <= campaign.goal,
            "Your campaign got enough funds"
        );
        uint balance = donationAmount[_id][msg.sender];
        usdt.transfer(msg.sender, balance);
        donationAmount[_id][msg.sender] = 0;
    }
}
