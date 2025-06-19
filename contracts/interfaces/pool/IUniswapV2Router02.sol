// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2Router01} from './IUniswapV2Router01.sol';

/**
 * @title IUniswapV2Router02
 * @author Uniswap V2 Router Interface
 * @notice Interface para o contrato Uniswap V2 Router (versão 02), estendendo IUniswapV2Router01.
 * @dev Adiciona suporte a tokens com taxas em transferências (fee-on-transfer) para operações de liquidez e swaps.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Organização modular com seções claras para remoção de liquidez e swaps.
 *      - Recomendações implícitas de segurança para implementações (ex.: validação de endereços, proteção contra reentrância, verificação de deadlines).
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
interface IUniswapV2Router02 is IUniswapV2Router01 {
    // ================================
    //      Remoção de Liquidez com Suporte a Taxas
    // ================================

    /**
     * @notice Remove liquidez de um par token/ETH, suportando tokens com taxas em transferências.
     * @dev Deve:
     *      - Verificar que `token` é um endereço válido.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountTokenMin` e `amountETHMin` protejam contra slippage.
     *      - Verificar que `deadline` não está expirado (block.timestamp <= deadline).
     *      - Lidar com a quantidade real recebida após taxas em transferências.
     *      - Reembolsar ETH ao destinatário.
     * @param token Endereço do token do par.
     * @param liquidity Quantidade de tokens de liquidez a serem removidos.
     * @param amountTokenMin Quantidade mínima de token aceita (proteção contra slippage).
     * @param amountETHMin Quantidade mínima de ETH aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens e ETH retirados.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @return amountETH Quantidade de ETH recebida após a remoção.
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    /**
     * @notice Remove liquidez de um par token/ETH com permissão via assinatura (EIP-2612), suportando tokens com taxas em transferências.
     * @dev Deve:
     *      - Validar a assinatura (v, r, s) e o `deadline`.
     *      - Verificar que `token` e `to` não são endereços zero.
     *      - Garantir que `amountTokenMin` e `amountETHMin` protejam contra slippage.
     *      - Usar `approveMax` para definir a aprovação máxima, se necessário.
     *      - Lidar com a quantidade real recebida após taxas em transferências.
     * @param token Endereço do token do par.
     * @param liquidity Quantidade de tokens de liquidez a serem removidos.
     * @param amountTokenMin Quantidade mínima de token aceita (proteção contra slippage).
     * @param amountETHMin Quantidade mínima de ETH aceita (proteção contra slippage).
     * @param to Endereço que receberá os tokens e ETH retirados.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     * @param approveMax Se verdadeiro, aprova o máximo possível de tokens.
     * @param v Componente da assinatura ECDSA.
     * @param r Componente da assinatura ECDSA.
     * @param s Componente da assinatura ECDSA.
     * @return amountETH Quantidade de ETH recebida após a remoção.
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
    ) external returns (uint256 amountETH);

    // ================================
    //      Swaps com Suporte a Taxas em Transferência
    // ================================

    /**
     * @notice Troca uma quantidade exata de tokens por outros tokens, suportando tokens com taxas em transferências.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e pelo menos um par.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountOutMin` protege contra slippage.
     *      - Verificar que `deadline` não está expirado.
     *      - Lidar com a quantidade real recebida após taxas em transferências.
     * @param amountIn Quantidade exata de tokens de entrada.
     * @param amountOutMin Quantidade mínima de tokens de saída aceita.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    /**
     * @notice Troca uma quantidade exata de ETH por tokens, suportando tokens com taxas em transferências.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e começa com WETH.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountOutMin` protege contra slippage.
     *      - Verificar que `deadline` não está expirado.
     *      - Processar o valor de ETH enviado com `msg.value`.
     *      - Lidar com a quantidade real recebida após taxas em transferências.
     * @param amountOutMin Quantidade mínima de tokens de saída aceita.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá os tokens de saída.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    /**
     * @notice Troca uma quantidade exata de tokens por ETH, suportando tokens com taxas em transferências.
     * @dev Deve:
     *      - Verificar que `path` contém endereços válidos e termina com WETH.
     *      - Validar que `to` não é o endereço zero.
     *      - Garantir que `amountOutMin` protege contra slippage.
     *      - Verificar que `deadline` não está expirado.
     *      - Lidar com a quantidade real recebida após taxas em transferências.
     * @param amountIn Quantidade exata de tokens de entrada.
     * @param amountOutMin Quantidade mínima de ETH aceita.
     * @param path Array de endereços representando o caminho dos pares de troca.
     * @param to Endereço que receberá o ETH.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}