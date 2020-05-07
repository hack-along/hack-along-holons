 
const Holon = artifacts.require("./Holon.sol")
const Hackalong = artifacts.require("./HackAlong.sol")

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
            assert.equal(secondholonsize.toString(), "1", "Second holon size not equal to 1");
    
            await holon.addMember ( secondholonaddress, "Holon", { from: owner });
            let size = await holon.getHolonSize();
            assert.equal(size.toString(), "3", "Holon size not equal to 3");
        })


    })
    
    
})