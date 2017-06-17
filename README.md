# elm-minesweeper

The classic game MineSweeper made with Elm. **[Play it.][play]**

## Development

1. `yarn install`
2. `yarn run build:css`
3. `yarn start`

Add `?debug=1` to the URL to run in debug mode.

Additional tasks:

- `yarn run format` runs [elm-format].
- `yarn run analyse` runs [elm-analyse].
- `yarn run eslint` runs [ESLint]. `yarn run eslint -- --fix` fixes most errors.
- `yarn test` runs [elm-verify-examples] and [elm-test].
- `yarn run build` makes a production build.

## License

[MIT](LICENSE)

[ESLint]: http://eslint.org/
[elm-analyse]: https://github.com/stil4m/elm-analyse
[elm-format]: https://github.com/avh4/elm-format
[elm-test]: https://github.com/elm-community/elm-test/
[elm-verify-examples]: https://github.com/stoeffel/elm-verify-examples
[play]: https://lydell.github.io/elm-minesweeper
