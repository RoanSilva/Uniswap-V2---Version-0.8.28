// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2Pair} from '../interfaces/pool/IUniswapV2Pair.sol';
import {IUniswapV2Factory} from '../interfaces/pool/IUniswapV2Factory.sol';
import {Babylonian} from '@uniswap/lib/contracts/libraries/Babylonian.sol';
import {SafeMath} from '@uniswap/v2-core/contracts/libraries/SafeMath.sol';
import {UniswapV2Library} from '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
import {FullMath} from '@uniswap/lib/contracts/libraries/FullMath.sol';

/**
 * @title UniswapV2LiquidityMathLibrary
 * @author Uniswap V2 Liquidity Math Library
 * @notice Biblioteca para cálculos avançados de liquidez em pares Uniswap V2, incluindo avaliação de liquidez,
 *         direção e magnitude de trades para arbitragem, e ajustes de reservas pós-arbitragem.
 * @dev Fornece funções otimizadas para cálculos relacionados à liquidez e arbitragem em pares Uniswap V2.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Verificações explícitas de segurança para prevenir erros (ex.: reservas insuficientes, quantidades inválidas).
 *      - Uso de SafeMath para operações aritméticas, garantindo clareza em auditorias.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
library UniswapV2LiquidityMathLibrary {
    using SafeMath for uint256;

    // ================================
    //           Funções de Arbitragem
    // ================================

    /**
     * @notice Determina a direção e magnitude de uma trade que maximiza o lucro com base em preços verdadeiros.
     * @dev Compara o preço implícito do par (reserveA/reserveB) com o preço verdadeiro (truePriceTokenA/truePriceTokenB).
     *      Calcula a quantidade de entrada (amountIn) usando o método babilônico para alinhar o preço do par ao preço verdadeiro.
     *      Fórmula: leftSide = sqrt((invariant * 1000 * truePriceIn) / (truePriceOut * 997)), amountIn = leftSide - rightSide.
     *      Reverte implicitamente se as reservas forem inválidas (verificado em UniswapV2Library).
     * @param truePriceTokenA Preço verdadeiro do token A (uint256, externamente observado).
     * @param truePriceTokenB Preço verdadeiro do token B (uint256, externamente observado).
     * @param reserveA Reserva atual do token A no par (uint256).
     * @param reserveB Reserva atual do token B no par (uint256).
     * @return aToB Verdadeiro se a trade deve ser de tokenA para tokenB, falso caso contrário.
     * @return amountIn Quantidade de tokens de entrada para a trade (uint256).
     */
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (bool aToB, uint256 amountIn) {
        require(truePriceTokenA > 0 && truePriceTokenB > 0, "UniswapV2LiquidityMathLibrary: INVALID_TRUE_PRICES");

        // Determina a direção da trade comparando preços implícitos e verdadeiros
        aToB = FullMath.mulDiv(reserveA, truePriceTokenB, reserveB) < truePriceTokenA;

        // Calcula o invariante do par (reserveA * reserveB)
        uint256 invariant = reserveA.mul(reserveB);

        // Calcula a raiz quadrada do novo estado ideal do par
        uint256 leftSide = Babylonian.sqrt(
            FullMath.mulDiv(
                invariant.mul(1000),
                aToB ? truePriceTokenA : truePriceTokenB,
                (aToB ? truePriceTokenB : truePriceTokenA).mul(997)
            )
        );

        // Calcula o estado atual ajustado pela taxa (0.3%)
        uint256 rightSide = aToB ? reserveA.mul(1000).div(997) : reserveB.mul(1000).div(997);

        // Se leftSide < rightSide, não há oportunidade de arbitragem
        if (leftSide < rightSide) {
            return (false, 0);
        }

        // Calcula a quantidade de entrada necessária
        amountIn = leftSide.sub(rightSide);
    }

    /**
     * @notice Calcula as reservas ajustadas de um par após uma arbitragem que alinha o preço ao preço verdadeiro.
     * @dev Usa `computeProfitMaximizingTrade` para determinar a direção e quantidade da trade.
     *      Ajusta as reservas com base no resultado da trade, usando `getAmountOut` para calcular a saída.
     *      Reverte se as reservas iniciais forem zero.
     * @param factory Endereço do contrato factory Uniswap V2.
     * @param tokenA Endereço do token A.
     * @param tokenB Endereço do token B.
     * @param truePriceTokenA Preço verdadeiro do token A (uint256).
     * @param truePriceTokenB Preço verdadeiro do token B (uint256).
     * @return reserveA Reserva ajustada do token A (uint256).
     * @return reserveB Reserva ajustada do token B (uint256).
     */
    function getReservesAfterArbitrage(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        // Obtém as reservas atuais
        (reserveA, reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        require(reserveA > 0 && reserveB > 0, "UniswapV2LiquidityMathLibrary: ZERO_PAIR_RESERVES");

        // Determina a direção e quantidade da trade
        (bool aToB, uint256 amountIn) = computeProfitMaximizingTrade(truePriceTokenA, truePriceTokenB, reserveA, reserveB);

        // Se não houver trade, retorna as reservas atuais
        if (amountIn == 0) {
            return (reserveA, reserveB);
        }

        // Ajusta as reservas com base na direção da trade
        if (aToB) {
            uint256 amountOut = UniswapV2Library.getAmountOut(amountIn, reserveA, reserveB);
            reserveA = reserveA.add(amountIn);
            reserveB = reserveB.sub(amountOut);
        } else {
            uint256 amountOut = UniswapV2Library.getAmountOut(amountIn, reserveB, reserveA);
            reserveB = reserveB.add(amountIn);
            reserveA = reserveA.sub(amountOut);
        }
    }

    // ================================
    //           Funções de Liquidez
    // ================================

    /**
     * @notice Calcula o valor de uma quantidade de tokens de liquidez em termos dos tokens subjacentes.
     * @dev Considera taxas de protocolo (se ativadas) e o histórico de kLast para ajustar o totalSupply.
     *      Fórmula para taxa: feeLiquidity = (totalSupply * (sqrt(reservesA * reservesB) - sqrt(kLast))) / (5 * sqrt(reservesA * reservesB) + sqrt(kLast)).
     *      Valor dos tokens: tokenAmount = (reserve * liquidityAmount) / totalSupply.
     *      Usa SafeMath para operações aritméticas seguras.
     * @param reservesA Reserva atual do token A (uint256).
     * @param reservesB Reserva atual do token B (uint256).
     * @param totalSupply Total de tokens de liquidez emitidos (uint256).
     * @param liquidityAmount Quantidade de tokens de liquidez a avaliar (uint256).
     * @param feeOn Indica se a taxa de protocolo está ativa.
     * @param kLast Último valor registrado do produto das reservas (uint256).
     * @return tokenAAmount Quantidade equivalente em token A (uint256).
     * @return tokenBAmount Quantidade equivalente em token B (uint256).
     */
    function computeLiquidityValue(
        uint256 reservesA,
        uint256 reservesB,
        uint256 totalSupply,
        uint256 liquidityAmount,
        bool feeOn,
        uint256 kLast
    ) internal pure returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        require(totalSupply > 0 && liquidityAmount <= totalSupply, "UniswapV2LiquidityMathLibrary: INVALID_LIQUIDITY_AMOUNT");
        require(reservesA > 0 && reservesB > 0, "UniswapV2LiquidityMathLibrary: INSUFFICIENT_RESERVES");

        // Ajusta totalSupply se a taxa de protocolo estiver ativa
        if (feeOn && kLast > 0) {
            uint256 rootK = Babylonian.sqrt(reservesA.mul(reservesB));
            uint256 rootKLast = Babylonian.sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 numerator1 = totalSupply;
                uint256 numerator2 = rootK.sub(rootKLast);
                uint256 denominator = rootK.mul(5).add(rootKLast);
                uint256 feeLiquidity = FullMath.mulDiv(numerator1, numerator2, denominator);
                totalSupply = totalSupply.add(feeLiquidity);
            }
        }

        // Calcula os valores equivalentes em tokens A e B
        tokenAAmount = reservesA.mul(liquidityAmount).div(totalSupply);
        tokenBAmount = reservesB.mul(liquidityAmount).div(totalSupply);
    }

    /**
     * @notice Obtém os parâmetros atuais do par e calcula o valor de uma quantidade de tokens de liquidez.
     * @dev Consulta as reservas, totalSupply, kLast e status de taxa do par para chamar `computeLiquidityValue`.
     *      Reverte se o par não tiver liquidez suficiente ou se a quantidade de liquidez for inválida.
     * @param factory Endereço do contrato factory Uniswap V2.
     * @param tokenA Endereço do token A.
     * @param tokenB Endereço do token B.
     * @param liquidityAmount Quantidade de tokens de liquidez a avaliar (uint256).
     * @return tokenAAmount Quantidade equivalente em token A (uint256).
     * @return tokenBAmount Quantidade equivalente em token B (uint256).
     */
    function getLiquidityValue(
        address factory,
        address tokenA,
        address tokenB,
        uint256 liquidityAmount
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        require(factory != address(0), "UniswapV2LiquidityMathLibrary: INVALID_FACTORY_ADDRESS");

        // Obtém as reservas atuais
        (uint256 reservesA, uint256 reservesB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);

        // Consulta parâmetros do par
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        bool feeOn = IUniswapV2Factory(factory).feeTo() != address(0);
        uint256 kLast = feeOn ? pair.kLast() : 0;
        uint256 totalSupply = pair.totalSupply();

        // Calcula o valor da liquidez
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }

    /**
     * @notice Calcula o valor de uma quantidade de tokens de liquidez após arbitragem que alinha o preço ao preço verdadeiro.
     * @dev Usa `getReservesAfterArbitrage` para obter reservas ajustadas e chama `computeLiquidityValue` para calcular o valor.
     *      Reverte se a quantidade de liquidez for inválida ou maior que o totalSupply.
     * @param factory Endereço do contrato factory Uniswap V2.
     * @param tokenA Endereço do token A.
     * @param tokenB Endereço do token B.
     * @param truePriceTokenA Preço verdadeiro do token A (uint256).
     * @param truePriceTokenB Preço verdadeiro do token B (uint256).
     * @param liquidityAmount Quantidade de tokens de liquidez a avaliar (uint256).
     * @return tokenAAmount Quantidade equivalente em token A (uint256).
     * @return tokenBAmount Quantidade equivalente em token B (uint256).
     */
    function getLiquidityValueAfterArbitrageToPrice(
        address factory,
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) internal view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        require(factory != address(0), "UniswapV2LiquidityMathLibrary: INVALID_FACTORY_ADDRESS");

        // Consulta parâmetros do par
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        bool feeOn = IUniswapV2Factory(factory).feeTo() != address(0);
        uint256 kLast = feeOn ? pair.kLast() : 0;
        uint256 totalSupply = pair.totalSupply();

        require(totalSupply >= liquidityAmount && liquidityAmount > 0, "UniswapV2LiquidityMathLibrary: INVALID_LIQUIDITY_AMOUNT");

        // Obtém as reservas ajustadas após arbitragem
        (uint256 reservesA, uint256 reservesB) = getReservesAfterArbitrage(factory, tokenA, tokenB, truePriceTokenA, truePriceTokenB);

        // Calcula o valor da liquidez com as reservas ajustadas
        return computeLiquidityValue(reservesA, reservesB, totalSupply, liquidityAmount, feeOn, kLast);
    }
}