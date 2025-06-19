// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IUniswapV2ERC20} from '../interfaces/pool/IUniswapV2ERC20.sol';
import {SafeMath} from '../libraries/SafeMath.sol';

/**
 * @title UniswapV2ERC20
 * @author Uniswap V2 ERC20 Token
 * @notice Implementação do token ERC-20 para Uniswap V2, usado para representar liquidez em pares de troca.
 * @dev Implementa o padrão ERC-20 com suporte a EIP-2612 (permit) para aprovações off-chain.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções e estados.
 *      - Verificações explícitas de segurança (ex.: endereços zero, saldos insuficientes, assinaturas inválidas).
 *      - Uso de SafeMath para operações aritméticas, garantindo clareza em auditorias.
 *      - Suporte a EIP-712 para assinaturas estruturadas (permit).
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow e otimizações modernas.
 */
contract UniswapV2ERC20 { // is IUniswapV2ERC20 {
    using SafeMath for uint256;

    // ================================
    //           Estados
    // ================================

    /// @notice Nome do token, conforme padrão ERC-20.
    string public constant name = "Uniswap V2";

    /// @notice Símbolo do token, conforme padrão ERC-20.
    string public constant symbol = "UNI-V2";

    /// @notice Número de casas decimais do token, conforme padrão ERC-20.
    uint8 public constant decimals = 18;

    /// @notice Total de tokens em circulação.
    uint256 public totalSupply;

    /// @notice Saldo de tokens por endereço.
    mapping(address => uint256) public balanceOf;

    /// @notice Quantidade de tokens aprovada por um owner para um spender.
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Separador de domínio para assinaturas EIP-712.
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice Hash do tipo de dados para a função permit (EIP-2612).
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Contador de nonces por endereço para assinaturas permit.
    mapping(address => uint256) public nonces;

    // ================================
    //           Eventos
    // ================================

    /// @notice Emitido quando uma aprovação de gasto é concedida.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Emitido quando tokens são transferidos.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ================================
    //           Construtor
    // ================================

    /**
     * @notice Inicializa o contrato, configurando o DOMAIN_SEPARATOR para EIP-712.
     * @dev Calcula o DOMAIN_SEPARATOR com base no nome do token, versão, chainId e endereço do contrato.
     *      Usa assembly para obter o chainId de forma eficiente.
     */
    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    // ================================
    //           Funções Internas
    // ================================

    /**
     * @notice Cria tokens e os atribui a um endereço.
     * @dev Aumenta o totalSupply e o saldo do destinatário, emitindo um evento Transfer de address(0).
     *      Usa SafeMath para operações aritméticas seguras.
     *      Reverte se o destinatário for address(0) ou se o valor for zero.
     * @param to Endereço que receberá os tokens.
     * @param value Quantidade de tokens a criar.
     */
    function _mint(address to, uint256 value) internal {
        require(to != address(0), "UniswapV2ERC20: MINT_TO_ZERO_ADDRESS");
        require(value > 0, "UniswapV2ERC20: INVALID_MINT_AMOUNT");

        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Queima tokens de um endereço específico.
     * @dev Reduz o totalSupply e o saldo do remetente, emitindo um evento Transfer para address(0).
     *      Usa SafeMath para operações aritméticas seguras.
     *      Reverte se o remetente for address(0), o saldo for insuficiente ou o valor for zero.
     * @param from Endereço que terá os tokens queimados.
     * @param value Quantidade de tokens a queimar.
     */
    function _burn(address from, uint256 value) internal {
        require(from != address(0), "UniswapV2ERC20: BURN_FROM_ZERO_ADDRESS");
        require(value > 0, "UniswapV2ERC20: INVALID_BURN_AMOUNT");
        require(balanceOf[from] >= value, "UniswapV2ERC20: INSUFFICIENT_BALANCE");

        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Define a permissão de gasto para um gastador em nome de um titular.
     * @dev Atualiza a allowance e emite um evento Approval.
     *      Reverte se o owner ou spender for address(0).
     * @param owner Endereço do titular dos tokens.
     * @param spender Endereço autorizado a gastar.
     * @param value Quantidade aprovada.
     */
    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0), "UniswapV2ERC20: APPROVE_FROM_ZERO_ADDRESS");
        require(spender != address(0), "UniswapV2ERC20: APPROVE_TO_ZERO_ADDRESS");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @notice Transfere tokens entre endereços.
     * @dev Reduz o saldo do remetente, aumenta o saldo do destinatário e emite um evento Transfer.
     *      Usa SafeMath para operações aritméticas seguras.
     *      Reverte se o remetente ou destinatário for address(0), o saldo for insuficiente ou o valor for zero.
     * @param from Endereço remetente.
     * @param to Endereço destinatário.
     * @param value Quantidade a transferir.
     */
    function _transfer(address from, address to, uint256 value) private {
        require(from != address(0), "UniswapV2ERC20: TRANSFER_FROM_ZERO_ADDRESS");
        require(to != address(0), "UniswapV2ERC20: TRANSFER_TO_ZERO_ADDRESS");
        require(value > 0, "UniswapV2ERC20: INVALID_TRANSFER_AMOUNT");
        require(balanceOf[from] >= value, "UniswapV2ERC20: INSUFFICIENT_BALANCE");

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    // ================================
    //           Funções Externas
    // ================================

    /**
     * @notice Aprova um endereço para gastar tokens em nome do chamador.
     * @dev Chama a função interna `_approve` para atualizar a allowance.
     *      Emite um evento Approval.
     *      Reverte se o spender for address(0).
     * @param spender Endereço autorizado a gastar.
     * @param value Quantidade aprovada.
     * @return bool Sempre retorna true se a operação for bem-sucedida.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Transfere tokens do chamador para um endereço destinatário.
     * @dev Chama a função interna `_transfer` para realizar a transferência.
     *      Emite um evento Transfer.
     *      Reverte se o destinatário for address(0), o saldo for insuficiente ou o valor for zero.
     * @param to Endereço destinatário.
     * @param value Quantidade a transferir.
     * @return bool Sempre retorna true se a operação for bem-sucedida.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Transfere tokens de um endereço para outro usando uma permissão prévia.
     * @dev Verifica e atualiza a allowance (se não for máxima), chama `_transfer` e emite um evento Transfer.
     *      Usa SafeMath para subtração da allowance.
     *      Reverte se o remetente ou destinatário for address(0), o saldo ou allowance for insuficiente, ou o valor for zero.
     * @param from Endereço remetente.
     * @param to Endereço destinatário.
     * @param value Quantidade a transferir.
     * @return bool Sempre retorna true se a operação for bem-sucedida.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value > 0, "UniswapV2ERC20: INVALID_TRANSFER_AMOUNT");
        require(allowance[from][msg.sender] >= value, "UniswapV2ERC20: INSUFFICIENT_ALLOWANCE");

        // Atualiza a allowance apenas se não for máxima
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            allowance[from][msg.sender] = currentAllowance.sub(value);
        }

        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice Aprova gastos via assinatura off-chain (EIP-2612).
     * @dev Valida a assinatura usando EIP-712, incrementa o nonce e chama `_approve`.
     *      Reverte se o deadline expirar, a assinatura for inválida ou o owner/spender for address(0).
     * @param owner Endereço do titular dos tokens.
     * @param spender Endereço autorizado a gastar.
     * @param value Quantidade aprovada.
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
    ) external {
        require(deadline >= block.timestamp, "UniswapV2ERC20: EXPIRED_PERMIT");
        require(owner != address(0), "UniswapV2ERC20: INVALID_OWNER");
        require(spender != address(0), "UniswapV2ERC20: INVALID_SPENDER");

        // Calcula o digest da mensagem EIP-712
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );

        // Verifica a assinatura
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "UniswapV2ERC20: INVALID_SIGNATURE"
        );

        _approve(owner, spender, value);
    }
}