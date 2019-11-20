// Copyright 2015-present 650 Industries. All rights reserved.

#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import <ABI36_0_0EXMediaLibrary/ABI36_0_0EXMediaLibrary.h>
#import <ABI36_0_0EXMediaLibrary/ABI36_0_0EXSaveToLibraryDelegate.h>
#import <ABI36_0_0EXMediaLibrary/ABI36_0_0EXMediaLibraryCameraRollRequester.h>

#import <ABI36_0_0UMCore/ABI36_0_0UMDefines.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMUtilities.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMEventEmitterService.h>

#import <ABI36_0_0UMFileSystemInterface/ABI36_0_0UMFileSystemInterface.h>

#import <ABI36_0_0UMPermissionsInterface/ABI36_0_0UMPermissionsInterface.h>
#import <ABI36_0_0UMPermissionsInterface/ABI36_0_0UMPermissionsMethodsDelegate.h>

NSString *const ABI36_0_0EXAssetMediaTypeAudio = @"audio";
NSString *const ABI36_0_0EXAssetMediaTypePhoto = @"photo";
NSString *const ABI36_0_0EXAssetMediaTypeVideo = @"video";
NSString *const ABI36_0_0EXAssetMediaTypeUnknown = @"unknown";
NSString *const ABI36_0_0EXAssetMediaTypeAll = @"all";

NSString *const ABI36_0_0EXMediaLibraryDidChangeEvent = @"mediaLibraryDidChange";

@interface ABI36_0_0EXMediaLibrary ()

@property (nonatomic, strong) PHFetchResult *allAssetsFetchResult;
@property (nonatomic, weak) id<ABI36_0_0UMPermissionsInterface> permissionsManager;
@property (nonatomic, weak) id<ABI36_0_0UMFileSystemInterface> fileSystem;
@property (nonatomic, weak) id<ABI36_0_0UMEventEmitterService> eventEmitter;
@property (nonatomic, strong) NSMutableSet *saveToLibraryDelegates;

@end

@implementation ABI36_0_0EXMediaLibrary

ABI36_0_0UM_EXPORT_MODULE(ExponentMediaLibrary);

- (instancetype) init
{
  if (self = [super init]) {
    _saveToLibraryDelegates = [NSMutableSet new];
  }
  return self;
}

- (void)setModuleRegistry:(ABI36_0_0UMModuleRegistry *)moduleRegistry
{
  _fileSystem = [moduleRegistry getModuleImplementingProtocol:@protocol(ABI36_0_0UMFileSystemInterface)];
  _eventEmitter = [moduleRegistry getModuleImplementingProtocol:@protocol(ABI36_0_0UMEventEmitterService)];
  _permissionsManager = [moduleRegistry getModuleImplementingProtocol:@protocol(ABI36_0_0UMPermissionsInterface)];
  [ABI36_0_0UMPermissionsMethodsDelegate registerRequesters:@[[ABI36_0_0EXMediaLibraryCameraRollRequester new]] withPermissionsManager:_permissionsManager];
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_queue_create("host.exp.exponent.MediaLibrary", DISPATCH_QUEUE_SERIAL);
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (NSDictionary *)constantsToExport
{
  return @{
           @"MediaType": @{
               @"audio": ABI36_0_0EXAssetMediaTypeAudio,
               @"photo": ABI36_0_0EXAssetMediaTypePhoto,
               @"video": ABI36_0_0EXAssetMediaTypeVideo,
               @"unknown": ABI36_0_0EXAssetMediaTypeUnknown,
               @"all": ABI36_0_0EXAssetMediaTypeAll,
               },
           @"SortBy": @{
               @"default": @"default",
               @"creationTime": @"creationTime",
               @"modificationTime": @"modificationTime",
               @"mediaType": @"mediaType",
               @"width": @"width",
               @"height": @"height",
               @"duration": @"duration",
               },
           @"CHANGE_LISTENER_NAME": ABI36_0_0EXMediaLibraryDidChangeEvent,
           };
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[ABI36_0_0EXMediaLibraryDidChangeEvent];
}

ABI36_0_0UM_EXPORT_METHOD_AS(getPermissionsAsync,
                    getPermissionsAsync:(ABI36_0_0UMPromiseResolveBlock)resolve
                    rejecter:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  [ABI36_0_0UMPermissionsMethodsDelegate getPermissionWithPermissionsManager:_permissionsManager
                                                      withRequester:[ABI36_0_0EXMediaLibraryCameraRollRequester class]
                                                            resolve:resolve
                                                             reject:reject];
}

ABI36_0_0UM_EXPORT_METHOD_AS(requestPermissionsAsync,
                    requestPermissionsAsync:(ABI36_0_0UMPromiseResolveBlock)resolve
                    rejecter:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  [ABI36_0_0UMPermissionsMethodsDelegate askForPermissionWithPermissionsManager:_permissionsManager
                                                         withRequester:[ABI36_0_0EXMediaLibraryCameraRollRequester class]
                                                               resolve:resolve
                                                                reject:reject];
}

ABI36_0_0UM_EXPORT_METHOD_AS(createAssetAsync,
                    createAssetFromLocalUri:(nonnull NSString *)localUri
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  PHAssetMediaType assetType = [ABI36_0_0EXMediaLibrary _assetTypeForUri:localUri];
  
  if (assetType == PHAssetMediaTypeUnknown || assetType == PHAssetMediaTypeAudio) {
    reject(@"E_UNSUPPORTED_ASSET", @"This file type is not supported yet", nil);
    return;
  }
  
  NSURL *assetUrl = [self.class _normalizeAssetURLFromUri:localUri];
  
  if (assetUrl == nil) {
    reject(@"E_INVALID_URI", @"Provided localUri is not a valid URI", nil);
    return;
  }
  if (!([_fileSystem permissionsForURI:assetUrl] & ABI36_0_0UMFileSystemPermissionRead)) {
    reject(@"E_FILESYSTEM_PERMISSIONS", [NSString stringWithFormat:@"File '%@' isn't readable.", assetUrl], nil);
    return;
  }
  
  __block PHObjectPlaceholder *assetPlaceholder;
  
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetChangeRequest *changeRequest = assetType == PHAssetMediaTypeVideo
                                        ? [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:assetUrl]
                                        : [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:assetUrl];
    
    assetPlaceholder = changeRequest.placeholderForCreatedAsset;
    
  } completionHandler:^(BOOL success, NSError *error) {
    if (success) {
      PHAsset *asset = [ABI36_0_0EXMediaLibrary _getAssetById:assetPlaceholder.localIdentifier];
      resolve([ABI36_0_0EXMediaLibrary _exportAsset:asset]);
    } else {
      reject(@"E_ASSET_SAVE_FAILED", @"Asset couldn't be saved to photo library", error);
    }
  }];
}

ABI36_0_0UM_EXPORT_METHOD_AS(saveToLibraryAsync,
                    saveToLibraryAsync:(nonnull NSString *)localUri
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPhotoLibraryAddUsageDescription"] == nil) {
    return reject(@"E_NO_PERMISSIONS", @"This app is missing NSPhotoLibraryAddUsageDescription. Add this entry to your bundle's Info.plist.", nil);
  }
  PHAssetMediaType assetType = [ABI36_0_0EXMediaLibrary _assetTypeForUri:localUri];
  NSURL *assetUrl = [self.class _normalizeAssetURLFromUri:localUri];
  ABI36_0_0UM_WEAKIFY(self)
  __block ABI36_0_0EXSaveToLibraryDelegate *delegate = [ABI36_0_0EXSaveToLibraryDelegate new];
  [_saveToLibraryDelegates addObject:delegate];
  ABI36_0_0EXSaveToLibraryCallback callback = ^(id asset, NSError *error){
    ABI36_0_0UM_STRONGIFY(self)
    [self.saveToLibraryDelegates removeObject:delegate];
    if (error) {
      return reject(@"E_SAVE_FAILED", [error localizedDescription], nil);
    }
    return resolve(nil);
  };
  
  if (assetType == PHAssetMediaTypeImage) {
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:assetUrl]];
    if (image == nil) {
      return reject(@"E_FILE_IS_MISSING", [NSString stringWithFormat:@"Couldn't open file: %@. Make sure if this file exists.", localUri], nil);
    }
    return [delegate writeImage:image withCallback:callback];
  } else if (assetType == PHAssetMediaTypeVideo) {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([assetUrl path])) {
      return [delegate writeVideo:[assetUrl path] withCallback:callback];
    }
    return reject(@"E_COULD_NOT_SAVE_VIDEO", @"This video couldn't be saved to the Camera Roll album.", nil);
  }
  
  return reject(@"E_UNSUPPORTED_ASSET", @"This file type is not supported yet.", nil);
}

ABI36_0_0UM_EXPORT_METHOD_AS(addAssetsToAlbumAsync,
                    addAssets:(NSArray<NSString *> *)assetIds
                    toAlbum:(nonnull NSString *)albumId
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  [ABI36_0_0EXMediaLibrary _addAssets:assetIds toAlbum:albumId withCallback:^(BOOL success, NSError *error) {
    if (error) {
      reject(@"E_ADD_TO_ALBUM_FAILED", @"Couldn\'t add assets to album", error);
    } else {
      resolve(@(success));
    }
  }];
}

ABI36_0_0UM_EXPORT_METHOD_AS(removeAssetsFromAlbumAsync,
                    removeAssets:(NSArray<NSString *> *)assetIds
                    fromAlbum:(nonnull NSString *)albumId
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetCollection *collection = [ABI36_0_0EXMediaLibrary _getAlbumById:albumId];
    PHFetchResult *assets = [ABI36_0_0EXMediaLibrary _getAssetsByIds:assetIds];
    
    PHFetchResult *collectionAssets = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection assets:collectionAssets];
    
    [albumChangeRequest removeAssets:assets];
    
  } completionHandler:^(BOOL success, NSError *error) {
    if (error) {
      reject(@"E_REMOVE_FROM_ALBUM_FAILED", @"Couldn\'t remove assets from album", error);
    } else {
      resolve(@(success));
    }
  }];
}

ABI36_0_0UM_EXPORT_METHOD_AS(deleteAssetsAsync,
                    deleteAssets:(NSArray<NSString *>*)assetIds
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHFetchResult *fetched = [PHAsset fetchAssetsWithLocalIdentifiers:assetIds options:nil];
    [PHAssetChangeRequest deleteAssets:fetched];
    
  } completionHandler:^(BOOL success, NSError *error) {
    if (success == YES) {
      resolve(@(success));
    } else {
      reject(@"E_ASSET_REMOVE_FAILED", @"Couldn't remove assets", error);
    }
  }];
}

ABI36_0_0UM_EXPORT_METHOD_AS(getAlbumsAsync,
                    getAlbumsWithOptions:(NSDictionary *)options
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }

  NSMutableArray<NSDictionary *> *albums = [NSMutableArray new];
  
  PHFetchOptions *fetchOptions = [PHFetchOptions new];
  fetchOptions.includeHiddenAssets = NO;
  fetchOptions.includeAllBurstAssets = NO;
  
  PHFetchResult *userAlbumsFetchResult = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:fetchOptions];
  [albums addObjectsFromArray:[ABI36_0_0EXMediaLibrary _exportCollections:userAlbumsFetchResult withFetchOptions:fetchOptions inFolder:nil]];

  if ([options[@"includeSmartAlbums"] boolValue]) {
    PHFetchResult<PHAssetCollection *> *smartAlbumsFetchResult =
    [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                             subtype:PHAssetCollectionSubtypeAlbumRegular
                                             options:fetchOptions];
    [albums addObjectsFromArray:[ABI36_0_0EXMediaLibrary _exportCollections:smartAlbumsFetchResult withFetchOptions:fetchOptions inFolder:nil]];
  }
  
  resolve(albums);
}

ABI36_0_0UM_EXPORT_METHOD_AS(getMomentsAsync,
                    getMoments:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  PHFetchOptions *options = [PHFetchOptions new];
  options.includeHiddenAssets = NO;
  options.includeAllBurstAssets = NO;
  
  PHFetchResult *fetchResult = [PHAssetCollection fetchMomentsWithOptions:options];
  NSArray<NSDictionary *> *albums = [ABI36_0_0EXMediaLibrary _exportCollections:fetchResult withFetchOptions:options inFolder:nil];
  
  resolve(albums);
}

ABI36_0_0UM_EXPORT_METHOD_AS(getAlbumAsync,
                    getAlbumWithTitle:(nonnull NSString *)title
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  PHAssetCollection *collection = [ABI36_0_0EXMediaLibrary _getAlbumWithTitle:title];
  resolve(ABI36_0_0UMNullIfNil([ABI36_0_0EXMediaLibrary _exportCollection:collection]));
}

ABI36_0_0UM_EXPORT_METHOD_AS(createAlbumAsync,
                    createAlbumWithTitle:(nonnull NSString *)title
                    withAssetId:(NSString *)assetId
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  [ABI36_0_0EXMediaLibrary _createAlbumWithTitle:title completion:^(PHAssetCollection *collection, NSError *error) {
    if (collection) {
      if (assetId) {
        [ABI36_0_0EXMediaLibrary _addAssets:@[assetId] toAlbum:collection.localIdentifier withCallback:^(BOOL success, NSError *error) {
          if (success) {
            resolve(ABI36_0_0UMNullIfNil([ABI36_0_0EXMediaLibrary _exportCollection:collection]));
          } else {
            reject(@"E_ALBUM_CANT_ADD_ASSET", @"Unable to add asset to the new album", error);
          }
        }];
      } else {
        resolve(ABI36_0_0UMNullIfNil([ABI36_0_0EXMediaLibrary _exportCollection:collection]));
      }
    } else {
      reject(@"E_ALBUM_CREATE_FAILED", @"Could not create album", error);
    }
  }];
}

  
ABI36_0_0UM_EXPORT_METHOD_AS(deleteAlbumsAsync,
                    deleteAlbums:(nonnull NSArray<NSString *>*)albumIds
                    assetRemove:(NSNumber *)assetRemove
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{

  PHFetchResult *collections = [ABI36_0_0EXMediaLibrary _getAlbumsById:albumIds];
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    if (assetRemove) {
      for (PHAssetCollection *collection in collections) {
        PHFetchResult *fetch = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        [PHAssetChangeRequest deleteAssets:fetch];
      }
    }
    [PHAssetCollectionChangeRequest deleteAssetCollections:collections];
  } completionHandler:^(BOOL success, NSError * _Nullable error) {
    if (success == YES) {
      resolve(@(success));
    } else {
      reject(@"E_ALBUM_DELETE_FAILED", @"Could not delete album", error);
    }
  }];
}
  
ABI36_0_0UM_EXPORT_METHOD_AS(getAssetInfoAsync,
                    getAssetInfo:(nonnull NSString *)assetId
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  PHAsset *asset = [ABI36_0_0EXMediaLibrary _getAssetById:assetId];
  
  if (asset) {
    NSMutableDictionary *result = [ABI36_0_0EXMediaLibrary _exportAssetInfo:asset];
    if (asset.mediaType == PHAssetMediaTypeImage) {
      PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
      options.networkAccessAllowed = YES;

      [asset requestContentEditingInputWithOptions:options
                                 completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
        result[@"localUri"] = [contentEditingInput.fullSizeImageURL absoluteString];
        result[@"orientation"] = @(contentEditingInput.fullSizeImageOrientation);
        
        CIImage *ciImage = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
        result[@"exif"] = ciImage.properties;
        resolve(result);
      }];
    } else {
      PHVideoRequestOptions *options = [PHVideoRequestOptions new];
      options.networkAccessAllowed = YES;

      [[PHImageManager defaultManager] requestAVAssetForVideo:asset
                                                      options:options
                                                resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        AVURLAsset *urlAsset = (AVURLAsset *)asset;
        result[@"localUri"] = [[urlAsset URL] absoluteString];
        resolve(result);
      }];
    }
  } else {
    resolve([NSNull null]);
  }
}

ABI36_0_0UM_EXPORT_METHOD_AS(getAssetsAsync,
                    getAssetsWithOptions:(NSDictionary *)options
                    resolve:(ABI36_0_0UMPromiseResolveBlock)resolve
                    reject:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (![self _checkPermissions:reject]) {
    return;
  }
  
  PHFetchOptions *fetchOptions = [PHFetchOptions new];
  NSMutableArray<NSPredicate *> *predicates = [NSMutableArray new];
  NSMutableDictionary *response = [NSMutableDictionary new];
  NSMutableArray<NSDictionary *> *assets = [NSMutableArray new];
  
  // options
  NSString *after = options[@"after"];
  NSInteger first = [options[@"first"] integerValue] ?: 20;
  NSArray<NSString *> *mediaType = options[@"mediaType"];
  NSArray *sortBy = options[@"sortBy"];
  NSString *albumId = options[@"album"];
  NSDate *createdAfter = [ABI36_0_0UMUtilities NSDate:options[@"createdAfter"]];
  NSDate *createdBefore = [ABI36_0_0UMUtilities NSDate:options[@"createdBefore"]];
  
  PHAssetCollection *collection;
  PHAsset *cursor;
  
  if (after) {
    cursor = [ABI36_0_0EXMediaLibrary _getAssetById:after];
    
    if (!cursor) {
      reject(@"E_CURSOR_NOT_FOUND", @"Couldn't find cursor", nil);
      return;
    }
  }
  
  if (albumId) {
    collection = [ABI36_0_0EXMediaLibrary _getAlbumById:albumId];
    
    if (!collection) {
      reject(@"E_ALBUM_NOT_FOUND", @"Couldn't find album", nil);
      return;
    }
  }
  
  if (mediaType && [mediaType count] > 0) {
    NSMutableArray<NSNumber *> *assetTypes = [ABI36_0_0EXMediaLibrary _convertMediaTypes:mediaType];
    
    if ([assetTypes count] > 0) {
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", assetTypes];
      [predicates addObject:predicate];
    }
  }
  
  if (sortBy && sortBy.count > 0) {
    fetchOptions.sortDescriptors = [ABI36_0_0EXMediaLibrary _prepareSortDescriptors:sortBy];
  }

  if (createdAfter) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creationDate > %@", createdAfter];
    [predicates addObject:predicate];
  }

  if (createdBefore) {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creationDate < %@", createdBefore];
    [predicates addObject:predicate];
  }
  
  if (predicates.count > 0) {
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    fetchOptions.predicate = compoundPredicate;
  }
  
  fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
  fetchOptions.includeAllBurstAssets = NO;
  fetchOptions.includeHiddenAssets = NO;
  
  PHFetchResult *fetchResult = collection
    ? [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions]
    : [PHAsset fetchAssetsWithOptions:fetchOptions];
  
  NSInteger cursorIndex = cursor ? [fetchResult indexOfObject:cursor] : NSNotFound;
  NSInteger totalCount = fetchResult.count;
  BOOL hasNextPage;
  
  // If we don't use any sort descriptors, the assets are sorted just like in Photos app.
  // That means they are in the insertion order, so the most recent assets are at the end.
  // Therefore, we need to reverse indexes to place them at the beginning.
  if (fetchOptions.sortDescriptors.count == 0) {
    NSInteger startIndex = MAX(cursorIndex == NSNotFound ? totalCount - 1 : cursorIndex - 1, -1);
    NSInteger endIndex = MAX(startIndex - first + 1, 0);
    
    for (NSInteger i = startIndex; i >= endIndex; i--) {
      PHAsset *asset = [fetchResult objectAtIndex:i];
      [assets addObject:[ABI36_0_0EXMediaLibrary _exportAsset:asset]];
    }
    
    hasNextPage = endIndex > 0;
  } else {
    NSInteger startIndex = cursorIndex == NSNotFound ? 0 : cursorIndex + 1;
    NSInteger endIndex = MIN(startIndex + first, totalCount);
    
    for (NSInteger i = startIndex; i < endIndex; i++) {
      PHAsset *asset = [fetchResult objectAtIndex:i];
      [assets addObject:[ABI36_0_0EXMediaLibrary _exportAsset:asset]];
    }
    hasNextPage = endIndex < totalCount - 1;
  }
  
  NSDictionary *lastAsset = [assets lastObject];
  
  response[@"assets"] = assets;
  response[@"endCursor"] = lastAsset ? lastAsset[@"id"] : after;
  response[@"hasNextPage"] = @(hasNextPage);
  response[@"totalCount"] = @(totalCount);
  
  resolve(response);
}

# pragma mark - PHPhotoLibraryChangeObserver

- (void)startObserving
{
  _allAssetsFetchResult = [ABI36_0_0EXMediaLibrary _getAllAssets];
  [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)stopObserving
{
  _allAssetsFetchResult = nil;
  [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
  if (changeInstance != nil && _allAssetsFetchResult != nil) {
    PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:_allAssetsFetchResult];
    
    if (changeDetails != nil) {
      _allAssetsFetchResult = changeDetails.fetchResultAfterChanges;
      
      // PHPhotoLibraryChangeObserver is calling this method too often, so we need to filter out some calls before they are sent to JS.
      // Ultimately, we emit an event only when something has been inserted or removed from the library.
      if (changeDetails.hasIncrementalChanges && (changeDetails.insertedObjects.count > 0 || changeDetails.removedObjects.count > 0)) {
        NSMutableArray *insertedAssets = [NSMutableArray new];
        NSMutableArray *deletedAssets = [NSMutableArray new];
        NSDictionary *body = @{
                               @"insertedAssets": insertedAssets,
                               @"deletedAssets": deletedAssets,
                               };
        
        for (PHAsset *asset in changeDetails.insertedObjects) {
          [insertedAssets addObject:[ABI36_0_0EXMediaLibrary _exportAsset:asset]];
        }
        for (PHAsset *asset in changeDetails.removedObjects) {
          [deletedAssets addObject:[ABI36_0_0EXMediaLibrary _exportAsset:asset]];
        }
        
        [_eventEmitter sendEventWithName:ABI36_0_0EXMediaLibraryDidChangeEvent body:body];
      }
    }
  }
}


# pragma mark - Internal methods


+ (PHFetchResult *)_getAllAssets
{
  PHFetchOptions *options = [PHFetchOptions new];
  options.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
  options.includeHiddenAssets = NO;
  options.includeAllBurstAssets = NO;
  return [PHAsset fetchAssetsWithOptions:options];
}

+ (PHFetchResult *)_getAssetsByIds:(NSArray<NSString *> *)assetIds
{
  PHFetchOptions *options = [PHFetchOptions new];
  options.includeHiddenAssets = YES;
  options.includeAllBurstAssets = YES;
  options.fetchLimit = assetIds.count;
  return [PHAsset fetchAssetsWithLocalIdentifiers:assetIds options:options];
}

+ (PHAsset *)_getAssetById:(NSString *)assetId
{
  if (assetId) {
    return [ABI36_0_0EXMediaLibrary _getAssetsByIds:@[assetId]].firstObject;
  }
  return nil;
}

+ (PHAssetCollection *)_getAlbumWithTitle:(nonnull NSString *)title
{
  PHFetchOptions *options = [PHFetchOptions new];
  options.predicate = [NSPredicate predicateWithFormat:@"title == %@", title];
  options.fetchLimit = 1;
  
  PHFetchResult *fetchResult = [PHAssetCollection
                                fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                subtype:PHAssetCollectionSubtypeAlbumRegular
                                options:options];

  return fetchResult.firstObject;
}

+ (PHFetchResult *)_getAlbumsById:(NSArray<NSString *>*)albumIds
{
  PHFetchOptions *options = [PHFetchOptions new];
  return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:albumIds options:options];
}


+ (PHAssetCollection *)_getAlbumById:(nonnull NSString *)albumId
{
  PHFetchOptions *options = [PHFetchOptions new];
  options.fetchLimit = 1;
  return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumId] options:options].firstObject;
}

+ (void)_ensureAlbumWithTitle:(nonnull NSString *)title completion:(void(^)(PHAssetCollection *collection, NSError *error))completion
{
  PHAssetCollection *collection = [ABI36_0_0EXMediaLibrary _getAlbumWithTitle:title];
  
  if (collection) {
    completion(collection, nil);
    return;
  }
  
  [ABI36_0_0EXMediaLibrary _createAlbumWithTitle:title completion:completion];
}

+ (void)_createAlbumWithTitle:(nonnull NSString *)title completion:(void(^)(PHAssetCollection *collection, NSError *error))completion
{
  __block PHObjectPlaceholder *collectionPlaceholder;
  
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
    collectionPlaceholder = changeRequest.placeholderForCreatedAssetCollection;
    
  } completionHandler:^(BOOL success, NSError *error) {
    if (success) {
      PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionPlaceholder.localIdentifier] options:nil];
      completion(fetchResult.firstObject, nil);
    } else {
      completion(nil, error);
    }
  }];
}

+ (void)_addAssets:(NSArray<NSString *> *)assetIds toAlbum:(nonnull NSString *)albumId withCallback:(void(^)(BOOL success, NSError *error))callback
{
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetCollection *collection = [ABI36_0_0EXMediaLibrary _getAlbumById:albumId];
    PHFetchResult *assets = [ABI36_0_0EXMediaLibrary _getAssetsByIds:assetIds];
    
    PHFetchResult *collectionAssets = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection assets:collectionAssets];
    
    [albumChangeRequest addAssets:assets];
  } completionHandler:callback];
}

+ (NSDictionary *)_exportAsset:(PHAsset *)asset
{
  if (asset) {
    NSString *fileName = [asset valueForKey:@"filename"];
    NSString *assetExtension = [fileName pathExtension];
    
    return @{
             @"id": asset.localIdentifier,
             @"filename": fileName,
             @"uri": [ABI36_0_0EXMediaLibrary _assetUriForLocalId:asset.localIdentifier andExtension:assetExtension],
             @"mediaType": [ABI36_0_0EXMediaLibrary _stringifyMediaType:asset.mediaType],
             @"mediaSubtypes": [ABI36_0_0EXMediaLibrary _stringifyMediaSubtypes:asset.mediaSubtypes],
             @"width": @(asset.pixelWidth),
             @"height": @(asset.pixelHeight),
             @"creationTime": [ABI36_0_0EXMediaLibrary _exportDate:asset.creationDate],
             @"modificationTime": [ABI36_0_0EXMediaLibrary _exportDate:asset.modificationDate],
             @"duration": @(asset.duration),
             };
  }
  return nil;
}

+ (NSMutableDictionary *)_exportAssetInfo:(PHAsset *)asset
{
  NSMutableDictionary *assetDict = [[ABI36_0_0EXMediaLibrary _exportAsset:asset] mutableCopy];
  
  if (assetDict) {
    assetDict[@"location"] = [ABI36_0_0EXMediaLibrary _exportLocation:asset.location];
    assetDict[@"isFavorite"] = @(asset.isFavorite);
    assetDict[@"isHidden"] = @(asset.isHidden);
    return assetDict;
  }
  return nil;
}

+ (NSNumber *)_exportDate:(NSDate *)date
{
  if (date) {
    NSTimeInterval interval = date.timeIntervalSince1970;
    NSUInteger intervalMs = interval * 1000;
    return [NSNumber numberWithUnsignedInteger:intervalMs];
  }
  return (id)[NSNull null];
}

+ (nullable NSDictionary *)_exportCollection:(PHAssetCollection *)collection
{
  return [ABI36_0_0EXMediaLibrary _exportCollection:collection inFolder:nil];
}

+ (nullable NSDictionary *)_exportCollection:(PHAssetCollection *)collection inFolder:(nullable NSString *)folderName
{
  if (collection) {
    return @{
             @"id": [ABI36_0_0EXMediaLibrary _assetIdFromLocalId:collection.localIdentifier],
             @"title": ABI36_0_0UMNullIfNil(collection.localizedTitle),
             @"folderName": ABI36_0_0UMNullIfNil(folderName),
             @"type": [ABI36_0_0EXMediaLibrary _stringifyAlbumType:collection.assetCollectionType],
             @"assetCount": [ABI36_0_0EXMediaLibrary _assetCountOfCollection:collection],
             @"startTime": [ABI36_0_0EXMediaLibrary _exportDate:collection.startDate],
             @"endTime": [ABI36_0_0EXMediaLibrary _exportDate:collection.endDate],
             @"approximateLocation": [ABI36_0_0EXMediaLibrary _exportLocation:collection.approximateLocation],
             @"locationNames": ABI36_0_0UMNullIfNil(collection.localizedLocationNames),
             };
  }
  return nil;
}

+ (NSArray *)_exportCollections:(PHFetchResult *)collections
               withFetchOptions:(PHFetchOptions *)options
                       inFolder:(nullable NSString *)folderName
{
  NSMutableArray<NSDictionary *> *albums = [NSMutableArray new];
  for (PHCollection *collection in collections) {
    if ([collection isKindOfClass:[PHAssetCollection class]]) {
      [albums addObject:[ABI36_0_0EXMediaLibrary _exportCollection:(PHAssetCollection *)collection inFolder:folderName]];
    }  else if ([collection isKindOfClass:[PHCollectionList class]]) {
      // getting albums from folders
      PHFetchResult *collectionsInFolder = [PHCollectionList fetchCollectionsInCollectionList:(PHCollectionList *)collection options:options];
      [albums addObjectsFromArray:[ABI36_0_0EXMediaLibrary _exportCollections:collectionsInFolder withFetchOptions:options inFolder:collection.localizedTitle]];
    }
  }
  return [albums copy];
}

+ (nullable NSDictionary *)_exportLocation:(CLLocation *)location
{
  if (location) {
    return @{
             @"latitude": @(location.coordinate.latitude),
             @"longitude": @(location.coordinate.longitude),
             };
  }
  return (id)[NSNull null];
}

+ (NSString *)_assetIdFromLocalId:(nonnull NSString *)localId
{
  // PHAsset's localIdentifier looks like `8B51C35E-E1F3-4D18-BF90-22CC905737E9/L0/001`
  // however `/L0/001` doesn't take part in URL to the asset, so we need to strip it out.
  return [localId stringByReplacingOccurrencesOfString:@"/.*" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, localId.length)];
}

+ (NSString *)_assetUriForLocalId:(nonnull NSString *)localId andExtension:(nonnull NSString *)extension
{
  NSString *assetId = [ABI36_0_0EXMediaLibrary _assetIdFromLocalId:localId];
  NSString *uppercasedExtension = [extension uppercaseString];
  
  return [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@&ext=%@", uppercasedExtension, assetId, uppercasedExtension];
}

+ (PHAssetMediaType)_assetTypeForUri:(nonnull NSString *)localUri
{
  CFStringRef fileExtension = (__bridge CFStringRef)[localUri pathExtension];
  CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
  
  if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
    return PHAssetMediaTypeImage;
  }
  if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
    return PHAssetMediaTypeVideo;
  }
  if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
    return PHAssetMediaTypeAudio;
  }
  return PHAssetMediaTypeUnknown;
}

+ (NSString *)_stringifyMediaType:(PHAssetMediaType)mediaType
{
  switch (mediaType) {
    case PHAssetMediaTypeAudio:
      return ABI36_0_0EXAssetMediaTypeAudio;
    case PHAssetMediaTypeImage:
      return ABI36_0_0EXAssetMediaTypePhoto;
    case PHAssetMediaTypeVideo:
      return ABI36_0_0EXAssetMediaTypeVideo;
    default:
      return ABI36_0_0EXAssetMediaTypeUnknown;
  }
}

+ (PHAssetMediaType)_convertMediaType:(NSString *)mediaType
{
  if ([mediaType isEqualToString:ABI36_0_0EXAssetMediaTypeAudio]) {
    return PHAssetMediaTypeAudio;
  }
  if ([mediaType isEqualToString:ABI36_0_0EXAssetMediaTypePhoto]) {
    return PHAssetMediaTypeImage;
  }
  if ([mediaType isEqualToString:ABI36_0_0EXAssetMediaTypeVideo]) {
    return PHAssetMediaTypeVideo;
  }
  return PHAssetMediaTypeUnknown;
}

+ (NSMutableArray<NSNumber *> *)_convertMediaTypes:(NSArray<NSString *> *)mediaTypes
{
  __block NSMutableArray<NSNumber *> *assetTypes = [NSMutableArray new];
  
  [mediaTypes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isEqualToString:ABI36_0_0EXAssetMediaTypeAll]) {
      *stop = YES;
      assetTypes = nil;
      return;
    }
    PHAssetMediaType assetType = [ABI36_0_0EXMediaLibrary _convertMediaType:obj];
    [assetTypes addObject:@(assetType)];
  }];
  
  return assetTypes;
}

+ (NSString *)_convertSortByKey:(NSString *)key
{
  if ([key isEqualToString:@"default"]) {
    return nil;
  }
  
  NSDictionary *conversionDict = @{
                                   @"creationTime": @"creationDate",
                                   @"modificationTime": @"modificationDate",
                                   @"mediaType": @"mediaType",
                                   @"width": @"pixelWidth",
                                   @"height": @"pixelHeight",
                                   @"duration": @"duration",
                                   };
  NSString *value = [conversionDict valueForKey:key];
  
  if (value == nil) {
    NSString *reason = [NSString stringWithFormat:@"SortBy key \"%@\" is not supported!", key];
    @throw [NSException exceptionWithName:@"ABI36_0_0EXMediaLibrary.UNSUPPORTED_SORTBY_KEY" reason:reason userInfo:nil];
  }
  return value;
}

+ (NSArray<NSString *> *)_stringifyMediaSubtypes:(PHAssetMediaSubtype)mediaSubtypes
{
  NSMutableArray *subtypes = [NSMutableArray new];
  NSMutableDictionary<NSString *, NSNumber *> *subtypesDict = [@{
                                                               @"hdr": @(PHAssetMediaSubtypePhotoHDR),
                                                               @"panorama": @(PHAssetMediaSubtypePhotoPanorama),
                                                               @"stream": @(PHAssetMediaSubtypeVideoStreamed),
                                                               @"timelapse": @(PHAssetMediaSubtypeVideoTimelapse),
                                                               @"screenshot": @(PHAssetMediaSubtypePhotoScreenshot),
                                                               @"highFrameRate": @(PHAssetMediaSubtypeVideoHighFrameRate)
                                                               } mutableCopy];
  
  subtypesDict[@"livePhoto"] = @(PHAssetMediaSubtypePhotoLive);
  if (@available(iOS 10.2, *)) {
    subtypesDict[@"depthEffect"] = @(PHAssetMediaSubtypePhotoDepthEffect);
  }
  
  for (NSString *subtype in subtypesDict) {
    if (mediaSubtypes & [subtypesDict[subtype] unsignedIntegerValue]) {
      [subtypes addObject:subtype];
    }
  }
  return subtypes;
}

+ (NSString *)_stringifyAlbumType:(PHAssetCollectionType)assetCollectionType
{
  switch (assetCollectionType) {
    case PHAssetCollectionTypeAlbum:
      return @"album";
    case PHAssetCollectionTypeMoment:
      return @"moment";
    case PHAssetCollectionTypeSmartAlbum:
      return @"smartAlbum";
  }
}

+ (NSNumber *)_assetCountOfCollection:(PHAssetCollection *)collection
{
  if (collection.estimatedAssetCount == NSNotFound) {
    PHFetchOptions *options = [PHFetchOptions new];
    options.includeHiddenAssets = NO;
    options.includeAllBurstAssets = NO;
    
    return @([PHAsset fetchAssetsInAssetCollection:collection options:options].count);
  }
  return @(collection.estimatedAssetCount);
}

+ (NSSortDescriptor *)_sortDescriptorFrom:(id)config
{
  if ([config isKindOfClass:[NSString class]]) {
    NSString *key = [ABI36_0_0EXMediaLibrary _convertSortByKey:config];
    
    if (key) {
      return [NSSortDescriptor sortDescriptorWithKey:key ascending:NO];
    }
  }
  if ([config isKindOfClass:[NSArray class]]) {
    NSArray *sortArray = (NSArray *)config;
    NSString *key = [ABI36_0_0EXMediaLibrary _convertSortByKey:sortArray[0]];
    BOOL ascending = [(NSNumber *)sortArray[1] boolValue];
    
    if (key) {
      return [NSSortDescriptor sortDescriptorWithKey:key ascending:ascending];
    }
  }
  return nil;
}

+ (NSArray *)_prepareSortDescriptors:(NSArray *)sortBy
{
  NSMutableArray *sortDescriptors = [NSMutableArray new];
  NSArray *sortByArray = (NSArray *)sortBy;
  
  for (id config in sortByArray) {
    NSSortDescriptor *sortDescriptor = [ABI36_0_0EXMediaLibrary _sortDescriptorFrom:config];
    
    if (sortDescriptor) {
      [sortDescriptors addObject:sortDescriptor];
    }
  }
  return sortDescriptors;
}

+ (NSURL *)_normalizeAssetURLFromUri:(NSString *)uri
{
  if ([uri hasPrefix:@"/"]) {
    return [NSURL URLWithString:[@"file://" stringByAppendingString:uri]];
  }
  return [NSURL URLWithString:uri];
}

- (BOOL)_checkPermissions:(ABI36_0_0UMPromiseRejectBlock)reject
{
  if (![_permissionsManager hasGrantedPermissionUsingRequesterClass:[ABI36_0_0EXMediaLibraryCameraRollRequester class]]) {
    reject(@"E_NO_PERMISSIONS", @"CAMERA_ROLL permission is required to do this operation.", nil);
    return NO;
  }
  return YES;
}

@end
