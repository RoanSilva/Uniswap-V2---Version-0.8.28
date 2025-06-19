// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title UQ112x112
 * @author Fixed-Point Arithmetic Library
 * @notice Biblioteca para manipulação de números fixos binários no formato UQ112x112.
 * @dev Representa números na faixa [0, 2**112 - 1] com uma resolução de 1 / 2**112, usada em cálculos de preços acumulados no Uniswap V2.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Verificações explícitas de segurança (ex.: divisão por zero).
 *      - Tipagem precisa para garantir cálculos corretos e evitar overflows.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
library UQ112x112 {
    // Constante Q112 representa 2**112, usada como denominador no formato UQ112x112
    uint224 private constant Q112 = 2**112;

    // ================================
    //           Funções de Codificação
    // ================================

    /**
     * @notice Codifica um valor uint112 para o formato UQ112x112.
     * @dev Multiplica o valor de entrada por 2**112 para representar o número no formato de ponto fixo UQ112x112.
     *      A operação é segura devido aos limites de uint112 e uint224, e Solidity 0.8.28 previne overflow nativamente.
     *      Exemplo: encode(1) retorna 1 * 2**112.
     * @param y Valor a ser codificado (uint112, na faixa [0, 2**112 - 1]).
     * @return z Valor codificado no formato UQ112x112 (uint224).
     */
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    // ================================
    //           Funções Aritméticas
    // ================================

    /**
     * @notice Divide um número UQ112x112 por um uint112, retornando um resultado no formato UQ112x112.
     * @dev Realiza a divisão x / y, onde x é um número UQ112x112 e y é um uint112.
     *      Reverte se o divisor for zero.
     *      A operação mantém a precisão do formato UQ112x112, e Solidity 0.8.28 previne overflow/underflow.
     *      Exemplo: uqdiv(encode(1), 2) retorna encode(0.5) = 0.5 * 2**112.
     * @param x Número no formato UQ112x112 (uint224).
     * @param y Divisor (uint112, na faixa [1, 2**112 - 1]).
     * @return z Resultado da divisão no formato UQ112x112 (uint224).
     */
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        require(y != 0, "UQ112x112: DIVISION_BY_ZERO");
        z = x / uint224(y);
    }
}