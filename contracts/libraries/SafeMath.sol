// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title SafeMath
 * @author Safe Mathematical Operations Library
 * @notice Biblioteca para operações matemáticas seguras com verificações explícitas para overflow, underflow e divisão por zero.
 * @dev Embora Solidity >=0.8.28 inclua verificações nativas de overflow/underflow, esta biblioteca é mantida para:
 *      - Compatibilidade com projetos legados que dependem de SafeMath.
 *      - Clareza em auditorias, fornecendo verificações explícitas com mensagens de erro descritivas.
 *      - Otimização opcional usando `unchecked` para operações seguras.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Organização clara e concisa para facilitar manutenção e auditoria.
 *      Compatível com Solidity 0.8.28, aproveitando otimizações modernas do compilador.
 */
library SafeMath {
    // ================================
    //           Funções Matemáticas
    // ================================

    /**
     * @notice Soma dois números com verificação explícita de overflow.
     * @dev Usa `unchecked` para realizar a adição, mas inclui uma verificação manual para garantir que o resultado seja válido.
     *      Reverte com mensagem de erro se ocorrer overflow (c < a).
     *      Compatível com Solidity 0.8.28, embora verificações nativas já estejam presentes.
     * @param a Primeiro número (uint256).
     * @param b Segundo número (uint256).
     * @return c Resultado da soma (uint256).
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked {
            c = a + b;
        }
        require(c >= a, "SafeMath: addition overflow");
    }

    /**
     * @notice Subtrai dois números com verificação explícita de underflow.
     * @dev Verifica se b <= a antes da subtração para evitar underflow.
     *      Usa `unchecked` para a operação de subtração, otimizando gás.
     *      Reverte com mensagem de erro se ocorrer underflow.
     * @param a Minuendo (uint256).
     * @param b Subtraendo (uint256).
     * @return Resultado da subtração (uint256).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        unchecked {
            return a - b;
        }
    }

    /**
     * @notice Multiplica dois números com verificação explícita de overflow.
     * @dev Retorna 0 se a = 0 para otimizar gás.
     *      Usa `unchecked` para a multiplicação, mas verifica manualmente se c / a == b para garantir ausência de overflow.
     *      Reverte com mensagem de erro se ocorrer overflow.
     * @param a Primeiro número (uint256).
     * @param b Segundo número (uint256).
     * @return c Resultado da multiplicação (uint256).
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        unchecked {
            c = a * b;
        }
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    /**
     * @notice Divide dois números com verificação explícita de divisão por zero.
     * @dev Verifica se b > 0 antes da divisão para evitar divisão por zero.
     *      Usa `unchecked` para a operação de divisão, otimizando gás.
     *      Reverte com mensagem de erro se o divisor for zero.
     * @param a Dividendo (uint256).
     * @param b Divisor (uint256).
     * @return Resultado da divisão (uint256).
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        unchecked {
            return a / b;
        }
    }
}