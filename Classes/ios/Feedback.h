//
//  Feedback.h
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
//  Setup with your email or/and imessage
//
//  [Feedback
//   setupWithIMessage:@"my_imessage@me.com"
//   email:@"my_email.me.com"];
//
//  Then do action on user button "Send feedback"
//
//  [Feedback
//   sendFeedbackWithController:self
//   text:@"User send feedback from App"];
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define ENABLE_iNFO_LOG  NO
#define ENABLE_ERROR_LOG NO

@interface FeedbackAttachment : NSObject

@property (nonatomic, strong) NSData   *attachmentData;
@property (nonatomic, strong) NSString *typeIdentifier;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *filename;

@end

@interface Feedback : NSObject

+(void)setupWithURLString:(NSString *)urlString;

+(void)setupWithIMessage:(NSString *)iMessage
                   email:(NSString *)email;

+(void)sendFeedbackWithController:(UIViewController *)controller;

+(void)sendFeedbackWithController:(UIViewController *)controller
                             text:(NSString         *)text;

+(void)sendFeedbackWithController:(UIViewController               *)controller
                      attachments:(NSArray <FeedbackAttachment *> *)attachments;

@end
