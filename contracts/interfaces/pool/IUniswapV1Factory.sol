// SPDX-License-Identifier: MIT
/**
 * @title IUniswapV1Factory
 * @notice Interface para interação com o factory do Uniswap V1
 * @dev Permite consultar o endereço do exchange associado a um token, compatível com Solidity 0.8.28
 *      Implementa padrões de nível empresarial com documentação detalhada
 * @custom:disclaimer Aviso: Esta interface é apenas para fins demonstrativos. Embora seja projetada para interagir com contratos Uniswap V1,
 *                    não há garantias sobre sua correção ou segurança. Esta interface é mantida em um padrão diferente de outros contratos no repositório,
 *                    sendo explicitamente excluída do programa de recompensas por bugs (bug bounty). Realize sua própria due diligence antes de usar esta interface em seu projeto.
 */
pragma solidity 0.8.28;

/**
 * @notice Interface para operações no factory Uniswap V1
 */
interface IUniswapV1Factory {
    /**
     * @notice Consulta o endereço do exchange associado a um token
     * @param token Endereço do token ERC20
     * @return Endereço do contrato de exchange Uniswap V1 correspondente ao token
     */
    function getExchange(address token) external view returns (address);
}