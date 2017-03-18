const NUMBER_INPUT_SELECTOR = "input[data-min], input[data-max]";

// eslint-disable-next-line no-unused-vars
function setup() {
  setupElm();
  setupNumberInputs();
}

function setupElm() {
  Elm.Main.embed(document.getElementById("app"), {
    // eslint-disable-next-line no-magic-numbers
    randomSeed: Math.floor(Math.random() * 0xffffffff)
  });
}

function setupNumberInputs() {
  delegate("input", NUMBER_INPUT_SELECTOR, event => {
    const input = event.target;
    const { value } = input;
    const position = input.selectionStart;
    const textBefore = removeNonDigits(value.slice(0, position));
    const textAfter = removeNonDigits(value.slice(position));
    const newValue = `${textBefore}${textAfter}`;
    const newPosition = textBefore.length;

    if (newValue !== value) {
      input.value = newValue;
      input.selectionStart = newPosition;
      input.selectionEnd = newPosition;
    }
  });

  delegate("blur", NUMBER_INPUT_SELECTOR, event => {
    const input = event.target;
    const { value } = input;
    const newValue = removeNonDigits(value);

    if (newValue !== value) {
      input.value = newValue;
    }
  });
}

function removeNonDigits(value) {
  return value.replace(/\D/g, "");
}

function delegate(eventName, selector, listener) {
  document.addEventListener(
    eventName,
    event => {
      if (event.target.matches && event.target.matches(selector)) {
        listener(event);
      }
    },
    true
  );
}
