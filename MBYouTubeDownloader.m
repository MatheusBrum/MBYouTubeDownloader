//
//  MBYouTubeDownloader.m
//  MyTube
//
//  Created by Matheus Brum on 07/07/11.
//  Copyright 2011 Brum. All rights reserved.
//

#import "MBYouTubeDownloader.h"

@implementation MBYouTubeDownloader
@synthesize DownloadRequest,
DownloadConnection,
receivedData,
delegate,
percentComplete,
operationIsOK,
appendIfExist,
humanLink,
videoImage,
videoTitle,
operationFinished,
//stories,
possibleFilename;
- (void) forceStop {
	operationBreaked = YES;
}
- (void) forceContinue {
	operationBreaked = NO;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: superURL];
	[request addValue: [NSString stringWithFormat: @"bytes=%.0f-", bytesReceived ] forHTTPHeaderField: @"Range"];	
	DownloadConnection = [NSURLConnection connectionWithRequest:request delegate: self];	
}
- (MBYouTubeDownloader *)initWithURL:(NSURL *)fileURL timeout:(NSInteger)timeout webView:(UIWebView *)webV delegate:(id<MBYouTubeDownloaderDelegate>)theDelegate{
    self = [super init];
	if(self) {
		self.delegate = theDelegate;
		bytesReceived = percentComplete = 0;
        superTimeout=timeout;
		localFilename = [[[fileURL absoluteString] lastPathComponent] copy];
		receivedData = [[NSMutableData alloc] initWithLength:0];
        superURL=[NSURL URLWithString:[webV stringByEvaluatingJavaScriptFromString:@"function getURL() {var player = document.getElementById('player'); var video = player.getElementsByTagName('video')[0]; return video.getAttribute('src');} getURL();"]];
        videoID=[[[fileURL absoluteString] lastPathComponent] stringByReplacingOccurrencesOfString:@"watch?v=" withString:@""];
        NSLog(@"Comecou o download %@",superURL);
        [self startDownload];
        NSString * path=[NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos/%@?v=2",videoID];
        [NSThread detachNewThreadSelector:@selector(parseXMLFileAtURL:) toTarget:self withObject:path];
	}
	return self;
}
-(void)baixarImagem{
    NSURL *imageURL = [NSURL URLWithString:[NSString stringWithFormat: @"http://i4.ytimg.com/vi/%@/default.jpg",videoID]];
	NSData *data = [NSData dataWithContentsOfURL:imageURL];
	videoImage = [[UIImage alloc] initWithData:data];
    [self performSelectorOnMainThread:@selector(jaBaixouImagem) withObject:nil waitUntilDone:YES];
}
-(void)jaBaixouImagem{
   // NSLog(@"jaBaixouImagem");
    videoInformationFinished=YES;
    [self checarSeConcluiu];
}
-(void)checarSeConcluiu{
    if (videoDownLoadFinished && videoInformationFinished) {
        [self concluir];
    }else{
        tempo=[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(concluir) userInfo:nil repeats:YES];

    }
}
-(void)concluir{
    if (videoDownLoadFinished && videoInformationFinished) {
        if ([self.delegate respondsToSelector:@selector(downloadBar:didFinishWithData:suggestedFilename:videoTitle:videoImage:)]) {
            [self.delegate downloadBar:self didFinishWithData:self.receivedData suggestedFilename:humanLink videoTitle:videoTitle videoImage:videoImage];
        }
      //  operationFinished = YES;
        [tempo invalidate];
    }else{
      //  NSLog(@"Esperando concluir");
    }
}
- (void)parseXMLFileAtURL:(NSString *)URL{	
   // NSLog(@"Comecou a pegar informações");
	NSURL *xmlURL = [NSURL URLWithString:URL];
    rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [rssParser setDelegate:self];
	[rssParser setShouldProcessNamespaces:NO];
    [rssParser setShouldReportNamespacePrefixes:NO];
    [rssParser setShouldResolveExternalEntities:NO];
    [rssParser parse];
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
	currentElement = [elementName copy];
	if ([elementName isEqualToString:@"media:group"]) {
		item = [[NSMutableDictionary alloc] init];
		currentTitle = [[NSMutableString alloc] init];
		currentLink = [[NSMutableString alloc] init];
	}
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	if ([currentElement isEqualToString:@"media:title"]) {
		[currentTitle appendString:string];
	}
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{     
	if ([elementName isEqualToString:@"media:group"]) {
		[item setObject:currentTitle forKey:@"title"];
        videoTitle=currentTitle;
	}
}
- (void)parserDidEndDocument:(NSXMLParser *)parser {   
	//NSLog(@"all done!= %@",videoTitle);
    [NSThread detachNewThreadSelector:@selector(baixarImagem) toTarget:self withObject:nil];
}
-(void)startDownload{
 //   NSLog(@"Comecou o download %@",superURL);
    DownloadRequest = [[NSURLRequest alloc] initWithURL:superURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:superTimeout];
    DownloadConnection = [[NSURLConnection alloc] initWithRequest:DownloadRequest delegate:self startImmediately:YES];
    if(DownloadConnection == nil) {
        [self.delegate downloadBar:self didFailWithError:[NSError errorWithDomain:@"UIDownloadBar Error" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"NSURLConnection Failed", NSLocalizedDescriptionKey, nil]]];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  //  NSLog(@"didReceiveData");
	if (!operationBreaked) {
		[self.receivedData appendData:data];
		float receivedLen = [data length];
		bytesReceived = (bytesReceived + receivedLen);
		if(expectedBytes != NSURLResponseUnknownLength) {
			percentComplete = (((bytesReceived/(float)expectedBytes)*100)/100);
            if ([delegate respondsToSelector:@selector(downloadBarUpdated:withPercentage:)]) {
                [delegate downloadBarUpdated:self withPercentage:percentComplete];
            }
		}
    } else {
		[connection cancel];
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError %@",[error description]);
    if ([delegate respondsToSelector:@selector(downloadBar:didFailWithError:)]) {
        [self.delegate downloadBar:self didFailWithError:error];
    }
	operationFailed = YES;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 //   NSLog(@"didReceiveResponse");
	NSHTTPURLResponse *r = (NSHTTPURLResponse*) response;
	NSDictionary *headers = [r allHeaderFields];
	if (headers){
		if ([headers objectForKey: @"Content-Range"]) {
			NSString *contentRange = [headers objectForKey: @"Content-Range"];
			NSRange range = [contentRange rangeOfString: @"/"];
			NSString *totalBytesCount = [contentRange substringFromIndex: range.location + 1];
			expectedBytes = [totalBytesCount floatValue];
		} else if ([headers objectForKey: @"Content-Length"]) {
			expectedBytes = [[headers objectForKey: @"Content-Length"] floatValue];
		} else expectedBytes = -1;
		if ([@"Identity" isEqualToString: [headers objectForKey: @"Transfer-Encoding"]]) {
			expectedBytes = bytesReceived;
			//operationFinished = YES;
		}
	}		
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	videoDownLoadFinished = YES;
    [self checarSeConcluiu];
}



@end
