// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IUniswapV2Migrator
 * @author Uniswap V2 Migration Interface
 * @notice Interface para o contrato de migração de liquidez do Uniswap V2.
 * @dev Define a estrutura padrão para migração de liquidez entre pools Uniswap V2.
 *      Segue as melhores práticas do Solidity, incluindo documentação NatSpec,
 *      validação implícita de segurança e clareza para implementações futuras.
 *      Compatível com Solidity 0.8.28 para segurança e otimizações modernas.
 */
interface IUniswapV2Migrator {
    /**
     * @notice Migra tokens de liquidez de um pool Uniswap V2 para outro.
     * @dev Esta função deve ser implementada com verificações de segurança para:
     *      - Validar que `token` é um endereço válido de contrato.
     *      - Garantir que `amountTokenMin` e `amountETHMin` protejam contra slippage excessivo.
     *      - Verificar que `to` não é o endereço zero.
     *      - Confirmar que `deadline` não está expirado (block.timestamp <= deadline).
     *      - Proteger contra ataques de reentrância e front-running.
     *      Recomenda-se usar SafeMath internamente para cálculos aritméticos, embora
     *      Solidity >=0.8 já inclua verificações de overflow/underflow nativas.
     * @param token Endereço do token de liquidez a ser migrado (ex.: UNI-V2 LP token).
     * @param amountTokenMin Quantidade mínima de tokens a receber após a migração.
     * @param amountETHMin Quantidade mínima de ETH a receber após a migração.
     * @param to Endereço que receberá os tokens e ETH migrados.
     * @param deadline Timestamp limite para a transação (UNIX timestamp).
     */
    function migrate(
        address token,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external;
}