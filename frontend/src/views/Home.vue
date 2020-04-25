<template>
  <div class="profile-view">
    <span v-if="ethereum && web3">
      network: {{ web3.currentProvider.networkVersion }} account:{{
        web3.eth.defaultAccount
      }}
    </span>
    <h1 v-if="teamName" style="margin-bottom:2rem">{{ teamName }}</h1>
    <template v-if="teamMembers">
      <ul v-for="(member, index) in teamMembers" :key="`member-${index}`">
        <li style="margin-bottom:2rem">
          <h2>{{ member.name }}</h2>

          ❤️ {{ member.remainingvotes }} remaining
          <button @click="sendLove(member.address, index)">send ❤️</button>
          <br /><small>{{ member.address }} </small>
        </li>
      </ul>
    </template>
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
