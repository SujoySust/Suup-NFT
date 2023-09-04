pragma solidity 0.8.14;

contract NFTexchange {
    using SafeMath for uint256;
    uint256 public chainId;
    string private _name;
    string private _version;
    string private constant EIP712_DOMAIN =
        "EIP712Domain(string name, string version, uint256 chainId, address verifyingContract)";
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
        uint256 chain;
        assembly {
            chain := chainId();
        }
        chainId = chain;
        _name = _contractName;
        _version = _contractVersion;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(_name)),
            keccak256(bytes(_version)),
            chainId,
            address(this)
        ));
        admins[_admin] = true;
        allAdmins.push(_admin);
        adminCount++;
    }

    function verifySeller(SellOrder memory sell, bytes memory sig) internal view returns(bool) {
        (bytes32, r, bytes32 s, uint8 v) = splitSig(sig);
        return sell._seller == ecrecover(hashSellOrder(sell), v, r, s);
    }

    function verifyBuyer(BuyOrder memory buy, bytes memory sig) internal view returns(bool) {
        (bytes32 r, bytes32 s, uint8 v) = splitSig(sig);
        return buy._buyer == ecrecover(hashBuyOrder(buy), v, r, s);
    }

    function hashSellOrder(SellOrder memory sell) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                SELL_TYPEHASH,
                keccak256(bytes(sell._nonce)),
                sell._startsAt
                sell._expiresAt
                sell._nftContract
                sell._nftTokenId
                sell._paymentTokenContract
                sell._seller
                sell._royaltyPayTo
                sell._sellerAmount
                sell._feeAmount
                sell._royaltyAmount
                sell._totalAmount
            ));
        ));
    }

    function hashBuyOrder(BuyOrder memory buy) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                BUY_TYPEHASH,
                keccak256(bytes(buy._nonce)),
                buy._startsAt
                buy._expiresAt
                buy._nftContract
                buy._nftTokenId
                buy._paymentTokenContract
                buy._buyer
                buy._royaltyPayTo
                buy._sellerAmount
                buy._feeAmount
                buy._royaltyAmount
                buy._totalAmount
            ));
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

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Unauthorized");
        -;
    }

    modifier ifPaused() {
        require(paused == false, "Sorry!! The contract is paused currently.");
        _;
    }

}
