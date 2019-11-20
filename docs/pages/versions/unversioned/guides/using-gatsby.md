---
title: Using Gatsby with Expo for Web
---

> Notice: Pre-rendering is an experimental feature with Expo so modules might not be fully optimized for Gatsby and the workflow is subject to breaking changes. If you find bugs please report them on [expo/expo](https://github.com/expo/expo/issues) with the `[Gatsby]` tag in the title.

- [Example](#example)
- [🏁 Setup](#-setup)
  - [Expo projects with Gatsby](#expo-projects-with-gatsby)
  - [Gatsby projects with Expo](#gatsby-projects-with-expo)
- [New Commands](#️-new-commands)
- [Contributing](#contributing)
- [Learn more](#learn-more-about-gatsby)

[Gatsby](https://www.gatsbyjs.org/) is a React framework that helps you perform pre-rendering on your websites.
Using Gatsby with Expo will enable you to [pre-render](https://www.netlify.com/blog/2016/11/22/prerendering-explained/) the web part of your Expo app. You'll also be able to use the web-enabled Expo SDK libraries (eg: Permissions, GestureHandler, Camera) with the Gatsby toolchain!

This guide will show you how to use the Gatsby CLI to develop your websites with the Expo SDK.

## Example

If you'd like to jump right into a working project then check out [expo/examples: with-gatsby](https://github.com/expo/examples/edit/master/with-gatsby/).

## 🏁 Setup

We put all of the features for Expo web in the plugin [`gatsby-plugin-react-native-web`](https://github.com/slorber/gatsby-plugin-react-native-web) so setup would be as easy as possible. This guide will show you how to install and use it. Under the hood it's basically doing what `expo start:web` or the Expo + Next.js workflows are doing.

### Expo projects with Gatsby

For using the Gatsby tools in a universal app with the Expo SDK.

<details><summary>Instructions</summary>
<p>
  
- Create a new project - `expo init --template blank`
- Install the plugin
  - **using yarn** - `yarn add gatsby-plugin-react-native-web`
  - using npm - `npm install --save gatsby-plugin-react-native-web`
- Create a `gatsby-config.js` and use the plugin - `touch gatsby-config.js`

  `gatsby-config.js`

  ```js
  module.exports = {
    plugins: [
      `gatsby-plugin-react-native-web`,
      /* ... */
    ],
  };
  ```

- Install the babel preset: `yarn add -D babel-preset-expo`

- Create a `babel.config.js` and use the Babel preset - `touch babel.config.js`

  `babel.config.js`

  ```js
  module.exports = {
    presets: ['babel-preset-expo'],
  };
  ```

- Add `/.cache` and `/public` to your `.gitignore`
- Run `yarn gatsby develop` to try it out!

</p>
</details>

### Gatsby projects with Expo

For using the Expo SDK in a web-only Gatsby project.

<details><summary>Instructions</summary>
<p>

- Create a new Gatsby project
  - Install the CLI - `npm install -g gatsby-cli`
  - Bootstrap - `gatsby new gatsby-site`
- Install the plugin
  - **using yarn** - `yarn add react-native-web gatsby-plugin-react-native-web`
  - using npm - `npm install --save react-native-web gatsby-plugin-react-native-web`
- Create a `gatsby-config.js` and use the plugin - `touch gatsby-config.js`

  `gatsby-config.js`

  ```js
  module.exports = {
    plugins: [
      `gatsby-plugin-react-native-web`,
      /* ... */
    ],
  };
  ```

- Install the babel preset
  - **using yarn** - `yarn add -D babel-preset-expo`
  - using npm - `npm install --save-dev babel-preset-expo`
- Create a `babel.config.js` and use the Babel preset - `touch babel.config.js`

  `babel.config.js`

  ```js
  module.exports = {
    presets: ['babel-preset-expo'],
  };
  ```

- Add `/.cache` and `/public` to your `.gitignore`
- Run `yarn gatsby develop` to try it out!
- [optional] You can now install other Expo modules:
  - Core packages: `yarn add expo`
  - Gestures: `yarn add react-native-gesture-handler`
  - hooks: `yarn add react-native-web-hooks`

</p>
</details>

## ⌨️ New Commands

You'll want to use the Gatsby CLI to develop the web part of your app now. You should still use `expo-cli` to run on iOS, and Android.

- **Starting web**

  - 🚫 `expo start:web`
  - ✅ `yarn gatsby develop`

- **Building web**

  - 🚫 `expo build:web`
  - ✅ `yarn gatsby build`

- **Serving your static project**
  - 🚫 `serve web-build`
  - ✅ `yarn gatsby serve`

## Contributing

If you would like to help make Gatsby support in Expo better, please feel free to open a PR or submit an issue:

- [Expo CLI][expo-cli]

If you have any problems rendering a certain component with pre-rendering then you can submit fixes to the expo/expo repo:

- [Expo SDK packages][expo-packages]

If you're curious how Expo support works under the hood, you can refer to this pull request:

- [Expo/Gatsby support PR](https://github.com/slorber/gatsby-plugin-react-native-web/pull/14)

## Learn more about Gatsby

Learn more about how to use Gatsby in their [docs](https://www.gatsbyjs.org/docs).

[expo-packages]: https://github.com/expo/expo/tree/master/packages
[expo-cli]: https://github.com/expo/expo-cli/
