---
title: Speech
sourceCodeUrl: "https://github.com/expo/expo/tree/sdk-34/packages/expo-speech"
---

import SnackInline from '~/components/plugins/SnackInline';

This module allows using Text-to-speech utility.

**Platform Compatibility**

| Android Device | Android Emulator | iOS Device | iOS Simulator |  Web  |
| ------ | ---------- | ------ | ------ | ------ |
| ✅     |  ✅     | ✅     | ✅     | ❌    |

## Installation

For [managed](../../introduction/managed-vs-bare/#managed-workflow) apps, you'll need to run `expo install expo-speech`. To use it in a [bare](../../introduction/managed-vs-bare/#bare-workflow) React Native app, follow its [installation instructions](https://github.com/expo/expo/tree/master/packages/expo-speech).


## Usage

<SnackInline label='Basic Speech usage' templateId='speech' dependencies={['expo-speech']}>

```javascript
import * as React from 'react';
import { View, StyleSheet, Button } from 'react-native';
import Constants from 'expo-constants';
import * as Speech from 'expo-speech';

export default class App extends React.Component {
  speak() {
    var thingToSay = '0';
    Speech.speak(thingToSay);
  }

  render() {
    return (
      <View style={styles.container}>
        <Button title="Press to hear some words" onPress={this.speak} />
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    paddingTop: Constants.statusBarHeight,
    backgroundColor: '#ecf0f1',
    padding: 8,
  },
  paragraph: {
    margin: 24,
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
  },
});
```
</SnackInline>

## API

```js
import * as Speech from 'expo-speech';
```

### `Speech.speak(text, options)`

Speak out loud the `text` given `options`. Calling this when another text is being spoken adds an utterance to queue.

#### Arguments

- **text (_string_)** -- The text to be spoken.
- **options (_object_)** --

  A map of options:

  - **voice (_string_)** -- Voice identifier (**iOS only**)
  - **language (_string_)** -- The code of a language that should be used to read the `text`, check out IETF BCP 47 to see valid codes.
  - **pitch (_number_)** -- Pitch of the voice to speak `text`. 1.0 is the normal pitch.
  - **rate (_number_)** -- Rate of the voice to speak `text`. 1.0 is the normal rate.
  - **onStart (_function_)** -- A callback that is invoked when speaking starts.
  - **onDone (_function_)** -- A callback that is invoked when speaking finishes.
  - **onStopped (_function_)** -- A callback that is invoked when speaking is stopped by calling `Speech.stop()`.
  - **onError (_function_)** -- (Android only). A callback that is invoked when an error occurred while speaking.

### `Speech.stop()`

Interrupts current speech and deletes all in queue.

### `Speech.pause()`

Pauses current speech.

### `Speech.resume()`

Resumes speaking previously paused speech or does nothing if there's none.

### `Speech.isSpeakingAsync()`

Determine whether the Text-to-speech utility is currently speaking. Will return `true` if speaker is paused.

#### Returns

Returns a Promise that resolves to a boolean, `true` if speaking, `false` if not.

### `Speech.getAvailableVoicesAsync()` (iOS only)

Returns list of all available voices.

#### Returns

List of `Voice` objects.

##### `Voice`

|   Field    |           Type           |
| :--------: | :----------------------: |
| identifier |          string          |
|    name    |          string          |
|  quality   | enum Speech.VoiceQuality |
|  language  |          string          |

##### enum `Speech.VoiceQuality`

possible values: `Default` or `Enhanced`.
