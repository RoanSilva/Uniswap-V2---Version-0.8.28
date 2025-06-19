// SPDX-License-Identifier: MIT
/**
 * @title ExampleFlashSwap
 * @notice Contrato para realizar flash swaps entre Uniswap V2 e V1, aproveitando arbitragem
 * @dev Implementa a interface IUniswapV2Callee para executar flash swaps, compatível com Solidity 0.8.28
 *      Inclui práticas de nível empresarial com segurança reforçada e documentação detalhada
 */
pragma solidity 0.8.28;

// Importações de interfaces e bibliotecas necessárias
import {IUniswapV2Callee} from '../interfaces/pool/IUniswapV2Callee.sol';
import {IUniswapV2Pair} from '../interfaces/pool/IUniswapV2Pair.sol';
import {IUniswapV1Factory} from '../interfaces/pool/IUniswapV1Factory.sol';
import {IUniswapV1Exchange} from '../interfaces/pool/IUniswapV1Exchange.sol';
import {IUniswapV2Router01} from '../interfaces/pool/IUniswapV2Router01.sol';
import {IERC20} from '../interfaces/utils/IERC20.sol';
import {IWETH} from '../interfaces/utils/IWETH.sol';
import {UniswapV2Library} from '../libraries/UniswapV2Library.sol';

/**
 * @notice Contrato principal para flash swaps entre Uniswap V2 e V1
 */
contract ExampleFlashSwap is IUniswapV2Callee {
    // Endereços imutáveis para economia de gás
    IUniswapV1Factory public immutable factoryV1;
    address public immutable factory;
    IWETH public immutable WETH;

    // Evento emitido quando o contrato é implantado
    event Deployed(address indexed factoryV1, address indexed factory, address indexed weth);

    /**
     * @notice Construtor para inicializar o contrato
     * @param _factoryV1 Endereço do factory Uniswap V1
     * @param _factory Endereço do factory Uniswap V2
     * @param router Endereço do roteador Uniswap V2
     * @dev Valida os endereços fornecidos e inicializa variáveis imutáveis
     */
    constructor(address _factoryV1, address _factory, address router) {
        require(_factoryV1 != address(0), "ExampleFlashSwap: ENDERECO_FACTORY_V1_INVALIDO");
        require(_factory != address(0), "ExampleFlashSwap: ENDERECO_FACTORY_V2_INVALIDO");
        require(router != address(0), "ExampleFlashSwap: ENDERECO_ROUTER_INVALIDO");

        factoryV1 = IUniswapV1Factory(_factoryV1);
        factory = _factory;
        //WETH = IWETH(IUniswapV2Router01(router).WETH());
        require(address(WETH) != address(0), "ExampleFlashSwap: ENDERECO_WETH_INVALIDO");

        emit Deployed(_factoryV1, _factory, address(WETH));
    }

    /**
     * @notice Função para receber ETH diretamente (fallback)
     * @dev Necessária para aceitar ETH de exchanges V1 e WETH
     */
    receive() external payable {}

    /**
     * @notice Executa a lógica de flash swap para arbitragem entre Uniswap V2 e V1
     * @dev Implementa a interface IUniswapV2Callee, realiza swap e repaga o flash loan
     * @param sender Endereço do iniciador do flash swap
     * @param amount0 Quantidade do token0 recebido
     * @param amount1 Quantidade do token1 recebido
     * @param data Dados adicionais (contém parâmetro de slippage)
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        // Validações iniciais
        require(msg.sender != address(0), "ExampleFlashSwap: REMETENTE_INVALIDO");
        require(sender != address(0), "ExampleFlashSwap: SENDER_INVALIDO");
        require(amount0 == 0 || amount1 == 0, "ExampleFlashSwap: ESTRATEGIA_UNIDIRECIONAL");

        // Determina os tokens e quantidades
        address[] memory path = new address[](2);
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        require(msg.sender == UniswapV2Library.pairFor(factory, token0, token1), "ExampleFlashSwap: PAR_V2_INVALIDO");

        path[0] = amount0 == 0 ? token0 : token1;
        path[1] = amount0 == 0 ? token1 : token0;
        uint256 amountToken = token0 == address(WETH) ? amount1 : amount0;
        uint256 amountETH = token0 == address(WETH) ? amount0 : amount1;

        require(path[0] == address(WETH) || path[1] == address(WETH), "ExampleFlashSwap: REQUER_PAR_WETH");

        IERC20 token = IERC20(path[0] == address(WETH) ? path[1] : path[0]);
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(address(token)));
        require(address(exchangeV1) != address(0), "ExampleFlashSwap: EXCHANGE_V1_INVALIDO");

        if (amountToken > 0) {
            // Caso: Swap de token para ETH
            (uint256 minETH) = abi.decode(data, (uint));
            require(minETH > 0, "ExampleFlashSwap: MIN_ETH_INVALIDO");

            // Aprova e realiza swap no Uniswap V1
            require(token.approve(address(exchangeV1), amountToken), "ExampleFlashSwap: APROVACAO_TOKEN_FALHOU");
            uint256 amountReceived = exchangeV1.tokenToEthSwapInput(amountToken, minETH, type(uint256).max);
            require(amountReceived > 0, "ExampleFlashSwap: SWAP_V1_FALHOU");

            // Calcula quantidade necessária para repagar o flash loan
            uint256 amountRequired = UniswapV2Library.getAmountsIn(factory, amountToken, path)[0];
            require(amountReceived > amountRequired, "ExampleFlashSwap: LUCRO_INSUFICIENTE");

            // Converte ETH para WETH e repaga o flash loan
            WETH.deposit{value: amountRequired}();
            require(WETH.transfer(msg.sender, amountRequired), "ExampleFlashSwap: TRANSFERENCIA_WETH_FALHOU");

            // Transfere o lucro restante para o sender
            (bool success, ) = sender.call{value: amountReceived - amountRequired}(new bytes(0));
            require(success, "ExampleFlashSwap: TRANSFERENCIA_LUCRO_FALHOU");
        } else {
            // Caso: Swap de ETH para token
            (uint256 minTokens) = abi.decode(data, (uint));
            require(minTokens > 0, "ExampleFlashSwap: MIN_TOKENS_INVALIDO");

            // Converte WETH para ETH e realiza swap no Uniswap V1
            WETH.withdraw(amountETH);
            uint256 amountReceived = exchangeV1.ethToTokenSwapInput{value: amountETH}(minTokens, type(uint256).max);
            require(amountReceived > 0, "ExampleFlashSwap: SWAP_V1_FALHOU");

            // Calcula quantidade necessária para repagar o flash loan
            uint256 amountRequired = UniswapV2Library.getAmountsIn(factory, amountETH, path)[0];
            require(amountReceived > amountRequired, "ExampleFlashSwap: LUCRO_INSUFICIENTE");

            // Repaga o flash loan e transfere o lucro restante
            require(token.transfer(msg.sender, amountRequired), "ExampleFlashSwap: TRANSFERENCIA_TOKEN_FALHOU");
            require(token.transfer(sender, amountReceived - amountRequired), "ExampleFlashSwap: TRANSFERENCIA_LUCRO_FALHOU");
        }
    }
}