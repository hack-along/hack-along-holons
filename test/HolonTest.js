 
const Holon = artifacts.require("./Holon.sol")
const Hackalong = artifacts.require("./HackAlong.sol")
const TestToken = artifacts.require("./TestToken.sol")

contract("Holon", async accounts => {

    const owner = accounts[0]
    const firstMember = accounts[1]
    const secondMember = accounts[2]

    const initHolon = async (from) => {
        const factory = await Hackalong.deployed()
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
            factory = await Hackalong.deployed();
            await factory.newHolon("First", { from: owner });
            holonaddress = await factory.newHolon.call("First", { from: owner });
            
            const size = await factory.nholons();
            assert.equal(size.toString(), "1", "nholons not equal to 1")
            let address = await factory.listMyHolons({from:owner});
            assert.equal(address.toString(),holonaddress.toString(),"address mismatch");
            address = await factory.listMyHolons({from:firstMember});
            assert.equal(address.toString(),"","address mismatch");
   
        })

        it("Fails creating a new Holon with the same name ", async () => {
            await factory.newHolon("First", { from: owner });
            const newholonaddress = await factory.newHolon.call("First", { from: owner })
            const size = await factory.nholons();
            assert.equal(size.toString(), "1", "nholons not equal to 1")
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
                await holon.addMember ( secondMember, "Josh",{ from: owner });
            } catch (_){}

            const holonsize = await holon.getHolonSize();
            assert.equal(holonsize.toString(), "2", "Holon size not equal to 2");
        })
        
        it("Creates a new holon with the second member, and adds it as a member", async () => {
            await factory.newHolon("Second", { from: owner });
            secondholonaddress = await factory.newHolon.call("Second"); 
            secondholon = await Holon.at(secondholonaddress);

            await secondholon.addMember ( secondMember, "Josh");
            const secondholonsize = await secondholon.getHolonSize();
            assert.equal(secondholonsize.toString(), "1","Second holon size not equal to 1");
 
            await holon.addMember ( secondholonaddress, "Holon", { from: owner });
            let size = await holon.getHolonSize();
            assert.equal(size.toString(), "3", "Holon size not equal to 3");
        })


    })
    
    describe("Holon Appreciation Test", _ => {
        let factory;
        let holonaddress;
        let holon;
  
        it("Member shares appreciation to another member", async () => {
            factory = await Hackalong.deployed();
            holonaddress = await factory.getHolon.call(0);
            holon = await Holon.at(holonaddress);
          
            await holon.appreciate (secondMember, 10, {from:firstMember})
            await holon.appreciate (firstMember, 11, {from:secondMember})
            const appr1 = await holon.appreciation.call(firstMember, secondMember);
            const appr2 = await holon.appreciation.call(secondMember, firstMember);
            assert.equal(appr1.toString(), "10", "Wrong appreciation received");
            assert.equal(appr2.toString(), "11", "Wrong appreciation received");
          
        })

        // it("Member shares love to another member", async () => {
        //     await holon.sendLoveTo (secondMember, 10, {from:firstMember})
        //     await holon.sendLoveTo (firstMember, 11, {from:secondMember})
        //     const appr1 = await holon.appreciation.call(firstMember, secondMember);
        //     const appr2 = await holon.appreciation.call(secondMember, firstMember);
        //     assert.equal(appr1.toString(), "10", "Wrong appreciation received");
        //     assert.equal(appr2.toString(), "11", "Wrong appreciation received");
          
        // })

        it("Sends rewards according to appreciation", async () => {
            await holon.appreciate (secondMember, 1, {from:firstMember}) // appreciation should now be equal to firstMember            
            const appr1 = await holon.appreciation.call(firstMember, secondMember);
            const appr2 = await holon.appreciation.call(secondMember, firstMember);
            assert.equal(appr1.toString(), appr2.toString(), "Appreciation not equal");
            // check consistent holon size
            const size = await holon.getHolonSize();
            //assert.equal(size.toString(), "2","Wrong holon size");
        
            // check balance prior to transaction
            let balance1 = await web3.eth.getBalance(firstMember);
            await  holon.weightedReward.sendTransaction({value: web3.utils.toWei("1", "ether"), from: owner})
            balance2 = await web3.eth.getBalance(firstMember);
            assert.equal(balance1.toString(), (balance2 -  web3.utils.toWei("0.5", "ether")) .toString(), "Recieved different rewards");
           
        })

        it("Sends token rewards according to appreciation", async () => {
            let token = await TestToken.deployed();
            
            let tokenbalance = await token.balanceOf(owner);
            console.log(tokenbalance);
            
            // check balance prior to transaction
            balance1 = token.balanceOf(firstMember);
            token.approve(holon.address,50,{from:owner});
            await  holon.weightedTokenReward(token.address,1, {from: owner});
            balance2 = await token.balanceOf(firstMember);
            assert.equal(balance1.toString(), (balance2 -  25) .toString(), "Recieved different rewards");
           
        })

        it("Holon shares appreciation to another member", async () => {
            holon.sendHolonLoveTo(holonaddress,secondMember,10,{from:owner});
        })

        it("Holon shares appreciation to another holon member", async () => {
        })
    })

  
})