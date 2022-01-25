module.exports = {
  "env": {
    "browser": true,
    "commonjs": true,
    "es6": true,
    "node": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "sourceType": "module"
  },
  "rules": {
    "no-undef":"off",
    "no-unreachable":"off",
    "no-console":"off",
    "no-regex-spaces":"off",

    "no-cond-assign":"off",
    "no-extra-semi":"off",
    "no-inner-declarations":"off",
    "no-redeclare":"off",
    "no-empty":"off",

    "no-unused-vars":"off",
    "no-fallthrough":"off",
    "no-constant-condition":"off",
    "indent": [ "warn", 2 ],
    "linebreak-style": [ "warn", "unix" ],
  }
};
