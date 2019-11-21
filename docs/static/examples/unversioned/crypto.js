import React, { useEffect } from 'react';
import { View, Text } from 'react-native';
import * as Crypto from 'expo-crypto';

export default function App() {
  useEffect(() => {
    runCrypto();
  }, []);

  const runCrypto = async () => {
    const digest = await Crypto.digestStringAsync(
      Crypto.CryptoDigestAlgorithm.SHA256,
      'Github stars are neat 🌟'
    );
    console.log('Digest: ', digest);
    /* Some crypto operation... */
  };

  return (
    <View
      style={{
        flex: 1,
        backgroundColor: '#fff',
        alignItems: 'center',
        justifyContent: 'center',
      }}>
      <Text>Crypto Module Example</Text>
    </View>
  );
}
