<template>
  <div>
    <h1 v-if="teamName" class="text-5xl my-4 text-white">{{ teamName }}</h1>
    <div v-if="teamMembers" class="flex mb-4 justify-center">
      <div
        v-for="(member, index) in teamMembers"
        :key="`member-${index}`"
        class="profile-card"
      >
        <div class="px-6 py-4">
          <h2 class="font-bold text-xl mb-2">{{ member.name }}</h2>
          <small>{{ member.address }} </small>
        </div>
        <div class="px-6 py-4">
          <span
            class="inline-block bg-gray-200 rounded-full px-3 py-1 text-sm font-semibold text-gray-700 m-2"
          >
            ❤️ {{ member.remainingvotes }} remaining
          </span>

          <button
            class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
            @click="sendLove(member.address, index)"
          >
            send ❤️
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import web3 from "../libs/web3.js";
import abi from "../data/abi.json";
export default {
  name: "web3form",
  data() {
    return {
      ethereum: false,
      contract: null,
      teamName: "",
      teamMembers: [],
      team: null,
      user: null,
      TEAMABI: abi,
      address: "0x63aef31d8b104eb9b6c189a513cc2f5efa3dee75",
    };
  },
  methods: {
    connectWeb3() {
      web3.eth.getAccounts((error, result) => {
        if (error) {
          console.log(error);
        } else {
          console.log(result);
          web3.defaultAccount = result[0];
        }
      });
      this.team = new web3.eth.Contract(this.TEAMABI, this.address);
      this.getTeam();
    },
    getTeam() {
      this.team.methods
        .getName()
        .call()
        .then((data) => {
          this.teamName = data;
        });

      this.team.methods
        .getAllMembers()
        .call()
        .then((data) => {
          console.log(data);
          this.makeTeam(data);
        });
    },
    makeTeam(members) {
      for (var i = 0; i < members.length; i++) {
        this.teamMembers.push({
          address: members[i],
          name: "",
          remainingvotes: "",
        });
        this.getToName(i);
        this.getRemainingVotes(i);
        this.findMe();
      }
    },

    getToName(index) {
      this.team.methods
        .toName(this.teamMembers[index].address)
        .call()
        .then((data) => {
          this.teamMembers[index].name = data;
        });
    },
    getRemainingVotes(index) {
      this.team.methods
        .remainingvotes(this.teamMembers[index].address)
        .call()
        .then((data) => {
          this.teamMembers[index].remainingvotes = data;
        });
    },
    findMe() {
      this.user = this.teamMembers.findIndex(
        (x) => x.address === web3.defaultAccount
      );
    },
    sendLove(address) {
      console.log(web3.defaultAccount);
      this.team.methods
        .voteforMember(address, 1)
        .send({ from: web3.defaultAccount })
        .then(() => {
          this.getRemainingVotes(this.user);
        });
    },
  },
  mounted() {
    this.connectWeb3();
  },
};
</script>
