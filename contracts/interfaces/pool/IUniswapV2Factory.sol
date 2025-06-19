// SPDX-License-Identifier: MIT
/**
 * @title IUniswapV2Factory
 * @notice Interface para interação com o factory do Uniswap V2
 * @dev Define métodos para criar e gerenciar pares de tokens, configurar taxas e consultar informações, compatível com Solidity 0.8.28
 *      Implementa padrões de nível empresarial com documentação detalhada
 * @custom:disclaimer Aviso: Esta interface é apenas para fins demonstrativos. Embora seja projetada para interagir com contratos Uniswap V2,
 *                    não há garantias sobre sua correção ou segurança. Esta interface é mantida em um padrão diferente de outros contratos no repositório,
 *                    sendo explicitamente excluída do programa de recompensas por bugs (bug bounty). Realize sua própria due diligence antes de usar esta interface em seu projeto.
 */
pragma solidity 0.8.28;

/**
 * @notice Interface para operações no factory Uniswap V2
 */
interface IUniswapV2Factory {
    /**
     * @notice Evento emitido quando um novo par de tokens é criado
     * @param token0 Endereço do primeiro token do par
     * @param token1 Endereço do segundo token do par
     * @param pair Endereço do contrato do par criado
     * @param pairCount Número total de pares criados até o momento
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairCount);

    /**
     * @notice Retorna o endereço que recebe as taxas do protocolo
     * @return Endereço do destinatário das taxas
     */
    function feeTo() external view returns (address);

    /**
     * @notice Retorna o endereço autorizado a configurar o destinatário das taxas
     * @return Endereço do configurador de taxas
     */
    function feeToSetter() external view returns (address);

    /**
     * @notice Consulta o endereço do par associado a dois tokens
     * @param tokenA Endereço do primeiro token
     * @param tokenB Endereço do segundo token
     * @return pair Endereço do contrato do par
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Consulta o endereço de um par pelo índice na lista de pares
     * @param index Índice do par na lista
     * @return pair Endereço do contrato do par
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @notice Retorna o número total de pares criados
     * @return Número total de pares
     */
    function allPairsLength() external view returns (uint256);

    /**
     * @notice Cria um novo par de tokens
     * @param tokenA Endereço do primeiro token
     * @param tokenB Endereço do segundo token
     * @return pair Endereço do contrato do par criado
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Configura o endereço que recebe as taxas do protocolo
     * @param feeTo Endereço do novo destinatário das taxas
     */
    function setFeeTo(address feeTo) external;

    /**
     * @notice Configura o endereço autorizado a definir o destinatário das taxas
     * @param feeToSetter Endereço do novo configurador de taxas
     */
    function setFeeToSetter(address feeToSetter) external;
}