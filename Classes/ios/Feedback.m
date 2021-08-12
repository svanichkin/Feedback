//
//  Feedback.m
//  Version 1.4
//
//  Created by Sergey Vanichkin on 15.02.2018.
//  Copyright © 2018 Sergey Vanichkin. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//

#import "Feedback.h"
#import <MessageUI/MessageUI.h>

#define FEEDBACK_iMESSAGE @"FeedbackIMessage"
#define FEEDBACK_EMAiL    @"FeedbackEmail"
#define FEEDBACK_UPDATE   @"FeedbackUpdate"

@implementation FeedbackAttachment
@end

@interface Feedback () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property (nonatomic, strong) NSString *iMessage;
@property (nonatomic, strong) NSString *email;

@property (nonatomic, strong) NSURL    *url;

@end

@implementation Feedback

-(instancetype)init
{
    if (self == [super init])
    {
        [NSNotificationCenter.defaultCenter
         addObserver:self
         selector:@selector(willEnterForegroundNotification)
         name:UIApplicationWillEnterForegroundNotification
         object:nil];
        
        if (@available(iOS 13.0, *))
            [NSNotificationCenter.defaultCenter
             addObserver:self
             selector:@selector(willEnterForegroundNotification)
             name:UISceneWillEnterForegroundNotification
             object:nil];
    }
    
    return
    self;
}

-(void)willEnterForegroundNotification
{
    if (ENABLE_iNFO_LOG)
        NSLog(@"[INFO] Feedback: Application will enter foreground");
    
    [Feedback
     setupWithURLString:Feedback.current.url.absoluteString];
}

+(Feedback *)current
{
    static dispatch_once_t pred;
    static Feedback *shared = nil;
    
    dispatch_once(&pred, ^
    {
        shared = self.new;
    });
    
    return shared;
}

+(void)setupWithURLString:(NSString *)urlString
{
    NSURL *url =
    [NSURL
     URLWithString:urlString];
    
    if (url == nil)
        [NSException
         raise:@"Feedback"
         format:@"Url string is not valid: %@",
         urlString];
    
    Feedback.current.url = url;
    
    Feedback.current.iMessage =
    [NSUserDefaults.standardUserDefaults
     objectForKey:FEEDBACK_iMESSAGE];
    
    Feedback.current.email    =
    [NSUserDefaults.standardUserDefaults
     objectForKey:FEEDBACK_EMAiL];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
    {
        NSDate *fileDate =
        [self
         lastModificationDateOfFileAtURL:url];
        
        NSDate *updateDate =
        [NSUserDefaults.standardUserDefaults
         objectForKey:FEEDBACK_UPDATE];
        
        if (updateDate && fileDate)
            if (!([fileDate
                   compare:updateDate] == NSOrderedDescending))
                return;

        NSData *jsonData =
        [NSData
         dataWithContentsOfURL:url];
        
        if (!jsonData)
            return;
        
        NSDictionary *jsonObject =
        [NSJSONSerialization
         JSONObjectWithData:jsonData
         options:0
         error:nil];
        
        if (!jsonObject)
            return;
        
        dispatch_async(dispatch_get_main_queue(), ^(void)
        {
            if (jsonObject[@"iMessage"])
            {
                Feedback.current.iMessage =
                jsonObject[@"iMessage"];
            
                [NSUserDefaults.standardUserDefaults
                 setObject:Feedback.current.iMessage
                 forKey:FEEDBACK_iMESSAGE];
            }
            
            if (jsonObject[@"email"])
            {
                Feedback.current.email    =
                jsonObject[@"email"];
            
                [NSUserDefaults.standardUserDefaults
                 setObject:Feedback.current.email
                 forKey:FEEDBACK_EMAiL];
            }
            
            if (jsonObject[@"iMessage"] && jsonObject[@"email"])
                [NSUserDefaults.standardUserDefaults
                 setObject:fileDate
                 forKey:FEEDBACK_UPDATE];
        });
    });
}

+(NSDate *)lastModificationDateOfFileAtURL:(NSURL *)url
{
    NSMutableURLRequest *request =
    [NSMutableURLRequest.alloc
     initWithURL:url];
    
    request.HTTPMethod = @"HEAD";
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    [NSURLConnection
     sendSynchronousRequest:request
     returningResponse:&response
     error:&error];
    
    if (error)
    {
        if (ENABLE_ERROR_LOG)
        NSLog(@"[Error] Feedback: %@",
              error.localizedDescription);
        
        return
        nil;
    }
    
    else if([response
             respondsToSelector:@selector(allHeaderFields)])
    {
        NSDictionary *headerFields =
        response.allHeaderFields;
        
        NSString *lastModification =
        headerFields[@"Last-Modified"];
        
        NSDateFormatter *formatter =
        NSDateFormatter.new;
        
        formatter.dateFormat =
        @"EEE, dd MMM yyyy HH:mm:ss zzz";
        
        return
        [formatter
         dateFromString:lastModification];
    }
    
    return nil;
}

+(void)setupWithIMessage:(NSString *)iMessage
                   email:(NSString *)email
{
    Feedback.current.iMessage = iMessage;
    Feedback.current.email    = email;
}

+(void)sendFeedbackWithController:(UIViewController *)controller
{
    [self
     sendFeedbackWithController:controller
     text:nil];
}

+(void)sendFeedbackWithController:(UIViewController *)controller
                             text:(NSString         *)text
{
    if (MFMessageComposeViewController.canSendText &&
        Feedback.current.iMessage.length)
    {
        MFMessageComposeViewController *message =
        MFMessageComposeViewController.new;
        
        message.messageComposeDelegate =
        Feedback.current;
        
        message.recipients =
        @[Feedback.current.iMessage];
        
        message.body =
        text;
        
        [controller
         presentViewController:message
         animated:YES
         completion:nil];
    }
    
    else if (MFMailComposeViewController.canSendMail &&
             Feedback.current.email.length)
    {
        MFMailComposeViewController *mail =
        MFMailComposeViewController.new;
        
        mail.mailComposeDelegate =
        Feedback.current;
        
        mail.toRecipients =
        @[Feedback.current.email];
        
        [mail
         setMessageBody:text
         isHTML:NO];
        
        [controller
         presentViewController:mail
         animated:YES
         completion:nil];
    }
}

+(void)sendFeedbackWithController:(UIViewController               *)controller
                      attachments:(NSArray <FeedbackAttachment *> *)attachments
{
    NSString *appName =
    NSBundle.mainBundle.localizedInfoDictionary[@"CFBundleDisplayName"];
    
    NSString *osVersion =
    [NSString
     stringWithFormat:@"iOS(%@)",
     UIDevice.currentDevice.systemVersion];
    
    NSString *appVersion =
    [NSString
     stringWithFormat:@"v.%@",
     [NSBundle.mainBundle.infoDictionary
      objectForKey:@"CFBundleShortVersionString"]];
    
    if (MFMessageComposeViewController.canSendText && Feedback.current.iMessage.length)
    {
        MFMessageComposeViewController *message =
        MFMessageComposeViewController.new;
        
        message.messageComposeDelegate =
        Feedback.current;
        
        message.recipients =
        @[Feedback.current.iMessage];
                
        for (FeedbackAttachment *attachment in attachments)
            [message
             addAttachmentData:attachment.attachmentData
             typeIdentifier:attachment.typeIdentifier
             filename:[@[appName,
                         appVersion,
                         osVersion,
                         NSDate.now,
                         attachment.filename]
                       componentsJoinedByString:@" "]];
        
        [controller
         presentViewController:message
         animated:YES
         completion:nil];
    }
    
    else if (MFMailComposeViewController.canSendMail && Feedback.current.email.length)
    {
        MFMailComposeViewController *mail =
        MFMailComposeViewController.new;
        
        mail.mailComposeDelegate =
        Feedback.current;
        
        mail.toRecipients =
        @[Feedback.current.email];
        
        mail.subject =
        NSBundle.mainBundle.localizedInfoDictionary[@"CFBundleDisplayName"];
        
        for (FeedbackAttachment *attachment in attachments)
            [mail
             addAttachmentData:attachment.attachmentData
             mimeType:attachment.mimeType
             fileName:[@[appName,
                         appVersion,
                         NSDate.now,
                         attachment.filename]
                       componentsJoinedByString:@" "]];
        
        [controller
         presentViewController:mail
         animated:YES
         completion:nil];
    }
}


-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult          )result
                       error:(NSError                     *)error
{
    [controller
     dismissViewControllerAnimated:YES
     completion:nil];
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller
                didFinishWithResult:(MessageComposeResult            )result
{
    [controller
     dismissViewControllerAnimated:YES
     completion:nil];
}

@end
