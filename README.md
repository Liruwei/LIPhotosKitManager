# LIPhotosKitManager

[![CI Status](http://img.shields.io/travis/Robert/LIPhotosKitManager.svg?style=flat)](https://travis-ci.org/Robert/LIPhotosKitManager)
[![Version](https://img.shields.io/cocoapods/v/LIPhotosKitManager.svg?style=flat)](http://cocoapods.org/pods/LIPhotosKitManager)
[![License](https://img.shields.io/cocoapods/l/LIPhotosKitManager.svg?style=flat)](http://cocoapods.org/pods/LIPhotosKitManager)
[![Platform](https://img.shields.io/cocoapods/p/LIPhotosKitManager.svg?style=flat)](http://cocoapods.org/pods/LIPhotosKitManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* Xcode 6
* iOS 8.0 +

## Installation

LIPhotosKitManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "LIPhotosKitManager"
```

## How to user

#### Importing Headers then create property and initialization

~~~objectiveC
#import <LIPhotosKitManager.h> //---------------------------------------1

@interface ViewController ()<LIPhotosKitManagerDelegate>
@property (nonatomic, strong) LIPhotosKitManager *manager; //-----------2
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //------------------------------------------------------------------3
    self.manager = [[LIPhotosKitManager alloc] init];
    self.manager.delagate = self;
}

- (void)managerDidReceivePhotoLibraryChangeNotification
{    
	// delegate method
    // update your datasource and refresh ui
}
@end

~~~

#### Get Albums 
You can use `allSystemAlbums` or `allUserCustomAlbums` methods to get albums in your device. These methods return a array contain `LIAlbum` objects.

~~~objectiveC
NSArray *systemAlbums = [self.manager allSystemAlbums];
NSArray *customAlbums = [self.manager allUserCustomAlbums];
~~~

#### Get Photos
Before obtaining Photos, you must get the `ALID` object. There are two ways to get that object. One is read from `ALAlbum` object, another is use the `allPhotosIDSortByCreateDateAscending:` method

~~~objectiveC
NSArray *imageIDs = [self.manager allPhotosIDSortByCreateDateAscending:YES];
~~~
Everything is ready ,use the following methods to get the photos you want.:

* requestThumbnailImageForID:size:contentMode:target:resultHandler: 
* requestOriginalImageForID:target:resultHandler:
* requestOriginalImageDataForID:target:resultHandler:

Esample 

~~~objectiveC
LIID *idObj = self.imageIDs[index];
UIImageView *imageView = self.imageView;
[self.manager requestThumbnailImageForID:idObj size:CGSizeMake(100, 100) contentMode:0 target:imageView resultHandler:^(UIImage *result, id target, NSDictionary *info) {
	UIImageView *imageView = target;
	imageView.image = result;
}];
~~~

## Author

Ruwei Li, liruwei0109@outlook.com

## License

LIPhotosKitManager is available under the MIT license. See the LICENSE file for more info.
