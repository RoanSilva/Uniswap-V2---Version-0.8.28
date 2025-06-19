// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IWETH
 * @author Wrapped Ether Interface
 * @notice Interface para o contrato Wrapped Ether (WETH), que tokeniza Ether (ETH) em um formato ERC-20.
 * @dev Define funções essenciais para depósito, retirada e transferência de WETH.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções.
 *      - Recomendações implícitas de segurança para implementações (ex.: validação de endereços, verificação de saldos).
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 *      Baseado no padrão WETH amplamente utilizado em DeFi.
 */
interface IWETH {
    // ================================
    //           Eventos
    // ================================

    /**
     * @notice Emitido quando ETH é depositado e WETH é emitido.
     * @dev Conforme o padrão ERC-20, deve ser emitido pela função `deposit`.
     * @param depositor Endereço que realizou o depósito.
     * @param amount Quantidade de ETH depositada e WETH emitida.
     */
    event Deposit(address indexed depositor, uint256 amount);

    /**
     * @notice Emitido quando WETH é queimado e ETH é retirado.
     * @dev Conforme o padrão ERC-20, deve ser emitido pela função `withdraw`.
     * @param withdrawer Endereço que realizou a retirada.
     * @param amount Quantidade de WETH queimada e ETH retirada.
     */
    event Withdrawal(address indexed withdrawer, uint256 amount);

    /**
     * @notice Emitido quando tokens WETH são transferidos.
     * @dev Conforme o padrão ERC-20, deve ser emitido pela função `transfer`.
     * @param from Endereço remetente dos tokens.
     * @param to Endereço destinatário dos tokens.
     * @param value Quantidade de tokens transferida.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ================================
    //           Funções
    // ================================

    /**
     * @notice Deposita ETH e emite tokens WETH equivalentes para o chamador.
     * @dev Deve:
     *      - Ser uma função pagável que aceita `msg.value` como quantidade de ETH.
     *      - Verificar que `msg.value` é maior que zero.
     *      - Emitir tokens WETH em uma proporção 1:1 com o ETH depositado.
     *      - Emitir o evento `Deposit` com os valores correspondentes.
     *      Implementações devem garantir que o contrato tenha saldo suficiente de ETH.
     */
    function deposit() external payable;

    /**
     * @notice Transfere tokens WETH para um endereço especificado.
     * @dev Deve:
     *      - Verificar que `to` não é o endereço zero.
     *      - Validar que o chamador possui saldo suficiente de WETH.
     *      - Emitir o evento `Transfer` com os valores correspondentes.
     *      Implementações devem proteger contra reentrância.
     * @param to Endereço destinatário dos tokens WETH.
     * @param value Quantidade de tokens WETH a transferir.
     * @return bool Indicador de sucesso da operação.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Queima tokens WETH e transfere ETH equivalente para o chamador.
     * @dev Deve:
     *      - Verificar que `amount` é maior que zero.
     *      - Validar que o chamador possui saldo suficiente de WETH.
     *      - Verificar que o contrato possui ETH suficiente para a retirada.
     *      - Queimar os tokens WETH e transferir ETH em uma proporção 1:1.
     *      - Emitir o evento `Withdrawal` com os valores correspondentes.
     *      Implementações devem proteger contra reentrância e garantir transferências seguras de ETH.
     * @param amount Quantidade de WETH a ser queimada e convertida em ETH.
     */
    function withdraw(uint256 amount) external;
}