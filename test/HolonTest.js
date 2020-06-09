 
const Holon = artifacts.require("./Holon.sol")
const HolonFactory = artifacts.require("./HolonFactory.sol")
const TestToken = artifacts.require("./TestToken.sol")

contract("Holon", async accounts => {

    const owner = accounts[0]
    const firstMember = accounts[1]
    const secondMember = accounts[2]

    const initHolon = async (from) => {
        const factory = await HolonFactory.deployed()
        const holon = await factory.newHolon("First", {from:from});
        return holon;
    }

    before(async function () {
        try {
            await web3.eth.personal.unlockAccount(owner, "", 1000)
            await web3.eth.personal.unlockAccount(firstMember, "", 1000)
            await web3.eth.personal.unlockAccount(secondMember, "", 1000)
        } catch(error) {
            console.warn(`error in unlocking wallet: ${JSON.stringify(error)}`)
        }
    })

    describe("Holon Creation test", _ => {
     
        let factory;
        let holonaddress;
        let holon;
        let secondholonaddress;
        let secondholon;

        it("Creates a new Holon ", async () => {
            factory = await HolonFactory.deployed();
            //create first holon
            await factory.newHolon("First", { from: owner });
            holonaddress = await factory.newHolon.call("First");
            
            //create second holon
            await factory.newHolon("Otherholon", { from: firstMember });
            let holonaddress2 = await factory.newHolon.call("Otherholon");
            
            //check if both succeeded
            const size = await factory.nholons();
            assert.equal(size.toString(), "2", "nholons not equal to 2");
            
            //check if holons can be fetched by owners
            let address = await factory.listHolonsOf(owner);
            assert.equal(address.toString(),holonaddress.toString(),"address mismatch");
            
            let address2 = await factory.listHolonsOf(firstMember);
            assert.equal(address2.toString(),holonaddress2.toString(),"address 2 mismatch");
   
        })

        it("Fails creating a new Holon with the same name ", async () => {
            await factory.newHolon("First", { from: owner });
            const newholonaddress = await factory.newHolon.call("First", { from: owner })
            const size = await factory.nholons();
            assert.equal(size.toString(), "2", "nholons not equal to 2")
            //assert.equal(holonaddress, haddress2, "Holon size is not 0")
        })

        it("Access the first holon", async () => {
            holon = await Holon.at(holonaddress);
            const holonsize = await holon.getHolonSize();
            assert.equal(holonsize.toString(), "0", "Holon size not equal to 0");
        })

        it("Tries creating the first member from a non-lead account", async () => {
            try {
                await holon.addMember ( firstMember, "Roberto",{ from: firstMember });
            } catch (_) {}

            const holonsize = await holon.getHolonSize();
            assert.equal(holonsize.toString(), "0", "Holon size not equal to 0");
            
        })

        it("Creates the first member", async () => {
            await holon.addMember ( firstMember, "Roberto",{ from: owner });
            const holonsize = await holon.getHolonSize();
            assert.equal(holonsize.toString(), "1", "Holon size not equal to 1");
        })

        it("Tries to add the same member ", async () => {
            try {
                await holon.addMember ( firstMember, "Roberto",{ from: firstMember });
            } catch (_) {}

            const holonsize = await holon.getHolonSize();
            assert.equal(holonsize.toString(), "1", "Holon size not equal to 1");
        })

        it("Tries to add a new member with same name", async () => {
            try {
                await holon.addMember ( secondMember, "Roberto",{ from: owner });
            } catch (_){}

            const holonsize = await holon.getHolonSize();
            assert.equal(holonsize.toString(), "1", "Holon size not equal to 1");
        })

        it("Adds a second member", async () => {
            try {
                await holon.addMember ( secondMember, "Josh",{ from: firstMember });
            } catch (_){}

            const holonsize = await holon.getHolonSize();
            assert.equal(holonsize.toString(), "2", "Holon size not equal to 2");
        })
        
        it("Creates a new holon with the second member, and adds it as a member", async () => {
            await factory.newHolon("Second", { from: owner });
            secondholonaddress = await factory.newHolon.call("Second"); 
            secondholon = await Holon.at(secondholonaddress);

            await secondholon.addMember ( secondMember, "Josh",{ from: owner });
            const secondholonsize = await secondholon.getHolonSize();
            assert.equal(secondholonsize.toString(), "1","Second holon size not equal to 1");
 
            await holon.addMember ( secondholonaddress, "Holon", { from: secondMember });
            let size = await holon.getHolonSize();
            assert.equal(size.toString(), "3", "Holon size not equal to 3");
        })


    })
    
    describe("Holon Appreciation Test", _ => {
        let factory;
        let holonaddress;
        let holon;
  
        it("Member shares appreciation to another member", async () => {
            factory = await HolonFactory.deployed();
            holonaddress = await factory.toAddress.call("First");
            holon = await Holon.at(holonaddress);
          
            await holon.dish (secondMember, 10, {from:firstMember})
            await holon.dish (firstMember, 11, {from:secondMember})
            const appr1 = await holon.dished.call(firstMember, secondMember);
            const appr2 = await holon.dished.call(secondMember, firstMember);
            assert.equal(appr1.toString(), "10", "Wrong appreciation received");
            assert.equal(appr2.toString(), "11", "Wrong appreciation received");
          
        })

        // it("Member shares appreciation to another member", async () => {
        //     await holon.sendLoveTo (secondMember, 10, {from:firstMember})
        //     await holon.sendLoveTo (firstMember, 11, {from:secondMember})
        //     const appr1 = await holon.appreciation.call(firstMember, secondMember);
        //     const appr2 = await holon.appreciation.call(secondMember, firstMember);
        //     assert.equal(appr1.toString(), "10", "Wrong appreciation received");
        //     assert.equal(appr2.toString(), "11", "Wrong appreciation received");
          
        // })

        it("Sends rewards according to appreciation", async () => {
            // make appreciation equal
            await holon.dish (secondMember, 1, {from:firstMember}) // appreciation should now be equal to firstMember            
            const appr1 = await holon.dished.call(firstMember, secondMember);
            const appr2 = await holon.dished.call(secondMember, firstMember);
            assert.equal(appr1.toString(), appr2.toString(), "Appreciation not equal");
            
            // check consistent holon size
            const size = await holon.getHolonSize();
            assert.equal(size.toString(), "3","Wrong holon size");
        
            // check balance prior to transaction
            let balance1 = await web3.eth.getBalance(firstMember);
            await  holon.reward.sendTransaction({value: web3.utils.toWei("1", "ether"), from: owner})
            balance2 = await web3.eth.getBalance(firstMember);
            assert.equal(balance2.toString(), (eval(balance1) +  eval(web3.utils.toWei("0.5", "ether"))) .toString(), "Recieved different rewards");
           
        })

        it("Sends Token rewards according to appreciation", async () => {
            //transfer 10 tokens to a member
            let token = await TestToken.deployed();
            await token.transfer(firstMember,10, {from:owner});
           
            // check balance prior to transaction
            balance1 = await token.balanceOf(firstMember);
            assert.equal(balance1.toString(),"10", "token transaction not functioning correctly")
            
            //approve contract to spend 1000 tokens 
            await token.approve(holon.address,1000,{from:owner});
            allowance = await token.allowance(owner, holon.address);
            assert.equal(allowance.toString(), "1000" .toString(), "Contract token allowance is not correct");
            await  holon.tokenReward(token.address,1000,{from:owner});
            balance2 = await token.balanceOf(firstMember);
            assert.equal(balance1.toString(), (eval(balance2) - eval(500)) .toString(), "Recieved different amount of reward for same appreciation");   
        })

        it("Tests Recursive Reward", async () => {
            //create two holons
            await factory.newHolon("A", { from: owner });
            let A =  await factory.newHolon.call("A");
            await factory.newHolon("B", { from: owner });
            let B = await factory.newHolon.call("B");
            let holonA = await Holon.at(A);
            let holonB = await Holon.at(B);
            //add holon members and normal members
            await holonA.addMember(B, "B",  { from: owner });
            await holonA.addMember(firstMember, "FirstMember",  { from: B });
            await holonB.addMember(A, "A",  { from: owner });
            await holonB.addMember(secondMember, "SecondMember",  { from: A });

            //reward the holons and see what happens ;)
            await holonA.reward.sendTransaction({value: web3.utils.toWei("10", "ether"), from: owner});
        })
            

        it("Holon shares appreciation to another member", async () => {
            holon.sendHolonLoveTo(holonaddress,secondMember,10,{from:owner});
        })

        it("Holon shares appreciation to another holon member", async () => {
        })
    })

  
})