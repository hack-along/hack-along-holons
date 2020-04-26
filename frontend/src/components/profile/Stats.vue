<template>
  <div>
    <span
      class="inline-block text-xs text-red-500 font-semibold mr-1 "
      :class="{ 'text-base block p-1': expanded }"
      title="love recived"
    >
      <small v-if="expanded">Recived </small>
      <font-awesome-icon :icon="['far', 'circle']" class="-mr-2" />
      <font-awesome-icon :icon="['far', 'heart']" />
      {{ love }}
    </span>

    <span
      class="inline-block text-xs text-green-500 font-semibold  mr-1 "
      :class="{ 'text-base block p-1': expanded }"
      title="love left to sent"
    >
      <small v-if="expanded"> Unsent </small>
      <font-awesome-icon :icon="['far', 'heart']" />
      {{ remaining }}
    </span>

    <span
      class="inline-block text-xs text-white font-semibold  mr-1 "
      :class="{ 'text-base block p-1': expanded }"
      title="precentage of total"
    >
      <small v-if="expanded"> Of total </small>{{ precentage }} %
    </span>
    <br />
    <span
      v-if="recieved"
      class="inline-block text-xs text-white font-semibold   "
      :class="{ 'text-base block': expanded }"
      title="fund balance"
    >
      <small v-if="expanded"> Recived </small> Ξ {{ recieved.slice(0, 5) }} /
      {{ totalrewards.slice(0, 5) }}
    </span>
  </div>
</template>

<script>
export default {
  name: "stats",
  props: [
    "love",
    "remaining",
    "recieved",
    "balance",
    "casted",
    "totalrewards",
    "expanded",
  ],
  data() {
    return {};
  },
  computed: {
    precentage() {
      if (this.recieved && this.casted) {
        return Math.floor((this.recieved / this.casted) * 100);
      } else {
        return 0;
      }
    },
  },
};
</script>
