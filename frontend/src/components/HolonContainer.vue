<template>
  <div>
    <router-link class="holon-link mr-2" :to="`/${homeHolon}`">
      <font-awesome-icon :icon="['far', 'circle']" class="-mr-2" />
      <font-awesome-icon :icon="['far', 'circle']" />
      Home
    </router-link>
    <router-link
      v-for="(holon, index) in holonList"
      class="holon-link"
      :to="`/${holon.address}`"
      :key="`holonlink-${index}`"
    >
      <font-awesome-icon :icon="['far', 'circle']" class="-mr-2" />
      <font-awesome-icon :icon="['far', 'circle']" />

      <span>{{ holon.name }}</span>
    </router-link>
    <div class="h-24 block min-w-full  m-0">
      <h1 v-if="holonName" class="text-5xl  text-white ">
        {{ holonName }}
      </h1>
      <h3>
        {{ holonaddress }}
      </h3>
    </div>
    <div class="m-grid-outer -mt-20">
      <div class="m-grid-container" name="gridmove-move">
        <div class="circle row-4 c-3  c-search-outer" key="fixed-possition">
          <div class="c-inner text-white text-2xl">
            {{ holonName }}
            <button
              class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
              @click="openAddLoveModal(holonaddress, true)"
            >
              Support ❤️ us!
            </button>
          </div>
        </div>
        <div
          v-for="(member, index) in holonMembers"
          class="circle"
          :class="getCircleClass(index)"
          :key="`${member.name}-${index}`"
        >
          <div class=" c-inner profile-card">
            <div class="px-6 py-4 ">
              <router-link :to="`/${member.address}`">
                <h2
                  class="font-bold text-xl text-white"
                  :title="member.address"
                >
                  {{ member.name }}
                </h2>
              </router-link>
            </div>
            <div>
              <holon-stats
                :expanded="false"
                :love="member.love"
                :remaining="member.remaininglove"
                :recieved="member.rewards"
                :casted="castedlove"
                :totalrewards="totalrewards"
              />
              <button
                v-if="member.address !== defaultAccount"
                class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
                @click="openAddLoveModal(index)"
              >
                send ❤️
              </button>
            </div>
          </div>
        </div>
        <holon-add
          :showAddField="showAddField"
          :key="'add-member'"
          @addMember="addMember"
          @addHolon="newHolon"
          @visible="toggleAddField"
        >
        </holon-add>
      </div>
    </div>
    <div v-if="holonMembers.length > 0">
      <h2 class="text-2xl  text-white ">Full member list</h2>
      <div class="flex mb-4 justify-center flex-wrap">
        <div
          v-for="(member, index) in holonMembers"
          :key="`member-${index}`"
          class="p-4 text-white max-w-md border border-blue-900 rounded-md m-3 "
        >
          <router-link :to="`/${member.address}`">
            <div class="px-6 py-4 truncate max-w-xs">
              <h2 class="font-bold text-xl mb-2">{{ member.name }}</h2>
              <small>{{ member.address }} </small>
            </div>
          </router-link>
          <div class="max-w-xs">
            <holon-stats
              :expanded="true"
              :love="member.love"
              :remaining="member.remaininglove"
              :recieved="member.rewards"
              :casted="castedlove"
              :totalrewards="totalrewards"
            />

            <button
              class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
              @click="openAddLoveModal(index)"
            >
              send ❤️
            </button>
          </div>
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
        <span
          v-if="addLoveModal.holon"
          class="text-gray-600 italic text-3xl pl-2"
        >
          / {{ addLoveModal.maxAmount }} ETH
        </span>
        <span v-else class="text-gray-600 italic text-3xl pl-2 ">
          / {{ addLoveModal.maxAmount - addLoveModal.amount }} ❤️
        </span>
        <div class="slidecontainer">
          <input
            type="range"
            :min="minAmount"
            :step="stepSize"
            :max="addLoveModal.maxAmount"
            v-model="addLoveModal.amount"
            class="slider"
          />
        </div>
      </div>
      <template slot="footer">
        <button
          v-if="addLoveModal.holon"
          class="bg-blue-500 hover:bg-blue-700 text-white rounded-full px-3 py-1 text-sm font-semibold m-2"
          @click="sendFunds(addLoveModal.target, addLoveModal.amount)"
        >
          send ❤️
        </button>
        <button
          v-else
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
import holonabi from "../data/holonabi.json";
import hackalongabi from "../data/hackalongabi.json";
export default {
  name: "HolonContainer",
  props: ["holonNav"],
  data() {
    return {
      showAddLoveModal: false,
      showAddField: false,
      addLoveModal: {
        holon: false,
        header: null,
        target: null,
        amount: 0,
        maxAmount: 100,
      },
      defaultAccount: null,
      contract: null,
      factory: null,
      holonList: [],
      holonName: "",
      holonMembers: [],
      holon: null,
      user: null,
      holonabi: holonabi,
      hackalongabi: hackalongabi,
      homeHolon: "0x82Aa4dC3E7D85a95cd801394A070AE316b6a668d",
      holonaddress: null,
      castedlove: 0,
      totallove: 0,
      totalrewards: 0,
      hackalongaddress: "0x11D142091C53A699eE80Aee0ab509F28BE4C3564",
      circleClass: [
        "row-3 c-2",
        "row-2 c-3",
        "row-3 c-4",
        "row-5 c-4",
        "row-6 c-3",
        "row-5 c-2",

        "row-1 c-3",
        "row-2 c-5",
        "row-6 c-5",
        "row-7 c-3",
        "row-6 c-1",
        "row-2 c-1",
      ],
    };
  },
  computed: {
    minAmount() {
      return this.addLoveModal.holon ? "0" : "1";
    },
    stepSize() {
      return this.addLoveModal.holon ? "0.0001" : "1";
    },
  },
  methods: {
    connectWeb3() {
      web3.eth.getAccounts((error, result) => {
        if (error) {
          console.log(error);
        } else {
          web3.defaultAccount = result[0];
          this.defaultAccount = result[0];
        }
      });
      this.holon = new web3.eth.Contract(this.holonabi, this.holonaddress);
      this.factory = new web3.eth.Contract(
        this.hackalongabi,
        this.hackalongaddress
      );
      this.makeHolonList();

      this.getTeam();
    },
    makeHolonList() {
      this.factory.methods
        .listHolons()
        .call()
        .then((data) => {
          if (data) {
            for (var i = 0; i < data.length; i++) {
              this.holonList[i] = {
                address: data[i],
                name: "",
              };
              this.getHolonName(data[i], i);
            }
          }
        });
    },
    getHolonName(address, index) {
      this.factory.methods
        .toName(address)
        .call()
        .then((data) => {
          this.holonList[index].name = data;
          this.$forceUpdate();
        });
    },
    getTeam() {
      this.holon.methods
        .getName()
        .call()
        .then((data) => {
          this.holonName = data;
        });

      this.holon.methods
        .totallove()
        .call()
        .then((data) => {
          this.totallove = data;
        });

      this.holon.methods
        .totalrewards()
        .call()
        .then((data) => {
          this.totalrewards = web3.utils.fromWei(data, "ether");
        });

      this.holon.methods
        .castedlove()
        .call()
        .then((data) => {
          this.castedlove = data;
        });

      this.holon.methods
        .listMembers()
        .call()
        .then((data) => {
          this.makeTeam(data);
        });
    },
    makeTeam(members) {
      for (var i = 0; i < members.length; i++) {
        this.holonMembers.push({
          address: members[i],
          name: "",
          love: "",
          remaininglove: "",
          rewards: "",
          profile: "",
        });
        this.getName(i);
        this.getLove(i);
        this.getRewards(i);
        this.getRemainingLove(i);
        this.findMe();
      }
    },
    getName(index) {
      this.holon.methods
        .toName(this.holonMembers[index].address)
        .call()
        .then((data) => {
          this.holonMembers[index].name = data;
        });
    },
    getRemainingLove(index) {
      this.holon.methods
        .remaininglove(this.holonMembers[index].address)
        .call()
        .then((data) => {
          this.holonMembers[index].remaininglove = data;
        });
    },
    getRewards(index) {
      this.holon.methods
        .rewards(this.holonMembers[index].address)
        .call()
        .then((data) => {
          this.holonMembers[index].rewards = web3.utils.fromWei(data, "ether");
        });
    },
    getLove(index) {
      this.holon.methods
        .love(this.holonMembers[index].address)
        .call()
        .then((data) => {
          this.holonMembers[index].love = data;
        });
    },
    findMe() {
      this.user = this.holonMembers.findIndex(
        (x) => x.address === web3.defaultAccount
      );
    },
    sendLove(address, amount) {
      this.holon.methods
        .sendLoveTo(address, amount)
        .send({ from: web3.defaultAccount })
        .then(() => {
          this.getRemainingLove(this.user);
        });
      this.closeAddLoveModal();
    },
    sendFunds(address, amount) {
      web3.eth.sendTransaction({
        to: address,
        from: web3.defaultAccount,
        value: web3.utils.toWei(amount, "ether"),
      });
      this.closeAddLoveModal();
    },
    addMember(address, name) {
      this.holon.methods
        .addMember(address, name)
        .send({ from: web3.defaultAccount })
        .then((data) => {
          console.log("success" + data);
        });
      this.showAddField = false;
    },
    newHolon(name) {
      this.factory.methods
        .newHolon(name)
        .send({ from: web3.defaultAccount })
        .then((data) => {
          console.log(data);
        });
      this.showAddField = false;
    },
    openAddLoveModal(index, holon) {
      if (holon) {
        this.addLoveModal.holon = true;
        this.addLoveModal.target = this.holonaddress;
        this.addLoveModal.header = this.holonName;
        new web3.eth.getBalance(web3.defaultAccount).then((bal) => {
          var balance = web3.utils.fromWei(bal, "ether");
          this.addLoveModal.maxAmount = balance;
        });
      } else {
        this.addLoveModal.holon = false;
        this.addLoveModal.target = this.holonMembers[index].address;
        this.addLoveModal.header = this.holonMembers[index].name;
        this.addLoveModal.maxAmount = this.holonMembers[
          this.user
        ].remaininglove;
      }

      this.showAddLoveModal = true;
    },
    closeAddLoveModal() {
      this.addLoveModal.holon = false;
      this.addLoveModal.target = "";
      this.addLoveModal.header = "";
      this.addLoveModal.amount = 0;
      this.addLoveModal.maxAmount = 100;
      this.showAddLoveModal = false;
    },
    toggleAddField(e) {
      this.showAddField = e;
      this.addingMember = false;
    },
    getCircleClass(index) {
      return this.circleClass[index];
    },
  },
  mounted() {
    if (this.holonNav) {
      let isEth = /^0x[a-fA-F0-9]{40}$/.test(this.holonNav);
      if (isEth) {
        this.holonaddress = this.holonNav;
        this.connectWeb3();
      } else {
        this.holonaddress = this.homeHolon;
        this.connectWeb3();
      }
    } else {
      this.holonaddress = this.homeHolon;
      this.connectWeb3();
    }
  },
};
</script>
