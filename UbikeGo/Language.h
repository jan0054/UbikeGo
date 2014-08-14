//
//  Language.h
//  UbikeGo
//
//  Created by csjan on 8/13/14.
//  Copyright (c) 2014 tapgo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Language : NSObject
+(void)initialize;
+(void)setLanguage:(NSString *)l;
+(NSString *)get:(NSString *)key alter:(NSString *)alternate;
@end
