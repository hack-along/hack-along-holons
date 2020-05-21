<template>
  <div id="app" class="container mx-auto pt-8">
    <router-view :key="$route.name + ($route.params.holon || '')" />

    <v-tour name="myTour" :steps="steps"></v-tour>
    <button
      @click="startTour"
      class="fixed right-0 bottom-0 border border-gray-600 text-gray-600 hover:border-gray-100 hover:text-gray-100 p-4 rounded-full w-16 h-16 mr-12 mb-12"
      title="start a tour"
    >
      <font-awesome-icon :icon="['fas', 'info']" size="xl" />
    </button>
  </div>
</template>
<script>
export default {
  name: "stats",
  data() {
    return {
      steps: [
        {
          target: "#v-step-0",
          header: {
            title: "Get Started"
          },
          content: `Welcome to <strong> holons </strong>!`
        },
        {
          target: ".v-step-1",
          content: "If you send a transaction to the holon, it will be split to its members according to the appreciation received",
          params: {
            placement: "bottom",
            enableScrolling: false
          }
        },
        {
          target: "#v-step-2",
          content: "Click here to create your holon and add members to it",
          params: {
            placement: "left",
            enableScrolling: false
          }
        }
      ]
    };
  },
  methods: {
    startTour() {
      this.$tours["myTour"].start();
    }
  }
};
</script>
<style lang="scss">
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
}

#nav {
  padding: 30px;
}
</style>

  