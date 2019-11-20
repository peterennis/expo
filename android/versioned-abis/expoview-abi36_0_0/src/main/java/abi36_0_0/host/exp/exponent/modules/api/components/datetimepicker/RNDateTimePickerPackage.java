package abi36_0_0.host.exp.exponent.modules.api.components.datetimepicker;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import abi36_0_0.com.facebook.react.ReactPackage;
import abi36_0_0.com.facebook.react.bridge.NativeModule;
import abi36_0_0.com.facebook.react.bridge.ReactApplicationContext;
import abi36_0_0.com.facebook.react.uimanager.ViewManager;

public class RNDateTimePickerPackage implements ReactPackage {
    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
      return Arrays.<NativeModule>asList(
        new RNDatePickerDialogModule(reactContext),
        new RNTimePickerDialogModule(reactContext)
      );
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
      return Collections.emptyList();
    }
}
