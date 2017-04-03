const ExtractTextPlugin = require("extract-text-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const ScriptExtHtmlWebpackPlugin = require("script-ext-html-webpack-plugin");
const path = require("path");
const webpack = require("webpack");
const serverConfig = require("./server.config");

const DEBUG = process.env.NODE_ENV !== "production";
const OUTPUT_PATH = path.resolve(__dirname, "build");
const PUBLIC_PATH = "/";

const extractSass = new ExtractTextPlugin({
  filename: "[name].[contenthash].css",
  disable: DEBUG,
});

module.exports = {
  context: path.resolve(__dirname, "src"),

  entry: {
    main: "./js/main.js",
  },

  output: {
    filename: DEBUG ? "[name].js" : "[name].[chunkhash].js",
    path: OUTPUT_PATH,
    publicPath: PUBLIC_PATH,
    pathinfo: DEBUG,
  },

  devtool: DEBUG ? "cheap-module-source-map" : "source-map",

  devServer: {
    hot: true,
    contentBase: OUTPUT_PATH,
    publicPath: PUBLIC_PATH,
    historyApiFallback: true,
    overlay: true,
    port: serverConfig.frontend.port,
    stats: "errors-only",
    proxy: {
      [serverConfig.backend.graphql]: serverConfig.backend.endpoint,
      [serverConfig.backend.graphiql]: serverConfig.backend.endpoint,
    },
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
        },
      },
      {
        test: /\.scss$/,
        use: extractSass.extract({
          fallback: {
            loader: "style-loader",
          },
          use: [
            {
              loader: "css-loader",
              options: {
                sourceMap: true,
              },
            },
            {
              loader: "postcss-loader",
            },
            {
              loader: "sass-loader",
              options: {
                precision: 8,
                sourceMap: true,
              },
            },
          ],
        }),
      },
    ],
  },

  plugins: [
    extractSass,

    DEBUG && new webpack.HotModuleReplacementPlugin(),

    DEBUG
      ? new webpack.NamedModulesPlugin()
      : new webpack.HashedModuleIdsPlugin(),

    new webpack.optimize.CommonsChunkPlugin({
      name: "vendor",
      minChunks(module) {
        return module.context && module.context.includes("node_modules");
      },
    }),

    new webpack.optimize.CommonsChunkPlugin({
      name: "manifest",
      minChunks: Infinity,
    }),

    new HtmlWebpackPlugin({
      template: "./index.ejs",
      minify: DEBUG
        ? false
        : {
            removeComments: true,
            collapseWhitespace: true,
            minifyCSS: true,
            minifyJS: true,
            removeRedundantAttributes: true,
            removeScriptTypeAttributes: true,
            removeStyleLinkTypeAttributes: true,
          },
    }),

    new ScriptExtHtmlWebpackPlugin({
      inline: /manifest/,
      defaultAttribute: "defer",
    }),
  ].filter(Boolean),
};
