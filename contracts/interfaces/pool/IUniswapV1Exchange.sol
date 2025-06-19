// SPDX-License-Identifier: MIT
/**
 * @title IUniswapV1Exchange
 * @notice Interface para interação com exchanges Uniswap V1
 * @dev Define métodos para consultar saldos, transferências, remoção de liquidez e swaps no Uniswap V1
 *      Compatível com Solidity 0.8.28, implementa padrões de nível empresarial com documentação detalhada
 * @custom:disclaimer Aviso: Esta interface é apenas para fins demonstrativos. Embora seja projetada para interagir com contratos Uniswap V1,
 *                    não há garantias sobre sua correção ou segurança. Esta interface é mantida em um padrão diferente de outros contratos no repositório,
 *                    sendo explicitamente excluída do programa de recompensas por bugs (bug bounty). Realize sua própria due diligence antes de usar esta interface em seu projeto.
 */
pragma solidity 0.8.28;

/**
 * @notice Interface para operações no exchange Uniswap V1
 */
interface IUniswapV1Exchange {
    /**
     * @notice Consulta o saldo de tokens de um proprietário no exchange
     * @param owner Endereço do proprietário a ser consultado
     * @return Saldo de tokens do proprietário
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Transfere tokens de um endereço para outro
     * @param from Endereço de origem dos tokens
     * @param to Endereço de destino dos tokens
     * @param value Quantidade de tokens a transferir
     * @return bool Indicador de sucesso da transferência
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Remove liquidez do pool do exchange
     * @param liquidity Quantidade de tokens de liquidez a remover
     * @param amountTokenMin Quantidade mínima de tokens a receber
     * @param amountETHMin Quantidade mínima de ETH a receber
     * @param deadline Timestamp limite para a transação
     * @return amountToken Quantidade de tokens recebidos
     * @return amountETH Quantidade de ETH recebidos
     */
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Realiza swap de tokens para ETH com quantidade de entrada fixa
     * @param tokensSold Quantidade de tokens a vender
     * @param minETH Quantidade mínima de ETH a receber
     * @param deadline Timestamp limite para a transação
     * @return amountETH Quantidade de ETH recebida
     */
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minETH,
        uint256 deadline
    ) external returns (uint256 amountETH);

    /**
     * @notice Realiza swap de ETH para tokens com quantidade de entrada fixa
     * @param minTokens Quantidade mínima de tokens a receber
     * @param deadline Timestamp limite para a transação
     * @return amountTokens Quantidade de tokens recebidos
     */
    function ethToTokenSwapInput(
        uint256 minTokens,
        uint256 deadline
    ) external payable returns (uint256 amountTokens);
}