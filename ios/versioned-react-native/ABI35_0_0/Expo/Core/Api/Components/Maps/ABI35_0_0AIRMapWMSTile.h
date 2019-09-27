//
//  ABI35_0_0AIRMapWMSTile.h
//  AirMaps
//
//  Created by nizam on 10/28/18.
//  Copyright © 2018. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

#import <ReactABI35_0_0/ABI35_0_0RCTComponent.h>
#import <ReactABI35_0_0/ABI35_0_0RCTView.h>
#import "ABI35_0_0AIRMapCoordinate.h"
#import "ABI35_0_0AIRMap.h"
#import "ABI35_0_0RCTConvert+AirMap.h"

@interface ABI35_0_0AIRMapWMSTile : MKAnnotationView <MKOverlay>

@property (nonatomic, weak) ABI35_0_0AIRMap *map;

@property (nonatomic, strong) MKTileOverlay *tileOverlay;
@property (nonatomic, strong) MKTileOverlayRenderer *renderer;
@property (nonatomic, copy) NSString *urlTemplate;
@property NSInteger maximumZ;
@property NSInteger minimumZ;
@property NSInteger tileSize;
@property BOOL shouldReplaceMapContent;

#pragma mark MKOverlay protocol

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly) MKMapRect boundingMapRect;
- (BOOL)canReplaceMapContent;
@end

@interface ABI35_0_0TileOverlay : MKTileOverlay
@property (nonatomic) double MapX,MapY,FULL;
@end
