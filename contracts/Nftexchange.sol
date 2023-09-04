// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./Extra.sol";
import "./SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTexchange is Extra {
    using SafeMath for uint256;
    string private _name;
    string private _version;
    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name, string version, address verifyingContract)";
    string private constant SELL_TYPE =
        "SellOrder(string _nonce, uint _startsAt, uint expiresAt, address _nftContract, uint256 _nftTokenId, address _paymentTokenContract, address _seller, address _royaltyPayTo, uint256 _sellerAmount,uint256 _feeAmount,uint256 _royaltyAmount,uint256 _totalAmount)";
    string private constant BUY_TYPE = 
        "BuyOrder(string _nonce,uint _startsAt,uint _expiresAt,address _nftContract,uint256 _nftTokenId,address _paymentTokenContract,address _buyer,address _royaltyPayTo,uint256 _sellerAmount,uint256 _feeAmount,uint256 _royaltyAmount,uint256 _totalAmount)";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));     
    bytes32 private constant SELL_TYPEHASH = keccak256(abi.encodePacked(SELL_TYPE));     
    bytes32 private constant BUY_TYPEHASH = keccak256(abi.encodePacked(BUY_TYPE));     

    bytes32 private DOMAIN_SEPARATOR;

    mapping(address => bool) public admins;
    address[] private allAdmins;
    uint16 public adminCount;
    bool public paused;

    struct SellOrder{
        string _nonce;
        uint _startsAt;
        uint _expiresAt;
        address _nftContract;
        uint256 _nftTokenId;
        address _paymentTokenContract;
        address _seller;
        address _royaltyPayTo;
        uint256 _sellerAmount;
        uint256 _feeAmount;
        uint256 _royaltyAmount;
        uint256 _totalAmount;
    }

    struct BuyOrder {
        string _nonce;
        uint _startsAt; 
        uint _expiresAt; 
        address _nftContract;
        uint256 _nftTokenId;
        address _paymentTokenContract; 
        address _buyer;
        address _royaltyPayTo;
        uint256 _sellerAmount; 
        uint256 _feeAmount;
        uint256 _royaltyAmount;
        uint256 _totalAmount;
    }

    event Exchange(uint256 indexed exchangeId);
    event Paused();
    event Unpaused();

    constructor(string memory _contractName, string memory _contractVersion, address _admin) {
        _name = _contractName;
        _version = _contractVersion;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(_name)),
            keccak256(bytes(_version)),
            address(this)
        ));
        admins[_admin] = true;
        allAdmins.push(_admin);
        adminCount++;
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function version() external view returns(string memory) {
        return _version;
    }

    function addAdmin(address _account) external onlyAdmin returns(bool) {
        admins[_account] = true;
        allAdmins.push(_account);
        adminCount++;
        return true;
    }

    function deleteAdmin(address _account) external onlyAdmin returns(bool) {
        require(_account != msg.sender, "You can't delete yourself from admin");
        require(admins[_account] == true, "No admin found with this address");
        delete admins[_account];
        removeArrayElement(allAdmins, _account);
        return true;
    }

    function getAllAdmins() external view onlyAdmin returns(address[] memory) {
        return allAdmins;
    }

    function withdrawNative(address payable to, uint256 amountInWei) external onlyAdmin returns(bool) {
        require(amountInWei <= address(this).balance, "Not enough fund");
        to.transfer(amountInWei);
        return true;
    }

    function withdrawToken(address _tokenContract, address to, uint256 amount) external onlyAdmin returns(bool) {
        IERC20 token = IERC20(_tokenContract);
        require(amount <= token.balanceOf(address(this)), "Not enough fund.");
        token.transfer(to, amount);
        return true;
    }

    function verifySeller(SellOrder memory sell, bytes memory sig) internal view returns(bool) {
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return sell._seller == ecrecover(hashSellOrder(sell), v, r, s);
    }

    function verifyBuyer(BuyOrder memory buy, bytes memory sig) internal view returns(bool) {
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return buy._buyer == ecrecover(hashBuyOrder(buy), v, r, s);
    }

    function buyCrypto(SellOrder memory sell, uint256 exchangeId, bytes memory _signature) 
    ifUnPaused payable external returns(bool) {
        require(sell._nftContract != address(0), "NFT Contract address can't be zero address!");
        require(sell._seller != address(0), "Seller address can't be zero address!");
        if(sell._royaltyAmount > 0) {
            require(sell._royaltyPayTo != address(0), "Royalty payout address can't be zero adress!");
        }

        IERC721 nft = IERC721(sell._nftContract);
        require(nft.isApprovedForAll(sell._seller, address(this)), "Sorry! Seller removed the approval for selling NFT.");
        require(nft.ownerOf(sell._nftTokenId) == sell._seller, "Sorry! Currently Seller doesn't own the NFT.");

        require(block.timestamp >= sell._startsAt, "Sell offer hasn't started yet!");
        require(block.timestamp < sell._expiresAt, "Sell offer expired.");

        require(msg.value > 0, "Zero amount sent.");
        require(sell._totalAmount == msg.value, "Total Amount and sent amount doesn't match.");
        require(verifySeller(sell, _signature), "Invalid seller signature.");

        emit Exchange(exchangeId);

        nft.transferFrom(sell._seller, msg.sender, sell._nftTokenId);
        payable(sell._seller).transfer(sell._sellerAmount);
        if(sell._royaltyAmount > 0) {
            payable(sell._royaltyPayTo).transfer(sell._royaltyAmount);
        }

        return true;
    }

    function sellNFT(BuyOrder memory buy, uint256 exchangeId, bytes memory _signature)
    ifUnPaused external returns(bool) {
        require(buy._nftContract != address(0), "NFT Contract address can't be zero address");
        require(buy._buyer != address(0), "Buyer address can't zero address");
        require(buy._paymentTokenContract != address(0), "Payment Token Contract address can't be zero address.");

        IERC20 token = IERC20(buy._paymentTokenContract);
        require(token.allowance(buy._buyer, address(this)) > buy._totalAmount, "Sorry buyer removed the approval for payment token transfer");
        require(token.balanceOf(buy._buyer) > buy._totalAmount, "Sorry! Currently you don't own the NFT.");

        IERC721 nft = IERC721(buy._nftContract);
        require(nft.isApprovedForAll(msg.sender, address(this)), "Sorry!! You removed the approval for selling NFT.");
        require(nft.ownerOf(buy._nftTokenId) == msg.sender, "Sorry!! Currently you don't own the NFT.");

        require(block.timestamp >= buy._startsAt, "Buy offer hasn't started yet!");
        require(block.timestamp < buy._expiresAt, "Buy offer expired");
        require(verifyBuyer(buy, _signature), "Invalid buyer signature.");

        emit Exchange(exchangeId);
        nft.transferFrom(msg.sender, buy._buyer, buy._nftTokenId);

        token.transferFrom(buy._buyer, msg.sender, buy._sellerAmount);
        token.transferFrom(buy._buyer, address(this), buy._feeAmount);

        if(buy._royaltyAmount > 0) {
            token.transferFrom(buy._buyer, buy._royaltyPayTo, buy._royaltyAmount);
        }

        return true;
    }

    function hashSellOrder(SellOrder memory sell) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                SELL_TYPEHASH,
                keccak256(bytes(sell._nonce)),
                sell._startsAt,
                sell._expiresAt,
                sell._nftContract,
                sell._nftTokenId,
                sell._paymentTokenContract,
                sell._seller,
                sell._royaltyPayTo,
                sell._sellerAmount,
                sell._feeAmount,
                sell._royaltyAmount,
                sell._totalAmount
            ))
        ));
    }

    function hashBuyOrder(BuyOrder memory buy) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                BUY_TYPEHASH,
                keccak256(bytes(buy._nonce)),
                buy._startsAt,
                buy._expiresAt,
                buy._nftContract,
                buy._nftTokenId,
                buy._paymentTokenContract,
                buy._buyer,
                buy._royaltyPayTo,
                buy._sellerAmount,
                buy._feeAmount,
                buy._royaltyAmount,
                buy._totalAmount
            ))
        ));
    }

    function splitSig(bytes memory sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r:= mload(add(sig, 32))
            s:= mload(add(sig, 64))
            v:= byte(0, mload(add(sig, 96)))
        }  
    }

    function pauseContract() external onlyAdmin returns(bool) {
        paused = true;
        emit Paused();
        return true;
    }

    function unPauseContract() external onlyAdmin returns (bool) {
        paused = false;
        emit Unpaused();
        return true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Unauthorized");
        _;
    }

    modifier ifPaused() {
        require(paused == false, "Sorry!! The contract is paused currently.");
        _;
    }
    modifier ifUnPaused() {
        require(paused == true, "Sorry!! The contract is paused currently.");
        _;
    }

}
