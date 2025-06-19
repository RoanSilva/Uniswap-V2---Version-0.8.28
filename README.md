Uniswap V2 Atualizado — Solidity 0.8.28
========================================

Este repositório contém a versão atualizada dos contratos do protocolo Uniswap V2, compatível com a versão Solidity 0.8.28, com melhorias de segurança, otimizações e ajustes modernos de sintaxe.

Sobre
-----

O Uniswap é um protocolo descentralizado para criação de liquidez automatizada (AMM - Automated Market Maker) na rede Ethereum. Esta versão foi baseada no repositório original da Uniswap V2 e adaptada para uso com o compilador Solidity ^0.8.0, especificamente 0.8.28.

Mudanças principais
-------------------

- Compatibilidade com Solidity ^0.8.0, testado em 0.8.28
- Atualização de visibilidades e eventos
- Organização e limpeza geral do código
- Preparação para testes modernos com Hardhat e Ethers.js

Como usar
---------

1. Clone os repositórios:

   git clone https://github.com/Uniswap/v2-core.git
   git clone https://github.com/Uniswap/v2-periphery.git
   
   cd v2-core
   cd v2-periphery

3. Atualize pelos novos contratos compativeis com a versão Solidity 0.8.28
   
   git clone https://github.com/RoanSilva/Uniswap-V2---Version-0.8.28.git
   
   cd v2-solidity 0.8.28

5. Instale as dependências:

   npm install

6. Compile os contratos:

   npx hardhat compile

7. Execute os testes:

   npx hardhat test

8. Rode um nó local:

   npx hardhat node

Tecnologias utilizadas
----------------------

- Solidity 0.8.28
- Hardhat
- Ethers.js
- Chai + Mocha (testes unitários)

Segurança
---------

Este repositório é fornecido apenas para fins educacionais e testes locais/testnet. NÃO utilize em produção sem auditoria de segurança.

Créditos
--------

Baseado no código original da equipe da Uniswap Labs.

Links úteis
-----------

- Documentação Uniswap V2: https://docs.uniswap.org/protocol/V2/
- Documentação Solidity: https://docs.soliditylang.org/
- Documentação Hardhat: https://hardhat.org/docs
