// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Extra.sol";

contract SUUPNFT is ERC721URIStorage, Extra {
    uint8 private tokenStartId = 1;
    mapping (address => bool) private admins;
    address[] private allAdmins;
    uint16 public adminCount;

    mapping(uint256 => string) private _tokenURIs;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory _name, string memory _symbol, address _admin) ERC721(_name, _symbol) {
        admins[_admin] = true;
        allAdmins.push(_admin);
        adminCount++;
    }

    function addAdmin(address _account) external onlyAdmin returns(bool) {
        admins[_account] = true;
        allAdmins.push(_account);
        adminCount++;
        return true;
    }

    function deleteAdmin(address _account) external onlyAdmin returns(bool) {
        require(_account != msg.sender, "You can not delete your account");
        removeArrayElement(allAdmins, _account);
        adminCount --;
        delete admins[_account];
        return true;
    }

    function adminLists() public view onlyAdmin returns (address[] memory) {
        return allAdmins;
    }

    function totalSupply() external view onlyAdmin returns(uint256) {
        return _tokenIds.current();
    }

    function mint(address recipient, string memory uri) public onlyAdmin returns(uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _tokenURIs[newItemId] = uri;
        return newItemId;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    function withdrawNative(address payable to, uint256 amountInWei) onlyAdmin public returns (bool) {
        require(amountInWei <= address(this).balance, "Not enough fund!");
        to.transfer(amountInWei);
        return true;
    }

    modifier onlyAdmin(){
        require(admins[msg.sender] == true , "Unauthorized request");
        _;
    }
}
