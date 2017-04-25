var LOCAL_STORAGE_MODEL_KEY = "localStorageModel";

// eslint-disable-next-line no-unused-vars
function setup() {
  removeLoader();
  setupElm();
}

function removeLoader() {
  var loader = document.getElementById("loader");
  loader.parentNode.removeChild(loader);
}

function setupElm() {
  var app = Elm.Main.embed(document.getElementById("app"), {
    debug: isDebug(window.location.search),
    // eslint-disable-next-line no-magic-numbers
    randomSeed: Math.floor(Math.random() * 0xffffffff),
    localStorageModelString: getLocalStorageModel()
  });

  app.ports.setLocalStorageModel.subscribe(setLocalStorageModel);
}

function isDebug(queryString) {
  return /(?:^|[?&])debug=1(?:$|&)/.test(queryString);
}

function getLocalStorageModel() {
  return window.localStorage.getItem(LOCAL_STORAGE_MODEL_KEY);
}

function setLocalStorageModel(string) {
  try {
    return window.localStorage.setItem(LOCAL_STORAGE_MODEL_KEY, string);
  } catch (error) {
    console.warn("Failed to write to localStorage", {
      LOCAL_STORAGE_MODEL_KEY: LOCAL_STORAGE_MODEL_KEY,
      string: string,
      error: error
    });
  }
  return null;
}
