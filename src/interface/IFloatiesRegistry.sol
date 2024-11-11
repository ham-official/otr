pragma solidity >=0.8.0 <0.9.0;

interface IFloatiesRegistry {
       struct RegistrationParams {
        address token;
        address registrant;
        bytes floatyHash;
    }
    function register(RegistrationParams memory params) external returns (address);
    function updateWl(address _addr, bool _value) external;
}