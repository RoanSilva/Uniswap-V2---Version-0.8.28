// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title Math
 * @author Mathematical Utility Library
 * @notice Biblioteca para operações matemáticas comuns com implementações seguras e eficientes.
 * @dev Fornece funções otimizadas para cálculo do mínimo entre dois números e raiz quadrada usando o método babilônico.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Verificações implícitas de segurança e otimizações de gás.
 *      - Organização clara e concisa para facilitar manutenção e auditoria.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
library Math {
    // ================================
    //           Funções Matemáticas
    // ================================

    /**
     * @notice Retorna o menor valor entre dois números.
     * @dev Usa um operador ternário para eficiência e legibilidade.
     *      Não requer verificações adicionais, pois opera com uint256 e não realiza aritmética que possa causar overflow.
     * @param x Primeiro número para comparação.
     * @param y Segundo número para comparação.
     * @return z O menor valor entre `x` e `y`.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /**
     * @notice Calcula a raiz quadrada inteira de um número usando o método babilônico.
     * @dev Implementa o método babilônico para números maiores que 3, retornando 1 para números entre 1 e 3, e 0 para y = 0.
     *      Otimizado para minimizar iterações e consumo de gás.
     *      Não requer verificações de overflow devido ao uso de uint256 e Solidity 0.8.28.
     *      A implementação é determinística e converge rapidamente para a raiz quadrada inteira.
     * @param y Número para calcular a raiz quadrada (uint256, não negativo).
     * @return z Raiz quadrada inteira de `y`.
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // Caso y == 0, z já é inicializado como 0 pelo compilador
    }
}