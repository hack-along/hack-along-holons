import Vue from "vue";

import "@/design/scss/index.scss";

import "./plugins/fontawesome";
import App from "./App.vue";
import "./registerServiceWorker";
import router from "./router";
import store from "./store";

Vue.component("modal", () => import("./components/Modal.vue"));
Vue.component("holon-add", () => import("./components/HolonAddEntity.vue"));
Vue.config.productionTip = false;

new Vue({
  router,
  store,
  render: (h) => h(App),
}).$mount("#app");
