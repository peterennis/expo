package expo.modules.notifications.notifications.presentation;

import android.content.Context;
import android.os.Bundle;
import android.os.ResultReceiver;

import org.json.JSONObject;
import org.unimodules.core.ExportedModule;
import org.unimodules.core.Promise;
import org.unimodules.core.interfaces.ExpoMethod;

import java.util.Map;

import expo.modules.notifications.notifications.service.BaseNotificationsService;

public class ExpoNotificationPresentationModule extends ExportedModule {
  private static final String EXPORTED_NAME = "ExpoNotificationPresenter";

  public ExpoNotificationPresentationModule(Context context) {
    super(context);
  }

  @Override
  public String getName() {
    return EXPORTED_NAME;
  }

  @ExpoMethod
  public void presentNotificationAsync(String identifier, Map notificationSpec, final Promise promise) {
    JSONObject notificationRequest = new JSONObject(notificationSpec);
    BaseNotificationsService.enqueuePresent(getContext(), identifier, notificationRequest, null, new ResultReceiver(null) {
      @Override
      protected void onReceiveResult(int resultCode, Bundle resultData) {
        super.onReceiveResult(resultCode, resultData);
        if (resultCode == BaseNotificationsService.SUCCESS_CODE) {
          promise.resolve(null);
        } else {
          Exception e = resultData.getParcelable(BaseNotificationsService.EXCEPTION_KEY);
          promise.reject("ERR_NOTIFICATION_PRESENTATION_FAILED", "Notification could not be presented.", e);
        }
      }
    });
  }
}
