package abi35_0_0.host.exp.exponent.modules.universal.sensors;

import java.util.Collections;
import java.util.List;

import abi35_0_0.org.unimodules.core.interfaces.InternalModule;
import abi35_0_0.org.unimodules.interfaces.sensors.services.MagnetometerService;
import host.exp.exponent.kernel.ExperienceId;
import host.exp.exponent.kernel.services.sensors.SubscribableSensorKernelService;

public class ScopedMagnetometerService extends BaseSensorService implements InternalModule, MagnetometerService {
  public ScopedMagnetometerService(ExperienceId experienceId) {
    super(experienceId);
  }

  @Override
  protected SubscribableSensorKernelService getSensorKernelService() {
    return getKernelServiceRegistry().getMagnetometerKernelService();
  }

  @Override
  public List<Class> getExportedInterfaces() {
    return Collections.<Class>singletonList(MagnetometerService.class);
  }
}

