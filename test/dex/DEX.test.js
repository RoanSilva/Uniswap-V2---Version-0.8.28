// test/dex.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DEX Functionality", function () {
    let factory, router, weth;
    let spbToken, bpsToken;
    let owner, user1, user2;
    
    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        
        // Deploy tokens
        const SPBToken = await ethers.getContractFactory("SPBToken");
        const BPSToken = await ethers.getContractFactory("BPSToken");
        
        spbToken = await SPBToken.deploy();
        bpsToken = await BPSToken.deploy();
        
        // Deploy DEX
        const WETH9 = await ethers.getContractFactory("WETH9");
        weth = await WETH9.deploy();
        
        const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
        factory = await UniswapV2Factory.deploy(owner.address);
        
        const UniswapV2Router02 = await ethers.getContractFactory("UniswapV2Router02");
        router = await UniswapV2Router02.deploy(factory.address, weth.address);
    });
    
    it("Should create pair successfully", async function () {
        await factory.createPair(spbToken.address, bpsToken.address);
        const pairAddress = await factory.getPair(spbToken.address, bpsToken.address);
        expect(pairAddress).to.not.equal(ethers.constants.AddressZero);
    });
    
    it("Should add liquidity successfully", async function () {
        // Criar par
        await factory.createPair(spbToken.address, bpsToken.address);
        
        // Preparar liquidez
        const spbAmount = ethers.utils.parseEther("1000");
        const bpsAmount = ethers.utils.parseEther("100");
        
        await spbToken.approve(router.address, spbAmount);
        await bpsToken.approve(router.address, bpsAmount);
        
        // Adicionar liquidez
        const deadline = Math.floor(Date.now() / 1000) + 60 * 20;
        await router.addLiquidity(
            spbToken.address,
            bpsToken.address,
            spbAmount,
            bpsAmount,
            0,
            0,
            owner.address,
            deadline
        );
        
        // Verificar reservas
        const pairAddress = await factory.getPair(spbToken.address, bpsToken.address);
        const pair = await ethers.getContractAt("UniswapV2Pair", pairAddress);
        const reserves = await pair.getReserves();
        
        expect(reserves._reserve0).to.be.gt(0);
        expect(reserves._reserve1).to.be.gt(0);
    });
    
    it("Should perform swap successfully", async function () {
        // Setup (criar par e adicionar liquidez)
        await factory.createPair(spbToken.address, bpsToken.address);
        
        const spbAmount = ethers.utils.parseEther("10000");
        const bpsAmount = ethers.utils.parseEther("1000");
        
        await spbToken.approve(router.address, spbAmount);
        await bpsToken.approve(router.address, bpsAmount);
        
        const deadline = Math.floor(Date.now() / 1000) + 60 * 20;
        await router.addLiquidity(
            spbToken.address,
            bpsToken.address,
            spbAmount,
            bpsAmount,
            0,
            0,
            owner.address,
            deadline
        );
        
        // Realizar swap
        const swapAmount = ethers.utils.parseEther("100");
        await spbToken.transfer(user1.address, swapAmount.mul(2));
        
        await spbToken.connect(user1).approve(router.address, swapAmount);
        
        const balanceBefore = await bpsToken.balanceOf(user1.address);
        
        await router.connect(user1).swapExactTokensForTokens(
            swapAmount,
            0,
            [spbToken.address, bpsToken.address],
            user1.address,
            deadline
        );
        
        const balanceAfter = await bpsToken.balanceOf(user1.address);
        expect(balanceAfter).to.be.gt(balanceBefore);
    });
});
