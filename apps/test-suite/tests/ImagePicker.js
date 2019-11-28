import { Platform } from 'react-native';
import Constants from 'expo-constants';
import * as ImagePicker from 'expo-image-picker';
import * as Permissions from 'expo-permissions';

import * as TestUtils from '../TestUtils';
import { isDeviceFarm } from '../utils/Environment';

export const name = 'ImagePicker';

export async function test({ it, xit, beforeAll, expect, jasmine, xdescribe, describe, afterAll }) {
  function testMediaObjectShape(shape, type) {
    expect(shape).toBeDefined();
    expect(typeof shape.cancelled).toBe('boolean');

    if (!shape.cancelled) {
      expect(typeof shape.uri).toBe('string');
      expect(typeof shape.width).toBe('number');
      expect(typeof shape.height).toBe('number');
      expect(typeof shape.type).toBe('string');

      expect(shape.uri).not.toBe('');
      expect(shape.width).toBeGreaterThan(0);
      expect(shape.height).toBeGreaterThan(0);

      expect(typeof shape.type).toBe('string');
      expect(shape.type).toBe(type);

      if (shape.type === 'video') {
        expect(typeof shape.duration).toBe('number');
        expect(shape.duration).toBeGreaterThan(0);
      }
    }
  }

  describe(name, () => {
    if (isDeviceFarm()) return;

    let originalTimeout;

    beforeAll(async () => {
      await Permissions.askAsync(Permissions.CAMERA_ROLL);
      await Permissions.askAsync(Permissions.CAMERA);

      await TestUtils.acceptPermissionsAndRunCommandAsync(() => {
        return Permissions.askAsync(Permissions.CAMERA_ROLL);
      });
      originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL;
      jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout * 10;
    });

    if (Constants.isDevice) {
      it('launches the camera', async () => {
        const { cancelled } = await ImagePicker.launchCameraAsync();
        expect(cancelled).toBe(true);
      });
    } else {
      it('natively prevents the camera from launching on a simulator', async () => {
        let err;
        try {
          await ImagePicker.launchCameraAsync();
        } catch ({ code }) {
          err = code;
        }
        expect(err).toBe('CAMERA_MISSING');
      });
    }

    describe('launchImageLibraryAsync', async () => {
      it('mediaType: image', async () => {
        const image = await ImagePicker.launchImageLibraryAsync({
          mediaTypes: ImagePicker.MediaTypeOptions.Images,
        });

        testMediaObjectShape(image, 'image');
      });

      it('mediaType: video', async () => {
        const video = await ImagePicker.launchImageLibraryAsync({
          mediaTypes: ImagePicker.MediaTypeOptions.Videos,
        });

        testMediaObjectShape(video, 'video');
      });

      it('allows editing', async () => {
        const image = await ImagePicker.launchImageLibraryAsync({
          mediaTypes: ImagePicker.MediaTypeOptions.Images,
          allowsEditing: true,
        });

        testMediaObjectShape(image, 'image');
      });

      it('allows editing and returns base64', async () => {
        const image = await ImagePicker.launchImageLibraryAsync({
          mediaTypes: ImagePicker.MediaTypeOptions.Images,
          allowsEditing: true,
          base64: true,
        });

        testMediaObjectShape(image, 'image');
        if (!image.cancelled) {
          expect(typeof image.base64).toBe('string');
          expect(image.base64).not.toBe('');
        }
      });

      if (Platform.OS === 'ios' && parseInt(Platform.Version, 10) > 10) {
        it('exporPreset should affect video dimensions', async () => {
          const video = await ImagePicker.launchImageLibraryAsync({
            mediaTypes: ImagePicker.MediaTypeOptions.Videos,
            videoExportPreset: ImagePicker.VideoExportPreset.H264_640x480,
          });

          testMediaObjectShape(video, 'video');

          if (!video.cancelled) {
            expect(video.width).toBeLessThanOrEqual(640);
            expect(video.height).toBeLessThanOrEqual(480);
          }
        });
      }
    });

    afterAll(() => {
      jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout;
    });
  });
}
