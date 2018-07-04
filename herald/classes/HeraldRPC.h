//
//  HeraldRPC.h
//  herald
//
//  Created by hypafrag on 05/07/2018.
//  Copyright © 2018 coons club. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HeraldRPC : NSObject

+ (instancetype)sharedInstance;

- (void)say:(NSString *)phrase;
- (void)skill:(NSString *)name;
- (void)skill:(NSString *)name withArgs:(NSArray<NSString *> *) args;

@end
