/**
 * ===========================================================================
 * Enterprise-level Master Test Suite for SPBToken and BPSToken
 * ===========================================================================
 * This suite validates all critical behaviors for both SPB and BPS tokens,
 * ensuring feature parity, security, and robustness for present and future upgrades.
 *
 * Key Areas Covered:
 *  - Deployment: parameter correctness, ownership
 *  - Tax logic: user-to-user, owner involvement, event emission
 *  - Administrative: minting, tax receiver update, onlyOwner guards
 *  - Pausing: pause/unpause, permission checks
 *  - Burn: self-burn and approved burnFrom
 *  - ERC20 allowances: transferFrom, tax, allowance reduction
 *  - Edge cases: zero values, zero address, overdraw
 *  - Gas: transfer cost profile
 *  - Integration: ensure both tokens behave identically in flows
 *
 * All tests are DRY by design, using a runner to execute the same validations for both tokens.
 * ===========================================================================
 */

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther, ZeroAddress } = require("ethers");

describe("SPB and BPS Tokens - Enterprise Test Suite", function () {
  let spbToken, bpsToken;
  let owner, taxReceiver, user1, user2;
  const initialSupply = parseEther("1000000"); // 1 milhão de tokens

  // -------------------------------------------------------------------------
  // Test Setup: Deploy both tokens with clean state before each test scenario
  // -------------------------------------------------------------------------
  beforeEach(async function () {
    [owner, taxReceiver, user1, user2] = await ethers.getSigners();

    // Deploy SPB Token (referência)
    const SPBToken = await ethers.getContractFactory("SPBToken");
    spbToken = await SPBToken.deploy(
      "SOCIETY PROJECT BANK",
      "SPB",
      1000000,
      taxReceiver.address
    );
    await spbToken.waitForDeployment();

    // Deploy BPS Token (deve ser funcionalmente idêntico)
    const BPSToken = await ethers.getContractFactory("BPSToken");
    bpsToken = await BPSToken.deploy(
      "BANK PROJECT SOCIETY",
      "BPS",
      1000000,
      taxReceiver.address
    );
    await bpsToken.waitForDeployment();
  });

  /**
   * -------------------------------------------------------------------------
   * DRY Test Runner: Executes full suite for any token contract instance
   * -------------------------------------------------------------------------
   * @param {() => Contract} tokenGetter - Function returning current token instance
   * @param {string} tokenName - Token label ("SPB" or "BPS")
   */
  function runTokenTests(tokenGetter, tokenName) {
    // -----------------------------------------------------------------------
    // Deployment and Ownership
    // -----------------------------------------------------------------------
    describe(`${tokenName} - Deployment`, function () {
      it("Should deploy with correct parameters // Deve implantar com os parâmetros corretos", async function () {
        // Testa nome, símbolo, decimais, supply total, saldo inicial e taxReceiver
        const token = tokenGetter();
        if (tokenName === "SPB") {
          expect(await token.name()).to.equal("SOCIETY PROJECT BANK");
          expect(await token.symbol()).to.equal("SPB");
        } else {
          expect(await token.name()).to.equal("BANK PROJECT SOCIETY");
          expect(await token.symbol()).to.equal("BPS");
        }
        expect(await token.decimals()).to.equal(18);
        expect(await token.totalSupply()).to.equal(initialSupply);
        expect(await token.balanceOf(owner.address)).to.equal(initialSupply);
        expect(await token.taxReceiver()).to.equal(taxReceiver.address);
      });

      it("Should set correct owner // Deve definir o owner corretamente", async function () {
        // Garante que o owner do contrato está correto após o deploy
        const token = tokenGetter();
        expect(await token.owner()).to.equal(owner.address);
      });
    });

    // -----------------------------------------------------------------------
    // Tax Calculation and Logic
    // -----------------------------------------------------------------------
    describe(`${tokenName} - Tax Logic`, function () {
      const transferAmount = parseEther("1000");
      const expectedTax = parseEther("10"); // 1% de 1000
      const expectedNet = parseEther("990"); // 1000 - 10

      it("Should calculate tax and net amount correctly // Deve calcular a taxa e o valor líquido corretamente", async function () {
        // Testa os métodos de cálculo de taxa e valor líquido
        const token = tokenGetter();
        expect(await token.calculateTax(transferAmount)).to.equal(expectedTax);
        expect(await token.calculateNetAmount(transferAmount)).to.equal(expectedNet);
      });

      it("Should NOT apply tax on transfer from owner // Não aplica taxa para transferências do owner", async function () {
        // Owner transfere -> user1 e não paga taxa
        const token = tokenGetter();
        await token.transfer(user1.address, transferAmount);
        expect(await token.balanceOf(user1.address)).to.equal(transferAmount);
        expect(await token.balanceOf(taxReceiver.address)).to.equal(0);
      });

      it("Should apply tax on user-to-user transfers // Aplica taxa entre usuários comuns", async function () {
        // user1 transfere para user2 e paga taxa
        const token = tokenGetter();
        await token.transfer(user1.address, transferAmount);
        await token.connect(user1).transfer(user2.address, transferAmount);
        expect(await token.balanceOf(user2.address)).to.equal(expectedNet);
        expect(await token.balanceOf(taxReceiver.address)).to.equal(expectedTax);
      });

      it("Should NOT apply tax when owner is sender or recipient // Não aplica taxa se o owner é remetente ou destinatário", async function () {
        // Se owner é destinatário, não há desconto de taxa
        const token = tokenGetter();
        await token.transfer(user1.address, transferAmount);
        await token.connect(user1).transfer(owner.address, transferAmount);
        expect(await token.balanceOf(owner.address)).to.equal(initialSupply);
      });

      it("Should emit TaxCollected event only when tax is applied // Evento TaxCollected emitido apenas quando há taxa", async function () {
        // Evento só é emitido quando transferência entre usuários comuns
        const token = tokenGetter();
        await expect(token.transfer(user1.address, transferAmount))
          .to.not.emit(token, "TaxCollected");
        await expect(
          token.connect(user1).transfer(user2.address, transferAmount)
        ).to.emit(token, "TaxCollected");
        await token.transfer(user1.address, transferAmount);
        await expect(
          token.connect(user1).transfer(user2.address, transferAmount)
        ).to.emit(token, "TaxCollected");
      });
    });

    // -----------------------------------------------------------------------
    // ERC20 transferFrom and Allowance/Tax Integration
    // -----------------------------------------------------------------------
    describe(`${tokenName} - ERC20 transferFrom`, function () {
      it("Should allow transferFrom with tax (user->user) // Deve permitir Transferencia com taxa", async function () {
        // user2 usa allowance de user1, taxa é aplicada, allowance é zerado
        const token = tokenGetter();
        const amount = parseEther("1000");
        await token.transfer(user1.address, amount);
        await token.connect(user1).approve(user2.address, amount);
        const expectedTax = await token.calculateTax(amount);
        const expectedNet = await token.calculateNetAmount(amount);

        await expect(
          token.connect(user2).transferFrom(user1.address, user2.address, amount)
        ).to.emit(token, "TaxCollected");

        expect(await token.balanceOf(user2.address)).to.equal(expectedNet);
        expect(await token.balanceOf(taxReceiver.address)).to.equal(expectedTax);
        expect(await token.allowance(user1.address, user2.address)).to.equal(0);
      });

      it("Should not collect tax in transferFrom if owner involved // Não deve cobrar taxa pra o owner", async function () {
        // Taxa não é aplicada se owner é remetente ou destinatário
        const token = tokenGetter();
        const amount = parseEther("1000");
        await token.transfer(user1.address, amount);
        await token.connect(user1).approve(owner.address, amount);

        // owner como to
        await expect(token.connect(owner).transferFrom(user1.address, owner.address, amount))
          .to.not.emit(token, "TaxCollected");
        expect(await token.balanceOf(owner.address)).to.be.above(0);

        // owner como from
        await token.approve(user2.address, amount);
        await expect(token.connect(user2).transferFrom(owner.address, user2.address, amount))
          .to.not.emit(token, "TaxCollected");
      });

      it("Should revert if allowance is insufficient in transferFrom // Deve reverter se allowance for insuficiente", async function () {
        // Deve falhar se allowance for insuficiente
        const token = tokenGetter();
        const amount = parseEther("1000");
        await token.transfer(user1.address, amount);
        await token.connect(user1).approve(user2.address, amount - 1n);
        await expect(
          token.connect(user2).transferFrom(user1.address, user2.address, amount)
        ).to.be.revertedWith("ERC20: insufficient allowance");
      });

      /*
      // Nota: Não é possível atingir "from == address(0)" via transferFrom por padrão ERC20.
      it("Should revert if from is zero address in transferFrom", async function () {
        const token = tokenGetter();
        await expect(
          token.transferFrom(ZeroAddress, user2.address, 100)
        ).to.be.revertedWith("ERC20: transfer from the zero address");
      });
      // Não testável por padrão ERC20 (sempre allowance insuficiente antes)
      */
      
      it("Should revert if to is zero address in transferFrom // Deve reverter se o Address for zero (0) ", async function () {
        // Deve falhar se destinatário for zero address
        const token = tokenGetter();
        await token.approve(user2.address, 100);
        await expect(
          token.connect(user2).transferFrom(owner.address, ZeroAddress, 100)
        ).to.be.revertedWith("ERC20: transfer to the zero address");
      });

      it("Should revert if transferFrom called when paused // Deve reverter se o contrato estiver pausado", async function () {
        // Deve falhar se contrato estiver pausado
        const token = tokenGetter();
        await token.pause();
        await expect(
          token.transferFrom(owner.address, user1.address, 100)
        ).to.be.revertedWith("Pausable: paused");
      });
    });

    describe(`${tokenName} - Allowance/Tax Integration`, function () {
      it("Should handle allowances and tax correctly // Permite allowance e taxa juntos corretamente", async function () {
        // Testa allowance, transferência e aplicação de taxa
        const token = tokenGetter();
        const allowanceAmount = parseEther("1000");
        const transferAmount = parseEther("500");
        await token.approve(user1.address, allowanceAmount);
        await token.transfer(user1.address, parseEther("1000"));
        await token.connect(user1).approve(user2.address, transferAmount);
        await token.connect(user1).transfer(user2.address, transferAmount);
        const expectedNet = await token.calculateNetAmount(transferAmount);
        const expectedTax = await token.calculateTax(transferAmount);
        expect(await token.balanceOf(user2.address)).to.equal(expectedNet);
        expect(await token.balanceOf(taxReceiver.address)).to.equal(expectedTax);
      });
    });

    // -----------------------------------------------------------------------
    // Administrative: Mint, Tax Receiver, OnlyOwner
    // -----------------------------------------------------------------------
    describe(`${tokenName} - Administrative/Ownership`, function () {
      it("Should allow only owner to mint new tokens // Apenas o owner pode mintar novos tokens", async function () {
        // Só owner consegue mintar, qualquer outro é revertido
        const token = tokenGetter();
        const mintAmount = parseEther("10000");
        await token.mint(user1.address, mintAmount);
        expect(await token.balanceOf(user1.address)).to.equal(mintAmount);
        expect(await token.totalSupply()).to.equal(initialSupply + mintAmount);

        await expect(
          token.connect(user1).mint(user1.address, mintAmount)
        ).to.be.revertedWith("Ownable: caller is not the owner");
      });

      it("Should allow owner to update tax receiver and emit event // Owner pode atualizar o taxReceiver e emitir evento", async function () {
        // Owner pode trocar o taxReceiver e evento é emitido corretamente
        const token = tokenGetter();
        await expect(token.setTaxReceiver(user1.address))
          .to.emit(token, "TaxReceiverUpdated")
          .withArgs(taxReceiver.address, user1.address);
        expect(await token.taxReceiver()).to.equal(user1.address);
      });

      it("Should NOT allow setting zero address as tax receiver // Não pode definir endereço zero como taxReceiver", async function () {
        // Não permite definir taxReceiver como zero address
        const token = tokenGetter();
        await expect(
          token.setTaxReceiver(ZeroAddress)
        ).to.be.revertedWith("Tax receiver cannot be zero address");
      });
    });

    // -----------------------------------------------------------------------
    // Pausable Controls
    // -----------------------------------------------------------------------
    describe(`${tokenName} - Pausable Controls`, function () {
      it("Should allow only owner to pause/unpause token // Apenas o owner pode pausar/despausar o token", async function () {
        // Owner pode pausar/despausar. Qualquer outro é revertido. Transferências são bloqueadas quando pausado.
        const token = tokenGetter();
        await token.pause();
        expect(await token.paused()).to.be.true;
        await expect(
          token.transfer(user1.address, parseEther("100"))
        ).to.be.revertedWith("Pausable: paused");
        await token.unpause();
        expect(await token.paused()).to.be.false;
        await expect(
          token.transfer(user1.address, parseEther("100"))
        ).to.not.be.reverted;
        await expect(
          token.connect(user1).pause()
        ).to.be.revertedWith("Ownable: caller is not the owner");
      });
    });

    // -----------------------------------------------------------------------
    // Burnable Extensions
    // -----------------------------------------------------------------------
    describe(`${tokenName} - Burnable Extensions`, function () {
      it("Should allow self-burn and approved burnFrom // Permite burn e burnFrom", async function () {
        // Owner pode burnar seus tokens, e burnFrom funciona para allowance de terceiros
        const token = tokenGetter();
        const burnAmount = parseEther("1000");

        // Owner queima seus próprios tokens
        await token.burn(burnAmount);
        expect(await token.balanceOf(owner.address)).to.equal(initialSupply - burnAmount);
        expect(await token.totalSupply()).to.equal(initialSupply - burnAmount);

        // user1 recebe tokens, aprova user2, user2 queima via burnFrom
        await token.transfer(user1.address, parseEther("2000"));
        await token.connect(user1).approve(user2.address, burnAmount);
        await token.connect(user2).burnFrom(user1.address, burnAmount);
        expect(await token.balanceOf(user1.address)).to.equal(parseEther("1000"));
      });
    });

    // -----------------------------------------------------------------------
    // Edge and Security Cases
    // -----------------------------------------------------------------------
    describe(`${tokenName} - Edge and Security Cases`, function () {
      it("Should allow zero-value transfers and reject invalid operations // Permite transfer zero, rejeita operações inválidas", async function () {
        // Transferência de valor zero é permitida. Outras operações inválidas são revertidas.
        const token = tokenGetter();
        await expect(token.transfer(user1.address, 0)).to.not.be.reverted;
        expect(await token.balanceOf(user1.address)).to.equal(0);
        await expect(
          token.transfer(ZeroAddress, parseEther("100"))
        ).to.be.revertedWith("ERC20: transfer to the zero address");
        await expect(
          token.connect(user1).transfer(user2.address, parseEther("100"))
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
      });
    });

    // -----------------------------------------------------------------------
    // Gas Usage Profile
    // -----------------------------------------------------------------------
    describe(`${tokenName} - Gas Profile`, function () {
      it("Should consume reasonable gas for transfers // Consumo de gas aceitável", async function () {
        // Mede consumo de gas de uma transferência comum, esperando valor razoável
        const token = tokenGetter();
        const tx = await token.transfer(user1.address, parseEther("1000"));
        const receipt = await tx.wait();
        console.log(`[${tokenName}] Transfer with tax gas used: ${receipt.gasUsed.toString()}`);
        expect(receipt.gasUsed).to.be.below(100000); // Limite arbitrário
      });
    });
  }

  // -------------------------------------------------------------------------
  // Execute all tests for both tokens (SPB and BPS) - Ensures total parity
  // -------------------------------------------------------------------------
  runTokenTests(() => spbToken, "SPB");
  runTokenTests(() => bpsToken, "BPS");

  // -------------------------------------------------------------------------
  // Integration Testing: Both tokens must behave identically in all flows
  // -------------------------------------------------------------------------
  describe("Integration Tests (Cross-Token Parity)", function () {
    it("Should behave identically in parallel flows // Ambos tokens devem se comportar de forma idêntica em fluxos paralelos", async function () {
      // Executa fluxo idêntico em ambos tokens e compara saldos finais
      const transferAmount = parseEther("1000");
      // SPB token
      await spbToken.transfer(user1.address, transferAmount);
      await spbToken.connect(user1).transfer(user2.address, transferAmount);
      const spbBalance = await spbToken.balanceOf(user2.address);
      const spbTaxBalance = await spbToken.balanceOf(taxReceiver.address);

      // BPS token
      await bpsToken.transfer(user1.address, transferAmount);
      await bpsToken.connect(user1).transfer(user2.address, transferAmount);
      const bpsBalance = await bpsToken.balanceOf(user2.address);
      const bpsTaxBalance = await bpsToken.balanceOf(taxReceiver.address);

      // Valida igualdade de comportamento e valores finais
      expect(spbBalance).to.equal(bpsBalance);
      expect(spbTaxBalance).to.equal(bpsTaxBalance);

      const expectedNet = await spbToken.calculateNetAmount(transferAmount);
      const expectedTax = await spbToken.calculateTax(transferAmount);
      expect(spbBalance).to.equal(expectedNet);
      expect(spbTaxBalance).to.equal(expectedTax);
    });
  });
});

/**
 * ===========================================================================
 * STRUCTURE AND EXECUTION NOTES
 * ===========================================================================
 * - Uses a DRY utility (`runTokenTests`) to execute all behavioral and security tests for both tokens.
 * - Each describe/it block is labeled for clarity and traceability in CI outputs.
 * - Uses explicit assertions for all behaviors, including event emission, revert reasons, and value checks.
 * - Integration tests guarantee that both tokens stay functionally in sync.
 *
 * RECOMMENDATION:
 * - When extending token features, always add corresponding test coverage inside `runTokenTests`.
 * - For security reviews, focus on edge/security and administrative/ownership test blocks.
 * ===========================================================================
 */
