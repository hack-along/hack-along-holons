<template>
  <div>
    <h1 v-if="teamName" class="text-5xl my-4 text-white">{{ teamName }}</h1>
    <div class="m-grid-outer">
      <transition-group class="m-grid-container" name="gridmove-move">
        <div class="circle row-4 c-3  c-search-outer" key="fixed-possition">
          <div class="c-inner text-white text-2xl">
            {{ teamName }}
          </div>
        </div>
        <div
          v-for="(member, index) in teamMembers"
          class="circle"
          :class="getCircleClass(index)"
          :key="`${member.name}-${index}`"
        >
          <div class=" c-inner profile-card">
            <div class="px-6 py-4">
              <h2 class="font-bold text-xl mb-2">{{ member.name }}</h2>
              <small>{{ member.address }} </small>
            </div>
            <div>
              <span
                v-if="member.address === defaultAccount"
                class="inline-block bg-gray-200  rounded-full px-3 py-1 text-sm font-semibold text-gray-700 m-2"
              >
                remaining ❤️ {{ member.remaininglove }}
              </span>

              <button
                v-else
                class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
                @click="openAddLoveModal(index)"
              >
                send ❤️
              </button>
            </div>
          </div>
        </div>
        <holon-add-member
          :showAddField="showAddField"
          :key="'add-member'"
          @addMember="addMember"
          @visible="toggleAddField"
        >
        </holon-add-member>
      </transition-group>
    </div>
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
            class="inline-block bg-gray-200  rounded-full px-3 py-1 text-sm font-semibold text-gray-700 m-2"
          >
            ❤️ {{ member.remaininglove }} remaining
          </span>

          <button
            class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
            @click="openAddLoveModal(index)"
          >
            send ❤️
          </button>
        </div>
      </div>
    </div>
    <modal
      v-if="showAddLoveModal"
      @close="closeAddLoveModal"
      :header="`Send to ${addLoveModal.header}`"
    >
      <div slot="body">
        <span class="text-blue-600 font-extrabold text-3xl">
          {{ addLoveModal.amount }}
        </span>
        <span class="text-gray-600 italic text-3xl pl-2">
          / {{ addLoveModal.maxAmount - addLoveModal.amount }}
        </span>
        <div class="slidecontainer">
          <input
            type="range"
            min="1"
            :max="addLoveModal.maxAmount"
            v-model="addLoveModal.amount"
            class="slider"
          />
        </div>
      </div>
      <template slot="footer">
        <button
          class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
          @click="sendLove(addLoveModal.target, addLoveModal.amount)"
        >
          send ❤️
        </button>
      </template>
    </modal>
  </div>
</template>
<script>
import web3 from "../libs/web3.js";
import abi from "../data/holonabi.json";
export default {
  name: "HolonContainer",
  data() {
    return {
      showAddLoveModal: false,
      showAddField: false,
      addLoveModal: {
        header: null,
        target: null,
        amount: 1,
        maxAmount: 100,
      },
      defaultAccount: null,
      contract: null,
      teamName: "",
      teamMembers: [],
      team: null,
      user: null,
      abi: abi,
      address: "0x82Aa4dC3E7D85a95cd801394A070AE316b6a668d",
      circleClass: [
        "row-2 c-3",
        "row-3 c-4",
        "row-5 c-4",
        "row-6 c-3",
        "row-5 c-2",
        "row-3 c-2",

        "row-1 c-3",
        "row-2 c-5",
        "row-6 c-5",
        "row-7 c-3",
        "row-6 c-1",
        "row-2 c-1",
      ],
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
          this.defaultAccount = result[0];
        }
      });
      this.team = new web3.eth.Contract(this.abi, this.address);
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
        .totallove()
        .call()
        .then((data) => {
          this.totalLove = data;
        });

      this.team.methods
        .totalrewards()
        .call()
        .then((data) => {
          this.totalRewards = data;
        });

      this.team.methods
        .castedlove()
        .call()
        .then((data) => {
          this.castedlove = data;
        });

      this.team.methods
        .listMembers()
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
          love: "",
          remaininglove: "",
          rewards: "",
        });
        this.getName(i);
        this.getRemainingLove(i);
        this.getRewards(i);
        this.getLove(i);
        this.findMe();
      }
    },
    getName(index) {
      this.team.methods
        .toName(this.teamMembers[index].address)
        .call()
        .then((data) => {
          this.teamMembers[index].name = data;
        });
    },
    getRemainingLove(index) {
      this.team.methods
        .remaininglove(this.teamMembers[index].address)
        .call()
        .then((data) => {
          this.teamMembers[index].remaininglove = data;
        });
    },
    getRewards(index) {
      this.team.methods
        .rewards(this.teamMembers[index].address)
        .call()
        .then((data) => {
          this.teamMembers[index].rewards = data;
        });
    },
    getLove(index) {
      this.team.methods
        .love(this.teamMembers[index].address)
        .call()
        .then((data) => {
          this.teamMembers[index].love = data;
        });
    },
    findMe() {
      this.user = this.teamMembers.findIndex(
        (x) => x.address === web3.defaultAccount
      );
    },
    sendLove(address, amount) {
      this.team.methods
        .sendLoveTo(address, amount)
        .send({ from: web3.defaultAccount })
        .then(() => {
          this.getRemainingLove(this.user);
        });
      this.closeAddLoveModal();
    },
    addMember(address, name) {
      this.team.methods
        .addMember(address, name)
        .send({ from: web3.defaultAccount })
        .then((data) => {
          console.log(data);
        });
      this.showAddField = false;
    },
    openAddLoveModal(index) {
      this.addLoveModal.target = this.teamMembers[index].address;
      this.addLoveModal.header = this.teamMembers[index].name;
      this.addLoveModal.maxAmount = this.teamMembers[this.user].remaininglove;
      this.showAddLoveModal = true;
    },
    closeAddLoveModal() {
      this.addLoveModal.target = "";
      this.addLoveModal.header = "";
      this.addLoveModal.amount = 1;
      this.addLoveModal.maxAmount = 100;
      this.showAddLoveModal = false;
    },
    toggleAddField(e) {
      this.showAddField = e;
    },
    getCircleClass(index) {
      return this.circleClass[index];
    },
  },
  mounted() {
    this.connectWeb3();
  },
};
</script>
