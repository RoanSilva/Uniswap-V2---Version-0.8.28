// SPDX-License-Identifier: MIT
/**
 * @title ExampleOracleSimple
 * @notice Oráculo de preço com janela fixa para pares Uniswap V2
 * @dev Calcula a média de preços acumulada por período fixo (24 horas), compatível com Solidity 0.8.28
 *      Implementa padrões de nível empresarial com segurança reforçada e documentação detalhada
 */
pragma solidity 0.8.28;

// Importações de interfaces e bibliotecas necessárias
import {IUniswapV2Factory} from '../interfaces/pool/IUniswapV2Factory.sol';
import {IUniswapV2Pair} from '../interfaces/pool/IUniswapV2Pair.sol';
import {FixedPoint} from '@uniswap/lib/contracts/libraries/FixedPoint.sol';
import {UniswapV2OracleLibrary} from '../libraries/UniswapV2OracleLibrary.sol';
import {UniswapV2Library} from '../libraries/UniswapV2Library.sol';

/**
 * @notice Contrato principal para oráculo de preço com janela fixa
 */
contract ExampleOracleSimple {
    using FixedPoint for *;

    /// @notice Período fixo para cálculo da média de preço (24 horas em segundos)
    uint256 public constant PERIOD = 24 hours;

    /// @notice Par Uniswap V2 associado ao oráculo
    IUniswapV2Pair public immutable pair;
    /// @notice Endereço do token0 do par
    address public immutable token0;
    /// @notice Endereço do token1 do par
    address public immutable token1;

    /// @notice Último preço acumulado para token1/token0
    uint256 public price0CumulativeLast;
    /// @notice Último preço acumulado para token0/token1
    uint256 public price1CumulativeLast;
    /// @notice Último timestamp do bloco registrado
    uint32 public blockTimestampLast;
    /// @notice Média de preço para token1/token0 em formato uq112x112
    FixedPoint.uq112x112 public price0Average;
    /// @notice Média de preço para token0/token1 em formato uq112x112
    FixedPoint.uq112x112 public price1Average;

    /// @notice Evento emitido quando o contrato é implantado
    /// @param factory Endereço do factory Uniswap V2
    /// @param token0 Endereço do token0
    /// @param token1 Endereço do token1
    /// @param pair Endereço do par Uniswap V2
    event Deployed(address indexed factory, address indexed token0, address indexed token1, address pair);

    /// @notice Evento emitido quando o oráculo é atualizado
    /// @param price0Average Nova média de preço para token1/token0
    /// @param price1Average Nova média de preço para token0/token1
    /// @param blockTimestamp Timestamp do bloco da atualização
    event Updated(FixedPoint.uq112x112 price0Average, FixedPoint.uq112x112 price1Average, uint32 blockTimestamp);

    /**
     * @notice Construtor para inicializar o oráculo
     * @param factory Endereço do factory Uniswap V2
     * @param tokenA Endereço de um dos tokens do par
     * @param tokenB Endereço do outro token do par
     * @dev Inicializa o par, tokens e preços acumulados iniciais
     */
    constructor(address factory, address tokenA, address tokenB) {
        require(factory != address(0), "ExampleOracleSimple: ENDERECO_FACTORY_INVALIDO");
        require(tokenA != address(0) && tokenB != address(0), "ExampleOracleSimple: ENDERECO_TOKEN_INVALIDO");
        require(tokenA != tokenB, "ExampleOracleSimple: TOKENS_IDENTICOS");

        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        require(address(_pair) != address(0), "ExampleOracleSimple: PAR_INVALIDO");

        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();

        price0CumulativeLast = _pair.price0CumulativeLast();
        price1CumulativeLast = _pair.price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 _blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "ExampleOracleSimple: SEM_LIQUIDEZ");

        blockTimestampLast = _blockTimestampLast;

        emit Deployed(factory, token0, token1, address(_pair));
    }

    /**
     * @notice Atualiza as médias de preço do oráculo
     * @dev Calcula as médias de preço com base nos preços acumulados desde a última atualização
     *      Requer que pelo menos um período completo (24 horas) tenha passado
     */
    function update() external {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));

        // Calcula o tempo decorrido desde a última atualização (overflow é desejado)
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        require(timeElapsed >= PERIOD, "ExampleOracleSimple: PERIODO_NAO_COMPLETO");

        // Calcula as médias de preço (overflow é desejado)
        price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
        );
        price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
        );

        // Atualiza os valores acumulados e o timestamp
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;

        emit Updated(price0Average, price1Average, blockTimestamp);
    }

    /**
     * @notice Consulta a quantidade de saída para uma quantidade de entrada
     * @dev Retorna 0 se o oráculo não foi atualizado pelo menos uma vez
     * @param token Endereço do token de entrada
     * @param amountIn Quantidade de entrada
     * @return amountOut Quantidade de saída calculada com base na média de preço
     */
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut) {
        require(token == token0 || token == token1, "ExampleOracleSimple: TOKEN_INVALIDO");
        require(amountIn > 0, "ExampleOracleSimple: QUANTIDADE_ENTRADA_INVALIDA");

        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}