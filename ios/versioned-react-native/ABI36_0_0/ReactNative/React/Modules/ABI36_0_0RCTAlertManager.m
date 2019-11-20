/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI36_0_0RCTAlertManager.h"

#import "ABI36_0_0RCTAssert.h"
#import "ABI36_0_0RCTConvert.h"
#import "ABI36_0_0RCTLog.h"
#import "ABI36_0_0RCTUtils.h"

@implementation ABI36_0_0RCTConvert (UIAlertViewStyle)

ABI36_0_0RCT_ENUM_CONVERTER(ABI36_0_0RCTAlertViewStyle, (@{
  @"default": @(ABI36_0_0RCTAlertViewStyleDefault),
  @"secure-text": @(ABI36_0_0RCTAlertViewStyleSecureTextInput),
  @"plain-text": @(ABI36_0_0RCTAlertViewStylePlainTextInput),
  @"login-password": @(ABI36_0_0RCTAlertViewStyleLoginAndPasswordInput),
}), ABI36_0_0RCTAlertViewStyleDefault, integerValue)

@end

@interface ABI36_0_0RCTAlertManager()

@end

@implementation ABI36_0_0RCTAlertManager
{
  NSHashTable *_alertControllers;
}

ABI36_0_0RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)invalidate
{
  for (UIAlertController *alertController in _alertControllers) {
    [alertController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  }
}

/**
 * @param {NSDictionary} args Dictionary of the form
 *
 *   @{
 *     @"message": @"<Alert message>",
 *     @"buttons": @[
 *       @{@"<key1>": @"<title1>"},
 *       @{@"<key2>": @"<title2>"},
 *     ],
 *     @"cancelButtonKey": @"<key2>",
 *   }
 * The key from the `buttons` dictionary is passed back in the callback on click.
 * Buttons are displayed in the order they are specified.
 */
ABI36_0_0RCT_EXPORT_METHOD(alertWithArgs:(NSDictionary *)args
                  callback:(ABI36_0_0RCTResponseSenderBlock)callback)
{
  NSString *title = [ABI36_0_0RCTConvert NSString:args[@"title"]];
  NSString *message = [ABI36_0_0RCTConvert NSString:args[@"message"]];
  ABI36_0_0RCTAlertViewStyle type = [ABI36_0_0RCTConvert ABI36_0_0RCTAlertViewStyle:args[@"type"]];
  NSArray<NSDictionary *> *buttons = [ABI36_0_0RCTConvert NSDictionaryArray:args[@"buttons"]];
  NSString *defaultValue = [ABI36_0_0RCTConvert NSString:args[@"defaultValue"]];
  NSString *cancelButtonKey = [ABI36_0_0RCTConvert NSString:args[@"cancelButtonKey"]];
  NSString *destructiveButtonKey = [ABI36_0_0RCTConvert NSString:args[@"destructiveButtonKey"]];
  UIKeyboardType keyboardType = [ABI36_0_0RCTConvert UIKeyboardType:args[@"keyboardType"]];

  if (!title && !message) {
    ABI36_0_0RCTLogError(@"Must specify either an alert title, or message, or both");
    return;
  }

  if (buttons.count == 0) {
    if (type == ABI36_0_0RCTAlertViewStyleDefault) {
      buttons = @[@{@"0": ABI36_0_0RCTUIKitLocalizedString(@"OK")}];
      cancelButtonKey = @"0";
    } else {
      buttons = @[
        @{@"0": ABI36_0_0RCTUIKitLocalizedString(@"OK")},
        @{@"1": ABI36_0_0RCTUIKitLocalizedString(@"Cancel")},
      ];
      cancelButtonKey = @"1";
    }
  }

  UIViewController *presentingController = ABI36_0_0RCTPresentedViewController();
  if (presentingController == nil) {
    ABI36_0_0RCTLogError(@"Tried to display alert view but there is no application window. args: %@", args);
    return;
  }

  UIAlertController *alertController = [UIAlertController
                                        alertControllerWithTitle:title
                                        message:nil
                                        preferredStyle:UIAlertControllerStyleAlert];
  switch (type) {
    case ABI36_0_0RCTAlertViewStylePlainTextInput: {
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = NO;
        textField.text = defaultValue;
        textField.keyboardType = keyboardType;
      }];
      break;
    }
    case ABI36_0_0RCTAlertViewStyleSecureTextInput: {
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = ABI36_0_0RCTUIKitLocalizedString(@"Password");
        textField.secureTextEntry = YES;
        textField.text = defaultValue;
        textField.keyboardType = keyboardType;
      }];
      break;
    }
    case ABI36_0_0RCTAlertViewStyleLoginAndPasswordInput: {
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = ABI36_0_0RCTUIKitLocalizedString(@"Login");
        textField.text = defaultValue;
        textField.keyboardType = keyboardType;
      }];
      [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = ABI36_0_0RCTUIKitLocalizedString(@"Password");
        textField.secureTextEntry = YES;
      }];
      break;
    }
    case ABI36_0_0RCTAlertViewStyleDefault:
      break;
  }

  alertController.message = message;

  for (NSDictionary<NSString *, id> *button in buttons) {
    if (button.count != 1) {
      ABI36_0_0RCTLogError(@"Button definitions should have exactly one key.");
    }
    NSString *buttonKey = button.allKeys.firstObject;
    NSString *buttonTitle = [ABI36_0_0RCTConvert NSString:button[buttonKey]];
    UIAlertActionStyle buttonStyle = UIAlertActionStyleDefault;
    if ([buttonKey isEqualToString:cancelButtonKey]) {
      buttonStyle = UIAlertActionStyleCancel;
    } else if ([buttonKey isEqualToString:destructiveButtonKey]) {
      buttonStyle = UIAlertActionStyleDestructive;
    }
    __weak UIAlertController *weakAlertController = alertController;
    [alertController addAction:[UIAlertAction actionWithTitle:buttonTitle
                                                        style:buttonStyle
                                                      handler:^(__unused UIAlertAction *action) {
      switch (type) {
        case ABI36_0_0RCTAlertViewStylePlainTextInput:
        case ABI36_0_0RCTAlertViewStyleSecureTextInput:
          callback(@[buttonKey, [weakAlertController.textFields.firstObject text]]);
          break;
        case ABI36_0_0RCTAlertViewStyleLoginAndPasswordInput: {
          NSDictionary<NSString *, NSString *> *loginCredentials = @{
            @"login": [weakAlertController.textFields.firstObject text],
            @"password": [weakAlertController.textFields.lastObject text]
          };
          callback(@[buttonKey, loginCredentials]);
          break;
        }
        case ABI36_0_0RCTAlertViewStyleDefault:
          callback(@[buttonKey]);
          break;
      }
    }]];
  }

  if (!_alertControllers) {
    _alertControllers = [NSHashTable weakObjectsHashTable];
  }
  [_alertControllers addObject:alertController];

  dispatch_async(dispatch_get_main_queue(), ^{
    [presentingController presentViewController:alertController animated:YES completion:nil];
  });
}

@end
