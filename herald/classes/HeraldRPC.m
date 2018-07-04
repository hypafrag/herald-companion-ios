//
//  HeraldRPC.m
//  herald
//
//  Created by hypafrag on 05/07/2018.
//  Copyright © 2018 coons club. All rights reserved.
//

#import "HeraldRPC.h"
#import <SocketRocket/SocketRocket.h>

@interface HeraldRPC () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *websocket;
@property (nonatomic, assign) int requestCounter;

@end

@implementation HeraldRPC

+ (instancetype)sharedInstance {
	static HeraldRPC *instance = nil;
	if (instance == nil) {
		instance = [HeraldRPC new];
	}
	return instance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		self.requestCounter = 0;
		self.websocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://192.168.1.3:5246"]];
		self.websocket.delegate = self;
		[self.websocket open];
	}
	return self;
}

- (NSDictionary *)requestDictForMethod:(NSString *)method withParams:(NSDictionary *)params {
	return @{
		@"jsonrpc": @"2.0",
		@"id": @(++self.requestCounter),
		@"method": method,
		@"params": params
	};
}

- (NSString *)requestBodyForMethod:(NSString *)method withParams:(NSDictionary *)params {
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self requestDictForMethod:method withParams:params] options:0 error:nil];
	NSString *body = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	NSLog(@"HeraldRPC request: %@", body);
	return body;
}

- (void)say:(NSString *)phrase {
	[self.websocket send:[self requestBodyForMethod:@"say" withParams:@{@"phrase": phrase}]];
}

- (void)skill:(NSString *)name {
	[self.websocket send:[self requestBodyForMethod:@"skill" withParams:@{@"name": name}]];
}

- (void)skill:(NSString *)name withArgs:(NSArray<NSString *> *)args {
	[self.websocket send:[self requestBodyForMethod:@"skill" withParams:@{@"name": name, @"args": args}]];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
	NSLog(@"Connected to HeraldRPC");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	NSLog(@"HeraldRPC response: %@", message);
}

@end
