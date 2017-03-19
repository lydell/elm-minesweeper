// eslint-disable-next-line no-unused-vars
function setup() {
  setupElm();
}

function setupElm() {
  Elm.Main.embed(document.getElementById("app"), {
    // eslint-disable-next-line no-magic-numbers
    randomSeed: Math.floor(Math.random() * 0xffffffff)
  });
}
