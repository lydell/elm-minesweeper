module.exports = {
  extends: ["strict/es5", "prettier"],
  plugins: ["prettier"],
  rules: {
    "id-blacklist": "off",
    "no-console": "off",
    "no-use-before-define": ["error", { functions: false }],
    strict: "off",
    "prettier/prettier": "error"
  },
  globals: {
    Elm: false,
    document: false,
    window: false
  }
};
