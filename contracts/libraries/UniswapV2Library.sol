// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2Pair} from '../interfaces/pool/IUniswapV2Pair.sol';
import {SafeMath} from "../libraries/SafeMath.sol";

/**
 * @title UniswapV2Library
 * @author Uniswap V2 Utility Library
 * @notice Biblioteca auxiliar para operações comuns do Uniswap V2, incluindo cálculo de endereços de pares,
 *         consulta de reservas e cálculos de valores para swaps e liquidez.
 * @dev Fornece funções otimizadas para interagir com pares Uniswap V2 de forma segura e eficiente.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Verificações explícitas de segurança para prevenir erros comuns (ex.: endereços inválidos, liquidez insuficiente).
 *      - Uso de SafeMath para operações aritméticas, mesmo com Solidity 0.8.28, para maior clareza em auditorias.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
library UniswapV2Library {
    using SafeMath for uint256;

    // ================================
    //           Funções de Ordenação
    // ================================

    /**
     * @notice Ordena dois endereços de token para garantir a ordenação canônica (token0 < token1).
     * @dev Reverte se os tokens forem iguais ou se algum for o endereço zero.
     *      A ordenação é essencial para cálculos consistentes de endereços de pares via CREATE2.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @return token0 Endereço do token com menor valor (ordenado).
     * @return token1 Endereço do token com maior valor (ordenado).
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // ================================
    //           Funções de Endereço
    // ================================

    /**
     * @notice Calcula o endereço de um par Uniswap V2 usando CREATE2 sem chamadas externas.
     * @dev Usa o hash de inicialização fixo do Uniswap V2 para calcular o endereço do par.
     *      A ordenação dos tokens é feita pela função `sortTokens` para garantir consistência.
     *      Fórmula: address(keccak256(0xff, factory, keccak256(token0, token1), initcodeHash)).
     * @param factory Endereço do contrato factory Uniswap V2.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @return pair Endereço calculado do par Uniswap V2.
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    // ================================
    //           Funções de Reservas
    // ================================

    /**
     * @notice Obtém as reservas ordenadas de um par Uniswap V2 para os tokens fornecidos.
     * @dev Consulta o par via `pairFor` e ajusta as reservas conforme a ordem original de `tokenA` e `tokenB`.
     *      Reverte se o par não existir ou não tiver liquidez.
     * @param factory Endereço do contrato factory Uniswap V2.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @return reserveA Reserva correspondente ao `tokenA`.
     * @return reserveB Reserva correspondente ao `tokenB`.
     */
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // ================================
    //           Funções de Cotação
    // ================================

    /**
     * @notice Calcula a quantidade equivalente de tokenB para uma quantidade de tokenA, com base nas reservas.
     * @dev Fórmula: amountB = (amountA * reserveB) / reserveA.
     *      Reverte se `amountA` ou as reservas forem zero.
     *      Usa SafeMath para garantir precisão e segurança nas operações aritméticas.
     * @param amountA Quantidade de tokenA (uint256).
     * @param reserveA Reserva de tokenA no par (uint256).
     * @param reserveB Reserva de tokenB no par (uint256).
     * @return amountB Quantidade equivalente de tokenB (uint256).
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB).div(reserveA);
    }

    /**
     * @notice Calcula a quantidade máxima de saída para uma quantidade de entrada, considerando a taxa de 0.3%.
     * @dev Fórmula: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997).
     *      A taxa de 0.3% é aplicada multiplicando `amountIn` por 997/1000.
     *      Reverte se `amountIn` ou as reservas forem zero.
     *      Usa SafeMath para operações aritméticas seguras.
     * @param amountIn Quantidade de tokens de entrada (uint256).
     * @param reserveIn Reserva de tokens de entrada no par (uint256).
     * @param reserveOut Reserva de tokens de saída no par (uint256).
     * @return amountOut Quantidade máxima de tokens de saída (uint256).
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator.div(denominator);
    }

    /**
     * @notice Calcula a quantidade necessária de entrada para obter uma quantidade de saída desejada, considerando a taxa de 0.3%.
     * @dev Fórmula: amountIn = (reserveIn * amountOut * 1000) / (reserveOut - amountOut * 997) + 1.
     *      A taxa de 0.3% é aplicada dividindo por 997/1000.
     *      O resultado é arredondado para cima (+1) para garantir que a saída desejada seja atingida.
     *      Reverte se `amountOut` ou as reservas forem zero, ou se `amountOut` for maior que `reserveOut`.
     *      Usa SafeMath para operações aritméticas seguras.
     * @param amountOut Quantidade desejada de tokens de saída (uint256).
     * @param reserveIn Reserva de tokens de entrada no par (uint256).
     * @param reserveOut Reserva de tokens de saída no par (uint256).
     * @return amountIn Quantidade necessária de tokens de entrada (uint256).
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = numerator.div(denominator).add(1);
    }

    // ================================
    //           Funções de Swap
    // ================================

    /**
     * @notice Calcula as quantidades de saída para cada etapa de um caminho de swap.
     * @dev Itera pelo `path` consultando reservas e aplicando `getAmountOut` para cada par.
     *      Reverte se o caminho tiver menos de dois tokens.
     *      Usa SafeMath para operações aritméticas seguras.
     * @param factory Endereço do contrato factory Uniswap V2.
     * @param amountIn Quantidade inicial de tokens de entrada (uint256).
     * @param path Array de endereços de tokens representando o caminho do swap.
     * @return amounts Array com quantidades calculadas para cada token no caminho (uint256[]).
     */
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /**
     * @notice Calcula as quantidades de entrada necessárias para cada etapa de um caminho de swap para obter uma saída desejada.
     * @dev Itera pelo `path` na ordem reversa, consultando reservas e aplicando `getAmountIn` para cada par.
     *      Reverte se o caminho tiver menos de dois tokens.
     *      Usa SafeMath para operações aritméticas seguras.
     * @param factory Endereço do contrato factory Uniswap V2.
     * @param amountOut Quantidade final desejada de tokens de saída (uint256).
     * @param path Array de endereços de tokens representando o caminho do swap.
     * @return amounts Array com quantidades calculadas para cada token no caminho (uint256[]).
     */
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}