// SPDX-License-Identifier: MIT
/**
 * @title ExampleComputeLiquidityValue
 * @notice Contrato para cálculo de valores de liquidez e reservas para pares Uniswap V2
 * @dev Integra com UniswapV2LiquidityMathLibrary para realizar cálculos, compatível com Solidity 0.8.28
 *      Implementa padrões de nível empresarial com segurança e otimização
 */
pragma solidity 0.8.28;

// Importações de dependências necessárias
import {SafeMath} from '../libraries/SafeMath.sol';
import {UniswapV2LiquidityMathLibrary} from '../libraries/UniswapV2LiquidityMathLibrary.sol';

/**
 * @notice Contrato principal para cálculos de liquidez
 */
contract ExampleComputeLiquidityValue {
    using SafeMath for uint256;

    /// @notice Endereço do factory Uniswap V2
    address public immutable factory;

    /// @notice Evento emitido quando o contrato é implantado
    /// @param factory Endereço do factory Uniswap V2
    event Deployed(address indexed factory);

    /**
     * @notice Construtor para inicializar o contrato
     * @param factory_ Endereço do factory Uniswap V2
     * @dev Armazena o endereço do factory como imutável para economia de gás
     */
    constructor(address factory_) {
        require(factory_ != address(0), "ExampleComputeLiquidityValue: ENDERECO_FACTORY_INVALIDO");
        factory = factory_;
        emit Deployed(factory_);
    }

    /**
     * @notice Obtém as reservas de um par de tokens após uma arbitragem hipotética
     * @dev Delega para UniswapV2LiquidityMathLibrary.getReservesAfterArbitrage
     * @param tokenA Endereço do primeiro token do par
     * @param tokenB Endereço do segundo token do par
     * @param truePriceTokenA Preço real do tokenA
     * @param truePriceTokenB Preço real do tokenB
     * @return reserveA Quantidade de reserva do tokenA
     * @return reserveB Quantidade de reserva do tokenB
     */
    function getReservesAfterArbitrage(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        require(tokenA != address(0) && tokenB != address(0), "ExampleComputeLiquidityValue: ENDERECO_TOKEN_INVALIDO");
        require(tokenA != tokenB, "ExampleComputeLiquidityValue: ENDERECOS_IDENTICOS");
        require(truePriceTokenA > 0 && truePriceTokenB > 0, "ExampleComputeLiquidityValue: PRECO_INVALIDO");

        return UniswapV2LiquidityMathLibrary.getReservesAfterArbitrage(
            factory,
            tokenA,
            tokenB,
            truePriceTokenA,
            truePriceTokenB
        );
    }

    /**
     * @notice Calcula as quantidades de tokens para uma dada quantidade de liquidez
     * @dev Delega para UniswapV2LiquidityMathLibrary.getLiquidityValue
     * @param tokenA Endereço do primeiro token do par
     * @param tokenB Endereço do segundo token do par
     * @param liquidityAmount Quantidade de tokens de liquidez
     * @return tokenAAmount Quantidade do tokenA
     * @return tokenBAmount Quantidade do tokenB
     */
    function getLiquidityValue(
        address tokenA,
        address tokenB,
        uint256 liquidityAmount
    ) external view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        require(tokenA != address(0) && tokenB != address(0), "ExampleComputeLiquidityValue: ENDERECO_TOKEN_INVALIDO");
        require(tokenA != tokenB, "ExampleComputeLiquidityValue: ENDERECOS_IDENTICOS");
        require(liquidityAmount > 0, "ExampleComputeLiquidityValue: QUANTIDADE_LIQUIDEZ_INVALIDA");

        return UniswapV2LiquidityMathLibrary.getLiquidityValue(
            factory,
            tokenA,
            tokenB,
            liquidityAmount
        );
    }

    /**
     * @notice Calcula as quantidades de tokens para uma quantidade de liquidez após arbitragem para um preço alvo
     * @dev Delega para UniswapV2LiquidityMathLibrary.getLiquidityValueAfterArbitrageToPrice
     * @param tokenA Endereço do primeiro token do par
     * @param tokenB Endereço do segundo token do par
     * @param truePriceTokenA Preço real do tokenA
     * @param truePriceTokenB Preço real do tokenB
     * @param liquidityAmount Quantidade de tokens de liquidez
     * @return tokenAAmount Quantidade do tokenA
     * @return tokenBAmount Quantidade do tokenB
     */
    function getLiquidityValueAfterArbitrageToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) external view returns (uint256 tokenAAmount, uint256 tokenBAmount) {
        require(tokenA != address(0) && tokenB != address(0), "ExampleComputeLiquidityValue: ENDERECO_TOKEN_INVALIDO");
        require(tokenA != tokenB, "ExampleComputeLiquidityValue: ENDERECOS_IDENTICOS");
        require(truePriceTokenA > 0 && truePriceTokenB > 0, "ExampleComputeLiquidityValue: PRECO_INVALIDO");
        require(liquidityAmount > 0, "ExampleComputeLiquidityValue: QUANTIDADE_LIQUIDEZ_INVALIDA");

        return UniswapV2LiquidityMathLibrary.getLiquidityValueAfterArbitrageToPrice(
            factory,
            tokenA,
            tokenB,
            truePriceTokenA,
            truePriceTokenB,
            liquidityAmount
        );
    }

    /**
     * @notice Mede o custo de gás da função getLiquidityValueAfterArbitrageToPrice
     * @dev Usado para análise de otimização de gás
     * @param tokenA Endereço do primeiro token do par
     * @param tokenB Endereço do segundo token do par
     * @param truePriceTokenA Preço real do tokenA
     * @param truePriceTokenB Preço real do tokenB
     * @param liquidityAmount Quantidade de tokens de liquidez
     * @return gasUsed Quantidade de gás consumido pela função
     */
    function getGasCostOfGetLiquidityValueAfterArbitrageToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 liquidityAmount
    ) external view returns (uint256 gasUsed) {
        require(tokenA != address(0) && tokenB != address(0), "ExampleComputeLiquidityValue: ENDERECO_TOKEN_INVALIDO");
        require(tokenA != tokenB, "ExampleComputeLiquidityValue: ENDERECOS_IDENTICOS");
        require(truePriceTokenA > 0 && truePriceTokenB > 0, "ExampleComputeLiquidityValue: PRECO_INVALIDO");
        require(liquidityAmount > 0, "ExampleComputeLiquidityValue: QUANTIDADE_LIQUIDEZ_INVALIDA");

        uint256 gasBefore = gasleft();
        UniswapV2LiquidityMathLibrary.getLiquidityValueAfterArbitrageToPrice(
            factory,
            tokenA,
            tokenB,
            truePriceTokenA,
            truePriceTokenB,
            liquidityAmount
        );
        uint256 gasAfter = gasleft();
        gasUsed = gasBefore - gasAfter;
    }
}