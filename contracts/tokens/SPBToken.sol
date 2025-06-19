// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/**
 * @title SPBToken
 * @notice Token ERC-20 com funcionalidades de queima, pausabilidade, taxas e propriedade.
 * @dev Implementa o padrão ERC-20 com extensões para:
 *      - Queima de tokens (ERC20Burnable).
 *      - Pausabilidade de transferências (Pausable).
 *      - Controle de propriedade (Ownable).
 *      - Taxa configurável (1% por padrão, até 10%) aplicada em transferências, enviada a um endereço receptor.
 *      Segue as melhores práticas de desenvolvimento em Solidity, incluindo:
 *      - Documentação NatSpec detalhada para todas as funções, estados e eventos.
 *      - Verificações explícitas de segurança (ex.: endereços válidos, limites de taxa, pausabilidade).
 *      - Uso de bibliotecas OpenZeppelin para funcionalidades padrão e seguras.
 *      - Organização modular com seções claras.
 *      Compatível com Solidity 0.8.28, aproveitando verificações nativas de overflow/underflow.
 */
contract SPBToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    // ================================
    //           Constantes
    // ================================

    /// @notice Percentual máximo permitido para a taxa de transferência.
    uint256 public constant MAX_TAX_PERCENT = 10;

    /// @notice Fornecimento inicial de tokens (1.000.000 tokens).
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    // ================================
    //           Estados
    // ================================

    /// @notice Percentual da taxa aplicada em transferências (em pontos percentuais).
    uint256 public taxPercent;

    /// @notice Endereço que recebe as taxas coletadas.
    address public taxReceiver;

    // ================================
    //           Eventos
    // ================================

    /// @notice Emite quando o endereço receptor de taxas é atualizado.
    /// @param oldReceiver Endereço receptor anterior.
    /// @param newReceiver Novo endereço receptor.
    event TaxReceiverUpdated(address indexed oldReceiver, address indexed newReceiver);

    /// @notice Emite quando o percentual da taxa é atualizado.
    /// @param oldTaxPercent Percentual anterior.
    /// @param newTaxPercent Novo percentual.
    event TaxPercentUpdated(uint256 oldTaxPercent, uint256 newTaxPercent);

    // ================================
    //           Construtor
    // ================================

    /**
     * @notice Inicializa o contrato com fornecimento inicial, configura o receptor de taxas e define a taxa padrão.
     * @dev Cunha 1.000.000 tokens para o proprietário e define taxReceiver como o chamador.
     *      A taxa inicial é definida como 1%.
     */
    constructor() ERC20("SOCIETY PROJECT BANK", "SPB") Ownable(msg.sender) {
        taxPercent = 1;
        taxReceiver = msg.sender;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // ================================
    //           Funções de Configuração
    // ================================

    /**
     * @notice Define um novo endereço para receber as taxas de transferência.
     * @dev Apenas o proprietário pode chamar. Reverte se o novo receptor for address(0).
     *      Emite evento TaxReceiverUpdated.
     * @param _receiver Novo endereço receptor de taxas.
     */
    function setTaxReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), "SPBToken: INVALID_TAX_RECEIVER");
        address oldReceiver = taxReceiver;
        taxReceiver = _receiver;
        emit TaxReceiverUpdated(oldReceiver, _receiver);
    }

    /**
     * @notice Define um novo percentual para a taxa de transferência.
     * @dev Apenas o proprietário pode chamar. Reverte se a taxa exceder MAX_TAX_PERCENT.
     *      Emite evento TaxPercentUpdated.
     * @param _taxPercent Novo percentual da taxa (em pontos percentuais).
     */
    function setTaxPercent(uint256 _taxPercent) external onlyOwner {
        require(_taxPercent <= MAX_TAX_PERCENT, "SPBToken: TAX_PERCENT_TOO_HIGH");
        uint256 oldTaxPercent = taxPercent;
        taxPercent = _taxPercent;
        emit TaxPercentUpdated(oldTaxPercent, _taxPercent);
    }

    /**
     * @notice Pausa todas as transferências do token.
     * @dev Apenas o proprietário pode chamar. Reverte se já pausado.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Retoma as transferências do token.
     * @dev Apenas o proprietário pode chamar. Reverte se não pausado.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ================================
    //           Funções Internas
    // ================================

    /**
     * @notice Executa uma transferência com aplicação de taxa.
     * @dev Sobrescreve _transfer do ERC20 para aplicar a taxa configurada e enviar ao taxReceiver.
     *      Reverte se pausado, endereços forem inválidos, saldo insuficiente ou taxa inválida.
     * @param sender Endereço do remetente.
     * @param recipient Endereço do destinatário.
     * @param amount Quantidade total a transferir (antes da taxa).
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override whenNotPaused {
        require(sender != address(0), "SPBToken: TRANSFER_FROM_ZERO_ADDRESS");
        require(recipient != address(0), "SPBToken: TRANSFER_TO_ZERO_ADDRESS");
        require(amount > 0, "SPBToken: INVALID_TRANSFER_AMOUNT");
        require(taxReceiver != address(0), "SPBToken: TAX_RECEIVER_NOT_SET");

        uint256 tax = (amount * taxPercent) / 100;
        uint256 afterTax = amount - tax;

        super._transfer(sender, taxReceiver, tax);
        super._transfer(sender, recipient, afterTax);
    }

    /**
     * @notice Atualiza o estado antes de qualquer transferência.
     * @dev Sobrescreve _update do ERC20 e ERC20Pausable para garantir correta execução em múltipla herança.
     * @param from Endereço de origem.
     * @param to Endereço de destino.
     * @param value Quantidade transferida.
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}