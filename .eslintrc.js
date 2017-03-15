module.exports = {
  extends: ["strict", "prettier"],
  plugins: ["prettier"],
  rules: {
    "id-blacklist": "off",
    "no-use-before-define": ["error", { functions: false }],
    "prettier/prettier": "error"
  },
  globals: {
    Elm: false,
    document: false
  }
};
