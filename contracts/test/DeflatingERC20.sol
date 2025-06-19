// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SafeMath} from '../libraries/SafeMath.sol';

/**
 * @title DeflatingERC20
 * @notice Um token ERC-20 deflacionário que queima 1% dos tokens transferidos.
 * @dev Implementa o padrão ERC-20 com suporte a EIP-2612 (permits) e mecanismo deflacionário.
 *      Cada transferência queima 1% do valor transferido, reduzindo o totalSupply.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções, estados e eventos.
 *      - Verificações explícitas de segurança (ex.: endereços inválidos, saldos insuficientes).
 *      - Uso de SafeMath para operações aritméticas seguras.
 *      - Suporte a EIP-712 e EIP-2612 para aprovações off-chain.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow.
 */
contract DeflatingERC20 {
    using SafeMath for uint256;

    // ================================
    //           Constantes
    // ================================

    /// @notice Nome do token.
    string public constant name = "Deflating Test Token";

    /// @notice Símbolo do token.
    string public constant symbol = "DTT";

    /// @notice Número de casas decimais do token.
    uint8 public constant decimals = 18;

    /// @notice Hash do tipo de dados para o permit (EIP-2612).
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Taxa de queima aplicada em cada transferência (1% = 1/100).
    uint256 private constant BURN_RATE = 100;

    // ================================
    //           Estados
    // ================================

    /// @notice Fornecimento total de tokens.
    uint256 public totalSupply;

    /// @notice Saldos de tokens por endereço.
    mapping(address => uint256) public balanceOf;

    /// @notice Aprovações de gastos entre proprietário e gastador.
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Separador de domínio para EIP-712.
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice Nonces para cada endereço, usados no permit (EIP-2612).
    mapping(address => uint256) public nonces;

    // ================================
    //           Eventos
    // ================================

    /// @notice Emite quando uma aprovação de gasto é feita.
    /// @param owner Endereço do proprietário dos tokens.
    /// @param spender Endereço autorizado a gastar.
    /// @param value Quantidade aprovada.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Emite quando uma transferência de tokens ocorre.
    /// @param from Endereço de origem.
    /// @param to Endereço de destino.
    /// @param value Quantidade transferida.
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ================================
    //           Construtor
    // ================================

    /**
     * @notice Inicializa o contrato com o fornecimento total inicial e configura o domínio EIP-712.
     * @dev Cunha o fornecimento total para o chamador e define o DOMAIN_SEPARATOR conforme EIP-712.
     *      Reverte se o fornecimento inicial for zero.
     * @param _totalSupply Fornecimento total inicial de tokens.
     */
    constructor(uint256 _totalSupply) {
        require(_totalSupply > 0, "DeflatingERC20: INVALID_INITIAL_SUPPLY");

        // Configura o DOMAIN_SEPARATOR para EIP-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        _mint(msg.sender, _totalSupply);
    }

    // ================================
    //           Funções Internas
    // ================================

    /**
     * @notice Cunha novos tokens para um endereço.
     * @dev Aumenta o totalSupply e o saldo do destinatário. Emite evento Transfer.
     *      Reverte se o destinatário for address(0).
     * @param to Endereço que receberá os tokens.
     * @param value Quantidade de tokens a cunhar.
     */
    function _mint(address to, uint256 value) internal {
        require(to != address(0), "DeflatingERC20: MINT_TO_ZERO_ADDRESS");

        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Queima tokens de um endereço.
     * @dev Reduz o totalSupply e o saldo do endereço. Emite evento Transfer.
     *      Reverte se o endereço for address(0) ou o saldo for insuficiente.
     * @param from Endereço de onde os tokens serão queimados.
     * @param value Quantidade de tokens a queimar.
     */
    function _burn(address from, uint256 value) internal {
        require(from != address(0), "DeflatingERC20: BURN_FROM_ZERO_ADDRESS");
        require(balanceOf[from] >= value, "DeflatingERC20: INSUFFICIENT_BALANCE");

        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Aprova um gastador para usar tokens de um proprietário.
     * @dev Define a allowance e emite evento Approval.
     *      Reverte se o proprietário ou gastador for address(0).
     * @param owner Endereço do proprietário dos tokens.
     * @param spender Endereço autorizado a gastar.
     * @param value Quantidade aprovada.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "DeflatingERC20: APPROVE_FROM_ZERO_ADDRESS");
        require(spender != address(0), "DeflatingERC20: APPROVE_TO_ZERO_ADDRESS");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @notice Transfere tokens com mecanismo deflacionário (queima 1%).
     * @dev Queima 1% do valor e transfere o restante. Emite evento Transfer.
     *      Reverte se os endereços forem inválidos ou o saldo for insuficiente.
     * @param from Endereço de origem.
     * @param to Endereço de destino.
     * @param value Quantidade total (antes da queima).
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "DeflatingERC20: TRANSFER_FROM_ZERO_ADDRESS");
        require(to != address(0), "DeflatingERC20: TRANSFER_TO_ZERO_ADDRESS");
        require(value > 0, "DeflatingERC20: INVALID_TRANSFER_AMOUNT");
        require(balanceOf[from] >= value, "DeflatingERC20: INSUFFICIENT_BALANCE");

        uint256 burnAmount = value.div(BURN_RATE);
        uint256 transferAmount = value.sub(burnAmount);

        _burn(from, burnAmount);
        balanceOf[from] = balanceOf[from].sub(transferAmount);
        balanceOf[to] = balanceOf[to].add(transferAmount);

        emit Transfer(from, to, transferAmount);
    }

    // ================================
    //           Funções Externas
    // ================================

    /**
     * @notice Aprova um gastador para usar tokens do chamador.
     * @dev Chama _approve internamente. Conforme o padrão ERC-20.
     * @param spender Endereço autorizado a gastar.
     * @param value Quantidade aprovada.
     * @return success Sempre retorna true se a aprovação for bem-sucedida.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice Transfere tokens do chamador para um destinatário com queima de 1%.
     * @dev Chama _transfer internamente. Conforme o padrão ERC-20.
     * @param to Endereço de destino.
     * @param value Quantidade total (antes da queima).
     * @return success Sempre retorna true se a transferência for bem-sucedida.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Transfere tokens de um endereço autorizado com queima de 1%.
     * @dev Reduz a allowance (se não for máxima) e chama _transfer. Conforme o padrão ERC-20.
     * @param from Endereço de origem.
     * @param to Endereço de destino.
     * @param value Quantidade total (antes da queima).
     * @return success Sempre retorna true se a transferência for bem-sucedida.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice Aprova um gastador via assinatura off-chain (EIP-2612).
     * @dev Verifica a assinatura e o deadline, incrementa nonce e chama _approve.
     *      Reverte se o deadline expirar, a assinatura for inválida ou o proprietário for address(0).
     * @param owner Endereço do proprietário dos tokens.
     * @param spender Endereço autorizado a gastar.
     * @param value Quantidade aprovada.
     * @param deadline Timestamp limite para a assinatura.
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
        require(deadline >= block.timestamp, "DeflatingERC20: EXPIRED_DEADLINE");
        require(owner != address(0), "DeflatingERC20: INVALID_OWNER");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner, "DeflatingERC20: INVALID_SIGNATURE");

        _approve(owner, spender, value);
    }
}