// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract RentalContract{
    address public landlord;
    address public tenant;
    uint public rentAmount;
    uint public depositAmount;
    uint public rentalDuration;
    uint public paymentInterval;
    bool public isAgreementActive;
    uint public totalRentpaid;
    uint public disputeAmount;
    bool public disputeReported;


    uint public agreementStartDate;
    uint public agreementEndDate;    
    uint public lastPaymentDate;

    constructor(
        uint _rentAmount,
        uint _depositAmount,
        uint _rentDuration,
        uint _paymentInterval
        
    ){
       landlord=msg.sender;
       rentAmount=_rentAmount;
       depositAmount=_depositAmount;
       rentalDuration=_rentDuration;
       isAgreementActive=false;
       paymentInterval=_paymentInterval;
       agreementStartDate = block.timestamp;  
       agreementEndDate = block.timestamp + _rentDuration;

    }


    // events

    event TenantEnterAgreement(address indexed  _address);
    event RentPaid(address tenant, uint amount,  uint totalRentpaid);
    event DisputeReported(uint disputeAmount);
    event AgreementEnded();


    // modifiers 

    modifier  IsActive(){
        require(isAgreementActive,"You have not enterd into Agreement");
        _;
    }

    modifier  OnlyOwner(){
        require(msg.sender == landlord, "OnlyLandlord Can raise dispute");
        _;
    }


    // function to  enter into agreement

    function enterAgreement() public payable {
        require(msg.sender != landlord, "Landlord cannot be the tenant");
        require(msg.value == rentAmount + depositAmount, "Insufficient  amount to enter in to Agreement.");

        tenant=msg.sender;
        isAgreementActive = true;

        totalRentpaid += rentAmount;

       emit TenantEnterAgreement(msg.sender);
    }
    
    function isDue() internal view  returns(bool){
         return  block.timestamp >= (lastPaymentDate + paymentInterval);
    }

    // function  to pay rent
    function payRent() public  payable  IsActive{
        require(msg.sender == tenant, "Only Tenant can Pay Tent");
        require(msg.value >= rentAmount,"Amount not sufficient");
        require(isDue(), "rent not Due for payment");
        totalRentpaid += rentAmount;
        lastPaymentDate=block.timestamp;
        emit RentPaid(msg.sender, rentAmount, totalRentpaid);
    }
    // function to report dispute
     
     function reportDispute(uint _AmountForDispute) public  OnlyOwner{
        require(_AmountForDispute >= disputeAmount, "dispute amount cannot exceed deposit amount");
        disputeAmount=_AmountForDispute;
        disputeReported = true;
        emit DisputeReported(disputeAmount);
     }

     function resolveDispute() public OnlyOwner  IsActive{
        require(disputeReported, "No dispute reported");

        uint amountToLandlord = disputeAmount;
        uint amountToTenant = depositAmount - disputeAmount;
        
        disputeAmount-amountToTenant;
        payable (tenant).transfer(amountToTenant);

        disputeAmount-amountToLandlord;
        payable (landlord).transfer(amountToLandlord);
      
       disputeReported=false;
       
     }

    //  function to end agreement
     function endAgreement() public {
        require(totalRentpaid >= rentAmount * rentalDuration, "Rental period not completed");
        if(!disputeReported){
            payable(tenant).transfer(depositAmount);
        }
        isAgreementActive=false;
        emit AgreementEnded();
     }
}