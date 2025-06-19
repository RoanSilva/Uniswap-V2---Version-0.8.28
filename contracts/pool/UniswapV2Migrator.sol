// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {TransferHelper} from '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import {IUniswapV2Migrator} from '../interfaces/pool/IUniswapV2Migrator.sol';
import {IUniswapV1Factory} from '../interfaces/pool/IUniswapV1Factory.sol';
import {IUniswapV1Exchange} from '../interfaces/pool/IUniswapV1Exchange.sol';
import {IUniswapV2Router01} from '../interfaces/pool/IUniswapV2Router01.sol';

/**
 * @title UniswapV2Migrator
 * @author Uniswap V2 Liquidity Migrator
 * @notice Contrato para migrar liquidez de pares Uniswap V1 para Uniswap V2.
 * @dev Facilita a transferência de liquidez de exchanges V1 para pares V2, incluindo a conversão de tokens de liquidez V1
 *      em tokens de liquidez V2, com suporte a ETH e tokens ERC-20.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções e estados.
 *      - Verificações explícitas de segurança (ex.: endereços inválidos, saldos insuficientes, proteção contra slippage).
 *      - Uso de TransferHelper para transferências seguras de tokens e ETH.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
contract UniswapV2Migrator is IUniswapV2Migrator {
    // ================================
    //           Estados
    // ================================

    /// @notice Endereço imutável da factory do Uniswap V1.
    IUniswapV1Factory public immutable factoryV1;

    /// @notice Endereço imutável do router do Uniswap V2.
    IUniswapV2Router01 public immutable router;

    // ================================
    //           Construtor
    // ================================

    /**
     * @notice Inicializa o contrato com os endereços da factory V1 e do router V2.
     * @dev Reverte se os endereços fornecidos forem address(0).
     *      Os endereços são marcados como imutáveis para otimização de gás.
     * @param _factoryV1 Endereço da factory Uniswap V1.
     * @param _router Endereço do router Uniswap V2.
     */
    constructor(address _factoryV1, address _router) {
        require(_factoryV1 != address(0), "UniswapV2Migrator: INVALID_FACTORY_V1_ADDRESS");
        require(_router != address(0), "UniswapV2Migrator: INVALID_ROUTER_ADDRESS");
        factoryV1 = IUniswapV1Factory(_factoryV1);
        router = IUniswapV2Router01(_router);
    }

    // ================================
    //           Funções de Recebimento
    // ================================

    /**
     * @notice Permite que o contrato receba ETH durante a migração.
     * @dev Necessário para aceitar ETH retornado de exchanges V1 ou do router V2.
     */
    receive() external payable {}

    // ================================
    //           Funções de Migração
    // ================================

    /**
     * @notice Migra liquidez de um par Uniswap V1 para Uniswap V2.
     * @dev Realiza as seguintes etapas:
     *      1. Verifica se o usuário possui liquidez V1 e transfere os tokens de liquidez V1 para o contrato.
     *      2. Remove a liquidez do par V1, recebendo ETH e tokens.
     *      3. Aprova o router V2 para gastar os tokens recebidos.
     *      4. Adiciona a liquidez ao par V2, respeitando os limites mínimos de saída.
     *      5. Reembolsa tokens ou ETH excedentes ao usuário.
     *      Reverte se:
     *      - O token não tiver um par V1 associado.
     *      - O usuário não tiver liquidez V1.
     *      - A transferência de tokens V1 falhar.
     *      - Os valores mínimos de saída não forem atendidos.
     *      - O deadline for ultrapassado.
     * @param token Endereço do token do par V1 a migrar.
     * @param amountTokenMin Quantidade mínima de tokens a receber no par V2 (proteção contra slippage).
     * @param amountETHMin Quantidade mínima de ETH a receber no par V2 (proteção contra slippage).
     * @param to Endereço que receberá os tokens de liquidez V2.
     * @param deadline Timestamp limite para execução da migração.
     */
    function migrate(
        address token,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override {
        require(token != address(0), "UniswapV2Migrator: INVALID_TOKEN_ADDRESS");
        require(to != address(0), "UniswapV2Migrator: INVALID_RECIPIENT_ADDRESS");
        require(deadline >= block.timestamp, "UniswapV2Migrator: EXPIRED_DEADLINE");

        // Obtém o endereço do exchange V1 e verifica a liquidez do usuário
        IUniswapV1Exchange exchangeV1 = IUniswapV1Exchange(factoryV1.getExchange(token));
        require(address(exchangeV1) != address(0), "UniswapV2Migrator: NO_V1_EXCHANGE");
        uint256 liquidityV1 = exchangeV1.balanceOf(msg.sender);
        require(liquidityV1 > 0, "UniswapV2Migrator: NO_LIQUIDITY");

        // Transfere os tokens de liquidez V1 do usuário para o contrato
        require(
            exchangeV1.transferFrom(msg.sender, address(this), liquidityV1),
            "UniswapV2Migrator: TRANSFER_FROM_FAILED"
        );

        // Remove a liquidez do par V1, recebendo ETH e tokens
        (uint256 amountETHV1, uint256 amountTokenV1) = exchangeV1.removeLiquidity(
            liquidityV1,
            1, // Quantidade mínima de token
            1, // Quantidade mínima de ETH
            type(uint256).max // Deadline máximo
        );
        require(amountETHV1 > 0 && amountTokenV1 > 0, "UniswapV2Migrator: INSUFFICIENT_V1_LIQUIDITY");

        // Aprova o router V2 para gastar os tokens recebidos
        TransferHelper.safeApprove(token, address(router), amountTokenV1);

        // Adiciona a liquidez ao par V2, enviando ETH e tokens
        (uint256 amountTokenV2, uint256 amountETHV2, ) = router.addLiquidityETH{value: amountETHV1}(
            token,
            amountTokenV1,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );

        // Reembolsa tokens ou ETH excedentes ao usuário
        if (amountTokenV1 > amountTokenV2) {
            // Reseta a aprovação por segurança
            TransferHelper.safeApprove(token, address(router), 0);
            // Retorna tokens excedentes
            TransferHelper.safeTransfer(token, msg.sender, amountTokenV1 - amountTokenV2);
        }
        if (amountETHV1 > amountETHV2) {
            // Retorna ETH excedente
            TransferHelper.safeTransferETH(msg.sender, amountETHV1 - amountETHV2);
        }
    }
}