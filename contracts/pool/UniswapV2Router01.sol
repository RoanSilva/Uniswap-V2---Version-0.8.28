// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2Factory} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import {TransferHelper} from '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import {IUniswapV2Pair} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import {UniswapV2Library} from '../libraries/UniswapV2Library.sol';
import {IUniswapV2Router01} from '../interfaces/pool/IUniswapV2Router01.sol';
import {IERC20} from '../interfaces/utils/IERC20.sol';
import {IWETH} from '../interfaces/utils/IWETH.sol';

/**
 * @title UniswapV2Router01
 * @author Uniswap V2 Router
 * @notice Contrato roteador para interagir com pares Uniswap V2, suportando adição/remoção de liquidez e swaps de tokens.
 * @dev Implementa funcionalidades para adicionar e remover liquidez, realizar swaps com tokens ERC-20 e ETH, e consultar preços.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções, estados e modificadores.
 *      - Verificações explícitas de segurança (ex.: endereços inválidos, quantidades insuficientes, paths inválidos).
 *      - Uso de TransferHelper para transferências seguras de tokens e ETH.
 *      - Suporte a WETH para swaps envolvendo ETH.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
contract UniswapV2Router01 is IUniswapV2Router01 {
    // ================================
    //           Estados
    // ================================

    /// @notice Endereço imutável da factory Uniswap V2.
    address public immutable factory;

    /// @notice Endereço imutável do contrato WETH.
    address public immutable WETH;

    // ================================
    //           Modificadores
    // ================================

    /**
     * @notice Garante que a transação não ultrapasse o deadline especificado.
     * @dev Reverte se o timestamp atual for maior ou igual ao deadline.
     * @param deadline Timestamp limite para a transação.
     */
    modifier ensure(uint256 deadline) {
        require(
            deadline >= block.timestamp,
            "UniswapV2Router01: EXPIRED_DEADLINE"
        );
        _;
    }

    // ================================
    //           Construtor
    // ================================

    /**
     * @notice Inicializa o contrato com os endereços da factory e do WETH.
     * @dev Reverte se os endereços fornecidos forem address(0).
     *      Os endereços são marcados como imutáveis para otimização de gás.
     * @param _factory Endereço da factory Uniswap V2.
     * @param _WETH Endereço do contrato WETH.
     */
    constructor(address _factory, address _WETH) {
        require(
            _factory != address(0),
            "UniswapV2Router01: INVALID_FACTORY_ADDRESS"
        );
        require(_WETH != address(0), "UniswapV2Router01: INVALID_WETH_ADDRESS");
        factory = _factory;
        WETH = _WETH;
    }

    // ================================
    //           Funções de Recebimento
    // ================================

    /**
     * @notice Permite que o contrato receba ETH apenas do contrato WETH.
     * @dev Reverte se o chamador não for o contrato WETH.
     */
    receive() external payable {
        require(msg.sender == WETH, "UniswapV2Router01: ETH_FROM_NON_WETH");
    }

    // ================================
    //           Funções Internas
    // ================================

    /**
     * @notice Calcula as quantidades ótimas para adicionar liquidez a um par.
     * @dev Cria o par se não existir e ajusta as quantidades com base nas reservas atuais.
     *      Usa UniswapV2Library para consultar reservas e calcular quantidades ótimas.
     *      Reverte se as quantidades mínimas não forem atendidas.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @param amountADesired Quantidade desejada do tokenA.
     * @param amountBDesired Quantidade desejada do tokenB.
     * @param amountAMin Quantidade mínima do tokenA.
     * @param amountBMin Quantidade mínima do tokenB.
     * @return amountA Quantidade final do tokenA a ser usada.
     * @return amountB Quantidade final do tokenB a ser usada.
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) private returns (uint256 amountA, uint256 amountB) {
        require(
            tokenA != address(0) && tokenB != address(0),
            "UniswapV2Router01: INVALID_TOKEN_ADDRESS"
        );
        require(tokenA != tokenB, "UniswapV2Router01: IDENTICAL_TOKENS");
        require(
            amountADesired > 0 && amountBDesired > 0,
            "UniswapV2Router01: INVALID_DESIRED_AMOUNT"
        );

        // Cria o par se não existir
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "UniswapV2Router01: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                require(
                    amountAOptimal <= amountADesired,
                    "UniswapV2Router01: EXCESSIVE_A_AMOUNT"
                );
                require(
                    amountAOptimal >= amountAMin,
                    "UniswapV2Router01: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @notice Realiza um swap de tokens ao longo de um path de pares.
     * @dev Assume que a quantidade inicial já foi transferida para o primeiro par.
     *      Executa swaps sequenciais, transferindo tokens para o próximo par ou destinatário final.
     *      Reverte se o path for inválido ou o swap falhar.
     * @param amounts Array com as quantidades de entrada/saída para cada par.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param _to Endereço que receberá os tokens de saída.
     */
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) private {
        require(path.length >= 2, "UniswapV2Router01: INVALID_PATH_LENGTH");
        require(
            _to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );

        for (uint256 i; i < path.length - 1; ++i) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // ================================
    //           Funções de Liquidez
    // ================================

    /**
     * @notice Adiciona liquidez a um par de tokens e cria tokens de liquidez.
     * @dev Transfere tokens do chamador para o par e chama mint no par.
     *      Cria o par se não existir. Reverte se as quantidades mínimas não forem atendidas.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @param amountADesired Quantidade desejada do tokenA.
     * @param amountBDesired Quantidade desejada do tokenB.
     * @param amountAMin Quantidade mínima do tokenA.
     * @param amountBMin Quantidade mínima do tokenB.
     * @param to Endereço que receberá os tokens de liquidez.
     * @param deadline Timestamp limite para a transação.
     * @return amountA Quantidade de tokenA usada.
     * @return amountB Quantidade de tokenB usada.
     * @return liquidity Quantidade de tokens de liquidez criados.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /**
     * @notice Adiciona liquidez a um par token/ETH e cria tokens de liquidez.
     * @dev Converte ETH em WETH, transfere tokens para o par e chama mint.
     *      Reembolsa ETH excedente. Reverte se as quantidades mínimas não forem atendidas.
     * @param token Endereço do token ERC-20.
     * @param amountTokenDesired Quantidade desejada do token.
     * @param amountTokenMin Quantidade mínima do token.
     * @param amountETHMin Quantidade mínima de ETH.
     * @param to Endereço que receberá os tokens de liquidez.
     * @param deadline Timestamp limite para a transação.
     * @return amountToken Quantidade de token usada.
     * @return amountETH Quantidade de ETH usada.
     * @return liquidity Quantidade de tokens de liquidez criados.
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        require(
            token != address(0),
            "UniswapV2Router01: INVALID_TOKEN_ADDRESS"
        );
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(msg.value > 0, "UniswapV2Router01: INSUFFICIENT_ETH_VALUE");

        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        require(
            IWETH(WETH).transfer(pair, amountETH),
            "UniswapV2Router01: WETH_TRANSFER_FAILED"
        );
        liquidity = IUniswapV2Pair(pair).mint(to);

        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    /**
     * @notice Remove liquidez de um par de tokens e devolve tokens subjacentes.
     * @dev Transfere tokens de liquidez para o par, chama burn e verifica quantidades mínimas.
     *      Reverte se as quantidades devolvidas forem insuficientes.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @param liquidity Quantidade de tokens de liquidez a queimar.
     * @param amountAMin Quantidade mínima do tokenA.
     * @param amountBMin Quantidade mínima do tokenB.
     * @param to Endereço que receberá os tokens.
     * @param deadline Timestamp limite para a transação.
     * @return amountA Quantidade de tokenA devolvida.
     * @return amountB Quantidade de tokenB devolvida.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        require(
            tokenA != address(0) && tokenB != address(0),
            "UniswapV2Router01: INVALID_TOKEN_ADDRESS"
        );
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(liquidity > 0, "UniswapV2Router01: INVALID_LIQUIDITY_AMOUNT");

        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        require(
            IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity),
            "UniswapV2Router01: TRANSFER_FAILED"
        );
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(
            amountA >= amountAMin,
            "UniswapV2Router01: INSUFFICIENT_A_AMOUNT"
        );
        require(
            amountB >= amountBMin,
            "UniswapV2Router01: INSUFFICIENT_B_AMOUNT"
        );
    }

    /**
     * @notice Remove liquidez de um par token/ETH e devolve tokens e ETH.
     * @dev Remove liquidez, converte WETH em ETH e transfere para o destinatário.
     *      Reverte se as quantidades devolvidas forem insuficientes.
     * @param token Endereço do token ERC-20.
     * @param liquidity Quantidade de tokens de liquidez a queimar.
     * @param amountTokenMin Quantidade mínima do token.
     * @param amountETHMin Quantidade mínima de ETH.
     * @param to Endereço que receberá os tokens e ETH.
     * @param deadline Timestamp limite para a transação.
     * @return amountToken Quantidade de token devolvida.
     * @return amountETH Quantidade de ETH devolvida.
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        require(
            token != address(0),
            "UniswapV2Router01: INVALID_TOKEN_ADDRESS"
        );
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(liquidity > 0, "UniswapV2Router01: INVALID_LIQUIDITY_AMOUNT");

        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @notice Remove liquidez de um par de tokens usando assinatura EIP-2612.
     * @dev Aprova a transferência via permit e chama removeLiquidity.
     *      Reverte se a assinatura for inválida ou as quantidades forem insuficientes.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @param liquidity Quantidade de tokens de liquidez a queimar.
     * @param amountAMin Quantidade mínima do tokenA.
     * @param amountBMin Quantidade mínima do tokenB.
     * @param to Endereço que receberá os tokens.
     * @param deadline Timestamp limite para a transação.
     * @param approveMax Se true, aprova uint256.max; caso contrário, aprova apenas a liquidez.
     * @param v Componente da assinatura ECDSA.
     * @param r Componente da assinatura ECDSA.
     * @param s Componente da assinatura ECDSA.
     * @return amountA Quantidade de tokenA devolvida.
     * @return amountB Quantidade de tokenB devolvida.
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountA, uint256 amountB) {
        require(
            tokenA != address(0) && tokenB != address(0),
            "UniswapV2Router01: INVALID_TOKEN_ADDRESS"
        );
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(liquidity > 0, "UniswapV2Router01: INVALID_LIQUIDITY_AMOUNT");

        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    /**
     * @notice Remove liquidez de um par token/ETH usando assinatura EIP-2612.
     * @dev Aprova a transferência via permit e chama removeLiquidityETH.
     *      Reverte se a assinatura for inválida ou as quantidades forem insuficientes.
     * @param token Endereço do token ERC-20.
     * @param liquidity Quantidade de tokens de liquidez a queimar.
     * @param amountTokenMin Quantidade mínima do token.
     * @param amountETHMin Quantidade mínima de ETH.
     * @param to Endereço que receberá os tokens e ETH.
     * @param deadline Timestamp limite para a transação.
     * @param approveMax Se true, aprova uint256.max; caso contrário, aprova apenas a liquidez.
     * @param v Componente da assinatura ECDSA.
     * @param r Componente da assinatura ECDSA.
     * @param s Componente da assinatura ECDSA.
     * @return amountToken Quantidade de token devolvida.
     * @return amountETH Quantidade de ETH devolvida.
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 amountToken, uint256 amountETH) {
        require(
            token != address(0),
            "UniswapV2Router01: INVALID_TOKEN_ADDRESS"
        );
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(liquidity > 0, "UniswapV2Router01: INVALID_LIQUIDITY_AMOUNT");

        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // ================================
    //           Funções de Swap
    // ================================

    /**
     * @notice Realiza um swap de uma quantidade exata de tokens por outra.
     * @dev Transfere tokens de entrada para o primeiro par e executa o swap ao longo do path.
     *      Reverte se a quantidade de saída for menor que o mínimo especificado.
     * @param amountIn Quantidade de tokens de entrada.
     * @param amountOutMin Quantidade mínima de tokens de saída.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function swapExactTokensForTokens(
        address[] calldata path,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(amountIn > 0, "UniswapV2Router01: INVALID_INPUT_AMOUNT");
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(path.length >= 2, "UniswapV2Router01: INVALID_PATH_LENGTH");

        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router01: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @notice Realiza um swap para receber uma quantidade exata de tokens.
     * @dev Calcula a quantidade de entrada necessária e executa o swap.
     *      Reverte se a quantidade de entrada exceder o máximo especificado.
     * @param amountOut Quantidade exata de tokens de saída desejada.
     * @param amountInMax Quantidade máxima de tokens de entrada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        require(amountOut > 0, "UniswapV2Router01: INVALID_OUTPUT_AMOUNT");
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(path.length >= 2, "UniswapV2Router01: INVALID_PATH_LENGTH");

        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router01: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @notice Realiza um swap de ETH por uma quantidade de tokens.
     * @dev Converte ETH em WETH, transfere para o primeiro par e executa o swap.
     *      Reverte se o path não começar com WETH ou a saída for insuficiente.
     * @param amountOutMin Quantidade mínima de tokens de saída.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(msg.value > 0, "UniswapV2Router01: INSUFFICIENT_ETH_VALUE");
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(path.length >= 2, "UniswapV2Router01: INVALID_PATH_LENGTH");
        require(path[0] == WETH, "UniswapV2Router01: INVALID_PATH");

        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router01: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        require(
            IWETH(WETH).transfer(
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            ),
            "UniswapV2Router01: WETH_TRANSFER_FAILED"
        );
        _swap(amounts, path, to);
    }

    /**
     * @notice Realiza um swap de tokens por uma quantidade exata de ETH.
     * @dev Executa o swap, converte WETH em ETH e transfere para o destinatário.
     *      Reverte se o path não terminar com WETH ou a entrada exceder o máximo.
     * @param amountOut Quantidade exata de ETH desejada.
     * @param amountInMax Quantidade máxima de tokens de entrada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá o ETH.
     * @param deadline Timestamp limite para a transação.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        require(amountOut > 0, "UniswapV2Router01: INVALID_OUTPUT_AMOUNT");
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(path.length >= 2, "UniswapV2Router01: INVALID_PATH_LENGTH");
        require(
            path[path.length - 1] == WETH,
            "UniswapV2Router01: INVALID_PATH"
        );

        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router01: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @notice Realiza um swap de uma quantidade exata de tokens por ETH.
     * @dev Executa o swap, converte WETH em ETH e transfere para o destinatário.
     *      Reverte se o path não terminar com WETH ou a saída for insuficiente.
     * @param amountIn Quantidade de tokens de entrada.
     * @param amountOutMin Quantidade mínima de ETH de saída.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá o ETH.
     * @param deadline Timestamp limite para a transação.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256[] memory amounts) {
        require(amountIn > 0, "UniswapV2Router01: INVALID_INPUT_AMOUNT");
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(path.length >= 2, "UniswapV2Router01: INVALID_PATH_LENGTH");
        require(
            path[path.length - 1] == WETH,
            "UniswapV2Router01: INVALID_PATH"
        );

        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router01: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @notice Realiza um swap de ETH por uma quantidade exata de tokens.
     * @dev Converte ETH em WETH, executa o swap e reembolsa ETH excedente.
     *      Reverte se o path não começar com WETH ou a entrada exceder o valor enviado.
     * @param amountOut Quantidade exata de tokens de saída desejada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(amountOut > 0, "UniswapV2Router01: INVALID_OUTPUT_AMOUNT");
        require(
            to != address(0),
            "UniswapV2Router01: INVALID_RECIPIENT_ADDRESS"
        );
        require(path.length >= 2, "UniswapV2Router01: INVALID_PATH_LENGTH");
        require(path[0] == WETH, "UniswapV2Router01: INVALID_PATH");

        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= msg.value,
            "UniswapV2Router01: EXCESSIVE_INPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        require(
            IWETH(WETH).transfer(
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            ),
            "UniswapV2Router01: WETH_TRANSFER_FAILED"
        );
        _swap(amounts, path, to);
        if (msg.value > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        }
    }

    // ================================
    //           Funções de Cotação
    // ================================

    /**
     * @notice Calcula a quantidade de tokenB equivalente a uma quantidade de tokenA com base nas reservas.
     * @dev Usa UniswapV2Library para realizar o cálculo.
     * @param amountA Quantidade de tokenA.
     * @param reserveA Reserva do tokenA no par.
     * @param reserveB Reserva do tokenB no par.
     * @return amountB Quantidade equivalente de tokenB.
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure override returns (uint256 amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    /**
     * @notice Calcula a quantidade de saída para uma quantidade de entrada em um par.
     * @dev Usa UniswapV2Library para realizar o cálculo, considerando a taxa de 0.3%.
     * @param amountIn Quantidade de entrada.
     * @param reserveIn Reserva do token de entrada.
     * @param reserveOut Reserva do token de saída.
     * @return amountOut Quantidade de saída.
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     * @notice Calcula a quantidade de entrada necessária para uma quantidade de saída em um par.
     * @dev Usa UniswapV2Library para realizar o cálculo, considerando a taxa de 0.3%.
     * @param amountOut Quantidade de saída desejada.
     * @param reserveIn Reserva do token de entrada.
     * @param reserveOut Reserva do token de saída.
     * @return amountIn Quantidade de entrada necessária.
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure override returns (uint256 amountIn) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /**
     * @notice Calcula as quantidades de saída para uma quantidade de entrada ao longo de um path.
     * @dev Usa UniswapV2Library para realizar os cálculos em cada par do path.
     * @param amountIn Quantidade de entrada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) public view override returns (uint256[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @notice Calcula as quantidades de entrada necessárias para uma quantidade de saída ao longo de um path.
     * @dev Usa UniswapV2Library para realizar os cálculos em cada par do path.
     * @param amountOut Quantidade de saída desejada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @return amounts Array com as quantidades de entrada/saída para cada par.
     */
    function getAmountsIn(
        uint256 amountOut,
        address[] memory path
    ) public view override returns (uint256[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {}
}