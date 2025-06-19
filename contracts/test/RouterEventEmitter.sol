// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2Router01} from '../interfaces/pool/IUniswapV2Router01.sol';

/**
 * @title RouterEventEmitter
 * @notice Contrato que realiza chamadas delegadas a um roteador Uniswap V2 e emite eventos com as quantidades resultantes.
 * @dev Utiliza delegatecall para executar funções de swap do roteador especificado e emite o evento Amounts com os valores retornados.
 *      Suporta swaps de tokens e ETH conforme a interface IUniswapV2Router01.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções e eventos.
 *      - Verificações explícitas de segurança (ex.: endereços válidos, paths válidos, chamadas bem-sucedidas).
 *      - Organização modular com seções claras.
 *      Compatível com Solidity 0.8.28, aproveitando otimizações modernas e verificações nativas de segurança.
 */
contract RouterEventEmitter {
    // ================================
    //           Eventos
    // ================================

    /**
     * @notice Emite as quantidades retornadas por uma chamada de swap.
     * @param amounts Array contendo as quantidades de entrada/saída do swap.
     */
    event Amounts(uint256[] amounts);

    // ================================
    //           Funções de Recebimento
    // ================================

    /**
     * @notice Permite que o contrato receba ETH.
     * @dev Usado para suportar swaps envolvendo ETH (ex.: swapExactETHForTokens, swapETHForExactTokens).
     */
    receive() external payable {}

    // ================================
    //           Funções de Swap
    // ================================

    /**
     * @notice Realiza um swap de uma quantidade exata de tokens por outra, emitindo as quantidades resultantes.
     * @dev Executa delegatecall para a função swapExactTokensForTokens do roteador e emite evento Amounts.
     *      Reverte se o roteador for inválido, o path for inválido, ou a chamada falhar.
     * @param router Endereço do contrato roteador Uniswap V2.
     * @param amountIn Quantidade de tokens de entrada.
     * @param amountOutMin Quantidade mínima de tokens de saída.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     */
    function swapExactTokensForTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(router != address(0), "RouterEventEmitter: INVALID_ROUTER_ADDRESS");
        require(path.length >= 2, "RouterEventEmitter: INVALID_PATH_LENGTH");
        require(to != address(0), "RouterEventEmitter: INVALID_RECIPIENT_ADDRESS");
        require(amountIn > 0, "RouterEventEmitter: INVALID_INPUT_AMOUNT");

        (bool success, bytes memory returnData) = router.delegatecall(
            abi.encodeWithSelector(
                IUniswapV2Router01.swapExactTokensForTokens.selector,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            )
        );
        require(success, "RouterEventEmitter: DELEGATECALL_FAILED");

        uint256[] memory amounts = abi.decode(returnData, (uint256[]));
        emit Amounts(amounts);
    }

    /**
     * @notice Realiza um swap para receber uma quantidade exata de tokens, emitindo as quantidades resultantes.
     * @dev Executa delegatecall para a função swapTokensForExactTokens do roteador e emite evento Amounts.
     *      Reverte se o roteador for inválido, o path for inválido, ou a chamada falhar.
     * @param router Endereço do contrato roteador Uniswap V2.
     * @param amountOut Quantidade exata de tokens de saída desejada.
     * @param amountInMax Quantidade máxima de tokens de entrada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     */
    function swapTokensForExactTokens(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(router != address(0), "RouterEventEmitter: INVALID_ROUTER_ADDRESS");
        require(path.length >= 2, "RouterEventEmitter: INVALID_PATH_LENGTH");
        require(to != address(0), "RouterEventEmitter: INVALID_RECIPIENT_ADDRESS");
        require(amountOut > 0, "RouterEventEmitter: INVALID_OUTPUT_AMOUNT");

        (bool success, bytes memory returnData) = router.delegatecall(
            abi.encodeWithSelector(
                IUniswapV2Router01.swapTokensForExactTokens.selector,
                amountOut,
                amountInMax,
                path,
                to,
                deadline
            )
        );
        require(success, "RouterEventEmitter: DELEGATECALL_FAILED");

        uint256[] memory amounts = abi.decode(returnData, (uint256[]));
        emit Amounts(amounts);
    }

    /**
     * @notice Realiza um swap de ETH por uma quantidade de tokens, emitindo as quantidades resultantes.
     * @dev Executa delegatecall para a função swapExactETHForTokens do roteador e emite evento Amounts.
     *      Reverte se o roteador for inválido, o path for inválido, o valor de ETH for zero, ou a chamada falhar.
     * @param router Endereço do contrato roteador Uniswap V2.
     * @param amountOutMin Quantidade mínima de tokens de saída.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     */
    function swapExactETHForTokens(
        address router,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        require(router != address(0), "RouterEventEmitter: INVALID_ROUTER_ADDRESS");
        require(path.length >= 2, "RouterEventEmitter: INVALID_PATH_LENGTH");
        require(to != address(0), "RouterEventEmitter: INVALID_RECIPIENT_ADDRESS");
        require(msg.value > 0, "RouterEventEmitter: INSUFFICIENT_ETH_VALUE");

        (bool success, bytes memory returnData) = router.delegatecall(
            abi.encodeWithSelector(
                IUniswapV2Router01.swapExactETHForTokens.selector,
                amountOutMin,
                path,
                to,
                deadline
            )
        );
        require(success, "RouterEventEmitter: DELEGATECALL_FAILED");

        uint256[] memory amounts = abi.decode(returnData, (uint256[]));
        emit Amounts(amounts);
    }

    /**
     * @notice Realiza um swap de tokens por uma quantidade exata de ETH, emitindo as quantidades resultantes.
     * @dev Executa delegatecall para a função swapTokensForExactETH do roteador e emite evento Amounts.
     *      Reverte se o roteador for inválido, o path for inválido, ou a chamada falhar.
     * @param router Endereço do contrato roteador Uniswap V2.
     * @param amountOut Quantidade exata de ETH desejada.
     * @param amountInMax Quantidade máxima de tokens de entrada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá o ETH.
     * @param deadline Timestamp limite para a transação.
     */
    function swapTokensForExactETH(
        address router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(router != address(0), "RouterEventEmitter: INVALID_ROUTER_ADDRESS");
        require(path.length >= 2, "RouterEventEmitter: INVALID_PATH_LENGTH");
        require(to != address(0), "RouterEventEmitter: INVALID_RECIPIENT_ADDRESS");
        require(amountOut > 0, "RouterEventEmitter: INVALID_OUTPUT_AMOUNT");

        (bool success, bytes memory returnData) = router.delegatecall(
            abi.encodeWithSelector(
                IUniswapV2Router01.swapTokensForExactETH.selector,
                amountOut,
                amountInMax,
                path,
                to,
                deadline
            )
        );
        require(success, "RouterEventEmitter: DELEGATECALL_FAILED");

        uint256[] memory amounts = abi.decode(returnData, (uint256[]));
        emit Amounts(amounts);
    }

    /**
     * @notice Realiza um swap de uma quantidade exata de tokens por ETH, emitindo as quantidades resultantes.
     * @dev Executa delegatecall para a função swapExactTokensForETH do roteador e emite evento Amounts.
     *      Reverte se o roteador for inválido, o path for inválido, ou a chamada falhar.
     * @param router Endereço do contrato roteador Uniswap V2.
     * @param amountIn Quantidade de tokens de entrada.
     * @param amountOutMin Quantidade mínima de ETH de saída.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá o ETH.
     * @param deadline Timestamp limite para a transação.
     */
    function swapExactTokensForETH(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(router != address(0), "RouterEventEmitter: INVALID_ROUTER_ADDRESS");
        require(path.length >= 2, "RouterEventEmitter: INVALID_PATH_LENGTH");
        require(to != address(0), "RouterEventEmitter: INVALID_RECIPIENT_ADDRESS");
        require(amountIn > 0, "RouterEventEmitter: INVALID_INPUT_AMOUNT");

        (bool success, bytes memory returnData) = router.delegatecall(
            abi.encodeWithSelector(
                IUniswapV2Router01.swapExactTokensForETH.selector,
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            )
        );
        require(success, "RouterEventEmitter: DELEGATECALL_FAILED");

        uint256[] memory amounts = abi.decode(returnData, (uint256[]));
        emit Amounts(amounts);
    }

    /**
     * @notice Realiza um swap de ETH por uma quantidade exata de tokens, emitindo as quantidades resultantes.
     * @dev Executa delegatecall para a função swapETHForExactTokens do roteador e emite evento Amounts.
     *      Reverte se o roteador for inválido, o path for inválido, o valor de ETH for zero, ou a chamada falhar.
     * @param router Endereço do contrato roteador Uniswap V2.
     * @param amountOut Quantidade exata de tokens de saída desejada.
     * @param path Array de endereços de tokens definindo a rota do swap.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação.
     */
    function swapETHForExactTokens(
        address router,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        require(router != address(0), "RouterEventEmitter: INVALID_ROUTER_ADDRESS");
        require(path.length >= 2, "RouterEventEmitter: INVALID_PATH_LENGTH");
        require(to != address(0), "RouterEventEmitter: INVALID_RECIPIENT_ADDRESS");
        require(msg.value > 0, "RouterEventEmitter: INSUFFICIENT_ETH_VALUE");
        require(amountOut > 0, "RouterEventEmitter: INVALID_OUTPUT_AMOUNT");

        (bool success, bytes memory returnData) = router.delegatecall(
            abi.encodeWithSelector(
                IUniswapV2Router01.swapETHForExactTokens.selector,
                amountOut,
                path,
                to,
                deadline
            )
        );
        require(success, "RouterEventEmitter: DELEGATECALL_FAILED");

        uint256[] memory amounts = abi.decode(returnData, (uint256[]));
        emit Amounts(amounts);
    }
}