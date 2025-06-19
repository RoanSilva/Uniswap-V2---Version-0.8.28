// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IUniswapV2Pair
 * @author Uniswap V2 Pair Interface
 * @notice Interface para o contrato de par de liquidez do Uniswap V2.
 * @dev Define a estrutura padrão para operações de liquidez, swaps e permissões via assinatura no Uniswap V2.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções e eventos.
 *      - Organização modular com seções claras para eventos, metadados, funções ERC-20, permissões EIP-2612 e operações de liquidez.
 *      - Recomendações implícitas de segurança para implementações (ex.: validação de endereços, proteção contra reentrância, verificação de deadlines).
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
interface IUniswapV2Pair {
    // ================================
    //           Eventos
    // ================================

    /**
     * @notice Emitido quando uma aprovação de gasto é concedida.
     * @param owner Endereço do titular que concede a aprovação.
     * @param spender Endereço autorizado a gastar os tokens.
     * @param value Quantidade de tokens aprovada.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Emitido quando ocorre uma transferência de tokens de liquidez.
     * @param from Endereço remetente dos tokens.
     * @param to Endereço destinatário dos tokens.
     * @param value Quantidade de tokens transferida.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Emitido quando liquidez é adicionada ao par.
     * @param sender Endereço que adicionou a liquidez.
     * @param amount0 Quantidade de token0 adicionada.
     * @param amount1 Quantidade de token1 adicionada.
     */
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    /**
     * @notice Emitido quando liquidez é removida do par.
     * @param sender Endereço que removeu a liquidez.
     * @param amount0 Quantidade de token0 retirada.
     * @param amount1 Quantidade de token1 retirada.
     * @param to Endereço que recebeu os tokens retirados.
     */
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @notice Emitido quando ocorre um swap entre os tokens do par.
     * @param sender Endereço que iniciou o swap.
     * @param amount0In Quantidade de token0 enviada ao par.
     * @param amount1In Quantidade de token1 enviada ao par.
     * @param amount0Out Quantidade de token0 retirada do par.
     * @param amount1Out Quantidade de token1 retirada do par.
     * @param to Endereço que recebeu os tokens do swap.
     */
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /**
     * @notice Emitido quando as reservas do par são sincronizadas.
     * @param reserve0 Nova reserva de token0 após sincronização.
     * @param reserve1 Nova reserva de token1 após sincronização.
     */
    event Sync(uint112 reserve0, uint112 reserve1);

    // ================================
    //       Funções de Metadados
    // ================================

    /**
     * @notice Retorna o nome do token de liquidez do par.
     * @dev Geralmente retorna uma string como "Uniswap V2 LP".
     * @return Nome do token.
     */
    function name() external pure returns (string memory);

    /**
     * @notice Retorna o símbolo do token de liquidez do par.
     * @dev Geralmente retorna uma string como "UNI-V2".
     * @return Símbolo do token.
     */
    function symbol() external pure returns (string memory);

    /**
     * @notice Retorna o número de casas decimais do token de liquidez.
     * @dev Normalmente retorna 18 para compatibilidade com padrões ERC-20.
     * @return Número de casas decimais.
     */
    function decimals() external pure returns (uint8);

    // ================================
    //       Funções ERC-20
    // ================================

    /**
     * @notice Retorna o suprimento total de tokens de liquidez em circulação.
     * @dev Deve refletir a soma de todos os tokens emitidos pelo par.
     * @return Quantidade total de tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Retorna o saldo de tokens de liquidez de um endereço.
     * @param owner Endereço a ser consultado.
     * @return Saldo de tokens do endereço.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Retorna a quantidade de tokens que um spender pode gastar em nome do owner.
     * @param owner Endereço do titular.
     * @param spender Endereço autorizado.
     * @return Quantidade de tokens aprovada.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Aprova um endereço para gastar tokens em nome do chamador.
     * @dev Deve emitir o evento `Approval` e verificar que `spender` não é o endereço zero.
     * @param spender Endereço autorizado a gastar tokens.
     * @param value Quantidade de tokens aprovada.
     * @return bool Indicador de sucesso da operação.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @notice Transfere tokens de liquidez do chamador para outro endereço.
     * @dev Deve emitir o evento `Transfer` e verificar que `to` não é o endereço zero.
     * @param to Endereço destinatário.
     * @param value Quantidade de tokens a transferir.
     * @return bool Indicador de sucesso da operação.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfere tokens de um endereço para outro usando uma aprovação prévia.
     * @dev Deve emitir o evento `Transfer`, verificar a autorização e atualizar a allowance.
     * @param from Endereço remetente.
     * @param to Endereço destinatário.
     * @param value Quantidade de tokens a transferir.
     * @return bool Indicador de sucesso da operação.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // ================================
    //        Permissões via EIP-2612
    // ================================

    /**
     * @notice Retorna o separador de domínio conforme EIP-712.
     * @dev Usado para assinaturas off-chain (EIP-2612).
     * @return Separador de domínio codificado como bytes32.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Retorna o hash do tipo de permissão para EIP-2612.
     * @dev Define a estrutura da mensagem assinada para `permit`.
     * @return Hash do tipo de permissão.
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /**
     * @notice Retorna o nonce atual de um endereço para assinaturas EIP-2612.
     * @dev Protege contra ataques de replay incrementando o nonce após cada uso.
     * @param owner Endereço do titular.
     * @return Nonce atual do endereço.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Aprova um spender via assinatura off-chain conforme EIP-2612.
     * @dev Deve:
     *      - Validar a assinatura (v, r, s) e o `deadline` (block.timestamp <= deadline).
     *      - Verificar que `owner` e `spender` não são endereços zero.
     *      - Incrementar o nonce do `owner` para evitar replay.
     *      - Emitir o evento `Approval`.
     * @param owner Endereço do titular.
     * @param spender Endereço autorizado.
     * @param value Quantidade de tokens aprovada.
     * @param deadline Timestamp limite para validade da assinatura.
     * @param v Componente da assinatura ECDSA.
     * @param r Componente da assinatura ECDSA.
     * @param s Componente da assinatura ECDSA.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ================================
    //      Funções de Liquidez
    // ================================

    /**
     * @notice Retorna a quantidade mínima de liquidez permanente do par.
     * @dev Evita a remoção total de liquidez para proteger contra manipulações.
     * @return Quantidade mínima de liquidez.
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    /**
     * @notice Retorna o endereço da fábrica que criou o par.
     * @dev Usado para validação e interação com a fábrica Uniswap V2.
     * @return Endereço da fábrica.
     */
    function factory() external view returns (address);

    /**
     * @notice Retorna o endereço do token0 do par.
     * @dev Token0 é o token com endereço menor para ordenação canônica.
     * @return Endereço do token0.
     */
    function token0() external view returns (address);

    /**
     * @notice Retorna o endereço do token1 do par.
     * @dev Token1 é o token com endereço maior para ordenação canônica.
     * @return Endereço do token1.
     */
    function token1() external view returns (address);

    /**
     * @notice Retorna as reservas atuais do par e o timestamp da última atualização.
     * @dev Reservas são armazenadas como uint112 para otimização de gás.
     * @return reserve0 Reserva atual de token0.
     * @return reserve1 Reserva atual de token1.
     * @return blockTimestampLast Timestamp da última atualização das reservas.
     */
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    /**
     * @notice Retorna o preço acumulado do token0 para oráculos.
     * @dev Usado para cálculos de preço médio ponderado pelo tempo (TWAP).
     * @return Preço acumulado do token0.
     */
    function price0CumulativeLast() external view returns (uint256);

    /**
     * @notice Retorna o preço acumulado do token1 para oráculos.
     * @dev Usado para cálculos de preço médio ponderado pelo tempo (TWAP).
     * @return Preço acumulado do token1.
     */
    function price1CumulativeLast() external view returns (uint256);

    /**
     * @notice Retorna o último valor do produto das reservas (k).
     * @dev Usado para verificar a invariante do par (x * y = k).
     * @return Último valor de k.
     */
    function kLast() external view returns (uint256);

    /**
     * @notice Adiciona liquidez ao par e emite tokens de liquidez.
     * @dev Deve:
     *      - Verificar que `to` não é o endereço zero.
     *      - Validar os valores de entrada para manter a invariante do par.
     *      - Emitir o evento `Mint`.
     * @param to Endereço que receberá os tokens de liquidez.
     * @return liquidity Quantidade de tokens de liquidez emitidos.
     */
    function mint(address to) external returns (uint256 liquidity);

    /**
     * @notice Remove liquidez do par e transfere os tokens subjacentes.
     * @dev Deve:
     *      - Verificar que `to` não é o endereço zero.
     *      - Queimar os tokens de liquidez enviados.
     *      - Emitir o evento `Burn`.
     * @param to Endereço que receberá os tokens retirados.
     * @return amount0 Quantidade de token0 retirada.
     * @return amount1 Quantidade de token1 retirada.
     */
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Realiza um swap entre os tokens do par.
     * @dev Deve:
     *      - Verificar que `to` não é o endereço zero.
     *      - Garantir que pelo menos um dos valores de saída seja maior que zero.
     *      - Validar a invariante do par após o swap.
     *      - Proteger contra reentrância.
     *      - Emitir o evento `Swap`.
     * @param amount0Out Quantidade de token0 a ser enviada.
     * @param amount1Out Quantidade de token1 a ser enviada.
     * @param to Endereço destinatário dos tokens do swap.
     * @param data Dados adicionais para chamadas de callback (ex.: flash swaps).
     */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    /**
     * @notice Remove tokens não sincronizados do contrato.
     * @dev Usado para corrigir discrepâncias entre reservas e saldos reais.
     * @param to Endereço que receberá os tokens excedentes.
     */
    function skim(address to) external;

    /**
     * @notice Sincroniza as reservas internas com os saldos reais dos tokens.
     * @dev Deve emitir o evento `Sync` após a atualização das reservas.
     */
    function sync() external;

    /**
     * @notice Inicializa o par com os endereços dos tokens.
     * @dev Deve:
     *      - Ser chamada apenas uma vez pela fábrica.
     *      - Verificar que `tokenA` e `tokenB` são endereços válidos e distintos.
     *      - Ordenar os tokens para manter a ordenação canônica (token0 < token1).
     * @param tokenA Endereço do primeiro token.
     * @param tokenB Endereço do segundo token.
     */
    function initialize(address tokenA, address tokenB) external;
}