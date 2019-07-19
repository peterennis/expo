package host.exp.exponent.notifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import java.util.HashMap;

import javax.inject.Inject;

import android.os.Bundle;
import host.exp.exponent.ExponentManifest;
import host.exp.exponent.di.NativeModuleDepsProvider;
import host.exp.exponent.kernel.KernelConstants;
import host.exp.exponent.notifications.helpers.Utils;
import host.exp.exponent.notifications.presenters.NotificationPresenterProvider;

public class ScheduledNotificationReceiver extends BroadcastReceiver {

  @Inject
  ExponentManifest mExponentManifest;

  public ScheduledNotificationReceiver() {
    NativeModuleDepsProvider.getInstance().inject(ScheduledNotificationReceiver.class, this);
  }

  public void onReceive(Context context, Intent intent) {
    Bundle bundle = intent.getExtras();
    HashMap details = (HashMap) bundle.getSerializable(KernelConstants.NOTIFICATION_OBJECT_KEY);
    int notificationId = bundle.getInt(KernelConstants.NOTIFICATION_ID_KEY, 0);

    Bundle notification = Utils.convertMapToBundle(details).getBundle("data");

    NotificationPresenterProvider.getNotificationPresenter().presentNotification(
        context.getApplicationContext(),
        notification.getString("experienceId"),
        notification,
        notificationId
    );
  }
}

