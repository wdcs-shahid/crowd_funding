//SPDX_License_Identifier:MIT

pragma solidity ^0.8.0;

import {Test , console} from "forge-std/Test.sol";
import {crowdFunding} from "../src/crowd_funding.sol";
import {MyToken} from "../src/USDT.sol";

contract testFunding is Test{
    crowdFunding public crowdfunding;
    MyToken public usdt;

    address public owner1 = address(1111);
    address public owner2 = address(2222);
    address public donor1 = address(3333);
    address public donor2 = address(4444);
    address public donor3 = address(5555);
    address public donor4 = address(6666);
    address public donor5 = address(7777);

    
    function setUp() public{
        usdt = new MyToken();
        crowdfunding = new crowdFunding(address(usdt));

        usdt.mint(donor1,100000);
        usdt.mint(donor2,100000);
        usdt.mint(donor3,100000);
        usdt.mint(donor4,100000);
        usdt.mint(donor5,100000);
    }

   function store_dataOfCampaigners(address _owner , uint _goal , uint _endAt) public{
   vm.prank(_owner);
   crowdfunding.startCampaign("education", _goal, _endAt);
   }
   
   function store_dataOfDonor(address _owner , uint _assumeTime , uint _id , uint _amount) public {
    vm.startPrank(_owner);
    vm.warp(_assumeTime);
    assertGe(usdt.balanceOf(_owner) , _amount, "Insufficient balance");
    usdt.approve(address(crowdfunding), _amount);
    crowdfunding.donate(_id, _amount);
    vm.stopPrank();
   }

   function test_startCampaign() public {
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfCampaigners(owner2, 15000 , 10 days);
   }
   
  function  test_donate() public {
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 2 days, 1 , 2000);
   store_dataOfDonor(donor2, 3 days, 1 , 3000);
   store_dataOfDonor(donor3, 4 days, 1 , 5000);
  }  
    
 function testFail_donate_FortimeEnd() public {
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 12 days, 1 , 2000);
 }
    
function testFail_donate_ForBalance() public {
    store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 12 days, 1 , 1000000);

}
   
function test_claimOfDonation() public{
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 2 days, 1 , 2000);
   store_dataOfDonor(donor2, 3 days, 1 , 3000);
   store_dataOfDonor(donor3, 4 days, 1 , 5000);

   vm.startPrank(owner1);
   vm.warp(block.timestamp + 11 days);
   crowdfunding.claimOfDonation(1);
   assertEq(usdt.balanceOf(owner1) , 10000);
   vm.stopPrank();
}

function testFail_claimOfDonation() public{
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 2 days, 1 , 2000);
   store_dataOfDonor(donor2, 3 days, 1 , 3000);
   store_dataOfDonor(donor3, 4 days, 1 , 4000);

   vm.startPrank(owner1);
   vm.warp(block.timestamp + 11 days);
   crowdfunding.claimOfDonation(1);
   vm.stopPrank();
}

function testFail_claimOfDonationForOwner() public {
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 2 days, 1 , 2000);
   store_dataOfDonor(donor2, 3 days, 1 , 3000);
   store_dataOfDonor(donor3, 4 days, 1 , 4000);

   vm.startPrank(donor1);
   vm.warp(block.timestamp + 11 days);
   crowdfunding.claimOfDonation(1);
   vm.stopPrank();
}

function test_refund() public{
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 2 days, 1 , 2000);
   store_dataOfDonor(donor2, 3 days, 1 , 3000);

   vm.startPrank(donor1);
   vm.warp(block.timestamp + 11 days);
   uint previousBalanceDonor1 = usdt.balanceOf(donor1);
   crowdfunding.refund(1);
   assertEq(previousBalanceDonor1 + 2000, usdt.balanceOf(donor1));
   vm.stopPrank();
   
   vm.startPrank(donor2);
   vm.warp(block.timestamp + 11 days);
   uint previousBalanceDonor2 = usdt.balanceOf(donor2);
   crowdfunding.refund(1);
   assertEq(previousBalanceDonor2 + 3000, usdt.balanceOf(donor2));
   vm.stopPrank();
}

function testFail_refund_ForOwner() public{  
   store_dataOfCampaigners(owner1 , 10000 , 10 days);
   store_dataOfDonor(donor1, 2 days, 1 , 2000);

   vm.startPrank(donor2);
   vm.warp(block.timestamp + 11 days);
   uint previousBalanceDonor1 = usdt.balanceOf(donor1);
   crowdfunding.refund(1);
   assertEq(previousBalanceDonor1 + 2000, usdt.balanceOf(donor1));
   vm.stopPrank();

}

}
