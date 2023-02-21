// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract SwapProxyStorage {
    bool public constant isSwapProxy = true;

    address public owner;
    address public implementation;
    address public swapRouter;
    address public swapFeeAddress;

    uint public swapCommission;
    uint public liqCommission;
}

contract SwapProxyImplementation is SwapProxyStorage {
    using SafeMath for uint;

    receive() external payable {}

    // events
    event swapTokenForToken(        
        address tokenFrom,
        address tokenTo,
        uint    amountIn,
        uint    amountOut,
        address to,
        uint    deadline
    );
    event swapEthForToken(
        address tokenTo,
        uint    amountIn,
        uint    amountOut,
        address to,
        uint    deadline
    );
    event swapTokenForEth(
        address tokenFrom,
        uint    amountIn,
        uint    amountOut,
        address to,
        uint    deadline
    );

    // setters
    function setSwapRouter(address newSwapRouter) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        swapRouter = newSwapRouter;
    }
    function setSwapFeeAddress(address newSwapFeeAddress) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        swapFeeAddress = newSwapFeeAddress;
    }
    function setCommission(uint newSwapCommission, uint newLiqCommission) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        swapCommission = newSwapCommission;
        liqCommission = newLiqCommission;
    }

    // withdraw
    function withdraw(address payable to) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        if (address(this).balance > 0) {
            to.transfer(address(this).balance);
        }
    }
    function withdrawToken(address tokenAddress, address to, uint256 amount) external {
        require(msg.sender == owner, "UNAUTHORIZED");
        IERC20 token = IERC20(tokenAddress);
        token.transfer(to, amount);
    }

    // swap proxy
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        (address tokenA, address tokenB) = (path[0], path[path.length-1]);
        uint tokenBBalance = IERC20(tokenB).balanceOf(address(this));

        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenA, swapRouter, amountIn);

        IPancakeRouter02 r = IPancakeRouter02(swapRouter);
        r.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);

        uint tokenBBalanceNew = IERC20(tokenB).balanceOf(address(this));
        uint swapAmount = tokenBBalanceNew - tokenBBalance;
        uint commAmount = swapAmount * swapCommission / 10000;

        TransferHelper.safeTransfer(tokenB, to, (swapAmount - commAmount));
        TransferHelper.safeTransfer(tokenB, swapFeeAddress, commAmount);

        emit swapTokenForToken(tokenA, tokenB, amountIn, swapAmount, to, deadline);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable {
        (address tokenB) = (path[path.length-1]);
        uint tokenBBalance = IERC20(tokenB).balanceOf(address(this));

        IPancakeRouter02 r = IPancakeRouter02(swapRouter);
        r.swapExactETHForTokensSupportingFeeOnTransferTokens(amountOutMin, path, address(this), deadline);

        uint tokenBBalanceNew = IERC20(tokenB).balanceOf(address(this));
        uint swapAmount = tokenBBalanceNew - tokenBBalance;
        uint commAmount = swapAmount * swapCommission / 10000;

        TransferHelper.safeTransfer(tokenB, to, (swapAmount - commAmount));
        TransferHelper.safeTransfer(tokenB, swapFeeAddress, commAmount);

        emit swapEthForToken(tokenB, msg.value, swapAmount, to, deadline);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        (address tokenA) = (path[0]);
        uint ethBalance = address(this).balance;

        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(tokenA, swapRouter, amountIn);

        IPancakeRouter02 r = IPancakeRouter02(swapRouter);
        r.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);

        uint ethBalanceNew = address(this).balance;
        uint swapAmount = ethBalanceNew - ethBalance;
        uint commAmount = swapAmount * swapCommission / 10000;

        TransferHelper.safeTransferETH(to, (swapAmount - commAmount));
        TransferHelper.safeTransferETH(swapFeeAddress, commAmount);

        emit swapTokenForEth(tokenA, amountIn, swapAmount, to, deadline);
    }

}


