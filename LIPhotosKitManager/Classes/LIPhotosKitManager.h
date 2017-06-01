//
//  LIPhotosKitManager.h
//
//  Created by RuweiLi on 7/16/16.
//  Copyright © 2016 liruwei. All rights reserved.
//

@import UIKit;
@import Foundation;

@import Photos;

typedef NS_ENUM(NSInteger,LIImageContentMode) {
    LIImageContentModeAspectFit = 0,
    LIImageContentModeAspectFill = 1,
    LIImageContentModeDefault = LIImageContentModeAspectFit
};

typedef void(^LIImageHandler)(UIImage  *_Nullable result ,id  _Nonnull target ,NSDictionary *_Nullable info);
typedef void(^LIVideoHandler)(NSURL  *_Nullable videoUrl ,id  _Nonnull target ,NSDictionary *_Nullable info);
typedef void(^LIImageDataHandler)(NSData *_Nullable imageData,id  _Nonnull target, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info);







@protocol LIPhotosKitManagerDelegate;
@class LIID,LIAlbum;
@interface LIPhotosKitManager : NSObject

@property (nonatomic, assign, nullable) id<LIPhotosKitManagerDelegate> delagate;

- (NSArray<LIAlbum*> *_Nonnull)allSystemAlbums;

- (NSArray<LIAlbum*> *_Nonnull)allUserCustomAlbums;

- (NSArray<LIID*> *_Nonnull)allPhotosIDSortByCreateDateAscending:(BOOL)ascending;

- (void)requestThumbnailImageForID:(LIID *_Nonnull)idObj size:(CGSize)imageSize contentMode:(LIImageContentMode)contentMode target:(id _Nonnull)target resultHandler:(LIImageHandler _Nonnull)result;

/**
 *  Generally do not need to call this method , because the original image is too big , you can use `requestThumbnailImageForID:size:contentMode:target:resultHandler:` method to obtain a large-size image
 */
- (void)requestOriginalImageForID:(LIID *_Nonnull)idObj target:(id _Nonnull)target resultHandler:(LIImageHandler _Nonnull)result;
- (void)requestOriginalImageDataForID:(LIID *_Nonnull)idObj target:(id _Nonnull)target resultHandler:(LIImageDataHandler _Nonnull)result;

-(void)requestVideoUrlForID:(LIID* _Nonnull)idObj target:(id _Nonnull)target resultHandler:(LIVideoHandler _Nonnull)handleBlock;

@end












@interface LIID : NSObject
@property (nonatomic, assign ,readonly) NSInteger index;
@property (nonatomic, copy, readonly, nonnull) NSString *identifier;
@property (nonatomic, copy, readonly, nullable) NSString *albumName;
@property (nonatomic, copy, readonly,nonnull) NSString *albumIdentifier;
@property (nonatomic) PHAssetMediaType type;
@property (nonatomic) NSTimeInterval duration;

@end

@interface LIAlbum : NSObject
@property (nonatomic, copy, readonly, nonnull) NSString *name;
@property (nonatomic, strong, readonly, nonnull) NSArray<LIID*> *photos;
@property (nonatomic, copy, readonly, nonnull) NSString *identifier;
@end


@protocol LIPhotosKitManagerDelegate <NSObject>
@required
- (void)managerDidReceivePhotoLibraryChangeNotification;
@end
