package abi35_0_0.expo.modules.sqlite;

import android.content.Context;

import java.util.Collections;
import java.util.List;

import abi35_0_0.org.unimodules.core.BasePackage;
import abi35_0_0.org.unimodules.core.ExportedModule;

public class SQLitePackage extends BasePackage {
  @Override
  public List<ExportedModule> createExportedModules(Context context) {
    return Collections.singletonList((ExportedModule) new SQLiteModule(context));
  }
}
