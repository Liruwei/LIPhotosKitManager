//
//  LIPhotosKitManager.m
//
//  Created by RuweiLi on 7/16/16.
//  Copyright © 2016 liruwei. All rights reserved.
//


#import "LIPhotosKitManager.h"
#import <objc/runtime.h>
@import Photos;

const void * TargetIndentifierKey;
const void * TargetResultHandelKey;
static NSString * AllPhotosAlbum = @"All Photos";
static NSString * LIIDIdentifier = @"identifier";
static NSString * LIIDIndex = @"index";
static NSString * LIIDAlbumName = @"albumName";
static NSString * LIIDAlbumIdentifier = @"albumIdentifier";
static NSString * LIAlbumIdentifier = @"identifier";
static NSString * LIAlbumName = @"name";
static NSString * LIAlbumPhotos = @"photos";




@interface LIPhotosKitManager ()<PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) NSMutableDictionary *photosResultsDic;
@end


@implementation LIPhotosKitManager
- (instancetype)init
{
    if (self = [super init]) {
        self.photosResultsDic = [NSMutableDictionary dictionary];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark -  Method
- (NSArray<LIAlbum *> *)allSystemAlbums
{
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    NSArray *albums = [self getAlbumsFromFetchResult:smartAlbums];
    return [albums mutableCopy];
}

- (NSArray<LIAlbum *> *)allUserCustomAlbums
{
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    NSArray *albums = [self getAlbumsFromFetchResult:topLevelUserCollections];
    return [albums mutableCopy];

}


- (NSArray *)allPhotosIDSortByCreateDateAscending:(BOOL)ascending
{
    PHFetchOptions *allPhotosOptions = [[PHFetchOptions alloc] init];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];
    PHFetchResult *allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
    
    NSDictionary *info = @{LIIDAlbumName:AllPhotosAlbum, LIIDAlbumIdentifier:[NSString string]};
    NSArray *identifiers = [self getIDsFromFetchResult:allPhotos info:info];

    [self.photosResultsDic setValue:allPhotos forKey:AllPhotosAlbum];
    return [identifiers mutableCopy];
}

- (PHImageRequestID)requestThumbnailImageForID:(LIID *)idObj size:(CGSize)imageSize contentMode:(LIImageContentMode)contentMode target:(id)target resultHandler:(LIImageHandler)handelBlock
{
    objc_setAssociatedObject(target, TargetIndentifierKey, idObj.identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    PHAsset *asset = [self getAssetFromID:idObj];
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(imageSize.width * scale, imageSize.height * scale);
    PHImageContentMode imageContentMode = [self transformImageContentMode:contentMode];
    PHImageManager *imageManager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    
    return [imageManager requestImageForAsset:asset targetSize:targetSize contentMode:imageContentMode options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        NSString *identifier = objc_getAssociatedObject(target, TargetIndentifierKey);
        if ([identifier isEqualToString:asset.localIdentifier]) {
            handelBlock(result,target,info);
        }
    }];
}

- (void)requestOriginalImageForID:(LIID *)idObj target:(id)target resultHandler:(LIImageHandler)handelBlock
{
    objc_setAssociatedObject(target, TargetIndentifierKey, idObj.identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    PHAsset *asset =  [self getAssetFromID:idObj];
    PHImageManager *imageManager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    
    [imageManager requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        NSString *identifier = objc_getAssociatedObject(target, TargetIndentifierKey);
        if ([identifier isEqualToString:asset.localIdentifier]) {
            handelBlock(result,target,info);
        }
    }];
}

- (void)requestOriginalImageDataForID:(LIID *)idObj target:(id)target resultHandler:(LIImageDataHandler)handelBlock
{
    objc_setAssociatedObject(target, TargetIndentifierKey, idObj.identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    PHAsset *asset = [self getAssetFromID:idObj];
    PHImageManager *imageManager = [PHImageManager defaultManager];
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    
    [imageManager requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        NSString *identifier = objc_getAssociatedObject(target, TargetIndentifierKey);
        if ([identifier isEqualToString:asset.localIdentifier]) {
            handelBlock(imageData,target,dataUTI,orientation,info);
        }
    }];
}

-(void)requestVideoUrlForID:(LIID*)idObj target:(id)target resultHandler:(LIVideoHandler)handleBlock{
    objc_setAssociatedObject(target, TargetIndentifierKey, idObj.identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    PHAsset *asset = [self getAssetFromID:idObj];
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.networkAccessAllowed = YES;
    
    PHImageManager *imageManager = [PHImageManager defaultManager];

    [imageManager requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            NSURL *URL = [(AVURLAsset *)asset URL];
            handleBlock(URL,target,info);
        }
    }];
}

- (PHAsset *)getAssetFromID:(LIID *)idObj
{
    return self.photosResultsDic[idObj.albumName][idObj.index];
}

- (NSArray *)getIDsFromFetchResult:(PHFetchResult *)result info:(NSDictionary *)info
{
    NSMutableArray *array = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PHAsset *asset = obj;
        LIID *idObj = [LIID new];
        [idObj setValue:asset.localIdentifier forKey:LIIDIdentifier];
        [idObj setValue:@(idx) forKey:LIIDIndex];
        [idObj setValue:info[LIIDAlbumName] forKey:LIIDAlbumName];
        [idObj setValue:info[LIIDAlbumIdentifier] forKey:LIIDAlbumIdentifier];
        idObj.type = asset.mediaType;
        idObj.duration = asset.duration;
        
        [array addObject:idObj];
    }];
    return array;
}

- (NSArray *)getAlbumsFromFetchResult:(PHFetchResult *)result
{
    NSMutableArray *albums = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PHCollection *collection = obj;
        if (![collection isKindOfClass:[PHAssetCollection class]]) {
            return;
        }
        PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
        NSString *name = assetCollection.localizedTitle;
        NSString *identifier = assetCollection.localIdentifier;
        NSDictionary *info = @{LIIDAlbumName:name,LIIDAlbumIdentifier:identifier};
        NSArray *photos = [self getIDsFromFetchResult:assetsFetchResult info:info];
        
        LIAlbum *album = [LIAlbum new];
        [album setValue:name forKey:LIAlbumName];
        [album setValue:identifier forKey:LIAlbumIdentifier];
        [album setValue:photos forKey:LIAlbumPhotos];
        [albums addObject:album];
        
        [self.photosResultsDic setValue:assetsFetchResult forKey:name];
    }];
    return albums;
}


- (PHImageContentMode)transformImageContentMode:(LIImageContentMode)mode{
    switch (mode) {
        case LIImageContentModeAspectFit:
            return PHImageContentModeAspectFit;
            break;
        case LIImageContentModeAspectFill:
            return PHImageContentModeAspectFill;
            break;
        default:
            return PHImageContentModeDefault;
            break;
    }
}

#pragma mark -  PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    if ([self.delagate respondsToSelector:@selector(managerDidReceivePhotoLibraryChangeNotification)]) {
        [self.delagate managerDidReceivePhotoLibraryChangeNotification];
    }
}
@end



@implementation LIID
@synthesize identifier = _identifier;
@synthesize albumIdentifier = _albumIdentifier;
- (NSString *)identifier
{
    if (!_identifier) {
        _identifier = [NSString string];
    }
    return _identifier;
}

- (NSString *)albumIdentifier
{
    if (!_albumIdentifier) {
        _albumIdentifier = [NSString string];
    }
    return _albumIdentifier;
}
@end

@implementation LIAlbum
@synthesize name = _name;
@synthesize identifier = _identifier;
@synthesize photos = _photos;
- (NSString *)name
{
    if (!_name) {
        _name = [NSString string];
    }
    return _name;
}

- (NSString *)identifier
{
    if (!_identifier) {
        _identifier = [NSString string];
    }
    return _identifier;
}

- (NSArray<LIID *> *)photos
{
    if (!_photos) {
        _photos = [NSArray array];
    }
    return _photos;
}

@end
