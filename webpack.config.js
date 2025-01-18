const path = require('path');

const main = {
  mode: 'development',
  target: 'electron-main',
  entry: './src/main.ts',
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'main.js'
  },
  module: {
    rules: [{
      test: /\.ts$/,
      use: 'ts-loader',
      exclude: /node_modules/
    }]
  },
  resolve: {
    extensions: ['.ts', '.js']
  },
  node: {
    __dirname: false,
    __filename: false
  }
};

const renderer = {
  mode: 'development',
  target: 'electron-renderer',
  entry: './src/renderer.ts',
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'renderer.js'
  },
  module: {
    rules: [{
      test: /\.ts$/,
      use: 'ts-loader',
      exclude: /node_modules/
    }]
  },
  resolve: {
    extensions: ['.ts', '.js']
  }
};

module.exports = [main, renderer];
