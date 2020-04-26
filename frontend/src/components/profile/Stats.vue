<template>
  <div>
    <span
      class="inline-block text-xs text-red-500 font-semibold mr-1 "
      title="love recived"
    >
      <font-awesome-icon :icon="['far', 'circle']" class="-mr-2" />
      <font-awesome-icon :icon="['far', 'heart']" />
      {{ love }}
    </span>

    <span
      class="inline-block text-xs text-green-500 font-semibold  mr-1 "
      title="love left to sent"
    >
      <font-awesome-icon :icon="['far', 'heart']" />
      {{ remaining }}
    </span>

    <span
      class="inline-block text-xs text-white font-semibold  mr-1 "
      title="precentage of total"
    >
      {{ precentage }} %
    </span>
    <br />
    <span
      v-if="recieved"
      class="inline-block text-xs text-white font-semibold   truncate"
      style="max-width:7rem;"
      title="fund balance"
    >
      <font-awesome-icon :icon="['fas', 'triangle']" class="-mr-2" />
      {{ recieved }}
    </span>
  </div>
</template>

<script>
export default {
  name: "stats",
  props: ["love", "remaining", "recieved", "balance", "casted"],
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
