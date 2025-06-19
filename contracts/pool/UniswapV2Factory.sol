// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2Factory} from '../interfaces/pool/IUniswapV2Factory.sol';
import {UniswapV2Pair} from '../pool/UniswapV2Pair.sol';

/**
 * @title UniswapV2Factory
 * @author Uniswap V2 Factory
 * @notice Contrato factory para criação e gerenciamento de pares de troca Uniswap V2.
 * @dev Implementa a lógica para criar pares de tokens, configurar taxas do protocolo e rastrear pares criados.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções e estados.
 *      - Verificações explícitas de segurança (ex.: endereços inválidos, pares duplicados).
 *      - Uso de CREATE2 para endereços determinísticos de pares.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
contract UniswapV2Factory is IUniswapV2Factory {
    // ================================
    //           Estados
    // ================================

    /// @notice Endereço que recebe as taxas do protocolo, ou address(0) se desativado.
    address public override feeTo;

    /// @notice Endereço autorizado a configurar o destinatário das taxas.
    address public override feeToSetter;

    /// @notice Mapeamento de pares de tokens (token0, token1) para o endereço do par.
    mapping(address => mapping(address => address)) public override getPair;

    /// @notice Lista de todos os pares criados pelo factory.
    address[] public override allPairs;

    // ================================
    //           Eventos
    // ================================

    /// @notice Emitido quando um novo par é criado.
    /// @param token0 Endereço do primeiro token (ordenado).
    /// @param token1 Endereço do segundo token (ordenado).
    /// @param pair Endereço do par criado.
    /// @param pairCount Número total de pares criados.
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint256 pairCount);

    // ================================
    //           Construtor
    // ================================

    /**
     * @notice Inicializa o contrato com o endereço autorizado a configurar taxas.
     * @dev Reverte se o endereço fornecido for address(0).
     * @param _feeToSetter Endereço que terá permissão para configurar o destinatário das taxas.
     */
    constructor(address _feeToSetter) {
        require(_feeToSetter != address(0), "UniswapV2Factory: INVALID_FEE_TO_SETTER");
        feeToSetter = _feeToSetter;
    }

    // ================================
    //           Funções de Consulta
    // ================================

    /**
     * @notice Retorna o número total de pares criados.
     * @dev Usa o comprimento do array allPairs para determinar a contagem.
     * @return uint256 Quantidade total de pares criados.
     */
    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    // ================================
    //           Funções de Gerenciamento
    // ================================

    /**
     * @notice Cria um novo par Uniswap V2 para dois tokens distintos.
     * @dev Usa CREATE2 para criar o par com endereço determinístico baseado nos tokens ordenados.
     *      Ordena os tokens (token0 < token1) para consistência.
     *      Inicializa o par com os tokens ordenados e atualiza os mapeamentos.
     *      Reverte se:
     *      - Os tokens forem idênticos.
     *      - Um dos tokens for address(0).
     *      - O par já existir.
     *      - A criação do par falhar.
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     * @return pair Endereço do par criado.
     */
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        // Verifica se os tokens são distintos
        require(tokenA != tokenB, "UniswapV2Factory: IDENTICAL_ADDRESSES");

        // Ordena os tokens para garantir consistência
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Factory: ZERO_ADDRESS");

        // Verifica se o par já existe
        require(getPair[token0][token1] == address(0), "UniswapV2Factory: PAIR_EXISTS");

        // Cria o par usando CREATE2
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new UniswapV2Pair{salt: salt}());

        // Inicializa o par com os tokens ordenados
        UniswapV2Pair(pair).initialize(token0, token1);

        // Atualiza os mapeamentos
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // Mapeamento reverso para conveniência

        // Adiciona o par à lista
        allPairs.push(pair);

        // Emite o evento de criação
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @notice Define o endereço que receberá as taxas do protocolo.
     * @dev Apenas o feeToSetter pode chamar esta função.
     *      O endereço pode ser address(0) para desativar as taxas.
     *      Reverte se o chamador não for o feeToSetter.
     * @param _feeTo Novo endereço destinatário das taxas.
     */
    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV2Factory: FORBIDDEN");
        feeTo = _feeTo;
    }

    /**
     * @notice Define o endereço autorizado a configurar o destinatário das taxas.
     * @dev Apenas o feeToSetter atual pode chamar esta função.
     *      Reverte se o chamador não for o feeToSetter ou se o novo endereço for address(0).
     * @param _feeToSetter Novo endereço autorizado a configurar taxas.
     */
    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2Factory: FORBIDDEN");
        require(_feeToSetter != address(0), "UniswapV2Factory: INVALID_FEE_TO_SETTER");
        feeToSetter = _feeToSetter;
    }
}