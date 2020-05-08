<template>
  <div class="flex justify-around flex-wrap">
    <span
      class="inline-block flex-initial text-xs text-red-500 font-semibold"
      :class="{ 'text-base block p-1 ': expanded }"
      title="love recived"
    >
      <small v-if="expanded">Recived</small>

      <font-awesome-icon :icon="['fas', 'arrow-right']" size="xs" />
      <font-awesome-icon :icon="['far', 'heart']" />
      {{ love }} / {{ precentage }} %
      <small v-if="expanded">of total</small>
    </span>

    <span
      class="inline-block flex-1 text-xs text-green-500 font-semibold mr-1"
      :class="{ 'text-base block p-1': expanded }"
      title="love left to sent"
    >
      <small v-if="expanded">Unsent</small>
      <font-awesome-icon :icon="['far', 'heart']" />
      {{ remaining }}
    </span>
    <br />
    <span
      v-if="recieved"
      class="inline-block flex-initial text-xs text-white font-semibold"
      :class="{ 'text-base block': expanded }"
      title="fund balance"
    >
      <small v-if="expanded">Recived</small>
      Ξ {{ recieved.slice(0, 5) }} /
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
    "expanded"
  ],
  data() {
    return {};
  },
  computed: {
    precentage() {
      if (this.love && this.casted) {
        return Math.floor((this.love / this.casted) * 100);
      } else {
        return 0;
      }
    }
  }
};
</script>
