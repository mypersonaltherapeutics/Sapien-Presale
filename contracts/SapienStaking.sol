pragma solidity ^0.4.18;

/// @author Stefan Ionescu - <codrinionescu@yahoo.com>

import "contracts/Owned.sol";
import "contracts/libraries/StringUtils.sol";
import "contracts/interfaces/SapienTokenInterface.sol";
import "contracts/storage/SPNStorage.sol";
import "contracts/libraries/SafeMath.sol";
import "contracts/interfaces/SapienStakingInterface.sol";

contract SapienStaking is SapienStakingInterface {

    using SafeMath for uint256;

    Owned private owned;

    SPNStorage _storage;

    address private sapienToken;

    address private upgradedContract;

    uint256 blockAttack = 0;

    mapping(string => uint256) private actions;

    modifier onlyOwner() {
        require(msg.sender == owned.getOwner());
        _;
    }

    modifier hatch() {

        require(blockAttack == 0);
        _;

    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
        
        require(msg.sender != address(0));    
    
        require(msg.sender == sapienToken);

        require(_storage != SPNStorage(0));

        _storage.increaseStakedSPNBalance(_from, _value);
      
        FallbackData(_data);
    
    }

    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    
        require(_to == sapienToken);
        require(_value <= _storage.getStakedBalance(msg.sender));
        require(_storage != SPNStorage(0));

        if (_to != address(0) && _to == sapienToken) {

          SapienTokenInterface receiver = SapienTokenInterface(_to);
          receiver.tokenFallback(msg.sender, _value, _data);

          _storage.decreaseStakedSPNBalance(msg.sender, _value);

          Transfer(msg.sender, _to, _value, _data);
        
          return true;

        } else if (_to != address(0) && _to == upgradedContract) {

            SapienStakingInterface upgrade = SapienStakingInterface(_to);
            upgrade.tokenFallback(msg.sender, _value, _data);

            _storage.decreaseStakedSPNBalance(msg.sender, _value);

            Upgraded(msg.sender, _value);

            return true;

        }

    }

    function SapienStaking(address _token, address _owned) {
        
        sapienToken = _token;
        owned = Owned(_owned);
        
    }

     function allowUpgrade(address _upgradeAddr) public onlyOwner {

        upgradedContract = _upgradeAddr;

    }

    function() payable {

        revert();

    }



    function changeOwned(address _owned) public onlyOwner {

        owned = Owned(_owned);

    }

    function changeActionCost(string _action, uint256 tokenAmount) public onlyOwner {

        actions[_action] = tokenAmount;

    }

    function changeSPNStorage(address _storageAddr) public onlyOwner {

        _storage = SPNStorage(_storageAddr);

    }

    function deleteAction(string _action) public onlyOwner {

        actions[_action] = 0;

    }

    function addAction(string actionName, uint256 cost) public onlyOwner {

        actions[actionName] = cost;

    }

    function changeTokenAddress(address _token) public onlyOwner {

        sapienToken = _token;

    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return _storage.getStakedBalance(_owner);
    }

    function tipUser(address _to, uint256 _amount) public hatch {

        require(_storage.getStakedBalance(msg.sender) >= _amount);
        require(_amount > 0 && _amount <= 10);
        require(_storage != SPNStorage(0));

        _storage.decreaseStakedSPNBalance(msg.sender, _amount);

        _storage.increaseStakedSPNBalance(_to, _amount);

        Tipped(msg.sender, _to, _amount);

    }

    function interactWithSapien(string _action) public hatch {

        require(actions[_action] > 0);
        require(_storage != SPNStorage(0));
        require(_storage.getStakedBalance(msg.sender) > actions[_action]);

        _storage.decreaseStakedSPNBalance(msg.sender, actions[_action]);

        MadeAnAction(msg.sender, _action, actions[_action]);

    }

    function escapeHatch() public onlyOwner {

        if (blockAttack == 0) {

            blockAttack = 1;

        } else {

            blockAttack = 0;

        }
            
    }

}