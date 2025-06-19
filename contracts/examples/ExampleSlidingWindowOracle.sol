// SPDX-License-Identifier: MIT
/**
 * @title ExampleSlidingWindowOracle
 * @notice Oráculo de preço com janela deslizante para pares Uniswap V2
 * @dev Fornece médias de preço móveis com base em observações coletadas em uma janela de tempo
 *      Compatível com Solidity 0.8.28, implementa padrões de nível empresarial com segurança e otimização
 */
pragma solidity 0.8.28;

// Importações de interfaces e bibliotecas necessárias
import {IUniswapV2Factory} from '../interfaces/pool/IUniswapV2Factory.sol';
import {IUniswapV2Pair} from '../interfaces/pool/IUniswapV2Pair.sol';
import {FixedPoint} from '@uniswap/lib/contracts/libraries/FixedPoint.sol';
import {SafeMath} from '../libraries/SafeMath.sol';
import {UniswapV2Library} from '../libraries/UniswapV2Library.sol';
import {UniswapV2OracleLibrary} from '../libraries/UniswapV2OracleLibrary.sol';

/**
 * @notice Contrato principal para oráculo de preço com janela deslizante
 */
contract ExampleSlidingWindowOracle {
    using FixedPoint for *;
    using SafeMath for uint256;

    /// @notice Estrutura para armazenar observações de preço
    struct Observation {
        uint256 timestamp; // Timestamp da observação
        uint256 price0Cumulative; // Preço acumulado para token1/token0
        uint256 price1Cumulative; // Preço acumulado para token0/token1
    }

    /// @notice Endereço do factory Uniswap V2
    address public immutable factory;
    /// @notice Tamanho da janela de tempo para cálculo da média (em segundos)
    uint256 public immutable windowSize;
    /// @notice Granularidade (número de observações na janela)
    uint8 public immutable granularity;
    /// @notice Tamanho do período entre observações (windowSize / granularity)
    uint256 public immutable periodSize;

    /// @notice Mapeamento de endereço do par para lista de observações de preço
    mapping(address => Observation[]) public pairObservations;

    /// @notice Evento emitido quando o contrato é implantado
    /// @param factory Endereço do factory Uniswap V2
    /// @param windowSize Tamanho da janela de tempo
    /// @param granularity Granularidade do oráculo
    event Deployed(address indexed factory, uint256 windowSize, uint8 granularity);

    /// @notice Evento emitido quando uma observação é atualizada
    /// @param pair Endereço do par Uniswap V2
    /// @param timestamp Timestamp da nova observação
    /// @param price0Cumulative Preço acumulado para token1/token0
    /// @param price1Cumulative Preço acumulado para token0/token1
    event ObservationUpdated(
        address indexed pair,
        uint256 timestamp,
        uint256 price0Cumulative,
        uint256 price1Cumulative
    );

    /**
     * @notice Construtor para inicializar o oráculo
     * @param factory_ Endereço do factory Uniswap V2
     * @param windowSize_ Tamanho da janela de tempo (em segundos)
     * @param granularity_ Granularidade (número de observações)
     * @dev Valida parâmetros e inicializa variáveis imutáveis
     */
    constructor(address factory_, uint256 windowSize_, uint8 granularity_) {
        require(factory_ != address(0), "SlidingWindowOracle: ENDERECO_FACTORY_INVALIDO");
        require(granularity_ > 1, "SlidingWindowOracle: GRANULARIDADE_INVALIDA");
        require(windowSize_ > 0, "SlidingWindowOracle: TAMANHO_JANELA_INVALIDO");

        uint256 _periodSize = windowSize_ / granularity_;
        require(
            _periodSize * granularity_ == windowSize_,
            "SlidingWindowOracle: JANELA_NAO_DIVISIVEL"
        );

        factory = factory_;
        windowSize = windowSize_;
        granularity = granularity_;
        periodSize = _periodSize;

        emit Deployed(factory_, windowSize_, granularity_);
    }

    /**
     * @notice Retorna o índice da observação correspondente a um timestamp
     * @param timestamp Timestamp para calcular o índice
     * @return index Índice da observação (0 a granularity-1)
     */
    function observationIndexOf(uint256 timestamp) public view returns (uint8 index) {
        uint256 epochPeriod = timestamp / periodSize;
        return uint8(epochPeriod % granularity);
    }

    /**
     * @notice Obtém a primeira observação na janela para um par
     * @param pair Endereço do par Uniswap V2
     * @return firstObservation Observação mais antiga na janela
     */
    function getFirstObservationInWindow(address pair)
        private
        view
        returns (Observation storage firstObservation)
    {
        uint8 observationIndex = observationIndexOf(block.timestamp);
        uint8 firstObservationIndex = (observationIndex + 1) % granularity;
        return pairObservations[pair][firstObservationIndex];
    }

    /**
     * @notice Atualiza os preços acumulados para um par na observação atual
     * @param tokenA Endereço de um dos tokens do par
     * @param tokenB Endereço do outro token do par
     * @dev Atualiza apenas uma vez por período (windowSize / granularity)
     */
    function update(address tokenA, address tokenB) external {
        require(tokenA != address(0) && tokenB != address(0), "SlidingWindowOracle: ENDERECO_TOKEN_INVALIDO");
        require(tokenA != tokenB, "SlidingWindowOracle: TOKENS_IDENTICOS");

        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        require(pair != address(0), "SlidingWindowOracle: PAR_INVALIDO");

        // Inicializa array de observações, se necessário
        if (pairObservations[pair].length < granularity) {
            for (uint8 i = uint8(pairObservations[pair].length); i < granularity; i++) {
                pairObservations[pair].push(Observation(0, 0, 0));
            }
        }

        // Obtém a observação para o período atual
        uint8 observationIndex = observationIndexOf(block.timestamp);
        Observation storage observation = pairObservations[pair][observationIndex];

        // Atualiza apenas se o período anterior terminou
        uint256 timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            (uint256 price0Cumulative, uint256 price1Cumulative,) =
                UniswapV2OracleLibrary.currentCumulativePrices(pair);

            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;

            emit ObservationUpdated(pair, block.timestamp, price0Cumulative, price1Cumulative);
        }
    }

    /**
     * @notice Calcula a quantidade de saída com base na média de preço
     * @param priceCumulativeStart Preço acumulado no início do período
     * @param priceCumulativeEnd Preço acumulado no fim do período
     * @param timeElapsed Tempo decorrido entre as observações
     * @param amountIn Quantidade de entrada
     * @return amountOut Quantidade de saída calculada
     */
    function computeAmountOut(
        uint256 priceCumulativeStart,
        uint256 priceCumulativeEnd,
        uint256 timeElapsed,
        uint256 amountIn
    ) private pure returns (uint256 amountOut) {
        require(timeElapsed > 0, "SlidingWindowOracle: TEMPO_INVALIDO");
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    /**
     * @notice Consulta a quantidade de saída para uma quantidade de entrada
     * @param tokenIn Endereço do token de entrada
     * @param amountIn Quantidade de entrada
     * @param tokenOut Endereço do token de saída
     * @return amountOut Quantidade de saída com base na média de preço
     * @dev Requer que a observação mais antiga esteja dentro da janela
     */
    function consult(address tokenIn, uint256 amountIn, address tokenOut)
        external
        view
        returns (uint256 amountOut)
    {
        require(tokenIn != address(0) && tokenOut != address(0), "SlidingWindowOracle: ENDERECO_TOKEN_INVALIDO");
        require(tokenIn != tokenOut, "SlidingWindowOracle: TOKENS_IDENTICOS");
        require(amountIn > 0, "SlidingWindowOracle: QUANTIDADE_ENTRADA_INVALIDA");

        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        require(pair != address(0), "SlidingWindowOracle: PAR_INVALIDO");

        Observation storage firstObservation = getFirstObservationInWindow(pair);
        require(firstObservation.timestamp != 0, "SlidingWindowOracle: SEM_OBSERVACOES");

        uint256 timeElapsed = block.timestamp - firstObservation.timestamp;
        require(timeElapsed <= windowSize, "SlidingWindowOracle: OBSERVACAO_FALTANDO");
        require(
            timeElapsed >= windowSize - periodSize * 2,
            "SlidingWindowOracle: TEMPO_INESPERADO"
        );

        (uint256 price0Cumulative, uint256 price1Cumulative,) =
            UniswapV2OracleLibrary.currentCumulativePrices(pair);
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(
                firstObservation.price0Cumulative,
                price0Cumulative,
                timeElapsed,
                amountIn
            );
        } else {
            return computeAmountOut(
                firstObservation.price1Cumulative,
                price1Cumulative,
                timeElapsed,
                amountIn
            );
        }
    }
}