/// NOTE Original ERC-20
interface IERC20 {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function decimals() external view returns (uint8);
	function totalSupply() external view returns (uint256);
	function balanceOf(address _owner) external view returns (uint256 balance);
	function transfer(address _to, uint256 _value) external returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
	function approve(address _spender, uint256 _value) external returns (bool success);
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

/// NOTE ERC-20-like
interface IERC20Like {
	function decimals() external view returns (uint8);
	function totalSupply() external view returns (uint64);
	function balanceOf(address user) external view returns (uint64);
	function transfer(address from, address to, uint64 amount) external;
	function approve(address spender, address delegate, uint64 amount) external;
	// TODO: implement allowance
	// function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}