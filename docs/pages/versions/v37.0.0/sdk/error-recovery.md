---
title: ErrorRecovery
sourceCodeUrl: 'https://github.com/expo/expo/tree/sdk-37/packages/expo-error-recovery'
---

import PlatformsSection from '~/components/plugins/PlatformsSection';
import InstallSection from '~/components/plugins/InstallSection';

This module provides utilities for helping you gracefully handle crashes due to fatal JavaScript errors.

<PlatformsSection android emulator ios simulator web />

## Installation

<InstallSection packageName="expo-error-recovery" />

## API

```js
import * as ErrorRecovery from 'expo-error-recovery';
```

### `ErrorRecovery.setRecoveryProps(props)`

Set arbitrary error recovery props. If your project crashes in production as a result of a fatal JS error, Expo will reload your project. If you've set these props, they'll be passed to your reloaded project's initial props under `exp.errorRecovery`. [Read more about error handling with Expo](../../guides/errors/).

#### Arguments

- **props (_object_)** -- An object which will be passed to your reloaded project's initial props if the project was reloaded as a result of a fatal JS error.

#
