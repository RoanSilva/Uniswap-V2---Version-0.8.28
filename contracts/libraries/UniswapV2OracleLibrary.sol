// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2Pair} from '../interfaces/pool/IUniswapV2Pair.sol';
import {FixedPoint} from '@uniswap/lib/contracts/libraries/FixedPoint.sol';

/**
 * @title UniswapV2OracleLibrary
 * @author Uniswap V2 Oracle Library
 * @notice Biblioteca auxiliar para oráculos Uniswap V2, focada no cálculo de preços médios usando acumuladores de preço.
 * @dev Fornece funções para consultar timestamps e preços acumulados de pares Uniswap V2 de forma segura e eficiente.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Verificações explícitas de segurança para prevenir erros (ex.: endereço inválido, reservas insuficientes).
 *      - Uso de FixedPoint para cálculos precisos de preços com representação de ponto fixo.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // ================================
    //           Funções de Timestamp
    // ================================

    /**
     * @notice Retorna o timestamp atual do bloco, truncado para uint32.
     * @dev O truncamento para uint32 (intervalo [0, 2**32 - 1]) é seguro, pois o timestamp do Ethereum
     *      está muito abaixo desse limite até 2038. Usa módulo para garantir compatibilidade com uint32.
     * @return blockTimestamp Timestamp atual do bloco truncado para uint32.
     */
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // ================================
    //           Funções de Preço
    // ================================

    /**
     * @notice Calcula os preços acumulados atuais de um par Uniswap V2, usando valores contrafactuais para otimizar gás.
     * @dev Consulta os acumuladores de preço (`price0CumulativeLast`, `price1CumulativeLast`) e reservas do par.
     *      Se o timestamp do bloco atual for diferente do último registrado, atualiza os acumuladores contrafactualmente
     *      com base nas reservas atuais, evitando a necessidade de chamar `sync` no par.
     *      Fórmula: priceCumulative += (reserveOut / reserveIn) * timeElapsed, usando FixedPoint para precisão.
     *      Reverte se o endereço do par for inválido ou se as reservas forem insuficientes.
     * @param pair Endereço do contrato do par Uniswap V2.
     * @return price0Cumulative Preço acumulado do token0 (uint256, em formato de ponto fixo).
     * @return price1Cumulative Preço acumulado do token1 (uint256, em formato de ponto fixo).
     * @return blockTimestamp Timestamp atual do bloco truncado para uint32.
     */
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) {
        require(pair != address(0), "UniswapV2OracleLibrary: INVALID_PAIR_ADDRESS");

        // Obtém o timestamp atual
        blockTimestamp = currentBlockTimestamp();

        // Consulta os acumuladores de preço e reservas do par
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();

        // Verifica se as reservas são suficientes
        require(reserve0 > 0 && reserve1 > 0, "UniswapV2OracleLibrary: INSUFFICIENT_RESERVES");

        // Atualiza os acumuladores se o tempo tiver passado desde a última atualização
        if (blockTimestampLast != blockTimestamp) {
            // Calcula o tempo decorrido, permitindo overflow natural em uint32
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;

            // Atualiza contrafactualmente os acumuladores de preço
            // Preço é representado como razão entre reservas, em formato Q112.112 (FixedPoint)
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}