// SPDX-License-Identifier: MIT
/**
 * @title IUniswapV2Callee
 * @notice Interface para contratos que participam de flash swaps no Uniswap V2
 * @dev Define o método chamado pelo par Uniswap V2 durante um flash swap, compatível com Solidity 0.8.28
 *      Implementa padrões de nível empresarial com documentação detalhada
 * @custom:disclaimer Aviso: Esta interface é apenas para fins demonstrativos. Embora seja projetada para interagir com contratos Uniswap V2,
 *                    não há garantias sobre sua correção ou segurança. Esta interface é mantida em um padrão diferente de outros contratos no repositório,
 *                    sendo explicitamente excluída do programa de recompensas por bugs (bug bounty). Realize sua própria due diligence antes de usar esta interface em seu projeto.
 */
pragma solidity 0.8.28;

/**
 * @notice Interface para operações de callback em flash swaps Uniswap V2
 */
interface IUniswapV2Callee {
    /**
     * @notice Método chamado pelo par Uniswap V2 durante um flash swap
     * @param sender Endereço que iniciou o flash swap
     * @param amount0 Quantidade do token0 fornecida pelo par
     * @param amount1 Quantidade do token1 fornecida pelo par
     * @param data Dados adicionais fornecidos pelo chamador do flash swap
     * @dev Implementações devem garantir que os tokens emprestados sejam devolvidos ao par com a taxa antes do final da transação
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}