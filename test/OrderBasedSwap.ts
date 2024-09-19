import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("OrderBasedSwap", function () {
    async function deployFixture() {
        // get token address one
        // get token address two

        const [owner, addr1, addr2] = await ethers.getSigners();

        const tokenOneContract = await ethers.getContractFactory("Mock20Token");
        const tokenTwoContract = await ethers.getContractFactory("LW3Token");
        const orderBasedSwapContract = await ethers.getContractFactory("OrderBasedSwap");

        const tokenOne = await tokenOneContract.deploy("Mock20Token", "MTK");
        const tokenTwo = await tokenTwoContract.deploy("LW3Token", "LW3");
        const orderBasedSwap = await orderBasedSwapContract.deploy();

        return { owner, addr1, addr2, tokenOne, tokenTwo, orderBasedSwap };
    }

    describe("Deployment", function () {
        it("Should set the correct owner", async function () {
            const {owner, orderBasedSwap} = await loadFixture(deployFixture);
            expect(await orderBasedSwap.owner()).to.equal(owner.address);
        });
    });

    describe("Creating an order", function () {
        it('Should create an order', async function () {
            const {orderBasedSwap, tokenOne, tokenTwo, addr1} = await loadFixture(deployFixture);

            // approve the order based swap contract to spend the token one
            await tokenOne.approve(orderBasedSwap.target, ethers.parseUnits("1", 18));
            // create order
            const order = await orderBasedSwap.createOrder(tokenOne.target, tokenTwo.target, ethers.parseUnits("1", 18), ethers.parseUnits("1", 18));

            // check if the order is created
            const orderId = await orderBasedSwap.orderCount();
            expect(orderId).to.equal(1);    
        });

        it('Should revert if the contract does not have enough allowance', async function () {
            const {orderBasedSwap, tokenOne, tokenTwo, addr1} = await loadFixture(deployFixture);

            // check if the order is created
           await expect( orderBasedSwap.createOrder(tokenOne.target, tokenTwo.target, ethers.parseUnits("1", 18), ethers.parseUnits("1", 18))).to.be.rejectedWith("Insufficient allowance");
        });

        it('Should revert if same tokens are passed', async function () {
            const {orderBasedSwap, tokenOne, addr1} = await loadFixture(deployFixture);

            // check if the order is created
           await expect( orderBasedSwap.createOrder(tokenOne.target, tokenOne.target, ethers.parseUnits("1", 18), ethers.parseUnits("1", 18))).to.be.rejectedWith("Sell and buy tokens must be different");
        });

        it('Should revert if amount is zero', async function () {
            const {orderBasedSwap, tokenOne, tokenTwo, addr1} = await loadFixture(deployFixture);

            // check if the order is created
           await expect( orderBasedSwap.createOrder(tokenOne.target, tokenTwo.target, 0, 0)).to.be.rejectedWith("Amounts must be greater than zero");
        });
    });

    describe("Filling an order", function () {
        it("Should fill an order", async function () {
            const {orderBasedSwap, tokenOne, tokenTwo, addr1, addr2} = await loadFixture(deployFixture);

            await tokenOne.approve(orderBasedSwap.target, ethers.parseUnits("1", 18));
            
            // approve the order based swap contract to spend the token one
            await tokenTwo.approve(orderBasedSwap.target, ethers.parseUnits("1", 18));

            // create order
            await orderBasedSwap.createOrder(tokenOne.target, tokenTwo.target, ethers.parseUnits("1", 18), ethers.parseUnits("1", 18));

            // fill order
            await orderBasedSwap.fulfillOrder(0);

            const order = await orderBasedSwap.orders(0);

            // check if the order is filled
            expect(order.isFulfilled).to.be.true;
        });
    });
});