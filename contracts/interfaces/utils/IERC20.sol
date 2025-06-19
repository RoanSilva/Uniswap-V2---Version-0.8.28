// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IERC20
 * @author ERC20 Standard Interface
 * @notice Interface padrão ERC-20 para tokens fungíveis.
 * @dev Define a estrutura padrão para tokens ERC-20, incluindo eventos e funções para gerenciamento de tokens.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todos os eventos e funções.
 *      - Organização modular com seções claras para eventos e funções.
 *      - Recomendações implícitas de segurança para implementações (ex.: validação de endereços, proteção contra reentrância).
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 *      Baseado no padrão EIP-20 (https://eips.ethereum.org/EIPS/eip-20).
 */
interface IERC20 {
    // ================================
    //           Eventos
    // ================================

    /**
     * @notice Emitido quando uma aprovação de gasto é concedida.
     * @dev Conforme o padrão ERC-20, deve ser emitido pela função `approve`.
     * @param owner Endereço do titular que concede a aprovação.
     * @param spender Endereço autorizado a gastar os tokens.
     * @param value Quantidade de tokens aprovada.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Emitido quando tokens são transferidos.
     * @dev Conforme o padrão ERC-20, deve ser emitido pelas funções `transfer` e `transferFrom`.
     * @param from Endereço remetente dos tokens.
     * @param to Endereço destinatário dos tokens.
     * @param value Quantidade de tokens transferida.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ================================
    //           Funções
    // ================================

    /**
     * @notice Retorna o nome do token.
     * @dev Recomenda-se retornar um nome legível, como "MyToken".
     *      Implementações devem garantir que a string retornada seja válida.
     * @return Nome do token como uma string.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retorna o símbolo do token.
     * @dev Recomenda-se retornar um símbolo curto, como "MTK".
     *      Implementações devem garantir que a string retornada seja válida.
     * @return Símbolo do token como uma string.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retorna o número de casas decimais do token.
     * @dev Normalmente retorna 18, seguindo o padrão comum para tokens ERC-20.
     * @return Número de casas decimais do token.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Retorna o suprimento total de tokens em circulação.
     * @dev Deve refletir a soma de todos os saldos de tokens existentes.
     * @return Quantidade total de tokens em circulação.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Retorna o saldo de tokens de um endereço.
     * @dev Deve retornar zero para endereços sem saldo.
     * @param account Endereço do titular a ser consultado.
     * @return Saldo de tokens do endereço.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Retorna a quantidade de tokens que um spender pode gastar em nome de um owner.
     * @dev Deve retornar zero se nenhuma aprovação foi concedida.
     * @param owner Endereço do titular dos tokens.
     * @param spender Endereço autorizado a gastar os tokens.
     * @return Quantidade de tokens aprovada para o spender.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Aprova um endereço para gastar uma quantidade específica de tokens em nome do chamador.
     * @dev Deve:
     *      - Verificar que `spender` não é o endereço zero.
     *      - Emitir o evento `Approval` com os valores correspondentes.
     *      - Substituir qualquer aprovação anterior para o mesmo `spender`.
     *      Implementações devem considerar o risco de ataques de aprovação dupla (double-spending approval).
     *      Recomenda-se usar `increaseAllowance`/`decreaseAllowance` para evitar esse risco.
     * @param spender Endereço autorizado a gastar os tokens.
     * @param value Quantidade de tokens aprovada.
     * @return bool Indicador de sucesso da operação.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @notice Transfere tokens do chamador para um endereço destinatário.
     * @dev Deve:
     *      - Verificar que `to` não é o endereço zero.
     *      - Validar que o chamador possui saldo suficiente.
     *      - Emitir o evento `Transfer` com os valores correspondentes.
     *      Implementações devem proteger contra reentrância.
     * @param to Endereço destinatário dos tokens.
     * @param value Quantidade de tokens a transferir.
     * @return bool Indicador de sucesso da operação.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfere tokens de um endereço para outro usando uma autorização prévia.
     * @dev Deve:
     *      - Verificar que `from` e `to` não são endereços zero.
     *      - Validar que `from` possui saldo suficiente.
     *      - Verificar que o chamador possui autorização suficiente via `allowance`.
     *      - Reduzir a `allowance` correspondente após a transferência.
     *      - Emitir o evento `Transfer` com os valores correspondentes.
     *      Implementações devem proteger contra reentrância.
     * @param from Endereço remetente dos tokens.
     * @param to Endereço destinatário dos tokens.
     * @param value Quantidade de tokens a transferir.
     * @return bool Indicador de sucesso da operação.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}