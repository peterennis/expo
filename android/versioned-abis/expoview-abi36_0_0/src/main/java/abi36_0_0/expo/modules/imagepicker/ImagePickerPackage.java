package abi36_0_0.expo.modules.imagepicker;

import android.content.Context;

import abi36_0_0.org.unimodules.core.BasePackage;
import abi36_0_0.org.unimodules.core.ExportedModule;

import java.util.Collections;
import java.util.List;

public class ImagePickerPackage extends BasePackage {
  @Override
  public List<ExportedModule> createExportedModules(Context context) {
    return Collections.singletonList((ExportedModule) new ImagePickerModule(context));
  }
}
