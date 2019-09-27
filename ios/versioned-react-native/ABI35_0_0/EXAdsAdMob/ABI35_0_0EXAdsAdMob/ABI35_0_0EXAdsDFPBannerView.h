#import <ABI35_0_0UMCore/ABI35_0_0UMDefines.h>
#import <ABI35_0_0UMCore/ABI35_0_0UMModuleRegistry.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ABI35_0_0EXAdsDFPBannerView : UIView <GADBannerViewDelegate, GADAppEventDelegate>

@property (nonatomic, copy) NSString *bannerSize;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, copy) NSString *testDeviceID;
@property (nonatomic, copy) NSDictionary *additionalRequestParams;

@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onSizeChange;
@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onAdmobDispatchAppEvent;
@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onAdViewDidReceiveAd;
@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onDidFailToReceiveAdWithError;
@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onAdViewWillPresentScreen;
@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onAdViewWillDismissScreen;
@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onAdViewDidDismissScreen;
@property (nonatomic, copy) ABI35_0_0UMDirectEventBlock onAdViewWillLeaveApplication;

- (GADAdSize)getAdSizeFromString:(NSString *)bannerSize;
- (void)loadBanner;

@end
