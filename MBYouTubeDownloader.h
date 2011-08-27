//
//  MBYouTubeDownloader.h
//  MyTube
//
//  Created by Matheus Brum on 07/07/11.
//  Copyright 2011 Brum. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol MBYouTubeDownloaderDelegate;
@interface MBYouTubeDownloader : NSObject <NSXMLParserDelegate>{
    NSURLRequest		*DownloadRequest;
	NSURLConnection		*DownloadConnection;
	NSMutableData		*receivedData;
	NSString			*localFilename;
    NSString            *humanLink;
	NSString			*videoID;
    NSURL               *superURL;
    NSTimer            *tempo;
    NSInteger           superTimeout;
	id<MBYouTubeDownloaderDelegate> delegate;
	float				bytesReceived;
	long long			expectedBytes;
	
	BOOL				operationFinished, operationFailed, operationBreaked;
	BOOL				operationIsOK;	
	BOOL				appendIfExist;
    BOOL                videoDownLoadFinished;
    BOOL                videoInformationFinished;
	FILE				*downFile;
	NSString			*possibleFilename;
	
	float percentComplete;

    NSString *videoTitle;
    UIImage *videoImage;
    
    
    //PARSER
    NSXMLParser * rssParser;
//	NSMutableArray * stories;
    NSString * currentElement;
	NSMutableString * currentTitle,  * currentLink;
	NSMutableDictionary * item;

}
- (MBYouTubeDownloader *)initWithURL:(NSURL *)fileURL timeout:(NSInteger)timeout webView:(UIWebView *)webV delegate:(id<MBYouTubeDownloaderDelegate>)theDelegate;
@property (assign) BOOL operationIsOK;
@property (assign) BOOL appendIfExist;
@property (assign) BOOL operationFinished;

//@property (nonatomic, copy) NSString *fileUrlPath;

@property (nonatomic, readonly) NSMutableData* receivedData;
@property (nonatomic, readonly, retain) NSURLRequest* DownloadRequest;
@property (nonatomic, readonly, retain) NSURLConnection* DownloadConnection;
@property (nonatomic,retain) id<MBYouTubeDownloaderDelegate> delegate;

@property (nonatomic, readonly) float percentComplete;
@property (nonatomic, retain) NSString *possibleFilename;
@property (nonatomic, retain)    NSString            *humanLink;

@property (nonatomic, retain)    NSString *videoTitle;
@property (nonatomic, retain)    UIImage *videoImage;

//@property (nonatomic, retain)NSMutableArray * stories;

- (void) forceStop;
-(void)startDownload;
- (void) forceContinue;
-(void)checarSeConcluiu;
-(void)concluir;
@end

@protocol MBYouTubeDownloaderDelegate<NSObject>
@optional
- (void)downloadBar:(MBYouTubeDownloader *)downloadBar didFinishWithData:(NSData *)fileData suggestedFilename:(NSString *)filename videoTitle:(NSString *)title videoImage:(UIImage *)img;
- (void)downloadBar:(MBYouTubeDownloader *)downloadBar didFailWithError:(NSError *)error;
- (void)downloadBarUpdated:(MBYouTubeDownloader *)downloadBar withPercentage:(float)complete;

@end
