// SPDX-License-Identifier: MIT
/**
 * @title IUniswapV2ERC20
 * @notice Interface para tokens ERC20 compatíveis com Uniswap V2, incluindo suporte a permit
 * @dev Define métodos padrão ERC20 e funcionalidades adicionais para aprovações off-chain, compatível com Solidity 0.8.28
 *      Implementa padrões de nível empresarial com documentação detalhada
 * @custom:disclaimer Aviso: Esta interface é apenas para fins demonstrativos. Embora seja projetada para interagir com contratos Uniswap V2,
 *                    não há garantias sobre sua correção ou segurança. Esta interface é mantida em um padrão diferente de outros contratos no repositório,
 *                    sendo explicitamente excluída do programa de recompensas por bugs (bug bounty). Realize sua própria due diligence antes de usar esta interface em seu projeto.
 */
pragma solidity 0.8.28;

/**
 * @notice Interface para tokens ERC20 compatíveis com Uniswap V2
 */
interface IUniswapV2ERC20 {
    /**
     * @notice Evento emitido quando uma aprovação de gasto é configurada
     * @param owner Endereço do proprietário dos tokens
     * @param spender Endereço autorizado a gastar os tokens
     * @param value Quantidade de tokens aprovada
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Evento emitido quando uma transferência de tokens é realizada
     * @param from Endereço de origem dos tokens
     * @param to Endereço de destino dos tokens
     * @param value Quantidade de tokens transferida
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Retorna o nome do token
     * @return Nome do token como string
     */
    function name() external pure returns (string memory);

    /**
     * @notice Retorna o símbolo do token
     * @return Símbolo do token como string
     */
    function symbol() external pure returns (string memory);

    /**
     * @notice Retorna o número de casas decimais do token
     * @return Número de casas decimais
     */
    function decimals() external pure returns (uint8);

    /**
     * @notice Retorna o fornecimento total de tokens
     * @return Quantidade total de tokens em circulação
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Consulta o saldo de tokens de um endereço
     * @param owner Endereço do proprietário a ser consultado
     * @return Saldo de tokens do proprietário
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Consulta a quantidade de tokens que um spender pode gastar em nome de um owner
     * @param owner Endereço do proprietário dos tokens
     * @param spender Endereço autorizado a gastar os tokens
     * @return Quantidade de tokens permitida
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Aprova um endereço para gastar uma quantidade de tokens em nome do chamador
     * @param spender Endereço autorizado a gastar os tokens
     * @param value Quantidade de tokens a aprovar
     * @return bool Indicador de sucesso da aprovação
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @notice Transfere tokens do chamador para um endereço de destino
     * @param to Endereço de destino dos tokens
     * @param value Quantidade de tokens a transferir
     * @return bool Indicador de sucesso da transferência
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfere tokens de um endereço para outro, usando uma aprovação prévia
     * @param from Endereço de origem dos tokens
     * @param to Endereço de destino dos tokens
     * @param value Quantidade de tokens a transferir
     * @return bool Indicador de sucesso da transferência
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Retorna o separador de domínio para assinaturas EIP-712
     * @return Hash do separador de domínio
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Retorna o hash do tipo de permissão para assinaturas EIP-712
     * @return Hash do tipo de permissão
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /**
     * @notice Consulta o nonce atual de um endereço para assinaturas EIP-712
     * @param owner Endereço do proprietário
     * @return Nonce atual do proprietário
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Permite aprovações off-chain usando assinaturas EIP-712
     * @param owner Endereço do proprietário dos tokens
     * @param spender Endereço autorizado a gastar os tokens
     * @param value Quantidade de tokens a aprovar
     * @param deadline Timestamp limite para a validade da assinatura
     * @param v Componente v da assinatura ECDSA
     * @param r Componente r da assinatura ECDSA
     * @param s Componente s da assinatura ECDSA
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
}