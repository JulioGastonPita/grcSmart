/* eslint-env node */
const { configure } = require('quasar/wrappers')

module.exports = configure(function (/* ctx */) {
  return {
    boot: [
      'axios'
    ],
    css: [
      'app.scss'
    ],
    extras: [
      'material-icons'
    ],
    build: {
      target: {
        browser: ['es2019', 'edge88', 'firefox78', 'chrome87', 'safari13.1'],
        node: 'node20'
      },
      vueRouterMode: 'history',
      typescript: {
        strict: true
      }
    },
    devServer: {
      open: false
    },
    framework: {
      config: {},
      plugins: [
        'Notify',
        'Dialog'
      ]
    },
    animations: [],
    ssr: {
      pwa: false,
      prodPort: 3000,
      middlewares: []
    },
    pwa: {
      workboxMode: 'generateSW',
      injectPwaMetaTags: true,
      swFilename: 'sw.js',
      manifestFilename: 'manifest.json',
      useCredentialsForManifestTag: false
    }
  }
})
