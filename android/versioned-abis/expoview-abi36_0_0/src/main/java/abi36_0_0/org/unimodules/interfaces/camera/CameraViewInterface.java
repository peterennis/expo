package abi36_0_0.org.unimodules.interfaces.camera;

import android.graphics.SurfaceTexture;

public interface CameraViewInterface {
  void setPreviewTexture(SurfaceTexture surfaceTexture);
  int[] getPreviewSizeAsArray();
}
