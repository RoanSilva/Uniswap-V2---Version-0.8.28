// SPDX-License-Identifier: MIT
/**
 * @title ExampleSwapToPrice
 * @notice Contrato para realizar swaps otimizados em pares Uniswap V2 com base em preços verdadeiros externos
 * @dev Executa swaps para maximizar lucros, compatível com Solidity 0.8.28
 *      Implementa padrões de nível empresarial com segurança reforçada e documentação detalhada
 */
pragma solidity 0.8.28;

// Importações de interfaces e bibliotecas necessárias
import {IUniswapV2Pair} from '../interfaces/pool/IUniswapV2Pair.sol';
import {IUniswapV2Router01} from '../interfaces/pool/IUniswapV2Router01.sol';
import {IERC20} from '../interfaces/utils/IERC20.sol';
import {Babylonian} from '@uniswap/lib/contracts/libraries/Babylonian.sol';
import {TransferHelper} from '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import {SafeMath} from '../libraries/SafeMath.sol';
import {UniswapV2Library} from '../libraries/UniswapV2Library.sol';
import {UniswapV2LiquidityMathLibrary} from '../libraries/UniswapV2LiquidityMathLibrary.sol';

/**
 * @notice Contrato principal para swaps otimizados com preço alvo
 */
contract ExampleSwapToPrice {
    using SafeMath for uint256;

    /// @notice Endereço do roteador Uniswap V2
    IUniswapV2Router01 public immutable router;
    /// @notice Endereço do factory Uniswap V2
    address public immutable factory;

    /// @notice Evento emitido quando o contrato é implantado
    /// @param factory Endereço do factory Uniswap V2
    /// @param router Endereço do roteador Uniswap V2
    event Deployed(address indexed factory, address indexed router);

    /// @notice Evento emitido quando um swap é realizado
    /// @param tokenIn Endereço do token de entrada
    /// @param tokenOut Endereço do token de saída
    /// @param amountIn Quantidade de entrada
    /// @param to Endereço do destinatário
    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        address indexed to
    );

    /**
     * @notice Construtor para inicializar o contrato
     * @param factory_ Endereço do factory Uniswap V2
     * @param router_ Endereço do roteador Uniswap V2
     * @dev Valida os endereços fornecidos e inicializa variáveis imutáveis
     */
    constructor(address factory_, IUniswapV2Router01 router_) {
        require(factory_ != address(0), "ExampleSwapToPrice: ENDERECO_FACTORY_INVALIDO");
        require(address(router_) != address(0), "ExampleSwapToPrice: ENDERECO_ROUTER_INVALIDO");

        factory = factory_;
        router = router_;

        emit Deployed(factory_, address(router_));
    }

    /**
     * @notice Realiza um swap para atingir um preço alvo, maximizando lucros
     * @param tokenA Endereço do primeiro token do par
     * @param tokenB Endereço do segundo token do par
     * @param truePriceTokenA Preço verdadeiro do tokenA
     * @param truePriceTokenB Preço verdadeiro do tokenB
     * @param maxSpendTokenA Máximo a gastar de tokenA
     * @param maxSpendTokenB Máximo a gastar de tokenB
     * @param to Endereço do destinatário dos tokens de saída
     * @param deadline Timestamp limite para a transação
     * @dev O chamador deve aprovar este contrato para gastar o token de entrada
     */
    function swapToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 maxSpendTokenA,
        uint256 maxSpendTokenB,
        address to,
        uint256 deadline
    ) external {
        require(tokenA != address(0) && tokenB != address(0), "ExampleSwapToPrice: ENDERECO_TOKEN_INVALIDO");
        require(tokenA != tokenB, "ExampleSwapToPrice: TOKENS_IDENTICOS");
        require(truePriceTokenA != 0 && truePriceTokenB != 0, "ExampleSwapToPrice: PRECO_ZERO");
        require(maxSpendTokenA != 0 || maxSpendTokenB != 0, "ExampleSwapToPrice: GASTO_ZERO");
        require(to != address(0), "ExampleSwapToPrice: ENDERECO_DESTINO_INVALIDO");
        require(deadline >= block.timestamp, "ExampleSwapToPrice: PRAZO_EXPIRADO");

        // Determina a direção do swap e a quantidade de entrada
        bool aToB;
        uint256 amountIn;
        {
            (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
            (aToB, amountIn) = UniswapV2LiquidityMathLibrary.computeProfitMaximizingTrade(
                truePriceTokenA,
                truePriceTokenB,
                reserveA,
                reserveB
            );
            require(amountIn > 0, "ExampleSwapToPrice: QUANTIDADE_ENTRADA_ZERO");
        }

        // Limita a quantidade de entrada ao máximo permitido
        uint256 maxSpend = aToB ? maxSpendTokenA : maxSpendTokenB;
        if (amountIn > maxSpend) {
            amountIn = maxSpend;
        }

        // Define tokens de entrada e saída
        address tokenIn = aToB ? tokenA : tokenB;
        address tokenOut = aToB ? tokenB : tokenA;

        // Transfere os tokens de entrada para o contrato
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        // Aprova o roteador para gastar os tokens
        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        // Configura o caminho do swap
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Executa o swap
        router.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin: confiando na matemática testada
            path,
            to,
            deadline
        );

        emit SwapExecuted(tokenIn, tokenOut, amountIn, to);
    }
}